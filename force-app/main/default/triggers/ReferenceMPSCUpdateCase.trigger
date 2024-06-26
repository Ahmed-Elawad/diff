/*History
  -------
 * 03/31/2015 Justin Stouffer created
 * 12/08/2016 Lynn Michels 	Not being used
 */
trigger ReferenceMPSCUpdateCase on Reference_MPSC__c (after update) {

   /* The records to be updated. */
  Map<Id,String> caseStepMap = new Map<Id,String>();
   for ( Reference_MPSC__c newRT: Trigger.new) {
       System.debug('ReferenceMPSCUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if ((newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_MPSC__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
            }
         } // if
      } // if ((newRT.Case_Lookup__c
   } // for (Reference_MPSC__c)
   
   if (!caseStepMap.isEmpty()) {
     // ReferenceUpdateCase.updateCaseStep(caseStepMap);
   } 
}