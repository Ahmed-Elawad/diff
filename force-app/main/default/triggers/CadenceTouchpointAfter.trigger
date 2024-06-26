/* 
 *
 * History
 * -------
 * 05/15/2019    Jermaine Stukes    Created
   05/25/2020    Dan Carmen         Added flag to skip the trigger.
   04/07/2021    Jermaine Stukes    Updated to add Auto-Send and Auto Skip Check
   06/23/2021    Jermaine Stukes    Update skipThisTouchpoint logic to address INC2701936 
   07/24/2023    Jaipal             APR0148811 Updated AutoSkipList with additional reason: Text
    09/26/2023 Pujitha Madamanchi    Autoskip steps when DNC is set on Lead/Contact when in Cadence
*/ 
trigger CadenceTouchpointAfter on Cadence_Touchpoint__c (after insert, after update) {
    System.debug('CadenceTouchpointAfter CadenceHelper.SKIP_TRIGGERS='+CadenceHelper.SKIP_TRIGGERS);
    if (CadenceHelper.SKIP_TRIGGERS) {
         return;
     }
    //List <CadenceUpdate.cadenceWrapper> CadenceWrappers = new List<CadenceUpdate.cadenceWrapper>();
    List <Id>carList = new List<Id>();
    List <Id>carAutoSkipList = new List<Id>();
    List <Id>carAutoSkipCallList = new List<Id>();
    List<Id> cadenceCloseList = new List<Id>();
    List <Id>carAutoSkipTextList = new List<Id>();
    //Boolean processAutomatedEmails = false;
    List<Cadence_Touchpoint__c> checkEligibleContactList = new List<Cadence_Touchpoint__c>();
    //List<Id> contactIdList = new List<Id>();
    for (Cadence_Touchpoint__c touchpoint : Trigger.new){  
        if(Trigger.isInsert){
            if(touchpoint.Status__c == 'Auto Skipped' && (touchpoint.StepType__c == 'Email')){
                carAutoSkipList.add(touchpoint.CarRecord__c);
                carList.add(touchpoint.CarRecord__c);
            }
            if(touchpoint.Status__c == 'Auto Skipped' && (touchpoint.StepType__c == 'Text')){
                carAutoSkipTextList.add(touchpoint.CarRecord__c);
                carList.add(touchpoint.CarRecord__c);
            }
      if(touchpoint.Status__c == 'Auto Skipped' && touchpoint.StepType__c == 'Call' && touchpoint.Override_Call__c){
                carAutoSkipCallList.add(touchpoint.CarRecord__c);
                carList.add(touchpoint.CarRecord__c);
            }
        }
        if(Trigger.isUpdate){
            Cadence_Touchpoint__c oldRec = Trigger.oldMap.get(touchpoint.Id);
            if(touchpoint.Status__c != oldRec.Status__c){
                if(touchpoint.Status__c == 'Auto Skipped' || touchpoint.Status__c == 'Auto Send'){
                    //carAutoSkipList.add(touchpoint.CarRecord__c);
                    carList.add(touchpoint.CarRecord__c);
                }
                if(touchpoint.Status__c == 'Closed' || touchpoint.Status__c == 'Skipped' || touchpoint.Status__c == CadenceUpdate.STATUS_INCOMPLETE){
                    carList.add(touchpoint.CarRecord__c);
                }
                else if(touchpoint.Status__c == 'Canceled By Rep' || touchpoint.Status__c == 'Closed - Cadence Ended'){
                    cadenceCloseList.add(touchpoint.CarRecord__c);
                }
            }
        }
    } // for (Cadence_Touchpoint__c touchpoint : Trigger.new

    System.debug('CadenceTouchpointAfter carAutoSkipList='+carAutoSkipList.size()+' carList='+carList.size()+' cadenceCloseList='+cadenceCloseList.size());
    
    if(!carAutoSkipList.isEmpty()){
        String skipReason = 'Auto Skipped Email: No eligible contacts were available to Email';
        WorkQueueController.updateCarList(carAutoSkipList,skipReason, true);
    }
    if(!carAutoSkipTextList.isEmpty()){
        String skipReason = 'Auto Skipped Text: No eligible contacts were available to Text';
        WorkQueueController.updateCarList(carAutoSkipTextList,skipReason, true);
    }
     if(!carAutoSkipCallList.isEmpty()){
        String skipReason = 'Auto Skipped Call: No eligible contacts were available to Call';
        WorkQueueController.updateCarList(carAutoSkipCallList,skipReason, true);
    }
    if(!carList.isEmpty()){
        CadenceUpdate.updateCarRecs(carList, false);
        CadenceUpdate.createTouchPoint(carList);
    }
    if(!cadenceCloseList.isEmpty()){
        CadenceUpdate.updateCarRecs(cadenceCloseList, true);
    }
} // CadenceTouchpointAfter