/* Test methods for the MetaDataBackup class
   
  History
  -------
  05/31/2017 Dan Carmen        Created
  10/30/2017 Dan Carmen   Added extra tracking
  11/03/2017 Dan Carmen   Added ability to log the comments.
  12/06/2017 Dan Carmen   Check if a piece of code is deleted.
  08/17/2018 Dan Carmen   Added test for Aura components
  09/12/2018 Cindy Freeman	Uncommented majority of tests so they all run
  11/10/2023 Dan Carmen   Ability to set the Can Be Deleted field based on latest comment including the "Can Be Deleted" value without spaces.

 */
@isTest
private class MetaDataBackupTest {

   static testMethod void testClasses() {
      MetaDataBackup.QUERY_LIMIT = 10;
      MetaDataBackup mdb = new MetaDataBackup(MetaDataBackup.TYPE_CLASS);
      Test.startTest();
      Database.executeBatch(mdb,10);
      Test.stopTest();
      
      System.assertEquals(10,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_CLASS]);
      
   } // testClasses

   static testMethod void testTriggers() {
      MetaDataBackup.QUERY_LIMIT = 10;
      MetaDataBackup mdb = new MetaDataBackup(MetaDataBackup.TYPE_TRIGGER);

      // simulate an update, so create a record for a trigger
      ApexTrigger aTrigger = [select Id
                                                ,Body
                                                ,ApiVersion
                                                ,CreatedById
                                                ,CreatedDate
                                                ,IsValid
                                                ,LastModifiedById
                                                ,LastModifiedDate
                                                ,LengthWithoutComments
                                                ,Name
                                                ,NamespacePrefix
                                                ,Status
                                            from ApexTrigger 
                                          where NamespacePrefix = null
                                          order by Name limit 1];
      
      MetadataBackup__c backup = mdb.createNewBackup(aTrigger);
      backup.CodeVersion__c = backup.CodeVersion__c+1;
      // put different value in the date to force an update
      backup.LastModifiedDate__c = Datetime.now();
      backup.LastModifiedBy__c = UserInfo.getUserId();
      backup.LastCheckedDate__c = Datetime.now().addDays(-1);
      
      Account acct = new Account(Name='Test Acct');
      insert acct;
      acct = [Select Id, Name, CreatedById, CreatedDate from Account where Id=:acct.Id ];
      
      // create a record that isn't a trigger - so it can be marked for delete
      MetadataBackup__c backup2 = mdb.createNewBackup(acct);
      backup2.CodeLength__c = 500;
      backup2.LastCheckedDate__c = Datetime.now().addDays(-1);
      MetadataBackup__c[] backups = new MetadataBackup__c[]{backup, backup2};
      insert backups;

      System.assertEquals(1,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_TRIGGER and CodeVersion__c=1]);

      Test.startTest();
      Database.executeBatch(mdb,10);
      Test.stopTest();
      
      System.assertEquals(9,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_TRIGGER and CodeVersion__c=1]);
      System.assertEquals(1,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_TRIGGER and CodeVersion__c=2]);
      System.assertEquals(1,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_TRIGGER and CodeVersion__c=0 and CodeIsDeleted__c=true]);
      
   } // testClasses
   
   static testMethod void testComponents() {
      MetaDataBackup.QUERY_LIMIT = 10;
      MetaDataBackup mdb = new MetaDataBackup(MetaDataBackup.TYPE_COMPONENT);
      Test.startTest();
      Database.executeBatch(mdb,10);
      Test.stopTest();
      
      System.assertEquals(10,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_COMPONENT]);
      
   } // testClasses

   static testMethod void testPages() {
      MetaDataBackup.QUERY_LIMIT = 10;
      MetaDataBackup mdb = new MetaDataBackup(MetaDataBackup.TYPE_PAGE);
      Test.startTest();
      Database.executeBatch(mdb,10);
      Test.stopTest();
      
      System.assertEquals(10,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_PAGE]);
      
   } // testClasses

   static testMethod void testScheduler() {
      MetaDataBackup.QUERY_LIMIT = 10;
      TestHelper.testScheduler('testMetaDataBackup', new MetaDataBackup());
   } // testScheduler

   static testMethod void testParseLatestComment() {
      // test an empty string
      String valueToCheck = MetaDataBackup.parseLatestComment(null,500);
      System.assertEquals('',valueToCheck);
      
      // test a string without the comment markers
      valueToCheck = MetaDataBackup.parseLatestComment('This string does not contain comments so should return an empty string',500);
      System.assertEquals('',valueToCheck);
      
      // comments from normal apex
      String textToCheck='/* this is just a test    11/01/2017 Dan Carmen   This is a Comment    ';
      textToCheck += '\n11/02/2017 Dan Carmen  This is another comment ';
      textToCheck += '\n11/03/2017 Dan Carmen  This is a third comment! */';

      valueToCheck = MetaDataBackup.parseLatestComment(textToCheck,500);
      System.assertEquals('11/03/2017 Dan Carmen This is a third comment!',valueToCheck);
      
      // comments from visualforce/components
      textToCheck='<!-- this is another test    11/01/2017 Dan Carmen   This is a Comment    ';
      textToCheck += '\n11/02/2017 Dan Carmen  This is another comment ';
      textToCheck += '\n11/03/2017 Dan Carmen  This is a third comment! ';
      textToCheck += '\n11/04/2017 Dan Carmen  This is a fourth comment!    -->';
      textToCheck += '\n11/05/2017 Dan Carmen  This is a fifth comment! ';

      valueToCheck = MetaDataBackup.parseLatestComment(textToCheck,500);
      System.assertEquals('11/04/2017 Dan Carmen This is a fourth comment!',valueToCheck);

      
   } // testParseLatestComment

   static testMethod void testAura() {
      MetaDataBackup.QUERY_LIMIT = 10;
      MetaDataBackup mdb = new MetaDataBackup(MetaDataBackup.TYPE_AURA);
      Test.startTest();
      Database.executeBatch(mdb,10);
      Test.stopTest();
      
      System.assertEquals(10,[select count() from MetadataBackup__c where Type__c=:MetaDataBackup.TYPE_AURA]);
   } // testAura


} // class MetaDataBackupTest