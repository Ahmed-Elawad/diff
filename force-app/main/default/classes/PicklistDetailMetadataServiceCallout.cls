public with sharing class PicklistDetailMetadataServiceCallout {
   
   public static MetadataService.CustomField[] TEST_CUSTOM_FIELDS=null;
   public static MetadataService.RecordType TEST_RECORDTYPE = null;

   public static MetadataService.MetadataPort createService(String sessionId) {
      MetadataService.MetadataPort service = new MetadataService.MetadataPort();
      service.SessionHeader = new MetadataService.SessionHeader_element();
      System.debug(sessionId);
      service.SessionHeader.sessionId = (sessionId != null ? sessionId : UserInfo.getSessionId());

      return service;
   } 
   
   public static SelectOptionWrapper[] getDependentPicklistOptionsCallout(String objectName, String[] objectFields, String recordTypeName, String controllingFieldValue, String sessionId) {

      MetadataService.MetadataPort service = createService(sessionId);
      
      String[] queryFields = new String[]{};
      for (String objectFieldName : objectFields) {
         String fullName = objectName+'.'+objectFieldName;
         queryFields.add(fullName);
      }


      MetadataService.CustomField[] customFields = null;

      MetadataService.RecordType recordType = null;

      String fullRecordTypeName = objectName+'.'+recordTypeName;
      

      if (Test.isRunningTest() && TEST_CUSTOM_FIELDS != null) {
         customFields = TEST_CUSTOM_FIELDS;
         recordType = TEST_RECORDTYPE;
      } else {
         customFields = (MetadataService.CustomField[]) service.readMetadata('CustomField', queryFields).getRecords();
         recordType = (MetadataService.RecordType) service.readMetadata('RecordType', new String[] { fullRecordTypeName }).getRecords()[0];
      }
         
      Map<String,Map<String,MetadataService.PicklistValue>> valueMapByPicklistNameMap = new Map<String,Map<String,MetadataService.PicklistValue>>();
      
      for (MetadataService.CustomField custFld : customFields) {
         Map<String, MetadataService.PicklistValue> valuesMap = new Map<String, MetadataService.PicklistValue>();
         for (MetadataService.PicklistValue pk : custFld.picklist.picklistValues) {
            valuesMap.put( pk.fullName, pk );
         }

         String fieldName = custFld.fullName.substring(custFld.fullName.indexOf('.')+1);
         valueMapByPicklistNameMap.put(fieldName, valuesMap);
      }
      
      SelectOptionWrapper[] wrappers = new SelectOptionWrapper[]{};


      System.debug(recordType.picklistValues);
      if(recordType != null && recordType.picklistValues != null){
         for ( MetadataService.RecordTypePicklistValue rpk : recordType.picklistValues ) {
            Map<String, MetadataService.PicklistValue> valuesMap = valueMapByPicklistNameMap.get(rpk.picklist);
            if (valuesMap != null) {
               System.debug('found picklist field values for '+rpk.picklist+'!');
               for ( MetadataService.PicklistValue pk : rpk.values ) {

                  String pklistValueDecoded = EncodingUtil.urlDecode(pk.fullName,'UTF-8');
                  MetadataService.PicklistValue picklistValue = valuesMap.get( pklistValueDecoded );

                  if ( picklistValue != null 
                         && ( picklistValue.controllingFieldValues == null 
                              || String.isBlank(controllingFieldValue) 
                              || (String.isNotBlank(controllingFieldValue) && new Set<String>( picklistValue.controllingFieldValues ).contains( controllingFieldValue ))
                     )) {
                     System.debug('found valid '+rpk.picklist+' value:'+pk.fullName+' pklistValueDecoded:'+pklistValueDecoded);
                     wrappers.add(new SelectOptionWrapper(rpk.picklist,pklistValueDecoded,pklistValueDecoded));
                  }

               }
            }
         }
      }

      return wrappers;
   } 

}