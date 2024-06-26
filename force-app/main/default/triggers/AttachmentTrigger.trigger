/*
 * Remove Attachments for Email-to-Case Cases  
 * History
 * -------
 * 02/05/2018 Lynn Michels		Created
 */
 
 
 trigger AttachmentTrigger on Attachment (after insert) {
 	
 	TriggerMethods.checkBeforeLoop('AttachmentTrigger', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
 	
	/*for (Attachment newRec: Trigger.new) {
		Attachment oldRec = Trigger.isUpdate ? Trigger.oldMap.get(newRec.id) : null; 
		TriggerMethods.checkInLoop('AttachmentTrigger', newRec, oldRec, Trigger.IsBefore, Trigger.IsAfter);
		
	}//end for
	*/
  // TriggerMethods.checkOutsideLoop('AttachmentTrigger', Trigger.isBefore, Trigger.isAfter);
}//end AttachmentTrigger