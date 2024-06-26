/* 
*Test methods for the HRISEmployeeLookupController.
*
* History
* ------------------------------------------------------------------------------
    10/14/2019  Matt Fritschi       Created.
    12/03/2019  Jake Hinds          Adding web service custom setting
    12/19/2022  Dan Carmen          Added Do Not Sync = true and Created By Process

*/

@isTest
public class HRISEmployeeLookupControllerTest {
    @testSetup static void testSetupMethod(){
        insert new WebServiceSettings__c(Name='EESearch',IsActive__c=true,Certificate__c=Label.Test_Class_Certificate_Name,
                                         Endpoint__c='https://webservices.paychex.com/rest/hrs/sfdc/salesforce-rem/SalesForceContactSearches',
                                         Timeout__c='60000',Forward_Host__c='webservices.paychex.com');
    }
    static testmethod void testNothingFilledOut()
    {
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.submit();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertNotEquals(0, pageMessages.size());
    } //testNothingFilledOut()
    
    static testmethod void testGoodEmployeeResponse(){
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.BISClientId = '123098';
        elc.searchId = '1234';
        elc.branch = '67';
        elc.clientNumber = '123456789';
        elc.companyName = 'Test Company';
        elc.firstName = 'Test';
        elc.lastName='Search';
        elc.submit();
        
        System.assertEquals(false, elc.isForm);
        System.assertEquals(2, elc.employees.size());
    } //testGoodEmployeeResponse()
    
    static testmethod void testSelectExistingContact(){
        Contact existingContact = new Contact(firstName = 'EmployeeSearch', lastName = 'TestContact');
        insert existingContact;
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.searchId = '1234';
        elc.submit();
        
        pageReference pager = page.HRISEmployeeLookupForm;
        Test.setCurrentPage(pager);
        
        elc.selectedRowNum='0';
        PageReference pr = elc.selectRow();

        System.debug('next page is: '+pr.getUrl());
        
        String contactURL = (String) pr.getUrl();
        String contactId = contactURL.substring(1);
        
        System.assertEquals(existingContact.Id, contactId);
        System.assertEquals(false, elc.isForm);
    } //testSelectExistingContact()
    
    
    static testmethod void testSelectNonexistentContactWithSFID(){      
        
        Account acct = new Account(Name='Employee Search Test Account', Bis_ID__c=123);
        insert acct;
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.searchId = '1234';
        elc.submit();
        
        elc.selectedRowNum='0';
        elc.selectRow();

        System.assertEquals(false, elc.isForm);
        
        List<Contact> createdCtct = [SELECT Id, Name FROM Contact WHERE Name = 'EmployeeSearch TestContact1'];
        System.assertEquals(false, elc.newlyCreatedContact==null);
        System.assertEquals(1, createdCtct.size());
    } //testSelectNonexistentContactWithSFID()
    
    
    static testmethod void testSelectNonexistentContactNoSFID(){      
        
        Account acct = new Account(Name='Employee Search Test Account', Bis_ID__c=456);
        insert acct;
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.searchId = '1234';
        elc.submit();
        
        elc.selectedRowNum='1';
        elc.selectRow();

        System.assertEquals(false, elc.isForm);
        
        List<Contact> createdCtct = [SELECT Id, Name FROM Contact WHERE Name = 'EmployeeSearch TestContact2'];
        System.assertEquals(false, elc.newlyCreatedContact==null);
        System.assertEquals(1, createdCtct.size());
        
    } //testSelectNonexistentContactNoSFID()
    
    
    static testmethod void doPutRequest(){      
        
        Account acct = new Account(Name='Employee Search Test Account', Bis_ID__c=123);
        insert acct;
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.searchId = '1234';
        elc.submit();
        
        elc.selectedRowNum='0';
        elc.selectRow();
               
        pageReference pager = page.HRISEmployeeLookupForm;
        Test.setCurrentPage(pager);
             
        PageReference pr = elc.doPutRequest();

        System.assertEquals(false, elc.isForm);
        
        List<Contact> createdCtct = [SELECT Id, Name FROM Contact WHERE Name = 'EmployeeSearch TestContact1'];
        System.assertEquals(false, elc.newlyCreatedContact==null);
        System.assertEquals(1, createdCtct.size());
               
        String contactURL = (String) pr.getUrl();
        String contactId = contactURL.substring(1);
        System.assertEquals(createdCtct[0].Id, contactId);
    } //doPutRequest()
    
    
    static testmethod void testCancel(){
        
        HRISEmployeeLookupController elc = new HRISEmployeeLookupController();
        elc.BISClientId = '123098';
        elc.searchId = '1234';
        elc.branch = '67';
        elc.clientNumber = '123456789';
        elc.companyName = 'Test Company';
        elc.firstName = 'Test';
        elc.lastName='Search';
        elc.submit();
        
        elc.cancel();
        
        System.assertEquals(true, elc.isForm);
        System.assertEquals('', elc.BISClientId);
        System.assertEquals('', elc.searchId);
        System.assertEquals('', elc.branch);
        System.assertEquals('', elc.clientNumber);
        System.assertEquals('', elc.companyName);
        System.assertEquals('', elc.firstName);
        System.assertEquals('', elc.lastName);
    } //testCancel()
    
    
    
    
    //Method for returning Http Response
    public static HttpResponse GoodEmployeeSearchExpectedResponse(String ctctId) 
    { 
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setStatusCode(200);
        String bodyStart = '{"metadata":{"contentItemCount":85},"links":[{"href":"https://webservicesimp.paychex.com/rest/hrs/sfdc/salesforce-rem","templated":false,"operations":[{"operation":"POST","mediaTypes":["application/json"]}],"rel":"self"}],"content":[';
        String employee1 = '';
        if(ctctId != null)
        {
            employee1 = '{"salesforceId":"' + ctctId + '","branch":"0072","payrollClientNumber":"17084689","companyId":123,"workerId":"37","dateOfBirth":"01/01/2016","companyName":"TEST COMPANY 1","employeeStatus":"A","ssnLastFour":"5359","givenName":"EmployeeSearch","surname":"TestContact","address":{"street":"14071 Towneway Dr","city":"Sugar Land","stateAbbrv":"TX","zipCode":"77498"},"telephone":null,"email":null,"retirementAccounts":{"id":35857246,"plan":{"name":"Pre-Tax","number":"398489","type":"401k"},"contributionSettings":{"source":"preTax","amount":0,"amountType":"percentage"}},"flexibleSpendingAccount":null,"links":[{"href":"https://webservicesimp.paychex.com/rest/hrs/sfdc/salesforce-rem/SalesForceContacts/e:5171122-37/SalesForceId","templated":false,"operations":[{"operation":"PUT","mediaTypes":["application/json"]}],"rel":"salesForceId"}],"contactId":null},';
        }
        else
        {
            employee1 = '{"salesforceId":"00370000023H2zOAAS","branch":"0072","payrollClientNumber":"17084689","companyId":123,"workerId":"37","dateOfBirth":"01/01/2016","companyName":"TEST COMPANY 1","employeeStatus":"A","ssnLastFour":"5359","givenName":"EmployeeSearch","surname":"TestContact1","address":{"street":"14071 Towneway Dr","city":"Sugar Land","stateAbbrv":"TX","zipCode":"77498"},"telephone":null,"email":null,"retirementAccounts":{"id":35857246,"plan":{"name":"Pre-Tax","number":"398489","type":"401k"},"contributionSettings":{"source":"preTax","amount":0,"amountType":"percentage"}},"flexibleSpendingAccount":null,"links":[{"href":"https://webservicesimp.paychex.com/rest/hrs/sfdc/salesforce-rem/SalesForceContacts/e:5171122-37/SalesForceId","templated":false,"operations":[{"operation":"PUT","mediaTypes":["application/json"]}],"rel":"salesForceId"}],"contactId":null},';
        }
        String employee2 = '{"salesforceId":null,"branch":"0071","payrollClientNumber":"17084680","companyId":456,"workerId":null,"dateOfBirth":null,"companyName":"Airline Diagnosis Center LLC","employeeStatus":null,"ssnLastFour":"2134","givenName":"EmployeeSearch","surname":"TestContact2","address":{"zipCode":"77076"},"telephone":null,"email":null,"retirementAccounts":null,"flexibleSpendingAccount":null,"links":[{"href":"https://webservicesimp.paychex.com/rest/hrs/sfdc/salesforce-rem/SalesForceContacts/ne:286691/SalesForceId","templated":false,"operations":[{"operation":"PUT","mediaTypes":["application/json"]}],"rel":"salesForceId"}],"contactId":"286691"},';
        String employee3 = '{"salesforceId":null,"branch":"0073","payrollClientNumber":"17084685","companyId":789,"workerId":null,"dateOfBirth":null,"companyName":"Airline Diagnosis Center LLC","employeeStatus":null,"ssnLastFour":null,"givenName":"EmployeeSearch","surname":"TestContact2","address":{"zipCode":"77076"},"telephone":null,"email":null,"retirementAccounts":null,"flexibleSpendingAccount":null,"links":[{"href":"https://webservicesimp.paychex.com/rest/hrs/sfdc/salesforce-rem/SalesForceContacts/ne:286691/SalesForceId","templated":false,"operations":[{"operation":"PUT","mediaTypes":["application/json"]}],"rel":"salesForceId"}],"contactId":"286691"}';
        String bodyEnd = ']}';
        String wholeResponse = bodyStart + employee1 + employee2 + employee3 + bodyEnd;
        httpResponse.setBody(wholeResponse); 
        return httpResponse;
    } //GoodEmployeeSearchExpectedResponse
    
    //Method for returning Http Response
    public static HttpResponse contactSuccessfullyCreated()
    {
        HttpResponse httpResponse = new HttpResponse();
        httpResponse.setStatusCode(200);
        httpResponse.setBody('Succeess!'); 
        return httpResponse;
    } //contactSuccessfullyCreated
    
}