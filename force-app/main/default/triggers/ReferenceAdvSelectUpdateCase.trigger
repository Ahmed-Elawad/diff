/* 
   If the current step field changes on the Reference Advisor Select object, update the current step and status
   fields on the case. 
   
  History
  -------
  01/17/2012 Cindy Freeman   Created
   
 */

trigger ReferenceAdvSelectUpdateCase on Reference_Advisor_Select__c (after update) {
    
   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   for ( Reference_Advisor_Select__c newRT: Trigger.new) {
      System.debug('ReferenceAdvSelectUpdateCase checking record newRT.Conversion_Status__c='+newRT.Conversion_Status__c);
      // should be a lookup present and a value in the conversion status field.
      if ((newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and status field changes 
            Reference_Advisor_Select__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
            }
         } // if
      } // if ((newRT.Case_Lookup__c
   } // for (Reference_Advisor_Select__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }

} // trigger ReferenceAdvSelectUpdateCase