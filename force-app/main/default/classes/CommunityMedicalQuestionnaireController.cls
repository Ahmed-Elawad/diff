/*
 * Class for methods used by the medicalQuestionnaire.cmp and medicalQUestionnaireAccSelect.cmp
 * --------
 * History
 * -------------------------------
 * 08/19/2021	Ahmed Elawad	Created
 * 09/16/2021	Matt Fritshci	Changed logic for verifying parent/child medical questionnaires.
 * 11/30/2021	Jake Hinds		Small changes to aknowledgement check
 * 30/05/2022   Reetesh Pandey  Apex code scan resolution
 * 11/12/2023    Tej Pothuri			Tech Debt Clean up for SPA
 */

public without sharing class CommunityMedicalQuestionnaireController {
    
    public CommunityMedicalQuestionnaireController(){
        System.debug('Just for test class');
    }
    
    // Save a single PEO_Onboarding_Medical_Questionnaire__c record.
    // Updates the timestamp for a completed form if form is saved and submitted
    // Returns true on success false on failure
   /* @AuraEnabled
    public static Boolean saveMedicalQuestionnaire(PEO_Onboarding_Medical_Questionnaire__c rec, String formName) {
        return CommunityMethods.saveMedicalQuestionnaire(rec, formName, 'CommunityMedicalQuestionnaireController');
    }
    
    // save multiple medical questionnaires
    @AuraEnabled
    public static Boolean saveMedicalQuestionnaires(List<PEO_Onboarding_Medical_Questionnaire__c> recs, String formName) {
        return CommunityMethods.saveMedicalQuestionnaires(recs, formName, 'CommunityMedicalQuestionnaireController');
    }
    
    // Saves the PEO Checklist record
    @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName){ 
        Boolean success = CommunityMethods.savePeoOnboardingChecklist(peoOnbChecklist, formName, 'CommunityAccountEditFormController');
        return success;
    }
    
    // Get the PEO onboarding checklist for the passed in Account ID. Each account should have only one checklist
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,Id oppId,PEO_Onboarding_Checklist__c oldChecklist, String formName) {
        return CommunityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'CommunityMedicalQuestionnaireController');
    }
    
     //Get the medical questionnaire
    @AuraEnabled
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaireForm(Id peoOnboardingChecklistId, String formName) {
         return CommunityMethods.getMedicalQuestionnaireForm(peoOnboardingChecklistId, formName, 'CommunityMedicalQuestionnaireController');
    }
    
    // medical questionnaire save method needed for portal user to save
    // for some reason the standard method doesn't register when logged in
    // the portal. Need this method to take generic map and save values
     @AuraEnabled
    public static Boolean commSaveMedicalQuestionnaire(Map<String, String> rec, String formName) {
        PEO_Onboarding_Medical_Questionnaire__c saveRec = new PEO_Onboarding_Medical_Questionnaire__c(Id=rec.get('Id'));
        
        for (String key : rec.KeySet()) {
            // verify if the key has a data
            if(key.contains('Name')) {
                continue;
            } else if (key.containsIgnoreCase('Date')) {
                saveRec.put(key, date.valueOf(rec.get(key)));
            } else {
                if (rec.get(key).isNumeric()) {
                    Integer i = Integer.valueOf(rec.get(key));
                    saveRec.put(key,i);  
                } else {
                    saveRec.put(key, rec.get(key));   
                }
            }
        }
        
        try {
            update saveRec;   
            return true;
        } catch(DmlException e) {
            communityMethods.logCommunityError(e, 'commSaveMedicalQuestionnaire', 'CommunityMedicalQuestionnaireController',formName, new List<PEO_Onboarding_Medical_Questionnaire__c>{saveRec});
            return false;
        }
    }
    
    @AuraEnabled      
    public static String verifyMedQuestionnairesHaveBeenCompleted(List<Account> allAccounts, String[] parentField){
        
        String accountsMissingInfo = '';
        
        //Check to see if the Parent Account is missing any fields.
        String[] parentFields =new String[]{};        
        String[] grp_med= new String[]{'Past_Medical_Carrier__c','Effective_date__c','Termination_date__c','Reason_for_termination__c'};
        String[] curr_med= new String[]{'Current_PEO_Carrier_if_applicable__c','Rate_change_on_last_renewal__c','Renewal_date__c','Years_with_current_carrier__c'};
        if(parentField.contains('group_medical_Yes')){
            parentFields= grp_med;
        }
        if(parentField.contains('Current_Medical_Yes')){
            if(parentFields.size()>0){                
                parentFields.addAll(curr_med);
            } else{
                parentFields= curr_med;
            }
        }
      
        boolean parentMissingFields = verifyParentMedicalQuestionnaire(allAccounts[0], parentFields);
        
        if(parentMissingFields) {
            System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted 1 Adding Account: ' + allAccounts[0].Name);
            accountsMissingInfo += allAccounts[0].Name + ', ';
        }
        allAccounts.remove(0);
        
        System.debug('MGF parentFields = ' + parentFields);
        PEO_Onboarding_Checklist__c parentChecklist;
		
        //Get a list of all Child Acocunt Ids        
        List<Id> accountIds = new List<Id>();
        for(Account acc : allAccounts) {
            accountIds.add(acc.Id);
        }
        
        //get checklists for child accounts with their medical questionnaires
        Map<Id, Account> accountWithChecklistMap = new Map<Id, Account>([SELECT Id, Name, (SELECT Id, Name FROM PEO_Onboarding_Checklists__r ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :accountIds]);
        
        List<Id> checklistIds = new List<Id>();
        for(Account acc : accountWithChecklistMap.values()) {
            if(acc.PEO_Onboarding_Checklists__r != null && acc.PEO_Onboarding_Checklists__r.size() == 1) {
                checklistIds.add(acc.PEO_Onboarding_Checklists__r[0].Id);
            }
        }
        
        List<Schema.FieldSetMember>  childMedQuestionnaireFieldSet = SObjectType.PEO_Onboarding_Medical_Questionnaire__c.FieldSets.Fields_Shared_With_Children.getFields();
        String[] childFields = new String[]{};
            for (SChema.FieldSetMember field : childMedQuestionnaireFieldSet) {
                childFields.add(field.getFieldPath());
            }
        
        String query = 'SELECT Id, Name, Parent_PEO_Checklist__c, Current_Medical_Coverage_Provided__c, (SELECT Id, Name, Use_Parent_Questionnaire_Answers__c,';
        
        String joinedFields = String.join(childFields, ', ');
        
        query += joinedFields + ' FROM PEO_Onboarding_Medical_Questionnaires__r ORDER BY CreatedDate DESC LIMIT 1) FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds';
        
        Map<Id, PEO_Onboarding_Checklist__c> checklistsWithMQMap = new Map<Id, PEO_Onboarding_Checklist__c>((List<PEO_Onboarding_Checklist__c>)Database.query(query));
        
        System.debug('childFields:'+childFields);
        
        //For each account
        for(Account acc : accountWithChecklistMap.values()) {
            System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted acc.name = ' + acc.Name);
            //get the checklist
            if(acc.PEO_Onboarding_Checklists__r != null && acc.PEO_Onboarding_Checklists__r.size() == 1 && checklistsWithMQMap.containsKey(acc.PEO_Onboarding_Checklists__r[0].Id)) {
                PEO_Onboarding_Checklist__c checklist = checklistsWithMQMap.get(acc.PEO_Onboarding_Checklists__r[0].Id);
                System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted checklist.Id = ' + checklist.Id);
                //Get the medical Questionnaire
                if(checklist.PEO_Onboarding_Medical_Questionnaires__r != null && checklist.PEO_Onboarding_Medical_Questionnaires__r.size() == 1) {
                    PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = checklist.PEO_Onboarding_Medical_Questionnaires__r[0];

                    boolean fieldsAreMissing;     
                    if(checklist.Current_Medical_Coverage_Provided__c == null || checklist.Current_Medical_Coverage_Provided__c != 'No') {
                        fieldsAreMissing = checkForMissingFields(false, medQuestionnaire, childFields);
                    }
                    else {
                        fieldsAreMissing = checkForMissingFields(false, medQuestionnaire, new String[]{});
                    }
                    
                    if(fieldsAreMissing) {
                        System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted 1 Adding Account: ' + acc.Name);
                        accountsMissingInfo += acc.Name + ', ';
                    }
                }
                else {
                    System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted 2 Adding Account: ' + acc.Name);
                    accountsMissingInfo += acc.Name + ', ';
                }
            }
            else {
                System.debug('MGF verifyMedQuestionnairesHaveBeenCompleted 3 Adding Account: ' + acc.Name);
                accountsMissingInfo += acc.Name + ', ';
            }
        }
        
        if(accountsMissingInfo != '') {
            accountsMissingInfo = accountsMissingInfo.substring(0, accountsMissingInfo.length() - 2);
            accountsMissingInfo += '.';
        }
        
        return accountsMissingInfo;
    }
    
    //Verifies that all required fields have been filled out for the Parent Medical Questionnaire.
    public static boolean verifyParentMedicalQuestionnaire(Account parentAccount, String[] parentFields) {
        boolean fieldsAreMissing = false;
        
        PEO_Onboarding_Checklist__c parentChecklist = [SELECT Id, Name FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :parentAccount.Id ORDER BY CreatedDate DESC LIMIT 1];
        
        if(parentChecklist != null) {
            Id parentChecklistId = parentChecklist.Id;
            
            String query = 'SELECT Id, Name, Use_Parent_Questionnaire_Answers__c';
            query+=(parentFields.isEmpty()?'':',');
            //Query for all required parent fields
            String joinedFields = String.join(parentFields, ', ');
            
            query += joinedFields + ' FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c = :parentChecklistId ORDER BY CreatedDate DESC LIMIT 1';  
            system.debug('query:'+query);
            PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = (PEO_Onboarding_Medical_Questionnaire__c)Database.query(query);
            
            if(medQuestionnaire != null) {
                fieldsAreMissing = checkForMissingFields(true, medQuestionnaire, parentFields);
            }
        }
        
        return fieldsAreMissing;
    }
    
    //Checks a list of fields to see if any are missing.
    public static boolean checkForMissingFields(Boolean isParent, PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire, String[] fieldsToCheck){
        boolean fieldsAreMissing = false;
        
        if(isParent) {
            for(String field : fieldsToCheck) {
                if(medQuestionnaire.get(field) == null || medQuestionnaire.get(field) == '') {
                    if((field == 'Effective_date__c' || field == 'Termination_date__c' || field == 'Reason_for_termination__c'|| field == 'Past_Medical_Carrier__c') && fieldsToCheck.contains('group_medical_offered_past_two_years__c') && 
                       (medQuestionnaire.get('group_medical_offered_past_two_years__c') == 'No')) {
                           continue;
                       }
                    if((field == 'Rate_change_on_last_renewal__c' || field == 'Renewal_date__c' || field == 'Years_with_current_carrier__c'|| field == 'Current_PEO_Carrier_if_applicable__c') && fieldsToCheck.contains('Current_Medical_Coverage_Provided__c') && 
                       (medQuestionnaire.get('Current_Medical_Coverage_Provided__c') == 'No')) {
                           continue;
                       }
                    System.debug('MGF checkForMissingFields Parent Missing: ' + field);
                    fieldsAreMissing = true;
                    break;
                }
            }
        }
        else {
            if (medQuestionnaire.Use_Parent_Questionnaire_Answers__c == null || medQuestionnaire.Use_Parent_Questionnaire_Answers__c == '') {
                fieldsAreMissing = true;
            }
            else if(medQuestionnaire.Use_Parent_Questionnaire_Answers__c == 'Different from Parent') {
                for(String field : fieldsToCheck) {
                    if(medQuestionnaire.get(field) == null || medQuestionnaire.get(field) == '') {
                        if((field == 'Effective_date__c' || field == 'Termination_date__c' || field == 'Reason_for_termination__c') && 
                           (medQuestionnaire.get('Past_medical_carrier_if_applicable__c') == 'No')) {
                               continue;
                           }
                         System.debug('MGF checkForMissingFields Child Missing: ' + field);
                        fieldsAreMissing = true;
                        break;
                    }
                }
            }
        }
        return fieldsAreMissing;
    }
    
    @AuraEnabled
    public static Boolean checkBLSPermissions(Id userId, String benchMarkPermission){
        return communityMethods.checkBLSPermissions(userId, benchMarkPermission);
    }*/
}