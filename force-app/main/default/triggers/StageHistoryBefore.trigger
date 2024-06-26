/* 
  Trigger for the Stage_History__c object
   
  History
  -------
  06/19/2018 Gram Bischof        Created
  09/20/2018 Dan Carmen          Change to only fire on the insert of a record

*/
trigger StageHistoryBefore on Stage_History__c (before insert) {
	DG_LMF_Service.CreateSLATimeLines(Trigger.new);
} // trigger StageHistoryBefor