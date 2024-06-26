trigger ExtractionRequestTrigger on Extraction_Request__c (before update,after update) {
  ExtractionRequestTriggerMethods.handleTrigger(Trigger.isBefore, Trigger.isAfter,Trigger.isUpdate,Trigger.newMap, Trigger.oldMap);
}