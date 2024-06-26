/* 
 * Trigger on the Assignment_Groups__c object (label = Group Member)
 *
 * History
 * -------
   07/19/2019 Dan Carmen        Created.
 
 */
trigger GroupMember on Assignment_Groups__c (after delete, after insert, after undelete, after update) {
   GroupMemberHelper.checkFromTrigger(Trigger.new, Trigger.oldMap);
} // trigger GroupMember