/* Trigger for this object
 *
 * History
 * -------
   08/26/2019 	Jake Hinds       Created
*/

trigger BusinessProfileTrigger on Business_Profile__c (before insert,after insert,before update,after update) {
	TriggerMethods.checkBeforeLoop('BusinessProfileTrigger', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
	for (Business_Profile__c bp : Trigger.new) {
		Business_Profile__c oldBP = (Trigger.isUpdate ? Trigger.oldMap.get(bp.id) : null);
		TriggerMethods.checkInLoop('BusinessProfileTrigger', bp, oldBP, Trigger.IsBefore, Trigger.IsAfter);
	} // for (Business_Profile__c bp
	TriggerMethods.checkOutsideLoop('BusinessProfileTrigger', Trigger.isBefore, Trigger.isAfter);
}