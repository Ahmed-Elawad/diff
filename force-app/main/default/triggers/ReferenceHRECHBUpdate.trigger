/*    If the current step field changes on the Reference HRE/CHB Onboarding object, update the current step field on the related case.

      History
      -------
      04/12/2013 Frank Lurz   Created

 */
trigger ReferenceHRECHBUpdate on Reference_HRE_CHB_Onboarding__c (after update) {
   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   Map<Id,Id> refsToUpdateMap = new Map<Id,Id>(); 
   for ( Reference_HRE_CHB_Onboarding__c newRT: Trigger.new) {
       System.debug('RReferenceHRECHBUpdate checking record newRT.Current_Step__c='+newRT.Current_Step__c);
      // should be a lookup present and a value in the current step field.
      if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes
          Reference_HRE_CHB_Onboarding__c oldRT = Trigger.oldMap.get(newRT.id);
          if ((newRT.Parent_Case__c != null) && (newRT.Current_Step__c != '')) {
                if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
                   caseStepMap.put(newRT.Parent_Case__c,newRT.Current_Step__c);
                }
          } // if ((newRT.Parent_Case__c
          if (newRt.OwnerId != oldRT.OwnerId) {
              refsToUpdateMap.put(newRt.Id,newRt.ownerId);
              system.debug('FLurz refsToUpdateMap = '+refsToUpdateMap);
          }
      } // if isUpdate
   } // for (Reference_HRE_CHB_Onboarding__c

   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
   if (!refsToUpdateMap.isEmpty()) {
      ReferenceHbkObjManageOwnership.updateObjOwnership(refsToUpdateMap);
   }
} // trigger RReferenceHRECHBUpdate