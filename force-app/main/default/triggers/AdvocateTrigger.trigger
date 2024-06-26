/* 
 * Trigger for the Advocate object.
 *
 * History
 * -------
 * 03/01/2020 Jermaine Stukes	Created
 * */
trigger AdvocateTrigger on amp_dev__Amp_Advocate__c  (after update, before insert) {  
    new AmplifinityHelper().triggerCheckAllFirst(trigger.New, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
} // trigger CarAfter