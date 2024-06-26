/* 
   Batch job for working with Data in a batch.
   
  DataLoadBatch3 dlb = new DataLoadBatch3();
  Database.executeBatch(dlb, 1);

  Apex_Batch_Control__c setup
  Name: DataLoadBatch3
  Active: true
  Batch Title: Data Load Bulk
  Nbr of Attempts: 10  (how many times it will check for the bulk results)
  Batch Size: 1  (how many Data Load records the batch will process at a time. Should be 1 due to mixed DML operations)
  Minutes till Launch: 5  (how many minutes until it checks for the bulk job status)

  History
  -------
  12/29/2020 Dan Carmen   Created
  03/26/2021 Dan Carmen   Change the finish stage for consistency.
  04/06/2021 Dan Carmen   Added better error handling

 */
global without sharing class DataLoadBatch3 implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable  {
   public static String CLASSNAME='DataLoadBatch3';
   // the statuses we're going to run for
   public static String[] BULK_STATUSES = new String[]{DataLoadMethods.STATUS_PROCESS_BULK,DataLoadMethods.STATUS_BULK_SUBMITTED,DataLoadMethods.STATUS_BULK_COMPLETE};

   global DataLoadBatch3() {
   } // DataLoadBatch3

   global void execute(SchedulableContext SC) {
      launchBatch();
   } // execute

   global Database.QueryLocator start(Database.BatchableContext BC){
      // the query for the dataload object
      String query = ObjectHelper.getSOQLQuery('DataLoad__c', null, false, false, false, false, false);
      String[] statuses = BULK_STATUSES;
      Datetime runTime = DateTime.now();
      query += ' Where Status__c in :statuses and BulkNextRunTime__c <= :runTime ';
      
      return Database.getQueryLocator(query);
   } // start
    
   //global DataLoad__c submitDataLoad = null;
   
   global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
      // the expectation is to only process one record at a time. But just in case...
      System.debug('execute scope='+scope.size());
      DataLoad__c[] dataLoads = (DataLoad__c[])scope;
      for (DataLoad__c dataLoad : dataLoads) {
         try {
              
            if (dataLoad.Status__c == DataLoadMethods.STATUS_PROCESS_BULK) {
               handleSubmit(dataLoad);
            } else if (dataLoad.Status__c == DataLoadMethods.STATUS_BULK_SUBMITTED) {
               checkOpenJob(dataLoad);
            } else if (dataLoad.Status__c == DataLoadMethods.STATUS_BULK_COMPLETE) {
               handleResults(dataLoad);
            }
         } catch (Exception e) {
            StringHelper.addToProcessNotes(dataLoad,'Error occurred during processing: '+e.getMessage()+' \n'+e.getStackTraceString());
            dataLoad.Status__c=DataLoadMethods.STATUS_ERROR;
         }
      } // for (DataLoad__c dataLoad : dataLoads
      update dataLoads;
   } // execute
       
   global void handleSubmit(DataLoad__c dataLoad) {
      if (String.isNotBlank(dataLoad.BulkJobId__c)) {
         DataLoadMethods.addToExceptions(dataLoad,'Attempted to Submit except that a Job Id is already present.');
         dataLoad.Status__c = DataLoadMethods.STATUS_ERROR;
         return;
      }
       
      // there should only be 1 csv file attached
      ContentDocumentLink cdl = [Select Id, ContentDocumentId, LinkedEntityId 
                                          ,ContentDocument.Title
                                      from ContentDocumentLink 
                                     where LinkedEntityId=:dataLoad.Id
                                       and ContentDocument.FileExtension='csv'
                                     limit 1];
      String operation = dataLoad.BulkOperation__c;
      String jobId = BulkApiHelper.createBulkJob(dataLoad.UpdateAPIObjectName__c, operation, cdl.ContentDocumentId);
      System.debug('handleSubmit jobId='+jobId);
       
      if (String.isNotBlank(jobId)) {
         dataLoad.BulkJobId__c = jobId;
         dataLoad.Status__c = DataLoadMethods.STATUS_BULK_SUBMITTED;
         dataLoad.ProcessDataStart__c = Datetime.now();
         StringHelper.addToProcessNotes(dataLoad, 'Bulk Job submitted with jobId='+jobId);
         // get the next run interval
         dataLoad.BulkNextRunTime__c = getNextRunInterval();
         StringHelper.addToProcessNotes(dataLoad, 'Bulk Job submitted with jobId='+jobId+' next checkTime '+dataLoad.BulkNextRunTime__c.format('MM/dd/yyyy hh:mm:ss'));
      } else {
         DataLoadMethods.addToExceptions(dataLoad,'Error submitting job statusCode='+BulkApiHelper.responseStatusCode+' resp body='+BulkApiHelper.responseBody);
         dataLoad.Status__c = DataLoadMethods.STATUS_ERROR;
         dataLoad.BulkNextRunTime__c = null;
      }
   } // handleSubmit
    
    
   global void checkOpenJob(DataLoad__c dataload) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      // how many times do we check for a job to end? So we don't check forever
      Integer maxChecks = (abc != null ? Integer.valueOf(abc.NbrOfAttempts__c) : 10);

      dataload.BulkStatusChecks__c = (dataload.BulkStatusChecks__c == null ? 0 : dataload.BulkStatusChecks__c) + 1;
      BulkApiHelper.checkJobStatus(dataload.BulkJobId__c);
      if (String.isNotBlank(BulkApiHelper.exceptionOccurred)) {
         DataLoadMethods.addToExceptions(dataLoad,BulkApiHelper.exceptionOccurred);
         dataload.BulkStatusChecks__c = maxChecks;
      } else {
         dataload.BulkJobStatus__c = BulkApiHelper.jobState;
         dataload.BulkRecordsProcessed__c = BulkApiHelper.recsProcessed;
         dataload.BulkRecordsFailed__c = BulkApiHelper.recsFailed;
         dataload.BulkProcessingTime__c = BulkApiHelper.totalProcessingTime;
      }
          
      if (dataload.BulkStatusChecks__c >= maxChecks) {
         dataload.ProcessDataEnd__c = Datetime.now();
         dataload.Status__c = DataLoadMethods.STATUS_ERROR;
         dataLoad.BulkNextRunTime__c = null;
         StringHelper.addToProcessNotes(dataload,'Reached the maximum number of job checks: '+maxChecks+'. Process will no longer check results. ');
         sendEmail(dataLoad, false);
      } else if (dataload.BulkJobStatus__c == BulkApiHelper.STATE_INPROGRESS) {
         dataLoad.BulkNextRunTime__c = getNextRunInterval();
         StringHelper.addToProcessNotes(dataload,'Job not complete, next check time '+dataLoad.BulkNextRunTime__c.format('MM/dd/yyyy hh:mm:ss'));
      } else if (dataload.BulkJobStatus__c == BulkApiHelper.STATE_ABORTED || dataload.BulkJobStatus__c == BulkApiHelper.STATE_FAILED) {
         dataload.ProcessDataEnd__c = Datetime.now();
         dataload.Status__c = DataLoadMethods.STATUS_ERROR;
         dataLoad.BulkNextRunTime__c = null;
         StringHelper.addToProcessNotes(dataload,'Job completed with a status of '+dataload.BulkJobStatus__c+' errorMsg='+BulkApiHelper.errorMsg);
         sendEmail(dataLoad, false);
      } else if (dataload.BulkJobStatus__c == BulkApiHelper.STATE_COMPLETE) {
         dataload.ProcessDataEnd__c = Datetime.now();
         dataload.Status__c = DataLoadMethods.STATUS_BULK_COMPLETE;
         dataLoad.BulkNextRunTime__c = Datetime.now();
         StringHelper.addToProcessNotes(dataload,'Job Completed');
      }
   } // checkOpenJob

   global void handleResults(DataLoad__c dataLoad) {
      BulkApiHelper.getResults(dataLoad.BulkJobId__c, dataLoad.Id);
      if (String.isNotBlank(BulkApiHelper.exceptions)) {
         DataLoadMethods.addToExceptions(dataLoad,BulkApiHelper.exceptions);
      }
      dataLoad.Status__c = DataLoadMethods.STATUS_COMPLETE;
      dataLoad.BulkNextRunTime__c = null;
      // send an email
      sendEmail(dataLoad, true);
   } // handleResults

   global void sendEmail(DataLoad__c dataLoad, Boolean isSuccess) {
      String subject='File Processing for '+dataLoad.FileType__c+' '+dataLoad.Name;
      String body = '';
      if (isSuccess) {
         Integer processed = (dataLoad.BulkRecordsProcessed__c != null ? Integer.valueOf(dataLoad.BulkRecordsProcessed__c) : 0);
         Integer failed = (dataLoad.BulkRecordsFailed__c != null ? Integer.valueOf(dataLoad.BulkRecordsFailed__c) : 0);
         subject += ' Complete with '+processed+' Records';
         Integer nbrSuccess = processed -failed;
         body = 'Total Records: '+processed;
         body += '\nNumber Success: '+nbrSuccess;
         body += '\nNumber Errors: '+failed;
      } else {
         subject += ' finished in Error';
         body = 'Please refer to the Data Load record for more details on the error ';
      }
          
      String host = Utilities.getInstanceURL()+'/';
      String dataLoadUrl = host + '/lightning/r/' +  String.valueOf(dataLoad.Id) + '/view';
      body += '\n\nData Load record: '+dataLoadUrl;

      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      if (isSuccess) {
         Id[] attachmentIds = new Id[]{};
         for (FileWrapper fw : BulkApiHelper.afq.wrappersToProcess) {
            attachmentIds.add(fw.conVersion.Id);
         }
         if (!attachmentIds.isEmpty()) {
            mail.setEntityAttachments(attachmentIds);
         }
         if (attachmentIds.size() < 2) {
            body += '\n\n ** There may have been a problem retrieving the success or failure files. Please refer to the Data Load record for more information. **';
         }
      } // if (isSuccess

      mail.setTargetObjectId(dataLoad.CreatedById);
      mail.setSaveAsActivity(false);
      mail.setSubject(subject);
      mail.setPlainTextBody(body);
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });       

   } // sendEmail

   global void finish(Database.BatchableContext batchableContext){
       // check to see if there are any data loads that need to be processed. 
       launchBatch();
   }
    
   global Datetime getNextRunInterval() {
      Datetime retDate = Datetime.now();
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer intervalMinutes = (abc != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 5);
      retDate = retDate.addMinutes(intervalMinutes);
      System.debug('getNextRunInterval intervalMinutes='+intervalMinutes+' retDate='+retDate.format('MM/dd/yyyy hh:mm:ss'));
      return retDate;
   } // getNextRunInterval
    
   public static void launchBatch() {
      // see if there are any records available to run - get the earliest time 
      DataLoad__c[] dataLoads = [select Id, BulkNextRunTime__c from DataLoad__c Where Status__c in :BULK_STATUSES and BulkNextRunTime__c != null order by BulkNextRunTime__c ASC limit 1 ];
      System.debug('launchBatch dataLoads='+dataLoads);
      if (dataLoads.size() > 0) {
         JobHelper.launchBatchWithSchedule(new DataLoadBatch3(), CLASSNAME, dataLoads[0].BulkNextRunTime__c, 1);
      } // if (nbrRecs > 0
       
   } // launchBatch
    
   public static String LAUNCH_EMAIL=Label.DataLoadEmailService;
    
   public static void launchBatchCheck() {
      if (LAUNCH_EMAIL == 'noemail') {
         launchBatch();
      } else {
         // send an email 
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         mail.setToAddresses(new String[]{LAUNCH_EMAIL});
         mail.setSaveAsActivity(false);
         mail.setSubject('Launch DataLoadBatch3');
         mail.setPlainTextBody('Launch DataLoadBatch3');
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });       
      }
   } // launchBatch2

} // class DataLoadBatch3