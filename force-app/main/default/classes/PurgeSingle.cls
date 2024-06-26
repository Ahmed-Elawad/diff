/* 
 * Purge a single iteration from PurgeControl
 *
 * History
 * -------
   12/08/2020 Dan Carmen   Created

 */
@RestResource(urlMapping='/purgeSingle/*')
global without sharing class PurgeSingle {

   @HttpPost
   global static void doPost(Integer nbrSecs) {
      ErrorLog__c log = ErrorLog.getLog('PurgeSingle');
      
      PurgeControl__c pc = ProcessChecker.getAnyTimeRecord(new String[]{PurgeBatch.PURGE});
      if (pc != null) {
         PurgeControlTracker__c[] insertTrackers = new PurgeControlTracker__c[]{};
         PurgeControlTracker__c[] updateTrackers = new PurgeControlTracker__c[]{};
         PurgeBatch pb = new PurgeBatch();
         pb.handlePurge(pc, insertTrackers, updateTrackers, false);
         DmlHelper.performDML(new PurgeControl__c[]{pc}, DmlHelper.DML_UPDATE, 'PurgeSingle', 'doPost', 'update the purge records', false);
         DmlHelper.performDML(insertTrackers, DmlHelper.DML_INSERT, 'PurgeSingle', 'doPost', 'inserting purge trackers', false);
         DmlHelper.performDML(updateTrackers, DmlHelper.DML_UPDATE, 'PurgeSingle', 'doPost', 'updating purge trackers', false);
         ErrorLog.checkSave();
      }
      ErrorLog.addToDescription(log, (pc != null? 'Ran the '+pc.Name+' purge' : 'Could not find a PurgeControl to run'));
      ErrorLog.saveLog(log);
      
   } // doPost
    
} // class PurgeSingle