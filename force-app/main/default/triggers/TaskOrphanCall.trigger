/** Trigger on the TaskOrphanCall__c object.
 *
 * History
 * -------
   03/31/2017 Dan Carmen        Created.
*/
trigger TaskOrphanCall on TaskOrphanCall__c (after insert, after update) {
   if (!TaskOrphanCallMethods.SKIP_TRIGGER) {
      TaskOrphanCallMethods.handleTrigger(Trigger.new, (Trigger.isUpdate ? Trigger.oldMap : null));
   }
} // trigger TaskOrphanCall