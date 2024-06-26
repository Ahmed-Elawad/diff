/** Controller extension class for the Flex New Client Onboarding VF page
* 
* History
* -------
* 08/05/2019   Michael Karcz   Created
* 07/06/2020  Jacob Hinds         Added without sharing per PMD
* 03/04/2022    Manoj    Updated code to make email and phone field to inputfield 
  10/25/2022   Dan Carmen      Additional changes for CSO/Enterprise registraion

*/

public without sharing class FlexNewClientOnboardingController {
    public Contact contact {get; set;}
    public String streetAdr {get; set;}
    public String city {get; set;}
    public String stateProv {get; set;}
    public String postalCode {get;set;}
    public String country {get; set;}
    public Boolean isResend {get;set;}
    public List<SelectOption> stateProvList {get; set;}
    public List<SelectOption> countryList {get; set;}
    public Map<String, String> stateMap = new Map<String, String>{'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ', 'Arkansas' => 'AR', 'California' => 'CA', 'Colorado' => 'CO', 'Connecticut' => 'CT', 'DC' => 'DC', 'Delaware' => 'DE', 'Florida' => 'FL', 'Georgia' => 'GA', 'Hawaii' => 'HI', 'Idaho' => 'ID', 'Illinois' => 'IL', 'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS', 'Kentucky' => 'KY', 'Louisiana' => 'LA', 'Maine' => 'ME', 'Marshall Islands' => 'MH', 'Maryland' => 'MD', 'Massachusetts' => 'MA', 'Michigan' => 'MI', 'Minnesota' => 'MN', 'Mississippi' => 'MS', 'Missouri' => 'MO', 'Montana' => 'MT', 'Nebraska' => 'NE', 'Nevada' => 'NV', 'New Hampshire' => 'NH', 'New Jersey' => 'NJ', 'New Mexico' => 'NM', 'New York' => 'NY', 'North Carolina' => 'NC', 'North Dakota' => 'ND', 'Ohio' => 'OH', 'Oklahoma' => 'OK', 'Oregon' => 'OR', 'Pennsylvania' => 'PA', 'Puerto Rico' => 'PR', 'Rhode Island' => 'RI', 'South Carolina' => 'SC', 'South Dakota' => 'SD', 'Tennessee' => 'TN', 'Texas' => 'TX', 'Utah' => 'UT', 'Vermont' => 'VT', 'Virginia' => 'VA', 'Virgin Islands' => 'VI', 'Washington' => 'WA', 'Washington DC' => 'DC', 'D.C.' => 'DC', 'West Virginia' => 'WV', 'Wisconsin' => 'WI', 'Wyoming' => 'WY'};
    public Map<String, String> provinceMap = new Map<String, String>{'Alberta' => 'AB', 'British Columbia' => 'BC', 'Manitoba' => 'MB', 'New Brunswick' => 'NB', 'Newfoundland' => 'NL', 'Labrador' => 'NL', 'Northwest Territories' => 'NT', 'Nova Scotia' => 'NS', 'Nunavut' => 'NU', 'Ontario' => 'ON', 'Prince Edward Island' => 'PE', 'Quebec' => 'QC', 'Saskatchewan' => 'SK', 'Yukon' => 'YT'};
    public Map<String, String> countryMap = new Map<String, String>{'United States' => 'US', 'Canada' => 'CA'};
    final String tinType = 'FEIN';
    public WebServiceSettings__c cs;
    /**BAU Changes**/ 
    public WebServiceSettings__c cs1;
    public String opportunityId;
    public String contactId;
    public String pageTitle {
        get {
            String title = (isResend != null && isResend ? 'Resend Flex Online Account Request' : 'Flex Online Account Request');
            return title;
        }} // pageTitle
    public String buttonTitle { 
        get {
            String title = (isResend != null && isResend ? 'Resend User Registration' : 'Submit New Client Request');
            return title;
        }} // buttonTitle
    
    public FlexNewClientOnboardingController() {
        isResend = false;
        cs = WebServiceSettings__c.getInstance('NewClientOnboarding');
        /**BAU Changes**/ //getting the customsetting value to resend the request to Flex system for email/phone updation 
        cs1 = WebServiceSettings__c.getInstance('NewClientOnboardingUpdation');
        /**BAU Changes**/
        stateProvList = new List<SelectOption>();
        countryList = new List<SelectOption>();
        
        for(String st : stateMap.keySet()) {
            stateProvList.add(new SelectOption(stateMap.get(st), st));
        }
        for(String prov : provinceMap.keySet()) {
            stateProvList.add(new SelectOption(provinceMap.get(prov), prov));
        }
        for(String cont : countryMap.keySet()) {
            countryList.add(new SelectOption(countryMap.get(cont), cont));
        }
        
        if (ApexPages.currentPage() != null) {
           //System.debug('ApexPages.currentPage().getParameters()  '+ApexPages.currentPage().getParameters());
           contactId = ApexPages.currentPage().getParameters().get('id');
           opportunityId = ApexPages.currentPage().getParameters().get('oppId');
        }

        setContact(contactId);
    } //END constructor
    
    public void setContact(String contactId) {
        if (contactId != null) {
            //BAU Changes  Added one field in the query --FlexUEID__c
            contact = [SELECT Id, AccountId, FirstName, LastName, Name, MobilePhone, Phone, Email, Primary_Client_Admin_Checkbox__c,FlexUEID__c
                             ,Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode, Account.BillingCountry, Account.BillingAddress
                             ,Account.LegalAddress__Street__s, Account.LegalAddress__City__s, Account.LegalAddress__StateCode__s, Account.LegalAddress__PostalCode__s
                             ,Account.LegalAddress__CountryCode__s, Account.LegalAddress__c
                             ,Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry, Account.ShippingAddress
                             ,Account.Name, Account.Federal_ID_Number__c, Account.Paychex_CEID__c, Account.Paychex_CAID__c 
                         FROM Contact WHERE Id =:contactId LIMIT 1];
            isResend = String.isNotBlank(contact.FlexUEID__c);
            if (contact.FlexUEID__c == null) {
               //contact.Email ='';
               //contact.MobilePhone ='';
            }
            // account for the different address fields that could be used. Legal is the main field. 
            String addrToUse = CsoQueueable.addrToUse(contact.Account);
            streetAdr = (String)contact.Account.get(CsoQueueable.checkFieldName('ShippingStreet', addrToUse));
            city = (String)contact.Account.get(CsoQueueable.checkFieldName('ShippingCity', addrToUse));
            stateProv = checkStateAbbr((String)contact.Account.get(CsoQueueable.checkFieldName('ShippingState', addrToUse)));
            postalCode = (String)contact.Account.get(CsoQueueable.checkFieldName('ShippingPostalCode', addrToUse));
            country = countryCodeAbbr((String)contact.Account.get(CsoQueueable.checkFieldName('ShippingCountry', addrToUse)));
            //stateProv = stateAbbr(contact.Account.BillingState);
            //country = countryCodeAbbr(contact.Account.BillingCountry);
        }
 
    } // setContact
    
    public PageReference submit() {
        Boolean isSuccess = false;
        // TODO - should be using this once we confirm it's being returned
        //if (String.isBlank(contact.FlexUEID__c)) {
        if (isResend == null || !isResend) {
            List<String> errorMessages = validateForm();
            
            if(!errorMessages.isEmpty()) {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Validation failed with the following errors:'));
                for(String error : errorMessages) {
                    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, error)); 
                }
            } else {
                contact.Account.BillingState = stateProv;
                contact.Account.BillingCountry = country;
                isSuccess = postCall();
                FlexNewClientOnboardingQueueable ncoQ = new FlexNewClientOnboardingQueueable(contact, contact.Account); //Call queueable to save the contact and account
                ncoQ.doDMLUpdate();
                //System.enqueueJob(ncoQ);
                if(isSuccess){
                    PageReference redirectPage = Page.FlexThankYouPage;
                    if(String.isNotBlank(opportunityId)){
                        redirectPage.getParameters().put('Id',opportunityId);
                    }else{
                        redirectPage.getParameters().put('Id',contact.Id);
                    }
                    redirectPage.setRedirect(true);
                    return redirectPage;
                }
            }
        } //end if(contact.Primary_Client_Admin...)
        else {
            // BAU Changes
            resendPostCall();//This method is created to resend the request to Flex system for email/phone updation
            FlexNewClientOnboardingQueueable ncoQ = new FlexNewClientOnboardingQueueable(contact, contact.Account); //Call queueable to save the contact and account
            // I don't believe we need a queueable here
            ncoQ.doDMLUpdate();
            //System.enqueueJob(ncoQ);
            //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'This contact has already been submitted to New Client Onboarding'));
        }
        return null;
        
    }//end submit()
    
    
   public Boolean postCall() {
      system.debug('start postCall'); 
      //Address stAddress = contact.Account.BillingAddress;
        
      if (cs == null || !cs.IsActive__c) {
         apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Service is inactive.  Please reach out to Salesforce Support'));
         return false;
      }
      Http http = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(cs.Endpoint__c);
      req.setClientCertificateName(cs.Certificate__c);
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json;charset=UTF-8');
      req.setHeader('X-payx-bizpn', 'Salesforce New Client Onboarding');
      req.setHeader('X-payx-user-untrusted', userHelper.getRunningUser().Email.subString(0, userHelper.getRunningUser().Email.indexOf('@')));
      req.setHeader('X-payx-cnsmr', 'Salesforce');
      req.setHeader('X-payx-txid', (String)contact.Id + Datetime.now().timeGmt());
      req.setTimeout(Integer.valueOf(cs.Timeout__c));
      //Map<String, String> phoneParts = formatPhone(contact.MobilePhone);
      StringHelper.parsePhone(contact.MobilePhone);

      JSONGenerator gen = JSON.createGenerator(false);
      gen.writeStartObject();
      gen.writeFieldName('client');
      gen.writeStartObject();
      gen.writeStringField('tinType','FEIN');
      gen.writeStringField('tin',EZOnboardingRegistration.formatFedId(contact.Account.Federal_ID_Number__c));
      gen.writeFieldName('legalAddress');

      EZOnboardingRegistration.addAddress(gen,null,streetAdr, city, stateProv, postalCode, country
                     ,'streetAddressOne','streetAddressTwo','','city','stateProv','postalCode','countryCode');
      //gen.writeStartObject();
      //gen.writeStringField('streetAddressOne',EZOnboardingRegistration.formatAddress(contact.Account.BillingStreet));
      //gen.writeStringField('city',EZOnboardingRegistration.formatName(contact.Account.BillingCity));
      //gen.writeStringField('stateProv',stateProv);
      //gen.writeStringField('postalcode',EZOnboardingRegistration.formatPostalCode(contact.Account.BillingPostalCode));
      //gen.writeStringField('countryCode',country);
      //gen.writeEndObject();
      gen.writeStringField('legalName',EZOnboardingRegistration.formatName(contact.Account.Name));
      gen.writeFieldName('user');
      gen.writeStartObject();
      gen.writeStringField('contactId',contact.Id);
      gen.writeStringField('email',contact.Email);
      gen.writeStringField('firstName',EZOnboardingRegistration.formatName(contact.FirstName));
      gen.writeStringField('lastName',EZOnboardingRegistration.formatName(contact.LastName));
      gen.writeFieldName('telephone');
      gen.writeStartObject();
      gen.writeStringField('areaCode',StringHelper.phoneArea);
      gen.writeStringField('number',StringHelper.phoneTele);
      gen.writeStringField('ext',StringHelper.phoneExt);
      gen.writeEndObject();
      gen.writeEndObject();
      gen.writeEndObject();
      gen.writeEndObject();
      req.setBody(gen.getAsString());
       /*
        req.setBody('{'
                    +   '"client": {'
                    +     '"tinType": "FEIN",'
                    +     '"tin": "' + EZOnboardingRegistration.formatFedId(contact.Account.Federal_ID_Number__c) + '",'
                    +     '"legalAddress": {'
                    +       '"streetAddressOne": "' + EZOnboardingRegistration.formatAddress(contact.Account.BillingStreet)+ '",' // .replaceAll('[^A-Za-z0-9\\&\\/#\\%\\- ]', '') + '",'
                    //+       '"streetAddressTwo": "",'
                    +       '"city": "' + EZOnboardingRegistration.formatName(contact.Account.BillingCity) + '",'
                    +       '"stateProv": "' + stateProv + '",'
                    +       '"postalcode": "' + EZOnboardingRegistration.formatPostalCode(contact.Account.BillingPostalCode) + '",'
                    +       '"countryCode": "' + country
                    +     '"},'
                    +     '"legalName": "' + cleanupAccountName(contact.Account.Name) + '",'
                    +     '"user": {'
                    +       '"contactId": "' + (String)contact.Id + '",'
                    +       '"email": "' + (String)contact.Email + '",'
                    +       '"firstName": "' + EZOnboardingRegistration.formatName(contact.FirstName) + '",'
                    +       '"lastName": "' + EZOnboardingRegistration.formatName(contact.LastName) + '",'
                    +       '"telephone": {'
                    +         '"areaCode": "' + StringHelper.phoneArea + '",'
                    +         '"number": "' + StringHelper.phoneTele + '",'
                    +         '"ext": "' + StringHelper.phoneExt + '"' //inline conditional to see if size of map is 3, add ext. Otherwise don't.
                    +       '}'
                    +     '}'
                    +   '}'
                    + '}');
          */
      system.debug('req is: ' + req); 
      HttpResponse response = http.send(req);
        //if(!Test.isRunningTest()) {
            //response = http.send(req);
         /*
        }
        else {
            response = new HttpResponse();
            if(contact.Name == 'Test Test') {
                //Simulate failed test
                response.setStatus('400');
                response.setStatusCode(400);
                response.setBody('{"content":[],"errors":[{"code":"API-CLIENTADD105","description":"Partial match. Clt Add Exists - Tin Match Only. New client was not created.","resolution":"0030g00002KbcXqAAJ12:04:21.551Z"}]}');
            }
            else {
                response.setStatus('200');
                response.setStatusCode(200);
                response.setBody('{"content":[{"client":{"ttesinType":"FEIN","tin":"476845124","legalName":"Testing Account 1","legalAddress":{"streetAddressOne":"844 Testing Lane","city":"Rochester","stateProv":"NY","postalcode":"12584","countryCode":"US"},"ceid":"00DCE1NVK2BVUZ8ZE09Y","caid":"00DCE1NVK2BVUZFHE1EQ","assignedName":"NYA160","user":{"contactId":"0030g00002MdkNsAAJ","email":"testingEmail12321@gmai1.com","firstName":"Joe","lastName":"Shmo","telephone":{"areaCode":"778","number":"8541205"},"guid":"00DCE1NVK2B5FX75DXKV"},"cltPeo":false}}]}');
            }
        }
           */ 
      System.debug('Response body: ' + response.getBody());
            //String envName = Utilities.checkForProduction();
            //System.debug('*****IS SANDBOX '+envName);
            
            //if(String.isNotBlank(envName) && envName.equalsIgnoreCase('CSO')) {
            //    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, !string.isBlank(response.getStatus()) ? response.getStatus(): 'no status returned'));
            //    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, String.valueOf(response.getStatusCode())));
            //    apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO, response.getBody()));
            //}
            
      boolean responseSuccess = handleResponse(response.getBody(), req.getBody());
            
      if (responseSuccess) {
         apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'The FLEX Online Account Request was submitted successfully'));
         return true;
      }
      return false;
   } //END postCall()
    
    
    public boolean handleResponse(String responseBody, String requestBody) {
        EZOnboardingRegistration.EntResponse entResp = EZOnboardingRegistration.parseResponse(responseBody);
        /*
        JSONParser parser = JSON.createParser(responseBody);
        String error;
        String errorDesc;
        
        String ceid;
        String caid;
        // BAU Changes
        String guid;
        // BAU Changes
        
        */
        System.debug('RESPONSE BODY: ' + responseBody);
        Map<String, errorWrapper> errorMap = new Map<String, errorWrapper>();
        for(NCOError__c cs : NCOError__c.getall().values()) {
            errorMap.put(cs.Code__c, new errorWrapper(cs.Code__c, cs.Description__c, cs.Description2__c, cs.Message_Type__c, cs.Print_Error__c));
        }
        /*
        while (parser.nextToken() != null) {
            String tokenName = parser.getCurrentName();
            if (tokenName == 'description') {
               errorDesc = parser.getText();
            } else if (tokenName == 'code') {
               error = parser.getText();
            } else if (tokenName == 'ceid') {
               ceid = parser.getText();
            } else if (tokenName == 'caid') {
               caid = parser.getText();
            } else if (tokenName == 'guid') {
               guid = parser.getText();
            }
            parser.nextToken();
        } //  while (parser.nextToken()
        */
        Boolean success = String.isBlank(entResp.errCode);
        
        System.debug('Testing NCO Final success='+success+' ceid='+entResp.ceid+' caid='+entResp.caid);
        if (success) {
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'The FLEX Online Account Request was submitted successfully'));
            contact.Primary_Client_Admin_Checkbox__c = true;
            contact.MobilePhone = contact.Phone;
            // BAU Changes
            if(String.isNotBlank(entResp.userGuid)) {
                contact.FlexUEID__c=entResp.userGuid;
            }
            
            if(entResp.ceid != null) contact.Account.Paychex_CEID__c = entResp.ceid;
            if(entResp.caid != null) contact.Account.Paychex_CAID__c = entResp.caid;
        } else {
            errorWrapper err = errorMap.get(entResp.errCode);
            
            ApexPages.Severity sev = (err.errType == 'CONFIRM' ? Apexpages.Severity.CONFIRM 
                                         : (err.errType == 'WARNING' ? Apexpages.Severity.WARNING : Apexpages.Severity.ERROR));
            apexPages.addMessage(new ApexPages.message(sev, err.desc1 + ' ' + err.desc2));
            if (err.printErr) {
               apexPages.addMessage(new ApexPages.message(sev, 'Error: ' + entResp.errCode));
               apexPages.addMessage(new ApexPages.message(sev, 'Description: ' + entResp.errDesc));
            }
            /*
            if(err.errType == 'CONFIRM') {
                apexPages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, err.desc1 + ' ' + err.desc2));
                if(err.printErr) {
                    apexPages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Error: ' + entResp.errCode));
                    apexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, 'Description: ' + entResp.errDesc));
                }
             
            }
            else if(err.errType == 'WARNING') {
                apexPages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING, err.desc1 + ' ' + err.desc2));
                if(err.printErr) {
                    apexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Error: ' + entResp.errDesc));
                }
            }
            else {
                apexPages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, err.desc1 + ' ' + err.desc2));
                if(err.printErr) {
                    apexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Error: ' + entResp.errDesc));
                }
            }
            */
            
        } // if (success
        
        createWebServiceLog(requestBody, success, String.isBlank(entResp.errCode) ? null : entResp.errCode + ' - ' + entResp.errDesc);
        
        return success;
    } //END handleResponse()
    
    
    public void createWebServiceLog(String requestBody, Boolean success, String errorMsg) {
        /*
        String infoDump = '';
        infoDump += 'tin:' + EZOnboardingRegistration.formatFedId(contact.Account.Federal_ID_Number__c) + ';';
        infoDump += 'streetAddressOne:' + EZOnboardingRegistration.formatAddress(contact.Account.BillingStreet) + ';';
        infoDump += 'city:' + EZOnboardingRegistration.formatName(contact.Account.BillingCity) + ';';
        infoDump += 'stateProv:' + stateProv + ';';
        infoDump += 'postalcode:' + EZOnboardingRegistration.formatPostalCode(contact.Account.BillingPostalCode) + ';';
        infoDump += 'countryCode:' + country + ';';
        infoDump += 'legalName:' + cleanupAccountName(contact.Account.Name) + ';';
        infoDump += 'contactId:' + (String)contact.Id + ';';
        infoDump += 'email:' + (String)contact.Email + ';';
        infoDump += 'firstName:' + (String)contact.FirstName + ';';
        infoDump += 'lastName:' + (String)contact.LastName + ';';

        infoDump += 'areaCode:' + StringHelper.phoneArea+ ';';
        infoDump += 'number:' + StringHelper.phoneTele + ';';
        infoDump += 'ext:' + StringHelper.phoneExt;
        */
        
        //logServiceCall(String serviceName, Boolean isSuccess, String errorMsg, String notes)
        
        Web_Service_Log__c wsl = WebServicesHelper.logServiceCall('Flex New Client Onboarding', success, errorMsg, requestBody);
        
    } // createWebServiceLog
    
    public List<String> validateForm() {
        
        List<String> errorMessage = new List<String>();
        
        //Illegal Character in Name
        /*
        if(!contact.Account.Name.containsOnly('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&- ')) {
            errorMessage.add('Illegal Character in Account Name\n');
        }
        */
        
        //Name is too short or too long
        if(!(contact.Account.Name.length() > 0 && contact.Account.Name.length() < 81)) {
            errorMessage.add('Account Name is too short or too long (max 80 chars)');
        }
        
        //Double space in Client name
        /*
        if(contact.Account.Name.contains('  ')) {
            errorMessage.add('Account Name contains a double space');
        }
        */
                
        //FEIN Missing
        if(String.isBlank(contact.Account.Federal_ID_Number__c)) {
            errorMessage.add('FEIN Missing');
        } else {
            //FEIN invalid length
            if((contact.Account.Federal_ID_Number__c.contains('-') && contact.Account.Federal_ID_Number__c.length() != 10) || (contact.Account.Federal_ID_Number__c.containsNone('-') && contact.Account.Federal_ID_Number__c.length() != 9)) {
                errorMessage.add('FEIN invalid length');
            }
            
            //FEIN Invalid Format
            if(!contact.Account.Federal_ID_Number__c.containsOnly('0123456789-')) {
                errorMessage.add('FEIN Invalid Format');
            }
            
            //FEIN Invalid Prefix
            List<String> prefixes = new List<String> {'00', '07', '08', '09', '17', '18', '19', '28', '29', '49', '78', '79', '89', '96', '97'};
            if(contact.Account.Federal_ID_Number__c.length() > 2) {
                if(prefixes.contains(contact.Account.Federal_ID_Number__c.substring(0,2))) {
                    errorMessage.add('FEIN Invalid Prefix');
                }
            }
            
            //FIEN Suspicious Sequence
            if(contact.Account.Federal_ID_Number__c == '999999999') {
                //Make sure it does not == 999999999
                errorMessage.add('FEIN Suspicious Sequence');
            }
        }//else
        
        //State/Province not recognized
        if(!stateMap.values().contains(stateProv) && !provinceMap.values().contains(stateProv)) {
            errorMessage.add('State/Province not recognized');
        }
        
        //Country not recognized
        List<String> countryVariationList = new List<String>{'UNITED STATES', 'US', 'USA', 'CANADA', 'CA'};
        if(!countryVariationList.contains(country)) {
            errorMessage.add('Country not recognized');
        }

        //Postal Code does not match country code
        if(stateMap.values().contains(stateProv) && (countryCodeAbbr(country) != 'US')) {
            errorMessage.add('Postal Code does not match country code');
        }
        
        //Postal Code does not match country code
        if(provinceMap.values().contains(stateProv) && (countryCodeAbbr(country) != 'CA')) {
            errorMessage.add('Postal Code does not match country code');
        }
        
        //Postal Code Missing
        if(String.isBlank(postalCode)) {
            errorMessage.add('Billing Zip/Postal Code Missing');
        } else {
            //Invalid characters in Postal Code
            if(!contact.Account.BillingPostalCode.containsOnly('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-')) {
                errorMessage.add('Invalid characters in Postal Code. Postal code should only contains letters, numbers, and the \'-\' symbol.');
            }
        }
        
        //Billing Street Missing
        if(String.isBlank(streetAdr)) {
            errorMessage.add('Billing Street Missing');
        }
        else {
            //Invalid characters in legal street address
            if(!streetAdr.containsOnly('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789&/#%-., ')) {
                errorMessage.add('Invalid characters in Address. Address should only contain letters of the alphabet, numbers, and the following special characters: \'&\', \'/\', \'#\', \'%\', \'-\'. No double space allowed.');
            }
            
            //Double space in legal street address
            if(streetAdr.contains('  ')) {
               errorMessage.add('Double space in legal street address');
            }
        }
        
        //Billing City Missing
        if(String.isBlank(city)) {
            errorMessage.add('Billing City missing');
        } else {
            //Double space in legal street city
            if(contact.Account.BillingCity.contains('  ')) {
                errorMessage.add('Double space in legal street city');
            }
        }
        
        //First Name is too short or too long
        if(String.isBlank(contact.FirstName) || contact.FirstName.length() > 30) {
            errorMessage.add('First Name is too short or too long (max 30 chars)');
        }
        
        //Last Name is too short or too long
        if(String.isBlank(contact.LastName) || contact.LastName.length() > 30) {
            errorMessage.add('Last Name is too short or too long (max 30 chars)');
        }
        
        //User Email is too short or too long
        if(String.isBlank(contact.Email) || contact.Email.length() > 250) {
            errorMessage.add('User Email is too short or too long');
        } else {
            //User Email invalid format
            if(!contact.Email.contains('@')) {
                errorMessage.add('User Email invalid format');
            }
        }
        
        if(String.isBlank(contact.MobilePhone)) {
            errorMessage.add('Mobile Phone Missing');
        } else {
            //Invalid characters in User Phone Number
            if(!contact.MobilePhone.containsOnly('0123456789-()xX ')) {
                errorMessage.add('Invalid characters in User Phone Number. Phone number can only contain numbers, the letter X, and the following special characters: \'(\', \')\', and \'-\'.');
            }
            //User Phone Number too short or too long
            if(String.isBlank(contact.MobilePhone) || contact.MobilePhone.replaceAll('[^+xX0-9]','').length() < 10) {
                errorMessage.add('User Phone Number too short or too long');
            }
        }
        
        return errorMessage;
    } // validateForm
    
    
    /**
* Take a full phone number and filter out the area code, main phone number, and extension if available
* returns a map of size 2 or 3 depending on whether there was an extension on the phone number
**/
    /*
    public Map<String, String> formatPhone(String phone) {
        Map<String, String> phoneParts = new Map<String, String>();
        String regEx = '[^+xX0-9]'; //A regEx to strip the phone number of all characters aside from +, x, and X
        
        phone = phone.replaceAll(regEx, '');
        if(phone.contains('+')) {
            phone = phone.substring(2);
        }
        
        phoneParts.put('areaCode', phone.substring(0,3));
        if(phone.contains('x')) {
            phoneParts.put('ext', phone.substringAfter('x'));
        }
        if(phone.contains('X')) {
            phoneParts.put('ext', phone.substringAfter('X'));
        }
        phoneParts.put('phone', phone.substring(3,phone.length()));
        
        return phoneParts;
    }
     */
    /*
    public String cleanupAccountName(String accountName) {
        accountName = accountName.replaceAll('[^-A-Za-z0-9\\& ]', '');
        accountName = accountName.replace('  ', ' ');
        
        return accountName;
    }
    */
    
    public String checkStateAbbr(String checkState) {
       if (String.isBlank(checkState)) {
          return 'NY';
       } else if (checkState.length() ==2 ) {
          return checkState.toUpperCase();
       }
       if (stateMap.containsKey(checkState)) {
          return stateMap.get(checkState);
       }
       if (provinceMap.containsKey(checkState)) {
          return provinceMap.get(checkState);
       }
       // in case the states aren't entered to match the key format
       String retVal = checkMap(checkState,stateMap);
       if (retVal == null) {
          retVal = checkMap(checkState,provinceMap);
       }
       return retVal;
    } // checkStateAbbr
    
    public String checkMap(String checkState, Map<String,String> checkMap) {
       String checkStateUp = checkState.toUpperCase();
       for (String key : checkMap.keySet()) {
          if (checkStateUp == key.toUpperCase()) {
             String retVal = checkMap.get(key);
             return retVal;
          }
       }
       return null;
    } // checkUpperCase
    /*
    public String stateAbbr(String inState) {
        if(inState == null) return 'New York';
        
        if(inState.length() == 2) return inState.toUpperCase();
        
        switch on inState.toUpperCase() {
            when 'ALABAMA' {
                return 'AL';
            }
            when 'ALASKA' {
                return 'AK';
            }
            when 'ARIZONA' {
                return 'AZ';
            }
            when 'ARKANSAS' {
                return 'AR';
            }
            when 'CALIFORNIA' {
                return 'CA';
            }
            when 'COLORADO' {
                return 'CO';
            }
            when 'CONNECTICUT' {
                return 'CT';
            }
            when 'DELAWARE' {
                return 'DE';
            }
            when 'FLORIDA' {
                return 'FL';
            }
            when 'GEORGIA' {
                return 'GA';
            }
            when 'HAWAII' {
                return 'HI';
            }
            when 'IDAHO' {
                return 'ID';
            }
            when 'ILLINOIS' {
                return 'IL';
            }
            when 'INDIANA' {
                return 'IN';
            }
            when 'IOWA' {
                return 'IA';
            }
            when 'KANSAS' {
                return 'KS';
            }
            when 'KENTUCKY' {
                return 'KY';
            }
            when 'LOUISIANA' {
                return 'LA';
            }
            when 'MAINE' {
                return 'ME';
            }
            when 'MARSHALL ISLANDS' {
                return 'MH';
            }
            when 'MARYLAND' {
                return 'MD';
            }
            when 'MASSACHUSETTS' {
                return 'MA';
            }
            when 'MICHIGAN' {
                return 'MI';
            }
            when 'MINNESOTA' {
                return 'MN';
            }
            when 'MISSISSIPPI' {
                return 'MS';
            }
            when 'MISSOURI' {
                return 'MO';
            }
            when 'MONTANA' {
                return 'MT';
            }
            when 'NEBRASKA' {
                return 'NE';
            }
            when 'NEVADA' {
                return 'NV';
            }
            when 'NEW HAMPSHIRE' {
                return 'NH';
            }
            when 'NEW JERSEY' {
                return 'NJ';
            }
            when 'NEW MEXICO' {
                return 'NM';
            }
            when 'NEW YORK' {
                return 'NY';
            }
            when 'NORTH CAROLINA' {
                return 'NC';
            }
            when 'NORTH DAKOTA' {
                return 'ND';
            }
            when 'OHIO' {
                return 'OH';
            }
            when 'OKLAHOMA' {
                return 'OK';
            }
            when 'OREGON' {
                return 'OR';
            }
            when 'PENNSYLVANIA' {
                return 'PA';
            }
            WHEN 'PUERTO RICO' {
                return 'PR';
            }
            when 'RHODE ISLAND' {
                return 'RI';
            }
            when 'SOUTH CAROLINA' {
                return 'SC';
            }
            when 'SOUTH DAKOTA' {
                return 'SD';
            }
            when 'TENNESSEE' {
                return 'TN';
            }
            when 'TEXAS' {
                return 'TX';
            }
            when 'UTAH' {
                return 'UT';
            }
            when 'VERMONT' {
                return 'VT';
            }
            when 'VIRGINIA' {
                return 'VA';
            }
            when 'WASHINGTON' {
                return 'WA';
            }
            when 'WASHINGTON DC' {
                return 'DC';
            }
            when 'D.C.' {
                return 'DC';
            }
            when 'WEST VIRGINIA' {
                return 'WV';
            }
            when 'WISCONSIN' {
                return 'WI';
            }
            when 'WYOMING' {
                return 'WY';
            }
            when 'VIRGIN ISLANDS' {
                return 'VI';
            }
            when 'ALBERTA' {
                return 'AB';
            }
            when 'BRITISH COLUMBIA' {
                return 'BC';
            }
            when 'MANITOBA' {
                return 'MB';
            }
            when 'NEW BRUNSWICK' {
                return 'NB';
            }
            when 'NEWFOUNDLAND' {
                return 'NL';
            }
            when 'LABRADOR' {
                return 'NL';
            }
            when 'NORTHWEST TERRITORIES' {
                return 'NT';
            }
            when 'NOVA SCOTIA' {
                return 'NS';
            }
            when 'NUNAVUT' {
                return 'NU';
            }
            when 'ONTARIO' {
                return 'ON';
            }
            when 'PRINCE EDWARD ISLAND' {
                return 'PE';
            }
            when 'QUEBEC' {
                return 'QC';
            }
            when 'SASKATCHEWAN' {
                return 'SK';
            }
            when 'YUKON' {
                return 'YT';
            }
            when else {
                return null;
            }
        }
    } // stateAbbr
    */
    public String countryCodeAbbr(String inCountry) {
        if(inCountry == null) return 'US';
        if(inCountry.length() == 2) return inCountry;
        if(inCountry.toUpperCase() == 'UNITED STATES') return 'US';
        if(inCountry.toUpperCase() == 'USA') return 'US';
        if(inCountry.toUpperCase() == 'CANADA') return 'CA';
        
        return null;
    } // countryCodeAbbr  
    
    
    public class errorWrapper {
        
        String errCode;
        String desc1;
        String desc2;
        String errType;
        Boolean printErr;
        
        public errorWrapper(String errorCode, String description, String description2, String errorType, Boolean printError) {
            errCode = errorCode;
            desc1 = description;
            desc2 = description2 == null ? '' : description2;
            errType = errorType;
            printErr = printError;
            
        }
    }
       
    /**BAU Changes**/
    public void resendPostCall() {
        //Map<String, String> phoneParts = formatPhone(contact.MobilePhone);
        // system.debug('MA1:ueid'+contact.FlexUEID__c);
        // system.debug('MA1:email'+(String)contact.Email);
        // system.debug('MA1:phoneNumber'+phoneParts.get('phone'));
        // system.debug('MA1:phoneAreaCode'+phoneParts.get('areaCode'));
        cs1= WebServiceSettings__c.getInstance('NewClientOnboardingUpdation');
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        // req.setEndpoint('https://service-inbound-pyx-n1.paychex.com/rest/onboarding-svc/onboarding/client/user/resendRegistrationLink');//Endpoint change
        req.setEndpoint(cs1.Endpoint__c);
        req.setClientCertificateName(cs1.Certificate__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setTimeout(Integer.valueOf(cs.Timeout__c));

        //Sample Request JSON BODY
        // String reqBody='{'+'"ueid":"00JWDGDYL47177HRJLT5",'+'"email":"bosco6.smartinis@gmail.com",'+'"phoneNumber": "3810257",'+'"phoneAreaCode":"125"'+'}';
        // req.setBody(reqBody);
        StringHelper.parsePhone(contact.MobilePhone);
        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartObject();
        gen.writeStringField('ueid',contact.FlexUEID__c);
        gen.writeStringField('email',contact.Email);
        gen.writeStringField('phoneNumber',StringHelper.phoneTele);
        gen.writeStringField('phoneAreaCode',+StringHelper.phoneArea);
        gen.writeEndObject();

        //String reqBody='{'+'"ueid":"'+contact.FlexUEID__c+'",'+'"email":"'+(String)contact.Email+'",'+'"phoneNumber":"'+StringHelper.phoneTele+'",'+'"phoneAreaCode":"'+StringHelper.phoneArea+'"'+'}';
        String reqBody = gen.getAsString();
        system.debug('resendPostCall reqBody='+reqBody);
        req.setBody(reqBody);

        HttpResponse response=http.send(req);
        system.debug('resendPostCall response='+response);
        EZOnboardingRegistration.EntResponse entResp = EZOnboardingRegistration.parseResponse(response.getBody());
        updateCSO(response.getStatusCode()==200, entResp.errCode, entResp.errDesc);

        // System.debug('MA Response body: ' + response.getBody());	
        // System.debug('MA Response body1: ' + response.getStatusCode());	
        if(response.getStatusCode()==200){
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM,'The Flex User Registration Request was successfully resent! Any additional client login assistance is available by using the *?* button on the Flex Login Page'));
        } else {
            handleUpdateRequest(entResp.errCode);
        }
    }//End resendPostCall

    public void handleUpdateRequest(String responseCode){
        /*
        String responseCode=null;
        JSONParser parser = JSON.createParser(responseBody);
        while(parser.nextToken() != null) {
            if(parser.getText() == 'code') {
                // system.debug('MA1:'+parser.getText());
                parser.nextToken();
                responseCode = parser.getText();
            }
        } 
        */
        if(responseCode=='API-RESENDUSER202-USERNOTSTAGED' || responseCode=='API-RESENDUSER203-ACCOUNTLOCKED'){
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.WARNING,'Flex User Registration has been completed. Client login assistance is available on the Flex login page by using the *?*. If the client needs to make changes that they are unable to make within Flex,Please contact their Payroll Specialist.'));
        }
        else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,'The request to resend the Flex User Registration was not successfully sent. If a client needs help editing an unregistered Flex user account,Please contact their Payroll Specialist.'));
        }
    }

    /**BAU Changes**/

    public void updateCSO(Boolean isSuccess, String code, String errorDesc){
        if (contact!=null) {
            CSO_Tracking__c[] csoRecs = [Select ID,UserRegistrationResent__c, UserRegistrationResentDate__c, CsoResponse__c, ProcessNotes__c from CSO_Tracking__c where AccountId__c =:contact.AccountId order by CreatedDate desc];
            CSO_Tracking__c csoRec = (!csoRecs.isEmpty() ? csoRecs[0] : null);
            System.debug('updateCSO csoRec='+(csoRec != null));
            if (csoRec!=null) {
                csoRec.UserRegistrationResent__c = (csoRec.UserRegistrationResent__c != null ? csoRec.UserRegistrationResent__c : 0) + 1;
                csoRec.UserRegistrationResentDate__c = Datetime.now();
                String msg = (isSuccess ? 'Resent User Registration email='+contact.Email+' phone='+contact.MobilePhone : 'Resend failed: '+code+'; '+errorDesc);
                StringHelper.addToProcessNotes(csoRec,msg);
                CsoMethods.SKIP_TRIGGERS = true;
                update csoRec;
            }  
        }  // if (contact!=null 
    } // updateCSO
    
   public PageReference cancel() {
        PageReference returnPr = null;
        try {
           String returnId = (opportunityId != null ? opportunityId : contactId);
           returnPr = new PageReference('/'+(returnId != null ? returnId : ''));
        } catch (Exception e) {
                // in case returnId isn't a valid id.
           returnPr = new PageReference('/');
        }
      returnPr.setRedirect(true);             
      return returnPr;
   } // cancel
 
} // class FlexNewClientOnboardingController