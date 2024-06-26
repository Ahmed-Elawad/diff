/* 
   If an error happens (ex row lock) retry it x number of times  

   *** KEEP API VERSION AT 44!!  ****
   
  History
  -------
  03/07/2019 Dan Carmen   Created
  03/13/2019 Dan Carmen   Add more logging
  10/23/2020 Dan Carmen   Move API version back to 44.0 to get around SF issue of delete ATMs.
  10/21/2021 Dan Carmen   Don't retry if running in a batch
   
 */
public with sharing class DmlHelperRetry implements Queueable, Database.AllowsCallouts {
   
   public ErrorLog__c errLog;
   public SObject[] recs;
   public Database.DMLOptions dlo = null;
   
   public DmlHelperRetry(ErrorLog__c p_errLog, SObject[] p_recs) {
      errLog = p_errLog;
      recs = p_recs;
   } // DmlHelperRetry
   
   public DmlHelperRetry(ErrorLog__c p_errLog, SObject[] p_recs, Database.DMLOptions p_dlo) {
      errLog = p_errLog;
      recs = p_recs;
      dlo = p_dlo;
   } // DmlHelperRetry

   public void execute(QueueableContext context) {
      processRetry(true);
       
   } // execute
   
   public Boolean processRetry(Boolean allowSleep) {
      Boolean retrySuccessful = false;
      Apex_Batch_Control__c abc = getBatchControl();
      // even though the field name is "Minutes_till_Launch__c", we're going to treat this value as seconds instead.
      if (allowSleep && abc != null && abc.Minutes_till_Launch__c != null && abc.Minutes_till_Launch__c > 0) {
         // call the sleep method
         Long sleepDuration = Utilities.Sleep(Integer.valueOf(abc.Minutes_till_Launch__c));
         ErrorLog.addToDescription(errLog, 'Sleep duration: '+sleepDuration);
      }
      
      // initialize the variables
      DmlHelper.errorDetails.clear();
      DmlHelper.performDmlResult = new DmlHelper.DmlResult();
      
      // attempt the save again
      try {
         Boolean okay = DmlHelper.handleDML(recs, errLog.DMLType__c, dlo, DmlHelper.performDmlResult);
         // see if it failed again.
         if (!okay) {
            if (DmlHelper.performDmlResult != null) {
               // make sure we're getting the same type of errors
               ErrorLog.checkErrorTypes(errLog,DmlHelper.performDmlResult.firstError);
               ErrorLog.addToDescription(errLog,DmlHelper.performDmlResult.firstError);
               if (DmlHelper.performDmlResult.firstErrorRec != null) {
                  ErrorLog.addToObjectInfo(errLog,String.valueOf(DmlHelper.performDmlResult.firstErrorRec));
               }
               ErrorLog.saveErrorLog(errLog);
               checkForRetry(errLog, DmlHelper.performDmlResult.errorRecs, dlo);
            } // if (DmlHelper.performDmlResult
         } else {
            errLog.SuccessOnRetry__c = true;
            ErrorLog.saveErrorLog(errLog);
            retrySuccessful = true;
         }
      } catch (Exception e) {
         // if this exception happens, what should we do?
         ErrorLog.logError('DmlHelperRetry', 'execute', 'General Exception', null, e, null, true);
      }
      return retrySuccessful;      
   } // processRetry
      
   // for testing purposes
   public static Boolean FORCE_RETRY=false;

   public static void checkForRetry(ErrorLog__c errLog, SObject[] recs) {
      checkForRetry(errLog,recs,null);
   }
    
   public static void checkForRetry(ErrorLog__c errLog, SObject[] recs, Database.DMLOptions dlo) {
      // check if we should retry on this error - right now only on row lock
      Boolean retry=(FORCE_RETRY || errLog.RowLockError__c);
      ErrorLog.addToDescription(errLog, 'retry='+retry);
      Boolean enqueued = false;
      if (retry) {
         Apex_Batch_Control__c abc = getBatchControl();
         System.debug('checkForRetry recs='+recs.size()+' abc='+abc);
         // we won't using this command during a test
         ErrorLog.addToDescription(errLog, 'hasRecs='+(!recs.isEmpty()+' abc active='+(abc != null && abc.Active__c)));
         if (!recs.isEmpty() 
                && abc != null && abc.Active__c) {
            // don't launch this in a batch job
            if (!System.isBatch() && canWeRetry(errLog)) {
               ErrorLog.addToDescription(errLog,'enqueueJob');
               // save the errLog so we can preserve this state if anything happens
               ErrorLog.saveErrorLog(errLog);
               System.debug('checkForRetry enqueueing job');
               DmlHelperRetry dhr = new DmlHelperRetry(errLog, recs, dlo);
               try {
                  System.enqueueJob(dhr);
                  enqueued = true;
               } catch (Exception e) {
                  ErrorLog.addToDescription(errLog,'DmlHelperRetry Could not queue: '+e.getMessage());
               }
            } // if (canWeRetry
         } // if (!recs.isEmpty
      } // if (errLog.RowLockError__c
      if (!enqueued) {
         // make sure we've save this
         ErrorLog.saveErrorLog(errLog);
      }
   } // checkForRetry
   
   public static Boolean canWeRetry(ErrorLog__c errLog) {
      Apex_Batch_Control__c abc = getBatchControl();
      ErrorLog.addToDescription(errLog,'canWeRetry abc isActive='+(abc != null && abc.Active__c));
      Boolean retry = false;
      if (abc != null && abc.Active__c) {
         ErrorLogCS__c errorLogCs = ErrorLog.getCustomSetting(errLog);
         System.debug('canWeRetry errorLogCs='+errorLogCs);
         ErrorLog.addToDescription(errLog,'errorLogCs found='+(errorLogCs != null)+' NbrErrorRetry__c='+(errorLogCs != null ? errorLogCs.NbrErrorRetry__c : -1));
         if (errorLogCs != null && errorLogCs.NbrErrorRetry__c != null && errorLogCs.NbrErrorRetry__c > 0) {
            // make sure not a null value
            if (errLog.NbrRetries__c == null) {
               errLog.NbrRetries__c = 0;
            }
            // make sure we haven't hit the maximum number of retries for this type
            if (errLog.NbrRetries__c < errorLogCs.NbrErrorRetry__c) {
               retry = true;
               errLog.NbrRetries__c++;
               errLog.MaxRetries__c = errorLogCs.NbrErrorRetry__c;
               ErrorLog.addToDescription(errLog,'Retrying Save attempt '+errLog.NbrRetries__c);
            }
         } // if (errorLogCs != null
      } // if (abc != null && abc.Active__c
      return retry;
   } // canWeRetry
   
   public static final String CLASS_NAME='DmlHelperRetry';
    
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      return abc;
   } // getBatchControl

} // class DmlHelperRetry