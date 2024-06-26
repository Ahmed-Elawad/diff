/** This trigger is to handle any after insert or after update processing.
 * History
 * -------
 * 02/21/2014 Justin Stouffer   Created
 * 12/31/2015 Jacob Hinds		Added in Sensivity push method from Parent referral account to child referral account to referral contacts
   07/25/2016 Dan Carmen      Change to make code more dynamic.
   03/16/2017 Dan Carmen        Changed criteria for ReferralObjectsSync call
   05/17/2018 Dan Carmen        Add calls to TriggerMethods
   08/02/2019 Dan Carmen        Add in SKIP_TRIGGERS
   02/13/2020 Cindy Freeman		moved setting of SENSITIVITY_UPDATE_IN_PROGRESS to ReferralAccountMethods
   01/27/2023 Jidesh            Added logic to trigger Chatter notifications for CPA
*/

trigger ReferralAccountAfter on Referral_Account__c (after insert, after update, before delete) {
   
   if (ReferralAccountMethods.SKIP_TRIGGERS) {
      return;
   }
	
	Map<Referral_Account__c, Map<String,Boolean>> updateMap = new Map<Referral_Account__c,Map<String,Boolean>>();
	
	if(trigger.isBefore){
		ReferralObjectsSync.deletedRefAccts(trigger.old);		
	}
	else if (trigger.isAfter){
		ReferralObjectsSync.processReferralAccounts(trigger.new, Trigger.oldMap);
	}
	
	if(trigger.isAfter && trigger.isUpdate && !ReferralAccountMethods.SENSITIVITY_UPDATE_IN_PROGRESS){
	    // ReferralAccountMethods.SENSITIVITY_UPDATE_IN_PROGRESS = true;
		for(Referral_Account__c newVal: Trigger.new){
			Referral_Account__c oldVal = Trigger.oldMap.get(newVal.id);
			ReferralAccountMethods.checkTriggerAfterDuring(newVal, oldVal);

		}
		
		ReferralAccountMethods.checkTriggerAfterActions();
	} // if(trigger.isAfter && trigger.isUpdate
	
	// TODO - the other code in the trigger should be modified to use the TriggerMethods logic
   if (Trigger.isInsert || Trigger.IsUpdate) {
      TriggerMethods.checkBeforeLoop('ReferralAccountAfter', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
      for (Referral_Account__c refAcct : Trigger.new) {
         Referral_Account__c oldRefAcct = (Trigger.isUpdate ? (Referral_Account__c)Trigger.oldMap.get(refAcct.Id) : null);
         TriggerMethods.checkInLoop('ReferralAccountAfter', refAcct, oldRefAcct, Trigger.IsBefore, Trigger.IsAfter);
      }

      TriggerMethods.checkOutsideLoop('ReferralAccountAfter', Trigger.isBefore, Trigger.isAfter);
       if(trigger.isAfter){
           CPA_ChatterMessages.mutualClientNewTierNotification(trigger.new, Trigger.oldMap, Trigger.isInsert, Trigger.IsUpdate);
       }
      
   } // if (Trigger.isInsert || Trigger.IsUpdate)
   

} // trigger ReferralAccountAfter