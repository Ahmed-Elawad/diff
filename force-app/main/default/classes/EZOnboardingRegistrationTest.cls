/* 
   Test methods for EZOnboardingRegistration

   
  History
  -------
  06/30/2022 Dan Carmen        Created
  07/11/2022 Harish Lanka      Added EZTest
  07/21/2022 Dan Carmen        Capture exception in getTracking
  10/25/2022 Dan Carmen        Additional CSO/Enterprise changes
  11/03/2022 Dan Carmen        Add Contact FlexUEID to the query
  05/22/2023 Dan Carmen        Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
  11/03/2023 Dan Carmen        Changes for PO Box
  01/22/2024 Dan Carmen        Fix query for tracker to make sure we're getting the children.
  04/23/2024 Dan Carmen        Fix for testCpqKeys test

 */
@isTest
public class EZOnboardingRegistrationTest {
    
   public static final String OPP1='Opp1';
   public static final String OPP2='Opp2';
   public static final String ACCT1='Test Account1';
   public static final String ACCT2='Test Account2';
   public static final String ACCT3='Test Account3';
    
   @testSetup
    public static void setupData() {
        CsoMethodTest.setupTriggers();
        //ADD CSO QUEUEABLE DATA
        //
        String[] wssNames = new String[]{CsoQueueable.VALIDATE_ACCT_CSO,CsoQueueable.VALIDATE_USER,EZOnboardingRegistration.REG_ENT
                                        ,EZOnboardingRegistration.OSS_KEYS, EZOnboardingRegistration.CPQ_KEYS, EZOnboardingRegistration.CPQ_SUB};
        WebServiceSettings__c[] wssList = new WebServiceSettings__c[]{};
        for (String wssName : wssNames) {
           WebServiceSettings__c wss = new WebServiceSettings__c(Name = wssName, IsActive__c=true,Timeout__c = '10000'
                ,Certificate__c = Label.Test_Class_Certificate_Name
                ,Endpoint__c = 'https://service-inbound-pyx-n0.paychex.com/cordgw/client/validate	'
            );
            if (wssName == EZOnboardingRegistration.CPQ_KEYS || wssName == EZOnboardingRegistration.CPQ_SUB) {
                wss.NamedCredential__c=true;
                wss.Comment__c = 'callout:OracleCPQ/{0}/actions/updateOSSAccountIDsFromSFDC';
            }
           wssList.add(wss);
        } // for (String wssName : wssNames
        insert wssList;

        Apex_Batch_Control__c abc1 = new Apex_Batch_Control__c(Name=CsoQueueable.CLASSNAME,Active__c=true);
        Apex_Batch_Control__c abc2 = new Apex_Batch_Control__c(Name=EZOnboardingRegistration.KEYS_NAME,Active__c=true);
        Apex_Batch_Control__c abc3 = new Apex_Batch_Control__c(Name=EnterpriseRegistration.CLASSNAME,Active__c=true);
        insert new Apex_Batch_Control__c[]{abc1,abc2,abc3};

        //Add Errors
        CSOErrorCodes__c CLIENT_CONSTRAINT = new CSOErrorCodes__c(Name='CLIENT-LIST-CONSTRAINT',Error_Code__c='CLIENT-LIST-CONSTRAINT',Error_Message__c='Legal Name must be populated on submission. Please update and re-submit.',Display_Message__c=true);
       	insert CLIENT_CONSTRAINT;

        Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
        Id acctRt = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId();

        Account acct1 = new Account(Name=ACCT1, RecordTypeId=acctRt, Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        Account acct2 = new Account(Name=ACCT2, RecordTypeId=acctRt, Federal_ID_Number__c='86-7530915'
                                   ,ShippingStreet='123 Shipping Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US'
                                   ,BillingStreet='123 Billing St', BillingCity='BillingCity', BillingState='MA', BillingPostalCode='22222',BillingCountry='US'
                                   ,LegalAddress__Street__s='123 Legal St', LegalAddress__City__s='LegalCity', LegalAddress__StateCode__s='VT', LegalAddress__PostalCode__s='33333', LegalAddress__CountryCode__s='US'
                                   );
        Account acct3 = new Account(Name=ACCT3, RecordTypeId=acctRt, Federal_ID_Number__c='86-7530917'
                                   ,ShippingStreet='234 Shipping Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US'
                                   ,BillingStreet='234 Billing St', BillingCity='BillingCity', BillingState='MA', BillingPostalCode='22222',BillingCountry='US'
                                   ,LegalAddress__Street__s='234 Legal St', LegalAddress__City__s='LegalCity', LegalAddress__StateCode__s='VT', LegalAddress__PostalCode__s='33333', LegalAddress__CountryCode__s='US'
                                   );
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert new Account[]{acct1,acct2,acct3};
        acct3.SalesParent__c = acct2.Id;
        update acct3;
        Account_Junction__c aj1 = new Account_Junction__c(Parent_Account__c=acct2.Id, Child_Account__c=acct3.Id, Type__c='Combo');
        insert aj1;
        
        
        Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
        Contact ctct1b = new Contact(FirstName='Louise',LastName='Test1b',Email='louise@test1.com', MobilePhone='(585) 111-2223', AccountId=acct1.id);
        Contact ctct2a = new Contact(FirstName='Lou',LastName='Test2a',Email='lou@test2.com', MobilePhone='(585) 111-2223', AccountId=acct2.id);
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        insert new Contact[]{ctct1a,ctct1b,ctct2a};
           
        Opportunity opp1 = new Opportunity(Name=OPP1, AccountId=acct1.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
        Opportunity opp2 = new Opportunity(Name=OPP2, AccountId=acct2.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
        OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
        insert new Opportunity[]{opp1,opp2};
        
        OpportunityContactRole ocr1 = new OpportunityContactRole(OpportunityId=opp1.Id, ContactId=ctct1a.Id, IsPrimary=true, Role='Decision Maker');
        insert ocr1;
        
        CSO_Tracking__c tracker1 = new CSO_Tracking__c(Name=opp1.Name, AccountId__c=acct1.Id, Opportunity__c=opp1.Id, Contact__c=ctct1a.Id);
        CSO_Tracking__c tracker2 = new CSO_Tracking__c(Name=opp2.Name, AccountId__c=acct2.Id, Opportunity__c=opp2.Id, Contact__c=ctct2a.Id);
        insert new CSO_Tracking__c[]{tracker1,tracker2};
        opp1.ClientTracking__c = tracker1.Id;
        opp2.ClientTracking__c = tracker2.Id;
        update new Opportunity[]{opp1,opp2};
        CSO_Tracking__c tracker3 = new CSO_Tracking__c(Name=acct3.Name, AccountId__c=acct3.Id, ParentAccount__c=acct2.Id, ParentTracker__c=tracker2.Id, ChildType__c='Combo');
        insert tracker3;

        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();

    } // setupData
    
    public static Opportunity getTestOpp(String oppName) {
       Opportunity opp = [Select Id, Name, AccountId, CloseDate, StageName, LeadSource, OwnerId, Pricebook2Id
                                ,Primary_Oracle_Quote__c, Probability,ClientRegistrationTestMode__c
                                ,(Select Id, OpportunityId, ContactId
                                    From OpportunityContactRoles)
                            From Opportunity where Name=:oppName];
       return opp;
    } // getTestOpp
    
    public static Account getTestAcct(String acctName) {
       Account acct = [Select Id, Name, RecordTypeId, SalesParent__c, Paychex_CEID__c, Paychex_CAID__c, EnterpriseBillingId__c, EnterpriseShippingId__c
                             ,BillingUUID__c, ShippingUUID__c
                             ,EBSAccountID__c, EBSBillToSiteID__c, EBSPartyId__c, EBSShipToSiteID__c
                             ,OSSAccountID__c, OSSBillToSiteID__c, OSSPartyID__c, OSSShipToSiteID__c
                             ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                             ,Federal_ID_Number__c,Significant_Contact_Email__c
                             ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                             ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s, LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                             ,(Select Id, Name, FirstName, LastName, Email, Phone, MobilePhone from Contacts)
                         From Account where Name=:acctName];
       return acct;
    } // getTestAcct
    
    public static CSO_Tracking__c getTracker(String trackName) {
       String query = EcomMethods.getCSOTrackerQuery();
       query += ' Where Name=:trackName';
       CSO_Tracking__c tracker = null;
       try {
           tracker = Database.query(query);
       } catch (Exception e) {}
       return tracker;
    } // getTracker
    
    static testMethod void testMisc1() {
       Opportunity testOpp = getTestOpp(OPP1);
       CSO_Tracking__c tracker1 = EZOnboardingRegistration.getTracking(testOpp.Id);
       System.assertNotEquals(null,tracker1);
       EZOnboardingRegistration.OppPathWrapper wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       EZOnboardingRegistration.getOpportunity(testOpp.Id,wrap);
       System.assertEquals(testOpp.Id, wrap.opp.Id);
        
       Opportunity updateOpp = new Opportunity(Id=testOpp.Id, LeadSource='EZOnboardingRegistration');
       EZOnboardingRegistration.updateOppAndAccount(testOpp.AccountId,updateOpp, '123 Any Street', 'SomeCity', '12345', 'USA', 'NY', 'No');
       
       Opportunity checkOpp = getTestOpp(OPP1);
       System.assertEquals('EZOnboardingRegistration', checkOpp.LeadSource);
       Account acct = getTestAcct(ACCT1);
       System.assertEquals('123 Any Street', acct.ShippingStreet);
       System.assertEquals('SomeCity', acct.ShippingCity);
       System.assertEquals('NY', acct.ShippingState);
       System.assertEquals('12345', acct.ShippingPostalCode);
       System.assertEquals('USA', acct.ShippingCountry);
           
       User runningUser = UserHelper.getRunningUser();
       String checkid = EZOnboardingRegistration.getCurrentUserId();
       System.assertEquals(runningUser.Id, checkid);
        
       Contact[] ctcts = EZOnboardingRegistration.getContact(testOpp.Id);
       System.assertEquals(2,ctcts.size());
        
       Contact ctct = ctcts[0];
       EZOnboardingRegistration.updateContact(ctct.Id, 'coolemail@test.com', '(555) 333-1234');
       Contact checkCtct = [Select Id, Name, Email, MobilePhone from Contact where Id=:ctct.Id];
       System.assertEquals('coolemail@test.com', checkCtct.Email);
       System.assertEquals('(555) 333-1234', checkCtct.MobilePhone);
        
       EZOnboardingRegistration.updateCSO(tracker1, '123456789','Yes', 'No', 'No', 'No', 'No' );
        
       CSO_Tracking__c tracker = getTracker(testOpp.Name);
       System.assertEquals('123456789', tracker.SSN_Number__c);
       System.assertEquals('Yes', tracker.Is_this_a_SSN_Number__c);
       System.assertEquals('No', tracker.Data_Extraction_Needed__c);
       System.assertEquals('No', tracker.Returning_Lost_Client__c);
       System.assertEquals('No', tracker.Client_Require_Non_English_Paperwork__c);
       System.assertEquals('No', tracker.Part_of_a_Multi_ID_Affiliated_ID_s__c);
        
       EZOnboardingRegistration.setLegalToShipping(acct);
       acct = getTestAcct(ACCT1);
       System.assertEquals(acct.ShippingStreet, acct.LegalAddress__Street__s);
       System.assertEquals(acct.ShippingState, acct.LegalAddress__StateCode__s);
       System.assertEquals(acct.ShippingCity, acct.LegalAddress__City__s);
       System.assertEquals(acct.ShippingPostalCode, acct.LegalAddress__PostalCode__s);
       System.assertEquals('US', acct.LegalAddress__CountryCode__s);
        
/*      
        CSO_Tracking__c cso = [SELECT ID FROM CSO_Tracking__c WHERE Opportunity__c =:recordId order by CreatedDate desc limit 1];
        cso.Is_this_a_SSN_Number__c = isssn;
        cso.SSN_Number__c = ssn;
        cso.Data_Extraction_Needed__c = extraction;
        cso.Returning_Lost_Client__c = client;
        cso.Client_Require_Non_English_Paperwork__c = paperwork;
        cso.Part_of_a_Multi_ID_Affiliated_ID_s__c = multiId;
*/
        
    } // testMisc1
    
    static testMethod void testGetWrapper() {
       Opportunity testOpp = getTestOpp(OPP1);
       CSO_Tracking__c tracker1 = EZOnboardingRegistration.getTracking(testOpp.Id);
       User runningUser = UserHelper.getRunningUser();
       Account acct = getTestAcct(ACCT1);
        
       EZOnboardingRegistration.OppPathWrapper wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(runningUser.Id, wrap.currentUserId);
       System.assertEquals(2,wrap.ctcts.size());
       System.assertEquals(false, wrap.docusignComplete);
       System.assertEquals(tracker1.Id, wrap.tracker.Id);
       
       EZOnboardingRegistration.removeException(tracker1);
    } // testGetWrapper
    
    static testMethod void testSignedQuote() {
       User runningUser = UserHelper.getRunningUser();
       EZOnboardingRegistration.QUOTE_CREATED_BY = runningUser.Name;
       //EZOnboardingRegistration.OppPathWrapper wrap = new EZOnboardingRegistration.OppPathWrapper();
        
       Opportunity testOpp = getTestOpp(OPP1);
       EZOnboardingRegistration.OppPathWrapper wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(false,wrap.docusignComplete);
       System.assertEquals(false,wrap.oppStageIsWon);
       System.assertEquals(false,wrap.ezComplete);
        
       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c newQuote = new cafsl__Oracle_Quote__c(Name=OPP1, cafsl__Opportunity__c=testOpp.Id, cafsl__Account__c=testOpp.AccountId);
       newQuote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert newQuote;
       testOpp.Primary_Oracle_Quote__c = newQuote.Id;
       testOpp.StageName = 'Won';
       testOpp.Probability=70;
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       update testOpp;
       wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(false,wrap.docusignComplete);
       System.assertEquals(true,wrap.oppStageIsWon);
       System.assertEquals(false,wrap.ezComplete);

       Blob b = Blob.valueOf('This is just some fun sample text');
       Attachment a = new Attachment(ParentId = testOpp.id
        								,Description = 'A very cool attachment'
        								,Name=testOpp.Name+' is now completed'
        								,Body=b);
       insert a;
       wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(true,wrap.docusignComplete);
       System.assertEquals(true,wrap.oppStageIsWon);
       System.assertEquals(true,wrap.ezComplete);

       
       // create a primary quote
       
    } // testSignedQuote
    
    static testMethod void testUpdateAcct() {
        Account acc = getTestAcct(ACCT1);
        EZOnboardingRegistration.updateAccount(acc.Id, '541234567');
        acc = [Select Id, Federal_ID_Number__c from Account where Id=:acc.Id];
        System.assertEquals('54-1234567', acc.Federal_ID_Number__c);
    } // testUpdateAcct
    
@isTest
    public static void EZTest(){
        Account acc = getTestAcct(ACCT1);
        Contact con = acc.Contacts[0];
        Opportunity opp = getTestOpp(OPP1);
        System.debug('EZTest opp='+opp.Id+' Name='+opp.Name);
        
        PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Bundle','Prod1','Prod2'}, 'PAY', null);
        Product2[] updateProds = new Product2[]{};
        // set the CSO attributes
        for (PricebookEntry entry : entries) {
            System.debug('EZTest prod='+entry.Product2.Name);
            updateProds.add(new Product2(Id=entry.Product2Id, CSO_Required__c=(entry.Product2.Name == 'Bundle'), CSO_Eligible__c=true, USS_Enterprise_Code__c=entry.Product2.Name));
        }
        update updateProds;
        
        opp.Pricebook2Id = entries[0].Pricebook2Id;
        OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
        update opp;
        
        //Product2[] prods = [Select Id, Name, USS_Enterprise_Code__c from Product2 where Id in :updateProds];
        //System.debug('EZTest prods='+prods);
        
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = acc.Id;
        quote.cafsl__Opportunity__c = opp.Id;
        quote.cafsl__Syncing__c = false;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = entries[0].Pricebook2Id;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        Assert.areEqual(1, [select count() from cafsl__Oracle_Quote__c where cafsl__Opportunity__c = :opp.Id]);
        //Assert.areEqual(1, [select count() from cafsl__Oracle_Quote__c where cafsl__Opportunity__c = :opp.Id and cafsl__Syncing__c = true]);
        //cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=entries[0].Product2Id, cafsl__Oracle_Quote__c=quote.Id, Prospect_Client__c=acc.Id);
        //cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=entries[1].Product2Id, cafsl__Oracle_Quote__c=quote.Id, Prospect_Client__c=acc.Id);
        //cafsl__Oracle_Quote_Line_Item__c quoteLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=entries[2].Product2Id, cafsl__Oracle_Quote__c=quote.Id, Prospect_Client__c=acc.Id);
        
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entries[0].Product2Id, Prospect_Client__c=acc.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entries[1].Product2Id, Prospect_Client__c=acc.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=5.00
                                                                                        ,cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entries[2].Product2Id, Prospect_Client__c=acc.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=6.00
                                                                                        ,cafsl__External_Id__c=3, cafsl__CPQ_External_Id__c='12345678-3', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        insert new cafsl__Oracle_Quote_Line_Item__c[]{quoteLine1,quoteLine2,quoteLine3};
            
        //cafsl__Oracle_Quote_Line_Item__c[] testItems = [Select Id, cafsl__Oracle_Quote__r.cafsl__Syncing__c
        //                                                      ,cafsl__Product__r.Name, cafsl__Product__r.USS_Enterprise_Code__c
        //                                                  From cafsl__Oracle_Quote_Line_Item__c
        //                                                 Where cafsl__Oracle_Quote__r.cafsl__Opportunity__c = :opp.Id];
        //System.debug('EZTest testItems='+testItems.size());
        //for (cafsl__Oracle_Quote_Line_Item__c item : testItems) {
        //    System.debug('EZTest prod='+item.cafsl__Product__r);
        //}
        
        // TODO for some reason the products aren't staying on the quote lines, which is causing the query when building the message to not return any data. 
        //Assert.areEqual(3, [select count() from cafsl__Oracle_Quote_Line_Item__c 
        //                                  where cafsl__Oracle_Quote__r.cafsl__Opportunity__c = :opp.Id
        //                                    //and cafsl__Oracle_Quote__r.cafsl__Syncing__c = true 
        //                                    and cafsl__Product__r.USS_Enterprise_Code__c != null
        //                     ]);

        opp.Primary_Oracle_Quote__c=quote.id;
        //opp.Pricebook2Id = entries[0].Pricebook2Id;
        update opp;
        //quote.cafsl__Syncing__c = true;
        //update quote;
        /*
        List<cafsl__Oracle_Quote_Line_Item__c> qLineList = [Select Id,
                                                            cafsl__Oracle_Quote__r.cafsl__Syncing__c,
                                                            cafsl__Oracle_Quote__r.cafsl__Opportunity__c,
                                                            cafsl__Oracle_Quote__r.cafsl__Opportunity__r.CloseDate,
                                                            cafsl__Product__c,cafsl__Product__r.Name,
                                                            cafsl__Product__r.cafsl__Part_Number__c, 
                                                            cafsl__Product__r.CSO_Required__c,    // TODO - use this to identify the bundle for now
                                                            cafsl__Product__r.USS_Enterprise_Code__c 
                                                            from cafsl__Oracle_Quote_Line_Item__c 
                                                            where cafsl__Oracle_Quote__r.cafsl__Opportunity__c =:opp.Id 
                                                            //and cafsl__Oracle_Quote__r.cafsl__Syncing__c = true 
                                                            //and cafsl__Product__r.USS_Enterprise_Code__c!=null
                                                           ];
        System.debug('EZTest opp.Id='+opp.Id+' qLineList='+qLineList);
        */
        CSO_Tracking__c cso = getTracker(opp.Name);
        // so it doesn't try to run the validation
        cso.ClientDataValidated__c = true;
        cso.User_Validated__c = true;
        cso.AccountId__c = acc.Id;
       
        WebServiceSettings__c webss = new WebServiceSettings__c(Certificate__c='SFDC_fullsandbx',Name='CSO_Registration',Endpoint__c='https://service-inbound-pyx-n2a.paychex.com/cordgw/client/register',IsActive__c=TRUE);
        Insert webss;

        EZOnboardingRegistration.updateOpp(opp,true,true,true);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EZOnboardingRegistrationMock());
        
        // reselect the opp to make sure we have all the fields
        //EZOnboardingRegistration.OppPathWrapper pathWrap = new EZOnboardingRegistration.OppPathWrapper();
        EZOnboardingRegistration.OppPathWrapper pathWrap = EZOnboardingRegistration.getOppPathInfo(opp.Id);
        EZOnboardingRegistration.getOpportunity(opp.Id, pathWrap);
        EZOnboardingRegistration.sendCSOData(pathWrap.opp,acc.Federal_ID_Number__c,con.Id,cso,false,'No','001000000000000000','001000000000000000');
        Test.stopTest();
    } // EZTest
    
    static testMethod void testParse() {
        
        String test1 = '{"content":[],"errors":[{"code":"API-CLIENTADD105","description":"Partial match. Clt Add Exists - Tin Match Only. New client was not created.","resolution":"0030g00002KbcXqAAJ12:04:21.551Z"}]}';
        EZOnboardingRegistration.EntResponse entResp = EZOnboardingRegistration.parseResponse(test1);
        System.assertEquals(true, entResp.errDesc.contains('Partial match. Clt Add Exists'), 'errDesc='+entResp.errDesc);
        String test2 = '"description":"Partial match. Clt Add Exists - Tin Match Only"';
        entResp = EZOnboardingRegistration.parseResponse(test2);
        System.assertEquals(true, entResp.errDesc.contains('Partial match. Clt Add Exists'),'errDesc='+entResp.errDesc);
    } // testParse
    
    static testMethod void testEnterpriseSubmit() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);

       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = mockResp.getTestEcagResponse(acct1.Id);
       Test.setMock(HttpCalloutMock.class, mockResp);
       cso.EntRegTest__c=true;
       update cso;
       Test.stopTest();
       
       CsoMethods.includeQueryReg = false;
       Map<Id, CSO_Tracking__c> csoMap = CsoMethods.getCsoRecs(new Id[]{cso.Id});
       CSO_Tracking__c cso1 = csoMap.get(cso.Id);
       Assert.isFalse(cso1.EntRegTest__c);
       Assert.isNotNull(cso1.RegistrationStart__c);
       Assert.isNotNull(cso1.RegistrationEnd__c);
       Assert.areEqual('200',cso1.RegistrationStatusCode__c);
        
       acct1 = [Select id, Paychex_CEID__c, Paychex_CAID__c, EnterpriseAAID__c, EnterpriseBillingId__c, EnterpriseShippingId__c, ClientRegistrationStatus__c from Account where Id=:acct1.id];
       System.debug('testEnterpriseSubmit acct1='+acct1);
       Assert.areEqual(EZOnboardingRegistrationMock.testCeid, acct1.Paychex_CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCaid, acct1.Paychex_CAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testLegalAid, acct1.EnterpriseAAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testBillAid, acct1.EnterpriseBillingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testShipAid, acct1.EnterpriseShippingId__c);
       Assert.areEqual(CsoMethods.TYPE_CLIENT, acct1.ClientRegistrationStatus__c);
        
    } // testEnterpriseSubmit
    
    static testMethod void testEnterpriseError() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       
       Opportunity opp = getTestOpp(OPP1);
       CSO_Tracking__c cso = getTracker(opp.Name);

       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = mockResp.getTestOicError(acct1.Id);
       Test.setMock(HttpCalloutMock.class, mockResp);
       cso.EntRegTest__c=true;
       update cso;
       Test.stopTest();
        
       CsoMethods.includeQueryReg = false;
       Map<Id, CSO_Tracking__c> csoMap = CsoMethods.getCsoRecs(new Id[]{cso.Id});
       CSO_Tracking__c cso1 = csoMap.get(cso.Id);
       Assert.isFalse(cso1.EntRegTest__c);
       Assert.isNotNull(cso1.RegistrationStart__c);
       Assert.isNotNull(cso1.RegistrationEnd__c);
       Assert.areEqual('400',cso1.RegistrationStatusCode__c);

       Assert.isFalse(cso1.Opportunity_Eligible__c);
       Assert.isNotNull(cso1.RegistrationDetail__c, 'RegistrationDetail__c='+cso1.RegistrationDetail__c);
       Assert.isTrue(cso1.RegistrationDetail__c.contains('Invalid Error 1'), 'RegistrationDetail__c='+cso1.RegistrationDetail__c);

    } // testEnterpriseError
    
    static testMethod void getTestCalls() {
      //String resp = new EZOnboardingRegistrationMock().getTestOicResponse(EZOnboardingRegistrationMock.acctId1);
      String resp = new EZOnboardingRegistrationMock().getTestOicError(EZOnboardingRegistrationMock.acctId1);
      //resp = new EZOnboardingRegistrationMock().getTestOicResponse2(EZOnboardingRegistrationMock.acctId1);
    } // getTestCalls
    
    static testMethod void testEntSubmitMulti() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       Account acct2 = getTestAcct(ACCT3);
       // make them same FEIN
       acct2.Federal_Id_Number__c = acct1.Federal_ID_Number__c;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct2;
       
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);

       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
       quote.cafsl__Account__c = acct1.Id;
       quote.cafsl__Opportunity__c = opp.Id;
       quote.cafsl__Syncing__c = true;
       quote.Name = 'Test Quote';
       quote.Multi_ID__c = true;
       quote.IsSubscriptionQuote__c=true;
       quote.cafsl__Pricebook_Id__c = opp.Pricebook2Id;
       quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert quote;
        
       Product2 quoteProductA = New Product2(Name = 'TestProduct', PayrollFrequency__c = 'Weekly', ProductCode = 'PAY', IsActive = true, CSO_Eligible__c = false);
       insert quoteProductA;
        
       cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct1.Id);
       cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct2.Id);
       insert new cafsl__Oracle_Quote_Line_Item__c[]{quoteLine1,quoteLine2};

       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock.acctId2 = acct2.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       //mockResp.responseToUse = mockResp.testOICResponse;
       mockResp.responseToUse = mockResp.testOICResponseMultiple;
       Assert.isTrue(mockResp.responseToUse.contains(acct1.Id));
        
       Test.setMock(HttpCalloutMock.class, mockResp);
       System.debug('testOicSubmitMulti set EntRegTest__c');
       TriggerMethods.clearVariables();
       CsoMethods.SKIP_TRIGGERS=false;
       cso.EntRegTest__c=true;
       update cso;
       Test.stopTest();
       
       CsoMethods.includeQueryReg = false;
       Map<Id, CSO_Tracking__c> csoMap = CsoMethods.getCsoRecs(new Id[]{acct1.id,acct2.Id}, false);
       CSO_Tracking__c cso1 = csoMap.get(acct1.Id);
       System.assertEquals(false,cso1.EntRegTest__c);
       Assert.isNotNull(cso1.RegistrationStart__c);
       Assert.isNotNull(cso1.RegistrationEnd__c);
       Assert.areEqual('200',cso1.RegistrationStatusCode__c);
       Assert.isTrue(cso1.RegistrationStarted__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCeid, cso1.CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCaid, cso1.CAID__c);
        
       CSO_Tracking__c cso2 = csoMap.get(acct2.Id);
       //Assert.isNotNull(cso1.RegistrationStart__c);
       //Assert.isNotNull(cso1.RegistrationEnd__c);
       Assert.areEqual('200',cso2.RegistrationStatusCode__c);
       Assert.isTrue(cso2.RegistrationStarted__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCeid, cso2.CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCaid2, cso2.CAID__c);

        
       Map<Id,Account> acctMap = new Map<Id,Account>([Select id, Paychex_CEID__c, Paychex_CAID__c, EnterpriseClientNumber__c
                                                             ,EnterpriseAAID__c, EnterpriseBillingId__c, EnterpriseShippingId__c 
                                                         from Account where Id=:acct1.id or Id=:acct2.Id]);
       acct1 = acctMap.get(acct1.Id);
       System.debug('testOicSubmit acct1='+acct1);
       Assert.areEqual(EZOnboardingRegistrationMock.testCeid, acct1.Paychex_CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCaid, acct1.Paychex_CAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testAcctNbr1, acct1.EnterpriseClientNumber__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testLegalAid, acct1.EnterpriseAAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testBillAid, acct1.EnterpriseBillingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testShipAid, acct1.EnterpriseShippingId__c);

       acct2 = acctMap.get(acct2.Id);
       System.debug('testOicSubmit acct2='+acct2);
       Assert.areEqual(EZOnboardingRegistrationMock.testCeid, acct2.Paychex_CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testCaid2, acct2.Paychex_CAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testAcctNbr2, acct2.EnterpriseClientNumber__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testLegalAid, acct2.EnterpriseAAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testBillAid2, acct2.EnterpriseBillingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.testBillAid2, acct2.EnterpriseShippingId__c);

        
    } // testEntSubmitMulti
    
    static testMethod void testOssKeys() {
       executeTestOssKeys(false);
    } // testOssKeys
    
    public static void executeTestOssKeys(Boolean useBatch) {
       System.debug('executeTestOssKeys useBatch='+useBatch);
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       acct1.Paychex_CEID__c = EZOnboardingRegistrationMock.testCeid;
       acct1.Paychex_CAID__c = EZOnboardingRegistrationMock.testCaid;
       acct1.EnterpriseBillingId__c = EZOnboardingRegistrationMock.testBillAid;
       acct1.EnterpriseShippingId__c = EZOnboardingRegistrationMock.testShipAid;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct1;
        
       AccountAddress__c addr1 = new AccountAddress__c(Name='bill addr', Account__c=acct1.Id, EnterpriseAID__c=EZOnboardingRegistrationMock.testBillAid
                                                      ,CAID__c=EZOnboardingRegistrationMock.testCaid, CEID__c=EZOnboardingRegistrationMock.testCeid);
       //AccountAddress__c addr2 = new AccountAddress__c(Name='ship addr', Account__c=acct1.Id, EnterpriseAID__c=EZOnboardingRegistrationMock.testShipAid
       //                                               ,CAID__c=EZOnboardingRegistrationMock.testCaid, CEID__c=EZOnboardingRegistrationMock.testCeid);
       insert new AccountAddress__c[]{addr1};
       
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);
       if (useBatch) {
          // to trigger the batch
          cso.OSSKeysNextAttempt__c = Datetime.now();
          CsoMethods.SKIP_TRIGGERS=true;
          update cso;
       }

       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       //mockResp.responseToUse = mockResp.testOICResponse;
       mockResp.responseToUse = EZOnboardingRegistrationMock.getOssKeyResp();
       Test.setMock(HttpCalloutMock.class, mockResp);
       cso.TestOSSKeys__c=true;
       update cso;

       Test.stopTest();
        
       acct1 = getTestAcct(ACCT2);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsPartyId, acct1.EBSPartyId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsAcctId, acct1.EBSAccountID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsBill1, acct1.EBSBillToSiteID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsShip2, acct1.EBSShipToSiteID__c);
        
       Assert.areEqual(EZOnboardingRegistrationMock.ossPartyId, acct1.OSSPartyID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ossAcctId, acct1.OSSAccountID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ossBill1, acct1.OSSBillToSiteID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ossShip2, acct1.OSSShipToSiteID__c);
        
       Assert.areEqual(2,[Select count() from AccountAddress__c where CAID__c=:EZOnboardingRegistrationMock.testCaid]);
        
       cso = getTracker(opp.Name);
       Assert.isNotNull(cso.OSSKeysStart__c);
       Assert.isNotNull(cso.OSSKeysEnd__c);
       Assert.areEqual('200', cso.OSSKeysStatusCode__c);

    } // executeTestOssKeys
    
    static testMethod void testOssKeyError() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       acct1.Paychex_CEID__c = EZOnboardingRegistrationMock.testCeid;
       acct1.Paychex_CAID__c = EZOnboardingRegistrationMock.testCaid;
       acct1.EnterpriseBillingId__c = EZOnboardingRegistrationMock.testBillAid;
       acct1.EnterpriseShippingId__c = EZOnboardingRegistrationMock.testShipAid;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct1;
        
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);
        
       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       //mockResp.responseToUse = mockResp.testOICResponse;
       mockResp.responseToUse = EZOnboardingRegistrationMock.getOssKeysNotFound();
       Test.setMock(HttpCalloutMock.class, mockResp);
       cso.TestOSSKeys__c=true;
       update cso;
       Test.stopTest();

       cso = getTracker(opp.Name);
       Assert.isNotNull(cso.OSSKeysStart__c);
       Assert.isNotNull(cso.OSSKeysEnd__c);
       Assert.areEqual('404', cso.OSSKeysStatusCode__c);
       Assert.areEqual('No matching records found', cso.OSSKeysDetail__c);

    } // testOssKeyError
    
    static testMethod void testOssKeyPartialError() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       acct1.Paychex_CEID__c = EZOnboardingRegistrationMock.testCeid;
       acct1.Paychex_CAID__c = EZOnboardingRegistrationMock.testCaid;
       acct1.EnterpriseBillingId__c = EZOnboardingRegistrationMock.testBillAid;
       acct1.EnterpriseShippingId__c = EZOnboardingRegistrationMock.testShipAid;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct1;
        
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);
        
       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       //mockResp.responseToUse = mockResp.testOICResponse;
       mockResp.responseToUse = EZOnboardingRegistrationMock.getOssKeyRespPartial();
       Test.setMock(HttpCalloutMock.class, mockResp);
       cso.TestOSSKeys__c=true;
       update cso;
       Test.stopTest();

       cso = getTracker(opp.Name);
       Assert.isNotNull(cso.OSSKeysStart__c);
       Assert.isNotNull(cso.OSSKeysEnd__c);
       Assert.areEqual('405', cso.OSSKeysStatusCode__c);
       Assert.isTrue(cso.OSSKeysDetail__c.startsWith('Missing fields'));

       acct1 = getTestAcct(ACCT2);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsPartyId, acct1.EBSPartyId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsAcctId, acct1.EBSAccountID__c);
       //Assert.areEqual(EZOnboardingRegistrationMock.ebsBill1, acct1.EBSBillToSiteID__c);
       Assert.isNull(acct1.EBSBillToSiteID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ebsShip2, acct1.EBSShipToSiteID__c);
        
       Assert.areEqual(EZOnboardingRegistrationMock.ossPartyId, acct1.OSSPartyID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ossAcctId, acct1.OSSAccountID__c);
       //Assert.areEqual(EZOnboardingRegistrationMock.ossBill1, acct1.OSSBillToSiteID__c);
       Assert.isNull(acct1.OSSBillToSiteID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.ossShip2, acct1.OSSShipToSiteID__c);
 
    } // testOssKeyPartialError
    
    static testMethod void testCpqKeys() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT1);
       acct1.Paychex_CEID__c = EZOnboardingRegistrationMock.testCeid;
       acct1.Paychex_CAID__c = EZOnboardingRegistrationMock.testCaid;
       acct1.EnterpriseBillingId__c = EZOnboardingRegistrationMock.testBillAid;
       acct1.EnterpriseShippingId__c = EZOnboardingRegistrationMock.testShipAid;
       acct1.OSSPartyID__c = EZOnboardingRegistrationMock.ossPartyId;
       acct1.OSSAccountID__c = EZOnboardingRegistrationMock.ossAcctId;
       acct1.OSSBillToSiteID__c = EZOnboardingRegistrationMock.ossBill1;
       acct1.OSSShipToSiteID__c = EZOnboardingRegistrationMock.ossShip2;
       // make sure required fields have values
       for (Schema.FieldSetMember fsm : Schema.SObjectType.Account.fieldSets.CPQSubReqFlds.getFields()) {
          String fldName = fsm.getFieldPath();
          if (acct1.get(fldName) == null) {
             acct1.put(fldName,EZOnboardingRegistrationMock.ossPartyId);
          }
       } // for (Schema.FieldSetMember fsm
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct1;
        
       Opportunity opp = getTestOpp(OPP1);
       Opportunity updateOpp = new Opportunity(Id=opp.Id, ClientRegistrationTestMode__c=true);
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       update updateOpp;
       CSO_Tracking__c cso = getTracker(opp.Name);

       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       //mockResp.responseToUse = mockResp.testOICResponse;
       mockResp.responseToUse = EZOnboardingRegistrationMock.getCPQKeysResp();
       mockResp.responseCode = 200;
       Test.setMock(HttpCalloutMock.class, mockResp);
       EZOnboardingRegistration.BYPASS_QUOTE_CHECK=true;
       cso.TestCPQKeys__c=true;
       update cso;
       Test.stopTest();
        
       cso = getTracker(opp.Name);
       Assert.isNotNull(cso.CPQKeysStart__c);
       Assert.isNotNull(cso.CPQKeysEnd__c);
       Assert.areEqual('200', cso.CPQKeysStatusCode__c);

    } // testCpqKeys
  
    static testMethod void testCpqSub() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       acct1.Paychex_CEID__c = EZOnboardingRegistrationMock.testCeid;
       acct1.Paychex_CAID__c = EZOnboardingRegistrationMock.testCaid;
       acct1.EnterpriseBillingId__c = EZOnboardingRegistrationMock.testBillAid;
       acct1.EnterpriseShippingId__c = EZOnboardingRegistrationMock.testShipAid;
       acct1.OSSPartyID__c = EZOnboardingRegistrationMock.ossPartyId;
       acct1.OSSAccountID__c = EZOnboardingRegistrationMock.ossAcctId;
       acct1.OSSBillToSiteID__c = EZOnboardingRegistrationMock.ossBill1;
       acct1.OSSShipToSiteID__c = EZOnboardingRegistrationMock.ossShip2;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update acct1;
        
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);

       Test.startTest();
       EZOnboardingRegistrationMock.acctId1 = acct1.Id;
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.getCPQKeysResp();
       Test.setMock(HttpCalloutMock.class, mockResp);
       EZOnboardingRegistration.BYPASS_QUOTE_CHECK=true;
       cso.TestCPQSub__c=true;
       update cso;
       Test.stopTest();
        
       cso = getTracker(opp.Name);
       Assert.isNotNull(cso.CPQSubStart__c);
       Assert.isNotNull(cso.CPQSubEnd__c);
       Assert.areEqual('200', cso.CPQSubStatusCode__c);

    } // testCpqSub

    static testMethod void testErrorParse() {
       // this is an example response from ECAG 4/24/2023
       String resp='{"instance":"5424eec8-9c9e-4fce-84da-20c42602f952","conflictResources":[{"detail":"Client with this tax ID already exists","key":"ENT-CLIENT-VIOLATION-40","conflictResource":{"links":[{"rel":"matchingClient","href":"https://ent-ose-client-svc-pyx.n2a-lb.paychex.com/clients?ceid=00H2A1IULGQW7QJR0C13"}]},"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/subtypes/ConflictResourceProblemDetails.java"}],"type":"https://code.paychex.com/projects/CORPUTIL/repos/spring-boot-starter-error-handling/browse/src/main/java/com/paychex/corp/springbootstarter/errorhandling/problem/IntegrationConflictProblem.java","title":"Conflicting Integration Request","key":"conflicting.integration.request","retryable":false,"status":409}';
       EZOnboardingRegistration.EntResponse entResp = EntRespHelper.parseOicResponse(null,resp);
       System.debug('entResp='+entResp);
       Assert.areEqual('409', entResp.statusCode);
       Assert.areEqual('ENT-CLIENT-VIOLATION-40', entResp.errCode);
       Assert.isTrue(entResp.errDesc.contains('Client with this tax ID already exists'), entResp.errDesc);
        
    } // testErrorParse
    /*
    static testMethod void testMultiIdGrouping() {
       Account acct1 = getTestAcct(ACCT1);
       Opportunity opp = getTestOpp(OPP1);
       CSO_Tracking__c tracker1 = EZOnboardingRegistration.getTracking(opp.Id);

       Account child1 = new Account(Name='ChildOne', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child2 = new Account(Name='ChildTwo', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child3 = new Account(Name='ChildThree', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child4 = new Account(Name='ChildFour', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child5 = new Account(Name='ChildFive', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child6 = new Account(Name='ChildSix', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child7 = new Account(Name='ChildSeven', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child8 = new Account(Name='ChildEight', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       Account child9 = new Account(Name='ChildNine', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert new Account[]{child1,child2,child3,child4,child5,child6,child7,child8,child9};
           
       Account_Junction__c aj1 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child1.Id, Type__c='Combo');
       Account_Junction__c aj2 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child2.Id, Type__c='Combo');
       Account_Junction__c aj3 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child3.Id, Type__c='Combo');
       Account_Junction__c aj4 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child4.Id, Type__c='Combo');
       Account_Junction__c aj5 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child5.Id, Type__c='Combo');
       Account_Junction__c aj6 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child6.Id, Type__c='Combo');
       Account_Junction__c aj7 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child7.Id, Type__c='Related/Common');
       Account_Junction__c aj8 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child8.Id, Type__c='Related/Common');
       Account_Junction__c aj9 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child9.Id, Type__c='Related/Common');
       insert new Account_Junction__c[]{aj1,aj2,aj3,aj4,aj5,aj6,aj7,aj8,aj9};
           
       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
       quote.cafsl__Account__c = acct1.Id;
       quote.cafsl__Opportunity__c = opp.Id;
       quote.cafsl__Syncing__c = true;
       quote.Name = 'Test Quote';
       quote.Multi_ID__c = true;
       quote.IsSubscriptionQuote__c=true;
       quote.cafsl__Pricebook_Id__c = opp.Pricebook2Id;
       quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert quote;
        
       Product2 quoteProductA = New Product2(Name = 'TestProduct', PayrollFrequency__c = 'Weekly', ProductCode = 'PAY', IsActive = true, CSO_Eligible__c = false);
       insert quoteProductA;
        
       cafsl__Oracle_Quote_Line_Item__c ql0 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct1.Id);
       cafsl__Oracle_Quote_Line_Item__c ql1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child1.Id);
       cafsl__Oracle_Quote_Line_Item__c ql2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child2.Id);
       cafsl__Oracle_Quote_Line_Item__c ql3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child3.Id);
       cafsl__Oracle_Quote_Line_Item__c ql4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child4.Id);
       cafsl__Oracle_Quote_Line_Item__c ql5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child5.Id);
       cafsl__Oracle_Quote_Line_Item__c ql6 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child6.Id);
       cafsl__Oracle_Quote_Line_Item__c ql7 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child7.Id);
       cafsl__Oracle_Quote_Line_Item__c ql8 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child8.Id);
       cafsl__Oracle_Quote_Line_Item__c ql9 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child9.Id);
       insert new cafsl__Oracle_Quote_Line_Item__c[]{ql0,ql1,ql2,ql3,ql4,ql5,ql6,ql7,ql8,ql9};
           
       Test.startTest();
       // this should create child wrappers for the multi-id.
       EZOnboardingRegistration.OppPathWrapper oppWrap = EZOnboardingRegistration.getRegInfo(opp.Id);
       Assert.areEqual(9, oppWrap.childWraps.size());
       Assert.areEqual(9, [Select count() from CSO_Tracking__c where ParentTracker__c=:tracker1.Id]);
       // reparent 2 of the combo ids so we have 2 groups
       // combo1 - acct1 with child1,child2,child3
       // combo2 - child4 a parent with child5,child6
       Id[] acctIds = new Id[]{child5.Id, child6.Id};
       CSO_Tracking__c[] updateTrackers = [Select Id, ParentAccount__c from CSO_Tracking__c where AccountId__c in :acctIds];
       for (CSO_Tracking__c cso : updateTrackers) {
          cso.ParentAccount__c = child4.Id;
       }
       CsoMethods.SKIP_TRIGGERS = true;
       update updateTrackers;

       EZOnboardingRegistration.ClientGroup[] grps = EZOnboardingRegistration.prepareEntRegistrationReq(tracker1.Id);
       Assert.areEqual(5,grps.size());
       Test.stopTest();
    } // testMultiIdGrouping
    */
    static testMethod void testMultiIdGroupingFedId() {
       Account acct1 = getTestAcct(ACCT1);
       Opportunity opp = getTestOpp(OPP1);
       CSO_Tracking__c tracker1 = EZOnboardingRegistration.getTracking(opp.Id);
       
       // first are same fein under the main parent
       Account child1 = new Account(Name='ChildOne', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c=acct1.Federal_Id_Number__c);
       Account child2 = new Account(Name='ChildTwo', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c=acct1.Federal_Id_Number__c);
       // next 5 are parent-child children
       Account child3 = new Account(Name='ChildThree', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431234');
       Account child4 = new Account(Name='ChildFour', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431235');
       Account child5 = new Account(Name='ChildFive', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431236');
       Account child6 = new Account(Name='ChildSix', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431237');
       Account child7 = new Account(Name='ChildSeven', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431238');
       // these 2 are a separate same fein relationship
       Account child8 = new Account(Name='ChildEight', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c='44-1431239');
       Account child9 = new Account(Name='ChildNine', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Federal_Id_Number__c=child8.Federal_Id_Number__c);
       Account child10 = new Account(Name='ChildTen', SalesParent__c=acct1.Id, RecordTypeId=acct1.RecordTypeId, Paychex_CEID__c='testMultiIdGroupCE', Federal_Id_Number__c=child8.Federal_Id_Number__c);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert new Account[]{child1,child2,child3,child4,child5,child6,child7,child8,child9,child10};
           
       // the type doesn't matter for this test
       Account_Junction__c aj1 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child1.Id, Type__c='Combo');
       Account_Junction__c aj2 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child2.Id, Type__c='Combo');
       Account_Junction__c aj3 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child3.Id, Type__c='Combo');
       Account_Junction__c aj4 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child4.Id, Type__c='Combo');
       Account_Junction__c aj5 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child5.Id, Type__c='Combo');
       Account_Junction__c aj6 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child6.Id, Type__c='Combo');
       Account_Junction__c aj7 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child7.Id, Type__c='Related/Common');
       Account_Junction__c aj8 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child8.Id, Type__c='Related/Common');
       Account_Junction__c aj9 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child9.Id, Type__c='Related/Common');
       insert new Account_Junction__c[]{aj1,aj2,aj3,aj4,aj5,aj6,aj7,aj8,aj9};
           
       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
       quote.cafsl__Account__c = acct1.Id;
       quote.cafsl__Opportunity__c = opp.Id;
       quote.cafsl__Syncing__c = true;
       quote.Name = 'Test Quote';
       quote.Multi_ID__c = true;
       quote.IsSubscriptionQuote__c=true;
       quote.cafsl__Pricebook_Id__c = opp.Pricebook2Id;
       quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert quote;
        
       Product2 quoteProductA = New Product2(Name = 'TestProduct', PayrollFrequency__c = 'Weekly', ProductCode = 'PAY', IsActive = true, CSO_Eligible__c = false);
       insert quoteProductA;
        
       // a line for each account so they're all included
       cafsl__Oracle_Quote_Line_Item__c ql0 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct1.Id);
       cafsl__Oracle_Quote_Line_Item__c ql1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child1.Id);
       cafsl__Oracle_Quote_Line_Item__c ql2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child2.Id);
       cafsl__Oracle_Quote_Line_Item__c ql3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child3.Id);
       cafsl__Oracle_Quote_Line_Item__c ql4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child4.Id);
       cafsl__Oracle_Quote_Line_Item__c ql5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child5.Id);
       cafsl__Oracle_Quote_Line_Item__c ql6 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child6.Id);
       cafsl__Oracle_Quote_Line_Item__c ql7 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child7.Id);
       cafsl__Oracle_Quote_Line_Item__c ql8 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child8.Id);
       cafsl__Oracle_Quote_Line_Item__c ql9 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=child9.Id);
       insert new cafsl__Oracle_Quote_Line_Item__c[]{ql0,ql1,ql2,ql3,ql4,ql5,ql6,ql7,ql8,ql9};
           
       Test.startTest();
       // this should create child trackers/wrappers for the multi-id.
       EZOnboardingRegistration.OppPathWrapper oppWrap = EZOnboardingRegistration.getRegInfo(opp.Id);
       Assert.areEqual(9, oppWrap.childWraps.size());
       Assert.areEqual(9, [Select count() from CSO_Tracking__c where ParentTracker__c=:tracker1.Id]);

       EZOnboardingRegistration.ClientGroup[] grps = EZOnboardingRegistration.prepareEntRegistrationReq(tracker1.Id);
       Assert.areEqual(7,grps.size());
       Test.stopTest();
       Set<String> validatedGrps = new Set<String>();
        
       String acct1FedId = EZOnboardingRegistration.formatFedId(acct1.Federal_Id_Number__c);
       String child3FedId = EZOnboardingRegistration.formatFedId(child3.Federal_Id_Number__c);
       String child4FedId = EZOnboardingRegistration.formatFedId(child4.Federal_Id_Number__c);
       String child5FedId = EZOnboardingRegistration.formatFedId(child5.Federal_Id_Number__c);
       String child6FedId = EZOnboardingRegistration.formatFedId(child6.Federal_Id_Number__c);
       String child7FedId = EZOnboardingRegistration.formatFedId(child7.Federal_Id_Number__c);
       String child8FedId = EZOnboardingRegistration.formatFedId(child8.Federal_Id_Number__c);
        
       EZOnboardingRegistration.ClientGroup grp7;
       for (EZOnboardingRegistration.ClientGroup grp : grps) {
          if (grp.parentFedId == acct1FedId) {
             Assert.areEqual(2,grp.children.size());
             validatedGrps.add('Group1');
          } else if (grp.parentFedId == child3FedId) {
             Assert.areEqual(0,grp.children.size());
             validatedGrps.add('Group2');
          } else if (grp.parentFedId == child4FedId) {
             Assert.areEqual(0,grp.children.size());
             validatedGrps.add('Group3');
          } else if (grp.parentFedId == child5FedId) {
             Assert.areEqual(0,grp.children.size());
             validatedGrps.add('Group4');
          } else if (grp.parentFedId == child6FedId) {
             Assert.areEqual(0,grp.children.size());
             validatedGrps.add('Group5');
          } else if (grp.parentFedId == child7FedId) {
             Assert.areEqual(0,grp.children.size());
             validatedGrps.add('Group6');
          } else if (grp.parentFedId == child8FedId) {
             Assert.areEqual(1,grp.children.size());
             validatedGrps.add('Group7');
             grp7 = grp;
          }
       }
       Assert.areEqual(7,validatedGrps.size());
       Assert.isNotNull(grp7);
       
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = mockResp.testOICResponseMultiple;
        
       Test.setMock(HttpCalloutMock.class, mockResp);

       EZOnboardingRegistration.ResponseWrapper resp = EZOnboardingRegistration.sendEntRegRequest(grp7, false);
       // we don't care if the response is successful
       Assert.areEqual(child10.Paychex_CEID__c, EZOnboardingRegistration.testCEID); 
        
    } // testMultiIdGroupingFedId
    
    //Test Custom Message
    Static testMethod void testErrorMessages(){
        String errorMessage = EntRespHelper.checkErrCode('CLIENT-LIST-CONSTRAINT', 'No Message');
        System.assertEquals('Legal Name must be populated on submission. Please update and re-submit.', errorMessage);
        
        errorMessage = EntRespHelper.checkErrCode('Not A Message', 'No Message');
        System.assertEquals('No Message', errorMessage);
        
    } // testErrorMessages
    
    static testMethod void testApprovers() {
       User testUsr = [Select Id, Name, Job_Name__c, Sales_Org__c, Sales_Division__c, Zone__c
                             ,Manager.Name, ManagerId, Manager.Manager.IsActive
                             ,Manager.Manager.Name, Manager.ManagerId, Manager.Manager.EasySetupDelegate__c
                         From User
                        Where IsActive=true and Job_Name__c=:UserHelper.JOB_REP
                          and Manager.Manager.IsActive = true
                         limit 1];
       User runningUser = UserHelper.getRunningUser();
       if (testUsr.Manager.Manager.EasySetupDelegate__c == null) {
          testUsr.Manager.Manager.EasySetupDelegate__c=UserInfo.getUserId();
          User updateUser = new User(Id=testUsr.Manager.ManagerId, EasySetupDelegate__c=UserInfo.getUserId());
          UserHelper.SKIP_USER_TRIGGERS=true;
          update updateUser;
          
       }
       System.runAs(runningUser) {
            
       System.debug('testApprovers testUsr='+testUsr);
       CSO_Tracking__c tracker = new CSO_Tracking__c(IsOppCso__c=true);
       Boolean changed = EZOnboardingRegistration.checkApprovers(tracker, testUsr);
       Assert.areEqual(testUsr.Manager.ManagerId,tracker.ExceptionApprover__c);
       Assert.areEqual(testUsr.Manager.Manager.EasySetupDelegate__c,tracker.ExceptionApprover2__c);
        
       tracker.Product_Bundle__c='Cool Bundle';
       EZOnboardingRegistration.checkExceptionAllowed(tracker, testUsr);
       Assert.isFalse(tracker.ExceptionAllowed__c);
       CsoExceptionSetup__c ces = new CsoExceptionSetup__c(Name='test1', Active__c=true, SalesOrgs__c=testUsr.Sales_Org__c+',AAA', ProductBundle__c='Cool Bundle');
       insert ces;
        
       EZOnboardingRegistration.checkExceptionAllowed(tracker, testUsr);
       Assert.isTrue(tracker.ExceptionAllowed__c);
       Assert.isFalse(tracker.ExceptionNeedApproval__c);
       
       ces.ApprovalProcess__c = true;
       ces.SalesDivisions__c = 'BadDivision';
       update ces;
        
       EZOnboardingRegistration.checkExceptionAllowed(tracker, testUsr);
       Assert.isFalse(tracker.ExceptionAllowed__c);
       Assert.isFalse(tracker.ExceptionNeedApproval__c);
       
       ces.SalesDivisions__c = testUsr.Sales_Division__c+',Other Division';
       update ces;

       EZOnboardingRegistration.checkExceptionAllowed(tracker, testUsr);
       Assert.isTrue(tracker.ExceptionAllowed__c);
       Assert.isTrue(tracker.ExceptionNeedApproval__c);
        
       ces.Zones__c=testUsr.Zone__c+',423';
       update ces;
 
       EZOnboardingRegistration.checkExceptionAllowed(tracker, testUsr);
       Assert.isTrue(tracker.ExceptionAllowed__c);
       Assert.isTrue(tracker.ExceptionNeedApproval__c);
       }

    } // testApprovers
    
    static testMethod void testAddress() {
       for (String poBox : EZOnboardingRegistration.poBoxVariations) {
          String streetAddr = poBox+' 742';
          EZOnboardingRegistration.AddressWrapper addWrap = EZOnboardingRegistration.getAddressWrap(streetAddr);
          Assert.isTrue(addWrap.isPoBox);
          Assert.areEqual('PO BOX 742',addWrap.addressOne,poBox+' '+addWrap.addressOne);
       }
       String streetAddr = '123 Not A PO Box St';
       EZOnboardingRegistration.AddressWrapper addWrap = EZOnboardingRegistration.getAddressWrap(streetAddr);
       Assert.isFalse(addWrap.isPoBox);
       Assert.areEqual(streetAddr,addWrap.addressOne);
        
    } // testAddress
    /*
    static testMethod void testLegalUpdate() {
       Account testAcct = new Account(Name='Legal Account', Paychex_CEID__c=EZOnboardingRegistrationMock.legalUpdateCEID
                                     ,Paychex_CAID__c=EZOnboardingRegistrationMock.legalUpdateCAID
                                     ,LegalAddress__Street__s='123 Any St', LegalAddress__City__s='Rochester', LegalAddress__StateCode__s='NY'
                                     ,LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert testAcct;
       testAcct.Name=EZOnboardingRegistrationMock.legalName;
       testAcct.LegalAddress__Street__s=EZOnboardingRegistrationMock.legalStreet;
       testAcct.LegalAddress__City__s=EZOnboardingRegistrationMock.legalCity;
       testAcct.LegalAddress__StateCode__s=EZOnboardingRegistrationMock.legalState;
       testAcct.LegalAddress__PostalCode__s=EZOnboardingRegistrationMock.legalPostal;
       testAcct.LegalAddress__CountryCode__s=EZOnboardingRegistrationMock.legalCountry;
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name='Test Legal Account', AccountId__c=testAcct.Id);
       insert tracker;
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);

       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.legalUpdateResp;
       Test.setMock(HttpCalloutMock.class, mockResp);

       EZOnboardingRegistration.ResponseWrapper rw = EZOnboardingRegistration.updateLegalInfo(tracker,testAcct);
       Test.stopTest();
       Account checkAcct = [Select Id, Name, Paychex_CEID__c, Paychex_CAID__c
                       ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s
                       ,LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                   From Account where Id=:testAcct.Id limit 1];
       Assert.areEqual(EZOnboardingRegistrationMock.legalName, checkAcct.Name);
       Assert.areEqual(EZOnboardingRegistrationMock.legalStreet, checkAcct.LegalAddress__Street__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCity, checkAcct.LegalAddress__City__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalState, checkAcct.LegalAddress__StateCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalPostal, checkAcct.LegalAddress__PostalCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCountry, checkAcct.LegalAddress__CountryCode__s);

    } // testLegalUpdate
    */
    static testMethod void testLegalUpdate2() {
       Account testAcct = new Account(Name='Legal Account', Paychex_CEID__c=EZOnboardingRegistrationMock.legalUpdateCEID
                                     ,Paychex_CAID__c=EZOnboardingRegistrationMock.legalUpdateCAID
                                     ,LegalAddress__Street__s='123 Any St', LegalAddress__City__s='Rochester', LegalAddress__StateCode__s='NY'
                                     ,LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US');
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert testAcct;
       testAcct.Name=EZOnboardingRegistrationMock.legalName;
       testAcct.LegalAddress__Street__s=EZOnboardingRegistrationMock.legalStreet;
       testAcct.LegalAddress__City__s=EZOnboardingRegistrationMock.legalCity;
       testAcct.LegalAddress__StateCode__s=EZOnboardingRegistrationMock.legalState;
       testAcct.LegalAddress__PostalCode__s=EZOnboardingRegistrationMock.legalPostal;
       testAcct.LegalAddress__CountryCode__s=EZOnboardingRegistrationMock.legalCountry;
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name='Test Legal Account', AccountId__c=testAcct.Id);
       insert tracker;
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);

       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.legalUpdateResp;
       Test.setMock(HttpCalloutMock.class, mockResp);

       EZOnboardingRegistration.ResponseWrapper rw = EZOnboardingRegistration.handleLegalUpdate(tracker.Id,true,true);
       Test.stopTest();
       Account checkAcct = [Select Id, Name, Paychex_CEID__c, Paychex_CAID__c
                       ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s
                       ,LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                   From Account where Id=:testAcct.Id limit 1];
       Assert.areEqual(EZOnboardingRegistrationMock.legalName, checkAcct.Name);
       Assert.areEqual(EZOnboardingRegistrationMock.legalStreet, checkAcct.LegalAddress__Street__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCity, checkAcct.LegalAddress__City__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalState, checkAcct.LegalAddress__StateCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalPostal, checkAcct.LegalAddress__PostalCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCountry, checkAcct.LegalAddress__CountryCode__s);

    } // testLegalUpdate

    // when we go to register a client, the legal address can be automatically registered as a non-legal address.
    // If this registration happens too soon, then the service will get a duplicate address error. When this happens,
    // we should be extracting the address id from the response and updating the account info.
    static testMethod void testNonLegalDuplicate() {
       Account testAcct = new Account(Name='Legal Account', Paychex_CEID__c=null, Paychex_CAID__c=null
                                     ,LegalAddress__Street__s='123 Any St', LegalAddress__City__s='Rochester', LegalAddress__StateCode__s='NY'
                                     ,LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US'
                                     ,BillingUUID__c=EZOnboardingRegistrationMock.sfAddrId, ShippingUUID__c=EZOnboardingRegistrationMock.sfAddrId);
       // have to have the bare information for it to work. 
       testAcct.ShippingStreet='123 Any St';
       testAcct.ShippingCity='Rochester';
       testAcct.ShippingState='NY';
       testAcct.ShippingPostalCode='14624';
       testAcct.ShippingCountry='US';
        
       testAcct.BillingStreet='123 Any St';
       testAcct.BillingCity='Rochester';
       testAcct.BillingState='NY';
       testAcct.BillingPostalCode='14624';
       testAcct.BillingCountry='US';
       // Paychex_CEID__c=EZOnboardingRegistrationMock.legalUpdateCEID
 //                                     ,Paychex_CAID__c=EZOnboardingRegistrationMock.legalUpdateCAID
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert testAcct;
       testAcct.Name=EZOnboardingRegistrationMock.legalName;
       //testAcct.LegalAddress__Street__s=EZOnboardingRegistrationMock.legalStreet;
       //testAcct.LegalAddress__City__s=EZOnboardingRegistrationMock.legalCity;
       //testAcct.LegalAddress__StateCode__s=EZOnboardingRegistrationMock.legalState;
       //testAcct.LegalAddress__PostalCode__s=EZOnboardingRegistrationMock.legalPostal;
       //testAcct.LegalAddress__CountryCode__s=EZOnboardingRegistrationMock.legalCountry;
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name='Test Legal Account', AccountId__c=testAcct.Id);
       insert tracker;
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);

       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.duplicateAddrOnRegister.replace(EZOnboardingRegistrationMock.duplAddrSfId,testAcct.Id);
       Test.setMock(HttpCalloutMock.class, mockResp);

       //EZOnboardingRegistration.ResponseWrapper rw = EZOnboardingRegistration.handleLegalUpdate(tracker.Id,true,true);
       Id[] trackerIds = new Id[]{tracker.Id};
       // need to use a second list because the code clears out ids from the first list as it uses them.
       Id[] trackerIds2 = new Id[]{tracker.Id};
       Id[] emptyList = new Id[]{};
       EnterpriseRegistration entReg = new EnterpriseRegistration(EZOnboardingRegistration.CLT_VALIDATE, trackerIds, emptyList, trackerIds2, trackerIds2);
       EnterpriseRegistration.launchJob(entReg);

       Test.stopTest();
       Account checkAcct = [Select Id, Name, Paychex_CEID__c, Paychex_CAID__c
                       ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s
                       ,LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                       ,EnterpriseAAID__c, EnterpriseClientNumber__c
                       ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                       ,BillingUUID__c, EnterpriseBillingId__c
                       ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                       ,ShippingUUID__c, EnterpriseShippingId__c
                   From Account where Id=:testAcct.Id limit 1];
       //Assert.areEqual(EZOnboardingRegistrationMock.legalName, checkAcct.Name);
       // make sure the legal information is returned and updated
       Assert.areEqual(EZOnboardingRegistrationMock.legalUpdateCEID, checkAcct.Paychex_CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalUpdateCAID, checkAcct.Paychex_CAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalAddrId, checkAcct.EnterpriseAAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.entCltNbr, checkAcct.EnterpriseClientNumber__c);
        
       Assert.areEqual(EZOnboardingRegistrationMock.legalStreet, checkAcct.LegalAddress__Street__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCity, checkAcct.LegalAddress__City__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalState, checkAcct.LegalAddress__StateCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalPostal, checkAcct.LegalAddress__PostalCode__s);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCountry, checkAcct.LegalAddress__CountryCode__s);
        
       // make sure the addresses and ids are returned and updated
       Assert.areEqual(EZOnboardingRegistrationMock.entAddrId, checkAcct.BillingUUID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.entAddrId, checkAcct.EnterpriseBillingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalStreet, checkAcct.BillingStreet);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCity, checkAcct.BillingCity);
       Assert.areEqual(EZOnboardingRegistrationMock.legalState, checkAcct.BillingState);
       Assert.areEqual('14514-1025', checkAcct.BillingPostalCode);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCountry, checkAcct.BillingCountry);
        
       Assert.areEqual(EZOnboardingRegistrationMock.entAddrId, checkAcct.ShippingUUID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.entAddrId, checkAcct.EnterpriseShippingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalStreet, checkAcct.ShippingStreet);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCity, checkAcct.ShippingCity);
       Assert.areEqual(EZOnboardingRegistrationMock.legalState, checkAcct.ShippingState);
       Assert.areEqual('14514-1025', checkAcct.ShippingPostalCode);
       Assert.areEqual(EZOnboardingRegistrationMock.legalCountry, checkAcct.ShippingCountry);

    } // testNonLegalDuplicate
    
    // If the address cannot be verified, but gets a candidate address in return.
    static testMethod void testAddrNotVerified() {
       /*
       Account testAcct = new Account(Name=EZOnboardingRegistrationMock.addrNot_Name, Paychex_CEID__c=null, Paychex_CAID__c=null
                                     ,LegalAddress__Street__s='123 Any St', LegalAddress__City__s='Rochester', LegalAddress__StateCode__s='NY'
                                     ,LegalAddress__PostalCode__s='14624', LegalAddress__CountryCode__s='US'
                                     ,BillingUUID__c=EZOnboardingRegistrationMock.sfAddrId, ShippingUUID__c=EZOnboardingRegistrationMock.addrNot_shipAddrId);
       // have to have the bare information for it to work. 
       testAcct.ShippingStreet='PO BOX 111';
       testAcct.ShippingCity='Rochester';
       testAcct.ShippingState='NY';
       testAcct.ShippingPostalCode='14624';
       testAcct.ShippingCountry='US';
        
       testAcct.BillingStreet='123 Any St';
       testAcct.BillingCity='Rochester';
       testAcct.BillingState='NY';
       testAcct.BillingPostalCode='14624';
       testAcct.BillingCountry='US';
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert testAcct;
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name=testAcct.Name, AccountId__c=testAcct.Id);
       CsoMethods.SKIP_TRIGGERS=true;
       insert tracker;
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);
       */
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account testAcct = getTestAcct(ACCT2);
       testAcct.ShippingUUID__c = EZOnboardingRegistrationMock.addrNot_shipAddrId;
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update testAcct;
       
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c tracker = getTracker(opp.Name);


       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.addrNotVerified.replace(EZOnboardingRegistrationMock.duplAddrSfId,testAcct.Id);
       Test.setMock(HttpCalloutMock.class, mockResp);
       System.debug('testAddrNotVerified before update');
       tracker.EntRegTest__c=true;
       CsoMethods.SKIP_TRIGGERS=false;
       TriggerMethods.clearVariables();
       update tracker;
 
       Test.stopTest();
       Account checkAcct = [Select Id, Name, Paychex_CEID__c, Paychex_CAID__c
                       ,LegalAddress__Street__s, LegalAddress__City__s, LegalAddress__StateCode__s
                       ,LegalAddress__PostalCode__s, LegalAddress__CountryCode__s
                       ,EnterpriseAAID__c, EnterpriseClientNumber__c
                       ,BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry
                       ,BillingUUID__c, EnterpriseBillingId__c
                       ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
                       ,ShippingUUID__c, EnterpriseShippingId__c
                   From Account where Id=:testAcct.Id limit 1];
       //Assert.areEqual(EZOnboardingRegistrationMock.legalName, checkAcct.Name);
       // make sure the legal information is returned and updated
       Assert.areEqual(EZOnboardingRegistrationMock.legalUpdateCEID, checkAcct.Paychex_CEID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalUpdateCAID, checkAcct.Paychex_CAID__c);
       Assert.areEqual(EZOnboardingRegistrationMock.legalAddrId, checkAcct.EnterpriseAAID__c);
        
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_legalStreet, checkAcct.LegalAddress__Street__s);
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_legalCity, checkAcct.LegalAddress__City__s);
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_legalPostal, checkAcct.LegalAddress__PostalCode__s);
        
       // the id should not have changed, the address should have
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_shipAddrId, checkAcct.ShippingUUID__c);
       Assert.IsNull(checkAcct.EnterpriseShippingId__c);
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_shipStreet, checkAcct.ShippingStreet);
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_shipCity, checkAcct.ShippingCity);
       Assert.areEqual(EZOnboardingRegistrationMock.addrNot_shipPostal, checkAcct.ShippingPostalCode);
       
       tracker = [Select Id, RegistrationStatusCode__c from CSO_Tracking__c where Id=:tracker.Id];
       Assert.areEqual('207',tracker.RegistrationStatusCode__c, 'Status Code='+tracker.RegistrationStatusCode__c);
    } // testAddrNotVerified
    
    static testMethod void testAddressCheck() {
       Account acct1 = new Account(Name='Test Account'
                                  ,ShippingStreet=null, ShippingCity='Rochester', ShippingState='NY', ShippingPostalCode='14624', ShippingCountry='US'
                                  ,BillingStreet='123 Main St', BillingCity='Rochester', BillingState='NY', BillingPostalCode='14624', BillingCountry=null
                                 );
       Assert.isFalse(EZOnboardingRegistration.checkShipping(acct1,null));
       Assert.isFalse(EZOnboardingRegistration.checkBilling(acct1,null));
        
       Account acct2 = new Account(Name='Test Account'
                                  ,ShippingStreet='123 Main St', ShippingCity='Rochester', ShippingState='NY', ShippingPostalCode='14624', ShippingCountry='US'
                                  ,BillingStreet='123 Main St', BillingCity='Rochester', BillingState='NY', BillingPostalCode='14624', BillingCountry='US'
                                 );
       Assert.isTrue(EZOnboardingRegistration.checkShipping(acct2,null));
       Assert.isTrue(EZOnboardingRegistration.checkBilling(acct2,null));
       // these should be false since there aren't any changes
       Assert.isFalse(EZOnboardingRegistration.checkShipping(acct2,acct2));
       Assert.isFalse(EZOnboardingRegistration.checkBilling(acct2,acct2));
        
       Account acct = new Account(Name='Test Account'
                                  ,ShippingStreet='123 Main St', ShippingCity='Rochester', ShippingState='NY', ShippingPostalCode='14624', ShippingCountry='US'
                                  ,BillingStreet='123 Main St', BillingCity='Rochester', BillingState='NY', BillingPostalCode='14624', BillingCountry='US'
                                 );
       Account oldAcct=new Account(Name='Test Account'
                                  ,ShippingStreet='123 Main St', ShippingCity='Rochester', ShippingState='NY', ShippingPostalCode='14624', ShippingCountry='US'
                                  ,BillingStreet='123 Main St', BillingCity='Rochester', BillingState='NY', BillingPostalCode='14624', BillingCountry='US'
                                 );
       // False because there aren't any changes
       Assert.isFalse(EZOnboardingRegistration.checkShipping(acct,oldAcct));
       Assert.isFalse(EZOnboardingRegistration.checkBilling(acct,oldAcct));
       
       oldAcct.ShippingStreet='234 Main St';
       oldAcct.BillingState='MA';
       // true because the addresses are different
       Assert.isTrue(EZOnboardingRegistration.checkShipping(acct,oldAcct));
       Assert.isTrue(EZOnboardingRegistration.checkBilling(acct,oldAcct));
       
       
    } // testAddressCheck
    
    static testMethod void testStreetComponents() {
       String componentStr = '{"primaryNumber":"3104","streetName":"PO Box","cityName":"McKinney","defaultCityName":"McKinney","stateAbbreviation":"TX","zipCode":"75070","plus4Code":"8184","deliveryPoint":"04","deliveryPointCheckDigit":"6"}';
       EZOnboardingRegistration.AddrResp addr = new EZOnboardingRegistration.AddrResp();
       EntRespHelper.handleStreetComponents(addr, JSON.deserializeUntyped(componentStr));
	   System.debug('street='+addr.street);
       // this isn't the correct format for a PO box, but it's how the code interprets it
       Assert.areEqual('3104 PO Box', addr.street);
    } // testStreetComponents

    static testMethod void testExtra() {
        EnterpriseRegistration er = new EnterpriseRegistration(EZOnboardingRegistration.REG_CLT_UPDATE, new Id[]{},new Id[]{},new Id[]{});
        er.handleCltUpdate();
    } // testExtra
    
    static testMethod void testAddrIdExists400() {
       // this is what can happen if a client already exists (we have the ceid/caid) and the registration is pushed through again 
       // the address validation will return the address ids.
       Account acct = new Account(Name='Entrepreneur Connect Inc', Paychex_CEID__c='001GJICFLS3S7ZBZPLBC', Paychex_CAID__c='00M9LQF7LRP2IF1L6DGY'
                                 ,Federal_Id_Number__c='72-0592945'
                                 ,LegalAddress__Street__s='1678 US Highway 190', LegalAddress__City__s='Eunice', LegalAddress__StateCode__s='LA'
                                 ,LegalAddress__PostalCode__s='70535', LegalAddress__CountryCode__s='US'
                                 ,BillingStreet='1678 US Highway 190', BillingCity='Eunice', BillingState='LA', BillingPostalCode='70535', BillingCountry='US'
                                 ,BillingUUID__c='6247b000-ee6a-407e-9513-2f112803cc7b' // , EnterpriseBillingId__c='6247b000-ee6a-407e-9513-2f112803cc7b'
                                 ,ShippingStreet='1678 US Highway 190', ShippingCity='Eunice', ShippingState='LA', ShippingPostalCode='70535', ShippingCountry='US'
                                 ,ShippingUUID__c='6247b000-ee6a-407e-9513-2f112803cc7b' // , EnterpriseShippingId__c='6247b000-ee6a-407e-9513-2f112803cc7b'
                                 );
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name='Test Legal Account', AccountId__c=acct.Id);
       insert tracker;
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);

       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.addrIdExists400;
        
       Test.setMock(HttpCalloutMock.class, mockResp);
       System.debug('testOicSubmitMulti set EntRegTest__c');
       TriggerMethods.clearVariables();
       Test.startTest();
       CsoMethods.SKIP_TRIGGERS=false;
       tracker.EntRegTest__c=true;
       update tracker;
       Test.stopTest();
       
       tracker = EZOnboardingRegistration.getTracking(tracker.Id);
       Assert.areEqual('200',tracker.RegistrationStatusCode__c);
       Assert.isTrue(tracker.RegistrationStarted__c);
       
       Account checkAcct = [Select Id, Name, BillingUUID__c, EnterpriseBillingId__c
                                  ,ShippingUUID__c, EnterpriseShippingId__c
                              From Account where Id=:acct.Id];
       Assert.areEqual(checkAcct.BillingUUID__c, checkAcct.EnterpriseBillingId__c);
       Assert.areEqual(checkAcct.ShippingUUID__c, checkAcct.EnterpriseShippingId__c);
       
    } // testAddrIdExists400
    
    static testMethod void testDuplAddr409() {
       CsoMethods.csoPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
       CsoMethods.cltRegAvail = true;
        
       Account acct1 = getTestAcct(ACCT2);
       Account acct2 = getTestAcct(ACCT3);
       // make them same FEIN
       acct1.Federal_Id_Number__c = '453211329';
       acct1.Paychex_CEID__c = '00Z1IQF9HV6OS797ZGXZ';
       acct1.Paychex_CAID__c = '001GJICFLTSSXH33EP5Q';
       acct1.ShippingUUID__c = '8d01031d-46d5-4dfd-83c3-ac6994e2407d';
       acct1.BillingUUID__c = '8d01031d-46d5-4dfd-83c3-ac6994e2407d';
        
       acct2.Federal_Id_Number__c = acct1.Federal_ID_Number__c;
       acct2.Paychex_CEID__c = '00Z1IQF9HV6OS797ZGXZ';
       acct2.Paychex_CAID__c = '001GJICFLTSSXH21E5BC';
       acct2.ShippingUUID__c = '80e0b928-674f-4203-bbd9-1c88ba01c12d';
       acct2.BillingUUID__c = '80e0b928-674f-4203-bbd9-1c88ba01c12d';
       ZipCheckOwner.SKIP_TRIGGERS=true;
       update new Account[]{acct1,acct2};
       
       Opportunity opp = getTestOpp(OPP2);
       CSO_Tracking__c cso = getTracker(opp.Name);

       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
       quote.cafsl__Account__c = acct1.Id;
       quote.cafsl__Opportunity__c = opp.Id;
       quote.cafsl__Syncing__c = true;
       quote.Name = 'Test Quote';
       quote.Multi_ID__c = true;
       quote.IsSubscriptionQuote__c=true;
       quote.cafsl__Pricebook_Id__c = opp.Pricebook2Id;
       quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
       insert quote;
        
       Product2 quoteProductA = New Product2(Name = 'TestProduct', PayrollFrequency__c = 'Weekly', ProductCode = 'PAY', IsActive = true, CSO_Eligible__c = false);
       insert quoteProductA;
        
       cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct1.Id);
       cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id
                                                       , Prospect_Client__c=acct2.Id);
       insert new cafsl__Oracle_Quote_Line_Item__c[]{quoteLine1,quoteLine2};

       Test.startTest();
       EZOnboardingRegistrationMock mockResp = new EZOnboardingRegistrationMock();
       mockResp.responseToUse = EZOnboardingRegistrationMock.addrAlreadyExists409;
        
       Test.setMock(HttpCalloutMock.class, mockResp);
       System.debug('testOicSubmitMulti set EntRegTest__c');
       TriggerMethods.clearVariables();
       CsoMethods.SKIP_TRIGGERS=false;
       cso.EntRegTest__c=true;
       update cso;
       Test.stopTest();

       Account checkAcct1 = [Select Id, Name, BillingUUID__c, EnterpriseBillingId__c
                                  ,ShippingUUID__c, EnterpriseShippingId__c
                              From Account where Id=:acct1.Id];
       Assert.areEqual('dfd2ee1f-686a-4e6f-8461-032d68856656', checkAcct1.EnterpriseBillingId__c);
       Assert.areEqual('dfd2ee1f-686a-4e6f-8461-032d68856656', checkAcct1.BillingUUID__c);
       Assert.areEqual('dfd2ee1f-686a-4e6f-8461-032d68856656', checkAcct1.EnterpriseShippingId__c);
       Assert.areEqual('dfd2ee1f-686a-4e6f-8461-032d68856656', checkAcct1.ShippingUUID__c);

       Account checkAcct2 = [Select Id, Name, BillingUUID__c, EnterpriseBillingId__c
                                  ,ShippingUUID__c, EnterpriseShippingId__c
                              From Account where Id=:acct2.Id];
       Assert.areEqual('db758253-6460-4b17-8293-9010278e164a', checkAcct2.EnterpriseBillingId__c);
       Assert.areEqual('db758253-6460-4b17-8293-9010278e164a', checkAcct2.BillingUUID__c);
       Assert.areEqual('db758253-6460-4b17-8293-9010278e164a', checkAcct2.EnterpriseShippingId__c);
       Assert.areEqual('db758253-6460-4b17-8293-9010278e164a', checkAcct2.ShippingUUID__c);

    } // testDuplAddr409
    
} // class EZOnboardingRegistrationTest