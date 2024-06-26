/* 
   Test methods for the AccountCheckContactEmail class
   
  History
  -------
  06/24/2011 Dan Carmen   Created
  05/30/2012 Dan Carmen   Cleaning up code
  02/09/2018 Dan Carmen   Add in check for Do_Not_Sync__c flag
   
 */
@isTest
private class AccountCheckContactEmailTest {

   static testMethod void testData() {
   	RecordTypeHelperTest.setupRecordType();
   	RecordType__c rtCore = RecordTypeHelper.getRtSetting(RecordTypeHelper.CORE_ACCOUNT);
   	System.debug('testData rtCore='+rtCore);
   	rtCore.UseForSync__c = true;
   	update rtCore;
   	
   	Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
      Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      Account a1 = new Account(Name='Test Account 1',RecordTypeId=rtAcct.getRecordTypeId(), Contact_Email_Available__c=false);
      Account a2 = new Account(Name='Test Account 2',RecordTypeId=rtAcct.getRecordTypeId(), Contact_Email_Available__c=false);
      Account a3 = new Account(Name='Test Account 3',RecordTypeId=rtAcct.getRecordTypeId(), Contact_Email_Available__c=true);
      Account[] accts = new Account[]{a1,a2,a3};
      insert accts;
      
      Contact c1_a1 = new Contact(FirstName='Test Account1',LastName='Contact 1', AccountId=a1.Id,RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true, Do_Not_Sync__c=true);
      Contact c2_a1 = new Contact(FirstName='Test Account1',LastName='Contact 2', AccountId=a1.Id,RecordTypeId=rtCtct.getRecordTypeId(), Email='test@test.com', Sales_Contact__c=true, Do_Not_Sync__c=false);
      Contact c1_a2 = new Contact(FirstName='Test Account2',LastName='Contact 1', AccountId=a2.Id,RecordTypeId=rtCtct.getRecordTypeId(), Email='test@test.com', Sales_Contact__c=true, Do_Not_Sync__c=false);
      Contact c1_a3 = new Contact(FirstName='Test Account2',LastName='Contact 1', AccountId=a3.Id,RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=false, Do_Not_Sync__c=true);
      Contact[] ctcts = new Contact[]{c1_a1,c2_a1,c1_a2};
      insert ctcts;
      
      Test.startTest();
      Database.executeBatch(new AccountCheckContactEmail(Date.today().addMonths(-3),6), 100);
      Test.stopTest();
      
      a1 = [Select Id, Contact_Email_Available__c from Account where Id=:a1.Id];
      System.assertEquals(true,a1.Contact_Email_Available__c);
      a2 = [Select Id, Contact_Email_Available__c from Account where Id=:a2.Id];
      System.assertEquals(true,a2.Contact_Email_Available__c);
      a3 = [Select Id, Contact_Email_Available__c from Account where Id=:a3.Id];
      System.assertEquals(false,a3.Contact_Email_Available__c);
            
   } // testData
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testAccountCheckContactEmail', new AccountCheckContactEmail());
   } // testScheduler

} // class AccountCheckContactEmailTest