/* Backup the metadata of the organization
   
  History
  -------
  05/30/2017 Dan Carmen   Created
  10/30/2017 Dan Carmen   Added extra tracking
  11/03/2017 Dan Carmen   Added ability to log the comments.
  11/03/2017 Dan Carmen   Additional check to mark the IsTest checkbox.
  12/06/2017 Dan Carmen   Check if a piece of code is deleted.
  08/17/2018 Dan Carmen   Handle Aura components
  09/12/2018 Cindy Freeman	Changed to use Files instead of Attachments
  11/10/2023 Dan Carmen   Ability to set the Can Be Deleted field based on latest comment including the "Can Be Deleted" value without spaces.
  
 */
global with sharing class MetaDataBackup implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
   
   global JobHelper jh = new JobHelper('MetaDataBackup');

   /** The time the process started. */
   global DateTime startTime;
   global Integer nbrProcessed = 0;
   global Integer nbrUpdated = 0;
   global Integer nbrCreated = 0;
   
   global String processNotes = '';
   
   // 
   global static Set<Id> recordIdSet = new Set<Id>();

   global MetaDataBackup() {
      startTime = DateTime.now();
   } // UserUpdateFromContact
   
   global MetaDataBackup(String p_currentType) {
      currentType = p_currentType;
      startTime = DateTime.now();
   } // UserUpdateFromContact
   
   public static String TYPE_CLASS='Apex Class';
   public static String TYPE_TRIGGER='Apex Trigger';
   public static String TYPE_COMPONENT='Visualforce Component';
   public static String TYPE_PAGE='Visualforce Page';
   public static String TYPE_AURA='Lightning Component';
   
   global String currentType = TYPE_CLASS;
   
   public static Integer QUERY_LIMIT=10000;
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      resetLastCheckedDate(currentType);
      
      if (currentType == TYPE_CLASS) {
         // this is the first time the code runs. We'll clear out the 
         return Database.getQueryLocator([select Id
                                                ,Body
                                                ,ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,IsValid
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,LengthWithoutComments
                                                ,Name
                                                ,NamespacePrefix
                                                ,Status
                                            from ApexClass 
                                          where NamespacePrefix = null
                                          order by Name limit :QUERY_LIMIT]);
      } else if (currentType == TYPE_TRIGGER) {
         return Database.getQueryLocator([select Id
                                                ,Body
                                                ,ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,IsValid
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,LengthWithoutComments
                                                ,Name
                                                ,NamespacePrefix
                                                ,Status
                                            from ApexTrigger 
                                          where NamespacePrefix = null
                                          order by Name limit :QUERY_LIMIT]);
      } else if (currentType == TYPE_COMPONENT) {
         return Database.getQueryLocator([select Id
                                                ,ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,Markup
                                                ,Name
                                                ,NamespacePrefix
                                            from ApexComponent 
                                          where NamespacePrefix = null
                                          order by Name limit :QUERY_LIMIT]);
      } else if (currentType == TYPE_PAGE) {
         return Database.getQueryLocator([select Id
                                                ,ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,Markup
                                                ,Name
                                                ,NamespacePrefix
                                            from ApexPage 
                                          where NamespacePrefix = null
                                          order by Name limit :QUERY_LIMIT]);
      } else if (currentType == TYPE_AURA) {
         return Database.getQueryLocator([Select Id
                                                ,AuraDefinitionBundle.ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,Source
                                                ,AuraDefinitionBundle.MasterLabel
                                                ,AuraDefinitionBundle.NamespacePrefix
                                                ,DefType    // HELPER/CONTROLLER/COMPONENT...
                                                ,Format     // JS/XML...
                                                ,AuraDefinitionBundle.DeveloperName
                                                ,AuraDefinitionBundle.Description
                                            From AuraDefinition
                                           Where AuraDefinitionBundle.NamespacePrefix = null
                                           Order by AuraDefinitionBundle.MasterLabel limit :QUERY_LIMIT
                                           ]);
      }
      return null;
   } // start

   // reset the last checked date on the records so we know which ones were updated
   global void resetLastCheckedDate(String recType) {
      for (MetadataBackup__c[] backups : [Select Id, LastCheckedDate__c 
                                            from MetadataBackup__c
                                           Where CodeIsDeleted__c=false and Type__c = :recType]) {
         for (MetadataBackup__c backup : backups) {
            backup.LastCheckedDate__c = null;
         }
         update backups;
      }

   } // resetLastCheckedDate
   
   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      MetaDataBackup uufc = new MetaDataBackup();
      Integer batchSize = getBatchSize();
      database.executeBatch(uufc, batchSize);
   } // execute

   global Integer getBatchSize() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('MetaDataBackup');
      Integer batchSize = ((abc != null && abc.BatchSize__c != null) ? (Integer)abc.BatchSize__c : 20);
      return batchSize;
   }

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      handleObjects(scope);
   } // execute

   public static final Integer LATEST_COMMENTS_SIZE = MetadataBackup__c.LatestComment__c.getDescribe().getLength();
   
   public static String[] TEST_VALUES=Label.MetadataBackup_TestValues.split(',');

   global void handleObjects(SObject[] recs) {
      // collect all of the ids
      Id[] recIds = new Id[]{};
      for (SObject rec : recs) {
         recIds.add(rec.Id);
      }
      
      //Map<Id,Attachment> attachByObjectIdMap = new Map<Id,Attachment>();
      Map<Id, FileWrapper> fileByObjectIdMap = new Map<Id, FileWrapper>();
      //Attachment[] insertAttachments = new Attachment[]{};
      FileWrapper[] fileWrapList = new FileWrapper[]{};
      
      // select the backup records
      Map<Id,MetadataBackup__c> backupMap = getBackupMap(recIds, currentType);
      
      MetadataBackup__c[] backupInserts = new MetadataBackup__c[]{};
      Map<Id,MetadataBackup__c> backupUpdateMap = new Map<Id,MetadataBackup__c>();
      
      Map<Id,MetadataBackupDetail__c> detailInsertMap = new Map<Id,MetadataBackupDetail__c>();
      
      Boolean isAura = (recs[0].getSObjectType() == AuraDefinition.sObjectType);
      
      for (SObject rec : recs) {
         MetadataBackup__c backup = backupMap.get(rec.Id);
         AuraDefinition auraDef = (currentType == TYPE_AURA ? (AuraDefinition)rec : null);
         
         if (backup == null) {
            backup = createNewBackup(rec);
         }
         backup.LastCheckedDate__c = Datetime.now();
         
         Datetime lastModDate = (DateTime)rec.get('LastModifiedDate');
         if (backup.LastModifiedDate__c == null || backup.LastModifiedDate__c != lastModDate) {
            createBackup(backup, detailInsertMap);
            backup.CodeVersion__c = backup.CodeVersion__c+1;
            backup.LastModifiedDate__c = (Datetime)rec.get('LastModifiedDate');
            backup.LastModifiedBy__c = (Id)rec.get('LastModifiedById');
            if (auraDef != null) {
               backup.APIVersion__c = String.valueOf(auraDef.AuraDefinitionBundle.ApiVersion);
               backup.DefType__c = auraDef.DefType;
               backup.Format__c = auraDef.Format;
               backup.Description__c = auraDef.AuraDefinitionBundle.Description;
            } else {
               backup.APIVersion__c = String.valueOf(rec.get('ApiVersion'));
            }
            if (currentType == TYPE_CLASS || currentType == TYPE_TRIGGER) {
               backup.CodeLength__c = Integer.valueOf(rec.get('LengthWithoutComments'));
            }

            String codeFldName = (currentType == TYPE_COMPONENT || currentType == TYPE_PAGE ? 'Markup' 
                                 : (currentType == TYPE_AURA ? 'Source' : 'Body'));
            String objectBody = (String)rec.get(codeFldName);
            // the length isn't stored in the object, so we'll use the actual length here
            if (currentType == TYPE_COMPONENT || currentType == TYPE_PAGE || currentType == TYPE_AURA) {
               backup.CodeLength__c = (objectBody != null ? objectBody.length() : 0);
            }
            backup.LatestComment__c = parseLatestComment(objectBody, LATEST_COMMENTS_SIZE);
            if (String.isNotBlank(backup.LatestComment__c) && backup.LatestComment__c.contains('CanBeDeleted')) {
               backup.CanBeDeleted__c = true;
            }
            Boolean isTest = false;
            for (String valueToCheck : TEST_VALUES) {
               if (objectBody.contains(valueToCheck)) {
                  isTest=true;
                  break;
               }
            } // for (String valueToCheck
            backup.TestClass__c = isTest;
            
            /*
            Attachment attach = new Attachment();
            attach.Body = Blob.valueOf(objectBody);
            attach.Name = backup.Name+'-'+backup.CodeVersion__c+getFileExtension(backup);
            attach.ContentType='text/plain';
            */
            String attachName = backup.Name+'-'+backup.CodeVersion__c+getFileExtension(backup);
            if (backup.Id == null) {
               	//attachByObjectIdMap.put(backup.ObjectId__c, attach);
               	FileWrapper fw = new FileWrapper(new Id[]{backup.ObjectId__c}, attachName, attachName, null, Blob.valueOf(objectBody));               	
               	fileByObjectIdmap.put(backup.ObjectId__c, fw);
            } else {
               	//attach.ParentId = backup.Id;
               	//insertAttachments.add(attach);
               	FileWrapper fw = new FileWrapper(new Id[]{backup.Id}, attachName, attachName, null, Blob.valueOf(objectBody));
         		fileWrapList.add(fw);
            }
         } // if (backup.LastModifiedDate__c == null
         // always save the records
         if (backup.Id == null) {
            backupInserts.add(backup);
         } else {
            backupUpdateMap.put(backup.Id, backup);
         }
      } // for (ApexClass ac

      saveBackupDetail(detailInsertMap, backupUpdateMap);
      /*
      if (!detailInsertMap.isEmpty()) {
         Database.insert(detailInsertMap.values(),false);
         for (Id backupId : detailInsertMap.keySet()) {
            MetadataBackupDetail__c detail = detailInsertMap.get(backupId);
            MetadataBackup__c backup = backupUpdateMap.get(backupId);
            if (detail != null && backup != null && detail.Id != null) {
               backup.PreviousVersion__c = detail.Id;
               if (backup.EarliestVersion__c == null) {
                  backup.EarliestVersion__c = detail.Id;
               }
            }
         } // for (Id backupId
         
      } // if (!detailInsertMap
      if (!backupUpdateMap.isEmpty()) {
         update backupUpdateMap.values();
      }
      */
      
      if (!backupInserts.isEmpty()) {
         insert backupInserts;
         for (MetadataBackup__c backup : backupInserts) {
            //Attachment attach = attachByObjectIdMap.get(backup.ObjectId__c);
            //if (attach != null) {
            //   attach.ParentId = backup.Id;
            //   insertAttachments.add(attach);
            //}
            FileWrapper fw = fileByObjectIdMap.get(backup.ObjectId__c);
            if (fw != null)
            {	fw.parentIds = new Id[]{backup.Id};
            	fileWrapList.add(fw);
            }
         }
      }
      
      //if (!insertAttachments.isEmpty()) {
      //   insert insertAttachments;
      //}
      if (!fileWrapList.isEmpty())
      {		AddFileQueueable afq = new AddFileQueueable(fileWrapList);	
			afq.processRecs();
	  }
      
   } // handleObjects
   
   global void saveBackupDetail(Map<Id,MetadataBackupDetail__c> detailInsertMap, Map<Id,MetadataBackup__c> backupUpdateMap) {
      if (!detailInsertMap.isEmpty()) {
         Database.insert(detailInsertMap.values(),false);
         for (Id backupId : detailInsertMap.keySet()) {
            MetadataBackupDetail__c detail = detailInsertMap.get(backupId);
            MetadataBackup__c backup = backupUpdateMap.get(backupId);
            if (detail != null && backup != null && detail.Id != null) {
               backup.PreviousVersion__c = detail.Id;
               if (backup.EarliestVersion__c == null) {
                  backup.EarliestVersion__c = detail.Id;
               }
            }
         } // for (Id backupId
         
      } // if (!detailInsertMap

      if (!backupUpdateMap.isEmpty()) {
         update backupUpdateMap.values();
      }

   } // saveBackupDetail
   
   global MetadataBackupDetail__c createBackup(MetadataBackup__c backup, Map<Id,MetadataBackupDetail__c> detailInsertMap) {
      MetadataBackupDetail__c detail = null;
      if (backup.Id != null) {
         detail = new MetadataBackupDetail__c(MetadataBackup__c=backup.Id, Name=backup.Name+'-'+backup.CodeVersion__c);
         detail.APIVersion__c = backup.APIVersion__c;
         detail.CodeLength__c = backup.CodeLength__c;
         detail.LastModifiedDate__c = backup.LastModifiedDate__c;
         detail.LastModifiedBy__c = backup.LastModifiedBy__c;
         detail.LatestComment__c = backup.LatestComment__c;
         detailInsertMap.put(backup.Id, detail);
      }
      return detail;
   } // createBackup

   global String getFileExtension(MetadataBackup__c backup) {
      String fileExt = (currentType == TYPE_CLASS ? '.cls' : 
                             (currentType == TYPE_TRIGGER ? '.trigger' :
                                   (currentType == TYPE_COMPONENT ? '.component' :
                                       (currentType == TYPE_PAGE ? '.page' : 
                                           (currentType == TYPE_AURA ? backup.Format__c : '')
                                       )
                                   )
                             )
                        );
      return fileExt;
   } // getFileExtension

   global MetadataBackup__c createNewBackup(SObject rec) {
      String recName = null;
      if (currentType == TYPE_AURA) {
         AuraDefinition ad = (AuraDefinition)rec;
         recName = ad.AuraDefinitionBundle.MasterLabel+'-'+ad.DefType;
      } else {
         recName = (String)rec.get('Name');
      }
      MetadataBackup__c backup = new MetadataBackup__c(Name=recName
               ,CodeVersion__c=0
               ,CreatedBy__c=(Id)rec.get('CreatedById')
               ,CreatedDate__c=(Datetime)rec.get('CreatedDate')
               ,ObjectId__c=rec.Id
               ,Type__c=currentType
              );
      return backup;
   } // createNewBackup

   global Map<Id,MetadataBackup__c> getBackupMap (Id[] recIds, String recType) {
      // select the backup records
      MetadataBackup__c[] backups = [Select Id, Name
                                            ,APIVersion__c
                                            ,CanBeDeleted__c
                                            ,CodeIsDeleted__c
                                            ,CodeVersion__c
                                            ,CodeLength__c
                                            ,CreatedBy__c
                                            ,CreatedDate__c
                                            ,DefType__c
                                            ,EarliestVersion__c
                                            ,Format__c
                                            ,LastCheckedDate__c
                                            ,LastModifiedBy__c
                                            ,LastModifiedDate__c
                                            ,LatestComment__c
                                            ,ObjectId__c
                                            ,PreviousVersion__c
                                            ,Type__c
                                       from MetadataBackup__c
                                      Where ObjectId__c in :recIds
                                        and Type__c = :recType];
      Map<Id,MetadataBackup__c> backupMap = new Map<Id,MetadataBackup__c>();
      for (MetadataBackup__c backup : backups) {
         backupMap.put(backup.ObjectId__c, backup);
      }
      return backupMap;
   } // getBackups
   
   /*
         String dateRegex = '^(0?[1-9]|[12][0-9]|3[01])[\/\-](0?[1-9]|1[012])[\/\-]\d{4}$';
      Pattern regexPattern = Pattern.compile(dateRegex);
      Matcher regexMatcher = regexPattern.matcher(message);
   */
   
   public static String DATE_REGEX = '(0?[1-9]|1[012])/(0?[1-9]|[12][0-9]|3[01])/((19|20)\\d\\d)';  

   
   public static String parseLatestComment(String textToParse, Integer maxSize) {
      if (String.isBlank(textToParse)) {
         return '';
      }
      String latestComment = '';
      // look for the comment box - beginning of file should start with '<!--' or '/*' for this to work
      // if one of the opening markers is found, extract the text up to the closing marker.
      // from the end of the extracted text, look for the latest date - ##/##/#### format - regex expression?
      // pull everything from the date to the end of the extracted text.
      String endOfCommentsMarker = '';
      Integer startExtractPos = 0;
      if (textToParse.startsWith('<!--')) {
         endOfCommentsMarker = '-->';
         startExtractPos = 4;
      } else if (textToParse.startsWith('/*')) {
         endOfCommentsMarker = '*/';
         startExtractPos = 2;
      }
      System.debug('parseLatestComment endOfCommentsMarker='+endOfCommentsMarker);
      // if no comments don't continue
      if (String.isBlank(endOfCommentsMarker)) {
         return '';
      }
      Integer endOfCommentsPos = textToParse.indexOf(endOfCommentsMarker);
      String comments = endOfCommentsPos > 0 ? textToParse.subString(startExtractPos,endOfCommentsPos) : '';
      System.debug('parseLatestComment startExtractPos='+startExtractPos+' endOfCommentsPos='+endOfCommentsPos+' comments='+comments);
      if (String.isBlank(comments)) {
         return '';
      }

      System.debug('parseLatestComment DATE_REGEX='+DATE_REGEX);
      Pattern regexPattern = Pattern.compile(DATE_REGEX);
      Matcher regexMatcher = regexPattern.matcher(comments);
      try {
         Integer startPos = 0;
         Integer endPos = 0;
         while (regexMatcher.find()) {
            System.debug('parseLatestComment inside loop group='+regexMatcher.group()+' regionStart='+regexMatcher.regionStart()+' regionEnd='+regexMatcher.regionEnd()+' end='+regexMatcher.end());
            startPos = regexMatcher.start();
            endPos = regexMatcher.end();
         } // while

         System.debug('startPos='+startPos+' endPos='+endPos);
         // remove some of the extra spaces
         if (startPos > 0 && endPos > startPos) {
            latestComment=comments.subString(startPos).trim();
            latestComment=(latestComment.replace('\t',' ').replace('  ',' ')).left(maxSize);
         }
      } catch (Exception e) {
         System.debug('parseLatestComment exception: '+e.getMessage()+'; '+e.getStackTraceString());
      }

      return latestComment; 
      
   } // parseLatestComment
   
   global Integer nbrMarkedAsDelete = 0;
   
   global void checkForDeleted(String recType) {
      Map<Id,MetadataBackupDetail__c> detailInsertMap = new Map<Id,MetadataBackupDetail__c>();
      Map<Id,MetadataBackup__c> backupUpdateMap = new Map<Id,MetadataBackup__c>();
      
      for (MetadataBackup__c backup : [Select Id, Name
                                            ,APIVersion__c
                                            ,CodeIsDeleted__c
                                            ,CodeVersion__c
                                            ,CodeLength__c
                                            ,CreatedBy__c
                                            ,CreatedDate__c
                                            ,EarliestVersion__c
                                            ,LastCheckedDate__c
                                            ,LastModifiedBy__c
                                            ,LastModifiedDate__c
                                            ,LatestComment__c
                                            ,ObjectId__c
                                            ,PreviousVersion__c
                                            ,Type__c
                                            from MetadataBackup__c
                                           Where CodeIsDeleted__c=false and Type__c = :recType
                                             and LastCheckedDate__c = null]) {
         nbrMarkedAsDelete++;
         createBackup(backup, detailInsertMap);
         backup.CodeLength__c = 0;
         backup.CodeIsDeleted__c = true;
         backup.LastCheckedDate__c = Datetime.now();
         backupUpdateMap.put(backup.Id, backup);
      } // for (MetadataBackup__c backup
      
      saveBackupDetail(detailInsertMap, backupUpdateMap);
      
   } // checkForDeleted
   
   global void finish(Database.BatchableContext bc){
      
      checkForDeleted(currentType);
      String message = '\nProcessing: '+currentType+', nbrProcessed: '+nbrProcessed+' '; 
      message += '\nBackup records updated: '+nbrUpdated+' '; 
      message += '\nBackup records created: '+nbrCreated+' '; 
      message += '\nBackup records marked as deleted: '+nbrMarkedAsDelete+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'Metadata Checker', message);
      
      String nextJob = getNextJob();
      /*
      String nextJob = (currentType == TYPE_CLASS ? TYPE_TRIGGER : 
                             (currentType == TYPE_TRIGGER ? TYPE_COMPONENT :
                                   (currentType == TYPE_COMPONENT ? TYPE_PAGE : 
                                      (currentType == TYPE_PAGE ? TYPE_AURA : null)
                                   )
                             )
                        );
      */
      if (!Test.isRunningTest() && String.isNotBlank(nextJob)) {
         database.executeBatch(new MetaDataBackup(nextJob), getBatchSize());
      }
   } // finish
   
   global String getNextJob() {
      String nextJob = (currentType == TYPE_CLASS ? TYPE_TRIGGER : 
                             (currentType == TYPE_TRIGGER ? TYPE_COMPONENT :
                                   (currentType == TYPE_COMPONENT ? TYPE_PAGE : 
                                      (currentType == TYPE_PAGE ? TYPE_AURA : null)
                                   )
                             )
                        );
      return nextJob;
   } // getNextJob
   
} // class MetaDataBackup