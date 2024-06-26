/** Tests for creating an external community user
*
* History
* -------
* 03/10/2020    Ahmed Elawad        Created.
* 03/16/2020    Ahmed Elawad        Added methods to test: contact verification, existing user, and comm. user creation
* 06/04/2020    Jake Hinds          Added OPP
* 08/5/2021     Ahmed Elawad        Added updateContactAndAcctWorkqueueTest
* 08/25/2021    Jake Hinds          test for checkForExistingChecklist
* 09/07/2021    Jake Hinds          adding comm user lookup to user creation test
* 10/10/2021    Jake Hinds          reactivation test
* 01/26/2022	Jake Hinds			Changes for NBSC Vertical Rep
* 02/07/2022	Jake Hinds			Removing experience
* 03/11/2022	Jake Hinds			testEnvironment + new permission set
* 05/03/2022	Srujan Kumar		createCommunityUserNew
* 05/03/2022	Srujan Kumar		sendEmailToCommUser
* 07/26/2022    Srujan Kumar		getChildAccounts
* 07/26/2022    Srujan Kumar		deleteChildAccountChecklists
* 06/06/2023    Josh Cartwright     upated NSC select to select PEO Sales org instead of NSC (NSC was recently removed)
* 05/07/2024    Josh Cartwright     updated test to accomidate updateContactAndAcctWorkqueue to reset broker commission work queues 

*/

@isTest
public class ConvertContactToCommunityUserTest {
    
    // Creates the required records for testing:
    // User record with role - to be assigned as account owner
    // Account: generic account with name and owner
    // Contact: Two contacts; one associated with a community user and one not
    @testSetup 
    static void recordSetup() {
        
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        Account acctB = new Account(Name = 'ChildTestAccountCommunities', AccountNumber = '8-12345678',NumberOfEmployees = 60, BillingStreet = ' Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='5678', Phone='123-456-7891', DBA__c='TEST',
                                    SalesParent__c = acctA.Id, RecordTypeId=rtAcct.getRecordTypeId());
        insert acctB;
        Account_Junction__c acctJunc = new Account_Junction__c(Child_Account__c=acctB.Id, Parent_Account__c=acctA.Id);
        insert acctJunc;
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a1;
        
        Schema.RecordTypeInfo peoOpptyRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=peoOpptyRT.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,OpportunityType__c = 'PEO'
                                             ,CloseDate=Date.today().addDays(30));
        
        Opportunity opptyB = new Opportunity(Name='testOpptyB', RecordTypeId=peoOpptyRT.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,OpportunityType__c = 'PEO'
                                             ,CloseDate=Date.today().addDays(30));
        insert new List<Opportunity>{opptyA,opptyB};
        //Test.setCreatedDate(opptyB.Id, Date.today().addDays(-60));
        
        PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Requested__c='Yes', Benefit_Effective_Date__c=System.today());
        insert peoOnbChecklist;
         
        /*PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=peoOnbChecklist.Id, Name='Census');
        insert doc;*/
        /*User u = new User(Alias = 'testUser', ProfileId ='00e0g0000010DA0AAM', Sales_Org__c = 'PAY', Username='CnvCntctTestUser@testorg.com', LastName='Testing', Email='TestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert u;*/
    }
    
    
    /*static testMethod void getProspectClientNumberTest(){	
        Account acc = [SELECT Id from Account LIMIT 1];	
        test.startTest();
        Account acct = ConvertContactToCommunityUser.getProspectClientNumber(acc.Id);
        system.Assert(acct != null);
        test.stopTest();
    }*/
    
    static testMethod void getChildAccounts(){	
        Account acc = [SELECT Id from Account LIMIT 1];	
        Test.startTest();	
        Map<String, Object> returnVals = ConvertContactToCommunityUser.getChildAccounts(acc.Id);	
        Test.stopTest();	
    }	
    	
    static testMethod void deleteChildAccountChecklists(){	
        Account acc = [SELECT Id FROM Account WHERE Name = 'ParentTestAccountCommunities'];	
        List<Id> accId = new List<Id>();	
        accId.add(acc.Id);	
        Test.startTest();	
        ConvertContactToCommunityUser.deleteChildAccountChecklists(accId);	
        Test.stopTest();	
    }
    
    static testMethod void sendEmailToCommUser() {	
        User[] salesPeople = [SELECT Id FROM User WHERE Profile.Name='HRS PEO-ASO Sales - SB' LIMIT 2];	
        Account acct = new Account(Name='test acct');	
        insert acct;	
        Contact ctct = new Contact(FirstName='test',LastName='user',Email='test@testPEOGettingStartedHelp.com',AccountId=acct.Id);	
        insert ctct;	
        DateTime inviteDate = DateTime.now();
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew('test@testPEOGettingStartedHelp.com','testNicknamePEOGettingStartedHelp',	
                                                                          ctct.Id, 'testAlia', '',inviteDate);	
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c=acct.Id,	
                                                                                Sales_Rep__c=salesPeople[0].Id,	
                                                                                Sales_Analyst__c=salesPeople[1].Id,	
                                                                                 Analyst_Queue_Name__c='test',	
                                                                                Analyst_Queue__c=system.now());	
        insert checklist;	
        List<String> inputId = new List<String>();	
        inputId.add(commUserId);	
        Test.startTest();	
        ConvertContactToCommunityUser.sendEmailToCommUser(inputId);	
        Test.stopTest();	
    }
    
    static testMethod void getContactForId() {
        // query the contact obj for the inserted contact record
        // Pass that contact id as a value to the getContactForId method
        // Verify email, contactID
        // List<User> usrs = new List<User>();
        
        Contact conRec = [SELECT firstName, LastName, Email, Phone FROM Contact WHERE email='c1a1@whoknows.com'];
        
        Contact methodContact = ConvertContactToCommunityUser.getContactForId(conRec.Id);
        
        System.assertNotEquals(methodContact, null,'Method returned null contact record');
        System.assertEquals(methodContact.Id, conRec.Id,'Method contact ID does not match inserted contact');
        System.assertEquals(methodContact.Email, conRec.Email, 'Returned contact email does not matched inserted contact email');
    }
    
    static testMethod void verifyFields() {
        String newusername = 'newUsername@test.com';
        String newnickName = 'newnickname@test.com';
        List<String> results = ConvertContactToCommunityUser.verifyFields(newusername, newnickName);
        
        System.assertEquals(results.isEmpty(), true, 'Recieved duplicate error for non existing user nickname and username');
    }
    
    
    static testMethod void createQuestionnaire() {
        Account acc = [SELECT Id, Name from Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        Opportunity opp = [SELECT Id, Name from Opportunity WHERE AccountId = :acc.Id LIMIT 1];
        PEO_Onboarding_Checklist__c checklist = [SELECT id,Name, Sales_Rep__c, Client_Add_on__c,Prospect_Client__c,Payroll_Frequency__c,Select_Child_Accounts__c, 
                                                 Child_Account_Ids__c, Medical_Benefits_Underwriting_Requested__c, Benefit_Effective_Date__c,Workers_Comp_FastPass__c,
                                                 WC_Codes_are_in_Target_Hazard_Group__c,WC_Premium_is_less_than_10_000__c,Opportunity__c, Medical_Underwriting_Path_Type__c,
                                                 Workers_Comp_Underwriting_Path_Type__c, Medical_Underwriting_Path__c, Submit_to_Workers_Comp_Underwriting__c,
                                                 Health_Benefits_Currently_through_a_PEO__c, Medical_Underwriting_Path_Option__c, display_Benchmark_tab__c,
                                                 Platform__c, Current_Aff_with_Paychex_PEO_Oasis__c, Client_Number__c, Is_this_a_current_Paychex_Agency_Client__c,
                                                 Parent_Company_Legal_Name__c, Parent_Paychex_oasis_Num__c, Parent_appro_self_retain_workers_comp__c, 
                                                 Is_Medical_Underwriting_Requested__c, Do_you_need_full_underwriting_path__c, why_choose_full_underwriting_path__c
                                                 from PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:acc.Id LIMIT 1];
        Boolean createdQuestionnaire = ConvertContactToCommunityUser.createQuestionnaire(checklist,null,null);
        
        
        //System.assertEquals(createdQuestionnaire, True);
    }
    
    static testMethod void createCommunityUser() {
        User runningUser = UserHelper.getRunningUser();
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Test.startTest();
        system.assertEquals(new String[]{},ConvertContactToCommunityUser.checkPermissions(runningUser));
        DateTime inviteDate = DateTime.now();
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew(username,nickname, newCommUserContact.Id, alias, '',inviteDate);
        Test.stopTest();
        Profile commProf = [Select id FROM profile where name='Customer community login user clone'];
        
        System.assertNotEquals(commUserId, null);
        User commU = [Select id,ProfileId FROM User where id=:commUserId ];
        System.assertEquals(commU.ProfileId, commProf.Id);
        PEO_Onboarding_Checklist__c checklist = [SELECT id,Community_User__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:newCommUserContact.AccountId LIMIT 1];
        system.assertEquals(commU.Id,checklist.Community_User__c);
        
    }
    
    static testMethod void createCommunityUserNew() {
        User runningUser = UserHelper.getRunningUser();
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Test.startTest();
        system.assertEquals(new String[]{},ConvertContactToCommunityUser.checkPermissions(runningUser));
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew(username,nickname, newCommUserContact.Id, alias, '', system.now());
        Test.stopTest();
        Profile commProf = [Select id FROM profile where name='Customer community login user clone'];
        
        System.assertNotEquals(commUserId, null);
        User commU = [Select id,ProfileId FROM User where id=:commUserId ];
        System.assertEquals(commU.ProfileId, commProf.Id);
        PEO_Onboarding_Checklist__c checklist = [SELECT id,Community_User__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c=:newCommUserContact.AccountId LIMIT 1];
        system.assertEquals(commU.Id,checklist.Community_User__c);
        
    }
    
    /*static testMethod void verifyExistingUserForContact() {
        Contact rec = [SELECT id FROM Contact WHERE email='c1a1@whoknows.com'];
        User retUser = ConvertContactToCommunityUser.verifyExistingUserForContact(rec.Id);
        
        Contact newCommUserContact = [SELECT Id FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Id commUserId = ConvertContactToCommunityUser.createCommunityUser(username,nickname, newCommUserContact.Id, alias, '');
        
        System.assertEquals(retuser, null);
        //  User commUser = ConvertContactToCommunityUser.verifyExistingUserForContact(commUserId);
        
        //System.assertEquals(commUser.Id, commUserId);
    }*/
    
    static testMethod void testOpp() {
        
        //Account acc = [SELECT Id, Name from Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
        Account acc = new Account(Name='test acct', OasisPEOAccountOwner__c=UserInfo.getUserId());	
        insert acc;
        Schema.RecordTypeInfo peoOpptyRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity oppty = new Opportunity(Name='testOppty', RecordTypeId=peoOpptyRT.getRecordTypeId()
                                            ,AccountId=acc.id
                                            ,StageName='Open'
                                            ,Employees_Paid_Per_Payroll__c = 51
                                            ,OpportunityType__c = 'PEO'
                                            ,CloseDate=Date.today().addDays(30));
        insert oppty;
        Opportunity returnOpp = ConvertContactToCommunityUser.getOpp(acc.Id);
        system.assertEquals(oppty.Id,returnOpp.Id);
        //JC NSC sales Division was replaced with PEO, updating select here: 
        /*User nsc = [SELECT Id FROM User WHERE isActive = true AND Sales_Division__c = 'PEO' LIMIT 1];
        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=oppty.id,TeamMemberRole='PEO NSC',UserId=nsc.Id);
        insert otm;
        
        Opportunity returnOpp = ConvertContactToCommunityUser.getOpp(acc.Id);
        system.assertEquals(oppty.Id,returnOpp.Id);
        system.runAs(nsc){
            returnOpp = ConvertContactToCommunityUser.getOpp(acc.Id);
            system.assertEquals(oppty.Id,returnOpp.Id);
        }
        //Test for DSM
        User  user1 = [Select Id, Name, ManagerId from User where id=: userinfo.getUserId()];
        oppty.Owner = user1;
        System.debug('User 1:'+user1);
        System.debug('Opty:'+oppty);
        System.debug('Opty owner:'+oppty.Owner);
        System.debug('Opty owner manager:'+oppty.Owner.ManagerId);
        oppty.Owner.ManagerId = user1.ManagerId;
        User manager = [Select Id, Name, ManagerId from User where id=: user1.ManagerId];
        system.runAs(manager){
            returnOpp = ConvertContactToCommunityUser.getOpp(acc.Id);
            system.assertEquals(oppty.Id,returnOpp.Id);
        }*/
    }
    
    static testMethod void updateAcctAndContactWorkqueueTest() {
        Contact conRec = [SELECT Id, firstName, LastName, Email, Phone FROM Contact WHERE email='c1a1@whoknows.com'];
        Account acc = [SELECT Id, Name from Account WHERE name='ParentTestAccountCommunities' LIMIT 1];
		
        Referral_Account__c refAcc = new Referral_Account__c(Name='TestRA', Account__c = acc.id);
        insert refAcc;
        Referral_Contact__c refCon = new Referral_Contact__c(Name='TestRC', Contact__c = conRec.id);
        insert refCon;
        List<Broker_Commission__c> lstBC = new List<Broker_Commission__c>(); 
        Broker_Commission__c bc1 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id, Prospect_Client__c = acc.id);        
        
        List<Work_Queue__c> insertWorkqueues = new List<Work_Queue__c>();
        Work_Queue__c cntctWq = new Work_Queue__c(Completed__c=true, Account_ID__c=acc.Id, Object_Record_ID__c=conRec.Id, Object__c='Contact');
        Work_Queue__c acctWq = new Work_Queue__c(Completed__c=true, Account_ID__c=acc.Id, Object_Record_ID__c=acc.Id, Object__c='Account');
        Work_Queue__c bcWq = new Work_Queue__c(Completed__c=true, Account_ID__c=acc.Id, Object_Record_ID__c=bc1.Id, Object__c='Broker_Commission__c');
       
        insertWorkqueues.add(acctWq);
        insertWorkqueues.add(cntctWq);
        insertWorkqueues.add(bcWq);
        
        Test.startTest();
        insert insertWorkqueues;
        
        Work_Queue__c[] wqs = [SELECT Id, Completed__c, Object__c, Object_Record_ID__c FROM Work_Queue__c];
        System.assertEquals(3, wqs.size(), 'Too many workqueues returned or inserted: '+ wqs.size());
        List<Work_Queue__c> updateWq = new List<Work_Queue__c>();
        
        for (Work_Queue__c wq : wqs) {
            if (!wq.Completed__c) {
                wq.Completed__c = true;
                updateWq.add(wq);
            }
        }
        
        if (!updateWq.isEmpty()) update updateWq;
        List<Id> childAccountIdsForQueues = new List<Id>();
        ConvertContactToCommunityUser.updateContactAndAcctWorkqueue(conRec.Id, acc.Id, childAccountIdsForQueues, null);
        Test.stopTest();
        
        Work_Queue__c[] recs =  [SELECT ID, Object__c, Object_Record_ID__c, Completed__c
                                 FROM Work_Queue__c 
                                 WHERE Account_ID__c=:acc.Id AND (Object__c='Contact' OR Object__c='Account' OR Object__c ='Broker_Commission__c')];
        
        Work_Queue__c recNotUpdate = null;
        for (Work_Queue__c rec : recs) {
            if (rec.Completed__c) {
                recNotUpdate = rec;
                break;
            }
        }

        System.assertEquals(recNotUpdate, null);
        delete wqs;
    }   
    static testMethod void testCheckForExistingChecklist() {
        Account acct = [SELECT id FROM Account WHERE SalesParent__c = null limit 1];
        PEO_Onboarding_Checklist__c checklist = ConvertContactToCommunityUser.checkForExistingChecklist(acct.Id);
        system.assert(checklist!=null);
    }
    static testMethod void testUserReactivation() {
        User[] salesPeople = [SELECT Id FROM User WHERE Profile.Name='HRS PEO-ASO Sales - SB' LIMIT 2];
        User notMe = [SELECT Id FROM User Where Profile.Name ='System Administrator' AND isActive = true AND Id <>:UserInfo.getUserId() LIMIT 1];
        Account acct = new Account(Name='test acct');
        insert acct;
        
        Contact ctct = new Contact(FirstName='test',LastName='user',Email='test@testPEOGettingStartedHelp.com',AccountId=acct.Id);
        insert ctct;
        
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c=acct.Id,
                                                                                Sales_Rep__c=salesPeople[0].Id,
                                                                                Sales_Analyst__c=salesPeople[1].Id,
                                                                                 Analyst_Queue_Name__c='test',
                                                                                Analyst_Queue__c=system.now());
        insert checklist;
        
        DateTime inviteDate = DateTime.now();
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew('test@testPEOGettingStartedHelp.com','testNicknamePEOGettingStartedHelp',
                                                                          ctct.Id, 'testAlia', '',inviteDate);
        
        system.runAs(notMe){
            test.startTest();
            User commUser = [SELECT Id,IsActive,AccountId FROM User WHERE Id=:commUserId LIMIT 1];
            commUser.IsActive = false;
            update commUser;
            Boolean goodSave = ConvertContactToCommunityUser.reactivateCommunityUser(commUser);
            //ConvertContactToCommunityUser.sendReactivationEmail(commUser);
            system.assertEquals(true,goodSave); 
            test.stopTest();
            PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Sales_Rep__c,Sales_Analyst__c,Analyst_Queue_Name__c,Analyst_Queue__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checklist.Id LIMIT 1];
            system.assertEquals(notMe.Id,uChecklist.Sales_Rep__c);
            system.assertEquals(null,uChecklist.Sales_Analyst__c);
            system.assertEquals(null,uChecklist.Analyst_Queue_Name__c);
            system.assertEquals(null,uChecklist.Analyst_Queue__c);
        }
    }
    /*static testMethod void testVerticalProcess() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acct = new Account(Name = 'ParentTestAccountCommunities2', AccountNumber = '8-00081235', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='456', Phone='456-123-7890', DBA__c='TEST2');
        insert acct;
        Contact ctct = new Contact(FirstName=' Comm Contact',LastName='Contact 2',  AccountId=acct.Id, DoNotCall=false, Email='ctct2@whoknows.com');
        insert ctct;
        
        Schema.RecordTypeInfo peoOpptyRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity oppty = new Opportunity(Name='testVerticalOppty', RecordTypeId=peoOpptyRT.getRecordTypeId()
                                             ,AccountId=acct.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,OpportunityType__c = 'PEO'
                                             ,CloseDate=Date.today().addDays(30));
		insert oppty;
        
        User peoRep = [SELECT Id FROM User WHERE isActive = true and Sales_Org__c = 'PEO' LIMIT 1];
        //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'NBSC_Vertical' LIMIT 1];
        system.runAs(peoRep){
            Test.startTest();
            
            Opportunity opp = ConvertContactToCommunityUser.getOpp(acct.Id);
            system.assert(opp!=null);
            
            //this would normally be created by the lightning component
            PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='Vertical Test',Prospect_Client__c=acct.Id, Medical_Benefits_Underwriting_Requested__c='No', 
                                                                                    Opportunity__c=opp.Id);
            Boolean result = ConvertContactToCommunityUser.createQuestionnaire(checklist,'test',opp);
        	system.assertEquals(false,result);
            Test.stopTest();
            PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Sales_Rep__c,Sales_Analyst__c,OwnerId,PEO_Checklist_submission_status__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :acct.Id LIMIT 1];
            system.assert(uChecklist!=null);
            system.assertEquals(peoRep.Id,uChecklist.Sales_Analyst__c);
            system.assertEquals(peoRep.Id,uChecklist.OwnerId);
            system.assertEquals('Submitted',uChecklist.PEO_Checklist_submission_status__c);
        }
    }*/
    /*static testMethod void testEnvironment(){
        String sandboxName = ConvertContactToCommunityUser.getEnv();
        System.debug('sandboxName='+sandboxName);
        // cannot use assert because we don't know where this will be run (which is why we have this in the first place).
    }*/
    
    /*static testMethod void testEdgeQQUserPermissions(){
        Boolean hasAccess = ConvertContactToCommunityUser.checkEdgeQQUserPermissions();
        //This was written as part of SPA phase 1 and 2 releases. Need to check with the team if its needed anymore
        //system.assertEquals(false,hasAccess);
    }*/
    
    /*static testMethod void getPEOOnboardingDocsTest(){
        PEO_Onboarding_Checklist__c chkList = [SELECT Id FROM PEO_Onboarding_Checklist__c limit 1];
        Test.startTest();
        ConvertContactToCommunityUser.getPEOOnboardingDocs(chkList.Id);
        Test.stopTest();
    }
    static testMethod void UpdatePEOOnboardingDocsTest(){
        PEO_Onboarding_Document__c[] chkListdocs = [SELECT Id FROM PEO_Onboarding_Document__c];
        Test.startTest();
        ConvertContactToCommunityUser.UpdatePEOOnboardingDocs(chkListdocs);
        Test.stopTest();
    }*/
    
    @isTest
    static void getInitializationAttributesTest() {
        Contact conRec = [SELECT Id, firstName, LastName, Email, Phone FROM Contact WHERE email='c1a1@whoknows.com'];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
               
        // do the run as a sales user
        Test.startTest();
        DateTime inviteDate = DateTime.now();
        Id commUserId = ConvertContactToCommunityUser.createCommunityUserNew(username,nickname, conRec.Id, alias, '',inviteDate);
        ConvertContactToCommunityUser.ConfigurationWrapper attributeWrapper =  ConvertContactToCommunityUser.getInitializationAttributes(conRec.Id);
        Test.stopTest();
        
        System.assertNotEquals(attributeWrapper.env, null, 'Expect the enviornment variable to be included in results');
        System.assertEquals(conRec.Id, attributeWrapper?.contactRecord.Id, 'Expected the current contact to be returned');
        System.assertEquals(commUserId, attributeWrapper.communityUserRecord.Id, 'Expected the community user that was created for the contact to be included in the result');
        System.assert(attributeWrapper.missingPermissionsList.isEmpty(), 'Expect that the missing permissions list is empty');
    }
    
    @isTest
    static void getOpportunityAndChecklistDocumentsTest() {
        Account acc = new Account(Name='test acct', OasisPEOAccountOwner__c=UserInfo.getUserId());	
        List<Account> accountChildren = [SELECT Id from Account WHERE SalesParent__c = :acc.Id];
        
        Test.startTest();
        ConvertContactToCommunityUser.RecordWrapper resultWrapper =  ConvertContactToCommunityUser.getOpportunityAndChecklistDocuments(acc.Id);
        Test.stopTest();
    }
}