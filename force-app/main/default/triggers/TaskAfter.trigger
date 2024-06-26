/** If there's a call disposition on a task attached to a lead, check if we need to update the lead.
 *
 * History
 * -------
 * 10/11/2013 Dan Carmen        Created.
   10/11/2014 Dan Carmen        Added more logic to set campaign info
   10/15/2014 Dan Carmen        Add in logic to check for ownership
   11/19/2014 Dan Carmen        Additional logic for setting the call disposition
   02/20/2015 Dan Carmen        Callback on PO record, only process NSS tasks if owned by NSR
   10/20/2015 Dan Carmen        Changes to allow to fire for more than NSS Tasks.
   02/08/2016 Lynn Michels    Added code for 'MSP Onboarding Task Recordtype' Record Type
   09/21/2016 Jacob Hinds     Added PartnerReferral task tracking
   02/02/2017 Jacob Hinds     Adding Extra field for PartnerReferral Tracking
   05/15/2017 Josh Cartwright   Adding code to populate MQL/MQL on oppty 
   03/28/2018 Sunnish Annu      Added the Chatter Post for Case when the related Task is completed.
   12/26/2018 Dan Carmen        Move all logic to TaskHelper

 */
trigger TaskAfter on Task (after insert, after update, after delete) {
   System.debug('TaskAfter SKIP_TRIGGERS='+TaskHelper.SKIP_TRIGGERS);
   if (TaskHelper.SKIP_TRIGGERS) {
      return;
   }
   //Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();
   //Id mspOnboardingTaskRtId = TaskHelper.getMSPOnboardingTaskRecordTypeId();
   //Id esrTaskRtId = TaskHelper.getESRTaskRecordTypeId();
   //List<Task> taskList = new List<Task>();
   //List<Task> pRefList = new List<Task>();
   
   //if (nssTaskRtId == null) {
   //   return;
   //}

   TriggerMethods.checkBeforeLoop('TaskAfter', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   //System.debug('TaskAfter label='+Label.ISDC_Task_Name+' nssTaskRtId='+nssTaskRtId+'  isDelete='+Trigger.isDelete+' isUpdate='+Trigger.isUpdate+' isInsert='+Trigger.isInsert);
   
   if (Trigger.isDelete) {
      TaskHelper.checkDeletedTasks(Trigger.old);
      //for (Task oldTsk : Trigger.old) {
      //   System.debug('oldTsk.qbdialer__Callback_Date_Time__c='+oldTsk.qbdialer__Callback_Date_Time__c);
      //   if (oldTsk.RecordTypeId == nssTaskRtId && oldTsk.qbdialer__Callback_Date_Time__c != null) {
      //      System.debug('TaskAfter delete trigger record type matches');
      //      TaskHelper.v_callbackIdsToDelete.add(oldTsk.Id);
      //   }
      //} // for (Task oldTsk : Trigger.old
   //} else {
      //for (Task tsk : Trigger.new) {
     //    Task oldTsk = (Trigger.isUpdate ? Trigger.oldMap.get(tsk.Id) : null);
      //   TriggerMethods.checkInLoop('TaskAfter', tsk, oldTsk, Trigger.IsBefore, Trigger.IsAfter);
         //Boolean statusChanged = ((Trigger.IsInsert || oldTsk.Status != tsk.Status) && tsk.Status == 'Completed') ;
         
         //if((Trigger.isInsert || (Trigger.isUpdate && tsk.CallDisposition!=null && tsk.CallDisposition != oldTsk.CallDisposition)) 
         //  && (tsk.CallType == 'Inbound' || tsk.CallType == 'Outbound') && tsk.Type == 'Call' && tsk.WhoId!=null){
        //     pRefList.add(tsk);
         //}
        
         //if (tsk.RecordTypeId == nssTaskRtId || String.isNotBlank(tsk.CallDisposition) || tsk.qbdialer__Callback_Date_Time__c != null || tsk.isdc_inbound_callerid__c != null) {
         //   System.debug('TaskAfter insert/update recordtype matches');
         //   TaskHelper.checkNSSTaskFromAfterTrigger(tsk,oldTsk);
         //} // if (tsk.RecordTypeId
      
         //if MSP Onboarding Task and it is new or the status is now 'Completed'
         //else if (statusChanged 
         //             && (tsk.RecordTypeId == mspOnboardingTaskRtId || tsk.RecordTypeId == esrTaskRtId))
         //{
         //      taskList.add(tsk);
         //}//end if MSP Onboarding Task
      //} // for (Task tsk
   } // if (Trigger.isDelete
   
   //TriggerMethods.checkOutsideLoop('TaskAfter', Trigger.isBefore, Trigger.isAfter);

   //if(!taskList.isEmpty())
   //{
   //       TaskHelper.taskCompleteChatterPost(taskList); 
   //}
   //if(!pRefList.isEmpty())
   //{
   //     TaskHelper.linkPartnerReferral(pRefList); 
   //}
   
   //TaskHelper.checkForNSSTasksAfterToProcess();
   
   
         //OpptyMethods.checkQualifiedType();
  

} // trigger TaskAfter