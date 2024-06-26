/* 
   Email Handler to start and stop jobs as a specific user
   
  History
  -------
  08/17/2021 Dan Carmen   Created
  05/10/2023 Dan Carmen   Increment API

 */
global class EmailJobManager implements Messaging.InboundEmailHandler {

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
      String subject = (email.subject != null ? email.subject : '');
      Integer commentSize = WebServiceSettings__c.Comment__c.getDescribe().getLength();
      System.debug('handleInboundEmail subject='+subject);
      subject = (subject.startsWith('Sandbox') ? subject.replace('Sandbox: ','').trim() : subject);
      System.debug('handleInboundEmail 2 subject='+subject);
      // subject should be in the format of 'Start...' or 'Stop...'
      String action=subject.substringBefore(' ');
      if (action == 'Start' || action == 'Stop' || action == 'Status' || action == 'Run') {
         String codeName = subject.substringAfter(' ');
         String settingName = (String.isNotBlank(codeName) ? RecordTypeHelper.cleanRtName(codeName) : '');
         Apex_Batch_Control__c abc = (String.isNotBlank(settingName) ? Apex_Batch_Control__c.getInstance(settingName) : null);
         if (abc == null) {
            result.success = false;
            result.message = 'Could not find a Batch Control setting for '+codeName+'. Please check your spelling and try again';
         } else {
            checkAbc(action, abc, email, result);
         }
         if (abc != null && result.success && !abc.SendCompletionEmail__c) {
            return null;
         }
      } else {
         result.success = false;
         result.message = 'Subject needs to begin with one of these actions: Start,Stop,Status';
      }
      return result;
   } // handleInboundEmail
    
   global Boolean checkAbc(String action, Apex_Batch_Control__c abc, Messaging.InboundEmail email, Messaging.InboundEmailResult result) {
      Boolean success=true;
      Integer commentSize = Apex_Batch_Control__c.ProcessNotes__c.getDescribe().getLength();
      if (action == 'Run') {
         if (!abc.Active__c) {
            result.success = false;
            result.message = abc.Name+' is not active';
         } else {
            UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
            if (!Test.isRunningTest()) {
               success = uzoc.launchJob(abc);
            }
            result.success = success;
            result.message = abc.Name+(success ? ' has started' : ' was unable to start');
         }
      } else if (action == 'Start') {
         abc.Active__c = true;
         abc.EmailTest__c=email.fromAddress;
         abc.ProcessNotes__c = ('Started via EmailJobManager by '+email.fromAddress+' at '+Datetime.now().format('M/d/yyyy H:mm:ss')).left(commentSize);
         update abc;
         UpdateZipOwnershipController uzoc = new UpdateZipOwnershipController();
         if (!Test.isRunningTest()) {
            success = uzoc.launchJob(abc);
         }
         result.success = success;
         result.message = abc.Name+(success ? ' has started' : ' was unable to start');
      } else if (action == 'Stop') {
         abc.Active__c = false;
         abc.EmailTest__c=email.fromAddress;
         abc.ProcessNotes__c = ('Stopped via EmailJobManager by '+email.fromAddress+' at '+Datetime.now().format('M/d/yyyy H:mm:ss')).left(commentSize);
         update abc;
         result.success = true;
         result.message = abc.Name+' has been stopped';

      } else if (action == 'Status') {
         // see if running
         AsyncApexJob[] runningJobs = [Select Id, Status, JobItemsProcessed, ExtendedStatus, NumberOfErrors, TotalJobItems
                                 FROM AsyncApexJob 
                                WHERE JobType='BatchApex' 
                                  AND ApexClass.Name like :abc.Name+'%'
                                  AND Status IN ('Processing','Preparing','Queued','Holding') 
                                 order by CreatedDate desc limit 1];
         System.debug('checkAbc runningJobs='+runningJobs.size());
         result.success = true;
         if (!runningJobs.isEmpty()) {
            System.debug('checkAbc runningJob='+runningJobs[0]);
            result.message = getAsyncMsg(abc.Name, runningJobs[0].Id, runningJobs[0].Status, runningJobs[0].ExtendedStatus, runningJobs[0].TotalJobItems
                                         , runningJobs[0].JobItemsProcessed, runningJobs[0].NumberOfErrors);
         } else {
            // see if scheduled
            CronTrigger[] scheduledJobs = [Select Id, CronJobDetail.Name
                                           ,CronJobDetail.Id
                                           ,NextFireTime
                                           ,State
                                    FROM CronTrigger 
                                   where CronJobDetail.Name like :abc.Name+'%'
                                     AND State !='COMPLETE' AND State != 'DELETED' AND State != 'ERROR'
                                     order by NextFireTime asc limit 1];
            System.debug('checkAbc scheduledJobs='+scheduledJobs.size());
            if (!scheduledJobs.isEmpty()) {
               System.debug('checkAbc scheduledJob='+scheduledJobs[0]);
               result.message = getCronMsg(abc.Name, scheduledJobs[0].Id, scheduledJobs[0].State, scheduledJobs[0].NextFireTime);
            } else {
               result.message = 'No running or scheduled jobs were found for '+abc.Name;
            }
         }
      }
      return success;
   } // checkAbc
    
    public String getAsyncMsg(String jobName, String jobId, String status, String extStatus, Integer nbrItems, Integer nbrProcessed, Integer nbrErrors ) {
       String msg = 'Found a running job for '+jobName;
       msg += '\n JobId='+jobId;
       msg += '\n Status='+status;
       msg += '\n ExtendedStatus='+extStatus;
       msg += '\n TotalJobItems='+nbrItems;
       msg += '\n JobItemsProcessed='+nbrProcessed;
       msg += '\n NumberOfErrors='+nbrErrors;
       return msg;
    } // getAsyncMsg
    
    public String getCronMsg(String jobName, String jobId, String state, Datetime nextFireTime) {
       String msg = 'Found a scheduled job for '+jobName;
       msg += '\n Id='+jobId;
       msg += '\n State='+state;
       msg += '\n NextFireTime='+nextFireTime.format('M/d/yyyy H:mm:ss');
       return msg;
    } // getCronMsg
    
} // class EmailJobManager