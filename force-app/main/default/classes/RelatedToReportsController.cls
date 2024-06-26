public with sharing class RelatedToReportsController {

	public static RelatedToReportsDataAccessor da = new RelatedToReportsDataAccessor();

	@AuraEnabled 
	public static List<RelatedToReports__c> allRelatedReports(Id recordId){ 

		try {
			String sObjectName = recordId.getSobjectType().getDescribe().getName();
			List<RelatedToReports__c> allReports = da.getRelatedReportsFromObjectType(sObjectName);
			return allReports;
		} catch(Exception ex){
			system.debug(ex.getMessage());
			throw new AuraHandledException('An error occured while gathering reports.');
		}
	
	}

}