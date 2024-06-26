/* 
 * Test methods for the AccountPartnerSync class.
               
 *
 * History
 * -------
   09/28/2015 Dan Carmen   Created
   05/25/2017 Dan Carmen      Move logic to class
   01/24/2023 Dan Carmen      Increment API, change to InterfaceC
   10/09/2023 Carrie Marciano specified account recordtype when creating test data

 */
@isTest
private class AccountPartnerSyncTest {

   public static final String BANK_REFERRAL_TYPE='52 Bank Tier 2';

   @testSetup
   public static void setup(){
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false,new String[]{'AccountPartnerSync'});
      TriggerMethodsTest.saveSetupClasses();
      ReferralType__c[] newTypes=  new ReferralType__c[]{};
      newTypes.add(new ReferralType__c(Name=BANK_REFERRAL_TYPE,PartnerReferralForm__c=true));
      insert newTypes;

   } // setup

    static testMethod void testBankSync() {
      //setupTestData();
      Id acctRT = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account').getRecordTypeId();

      // create accounts
      Account acct1 = new Account(Name='Test Parent 1', PartnerId__c='1', ShippingPostalCode='12345', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      Account acct2 = new Account(Name='Test Parent 2', PartnerId__c='2', ShippingPostalCode='12345', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      Account[] accts = new Account[]{acct1,acct2};
      Test.startTest();
      insert accts;
      Test.stopTest();
      TriggerMethods.clearVariables();
      Utilities.SKIP_FUTURE=true;
      
      // verify partner records were created
      System.assertEquals(1,[select count() from Partner__c where Account__c=:acct1.Id]);
      System.assertEquals(1,[select count() from Partner__c where Account__c=:acct2.Id]);
      
      // update the parents. create brances.
      acct1.ShippingPostalCode = '23456';
      acct2.ShippingPostalCode = '34567';
      
      Account acct1a = new Account(Name='Parent 1 Branch 1', ParentId=acct1.Id, ReferralParent__c=acct1.Id, ShippingPostalCode='12345', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      Account acct1b = new Account(Name='Parent 1 Branch 2', ParentId=acct1.Id, ReferralParent__c=acct1.Id, ShippingPostalCode='12346', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      Account acct1c = new Account(Name='Parent 1 Branch 3', ParentId=acct1.Id, ReferralParent__c=acct1.Id, ShippingPostalCode='12347', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);

      Account acct2a = new Account(Name='Parent 2 Branch 1', ParentId=acct2.Id, ReferralParent__c=acct2.Id, ShippingPostalCode='12365', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      Account acct2b = new Account(Name='Parent 2 Branch 2', ParentId=acct2.Id, ReferralParent__c=acct2.Id, ShippingPostalCode='12366', Referral_Type__c=BANK_REFERRAL_TYPE,RecordTypeId=acctRT);
      accts = new Account[]{acct1,acct1a,acct1b,acct1c,acct2,acct2a,acct2b};
      upsert accts;
       
      TriggerMethods.clearVariables();
      
      System.assertEquals(3, [select count() from Partner__c where ParentPartner__r.Account__c=:acct1.Id]);
      System.assertEquals(2, [select count() from Partner__c where ParentPartner__r.Account__c=:acct2.Id]);
      
      // delete one of the branches from acct2
      acct2b.ParentId = null;
      acct2b.ReferralParent__c = null;
      acct2b.ShippingPostalCode='23456';
      update acct2b;
      TriggerMethods.clearVariables();
      
      delete acct2b;
      
      // verify there's now only one under that branch.
      System.assertEquals(1, [select count() from Partner__c where ParentPartner__r.Account__c=:acct2.Id]);
      
   } // testBankSync

} // class AccountPartnerSyncTest