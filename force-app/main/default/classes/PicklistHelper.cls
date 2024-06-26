/* 
 * Methods to help with picklist manipulation
 *
 * History
 * -------
   10/18/2017 Dan Carmen       Created
   07/17/2018 Dan Carmen       Add additional debugging

 */
public without sharing class PicklistHelper {
   
    public static Boolean SKIP_TRIGGER=false;
    public static String TOKEN_KEY='-Q-';

    public static void processAllAfterTrigger(PicklistDetail__c[] pkDetails, Map<Id,PicklistDetail__c> oldMap) {
        SKIP_TRIGGER = true;

        String[] recordTypeDeveloperNames = new String[]{};
        for (PicklistDetail__c pkDetail : pkDetails) {
            if (pkDetail.Process__c) {
                recordTypeDeveloperNames.add(pkDetail.Developer_Name__c);
            }
        }
        
        System.debug('processAllAfterTrigger recordTypeDeveloperNames='+recordTypeDeveloperNames.size());
        runPicklistDetailUpdateBatch(recordTypeDeveloperNames);
   } // processAllAfterTrigger

    // run the batch from the trigger
    private static void runPicklistDetailUpdateBatch(String[] recordTypes){

        if(!System.isBatch() && recordTypes.size() > 0){
            String query = 'SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE DeveloperName IN :recordTypesToAnalyze AND (SObjectType = \'Task\' OR SObjectType = \'Event\')';
            Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(PicklistDetailUpdateBatch.CLASS_NAME);
            // pull from the custom setting, otherwise use a default value.
            Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 5);
            PicklistDetailUpdateBatch batchJob = new PicklistDetailUpdateBatch(query, recordTypes);
            database.executebatch(batchJob,batchSize);
        }
    }

    // create a mapping based on all of the field names passed in.
    // if a detail record doesn't already exist, then create it.
    public static Map<String, PicklistDetail__c> getFieldsToPicklistDetailRecords(RecordType rt, String[] fieldNames, PicklistDetail__c[] pkDetails){

        Map<String, PicklistDetail__c> fieldToPicklistDetail = new Map<String, PicklistDetail__c>();

        for(String field : fieldNames){
            
            if(pkDetails != null){
                for(PicklistDetail__c pkDetail : pkDetails){

                    if(pkDetail.Developer_Name__c == rt.DeveloperName && field == pkDetail.FieldName__c){
                        fieldToPicklistDetail.put(field, pkDetail);
                        break;
                    }
                }
            }
            
            if(!fieldToPicklistDetail.containsKey(field)){
                fieldToPicklistDetail.put(field, createPicklistDetailRecord(rt, field));
            }
        }

        return fieldToPicklistDetail;
    } // getFieldsToPicklistDetailRecords

    // create a new PicklistDetail__c instance
    public static PicklistDetail__c createPicklistDetailRecord(RecordType rt, String field){
        return new PicklistDetail__c(
                Name = rt.SobjectType+'-'+rt.Name, 
                Developer_Name__c = rt.DeveloperName, 
                FieldName__c = field, 
                RecordTypeName__c = rt.Name,
                ObjectName__c = rt.SobjectType
               ,RecordTypeId__c=rt.Id
        );

    } // createPicklistDetailRecord

  
} // class PicklistHelper