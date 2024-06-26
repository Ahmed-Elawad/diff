/*
 * History
 * ------------------------
 * 7/26/2021 Ahmed Elawad		Created logic to route to PEOUnderwritingDocumentAfter class for inserts  
 * 11/01/2021	Matt Fritschi	Calls TriggerMethods on udpate.
 */

trigger PEOUnderwritingDocument on PEO_Onboarding_Document__c (before insert, before update, after update) {
    
    if (trigger.isUpdate && Trigger.isAfter) {
        System.debug('PEOUnderwritingDocument trigger.isUpdate='+trigger.isUpdate+' Trigger.isAfter='+Trigger.isAfter);
        TriggerMethods.checkBeforeLoop('PEOUnderwritingDocument', Trigger.new, Trigger.oldMap,  Trigger.IsBefore, Trigger.IsAfter);
    }
    
}