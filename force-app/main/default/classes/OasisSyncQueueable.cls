/* 
 * Send records through the Oasis Sync
 *
 * History
 * -------
  05/08/2019 Dan Carmen       Created
  08/09/2019 Dan Carmen        Changes to move workable code to DuplicateCheckQueueable
  03/10/2020 Dan Carmen        Comment out all code

*/
//public without sharing class OasisSyncQueueable implements Queueable {
public without sharing class OasisSyncQueueable {
    
   //public ErrorLog__c runLog;

   public OasisSyncQueueable() {
      //runLog = ErrorLog.logError('OasisSyncQueueable', 'LOG_DATA', 'LOG_DATA', '', '');
      // so we only save the log if we want to.
      //ErrorLog.errorLogList.clear();
      //runLog.BatchSize__c = 0;
   } // OasisSyncQueueable
   //public Id[] recIds = new Id[]{};
   
   //public void addIdToProcess(Id recId, String syncType) {
      //recIds.add(recId);
      //runLog.BatchSize__c = recIds.size();
   //} // addIdToProcess
   
   /*
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('OasisSyncQueueable');
      return abc;
   } // getBatchControl
   
   public void execute(QueueableContext context) {      
      Id[] recIdsToProcess = new Id[]{};
      Id[] recIdsRemaining = new Id[]{};
      Apex_Batch_Control__c abc = getBatchControl();
      Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 1);

      for (Id recId : recIds) {
         if (recIdsToProcess.size() < batchSize) {
            recIdsToProcess.add(recId);
         } else {
            recIdsRemaining.add(recId);
         }
      } // for (Id recId
      addToLog('batchSize='+batchSize+' recIdsToProcess='+recIdsToProcess.size()+' recIdsRemaining='+recIdsRemaining.size());

      processRecs(recIdsToProcess);

      if (!recIdsRemaining.isEmpty()) {
         OasisSyncQueueable newOSQ = new OasisSyncQueueable();
         newOSQ.recIds = recIdsRemaining;
         launchQueueable(newOSQ);
      }
   } // execute
   */
   //public void processRecs() {
      //processRecs(recIds);
   //} // processRecs
   /*
   public void processRecs(Id[] recIdsToProcess) {
      Lead[] leads = queryLeads(recIdsToProcess);
      addToLog('leads='+leads.size());
      if (leads.size() > 0) {
         ErrorLog.setCodeKey(runLog, leads[0].Name);
      }
      OasisSyncLeads.processLeads(leads, (Map<Id,Lead>)null, OasisSyncHelper.SYNC_DUPE_RESULT, runLog);
      
      saveLog();
   } // processRecs
   */
   //public static void launchQueueable(OasisSyncQueueable p_osq) {
      //Apex_Batch_Control__c abc = getBatchControl();
      //System.debug('launchQueueable abc='+abc);
      //if (p_osq != null && abc != null && abc.Active__c && !p_osq.recIds.isEmpty()) {
         //OasisSyncQueueable osq = new OasisSyncQueueable();
         //osq.recIds = p_osq.recIds;
      //   System.debug('launchQueueable enqueueJob');
      //   System.enqueueJob(p_osq);
      //}
   //} // launchQueueable
/*
   public void addToLog(String notesToAdd) {
      ErrorLog.addToDescription(runLog,notesToAdd);
   } // addToLog
   
   public void saveLog() {
      Apex_Batch_Control__c abc = getBatchControl();
      if (abc != null && abc.LogProcess__c && runLog != null) {
         ErrorLog.saveErrorLog(runLog);
      }
   } // saveLog

   public static Lead[] queryLeads(Id[] leadIds) {
      Lead[] lds = [Select Id, Name
                          ,City
                          ,Company
                          ,ConvertedAccountId
                          ,ConvertedContactId
                          ,ConvertedDate
                          ,CreatedByProcess__c
                          ,DisqualifiedReason__c
                          ,DuplicateCheckStatus__c
                          ,Email
                          ,Fax
                          ,FirstName
                          ,Industry
                          ,IsConverted
                          ,LastName
                          ,LastActivityDate
                          ,LeadSource
                          ,MobilePhone
                          ,NumberOfEmployees
                          ,OasisId__c 
                          ,Other_Phone__c
                          ,OwnerId
                          ,OwnedBy__c
                          ,OwnedByPrev__c
                          ,Phone
                          ,PostalCode
                          ,Product_Division__c
                          ,State
                          ,Status
                          ,Street
                          ,Title
                          ,Website
                      From Lead
                     Where Id in :leadIds];
                     
      return lds;
   } // queryLeads
   */
} // class OasisSyncQueueable