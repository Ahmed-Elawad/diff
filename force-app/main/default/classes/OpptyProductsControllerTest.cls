/* 
 * Test Methods for the OpptyProductsController class.
 *
 * History
 * -------
 * 08/01/2011 Dan Carmen        Created.
   04/05/2013 Dan Carmen        Modifications so code will pass tests in the sandboxes
 *
 */
@isTest(seeAllData=false)
private class OpptyProductsControllerTest {
   @testSetup
   public static void setupData() {
      ProductSelectorTest.setupData();
   }

   static testMethod void testNoOppty() {
      //Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Opportunity());
      //System.CurrentPageReference().getParameters().put('id',opp1.Id);
      OpptyProductsController opc = new OpptyProductsController(sc1);
      System.assertEquals(false,opc.opptyFound);
      System.assertEquals(false,opc.opptyComplete);
   } // testNoOppty
   
   static testMethod void testOppty() {      
      // verify the mapping is setup
      //ProductPricebookMapTest.verifyMappingSetup('Core Mapping','Core Products','PAY');
      //ProductMappingTest.verifyMappingSetup('Oppty-Default', 'Default-PAY', 'Unknown-PAY', 'PAY');


      Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
      insert opp1;
       
      PricebookEntry[] entries = ProductSelectorTest.getEntries();
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entries[0].Id, ServiceDate=opp1.CloseDate, Quantity=1, TotalPrice=100);
      insert oli;
      // verify product was created
      opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem
                from Opportunity where Id = :opp1.Id];
      System.assertEquals(true,opp1.HasOpportunityLineItem);
      
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new Opportunity());
      System.CurrentPageReference().getParameters().put('id',opp1.Id);
      OpptyProductsController opc = new OpptyProductsController(sc1);
      
      System.assertEquals(true,opc.opptyFound);
      System.assertEquals('Test 1',opc.blockTitle);      
      System.assertEquals(false,opc.readOnly);
      System.assertNotEquals(null,opc.saveProducts());
      System.assertEquals(true,opc.finishSetup());
      System.assertEquals(null,opc.checkOpptyAndContinue());
      System.assertEquals(null, opc.calcRevenue());
      System.assertEquals(null, opc.changePriceSchedule());
      System.assertEquals(false,opc.needServiceLocation);                
   } // testOppty
   
   static testMethod void testOppty2() {      
      // verify the mapping is setup
      //ProductPricebookMapTest.verifyMappingSetup('MMS Mapping','MMS Products','MMS');
      //ProductMappingTest.verifyMappingSetup('Oppty-Default', 'Default-MMS', 'Unknown-MMS', 'MMS');

      Schema.Recordtypeinfo mmsRt = RecordTypeHelper.getRecordType('MMS Opportunity Record Type', 'Opportunity');
      Opportunity opp2 = new Opportunity(Name='Test 2', CloseDate=Date.today(), StageName='Pending', RecordTypeId=mmsRt.getRecordTypeId());
      insert opp2;

      PricebookEntry[] entries = ProductSelectorTest.getEntries();
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp2.Id, PricebookEntryId=entries[0].Id, ServiceDate=opp2.CloseDate, Quantity=1, TotalPrice=100);
      insert oli;

      // verify product was created
      opp2 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem
                from Opportunity where Id = :opp2.Id];
      System.assertEquals(true,opp2.HasOpportunityLineItem);
      
      ApexPages.Standardcontroller sc2 = New ApexPages.StandardController(new Opportunity());
      System.CurrentPageReference().getParameters().put('id',opp2.Id);
      OpptyProductsController opc = new OpptyProductsController(sc2);
      
      System.assertEquals(true,opc.opptyFound);
      System.assertEquals('Test 2',opc.blockTitle);      
      System.assertEquals(false,opc.readOnly);
      System.assertNotEquals(null,opc.saveProducts());
      //System.assertEquals(true,opc.finishSetup());
      System.assertEquals(null,opc.checkOpptyAndContinue());
      System.assertEquals(null, opc.calcRevenue());
      System.assertEquals(null, opc.changePriceSchedule());
      System.assertEquals(false,opc.needServiceLocation);                              
   } // testOppty2 
      
} // class OpptyProductsControllerTest