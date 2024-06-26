/* 
   Methods for working with the DataLoad object

  Referral Source files:
  Can contains Referral Accounts, Referral Contacts, or both.
  If just Referral Contacts, has to have the ID of the Referral Account.
   
  History
  -------
  07/30/2020 Dan Carmen   Created
  12/14/2020 Dan Carmen   Change to without sharing
  03/10/2021 Dan Carmen   Changes to use approval process
  03/26/2021 Dan Carmen   Fix for field accessibility
  05/14/2021 Dan Carmen   Fix for inserting Createable fields (that aren't updateable)
  06/16/2022 Dan Carmen   Fix for RequestStartTime__c

 */
public without sharing class DataLoadMethods {
   // on initial creation - for both dataload and dataload record
   public static final String STATUS_PENDING='Pending';
   // after the file is successfully loaded
   public static final String STATUS_LOADED='File Loaded';
    
   // if the dataload record is processed successfully
   public static final String STATUS_SUCCESS='Success';
   public static final String STATUS_READY='Ready To Process';
    
   public static final String STATUS_PARSE='Parse File';
   public static final String STATUS_PARSING='Parsing File';
   public static final String STATUS_FILE_PARSED='File Parsed';
    
   public static final String STATUS_PROCESS='Process Data Records';
   public static final String STATUS_PROCESSSING='Processing';
   public static final String STATUS_COMPLETE='Complete';
   public static final String STATUS_APPROVED='Approved';
    
   public static final String STATUS_PROCESS_BULK='Process Bulk Job';
   public static final String STATUS_BULK_SUBMITTED='Bulk Job Submitted';
   public static final String STATUS_BULK_COMPLETE='Bulk Job Complete';
   public static final String STATUS_APPROVAL='Waiting For Approval';

   public static final String STATUS_CHECK_DUPES='Checking Duplicates';
   public static final String STATUS_UPDATE_SF='Updating Salesforce';
   // if there is an error processing the record
   public static final String STATUS_ERROR='Error';

   public static final String TYPE_LEAD_LIST='Lead List';
   public static final String TYPE_REF_SOURCE='Referral Source List';
   public static final String TYPE_SF_UPDATE='Record Update-Inline';
   public static final String TYPE_SF_UPDATE_BULK='Record Update-Bulk Load';
   public static final String TYPE_SF_INSERT='Record Insert-Inline';
   public static final String TYPE_SF_INSERT_BULK='Record Insert-Bulk Load';
   public static final String TYPE_SF_DELETE='Record Delete-Inline';
   public static final String TYPE_SF_DELETE_BULK='Record Delete-Bulk Load';
    
   public static Boolean SKIP_TRIGGER=false;
    
   public static void handleTrigger(DataLoad__c[] recs, Map<Id,DataLoad__c> oldMap) {
      System.debug('DataLoadMethods.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER);
      if (SKIP_TRIGGER) {
         return;           
      }
      Map<Id,DataLoad__c> checkForLoadedFile = new Map<Id,DataLoad__c>();
      for (DataLoad__c rec : recs) {
         DataLoad__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (Trigger.isBefore) {
            System.debug('handleTrigger before status='+rec.Status__c);
            if (rec.FileType__c.startsWith('Record ') && (oldRec == null || rec.FileType__c != oldRec.FileType__c 
                                                                                  || rec.UpdateAPIObjectName__c != oldRec.UpdateAPIObjectName__c)) {
               if (String.isBlank(rec.UpdateAPIObjectName__c)) {
                  rec.UpdateAPIObjectName__c.addError('Must Include the API Object Name to Update or Insert!'); 
               } else {
                  Map<String, Schema.SObjectField> fieldMap = new ObjectHelper().getFieldMap(rec.UpdateAPIObjectName__c);
                  if (fieldMap == null) {
                     rec.UpdateAPIObjectName__c.addError('This does not seem to be a valid object Name!');
                  }
               }
            } else if (rec.FileType__c == TYPE_LEAD_LIST || rec.FileType__c == TYPE_REF_SOURCE) {
               rec.UpdateAPIObjectName__c = null;
            }
            if (rec.Status__c == STATUS_PARSE && !rec.FileLoaded__c) {
               rec.Status__c.addError('File Must Be Loaded Before The File Can Be Parsed.');
            } else if (rec.Status__c == STATUS_PROCESS_BULK && oldRec != null && rec.Status__c != oldRec.Status__c) {
               // populate the run time to get picked up by the batch job.
               rec.BulkNextRunTime__c = (rec.RequestStartTime__c != null ? rec.RequestStartTime__c : Datetime.now());
            } else if (rec.Status__c == STATUS_PROCESS && rec.RequestStartTime__c == null) {
               rec.RequestStartTime__c = Datetime.now();
            } else if (rec.Status__c == STATUS_APPROVED) {
               if (rec.IsBulk__c) {
                  rec.BulkNextRunTime__c = (rec.RequestStartTime__c != null ? rec.RequestStartTime__c : Datetime.now());
                  rec.Status__c = STATUS_PROCESS_BULK;
               } else if (rec.IsInline__c) {
                  rec.RequestStartTime__c = (rec.RequestStartTime__c != null ?  rec.RequestStartTime__c : Datetime.now());
                  rec.Status__c = STATUS_PARSE;
               }
            }
         } else if (Trigger.isAfter) {
            System.debug('handleTrigger after status='+rec.Status__c);
            if (Trigger.isUpdate && rec.Status__c == STATUS_PARSE && rec.FileLoaded__c) {
               DataLoadBatch.launchBatch();
            } else if (Trigger.isUpdate && rec.Status__c == STATUS_PROCESS_BULK && rec.FileLoaded__c) {
               if (rec.BulkNextRunTime__c <= Datetime.now()) {
                  DataLoadQueueable.checkLaunchQueuable(rec.Id); 
               } else {
                  DataLoadBatch3.launchBatchCheck();
               }
            } else if (Trigger.isUpdate && rec.Status__c == STATUS_PROCESS && rec.FileLoaded__c ) {
               if (rec.NbrLoadRecords__c > 0) {
                  DataLoadBatch2.launchBatch();
               } else {
                  rec.Status__c.addError('Data Load Records not found!');
               }
            }
         }
          
      } // for (DataLoad__c rec
       
   } // handleTrigger
    

   /*********************************  If a file is deleted from the DataLoad record  *********************************/
   public static void handleDeletedFiles(Map<String,ContentDocumentLink> deleteCdlMap) {
      // select the data load records
      // Only change the status if the file hasn't been parsed
      DataLoad__c[] dataLoads = [Select Id, Name, FileType__c, HeaderRow__c, HeadersAreValid__c, NbrHeaders__c, ProcessNotes__c, Status__c
                                                                       ,FileLoaded__c, FileParsed__c
                                                                       ,NbrValidHeaders__c,UpdateAPIObjectName__c
                                                                   From DataLoad__c
                                                                  Where Id in :deleteCdlMap.keySet()
                                                                    and FileParsed__c=false];
      for (DataLoad__c dLoad : dataLoads) {
         dLoad.Status__c = 'Pending';
         dLoad.FileLoaded__c = false;
      }
      update dataLoads;
   } // handleDeletedFiles
    
   /*********************************  For initial file load from ContentDocumentLink trigger *********************************/
    
   public static String[] OKAY_EXTENSIONS = new String[]{'csv','log','txt'};
   
   public class CdlWrap {
      public ContentDocumentLink cdl=null;
      public ContentVersion cver=null;
      public String notes='';
   } // class CdlWrap
   
   public static Integer MAX_FILE_SIZE=10000000;
    
   public static void checkDataLoadRecs(Map<Id,ContentDocumentLink> cdlMap, String[] dataLoadIds) {
      // only allow csv files to be attached. Txt and log files will be ignored.
      CdlWrap[] goodRecs = new CdlWrap[]{};
      ContentVersion[] cversions = [select Id
                                          ,ContentBodyId
	                                      ,ContentDocumentId
	                                      ,ContentDocument.ParentId
	                                      ,ContentDocument.Title
                                          ,ContentSize, FileExtension, FileType, IsLatest, PublishStatus, VersionData, VersionNumber, LastModifiedDate
                                      from ContentVersion
                                     Where ContentDocumentId in :cdlMap.keySet()];
      Boolean allOkay = true;
      for (ContentVersion cver : cversions) {
         ContentDocumentLink cdl = cdlMap.remove(cver.ContentDocumentId);
         if (cdl != null) {
            if (!OKAY_EXTENSIONS.contains(cver.FileExtension)) {
               allOkay = false;
               cdl.addError('Attached files must be of type csv');
            } else if (cver.FileExtension == 'csv') {
               CdlWrap cwrap = new CdlWrap();
               cwrap.cdl=cdl;
               cwrap.cver=cver;
               goodRecs.add(cwrap);
            }
         }
      } // for (ContentVersion cver : cversions
      if (!allOkay) {
           return;
      }
      Map<Id,DataLoad__c> dataLoadMap = new Map<Id,DataLoad__c>([Select Id, Name, DataLoadApproval__c, FileSize__c, FileType__c, HeaderRow__c, HeadersAreValid__c, NbrHeaders__c, ProcessNotes__c, Status__c
                                                                       ,NbrValidHeaders__c,UpdateAPIObjectName__c,FileLoaded__c, ApprovalNeeded__c
                                                                   From DataLoad__c
                                                                  Where Id in :dataLoadIds]);
      DataLoad__c[] updateDataLoads = new DataLoad__c[]{};
      for (CdlWrap cwrap : goodRecs) {
         DataLoad__c dataLoad = dataLoadMap.get(cwrap.cdl.LinkedEntityId);
         if (dataLoad != null) {
            dataLoad.FileSize__c = cwrap.cver.ContentSize;
            if (dataLoad.FileSize__c > MAX_FILE_SIZE) {
               dataLoad.Status__c = STATUS_ERROR;
               throw new DataLoadException('** This file is too large to process! Please keep the file size under 10MB! **');
               //StringHelper.addToProcessNotes(dataLoad, '** This file is too large to process! Please keep the file size under 10MB! **');
               //updateDataLoads.add(dataLoad);
            } else {
               checkHeaders(cwrap, dataLoad);
               updateDataLoads.add(dataLoad);
            }
         }
      }
      if (!updateDataLoads.isEmpty()) {
         update updateDataLoads;
         // see if the records need to get approval
         for (DataLoad__c dataLoad : updateDataLoads) {
            if (dataLoad.Status__c == STATUS_APPROVAL || dataLoad.Status__c == STATUS_READY) {
               // enter into the approval process
               Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
               req1.setComments('Submitting request for approval.');
               req1.setObjectId(dataLoad.Id);
               // Submit the approval request for the account
               //try {
                  Approval.ProcessResult result = Approval.process(req1);
               //} catch (Exception e) {
                  // log an error - referral wasn't submitted for approval!
               //   dataLoad.addError('Error setting approval: '+e);
               //}
            }
         } // for (DataLoad__c dataLoad : updateDataLoads
      } // if (!updateDataLoads.isEmpty(
   } // checkDataLoadRecs
    
   public static String LEAD_LIST_HEADERS='FirstName,LastName,Phone,Email,Company,Street,City,State,PostalCode';
   public static String REF_SRC_CTCT='FirstName,LastName,Phone,Email';
   public static String REF_SRC_ACCT='Company,Street,City,State,PostalCode,Referral_Source_Business_Type__c';
   public static String REF_SRC_HEADERS='FirstName,LastName,Phone,Email,Company,Street,City,State,PostalCode,Referral_Source_Business_Type__c';
    
    
   public class HeaderWrap {
      public String headerRow=null;
      public String headerRowClean=null;
      public String[] headerNames = new String[]{};
      public String[] headerNamesClean = new String[]{};
      // if the file is too large and it's a bulk load, allow the header check to be skipped
      public Boolean skipHeaderCheck = false;
   } // lass HeaderWrap
        
   public static HeaderWrap getHeaderRow(CdlWrap cwrap, DataLoad__c dataLoad) {
      HeaderWrap hw = new HeaderWrap();
      Blob b = cwrap.cver.VersionData;
      System.debug('getHeaderRow fileSize='+b.size());
      String fileInfo = null;
      try {
         fileInfo = b.toString().left(10000);
      } catch (System.StringException se) {
         System.debug('getHeaderRow se exception='+se);
         // if this is too large to parse, allow to proceed if it's a bulk data job - give a warning that will fail if any bad headers.
         String errMsg = se.getMessage();
         // errMsg.contains('not a valid')
         cwrap.notes = '** '+errMsg+' **';
         if (errMsg.contains('String length exceeds maximum') && dataLoad.FileType__c.endsWith('Bulk Load')) {
            cwrap.notes += '** This file is too large to parse! The process will continue but if any of the headers are not recognized by Salesforce then the entire process will fail. **';
            hw.skipHeaderCheck = true;
         } else {
            cwrap.notes += ' ** The process cannot continue! **';
            throw new DataLoadException(cwrap.notes);
         }
         /*
         cwrap.notes += '** This file is too large to parse!';
         if (dataLoad.FileType__c.endsWith('Bulk Load')) {
            cwrap.notes += ' The process will continue but if any of the headers are not recognized by Salesforce then the entire process will fail. **';
            hw.skipHeaderCheck = true;
         } else {
            cwrap.notes += ' The process cannot continue! **';
            throw new DataLoadException(cwrap.notes);
         } 
         */
         return hw;
      } catch (Exception e) {
         // do we need to do anything here?
         System.debug('getHeaderRow exception='+e);
      }
      System.debug('getHeaderRow fileInfo='+fileInfo);
      Integer endOfHeader = fileInfo.indexOf(EmailServiceProcessorBatch.CRLF,0);
      System.debug('getHeaderRow endOfHeader='+endOfHeader);
      String headerRow = fileInfo.substring(0,endOfHeader);//This should be the Column headers from the csv

      headerRow = EncodingUtil.urlEncode(headerRow, 'ASCII');
      headerRow = EncodingUtil.urlDecode(headerRow, 'ASCII');
      hw.headerNames = splitRow(headerRow);
      //hw.headerNames = headerRow.split(',');
      dataLoad.NbrHeaders__c = hw.headerNames.size();
      for (String headerName : hw.headerNames) {
         headerName = checkData(headerName);
         headerName = headerName.toLowerCase().trim().replace('"','').replace('?','');
         hw.headerNamesClean.add(headerName);
      }
      dataLoad.HeaderRow__c=String.join(hw.headerNamesClean,', ');
      return hw;
   } // getHeaderRow
    
    public class DataLoadException extends Exception {}
    
   public static void checkHeaders(CdlWrap cwrap, DataLoad__c dataLoad) {
      HeaderWrap headWrap = getHeaderRow(cwrap,dataLoad);
      //String fileInfo = EncodingUtil.base64Encode(cwrap.cver.VersionData);
      // make sure required headers are present
      Boolean headersOkay = headWrap.skipHeaderCheck;
      if (!headersOkay) {
         if (dataLoad.FileType__c == TYPE_LEAD_LIST) {
            headersOkay = checkLeadListHeaders(cwrap, dataLoad, headWrap);
         } else if (dataLoad.FileType__c == TYPE_REF_SOURCE) {
            headersOkay = checkRfrlSourceHeaders(cwrap, dataLoad, headWrap);
         } else if (dataLoad.FileType__c == TYPE_SF_UPDATE || dataLoad.FileType__c == TYPE_SF_UPDATE_BULK) {
            headersOkay = checkUpdateHeaders(cwrap, dataLoad, headWrap);
         } else if (dataLoad.FileType__c == TYPE_SF_INSERT || dataLoad.FileType__c == TYPE_SF_INSERT_BULK) {
            headersOkay = checkInsertHeaders(cwrap, dataLoad, headWrap);
         } else if (dataLoad.FileType__c == TYPE_SF_DELETE || dataLoad.FileType__c == TYPE_SF_DELETE_BULK) {
            headersOkay = checkDeleteHeaders(cwrap, dataLoad, headWrap);
         }
      } // if (!headersOkay
       
      if (!headersOkay) {
         dataLoad.Status__c = DataLoadMethods.STATUS_ERROR;
         dataLoad.FileLoaded__c = false;
      } else {
         checkApproval(dataLoad);
         //dataLoad.ApprovalNeeded__c = (!Test.isRunningTest() && (dataLoad.FileType__c.startsWith('Record ')));
         dataLoad.FileLoaded__c = true;
         dataLoad.Status__c = STATUS_APPROVAL;
         if (dataLoad.ApprovalNeeded__c) {
            dataLoad.Status__c = STATUS_APPROVAL;
         } else {
            dataLoad.Status__c = STATUS_READY;
            // automatically parse the file
         //   dataLoad.Status__c = (Test.isRunningTest() ? DataLoadMethods.STATUS_LOADED 
         //                          : dataLoad.FileType__c.contains('Bulk') ? STATUS_PROCESS_BULK : DataLoadMethods.STATUS_PARSE);
         }
         
      }

      dataLoad.ProcessNotes__c = cwrap.notes;
   } // checkHeaders

   public static void checkApproval(DataLoad__c dataLoad) {
      
      DataLoadApproval__c[] approves = [Select Id, Name, ApprovedUser__c, FileTypes__c, MaxFileSize__c, ObjectNames__c, ProfileNames__c
                                          From DataLoadApproval__c
                                         Where Active__c=true];
      User runningUser = UserHelper.getRunningUser();
      Boolean approved = false;
      dataLoad.ApprovalNeeded__c = true;
       
      for (DataLoadApproval__c approve : approves) {
         Boolean apprUser = (approve.ApprovedUser__c == null || (approve.ApprovedUser__c != null && approve.ApprovedUser__c == runningUser.Id));
         Boolean apprFile = (String.isBlank(approve.FileTypes__c) || approve.FileTypes__c.contains(dataLoad.FileType__c));
         Boolean apprMaxSize = (approve.MaxFileSize__c == null || dataLoad.FileSize__c < approve.MaxFileSize__c);
         String[] objNames = (String.isNotBlank(approve.ObjectNames__c) ? approve.ObjectNames__c.toLowerCase().split(',') : new String[]{});
         Boolean apprObj = (String.isBlank(dataLoad.UpdateAPIObjectName__c) 
                             || (String.isNotBlank(dataLoad.UpdateAPIObjectName__c) && (objNames.isEmpty() || objNames.contains(dataLoad.UpdateAPIObjectName__c.toLowerCase()))));
         String[] profNames = (String.isNotBlank(approve.ProfileNames__c) ? approve.ProfileNames__c.toLowerCase().split(',') : new String[]{});
         Boolean apprProf = (profNames.isEmpty() || profNames.contains(runningUser.Profile.Name.toLowerCase()));
         System.debug('checkApproval approve='+approve.Name+' apprUser='+apprUser+' apprFile='+apprFile+' apprMaxSize='+apprMaxSize+' apprObj='+apprObj+' apprProf='+apprProf);
         approved = (apprUser && apprFile && apprMaxSize && apprObj && apprProf);
         if (approved) {
            dataLoad.ApprovalNeeded__c = false;
            dataLoad.DataLoadApproval__c = approve.Id;
            break;
         }
      } // for (DataLoadApproval__c approve
      
   } // checkApproval
    
   public static Boolean checkRfrlSourceHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap) {
      cwrap.notes = 'Required Headers for Referral Source Acct: '+REF_SRC_ACCT+'; Ctct: '+REF_SRC_CTCT;
      
      Set<String> acctHeadersSet = new Set<String>(REF_SRC_ACCT.toLowerCase().split(','));
      Set<String> ctctHeadersSet = new Set<String>(REF_SRC_CTCT.toLowerCase().split(','));
      
      Boolean headersOkay = checkHeaders(cwrap, dataLoad, headWrap, ObjectHelper.OBJECT_REF_ACCOUNT, Objecthelper.OBJECT_REF_CONTACT, acctHeadersSet, ctctHeadersSet,false);
      return headersOkay;
   } // checkRfrlSourceHeaders
    
   public static Boolean checkLeadListHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap) {
      cwrap.notes = 'Required Headers for Lead List: '+LEAD_LIST_HEADERS;
      Set<String> reqHeadersSet = new Set<String>(LEAD_LIST_HEADERS.toLowerCase().split(','));
      
      Boolean headersOkay = checkHeaders(cwrap, dataLoad, headWrap, ObjectHelper.OBJECT_LEAD, null, reqHeadersSet, null,false);
      return headersOkay;
   } // checkLeadListHeaders
    
   public static Boolean checkDeleteHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap) {
      cwrap.notes = 'Required Headers for Salesforce Record Delete: Id. ** No other fields will be used **';
      Set<String> reqHeadersSet = new Set<String>{'id'};
      Boolean headersOkay = checkHeaders(cwrap, dataLoad, headWrap, dataLoad.UpdateAPIObjectName__c, null, reqHeadersSet, null,true);
      return headersOkay;
   } // checkDeleteHeaders
    
   public static Boolean checkUpdateHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap) {
      // has to have at least an Id of a record
      cwrap.notes = 'Required Headers for Salesforce Record Update: Id';
      Set<String> reqHeadersSet = new Set<String>{'id'};
      Boolean headersOkay = checkHeaders(cwrap, dataLoad, headWrap, dataLoad.UpdateAPIObjectName__c, null, reqHeadersSet, null,false);
      return headersOkay;
   } // checkUpdateHeaders
    
   public static Boolean checkInsertHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap) {
      cwrap.notes = '* Make sure you have all required fields included in your file for this object!';
      Set<String> reqHeadersSet = new Set<String>();
      Boolean headersOkay = checkHeaders(cwrap, dataLoad, headWrap, dataLoad.UpdateAPIObjectName__c, null, reqHeadersSet, null,false);
      return headersOkay;
   }
    
   public static Boolean checkHeaders(CdlWrap cwrap, DataLoad__c dataLoad, HeaderWrap headWrap, String objectName, String objectName2
                                     ,Set<String> requiredHeaders // these are required for passing this check
                                     ,Set<String> requiredHeaders2
                                     ,Boolean onlyUseRequired
                                     ) {
      // retrieve the available fields for the object
      //ObjectHelper.getSOQLQuery(objectName, null, true, true, true, true, true);
      //String[] availableFlds = (ObjectHelper.latestSoqlWrapper != null ? ObjectHelper.latestSoqlWrapper.flds : null);
      Map<String, Schema.SObjectField> obj1FldMap = new ObjectHelper().getFieldMap(objectName);
      Map<String, Schema.SObjectField> obj2FldMap = null;
      Boolean isInsert = dataLoad.FileType__c.contains('Insert');
      Boolean isUpdate = !isInsert;

      Set<String> availFldSet = new Set<String>();
      for (String fldName : obj1FldMap.keySet()) {
          availFldSet.add(fldName.toLowerCase());
      }

      // where Referral Account and Referral Contact are processed together
      if (objectName2 != null) {
         //ObjectHelper.getSOQLQuery(objectName2, null, true, true, true, true, true);
         //if (ObjectHelper.latestSoqlWrapper != null) {
         //   availableFlds.addAll(ObjectHelper.latestSoqlWrapper.flds);
         //}
         obj2FldMap = new ObjectHelper().getFieldMap(objectName2);
         if (obj2FldMap != null) {
            for (String fldName : obj2FldMap.keySet()) {
               availFldSet.add(fldName.toLowerCase());
            }
         }
      } // if (objectName2 != null

      Boolean headersOkay = (availFldSet != null && availFldSet.size() > 1);
      System.debug('checkUpdateHeaders objectName='+objectName+' headersOkay='+headersOkay+' availFldSet='+(availFldSet != null ? availFldSet.size() : -1));
      if (headersOkay) {
         // put all the fields to lower case and add to a set to make sure no case discrepancy
         // make sure there aren't duplicate headers - a duplicate will throw an error
         Set<String> headerCheck = new Set<String>();
         Boolean duplicateCheckPasses=true;
         // make sure that all of the fields that are required are accounted for.
         //String[] reqFldCheck = new String[]{};
         //reqFldCheck.addAll(requiredHeaders);
         //Boolean idFound = false;
         Integer okayFlds = 0;
         // a list of Y or N depending on if the field is valid
         String[] headersOkayList = new String[]{};
             
         // do we have required fields in the object 1 or object 2 header
         Boolean obj1Flds = false;
         Boolean obj2Flds = false;
             
         for (Integer headerCnt=0; headerCnt < headWrap.headerNames.size(); headerCnt++) {
            String headerName = headWrap.headerNames[headerCnt];
            cwrap.notes += '\nChecking '+headerName+'('+(headerCnt+1)+'): ';
            headerName = headWrap.headerNamesClean[headerCnt];
            // is this column accessible to the running user
            Boolean updateable = true;
            String checkFieldName = null;
             
            Boolean found = requiredHeaders.contains(headerName);
            Boolean requiredFound = found;
            obj1Flds = (obj1Flds || found);
            if (found) {
               requiredHeaders.remove(headerName);
            }
            if (!found && requiredHeaders2 != null && requiredHeaders2.contains(headerName)) {
               found = true;
               requiredFound = true;
               requiredHeaders2.remove(headerName);
               obj2Flds = found;
            }
             
            if (!onlyUseRequired && !found) {
               found = availFldSet.contains(headerName);
            }
            // look for the case where the headername contains the object name. Ex: Referral_Account__c.Sensitivity_401_k__c
            if (!onlyUseRequired && !found) {
               Integer periodPos = headerName.indexOf('.');
               if (periodPos > 0) {
                  // strip off the object name and compare object and field
                  String checkObjectName = headerName.substring(0,periodPos);
                  checkFieldName = headerName.substring(periodPos+1);
                  found = (availFldSet.contains(checkFieldName) && (checkObjectName == objectName || checkObjectName == objectName2));
               }
            } // if (!found
            if (found) {
               String nameToUse = (checkFieldName != null ? checkFieldName : headerName);
               Schema.SObjectField sFld = (obj1FldMap != null && obj1FldMap.containsKey(nameToUse) ? obj1FldMap.get(nameToUse)
                                             : obj2FldMap != null && obj2FldMap.containsKey(nameToUse) ? obj2FldMap.get(nameToUse) : null);
               if (sFld != null && nameToUse != 'Id') {
                  Schema.DescribeFieldResult dfr = sFld.getDescribe();
                  updateable = ((isUpdate && dfr.isUpdateable()) || (isInsert && dfr.isCreateable()));
               }
            }

            cwrap.notes += ((found && updateable) ? 'Found' : (onlyUseRequired ? '*Not Used*' : ((found && !updateable) ? '*No Update Access*' : '*Not Found*')));
            headersOkayList.add(((found && updateable) ? 'Y' : 'N'));
            if (found && updateable) {
               okayFlds++;
            }
         } // for (String headerName : headerNames
          
         System.debug('checkUpdateHeaders obj1Flds='+obj1Flds+' requiredHeaders='+requiredHeaders);
         String[] notFoundList = new String[]{};
         if (obj2Flds && !requiredHeaders2.isEmpty()) {
            headersOkay=false;
            notFoundList.addAll(requiredHeaders2);
         }
         // have to have at least one object. If no object2, object1 is required. 
         if ((!obj2Flds || obj1Flds) && !requiredHeaders.isEmpty()) {
            headersOkay=false;
            notFoundList.addAll(requiredHeaders);
         }
          
         if (!notFoundList.isEmpty()) {
            cwrap.notes += '\n***Required Columns were not found: '+String.join(notFoundList,',');
         } else {
            // for the bulk data loads, all of the headers must be valid
            if (dataLoad.FileType__c.endsWith('Bulk Load') && okayFlds != dataLoad.NbrHeaders__c) {
               headersOkay = false;  
               cwrap.notes += '\n** All headers MUST be valid for a bulk data load. Cannot proceed. **';
            } else {
               cwrap.notes += '\nFile Header validation passed. Columns with Found headers will be processed.';
            }
         }
         dataLoad.HeadersAreValid__c = String.join(headersOkayList,',');
         dataLoad.NbrValidHeaders__c = okayFlds;
      } // if (headersOkay
      System.debug('checkUpdateHeaders cwrap.notes='+cwrap.notes);
      return headersOkay;
   } // checkUpdateHeaders
    
   public static String[] splitRow(String rowToCheck) {
      // check for empty rows - ,, together. Have to do it twice in case ,,,,,,, so the split works correctly
      String dataRow = rowToCheck.replaceAll(',,',',"",');
      dataRow = dataRow.replaceAll(',,',',"",');
      // check for trailing space
      dataRow = dataRow.endsWith(',') ? dataRow+'""' : dataRow;
       // start simple - TODO - check for quotes and such
      String[] dataValues = dataRow.split(',');
      return dataValues;
   } // splitRow
    
   public static String checkData(String dataToCheck) {
      String returnVal = dataToCheck;
      if (String.isNotBlank(returnVal)) {
          // if leading/trailing '"' remove
          //System.debug('checkData returnVal='+returnVal);
          if (returnVal.startswith('"') && returnVal.endsWith('"')) {
              // to account for it just being one double quote-"
              returnVal = (returnVal.length() == 1 ? '' : returnVal.substring(1,returnVal.length()-1));
          }
      } // if (String.isNotBlank
      return returnVal;
   } // checkData
    
   //-----------------------------------------------------------------------------------
    
   // different types of messages we send to Dataflux
   public static String VALIDATION_REQUEST='Validation Request';
   public static String VALIDATION_RESPONSE='Validation Response';
   public static STRING LEAD_REQUEST='Lead Request';
   public static String LEAD_RESPONSE='Lead Response';
   public static String REFERRAL_REQUEST='Referral Source Request';
   public static String REFERRAL_RESPONSE='Referral Source Response';
    
   public static String SERV_VALIDATION='NSS_DF_VALIDATION_SERVICE.ddf';
   public static String SERV_LEAD='NSS_DF_LEAD_LOAD_SERVICE.ddf';
   public static String SERV_REF_SRC='SFDC_Lead_Load_Service.ddf';
   
   public static String validationMsgStart() {
      return msgStart(SERV_VALIDATION);
   } // validationMsgStart
    
   public static String leadMsgStart() {
      return msgStart(SERV_LEAD);
   } // leadMsgStart
    
   public static String rfrlMsgStart() {
      return msgStart(SERV_REF_SRC);
   } // rfrlMsgStart
    
   public static String msgStart(String serviceName) {
      String msg='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:arc="archserver.xsd.dataflux.com">'
               +'<soapenv:Header/>'
               +'<soapenv:Body>'
               +'<arc:SendArchitectServiceRequest>'
               +'\n<serviceName>'+serviceName+'</serviceName>';
      return msg;
   } // msgStart
    
   public static String msgEnd() {
      String msg='\n</arc:SendArchitectServiceRequest>'
                +'</soapenv:Body>'
                +'</soapenv:Envelope>';
      return msg;
   } // msgEnd
    
   public static String getMsgStart(String serviceName, DataLoadMapping__mdt[] mappings) {
      String msgStart = msgStart(serviceName);
      for (DataLoadMapping__mdt mapping : mappings) {
         msgStart += '\n'+getFldDef(mapping.TagName__c);
      } // for (DataLoadMapping__mdt mapping
      return msgStart;
   } // getFldDefs
    
   public static String getFldDef(String fieldName) {
      String msg='<fieldDefinitions>'
                +'<fieldName>'+fieldName+'</fieldName>'
                +'<fieldType>STRING</fieldType>'
                +'<fieldLength>255</fieldLength>'
                +'</fieldDefinitions>';
      return msg;
   } // getFldDef
    
   public static Boolean getValueUseOtherMode=false;
    
   public static String getValue(String valueToCheck, Boolean checkSpecialChars) {
      String retValue = (getValueUseOtherMode ? '<value>' : '<value');
      if (String.isNotBlank(valueToCheck)) {
         String checkValue = valueToCheck.trim();
         if (checkSpecialChars) {
            checkValue = checkValue.replaceAll('&', '&amp;'); 
         }
         retValue += (getValueUseOtherMode ? checkValue : '>'+checkValue+'</value>');
      } else if (!getValueUseOtherMode) {
         retValue += '/>';
      }
      retValue += (getValueUseOtherMode ? '</value>' : '');
      //System.debug('getValue valueToCheck='+valueToCheck+' retValue='+retValue);
      return retValue;
   } // getValue
    
    
   // onlyForObject - if we're only going to be getting data for one object. For referral sources, referral account and referral contact are handled separately
   public static String getRecData(DataLoadMapping__mdt[] mappings, DlrWrap wrap, String onlyForObject, Map<String,String> keyValueOverride) {
      Boolean dataOkay = String.isBlank(onlyForObject);
      String recData = '<dataRows>';
      for (DataLoadMapping__mdt mapping : mappings) {
         String checkData = (mapping.ObjectName__c == 'Static' ? mapping.SFFieldName__c 
                              : mapping.SFFieldName__c != null ? wrap.dataMap.get(mapping.SFFieldName__c.toLowerCase()) : null);
         // this is so we can override specific values.
         if (keyValueOverride.containsKey(mapping.TagName__c)) {
            System.debug('getRecData using keyValueOverride for '+mapping.TagName__c);
            checkData = keyValueOverride.get(mapping.TagName__c);
         }
         // if an object name is passed in, we only want to return data for the fields marked by that object.
         if (String.isNotBlank(onlyForObject) && String.isNotBlank(mapping.ObjectName__c) && mapping.ObjectName__c != 'Static' && mapping.ObjectName__c != onlyForObject) {
            //System.debug('clearing value because not matching object. Tag='+mapping.TagName__c);
            checkData = '';
         }
         // if an object name is passed in, make sure we have data for at least one of the fields specific for that object. 
         dataOkay = dataOkay || (String.isNotBlank(onlyForObject) && mapping.ObjectName__c == onlyForObject && String.isNotBlank(checkData));
         recData += '\n'+getValue(checkData, true);
      } // for (DataLoadMapping__mdt map
      recData += '\n</dataRows>';
      return (dataOkay ? recData : '');
   } // getRecData

   public static DataLoadMapping__mdt[] getDataMappings(String msgType) {
      DataLoadMapping__mdt[] mappings = [Select Id, Label, DeveloperName
                                               ,MsgType__c, ObjectName__c, SFFieldName__c
                                               ,SortOrder__c, TagName__c
                                           From DataLoadMapping__mdt
                                          Where MsgType__c=:msgType
                                          order by SortOrder__c];
      return mappings;
   } // getDataMappings
    
   public static Map<String,DataLoadMapping__mdt[]> getDataMappingsByObject(String msgType) {
      Map<String,DataLoadMapping__mdt[]> mappingMap = new Map<String,DataLoadMapping__mdt[]>();
      DataLoadMapping__mdt[] mappings = getDataMappings(msgType);
      for (DataLoadMapping__mdt mapping : mappings) {
         if (mapping.ObjectName__c != null && mapping.SFFieldName__c != null) {
            DataLoadMapping__mdt[] recs = (mappingMap.containsKey(mapping.ObjectName__c) ? mappingMap.get(mapping.ObjectName__c) : new DataLoadMapping__mdt[]{});
            recs.add(mapping);
            mappingMap.put(mapping.ObjectName__c,recs);
         }
      } // for (DataLoadMapping__mdt mapping
      return mappingMap;
   } // getDataMappingsByObject
    
   public class DlrWrap {
      public DlrWrap() {}
      public DlrWrap(DataLoadRecord__c p_dlr) {
         dlr = p_dlr;
      } // DlrWrap
      public DlrWrap(DataLoadRecord__c p_dlr, String[] headers, Boolean[] validHeaders) {
         dlr = p_dlr;
         // default this because we'll use for 
         dataMap.put('dlr.id',dlr.Id);
         String[] rowData = splitRow(dlr.DataRow__c);
         Integer colNbr=0;
         String compositeData = null;   
         for (String fldData : rowData) {
            //System.debug('DlrWrap fldData='+fldData);
            String data = null;
            // If there is field data like "John Smith, CPA" - we need to compile two data rows
            if (fldData.startsWith('"') && !fldData.endsWith('"')) {
               compositeData = fldData;
               //System.debug('Start compositeData colNbr='+colNbr);
            } else if (compositeData != null && fldData.endsWith('"')) {  // !fldData.startsWith('"')
               data = checkData(compositeData+','+fldData);
               compositeData = null;
               //System.debug('End compositeData colNbr='+colNbr);
            } else {
               data = checkData(fldData);
               //System.debug('normal data check colNbr='+colNbr+' data='+data);
            }
            //System.debug('colNbr='+colNbr+' compositeData is null='+(compositeData == null)+' validHeader='+validHeaders[colNbr]+' data='+data);
            if (compositeData == null && String.isNotBlank(data) && validHeaders[colNbr]) {
               //System.debug('DlrWrap colNbr='+colNbr+' header='+headers[colNbr]+' data='+data);
               dataMap.put(headers[colNbr], data);
            }
            // only increment the column number if we're not in the middle of a composite field.
            if (compositeData == null) {
               colNbr++;
            }
            
         } // for (String fldData
         /*
         for (Integer cnt=0; cnt<headers.size(); cnt++) {
            if (validHeaders[cnt]) {
               String data = checkData(recData[cnt]);
               if (String.isNotBlank(data)) {
                   dataMap.put(headers[cnt],data);
               }
            }
         } // for (Integer
         */
      } // DlrWrap
       
      // add the values of the passed in wrap to this dataMap
      public void addToDataMap(DlrWrap addWrap) {
         dataMap.putAll(addWrap.dataMap);
      } // addToDataMap
 
      public DataLoadRecord__c dlr;
      public SObject saveRec;
      public Lead ld;
      public Account acct;
      public Contact ctct;
      public Referral_Account__c refAcct;
      public Referral_Contact__c refCtct;
       
      public Integer valuesFound=0;
      public Map<String,String> dataMap = new Map<String,String>();

      public Boolean respIsLead {
         get {return dataMap.containsKey('LEAD_DF_UID');}
      }
      public Boolean respIsCtct {
         get {return dataMap.containsKey('CONTACT_DF_UID');}
      }
       
      public String status=null;
   } // class DlrWrap
    
   public static DlrWrap[] wraps = new DlrWrap[]{};
   // map of the wraps for easy lookup and use.
   public static Map<String,DlrWrap> wrapMap = new Map<String,DlrWrap>();
   public static Integer recsFound = 0;
    
   public static void setupRfrlWraps(DataLoadRecord__c[] dlRecs, String[] headers, Boolean[] validHeaders) {
      Map<String, Schema.SObjectField> refCtctFieldMap = Referral_Contact__c.sObjectType.getDescribe().fields.getMap();
      Map<String, Schema.SObjectField> refAcctFieldMap = Referral_Account__c.sObjectType.getDescribe().fields.getMap();
      for (DataLoadRecord__c dlRec : dlRecs) {
         
      }
   } // setupRfrlWraps
    
   public static String buildMsg(String msgType, String serviceName
                                ,String[] headers, Boolean[] validHeaders, DataLoadRecord__c[] dlRecs
                                ,String onlyForObject, Map<String,String> keyValueOverride) {
      DataLoadMapping__mdt[] mappings = getDataMappings(msgType);
      System.debug('buildMsg wrapMap='+wrapMap.size());
      String msg = getMsgStart(serviceName, mappings);
      // add in the data
      recsFound = 0;
      // if the recs is already populated, reuse that to save parsing
      for (DataLoadRecord__c dlRec : dlRecs) {
         DlrWrap wrap = wrapMap.get(dlRec.id);
         if (wrap == null) {
            wrap = new DlrWrap(dlRec, headers, validHeaders);
            wraps.add(wrap);
            wrapMap.put(dlRec.Id,wrap);
         }
         String checkData = getRecData(mappings,wrap,onlyForObject, keyValueOverride);
         // make sure data is actually returned in one of the rows.
         if (String.isNotBlank(checkData)) {
            recsFound++;
            msg += '\n'+checkData;
         }
      } // for (DataLoadRecord__c dlRec
      msg += msgEnd();
      System.debug('buildMsg wrapMap='+wrapMap.size()+' recsFound='+recsFound);
      return (recsFound>0 ? msg : '');
   } // buildMsg

   // build a message based on the response of another message
   public static String buildMsg2(String msgType, String serviceName
                                ,DlrWrap[] wraps) {
      DataLoadMapping__mdt[] mappings = getDataMappings(msgType);
      String msg = getMsgStart(serviceName, mappings);
      // add in the data
      for (DlrWrap wrap : wraps) {
         msg += '\n'+getRecData2(mappings,wrap);
      } // for (DataLoadRecord__c dlRec
      msg += msgEnd();
      return msg;
   } // buildMsg
    
   public static String getRecData2(DataLoadMapping__mdt[] mappings, DlrWrap wrap) {
      String recData = '<dataRows>';
      for (DataLoadMapping__mdt mapping : mappings) {
         String checkData = wrap.dataMap.get(mapping.TagName__c);
         recData += '\n'+getValue(checkData,false);
      } // for (DataLoadMapping__mdt map
      recData += '\n</dataRows>';
      return recData;
   } // getRecData

    
   public static String[] getHeadersFromResponse(String msgResp) {
      String[] headers = new String[]{};
      Integer headerStart = msgResp.indexOf('<fieldDefinitions>');
      Integer headerEnd = msgResp.lastIndexOf('</fieldDefinitions>')+19;
      String headerBlock = ((headerStart > -1 && headerEnd > headerStart) ? msgResp.substring(headerStart, headerEnd) : '');
      headerBlock = headerBlock.replaceAll('\n','');
      System.debug('getHeadersFromResponse headerStart='+headerStart+'headerEnd='+headerEnd+' headerBlock='+headerBlock.length());
      String[] headerTokens = headerBlock.split('</fieldDefinitions>');
      System.debug('getHeadersFromResponse nbrTokens='+headerTokens.size());
      for (String headerToken : headerTokens) {
          //System.debug(headerToken);
          Integer nameStart = headerToken.indexOf('<fieldName>')+11;
          Integer nameEnd = headerToken.indexOf('</fieldName>');
          String headerName=((nameStart > -1 && nameEnd > nameStart) ? headerToken.subString(nameStart,nameEnd) : '');
          //System.debug('nameStart='+nameStart+' nameEnd='+nameEnd+' headerName='+headerName);
          headers.add(headerName);
      } // for (String headerToken
      return headers;
   } // getHeadersFromResponse
    
   public static DlrWrap[] parseMsgResp(String msgResp, DataLoadRecord__c[] recs, Boolean removeSpecialChars) {

      // store in a map to add to the wrapper class
      Map<String,DataLoadRecord__c> dlrMap = (recs != null ? new Map<String,DataLoadRecord__c>(recs) : new Map<String,DataLoadRecord__c>());

      String[] headers = getHeadersFromResponse(msgResp);
      DlrWrap[] returnWraps = new DlrWrap[]{};
      // pull out the entire data section of the response   
      Integer dataStart = msgResp.indexOf('<dataRows>');
      Integer dataEnd = msgResp.lastIndexOf('</dataRows>')+11;
      String allDataSections = ((dataStart > -1 && dataEnd > dataStart) ? msgResp.substring(dataStart,dataEnd) : '');
      allDataSections = allDataSections.replaceAll('\n','');
       
      String[] dataSections = allDataSections.split('</dataRows>');
      System.debug('parseMsgResp dataStart='+dataStart+' dataEnd='+dataEnd+' dataSections='+dataSections.size());
      for (String dataSection : dataSections) {
         DlrWrap tempWrap = new DlrWrap();
         //wraps.add(wrap);
         String dataSection2 = dataSection.substring(10);  // remove <dataRows> from the beginning
         String[] dataSectionTokens = dataSection2.split('</value>');
         System.debug('parseMsgResp dataSectionTokens='+dataSectionTokens.size());
         for (Integer cnt=0; (cnt<dataSectionTokens.size() && cnt<headers.size()); cnt++) {
            // this will be in the format '<value>xxxxx' the </value> will be stripped off
            String section = dataSectionTokens[cnt];  
            String dataValue = section.substring(7);
            if (String.isNotBlank(dataValue)) {
               // we encoded the ampersand to send it in. Decode it here.
               if (removeSpecialChars) {
                  dataValue = dataValue.replaceAll('&amp;', '&');
               }
               String header=headers[cnt];
               System.debug('parseMsgResp header='+header+' dataValue='+dataValue);
               //System.debug('parseMsgResp header='+header+' dataValue='+dataValue+' section='+section);
               tempWrap.dataMap.put(header,dataValue);
            } 
         }
         // pull out the "sales lead id" if it exists. This should be the id of the data load record passed in originally
         String salesLeadId = (tempWrap.dataMap.containsKey('LEAD_SALES_LEAD_ID') ? tempWrap.dataMap.get('LEAD_SALES_LEAD_ID') 
                               : (tempWrap.dataMap.containsKey('CONTACT_SALES_LEAD_ID') ? tempWrap.dataMap.get('CONTACT_SALES_LEAD_ID')
                                  : (tempWrap.dataMap.containsKey('ACCOUNT_SALES_LEAD_ID') ? tempWrap.dataMap.get('ACCOUNT_SALES_LEAD_ID') 
                                     : (tempWrap.dataMap.containsKey('SALES_LEAD_ID') ? tempWrap.dataMap.get('SALES_LEAD_ID') : null))));
         DlrWrap checkWrap = (salesLeadId != null ? wrapMap.get(salesLeadId) : null);
         System.debug('tempWrap 1 dataMap='+tempWrap.dataMap.size());
         if (checkWrap != null) {
            System.debug('reusing an existing DlrWrap');
            checkWrap.addToDataMap(tempWrap);
            tempWrap = checkWrap;
         } else {
            // in theory shouldn't ever get here.
            System.debug('using a new DlrWrap');
            tempWrap.dlr = (salesLeadId != null ? dlrMap.get(salesLeadId) : null);
            if (salesleadId != null) {
               wrapMap.put(salesLeadId, tempWrap);
            }
         }
         System.debug('tempWrap 2 dataMap='+tempWrap.dataMap.size());
         returnWraps.add(tempWrap);

         System.debug('parseMsgResp salesLeadId='+salesLeadId+' wrap.dlr='+(tempWrap.dlr != null));
      } // for (String dataSection
      return wraps;
   } // parseMsgResp

   public static void addToExceptions(DataLoad__c dl, String textToAdd) {
      StringHelper.addToProcessNotes(dl, DataLoad__c.Exceptions__c.getDescribe(), textToAdd); 
   } // addToExceptions
    
   // retrieve one or more dataload records based either on the id passed in or the status
   // this is to retrieve individual records or all open bulk jobs for example
   public static DataLoad__c[] getDataLoad(Id dataLoadId, String status, Boolean useRequestDate) {
      String query = ObjectHelper.getSOQLQuery('DataLoad__c', null, false, false, false, false, false);
      Datetime currentTime = Datetime.now();
      if (dataLoadId != null) {
         query += ' where Id=:dataLoadId ';
      } else if (status != null) {
         query += ' where Status__c=:status ';
         query += (useRequestDate ? ' and RequestStartTime__c <= :currentTime ' : '');
         query += ' Order by RequestStartTime__c ';
      } else {
         query = null;
      }
      DataLoad__c[] dataloads = (query != null ? Database.query(query) : new DataLoad__c[]{});
      /*
      DataLoad__c dl = [Select Id, Name, BulkJobId__c, CreatedById, Exceptions__c
                           ,Campaign__c, FileType__c, HeaderRow__c
                           ,HeadersAreValid__c, NbrHeaders__c, NbrValidHeaders__c, NotifyOwner__c, OwnedBy__c
                           ,ProcessDataStart__c, ProcessDataEnd__c
                           ,ProcessNotes__c, Status__c, UpdateAPIObjectName__c
                       From DataLoad__c
                        Where id=:dataLoadId];
     */
      return dataloads;
   } // getDataLoad
    
    
} // class DataLoadMethods