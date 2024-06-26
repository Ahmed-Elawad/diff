/* 
 * To schedule the batch job
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional fields to the queries
   07/06/2020  Jacob Hinds         Added without sharing per PMD

 */
global without sharing class PicklistDetailScheduledUpdate implements Schedulable {
   
   public static Integer DEFAULT_BATCH=5;

    public static String query = 'SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = \'Task\' OR SObjectType = \'Event\'';

    global void execute(SchedulableContext sc) {
        if(!String.isEmpty(query)) {
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(PicklistDetailUpdateBatch.CLASS_NAME);
        // pull from the custom setting, otherwise use a default value.
        Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : DEFAULT_BATCH);
          PicklistDetailUpdateBatch batchJob = new PicklistDetailUpdateBatch(query);
          database.executebatch(batchJob,batchSize);
        }
    }
} // class PicklistDetailScheduledUpdate