/* 
 * Test Methods for the PicklistHelper class
 *
 * History
 * -------
   02/26/2018 Dan Carmen       Created

 */
@isTest
private class PicklistHelperTest {
   
    /**
     * Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
     **/
   private class WebServiceMockImpl implements WebServiceMock 
   {
      public void doInvoke(
         Object stub, Object request, Map<String, Object> response,
         String endpoint, String soapAction, String requestName,
         String responseNS, String responseName, String responseType) 
      {
         if(request instanceof MetadataService.readMetadata_element) {
             response.put('response_x', new MetadataService.readCustomFieldResponse_element());
         }

         return;
      }
   }    
      
   @IsTest
   private static void coverGeneratedCodeCRUDOperations()
   {  
      // Null Web Service mock implementation
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        // Only required to workaround a current code coverage bug in the platform
        MetadataService metaDataService = new MetadataService();
        // Invoke operations     
        Test.startTest();    
        MetadataService.MetadataPort metaDataPort = PicklistDetailMetadataServiceCallout.createService(null);
        Test.stopTest();
   }
   
   public static MetadataService.CustomField[] md_customFields = null;
   public static MetadataService.RecordType md_recordType = null;
   
   public static void setupData() {
      //  https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/customfield.htm
      // from service.readMetadata
      md_customFields = new MetadataService.CustomField[]{};
      MetadataService.CustomField custFld = new MetadataService.CustomField();
      custFld.fullName = ObjectHelper.OBJECT_TASK+'.Status';
      
      MetadataService.PicklistValue pkValue1 = new MetadataService.PicklistValue();
      pkValue1.fullName = 'Status1';
      pkValue1.controllingFieldValues = null;
      
      MetadataService.PicklistValue pkValue2 = new MetadataService.PicklistValue();
      pkValue2.fullName = 'Status2';
      pkValue2.controllingFieldValues = null;
      
      MetadataService.PicklistValue pkValue3 = new MetadataService.PicklistValue();
      pkValue3.fullName = 'Status3';
      pkValue3.controllingFieldValues = null;
      
      MetadataService.PicklistValue pkValue4 = new MetadataService.PicklistValue();
      pkValue4.fullName = 'Status4';
      pkValue4.controllingFieldValues = null;
      
      custFld.picklist = new MetadataService.Picklist();
      custFld.picklist.picklistValues = new MetadataService.PicklistValue[]{pkValue1,pkValue2,pkValue3,pkValue4};
      md_customFields.add(custFld);
      
      
      // from service.readMetadata
      md_recordType = new MetadataService.RecordType();
      md_recordType.fullName = ObjectHelper.OBJECT_TASK+'.'+AccountHelper.CORE_TASK;
      md_recordType.label = AccountHelper.CORE_TASK;
      md_recordType.picklistValues = new MetadataService.RecordTypePicklistValue[]{};
      
      MetadataService.RecordTypePicklistValue rtPicklistValue = new MetadataService.RecordTypePicklistValue();
      rtPicklistValue.picklist = 'Status';
      rtPicklistValue.values = new MetadataService.PicklistValue[]{pkValue1,pkValue2,pkValue3};
      md_recordType.picklistValues.add(rtPicklistValue);
      
      

   } // setupData
   
   static testMethod void testGetPicklistValues() {
      // we're not testing the trigger here, so we'll skip it.
      PicklistHelper.SKIP_TRIGGER = true;
      
      Map<String, Schema.RecordTypeInfo> taskRtMap = Task.getSobjectType().getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfo = taskRtMap.get(AccountHelper.CORE_TASK);
      
      String[] statusOptions = new String[]{'Status1','Status2','Status3','Status4'};
      String statusOptionsStr = PicklistDetailCalloutHelper.concatOptions(statusOptions);
      String[] typeOptions = new String[]{'Type1','Type2','Type3','Type4'};
      String typeOptionsStr = PicklistDetailCalloutHelper.concatOptions(typeOptions);
      
      RecordType rt = RecordTypeDataAccessor.getRecordTypeById(rtInfo.getRecordTypeId());

      PicklistDetail__c pkDetail1 = new PicklistDetail__c(Name='Test1', FieldName__c='Status', ObjectName__c=ObjectHelper.OBJECT_TASK
                                          ,RecordTypeName__c=rtInfo.getName(), RecordTypeId__c=rtInfo.getRecordTypeId()
                                          ,PicklistData__c=statusOptionsStr, Developer_Name__c=rt.DeveloperName);
      PicklistDetail__c pkDetail2 = new PicklistDetail__c(Name='Test2', FieldName__c='Type', ObjectName__c=ObjectHelper.OBJECT_TASK
                                          ,RecordTypeName__c=rtInfo.getName(), RecordTypeId__c=rtInfo.getRecordTypeId()
                                          ,PicklistData__c=typeOptionsStr, Developer_Name__c=rt.DeveloperName);
      PicklistDetail__c[] pkDetails = new PicklistDetail__c[]{pkDetail1,pkDetail2};
      insert pkDetails;
      

      PicklistDetailCalloutHelper.TASK_PICKLIST_FIELD_NAMES = 'Status,Type';
      SelectOptionWrapper[] optionWrappers = CreateActivityPicklistHelper.getPicklistValues(rt);
      SelectOptionWrapper[] statusWrappers = new SelectOptionWrapper[]{};
      SelectOptionWrapper[] typeWrappers = new SelectOptionWrapper[]{};
      
      for (SelectOptionWrapper soWrapper : optionWrappers) {
         if (soWrapper.picklistName == 'Status') {
            statusWrappers.add(soWrapper);
         } else if (soWrapper.picklistName == 'Type') {
            typeWrappers.add(soWrapper);
         }
      }
      
      System.assertEquals(statusOptions.size(), statusWrappers.size());
      System.assertEquals(typeOptions.size(), typeWrappers.size());

   } // testGetPicklistValues

   static testMethod void testPicklistDetailTrigger() {
      setupData();
      PicklistDetailMetadataServiceCallout.TEST_CUSTOM_FIELDS = md_customFields;
      PicklistDetailMetadataServiceCallout.TEST_RECORDTYPE = md_recordType;

      Map<String, Schema.RecordTypeInfo> taskRtMap = Task.getSobjectType().getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfo = taskRtMap.get(AccountHelper.CORE_TASK);
      RecordType rt = RecordTypeDataAccessor.getRecordTypeById(rtInfo.getRecordTypeId());

      PicklistHelper.SKIP_TRIGGER = false;
      PicklistDetail__c pkDetail1 = new PicklistDetail__c(Name='Test1', FieldName__c='Status', ObjectName__c=ObjectHelper.OBJECT_TASK
                                          ,RecordTypeName__c=rtInfo.getName(), RecordTypeId__c=null
                                          ,PicklistData__c=null, Process__c=true, Developer_Name__c=rt.DeveloperName);
      Test.startTest();
      insert pkDetail1;
      Test.stopTest();
      
      pkDetail1 = [Select Id, Name
                         ,Error__c
                         ,FieldName__c
                         ,NbrPicklistValues__c
                         ,ObjectName__c
                         ,PicklistData__c
                         ,Process__c
                         ,RecordTypeId__c
                         ,RecordTypeName__c
                    from PicklistDetail__c
                    Where Id=:pkDetail1.Id];

      System.assertEquals(rtInfo.getRecordTypeId(), pkDetail1.RecordTypeId__c);
      System.assertEquals(3,pkDetail1.NbrPicklistValues__c);
      
   } 
}