/* 
 * Check on the types for the contacts
 *
 * History
 * -------
   01/28/2016 Dan Carmen      Created
   12/13/2017 Dan Carmen      Changed the Payroll Contact criteria
   07/18/2019 Dan Carmen      Add criteria for Business Owner

 */
public with sharing class ContactCheckType {

   public static void checkType(Contact newCtct, Contact oldCtct) {
      // if the field changes
      Boolean checkContactTypes = (oldCtct == null || (oldCtct != null && newCtct.Contact_Types__c != oldCtct.Contact_Types__c));
      System.debug('checkType ctct='+newCtct.LastName+' checkContactTypes='+checkContactTypes);
      if (checkContactTypes) {
         String contactTypes =  (String.isNotBlank(newCtct.Contact_Types__c) ? newCtct.Contact_Types__c.toUpperCase() : '');
         //System.debug('checkType contactTypes='+contactTypes);
         newCtct.PayrollContact__c = contactTypes.contains('PAY');
         //System.debug('checkType ctct='+newCtct.LastName+' PayrollContact__c='+newCtct.PayrollContact__c+' Contact_Types__c='+newCtct.Contact_Types__c);
         // in certain situations, look for the specific word, rather than the word itself.
         // this is to differentiate between PAYROLL-D (from client_address table) and PAYROLL (contact_info table).
         //if (contactTypes.contains('PAYROLL')) {
         //   Set<String> tokenSet = new Set<String>();
         //   tokenSet.addAll(contactTypes.split(';'));
            //System.debug('checkType tokenSet='+tokenSet);
         //   newCtct.PayrollContact__c = tokenSet.contains('PAYROLL');
         //} // if (contactTypes
         
      } // if (oldCtct == null ||
      
      if (String.isNotBlank(newCtct.Title) && (oldCtct == null || (oldCtct != null && newCtct.Title != oldCtct.Title))) {
         if (newCtct.Title.containsIgnoreCase('Owner')) {
            newCtct.Business_Owner__c = true;
         }
      }
      
      if (String.isNotBlank(newCtct.Willing_to_Be_a_Reference_TAA__c) && (oldCtct == null || (newCtct.Willing_to_Be_a_Reference_TAA__c != oldCtct.Willing_to_Be_a_Reference_TAA__c))) {
         newCtct.TAA_Reference_Date__c = Date.today();
      }
      
      // mark the date wehn enrolled.
      if (newCtct.AICPA_Enrolled__c == 'Y' && (oldCtct == null || (newCtct.AICPA_Enrolled__c != oldCtct.AICPA_Enrolled__c))) {
         newCtct.AICPA_Enrolled_Date__c = Date.today();
         newCtct.AICPA_Original_Type__c = newCtct.Referral_Type__c;
      }
      
      // mark the date when changed to true.
      if (newCtct.AKC_Registered__c && (oldCtct == null || (oldCtct.AKC_Registered__c == false))) {
         newCtct.Date_AKC_Registered__c = Date.today();
      }
   } // checkType
} // class ContactCheckType