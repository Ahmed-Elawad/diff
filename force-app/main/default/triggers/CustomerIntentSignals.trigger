/* 
 * 12/13/2023 Shilpa Govindarajulu       APR0155814-Created
 * 
 * 
 */

trigger CustomerIntentSignals on Customer_Intent_Signal__c (after insert) {
	IntentHelper.handleTrigger(trigger.new,Trigger.oldMap);
}