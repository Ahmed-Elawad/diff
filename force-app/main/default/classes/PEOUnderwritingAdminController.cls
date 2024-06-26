/* 
* Controller for the PEO Edge Underwriting Admin Lightning Component
*
* History
* -------
* 07/27/2021    Jake Hinds   Created
* 01/25/2022	Jake Hinds	 Document Management
*/
public without sharing class PEOUnderwritingAdminController {
    @AuraEnabled
    public static Map<Id,PEO_Onboarding_Checklist__c> getAllChecklists(String parentChecklistId){
        Map<Id,PEO_Onboarding_Checklist__c> checklistMap = new Map<Id,PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c[] allChecklists = [SELECT Id,Prospect_Client__r.Name FROM PEO_Onboarding_Checklist__c 
                                                       WHERE Id = :parentChecklistId OR Parent_PEO_Checklist__c = :parentChecklistId];
        //loop through once to get the parent to put in first
        for(PEO_Onboarding_Checklist__c checklist : allChecklists){
            if(checklist.Id == parentChecklistId){
                checklistMap.put(checklist.Id,checklist);
                break;
            }
        }
        for(PEO_Onboarding_Checklist__c checklist : allChecklists){
            if(!checklistMap.containsKey(checklist.Id)){
                checklistMap.put(checklist.Id,checklist);
            }
        }
        return checklistMap;
    }
    @AuraEnabled
    public static PEO_Onboarding_Document_Discrepency__c[] getAllDiscrepancies(String[] checklistIds){
        PEO_Onboarding_Document_Discrepency__c[] discs;
        if(!checklistIds.isEmpty()){
            discs = [SELECT Id,Discrepancy_ID__c,Name,Status__c,Discrepancy_Type__c,Discrepancy_Sub_Type__c,Follow_Up_Date__c,additional_information__c,
                                                              Prospect_Client_Name__c,PEO_Underwriting_Checklist__c
                                                              FROM PEO_Onboarding_Document_Discrepency__c 
                     											WHERE PEO_Underwriting_Checklist__c in :checklistIds /*AND Status__c='Open'*/ 
                                                              	ORDER BY Prospect_Client_Name__c,Follow_Up_Date__c ASC];
        }
        system.debug('discs'+discs);
        return discs;
    }
    @AuraEnabled
    public static Boolean updateDiscrepanciesApex(PEO_Onboarding_Document_Discrepency__c updateDisc, PEO_Onboarding_Document_Discrepency__c[] discsToUpdate){
        for(PEO_Onboarding_Document_Discrepency__c disc: discsToUpdate){
            if(disc.Status__c != updateDisc.Status__c && String.isNotBlank(updateDisc.Status__c)){
                disc.Status__c = updateDisc.Status__c;
            }
            if(disc.Follow_Up_Date__c != updateDisc.Follow_Up_Date__c && updateDisc.Follow_Up_Date__c != null){
                disc.Follow_Up_Date__c = updateDisc.Follow_Up_Date__c;
            }
            if(disc.additional_information__c != updateDisc.additional_information__c && String.isNotBlank(updateDisc.additional_information__c)){
                disc.additional_information__c = updateDisc.additional_information__c;
            }
        }
        try{
            update discsToUpdate;
            return true;
        }
        catch(Exception e){
            system.debug('Error updating discrepancies'+e.getMessage());
            return false;
        }
    }
    @AuraEnabled
    public static DocWrapper[] getDocsApex(String checklistId){
        DocWrapper[] docWraps;
        Map<Id,PEO_Onboarding_Document__c> docMap;
        if(String.isNotBlank(checklistId)){
            docMap = new Map<Id,PEO_Onboarding_Document__c>([SELECT Id,Name,Status__c FROM PEO_Onboarding_Document__c 
                                                             WHERE PEO_Onboarding_Checklist__c=:checklistId]);
        }
        system.debug('PEOUnderwritingAdminController getDocsApex docMap'+docMap);
        if(docMap!=null && !docMap.isEmpty()){
            //get all content document links and create a map organizing by onboarding doc id
            Map<Id,ContentDocumentLink[]> linksByDocId = new Map<Id,ContentDocumentLink[]>();
            ContentDocumentLink[] allLinks = [SELECT ContentDocumentId, LinkedEntityId,ShareType,
                                              ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId
                                      FROM ContentDocumentLink 
                                      where LinkedEntityId in :docMap.keySet()
                                      ORDER BY ContentDocument.ContentModifiedDate DESC];
            system.debug('PEOUnderwritingAdminController getDocsApex allLinks'+allLinks);
            for(ContentDocumentLink link:allLinks){
                //if there were multiple links per onb doc we need all of them
                ContentDocumentLink[] linksForMap = new ContentDocumentLink[]{};
                if(!linksByDocId.isEmpty() && linksByDocId.containsKey(link.LinkedEntityId)){
                    linksForMap = linksByDocId.get(link.LinkedEntityId);
                }
                linksForMap.add(link);
                linksByDocId.put(link.LinkedEntityId,linksForMap);
            }
            system.debug('PEOUnderwritingAdminController getDocsApex linksByDocId'+linksByDocId);
            //loop through the onboarding doc ids, get the doc links and build a wrapper
            for(PEO_Onboarding_Document__c onbDoc:docMap.values()){
                ContentDocumentLink[] linksForDoc = linksByDocId.get(onbDoc.Id);
                DocWrapper docWrap = new DocWrapper(onbDoc,linksForDoc);
                if(docWraps==null){
                    docWraps = new DocWrapper[]{};
                }
                docWraps.add(docWrap);
            }
            system.debug('PEOUnderwritingAdminController getDocsApex docWraps'+docWraps);
        }
        return docWraps;
    }
    public class DocWrapper {
        @AuraEnabled
        public Id docId{get;set;}
        @AuraEnabled
        public string name{get;set;}
        @AuraEnabled
        public String status{get;set;}
        @AuraEnabled
        public ContentDocumentLink[] docLinks{get;set;}
        //constructor
        public DocWrapper(PEO_Onboarding_Document__c p_doc,ContentDocumentLink[] p_docLinks) {
            system.debug('PEOUnderwritingAdminController DocWrapper constructor'+p_Doc+' links:'+p_docLinks);
        	docId = p_doc.Id;
			name = p_doc.Name;
            status = p_doc.Status__c;
            docLinks = p_docLinks;
        } // DocWrapper
    }
    @AuraEnabled
    public static void reparentFiles(ContentDocumentLink[] oldLinks,String newParent){
        ContentDocumentLink[] newLinks = new ContentDocumentLink[]{};
        if(oldLinks!=null && !oldLinks.isEmpty()){
        	for(ContentDocumentLink oldLink:oldLinks){
                ContentDocumentLink newLink = new ContentDocumentLink(ContentDocumentId=oldLink.ContentDocumentId,LinkedEntityId=newParent,ShareType=oldLink.ShareType);
                newLinks.add(newLink);
            }
            if(!newLinks.isEmpty()){
                try{
                    insert newLinks;
                	delete oldLinks;
                }
                catch(Exception e){
                    system.debug('error saving: '+e.getMessage());
                }
            }
        }
    }
    @AuraEnabled
    public static void deleteFiles(ContentDocumentLink[] oldLinks){
        ContentDocument[] docs = new ContentDocument[]{};
        if(oldLinks!=null && !oldLinks.isEmpty()){
        	for(ContentDocumentLink oldLink:oldLinks){
                system.debug('oldLink'+oldLink);
                ContentDocument doc = new ContentDocument(Id=oldLink.ContentDocumentId);
                docs.add(doc);
            }
            if(!docs.isEmpty()){
                try{
                    system.debug('docs delete'+docs);
                    delete docs;
                }
                catch(Exception e){
                    system.debug('error saving: '+e.getMessage());
                }
            }
        }
    }
    @AuraEnabled
    public static void approveDocRecord(Id documentId){
        if(String.isNotBlank(documentId)){
            PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(Id=documentId,Status__c='Approved');
            update doc;
        }
    }
    @AuraEnabled
    public static void submitToClientSpace(Id parentChecklistId,String whichDocs){
        system.debug('parentId:'+parentChecklistId+' docType:'+whichDocs);
        if(String.isNotBlank(parentChecklistId) && String.isNotBlank(whichDocs)){
            PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Id=parentChecklistId,Submit_Docs_to_Clientspace__c=whichDocs);
            update checklist;
        }
    }
}