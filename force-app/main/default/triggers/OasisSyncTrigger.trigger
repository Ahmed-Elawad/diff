/* Trigger on the OasisSync object

  History
  -------
  04/04/2019 Dan Carmen        Created
  03/11/2020 Dan Carmen        Comment out code
  
 */
trigger OasisSyncTrigger on OasisSync__c (after insert, after update, before insert, before update) {
   //OasisSyncHelper.processRecords(Trigger.new, Trigger.oldMap);
   
} // trigger OasisSyncTrigger