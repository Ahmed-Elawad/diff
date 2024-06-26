@isTest
private class CloneOpportunityControllerTest {
	
	@isTest static void testConstructor() {
		Opportunity opp = new Opportunity(Name='test opp', StageName = 'Test', CloseDate=Date.today());
		insert opp;

		Test.setCurrentPageReference(new PageReference('Page.CloneOpportunity')); 
		System.currentPageReference().getParameters().put('id', opp.Id);

		Test.startTest();
		CloneOpportunityController controller = new CloneOpportunityController();
		Test.stopTest();

		System.assertEquals(controller.clonedOpp != null, true);
	}


	@isTest static void cloneOpportunityTest() {
		Opportunity opp = new Opportunity(Name='test opp', StageName = 'Test', CloseDate=Date.today());
		insert opp;
        
          String[] prodNames = new String[]{'OpptyLineItemTest','Direct Deposit'};
          PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
          PricebookEntry entry = entries.get(0);
          // create opportunitylineitems
          OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                      ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5, Non_Payroll_Unit__c=1.5);
          insert oli;
         
        AccountMethodsTest.setupTestAcctCtct(1); 

        // reselect the contact
         Contact ctct = [Select AccountId, Account.Id, Account.Name, Dialed__c, FirstName, LastName, Name, Phone, Products__c from Contact where Id=:AccountMethodsTest.testCtcts[0].Id];
        
         OpportunityContactRole oCR = new OpportunityContactRole( ContactId = ctct.id, IsPrimary=true, OpportunityId = opp.Id); 
         insert oCR;   

		Test.setCurrentPageReference(new PageReference('Page.CloneOpportunity')); 
		System.currentPageReference().getParameters().put('id', opp.Id);

		Test.startTest();
		CloneOpportunityController controller = new CloneOpportunityController();
		controller.cloneWithProducts = true;
        controller.updateProductDisplay();
		controller.cloneOpportunity();
		Test.stopTest();

		System.assertEquals(controller.clonedOpp.Id != null, true);
        System.assertEquals(controller.clonedOpp.Primary_Opportunity__c == opp.Id, true);
        System.assertEquals(controller.clonedOpp.Payroll_Units__c == oli.Payroll_Unit__c, true);
        System.assertEquals(controller.clonedOpp.Non_Payroll_Units__c == oli.Non_Payroll_Unit__c, true);
        System.assertEquals(controller.clonedOpp.Amount == oli.TotalPrice, true);
	}
    
    @isTest static void PrimaryOpportunityCopyTest() {
        Opportunity opp2 = new Opportunity(Name='test opp2', StageName = 'Test', CloseDate=Date.today());
        insert opp2;
        
        Opportunity opp = new Opportunity(Name='test opp', StageName = 'Test', CloseDate=Date.today(), Primary_Opportunity__c = opp2.Id);
        insert opp;
        
          String[] prodNames = new String[]{'OpptyLineItemTest','Direct Deposit'};
          PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames,'OpptyLineItemTest',null);
          PricebookEntry entry = entries.get(0);
          // create opportunitylineitems
          OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=opp.Id, PricebookEntryId=entry.Id, Status__c='Pending', ServiceDate=Date.today()
                                      ,Quantity=1, TotalPrice=1000, Setup_Fee__c=100, Payroll_Unit__c=2.5,Non_Payroll_Unit__c=1.5);
          insert oli;
         
        AccountMethodsTest.setupTestAcctCtct(1); 

        // reselect the contact
         Contact ctct = [Select AccountId, Account.Id, Account.Name, Dialed__c, FirstName, LastName, Name, Phone, Products__c from Contact where Id=:AccountMethodsTest.testCtcts[0].Id];
        
         OpportunityContactRole oCR = new OpportunityContactRole( ContactId = ctct.id, IsPrimary=true, OpportunityId = opp.Id); 
         insert oCR;   

		Test.setCurrentPageReference(new PageReference('Page.CloneOpportunity')); 
		System.currentPageReference().getParameters().put('id', opp.Id);

		Test.startTest();
		CloneOpportunityController controller = new CloneOpportunityController();
		controller.cloneWithProducts = true;
        controller.updateProductDisplay();
		controller.cloneOpportunity();
		Test.stopTest();

		System.assertEquals(controller.clonedOpp.Id != null, true);
        System.assertEquals(controller.clonedOpp.Primary_Opportunity__c == opp2.Id, true);
	}
	
}