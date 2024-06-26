/**
 Test methods for the AccountCheckContactRestrictions class
   
  History
  -------
  02/20/2011 Carrie Marciano   Created
  10/27/2014 Dan Carmen        Changed to without sharing
  04/09/2020 Dan Carmen        Changed to CreateTestData to get recordtype info.
 
 */
@isTest
private class AccountCheckContactRestrictionsTest {

  
    static testMethod void testData() {
   	
   	  Schema.RecordTypeInfo rt = CreateTestData.getDefaultProspectAcctRT();
      Schema.RecordTypeInfo ctctRt = CreateTestData.getDefaultSalesContactRT();
   	  
      Account a1 = new Account(Name='Test Account 1',RecordTypeId=rt.getRecordTypeId(), Related_Contact_has_Do_Not_Call__c=false, Related_Contact_is_Email_Opt_Out__c=false);
      Account a2 = new Account(Name='Test Account 2',RecordTypeId=rt.getRecordTypeId(), Related_Contact_has_Do_Not_Call__c=false, Related_Contact_is_Email_Opt_Out__c=false);
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1_a1 = new Contact(FirstName='Test Account1',LastName='Contact 1', AccountId=a1.Id, DoNotCall=false, HasOptedOutOfEmail=false, RecordTypeId=ctctRt.getRecordTypeId());
      Contact c2_a1 = new Contact(FirstName='Test Account1',LastName='Contact 2', AccountId=a1.Id, DoNotCall=false, HasOptedOutOfEmail=true, RecordTypeId=ctctRt.getRecordTypeId());
      Contact c1_a2 = new Contact(FirstName='Test Account2',LastName='Contact 1', AccountId=a2.Id, DoNotCall=false, HasOptedOutOfEmail=false, RecordTypeId=ctctRt.getRecordTypeId());
      Contact[] ctcts = new Contact[]{c1_a1,c2_a1,c1_a2};
      insert ctcts;
      
      a1 = [Select Id, Related_Contact_has_Do_Not_Call__c, Related_Contact_is_Email_Opt_Out__c from Account where Id=:a1.Id];
      System.assertEquals(true,a1.Related_Contact_is_Email_Opt_Out__c);
      System.assertEquals(false,a1.Related_Contact_has_Do_Not_Call__c);
      a2 = [Select Id, Related_Contact_has_Do_Not_Call__c, Related_Contact_is_Email_Opt_Out__c from Account where Id=:a2.Id];
      System.assertEquals(false,a2.Related_Contact_is_Email_Opt_Out__c);
      System.assertEquals(false,a1.Related_Contact_has_Do_Not_Call__c);
    }        
 
   
} // AccountCheckContactRestrictionsTest