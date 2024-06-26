/* Trigger on the ZipImport__c object

  History
  -------
  09/05/2023 Dan Carmen        Created
  
 */
trigger ZipImport on ZipImport__c (before insert, before update, after insert, after update) {
   new ZipInsertMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
} // trigger ZipImport