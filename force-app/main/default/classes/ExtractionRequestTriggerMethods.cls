/** Extraction Request Trigger methods class.

* History
* -------
01/27/2022 Reetesh Pandey       Created
04/26/2024 Eric Porter          Updated Extraction Records to update only when the owner has changed from designated queue to user(APR0167969)

*/
public without sharing class ExtractionRequestTriggerMethods {
    public static void handleTrigger(Boolean isBefore,Boolean isAfter, Boolean isUpdate, Map<Id,Extraction_Request__c> newMap, Map<Id,Extraction_Request__c> oldMap){       
        List<Extraction_Request__c> exReqList = new List<Extraction_Request__c>();
        List<Case> caseList = new List<Case>();
        Id MPSCqueueID= [Select id from group where type='queue' AND DeveloperName= 'MPSC_Implementation_Support' limit 1].id;
        for(Extraction_Request__c exr: [select id,ownerId,owner.name,Contact_name__c,Contact_name__r.Name,Contact_Email__c,
                                        case__c,Case__r.CaseNumber,status__c,Sales_Rep_Name__c,CreatedBy.Name,Reassign_to_Queue__c from  Extraction_Request__c where id IN: newMap.keyset() ])
        {
            System.debug('Extraction record updated' + oldMap.get(exr.id) +'----'+ newMap.get(exr.id));
            if( isBefore &&  (oldMap.get(exr.id).Reassign_to_Queue__c != newMap.get(exr.id).Reassign_to_Queue__c) && newMap.get(exr.id).Reassign_to_Queue__c == true ){
                newMap.get(exr.id).OwnerId = MPSCqueueID;
                newMap.get(exr.id).Reassign_to_Queue__c=false;           
                caseList.add(new case(id= exr.case__c,ownerid= MPSCqueueID)); 
            }else {
                if((oldMap.get(exr.id).ownerid != newMap.get(exr.id).ownerid)
                   || (oldMap.get(exr.id).status__c != newMap.get(exr.id).status__c)
                  ){
                      exReqList.add(exr);
                      caseList.add(new case(id= exr.case__c,ownerid= exr.ownerid,status= exr.status__c));   
                  }
            }        
        }
        
        List<Id> userToMentionIdList = new List<Id>();
        String postTextOwnerChange = '';
        String postTextStatusChange = '';
        if(isAfter){
            for(Extraction_Request__c exr:exReqList){ 
                userToMentionIdList.add(exr.CreatedById);
                if(newMap.get(exr.id).ownerid != MPSCqueueID && oldMap.get(exr.id).ownerid != newMap.get(exr.id).ownerid && oldMap.get(exr.id).ownerid == MPSCqueueID){
                    postTextOwnerChange= ' Your request for Data Extraction has been assigned to '+  exr.owner.name +'. We will contact '+
                        exr.Contact_name__r.Name +' through email at '+ exr.Contact_Email__c +' within 24 hours. New Case created with case number '+
                        exr.Case__r.CaseNumber +' .';
                    ChatterMentionPost.createChatterMentionPost(exr.Id, userToMentionIdList, new String[]{postTextOwnerChange}, true, true); 
                    ChatterMentionPost.createChatterMentionPost(exr.case__r.Id, userToMentionIdList, new String[]{postTextOwnerChange}, true, true); 
                }
                if((oldMap.get(exr.id).status__c != newMap.get(exr.id).status__c) && newMap.get(exr.id).status__c == 'Closed - Client Unresponsive'){
                    postTextStatusChange = ' Your request for Data Extraction has been closed, due to unresponsiveness from the contact,'+  exr.Contact_name__r.Name +
                        ' . We attempted to contact through email at '+  exr.Contact_Email__c +' . '+  exr.Sales_Rep_Name__c +
                        ' , please reach out to the client and submit a new extraction request.';
                    ChatterMentionPost.createChatterMentionPost(exr.Id, userToMentionIdList, new String[]{postTextStatusChange}, true, true); 
                    ChatterMentionPost.createChatterMentionPost(exr.case__r.Id, userToMentionIdList, new String[]{postTextStatusChange}, true, true);
                } 
            }
        }
        if(caseList.size()>0){            
            update caseList;
        }
    }
    
}