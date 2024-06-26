/* 
 *  A batch job to make sure referral contacts are creating contacts   
 * History
 * -------
 * 06/16/2014 Josh Cartwright  created
 *  
 */

global with sharing class CheckReferralsBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
	
   global static final String CHECKREFERRALS_BATCH='CheckReferralsBatch';

   // The total number of purge records found.
   global Integer numberRecs = 0;
   
   // The total number of records purged
   global Integer numberRecsSuccess = 0;
   global Integer numberRecsError = 0;
   /** The time the process started. */
   global DateTime startTime;
   
   // messages that occur during the process. 
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper(CHECKREFERRALS_BATCH);
   
   // if we hit a limit, do we want to relaunch the batch job?
   global Boolean relaunchBatch = false;

  	
	global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      return Database.getQueryLocator([select id from Referral_Contact__c where Contact__c = null and Referral_Account__c != null and Referral_Account__r.name != 'Paychex Employees']);
   } // start
   
     // In order to schedule a batch run
   global void execute(SchedulableContext sc) { 
      CheckReferralsBatch crb = new CheckReferralsBatch();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CHECKREFERRALS_BATCH);
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 200);
      database.executeBatch(crb, batchSize);
   } // execute
   
	   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Referral_Contact__c> rcList = (List<Referral_Contact__c>)scope;
      numberRecs += rcList.size();
  //    Referral_Contact__c[] updateRecs = new Referral_Contact__c[]{};

      DmlHelper.performDML2(rcList, DmlHelper.DML_UPDATE, 'ChechReferralsBatch', 'execute', 'update the Referral records', true);
      system.debug('JC numberRecsSuccess ' + numberRecsSuccess + 'DmlHelper.performDmlResult.nbrSuccess ' + DmlHelper.performDmlResult.nbrSuccess  ); 
      numberRecsSuccess += DmlHelper.performDmlResult.nbrSuccess;
      numberRecsError += DmlHelper.performDmlResult.nbrError;
   } // execute
	
	
	   global void finish(Database.BatchableContext bc){
      String message = '\nTotal recors selected: '+numberRecs+' '; 
      message += '\nTotal records success: '+numberRecsSuccess+' '; 
      message += '\nTotal records error: '+numberRecsError+' '; 
      
      Integer nbrRemaining = [select count() from Referral_Contact__c where Contact__c = null and Referral_Account__c != null and Referral_Account__r.name != 'Paychex Employees' limit 10000];
      message += '\nTotal records remaining: '+nbrRemaining+' '; 
      //message += '\nTotal Users updated: '+nbrUsersUpdated+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'Check Referrals Batch', message);
      
      // see if we need to relaunch the process
      //if (relaunchBatch) {
      //   Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CHECKREFERRALS_BATCH);
      //   if (abc != null && abc.Active__c) {
      //      Database.executeBatch(new CheckReferralsBatch(), CheckReferralsBatch.BATCH_SIZE);
      //   } // if (abc != null
      //} // if (relaunchBatch
   } // finish
   
      public static void kickOffRefBatchJob()
    {  Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('CheckReferralsBatch');
      //if (abc != null && abc.Active__c && abc.IsJobScheduled__c == false) {
      if (abc != null && abc.Active__c 
               && (abc.Latest_Scheduled_Time__c == null || abc.Latest_Scheduled_Time__c < System.now()) ) {
         System.debug('JC here at kickOffBatchJob, scheduling Batch');
         scheduleBatchJob();
      }
      return;      
      
    } // kickOffBatchJob
   
   public static Id batchId = null;
   public static String scheduleName = null;
   public static Integer nbrMinutes = null;
   public static String SERVICE_NAME='ChecReferralBatch'; //JC added 
   
   
  //JC added for Referral Batch to catch referrals that werent converted to contacts 
    
   public static void scheduleBatchJob() {
      //need unique job name - only schedule to the minute so that only one job will be scheduled per minute.
      String rightNow = DateTime.now().format('yyyyMMddHHmmssSSS');
      try {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('CheckReferralsBatch');
        nbrMinutes = (abc != null && abc.Minutes_till_Launch__c != null ? abc.Minutes_till_Launch__c.intValue() : 5);
        
        scheduleName = SERVICE_NAME+rightNow;
        
        abc.Latest_Scheduled_Time__c = System.now().addMinutes(nbrMinutes);
        update abc;
        
         batchId = System.scheduleBatch(new CheckReferralsBatch(), scheduleName, nbrMinutes, abc.BatchSize__c.intValue());
         System.debug('scheduleBatchJob batchId='+batchId+' rightNow='+rightNow);
      } catch (Exception e) {
        System.debug('scheduleBatchJob exception: '+e.getStackTraceString());
      }
   } // scheduleBatchJob // JC end New code 
	
    
}