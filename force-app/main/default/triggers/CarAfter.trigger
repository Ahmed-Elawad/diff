/* 
 *
 * History
 * -------
 * 05/15/2019   Jermaine Stukes     Created
 * 10/10/2019   Jermaine Stukes     Updated
 */
trigger CarAfter on Cadence_Assignment_Record__c (after insert, after update) {  
    CadenceUpdate.checkCarsAfter(Trigger.new, Trigger.oldMap);
} // trigger CarAfter