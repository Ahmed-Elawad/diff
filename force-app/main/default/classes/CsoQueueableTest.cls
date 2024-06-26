/** Test methods for the CsoMethod and CSOQueueable class
 *
 * History
 * -------
 * 07/12/2022 Jermaine Stukes	Created.
   10/25/2022   Dan Carmen      Additional changes for CSO/Enterprise registraion
   04/01/2023   Dan Carmen      Don't require user validation
   11/13/2023   Dan Carmen      Handle SSN for validation call

*/
@isTest
public class CsoQueueableTest {
    
    @testSetup
    public static void setupData() {
        CsoMethodTest.setupData();
        WebServiceSettings__c acctValidateWebServiceSetting = new WebServiceSettings__c(
            Name = 'CSO_Account_Validation'
            ,Certificate__c = Label.Test_Class_Certificate_Name
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,Endpoint__c = 'https://service-inbound-pyx-n0.paychex.com/cordgw/client/validate	'
        );
        WebServiceSettings__c userValidateWebServiceSetting = new WebServiceSettings__c(
            Name = 'CSO_User_Validation'
            ,Certificate__c = Label.Test_Class_Certificate_Name
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,Endpoint__c = 'https://service-inbound-pyx-n0.paychex.com/cordgw/user/validate	'
        );
        WebServiceSettings__c[] wssList = new WebServiceSettings__c[]{acctValidateWebServiceSetting,userValidateWebServiceSetting};
            insert wssList;
        //Add CSO_Field_Mapping__c
        CSO_Field_Mapping__c tin = new CSO_Field_Mapping__c(Name='tin',CSO_Name__c='tin', Field_API__c='Federal_ID_Number__c',InitialValidation__c=true,Order__c=2);
        CSO_Field_Mapping__c legalAddressStart = new CSO_Field_Mapping__c(Name='legalAddress1',CSO_Name__c='legalAddress', IsStartObject__c=true,InitialValidation__c=true,Order__c=3);
        CSO_Field_Mapping__c legalAddressEnd = new CSO_Field_Mapping__c(Name='legalAddress2',CSO_Name__c='legalAddress', IsEndObject__c=true,InitialValidation__c=true,Order__c=4);
        CSO_Field_Mapping__c email = new CSO_Field_Mapping__c(Name='email',CSO_Name__c='email', Field_API__c='Significant_Contact_Email__c',UserValidation__c=true,Order__c=1);
        CSO_Field_Mapping__c[] csoFields = new CSO_Field_Mapping__c[]{tin,legalAddressStart,legalAddressEnd,email};
            insert csoFields;
        //Add Errors
        //CSOErrorCodes__c CLIENT_CONSTRAINT = new CSOErrorCodes__c(Name='CLIENT-LIST-CONSTRAINT',Error_Code__c='CLIENT-LIST-CONSTRAINT',Error_Message__c='Legal Name must be populated on submission. Please update and re-submit.',Display_Message__c=true);
       	//insert CLIENT_CONSTRAINT;
        //Create Account and contacts
        //CreateTestData.createTestAandC();
        
        //CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        //CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        //Account acct1 = getAccount('Test Account1');
        //Id ctctId = acct1.Contacts[0].Id;
        //CreateTestData.createTestCoreOptys(acct1.Id, ctctId);
    } // setupData
    
    public static Account getAccount(String acctName) {
       Account acct1 = [Select Id, Name
                              ,(Select Id from Contacts)
                              ,Significant_Contact_Email__c
                              ,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry
                              ,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry
                              ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                              ,Federal_ID_Number__c 
                          from Account where Name=:acctName limit 1];
       return acct1;
    } // getAccount

    public static CSO_Tracking__c getTestTracker(Id opptyId) {
       String trackerQuery = CsoMethods.getQuery(CsoMethods.QUERY_CSO);
       trackerQuery += ' where Opportunity__c=:opptyId limit 1';
       CSO_Tracking__c[] trackers = Database.query(trackerQuery);
       return trackers[0];
       /*
       CSO_Tracking__c csoRec = [Select Id,Account_Eligible__c,AccountKnockout__c,ClientDataValidated__c,InitialValidationDetail__c
                                       ,Opportunity_Eligible__c,CsoResponse__c,User_Validated__c,ProductsValidated__c
                                       ,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c
                                       ,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c , CanUseCSO__c
                                   from CSO_Tracking__c 
                                  where Opportunity__c=:opptyId
                                 limit 1];       
       return csoRec;
       */
    } // getTestTracker

    
    Static testMethod void testOpportunityValidationSuccess(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        
        Account acct1 = getAccount('Test Account1');
        acct1.Federal_ID_Number__c = '11-2222222';
        update acct1;
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        CSO_Tracking__c csoRec = getTestTracker(opptyId);
        csoRec.User_Validated__c = true;
        csoRec.OpportunityFieldsValidated__c = true;
        csoRec.ProductsValidated__c = true;
        csoRec.AccountKnockout__c = false;
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CsoQueueableMock());
        update csoRec;
        //Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
        //csoMap.put(acct1.Id, csoRec);
        //csoMethods.sendToCSO(new Account[]{acct1},csoMap);
        CsoQueueable csoQue = new CsoQueueable();
        csoQue.addRecsToProcess(acct1,csoRec);
        CsoQueueable.checkLaunchQueueable(csoQue);
        test.stopTest();
        CSO_Tracking__c csoRec2 = getTestTracker(opptyId);
        System.assertEquals(true, csoRec2.Opportunity_Eligible__c);
        System.assertEquals(true, csoRec2.Account_Eligible__c);
    } // testOpportunityValidationSuccess
    
    Static testMethod void testClientValidationSuccess(){
        CsoQueueable.ALLOW_USER_VAL=true;
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        
        Account acct1 = getAccount('Test Account1');
        acct1.Federal_ID_Number__c = '11-2222222';
        update acct1;
        //test.startTest();
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        CSO_Tracking__c csoRec = getTestTracker(opptyId);
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CsoQueueableMock());
        CsoQueueable csoQue = new CsoQueueable();
        csoQue.addRecsToProcess(acct1,csoRec);
        CsoQueueable.checkLaunchQueueable(csoQue);
        test.stopTest();

        //Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
        //csoMap.put(acct1.Id, csoRec);
        //csoMethods.sendToCSO(new Account[]{acct1},csoMap);
        //test.stopTest();
        CSO_Tracking__c csoRec2 = getTestTracker(opptyId);
        System.assertEquals(true, csoRec2.ClientDataValidated__c);
        System.assertEquals(false, csoRec2.User_Validated__c);
        System.assertEquals(true, csoRec2.Account_Eligible__c);
        System.assertEquals(false, csoRec2.Opportunity_Eligible__c);
    } // testClientValidationSuccess
    
    Static testMethod void testClientValidationFailure(){
        CsoQueueable.ALLOW_USER_VAL=true;
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
 
        Account acct1 = getAccount('Test Account2');
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        CSO_Tracking__c csoRec = getTestTracker(opptyId);
        
        //Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
        //csoMap.put(acct1.Id, csoRec);
        //csoMethods.sendToCSO(new Account[]{acct1},csoMap);
        test.startTest();
        CsoQueueableMock cqm = new CsoQueueableMock();
        cqm.responseCode = 400;
        Test.setMock(HttpCalloutMock.class, cqm);
        CsoQueueable csoQue = new CsoQueueable();
        csoQue.addRecsToProcess(acct1,csoRec);
        CsoQueueable.checkLaunchQueueable(csoQue);
        test.stopTest();
        
        CSO_Tracking__c csoRec2 = [Select Id,Account_Eligible__c,ClientDataValidated__c,InitialValidationDetail__c,Opportunity_Eligible__c,CsoResponse__c,User_Validated__c,ProductsValidated__c,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId limit 1];
        System.assertEquals(false, csoRec2.ClientDataValidated__c);
        System.assertEquals(false, csoRec2.User_Validated__c);
        System.assertEquals(false, csoRec2.Account_Eligible__c);
    } // testClientValidationFailure
    
    Static testMethod void testUserValidationSuccess(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;

        Account acct1 = getAccount('Test Account1');
        //test.startTest();
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        CSO_Tracking__c csoRec = getTestTracker(opptyId);
        csoRec.ClientDataValidated__c = true;
        csoRec.OpportunityFieldsValidated__c = true;
        csoRec.ProductsValidated__c = true;
        csoRec.AccountKnockout__c = false;
        update csoRec;
        //Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
        //csoMap.put(acct1.Id, csoRec);
        //csoMethods.sendToCSO(new Account[]{acct1},csoMap);
        //test.stopTest();
        
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new CsoQueueableMock());
        CsoQueueable csoQue = new CsoQueueable();
        csoQue.addRecsToProcess(acct1,csoRec);
        CsoQueueable.checkLaunchQueueable(csoQue);
        test.stopTest();

        CSO_Tracking__c csoRec2 = [Select Id,Account_Eligible__c,AccountKnockout__c,ClientDataValidated__c,InitialValidationDetail__c,Opportunity_Eligible__c,CsoResponse__c,User_Validated__c,ProductsValidated__c,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId limit 1];
        System.assertEquals(true, csoRec2.User_Validated__c);
        System.assertEquals(true, csoRec2.Account_Eligible__c);
    } // testUserValidationSuccess
    
    Static testMethod void testUserValidationFailure(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;

        Account acct1 = getAccount('Test Account2');
        //test.startTest();
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        CSO_Tracking__c csoRec = getTestTracker(opptyId);
        csoRec.ClientDataValidated__c = true;
        csoRec.OpportunityFieldsValidated__c = true;
        csoRec.ProductsValidated__c = true;
        update csoRec;
        //Map<Id, CSO_Tracking__c> csoMap = new Map<Id, CSO_Tracking__c>();
        //csoMap.put(acct1.Id, csoRec);
        //csoMethods.sendToCSO(new Account[]{acct1},csoMap);

        test.startTest();
        CsoQueueableMock cqm = new CsoQueueableMock();
        cqm.responseCode = 400;
        Test.setMock(HttpCalloutMock.class, cqm);
        CsoQueueable csoQue = new CsoQueueable();
        csoQue.addRecsToProcess(acct1,csoRec);
        CsoQueueable.checkLaunchQueueable(csoQue);
        test.stopTest();

        CSO_Tracking__c csoRec2 = [Select Id,Account_Eligible__c,ClientDataValidated__c,InitialValidationDetail__c,Opportunity_Eligible__c,CsoResponse__c,User_Validated__c,ProductsValidated__c,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId limit 1];
        System.assertEquals(false, csoRec2.User_Validated__c);
        System.assertEquals(false, csoRec2.Account_Eligible__c);
    } // testUserValidationFailure
    
    static testMethod void testSetAcctFldMap() {
       Account acct1 = new Account(Name='Account1', ShippingStreet='123 Shipping St', ShippingCity='ShippingCity', ShippingState='NY', ShippingPostalCode='11111', ShippingCountry='US');
       Account acct2 = new Account(Name='Account2', BillingStreet='123 Billing St', BillingCity='BillingCity', BillingState='MA', BillingPostalCode='22222',BillingCountry='US');
       Account acct3 = new Account(Name='Account3', LegalAddress__Street__s='123 Legal St', LegalAddress__City__s='LegalCity', LegalAddress__StateCode__s='VT', LegalAddress__PostalCode__s='33333', LegalAddress__CountryCode__s='US');
       CSO_Tracking__c cso = new CSO_Tracking__c();
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(acct1,cso);
       Map<String,String> fldMap1 = new CsoQueueable().setAcctFldMap(wrap);
       System.assertEquals('123 Shipping St',fldMap1.get('ShippingStreet'));
       System.assertEquals('ShippingCity',fldMap1.get('ShippingCity'));
       System.assertEquals('NY',fldMap1.get('ShippingState'));
       System.assertEquals('11111',fldMap1.get('ShippingPostalCode'));
       System.assertEquals('US',fldMap1.get('ShippingCountry'));
        
       wrap = new CsoQueueable.AcctCsoWrap(acct2,cso);
       Map<String,String> fldMap2 = new CsoQueueable().setAcctFldMap(wrap);
       System.assertEquals('123 Billing St',fldMap2.get('ShippingStreet'));
       System.assertEquals('BillingCity',fldMap2.get('ShippingCity'));
       System.assertEquals('MA',fldMap2.get('ShippingState'));
       System.assertEquals('22222',fldMap2.get('ShippingPostalCode'));
       System.assertEquals('US',fldMap2.get('ShippingCountry'));

       wrap = new CsoQueueable.AcctCsoWrap(acct3,cso);
       Map<String,String> fldMap3 = new CsoQueueable().setAcctFldMap(wrap);
       System.assertEquals('123 Legal St',fldMap3.get('ShippingStreet'));
       System.assertEquals('LegalCity',fldMap3.get('ShippingCity'));
       System.assertEquals('VT',fldMap3.get('ShippingState'));
       System.assertEquals('33333',fldMap3.get('ShippingPostalCode'));
       System.assertEquals('US',fldMap3.get('ShippingCountry'));

    } // testSetAcctFldMap
    
    static testMethod void testUpdates() {
       Account acct1 = new Account(Name='Account1', ShippingStreet='123 Shipping St', ShippingCity='ShippingCity', ShippingState='NY', ShippingPostalCode='11111', ShippingCountry='US');
       //Account acct2 = new Account(Name='Account2', BillingStreet='123 Billing St', BillingCity='BillingCity', BillingState='MA', BillingPostalCode='22222',BillingCountry='US');
       //Account acct3 = new Account(Name='Account3', LegalAddress__Street__s='123 Legal St', LegalAddress__City__s='LegalCity', LegalAddress__StateCode__s='VT', LegalAddress__PostalCode__s='33333', LegalAddress__CountryCode__s='US');
       CSO_Tracking__c cso = new CSO_Tracking__c();
       CsoQueueable.AcctCsoWrap wrap = new CsoQueueable.AcctCsoWrap(acct1,cso);
       wrap.setRequestStart(EZOnboardingRegistration.REG_CSO);
       System.assertNotEquals(null,cso.RegistrationStart__c);
        
       wrap.setRequestEnd(EZOnboardingRegistration.REG_CSO, '200',null);
       System.assertEquals('200',cso.RegistrationStatusCode__c);
       System.assertNotEquals(null,cso.RegistrationEnd__c);
       System.assertEquals(true,cso.RegistrationStarted__c);

    } // testUpdates
    
} // class CsoQueueableTest