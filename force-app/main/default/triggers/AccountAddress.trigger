/** Trigger for working on the Account Address object

 * 
 * History
 * -------
   01/20/2023 Dan Carmen         Created
   03/22/2023 Dan Carmen         Added after actions

 */
trigger AccountAddress on AccountAddress__c (before insert, before update, after insert, after update) {
   new AccountAddressMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
} // trigger AccountAddress