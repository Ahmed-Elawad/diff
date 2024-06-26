/* 
 *  A trigger for the CSA Inquiries object.
 *   
 * History
 * -------
   09/27/2016 Dan Carmen       created
 
 */
trigger CSAInquiries on CSA_Inquiries__c (before insert, before update) {
   for (CSA_Inquiries__c rec : Trigger.new) {
      CSA_Inquiries__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(rec.Id) : null);
      SRRTransitionHelper.checkBeforeActions(rec,oldRec);
   }
   SRRTransitionHelper.processBeforeActions();
} // trigger CSAInquiries