/* 
   If the current step field changes on the Reference TAA object, update the current step
   field on the case. 
   
  History
  -------
  04/27/2010 Matt Nesci   Created via Dan Carmen's code    
  03/02/2011 Dan Carmen   Modified to use current step map.

 */
trigger ReferenceHROUpdateCase on Reference_HRO__c (after update) {

   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   for ( Reference_HRO__c newRT: Trigger.new) {
       System.debug('ReferenceHROUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if ((newRT.Case_Number__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_HRO__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Number__c,newRT.Current_Step__c);
            }
         } // if
      } // if ((newRT.Case_Number__c
   } // for (Reference_HRO__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
} // trigger ReferenceHROUpdateCase