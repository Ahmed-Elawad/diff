/* 
 * Break up the save routine
 *
 * History
 * -------
   06/04/2019 Dan Carmen       Created

*/
//public with sharing class OasisSaveQueueable implements Queueable {
public with sharing class OasisSaveQueueable {
    public OasisSaveQueueable() {}
   /*
   public static String CLASSNAME='OasisSaveQueueable';
   
   public Map<Id,Datetime> processNowMap = new Map<Id,Datetime>();
   public Map<Id,Datetime> processNextMap = new Map<Id,Datetime>();
   public ErrorLog__c log = null;
    
   public OasisSaveQueueable(Map<Id,Datetime> p_oasisSyncIdMap) {
      Apex_Batch_Control__c abc = getBatchControl();
      Integer batchSize = (abc != null && abc.BatchSize__c != null ? (Integer)abc.BatchSize__c : 10);
      System.debug('OasisSaveQueueable batchSize='+batchSize);
      for (Id key : p_oasisSyncIdMap.keySet()) {
         if (processNowMap.size() < batchSize) {
            processNowMap.put(key,p_oasisSyncIdMap.get(key));
         } else {
            processNextMap.put(key,p_oasisSyncIdMap.get(key));
         }
      }

   } // OasisSaveQueueable

   public void execute(QueueableContext context) {
      processRecs();
      // wait before trying to save the next bunch of records
      //sleep(SLEEP_SECONDS);
      //saveRecords(); 
   } // execute
   
   public void processRecs() {
      // retrieve the records
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Set<String>(), processNowMap.keySet());
      if (syncMap.isEmpty()) {
         return;
      }
      Map<String,User> usersByPersonIdMap = OasisSyncHelper.getUsersByPersonIdMap(syncMap.values()); 
      Apex_Batch_Control__c abc = getBatchControl();
      System.debug('processRecs abc='+abc);
      if (abc != null && abc.LogProcess__c) {
         log = ErrorLog.logError(CLASSNAME, 'LOG_DATA', syncMap.values()[0].Name, null, 'usersByPersonIdMap='+usersByPersonIdMap.size()+' user='+UserInfo.getLastName());
         log.BatchSize__c = processNowMap.size();
         log.NbrSuccess__c = syncMap.size();
         log.NbrRetries__c = processNextMap.size();
         log.ObjectId__c = syncMap.values()[0].Id;
         OasisSyncHelper.log = log;
      }
      
      OasisSync__c[] updateSyncs = new OasisSync__c[]{};
      
      Map<String,Campaign> campMap = OasisSyncHelper.getCampaignMap(syncMap.values());

      for (OasisSync__c sync : syncMap.values()) {
         Datetime checkTime = processNowMap.get(sync.Id);
         // if it doesn't meet these criteria do nothing and continue
         // compare the retrieve date - only process if the same (could have been sent again, in which case we'll let it process later)
         //Boolean timesMatch = (checkTime != null && checkTime == sync.ReceivedLastUpdated__c);
         //Boolean timesMatch2 = (checkTime != null && sync.ReceivedLastUpdated__c != null && checkTime.getTime() == sync.ReceivedLastUpdated__c.getTime());
         //String times = 't1='+checkTime.getTime()+' t2='+sync.ReceivedLastUpdated__c.getTime()+' t3='+Integer.valueOf(checkTime.getTime()/1000);
         Boolean timesMatch = (checkTime != null && sync.ReceivedLastUpdated__c != null && Integer.valueOf(checkTime.getTime()/1000) == Integer.valueOf(sync.ReceivedLastUpdated__c.getTime()/1000));
         
         if (!sync.Processed__c && sync.Source__c == OasisSyncHelper.SOURCE_OASIS 
                   && timesMatch) {
            User usr = OasisSyncHelper.getUserFromMap(sync, usersByPersonIdMap);
            OasisSyncHelper.handleRecord(sync, usr, campMap);
            updateSyncs.add(sync);
         } else {
            ErrorLog.addToDescription(log,'Could not process Id='+sync.Id+'. Processed='+sync.Processed__c+' Source='+sync.Source__c+' timesMatch='+timesMatch+' checkTime='+checkTime+' ReceivedLastUpdated__c='+sync.ReceivedLastUpdated__c);
         }
      } // for (OasisSync__c sync : syncMap
      
      ErrorLog.saveErrorLog(log);
      
      OasisSync__c[] syncsWithLinks = new OasisSync__c[]{};
      // separate the links to records that haven't been created so we can save just those fields a second time.
      for (OasisSync__c sync : updateSyncs) {
         OasisSync__c newSync = new OasisSync__c();
         if (sync.Account__r != null) {
            System.debug('processRecs account link is set');
            if (sync.Account__r.Id == null) {
               newSync.Id = sync.Id;
               newSync.Account__r = sync.Account__r;
               newSync.Account__c = sync.Account__c;
            } else {
               if (sync.Account__r.Id != sync.Account__c || sync.Account__r.Id != sync.AccountIdPayx__c) {
                  sync.Account__c = sync.Account__r.Id;
                  sync.AccountIdPayx__c = sync.Account__r.Id;
               }
            }
            System.debug('processRecs 1newSync.Account__r='+(newSync.Account__r != null));
            sync.Account__r = null;
            System.debug('processRecs 2newSync.Account__r='+(newSync.Account__r != null));
         }
         if (sync.Contact__r != null) {
            System.debug('processRecs contact link is set');
            if (sync.Contact__r.Id == null) {
               newSync.Id = sync.Id;
               newSync.Contact__r = sync.Contact__r;
               newSync.Contact__c = sync.Contact__c;
            } else {
               if (sync.Contact__r.Id != sync.Contact__c || sync.Contact__r.Id != sync.ContactIdPayx__c) {
                  sync.Contact__c = sync.Contact__r.Id;
                  sync.ContactIdPayx__c = sync.Contact__r.Id;
               }
            }
            sync.Contact__r = null;
            System.debug('processRecs newSync.Contact__r='+(sync.Contact__r != null));
         }
         
         if (sync.Lead__r != null) {
            System.debug('processRecs lead link is set');
            if (sync.Lead__r.Id == null) {
               newSync.Id = sync.Id;
               newSync.Lead__r = sync.Lead__r;
               newSync.Lead__c = sync.Lead__c;
            } else {
               if (sync.Lead__r.Id != sync.Lead__c || sync.Lead__r.Id != sync.LeadIdPayx__c) {
                  sync.Lead__c = sync.Lead__r.Id;
                  sync.LeadIdPayx__c = sync.Lead__r.Id;
               }
            }
            sync.Lead__r = null;
         }
         if (newSync.Id != null) {
            System.debug('processRecs add record to syncsWithLinks');
            syncsWithLinks.add(newSync);
         }
      } // for (OasisSync__c sync : updateSyncs
      
      System.debug('processRecs updateSyncs='+updateSyncs.size()+' syncsWithLinks='+syncsWithLinks.size());
      
      OasisSyncHelper.checkSave(new OasisSync__c[]{}, updateSyncs);
       
      OasisSyncHelper.checkSave();
      ErrorLog.saveErrorLog(log);

      for (OasisSync__c sync : syncsWithLinks) {
         System.debug('processRecs hasAcct='+(sync.Account__r != null)+' hasCtct='+(sync.Contact__r != null)+' hasLead='+(sync.Lead__r != null));
         if (sync.Account__r != null && sync.Account__r.Id != null && (sync.Account__c != sync.Account__r.Id || sync.AccountIdPayx__c != sync.Account__r.Id)) {
            sync.Account__c = sync.Account__r.Id;
            sync.AccountIdPayx__c = sync.Account__r.Id;
            System.debug('processRecs setting account id '+sync.Account__c);
         }
         if (sync.Contact__r != null && sync.Contact__r.Id != null && sync.Contact__c != sync.Contact__r.Id) {
            sync.Contact__c = sync.Contact__r.Id;
            sync.ContactIdPayx__c = sync.Contact__r.Id;
            System.debug('processRecs setting contact id '+sync.Contact__c);
         }
         if (sync.Lead__r != null && sync.Lead__r.Id != null && sync.Lead__c != sync.Lead__r.Id) {
            System.debug('processRecs setting lead id');
            sync.Lead__c = sync.Lead__r.Id;
            sync.LeadIdPayx__c = sync.Lead__r.Id;
         }
         sync.Account__r = null;
         sync.Contact__r = null;
         sync.Lead__r = null;

      } // for (OasisSync__c sync : updateSyncs
      
      OasisSyncHelper.checkSave(new OasisSync__c[]{}, syncsWithLinks);

      OasisSyncHelper.checkSendRecordIdUpdates();
      
      if (!processNextMap.isEmpty() && abc != null && abc.NbrOfAttempts__c > 0) {
         Integer sleepSeconds = (abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 0);
         Long sleepDuration = Utilities.Sleep(Integer.valueOf(sleepSeconds));
         ErrorLog.addToDescription(log, 'Sleep duration: '+sleepDuration);
      }
      ErrorLog.saveErrorLog(log);
   }// processRecs

   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      return abc;
   } // getBatchControl
   */

} // class OasisSaveQueueable