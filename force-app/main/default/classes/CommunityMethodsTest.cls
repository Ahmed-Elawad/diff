/* 
  Tests for CommunityMethods. 
  History
  -------
   05/10/20201  Jake Hinds  Created
   07/16/2021 Jake Hinds       Set opp checkbox
   03/11/2021 Jake Hinds       testPermissionSetResend
   03/11/2021 Jake Hinds       testEmailChange
   02/14/2023 Dan Carmen       Did a check for updateChecklistOwnerWithOptyOwner for future call
   12/14/2023 Jidesh		   Updated testChecklistIncomplete to test Last_Change_Made__c field
 */
@isTest
public class CommunityMethodsTest {
    private static Schema.RecordTypeInfo accountRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
    private static Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
    private static final String PARENT_ACCOUNT_NAME = 'ParentTestAccountCommunities';
    private static final String CHILD_ACCOUNT_NAME = 'childTestAccountCommunities';
    private static final String SINGLE_ID_ACCOUNT_NAME = 'loneTestAccountCommunities';
    private static final String PARENT_CONTACT_EMAIL = 'c1@whoknows.com';
    private static final String CHILD_CONTACT_EMAIL = 'c2@whoknows.com';
    private static final String SINGLE_ID_CONTACT_EMAIL = 'c3@whoknows.com';
    private static final String PARENT_OPPTY_NAME = 'PARENTOPPTY';
    private static final String CHILD_OPPTY_NAME = 'CHILDOPPTY';
    private static final String SINGLE_ID_OPPTY_NAME = 'SINGLEIDOPPTY';
    private static final String PARENT_USERNAME = 'SINGLEIDOPPTY';
    private static final String CHILD_USERNAME = 'SINGLEIDOPPTY';
    private static final String SINGLE_ID_USERNAME = 'SINGLEIDOPPTY';
    private static final String PARENT_PORTAL_USERNAME = 'commUsr@whoknows.com';
    private static final String CHILD_PORTAL_USERNAME = 'commUsrChild@whoknows.com';
    private static final String SINGLE_ID_PORTAL_USERNAME = 'commUsrSingle@whoknows.com';
    
    @testSetup
    public static void setup(){
    	TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'CommunityMethods'}, classes, TriggerMethods.INTERFACE_C);
        TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, new String[]{'CommunityMethods'}, classes, TriggerMethods.INTERFACE_C);
        insert classes;
        
        Account acctA = new Account(Name = PARENT_ACCOUNT_NAME, AccountNumber = '8-00081234', RecordTypeId=accountRT.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        INSERT acctA;
        Account acctB = new Account(Name = CHILD_ACCOUNT_NAME, AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=accountRT.getRecordTypeId());
        Account acctC = new Account(Name = SINGLE_ID_ACCOUNT_NAME, AccountNumber = '8-12345679',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    RecordTypeId=accountRT.getRecordTypeId());
        INSERT new List<Account>{acctB, acctC};
        Account_Junction__c acctJunc = new Account_Junction__c(Child_Account__c=acctB.Id, Parent_Account__c=acctA.Id);
        INSERT acctJunc;

        // insert contacts attached to the account
        Contact c1 = new Contact(FirstName=PARENT_CONTACT_EMAIL,LastName=PARENT_CONTACT_EMAIL,  AccountId=acctA.Id, DoNotCall=false, Email=PARENT_CONTACT_EMAIL);
        Contact c2 = new Contact(FirstName=CHILD_CONTACT_EMAIL,LastName=CHILD_CONTACT_EMAIL,  AccountId=acctB.Id, DoNotCall=false, Email=CHILD_CONTACT_EMAIL);
        Contact c3 = new Contact(FirstName=SINGLE_ID_CONTACT_EMAIL,LastName=SINGLE_ID_CONTACT_EMAIL,  AccountId=acctC.Id, DoNotCall=false, Email=SINGLE_ID_CONTACT_EMAIL);
        INSERT new List<Contact>{c1, c2, c3};

        // insert opportunity for the checklist
        Opportunity opptyA = new Opportunity(Name=PARENT_OPPTY_NAME, RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        Opportunity opptyB = new Opportunity(Name=CHILD_OPPTY_NAME, RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acctB.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        Opportunity opptyC = new Opportunity(Name=SINGLE_ID_OPPTY_NAME, RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acctC.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert new List<Opportunity>{opptyA, opptyB, opptyC};
    

        // insert checklists
        PEO_Onboarding_Checklist__c parentchk = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id);
        PEO_Onboarding_Checklist__c childchk = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctB.Id,Parent_PEO_Checklist__c=parentchk.Id);
        PEO_Onboarding_Checklist__c singleidchk = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctc.Id);
        insert new List<PEO_Onboarding_Checklist__c>{parentchk, childchk, singleidchk};
            
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone'];
        User u1 = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c1.Id, Sales_Org__c = 'PAY', Username=PARENT_PORTAL_USERNAME, 
                          LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', 
                          EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        User u2 = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c2.Id, Sales_Org__c = 'PAY', Username=CHILD_PORTAL_USERNAME, 
                          LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', 
                          EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        User u3 = new User(Alias = 'testComm', ProfileId = p.Id, ContactId = c3.Id, Sales_Org__c = 'PAY', Username=SINGLE_ID_PORTAL_USERNAME, 
                          LastName='Testing', Email='commTestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', 
                          EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert new List<User>{u1, u2, u3};
    }
    
    static testMethod void testPermissionSetResend(){
        User dummyUser = [SELECT id FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() LIMIT 1];
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acct.Id,email='test@test.test');
        Contact ctct2 = new Contact(FirstName='test2',LastName='test2',AccountId=acct.Id,email='test2@test2.test');   
        Contact[] ctcts = new Contact[]{ctct,ctct2};
        insert ctcts;
        
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opp = new Opportunity(AccountId=acct.Id,CloseDate=date.today(),StageName='Pending',Name='test',RecordTypeId=rt.getRecordTypeId());
        insert opp;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PEO_Getting_Started_Prospect' LIMIT 1];
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        
        User u1 = new User(
            UserName = 'testOppCommUser1@test.testtesttest',
            FirstName = ctct.FirstName,
            LastName = ctct.LastName,
            Alias = 'tOPPest',
            email = ctct.Email,
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesOP2343Pt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community');
        User u2 = new User(
            UserName = 'testOppCommUser2@test.testtesttest',
            FirstName = ctct2.FirstName,
            LastName = ctct2.LastName,
            Alias = 'tOPPest',
            email = ctct2.Email,
            ContactId = ctct2.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesO55PPt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community',
        	Community_User_First_Login__c=system.now());
        User[] users = new User[]{u1,u2};
        PermissionSetAssignment psa1;
        PermissionSetAssignment psa2;
        system.runAs(dummyUser){
            insert users;
            psa1 = new PermissionSetAssignment(AssigneeId=u1.Id,PermissionSetId=ps.Id);
            psa2 = new PermissionSetAssignment(AssigneeId=u2.Id,PermissionSetId=ps.Id);
            PermissionSetAssignment[] psas = new PermissionSetAssignment[]{psa1,psa2};
            insert psas;
        }
        Test.startTest();
        
        TriggerMethods.objType=Contact.sObjectType;
        TriggerMethods.clearVariables();
        
        ctct.Resend_Getting_Started_Welcome_Email__c = true;
        ctct2.Resend_Getting_Started_Welcome_Email__c = true;
        update ctcts;
        
        test.stopTest();
        
        //user one should have gotten reset because they have not logged in
        PermissionSetAssignment newPSA = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId=:u1.Id AND PermissionSetId=:ps.Id LIMIT 1];
        system.assertNotEquals(psa1.Id,newPSA.Id);
        
        //user two should not have gotten reset because they already were logged in
        PermissionSetAssignment existingPSA = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId=:u2.Id AND PermissionSetId=:ps.Id LIMIT 1];
        system.assertEquals(psa2.Id,existingPSA.Id);
        
        
    }
    
    static testMethod void testChatterForFailedCensus(){
        //Creating account for test
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        insert Acc;

        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acc.id,Name='testing Peo',Sales_Rep__c = UserInfo.getUserId()
                                                                                ,Medical_Pre_Qualifier_Status__c = '', CS_CM_WC_UW_Status__c ='Approved'
                                                                                ,CS_CM_Contract_Status__c='Approved'
                                                                                ,Medical_Benefits_Underwriting_Requested__c ='No' );  
        insert checklist;
        List<PEO_Onboarding_Checklist__c> chkLists = new List<PEO_Onboarding_Checklist__c>();
        chkLists.add(checklist);
        Test.startTest();
        CommunityMethods.chatterForFailedCensus(chkLists);
        Test.stopTest();
    }
    
    static testMethod void testEmailChange(){
        User dummyUser = [SELECT id FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() LIMIT 1];
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acct.Id,email='test@test.test');  
        insert ctct;
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opp = new Opportunity(AccountId=acct.Id,CloseDate=date.today(),StageName='Pending',Name='test',RecordTypeId=rt.getRecordTypeId());
        insert opp;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PEO_Getting_Started_Prospect' LIMIT 1];
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        
        User u1 = new User(
            UserName = 'testOppCommUser1@test.testtesttest',
            FirstName = ctct.FirstName,
            LastName = ctct.LastName,
            Alias = 'tOPPest',
            email = ctct.Email,
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesOP2343Pt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community');
        PermissionSetAssignment psa1;
        system.runAs(dummyUser){
            insert u1;
            psa1 = new PermissionSetAssignment(AssigneeId=u1.Id,PermissionSetId=ps.Id);
            insert psa1;
        }
        Test.startTest();
        
        TriggerMethods.objType=Contact.sObjectType;
        TriggerMethods.clearVariables();
        
        ctct.Email = 'test2@test2.test2';
        update ctct;
        
        test.stopTest();
        
        User updatedUser = [SELECT Id,Email FROM User where Id = :u1.Id LIMIT 1];
        system.assertEquals(ctct.Email,updatedUser.Email);
    }
    
    static testMethod void testOwnerChatter() {
        User[] userList = [SELECT ID from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 2];
        Account acct1 = new Account(Name='test1',OasisPEOAccountOwner__c = userList[0].Id);
        Account acct2 = new Account(Name='test2',Premier_PBS_Account_Owner__c = userList[0].Id);
        Account[] accts = new Account[]{acct1,acct2};
        insert accts;
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        
        CommunityMethods.alreadyRan = false;
        Test.startTest();
        acct1.ShippingPostalCode = '14444';
        acct1.OasisPEOAccountOwner__c = userList[1].Id;
        acct2.ShippingPostalCode = '14444';
        acct2.Premier_PBS_Account_Owner__c = userList[1].Id;
        update accts;
        System.assertEquals(true,CommunityMethods.postCreated);
    }
    
    static testMethod void testUserCreation() {
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acct.Id,email='test@test.test');    
        insert ctct;
        
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opp = new Opportunity(AccountId=acct.Id,CloseDate=date.today(),StageName='Pending',Name='test',RecordTypeId=rt.getRecordTypeId());
        insert opp;
        
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        Test.startTest();
        User u = new User(
            UserName = 'testOppCommUser@test.testtesttest',
            FirstName = ctct.FirstName,
            LastName = ctct.LastName,
            Alias = 'tOPPest',
            email = ctct.Email,
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesOPPt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community');
        insert u;
        test.stopTest();
        Opportunity uOpp = [SELECT Has_Community_User__c FROM Opportunity WHERE Id = :opp.Id];
        system.assertEquals(true,uOpp.Has_Community_User__c);
    }
    
    static testMethod void testChecklistIncomplete() {
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        WC_NAICS_To_Industry_Map__c naicsCode = new WC_NAICS_To_Industry_Map__c(Name='12345', COVID_Questionnaire_Required__c=true);
        insert naicsCode;
        
        Account parentAcct = new Account(Name='parent',Employees__c=1,NAICS_Code__c='12345',RecordTypeId=acctRT.getRecordTypeId());
        insert parentAcct;
        Account childAcct = new Account(Name='child',SalesParent__c = parentAcct.Id,Employees__c=1,NAICS_Code__c='12345',RecordTypeId=acctRT.getRecordTypeId());
        insert childAcct;
        
        PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=parentAcct.Id,CensusRequired__c=true);
        insert parentChecklist;
        
        PEO_Onboarding_Checklist__c childChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=childAcct.Id,Parent_PEO_Checklist__c=parentChecklist.Id,CensusRequired__c=true);
        insert childChecklist;
        
        PEO_Onboarding_Document__c parentDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=parentChecklist.Id,
                                                                        Routing_Name__c='Census',
                                                                        Name='Census');
        PEO_Onboarding_Document__c childDoc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=childChecklist.Id,
                                                                        Routing_Name__c='Census',
                                                                        Name='Census');
        insert new List<PEO_Onboarding_Document__c>{parentDoc,childDoc};
            
        /*WC_Questionnaire_Industry_Specific__c parentIndustry = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=parentChecklist.Id,Peo_IndSpecific_formStatus__c);
        WC_Questionnaire_Industry_Specific__c childIndustry = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=childChecklist.Id); 
        insert new List<WC_Questionnaire_Industry_Specific__c>{parentIndustry,childIndustry};*/
        
        //PEO_Onboarding_Medical_Questionnaire__c parentMed = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=parentChecklist.Id);
        //PEO_Onboarding_Medical_Questionnaire__c childMed = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c=childChecklist.Id);
        
        //insert new List<PEO_Onboarding_Medical_Questionnaire__c>{parentMed,childMed};
        // This code runs as the Non admin
        String uniqueUserName = 'nonAdmin' + DateTime.now().getTime() + '@testorg.com';
        List<String> limitedProfileNames = new List<String>{'System Administrator API-ClientSpace','System Administrator','Sales Enablement'};
        //List<Profile> limitedProfiles = [SELECT Id, Name FROM Profile WHERE Name IN:limitedProfileNames];
        Profile p = [SELECT Id FROM Profile WHERE Name NOT IN :limitedProfileNames limit 1];
        User u = new User(Alias = 'nonAdm', Email='nonAdmin@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',Sales_Org__c = 'PEO',
         UserName=uniqueUserName);
        
        Id[] checklistIds = new Id[]{parentChecklist.Id,childChecklist.Id};
        Test.startTest();
        System.runAs(u) {
            CommunityMethods.checkIfChecklistComplete(new Set<Id>{parentChecklist.Id}, 'Test');
        }
        test.stopTest();
        PEO_Onboarding_Checklist__c updatedParentChecklist = [SELECT Id, Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Id = :parentChecklist.Id LIMIT 1];
        System.assertNotEquals(null, updatedParentChecklist.Last_Change_Made__c);
    }
    
    static testMethod void updateChecklistStepForLostOpptytest() {
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        Account[] accts = new Account[]{acct1,acct2};
            insert accts;
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Lost'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        PEO_Onboarding_Checklist__c chk = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyA.Id, Prospect_Client__c=acct1.Id);
        insert chk;
        
        Test.startTest();
        CommunityMethods.updateChecklistStepForLostOppty(new Set<Id>{opptyA.Id}, 'Test');
        test.stopTest();
        PEO_Onboarding_Checklist__c checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c=:opptyA.Id LIMIT 1];
        System.assertEquals(checklists.Current_Step__c, 'Lost');
    }
    
    static testMethod void updateChecklistOwnerWithOptyOwnertest() {
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        Account[] accts = new Account[]{acct1,acct2};
            insert accts;
        //User[] userList = [SELECT ID from User WHERE isActive = true AND Profile.Name = 'System Administrator' LIMIT 2];
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Lost'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        system.debug('opptyA:'+opptyA);
        PEO_Onboarding_Checklist__c chk = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyA.Id, Prospect_Client__c=acct1.Id);
        insert chk;
        
        Test.startTest();
        CommunityMethods.updateChecklistOwnerWithOptyOwner(new Set<Id>{opptyA.Id}, 'Test');
        test.stopTest();
        PEO_Onboarding_Checklist__c checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c, Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c=:opptyA.Id LIMIT 1];
        Opportunity optys = [SELECT Id, OwnerId FROM Opportunity WHERE AccountId=:acct1.id LIMIT 1];
        System.assertEquals(checklists.Sales_Rep__c, optys.OwnerId);
        
    }
    
    static testMethod void updateIsqForChkTest() {
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account parentAcct = new Account(Name='parent',Employees__c=1,NAICS_Code__c='12345',RecordTypeId=acctRT.getRecordTypeId());
        insert parentAcct;
        Account childAcct = new Account(Name='child',SalesParent__c = parentAcct.Id,Employees__c=1,NAICS_Code__c='12345',RecordTypeId=acctRT.getRecordTypeId());
        insert childAcct;
        
        PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=parentAcct.Id,CensusRequired__c=true);
        insert parentChecklist;
        
        PEO_Onboarding_Checklist__c childChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=childAcct.Id,Parent_PEO_Checklist__c=parentChecklist.Id,CensusRequired__c=true);
        insert childChecklist;
        Map<Id, Set<String>> chkMap = new Map<Id, Set<String>>();
        chkMap.put(parentChecklist.Id, new Set<String>{'Manufacturing'});
            
        Test.startTest();
        CommunityMethods.insertISQRecordsForChk2(chkMap);
        Test.stopTest();
    }
    
    static testMethod void deleteIsqForChkTest() {
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account parentAcct = new Account(Name='parent',Employees__c=1,NAICS_Code__c='12345',RecordTypeId=acctRT.getRecordTypeId());
        insert parentAcct;
        
        PEO_Onboarding_Checklist__c parentChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=parentAcct.Id,CensusRequired__c=true);
        insert parentChecklist;
        String RecordTypeId = (String)Schema.SObjectType.WC_Questionnaire_Industry_Specific__c.getRecordTypeInfosByName().get('Manufacturing').getRecordTypeId();
        WC_Questionnaire_Industry_Specific__c isq = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=parentChecklist.Id, RecordTypeId=RecordTypeId);
        insert isq;
        
        Map<Id, Set<String>> chkMap = new Map<Id, Set<String>>();
        chkMap.put(parentChecklist.Id, new Set<String>{'Manufacturing'});
        
        Test.startTest();
        CommunityMethods.deleteIsqAndWqforCHK2(chkMap);
        Test.stopTest();
    }
    
    static testMethod void updChecklistForOpptyStageChangetest() {
        Account acct1 = new Account(Name='test1');
        Account acct2 = new Account(Name='test2');
        Account[] accts = new Account[]{acct1,acct2};
            insert accts;
        
        Schema.RecordTypeInfo peoOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Lost'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        Opportunity opptyB = new Opportunity(Name='testOpptyB', RecordTypeId=peoOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Lost'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        insert opptyB;
        PEO_Onboarding_Checklist__c chk = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyA.Id, Prospect_Client__c=acct1.Id);
        PEO_Onboarding_Checklist__c chk2 = new PEO_Onboarding_Checklist__c(Opportunity__c=opptyB.Id, Prospect_Client__c=acct1.Id,Opportunity_to_Discovery_Date__c = Datetime.now());
        insert chk;
        insert chk2;
        
        Test.startTest();
        CommunityMethods.updChecklistForOpptyStageChange(new Set<Id>{opptyA.Id}, 'Test');
        CommunityMethods.updChecklistForOpptyStageChange(new Set<Id>{opptyB.Id}, 'Test2');
        test.stopTest();
        //PEO_Onboarding_Checklist__c checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c=:opptyA.Id LIMIT 1];
        //System.assertEquals(checklists.Current_Step__c, 'Lost');
    }
    
    static testMethod void retrieveBenchmarkValuesTest() {
        //Benchmerk tests
        Account acct1 = new Account(Name='Account1',BillingState ='CA', ShippingState='CA', NAICS_Code__c='561720');
        Account acct2 = new Account(Name='Account2',BillingState ='CA', ShippingState='CA', NAICS_Code__c='561720');
        Account[] accts = new Account[]{
            acct1,
                acct2    
                };
                    insert accts;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = accts[0].Id);
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c = accts[1].Id);
        insert checklist;
        insert checklist2;
        BLS_Med_Partcptn__c blsMedData = new BLS_Med_Partcptn__c();
        blsMedData.Name = 'Default';
        blsMedData.Prefix__c = 'NB';
        blsMedData.datatype_code__c ='26';
        blsMedData.estimate_code__c = '15';
        blsMedData.industry_code__c = '0000';
        blsMedData.ocupational_code__c = '000000';
        blsMedData.ownership_code__c = '2';
        blsMedData.provision_code__c = '179';
        blsMedData.seasonal__c = 'U';
        blsMedData.subcell_code__c = '00';
        Insert blsMedData;
        
        BLS_Average_Wage__c blsAvgWageData = new BLS_Average_Wage__c();
        blsAvgWageData.Name = 'Default';
        blsAvgWageData.seasonal__c = 'U';
        blsAvgWageData.area_code__c = '000';
        blsAvgWageData.industry_code__c = '10';
        blsAvgWageData.owner_code__c = '5';
        blsAvgWageData.Prefix__c = 'EN';
        blsAvgWageData.size_code__c = '0';
        blsAvgWageData.type_code__c = '5';
        Insert blsAvgWageData;
        
        BLS_Turnover_Rate__c blsTurnOverData = new BLS_Turnover_Rate__c();
        blsTurnOverData.Name = 'Default';
        blsTurnOverData.area_code__c = '00000';
        blsTurnOverData.dataelement_code__c = 'QU';
        blsTurnOverData.industry_code__c = '000000';
        blsTurnOverData.Prefix__c = 'JT';
        blsTurnOverData.ratelevel_code__c = 'R';
        blsTurnOverData.seasonal__c = 'U';
        blsTurnOverData.sizeclass_code__c = '00';
        blsTurnOverData.state_code__c = '00';
        Insert blsTurnOverData;
        
        PEOUW_BLS_Data__c blsRecord = new PEOUW_BLS_Data__c(PEO_Underwriting_Checklist__c = checklist.Id);
        insert blsRecord;
        
        List<Account> dataPointAcc = [Select id, Name, BillingState, ShippingState, NAICS_Code__c from Account];
        
        User dummyUser = [SELECT id FROM User WHERE IsActive = true and Profile.Name = 'System Administrator' AND Id != :UserInfo.getUserId() LIMIT 1];
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acct.Id,email='test@test.test');
        Contact ctct2 = new Contact(FirstName='test2',LastName='test2',AccountId=acct.Id,email='test2@test2.test');   
        Contact[] ctcts = new Contact[]{ctct,ctct2};
            insert ctcts;
        
        Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opp = new Opportunity(AccountId=acct.Id,CloseDate=date.today(),StageName='Pending',Name='test',RecordTypeId=rt.getRecordTypeId());
        insert opp;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'PEO_Getting_Started_Prospect' LIMIT 1];
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        
        User u1 = new User(
            UserName = 'testOppCommUser1@test.testtesttest',
            FirstName = ctct.FirstName,
            LastName = ctct.LastName,
            Alias = 'tOPPest',
            email = ctct.Email,
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesOP2343Pt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community');
        User u2 = new User(
            UserName = 'testOppCommUser2@test.testtesttest',
            FirstName = ctct2.FirstName,
            LastName = ctct2.LastName,
            Alias = 'tOPPest',
            email = ctct2.Email,
            ContactId = ctct2.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesO55PPt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community',
            Community_User_First_Login__c=system.now());
        User[] users = new User[]{u1,u2};
            PermissionSetAssignment psa1;
        PermissionSetAssignment psa2;
        system.runAs(dummyUser){
            insert users;
            psa1 = new PermissionSetAssignment(AssigneeId=u1.Id,PermissionSetId=ps.Id);
            psa2 = new PermissionSetAssignment(AssigneeId=u2.Id,PermissionSetId=ps.Id);
            PermissionSetAssignment[] psas = new PermissionSetAssignment[]{psa1,psa2};
                insert psas;
        }
        Test.startTest();
        CommunityMethods.retrieveBenchmarkValues(checklist);
        CommunityMethods.checkIfBenchmarkValuesExist(accts[0], checklist);
        CommunityMethods.checkBLSPermissions(u2.Id,'Test');
        Test.stopTest();
        
        
    }
    
    static testMethod void getAccountInformationTest() {
        set<String> contactEmails = new Set<String>{PARENT_CONTACT_EMAIL, CHILD_CONTACT_EMAIL, SINGLE_ID_CONTACT_EMAIL};
        set<String> accountNames = new Set<String>{PARENT_ACCOUNT_NAME, CHILD_ACCOUNT_NAME, SINGLE_ID_ACCOUNT_NAME};
    
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, Email FROM contact WHERE email in :contactEmails]);
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Name in :accountNames]);
        Map<Id, PEO_Onboarding_Checklist__c> checklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id,Prospect_Client__c FROM PEO_Onboarding_Checklist__c]);

        Contact parentContact = null;
        Contact childContact = null;
        Contact singleIdContact = null;
        PEO_Onboarding_Checklist__c parentChecklist = null;
        PEO_Onboarding_Checklist__c childChecklist = null;
        PEO_Onboarding_Checklist__c singleIdChecklist = null;
        Account parentAccount = null;
        Account childAccount = null;
        Account singleIdAccount = null;
        
        for (Contact cntct : contacts.values()) {
            if (cntct.email == PARENT_CONTACT_EMAIL) parentContact = cntct;
            if (cntct.email == CHILD_CONTACT_EMAIL) childContact = cntct;
            if (cntct.email == SINGLE_ID_CONTACT_EMAIL) singleIdContact = cntct;
        }
        
        for (Account acct : accounts.values()) {
            if (acct.Name == PARENT_ACCOUNT_NAME) parentAccount = acct;
            if (acct.Name == CHILD_ACCOUNT_NAME) childAccount = acct;
            if (acct.Name == SINGLE_ID_ACCOUNT_NAME) singleIdAccount = acct;
        }
        
        for (PEO_Onboarding_Checklist__c chk : checklists.values()) {
            if (chk.Prospect_Client__c == parentAccount.Id) parentChecklist = chk;
            if (chk.Prospect_Client__c == childAccount.Id) childChecklist = chk;
            if (chk.Prospect_Client__c == singleIdAccount.Id) singleIdChecklist = chk;
        }
	
        
        Test.startTest();
        Set<Id> AllIds = new Set<Id>();
        AllIds.addAll(contacts.keySet());
        AllIds.addAll(accounts.keySet());
        AllIds.addAll(checklists.keySet());
        Map<Id, Account[]> accountsMapping = CommunityMethods.getAccountInformation(AllIds,'CommunityAccountEditForm', 'CommunityMethodsTest');
        
        // We simply want the data so every id passed should have a list of relavent accounts mapped.
        List<Account> accountsForParentContact = accountsMapping.get(parentContact.Id);
        List<Account> accountsForChildOfParent = accountsMapping.get(childContact.Id);
        List<Account> accountsForSingleIdContact = accountsMapping.get(singleIdContact.Id);
        List<Account> accountsForParentChecklist = accountsMapping.get(parentChecklist.Id);
        List<Account> accountsForChildChecklists = accountsMapping.get(childChecklist.Id);
        List<Account> accountsForSingleIdChecklist = accountsMapping.get(singleIdChecklist.Id);
        List<Account> accountsForParentAccount = accountsMapping.get(parentAccount.Id);
        List<Account> accountsForChildAccount = accountsMapping.get(childAccount.Id);
        List<Account> accountsForSingleId = accountsMapping.get(singleIdAccount.Id);
        
        System.assertEquals(2, accountsForParentContact != null ? accountsForParentContact.size() : 0, 'Expected two accounts to be returned for a contact that is associated with a multi Id with a parent and child');
        System.assertEquals(1, accountsForChildOfParent != null ? accountsForChildOfParent.size() : 0, 'Expected the child account to be returned for a contact associated to a child of a parent');
        System.assertEquals(1, accountsForSingleIdContact != null ? accountsForSingleIdContact.size() : 0, 'Expected the single account to be returned for a contact associated with a single account');
        System.assertEquals(2, accountsForParentChecklist != null ? accountsForParentChecklist.size() : 0, 'Expected both child accounts to be returned when a parent checklist is provided');
        System.assertEquals(1, accountsForChildChecklists != null ? accountsForChildChecklists.size() : 0, 'Expected the single account to be returned for a checklist associated with a single checklist');
        System.assertEquals(1, accountsForSingleIdChecklist != null ? accountsForSingleIdChecklist.size() : 0, 'Expected the single account to be returned for a checklist fopr a single Id');
        System.assertEquals(2, accountsForParentAccount != null ? accountsForParentAccount.size() : 0, 'Expected both child and parent account to be returned for a parent Id');
        System.assertEquals(1, accountsForChildAccount != null ? accountsForChildAccount.size() : 0, 'Expected the single child account to be returned for a child id');
        System.assertEquals(1, accountsForSingleId != null ? accountsForSingleId.size() : 0, 'Expected the single account to be returned for a single ID when using an account Id');
    }
    
    static testMethod void getAccountInformationForPortalUsers() {
        User singleIdPortalUser = [SELECT Id, Username From User where username = :SINGLE_ID_PORTAL_USERNAME];
        User parentPortalUse = [SELECT Id, Username From User where username = :PARENT_PORTAL_USERNAME];
        User childPortalUser = [SELECT Id, Username From User where username = :CHILD_PORTAL_USERNAME];
        Map<Id, Account[]> singleIdAccounts;
        Map<Id, Account[]> parentIdAccounts;
        Map<Id, Account[]> childIdAccounts;
        Test.startTest();
        System.runAs(singleIdPortalUser) {
            singleIdAccounts = CommunityMethods.getAccountInformation(new Set<Id>{singleIdPortalUser.Id},'CommunityAccountEditForm', 'CommunityMethodsTest');
        }
        System.runAs(parentPortalUse) {
        	parentIdAccounts = CommunityMethods.getAccountInformation(new Set<Id>{parentPortalUse.Id},'CommunityAccountEditForm', 'CommunityMethodsTest');
        }
        System.runAs(childPortalUser) {
        	childIdAccounts = CommunityMethods.getAccountInformation(new Set<Id>{childPortalUser.Id},'CommunityAccountEditForm', 'CommunityMethodsTest');
        }
        Test.stopTest();
        List<Account> accountsForSingleIdUser = singleIdAccounts.get(singleIdPortalUser.Id);
        List<Account> accountsForChildUser = childIdAccounts.get(childPortalUser.Id);
        List<Account> accountsForParentUser = parentIdAccounts.get(parentPortalUse.Id);
        System.assertEquals(2, accountsForParentUser != null ? accountsForParentUser.size() : 0, 'Expected the single account to be returned when using the portal user associated to a single id');
        System.assertEquals(1, accountsForChildUser != null ? accountsForChildUser.size() : 0, 'Expected both the parent and child account to be returned when using the portal user associated to the parent account');
        System.assertEquals(1, accountsForSingleIdUser != null ? accountsForSingleIdUser.size() : 0, 'Expected the single account to be returned when using the portal user associated to a single id');
    }
    
}