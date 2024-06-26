//Class to feed documents to clientspace
/*
 * HISTORY
 * -------
 * 05/07/2021  Matt Fritschi  Created
 * 
 * 
 * */

@isTest
public class ClientspaceAPIQueueableTest {
  @testSetup
     public static void setupTestData() {
       TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createTriggerSetting('PEOOnboardingChecklist', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
        TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
        insert classes;
        
        PEO_Onboarding_Document_Map__c peoMap = new PEO_Onboarding_Document_Map__c(Name='test',Description__c='test',Clientspace_Table__c='test',Clientspace_Field__c='test',Document_Category__c='test');
        insert peoMap;
        
        Map<String, String> docMapping = new Map<String, String>();
        List<String> docNames = new List<String>();
        docMapping.put('Census', 'Medical');
        docMapping.put('Claims Information', 'Medical');
        docMapping.put('Health Insurance Renewal', 'Medical');
        docMapping.put('Health Insurance Summary', 'Medical');
        docMapping.put('Health Invoice', 'Medical');
        docMapping.put('Other', 'Optional');
        docMapping.put('SUI Rate Forms', 'Risk');
        docMapping.put('WC Declarations Page', 'Risk');
        docMapping.put('Loss Runs', 'Risk');
        
        List<PEO_Onboarding_Document_Map__c> nameMaplst = new List<PEO_Onboarding_Document_Map__c>();
        for (String docName: docMapping.keySet()) {
            nameMaplst.add(new PEO_Onboarding_Document_Map__c(name=docName, Document_Category__c=docMapping.get(docName)));   
        }
        insert nameMaplst;
     }
    static testMethod void testDocSend(){
        Account acct = new Account(Name='test',CSCMContractStatus__c='Prospect');
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',Prospect_Client__c = acct.Id);
        insert checklist;
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Routing_Name__c='Census');
        insert doc;
        ContentVersion cdv = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test', description='Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=doc.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        
        Account acct2 = new Account(Name='testAccount2',CSCMContractStatus__c='Prospect');
        insert acct2;
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Name='testAccount2',Prospect_Client__c = acct2.Id,Sales_Rep__c = UserInfo.getUserId() ,Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical',Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp');
        insert checklist2;
        PEO_Onboarding_Document__c doc2 = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist2.Id,Routing_Name__c='Census');
        insert doc2;
        ContentVersion cdv2 = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test2', PathOnClient='c:\Test2', description='Test2');
        insert cdv2;
        ContentVersion cv2 = [Select ContentDocumentID from ContentVersion where id = :cdv2.id];
        contentDocumentLink cdl2 = new contentDocumentLink(ContentDocumentID = cv2.ContentDocumentID, LinkedEntityID=doc2.id, ShareType='V', Visibility='AllUsers' );
        insert cdl2;
        PEO_Onboarding_Document_Map__c HSFDM = new PEO_Onboarding_Document_Map__c(name='HSF Census', Document_Category__c='Medical', Clientspace_Table__c = 'gen_BenefitsBatch', Clientspace_Field__c='fuGAIHealthCensus');
        Insert HSFDM;
        
        test.startTest();
        TriggerMethods.clearVariables();
        doc.Status__c = 'Approved';
        update doc;
        doc2.Status__c = 'Approved';
        update doc2;
        checklist.Submit_Docs_to_Clientspace__c = 'All';
        checklist2.Submit_Docs_to_Clientspace__c = 'All';
        update checklist;
        update checklist2;
        ContentVersion cdv3 = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test3', PathOnClient='c:\Test3', description='Test3');
        insert cdv3;
        ContentVersion cv3 = [Select ContentDocumentID from ContentVersion where id = :cdv3.id];
        contentDocumentLink cdl3 = new contentDocumentLink(ContentDocumentID = cv3.ContentDocumentID, LinkedEntityID=doc2.id, ShareType='V', Visibility='AllUsers' );
        insert cdl3;
        doc2.Docs_Sent_to_Clientspace__c = cdl2.Id+',';
        doc2.Status__c = 'Approved';
        update doc2;
        checklist2.Submit_Docs_to_Clientspace__c = 'All';
        update checklist2;
        test.stopTest();
        
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Submit_Docs_to_Clientspace__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checkList.Id LIMIT 1];
        PEO_Onboarding_Checklist__c uChecklist2 = [SELECT Id,Submit_Docs_to_Clientspace__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checklist2.Id LIMIT 1];
        system.assertEquals(null,uChecklist.Submit_Docs_to_Clientspace__c);
        PEO_Onboarding_Document__c uDoc = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id=:doc.Id LIMIT 1];
        PEO_Onboarding_Document__c uDoc2 = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id=:doc2.Id LIMIT 1];
        system.assertEquals('Submitted to Clientspace',uDoc.Status__c);
    }
    
    //HSF
    /*static testMethod void testHSFDocSend(){
        Account acct = new Account(Name='test',CSCMContractStatus__c='Prospect');
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',Prospect_Client__c = acct.Id);
        insert checklist;
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Routing_Name__c='HSF Census');
        insert doc;
        ContentVersion cdv = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test', description='Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=doc.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        
        PEO_Onboarding_Document_Map__c HSFDM = new PEO_Onboarding_Document_Map__c(name='HSF Census', Document_Category__c='Medical', Clientspace_Table__c = 'gen_BenefitsBatch', Clientspace_Field__c='fuGAIHealthCensus');
        Insert HSFDM;
        
        test.startTest();
        TriggerMethods.clearVariables();
        doc.Status__c = 'Approved';
        update doc;
        checklist.HSF_Submission_Status__c = 'Submitted';
        update checklist;
        test.stopTest();
        
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Submit_Docs_to_Clientspace__c,HSF_Submission_Status__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checkList.Id LIMIT 1];
        //system.assertEquals(null,uChecklist.Submit_Docs_to_Clientspace__c);
        PEO_Onboarding_Document__c uDoc = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id=:doc.Id LIMIT 1];
        system.assertEquals('Submitted to Clientspace',uDoc.Status__c);
    }*/
    
    static testMethod void testGatherChecklistStateAndCodeFromAccount(){
        Account acct = new Account(Name='test',CSCMContractStatus__c='Prospect');
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',Prospect_Client__c = acct.Id);
        insert checklist;
        system.debug('clientspace checklist : ' + checklist);
        test.startTest();
        TriggerMethods.clearVariables();
        acct = [SELECT Id, Name, CSCMContractStatus__c FROM Account WHERE Id = :acct.Id LIMIT 1];
        acct.CSCMContractStatus__c = 'Approved';
        update acct;
        test.stopTest();
        
        system.debug('clientspace checklist Id : ' + checklist.Id);
        PEO_Underwriting_Code__c[] codes = [SELECT Id, Name, State__c, Description__c, FICA__c, FUTA__c, State_Disability_TDI_DBL_information__c, SUI_Pricing__c, Workers_Compensation__c FROM PEO_Underwriting_Code__c WHERE PEO_Underwriting_Checklist__c = :checklist.Id];
        system.debug('clientspace codes list : ' + codes);
        system.assertEquals(1,codes.size());
    }
    
    static testMethod void testCodeFromChecklistExistingCode(){
        Account acct = new Account(Name='test',CSCMContractStatus__c='Prospect');
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',Prospect_Client__c = acct.Id);
        insert checklist;
        system.debug('clientspace existcode checklist : ' + checklist);
        PEO_Underwriting_Code__c code = new PEO_Underwriting_Code__c(PEO_Underwriting_Checklist__c=checklist.Id, State_Name__c='FL',Name='8675', 
                                                                     Pricing_Batch_Id__c='10001', PB_State_Id__c='10003',PB_Code_Id__c='10005',Description__c='Test Comp Code Description',
                                                                     IsActive__c=false,FICA__c=5.00,FUTA__c=5.00,Workers_Compensation__c=5.00,
                                                                     Workers_Comp_Insurance__c=4.00,SUI_Pricing__c=5.00,
                                                                     State_Disability_TDI_DBL_information__c=10.00, AdminPercent__c= 18.42,
                                                                    CompCodeStatus__c ='New',FullTimeEmployees__c = 15,
                                                                    GrossPayroll__c = 123456.00, PartTimeEmployees__c = 5,
                                                                    PerHead__c = 1750, PerUnit__c = 1111, ClientReport__c= true, Set_up_fee__c = 223344);//in the fake json, the last field should be the one changing to test all of the other fields
        insert code;
        system.debug('clientspace code : ' + code);
        test.startTest();
        TriggerMethods.clearVariables();
        checklist.Pull_Clientspace_States_And_Codes__c = True;
        update checklist;
        test.stopTest();
        System.debug('clientspace testCodeFromChecklistExistingCode checklist:'+checklist.Id);
        PEO_Underwriting_Code__c[] codes = [SELECT Id, Name, State__c, Description__c, FICA__c, FUTA__c, State_Disability_TDI_DBL_information__c, SUI_Pricing__c, Workers_Compensation__c FROM PEO_Underwriting_Code__c WHERE PEO_Underwriting_Checklist__c = :checklist.Id];
        system.debug('clientspace codes testCodeFromChecklistExistingCode list : ' + codes);
        system.assertEquals(1,codes.size());
    }
}