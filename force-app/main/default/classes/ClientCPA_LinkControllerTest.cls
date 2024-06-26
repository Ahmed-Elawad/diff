/* 
 * Test methods for the ClientCPA_LinkController class.
 *
 * History
 * -------
 * 11/22/2011 Dan Carmen        Created.
   10/29/2018 Dan Carmen   Increment API to version 44

 */
@isTest
private class ClientCPA_LinkControllerTest {

   static testMethod void testController() {
      // create an Account to search
      Account acct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514');
      insert acct;

      // create a referral to search
      Referral_Account__c ra = new Referral_Account__c(Name='ClientCPA_LinkControllerTest', Zip_Postal_Code__c = '14514');
      insert ra;
      Referral_Contact__c rc = new Referral_Contact__c(Referral_Account__c=ra.Id, Name='Test Referral0', Email__c='test0@testreferral.com', Phone__c='5551234567');
      insert rc;
      
   	  Client_CPA_Link__c cpl = new Client_CPA_Link__c();
      ClientCPA_LinkController cplc = new ClientCPA_LinkController(new ApexPages.StandardController(cpl));
      cplc.acctSearch.linkRecord.Payroll_Branch_Number__c = '0017';
      cplc.acctSearch.linkRecord.Payroll_Client_Number__c = 'DAN0';
      cplc.refSearch.linkRecord.Email__c = 'test0@testreferral.com';
      cplc.refSearch.linkRecord.Phone__c = '5551234567';
      cplc.refSearch.linkRecord.Referral_Account_Name__c = 'ClientCPA_LinkControllerTest';
      
      System.assertEquals(false,cplc.searchPerformed);
      System.assertEquals(null,cplc.searchRecords());
      System.assertEquals(true,cplc.searchPerformed);
   } // testController
   
} // ClientCPA_LinkControllerTest