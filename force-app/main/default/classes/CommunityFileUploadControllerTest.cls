/*
* Tests for CommunityFileUploadController methods
* 
* History
* ----------------------------------------
* 08/23/2021  Ahmed  Elawad    Created
* 12/17/2021	Jake Hinds		Additional test coverage for round robin
*/ 

@isTest
public class CommunityFileUploadControllerTest {
    
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
        
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id, Name='Census');
        insert doc;
        PEO_Onboarding_Medical_Questionnaire__c medForm = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id);
        insert medForm;
        
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
        }
    }
    
    // Test for savePeoOnboardingChecklist
    @TestVisible static testMethod void savePeoOnboardingChecklistTest(){
        Account parentAcc = [SELECT Id, Name FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c
                                                       FROM PEO_Onboarding_Checklist__c
                                                       WHERE Prospect_Client__c=:parentAcc.Id];
        peoOnbChecklist.Peo_401k_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_EPLI_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_Covid_formStatus__c = 'Complete';
        peoOnbChecklist.Peo_WC_formStatus__c = 'Complete';
        
        
        Test.startTest();
        CommunityFileUploadController.savePeoOnboardingChecklist(peoOnbChecklist,'Test');
        Test.stopTest();
        
        PEO_Onboarding_Checklist__c updatedCheclist = [SELECT ID, Peo_401k_formStatus__c, Peo_EPLI_formStatus__c, Peo_Covid_formStatus__c,
                                                       Peo_WC_formStatus__c, Peo_401k_SubmissionTime__c, Peo_EPLI_SubmissionTime__c,
                                                       Peo_Covid_formSubmissionTime__c, Peo_WC_SubmissionTime__c
                                                       FROM PEO_Onboarding_Checklist__c
                                                       WHERE Prospect_Client__c=:parentAcc.Id];
        
        System.assertEquals(updatedCheclist.Peo_401k_formStatus__c, 'Complete', 'updatedCheclist status Peo_401k_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_EPLI_formStatus__c, 'Complete', 'updatedCheclist status Peo_EPLI_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_Covid_formStatus__c, 'Complete', 'updatedCheclist status Peo_Covid_formStatus__c not updated');
        System.assertEquals(updatedCheclist.Peo_WC_formStatus__c, 'Complete', 'updatedCheclist status Peo_WC_formStatus__c not updated');
        System.assertNotEquals(updatedCheclist.Peo_401k_SubmissionTime__c,null, 'Failed to update Peo_401k_SubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_EPLI_SubmissionTime__c,null, 'Failed to update Peo_EPLI_SubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_Covid_formSubmissionTime__c,null, 'Failed to update Peo_Covid_formSubmissionTime__c');
        System.assertNotEquals(updatedCheclist.Peo_WC_SubmissionTime__c,null, 'Failed to update Peo_WC_SubmissionTime__c');
    }
    
    
    // test for getPEOOnboardingChecklist method
    static testMethod void getPEOOnboardingChecklistTest() {
        Account parentAcc = [SELECT Id, Name FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:parentAcc.Id];
        PEO_Onboarding_Checklist__c returnedChecklist = CommunityFileUploadController.getPEOOnboardingChecklist(parentAcc.Id, null, null, 'Test');
        
        // tests that the method returned a checklist and that the checklist is the one that's expected to be returned
        System.assertNotEquals(returnedChecklist, null, 'CommunityFileUploadController.getPEOOnboardingChecklist failed to return checklist');
        System.assertEquals(returnedChecklist.Id, peoOnbChecklist.Id, 'CommunityFileUploadController.getPEOOnboardingChecklist did not return already existing checklist');
    }
    
    // This method tests CommunityFileUploadController.submitForReview AND PEOOnboardingChecklist_Handler.reassignChildrenToHaveSameOwnerNow
    static testMethod void testSubmitChecklistsForReview(){
        List<String> districtsList = new List<String>();
        for(Integer i = 0; i <= 50; i++) {
            districtsList.add('0'+String.valueOf(i));
        }
        User runAs = [SELECT Id, Name, District__c,Sales_Org__c FROM User WHERE Sales_Org__c = 'PAS' AND District__c != null AND District__c IN :districtsList AND IsActive=true LIMIT 1];
        System.debug('Got user w/o issue');
        User strategicRep = [SELECT id FROM User WHERE Profile.Name='System Administrator' AND isActive = true LIMIT 1];
        
        Group queue = [Select Id,Name FROM Group WHERE Name ='Test Queue 1' and type='queue' LIMIT 1];
        
        PEO_Edge_Queue_Districts__c queueSetting = new PEO_Edge_Queue_Districts__c(Name=queue.Name ,Districts__c = String.valueOf(integer.valueOf(runAs.District__c))/*,Sales_Org__c=runAs.Sales_Org__c*/);// Commented By Rohith Ramini SFDC-14633
        insert queueSetting;
        
        Account parentAcct = [SELECT Id, Name, ShippingState, BillingState FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        Account childAcct = [SELECT Id, Name, ShippingState, BillingState FROM Account WHERE Name = 'ChildTestAccountCommunities'];
        System.debug('Got accounts w/o issue');
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, Route_to_Testing_Queue__c, OwnerId, Current_Step__c, New_Submission_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        PEO_Onboarding_Checklist__c childPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId, Current_Step__c, New_Submission_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :childAcct.Id];
        System.debug('Got checklists w/o issue');
        parentPeoOnbCheck.Sales_Rep__c = runAs.Id;
        childPeoOnbCheck.Sales_Rep__c = runAs.Id;
        List<PEO_Onboarding_Checklist__c> checklistsToUpdate = new List<PEO_Onboarding_Checklist__c>();
        checklistsToUpdate.add(parentPeoOnbCheck);
        checklistsToUpdate.add(childPeoOnbCheck);
        System.debug('Sending update  w/o');
        update checklistsToUpdate;
        System.debug('Post update  w/o');
        PEO_Onboarding_Document__c parentDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentPeoOnbCheck.Id);
        PEO_Onboarding_Document__c childDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=childPeoOnbCheck.Id);
        System.debug('Got updated docs  w/o');
        List<PEO_Onboarding_Document__c> docsToInsert = new List<PEO_Onboarding_Document__c>();
        docsToInsert.add(parentDoc);
        docsToInsert.add(childDoc);
        insert docsToInsert;
        System.debug('Inserted docs w/o');
        User currentUser = UserHelper.getRunningUser();
        PEO_Edge_Queue_Districts__c peo = new PEO_Edge_Queue_Districts__c();
        peo.Name = 'Testing';
        insert peo;
        PEO_Edge_Queue_Districts__c peo2 = new PEO_Edge_Queue_Districts__c();
        peo2.Name = 'Qualifier';
        insert peo2;
        Group g1 = new Group(Name='Testing', type='Queue');
     //   insert g1;
        Group g2 = new Group(Name='Qualifier', type='Queue');
       // insert g2;
        Test.startTest();
        
        runAs.Dedicated_NBSC__c=currentUser.id;
        update runAs;
        CommunityFileUploadController.submitForReview(parentPeoOnbCheck, currentUser, null,'Test');
        PEO_Onboarding_Checklist__c updatedParentChecklistDed = [SELECT ID,OwnerId ,Sales_Analyst__c
                                                                 FROM PEO_Onboarding_Checklist__c WHERE Id=:parentPeoOnbCheck.Id LIMIT 1];
        system.assertEquals(currentUser.id, updatedParentChecklistDed.Sales_Analyst__c);
        
        runAs.Dedicated_NBSC__c=null;
        update runAs;
        parentPeoOnbCheck.PEO_Checklist_submission_status__c = null;
        parentPeoOnbCheck.Sales_Analyst__c = null;
        update parentPeoOnbCheck;      
        
        parentPeoOnbCheck.Route_to_Testing_Queue__c = true;
        CommunityFileUploadController.submitForReview(parentPeoOnbCheck, currentUser, null,'Test');
        parentPeoOnbCheck.Route_to_Testing_Queue__c = false;
        parentPeoOnbCheck.PEO_Checklist_submission_status__c = '';
        update parentPeoOnbCheck; 
        
        CommunityFileUploadController.submitForReview(parentPeoOnbCheck, currentUser, null,'Test');
        PEO_Onboarding_Checklist__c updatedParentChecklist1 = [SELECT ID,OwnerId FROM PEO_Onboarding_Checklist__c WHERE Id=:parentPeoOnbCheck.Id LIMIT 1];
        system.debug('CommunityfileUploadControllerTest testSubmitChecklistsForReview queue' + queue + updatedParentChecklist1.OwnerId );
        system.assertEquals(queue.Id,updatedParentChecklist1.OwnerId);
        PEO_Onboarding_Checklist__c updatedChildChecklist1 = [SELECT ID,OwnerId FROM PEO_Onboarding_Checklist__c WHERE Id=:childPeoOnbCheck.Id LIMIT 1];
        system.assertEquals(updatedParentChecklist1.OwnerId,updatedChildChecklist1.OwnerId);
        
        parentPeoOnbCheck.PEO_Checklist_submission_status__c = '';
        childPeoOnbCheck.PEO_Checklist_submission_status__c = '';
        update checklistsToUpdate;
        
        CommunityFileUploadController.submitForReview(parentPeoOnbCheck, currentUser, strategicRep,'Test');
        PEO_Onboarding_Checklist__c updatedParentChecklist2 = [SELECT ID,OwnerId FROM PEO_Onboarding_Checklist__c WHERE Id=:parentPeoOnbCheck.Id LIMIT 1];
        system.assertEquals(strategicRep.Id,updatedParentChecklist2.OwnerId);
        
        //hitting the code that validates the record was already submitted
        CommunityFileUploadController.submitForReview(parentPeoOnbCheck, currentUser, strategicRep,'Test');
        PEO_Onboarding_Checklist__c updatedParentChecklist3 = [SELECT ID,OwnerId FROM PEO_Onboarding_Checklist__c WHERE Id=:parentPeoOnbCheck.Id LIMIT 1];
        system.assertEquals(strategicRep.Id,updatedParentChecklist3.OwnerId);
        Test.stopTest();
    }
    
    // tests for getSubmissionStatus(Id{PEO_Onboarding_Checklist__c Id}) 
    // *******************
    // *******************
    static testMethod void testgetSubmissionStatus(){
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c, OwnerId FROM PEO_Onboarding_Checklist__c limit 1];
        List<PEO_Onboarding_Checklist__c> retVal = CommunityFileUploadController.getSubmissionStatus(parentPeoOnbCheck.Id); 
        
        // need to add assertions
    }
    
    // Test for getPEOchecklistDetails(Id{accountID})
    static testMethod void testGetPEOchecklistDetails(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:parentAcct.Id];
        PEO_Onboarding_Checklist__c returnedChecklist = CommunityFileUploadController.getPEOchecklistDetails(parentAcct.Id);
        System.assertNotEquals(null, returnedChecklist);
        System.assertEquals(peoOnbChecklist.Id, returnedChecklist.Id, 'Returned checklist different from expected checklist');
    }
    
    // Tests for getPEODocument(Id{PEO_Onboarding_Checklist__c Id}, String{documentName}, String{customSettingName}, Id{Account Id})
   static testMethod void getPEODocumentTest() {
        Account parentAcc = [SELECT Id, Name FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:parentAcc.Id];
        PEO_Onboarding_Document__c queryDoc = [SELECT Id FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c=:peoOnbChecklist.Id];
        Id returnedDoc = CommunityFileUploadController.getPEODocument(peoOnbChecklist.Id, 'Census', null, parentAcc.Id,'Test');
        
        // tests to check a non null return value and the same doc record ID is returned
        System.assertNotEquals(returnedDoc, null);
        System.assertEquals(returnedDoc, queryDoc.Id);
        
        // Do the same thing except provide the account ID for the child. The child should have no records so a new one is created
        // need to provide all params for this to work: getPEODocument(checklistId, documentName, customSettingName, AccId)
        Account childAcc = [SELECT Id, Name FROM Account WHERE name='ChildTestAccountCommunities' LIMIT 1]; 
        PEO_Onboarding_Checklist__c childChecklsit = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:childAcc.Id];
        // should have a empty list return value
        List<PEO_Onboarding_Document__c> listBeforeMethodInsertsDocs = [SELECT Id FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c=:childChecklsit.Id];
        Id newlyInsertedDoc = CommunityFileUploadController.getPEODocument(peoOnbChecklist.Id, 'Census', 'Census', childAcc.Id,'Test');
        List<PEO_Onboarding_Document__c> listAfterMethodInsertsDocs = [SELECT Id FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c=:peoOnbChecklist.Id];
        
        System.assert(listBeforeMethodInsertsDocs.isEmpty(), 'Doc already exists for this account');
        System.assert(!listAfterMethodInsertsDocs.isEmpty(), 'Doc list after method call does not have the new doc');
        Id matchedId;
        for (PEO_Onboarding_Document__c d : listAfterMethodInsertsDocs) if (d.Id == newlyInsertedDoc) matchedId = d.Id;
        System.assertEquals(matchedId, newlyInsertedDoc, 'Queried doc Id does not match return value from method call');
    }
    
    // test for getFiles(String{PEO_Onboarding_Document__c id})
    static testMethod void testGetFiles(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        Id newPeoOnbDocId = CommunityFileUploadController.getPEODocument(String.valueof(parentPeoOnbCheck.Id), 'Test Document', 'Test Document',parentPeoOnbCheck.Prospect_Client__c,'Test');
        PEO_Onboarding_Document__c peoOnbDoc = [SELECT Id, name, Routing_Name__c, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE Id = :newPeoOnbDocId LIMIT 1];
        System.assertNotEquals(null, peoOnbDoc);
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbDoc.PEO_Onboarding_Checklist__c);
        System.assertEquals('Test Document', peoOnbDoc.name);
        System.assertEquals('Test Document', peoOnbDoc.Routing_Name__c);
        
        ContentVersion contentVersion = new ContentVersion(Title = 'Test File', PathOnClient = 'TestFile.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
        insert contentVersion;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = peoOnbDoc.Id, ContentDocumentId = documents[0].Id, shareType = 'V');
        insert cdl;
        
        List<ContentDocument> fileList = CommunityFileUploadController.getFiles(peoOnbDoc.Id);
        System.assertEquals(1, fileList.size());
    }
    
    // Test for getPEODocument(String{PEO_Onboarding_Checklist__c id})
    static testMethod void testGetSubmittedFilesForDoc(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        Id newPeoOnbDocId = CommunityFileUploadController.getPEODocument(String.valueof(parentPeoOnbCheck.Id), 'Test Document', 'Test Document',parentPeoOnbCheck.Prospect_Client__c,'Test');
        PEO_Onboarding_Document__c peoOnbDoc = [SELECT Id, name, Routing_Name__c, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE Id = :newPeoOnbDocId LIMIT 1];
        System.assertNotEquals(null, peoOnbDoc);
        System.assertEquals(parentPeoOnbCheck.Id, peoOnbDoc.PEO_Onboarding_Checklist__c);
        System.assertEquals('Test Document', peoOnbDoc.name);
        System.assertEquals('Test Document', peoOnbDoc.Routing_Name__c);
        
        ContentVersion contentVersion = new ContentVersion(Title = 'Test File', PathOnClient = 'TestFile.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
        insert contentVersion;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = peoOnbDoc.Id, ContentDocumentId = documents[0].Id, shareType = 'V');
        insert cdl;
        
        List<ContentDocument> fileList = CommunityFileUploadController.getFiles(peoOnbDoc.Id);
        System.assertEquals(1, fileList.size());
        
        fileList = CommunityFileUploadController.getSubmittedFilesForDoc(peoOnbDoc.Id);
        System.assertEquals(0, fileList.size());
        
        CommunityFileUploadController.saveFiles(peoOnbDoc.Id,'Test');
        fileList = CommunityFileUploadController.getSubmittedFilesForDoc(peoOnbDoc.Id);
        System.assertEquals(1, fileList.size());
    }
    
    // why are the tests commented out? *******************
    // *******************
    // *******************
    static testMethod void testpeoGetKnowledgeDetailsWrap(){
        CommunityFileUploadController.KnowledgeArticleWrap kwrap; 
        CommunityFileUploadController.KnowledgeArticleWrap kwrap2; 
        CommunityFileUploadController.KnowledgeArticleWrap kwrap3;
        kwrap = CommunityFileUploadController.getKnowledgeDetailsWrap('ALL');
        kwrap2 = CommunityFileUploadController.getKnowledgeDetailsWrap('Census');
        kwrap3 = CommunityFileUploadController.peoGetKnowledgeDetailsWrap('Census');
        //System.assertEquals('Census', kwrap2.knowledge[0].Title);
        //System.assertEquals(1, kwrap3.knowledge.size());
    } 
    
    
    static testMethod void testgetStrategicAccountPartner() {
        Account parentAcc = [SELECT Id, Name, Referral_National_Account__c FROM Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        User stratgicAccPart = CommunityFileUploadController.getStrategicAccountPartner(parentAcc);   
    }
    
    static testMethod void testgetMedicalQuestionnaireForm() {
        PEO_Onboarding_Medical_Questionnaire__c medForm = [SELECT Id, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Medical_Questionnaire__c LIMIT 1];
        PEO_Onboarding_Medical_Questionnaire__c resultMedForm = CommunityFileUploadController.getMedicalQuestionnaireForm(medForm.PEO_Onboarding_Checklist__c,'Test');
        System.assertEquals(medForm.Id, resultMedForm.Id, 'The returned medical form is not the one expected');
    }
    
    static testMethod void deleteFileTest(){
        Account parentAcct = [SELECT Id, Name FROM Account WHERE Name = 'ParentTestAccountCommunities'];
        PEO_Onboarding_Checklist__c parentPeoOnbCheck = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAcct.Id];
        
        Id newPeoOnbDocId = CommunityFileUploadController.getPEODocument(String.valueof(parentPeoOnbCheck.Id), 'Test Document', 'Test Document',parentPeoOnbCheck.Prospect_Client__c,'Test');
        PEO_Onboarding_Document__c peoOnbDoc = [SELECT Id, name, Routing_Name__c, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Document__c WHERE Id = :newPeoOnbDocId LIMIT 1];
        
        ContentVersion contentVersion = new ContentVersion(Title = 'Test File', PathOnClient = 'TestFile.jpg', VersionData = Blob.valueOf('Test Content'), IsMajorVersion = true);
        insert contentVersion;  
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        //create ContentDocumentLink  record 
        ContentDocumentLink cdl = New ContentDocumentLink(LinkedEntityId = peoOnbDoc.Id, ContentDocumentId = documents[0].Id, shareType = 'V');
        insert cdl;
        
        List<ContentDocument> fileList = CommunityFileUploadController.getFiles(peoOnbDoc.Id);
        
        fileList = CommunityFileUploadController.getSubmittedFilesForDoc(peoOnbDoc.Id);
        
        CommunityFileUploadController.saveFiles(peoOnbDoc.Id,'Test');
        fileList = CommunityFileUploadController.getSubmittedFilesForDoc(peoOnbDoc.Id);
        CommunityFileUploadController.deleteFile(fileList[0].Id, parentPeoOnbCheck.Id, 'Test Document','Test');
    }
    
    // Test for saveThisAccountMethod
    static testMethod void saveThisAccountTest(){
        Account acc = [select id,NumberOfEmployees, Naics_Code__c, salesParent__c from Account where name ='ParentTestAccountCommunities'];
        String oldNaics = acc.Naics_Code__c;
        acc.Naics_Code__c = '1234567';
        Account retAcc = CommunityFileUploadController.saveThisAccount(acc,'Test');
        
        System.assertNotEquals(oldNaics, retAcc.NAICS_Code__c);
        System.assertEquals('1234567', retAcc.NAICS_Code__c);
    }
    
    static testMethod void UpdatePEOCheckListDataTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id, Name, Prospect_Client__c,PEO_Sales_Notes__c,Workers_Comp_Sales_Notes__c,
                                                         Financial_Underwriting_Sales_Notes__c, Pricing_Console_Notes__c FROM PEO_Onboarding_Checklist__c limit 1];
        Test.startTest();
        CommunityFileUploadController.UpdatePEOCheckListData(chkList.Prospect_Client__c, chkList);
        Test.stopTest();
    }
    
    static testMethod void getPEODocumentDetailsTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id,Prospect_Client__c FROM PEO_Onboarding_Checklist__c limit 1];
        chkList.CensusRequired__c = true;
        update chkList;
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c();
        doc.Name='Census';
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
        Test.startTest();
        CommunityFileUploadController.getPEODocumentDetails(chkList.Id);
        Test.stopTest();
    }
    
    static testMethod void postSaveAndCompleteChatterTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id FROM PEO_Onboarding_Checklist__c limit 1];
        Test.startTest();
        CommunityFileUploadController.postSaveAndCompleteChatter(chkList.Id, false);
        Test.stopTest();
    }
    
    static testMethod void submitDocsToClientSpaceAllTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id FROM PEO_Onboarding_Checklist__c limit 1];
        Test.startTest();
        CommunityFileUploadController.submitDocsToClientSpaceAll(chkList.Id, true);
        Test.stopTest();
    }
    
    static testMethod void getPEOOnboardingDocsTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id FROM PEO_Onboarding_Checklist__c limit 1];
        Test.startTest();
        CommunityFileUploadController.getPEOOnboardingDocs(chkList.Id);
        Test.stopTest();
    }
    
}