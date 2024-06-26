/**
 * Test Methods for the Tax Notice Email Handler class. uses Referral Source Email Handler class as a template
 
  History
  -------
  11/06/2017 Frank Lurz    Created
  
 */
@isTest
private class TaxNoticeEmailHandlerTest {

   static testMethod void testSettingSubmissionDate() {
   
      String TAX_EMAIL_MESSAGE='Tax Notice Submitted:';
      String ID_SEPARATOR=';';
      // create a Client & Field Submissionrecord
      Client_Field_Submission__c testCFS01 = new Client_Field_Submission__c (Business_Name__c = 'Test CFS01'
                                               ,Federal_ID_Number_Submitted__c = '123456789'
                                               ,Paychex_Client_ID__c = '88-1234ABCD'
                                               ,Government_Tax_Agency__c = 'SSA - Social Security Administration'
                                               ,Tax_Form__c =  'Department of Income/Withholding Tax' 
                                               ,Notice_Type__c = 'Overpayment Issue'
                                               ,Submitters_Name__c = 'Joe Test'
                                               ,Email__c = 'test@paychex.com'
                                               ,Phone_Number__c = '5855552150'
                                               ,Main_Contact__c = true
                                               );
      insert testCFS01;
      
      testCFS01.Submission_Done__c = TRUE; 
      update testCFS01;     
      //testCFS01.Submission_Date__c = System.now(); 
      //update testCFS01;     
      
      //refCtct = [Select Id, Contact_ID__c from Referral_Contact__c where Id = :refCtct.Id];
      //System.assertEquals(true, refCtct.Contact_Id__c != null);
      //System.debug('testSettingSubmissionDate refCtct.Contact_Id__c='+refCtct.Contact_Id__c);
      
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = 'Tax Notice Submitted:'+testCFS01.id;
      System.debug('testSettingSubmissionDate plainTextBody='+email.plainTextBody);
      email.fromAddress = 'flurz@paychex.com';
      email.subject='Tax Notice Submission'; 
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      TaxNoticeEmailHandler tneh = new TaxNoticeEmailHandler();

      System.debug('testSettingSubmissionDate before startTest');
      Test.startTest();
      tneh.handleInboundEmail(email, env);
      Test.stopTest();
      System.debug('testSettingSubmissionDate after stopTest');
      
      //refCtct = [Select Id, Contact_Id__c, User_Name__c from Referral_Contact__c where Id=:refCtct.Id];
      //System.assertEquals(true, refCtct.User_Name__c.contains(ReferralSourceEmailHandler.SETUP_ONLINE));
      //System.assertEquals(1,[select count() from Process_Log__c where Status__c=:Label.ProcessLogSuccess]);
        
   } // testSettingSubmissionDate
   

   
} // class TaxNoticeEmailHandlerTest