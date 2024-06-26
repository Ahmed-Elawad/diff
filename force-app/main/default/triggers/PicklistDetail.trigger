trigger PicklistDetail on PicklistDetail__c (after insert, after update) {
   if (!PicklistHelper.SKIP_TRIGGER) {
      PicklistHelper.processAllAfterTrigger(Trigger.new, Trigger.oldMap);
   }
} // trigger PicklistDetail