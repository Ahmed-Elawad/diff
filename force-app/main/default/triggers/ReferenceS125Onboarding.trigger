/*
*  01/31/2017 Lynn Michels Created to sync Onboarding Status with Current Step on Case
*
*
*/

trigger ReferenceS125Onboarding on Reference_S125_Onboarding__c (after update) {
	
	Map<Id,String> caseStepMap = new Map<Id,String>();
	
	for (Reference_S125_Onboarding__c refS125: Trigger.new) {
		if ((refS125.Case_Lookup__c != null) && (refS125.current_step__c != '')) {
				if (Trigger.isUpdate) {
            		Reference_S125_Onboarding__c oldRT = Trigger.oldMap.get(refS125.id);
            		if ((refS125.current_step__c != oldRT.current_step__c)) {
						caseStepMap.put(refS125.Case_Lookup__c,refS125.current_step__c);
           			}
         		} //end isUpdate
      } //end not null or empty
   } //end for 
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
}//for trigger