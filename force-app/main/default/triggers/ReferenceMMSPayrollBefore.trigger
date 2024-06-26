/*  
 * things to do before update
 *   
 * History
 * -------
 * 09/09/2013 Cindy Freeman		created
 * 
 */


trigger ReferenceMMSPayrollBefore on Reference_MMS_Payroll__c (before update) {
    UserHelper uh = new UserHelper();

    for ( Reference_MMS_Payroll__c newRef: Trigger.new) {
      // get the old record
      Reference_MMS_Payroll__c oldRef = (Reference_MMS_Payroll__c)Trigger.oldMap.get(newRef.Id);
      
      if (newRef.OwnerId <> oldRef.OwnerId) {
          // look to see if changed from queue to user then edit date
          Group oldOwner = uh.getQueueById(oldRef.OwnerId);             
          User newOwner = uh.getUserById(newRef.OwnerId);           
          if (oldOwner != null && newOwner != null)
		  {	  newRef.Client_Assigned_Date__c = System.date.today();	}
		  
	  } // if
	} // for trigger.new
	
}