/*
* After Trigger for Onboarding Tool Records
* 
* 11/30/2020	Matt Fritschi	Created
  07/13/2022	Chris Santoro	Updated trigger to call createCTTCase() for Mandate sales to create a Case/Reference for CTT. 
  08/01/2022    Dan Carmen      Clean up code
  09/01/2023    Dan Carmen      Add call to OnboardingToolHelper
 
   
*/

trigger OnboardingToolAfter on Onboarding_Tool__c (after insert, after update) {
    System.debug('OnboardingToolAfter OnboardingToolHelper.SKIP_TRIGGERS='+OnboardingToolHelper.SKIP_TRIGGERS);
    if (OnboardingToolHelper.SKIP_TRIGGERS) {
        return;
    }
    OnboardingToolHelper.checkAllAfter(Trigger.new, Trigger.oldMap);

    List<Id> parentOnboardingIds = new List<Id>();
    List<Id> newlyUpdatedChildren = new List<Id>();
    List<Onboarding_Tool__c> updateChildren = new List<Onboarding_Tool__c>();
    
    List<Opportunity> opptyList = new List<Opportunity>();
    List<Id> opportunitiesToCheck = new List<Id>();
    Map<Id, Onboarding_Tool__c> onboardingToolRecsToUpdate = new Map<Id, Onboarding_Tool__c>();
   
    Map<Id, Case> caseCTTToInsert = new Map<Id, Case>();
    List<Onboarding_Tool__c> createReferenceCTT = new List<Onboarding_Tool__c>();
    Onboarding_Tool__c[] mandateOnboards = new Onboarding_Tool__c[]{};
    Id[] referenceCTTOppIds = new Id[]{};
            
    for (Onboarding_Tool__c newOT : Trigger.new) {
        
        Onboarding_Tool__c oldOT = (Trigger.isUpdate ? Trigger.oldMap.get(newOT.id) : null);
        
        if(newOT != null) {
            if(oldOT == null) {
				//If a parent is inserted after the child, update n to have the parents data.
                if(newOT.Is_Parent__c) {
                    System.debug('OnboardingToolAfter newOT='+newOT.Name+' Is_Parent__c');
                    updateChildren.add(newOT);
                }
                
            }
            //System.debug('OnboardingToolAfter oldOT = ' + oldOT);
            //If this is an NCP that is not a child that was submitted for the first time, create a Reference CTT record
            // If it's modified and it's already submitted, check to make sure one exists?
            //if (newOT.NCP_Submitted__c && !newOT.Is_Child__c && (oldOT == null || !oldOT.NCP_Submitted__c))  {
            if (newOT.NCP_Submitted__c && !newOT.Is_Child__c)  {
               Boolean isChanged = (oldOT == null || (oldOT != null && !oldOT.NCP_Submitted__c));
               // only do the mandate check if the submitted flag was just set.
               if (isChanged && newOT.Mandate_Sale__c) {
                  mandateOnboards.add(newOT);
               }
               createReferenceCTT.add(newOT);
               if (newOT.Opportunity_Id__c != null) {
                  referenceCTTOppIds.add(newOT.Opportunity_Id__c);
               }
               System.debug('OnboardingToolAfter creating Reference CTT object');
            }

            if(oldOT != null) {
                //If this is a child NCP that was submitted for the first time, check if all children were submitted
                if(newOT.NCP_Submitted__c && newOT.NCP_Submitted__c != oldOT.NCP_Submitted__c && newOT.Is_Child__c && newOT.Parent_Onboarding_Record__c != null)
                {
                    parentOnboardingIds.add(newOT.Parent_Onboarding_Record__c);
                    newlyUpdatedChildren.add(newOT.Id);
                }
                //If this is a Parent NCP that was submitted for the first time, update the children with the parent's data
                if(newOT.NCP_Submitted__c && newOT.NCP_Submitted__c != oldOT.NCP_Submitted__c && newOT.Is_Parent__c) {
                    System.debug('OnboardingToolAfter newOT='+newOT.Name+' Is_Parent__c and NCP_Submitted__c');
                    updateChildren.add(newOT);
                }
            } // if(oldOT != null
            
        }
    } // for newOT

    System.debug('OnboardingToolAfter parentOnboardingIds='+parentOnboardingIds.size()+' updateChildren='+updateChildren.size()+' onboardingToolRecsToUpdate='+onboardingToolRecsToUpdate.size()+' createReferenceCTT='+createReferenceCTT.size());
    
    if(!parentOnboardingIds.isEmpty()) {
        OnboardingToolHelper.checkAllSubmitted(parentOnboardingIds, newlyUpdatedChildren, onboardingToolRecsToUpdate);
    }
    
    if(!updateChildren.isEmpty()) {
        OnboardingToolHelper.updateChildrenToHaveParentData(updateChildren, onboardingToolRecsToUpdate);
    }
    
    if(!createReferenceCTT.isEmpty()) {
        OnboardingToolHelper.createCTT(createReferenceCTT, mandateOnboards, referenceCTTOppIds);
    }
    
    if(!onboardingToolRecsToUpdate.isEmpty()) {
        update onboardingToolRecsToUpdate.values();
    }
    
}