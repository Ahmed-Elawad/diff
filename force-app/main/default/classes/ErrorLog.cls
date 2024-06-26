/* 
 * Helper class to log errors
 *
 * History
 * -------
 * 10/06/2014 Dan Carmen   Created - rewrite of the SObjectHelper class
   03/20/2015 Dan Carmen   Added additional functionality
   07/28/2015 Dan Carmen   Record if this is due to a row lock.
   02/26/2016 Dan Carmen   Added record count on the record.
   05/02/2016 Dan Carmen   Add more logging capabilities
   03/14/2017 Dan Carmen   Save failed records for possible reprocessing.
   10/11/2018 Dan Carmen   Add addToDescription method
   11/19/2018 Dan Carmen   Change the order of logging - the actual error message is getting dropped off in some cases.
   03/07/2019 Dan Carmen   Added another constructor for ObjectApiName__c and DmlType__c
   12/08/2020 Dan Carmen   Added start and end times for logs
   12/14/2023 Dan Carmen   Add more logging options
   
 */
public without sharing class ErrorLog {
   
   public static Boolean LOG_DETAILS=Label.ErrorLogLogDetails == 'Y';

   // the errors to save
   public static ErrorLog__c[] errorLogList = new ErrorLog__c[]{};
   
   public static DetailWrap[] detailWraps = new DetailWrap[]{};
   
   public static Map<ErrorLog__c, ErrorDetail__c[]> errorLogMap = new Map<ErrorLog__c, ErrorDetail__c[]>();
   
   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, Exception ex) {
      return(logError(className, methodName, codeKey, objectId, ex, null, false));
   } // logError

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, Exception ex, SObject logObj) {
      return(logError(className, methodName, codeKey, objectId, ex, logObj, false));
   } // logError

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, Exception ex, SObject logObj, Boolean saveError) {
      return(logError(className, methodName, codeKey, objectId, (ex != null ? (ex.getMessage()+': '+ex.getStackTraceString()) : null), null, null, null, null, logObj, saveError, null));
   } // logError
   

   public static final Integer CODEKEY_SIZE = ErrorLog__c.CodeKey__c.getDescribe().getLength();
   public static final Integer DESCRIPTION_SIZE = ErrorLog__c.Description__c.getDescribe().getLength();
   public static final Integer OBJECT_INFO_SIZE = ErrorLog__c.ObjectInfo__c.getDescribe().getLength();
   public static final Integer ERRORROWS_SIZE = ErrorLog__c.ErrorRows__c.getDescribe().getLength();
   
   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description) {
      return(logError(className, methodName, codeKey, objectId, description, null,null,null, null, null, false, null, null,null));
   }

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, SObject logObj) {
      return(logError(className, methodName, codeKey, objectId, description, null,null,null, null, logObj, false, null, null,null));
   } // logError

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, SObject logObj, Boolean saveError) {
      return(logError(className, methodName, codeKey, objectId, description, null,null,null, null, logObj, saveError, null, null,null));
   } // logError

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, Integer batchSize, Integer nbrSuccess, Integer nbrFailure, SObject logObj, Boolean saveError) {
      return(logError(className, methodName, codeKey, objectId, description, null,null,null, null, logObj, saveError, null, null,null));
      
   }

   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, Integer batchSize, Integer nbrSuccess, Integer nbrFailure, String rowNums, SObject logObj, Boolean saveError) {
      return(logError(className, methodName, codeKey, objectId, description, null,null,null, null, logObj, saveError, null, null,null));
   }
   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, Integer batchSize, Integer nbrSuccess, Integer nbrFailure, String rowNums, SObject logObj, Boolean saveError, ErrorDetail__c[] errorDetails) {
      return(logError(className, methodName, codeKey, objectId, description, batchSize, nbrSuccess, nbrFailure, rowNums, logObj, saveError, errorDetails, null, null));
   }
   public static ErrorLog__c logError(String className, String methodName, String codeKey, String objectId, String description, Integer batchSize, Integer nbrSuccess, Integer nbrFailure, String rowNums, SObject logObj, Boolean saveError, ErrorDetail__c[] errorDetails, String objectApiName, String dmlType) {
      ErrorLog__c errorLog = new ErrorLog__c(ClassName__c=className, MethodName__c=methodName
                                //,CodeKey__c=(String.isNotBlank(codeKey) ? codeKey.left(CODEKEY_SIZE) : null)
                                ,ErrorRows__c=(String.isNotBlank(rowNums) ? rowNums.left(ERRORROWS_SIZE) : null)
                                ,ObjectId__c=objectId
                                ,BatchSize__c=batchSize, NbrSuccess__c=nbrSuccess, NbrFailure__c=nbrFailure
                                ,NbrErrorDetails__c=(errorDetails != null ? errorDetails.size() : null)
                                ,ObjectAPIName__c=objectApiName, DmlType__c=dmlType);
      setCodeKey(errorLog, codeKey);
      // log this first so the error message shows at the top of the description
      if (logObj != null) {
         addToObjectInfo(errorLog,String.valueOf(logObj));
         //String objText = 'Object Output: '+logObj;
         //addToDescription(errorLog, objText);
      }
      addToDescription(errorLog, description);
      checkErrorTypes(errorLog, description);

      System.debug('logError: saveError='+saveError+' errorLog='+errorLog);
      errorLogList.add(errorLog);
      if (errorDetails != null && !errorDetails.isEmpty()) {
         DetailWrap detWrap = new DetailWrap();
         detWrap.errorLog=errorLog;
         detWrap.errorDetails=errorDetails;
         detailWraps.add(detWrap);
      }
      //errorLogMap.put(errorLog, (errorDetails != null ? errorDetails : new ErrorDetail__c[]{}));
      logLimits(errorLog);
      if (saveError) {
         checkSave();
      }
      return errorLog;
   } // logError
   
   public static void setCodeKey(ErrorLog__c errorLog, String codeKeyTxt) {
      if (errorLog != null && String.isNotBlank(codeKeyTxt)) {
         errorLog.CodeKey__c=(String.isNotBlank(codeKeyTxt) ? codeKeyTxt.left(CODEKEY_SIZE) : null);
      }
   } // setCodeKey
   
   public static void checkErrorTypes(ErrorLog__c errorLog, String textToCheck) {
      errorLog.RowLockError__c = (String.isNotBlank(textToCheck) && (textToCheck.contains('UNABLE_TO_LOCK_ROW') || textToCheck.contains('exclusive access')));
      errorLog.InsufficientAccess__c = (String.isNotBlank(textToCheck) && (textToCheck.contains('INSUFFICIENT_ACCESS_OR_READONLY') || textToCheck.contains('insufficient access')));
      errorLog.ValidationRuleError__c = (String.isNotBlank(textToCheck) && (textToCheck.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')));
      
   } // checkErrorTypes
   
   public static void addToObjectInfo(ErrorLog__c errorLog, String textToAdd) {
      StringHelper.addNotesToField(errorLog, 'ObjectInfo__c', OBJECT_INFO_SIZE, textToAdd, true);
   }
   
   public static void addToDescription(ErrorLog__c errorLog, String textToAdd) {
      if (errorLog != null) {
         StringHelper.addNotesToField(errorLog, 'Description__c', DESCRIPTION_SIZE, textToAdd, true);
      }
   } // addToDescription
   
   public static final Integer NOTES_SIZE = ErrorLog__c.Notes__c.getDescribe().getLength();
   
   public static void saveErrorLog(ErrorLog__c errLog) {
      if (errLog != null) {
         saveErrorLogs(new ErrorLog__c[]{errLog});
      }
   }

   public static void saveErrorLogs(ErrorLog__c[] p_errorLogList) {
      if (!p_errorLogList.isEmpty()) {
         Database.upsert(p_errorLogList,false);
      }
   } // saveErrorLogs

   public static void checkSave() {
      saveErrorLogs(errorLogList);
      if (LOG_DETAILS && !detailWraps.isEmpty()) {
         String notes = '';
         ErrorDetail__c[] insertValues = new ErrorDetail__c[]{};
         for (DetailWrap detailWrap : detailWraps) {
            notes += '\nId='+detailWrap.errorLog.Id+' errorDetails='+(detailWrap.errorDetails != null ? detailWrap.errorDetails.size() : -1);
            if (detailWrap.errorLog.Id != null && detailWrap.errorDetails != null) {
               for (ErrorDetail__c detail : detailWrap.errorDetails) {
                  detail.ErrorLog__c = detailWrap.errorLog.Id;
                  insertValues.add(detail);
               }
            }
            notes += ' insertValues='+insertValues.size();
         }

         if (!insertValues.isEmpty()) {
            try {
               notes += '\nAttempting to insert insertValues size='+insertValues.size();
               insert insertValues;
            } catch (Exception e) {
               notes += '\nError inserting error details: '+e;
               for (ErrorLog__c errorLog : errorLogList) {
                  errorLog.Notes__c = notes.left(NOTES_SIZE);
               }
               // to save why the exception happened.
               update errorLogList;
            }
         }
         detailWraps.clear();
      } // if (!detailWraps.isEmpty())
      errorLogList.clear();
   } // checkSave
   
   public class DetailWrap {
      public ErrorLog__c errorLog = null;
      public ErrorDetail__c[] errorDetails = null;
   } // DetailWrap

   public static ErrorLogCS__c getCustomSetting(ErrorLog__c errorLog) {
      return (errorLog != null ? getCustomSetting(errorLog.ClassName__c, errorLog.MethodName__c, errorLog.CodeKey__c) : null);
   } // getCustomSetting

   // get a matching custom setting for the matching values
   public static ErrorLogCS__c getCustomSetting(String className, String methodName, String codeKey) {
      String key = RecordTypeHelper.cleanRtName(className+'-'+methodName+'-'+codeKey);
      ErrorLogCS__c errorLogCs = ErrorLogCS__c.getInstance(key);
      System.debug('getCustomSetting 1 key='+key+' errorLogCs='+errorLogCs);
      if (errorLogCs == null) {
         key = RecordTypeHelper.cleanRtName(className+'-'+methodName);
         errorLogCs = ErrorLogCS__c.getInstance(key);
         System.debug('getCustomSetting 2 key='+key+' errorLogCs='+errorLogCs);
      }
      if (errorLogCs == null) {
         key = RecordTypeHelper.cleanRtName(className);
         errorLogCs = ErrorLogCS__c.getInstance(key);
         System.debug('getCustomSetting 3 key='+key+' errorLogCs='+errorLogCs);
      }
      return errorLogCs;
   } // getCustomSetting
    
   public static void logLimits(ErrorLog__c log) {
      if (log != null) {
         String summary = 'AggregateQueries='+Limits.getAggregateQueries()+'/'+Limits.getLimitAggregateQueries();
         summary +=' \nasyncCalls='+Limits.getAsyncCalls()+'/'+Limits.getLimitAsyncCalls();
         summary += ' \ncpuTime='+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime();
         summary += ' \nDMLRows='+Limits.getDMLRows()+'/'+Limits.getLimitDMLRows();
         summary += ' \nDMLStatements='+Limits.getDMLStatements()+'/'+Limits.getLimitDMLStatements();
         summary += ' \nEmailInvocations='+Limits.getEmailInvocations()+'/'+Limits.getLimitEmailInvocations();
         summary += ' \nfutureCalls='+Limits.getFutureCalls()+'/'+Limits.getLimitFutureCalls();
         summary += ' \nheapSize='+Limits.getHeapSize()+'/'+Limits.getHeapSize();
         summary += ' \nqueries='+Limits.getQueries()+'/'+Limits.getLimitQueries();
         summary += ' \nqueryRows='+Limits.getQueryRows()+'/'+Limits.getLimitQueryRows();
         summary += ' \nQueueableJobs='+Limits.getQueueableJobs()+'/'+Limits.getLimitQueueableJobs();
         log.LimitInfo__c = summary;
      }
      
   } // logLimits

   public static ErrorLog__c recLog=null;
    
   // get an error log object that's used for logging only    
   public static ErrorLog__c getLog(String className) {
      recLog = new ErrorLog__c(ClassName__c=className,MethodName__c='LOG_DATA', CodeKey__c='LOG_DATA',StartTime__c=DateTime.now());
      recLog.DMLQueriesStart__c=Limits.getQueries();
      return recLog;
   } // getLog
    
    public static void saveLog(ErrorLog__c errLog) {
        if (errLog != null) {
            errLog.EndTime__c=Datetime.now();
            errLog.DMLQueriesEnd__c=Limits.getQueries();
            logLimits(errLog);
            ErrorLogCS__c errLogCs = getCustomSetting(errLog.ClassName__c,null,null);
            if (errLogCs != null && errLogCs.LogData__c) {
                saveErrorLog(errLog);
            }
        }
    } // saveLog   
    
    // to hold it in place for a transaction
    public static ErrorLog__c processLog=null;
    
    public static ErrorLog__c getProcessLog(String className) {
      processLog = new ErrorLog__c(ClassName__c=className,MethodName__c='LOG_DATA', CodeKey__c='ProcessLog',StartTime__c=DateTime.now());
      //System.debug('getLog Limits.getQueries()='+Limits.getQueries());
      processLog.DMLQueriesStart__c=Limits.getQueries();
      return processLog;
    } // getProcessLog
    
    public static void startLog1(ErrorLog__c errLog, String logType) {
       if (errLog != null) {
          errLog.Log1Type__c = logType;
          errLog.Log1Start__c = Datetime.now();
          errLog.DMLQueriesLog1Start__c=Limits.getQueries();
       }
    } // startLog1

    public static void endLog1(ErrorLog__c errLog) {
       if (errLog != null) {
          errLog.Log1End__c = Datetime.now();
          errLog.DMLQueriesLog1End__c=Limits.getQueries();
       }
    } // endLog1

    public static void startLog2(ErrorLog__c errLog, String logType) {
       if (errLog != null) {
          errLog.Log2Type__c = logType;
          errLog.Log2Start__c = Datetime.now();
          errLog.DmlQueriesLog2Start__c=Limits.getQueries();
       }
    } // startLog2

    public static void endLog2(ErrorLog__c errLog) {
       if (errLog != null) {
          errLog.Log2End__c = Datetime.now();
          errLog.DmlQueriesLog2End__c=Limits.getQueries();
       }
    } // endLog2

} // class ErrorLog