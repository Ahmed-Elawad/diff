/* 
   If the current step field changes on the Reference Enterprise Service object, update the current step
   field on the case. 
   
  History
  -------
  10/29/2015 Jacob Hinds   Created 
  12/14/2022 Susmitha Somavarapu  Round Robin to HRS 4S CAM Rollover Checks Queue(APR0145274)
  03/23/2023 Reetesh Pandey	Moved trigger logic to RIFUpdateCaseHandler class

 */
 
trigger ReferenceIncomingFundsUpdateCase on Reference_Incoming_Funds__c (after update, before update) {
	/* The records to be updated. */
   RIFUpdateCaseHandler.updateHandler(true,Trigger.newMap,Trigger.oldMap,Trigger.isAfter,Trigger.isBefore);    
}