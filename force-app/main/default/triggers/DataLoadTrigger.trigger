/* 
   Trigger for the DataLoad object
   
  History
  -------
  07/30/2020 Dan Carmen   Created

 */
trigger DataLoadTrigger on DataLoad__c (before insert, before update, after insert, after update) {
   DataLoadMethods.handleTrigger(Trigger.new, Trigger.oldMap);
} // trigger DataLoadTrigger