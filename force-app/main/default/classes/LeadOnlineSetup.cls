/* Handle Leads that come in for online.
   
  History
  -------
  03/11/2016 Dan Carmen   Created
  
 */
public with sharing class LeadOnlineSetup {
   
   public static String CHECK_METHOD=Label.LeadOnlineSetup;
   public static String STATUS_OPEN=Label.LeadOnlineOpenStatus;
   public static String STATUS_CLOSE=Label.LeadOnlineCloseStatus;
   public static String STATUS_ERROR=Label.LeadOnlineErrorStatus;
   
   public static Map<String,Lead> contactIdLeadMap = new Map<String,Lead>();
   
   public static Boolean checkOnlineSetup(Lead ld, Lead oldLd) {
      Boolean leadHandled = false;
      if (String.isNotBlank(ld.Mthd_Lead_Rcvd__c) && ld.Mthd_Lead_Rcvd__c == CHECK_METHOD
           && (String.isBlank(ld.Status) || ld.Status == STATUS_OPEN)
           && String.isNotBlank(ld.FirstName) && String.isNotBlank(ld.LastName)) {
         leadHandled = true;
         // first name is username, last name is contact id
         contactIdLeadMap.put(ld.LastName, ld);
      } // if (String.isNotBlank
      return leadHandled;
   } // checkOnlineSetup
   
   public static String ERROR_MSG='Match could not be found for the lead id';
   
   public static void handleOnlineSetupRecords() {
      if (!contactIdLeadMap.isEmpty()) {
         // search for existing contacts with the ids
         Referral_Contact__c[] refCtcts = [Select Id, Name, User_Name__c, Contact_ID__c from Referral_Contact__c where Contact_ID__c in :contactIdLeadMap.keySet()];
         for (Referral_Contact__c refCtct : refCtcts) {
            Lead ld = contactIdLeadMap.remove(refCtct.Contact_ID__c);
            if (ld != null) {
               refCtct.User_Name__c = ld.FirstName;
               refCtct.UserNameDate__c = Date.today();
               ld.Status = STATUS_CLOSE;
            }
         } // for (Referral_Contact__c refCtct
         // if anything is left in the map, mark as error
         for (Lead ld : contactIdLeadMap.values()) {
            ld.Status = STATUS_ERROR;
            ld.Comment__c = ERROR_MSG;
         }
         DmlHelper.performDML2(refCtcts, DmlHelper.DML_UPDATE, 'LeadOnlineSetup', 'handleOnlineSetupRecords', 'Update refCtcts', true);
      } // if (!contactIdLeadMap.isEmpty
   } // handleOnlineSetupRecords
   
} // class LeadOnlineSetup