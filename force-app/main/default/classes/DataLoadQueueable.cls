/** Queueable to process the dataload Bulk
 * 
 * History
 * -------
   03/30/2021 Dan Carmen           Created

*/
public class DataLoadQueueable implements Queueable, Database.AllowsCallouts {

   public static final String CLASSNAME='DataLoadQueueable';
   
   public Id dataLoadId = null;
    
   public DataLoadQueueable(Id p_dataLoadId) {
      dataLoadId = p_dataLoadId;
   }
    
   public void execute(QueueableContext context) {
      processRecs();
   } // execute
    
   public void processRecs() {
      Id v_dataLoadId = dataloadId;
      String query = ObjectHelper.getSOQLQuery('DataLoad__c', null, false, false, false, false, false);
      query += ' Where Id=:v_dataLoadId ';
      try {
         DataLoad__c dl = Database.query(query);
         if (dl.Status__c == DataLoadMethods.STATUS_PROCESS_BULK) {
            //submitDataLoad = dataLoad;
            try {
               new DataLoadBatch3().handleSubmit(dl);
            } catch (Exception e) {
               dl.Status__c = DataLoadMethods.STATUS_ERROR;
               StringHelper.addToProcessNotes(dl,'Exception submitting the job: '+e.getMessage()+'; '+e.getStackTraceString());
            }
            update dl;
            DataLoadBatch3.launchBatchCheck();
         }
      } catch (Exception e) {
         System.debug('processRecs exception: '+e.getMessage());
      }
  
   } // processRecs

   public static Boolean checkLaunchQueuable(Id dataLoadId) {
      Boolean queueableLaunched = false;
      if (dataLoadId != null) {
         Apex_Batch_Control__c abc = getBatchControl();
         System.debug('checkLaunchQueuable dataLoadId='+dataLoadId+' abc='+abc);
         // we won't using this command during a test
         Boolean abcIsActive = (abc != null && abc.Active__c);
         DataLoadQueueable dq = new DataLoadQueueable(dataLoadId);
         Boolean allowFuture = Utilities.allowFuture();
         System.debug('checkLaunchQueuable abcIsActive='+abcIsActive+' allowFuture='+allowFuture);
         if (abcIsActive && allowFuture) {
            System.enqueueJob(dq);
            queueableLaunched=true;
         } else {
            // run it inline
            System.debug('checkLaunchQueuable launching inline');
            dq.processRecs();
         }
      } // if (!ecomsToProcess.isEmpty
      return queueableLaunched;
   } // checkLaunchQueuable
    
    
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      return abc;
   } // getBatchControl

} // class DataLoadQueueable