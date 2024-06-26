trigger ClientEDWInfo on ClientEDWInfo__c (before insert, before update, after insert, after update) {
   
   if (ClientEDWInfoHelper.TRIGGER_ALREADY_RAN) {
      return;
   }
	
	/*
	if (Trigger.isBefore) {
	   ClientEDWInfoHelper.processAllBefore(Trigger.new, Trigger.oldMap);
	} else if (Trigger.isAfter) {
	   
	}
		for (ClientEDWInfo__c EDW: trigger.new){
			ClientEDWInfo__c oldEdw = (trigger.isUpdate ? trigger.oldmap.get(edw.id) : null); 
			if (Trigger.isBefore) {
			   ClientEDWInfoHelper.checkBefore(EDW, oldEdw);
			} // if (Trigger.isBefore
			if (Trigger.isAfter) {
			   ClientEDWInfoHelper.checkAfter(EDW, oldEdw);
			}
		}	//for 
    */
   if (Trigger.isBefore) {
      ClientEDWInfoHelper.processAllBefore(trigger.new, trigger.oldMap);
   } else if (Trigger.isAfter) {
      ClientEDWInfoHelper.processAllAfter(trigger.new, trigger.oldMap);
      // if it's the after, make sure it doesn't run again ()
      ClientEDWInfoHelper.TRIGGER_ALREADY_RAN = true;
   }
		
} // trigger ClientEDWInfo