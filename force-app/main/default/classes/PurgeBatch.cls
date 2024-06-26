/* 
 * A batch job to purge from the database
 *
 * History
 * -------
   05/26/2015 Dan Carmen   		Created
   02/08/2016 Dan Carmen   		Add extra debugging.
   10/24/2017 Dan Carmen   		Additional logging.
   10/22/2018 Dan Carmen   		Extra functionality to log what the process is doing
   01/07/2019 Jermaine Stukes	Added Archive
   05/17/2020 Jermaine Stukes	Updated Archive
   11/18/2020 Manmeet Vaseer	Fixed Archive Bug. Added handling of Comma, and Double Quotes in a string field.
   12/24/2020 Dan Carmen        Modify to use datetime in purge if it's a datetime field (instead of just a date)
   01/22/2021 Dan Carmen        Add option to permanently delete
   02/17/2021 Dan Carmen        Option to purge the recycle bin
   04/22/2021 Dan Carmen        Change launchBatch method
   02/10/2023 Dan Carmen        Fix the TotalNbrRecordsPurged__c field calculation

 */
global with sharing class PurgeBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
    
    global static final String CLASSNAME='PurgeBatch';
    
    global static final String PURGE='Purge Only';
    global static final String ARCHIVE='Purge and Archive';
    global static final String EMPTY_BIN='Empty Recycle Bin';
    
    global static String[] PROCESS_TYPES= new String[]{PURGE,ARCHIVE,EMPTY_BIN};
    
    // The total number of purge records found.
    global Integer numberPurges = 0;
    // The total number of records purged
    global Integer numberPurged = 0;
    /** The time the process started. */
    global DateTime startTime;
    
    // messages that occur during the process. 
    global String processNotes = '';
    
    global JobHelper jh = new JobHelper(CLASSNAME);
    
    // if we hit a limit, do we want to relaunch the batch job?
    global Boolean relaunchBatch = false;
    
    global PurgeBatch() {
        startTime = DateTime.now();
    } // UserUpdateFromContact
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // save the record - show that the job started
        jh.setStarted();
        return ProcessChecker.getDataLocator(PROCESS_TYPES);
    } // start
    
    // In order to schedule a batch run
    global void execute(SchedulableContext sc) {
        launchBatch();
    } // execute
    
   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<PurgeControl__c> purges = (List<PurgeControl__c>)scope;
      numberPurges += purges.size();
      PurgeControlTracker__c[] insertTrackers = new PurgeControlTracker__c[]{};
      PurgeControlTracker__c[] updateTrackers = new PurgeControlTracker__c[]{};
                
      for (PurgeControl__c pc : purges) {
         handlePurge(pc,insertTrackers, updateTrackers, true);
      } // for (PurgeControl__c pc
        
      System.debug('execute purges='+purges.size()+' insertTrackers='+insertTrackers.size()+' updateTrackers='+updateTrackers.size());
      DmlHelper.performDML(purges, DmlHelper.DML_UPDATE, 'PurgeBatch', 'execute', 'update the purge records', false);
      DmlHelper.performDML(insertTrackers, DmlHelper.DML_INSERT, 'PurgeBatch', 'execute', 'inserting purge trackers', false);
      DmlHelper.performDML(updateTrackers, DmlHelper.DML_UPDATE, 'PurgeBatch', 'execute', 'updating purge trackers', false);
      ErrorLog.checkSave();

   } // execute
    
    // The maximum number of records to retrieve at once. Use 1/4 of what the limits are - just in case. 
    public static Integer MAX_BATCH=(Limits.getLimitDmlRows() / Integer.valueOf(Label.Purge_Divisor))-25;
    public static final Integer LATEST_QUERY_SIZE = PurgeControl__c.LatestQuery__c.getDescribe().getLength();
    
    global void handlePurge(PurgeControl__c pc, PurgeControlTracker__c[] insertTrackers, PurgeControlTracker__c[] updateTrackers, Boolean setNextRunTime) {
        System.debug('handlePurge pc='+pc.Name);
        //BAU Changes//Apex Scan Code
        //pc.DateFieldToCheck__c=pc.DateFieldToCheck__c!=null?String.escapeSingleQuotes(pc.DateFieldToCheck__c):null;
        //pc.AdditionalPurgeCriteria__c=pc.AdditionalPurgeCriteria__c!=null?String.escapeSingleQuotes(pc.AdditionalPurgeCriteria__c):null;
        // verify Purge Control has criteria
        if ((String.isBlank(pc.DateFieldToCheck__c) || pc.NbrDaysToKeep__c == null) && (String.isBlank(pc.AdditionalPurgeCriteria__c))) {
            pc.IsActive__c = false;
            StringHelper.addToProcessNotes(pc, 'Purge criteria could not be found!');
            processNotes += '\n'+pc.Name+': '+pc.Notes__c;
            System.debug('handlePurge purge criteria could not be found');
            return;
        } // if ((String.isBlank(pc.DateFieldToCheck__c
        
        // so we can calculate how many seconds this is running
        Datetime processStart = DateTime.now();
        Integer batchSize = ((pc.BatchSize__c != null && pc.BatchSize__c > 0) ? Integer.valueOf(pc.BatchSize__c) : MAX_BATCH);

        String query = (pc.ProcessType__c==ARCHIVE ? ObjectHelper.getSOQLQuery(pc.ObjectAPIName__c, null, true, true,true, true) : 'Select Id from '+pc.ObjectAPIName__c) +' where ';
        
        Date purgeDate = null;
        DateTime purgeDateTime = null;
        Boolean hasPurgeDate = false;
        if (String.isNotBlank(pc.DateFieldToCheck__c) && pc.NbrDaysToKeep__c != null) {
            String fieldFormat = new ObjectHelper().getFieldType(pc.ObjectAPIName__c, pc.DateFieldToCheck__c);
            if (fieldFormat == 'DATETIME') {
               purgeDateTime = Datetime.now().addDays(-(Integer)pc.NbrDaysToKeep__c);
               purgeDate = purgeDateTime.date();
               pc.PurgeDateTime__c = purgeDateTime;
               query += pc.DateFieldToCheck__c+' < :purgeDateTime ';
            } else {
               purgeDate = Date.today().addDays(-(Integer)pc.NbrDaysToKeep__c);
               pc.PurgeDateTime__c = purgeDate;
               query += pc.DateFieldToCheck__c+' < :purgeDate ';
            }
            hasPurgeDate = true;
        } else {
            // do this so we can log all of the transactions based on one date field
            purgeDate = Date.today();
        }
        
        PurgeControlTracker__c pcd = ProcessChecker.getTracker(pc, purgeDate, insertTrackers, updateTrackers);

        if (String.isNotBlank(pc.AdditionalPurgeCriteria__c)) {
            if (hasPurgeDate) {
                query += ' and ';
            }
            query += pc.AdditionalPurgeCriteria__c;
        } // if (String.isNotBlank(pc.AdditionalPurgeCriteria__c
        if (pc.ProcessType__c == EMPTY_BIN) {
           query += ' and IsDeleted=true ';
        }
        query += ' limit :batchSize ';
        if (pc.ProcessType__c == EMPTY_BIN) {
           query += ' ALL ROWS ';
        }
        pc.LatestQuery__c = query.length() > LATEST_QUERY_SIZE ? query.substring(0, LATEST_QUERY_SIZE) : query;
        
        processNotes += '\n'+query;
        try {
            Integer foundNow = 0;
            Integer failedNow = 0;
            Integer purgedNow = 0;
            //List<SObject[]> archiveList = new List<SObject[]>();
            SObject[] archiveList = new SObject[]{};
            for (SObject[] recs : Database.query(query)) {
                foundNow += recs.size();
                pcd.NbrFound__c += recs.size();
                // keep running number of records.
                System.debug('handlePurge foundNow='+foundNow);
                if (pc.ProcessType__c != EMPTY_BIN) {
                   if (pc.ProcessType__c == ARCHIVE) {
                       archiveList.addAll(recs);
                   }
                   DmlHelper.performDML2(recs, DmlHelper.DML_DELETE, 'PurgeBatch', 'handlePurge', 'Deleting Records', false);
                   if (DmlHelper.performDmlResult != null) {
                       System.debug('handlePurge DmlHelper.performDmlResult.nbrSuccess='+DmlHelper.performDmlResult.nbrSuccess);
                       purgedNow += DmlHelper.performDmlResult.nbrSuccess;
                       pcd.NbrRecsPurged__c += DmlHelper.performDmlResult.nbrSuccess;
                       pcd.NbrFailed__c += DmlHelper.performDmlResult.nbrError;
                       failedNow += DmlHelper.performDmlResult.nbrError;
                       pc.TotalNbrRecordsPurged__c = (pc.TotalNbrRecordsPurged__c != null ? pc.TotalNbrRecordsPurged__c : 0) + DmlHelper.performDmlResult.nbrSuccess;
                   }
                } // if (pc.ProcessType__c != EMPTY_BIN
                if (!recs.isEmpty() && pc.ProcessType__c == EMPTY_BIN || pc.PermanentlyDelete__c) {
                    Database.EmptyRecycleBinResult[] results = Database.emptyRecycleBin(recs);
                    // log the success and failures
                    if (pc.ProcessType__c == EMPTY_BIN) {
                       Integer nbrSuccess = 0;
                       Integer nbrFailed = 0;
                       for (Database.EmptyRecycleBinResult result : results) {
                          if (result.isSuccess()) {
                             nbrSuccess++;
                          } else {
                             nbrFailed++;
                          }
                       } // for (Database.EmptyRecycleBinResult result
                       purgedNow += nbrSuccess;
                       pcd.NbrRecsPurged__c += nbrSuccess;
                       pcd.NbrFailed__c += nbrFailed;
                       failedNow += nbrFailed;
                       pc.TotalNbrRecordsPurged__c = (pc.TotalNbrRecordsPurged__c != null ? pc.TotalNbrRecordsPurged__c : 0) + nbrSuccess;

                    } // if (pc.ProcessType__c == EMPTY_BIN
                }

            } // for (SObject[] recs
            if(!archiveList.isEmpty()){  
                try{
                    System.debug('PROCESS ARCHIVE');
                    processArchive(pc, archiveList, query);
                }
                catch (Exception e) {
                    processNotes += '\n    Exception occurred!';
                    StringHelper.addToProcessNotes(pc, 'Error in query: '+'. Ex='+e.getMessage()+'; '+e.getStackTraceString());
                    System.debug('handlePurge notes='+pc.Notes__c);
                    
                    ErrorLog.logError('PurgeBatch', 'handlePurge', 'Error Executing Purge', pc.Id, e, null, true);
                }                
            } // if(!archiveList.isEmpty()
            
            if (foundNow > 0) {
                pcd.NbrIterations__c++;
            }
            
            //Database.DeleteResult[] results = Database.delete(Database.query(query));
            //pcd.NbrRecsPurged__c = results.size();
            String purgeNotes = 'foundNow='+foundNow+' purgedNow='+purgedNow+' failedNow='+failedNow;
            processNotes += ('\n    '+purgeNotes);
            numberPurged += purgedNow;
            pc.MoreRecords__c = foundNow >= batchSize;
            // if there are more records, set the next run time to right now, otherwise set based on the setup.
            if (setNextRunTime) {
               if (pc.MoreRecords__c) {
                  pc.NextRunTime__c = Datetime.now();
               } else {
                  ProcessChecker.setNextRunTime(pc);
               }
            } // if (setNextRunTime
            
            // if we're at the max, relaunch the batch
            
            relaunchBatch = numberPurged > 0 && (relaunchBatch || (pcd.NbrRecsPurged__c >= batchSize));
            StringHelper.addToProcessNotes(pc, purgeNotes+' relaunchBatch='+relaunchBatch);
        } catch (Exception e) {
            pc.IsActive__c=false;
            StringHelper.addToProcessNotes(pc, 'Error in query: '+query+'. Ex='+e.getMessage()+'; '+e.getStackTraceString());
            System.debug('handlePurge notes='+pc.Notes__c);
            processNotes += '\n    Exception occurred!';
            ErrorLog.logError('PurgeBatch', 'handlePurge', 'Error Executing Purge', pc.Id, e, null, true);
        }
        pcd.EndDate__c=DateTime.now();
        Integer numSeconds = Integer.valueOf((pcd.EndDate__c.getTime() - processStart.getTime())/1000);
        pcd.SecondsProcessed__c += numSeconds;
    } // handlePurge
    
   private static void processArchive(PurgeControl__c currentPurge, SObject[] archiveRecList, String queryString ) {       
        String recordName = currentPurge.ObjectAPIName__c+'_'+Date.today().format();
        String processNotes = '';
        //Create file for every array in list
        
        try {
            createArchiveFile(archiveRecList, currentPurge.ObjectAPIName__c, queryString);
            processNotes = 'Archive Process Completed at: '+DateTime.now().format();
            //Update Purge Control record date
            //currentPurge.Next_Archive_Date__c = currentPurge.ArchiveFrequency__c != Null ? Date.today() + Integer.valueof(currentPurge.ArchiveFrequency__c) : Date.today()+30;            
        }
        catch(Exception ex){
            processNotes = 'Error encountered. Archiving not completed \n Ex='+ex.getMessage()+'; '+ex.getStackTraceString();
        }
        StringHelper.addToProcessNotes(currentPurge, processNotes);     
   } // processArchive
    
    public static void createArchiveFile(SObject[] dataRows, String archiveObject, String queryString)
    {
        String csvHeader;
        Folder archiveFolder = [SELECT Id, Name FROM Folder WHERE Name = 'Archive Logs'];
        List<String> csvRowValues = new List<String>();
        //Create CSV File
        String fileName = archiveObject+'_'+DateTime.now().format()+'.csv';
        //Create CSV Rows
        String headerFields = queryString.substringBetween('Select', 'From');
        headerFields.remove(' ');
        csvHeader =  headerFields+'\n';
        List<String> fieldList = headerFields.split(',');
        
        for(SObject dataFile : dataRows){
            Map<String, Object> archiveFieldMap = dataFile.getPopulatedFieldsAsMap();
            String fileRow = '';
            for(String csvField :  fieldList){
                string fieldValue = archiveFieldMap.get(csvField) != null ? String.valueof(archiveFieldMap.get(csvField)) : ' ';
                fieldValue = escapeSpecialChars(fieldValue);
                fileRow +=  ',' + fieldValue;                
            }
            fileRow = fileRow.replaceFirst(',', '');
            System.debug('FILE ROW: '+fileRow);
            csvRowValues.add(fileRow);
        }
        String csvFile = csvHeader + String.join(csvRowValues,'\n');
        Document doc = new Document(Name = fileName, Body = Blob.valueOf(csvFile), FolderId = archiveFolder.id, Type = 'csv', ContentType='application/vnd.ms-excel');
        insert doc;
    } // createArchiveFile
    
    public static String escapeSpecialChars(String value)	{
        String retVal = value;
        if (String.isNotBlank(retVal) && (retVal.indexOf(',') != -1 || retVal.indexOf('"') != -1 || retVal.indexOf('\n') != -1)) {
            retVal = '"' + retVal.replaceAll('"', '') + '"';
        }
        
        return retVal;
    } // escapeSpecialChars
 
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Purge Controls Processed: '+numberPurges+' '; 
      message += '\nTotal records purged: '+numberPurged+' '; 
      //message += '\nTotal Users updated: '+nbrUsersUpdated+' '; 
        
      message += '\n\n'+processNotes;
        
      jh.completeJob(bc, 'Purge Batch', message);
        
      // only run once for a test
      if (!Test.isRunningTest()) {
         launchBatch();
      }
   } // finish
    
   public static void launchBatch() {
      DateTime nextRunTime = ProcessChecker.getNextRunTime(PROCESS_TYPES);
      if (nextRunTime != null) {
         JobHelper.launchBatchWithSchedule(new PurgeBatch(), CLASSNAME, nextRunTime, 1);
      }
   } // launchBatch
    
} // class PurgeBatch