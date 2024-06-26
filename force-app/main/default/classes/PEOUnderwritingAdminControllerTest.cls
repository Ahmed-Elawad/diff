/* 
* Controller for the PEO Edge Underwriting Admin Lightning Component
*
* History
* -------
* 07/27/2021    Jake Hinds   Created
* 01/25/2022	Jake Hinds	 Document Management
*/
@isTest
public class PEOUnderwritingAdminControllerTest {
	@testSetup
    public static void setup(){
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'test',
                               LastName = 'con',
                               Email='testing@testing.com');
        insert c;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo');
        insert checklist;
        
        PEO_Onboarding_Checklist__c checklistChild = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo',Parent_PEO_Checklist__c=checklist.Id);
        insert checklistChild;
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=checklist.Id,Discrepancy_Type__c = 'Census');
        insert disc;
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Name = 'Census',Status__c='');
        insert doc;
        
        ContentVersion contentVersion1 = new ContentVersion(
                    Title          = 'test file 1',
                    PathOnClient   = 'testFile1.txt',
                    VersionData    = Blob.valueOf('Test File 1'),
                    IsMajorVersion = true);
        ContentVersion contentVersion2 = new ContentVersion(
                    Title          = 'test file 2',
                    PathOnClient   = 'testFile2.txt',
                    VersionData    = Blob.valueOf('Test File 2'),
                    IsMajorVersion = true);
        ContentVersion contentVersion3 = new ContentVersion(
                    Title          = 'test file 3',
                    PathOnClient   = 'testFile3.txt',
                    VersionData    = Blob.valueOf('Test File 3'),
                    IsMajorVersion = true);
        insert new ContentVersion[]{contentVersion1,contentVersion2,contentVersion3};

        List<ContentDocument> contentDocuments = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink[] cdls = new ContentDocumentLink[]{};
        for(ContentDocument cDoc:contentDocuments){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = doc.Id;
            cdl.ContentDocumentId = cDoc.Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            cdls.add(cdl);
        }
        insert cdls;
        
    }
    public static testMethod void testQueries(){
    	PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c=null LIMIT 1];
        Map<Id,PEO_Onboarding_Checklist__c> checklistMap = PEOUnderwritingAdminController.getAllChecklists(String.valueOf(checklist.Id));
        system.assertEquals(2,checklistMap.size());
        String[] checklistIds = new String[]{};
        for(PEO_Onboarding_Checklist__c checklistFromMap : checklistMap.values()){
            checklistIds.add(String.valueOf(checklistFromMap.Id));
        }
        
        PEO_Onboarding_Document_Discrepency__c[] discs = PEOUnderwritingAdminController.getAllDiscrepancies(checklistIds);
        system.assertEquals(1,discs.size());

        PEOUnderwritingAdminController.DocWrapper[] docWraps = PEOUnderwritingAdminController.getDocsApex(String.valueOf(checklist.Id));
        system.assertEquals(1,docWraps.size());
        system.assertEquals(3,docWraps[0].docLinks.size());
    }//testQueries
    public static testMethod void testUpdateDisc(){
    	PEO_Onboarding_Document_Discrepency__c[] discs = [SELECT Id,Status__c,Follow_Up_Date__c,additional_information__c FROM PEO_Onboarding_Document_Discrepency__c];
        PEO_Onboarding_Document_Discrepency__c updateDisc = new PEO_Onboarding_Document_Discrepency__c(Status__c='Closed',Follow_Up_Date__c=date.today(),additional_information__c='test');
        PEOUnderwritingAdminController.updateDiscrepanciesApex(updateDisc, discs);
        for(PEO_Onboarding_Document_Discrepency__c uDisc:[SELECT Id,Status__c,Follow_Up_Date__c,additional_information__c FROM PEO_Onboarding_Document_Discrepency__c]){
            system.assertEquals(updateDisc.Status__c, uDisc.Status__c);
            system.assertEquals(updateDisc.Follow_Up_Date__c, uDisc.Follow_Up_Date__c);
            system.assertEquals(updateDisc.additional_information__c, uDisc.additional_information__c);
        }
    }//testUpdateDisc
    public static testMethod void testFileManipulation(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c=null LIMIT 1];
        //will use this to transfer file to
        PEO_Onboarding_Document__c newDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Name = 'Payroll Report',Status__c='');
        insert newDoc;
        PEOUnderwritingAdminController.DocWrapper[] docWraps = PEOUnderwritingAdminController.getDocsApex(String.valueOf(checklist.Id));
        ContentDocumentLink linkToReparent = docWraps[0].docLinks[0];
        ContentDocumentLink linkToDelete = docWraps[0].docLinks[1];
        
        PEOUnderwritingAdminController.reparentFiles(new ContentDocumentLink[]{linkToReparent},String.valueOf(newDoc.Id));
        PEOUnderwritingAdminController.deleteFiles(new ContentDocumentLink[]{linkToDelete});
        
        PEOUnderwritingAdminController.DocWrapper[] uDocWraps = PEOUnderwritingAdminController.getDocsApex(String.valueOf(checklist.Id));
        system.assertEquals(2,uDocWraps.size());
        for(PEOUnderwritingAdminController.DocWrapper docWrap:uDocWraps){
            system.assertEquals(1,docWrap.docLinks.size());
        }        
    }
    public static testMethod void testDocApprove(){
    	PEO_Onboarding_Document__c doc = [SELECT Id FROM PEO_Onboarding_Document__c WHERE Status__c!='Approved'];
        PEOUnderwritingAdminController.approveDocRecord(doc.Id);
        PEO_Onboarding_Document__c uDoc = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id = :doc.Id];
        system.assertEquals('Approved',uDoc.Status__c);
    }
    public static testMethod void testSubmitToClientSpace(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c=null LIMIT 1];
        PEOUnderwritingAdminController.submitToClientSpace(checklist.Id,'Test');
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Submit_Docs_to_Clientspace__c FROM PEO_Onboarding_Checklist__c WHERE Id = :checklist.Id];
        system.assertEquals('Test',uChecklist.Submit_Docs_to_Clientspace__c);
    }
}