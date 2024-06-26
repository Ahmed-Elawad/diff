/* 
   A trigger to handle before delete operations.
   
  History
  -------
  01/25/2018  Frank Lurz   Created for Case #27425449
  
 */
trigger ClientSuccessManagerBeforeDelete on Client_Success_Manager__c (before delete) {

  for (Client_Success_Manager__c csm: trigger.old) {
      if (csm.Do_Not_Delete__c == true)
      csm.adderror('This Client Success Manager record cannot be Deleted. If you have any issues or questions with this, please contact your Salesforce.com Business Unit Representative.');
  } 
}