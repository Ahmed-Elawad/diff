public with sharing class ExportEventAuraService {

	@AuraEnabled
	public static Event getEventFields(Id recordId) {
		return [
			SELECT Id,Subject,LastModifiedDate,CreatedDate,Description,Location,DurationInMinutes,StartDateTime
			FROM Event
			WHERE Id =:recordId
			LIMIT 1
		];
	}
}