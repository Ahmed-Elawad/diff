trigger PSP_Share_Cases_ContentDocumentLink_CaseTrigger on ContentDocumentLink(after insert, after update, before delete) {
  /*persp.PSPLogger Logger = new persp.PSPLogger('PSP_Share_Cases_ContentDocumentLink_CaseTrigger', false);
  String fieldsToShare = 'LinkedEntityId, ContentDocumentId';
  String triggerWhere = 'TGlua2VkRW50aXR5LlNlbmRfQ2FzZV90b19TZXJ2aWNlX05vd19fYz10cnVl';
  
  if(!Trigger.isDelete) {
    List<Id> linkedEntityIds = new List<Id>();
    List<Id> contentDocumentIds = new List<Id>();
    for (ContentDocumentLink obj : Trigger.new) {
        linkedEntityIds.add(obj.LinkedEntityId);
        contentDocumentIds.add(obj.ContentDocumentId);
    }
            
    List<Case> find = [SELECT Send_Case_to_Service_Now__c FROM Case WHERE Id IN :linkedEntityIds AND Send_Case_to_Service_Now__c = true LIMIT 1];
    if (find.size() == 0)
      return;
        
    List<ContentVersion> attachments = [select Title, VersionData, ContentDocumentId, Description, OwnerId, FileType from ContentVersion where ContentDocumentId IN :contentDocumentIds];
    for (Integer i = 0; i < linkedEntityIds.size(); i++) {
        for (ContentVersion attachment : attachments) {
          persp.PSPUtil.createFile(EncodingUtil.base64Encode(attachment.VersionData), JSON.serialize(attachment), '', 'aBN0g000000bmIPGAY', '', 'ContentVersion', '', String.valueOf(linkedEntityIds.get(i)));
        }
    }
  }
  else 
    persp.PSPUtil.createPspOutMessage('ContentDocumentLink', 'aBN0g000000bmIPGAY', fieldsToShare, EncodingUtil.base64Decode(triggerWhere).toString(), true, '', '', Logger, '', '3');

  Logger.commitLog();*/
}
/*trigger PSP_Share_Cases_ContentDocumentLink_CaseTrigger on ContentDocumentLink(after insert, after update, before delete) {
    persp.PSPLogger Logger = new persp.PSPLogger('PSP_Share_Cases_ContentDocumentLink_CaseTrigger', false);
    String fieldsToShare = 'LinkedEntityId, ContentDocumentId';
    String triggerWhere = 'TGlua2VkRW50aXR5LlNlbmRfQ2FzZV90b19TZXJ2aWNlX05vd19fYz10cnVl';
    map<id,id> cdlLEtoCDMap = new map<id,id>();
    if(!Trigger.isDelete) {
        for (ContentDocumentLink obj : Trigger.new) {
            if(obj.LinkedEntityId != NULL && obj.LinkedEntityId.getSobjectType() == Schema.Case.SObjectType){
                cdlLEtoCDMap.put(obj.LinkedEntityId,obj.ContentDocumentId); 
            }
        }
        system.debug('cdlLEtoCDMap ' + cdlLEtoCDMap);
        List<Case> findCase = [SELECT Send_Case_to_Service_Now__c FROM Case WHERE Id IN: cdlLEtoCDMap.keyset() AND Send_Case_to_Service_Now__c = true]; 
        system.debug('findCase ' + findCase);
        if(findCase.isEmpty()){
            return;
        }
        else {
            map<id,id> cdlCDtoLEMap =  new map<id,id>();
            for(case c: findCase){
                if(cdlLEtoCDMap.keySet().contains(c.id)){
                    cdlCDtoLEMap.put(cdlLEtoCDMap.get(c.id),c.id); 
                }
            }
            system.debug('cdlCDtoLEMap ' + cdlCDtoLEMap);
            if(!cdlCDtoLEMap.isEmpty()){            
                for (ContentVersion attachment : [select Title, VersionData, ContentDocumentId, Description, OwnerId, FileType from ContentVersion where ContentDocumentId in :cdlCDtoLEMap.keyset()]) {
                    persp.PSPUtil.createFile(EncodingUtil.base64Encode(attachment.VersionData), JSON.serialize(attachment), '', 'aBN0g000000bmIPGAY', '', 'ContentVersion', '', cdlCDtoLEMap.get(attachment.ContentDocumentId));
                }
            }
        }
    }
    else 
        persp.PSPUtil.createPspOutMessage('ContentDocumentLink', 'aBN0g000000bmIPGAY', fieldsToShare, EncodingUtil.base64Decode(triggerWhere).toString(), true, '', '', Logger, '', '3');
    Logger.commitLog();
}//Full=aBW1b000000CezSGAS Production=aBN0g000000bmIPGAY */