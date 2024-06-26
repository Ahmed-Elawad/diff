/* 
 * Test methods for OnboardingPDFController.
 *
 * History
 * -------
 * 12/12/2016	Jermaine Stukes Created
 * 08/21/2019	Jermaine Stukes	Added Doc Desk PDF test
 * 04/01/2020	Carrie Marciano added tests for Oracle CPQ Quotes
   03/16/2023   Jaipal              Added new fields to this page as per: APR0150123
   05/22/2023   Dan Carmen         Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c

 */
@isTest
public class OnboardingPDFControllerTest {
    @testSetup
    public static void setupData() {
        OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
    }
    
    static testMethod void testOnboardingExistingClient()
    {
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = '0011-2222',NumberOfEmployees = 60);
        insert acctA;
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@paychex.com', HasOptedOutOfEmail=false);
        insert c1_a1;

        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Sold'
                                             ,Employees_Paid_Per_Payroll__c = 25
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        
        Onboarding_Tool__c aso = new Onboarding_Tool__c(Opportunity_Id__c = opptyA.Id, Authorize_Officer__c = c1_a1.Id, Company_Contact__c = c1_a1.Id, New_Existing__c = 'Existing Paychex Client',HRE_Decision_Factors__c = 'Other');
        insert aso;
                //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/OnboardingPDF?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        //Create OnboardingPDFController
        OnboardingPDFController pdf = new OnboardingPDFController();
        System.assertEquals(pdf.onboardingOpp.Id, opptyA.Id);
    }
    static testMethod void testOnboardingNewClient()
    {
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = Null, NumberOfEmployees = 60);
        insert acctA;
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@paychex.com', HasOptedOutOfEmail=false);
        insert c1_a1;
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Sold'
                                             ,Employees_Paid_Per_Payroll__c = 25
                                             ,CloseDate=Date.today().addDays(30));
        insert opptyA;
        
        Onboarding_Tool__c aso = new Onboarding_Tool__c(Opportunity_Id__c = opptyA.Id, Product__c='Paychex HR Essentials', Authorize_Officer__c = c1_a1.Id, Company_Contact__c = c1_a1.Id, New_Existing__c = 'New Client',HRE_Decision_Factors__c = 'Other');
        
        insert aso;
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/OnboardingPDF?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        //Create OnboardingPDFController
        OnboardingPDFController pdf = new OnboardingPDFController();
        pdf.aoName = c1_a1.Name;
        pdf.aoTitle = 'testTitle';
        pdf.ccName = c1_a1.Name;
        pdf.ccTitle = 'testTitle';
        pdf.handbookName = c1_a1.Name;
        pdf.handbookTitle = 'testTitle';
        System.assertEquals(pdf.onboardingOpp.Id, opptyA.Id);
    }

     public static Pricebook2 setupPricebookAndMap(Boolean createPkg) {
    // create the products
      String[] prodNames = new String[]{'ProductHelperTest1','ProductHelperTest2','ProductHelperTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry entry = entries.get(0);
      Pricebook2 pb = entry.Pricebook2;
      pb.Sales_Org__c='TestSalesOrg';
      
    
      System.debug('setupPricebookAndMap pricebook id='+pb.Id);
      
      Integer nbr = [Select count() from Product_Pricebook_Map__c
                               where Sales_Org__c in ('TestSalesOrg')
                                 and Pricebook_Id__c != null
                               ];
      System.assertEquals(1,nbr);
      //Product2 p1 = new Product2(Name='ProductHelperTest1',ProductCode='ProductHelperTest1',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Default_Units_to_Employees__c=true, IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //Product2 p2 = new Product2(Name='ProductHelperTest2',ProductCode='ProductHelperTest2',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Default_Units_to_Employees__c=false,IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //Product2[] prods = new Product2[]{p1,p2};
      //if (createPkg) {
      //   Product2 p3 = new Product2(Name='ProductHelperTest3',ProductCode='ProductHelperTest3',Unit_Type__c='Widget',Sales_Org__c=ppm1.Sales_Org__c, Is_Package__c=true, Default_Units_to_Employees__c=true, IsActive=true,Is_Payroll_Unit__c=false,Is_Non_Payroll_Unit__c=false);
      //     prods.add(p3);
      //}
      //insert prods;
      if (createPkg) {
         Product2 p1 = entries.get(0).Product2;
         Product2 p2 = entries.get(1).Product2;
         Product2 p3 = entries.get(2).Product2;
         p3.Is_Package__c = true;
         p3.Default_Units_to_Employees__c = true;
         p1.Default_Units_to_Employees__c = true;
         update p1;
         update p3;
         
         Product_Parent_Child_Link__c prodLink1 = new Product_Parent_Child_Link__c(Parent_Product_Code__c=p3.ProductCode
                                                                                  ,Child_Product_Code__c=p1.ProductCode
                                                                                  ,Included_in_Parent_Price__c=true);
         Product_Parent_Child_Link__c prodLink2 = new Product_Parent_Child_Link__c(Parent_Product_Code__c=p3.ProductCode
                                                                                  ,Child_Product_Code__c=p2.ProductCode);
         Product_Parent_Child_Link__c[] links = new Product_Parent_Child_Link__c[]{prodLink1,prodLink2};
         insert links;
         
         // add pricing
         Product_Pricing__c pp1 = new Product_Pricing__c(Name=p1.ProductCode,Low_Value__c=1, High_Value__c=5, Amount__c=5, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg', Setup_Fee__c=100, Discount_Free_Months_Allowed__c=3,Discount_Pct_Allowed__c=50);
         Product_Pricing__c pp2 = new Product_Pricing__c(Name=p1.ProductCode,Low_Value__c=6, High_Value__c=99, Amount__c=7, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg');
         Product_Pricing__c pp3 = new Product_Pricing__c(Name=p3.ProductCode,Low_Value__c=1, High_Value__c=99, Amount__c=3, Pricing_Type__c='Cumulative Rate Per Unit', Sales_Org__c='TestSalesOrg', Setup_Fee__c=50, Discount_Free_Months_Allowed__c=6,Discount_Pct_Allowed__c=75);
         Product_Pricing__c[] pricings = new Product_Pricing__c[]{pp1,pp2,pp3};
         insert pricings;
      }
      
      return pb;
   } // setupPricebookAndMap
    
    static testMethod void testOracleDDPDF()
    {
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = Null, NumberOfEmployees = 60);
        insert acctA;
        Contact c1_a1 = new Contact(FirstName='Test Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@paychex.com', HasOptedOutOfEmail=false);
        insert c1_a1;
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');

        List<Product2> productList = new List<Product2>();
        List<Account> acctList = new List<Account>();
        List<cafsl__Oracle_Quote_Line_Item__c> oracleQuoteLineList = new List<cafsl__Oracle_Quote_Line_Item__c>();
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        
        Product2 quoteProductA = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductA);
        Product2 quoteProductB = New Product2(Name = 'Paychex Promise', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductB);
        Product2 quoteProductC = New Product2(Name = 'Paychex Flex Enterprise', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductC);
        Product2 quoteProductD = New Product2(Name = 'ESR', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductD);
        Product2 quoteProductE = New Product2(Name = 'Flextime', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        productList.add(quoteProductE);
        insert productList;
        
       Id spricebookId = Test.getStandardPricebookId();
      System.debug('***CLM*** spricebookId: ' + spricebookId);
     
      PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductA.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe2 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductB.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe3 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductC.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe4 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductD.Id, UnitPrice=7.00, isActive=true, UseStandardPrice=false);
      PricebookEntry spbe5 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = quoteProductE.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      PricebookEntry[] spbes = new PricebookEntry[]{spbe1,spbe2,spbe3,spbe4,spbe5};
      insert spbes;
        
    // verify pricebookentry values updated
      PricebookEntry[] nPbes = [Select Id, Pricebook2Id, Product2Id, UnitPrice, Product2.Name, Pricebook2.Name from PricebookEntry where Id in :spbes];
      System.debug('***CLM*** After inserted PricebookEntries nPbes: ' + nPbes);
        
        Opportunity opptyA = new Opportunity(Name='testOpptyA', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                             ,AccountId=acctA.id
                                             ,StageName='Sold'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,Pricebook2Id = spricebookId
                                             ,Employees_Paid_Per_Payroll__c = 51
                                             ,Payroll_Platform__c = 'PAY'
                                             ,Payroll_Unit__c = true
                                             ,Payroll_Units__c = 5);
        insert opptyA;
        
        //oracle field mappings
        cafsl__Field_Mapping__c qFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multi_id__c', cafsl__Target__c='multi_id_client__c');
        cafsl__Field_Mapping__c qFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='multiple_pay_frequencies__c', cafsl__Target__c='multi_frequency__c');
        cafsl__Field_Mapping__c qFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote to Opportunity', cafsl__Source__c='number_of_related_accounts__c', cafsl__Target__c='number_of_ids__c');
        cafsl__Field_Mapping__c qlFieldMapping1 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='discount_percent__c', cafsl__Target__c='discount_percent__c');
        cafsl__Field_Mapping__c qlFieldMapping2 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='customer_price_unit__c', cafsl__Target__c='unitprice');
        cafsl__Field_Mapping__c qlFieldMapping3 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__quantity__c', cafsl__Target__c='quantity');
        cafsl__Field_Mapping__c qlFieldMapping4 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__cpq_external_id__c', cafsl__Target__c='cpq_external_id__c');
        cafsl__Field_Mapping__c qlFieldMapping5 = new cafsl__Field_Mapping__c(cafsl__Data_Set__c='paychexinctest3', cafsl__Type__c='Oracle Quote Line Item to Opportunity Line Item', cafsl__Source__c='cafsl__sales_price__c', cafsl__Target__c='oracle_sales_price__c');
        cafsl__Field_Mapping__c[] fMappings = new cafsl__Field_Mapping__c[]{qFieldMapping1,qFieldMapping2,qFieldMapping3,qlFieldMapping1,qlFieldMapping2,qlFieldMapping3,qlFieldMapping4,qlFieldMapping5};
        insert fMappings;
        
        cafsl__Field_Mapping__c[] newFMappings = [SELECT Id, Name, cafsl__Type__c, cafsl__Source__c, cafsl__Target__c FROM cafsl__Field_Mapping__c];
        System.debug('newFMappings='+newFMappings);
        
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        //New Quote
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opptyA.AccountId;
        quote.cafsl__Opportunity__c = opptyA.Id;
        //quote.cafsl__Syncing__c = true;
        quote.Name = 'TestQuote';
        quote.Multi_ID__c = false;
        quote.cafsl__Pricebook_Id__c = spricebookId;
        quote.cafsl__CPQ_External_Id__c='12345678';
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        cafsl__Oracle_Quote__c newQuote = [SELECT Id, Name, cafsl__CPQ_External_Id__c, Approver__c FROM cafsl__Oracle_Quote__c WHERE Id=:quote.Id];
        System.debug('newQuote='+newQuote);
        
        //New Quote Line Items       
        System.debug('quoteProductA='+quoteProductA);
        System.debug('cafsl__Oracle_Quote__c.Id='+quote.Id);
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductA.Id, cafsl__Pricebook_Entry__c = spbe1.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=5.00, customer_price_unit__c=4.00, cafsl__External_Id__c=1, cafsl__CPQ_External_Id__c='12345678-1', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductB.Id, cafsl__Pricebook_Entry__c = spbe2.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=6.00, customer_price_unit__c=4.00, cafsl__External_Id__c=2, cafsl__CPQ_External_Id__c='12345678-2', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine3 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductC.Id, cafsl__Pricebook_Entry__c = spbe3.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=7.00, customer_price_unit__c=4.00, cafsl__External_Id__c=3, cafsl__CPQ_External_Id__c='12345678-3', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine4 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductD.Id, cafsl__Pricebook_Entry__c = spbe4.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=8.00, customer_price_unit__c=4.00, cafsl__External_Id__c=4, cafsl__CPQ_External_Id__c='12345678-4', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        cafsl__Oracle_Quote_Line_Item__c quoteLine5 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c=quoteProductE.Id, cafsl__Pricebook_Entry__c = spbe5.Id, Billing_Frequency__c = 'Weekly', cafsl__Oracle_Quote__c = quote.Id, cafsl__Quantity__c=9.00, customer_price_unit__c=4.00, cafsl__External_Id__c=5, cafsl__CPQ_External_Id__c='12345678-5', Discount_Percent__c=0.00, Discount_Amount__c=0.00);
        
        oracleQuoteLineList.add(quoteLine1);
        oracleQuoteLineList.add(quoteLine2);
        oracleQuoteLineList.add(quoteLine3);
        oracleQuoteLineList.add(quoteLine4);
        oracleQuoteLineList.add(quoteLine5);
        insert oracleQuoteLineList;

        cafsl__Oracle_Quote_Line_Item__c[] insertOQLs = [SELECT Id, cafsl__Product__c, cafsl__Product__r.Name, cafsl__Pricebook_Entry__c, cafsl__Oracle_Quote__c, cafsl__Quantity__c, cafsl__External_Id__c, cafsl__CPQ_External_Id__c FROM cafsl__Oracle_Quote_Line_Item__c WHERE Id = :oracleQuoteLineList];
        System.debug('insertOQLs: ' + insertOQLs);
        
        //mark quote primary
        //quote.cafsl__Syncing__c = true;
        //update quote;
        opptyA.Primary_Oracle_Quote__c=quote.id;
        update opptyA;
        
        cafsl__Oracle_Quote__c pQuote = [SELECT Id, Name, cafsl__CPQ_External_Id__c, cafsl__Account__c, cafsl__Opportunity__c, cafsl__Pricebook_Id__c, cafsl__Syncing__c FROM cafsl__Oracle_Quote__c WHERE Id=:quote.Id];
        System.debug('primaryQuote: '+pQuote); 
        
        Onboarding_Tool__c docDesk = new Onboarding_Tool__c(Opportunity_Id__c = opptyA.Id, Product__c='HR Solutions-Flex', Authorize_Officer__c = c1_a1.Id, Company_Contact__c = c1_a1.Id, New_Existing__c = 'Existing Paychex Client',PESS__c = true,Pop__c = true,HRE_Decision_Factors__c = 'Other');       
        insert docDesk;
        //Set Current Page to new reference
        PageReference pageRef = new PageReference('/apex/OnboardingPDF?id='+opptyA.Id);
        test.setCurrentPageReference(pageRef);
        
        
        //Create OnboardingPDFController
        OnboardingPDFController pdf = new OnboardingPDFController();
        pdf.onboardingRecord.PESS__c = true;
        pdf.onboardingRecord.Product__c = 'HR Solutions-Flex';
        pdf.onboardingRecord.New_Existing__c = 'Existing Paychex Client';
        pdf.onboardingRecord.Pop__c = true;
        pdf.initialize();
        System.assertEquals(pdf.onboardingOpp.Id, opptyA.Id);
    }
    
}