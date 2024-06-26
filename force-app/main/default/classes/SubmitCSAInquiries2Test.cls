/* 
 * Test methods for the SubmitCSAInquiries2 class.
 *
 * History
 * -------
 * 10/04/2010 Dan Carmen        Created.
   12/15/2016 Dan Carmen      Modifications for submitting referral issues
   04/30/2018 Frank Lurz      Modifications for INTERNAL REFERRALS
 *
 */
@isTest
private class SubmitCSAInquiries2Test {

   /** Get a User record and verify that a contact record exists for the User.
    */
   private static User getUserVerifyContact(Boolean checkForContact) {
      User u = [Select Id, Sales_Org__c, Zone__c, HR_Person_Id__c
                      ,FirstName, LastName
                  from User 
                 where IsActive=true
                   and HR_Person_Id__c != null
                   and Profile.Name='Sales CSA'
                  limit 1 
                ];
                
                
      if (checkForContact) {
         // get the Paychex Inc SA account just in case
         Account acct = null;
         try {
            acct = [Select Id, Name from Account where name='Paychex Inc SA'];
         } catch (Exception e) {
            // if account doesn't exist, create it.
            acct = new Account(Name = 'Paychex Inc SA');
            insert acct; 
         } // try

         try {
            Contact c = [Select Id
                        from Contact
                       where HR_Person_Id__c = :u.HR_Person_Id__c
                         and Account.Name = 'Paychex Inc SA'
                      ];
         } catch (Exception e) {
            // contact not found - create a new one.
            Contact c = new Contact(AccountId = acct.Id
                                   ,FirstName = u.FirstName
                                   ,LastName = u.LastName
                                   ,HR_Person_Id__c = u.HR_Person_Id__c);
            insert c;
         } // try
      } // if (checkForContact)
      return u;
   } // getUserVerifyContact
   
   private static CSA_Inquiries_Setup__c createCsaInquirySetup(String requestType) {
      CSA_Inquiries_Setup__c cis = new CSA_Inquiries_Setup__c(Name = requestType);
      cis.Web_Request_Type__c = true;
      cis.Bonus_Expected__c = false;
      cis.Bonus_Received__c = true;
      cis.Tier_1_Bank__c = false;
      cis.Tier_2_Bank__c = true;
      cis.SOAR_Referral_Type__c = false;
      cis.Payroll_Spec_Branch_No__c = true;
      cis.Payroll_Specialist__c = false;
      cis.New_Units__c = true;
      cis.Original_Units__c = false;
      cis.Bonus_Effected__c = true;
      cis.Term_ed_Rep__c = false;
      cis.Unit_Type__c = true;
      cis.URL__c = false;
      cis.Sales_Rep__c = true;
      cis.Requestors_Role__c = false;
      cis.Request_Type__c = true;
      cis.Report_Type__c = false;
      cis.Report_Status__c = true;
      cis.Report_Name__c = false;
      cis.Referring_Rep__c = true;
      cis.Referral_Type__c = false;
      cis.Referral_Bank_Name__c = true;
      cis.Receiving_Rep_del__c = false;
      cis.Receiving_District__c = true;
      cis.Receiving_DSM_del__c = false;
      cis.RSM__c = true;
      cis.RECOGNITION_TYPE__c = false;
      cis.Question_Comment__c = true;
      cis.Prospect_Client_Name__c = false;
      cis.Product__c = true;
      cis.Processing_Branch__c = false;
      cis.Order_Number__c = true;
      cis.Moving_From_Rep_del__c = false;
      cis.Moving_From_District__c = true;
      cis.Moving_From_DSM_del__c = false;
      cis.Division__c = true;
      cis.District_Number__c = false;
      cis.DSM__c = true;
      cis.Comp_Plan_Type__c = false;
      cis.Commissionable_Month__c = false;
      cis.Client_Start_Date__c = false;
      cis.Client_Number__c = false;
      cis.Business_Justification__c = false;
      cis.Bonus_Type__c = false;
      cis.Bank_Level__c = false;
      cis.Affected_Unit__c = false;
      cis.Affected_Role__c = false;
      cis.Affected_Revenue__c = false;
      cis.Affected_Commission__c = false;
      cis.Additional_URLs_Affected__c = false;
      cis.Subject__c  = false;

      insert cis;
      return cis;
   } // createCsaInquirySetup
   
   /** Test for a User record without a Contact record.
    */
   static testMethod void testUserNoContact() {
      User u = getUserVerifyContact(false);
      u.HR_Person_Id__c = 'BadIdNbr';
      update u;
      System.runAs(u) {
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();

         // should be an error now.
         System.assertEquals(1,ApexPages.getMessages().size());
         String msgDetail = ApexPages.getMessages().get(0).getDetail();
         System.assertEquals(true,msgDetail.contains('A matching contact record could not be found'));
      } // System.runAs
   } // testUserNoContact
   
   /** Test for the Request type not found.
    */
   static testMethod void testRequestNotFound() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         createCsaInquirySetup('Test Request1');
         createCsaInquirySetup('Test Request2');
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         sci.cSAInq.Request_Type__c = 'Test Request3';
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         sci.setRequestType();
         // should be an error now.
         System.assertEquals(1,ApexPages.getMessages().size());
         String msgDetail = ApexPages.getMessages().get(0).getDetail();
         System.assertEquals(true,msgDetail.contains('Could not find a record for'));
         System.assertEquals(false,sci.setupFound);
         
         sci.cancel();
      } // System.runAs
      
   } // testRequestNotFound
    
   /** Test for a standard case where everything is working correctly.
    */
   static testMethod void testDefaultCase() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         createCsaInquirySetup('Test Request1');
         createCsaInquirySetup('Test Request2');
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         sci.cSAInq.Request_Type__c = 'Test Request2';
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         sci.setRequestType();
         // should still be no errors
         System.assertEquals(0,ApexPages.getMessages().size());
         System.assertEquals(true,sci.setupFound);
         
         sci.cSAInq.Request_Type__c = 'BONUS DISCREPANCY';
         sci.submit();
      } // System.runAs
      
   } // testDefaultCase
    
   /** Test for a standard case where everything is working correctly.
    */
   static testMethod void testDefaultCase2() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         createCsaInquirySetup('Test Request2');
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         sci.cSAInq.Request_Type__c = 'Test Request2';
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         sci.setRequestType();
         // should still be no errors
         System.assertEquals(0,ApexPages.getMessages().size());
         System.assertEquals(true,sci.setupFound);
         
         sci.cSAInq.Request_Type__c = 'PAYROLL UNIT DISCREPANCY';
         sci.submit();
      } // System.runAs
      
   } // testDefaultCase2
    
   /** Test for a standard case where everything is working correctly.
    */
   static testMethod void testDefaultCase3() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         createCsaInquirySetup('Test Request2');
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         sci.cSAInq.Request_Type__c = 'Test Request2';
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         sci.setRequestType();
         // should still be no errors
         System.assertEquals(0,ApexPages.getMessages().size());
         System.assertEquals(true,sci.setupFound);
         
         sci.cSAInq.Request_Type__c = 'REPORT';
         sci.submit();
      } // System.runAs
      
   } // testDefaultCase3
    
   /** Test for a standard case where everything is working correctly.
    */
   static testMethod void testDefaultCase4() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         createCsaInquirySetup('Test Request2');
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         sci.cSAInq.Request_Type__c = 'Test Request2';
         // verify no errors
         System.assertEquals(0,ApexPages.getMessages().size());

         sci.setRequestType();
         // should still be no errors
         System.assertEquals(0,ApexPages.getMessages().size());
         System.assertEquals(true,sci.setupFound);
         
         sci.cSAInq.Request_Type__c = 'REPORT';
         sci.save();
      } // System.runAs
      
   } // testDefaultCase4
    
   /** Test the case fields.
    */
   static testMethod void testCaseFields() {
      User u = getUserVerifyContact(true);
      System.runAs(u) {
         SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
         
         sci.cSAInq.Report_Status__c = 'Test Status';
         sci.cSAInq.Division__c = 'Test Div';
         testRequestType(sci,'REPORT',' Test Status : Test Div ');
         
         sci.cSAInq.RECOGNITION_Type__c = 'Test Recognition';
         testRequestType(sci,'RECOGNITION',' Test Recognition : '+ u.Sales_Org__c+' ');

         testRequestType(sci,'COMM/AUDIT',' '+ u.Zone__c + ' : '+ u.Sales_Org__c+' ');

         testRequestType(sci,'STAT DISCREPANCY',' '+ u.Sales_Org__c+' ');

         testRequestType(sci,'COMMISSION SYSTEM ACCESS',' '+ u.Zone__c + ' : '+ u.Sales_Org__c+' ');
         
      } // System.runAs
   } // testCaseFields
   
   private static boolean testRequestType(SubmitCSAInquiries2 sci, String requestType, String description) {
      sci.cSAInq.Request_Type__c = requestType;
      sci.setCaseFields();
      System.assertEquals('CSA Submit Request',sci.c.origin);
      System.assertEquals('CSA Inquiry',sci.c.Type);
      System.assertEquals(requestType,sci.c.subject);
      
      return true;
   } // testRequestType
   
   static testMethod void testFollowUpDate() {
      SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
      Date checkDate = Date.newInstance(2010,1,1);
      Date compareDate = Date.newInstance(2010,1,18);
      System.assertEquals(compareDate,sci.getFollowUpDate('BONUS DISCREPANCY', checkDate));
      
      checkDate = Date.newInstance(2010,1,19);
      compareDate = Date.newInstance(2010,2,18);
      System.assertEquals(compareDate,sci.getFollowUpDate('PAYROLL UNIT DISCREPANCY', checkDate));
      
      checkDate = Date.newInstance(2010,10,1);
      compareDate = Date.newInstance(2010,10,5);
      
      //System.assertEquals(compareDate,secondDay);
      System.assertEquals(compareDate,sci.getFollowUpDate('REPORT', checkDate));
      
   } // testFollowUpDate
       static testMethod void testSplitOpportunity()
    {
        SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
        sci.CSAInq.Request_Type__c = 'SPLIT OPPORTUNITY';
        sci.setRequestType();
        sci.getProducts();
        sci.submit();
        System.assertEquals(true,sci.split);
        System.assertEquals(sci.CSAInq.Request_Type__c,sci.c.subject);
    }
    
       static testMethod void testInternalReferrals()
    {
        SubmitCSAInquiries2 sci = new SubmitCSAInquiries2();
        sci.CSAInq.Request_Type__c = 'INTERNAL REFERRALS';
        sci.setRequestType();
        sci.submit();
        System.assertEquals(sci.CSAInq.Request_Type__c,sci.c.subject);
    }
    
} // class SubmitCSAInquiries2Test