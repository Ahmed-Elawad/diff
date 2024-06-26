/*
* Controller for workers comp component in community forms
* 
* History
* ----------------------------------------
* 08/20/2021	Ahmed	Elawad		Created
*/ 

public without sharing class Community401kController {

    @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName){ 
        return CommunityMethods.savePeoOnboardingChecklist(peoOnbChecklist, formName, 'Community401kController');
    }
}