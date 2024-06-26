/**
 * Test class for NSSLegacyHistoryController visualforce page
  * History
 * -------
 * 02/03/2014 Cindy Freeman   Created
 * 08/22/2018 Cindy Freeman	  Modified to test for Files instead of Attachments
*  04/24/2019 Jermaine Stukes	Add test methods
   04/16/2021 Dan Carmen        Increment API version
   01/31/2022 Jermaine Stukes	Updated s2s methods
 */
@isTest
private class WebServicesHelperTest {
 
    @testSetUp
    static void SetUp(){
        List<Support_Process__c> spList = new List<Support_Process__c>();
        Support_Process__c spS2S = new Support_Process__c(
        Name = 'S2S - Default'
            ,Chatter_Group__c = '0F90g000000XkDi'
            ,Chatter_Notification__c = 'S2S queueable job returned error message'
            ,Create_SNOW_Case__c = false
            ,Create_Chatter_Message__c = true
            ,Exception_caught__c = 'Default'
            ,Process_being_supported__c = 'S2S'
        );
        spList.add(spS2S);
        Support_Process__c sp2S2S = new Support_Process__c(
            Name = 'S2S-failure limit reached'
            ,Chatter_Group__c = '0F90g000000XkDi'
            ,Chatter_Notification__c = 'S2S queueable job returned error message'
            ,Create_SNOW_Case__c = true
            ,Create_Chatter_Message__c = true
            ,Exception_caught__c = 'Consecutive failure limit reached'
            ,Process_being_supported__c = 'S2S'
        );
        spList.add(sp2S2S);
        insert spList;
        WebServiceSettings__c wssS2S = new WebServiceSettings__c (
            Name = 'S2S_UC_Service'
            ,certificate__c = label.S2S_Certificate //'sfdcuserfull'
            ,Timeout__c = '12000'
            ,endpoint__c='https://webservicesimp.paychex.com/rest/corporate/sfdc-dev/1_0/resources/interactions/?source=Upstream'
            ,IsActive__c=true);
        upsert wssS2S;
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                             ,recordtypeId = acctCorert.getRecordTypeId()
                             ,type = 'MMS Client'
                             ,BillingPostalCode = '10000'
                             ,AccountNumber = '83-1234567'
                             ,Do_Not_Call__c = true
                             ,Phone = '555-1212'
                             ,Email_Opt_Out__c = true
                             ,AnnualRevenue = 25);
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                            ,Lastname = 'Last1'
                            ,recordtypeId = ctctCorert.getRecordTypeId()
                            ,Phone = '585-555-1212'
                            ,Email = 'fLast1@abc.com'
                            ,DoNotCall = false
                            ,HasOptedOutOfEmail = false
                            ,AccountId=acct1.Id);
        Contact ctct1a = new Contact(Firstname = 'Second'
                             ,Lastname = 'Last1'
                             ,recordtypeId = ctctCorert.getRecordTypeId()
                             ,Phone = '585-555-2323'
                             ,Email = 'sLast1@abc.com'
                             ,DoNotCall = false
                             ,HasOptedOutOfEmail = false
                             ,AccountId=acct1.Id);
        Contact[] ctcts = new Contact[]{ctct1,ctct1a};
            insert ctcts;
        Profile prof1 = [select id from profile where name='Standard User' limit 1];
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
    }
    static testMethod void wssTest() {
		populateEndpoint();
		
		WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('NSS History external');		
		System.assertEquals(null, wss.Certificate__c);
		System.assertEquals('http://10.25.14.212', wss.Endpoint__c.substring(0,19));
		
		String responsexml = 'This is the response xml.';
		String requestxml = 'This is the request xml.';
	
    	WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
    	wsWrap.svcName = 'Service Error1';
    	wsWrap.succes = false;
    	wsWrap.errMsg = 'Error Message';
    	wsWrap.responsexml = responsexml;
    	wsWrap.requestxml = requestxml;
    	wsWrap.namedFunction = 'Test function';
    	wsWrap.sobjName = 'Test SObject';
    	WebServicesHelper.logServiceCall(wsWrap);
		
		//WebServicesHelper.logServiceCall('Service Error1', false, 'Error Message', Blob.valueOf(responsexml), Blob.valueOf(requestxml));
		Web_Service_Log__c wslog = [Select Id, ServiceName__c, CalledBy__c, CalledDT__c, Successful__c, ErrorMsg__c, Notes__c, NamedFunction__c, SobjName__c 
									from Web_Service_Log__c where ServiceName__c = 'Service Error1'];
		System.assertEquals(System.Today(), wslog.CalledDT__c.date());
		System.assertEquals(UserInfo.getUserId(), wslog.CalledBy__c);
		System.assertEquals(false, wslog.Successful__c);
		System.assertEquals('Service Error1', wslog.ServiceName__c);
		System.assertEquals('Error Message', wslog.ErrorMsg__c);
		System.assertEquals(null, wslog.Notes__c);
		System.assertEquals('Test function', wslog.NamedFunction__c);
		System.assertEquals('Test SObject', wslog.SobjName__c);
		
		
		Attachment[] attached = [Select Id, Name, ParentId, Body from Attachment where ParentId = :wslog.Id];
		System.assertEquals(2, attached.size());
		for (Attachment att: attached)
		{	String myblob = att.Body.toString();
			if (att.Name.right(8) == 'response')
			{	System.assertEquals(true, myblob.contains('This is the response xml.'));	}
			else
			{	System.assertEquals(true, myblob.contains('This is the request xml.'));	}
		} // for attachments
		/*
		ContentDocumentLink[] contentDocList = [Select id, LinkedEntityId, ContentDocumentId from ContentDocumentLink 
												where LinkedEntityId = :wslog.Id];
		Id[] contentIdList = new list<Id>();
		for (ContentDocumentLink cdl: contentDocList)
		{	contentIdList.add(cdl.ContentDocumentId);	}
														
		ContentVersion[] contentList = [select Id, Title, VersionData from ContentVersion where contentDocumentId in :contentIdList];
		System.assertEquals(2, contentList.size());
		
		for (ContentVersion cv : contentList)
		{	String filename = cv.Title;
			String versData = cv.VersionData.toString();
			if (filename.right(8) == 'response')
			{	System.assertEquals(true, versData.contains('This is the response xml.'));	}
			else
			{	System.assertEquals(true, versData.contains('This is the request xml.'));	}
		} // for
		*/
    } // wssTest
    static testMethod void tesSupport1()
    {
        //CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        insert wsLog;
        wsLog.SobjName__c = 'Case';
        wsLog.UC_Service__c = true;
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.Successful__c = false;
        wsLog.Rest_Response__c = 'No APEX Job Created';        
        update wsLog;
        test.stopTest();
        Web_Service_Log__c testLog = [Select Id, SnowCaseCreated__c from Web_Service_Log__c where Id=:wsLog.Id];
        System.assertEquals(false, testLog.SnowCaseCreated__c);
        
    }
    static testMethod void testInvalidSkill()
    {
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id);
        
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        insert wsLog;
        wsLog.SobjName__c = 'Case';
        wsLog.UC_Service__c = true;
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.UcServiceCaseId__c = case1.Id;
        wsLog.Successful__c = false;
        wsLog.Rest_Response__c = '{"message" : "SkillAddress is not valid "}';       
        update wsLog;
        test.stopTest();
        List<Web_Service_Log__c> wsLogList = [Select Id, Successful__c from Web_Service_Log__c where UcServiceCaseId__c =:case1.Id Order By CreatedDate ASC];
        System.assertEquals(2, wsLogList.size());
        
        //
    }
    static testMethod void testCreateWsLog()
    {
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id);
        insert case1;
        WebServicesHelper wsh = new WebServicesHelper();
        wsh.createWsLog(case1.Id);
        Web_Service_Log__c wsLog2 = [Select Id, Successful__c from Web_Service_Log__c where UcServiceCaseId__c =:case1.Id];
        test.stopTest();
        System.assert(wsLog2 != null);
    }
    /*static testMethod void testLargeThresholdAndRetry()
    {
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id);
        
        insert case1;
        List<Web_Service_Log__c> wsList = new List<Web_Service_Log__c>();
        for(integer i = 0; i < 25; i++){
            Web_Service_Log__c log = new Web_Service_Log__c();
            insert log;
            wsList.add(log);
            
        }
        for(Web_Service_Log__c wsLog : wsList){
            wsLog.SobjName__c = 'Case';
            wsLog.UC_Service__c = true;
            wsLog.ServiceName__c = 'CaseS2SQueuable';
            wsLog.UcServiceCaseId__c = case1.Id;
            wsLog.Successful__c = false;
            wsLog.Rest_Response__c = '{"message" : "APEX job failed "}';
        }
        update wsList;
        DateTime currentDate = DateTime.now().addHours(-24);
        List<Web_Service_Log__c> wsList2 = [select Id, SnowCaseCreated__c, Successful__c from Web_Service_Log__c where UC_Retry__c = true ];
        System.assertEquals(25, wsList2.size());
        Web_Service_Log__c successLog = new Web_Service_Log__c();
        insert successLog;
        successLog.SobjName__c = 'Case';
        successLog.UC_Service__c = true;
        successLog.ServiceName__c = 'CaseS2SQueuable';
        successLog.UcServiceCaseId__c = case1.Id;
        successLog.Successful__c = true;
        successLog.Rest_Response__c = '{"message" : "Created "}';
        update successLog;
        test.stopTest();
        Id recTypeId = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case').getRecordTypeId();
        Case snowCase = [Select Id from Case where recordtypeId =:recTypeId and Assignment_Group__c = 'DEV - SALESFORCE.COM'];
        System.assert(snowCase != null);
        List<Web_Service_Log__c> wsList3 = [select Id from Web_Service_Log__c where UC_Retry__c = true ];
        System.assertEquals(0, wsList3.size());
    }
    static testMethod void testThreshold2()
    {
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,Issue_Type__c = 'New Client / Implementation Issue'
                               ,Subject = 'New Test'
                               ,Description = 'Test Description'
                               ,contactId = con1.Id);
        
        insert case1;
        List<Web_Service_Log__c> wsList = new List<Web_Service_Log__c>();
        List<Web_Service_Log__c> wsList2 = new List<Web_Service_Log__c>();
        List<Web_Service_Log__c> wsList3 = new List<Web_Service_Log__c>();
        List<Web_Service_Log__c> wsList4 = new List<Web_Service_Log__c>();
        
        for(integer i = 0; i < 4; i++){
            Web_Service_Log__c log = new Web_Service_Log__c();
            wsList2.add(log);
            wsList.add(log);            
        }
        insert wsList2;
        Web_Service_Log__c successLog = new Web_Service_Log__c();
        successLog.SobjName__c = 'Case';
        successLog.UC_Service__c = true;
        successLog.ServiceName__c = 'CaseS2SQueuable';
        successLog.UcServiceCaseId__c = case1.Id;
        successLog.Successful__c = true;
        successLog.Rest_Response__c = '{"message" : "Created "}';
        insert successLog;
        for(integer i = 0; i < 3; i++){
            Web_Service_Log__c log = new Web_Service_Log__c();
            wsList3.add(log);
            wsList.add(log);           
        }
        insert wsList3;
        Web_Service_Log__c successLog2 = new Web_Service_Log__c();
        successLog2.SobjName__c = 'Case';
        successLog2.UC_Service__c = true;
        successLog2.ServiceName__c = 'CaseS2SQueuable';
        successLog2.UcServiceCaseId__c = case1.Id;
        successLog2.Successful__c = true;
        successLog2.Rest_Response__c = '{"message" : "Created "}';
        insert successLog2;
        for(integer i = 0; i < 3; i++){
            Web_Service_Log__c log = new Web_Service_Log__c();
            wsList4.add(log);
            wsList.add(log);           
        }
        insert wsList4;
        for(Web_Service_Log__c wsLog : wsList){
            wsLog.SobjName__c = 'Case';
            wsLog.UC_Service__c = true;
            wsLog.ServiceName__c = 'CaseS2SQueuable';
            wsLog.UcServiceCaseId__c = case1.Id;
            wsLog.Successful__c = false;
            wsLog.Rest_Response__c = '{"message" : "APEX job failed "}';
        }
        update wsList;
        DateTime currentDate = DateTime.now().addHours(-24);
        List<Web_Service_Log__c> wsCheckList = [select Id, SnowCaseCreated__c, Successful__c from Web_Service_Log__c where ServiceName__c='CaseS2SQueuable' and Successful__c = false and CreatedDate >=: currentDate Order by CreatedDate Asc ];
        System.assertEquals(10, wsCheckList.size());
        test.stopTest();
        Id recTypeId = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case').getRecordTypeId();
        List<Case> snowCase = [Select Id from Case where recordtypeId =:recTypeId and Assignment_Group__c = 'DEV - SALESFORCE.COM'];
        System.assertEquals(0, snowCase.size());
    }
    /*static testMethod void testUCUnsuccessfulLog()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
    	wsWrap.svcName = 'CaseS2SQueuable';
    	wsWrap.succes = false;
    	wsWrap.errMsg = 'No APEX Job Created';
    	wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
    	wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Web_Service_Log__c testLog = [Select id,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.ucResponse, testLog.Rest_Response__c);
    }
    static testMethod void testUCUnsuccessfulLog2()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Schema.RecordTypeInfo snowRt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'CaseS2SQueuable';
        wsWrap.succes = false;
        wsWrap.errMsg = 'APEX job failed';
        wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
        wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Web_Service_Log__c testLog = [Select id,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.ucResponse, testLog.Rest_Response__c);
        Case snowCase = [Select Id from Case where recordtypeId =:snowRt.getRecordTypeId() and Originator__c =: case1.contactId];
        System.assert(snowCase != null);
    }
    static testMethod void testUCUnsuccessfulLog3()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Schema.RecordTypeInfo snowRt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'CaseS2SQueuable';
        wsWrap.succes = false;
        wsWrap.errMsg = 'Abstraction layer issue';
        wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
        wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Web_Service_Log__c testLog = [Select id,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.ucResponse, testLog.Rest_Response__c);
        Case snowCase = [Select Id from Case where recordtypeId =:snowRt.getRecordTypeId() and Originator__c =: case1.contactId];
        System.assert(snowCase != null);
    }
    static testMethod void testUCUnsuccessfulLog4()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Schema.RecordTypeInfo snowRt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'CaseS2SQueuable';
        wsWrap.succes = false;
        wsWrap.errMsg = 'UC transport issue';
        wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
        wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Web_Service_Log__c testLog = [Select id,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.ucResponse, testLog.Rest_Response__c);
        Case snowCase = [Select Id from Case where recordtypeId =:snowRt.getRecordTypeId() and Originator__c =: case1.contactId];
        System.assert(snowCase != null);
    }
    static testMethod void testUCUnsuccessfulLog5()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'CaseS2SQueuable';
        wsWrap.succes = false;
        wsWrap.errMsg = 'UC Submission Unknown Exception';
        wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
        wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Web_Service_Log__c testLog = [Select id,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.ucResponse, testLog.Rest_Response__c);
    }
    static testMethod void testUCUnsuccessfulLog6()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        test.startTest();
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Schema.RecordTypeInfo snowRt = RecordTypeHelper.getRecordType('Sales Support Cases Record Type', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.SobjName__c = 'Case';
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.svcName = 'CaseS2SQueuable';
        wsWrap.succes = false;
        wsWrap.errMsg = 'Consecutive failure limit reached';
        wsWrap.ucCallCaseId = String.valueOf(case1.Id);
        wsWrap.ucServiceCall = true;
        wsWrap.ucResponse = '{"message" : "test "}';
        wsWrap.nbrAttempts = 1;
        wsWrap.sobjName = 'Test SObject';
        WebServicesHelper.updateLog(wsWrap, wsLog);
        test.stopTest();
        Case snowCase = [Select Id from Case where recordtypeId =:snowRt.getRecordTypeId() and Originator__c =: case1.contactId];
        System.assert(snowCase != null);
    }
    static testMethod void testUCUpdateLog()
    {
        CreateTestData.createSingleAandTwoCts();
        Account acct1 = [Select Id from Account where AccountNumber =:'83-1234567'];
        Contact con1 = [Select Id, Name, AccountId, Account.Name, Account.AccountNumber, Account.Type from Contact where AccountId=:acct1.Id limit 1];
        con1.firstName = 'Salesforce';
        con1.lastName = 'Support';
        update con1;
        Schema.RecordTypeInfo hrsRt = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRt.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               ,CreatedDate = dateTime.now()
                               ,Product__c = 'Payroll'
                               ,contactId = con1.Id);
        insert case1;
        Web_Service_Log__c wsLog = new Web_Service_Log__c();
        wsLog.Successful__c = false;
        wsLog.Rest_Response__c = '{"message" : "test "}';
        wsLog.UC_Retry__c = false;
        wsLog.ServiceName__c = 'CaseS2SQueuable';
        wsLog.UC_Service__c = true;
        wsLog.UcServiceCaseId__c = String.valueOf(case1.Id);
        insert wsLog;
        WebServicesHelper.WebServiceWrapper wsWrap = new WebServicesHelper.WebServiceWrapper();
        wsWrap.succes = true;
        wsWrap.notes = 'test';
        wsWrap.namedFunction = 'Update Case';
        WebServicesHelper.updateLog(wsWrap,wslog);	
        Web_Service_Log__c testLog = [Select id,Successful__c,Rest_Response__c from Web_Service_Log__c where UcServiceCaseId__c =: wsWrap.ucCallCaseId];
        System.assert(testLog != null);
        System.assertEquals(wsWrap.succes, testLog.Successful__c);
 
    }*/
   static testMethod void testLogServiceCall() {
      WebServicesHelper.logServiceCall('Test Service', true, 'This is an error message', 'These are notes');
      System.assertEquals(1,[Select count() from Web_Service_Log__c]);
   } // testLogServiceCall
   
	/** can be used to populate Custom Setting when testing (or after sandbox refresh)
	 */
	public static void populateEndpoint() {	
		WebServiceSettings__c wssInternal = new WebServiceSettings__c (
			Name = 'NSS History external'
			,certificate__c = null
			,endpoint__c='http://10.25.14.212:11000/CorpApps_LeadManagementActivityOrchestration/proxy-service/LeadManagementActivityOrchestrationREST'
			,IsActive__c=true);
		upsert wssInternal;
	} // populateEndpoint
	    
} // class WebServicesHelperTest