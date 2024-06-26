/* 
 * Helper class to manage SObjects

  ****** This class needs to stay at API version 44 ***********

https://trailblazer.salesforce.com/issues_view?id=a1p3A00000031zaQAA

https://help.salesforce.com/s/articleView?id=000356200&type=1


 * History
 * -------
 * 11/17/2011 Dan Carmen   Created - rewrite of the SObjectHelper class
   10/08/2013 Dan Carmen   Added methods to handle save results
   03/20/2015 Dan Carmen   Added the performDML method
   02/27/2016 Dan Carmen   Added the performDML2 method for partial saves
   04/27/2016 Dan Carmen   Changes for savings
   05/02/2016 Dan Carmen   Add more logging capabilities
   08/01/2016 Dan Carmen   Change logging of status message.
   03/08/2019 Dan Carmen   Added ability to retry saving
   03/15/2019 Dan Carmen   Add Database.DMLOptions as an option
   04/08/2019 Dan Carmen   Refactor the code to be able to call pieces separately.
   08/08/2019 Dan Carmen   Update delete to handle an NPE  
   05/26/2020 Dan Carmen   Add methods for fieldsets
   10/23/2020 Dan Carmen   Move API version back to 44.0 to get around SF issue of delete ATMs.
   12/22/2021 Dan Carmen   Modify buildQueryFromSet method
   04/28/2022 Dan Carmen   Add buildStringFromSet method
   10/05/2022 Dan Carmen   Fix save error

 */
public without sharing class DmlHelper {

   /** Default constructor.
    */
   public DmlHelper() {
    
   } // DmlHelper
   
   /** Save the records passed in. If inserting the records and there's a parent id,
       will set that value on the records.
    */
   public Boolean saveRecords(SObject[] recs, String parentFieldName, Id parentId, Boolean throwExceptionIfOne, Boolean logErrorOnRecord) {
      Boolean allOkay = true;
      // only proceed if records are passed in
      if (recs != null && recs.size() > 0) {
         // if a lookup field is passed in, set the value on the fields that are inserts.
         if (parentFieldName != null && parentId != null) {
            for (SObject rec : recs) {
               if (rec.Id == null) {
                  rec.put(parentFieldName, parentId);
               }
            } // for
         } // if (parentFieldName)
         Integer numSuccess=0;
         Integer numFailure=0;
         List<Database.upsertResult> uResults = Database.upsert(recs,false);
         for (Integer cnt=0; cnt<uResults.size(); cnt++) {
            Database.upsertResult result = uResults.get(cnt);
            if (!result.isSuccess()) {
               allOkay = false;
               numFailure++;
               String errorStr = '';
               for (Database.Error err : result.getErrors()) {
                  errorStr += err.getMessage();
               }
               System.debug('Error='+errorStr);
               // if there is only one record and there's an exception, throw it.
               if (throwExceptionIfOne && recs.size() == 1) {
                  throw new SaveException(errorStr);
               } else if (logErrorOnRecord) {
                  // there might be times we don't want to log the error on the object
                  recs.get(cnt).addError(errorStr);
               }
            } else {
               numSuccess++;
            }
         } // for
         System.debug('saveRecords numRec='+recs.size()+' numSuccess='+numSuccess+' numFailure='+numFailure);
      } // if (recs != null
      return allOkay;
   } // saveRecords
   
   public class SaveException extends Exception {}
   
   /** Check the results of an upsert. Log an error against the object if one occurs. 
    */
   public static Boolean checkUpsertResults(Database.UpsertResult[] results, SObject[] recs) {
      Boolean okay = true;
      for (Integer cnt=0; cnt<results.size(); cnt++) {
         Database.UpsertResult result = results[cnt];
         if (!result.isSuccess()) {
            recs[cnt].addError(getErrorMsg(result.getErrors()));
            okay = false;
         }
      } // for (Integer cnt=0
      return okay;
   } // checkUpsertResults

   /** Check the results of a save. Log an error against the object if one occurs. 
    */
   public static Boolean checkSaveResults(Database.SaveResult[] results, SObject[] recs) {
      Boolean okay = true;
      for (Integer cnt=0; cnt<results.size(); cnt++) {
         Database.SaveResult result = results[cnt];
         if (!result.isSuccess()) {
            recs[cnt].addError(getErrorMsg(result.getErrors()));
            okay = false;
         }
      } // for (Integer cnt=0
      return okay;
   } // checkSaveResults

   public static String getErrorMsg(Database.Error[] errors) {
      String errorMsg = '';
      if (errors != null) {
         for (Database.Error err : errors) {
            errorMsg += err.getMessage();
         }
      }
      System.debug('errorMsg='+errorMsg);
      return errorMsg;
   } // getErrorMsg

   public static final String DML_INSERT='Insert';
   public static final String DML_UPDATE='Update';
   public static final String DML_UPSERT='Upsert';
   public static final String DML_DELETE='Delete';
   
   public static Boolean performDML(SObject[] objectsToSave, String dmlType, String className, String methodName, String codeKey, Boolean saveErrors) {
      Boolean okay = true;
      System.debug('performDML dmlType='+dmlType+' methodName='+methodName+' codeKey='+codeKey+' nbrObjs='+objectsToSave.size());
      if (!objectsToSave.isEmpty()) {
         try {
            if (dmlType == DML_INSERT) {
               insert objectsToSave;
            } else if (dmlType == DML_UPDATE) {
               update objectsToSave;
            }
         } catch (Exception e) {
            okay = false;
            SObject firstObj = objectsToSave[0]; 
            ErrorLog.logError(className, methodName, codeKey, firstObj.Id, e, firstObj, saveErrors);
         }
      } // if (!objectsToSave.isEmpty
      return okay;
   } // performDML

   public static String errorMsg = null;
   
   public static DmlResult performDmlResult = null;

   public static Boolean performDML2(SObject[] objectsToSave, String dmlType, String className, String methodName, String codeKey, Boolean saveErrors) {
      return performDML2(objectsToSave, dmlType, className, methodName, codeKey, saveErrors, (Database.DMLOptions)null);
   } // performDML2
   
   public static void prepareForSave() {
      errorDetails.clear();
      performDmlResult = null;
   } // prepareForSave
   
   public static DmlResult initializeDmlResult(SObject[] objectsToSave, String dmlType, String className, String methodName, String codeKey) {
      performDmlResult = new DmlResult(objectsToSave, dmlType, className, methodName, codeKey);
      System.debug('initializeDmlResult performDmlResult is null='+(performDmlResult == null));
      return performDmlResult;
   }
   
   public static Boolean performDML2(SObject[] objectsToSave, String dmlType, String className, String methodName, String codeKey, Boolean saveErrors, Database.DMLOptions dlo) {
      Boolean okay = true;
      prepareForSave();
      System.debug('performDML dmlType='+dmlType+' methodName='+methodName+' codeKey='+codeKey+' nbrObjs='+objectsToSave.size());
      if (!objectsToSave.isEmpty() && String.isNotBlank(dmlType)) {
         DmlResult dmlResult = null;
         try {
            dmlResult = initializeDmlResult(objectsToSave, dmlType, className, methodName, codeKey);
            Schema.DescribeSObjectResult describe = objectsToSave[0].getSObjectType().getDescribe();
            String objectName = describe.getName();
            handleDML(objectsToSave,dmlType,dlo,dmlResult);
            okay = checkDmlResult(saveErrors,dmlResult);
            /*
            if (performDmlResult != null && performDmlResult.nbrError > 0) {
               okay = false;
               errorMsg = performDmlResult.firstError;
               SObject firstRec = performDmlResult.firstErrorRec != null ? performDmlResult.firstErrorRec : objectsToSave[0];
               ErrorLog__c errLog = ErrorLog.logError(className, methodName, codeKey, performDmlResult.firstErrorId, performDmlResult.firstError
                                 ,performDmlResult.NbrRecs, performDmlResult.nbrSuccess, performDmlResult.nbrError
                                 ,(!performDmlResult.lineNumbers.isEmpty() ? String.valueOf(performDmlResult.lineNumbers) : null)
                                 ,firstRec, saveErrors,errorDetails,objectName,dmlType);
               DmlHelperRetry.checkForRetry(errLog, performDmlResult.errorRecs);
               
            } // if (performDmlResult
            */
         } catch (Exception e) {
            // catch any general exception here
            // if the entire batch fails, capture all of the records to reprocess
            SObject errorRec = (objectsToSave != null && !objectsToSave.isEmpty() ? objectsToSave[0] : null);
            ErrorLog.logError(className, methodName, codeKey, (errorRec != null ? errorRec.Id : null), e, errorRec, saveErrors);
            okay = false;
         }
         performDmlResult = dmlResult;
      } // if (!objectsToSave.isEmpty
      // clear this out so it can be set for the next operation.
      return okay;
   } // performDML2
   
   public static Boolean checkDmlResult(Boolean saveErrors,DmlResult dmlResult) {
      Boolean okay = true;
      if (dmlResult != null) {
         performDmlResult = dmlResult;
      }
      if (performDmlResult != null && performDmlResult.nbrError > 0) {
         okay = false;
         errorMsg = performDmlResult.firstError;
         SObject firstRec = performDmlResult.firstErrorRec != null ? performDmlResult.firstErrorRec : performDmlResult.objectsToSave[0];
         ErrorLog__c errLog = ErrorLog.logError(performDmlResult.className, performDmlResult.methodName, performDmlResult.codeKey, performDmlResult.firstErrorId, performDmlResult.firstError
                                 ,performDmlResult.NbrRecs, performDmlResult.nbrSuccess, performDmlResult.nbrError
                                 ,(!performDmlResult.lineNumbers.isEmpty() ? String.valueOf(performDmlResult.lineNumbers) : null)
                                 ,firstRec, saveErrors,errorDetails,performDmlResult.objectName,performDmlResult.dmlType);
         DmlHelperRetry.checkForRetry(errLog, performDmlResult.errorRecs);
               
      } // if (performDmlResult
      return okay;
   } // checkDmlResult
   
   public static Boolean handleDML(SObject[] objectsToSave, String dmlType, Database.DMLOptions dlo, DmlResult dmlResult) {
      Boolean okay = true;
      if (dmlType == DML_INSERT) {
         handleInsert(objectsToSave,dlo,dmlResult);
      } else if (dmlType == DML_UPDATE) {
         handleUpdate(objectsToSave,dlo,dmlResult);
      } else if (dmlType == DML_UPSERT) {
         handleUpsert(objectsToSave,dmlResult);
      } else if (dmlType == DML_DELETE) {
         handleDelete(objectsToSave,dmlResult);
      } // if (dmlType ==
            
      okay = !(performDmlResult != null && performDmlResult.nbrError > 0);
      return okay;
   } // handleDML

   public static ErrorDetail__c[] errorDetails = new ErrorDetail__c[]{};
   
   public class DmlResult {
      
      public DmlResult() {
         // no argument constructor
      }
      
      public DmlResult(SObject[] p_objectsToSave, String p_dmlType, String p_className, String p_methodName, String p_codeKey) {
         className = p_className;
         methodName = p_methodName;
         codeKey = p_codeKey;
         dmlType = p_dmlType;
         objectsToSave = p_objectsToSave;
         Schema.DescribeSObjectResult describe = objectsToSave[0].getSObjectType().getDescribe();
         String objectName = describe.getName();
      } // DmlResult
      
      public String className = null;
      public String methodName = null;
      public String codeKey = null;
      public String dmlType = null;
      public SObject[] objectsToSave = null;
      public String objectName = null;
      public Integer nbrRecs = 0;
      public Integer nbrSuccess = 0;
      public Integer nbrError = 0;
      public String firstErrorId = null;
      public String firstError = null;
      public SObject firstErrorRec = null;
      public Integer[] lineNumbers = new Integer[]{};
      public SObject[] errorRecs = new SObject[]{};
      public Database.SaveResult[] saveResults;
      public Database.DeleteResult[] deleteResults;
      public Database.UpsertResult[] upsertResults;
   } // class DmlResult
   
   public static void handleInsert(SObject[] objectsToSave, Database.DMLOptions dlo, DmlResult dmlResult) {
      if (dlo != null) {
         processSaveResult(Database.insert(objectsToSave,dlo), objectsToSave, DML_INSERT,dmlResult);
         return;
      }
      processSaveResult(Database.insert(objectsToSave,false), objectsToSave, DML_INSERT,dmlResult);
   } // handleInsert
   
   public static void handleUpdate(SObject[] objectsToSave, Database.DMLOptions dlo, DmlResult dmlResult) {
      if (dlo != null) {
         processSaveResult(Database.update(objectsToSave,dlo), objectsToSave, DML_UPDATE, dmlResult);
         return;
      }
      processSaveResult(Database.update(objectsToSave,false), objectsToSave, DML_UPDATE, dmlResult);
   } // handleInsert
   
   public static void processSaveResult(Database.SaveResult[] saveResults, SObject[] objectsToSave, String dmlType, DmlResult dmlResult) {
      //DmlResult result = new DmlResult();
      if (dmlResult != null) {
         performDmlResult = dmlResult;
      }
      performDmlResult.saveResults = saveResults;
      performDmlResult.nbrRecs = saveResults.size();
      for (Integer cnt=0; cnt<saveResults.size(); cnt++) {
         Database.SaveResult saveResult = saveResults[cnt];
         //Boolean isSuccess = saveResult.isSuccess();
         //Database.Error[] errors = (!isSuccess && result.firstError == null ? saveResult.getErrors() : null);
         checkResults(performDmlResult, saveResult.isSuccess(), saveResult.getErrors(), objectsToSave[cnt], cnt, dmlType);
      } // for (Database.SaveResult saveResult
      //return result;
   } // processSaveResult
   
   public static Boolean LOG_DETAILS=Label.ErrorLogLogDetails == 'Y';

   public static void checkResults(DmlResult result, Boolean isSuccess, Database.Error[] errors, SObject rec, Integer rowNum, String dmlType) {
      //System.debug('checkResults isSuccess='+isSuccess);
      if (isSuccess) {
         result.nbrSuccess++;
      } else {
         result.nbrError++;
         result.lineNumbers.add(rowNum);
         result.errorRecs.add(rec);
         String thisErrorMsg = getErrorMsg(errors);
         if (result.firstError == null && errors != null) {
            result.firstError = thisErrorMsg;
            result.firstErrorId = (rec != null ? rec.Id : null);
            result.firstErrorRec = rec;
         } // if (result.firstError == null
         logErrorDetail(thisErrorMsg, rec, dmlType);
         System.debug('checkResults isSuccess='+isSuccess+' rowNum='+rowNum+' msg='+result.firstError);
      }
   } // checkResults
   
   public static void handleDelete(SObject[] objectsToSave, DmlResult dmlResult) {
      //DmlResult result = new DmlResult();
      if (dmlResult != null) {
         performDmlResult = dmlResult;
      }
      if (performDmlResult == null) {
         performDmlResult = new DmlResult(objectsToSave, DML_DELETE, 'UnknownClass', 'UnknownMethod', 'In handleDelete no DmlResult');
      }
      performDmlResult.deleteResults = Database.delete(objectsToSave,false);
      for (Integer cnt=0; cnt<performDmlResult.deleteResults.size(); cnt++) {
         Database.DeleteResult deleteResult = performDmlResult.deleteResults[cnt];
         Boolean isSuccess = deleteResult.isSuccess();
         Database.Error[] errors = (!isSuccess && performDmlResult.firstError == null ? deleteResult.getErrors() : null);
         checkResults(performDmlResult, isSuccess, errors, objectsToSave[cnt], cnt, DML_DELETE);
      } // for (Database.SaveResult saveResult
      //return result;
   } // handleDelete
   
   // to use in the upsert operation, so we don't have to pass it in
   //public static Schema.SObjectField externalIdFld = null;
   
   public static void handleUpsert(SObject[] objectsToSave, DmlResult dmlResult) {
      handleUpsertResults(objectsToSave, Database.upsert(objectsToSave,false), dmlResult);
      /*
      DmlResult result = new DmlResult();
      if (externalIdFld != null) {
         result.upsertResults = Database.upsert(objectsToSave,externalIdFld,false);
      } else {
         result.upsertResults = Database.upsert(objectsToSave,false);
      }
      for (Integer cnt=0; cnt<result.upsertResults.size(); cnt++) {
         Database.UpsertResult upsertResult = result.upsertResults[cnt];
         Boolean isSuccess = upsertResult.isSuccess();
         Database.Error[] errors = (!isSuccess && result.firstError == null ? upsertResult.getErrors() : null);
         checkResults(result, isSuccess, errors, objectsToSave[cnt], cnt, DML_UPSERT);
      } // for (Database.SaveResult saveResult

      return result;
      */
   } // handleUpsert
   
   // break this out because if we want to use an externalIdFld we can't a generic SObject. 
   public static void handleUpsertResults(SObject[] objectsToSave, Database.UpsertResult[] results, DmlResult p_performDmlResult) {
      //DmlResult result = new DmlResult();
      System.debug('handleUpsertResults performDmlResult is null='+(performDmlResult == null)+' p_performDmlResult is null='+(p_performDmlResult == null));
      if (p_performDmlResult != null) {
         performDmlResult = p_performDmlResult;
      }
      performDmlResult.upsertResults = results;
      for (Integer cnt=0; cnt<performDmlResult.upsertResults.size(); cnt++) {
         Database.UpsertResult upsertResult = performDmlResult.upsertResults[cnt];
         Boolean isSuccess = upsertResult.isSuccess();
         Database.Error[] errors = (!isSuccess && performDmlResult.firstError == null ? upsertResult.getErrors() : null);
         checkResults(performDmlResult, isSuccess, errors, objectsToSave[cnt], cnt, DML_UPSERT);
      } // for (Database.SaveResult saveResult

      //return result;
   } // handleUpsertResults
   
   public static final Integer ERROR_MSG_SIZE = ErrorDetail__c.ErrorMessage__c.getDescribe().getLength();
   public static final Integer Fld_DETAIL_SIZE = ErrorDetail__c.FieldDetails__c.getDescribe().getLength();

   public static void logErrorDetail(String thisErrorMsg, SObject rec, String dmlType) {
      if (rec != null) {
         ErrorDetail__c errorRec = new ErrorDetail__c(Id__c=rec.Id, ErrorMessage__c=thisErrorMsg.left(ERROR_MSG_SIZE));
         //errorRec.DMLType__c=dmlType;
         //Schema.DescribeSObjectResult describe = rec.getSObjectType().getDescribe();
         //errorRec.ObjectName__c = describe.getName();
         Map<String,Object> populatedFieldMap = rec.getPopulatedFieldsAsMap();
         String fldDetails = '';
         for (String fieldName : populatedFieldMap.keySet()) {
            if (!ObjectHelper.excludeFieldNames.contains(fieldName)) {
               fldDetails += '<'+fieldName+'>'+String.valueOf(populatedFieldMap.get(fieldName))+'</'+fieldName+'>';
            //} else if (fieldName == 'Id' && String.isBlank(errorRec.Id__c)) {
            //   errorRec.Id__c = String.valueOf(populatedFieldMap.get(fieldName));
            }
         } // for (String fieldName
         errorRec.FieldDetails__c = fldDetails.left(Fld_DETAIL_SIZE);
         System.debug('logErrorDetail errorRec='+errorRec);
         errorDetails.add(errorRec);
      }
   } // logErrorDetail

   public static String buildQueryFromSet(Set<String> fldSet, String tableName) {
      String[] fldList = new String[]{};
      fldList.addAll(fldSet);
      fldList.sort();
      String query = 'Select '+String.join(fldList,', ')+(String.isNotBlank(tableName) ? ' From '+tableName: '')+' ';
      System.debug('buildQueryFromSet tableName='+tableName+' query='+query);
      return query;
   } // buildQueryFromSet
    
   public static String buildStringFromSet(Set<String> fldSet) {
      String query = '';
      if (fldSet != null && !fldSet.isEmpty()) {
         String[] fldList = new String[]{};
         fldList.addAll(fldSet);
         fldList.sort();
         query += String.join(fldList,', ');
      }
      return query;
   } // buildStringFromSet
    
   public static void addFieldsToSet(Schema.FieldSet fieldSet, String prefix, Set<String> fldSet) {
      for (Schema.FieldSetMember fsm : fieldSet.getFields()) {
         String fldName = prefix+fsm.getFieldPath();
         fldSet.add(fldName);
      }
   } // addFieldsToSet
    
   public static Database.SaveResult[] simpleUpdate(SObject[] recs) {
      Database.SaveResult[] results = Database.update(recs,false);
      return results;
   } // simpleUpdate
    
   public static Database.UpsertResult[] simpleUpsert(SObject[] recs, Schema.sObjectField upsertFld) {
      Database.UpsertResult[] results = Database.Upsert(recs,upsertFld, false);
      return results;
   } // simpleUpsert
    
   public static Database.SaveResult[] simpleInsert(SObject[] recs) {
      Database.SaveResult[] results = Database.insert(recs,false);
      return results;
   } // simpleInsert
    
} // class DmlHelper