/**
 * Test class for UserPwdExtension controller class
 *
 * History
 * --------
 * 07/06/2014 Cindy Freeman     created
   10/29/2018 Dan Carmen        Increment API to version 44
   12/17/2020 Dan Carmen        Update test so the users have different FederationIdentifiers 

 */
@isTest
private class UserPwdExtensionTest {

   static testMethod void runAsSandbox() {
      User runningUser = UserHelper.getRunningUser();
      // setup test users
      List <User> usrs = new List<User>();
      for (integer i = 0; i < 10; i++) 
      {
         User newU;
         newU = runningUser.clone(false);
            
         newU.FirstName = 'Test' + i;
         if (i > 4)
         {  newU.LastName = 'User NSS';
            newU.Job_Name__c = UserHelper.JOB_NSR;
         }
         else
         {  newU.LastName = 'User'; 
         }
         newU.Alias = 'Tester' + i;
         newU.Username = 'Tester' + i + '@sfdev.com';
         newU.CommunityNickname = 'Tester' + i;
         newU.FederationIdentifier='Tester'+i;
         newU.HR_Person_Id__c='Tester'+i;
         usrs.add(newU);     
      } // for (integer
      insert usrs;

      System.runAs(runningUser) {
         Test.setCurrentPage(Page.TestUserPwdReset);
         UserPwdExtension upe = new UserPwdExtension(new ApexPages.Standardcontroller(runningUser));
         System.assertEquals(null,upe.uzers);
         System.assertNotEquals(null,upe.getItems());
         upe.getWhoandWhere();
         // force to think it's a sandbox
         upe.orgBad = false;
         upe.uzers = 'testNsrs';
         Test.startTest();
         upe.resetPwd1();
         upe.resetPwd2();
         upe.resetPwd3();

         upe.uzers = 'testUsers';
         upe.resetPwd1();
         upe.resetPwd2();
         upe.resetPwd3();

         Test.stopTest();
      } // System.runAs
   } // runAsSandbox
   
   static testMethod void runAsSandboxBadUserType() {
      User runningUser = UserHelper.getRunningUser();
      Test.setCurrentPage(Page.TestUserPwdReset);
      UserPwdExtension upe = new UserPwdExtension(new ApexPages.Standardcontroller(runningUser));
      System.assertEquals(null,upe.uzers);
      System.assertNotEquals(null,upe.getItems());
      upe.getWhoandWhere();
      // force to think it's a sandbox
      upe.orgBad = false;

      upe.resetPwd1();
      System.assertEquals(1,ApexPages.getMessages().size());
      // error message is the same - won't add more
      upe.resetPwd2();
      System.assertEquals(1,ApexPages.getMessages().size());
      // error message is the same - won't add more
      upe.resetPwd3();
      System.assertEquals(1,ApexPages.getMessages().size());

   } // runAsSandboxBadUserType
   
   static testMethod void runAsProduction() {
      User runningUser = UserHelper.getRunningUser();
      Test.setCurrentPage(Page.TestUserPwdReset);
      UserPwdExtension upe = new UserPwdExtension(new ApexPages.Standardcontroller(runningUser));
      System.assertEquals(null,upe.uzers);
      System.assertNotEquals(null,upe.getItems());
      Boolean isRunningInProd = (Utilities.checkForProduction() == null);
      upe.getWhoandWhere();
      // force to think it's production
      upe.orgBad = true;
      upe.resetPwd1();
      System.assertEquals(1,ApexPages.getMessages().size());

      upe.resetPwd2();
      System.assertEquals(2,ApexPages.getMessages().size());

      upe.resetPwd3();
      System.assertEquals(3,ApexPages.getMessages().size());
      
   } // runAsProduction
   
} // class UserPwdExtensionTest