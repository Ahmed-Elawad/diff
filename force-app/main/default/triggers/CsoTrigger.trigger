/**
 * Trigger on the CSO Tracking object
 * 
 * History
 * -------
   10/03/2022 Dan Carmen      Added after update

 */
trigger CsoTrigger on CSO_Tracking__c (before insert, before update, after insert, after update) {
    System.debug('Entered CsoTrigger');
    TriggerMethods.handleTrigger('CsoTrigger', Trigger.new, Trigger.oldMap, null);
} // trigger CsoTrigger