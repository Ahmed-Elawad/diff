trigger PEOComplianceInfoTrigger on PEO_Compliance_Info__c (before insert, before update, after insert,after update) {
	if (Trigger.isAfter) { //Trigger.isUpdate && 
        List<PEO_Compliance_Info__c> complianceData = new List<PEO_Compliance_Info__c>();
        for(PEO_Compliance_Info__c updatedComplianceInfo : Trigger.new){
			complianceData.add(updatedComplianceInfo);
        }
        if(complianceData.size() > 0){
            ClientSpaceHelper.complianceInfoAfter(complianceData);
        }
    }
}