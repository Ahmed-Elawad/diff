@isTest
private class ContactBannerPopoverAuraServiceTest {
	
	@isTest static void getCompactLayoutFieldsTest_receiveMetadataRecords() {
		Test.startTest();
		List<CustomCompactLayoutItem__mdt> compactLayoutItems = ContactBannerPopoverAuraService.getCompactLayoutFields();
		Test.stopTest();

		System.assertEquals(compactLayoutItems.size() > 0, true, 'Compact Layout Items were queried');
	}
	
}