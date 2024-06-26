@isTest
private class NotifyCaseOwnerTest {

    static testMethod void testClosedCaseNotification() 
    {
        //Set up Test Data
      Id caseRecordType = [SELECT Id, Name FROM RecordType WHERE Name='Service Support 401k/S125 Case' and IsActive = TRUE AND SobjectType = 'Case' LIMIT 1][0].id;
	  Account acc = new account(name = 'TestCoverage');
	  insert acc;
	  Contact con = new contact(accountId = acc.id, lastname='Coverage', firstname='Test');
	  insert con;

	  Case parentCase1 = new case(accountId = acc.id,RecordTypeId = caseRecordType , contactId = con.id, status = 'New', type = 'Help Request', origin = 'Email', subject = 'Test Coverage 2');
	  insert parentCase1;
	  Case childCase1 = new case(accountId = acc.id, RecordTypeId = caseRecordType , contactId = con.id, status = 'Solved',ParentId=parentCase1.id, type = 'Help Request', origin = 'Email', subject = 'Test Coverage 1');
	  insert childCase1;

	  Case parentCase2 = new case(accountId = acc.id, RecordTypeId = caseRecordType ,contactId = con.id, status = 'New', type = 'Help Request', origin = 'Email', subject = 'Test Coverage 2');
	  insert parentCase2;

	  Case childCase2 = new case(accountId = acc.id, RecordTypeId = caseRecordType , contactId = con.id, status = 'New',ParentId= parentCase2.id, type = 'Help Request', origin = 'Email', subject = 'Test Coverage 1');
	  insert childCase2;
	  
	  childCase2.status = 'Solved';
	  update childCase2;

    }

}