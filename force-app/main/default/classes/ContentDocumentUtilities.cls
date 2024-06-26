/* 
 *  A utility to handle functions related to ContentDocument.
 *   
 * History
 * -------
 * 06/16/2016 Justin Stouffer Created
   09/18/2020 Dan Carmen      Added SKIP_TRIGGER flag, call to DataLoadMethods
   03/12/2021 Jacob Hinds     Adding peo onboarding document method
   07/23/2021 Dan Carmen      Updated to only push PEO Docs through handleContentDocumentDeleteActions
   09/17/2021 Matt Fritschi   Post chatter message when document is uploaded to PEO Underwriting Document object
   01/22/2022 Jake Hinds      Removing future method, leaving it commented - not sure if this will impact performance.  Adding in DMLHelper
   11/11/2022 Jidesh		  Updated the method changePEODocStatus to default the HSF document as approved
   06/12/2022 Jidesh		  Updated the method changePEODocStatus to default the Quick quote document as approved
   06/22/2023 Jidesh          Created handleRelatedChecklistUpdate to update related checklists of a document based on criteria
 */

public class ContentDocumentUtilities {
    
   public static Boolean SKIP_TRIGGER=false;
   // Jidesh: variable storing PEO Checklists whose Medical Census to Clientspace Status and response needs to be cleared
   public static List<PEO_Onboarding_Checklist__c> refreshChecklists = new List<PEO_Onboarding_Checklist__c>();
    
   public static void handleTriggerActions(ContentDocumentLink[] recs, Map<Id,ContentDocumentLink> oldMap) {
      if (SKIP_TRIGGER) {
         return;
      }
      String dataLoadPrefix = String.valueOf(DataLoad__c.sobjecttype.getdescribe().getkeyprefix());
      String peoDocPrefix = String.valueOf(PEO_Onboarding_Document__c.sobjecttype.getdescribe().getkeyprefix());
      String peoCheckPrefix = String.valueOf(PEO_Onboarding_Checklist__c.sobjecttype.getdescribe().getkeyprefix());
       
      User runningUser = UserHelper.getRunningUser();
       
      if(Trigger.isInsert && Trigger.isBefore)
       {
           List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            System.debug('ContentDocumentLinkBefore');
    
            List<Id> contentDocumentIds = new List<Id>();
            for (ContentDocumentLink cdl : recs) 
            {
                System.debug('ContentDocumentLinkBefore Adding Document Id: '+cdl.ContentDocumentId);
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
       
            Map<Id, ContentVersion> conVersions = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId, Onboarding_Document_Id_fileupload__c FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds]);
       
            for(ContentDocumentLink cdl : recs)
            {
                System.debug('ContentDocumentLinkBefore conVersions.size()='+conVersions.size());
                System.debug('ContentDocumentLinkBefore cdl.ContentDocumentId='+cdl.ContentDocumentId);
                ContentVersion conVer;
                for(ContentVersion cv : conVersions.values())
                {
                    if(cv.ContentDocumentId != null && cv.ContentDocumentId == cdl.ContentDocumentId)
                    {
                        conVer = cv;
                        break;
                    }
                }
                if(conVer != null && conVer.Onboarding_Document_Id_fileupload__c != null && conVer.Onboarding_Document_Id_fileupload__c != cdl.LinkedEntityId && String.valueOf(cdl.LinkedEntityId).startsWith(peoCheckPrefix))
                {
                    System.debug('ContentDocumentLinkBefore setting linked entity Id to '+conVer.Onboarding_Document_Id_fileupload__c);
                    ContentDocumentLink cloned = cdl.clone();
                    cloned.Visibility = 'AllUsers';
                    cloned.LinkedEntityId = conVer.Onboarding_Document_Id_fileupload__c;
                    cloned.ShareType = 'I';
                    cdlList.add(cloned);
                }
            }//for
           if(!cdlList.isEmpty()){
               DmlHelper.performDML2(cdlList, DmlHelper.DML_INSERT, 'ContentDocumentUtilities', 'execute', 'insert content Document links', true);
           }
            
      }
      else if (Trigger.isAfter && Trigger.isInsert) {
         Map<id,ContentDocumentLink> CDMap = new Map<id,ContentDocumentLink>();
         String casePrefix = String.valueOf(case.sobjecttype.getdescribe().getkeyprefix());
         String refHNBFPrefix = String.valueOf(reference_HNBF__c.sobjecttype.getdescribe().getkeyprefix());
         Map<Id,ContentDocumentLink> checkDataLoadMap = new Map<Id,ContentDocumentLink>();
         String[] dataLoadIds = new String[]{};
         Id[] peoDocIds = new Id[]{};
         List<ContentDocumentLink> cdlListForChatter = new List<ContentDocumentLink>();    
          
         for(ContentDocumentLink cdl: recs) {
            String entityId = string.valueOf(cdl.LinkedEntityId);
            if (String.isNotBlank(entityId)) {
                System.debug('ContentDocumentUtilities LinkedEntityId='+entityId);
               if (entityId.startsWith(casePrefix) || entityId.startsWith(refHNBFPrefix)) {
                  cdMap.put(cdl.LinkedEntityId,cdl);                          
               } else if (entityId.startsWith(dataLoadPrefix) && cdl.ContentDocumentId != null) {
                  checkDataLoadMap.put(cdl.ContentDocumentId, cdl);
                  dataLoadIds.add(entityId);
               } else if (entityId.startsWith(peoDocPrefix) && cdl.ContentDocumentId != null) {
                  peoDocIds.add(entityId);
                  cdlListForChatter.add(cdl);
               }
            }
         }//for
    
         if(!cdMap.isEmpty()){
            ContentDocumentUtilities.linkToAccount(cdMap);
         }
          
         if (!checkDataLoadMap.isEmpty()) {
            DataLoadMethods.checkDataLoadRecs(checkDataLoadMap, dataLoadIds);
         } 
         
         if(!peoDocIds.isEmpty()){
             
              postChatterForDocUpload(cdlListForChatter, runningUser);
              changePEODocStatus(peoDocIds);
              /*if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
                  
              }
              else{
                 changePEODocStatusFuture(peoDocIds);
              }*/
             if(refreshChecklists.size()>0){
                 handleRelatedChecklistUpdate(refreshChecklists);
             }
         }
      } else if (Trigger.isDelete && Trigger.isAfter) {
         // update dataloads - file no longer loaded
         Map<String,ContentDocumentLink> deleteCdlMap = new Map<String,ContentDocumentLink>();
         ContentDocumentLink[] peoDeleteDocs = new ContentDocumentLink[]{};
         for (ContentDocumentLink cdl : recs) {
            String entityId = string.valueOf(cdl.LinkedEntityId);
            if (entityId.startsWith(dataLoadPrefix) && cdl.ContentDocumentId != null) {
               deleteCdlMap.put(entityId, cdl);
            } else if (entityId.startsWith(peoDocPrefix) && cdl.ContentDocumentId != null) {
               peoDeleteDocs.add(cdl);
            }
         }
          
          if (!deleteCdlMap.isEmpty()) {
              DataLoadMethods.handleDeletedFiles(deleteCdlMap);
          }
          if (!peoDeleteDocs.isEmpty()) {
             handleContentDocumentDeleteActions(peoDeleteDocs);
          }
      } // if (Trigger.isAfter && Trigger.isInsert
      
   } // handleTriggerActions

    private static set<string> ESR_CASE_REC_TYPE_NAMES = new set<string>{'Service Support ESR Case','Service Onboarding ESR Case'};
        
    private static map<Id,ESR_Document__c> ESRDMap;
    
    private static map<id,account> accountMap;
    
    private static list<case> cases;
    
    private static string caseRecTypeName;
        
    //Posts a chatter message when a prospect uploads a document.
    public static void postChatterForDocUpload(List<ContentDocumentLink> cdlList, User runningUser) {
        
        //get all PEO Onboarding Documents
        List<Id> onboardingDocumentIds = new List<Id>();
        for(ContentDocumentLink cdl : cdlList) {
            if(!onboardingDocumentIds.contains(cdl.LinkedEntityId)) {
                onboardingDocumentIds.add(cdl.LinkedEntityId);
            }
        }
        List<PEO_Onboarding_Document__c> docs = [SELECT Id, Name, PEO_Onboarding_Checklist__c, PEO_Onboarding_Checklist__r.Sales_Rep__c, PEO_Onboarding_Checklist__r.Sales_Analyst__c, PEO_Onboarding_Checklist__r.Prospect_Client__c, PEO_Onboarding_Checklist__r.Prospect_Client__r.Name FROM PEO_Onboarding_Document__c WHERE Id IN :onboardingDocumentIds];
        if(!docs.isEmpty()) {
            List<Id> checklistsAlreadyChattered = new List<Id>();
            
            //Post a chatter to the Checklist for the documents uploaded.
            
            for(PEO_Onboarding_Document__c doc : docs) {
                if(doc.PEO_Onboarding_Checklist__c != null && !checklistsAlreadyChattered.contains(doc.PEO_Onboarding_Checklist__c)) {
                    List<Id> mentionList = new List<Id>();
                    // Updated and commented By Rohith Document Upload User Story Start SFDC-16847
                    //if(doc.Name != 'Census'){
                        if(doc.PEO_Onboarding_Checklist__r.Sales_Rep__c != null && !mentionList.contains(doc.PEO_Onboarding_Checklist__r.Sales_Rep__c)) {
                            mentionList.add(doc.PEO_Onboarding_Checklist__r.Sales_Rep__c);
                        }
                        /*if(doc.PEO_Onboarding_Checklist__r.PEO_NSC__c != null && !mentionList.contains(doc.PEO_Onboarding_Checklist__r.PEO_NSC__c)) {
                            mentionList.add(doc.PEO_Onboarding_Checklist__r.PEO_NSC__c);
                        }*/
                        if(doc.PEO_Onboarding_Checklist__r.Sales_Analyst__c != null && !mentionList.contains(doc.PEO_Onboarding_Checklist__r.Sales_Analyst__c)) {
                            mentionList.add(doc.PEO_Onboarding_Checklist__r.Sales_Analyst__c);
                        }
                    //}
                    // Updated and commented By Rohith Document Upload User Story End
                    // Updated By Rohith Document Upload User Story Start
                    System.debug('Doc'+doc.id);
                    System.debug('Doc Name'+doc.Name);
                    //SPA S11 sfdc-20094-start
                    /*if(doc.Name == 'Census'){
                        if(doc.PEO_Onboarding_Checklist__r.Sales_Rep__c != null){
                            mentionList.add(doc.PEO_Onboarding_Checklist__r.Sales_Rep__c);
                        }
                    }*/
                    //SPA S11 sfdc-20094-end
                    // Updated By Rohith Document Upload User Story End
                    String postText ;
                    String DocName;
                    // Updated By Rohith Document Upload User Story Start
                   if( doc.Name =='WC Rates and Pricing')
                       		DocName='WC Policy / Pricing';
                        else
                         	DocName=doc.Name;
                    
                        postText = 'A new document has been uploaded for ' + DocName + ' by ' + runningUser.Name + ' for Prospect '+ doc.PEO_Onboarding_Checklist__r.Prospect_Client__r.Name + '.';
                  
                    //SPA S11 sfdc-20094-start
                    /*if(doc.Name == 'Census'){
                        postText  =   doc.PEO_Onboarding_Checklist__r.Prospect_Client__r.Name +' has uploaded a Census for review. If you wish to utilize HSF Census Review for this deal, please navigate to the Required Documents section of the Medical Chevron to download the HSF Template. Then continue to the Summary Chevron to fully submit the HSF Census for review. Else, please proceed with a Full Master Medical Submission.”';
                    }*/
                    //SPA S11 sfdc-20094-end
                    // Updated By Rohith Document Upload User Story End SFDC-16847
                   // if(doc.Name != 'Census'){
                        ChatterMentionPost.createChatterMentionPost(doc.PEO_Onboarding_Checklist__c, mentionList, new String[]{postText},true,false);
                   // }
                }
            }
            System.debug('MGF ContentDocumentUtilities handleTriggerActions Posting chatter message...');
            ChatterMentionPost.postBatchFeedElements();
        }
    }
    
    //creates an additional link from a File related to a case, to the Account the case is also related to.    
    public static void linkToAccount(Map<id,id> CDMap){
        set<id> dlIds = new set<id>();
        dlIds.addall(cdMap.values());
        map<id,Document_Link__c> DLMap = new map<id,Document_Link__c>([select id, Case__c, ESR_Document__c from Document_Link__c where id in :dlIDs]);
        accountMap = new map<id,account>([select id, 
                                     (select id from ESR_Documents__r order by CreatedDate ASC limit 1),
                                     (select id, AccountID, recordTypeId from cases where id in:CDMap.keySet())
                                     from account 
                                     where id in (select AccountId from case where id in:CDMap.keySet())]);
        ESRDMap = new map<Id,ESR_Document__c>();
        cases = new list<case>();
        setupESRDs();
        for(case c : cases){
            DLMap.get(CDMap.get(c.Id)).ESR_Document__c=ESRDMap.get(c.AccountId).id;
        }//for(case c : cases){
        if(!DLMap.isEmpty()){
            update DLMap.values();
        }
    }

    //creates an additional link from a File related to a case, to the Account the case is also related to.    
    public static void linkToAccount(Map<id,ContentDocumentLink> CDMap){
        list<contentDocumentLink> CDLs = new list<contentDocumentLink>();
        string refHNBFPrefix = string.valueOf(reference_HNBF__c.sobjecttype.getdescribe().getkeyprefix());
        set<id> caseIDSet = new set<id>();
        set<id> refHNBFIds = new set<id>();
        for(id i:CDMap.keyset()){
            if(string.valueOf(i).startsWith(refHNBFPrefix)){
                refHNBFIds.add(i);                              
            }
        }
        map<id,reference_HNBF__c> refHNBFMap = new map<id,reference_HNBF__c>([select Id, Case_Number__c from reference_HNBF__c where id in :refHNBFIds]);
        if(!refHNBFMap.isEmpty()){
            for(id i: refHNBFMap.keySet()){
                CDMAP.put(refHNBFMap.get(i).Case_Number__c,CDMAP.get(i));
                CDMap.remove(i);                
            }
        }
        accountMap = new map<id,account>([select id, 
                                     (select id from ESR_Documents__r order by CreatedDate ASC limit 1),
                                     (select id, AccountID, recordTypeId from cases where id in:CDMap.keySet())
                                     from account 
                                     where id in (select AccountId from case where id in:CDMap.keySet())]);
        ESRDMap = new map<Id,ESR_Document__c>();
        cases = new list<case>();
        setupESRDs();
        for(case c : cases){
            caseRecTypeName = RecordTypeHelper.getRecordTypeById(c.RecordTypeId,'Case').getName();
            CDLs.add(new contentDocumentLink(LinkedEntityId = (ESR_CASE_REC_TYPE_NAMES.contains(caseRecTypeName) ? ESRDMap.get(c.AccountId).id : c.AccountId),
                                             ContentDocumentId = CDMap.get(c.Id).ContentDocumentId,
                                             ShareType = CDMap.get(c.Id).ShareType,
                                             visibility = CDMap.get(c.Id).visibility));
        }//for(case c : cases){
        if(!CDLs.isEmpty()){
            upsert CDLs;
        }
    }
    
    private static void setupESRDs(){
        for (account a: accountMap.values()){
            cases.addAll(a.cases);                                  
        }//for (account a: accountMap.values())
        for(case c : cases){ 
            caseRecTypeName = RecordTypeHelper.getRecordTypeById(c.RecordTypeId,'Case').getName();
            if(ESR_CASE_REC_TYPE_NAMES.contains(caseRecTypeName) && accountMap.get(c.AccountId).ESR_Documents__r.isEmpty() 
                && !ESRDMap.keySet().contains(c.AccountID)){
                ESRDMap.put(c.AccountID, new ESR_Document__c(Account__c = c.AccountID));                
            }
            else if(ESR_CASE_REC_TYPE_NAMES.contains(caseRecTypeName) && !accountMap.get(c.AccountId).ESR_Documents__r.isEmpty()){
                ESRDMap.put(c.AccountId, accountMap.get(c.AccountId).ESR_Documents__r[0]);      
            }           
        }
        if(!ESRDMap.isEmpty()){
            upsert ESRDMap.values();
        }//for(case c : cases)
    }
    @Future
    public static void changePEODocStatusFuture(Id[] docIds) {
         changePEODocStatus(docIds);
    }
    public static void changePEODocStatus(Id[] docIds) {
        Map<Id,PEO_Onboarding_Document__c> docMap = new Map<Id,PEO_Onboarding_Document__c>([SELECT Id, Name, Status__c,PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c,PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c, PEO_Onboarding_Checklist__r.HSF_Submission_Status__c, PEO_Onboarding_Checklist__r.HSF_Submission_Response__c FROM PEO_Onboarding_Document__c WHERE Id in:docIds]);
        for(PEO_Onboarding_Document__c doc:docMap.values()){
            if(doc.Status__c!='Discrepancy'){
                System.debug('changePEODocStatus doc details:'+doc);
                doc.Status__c = 'Submitted by Prospect';
                //HSF Census submission are done by reps and doesnt require approval
                //Hence the uploaded doc will be approved by default
                //Bypassing the Doc approval when name equals HSF Census
                System.debug('changePEODocStatus docName:'+doc.Name);
                /*if(doc.Name == Label.HSF_Routing_Name){
                    doc.Status__c = 'Approved';
                }*/
                System.debug('changePEODocStatus doc Medical_Underwriting_Path_Type__c:'+doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c);
                System.debug('changePEODocStatus doc Workers_Comp_Underwriting_Path_Type__c:'+doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c);
                if(doc.PEO_Onboarding_Checklist__r.Medical_Underwriting_Path_Type__c == 'Quick Quote - Medical' && doc.PEO_Onboarding_Checklist__r.Workers_Comp_Underwriting_Path_Type__c == 'Quick Quote - Workers Comp'){
                    doc.Status__c = 'Approved';
                    System.debug('Doc status updated as approved');
                    if(doc.Name == 'Census'){
                        doc.Docs_Sent_to_Clientspace__c = '';
                        doc.Date_Sent_to_Clientspace__c = Null;
                        doc.PEO_Onboarding_Checklist__r.HSF_Submission_Status__c = '';
                        doc.PEO_Onboarding_Checklist__r.HSF_Submission_Response__c = '';
                        refreshChecklists.add(doc.PEO_Onboarding_Checklist__r);
                    }
                    
                }
            }
            doc.Date_Uploaded__c=Datetime.now();
        }
        DmlHelper.performDML2(docMap.values(), DmlHelper.DML_UPDATE, 'ContentDocumentUtilities', 'changePEODocStatus', 'Updating Doc Status', true);
    }
    
    //When remove the record is clicked
    public static void handleContentDocumentDeleteActions(ContentDocumentLink[] recs) {
        String peoDocPrefix = String.valueOf(PEO_Onboarding_Document__c.sobjecttype.getdescribe().getkeyprefix());
        //system.debug('peoDocPrefix:'+peoDocPrefix);
        List<Id> contDocIds = new List<Id>();
        List<Id> peoIds = new List<Id>();
        for(ContentDocumentLink cdl: recs)contDocIds.add(cdl.LinkedEntityId);
        List<PEO_Onboarding_Document__c> peoList = [SELECT Id,Name,Parent_Account__c,PEO_Onboarding_Checklist__c,Prospect_Client_Name__c,Routing_Name__c,Status__c 
                                                    FROM PEO_Onboarding_Document__c WHERE Id IN :contDocIds];
        for(PEO_Onboarding_Document__c peoDoc:peoList)peoIds.add(peoDoc.Id);
        List<ContentDocumentLink> cdLinkList = [SELECT ContentDocumentId,Id,IsDeleted,LinkedEntityId,ShareType,SystemModstamp,Visibility 
                                                FROM ContentDocumentLink where LinkedEntityId  IN:peoIds];
        List<Id> documentIds = new List<Id>(); 
        for(ContentDocumentLink cdl:cdLinkList){  
            String entityId = string.valueOf(cdl.LinkedEntityId);
            system.debug('entityId:'+entityId);
            if(entityId.startsWith(peoDocPrefix) && cdl.ContentDocumentId != null)documentIds.add(cdl.ContentDocumentId);  
        }   
        if(documentIds.isEmpty())peoList[0].Status__c = '';
        DmlHelper.performDML2(peoList, DmlHelper.DML_UPDATE, 'ContentDocumentUtilities', 'handleContentDocumentDeleteActions', 'Updating Doc Status', true);
    }
    
    //Update related checklist record when documents are updated
    public static void handleRelatedChecklistUpdate (List<PEO_Onboarding_Checklist__c> refreshChecklists) {
        if(refreshChecklists.size()>0){
            DmlHelper.performDML2(refreshChecklists, DmlHelper.DML_UPDATE, 'ContentDocumentUtilities', 'changePEODocStatus', 'Refreshing the Checklist', true);
        }
    }

    
}