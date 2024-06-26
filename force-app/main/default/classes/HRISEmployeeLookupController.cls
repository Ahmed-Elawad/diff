/*
	10/07/2019	Matt Fritschi		Created. 
    12/03/2019	Jake Hinds			Adding web service custom setting, limiting to 1000 results
    12/19/2022  Dan Carmen          Added Do Not Sync = true and Created By Process
 
*/

public with sharing class HRISEmployeeLookupController {
    
    public Map<String, String> dataMap {get;set;}
    
    public boolean isForm {get;set;}
    public Contact newlyCreatedContact {get; set;}
    public String searchId {get;set;}
    public String firstName {get;set;}
    public String lastName {get;set;}
    public String branch {get;set;}
    public String BISClientId {get;set;}
    public String clientNumber {get;set;}
    public String companyName {get;set;}
    public String errorMessage = '';
    public EmployeeWrapper selectedEmp {get; set;}
    public String selectedRowNum {get;set;}
    public List<EmployeeWrapper> employees {get;set;}
    public WebServiceSettings__c cs;
    
    //***** Constructor *****
    public HRISEmployeeLookupController() {
        employees = new List<EmployeeWrapper>();
        isForm = true;
        cs = WebServiceSettings__c.getInstance('EESearch');
    }//----- End Constructor -----
    
    
    //***** Submit *****
    public PageReference submit() {
        if(String.isBlank(searchId) && String.isBlank(firstName) && String.isBlank(lastName) 
           && String.isBlank(branch) && String.isBlank(BISClientId) && String.isBlank(clientNumber)
           && String.isBlank(companyName))
        {
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'You must search on at least one field.'));
        }
        else if(ssnIsIncorrect(searchId))
        {
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'The SSN can only be the last 4 numbers of the Employee\'s Social Security Number'));     
        }
        else if(cs!=null && cs.IsActive__c)
        {
            Http http = new Http();
            httpRequest request = new HttpRequest();
            //Need to set the endpoint of this request.
            request.setEndpoint(cs.Endpoint__c);
            request.setMethod('POST');
            
            //Set the Headers
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('Accept', 'application/json');
            request.setHeader('X-PAYX-USER-ID', 'HRS_SFREM_ASV');
            request.setHeader('x-forwarded-proto', 'https');
            request.setHeader('X-Forwarded-Prefix', 'rest/hrs/sfdc/salesforce-rem');
            
            request.setHeader('x-forwarded-host', cs.Forward_Host__c);
            
            request.setTimeout(Integer.valueOf(cs.Timeout__c));
            
            //build and set the body
            String body = buildBody();
            request.setBody(body);
            System.debug('The body is: '+ body);
            
            try
            {
                HttpResponse response;
                if(!Test.isRunningTest())
                {
                    System.debug('The Certificate is: '+ cs.Certificate__c);
                    request.setClientCertificateName(cs.Certificate__c);
                    System.debug('The full request is: ' + request);
                    response = http.send(request);
                }
                else
                {
                    List<Contact> testContactList = [SELECT Id, Name FROM Contact WHERE Name = 'EmployeeSearch TestContact'];
                    if(testContactList.size() > 0) {
                        response = HRISEmployeeLookupControllerTest.GoodEmployeeSearchExpectedResponse(testContactList[0].Id);
                    }
                    else {
                        response = HRISEmployeeLookupControllerTest.GoodEmployeeSearchExpectedResponse(null);
                    }
                    
                }
                
                System.debug('Response Status Code is: '+response.getStatusCode());
                System.debug('Response body is: '+response.getBody());
                //Make sure the call was successful
                if(response.getStatusCode()==200)
                {
                    //Here is where we do something with the data being returned.
                    Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                    System.debug('The returned mapping is: '+results);
                    System.debug('The size of the Map is: '+ results.size());
                    /*if(results.size() > 200)
{
apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Too many records were returned. You must narrow your search.'));
clearData();
return null;
} //if(results.size() > 200)*/
                    System.debug('Keys:'+results.keySet());
                    List<Object> employeeList = (List<Object>) results.get('content');
                    
                    if(employeeList != null)
                    {
                        Integer row = 0;
                        for(Object employee : employeeList)
                        {
                            
                            if (employees.size()<1000){
                                buildEmployeeTable(employee, row);
                            }
                            else if(employees.size()==1000){
                                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Max of 1000 rows returned. You must narrow your search.'));
                                break;
                                //not sure if needed clearData();
                                //not sure if needed return null;
                            }
                            
                            row = row + 1;
                        }
                        isForm = false;
                    } //if(employeeList != null)
                    else
                    {
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'There are no records that match your search.'));
                        clearData();
                    }
                } //if(response.getStatusCode()==200)
                else
                {
                    String responseBody = (String) response.getBody();
                    if(responseBody.contains('The result set will be too large'))
                    {
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'The result set will be too large. You must narrow your search.'));
                        clearData();
                    }
                }
            }
            catch(System.CalloutException e)
            {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, e.getMessage()));
                clearData();
            }
        }
        else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Service is inactive.  Please reach out to Salesforce Support'));
        }
        
        return null; 
    }//----- End Submit -----
    
    
    //***** Select Row *****
    public PageReference selectRow() {
        
        PageReference showContact = new PageReference('');
        boolean contactCompleted = false;
        
        selectedEmp = new EmployeeWrapper();
        for(EmployeeWrapper emp : employees)
        {
            if(emp.rowID == selectedRowNum)
            {
                selectedEmp = emp;
            }
        }
        
        //See if a contact record already exists
        Boolean contactIdExists = (String.isNotBlank(selectedEmp.salesforceId) ? true : false);
        
        if(contactIdExists)
        {
            //Redirect them to the Salesforce Contact
            System.debug('Contact Id: '+ selectedEmp.salesforceId);
            Contact[] existingContact = [SELECT Id, Name FROM Contact WHERE Id=:selectedEmp.salesforceId];
            
            if(existingContact.size()==1)
            {
                contactCompleted = true;
                System.debug('Redirect to Contact: '+ existingContact[0]);
                showContact = redirectToContact(existingContact[0]);
                return showContact;
            }
            else
            {
                errorMessage = 'Something went wrong when trying to retrieve the contact.';
                contactCompleted = createContact(selectedEmp);
            }
            
        }
        else
        {
            System.debug('No salesforceId found.');
            contactCompleted = createContact(selectedEmp);
        }
        
        if(contactCompleted)
        {
            return null;
        }
        else
        {
            //Show the error message.
            System.debug('Showing error message');
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, errorMessage));
        }
        System.debug('SHOULD NOT REDIRECT');
        return null;
        
    }//----- End Select Row -----
    
    public PageReference doPutRequest()
    {
        System.debug('Entered PUT Request');
        if(newlyCreatedContact != null)
        {
            //Submit the Contact ID to The server, and change the page to the new contact
            Http http = new Http();
            httpRequest request = new HttpRequest();
            //Need to set the endpoint of this request.
            request.setEndpoint(selectedEmp.link);
            request.setMethod('PUT');
            
            //Set the Headers
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            request.setHeader('Accept', 'application/vnd.paychex.com+json');
            request.setHeader('X-PAYX-USER-ID', 'HRS_SFREM_ASV');
            request.setHeader('x-forwarded-proto', 'https');
            request.setHeader('X-Forwarded-Prefix', 'rest/hrs/sfdc/salesforce-rem');
            
            request.setHeader('x-forwarded-host', LABEL.Employee_Search_Webservice_Forward_Host);
            
            request.setTimeout(30000);
            
            request.setBody(newlyCreatedContact.Id);
            System.debug('The body is: '+ newlyCreatedContact.Id);
            System.debug('The endpoint is: '+selectedEmp.link);
            
            try
            {
                HttpResponse response;
                if(!Test.isRunningTest()) {
                    request.setClientCertificateName(cs.Certificate__c);
                    response = http.send(request); 
                }
                else { 
                    response = HRISEmployeeLookupControllerTest.contactSuccessfullyCreated(); 
                }
                
                System.debug('Directly After the send.');
                System.debug('Response Status Code is: '+response.getStatusCode());
                System.debug('Response body is: '+response.getBody());
                //Make sure the call was successful
                if(response.getStatusCode()==200)
                {
                    //Here is where we do something with the data being returned.
                    system.debug('Submitting the new slaesforceId was successful. Redirecting to new Contact now.');
                    return redirectToContact(newlyCreatedContact);
                }
                else
                {
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Submitting this new Contact ran into an error.'));
                }
            }
            catch(System.CalloutException e)
            {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Submitting this new Contact took too long.'));
            }
            
        }
        return null;
    }
    
    
    //createContact	---	Creates a Contact for the selected employee
    public boolean createContact(EmployeeWrapper selectedEmp)
    {
        Boolean contactSuccess = false;
        System.debug('Selected EmployeeWrapper='+selectedEmp);
        Integer BISID = Integer.valueOf(selectedEmp.BISClientId);
        String branchAndPayrollClientNumber = selectedEmp.prospectClientNumber;
        
        Account[] matchingAccounts = [SELECT Id, Name FROM Account WHERE Bis_ID__c = :BISID];
        
        //First try finding Account based on BIS ID.
        System.debug('The number of Accounts returned is: '+ matchingAccounts.size());            
        if((matchingAccounts.size()) == 1)
        {
            Account matchedAccount = matchingAccounts[0];
            //Create a new Contact
            System.debug('The Link we will use for this request is: ' + selectedEmp.link);
            Date dateOfBirth = null;
            if(selectedEmp.DOB != null)
            {
                dateOfBirth = Date.parse(selectedEmp.DOB);
            }
            
            Contact ctct = new Contact(FirstName=selectedEmp.firstName, LastName=selectedEmp.lastName, AccountId=matchedAccount.Id, Last_4_SSN__c=selectedEmp.ssn4
                                      , Email=selectedEmp.email, HomePhone=selectedEmp.homePhoneNumber, Birthdate=dateOfBirth, Status_of_Employment__c=selectedEmp.status
                                      , Do_Not_Sync__c=true, CreatedByProcess__c='HRISEmployeeLookupController');
            
            try
            {
                insert ctct;
                newlyCreatedContact = ctct;
                System.debug('The new Contacts is: '+ newlyCreatedContact);
                contactSuccess = true;
            }
            catch(DMLException e)
            {
                contactSuccess = false;  
            }
            
        }
        else
        {
            errorMessage = 'Could not find an Account that corresponds to that Client.';
            System.debug(errorMessage);
        }
        
        return contactSuccess;
    } //createContact
    
    
    //***** Cancel *****
    public void cancel() {
        clearData();
        isForm = true;
    }//----- End Cancel -----
    
    
    //***** Clear Data *****
    public void clearData() {
        searchId = '';
        firstName = '';
        lastName = '';
        branch = '';
        BISClientId = '';
        clientNumber = '';
        companyName = '';
        employees.clear();
        errorMessage = '';
        selectedRowNum = '';
        selectedEmp = null;
        newlyCreatedContact = null;
    }//----- End Clear Data -----
    
    
    //Build the body of the HTTP Request that will be sent
    public String buildBody()
    {
        String requestBody = '{';
        if(String.isNotBlank(BISClientId))
        {
            requestBody += '"companyId":"' + BISClientId + '",';
        }
        if(String.isNotBlank(firstName))
        {
            requestBody += '"givenName":"' + firstName + '",';
        }
        if(String.isNotBlank(lastName))
        {
            requestBody += '"surname":"' + lastName + '",';
        }
        if(String.isNotBlank(searchId))
        {
            requestBody += '"ssnLastFour":"' + searchId + '",';
        }
        if(String.isNotBlank(branch))
        {
            requestBody += '"branch":"' + branch + '",';
        }
        if(String.isNotBlank(clientNumber))
        {
            requestBody += '"payrollClientNumber":"' + clientNumber + '",';
        }
        if(String.isNotBlank(companyName))
        {
            requestBody += '"companyName":"' + companyName + '"';
        }
        if(requestBody.substring(requestBody.length()-1, requestBody.length()) == ',')
        {
            //If the last character is a comma, remove it.
            requestBody = requestBody.substring(0, requestBody.length()-1);
        }
        
        requestBody += '}';
        return requestBody;
    } //buildBody()
    
    
    //Create the employeeWrappers that will be put in the table
    public void buildEmployeeTable(Object employee, Integer rownum)
    {
        System.debug('BUILDING EMPLOYEES');
        Map<String, Object> employeeInfo = (Map<String, Object>) employee;
        
        
        EmployeeWrapper wrap = new EmployeeWrapper();
        wrap.salesforceId = (String) employeeInfo.get('salesforceId');
        wrap.firstName = (String) employeeInfo.get('givenName');
        wrap.lastName = (String) employeeInfo.get('surname');
        if(employeeInfo.get('branch')!=null)
        {
            wrap.branch = String.valueOf(Integer.valueOf(employeeInfo.get('branch')));
        }
        else
        {
            wrap.branch = (String) employeeInfo.get('branch');
        }
        wrap.BISClientId =  String.valueOf(employeeInfo.get('companyId'));
        wrap.companyName = (String) employeeInfo.get('companyName');
        wrap.ssn4 = (String) employeeInfo.get('ssnLastFour');
        wrap.status = (String) employeeInfo.get('employeeStatus');
        if(employeeInfo.get('address') != null)
        {
            wrap.address = buildAddressString(employeeInfo, wrap);
        }
        wrap.DOB = (String) employeeInfo.get('dateOfBirth');
        wrap.payrollClientNum = (String) employeeInfo.get('payrollClientNumber');
        wrap.salesforceId = (String) employeeInfo.get('salesforceId');
        wrap.link = getLink(employeeInfo);
        wrap.homePhoneNumber = (String) employeeInfo.get('telephone');
        wrap.email = (String) employeeInfo.get('email');
        wrap.rowID = String.valueOf(rownum);
        wrap.prospectClientNumber = wrap.branch + '-' + wrap.payrollClientNum;
        
        System.debug(wrap);
        if(String.isNotBlank(wrap.ssn4)){
            employees.add(wrap);
        }
        
        System.debug('employees.sze()='+employees.size());
    } //buildEmployeeTable()
    
    
    //Takes the address returned in the HTTP Response and formats it
    public String buildAddressString(Map<String, Object> employeeInfoAddress, EmployeeWrapper empWrap)
    {
        System.debug('The Address is:' + employeeInfoAddress.get('address'));
        String empAddress = '';
        Map<String, Object> employeeAddress = (Map<String, Object>) employeeInfoAddress.get('address');
        
        if(employeeAddress.get('street') != null)
        {
            empAddress += (String) employeeAddress.get('street') + '<br/>';
        }
        if(employeeAddress.get('city') != null)
        {
            empAddress += (String) employeeAddress.get('city') + ', ';
        }
        if(employeeAddress.get('stateAbbrv') != null)
        {
            empAddress += (String) employeeAddress.get('stateAbbrv') + ' ';
        }
        if(employeeAddress.get('zipCode') != null)
        {
            empAddress += (String) employeeAddress.get('zipCode');
        }
        
        
        empWrap.street = (String) employeeInfoAddress.get('street');
        empWrap.city = (String) employeeInfoAddress.get('city');
        empWrap.stateAbbrev = (String) employeeInfoAddress.get('stateAbbrv');
        empWrap.zipCode = (String) employeeInfoAddress.get('zipCode');
        
        System.debug('The Address is:' + empAddress);
        return empAddress;
        
    }//buildAddressString
    
    
    //Gets the link to send the salesforceID to
    public String getLink(Map<String, Object> employeeInfoLinks)
    {
        String link = '';
        
        List<Object> employeeLinksList = (List<Object>) employeeInfoLinks.get('links');
        Map<String, Object> employeeLinksMap= (Map<String, Object>) employeeLinksList.get(0);
        
        System.debug('Links are: '+ employeeLinksMap);
        link += (String) employeeLinksMap.get('href');
        
        System.debug('The Link is: '+ link);
        
        return link;
    } //getLink()
    
    
    //Redirect the User to the selected Contact
    public PageReference redirectToContact(Contact c)
    {
        PageReference redirectToContact = new ApexPages.StandardController(c).view();
        redirectToContact.setRedirect(true);
        return redirectToContact;
    } //redirectToContact
    
    public boolean ssnIsIncorrect(String ssn)
    {
        boolean isIncorrect = true;
        
        //check for correct length and numeric
        if((ssn.length() == 4 && ssn.isNumeric()) || ssn.length() == 0)
        {
            isIncorrect = false;
        } 
        
        return isIncorrect;
    }
    
    
    //Wrapper class for employees returned from GET Request to HRIS
    public class EmployeeWrapper {
        
        public String searchId {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String branch {get;set;}
        public String BISClientId {get;set;}
        public String prospectClientNumber {get;set;}
        public String companyName {get;set;}
        public String salesforceId {get; set;}
        public String payrollClientNum {get; set;}
        public String link {get; set;}
        public String street {get; set;}
        public String city {get; set;}
        public String stateAbbrev {get; set;}
        public String zipCode {get; set;}
        public String homePhoneNumber {get; set;}
        public String email {get; set;}
        public String ssn4 {get;set;}
        public String status {get;set;}
        public String address {get;set;}
        public String DOB {get;set;}
        public String rowID {get;set;}
        
        public EmployeeWrapper() {
            link = null;
            homePhoneNumber = null;
            email = null;
            street = null;
            status = null;
            DOB = null;
            street = null;
            city = null;
            stateAbbrev = null;
            zipCode = null;
            address = null;
            firstName = null;
            searchId = null;
            lastName = null;
            branch = null;
            BISClientId = null;
            prospectClientNumber = null;
            companyName = null;
            salesforceId = null;
            payrollClientNum = null;
            rowID = null;
        }
        
    }
    
}