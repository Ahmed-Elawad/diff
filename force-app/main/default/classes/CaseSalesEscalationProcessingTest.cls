/**
 * Test methods for new CaseSalesEscalationProcessing
 *
 *  History
 *  --------
 *  05/31/2017  Jermaine Stukes     created
 *  08/24/2017  Cindy Freeman		added temporary hack to check SFDC instance to get right record type  
 * 	03/05/2017	Jermaine Stukes		Added additional test methods
 *	03/26/2018	Jermaine Stukes		Updated Test Methods
	06/11/2018	Jermaine Stukes		More test method updates
	11/25/2019	Matt Fritschi		Commented out testFlexForwardAssignments test method (Routing Rule was removed)
	06/18/2020	Jake Hinds			Test method for resubmission checkbox
 */
@isTest(SeeAllData=false)
public class CaseSalesEscalationProcessingTest {
    
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
                                 ,Email='fLast1@abc.com'
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
        //Create Assignment Records
        S2S_Assignment__c hroAssignment = new S2S_Assignment__c(
            Name = 'HRO MPSC'
            ,Product__c = 'HRO'
            ,Condition1__c = 'CurrentClient__c'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition2__c = '940_942_943_944_1240_1242_1244_1243'
            ,Condition2_AcctField__c = true
            ,Condition3_Field__c = 'Issue_Type__c'
            ,Condition3__c = 'Next Level Escalation'
            ,Condition3_Field_Not_Equal__c = true);
        S2S_Assignment__c flextimeAssignment = new S2S_Assignment__c(
            Name = 'FlexTime'
            ,Product__c = 'FlexTime'
            ,Condition1__c = 'CurrentClient__c'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition2__c = '940_942_943_944_1240_1242_1244_1243'
            ,Condition2_AcctField__c = true
            ,Condition3_Field__c = 'Issue_Type__c'
            ,Condition3__c = 'Next Level Escalation'
            ,Condition3_Field_Not_Equal__c = true);
        S2S_Assignment__c flextimeEscAssignment = new S2S_Assignment__c(
            Name = 'FlexTime_Escalated'
            ,Product__c = 'FlexTime'
            ,Condition1__c = 'CurrentClient__c'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition2__c = '940_942_943_944_1240_1242_1244_1243'
            ,Condition2_AcctField__c = true
            ,Condition3_Field__c = 'Issue_Type__c'
            ,Condition3__c = 'Next Level Escalation'
            ,Condition3_Field_Not_Equal__c = false);
        S2S_Assignment__c payrollSFDCAsssignment = new S2S_Assignment__c(
            Name = 'Payroll Flex SFDC'
            ,Product__c = 'Payroll'
            ,Condition1_Field__c = 'Type'
            ,Condition1__c = 'FLEX Client_HR Solutions FLEX Client'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Issue_Type__c'
            ,Condition2__c = 'Next Level Escalation'
            ,Condition2_Field_Not_Equal__c = true
            ,Condition3_Field_Not_Equal__c = false
            ,Condition3_AcctField__c = true
            ,Condition3_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition3__c = '940_942_943_944_1240_1242_1244_1243');
        S2S_Assignment__c payrollUCAsssignment = new S2S_Assignment__c(
            Name = 'Payroll Flex UC'
            ,Product__c = 'Payroll'
            ,Condition1_Field__c = 'Type'
            ,Condition1__c = 'FLEX Client_HR Solutions FLEX Client'
            ,Condition1_AcctField__c = true
            ,Condition2_Field__c = 'Issue_Type__c'
            ,Condition2__c = 'Next Level Escalation'
            ,Condition2_Field_Not_Equal__c = true
            ,Condition3_Field_Not_Equal__c = TRUE
            ,Condition3_AcctField__c = true
            ,Condition3_Field__c = 'Payroll_Branch_Nbr__c'
            ,Condition3__c = '940_942_943_944_1240_1242_1244_1243');
        S2S_Assignment__c[] s2sAssignList = new S2S_Assignment__c[]{hroAssignment, flextimeEscAssignment, flextimeAssignment,payrollSFDCAsssignment,payrollUCAsssignment};
            insert s2sAssignList;
        //Create Assignment Map Records
        S2S_Assignment_Maps__c hroAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'HRO MPSC'
            ,AssignmentId1__c = 'Paychex_Payroll_Specialist__c'
            ,AssignmentId2__c = 'MMS_MAM_NAM__c'
            ,AssignmentId3__c = 'HRO_Implementation_Coordinator__c'
            ,FieldAssignment3UserMap__c = 'Id'
            ,DefaultQueueId__c = '00G70000003oGzi');
        S2S_Assignment_Maps__c flextimeEscAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'FlexTime_Escalated'
            ,AssignmentId1__c = 'Paychex_Payroll_Specialist__c'
            ,AssignmentId2__c = 'MMS_MAM_NAM__c'
            ,AssignmentId3__c = 'TLO_Implementation_Coordinator__c'
            ,FieldAssignment3UserMap__c = 'Id'
            ,Escalated__c = true
            ,DefaultQueueId__c = '00G70000003oGzi');
        S2S_Assignment_Maps__c flextimeAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'FlexTime'
            ,AssignmentId1__c = 'Paychex_Payroll_Specialist__c'
            ,AssignmentId2__c = 'MMS_MAM_NAM__c'
            ,AssignmentId3__c = 'TLO_Implementation_Coordinator__c'
            ,FieldAssignment3UserMap__c = 'Id'
            ,DefaultQueueId__c = '00G70000003oGzi');
        S2S_Assignment_Maps__c payrollSFDCAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'Payroll Flex SFDC'
            ,AssignmentId1__c = 'Paychex_Payroll_Specialist__c'
            ,DefaultQueueId__c = '00G70000003oGzi');
        S2S_Assignment_Maps__c payrollUCAssignmentMap = new S2S_Assignment_Maps__c(
            Name = 'Payroll Flex UC'
            ,DefaultQueueId__c = label.UC_Queue);
        S2S_Assignment_Maps__c[] s2sAssignMapList = new S2S_Assignment_Maps__c[]{hroAssignmentMap, flextimeEscAssignmentMap, flextimeAssignmentMap, payrollSFDCAssignmentMap,payrollUCAssignmentMap};
        insert s2sAssignMapList;
        //Create Case Type Records
        S2S_Case_Types__c s2sCaseType = new S2S_Case_Types__c(
            Name = 'Sales2Service'
            ,Field_List__c = 'Type,Product__c,Issue_Type__c,Subject,Description');
        insert s2sCaseType;
        //Create Default Records
        S2S_Mapping_Defaults__c default401k = new S2S_Mapping_Defaults__c(
            Name = '401K'
            ,Product__c = '401K'
            ,QueueId__c = '005700000049XP3');
        S2S_Mapping_Defaults__c defaultFlextime = new S2S_Mapping_Defaults__c(
            Name = 'FlexTime'
            ,Product__c = 'FlexTime'
            ,QueueId__c = '00G700000044SPa');
        S2S_Mapping_Defaults__c defaultPayroll = new S2S_Mapping_Defaults__c(
            Name = 'Payroll'
            ,Product__c = 'Payroll'
            ,QueueId__c = '00G70000003oGzi');
        S2S_Mapping_Defaults__c defaultHRO = new S2S_Mapping_Defaults__c(
            Name = 'HRO'
            ,Product__c = 'HRO'
            ,QueueId__c = '00G700000044SPa');
        S2S_Mapping_Defaults__c[] s2sDefaultList = new S2S_Mapping_Defaults__c[]{default401k, defaultFlextime, defaultPayroll, defaultHRO};
            insert s2sDefaultList;
        //Create Account and contacts
        CreateTestData.createSingleAandTwoCts();
    }//Setup()
    static testMethod void testSuccessfulDefaultQUeue()
    {
        
        Contact con1 = [Select Id, Name, AccountId  from Contact where Email=:'fLast1@abc.com'];
       	//S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = '401K'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                              ,accountId = con1.AccountId);
        test.startTest();
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assert(case1.Id !=Null);
        System.assert(kase.OwnerId !=Null);
        S2S_Mapping_Defaults__c defaultQ = S2S_Mapping_Defaults__c.getInstance('401K');
        String ownerId = defaultQ.QueueId__c;
        System.assertEquals(kase.OwnerId, ownerId);
        
    }
    /*
    static testMethod void testFlexForwardAssignments()
    {
        String ffQueue = label.Flex_Forward_Queue;
        Account acct1 = [Select Id, Name, AccountNumber, Bis_ID__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId from Contact where AccountId=:acct1.Id limit 1];
        acct1.Migration_Status__c = 'Client Lost';
        test.startTest();
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'HRO'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,AccountId = acct1.Id);
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assert(case1.Id !=Null);
        System.assertEquals(ffQueue, kase.OwnerId);
        
    }
*/
    static testMethod void testDefaultandUpdate()
    {    
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c, ManagerId, Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        acct1.AccountNumber = '4012-123456';
        acct1.Type = 'FLEX Client';
        acct1.Bis_ID__c = 1112222;
        acct1.First_Run_Date__c = Date.today()+7;
        test.startTest();
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'HRO'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        insert case1;
        case1.Product__c = '401k';
        update case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        S2S_Mapping_Defaults__c defaultQ = S2S_Mapping_Defaults__c.getInstance('401K');
        String ownerId = defaultQ.QueueId__c;
        System.assertEquals(ownerId, kase.OwnerId);
        
    }
    static testMethod void testSFDCPayrollAssignments()
    {    
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
        upsert con2;
        acct1.AccountNumber = '940-123456';
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
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assertEquals(con2.User_Lookup__c, kase.OwnerId);
        
    }
    static testMethod void testUCPayrollAssignments()
    {    
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type, User_Lookup__c from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        con2.User_Lookup__c = uzer1.Id;
        test.startTest();
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
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId,Resubmit_Case__c from Case where Id=:case1.Id];
        System.assertEquals(label.UC_Queue, kase.OwnerId);
        
        kase.Resubmit_Case__c = true;
        update kase;
        //only created on update, if insert it would have had to be submitted through the s2s controller, not trigger.
        Web_Service_Log__c[] wsls = [SELECT id FROM Web_Service_Log__c WHERE UC_Service__c = true AND UcServiceCaseId__c = :kase.Id];
        system.assert(wsls!=null);
        system.assertEquals(1,wsls.size());
        
    }
    static testMethod void testFlexTime_TLOIC()
    {
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where Email=:'fLast1@abc.com' and AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, User_Lookup__c, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c, ManagerId, Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        acct1.AccountNumber = '940-123456';
        acct1.Type = 'FLEX Client';
        acct1.Bis_ID__c = 11122234;
        acct1.First_Run_Date__c = Date.today()+7;
        acct1.TLO_Implementation_Coordinator__c = uzer1.Id;
        test.startTest();
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Servicee'
                               ,Product__c = 'FlexTime'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assertEquals(uzer1.Id, kase.OwnerId);
        
    }
    static testMethod void testHRO_SIPM()
    {
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, User_Lookup__c, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c,  Sales_Org__c, ManagerId from User where Person_ID_Number__c='A123' limit 1];
        acct1.AccountNumber = '940-123456';
        acct1.Type = 'FLEX Client';
        acct1.MMS_MAM_NAM__c = con2.Id;
        acct1.Bis_ID__c = 1112222;
        acct1.First_Run_Date__c = Date.today()+7;
        acct1.Paychex_Payroll_Specialist__c = null;
        acct1.HRO_Implementation_Coordinator__c = null;
        test.startTest();
        upsert acct1;
        con2.User_Lookup__c = uzer1.Id;
        upsert con2;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        //Test First Assignment
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'HRO'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assertEquals(con2.User_Lookup__c, kase.OwnerId);
    }
    static testMethod void testHRO_ImpCoordinator()
    {
        Account acct1 = [Select Id, Name, AccountNumber, Paychex_Payroll_Specialist__c, MMS_MAM_NAM__c, HRO_Implementation_Coordinator__c, Type from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        Contact con2 = [Select Id, Name, Email, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where Email=:'sLast1@abc.com' and AccountId=:acct1.Id limit 1];
        User uzer1 = [Select Id,Person_ID_Number__c, ManagerId, Sales_Org__c from User where Person_ID_Number__c='A123' limit 1];
        acct1.AccountNumber = '940-123456';
        acct1.Type = 'FLEX Client';
        acct1.Bis_ID__c = 1112222;
        acct1.First_Run_Date__c = Date.today()+7;
        acct1.Paychex_Payroll_Specialist__c = null;
        acct1.MMS_MAM_NAM__c = null;
        acct1.HRO_Implementation_Coordinator__c = uzer1.Id;
        test.startTest();
        upsert acct1;
        //S2S Record Type
        Schema.RecordTypeInfo salesOpsrt = RecordTypeHelper.getRecordType(label.RT_Case_S2S, 'Case');
        Case case1 = new Case (recordtypeId = salesOpsrt.getRecordTypeId()
                               ,Type='Sales2Service'
                               ,Product__c = 'HRO'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id
                               ,accountId = con1.AccountId);
        insert case1;
        test.stopTest();
        Case kase = [select Id, OwnerId from Case where Id=:case1.Id];
        System.assertEquals(uzer1.Id, kase.OwnerId);
       
    }
}