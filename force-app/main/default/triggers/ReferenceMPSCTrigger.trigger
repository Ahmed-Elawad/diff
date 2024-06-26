/* 
 * Handles updates to the Reference MPSC object
 *
 * History
 * -------
 * 11/10/2016 Lynn Michels          Created
 * 01/29/2018 Frank Lurz            Added Survey functionality
 * 06/01/2018 Frank Lurz            Added call to the ReferenceMPSC.updateCurrentStep method - Case #26570011
 * 01/23/2019 Dan Carmen            Added TRIGGERS_RAN variable
 * 01/04/2021 Brandon Vidro			Added sendChatter on insert

 */
 trigger ReferenceMPSCTrigger on Reference_MPSC__c (before update, after update, after insert) {
    
    if (ReferenceMPSC.TRIGGERS_RAN) {
       return;
    }
    
    Id mpscTransfer = Schema.SObjectType.Reference_MPSC__c.getRecordTypeInfosByName().get('Reference MPSC Transfer').getRecordTypeId();
    //holds the Reference MPSC where the current step changed
    Map<Id, String> caseCurrentStepMap = new Map<Id, String>();
    //holds the Reference MPSC where the Send Survey changed
    List<Reference_MPSC__c> sendSurveyList = new List<Reference_MPSC__c>();
    Map<Id, Reference_MPSC__c> sendChatter = new Map<Id, Reference_MPSC__c>();
    
    if (Trigger.isBefore){
        if(Trigger.isUpdate){
            ReferenceMPSC.populateReadyToTransferDates(Trigger.new);   
            ReferenceMPSC.updateCurrentStep(Trigger.new); 
            for (Reference_MPSC__c refMPSC : Trigger.new){  
                Reference_MPSC__c oldRefMPSC = (Reference_MPSC__c)Trigger.oldMap.get(refMPSC.id);
                if(refMPSC.RecordTypeId == mpscTransfer && (oldRefMPSC.Send_Survey__c != refMPSC.Send_Survey__c) && (refMPSC.Send_Survey__c == TRUE)){
                    sendSurveyList.add(refMPSC);
                }//end if Survey            
            }//end for loop
            
        }//end isUpdate
    }//end isBefore
    
    if (Trigger.isAfter){
        if(Trigger.isInsert) {
            for (Reference_MPSC__c refMPSC : Trigger.new){  
                sendChatter.put(refMPSC.Id, refMPSC);
            }
        }
        if(Trigger.isUpdate){
            for (Reference_MPSC__c refMPSC : Trigger.new){  
                Reference_MPSC__c oldRefMPSC = (Reference_MPSC__c)Trigger.oldMap.get(refMPSC.id);
                if(refMPSC.RecordTypeId == mpscTransfer && (oldRefMPSC.Current_Step__c != refMPSC.Current_Step__c)){
                    caseCurrentStepMap.put(refMPSC.case_lookup__c, refMPSC.current_step__c);
                }//end if
            }//end for loop
        }//end isUpdate
        // to prevent recursive runs
        ReferenceMPSC.TRIGGERS_RAN = true;
    }//end isAfter
    
    if(!caseCurrentStepMap.isEmpty()){
        ReferenceMPSC.updateCase(caseCurrentStepMap);
    }

    if(!sendSurveyList.isEmpty()){
        ReferenceMPSCSurvey.SendMPSCSurvey(sendSurveyList);
    }
        
    if(!sendChatter.isEmpty()){
        ReferenceMPSC.sendChatterOnRefMPSCInsert(sendChatter);
    }

}//end ReferenceMPSCTrigger