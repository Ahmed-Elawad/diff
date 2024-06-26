/* Trigger for Onboarding checklist
*
*   HISTORY
*  ---------
*   03/10/2021  Jacob Hinds     Created

*/
trigger PEOOnboardingChecklist on PEO_Onboarding_Checklist__c (before insert, before update, after insert,after update) {
    if(Trigger.isBefore && Trigger.IsInsert){
        TriggerMethods.checkBeforeLoop('PEOOnboardingChecklist', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
        PEOOnboardingChecklist_Handler.beforeInsertHandler(Trigger.New);
    }
    else if(Trigger.isAfter && Trigger.IsInsert){
        TriggerMethods.checkBeforeLoop('PEOOnboardingChecklist', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
        PEOOnboardingChecklist_Handler.afterInsertHandler(Trigger.OldMap, Trigger.NewMap);
    }else if(Trigger.isBefore && Trigger.IsUpdate){
        TriggerMethods.checkBeforeLoop('PEOOnboardingChecklist', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
        PEOOnboardingChecklist_Handler.beforeUpdateHandler(Trigger.OldMap, Trigger.NewMap);
    }
    else if(Trigger.isAfter && Trigger.IsUpdate){
        TriggerMethods.checkBeforeLoop('PEOOnboardingChecklist', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
        PEOOnboardingChecklist_Handler.afterUpdateHandler(Trigger.OldMap, Trigger.NewMap);
    }
}