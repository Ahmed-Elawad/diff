/** Utilities for running Test Methods
   To execute from Execute Anonymous window
   TestClassJob tcj =new TestClassJob();
   tcj.execute(null);
 *
 * History
 * -------
   08/01/2017 Dan Carmen        Created
   09/26/2019 Jake Hinds        Adding way to cancel running tests if taking too long
   06/16/2020 Cindy Freeman     Added method to send separate email for specific test results
   01/05/2021 Dan Carmen        Add time to result email, increment API version
   01/19/2021 Dan Carmen        Fix for NPE

 */
global with sharing class TestClassJob implements Schedulable {
   global TestClassJob() {
      startTime = Datetime.now();
   } // TestClassJob
  
   global Datetime startTime = Datetime.now();

   // launch the tests
   public static String MODE_LAUNCH='Launch Tests';
   // check to see if the tests are done and what their status is
   public static String MODE_CHECK='Check Tests';
   
   global TestClassJob (Id[] p_jobIds, Integer p_attemptNbr, Datetime p_startTime) {
      jobIds = p_jobIds;
      attemptNbr = p_attemptNbr;
      startTime = p_startTime;
      curMode = MODE_CHECK;
   }
   
   global Id[] jobIds = null;
   
   global Integer attemptNbr = 0;
   
   global String curMode = MODE_LAUNCH;
   
   global void execute(SchedulableContext SC) {
      System.debug('TestClassJob.execute curMode='+curMode);
      try {
         if (curMode == MODE_LAUNCH) {
            jobIds = enqueueTests();
            if (!Test.isRunningTest()) {
               scheduleTestJob();
            }
         } else if (curMode == MODE_CHECK) {
            areTestsComplete();
         }
      } catch (Exception e) {
         ErrorLog.logError('TestClassJob', 'execute', 'General Exception', null, e.getMessage()+'; '+e.getStackTraceString(), null, true);

      }
   } // execute
   
   public static Integer INTERVAL_MINUTES=Integer.valueOf(Label.TestClassJob_Interval);
   
   // schedule the job to run in the future to check if the tests are complete
   global void scheduleTestJob() {
      // Re-schedule ourself to run again in "intervalMinutes" time
      DateTime now  = DateTime.now();
      DateTime nextRunTime = now.addMinutes(INTERVAL_MINUTES);
      String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
      System.schedule(TestClassJob.class.getName() + '-' + now.format(), cronString, new TestClassJob(jobIds, attemptNbr+1, startTime));
   } // scheduleTestJob
   

   public static Integer TEST_LIMIT=2000;
   public static Integer TEST_ATTEMPT_LIMIT = Integer.valueOf(Label.TestClassJob_Attempt_Limit);
   public static String NAME_COMPARE='%Test%';

   // Enqueue all classes ending in "Test". 
   public ID[] enqueueTests() {
       
      Id[] parentJobIds = new Id[]{};
      String testClassList = 'Test Classes Queued: ';
      Integer totalClasses = 0;
      for (ApexClass[] testClasses : [SELECT Id, Name 
                                   FROM ApexClass 
                                   WHERE Name LIKE :NAME_COMPARE
                                          AND NameSpacePrefix = null
                                   ORDER BY Name
                                   limit :TEST_LIMIT]) {
                                   // used for testing
                                   // WHERE (Name = 'AccountBeforeTest' OR Name = 'AccountChatterUpdateTest' or Name = 'AccountCheckContactEmailTest')
                                   // AND NameSpacePrefix = null
                                   // ORDER BY Name]) {
         totalClasses += testClasses.size();
         ApexTestQueueItem[] queueItems = new List<ApexTestQueueItem>();
         for (ApexClass cls : testClasses) {
            testClassList += '\n'+cls.Name;
            queueItems.add(new ApexTestQueueItem(ApexClassId=cls.Id));
         }
         ApexTestQueueItem item = null;
         if (!Test.isRunningTest()) {
            insert queueItems;

            // Get the job ID of the first queue item returned.
            item = [SELECT ParentJobId FROM ApexTestQueueItem WHERE Id=:queueItems[0].Id LIMIT 1];
         } else {
            item = new ApexTestQueueItem();
         }
         parentJobIds.add(item.parentjobid);
         testClassList += '\n\nParent Job Id: '+item.parentjobid;
         //System.debug('enqueueTests testClassList='+testClassList);
         
      } // for (ApexClass[] testClasses
      JobHelper jh = new JobHelper('TestClassJob-Enqueue');
      jh.tracker.Process_Start__c = startTime;
      jh.completeJob('TestClassJob-Enqueue Tests Complete', testClassList);
         
      return parentJobIds;
   } // enqueueTests

   // are all of the tests complete?
   global void areTestsComplete() {
      JobHelper jh = new JobHelper('TestClassJob-Waiting');
      jh.tracker.Process_Start__c = startTime;
      jh.addToNotes('JobIds='+jobIds);
      Boolean classesComplete = checkClassStatus(jobIds, jh,attemptNbr);
      if (!classesComplete && attemptNbr < TEST_ATTEMPT_LIMIT) {
         jh.completeJob('TestClassJob-Tests Not Complete','Waiting on tests');
         // reschedule the check
         if (!Test.isRunningTest()) {
            scheduleTestJob();
         }
      } else if(!classesComplete && attemptNbr == TEST_ATTEMPT_LIMIT){
         ApexTestQueueItem[] unfinishedTests = [SELECT Id FROM ApexTestQueueItem WHERE ParentJobId in :jobIds AND Status IN ('Holding','Queued','Preparing','Processing')];
         if(unfinishedTests!=null && !unfinishedTests.isEmpty()){
            for(ApexTestQueueItem test: unfinishedTests) {
                test.Status = 'Aborted';
            }
            update unfinishedTests;
         }
         completeJob(jh,jobIds);
      }
      else {
         completeJob(jh,jobIds);
      }
   } // areTestsComplete
   
   
   
   // Get the status and pass rate for each class
   // whose tests were run by the job.
   // that correspond to the specified job ID.
   public Boolean checkClassStatus(ID[] parentJobIds, JobHelper jh,Integer attemptNum) {
      Boolean allComplete = true;
      String classStatus='Class Status: ';
      Set<String> classCompleteSet = new Set<String>();
      classCompleteSet.addAll(Label.TestClassJob_ClassComplete.split(','));
      Integer numberClasses = 0;
      Integer classesComplete = 0;
      Integer classesNotComplete = 0;

      for (ApexTestQueueItem[] items : [SELECT ApexClass.Name, Status, ExtendedStatus
                                          FROM ApexTestQueueItem 
                                         WHERE ParentJobId in :parentJobIds]) {
         numberClasses += items.size();
         for (ApexTestQueueItem item : items) {
            if (classCompleteSet.contains(item.Status)) {
               classesComplete++;
            } else {
               allComplete = false;
               classesNotComplete++;
               classStatus += '\n'+item.ApexClass.Name + ': ' + (attemptNum == TEST_ATTEMPT_LIMIT ? 'Aborted':item.Status )+ (String.isBlank(item.extendedstatus) ? '' : ' : '+item.extendedStatus);
            }
         } // for (ApexTestQueueItem item
      } // for (ApexTestQueueItem[] items
      String msg = 'Number of Test Classes: '+numberClasses;
      msg += '\nClasses Complete: '+classesComplete;
      if(attemptNum == TEST_ATTEMPT_LIMIT){
        msg += '\nClasses Aborted: '+classesNotComplete;
      }
      else{
        msg += '\nClasses In Progress: '+classesNotComplete;
      }
      msg += '\n\n'+classStatus;
      jh.addToNotes(msg);
      return allComplete;
   } // checkClassStatus

   // Get the result for each test method that was executed.
   public Integer checkMethodStatus(ID[] parentJobIds, JobHelper jh) {
      Integer nbrTestMethods = [Select count() from ApexTestResult WHERE AsyncApexJobId in :parentJobIds];
      
      String[] failStatuses = Label.TestClassJob_MethodFail.split(',');

      String msg = 'Total Number Of Test Methods: '+nbrTestMethods;

      String failedMethods = '';
      Integer nbrFailures = 0;
      
      for (ApexTestResult[] failedResults : [SELECT Outcome, ApexClass.Name, MethodName, Message, StackTrace 
                                               FROM ApexTestResult 
                                              WHERE AsyncApexJobId in :parentJobIds
                                                AND Outcome in :failStatuses
                                           order by ApexClass.Name, MethodName]) {
      
         nbrFailures += failedResults.size();
         for (ApexTestResult atr : failedResults) {
            failedMethods += '\n\n'+atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome;
            //System.debug(atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome);
            if (atr.message != null) {
               //System.debug(atr.Message + '\n       at ' + atr.StackTrace);
               failedMethods += atr.Message + '\n       at ' + atr.StackTrace;
            }
         } // for (ApexTestResult atr
      } // for (ApexTestResult[] failedResults

      msg += '\nNumber of Failed Test Methods: '+nbrFailures;
      if (nbrFailures > 0) {
         msg += '\nFailed Methods: '+failedMethods;
      }

      jh.addToNotes(msg);
      return nbrFailures;
   } // checkMethodStatus
     
   public void completeJob(JobHelper jh,Id[] jobIds){      
       checkMethodStatusSpecific(jobIds);
       
       Integer nbrFailures = checkMethodStatus(jobIds, jh);
         
         jh.tracker.Job_Name__c='TestClassJob-Complete';
         jh.completeJob('TestClassJob-Tests Complete '+(nbrFailures > 0 ? 'With Failures' : 'Successfully'), 'Number of Test Failures: '+nbrFailures);
         //clean up old runs
         CronTrigger[] oldJobs;
         oldJobs = [SELECT Id,CronJobDetailId,CronJobDetail.Name,StartTime FROM CronTrigger WHERE StartTime<:date.today() AND CronJobDetail.Name LIKE 'TestClassJob-%' LIMIT 99];
         if(oldJobs!=null && !oldJobs.isEmpty()){
            for(CronTrigger oldJob: oldJobs){
                system.abortJob(oldJob.Id);
            }
         }
   } // completeJob
    
   // Get the results for specific tests that was executed.
   public void checkMethodStatusSpecific(ID[] parentJobIds) {
         Integer nbrFailures;
         Integer nbrSuccess;
         String failedMethods;
         String successMethods;
         List<String> failStatuses = Label.TestClassJob_MethodFail.split(',');
       
         Map<Id, Test_Class_Job_Settings__c> settingsMap = new Map<Id, Test_Class_Job_Settings__c> ([Select Id, Name, Active__c, Additional_Emails__c, SendErrorOnlyEmail__c, Test_Classes__c
                                                from Test_Class_Job_Settings__c where Active__c = true]);
         for (Test_Class_Job_Settings__c js: settingsMap.Values()) {
            List<String> clsList = js.Test_Classes__c.split(',');                               
            for (ApexTestResult[] testResults : [SELECT Outcome, ApexClass.Name, MethodName, Message, StackTrace 
                                               FROM ApexTestResult 
                                               WHERE AsyncApexJobId in :parentJobIds
                                               AND apexClass.Name in :clsList
                                               order by ApexClass.Name, MethodName]) {                                                  
                nbrFailures = 0;
                nbrSuccess = 0;
                failedMethods = '';
                successMethods = '';
                
                for (ApexTestResult atr : testResults) {
                    if (failStatuses.contains(atr.Outcome))
                    {   nbrFailures ++;
                        failedMethods += '\n\n'+atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome; 
                        if (atr.message != null) 
                        {   failedMethods += atr.Message + '\n       at ' + atr.StackTrace; }
                    }
                    else
                    {   nbrSuccess ++;
                        successMethods += '\n\n'+atr.ApexClass.Name + '.' + atr.MethodName + ': ' + atr.Outcome;    
                    }           
                } // for (ApexTestResult atr
                                        
            } // for testResults coz could be in multiple parentJobIds
            
            // send out specific email
            if ((js.SendErrorOnlyEmail__c && nbrFailures > 0) || !js.SendErrorOnlyEmail__c) {
                // prepare the email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSaveAsActivity(false);
    
                String msgBodyTitle = 'The TestClassJob process finished processing';
                String instanceName = Utilities.checkForProduction();
                if (String.isNotBlank(instanceName)) {
                   msgBodyTitle = 'This was running in the '+instanceName+' instance. \n'+msgBodyTitle;
                }               
    
                mail.setTargetObjectId(UserInfo.getUserId());
                mail.setSubject('TestClassJob completed for '+js.Name+' group');
                String msg = msgBodyTitle+'. \n\n';
                
                Datetime curTime = Datetime.now();
                startTime = (startTime != null ? startTime : Datetime.now());
                Integer minutesProcessed = Integer.valueOf((curTime.getTime() - startTime.getTime())/60000);
                
                msg += 'Start Time = '+startTime.format('MM/dd/yyyy HH:mm:ss');
                msg += '\nEnd Time = '+curTime.format('MM/dd/yyyy HH:mm:ss');
                
                msg += '\nMinutes Processing='+minutesProcessed;
               
                msg += '\n\nTotal Number of Test Methods:  '+(nbrFailures+nbrSuccess)+' \n';
                msg += 'Number of Successful Methods:  '+nbrSuccess+' \n';
                msg += 'Number of Failed Methods:  '+nbrFailures+' \n\n';                
                mail.setPlainTextBody (msg+'. \n\n'+successMethods+' \n\n'+failedMethods);
                
                if (String.isNotBlank(js.Additional_Emails__c)) {
                   mail.setCcAddresses(js.Additional_Emails__c.split(','));
                }

                if (!Test.isRunningTest())
                {   Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   }

             } // if (sendEmail
         
         } // for settingsMap
         
   } // checkMethodStatusSpecific
   
/*  https://salesforce.stackexchange.com/questions/37333/how-to-run-a-scheduled-job-every-15-minutes
global without sharing class JobRunner implements Schedulable {
    Integer intervalMinutes;
    public JobRunner(Integer intervalMinutes) {
        this.intervalMinutes = intervalMinutes;
    }
    public void execute(SchedulableContext sc) {
        // Re-schedule ourself to run again in "intervalMinutes" time
        DateTime now  = DateTime.now();
        DateTime nextRunTime = now.addMinutes(intervalMinutes);
        String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
        System.schedule(JobRunner.class.getName() + '-' + now.format(), cronString, new JobRunner(intervalMinutes));
        // Abort the current job
        Id jobId = sc.getTriggerId();
        System.abortJob(jobId);     
        // Launch a batch job or call a future method to do the actual work
        Database.executeBatch(new SomeBatchJob());
    }
}
*/
   

} // class TestClassJob