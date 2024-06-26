/** Test methods for ProductCalculator and ProductCalculatorBatch
 *
 * History
 * -------
 * 11/07/2012 Dan Carmen   Created
 *
*/
@isTest(SeeAllData=false)
private class ProductCalculatorTest {

   /** Test calculating an opportunity 
    */
   static testMethod void testOppCalc() {
      Pricebook2 pb = ProductHelperTest.setupPricebookAndMap(true);
      
      // reselect the pricebook because the entries aren't attached to this version.
      ProductHelper ph = new ProductHelper();
      Pricebook2 pbCheck = ph.getPricebook(null,pb.Id);

      Opportunity opp = new Opportunity(Name='Test Opp'
                                       ,Pricebook2Id=pb.Id
                                       ,Frequency__c='26'
                                       ,Employees_Paid_Per_Payroll__c=40
                                       ,CloseDate=Date.today().addDays(21)
                                       ,StageName='Pending');
      insert opp;
      
      // olis to create
      OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      
      for (PricebookEntry pbe : pbCheck.PricebookEntries) {
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = opp.Id, PricebookEntryId=pbe.Id);
         oli.Unit__c = (pbe.Product2.Default_Units_to_Employees__c ? opp.Employees_Paid_Per_Payroll__c : 1);
         oli.Quantity = 1;
         oli.TotalPrice = 0;
         oli.ServiceDate = opp.CloseDate;
         olis.add(oli);
      }
      System.debug('insert olis-before');
      insert olis;
      System.debug('insert olis-after');
      
      // verify opportunity line items
      Opportunity testOppQuery = [Select Id, Name, HasOpportunityLineItem
                                       ,(Select Id, PricebookEntryId
                                           From OpportunityLineItems)
                                    From Opportunity
                                   Where Id = :opp.Id];
      System.assertEquals(true,testOppQuery.HasOpportunityLineItem);
      
      Test.startTest();
      
      ProductCalculatorBatch pcb = new ProductCalculatorBatch();
      pcb.opptyIds = new Id[]{opp.Id};
      Database.executeBatch(pcb, 1);
      
      Test.stopTest();
      
   } // testOppCalc
   
} // class ProductCalculatorTest