/* 
 * A batch job for handling the referral scoring
 *
 * History
 * -------
   05/06/2016 Dan Carmen   Created
   07/17/2017 Dan Carmen   Link to the previous referral history
   06/19/2020 Dan Carmen   Clean up queries, remove extra code
   05/11/2021 Dan Carmen    Clean up code, add Mutual client counts
   01/24/2022 Dan Carmen    Add Mututal Client Tier to the Referral Account
   05/10/2023 Jidesh		Updated the SOQL to Include Owner and Chatter time stamp field sfdc-17885
 */
global without sharing class ReferralScoreBatch  
                      implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   // The time the process started.
   global DateTime startTime;
   // The total number of referral sources found. 
   global Integer referralSourcesFound = 0;
   // The number of differences found. 
   //global Integer diffFound = 0;
   global Integer ctctsFound = 0;
   global Integer ctctsUpdated = 0;
   global Integer refCtctsUpdated = 0;
   global Integer acctsFound = 0;
   global Integer acctsUpdated = 0;
   global Integer refAcctsUpdated = 0;
   global Integer ctrsUpdated = 0;
   global Integer ctrsInserted = 0;
   global Integer ctrsDeleted = 0;
   global Integer histInserted = 0;
   global Integer histUpdated = 0;
   global Integer nbrOpportunities = 0;
   global Integer nbrReferrals = 0;
   
   global String runParams = '';
   
   global ReferralCounter__c totalCounter = new ReferralCounter__c();
   
   global String batchMode = ObjectHelper.OBJECT_CONTACT;
      
   global JobHelper jh = new JobHelper('ReferralScoreBatch');

   // Default constructor.
   global ReferralScoreBatch() {
      startTime = DateTime.now();
      ReferralScoreMethods.clearCounter(totalCounter,null);
   } // ReferralScoreBatch
   
   global ReferralScoreBatch(String p_batchMode) {
      batchMode = p_batchMode;
      startTime = DateTime.now();
      ReferralScoreMethods.clearCounter(totalCounter,null);
   } // ReferralScoreBatch

   // pull back 2 1/2 years to account for client referrals that could drop out of the query.
   public static Date earliestDate = Date.today().addMonths(-30);
   
   public static Boolean queryReferralsSeparately = (Label.ReferralScoreQueryRefsSeparately == 'Y');

   global Database.QueryLocator start(Database.BatchableContext BC){
      jh = new JobHelper('ReferralScoreBatch-'+batchMode);
      // save the record - show that the job started
      jh.saveJob();

      // the id of the batch job
      Id batchJobId = BC.getJobId();
                                          
      // collect the lead sources of the opportunities
      Set<String> oppLeadSourceSet = new Set<String>();
      Set<String> primaryReferralTypeSet = new Set<String>();
      Set<String> busTypeSet = new Set<String>();
      Set<String> contactReferralType = new Set<String>();

      for (Lead_Source_for_Referrals__c ls: Lead_Source_for_Referrals__c.getAll().values()) {
         if (ls.Business_Type__c) {
            busTypeSet.add(ls.Value__c);
         }
         if (ls.Lead_Source__c) {
             oppLeadSourceSet.add(ls.Value__c);
         }
         if (ls.ContactReferralType__c) {
            primaryReferralTypeSet.add(ls.Value__c);
         }
      } // for(Lead_Source_for_Referrals__c
      
      for (ReferralScoreSetup__c rss : ReferralScoreSetup__c.getAll().values()) {
         primaryReferralTypeSet.add(rss.ReferralSource__c);
      }
      
      runParams += 'queryReferralsSeparately='+queryReferralsSeparately;
      runParams += '\noppLeadSourceSet='+oppLeadSourceSet;
      runParams += '\nbusTypeSet='+busTypeSet;
      
      System.debug('ReferralScoreBatch.execute batchMode='+batchMode+' oppLeadSourceSet='+oppLeadSourceSet+' primaryReferralTypeSet='+primaryReferralTypeSet);
      
      if (batchMode == ObjectHelper.OBJECT_ACCOUNT) {

         // get the ids of accounts that are client referrals so they're part of the query         
         Set<Id> acctIdSet = new Set<Id>();
         for (Opportunity opp : [Select Id, Client_Referral__c
                                   From Opportunity
                                  Where CloseDate >= :earliestDate
                                    and LeadSource in :oppLeadSourceSet
                                    and Client_Referral__c != null]) {
            acctIdSet.add(opp.Client_Referral__c);                    
         } // for (Opportunity opp
         
         runParams += '\nNbr of account ids based on client referrals: '+acctIdSet.size();
         
         System.debug('ReferralScoreBatch acctIdSet from opps='+acctIdSet.size());
            return Database.getQueryLocator([Select Id, Name
                                             ,LatestReferralDate__c
                                             ,Referral__c
                                             ,Referral_Type__c
                                             ,ScoreRfrlsSold__c
                                             ,ScoreTotalRfrls__c
                                             ,Mirror_Referral_Account__c
                                             ,Mirror_Referral_Account__r.Id
                                             ,Mirror_Referral_Account__r.LatestReferralDate__c
                                             ,Mirror_Referral_Account__r.Best_CPA_Score_in_Firm__c
                                             ,Mirror_Referral_Account__r.Managed_by_Channel__c
                                             ,Mirror_Referral_Account__r.MutualClients__c
                                             ,Mirror_Referral_Account__r.MutualClientTier__c
                                             ,Mirror_Referral_Account__r.Referral_Type__c
                                             ,Mirror_Referral_Account__r.Referral_Source_Business_Type__c
                                             ,Mirror_Referral_Account__r.chatter_time_stamp_on_tier_down__c
                                             ,Mirror_Referral_Account__r.CPA_Program_Status__c
                                             ,Mirror_Referral_Account__r.OwnerId
                                         From Account
                                        Where (Referral__c in :busTypeSet 
                                                and Mirror_Referral_Account__c != null)
                                           or Id in :acctIdSet
                                         ]);
      } // if (batchMode == ObjectHelper.OBJECT_ACCOUNT
      
      runParams += '\nprimaryReferralTypeSet='+primaryReferralTypeSet;

      // by default it runs for the contact
         return Database.getQueryLocator([Select Id
                                             ,Name
                                             ,LatestReferralDate__c
                                             ,PrimaryReferralType__c
                                             ,Referral_Contact__c
                                             ,Referral_Type__c
                                             ,ScoreRfrlsSold__c
                                             ,ScoreTotalRfrls__c
                                             ,Account.Id
                                             ,Account.Name
                                             ,Account.Referral__c
                                             ,Account.Mirror_Referral_Account__c
                                             ,Mirror_Ref_Ctct__c
                                             ,Mirror_Ref_Ctct__r.Id
                                             ,Mirror_Ref_Ctct__r.CPA_Referral_Score__c
                                             ,Mirror_Ref_Ctct__r.LatestReferralDate__c
                                             ,Mirror_Ref_Ctct__r.MutualClients__c
                                             ,Mirror_Ref_Ctct__r.PrimaryReferralType__c
                                             ,Mirror_Ref_Ctct__r.Referral_Account__c
                                             ,Mirror_Ref_Ctct__r.Referral_Account__r.DefaultCtctPrimaryType__c
                                             ,Mirror_Ref_Ctct__r.Referral_Account__r.Managed_by_Channel__c
                                             ,Mirror_Ref_Ctct__r.Referral_Type__c
                                         From Contact
                                        Where 
                                        (PrimaryReferralType__c in :primaryReferralTypeSet)
                                          and Mirror_Ref_Ctct__c != null
                                         ]);
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      launchBatchJob(ObjectHelper.OBJECT_CONTACT);
   } // execute
   
   global void launchBatchJob(String objectType) {
      ReferralScoreBatch rsb = new ReferralScoreBatch(objectType);
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('ReferralScoreBatch');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
      database.executeBatch(rsb, batchSize);
   } // launchBatchJob

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      System.debug('execute scope size='+scope.size()+' batchMode='+batchMode);
      if (batchMode == ObjectHelper.OBJECT_CONTACT) {
         Contact[] ctcts = (Contact[])scope;
         ctctsFound += ctcts.size();
         ReferralScoreMethods.processContacts(ctcts, BC.getJobId(), true);
      } else if (batchMode == ObjectHelper.OBJECT_ACCOUNT) {
         Account[] accts = (Account[])scope;
         acctsFound += accts.size();
         ReferralScoreMethods.processAccounts(accts, BC.getJobId(), true);
      }
      //nbrOpportunities += opps.size();
      
      //ReferralScoreMethods.processOpportunities(opps, BC.getJobId());
      
      ctrsUpdated += ReferralScoreMethods.nbrUpdates;
      ctrsInserted += ReferralScoreMethods.nbrInserts;
      ctrsDeleted += ReferralScoreMethods.nbrDeletes;
      nbrOpportunities += ReferralScoreMethods.nbrOpportunities;
      nbrReferrals += ReferralScoreMethods.nbrReferrals;
      histInserted += ReferralScoreMethods.nbrHistInserted;
      histUpdated += ReferralScoreMethods.nbrHistUpdated;
      ctctsUpdated += ReferralScoreMethods.contactsUpdated;
      refCtctsUpdated += ReferralScoreMethods.refContactsUpdated;
      acctsUpdated += ReferralScoreMethods.accountsUpdated;
      refAcctsUpdated += ReferralScoreMethods.refAccountsUpdated;
      
      ReferralScoreMethods.addToCounter(ReferralScoreMethods.totalCounter, totalCounter); 
   } // execute

   global void finish(Database.BatchableContext BC){
      String message = '\nBatchMode: '+batchMode+' ';
      message += '\n'+runparams;
       
      //message += '\nTotal Referral Types updated: '+diffFound+' ';
      message += '\n\nRecords checked from: Year 2:'+ReferralScoreMethods.year2.format();
      message +=   '\n                      Year 1:'+ReferralScoreMethods.year1.format();
      message +=   '\n                    6 months:'+ReferralScoreMethods.months6.format();
      message += '\n';
      if (batchMode == ObjectHelper.OBJECT_CONTACT) {
         message += '\nNumber of Contacts Found: '+ctctsFound;
         message += '\nNumber of Contacts Updated: '+ctctsUpdated;
         message += '\nNumber of Referral Contacts Updated: '+refCtctsUpdated;
      } else if (batchMode == ObjectHelper.OBJECT_ACCOUNT) {
         message += '\nNumber of Accounts Found: '+acctsFound;
         message += '\nNumber of Accounts Updated: '+acctsUpdated;
         message += '\nNumber of Referral Accounts Updated: '+refAcctsUpdated;
      }
      message += '\n\nNumber of Referrals found: '+nbrReferrals;
      message += '\nNumber of Opportunities found: '+nbrOpportunities;

      message += '\n\nNumber of counters Updated: '+ctrsUpdated; 
      message += '\nNumber of counters Inserted: '+ctrsInserted; 
      message += '\nNumber of counters Deleted: '+ctrsDeleted; 

      message += '\n\nNumber of histories Updated: '+histUpdated; 
      message += '\nNumber of histories Inserted: '+histInserted; 

      message += '\n\nTotal Counter values: ';
      message += '\n6 Months Sold = '+totalCounter.X6MonthsSold__c;
      message += '\n6 Months Any = '+totalCounter.X6MonthsAny__c;
      message += '\n1 Year Sold ='+totalCounter.X1YearSold__c;
      message += '\n1 Year Any = '+totalCounter.X1YearAny__c;
      message += '\n2 Years Sold = '+totalCounter.X2YearsSold__c;
      message += '\n2 Years Any = '+totalCounter.X2YearsAny__c;
      message += '\nMutual Clients = '+totalCounter.MutualClients__c;
      
      System.debug('ReferralScoreBatch finish message='+message);
      
      jh.completeJob(bc, 'Referral Type Update='+batchMode, message);
      
      if (!Test.isRunningTest() && batchMode == ObjectHelper.OBJECT_CONTACT) {
         launchBatchJob(ObjectHelper.OBJECT_ACCOUNT);
      }
   } // finish

} // class ReferralScoreBatch