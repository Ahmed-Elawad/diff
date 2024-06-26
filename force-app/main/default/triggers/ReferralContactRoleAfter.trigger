/** This trigger is to handle any after insert or after update processing.
 * History
 * -------
 * 02/21/2014 Justin Stouffer   Created
 *
*/

trigger ReferralContactRoleAfter on Referral_Contact_Role__c (before insert, before update, after insert, after update) {
	
	if (Trigger.isBefore) {
	   ReferralObjectsSync.processRefContactRoles(Trigger.new);
	}
	//ReferralObjectsSync.processReferralContactRoles(trigger.new);
	
}