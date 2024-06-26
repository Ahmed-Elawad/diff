public with sharing class ContactBannerPopoverAuraService {
	@AuraEnabled
	public static List<CustomCompactLayoutItem__mdt> getCompactLayoutFields() {
		List<CustomCompactLayoutItem__mdt> compactLayoutFields = [
			SELECT Label, DeveloperName__c, Order__c, Type__c, LookupIdField__c
			FROM CustomCompactLayoutItem__mdt
			WHERE Active__c = true
			AND ObjectName__c = 'Contact'
			ORDER BY Order__c ASC
		];

		return compactLayoutFields;
	}
}