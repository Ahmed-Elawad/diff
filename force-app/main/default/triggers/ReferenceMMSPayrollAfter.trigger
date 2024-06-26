/*  
   After insert of a new reference object, attach mandatory documents along with documents needed based on the product summery field
 *   
 * History
 * -------
 * 05/31/2013 Cindy Freeman     created
 * 09/09/2013 Cindy Freeman     modified to update case, opty and account from reference record change
 * 09/30/2013 Cindy Freeman     modified to send inserts to CreateRelatedObjects2    
 * 11/27/2013 Cindy Freeman     modified to check fields that need to update Prospect-Client fields
 * 03/06/2014 Justin Henderson removed the call to update MMS Opty Status and RT update.
 * 04/10/2024  Carrie Marciano    Removed code related to old MPSC Process
 */
 
trigger ReferenceMMSPayrollAfter on Reference_MMS_Payroll__c (after insert, after update) {
    
    /* cases to be updated from reference record */
    Map<Id,String> caseStepMap = new Map<Id,String>(); 
     
    /* MMS reference rcds with step changes that may need to update opty */
    Reference_MMS_Payroll__c[] toUpdateSubmitted = new Reference_MMS_Payroll__c[]{};
    /* MMS reference rcds with actual run date changes that may need to update opty */
    Reference_MMS_Payroll__c[] toUpdateStarted = new Reference_MMS_Payroll__c[]{};
    /* MMS reference rcds with owner changes that may need to update account and case */
    //Reference_MMS_Payroll__c[] toUpdateAcct = new Reference_MMS_Payroll__c[]{};
    Id[] mmstoUpdateAcct = new Id[]{};
    /* MMS reference rcds with field changes that need to update account */
    Id[] mmstoUpdateAcctFlds = new Id[] {};
    
    UserHelper uh = new UserHelper();
       
    if (Trigger.isInsert)
    {   //RefMMSPayrollHelper.createOnboardingDocs(Trigger.new); 
        CreateRelatedObjects2.processSObjects('Reference_MMS_Payroll__c', Trigger.new);
    }
        
    if (Trigger.isUpdate)
    {   for ( Reference_MMS_Payroll__c newRec: Trigger.new) {
            Reference_MMS_Payroll__c oldRec = Trigger.oldMap.get(newRec.id);
            if (newRec.Current_Step__c != oldRec.Current_Step__c) {
               caseStepMap.put(newRec.Case_Number__c,newRec.Current_Step__c);               
               toUpdateSubmitted.add(newRec);       // check step and date to update opty
            } // if new step != old step
            if (newRec.First_Payroll_has_Run__c  && newRec.First_Payroll_has_Run__c <> oldRec.First_Payroll_has_Run__c) {
                toUpdateStarted.add(newRec);
            } // if first payroll run date
            if (newRec.OwnerId <> oldRec.OwnerId) {
                // look to see if changed from queue to user
                Group oldOwner = uh.getQueueById(oldRec.OwnerId);             
                User newOwner = uh.getUserById(newRec.OwnerId);           
                if (oldOwner != null && newOwner != null)
                {   mmstoUpdateAcct.add(newRec.Id); }  
            } // if new OwnerId<>old OwnerId
            if ((newRec.Assigned_Prospect_Client_Number__c != null && newRec.Assigned_Prospect_Client_Number__c <> oldRec.Assigned_Prospect_Client_Number__c)
                || (newRec.MyPaychex_com_Client__c != null && newRec.MyPaychex_com_Client__c <> oldRec.MyPaychex_com_Client__c))
            {   mmstoUpdateAcctFlds.add(newRec.Id); }
        } // for
    } // if isUpdate

    if (!caseStepMap.isEmpty()) {
        ReferenceUpdateCase.updateCaseStep(caseStepMap);
    }
    
   // if (!toUpdateSubmitted.isEmpty() || !toUpdateStarted.isEmpty()) {
   //     ReferenceUpdateCase.updateMMSOpty(toUpdateSubmitted, toUpdateStarted);
   // } Removed by JRH
    
    if (!mmstoUpdateAcct.isEmpty()) {
        ReferenceMMSUpdate.processMMSOwner(mmstoUpdateAcct);
    }
    
    if (!mmstoUpdateAcctFlds.isEmpty()) {
        ReferenceMMSUpdate.processMMSAccount(mmstoUpdateAcctFlds);
    }
    
}