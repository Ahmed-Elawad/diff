/*  
 * Requirements: https://wiki.paychex.com/display/CP/APR0108928+-+CPA+Contact+Me+Form+Automation
 * 
 * The CPA/accountant channel is requesting to automate the process for the “contact me” form 
 * on https://www.paychex.com/accounting-professionals. This will provide a consistent, 
 * increased speed of sales representative awareness, as well as a formal, trackable path of activity, 
 * potential referral, and potential sale.
 * 
 * Associated Email Service: Accountant Referral Partner
 * 
  email.tst,sample.tst,paychex.test

 * 
 * History
 * --------
   01/29/2021 Manmeet Vaseer    Created.
   12/21/2022 Dan Carmen        Clean up code, use SF Duplicate Management.
   03/11/2024 Dan Carmen        Add ability to mark a record as purge since it seems to be not valid.

 */
global without sharing class AccountantReferralPartnerEmailHandler implements Messaging.InboundEmailHandler {

    public PartnerReferral__c partRef;
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        partRef = new PartnerReferral__c();
        partRef.Source__c = 'CPA';
        partRef.Comments__c = 'Pending';
        partRef.Processed__c = false;

        try {
            String emailBody = email.plainTextBody != null ? normalizeXML(email.plainTextBody) : '';
            if(emailBody.contains('<contactme>') && emailBody.contains('</contactme>'))	{
                String xmlPayload = emailBody.substringBetween('<contactme>','</contactme>');
                if(xmlPayload != null && xmlPayload.length() > 0)	{
                    ContactMePayload cmPayload = parsePayload(xmlPayload, partRef);
                    if(cmPayLoad.formUrl != null && cmPayLoad.formUrl.length() > 0)	{
                        partRef.Company__c = cmPayload.companyName;
                        partRef.FirstName__c = cmPayload.firstName;
                        partRef.LastName__c = cmPayload.lastName;
                        partRef.Email__c = cmPayload.email;
                        partRef.Phone__c = cmPayload.phone;
                        partRef.ZipPostalCode__c = cmPayload.zipCode;
                        checkForTest(partRef);
                        if (!partRef.PurgeRecord__c) {
                           AccountantReferralPartnerHelper arph = new AccountantReferralPartnerHelper(cmPayload, partRef);
                           boolean success = arph.processReferrals();
                           if(success)	{
                               partRef.Comments__c = 'Successful';
                               partRef.Processed__c = true;
                           }
                        }
                    }
                    else {
                    	partRef.Comments__c = 'Invalid Form URL. Form URL is required.';
                    }
                }
                else {
                    partRef.Comments__c = 'ContactMe Payload is Empty.';
                }
            }
            else {
                partRef.Comments__c = 'Invalid ContactMe XML message in the email body: ' + emailBody;
            }
        }
        catch(Exception e)	{
            partRef.Comments__c = 'Error: ' + e + ', Stack Trace: ' + e.getStackTraceString();
        }
        
        insert partRef;
        return result;
    }
    
   public static String[] testFlds = Label.AccountantReferralPartner_Flds.split(',');
   public static String[] testValues = Label.AccountantReferralPartner_Values.split(',');
    
   public static void checkForTest(PartnerReferral__c partRef) {
      for (String fldName : testFlds) {
         try {
            String fldValue = String.valueOf(partRef.get(fldName));     
            if (String.isNotBlank(fldValue)) {
               for (String testVal : testValues) {
                  if (fldValue.contains(testVal)) {
                     partRef.PurgeRecord__c = true;
                     partRef.Comments__c = 'PurgeRecord marked true due to '+fldName+' containing '+testVal;
                     partRef.Processed__c = true;
                     StringHelper.addToProcessNotes(partRef,'PurgeRecord marked true due to '+fldName+' containing '+testVal);
                     break;
                  }
               } // for (String testVal
            } // if (String.isNotBlank
         } catch (Exception e) {
            System.debug('checkForTest e='+e);
         }
      }
   } // checkForTest

    ContactMePayload parsePayload(String xmlPayload, PartnerReferral__c partRef)	{
        xmlPayload = '<contactme>' + xmlPayload + '</contactme>';
        partRef.description__c = xmlPayload;
        
        xmlHelper xmlh = new xmlHelper('AccountantReferralPartnerEmailHandler.ContactMePayload',xmlPayload);
        ContactMePayload payload = (ContactMePayload) xmlh.xmlObject;
        if(payload != null)	{
            String xmlPOI = xmlPayload.substringBetween('<productsofinterest>','</productsofinterest>');
            populateProductsOfInterest(xmlPOI, payload);
            System.debug('ContactMePayload: ' + payload);
            return payload;
        }
        else {
            partRef.Comments__c = 'Unable to create ContactMePayload object.';    
        }
        
        return null;
    }
    
    void populateProductsOfInterest(String xmlPOI, ContactMePayload payload)	{
        if(xmlPOI != null)	{
            List<String> lst = xmlPOI.split('<item>');
            payload.productsOfInterest = new List<String>();
            for(String v : lst)	{
                if(!String.isBlank(v)) payload.productsOfInterest.add(v.remove('</item>').trim());
            }
        }
    }
    

    public class ContactMePayload {
        public String companyName;
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
        public String zipCode;
        public List<String> productsOfInterest;
        public String comments;
        public String formUrl;
    }
 
    public static String normalizeXML(String xml)	{
        if(xml != null && xml.length() > 0)	{
            xml = xml.replaceALL('>[\\s|\\n]+?<','><'); //remove while spaces between the xml tags
            String convertedXML = xml;
            
            String[] regExps = new String[]{'><(.*?)>', '</(.*?)><'};
            for(String regExp : regExps)	{
                Pattern p = Pattern.compile(regExp);      
                Matcher m = p.matcher(xml);
                while (m.find()) {         
                    String tagName = m.group(1).remove('/');
                    convertedXML = convertedXML.replaceAll(tagName, tagName.toLowerCase());
                    //converted = m.replaceAll('<' + m.group(1).toLowerCase() + '>');
                }
            }
            
            return convertedXML;
        }
        
        return '';
    }
    
    
} // class AccountantReferralPartnerEmailHandler