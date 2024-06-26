/*
* Tests for CommunitySummaryController methods
* 
* History
* ----------------------------------------
* 08/23/2021	Ahmed	Elawad		Created
* 12/22/2021	Jake Hinds			Removing Opp references
*/ 


@isTest
public class CommunitySummaryControllerTest {
    
    @testSetup
    Static void setupData() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
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
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone'];
        User u = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c1_a1.Id, Sales_Org__c = 'PAY', Username='commTestUser@testorg.com', LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert u;
        
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
        //setting2.Sales_Org__c = 'PAS'; // Commented By Rohith Ramini SFDC-14633
        insert setting2;
        
        WC_NAICS_To_Industry_Map__c naics = new WC_NAICS_To_Industry_Map__c(Name = '12345', COVID_Questionnaire_Required__c=true, Industry_name__c='Doctor\'s Offices', PEO_Industry_Title__c='Doctor\'s Offices');
        WC_NAICS_To_Industry_Map__c naics2 = new WC_NAICS_To_Industry_Map__c(Name = '67890', COVID_Questionnaire_Required__c=false);
        WC_NAICS_To_Industry_Map__c naics3 = new WC_NAICS_To_Industry_Map__c(Name = '611410', COVID_Questionnaire_Required__c=false, Industry_name__c='School/Day care', PEO_Industry_Title__c='School/Day care');
        WC_NAICS_To_Industry_Map__c naics4 = new WC_NAICS_To_Industry_Map__c(Name = '522110', COVID_Questionnaire_Required__c=false, Industry_name__c='Banks', PEO_Industry_Title__c='Banks');
        List<WC_NAICS_To_Industry_Map__c> naicsCodes = new List<WC_NAICS_To_Industry_Map__c>();
        naicsCodes.add(naics);
        naicsCodes.add(naics2);
        naicsCodes.add(naics3);
        naicsCodes.add(naics4);
        insert naicsCodes;
    }
    
    // test for getAccountInformation(String{User, Contact, or Account Id})
    @TestVisible static testMethod void getAccountInfoFromUser(){
        User testUser = [SELECT Id, ContactId, Alias FROM User WHERE Alias = 'testComm'];
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE FirstName = 'Test Comm Contact' LIMIT 1];
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        Account childAcct = [SELECT Id, Name FROM Account WHERE Name = 'ChildTestAccountCommunities'];
        
        Account[] acctArray = CommunitySummaryController.getAccountInformation(testUser.Id, '');
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
        
        acctArray = CommunitySummaryController.getAccountInformation(testContact.Id, '');
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
        
        acctArray = CommunitySummaryController.getAccountInformation(parentAcct.Id, '');
        System.assertEquals(2, acctArray.size());
        System.assertEquals(parentAcct.Id, acctArray[0].Id);
        System.assertEquals(childAcct.Id, acctArray[1].Id);
    }
    
    // test for getIndustryDetails(String{PEO_Onboarding_Checklist__c Id}, String{INdustry name})
    @TestVisible static testMethod void testGetIndustryDetails(){
        
        User runAs = [SELECT Id, Name, PEO_Queue_Bypass__c FROM User WHERE Job_Name__c = 'Sales Representative' AND PEO_Queue_Bypass__c = null LIMIT 1];
        
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        WC_NAICS_To_Industry_Map__c[] wcNaicsCodes = [SELECT ID, Name, PEO_Industry_Title__c, Industry_Name__c FROM WC_NAICS_To_Industry_Map__c where Name=:parentAcct.NAICS_Code__c];
        WC_NAICS_To_Industry_Map__c doctorNAICS = null;
        
        List<WC_Questionnaire_Industry_Specific__c> wcQuestionnairesToInsert = new List<WC_Questionnaire_Industry_Specific__c>();
        RecordType rt = [select Id,Name from RecordType where sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name='Doctor\'s Offices'];
        
        for(WC_NAICS_To_Industry_Map__c naics : wcNaicsCodes) {
            if(doctorNAICS == null && naics.Industry_Name__c.contains('Doctor')) {
                doctorNAICS = naics;
                WC_Questionnaire_Industry_Specific__c wcQuestionnaire = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id, RecordTypeId=rt.Id);
                wcQuestionnairesToInsert.add(wcQuestionnaire);
                break;
            }
        }
        insert wcQuestionnairesToInsert;
        
        parentAcct.NAICS_Code__c = doctorNAICS.Name;
        update parentAcct;
        
        List<String> naicsCodes = new List<String>();
        naicsCodes.add(parentAcct.NAICS_Code__c);
        List<String> naicsNames = CommunityIndustrySpecificController.getIndustryNames(new List<String>(naicsCodes));
        
        CommunityMethods.IndustrySpecificWrap wrap = CommunityIndustrySpecificController.getIndustryDetails(parentPeoOnbCheck.Id, naicsNames[0],'Tests');
        System.debug('wrap.IndustryType = ' + wrap.IndustryType);
        System.assertEquals('Doctors_Offices', wrap.IndustryType);
        System.assertEquals(wcQuestionnairesToInsert[0].Id, wrap.industryRec.Id);
    }
    
    // test for getPEOOnboardingChecklist()    
    static testMethod void GetPEOOnboardingChecklistTest(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c 
                                                         FROM PEO_Onboarding_Checklist__c 
                                                         WHERE Prospect_Client__c = :parentAcct.Id];
        
        PEO_Onboarding_Checklist__c peoOnbCheck = CommunitySummaryController.getPEOOnboardingChecklist(parentAcct.Id, null, '');
        
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbCheck.Id);
    }
    
    // test for getMedicalQuestionnaireForm method
    static testMethod void getMedicalQuestionnaireFormTest() {
        // need to write whole method. No other clas had a method written for this
    }
    
    // test for getIndustryStatus()
    static testMethod Void getIndustryStatusTest(){
        WC_Questionnaire_Industry_Specific__c rec = new WC_Questionnaire_Industry_Specific__c();
        RecordType rt = [select Id,Name from RecordType where sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name='Doctor\'s Offices'];
        
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        rec.PEO_Underwriting_Checklist__c = parentPeoOnbCheck.Id;
        rec.Peo_IndSpecific_formStatus__c = 'Complete';
        
        Test.StartTest();
        insert rec;
        Test.StopTest();
        
        String status = CommunitySummaryController.getIndustryStatus(parentPeoOnbCheck.Id);
        
        System.assertEquals('Complete', status);
    }
    
    // test for needCovidQuestionnaire(Account)
    static testMethod void needCovidQuestionnaire(){
        Account parentAcct = [SELECT Id, Name, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities' LIMIT 1];
        
        Boolean questionnaireNeeded = CommunitySummaryController.needCovidQuestionnaire(parentAcct);
        System.assertEquals(true, questionnaireNeeded);
        
        parentAcct.NAICS_Code__c = '67890';
        update parentAcct;
        
        questionnaireNeeded = CommunitySummaryController.needCovidQuestionnaire(parentAcct);
        System.assertEquals(false, questionnaireNeeded);
    }
    // test for getAllPeoDocs()
    static testMethod void testGetAllPeoDocs(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        Map<String, String> docNameSettingMap = new Map<String, String>();
        docNameSettingMap.put('Census', 'Census');
        
        //Id newPeoOnbDocId = CommunitiesAccountUpdateController.getPEODocument(String.valueof(parentPeoOnbCheck.Id), 'Census', 'Census',parentPeoOnbCheck.Prospect_Client__c);
        //PEO_Onboarding_Document__c peoOnbDoc = [SELECT Id, name, Routing_Name__c, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE Id = :newPeoOnbDocId LIMIT 1];
        PEO_Onboarding_Document__c[] peoDocList = CommunitySummaryController.getAllPeoDocs(parentPeoOnbCheck.Id, docNameSettingMap, parentAcct.Id, 'Tests');
        System.assertEquals(1, peoDocList.size());
        System.assertEquals(parentPeoOnbCheck.Id, peoDocList[0].PEO_Onboarding_Checklist__c);
        System.assertEquals('Census', peoDocList[0].Routing_Name__c);
    }
    
    // test method for getDiscrepancies()
    static testMethod void getDiscrepanciesTest() {
        // get the checklist
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        // get a document for the checklist
        PEO_Onboarding_Document__c newDoc = new PEO_Onboarding_Document__c(Name='Census',PEO_Onboarding_Checklist__c= parentPeoOnbCheck.Id);
        insert newDoc;
        
        // create discrepancies for each
        list<PEO_Onboarding_Document_Discrepency__c> discs = new List<PEO_Onboarding_Document_Discrepency__c>();
        PEO_Onboarding_Document_Discrepency__c docDisc = new PEO_Onboarding_Document_Discrepency__c(PEO_Onboarding_Document__c=newDoc.Id,PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id,Discrepancy_Type__c='Census' );
        PEO_Onboarding_Document_Discrepency__c chklstDisc = new PEO_Onboarding_Document_Discrepency__c(PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id,Discrepancy_Type__c='Workers Comp Questionnaire' );
        discs.add(docDisc);
        discs.add(chklstDisc);
        insert discs;
        
        Map<String, String> recordIDMap = new Map<String, String>();
        recordIDMap.put('Checklist', parentPeoOnbCheck.Id);
        
        // use the controller method to get the discrepancies
        Map<String, PEO_Onboarding_Document_Discrepency__c[]> results = CommunitySummaryController.getDiscrepancies(new List<String>{newDoc.Id}, recordIDMap);
        
        System.assertEquals(results.isEmpty(), false);
        // verify the results match
        List<PEO_Onboarding_Document_Discrepency__c> resultDocumentDiscList = results.get('checklist');
        List<PEO_Onboarding_Document_Discrepency__c> resultChecklistDiscList = results.get('docDiscrepancies');
        for (String key : results.keySet()){
            System.debug('Key: ' + key);
            System.debug(results.get(key));
        }
        
        System.assertNotEquals(null, resultChecklistDiscList);
        System.assertNotEquals(null, resultDocumentDiscList);
        System.assertEquals(false,resultChecklistDiscList.isEmpty());
        System.assertEquals(false,resultDocumentDiscList.isEmpty());
        PEO_Onboarding_Document_Discrepency__c returnedhChklstDisc = resultChecklistDiscList[0];
        PEO_Onboarding_Document_Discrepency__c returnedhDocDisc = resultDocumentDiscList[0];
        System.assertNotEquals(returnedhChklstDisc, null);
        System.assertNotEquals(returnedhDocDisc, null);
    }
    
    // test for updateDisc(PEO_Onboarding_Document_Discrepency__c{record})
    
    static testMethod void testUpdateDiscrepancy(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(additional_information__c='TEST1',PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id);
        insert disc;
        
        Map<String, String> disceMapValues = new Map<String, String>();
        disceMapValues.put('Id', disc.Id);
        disceMapValues.put('additional_information__c', 'TEST2');
        
        Id recordId = CommunitySummaryController.updateDisc(disceMapValues,'Tests');
        
        disc = [SELECT Id, Name, additional_information__c FROM PEO_Onboarding_Document_Discrepency__c WHERE ID=:recordId LIMIT 1];
        System.assertEquals('TEST2', disc.additional_information__c);
    }
    static testMethod void testUpdateDiscrepancy2(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        PEO_Onboarding_Document_Discrepency__c disc = new PEO_Onboarding_Document_Discrepency__c(additional_information__c='TEST1',PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id);
        insert disc;
        
        Map<String, String> disceMapValues = new Map<String, String>();
        disceMapValues.put('Id', disc.Id);
        disceMapValues.put('additional_information__c', 'TEST2');
        
        Id recordId = CommunitySummaryController.updateDisc(disceMapValues,'Tests');
        
        disc = [SELECT Id, Name, additional_information__c FROM PEO_Onboarding_Document_Discrepency__c WHERE ID=:recordId LIMIT 1];
        System.assertEquals('TEST2', disc.additional_information__c);
        CommunitySummaryController.getIndustryDetails(parentAcct.Id,parentPeoOnbCheck.Id,'test');
        CommunitySummaryController.getRunningUser();
        CommunitySummaryController.getMedicalQuestionnaireForm(parentPeoOnbCheck.Id,'test');
    }
}