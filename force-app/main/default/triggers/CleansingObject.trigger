/* 
 *  A trigger for the Cleansing Object object.
 *   
 * History
 * -------
   10/04/2016 Dan Carmen       created
 
 */
trigger CleansingObject on Cleansing_Object__c (before insert, before update) {
   for (Cleansing_Object__c rec : Trigger.new) {
      Cleansing_Object__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(rec.Id) : null);
      SRRTransitionHelper.checkBeforeActions(rec,oldRec);
   }
   SRRTransitionHelper.processBeforeActions();
} // trigger CleansingObject