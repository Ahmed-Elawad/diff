/* 
   Batch job for working with the file in a batch.

   DataLoadBatch dlb = new DataLoadBatch();
   Database.executeBatch(dlb, 200);

   
  History
  -------
  07/30/2020 Dan Carmen   Created
  12/02/2020 Dan Carmen   Added check for blank row.
  12/14/2020 Dan Carmen   Change to without sharing
  03/30/2021 Dan Carmen   Remove notify when parsing complete
  03/13/2023 Dan Carmen   Increment API to 57

 */
global without sharing class DataLoadBatch implements Database.batchable<String>, Database.Stateful {
    
   public static String CLASSNAME='DataLoadBatch';
   
   // data file was just attached, split the file into separate records for processing
   public static String MODE_PARSE_FILE='ParseFile';
   // for lead/referral source lists, send the data to dataflux and get results returned.
   public static String MODE_SEND_TO_DF='SendToDataFlux';
   // for update lists, create the update records and update SF
   public static String MODE_UPDATE_SF='UpdateSf';
   
   // defaults to parsing the file first
   global String currentMode=MODE_PARSE_FILE;
    
   global DataLoad__c dataLoad = null;
    
   global Integer nbrRows = 0;

   global Iterable<String> start(Database.batchableContext batchableContext) {
      // process one file at a time
      CSVIterator iterator = null;
      try {
         dataLoad = [Select Id, Name
                           ,Campaign__c, FileType__c, HeaderRow__c
                           ,HeadersAreValid__c, NbrHeaders__c, NbrValidHeaders__c
                           ,ProcessNotes__c, Status__c, UpdateAPIObjectName__c
                           ,InlineNbrInserts__c, InlineProcessed__c, InlineTotalRecs__c
                           ,InlineNbrSuccess__c, InlineNbrUpdates__c
                       From DataLoad__c
                      Where Status__c=:DataLoadMethods.STATUS_PARSE
                      Order by CreatedDate desc
                      limit 1];
          
         dataLoad.Status__c=DataLoadMethods.STATUS_PARSING;
         DataLoadMethods.SKIP_TRIGGER=true;
         update dataLoad;
         DataLoadMethods.SKIP_TRIGGER=false;

         ContentDocumentLink cdl = [Select Id, ContentDocumentId, LinkedEntityId 
                                          ,ContentDocument.Title
                                      from ContentDocumentLink 
                                     where LinkedEntityId=:dataLoad.Id
                                       and ContentDocument.FileExtension='csv'
                                     limit 1];

         ContentVersion cver = [select Id
                                   ,ContentBodyId
	                               ,ContentDocumentId
	                               ,ContentDocument.ParentId
	                               ,ContentDocument.Title
                                   ,ContentSize, FileExtension, FileType, IsLatest, PublishStatus, VersionData, VersionNumber, LastModifiedDate
                               from ContentVersion
                              Where ContentDocumentId=:cdl.ContentDocumentId];

         Blob b = cver.VersionData;
         String fileInfo = b.toString();
         System.debug('DataLoadBatch.start fileInfo='+fileInfo.length());
         iterator = new CSVIterator(fileInfo, EmailServiceProcessorBatch.CRLF);
         // skip past the header row
         iterator.next();
      } catch (Exception e) {
         System.debug('Exception selecting file: '+e.getMessage());
         return null;
      }
       
      return iterator;
   } // start
    
   global void execute(Database.BatchableContext batchableContext, List<String> scope) {
      System.debug('execute currentMode='+currentMode+' scope='+scope.size());
      if (currentMode == MODE_PARSE_FILE) {
         saveDataRows(scope);
      }
   } // execute
    
   global void saveDataRows(String[] fileRows) {
      DataLoadRecord__c[] insertRecs = new DataLoadRecord__c[]{};
      for (String fileRow : fileRows) {
          nbrRows++;
          // so we don't load empty rows (just commas).
          String checkRow = fileRow.replaceAll(',', '');
          if (String.isNotBlank(checkRow)) {
             DataLoadRecord__c newRec = new DataLoadRecord__c(DataLoad__c=dataLoad.Id);
             newRec.DataRow__c=fileRow;
             newRec.RowNbr__c=nbrRows;
             newRec.Status__c='Pending';
             insertRecs.add(newRec);
          }
      } // for (String fileRow : fileRows
      System.debug('saveDataRows insertRecs='+insertRecs.size());
      insert insertRecs;
   } // saveDataRows
    
   global void finish(Database.BatchableContext batchableContext){
      // check for errors. If no errors, change to next status
      //dataLoad.Status__c = DataLoadMethods.STATUS_FILE_PARSED;
      dataLoad.Status__c = (Test.isRunningTest() ? DataLoadMethods.STATUS_FILE_PARSED : DataLoadMethods.STATUS_PROCESS);
      dataLoad.FileParsed__c = true;
      Integer nbrRecs = [Select count() from DataLoadRecord__c where DataLoad__c=:dataLoad.Id];
      dataLoad.InlineTotalRecs__c = nbrRecs;
       
      update dataLoad;
       
      //notifyUser();
       
      // see if any other records are pending. Relaunch if there are. 
      launchBatch();
   } // finish
        
   public static void launchBatch() {
      DataLoad__c[] dataLoads = [select Id, RequestStartTime__c from DataLoad__c Where Status__c = :DataLoadMethods.STATUS_PARSE order by RequestStartTime__c ASC nulls first limit 1 ];
      System.debug('DataLoadBatch launchBatch dataLoads='+dataLoads.size());
      if (!dataLoads.isEmpty()) {
         Integer nbrRunning = [Select count()
                              FROM AsyncApexJob 
                                    WHERE JobType='BatchApex' 
                                    AND Status IN ('Processing','Preparing','Queued') 
                                    AND ApexClass.Name = :CLASSNAME];
         System.debug('DataLoadBatch.launchBatch nbrRunning='+nbrRunning);
         if (Test.isRunningTest() || nbrRunning == 0) {
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
            Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 200);
            DataLoadBatch dlb = new DataLoadBatch();
            Database.executeBatch(dlb, batchSize);
         }


      }

   } // launchBatch

} // class DataLoadBatch