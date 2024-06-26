/* 
 * Validate that the record type name is valid and populate the id
 *
 * History
 * -------
 * 10/19/2011 Dan Carmen   Created
   10/26/2018 Dan Carmen   Need to look at removing this entirely!
 *
 */
trigger RecordTypeMapping on Record_Type_Mapping__c (before insert, before update) {

   // store object names in a map to prevent duplicates
   Map<String,String> sObjectNames = new Map<String,String>();
   
   for (Record_Type_Mapping__c rec : Trigger.new) {
      // clear out id
      rec.RecordTypeId__c = null;
      if (rec.Object_API_Name__c != null) {
         sObjectNames.put(rec.Object_API_Name__c,rec.Object_API_Name__c);
      }
   } // for
   
   // do nothing if no values passed in
   if (sObjectNames.isEmpty()) {
      return;
   }
   
   SObjectHelper soh = new SObjectHelper();
   Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
   RecordTypeHelper.getRecordTypesMap(sObjectNames.values(),null,byName);

   // populate the record type ids
   for (Record_Type_Mapping__c rec : Trigger.new) {
      if (rec.RecordTypeName__c != null) {
   	     Schema.RecordTypeInfo rt = byName.get(rec.RecordTypeName__c);
   	     if (rt == null) {
   	        rec.RecordTypeName__c.addError('Could not find a valid Record Type for '+rec.RecordTypeName__c);
   	     } else {
   	        Rec.RecordTypeId__c = rt.getRecordTypeId();
   	     }
   	  } // if
      
   } // for

} // trigger RecordTypeMapping