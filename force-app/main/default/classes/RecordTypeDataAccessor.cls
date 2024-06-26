/* 
 * Methods to help with PicklistDetail__c queries
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional comments

 */
public with sharing class RecordTypeDataAccessor {

	public static RecordType[] getRecordTypesByNames (Set<String> names) {
		return [Select Id, Name, DeveloperName FROM RecordType where Name in :names];
	}

	public static RecordType getRecordTypeById(Id recordTypeId){
		return [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE Id = :recordTypeId LIMIT 1];
	}
} // class RecordTypeDataAccessor