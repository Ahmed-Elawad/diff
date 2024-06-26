/* 
 *
 * History
 * -------
 * 05/15/2019   Jermaine Stukes   Created
   11/15/2019   Dan Carmen        Only populate the close date if null
   04/08/2020   Jermaine Stukes   check Email Eligibility 
   06/01/2021   Dan Carmen        Populate CloseDateTime__c
   08/31/2021   Dan Carmen        Add in CadenceHelper.SKIP_TRIGGERS for email check
   07/24/2023   Jaipal            APR0148811 Updated Step Type with additional reason: Text
   09/26/2023 Pujitha Madamanchi    Autoskip steps when DNC is set on Lead/Contact when in Cadence
   03/05/2024   Jaipal            Fix for INC3640328 | Touchpoint step is not executing in some scenarios, added text step differently
 */
trigger CadenceTouchpointBefore on Cadence_Touchpoint__c (before insert, before update) {
    List<Cadence_Touchpoint__c> tpEmailCheckList = new List<Cadence_Touchpoint__c>();
    List<Cadence_Touchpoint__c> tpCallCheckList = new List<Cadence_Touchpoint__c>();
    List<Cadence_Touchpoint__c> tpTextCheckList = new List<Cadence_Touchpoint__c>();
    for (Cadence_Touchpoint__c touchpointRecord : Trigger.new)
    {   //Build list to check for email eligible contacts
        if(Trigger.isInsert){
            if(touchpointRecord.Status__c == 'Open' && (touchpointRecord.StepType__c == 'Email' || touchpointRecord.StepType__c == 'Automated Email'))// || touchpointRecord.StepType__c == 'Text'))
            {
                tpEmailCheckList.add(touchpointRecord);               
            }
            if(touchpointRecord.Status__c == 'Open' && touchpointRecord.StepType__c == 'Call'){
                tpCallCheckList.add(touchpointRecord);   
            }
            if(touchpointRecord.Status__c == 'Open' && touchpointRecord.StepType__c == 'Text'){
                tpTextCheckList.add(touchpointRecord);   
            }
        }
        if (Trigger.isUpdate){
            Cadence_Touchpoint__c oldRec = Trigger.oldMap.get(touchpointRecord.Id);
            if(touchpointRecord.Status__c == 'Closed' && touchpointRecord.Close_Date__c==null){
                touchpointRecord.Close_Date__c = Date.today();
            }
            if(touchpointRecord.Status__c == 'Closed' && touchpointRecord.CloseDateTime__c==null){
                touchpointRecord.CloseDateTime__c = Datetime.now();
            }
            if(touchpointRecord.Status__c == 'Open' && (touchpointRecord.StepType__c == 'Email' || touchpointRecord.StepType__c == 'Automated Email')) // || touchpointRecord.StepType__c == 'Text'))
            {
                tpEmailCheckList.add(touchpointRecord);               
            }
            if(touchpointRecord.Status__c == 'Open' && touchpointRecord.StepType__c == 'Call'){
                System.debug('tpCallCheckList');
                tpCallCheckList.add(touchpointRecord);               
            }
            if(touchpointRecord.Status__c == 'Open' && touchpointRecord.StepType__c == 'Text'){
                tpTextCheckList.add(touchpointRecord);               
            }
        }
    }//Check for email eligible contacts
    System.debug('CadenceTouchpointBefore isUpdate='+Trigger.isUpdate+' tpEmailCheckList='+tpEmailCheckList.size());
    if(!CadenceHelper.SKIP_TRIGGERS && !tpEmailCheckList.isEmpty()){
        List<Cadence_Touchpoint__c> tpEmailCheckListAll = new List<Cadence_Touchpoint__c>();
        tpEmailCheckListAll.addAll(tpEmailCheckList);
        CadenceUpdate.checkForEligibleContacts(tpEmailCheckListAll);
    }
    if(!CadenceHelper.SKIP_TRIGGERS && !tpTextCheckList.isEmpty()){
        List<Cadence_Touchpoint__c> tpTextCheckListAll = new List<Cadence_Touchpoint__c>();
        tpTextCheckListAll.addAll(tpTextCheckList);
        CadenceUpdate.checkForEligibleContacts(tpTextCheckList);
    }
    if(!CadenceHelper.SKIP_TRIGGERS && !tpCallCheckList.isEmpty()){
       List<Cadence_Touchpoint__c> tpCallCheckListAll = new List<Cadence_Touchpoint__c>();
        tpCallCheckListAll.addAll(tpCallCheckList);
        CadenceUpdate.checkCallSteps(tpCallCheckListAll);
    }
} // trigger CadenceTouchpointBefore