/** Test methods for the TestClassJobTest

 *
 * History
 * -------
   08/02/2017 Dan Carmen        Created
   06/17/2020 Cindy Freeman		added Test_Class_Job_Settings for testing
   01/05/2021 Dan Carmen        Increment API version
 */
@isTest
private class TestClassJobTest {

    static testMethod void testEnqueueTests() {
       Test_Class_Job_Settings__c js = new Test_Class_Job_Settings__c();
        js.Name = 'Marketing';
        js.Active__c = false;
        js.SendCompletionEmail__c = true;
        js.Test_Classes__c = 'SOAREmailHandlerTest';
        insert js;
        
       TestClassJob.TEST_LIMIT=1;
       // this should be a test that runs quickly
       TestClassJob.NAME_COMPARE=Label.TestClassJob_TestClass;
       Test.startTest();
       TestClassJob tcj = new TestClassJob();
       tcj.execute(null);
       Test.stopTest();
    } // testEnqueueTests
    
    static testMethod void checkComplete() {
       Test_Class_Job_Settings__c js = new Test_Class_Job_Settings__c();
        js.Name = 'Marketing';
        js.Active__c = true;
        js.SendCompletionEmail__c = true;
        js.Additional_Emails__c = 'cfreeman1@paychex.com';
        js.Test_Classes__c = 'SOAREmailHandlerTest';
        insert js;
        
       TestClassJob.TEST_LIMIT=1;
       Test.startTest();
       TestClassJob tcj = new TestClassJob(new Id[]{'7072F000000XvfqQAC'},0,Datetime.now());
       tcj.execute(null);
       Test.stopTest();
    } // checkComplete
    
    static testMethod void testSchedule() {
       Test.startTest();
       TestClassJob tcj = new TestClassJob(new Id[]{'7072F000000XvfqQAC'},0,Datetime.now());
       tcj.scheduleTestJob();
       Test.stopTest();
    } // testSchedule
    
} // TestClassJobTest