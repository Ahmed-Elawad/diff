/* Test methods for the LeadOnlineSetup class.
   
  History
  -------
  03/11/2016 Dan Carmen   Created
  
 */
@isTest
private class LeadOnlineSetupTest {

   static testMethod void testLeads() {
      ReferralObjectsSync.SKIP_SYNC=false;
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Acct');
      insert refAcct;
      
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Test Ctct1', Referral_Account__c=refAcct.Id);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Test Ctct1', Referral_Account__c=refAcct.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;
      
      refCtct1 = [Select Id, Name, Contact_Id__c, User_Name__c, UsernameDate__c from Referral_Contact__c where Id=:refCtct1.Id];
      refCtct2 = [Select Id, Name, Contact_Id__c, User_Name__c, UsernameDate__c from Referral_Contact__c where Id=:refCtct2.Id];
      
      System.debug('testLeads refCtct1='+refCtct1);
      System.assertEquals(true, refCtct1.Contact_Id__c != null);
      System.assertEquals(null,refCtct1.User_Name__c);
      System.assertEquals(null,refCtct1.UsernameDate__c);
      
      System.assertEquals(true, refCtct2.Contact_Id__c != null);
      System.assertEquals(null,refCtct2.User_Name__c);
      System.assertEquals(null,refCtct2.UsernameDate__c);
      
      Lead ld1 = new Lead(Company='Test1', FirstName='username1', LastName=refCtct1.Contact_Id__c, PostalCode='12345', Status=LeadOnlineSetup.STATUS_OPEN, Mthd_Lead_Rcvd__c=LeadOnlineSetup.CHECK_METHOD);
      Lead ld2 = new Lead(Company='Test2', FirstName='username2', LastName=refCtct2.Contact_Id__c, PostalCode='12345', Status=LeadOnlineSetup.STATUS_OPEN, Mthd_Lead_Rcvd__c=LeadOnlineSetup.CHECK_METHOD);
      Lead ld3 = new Lead(Company='Test3', FirstName='username3', LastName='BadId', PostalCode='12345', Status=LeadOnlineSetup.STATUS_OPEN, Mthd_Lead_Rcvd__c=LeadOnlineSetup.CHECK_METHOD);
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;
      
      ld1 = [Select Id, FirstName, Status, Comment__c from Lead where Id=:ld1.Id];
      System.assertEquals(LeadOnlineSetup.STATUS_CLOSE, ld1.Status);
      
      ld2 = [Select Id, FirstName, Status, Comment__c from Lead where Id=:ld2.Id];
      System.assertEquals(LeadOnlineSetup.STATUS_CLOSE, ld2.Status);

      ld3 = [Select Id, FirstName, Status, Comment__c from Lead where Id=:ld3.Id];
      System.assertEquals(LeadOnlineSetup.STATUS_ERROR, ld3.Status);
      System.assertEquals(LeadOnlineSetup.ERROR_MSG,ld3.Comment__c);
      
      refCtct1 = [Select Id, Name, Contact_Id__c, User_Name__c, UsernameDate__c from Referral_Contact__c where Id=:refCtct1.Id];
      refCtct2 = [Select Id, Name, Contact_Id__c, User_Name__c, UsernameDate__c from Referral_Contact__c where Id=:refCtct2.Id];

      System.assertEquals(ld1.FirstName,refCtct1.User_Name__c);
      System.assertEquals(Date.today(),refCtct1.UsernameDate__c);

      System.assertEquals(ld2.FirstName,refCtct2.User_Name__c);
      System.assertEquals(Date.today(),refCtct2.UsernameDate__c);

   } // testLeads
} // class LeadOnlineSetupTest