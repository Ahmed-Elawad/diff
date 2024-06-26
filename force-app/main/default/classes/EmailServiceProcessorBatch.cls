/**
 * This is part of several classes that work together to process email attachments and insert records into Salesforce.
 * This is the batchable class that manages the reading, processing, and inserting of the records.

  History
  -------
  08/19/2015 Justin Stouffer Created
  02/10/2016 Dan Carmen      Code modifications for SRR
  11/02/2016 Justin Stouffer Updated CSVIterator to handle line splitting more efficiently.
  12/13/2016 Dan Carmen      Fix for skipping records when file is broken up into batches.
  08/22/2019 Justin Stouffer - fix to remove a "?" from the first column in the import file. 
  02/24/2020 Dan Carmen        Increment API version
  10/07/2020 Jake Hinds     Change to only return fields that were set from this process in output.
  12/28/2020 Dan Carmen        Increment API to get rid of Missing dependent object: Field: Case.ServiceContractId error
  
 */
global class EmailServiceProcessorBatch implements Database.batchable<String>, Database.Stateful {

   private String m_csvFile;
   private String m_startRow;
   private String fileName;
   public static final String CRLF = '\r\n';
   private Web_Service_Log__c wsl;
   private Email_File_Upload_Settings__c eFUS;
   private static final Integer SCOPE_SIZE = 400;
   private boolean isError = FALSE;
   private boolean okToProceed = FALSE;
   private string errorBody = '';
   private string tmpError = '';
   private String logFileMsgs = '';
   private integer numRecords = 0;
   // the map of the fields for the object being inserted into
   global Map<String, Schema.SObjectField> fieldMap = null;
   // the map of the valid header fields
   global Map<Integer,String> headerFieldMap = new Map<Integer,String>();
   // the static values that will be set on every record inserted
   global Map<String,Object> staticValuesMap = null;
   // header values that are used only for querying
   //global Set<String> queryHeaderSet = null;
   global Map<String,EmailFileQuery__c> queryHeaderMap = null;
   
   // if any attachments were created, store the names here.
   global String[] attachmentNames = new String[]{};
   
   
       
   global Iterable<String> start(Database.batchableContext batchableContext) {
      wsl =[Select Id, ServiceName__c, NamedFunction__c, Notes__c, Successful__c, Action__c, NbrAttempts__c, ErrorMsg__c, ServiceEnd__c
                    from Web_Service_Log__c 
                    Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                    and Successful__c = FALSE
                    and Action__c = 'Insert'
                    and NbrAttempts__c = 0
                    order by createdDate ASC limit 1];

      for(Email_File_Upload_Settings__c e: Email_File_Upload_Settings__c.getall().values()){
         if (WSL.NamedFunction__c == e.ID_Key__c && e.Active__c){
            okToProceed = TRUE;
            eFUS = e;
            break;
         }
      } // for(Email_File_Upload_Settings__c
      Attachment attch =  [Select Name, Body from Attachment where Parent.id = :wsl.id limit 1];
      fileName = attch.Name;
      m_csvFile = attch.body.toString();
      integer endOfHeader = m_csvFile.indexOf(CRLF,0);
      m_startRow = m_csvFile.substring(0,endOfHeader);//This should be the Column headers from the csv
      System.debug('EmailServiceProcessorBatch m_startRow='+m_startRow);
      
      fieldMap = new ObjectHelper().getFieldMap(eFUS.Object_Type__c);
      staticValuesMap = getStaticValues(eFUS.ID_Key__c, fieldMap);
      queryHeaderMap = getQueryHeaderMap(eFUS.ID_Key__c);
      //queryHeaderSet = getQueryHeaderFields(eFUS.ID_Key__c);
      parseHeaderFields(m_startRow);
      
      if (okToProceed && headerFieldMap.size() == 0) {
         logMessage('No header name match up to table!', true);
         okToProceed = false;
      }
      System.debug('start okToProceed='+okToProceed);
      
      return new CSVIterator(m_csvFile, CRLF);//This custom iterator will break the file up line by line so the apex limits are not exceeded.
   } // start
   
   public void logMessage(String msg, Boolean setAsError) {
      if (String.isNotBlank(msg) && wsl != null) {
         System.debug('logMessage: '+msg);
         logFileMsgs += '\n'+msg;
         if (setAsError) {
            wsl.ErrorMsg__c = msg.left(ERROR_MSG_LENGTH);
         }
      } else if (wsl == null) {
         System.debug('logMessage msg='+msg);
      }
   } // logMessage

   public static Integer ERROR_MSG_LENGTH=Web_Service_Log__c.ErrorMsg__c.getDescribe().getLength();

   // return the fields from the header that are valid for the object
   // also include the fields used to query
   global void parseHeaderFields(String headerRow) {
      headerFieldMap.clear();
      System.debug('parseHeaderFields  headerRow='+headerRow);
      System.debug('parseHeaderFields fieldMap='+fieldMap.keySet());
      System.debug('parseHeaderFields fieldMap All='+fieldMap);
      headerRow = EncodingUtil.urlEncode(headerRow, 'ASCII');
      headerRow = EncodingUtil.urlDecode(headerRow, 'ASCII');
      String[] headerNames = headerRow.split(',');
      System.debug('headerNames='+headerNames.size());
      String headersNotMappedToFlds = '';
      for (Integer col=0; col<headerNames.size(); col++) {
         // make sure there is no leading or trailing whitespace,and remove quotes
         String headerName = headerNames[col].trim().toLowerCase().replace('"','').replace('?','');
         Schema.SObjectField headerFld = fieldMap.get(headerName);
         Boolean isEditable = headerFld != null && headerFld.getDescribe().isCreateable();
         System.debug('parseHeaderFields headerName='+headerName+' headerFld='+headerFld+' isEditable='+isEditable+' in queryHeaderMap='+queryHeaderMap.containsKey(headerName));
         // it either has to be a field used in a query or map to a field on the actual object to be used.
         if (queryHeaderMap.containsKey(headerName) || isEditable) {
            headerFieldMap.put(col,headerName);
         } else {
            headersNotMappedToFlds += headerName+';';
         }
      } // for (Integer col=0
      
      // log the header fields that don't map to an object
      if (String.isNotBlank(headersNotMappedToFlds)) {
         logMessage('Header Fields Not Mapped: '+headersNotMappedToFlds, true);
      }
      System.debug('parseHeaderFields headerFieldMap='+headerFieldMap.size());
   } // parseHeaderFields
  
   global void execute(Database.BatchableContext batchableContext, List<String> scope) {
      if (okToProceed){
         try {
            System.debug('execute scope='+scope.size());
            list<sObject> objToInsertList = new list<sObject>(); 
            String csvFile = m_startRow + 'EndOfLine';
            Boolean checkForHeader=scope[0].contains(m_startRow);
            System.debug('execute checkForHeader='+checkForHeader+' scope[0]='+scope[0]);
            if(checkForHeader){//If it's the first part of the batch, we don't want to add the csv file header row
               csvFile = '';
            }
            for(String row : scope) {
               csvFile += row + 'EndOfLine'; //CRLF;//Add each row with a \r\n to a single string
            }            
            map<integer,map<string,Object>> recMap = EmailServiceProcessor.parseCSVToMap(csvFile,FALSE,headerFieldMap,fieldMap);//Parse the csv and create a map of a map with with string-value pairs for each row/record

            //Map<String,Object> staticValues = getStaticValues(eFUS.ID_Key__c, fieldMap);
            
            checkForQueryFields(recMap, eFUS.ID_Key__c);
            
            system.debug('JGS recMap=' + recMap);
            Schema.sObjectType objectDef = Schema.getGlobalDescribe().get(eFUS.Object_Type__c).getDescribe().getSObjectType();
            Set<String>fieldSet = new Set<String>();
            For (map<string,Object> columnDataMap: recMap.values()){
               sObject thisObj = objectDef.newSobject();
               system.debug('JGS columnDataMap.keySet()=' + columnDataMap.keySet());
               for (string fldName: columnDataMap.keySet()){//For each key (FieldName) add the corresponding value to the new object record
                  try {
                     //string tmpVal = string.valueOf(columnDataMap.get(fldName));  
                     // strip out the quotes if they exist
                     //if (tmpVal.startsWith('"') || tmpVal.endsWith('"')) {
                     //   thisObj.put(fldName,tmpVal.subString((tmpVal.startsWith('"')?1:0),(tmpVal.endsWith('"')?tmpVal.length()-1:tmpVal.length())));
                     //} else {                     
                     // only set the columns that exist in the object. Query columns could be in the mix
                     if (fieldMap.containsKey(fldName)) {
                        thisObj.put(fldName,columnDataMap.get(fldName));
                         if(!fieldSet.contains(fldName)){
                             fieldSet.add(fldName);
                         }
                     }
                     //}
                  } catch(exception e) {
                     //Throw out extra fields that aren't on the object
                     String errorMsg = '==== Invalid field specified in header ' + fldName;
                     logMessage(errorMsg, false);
                  }       
               } // for (string fldName
                  if (!staticValuesMap.isEmpty()) {
                     for (String fldName : staticValuesMap.keySet()) {
                        thisObj.put(fldName,staticValuesMap.get(fldName));
                     }
                  } // if (!staticValuesMap.isEmpty

                     objToInsertList.add(thisObj);
                     numRecords++;
               } // for (string tmpkey: columnDataMap.keySet()
               If (!objToInsertList.isEmpty()){
                  // insert the new records
                  if (DmlHelper.performDML2(objToInsertList, DmlHelper.DML_INSERT, 'EmailServiceProcessorBatch', 'execute', 'insert new records', true) == false) {
                     isError = true;
                     wsl.Action__c = 'Failed';
                     wsl.ErrorMsg__c = (String.isNotBlank(DmlHelper.errorMsg) ? DmlHelper.errorMsg.left(ERROR_MSG_LENGTH) : wsl.ErrorMsg__c);
                  }
                  
                  if (eFUS.ReturnRecordResultsToSubmitter__c) {
                     attachRecordResults(objToInsertList,fieldSet);
                  }
                  //insert objToInsertList;//Insert the objects
            } // For (map<string,Object> columnDataMap
         } // try
         catch(exception e){
            isError = TRUE;
            wsl.Action__c = 'Failed';
            logMessage(e.getMessage(), true);
            system.debug('The error occurred at record ' + numRecords + '. '+e.getStackTraceString());
         }
      } // if (okToProceed)
      else {
         isError = TRUE;
         wsl.Action__c = 'Failed';
         logMessage('Key does not match setting', true);
      }
   } // execute
       
   public void attachRecordResults(list<sObject> objToInsertList,Set<String> fieldNames) {
      try {
         // records successfully inserted - reselect to get all values
         Id[] recordIds = new Id[]{};
         // records without an idea - we will attach them as is 
         SObject[] failedRecords = new SObject[]{};
         for (SObject rec : objToInsertList) {
            if (rec.Id != null) {
               recordIds.add(rec.Id);
            } else {
               failedRecords.add(rec);
            }
         } // for (SObject rec
         System.debug('attachRecordResults recordIds='+recordIds.size()+' failedRecords='+failedRecords.size());
         if (!recordIds.isEmpty()) {
            handleSuccesses(recordIds,fieldNames);
         }
         if (!failedRecords.isEmpty()) {
            handleFailures(failedRecords);
         }
      } catch (Exception e) {
         System.debug('attachRecordResults e='+e.getMessage()+'; '+e.getStackTraceString());
      }
   } // attachRecordResults
   
   public void handleSuccesses(Id[] p_recordIds,Set<String> fieldNames) {
      //String query = ObjectHelper.getSOQLQuery(eFUS.Object_Type__c, null, true, false, true);
      Set<Id> recordIdSet = new Set<Id>();
      recordIdSet.addAll(p_recordIds);
      String query = 'SELECT ID ';
      for(String field: fieldNames){
          query+= ','+field;
      }
      query += ' FROM '+eFUS.Object_Type__c+' Where Id in :recordIdSet';
      system.debug('EmailServiceProcessorBatch handleSuccesses query'+query);
      //String[] fieldNames = ObjectHelper.fieldNameByObjectNameMap.get(eFUS.Object_Type__c);
      String[]fieldList = new String[]{};
      fieldList.addAll(fieldNames);
      //make output columns alphabetized, except for ID first.
      fieldList.sort();
      fieldList.add(0,'Id');
      String output = buildHeader(fieldList)+CRLF;
      System.debug('handleSuccesses output='+output);
      
      for (SObject rec : Database.query(query)) {
         output += buildLine(fieldList, rec);
      } // for (SObject rec
      attachOutput('SuccessfulRecords','.csv',output);
   } // handleSuccesses
   
   public String buildLine(String[] fieldNames, SObject rec) {
      String output = '';
      System.debug('buildLine rec='+rec);
      for (String fieldName : fieldNames) {
         if (!fieldName.contains('.')) {
            Object value = rec.get(fieldName);
            System.debug('buildLine fieldName='+fieldName+' value='+value);
            if (output != '') {
               output += ',';
            }
            output += (value != null ? '"'+value+'"': '');
         }
      }
      return output+CRLF;
   } // buildLine
   
   public String buildHeader(String[] fieldNames) {
      String header = '';
      for (String fieldName : fieldNames) {
         if (!fieldName.contains('.')) {
            if (String.isNotBlank(header)) {
               header += ',';
            }
            header += fieldName;
         }
      } // for (String fieldName
      return header;
   } // buildHeader
   
   public void handleFailures(SObject[] failedRecords) {
      //Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(thisObj));
      //m.remove('attributes');
      //Set<String> fieldNameSet = new Set<String>();
      String output = '';
      
      for (SObject rec : failedRecords) {
         if (String.isNotBlank(output)) {
            output += '\n';
         }
         output += rec;
      } // for (SObject rec
      
      attachOutput('FailedRecords','.txt',output);
   } // handleFailures
   
   public void attachOutput(String fileName, String fileExtension, String output) {
      Attachment attch = new Attachment();
      attch.parentId = wsl.id;
      attch.body = blob.valueOf(output);
      String attachName = fileName+Datetime.now().format('mmss')+fileExtension;
      attch.name = attachName;
      insert attch;
      attachmentNames.add(attachName);
   } // attachOutput
   
   public Map<String,EmailFileQuery__c> getQueryHeaderMap(String idKey) {
      Map<String,EmailFileQuery__c> v_queryMap = new Map<String,EmailFileQuery__c>();
      for (EmailFileQuery__c fileQuery : EmailFileQuery__c.getAll().values()) {
         //if (fileQuery.ID_Key__c == idKey && String.isNotBlank(fileQuery.DataFileColumnName__c)
         if (fileQuery.Name.startsWith(idKey) && String.isNotBlank(fileQuery.DataFileColumnName__c)
                       && String.isNotBlank(fileQuery.NewObjectRelatedField__c)
                       && String.isNotBlank(fileQuery.QueryObject__c)
                       && String.isNotBlank(fileQuery.SelectField__c)
                       && String.isNotBlank(fileQuery.WhereField__c)) {
            v_queryMap.put(fileQuery.DataFileColumnName__c.toLowerCase(),fileQuery);
            System.debug('getQueryHeaderMap added '+fileQuery.DataFileColumnName__c.toLowerCase());
         } // if (fileQuery.ID_Key__c
      } // for (EmailFileQuery__c
      System.debug('getQueryHeaderMap v_queryMap='+v_queryMap.size());
      return v_queryMap;
   } // getQueryHeaderMap
   
   public Set<String> getQueryHeaderFields(String idKey) {
      Set<String> queryHeaderFields = new Set<String>();
      for (EmailFileQuery__c fileQuery : EmailFileQuery__c.getAll().values()) {
         //if (fileQuery.ID_Key__c == idKey && String.isNotBlank(fileQuery.DataFileColumnName__c)
         if (fileQuery.Name.startsWith(idKey) && String.isNotBlank(fileQuery.DataFileColumnName__c)
                       && String.isNotBlank(fileQuery.NewObjectRelatedField__c)
                       && String.isNotBlank(fileQuery.QueryObject__c)
                       && String.isNotBlank(fileQuery.SelectField__c)
                       && String.isNotBlank(fileQuery.WhereField__c)) {
            queryHeaderFields.add(fileQuery.DataFileColumnName__c);
            System.debug('getQueryHeaderFields added '+fileQuery.DataFileColumnName__c);
         } // if (fileQuery.ID_Key__c
      } // for (EmailFileQuery__c
      System.debug('queryHeaderFields queryHeaderFields='+queryHeaderFields.size());
      return queryHeaderFields;
   } // getQueryHeaderFields
   
   public void checkForQueryFields(map<integer,map<string,Object>> recMap, String idKey) {
      System.debug('checkForQueryFields queryHeaderMap='+queryHeaderMap.size());
      if (queryHeaderMap.isEmpty()) {
         return;
      }
      for (EmailFileQuery__c fileQuery : queryHeaderMap.values()) {
            preQueryCheck(recMap, fileQuery);
      }
      /*
      for (EmailFileQuery__c fileQuery : EmailFileQuery__c.getAll().values()) {
         //if (fileQuery.ID_Key__c == idKey && String.isNotBlank(fileQuery.DataFileColumnName__c)
         if (fileQuery.Name.startsWith(idKey) && String.isNotBlank(fileQuery.DataFileColumnName__c)
                       && queryHeaderSet.contains(fileQuery.DataFileColumnName__c)) {
            // not sure how much this will be used, so for now we're not going to worry as much about limits 
            // and execute once for each query record
            preQueryCheck(recMap, fileQuery);
         } // if (fileQuery.ID_Key__c
      } // for (EmailFileQuery__c fileQuery
      */
   } // checkForQueryFields
   
   // make sure there is data for the column before attempting the query
   public Boolean preQueryCheck(map<integer,map<string,Object>> recMap, EmailFileQuery__c fileQuery) {
      Map<Integer,Object> queryDataStorageMap = new Map<Integer,Object>();
      Map<String,List<Integer>> dataToRecMap = new Map<String,List<Integer>>();
      Map<String, Schema.SObjectField> queryObjFldMap = new ObjectHelper().getFieldMap(fileQuery.QueryObject__c);
      Boolean okayToContinue = (queryObjFldMap != null);
      // verify the fields are valid for the object we are querying against
      if (okayToContinue) {
         okayToContinue = (queryObjFldMap.containsKey(fileQuery.SelectField__c) && queryObjFldMap.containsKey(fileQuery.WhereField__c));
      }
      // verify the field we are putting into our new object is valid
      if (okayToContinue) {
         okayToContinue = fieldMap.containsKey(fileQuery.NewObjectRelatedField__c);
      }

      if (okayToContinue) {
         // get the data out of the column (assuming the column actually exists)
         for (Integer key : recMap.keySet()) {
            Map<String,Object> columnDataMap = recMap.get(key);
            if (columnDataMap != null) {
               // storing all of the column names as lower case
               Object columnData = columnDataMap.get(fileQuery.DataFileColumnName__c.toLowerCase());
               if (columnData != null) {
                  queryDataStorageMap.put(key,columnData);
                   string dataToAdd = String.valueOf(columnData).substringBefore('.');
                   if(dataToRecMap.keySet().contains(dataToAdd)){
                       dataToRecMap.get(dataToAdd).add(key);    
                   }
                   else{
                       dataToRecMap.put(dataToAdd,new Integer[]{key});
                   }
               }
            } // if (columnDataMap != null
         } // for (Integer key
         
         okayToContinue = !queryDataStorageMap.isEmpty();
      } // if (okayToContinue
      
      if (okayToContinue) {
         okayToContinue = performQuery(recMap, fileQuery, queryDataStorageMap, dataToRecMap, queryObjFldMap);
      } // if (okayToContinue
      
      return okayToContinue;
   } // preQueryCheck
      
   public Boolean performQuery(map<integer,map<string,Object>> recMap, EmailFileQuery__c fileQuery
                                ,Map<Integer,Object> queryDataStorageMap
                                ,Map<String,List<Integer>> dataToRecMap
                                ,Map<String, Schema.SObjectField> queryObjFldMap) {
      Boolean okayToContinue = true;
      String[] queryStrings = new String[]{};
      Decimal[] queryDecimals = new Decimal[]{};
      
      Schema.SObjectField whereFld = queryObjFldMap.get(fileQuery.WhereField__c);
      Schema.DisplayType fldType = whereFld.getDescribe().getType();
      
      Boolean isNumber = (fldType == Schema.DisplayType.Currency
                       || fldType == Schema.DisplayType.Double
                       || fldType == Schema.DisplayType.Percent
                       || fldType == Schema.DisplayType.Integer);
                                    
      Boolean isDouble = fldType == Schema.DisplayType.Double;
                       
      for (Object checkObj : queryDataStorageMap.values()) {
         Object retObject = ObjectHelper.formatStringAsObject(whereFld, String.valueOf(checkObj));
          if (retObject != null) {
              if (isDouble){
                  decimal d = double.valueOf(retObject);
                  queryDecimals.add(d);
              }
              else if (isNumber) {
                  queryDecimals.add(Decimal.valueOf((String)retObject));
              } else {
                  queryStrings.add((String)retObject);
              }
          }
      } // for (Object checkObj
      if (!queryStrings.isEmpty() || !queryDecimals.isEmpty()) {
         String query = 'Select '+fileQuery.SelectField__c+', '+fileQuery.WhereField__c+' from '+fileQuery.QueryObject__c+' where '+fileQuery.WhereField__c+' in '+(isNumber ? ':queryDecimals' : ':queryStrings');
         System.debug('performQuery query='+query);
         try {
            SObject[] queryResults = Database.query(query);
            okayToContinue = processQueryResults(recMap, fileQuery, queryDataStorageMap, dataToRecMap, queryObjFldMap, queryResults);
         } catch (Exception e) {
            // what do we do if the query fails?
            System.debug('performQuery exception: '+e.getStackTraceString());
         }
      } // if (!queryRecs.isEmpty()
      return okayToContinue;
   } // performQuery
   
   public Boolean processQueryResults(map<integer,map<string,Object>> recMap, EmailFileQuery__c fileQuery
                                ,Map<Integer,Object> queryDataStorageMap
                                ,Map<String,List<Integer>> dataToRecMap
                                ,Map<String, Schema.SObjectField> queryObjFldMap
                                ,SObject[] queryResults) {
      // for now we're not going to ignore more than one row returned for a record, but that is something that should be addressed when this functionality 
      // comes more into use.
      Boolean okayToContinue = true;
      // TODO - handle required relationships
      for (SObject queryResult : queryResults) {
         // use the data to find the original record
         String sourceData = String.valueOf(queryResult.get(fileQuery.WhereField__c));
         if(dataToRecMap.keySet().contains(sourceData)){
             for(integer recNum:dataToRecMap.get(sourceData)){
                 System.debug('processQueryResults found matching record for source data '+sourceData+', recNum='+recNum);
                 map<string,Object> columnDataMap = recMap.get(recNum);
                 if (columnDataMap != null) {
                     columnDataMap.put(fileQuery.NewObjectRelatedField__c, queryResult.get(fileQuery.SelectField__c));
                 }
             }
         }
         else{
            System.debug('processQueryResults no matching record found for source data '+sourceData);
         }
      } // for (SObject queryResult
      return okayToContinue;
   } // processQueryResults
   
   // retrieve the values that do not change when inserting a record
   // <field name, field value>
   public Map<String,Object> getStaticValues(String idKey, Map<String, Schema.SObjectField> fieldMap) {
      Map<String,Object> staticValues = new Map<String,Object>();
      for (EmailFileValuePairs__c valuePair : EmailFileValuePairs__c.getAll().values()) {
         //if (valuePair.ID_Key__c == idKey && String.isNotBlank(valuePair.APIFieldName__c) && String.isNotBlank(valuePair.Value__c)) {
         if (valuePair.Name.startsWith(idKey) && String.isNotBlank(valuePair.APIFieldName__c) && String.isNotBlank(valuePair.Value__c)) {
            // make sure the field exists
            Schema.SObjectField fld = fieldMap.get(valuePair.APIFieldName__c);
            if (fld != null) {
               Object retObject = ObjectHelper.formatStringAsObject(fld, valuePair.Value__c);
               if (retObject != null) {
                  staticValues.put(valuePair.APIFieldName__c, retObject);
               }
            } // if (fld != null
         } // if (valuePair.ID_Key__c == idKey
      } // for (EmailFileValuePairs__c valuePair
      return staticValues;
   } // getStaticValues
   
   global void finish(Database.BatchableContext batchableContext){
      Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
      Messaging.EmailFileAttachment[] emailAttachments = new Messaging.EmailFileAttachment[] {};
      
      if (!attachmentNames.isEmpty()) {
         for (Attachment attach : [Select Id, Name, Body from Attachment where ParentId=:wsl.Id and Name in :attachmentNames]) {
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attach.Name);
            efa.setBody(attach.Body);
            emailAttachments.add(efa);
         }
      } // if (!attachmentNames.isEmpty
      
      mail.setToAddresses(new String[]{wsl.Notes__c});
      string txtBody = '';
      if (eFUS.Notification_Email__c != NULL && eFUS.Notification_Email__c != ''){
         mail.setCCAddresses(eFUS.Notification_Email__c.split(','));
      }
      if(!isError){//Send emails and update the Web Service Log
         wsl.Action__c = 'Success';
         wsl.Successful__c = TRUE;
         wsl.NbrAttempts__c = 1;
         wsl.ServiceEnd__c = datetime.now();
         boolean attchmnt = FALSE;
         attachment attch = new attachment();
         if (errorBody != ''){
            attch.parentId = wsl.id;
            attch.body = blob.valueOf(errorBody);
            attch.name = 'Exceptions.csv';
            insert attch;
            attchmnt = TRUE;
         }
         txtBody = 'The upload of ' + fileName + ' is complete. ' + numRecords + ' ' + eFUS.Name + 's were successfully inserted into Salesforce.com.';
         if (attchmnt){
            txtBody += '\r\nThe attached document contains the records that could not be inserted.';
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('Exceptions.csv');
            efa.setBody(blob.valueOf(errorBody));
            emailAttachments.add(efa);
            //mail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa}); 
         }
         txtBody += '\r\n\r\nThank You!';
         mail.setSubject('The Salesforce.com File Upload is Complete');
      } else{
         wsl.ServiceEnd__c = datetime.now();
         txtBody = 'The upload of ' + fileName + ' has finished, but there was an issue.';
         mail.setSubject('The Salesforce.com File Upload finished but there was a problem.');                
      } 
      if (!emailAttachments.isEmpty()) {
         mail.setFileAttachments(emailAttachments);
      }
      txtBody += logFileMsgs;
      mail.setPlainTextBody(txtBody);
      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
      update wsl;
      If (![Select Id from Web_Service_Log__c Where ServiceName__c = :EmailServiceProcessor.SERVICE_NAME 
                                               and Successful__c = FALSE
                                               and Action__c = 'Insert'].isEmpty()){
         EmailServiceProcessor.kickOffBatchJob(eFUS != null && eFUS.MaxRecsPerBatch__c != null ? (Integer)eFUS.MaxRecsPerBatch__c : 200);//Run it again if there are still web service logs to process.                                  
      }
   } // finish
   
} // class EmailServiceProcessorBatch