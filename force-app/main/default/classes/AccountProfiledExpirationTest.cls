/* Test methods for AccountProfiledExpiration class
   
  History
  -------
  12/15/2016 Jacob Hinds   Created
 */
@isTest
private class AccountProfiledExpirationTest {

    static testMethod void testExpiration() {
        Account acct1 = new Account(Name='Test Acct1', Profiled__c = true, Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Account acct2 = new Account(Name='Test Acct2', Profiled__c = true, Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Account acct3 = new Account(Name='Test Acct3', Profiled__c = true, Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Account acct4 = new Account(Name='Test Acct4', Profiled__c = true, Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Account acct5 = new Account(Name='Test Acct5', Profiled__c = true, Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
        insert accts;
        
        AccountProfiledExpiration ape = new AccountProfiledExpiration();
        Test.startTest();
        Database.executeBatch(ape,5);
        Test.stopTest();
        
        for(Account a:[SELECT Id,Profiled__c,Profiled_Date__c,Profiled_Expiration_Date__c FROM Account WHERE Id in:accts]){
        	system.assertEquals(false,a.Profiled__c);
        	system.assertEquals(null,a.Profiled_Date__c);
        	system.assertEquals(null,a.Profiled_Expiration_Date__c);
        }
    }
}