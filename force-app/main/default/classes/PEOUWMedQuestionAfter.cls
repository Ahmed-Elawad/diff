/*
 * 11/01/2021	Matt Fritschi	Calls checkIfChecklistCompleteFuture on update to see if the form has been completed.
 * 
 * 
 * */
public without sharing class PEOUWMedQuestionAfter implements TriggerInterfaceC {
    
    // handle all trigger oparations
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('Made it to after trigger handler');
        if (Trigger.isUpdate && isAfter && recs != null && !recs.isEmpty()) {
            // handle the after action
            handleAfter(recs, oldMap);
        }
    }
    
    public void handleAfter(SObject[] recs, Map<Id,SObject> oldMap) { 
        
        //Get all checklists for the medical questionnaires
        Set<Id> checklistIds = new Set<Id>();
        Map<Id, PEO_Onboarding_Checklist__c> checklists;
        List<PEO_Onboarding_Medical_Questionnaire__c> moveDataToChildren = new List<PEO_Onboarding_Medical_Questionnaire__c>(); 
        List<PEO_Onboarding_Medical_Questionnaire__c> questionnairesToUpdate = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        
        for(SObject rec : recs) {
            PEO_Onboarding_Medical_Questionnaire__c questionnaire = (PEO_Onboarding_Medical_Questionnaire__c) rec;
            System.debug('MGF handleAfter questionnaire.Use_Parent_Questionnaire_Answers__c=' + questionnaire.Use_Parent_Questionnaire_Answers__c);
            if(questionnaire.PEO_Onboarding_Checklist__c != null && !checklistIds.contains(questionnaire.PEO_Onboarding_Checklist__c)) {
                checklistIds.add(questionnaire.PEO_Onboarding_Checklist__c);
            }
        }
        
        checklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]);
        
        for(SObject rec : recs) {
            PEO_Onboarding_Medical_Questionnaire__c questionnaire = (PEO_Onboarding_Medical_Questionnaire__c) rec;
            boolean isParent = true;
            
            PEO_Onboarding_Medical_Questionnaire__c oldQuestionnaire = (PEO_Onboarding_Medical_Questionnaire__c) oldMap.get(questionnaire.Id);
            
            if(checklists.containsKey(questionnaire.PEO_Onboarding_Checklist__c)) {
                PEO_Onboarding_Checklist__c checklist = checklists.get(questionnaire.PEO_Onboarding_Checklist__c);
                System.debug('MGF checklist = ' + checklist);
                
                if(checklist.Parent_PEO_Checklist__c != null) {
                    System.debug('MGF checklist.Parent_PEO_Checklist__c = ' + checklist.Parent_PEO_Checklist__c);
                    isParent = false;
                }
                
                //If this is a parent Medical Questionnaire, check to see if any fields changed that are shared with children.
                if(Trigger.isAfter && isParent) {
                    boolean sharedFieldsHaveChanged = checkFields(questionnaire, oldQuestionnaire);
                    
                    //If fields changed that were shared with cihldren, copy it to the correct children.
                    if(sharedFieldsHaveChanged) {
                        moveDataToChildren.add(questionnaire);
                    }
                }
            }
            
            
        }
        
        if(!moveDataToChildren.isEmpty()) {
            setFieldsOnChildren(moveDataToChildren, questionnairesToUpdate);
        }
        
        if(!questionnairesToUpdate.isEmpty()) {
            update questionnairesToUpdate;
        }
        
        System.debug('MGF PEOOnbaordingChecklist_Handler calling checkIfChecklistComplete');
        if(!System.isFuture()) {
            CommunityMethods.checkIfChecklistCompleteFuture(checklistIds, 'PEOUWMedQuestionAfter Update');
        }
    }
    
    //Checks to see if any of the fields that are shared with child medical questionnaire's have been changed.
    private boolean checkFields(PEO_Onboarding_Medical_Questionnaire__c questionnaire, PEO_Onboarding_Medical_Questionnaire__c oldQuestionnaire) {
        
        boolean fieldsHaveChanged = false;
        List<Schema.FieldSetMember>  medQuestionnaireFieldSet = SObjectType.PEO_Onboarding_Medical_Questionnaire__c.FieldSets.Fields_Shared_With_Children.getFields();
        String[] fields = new String[]{};
            for (SChema.FieldSetMember field : medQuestionnaireFieldSet) {
                fields.add(field.getFieldPath());
            }
        
        for(String field : fields) {
            if(questionnaire.get(field) != oldQuestionnaire.get(field)) {
                fieldsHaveChanged = true;
                break;
            }
        }
        
        return fieldsHaveChanged;
    }
    
    //Copies shared fields to the necessary children.
    private void setFieldsOnChildren(List<PEO_Onboarding_Medical_Questionnaire__c> moveDataToChildren, List<PEO_Onboarding_Medical_Questionnaire__c> questionnairesToUpdate) {
        
        //
        List<Id> parentChecklistIds = new List<Id>();
        Map<Id, PEO_Onboarding_Medical_Questionnaire__c> parentChecklistsToQuestionnaires = new Map<Id, PEO_Onboarding_Medical_Questionnaire__c>();
        Map<Id, List<PEO_Onboarding_Checklist__c>> parentChecklistsToChildQuestionnaires = new Map<Id, List<PEO_Onboarding_Checklist__c>>();
        
        for(PEO_Onboarding_Medical_Questionnaire__c questionnaire : moveDataToChildren) {
            parentChecklistIds.add(questionnaire.PEO_Onboarding_Checklist__c);
            parentChecklistsToQuestionnaires.put(questionnaire.PEO_Onboarding_Checklist__c, questionnaire);
        }
        
        //Get all child checklists and medical questionnaires for the parent medical questionnaires
        List<PEO_Onboarding_Checklist__c> childChecklists = new List<PEO_Onboarding_Checklist__c>([SELECT Id, Name, Parent_PEO_Checklist__c, (SELECT Id, Name, Current_PEO_Carrier_if_applicable__c, Renewal_date__c, Rate_change_on_last_renewal__c, 
                                                                                                                                              Use_Parent_Questionnaire_Answers__c, Years_with_current_carrier__c, Past_medical_carrier_if_applicable__c, Effective_date__c, Termination_date__c, Reason_for_termination__c 
                                                                                                                                              FROM PEO_Onboarding_Medical_Questionnaires__r ORDER BY CreatedDate DESC LIMIT 1) FROM PEO_Onboarding_Checklist__c WHERE Parent_PEO_Checklist__c IN :parentChecklistIds]);
        
        List<Schema.FieldSetMember>  medQuestionnaireFieldSet = SObjectType.PEO_Onboarding_Medical_Questionnaire__c.FieldSets.Fields_Shared_With_Children.getFields();
        String[] fields = new String[]{};
            
            for (SChema.FieldSetMember field : medQuestionnaireFieldSet) {
                fields.add(field.getFieldPath());
            }
        
        //For each child checklist, if it has been marked 'Same as parent', copy over shared fields.
        for(PEO_Onboarding_Checklist__c checklist : childChecklists) {
            if(checklist.PEO_Onboarding_Medical_Questionnaires__r.size() == 1) {
                PEO_Onboarding_Medical_Questionnaire__c childQuestionnaire = checklist.PEO_Onboarding_Medical_Questionnaires__r[0];
                if(childQuestionnaire.Use_Parent_Questionnaire_Answers__c == 'Same as Parent' && parentChecklistsToQuestionnaires.containsKey(checklist.Parent_PEO_Checklist__c)) {
                    PEO_Onboarding_Medical_Questionnaire__c parentQuestionnaire = parentChecklistsToQuestionnaires.get(checklist.Parent_PEO_Checklist__c);
                    for(String field : fields) {
                        childQuestionnaire.put(field, parentQuestionnaire.get(field));
                    }  
                    
                    questionnairesToUpdate.add(childQuestionnaire);
                }
            }
        }
        
    }
    
}