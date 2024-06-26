/** Handle actions from the P Referral object
 *
 * History 
 * -------
   10/07/2015 Dan Carmen      Created
   12/14/2016 Cindy Freeman    Modified to create Marketing Call Tracking records 
   02/01/2017 Cindy Freeman    Moved check for Partner Referrals for Marketing Call Tracking record to triggerCheckAfterActions
   02/16/2017 Cindy Freeman	   removed comments so code is easier to read
   10/15/2020 Dan Carmen       Moved more code to PartnerReferralHelper

 */ 
trigger PartnerReferral on PartnerReferral__c (after insert, after update, before insert, before update) {
             
   if (Trigger.isBefore) {
      PartnerReferralHelper.checkBeforeActions(Trigger.new, Trigger.oldMap);
   } else if (Trigger.isAfter) {
      PartnerReferralHelper.checkAfterActions(Trigger.new, Trigger.oldMap);
   }
   /*
   for (PartnerReferral__c partRef : Trigger.new) {
      PartnerReferral__c oldPartRef = (Trigger.isUpdate ? Trigger.oldMap.get(partRef.id) : null);
      //if (Trigger.isBefore) {
      //   PartnerReferralHelper.triggerCheckBeforeActions(partRef, oldPartRef);
      //}
      if (Trigger.isAfter) {
         PartnerReferralHelper.triggerCheckAfterActions(partRef, oldPartRef, Trigger.isInsert);
      }
   } // for (PartnerReferral__c bankRef
   
   //if (Trigger.isBefore) {
   //   PartnerReferralHelper.processTriggerBefore();
   //}
   if (Trigger.isAfter) {
      PartnerReferralHelper.processTriggerAfter();
   }
   */

} // trigger PartnerReferral