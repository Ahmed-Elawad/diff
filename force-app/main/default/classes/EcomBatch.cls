/* 
   Batch job for working with Data in a batch.
   
  EcomBatch.launchBatch();

  Apex_Batch_Control__c setup
  Name: EcomBatch
  Active: true
  Batch Title: Ecom Batch
  Nbr of Attempts: 5 (how many times it will check ecom records before giving up)
  Batch Size: 1  (how many Ecom records the batch will process at a time. Should be 1 due to mixed DML operations)
  Minutes till Launch: 2  (how many minutes until it checks the records again)
  Check Days: 2 how much we increase the Minutes till launch interval during non business hours.

  History
  -------
  04/02/2021 Dan Carmen      Created
  08/10/2021 Dan Carmen      Change to always run
  09/20/2023 Dan Carmen      Added a check for the next launch time to make sure it's not greater than the interval set in the custom setting.

 */
global with sharing class EcomBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable  {
   public static String CLASSNAME='EcomBatch';

   global JobHelper jh = new JobHelper(CLASSNAME);

   global EcomBatch() {
   } // DataLoadBatch3

   global void execute(SchedulableContext SC) {
      launchBatch();
   } // execute

   global Database.QueryLocator start(Database.BatchableContext BC){
      jh = new JobHelper(CLASSNAME);
      // the query for the dataload object
      jh.tracker.Nbr_Batches__c=0;
      String query = ObjectHelper.getSOQLQuery('Ecommerce__c', null, false, false, false, false, false);
      Datetime runTime = DateTime.now();
      query += ' Where Processed__c=false and CheckTime__c <= :runTime order by SortOrder__c ASC, CreatedDate ASC ';
      System.debug('start query='+query);
      return Database.getQueryLocator(query);
   } // start
    
   //global DataLoad__c submitDataLoad = null;
   
   global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {

      // the expectation is to only process one record at a time
      Ecommerce__c[] ecoms = (Ecommerce__c[])scope;
      Apex_Batch_Control__c abc = getBatchControl();
      jh.tracker.Nbr_Batches__c = ecoms.size();
      jh.addToNotes2('ecoms='+ecoms.size()+' abc active='+(abc != null && abc.Active__c ? 'True' : 'False'));
      String[] ceidsCaids = new String[]{};
      if (abc.Active__c) {
         Integer maxAttempts = (abc.NbrOfAttempts__c != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 2);
         Integer numMinutes = (abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 2);
         for (Ecommerce__c ecom : ecoms) {
            // set the next interval, just in case
            ecom.CheckCount__c = (ecom.CheckCount__c != null ? ecom.CheckCount__c+1 : 1);
            ecom.CheckTime__c = (ecom.CheckCount__c <= maxAttempts ? Datetime.now().addMinutes(numMinutes) : null);
            if (String.isNotBlank(ecom.MktgId__c)) {
               if (String.isNotBlank(ecom.CAID__c)) {
                   ceidsCaids.add(ecom.CAID__c);
               }
               if (String.isNotBlank(ecom.CEID__c)) {
                   ceidsCaids.add(ecom.CEID__c);
               }
            } // if (!ecom.IsFlexForm__c
         } // for
      } // if (abc.Active__c
      EcomMethods.processEcoms(ecoms);
      // see if there are other records to process. If the flex forms are entered before the lead comes over, we only mark the ones with a MktgId__c to process again
      jh.addToNotes2('ceidsCaids='+ceidsCaids.size());
      if (!ceidsCaids.isEmpty()) {
          Ecommerce__c[] checkEcoms = [Select Id, CheckCount__c,CheckTime__c, Processed__c
                                    From Ecommerce__c
                                   where Processed__c=false
                                     and CheckTime__c=null
                                     and MktgId__c=null
                                     and (CAID__c in :ceidsCaids or CEID__c in :ceidsCaids)];
          jh.addToNotes2('checkEcoms='+checkEcoms.size());
          for (Ecommerce__c ecom : checkEcoms) {
             ecom.CheckTime__c=Datetime.now();
             ecom.CheckCount__c=0;
          }
          if (!checkEcoms.isEmpty()) {
             //TriggerMethods.SKIP_TRIGGERS=true;
             update checkEcoms;
             //TriggerMethods.SKIP_TRIGGERS=false;
          }
      }
   } // execute
    
   global void finish(Database.BatchableContext batchableContext){
       // check to see if there are any more ecommerce records that need to be processed. 
       launchNotes='';
       if ( !Test.isRunningTest()) {
          launchBatch();
       }
       jh.addToNotes2(launchNotes);
       jh.tracker.Process_End__c = Datetime.now();
       jh.tracker.Status__c = JobHelper.STATUS_COMPLETED;
       jh.saveJob();
   } // finish
    
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      return abc;
   } // getBatchControl
    
   public static String launchNotes='';
 
   public static void launchBatch() {
      // see if there are any records available to run - get the earliest time 
      Ecommerce__c[] ecoms = [select Id, CheckTime__c from Ecommerce__c Where Processed__c=false and CheckTime__c != null order by CheckTime__c ASC limit 1 ];
      Apex_Batch_Control__c abc = getBatchControl();
      Datetime nextLaunchTime = (ecoms.size() > 0 ? ecoms[0].CheckTime__c : null);
      Datetime abcNextLaunch = ((abc != null && abc.Active__c && abc.Minutes_till_Launch__c != null) ? getNextLaunchTime(abc) : null);
      // make sure we don't schedule for a larger gap than what's in the custom setting
      if (nextLaunchTime == null || (nextLaunchTime != null && abcNextLaunch != null && abcNextLaunch < nextLaunchTime)) {
         nextLaunchTime = abcNextLaunch;
      }
      launchNotes = 'launchBatch ecoms='+ecoms.size()+' nextLaunchTime='+(nextLaunchTime != null ? nextLaunchTime.format('M/d/yyyy H:mm:ss') : 'null');
      //if (nextLaunchTime == null && abc != null && abc.Active__c && abc.Minutes_till_Launch__c != null) {
      //   nextLaunchTime = getNextLaunchTime(abc);
      //}
      //launchNotes += ' after abc check nextLaunchTime='+(nextLaunchTime != null ? nextLaunchTime.format('M/d/yyyy H:mm:ss') : 'null');
      System.debug('launchBatch ecoms='+ecoms.size()+' abc minutes='+(abc != null ? abc.Minutes_till_Launch__c : -1)+' nextLaunchTime='+nextLaunchTime);
      if (nextLaunchTime != null) {
         JobHelper.launchBatchWithSchedule(new EcomBatch(), CLASSNAME, nextLaunchTime, 1);
      }
      //if (ecoms.size() > 0) {
      //   JobHelper.launchBatchWithSchedule(new EcomBatch(), CLASSNAME, ecoms[0].CheckTime__c, 1);
      //} // if (nbrRecs > 0
       
   } // launchBatch
    
   public static Datetime getNextLaunchTime(Apex_Batch_Control__c abc) {
      // see if we're within business hours
      BusinessHours busHours = DG_LMF_Service.getBusinessHours(SLAHelperBatch.BATCH);
      Boolean inBusHours = (busHours == null || (busHours != null && BusinessHours.isWithin(busHours.Id, Datetime.now())));
      // if we're outside of business hours use a larger interval
      Integer intervalMultiplier = (inBusHours ? 1 : (abc.Check_Days__c != null ? Integer.valueOf(abc.Check_Days__c) : 2));
      Integer minutesTillNext = (abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 1) * intervalMultiplier;
      Datetime nextLaunchTime = Datetime.now().addMinutes(minutesTillnext);
      return nextLaunchTime;
   } // getNextLaunchTime

} // class EcomBatch