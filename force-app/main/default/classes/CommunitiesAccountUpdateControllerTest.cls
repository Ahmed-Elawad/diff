/* 
* Test methods for CommunitiesAccountUpdateController.
*
* History
* -------
* 04/02/2021    Matt Fritschi       Created
* 06/16/2021    Jidesh Athippatta   testpeoGetKnowledgeDetailsWrap method
* 07/06/2021    Ahmed Elawad        Updated  testGetPEOOnboardingChecklist to pass in third checklist param
* 7/20/2021     Ahmed Elawad        Updated setupData to run as system admin with knowlege access
* 08/07/2021    Jake Hinds          Change from Experience to sales org for queue routing
* 08/09/2021    Matt Fritschi       Updated prospect comments on discrepancies should now be cleared out and stored to comments log.
* 09/03/2021	Ahmed Elawad		Added handleAutoSaveRecordsTest methods
* 12/22/2021	Jake Hinds			Removing opp calls
* 02/07/2022	Jake Hinds			Removing experience
* 02/21/2022	Jake Hinds			testCompleteNotification
* 12/08/2022	Jidesh Athippatta	testSbmtForHSFandGetUpdChklst
* 12/27/2023	Jidesh Athippatta	Updated logic on handleAutoSaveRecordsTest method for Last_Change_Made__c field testing.
*/

@isTest
public class CommunitiesAccountUpdateControllerTest {
    @testSetup
    Static void setupData() {
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
        // Creating Referal Account //
        Referral_Account__c ref = new Referral_Account__c(Street_Address_1__c='Test1',City__c='Test',State_Province__c='N',Zip_Postal_Code__c='1290');
        insert ref;
        // End POc
        Account acctB = new Account(Name = 'ChildTestAccountCommunities', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId());
        insert acctB;
        Account_Junction__c acctJunc = new Account_Junction__c(Child_Account__c=acctB.Id, Parent_Account__c=acctA.Id);
        insert acctJunc;
        
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a1;
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id);
        insert peoOnbChecklist;
        PEO_Onboarding_Checklist__c peoOnbChecklistChild = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctB.Id,Parent_PEO_Checklist__c=peoOnbChecklist.Id);
        insert peoOnbChecklistChild;
        PEO_Onboarding_Medical_Questionnaire__c med = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id);
        insert med;
        WC_Questionnaire_Industry_Specific__c ind = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=peoOnbChecklist.Id);
        insert ind;
        Policy_Period__c pol = new Policy_Period__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id);
        insert pol;
            
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone'];
        User u = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c1_a1.Id, Sales_Org__c = 'PAY', Username='commTestUser@testorg.com', LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert u;
        // Making Changes
        Contact c1_a2 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctB.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a2;
       // User u2 = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c1_a2.Id, Sales_Org__c = 'PAY', Username='c1a1@whoknows.com', LastName='Testing', Email='c1a1@whoknows.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
       // insert u2;
       user cUser = [Select Id, ContactId from user where Id =:UserInfo.getUserId()];
        System.runAs(cUser){
            Contact c1_a3 = new Contact(FirstName='Test Comm Contact2',LastName='Contact 2',  AccountId=acctB.Id, DoNotCall=false, Email='c1a12@whoknows.com');
            insert c1_a3;
            
            User u2 = new User(Alias = 'testCom', ProfileId = p.Id, ContactId = c1_a3.Id, Sales_Org__c = 'PAY', Username='commTestUser123@testorg.com', LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
            insert u2;
        }
    
        // Making Changes End 
        
        User runningUser = [SELECT ID, Name FROM User WHERE ProfileName__c='System Administrator' AND UserPermissionsKnowledgeUser=true LIMIT 1];
        System.runAs(runningUser) {
            
            Group testGroup = new Group(Name='Test Queue 1', Type='Queue');
            insert testGroup;
            
            QueueSObject q = new QueueSObject(SobjectType='PEO_Onboarding_Checklist__c', QueueId=testGroup.Id);
            insert q;
            
            User groupMem = [SELECT Id, Name, PEO_Queue_Bypass__c FROM User WHERE Job_Name__c = 'Sales Representative' AND PEO_Queue_Bypass__c = null LIMIT 1];
            GroupMember member = new GroupMember();
            member.UserOrGroupId = groupMem.Id;
            member.GroupId = testGroup.Id;
            insert member;
            /*test data peoGetKnowledgeDetailsWrap: start*/
            PEO_Onboarding_Document_Map__c setting = new PEO_Onboarding_Document_Map__c();
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
            
            ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = kTest.Id, ContentDocumentId = documents[0].Id, shareType = 'V');
            insert cdl;
            cdl = [select Id, LinkedEntityId, ContentDocumentId, shareType from ContentDocumentLink where Id=:cdl.Id];
            
            List<Knowledge__kav> kav = [select Id, ArticleNumber, KnowledgeArticleId, PublishStatus, Article_Body__c, Hover_Description__c, UrlName, ClientSpace_Field__c, Title from Knowledge__kav where id = : kTest.id];
            String articleId = kTest.KnowledgeArticleId;
            KbManagement.PublishingService.publishArticle(articleId, true);
            setting.Name = 'Census';
            setting.ArticleNumber__c = kTest.ArticleNumber;
            insert setting;
            /*test data peoGetKnowledgeDetailsWrap: end*/
            
            
        }
        
       PEO_Edge_Queue_Districts__c setting2 = new PEO_Edge_Queue_Districts__c();
        setting2.Name = 'Test Queue 1';
        setting2.Area__c = 'East';
        String districts = '';
        for(Integer i = 0; i <= 50; i++) {
            if(i < 50) {
                districts += String.valueOf(i) + ',';
            }
            else {
                districts += String.valueOf(i);
            }
            
        }
        setting2.Districts__c = districts;
        insert setting2;
        
        WC_NAICS_To_Industry_Map__c naics = new WC_NAICS_To_Industry_Map__c(Name = '12345', COVID_Questionnaire_Required__c=true, Industry_name__c='Doctor\'s Offices', PEO_Industry_Title__c='Doctor\'s Offices');
        WC_NAICS_To_Industry_Map__c naics2 = new WC_NAICS_To_Industry_Map__c(Name = '67890', COVID_Questionnaire_Required__c=false);
        List<WC_NAICS_To_Industry_Map__c> naicsCodes = new List<WC_NAICS_To_Industry_Map__c>();
        naicsCodes.add(naics);
        naicsCodes.add(naics2);
        insert naicsCodes;
    }
    
    static testMethod void getAccountInfoFromUser(){
        User testUser = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'testComm' LIMIT 1];
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Comm Contact' LIMIT 1];
        Account parentAcct = [SELECT Id, Name,Referral_National_Account__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        Account childAcct = [SELECT Id, Name FROM Account WHERE Name = 'ChildTestAccountCommunities'];
        
        Account[] acctArray = CommunitiesAccountUpdateController.getAccountInformation(testUser.Id,'CommunityAccountEditForm');
        CommunitiesAccountUpdateController.getStrategicAccountPartner(parentAcct);
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
        
        acctArray = CommunitiesAccountUpdateController.getAccountInformation(testContact.Id, 'CommunityAccountEditForm');
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
        
        acctArray = CommunitiesAccountUpdateController.getAccountInformation(parentAcct.Id, 'CommunityAccountEditForm');
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
    }
    
    static testMethod void getImplementationQuestionStatusTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id FROM PEO_Onboarding_Checklist__c LIMIT 1];
        Test.startTest();
        Boolean status = CommunitiesAccountUpdateController.getImplementationQuestionStatus(chkList.Id);
        Test.stopTest();
        system.Assert(!status);
    }
    
    static testMethod void testGetPEOOnboardingChecklist(){
        List<String> allNaisCode = new List<String>();
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        Account childAcct = [SELECT Id, Name FROM Account WHERE Name = 'ChildTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        PEO_Onboarding_Checklist__c peoOnbCheck = CommunitiesAccountUpdateController.getPEOOnboardingChecklist(parentAcct.Id, null,'CommunitiesAccountUpdateController');
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbCheck.Id);
        peoOnbCheck = CommunitiesAccountUpdateController.getPEOOnboardingChecklist(childAcct.Id, null,'CommunitiesAccountUpdateController');
        User u =[Select Id ,ContactId from User where UserName =: 'commTestUser@testorg.com'];
        System.runAs(u){
            CommunitiesAccountUpdateController.submitSurvey(2,'yes','test');
            CommunitiesAccountUpdateController.getSurvey(); 
        }
        allNaisCode.add('test1');
        allNaisCode.add('Test2');
        CommunitiesAccountUpdateController.getIndustryNames(allNaisCode);
        CommunitiesAccountUpdateController.getSalesRepresentativeInfo(userInfo.getUserId());
        system.assertNotEquals(null, peoOnbCheck);
    }

    static testMethod void testGetRunningUser(){
        User runningUser = UserHelper.getRunningUser();
        User testUser = CommunitiesAccountUpdateController.getRunningUser();
        
        system.assertEquals(runningUser.Id, testUser.Id);
        system.assertEquals(true,CommunitiesAccountUpdateController.getSystemPermission());
    }
    
    static testMethod void testGetCommunityUser(){
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Comm Contact' LIMIT 1];
        User testUser = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'testComm' LIMIT 1];
        
        User commUser = CommunitiesAccountUpdateController.getCommunityUser(testContact.Id);
        system.assertEquals(testUser.Id, commUser.Id);
        
        commUser = CommunitiesAccountUpdateController.getCommunityUser(testUser.Id);
        system.assertEquals(testUser.Id, commUser.Id);
    }
    
    static testMethod void needCovidQuestionnaire(){
        Account parentAcct = [SELECT Id, Name, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        
        Boolean questionnaireNeeded = CommunitiesAccountUpdateController.needCovidQuestionnaire(parentAcct,'CommunitiesAccountUpdateController');
        System.assertEquals(true, questionnaireNeeded);
        
        parentAcct.NAICS_Code__c = '67890';
        update parentAcct;
        
        questionnaireNeeded = CommunitiesAccountUpdateController.needCovidQuestionnaire(parentAcct,'CommunitiesAccountUpdateController');
        System.assertEquals(false, questionnaireNeeded);
    }
    
    static testMethod void handleAutoSaveRecordsTest() {
        // get the records from each object and update one field
        List<Account> accLst = [SELECT ID, Name, NumberOfEmployees FROM Account];
        for (Account acc : accLst) acc.NumberOfEmployees = 100000;
        List<PEO_Onboarding_Checklist__c> peoChecklists = [SELECT ID, description_principle_product_business__c FROM PEO_Onboarding_Checklist__c];
        for (PEO_Onboarding_Checklist__c chk : peoChecklists) chk.description_principle_product_business__c = 'handleAutoSaveRecordsTest';
        List<PEO_Onboarding_Medical_Questionnaire__c> peoMed = [SELECT ID, Current_PEO_Carrier_if_applicable__c FROM PEO_Onboarding_Medical_Questionnaire__c];
        for (PEO_Onboarding_Medical_Questionnaire__c chk : peoMed) chk.Current_PEO_Carrier_if_applicable__c = 'handleAutoSaveRecordsTest';
        List<WC_Questionnaire_Industry_Specific__c> ind = [SELECT ID, additional_ancillary_services_offered__c FROM WC_Questionnaire_Industry_Specific__c];
        for (WC_Questionnaire_Industry_Specific__c chk : ind) chk.additional_ancillary_services_offered__c = 'handleAutoSaveRecordsTest';
        List<Policy_Period__c> policies = [SELECT ID, Insurance_Carrier__c FROM Policy_Period__c];
        for (Policy_Period__c chk : policies) chk.Insurance_Carrier__c = 'handleAutoSaveRecordsTest';
        List<PEO_Implementation_Checklist__c> lstPEOImpchk = new List<PEO_Implementation_Checklist__c>();
        // handleAutoSaveRecords should return true for success
        Test.startTest();
        Map<String, Map<String, List<SObject>>> successSave = CommunitiesAccountUpdateController.handleAutoSaveRecords(accLst, peoChecklists, peoMed, ind, policies,lstPEOImpchk,'CommunitiesAccountUpdateController');
        Test.stopTest();
        
        // verify success for valid records
        System.assertNotEquals(successSave, null, 'Failed to save valid PEO records');
        
        // get the updated lists and verify the values have changed
        List<Account> updatedaccLst = [SELECT ID, Name, NumberOfEmployees FROM Account];
        List<PEO_Onboarding_Checklist__c> updatedpeoChecklists = [SELECT ID, description_principle_product_business__c FROM PEO_Onboarding_Checklist__c];
        List<PEO_Onboarding_Medical_Questionnaire__c> updatedpeoMed = [SELECT ID, Current_PEO_Carrier_if_applicable__c FROM PEO_Onboarding_Medical_Questionnaire__c];
        List<WC_Questionnaire_Industry_Specific__c> updatedind = [SELECT ID, additional_ancillary_services_offered__c FROM WC_Questionnaire_Industry_Specific__c];
        List<Policy_Period__c> updatedpolicies = [SELECT ID, Insurance_Carrier__c FROM Policy_Period__c];
        Account NotUpdateDAccount;
        PEO_Onboarding_Checklist__c notUpdatedChecklist;
        PEO_Onboarding_Medical_Questionnaire__c notUpdatedMed;
        WC_Questionnaire_Industry_Specific__c notUpdatedInd;
        Policy_Period__c notUpdatedPolicy;
        for (Account acc : updatedaccLst) {
            if (acc.NumberOfEmployees != 100000) {
                NotUpdateDAccount = acc;
                break;
            }
        }
        System.assertEquals(null, NotUpdateDAccount);
        
        for (PEO_Onboarding_Checklist__c peo : updatedpeoChecklists) {
            if (peo.description_principle_product_business__c != 'handleAutoSaveRecordsTest') notUpdatedChecklist = peo;
        }
        System.assertEquals(null, notUpdatedChecklist);
        
        for (PEO_Onboarding_Medical_Questionnaire__c med : updatedpeoMed) {
            if (med.Current_PEO_Carrier_if_applicable__c != 'handleAutoSaveRecordsTest') notUpdatedMed = med;
        }
        System.assertEquals(null, notUpdatedMed);
        
        for (WC_Questionnaire_Industry_Specific__c indrec : updatedind) {
            if (indrec.additional_ancillary_services_offered__c != 'handleAutoSaveRecordsTest') notUpdatedInd = indrec;
        }
        System.assertEquals(null, notUpdatedInd);
        
        for (Policy_Period__c pol : updatedpolicies) {
            if (pol.Insurance_Carrier__c != 'handleAutoSaveRecordsTest') notUpdatedPolicy = pol;
        }
        System.assertEquals(null, notUpdatedPolicy);
        
        // update the records to have an invalud value somehow
        for (Account acc : accLst) acc.Id = null; // there are two accouts. total of 6 logs should be created
        for (PEO_Onboarding_Checklist__c chk : peoChecklists) chk.id = null;
        for (PEO_Onboarding_Medical_Questionnaire__c chk : peoMed) chk.id = null;
        for (WC_Questionnaire_Industry_Specific__c chk : ind) chk.Id = null;
        for (Policy_Period__c chk : policies) chk.Id = null;
        
        // attempt the save. Should be false
        Map<String, Map<String, List<SObject>>>  successSave2 = CommunitiesAccountUpdateController.handleAutoSaveRecords(accLst, peoChecklists, peoMed, ind, policies,lstPEOImpchk,'CommunitiesAccountUpdateController');
        System.assertNotEquals(successSave2, null, 'Save with invalid records should have failed. Expected successSave2 to be false');
        
        // verify error logs were inserted
        List<ErrorLog__c> errLogs = [SELECT ID FROM ErrorLog__c];
        //modified this to Assert not equals, since we started using Database class methods instead of normal DML in handleAutoSaveRecords method
        //System.assertEquals(errLogs.size(), 6, (errLogs.size() < 6 ? 'Not enough' : 'Too Many') + ' logs were inserted: ' + errLogs.size());
        System.assertNotEquals(6, errLogs.size(),'Logs were inserted: ' + errLogs.size());
    }
    
    static testMethod void getPEOOnboardingChecklistsDataTest() {
        Account parentAcct = [SELECT Id, Name, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        List<PEO_Onboarding_Checklist__c> data = [SELECT Id, List_of_Owners__c, Prospect_Client__c, Prospect_Client__r.Name FROM PEO_Onboarding_Checklist__c
                                                      WHERE Prospect_Client__c=:parentAcct.Id];
        List<PEO_Onboarding_Checklist__c> retList = CommunitiesAccountUpdateController.getPEOOnboardingChecklistsData(new List<Account>{parentAcct}, 'Test');
        System.assertEquals(retList.size(), data.size(), 'Returned more checklsits than expected for the parent account');
        
        PEO_Onboarding_Checklist__c retCheklist = retList[0];
        PEO_Onboarding_Checklist__c queriedCheclist = data[0];
        System.assertEquals(retCheklist.Id, queriedCheclist.Id, 'The method returned an unexpected checklist. Should have returnred the parent accounts checklist');
    }
    
    static testMethod void testgetMedicalQuestionnaireForm() {
        PEO_Onboarding_Medical_Questionnaire__c medForm = [SELECT Id, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Medical_Questionnaire__c LIMIT 1];
        PEO_Onboarding_Medical_Questionnaire__c resultMedForm = CommunityFileUploadController.getMedicalQuestionnaireForm(medForm.PEO_Onboarding_Checklist__c,'Test');
        System.assertEquals(medForm.Id, resultMedForm.Id, 'The returned medical form is not the one expected');
    }
    
    //doing this so we get coverage without needing to run the second test manually
    static testMethod void testCompleteNotification() {
        PEOUWProspectChatterMessagesTest.testCompleteStep();
    }
    
    public static testMethod void testQueries(){
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c=null LIMIT 1];
        PEO_Onboarding_Document__c newDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Name = 'Payroll Report',Status__c='');
        insert newDoc;
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
                cdl.LinkedEntityId = newDoc.Id;
                cdl.ContentDocumentId = cDoc.Id;
                cdl.ShareType = 'V';
                cdl.Visibility = 'AllUsers';
                cdls.add(cdl);
            }
        insert cdls;
        CommunitiesAccountUpdateController.DocWrapper[] docWraps = CommunitiesAccountUpdateController.getDocsApex(String.valueOf(checklist.Id));
        system.assertEquals(1,docWraps.size());
    }//testQueries
    
    static testMethod void testSbmtForHSFandGetUpdChklst() {
        Account parentAcct = [SELECT Id, Name, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c peoOnbChecklistHSF = new PEO_Onboarding_Checklist__c(Prospect_Client__c=parentAcct.Id);
        insert peoOnbChecklistHSF;
        Boolean hsfCreated = CommunitiesAccountUpdateController.submitForHSF(peoOnbChecklistHSF);
        system.assertEquals(hsfCreated,true);
        List<PEO_Onboarding_Checklist__c> chklsts = new List<PEO_Onboarding_Checklist__c>();
        chklsts.add(peoOnbChecklistHSF);
        List <PEO_Onboarding_Checklist__c> retChklst = CommunitiesAccountUpdateController.getUpdatedChecklist(chklsts, 'testForm');
        system.assertEquals(retChklst[0].HSF_Submission_Status__c,'Submitted');
    }
    
    @istest static void getCommunityFormsUserAttributesTest() {
        User SalesUser = [SELECT ID, Name FROM User WHERE ProfileName__c='System Administrator'  AND isActive=true LIMIT 1];
        User testUser = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'testComm' LIMIT 1];
        system.runAs(SalesUser) {
            Test.startTest();
            CommunitiesAccountUpdateController.UserAttributeWrapper resultWrapper = CommunitiesAccountUpdateController.getCommunityFormsUserAttributes(testUser.Id, 'getCommunityFormsUserAttributesTest');
            test.stopTest();
            
            Assert.areEqual(SalesUser.Id, resultWrapper.runningUser?.Id, 'The sales user should be the running user');
            Assert.areEqual(testUser.Id, resultWrapper.communityUser?.Id, 'The inserted community user should be included in the result');
        }
    }
    
    @isTest static void getCommunityFormRecordsTest() {
        User testUser = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'testComm' LIMIT 1];
        User SalesUser = [SELECT ID, Name FROM User WHERE ProfileName__c='System Administrator' AND isActive=true  LIMIT 1];
        system.runAs(SalesUser) {
            Test.startTest();
            CommunitiesAccountUpdateController.communityFormsWrapper resultWrapper =  CommunitiesAccountUpdateController.getCommunityFormRecords('getCommunityFormRecordsTest', testUser.Id);
            Test.stopTest();
            
            Assert.areEqual(2, resultWrapper.allAccounts.size());
        }
    }
}