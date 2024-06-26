@isTest
private class SubmittedRevenueCloneControllerTest {
    
    @isTest static void testConstructor() {
        Opportunity opp = new Opportunity(Name='Test opp', StageName = 'Sold - Submitted', CloseDate=Date.today());
        insert opp;
        
        Test.setCurrentPageReference(new PageReference('Page.SubmittedRevenueClone')); 
        System.currentPageReference().getParameters().put('id', opp.Id);
        
        Test.startTest();
        SubmittedRevenueCloneController controller = new SubmittedRevenueCloneController();
        Test.stopTest();
        
        System.assertEquals(controller.products != null, true);
    }
    
    @isTest static void submittedRevenueCloneTest() {
        Opportunity opp = new Opportunity(Name='Test opp', StageName = 'Sold - Submitted', CloseDate=Date.today(), Payroll_Unit__c = true);
        insert opp;
        
        String[] prodNames = new String[]{'OpptyLineItemTest','Direct Deposit', 'Submitted Revenue Adjustment'};
        PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
        PricebookEntry entry = entries.get(0);
        PricebookEntry entry2 = entries.get(1);
        PricebookEntry entry3 = entries.get(2);
     
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                                          ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5);
        OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry2.Id, Status__c='Pending', ServiceDate=Date.today()
                                                          ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5);
        OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry3.Id, Status__c='Pending', ServiceDate=Date.today()
                                                          ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5);
        
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>{oli, oli2, oli3};
        insert olis;

        Test.setCurrentPageReference(new PageReference('Page.SubmittedRevenueClone')); 
        System.currentPageReference().getParameters().put('id', opp.Id);
        System.currentPageReference().getParameters().put('strCloseDateName', string.valueOf(Date.today()+1));
        
        Test.startTest();
        SubmittedRevenueCloneController controller = new SubmittedRevenueCloneController();
      
        //This will generate another oppty clone
        for(Integer i = 0; i < 1; i++) {
            controller.wrapOppLineItems.get(i).hasRevOnSubmit = true;
            controller.wrapOppLineItems.get(i).selected = true;
        }
  
        controller.processSelected();
        controller.previewOpportunityClones();
        controller.cancel();
        controller.previewOpportunityClones();
        controller.cloneOpportunity();
        Test.stopTest();
        
        List<Opportunity> numOppties = [Select Id, StageName from Opportunity where Name = 'Test Opp'];
        System.assertEquals(String.valueOf(numOppties.size()), '3');
        System.assertEquals(numOppties.get(0).StageName, 'Sold - Submitted');
        System.assertEquals(numOppties.get(1).StageName, 'Sold - Submitted');
        
	}
    
}