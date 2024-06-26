/* 
 * Test Methods for the OpptyProductCheck class
 *
 * History
 * -------
  09/03/2017  Jermaine Stukes       Created
  12/05/2017  Cindy Freeman			modified for Benefits Type test
  05/19/2021  Dan Carmen            Changed to use labels for StageName

 */
  
@isTest(seeAllData=false)
public class OpptyProductCheckTest {
    @testSetup
    public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyProductCheck'});
      TriggerMethodsTest.saveSetupClasses();

    } // setupData
    
 static testmethod void testSuccessfulHandbookContact()  {
         //Create Account and Contact
         CreateTestData.createTestAandC();
         Account acct1 = CreateTestData.acct1;
         Contact ct1 = CreateTestData.ctct1;
         //Create Opportunity
         CreateTestData.createTestCoreOptys(acct1.id, ct1.id);
         Opportunity oppty1 = CreateTestData.oppty1;
         oppty1.Handbook_Contact__c = null;
         update oppty1;
         String prodName = 'Employee Handbook Builder';
         String[] prodNames = new String[]{'Employee Handbook Builder'};
         String Pay_Freq = 'Weekly';
         Pricebook2 pb = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
         insert pb;
         List<Product2> productList = new List<Product2>();
         Product2 managedProductA = New Product2(Name = prodName, PayrollFrequency__c = Pay_Freq, ProductCode = 'PAY', IsActive = true);
         productList.add(managedProductA);
         insert productList;
         PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'Employee Handbook Builder',null);
         PricebookEntry entry = entries.get(0);
         // create opportunitylineitems
         OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=oppty1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=100);
         insert oli1;
         oppty1.StageName = Label.OppStage_Sold_Submitted;
         String errorMessage = 'A \"Handbook Contact\" must be entered for this opportunity.';

         try
         {
             update oppty1;
         }
         catch (Exception e) 
         {
             Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
             System.assertEquals(expectedExceptionThrown, true);
         }
         oppty1.Handbook_Contact__c = ct1.Id;
                  try
         {
             update oppty1;
         }
         catch (Exception e) 
         {
             Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
             System.assertEquals(expectedExceptionThrown, false);
         }
         
     } // testSuccessfulHandbookContact
   
    
      static testmethod void testSuccessfulFlexBenAdmin()  {
     	 System.assertEquals('FLEX BA', Label.FLEX_BenAdmin_Product_Code);
     	 
         //Create Account and Contact
         CreateTestData.createTestAandC();
         Account acct1 = CreateTestData.acct1;
         Contact ct1 = CreateTestData.ctct1;
         //Create Opportunity
         CreateTestData.createTestCoreOptys(acct1.id, ct1.id);
         Opportunity oppty1 = CreateTestData.oppty1;
         oppty1.Handbook_Contact__c = null;
         update oppty1;
         String prodName = 'FLEX BA MF';		// need to put product code into the product name so ProductMethodsTest.getEntries returns product code we expect
         String[] prodNames = new String[]{'FLEX BA MF'};
         String Pay_Freq = 'Weekly';
         Pricebook2 pb = new Pricebook2(Name='Core Products', IsActive=true, Sales_Org__c=UserHelper.SO_CORE, Primary__c=true);
         insert pb;
         List<Product2> productList = new List<Product2>();
         Product2 managedProductA = New Product2(Name = prodName, PayrollFrequency__c = Pay_Freq, ProductCode = 'FLEX BA MF', IsActive = true);
         productList.add(managedProductA);
         insert productList;
         PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'FLEX BA MF',null);
         PricebookEntry entry = entries.get(0);
         // create opportunitylineitems
         OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=oppty1.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today(), Quantity=1, TotalPrice=100);
         insert oli1;
                           
         oppty1.StageName = Label.OppStage_Sold_Submitted;
         String errorMessage = 'This opty has a Flex Ben Admin product ';

         try
         {
             update oppty1;
         }
         catch (Exception e) 
         {
             Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
             System.assertEquals(expectedExceptionThrown, true);
         }
         oppty1.Benefit_Types_Offered__c = 'Dental';
         try
         {
             update oppty1;
         }
         catch (Exception e) 
         {
             Boolean expectedExceptionThrown =  e.getMessage().contains(errorMessage) ? true : false;
             System.assertEquals(expectedExceptionThrown, false);
         }
         
     } // test Flex BenAdmin   
 
    
}