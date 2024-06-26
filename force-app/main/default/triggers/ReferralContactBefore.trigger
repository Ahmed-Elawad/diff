/** This trigger to handle any before insert or before update processing.
 *
 * History
 * -------
 * 04/10/2013 Cindy Freeman     Created
   08/28/2013 Dan Carmen        Added parsing of full name field
   08/18/2016 Dan Carmen        Move Code to the ReferralAccountMethods class
   01/29/2018 Jacob Hinds        Added profiling
   08/02/2019 Dan Carmen        Add in SKIP_TRIGGERS
   10/02/2020 Dan Carmen        Update for lead loader
   03/26/2021 Jacob Hinds       Adding RJMethods call
   08/25/2021 Dan Carmen        Add call to TriggerMethods
   11/05/2021 Dan Carmen        Removed direct call to AccountProfiled - handle through TriggerMethods
   03/25/2022 Dan Carmen        Clean up trigger

*/

trigger ReferralContactBefore on Referral_Contact__c (before insert, before update) {

   if (ReferralAccountMethods.SKIP_TRIGGERS) {
      return;
   }

   // The Referrals flagged for deletion we need to check
    Map<Id, Referral_Contact__c> deleteRefCtctMap = new Map<Id, Referral_Contact__c>();

   ReferralAccountMethods.resetVariables();

   TriggerMethods.handleTrigger('ReferralContactBefore', Trigger.new, Trigger.oldMap, null);
    for ( Referral_Contact__c newR: Trigger.new) {
        Referral_Contact__c oldR = (Trigger.isUpdate ? Trigger.oldMap.get(newR.id) : null);
      if (Trigger.isUpdate && newR.To_Be_Deleted__c == true && oldR.To_Be_Deleted__c == false) {
         deleteRefCtctMap.put(newR.Id, newR);
      }
        
      ReferralAccountMethods.checkRefCtctBeforeActions(newR,oldR);
      ReferralAccountMethods.checkLeadLoaderBeforeActions(newR, oldR);
      
    } // for
    
   ReferralAccountMethods.checkRefCtctTriggerBeforeActions();

    if (!deleteRefCtctMap.isEmpty()) {
      ReferralContactValidation.validateDeletions(deleteRefCtctMap, false);
    }
    RJMethods.checkOACFieldChange(Trigger.new,Trigger.oldMap);

} // trigger ReferralContactBefore