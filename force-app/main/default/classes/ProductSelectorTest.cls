/* 
 * Test Methods for the ProductSelector class.
 *
 * History
 * -------
 * 08/02/2011 Dan Carmen   Created
   04/02/2012 Dan Carmen   Added more tests for adjustments.
   10/18/2012 Dan Carmen   Added matchKey method
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   08/26/2015 Dan Carmen   Changes to handle grouped products (steelbrick)
   11/11/2020 Dan Carmen   Don't store the pricebook entry in the product selector

*/
//@isTest
@IsTest(SeeAllData=false)
public class ProductSelectorTest {
    
   @testSetup
   public static void setupData() {
      String[] prodNames = new String[]{'ProductMethodsTest1','ProductMethodsTest2','ProductMethodsTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'ProductMethodsTest', null);
      PricebookEntry entry = entries.get(0);
      Product2 prod = new Product2(Id=entry.Product2Id, Unit_Type__c='Widget'); //[Select Id, Unit_Type__c from Product2 where id = :entry.Product2Id];
      //prod.Unit_Type__c = 'Widget';
      PricebookEntry entry3 = entries[2];
      Product2 prod3 = new Product2(Id=entry3.Product2Id, Is_Package__c=true);
      Product2[] updateProds = new Product2[]{prod,prod3};
      update updateProds;
      ProductQuery.clearCache();

   } // setupData
   
   // Create and return a PricebookEntry.
   public static PricebookEntry[] getEntries() {
      PricebookEntry[] entries = [Select Id, Pricebook2Id, Product2Id,UnitPrice,UseStandardPrice,IsActive
                                    ,ProductCode
                                    ,Product2.Name
                                    ,Product2.ProductCode
                                    ,Product2.Default_Units_to_Employees__c
                                    ,Product2.Is_Payroll_Unit__c
                                    ,Product2.Is_Non_Payroll_Unit__c
                                    ,Product2.Is_Package__c 
                                    ,Product2.Unit_Type__c
                                from PricebookEntry where Product2.Name like 'ProductMethodsTest%'
                                 and Pricebook2.Name='ProductMethodsTest'
                                order by Product2.Name];
      System.debug('getEntries entries='+entries.size());
      return entries;
   } // getEntries
   

   // Test the main constructor and the variables set.
   static testMethod void testMainConstructor() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(false,ps.displayAllChildren);
      System.assertEquals(null,ps.entry);
      System.assertEquals(false,ps.selected);
      System.assertEquals(false,ps.pricingExistsButDoesntMatch);
      System.assertEquals(null,ps.oppty);
      System.assertEquals('Total',ps.name);
      System.assertEquals(null,ps.getDescription());
      System.assertEquals(false,ps.hasAlwaysDisplayChildren());
      System.assertEquals(false,ps.hasChildren);
      System.assertEquals(false,ps.hasEntry);
      System.assertEquals(false,ps.hasHiddenChildren);
      System.assertEquals(false,ps.hasIncludedChildren());
      System.assertEquals(false,ps.hasPricingInfo);
      System.assertEquals(false,ps.hasSavedChildren());
      System.assertEquals(false,ps.prodIsSaved);
      System.assertEquals(0,ps.getlevel());
      System.assertEquals(0,ps.levels.size());
      System.assertEquals(null,ps.addChild(null,null));
      System.assertEquals(false,ps.addChild(null));
      System.assertEquals(true,ps.setChildrenToParentFlag());
      System.assertEquals(false,ps.isSetIfParentSet());
      System.assertEquals(null,ps.initialCalcPerformed);
      System.assertEquals(false,ps.isChild);
      System.assertEquals(false,ps.isAdjustment);
      System.assertEquals(false,ps.isChildOfPackage());
      System.assertEquals(false,ps.isMandatory);
      System.assertEquals(false,ps.isParentSelected);
      System.assertEquals(false,ps.isPkg);
      System.assertEquals(null,ps.includeType);
      System.assertEquals(false,ps.includedInParentPrice);
      System.assertEquals(false,ps.showPricePerFreq);
      
      ps.getDisplayChildren(null);
      ps.getSavedChildren(null);
      ps.resetProd();
      ps.clearLineItem();
   } // testMainConstructor
   
   // Test the other constructors.
   static testMethod void testOtherConstructors() {
   	  ProductMappingTest.clearMappingByType('Oppty-Default');
      PricebookEntry entry = getEntries()[0];
      // add a line item that's been saved
      Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30));
      insert oppty;
      ProductSelector ps1 = new ProductSelector(entry,oppty);
      System.assertEquals(entry.Id,ps1.entry.Id);
      System.assertEquals(oppty.Id,ps1.oppty.Id);
      
      ProductSelector parent = new ProductSelector();
      Product_Parent_Child_Link__c prodLink = new Product_Parent_Child_Link__c();
      ps1.parent = parent;
      ps1.prodLink = prodLink;
      
      ProductSelector ps2 = new ProductSelector(ps1);
      System.assertEquals(entry.Id,ps2.entry.Id);
      System.assertEquals(oppty.Id,ps2.oppty.Id);
      
   } // testOtherConstructors
   
   // Test the revenue flags.
   static testMethod void testRevenueFlags() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(null,ps.revAdj);
      System.assertEquals(null,ps.estRev);
      System.assertEquals(false,ps.showRevCalcd);
      System.assertEquals(false,ps.showRevAdj);
      System.assertEquals(false,ps.showRevTotal);
      System.assertEquals(false,ps.enterRevenueManually);
      System.assertEquals(false,ps.hasRevenue());
      System.assertEquals(false,ps.showRevenue);
      
      OpportunityLineItem oli = new OpportunityLineItem();
      ps.oli = oli;
      oli.Total_Calced__c = 100;
      System.assertEquals(true,ps.showRevCalcd);

      ps.selected=true;
      System.assertEquals(true,ps.showRevTotal);
      ps.hasPricingInfo = true;
      System.assertEquals(true,ps.showRevTotal);
      ps.selected=true;
      ProductSelector parent = new ProductSelector();
      Product_Parent_Child_Link__c prodLink = new Product_Parent_Child_Link__c();
      prodLink.Remove_Price__c = 100;
      ps.prodLink = prodLink;
      ps.selected=false;
      ps.parent = parent;
      ps.parent.selected=true;
      // if not selected, should still show rev total since remove price.
      System.assertEquals(true,ps.showRevTotal);
      ps.selected=true;
      
      System.assertEquals(null,ps.revAdj);
      System.assertEquals('0.00',ps.estRev);
      ps.oli.Rev_Adj__c = 100;
      ps.oli.TotalPrice = 200;
      System.assertEquals('100.00',ps.revAdj);
      System.assertEquals('200.00',ps.estRev);
      ps.revAdj = '149.99';
      ps.estRev = '249.90';
      System.assertEquals('149.99',ps.revAdj);
      System.assertEquals('249.90',ps.estRev);
      ps.revAdj = 'revAdj';
      ps.estRev = 'estRev';
      System.assertEquals('149.99',ps.revAdj);
      System.assertEquals('249.90',ps.estRev);
      ps.revAdj = null;
      ps.estRev = null;
      System.assertEquals(null,ps.revAdj);
      System.assertEquals(null,ps.estRev);
      
   } // testRevenueFlags

   // Test the prodId field.
   static testMethod void testProdId() {
   	ProductMappingTest.clearMappingByType('Oppty-Default');
      ProductSelector ps = new ProductSelector();
      System.assertEquals('NoId',ps.prodId);
      ps.resetProdId();
      // add a line item with a PricebookEntry (not saved) and adjustment
      PricebookEntry entry = getEntries()[0];
      //ps.entry = getEntry();
      ps.entryId = entry.Id;
      ps.pricebookId = entry.Pricebook2Id;
       
      ps.setupLineItem(null);
      ps.selected = true;
      ps.oli.Adj_Type__c='Test';
      System.assertEquals(ps.entry.Id+'Test',ps.prodId);
      ps.resetProdId();
      
      // add a line item that's been saved
      Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30));
      insert oppty;
      ps.oli.OpportunityId = oppty.Id;
      ps.oli.Quantity = 1;
      insert ps.oli;
      System.assertEquals(ps.oli.Id,ps.prodId);
      ps.resetProdId();
      
      System.assertEquals('ProductMethodsTest1',ps.pricingProdCode);
      Product_Parent_Child_Link__c prodLink = new Product_Parent_Child_Link__c();
      prodLink.Price_Schedule_Product_Code__c='TestPriceProductCode';
      ps.prodLink = prodLink;
      System.assertEquals('TestPriceProductCode',ps.pricingProdCode);
      
   } // testProdId
   
   // Test the unit methods. 
   static testMethod void testUnit() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(false,ps.unitChanged);
      System.assertEquals(null,ps.unit);
      System.assertEquals(false,ps.enterUnit);
      System.assertEquals('Total',ps.name);
      System.assertEquals(null,ps.getDescription());

      OpportunityLineItem oli = new OpportunityLineItem();
      ps.oli = oli;
      System.assertEquals(null,ps.unit);
      ps.oli.Unit__c = 3;
      System.assertEquals('3',ps.unit);
      System.assertEquals(false,ps.unitChanged);
      ps.unit = '5';
      System.assertEquals('5',ps.unit);
      System.assertEquals(true,ps.unitChanged);
      ps.unit = 'Unit';
      System.assertEquals('5',ps.unit);
      System.assertEquals(false,ps.unitChanged);

      ps.selected = true;
      ps.pricingExistsButDoesntMatch = false;
      
      PricebookEntry entry = getEntries()[0];

      ps.entryId = entry.Id;
      ps.pricebookId = entry.Pricebook2Id;

      System.assertEquals(true,ps.enterUnit);
      
      System.assertEquals('ProductMethodsTest1',ps.name);
      System.assertEquals('ProductMethodsTest1',ps.getDescription());
      ProductSelector parent = new ProductSelector();
      //parent.entry = ps.entry;
      parent.entryId = ps.entryId;
      parent.pricebookId = ps.pricebookId;
       
      ps.parent = parent;
      System.assertEquals('ProductMethodsTest1, parent=ProductMethodsTest1',ps.getDescription());
      
      
   } // testUnit

   static testMethod void testGetPackageId() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(null,ps.getPackageId());
      System.assertEquals(false,ps.isChildOfPackage());
      ProductSelector parent = new ProductSelector();
      ps.parent = parent;
      System.assertEquals(null,ps.getPackageId());
      System.assertEquals(false,ps.isChildOfPackage());
      //parent.entry = getEntry();
      PricebookEntry[] entries = getEntries();
      PricebookEntry entry1 = entries[0];
      PricebookEntry entry2 = entries[1];
      PricebookEntry entry3 = entries[2];
      System.debug('testGetPackageId entry1='+entry1.Product2.Name+',pkg='+entry1.product2.Is_Package__c+' entry2='+entry2.Product2.Name+',pkg='+entry2.Product2.Is_Package__c+' entry3='+entry3.Product2.name+',pkg='+entry3.Product2.Is_Package__c);

      //ps.entry = getEntry();
      ps.entryId =entry1.Id;
      ps.pricebookId = entry1.Pricebook2Id;
       
      parent.entryId = entry2.Id;
      parent.pricebookId = entry2.Pricebook2Id;

      //parent.entry.Product2.Is_Package__c = false;
      System.assertEquals(null,ps.getPackageId());
      System.assertEquals(false,ps.isChildOfPackage());
       
      System.debug('testGetPackageId prod='+entry3.Product2.Name+' isPackage='+entry3.Product2.Is_Package__c);
      parent.entryId = entry3.Id;
      parent.pricebookId = entry3.Pricebook2Id;
      //entry.Product2.Is_Package__c = true;
      System.assertEquals(parent.entry.Product2Id,ps.getPackageId());
      System.assertEquals(true,ps.isChildOfPackage());
      
      System.assertEquals(parent.entry.Product2.Id,ps.getRollupProductId());
      
      System.assertEquals(true,parent.productMatches(parent.entry.Id, null));
      
      ProductSelector parent2 = new ProductSelector();
      ps.parent = parent2;
      parent2.parent = parent;
      System.assertEquals(parent.entry.Product2Id,ps.getPackageId());
      System.assertEquals(true,ps.isChildOfPackage());
   } // testGetPackageId
   
   // Test the setup fee options.
   static testMethod void testSetup() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(null,ps.setupFee);
      System.assertEquals(false,ps.hasSetupFee);
      System.assertEquals(false,ps.hasSetupFeePicklist);
      System.assertEquals(null,ps.hasEnterableSetupFee);
      ps.hasEnterableSetupFee = true;
      System.assertEquals(true,ps.hasEnterableSetupFee);
      ps.hasEnterableSetupFee = false;
      System.assertEquals(false,ps.hasEnterableSetupFee);
      
      System.assertEquals(null,ps.setupFeeSelectedOption);
      OpportunityLineItem oli = new OpportunityLineItem();
      ps.oli = oli;
      System.assertEquals(null,ps.setupFeeSelectedOption);
      ps.oli.Setup_Fee__c = 99.95;
      System.assertEquals(true,ps.hasSetupFee);
      System.assertEquals('99',ps.setupFeeSelectedOption);
      ps.setupFeeSelectedOption='69.96';
      System.assertEquals('69',ps.setupFeeSelectedOption);
      ps.setupFeeSelectedOption='Setup';
      System.assertEquals(null,ps.setupFeeSelectedOption);
      System.assertEquals(false,ps.hasSetupFee);
      
      ps.setupFee = null;
      System.assertEquals(null,ps.setupFee);
      System.assertEquals(false,ps.hasSetupFee);
      ps.setupFee = '';      
      System.assertEquals(null,ps.setupFee);
      System.assertEquals(false,ps.hasSetupFee);
      ps.setupFee = '49.95';
      System.assertEquals('49.95',ps.setupFee);
      System.assertEquals(true,ps.hasSetupFee);
      ps.setupFee = '59.956';
      System.assertEquals('59.96',ps.setupFee);
      System.assertEquals(true,ps.hasSetupFee);
      // if invalid value is passed in, do not change previous value.
      ps.setupFee = 'Setup';
      System.assertEquals('59.96',ps.setupFee);
      System.assertEquals(true,ps.hasSetupFee);
   } // testSetup
    
   // Test if there's a payroll unit.
   static testMethod void testPayrollUnit() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(false,ps.hasPayrollUnit);
      OpportunityLineItem oli = new OpportunityLineItem();
      System.assertEquals(false,ps.hasPayrollUnit);
      ps.oli = oli;
      oli.Payroll_Unit__c = 1;
      System.assertEquals(true,ps.hasPayrollUnit);
   } // testPayrollUnit
   
   // Test if there is a remove price.
   static testMethod void testHasRemovePrice() {
      ProductSelector ps = new ProductSelector();
      System.assertEquals(false,ps.hasRemovePrice);
      Product_Parent_Child_Link__c prodLink = new Product_Parent_Child_Link__c();
      ps.prodLink = prodLink;
      System.assertEquals(false,ps.hasRemovePrice);
      prodLink.Remove_Price__c = 100;
      System.assertEquals(true,ps.hasRemovePrice);
   } // testHasRemovePrice
   
   // Test the billing period method
   static testMethod void testBillingPeriod() {
      ProductSelector ps = new ProductSelector();
      // test no oli
      System.assertEquals(null,ps.billingPeriod);
      OpportunityLineItem oli = new OpportunityLineItem();
      ps.oli = oli;
      // test no frequency set
      System.assertEquals(null,ps.billingPeriod);
      // test an unknown frequency
      oli.Frequency__c = 77;
      System.assertEquals(null,ps.billingPeriod);
      // test valid frequencies
      oli.Frequency__c = 52;
      System.assertEquals(' /Weekly',ps.billingPeriod);
      oli.Frequency__c = 26;
      System.assertEquals(' /Bi-Weekly',ps.billingPeriod);
      oli.Frequency__c = 24;
      System.assertEquals(' /Semi-Monthly',ps.billingPeriod);
      oli.Frequency__c = 12;
      System.assertEquals(' /Monthly',ps.billingPeriod);
      oli.Frequency__c = 4;
      System.assertEquals(' /Quarterly',ps.billingPeriod);
      oli.Frequency__c = 2;
      System.assertEquals(' /Semi-Annually',ps.billingPeriod);
      oli.Frequency__c = 1;
      System.assertEquals(' /Annually',ps.billingPeriod);
   } // testBillingPeriod

   // Test the discounting portion.
   static testMethod void testDiscounts() {
      ProductSelector ps = new ProductSelector();
      // test default options
      System.assertEquals(0,ps.maxFreeMonths);
      System.assertEquals(0,ps.maxDiscMonths);
      System.assertEquals(false,ps.hasDiscPct);
      System.assertEquals(null,ps.selectedFreeMonths);
      System.assertEquals(null,ps.selectedDiscMonths);
      
      // free months settings
      System.assertEquals(0,ps.freeMonthsOptions.size());
      System.assertEquals(false,ps.freeMonthsAllowed);
      // if free months set, should be allowed.
      ps.maxFreeMonths = 3;
      System.assertEquals(true,ps.freeMonthsAllowed);
      System.assertEquals(4,ps.freeMonthsOptions.size());

      // discount month settings
      System.assertEquals(0,ps.discMonthsOptions.size());
      System.assertEquals(false,ps.discPctAllowed);
      ps.maxDiscMonths = 3;
      System.assertEquals(true,ps.discPctAllowed);
      System.assertEquals(4,ps.discMonthsOptions.size());
      
      // test with a line item
      OpportunityLineItem oli = new OpportunityLineItem();
      ps.oli = oli;
      System.assertEquals(null,ps.selectedFreeMonths);
      oli.Discount_Free_Months__c = 3;
      System.assertEquals('3',ps.selectedFreeMonths);
      ps.selectedFreeMonths = '6';
      System.assertEquals('6',ps.selectedFreeMonths);
      ps.selectedFreeMonths = 'TEST';
      System.assertEquals(null,ps.selectedFreeMonths);
      
      System.assertEquals(null,ps.selectedDiscMonths);
      oli.Discount_Months__c = 3;
      System.assertEquals('3',ps.selectedDiscMonths);
      ps.selectedDiscMonths = '6';
      System.assertEquals('6',ps.selectedDiscMonths);
      ps.selectedDiscMonths = 'TEST';
      System.assertEquals(null,ps.selectedDiscMonths);

   } // testDiscounts
   
   @isTest
   static void testAdjustments() {
      // make sure a default product is not created
      ProductMappingTest.clearMappingByType('Oppty-Default');
      // create the products
      String[] prodNames = new String[]{'TestProd1','TestProd2','TestProd3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestProdOrg', null);
      // create an opportunity with the three products
      Opportunity opp = new Opportunity(Name='Test Opp',CloseDate=Date.today().addMonths(1),StageName='Pending');
      insert opp;
      
      // add line items
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id);
      OpportunityLineItem oli1a = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id,Adj_Type__c=ProductHelper.CHARGEBACK);
      OpportunityLineItem oli1b = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id,Adj_Type__c=ProductHelper.TRUEUP);
      OpportunityLineItem oli1c = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id,Adj_Type__c=ProductHelper.REFERRAL);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=200, PricebookEntryId=entries.get(1).Id);
      OpportunityLineItem oli2a = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id,Adj_Type__c=ProductHelper.TRUEUP);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=300, PricebookEntryId=entries.get(2).Id);
      OpportunityLineItem oli3a = new OpportunityLineItem(OpportunityId=opp.Id, Quantity=1, TotalPrice=100, PricebookEntryId=entries.get(0).Id,Adj_Type__c=ProductHelper.REFERRAL);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli1a,oli1b,oli1c,oli2a,oli3a};
      insert olis;
    
      // create a new ProductSelector instance based on the first entry
      ProductSelector ps1 = new ProductSelector(entries.get(0),opp);
      // keep track of the adjustments
      List<ProductSelector> adjustments = new List<ProductSelector>();
      
      ProductSelector tempPs = new ProductSelector();
      
      ps1.setMatchKey();
      System.assertEquals(false,ps1.lineItemMatchesProd(oli2, tempPs.getKey(oli2.PricebookEntryId,oli2.Product_Parent_Child_Link__c,null), adjustments));
      System.assertEquals(true,ps1.lineItemMatchesProd(oli1, tempPs.getKey(oli1.PricebookEntryId,oli1.Product_Parent_Child_Link__c,null), adjustments));
      // verify no adjustments
      System.assertEquals(0,adjustments.size());
      System.assertEquals(false,ps1.hasChargeback);
      System.assertEquals(false,ps1.hasTrueup);
      System.assertEquals(false,ps1.hasReferral);
      
      // should be false but added an adjustment
      System.assertEquals(false,ps1.lineItemMatchesProd(oli1a, tempPs.getKey(oli1a.PricebookEntryId,oli1a.Product_Parent_Child_Link__c,null), adjustments));
      // verify no adjustments
      System.assertEquals(1,adjustments.size());
      System.assertEquals(true,ps1.hasChargeback);
      System.assertEquals(false,ps1.hasTrueup);
      System.assertEquals(false,ps1.hasReferral);
 
       // should be false but added an adjustment
      System.assertEquals(false,ps1.lineItemMatchesProd(oli1b, tempPs.getKey(oli1b.PricebookEntryId,oli1b.Product_Parent_Child_Link__c,null), adjustments));
      // verify no adjustments
      System.assertEquals(2,adjustments.size());
      System.assertEquals(true,ps1.hasChargeback);
      System.assertEquals(true,ps1.hasTrueup);
      System.assertEquals(false,ps1.hasReferral);
 
       // should be false but added an adjustment
      System.assertEquals(false,ps1.lineItemMatchesProd(oli1c, tempPs.getKey(oli1c.PricebookEntryId,oli1c.Product_Parent_Child_Link__c,null), adjustments));
      // verify no adjustments
      System.assertEquals(3,adjustments.size());
      System.assertEquals(true,ps1.hasChargeback);
      System.assertEquals(true,ps1.hasTrueup);
      System.assertEquals(true,ps1.hasReferral);
      
      List<ProductSelector> checkRecs = new List<ProductSelector>();
      ps1.addAdjustments(checkRecs);
      System.assertEquals(3,checkRecs.size());
      
      
      ps1.resetProd();
      ps1.clearLineItem();
      
   } // testAdjustments

} // class ProductSelectorTest