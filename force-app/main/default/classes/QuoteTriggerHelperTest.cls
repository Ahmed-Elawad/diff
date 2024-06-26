/* 
   
  History
  -------
  09/11/2019 Dan Carmen       Increment API version
  10/03/2019 Brandon Vidro	  Added setQuoteNumberTest
      
 */
@isTest
private class QuoteTriggerHelperTest {
    static testMethod void testQuoteTriggerHelperMethod(){
    	QuoteTriggerHelper insQuoteTriggerHelper = new QuoteTriggerHelper();
  	}
/*	
	@isTest static void QuotePrimaryContactAssigner_GivePrimaryContactInOpportunityRoleAndInsertQuote_SetPrimaryContactOnQuote() {
		// create the source account
		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
		Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
		insert acct;

		// get the core record type - have to set the record type because of the Sales_Contact__c flag.
		Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

		// create contacts
		Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
		insert ctct1;

		// create opportunities
		Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id);
		insert opp1;

		OpportunityContactRole role = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = ctct1.Id, IsPrimary = true);
		insert role;

		SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id, SBQQ__Status__c = 'Draft');
		List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>{quote};

		Test.startTest();
			insert newQuotes;
		Test.stopTest();

		System.debug(quote);
		System.debug(newQuotes[0]);
		quote = [SELECT SBQQ__PrimaryContact__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
		System.assertEquals(quote.SBQQ__PrimaryContact__c, ctct1.Id);
		System.assertEquals(quote.SBQQ__PrimaryContact__c, role.ContactId);
	}
    
    @isTest static void setQuoteNumberTest() {
		// create the source account
		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
		Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
		insert acct;

		// create opportunities
		Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id);
        Opportunity opp2 = new Opportunity(Name='Test Opp2',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id);
		insert opp1;
        insert opp2;
        
		// create quotes
		SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id, SBQQ__Status__c = 'Draft');
		SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp2.Id, SBQQ__Status__c = 'Draft');
		List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>{quote, quote2};

		Test.startTest();
			insert newQuotes;
		Test.stopTest();

		quote = [SELECT Id, SBQQ__Opportunity2__r.Id, Quote_Number__c from SBQQ__Quote__c where SBQQ__Opportunity2__r.Id = :opp1.Id];
        quote2 = [SELECT Id, SBQQ__Opportunity2__r.Id, Quote_Number__c from SBQQ__Quote__c where SBQQ__Opportunity2__r.Id = :opp2.Id];

        System.assertEquals(quote.Quote_Number__c, 1);
        System.assertEquals(quote2.Quote_Number__c, 1);
	}
*/
}