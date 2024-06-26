/*
 * Test method for CaseS2SQueueable
 * 
 *History
 * -------
 * 09/24/2018 	Jermaine Stukes   	Created
 * 10/31/2019	Jermaine Stukes		Updated
 * 07/06/2020	Jacob Hinds			Adding in additional skill mapping fields to generateJSON
 * 01/31/2022	Jermaine Stukes		Add Retry test
 * 03/23/2023   Dan Carmen          New retryList variable and increment the counter on the logs to control the retries.
 * 11/13/2023   Reetesh Pandey		Added logic for CER,DSCUn,eIMP, eDSC and updated rev location 
*/
@isTest
public class CaseS2SQueueableTest {
    
    @testSetup
    Static void Setup()
    {
        //Create User
        UserTestHelper uth = new UserTestHelper();
        User curUser = uth.getUserById(UserInfo.getUserId());
        Profile prof1 = [select id from profile where name='Standard User' limit 1];
        UserHelper uh = new UserHelper();
        Group UCqueueId = uh.getQueue('UC_Specialist_Queue');

        // create a User where the community nickname equals the email address
       User testUser = new User(FirstName = 'Test'
                                 ,LastName = 'User'
                                 ,Title = 'Test'
                                 ,Username = 'fLast1@abc.com.test'
                                 ,Email='sfdc_automation@paychex.com'
                                 ,Sales_Org__c = 'MMS'
                                 ,IsActive = true
                                 // person id
                                 ,EmployeeNumber = 'TestEmp-112233'
                                 //,ManagerId = curUser.ManagerId
                                 ,HR_Person_ID__c = '8765309'
                                 ,Hire_Date__c = Date.today()
                                 ,Department = 'Test Dept'
                                 ,Alias = 'alias01'
                                 ,CommunityNickname = 'nickname01'
                                 ,MobilePhone = '585-123-6544'
                                 ,Phone = '585-123-6543'
                                 // rep code
                                 ,Person_ID_Number__c = 'A123'
                                 ,Street = '123 Some St'
                                 ,City = 'Somewhere'
                                 ,PostalCode = '14514'
                                 ,State = 'NY'
                                 ,Cost_Center__c = '0017'
                                 ,District__c = '0017'
                                 ,Creation_Type__c = 'NewUser'
                                 ,TimeZoneSidKey = 'GMT'
                                 ,LocaleSidKey='en_US'
                                 ,EmailEncodingKey='UTF-8'
                                 ,ProfileId=prof1.Id
                                 ,LanguageLocaleKey = 'en_US'
                                );
        insert testUser;
        //Create WebService Setting
        WebServiceSettings__c ucWebServiceSetting = new WebServiceSettings__c(
        Name = 'S2S_UC_Service'
            ,Certificate__c = Label.Test_Class_Certificate_Name
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,Endpoint__c = 'https://webservices.paychex.com/rest/corporate/sfdc/1_0/resources/interactions/?source=Upstream'
        );
        insert ucWebServiceSetting;
        //Create Assignment Record
        S2S_Assignment__c payrollUCAsssignment = new S2S_Assignment__c(
            Name = 'Payroll Flex UC'
            ,Product__c = 'Payroll'
            ,Condition1_Field__c = 'Type'
            ,Condition1__c = 'FLEX Client_HR Solutions FLEX Client'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Issue_Type__c'
            ,Condition2__c = 'Next Level Escalation'
            ,Condition2_Field_Not_Equal__c = true
            ,Condition3_Field_Not_Equal__c = true
            ,Condition3_AcctField__c = true
            ,Condition3_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition3__c = '940_942_943_944_1240_1242_1244_1243');
         S2S_Assignment__c flextimeAssignment = new S2S_Assignment__c(
            Name = 'FlexTime'
            ,Product__c = 'FlexTime'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition2__c = '940_942_943_944_1240_1242_1244_1243_4012'
            ,Condition2_AcctField__c = true
            ,Condition3_Field__c = 'Issue_Type__c'
            ,Condition3__c = 'Next Level Escalation'
            ,Condition3_Field_Not_Equal__c = true);
        S2S_Assignment__c[] s2sAssignList = new S2S_Assignment__c[]{flextimeAssignment,payrollUCAsssignment};
            insert s2sAssignList;
        //Create Assignment Map Records
        S2S_Assignment_Maps__c payrollUCAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'Payroll Flex UC'
            ,DefaultQueueId__c = label.UC_Queue);
        S2S_Assignment_Maps__c flextimeAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'FlexTime'
            ,AssignmentId1__c = 'Paychex_Payroll_Specialist__c'
            ,AssignmentId2__c = 'MMS_MAM_NAM__c'
            ,AssignmentId3__c = 'TLO_Implementation_Coordinator__c'
            ,FieldAssignment3UserMap__c = 'Id'
            ,Escalated__c = false
            ,DefaultQueueId__c = '00G70000003oGzi');
        S2S_Assignment_Maps__c[] s2sAssignMapList = new S2S_Assignment_Maps__c[]{flextimeAssignmentMap,payrollUCAssignmentMap};
        insert s2sAssignMapList;
        //Create Case Type Records
        S2S_Case_Types__c s2sCaseType = new S2S_Case_Types__c(
            Name = 'Sales2Service'
            ,Field_List__c = 'Type,Product__c,Issue_Type__c,Subject,Description');
        insert s2sCaseType;
        S2S_Skill_Mapping__c dscMappingPRS = new S2S_Skill_Mapping__c(Name='DSC 1', Revenue_Location__c='4012', Skill__c='DSC1',Product__c='Payroll',Assign_To_Field__c='Paychex_Payroll_Specialist__c',Payroll_Specialist__c=true);
        S2S_Skill_Mapping__c dscMappingNoPRS = new S2S_Skill_Mapping__c(Name='DSC 1 No PRS', Revenue_Location__c='4012', Skill__c='DSC1',Product__c='Payroll',Assign_To_Field__c='',Payroll_Specialist__c=false);
        S2S_Skill_Mapping__c impMapping = new S2S_Skill_Mapping__c(Name='940Imp', Revenue_Location__c='940', Skill__c='0940_Imp',Product__c='Payroll',Assign_To_Field__c='MMS_AS__c',Payroll_Specialist__c=false);
        S2S_Skill_Mapping__c[] skillMappings = new S2S_Skill_Mapping__c[]{dscMappingPRS,dscMappingNoPRS,impMapping};
        insert skillMappings;
        //Create Default Records
        S2S_Mapping_Defaults__c defaultPayroll = new S2S_Mapping_Defaults__c(
            Name = 'Payroll'
            ,Product__c = 'Payroll'
            ,QueueId__c = '00G70000003oGzi');
            insert defaultPayroll;
        //Create test account and contact for case
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        Contact ctct1 = new Contact(Firstname = 'Salesforce'
                                ,Lastname = 'Support'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        insert ctct1;
    }//Setup()
    
    static testMethod void testQueueableJob()
    {    
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
        upsert con2;
        acct1.AccountNumber = '4012-123456';
        acct1.Revenue_Location__c = 4012;
        acct1.Type = 'FLEX Client';
        acct1.Paychex_Payroll_Specialist__c = con2.Id;
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Alternate_Contact__c = con2.id
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+con1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController cs2sc = new CaseS2SController();
        cs2sc.initialize();
        cs2sc.s2sCase = case1;
        cs2sc.attachBody = blob.valueof('TEST');
        cs2sc.attachName = 'Test File';
        cs2sc.saveKase(); 
        test.stopTest();
        Case kase = [select Id, OwnerId, ProcessNotes__c, (Select ContentDocument.Id from ContentDocumentLinks),(Select Id from CaseComments) from Case where Id=:case1.Id];
        System.assertEquals(label.UC_Queue, kase.OwnerId);
        System.assert(kase.ProcessNotes__c.Contains('Submitted through S2S QA'));
    }
    static testMethod void testReTry(){
                Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
                Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'FlexTime'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        test.startTest();
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.UcServiceCaseId__c = case1.Id;
        wsLog.UC_Service__c = true;
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.Successful__c = false;
        wsLog.NamedFunction__c = 'createUcCase';
        wsLog.UC_Retry__c = true;
        insert wsLog;
        CaseS2SQueueable cS2S = new CaseS2SQueueable(new Web_Service_Log__c[]{wsLog});
        cS2S.launchQueueable();
        test.stopTest();
        Web_Service_Log__c checkLog = [Select Id, UC_Retry__c from Web_Service_Log__c where Id=:wsLog.Id];
        System.assert(!checkLog.UC_Retry__c);
    }
    static testMethod void testCaseComments()
    {    
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
        update con2;
        acct1.AccountNumber = '4012-123456';
        acct1.Revenue_Location__c = 4012;
        acct1.Type = 'FLEX Client';
        acct1.Paychex_Payroll_Specialist__c = con2.Id;
        update acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'FlexTime'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Alternate_Contact__c = con2.id
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        insert case1;
        Case kase = [select Id, OwnerId, ProcessNotes__c, (Select ContentDocument.Id from ContentDocumentLinks),(Select Id from CaseComments) from Case where Id=:case1.Id];
        CaseComment testComment = new CaseComment(ParentId = kase.Id, CommentBody = 'Test', CreatedById = kase.OwnerId);
        insert testComment;
        kase.Product__c = 'Payroll';
        update kase;
    }    
    static testMethod void testReAssignSkill()
    {
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        
        upsert con2;
        acct1.AccountNumber = '4012-123456';
        acct1.Type = 'FLEX Client';
        acct1.Paychex_Payroll_Specialist__c = con2.Id;
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        test.startTest();
        //S2S Quick Action Data
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+con1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController cs2sc = new CaseS2SController();
        cs2sc.initialize();
        cs2sc.s2sCase = case1;
        cs2sc.saveKase();
        System.assert(cs2sc.s2sCase.id != null);
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.UcServiceCaseId__c = cs2sc.s2sCase.id;
        wsLog.UC_Service__c = true;
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.Successful__c = false;
        
        wsLog.NamedFunction__c = 'createUcCase';
        insert wsLog;
        wsLog.Rest_Response__c = '{"message" : "SkillAddress is not valid "}';
        update wsLog;
        test.stopTest();
        List<Web_Service_Log__c> reassignLog = [Select Id, Invalid_Skill__c from Web_Service_Log__c where UcServiceCaseId__c =:case1.Id and Invalid_Skill__c = true limit 1];
        System.assert(!reassignLog.IsEmpty());
    }
    static testMethod void testPackageChange()
    {   
        S2S_Skill_Mapping__c pkgChngMapping = new S2S_Skill_Mapping__c(Name='Payroll_S2S_PackageChange', Revenue_Location__c='',Skill__c='PackageChange',Product__c='Payroll',Payroll_Specialist__c=false,Condition1_Field__c ='Issue_Type__c',Condition1_Value__c ='Package Change');
        S2S_Skill_Mapping__c [] skillMappings = new S2S_Skill_Mapping__c[]{pkgChngMapping};
        insert  skillMappings;
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
        upsert con2;
        acct1.AccountNumber = '4012-123456';
        acct1.Revenue_Location__c = null;
        acct1.Type = 'FLEX Client';
        acct1.Paychex_Payroll_Specialist__c = con2.Id;
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'Package Change'
                               ,Subject = 'New Test'
                               ,Alternate_Contact__c = con2.id
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+con1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController cs2sc = new CaseS2SController();
        cs2sc.initialize();
        cs2sc.s2sCase = case1;
        cs2sc.attachBody = blob.valueof('TEST');
        cs2sc.attachName = 'Test File';
        cs2sc.saveKase(); 
        test.stopTest();
        Case kase = [select Id, OwnerId, ProcessNotes__c, (Select ContentDocument.Id from ContentDocumentLinks),(Select Id from CaseComments) from Case where Id=:case1.Id];
        System.assertEquals(label.UC_Queue, kase.OwnerId);
        System.assert(kase.ProcessNotes__c.Contains('Submitted through S2S QA'));
    }
    //CER Reetesh
    static testMethod void testCERChange()
    {   
        S2S_Skill_Mapping__c cerChngMapping = new S2S_Skill_Mapping__c(Name='Payroll CER', Revenue_Location__c='',Skill__c='CER',Product__c='Payroll',Payroll_Specialist__c=false,Service_Model_Type__c='eComm Implementation (eIMP)',Condition1_Field__c ='');
        S2S_Skill_Mapping__c [] skillMappings = new S2S_Skill_Mapping__c[]{cerChngMapping};
        insert  skillMappings;   
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
        upsert con2;
        acct1.AccountNumber = '4012-123456';
        acct1.Revenue_Location__c = null;
        acct1.Type = 'FLEX Client';
        acct1.Paychex_Payroll_Specialist__c = con2.Id;
        acct1.Service_Model_Type__c ='eComm Implementation (eIMP)';
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'Package Change'
                               ,Subject = 'New Test'
                               ,Alternate_Contact__c = con2.id
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        PageReference pageRef = new PageReference('/apex/SalesToService?id='+con1.Id);
        test.setCurrentPageReference(pageRef);
        CaseS2SController cs2sc = new CaseS2SController();
        cs2sc.initialize();
        cs2sc.s2sCase = case1;
        cs2sc.attachBody = blob.valueof('TEST');
        cs2sc.attachName = 'Test File';
        cs2sc.saveKase(); 
        test.stopTest();
        Case kase = [select Id, OwnerId, ProcessNotes__c, (Select ContentDocument.Id from ContentDocumentLinks),(Select Id from CaseComments) from Case where Id=:case1.Id];
        System.assertEquals(label.UC_Queue, kase.OwnerId);
        System.assert(kase.ProcessNotes__c.Contains('Submitted through S2S QA'));
    }
}