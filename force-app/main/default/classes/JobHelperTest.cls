/* 
 * Test Methods for the JobHelper class
 *
 * History
 * -------
 * 06/28/2012 Dan Carmen   Created
   03/27/2013 Dan Carmen   Modified to complete job from a non-batch scheduled job
   01/28/2014 Dan Carmen   Updated status in completeJob.
   04/28/2015 Dan Carmen   Save notes as an attachment if they're too long.
   08/02/2017 Dan Carmen   Add ability to add to notes (not just at the end)
   08/20/2018 Cindy Freeman     added test for Files and not just Attachments
   01/13/2021 Dan Carmen        Add methods to help manage scheduled and batch jobs
   08/16/2021 Dan Carmen        Add addToNotes2 
   10/26/2021 Dan Carmen        Update job scheduler to not perform the checks for existing jobs during a test run.
   05/16/2023 Dan Carmen        Update scheduleBatch to not always add 1 minute to the schedule time

*/
@isTest
private class JobHelperTest {

   static testMethod void testHelperNoEmail() {
    // verify no Job_Tracker__c object
    System.assertEquals(0,[Select count() from Job_Tracker__c]);
    
      // run a batch process - should be nothing to run
      ZipBatch zb = new ZipBatch();

      // run process
      Test.startTest();
      Database.executeBatch(zb,10);
      Test.stopTest();
      
      // verify 1 Job_Tracker__c object
      System.assertEquals(1,[Select count() from Job_Tracker__c]);
      
   } // testHelperNoEmail
   
   static testMethod void testHelperWithEmail() {
    // create the record to send the emails
    Apex_Batch_Control__c config = new Apex_Batch_Control__c(Name='ZipBatchTest',SendCompletionEmail__c=true);
    insert config;
    
      // verify no Job_Tracker__c object
      System.assertEquals(0,[Select count() from Job_Tracker__c]);
      
      // run a batch process - should be nothing to run
      ZipBatch zb = new ZipBatch();

      // run process
      Test.startTest();
      Database.executeBatch(zb,10);
      Test.stopTest();
      
      // verify 1 Job_Tracker__c object
      System.assertEquals(1,[Select count() from Job_Tracker__c]);
      
   } // testHelperWithEmail
   
   static testMethod void testMiscellaneous() {
      // setup the batch control
      Apex_Batch_Control__c batchControl = new Apex_Batch_Control__c(Name='Test Job', SaveAttachments__c=true, SendCompletionEmail__c=true);
      insert batchControl;
      
      JobHelper jh = new JobHelper(batchControl.Name);
      System.assertEquals(JobHelper.STATUS_STARTED, jh.tracker.Status__c);
      
      jh.setScheduled();
      System.assertEquals(JobHelper.STATUS_SCHEDULED, jh.tracker.Status__c);
      
      jh.setStarted();
      System.assertEquals(JobHelper.STATUS_STARTED, jh.tracker.Status__c);

      // add some logging and complete the job
      ChangeLog.addToLog('123', 'Field1', 'Value1');      
      ChangeLog.addToLog('124', 'Field2', 'Value2');      
      ChangeLog.addToLog('125', 'Field3', 'Value3');  
      
      String notes = 'Here are some test notes';
      // make the notes longer than the size of the field so that it should create an attachment.
      while (notes.length() <= JobHelper.NOTES_SIZE) {
         notes += '\nThe quick brown fox jumped over the lazy dog.';
      }
      
      Attachment attach = new Attachment(ParentId = null, Name='extendedNotes.txt'
                               ,Body=Blob.valueOf(notes), ContentType='text');
      jh.addAttachmentsToJob(new Attachment[] {attach});
         
      String logFile = 'Some text to put into a file.  This is a TEST.  I hope it works';
      Blob csvBlob = Blob.valueOf(logFile);
      String rightNow = DateTime.now().format('yyyyMMddHHmmss');
      String fileName= 'JobHelperTest.'+rightNow+'.csv';
      FileWrapper fw = new FileWrapper(null, fileName, fileName, null, csvBlob);        
      jh.addFilesToJob(new FileWrapper[]{fw});    
         
      jh.completeJob('TestJob', notes);
      System.assertEquals(1,[Select count() from Job_Tracker__c where Job_Name__c=:batchControl.Name and Status__c=:JobHelper.STATUS_COMPLETED]);
      System.assertEquals(1,[select count() from Attachment where ParentId=:jh.tracker.Id]);
      System.assertEquals(3,[select count() from ContentDocumentLink where LinkedEntityId = :jh.tracker.Id]);
      
       
      jh = new JobHelper(batchControl.Name);
      jh.addToNotes2('These are new notes');
      System.assertEquals(true,jh.tracker.Notes__c.contains('These are new notes'));
   } // testMiscellaneous
    
   static testMethod void testScheduled() {
      System.assertEquals(0,JobHelper.getNbrRunningBatches('ThisIsABadName'));
      System.assertEquals(false,JobHelper.isScheduledOkay('ThisIsABadName', Datetime.now()));
      Test.startTest();
      // to test the scheduler
      PurgeBatch pb = new PurgeBatch();
      Datetime nextRunTime = Datetime.now().addDays(14);
      String jobId = JobHelper.scheduleBatch(pb, PurgeBatch.CLASSNAME, nextRunTime, 1);
      System.assertNotEquals(null,jobId);
      // check a day later - shouldn't have to schedule
      System.assertEquals(true,JobHelper.isScheduledOkay(PurgeBatch.CLASSNAME, nextRunTime.addDays(1)));
      System.abortJob(jobId);
      Test.stopTest();
   } // testScheduled

   static testMethod void testScheduled2() {
      PurgeBatchTest.setupData();
      Test.startTest();
      // to test the scheduler
      PurgeBatch pb = new PurgeBatch();
      Datetime nextRunTime = Datetime.now().addDays(14);
      String jobId = JobHelper.launchBatchWithSchedule(pb, PurgeBatch.CLASSNAME, nextRunTime, 1);
      //System.assertNotEquals(null,jobId);
      // check a day later - shouldn't have to schedule
      //System.assertEquals(true,JobHelper.isScheduledOkay(PurgeBatch.CLASSNAME, nextRunTime.addDays(1)));
      //System.abortJob(jobId);
      Test.stopTest();

   } // testScheduled2

} // class JobHelperTest