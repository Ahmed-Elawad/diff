/** This trigger to handle any before insert or before update processing.
 * History
 * -------
 * 04/10/2013 Cindy Freeman     Created
   08/23/2016 Dan Carmen        Cleaning up the code
   05/18/2018 Dan Carmen        Add TriggerMethods call
   08/02/2019 Dan Carmen        Add in SKIP_TRIGGERS
   10/02/2020 Dan Carmen        Update for lead loader
   03/25/2022 Dan Carmen        Clean up code
   04/12/2022 Dan Carmen        Fix deleteRefAcctMap map

*/
 
trigger ReferralAccountBefore on Referral_Account__c (before insert, before update) {
   if (ReferralAccountMethods.SKIP_TRIGGERS) {
      return;
   }
   Map<Id,Referral_Account__c> deleteRefAcctMap = new Map<Id,Referral_Account__c>();

   ReferralAccountMethods.resetVariables();
   TriggerMethods.checkBeforeLoop('ReferralAccountBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   for ( Referral_Account__c refAcct: Trigger.new) {
      Referral_Account__c oldRefAcct = (Trigger.isUpdate ? Trigger.oldMap.get(refAcct.id) : null);
      ReferralAccountMethods.checkBeforeActions(refAcct, oldRefAcct);
      ReferralAccountMethods.checkLeadLoaderBeforeActions(refAcct, oldRefAcct);
      TriggerMethods.checkInLoop('ReferralAccountBefore', refAcct, oldRefAcct, Trigger.IsBefore, Trigger.IsAfter);
        
      if (Trigger.isUpdate) {
         if (refAcct.To_Be_Deleted__c == true && oldRefAcct.To_Be_Deleted__c == false) {
            deleteRefAcctMap.put(refAcct.Id, refAcct);
         }
      }
	} // for
	
	ReferralAccountMethods.checkRefAcctTriggerBeforeActions();
	
	if (!deleteRefAcctMap.isEmpty()) {
      ReferralAccountValidation.validateDeletions(deleteRefAcctMap, false);
	}
    TriggerMethods.checkOutsideLoop('ReferralAccountBefore', Trigger.isBefore, Trigger.isAfter);
	
	
} // trigger ReferralAccountBefore