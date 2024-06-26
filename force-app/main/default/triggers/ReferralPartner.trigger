/* 
 * Handle all trigger actions from the Referral_Partner__c object.
 *
 * History
 * -------
 * 08/22/2012 Dan Carmen   Created
   05/20/2019 Dan Carmen   Clear the cache on save of a referral partner.

 */
trigger ReferralPartner on Referral_Partner__c (before insert, before update) {

   // the records to check for the selling opportunity record type ids
   Referral_Partner__c[] checkOppRecTypeIds = new Referral_Partner__c[]{};
   
   for (Referral_Partner__c rec : Trigger.new) {
      Referral_Partner__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(rec.Id) : null);
      SRRTransitionHelper.checkBeforeActions(rec,oldRec);
    // only check if we're going to be creating a referring opportunity
      if (rec.CreateRefOpp__c) {
         checkOppRecTypeIds.add(rec);
      }
   } // for (Referral_Partner__c
   
   SRRTransitionHelper.processBeforeActions();

   if (!checkOppRecTypeIds.isEmpty()) {
    ReferralPartnerMethods.checkRecordTypeId(checkOppRecTypeIds);
   }
   
   ReferralQueries.clearReferralPartnerCache();
} // trigger ReferralPartner