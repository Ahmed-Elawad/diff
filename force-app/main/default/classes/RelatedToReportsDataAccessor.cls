public with sharing class RelatedToReportsDataAccessor {

	public RelatedToReportsDataAccessor() {}

	public List<RelatedToReports__c> getRelatedReportsFromObjectType(String sObjectName){
		List<RelatedToReports__c> allReports = [
			SELECT Name, ReportID__c, Object__c
			FROM RelatedToReports__c
			WHERE Object__c = :sObjectName
			ORDER BY Name
		];
		return allReports;
	}
}