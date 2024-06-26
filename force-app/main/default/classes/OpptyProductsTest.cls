/* 
 * Test methods for OpptyProducts class and trigger.
 *
 * History
 * -------
 * 11/10/2011 Dan Carmen   Created
   12/23/2011 Dan Carmen   Check to see if opportunity is cloned.
   04/02/2012 Dan Carmen   Fix for cloning check
   07/30/2015 Dan Carmen   Modifications for pilot users
   03/01/2016 Jacob Hinds  Added Referred Commissioned and Referred Sold - Commissioned to getProdStatus
   04/05/2019 Dan Carmen   Modifying how default products are being set.
   07/26/2019 Dan Carmen   Remove test for workflow
   03/16/2021 Carrie Marciano	Removing call to OpptyProducts.getProdStatus, will now set the prodStatus to the Oppty.StageName
   06/29/2021 Dan Carmen   Update checkOpptyAndProductStatusFuture to get around Aggregate query has too many rows error
   03/02/2022 Dan Carmen   APR0131613 Change how default pricebook is set
   10/18/2023 Dan Carmen       Modified addDefaultOpptyLineItemNow so it will work without pricebook sales org 

*/
@isTest(seeAllData=false)
public class OpptyProductsTest {

   @testSetup
   public static void setupDefaultProd() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyCheckFields'});
      TriggerMethodsTest.saveSetupClasses();

      // setup the pricebook and default product for core
      Pricebook2 pb1 = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
      insert pb1; 
      
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'Unknown-PAY','Unknown-HRS'}, UserHelper.SO_CORE, pb1);
      Product2 unknownPAY = null;
      Product2 unknownHRS = null;
      Product2[] updateProds = new Product2[]{};
      for (PricebookEntry entry : entries) {
         if (entry.Product2.Name == 'Unknown-PAY') {
            unknownPAY = new Product2(Id=entry.Product2.Id, Is_Default_Product__c=true, Product_Group__c='Payroll');
            updateProds.add(unknownPAY);
            pb1.DefaultProduct__c = entry.Product2.Id;
         } else if (entry.Product2.name == 'Unknown-HRS') {
            unknownHRS = new Product2(Id=entry.Product2.Id, Is_Default_Product__c=true, Product_Group__c='Retirement');
            updateProds.add(unknownHRS);
         }
      }
      System.assertEquals(2,updateProds.size());
      update updateProds;
      update pb1;
       
      // verify the mapping is setup
      ProductPricebookMapTest.verifyMappingSetup('Core Mapping','Core Products',UserHelper.SO_CORE);
      //ProductMappingTest.verifyMappingSetup('Oppty-Default', 'Default-PAY', 'Unknown-PAY', UserHelper.SO_CORE);
   } // setupDefaultProd

   static testMethod void testProdOfInterest() {
       
      Pricebook2 pb = [Select Id, Name 
                             ,(Select Id, Name
                                 From PricebookEntries)
                         from Pricebook2 
                        where Name='Core Products' limit 1];
       
      System.assertEquals(2,pb.PricebookEntries.size());

      Referral_Partner__c rp1 = new Referral_Partner__c(name= ' test',Partner_Type__c = 'NSS Referral',
                                                       NSS_Source__c = 'Inbound',Evaluate_Product_Of_Interest__c = true,
                                                       Product_Of_Interest_Product_Group__c = 'Payroll');
	   
      Referral_Partner__c rp2 = new Referral_Partner__c(name= ' testRetirement',Partner_Type__c = 'NSS Referral',
                                                       NSS_Source__c = 'Inbound',Evaluate_Product_Of_Interest__c = true,
                                                       Product_Of_Interest_Product_Group__c = 'Retirement');
       
      Referral_Partner__c[] rfList = new Referral_Partner__c[]{rp1,rp2};
      insert rfList;
       
      Opportunity oppPOI = new Opportunity(Name='Test 1',pricebook2id = pb.Id, CloseDate=Date.today(), StageName='Pending', AdditionalProductsOfInterest__c = 'Payroll,Retirement');
      Opportunity[] opps = new Opportunity[]{oppPOI};
      // we don't want it to create the default products here.
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opps;

      Referral__c ref = new Referral__c(Referral_Partner__c=rp1.Id,Selling_Opportunity__c = oppPOI.id, Name='Test Referral',Referring_User__c=UserInfo.getUserId() );
      insert ref;
       
      OpportunityLineItem POIoli1 = new OpportunityLineItem(OpportunityId=oppPOI.Id, Quantity=1, TotalPrice=0, PricebookEntryId=pb.PricebookEntries[0].Id);
      OpportunityLineItem POIoli2 = new OpportunityLineItem(OpportunityId=oppPOI.Id, Quantity=1, TotalPrice=0, PricebookEntryId=pb.PricebookEntries[1].Id);
      OpportunityLineItem[] oilsList = new OpportunityLineItem[]{POIoli1,POIoli2};
      Test.startTest();
      insert oilsList; 
      Test.stopTest();
       
      // should now be 2 referrals
      System.assertEquals(2,[Select count() from Referral__c where Selling_Opportunity__c=:oppPOI.Id]);
      Opportunity oppCheck = [Select Id, ProductGroupsSelected__c from Opportunity where Id=:oppPOI.Id];
      System.assertEquals('Payroll,Retirement', oppCheck.ProductGroupsSelected__c);

   } // testProdOfInterest
    
   // Test that the status and date on the OpportunityLineItems will change when the values on the Opportunity change,
   //    unless the User Override flag is set.
   static testMethod void testOpptyAndProdStatus() {
      ProductMappingTest.clearMappingByType('Oppty-Default');
      // create opportunities
      // pricebook2 pb = new pricebook2(name = 'test');
      // insert pb;
       
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending');
      Opportunity opp2 = new Opportunity(Name='Test 2', CloseDate=Date.today(), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
       insert opps;

      //set<id> optyids= new set<id>();
      //optyids.add(oppPOI.Id);
      //OpptyProducts.EvaluateProductOfInterestNow(optyids);
      // get a pricebookentry
      String[] prodNames = new String[]{'ProductMethodsTest1'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'ProductMethodsTest1',null);
      PricebookEntry entry = entries.get(0);
      // create opportunitylineitems
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=100);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=200);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp2.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=100);
      // the values should not change here
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opp2.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=200, User_Override__c=true);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4};
      insert olis;
      
      // change status and date on opportunities
      opp1.CloseDate = Date.today().addDays(14);
      opp1.StageName = 'Sold';
      opp2.CloseDate = Date.today().addDays(21);
      opp2.StageName = 'Sold - Submitted';
      Test.StartTest();
      update opps;
      Test.StopTest();
      
      // verify lineitems change to match.
      testLineItem(oli1.Id,Date.today().addDays(14),'Sold');
      testLineItem(oli2.Id,Date.today().addDays(14),'Sold');
      testLineItem(oli3.Id,Date.today().addDays(21),'Sold - Submitted');
      testLineItem(oli4.Id,Date.today(),'Pending');
   } // testOpptyAndProdStatus
   
   // Verify that the lineitems change
   private static void testLineItem(Id oliId, Date checkDate, String status) {
      OpportunityLineItem oli = [Select Id, Status__c, ServiceDate from OpportunityLineItem where Id=:oliId];
      System.assertEquals(checkDate,oli.ServiceDate);
      System.assertEquals(status,oli.Status__c);
   } // testLineItem

   static testMethod void testSettingDefaultProd() {
      Utilities.SKIP_FUTURE = false;
    
      // get the core record type
      Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
      System.debug('inserting opp1');
      Test.StartTest();
      insert opp1;
      Test.StopTest();
      // verify product was created
      opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c
                from Opportunity where Id = :opp1.Id];
      System.assertEquals(true,opp1.HasOpportunityLineItem);
      // this is testing the workflow - we don't need to test workflow
      //System.assertEquals(opp1.Id,opp1.OpportunityId__c);
      
      // if we clone this opportunity, it should not create line items.
      Opportunity opp2 = opp1.clone(false,true,false);
      System.debug('inserting opp2');
      Utilities.SKIP_FUTURE = true;
      TriggerMethods.clearVariables();
      insert opp2;
      opp2 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c
               from Opportunity where Id = :opp2.Id];
      System.assertEquals(false,opp2.HasOpportunityLineItem);
   } // testSettingDefaultProd

   static testMethod void testSettingDefaultProd2() {
      Utilities.SKIP_FUTURE = false;
      Pricebook2 pb = [Select Id, Name from Pricebook2 where Name='Core Products' limit 1];
    
      // get the core record type
      Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
      Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId(), Pricebook2Id=pb.Id
                                           ,AdditionalProductsOfInterest__c='Payroll,Retirement',EvaluateProductGroupOverride__c=true);
      System.debug('testSettingDefaultProd2 inserting opp1');
      Test.StartTest();
      insert opp1;
      Test.StopTest();
      // verify product was created
      opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c
                from Opportunity where Id = :opp1.Id];
      System.assertEquals(true,opp1.HasOpportunityLineItem);
      // should be 2 because of product of interest
      System.assertEquals(2,[Select count() from OpportunityLineItem where OpportunityId=:opp1.Id]);
      
   } // testSettingDefaultProd2

   static testMethod void testRunAsRelationalJunction() {
    UserHelperTest.setupGenericUsers();
    
    User u = [Select Id from User where Name='Relational Junction' and IsActive=true limit 1];
    System.runAs(u) {
         // get the core record type
         Schema.Recordtypeinfo coreRt = RecordTypeHelper.getRecordType('Core Opportunity Record Type', 'Opportunity');
         Opportunity opp1 = new Opportunity(Name='Test 1', CloseDate=Date.today(), StageName='Pending', RecordTypeId=coreRt.getRecordTypeId());
         System.debug('inserting opp1');
         insert opp1;
         // verify no product was created
         opp1 = [Select Id, Name, CloseDate, StageName, HasOpportunityLineItem, OpportunityId__c
                   from Opportunity where Id = :opp1.Id];
         System.assertEquals(false,opp1.HasOpportunityLineItem);
        
     } // System.runAs
   } // testRunAsRelationalJunction
   
} // class OpptyProductsTest