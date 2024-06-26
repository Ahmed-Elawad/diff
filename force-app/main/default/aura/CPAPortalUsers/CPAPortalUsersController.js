/*
02/27/2023   Vinay   Added functionality to set "isEndDated" in init method.

*/
({
	init  : function(component, event, helper) {
		var today = new Date();
		var inviteSentDate = new Date(component.get('v.commUser.Requested_Invite_Date__c'));
		var sevenDaysFromInvite = inviteSentDate.setDate(inviteSentDate.getDate() + 7);
		component.set('v.invitationExpiryDate', sevenDaysFromInvite);
		if(today > sevenDaysFromInvite) {
			component.set('v.isEndDated', true);
		}
	}
})