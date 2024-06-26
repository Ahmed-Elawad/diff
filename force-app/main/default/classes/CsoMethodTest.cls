/** Test methods for the CsoMethod and CSOQueueable class
 *
 * History
 * -------
 * 07/12/2022 Jermaine Stukes	Created.
   10/25/2022 Dan Carmen        Additional changes for CSO/Enterprise registraion
   11/18/2022 Dan Carmen        Code for multiple opps with one tracker
   01/30/2023 Dan Carmen        Make sure opp name isn't too long for tracker name
   03/17/2023 Dan Carmen        Add Opportunity Lead Source as a knock out.
   05/22/2023 Dan Carmen        Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
   09/27/2023 Dan Carmen        Logic to handle the Combo field on the onboarding record

*/
@isTest
public class CsoMethodTest {

    @testSetup
    public static void setupData() {
        setupTriggers();
        
        Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=CsoQueueable.CLASSNAME, Active__c=true);
        insert abc;
        
        RecordType__c rt1 = new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_CORE,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE
                                                 ,Sales_Org__c=UserHelper.SO_CORE, UsedInOwnership__c=true, CSORegistration__c=true, EnterpriseRegistration__c=false);
        RecordType__c rt2 = new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_MMS,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS
                                                 ,Sales_Org__c=UserHelper.SO_MMS, UsedInOwnership__c=true, CSORegistration__c=false, EnterpriseRegistration__c=true);
        RecordType__c rt3 = new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_401K,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K
                                                 ,Sales_Org__c=UserHelper.SO_401, UsedInOwnership__c=true, CSORegistration__c=false, EnterpriseRegistration__c=false);
        insert new RecordType__c[]{rt1,rt2,rt3};
        RecordTypeHelperTest.setupRecordType();

        //Add Knockouts
        CsoKnockouts__c cannibis = new CsoKnockouts__c(Active__c = true, Name='CRB/MRB', ApiName__c='Restricted_Industry__c',FieldValue__c='CRB/MRB',Account_Knockout__c=true,Outcome__c='Cannabis Industry');
        CsoKnockouts__c returningLc = new CsoKnockouts__c(Active__c = true, Name='Returning Lost Client', ApiName__c='Returning_Lost_Client__c',FieldValue__c='true',isBoolean__c=true,Opportunity_Knockout__c=true,Outcome__c='Returning Lost Client');
        CsoKnockouts__c leadSource = new CsoKnockouts__c(Active__c = true, Name='LeadSource', ApiName__c='LeadSource',FieldValue__c=null,isBoolean__c=true,Opportunity_Knockout__c=true,Outcome__c='Bad Lead Source');
        CsoKnockouts__c[] csoKOs = new CsoKnockouts__c[]{cannibis,returningLc,leadSource};
        insert csoKOs;
        //Add Errors
        CSOErrorCodes__c CLIENT_CONSTRAINT = new CSOErrorCodes__c(Name='CLIENT-LIST-CONSTRAINT',Error_Code__c='CLIENT-LIST-CONSTRAINT',Error_Message__c='Legal Name must be populated on submission. Please update and re-submit.',Display_Message__c=true);
       	insert CLIENT_CONSTRAINT;
        //Create Account and contacts
        CreateTestData.createTestAandC();
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
        OracleQuoteTriggerPayxHelperTest.setupMapping();
        
        Account acct = new Account(Name='Test Account');
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert acct;
        
        Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtMMS = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
        
        Opportunity opp1 = new Opportunity(Name='Test MMS Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtMMS.getRecordTypeId());
        OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
        insert opp1;
        
        CSO_Tracking__c tracker = new CSO_Tracking__c(Name='MMS Opp', AccountId__c=acct.Id, Opportunity__c=opp1.Id);
        CsoMethods.SKIP_TRIGGERS=true;
        insert tracker;
        CsoMethods.SKIP_TRIGGERS=false;
        
        opp1.ClientTracking__c=tracker.Id;
        opp1.ClientRegistrationType__c=CsoMethods.TYPE_ENT;
        update opp1;
        OpptyMethods.SKIP_OPPTY_TRIGGERS=false;

    } //setupData
    
    public static Opportunity getMMSOpp() {
       Opportunity opp = [Select Id, Name, AccountId, Account.Name, Account.Id
                                ,ClientTracking__c
                            From Opportunity
                           Where Name='Test MMS Opp' limit 1];
       return opp;
    } // getMMSOpp
    
    public static void setupTriggers() {
        //Create Trigger Method 
        TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'CsoMethods'});
        TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'CsoMethods'});
        TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'CsoMethods'});
        TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, new String[]{'CsoMethods'});
        TriggerMethodsTest.createTriggerSetting('CsoTrigger', true, true, false, false, new String[]{'CsoMethods'});
        TriggerMethodsTest.saveSetupClasses();

    } // setupTriggers

    Static testMethod void testOpportunityInsert(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        
        Account acct = CreateTestData.getTestAcct1();
        Contact ct1 = acct.Contacts[0];
        //Test new opportunity, verify CSO record is created
        //Contact ct1 = [Select Id, Name, Account.Name, Account.Id from Contact where Email=:'fLast1@abc.com'];
        System.debug('testOpportunityInsert before startTest');
        test.startTest();
        Id opptyId = CreateTestData.createTestCoreOptys(acct.Id, ct1.Id);
        test.stopTest();
        System.debug('testOpportunityInsert after stopTest');
        CSO_Tracking__c[] csoList = [Select Id, AccountId__c, CanUseCSO__c, Contact__c, Opportunity__c  
                                           ,Account_Eligible__c, AccountLastChecked__c, OpportunityLastChecked__c, OpportunityFieldsValidated__c, Opportunity_Eligible__c
                                       from CSO_Tracking__c where Opportunity__c=:opptyId];
        
        //Verify CSO Record is created
        System.assertEquals(1, csoList.size());
        CSO_Tracking__c cso = csoList[0];
        System.assertEquals(true, cso.CanUseCSO__c);
        System.assertEquals(acct.Id, cso.AccountId__c);
        
        Opportunity opp = [Select Id, Name, ClientTracking__c, ClientRegistrationType__c
                                 ,Account.Id
                                 ,Account.ClientRegistrationStatus__c
                             From Opportunity
                            Where Id=:opptyId];
        System.assertEquals(CsoMethods.TYPE_CSO, opp.ClientRegistrationType__c);
        System.assertEquals(cso.Id, opp.ClientTracking__c);
        System.assertEquals(CsoMethods.TYPE_CSO, opp.Account.ClientRegistrationStatus__c);
        System.assertEquals(true, cso.Account_Eligible__c);
        Assert.isNotNull(cso.AccountLastChecked__c);
        Assert.isNotNull(cso.OpportunityLastChecked__c);
        System.assertEquals(true, cso.OpportunityFieldsValidated__c);
        System.assertEquals(false, cso.Opportunity_Eligible__c);
        
        Account updateAcct = new Account(Id=acct.Id);
        updateAcct.ShippingCity = 'Somecity';
        updateAcct.ShippingStreet = '123 Main St';
        updateAcct.ShippingState = 'NY';
        updateAcct.ShippingPostalCode = '14624';
        updateAcct.Federal_ID_Number__c = '37-4212345';
        update updateAcct;

        csoList = [Select Id, AccountId__c, CanUseCSO__c, Contact__c, Opportunity__c  
                                           ,Account_Eligible__c, AccountLastChecked__c, OpportunityLastChecked__c, OpportunityFieldsValidated__c, Opportunity_Eligible__c
                                       from CSO_Tracking__c where Opportunity__c=:opptyId];
        cso = csoList[0];
        System.assertEquals(true, cso.Account_Eligible__c);
        System.assertNotEquals(null, cso.AccountLastChecked__c);
        System.assertNotEquals(null, cso.OpportunityLastChecked__c);
        System.assertEquals(true, cso.OpportunityFieldsValidated__c);

    } // testOpportunityInsert
    
    static testMethod void testPermission() {
        CustomPermission cp = null;
        // find a permission and make sure the running user doesn't have access
        for (CustomPermission checkCp : [Select Id, DeveloperName from CustomPermission where NamespacePrefix=null]) {
            if (!FeatureManagement.checkPermission(checkCp.DeveloperName)) {
               cp = checkCp;
               break;
            }
        } // for (CustomPermission checkCp
        System.debug('testPermission cp='+cp);
        System.assertNotEquals(null, cp);
        CsoMethods.csoPerm = cp.DeveloperName;
        
        PermissionSet ps = new PermissionSet( Name = 'CustomPermissionEnabled',  Label = 'Custom Permisison Enabled' );
        insert ps;
        
        SetupEntityAccess sea = new SetupEntityAccess(ParentId = ps.Id, SetupEntityId = cp.Id);

        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = UserInfo.getUserId(),  PermissionSetId = ps.Id );    
        
        Test.startTest();
        insert new List<SObject>{ sea, psa };
        Test.stopTest();
        
        User runningUser = new User(Id=UserInfo.getUserId());
        System.runAs(runningUser) {
           Assert.isTrue(FeatureManagement.checkPermission(cp.DeveloperName));
           Set<String> permSet = CsoMethods.doesUserHavePermission(new Id[]{UserInfo.getUserId()}, new String[]{cp.DeveloperName}); 
           String permKey=UserInfo.getUserId()+cp.DeveloperName;
           Assert.isTrue(permSet.contains(permKey));
        } // System.runAs
           
    } // testPermission

    Static testMethod void testOpportunityInsertMultiple() {
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        
        Account acct1 = CreateTestData.getTestAcct1();
        Account acct2 = CreateTestData.getTestAcct2();
        Account acct3 = CreateTestData.getTestAcct('Test Prospect1');
        Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtCore = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
        Schema.RecordTypeInfo rtMMS = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
        Schema.RecordTypeInfo rt401 = byNameMap.get(OpportunityCreateCase.RT_OPPTY_401K);
        
        Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtCore.getRecordTypeId());
        Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtMMS.getRecordTypeId());
        // this should not create a CSO record
        Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rt401.getRecordTypeId());
        
        Test.startTest();
        insert new Opportunity[]{opp1,opp2,opp3};
        Test.stopTest();
        
        Id[] acctIds = new Id[]{acct1.Id,acct2.Id,acct3.Id};
        CSO_Tracking__c[] csoList = [Select Id, AccountId__c, CanUseCSO__c, Contact__c, Opportunity__c  
                                           ,AccountId__r.Id, AccountId__r.ClientRegistrationStatus__c
                                           ,Opportunity__r.Id, Opportunity__r.ClientTracking__c, Opportunity__r.ClientRegistrationType__c
                                       from CSO_Tracking__c
                                      Where AccountId__c in :acctIds];
        System.assertEquals(2,csoList.size());
        Boolean opp1Found = false;
        Boolean opp2Found = false;
        for (CSO_Tracking__c cso : csoList) {
            if (cso.Opportunity__c == opp1.Id) {
               opp1Found = true;
               System.assertEquals(CsoMethods.TYPE_CSO, cso.Opportunity__r.ClientRegistrationType__c);
               System.assertEquals(cso.Id, cso.Opportunity__r.ClientTracking__c);
               System.assertEquals(CsoMethods.TYPE_CSO, cso.AccountId__r.ClientRegistrationStatus__c);
            } else if (cso.Opportunity__c == opp2.Id) {
               opp2Found = true;
               System.assertEquals(CsoMethods.TYPE_ENT, cso.Opportunity__r.ClientRegistrationType__c);
               System.assertEquals(cso.Id, cso.Opportunity__r.ClientTracking__c);
               System.assertEquals(CsoMethods.TYPE_ENT, cso.AccountId__r.ClientRegistrationStatus__c);
            }
        } // for (CSO_Tracking__c cso : csoList
        System.assertEquals(true,opp1Found);
        System.assertEquals(true,opp2Found);
    } // testOpportunityInsertMultiple
    
    Static testMethod void testOpportunityInsertMultipleOneAcct() {
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        
        Account acct1 = CreateTestData.getTestAcct1();

        Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtCore = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
        Schema.RecordTypeInfo rtMMS = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
        Schema.RecordTypeInfo rt401 = byNameMap.get(OpportunityCreateCase.RT_OPPTY_401K);
        
        Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtCore.getRecordTypeId());
        Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtMMS.getRecordTypeId());
        Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rt401.getRecordTypeId());
        
        Test.startTest();
        insert new Opportunity[]{opp1,opp2,opp3};
        Test.stopTest();
        
        CSO_Tracking__c[] csoList = [Select Id, AccountId__c, CanUseCSO__c, Contact__c, Opportunity__c  
                                           ,AccountId__r.Id, AccountId__r.ClientRegistrationStatus__c
                                           ,Opportunity__r.Id, Opportunity__r.ClientTracking__c, Opportunity__r.ClientRegistrationType__c
                                       from CSO_Tracking__c
                                      where AccountId__c = :acct1.Id];
        System.assertEquals(1,csoList.size());
        
    } // testOpportunityInsertMultipleOneAcct
    
    Static testMethod void testOpportunityKnockoutsandException(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        //Test new opportunity, verify CSO record is created
        Contact ct1 = [Select Id, Name, Account.Name, Account.Id from Contact where Email=:'fLast1@abc.com'];
        test.startTest();
        Id opptyId = CreateTestData.createTestCoreOptys(ct1.Account.Id, ct1.Id);
        
        Opportunity opptyTest = [Select Id, Returning_Lost_Client__c from Opportunity where Id=:opptyId];
        opptyTest.Returning_Lost_Client__c = True;
        TriggerMethods.clearVariables();
        update opptyTest;
        
        CSO_Tracking__c csoRec = [Select Id,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //Verify Knockout is recorded
        System.assertEquals(false, csoRec.OpportunityFieldsValidated__c);
        System.assertEquals('Returning Lost Client', csoRec.OpportunityEligibilityDetail__c);
        //Remove Knockout
        opptyTest.Returning_Lost_Client__c = False;
        TriggerMethods.clearVariables();
        update opptyTest;
        CSO_Tracking__c csoRec2 = [Select Id,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //Verify Knockout is removed
        System.assertEquals(true, csoRec2.OpportunityFieldsValidated__c);
        System.assertNotEquals('Returning Lost Client', csoRec2.OpportunityEligibilityDetail__c);
        //Add exception
        System.assert(csoRec2.CsoExceptionDate__c==null);
        csoRec2.CsoException__c = true;
        csoRec2.CsoExceptionList__c = 'Acquisition';
        TriggerMethods.clearVariables();
        update csoRec2;
        test.stopTest(); 
        CSO_Tracking__c csoRec3 = [Select Id,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        System.assertEquals(true, csoRec3.CsoException__c);
           
    } // testOpportunityKnockoutsandException
    
    Static testMethod void testOppLeadSourceKO(){
        CsoMethods.leadSourceKOs = new String[]{'KO Lead Source','Not So Good Lead Source'};
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        //Test new opportunity, verify CSO record is created
        Contact ct1 = [Select Id, Name, Account.Name, Account.Id from Contact where Email=:'fLast1@abc.com'];
        test.startTest();
        Id opptyId = CreateTestData.createTestCoreOptys(ct1.Account.Id, ct1.Id);
        
        Opportunity opptyTest = [Select Id, LeadSource from Opportunity where Id=:opptyId];
        opptyTest.LeadSource = 'KO Lead Source';
        TriggerMethods.clearVariables();
        update opptyTest;
        
        CSO_Tracking__c csoRec = [Select Id,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //Verify Knockout is recorded
        Assert.isFalse(csoRec.OpportunityFieldsValidated__c);
        Assert.areEqual('Bad Lead Source', csoRec.OpportunityEligibilityDetail__c);
        //Remove Knockout
        opptyTest.LeadSource = 'Good Lead Source';
        TriggerMethods.clearVariables();
        update opptyTest;
        CSO_Tracking__c csoRec2 = [Select Id,OpportunityFieldsValidated__c,OpportunityEligibilityDetail__c,CsoExceptionDate__c,CsoException__c,CsoExceptionList__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //Verify Knockout is removed
        Assert.isTrue(csoRec2.OpportunityFieldsValidated__c);
        Assert.isNull(csoRec2.OpportunityEligibilityDetail__c);
           
    } // testOppLeadSourceKO
    
    //Test Quote
    Static testMethod void testOpportunityQuote(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        Contact ct1 = [Select Id, Name, AccountId, Account.Name, Account.Id from Contact where Email=:'fLast1@abc.com'];
        //test.startTest();
    
        //New Quote
        Pricebook2 pb1 = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
        insert pb1; 
        // create the default product
        PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Unknown-PAY'},UserHelper.SO_CORE,pb1);
        PricebookEntry entryUnknownPay = entries[0];
        entryUnknownPay.Product2.Is_Default_Product__c=true;
        update entryUnknownPay.Product2;
        pb1.DefaultProduct__c = entryUnknownPay.Product2.Id;
        update pb1;
        Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
        Opportunity opp1 = new Opportunity(Name='Opp Test 1', AccountId=ct1.AccountId, CloseDate=Date.today().addDays(7), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
        Utilities.SKIP_FUTURE=true;
        insert opp1;
        CSO_Tracking__c tracker = [Select Id, Name from CSO_Tracking__c where Opportunity__c=:opp1.Id];
        
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opp1.AccountId;
        quote.cafsl__Opportunity__c = opp1.Id;
        quote.cafsl__Syncing__c = true;
        quote.IsSubscriptionQuote__c=true;
        quote.Name = 'Test Quote';
        quote.Multi_ID__c = true;
        quote.cafsl__Pricebook_Id__c = opp1.Pricebook2Id;
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true, CSO_Eligible__c = false);
        insert quoteProductA;
        
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProductA.Id, cafsl__Oracle_Quote__c = quote.Id, Prospect_Client__c=ct1.Account.Id);
        insert quoteLine1;
        // to trigger the logic - we want the quote line already there
        //quote.IsSubscriptionQuote__c=true;
        //quote.cafsl__Syncing__c=true;
        //update quote;
        
    } // testOpportunityQuote
    
    Static testMethod void testOpportunityEligible(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        //Test new opportunity, verify CSO record is created
        Account acct1 = [Select Id, Name,(Select Id from Contacts),Restricted_Industry__c from Account where Name=:'Test Account1' limit 1];
        acct1.Restricted_Industry__c = null;
        acct1.ShippingStreet = '505 Lincoln Place';
        acct1.ShippingCity = 'Brooklyn';
        acct1.ShippingState = 'NY';
        acct1.ShippingPostalCode = '11238';
        acct1.Federal_ID_Number__c = '12-3456789';
        update acct1;
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true, CSO_Eligible__c = true);
        insert quoteProductA;
        Id spricebookId = Test.getStandardPricebookId();
        PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductA.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
        insert spbe1;
        PriceBookEntry[] pbe = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id =:spbe1.Id];
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Sold'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = spricebookId
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);
        insert opptyA;
        CSO_Tracking__c tracker = [Select Id, Name
                                     From CSO_Tracking__c
                                    Where Opportunity__c=:opptyA.Id];
        
        //New Quote
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.cafsl__Syncing__c=true;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        quote.IsSubscriptionQuote__c=true;
        insert quote;
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductA.Id, cafsl__Pricebook_Entry__c = spbe1.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        quoteLine1.cafsl__Quantity__c=1;
        insert quoteLine1;
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        quote.Multi_ID__c = true;
        update quote;

    } // testOpportunityEligible
    
    //Test Account Knockouts
    Static testMethod void testAccountKnockouts(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        test.startTest();
        Account acct1 = [Select Id, Name,(Select Id from Contacts),Restricted_Industry__c from Account where Name=:'Test Account1' limit 1];
        acct1.Restricted_Industry__c = 'CRB/MRB';
        update acct1;
        Id conID = acct1.Contacts[0].Id;
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, conID);
        test.stopTest(); 
        CSO_Tracking__c csoRec = [Select Id,Account_Eligible__c,Opportunity_Eligible__c,AccountKnockout__c,AccountKnockoutDetail__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        System.assertEquals(false, csoRec.Account_Eligible__c);
        System.assertEquals(false, csoRec.Opportunity_Eligible__c);
        System.assertEquals(true, csoRec.AccountKnockout__c);
        System.assert(csoRec.AccountKnockoutDetail__c.contains('Cannabis Industry'));
        //Remove Knockouts
        acct1.Restricted_Industry__c = null;
        acct1.ShippingStreet = '505 Lincoln Place';
        acct1.ShippingCity = 'Brooklyn';
        acct1.ShippingState = 'NY';
        acct1.ShippingPostalCode = '11238';
        acct1.Federal_ID_Number__c = '12-3456789';
        TriggerMethods.clearVariables();
        update acct1;
        CSO_Tracking__c csoRec2 = [Select Id,Account_Eligible__c,Opportunity_Eligible__c,AccountKnockout__c,AccountKnockoutDetail__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        System.assertEquals(true, csoRec.AccountKnockout__c);
        // make sure Cannabis is no longer in the knockout
        System.debug('testAccountKnockouts csoRec2='+csoRec2);
        System.assertEquals(true,(csoRec2.AccountKnockoutDetail__c==null || !csoRec2.AccountKnockoutDetail__c.contains('Cannabis Industry')));
    } // testAccountKnockouts
    
    //Test Contact Change
    Static testMethod void testContactUpdate(){
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        Account acct1 = CreateTestData.getTestAcct1();
        Contact ct1 = acct1.Contacts[0];
        if (acct1.SignificantContact__c != ct1.Id) {
           acct1.SignificantContact__c = ct1.Id;
           ZipCheckOwner.SKIP_TRIGGERS=true;
           update acct1;
           ZipCheckOwner.SKIP_TRIGGERS=false;
        }
        ct1.Email = null;
        update ct1;
        Test.startTest();
        Id opptyId = CreateTestData.createTestCoreOptys(acct1.Id, ct1.Id);
        Test.stopTest();
        // we aren't tracking this as a knockout
        //CSO_Tracking__c csoRec = [Select Id,Account_Eligible__c,Opportunity_Eligible__c,AccountKnockout__c,AccountKnockoutDetail__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //System.assertEquals(true, csoRec.AccountKnockoutDetail__c.contains('Significant Contact Email is blank'));
        //ct1.Email = 'testing@test.com';
        //update ct1;
        //CSO_Tracking__c csoRec2 = [Select Id,Account_Eligible__c,Opportunity_Eligible__c,AccountKnockout__c,AccountKnockoutDetail__c from CSO_Tracking__c where Opportunity__c=:opptyId];
        //System.assertEquals(false, csoRec2.AccountKnockoutDetail__c.contains('Significant Contact Email is blank'));
    } // testContactUpdate
    
    static testMethod void testMultipleOppsOneTracker() {
       Account acct = CreateTestData.getTestAcct1();
       // we just want to create records manually for test purposes
       CsoMethods.SKIP_TRIGGERS=true;
       Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
       Schema.RecordTypeInfo oppRt = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
       Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct.Id, RecordTypeId=oppRt.getRecordTypeId(), StageName=Label.OppStage_Qualified, CloseDate=Date.today().addDays(7), ClientRegistrationType__c=CsoMethods.TYPE_CSO);
       Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct.Id, RecordTypeId=oppRt.getRecordTypeId(), StageName=Label.OppStage_Qualified, CloseDate=Date.today().addDays(7), ClientRegistrationType__c=CsoMethods.TYPE_CSO);
       Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct.Id, RecordTypeId=oppRt.getRecordTypeId(), StageName=Label.OppStage_Qualified, CloseDate=Date.today().addDays(7), ClientRegistrationType__c=CsoMethods.TYPE_CSO);
       Opportunity opp4 = new Opportunity(Name='Opp4', AccountId=acct.Id, RecordTypeId=oppRt.getRecordTypeId(), StageName=Label.OppStage_Qualified, CloseDate=Date.today().addDays(7), ClientRegistrationType__c=null);
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       insert new Opportunity[]{opp1,opp2,opp3,opp4};
          
       CSO_Tracking__c csoRec = new CSO_Tracking__c(Name='Test Tracker', AccountId__c=acct.Id, Opportunity__c=opp4.Id);
       insert csoRec;
        
       opp1.ClientTracking__c = csoRec.Id;
       opp2.ClientTracking__c = csoRec.Id;
       opp3.ClientTracking__c = csoRec.Id;
       update new Opportunity[]{opp1,opp2,opp3};
       
       OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
       CsoMethods.SKIP_TRIGGERS=false;
       opp2.StageName = Label.OppStage_Gained_Access;
       System.debug('testMultipleOppsOneTracker before update oppp2');
       update opp2;
        
       csoRec = [Select Id, Opportunity__c from CSO_Tracking__c where Id=:csoRec.Id];
       System.assertEquals(opp2.Id, csoRec.Opportunity__c);
       
       TriggerMethods.clearVariables();    
       opp3.StageName = Label.OppStage_Discovery;
       update opp3;

       csoRec = [Select Id, Opportunity__c from CSO_Tracking__c where Id=:csoRec.Id];
       System.assertEquals(opp3.Id, csoRec.Opportunity__c);
        
       opp3.StageName = Label.OppStage_Lost;
       opp1.StageName = Label.OppStage_Gained_Access;
       opp2.Amount = 500;
       update new Opportunity[]{opp1,opp2,opp3};

       csoRec = [Select Id, Opportunity__c from CSO_Tracking__c where Id=:csoRec.Id];
       System.assertEquals(opp2.Id, csoRec.Opportunity__c);

    } // testMultipleOppsOneTracker
    
    static testMethod void testOnboardingCase() {
       Account acct = CreateTestData.getTestAcct1();
       Contact ctct = acct.Contacts[0];
       // we just want to create records manually for test purposes
       CsoMethods.SKIP_TRIGGERS=true;
       Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
       Schema.RecordTypeInfo oppRt = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
       Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct.Id, RecordTypeId=oppRt.getRecordTypeId(), StageName=Label.OppStage_Qualified
                                            , CloseDate=Date.today().addDays(7), ClientRegistrationType__c=CsoMethods.TYPE_CSO, LeverageSST__c=true);
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       insert new Opportunity[]{opp1};
          
       CSO_Tracking__c tracker = new CSO_Tracking__c(Name='Test Tracker', AccountId__c=acct.Id, Contact__c=ctct.Id, Opportunity__c=opp1.Id, IsOppEnterprise__c=true);
       CsoMethods.SKIP_TRIGGERS=false;
       insert tracker;
        
       opp1.ClientTracking__c = tracker.Id;
       update new Opportunity[]{opp1};
           
       //Onboarding_Tool__c onbTool = new Onboarding_Tool__c(Name=acct.Name, AccountId__c=acct.Id, Company_Contact__c=ctct.Id, Opportunity_Id__c=opp1.Id);
       //insert onbTool;
       
       //tracker.Onboarding_Tool__c = onbTool.Id;
       Onboarding_Tool__c[] onbTools = [Select Id from Onboarding_Tool__c where Opportunity_Id__c=:opp1.Id];
       Assert.areEqual(1,onbTools.size());
       tracker.RegistrationStarted__c = true;
       tracker.RegistrationStartedBy__c = UserInfo.getUserId();
       
       TriggerMethods.clearVariables();
       CsoMethods.SKIP_TRIGGERS=false;
       Test.startTest();
       update tracker;
       Test.stopTest();
       Group ownerQueue = new UserHelper().getQueue(Label.CTT_Queue);

       Case onbCase = [Select Id, AccountId, ContactId, RecordType.Name, OwnerId, Opportunity__c
                         From Case
                        Where Opportunity__c=:opp1.Id];
       Assert.areEqual(ownerQueue.Id,onbCase.OwnerId);
       Assert.areEqual(Label.CTT_Case_RecordType,onbCase.RecordType.Name);
       Assert.areEqual(acct.Id, onbCase.AccountId);
       Assert.areEqual(ctct.Id, onbCase.ContactId);
        
       Reference_CTT__c refCtt = [Select Id, OwnerId, Case__c, Prospect_Client__c, Status__c
                                        ,Onboarding_Tool__c, Ready_to_be_Worked__c
                                    From Reference_CTT__c
                                   Where Opportunity__c=:opp1.Id];
       Assert.areEqual(ownerQueue.Id,refCtt.OwnerId);
       Assert.areEqual(onbCase.Id, refCtt.Case__c);
       Assert.areEqual(acct.Id, refCtt.Prospect_Client__c);
       Assert.areEqual(onbTools[0].Id, refCtt.Onboarding_Tool__c);
       Assert.isTrue(refCtt.Ready_to_be_Worked__c);
       Assert.areEqual('Submitted to CTT',refCtt.Status__c);
    } // testOnboardingCase

    static testMethod void testMisc() {
       Account acct1 = new Account(Name='Test Acct', Federal_ID_Number__c='12-3456789');
       Assert.isFalse(CsoMethods.validationfieldChanged(acct1, acct1));
       Account acct2 = new Account(Name='Test Acct', Federal_ID_Number__c='12-3456790');
       Assert.isTrue(CsoMethods.validationfieldChanged(acct1, acct2));
        
       String query = CsoMethods.getQuery(CsoMethods.QUERY_ACCT_MULTI);
    } // testMisc
    
    static testMethod void testMultiId() {
        CsoMethods.csoPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
        CsoMethods.cltRegAvail = true;
        
        Account acct1 = CreateTestData.getTestAcct1();
        Account updateAcct = new Account(Id=acct1.Id, Federal_Id_Number__c='41-3152353');
        ZipCheckOwner.SKIP_TRIGGERS=true;
        update updateAcct;
        
        Account child1 = new Account(Name='Child Acct1', RecordTypeId=acct1.RecordTypeId
						  ,NumberOfEmployees=14, Employees__c=14, SalesParent__c=acct1.Id, Create_Junction__c=true, Federal_Id_Number__c=null);
        Account child2 = new Account(Name='Child Acct2', RecordTypeId=acct1.RecordTypeId
						  ,NumberOfEmployees=15, Employees__c=15, SalesParent__c=acct1.Id, Create_Junction__c=true, Federal_Id_Number__c=null);
        insert new Account[]{child1,child2};

        Account_Junction__c aj1 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child1.Id, SalesParentChild__c=true, Type__c='Combo');
        Account_Junction__c aj2 = new Account_Junction__c(Parent_Account__c=acct1.Id, Child_Account__c=child2.Id, SalesParentChild__c=true, Type__c='Combo');
        insert new Account_Junction__c[]{aj1,aj2};

        Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
        Schema.RecordTypeInfo rtMMS = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
        
        Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, CloseDate=Date.today().addDays(14), StageName='Pending', RecordTypeId=rtMMS.getRecordTypeId());
        insert opp1;

        CSO_Tracking__c[] trackings = [Select Id,Environment__c, IsOppCso__c,IsOppEnterprise__c from CSO_Tracking__c where Opportunity__c=:opp1.Id];
        Assert.areEqual(1,trackings.size());
        CSO_Tracking__c parentTracker = trackings[0];
        
        // create the child trackers (which should create the child onboardings)
        CSO_Tracking__c childTrack1 = new CSO_Tracking__c(AccountId__c=child1.Id, Name=child1.Name, ParentAccount__c=acct1.Id, ParentTracker__c=parentTracker.Id, Environment__c=parentTracker.Environment__c, IsOppCso__c=parentTracker.IsOppCso__c,IsOppEnterprise__c=parentTracker.IsOppEnterprise__c, ChildType__c='Sales Parent-Child');
        CSO_Tracking__c childTrack2 = new CSO_Tracking__c(AccountId__c=child2.Id, Name=child2.Name, ParentAccount__c=acct1.Id, ParentTracker__c=parentTracker.Id, Environment__c=parentTracker.Environment__c, IsOppCso__c=parentTracker.IsOppCso__c,IsOppEnterprise__c=parentTracker.IsOppEnterprise__c, ChildType__c='Sales Parent-Child');
        CsoMethods.SKIP_TRIGGERS=false;
        TriggerMethods.clearVariables();
        insert new CSO_Tracking__c[]{childTrack1,childTrack2};
        
        Onboarding_Tool__c parentOnboarding = [Select Id, Combo__c
                                                 From Onboarding_Tool__c
                                                WHere AccountId__c=:acct1.Id];
        Assert.isNull(parentOnboarding.Combo__c);
        
        childTrack1.ChildType__c = 'Combo';
        CsoMethods.SKIP_TRIGGERS=false;
        TriggerMethods.clearVariables();
        update childTrack1;
        
        parentOnboarding = [Select Id, Combo__c
                                                 From Onboarding_Tool__c
                                                WHere AccountId__c=:acct1.Id];
        Assert.areEqual('Yes',parentOnboarding.Combo__c);

    } // testMultiId
    
    Static testMethod void testSubscriptionSoldStarted(){
        //Test new opportunity, verify CSO record is created
        Account acct1 = [Select Id, Name,(Select Id from Contacts),Restricted_Industry__c from Account where Name=:'Test Account1' limit 1];
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true, CSO_Eligible__c = true);
        insert quoteProductA;
        Id spricebookId = Test.getStandardPricebookId();
        PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductA.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
        insert spbe1;
        PriceBookEntry[] pbe = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id =:spbe1.Id];
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acct1.id
                                             ,StageName='Sold'
                                             ,OpportunityType__c='Payroll'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = spricebookId
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);
        insert opptyA;
        //New Quote
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.IsSubscriptionQuote__c=true;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductA.Id, cafsl__Pricebook_Entry__c = spbe1.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        insert quoteLine1;
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;

        Assert.areEqual(1,[Select count() from Opportunity where Id=:opptyA.Id and IsPrimaryQuoteSubscription__c=true]);
        opptyA.StageName = Label.OppStage_Sold_Submitted;
        opptyA.Probability = CsoMethods.probSoldSubmit;
        update opptyA;
        
    } // testOpportunityEligible
    
    static testMethod void testRegField() {
       executeTestField('EntRegTest__c');
    }
    
    static testMethod void testKeyField() {
       executeTestField('TestOSSKeys__c');
    }

    static testMethod void testCpqKeysField() {
       executeTestField('TestCPQKeys__c');
    }

    static testMethod void testCpqSubField() {
       executeTestField('TestCPQSub__c');
    }

    static testMethod void testCltValField() {
       executeTestField('TestClientValidation__c');
    }

    static testMethod void testBillValField() {
       executeTestField('TestBillingValidation__c');
    }

    static testMethod void testShipValField() {
       executeTestField('TestShippingValidation__c');
    }

    
    public static void executeTestField(String fldName) {
      CsoMethods.cltRegPerm = CsoMethods.PERM_ALL;
      CsoMethods.cltRegAvail = true;
        
      Opportunity opp = getMMSOpp();
      CSO_Tracking__c tracker = new CSO_Tracking__c(Id=opp.ClientTracking__c);
      TriggerMethods.clearVariables();
      tracker.put(fldName,true);
      Test.startTest();
      update tracker;
      Test.stopTest();
      tracker = [Select Id,Environment__c, IsOppCso__c,IsOppEnterprise__c 
                                           ,EntRegTest__c, TestOSSKeys__c, TestCPQKeys__c, TestCPQSub__c
                                           ,TestClientValidation__c, TestBillingValidation__c, TestShippingValidation__c
                                       from CSO_Tracking__c where Opportunity__c=:opp.Id];
      Boolean fldValue = (Boolean)tracker.get(fldName);
      Assert.isFalse(fldValue);
   } // testRegCall

} // class CsoMethodTest