/* 
 * Test Methods for the SequenceUpdater class. Logic for actually performing the updates is in the
 * AccountCheckSequenceTest class. This class will only test the batch statements.
 *
 * History
 * -------
 * 02/06/2012 Dan Carmen   Created
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   02/11/2014 Dan Carmen   Commented out code
 *
 */
@isTest
private class SequenceUpdaterTest {

  /*
   static testMethod void testBatch() {
      // setup test sequences
      SequenceTest.setupTestData();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] sObjectNames = new String[]{'Account'};
      String[] recordTypeNames = new String[]{RecordTypeHelper.CORE_ACCOUNT,RecordTypeHelper.MMS_ACCOUNT};
      RecordTypeHelper.getRecordTypesMap(sObjectNames, recordTypeNames, null, byName);
   	  
      Schema.RecordTypeInfo coreRt = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo mmsRt = byName.get(RecordTypeHelper.MMS_ACCOUNT);

      SequenceTest.setupTestUsers();
   	   
      // setup test Accounts
      Account a1 = new Account(Name='Test acct1', OwnerId=SequenceTest.coreUser.Id, RecordTypeId=coreRt.getRecordTypeId(), NumberOfEmployees=null, Bis_Id__c=22, First_Run_Date__c=Date.today());
      Account a2 = new Account(Name='Test acct2', OwnerId=SequenceTest.coreUser.Id, RecordTypeId=coreRt.getRecordTypeId(), NumberOfEmployees=42, Bis_Id__c=23, First_Run_Date__c=Date.today());

      Account a3 = new Account(Name='Test acct3', OwnerId=SequenceTest.mmsUser.Id, RecordTypeId=mmsRt.getRecordTypeId(), NumberOfEmployees=77, Bis_Id__c=25, First_Run_Date__c=Date.today());
   	  
      Account[] accts = new Account[]{a1,a2,a3};
      insert accts;
   	  
      Id[] acctIds = new Id[]{a1.Id,a2.Id,a3.Id};
      	
      // get the links
      Account_Sequence_Link__c[] links = [Select Id, Account__c, Is_Test_Record__c from Account_Sequence_Link__c where Account__c in :acctIds];
      // verify 3 are returned
      System.assertEquals(3,links.size());
      // update the Is_Test_Record__c 
   	  
      // verify attached to sequence
      System.assertEquals(1,[Select count() from Account_Sequence_Link__c where Account__c=:a1.Id]);
      System.assertEquals(1,[Select count() from Account_Sequence_Link__c where Account__c=:a2.Id]);
      System.assertEquals(1,[Select count() from Account_Sequence_Link__c where Account__c=:a3.Id]);
   	  
      // run the batch
      SequenceUpdater su = new SequenceUpdater();
      Test.startTest();
      Database.executeBatch(su,5);
      Test.stopTest();
      
   } // testBatch
   
   static testMethod void testScheduler() {
   	  TestHelper.testScheduler('testSequenceUpdater', new SequenceUpdater());
   } // testScheduler
   
   */
} // SequenceUpdaterTest