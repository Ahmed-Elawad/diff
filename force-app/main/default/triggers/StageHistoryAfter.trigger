trigger StageHistoryAfter on Stage_History__c (after insert,after update) {
	DG_LMF_Service.UpdateSLATimeLines(trigger.new); 
}