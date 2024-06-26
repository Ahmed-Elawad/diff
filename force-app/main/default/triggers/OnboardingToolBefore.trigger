/*
* Before Trigger for Onboarding Tool Records
* 
* 11/30/2020	Matt Fritschi	Created
  09/01/2023    Dan Carmen      Add call to OnboardingToolHelper

*/

trigger OnboardingToolBefore on Onboarding_Tool__c (before insert, before update) {
    if (OnboardingToolHelper.SKIP_TRIGGERS) {
        return;
    }
    
    OnboardingToolHelper.checkAllBefore(Trigger.new, Trigger.oldMap);
    
    List<Onboarding_Tool__c> checkIfParent = new List<Onboarding_Tool__c>();
    Onboarding_Tool__c[] checkForAccts = new Onboarding_Tool__c[]{};
    Id[] oppIds = new Id[]{};
        
    for (Onboarding_Tool__c newOT : Trigger.new) {
        
        Onboarding_Tool__c oldOT = (Trigger.isUpdate ? Trigger.oldMap.get(newOT.id) : null);
        if(newOT != null) {
            if (newOT.AccountId__c == null && newOT.Opportunity_Id__c != null) {
                checkForAccts.add(newOT);
                oppIds.add(newOT.Opportunity_Id__c);
            }
            if(oldOT == null) {
                if(newOT.PreAssignedClientNum__c != 'No') {
                    newOT.PreAssignedClientNum__c = 'No';
                }
                System.debug(' OnboardingToolBefore newOT.Multi_ID__c=' + newOT.Multi_ID__c);
                
                //If this is a Multi Id OT record, see if its Oppty has already been split.
                if(newOT.Multi_ID__c) {
                    checkIfParent.add(newOT);
                }
            }
        }
        
    } // for newOT
    
    if(!checkIfParent.isEmpty()) {
        OnboardingToolHelper.checkIfAlreadySplit(checkIfParent);
    }
    
    if (!checkForAccts.isEmpty()) {
        
    }
} // trigger OnboardingToolBefore