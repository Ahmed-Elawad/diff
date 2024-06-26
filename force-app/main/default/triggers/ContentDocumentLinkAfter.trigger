/* 
 *  After trigger for ContentDocumentLink.
 *   
 * History
 * -------
 * 06/16/2016 Justin Stouffer Created
   08/10/2020 Dan Carmen      Added in before insert and delete actions 
 
 */

trigger ContentDocumentLinkAfter on ContentDocumentLink (before insert, after insert, before delete, after delete) {
   // for a delete trigger, pass in the old records.
   ContentDocumentUtilities.handleTriggerActions((Trigger.isDelete ? Trigger.old :Trigger.new), Trigger.oldMap);
} // trigger ContentDocumentLinkAfter