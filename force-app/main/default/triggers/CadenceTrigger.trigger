/* Trigger on the Cadence__c object

 * History
 * -------
  11/16/2019 Dan Carmen           Created
  05/17/2022 Dan Carmen           Update API version

*/
trigger CadenceTrigger on Cadence__c (after insert, after update, before insert, before update) {
    TriggerMethods.handleTrigger('CadenceTrigger', Trigger.new, Trigger.oldMap, null);
} // trigger CadenceTrigger