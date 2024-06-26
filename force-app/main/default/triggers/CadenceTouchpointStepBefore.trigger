/* 
 *
 * History
 * -------
 * 05/15/2019	 Jermaine Stukes   Created
   12/20/2019   Dan Carmen        Moved logic to CadenceHelper
   05/01/2020   Dan Carmen        Add before delete
 */
trigger CadenceTouchpointStepBefore on Cadence_Step__c (before delete, before insert, before update, after insert, after update) {
   new CadenceHelper().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);

} // trigger CadenceTouchpointStepBefore