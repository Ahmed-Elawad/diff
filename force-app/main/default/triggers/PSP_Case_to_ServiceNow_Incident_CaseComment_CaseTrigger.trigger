trigger PSP_Case_to_ServiceNow_Incident_CaseComment_CaseTrigger on CaseComment(after insert, after update) {
   /*persp.PSPLogger Logger = new persp.PSPLogger('PSP_Case_to_ServiceNow_Incident_CaseComment_CaseTrigger', false);
   String triggerWhere = 'UGFyZW50LlNlbmRfQ2FzZV90b19TZXJ2aWNlX05vd19fYz10cnVl';
   persp.PSPUtil.createPspOutMessage('CaseComment', 'aBN0g000000bmIPGAY', 'Id,ParentId,IsPublished,CommentBody,CreatedById,CreatedDate,SystemModstamp,LastModifiedDate,LastModifiedById,IsDeleted,ConnectionReceivedId,ConnectionSentId', EncodingUtil.base64Decode(triggerWhere).toString(), false, '', '', Logger, 'share', '3');*/
}//Full=aBW1b000000CezSGAS Production=aBN0g000000bmIPGAY