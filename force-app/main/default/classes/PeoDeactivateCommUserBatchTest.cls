/*
* History
* -------------------------------
* 10/11/2021	Jidesh 			Created
* 10/11/2021	Matt Fritschi	Added tests for no login automatic notifications
* 11/01/2021	Matt Fritschi	Added tests for no progress automatic notifications
* 11/08/2021	Matt Fritschi	Added tests for open discrepancy automatic notifications
* 02/07/2022	Jake Hinds		Removing audience
* 11/08/2023	Priyanka G		Added New email templates
* 04/26/2024    Josh Cartwright updated test class to look at -1 instead of -2 for reminder emails
*/

@isTest
public class PeoDeactivateCommUserBatchTest {
    
    @testSetup 
    static void recordSetup() {
        System.runAs(new User(Id=UserInfo.getUserId())){
            List<EmailTemplate> templates = new List<EmailTemplate>();
            
            EmailTemplate validEmailTemplate = new EmailTemplate();
            validEmailTemplate.isActive = true;
            validEmailTemplate.Name = 'Deactivation Email';
            validEmailTemplate.DeveloperName = 'unique_name_addSomethingSpecialHere';
            validEmailTemplate.TemplateType = 'text';
            validEmailTemplate.FolderId = UserInfo.getUserId();
            templates.add(validEmailTemplate);
            
            EmailTemplate validEmailTemplate2 = new EmailTemplate();
            validEmailTemplate2.isActive = true;
            validEmailTemplate2.Name = 'PEOUW Edge Email Login Reminder Day 3';
            validEmailTemplate2.DeveloperName = 'User_registered_3';
            validEmailTemplate2.TemplateType = 'text';
            validEmailTemplate2.FolderId = UserInfo.getUserId();
            templates.add(validEmailTemplate2);
            
            EmailTemplate validEmailTemplate3 = new EmailTemplate();
            validEmailTemplate3.isActive = true;
            validEmailTemplate3.Name = 'PEOUW Edge Email Keep Going Reminder 3';
            validEmailTemplate3.DeveloperName = 'User_Has_No_Activity_3';
            validEmailTemplate3.TemplateType = 'text';
            validEmailTemplate3.FolderId = UserInfo.getUserId();
            templates.add(validEmailTemplate3);
            
            EmailTemplate validEmailTemplate4 = new EmailTemplate();
            validEmailTemplate4.isActive = true;
            validEmailTemplate4.Name = 'Discrepancy Logged/Not Resolved';
            validEmailTemplate4.DeveloperName = 'Discrepancy_Logged_Not_Resolved';
            validEmailTemplate4.TemplateType = 'text';
            validEmailTemplate4.FolderId = UserInfo.getUserId();
            templates.add(validEmailTemplate4);
            /*
            EmailTemplate validEmailTemplate5 = new EmailTemplate();
            validEmailTemplate5.isActive = true;
            validEmailTemplate5.Name = 'Deactivation Email';
            validEmailTemplate5.DeveloperName = 'unique_name_addSomethingSpecialHere';
            validEmailTemplate5.TemplateType = 'text';
            validEmailTemplate5.FolderId = UserInfo.getUserId();
            templates.add(validEmailTemplate5);*/
            
            insert templates;
        }  
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
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_PEO,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Disqualified'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        
        Schema.RecordTypeInfo peoOpptyRT = RecordTypeHelper.getRecordType('PEO Opportunity Record Type','Opportunity');
        Opportunity opptyB = new Opportunity(Name='testOpptyB', RecordTypeId=peoOpptyRT.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Open'
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,CloseDate=Date.today().addDays(30));
        insert new List<Opportunity>{opptyA,opptyB};
        //Test.setCreatedDate(opptyB.Id, Date.today().addDays(-60));
        
        List<User> salesRep = new List<User>([SELECT Id, Name FROM User WHERE Job_Name__c='Sales Representative' and isActive=true LIMIT 2]);    
        PEO_Onboarding_Checklist__c peoOnbChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c=acctA.Id, Medical_Benefits_Underwriting_Requested__c='Yes', Benefit_Effective_Date__c=System.today(),Opportunity__c =opptyA.Id,Sales_Rep__c=salesRep[0].Id,Name='setupChecklist');
        insert peoOnbChecklist;
        
        
        /*User u = new User(Alias = 'testUser', ProfileId ='00e0g0000010DA0AAM', Sales_Org__c = 'PAY', Username='CnvCntctTestUser@testorg.com', LastName='Testing', Email='TestUser@testorg.com', TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', LanguageLocaleKey='en_US');
        insert u;*/
    }
    
	static testMethod void deactivateUserBatchTest() {
        Account acct = new Account(Name='test acct');
        insert acct;
    	Opportunity opp = new Opportunity(Name='test Opp',AccountId=acct.Id,StageName=Label.OppStage_Qualified,
                                          CloseDate = date.today().addDays(80),Auto_Close_Date__c=date.today());
        insert opp;
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
		Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                        Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User');
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
        System.debug('check.Community_User_First_Login__c='+check.Community_User_First_Login__c+' check.ContactId='+check.ContactId+' check.IsActive='+check.IsActive+' check.IsActive='+check.IsActive);
        
        test.startTest();
        PeoDeactivateCommUserBatch deactvUser = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(deactvUser, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);
        test.stopTest();
        //Opportunity uOpp = [SELECT Id,StageName,Reason_Not_Sold__c FROM Opportunity WHERE Id = :opp.Id LIMIT 1];
        //system.assertEquals(Label.OppStage_Lost,uOpp.StageName);
        //system.assertEquals(Label.Auto_Close_Stage,uOpp.Reason_Not_Sold__c);
    }
    
    static testMethod void testNoLoginEmailNotification() { 
        Account acct = new Account(Name='test acct');
        insert acct;
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User', 
                          Deactivated_due_to_Inactivity__c = System.today());
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
        System.debug('check.Community_User_First_Login__c='+check.Community_User_First_Login__c+' check.ContactId='+check.ContactId+' check.IsActive='+check.IsActive+' check.IsActive='+check.IsActive);
            
        Datetime lastWorkDay;
        for(Integer i = -1; i > -5; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-1 == 1) {
                break;
            }
        }

        Test.setCreatedDate(check.Id, lastWorkDay);
        
        test.startTest();
        PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(sendNotification, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);
        test.stopTest();
        
        System.assertEquals(1, PeoDeactivateCommUserBatch.emailLimits, 'Emails should be sent');
    }
    
    static testMethod void testNoLoginChatterNotification() { 
        Account acct = new Account(Name='test acct');
        insert acct;
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User');
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
        System.debug('check.Community_User_First_Login__c='+check.Community_User_First_Login__c+' check.ContactId='+check.ContactId+' check.IsActive='+check.IsActive+' check.IsActive='+check.IsActive);
            
        Datetime lastWorkDay;
        for(Integer i = -4; i > -10; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-1 == 3) {
                break;
            }
        }

        Test.setCreatedDate(check.Id, lastWorkDay);
        
        test.startTest();
        PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(sendNotification, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);
        test.stopTest();
        
        System.assertEquals(true, PeoDeactivateCommUserBatch.chatterSent, 'Chatters were sent');
    }
    
    static testMethod void testNoProgressEmailNotification() { 
        Account acct = [SELECT Id, Name FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User', Community_User_First_Login__c = System.today());
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
            
        Datetime lastWorkDay;
        for(Integer i = -1; i > -5; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-2 == 1) {
                break;
            }
        }
		
		System.debug('MGF testNoProgressEmailNotification lastWorkDay='+lastWorkDay);
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id, Name, Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Name='setupChecklist'];
        peoOnbChecklist.Last_Change_Made__c = lastWorkDay;
        update peoOnbChecklist;
        
        peoOnbChecklist=[SELECT Id, Last_Change_Made__c, Name FROM PEO_Onboarding_Checklist__c WHERE Id=:peoOnbChecklist.Id];
        System.debug('MGF testNoProgressEmailNotification acct.Id='+acct.Id+' peoOnbChecklist.Id='+peoOnbChecklist.Id+' peoOnbChecklist.Name='+peoOnbChecklist.Name+' peoOnbChecklist.Last_Change_Made__c='+peoOnbChecklist.Last_Change_Made__c);
        test.startTest();
        PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(sendNotification, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);
        test.stopTest();
        
        System.assertEquals(1, PeoDeactivateCommUserBatch.emailLimits, 'Emails should be sent');
    }
    
    static testMethod void testNoProgressChatterNotification() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User', Community_User_First_Login__c = System.today());
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
        System.debug('check.Community_User_First_Login__c='+check.Community_User_First_Login__c+' check.ContactId='+check.ContactId+' check.IsActive='+check.IsActive+' check.IsActive='+check.IsActive);
            
        Datetime lastWorkDay;
        for(Integer i = -4; i > -10; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-1 == 3) {
                break;
            }
        }

        System.debug('MGF testNoProgressEmailNotification lastWorkDay='+lastWorkDay);
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id, Name, Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Name='setupChecklist'];
        peoOnbChecklist.Last_Change_Made__c = lastWorkDay;
        update peoOnbChecklist;
        
        peoOnbChecklist=[SELECT Id, Last_Change_Made__c, Name FROM PEO_Onboarding_Checklist__c WHERE Id=:peoOnbChecklist.Id];
        System.debug('MGF testNoProgressEmailNotification acct.Id='+acct.Id+' peoOnbChecklist.Id='+peoOnbChecklist.Id+' peoOnbChecklist.Name='+peoOnbChecklist.Name+' peoOnbChecklist.Last_Change_Made__c='+peoOnbChecklist.Last_Change_Made__c);
        
        test.startTest();
        PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(sendNotification, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);
        test.stopTest();
        
        System.assertEquals(true, PeoDeactivateCommUserBatch.chatterSent, 'Chatters were sent');
    }
    
    static testMethod void testOpenDiscrepancyEmailNotification() { 
        Account acct = [SELECT Id, Name FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User', Community_User_First_Login__c = System.today());
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
            
        Datetime lastWorkDay;
        for(Integer i = -1; i > -5; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-2 == 1) {
                break;
            }
        }
		
		System.debug('MGF testNoProgressEmailNotification lastWorkDay='+lastWorkDay);
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id, Name, Most_Recent_Open_Discrepancy__c FROM PEO_Onboarding_Checklist__c WHERE Name='setupChecklist'];
        peoOnbChecklist.Most_Recent_Open_Discrepancy__c = lastWorkDay;
        update peoOnbChecklist;
        
        peoOnbChecklist=[SELECT Id, Most_Recent_Open_Discrepancy__c, Name FROM PEO_Onboarding_Checklist__c WHERE Id=:peoOnbChecklist.Id];
        System.debug('MGF testNoProgressEmailNotification acct.Id='+acct.Id+' peoOnbChecklist.Id='+peoOnbChecklist.Id+' peoOnbChecklist.Name='+peoOnbChecklist.Name+' peoOnbChecklist.Most_Recent_Open_Discrepancy__c='+peoOnbChecklist.Most_Recent_Open_Discrepancy__c);
        test.startTest();
        PeoDeactivateCommUserBatch.scheduleBatch(PeoDeactivateCommUserBatch.MODE_PEO_UNDERWRITING_CHECKLIST, true);
        //PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        //Integer batchSize = 500;
        //database.executeBatch(sendNotification, batchSize);
        //SchedulableContext sc = null;
        //PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        //tsc.execute(sc);
        test.stopTest();
        
    }
    
    static testMethod void testOpenDiscrepancyChatterNotification() {
        Account acct = [SELECT Id, Name FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        insert new Apex_Batch_Control__c(Name='PeoDeactivateCommUserBatch',Active__c=true,Check_Days__c = 365);
        Contact newCommUserContact = [SELECT Id,AccountId FROM Contact WHERE email='c1a1@whoknows.com' LIMIT 1];
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Login User Clone']; 
        User u = new User(Alias = 'testUser', Email='commuser@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='commuser@testorg.com',
                          Sales_Org__c = 'PAY', ContactId = newCommUserContact.Id, FirstName = 'deactivateUserBatchTest Test User',Community_User_First_Login__c = System.today());
        insert u;
        
        User check = [Select Id,IsActive,AccountId,LastLoginDate,Name,ProfileName__c,Username,Email,CreatedDate,Community_User_First_Login__c,ContactId,contact.HasOptedOutOfEmail,FirstName
        from User where ProfileName__c = 'Customer Community Login User Clone' AND IsActive= true AND FirstName = 'deactivateUserBatchTest Test User' LIMIT 1];
        System.debug('check.Community_User_First_Login__c='+check.Community_User_First_Login__c+' check.ContactId='+check.ContactId+' check.IsActive='+check.IsActive+' check.IsActive='+check.IsActive);
            
        Datetime lastWorkDay;
        for(Integer i = -4; i > -10; i--) {
            lastWorkDay = Datetime.now().addDays(i);
            Date startDate = date.newinstance(lastWorkDay.year(), lastWorkDay.month(), lastWorkDay.day());
            System.debug('i='+i+' lastWorkDay.day()='+lastWorkDay.day()+' lastWorkDay.month()='+lastWorkDay.month());
            System.debug('numDays = '+PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today()));
            if(PeoDeactivateCommUserBatch.getWorkingDays(startDate, Date.today())-2 == 4) {
                break;
            }
        }

        System.debug('MGF testNoProgressEmailNotification lastWorkDay='+lastWorkDay);
        PEO_Onboarding_Checklist__c peoOnbChecklist = [SELECT Id, Name, Most_Recent_Open_Discrepancy__c FROM PEO_Onboarding_Checklist__c WHERE Name='setupChecklist'];
        peoOnbChecklist.Most_Recent_Open_Discrepancy__c = lastWorkDay;
        update peoOnbChecklist;
        
        peoOnbChecklist=[SELECT Id, Most_Recent_Open_Discrepancy__c, Name FROM PEO_Onboarding_Checklist__c WHERE Id=:peoOnbChecklist.Id];
        System.debug('MGF testNoProgressEmailNotification acct.Id='+acct.Id+' peoOnbChecklist.Id='+peoOnbChecklist.Id+' peoOnbChecklist.Name='+peoOnbChecklist.Name+' peoOnbChecklist.Most_Recent_Open_Discrepancy__c='+peoOnbChecklist.Most_Recent_Open_Discrepancy__c);
        
        test.startTest();
        PeoDeactivateCommUserBatch.scheduleBatch(PeoDeactivateCommUserBatch.MODE_PEO_UNDERWRITING_CHECKLIST, true);
        /*PeoDeactivateCommUserBatch sendNotification = new PeoDeactivateCommUserBatch();
        Integer batchSize = 500;
        database.executeBatch(sendNotification, batchSize);
        SchedulableContext sc = null;
        PeoDeactivateCommUserBatch tsc = new PeoDeactivateCommUserBatch();
        tsc.execute(sc);*/
        test.stopTest();
        
        System.assertEquals(true, PeoDeactivateCommUserBatch.chatterSent, 'Chatters were sent');
    }
}