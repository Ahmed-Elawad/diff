/* 
 * Trigger for actions on a Referral object
 *
 * History
 * -------
 * 08/21/2012 Dan Carmen       Created
 * 12/03/2015 Cindy Freeman    If referral approval is rejected, want to move reject comments onto referral record
   01/26/2016 Dan Carmen       Check disposition for commissions
   04/19/2021 Dan Carmen       Added recursion check

 */
trigger ReferralTrigger on Referral__c (before insert, after insert, before update, after update) {
   // do we skip this trigger?
   if (ReferralTriggerActions.SKIP_TRIGGER) {
      return;
   }

   TriggerMethods.checkBeforeLoop('ReferralTrigger', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   for (Referral__c ref : Trigger.new) {
      Referral__c oldRef = (Trigger.isUpdate ? Trigger.oldMap.get(ref.id) : null);

      TriggerMethods.checkInLoop('ReferralTrigger', ref, oldRef, Trigger.IsBefore, Trigger.IsAfter);
   	if (Trigger.isBefore) {
   	   ReferralTriggerActions.checkBeforeActions(ref, oldRef);

   	} else if (Trigger.isAfter) {
         ReferralTriggerActions.checkAfterActions(ref, oldRef);
   	}
   } // for (Referral__c ref
   
   TriggerMethods.checkOutsideLoop('ReferralTrigger', Trigger.isBefore, Trigger.isAfter);

   if (Trigger.isBefore) {
      ReferralTriggerActions.handleBeforeActions();
   } else if (Trigger.isAfter) {
      ReferralTriggerActions.handleAfterActions();
      // to prevent recursion
      ReferralTriggerActions.SKIP_TRIGGER = (Label.ReferralTrigger_PreventRecursion == 'Y');
   }

} // trigger ReferralTrigger