/* Test methods for the AccountTeamMemberBatch class
   
  History
  -------
  09/11/2017 Dan Carmen       Created
  05/03/2019 Dan Carmen       Changes for tests failing
  
 */
@isTest
private class AccountTeamMemberBatchTest {

   @testSetup 
   static void setupTestData(){
      AccountTeamMemberBatch.CHECK_ACTIVE_FLAG = false;
      
      // create custom settings
      HoldOutExpirationMethodsTest.populateSetting();
   } // setupTestData

   static testMethod void testBatch() {
      
      // select some users
      User[] users = [Select Id, Name from User where Sales_Org__c = :UserHelper.SO_CORE and IsActive=true limit 2];
      // create accounts
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<150; cnt++) {
         accts.add(new Account(Name='Account '+cnt, OwnerId=users[0].Id));
      }
      // add account with hold outs
      for (Integer cnt=150; cnt<200; cnt++) {
         accts.add(new Account(Name='Account '+cnt, OwnerId=users[1].Id, Hold_Out__c=true));
      }
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      AccountTeamMember[] atms = new AccountTeamMember[]{};
      // create team members
      for (Account acct : accts) {
         atms.add(new AccountTeamMember(AccountId=acct.Id, UserId=users[1].Id, TeamMemberRole='Internal Referral'));
      }
      insert atms;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      
      AccountTeamMemberBatch atmb = new AccountTeamMemberBatch();
      Test.startTest();
      database.executeBatch(atmb, 250);
      Test.stopTest();
      
      // should only be 50 team members left
      System.assertEquals(50, [select count() from AccountTeamMember]);
   } // testBatch
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testAccountTeamMemberBatch', new AccountTeamMemberBatch());
   } // testScheduler
   
} // class AccountTeamMemberBatchTest