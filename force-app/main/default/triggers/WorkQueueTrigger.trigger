/* Trigger for Work Queue
*
*   HISTORY
*  ---------
*   05/16/2024  Jidesh     Created

*/
trigger WorkQueueTrigger on Work_Queue__c (before insert, after insert) {
    if(Trigger.isAfter && Trigger.IsInsert && System.Label.Enable_WorkQueue_Triggers == 'Yes'){
        WorkQueueTriggerHandler.afterInsertHandler(Trigger.OldMap, Trigger.NewMap);
    }
}