/** Test methods for the AccountZipCodeBatch class

* History
* -------
03/04/2022 Dan Carmen       Created

*/
@isTest
public class AccountZipCodeBatchTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ZipCheckOwner','AccountJunctionMethods'});
      TriggerMethodsTest.saveSetupClasses();
      RecordTypeHelperTest.setupRecordType();
   } // setupData
    
   static testMethod void testAcctBatchJob() {
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT);

      Account acct1 = new Account(Name='Account1', ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      Account acct2 = new Account(Name='Account2', ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      Account acct3 = new Account(Name='Account3', ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2,acct3};
      ZipCheckOwner.SKIP_TRIGGERS=false;
      
      Test.startTest();
      AccountZipCodeBatch azcb = new AccountZipCodeBatch();
      database.executeBatch(azcb, 10);
      Test.stopTest();
       
      System.assertEquals(0,[select count() from Account where Use_Zip_Assignment_Rules__c=true]);

   } // testAcctBatchJob

   static testMethod void testCtctBatchJob() {
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 10];
       
      Schema.RecordTypeInfo rtCore = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT);
      Account acct1 = new Account(Name='Account1', OwnerId=users[0].Id, ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      Account acct2 = new Account(Name='Account2', OwnerId=users[1].Id, ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      Account acct3 = new Account(Name='Account3', OwnerId=users[2].Id, ShippingPostalCode='14624', Use_Zip_Assignment_Rules__c=true, RecordTypeId=rtCore.getRecordTypeId());
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2,acct3};
      ZipCheckOwner.SKIP_TRIGGERS=false;

      Contact ctct1a = new Contact(FirstName='Joe', LastName='Contact1a', AccountId=acct1.Id, OwnerId=users[4].Id, Sales_Contact__c=true);
      Contact ctct1b = new Contact(FirstName='Joe', LastName='Contact1b', AccountId=acct1.Id, OwnerId=users[4].Id, Sales_Contact__c=true);
      Contact ctct1c = new Contact(FirstName='Joe', LastName='Contact1c', AccountId=acct1.Id, OwnerId=users[4].Id, Sales_Contact__c=true, Hold_Out__c=true);
      Contact ctct2a = new Contact(FirstName='Taylor', LastName='Contact2a', AccountId=acct2.Id, OwnerId=users[5].Id, Sales_Contact__c=true);
      Contact ctct2b = new Contact(FirstName='Taylor', LastName='Contact2b', AccountId=acct2.Id, OwnerId=users[5].Id, Sales_Contact__c=true);
      Contact ctct2c = new Contact(FirstName='Taylor', LastName='Contact2c', AccountId=acct2.Id, OwnerId=users[5].Id, Sales_Contact__c=true, Hold_Out__c=true);
      Contact ctct3a = new Contact(FirstName='Debbie', LastName='Contact3a', AccountId=acct3.Id, OwnerId=users[6].Id, Sales_Contact__c=true);
      Contact ctct3b = new Contact(FirstName='Debbie', LastName='Contact3b', AccountId=acct3.Id, OwnerId=users[6].Id, Sales_Contact__c=true);
      Contact ctct3c = new Contact(FirstName='Debbie', LastName='Contact3c', AccountId=acct3.Id, OwnerId=users[6].Id, Sales_Contact__c=true, Hold_Out__c=true);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert new Contact[]{ctct1a,ctct1b,ctct1c,ctct2a,ctct2b,ctct2c,ctct3a,ctct3b,ctct3c};
      
      Test.startTest();
      AccountZipCodeBatch.launchBatch(AccountZipCodeBatch.CTCT_OWNER);
      Test.stopTest();

      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, Name, OwnerId, OwnerMismatch__c from Contact]);
      System.assertEquals(acct1.OwnerId, ctctMap.get(ctct1a.Id).OwnerId);
      System.assertEquals(acct1.OwnerId, ctctMap.get(ctct1b.Id).OwnerId);
      System.assertEquals(users[4].Id, ctctMap.get(ctct1c.Id).OwnerId);
       
      System.assertEquals(acct2.OwnerId, ctctMap.get(ctct2a.Id).OwnerId);
      System.assertEquals(acct2.OwnerId, ctctMap.get(ctct2b.Id).OwnerId);
      System.assertEquals(users[5].Id, ctctMap.get(ctct2c.Id).OwnerId);

      System.assertEquals(acct3.OwnerId, ctctMap.get(ctct3a.Id).OwnerId);
      System.assertEquals(acct3.OwnerId, ctctMap.get(ctct3b.Id).OwnerId);
      System.assertEquals(users[6].Id, ctctMap.get(ctct3c.Id).OwnerId);

   } // testCtctBatchJob
    
   static testMethod void testPO() {
      Account acct1 = new Account(Name='Test Account1', ShippingPostalCode='12345');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1};
          
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='TestLast1');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert new Contact[]{ctct1};
          
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];

      Prospect_Ownership__c po1 = new Prospect_Ownership__c(Decision_Maker__c=ctct1.Id
                                       ,StartDate__c=Date.today().addDays(-5)
                                       ,ProspectingStart__c=Date.today().addDays(-5)
                                       ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,NSR_Name__c=users[0].Id);
      insert new Prospect_Ownership__c[]{po1};

      Test.startTest();
      AccountZipCodeBatch.launchBatch(AccountZipCodeBatch.MODE_PO);
      Test.stopTest();

   } // testPO
    
   static testMethod void testScheduleBatch() {
      TestHelper.testScheduler(AccountZipCodeBatch.CLASS_NAME, new AccountZipCodeBatch());
   }

} // class AccountZipCodeBatchTest