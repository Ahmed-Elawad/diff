/* Change the ownership of the records when the status is set to Approved.
   
  History
  -------
  10/07/2009 Dan Carmen   Clean up trigger code - moved from Approveemail trigger
  08/01/2010 Dan Carmen   Add in HRS functionality
  05/06/2021 Dan Carmen   Update API version
    
 */
trigger TransferRequestCheckStatus on Transfer_Request__c (before insert, before update) {

   Transfer_Request__c[] approveRequests = new Transfer_Request__c[]{};
   Transfer_Request__c[] declinedRequests = new Transfer_Request__c[]{};
   
   for (Transfer_Request__c tr : Trigger.new) {
      if (Trigger.isInsert) {
      	 // a transfer status on create is equivalent to approved
         if (tr.Status__c.startsWith(CrossoverRequestController.STATUS_TXFER)) {
            approveRequests.add(tr);
         }
      } else if (Trigger.isUpdate) {
   	  
         Transfer_Request__c oldTr = Trigger.oldMap.get(tr.Id);
         // If the auto approved button is set, and the status hasn't changed, change the status 
         if ((oldTr.Auto_Approved__c == false) && (tr.Auto_Approved__c == true) &&
         	 ((tr.Status__c == CrossoverRequestController.STATUS_SUBMIT ) || (tr.Status__c == CrossoverRequestController.DSA_STATUS))) {
            tr.Status__c = CrossoverRequestController.STATUS_APPROVED;
            approveRequests.add(tr);
         } else if (tr.Status__c != oldTr.Status__c) {
            Boolean isDsaZsa = Utilities.checkDsaZsaProf(UserInfo.GetUserId());
         	if ((isDsaZsa && (oldTr.Status__c == CrossoverRequestController.DSA_STATUS)) ||
         	    (oldTr.Status__c != CrossoverRequestController.DSA_STATUS)) {
          	   if (tr.Status__c == CrossoverRequestController.STATUS_APPROVED) {
                  approveRequests.add(tr);
         	   } else if (tr.Status__c == 'Declined') {
         	      declinedRequests.add(tr);
         	   }
         	} else if (!isDsaZsa && (oldTr.Status__c == CrossoverRequestController.DSA_STATUS)) {
         	   // if this is not the correct profile, do not allow the users to change the status.
         	   tr.Status__c = oldTr.Status__c;
         	}
         }
   
      } // if (Trigger)
   } // for

   if (!approveRequests.isEmpty()) {
      TransferRequestCheckStatus.processApproved(approveRequests);
   } // if (requests.size)
   if (!declinedRequests.isEmpty()) {
      TransferRequestCheckStatus.processDeclined(declinedRequests);
   }

} // trigger TransferRequestCheckStatus