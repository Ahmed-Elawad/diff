/* Test methods for the AccountMatch class

 * History
 * -------
  07/27/2022 Dan Carmen           Created

*/
@isTest
public class AccountMatchTest {
    
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{AccountMatch.CLASSNAME});
      TriggerMethodsTest.saveSetupClasses();
   } // setupData

   static testMethod void testMatch1() {
      Account acct1 = new Account(Name='Account1', AccountNumber='13-1234');
      Account acct2 = new Account(Name='Account2', AccountNumber='13-1235');
      Account acct3 = new Account(Name='Account3', AccountNumber='13-1236');
      Account acct4 = new Account(Name='Account4', AccountNumber=null);
      Account acct5 = new Account(Name='Account5', AccountNumber=null);
      ZipCheckOwner.SKIP_TRIGGERS = true;
      insert new Account[]{acct1,acct2,acct3,acct4,acct5}; 
      
      AccountMatch__c am1 = new AccountMatch__c(Name='13-1234', AccountName__c='Account1', BisId__c='1234');
      AccountMatch__c am2 = new AccountMatch__c(Name='13-1235', AccountName__c='Account2', BisId__c='1235');
      AccountMatch__c am3 = new AccountMatch__c(Name='13-1236', AccountName__c='Account3', BisId__c='1236');
      AccountMatch__c am4 = new AccountMatch__c(Name='13-1237', AccountName__c='Account4', BisId__c='1237');
      AccountMatch__c am5 = new AccountMatch__c(Name='13-1238', AccountName__c='Account5', BisId__c='1238');
      insert new AccountMatch__c[]{am1,am2,am3,am4,am5};
          
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, AccountNumber, Bis_Id__c from Account]);
      Map<Id,AccountMatch__c> matchMap = new Map<Id,AccountMatch__c>([Select Id, Name, Account__c, BisId__c, Finished__c, LastMatchAttempt__c, NbrMatchAttempts__c from AccountMatch__c]);
       
      checkResults(acctMap.get(acct1.Id), matchMap.get(am1.Id), 1234, acct1.Id, 1, Date.today(), true);
      checkResults(acctMap.get(acct2.Id), matchMap.get(am2.Id), 1235, acct2.Id, 1, Date.today(), true);
      checkResults(acctMap.get(acct3.Id), matchMap.get(am3.Id), 1236, acct3.Id, 1, Date.today(), true);
      checkResults(acctMap.get(acct4.Id), matchMap.get(am4.Id), null, null, 1, Date.today(), false);
      checkResults(acctMap.get(acct5.Id), matchMap.get(am5.Id), null, null, 1, Date.today(), false);
       
      acct4.AccountNumber='13-1237';
      acct5.AccountNumber='13-1238';
      // including acct3 even though no update
      update new Account[]{acct3,acct4,acct5};
      
      acctMap = new Map<Id,Account>([Select Id, Name, AccountNumber, Bis_Id__c from Account]);
      matchMap = new Map<Id,AccountMatch__c>([Select Id, Name, Account__c, BisId__c, Finished__c, LastMatchAttempt__c, NbrMatchAttempts__c from AccountMatch__c]);
       
      checkResults(acctMap.get(acct4.Id), matchMap.get(am4.Id), 1237, acct4.Id, 2, Date.today(), true);
      checkResults(acctMap.get(acct5.Id), matchMap.get(am5.Id), 1238, acct5.Id, 2, Date.today(), true);

   } // testMatch1
    
   public static void checkResults(Account checkAcct, AccountMatch__c checkAm, Integer bisId, Id acctId, Integer nbrAttempts, Date lastAttempt, Boolean finished) {
      System.debug('checkResults checkAcct='+(checkAcct != null)+' checkAm='+(checkAm != null)+' bisId='+bisId+' acctId='+acctId+' nbrAttempts='+nbrAttempts+' finished='+finished);
      System.assertEquals(bisId,checkAcct.Bis_Id__c);
      System.assertEquals(acctId, checkAm.Account__c);
      System.assertEquals(nbrAttempts, checkAm.NbrMatchAttempts__c);
      System.assertEquals(lastAttempt, checkAm.LastMatchAttempt__c);
      System.assertEquals(finished, checkAm.Finished__c);
        
   } // checkResults
} // class AccountMatchTest