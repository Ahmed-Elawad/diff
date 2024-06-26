/* 
* Controller for the PEO Edge CommunityAccountEditForm component
*
* History
* -------
* 08/19/2021    Ahmed Elawad   Created
*/

public without sharing class CommunityAccountEditFormController {
    
    // Saves the PEO Checklist record
    @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName){ 
        return CommunityMethods.savePeoOnboardingChecklist(peoOnbChecklist, formName, 'CommunityAccountEditFormController');
    }
    
    // Save the medical questionnaire record
    @AuraEnabled
    public static Boolean saveMedicalQuestionnaire(PEO_Onboarding_Medical_Questionnaire__c rec, String formName) {
        return CommunityMethods.saveMedicalQuestionnaire(rec, formName, 'CommunityAccountEditFormController');
    }
    
    // save miltuple PEO_Onboarding_Medical_Questionnaire__c records.
    @AuraEnabled
    public static Boolean saveMedicalQuestionnaires(List<PEO_Onboarding_Medical_Questionnaire__c> recs, String formName) {
        return CommunityMethods.saveMedicalQuestionnaires(recs, formName, 'CommunityAccountEditFormController');
    }
    
    // Get the PEO onboarding checklist for the passed in Account ID
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,PEO_Onboarding_Checklist__c oldChecklist, String formName) {
        return CommunityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'CommunityAccountEditFormController');
    }
    
    // Get the Medical Questionnaire for the passed in PEO Underwriting Checklist ID
    @AuraEnabled
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaire(Id peoUnderwritingChecklistId, String formName) {
        return CommunityMethods.getMedicalQuestionnaireForm(peoUnderwritingChecklistId, formName, 'CommunityAccountEditFormController');
    }
    
    // Save the account record
    // Update the CS location data if the updated account is a child in a multi ID
    // Returns the account that was updated without re-querying
     @AuraEnabled  
    public static Account saveThisAccount(Account acct, String formName){ 
        System.debug('Updating acct...');
        // handle the type conversion for the recieved acct record
        Integer numofEmps = acct.NumberOfEmployees;
        acct.NumberOfEmployees = numofEmps;
        try {
            update acct;
            String[] fldList = new String[]{};
                Schema.FieldSet oppFldSet = Schema.SObjectType.Account.fieldSets.PEO_Edge_Form_Fields;
            for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
                String fldName = fsm.getFieldPath();
                fldList.add(fldName);
            }
            String queryString = 'SELECT '
                + String.join(fldList,',') 
                +' FROM Account WHERE Id = \''+ acct.Id + '\' LIMIT 1';
            return Database.query(queryString);
        } catch(Exception e) {
            communityMethods.logCommunityError(e, 'saveThisAccount', 'CommunityAccountEditFormController',formName, new List<Account>{acct});
            return null;
        }
    }
    
    // retrieves the picklist values from the state_with_most_employees__c field on the PEO_Onboarding_Checklist__c OBJ
    // Returns the list as a map: {NY: New York, etc...}
    @AuraEnabled
    public static Map<String, String> getSelectOptions(String formName) {
        try {
            Map<String, String> options = new Map<String, String>();
            Schema.sObjectType objType = PEO_Onboarding_Checklist__c.getSObjectType();
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
            List<Schema.PicklistEntry> pList = fieldMap.get('state_with_most_employees__c').getDescribe().getPickListValues();
            for (Schema.PicklistEntry p: pList) {
                options.put(p.getValue(), p.getLabel());
            }
            return options;
        } catch(Exception e) {
            communityMethods.logCommunityError(e, 'getOptions', 'CommunityAccountEditFormController', formName, null);
        }
        return null;
    }
    
    @AuraEnabled
    public static Boolean checkIfBenchmarkValuesExist(Account account, PEO_Onboarding_Checklist__c checklist) {
        return communityMethods.checkIfBenchmarkValuesExist(account, checklist);
    }
    
    @AuraEnabled
    public static Map<String, Decimal> retrieveBenchmarkValues(PEO_Onboarding_Checklist__c checklist) {
        return communityMethods.retrieveBenchmarkValues(checklist);
    }
    
    @AuraEnabled
    public static Boolean checkBLSPermissions(Id userId, String benchMarkPermission){
        return communityMethods.checkBLSPermissions(userId, benchMarkPermission);
    }
    
}