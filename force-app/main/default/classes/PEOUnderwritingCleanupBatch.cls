/* 
Clear out uploaded documents that are no longer needed

History
-------
08/20/2021     Jake Hinds  Created

*/
global without sharing class PEOUnderwritingCleanupBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    public static final String CLASS_NAME='PEOUnderwritingCleanupBatch';
    
    
   	// The total number of accts found.
   	global Integer numberCVs = 0;
   	global Integer numberDocs = 0;
    global Integer numberDeleteErrors = 0;
    
    global JobHelper jh = new JobHelper(CLASS_NAME);
    global Map<Id,PEO_Onboarding_Document__c> docMap;
    global Set<Id> checklistIds = new Set<Id>();
    global Date todayDate = System.today();
    global Date checkDate = System.today().addDays(-180);
    
    // The time the process started. 
    global DateTime startTime;
    // messages that occur during the process.
    global String processNotes = '';
    
    global PEOUnderwritingCleanupBatch() {
        system.debug('in constructor');
        
        docMap = new Map<Id,PEO_Onboarding_Document__c>([SELECT Id,PEO_Onboarding_Checklist__c,Expiration_Date__c 
                                                         FROM PEO_Onboarding_Document__c WHERE Expiration_Date__c <= :todayDate AND Status__c != 'Purged']);
        
    } // PEOUnderwritingCleanupBatch
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // save the record - show that the job started
        jh.setStarted();
        /*return Database.getQueryLocator([SELECT Id,ContentDocumentId,linkedEntityId 
                                         FROM ContentDocumentLink  WHERE ContentDocument.CreatedDate >=:checkDate AND linkedEntityId in :docMap.keySet() ]);*/
        return Database.getQueryLocator([SELECT Id,ContentDocumentId,Onboarding_Document_Id_fileupload__c 
                                         FROM ContentVersion /*USING SCOPE Team*/ WHERE CreatedDate >=:checkDate AND Onboarding_Document_Id_fileupload__c in :docMap.keySet() ]);
    } // start
    
    global void execute(SchedulableContext sc) {
        system.debug('Batch Process scheduled');
        Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
        // pull from the custom setting, otherwise use a default value.
        Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 500);
        PEOUnderwritingCleanupBatch peoUCB = new PEOUnderwritingCleanupBatch();
        database.executeBatch(peoUCB, batchSize);
    } // execute
    
    global void execute(Database.BatchableContext BC, List<SObject> scope)
    {
        List<ContentVersion> cvs = (List<ContentVersion>)scope;
       // List<ContentDocumentLink> cdls = (List<ContentDocumentLink>)scope;
        Map<Id,ContentDocument> cdMap = new Map<Id,ContentDocument>();//Content Document records we will delete
        Map<Id,Id> docIdByCDId = new Map<Id,Id>();//UW doc by Content Doc Id, used for delete verification
        Map<Id,PEO_Onboarding_Document__c> docsToUpdate = new Map<Id,PEO_Onboarding_Document__c>();//UW docs we will update status with
        //deleting a content doc should wipe out all content versions
        for(ContentVersion cv:cvs){
            if(!cdMap.containsKey(cv.ContentDocumentId)){
                ContentDocument cd = new ContentDocument(Id=cv.ContentDocumentId);
                cdMap.put(cd.Id,cd);
                numberCVs++;
                //keep track of the content docs we are trying to delete with their UW doc ID so we can update the record if successful
                docIdByCDId.put(cd.Id,cv.Onboarding_Document_Id_fileupload__c);
            }
        }
        /*for(ContentDocumentLink cdl:cdls){
            if(!cdMap.containsKey(cdl.ContentDocumentId)){
                ContentDocument cd = new ContentDocument(Id=cdl.ContentDocumentId);
                cdMap.put(cd.Id,cd);
                numberCVs++;
                //keep track of the content docs we are trying to delete with their UW doc ID so we can update the record if successful
                docIdByCDId.put(cd.Id,cdl.linkedEntityId);
            }
        }*/
        if(!cdMap.isEmpty()){
        	Database.DeleteResult[] drList = Database.delete(cdMap.values(), false);
            for(Database.DeleteResult dr : drList) {
                if (dr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully deleted account with ID: ' + dr.getId());
                    Id docId = docIdByCDId.get(dr.getId());
                    if(docId!=null && !docsToUpdate.containsKey(docId)){
                        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(Id=docId,Status__c='Purged');
                        docsToUpdate.put(doc.Id,doc);
                        numberDocs++;
                    }
                }//if dr success
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.'+err.getStatusCode() + ': ' + err.getMessage());
                        Id docId = docIdByCDId.get(dr.getId());
                        if(docId!=null){
                            system.debug('error doc Id '+docId);
                            processNotes += '\n Could not delete '+dr.getId()+' on doc record: '+docId+'. Error:'+err.getMessage();
                        }
                        numberDeleteErrors++;
                    }
                }//else
            }//for DR
    		//Database.emptyRecycleBin(cdMap.values());
        }  
        if(!docsToUpdate.isEmpty()){
            DmlHelper.performDML2(docsToUpdate.values(), DmlHelper.DML_UPDATE, 'PEOUnderwritingCleanupBatch', 'execute', 'update PEO UW Doc Status', true);
        }
    } // execute
    
    global void finish(Database.BatchableContext BC){
        String message = '\nTotal Expired Docs Found: '+docMap.size();
        message += '\nTotal CV Deleted: '+numberCVs;
        message += '\nTotal CV Delete Errors: '+numberDeleteErrors;
        message += '\nTotal Docs Records Updated: '+numberDocs;
        message += '\n\n'+processNotes;
        system.debug('message:'+message);
        jh.completeJob(bc, 'PEOUnderwritingCleanupBatch process', message);
        
    } // finish 
}