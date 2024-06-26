/* 
 * Test methods for the RecordTypeMapping trigger.
 *
 * History
 * -------
 * 10/19/2011 Dan Carmen   Created
   10/26/2018 Dan Carmen   Need to look at removing this entirely!

 */
@isTest
private class RecordTypeMappingTest {

   static testMethod void testData() {
   	  // test no object or record type name
      Record_Type_Mapping__c rtm = new Record_Type_Mapping__c(RecordTypeId__c='BadId');
      insert rtm;
      
      rtm = [select id, name, Object_API_Name__c, RecordTypeName__c, RecordTypeId__c from Record_Type_Mapping__c where Id = :rtm.Id];
      System.assertEquals(null,rtm.RecordTypeId__c);
      
      // object name but no record type name
      rtm = new Record_Type_Mapping__c(Object_API_Name__c='Account');
      insert rtm;
      rtm = [select id, name, Object_API_Name__c, RecordTypeName__c, RecordTypeId__c from Record_Type_Mapping__c where Id = :rtm.Id];
      System.assertEquals(null,rtm.RecordTypeId__c);
      
      // object name and bad record type name
      rtm = new Record_Type_Mapping__c(Object_API_Name__c='Account', RecordTypeName__c='ThisIsABadRecordTypeName');
      try {
         insert rtm;
         System.assertEquals('Should not get here','Do not go here');
      } catch (Exception e) {
      	 // should get here.
      	 System.assertEquals(1,1);
      }
      // insert should fail
      System.assertEquals(null,rtm.Id);
      
      // object name and good record type name
      // get all valid record types and pick one
      List<Schema.RecordTypeInfo> rts = RecordTypeHelper.getRecordTypes('Account');
      Schema.RecordTypeInfo rt = rts.get(0);
      rtm = new Record_Type_Mapping__c(Object_API_Name__c='Account', RecordTypeName__c=rt.getName());
      insert rtm;
      rtm = [select id, name, Object_API_Name__c, RecordTypeName__c, RecordTypeId__c from Record_Type_Mapping__c where Id = :rtm.Id];
      System.assertEquals(rt.getRecordTypeId(),rtm.RecordTypeId__c);
      
   } // testData
   
} // class RecordTypeMappingTest