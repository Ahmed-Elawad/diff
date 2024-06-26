/*
* Controller for workers comp component in community forms
* 
* History
* ----------------------------------------
* 08/20/2021	Ahmed	Elawad		Created
*/ 

public without sharing class CommunityWorkersCompController {
    
    // save the PEO ONboarding checklist and set the submission times for the form sections if the
    // status has been flaged as complete
    @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName){ 
        return CommunityMethods.savePeoOnboardingChecklist(peoOnbChecklist, formName, 'CommunityWorkersCompController'); 
    }
}