/**
 * The testMethods for the ProductHelper class.
 
  History
  -------
   05/09/2011 Dan Carmen   Created
   05/16/2012 Dan Carmen   Allow to have multiple sales orgs on prices
   05/30/2012 Dan Carmen   Added logic for Payroll Platform
   11/01/2012 Dan Carmen   Modifications to allow Account clone to calculate revenue
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   02/01/2015 Jacob Hinds  Added in Non Payroll Unit
   11/02/2017 Jacob Hinds  changed how payroll platform picklist is built
   05/18/2021 Carrie Marciano	Carrie Marciano updated to use OppStage labels
   06/07/2022 Dan Carmen      Change to allow Units field to display for Quote Opportunity

*/
@isTest
public class ProductHelperTest {

   @isTest(SeeAllData=false)
   static void testMainCase() {
      ProductHelper prodHelper = new ProductHelper();
      // test default values
      System.assertEquals(true,prodHelper.isShortPkgList);
      System.assertEquals(false,prodHelper.showProdList);
      
      System.assertEquals(false,prodHelper.showAllProducts);
      System.assertEquals(false,prodHelper.showAllColumns);
      System.assertEquals(false,prodHelper.readOnly);
      System.assertEquals(false,prodHelper.includedChildrenExist);
      System.assertEquals(false,prodHelper.hasRevenueSplit);
      System.assertEquals(false,prodHelper.hasPayrollUnit);
      System.assertEquals(false,prodHelper.hasNonPayrollUnit);
      System.assertEquals(false,prodHelper.hasMultiplePlatforms);
      
   } // testMainCase
   
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
   
   // Test retrieving a pricebook.
   @isTest(SeeAllData=false)
   static void testGetPricebook() {
      Pricebook2 pb1 = setupPricebookAndMap(false);
      ProductHelper ph = new ProductHelper();
      
      Pricebook2 pbCheck = ph.getPricebookBySalesOrg('TestSalesOrg');
      // verify retrieved
      System.assertEquals(pb1.Id,pbCheck.Id);
      
      // test sales org that doesn't exist
      pbCheck = ph.getPricebookBySalesOrg('BadSalesOrg');
      // verify nothing retrieved
      System.assertEquals(null,pbCheck);
      
      // test retrieving by pricebook name
      pbCheck = ph.getPricebook('TestSalesOrg',null);
      // verify retrieved
      System.assertEquals(pb1.Id,pbCheck.Id);
      
      // test bad pricebook name
      pbCheck = ph.getPricebook('BadPricebookName',null);
      // verify nothing retrieved
      System.assertEquals(null,pbCheck);
      
      // test retrieving by pricebook id
      System.debug('pricebook id='+pb1.Id);
      pbCheck = ph.getPricebook(null,pb1.Id);
      // verify retrieved
      System.assertEquals(pb1.Id,pbCheck.Id);
      
      System.assertEquals(false,ph.hasPackages);
   } // testGetPricebook
   
   // Test package settings.
   @isTest(SeeAllData=false)
   static void testPackage() {
      Pricebook2 pb1 = setupPricebookAndMap(true);
      ProductHelper ph = new ProductHelper();
      
      Pricebook2 pbCheck = ph.getPricebookBySalesOrg('TestSalesOrg');
      System.assertEquals(true,ph.hasPackages);
      System.assertEquals(false,ph.pkgSelected);
      ph.changePackage();
      ph.checkRevenueSplit();
   } // testPackage
   
   // Test some of the properties of the class 
   @isTest(SeeAllData=false)
   static void testMiscProps() {
      ProductHelper ph = new ProductHelper();
      System.assertEquals(false,ph.useFrequency);
      System.assertEquals(false,ph.useEmpsPerPay);
      ph.salesOrg = UserHelper.SO_CORE;
      System.assertEquals(true,ph.useFrequency);
      System.assertEquals(true,ph.useEmpsPerPay);
      ph.salesOrg = UserHelper.SO_MMS;
      System.assertEquals(true,ph.useFrequency);
      System.assertEquals(true,ph.useEmpsPerPay);
      ph.salesOrg = UserHelper.SO_PEO_ASO;
      System.assertEquals(true,ph.useFrequency);
      System.assertEquals(true,ph.useEmpsPerPay);
      ph.salesOrg = 'BadSalesOrg';
      System.assertEquals(false,ph.useFrequency);
      System.assertEquals(false,ph.useEmpsPerPay);
      
      ph.selectStandaloneProduct();
      System.assertEquals(false,ph.isSold);
      System.assertEquals(false,ph.hasPriceSchedule);
      
   } // testMiscProps

   // Test the flow of the Opportunity.
   @isTest(SeeAllData=false)
   static void testOpptyFlow_noProds() {
      Pricebook2 pb1 = setupPricebookAndMap(true);
      Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30));
      insert oppty;
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Opportunity());
      System.CurrentPageReference().getParameters().put('id',oppty.Id);
      OpptyProductsController opc = new OpptyProductsController(sc1);
      System.assertEquals(false,opc.opptyComplete);
      System.assertEquals(true,opc.opptyFound);
      
      // add frequency and number of employees
      opc.productHelper.oppty.Frequency__c = '26';
      opc.productHelper.oppty.Employees_Paid_Per_Payroll__c = 7;
      System.assertEquals(null,opc.checkOpptyAndContinue());
      System.assertEquals(true,opc.opptyComplete);
      System.assertEquals(true,opc.opptyFound);
      
   } // testOpptyFlow_noProds

   // Test the flow of the Opportunity.
   @isTest(SeeAllData=false)
   static void testOpptyFlow() {
    ProductMappingTest.clearMappingByType('Oppty-Default');
      Pricebook2 pb1 = setupPricebookAndMap(true);
      Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30),Pricebook2=pb1);
      oppty.Frequency__c = '26';
      oppty.Employees_Paid_Per_Payroll__c = 7;
      insert oppty;
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Opportunity());
      System.CurrentPageReference().getParameters().put('id',oppty.Id);
      System.CurrentPageReference().getParameters().put('salesOrg','TestSalesOrg');
      OpptyProductsController opc = new OpptyProductsController(sc1);
      System.assertEquals(true,opc.opptyComplete);
      System.assertEquals(true,opc.opptyFound);
      
      // should be two values in the picklist - standalone and the package
      System.assertEquals(true,opc.productHelper.packagesAvailable);
      System.assertEquals(2,opc.productHelper.pkgOptions.size());
      
      opc.productHelper.setupQuoteProdList();
      opc.productHelper.changeShowProdList();
      opc.productHelper.changeShowPkg();
      
      System.assertEquals('',opc.productHelper.selectedPkgName);
      
      opc.productHelper.isStandAlone = true;
      System.assertEquals(ProductHelper.STANDALONE,opc.productHelper.selectedPkgName);
      opc.productHelper.isStandAlone = false;
      
      // select the package
      opc.productHelper.selectedPkgOption = 'ProductHelperTest3';
      System.assertEquals(null,opc.productHelper.selectPkg());
      
      System.assertEquals('ProductHelperTest3',opc.productHelper.selectedPkgName);
      opc.productHelper.checkRevenueSplit();
      // verify records
      System.assertEquals(3,opc.productHelper.allProdsAndPackages.size());
      // prodList should be one - only the package should display
      System.assertEquals(1,opc.productHelper.prodList.size());
      // verify emp count set where supposed to be
      for (ProductSelector prod : opc.productHelper.allProdsAndPackages) {
         if (prod.selected && prod.entry.Product2.Default_Units_to_Employees__c) {
            System.assertEquals(oppty.Employees_Paid_Per_Payroll__c,prod.oli.Unit__c);
         //} else {
         //   System.assertEquals(1,prod.oli.Unit__c);
         }
      } // for
      
      System.assertNotEquals(null,opc.productHelper.displayProdList);

      // select all products
      //for (ProductSelector prod : opc.productHelper.prodList) {
      //     if (prod.hasEntry) {
      //      prod.selected = true;
      //      System.CurrentPageReference().getParameters().put('entryId',prod.entry.Id);
      //      System.CurrentPageReference().getParameters().put('linkId',prod.linkId);
      //      opc.productHelper.changeProdSelection();
      //     }
      //} // for (ProductSelector
      
   } // testOpptyFlow
   
   @isTest(SeeAllData=false)
   static void tempTests() {
      ProductMappingTest.clearMappingByType('Oppty-Default');
      Pricebook2 pb1 = setupPricebookAndMap(true);
      ProductQuery.clearCache();
      Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30));
      insert oppty;
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Opportunity());
      System.CurrentPageReference().getParameters().put('id',oppty.Id);
      System.CurrentPageReference().getParameters().put('salesOrg','TestSalesOrg');
      OpptyProductsController opc = new OpptyProductsController(sc1);
      System.assertEquals(false,opc.productHelper.hasPayrollUnit);
      System.assertEquals(false,opc.productHelper.hasNonPayrollUnit);
      System.assertEquals(true,opc.productHelper.hasNonShortList);
      System.assertEquals(false,opc.productHelper.hasDiscounting);
      opc.productHelper.saveSelectedProducts(oppty.Id);
      opc.productHelper.applyDiscountAllProducts();
      opc.productHelper.changeFrequency();
      opc.productHelper.changeEmpCount();
      opc.productHelper.getOpptyFreq();
      opc.productHelper.changeShowColumns();
      System.CurrentPageReference().getParameters().put('prodId',oppty.Id);
      System.CurrentPageReference().getParameters().put('adjType','True-Up');
      opc.productHelper.addAdjustment();

      System.CurrentPageReference().getParameters().put('prodId',oppty.Id);
      System.CurrentPageReference().getParameters().put('adjType','Chargeback');
      opc.productHelper.addAdjustment();

      System.CurrentPageReference().getParameters().put('prodId',oppty.Id);
      System.CurrentPageReference().getParameters().put('adjType','Referral');
      opc.productHelper.addAdjustment();

      opc.productHelper.saveSelectedProducts(oppty.Id);
      opc.productHelper.changeShowChildren();
      opc.productHelper.selectPkg();
      //opc.productHelper.changeProdSelection();
      
   } // tempTests
   
   /*
   static testMethod void testLineItemOverride() {
      ProductMappingTest.clearMappingByType('Oppty-Default');
      String[] prodNames = new String[]{'ProductMethodsTest1','ProductMethodsTest2','ProductMethodsTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'ProductMethodsTest1',null);
      // create Opportunity
      Opportunity opp1 = new Opportunity(Name='Test Oppty',StageName='Pending',CloseDate=Date.today().addDays(30));
      insert opp1;
      
      // create lineitems
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=1, PricebookEntryId=entries.get(0).Id, TotalPrice=30);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp1.Id, Quantity=1, PricebookEntryId=entries.get(1).Id, TotalPrice=60);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2};
      insert olis;
      
      //LineitemOverride lo1 = new LineitemOverride(OpportunityLineItemId=oli1.Id);
      //insert lo1;
   } // testLineItemOverride
   */
   
   @isTest
   static void testAdjustments() {
      User curUser = new UserHelper().getUserById(UserInfo.getUserId());
      // make sure a default product is not created
      ProductMappingTest.clearMappingByType('Oppty-Default');
      
      insert new SalesOrg__c(Name='TestProdOrg',Payroll_Platforms__c='PAY');
      // create the products
      String[] prodNames = new String[]{'TestProd1','TestProd2','TestProd3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestProdOrg', null);
      // create an opportunity with the three products
      Opportunity opp = new Opportunity(Name='Test Opp',CloseDate=Date.today().addMonths(1),StageName='Pending',Frequency__c='26',Employees_Paid_Per_Payroll__c=26);
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
    
      ProductHelper ph = new ProductHelper();
      ph.setOpportunity(opp.Id,curUser,false);
      ph.getPricebook(null,ph.oppty.Pricebook2Id);
      
      system.assertEquals('PAY',ph.availPayrollPlatforms[0].getValue());
      
      System.currentPageReference().getParameters().put('prodId',oli3.Id);
      ph.deleteAdjustment();
      
      System.CurrentPageReference().getParameters().put('prodId',oli1.Id);
      System.CurrentPageReference().getParameters().put('adjType','True-Up');
      ph.addAdjustment();
      
      ph.saveSelectedProducts(opp.Id);
      
   } // testAdjustments
    
   @isTest
    static void testPEOImplementation() { 
        List<String>restrictedPEOValueList = Label.PEO_Implementation_Values.split(';');
        List<String>restrictedPEOProfileList = Label.PEO_Implementation_Profiles.split(';');
        //Id opptyRT = RecordTypeHelper.getRecordType(Label.RT_Oppty_PeoC,'Opportunity').getRecordTypeId();
        
        User salesUser = [SELECT Id,Profile.Name from User WHERE IsActive = true AND Profile.Name = :restrictedPEOProfileList[0] LIMIT 1];    
        Account acct = new Account(Name='Test acct',CSCMContractStatus__c=restrictedPEOValueList[0],OwnerId=salesUser.Id);
        insert acct;
        //Opportunity opp = new Opportunity(Name='test opp',RecordTypeId=opptyRT,CloseDate = date.today(),StageName=Label.OppStage_IEUP,OwnerId=salesUser.Id,AccountId=acct.Id);
        Opportunity opp = new Opportunity(Name='test opp',CloseDate = date.today(),StageName=Label.OppStage_IEUP,OwnerId=salesUser.Id,AccountId=acct.Id);
        insert opp;
        Test.startTest();
        system.runAs(salesUser){
            ProductHelper ph = new ProductHelper();
            ph.setOpportunity(opp.Id,salesUser,false);
            ph.setPriceScheduleByCostCenter();
            system.assertEquals(true,ph.readOnly);
        }
        Test.stopTest();
    }
    
   @isTest
   static void testMisc() {
      ProductHelper ph = new ProductHelper();
      System.assertEquals(false,ph.hasGroupedProducts);
      ph.setupQuoteProds();
      ph.checkForNonPayrollUnit();
      System.assertEquals(null,ph.contactId);
   } // testMisc
} // class ProductHelperTest