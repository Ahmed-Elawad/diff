/* 
 * A batch job for handling the referral scoring based on the opportunity
 *
 * History
 * -------
   07/12/2016 Dan Carmen   Created
 *
 */
global without sharing class ReferralScoreOppBatch   
                      //implements Database.Batchable<SObject>, Database.Stateful , Schedulable
                       {

   //global ReferralScoreOppBatch() {
   //} // ReferralScoreBatch

    /*
   // The time the process started.
   global DateTime startTime;
   // The total number of referral sources found. 
   global Integer referralSourcesFound = 0;
   // The number of differences found. 
   global Integer diffFound = 0;
   global Integer ctrsUpdated = 0;
   global Integer ctrsInserted = 0;
   global Integer ctrsDeleted = 0;
   global Integer nbrOpportunities = 0;
   global ReferralCounter__c totalCounter = new ReferralCounter__c();
      
   global JobHelper jh = new JobHelper('ReferralScoreOppBatch');

   // Default constructor.
   global ReferralScoreOppBatch() {
      startTime = DateTime.now();
      ReferralScoreMethods.clearCounter(totalCounter);
   } // ReferralScoreBatch

   public static Date year2 = Date.today().addMonths(-24);

   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.saveJob();

      // the id of the batch job
      Id batchJobId = BC.getJobId();
                                          
      // collect the lead sources of the opportunities
      Set<String> oppLeadSourceSet = new Set<String>();
      for(Lead_Source_for_Referrals__c ls: Lead_Source_for_Referrals__c.getAll().values()){
         if(ls.Lead_Source__c){
            oppLeadSourceSet.add(ls.value__c);
         }
      } // for(Lead_Source_for_Referrals__c
      System.debug('ReferralScoreOppBatch oppLeadSourceSet='+oppLeadSourceSet);
      
      return Database.getQueryLocator([Select Id
                                             ,Name
                                             ,LeadSource
                                             ,StageName, CloseDate
                                             ,Account.BIS_ID__c, Account.Lost_Date__c, Account.Type
                                             ,ReferralAccount__c
                                             ,ReferralAccount__r.Id
                                             ,ReferralAccount__r.Name
                                             ,ReferralAccount__r.Referral__c
                                             ,ReferralAccount__r.ReferralScore__c
                                             ,ReferralAccount__r.ReferralScoreSubmitted__c
                                             ,ReferralContact__c
                                             ,ReferralContact__r.Id
                                             ,ReferralContact__r.Name
                                             ,ReferralContact__r.Referral_Type__c
                                             ,ReferralContact__r.ReferralScore__c
                                             ,ReferralContact__r.ReferralScoreSubmitted__c
                                             ,Client_Referral__c
                                             ,Client_Referral__r.Id
                                             ,Client_Referral__r.Name
                                             ,Client_Referral__r.Referral__c
                                             ,Client_Referral__r.ReferralScore__c
                                             ,Client_Referral__r.ReferralScoreSubmitted__c
                                         From Opportunity
                                        Where LeadSource in :oppLeadSourceSet
                                          and CloseDate >= :year2
                                        order by ReferralAccount__c, ReferralContact__c]);
      
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      ReferralScoreOppBatch rsb = new ReferralScoreOppBatch();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('ReferralScoreOppBatch');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 2000);
      database.executeBatch(rsb, batchSize);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      Opportunity[] opps = (Opportunity[])scope;
      nbrOpportunities += opps.size();
      
      ReferralScoreMethods.processOpportunities(opps, BC.getJobId());
      
      ctrsUpdated += ReferralScoreMethods.nbrUpdates;
      ctrsInserted += ReferralScoreMethods.nbrInserts;
      ctrsDeleted += ReferralScoreMethods.nbrDeletes;
      //nbrOpportunities += ReferralScoreMethods.nbrOpportunities;
      ReferralScoreMethods.addToCounter(ReferralScoreMethods.totalCounter, totalCounter); 
   } // execute

   global void finish(Database.BatchableContext BC){
      String message = '\nTotal referral sources Processed: '+referralSourcesFound+' '; 
      message += '\nTotal Referral Types updated: '+diffFound+' ';
      message += '\nSold Opportunities checked from '+ReferralScoreMethods.year2.format();
      message += '\nNumber of Opportunities found: '+nbrOpportunities;
      message += '\n\nNumber of counters Updated: '+ctrsUpdated; 
      message += '\nNumber of counters Inserted: '+ctrsInserted; 
      message += '\nNumber of counters Deleted: '+ctrsDeleted; 
      message += '\n\nTotal Counter values: ';
      message += '\n6 Months Sold = '+totalCounter.X6MonthsSold__c;
      message += '\n6 Months Any = '+totalCounter.X6MonthsAny__c;
      message += '\n1 Year Sold ='+totalCounter.X1YearSold__c;
      message += '\n1 Year Any = '+totalCounter.X1YearAny__c;
      message += '\n2 Years Sold = '+totalCounter.X2YearsSold__c;
      message += '\n2 Years Any = '+totalCounter.X2YearsAny__c;
      message += '\nMutual Clients = '+totalCounter.MutualClients__c;
      
      // need a batch job to 
      //   1) clean up referral counters that do not have this batch id.
      //   2) Set the referral score on accounts and contacts that do not have a score.
      
      System.debug('ReferralScoreOppBatch finish message='+message);
      
      jh.completeJob(bc, 'Referral Type Update', message);
   } // finish
   */
} // class ReferralScoreOppBatch