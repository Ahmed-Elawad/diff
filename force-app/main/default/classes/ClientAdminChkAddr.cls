/* The the address types of the client admin record. Set the flags based on the 
   values in the field.
   
  History
  -------
  05/01/2009 Dan Carmen   Created
  09/19/2009 Dan Carmen   Add Premier client types.
  04/20/2011 Tom Muskatevc Added MMS client types.
  01/15/2013 Dan Carmen   Changed to use Contact Types field
  04/09/2013 Dan Carmen   Changed back to use Address Types until code can be updated
  11/13/2013 Dan Carmen   Change back to use Contact Types field
  
 */
public class ClientAdminChkAddr {
   public static void checkTypes(List<Client_Admin__c> allRecords) {
      for (Client_Admin__c ca : allRecords) {
         String contactTypes = (!String.isBlank(ca.Contact_Types__c) ? ca.Contact_Types__c : '');
         // set the flags
         ca.ADM401__c = (contactTypes.contains('401ADM'));
         ca.Envelopes__c = (contactTypes.contains('ENVELOPES'));
         ca.HRS125__c = (contactTypes.contains('HRS125'));
         ca.HRSADM__c = (contactTypes.contains('HRSADM'));
         ca.TAA__c = (contactTypes.contains('TIB') || contactTypes.contains('TLO'));
         ca.MMS__c = (contactTypes.contains('MMS'));


         ca.Premier_Cobra__c = (contactTypes.contains('CBR'));
         ca.Premier_Compliance__c = (contactTypes.contains('CI'));
         ca.Premier_EAP__c = (contactTypes.contains('EAP'));
         ca.Premier_Handbooks__c = (contactTypes.contains('HBK'));
         ca.Premier_Safety__c = (contactTypes.contains('SAFETY_LOSS'));
         ca.Premier_Survey__c = (contactTypes.contains('SURVEY'));
         ca.Premier_Mailing_Labels__c = (contactTypes.contains('COBRA_LETTER'));
         ca.Premier_Posters__c = (contactTypes.contains('PST'));
         ca.Premier_Seminars__c = (contactTypes.contains('SEM'));
         ca.Premier_Welcome_Letter__c = (contactTypes.contains('WELCOME_LETTER'));
        
         // reset the flags
         ca.Premier_Payroll__c = false;
         
         // in certain situations, look for the specific word, rather than the word itself.
         // this is to differentiate between PAYROLL-D (from client_address table) and PAYROLL (contact_info table).
         if (contactTypes.contains('PAYROLL')) {
         	Set<String> tokenSet = new Set<String>();
         	tokenSet.addAll(contactTypes.split(';'));
            //Set<String> tokens StringHelper.getTokens(ca.Contact_Types__c, ';', ',');
            ca.Premier_Payroll__c = tokenSet.contains('PAYROLL');
         
            // have to look for specific String value in the case of PAYROLL
            //for (String token : tokens) {
            //   if (token == 'PAYROLL') {
            //      ca.Premier_Payroll__c = true;
            //   }
            //} // for (String token)
         } // if (ca.Contact_Types__c)
         
         
      } // for (Client_Admin__c)
   } // checkTypes
   
} // class ClientAdminChkAddr