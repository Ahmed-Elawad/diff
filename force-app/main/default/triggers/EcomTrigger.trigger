/* 
   Trigger on the ECommerce__c object

   
  History
  -------
  10/06/2020 Dan Carmen        Created

 */
trigger EcomTrigger on ECommerce__c (before insert, before update, after insert, after update) {
   new EcomMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
} // trigger EcomTrigger