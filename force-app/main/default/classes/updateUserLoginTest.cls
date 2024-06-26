@isTest
public class updateUserLoginTest {
  @testSetup
    public static void setup(){
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'Susmitha',
                               LastName = 'Somavarapu',
                               Email='testing@testing.com');
        insert c;
        
       
        
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
       
        
        User communityUsr = new User(
            UserName = c.email,
            FirstName = c.FirstName,
            LastName = c.LastName,
            Alias = 'alias',
            email = c.Email,
            ContactId = c.id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS'
        );
        
        insert communityUsr;
        
    }
     static testMethod void testUpdate() {
           Test.startTest();
      updateUserLogin accb = new updateUserLogin();
      Database.executeBatch(accb,1);
      Test.stopTest();
     }
     static testMethod void testScheduler() {
      TestHelper.testScheduler('TestupdateUserLogin',new updateUserLogin());
   } // testScheduler
}