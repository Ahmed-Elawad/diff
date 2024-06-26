/* 
 * A class to help with tracking and logging jobs.
 *
 * History
 * -------
 * 06/28/2012 Dan Carmen   Created
   03/27/2013 Dan Carmen   Modified to complete job from a non-batch scheduled job
   11/05/2013 Dan Carmen   Added check to always send an email on errors
   01/28/2014 Dan Carmen   Updated status in completeJob.
   03/01/2014 Dan Carmen   Changes for NSS
   04/28/2015 Dan Carmen   Save notes as an attachment if they're too long.
   08/02/2017 Dan Carmen   Add ability to add to notes (not just at the end)
   08/20/2018 Cindy Freeman		add method addFilesToJob to replace addAttachementsToJob method
   01/13/2021 Dan Carmen        Add methods to help manage scheduled and batch jobs
   08/16/2021 Dan Carmen        Add addToNotes2 
   10/26/2021 Dan Carmen        Update job scheduler to not perform the checks for existing jobs during a test run.
   05/16/2023 Dan Carmen        Update scheduleBatch to not always add 1 minute to the schedule time

*/
public with sharing class JobHelper {

   public static String STATUS_STARTED='Started';
   public static String STATUS_SCHEDULED='Scheduled';
   public static String STATUS_COMPLETED='Completed';

   public AddFileQueueable afq = new AddFileQueueable();
   
   public Job_Tracker__c tracker = new Job_Tracker__c();
   
   private String trackerNotes = '';
      
   /** Default constructor. */
   public JobHelper(String jobName) {
      tracker.Job_Name__c = jobName;
      tracker.Process_Start__c = DateTime.now();
      tracker.Status__c=STATUS_STARTED;
      Apex_Batch_Control__c batchControl = Apex_Batch_Control__c.getInstance(tracker.Job_Name__c);
      if (batchControl != null) {
         ChangeLog.allowLogging = batchControl.SaveAttachments__c;
      }
    } // JobHelper
   
   public void setScheduled() {
      tracker.Process_Start__c = null;
      tracker.Status__c = STATUS_SCHEDULED;
   } // setScheduled
   
   public void setStarted() {
      tracker.Process_Start__c = DateTime.now();
      tracker.Status__c=STATUS_STARTED;
   } // setStarted
   
   /** Save the current tracker record. */
   public Boolean saveJob() {
      upsert tracker;
      return true;
   } // saveJob
   
   /** Save the passed in attachments to the job tracker record. 
    */
   public Boolean addAttachmentsToJob(Attachment[] attachments) {
    Boolean attachmentsAdded = false;
      Apex_Batch_Control__c batchControl = Apex_Batch_Control__c.getInstance(tracker.Job_Name__c);
      // make sure the tracker is saved.
      if (tracker.Id == null) {
         saveJob();
      }   
         
      if ((batchControl != null && batchControl.SaveAttachments__c) &&
           attachments != null && !attachments.isEmpty() && tracker.Id != null) {

         attachmentsAdded = true;
        for (Attachment attach : attachments) {
           attach.ParentId = tracker.Id;
        }
        insert attachments;
      } // if ((batchControl != null
      return attachmentsAdded;
   } // addAttachmentsToJob
   
   public void checkChangeLog() {
      //Attachment attach = ChangeLog.getAttachment(tracker.Job_Name__c);
      //if (attach != null) {
      //   addAttachmentsToJob(new Attachment[]{attach});
      //}
      FileWrapper fw = ChangeLog.getFileWrapper(tracker.Job_Name__c);
      if (fw != null) {
      	   addFilesToJob(new FileWrapper[]{fw});
      }
   } // checkChangeLog

  /** Save the passed in files to the job tracker record.
   */
   public Boolean addFilesToJob(FileWrapper[] fileWrappers) {
  		Boolean filesAdded = false;
  		Apex_Batch_Control__c batchControl = Apex_Batch_Control__c.getInstance(tracker.Job_Name__c);
      	// make sure the tracker is saved.
      	if (tracker.Id == null) {
         	saveJob();
      	} 
      	
      	for (FileWrapper fw: fileWrappers){
      		fw.parentIds = new Id[]{tracker.Id};	
      	}      
      	AddFileQueueable afq = new AddFileQueueable(fileWrappers);
      	afq.processRecs();
  		filesAdded = true;
  		
  		return filesAdded;
   }
  
   public static final Integer NOTES_SIZE = Job_Tracker__c.Notes__c.getDescribe().getLength();

   public void addToNotes(String notes) {
      if (String.isNotBlank(notes)) {
         trackerNotes += (String.isBlank(trackerNotes) ? '' : '\n') + notes;
      } // if (String.isNotBlank(notes
   } // addToNotes
   
   public void addToNotes2(String notes) {
      if (String.isNotBlank(notes)) {
         Schema.DescribeFieldResult dfr = Schema.SObjectType.Job_Tracker__c.fields.Notes__c;
         StringHelper.addToProcessNotes(tracker, dfr, notes);
      }
   } // addToNotes2
    
   public void completeJob(String jobDesc, String notes) {
    completeJob((Database.BatchableContext)null, jobDesc, notes);
    /*
      tracker.Process_End__c = Datetime.now();
      // make sure the notes aren't too long for the field. If they are, substring.
      Integer notesLength = ObjectHelper.getFieldLngth(Job_Tracker__c.Notes__c);
      tracker.Notes__c = ((notes != null && notes.length() >= notesLength) ? notes.subString(0,notesLength) : notes);
      tracker.Status__c = 'Completed';
      
      saveJob();
      checkChangeLog();
      
      // prepare the email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      //String[] toAddresses = new String[] {a.CreatedBy.Email};
      //mail.setToAddresses(toAddresses);
      mail.setTargetObjectId(UserInfo.getUserId());
      mail.setSaveAsActivity(false);
      
      mail.setSubject(jobDesc+' completed');

      String timeStatus = ' \n\n     Start Time='+tracker.Process_Start__c;
      timeStatus +=    '\n     End Time='+tracker.Process_End__c+'\n\n ';

      mail.setPlainTextBody ('The '+jobDesc+' process finished processing. \n\n'+timeStatus+notes);
      // only send the message if on production.
      checkSendEmail(mail, false);
      */
   } // completeJob
   
   /** Save the job information and send an email if required.
    */
   public void completeJob(Database.BatchableContext bc, String jobDesc, String notes) {
      AsyncApexJob aaj = null;
      Boolean hasErrors = false;
      Apex_Batch_Control__c batchControl = Apex_Batch_Control__c.getInstance(tracker.Job_Name__c);
      if (batchControl != null) {
         notes += '\n\nBatchControl settings: active='+batchControl.Active__c+
                      ' completeEmail='+batchControl.SendCompletionEmail__c+
                      ' errorEmail='+batchControl.SendErrorEmail__c+
                      ' attachments='+batchControl.SaveAttachments__c;
      } // if (batchControl != null

      if (bc != null) {
         // Query the AsyncApexJob object to retrieve the current job's information.
         aaj = [Select Id, Status, NumberOfErrors, JobItemsProcessed,
                               TotalJobItems, CreatedById
                          from AsyncApexJob where Id = :bc.getJobId()];
         // set the job id as the name
         tracker.Job_Id__c = bc.getJobId();
         tracker.Status__c = aaj.Status;
         tracker.Nbr_Batches__c = aaj.TotalJobItems;
         tracker.Nbr_Errors__c = aaj.NumberOfErrors;
         hasErrors = (aaj.NumberOfErrors != null && aaj.NumberOfErrors > 0);
         
      } else {
         tracker.Status__c = STATUS_COMPLETED;
      }
      tracker.Process_End__c = Datetime.now();
      
      addToNotes(notes);
      // make sure the notes aren't too long for the field. If they are, substring.
      tracker.Notes__c = trackerNotes.left(NOTES_SIZE);

      saveJob();
      
      // save the long notes as an attachment so we retain all of the information.
      if (trackerNotes.length() > NOTES_SIZE) {
         /*
         Attachment attach = new Attachment(ParentId = tracker.Id, Name='extendedNotes.txt'
                               ,Body=Blob.valueOf(trackerNotes), ContentType='text');
         insert attach;
         */
         FileWrapper fw = new FileWrapper(new Id[]{tracker.Id}, 'extendedNotes.txt', 'extendedNotes.txt', null, Blob.valueOf(trackerNotes));
         AddFileQueueable afq = new AddFileQueueable(new FileWrapper[]{fw});
      	 afq.processRecs();        
      }
      checkChangeLog();

      
      // are we going to send an email?
      if (batchControl != null) {
         Boolean sendEmail = (batchControl.SendCompletionEmail__c || (hasErrors && batchControl.SendErrorEmail__c));

         if (sendEmail) {
            // prepare the email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSaveAsActivity(false);

            String msgBodyTitle = 'The '+jobDesc+' process finished processing';
            String instanceName = Utilities.checkForProduction();
            if (String.isNotBlank(instanceName)) {
               msgBodyTitle = 'This was running in the '+instanceName+' instance. \n'+msgBodyTitle;
            }
            
         
            String timeStatus = '\n\n     Start Time='+tracker.Process_Start__c;
            timeStatus +=    '\n     End Time='+tracker.Process_End__c+'\n\n ';

            if (aaj != null) {
               mail.setTargetObjectId(aaj.CreatedById);
               mail.setSubject(jobDesc+' completed with status: ' + aaj.Status);
               mail.setPlainTextBody (msgBodyTitle+' ' + aaj.TotalJobItems +
                      ' batches with '+ aaj.NumberOfErrors + ' failures. \n\n'+timeStatus+trackerNotes);
            } else {
               mail.setTargetObjectId(UserInfo.getUserId());
               mail.setSubject(jobDesc+' completed');
               mail.setPlainTextBody (msgBodyTitle+'. \n\n'+timeStatus+trackerNotes);
            }
            if (String.isNotBlank(batchControl.AdditionalEmails__c)) {
               mail.setCcAddresses(batchControl.AdditionalEmails__c.split(','));
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         } // if (sendEmail
      } // if (batchControl != null
      
   } // completeJob
    
   // if we're running a test, do we always want to be able to launch so a currently scheduled job doesn't interfere?
   public static Boolean ForceRunWithTest=Test.isRunningTest();
   
   public static String launchBatchWithSchedule(Database.Batchable<SObject> batchClass, String classname, Datetime nextRunTime, Integer nbrRunningAtOnce) {
      String jobId = null;
       
      // if the batch job is already running, don't launch again.
      Integer nbrRunning = JobHelper.getNbrRunningBatches(classname);
      // if it's currently running, don't need to do anything
      if (ForceRunWithTest || (nbrRunning < nbrRunningAtOnce)) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(classname);
         Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 1);
         
         // check if it's scheduled
         if (!ForceRunWithTest && JobHelper.isScheduledOkay(classname, nextRunTime)) {
            return null;
         }

         System.debug('launchBatchWithSchedule nbrRunning='+nbrRunning+' abc='+abc+' batchSize='+batchSize);
         if (abc != null && abc.Active__c ) {
            // if the records are ready to run now
            jobId = JobHelper.scheduleBatch(batchClass, classname, nextRunTime, batchSize);
         }
      } // if (nbrRunning < nbrRunningAtOnce
      return jobId;
   } // launchBatchWithSchedule
    
   public static Integer getNbrRunningBatches(String classname) {
      Integer nbrRunning = [Select count()
                                 FROM AsyncApexJob 
                                WHERE JobType='BatchApex' 
                                  AND Status IN ('Processing','Preparing','Queued') 
                                  AND ApexClass.Name = :classname];
      return nbrRunning;
   } // getNbrRunningBatches
    
   // is there already a job scheduled before or equal to the time frame passed in
   public static Boolean isScheduledOkay(String classname, Datetime nextRunTime) {
      Boolean isScheduled = false;
      CronTrigger[] scheduledJobs = getScheduled(classname);
      if (scheduledJobs.size() > 0) {
         CronTrigger nextJob = scheduledJobs[0];
         if (nextJob.NextFireTime > nextRunTime) {
            // cancel the next job and reschedule
            System.debug('isScheduledOkay canceling a job for '+classname+' scheduled at '+nextJob.NextFireTime.format('MM/dd/yyyy HH:mm:ss')+' nextRunTime='+nextRunTime.format('MM/dd/yyyy HH:mm:ss'));
            System.abortJob(nextJob.Id);
         } else {
            // exit here because it's already scheduled by the next job time
            isScheduled = true;
         }
      }
      System.debug('isScheduledOkay for '+classname+' scheduledJobs='+scheduledJobs.size()+' isScheduled='+isScheduled);
      return isScheduled;
   } // isScheduledOkay
    
   // get any scheduled jobs for the passed in classname
   public static CronTrigger[] getScheduled(String classname) {
      String checkClass = classname+'%';
      CronTrigger[] scheduledJobs = [Select Id, CronJobDetail.Name
                                           ,CronJobDetail.Id
                                           ,NextFireTime
                                           ,State
                                    FROM CronTrigger 
                                   where CronJobDetail.Name like :checkClass
                                     AND State !='COMPLETE' AND State != 'DELETED' AND State != 'ERROR'
                                     order by NextFireTime asc];
       return scheduledJobs;
   } // getScheduled

   public static String scheduleBatch(Database.Batchable<SObject> batchClass, String className, Datetime nextRunTime, Integer batchSize) {
      String jobId = null;
      if (nextRunTime <= Datetime.now()) {
         System.debug('scheduleBatch launching '+className+' now');
         jobId = Database.executeBatch(batchClass, batchSize);
      } else {
         // we have to schedule it in the future
         String jobName = className+DateTime.now().format('yyyyMMddHHmmssSSS');
         long milliseconds = (nextRunTime.getTime() - Datetime.now().getTime());
         Integer scheduleMinutes = Integer.valueOf((milliseconds/60000));
         scheduleMinutes = (scheduleMinutes <= 0 ? 1 : scheduleMinutes);
         System.debug('scheduleBatch launching '+className+' in '+scheduleMinutes+' minutes');
         try {
            jobId = System.scheduleBatch(batchClass, jobName, scheduleMinutes, batchSize);
            System.debug('scheduleBatch jobId='+jobId+' jobName='+jobName);
         } catch (Exception e) {
            System.debug('Exception e: '+e.getMessage());
         }
      }

      return jobId;
   } // scheduleBatch
    
} // class JobHelper