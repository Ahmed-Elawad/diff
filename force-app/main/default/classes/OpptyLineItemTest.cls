/* 
   Test methods for the OpptyLineItem trigger.. 
   
  History
  -------
  11/21/2011 Dan Carmen      Created
  12/29/2011 Dan Carmen      Added update to Opportunity revenue, setup fee, and payroll units field if line item changes.
  02/02/2012 Dan Carmen      If a lineitem is inserted, if there's a non-default and default product on the same opportunity, remove the default product.
  08/29/2013 Cindy Freeman   If line item is added to MMS Opty, push product up to oppty.product_summary__c 
  07/30/2019 Dan Carmen      Update the WIN__c (Discount Percent) field on the opp 
  08/23/2019 Jacob Hinds     adding test for exclude revenue  
  03/24/2020 Matt Fritschi   Added test for checking OracleQuoteLines
  04/29/2020 Carrie Marciano Removed Payroll_Frequency__c
  06/01/2020 Jake Hinds      Changing ALLOW DELETE to PREVENT DELETE per label name
  06/15/2021 Carrie Marciano added code to update Oppty Recordtype, Type, Service Location, and Payroll Platform based on products added to oppty for ASO/PEO
  10/26/2021 Dan Carmen      Update test to new method of handling default prods.
  05/22/2023 Dan Carmen      Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
  08/22/2023 Carrie Marciano added code to evaluate Exclude_From_Revenue__c on quotelines that are in Compare Quote
  12/13/2023 Dan Carmen      Changes for performance
  01/18/2024 Dan Carmen      Change in checkOliValueBefore to only match the quote line item by cpq id

 */
@isTest
private class OpptyLineItemTest {
    
   @testSetup
   public static void testSetup() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyCheckFields'});
      TriggerMethodsTest.saveSetupClasses();
      OracleQuoteTriggerPayxHelperTest.setupOracleSetting();
   }
    
   public static void resetFlags() {
      OpptyLineItem.resetFlags();
   } // resetFlags

   static testMethod void testOverrideFlag() {
      ProductMappingTest.clearMappingByType('Oppty-Default');
      // create Opportunity
      Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
      Opportunity[] opps = new Opportunity[]{opp1};
      insert opps;
        
      // get a pricebookentry
      String[] prodNames = new String[]{'OpptyLineItemTest','Direct Deposit'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
      PricebookEntry entry = entries.get(0);
      // create opportunitylineitems
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5,Discount_Percent__c=10.0);
      resetFlags();
      insert oli;
        
      oli = verifyFlag(oli.Id,false);
        
      // verify opportunity values updated
      opp1 = [Select Id, StageName, Amount, Revenue__c, Setup_Fee__c, Payroll_Units__c, Product_Summary__c,WIN__c  from Opportunity where Id = :opp1.Id
               and HasOpportunityLineItem = true];
      System.assertEquals(1000,opp1.Amount);
      System.assertEquals(100,opp1.Setup_Fee__c);
      System.assertEquals(900,opp1.Revenue__c);
      System.assertEquals(2.5,opp1.Payroll_Units__c);
      System.assertEquals(10.0, opp1.WIN__c);

      oli.External_System_Id__c = 'test';
      oli.Status__c = OpptyProducts.COMMISSIONED;
      oli.Setup_Fee__c = 200;
      oli.Payroll_Unit__c = 3;
      oli.Discount_Percent__c = 15.0;
      resetFlags();
      update oli;
      oli = verifyFlag(oli.Id,true);
        
      // verify opportunity status and values updated
      opp1 = [Select Id, StageName, Amount, Revenue__c, Setup_Fee__c, Payroll_Units__c,WIN__c from Opportunity where Id = :opp1.Id];
      //System.assertEquals(OpptyProducts.COMMISSIONED,opp1.StageName);
      System.assertEquals(1000,opp1.Amount);
      System.assertEquals(200,opp1.Setup_Fee__c);
      System.assertEquals(800,opp1.Revenue__c);
      System.assertEquals(3,opp1.Payroll_Units__c);
      System.assertEquals(15.0, opp1.WIN__c);
       
      // flag should stay on if value is removed
      oli.External_System_Id__c = null;
      resetFlags();
      update oli;
      oli = verifyFlag(oli.Id,true);
        
      oli.User_Override__c = false;
      oli.External_System_Id2__c = 'test';
      resetFlags();
      update oli;
      oli = verifyFlag(oli.Id,true);

      entry = entries.get(1);
      // add opportunitylineitem
      oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=0, Setup_Fee__c=0, Payroll_Unit__c=0);
      resetFlags();
      insert oli;
      opp1 = [Select Id, StageName, Amount, Revenue__c, Setup_Fee__c, Payroll_Units__c, Product_Summary__c from Opportunity where Id = :opp1.Id
               and HasOpportunityLineItem = true];
      System.debug('testOverrideFlag opp1='+opp1);
      System.assertEquals(true,opp1.Product_Summary__c.contains('Direct Deposit'));
      // set the 
   } // testOverrideFlag

   private static OpportunityLineItem verifyFlag(Id oliId, Boolean flagValue) {
      // this isn't being handled in the trigger - we won't worry about this test
      OpportunityLineItem oli = [Select Id, User_Override__c, External_System_Id__c, External_System_Id2__c, External_System_Id3__c, External_System_Id_Setup__c from OpportunityLineItem where Id = :oliId];
      //System.assertEquals(flagValue,oli.User_Override__c);
      return oli;
   } // verifyFlag

    static testMethod void testDefaultProd() {
       OpptyLineItem.DISABLE_DELETE=false;
       OpptyLineItem.ALLOW_FUTURE=false;
        // setup the pricebook and default product for core
        Pricebook2 pb1 = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
        insert pb1; 
        // create the default product
        PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Unknown-PAY'},UserHelper.SO_CORE,pb1);
        PricebookEntry entryUnknownPay = entries[0];
        entryUnknownPay.Product2.Is_Default_Product__c=true;
        update entryUnknownPay.Product2;
        pb1.DefaultProduct__c = entryUnknownPay.Product2.Id;
        update pb1;
        
        // create another product
        entries = ProductMethodsTest.getEntries(new String[]{'AnotherProduct'},UserHelper.SO_CORE,pb1);
        
        // verify the mapping is setup
        ProductPricebookMapTest.verifyMappingSetup('Core Mapping',pb1.Name,UserHelper.SO_CORE);
        //ProductMappingTest.verifyMappingSetup('Oppty-Default', 'Default-PAY', 'Unknown-PAY', UserHelper.SO_CORE);
        
        // product should already be setup - products move along with refreshes
        // get the core record type
        Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
        Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
        // so it runs synchronously
        Utilities.SKIP_FUTURE=true;
        insert opp1;
        // verify product was created
        opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c, Pricebook2Id
                ,(Select Id, PricebookEntryId
                  ,PricebookEntry.Product2.Is_Default_Product__c 
                  from OpportunityLineItems)
                from Opportunity where Id = :opp1.Id];
        System.assertEquals(true,opp1.HasOpportunityLineItem);
        System.assertEquals(1,opp1.OpportunityLineItems.size());
        
        // select another product from the same pricebook - doesn't matter what, as long as it's not a default product
        PricebookEntry pbe = [Select Id from PricebookEntry 
                              where Pricebook2Id = :opp1.Pricebook2Id
                              and Product2.Is_Default_Product__c = false
                              and IsActive = true
                              and Product2.IsActive = true
                              limit 1];
        // create a new line item
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=pbe.Id, Quantity=1, TotalPrice=100);
        resetFlags();
        Test.startTest();
        System.debug('testDefaultProd start before default product check');
        OpptyLineItem.ALLOW_FUTURE=true;
        insert oli;
        OpptyLineItem.ALLOW_FUTURE=false;
        Test.stopTest();
        
        // verify default product was deleted
        opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c, Pricebook2Id
                ,(Select Id, PricebookEntryId
                  ,PricebookEntry.Product2.Is_Default_Product__c 
                  from OpportunityLineItems)
                from Opportunity where Id = :opp1.Id];
        System.assertEquals(true,opp1.HasOpportunityLineItem);
        System.assertEquals(1,opp1.OpportunityLineItems.size());
        
        delete oli;
        //System.assertEquals(false,opp1.OpportunityLineItems.get(0).PricebookEntry.Product2.Is_Default_Product__c);
    } // testSettingDefaultProd

    static testMethod void testExcludeRevenue(){
          ProductMappingTest.clearMappingByType('Oppty-Default');
          // create Opportunity
          Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
          Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
          Opportunity[] opps = new Opportunity[]{opp1};
          insert opps;
            
          // get a pricebookentry
          String[] prodNames = new String[]{'OpptyLineItemTest','Direct Deposit'};
          PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
          PricebookEntry entry = entries.get(0);
          entry.Product2.Exclude_Revenue_from_Opportunity__c = true;
          update entry.Product2;
          resetFlags();
          // create opportunitylineitems
          OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                      ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5);
          insert oli;
            
          // verify opportunity values updated
          opp1 = [Select Id, StageName, Amount, Revenue__c, Setup_Fee__c, Payroll_Units__c, Product_Summary__c  from Opportunity where Id = :opp1.Id
                   and HasOpportunityLineItem = true];
          System.assertEquals(0,opp1.Amount);
    } // testExcludeRevenue
    
    static testMethod void testOracleQuoteLine() {
       OpptyLineItem.DISABLE_DELETE=false;
       OpptyLineItem.ALLOW_FUTURE=false;
        // setup the pricebook and default product for core
        Pricebook2 pb1 = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
        insert pb1; 
        // create the default product
        PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Unknown-PAY'},UserHelper.SO_CORE,pb1);
        PricebookEntry entryUnknownPay = entries[0];
        entryUnknownPay.Product2.Is_Default_Product__c=true;
        update entryUnknownPay.Product2;
        pb1.DefaultProduct__c = entryUnknownPay.Product2.Id;
        update pb1;
        
        // verify the mapping is setup
        ProductPricebookMapTest.verifyMappingSetup('Core Mapping',pb1.Name,UserHelper.SO_CORE);
        //ProductMappingTest.verifyMappingSetup('Oppty-Default', 'Default-PAY', 'Unknown-PAY', UserHelper.SO_CORE);
        
        // product should already be setup - products move along with refreshes
        // get the core record type
        Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
        Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
        Utilities.SKIP_FUTURE=true;
        insert opp1;
        // verify product was created
        opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c, Pricebook2Id, AccountId
                ,(Select Id, PricebookEntryId
                  ,PricebookEntry.Product2.Is_Default_Product__c 
                  from OpportunityLineItems)
                from Opportunity where Id = :opp1.Id];
        System.assertEquals(true,opp1.HasOpportunityLineItem);
        System.assertEquals(1,opp1.OpportunityLineItems.size());
        System.debug('testOracleQuoteLine opp1='+opp1);
        // select another product from the same pricebook - doesn't matter what, as long as it's not a default product  
        String[] prodNames = new String[]{'Prod1','Prod2'}; 
        PricebookEntry[] pbes = ProductMethodsTest.getEntries(prodNames,UserHelper.SO_CORE,pb1);
      	PricebookEntry entry1 = pbes.get(0);
      	PricebookEntry entry2 = pbes.get(1);
        
        Pricebook2 checkPb = [Select Id, IsActive, Name
                               ,(Select Id, Name, Pricebook2Id, Product2.Always_Include__c, Product2.Default_Package__c
                                 , Product2.Default_Units_to_Employees__c, Product2.Exclude_Revenue_from_Opportunity__c
                                 , Product2.Has_Child__c, Product2.Id, Product2.In_Short_List__c
                                 , Product2.Is_Default_Product__c, Product2.Is_Dependent_Product__c
                                 , Product2.Is_Non_Payroll_Unit__c, Product2.Is_Package__c
                                 , Product2.Is_Payroll_Unit__c, Product2.Is_Setup_Fee__c, Product2.Name, Product2.Operations_Group__c
                                 , Product2.Payroll_Platform__c, Product2.ProductCode, Product2.Rollup_Product__c
                                 , Product2.Sales_Org__c, Product2.Sort_Order__c, Product2.StockKeepingUnit, Product2.Unit_Type__c
                                 , Product2.cafsl__Part_Number__c, Product2Id, ProductCode, UnitPrice 
                                 From PricebookEntries  where IsActive=true and Product2.IsActive=true order by Product2.Sort_Order__c, Product2.Name )
                              from Pricebook2 Where IsActive=true and Id=:pb1.Id];
        System.debug('checkPb='+(checkPb != null)+' entries='+checkPb.PricebookEntries.size());
        Account acctA = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert acctA;
        
        cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
        cafsl__Oracle_Quote__c quote = new cafsl__Oracle_Quote__c();
        quote.cafsl__Account__c = opp1.AccountId;
        quote.cafsl__Opportunity__c = opp1.Id;
        quote.cafsl__Syncing__c = true;
        quote.Name = 'Test Quote';
        quote.Multi_ID__c = true;
        quote.cafsl__Pricebook_Id__c = opp1.Pricebook2Id;
        quote.cafsl__Data_Set__c = setting.cafsl__Data_Set__c;
        insert quote;
        
        Product2 quoteProduct1 = New Product2(Name = 'HR Solutions', PayrollFrequency__c = 'Weekly', ProductCode = 'ASO', IsActive = true);
        Product2 quoteProduct2 = New Product2(Name = 'Flex Enterprise', PayrollFrequency__c = 'Weekly', ProductCode = 'PFE', IsActive = true);
        Product2[] quoteProducts = new Product2[]{quoteProduct1, quoteProduct2};
        insert quoteProducts;
        
        cafsl__Oracle_Quote_Line_Item__c quoteLine1 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProducts[0].Id, cafsl__Oracle_Quote__c = quote.Id, Prospect_Client__c=acctA.Id
                                                                                          ,cafsl__CPQ_External_Id__c='5858675309',Exclude_From_Revenue__c = True);
        cafsl__Oracle_Quote_Line_Item__c quoteLine2 = new cafsl__Oracle_Quote_Line_Item__c(cafsl__Product__c = quoteProducts[1].Id, cafsl__Oracle_Quote__c = quote.Id, Prospect_Client__c=acctA.Id
                                                                                          ,cafsl__CPQ_External_Id__c='5858675310',Exclude_From_Revenue__c = False);
        cafsl__Oracle_Quote_Line_Item__c[] quoteLines = new cafsl__Oracle_Quote_Line_Item__c[]{quoteLine1, quoteLine2};
        insert quoteLines;
        
        // create a new line item
        OpportunityLineItem oli1 = New OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry1.Id, Quantity=1, UnitPrice=2400, Discount_Amount__c=1, Oracle_Quote_Line__c=quoteLines[0].Id, CPQ_External_Id__c='5858675309');
        OpportunityLineItem oli2 = New OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry2.Id, Quantity=1, UnitPrice=3400, Discount_Amount__c=1, Oracle_Quote_Line__c=quoteLines[1].Id, CPQ_External_Id__c='5858675310');
        OpportunityLineItem[] olis = New OpportunityLineItem[]{oli1,oli2};

        resetFlags();
        Test.startTest();
        OpptyLineItem.ALLOW_FUTURE=true;
        insert olis;
        OpptyLineItem.ALLOW_FUTURE=false;
        Test.stopTest();
        
        // verify default product was deleted
        opp1 = [Select Id, Name, Revenue__c, Amount, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c, Pricebook2Id
                ,(Select Id, PricebookEntryId
                  ,PricebookEntry.Product2.Is_Default_Product__c, Non_Discounted_Revenue__c, Quantity, TotalPrice, Non_Discounted_Price__c
                  from OpportunityLineItems)
                from Opportunity where Id = :opp1.Id];
        Assert.areEqual(true,opp1.HasOpportunityLineItem);
        Assert.areEqual(2,opp1.OpportunityLineItems.size());
        Assert.areEqual(3400,opp1.Amount);
        
        //System.assertEquals(opp1.OpportunityLineItems[0].Non_Discounted_Revenue__c, opp1.OpportunityLineItems[0].Non_Discounted_Price__c * opp1.OpportunityLineItems[0].Quantity);
        
    } // testOracleQuoteLine

    static testMethod void testOpptyFieldUpdates() {
        OpptyLineItem.DISABLE_DELETE=false;
        OpptyLineItem.ALLOW_FUTURE=false;
        // create ProductOpptyMapping__c custom setting
        List<ProductOpptyMapping__c> pomList = new List<ProductOpptyMapping__c>();
        ProductOpptyMapping__c pom = new ProductOpptyMapping__c(Name='Paychex PEO',OpptyPricebookName__c='HRS-PEO-ASO SB',OpptyRecordType__c='PEO Opportunity Record Type',OpptyPayrollPlatform__c='PEO',
                                                                ProductCode__c='PEOBundle',OpptyType__c='PEO',OpptyServiceLocation__c='PEO Service Center');
        pomList.add(pom);
        insert pomList;
        
        //create pricebook
        Pricebook2 asoPB = new Pricebook2(Name='HRS-PEO-ASO SB', IsActive=true);
      	insert asoPB;
      	asoPB= [Select Id, Name, IsActive from Pricebook2 where Name='HRS-PEO-ASO SB'];
      	//Pricebook2 asoPB = new ProductHelper().getPricebook('HRS-PEO-ASO SB',null);
        System.debug('testOpptyFieldUpdates asoPB: '+asoPB);
        
        // create Opportunity
        Schema.Recordtypeinfo asoRt = RecordTypeHelper.getRecordType('ASO Opportunity Record Type', 'Opportunity');
        Opportunity asoOpp = new Opportunity(Name='ASO opp with PEO product', CloseDate=Date.today(), StageName='Pending', RecordTypeId=asoRt.getRecordTypeId(), Pricebook2Id=asoPB.Id);
        Opportunity[] opps = new Opportunity[]{asoOpp};
        insert opps;
        
        Opportunity checkOpp = [Select Id, Pricebook2.Name from Opportunity where Id=:asoOpp.Id];
        Assert.areEqual('HRS-PEO-ASO SB', checkOpp.Pricebook2.Name, 'Pricebook does not match '+checkOpp.Pricebook2.Name);
                
        // create product
        Product2 prodPEO = New Product2(Name = 'Paychex PEO', PayrollFrequency__c = 'Weekly', ProductCode = 'PEOBundle', IsActive = true);
        insert prodPEO;
        prodPEO= [Select Id, Name, ProductCode from Product2 where Name='Paychex PEO'];
        System.debug('testOpptyFieldUpdates prodPEO: '+prodPEO);
        
        Id spricebookId = Test.getStandardPricebookId();
      	System.debug('testOpptyFieldUpdates spricebookId: ' + spricebookId);
     
      	PricebookEntry spbe1 = new PricebookEntry(Pricebook2Id = spricebookId, Product2Id = prodPEO.Id, UnitPrice=5.00, isActive=true, UseStandardPrice=false);
      	PricebookEntry[] spbes = new PricebookEntry[]{spbe1};
      	insert spbes;
        
        // create custom pricebook entry
        PricebookEntry pbe1 = new PricebookEntry(Pricebook2Id = asoPB.Id, Product2Id = prodPEO.Id, UnitPrice=5.00, isActive=true);
      	PricebookEntry[] pbes = new PricebookEntry[]{pbe1};
      	insert pbes;
        
    	PricebookEntry pbe = pbes.get(0);
      	System.debug('testOpptyFieldUpdates pbe: ' + pbe);
        
        // create opportunitylineitems
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=asoOpp.Id, PricebookEntryId=pbe.Id, Status__c='Pending', ServiceDate=Date.today()
                                                          ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5,Discount_Percent__c=10.0);
        resetFlags();    
        Test.startTest();
        System.debug('testOpptyFieldUpdates start before insert oli');
        insert oli;
        Test.stopTest();
        
        // verify fields were updated
        asoOpp = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, 
                  OpportunityId__c, Pricebook2Id, Pricebook2.Name, RecordTypeId, RecordType.Name, OpportunityType__c, Payroll_Platform__c, Service_Location__c 
                  ,(Select Id, PricebookEntryId
                  		,PricebookEntry.Product2.Is_Default_Product__c, Non_Discounted_Revenue__c, Quantity, UnitPrice, Non_Discounted_Price__c
                  		from OpportunityLineItems)
                from Opportunity where Id = :asoOpp.Id];
        System.assertEquals(true,asoOpp.HasOpportunityLineItem);
        System.assertEquals('PEO Opportunity Record Type',asoOpp.RecordType.Name);
        System.assertEquals('PEO',asoOpp.OpportunityType__c);
        System.assertEquals('PEO',asoOpp.Payroll_Platform__c);
        System.assertEquals('PEO Service Center',asoOpp.Service_Location__c);
        
        
    } // testOpptyFieldUpdates
    
   static testMethod void testMultipleLineItems() {
      ProductMappingTest.clearMappingByType('Oppty-Default');
      // create Opportunity
      Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
      insert new Opportunity[]{opp1};
        
      // get a pricebookentry
      String[] prodNames = new String[]{'Prod1','Prod2','Prod3','Prod4','Prod5','Prod6'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
      PricebookEntry entry1 = entries.get(0);
      PricebookEntry entry2 = entries.get(1);
      PricebookEntry entry3 = entries.get(2);
      PricebookEntry entry4 = entries.get(3);
      PricebookEntry entry5 = entries.get(4);
      PricebookEntry entry6 = entries.get(5);
      // create opportunitylineitems
      OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      for (Integer cnt=0; cnt<200; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry1.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=100, Setup_Fee__c=10, Payroll_Unit__c=1,Discount_Percent__c=1.0);
         olis.add(oli);
      }
      // revenue = 20000, setup fees = 2000, payroll units = 200
      for (Integer cnt=0; cnt<200; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry2.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=20, Setup_Fee__c=null, Payroll_Unit__c=null,Discount_Percent__c=5.0);
         olis.add(oli);
      }
      // revenue = 4000
      for (Integer cnt=0; cnt<200; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry3.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=50, Setup_Fee__c=5, Payroll_Unit__c=null,Discount_Percent__c=4.0);
         olis.add(oli);
      }
      // revenue 10000, setup = 1000
      for (Integer cnt=0; cnt<400; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry4.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=10, Setup_Fee__c=null, Payroll_Unit__c=null,Discount_Percent__c=null);
         olis.add(oli);
      }
      // revenue 4000
      for (Integer cnt=0; cnt<400; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry5.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=25, Setup_Fee__c=null, Payroll_Unit__c=null,Discount_Percent__c=null);
         olis.add(oli);
      }
      // revenue 10000
      for (Integer cnt=0; cnt<400; cnt++) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry6.Id, Status__c='Pending', ServiceDate=Date.today()
                                  ,Quantity=1, TotalPrice=5, Setup_Fee__c=null, Payroll_Unit__c=null,Non_Payroll_Unit__c=1, Discount_Percent__c=null);
         olis.add(oli);
      }
      //revenue 2000, non payroll units = 400
      // totals
      // Revenue: 10000 + 2000 + 5000  + 1000 + 2500 + 500 = 21,000
      // Setup: 1000 + 500 = 1500
      // Payroll Units: 100
      // Non Payroll Units: 100
      resetFlags();
      Test.startTest();
      insert olis;
      Test.stopTest();
       
      Opportunity checkOpp = [Select Id, Setup_Fee__c, Payroll_Units__c, Non_Payroll_Units__c, Revenue__c, Amount, Win__c
                                From Opportunity
                               Where Id=:opp1.Id];
      System.debug('testMultipleLineItems checkOpp='+checkOpp);
      Assert.areEqual(50000, checkOpp.Amount);
      Assert.areEqual(3000, checkOpp.Setup_Fee__c);
      Assert.areEqual(200, checkOpp.Payroll_Units__c);
      Assert.areEqual(400, checkOpp.Non_Payroll_Units__c);
   } // testMultipleLineItems
    
} // class OpptyLineItemTest