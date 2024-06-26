/* 
   If the current step field changes on the Reference Enterprise Service object, update the current step
   field on the case. 
   
  History
  -------
  08/31/2015 Jacob Hinds   Created 
 */

trigger ReferenceEnterpriseServiceUpdateCase on Reference_Enterprise_Service__c (after update, before update) {
    /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   Map<Id,Id> ownerMap = new Map<Id,Id>();
   for ( Reference_Enterprise_Service__c newRT: Trigger.new) {
      if (Trigger.isUpdate) {
         Reference_Enterprise_Service__c oldRT = Trigger.oldMap.get(newRT.id);
         System.debug('Reference_Enterprise_Service after='+Trigger.isAfter+' before='+Trigger.isBefore+' checking record newRT.Current_Step__c='+newRT.Current_Step__c);
         // should be a lookup present and a value in the current step field.
         if (Trigger.isAfter && (newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
             // if update, only set if there is a value and step field changes 
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
            }
            if ((newRt.OwnerId != oldRt.OwnerId)){
               ownerMap.put(newRt.Id,newRt.OwnerId);
            }
         }
      } // if (Trigger.isUpdat
      
   } // for (Reference_GL__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
   
   if (!ownerMap.isEmpty()){
      ReferenceESMethods.updateChildObjects(ownerMap);
   }
}