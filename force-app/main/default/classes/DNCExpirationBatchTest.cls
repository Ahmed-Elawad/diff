/* 
  Clear DNC on records that have an expiration of today or older.
   
  History
  -------
   10/03/2018     Jake Hinds  Created

*/
@isTest
public class DNCExpirationBatchTest {

    static testMethod void testDNCExpirationBatch() {
        Date expirationDate = system.today().addDays(-1);
        Lead ld = new Lead(FirstName='test',LastName='lead',company='co',phone='1234567890',DoNotCall=true,DNC_Expiration__c = expirationDate);
        insert ld;
        Account acct = new Account(Name='test acct',Do_Not_Call__c=true,DNC_Expiration__c = expirationDate);
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='contact',AccountId=acct.Id,phone='1234567890',DoNotCall=true,DNC_Expiration__c = expirationDate);
        insert ctct;
        Test.startTest();
        Id batchJobId = Database.executeBatch(new DNCExpirationBatch(), 500);
        Test.stopTest();
        Lead uLd = [Select Id,DoNotCall,DNC_Expiration__c FROM Lead WHERE id=:ld.Id];
        system.assert(uLd.DNC_Expiration__c==null);
        system.assertEquals(false,uLd.DoNotCall);
        Account uAcct = [Select Id,Do_Not_Call__c,DNC_Expiration__c FROM Account WHERE id=:acct.Id];
        system.assert(uAcct.DNC_Expiration__c==null);
        system.assertEquals(false,uAcct.Do_Not_Call__c);
        Contact uCtct = [Select Id,DoNotCall,DNC_Expiration__c FROM Contact WHERE id=:ctct.Id];
        system.assert(uCtct.DNC_Expiration__c==null);
        system.assertEquals(false,uCtct.DoNotCall);
    }
}