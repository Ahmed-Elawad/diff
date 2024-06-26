@isTest
private class DeleteTestLeadBatchTest {
    static testmethod void test() {
    // Minutes_till_Launch__c to null so it doesn't try to launch again
    Apex_Batch_Control__c  abc2 = new Apex_Batch_Control__c(Name=DeleteTestLeadBatch.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=1, Minutes_till_Launch__c=null);
    insert abc2;
    Datetime cd = system.now()-8;
    // Create test leads to be deleted
    Lead ld = new Lead(LastName = 'test1', Company = 'testCompany1', Email='test1@paychextest.com', CreatedDate=cd);
    insert ld;
 
    Test.startTest();
    DeleteTestLeadBatch b = new DeleteTestLeadBatch();
    Database.executeBatch(b);
    Test.stopTest();
    // Verify accounts updated
    Lead[] ldTest = [SELECT Id, Name FROM Lead];
    System.assertEquals(0, ldTest.size());
    }
}