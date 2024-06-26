@isTest
private class CustomLookupAuraServiceTest {
	
	@isTest static void fetchLookUpValuesTest_GiveKeywordAndObjectType_ReceiveRecords() {

		Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
		Account acct = new Account(Name='Test Account0',recordtypeId = acctCorert.getRecordTypeId(),AccountNumber='1234-TEST0123', Employees__c=10,ShippingStreet='123 Any St',ShippingCity='TestCity',ShippingState='NY',ShippingPostalCode='14514');
		insert acct;

		Test.startTest();
		List<SObject> records = CustomLookupAuraService.fetchLookUpValues('Test', 'Account');
		Test.stopTest();

		System.assertEquals(records.size() > 0, true, 'Accounts have been found for the search term');

	}
	
	
}