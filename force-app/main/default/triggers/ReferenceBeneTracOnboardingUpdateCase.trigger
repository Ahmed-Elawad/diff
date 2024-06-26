/* 
   If the current step field changes on the Reference BeneTrac Onboarding object, update the current step
   field on the case. 
   
  History
  -------
  05/21/2015 Carrie Marciano Created

 */
trigger ReferenceBeneTracOnboardingUpdateCase on Reference_BeneTrac_Onboarding__c (after update) {

   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   for ( Reference_BeneTrac_Onboarding__c newRT: Trigger.new) {
       System.debug('ReferenceBeneTracOnboardingUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if ((newRT.Case_Number__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_BeneTrac_Onboarding__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Number__c,newRT.Current_Step__c);
            }
         } // if
      } // if ((newRT.Case_Number__c
   } // for (Reference_BeneTrac_Onboarding__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
} // trigger ReferenceBeneTracOnboardingUpdateCase