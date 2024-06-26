/* Trigger on the NewUserRequest__c object 
   
   History
   -------
   04/23/2024 Dan Carmen   Created
  
 */
trigger NewUserRequest on NewUserRequest__c (after insert, after update) {
   NewUserHelper.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
} // NewUserRequest