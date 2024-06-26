trigger PEOOnboardingMedicalQuestionnaire on PEO_Onboarding_Medical_Questionnaire__c (before insert, before update, after insert,after update) {
    TriggerMethods.checkBeforeLoop('PEOOnboardingMedicalQuestionnaire', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
}