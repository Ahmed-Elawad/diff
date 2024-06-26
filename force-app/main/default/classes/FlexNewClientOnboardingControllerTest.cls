/** 
 *
 * History
 * -------
   10/25/2022   Dan Carmen      Additional changes for CSO/Enterprise registraion
   03/13/2024   Dan Carmen      Change to use label.Certificate_Name for the Certificate.

*/
@isTest
public class FlexNewClientOnboardingControllerTest {
    
    @testSetup
    public static void testSetupMethod(){
        if(String.isBlank(Utilities.checkForProduction())) {
            insert new WebServiceSettings__c(Name='NewClientOnboarding',IsActive__c=true,Certificate__c=label.Certificate_Name,
                                         Endpoint__c='https://webservicesn2a.paychex.com/rest/onboarding-svc/client/user',
                                         Timeout__c='40000');
        } else {
    		insert new WebServiceSettings__c(Name='NewClientOnboarding',IsActive__c=true,Certificate__c=label.Certificate_Name,
                                         Endpoint__c='https://webservicesn2a.paychex.com/rest/onboarding-svc/client/user',
                                         Timeout__c='40000');
        }
        insert new WebServiceSettings__c(Name='NewClientOnboardingUpdation',IsActive__c=true,Certificate__c=label.Certificate_Name,
                                         Endpoint__c='https://webservicesn2a.paychex.com/rest/onboarding-svc/client/user',
                                         Timeout__c='40000');
    } // testSetupMethod
    
    public static testMethod void testNormal() {
        Account acc = new Account();
        acc.Federal_ID_Number__c = '476845124';
        acc.BillingStreet = '844 Testing Lane';
        acc.BillingCity = 'Rochtester';
        acc.BillingState = 'Alabama';
        acc.BillingPostalCode = '12584';
        acc.BillingCountry = 'United States';
        acc.Name = 'Testing Account 1';
        insert acc;
        
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Email = 'testingEmail12321@gmai1.com';
        con.LastName = 'Shmo';
        con.FirstName = 'Joe';
        con.MobilePhone = '(778) 854-1205';
        con.Primary_Client_Admin_Checkbox__c = false;
        insert con;
        
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FlexNewClientOnboardingMock(true));
        
        PageReference pageRef = Page.FlexNewClientOnboarding;
        pageRef.getParameters().put('id', String.valueof(con.Id));
        Test.setCurrentPage(pageRef);
        
        FlexNewClientOnboardingController testNCO = new FlexNewClientOnboardingController();
        testNCO.contact.Email ='testingEmail12321@gmai1.com';
        testNCO.contact.MobilePhone ='(778) 854-1205';
        testNCO.submit();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.debug('MAK - FlexNewClientOnboardingControllerTest - testNormal() - pageMessages: ' + pageMessages);
        //ApexPages.Message message = !String.isBlank(Utilities.checkForProduction()) ? pageMessages[2] : pageMessages[0];
        ApexPages.Message message = pageMessages[0];
        System.debug('MAK - FlexNewClientOnboardingControllerTest - testNormal() - message: ' + message);
        System.assert(message.getSummary() == 'The FLEX Online Account Request was submitted successfully');
        
        Test.StopTest();
        
        System.assertEquals('Flex Online Account Request',testNCO.pageTitle);
        System.assertEquals('Submit New Client Request',testNCO.buttonTitle);
        testNCO.cancel();
    } // testNormal
    
    
    public static testMethod void testServerError() {
        
        NCOError__c ncoe = new NCOError__c(Code__c = 'API-CLIENTADD105',
                                          Description__c = 'We have found a match to an existing client account within Paychex system. The new client landing will not be available and the Admin user has not been created. Implementation will resolve this when completing the on-boarding of this client.',
                                          Description2__c = 'Please capture the admin user account details in the op0053 form as part of your client submission.',
                                          Message_Type__c = 'ERROR',
                                          Print_Error__c = true,
                                          Name = 'API-CLIENTADD105');
        insert ncoe;
        
        Account acc = new Account();
        acc.Federal_ID_Number__c = '476845124';
        acc.BillingStreet = '844 Testing Lane';
        acc.BillingCity = 'Rochtester';
        acc.BillingState = 'Alabama';
        acc.BillingPostalCode = '12584';
        acc.BillingCountry = 'United States';
        acc.Name = 'Testing Account 1';
        insert acc;
        
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Email = 'testingEmail12321@gmai1.com';
        con.LastName = 'Test';
        con.FirstName = 'Test';
        con.MobilePhone = '(778) 854-1205';
        con.Primary_Client_Admin_Checkbox__c = false;
        insert con;
        
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new FlexNewClientOnboardingMock(false));
        
        PageReference pageRef = Page.FlexNewClientOnboarding;
        pageRef.getParameters().put('id', String.valueof(con.Id));
        Test.setCurrentPage(pageRef);
        
        FlexNewClientOnboardingController testNCO = new FlexNewClientOnboardingController();
        testNCO.submit();
		
		ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assert(pageMessages.size() >= 1);
		        
        Test.StopTest();
        
    } // testServerError
    
    
    public static testMethod void testValidationError() {
        Account acc = new Account();
        acc.Federal_ID_Number__c = '09684512+444';
        acc.BillingStreet = '844 Tes^ting  Lane';
        acc.BillingCity = 'Rochtester  T';
        acc.BillingState = 'Alaboma';
        acc.BillingPostalCode = '125843(222';
        acc.BillingCountry = 'United Stotes';
        acc.Name = 'Testing Account 11111111111111111111111111111111111111111111111111111111111111111111';
        insert acc;
        
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Email = 'testingEmail12321@gmai1.com';
        con.LastName = 'Shmoooooooooooooooooooooooooooo';
        con.FirstName = 'Joeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
        con.MobilePhone = '+1 (778) 854-12055834 x23843';
        con.Primary_Client_Admin_Checkbox__c = false;
        insert con;
        
        Test.StartTest();
        
        PageReference pageRef = Page.FlexNewClientOnboarding;
        pageRef.getParameters().put('id', String.valueof(con.Id));
        Test.setCurrentPage(pageRef);
        
        FlexNewClientOnboardingController testNCO = new FlexNewClientOnboardingController();
        testNCO.submit();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assert(pageMessages.size() > 1);
        
        Test.StopTest();
        
    } // testValidationError
    
    
    // public static testMethod void testClientAdminTrue() {
    //     Account acc = new Account();
    //     acc.Federal_ID_Number__c = '476845124';
    //     acc.BillingStreet = '844 Testing Lane';
    //     acc.BillingCity = 'Rochtester';
    //     acc.BillingState = 'Alabama';
    //     acc.BillingPostalCode = '12584';
    //     acc.BillingCountry = 'United States';
    //     acc.Name = 'Testing Account 1';
    //     insert acc;
        
    //     Contact con = new Contact();
    //     con.AccountId = acc.Id;
    //     con.Email = 'testingEmail12321@gmai1.com';
    //     con.LastName = 'Shmo';
    //     con.FirstName = 'Joe';
    //     con.Phone = '(778) 854-1205';
    //     con.Primary_Client_Admin_Checkbox__c = true;
    //     insert con;
        
    //     Test.StartTest();
        
    //     PageReference pageRef = Page.FlexNewClientOnboarding;
    //     pageRef.getParameters().put('id', String.valueof(con.Id));
    //     Test.setCurrentPage(pageRef);
        
    //     FlexNewClientOnboardingController testNCO = new FlexNewClientOnboardingController();
    //     testNCO.submit();
        
    //     ApexPages.Message[] pageMessages = ApexPages.getMessages();
    //     System.assert(pageMessages[0].getSummary() == 'This contact has already been submitted to New Client Onboarding');
        
    //     Test.StopTest();
        
    // }

    
    public static testMethod void testAbbr() {
        FlexNewClientOnboardingController testNCO = new FlexNewClientOnboardingController();
        /*
        Map<String, String> stateMap = new Map<String, String>{'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ', 'Arkansas' => 'AR', 'California' => 'CA', 'Colorado' => 'CO', 'Connecticut' => 'CT', 'DC' => 'DC', 'Delaware' => 'DE', 'Florida' => 'FL', 'Georgia' => 'GA', 'Hawaii' => 'HI', 'Idaho' => 'ID', 'Illinois' => 'IL', 'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS', 'Kentucky' => 'KY', 'Louisiana' => 'LA', 'Maine' => 'ME', 'Maryland' => 'MD','Marshall Islands' => 'MH', 'Massachusetts' => 'MA', 'Michigan' => 'MI', 'Minnesota' => 'MN', 'Mississippi' => 'MS', 'Missouri' => 'MO', 'Montana' => 'MT', 'Nebraska' => 'NE', 'Nevada' => 'NV', 'New Hampshire' => 'NH', 'New Jersey' => 'NJ', 'New Mexico' => 'NM', 'New York' => 'NY', 'North Carolina' => 'NC', 'North Dakota' => 'ND', 'Ohio' => 'OH', 'Oklahoma' => 'OK', 'Oregon' => 'OR', 'Pennsylvania' => 'PA', 'Puerto Rico' => 'PR', 'Rhode Island' => 'RI', 'South Carolina' => 'SC', 'South Dakota' => 'SD', 'Tennessee' => 'TN', 'Texas' => 'TX', 'Utah' => 'UT', 'Vermont' => 'VT', 'Virginia' => 'VA', 'Virgin Islands' => 'VI', 'Washington' => 'WA', 'Washington DC' => 'DC', 'D.C.' => 'DC', 'West Virginia' => 'WV', 'Wisconsin' => 'WI', 'Wyoming' => 'WY'};
		Map<String, String> provinceMap = new Map<String, String>{'Alberta' => 'AB', 'British Columbia' => 'BC', 'Manitoba' => 'MB', 'New Brunswick' => 'NB', 'Newfoundland' => 'NL', 'Labrador' => 'NL', 'Northwest Territories' => 'NT', 'Nova Scotia' => 'NS', 'Nunavut' => 'NU', 'Ontario' => 'ON', 'Prince Edward Island' => 'PE', 'Quebec' => 'QC', 'Saskatchewan' => 'SK', 'Yukon' => 'YT'};
    	Map<String, String> countryMap = new Map<String, String>{'United States' => 'US', 'Canada' => 'CA'};
        
        
        Test.startTest();
        for(String state : stateMap.keySet()) {
            String abbr = testNCO.stateAbbr(state);
            System.assertEquals(stateMap.get(state), abbr);
        }
        
        for(String province : provinceMap.keySet()) {
            String abbr = testNCO.stateAbbr(province);
            System.assertEquals(provinceMap.get(province), abbr);
        }
        for(String country : countryMap.keySet()) {
            String abbr = testNCO.countryCodeAbbr(country);
            System.assertEquals(countryMap.get(country), abbr);
        }
        Test.stopTest();
        */
    } // testAbbr
    
    static testMethod void testResend() {
        Contact con = new Contact();
        con.Email = 'testingEmail12321@gmai1.com';
        con.LastName = 'Shmo';
        con.FirstName = 'Joe';
        con.MobilePhone = '(778) 854-1205';
        con.Primary_Client_Admin_Checkbox__c = false;
        con.FlexUEID__c='TestFlexUeid123';

        Test.setMock(HttpCalloutMock.class, new FlexNewClientOnboardingMock(true));
        FlexNewClientOnboardingController fnco = new FlexNewClientOnboardingController();
        fnco.contact = con;
        Test.startTest();
        fnco.resendPostCall();
        Test.stopTest();
    } // testResend
    
    static testMethod void testValidate() {
       Account acct = new Account(Name='Test Account');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
        
       Contact ctct = new Contact(AccountId=acct.Id, LastName='Swift');
       ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
       ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
       insert ctct;
        
       FlexNewClientOnboardingController flexCtrl = new FlexNewClientOnboardingController();
       flexCtrl.setContact(ctct.Id);
        
       String[] errors = flexCtrl.validateForm();
       System.assertEquals(true, errors.size() > 1);
           
    } // testValidate
    
} // class FlexNewClientOnboardingControllerTest