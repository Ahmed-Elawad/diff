/**
* History
* -------
  05/20/2019 Michael Karcz    Created
  08/24/2020 Michael Karcz    Modified/Added Validation to the form
  12/08/2022 Dan Carmen       Modified to use SF Duplicate Management
  04/17/2023 Dan Carmen       Add additional logging

**/

public without sharing class FlexOnlineAccountRequestController {
    public static final String CLASSNAME='FlexOnlineAccountRequestController';
    //Fields on form
    public String firmName {get;set;}
    public String zipCode {get;set;}
    //public String contactName {get;set;}
    public String contactFirstName {get;set;}
    public String contactLastName {get;set;}
    public String phone {get;set;}
    public String email {get;set;}
    public String newUsername {get;set;}
    public date dob {get;set;}
    
    //Salesforce Objects
    public Flex_Online_Account_Request__c foaRequest;
    public Referral_Account__c rAccount;
    public Referral_Contact__c rContact;
    public WebServiceSettings__c cs;
    
    //Variables for form
    public Referral_Account__c dupRAccount {get;set;}
    public Referral_Contact__c dupRContact {get;set;}
    public boolean internal {get;set;}
    public String displayMessage {get;set;}
    public boolean isUsernameUnique {get;set;}
    public boolean uniqueCheckError {get;set;}
    public boolean caseCreated {get;set;} //might not need
    public boolean showForm {get;set;}
    public boolean readyToSubmit {get;set;}
    public boolean foundRAccount {get;set;}
    public boolean foundRContact {get;set;}
    public boolean duplicateEmail {get;set;}
    
    public String city = '';
    public String state = '';
    
    private boolean error = false;
    private String endpoint;
    private String errorDescription = '';
    
    //***** Constructor *****
    public FlexOnlineAccountRequestController() {
        
        //Set default values for VF page
        isUsernameUnique = false;
        uniqueCheckError = true;
        showForm = true;
        caseCreated = false;
        foundRAccount = false;
        foundRContact = false;
        readyToSubmit = true;
        duplicateEmail = false;
        
        
        foaRequest = new Flex_Online_Account_Request__c();
        String rContactId = ApexPages.currentPage().getParameters().get('id');
        
        System.debug('FlexOnlineAccountRequestController, Constructor, Contact ID retrieved from URL: ' + rContactId);
        
        if(rContactId != null) {
            internal = true;
            rContact = [SELECT Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Contact_ID__c, PrimaryReferralType__c, OwnerId
                             , Referral_Account__r.Name, Referral_Account__r.Zip_Postal_Code__c 
                          FROM Referral_Contact__c WHERE Id =:rContactId LIMIT 1];
            rAccount = rContact.Referral_Account__r;
            
            //Check if the referral contact is a CPA/Accountant
            if(String.isBlank(rContact.PrimaryReferralType__c) || !rContact.PrimaryReferralType__c.contains('CPA')) {
                showForm = false;
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'This form only supports creating Flex accountant users from referring accountant records. The record you selected is not an Accountant. Please evaluate the record and try again with an Accountant. Note: Primary Referral Type does not contain "CPA"'));
            }
            
            firmName = rContact.Referral_Account__r.Name;
            zipCode = rContact.Referral_Account__r.Zip_Postal_Code__c;
            //contactName = rContact.Name;
            contactFirstName = rContact.First_Name__c; //Name.split(' ')[0];
            contactLastName = rContact.Last_Name__c; //Name.split(' ')[1];
            phone = rContact.Phone__c;
            email = rContact.Email__c;
            
            foaRequest.Submission_Start_Source__c = 'Internal';
            foaRequest.Submitted_By__c = UserHelper.getRunningUser().Name;
        }
        else {
            internal = false;
            foaRequest.Submission_Start_Source__c = 'External';
        }
        
        //Set values for tests
        /*
        if(Test.isRunningTest()){
            if(!internal) {
            	firmName = 'Test Firm 78';
    			zipCode = '14464';
    			contactFirstName = 'Kevin';
    			contactLastName = 'Smith';
    			phone = '4483928345';
    			email = 'testEmail2819@gmai1.com';
            }
            dob = Date.newInstance(1982, 5, 24); // Set dob for tests
        	newUsername = 'testUser33228'; // Set new username for tests
        }
        */
        //determine the endpoint based on which button was pressed
        //endpoint = null;
        String environment = ApexPages.currentPage().getParameters().get('access');
        
        environment = (String.isNotBlank(environment) ? environment : 'FlexCPAExternal');
        cs = WebServiceSettings__c.getInstance(environment);
        StringHelper.addToProcessNotes(foaRequest,'environment='+environment+' cs='+(cs != null ? cs.Name : 'NotFound'));
        
        //if (environment != null) {
        //    cs = WebServiceSettings__c.getInstance(environment);
        //} else if(environment == null) {
        //    cs = WebServiceSettings__c.getInstance('FlexCPAExternal');
        //}
        //else {
        //    cs = WebServiceSettings__c.getInstance('FlexCPAN2A');
        //}
        System.debug('FlexOnlineAccountRequestController cs='+cs);
        endpoint = (cs != null ? cs.Endpoint__c : null);
        //if(cs != null && cs.Endpoint__c != null) {
        //    endpoint = cs.Endpoint__c;
        //}
        
        System.debug('Testing at the end of the constructor');
        System.debug('showForm: ' + showForm);
        System.debug('foundRAccount: ' + foundRAccount);
        System.debug('foundRContact: ' + foundRContact);
    }//----- End Constructor -----
    
    
    public void validateAndCheckDupes() {
        foundRAccount = false;
        foundRContact = false;
        showForm = true;
        readyToSubmit = true;
        
        System.debug('MAK TEST - validateAndCheckDupes, readyToSubmit: ' + readyToSubmit);
        
        String validateMessage = validateForm();
        if(!String.isBlank(validateMessage)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, validateMessage));
            readyToSubmit = false;
            if(error) CreateACase();
            return;
        }
        //If the submission started within Salesforce
        if(internal) {
            List<Flex_Online_Account_Request__c> qryResults = [SELECT Id, Name__c FROM Flex_Online_Account_Request__c WHERE Referral_Contact__c = :rContact.Id];
            //If the record already exists
            if(!qryResults.isEmpty()) {
                displayMessage = 'An account for this user already exists. For password reset assistance or additional support, please contact the Paychex Online Support Team at: (877) 281-6624';
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, displayMessage));
                readyToSubmit = false;
            }
            else{
                foaRequest.Referral_Account__c = rAccount.Id;
                foaRequest.Referral_Contact__c = rContact.Id;
                foaRequest.Name__c = contactFirstName + ' ' + contactLastName;
                foaRequest.Phone__c = phone;
                foaRequest.Email__c = email;
                foaRequest.Zip_Code__c = zipCode;
                foaRequest.Flex_Username__c = newUsername;
                foaRequest.Ready_For_Submission__c = true;
                readyToSubmit = true;
            }
        }
        //If the submission started externally
        else {
            foaRequest.Submitted_By__c = contactFirstName + ' ' + contactLastName;
            
            //Check for referral account/referral contact
            //Id rAccId;
            //if(!Test.isRunningTest()) 
            Id rAccId = dupeBlockerRAccountCheck(firmName, zipCode);
            StringHelper.addToProcessNotes(foaRequest,'validateAndCheckDupes rAccId='+rAccId);
            
            system.debug('JGS rAccId = ' + rAccId);
            //duplicate account found, provide alternative options on page
            if(rAccId != null) {
                System.debug('MAK TEST rAccId: ' + rAccId);
                dupRAccount = [SELECT Id, Name, Zip_Postal_Code__c, OwnerId FROM Referral_Account__c WHERE Id = :rAccId LIMIT 1];
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, 'The data entered matches an existing referrer record. If you may have already created a Paychex Flex user with this information as well please go to www.PaychexFlex.com and use the Forgot Username/Password feature to access your account.  If not you can: Create a new Paychex Flex user for the existing referrer record or Create a new referrer record and new Paychex Flex user.'));
                showForm = false;
                foundRAccount = true;
                foaRequest.Duplicate_Referral_Account_Found__c = true;
                readyToSubmit = false;
                
                Id rConId = dupeBlockerRContactCheck(contactFirstName, contactLastName, email, dupRAccount.Id);
                StringHelper.addToProcessNotes(foaRequest,'validateAndCheckDupes rConId='+rConId);
                
                //duplicate contact found, set information to be able to show on page
                if(rConId != null) {
                    System.debug('MAK TEST rConId: ' + rConId);
                    dupRContact = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, OwnerId, Contact_ID__c FROM Referral_Contact__c WHERE Id = :rConId LIMIT 1];
                    foundRContact = true;
                    foaRequest.Duplicate_Referral_Contact_Found__c = true;
                    readyToSubmit = false;
                }
            }// if(rAccId != null)
        }// else	If the submission started externally
        
        if(!foundRAccount && !foundRContact && readyToSubmit) {
            System.debug('MAK TEST - validateAndCheckDupes, inside if statement calling submit()');
            submit();
        }
    }// end validateAndCheckDuplicates
    
    
    public void submit() {
        foundRAccount = false;
        showForm = true;
        
        System.debug('MAK TEST - submit, rAccount: ' + rAccount);
        System.debug('MAK TEST - submit, rContact: ' + rContact);
        StringHelper.addToProcessNotes(foaRequest,'submit rAccount='+(rAccount != null)+' rContact='+(rContact != null));
        
        //If there is no referral account
        if(rAccount == null) {
            rAccount = new Referral_Account__c();
            rAccount.RecordTypeId = RecordTypeHelper.getRecordType(Label.FLEX_Online_Referral_Account_RT, 'Referral_Account__c').getRecordTypeId();
            rAccount.Name = firmName;
            //Add address to Referral Account. Street_Address_1__c
            rAccount.Referral_Source_Business_Type__c = 'Accounting Firm';
            rAccount.Zip_Postal_Code__c = zipCode;
            rAccount.Use_Zip_Assignment_Rules__c = true;
            
            rContact = new Referral_Contact__c();
            rContact.RecordTypeId = RecordTypeHelper.getRecordType(Label.FLEX_Online_Referral_Contact_RT, 'Referral_Contact__c').getRecordTypeId();
            rContact.Name = contactFirstName + ' ' + contactLastName;
            rContact.First_Name__c=contactFirstName;
            rContact.Last_Name__c=contactLastName;
            rContact.Phone__c = phone;
            rContact.Email__c = email;
            
            readyToSubmit = true;
        } else if(rContact == null) {
            //If there is a referral account but we need to create a new contact
            rContact = new Referral_Contact__c();
            rContact.Referral_Account__c = rAccount.Id;
            rContact.RecordTypeId = RecordTypeHelper.getRecordType(Label.FLEX_Online_Referral_Contact_RT, 'Referral_Contact__c').getRecordTypeId();
            rContact.Name = contactFirstName + ' ' + contactLastName;
            rContact.First_Name__c=contactFirstName;
            rContact.Last_Name__c=contactLastName;
            rContact.Phone__c = phone;
            rContact.Email__c = email;
            readyToSubmit = true;
        } // else (If there is a referral account)

        if(readyToSubmit) {
            insertRObjects();
        }
        
        //Setup the foaRequest object with data from submission
        foaRequest.Referral_Account__c = rAccount.Id;
        foaRequest.Referral_Contact__c = rContact.Id;
        foaRequest.Name__c = contactFirstName + ' ' + contactLastName;
        foaRequest.Phone__c = phone;
        foaRequest.Email__c = email;
        foaRequest.Flex_Username__c = newUsername;
        foaRequest.Ready_For_Submission__c = true;
        
        //System.debug('MAK TEST: End of Submit, submit: ' + submit);
        //System.debug('MAK TEST: End of Submit, isUsernameUnique: ' + isUsernameUnique);
        //System.debug('MAK TEST: End of Submit, caseCreated: ' + caseCreated);
        //System.debug('MAK TEST: End of Submit, foundRAccount: ' + foundRAccount);
        //System.debug('MAK TEST: End of Submit, error: ' + error);
    }//----- End Submit -----
    
    
    public Id dupeBlockerRAccountCheck(String accountName, String zipCode) {
        Id returnId = null;
        Referral_Account__c ra = new Referral_Account__c(Name=accountName, NameForDuplicateManagement__c=accountName, Zip_Postal_Code__c=zipCode);
        StringHelper.addToProcessNotes(foaRequest,'dupeBlockerRAccountCheck ra='+ra);
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new SObject[]{ra});
        if (!results.isEmpty()) {
           DuplicateHelper.DupeResult result = results[0];
           StringHelper.addToProcessNotes(foaRequest,'dupeBlockerRAccountCheck hasResults='+result.hasResults+' result.refAcctIds='+result.refAcctIds);
           if (result.hasResults && !result.refAcctIds.isEmpty()) {
              returnId = result.refAcctIds[0];
           }
        } // if (!results.isEmpty
        /*
        Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Referral_account__c');
        if(isDupeBlockerSetup) {
            Referral_Account__c ra = new Referral_Account__c(Name=accountName, Zip_Postal_Code__c=zipCode);
            List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(ra);
            
            if(!matchSets.isEmpty()) {
                for(Id id : matchSets.get(0).matchedIds) {
                    return id;
                }
            }
        }
        try {
           Referral_Account__c[] ras = [Select Id, Name, Zip_Postal_Code__c, Account_Id__c 
                                          From Referral_Account__c
                                         Where Name = :accountName
                                           and Zip_Postal_Code__c = :zipCode
                                         order by LastModifiedDate desc];
           System.debug('dupeBlockerRAccountCheck ras='+ras.size());
           if (!ras.isEmpty()) {
              return ras[0].Id;
           }
        } catch (Exception e) {
           System.debug('Exception '+e.getMessage()); 
        }
        */
        return returnId;
    } // dupeBlockerRAccountCheck
    
    
    public Id dupeBlockerRContactCheck(String firstName, String lastName, String yourEmail, Id rAccID) {
        Id returnId = null;
        Referral_Contact__c rc = new Referral_Contact__c(First_Name__c=firstName, Last_Name__c=lastName, Email__c=yourEmail, Referral_Account__c=rAccID);
        StringHelper.addToProcessNotes(foaRequest,'dupeBlockerRContactCheck rc='+rc);
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new SObject[]{rc});
        if (!results.isEmpty()) {
           DuplicateHelper.DupeResult result = results[0];
           StringHelper.addToProcessNotes(foaRequest,'dupeBlockerRContactCheck hasResults='+result.hasResults+' result.refCtctIds='+result.refCtctIds);
           if (result.hasResults && !result.refCtctIds.isEmpty()) {
              returnId = result.refCtctIds[0];
           }
        } // if (!results.isEmpty

        /*
        Boolean isDupeBlockerSetup = Utilities.checkDupeBlocker('Referral_contact__c');
        
        if(isDupeBlockerSetup) {
            Referral_Contact__c rc = new Referral_Contact__c(First_Name__c=firstName, Last_Name__c=lastName, Email__c=yourEmail, Referral_Account__c=rAccID);
            List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(rc);
            
            if(!matchSets.isEmpty()) {
                for(Id id : matchSets.get(0).matchedIds) {
                    return id;
                }
            }
        }
        try {
           Referral_Contact__c[] rcs = [Select Id, Name, First_Name__c, Last_Name__c, Email__c, Referral_Account__c, Contact_Id__c 
                                          From Referral_Contact__c
                                         Where First_Name__c = :firstName
                                           and Last_Name__c = :lastName
                                           and Email__c = :yourEmail
                                           and Referral_Account__c = :rAccId
                                           and Contact_Id__c != null
                                         order by LastModifiedDate desc];
           System.debug('dupeBlockerRContactCheck rcs='+rcs.size());
           if (!rcs.isEmpty()) {
              return rcs[0].Id;
           }
        } catch (Exception e) {
           System.debug('Exception '+e.getMessage()); 
        }
        return null;
        */
        return returnId;
    } // dupeBlockerRContactCheck

    // for testing    
    public static Boolean performUsernameCallout = true;
    
    //***** isUsernameUnique *****
    public String isUsernameUnique() {
        if (!performUsernameCallout) {
            isUsernameUnique = true;
            return '';
        }
        
        if(String.isBlank(newUsername) || String.isBlank(endpoint)) return 'Please provide a new Flex username';
        
        String username = '';
        String password = '';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        if (String.isNotBlank(cs.Certificate__c)) {
           req.setClientCertificateName(cs.Certificate__c);
        }
        
        String reqBody = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:mes="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1"\n xmlns:orig="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:tim="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1"';
        reqBody += ' xmlns:sso="http://services.paychex.com/payx/SSOUserRegistration_1_0">\r\n';
        reqBody += '<soapenv:Header>\r\n';
        reqBody += '<mes:messageInfoElement>\r\n';
        reqBody += '<mes:timingInfo>\r\n';
        reqBody += '<tim:id>123456780</tim:id>\r\n';
        reqBody += '<tim:duration>10000</tim:duration>\r\n';
        reqBody += '</mes:timingInfo>\r\n';
        reqBody += '</mes:messageInfoElement>\r\n';
        reqBody += '</soapenv:Header>\r\n';
        reqBody += '<soapenv:Body>\r\n';
        reqBody += '<sso:isUsernameUnique>\r\n';
        reqBody += '<sso:username>' + newUsername + '</sso:username>\r\n';
        reqBody += '</sso:isUsernameUnique>\r\n';
        reqBody += '</soapenv:Body>\r\n';
        reqBody += '</soapenv:Envelope>';
        
        req.setTimeout(Integer.valueOf(cs.Timeout__c));
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Length', string.valueOf(reqBody.length()));
        req.setHeader('Content-Type', 'text/xml; charset=utf-8');
        req.setHeader('Soapaction', 'isUsernameUnique');
        req.setHeader('Accept-Encoding', 'gzip');
        req.setHeader('WWW-Authenticate', 'BASIC realm=""');
        req.setBody(reqBody);
        
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        //if (test.isRunningTest()){
        //    res.setStatusCode(200);
        //    res.setBody('<?xml version=\'1.0\' encoding=\'UTF-8\'?><S:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:S="http://schemas.xmlsoap.org/soap/envelope/"><env:Header><ns3:messageInfoElement xmlns:ns3="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns4="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:ns5="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1" xmlns:ns6="http://schemas.paychex.com/enterprise/metadata/CacheFlags_1" xmlns:ns7="http://schemas.paychex.com/enterprise/keyValuePair/TypedKeyValuePair_2"><ns3:trackingId>258d08c7-b2a7-420b-ab54-8baa6b69dc03</ns3:trackingId><ns3:originatorInfo><ns4:modifiedBy>Unknown User</ns4:modifiedBy></ns3:originatorInfo><ns3:timingInfo><ns5:id>123456780</ns5:id><ns5:duration>10000</ns5:duration></ns3:timingInfo></ns3:messageInfoElement><work:WorkContext xmlns:work="http://oracle.com/weblogic/soap/workarea/">rO0ABXoAAALmAC53ZWJsb2dpYy5hcHAucmVnaXN0cmF0aW9uLXN2Yy1jbHQtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMjAwNDIzMTYyM19SQ19yZWxlYXNlXzIwMjAuNS4yLW1hai1oeXUuNjMALndlYmxvZ2ljLmFwcC5sZWd1c2Vyc3RvcmUtc3ZjLWNsdC1wYXJhbGxlbC13YXIAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ADhOUl9QTkdfQlVJTERfMjAxOTEwMjgxNTE1X1JDX3JlbGVhc2VfMjAxOS4xMC4xLW1hai1qYWNfNQAmd2VibG9naWMuYXBwLnVzZXItc3ZjLWNsdC1wYXJhbGxlbC13YXIAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ADlOUl9QTkdfQlVJTERfMjAyMDA1MjExODI0X1JDX3JlbGVhc2VfMjAyMC42LjItbWFqLWplZS4yNTMAMHdlYmxvZ2ljLmFwcC5ib2xwb2xwcm92aXNpb25pbmctc3ZjLXBhcmFsbGVsLXdhcgAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAOE5SX1BOR19CVUlMRF8yMDIwMDUwNjIwMDZfUkNfcmVsZWFzZV8yMDIwLjUuMi1tYWotaHl1Ljc5AC53ZWJsb2dpYy5hcHAucHJvdmlzaW9uaW5nLXN2Yy1jbHQtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMjAwNTI2MTAzOV9SQ19yZWxlYXNlXzIwMjAuNi4yLW1hai1qZWUuNzIAAA==</work:WorkContext></env:Header><S:Body><ns8:isUsernameUniqueResponse xmlns="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponseInfo_1" xmlns:ns2="http://schemas.paychex.com/enterprise/keyValuePair/TypedKeyValuePair_2" xmlns:ns3="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns4="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:ns5="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1" xmlns:ns6="http://schemas.paychex.com/enterprise/metadata/CacheFlags_1" xmlns:ns7="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponse_1" xmlns:ns8="http://services.paychex.com/payx/SSOUserRegistration_1_0" xmlns:ns9="http://schemas.paychex.com/faults/GenericFault_1_0"><ns7:serviceResponseInfo><completed>true</completed></ns7:serviceResponseInfo><ns8:result><ns8:success>true</ns8:success></ns8:result></ns8:isUsernameUniqueResponse></S:Body></S:Envelope>');
        //}
        //else{
            res = http.send(req);
        //}
        
        //Debugging in full
        //if(!String.isBlank(Utilities.checkForProduction())) {
            //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, 'isUsernameUnique Request: ' + req.getBody()));
            //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, 'isUsernameUnique Response: ' + res.getBody()));
        //}
        
        System.debug('\nisUsernameUnique, Request: ' + req.getBody() + '\n');
        System.debug('\nisUsernameUnique, Response: ' + res.getBody() + '\n');
        
        // Handling Response //
        String xml = res.getBody();
        String returnVal='';
        
        if(xml.containsIgnoreCase('success>true<')) {
            isUsernameUnique = true;
            uniqueCheckError = false;
            //return '';
        } else if(xml.containsIgnoreCase('success>false<')){
            isUsernameUnique = false;
            uniqueCheckError = false;
            errorDescription += 'Username is not unique. ';
            returnVal='You are attempting to create a Username that already exists. If you would like to try to retrieve your username and reset your password, please use this link http://www.paychexflex.com/. If you need assistance in resetting your password or creating a new user, please click on the Create a Case button. A Paychex Representative will contact you shortly to assist in completing your new user setup.';
        } else {
            isUsernameUnique = false;
            uniqueCheckError = true;
            error = true;
            errorDescription += 'Unknown error occurred when attempting to connect to SSOUserRegistration (isUsernameUnique) service. Reason in Response from service: ' + xml.substringBetween('failureReasonCode>', '</');
            returnVal='An error was encountered in attempting to setup your new Username. A Paychex Representative will contact you shortly to assist in completing your new User setup.';
        }
        StringHelper.addToProcessNotes(foaRequest,'isUsernameUnique='+isUsernameUnique+' uniqueCheckError='+uniqueCheckError+' returnVal='+returnVal);
        return returnVal;
    }//----- End isUsernameUnique
    
    
    //***** createShellAccount *****
    public void createShellAccount(){
        if(isUsernameUnique && !caseCreated && !foundRAccount && readyToSubmit && !error) {
            System.debug('MAK TEST: createShellAccount BEGIN');
            if(String.isNotBlank(endpoint))
            {
                String username = '';
                String password = '';
                Blob headerValue = Blob.valueOf(username + ':' + password);
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                HttpRequest req = new HttpRequest();
                req.setEndpoint(endpoint);
                req.setMethod('POST');
                if (String.isNotBlank(cs.Certificate__c)) {
                   req.setClientCertificateName(cs.Certificate__c);
                }
                
                dob = dob.addDays(1); // adding one day due to the formatting in the next line subtracting a day for some unknown reason
                String dobstring = ((Datetime)dob).format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'); // formatting to be acceptable by the Flex service
                dob = dob.addDays(-1); // removing a day now that the date is properly formatted as to not affect the form
                String left = dobstring.left(26);
                String right = dobstring.right(2);
                dobstring = String.join(new List<String>{left, right}, ':');
                
                String reqBody = '<S:Envelope xmlns:S="http://schemas.xmlsoap.org/soap/envelope/">'
                    + '<S:Header>'
                    +    '<messageInfoElement xmlns="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns2="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1">'
                    +       '<trackingId>ewn1apw1.paychex.com-142802ca30c-2f</trackingId>'
                    +       '<messageFlowId>messageFlowId</messageFlowId>'
                    +       '<originatorInfo>'
                    +          '<ns2:srcSystem>sso.addUserRemote.saveNewUser</ns2:srcSystem>'
                    +          '<ns2:modifiedBy>cjwp1user</ns2:modifiedBy>'
                    +          '<ns2:modified_DateTime>2013-11-22T10:14:07.082-05:00</ns2:modified_DateTime>'
                    +       '</originatorInfo>'
                    +    '</messageInfoElement>'
                    +    '<WorkContext xmlns="http://oracle.com/weblogic/soap/workarea/">rO0ABXoAAAPyACF3ZWJsb2dpYy5hcHAuc3Vic2NyaXB0aW9uX3NlcnZpY2UAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ACJOUl9QTkdfQlVJTERfMjAxMzEwMTYxNTQ1X1JDX1I3XzQ1ABl3ZWJsb2dpYy5hcHAucGFydHlfcmVtb3RlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAjTlJfUE5HX0JVSUxEXzIwMTMxMTIwMTMyOF9SQ19SOGJfOTMAJndlYmxvZ2ljLmFwcC5yZXBvcnRpbmdTZWN1cml0eV9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAiTlJfUE5HX0JVSUxEXzIwMTMwODMwMDgxMl9SQ19SN18xNAAgd2VibG9naWMuYXBwLmVudGl0bGVtZW50X3NlcnZpY2UAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ACNOUl9QTkdfQlVJTERfMjAxMzExMDcxNDQwX1JDX1I4Yl8xMgAhd2VibG9naWMuYXBwLnJlZ2lzdHJhdGlvbl9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAiTlJfUE5HX0JVSUxEXzIwMTMxMDE4MDgwN19SQ19SN18xNQAhd2VibG9naWMuYXBwLnBuZ1VzZXJTdG9yZV9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAiTlJfUE5HX0JVSUxEXzIwMTMwODMwMDgxMl9SQ19SN18xNAAjd2VibG9naWMuYXBwLnVzZXJNYW5hZ2VtZW50X3NlcnZpY2UAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ACNOUl9QTkdfQlVJTERfMjAxMzExMjEwODQ1X1JDX1I4Yl8xNgAcd2VibG9naWMuYXBwLkNBUHJveHlTZXJ2aWNlcwAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAGU5SX1BOR19CVUlMRF8yMDEzMTEyMTEzMTkAG3dlYmxvZ2ljLmFwcC5wb3J0YWxfc2VydmljZQAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAI05SX1BOR19CVUlMRF8yMDEzMTEwNzE0MjhfUkNfUjhiXzE0AAA=</WorkContext>'
                    + '</S:Header>'
                    + '<S:Body>'
                    +    '<ns65:createShellAccount xmlns:ns65="http://services.paychex.com/payx/SSOUserRegistration_1_0" xmlns:ns10="http://xml.paychex.com/paychex/payroll/reporting/v1/ReportGenerationService_1" xmlns:ns11="http://xml.paychex.com/paychex/enterprise/common/v3/TypedKeyValuePair_3" xmlns:ns12="http://xml.paychex.com/paychex/payroll/reporting/v1/ReportOptionsData_1/" xmlns:ns13="http://xml.paychex.com/paychex/enterprise/report/v1/ReportOption_1/" xmlns:ns14="http://schemas.paychex.com/enterprise/client/ClientProductSubscription_1" xmlns:ns15="http://schemas.paychex.com/enterprise/product/Product_1" xmlns:ns16="http://schemas.paychex.com/es/client/ClientAppAcct_1_0" xmlns:ns17="http://schemas.paychex.com/es/client/EntAppRouting_1_0" xmlns:ns18="http://schemas.paychex.com/es/client/ClientCAppAcct_1_0" xmlns:ns19="http://schemas.paychex.com/es/client/ClientAcctRegisterMsg_1_0" xmlns:ns2="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponseInfo_1" xmlns:ns20="http://schemas.paychex.com/es/client/ClientData_1_0" xmlns:ns21="http://schemas.paychex.com/es/client/PostalAddress_1_0" xmlns:ns22="http://schemas.paychex.com/es/client/EntValidation_1_0" xmlns:ns23="http://schemas.paychex.com/enterprise/proposedResolution/ProposedResolution_1" xmlns:ns24="http://schemas.paychex.com/enterprise/properties/Properties_1" xmlns:ns25="http://schemas.paychex.com/payxHR-XML-3_0/UserAccountExt_1" xmlns:ns26="http://xml.paychex.com/paychex/enterprise/common/v4/" xmlns:ns27="http://xml.paychex.com/paychex/enterprise/service/v1/" xmlns:ns28="http://www.openapplications.org/oagis/v9/" xmlns:ns29="http://www.hr-xml.org/v3/" xmlns:ns3="http://schemas.paychex.com/es/fault/GenericFault_1_0" xmlns:ns30="http://xml.paychex.com/paychex/enterprise/financial/v1/" xmlns:ns31="http://xml.paychex.com/paychex/enterprise/client/v2/" xmlns:ns32="http://xml.paychex.com/paychex/payroll/v1/" xmlns:ns33="http://xml.paychex.com/paychex/enterprise/regulations/v1/" xmlns:ns34="urn:swift:xsd:pain001" xmlns:ns35="urn:swift:xsd:pain002" xmlns:ns36="http://xml.paychex.com/paychex/enterprise/filter/v1/" xmlns:ns37="http://xml.paychex.com/paychex/enterprise/worker/v1/" xmlns:ns38="http://schemas.paychex.com/enterprise/keyValuePair/TypedKeyValuePair_2" xmlns:ns39="http://schemas.paychex.com/faults/GenericFault_1_0" xmlns:ns4="http://www.hr-xml.org/3" xmlns:ns40="http://schemas.paychex.com/payxSSO/SSOUser_1" xmlns:ns41="http://services.paychex.com/payx/uc_1" xmlns:ns42="http://schemas.paychex.com/es/client/CltModMsg_1_0" xmlns:ns43="http://schemas.paychex.com/es/client/EntDataElement_1_0" xmlns:ns44="http://schemas.paychex.com/es/client/EntRequestor_1_0" xmlns:ns45="http://schemas.paychex.com/es/client/ClientLookupReq_1_0" xmlns:ns46="http://schemas.paychex.com/es/client/ClientAddMsg_1_0" xmlns:ns47="http://schemas.paychex.com/es/client/ClientSplitAppAcctMsg_1_0" xmlns:ns48="http://schemas.paychex.com/es/client/ClientLookupResp_1_0" xmlns:ns49="http://schemas.paychex.com/es/client/ClientSplitNotifReq_1_0" xmlns:ns5="http://www.openapplications.org/oagis/9" xmlns:ns50="http://xml.paychex.com/paychex/enterprise/report/v1/ReportSecurity_1" xmlns:ns51="http://schemas.paychex.com/enterprise/validationResult/ValidationResult_1" xmlns:ns52="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponse_2" xmlns:ns53="http://services.paychex.com/payx/worker/BasicWorkerDataAccess_1_0" xmlns:ns54="http://xml.paychex.com/paychex/enterprise/common/v2/GenericFault_2/" xmlns:ns55="http://schemas.paychex.com/enterprise/security/claims/SecurityComponents_2" xmlns:ns56="http://schemas.paychex.com/enterprise/security/claims/Permission_2" xmlns:ns57="http://schemas.paychex.com/enterprise/payxEntityId/PayxEntityId_1_0" xmlns:ns58="http://xml.paychex.com/paychex/enterprise/portal/v2/" xmlns:ns59="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns6="http://xml.paychex.com/paychex/payroll/locking/v1/" xmlns:ns60="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:ns61="http://schemas.paychex.com/enterprise/security/claims/Identity_1" xmlns:ns62="http://schemas.paychex.com/enterprise/security/claims/SecurityComponents_1" xmlns:ns63="http://schemas.paychex.com/enterprise/security/claims/Permission_1" xmlns:ns64="http://schemas.paychex.com/enterprise/security/claims/PaychexUser_1" xmlns:ns66="http://schemas.paychex.com/enterprise/security/claims/Identity_3" xmlns:ns67="http://schemas.paychex.com/enterprise/security/claims/SecurityComponents_3" xmlns:ns68="http://schemas.paychex.com/enterprise/security/claims/PaychexUser_2" xmlns:ns69="http://xml.paychex.com/paychex/enterprise/user/v2/ws/" xmlns:ns7="http://schemas.paychex.com/es/client/ClientRelatedAppAcct_1_0" xmlns:ns70="http://services.paychex.com/payx/DataportalService/Types_2" xmlns:ns71="http://schemas.paychex.com/payx/Internal_LDAP_1" xmlns:ns72="http://xml.paychex.com/paychex/enterprise/client/v2/ws/" xmlns:ns73="http://services.paychex.com/payx/PNGUserStore_1_0" xmlns:ns74="http://xml.paychex.com/paychex/payroll/notes/v1/ws/" xmlns:ns75="http://xml.paychex.com/paychex/payroll/notes/v1/" xmlns:ns76="http://xml.paychex.com/paychex/enterprise/financial/v1/ws/" xmlns:ns77="http://services.paychex.com/payx/UserWebflowService_1_0" xmlns:ns78="http://xml.paychex.com/paychex/enterprise/subscription/v2/ws/" xmlns:ns79="http://schemas.paychex.com/enterprise/security/claims/SoftwareApplicationSystem_1" xmlns:ns8="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponse_1" xmlns:ns80="http://schemas.paychex.com/enterprise/security/claims/Roles_1" xmlns:ns81="http://schemas.paychex.com/faults/OperationInfo_1_0" xmlns:ns82="http://services.paychex.com/payx/MigrationToolService_1_0" xmlns:ns83="http://xml.paychex.com/paychex/enterprise/report/ws/v1/" xmlns:ns84="http://xml.paychex.com/paychex/payroll/dataimport/v3/ws/" xmlns:ns85="http://xml.paychex.com/paychex/payroll/dataimport/v3/" xmlns:ns86="http://xml.paychex.com/paychex/enterprise/portal/v2/ws/" xmlns:ns87="http://xml.paychex.com/paychex/enterprise/worker/v1/ws/" xmlns:ns88="http://xml.paychex.com/paychex/enterprise/entitlement/v2/ws/" xmlns:ns89="http://xml.paychex.com/paychex/payroll/locking/v1/ws/" xmlns:ns9="http://services.paychex.com/payx/client/ClientProductSubscriptionService_1_0" xmlns:ns90="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1" xmlns:ns91="http://schemas.paychex.com/es/fault/EntIdFault_1_0" xmlns:ns92="http://schemas.paychex.com/enterprise/payx/UserLdapType_1" xmlns:ns93="http://schemas.paychex.com/enterprise/domain/worker/BasicWorker_1">'
                    +       '<ns65:info>'
                    +          '<ns65:firstName>' + foaRequest.Name__c.split(' ').get(0) + '</ns65:firstName>'
                    +          '<ns65:lastName>' + foaRequest.Name__c.split(' ').get(1) + '</ns65:lastName>'
                    +          '<ns65:dateOfBirth>' + dobstring + '</ns65:dateOfBirth>'
                    +          '<ns65:cpaId>' + rContact.Contact_ID__c + '</ns65:cpaId>' //rContact.Contact_ID__c
                    +          '<ns65:jobTitle>test</ns65:jobTitle>'
                    +          '<ns65:emailAddress>' + foaRequest.Email__c + '</ns65:emailAddress>'
                    +          '<ns65:username>' + foaRequest.Flex_Username__c + '</ns65:username>'
                    +          '<ns65:phoneNumber>' + foaRequest.Phone__c.replaceAll('[^0-9]', '') + '</ns65:phoneNumber>'
                    +          '<ns65:addressLine1></ns65:addressLine1>'
                    +          '<ns65:addressLine2/>'
                    +          '<ns65:pin>1234</ns65:pin>'
                    +          '<ns65:city>' + city + '</ns65:city>'
                    +          '<ns65:state>' + state + '</ns65:state>'
                    +          '<ns65:zipCode>' + zipCode + '</ns65:zipCode>'
                    +          '<ns65:country>US</ns65:country>'
                    +          '<ns65:accountType>ACCOUNTANT</ns65:accountType>'
                    +       '</ns65:info>'
                    +    '</ns65:createShellAccount>'
                    + '</S:Body>'
                    + '</S:Envelope>';
                
                req.setTimeout(Integer.valueOf(cs.Timeout__c));
                req.setHeader('Authorization', authorizationHeader);
                req.setHeader('Content-Length', string.valueOf(reqBody.length()));
                req.setHeader('Content-Type', 'text/xml; charset=utf-8');
                req.setHeader('Soapaction', 'createShellAccount');
                req.setHeader('Accept-Encoding', 'gzip');
                req.setHeader('WWW-Authenticate', 'BASIC realm=""');
                req.setBody(reqBody);
                
                Http http = new Http();
                HttpResponse res = new HttpResponse();
                //if (Test.isRunningTest()){
                //    res.setStatusCode(200);
                //    res.setBody('<?xml version=\'1.0\' encoding=\'UTF-8\'?><S:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:S="http://schemas.xmlsoap.org/soap/envelope/"><env:Header><ns3:messageInfoElement xmlns:ns3="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns4="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:ns5="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1" xmlns:ns6="http://schemas.paychex.com/enterprise/metadata/CacheFlags_1" xmlns:ns7="http://schemas.paychex.com/enterprise/keyValuePair/TypedKeyValuePair_2"><ns3:trackingId>ewn1apw1.paychex.com-142802ca30c-2f</ns3:trackingId><ns3:messageFlowId>messageFlowId</ns3:messageFlowId><ns3:originatorInfo><ns4:srcSystem>sso.addUserRemote.saveNewUser</ns4:srcSystem><ns4:modifiedBy>cjwp1user</ns4:modifiedBy><ns4:modified_DateTime>2013-11-22T10:14:07.082-05:00</ns4:modified_DateTime></ns3:originatorInfo></ns3:messageInfoElement><work:WorkContext xmlns:work="http://oracle.com/weblogic/soap/workarea/">rO0ABXoAAAQAABl3ZWJsb2dpYy5hcHAucGFydHlfcmVtb3RlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAjTlJfUE5HX0JVSUxEXzIwMTMxMTIwMTMyOF9SQ19SOGJfOTMAKXdlYmxvZ2ljLmFwcC51c2VydXRpbGl0eS1zdmMtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMjAwMzI3MTY0OV9SQ19yZWxlYXNlXzIwMjAuNC4zLW1hai1mb3IuNzcAIXdlYmxvZ2ljLmFwcC5zdWJzY3JpcHRpb25fc2VydmljZQAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAIk5SX1BOR19CVUlMRF8yMDEzMTAxNjE1NDVfUkNfUjdfNDUAJndlYmxvZ2ljLmFwcC5yZXBvcnRpbmdTZWN1cml0eV9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAiTlJfUE5HX0JVSUxEXzIwMTMwODMwMDgxMl9SQ19SN18xNAAud2VibG9naWMuYXBwLnN1YnNjcmlwdGlvbi1zdmMtY2x0LXBhcmFsbGVsLXdhcgAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAOU5SX1BOR19CVUlMRF8yMDIwMDUyNjExNDdfUkNfcmVsZWFzZV8yMDIwLjYuMi1tYWotamVlLjUwOAAud2VibG9naWMuYXBwLmNvbXBhc3NvY2dhdGV3YXktc3ZjLXBhcmFsbGVsLXdhcgAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAOE5SX1BOR19CVUlMRF8yMDIwMDQyMzA5MDNfUkNfcmVsZWFzZV8yMDIwLjUuMi1tYWotaHl1LjU3ACZ3ZWJsb2dpYy5hcHAuZ3VpZC1zdmMtY2x0LXBhcmFsbGVsLXdhcgAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAGU5SX1BOR19CVUlMRF8yMDE5MDYyMDE0NDQAIXdlYmxvZ2ljLmFwcC5yZWdpc3RyYXRpb25fc2VydmljZQAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAIk5SX1BOR19CVUlMRF8yMDEzMTAxODA4MDdfUkNfUjdfMTUAMHdlYmxvZ2ljLmFwcC5ib3oAAAQAbHBvbHByb3Zpc2lvbmluZy1zdmMtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMjAwNTA2MjAwNl9SQ19yZWxlYXNlXzIwMjAuNS4yLW1hai1oeXUuNzkALndlYmxvZ2ljLmFwcC5wcm92aXNpb25pbmctc3ZjLWNsdC1wYXJhbGxlbC13YXIAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ADhOUl9QTkdfQlVJTERfMjAyMDA1MjYxMDM5X1JDX3JlbGVhc2VfMjAyMC42LjItbWFqLWplZS43MgApd2VibG9naWMuYXBwLnVzZXJ3ZWJmbG93LXN2Yy1wYXJhbGxlbC13YXIAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ADhOUl9QTkdfQlVJTERfMjAyMDA0MjMwOTM5X1JDX3JlbGVhc2VfMjAyMC41LjItbWFqLWh5dS41MgAgd2VibG9naWMuYXBwLmVudGl0bGVtZW50X3NlcnZpY2UAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ACNOUl9QTkdfQlVJTERfMjAxMzExMDcxNDQwX1JDX1I4Yl8xMgAbd2VibG9naWMuYXBwLnBvcnRhbF9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAjTlJfUE5HX0JVSUxEXzIwMTMxMTA3MTQyOF9SQ19SOGJfMTQAHndlYmxvZ2ljLmFwcC5lbnRjb21tb24tc3ZjLWNsdAAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAIE5SX0hSU19CVUlMRF8yMDE4MTEwNTE0MTBfUkNfMTAyAC53ZWJsb2dpYy5hcHAucmVnaXN0cmF0aW9uLXN2Yy1jbHQtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMjAwNDIzMTYyM19SQ19yZWxlYXNlXzIwMjAuNS4yLW1hai1oeXUuNjMAJHdlYmxvZ2ljLmFwcC5wYmFwcm92aXNpb25pbmctc3ZjLWNsdAAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAIE5SX0hSU19CVUlMRF8yMDIwMDUyMDEzMzRfUkNfMTkxAHoAAAJvI3dlYmxvZ2ljLmFwcC51c2VyTWFuYWdlbWVudF9zZXJ2aWNlAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAAjTlJfUE5HX0JVSUxEXzIwMTMxMTIxMDg0NV9SQ19SOGJfMTYAJndlYmxvZ2ljLmFwcC51c2VyLXN2Yy1jbHQtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA5TlJfUE5HX0JVSUxEXzIwMjAwNTIxMTgyNF9SQ19yZWxlYXNlXzIwMjAuNi4yLW1hai1qZWUuMjUzAC53ZWJsb2dpYy5hcHAubGVndXNlcnN0b3JlLXN2Yy1jbHQtcGFyYWxsZWwtd2FyAAAA1gAAACN3ZWJsb2dpYy53b3JrYXJlYS5TdHJpbmdXb3JrQ29udGV4dAA4TlJfUE5HX0JVSUxEXzIwMTkxMDI4MTUxNV9SQ19yZWxlYXNlXzIwMTkuMTAuMS1tYWotamFjXzUAIXdlYmxvZ2ljLmFwcC5wbmdVc2VyU3RvcmVfc2VydmljZQAAANYAAAAjd2VibG9naWMud29ya2FyZWEuU3RyaW5nV29ya0NvbnRleHQAIk5SX1BOR19CVUlMRF8yMDEzMDgzMDA4MTJfUkNfUjdfMTQAHHdlYmxvZ2ljLmFwcC5DQVByb3h5U2VydmljZXMAAADWAAAAI3dlYmxvZ2ljLndvcmthcmVhLlN0cmluZ1dvcmtDb250ZXh0ABlOUl9QTkdfQlVJTERfMjAxMzExMjExMzE5AAA=</work:WorkContext>'
                //                + '</env:Header><S:Body><ns8:createShellAccountResponse xmlns="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponseInfo_1" xmlns:ns2="http://schemas.paychex.com/enterprise/keyValuePair/TypedKeyValuePair_2" xmlns:ns3="http://schemas.paychex.com/enterprise/metadata/MessageInfo_1" xmlns:ns4="http://schemas.paychex.com/enterprise/metadata/OriginatorInfo_1" xmlns:ns5="http://schemas.paychex.com/enterprise/metadata/TimingInfo_1" xmlns:ns6="http://schemas.paychex.com/enterprise/metadata/CacheFlags_1" xmlns:ns7="http://schemas.paychex.com/enterprise/serviceResponse/ServiceResponse_1" xmlns:ns8="http://services.paychex.com/payx/SSOUserRegistration_1_0" xmlns:ns9="http://schemas.paychex.com/faults/GenericFault_1_0"><ns7:serviceResponseInfo><completed>true</completed></ns7:serviceResponseInfo><ns8:result><ns8:success>true</ns8:success></ns8:result><ns8:guid>00JWDGDYKAY0YMBSRJZP</ns8:guid></ns8:createShellAccountResponse></S:Body></S:Envelope>');
				//}
                //else{
                    res = http.send(req);
                //}
                
                System.debug('\ncreateShellAccount, Request: ' + req.getBody() + '\n');
                System.debug('\ncreateShellAccount, Response: ' + res.getBody() + '\n');
                
                addToRequestResponse('Request: '+req.getBody());
                addToRequestResponse('Response: '+res.getBody());
                
                //Uncomment these for testing
                //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, 'createShellAccount Request: ' + req.getBody()));
                //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, 'createShellAccount Response: ' + res.getBody()));
                
                // Handling Response //
                String xml = res.getBody();
                
                //If an error was found in the response
                if(xml.containsIgnoreCase('success>false</')) {
                    System.debug('MAK TEST: createShellAccount SUCCESS FALSE');
                    Boolean createCase = true;
                    foaRequest.Ready_For_Submission__c = false;
                    foaRequest.Successful_Submission__c = false;
                    String failureReasonCode = xml.substringBetween('failureReasonCode>', '</failureReasonCode>');
                    if(!String.isBlank(failureReasonCode)) foaRequest.Error_Messages__c += failureReasonCode;
                    //If the error was because the email already exists
                    if(xml.containsIgnoreCase('EMAIL_EXISTS')) {
                        System.debug('MAK TEST: createShellAccount EMAIL EXISTS');
                        createCase = false;
                        isUsernameUnique = false;
                        uniqueCheckError = false;
                        foaRequest.Error_Messages__c += 'Email already exists';
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'The e-mail address you entered is already registered to an existing Paychex Flex user. Please go to www.PaychexFlex.com and use the Forgot Username/Password feature to access your account.'));
                    }
                    //Successful connection but Unknown error
                    else {
                        System.debug('MAK TEST: createShellAccount CONNECTION SUCCESS UNKNOWN ERROR');
                        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'An error was encountered in attempting to setup your new Username. A Paychex Representative will contact you shortly to assist in completing your new User setup. Error: Successful connection, unknown error.'));
                        errorDescription += 'Unknown error occurred when attempting to connect to SSOUserRegistration (createShellAccount) service.\n';
                    }
                    errorDescription +=  'Response from service: ' + xml;
                    error = true;
                    if(createCase) createACase();
                }
                //Unsuccessful service call
                else if(xml.containsIgnoreCase('faultString')) {
                    System.debug('MAK TEST: createShellAccount FAULTSTRING');
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'An error was encountered in attempting to setup your new Username. A Paychex Representative will contact you shortly to assist in completing your new User setup. Error: Unsuccessful connection.'));
                    errorDescription += 'FaultString found. The service could not be connected to. This could be due to the service being unavailable or due to an unknown error. Service call Response: ' + xml;
                    error = true;
                    createACase();
                }
                else {
                    System.debug('MAK TEST: createShellAccount SUCCESS');
                    foaRequest.Ready_For_Submission__c = false;
                    foaRequest.Successful_Submission__c = true;
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Your submission has been submitted successfully.'));
                }
                
                //If the request was successful, move the username to the Referral Contact record
                if(!foaRequest.Ready_For_Submission__c && foaRequest.Successful_Submission__c) {
                    if(rContact != null) {
                        rContact.Flex_Online_Account_Username__c = foaRequest.Flex_Username__c;
                        rContact.Primary_Contact__c = true;
                        DMLHelper.performDML2(new List<Referral_Contact__c>{rContact}, DmlHelper.DML_UPDATE, 'FlexOnlineAccountRequestMethods', 'createShellAccount', 'Updating Referral Contact after assigning Flex Username', true);
                    }
                }
                insertFOARequest();
            }// if(String.isNotBlank(endpoint)
        }// if(isUsernameUnique && !caseCreated...
    }//----- End createShellAccount -----
    
    public void addToRequestResponse(String msgToAdd) {
       Schema.DescribeFieldResult dfr = Flex_Online_Account_Request__c.RequestResponse__c.getDescribe();
       //Integer fldSize = CSO_Tracking__c.CsoResponse__c.getDescribe().getLength();
       StringHelper.addToProcessNotes(foaRequest, dfr, msgToAdd);
    } // addToCsoResponse

    public void createACase() {
        Case c = new Case();
        c.RecordTypeId = RecordTypeHelper.getRecordType(Label.FLEX_Online_Case_RT, 'Case').getRecordTypeId();
        System.debug('FlexOnlineAccountRequestController, CreateACase, record type Id: ' + c.RecordTypeId);
        c.Priority = 'Medium';
        c.Type = 'Act Support';
        c.Origin = 'Flex Online Account Form';
        c.OwnerId = Label.Flex_Online_Owner_Queue_ID;
        c.Description = 'Submitted values: ' + '\n'
                			+ 'Firm name: ' + firmName + '\n'
                			+ 'Zip Code: ' + zipCode + '\n'
                			+ 'New User First/Last Name: ' + contactFirstName + ' ' + contactLastName + '\n'
                			+ 'Phone: ' + phone + '\n'
                			+ 'Email: ' + email + '\n'
                			+ 'New Flex Username: ' + newUsername + '\n';
        if(rContact != null) {
            c.Referral_Contact__c = rContact.Id;    
        }
        
        if(rAccount != null) {
            c.Referral_Account__c = rAccount.Id;
        }
        
        if(internal) {
            c.Submitter_Name__c = UserHelper.getRunningUser().Id;
            System.debug('FlexOnlineAccountRequestController, CreateACase, getRunningUser Id: ' + c.contactId);
            c.Description += '\nReferral Account: ' + rAccount.Id + ' ' + rAccount;
            c.Description += '\nReferral Contact: ' + rContact.Id + ' ' + rContact;
            c.Description += '\nInternal or External: Internal';
        }
        else c.Description += '\nInternal or External: External';
        
        if(error) {
            c.Subject = 'Flex Online Account Request Error';
            c.Description +=  '\n' + errorDescription;
        }
        else {
            c.Subject = 'New Flex Online Account Request From Existing Record';
        }
        
        DmlHelper.performDML2(new List<Case>{c}, DmlHelper.DML_INSERT, 'FlexOnlineAccountRequestController', 'createACase', 'Insert new case upon error', false);
        caseCreated = true;
        foaRequest.Case_Created__c = true;
        foaRequest.Case__c = c.Id;

        apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'A case has been submitted to notify the ACT team.'));
    } // createACase
    
    
    //called from button on vf page to use the dupeblocker found referral account
    public void useRAccount() {
        rAccount = dupRAccount;
        foaRequest.Referral_Account_Used__c = true;
        StringHelper.addToProcessNotes(foaRequest,'useRAccount rAccount='+(rAccount != null ? String.valueOf(rAccount.Id) : 'Id Not Found!'));
        submit();
    } // useRAccount
    
    
    //called from button on vf page to use the dupeblocker found referral account and referral contact
    public void useRAcctRCon() {
        readyToSubmit = true;
        rContact = dupRContact;
        foaRequest.Referral_Contact_Used__c = true;
        StringHelper.addToProcessNotes(foaRequest,'useRAcctRCon rContact='+(rContact != null ? String.valueOf(rContact.Id) : 'Id Not Found!'));
        useRAccount();
    } // useRAcctRCon
    
    
    public String validateForm() {
        String errorMessage = '';
        Boolean usernameInvalid = false;
        Boolean emailInvalid = false;
        
        errorMessage += isUsernameUnique();
        
        String formattedZip = zipCode.length() > 5 ? zipCode.subString(0,5) : zipCode;
        System.debug('MAK FORMATTEDZIP: ' + formattedZip);
        Boolean zipInfoFound = retrieveZipInformation(formattedZip);
        if(!zipInfoFound) {
            errorMessage += 'Please verify that the zip code is accurate.';
        }
        
        if(!String.isBlank(firmName)) {
            if(firmName.contains('  ')) firmName.replaceAll('  ', ' ');
        }
        
        //First name, Last name, and Email != null
        if(String.isBlank(contactFirstName) || String.isBlank(contactLastName) || String.isBlank(email) || String.isBlank(phone) || String.isBlank(newUsername) || String.isBlank(zipCode)) {
            errorMessage += 'All fields are required.';
        }
        //Check these only if the first name, last name, and email are all populated
        else {
            //First name too long
            if(contactFirstName.length() > 40) {
                errorMessage += 'First name is required and must be 30 characters or less.';
            }
            //Last name too long
            if(contactLastName.length() > 40) {
                errorMessage += 'Last name is required and must be 30 characters or less.';
            }
            
            //Replace double spaces in the first and last name
            if(contactFirstName.contains('  ')) contactFirstName.replaceAll('  ', ' ');
            if(contactLastName.contains('  ')) contactLastName.replaceAll('  ', ' ');
            
            //Validate the email is x@y.zz format
            if(!Pattern.matches('^.+@.+\\..{2,}$', email)) {
                //emailInvalid = true;
                errorMessage += 'An e-mail address must be in the format x@y.zz where x is one or more characters, y is one or more characters, and zz is two or more characters.';
            }
            
            if(zipCode.length() != 5) {
                errorMessage += 'Zip code must be 5 digits.';
            }
            
            String tempPhone = phone.replaceAll('[^0-9]', '');
            if(tempPhone.length() != 10) {
                errorMessage += 'Phone number must contain 10 digits.';
            }
            
            if(newUsername.length() > 20) {
                errorMessage += 'Username is required and must be 20 characters or less.';
            }
            
            if(!(newUsername.length() >= 8 && newUsername.length() <= 18) || !(newUsername.containsOnly('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-_'))) {
            	errorMessage += 'Username must be between 8-18 characters long, and can only contain letters, numbers, hyphens, periods, and underscores.';
            }
        }
        StringHelper.addToProcessNotes(foaRequest,'validateForm errorMessage='+errorMessage);
        return errorMessage;
    }// Validate form
    
    
    public void insertRObjects() {
        if(rAccount != null) {
            String dmlType = (rAccount.id != null ? DmlHelper.DML_UPDATE : DmlHelper.DML_INSERT);
            StringHelper.addToProcessNotes(foaRequest,'insertRObjects rAccount dmlType='+dmlType);
            Referral_Account__c[] rAccounts = new Referral_Account__c[]{rAccount};
            DMLHelper.performDML2(rAccounts,dmlType, CLASSNAME, 'insertRObjects', 'Save Referral Account', true);
            rAccount = [SELECT Id, OwnerId, Name, Zip_Postal_Code__c, Referral_Source_Business_Type__c, Use_Zip_Assignment_Rules__c FROM Referral_Account__c WHERE Id = :rAccount.Id];
        }
        
        if(rContact != null) {
            Referral_Contact__c[] rContacts = new Referral_Contact__c[]{rContact};
            if (rContact.Id == null) {
                rContact.Referral_Account__c = rAccount.Id;
                rContact.OwnerId = rAccount.OwnerId;
            }
            String dmlType = (rContact.id != null ? DmlHelper.DML_UPDATE : DmlHelper.DML_INSERT);
            StringHelper.addToProcessNotes(foaRequest,'insertRObjects rContact dmlType='+dmlType);
            DMLHelper.performDML2(rContacts,dmlType, CLASSNAME, 'insertRObjects', 'Save Referral Contact', true);
            System.debug('Testing rContact ID: ' + rContact.Id);
            rContact = [SELECT Id, Name, Phone__c, Email__c, Contact_ID__c, PrimaryReferralType__c, OwnerId, Referral_Account__c, Referral_Account__r.Name, Referral_Account__r.Zip_Postal_Code__c FROM Referral_Contact__c WHERE Id =:rContact.Id LIMIT 1];
        }
    } // insertRObjects
    
    public boolean retrieveZipInformation(String zip) {
        boolean successfulCall = false;
        try {
            Zip_Code_Information__c zipInfo = [SELECT City__c, State__c FROM Zip_Code_Information__c WHERE Name = :zip LIMIT 1];
            city = zipInfo.City__c;
        	state = zipInfo.State__c;
            successfulCall = true;
            System.debug('MAK CITY/STATE: ' + city + '\\' + state);
        } catch(System.QueryException e) {
            System.debug('FlexOnlineAccountRequestController, retrieveZipInformation, exception occured: ' + e.getMessage());
            successfulCall = false;
        }
        return successfulCall;
    }
    
    
    public void insertFOARequest() {
        System.debug('FOAREQUEST QUEUEABLE: \n rAccount: ' + rAccount + '\n rContact: ' + rContact);
        
        List<Flex_Online_Account_Request__c> foaReqs = new List<Flex_Online_Account_Request__c> {foaRequest};
        foaRequest.Referral_Account__c = rAccount.Id;
        foaRequest.Referral_Contact__c = rContact.Id;
        DMLHelper.performDML2(foaReqs, DmlHelper.DML_INSERT, 'FlexOnlineAccountRequestQueueable', 'doDMLUpdate', 'Inserting FOARequest', true);
    } // insertFOARequest
}