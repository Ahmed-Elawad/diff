/* 
 *
 * History
 * -------
 * 05/15/2019   Jermaine Stukes     Created
 * 10/10/2019   Jermaine Stukes     Updated
   11/12/2019   Dan Carmen          Moved code to CadenceUpdate
 */
trigger CarBefore on Cadence_Assignment_Record__c (before insert, before update) {
    CadenceUpdate.checkCarsBefore(Trigger.new, Trigger.oldMap);

} // trigger CarBefore