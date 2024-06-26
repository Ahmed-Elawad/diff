/*
* Tests for CommunityIndustrySpecificController methods
* 
* History
* ----------------------------------------
* 08/23/2021	Ahmed	Elawad		Created
*/ 

@isTest
public class CommunityIndustrySpecificControllerTest {
    
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
        
        CommunityMethods.IndustrySpecificWrap wrap = CommunityIndustrySpecificController.getIndustryDetails(parentPeoOnbCheck.Id, naicsNames[0], 'Test');
        System.debug('wrap.IndustryType = ' + wrap.IndustryType);
        System.assertEquals('Doctors_Offices', wrap.IndustryType);
        System.assertEquals(wcQuestionnairesToInsert[0].Id, wrap.industryRec.Id);
    }
    
    // tests saveIndustrySpecific(WC_Questionnaire_Industry_Specific__c{record}){
    static testMethod void saveIndustrySpecificTest() {
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        RecordType rt = [select Id,Name from RecordType where sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name='Doctor\'s Offices'];
        WC_Questionnaire_Industry_Specific__c wcQuestionnaire = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id, RecordTypeId=rt.Id);
        
        WC_Questionnaire_Industry_Specific__c insertedQuestionnaire = CommunityIndustrySpecificController.saveIndustrySpecific(wcQuestionnaire, '');
        WC_Questionnaire_Industry_Specific__c queriedRec = [SELECT Id FROM WC_Questionnaire_Industry_Specific__c WHERE PEO_Underwriting_Checklist__c=:parentPeoOnbCheck.Id LIMIT 1];
        
        System.assertNotEquals(insertedQuestionnaire, null, 'Did not insert industry record');
        System.assertEquals(insertedQuestionnaire.Id, queriedRec.Id, 'Insert method did not insert WC_Questionnaire_Industry_Specific__c for checklist');
    }
    
    // test for getIndustrySpecificStatus(String{PEO_Onboarding_Checklist__c Id})
    static testMethod void getIndustrySpecificStatusTest() {
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState, NAICS_Code__c FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        RecordType rt = [select Id,Name from RecordType where sObjectType='WC_Questionnaire_Industry_Specific__c' AND Name='Doctor\'s Offices'];
        WC_Questionnaire_Industry_Specific__c wcQuestionnaire = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=parentPeoOnbCheck.Id, RecordTypeId=rt.Id, Peo_IndSpecific_formStatus__c='Complete');
        insert wcQuestionnaire;
        
        String res = CommunityIndustrySpecificController.getIndustrySpecificStatus(parentPeoOnbCheck.Id);
        System.assertEquals('Complete', res);
        // add test for updating submission status
    }
    
    // Test for getIndustryNames(String[]{String of NAICS codes})
    static testMethod void getIndustryNames() {
        String[] codes = new String[]{'12345', '611410', '522110'};
		List<string> retIndsutries = CommunityIndustrySpecificController.getIndustryNames(codes);
        
        System.assertEquals(3, retIndsutries.size(), 'The returned industry list should contain 3');
        
        String doctorsOffices = retIndsutries[0];
        String SchoolDaycare = retIndsutries[1];
        String Banks = retIndsutries[2];
        
        System.assertEquals(doctorsOffices, 'Doctor\'s Offices', 'Doctor\'s Offices was not returned for code: '+retIndsutries[0]);
        System.assertEquals(SchoolDaycare, 'School/Day care', 'School/Day care should have been an industry returned: '+retIndsutries[1]);
        System.assertEquals(Banks, 'Banks', 'Banks should have been an industry returned: '+retIndsutries[2]);
    }
}