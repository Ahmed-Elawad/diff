/* 
 *  Test for ContentDocumentUtilities.
 *   
 * History
 * -------
 * 06/16/2016 Justin Stouffer Created
 * 03/15/2021 Jacob Hinds		PEO doc linking
   07/23/2021 Dan Carmen      Updated to only push PEO Docs through handleContentDocumentDeleteActions
   09/17/2021 Matt Fritschi		Added testChatterPostForDocUpload

*/

@isTest
public class ContentDocumentUtilitiesTest {
    
    static testMethod void testBasicLinkFunction(){
		account testAccount = new Account(Name='UploadTestAccount');
        insert testAccount;
        Schema.RecordTypeInfo caseESRrt = RecordTypeHelper.getRecordType('Service Support ESR Case', 'Case');
		case testCase = new Case(RecordTypeId = caseESRrt.getRecordTypeId(),Subject = 'Test', Description = 'test', accountID=testAccount.id);        
        insert testCase;
        Document_Link__c dl = new Document_Link__c(case__c=testCase.id,link__c='WWW.TestLink.Com');
        insert dl;
        List<ESR_Document__c> esrDs = [Select id,(select id, 
                                           Case__c, 
                                           ESR_Document__c, 
                                           Link__c from Document_Links__r ) 
                                from ESR_Document__c where Account__c = :testAccount.id];
        system.assertEquals(1, esrDs.size());
        system.assertEquals(1, esrDs[0].Document_Links__r.size());
        system.assertEquals(esrDs[0].Document_Links__r[0].id, dl.id);
        Document_Link__c dl2 = new Document_Link__c(case__c=testCase.id,link__c='WWW.TestLink2.Com');
        insert dl2;
        esrDs = [Select id,(select id, 
                                           Case__c, 
                                           ESR_Document__c, 
                                           Link__c from Document_Links__r
                           				   order by createdDate ASC) 
                                from ESR_Document__c where Account__c = :testAccount.id];
        system.assertEquals(1, esrDs.size());
        system.assertEquals(2, esrDs[0].Document_Links__r.size());
    }
    
    static testMethod void testBasicFileFunction(){
		account testAccount = new Account(Name='UploadTestAccount');
        insert testAccount;
        Schema.RecordTypeInfo caseESRrt = RecordTypeHelper.getRecordType('Service Support ESR Case', 'Case');
		case testCase = new Case(RecordTypeId = caseESRrt.getRecordTypeId(),Subject = 'Test', Description = 'test', accountID=testAccount.id);        
        insert testCase;
        contentVersion cdv = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=testCase.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        List<ESR_Document__c> esrDs = [Select id
                                from ESR_Document__c where Account__c = :testAccount.id];
        list<contentDocumentLink> cdls = [Select contentDocumentID, LinkedEntityID from contentDocumentLink where contentDocumentId=:cv.ContentDocumentID];
        system.assertEquals(1, esrDs.size());
        system.assertEquals(3, cdls.size());
        contentVersion cdv2 = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test2', PathOnClient='c:\Test');
        insert cdv2;
        ContentVersion cv2 = [Select ContentDocumentID from ContentVersion where id = :cdv2.id];
        reference_HNBF__C refHNBF = new reference_HNBF__c(case_Number__c=testCase.id);
        insert refHNBF;
        contentDocumentLink cdl2 = new contentDocumentLink(ContentDocumentID = cv2.ContentDocumentID, LinkedEntityID=refHNBF.id, ShareType='V', Visibility='AllUsers' );
        insert cdl2;
        esrDs = [Select id from ESR_Document__c where Account__c = :testAccount.id];
        cdls = [Select contentDocumentID, LinkedEntityID from contentDocumentLink where contentDocumentId=:cv2.ContentDocumentID];
        system.assertEquals(1, esrDs.size());
        system.assertEquals(3, cdls.size());
    }
    static testMethod void testPEODoc(){
        PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c();
        insert parentChecklist;
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentChecklist.Id);
        insert doc;
        //HSF testing
        PEO_Onboarding_Document__c doc2 = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentChecklist.Id, Status__c='Approved', Name='HSF Census');
        insert doc2;
        contentVersion cdv = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=doc.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        contentDocumentLink cd2 = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=doc2.id, ShareType='V', Visibility='AllUsers' );
        insert cd2;
        PEO_Onboarding_Document__c uDoc = [SELECT id,Status__c FROM PEO_Onboarding_Document__c WHERE Id = :doc.Id LIMIT 1];
        system.assertEquals('Submitted by Prospect', uDoc.Status__c);
    }
    
    static testMethod void testHandleContentDocumentDeleteActions(){
       PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c();
        insert parentChecklist;
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentChecklist.Id);
        insert doc;
        
        contentVersion cdv = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test', Onboarding_Document_Id_fileupload__c=doc.Id);
        insert cdv;
        
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=parentChecklist.Id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        
        PEO_Onboarding_Document__c uDoc = [SELECT id,Status__c FROM PEO_Onboarding_Document__c WHERE Id = :doc.Id LIMIT 1];
        List<contentDocumentLink> conDocLink = new List<contentDocumentLink>([SELECT Id, LinkedEntityID FROM ContentDocumentLink WHERE LinkedEntityID = :doc.Id AND ContentDocumentID = :cv.ContentDocumentID]);
        ContentDocumentUtilities.handleContentDocumentDeleteActions(conDocLink);
        System.assertEquals(conDocLink.size(), 1);
        system.assertEquals('Submitted by Prospect', uDoc.Status__c); 
    }
    
    @isTest(SeeAllData=true)
    static void testChatterPostForDocUpload(){
        User rep = [Select Id, FirstName, LastName, Email from User where Job_Name__c = :UserHelper.JOB_REP and IsActive=true limit 1];
        PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c(Sales_Rep__c=rep.Id);
        insert parentChecklist;
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentChecklist.Id);
        insert doc;
        
        contentVersion cdv = new contentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test', Onboarding_Document_Id_fileupload__c=doc.Id);
        insert cdv;
        
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=parentChecklist.Id, ShareType='V', Visibility='AllUsers' );
        
        Test.startTest();
        insert cdl;
        Test.stopTest();
        
        list<feedItem> fItemList = [Select Id, Body from feedItem where parentId = :parentChecklist.Id];
        system.assertEquals(fItemList.size(),1);
    } //testChatterPostForDocUpload
    
}