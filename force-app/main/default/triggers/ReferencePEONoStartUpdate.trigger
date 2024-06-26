/* 
   If the Status field changes on the Reference PEO No Start object, update the Status field on the related Case. 
   This code differs from ReferencePEOUpdate in that, there is not a Current Step field being utilized on the Reference PEO No Start object.
   
  History
  -------
  08/04/2015 Frank Lurz   Created
   
 */
trigger ReferencePEONoStartUpdate on Reference_PEO_No_Start__c (after update) {

   /* The records to be updated. */
   Map<Id,String> caseStatusMap = new Map<Id,String>();
    
   for ( Reference_PEO_No_Start__c newRec: Trigger.new) {
      System.debug('ReferencePEONoStartUpdate checking record newRec.Status__c='+newRec.Status__c);
      // should be a lookup present and a value in the Status field.
      if ((newRec.Salesforce_Case__c != null) && (newRec.Status__c != '')) {
         if (Trigger.isUpdate) {
            // if update, only set if there is a value and step field changes 
            Reference_PEO_No_Start__c oldRec = Trigger.oldMap.get(newRec.id);
            if ((newRec.Status__c != oldRec.Status__c)) {
               caseStatusMap.put(newRec.Salesforce_Case__c,newRec.Status__c);
            } // if ((newRec.Status__c
         } // if (Trigger.isUpdate
      } // if ((newRec.Parent_Case__c
   } // for ( Reference_PEO_No_Start__c
    
   if (!caseStatusMap.isEmpty()) {
      ReferenceUpdateCase.updateCaseStatus(caseStatusMap);
   }
  
} // trigger ReferencePEONoStartUpdate