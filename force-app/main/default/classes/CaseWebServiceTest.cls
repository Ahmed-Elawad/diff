/*  
 * Test Method for CaseWebService Rest Service
 * 
 *
 * History
 * -------
 * 12/07/2017	Jermaine Stukes Created
 * 09/20/2018	Jermaine Stukes	Added UC Integration tests
 * 01/05/2022	Jermaine Stukes Added tests
 * 
 */
@isTest
public class CaseWebServiceTest 
{
    @testSetup
    Static void Setup()
    {
        //Add Defaults
        List<S2S_ViewGadget_Parameters__c> S2SViewGadgetList = new List<S2S_ViewGadget_Parameters__c>();
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='Assigned_UC_Agent__c', Api_Name__c='Assigned_UC_Agent__c'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='branch', Api_Name__c='Branch_ID__c'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='branchClientNum', Api_Name__c='Branch_Client_ID__c'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='caseID', Api_Name__c='Id'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='CaseNumber', Api_Name__c='CaseNumber'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='clientNum', Api_Name__c='Client_ID__c'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='closeDateEnd', Api_Name__c='ClosedDate'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='closeDateStart', Api_Name__c='ClosedDate'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='isClosed', Api_Name__c='isClosed'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='rangeEnd', Api_Name__c='CreatedDate'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='rangeStart', Api_Name__c='CreatedDate'));
        S2SViewGadgetList.add(new S2S_ViewGadget_Parameters__c(Name='status', Api_Name__c='status'));
        insert S2SViewGadgetList;
        //Create Account and case
        CreateTestData.createAccountandCases();
    }//Setup()
    static String restUri = 'https://'+System.URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/UnifiedCommunications';
    static testmethod void testBranchClientSearch()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();
        String testResults = res.responseBody.toString();
        System.debug('*****STATUS CODE*****'+res.statusCode);
        System.assert(testResults.contains('11-1234567'));
        System.assertNotEquals(null, testResults);
        System.assertNotEquals(null, res.statusCode);         
    }
    static testmethod void testCreateRange()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('rangeStart', '2016-09-01');
        req.addParameter('rangeEnd', '2016-11-01');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(null, testResults);
        System.assertNotEquals(null, res.statusCode);    
    }
    static testmethod void testCloseRange()
    {
        CreateTestData.createAccountandCases();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('closeDateStart', '2017-09-01');
        req.addParameter('closeDateEnd', '2017-11-01');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode);    
    }
    static testmethod void testStatus()
    {
        CreateTestData.createAccountandCases();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('status', 'New');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode);  
    }
    static testmethod void testFieldSet()
    {
        CreateTestData.createAccountandCases();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('fieldSet', 'Id, Description,Subject,origin');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode);  
    }
    static testmethod void testOffSet()
    {
        CreateTestData.createAccountandCases();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('offset', '1');
        req.addParameter('limit', '2');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode); 
    }
    static testmethod void testCaseId()
    {
        CreateTestData.createAccountandCases();
         Case testCase = [Select Id, Branch_Client_ID__c from Case where Branch_Client_ID__c='11-1234567' limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('branchClientNum', '11-1234567');
        req.addParameter('caseID', testCase.Id);
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode); 
    }
    static testmethod void testBadData()
    {
        CreateTestData.createAccountandCases();
        List<Account> acctList = [Select Id from Account where AccountNumber='11-1234567'];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.params.put('branchClientNum', 'bad br-clt');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        
        String testResults = res.responseBody.toString();
        System.debug('TEST BAD DATA'+testResults);
        System.assert(testResults.contains('"TotalCount" : 0'));  
        /*CreateTestData.createAccountandCases();
        RestRequest request = new RestRequest();
        request.requestUri = restUri;
        request.httpMethod = 'GET';
        request.params.put('branchClientNum', 'bad br-clt');
        RestContext.request = request;
        // Call the method to test
        CaseWebService.ReturnWrapper testWrapper = new CaseWebService.ReturnWrapper();
        testWrapper = CaseWebService.getCases();
        System.assertEquals(0, testWrapper.TotalCount);  */
    }
    static testmethod void testUpdateCase()
    {
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri+'/'+kase.Id; 
        req.requestBody = Blob.valueOf('{"Description": "This is a test"}');
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.updateCaseFields();
        Test.stopTest(); 
        System.assertEquals(res.statusCode, 201);
         
    }
    static testmethod void testBadCaseId()
    {
        CreateTestData.createAccountandCases();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri+'/1111111111'; 
        req.requestBody = Blob.valueOf('{"Description": "This is a bad test"}');
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.updateCaseFields();
        Test.stopTest(); 
        System.assertEquals(500, res.statusCode);
    }
    static testmethod void testUpdateCloseCase()
    {
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, isclosed, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri+'/'+kase.Id; 
        req.requestBody = Blob.valueOf('{"Assigned_UC_Agent__c": "Jermaine Stukes"}');
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.updateCaseFields();
        Test.stopTest(); 
        System.assertEquals(res.statusCode, 201);
        
    }
    /*static testmethod void testUpdateBadCase()
    {
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri+'/'+kase.Id; 
        req.requestBody = Blob.valueOf('{"Bad Field": "This is a bad test"}');
        req.httpMethod = 'Patch';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.updateCaseFields();
        Test.stopTest();
        String testResults = res.responseBody.toString();
        System.Debug('********Results******'+testResults);
        System.assert(testResults.contains('Error: Unhandled exception:'));  
    }*/
    static testmethod void testUpdateCaseComments()
    {
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri+'/'+kase.Id; 
        req.requestBody = Blob.valueOf('{"CaseComments": "This is a test"}');
        req.httpMethod = 'Patch';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.updateCaseFields();
        Test.stopTest(); 
        System.assertEquals(res.statusCode, 201);
    }
    static testmethod void testSendAtt()
    {
        Blob b = blob.valueof('TEST');
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        Attachment kaseAttachments = new Attachment();//[Select Id, Name, Body, BodyLength, ContentType from Attachment WHERE ParentId =:oppId];    
        kaseAttachments.Name = 'Test Attach';
        kaseAttachments.Body = b;
        kaseAttachments.ParentId = kase.Id;
        insert kaseAttachments;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('fileId', kaseAttachments.Id);
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode);
    }
    static testmethod void testSendFile()
    {
        Blob b = blob.valueof('TEST');
        String attachName = 'Test File';
        CreateTestData.createAccountandCases();
        Case kase = [select Id, Account.AccountNumber, Description, OwnerId from Case where Account.AccountNumber='11-1234567' limit 1];
        Id[]  fileParent= new Id[]{kase.id};
        AddFileQueueable afq = new AddFileQueueable();
        afq.addAnotherFile(fileParent, attachName, attachName,Null , b);
        afq.processRecs();
        ContentDocumentLink cdl = [Select ContentDocument.Id, ContentDocument.Title, ContentDocument.ContentSize from ContentDocumentLink where LinkedEntityId=:kase.Id limit 1];
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('fileId', cdl.ContentDocument.Id);
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        String testResults = res.responseBody.toString();
        System.assertNotEquals(Null, testResults);
        System.assertNotEquals(Null, res.statusCode);
    }
    static testmethod void testSendBadAtt()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('fileId', '00P1111111111');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        System.assertEquals(res.statusCode, 404);
    }
    static testmethod void testSendBadFile()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('fileId', '0691111111111');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        System.assertEquals(res.statusCode, 404);
    }
    static testmethod void testSendBadData()
    {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = restUri; 
        req.addParameter('fileId', '1111111111');
        req.httpMethod = 'GET';
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        CaseWebService.webServiceRequest();
        Test.stopTest();  
        System.assertEquals(res.statusCode, 404);
    }
}