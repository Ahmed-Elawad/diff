/*
 * On record insert, find the Carrier Quote record that is linked through the Acord record
 * Reference PC -> Case -> Opportunity -> Account -> Accord -> Carrier Quote
 * On update, keep current step in sync with case
 * History
 * -------
 * 07/05/2018 Lynn Michels		Created
 */
 trigger ReferencePC on Reference_P_C__c (after insert, after update) {
 	Map<Id,String> caseStepMap = new Map<Id,String>();
 	
 	for (Reference_P_C__c refPC : Trigger.new)
    {   
    	Reference_P_C__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(refPC.Id) : null);
	    if(Trigger.isInsert)
	    {   
	    	TriggerMethods.checkBeforeLoop('ReferencePC', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
	    }//end isInsert
	    
	    if(Trigger.isUpdate)
	    {
	        if (refPC.Case_Lookup__c != null && (refPC.Current_Step__c != oldRec.Current_Step__c)) {
	        	caseStepMap.put(refPC.Case_Lookup__c,refPC.Current_Step__c);
	        }//end if     	
	    }//end isUpdate
    }//end for
    
	if (!caseStepMap.isEmpty()) {
		ReferenceUpdateCase.updateCaseStep(caseStepMap);
	}
   
   // TriggerMethods.checkInLoop('ReferencePC', Trigger.new, Trigger.oldMap,Trigger.isBefore, Trigger.isAfter);
   // TriggerMethods.checkOutsideLoop('ReferencePC', Trigger.isBefore, Trigger.isAfter);

}