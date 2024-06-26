/*
 * On record insert, find the Equifax Commercial Report record that is linked through the Account record
 * Reference Credit Risk -> Case -> Account -> Accord -> Equifax Commercial Report
 *
 * History
 * -------
 * 10/17/2018 Frank Lurz     Created
 * 09/08/2021 Carrie Marciano	Commented out for Forseva uninstall
 */
 trigger ReferenceCreditRisk on Reference_Credit_Risk__c (after insert, after update) {
    Map<Id,String> caseStepMap = new Map<Id,String>();
/*    
    for (Reference_Credit_Risk__c refCreditRisk : Trigger.new)
    {   
        Reference_Credit_Risk__c oldRec = (Trigger.isUpdate ? Trigger.oldMap.get(refCreditRisk.Id) : null);
        if(Trigger.isInsert)
        {   system.debug('***FRL*** - inside the ReferenceCreditRisk trigger, inside isInsert');
            TriggerMethods.checkBeforeLoop('ReferenceCreditRisk', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
        }//end isInsert
        
        if(Trigger.isUpdate)
        {
            /////if (refCreditRisk.Case__c != null && (refCreditRisk.Current_Step__c != oldRec.Current_Step__c)) {
            /////    caseStepMap.put(refCreditRisk.Case__c,refCreditRisk.Current_Step__c);
            /////}//end if       
        }//end isUpdate
    }//end for
    
    /////if (!caseStepMap.isEmpty()) {
    /////    ReferenceUpdateCase.updateCaseStep(caseStepMap);
    /////}
   
   // TriggerMethods.checkInLoop('ReferenceCreditRisk', Trigger.new, Trigger.oldMap,Trigger.isBefore, Trigger.isAfter);
   // TriggerMethods.checkOutsideLoop('ReferenceCreditRisk', Trigger.isBefore, Trigger.isAfter);
*/
}