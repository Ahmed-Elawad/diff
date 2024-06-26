/* 
  Creates HR Matters Tracking objects when a case is created/edited and meets certain criteria
   
  History
  -------
  03/05/2020 Michael Karcz    Created

 */

public with sharing class HRMattersTrackingHelper implements TriggerInterface2 {
    
    
    public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
    
    // see if there are any actions that need to take place at the end of the trigger.
    public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
    
    public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
        System.debug('MAK - Inside HRMattersTrackingHelper, first line');
        if(isAfter) {
            //if working with cases, convert them all to cases
            if(recs[0].getSObjectType() == Case.sObjectType) {
                Case[] caseRecs = (Case[])recs;
                Map<Id, Case> oldCases = (oldMap == null) ? new Map<Id, Case>() : (Map<Id, Case>)oldMap;
                Map<Id, Case> casesToProcess = new Map<Id, Case>();
                
                Id rtId = RecordTypeHelper.getRecordType('HRS HRBP Case Record Type', ObjectHelper.OBJECT_CASE).getRecordTypeId();
                
                for(Case cse : caseRecs) {
                    //if there's no parent, the record type is HRS HRBP Case Record Type, and if the Category field is not blank...
                    if((cse.ParentId == null) && (cse.RecordTypeId == rtId) && (!String.isBlank(cse.Category__c))) {
                        //if the case is brand new
                        if(oldCases.get(cse.Id) == null) {
                            casesToProcess.put(cse.Id, cse);
                        }
                        else {
                            Case oldCase = oldCases.get(cse.Id);
                            //if the record type field or the category field changed
                            if(oldCase.RecordTypeId != rtId || String.isBlank(oldCase.Category__c)) {
                                casesToProcess.put(cse.Id, cse);
                            }
                        }
                    } // if((cse.ParentId.isBlank
                } // for(Case cse : caseRecs)
                processCases(casesToProcess);
            } // if(recs[0].getSObjectType()
        } // if(isAfter)
    } // checkAllBeforeTrigger
    
    public void processCases(Map<Id, Case> casesToProcess) {
        HR_Matters_Tracking__c[] HRs = [SELECT Case__c FROM HR_Matters_Tracking__c WHERE Case__c IN :casesToProcess.keySet()];
        for(HR_Matters_Tracking__c HRt : HRs) {
            casesToProcess.remove(HRt.Case__c);
        }
        if(!casesToProcess.isEmpty()) createTrackers(casesToProcess);
    } // processCases
    
    public void createTrackers(Map<Id, Case> casesNeedingTrackers) {
        HR_Matters_Tracking__c[] newHRTrackers = new HR_Matters_Tracking__c[]{};
        for(Case c : casesNeedingTrackers.values()) {
            HR_Matters_Tracking__c newTracker = new HR_Matters_Tracking__c();
            newTracker.Case__c = c.Id;
            newTracker.OwnerId = Label.HR_Matters_Tracking_Owner;
            
            newHRTrackers.add(newTracker);
        }
        DMLHelper.performDML2(newHRTrackers, DmlHelper.DML_INSERT, 'HRMattersTrackingHelper', 'createTrackers', 'Creating new HR Matters Tracking records', true);
    } // createTrackers
    
}