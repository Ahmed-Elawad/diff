/* 
 * Test methods for the PurgeBatch class
 *
 * History
 * -------
   05/26/2015 Dan Carmen   Created
   10/24/2017 Dan Carmen   Additional logging.
   10/22/2018 Dan Carmen   Extra functionality to log what the process is doing
   02/18/2019 Jermaine Stukes	Added archive test
   09/09/2020 Dan Carmen   Added extra criteria to Purge_Control__c creation
   02/17/2021 Dan Carmen        Option to purge the recycle bin
   04/22/2021 Dan Carmen        Change launchBatch method
   02/10/2023 Dan Carmen        Fix the TotalNbrRecordsPurged__c field calculation

 */
@isTest
public class PurgeBatchTest {

   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c  abc = new Apex_Batch_Control__c(Name=PurgeBatch.CLASSNAME,Active__c=True);
      insert abc;
      // this is here because there was a problem with deleting tasks and having them register correctly
      TriggerMethodsTest.createTriggerSetting('TaskAfter', false, true, false, true, new String[]{'ClientSpaceHelper'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData

   static testMethod void testBatch() {
      // create purge records
      PurgeControl__c purge1 = new PurgeControl__c(Name='Test1',ObjectAPIName__c='Job_Tracker__c',IsActive__c=true, NextRunTime__c=DateTime.now()
                                                  , DateFieldToCheck__c='Process_End__c',NbrDaysToKeep__c=30,ProcessType__c = PurgeBatch.PURGE
                                                  , AdditionalPurgeCriteria__c='Status__c=\'Completed\' ');
      
      PurgeControl__c purge2 = new PurgeControl__c(Name='Test2',ObjectAPIName__c='Web_Service_Log__c',IsActive__c=true, NextRunTime__c=DateTime.now()
                                                  , DateFieldToCheck__c='ServiceEnd__c',NbrDaysToKeep__c=30,ProcessType__c = PurgeBatch.PURGE
                                                  , AdditionalPurgeCriteria__c='Successful__c=true and SendMsg__c=false and ServiceName__c=\'Test Service1\' ');
      // test getting the maximum number of records in the batch and setting the MoreRecords__c field   
      PurgeControl__c purge3 = new PurgeControl__c(Name='Test3',ObjectAPIName__c='Web_Service_Log__c',IsActive__c=true, NextRunTime__c=DateTime.now()
                                                  , DateFieldToCheck__c='ServiceEnd__c',NbrDaysToKeep__c=30,ProcessType__c = PurgeBatch.PURGE
                                                  , AdditionalPurgeCriteria__c='Successful__c=true and SendMsg__c=true and ServiceName__c=\'Test Service2\' '
                                                  , BatchSize__c = 15);
      // no criteria
      PurgeControl__c purge4 = new PurgeControl__c(Name='Test4',ObjectAPIName__c='Job_Tracker__c',IsActive__c=true, NextRunTime__c=DateTime.now()
                                                  , DateFieldToCheck__c=null,NbrDaysToKeep__c=null,ProcessType__c = PurgeBatch.PURGE
                                                  , AdditionalPurgeCriteria__c=null);
       // bad criteria (Successfully__c instead of Successful__c)
       PurgeControl__c purge5 = new PurgeControl__c(Name='Test5',ObjectAPIName__c='Web_Service_Log__c',IsActive__c=true, NextRunTime__c=DateTime.now()
                                                    , DateFieldToCheck__c='ServiceEnd__c',NbrDaysToKeep__c=30,ProcessType__c = PurgeBatch.PURGE
                                                    , AdditionalPurgeCriteria__c='Successfully__c=true and SendMsg__c=true and ServiceName__c=\'Test Service2\' ');
       /*PurgeControl__c purge6 = new PurgeControl__c(Name='Test6',ObjectAPIName__c='Task',IsActive__c=true
                                                    , DateFieldToCheck__c='ActivityDate',NbrDaysToKeep__c=30, Archive__c=true ,ArchiveFrequency__c = 90
                                                   , AdditionalPurgeCriteria__c='IsRecurrence = false',ProcessType__c = 'Purge Only');*/
       PurgeControl__c[] purges = new PurgeControl__c[]{purge1,purge2,purge3,purge4,purge5};
           insert purges;
      
      // create test data
      // the number of records we will create for each case.
      Integer nbr_recs_success1 = 20;
      Integer nbr_recs_success2 = 15;
      Integer nbr_recs_success3 = 18;
      Integer nbr_recs_fail = 10;
      Date keepDate = Date.today().addDays(-30);
      DateTime inRangeDT = Datetime.now();
      DateTime outOfRangeDT = Datetime.now().addDays(-40);
      Job_Tracker__c[] newJobTrackers = new Job_Tracker__c[]{};
      // create records to be purged by Test1
      for (Integer cnt=0; cnt<nbr_recs_success1; cnt++) {
         newJobTrackers.add(new Job_Tracker__c(Job_Name__c='Test1',Process_Start__c=outOfRangeDT, Process_End__c=outOfRangeDT, Nbr_Batches__c=cnt, Status__c='Completed'));
      }
      // create records that will not be purged based on date
      for (Integer cnt=0; cnt<nbr_recs_fail; cnt++) {
         newJobTrackers.add(new Job_Tracker__c(Job_Name__c='Test1',Process_Start__c=inRangeDT, Process_End__c=inRangeDT, Nbr_Batches__c=cnt, Status__c='Completed'));
      }
      // create records that will not be purged based on status
      for (Integer cnt=0; cnt<nbr_recs_fail; cnt++) {
         newJobTrackers.add(new Job_Tracker__c(Job_Name__c='Test1',Process_Start__c=outOfRangeDT, Process_End__c=outOfRangeDT, Nbr_Batches__c=cnt, Status__c='Bad Status'));
      }
      insert newJobTrackers;
      System.assertEquals(newJobTrackers.size(), [select count() from Job_Tracker__c]);
      
      Web_Service_Log__c[] newWSLs = new Web_Service_Log__c[]{};
      // create records to be purged by Test2
      for (Integer cnt=0; cnt<nbr_recs_success2; cnt++) {
         newWSLs.add(new Web_Service_Log__c(ServiceName__c='Test Service1', ServiceEnd__c=outOfRangeDT, Successful__c=true, SendMsg__c=false));
      } 
      // create records to be purged by Test3
      for (Integer cnt=0; cnt<nbr_recs_success3; cnt++) {
         newWSLs.add(new Web_Service_Log__c(ServiceName__c='Test Service2', ServiceEnd__c=outOfRangeDT, Successful__c=true, SendMsg__c=true));
      } 
      // create records that will not be purged based on date
      for (Integer cnt=0; cnt<nbr_recs_fail; cnt++) {
         newWSLs.add(new Web_Service_Log__c(ServiceName__c='Test Service1', ServiceEnd__c=inRangeDT, Successful__c=true, SendMsg__c=false));
      } 
      // create records that will not be purged based additional criteria
      for (Integer cnt=0; cnt<nbr_recs_fail; cnt++) {
         newWSLs.add(new Web_Service_Log__c(ServiceName__c='Test Service2', ServiceEnd__c=outOfRangeDT, Successful__c=false, SendMsg__c=true));
      } 
      insert newWSLs;
      System.assertEquals(newWSLs.size(), [select count() from Web_Service_Log__c]);
      // create records to be purged by Test6
      User payU = [Select Id from User where Sales_Org__c = 'PAY' and IsActive=true limit 1];
     // create an Opportunity
      Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addMonths(1), StageName='Pending');
      insert opp;
       Task[] newTasks = new Task[]{};
      for (Integer cnt=0; cnt<nbr_recs_success1; cnt++) {
         newTasks.add(new Task(Subject='Task6',OwnerId=payU.Id, ActivityDate=Date.today().addDays(-50), WhatId=opp.Id, IsRecurrence = false));
      }

       insert newTasks;
      PurgeBatch pb = new PurgeBatch();
      Test.startTest();
      Database.executeBatch(pb,purges.size());
      Test.stopTest();

      // verify remaining counts
      Integer remainingJobTrackers = newJobTrackers.size() - nbr_recs_success1;
      System.assertEquals(remainingJobTrackers,[select count() from Job_Tracker__c where Job_Name__c='Test1']);
      Integer remainingWSLs = newWSLs.size() - nbr_recs_success2 - Integer.valueOf(purge3.BatchSize__c);
      System.assertEquals(remainingWSLs, [select count() from Web_Service_Log__c]);

      Map<Id,PurgeControl__c> pcMap = getPurgeControlMap();
      
      // verify tracker records are created for each
      purge1 = pcMap.get(purge1.Id);
      System.assertEquals(true,purge1.IsActive__c);
      System.assertEquals(false,purge1.MoreRecords__c);
      System.assertEquals(1,purge1.PurgeControlTrackers__r.size());
      System.assertEquals(nbr_recs_success1,purge1.PurgeControlTrackers__r[0].NbrRecsPurged__c);
      System.assertEquals(keepDate,purge1.PurgeControlTrackers__r[0].PurgeDate__c);
      
      purge2 = pcMap.get(purge2.Id);
      System.assertEquals(true,purge2.IsActive__c);
      System.assertEquals(false,purge2.MoreRecords__c);
      System.assertEquals(1,purge2.PurgeControlTrackers__r.size());
      System.assertEquals(nbr_recs_success2,purge2.PurgeControlTrackers__r[0].NbrRecsPurged__c);
      System.assertEquals(keepDate,purge2.PurgeControlTrackers__r[0].PurgeDate__c);

      purge3 = pcMap.get(purge3.Id);
      System.assertEquals(true,purge3.IsActive__c);
      System.assertEquals(true,purge3.MoreRecords__c);
      System.assertEquals(1,purge3.PurgeControlTrackers__r.size());
      //System.assertEquals(nbr_recs_success3,purge3.PurgeControlTrackers__r[0].NbrRecsPurged__c);
      System.assertEquals(purge3.BatchSize__c, purge3.PurgeControlTrackers__r[0].NbrRecsPurged__c);
      System.assertEquals(purge3.BatchSize__c, purge3.PurgeControlTrackers__r[0].NbrFound__c);
      System.assertEquals(0, purge3.PurgeControlTrackers__r[0].NbrFailed__c);
      System.assertEquals(keepDate,purge3.PurgeControlTrackers__r[0].PurgeDate__c);

      purge4 = pcMap.get(purge4.Id);
      System.assertEquals(false,purge4.IsActive__c);
      System.assertEquals(0,purge4.PurgeControlTrackers__r.size());
      System.assertEquals(true,purge4.ProcessNotes__c.contains('Purge criteria could not be found'));

      purge5 = pcMap.get(purge5.Id);
      System.assertEquals(false,purge5.IsActive__c);
      System.assertEquals(1,purge5.PurgeControlTrackers__r.size());
      System.assertEquals(0,purge5.PurgeControlTrackers__r[0].NbrRecsPurged__c);
      System.assertEquals(keepDate,purge5.PurgeControlTrackers__r[0].PurgeDate__c);
      System.assertEquals(true,purge5.ProcessNotes__c.contains('Error in query'));
       
     /* purge6 = getPurgeControl(purge6.Id);
       System.assertEquals(true,purge6.IsActive__c);
       System.assertEquals(1,purge6.PurgeControlTrackers__r.size());*/
   } // testBatch
   
    static testMethod void testArchiveBatch() {

      
      // create test data
      // the number of records we will create for each case.
      Integer nbr_recs_success1 = 20;
      //Date keepDate = Date.today().addDays(-30);

      // create records to be purged by Test6
      User payU = [Select Id from User where Job_Name__c=:UserHelper.JOB_REP and IsActive=true limit 1];
     // create an Opportunity
      Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addMonths(1), StageName='Pending');
      insert opp;
       Task[] newTasks = new Task[]{};
      for (Integer cnt=0; cnt<nbr_recs_success1; cnt++) {
         newTasks.add(new Task(Subject='Task6',OwnerId=payU.Id, ActivityDate=Date.today().addDays(-50), WhatId=opp.Id, IsRecurrence = false));
      }
       insert newTasks;
        
              // create purge records
        PurgeControl__c purge = new PurgeControl__c(Name='Test6',ObjectAPIName__c='Task',IsActive__c=true, ProcessType__c=PurgeBatch.ARCHIVE
                                                    , DateFieldToCheck__c='ActivityDate',NbrDaysToKeep__c=30, NextRunTime__c=DateTime.now() );
        insert purge;
        PurgeControl__c purgeData = [Select Id,RelaunchBatch__c from PurgeControl__c where Id=:purge.Id];
        System.assertEquals(true,purgeData.RelaunchBatch__c);
        PurgeBatch pb = new PurgeBatch();
        test.startTest();
        //Database.executeBatch(pb,1);
        PurgeBatch.launchBatch();
        test.stopTest();
        
        Map<Id,PurgeControl__c> pcMap = getPurgeControlMap();
        
        purge = pcMap.get(purge.Id);
        System.assertEquals(true,purge.IsActive__c);
        System.assertEquals(1,purge.PurgeControlTrackers__r.size());
        PurgeControlTracker__c pct = purge.PurgeControlTrackers__r[0];
        System.assertEquals(nbr_recs_success1, pct.NbrFound__c);
        System.assertEquals(nbr_recs_success1, pct.NbrRecsPurged__c);
        System.assertEquals(0, pct.NbrFailed__c);
    } // testArchiveBatch
   
   public static Map<Id,PurgeControl__c> getPurgeControlMap() {
      Map<Id,PurgeControl__c> pcMap = new Map<Id,PurgeControl__c>([select Id, Name
                                             ,AdditionalPurgeCriteria__c
                                             ,ArchiveFrequency__c
                                             ,BatchSize__c
                                             ,DateFieldToCheck__c
                                             ,EmailBody__c
                                             ,EmailNotification__c
                                             ,IsActive__c
                                             ,LatestQuery__c
                                             ,MoreRecords__c
                                             ,NbrDaysToKeep__c
                                             ,Next_Archive_Date__c
                                             ,ProcessCheckMinRecs__c
                                             ,ProcessCheckMaxRecs__c
                                             ,ProcessNotes__c
                                             ,ProcessType__c
                                             ,ObjectAPIName__c
                                             ,RelaunchBatch__c
                                             ,TotalRecordsPurged__c
                                             ,(Select Id, Name, NbrRecsPurged__c, OutsideRange__c, PurgeDate__c
                                                     ,NbrFound__c, NbrFailed__c
                                                 from PurgeControlTrackers__r)
                                         From PurgeControl__c]);
      return pcMap;
   } // getPurgeControlMap
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testPurgeBatch', new PurgeBatch());
   } // testScheduler
   
   static testMethod void testPurgeSingle() {
      Task[] newTasks = new Task[]{};
      for (Integer cnt=0; cnt<20; cnt++) {
         newTasks.add(new Task(Subject='Task'+cnt, ActivityDate=Date.today().addDays(-50), IsRecurrence = false));
      }
      insert newTasks;
        
      // create purge record - set the batch size for half the number we created
      PurgeControl__c purge = new PurgeControl__c(Name='testPurgeSingle',ObjectAPIName__c='Task',IsActive__c=true, ProcessType__c=PurgeBatch.PURGE
                                                    , DateFieldToCheck__c='ActivityDate',NbrDaysToKeep__c=30, AllowRunAnytime__c=true,BatchSize__c=(newTasks.size()/2) );
      insert purge;

      Test.startTest();
      PurgeSingle.doPost(1);
      Test.stopTest();
       
      System.assertEquals(10,[select count() from Task]);
   } // testPurgeSingle

   static testMethod void testEmptyRecycleBin() {
      // create purge record
      PurgeControl__c purge = new PurgeControl__c(Name='testPurgeSingle',ObjectAPIName__c='Task',IsActive__c=true, ProcessType__c=PurgeBatch.EMPTY_BIN
                                                    , DateFieldToCheck__c='LastModifiedDate',NbrDaysToKeep__c=-1, BatchSize__c=100, NextRunTime__c=DateTime.now() );
      insert purge;
     
      Task[] newTasks = new Task[]{};
      for (Integer cnt=0; cnt<10; cnt++) {
         newTasks.add(new Task(Subject='Task'+cnt, ActivityDate=Date.today().addDays(-50), IsRecurrence = false));
      }
      insert newTasks;
      delete newTasks;
      // verify they're in the recycle bin
      Task[] testDeleted = [Select Id from Task where IsDeleted=true ALL ROWS];
      System.assertEquals(10,testDeleted.size());

      PurgeBatch pb = new PurgeBatch();
      test.startTest();
      PurgeBatch.launchBatch();
      test.stopTest();
       
      Map<Id,PurgeControl__c> pcMap = getPurgeControlMap(); 
      purge = pcMap.get(purge.Id);
      System.assertEquals(10,purge.TotalRecordsPurged__c);
       
      testDeleted = [Select Id from Task where IsDeleted=true ALL ROWS];
      //System.assertEquals(0,testDeleted.size());
   } // testEmptyRecycleBin
    
} // class PurgeBatchTest