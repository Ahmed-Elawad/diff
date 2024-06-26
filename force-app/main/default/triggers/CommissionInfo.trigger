/* Trigger for the Commission Info object
   
  History
  -------
  02/19/2016 Dan Carmen   Created
  
 */
trigger CommissionInfo on CommissionInfo__c (before insert, before update) {

   for (CommissionInfo__c comInfo : Trigger.new) {
      CommissionInfo__c oldComInfo = (Trigger.isUpdate ? Trigger.oldMap.get(comInfo.id) : null);
      if (Trigger.isBefore) {
         CommissionMethods.checkTriggerBeforeActions(comInfo,null);
      }
      if (Trigger.isAfter) {
         CommissionMethods.checkTriggerAfterActions(comInfo,null);
      }
   } // for (CommissionInfo__c comInfo

   if (Trigger.isBefore) {
      CommissionMethods.processTriggerBefore();
   }

   if (Trigger.isBefore) {
      CommissionMethods.processTriggerAfter();
   }
   
} // trigger CommissionInfo