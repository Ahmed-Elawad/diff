trigger PSP_Case_CaseTrigger on Case(after insert, after update) {
  /*persp.PSPLogger Logger = new persp.PSPLogger('PSP_Case_CaseTrigger', false);
  String triggerWhere = '';
  for (Case caseSobject : Trigger.new) {
      if (caseSobject.Send_Case_to_Service_Now__c != true){
          continue;
      }
      persp.PSPUtil.createPspOutMessage('Case', 'aBN0g000000bmIPGAY', 'Service_Now_Affected_User__c,Service_Now_Caller__c,Service_Now_Client_ID__c,Service_Now_Owner__c,Service_Now_Priority__c,Service_Now_State__c,CaseNumber,Enterprise_Support_Ticket_Number__c,Subject,Description,Id,Assignment_Group__c,Status,Servicenow_Id__c,Business_Application__c,Impact__c,Urgency__c,Manager_Escalation_Comments__c,Manager_Escalation_Needed__c,Manager_Escalation_Reason__c,Manager_Escalation_Submitter_Email__c,Originator_Email_Address__c,Business_Critical_Date__c from Case',  EncodingUtil.base64Decode(triggerWhere).toString(), true, '', '', Logger, '', '3');
  }*/
}//Full=aBW1b000000CezSGAS Production=aBN0g000000bmIPGAY