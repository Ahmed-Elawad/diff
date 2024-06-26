/* 
 * Methods to help with PicklistDetail__c data. 
 *
 * History
 * -------
   07/17/2018 Dan Carmen         Add additional fields to the queries

 */
public with sharing class PicklistDetailWrapper {
    
    public Map<String,PicklistDetail__c> detailByFldMap = new Map<String,PicklistDetail__c>();
    public String[] fieldNames = new String[]{};
    public String objectName;
    public String recordTypeName;
    public RecordType rt = null;

    public PicklistDetailWrapper(PicklistDetail__c pkDetail) {
        objectName = pkDetail.ObjectName__c;
        recordTypeName = pkDetail.RecordTypeName__c;
        detailByFldMap.put(pkDetail.FieldName__c,pkDetail);
        fieldNames.add(pkDetail.FieldName__c);
    } // PicklistDetailWrapper


    public String getKey() {
        return objectName + recordTypeName;
    }

    public void addDetail(PicklistDetail__c pkDetail) {
        detailByFldMap.put(pkDetail.FieldName__c,pkDetail);
        fieldNames.add(pkDetail.FieldName__c);
    } // addDetail
    
    public void setRecordType(RecordType p_rt) {
        rt = p_rt;
        // make sure the record type id is set on the object.
        for (PicklistDetail__c pkDetail : detailByFldMap.values()) {
            pkDetail.RecordTypeId__c = rt.Id;
        }
    } // setRecordType
    
    public void setError(Boolean isError, String notesToAdd) {
        for (PicklistDetail__c pkDetail : detailByFldMap.values()) {
            pkDetail.Error__c = isError;
            addToProcessNotes(pkDetail, notesToAdd);
            if (isError) {
                pkDetail.NbrPicklistValues__c = 0;
                pkDetail.PicklistData__c = null;
                pkDetail.RecordTypeId__c = null;
                pkDetail.ValuesLastUpdated__c = Datetime.now();
            }
        }
    } // setError

    public void addToAllProcessNotes(String notesToAdd) {
        for (PicklistDetail__c pkDetail : detailByFldMap.values()) {
            addToProcessNotes(pkDetail, notesToAdd);
        }
    } // addToProcessNotes
      

    private static void addToProcessNotes(PicklistDetail__c pkDetail, String notesToAdd) {
        if (String.isNotBlank(notesToAdd)) {
            StringHelper.addNotesToField(pkDetail, 'ProcessNotes__c', PicklistDetailCalloutHelper.PROCESS_NOTES_SIZE, notesToAdd, true);
        }
   } // addToProcessTracker
} // class PicklistDetailWrapper