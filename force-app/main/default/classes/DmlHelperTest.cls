/* 
 * Test methods for DmlHelper class
 *
 * History
 * -------
  11/17/2011 Dan Carmen   Created - rewrite of the SObjectHelper class
  10/08/2013 Dan Carmen   Added methods to handle save results
  03/20/2015 Dan Carmen   Added the performDML method
  03/08/2019 Dan Carmen   Added ability to retry saving
  10/23/2020 Dan Carmen   Move API version back to 44.0 to get around SF issue of delete ATMs.
  10/21/2021 Dan Carmen   Don't retry if running in a batch
  10/09/2023 Carrie Marciano specified account recordtype when creating test data 
   
 */
@isTest
private class DmlHelperTest {
   
   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = DmlHelperRetry.CLASS_NAME, Active__c = true, BatchSize__c=50, SendCompletionEmail__c=true);
      insert abc;
      // setup the custom settings that control error retry
      ErrorLogTest.setupData();
   } // setupData

   static testMethod void testUpsertSuccess() {
      DmlHelper.LOG_DETAILS=true;
      // create two objects
      Account a1 = new Account(Name='Test 1');
      insert a1;
      a1.ShippingPostalCode = '14514';
      Account a2 = new Account(Name='Test 2');
      Account[] accts = new Account[]{a1,a2};
      DmlHelper oh = new DmlHelper();
      System.assertEquals(true,oh.saveRecords(accts, null, null,false,false));
      // verify a2 saved
      System.assertEquals(true,(a2.Id != null));
      
      // save Contacts against a1
      Contact c1 = new Contact(FirstName='James', LastName='Test', AccountId=a1.Id);
      insert c1;
      c1.FirstName='Jimmy';
      Contact c2 = new Contact(FirstName='Timmy', LastName='Test');
      Contact c3 = new Contact(FirstName='Tina', LastName='Test');
      Contact[] ctcts = new Contact[]{c1,c2,c3};
      System.assertEquals(true,oh.saveRecords(ctcts, 'AccountId', a1.Id,false,false));
      
      // verify records saved
      System.assertEquals(true,(c2.Id != null));
      System.assertEquals(true,(c3.Id != null));
      // verify records saved with updated data
      c1 = [Select FirstName, LastName, AccountId from Contact where Id=:c1.Id];
      System.assertEquals('Jimmy',c1.FirstName);
      c2 = [Select FirstName, LastName, AccountId from Contact where Id=:c2.Id];
      System.assertEquals(a1.Id,c2.AccountId);
      c3 = [Select FirstName, LastName, AccountId from Contact where Id=:c3.Id];
      System.assertEquals(a1.Id,c3.AccountId);
      
      // test failure - required field missing
      Contact c4 = new Contact(FirstName='Tommy');
      Contact c5 = new Contact(FirstName='Teddy', LastName='Test');
      ctcts = new Contact[]{c4,c5};
      System.assertEquals(false,oh.saveRecords(ctcts, 'AccountId', a1.Id,false,false));
   } // testUpsertSuccess
   
   static testMethod void testFailure() {
      DmlHelper.LOG_DETAILS=true;
      // attempt a save that will cause an error
      Contact ctct = new Contact(LastName='LastName', Email='bademail');
      Contact[] ctcts = new Contact[]{ctct};
      DmlHelper oh = new DmlHelper();
      // this should return false because the save will fail with a bad email
      System.assertEquals(false,oh.saveRecords(ctcts, null, null,false,false));
      // check if exception is thrown
      try {
         oh.saveRecords(ctcts, null, null,true,false);
         // we should not get here
         System.assertEquals('Do Not','Get Here');
      } catch (DmlHelper.SaveException se) {
         // we should get here.
         System.assertEquals('Good','Good');
      }
      // should return without an exception but have an error.
      System.assertEquals(false,oh.saveRecords(ctcts, null, null,false,true));
      
   } // testFailure

   static testMethod void testUpsertResult() {
      DmlHelper.LOG_DETAILS=true;
      // should fail with no last name
      Lead lead1 = new Lead(Company='Test Company 1',PostalCode='12345');
      // should fail with no company name
      Lead lead2 = new Lead(LastName='LastName2',PostalCode='12345');
      Lead[] leads = new Lead[]{lead1,lead2};
      Database.UpsertResult[] results = Database.Upsert(leads,false);
      System.assertEquals(false,DmlHelper.checkUpsertResults(results,leads));
      
      // fix the errors
      lead1.LastName = 'LastName1';
      Lead2.Company = 'Test Company 2';
      results = Database.Upsert(leads,false);
      System.assertEquals(true,DmlHelper.checkUpsertResults(results,leads));
      
      // update so one record fails
      lead1.LastName = null;
      Database.SaveResult[] results2 = Database.Update(leads,false);
      System.assertEquals(false,DmlHelper.checkSaveResults(results2,leads));
      
      // fix broken record
      lead1.LastName = 'NewLastName1';
      results2 = Database.Update(leads,false);
      System.assertEquals(true,DmlHelper.checkSaveResults(results2,leads));
      

   } // testUpsertResul
   
   static testMethod void testSaveRecords() {
      DmlHelper.LOG_DETAILS=true;
      Account acct1 = new Account(Name='Acct1');
      Account acct2 = new Account(Name='Acct2');
      Account[] accts = new Account[]{acct1,acct2};
      
      Boolean saveOkay = DmlHelper.performDML(accts, DmlHelper.DML_INSERT, 'DmlHelperTest', 'testSaveRecords', 'test 1', true);
      System.assertEquals(true,saveOkay);

      System.assertEquals(true,acct1.Id != null);
      System.assertEquals(true,acct2.Id != null);
   
      acct1.ShippingPostalCode='14514';
      acct2.ShippingPostalCode='14614';
      
      saveOkay = DmlHelper.performDML(accts, DmlHelper.DML_UPDATE, 'DmlHelperTest', 'testSaveRecords', 'test 2', true);
      System.assertEquals(true,saveOkay);
      
      
      Account acct3 = new Account(Name='Acct3');
      accts.add(acct3);
      
      // this should fail since the other two accounts are still in the array
      saveOkay = DmlHelper.performDML(accts, DmlHelper.DML_INSERT, 'DmlHelperTest', 'testSaveRecords', 'test 3', true);
      System.assertEquals(false,saveOkay);

      System.assertEquals(true,acct3.Id == null);

   } // testSaveRecords

   static testMethod void testSaveRecords2() {
      DmlHelper.LOG_DETAILS=true;
      Id acctRT = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account').getRecordTypeId(); 
      Account acct1 = new Account(Name='Acct1',RecordTypeId=acctRT);
      Account acct2 = new Account(Name='Acct2',RecordTypeId=acctRT);
      Account[] accts = new Account[]{acct1,acct2};
      
      Boolean saveOkay = DmlHelper.performDML2(accts, DmlHelper.DML_INSERT, 'DmlHelperTest', 'testSaveRecords', 'test 1', true);
      System.assertEquals(true,saveOkay);

      System.assertEquals(true,acct1.Id != null);
      System.assertEquals(true,acct2.Id != null);
   
      // this one will fail since they've already been inserted
      saveOkay = DmlHelper.performDML2(accts, DmlHelper.DML_INSERT, 'DmlHelperTest', 'testSaveRecords', 'test 1 fail', true);
      System.assertEquals(false,saveOkay);
      
      // verify the error records were created.
      System.assertEquals(1,[select count() from ErrorLog__c]);
      System.assertEquals(2,[select count() from ErrorDetail__c]);
      System.assertEquals(1,[select count() from ErrorDetail__c where Id__c=:acct1.Id]);

      acct1.ShippingPostalCode='14514';
      acct2.ShippingPostalCode='14614';
      
      saveOkay = DmlHelper.performDML2(accts, DmlHelper.DML_UPDATE, 'DmlHelperTest', 'testSaveRecords', 'test 2', true);
      System.assertEquals(true,saveOkay);
      
      
      Account acct3 = new Account(Name='Acct3',RecordTypeId=acctRT);
      accts.add(acct3);
      
      saveOkay = DmlHelper.performDML2(accts, DmlHelper.DML_UPSERT, 'DmlHelperTest', 'testSaveRecords', 'test 3', true);
      System.assertEquals(true,saveOkay);
      System.assertEquals(3,[select count() from Account]);

      saveOkay = DmlHelper.performDML2(accts, DmlHelper.DML_DELETE, 'DmlHelperTest', 'testSaveRecords', 'test 4', true);
      System.assertEquals(true,saveOkay);

      System.assertEquals(0,[select count() from Account]);

   } // testSaveRecords2

   static testMethod void testRetrySuccess() {
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<10; cnt++) {
         accts.add(new Account(name='Test Account'+cnt));
      }
      
      ZipCheckOwner.SKIP_TRIGGERS=true;
      
      // mock up a situation so we can test if it executes
      ErrorLog__c errLog = ErrorLog.logError('Test1', 'testRetrySuccess', 'JustACodeKey', (String)null, (Exception)null);
      errLog.RowLockError__c = true;
      errLog.DMLType__c = DmlHelper.DML_INSERT;
      //DmlHelperRetry.FORCE_RETRY=true;
      
      Test.StartTest();
      DmlHelperRetry.checkForRetry(errLog, accts);
      Test.StopTest();
      
      ErrorLog__c checkLog = [Select Id, Name, Description__c, MaxRetries__c, NbrRetries__c, SuccessOnRetry__c from ErrorLog__c where ClassName__c='Test1' and MethodName__c='testRetrySuccess'];
      System.assertEquals(1,checkLog.MaxRetries__c);
      System.assertEquals(1,checkLog.NbrRetries__c);
      System.assertEquals(true,checkLog.SuccessOnRetry__c);
      System.assertEquals(10,[select count() from Account where Name like 'Test Account%']);
   } // testRetrySuccess

   static testMethod void testRetryFailure() {
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<10; cnt++) {
         // wrong ID type to force it to fail.
         accts.add(new Account(name='Test Account'+cnt, CPA_Name_Ref__c=UserInfo.getUserId()));
      }
      
      ZipCheckOwner.SKIP_TRIGGERS=true;
      
      // mock up a situation so we can test if it executes
      ErrorLog__c errLog = ErrorLog.logError('Test1', 'testRetryFailure', 'JustACodeKey', (String)null, (Exception)null);
      errLog.RowLockError__c = true;
      errLog.DMLType__c = DmlHelper.DML_INSERT;
      //DmlHelperRetry.FORCE_RETRY=true;
      
      Test.StartTest();
      DmlHelperRetry.checkForRetry(errLog, accts);
      Test.StopTest();
      
      ErrorLog__c checkLog = [Select Id, Name, Description__c, MaxRetries__c, NbrRetries__c, SuccessOnRetry__c from ErrorLog__c where ClassName__c='Test1' and MethodName__c='testRetryFailure'];
      System.assertEquals(1,checkLog.MaxRetries__c);
      System.assertEquals(1,checkLog.NbrRetries__c);
      System.assertEquals(false,checkLog.SuccessOnRetry__c);
      System.assertEquals(0,[select count() from Account where Name like 'Test Account%']);
      
   } // testRetryFailure
    
   static testMethod void testFieldSetQuery() {
      Contact ctct = new Contact(FirstName='Joe',LastName='Contact');
      insert ctct;
      Id ctctId = ctct.Id;
       
      Set<String> fldSet = new Set<String>();
      DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.WorkQueueQuery, '', fldSet);
      String query = DmlHelper.buildQueryFromSet(fldSet,'Contact')+' where Id=:ctctId';
      Contact[] ctcts = Database.query(query);
      System.assertEquals(1,ctcts.size());
      System.assertEquals(ctctId, ctcts[0].Id);
   } // testFieldSetQuery

   static testMethod void testDml() {
      Account acct = new Account(Name='Test Account');
      Database.SaveResult[] results = DmlHelper.simpleInsert(new Account[]{acct});
      System.assertNotEquals(null,acct.Id);
      acct.ShippingPostalCode = '14624';
      results = DmlHelper.simpleUpdate(new Account[]{acct});
      acct = [Select Id, Name, ShippingCity, ShippingPostalCode from Account where Id=:acct.Id];
      System.assertEquals('14624',acct.ShippingPostalCode);
      acct.ShippingCity = 'Rochester';
      Database.UpsertResult[] results2 = DmlHelper.simpleUpsert(new Account[]{acct}, Account.Id);
      acct = [Select Id, Name, ShippingCity, ShippingPostalCode from Account where Id=:acct.Id];
      System.assertEquals('Rochester',acct.ShippingCity);
   } // testDml

} // class DmlHelperTest