/* 
 History
--------------
06/18/2019 Dan Carmen      Clean up code and increment API 

*/ 
@isTest
private class QuotePrimaryContactAssignerTest {
    static testMethod void testQuotePrimaryContactAssignerMethod(){
    	QuotePrimaryContactAssigner insQuotePrimaryContactAssigner = new QuotePrimaryContactAssigner();
  	}
/*	
	@isTest static void QuotePrimaryContactAssigner_GivePrimaryContactInOpportunityRole_SetPrimaryContactOnQuote() {
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
		QuotePrimaryContactAssigner.setPrimaryContact(newQuotes);
		Test.stopTest();

		System.assertEquals(quote.SBQQ__PrimaryContact__c, ctct1.Id);
		System.assertEquals(quote.SBQQ__PrimaryContact__c, role.ContactId);
	}
	
	@isTest static void QuotePrimaryContactAssigner_GiveMultiplePrimaryContactsInOpportunityRoles_SetPrimaryContactOnMultipleDifferentQuotes() {

		// create the source account
		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
		Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
		insert acct;

		// get the core record type - have to set the record type because of the Sales_Contact__c flag.
		Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

		// create contacts
		Contact ctct1 = new Contact(AccountId=acct.Id,FirstName='First',LastName='LastTest1',Email='firstTest1@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
		Contact ctct2 = new Contact(AccountId=acct.Id,FirstName='Second',LastName='LastTest2',Email='firstTest2@test.com',Sales_Contact__c=true, RecordTypeId=coreRt.getRecordTypeId());
		List<Contact> contacts = new List<Contact>{ctct1, ctct2};
		insert contacts;

		// create opportunities
		Opportunity opp1 = new Opportunity(Name='Test Opp1',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test',AccountId=acct.Id);
		Opportunity opp2 = new Opportunity(Name='Test Opp2',CloseDate=Date.today().addDays(7),StageName='Sold',Employees_Paid_Per_Payroll__c=10,Local_Competitors__c='Test2',AccountId=acct.Id);
		insert new List<Opportunity>{opp1, opp2};

		OpportunityContactRole role = new OpportunityContactRole(OpportunityId = opp1.Id, ContactId = ctct1.Id, IsPrimary = true);
		OpportunityContactRole role2 = new OpportunityContactRole(OpportunityId = opp2.Id, ContactId = ctct2.Id, IsPrimary = true);
		insert new List<OpportunityContactRole>{role, role2};

		SBQQ__Quote__c quote1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.Id, SBQQ__Status__c = 'Draft');
		SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp2.Id, SBQQ__Status__c = 'Draft');
		List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>{quote1, quote2};

		Test.startTest();
		QuotePrimaryContactAssigner.setPrimaryContact(newQuotes);
		Test.stopTest();

		System.assertEquals(quote1.SBQQ__PrimaryContact__c, ctct1.Id);
		System.assertEquals(quote2.SBQQ__PrimaryContact__c, ctct2.Id);
	}
*/	
}