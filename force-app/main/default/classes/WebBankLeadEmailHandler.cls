/*
 *  This class pulls in the inbound email message for a bank lead, 
 *  cleans it, and sends it to the WebBankLeadHelper class for processing.  
 *
 * History
 * --------
 * 10/25/2013  Justin Stouffer      created 
   11/17/2015  Dan Carmen           Modified to use PartnerReferral__c object
   02/01/2016  Dan Carmen           Be able to account for multiple tags
   07/06/2020  Jacob Hinds          Added without sharing per PMD
   04/13/2021  Pujitha Madamanchi   Populate campaign lookup on Partner Referral
   04/28/2021  Pujitha Madamanchi   Add clover tag
   08/05/2021  Pujitha Madamanchi   Add MID tag
   11/25/2021  Pujitha Madamanchi   APR0127496: Citibank tags
   04/04/2022  Pujitha Madamanchi   Populate Area/Division
   09/06/2022   Pujitha Madamanchi  APR0141064 : Additional Products Tag
   05/30/2024   Pujitha Madamanchi  New bank tags

 */
 
global without sharing class WebBankLeadEmailHandler implements Messaging.InboundEmailHandler {
 
   //public static String MSG_START='<node>';
   //public static String MSG_END='</node>';
   
   public static String[] TAG_OPTIONS = Label.BankTagOptions.split(';');

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                          Messaging.InboundEnvelope env) {
 
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    
      String myPlainText = '';
      String msgBody = email.plainTextBody;

      // be able to account for multiple tags
      for (String tagOption : TAG_OPTIONS) {
         String startTag = '<'+tagOption+'>';
         String endTag = '</'+tagOption+'>';
         Integer msgStart = msgBody.indexOf(startTag);
         // look for the closing node tag 
         Integer msgEnd = msgBody.indexOf(endTag);
         if (msgStart >= 0 && msgEnd > 0) {
            //myPlainText = myPlainText.substring(0, idx - 1);
            myPlainText = msgBody.substring(msgStart, msgEnd + endTag.length());
            System.debug('handleInboundEmail tagOption='+tagOption+' myPlainText='+myPlainText);
            break;
         } // if (msgStart >= 0
      } // for (String tagOption
    
      //List<WebBankleadHelper.bankLead> blList = new List<WebBankleadHelper.bankLead>();
      //PartnerReferral__c[] incomingReferrals = new PartnerReferral__c[]{};
      PartnerReferral__c incomingReferral = null;
    
      if (String.isBlank(myPlainText)) {  
         Throw new BankEmailException('Empty Email Body');
      } else {   
         try {
            xmlHelper blHelper = new xmlHelper('WebBankLeadHelper.banklead',myPlainText);
            WebBankleadHelper.bankLead bl = new WebBankleadHelper.bankLead();
            System.debug('handleInboundEmail before parsing the bankLead object');
            bl = (WebBankLeadHelper.bankLead)blHelper.xmlObject;
            Boolean hasBasicInformation = bl.hasBasicInformation();
            System.debug('handleInboundEmail after parsing the bankLead object hasBasicInformation='+hasBasicInformation);
            if (hasBasicInformation) {
               incomingReferral = createReferral(bl);
            }
            //incomingReferrals.add(incomingReferral);
            // check attribute on the bank lead to determine if to use the legacy or new process
            //blList.add(bl);
         } catch(Exception ex) {
            String msg = 'Unable to Parse XML' + (Test.isRunningTest() || String.isNotBlank(Utilities.checkForProduction()) ? ': '+ex.getMessage()+'; '+ex.getStackTraceString() : '');
            Throw new BankEmailException(msg);   
         } // try
      } // if (String.isBlank(myPlainText
      
      if (incomingReferral == null) {
         String msg = 'Unable to Parse XML' + (Test.isRunningTest() || String.isNotBlank(Utilities.checkForProduction()) ? ': bad message data' : '');
         Throw new BankEmailException(msg);
      }
 
      System.debug('handleInboundEmail incomingReferral is null='+(incomingReferral == null));
      if (incomingReferral != null) {
         try {
            insert incomingReferral;
            System.debug('handleInboundEmail after inserting the incomingReferral');
            //incomingReferrals.clear();
            // save the original email as an attachment
            Attachment attach = new Attachment(ParentId = incomingReferral.Id, Name='originalEmailBody.txt'
                               ,Body=Blob.valueOf(email.plainTextBody), ContentType='text');
            insert attach;
         } catch (Exception ex) {
            String msg = 'Unable to Process Lead' + (Test.isRunningTest()  || String.isNotBlank(Utilities.checkForProduction()) ? ': '+ex.getMessage()+': '+ex.getStackTraceString() : '');
            Throw new BankEmailException(msg); 
         }
      } // if (!incomingReferrals
 
 /*
      if (!blList.isEmpty()) {   
         Try {
            WebBankLeadHelper.processBankLead(blList);
         } catch(Exception ex) {
            String msg = 'Unable to Process Lead' + (Test.isRunningTest() ? ': '+ex.getMessage()+': '+ex.getStackTraceString() : '');
            Throw new BankEmailException(msg); 
         } // try 
      } // if (!blList.isEmpty
*/    
      return result;
       
   } //handleInboundEmail
  
   // this exception is used to throw missing attachment messages
   public class BankEmailException extends Exception {}
         
   public static Integer COMMENTS_LENGTH=PartnerReferral__c.Comments__c.getDescribe().getLength();

   // save to a partner referral record to preserve the original state.
   public static PartnerReferral__c createReferral(WebBankLeadHelper.BankLead bankLead) {
      PartnerReferral__c partRef = new PartnerReferral__c();
      partRef.EmpFirstName__c = bankLead.refEmployeeFirstName;
      partRef.EmpLastName__c = bankLead.refEmployeeLastName;
      // set a default employee name if none passed in
      if (String.isBlank(partRef.EmpFirstName__c) && String.isBlank(partRef.EmpLastName__c)) {
         partRef.EmpFirstName__c = 'Default';
         partRef.EmpLastName__c = 'PartnerContact';
      }
      partRef.EmpPhone__c = bankLead.refEmployeePhone;
      partRef.EmpEmail__c = bankLead.refEmployeeEmail;
      
      partRef.FirstName__c = bankLead.firstName;
      partRef.LastName__c = bankLead.lastName;
      if (String.isBlank(partRef.FirstName__c) && !String.isBlank(partRef.LastName__c) && partRef.LastName__c.containsWhitespace()) {
          partRef.FirstName__c = partRef.LastName__c.normalizeSpace().substringBefore(' ');
          partRef.LastName__c = partRef.LastName__c.normalizeSpace().substringAfter(' ');
      }        
      partRef.Title__c = bankLead.title;
      partRef.Email__c = bankLead.email;
      partRef.Phone__c = bankLead.phone;
      
      partRef.Company__c = bankLead.company;
      partRef.StreetAddress__c = bankLead.street;
      partRef.City__c = bankLead.city;
      partRef.State__c = bankLead.state;
      partRef.ZipPostalCode__c = bankLead.zip;
      partRef.NumberOfEmployees__c = bankLead.NumOfEmployees;
      
      partRef.PromoCode__c = bankLead.promocode;
      partRef.Comments__c = (String.isNotBlank(bankLead.comments) ? bankLead.comments.left(COMMENTS_LENGTH) : null);
      
      partRef.CampaignId__c = bankLead.campaignId;
      partRef.Campaign__c = bankLead.campaignId; //APR0115879
      partRef.Additional_Partner_Info__c = (String.isNotBlank(bankLead.profile) ? bankLead.profile.left(127) : null);
      //Populate Area/Division to the same fields if Additional Referring Name is blank. They would like to reuse these fields for finance reproting.
      partRef.AdditionalReferringName__c = bankLead.AdditionalReferringName;
      partRef.AdditionalReferringEmpId__c = bankLead.AdditionalReferringEmpId;
      partRef.AdditionalReferringEmail__c = bankLead.refCCEmail;
      partRef.EmployeeId__c = bankLead.EmployeeID;
      partRef.SalesRepFirstName__c = bankLead.salesRepFirstName;
      partRef.SalesRepLastName__c = bankLead.salesRepLastName;
      
      partRef.PartnerName__c = bankLead.bankName;
      partRef.BranchName__c = bankLead.branchName;
      partRef.BranchNumber__c = bankLead.branchNumber;
      partRef.BranchZip__c = bankLead.branchZip;
      
      partRef.Expressed_Interest__c = bankLead.expressedInterest;
      partRef.Obtained_Consent__c = bankLead.obtainedConsent;
      partRef.Spoken_to_a_Paychex_Rep__c = bankLead.spokenToPaychexRep;
      partRef.Scheduled_an_Appointment__c = bankLead.scheduledAppointment;
      
      partRef.Area__c = bankLead.Area;
      partRef.Division__c = bankLead.Division;
      partRef.Employee_Department_Cost_Center_Number__c = bankLead.SynEEDeptCostCenter;
      partRef.Employee_Line_of_Business__c = bankLead.SynLineofBusiness;
      partRef.Bundled_Package__c = bankLead.referralBundle;
      
      Boolean isPayroll = (bankLead.payroll == 'TRUE');
      Boolean is401k = (bankLead.x401k == 'TRUE');
      Boolean isClover = (bankLead.Clover == 'TRUE');
      // default to payroll if neither is selected.
      if (!isPayroll && !is401k) {
         isPayroll = true;
      }

      //09/06/2022   Pujitha Madamanchi  APR0141064 : Additional Products Tag
      partRef.Products__c = (isPayroll ? PartnerWrapper.PROD_INTEREST_PAYROLL : '')
                           +(is401k ? (isPayroll ? ';' : '') + PartnerWrapper.PROD_INTEREST_401k : '')
                           +(isClover ? ((isPayroll || is401k) ? ';' : '') + PartnerWrapper.PROD_INTEREST_Clover : '')
                           +(bankLead.additionalProducts!=null ? ((isPayroll || is401k || isClover) ? ';' : '') + bankLead.additionalProducts : '');
      partRef.Line_Of_Business__c = bankLead.lineOfBusiness;
      // default this for the email entry
      partRef.ReferralType__c = WebBankLeadHelper.TIER_1;
      partRef.ReferralEntry__c = Label.RefEntry_EmailServ;
      partRef.ProcessReferral__c = true;
      partRef.MID__c = bankLead.MID;
      partRef.Vendor_ID__c = (String.isNotBlank(bankLead.VendorId) ? Integer.valueOf(bankLead.VendorId): null);
       
      partRef.Source__c='WebBankLeadEmailHandler';

  
      if(bankLead.CustConsent!= null){
          partRef.Obtained_Consent__c= bankLead.CustConsent=='True'?'Yes':'No';
      }   
      partRef.Consent_Obtained_By__c = bankLead.ConsentObtainedBy;
      partRef.Consent_to_Text_Date__c = bankLead.ConsentObtainedDateSubmitted;
      partRef.Consent_Obtained_Method__c = bankLead.CustConsentContactMethod;
      partRef.Consent_Obtained_From__c = bankLead.CustomerConsentName!= null? bankLead.CustomerConsentName: (bankLead.firstName+' '+bankLead.LastName);
      partRef.Consent_Obtained_Phone__c = bankLead.CustConsentPhone;   
      partRef.Consent_Obtained_Date__c = bankLead.CustConsentDateObtained;


      return partRef;
   } // createReferral 
   
} // class WebBankLeadEmailHandler

/* XML Should look like:


<node>
<bankName>Bank of Bob</bankName>
<branchNumber>12</branchNumber>
<branchName>Robert</branchName>
<branchZip>14512</branchZip>
<refEmployeeFirstName>Jimmy</refEmployeeFirstName>
<refEmployeeLastName>Dean</refEmployeeLastName>
<refEmployeePhone>5851239876</refEmployeePhone>
<refEmployeeEmail>dcarmen@paychex.com</refEmployeeEmail>
<salesRepFirstName></salesRepFirstName>
<salesRepLastName></salesRepLastName>
<firstName>Tina</firstName>
<lastName>Taylor</lastName>
<company>Taylor Tuxes</company>
<email>tina.taylor@taylortuxes.com</email>
<phone>5856879564</phone>
<street>444 4th Ave</street>
<city>Rochester</city>
<state>NY</state>
<zip>14512</zip>
<AdditionalReferringName></AdditionalReferringName>
<AdditionalReferringEmpId></AdditionalReferringEmpId>
<EmployeeID></EmployeeID>
<promocode>YAY</promocode>
<title>Tailor</title>
<NumOfEmployees>7</NumOfEmployees>
<comments>These are comments. I hope you enjoy them!</comments>
</node> 
The information contained

*/