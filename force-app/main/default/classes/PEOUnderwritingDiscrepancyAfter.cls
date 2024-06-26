/*
* History
* -------------------------------
* 5/4/2021		Ahmed Elawad		Created - May the fourth be with you
* 5/5/2020		Ahmed Elawad		Added methods for handeling automated status updates
* 10/11/2021	Matt Fritschi		Updates open discrepancy counts on checklist on insert/update.
*/

public without sharing class PEOUnderwritingDiscrepancyAfter implements TriggerInterfaceC  {
	Public static Boolean SENT_CHATTER = FALSE;    
    // handle all trigger oparations
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('Made it to trigger handler: After');
        if (isAfter && recs != null && !recs.isEmpty()) {
            // handle the after action
            handleAfter(recs, oldMap);
        }
    }
    
    // Segments the document lookup IDs into two maps. One for documents that definetly need to have
    // a 'Discrepancy' status & others where the status needs to be verified. If the current disc status is anything
    // but resolved than the doc status has to be 'Discrepancy'. Calls segmentDocumentsByDiscrepancyStatus helper to
    // partition doc lookup Ids and updateDocumentStatus to determine which documents need to have a status update
    // for documents in the verifyCorrectStatusDocs map
    public void handleAfter(SObject[] recs, Map<Id,SObject> oldMap) {
        List<Peo_Onboarding_Document__c> docsToUpdate = new List<Peo_Onboarding_Document__c>();
        Map<Id, Peo_Onboarding_Document__c> shouldHaveDiscrepancyStatusDocs = new Map<Id, Peo_Onboarding_Document__c>();
        Map<Id, Peo_Onboarding_Document__c> verifyCorrectStatusDocs = new Map<Id, Peo_Onboarding_Document__c>();
        //Map<Id, Peo_Onboarding_Document_Discrepency__c> giveSalesRepViewAccess = new Map<Id, Peo_Onboarding_Document_Discrepency__c>();
        //Map<Id, Peo_Onboarding_Document_Discrepency__c> prospectCommentsChatterMessage = new Map<Id, Peo_Onboarding_Document_Discrepency__c>();
        Map <Id, Map<String, Integer>> discrepancyCountUpdate = new Map <Id, Map<String, Integer>>();
        List<Id> checklistIds = new List<Id>();
        
        // iterate the new recs and sort all the discrepancies into one of the two maps for later updates
        for (SObject newDisc : recs) {
           	segmentDocumentsByDiscrepancyStatus(recs, oldMap, shouldHaveDiscrepancyStatusDocs, verifyCorrectStatusDocs);
            Peo_Onboarding_Document_Discrepency__c newDiscrepancy = (Peo_Onboarding_Document_Discrepency__c) newDisc;
            
            if(Trigger.isInsert && newDiscrepancy.PEO_Underwriting_Checklist__c != null) {
                checklistIds.add(newDiscrepancy.PEO_Underwriting_Checklist__c);
            }
            
            if(Trigger.isUpdate) {
                Peo_Onboarding_Document_Discrepency__c oldDiscrepancy = (Peo_Onboarding_Document_Discrepency__c) oldMap.get(newDiscrepancy.Id);
                if(oldDiscrepancy != null && oldDiscrepancy.Status__c != newDiscrepancy.Status__c) {
                    checklistIds.add(newDiscrepancy.PEO_Underwriting_Checklist__c);
                }
            }
        }
        
        /*
        if(!prospectCommentsChatterMessage.isEmpty()) {
            createChatterPosts(prospectCommentsChatterMessage);
        }*/
        
        // get a list of all the documents and discrepancies to be referenced
        // Should probably add a check for empty lookups in the disc. Lookups on the discrepancy should
        // now always have the checklist, but not always have a document
        Peo_Onboarding_Document__c[] allDocs = [SELECT Id, Status__c 
                                                FROM Peo_Onboarding_Document__c
                                                WHERE Id IN :shouldHaveDiscrepancyStatusDocs.keySet()
                                                OR Id IN :verifyCorrectStatusDocs.keySet()];
        Peo_Onboarding_Document_Discrepency__c[] discsToVerify = [SELECT Id, Status__c, Peo_Onboarding_Document__c 
                                                                  FROM Peo_Onboarding_Document_Discrepency__c
                                                                  WHERE Status__c !='Resolved'
                                                                  AND Peo_Onboarding_Document__c IN :verifyCorrectStatusDocs.keySet()];
        
        // Iterate the documents and determine if the status needs to be updated. For any documents
        // that are in the shouldHaveDiscrepancyStatusDocs continue to the next doc as soon as the
        // status is updated
        for (Peo_Onboarding_Document__c doc : allDocs) {
            if (shouldHaveDiscrepancyStatusDocs.containsKey(doc.Id)) {
                if (doc.Status__c != 'Discrepancy') {
                    doc.Status__c = 'Discrepancy';
                    docsToUpdate.add(doc);
                    continue;
                }
            }
            
            // if the document was flagged as needing a status verification
            // call updateDocumentStatus to verify if the status should be reverted
            // to 'Submitted by Prospect' or updated to 'Discrepancy' if there are
            // still open discrepancies for the document
            if (verifyCorrectStatusDocs.containsKey(doc.Id)) {
                updateDocumentStatus(doc, discsToVerify, docsToUpdate);
            }
        }
        
        //if(!giveSalesRepViewAccess.isEmpty()) {
        //    grantViewAccess(giveSalesRepViewAccess);
        //}
        
        if (!docsToUpdate.isEmpty()) {
            update docsToUpdate;
        } 
        
         if(!checklistIds.isEmpty()) {
            changeOpenDiscCount(checklistIds);
        }
    }
    
    //Used to determine if the Open Discrepancy Count on the Discrepancies checklist needs to be changed.
    //In the future, maybe change this method to use COUNT() query call instead of doing all the math. Could be more reliable.
    public void changeOpenDiscCount(List<Id> checklistIds) {
        System.debug('MGF changeOpenDiscCount');
        
        List<String> openStatus = Label.PEO_UW_Discrepancy_Open_Status.split(',');
        
        Map<Id, PEO_Onboarding_Checklist__c> childChecklistsWithDiscs = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Parent_PEO_Checklist__c, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c, 
                                                                                                                  (SELECT Id, Name, Discrepancy_Category__c, Status__c FROM PEO_Underwriting_Document_Discrepencies__r WHERE Discrepancy_Category__c != null AND Status__c IN :openStatus) 
                                                                                                                  FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds AND Parent_PEO_Checklist__c != null]);
        List<Id> parentIds = new List<Id>();
        Map<Id, PEO_Onboarding_Checklist__c> updatedChecklists = new Map<Id, PEO_Onboarding_Checklist__c>();
        
        for(PEO_Onboarding_Checklist__c checklist : childChecklistsWithDiscs.values()) {
            Integer medicalCount = 0;
            Integer riskCount = 0;
            
            for(Peo_Onboarding_Document_Discrepency__c disc : checklist.PEO_Underwriting_Document_Discrepencies__r) {
                if(disc.Discrepancy_Category__c == 'Medical')
                    medicalCount++;
                if(disc.Discrepancy_Category__c == 'Risk')
                    riskCount++;
            }
            if(!parentIds.contains(checklist.Parent_PEO_Checklist__c)) {
                parentIds.add(checklist.Parent_PEO_Checklist__c);
            }
            checklist.Number_of_Open_Medical_Discrepancies__c = medicalCount;
            checklist.Number_of_Open_Risk_Discrepancies__c = riskCount;
            updatedChecklists.put(checklist.Id, checklist);
        }
        
        checklistIds.addAll(parentIds);
        Map<Id, PEO_Onboarding_Checklist__c> parentChecklsitsWithDiscs = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c, 
                                                                                                                   (SELECT Id, Name, Discrepancy_Category__c, Status__c FROM PEO_Underwriting_Document_Discrepencies__r WHERE Discrepancy_Category__c != null AND Status__c IN :openStatus), 
                                                                                                                   (SELECT Id, Name, Number_of_Open_Medical_Discrepancies__c, Number_of_Open_Risk_Discrepancies__c FROM PEO_Underwriting_Checklists__r)
                                                                                                                   FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds AND Parent_PEO_Checklist__c = null]);
        //
        for(PEO_Onboarding_Checklist__c checklist : parentChecklsitsWithDiscs.values()) {
            Integer medicalCount = 0;
            Integer riskCount = 0;
            
            for(Peo_Onboarding_Document_Discrepency__c disc : checklist.PEO_Underwriting_Document_Discrepencies__r) {
                if(disc.Discrepancy_Category__c == 'Medical')
                    medicalCount++;
                if(disc.Discrepancy_Category__c == 'Risk')
                    riskCount++;
            }
            
            System.debug('MGF changeOpenDiscCount Medical Count 1 = '+medicalCount);
            for(PEO_Onboarding_Checklist__c childChecklist : checklist.PEO_Underwriting_Checklists__r) {
                if(updatedChecklists.containsKey(childChecklist.Id)) {
                    medicalCount = medicalCount + (Integer) updatedChecklists.get(childChecklist.Id).Number_of_Open_Medical_Discrepancies__c;
                    riskCount = riskCount + (Integer) updatedChecklists.get(childChecklist.Id).Number_of_Open_Risk_Discrepancies__c;
                    System.debug('MGF changeOpenDiscCount Medical Count 2 = '+medicalCount);
                }
                else {
                    if(childChecklist.Number_of_Open_Medical_Discrepancies__c != null && childChecklist.Number_of_Open_Medical_Discrepancies__c > 0) {
                        medicalCount = medicalCount + (Integer)childChecklist.Number_of_Open_Medical_Discrepancies__c;
                    }
                    if(childChecklist.Number_of_Open_Risk_Discrepancies__c != null && childChecklist.Number_of_Open_Risk_Discrepancies__c > 0) {
                        riskCount = riskCount + (Integer)childChecklist.Number_of_Open_Risk_Discrepancies__c;
                    }
                    System.debug('MGF changeOpenDiscCount Medical Count 3 = '+medicalCount);
                }
            }
            System.debug('MGF changeOpenDiscCount Medical Count 4 = '+medicalCount);
            checklist.Number_of_Open_Medical_Discrepancies__c = medicalCount;
            checklist.Number_of_Open_Risk_Discrepancies__c = riskCount;
            updatedChecklists.put(checklist.Id, checklist);
        }
        
        if(!updatedChecklists.isEmpty()) {
            DmlHelper.performDML2(updatedChecklists.values(), DmlHelper.DML_UPDATE, 'PEOUnderwritingDiscrepancyAfter', 'changeOpenDiscCount', 'Updating PEO Underwriting Checklists', true);
        }
    }
    
    //Changes the count of the open discrepancies in that category
    public void changeCount(Peo_Onboarding_Document_Discrepency__c newDiscrepancy, Map<String, Integer> discrepancyCategoryCount, Integer num) {
        
        //if category doesn't already exist in the map, create it
        if(!discrepancyCategoryCount.containsKey(newDiscrepancy.Discrepancy_Category__c)) {
            discrepancyCategoryCount.put(newDiscrepancy.Discrepancy_Category__c, num);
        }
        //increment it
        else {
            Integer count = discrepancyCategoryCount.get(newDiscrepancy.Discrepancy_Category__c);
            count = count + num;
            discrepancyCategoryCount.put(newDiscrepancy.Discrepancy_Category__c, count);
        }
    }
    
    // For the list of documents iterate the provided list of discrepancies. If a discrepancy is found for the document update the status
    // of the document to discrepancy and update a flag to not revert the change. If no open discrepancy is found then update the status to
    // 'Submitted by prospect' if it's anything but that.
    // NOTE: May want to add some removal of discrepancies with a lookup to an already verified doc to speed up the iteration. Unsure of 
    // change in operation time at scale if remove is called on the list
    public void updateDocumentStatus(Peo_Onboarding_Document__c doc, Peo_Onboarding_Document_Discrepency__c[] discsToVerify, List<Peo_Onboarding_Document__c> docsToUpdate) {
        Boolean foundOpenDisc = false;
        
        System.debug('Iterating existing discs...');
        // verify if there are any open discrepancies for the document
        for (Peo_Onboarding_Document_Discrepency__c disc: discsToVerify) {
            if ((String)disc.Peo_Onboarding_Document__c == (String)doc.Id) {
                if (doc.Status__c != 'Discrepancy') {
                    doc.Status__c = 'Discrepancy';
                    docsToUpdate.add(Doc);   
                }
                foundOpenDisc = true;
                break;
            }
        }
        
        if (!foundOpenDisc && doc.Status__c == 'Discrepancy') {
            Doc.Status__c = 'Submitted by Prospect';
            docsToUpdate.add(doc);
        }
        
    }
    
    // Segment the documents drivin by the current discrepancies status. If the discrepancy status is anything except resolved regardless of 
    // an update or insert operation then the document status must be 'Discrepancy'. Add these documents to shouldHaveDiscrepancyStatusDocs.
    // If the Status of the disc is resolved then the status of the document is contingent on if there are other open discrepancies for 
    // the document. Add those documents to verifyCorrectStatusDocs
    public void segmentDocumentsByDiscrepancyStatus(SObject[] recs, Map<Id,SObject> oldMap, Map<Id, Peo_Onboarding_Document__c> shouldHaveDiscrepancyStatusDocs, Map<Id, Peo_Onboarding_Document__c> verifyCorrectStatusDocs) {
        for (SObject newDisc : recs) {
            // verify that the status has changed
            Peo_Onboarding_Document_Discrepency__c oldDisc;
            if (oldMap != null && oldMap.get(newDisc.Id) != null) {
                oldDisc = (Peo_Onboarding_Document_Discrepency__c)oldMap.get(newDisc.Id);
            }
            String newDiscStatus = (String)newDisc.get('Status__c');
            if (newDiscStatus != 'Resolved') {
                shouldHaveDiscrepancyStatusDocs.put((Id)newDisc.get('Peo_Onboarding_Document__c'), null);
                continue;
            }
            String oldDiscStatus = (String)oldDisc.get('Status__c');
            if (oldDisc != null && oldDiscStatus != newDiscStatus) {
                verifyCorrectStatusDocs.put((Id)newDisc.get('Peo_Onboarding_Document__c'), null);
            }
        }
    }
    
    /*public void grantViewAccess(Map<Id, Peo_Onboarding_Document_Discrepency__c> giveRepsViewAccess) {
        List<Id> checklistIds = new List<Id>();
        List<Peo_Onboarding_Document_Discrepency__Share> sharingRecs = new List<Peo_Onboarding_Document_Discrepency__Share>();
            
        for(Peo_Onboarding_Document_Discrepency__c disc : giveRepsViewAccess.values()) {
            if(!checklistIds.contains(disc.PEO_Underwriting_Checklist__c)) {
                checklistIds.add(disc.PEO_Underwriting_Checklist__c);
            }
        }
        
        Map<Id, PEO_Onboarding_Checklist__c> checklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]);
        
        for(Peo_Onboarding_Document_Discrepency__c disc : giveRepsViewAccess.values()) {
            if(checklists.containsKey(disc.PEO_Underwriting_Checklist__c)) {
                PEO_Onboarding_Checklist__c checklist = checklists.get(disc.PEO_Underwriting_Checklist__c);
                if(checklist.Sales_Rep__c != null) {
                    Peo_Onboarding_Document_Discrepency__Share discShare = new Peo_Onboarding_Document_Discrepency__Share();
                    discShare.ParentId = disc.Id;
                    discShare.UserOrGroupId  = checklist.Sales_Rep__c;
                    discShare.AccessLevel = 'read';
                    discShare.RowCause = Schema.Peo_Onboarding_Document_Discrepency__Share.RowCause.Sales_Rep__c;
                    sharingRecs.add(discShare);
                }
            }
        }
        
        Database.SaveResult[] lsr = Database.insert(sharingRecs,false);
        
        Integer i=0;
        for(Database.SaveResult sr : lsr){
            if(!sr.isSuccess()){
                // Get the first save result error
                Database.Error err = sr.getErrors()[0];
                
                // Check if the error is related to a trivial access level
                // Access levels equal or more permissive than the object's default 
                // access level are not allowed. 
                // These sharing records are not required and thus an insert exception is 
                // acceptable. 
                if(!(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                               &&  err.getMessage().contains('AccessLevel'))){
                    // Throw an error when the error is not related to trivial access level.
                    trigger.newMap.get(sharingRecs[i].ParentId).
                      addError(
                       'Unable to grant sharing access due to following exception: '
                       + err.getMessage());
                }
            }
            i++;
        }  
    }*/
    
    /*public void createChatterPosts(Map<Id, Peo_Onboarding_Document_Discrepency__c> prospectCommentsChatterMessage) {
        System.debug('MGF PEOUnderwritingCiscrepenctAfter createChatterPosts');
        for(Peo_Onboarding_Document_Discrepency__c disc : prospectCommentsChatterMessage.values()) {
            List<Id> usersToMention = new List<Id>();
            Id parentId = disc.Id;
            String[] messages = new String[]{};
            
            String message = disc.Prospect_Client_Name__c + ' has responded to ' + disc.Discrepancy_Type__c;
            if(disc.Discrepancy_Sub_Type__c != null) {
                message += '/' + disc.Discrepancy_Sub_Type__c;
            }
            message += '. Please review the response and mark the discrepancy as resolved at your earliest convenience ' + disc.PEO_Underwriting_Checklist__c;
            
            messages.add(message);
            ChatterMentionPost.createChatterMentionPost(parentId, usersToMention, messages, true);
            SENT_CHATTER = true;
        }
    }*/
}