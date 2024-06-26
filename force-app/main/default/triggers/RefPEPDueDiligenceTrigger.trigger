/* 
	Trigger for the Reference PEP Due Diligence	
	Req: https://wiki.paychex.com/display/CP/APR0116626+-+New+Object+in+SFDC+for+PEP+Due+Diligence+Team

   
	History
	-------
	04/07/2021 Manmeet Vaseer   Created

 */
trigger RefPEPDueDiligenceTrigger on Reference_PEP_Due_Diligence__c (before insert, before update, after insert, after update) {
	RefPEPDueDiligenceMethods.handleTrigger(Trigger.new, Trigger.oldMap);
}