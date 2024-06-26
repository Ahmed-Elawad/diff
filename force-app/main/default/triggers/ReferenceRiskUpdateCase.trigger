/* 
   If the current step field changes on the Reference Credit Risk object, update the current step
   field on the case. 
   
  History
  -------
  02/21/2011 Dan Carmen   Created
  03/02/2011 Dan Carmen   Modified to use current step map.
   
 */
trigger ReferenceRiskUpdateCase on Reference_Credit_Risk__c (after update) {

   // The records to be updated.
   Map<Id,String> caseStepMap = new Map<Id,String>();
   // The records that will update fields on the account.
   Reference_Credit_Risk__c[] toUpdateAcct = new Reference_Credit_Risk__c[]{};

   for ( Reference_Credit_Risk__c newRT: Trigger.new) {
      System.debug('ReferenceRiskUpdateCase checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if ((newRT.Case__c != null) && (newRT.Current_Step__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_Credit_Risk__c oldRT = Trigger.oldMap.get(newRT.id);
            if ((newRT.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case__c,newRT.Current_Step__c);
            }
            if (newRT.Updated_Credit_Limit__c != oldRT.Updated_Credit_Limit__c) {
               toUpdateAcct.add(newRT);
            }
         } // if
      } // if ((newRT.Case_Lookup__c
   } // for (Reference_TAA__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }

   if (!toUpdateAcct.isEmpty()) {
      //ReferenceUpdateCase.updateRiskAcct(toUpdateAcct);
   } // if (!
} // trigger ReferenceRiskUpdateCase