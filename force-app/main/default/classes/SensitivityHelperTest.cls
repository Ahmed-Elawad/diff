/* 
 * Test methods for the SensitivityHelper class
 *
 * History
 * -------
   09/22/2016 Dan Carmen   Created

 */
@isTest
private class SensitivityHelperTest {

   static testMethod void testQuery() {
      ReferralAccountMethodsTest.setupSensitivityCustomSetting();
      Contact cpa = ReferralScoreMethodsTest.createCpa('TestCPA');
      Account acct1 = new Account(Name='Test Rec 1');
      Account acct2 = new Account(Name='Test Rec 2');
      Account acct3 = new Account(Name='Test Rec 3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      AccountContactRelation acr1 = new AccountContactRelation(AccountId=acct1.Id, ContactId=cpa.Id, Roles=Label.ReferralSourceCpa
                                        ,StartDate=Date.today().addDays(-7), IsActive=true);
      AccountContactRelation acr2 = new AccountContactRelation(AccountId=acct2.Id, ContactId=cpa.Id, Roles=Label.ReferralSourceCpa
                                        ,StartDate=Date.today().addDays(-7), IsActive=true);
      AccountContactRelation acr3 = new AccountContactRelation(AccountId=acct3.Id, ContactId=cpa.Id, Roles=Label.ReferralSourceCpa
                                        ,StartDate=Date.today().addDays(7), IsActive=false);
      AccountContactRelation[] acrs = new AccountContactRelation[]{acr1,acr2,acr3};
      insert acrs;
      
      ProductSensitivityFields__c testSensitivity = null;
      for (ProductSensitivityFields__c psf : ProductSensitivityFields__c.getAll().values()) {
         if (psf.OnAccount__c && psf.OnContact__c && String.isNotBlank(psf.AccountRollupField__c)) {
            testSensitivity = psf;
            break;
         }
      } // for (ProductSensitivityFields__c psf
      
      Id acctId = acct1.Id;
      String acctQuery = 'Select Id, Name, '+testSensitivity.AccountRollupField__c+' from Account where Id=:acctId';
      acct1 = (Account)Database.query(acctQuery);
      System.assertEquals(false,(Boolean)acct1.get(testSensitivity.AccountRollupField__c));

      // make sure we have a value
      System.assertEquals(true, testSensitivity != null);

      // set a sensitivity
      cpa.put(testSensitivity.FieldName__c,true);
      update cpa;
      
      acct1 = (Account)Database.query(acctQuery);
      System.assertEquals(true,(Boolean)acct1.get(testSensitivity.AccountRollupField__c));
      
      acctId = acct2.Id;
      acct2 = (Account)Database.query(acctQuery);
      System.assertEquals(true,(Boolean)acct2.get(testSensitivity.AccountRollupField__c));
      
      acctId = acct3.Id;
      acct3 = (Account)Database.query(acctQuery);
      System.assertEquals(false,(Boolean)acct3.get(testSensitivity.AccountRollupField__c));
      
      // remove the sensitivity
      cpa.put(testSensitivity.FieldName__c,false);
      update cpa;
      
      acctId = acct1.Id;
      acct1 = (Account)Database.query(acctQuery);
      System.assertEquals(false,(Boolean)acct1.get(testSensitivity.AccountRollupField__c));
      
      acctId = acct2.Id;
      acct2 = (Account)Database.query(acctQuery);
      System.assertEquals(false,(Boolean)acct2.get(testSensitivity.AccountRollupField__c));

      acctId = acct3.Id;
      acct3 = (Account)Database.query(acctQuery);
      System.assertEquals(false,(Boolean)acct3.get(testSensitivity.AccountRollupField__c));
      
   } // testQuery
   
} // class SensitivityHelperTest