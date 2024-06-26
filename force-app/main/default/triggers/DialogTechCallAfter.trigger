trigger DialogTechCallAfter on INVOCA_FOR_SF__Invoca_Call_Log__c(after insert, after update) {
        
    TriggerMethods.checkBeforeLoop('DialogTechCallAfter',Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);

    TriggerMethods.checkOutsideLoop('DialogTechCallAfter',Trigger.isBefore, Trigger.isAfter);

}