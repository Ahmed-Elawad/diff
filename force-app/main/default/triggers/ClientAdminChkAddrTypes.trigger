/* 
   Check if the address types field is changed. If it changes, reset the flags
   on the object. 
   
  History
  -------
  05/01/2009 Dan Carmen   Created
  01/15/2013 Dan Carmen   Changed to use Contact Types field
  04/09/2013 Dan Carmen   Changed back to use Address Types until code can be updated
   
 */
trigger ClientAdminChkAddrTypes on Client_Admin__c (before insert, before update) {
   List<Client_Admin__c> checkRecords = new List<Client_Admin__c>();
   for ( Client_Admin__c newa: Trigger.new) {
   	  if (Trigger.isInsert) {
   	  	 checkRecords.add(newa);
   	  } else if (Trigger.isUpdate) {
         Client_Admin__c olda = Trigger.oldMap.get(newa.id);
         if (newa.Contact_Types__c != olda.Contact_Types__c) {
         	 checkRecords.add(newa);
         }
   	  } // if (Trigger)
   } // for
   
   // only call the next procedure if records were changed.
   if (!checkRecords.isEmpty()) {
   	  ClientAdminChkAddr.checkTypes(checkRecords);
   }
} // trigger ClientAdminChkAddrTypes