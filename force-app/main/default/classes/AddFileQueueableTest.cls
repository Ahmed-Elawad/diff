/** Test methods for the AddFileQueueable class

 * History
 * -------
   05/25/2018 Dan Carmen       Created
   07/24/2018 Dan Carmen       Added a no argument constructor

*/
@isTest
private class AddFileQueueableTest {
   
   @testSetup
   private static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = AddFileQueueable.CLASS_NAME, Active__c = true);
      insert abc; 
   } // setupData

   static testMethod void testFileInsertAcct() {
      Account acct1 = new Account(Name='Account 1');
      Account acct2 = new Account(Name='Account 2');
      Account[] accts = new Account[]{acct1,acct2};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      String file1 = 'This is file 1';
      String file2 = 'This is file 2';
      String file3 = 'This is file 3';

      // for code coverage of argument-less constructor      
      AddFileQueueable afqTemp = new AddFileQueueable();
      
      // Id[] p_parentIds, String p_fileName, String p_displayName, String p_fileContent
      // attach to both accounts
      AddFileQueueable afq = new AddFileQueueable(new Id[]{acct1.Id,acct2.Id}, 'file1.txt', 'ThisIsFile1', file1, null);
      afq.addAnotherFile(new Id[]{acct1.Id}, 'file2.txt', 'ThisIsFile2', file2,null);
      afq.addAnotherFile(new Id[]{acct2.Id}, 'file3.txt', 'ThisIsFile3', file3,null);
      
      Test.startTest();
      afq.launchQueueable(true);
      Test.stopTest();
      
      Id[] acctIds = new Id[]{acct1.Id,acct2.Id};
      // should be 4 file links created
      //System.assertEquals(4,[select count() from ContentDocumentLink where LinkedEntityId in :acctIds]);
      
      ContentDocumentLink[] links = [select Id, ContentDocumentId , LinkedEntityId, ShareType, Visibility from ContentDocumentLink where LinkedEntityId in :acctIds];
      System.assertEquals(4, links.size());
      
      for (ContentDocumentLink link : links ) {
         System.debug('testFileInsertAcct link='+link);
      }
   
   } // testFileInsert
} // class AddFileQueueable