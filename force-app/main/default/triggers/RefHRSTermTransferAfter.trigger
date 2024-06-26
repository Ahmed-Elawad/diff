/*
    
    History
    --------
    10/06/2017  Lynn Michels    Created
*/
trigger RefHRSTermTransferAfter on Reference_HRS_Termination_Transfer__c (after update) {
    if(RefHRSTermTransferMethods.skipTrigger == true){
        return;
    }
    for (Reference_HRS_Termination_Transfer__c newRec : Trigger.new) {
        Reference_HRS_Termination_Transfer__c oldRec = Trigger.oldMap.get(newRec.id);
        TriggerMethods.checkInLoop('RefHRSTermTransferAfter', newRec, oldRec, Trigger.isBefore, Trigger.isAfter);
    }
    TriggerMethods.checkOutsideLoop('RefHRSTermTransferAfter', Trigger.isBefore, Trigger.isAfter);

}