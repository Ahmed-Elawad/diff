/* 
 * Methods for referral scoring
 
   Find Opportunities linked to contact/accounts, (through ReferralContact__c/ReferralAccount__c fields) based on referral type of contact/account
   Find Opportunities linked to client referrals (through Client_Referral__c field)
   Find mutual clients

   To calculate scores:
   Query all referrals and opportunities associated with the contact.
   Score - Referrals Sold count includes: Opportunities whose Run-Effective Date (CloseDate) is within the past 12 months
                                          the Opportunity Status starts with 'Sold'
                                      Account attached to the Opportunity has a bis id or the Client Type is of a specific type (like 'SurePayroll')
   
   Score - Total Referrals: Referrals whose created is date within the past year.
                            or if there isn't a referral, opportunity whose created date is within the past year.
 
 *
 * History
 * -------
   05/06/2016 Dan Carmen    Created
   08/18/2016 Dan Carmen    Modifications to better handle client referrals.
   07/17/2017 Dan Carmen    Link to the previous referral history
   06/12/2020 Michael Karcz Modified to handle new Scoring labels of Bronze, Silver, Gold, and Platinum
   06/19/2020 Dan Carmen    Clean up queries, remove extra code
   11/23/2020 Jake Hinds	Adding in sold oppty date and ID fields
   05/11/2021 Dan Carmen    Clean up code, add Mutual client counts
   07/15/2021 Pradeep Garlapaati    Adding Payroll unit to the score calculations
   01/24/2022 Dan Carmen    Add Mututal Client Tier to the Referral Account
   09/01/2022 Dan Carmen    Fix for Referral Type being set (if different than score fields)
   09/04/2022 Dan Carmen    Ability to calculate sold score if no units based on Lead Source
   04/10/2023 Jaipal        APR0147473: Update Medal Score Formula To Include SurePayroll Without Units
   05/10/2023 Jidesh    	Updated calcAcctScore, processAccounts, checkMutualClients methods as part of SFDC-17885 - Chatter notifications while moving down the tier
*/
global without sharing class ReferralScoreMethods {
    

   public static final String BY_CTCT='ByCtctId';
   public static final String BY_ACCT='ByAcctId';
   
   public static final Integer REF_COUNTER_NAME_SIZE = ReferralCounter__c.Name.getDescribe().getLength();

   // map of the existing counters - there will only be one for a contact/account combination
   public static Map<String,ReferralCounter__c> existingCountMap = new Map<String,ReferralCounter__c>();
   
   // map of the existing counters - first key is the id of the source record (account or contact)
   //public static Map<Id, Map<String, Map<String, ReferralCounter__c>>> existingCounterMap = new  Map<Id, Map<String, Map<String, ReferralCounter__c>>>();
   // map of the new counters - first key is the id of the source record (account or contact)
   //public static Map<Id, Map<String, Map<String, ReferralCounter__c>>> newCounterMap = new  Map<Id, Map<String, Map<String, ReferralCounter__c>>>();
   // map of the existing history records - 
   public static Map<Id,ReferralScoreHistory__c[]> historyMap = new Map<Id,ReferralScoreHistory__c[]>();
   
   private static ReferralScoreHistory__c[] updateHistories = new ReferralScoreHistory__c[]{};
   private static ReferralScoreHistory__c[] insertHistories = new ReferralScoreHistory__c[]{};
   
   private static ReferralCounter__c[] counterInserts = new ReferralCounter__c[]{};
   private static ReferralCounter__c[] counterUpdates = new ReferralCounter__c[]{};
   private static ReferralCounter__c[] counterDeletes = new ReferralCounter__c[]{};
   
   public static Integer nbrInserts {get{return counterInserts.size();}}
   public static Integer nbrUpdates {get{return counterUpdates.size();}}
   public static Integer nbrDeletes{get{return counterDeletes.size();}}
   
   public static Integer nbrHistUpdated{get{return updateHistories.size();}}
   public static Integer nbrHistInserted{get{return insertHistories.size();}}
  
   public static ReferralCounter__c totalCounter = null;

   public static Integer nbrOpportunities = 0;
   public static Integer nbrReferrals = 0;
   // Jidesh: variable storing referral accounts moving down the tier to trigger chatter
   public static List<Referral_Account__c> tierDownAccnts = new List<Referral_Account__c>();

   public class RefSourceWrapper {
      public String recName = null;
      public RefSourceWrapper(String p_refSource) {
         referralSource = p_refSource;
      } // RefSourceWrapper
      
      // the primary referral source of this record
      public String referralSource = null;
      public Date latestReferralDate = null;
       
      public Date latestOpptyDate = null;
      public Date latestSoldOpptyDate = null;
      public Id latestOppty = null;
      public Id latestSoldOppty = null;
      public Decimal submittedCount = 0;
      public Decimal soldCount = 0;
      public Integer mutualClients = 0;
      public Integer mutualAll = 0;
      public String mutualClientTier = null;
       
      // The key is always the accountId+contactId for consistency, and for easy compare to existing
      // This is what we're calculating for this run.
      public Map<String,ReferralCounter__c> refCounterMap = new Map<String,ReferralCounter__c>();
      
      public void checkReferralDate(String p_refSource, Date p_checkDate) {
         if ((String.isNotBlank(referralSource) && referralSource == p_refSource && p_checkDate != null)
              && (latestReferralDate == null || p_checkDate > latestReferralDate)
            ) {
            latestReferralDate = p_checkDate;
         } // if ((String.isNotBlank(referralSource
      } // checkReferralDate
   } // RefSourceWrapper
   
   // do we set the referral type on the contacts?
   public static Boolean SET_CONTACT_REF_SCORE=(Label.ReferralTypeSetOnContact == 'Y');

   public static void setup() {
      checkCustomSettings();
      totalCounter = new ReferralCounter__c();
      clearCounter(totalCounter,null);
      existingCountMap.clear();
      
      // make sure these are clear
      //existingCounterMap.clear();
      //newCounterMap.clear();
      refSourceWrapMap.clear();
      
      updateHistories.clear();
      insertHistories.clear();
      
      counterInserts.clear();
      counterUpdates.clear();
      counterDeletes.clear();
      
      nbrOpportunities = 0;
      nbrReferrals = 0;
   } // setup

   // use these for a default value
   public static String[] SOLD_ACCOUNT_TYPES = Label.AccountTypesSold.split(';');
   
   public static Date months6 = Date.today().addMonths(-6);
   public static Date year1 = Date.today().addMonths(-12);
   public static Date year2 = Date.today().addMonths(-24);

   global static Map<String,String> sourceByBusinessTypeMap = null;
   global static Map<String,String> leadSourceRefSourceMap = null;
   global static Map<String,String> contactReferralTypeMap = null;
   global static Set<String> opportunityTypeSet = new Set<String>();

   public static Map<String,ReferralScoreSetup__c[]> scoreBySourceMap = null;
   //public static Map<String,ReferralScoreSetup__c[]> soldScoreBySourceMap = null;
   //public static Map<String,ReferralScoreSetup__c[]> submittedScoreBySourceMap = null;
   public static Map<String,ReferralScoreSetup__c[]> refAcctTiers = null;
   // for the lead sources of opps that do not use payroll units - we will count the quantity of opps vs sum of payroll units
   public static Set<String> leadSourcesDoNotUseUnits = new Set<String>();
    
   
   // break out the custom settings so we only have to loop through all of the values once.
   global static void checkCustomSettings() {
      checkLeadSourceCustomSetting();
      checkReferralScoreSetupCustomSetting();
   } // checkCustomSettings

   public static void checkLeadSourceCustomSetting() {
      if (leadSourceRefSourceMap == null) {
         System.debug('checkCustomSettings setting up from custom settings');
         leadSourceRefSourceMap = new Map<String,String>();
         sourceByBusinessTypeMap = new Map<String,String>();
         contactReferralTypeMap = new Map<String,String>();
         opportunityTypeSet.clear();
         
         for(Lead_Source_for_Referrals__c ls: Lead_Source_for_Referrals__c.getAll().values()){
            if (ls.Business_Type__c && String.isNotBlank(ls.Value__c) && String.isNotBlank(ls.ReferralSource__c)) {
               sourceByBusinessTypeMap.put(ls.Value__c, ls.ReferralSource__c);
            }
            if(ls.Lead_Source__c && String.isNotBlank(ls.ReferralSource__c)) {
               leadSourceRefSourceMap.put(ls.Value__c,ls.ReferralSource__c);
               if (ls.DoesNotUsePayrollUnits__c) {
                  leadSourcesDoNotUseUnits.add(ls.Value__c);
               }
            }
            if(ls.ContactReferralType__c && String.isNotBlank(ls.ReferralSource__c)) {
               contactReferralTypeMap.put(ls.Value__c,ls.ReferralSource__c);
            }
            if (String.isNotBlank(ls.OpportunityTypes__c)) {
               String[] oppTypes = ls.OpportunityTypes__c.split(',');
               opportunityTypeSet.addAll(oppTypes);
            }
         } // for(Lead_Source_for_Referrals__c

      } // if (leadSourceRefSourceMap ==
      System.debug('checkLeadSourceCustomSetting leadSourceRefSourceMap='+leadSourceRefSourceMap.size()+' sourceByBusinessTypeMap='+sourceByBusinessTypeMap.size());

   } // checkLeadSourceCustomSetting
   
   public static void checkReferralScoreSetupCustomSetting() {
      if (scoreBySourceMap == null) { //(soldScoreBySourceMap == null || submittedScoreBySourceMap == null) {
         scoreBySourceMap = new Map<String,ReferralScoreSetup__c[]>();
         //soldScoreBySourceMap = new Map<String,ReferralScoreSetup__c[]>();
         //submittedScoreBySourceMap = new Map<String,ReferralScoreSetup__c[]>();
         refAcctTiers = new Map<String,ReferralScoreSetup__c[]>();
          
         for (ReferralScoreSetup__c rss : ReferralScoreSetup__c.getAll().values()) {
            if (String.isNotBlank(rss.ReferralSource__c)) {
               if (rss.MutualClient__c) {
                  ReferralScoreSetup__c[] scoreList = (refAcctTiers.containsKey(rss.ReferralSource__c) ? refAcctTiers.get(rss.ReferralSource__c) : new ReferralScoreSetup__c[]{});
                  scoreList.add(rss);
                  refAcctTiers.put(rss.ReferralSource__c, scoreList);
              } else {
                  //Map<String,ReferralScoreSetup__c[]> scoreBySourceMap = (rss.SoldReferrals__c ? soldScoreBySourceMap : submittedScoreBySourceMap);
                  ReferralScoreSetup__c[] scoreList = (scoreBySourceMap.containsKey(rss.ReferralSource__c) ? scoreBySourceMap.get(rss.ReferralSource__c) : new ReferralScoreSetup__c[]{});
                  scoreList.add(rss);
                  scoreBySourceMap.put(rss.ReferralSource__c, scoreList);
               } // if (rss.MutualClient__c
            } // if (String.isNotBlank(rss.ReferralSource__c
         } // for (ReferralScoreSetup__c rss
          
      } // if (soldScoreBySourceMap == null || submittedScoreBySourceMap == null

      //System.debug('checkReferralScoreSetupCustomSetting soldScoreBySourceMap='+soldScoreBySourceMap.size()+' submittedScoreBySourceMap='+submittedScoreBySourceMap.size());
      System.debug('checkReferralScoreSetupCustomSetting scoreBySourceMap='+scoreBySourceMap.size()+' refAcctTiers='+refAcctTiers.size());
   } // checkReferralScoreSetupCustomSetting

   public static void checkForSaves() {

      DmlHelper.performDML2(updateHistories, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'checkForSaves', 'update history records', false);
      DmlHelper.performDML2(insertHistories, DmlHelper.DML_INSERT, 'ReferralScoreMethods', 'checkForSaves', 'insert history records', false);
      
      DmlHelper.performDML2(counterInserts, DmlHelper.DML_INSERT, 'ReferralScoreMethods', 'checkForSaves', 'insert new counter records', false);
      DmlHelper.performDML2(counterUpdates, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'checkForSaves', 'update counter records', false);
       
      if (!existingCountMap.isEmpty()) {
         // if there's anything left in here, it didn't match and it's no longer used.
         counterDeletes.addAll(existingCountMap.values());
      }
      DmlHelper.performDML2(counterDeletes, DmlHelper.DML_DELETE, 'ReferralScoreMethods', 'checkForSaves', 'delete counter records', false);
      ErrorLog.checkSave();
   } // checkForSaves

   public static Integer contactsUpdated = 0;
   public static Integer refContactsUpdated = 0;

   public static void processContacts(Contact[] ctcts, String jobId, Boolean queryReferrals) {
      System.debug('processContacts ctcts='+ctcts.size()+' queryReferrals='+queryReferrals);
      setup();
      
      Contact[] updateCtcts = new Contact[]{};
      Referral_Contact__c[] updateRefCtcts = new Referral_Contact__c[]{};
      
      if (queryReferrals) {
         // setup the data for this set of contacts - populates the refSourceWrapMap
         Set<Id> recIdSet = getRecIdSet(ctcts);
         // gets the existing referral counters
         getRefCounters(recIdSet, BY_CTCT);
         // gets the existing referral histories
         getRefHistories(recIdSet);
         // gets the referral/opportunity data
         queryReferralData(recIdSet, BY_CTCT, jobId);
         // get the mutual client information
         checkMutuals(recIdSet, BY_CTCT, jobId);
      } // if (queryReferrals
      
      for (Contact ctct : ctcts) {
         String refSource = (ctct.PrimaryReferralType__c != null ? contactReferralTypeMap.get(ctct.PrimaryReferralType__c) : null);
         Boolean recChanged = false;
         RefSourceWrapper refSourceWrap = refSourceWrapMap.get(ctct.Id);
         System.debug('processContacts refSourceWrap='+(refSourceWrap != null));

         recChanged = compareExistingToNew(refSourceWrap,ctct
                                           ,(refSourceWrap != null ? refSourceWrap.referralSource : null)
                                          ,'ScoreRfrlsSold__c', 'ScoreTotalRfrls__c', 'Referral_Type__c');
         recChanged = recChanged || (refSourceWrap != null && ctct.Mirror_Ref_Ctct__c != null && ctct.Mirror_Ref_Ctct__r.MutualClients__c != refSourceWrap.mutualClients);
         if (refSourceWrap != null && refSourceWrap.latestReferralDate != null) {
            if (ctct.LatestReferralDate__c == null || refSourceWrap.latestReferralDate != ctct.LatestReferralDate__c) {
               ctct.LatestReferralDate__c = refSourceWrap.latestReferralDate;
               recChanged = true;
            }
            System.debug('processContacts latestReferralDate='+ctct.Mirror_Ref_Ctct__r.LatestReferralDate__c+' refSourceWrap.latestReferralDate='+refSourceWrap.latestReferralDate+' ctct.Mirror_Ref.LatestReferralDate='+ctct.Mirror_Ref_Ctct__r.LatestReferralDate__c);
         } // if (refSourceWrap.latestReferralDate

         if (recChanged) {
            // create a new instance so other fields don't get inadvertently changed.
            Contact newCtct = new Contact(Id=ctct.Id
                                         ,ScoreRfrlsSold__c=ctct.ScoreRfrlsSold__c
                                         ,ScoreTotalRfrls__c=ctct.ScoreTotalRfrls__c
                                         ,LatestReferralDate__c=ctct.LatestReferralDate__c
                                         ,Referral_Type__c=ctct.Referral_Type__c
                                         );
            updateCtcts.add(newCtct);
            if (ctct.Mirror_Ref_Ctct__c != null) {
               // create a new instance so other fields don't get inadvertently changed.
               Referral_Contact__c refCtct = new Referral_Contact__c(Id=ctct.Mirror_Ref_Ctct__c, LatestReferralDate__c = refSourceWrap.latestReferralDate, Referral_Type__c = ctct.Referral_Type__c
                                                                     ,MutualClients__c=refSourceWrap.mutualClients);
               updateRefCtcts.add(refCtct);
            }
         }
         // check the history record
         checkHistoryRecords(ctct.Id, null, ctct.Name, historyMap.get(ctct.Id), ctct.ScoreRfrlsSold__c, ctct.ScoreTotalRfrls__c, refSource, ctct.Mirror_Ref_Ctct__c, null, refSourceWrap);
      } // for (Contact ctct
      
      contactsUpdated = updateCtcts.size();
      refContactsUpdated = updateRefCtcts.size();
      
      // I don't believe we need the triggers to fire
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      DmlHelper.performDML2(updateCtcts, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'processContacts', 'update score on contacts', false);
      if (!updateRefCtcts.isEmpty()) {
         ReferralObjectsSync.SKIP_SYNC = true;
         DmlHelper.performDML2(updateRefCtcts, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'processContacts', 'update referral contacts', false);
         ReferralObjectsSync.SKIP_SYNC = false;
      }
      checkForSaves();
   } // processContacts
   
   public static void queryReferralData(Set<Id> recIdSet, String runType, String jobId) {
      Set<Id> opptyIdToExcludeSet = checkReferrals(recIdSet, runType, jobId);
      checkOpptys(recIdSet, opptyIdToExcludeSet, runType, jobId);
   } // queryReferralData
   
   public static Set<Id> getRecIdSet(Contact[] ctcts) {
      Set<Id> recIdSet = new Set<Id>();
      for (Contact ctct : ctcts) {
         RefSourceWrapper refSourceWrap = null;
         // in case the referral type isn't set on the contact for some reason
         String refType = (String.isNotBlank(ctct.PrimaryReferralType__c) ? ctct.PrimaryReferralType__c 
                               : (ctct.Mirror_Ref_Ctct__r != null && ctct.Mirror_Ref_Ctct__r.Referral_Account__r != null ? ctct.Mirror_Ref_Ctct__r.Referral_Account__r.DefaultCtctPrimaryType__c : null));
         refType = ((String.isNotBlank(refType) && contactReferralTypeMap.containsKey(refType)) ? contactReferralTypeMap.get(refType) : refType);
         System.debug('getRecIdSet refType='+refType);
         if (String.isNotBlank(refType)) {
            refSourceWrap = new RefSourceWrapper(refType);
            refSourceWrap.recName = ctct.Name;
            refSourceWrapMap.put(ctct.Id, refSourceWrap);
         }
         recIdSet.add(ctct.Id);
      } // for (Contact ctct
      return recIdSet;
   } // getRecIdSet
   
   public static Set<Id> getRecIdSet(Account[] accts) {
      Set<Id> recIdSet = new Set<Id>();
      for (Account acct : accts) {
         RefSourceWrapper refSourceWrap = null;
         if (acct.Referral__c != null && sourceByBusinessTypeMap.get(acct.Referral__c) != null) {
            refSourceWrap = new RefSourceWrapper(sourceByBusinessTypeMap.get(acct.Referral__c));
            refSourceWrap.recName = acct.Name;
            refSourceWrapMap.put(acct.Id, refSourceWrap);
         }
         recIdSet.add(acct.Id);
      } // for (Account acct
      return recIdSet;
   } // getRecIdSet
   
   public static Integer accountsUpdated = 0;
   public static Integer refAccountsUpdated = 0;
   
   public static void processAccounts(Account[] accts, String jobId, Boolean queryReferrals) {
      System.debug('processAccounts accts='+accts.size());
      setup();
      
      Account[] updateAccts = new Account[]{};
      Referral_Account__c[] updateRefAccts = new Referral_Account__c[]{};
      
      if (queryReferrals) {
         // setup the data for this set of contacts
         Set<Id> recIdSet = getRecIdSet(accts);
         getRefCounters(recIdSet, BY_ACCT);
         getRefHistories(recIdSet);
         queryReferralData(recIdSet, BY_ACCT, jobId);
         // get the mutual client information
         checkMutuals(recIdSet, BY_ACCT, jobId);
      } // if (queryReferrals
       
      // mutual client tiers can only move up, not down except for 1 time of year. 
      Boolean canWeResetMutuals = checkToResetMutuals();

      for (Account acct : accts) {
         String refSource = (acct.Referral__c != null ? sourceByBusinessTypeMap.get(acct.Referral__c) : null);
         Boolean recChanged = false;

         RefSourceWrapper refSourceWrap = refSourceWrapMap.get(acct.Id);
         recChanged = compareExistingToNew(refSourceWrap, acct
                                          ,(refSourceWrap != null ? refSourceWrap.referralSource : null)
                                          ,'ScoreRfrlsSold__c', 'ScoreTotalRfrls__c', 'Referral_Type__c');

         Boolean mutualChanged = checkMutualClients(acct, refSourceWrap, canWeResetMutuals);
          
         if (refSourceWrap != null && refSourceWrap.latestReferralDate != null) {
            if (acct.LatestReferralDate__c == null || refSourceWrap.latestReferralDate != acct.LatestReferralDate__c) {
               acct.LatestReferralDate__c = refSourceWrap.latestReferralDate;
               recChanged = true;
            }
         } // if (refSourceWrap.latestReferralDate
                          
         if (recChanged) {
            // create a new record so other fields don't get inadvertently changed.
            Account newAcct = new Account(Id=acct.Id
                                         ,ScoreRfrlsSold__c=acct.ScoreRfrlsSold__c
                                         ,ScoreTotalRfrls__c=acct.ScoreTotalRfrls__c
                                         ,Referral_Type__c=acct.Referral_Type__c
                                         ,LatestReferralDate__c = acct.LatestReferralDate__c);
            updateAccts.add(newAcct);
         }
         if ((recChanged || mutualChanged) && acct.Mirror_Referral_Account__r != null) {
                    //&& (acct.Mirror_Referral_Account__r.LatestReferralDate__c == null || refSourceWrap.latestReferralDate != acct.Mirror_Referral_Account__r.LatestReferralDate__c)) {
               // create a new record so other fields don't get inadvertently changed.
               Referral_Account__c refAcct = new Referral_Account__c(Id=acct.Mirror_Referral_Account__r.Id
                                                                     ,LatestReferralDate__c=refSourceWrap.latestReferralDate
                                                                     ,Best_CPA_Score_in_Firm__c=acct.Mirror_Referral_Account__r.Best_CPA_Score_in_Firm__c
                                                                     ,MutualClients__c=refSourceWrap.mutualClients
                                                                     ,MutualClientTier__c=refSourceWrap.mutualClientTier
                                                                     ,Referral_Type__c=acct.Referral_Type__c);
             // Jidesh: reset the chatter time stamp
             if(canWeResetMutuals && mutualChanged && acct.Mirror_Referral_Account__r.chatter_time_stamp_on_tier_down__c != NULL && acct.Mirror_Referral_Account__r.CPA_Program_Status__c == 'Enrolled'){
                 System.debug('Setting chatter_time_stamp_on_tier_down__c to Null');
                 refAcct.chatter_time_stamp_on_tier_down__c = null;
             }
               updateRefAccts.add(refAcct);
         }
         checkHistoryRecords(null, acct.Id, acct.Name, historyMap.get(acct.Id), acct.ScoreRfrlsSold__c, acct.ScoreTotalRfrls__c, refSource, null, acct.Mirror_Referral_Account__c, refSourceWrap);
      } // for (Account acct
      
      accountsUpdated = updateAccts.size();
      refAccountsUpdated = updateRefAccts.size();
      // Jidesh: Fire chatter msg on moving down the tier sfdc-17885
       System.debug('processAccounts tierDownAccnts:'+tierDownAccnts);
       if(tierDownAccnts.size()>0){
           CPA_ChatterMessages.mutualClientMoveDownTierNotification(tierDownAccnts); 
       }
      System.debug('processAccounts updateAccts='+updateAccts.size()+' updateRefAccts='+updateRefAccts.size());
       
      ZipCheckOwner.SKIP_TRIGGERS=true;
      DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'processAccounts', 'update score on accounts', false);
      if (!updateRefAccts.isEmpty()) {
         ReferralObjectsSync.SKIP_SYNC = true;
         DmlHelper.performDML2(updateRefAccts, DmlHelper.DML_UPDATE, 'ReferralScoreMethods', 'processAccounts', 'update referral accounts', false);
         ReferralObjectsSync.SKIP_SYNC = false;
      }
      checkForSaves();
   } // processAccounts
    
   // Date range we can reset dates day/month-day/month. Ex Jan 1 - Jan 10 = 1/1-1/10
   public static String RESET_MUTUALS_KEY=Label.ReferralScore_MutualClientReset;
    
   public static Boolean checkToResetMutuals() {
      Boolean canWeResetMutuals = false;
      String[] firstTokens = RESET_MUTUALS_KEY.split('-');
      Date startDate = null;
      Date endDate = null;
      System.debug('checkToResetMutuals RESET_MUTUALS_KEY='+RESET_MUTUALS_KEY+' firstTokens='+firstTokens.size());
      Integer thisYear = Date.today().year();
      if (firstTokens.size() == 2) {
         try {
            String[] startTokens = firstTokens[0].split('/');
            startDate = Date.newInstance(thisYear,Integer.valueOf(startTokens[0]),Integer.valueOf(startTokens[1]));
            String[] endTokens = firstTokens[1].split('/');
            endDate = Date.newInstance(thisYear,Integer.valueOf(endTokens[0]),Integer.valueOf(endTokens[1]));
         } catch (Exception e) {
            System.debug('checkToResetMutuals exception: '+e.getMessage());
         }
      }
      startDate = (startDate != null ? startDate : Date.newInstance(thisYear,1,1));
      endDate = (endDate != null ? endDate : Date.newInstance(thisYear,1,10));
      canWeResetMutuals = (startDate <= Date.today() && endDate >= Date.today());
      System.debug('checkToResetMutuals canWeResetMutuals='+canWeResetMutuals);
      return canWeResetMutuals;
   } // checkToResetMutuals
    
   public static Boolean checkMutualClients(Account acct, RefSourceWrapper refSourceWrap, Boolean canWeResetMutuals) {
      Boolean mutualChanged = false;
      // only process if we have records setup
      Boolean tiersSetup = refAcctTiers.containsKey(acct.Mirror_Referral_Account__r.Referral_Source_Business_Type__c);
      System.debug('checkMutualClients tiersSetup='+tiersSetup);
      if (acct.Mirror_Referral_Account__r != null && tiersSetup) {
         // default the current value
         refSourceWrap.mutualClientTier = acct.Mirror_Referral_Account__r.MutualClientTier__c;
         Integer curMutualClients = (acct.Mirror_Referral_Account__r.MutualClients__c != null ? Integer.valueOf(acct.Mirror_Referral_Account__r.MutualClients__c) : 0);
         mutualChanged = (curMutualClients != refSourceWrap.mutualClients );
         System.debug('checkMutualClients mutualChanged='+mutualChanged+' canWeResetMutuals='+canWeResetMutuals);
         // always can update if the count increases. Otherwise only can go backwards during a certain time of the year.
         // Jidesh chatter msg on moving down the tier sfdc-17885
          if(!canWeResetMutuals && refSourceWrap.mutualClients < curMutualClients && acct.Mirror_Referral_Account__r.chatter_time_stamp_on_tier_down__c == Null && acct.Mirror_Referral_Account__r.CPA_Program_Status__c == 'Enrolled'){
              // refSourceWrap is based on account
              // curMutualClients based on Referral Account
              // Set the chatter time stamp here
              // Add RA to the list
              acct.Mirror_Referral_Account__r.chatter_time_stamp_on_tier_down__c = System.now();
              tierDownAccnts.add(acct.Mirror_Referral_Account__r);
          }
          System.debug('refSourceWrap.mutualClientTier>>>>>>>>>>before if'+refSourceWrap.mutualClientTier);
         if (canWeResetMutuals || refSourceWrap.mutualClients > curMutualClients  || (String.isBlank(refSourceWrap.mutualClientTier) && refSourceWrap.mutualClients > 0)) {
            System.debug('checkMutualClients canWeResetMutuals:'+canWeResetMutuals+' refSourceWrap.mutualClients='+refSourceWrap.mutualClients+' curMutualClients='+curMutualClients);
            ReferralScoreSetup__c[] setups =  refAcctTiers.get(acct.Mirror_Referral_Account__r.Referral_Source_Business_Type__c);
            if (setups != null) {
               refSourceWrap.mutualClientTier = null;
               for (ReferralScoreSetup__c rss : setups) {
                  if (rss.RangeMin__c <= refSourceWrap.mutualClients && refSourceWrap.mutualClients <= rss.RangeMax__c) {
                     refSourceWrap.mutualClientTier = rss.ReferralType__c;
                     if (acct.Mirror_Referral_Account__r.MutualClientTier__c != rss.ReferralType__c) {
                        mutualChanged = true;
                     }
                     break;
                  } // if (rss.RangeMin__c
               } // for (ReferralScoreSetup__c rss : setups
            } // if (setups != null
         } // if (canWeResetMutuals || refSourceWrap.mutualClients
      } // if (acct.Mirror_Referral_Account__r
      System.debug('refSourceWrap.mutualClientTier>>>>>>>>>>after if'+refSourceWrap.mutualClientTier);
      return mutualChanged;
   } // checkMutualClients
    
   // query all of the existing referral counters
   public static void getRefCounters(Set<Id> queryIds, String counterType) {
      ReferralCounter__c[] counters = [Select Id, Name
                                             ,X1YearSold__c
                                             ,X1YearAny__c
                                             ,X2YearsSold__c
                                             ,X2YearsAny__c
                                             ,X6MonthsSold__c
                                             ,X6MonthsAny__c
                                             ,Account__c
                                             ,Contact__c
                                             ,JobId__c
                                             ,Latest_Opportunity_Date__c
                                             ,Latest_Opportunity__c
                                             ,Latest_Sold_Opportunity_Date__c
                                             ,Latest_Sold_Opportunity__c
                                             ,MutualAll__c
                                             ,MutualClients__c
                                             ,Referral_Account__c
                                             ,Referral_Contact__c
                                             ,ReferralSource__c
                                             ,ReferralSource2__c
                                         From ReferralCounter__c
                                        Where Account__c in :queryIds
                                           or Contact__c in :queryIds];
      // return all of the counters grouped by the id that was passed in
      for (ReferralCounter__c counter : counters) {
         String key = ''+(counter.Account__c != null ? String.valueOf(counter.Account__c) : '') + (counter.Contact__c != null ? String.valueOf(counter.Contact__c) : '');
         if (String.isNotBlank(key)) {
            existingCountMap.put(key,counter);
         }
         /*
         checkCounter(counterType, counter.Contact__c, counter.Account__c
                      ,(counter.Referral_Contact__c != null ? counter.Referral_Contact__c : null)
                      ,(counter.Referral_Account__c != null ? counter.Referral_Account__c : null)
                      , counter.ReferralSource2__c, existingCounterMap, counter, null, null); 
         */
      } // for (ReferralCounter__c counter
      System.debug('getRefCounters queryIds='+queryIds.size()+' counters='+counters.size()+' existingCountMap='+existingCountMap.size());
   } // getRefCounters
    
   // There is only one current history for accounts and contacts
   public static void getRefHistories(Set<Id> queryIds) {
      historyMap.clear();
      ReferralScoreHistory__c[] histories = [Select Id, Name
                                                   ,Account__c
                                                   ,Contact__c
                                                   ,EndDate__c
                                                   ,MutualAll__c
                                                   ,MutualClients__c
                                                   ,MutualClientTier__c
                                                   ,PreviousReferralScore__c
                                                   ,Referral_Account__c
                                                   ,Referral_Contact__c
                                                   ,ReferralSource__c
                                                   ,ReferralScore__c
                                                   ,ReferralScoreSubmitted__c
                                             	   ,Count_Referrals_Sold__c
                                             	   ,Count_Total_Referrals__c
                                             	   ,Latest_Opportunity_Date__c
                                             	   ,Latest_Opportunity__c
                                             	   ,Latest_Sold_Opportunity_Date__c
                                             	   ,Latest_Sold_Opportunity__c
                                                   ,StartDate__c
                                               From ReferralScoreHistory__c
                                              Where (Account__c in :queryIds
                                                     or Contact__c in :queryIds)
                                                and EndDate__c = null
                                                order by StartDate__c desc];
      for (ReferralScoreHistory__c history : histories) {
         Id keyId = (history.Contact__c != null && queryIds.contains(history.Contact__c) ? history.Contact__c : history.Account__c);
         if (keyId != null) {
            ReferralScoreHistory__c[] historyById = (historyMap.containsKey(keyId) ? historyMap.get(keyId) : new ReferralScoreHistory__c[]{});
            historyById.add(history);
            historyMap.put(keyId,historyById);
         }
      }
      System.debug('getRefHistories queryIds='+queryIds.size()+' histories='+histories.size()+' historyMap='+historyMap.size());
   } // getRefHistories

   public static Map<Id, RefSourceWrapper> refSourceWrapMap = new Map<Id, RefSourceWrapper>();
   
   public static Set<Id> checkReferrals(Set<Id> queryIdSet, String runType, String jobId) {
      // keep track of 
      Set<Id> opptyIdToExcludeSet = new Set<Id>();
      for (Referral__c rfrl : [Select Id, Name
                                     ,CreatedDate
                                     ,Referral_Id__c
                                     ,ReferralSourceAccount__c
                                     ,ReferralSourceAccount__r.Name
                                     ,ReferralSourceAccount__r.Mirror_Referral_Account__c
                                     ,ReferralSourceContact__c
                                     ,ReferralSourceContact__r.Name
                                     ,ReferralSourceContact__r.Mirror_Ref_Ctct__c
                                     ,ReferralSourceContact__r.Mirror_Ref_Ctct__r.Referral_Account__c
                                     ,SellingLeadSource__c
                                     ,Selling_Opportunity__c
                                     ,Selling_Opportunity__r.Id
                                     ,Selling_Opportunity__r.CloseDate
                                     ,Selling_Opportunity__r.CreatedDate
                                     ,Selling_Opportunity__r.LeadSource
                                     ,Selling_Opportunity__r.Name
                                     ,Selling_Opportunity__r.StageName
                               		 ,Selling_Opportunity__r.isClosed
                               		 ,Selling_Opportunity__r.isWon
                                     ,Selling_Opportunity__r.Account.BIS_ID__c
                                     ,Selling_Opportunity__r.Account.Lost_Date__c
                                     ,Selling_Opportunity__r.Account.Type
                               		 ,Selling_Opportunity__r.Payroll_Units__c
                                     ,Selling_Opportunity__r.OpportunityType__c
                                 From Referral__c
                                Where CreatedDate >= :year2
                                  and SellingLeadSource__c in :leadSourceRefSourceMap.keySet()
                                  and (ReferralSourceAccount__c in :queryIdSet
                                        or ReferralSourceContact__c in :queryIdSet)]) {
         nbrReferrals++;
         if (rfrl.Selling_Opportunity__c != null) {
            opptyIdToExcludeSet.add(rfrl.Selling_Opportunity__c);
         }
         Id keyId = (runType == BY_CTCT ? rfrl.ReferralSourceContact__c : (runType == BY_ACCT ? rfrl.ReferralSourceAccount__c : null));
         RefSourceWrapper refSourceWrap = (keyId != null ? refSourceWrapMap.get(keyId) : null);
         if (refSourceWrap != null) {
            String leadSource = (rfrl.Selling_Opportunity__r != null ? rfrl.Selling_Opportunity__r.LeadSource : rfrl.SellingLeadSource__c);
            checkAddToCounter(leadSource, rfrl.Selling_Opportunity__r, rfrl, rfrl.ReferralSourceContact__r, rfrl.ReferralSourceAccount__r, runType, jobId, refSourceWrap);
         }
      } // for (Referral__c rfrl
      return opptyIdToExcludeSet;
   } // checkReferrals
   
   public static void checkOpptys(Set<Id> queryIdSet, Set<Id> excludeOpptyIdSet, String runType, String jobId) {
      System.debug('checkOpptys queryIdSet='+queryIdSet.size()+' excludeOpptyIdSet='+excludeOpptyIdSet.size());
      for (Opportunity oppty : [Select Id, CloseDate, LeadSource, Name
                                      ,OpportunityType__c
                               		  ,Payroll_Units__c
                                      ,CreatedDate
                                      ,StageName
                                	  ,isClosed
                                	  ,isWon
                                      ,Account.BIS_ID__c, Account.Lost_Date__c, Account.Type
                                      ,ReferralAccount__c
                                      ,ReferralAccount__r.Id
                                      ,ReferralAccount__r.Name
                                      ,ReferralAccount__r.Mirror_Referral_Account__c
                                      ,ReferralContact__c
                                      ,ReferralContact__r.Name
                                      ,ReferralContact__r.Mirror_Ref_Ctct__c
                                      ,ReferralContact__r.Mirror_Ref_Ctct__r.Referral_Account__c
                                      ,Client_Referral__c
                                  From Opportunity
                                 Where (CreatedDate >= :year2 or CloseDate >= :year2)
                                   and LeadSource in :leadSourceRefSourceMap.keySet()
                                   and Id not in :excludeOpptyIdSet
                                   and (ReferralAccount__c in :queryIdSet
                                         or ReferralContact__c in :queryIdSet)]) {

         nbrOpportunities++;
         Id keyId = (runType == BY_CTCT ? oppty.ReferralContact__c : (runType == BY_ACCT ? oppty.ReferralAccount__c : null));
         RefSourceWrapper refSourceWrap = (keyId != null ? refSourceWrapMap.get(keyId) : null);
         if (refSourceWrap != null) {
            checkAddToCounter(oppty.LeadSource, oppty, null, oppty.ReferralContact__r, oppty.ReferralAccount__r, runType, jobId, refSourceWrap);
         }         
      } // for (Referral__c rfrl
   } // checkOpptys
    
   // query the mutual client information
   public static void checkMutuals(Set<Id> queryIdSet, String runType, String jobId) {
      List<AggregateResult> mutualClientResults = new List<AggregateResult>( 
                      [select COUNT(Id) cnt, CPA_Name_Ref__c refCtctId, CPA_Name_Ref__r.Referral_Account__c refAcctId, CPA_Name_Ref__r.Contact__c ctctId
                             ,CPA_Name_Ref__r.Contact__r.AccountId acctId, CurrentClient__c curClient
                         from Account
                        where CPA_Name_Ref__r.Contact__c in :queryIdSet
                           or CPA_Name_Ref__r.Contact__r.AccountId in :queryIdSet
                        group by CPA_Name_Ref__c, CPA_Name_Ref__r.Referral_Account__c, CPA_Name_Ref__r.Contact__c, CPA_Name_Ref__r.Contact__r.AccountId, CurrentClient__c]);
      for (AggregateResult result : mutualClientResults) {
         Integer cnt = (Integer)result.get('cnt');
         Id refCtctId = (Id)result.get('refCtctId');
         Id refAcctId = (Id)result.get('refAcctId');
         Id ctctid = (Id)result.get('ctctId');
         Id acctId = (Id)result.get('acctId');
         Boolean currentClient = (Boolean)result.get('curClient');
         Id keyId = (runType == BY_CTCT ? ctctid : (runType == BY_ACCT ? acctId : null));
         RefSourceWrapper refSourceWrap = (keyId != null ? refSourceWrapMap.get(keyId) : null);
         if (refSourceWrap != null) {
            if (currentClient) {
               refSourceWrap.mutualClients = refSourceWrap.mutualClients + cnt;
            }
            refSourceWrap.mutualAll = refSourceWrap.mutualAll + cnt;
            String counterKey = ''+(acctId != null ? String.valueOf(acctId) : '') + (ctctId != null ? String.valueOf(ctctId) : '');
            ReferralCounter__c counter = refSourceWrap.refCounterMap.get(counterKey);
            // should always exist here but just in case
            if (counter == null && String.isNotBlank(counterKey)) {
               counter = new ReferralCounter__c(Contact__c=ctctId, Account__c=acctId, Referral_Contact__c=refCtctId, Referral_Account__c=refAcctId, ReferralSource2__c=refSourceWrap.referralSource);
               // make sure the name doesn't exceed the size.
               counter.Name = refSourceWrap.recName.left(REF_COUNTER_NAME_SIZE);
               clearCounter(counter,jobId);
               refSourceWrap.refCounterMap.put(counterKey,counter);
            } // if (counter == null
            if (counter != null) {
               counter.MutualAll__c = counter.MutualAll__c+cnt;
               if (currentClient) {
                  counter.MutualClients__c = counter.MutualClients__c + cnt;
               }
            } // if (counter != null
         } // if (refSourceWrap != null
      } // for (AggregateResult result
   } // checkMutuals
   

   public static final Integer REF_HISTORY_NAME_SIZE = ReferralScoreHistory__c.Name.getDescribe().getLength();

   public static void checkHistoryRecords(Id ctctId, Id acctId, String recName, ReferralScoreHistory__c[] historyRecs
                                         ,String refScore, String refScoreSubmitted, String referralSource
                                         ,Id refCtctId, Id refAcctId
                                         ,RefSourceWrapper refSourceWrap) {
      System.debug('checkHistoryRecords recName='+recName+' refScore='+refScore+' refScoreSubmitted='+refScoreSubmitted+' referralSource='+referralSource+' hasWrapper='+(refSourceWrap != null));
      Boolean historyHandled = false;
      ReferralScoreHistory__c latestHistory = null;
      // if there is more than one, the first should be the current one. If there is more than one, end date the others.
      if (historyRecs != null && !historyRecs.isEmpty()) {
         latestHistory = historyRecs[0];
         if (historyRecs.size() > 1) {
            // end date these records
            for (Integer recCnt = 1; recCnt < historyRecs.size(); recCnt++) {
               ReferralScoreHistory__c thisHistory = historyRecs[recCnt];
               thisHistory.EndDate__c = Date.today().addDays(-1);
               updateHistories.add(thisHistory);
            }
         }
      } // if (historyRecs != null
      
      if (latestHistory != null && refSourceWrap != null) {
         if (latestHistory.ReferralScore__c != refScore || latestHistory.ReferralScoreSubmitted__c != refScoreSubmitted || latestHistory.ReferralSource__c != referralSource
            || latestHistory.Count_Referrals_Sold__c != refSourceWrap.soldCount || latestHistory.Count_Total_Referrals__c != refSourceWrap.submittedCount 
            || latestHistory.Latest_Opportunity_Date__c != refSourceWrap.latestOpptyDate || latestHistory.Latest_Sold_Opportunity_Date__c != refSourceWrap.latestSoldOpptyDate
            || latestHistory.MutualClients__c != refSourceWrap.mutualClients || latestHistory.MutualAll__c != refSourceWrap.mutualAll) {
            // if any of the criteria don't match then we end the current history record and create a new one with the existing information
            System.debug('checkHistoryRecords end dated existing history record for '+recName);
            latestHistory.EndDate__c = Date.today().addDays(-1);
            updateHistories.add(latestHistory);
         } else {
            System.debug('checkHistoryRecords no changes for '+recName);
            // if everything matches we don't need to do anything else.
            historyHandled = true;
         }
      }
      
      if (!historyHandled && (String.isNotBlank(refScore) || String.isNotBlank(refScoreSubmitted))) {
         System.debug('checkHistoryRecords new history created for '+recName);
         ReferralScoreHistory__c history = new ReferralScoreHistory__c(Name=recName.left(REF_HISTORY_NAME_SIZE)
                                                     ,Account__c=acctId, Contact__c=ctctId, StartDate__c=Date.today()
                                                     ,PreviousReferralScore__c = (latestHistory != null ? latestHistory.Id : null)
                                                     ,ReferralScore__c=refScore, ReferralScoreSubmitted__c=refScoreSubmitted
                                                     ,ReferralSource__c=referralSource
                                                     ,Referral_Account__c=refAcctId, Referral_Contact__c=refCtctId
													 ,Latest_Opportunity_Date__c = (refSourceWrap != null ? refSourceWrap.latestOpptyDate : null)
													 ,Latest_Opportunity__c = (refSourceWrap != null ? refSourceWrap.latestOppty : null)
													 ,Latest_Sold_Opportunity_Date__c = (refSourceWrap != null ? refSourceWrap.latestSoldOpptyDate : null)
													 ,Latest_Sold_Opportunity__c = (refSourceWrap != null ? refSourceWrap.latestSoldOppty : null)
                                                     ,Count_Total_Referrals__c = (refSourceWrap != null ? refSourceWrap.submittedCount : null)
													 ,Count_Referrals_Sold__c = (refSourceWrap != null ? refSourceWrap.soldCount : null)
													 ,MutualAll__c = (refSourceWrap != null ? refSourceWrap.mutualAll : null)
													 ,MutualClients__c = (refSourceWrap != null ? refSourceWrap.mutualClients : null)
                                                     ,MutualClientTier__c = (refSourceWrap != null ? refSourceWrap.mutualClientTier : null)
                                                     );
         insertHistories.add(history);
      }
   } // checkHistoryRecords
   
   public static String getChildRecordName(Contact ctct, Account acct, Opportunity opp, Referral__c rfrl) {
      String recName = (ctct != null ? ctct.Name +'-' : '') +
                             (acct != null ? acct.Name : (opp != null ? opp.Name : (rfrl != null ? rfrl.Name : '')));
      return recName;
   } // getChildRecordName
   
    
   public static void checkAddToCounter(String leadSource, Opportunity opp, Referral__c rfrl, Contact ctct, Account acct, String counterType, String jobId, RefSourceWrapper refSourceWrap) {
      if (String.isNotBlank(leadSource)) {
         String referralSource = leadSourceRefSourceMap.get(leadSource);
         String name=(opp != null ? opp.Name : (rfrl != null ? rfrl.Name : 'NoName'));
         String oppType=(opp != null ? opp.OpportunityType__c : null);
         Boolean oppTypeOkay = (oppType == null || opportunityTypeSet.isEmpty() || opportunityTypeSet.contains(oppType));
         System.debug('checkAddToCounter name='+name+' leadSource='+leadSource+' referralSource='+referralSource+' rfrl='+(rfrl != null)+' oppTypeOkay='+oppTypeOkay);
         // make sure it's a valid lead source for this process.
         if (referralSource != null && oppTypeOkay) {
            String counterName = getChildRecordName(ctct, acct, opp, rfrl);
            Id acctId = (acct != null ? acct.Id : null);
            Id ctctId = (ctct != null ? ctct.Id : null);
            Id refCtctId = null;
            Id refAcctId = null;
            
            if (ctct != null) {
                 if(ctct.Mirror_Ref_Ctct__c != null) {
                     refCtctId = ctct.Mirror_Ref_Ctct__c;
                     refAcctId = ctct.Mirror_Ref_Ctct__r.Referral_Account__c;
                 }
            }
            if (refAcctId == null && acct != null) {
               refAcctId = acct.Mirror_Referral_Account__c;
            }
            ReferralCounter__c counter = null;
            // Key is always acctId + ctctId
            String counterKey = ''+(acctId != null ? String.valueOf(acctId) : '') + (ctctId != null ? String.valueOf(ctctId) : '');
            if (String.isNotBlank(counterKey)) {
               counter = refSourceWrap.refCounterMap.get(counterKey);
            }
            if (counter == null && String.isNotBlank(counterKey)) {
               counter = new ReferralCounter__c(Contact__c=ctctId, Account__c=acctId, Referral_Contact__c=refCtctId, Referral_Account__c=refAcctId, ReferralSource2__c=referralSource);
               // make sure the name doesn't exceed the size.
               counter.Name = counterName.left(REF_COUNTER_NAME_SIZE);
               clearCounter(counter,jobId);
               refSourceWrap.refCounterMap.put(counterKey,counter);
            } // if (counter == null
            /*
            counter = checkCounter(counterType, (ctct != null ? ctct.Id : null), (acct != null ? acct.Id : null)
                                                      ,refCtctId
                                                      ,refAcctId
                                                      ,referralSource
                                                      ,newCounterMap //(counterType == BY_CTCT ? byCtctIdBySourceByAcctIdMap : byAcctIdBySourceByCtctIdMap)
                                                      ,null, jobId, counterName);
            */
            if (counter != null) {
               addToCounter(opp, rfrl, counter, refSourceWrap);
            }
         } // if (referralSource != null
          
      } // if (String.isNotBlank(leadSource
   } // checkAddToCounter
   
   // compare the map of existing counters to new counters
   public static Boolean compareExistingToNew(RefSourceWrapper refSourceWrap
                                          ,SObject sourceRec, String sourceRecReferralSource, String soldScoreFld, String submittedScoreFld, String referralTypeFld) {
      Decimal soldCnt = 0;
      Decimal submittedCnt = 0;
      if (refSourceWrap != null) {
                                                  
         for (String key : refSourceWrap.refCounterMap.keySet()) {
            // the counter we calculated now
            ReferralCounter__c thisCtr = refSourceWrap.refCounterMap.get(key);
            // the counter we selected from the database - remove from the map because we used it. 
            ReferralCounter__c existingCtr = existingCountMap.remove(key);
            // compare and return the results
            ReferralCounter__c resultCounter = compareCounters(existingCtr, thisCtr);
            if (resultCounter != null) {
               soldCnt += resultCounter.X1YearSold__c;
               submittedCnt += resultCounter.X1YearAny__c;
            }
         } // for (String key : refSourceWrap
       
         refSourceWrap.submittedCount = submittedCnt;
         refSourceWrap.soldCount = soldCnt;
      } // if (refSourceWrap != null
	  
      
      // check the score on the sourceRec - see if different and update if necessary.
      Boolean sourceRecChanged = false;

      String curRefScore = (String)sourceRec.get(soldScoreFld);
      String curRefScoreSubmitted = (String)sourceRec.get(submittedScoreFld);
      Boolean hasRefType = String.isNotBlank(referralTypeFld);
      String curRefType = (hasRefType ? (String)sourceRec.get(referralTypeFld) : null);
                                              
      String cpaScore = null;
      String channelManaged = null;
      // get the current cpaScore
      if(sourceRec.getSObjectType() == Contact.sObjectType) {
         Contact ctct = (Contact)sourceRec;
         if(ctct.Mirror_Ref_Ctct__c != null) {
            cpaScore = ctct.Mirror_Ref_Ctct__r.CPA_Referral_Score__c;
         }
         if (ctct.Mirror_Ref_Ctct__c != null && ctct.Mirror_Ref_Ctct__r.Referral_Account__r != null) {
            channelManaged = (ctct.Mirror_Ref_Ctct__r.Referral_Account__r.Managed_by_Channel__c ? 'True' : 'False');
         }
      } else if (sourceRec.getSObjectType() == Account.sObjectType) {
         Account acct = (Account)sourceRec;
         if(acct.Mirror_Referral_Account__c != null) {
            cpaScore = acct.Mirror_Referral_Account__r.Best_CPA_Score_in_Firm__c;
            if (String.isNotBlank(cpaScore) && cpaScore.length() > 1) {
               // score on the account might be in the format F - ROBERT NAPRAVA - strip off the extra data
               cpaScore = cpaScore.left(1);
            }
            channelManaged = (acct.Mirror_Referral_Account__r.Managed_by_Channel__c ? 'True' : 'False');
        }
      }
      //String newRefScore = getScore(soldScoreBySourceMap.get(sourceRecReferralSource), soldCnt, cpaScore, channelManaged);
      //String newRefScoreSubmitted = getScore(submittedScoreBySourceMap.get(sourceRecReferralSource), submittedCnt, cpaScore, channelManaged);
      String newRefScore = getScore(scoreBySourceMap.get(sourceRecReferralSource), soldCnt, cpaScore, channelManaged);
      String newRefScoreSubmitted = getScore(scoreBySourceMap.get(sourceRecReferralSource), submittedCnt, cpaScore, channelManaged);
                  
      System.debug('compareExistingToNew sourceRec='+(String)sourceRec.get('Name')+' refSource='+sourceRecReferralSource+' soldCnt='+soldCnt+' submittedCnt='+submittedCnt+' curRefScore='+curRefScore+' newRefScore='+newRefScore+' curRefScoreSubmitted='+curRefScoreSubmitted+' newRefScoreSubmitted='+newRefScoreSubmitted);
      // see if one of the values has changed.
      if ((String.isNotBlank(newRefScore) && curRefScore != newRefScore) 
             || (String.isNotBlank(newRefScoreSubmitted) && curRefScoreSubmitted != newRefScoreSubmitted)
             || (hasRefType && curRefType != newRefScore)) {
         sourceRec.put(soldScoreFld,newRefScore);
         sourceRec.put(submittedScoreFld,newRefScoreSubmitted);
         if (hasRefType) {
            sourceRec.put(referralTypeFld, newRefScore);           
         } 
         sourceRecChanged = true;
      } // if ((String.isNotBlank

      return sourceRecChanged;
   } // compareExistingToNew

   // compare the two passed in counters
   public static ReferralCounter__c compareCounters(ReferralCounter__c existingCtr, ReferralCounter__c newCtr) {
      System.debug('compareCounters existingCtr='+existingCtr+' newCtr='+newCtr);
      ReferralCounter__c returnCounter = null;
      if (existingCtr == null && newCtr != null) {
         System.debug('compareCounters new counter');
         // we didn't have any values before but we do now so we'll insert a new one
         returnCounter = newCtr;
         counterInserts.add(newCtr);
      } else if (existingCtr != null && newCtr == null) {
         System.debug('compareCounters delete counter');
         // we did have a counter, but the latest count didn't find any referrals, so we'll delete this counter record (could have gone past the time limit)
         counterDeletes.add(existingCtr);
      } else if (existingCtr != null && newCtr != null) {
         System.debug('compareCounters update counter');
         returnCounter = existingCtr;
         // see if there are any changes to the record and update if needed. If no change don't need to update.
         if (areCountersDifferent(existingCtr, newCtr)) {
            setCounter1ToCounter2(existingCtr, newCtr);
            counterUpdates.add(existingCtr);
         }
      }
      if (returnCounter != null) {
         // add to the totals
         addToCounter(returnCounter, totalCounter);
      }
      return returnCounter;
   } // compareCounters
   
   public static String getScore(ReferralScoreSetup__c[] setups, Decimal nbrRfrls, String cpaScore, String channelManaged) {
      System.debug('getScore nbrRfrls='+nbrRfrls+' setups='+(setups != null ? setups.size() : -1) +' cpaScore='+cpaScore+' channelManaged='+channelManaged);
      String refScore = '';
      if (setups != null) {
         ReferralScoreSetup__c defaultSetup = null;
         for (ReferralScoreSetup__c rss : setups) {
            System.debug('getScore rss='+rss);
            if (rss.AllowBlankScore__c) {
               defaultSetup = rss;
            }
            if (rss.RangeMin__c <= nbrRfrls && rss.RangeMax__c >= nbrRfrls) {
               Boolean match = false;
               if (String.isNotBlank(rss.ReferralScore__c) 
                     && ((String.isNotBlank(cpaScore) && rss.ReferralScore__c.contains(cpaScore))
                         || (cpaScore == null && rss.AllowBlankScore__c))) {
                  match = true;
               } else if (String.isNotBlank(rss.ManagedByChannel__c) && rss.ManagedByChannel__c == channelManaged) {
                  match = true;
               } else if (String.isBlank(rss.ReferralScore__c) && String.isBlank(rss.ManagedByChannel__c)) {
                  match = true;
               }
               System.debug('getScore match='+match+' rss='+rss.Name);
               if(match) {
                  refScore = rss.ReferralType__c;
                  break;
               }
            } // if (rss.ReferralScore__c != null
         } // for (ReferralScoreSetup__c rss
         if (String.isBlank(refScore) && defaultSetup != null) {
            refScore = defaultSetup.ReferralType__c;
         }
      } // if (setups != null
      System.debug('getScore refScore='+refScore);
      return refScore;
   } // getScore
   //APR0147473-- BAU Jaipal Added Label check to make sure the units are counted as .5
   public static String[] halfUnitOppTypes = Label.ReferralScoreMethods_HalfUnitOppTypes.split(',');

   public static void addToCounter(Opportunity oppty, Referral__c ref, ReferralCounter__c counter, RefSourceWrapper refSourceWrap) {   
      Date submittedDate = (ref != null ? ref.CreatedDate.date() : (oppty != null ? oppty.CreatedDate.date() : null));
      Date soldDate = (oppty != null ? oppty.CloseDate : null);
      // take into account if the lead source indicates that we're counting the units
                  // new check on the end of this line
      Boolean usesUnits = (oppty != null && !leadSourcesDoNotUseUnits.contains(oppty.LeadSource) && !halfUnitOppTypes.contains(oppty.OpportunityType__c));
      Boolean soldWithUnits = (oppty!=null && oppty.isClosed && oppty.isWon && oppty.Payroll_Units__c != null && oppty.Payroll_Units__c > 0);
      Boolean soldNoUnits = (oppty!=null && oppty.isClosed && oppty.isWon);
                  // new variable
                  Boolean isSoldHalfUnit = (soldNoUnits && halfUnitOppTypes.contains(oppty.OpportunityType__c));
                  // updated variable definition	
      Boolean recSold = (isSoldHalfUnit || (usesUnits ? soldWithUnits : soldNoUnits));
      Boolean recNegSale = (oppty!=null && oppty.isClosed && oppty.isWon && oppty.Payroll_Units__c != null && oppty.Payroll_Units__c < 0);
      System.debug('addToCounter oppty='+(oppty != null ? oppty.Name : 'NoOpp')+' recSold='+recSold+' submittedDate='+submittedDate+' soldDate='+soldDate+' isSoldHalfUnit='+isSoldHalfUnit);
      
      if (counter != null && submittedDate != null) {
         
         if (refSourceWrap != null) {
            refSourceWrap.checkReferralDate(counter.ReferralSource2__c, submittedDate);
         }
         
         if (submittedDate >= year2) {
            counter.X2YearsAny__c++;
         } // if (checkDate >= year2
               
         if (submittedDate >= year1) {
            counter.X1YearAny__c++;
         } // if (oppty.CloseDate >= year1
         
         if (submittedDate >= months6) {
            counter.X6MonthsAny__c++;
         } // if (oppty.CloseDate >= months6
          
         if (oppty!=null && refSourceWrap != null && (counter.Latest_Opportunity_Date__c == null || counter.Latest_Opportunity_Date__c < submittedDate)) {
             counter.Latest_Opportunity_Date__c = submittedDate;
             counter.Latest_Opportunity__c = oppty.Id;
             refSourceWrap.latestOpptyDate = submittedDate;
             refSourceWrap.latestOppty = oppty.Id;
         }
         if(oppty!=null && refSourceWrap != null && (counter.Latest_Sold_Opportunity_Date__c == null || counter.Latest_Sold_Opportunity_Date__c < submittedDate) && recSold){
                 counter.Latest_Sold_Opportunity_Date__c = submittedDate;
                 counter.Latest_Sold_Opportunity__c = oppty.Id;
                 refSourceWrap.latestSoldOpptyDate = submittedDate;
                 refSourceWrap.latestSoldOppty = oppty.Id;
         }
         
      } // if (counter != null
         
      System.debug('addToCounter name='+(oppty != null ? oppty.Name : (ref != null ? ref.Name : 'NoName')) +' recSold='+recSold);
      
          
      if (counter != null && soldDate != null && (recSold || recNegSale)) {
                     // updated unit count
         Decimal nbrUnits = (usesUnits ? oppty.Payroll_Units__c : (isSoldHalfUnit ? .5 : 1));
          system.debug('nbrUnits'+nbrUnits+'usesUnits'+usesUnits+'oppty.Payroll_Units__c'+oppty.Payroll_Units__c+'isSoldHalfUnit'+isSoldHalfUnit);
         if (soldDate >= year2) {
            counter.X2YearsSold__c = counter.X2YearsSold__c +(recSold ?nbrUnits : (recNegSale ? (-1*nbrUnits) : 0));
         } // if (soldDate >= year2
               
         if (soldDate >= year1) {
            counter.X1YearSold__c = counter.X1YearSold__c +(recSold ? nbrUnits : (recNegSale ? (-1*nbrUnits) : 0));
         } // if (soldDate >= year1
         
         if (soldDate >= months6) {
            counter.X6MonthsSold__c = counter.X6MonthsSold__c +(recSold ? nbrUnits : (recNegSale ? (-1*nbrUnits) : 0));
         } // if (soldDate >= months6
         
      } // if (counter != null && soldDate != null
      
   } // addToCounter


   // set the values of counter1 to the values in counter2
   public static void setCounter1ToCounter2(ReferralCounter__c counter1, ReferralCounter__c counter2) {
      counter1.X6MonthsSold__c = counter2.X6MonthsSold__c;
      counter1.X6MonthsAny__c = counter2.X6MonthsAny__c;
      counter1.X1YearSold__c = counter2.X1YearSold__c;
      counter1.X1YearAny__c = counter2.X1YearAny__c;
      counter1.X2YearsSold__c = counter2.X2YearsSold__c;
      counter1.X2YearsAny__c = counter2.X2YearsAny__c;
      counter1.MutualClients__c = counter2.MutualClients__c;
      counter1.MutualAll__c = counter2.MutualAll__c;
      counter1.JobId__c = counter2.JobId__c;
      counter1.Latest_Opportunity_Date__c = counter2.Latest_Opportunity_Date__c;
      counter1.Latest_Opportunity__c = counter2.Latest_Opportunity__c;
      counter1.Latest_Sold_Opportunity_Date__c = counter2.Latest_Sold_Opportunity_Date__c;
      counter1.Latest_Sold_Opportunity__c = counter2.Latest_Sold_Opportunity__c;
   } // setCounter1ToCounter2
   
   public static Boolean areCountersDifferent(ReferralCounter__c counter1, ReferralCounter__c counter2) {
      Boolean changed = (counter1.X6MonthsSold__c != counter2.X6MonthsSold__c
                         || counter1.X6MonthsAny__c != counter2.X6MonthsAny__c
                         || counter1.X1YearSold__c != counter2.X1YearSold__c
                         || counter1.X1YearAny__c != counter2.X1YearAny__c
                         || counter1.X2YearsSold__c != counter2.X2YearsSold__c
                         || counter1.X2YearsAny__c != counter2.X2YearsAny__c
                         || counter1.MutualClients__c != counter2.MutualClients__c
                         || counter1.MutualAll__c != counter2.MutualAll__c
                         || counter1.Latest_Opportunity_Date__c != counter2.Latest_Opportunity_Date__c
                         || counter1.Latest_Opportunity__c != counter2.Latest_Opportunity__c
                         || counter1.Latest_Sold_Opportunity_Date__c != counter2.Latest_Sold_Opportunity_Date__c
                         || counter1.Latest_Sold_Opportunity__c != counter2.Latest_Sold_Opportunity__c
                        );
      System.debug('areCountersDifferent changed='+changed);
      return changed;
   } // areCountersDifferent
   
   public static void clearCounter(ReferralCounter__c counter, String jobId) {
      // only clear the counter if there isn't a jobId or the jobId changes
      if (String.IsBlank(jobId) || jobId != counter.JobId__c) {
         counter.X6MonthsSold__c = 0;
         counter.X6MonthsAny__c = 0;
         counter.X1YearSold__c = 0;
         counter.X1YearAny__c = 0;
         counter.X2YearsSold__c = 0;
         counter.X2YearsAny__c = 0;
         counter.MutualClients__c = 0;
         counter.MutualAll__c = 0;
         counter.JobId__c = jobId;
         counter.Latest_Opportunity_Date__c = null;
         counter.Latest_Opportunity__c = null;
         counter.Latest_Sold_Opportunity_Date__c = null;
         counter.Latest_Sold_Opportunity__c = null;
      }
   } // clearCounter 
   
   public static void addToCounter(ReferralCounter__c fromCounter, ReferralCounter__c p_totalCounter) {
      p_totalCounter.X6MonthsSold__c += fromCounter.X6MonthsSold__c;
      p_totalCounter.X6MonthsAny__c += fromCounter.X6MonthsAny__c;
      p_totalCounter.X1YearSold__c += fromCounter.X1YearSold__c;
      p_totalCounter.X1YearAny__c += fromCounter.X1YearAny__c;
      p_totalCounter.X2YearsSold__c += fromCounter.X2YearsSold__c;
      p_totalCounter.X2YearsAny__c += fromCounter.X2YearsAny__c;
      p_totalCounter.MutualClients__c += fromCounter.MutualClients__c;
      p_totalCounter.MutualAll__c += fromCounter.MutualAll__c;
   } // addToCounter

   public static Set<Id> contactIdSet = new Set<Id>();
  
   public static void checkTriggerBefore(Contact ctct, Contact oldCtct) {
      if (ctct.Id != null && ctct.CalculateScore__c) {
         contactIdSet.add(ctct.Id);
         ctct.CalculateScore__c = false;
      }
   } // checkTriggerBefore
   
   public static void processCtctTriggerBefore() {
      
   } // processCtctTriggerBefore
   
   public static void checkTriggerAfter(Contact ctct, Contact oldCtct) {
   
   } // checkTriggerAfter
   
   public static void processCtctTriggerAfter() {
      if (!contactIdSet.isEmpty()) {
         if (Test.isRunningTest()) {
            calcCtctScore(contactIdSet);
         } else {
            calcCtctScoreFuture(contactIdSet);
         }
         contactIdSet.clear();
      }
   } // processCtctTriggerAfter

   // ability to calculate the score for a single contact (or group of contacts) independent of the batch job   
   @future
   public static void calcCtctScoreFuture(Set<Id> ctctIdSet) {
      calcCtctScore(ctctIdSet);
   } // calcCtctScoreFuture

   public static void calcCtctScore(Set<Id> ctctIdSet) {
      System.debug('calcCtctScore ctctIdSet='+ctctIdSet.size());
      Contact[] ctcts = [Select Id
                                             ,Name
                                             ,LatestReferralDate__c
                                             ,PrimaryReferralType__c
                                             ,Referral_Type__c
                                             ,Referral_Contact__c
                                             ,ScoreRfrlsSold__c
                                             ,ScoreTotalRfrls__c
                                             ,AccountId
                                             ,Account.Id
                                             ,Account.Name
                                             ,Account.Referral__c
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
                                        Where Id in :ctctIdSet];
      if (!ctcts.isEmpty()) {
         processContacts(ctcts, 'future', true);
         // get the account ids. Run for the accounts
         Set<Id> acctIdSet = new Set<Id>();
         for (Contact ctct : ctcts) {
             if (ctct.AccountId != null) {
                acctIdSet.add(ctct.AccountId);
             }
         }
         calcAcctScore(acctIdSet);
      }
   } // calcCtctScore
    
   public static void calcAcctScore(Set<Id> acctIdSet) {
      System.debug('calcAcctScore acctIdSet='+acctIdSet.size());
      Account[] accts = [Select Id, Name
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
                                        Where Id in :acctIdSet];
      if (!accts.isEmpty()) {
         processAccounts(accts, 'future', true);
      }
   } // calcAcctScore
   
} // class ReferralScoreMethods