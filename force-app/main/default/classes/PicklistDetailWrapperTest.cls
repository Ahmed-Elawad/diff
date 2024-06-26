@isTest
private class PicklistDetailWrapperTest {
    
    private static PicklistDetail__c createPicklistDetail(RecordType rt, String name, String fieldName, String objectName){
        return new PicklistDetail__c(
            Name=name, 
            FieldName__c=fieldName,
            ObjectName__c=objectName,
            RecordTypeName__c=rt.Name, 
            RecordTypeId__c=rt.Id,
            PicklistData__c='', 
            Developer_Name__c=rt.DeveloperName
        );
    }

    @isTest static void testPicklistDetailWrapperConstructor() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);

        Test.startTest();
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail);
        Test.stopTest();

        System.assertEquals(wrapper.objectName, ObjectHelper.OBJECT_TASK);
        System.assertEquals(wrapper.recordTypeName, rt.Name);
        System.assertEquals(wrapper.detailByFldMap.get(pkdetail.FieldName__c) != null, true);
        System.assertEquals(wrapper.fieldNames.size() > 0, true);
    }
    
    @isTest static void getKeyTest() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail);

        Test.startTest();
        String key = wrapper.getKey();
        Test.stopTest();

        System.assertEquals(key, ObjectHelper.OBJECT_TASK + rt.Name);
    
    }
    
    @isTest static void addDetailTest() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail1 = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);
        PicklistDetail__c pkDetail2 = createPicklistDetail(rt, 'test2', 'Type', ObjectHelper.OBJECT_TASK);
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail1);

        System.assertEquals(wrapper.detailByFldMap.keyset().size(), 1);

        Test.startTest();
        wrapper.addDetail(pkDetail2);
        Test.stopTest();

        System.assertEquals(wrapper.detailByFldMap.keyset().size(), 2);
    
    }
    
    @isTest static void setRecordTypeTest() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail1 = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail1);

        Test.startTest();
        wrapper.setRecordType(rt);
        Test.stopTest();

        System.assertEquals(wrapper.detailByFldMap.values().get(0).RecordTypeId__c != null, true);
    
    }
    
    @isTest static void setErrorTest() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail1 = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail1);

        Test.startTest();
        wrapper.setError(true, 'Error Notes');
        Test.stopTest();

        System.assertEquals(wrapper.detailByFldMap.values().get(0).Error__c, true);
    
    }
    
    @isTest static void addToAllProcessNotesTest() {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        PicklistDetail__c pkDetail1 = createPicklistDetail(rt, 'test1', 'Status', ObjectHelper.OBJECT_TASK);
        PicklistDetailWrapper wrapper = new PicklistDetailWrapper(pkDetail1);

        Test.startTest();
        wrapper.addToAllProcessNotes('Process Notes');
        Test.stopTest();

        System.assertEquals(wrapper.detailByFldMap.values().get(0).ProcessNotes__c.contains('Process Notes'), true);
    
    }

}