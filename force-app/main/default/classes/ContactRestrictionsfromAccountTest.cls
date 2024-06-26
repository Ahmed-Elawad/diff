/**
 Test methods for the AccountCheckContactRestrictions class
   
  History
  -------
  02/27/2011 Carrie Marciano   Created
  09/16/2015 Cindy Freeman     Added test for mergedContacts method
  10/23/2018 Jacob Hinds       Minor changes for DNC update
  10/26/2018 Dan Carmen        Setting API version to 44

  */
@isTest
private class ContactRestrictionsfromAccountTest {
    
static testMethod void testData() {
    
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
      
      Account a1 = new Account(Name='Test Account 1',RecordTypeId=rt.getRecordTypeId(), Do_Not_Call__c=false, Email_Opt_Out__c=false);
      Account a2 = new Account(Name='Test Account 2',RecordTypeId=rt.getRecordTypeId(), Do_Not_Call__c=false, Email_Opt_Out__c=false);
      Account[] accts = new Account[]{a1,a2};
      insert accts;
      
      Contact c1_a1 = new Contact(FirstName='Test Account1',LastName='Contact 1', AccountId=a1.Id, Phone='585-456-7890',DoNotCall=false, Email='c1a1@gmail.com', HasOptedOutOfEmail=false);
      Contact c2_a1 = new Contact(FirstName='Test Account1',LastName='Contact 2', AccountId=a1.Id, Phone='585-367-4840',DoNotCall=false, Email='c2a1@gmail.com', HasOptedOutOfEmail=false);
      Contact c1_a2 = new Contact(FirstName='Test Account2',LastName='Contact 1', AccountId=a2.Id, Phone='585-987-1346',DoNotCall=false, Email='c1a2@gmail.com', HasOptedOutOfEmail=false);
      Contact[] ctcts = new Contact[]{c1_a1,c2_a1,c1_a2};
      insert ctcts;
      
      a1 = [Select Id, Do_Not_Call__c,Email_Opt_Out__c from Account where Id=:a1.Id];
      System.assertEquals(false,a1.Do_Not_Call__c);
      System.assertEquals(false,a1.Email_Opt_Out__c);
      a2 = [Select Id, Do_Not_Call__c,Email_Opt_Out__c from Account where Id=:a2.Id];
      System.assertEquals(false,a2.Do_Not_Call__c);
      System.assertEquals(false,a2.Email_Opt_Out__c);
      c1_a1 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c1_a1.Id];
      System.assertEquals(false,c1_a1.DoNotCall);
      System.assertEquals(false,c1_a1.HasOptedOutOfEmail);
      c2_a1 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c2_a1.Id];
      System.assertEquals(false,c2_a1.DoNotCall);
      System.assertEquals(false,c2_a1.HasOptedOutOfEmail);
      c1_a2 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c1_a2.Id];
      System.assertEquals(false,c1_a2.DoNotCall);
      System.assertEquals(false,c1_a2.HasOptedOutOfEmail);
      
      
      Id[]fixedSearchResults = new Id[]{c1_a1.Id,c2_a1.Id,c1_a2.Id};
      Test.setFixedSearchResults(fixedSearchResults);
          
      Test.startTest();
      
      a1.Do_Not_Call__c = true;
      update a1;
      a2.Email_Opt_Out__c = true;
      update a2;
      
      Test.stopTest();
      a1 = [Select Id, Do_Not_Call__c,Email_Opt_Out__c from Account where Id=:a1.Id];
      System.assertEquals(true,a1.Do_Not_Call__c);
      c1_a1 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c1_a1.Id];
      System.assertEquals(true,c1_a1.DoNotCall);
      System.assertEquals(false,c1_a1.HasOptedOutOfEmail);
      c2_a1 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c2_a1.Id];
      System.assertEquals(true,c2_a1.DoNotCall);
      System.assertEquals(false,c2_a1.HasOptedOutOfEmail);
      
      a2 = [Select Id, Do_Not_Call__c,Email_Opt_Out__c from Account where Id=:a2.Id];
      System.assertEquals(true,a2.Email_Opt_Out__c);
      c1_a2 = [Select Id, DoNotCall, HasOptedOutOfEmail from Contact where Id=:c1_a2.Id];
      System.assertEquals(false,c1_a2.DoNotCall);
      System.assertEquals(true,c1_a2.HasOptedOutOfEmail);
      
    }        
    
    /* test method for mergedContacts
     */
    static testmethod void testMergedCtcts() {
        CreateTestData.createTestAandC();
        Account acct1 = [Select Id, Do_Not_Call__c, Email_Opt_Out__c from Account where Name = 'Test Account1'];
        acct1.Do_Not_Call__c = true;
        acct1.Email_Opt_Out__c = true;
        update acct1;
        
        Contact[] ctctList = [Select Id,  DoNotCall, HasOptedOutOfEmail from Contact where accountId = :acct1.Id ];
        for (Contact ctct:ctctList)
        {   System.assertEquals(ctct.DoNotCall, true);
            System.assertEquals(ctct.HasOptedOutOfEmail, true);
        }
        
        Contact ctct2 = [Select Id, accountId, DoNotCall, HasOptedOutOfEmail from Contact where account.Name = 'Test Account2'];
        System.assertEquals(ctct2.DoNotCall, false);
        System.assertEquals(ctct2.HasOptedOutOfEmail, false);
        ctct2.AccountId = acct1.Id;
        update ctct2;
        ctct2 = [Select Id, accountId, DoNotCall, HasOptedOutOfEmail from Contact where Id = :ctct2.Id];
        System.assertEquals(ctct2.DoNotCall, true);
        System.assertEquals(ctct2.HasOptedOutOfEmail, true);
        
    } // testMergedCtcts
    
 
} // ContactRestrictionsfromAccountTest