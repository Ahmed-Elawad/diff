/* 
 * Controller for Consumer Privacy form.
 *
 * History
 * -------
 * 09/19/2022 Chris Santoro		Created.
 * 09/26/2022 Loann Desmond		Email functionality added
 */

public without sharing class ConsumerPrivacyController 
{
    public Reference_Consumer_Privacy__c refCP { get; set; }
    public boolean submitted { get; set; }
    //public boolean validated { get; set; }
    public string ccpaAuthAgentFormLink { get; set; }
    public string errorMessage { get; set; }
    public string dateOfBirth { get; set; }
    public string ssn { get; set; }
    public string ssnRekey { get; set; }
    public string emailAddressRekey { get; set; }
    public string requestOptionSelection { get; set; }
    public List<SelectOption> communicationOptions { get; set; }
    //public List<SelectOption> requestTypeOptions { get; set; }
    public List<SelectOption> requestOptions { get; set; }
    public Attachment authAgentAttachment { get; set; }
    public string reCAPTCHA_Site_Key { get; set; }
    
    public ConsumerPrivacyController()
    {
        refCP = new Reference_Consumer_Privacy__c();
        refCP.Tracking_URL__c = (ApexPages.currentPage().getParameters().get('site') == null ? 'main' : ApexPages.currentPage().getParameters().get('site'));
        authAgentAttachment = new Attachment();
        ccpaAuthAgentFormLink = Label.AuthorizedAgentForm;
        submitted = (ApexPages.currentPage().getParameters().get('submitted') == 'true' ? true : false);
        getSelectOptions();
        ssn = '';
        ssnRekey = '';
        emailAddressRekey = '';
        reCAPTCHA_Site_Key = Label.reCAPTCHA_Site_Key;
    }
    
    public PageReference submitForm()
    {
        if(validateForm()){
            System.debug('ConsumerPrivacyController: Submit button clicked');
            System.debug('ConsumerPrivacyController: Saving data for ' + refCP.Submitter_First_Name__c);
            Database.DMLOptions dmo = new Database.DMLOptions();
            Database.SaveResult sr = database.insert(refCP, dmo);
            if (sr.isSuccess()) {
                submitted = true;
                System.debug('ConsumerPrivacyController: authAgentAttachment: ' + authAgentAttachment);
                if(refCP.Options__c == 'I am making the request below as an authorized agent of another Consumer' && authAgentAttachment != null)
                {
                    saveAttachment(sr.getId());
                }
                sendCaseEmail(sr.getId());
                string url = URL.getSalesforceBaseUrl().toExternalForm() + '/ccpa?submitted=true';
                PageReference refPageTest = new PageReference(url);
                refPageTest.setRedirect(true);        
                return refPageTest;
            } else {
                string errorMsg = 'Error Saving Case: ';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage();
                }
                system.debug('ConsumerPrivacyController: error message: ' + errorMsg);
                ErrorLog.logError('ConsumerPrivacyController', 'createCase', 'error creating Consumer Privacy case', refCP.Id, errorMsg);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsg)); 
            }
        }
        
        return null;
    }
 
    public void getSelectOptions()
    {
        //Retrieve picklist values for Communication_Type__c
        communicationOptions = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Reference_Consumer_Privacy__c.Communication_Type__c.getDescribe();
        List<Schema.PicklistEntry> entries = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry : entries)
        {
            communicationOptions.add(new SelectOption(entry.getLabel(), entry.getValue()));
            System.debug('Communication option: Label: ' + entry.getLabel() + ' -- value: ' + entry.getValue());
        }  
        
        //Retrieve picklist values for Options__c
        requestOptions = new List<SelectOption>();
        fieldResult = Reference_Consumer_Privacy__c.Options__c.getDescribe();
        entries = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry : entries)
        {
            requestOptions.add(new SelectOption(entry.getLabel(), entry.getValue()));
            System.debug('Options: Label: ' + entry.getLabel() + ' -- value: ' + entry.getValue());
        } 
        
        //Retrieve picklist values for Request_Option__c
        /*requestTypeOptions = new List<SelectOption>();
        fieldResult = Reference_Consumer_Privacy__c.Request_Option__c.getDescribe();
        entries = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry entry : entries)
        {
            requestTypeOptions.add(new SelectOption(entry.getLabel(), entry.getValue()));
            System.debug('Request Type option: Label: ' + entry.getLabel() + ' -- value: ' + entry.getValue());
        } */
    }
        
    public void sendCaseEmail(Id refCPId)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		String[] sendingTo = new String[]{ Label.Consumer_Privacy_Email_Service };
		email.setToAddresses(sendingTo);
		email.setSubject('Consumer Privacy Request');
		email.setPlainTextBody(refCPId);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });  
    } 
    
    public void saveAttachment(Id parentId)
    {        
        System.debug('uploading attachment');
        authAgentAttachment.ParentId = parentId;
        //authAgentAttachment.Name = 'Authorized Agent Form.pdf';
        insert authAgentAttachment;
        authAgentAttachment = null;
        //return null;
    } 
    
    public boolean validateForm()
    {
		System.debug('ConsumerPrivacyController: validateForm called');
        boolean isValid = true;
        boolean showMailingAddress = false;
        errorMessage = '';
        
        if(refCP.Submitter_First_Name__c == '')
        {
            System.debug('Submitter First Name missing');
            errorMessage += '&#x2022; Submitter First Name cannot be blank<br/>';
            isValid = false;
        } 
        if(refCP.Submitter_Last_Name__c == '')
        {
            System.debug('Submitter Last Name missing');
            errorMessage += '&#x2022; Submitter Last Name cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Email_Address__c == '')
        {
            System.debug('Email Address missing');
            errorMessage += '&#x2022; Email Address cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Email_Address__c != '' && !Pattern.matches('^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$', refCP.Email_Address__c))
        {
            System.debug('Email address not valid');
            errorMessage += '&#x2022; Please enter a valid Email Address<br/>';
            isValid = false;
        }
        if(requestOptionSelection == null)
        {
            System.debug('Options missing');
            errorMessage += '&#x2022; "Is this request being made on behalf of yourself or as an authorized agent of another Consumer?" cannot be blank<br/>';
            isValid = false;
        }
        else 
        {
            refCP.Options__c = requestOptionSelection;
        }
        if(requestOptionSelection == 'I am making the request below as an authorized agent of another Consumer' && authAgentAttachment == null)
        {
            System.debug('Auth Agent Form missing');
            errorMessage += '&#x2022; Authorized Agent Form must be attached<br/>';
            isValid = false;
        }       
        if(refCP.Consumer_First_Name__c == '')
        {
            System.debug('Consumer First Name missing');
            errorMessage += '&#x2022; "Consumer First Name cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Consumer_Last_Name__c == '')
        {
            System.debug('Consumer Last Name missing');
            errorMessage += '&#x2022; "Consumer Last Name cannot be blank<br/>';
            isValid = false;
        }
         if(refCP.Consumer_Phone__c != '' && !(Pattern.matches('1?-?\\(?[0-9]{3}[\\-\\)][0-9]{3}-[0-9]{4}', refCP.Consumer_Phone__c) || (Pattern.matches('1?-?\\(?[0-9]{3}[0-9]{3}[0-9]{4}', refCP.Consumer_Phone__c))))
        {
            System.debug('Phone Number not validated');
            errorMessage += '&#x2022; Please enter a valid Phone Number<br/>';
            isValid = false;
        }
         if(refCP.Consumer_Email__c != '' && !Pattern.matches('^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$', refCP.Consumer_Email__c))
        {
            System.debug('Email address not valid');
            errorMessage += '&#x2022; Please enter a valid Email Address<br/>';
            isValid = false;
        }
        if(refCP.Address_Line1__c == '')
        {
            System.debug('Address Line 1 missing');
            errorMessage += '&#x2022; Address Line 1 cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.City__c == '')
        {
            System.debug('City missing');
            errorMessage += '&#x2022; City cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.State__c == '')
        {
            System.debug('State missing');
            errorMessage += '&#x2022; State cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Zip_Code__c == '')
        {
            System.debug('Zip Code missing');
            errorMessage += '&#x2022; Zip Code cannot be blank<br/>';
            isValid = false;
        } 
        else     
        {
            if(!Pattern.matches('\\d\\d\\d\\d\\d', refCP.Zip_Code__c))
            {
                System.debug('Zip Code invalid');
                errorMessage += '&#x2022; Please enter a valid Zip Code<br/>';
                isValid = false;  
            }
        }
        if(ssn == '')
        {
            System.debug('SSN missing');
            errorMessage += '&#x2022; Social Security Number cannot be blank<br/>';
            isValid = false;
        }
        else
        {
            string ssnReformat = '';
            //Strip out the hyphens if they are present
            if(Pattern.matches('\\d\\d\\d-\\d\\d-\\d\\d\\d\\d', ssn))
            {
                ssnReformat = ssn.replace('-', '');
            } 
            else 
            {
                ssnReformat = ssn;
            }
			//Ensure SSN is formatted correctly with 9 digits            
            if(!Pattern.matches('\\d\\d\\d\\d\\d\\d\\d\\d\\d', ssnReformat))
            {
                System.debug('SSN invalid');
                errorMessage += '&#x2022; Please enter a valid Social Security<br/>';
                isValid = false;  
            } 
            else 
            {
                refCP.SSN__c = ssnReformat;
            }
        }
        if(dateOfBirth == '')
        {
            System.debug('Date of Birth missing');
            errorMessage += '&#x2022; Date of Birth cannot be blank<br/>';
            isValid = false;
        } 
        else
        {
            //  MM/DD/YYYY format
            if(!Pattern.matches('^(0?[1-9]|1[0-2])\\/(0?[1-9]|1\\d|2\\d|3[01])\\/(19|20)\\d{2}$', dateOfBirth))
            {
                System.debug('Date of Birth invalid');
                errorMessage += '&#x2022; Please enter a valid Date of Birth<br/>';
            	isValid = false;
            } 
            else 
            {
                refCP.Date_of_Birth__c = Date.parse(dateOfBirth);
            }
        }
        if(refCP.PI_Categories__c == false && refCP.PI_Deletion__c == false && refCP.PI_Specific_Pieces__c == false)
        {
            System.debug('Request Type missing');
            errorMessage += '&#x2022; Request Type cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Communication_Type__c == null)
        {
            System.debug('Communication Type missing');
            errorMessage += '&#x2022; Communication Type cannot be blank<br/>';
            isValid = false;
        } 
        else if(refCP.Communication_Type__c == 'By mail at the following address:')
        {
            showMailingAddress = true;
        }
        else
        {
            showMailingAddress = false;
        }
        if(refCP.Mailing_Address_Line1__c == '' && showMailingAddress)
        {
            System.debug('Mailing Address Line 1 missing');
            errorMessage += '&#x2022; Mailing Address 1 cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Mailing_City__c == '' && showMailingAddress)
        {
            System.debug('Mailing City missing');
            errorMessage += '&#x2022; Mailing City cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Mailing_State__c == '' && showMailingAddress)
        {
            System.debug('Mailing State missing');
            errorMessage += '&#x2022; Mailing State cannot be blank<br/>';
            isValid = false;
        }
        if(refCP.Mailing_Zip_Code__c == '' && showMailingAddress)
        {
            System.debug('Mailing Zip Code missing');
            errorMessage += '&#x2022; Mailing Zip Code cannot be blank<br/>';
            isValid = false;
        }
        else if(refCP.Mailing_Zip_Code__c != '' && showMailingAddress)     
        {
            if(!Pattern.matches('\\d\\d\\d\\d\\d', refCP.Mailing_Zip_Code__c))
            {
                System.debug('Zip Code invalid');
                errorMessage += '&#x2022; Please enter a valid Mailing Zip Code<br/>';
                isValid = false;  
            }
        }
        
        System.debug('ConsumerPrivacyController: validation completed - ' + isValid);
        System.debug('Error Message - ' + errorMessage);
        
        return isValid;
    }
}