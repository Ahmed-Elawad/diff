/** This trigger is to handle any after insert or after update processing.
 * History
 * -------
 * 02/21/2014 Justin Stouffer   Created
   03/16/2017 Dan Carmen        Changed criteria for ReferralObjectsSync call
   11/02/2018 Dan Carmen        Added call to refCtctAfterActions
   08/02/2019 Dan Carmen        Add in SKIP_TRIGGERS
   08/25/2021 Dan Carmen        Add call to TriggerMethods

*/

trigger ReferralContactAfter on Referral_Contact__c (after insert, after update, before delete) {
	
   if (ReferralAccountMethods.SKIP_TRIGGERS) {
      return;
   }

	If(trigger.isBefore){
		ReferralObjectsSync.deletedRefCntcts(trigger.old);	
	}else if(trigger.isAfter){
       TriggerMethods.handleTrigger('ReferralContactAfter', Trigger.new, Trigger.oldMap, null);
	   Map<Id,Referral_Contact__c> oldMap = (Trigger.isUpdate ? Trigger.oldMap : null);
		ReferralObjectsSync.processReferralContacts(trigger.new, oldMap);
		ReferralAccountMethods.refCtctAfterActions(trigger.new, oldMap);
    }
} // ReferralContactAfter