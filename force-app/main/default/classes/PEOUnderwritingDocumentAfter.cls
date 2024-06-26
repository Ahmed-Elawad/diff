/**
* History
* -----------------------
* 7/26/2021 Ahmed Elawad        Created & added logic to share doc with the sales rep on creation
* 08/09/2021 Jake Hinds         Removing Doc shares
* 11/01/2021	Matt Fritschi	Calls checkIfChecklistCompleteFuture on update to see if the form has been completed.
*/

public without sharing class PEOUnderwritingDocumentAfter implements TriggerInterfaceC {
    
    public static User runningUser = userHelper.getRunningUser();
    
    public static void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        // handle record insertions and creations to add access for the salesrep, portaluser, nsc, or analyst once the record is created
        System.debug('PEOUnderwritingDocumentAfter isAfter='+isAfter+' Trigger.isUpdate='+Trigger.isUpdate);
        if (isAfter && Trigger.isUpdate) {
            afterUpdateHandler(recs, oldMap);
        }
    }
    
    public static void afterUpdateHandler(SObject[] recs,Map<Id,SObject> oldMap){ 
        System.debug('PEOUnderwritingDocumentAfter entered afterUpdateHandler');
        Set<Id> checklistIds = new Set<Id>();
        
        for(SObject rec : recs) {
			PEO_Onboarding_Document__c newDoc = (PEO_Onboarding_Document__c) rec;
            
            System.debug('MGF PEOUnderwritingDocument newDoc.PEO_Onboarding_Checklist__c='+newDoc.PEO_Onboarding_Checklist__c);
            if(newDoc.PEO_Onboarding_Checklist__c != null && !checklistIds.contains(newDoc.PEO_Onboarding_Checklist__c)) {
                checklistIds.add(newDoc.PEO_Onboarding_Checklist__c);
            }
        }
        
        System.debug('MGF PEOUnderwritingDocument System.isFuture()='+System.isFuture()+' checklistIds.IsEmpty()='+checklistIds.IsEmpty());
        if(!System.isFuture() && !checklistIds.IsEmpty()) {
            CommunityMethods.checkIfChecklistCompleteFuture(checklistIds, 'PEOUnderwritingDocument After Update');
        }
        else if(System.isFuture() && !checklistIds.IsEmpty()) {
            CommunityMethods.checkIfChecklistComplete(checklistIds, 'PEOUnderwritingDocument After Update');
        }
        
    }
}