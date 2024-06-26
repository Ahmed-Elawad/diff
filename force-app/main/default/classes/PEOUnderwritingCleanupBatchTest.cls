/* 
Clear out uploaded documents that are no longer needed

History
-------
08/20/2021     Jake Hinds  Created

*/

@isTest
public class PEOUnderwritingCleanupBatchTest {
    @testSetup
    public static void setup(){
    }
    static testMethod void testPurgeDoc(){
        Account acct = new Account(Name='test acct');
        insert acct;
        
		Opportunity oppty = new Opportunity(Name='test opp',AccountId=acct.Id,CloseDate=date.today().addDays(-300),StageName='Pending');
        insert oppty;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c= acct.Id,Opportunity__c=oppty.Id);
        insert checklist;
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(Name='Census',PEO_Onboarding_Checklist__c=checklist.Id,Status__c='Submitted to Clientspace');
        insert doc;
        
    	ContentVersion cv=new Contentversion();
        cv.title='test';
        cv.PathOnClient ='test';
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.Onboarding_Document_Id_fileupload__c = doc.Id;
        insert cv;
        
        Test.startTest();
        
        PEOUnderwritingCleanupBatch peoUCB = new PEOUnderwritingCleanupBatch();
        Database.executeBatch(peoUCB,10);
        
        Test.stopTest();
        
        ContentVersion[] cvs = [SELECT Id FROM ContentVersion WHERE Id =:cv.Id];
        system.assert(cvs.isEmpty());
        
        PEO_Onboarding_Document__c uDoc = [SELECT Status__c FROM PEO_Onboarding_Document__c WHERE Id =:doc.Id LIMIT 1];
        system.assertEquals('Purged',uDoc.Status__c);
    }
    static testMethod void testScheduler() {
      TestHelper.testScheduler('PEOUnderwritingCleanupBatch', new PEOUnderwritingCleanupBatch());
   } // testScheduler
}