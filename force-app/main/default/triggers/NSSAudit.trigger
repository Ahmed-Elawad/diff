/* 
 *  Trigger for the NSSAudit object.
 
 * History
 * -------
 * 08/15/2014 Dan Carmen     created
   09/18/2014 Dan Carmen     Added logic to set the NSR (contact) field
   03/09/2016 Dan Carmen     Add ability to link to the Commission Month object
 * 
 */
trigger NSSAudit on NSSAudit__c (before insert, before update) {
   
   for (NSSAudit__c nssAudit : Trigger.new) {
      NSSAudit__c oldAudit = (Trigger.isUpdate ? Trigger.oldMap.get(nssAudit.Id) : null);
      if (Trigger.isBefore) {
         NSSAuditHelper.checkTriggerBeforeActions(nssAudit, oldAudit);
      }
   } // for (NSSAudit__c
   
   if (Trigger.isBefore) {
      NSSAuditHelper.processTriggerBefore();
   }
   

} // trigger NSSAudit