/* 
 *   
 * History
 * -------
 * 08/20/2017 Cindy Freeman		created
   12/21/2022 Dan Carmen        Changed TriggerInterface

*/

trigger ClientReferencesAfter on Client_Reference__c (after insert, after update) {
    TriggerMethods.handleTrigger('ClientReferencesAfter', Trigger.new, Trigger.oldMap, null);
} // ClientReferencesAfter