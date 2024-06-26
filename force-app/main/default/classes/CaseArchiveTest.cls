/* 
 * Test methods for the CaseArchive job
 *
 * History
 * -------
 * 12/09/2015 Dan Carmen     Created
   03/07/2017 Dan Carmen     Change to run for all record types
   02/06/2018 Dan Carmen     Confirm the setup of the employee contact triggers.
 *
 */
@isTest
private class CaseArchiveTest {

   static testMethod void testBatchJob() {
      ContactFormatPaychexEmpsTest.checkSetupData();
      Schema.RecordTypeInfo acctRtType = RecordTypeHelper.getRecordType(Label.RT_System_Admin_Account, ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo ctctRtType = RecordTypeHelper.getRecordType(Label.RT_Paychex_Employee, ObjectHelper.OBJECT_CONTACT);
      List<Schema.RecordTypeInfo> caseRts = RecordTypeHelper.getRecordTypes(ObjectHelper.OBJECT_CASE);
      // grab the first record type to use
      Schema.RecordTypeInfo caseRtType = caseRts[0];
      Id caseRtId = caseRtType.getRecordTypeId();
      
      // create the custom setting
      RecordType__c rtSetting = new RecordType__c(Name=caseRtType.getName(),ObjectName__c=ObjectHelper.OBJECT_CASE, UseInCaseArchive__c=true);
      insert rtSetting;

      // create the Paychex account
      Account payxAcct = ContactFormatPaychexEmps.getParentAcct();
      
      //Account payxAcct = new Account(Name=UserHelper.PAYCHEX_COMP, RecordTypeId=acctRtType.getRecordTypeId());
      //insert payxAcct;

      Account payxAcctD = new Account(Name=UserHelper.PAYCHEX_COMP+'-D', RecordTypeId=acctRtType.getRecordTypeId());
      insert payxAcctD;
      
      Contact emp1 = new Contact(AccountId=payxAcct.Id, FirstName='First', LastName='Alast', HR_Person_Id__c='1');
      Contact emp2 = new Contact(AccountId=payxAcct.Id, FirstName='First', LastName='Blast', HR_Person_Id__c='2');
      Contact emp3 = new Contact(AccountId=payxAcct.Id, FirstName='First', LastName='Clast', HR_Person_Id__c='3');
      Contact emp4 = new Contact(AccountId=payxAcct.Id, FirstName='First', LastName='ASecondLast', HR_Person_Id__c='4');
      Contact emp5 = new Contact(AccountId=payxAcct.Id, FirstName='First', LastName='Dlast', HR_Person_Id__c='5');
      Contact[] ctcts = new Contact[]{emp1,emp2,emp3,emp4,emp5};
      insert ctcts;

      Contact emp5archive = new Contact(AccountId=payxAcctD.Id, FirstName='Archive', LastName='First DLast',ReportsToId=emp5.Id);      
      insert emp5archive;
      
      Case c1a = new Case(Subject='Test Case1', ContactId=emp1.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c1b = new Case(Subject='Test Case2', ContactId=emp1.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c2a = new Case(Subject='Test Case3', ContactId=emp2.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c2b = new Case(Subject='Test Case4', ContactId=emp2.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c3a = new Case(Subject='Test Case5', ContactId=emp3.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c3b = new Case(Subject='Test Case6', ContactId=emp3.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c4a = new Case(Subject='Test Case7', ContactId=emp4.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c4b = new Case(Subject='Test Case8', ContactId=emp4.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c5a = new Case(Subject='Test Case9', ContactId=emp5.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case c5b = new Case(Subject='Test Case10', ContactId=emp5.Id, Status='In Progress', RecordTypeId=caseRtId);
      Case[] cases = new Case[]{c1a,c1b,c2a,c2b,c3a,c3b,c4a,c4b,c5a,c5b};
      insert cases;
      
      System.assertEquals(10,[select count() from Case where Account.Name=:UserHelper.PAYCHEX_COMP]);
      
      c1a.Status = 'Closed';
      c2a.Status = 'Closed';
      c3a.Status = 'Closed';
      c4a.Status = 'Closed';
      c5a.Status = 'Closed';
      update cases;
      
      CaseArchive ca = new CaseArchive();
      CaseArchive.nbrCheckDays = 0;
      
      Test.startTest();
      Database.executeBatch(ca,cases.size());
      Test.stopTest();

      // the 4 closed cases should no longer be attached to the paychex account.
      System.assertEquals(5,[select count() from Case where Account.Name=:UserHelper.PAYCHEX_COMP]);
      
      String acctNameA = UserHelper.PAYCHEX_COMP+'-A';
      String acctNameB = UserHelper.PAYCHEX_COMP+'-B';
      String acctNameC = UserHelper.PAYCHEX_COMP+'-C';
      
      c1a = [Select Id, ContactId, Contact.Name, Contact.HR_Person_Id__c, Contact.ReportsToId, AccountId, Account.Name from Case where Id=:c1a.Id];
      System.debug('c1a='+c1a+' emp1='+emp1.Id);
      System.debug('c1a contact='+c1a.Contact);
      System.debug('c1a account='+c1a.Account);

      System.assertEquals(2,[select count() from Case where (Id=:c1a.Id or Id=:c4a.Id) and Account.Name=:acctNameA]);
      System.assertEquals(1,[select count() from Case where Id=:c2a.Id and Account.Name=:acctNameB]);
      System.assertEquals(1,[select count() from Case where Id=:c3a.Id and Account.Name=:acctNameC]);
      System.assertEquals(1,[select count() from Case where Id=:c5a.Id and Account.Name=:payxAcctD.Name]);
      
   } // testBatchJob
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('CaseArchiveTest', new CaseArchive());
   } // testScheduler

} // class CaseArchiveTest