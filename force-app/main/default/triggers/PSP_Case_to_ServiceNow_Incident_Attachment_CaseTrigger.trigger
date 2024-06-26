trigger PSP_Case_to_ServiceNow_Incident_Attachment_CaseTrigger on Attachment(after insert, after update, before delete) {
   /*persp.PSPLogger Logger = new persp.PSPLogger('PSP_Case_to_ServiceNow_Incident_Attachment_CaseTrigger', false);
   String triggerWhere = 'UGFyZW50SWQgaW4gKHNlbGVjdCBJZCBmcm9tIENhc2Ugd2hlcmUgU2VuZF9DYXNlX3RvX1NlcnZpY2VfTm93X19jPXRydWUp';
   persp.PSPUtil.createPspOutMessage('Attachment', 'aBN0g000000bmIPGAY', 'Id,IsDeleted,ParentId,Name,IsPrivate,ContentType,BodyLength,Body,OwnerId,CreatedDate,CreatedById,LastModifiedDate,LastModifiedById,SystemModstamp,Description', EncodingUtil.base64Decode(triggerWhere).toString(), true, '', '', Logger, 'share', '3');*/
}