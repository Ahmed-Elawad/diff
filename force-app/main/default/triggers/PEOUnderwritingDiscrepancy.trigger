/**
 * History
 * ----------------
 * 4/13/2021    Ahmed Elawad    Created
 * 5/5/2021     Ahmed Elawad    Added insert & update: After
 * 6/1/2021     Ahmed Elawad    Added (Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore
 */

trigger PEOUnderwritingDiscrepancy on PEO_Onboarding_Document_Discrepency__c (before insert, before update, after insert,after update) {
    // if inserting a discrepancy run the document update after the save
    if (Trigger.isInsert && Trigger.isAfter) {
        System.debug('Running insert and after trigger...');
        TriggerMethods.checkBeforeLoop('PEOUnderwritingDiscrepancy', Trigger.new, Trigger.oldMap,  Trigger.IsBefore, Trigger.IsAfter);
    }
                                                                                  
    if (Trigger.isUpdate && Trigger.isAfter) {
        System.debug('Running update and after trigger...');
        TriggerMethods.checkBeforeLoop('PEOUnderwritingDiscrepancy', Trigger.new, Trigger.oldMap,  Trigger.IsBefore, Trigger.IsAfter);
    }
    
    if ((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore) {
        System.debug('Running update and after trigger...');
        TriggerMethods.checkBeforeLoop('PEOUnderwritingDiscrepancy', Trigger.new, Trigger.oldMap,  Trigger.IsBefore, Trigger.IsAfter);
    }
    
}