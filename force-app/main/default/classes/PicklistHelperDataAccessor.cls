/* 
 * Methods to help with PicklistDetail__c queries
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional fields to the queries

 */
public with sharing class PicklistHelperDataAccessor {
	   	
      public static PicklistDetail__c[] getPicklistDetailsFromObjectNameAndRecordType(String objectName, String recordTypeDeveloperName){
         PicklistDetail__c[] pkDetails = [
            SELECT Id, FieldName__c, ObjectName__c, PicklistData__c, RecordTypeName__c, Developer_Name__c
                  ,ProcessNotes__c, Process__c, Error__c, NbrPicklistValues__c, RecordTypeId__c, ValuesLastUpdated__c
            FROM PicklistDetail__c
            WHERE ObjectName__c = :objectName
            AND Developer_Name__c = :recordTypeDeveloperName
        ];

         return pkDetails;
      } // getPicklistDetailsFromObjectNameAndRecordType
   
      public static PicklistDetail__c[] getPicklistDetailsFromRTDeveloperNames(String[] recordTypeDeveloperNames){
         PicklistDetail__c[] pkDetails = [
            SELECT Id, FieldName__c, ObjectName__c, PicklistData__c, RecordTypeName__c, Developer_Name__c
                  ,ProcessNotes__c, Process__c, Error__c, NbrPicklistValues__c, RecordTypeId__c, ValuesLastUpdated__c
            FROM PicklistDetail__c
            WHERE Developer_Name__c IN :recordTypeDeveloperNames
         ];

         return pkDetails;
      } // getPicklistDetailsFromRTDeveloperNames
   
      public static PicklistDetail__c[] upsertPicklistDetails(PicklistDetail__c[] pkDetails){
         // so we don't execute the trigger again.
         PicklistHelper.SKIP_TRIGGER = true;
         DmlHelper.performDML2(pkDetails, DmlHelper.DML_UPSERT, 'PicklistHelperDataAccessor', 'upsertPicklistDetails', 'upsert the pkDetails records', true);
         return pkDetails;
      } // upsertPicklistDetails

} // class PicklistHelperDataAccessor