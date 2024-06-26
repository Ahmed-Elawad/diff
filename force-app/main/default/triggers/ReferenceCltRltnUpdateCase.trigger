/* 
   If the current step field changes on the Reference Client Relations object, update the current step
   field on the case. 
   
  History
  -------
  02/02/2010 Dan Carmen   Created  - Updated by Michelle Brown 2/11/11
   
 */
trigger ReferenceCltRltnUpdateCase on Reference_Client_Relations__c (after update) {

   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   
   for ( Reference_Client_Relations__c newRT: Trigger.new) {
      System.debug('ReferenceCltRltnUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if ((newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_Client_Relations__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
            }
         } // if
      } // if ((newRT.Case_Lookup__c
   } // for (Reference_Client_Relations__c
      
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
} // trigger ReferenceCltRltnUpdateCase