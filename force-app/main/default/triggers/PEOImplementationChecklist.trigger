trigger PEOImplementationChecklist on PEO_Implementation_Checklist__c (before insert, before update, after insert,after update) {
    if (Trigger.isAfter) { //Trigger.isUpdate && 
        List<PEO_Implementation_Checklist__c> checklistData = new List<PEO_Implementation_Checklist__c>();
        for(PEO_Implementation_Checklist__c updatedChecklist : Trigger.new){
            if(updatedChecklist.Status__c == 'Completed' ){
                checklistData.add(updatedChecklist);
            }
        }
        if(checklistData.size() > 0){
            CommunityImplementationController.createRelatedComplianceData(checklistData);
            ClientSpaceHelper.checkImplementationAfterChecklist(checklistData);
        }
    }
}