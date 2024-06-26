/*
* Controller for workers comp component in community forms
* 
* History
* ----------------------------------------
* 08/20/2021	Ahmed	Elawad		Created
*/ 


public without sharing class CommunityEpliController {
    
    public CommunityEpliController(){
        System.debug('Just for test class');
    }
    
   /* @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName){ 
        return CommunityMethods.savePeoOnboardingChecklist(peoOnbChecklist, formName, 'CommunityEpliController');
    }
    
   //Save Policy Periods for the EPLI
    @AuraEnabled
    public static List<Policy_Period__c> saveEPLIPolicyPeriods(List<Policy_Period__c> newPolPeriods, String formName) {
        List<Policy_Period__c> currentPolicyPeriods = [SELECT Id, Name, PEO_Onboarding_Checklist__c FROM Policy_Period__c WHERE PEO_Onboarding_Checklist__c = :newPolPeriods[0].PEO_Onboarding_Checklist__c];
        List<Policy_Period__c> polPeriodsToDelete = new List<Policy_Period__c>();
        boolean skip = false;
        
        for(Policy_Period__c polPeriod : currentPolicyPeriods){
            skip = false;
            for(Policy_Period__c newPolPeriod : newPolPeriods){
                // System.debug('MGF newPolPeriod = '+newPolPeriod);
                if(polPeriod.Id != null && polPeriod.Id == newPolPeriod.Id){
                    // System.debug('MGF Skipping because match found: polPeriod.Id = '+polPeriod.Id + ' newPolPeriod = '+newPolPeriod);
                    skip = true;
                    break;
                }
            }
            
            if(!skip){
                polPeriodsToDelete.add(polPeriod);
            }
            
        }
        
        try {
            if(!polPeriodsToDelete.isEmpty()) {
                delete polPeriodsToDelete;
            }
            upsert newPolPeriods;
            return newPolPeriods;
         }catch(Exception e) {
            CommunityMethods.logCommunityError(e, 'saveEPLIPolicyPeriods', 'CommunityEpliController', formName, newPolPeriods);
            return null;
        }
    }
    
    //Get Policy Periods for the EPLI
    @AuraEnabled
    public static List<Policy_Period__c> getEPLIPolicyPeriods(Id peoOnboardingChecklistId, String formName) {
        List<Policy_Period__c> polPeriods = new List<Policy_Period__c>([SELECT Id, Name, Policy_Period__c, Insurance_Carrier__c, Premium__c, Limit__c, Deductible_Retention__c, 
                                                                        PEO_Onboarding_Checklist__c FROM Policy_Period__c WHERE PEO_Onboarding_Checklist__c = :peoOnboardingChecklistId]);
        
        if(polPeriods.isEmpty()){
            Policy_Period__c polPeriod = new Policy_Period__c(PEO_Onboarding_Checklist__c = peoOnboardingChecklistId);
             try {
                insert polPeriod;    
                polPeriods.add(polPeriod);
            } catch(Exception e) {
                CommunityMethods.logCommunityError(e, 'saveEPLIPolicyPeriods', 'CommunityEpliController', formName, polPeriod, null);
            }
        }
        return polPeriods;
    }
    */
}