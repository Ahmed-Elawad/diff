/* Trigger on the AccountMatch__c object

 * History
 * -------
  07/27/2022 Dan Carmen           Created

*/
trigger AccountMatch on AccountMatch__c (before insert, before update) {
   new AccountMatch().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
} // trigger AccountMatch