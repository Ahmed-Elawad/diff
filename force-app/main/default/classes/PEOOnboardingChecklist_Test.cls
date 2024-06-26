/*
 * 06/15/2021 Jake Hinds      Created
 * 12/14/2021 Jake Hinds    Adding method for discrepancy count date
 * 02/07/2022 Jake Hinds			Removing audience
 * 09/23/22   Josh Cartwright   updated test to set values for CS satatus 
 * 01/22/24   Jidesh 		Added testResetQQDocs, testsetRequiredDocumentsWorkersComp for improving code covg
*/

@isTest
public class PEOOnboardingChecklist_Test {
    @testSetup
    public static void setup(){
        Referral_Account__c refAcc = new Referral_Account__c();
        refAcc.Name = 'Test';
        refAcc.Street_Address_1__c = 'Test';
        refAcc.Name = 'Test';
        refAcc.City__c = 'Test';
        refAcc.State_Province__c = 'NY';
        refAcc.Zip_Postal_Code__c = '12345';
        refAcc.Referral_Source_Business_Type__c = 'Strategic Account';
        refAcc.NBSC_SA_Partner__c = UserInfo.getUserId();
        insert refAcc;
        
        List<Account> Accs = new List<Account>();
        //Creating accounts for test
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        acc.Referral_National_Account__c = refAcc.Id;
        Accs.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Peo test2';
        acc2.ShippingState = 'Texas';
        Accs.add(acc2);
        insert Accs;
        
        //Creating contacts for test
        List<Contact> Conts = new List<Contact>();
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'test',
                               LastName = 'contact',
                               Email='testing@testing.com');
        Conts.add(c);
        Contact c2 = new Contact(AccountId=acc2.id,
                               FirstName = 'test',
                               LastName = 'contact2',
                               Email='testing2@testing.com');
        Conts.add(c2);
        insert Conts;
        
        //Creating checklists for test
        List<PEO_Onboarding_Checklist__c> Clists = new List<PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo',Sales_Rep__c = UserInfo.getUserId()
                                                                                ,Medical_Pre_Qualifier_Status__c = '', CS_CM_WC_UW_Status__c ='Approved'
                                                                                ,CS_CM_Contract_Status__c='Approved'
                                                                                ,Medical_Benefits_Underwriting_Requested__c ='No' );        
        //PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc2.id,Name='testing Peo2',Sales_Rep__c = UserInfo.getUserId(),Medical_Pre_Qualifier_Status__c = '');
        Clists.add(checklist);
        //Clists.add(checklist2);
        insert Clists;
        
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        
        User communityUsr = new User(
            UserName = c.email,
            FirstName = c.FirstName,
            LastName = c.LastName,
            Alias = 'alias',
            email = c.Email,
            ContactId = c.id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS'
        );
        insert communityUsr;
        
    }
    
    static testmethod void testQuickQuoteNBSCAssignment(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Name, Sales_Analyst__c, Route_to_Testing_Queue__c, Parent_PEO_Checklist__c, Prospect_Client__c, Sales_Rep__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        PEO_Edge_Queue_Districts__c peo = new PEO_Edge_Queue_Districts__c();
        peo.Name = 'Testing';
        insert peo;
        PEO_Edge_Queue_Districts__c peo2 = new PEO_Edge_Queue_Districts__c();
        peo2.Name = 'Qualifier';
        insert peo2;
        Group g1 = new Group(Name='Testing', type='Queue');
        insert g1;
        Group g2 = new Group(Name='Qualifier', type='Queue');
        insert g2;
        Test.startTest();
        List<PEO_Edge_Queue_Districts__c> possibleQueues = PEO_Edge_Queue_Districts__c.getAll().values();
        system.debug('++'+possibleQueues);
        PEOOnboardingChecklist_Handler.QuickQuoteNBSCAssignment(chkList);
        Test.stopTest();
    }
    
    static testmethod void testPostHSACensusFailChatter(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Name, Parent_PEO_Checklist__c, Prospect_Client__c, Sales_Rep__c, HSF_Submission_Response__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        chkList[0].HSF_Submission_Status__c = 'Fail';
        chkList[0].HSF_Submission_Response__c = 'Test';
        Test.startTest();
        PEOOnboardingChecklist_Handler.postHSACensusFailChatter(chkList);
        Test.stopTest();
    }
    
    static testmethod void testClearPrevCensusInfo(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Name, Parent_PEO_Checklist__c, Prospect_Client__c, Sales_Rep__c, HSF_Submission_Response__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
        doc.Name='Census';
        doc.PEO_Onboarding_Checklist__c=chkList[0].Id;
        doc.Routing_Name__c='Census';
        doc.Status__c = 'Submitted to Clientspace';
        doc.Docs_Sent_to_Clientspace__c = 'Yes';
        insert doc;
        Test.startTest();
        PEOOnboardingChecklist_Handler.clearPrevCensusInfo(chkList);
        Test.stopTest();
    }
    
    static testmethod void testCreateChatterMentionPostWithProspectMention(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Name, Parent_PEO_Checklist__c, Prospect_Client__c, Sales_Rep__c, HSF_Submission_Response__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        List<Id> userId = new List<Id>();
        userId.add(UserInfo.getUserId());
        Test.startTest();
        PEOOnboardingChecklist_Handler.createChatterMentionPostWithProspectMention(chkList[0].Id, chkList[0].Prospect_Client__c, userId, false, true, 'WC', 'None');
        Test.stopTest();
    }
    
    static testmethod void testSendDiscrepancyEmailFuture(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Name, Parent_PEO_Checklist__c, Prospect_Client__c, Sales_Rep__c, HSF_Submission_Response__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        List<Id> chkId = new List<Id>();
        chkId.add(chkList[0].Id);
        Test.startTest();
        PEOOnboardingChecklist_Handler.sendDiscrepancyEmailFuture(chkId);
        Test.stopTest();
    }
    
    static testmethod void testSendChatterPostEmail(){
        List<PEO_Onboarding_Checklist__c> chkList = [SELECT Id, Prospect_Client__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        Test.startTest();
        PEOOnboardingChecklist_Handler.sendChatterPostEmail(chkList);
        Test.stopTest();
    }
    
    static testMethod void testMedicalPreqSubmissionCheck(){
        User runningUser = [SELECT ID, Name FROM User WHERE ProfileName__c='System Administrator' AND UserPermissionsKnowledgeUser=true LIMIT 1];
        System.runAs(runningUser) {
            Account acctB = new Account(Name = 'ChildTestAccountCommunities', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                        BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST');
            insert acctB;
            PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctB.Id);
            insert peoOnbChecklist;
            List<PEO_Onboarding_Checklist__c> parentPeoOnbCheck = [SELECT Id, Name, Med_pre_qual_submission__c, Prospect_Client__c FROM PEO_Onboarding_Checklist__c ];
            List<PEO_Onboarding_Medical_Questionnaire__c> medQuest = new List<PEO_Onboarding_Medical_Questionnaire__c>();
            User tanya = [SELECT Id,Name,Username FROM User WHERE Username LIKE '%lobb%' limit 1];
            Map<id,PEO_Onboarding_Checklist__c> checklist = new Map<id,PEO_Onboarding_Checklist__c>();
            List<PEO_Onboarding_Document__c> docList = new List<PEO_Onboarding_Document__c>();
            Account acc = [Select Id, Name from Account limit 1];
            Id profileId = null;
            for(Integer i=0; i<parentPeoOnbCheck.size(); i++){
                if(i == 0){
                    PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck[i].Id, Years_with_current_carrier__c=10, Past_medical_carrier_if_applicable__c='No', Renewal_date__c=System.today(), Client_Id_user_agreement_acknowledgment__c =profileId);
                    medQuest.add(medQuestionnaire);
                    checklist.put(parentPeoOnbCheck[i].Id, parentPeoOnbCheck[i]);
                }
                else{
                    PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck[i].Id, Years_with_current_carrier__c=10, Past_medical_carrier_if_applicable__c='No', Renewal_date__c=System.today(), Client_Id_user_agreement_acknowledgment__c =tanya.Id);
                    medQuest.add(medQuestionnaire);
                    checklist.put(parentPeoOnbCheck[i].Id, parentPeoOnbCheck[i]);
                }
            } 
            Knowledge__kav kTest = new Knowledge__kav(Title='Census'
                                                      ,Article_Body__c='<span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">The Census documents the demographics of the prospect&#39;s group to assess the potential risk and assign a rate band. Demographic information includes:</span></span></span></span></span> <ul><li style="margin-left: 8px;margin-bottom: 11px;"><span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">Name</span></span></span></span></span></li><li style="margin-left: 8px;margin-bottom: 11px;"><span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">Birth date</span></span></span></span></span></li><li style="margin-left: 8px;margin-bottom: 11px;"><span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">Gender</span></span></span></span></span></li><li style="margin-left: 8px;margin-bottom: 11px;"><span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">ZIP code</span></span></span></span></span></li><li style="margin-left: 8px;margin-bottom: 11px;"><span style="font-size: 14px;"><span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">Health insurance coverage level</span></span></span></span></span></li></ul> <span style="font-size: 14px;"> <span style="line-height: 107%;"><span style="font-family: Calibri,sans-serif;"><span style="line-height: 107%;"><span style="color: #313537;">This information must be completed for all<span class="msoDel" style="text-decoration: line-through;"><span style="color: red;"><del> </del></span></span> <b><i>full-time employees</i></b> (30+ hours per week), their <b><i>dependents</i></b>, and those who are <b><i>COBRA eligible</i></b> or current <b><i>COBRA participants</i></b>.</span></span></span></span></span><br>'
                                                      ,Hover_Description__c='Documents business demographics, including all full-time employees (30+ hours per week) and all dependents currently enrolled in medical plan, as well as those who are COBRA-eligible or current COBRA participants.'
                                                      ,UrlName = 'CensusTest'
                                                      ,ClientSpace_Field__c='Census');
            insert kTest;
            ContentVersion contentVersion = new ContentVersion(Title = 'Test File', PathOnClient = 'TestFile.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
            insert contentVersion;  
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            kTest = [select Id, ArticleNumber, KnowledgeArticleId, PublishStatus, Article_Body__c, Hover_Description__c, UrlName, ClientSpace_Field__c, Title from Knowledge__kav where id = : kTest.id];
            List<Knowledge__kav> kav = [select Id, ArticleNumber, KnowledgeArticleId, PublishStatus, Article_Body__c, Hover_Description__c, UrlName, ClientSpace_Field__c, Title from Knowledge__kav where id = : kTest.id];
            String articleId = kTest.KnowledgeArticleId;
            KbManagement.PublishingService.publishArticle(articleId, true);
            
            for(Integer i=0; i<parentPeoOnbCheck.size(); i++){
                PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
                doc.PEO_Onboarding_Checklist__c = parentPeoOnbCheck[i].Id;
                doc.Name = 'Census';
                doc.Routing_Name__c = 'Census';
                doc.Status__c = 'Submitted by Prospect';
                doc.Parent_Account__c = acc.Id;
                docList.add(doc);
            }
            insert docList;
            
            insert medQuest;
            ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = docList[0].Id, ContentDocumentId = documents[0].Id, shareType = 'V');
            insert cdl;
            Boolean returnVal = PEOOnboardingChecklist_Handler.medicalPreqSubmissionCheck(checklist);
            System.assertEquals(true, returnVal);
        }
    }//testMedicalPreqSubmissionCheck
    
    public static testMethod void testUpdateDocReqdStatus(){
        //List<PEO_Onboarding_Checklist__c> checkListBeforeInsert, Map<id,PEO_Onboarding_Checklist__c> checkListBeforeUpdate
        List<PEO_Onboarding_Checklist__c> checkListBeforeInsert = [Select Id, Name, Prospect_Client__c,Additional_Misc_Documents_Required__c, Parent_PEO_Checklist__c, 
                                                                   Is_Medical_Underwriting_Requested__c, Is_Your_Plan_Self_Funded_or_Level_Funded__c,Medical_Quick_Quote_Eligibility__c	
                                                                   ,Workers_Comp_Quick_Quote_Eligibility__c from PEO_Onboarding_Checklist__c LIMIT 1]; 
        Map<id,PEO_Onboarding_Checklist__c> checklistMap = new Map<id,PEO_Onboarding_Checklist__c>();
        /*PEO_Onboarding_Medical_Questionnaire__c mq = new PEO_Onboarding_Medical_Questionnaire__c();
        mq.PEO_Onboarding_Checklist__c = checkListBeforeInsert[0].Id;
        mq.claims_exp_available__c = 'Yes';
        Insert mq;
        List<PEO_Onboarding_Medical_Questionnaire__c> medQuestnrs = [SELECT claims_exp_available__c,Id,Name,PEO_Onboarding_Checklist__c 
                                                                     FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c IN: checkListBeforeInsert];
        */
        //system.debug('checkListBeforeInsert:'+checkListBeforeInsert);
        for(PEO_Onboarding_Checklist__c cl:checkListBeforeInsert){
            /*cl.Medical_Benefits_Underwriting_Requested__c = 'Yes';
            cl.Current_Medical_Coverage_Provided__c = 'Yes';
            cl.Has_Self_or_Level_Funded_Plan__c = 'Yes';
            cl.Number_of_Enrolled_Employees__c = 65;
            cl.Health_Benefits_Currently_through_a_PEO__c = 'Yes';
            cl.medical_coverage_renewal_date__c = Date.today();
            cl.Workers_Comp_FastPass__c = 'Yes';*/
            cl.Medical_Underwriting_Path_Type__c = 'Traditional - Medical';
            cl.Workers_Comp_Underwriting_Path_Type__c = 'Clientspace Forced - Workers Comp';
            cl.medical_coverage_renewal_date__c = Date.today();
            cl.Currently_using_a_PEO__c = 'Yes';
        }
        Test.startTest();
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Name = 'Traditional - Medical';
        reqDoc.Additional_Misc_Documents_Required__c = true;
        reqDoc.Benefit_Summaries_Required__c = true;
        insert reqDoc;
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc2 = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc2.Name = 'Clientspace Forced - Workers Comp';
        reqDoc2.Additional_Misc_Documents_Required__c = true;
        reqDoc2.Benefit_Summaries_Required__c = true;
        reqDoc2.Health_Insurance_Renewal_Required__c = true;
        
        reqDoc2.Health_Insurance_Renewal_Required__c = true;
        reqDoc2.Health_Invoice_Required__c = true;
        reqDoc2.Loss_Runs_Required__c = true;
        reqDoc2.Medical_Invoice_Required__c = true;
        reqDoc2.Miscellaneous_Docs_Required_WC__c = true;
        reqDoc2.Payroll_Register_Required__c = true;
        reqDoc2.SUI_Required__c = true;
        reqDoc2.WC_Classes_And_Wages_Required__c = true;
        reqDoc2.WC_Declarations_Required__c = true;
        reqDoc2.WC_RatesAndPricing_Required__c = true;
        insert reqDoc2;
        //insert new PEO_Medical_Workers_Comp_UW_Path__c(Name = 'Traditional - Medical', Additional_Misc_Documents_Required__c = true);  
        //insert new PEO_Medical_Workers_Comp_UW_Path__c(Name = 'Traditional - Workers Comp', Benefit_Summaries_Required__c = true);
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(checkListBeforeInsert,checklistMap, checklistMap);
        system.assertEquals(checkListBeforeInsert[0].Additional_Misc_Documents_Required__c,true);
        Test.stopTest();
    }
    public static testMethod void testUpdateDocReqdStatus2(){
        List<PEO_Onboarding_Checklist__c> chkList = [Select Id, Name, Prospect_Client__c,Additional_Misc_Documents_Required__c, Parent_PEO_Checklist__c,
                                                     Is_Medical_Underwriting_Requested__c, Is_Your_Plan_Self_Funded_or_Level_Funded__c,Medical_Quick_Quote_Eligibility__c	
                                                     ,Workers_Comp_Quick_Quote_Eligibility__c from PEO_Onboarding_Checklist__c LIMIT 1]; 
        Map<id,PEO_Onboarding_Checklist__c> checklistMap = new Map<id,PEO_Onboarding_Checklist__c>();
        chkList[0].Medical_Underwriting_Path_Type__c = 'Salesforce Forced - Medical';
        chkList[0].Workers_Comp_Underwriting_Path_Type__c = 'Salesforce Forced - Workers Comp';
        chkList[0].medical_coverage_renewal_date__c = Date.today();
        chkList[0].Currently_using_a_PEO__c = 'Yes';
        Test.startTest();
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Name = 'Salesforce Forced - Medical';
        reqDoc.Additional_Misc_Documents_Required__c = true;
        reqDoc.Benefit_Summaries_Required__c = true;
        insert reqDoc;
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(chkList,checklistMap, checklistMap);
        system.assertEquals(chkList[0].Additional_Misc_Documents_Required__c,true);
        Test.stopTest();
    }
    
    public static testMethod void testUpdateDocReqdStatus3(){
        List<PEO_Onboarding_Checklist__c> chkList = [Select Id, Name, Prospect_Client__c,Additional_Misc_Documents_Required__c, Parent_PEO_Checklist__c,
                                                     Is_Medical_Underwriting_Requested__c, Is_Your_Plan_Self_Funded_or_Level_Funded__c,Medical_Quick_Quote_Eligibility__c	
                                                     ,Workers_Comp_Quick_Quote_Eligibility__c from PEO_Onboarding_Checklist__c LIMIT 1]; 
        Map<id,PEO_Onboarding_Checklist__c> checklistMap = new Map<id,PEO_Onboarding_Checklist__c>();
        chkList[0].Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical';
        chkList[0].Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp';
        chkList[0].medical_coverage_renewal_date__c = Date.today();
        chkList[0].Currently_using_a_PEO__c = 'No';
        Test.startTest();
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Name = 'Quick Quote - Medical';
        reqDoc.Additional_Misc_Documents_Required__c = true;
        reqDoc.Benefit_Summaries_Required__c = true;
        insert reqDoc;
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(chkList,checklistMap, checklistMap);
        system.assertEquals(chkList[0].Additional_Misc_Documents_Required__c,true);
        
        Test.stopTest();
    }
    
    public static testMethod void testUpdateDocReqdStatus4(){
        List<PEO_Onboarding_Checklist__c> chkList = [Select Id, Name, Prospect_Client__c,Additional_Misc_Documents_Required__c, Parent_PEO_Checklist__c,
                                                     Is_Medical_Underwriting_Requested__c, Is_Your_Plan_Self_Funded_or_Level_Funded__c,Medical_Quick_Quote_Eligibility__c	
                                                     ,Workers_Comp_Quick_Quote_Eligibility__c from PEO_Onboarding_Checklist__c LIMIT 1]; 
        Map<id,PEO_Onboarding_Checklist__c> checklistMap = new Map<id,PEO_Onboarding_Checklist__c>();
        chkList[0].Medical_Underwriting_Path_Type__c = 'Clientspace Forced - Medical';
        chkList[0].Workers_Comp_Underwriting_Path_Type__c = 'Clientspace Forced - Workers Comp';
        chkList[0].medical_coverage_renewal_date__c = Date.today();
        chkList[0].Currently_using_a_PEO__c = 'No';
        chkList[0].CS_Benefits_Summaries_Required__c = true;
        chkList[0].CS_Census_Required__c = true;
        chkList[0].CS_Health_Insurance_Summary_Required__c = true;
        chkList[0].CS_Health_Insurance_Renewal_Required__c = true;
        chkList[0].CS_Claims_Report_Required__c = true;
        chkList[0].CS_Medical_Invoice_Required__c = true;
        
        Test.startTest();
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Name = 'Clientspace Forced - Medical';
        reqDoc.Additional_Misc_Documents_Required__c = true;        
        reqDoc.Benefit_Summaries_Required__c = true;
        insert reqDoc;
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(chkList,checklistMap, checklistMap);
        system.assertEquals(chkList[0].Benefit_Summaries_Required__c,true);
        chkList[0].CS_Benefits_Summaries_Required__c = false;
        chkList[0].CS_Census_Required__c = false;
        chkList[0].CS_Health_Insurance_Summary_Required__c = false;
        chkList[0].CS_Health_Insurance_Renewal_Required__c = false;
        chkList[0].CS_Claims_Report_Required__c = false;
        chkList[0].CS_Medical_Invoice_Required__c = false;
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(chkList,checklistMap, checklistMap);
        system.assertEquals(chkList[0].Benefit_Summaries_Required__c,false);
        Test.stopTest();
    }
    
    public static testMethod void testSetAllRequiredDocuments(){
        List<PEO_Onboarding_Checklist__c> chkList = [Select Id, Additional_Misc_Documents_Required__c, Benefit_Summaries_Required__c,
                                                     CensusRequired__c, Miscellaneous_Docs_Required__c, Claims_Report_Required__c,
                                                     Health_Insurance_Renewal_Required__c, Health_Invoice_Required__c, Loss_Runs_Required__c,
                                                     Medical_Invoice_Required__c, Miscellaneous_Docs_Required_WC__c, Payroll_Register_Required__c,
                                                     SUI_Required__c, WCClassesWages_Required__c, WC_Declarations_Required__c,
                                                     WC_RatesAndPricing_Required__c, medical_coverage_renewal_date__c, Currently_using_a_PEO__c,
                                                     Workers_Comp_Quick_Quote_Eligibility__c from PEO_Onboarding_Checklist__c LIMIT 1];
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Additional_Misc_Documents_Required__c = true;
        reqDoc.Benefit_Summaries_Required__c = true;
        reqDoc.Census_Required__c = true;
        reqDoc.Miscellaneous_Docs_Required_Medical__c = true;
        reqDoc.Claims_Report_Required__c = true;
        reqDoc.Health_Insurance_Renewal_Required__c = true;
        reqDoc.Health_Invoice_Required__c = true;
        reqDoc.Loss_Runs_Required__c = true;
        reqDoc.Medical_Invoice_Required__c = true;
        reqDoc.Miscellaneous_Docs_Required_WC__c = true;
        reqDoc.Payroll_Register_Required__c = true;
        reqDoc.SUI_Required__c = true;
        reqDoc.WC_Classes_And_Wages_Required__c = true;
        reqDoc.WC_Declarations_Required__c = true;
        reqDoc.WC_RatesAndPricing_Required__c = true;
        Test.startTest();
        PEOOnboardingChecklist_Handler.setAllRequiredDocuments(chkList[0],reqDoc, false, null);
        test.stopTest();
    }
    public static testMethod void getUploadedDocsTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id,Prospect_Client__c FROM PEO_Onboarding_Checklist__c limit 1];
        //chkList.WCClassesWages_Required__c = true;
        //update chkList;
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
        doc.Name='WC Classes and Wages';
        doc.PEO_Onboarding_Checklist__c = chkList.Id;
        insert doc;
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S';
        cVersion.Title = 'Test';
        cVersion.PathOnClient = 'Test';
        cVersion.VersionData = Blob.valueof('Test');
        Insert cVersion;
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = conDocument;
        link.LinkedEntityId = doc.Id;
        insert link;
        Set<Id> checkListIds = new Set<Id>();
        checkListIds.add(chkList.Id);
        Test.startTest();
        Map<Id, Boolean> docsMap = PEOOnboardingChecklist_Handler.getUploadedDocs(checkListIds);
        system.assertEquals(docsMap.get(chkList.Id), true);
        Test.stopTest();
    }
    
    /*public static testMethod void testUpdateDocReqdStatus2(){
        List<PEO_Onboarding_Checklist__c> checkListBeforeInsert = [Select Id,Additional_Misc_Documents_Required__c,
                                                                   Parent_PEO_Checklist__c, Is_Medical_Underwriting_Requested__c, Is_Your_Plan_Self_Funded_or_Level_Funded__c 
                                                                   from PEO_Onboarding_Checklist__c]; 
        Map<id,PEO_Onboarding_Checklist__c> checklistMap = new Map<id,PEO_Onboarding_Checklist__c>();
        for(PEO_Onboarding_Checklist__c cl:checkListBeforeInsert){
            cl.Medical_Underwriting_Path_Type__c = 'Traditional - Medical';
            cl.Workers_Comp_Underwriting_Path_Type__c = 'Traditional - Workers Comp';
        }
        insert new PEO_Medical_Workers_Comp_UW_Path__c(Name = 'Traditional - Workers Comp', Additional_Misc_Documents_Required__c = true);  
        PEOOnboardingChecklist_Handler.updateDocReqdStatus(checkListBeforeInsert,checklistMap, checklistMap);
        system.assertEquals(checkListBeforeInsert[0].Additional_Misc_Documents_Required__c,true);
        
    }*/
    
    public static testMethod void testDiscEmail(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Send_Discrepancy_Email__c FROM PEO_Onboarding_Checklist__c LIMIT 1];
        checklist.Send_Discrepancy_Email__c = 'Sales Rep';
        update checklist;
        
        Task[] tsk = [SELECT id FROM Task WHERE WhatId = :checklist.Id];
        system.assertEquals(1,tsk.size());
        

        
        //tsk = [SELECT id FROM Task WHERE WhatId = :checklist.Id];
        //system.assertEquals(2,tsk.size());
    }//testDiscEmail
        
    public static testMethod void testNSC(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Prospect_Client__c,Prospect_Client__r.Name FROM PEO_Onboarding_Checklist__c];
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opp = new Opportunity(Name='test',StageName='Pending',CloseDate=date.today(),RecordTypeId=rt.getRecordTypeId(),AccountId=checklist.Prospect_Client__c);
        insert opp;
        OpportunityTeamMember otm = new OpportunityTeamMember(UserId=UserInfo.getUserId(),TeamMemberRole='PEO NSC',OpportunityId=opp.Id);
        insert otm;
        
        Test.startTest();
        //random update to check the nsc field
        checklist.Name = 'test';
        update checklist;
        Test.stopTest();
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Opportunity__c FROM PEO_Onboarding_Checklist__c where Id = :checklist.Id];
        system.assertEquals(opp.Id,uChecklist.Opportunity__c);
    }//testNSC
    
    public static testMethod void testOwnerSync(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Prospect_Client__c,Prospect_Client__r.Name,OwnerId FROM PEO_Onboarding_Checklist__c];  
        PEO_Onboarding_Checklist__c childChecklist = new PEO_Onboarding_Checklist__c(OwnerId=checklist.OwnerId,Prospect_Client__c=checklist.Prospect_Client__c,Name='testing Peo Child',
                                                                                     Sales_Rep__c = UserInfo.getUserId(),Parent_PEO_Checklist__c=checklist.Id);
        insert childChecklist;
        
        Test.startTest();
        User newOwner = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id <> :checklist.OwnerId LIMIT 1];
        checklist.OwnerId = newOwner.Id;
        update checklist;
        
        Test.stopTest();
        
        PEO_Onboarding_Checklist__c uChild = [SELECT Id,OwnerId FROM PEO_Onboarding_Checklist__c WHERE Id=:childChecklist.Id];
        system.assertEquals(newOwner.Id,uChild.OwnerId);
    }//testOwnerSync
    static testMethod void testMedicalUWCreate(){
        Account acct = new Account(Name='test acct1');
        Account acct2 = new Account(Name='test acct2');
        List<Account> accts = new Account[]{acct,acct2};
        insert accts;

        Opportunity opp = new Opportunity(Name='test opp1',AccountId=acct.Id,CloseDate=date.today(),StageName='Pending');
        Opportunity opp2 = new Opportunity(Name='test opp2',AccountId=acct2.Id,CloseDate=date.today(),StageName='Pending');
        List<Opportunity> opps = new Opportunity[]{opp,opp2};
        insert opps;
        
        Test.startTest();
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acct.Id,Opportunity__c=opp.Id,Is_Medical_Underwriting_Requested__c = 'Currently have Medical, please quote');
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acct2.Id,Opportunity__c=opp2.Id);
        List<PEO_Onboarding_Checklist__c> checklists = new PEO_Onboarding_Checklist__c[]{checklist,checklist2};
            insert checklists;
        
        checklist2.Is_Medical_Underwriting_Requested__c = 'Currently have Medical, please quote';
        checklist2.CS_CM_Implementation_Date__c =system.today();
        update checklist2;
        
        PEO_Onboarding_Checklist__c[] uChecklists = [SELECT Id,Reference_PEO_Medical_UW__c FROM PEO_Onboarding_Checklist__c WHERE Reference_PEO_Medical_UW__c != null];
        system.assertEquals(uChecklists.size(),2);
        
        Test.stopTest();
    }
    
    static testMethod void testcheckMedStatus(){
        //checkMedStatus(Map<Id, PEO_Onboarding_Checklist__c> oldChecklistMap, Map<Id, PEO_Onboarding_Checklist__c> newChecklistMap)
        //Medical_Pre_Qualifier_Status__c = 'Approved'
        User runningUser = [SELECT ID, Name FROM User WHERE ProfileName__c='System Administrator' AND UserPermissionsKnowledgeUser=true LIMIT 1];
        Account acc = [Select Id, Name from Account where Name = 'Peo test2' limit 1];
        List<PEO_Onboarding_Checklist__c> checklist = [SELECT Id,Name,Sales_Analyst__c, Sales_Rep__c,Community_User__c,Medical_Pre_Qualifier_Status__c,Prospect_Client__c,Prospect_Client__r.Name,OwnerId FROM PEO_Onboarding_Checklist__c]; 
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo2',Sales_Rep__c = UserInfo.getUserId(),Medical_Pre_Qualifier_Status__c = '');
        insert checklist2;
        Map<Id, PEO_Onboarding_Checklist__c> oldChecklistMap  = new Map<Id, PEO_Onboarding_Checklist__c>();
        oldChecklistMap.put(checklist[0].Id, checklist[0]);
        oldChecklistMap.put(checklist2.Id, checklist2);
        Map<Id, PEO_Onboarding_Checklist__c> newChecklistMap  = new Map<Id, PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c checklist2upd = new PEO_Onboarding_Checklist__c(Id = checklist2.Id,Prospect_Client__c = checklist2.Prospect_Client__c,Medical_Pre_Qualifier_Status__c = 'Approved', Community_User__c = runningUser.Id, Sales_Rep__c = runningUser.Id, Sales_Analyst__c= runningUser.Id);
        system.debug('checklist2upd:'+checklist2upd);
        newChecklistMap.put(checklist[0].Id, checklist[0]);
        newChecklistMap.put(checklist2.Id, checklist2upd);
        
        Test.startTest();
        PEOOnboardingChecklist_Handler.checkMedStatus(oldChecklistMap,newChecklistMap);
        Test.stopTest();
    }
    
    static testMethod void updateChecklistStatusToCompleteTest() {
        List<PEO_Onboarding_Checklist__c> checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c];
        Set<ID> IdSet = new Set<Id>();
        for (PEO_Onboarding_Checklist__c chk : checklist ) {
            IdSet.add(chk.Id);
        }
        Test.StartTest();
        PEOOnboardingChecklist_Handler.updateChecklistStatusToComplete(IdSet); 
        Test.StopTest();
        List<PEO_Onboarding_Checklist__c> checklistsUpdated = [SELECT Id, Current_Step__c FROM PEO_Onboarding_Checklist__c];
        Boolean failedToUpdateStatus = false;
        for (PEO_Onboarding_Checklist__c chk : checklistsUpdated ) {
            if (chk.Current_Step__c != 'Completed') failedToUpdateStatus = true;
        }
        
        System.assertEquals(false, failedToUpdateStatus);
    }
    static testMethod void testDiscrepancyCount(){
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test');
        insert checklist;
        checklist.Number_of_Open_Medical_Discrepancies__c = 1;
        update checklist;
        PEO_Onboarding_Checklist__c uChecklist = [SELECT id,Most_Recent_Open_Discrepancy__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checklist.Id LIMIT 1];
        system.assertNotEquals(null,uChecklist.Most_Recent_Open_Discrepancy__c);
        
        checklist.Number_of_Open_Medical_Discrepancies__c = 0;
        update checklist;
        uChecklist = [SELECT id,Most_Recent_Open_Discrepancy__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checklist.Id LIMIT 1];
        system.assertEquals(null,uChecklist.Most_Recent_Open_Discrepancy__c);
    }
    static testMethod void sendChatterForRejectedChecklistTest() {
        List<PEO_Onboarding_Checklist__c> checklist = [SELECT Id ,Medical_Benefits_Underwriting_Requested__c ,CS_CM_Medical_UW_Status__c, CS_CM_WC_UW_Status__c, CS_CM_Contract_Status__c,  Current_Step__c, Completed_Status_Date__c FROM PEO_Onboarding_Checklist__c];
        Map<Id, PEO_Onboarding_Checklist__c> idMap = new Map<Id, PEO_Onboarding_Checklist__c>();
        Set<Id> IdSet = new Set<Id>();
        for (PEO_Onboarding_Checklist__c chk : checklist ) {
            idMap.put(chk.Id, chk);
            IdSet.add(chk.Id);
        }

        PEOOnboardingChecklist_Handler.sendChecklistCurrentStepValueUpdate(idMap);  
        PEOOnboardingChecklist_Handler.sendChatterForRejectedChecklist(IdSet);
    }
    /*static testMethod void testSANotification(){
        User[] chatterUsers = [SELECT id FROM User WHERE Id!=:UserInfo.getUserId() AND Profile.Name = 'System Administrator' AND IsActive = true LIMIT 5];
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',OwnerId=chatterUsers[2].Id,Sales_Rep__c=chatterUsers[0].Id,
                                                                                Sales_Analyst__c=chatterUsers[2].Id);
        insert checklist;
        
        test.startTest();
        checklist.OwnerId = chatterUsers[3].Id;
        checklist.PEO_Sales_Notes__c = 'test';
        checklist.Workers_Comp_Sales_Notes__c = 'test';
        checklist.Financial_Underwriting_Sales_Notes__c = 'test';
        checklist.Pricing_Console_Notes__c = 'test';
        update checklist;
        system.assertEquals(true,PEOOnboardingChecklist_Handler.saNotificationPosted);
        test.stopTest();
    }*/
    
    public static testMethod void testSalesAnalystNotification(){
        List<PEO_Onboarding_Checklist__c> checklist = [SELECT Id, Sales_Rep__c, Sales_Analyst__c, Sales_Analyst__r.ManagerId, Prospect_Client__r.Name FROM PEO_Onboarding_Checklist__c LIMIT 1];
        checklist[0].PEO_Sales_Notes__c = 'Test';
        checklist[0].Workers_Comp_Sales_Notes__c = 'Test';
        checklist[0].Financial_Underwriting_Sales_Notes__c = 'Test';
        checklist[0].Pricing_Console_Notes__c = 'Test';
        checklist[0].PEO_Sales_Notes__c = 'Test';
        Test.startTest();
        PEOOnboardingChecklist_Handler.salesAnalystNotification(checklist);
        system.assertEquals(true,PEOOnboardingChecklist_Handler.saNotificationPosted);
        Test.StopTest();
    }
    
    public static testMethod void testNoNotifications(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Send_Discrepancy_Email__c, CS_CM_Contract_Status__c, Last_Change_Made__c FROM PEO_Onboarding_Checklist__c LIMIT 1];
        checklist.CS_CM_Contract_Status__c = 'Approved';
        update checklist;
    }
    
    public static testMethod void testSendHSFStatusUpdateChatter(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id, Prospect_Client__c, View_in_Clientspace__c FROM PEO_Onboarding_Checklist__c LIMIT 1];
        checklist.Sales_Rep__c = UserInfo.getUserId();
        Test.startTest();
        PEOOnboardingChecklist_Handler.sendHSFStatusUpdateChatter('Success', checklist);
        Test.stopTest();
    }
    
    public static testMethod void testSendHSFStatusUpdateChatter2(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id, Prospect_Client__c  FROM PEO_Onboarding_Checklist__c LIMIT 1];
        checklist.Sales_Rep__c = UserInfo.getUserId();
        checklist.HSF_Submission_Response__c = 'Test';
        Test.startTest();
        PEOOnboardingChecklist_Handler.sendHSFStatusUpdateChatter('FAIL', checklist);
        Test.stopTest();
    }
    //testNoNotifications
    
    public static testMethod void testResetQQDocs(){
        //fetching checklist
        //add QQ_Reset_Date__c in below query if needed
        PEO_Onboarding_Checklist__c checklist = [SELECT Id, Prospect_Client__c, Sales_Analyst__c, Sales_Rep__c,
                                                 Additional_Misc_Documents_Required__c, Benefit_Summaries_Required__c, CensusRequired__c, Miscellaneous_Docs_Required__c,
                                                 Is_Your_Plan_Self_Funded_or_Level_Funded__c, Parent_PEO_Checklist__c,Claims_Report_Required__c, Health_Insurance_Renewal_Required__c,
                                                 Health_Invoice_Required__c, Loss_Runs_Required__c, Is_Medical_Underwriting_Requested__c,
                                                 Medical_Invoice_Required__c, Miscellaneous_Docs_Required_WC__c, Payroll_Register_Required__c, SUI_Required__c,
                                                 WCClassesWages_Required__c, WC_Declarations_Required__c, WC_RatesAndPricing_Required__c, medical_coverage_renewal_date__c, 
                                                 Currently_using_a_PEO__c, Workers_Comp_Underwriting_Path_Type__c
                                                 FROM PEO_Onboarding_Checklist__c LIMIT 1];
        //creating doc
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
        doc.Name='Census';
        doc.PEO_Onboarding_Checklist__c= checklist.Id;
        doc.Routing_Name__c='Census';
        doc.Status__c = 'Submitted to Clientspace';
        doc.Docs_Sent_to_Clientspace__c = 'Yes';
        doc.Date_Uploaded__c = DateTime.now();
        insert doc;
        Test.startTest();
        //checklist.QQ_Reset_Date__c = DateTime.now();
        checklist.Sales_Analyst__c = UserInfo.getUserId();
        checklist.Sales_Rep__c = UserInfo.getUserId();
        Update checklist;
        System.debug('Updated checklist:'+checklist);
        PEO_Onboarding_Checklist__c[] checklists = new List<PEO_Onboarding_Checklist__c>();    
        checklists.add(checklist);
        User usr = [Select id,Name from user where id=:UserInfo.getUserId() limit 1];
        Map<id,User> userMap = new Map<id,User>();
        userMap.put(usr.Id, usr);
        System.debug('checklists before pass:'+checklists);
        PEOOnboardingChecklist_Handler.qqApprovedNotification(checklists, userMap);
        PEO_Onboarding_Checklist__c checklistRet = [SELECT Id, Prospect_Client__c,CS_CM_Contract_Status__c
                                                 FROM PEO_Onboarding_Checklist__c where id=:checklist.Id LIMIT 1];
        system.assertEquals('Approved',checklistRet.CS_CM_Contract_Status__c);
        Test.stopTest();
    }
    
    public static testMethod void testsetRequiredDocumentsWorkersComp(){
        List<Account> Accs = new List<Account>();
        Referral_Account__c refAcc = new Referral_Account__c();
        refAcc.Name = 'Test';
        refAcc.Street_Address_1__c = 'Test';
        refAcc.Name = 'Test';
        refAcc.City__c = 'Test';
        refAcc.State_Province__c = 'NY';
        refAcc.Zip_Postal_Code__c = '12345';
        refAcc.Referral_Source_Business_Type__c = 'Strategic Account';
        refAcc.NBSC_SA_Partner__c = UserInfo.getUserId();
        insert refAcc;
        //Creating accounts for test
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        acc.Referral_National_Account__c = refAcc.Id;
        Accs.add(acc);
        Account acc2 = new Account();
        acc2.Name = 'Peo test2';
        acc2.ShippingState = 'Texas';
        Accs.add(acc2);
        insert Accs;
        
        //Creating contacts for test
        List<Contact> Conts = new List<Contact>();
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'test',
                               LastName = 'contact',
                               Email='testing@testing.com');
        Conts.add(c);
        Contact c2 = new Contact(AccountId=acc2.id,
                               FirstName = 'test',
                               LastName = 'contact2',
                               Email='testing2@testing.com');
        Conts.add(c2);
        insert Conts;
        
        //Creating checklists for test
        List<PEO_Onboarding_Checklist__c> Clists = new List<PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo',Sales_Rep__c = UserInfo.getUserId()
                                                                                ,Medical_Pre_Qualifier_Status__c = '', CS_CM_WC_UW_Status__c ='Approved'
                                                                                ,CS_CM_Contract_Status__c='Approved'
                                                                                ,Medical_Benefits_Underwriting_Requested__c ='No',Workers_Comp_Underwriting_Path_Type__c='Clientspace Forced - Workers Comp');        
        PEO_Medical_Workers_Comp_UW_Path__c reqDoc = new PEO_Medical_Workers_Comp_UW_Path__c();
        reqDoc.Name = 'Traditional - Medical';
        reqDoc.Additional_Misc_Documents_Required__c = true;
        reqDoc.Benefit_Summaries_Required__c = true;
        reqDoc.Census_Required__c = true;
        reqDoc.Miscellaneous_Docs_Required_Medical__c = true;
        reqDoc.Claims_Report_Required__c = true;
        insert reqDoc;
        Clists.add(checklist2);
        insert Clists;
        Test.startTest();
        Map<Id, Boolean> docsMap = new Map<Id, Boolean>();
        PEO_Onboarding_Checklist__c chkRet1 = PEOOnboardingChecklist_Handler.setRequiredDocumentsWorkersComp(checklist2, reqDoc, docsMap);
        //system.assertEquals('Approved',checklistRet.CS_CM_Contract_Status__c);
        //System.debug('checklists chkRet1:'+chkRet1);
        checklist2.Workers_Comp_Underwriting_Path_Type__c='Salesforce Forced - Workers Comp';
        update checklist2;
        PEO_Onboarding_Checklist__c chkRet2 = PEOOnboardingChecklist_Handler.setRequiredDocumentsWorkersComp(checklist2, reqDoc, docsMap);
        //System.debug('checklists chkRet2:'+chkRet2);
        system.assertEquals(false,chkRet2.CensusRequired__c);
        system.assertNotEquals(true,chkRet2.Medical_Invoice_Required__c);
        checklist2.Workers_Comp_Underwriting_Path_Type__c='Traditional - Workers Comp';
        update checklist2;
        PEO_Onboarding_Checklist__c chkRet3 = PEOOnboardingChecklist_Handler.setRequiredDocumentsWorkersComp(checklist2, reqDoc, docsMap);
        //System.debug('checklists chkRet3:'+chkRet3);
        system.assertEquals(false,chkRet2.Benefit_Summaries_Required__c);
        Test.stopTest();
    }
    
    static testmethod void testResetQQDocuments(){
        PEO_Onboarding_Checklist__c checklist  = [SELECT Id, QQ_Reset_Date__c FROM PEO_Onboarding_Checklist__c LIMIt 1];
        checklist.QQ_Reset_Date__c = system.now();
        Test.StartTest();
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
        doc.PEO_Onboarding_Checklist__c = checklist.Id;
        doc.Name = 'Census';
        doc.Status__c = 'Submitted by Prospect';
        doc.Date_Uploaded__c = system.now();
        insert doc;
        update checklist;
        PEO_Onboarding_Document__c d = [SELECT Id, Status__c FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c =: checklist.Id];
        system.assertEquals('Approved', d.Status__c);
        Test.StopTest();
    }
}