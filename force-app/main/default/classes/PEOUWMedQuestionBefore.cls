public without sharing class PEOUWMedQuestionBefore implements TriggerInterfaceC {
    
    // handle all trigger oparations
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('Made it to before trigger handler');
        if (isBefore && recs != null && !recs.isEmpty()) {
            // handle the after action
            handleBefore(recs, oldMap);
        }
    }
    
    public void handleBefore(SObject[] recs, Map<Id,SObject> oldMap) { 
        
        //Get all checklists for the medical questionnaire
        System.debug('MGF handleBefore');
        List<PEO_Onboarding_Medical_Questionnaire__c> copyParentData = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        List<Id> checklistIds = new List<Id>();
        Map<Id, PEO_Onboarding_Checklist__c> checklists;
        
        for(SObject rec : recs) {
            PEO_Onboarding_Medical_Questionnaire__c questionnaire = (PEO_Onboarding_Medical_Questionnaire__c) rec;
            if(questionnaire.PEO_Onboarding_Checklist__c != null && !checklistIds.contains(questionnaire.PEO_Onboarding_Checklist__c)) {
                checklistIds.add(questionnaire.PEO_Onboarding_Checklist__c);
            }
        }
        
        System.debug('MGF handleBefore checklistIds.size() = ' + checklistIds.size());
        System.debug('MGF handleBefore checklistIds = ' + checklistIds);
        checklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]);
        System.debug('MGF handleBefore checklists.size() = ' + checklists.size());
        for(SObject rec : recs) {
            
            PEO_Onboarding_Medical_Questionnaire__c questionnaire = (PEO_Onboarding_Medical_Questionnaire__c) rec;
            boolean isParent = true;
            
            PEO_Onboarding_Medical_Questionnaire__c oldQuestionnaire = (oldMap!=null && oldMap.containsKey(questionnaire.Id)?(PEO_Onboarding_Medical_Questionnaire__c) oldMap.get(questionnaire.Id):null);
            
            //Check to see if this is a parent or child Medical Questionnaire
            if(checklists.containsKey(questionnaire.PEO_Onboarding_Checklist__c)) {
                PEO_Onboarding_Checklist__c checklist = checklists.get(questionnaire.PEO_Onboarding_Checklist__c);
                System.debug('MGF handleBefore checklist = ' + checklist);
                
                if(checklist.Parent_PEO_Checklist__c != null) {
                    System.debug('MGF handleBefore checklist.Parent_PEO_Checklist__c = ' + checklist.Parent_PEO_Checklist__c);
                    isParent = false;
                }
                
                //If this is a child Medical Questionnaire who wants to use the Parent's data, add it to the list
                if(Trigger.isBefore && !isParent && oldQuestionnaire!=null && questionnaire.Use_Parent_Questionnaire_Answers__c != oldQuestionnaire.Use_Parent_Questionnaire_Answers__c && questionnaire.Use_Parent_Questionnaire_Answers__c == 'Same as Parent') {
                    System.debug('MGF handleBefore adding to copyParentData: ' + questionnaire.Id);
                    copyParentData.add(questionnaire);
                }
            }
        }
        
        //Copy Parent's Data
        if(!copyParentData.isEmpty()) {
            setParentData(copyParentData, checklists);
        }
    }
    
    //Copies fields form the Parent Medical Questionnailre to the Child Medical Questionnaire
    private void setParentData(List<PEO_Onboarding_Medical_Questionnaire__c> copyParentData, Map<Id, PEO_Onboarding_Checklist__c> checklists) {
        
        //Find the Parent PEO Onboarding Checklists, along with their Medical Questionnaires
        System.debug('MGF setParentData');
        List<Id> parentChecklistIds = new List<Id>();
        for(PEO_Onboarding_Medical_Questionnaire__c questionnaire : copyParentData) {
            System.debug('MGF questionnaire = '+questionnaire);
            
            if(checklists.containsKey(questionnaire.PEO_Onboarding_Checklist__c)) {
                PEO_Onboarding_Checklist__c checklist = checklists.get(questionnaire.PEO_Onboarding_Checklist__c);
                System.debug('MGF checklist = '+checklist);
                
                if(checklist.Parent_PEO_Checklist__c != null && !parentChecklistIds.contains(checklist.Parent_PEO_Checklist__c)) {
                    parentChecklistIds.add(checklist.Parent_PEO_Checklist__c);
                    System.debug('MGF parentChecklistIds added = '+checklist.Parent_PEO_Checklist__c);
                }
            }
        }
        System.debug('MGF parentChecklistIds = '+parentChecklistIds);
        Map<Id, PEO_Onboarding_Checklist__c> parentChecklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, 
                                                                                                          (SELECT Id, Name, Current_PEO_Carrier_if_applicable__c, Renewal_date__c, Rate_change_on_last_renewal__c, 
                                                                                                           Years_with_current_carrier__c, Past_medical_carrier_if_applicable__c, Effective_date__c, Termination_date__c, Reason_for_termination__c 
                                                                                                           FROM PEO_Onboarding_Medical_Questionnaires__r ORDER BY CreatedDate DESC LIMIT 1) 
                                                                                                          FROM PEO_Onboarding_Checklist__c WHERE Id IN :parentChecklistIds]);
       
        //From the child Questionnaire, find the Parent's Medical Questionnaire and copy over the Data.
        for(PEO_Onboarding_Medical_Questionnaire__c questionnaire : copyParentData) {
            
            if(checklists.containsKey(questionnaire.PEO_Onboarding_Checklist__c)) {
                PEO_Onboarding_Checklist__c checklist = checklists.get(questionnaire.PEO_Onboarding_Checklist__c);
                System.debug('MGF checklist = '+checklist);
                
                if(parentChecklists.containsKey(checklist.Parent_PEO_Checklist__c)) {
                    PEO_Onboarding_Checklist__c parentChecklist = parentChecklists.get(checklist.Parent_PEO_Checklist__c);
                    System.debug('MGF parentChecklist = '+parentChecklist);
                    
                    if(parentChecklist != null && parentChecklist.PEO_Onboarding_Medical_Questionnaires__r.size() > 0) {
                        List<Schema.FieldSetMember>  medQuestionnaireFieldSet = SObjectType.PEO_Onboarding_Medical_Questionnaire__c.FieldSets.Fields_Shared_With_Children.getFields();
                        String[] fields = new String[]{};
                            
                            for (SChema.FieldSetMember field : medQuestionnaireFieldSet) {
                                fields.add(field.getFieldPath());
                            }
                        System.debug('MGF Fields = ' + fields);
                        for(String field : fields) {
                            questionnaire.put(field, parentChecklist.PEO_Onboarding_Medical_Questionnaires__r[0].get(field));
                            System.debug('MGF parentChecklist.PEO_Onboarding_Medical_Questionnaires__r[0].get(field) = ' + parentChecklist.PEO_Onboarding_Medical_Questionnaires__r[0].get(field));
                        }                        
                    }
                }
            }
        }
        
    }
}