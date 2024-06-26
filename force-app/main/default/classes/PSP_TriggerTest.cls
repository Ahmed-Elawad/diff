@isTest
public class PSP_TriggerTest {

    /*static testmethod void testCaseTriggers() {
        
        CreateTestData.createTestAandC();
        Account a1 = [select Id, Name, AccountNumber from Account where name = 'Test Account1'];
        Contact ctct1 = [select Id, Name from Contact where AccountId = :a1.Id and FirstName = 'First'];
        Case case1 = new Case (Subject = 'Test Case'
                               , AccountId = a1.Id
                               , Originator__c = ctct1.Id
                               , Assignment_Group__c = 'ES - PASS'
                               , Impact__c = '2 - Medium'
                               , Urgency__c = '2 - Medium'
                               , Business_Application__c = 'Other'
                               , Send_Case_to_Service_Now__c = TRUE
                               , Description = 'send to service now');
        insert case1;
        
        /*Attachment attach=new Attachment();    
        attach.Name='Unit Test Attachment';
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=case1.id;

        insert attach;
        
        CaseComment cmnt1 = new CaseComment(parentid = case1.id);
        insert cmnt1;
        
        ContentVersion cdv = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=case1.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        
        List<persp__psp_out_message__c> pOM = [select id from persp__psp_out_message__c where createdDate = Today];
        system.assertEquals(3,pOM.size());
    }
    
    */
    
}