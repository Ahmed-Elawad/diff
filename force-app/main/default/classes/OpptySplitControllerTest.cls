/* 
 * Test methods for OpptySplitController.
 *
 * History
 * -------
 * 12/13/2016  Jermaine Stukes   Created
 * 02/12/2018  Jermaine Stukes   Updated
   06/04/2019  Dan Carmen        Change to skip triggers
   02/24/2020  Dan Carmen        Increment API to 48
   09/23/2020  Matt Fritschi	 Added changes to test Oracle Quotes
   11/30/2020  Matt Fritschi	 Added changes to test creating Child Onboarding records for the child Opportunities.
   05/19/2021  Dan Carmen        Updated to use labels for StageNames
   12/14/2021  Dan Carmen        Removed/commented out Steelbrick (Salesforce CPQ) code. Add ability to split out product groups.
   01/13/2022  Dan Carmen        Change for multiple approval statuses
   05/22/2023  Dan Carmen        Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
   05/23/2023  Dan Carmen        For multi-ids, ability to split processing into queueable jobs.
   09/04/2023  Reetesh Pandey    Split functionality to add Non Payroll Unit Test
   12/15/2023  Dan Carmen        Add extra logging

 */

@isTest(seeAllData=false) 
public class OpptySplitControllerTest {
    
   @testSetup
   public static void setupData() {
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=OpptySplitController.CLASSNAME, Active__c=true, BatchSize__c=2);
      insert abc;
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'TestProd1','TestProd2','TestProd3','TestProd4','TestProd5','TestProd6','TestProd7','TestProd8'}, 'PAS', null);
      // make sure we get them in order
      Map<String,PricebookEntry> entryMap = getEntryMap();
      // update product info for tests
      Product2 prod1 = new Product2(Id=entryMap.get('TestProd1').Product2Id, PayrollFrequency__c = 'Weekly');
      Product2 prod2 = new Product2(Id=entryMap.get('TestProd2').Product2Id, PayrollFrequency__c = 'Weekly');
      Product2 prod3 = new Product2(Id=entryMap.get('TestProd3').Product2Id, PayrollFrequency__c = 'Weekly',Product_Group__c='Payroll');
      Product2 prod4 = new Product2(Id=entryMap.get('TestProd4').Product2Id, PayrollFrequency__c = 'Weekly',Product_Group__c='Payroll');
      Product2 prod5 = new Product2(Id=entryMap.get('TestProd5').Product2Id, PayrollFrequency__c = 'Weekly',Product_Group__c='Retirement');
      Product2 prod6 = new Product2(Id=entryMap.get('TestProd6').Product2Id, PayrollFrequency__c = 'Weekly',Product_Group__c='Retirement');
      update new Product2[]{prod1,prod2,prod3,prod4,prod5,prod6};

      Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, 'Account');
      Account acctA = new Account(Name = 'testAccountA', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081234',NumberOfEmployees = 60);
      Account acctB = new Account(Name = 'testAccountB', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081235',NumberOfEmployees = 60);
      Account acctC = new Account(Name = 'testAccountC', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081236',NumberOfEmployees = 50);
      Account acctD = new Account(Name = 'testAccountD', RecordTypeId=rtAcct.getRecordTypeId(), AccountNumber = '8-00081237',NumberOfEmployees = 40);
      Account[] accts = new Account[]{acctA,acctB,acctC,acctD};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;

      OppProductGroup__c[] opgs = new OppProductGroup__c[]{};
      opgs.add(new OppProductGroup__c(Name=OpportunityCreateCase.RT_OPPTY_CORE_DSA, RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA, Primary__c=false, OpportunityType__c='Payroll', ProductGroup__c='Payroll'));
      opgs.add(new OppProductGroup__c(Name=OpportunityCreateCase.RT_OPPTY_CORE, RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE, Primary__c=true, OpportunityType__c='Payroll', ProductGroup__c='Payroll'));
      opgs.add(new OppProductGroup__c(Name=OpportunityCreateCase.RT_OPPTY_401K, RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K, Primary__c=true, OpportunityType__c='New Plan', ProductGroup__c='Retirement'));
      opgs.add(new OppProductGroup__c(Name='HRS 401k Opportunity FSS Record Type', RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K_FSS, Primary__c=false, OpportunityType__c='New Plan', ProductGroup__c='Retirement'));
      opgs.add(new OppProductGroup__c(Name=OpportunityCreateCase.RT_OPPTY_MMS, RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, Primary__c=true, OpportunityType__c='Payroll', ProductGroup__c='Payroll'));
      insert opgs;
                
      Referral_Partner__c rp1 = new Referral_Partner__c(Name='Payroll',Partner_Type__c = 'NSS Referral',
                                                       NSS_Source__c = 'Inbound',Evaluate_Product_Of_Interest__c = true,
                                                       Product_Of_Interest_Product_Group__c = 'Payroll');
	   
      Referral_Partner__c rp2 = new Referral_Partner__c(Name='Retirement',Partner_Type__c = 'NSS Referral',
                                                       NSS_Source__c = 'Inbound',Evaluate_Product_Of_Interest__c = true,
                                                       Product_Of_Interest_Product_Group__c = 'Retirement');
       
      Referral_Partner__c[] rfList = new Referral_Partner__c[]{rp1,rp2};
      insert rfList;
      OracleQuoteTriggerPayxHelperTest.setupMapping();
      OracleQuoteTriggerPayxHelperTest.setupOracleSetting();

    } // setupData
    
    public static Map<String,PricebookEntry> getEntryMap() {
       PricebookEntry[] entries = [Select Id, Pricebook2Id, Product2Id,UnitPrice,UseStandardPrice,IsActive
                                    ,Pricebook2.Id, Pricebook2.Name
                                    ,Product2.Id, Product2.Name, Product2.ProductCode, Product2.Sales_Org__c, Product2.IsActive, Product2.Family  
                                    ,Product2.cafsl__Part_Number__c, Product2.StockKeepingUnit
                                from PricebookEntry where Pricebook2.Name='PAS'
                                 order by Product2.Name];
       Map<String,PricebookEntry> entryMap = new Map<String,PricebookEntry>();
       for (PricebookEntry entry : entries) {
          entryMap.put(entry.Product2.Name, entry);
       }
       return entryMap;
    } // getEntryMap
    
    public static Map<String,Referral_Partner__c> getRefPartnerMap() {
       Referral_Partner__c[] refParts = [Select Id, Name from Referral_Partner__c];
       Map<String,Referral_Partner__c> refPartnerMap = new Map<String,Referral_Partner__c>();
       for (Referral_Partner__c refPart : refParts) {
          refPartnerMap.put(refPart.Name, refPart);
       }
       return refPartnerMap;
    } // getRefPartnerMap
    
    public static Account[] getTestAccts() {
       Account[] accts = [Select Id, Name, RecordTypeId, AccountNumber, NumberOfEmployees from Account where Name like 'testAccount%'];
       return accts;
    } // getTestAccts

    static testMethod void testSuccessfulOracleSplit() {
        //Select Products
        List<cafsl__Oracle_Quote_Line_Item__c> quoteLineList = new List<cafsl__Oracle_Quote_Line_Item__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Map<String,PricebookEntry> entryMap = getEntryMap();
        PricebookEntry entry1 = entryMap.get('TestProd1');
        PricebookEntry entry2 = entryMap.get('TestProd2');

        //First Acct
        Account[] accts = getTestAccts();
        Account acctA = accts[0];
        Account acctB = accts[1];

        //Test Opportunity
        Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=mmsOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,Pricebook2Id = entry1.Pricebook2Id
                                             ,Payroll_Platform__c = 'PAY'
                                             ,StageName=Label.OppStage_Sold
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5
                                             ,Non_Payroll_Units__c = 5
                                             ,Service_Location__c = 'Akron Branch 0049'
                                             ,Number_of_Ids__c=2
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        
        //New Quote
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        //quote.cafsl__Syncing__c = true;
        quote.Name = 'Test Quote';
        quote.Multi_ID__c = true;
        quote.cafsl__Pricebook_Id__c = entry1.Pricebook2Id;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.Status__c = 'approved';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
       //cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductA.Id, cafsl__Pricebook_Entry__c = spbe1.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);

		cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry1.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry2.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00, cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        quoteLineList.add(quoteLine1);
        quoteLineList.add(quoteLine2);
        insert quoteLineList;
        
        OpportunityLineItem Oli1 = new OpportunityLineItem(OpportunityId = opptyA.Id, Oracle_Quote_Line__c=quoteLine1.Id, CPQ_External_Id__c='12345678-1', cafsl__External_Id__c=1, Quantity = 1, UnitPrice = 100, PricebookEntryId =entry1.Id,Non_Payroll_Unit__c =5);
        Oli1.Oracle_Quote_Line__c = quoteLine1.Id;
        oliList.add(Oli1);
        
        OpportunityLineItem Oli2 = new OpportunityLineItem(OpportunityId = opptyA.Id, Oracle_Quote_Line__c=quoteLine2.Id, CPQ_External_Id__c='12345678-2', cafsl__External_Id__c=2 , Quantity = 1, UnitPrice = 100, PricebookEntryId = entry1.Id);
        Oli1.Oracle_Quote_Line__c = quoteLine2.Id;
        oliList.add(Oli2);
        insert oliList;
        
        //mark quote primary
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        Onboarding_Tool__c parentOnboardingRec = new Onboarding_Tool__c(Opportunity_Id__c = opptyA.Id, Spanish_Speaking_Needs__c = 'No', Skylight__c='Decline Both', NCP_Submitted__c=true);
        insert parentOnboardingRec;
        
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/OpptySplit?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        Test.startTest();
        OpptySplitController osc = new OpptySplitController();
        // test misc stuff
        System.assertEquals(true,osc.blockTitle.contains('testOpptyA'));
        System.assertEquals(OpptySplitController.HTML_YES,osc.quoteFoundText);
        System.assertEquals(OpptySplitController.HTML_YES,osc.multiIdText);
        System.assertEquals(OpptySplitController.HTML_YES,osc.multipleQuoteText);
        System.assertEquals(OpptySplitController.HTML_YES,osc.quoteApprovedText);
        System.assertEquals(OpptySplitController.HTML_NO,osc.prodGroupText);
        System.assertEquals(true,osc.splitOkay);
        System.assertEquals(false,osc.splitByProdGroupOkay);
        System.assertEquals(true,osc.statusMsg.contains('The Split Opportunity button will separate this Opportunity into separate id'));
        
        osc.splitOpportunity();
        osc.returnToOpportunity();
        List<Opportunity> testOppy = [Select id, Name, Non_Payroll_Units__c from Opportunity where Name=:acctB.Name+'-'+opptyA.Payroll_Platform__c];
        System.assertEquals(true, testOppy.size() > 0);
        System.assertEquals(5, testOppy[0].Non_Payroll_Units__c);
        Test.stopTest();

    } // testSuccessfulOracleSplit
   
   static testMethod void testInvalidOpp() {
      //Select Products
      List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
      Map<String,PricebookEntry> entryMap = getEntryMap();
      PricebookEntry entry1 = entryMap.get('TestProd1');

      Account[] accts = getTestAccts();
      Account acctA = accts[0];

      //Test Opportunity
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,'Opportunity');
      Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=mmsOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,Pricebook2Id = entry1.Pricebook2Id
                                             ,Payroll_Platform__c = 'PAY'
                                             ,StageName=Label.OppStage_Sold
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5
                                             ,Service_Location__c = 'Akron Branch 0049'
                                             ,Number_of_Ids__c=1
                                             ,CloseDate=Date.today().addDays(30));
      insert opptyA;
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = opptyA.Id, Quantity = 1,TotalPrice = 100, PricebookEntryId =entry1.Id);
      insert oli1;
       
      //Set Current Page to new reference
      PageReference pageRef = new PageReference('/apex/OpptySplit?id='+opptyA.Id);
      test.setCurrentPageReference(pageRef);
      Test.startTest();
      OpptySplitController osc = new OpptySplitController();
      // test misc stuff
      System.assertEquals(true,osc.blockTitle.contains('testOpptyA'));
      System.assertEquals(OpptySplitController.HTML_NO,osc.quoteFoundText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.multiIdText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.multipleQuoteText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.quoteApprovedText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.prodGroupText);
      System.assertEquals(false,osc.splitOkay);
      System.assertEquals(false,osc.splitByProdGroupOkay);
      System.assertEquals(true,osc.statusMsg.contains('No Multi-Ids or Product Groups were found to'));
      Test.stopTest();
       
      PageReference pr1 = osc.cloneOpportunity();
      System.assertEquals(true,pr1.getUrl().contains(opptyA.Id),pr1.getUrl());

      PageReference pr2 = osc.submittedRevenueClone();
      System.assertEquals(true,pr2.getUrl().contains(opptyA.Id),pr2.getUrl());

   } // testInvalidOpp
    
   static testMethod void testOnlyProdGroups() {
      //Select Products
      Map<String,PricebookEntry> entryMap = getEntryMap();
      PricebookEntry entry3 = entryMap.get('TestProd3');
      PricebookEntry entry4 = entryMap.get('TestProd4');
      PricebookEntry entry5 = entryMap.get('TestProd5');
      PricebookEntry entry6 = entryMap.get('TestProd6');
       
      Map<String,Referral_Partner__c> refPartnerMap = getRefPartnerMap();
      Referral_Partner__c rp1 = refPartnerMap.get('Payroll');
      Referral_Partner__c rp2 = refPartnerMap.get('Retirement');
       
      PartnerReferral__c partRef = new PartnerReferral__c(Company__c='TestCompany');
      insert partRef;

      Account[] accts = getTestAccts();
      Account acctA = accts[0];
       
      Contact testContact = new Contact(AccountId=acctA.Id, FirstName='Timmy',LastName='Contact');
      insert testContact;

      //Test Opportunity
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K,'Opportunity');
      Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=mmsOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,Pricebook2Id = entry3.Pricebook2Id
                                             ,Payroll_Platform__c = 'PAY'
                                             ,StageName=Label.OppStage_Sold
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5
                                             ,Service_Location__c = 'Akron Branch 0049'
                                             ,Number_of_Ids__c=1
                                             ,OpportunityType__c='New Plan'
                                             //,EvaluateProductGroupOverride__c=true
                                             ,AdditionalProductsOfInterest__c='Payroll,Retirement'
                                             ,ProductGroupsSelected__c='Payroll,Retirement'
                                             ,CloseDate=Date.today().addDays(30));
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opptyA;
       
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opptyA.Id, ContactId=testContact.Id, Role='Owner', IsPrimary=true);
      insert ocr;
       
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId = opptyA.Id, Quantity = 1,TotalPrice = 110, PricebookEntryId = entry3.Id);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId = opptyA.Id, Quantity = 1,TotalPrice = 120, PricebookEntryId = entry4.Id);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId = opptyA.Id, Quantity = 1,TotalPrice = 130, PricebookEntryId = entry5.Id);
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId = opptyA.Id, Quantity = 1,TotalPrice = 140, PricebookEntryId = entry6.Id);
      OpptyLineItem.SKIP_TRIGGER=true;
      insert new OpportunityLineItem[]{oli1,oli2,oli3,oli4};
          
      Referral__c ref1 = new Referral__c(Name='Ref1', Referral_Partner__c=rp1.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      Referral__c ref2 = new Referral__c(Name='Ref2', Referral_Partner__c=rp2.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      ReferralTriggerActions.SKIP_TRIGGER=true;
      insert new Referral__c[]{ref1,ref2};
      opptyA.ReferralLookup__c = ref1.Id;
      update opptyA;
       
      System.assertEquals(1,[select count() from Opportunity where Id=:opptyA.Id and EvaluateProductGroup__c=true]);
          
      //Set Current Page to new reference
      PageReference pageRef = new PageReference('/apex/OpptySplit?id='+opptyA.Id);
      test.setCurrentPageReference(pageRef);
      Test.startTest();
      OpptySplitController osc = new OpptySplitController();
      // test misc stuff
      System.assertEquals(true,osc.blockTitle.contains('testOpptyA'));
      System.assertEquals(OpptySplitController.HTML_NO,osc.quoteFoundText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.multiIdText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.multipleQuoteText);
      System.assertEquals(OpptySplitController.HTML_NO,osc.quoteApprovedText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.prodGroupText);
      System.assertEquals(false,osc.splitOkay);
      System.assertEquals(true,osc.splitByProdGroupOkay);
      System.assertEquals(true,osc.statusMsg.contains('No Multi-Id was found. The Split Opportunity button will only separate the Product Groups'));
       
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      OpptyLineItem.SKIP_TRIGGER=false;
      System.debug('testOnlyProdGroups before splitOpportunity');
      osc.splitOpportunity();

      Test.stopTest();
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, OpportunityType__c, ReferralLookup__c, ProductGroupsSelected__c
                                                           ,ReferralLookup__r.Name, ReferralLookup__r.Referral_Partner__c, ReferralLookup__r.Selling_Opportunity__c
                                  ,(Select Id, ContactId, IsPrimary, OpportunityId, Role from OpportunityContactRoles)
                                  ,(Select Id, PricebookEntryId, Product2.Product_Group__c
                                      From OpportunityLineItems)
                              From Opportunity
                             Where AccountId=:acctA.Id]);
      System.assertEquals(2,oppMap.size());

      // check the original opp
      Opportunity opp1 = oppMap.remove(opptyA.Id);
      System.debug('testOnlyProdGroups opp1='+opp1);
      System.assertEquals('Retirement',opp1.ProductGroupsSelected__c);
      System.assertEquals(rp2.Id, opp1.ReferralLookup__r.Referral_Partner__c);
      findEntries(opp1.OpportunityLineItems, entry5.Id, entry6.Id);
      System.assertEquals(1,opp1.OpportunityContactRoles.size());
             
      // pull the other opp which should just have been created
      Opportunity opp2 = oppMap.values()[0];
      System.debug('testOnlyProdGroups opp2='+opp2);
      System.assertEquals('Payroll',opp2.ProductGroupsSelected__c);
      System.assertEquals(rp1.Id, opp2.ReferralLookup__r.Referral_Partner__c);
      findEntries(opp2.OpportunityLineItems, entry3.Id, entry4.Id);
      System.assertEquals(1,opp2.OpportunityContactRoles.size());
          
   } // testOnlyProdGroups
      
   static testMethod void testMultiAndProdGroup() {
      //Select Products
      Map<String,PricebookEntry> entryMap = getEntryMap();
      PricebookEntry entry3 = entryMap.get('TestProd3');
      PricebookEntry entry4 = entryMap.get('TestProd4');
      PricebookEntry entry5 = entryMap.get('TestProd5');
      PricebookEntry entry6 = entryMap.get('TestProd6');
       
      Map<String,Referral_Partner__c> refPartnerMap = getRefPartnerMap();
      Referral_Partner__c rp1 = refPartnerMap.get('Payroll');
      Referral_Partner__c rp2 = refPartnerMap.get('Retirement');
       
      PartnerReferral__c partRef = new PartnerReferral__c(Company__c='TestCompany');
      insert partRef;

      Account[] accts = getTestAccts();
      Account acctA = accts[0];
      Account acctB = accts[1];
      Account acctC = accts[2];
      Account acctD = accts[3];

      //Test Opportunity
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K,'Opportunity');
      Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=mmsOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,Pricebook2Id = entry3.Pricebook2Id
                                             ,Payroll_Platform__c = 'PAY'
                                             ,StageName=Label.OppStage_Sold
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 1
                                             ,Service_Location__c = 'Akron Branch 0049'
                                             ,Number_of_Ids__c=4
                                             ,OpportunityType__c='New Plan'
                                             //,EvaluateProductGroupOverride__c=true
                                             ,AdditionalProductsOfInterest__c='Payroll,Retirement'
                                             ,ProductGroupsSelected__c='Payroll,Retirement'
                                             ,CloseDate=Date.today().addDays(30));
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opptyA;
        
      //New Quote
      cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
      cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
      quote.cafsl__Account__c = opptyA.AccountId;
      quote.cafsl__Opportunity__c = opptyA.Id;
      quote.Name = 'Test Quote';
      quote.Multi_ID__c = true;
      quote.cafsl__Pricebook_Id__c = entry3.Pricebook2Id;
      quote.cafsl__CPQ_External_Id__c='12345678';
      quote.Status__c = 'approved';
      quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
      insert quote;
        
      cafsl__Oracle_Quote_Line_Item__c qLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry5.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=3, cafsl__CPQ_External_Id__c='12345678-3', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry6.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=4, cafsl__CPQ_External_Id__c='12345678-4', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=5, cafsl__CPQ_External_Id__c='12345678-5', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine6 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=6, cafsl__CPQ_External_Id__c='12345678-6', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine7 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry5.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=7, cafsl__CPQ_External_Id__c='12345678-7', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine8 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry6.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=8, cafsl__CPQ_External_Id__c='12345678-8', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine9 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=9, cafsl__CPQ_External_Id__c='12345678-9', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine10 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=10, cafsl__CPQ_External_Id__c='12345678-10', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine11 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry5.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=11, cafsl__CPQ_External_Id__c='12345678-11', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine12 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry6.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=12, cafsl__CPQ_External_Id__c='12345678-12', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine13 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=13, cafsl__CPQ_External_Id__c='12345678-13', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine14 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=14, cafsl__CPQ_External_Id__c='12345678-14', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine15 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry5.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=15, cafsl__CPQ_External_Id__c='12345678-15', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine16 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry6.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=16, cafsl__CPQ_External_Id__c='12345678-16', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c[] quoteLines = new cafsl__Oracle_Quote_Line_Item__c[]{qLine1,qLine2,qLine3,qLine4,qLine5,qLine6,qLine7,qLine8,qLine9,qLine10,qLine11,qLine12,qLine13,qLine14,qLine15,qLine16};
      insert quoteLines;
       
      Assert.areEqual(16, [Select count() from cafsl__Oracle_Quote_Line_Item__c where Prospect_Client__c != null]);
       
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline1.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline1.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline1.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline2.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline2.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline2.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline3.Id, PricebookEntryId=entry5.Id, CPQ_External_Id__c=qline3.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline3.cafsl__External_Id__c, Quantity=1, UnitPrice=80);
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline4.Id, PricebookEntryId=entry6.Id, CPQ_External_Id__c=qline4.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline4.cafsl__External_Id__c, Quantity=1, UnitPrice=70);

      OpportunityLineItem oli5 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline5.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline5.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline5.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli6 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline6.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline6.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline6.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem oli7 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline7.Id, PricebookEntryId=entry5.Id, CPQ_External_Id__c=qline7.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline7.cafsl__External_Id__c, Quantity=1, UnitPrice=80);
      OpportunityLineItem oli8 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline8.Id, PricebookEntryId=entry6.Id, CPQ_External_Id__c=qline8.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline8.cafsl__External_Id__c, Quantity=1, UnitPrice=70);

      OpportunityLineItem oli9 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline9.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline9.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline9.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli10 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline10.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline10.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline10.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem oli11 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline11.Id, PricebookEntryId=entry5.Id, CPQ_External_Id__c=qline11.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline11.cafsl__External_Id__c, Quantity=1, UnitPrice=80);
      OpportunityLineItem oli12 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline12.Id, PricebookEntryId=entry6.Id, CPQ_External_Id__c=qline12.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline12.cafsl__External_Id__c, Quantity=1, UnitPrice=70);

      OpportunityLineItem oli13 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline13.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline13.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline13.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli14 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline14.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline14.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline14.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem oli15 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline15.Id, PricebookEntryId=entry5.Id, CPQ_External_Id__c=qline15.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline15.cafsl__External_Id__c, Quantity=1, UnitPrice=80);
      OpportunityLineItem oli16 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline16.Id, PricebookEntryId=entry6.Id, CPQ_External_Id__c=qline16.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline16.cafsl__External_Id__c, Quantity=1, UnitPrice=70);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4,oli5,oli6,oli7,oli8,oli9,oli10,oli11,oli12,oli13,oli14,oli15,oli16};
          
      OpptyLineItem.SKIP_TRIGGER=true;
      insert olis;

      Assert.areEqual(16, [Select count() from OpportunityLineItem where Oracle_Quote_Line__r.Prospect_Client__c != null]);
       
      // setup the referrals
      Referral__c ref1 = new Referral__c(Name='Ref1', Referral_Partner__c=rp1.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      Referral__c ref2 = new Referral__c(Name='Ref2', Referral_Partner__c=rp2.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      ReferralTriggerActions.SKIP_TRIGGER=true;
      insert new Referral__c[]{ref1,ref2};
      opptyA.ReferralLookup__c = ref1.Id;
      opptyA.Primary_Oracle_Quote__c=quote.id;
      update opptyA;
       
      System.assertEquals(1,[select count() from Opportunity where Id=:opptyA.Id and EvaluateProductGroup__c=true]);
 
      //Set Current Page to new reference
      PageReference pageRef = new PageReference('/apex/OpptySplit?id='+opptyA.Id);
      test.setCurrentPageReference(pageRef);
      Test.startTest();
      OpptySplitController osc = new OpptySplitController();
      // test misc stuff
      System.assertEquals(true,osc.blockTitle.contains('testOpptyA'));
      System.assertEquals(OpptySplitController.HTML_YES,osc.quoteFoundText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.multiIdText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.multipleQuoteText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.quoteApprovedText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.prodGroupText);
      System.assertEquals(true,osc.splitOkay);
      System.assertEquals(true,osc.splitByProdGroupOkay);
      System.assertEquals(true,osc.statusMsg.contains('The Split Opportunity button will separate the ids and the Product Groups'), osc.statusMsg);
       
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      OpptyLineItem.SKIP_TRIGGER=false;
      System.debug('testMultiAndProdGroup before splitOpportunity');
      osc.splitOpportunity();

      Test.stopTest();
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, AccountId, Name, OpportunityType__c, ReferralLookup__c, ProductGroupsSelected__c
                                                           ,ReferralLookup__r.Name, ReferralLookup__r.Referral_Partner__c, ReferralLookup__r.Selling_Opportunity__c
                                  ,(Select Id, PricebookEntryId, Product2.Product_Group__c
                                      From OpportunityLineItems)
                              From Opportunity]);
      System.assertEquals(8,oppMap.size());
       
      Integer cntRetire=0;
      Integer cntPayroll=0;
      for (Opportunity opp : oppMap.values()) {
         if (opp.ProductGroupsSelected__c=='Retirement') {
            cntRetire++;
            if (opp.AccountId == acctA.Id) {
               System.assertEquals(rp2.Id, opp.ReferralLookup__r.Referral_Partner__c);
            } else {
               System.assertEquals(null, opp.ReferralLookup__c);
            }
            findEntries(opp.OpportunityLineItems, entry5.Id, entry6.Id);
         } else if (opp.ProductGroupsSelected__c=='Payroll') {
            cntPayroll++;
            if (opp.AccountId == acctA.Id) {
               System.assertEquals(rp1.Id, opp.ReferralLookup__r.Referral_Partner__c);
            } else {
               System.assertEquals(null, opp.ReferralLookup__c);
            }
            findEntries(opp.OpportunityLineItems, entry3.Id, entry4.Id);
         }
      } // for (Opportunity opp
       
      System.assertEquals(4,cntRetire);
      System.assertEquals(4,cntPayroll);
      Assert.isTrue(OpptySplitController.summarySent);
   } // testMultiAndProdGroup
    
   public static void findEntries(OpportunityLineItem[] olis, Id entryId1, Id entryId2) {
      System.assertEquals(2,olis.size());
      Boolean found1=false;
      Boolean found2=false;
      for (OpportunityLineItem oli : olis) {
          found1 = (found1 || oli.PricebookEntryId == entryId1);
          found2 = (found2 || oli.PricebookEntryId == entryId2);
      }
      System.assertEquals(true,found1);
      System.assertEquals(true,found2);

   } // findEntries
    
    
   static testMethod void testMultiAndProdGroup2() {
      //Select Products
      Map<String,PricebookEntry> entryMap = getEntryMap();
      PricebookEntry entry3 = entryMap.get('TestProd3');
      PricebookEntry entry4 = entryMap.get('TestProd4');
      PricebookEntry entry5 = entryMap.get('TestProd5');
      PricebookEntry entry6 = entryMap.get('TestProd6');
       
      Map<String,Referral_Partner__c> refPartnerMap = getRefPartnerMap();
      Referral_Partner__c rp1 = refPartnerMap.get('Payroll');
      Referral_Partner__c rp2 = refPartnerMap.get('Retirement');
       
      PartnerReferral__c partRef = new PartnerReferral__c(Company__c='TestCompany');
      insert partRef;

      Account[] accts = getTestAccts();
      Account acctA = accts[0];
      Account acctB = accts[1];
      Account acctC = accts[2];
      Account acctD = accts[3];

      //Test Opportunity
      Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_401K,'Opportunity');
      Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=mmsOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,Pricebook2Id = entry3.Pricebook2Id
                                             ,Payroll_Platform__c = 'PAY'
                                             ,StageName=Label.OppStage_Sold
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 1
                                             ,Service_Location__c = 'Akron Branch 0049'
                                             ,Number_of_Ids__c=4
                                             ,OpportunityType__c='New Plan'
                                             //,EvaluateProductGroupOverride__c=true
                                             ,AdditionalProductsOfInterest__c='Payroll,Retirement'
                                             ,ProductGroupsSelected__c='Payroll,Retirement'
                                             ,CloseDate=Date.today().addDays(30));
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opptyA;
        
      //New Quote
      cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
      cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
      quote.cafsl__Account__c = opptyA.AccountId;
      quote.cafsl__Opportunity__c = opptyA.Id;
      quote.Name = 'Test Quote';
      quote.Multi_ID__c = true;
      quote.cafsl__Pricebook_Id__c = entry3.Pricebook2Id;
      quote.cafsl__CPQ_External_Id__c='12345678';
      quote.Status__c = 'approved';
      quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
      insert quote;
        
      cafsl__Oracle_Quote_Line_Item__c qLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry5.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=3, cafsl__CPQ_External_Id__c='12345678-3', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry6.Product2Id, Prospect_Client__c=acctA.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=4, cafsl__CPQ_External_Id__c='12345678-4', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=5, cafsl__CPQ_External_Id__c='12345678-5', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine6 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctB.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=6, cafsl__CPQ_External_Id__c='12345678-6', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine9 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=9, cafsl__CPQ_External_Id__c='12345678-9', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine10 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctC.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=10, cafsl__CPQ_External_Id__c='12345678-10', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c qLine13 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry3.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=13, cafsl__CPQ_External_Id__c='12345678-13', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
      cafsl__Oracle_Quote_Line_Item__c qLine14 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = entry4.Product2Id, Prospect_Client__c=acctD.Id, Billing_Frequency__c = 'Weekly'
                                                                                        ,cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00
                                                                                        ,cafsl__External_Id__c=14, cafsl__CPQ_External_Id__c='12345678-14', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
   
      cafsl__Oracle_Quote_Line_Item__c[] quoteLines = new cafsl__Oracle_Quote_Line_Item__c[]{qLine1,qLine2,qLine3,qLine4,qLine5,qLine6,qLine9,qLine10,qLine13,qLine14};
      insert quoteLines;
       
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline1.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline1.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline1.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline2.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline2.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline2.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline3.Id, PricebookEntryId=entry5.Id, CPQ_External_Id__c=qline3.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline3.cafsl__External_Id__c, Quantity=1, UnitPrice=80);
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline4.Id, PricebookEntryId=entry6.Id, CPQ_External_Id__c=qline4.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline4.cafsl__External_Id__c, Quantity=1, UnitPrice=70);

      OpportunityLineItem oli5 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline5.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline5.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline5.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli6 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline6.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline6.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline6.cafsl__External_Id__c, Quantity=1, UnitPrice=90);

      OpportunityLineItem oli9 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline9.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline9.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline9.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli10 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline10.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline10.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline10.cafsl__External_Id__c, Quantity=1, UnitPrice=90);

      OpportunityLineItem oli13 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline13.Id, PricebookEntryId=entry3.Id, CPQ_External_Id__c=qline13.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline13.cafsl__External_Id__c, Quantity=1, UnitPrice=10);
      OpportunityLineItem oli14 = new OpportunityLineItem(OpportunityId=opptyA.Id, Oracle_Quote_Line__c=qline14.Id, PricebookEntryId=entry4.Id, CPQ_External_Id__c=qline14.cafsl__CPQ_External_Id__c, cafsl__External_Id__c=qline14.cafsl__External_Id__c, Quantity=1, UnitPrice=90);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4,oli5,oli6,oli9,oli10,oli13,oli14};
          
      OpptyLineItem.SKIP_TRIGGER=true;
      insert olis;
       
      // setup the referrals
      Referral__c ref1 = new Referral__c(Name='Ref1', Referral_Partner__c=rp1.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      Referral__c ref2 = new Referral__c(Name='Ref2', Referral_Partner__c=rp2.Id, Account__c=acctA.Id, Selling_Opportunity__c=opptyA.Id, PartnerReferral__c=partRef.Id);
      ReferralTriggerActions.SKIP_TRIGGER=true;
      insert new Referral__c[]{ref1,ref2};
      opptyA.ReferralLookup__c = ref1.Id;
      opptyA.Primary_Oracle_Quote__c=quote.id;
      update opptyA;
       
      System.assertEquals(1,[select count() from Opportunity where Id=:opptyA.Id and EvaluateProductGroup__c=true]);
 
      //Set Current Page to new reference
      PageReference pageRef = new PageReference('/apex/OpptySplit?id='+opptyA.Id);
      test.setCurrentPageReference(pageRef);
      Test.startTest();
      OpptySplitController osc = new OpptySplitController();
      // test misc stuff
      System.assertEquals(true,osc.blockTitle.contains('testOpptyA'));
      System.assertEquals(OpptySplitController.HTML_YES,osc.quoteFoundText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.multiIdText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.multipleQuoteText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.quoteApprovedText);
      System.assertEquals(OpptySplitController.HTML_YES,osc.prodGroupText);
      System.assertEquals(true,osc.splitOkay);
      System.assertEquals(true,osc.splitByProdGroupOkay);
      System.assertEquals(true,osc.statusMsg.contains('The Split Opportunity button will separate the ids and the Product Groups'), osc.statusMsg);
       
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      OpptyLineItem.SKIP_TRIGGER=false;
      System.debug('testMultiAndProdGroup before splitOpportunity');
      osc.splitOpportunity();

      Test.stopTest();
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, AccountId, Name, OpportunityType__c, ReferralLookup__c, ProductGroupsSelected__c
                                                           ,ReferralLookup__r.Name, ReferralLookup__r.Referral_Partner__c, ReferralLookup__r.Selling_Opportunity__c
                                  ,(Select Id, PricebookEntryId, Product2.Product_Group__c
                                      From OpportunityLineItems)
                              From Opportunity]);
      System.assertEquals(5,oppMap.size());
       
      Integer cntRetire=0;
      Integer cntPayroll=0;
      for (Opportunity opp : oppMap.values()) {
         if (opp.ProductGroupsSelected__c=='Retirement') {
            cntRetire++;
            if (opp.AccountId == acctA.Id) {
               System.assertEquals(rp2.Id, opp.ReferralLookup__r.Referral_Partner__c);
            } else {
               System.assertEquals(null, opp.ReferralLookup__c);
            }
            findEntries(opp.OpportunityLineItems, entry5.Id, entry6.Id);
         } else if (opp.ProductGroupsSelected__c=='Payroll') {
            cntPayroll++;
            if (opp.AccountId == acctA.Id) {
               System.assertEquals(rp1.Id, opp.ReferralLookup__r.Referral_Partner__c);
            } else {
               System.assertEquals(null, opp.ReferralLookup__c);
            }
            findEntries(opp.OpportunityLineItems, entry3.Id, entry4.Id);
         }
      } // for (Opportunity opp
       
      System.assertEquals(1,cntRetire);
      System.assertEquals(4,cntPayroll);
   } // testMultiAndProdGroup2
   
} // OpptySplitControllerTest