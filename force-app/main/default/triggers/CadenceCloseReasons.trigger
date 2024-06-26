/* Trigger on the Cadence_Close_Reasons__c object

 * History
 * -------
  11/16/2019 Dan Carmen           Created

*/
trigger CadenceCloseReasons on Cadence_Close_Reasons__c (after insert, after update, before insert, before update) {
    TriggerMethods.checkBeforeLoop('CadenceCloseReasons', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
} // trigger CadenceCloseReasons