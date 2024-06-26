/**
 * The testMethods for the PriceHelper class.
 
   History
   -------
   05/09/2011 Dan Carmen   Created
   04/20/2012 Dan Carmen   Added tests for setup fee method.
   05/16/2012 Dan Carmen   Allow to have multiple sales orgs on prices
   11/01/2012 Dan Carmen   Modifications to allow Account clone to calculate revenue
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
 
 */
@isTest
private class PriceHelperTest {
	
   static Office_Price_Schedule_Map__c setupTestPriceScheduleMap(String salesOrg, Integer costCenter) {
      Office_Price_Schedule_Map__c opsm = new Office_Price_Schedule_Map__c(
   	                    Name=''+costCenter
   	                   ,Avg__c=5
                       ,Branch_Nbr__c=costCenter
                       ,BW_SM_Pct__c=70
                       ,Monthly_Pct__c=10
                       ,Price_Schedule__c='A'
                       ,Price_Schedule_2__c='I'
                       ,Sales_Org__c=salesOrg
                       ,Wkly_Pct__c=20);
      insert opsm;
      return opsm;
   } // setupTestPriceScheduleMap
   
   static testMethod void testPriceScheduleMap() {
   	  // create a rep
      User u1 = new User(Sales_Org__c='testSalesOrg', Cost_Center__c='0777');
      PriceHelper priceHelper = new PriceHelper();
      // test selecting with no price schedule created
      System.assertEquals(null,priceHelper.getPriceSchedule(u1));
      // test again, this time it should not actually perform the query again
      System.assertEquals(null,priceHelper.getPriceSchedule(u1));
      
      // setup a price schedule
      Office_Price_Schedule_Map__c testOpsm = setupTestPriceScheduleMap('testSalesOrg',777);
      // new instance of PriceHelper so it doesn't use previous stored value
      priceHelper = new PriceHelper();
      priceHelper.setPriceSchedule(u1.Cost_Center__c,u1.Sales_Org__c);
      System.assertEquals(testOpsm.Id,priceHelper.priceScheduleMap.Id);
      //System.assertEquals(testOpsm.Id,priceHelper.getPriceSchedule(u1).Id);
      // select a second rep in the same office as the first
      User u2 = new User(Sales_Org__c='testSalesOrg', Cost_Center__c='0777');
      // should come back with the same record, but this time didn't query the data
      System.assertEquals(testOpsm.Id,priceHelper.getPriceSchedule(u2).Id);

      priceHelper.logPricingError('123', 26);

   } // testPrices
   
   private static Product_Pricing__c getPricing(String pricingType, Decimal amount, Integer lowValue, Integer highValue) {
      Product_Pricing__c pp = new Product_Pricing__c(
                      Name=pricingType
                     ,Amount__c=amount
                     ,Base_Fee__c=50
                     ,Base_Fee_Product_Code__c=null
                     ,Discount_Free_Months_Allowed__c=null
                     ,Discount_Pct_Allowed__c=null
                     ,Enter_Revenue_Manually__c=false
                     ,Frequency_Annual_Rev__c=52
                     ,Frequency_Search__c=52
                     ,High_Value__c=highValue
                     ,Low_Value__c=lowValue
                     ,Minimum_Fee__c=null
                     ,Price_Revenue_Adj__c=null
                     ,Pricing_Schedule__c=null
                     ,Pricing_Type__c=pricingType
                     ,Revenue_Pct__c=null
                     ,Sales_Org__c='PAY'
                     ,Setup_Fee__c=100
                     ,Setup_Fee_Options__c=null);
      return pp;
   } // getPricing
   
   private static void setupPricings() {
      Product_Pricing__c[] pricings = new Product_Pricing__c[]{};
      pricings.add(getPricing('Flat Dollar',50,1,5));
      pricings.add(getPricing('Flat Dollar',100,6,50));

      pricings.add(getPricing('Cumulative Flat Dollar',50,1,5));
      pricings.add(getPricing('Cumulative Flat Dollar',100,6,50));

      pricings.add(getPricing('Rate Per Unit',50,1,5));
      pricings.add(getPricing('Rate Per Unit',100,6,50));

      pricings.add(getPricing('Cumulative Rate Per Unit',50,1,5));
      pricings.add(getPricing('Cumulative Rate Per Unit',100,6,50));

      insert pricings;
   } // setupPricings
   
   static testMethod void testPricingCalc() {
      setupPricings();
      PriceHelper priceHelper = new PriceHelper();
      String[] prodCodes = new String[]{'Flat Dollar','Cumulative Flat Dollar','Rate Per Unit','Cumulative Rate Per Unit'};
      priceHelper.setPricings(prodCodes, 'PAY', 52, 10, false);
      // test Flat Dollar
      priceHelper.calcPrice('Flat Dollar', 'PAY', 52, 10);
      System.assertEquals(150,priceHelper.pricePerPeriod);
      System.assertEquals(7800,priceHelper.priceAnnual);

      // test Cumulative Flat Dollar
      priceHelper.calcPrice('Cumulative Flat Dollar', 'PAY', 52, 10);
      System.assertEquals(200,priceHelper.pricePerPeriod);
      System.assertEquals(10400,priceHelper.priceAnnual);

      // test Rate Per Unit
      priceHelper.calcPrice('Rate Per Unit', 'PAY', 52, 10);
      System.assertEquals(1050,priceHelper.pricePerPeriod);
      System.assertEquals(54600,priceHelper.priceAnnual);

      // test Cumulative Rate Per Unit
      priceHelper.calcPrice('Cumulative Rate Per Unit', 'PAY', 52, 10);
      System.assertEquals(800,priceHelper.pricePerPeriod);
      System.assertEquals(41600,priceHelper.priceAnnual);

   } // testPricingCalc
   
   static testMethod void testNoBaseLevel() {
      Product_Pricing__c[] pricings = new Product_Pricing__c[]{};
      pricings.add(getPricing('Cumulative Rate Per Unit',50,1,5));
      pricings.add(getPricing('Cumulative Rate Per Unit',100,6,50));
      insert pricings;

      PriceHelper priceHelper = new PriceHelper();
      String[] prodCodes = new String[]{'Cumulative Rate Per Unit'};
      priceHelper.setPricings(prodCodes, 'PAY', 52, 10, true);
   	  
      // if no base record, can't calculate price
      // test Cumulative Rate Per Unit
      priceHelper.calcPrice('Cumulative Rate Per Unit', 'PAY', 52, 10);
      System.assertEquals(800,priceHelper.pricePerPeriod);
      System.assertEquals(41600,priceHelper.priceAnnual);
   } // testNoBaseLevel
   
   static testMethod void testOtherCases() {
      // do not pre-set the pricings, let the process retrieve them as part of the calc
      setupPricings();
      PriceHelper priceHelper = new PriceHelper();
      //String[] prodCodes = new String[]{'Flat Dollar','Cumulative Flat Dollar','Rate Per Unit','Cumulative Rate Per Unit'};
      //priceHelper.setPricings(prodCodes, 'PAY', 52, null, 10, true);

      // test with no product code
      priceHelper.calcPrice(null, 'PAY', 52, 6);
      System.assertEquals(0,priceHelper.pricePerPeriod);
      System.assertEquals(0,priceHelper.priceAnnual);
      System.assertEquals(true,priceHelper.enterRevenueManually);

      // test with bad product code
      priceHelper.calcPrice('ThisIsABadProdCode', 'PAY', 52, 6);
      System.assertEquals(true,priceHelper.enterRevenueManually);
      
      // test Cumulative Rate Per Unit
      priceHelper.calcPrice('Cumulative Rate Per Unit', 'PAY', 52, 6);
      System.assertEquals(400,priceHelper.pricePerPeriod);
      System.assertEquals(20800,priceHelper.priceAnnual);
   	
      // check search frequency
      System.assertEquals(26,priceHelper.checkSearchFrequency(26));
      System.assertEquals(26,priceHelper.checkSearchFrequency(24));
      System.assertEquals(4,priceHelper.checkSearchFrequency(4));
      System.assertEquals(12,priceHelper.checkSearchFrequency(12));
      System.assertEquals(52,priceHelper.checkSearchFrequency(52));
   	  
      priceHelper.logPricingError('123', 26);
   } // testOtherCases
   
   static testMethod void testDiscounts() {
      Product_Pricing__c pp = getPricing('Cumulative Rate Per Unit',50,1,10);
      pp.Discount_Free_Months_Allowed__c = 6;
      pp.Discount_Pct_Allowed__c = 33.3;
      insert pp;
      
      PriceHelper priceHelper = new PriceHelper();
      priceHelper.calcPrice('Cumulative Rate Per Unit','PAY',52,6,7,50,7);
      
   } // testDiscounts
   
   static testMethod void testSetupFee() {
      Product_Pricing__c pp = getPricing('Cumulative Rate Per Unit',50,1,10);

      // set up another pricing option
      Product_Pricing__c pp2 = getPricing('Cumulative Rate Per Unit',50,1,10);
      pp2.Name = 'TESTPRODCODE';
      insert pp2;
      
      PriceHelper ph = new PriceHelper();
      ph.baseRecord = pp;
      pp.Setup_Fee__c = null;
      
      // test no setup fee
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('No Setup Fee',ph, false, null, null, false);
      
      // test basic setup fee
      pp.Setup_Fee__c = 100;
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('basic setup fee',ph, true, 100, null, false);

      // test percent setup fee - no value
      pp.Setup_Fee_Options__c = 'PCT:';
      ph.priceAnnual = 100;
      ph.checkSetupFee('PAY', 26, 7);
      // false because no percent entered.
      checkResults('percent setup fee - no value',ph, false, null, null, false);

      // test percent setup fee - correct value
      pp.Setup_Fee_Options__c = 'PCT:  20';
      ph.priceAnnual = 100;
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('percent setup fee - no value',ph, true, 20, null, false);

      // test manual entry
      pp.Setup_Fee_Options__c = 'MANUAL';
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('manual entry',ph, true, null, null, false);
     
      // no setup fee
      pp.Setup_Fee_Options__c = 'NONE';
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('no setup fee',ph, false, null, null, false);
     
      // test no or bad values
      pp.Setup_Fee_Options__c = 'VALUES:  BADNUMBER';
      ph.checkSetupFee('PAY', 26, 7);
      checkResults('test no or bad values',ph, false, null, null, false);
     
      // test list of values
      pp.Setup_Fee_Options__c = 'VALUES:  30;20;10;0';
      ph.checkSetupFee('PAY', 26, 7);
      String[] checkValues = new String[]{'30','20','10','0'};
      checkResults('test list of values',ph, true, 30, checkValues, false);
     
      // test product code
      pp.Setup_Fee_Options__c = 'PRODCODE:TESTPRODCODE';
      ph.checkSetupFee('PAY', 52, 7);
      checkResults('test product code',ph, true, 20800,null, true);
     
       
   } // testSetupFee
   
   private static void checkResults(String testName, PriceHelper ph, Boolean hasSetupFee, Decimal setupFee, String[] setupFeeOptions, Boolean setupFeeTieredPricing) {
   	System.debug('test: '+testName);
      System.assertEquals(hasSetupFee,ph.hasSetupFee);
      System.assertEquals(setupFee,ph.setupFee);
      System.assertEquals(setupFeeOptions,ph.setupFeeOptions);
      System.assertEquals(setupFeeTieredPricing,ph.setupFeeTieredPricing);
   } // checkResults
} // class PriceHelperTest