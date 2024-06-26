trigger HRGAssignment on HRG_Assignment__c (before insert,before update,after insert,after update) {
    new HRGAutoAssignment().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);

}