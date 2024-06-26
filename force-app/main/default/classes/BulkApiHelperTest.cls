/* 
   Test methods for BulkApiHelper class
   
  History
  -------
  12/31/2020 Dan Carmen   Created

 */
@isTest
public with sharing class BulkApiHelperTest {

   static testMethod void testCreateBulkJob() {
      String csv = 'FirstName,LastName\nJimmy,Test';
      ContentVersion cv = new ContentVersion();
      cv.title = 'Data csv.csv';
      cv.PathOnClient ='Data csv.csv';
      cv.VersionData =Blob.valueOf(csv);
      insert cv;

      ContentVersion dataContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :cv.Id];
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK1;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 
      String jobId = null;
      Test.startTest();
      jobId = BulkApiHelper.createBulkJob('Contact', 'insert', dataContent.ContentDocumentId);
      Test.stopTest();
      System.assertEquals(BulkAPIMock.JOB_ID,jobId);
     
   } // testCreateBulkJob
    
   static testMethod void testCheckJobStatus() {
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK2;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 
      Test.startTest();
      BulkApiHelper.checkJobStatus(BulkAPIMock.JOB_ID);
      Test.stopTest();
       
      System.assertEquals(BulkApiHelper.STATE_INPROGRESS,BulkApiHelper.jobState);
      System.assertEquals(4,BulkApiHelper.recsProcessed);
      System.assertEquals(1,BulkApiHelper.recsFailed);
      System.assertEquals(1313,BulkApiHelper.totalProcessingTime);

   } // testCheckJobStatus
    
   static testMethod void testGetResults() {
      DataLoadMethods.SKIP_TRIGGER=true;
      // create a record to save the results against.
      DataLoad__c dataLoad = new DataLoad__c(Name='Test Name', FileType__c='TestType');
      insert dataLoad;
       
      BulkAPIMock.MOCK_VERSION = BulkAPIMock.MOCK3;
      Test.setMock(HttpCalloutMock.class, new BulkAPIMock()); 
      Test.startTest();
      BulkApiHelper.getResults(BulkAPIMock.JOB_ID, dataLoad.Id);
      Test.stopTest();
       
      // should be 2 files attached
      System.assertEquals(2,[select count() from ContentDocumentLink where LinkedEntityId=:dataLoad.Id and ContentDocument.FileExtension='csv']);

   } // testGetResults

} // class BulkApiHelperTest