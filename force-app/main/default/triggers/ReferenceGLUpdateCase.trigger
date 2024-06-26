/* 
   If the current step field changes on the Reference GL object, update the current step
   field on the case. 
   
  History
  -------
  02/02/2010 Dan Carmen   Created
  03/02/2011 Dan Carmen   Modified to use current step map.
  09/09/2011 Dan Carmen   Modified trigger to set client unresponsive status.
  03/25/2015 Jake Hinds   Removed "Client Unresponsive" else clause.
  03/23/2023 Pujitha Madamanchi APR0148464: Update Referral with Xero rev share details
  03/29/2023 Pujitha Madamanchi APR0148464: Backout Update Referral for Xero rev share
   
 */
trigger ReferenceGLUpdateCase on Reference_GL__c (before update, after update) {

   /* The records to be updated. */
   Map<Id,String> caseStepMap = new Map<Id,String>();
   Id[] caseIds = new Id[]{};
   for ( Reference_GL__c newRT: Trigger.new) {
      if (Trigger.isUpdate) {
         Reference_GL__c oldRT = Trigger.oldMap.get(newRT.id);
         System.debug('ReferenceGLUpdateCase after='+Trigger.isAfter+' before='+Trigger.isBefore+' checking record newRT.Current_Step__c='+newRT.Current_Step__c);
         // should be a lookup present and a value in the current step field.
         if (Trigger.isAfter && (newRT.Case_Lookup__c != null) && (newRT.Current_Step__c != '')) {
         // if update, only set if there is a value and step field changes 
            if ((newRt.Current_Step__c != oldRT.Current_Step__c)) {
               caseStepMap.put(newRT.Case_Lookup__c,newRT.Current_Step__c);
            }
         }
          
      } // if (Trigger.isUpdat
      
   } // for (Reference_GL__c
   
   if (!caseStepMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStep(caseStepMap);
   }
   
} // trigger ReferenceGLUpdateCase