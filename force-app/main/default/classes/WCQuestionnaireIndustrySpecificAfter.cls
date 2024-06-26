/* After Trigger for WC Questionnaire Industry Specific object
*
*   HISTORY
*  ---------
*   08/12/2021  Matt Fritschi     Created
*	11/01/2021	Matt Fritschi	Calls CommunityMethods.checkIfChecklistCompleteFuture on after update
	02/10/2022  Jake Hinds		  Status to checklist
*/
public without sharing class WCQuestionnaireIndustrySpecificAfter implements TriggerInterfaceC {
    
    // handle all trigger oparations
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('WCQuestionnaireIndustrySpecificAfter Made it to after trigger handler');
        if (isAfter && recs != null && !recs.isEmpty()) {
            // handle the after action
            handleAfter(recs, oldMap);
        }
        
        if (isAfter && oldMap != null && !oldMap.isEmpty()) {
            // handle the after action
            handleAfter(null, oldMap);
        }
    }
    
    public void handleAfter(SObject[] recs, Map<Id,SObject> oldMap) { 
        
        Map<Id,PEO_Onboarding_Checklist__c> checklistsToUpdate = new Map<Id,PEO_Onboarding_Checklist__c>();
        Map<Id, List<String>> checklistToRecordTypes = new Map<Id, List<String>>();
        Map<Id, RecordType> indSpecificRecordTypes = new Map<Id, RecordType>([SELECT Id, Name from RecordType where sObjectType='WC_Questionnaire_Industry_Specific__c']);
        Set<Id> checklistIds = new Set<Id>();
        List<Id> checklistCheckCompleteIds = new List<Id>();
        Map<Id, List<String>> isqToRemoveFromChk = new Map<Id, List<String>>();
        
        //Get a map of checklist Ids to the new incoming Industry Specific Record Types
        if(!Trigger.isDelete) {
            for(SObject rec : recs) {
                WC_Questionnaire_Industry_Specific__c indSpecific = (WC_Questionnaire_Industry_Specific__c) rec;
                WC_Questionnaire_Industry_Specific__c oldRec = (oldMap!=null && !oldMap.isEmpty() ? (WC_Questionnaire_Industry_Specific__c)oldMap.get(indSpecific.Id):null);
                
                if(indSpecific.PEO_Underwriting_Checklist__c != null && !checklistCheckCompleteIds.contains(indSpecific.PEO_Underwriting_Checklist__c) && 
                   (oldRec == null || (oldRec!=null && oldRec.Peo_IndSpecific_formStatus__c != indSpecific.Peo_IndSpecific_formStatus__c))) {
                       checklistCheckCompleteIds.add(indSpecific.PEO_Underwriting_Checklist__c);
                   }
                if(Trigger.isInsert) {
                    
                    if(!checklistToRecordTypes.keySet().contains(indSpecific.PEO_Underwriting_Checklist__c)) {
                        checklistToRecordTypes.put(indSpecific.PEO_Underwriting_Checklist__c, new List<String>());
                    }
                    
                    RecordType recordType = indSpecificRecordTypes.get(indSpecific.RecordTypeId);
                    List<String> recordTypes = checklistToRecordTypes.get(indSpecific.PEO_Underwriting_Checklist__c);
                    if(recordTypes != null && String.isNotBlank(recordType.Name) && !recordTypes.contains(recordType.Name)) {
                        recordTypes.add(recordType.Name);
                    }
                }
                else if(Trigger.isUpdate) {
                    if(indSpecific.PEO_Underwriting_Checklist__c != null) {
                        checklistIds.add(indSpecific.PEO_Underwriting_Checklist__c);
                    }
                }
            }
        }
        
        if(Trigger.isDelete) {
            for(SObject rec : oldMap.values()) {
                WC_Questionnaire_Industry_Specific__c indSpecific = (WC_Questionnaire_Industry_Specific__c) rec;
                
                System.debug('PeoWCIndSpecificDeleteAfter: Handeling rec delete');
                if(!isqToRemoveFromChk.keySet().contains(indSpecific.PEO_Underwriting_Checklist__c)) {
                    System.debug('PeoWCIndSpecificDeleteAfter:Adding chk to isq update map');
                    isqToRemoveFromChk.put(indSpecific.PEO_Underwriting_Checklist__c, new List<String>());
                }
                
                RecordType recordType = indSpecificRecordTypes.get(indSpecific.RecordTypeId);
                System.debug('PeoWCIndSpecificDeleteAfter:recordType: '+recordType);
                List<String> recordTypes = isqToRemoveFromChk.get(indSpecific.PEO_Underwriting_Checklist__c);
                if(recordTypes != null && recordType!=null && String.isNotBlank(recordType.Name) && !recordTypes.contains(recordType.Name)) {
                    recordTypes.add(recordType.Name);
                    System.debug('PeoWCIndSpecificDeleteAfter:Added isq name to recordTypes: '+recordTypes);
                }
                System.debug('PeoWCIndSpecificDeleteAfter:recordTypes: '+recordTypes);
                if(indSpecific.PEO_Underwriting_Checklist__c != null && !checklistCheckCompleteIds.contains(indSpecific.PEO_Underwriting_Checklist__c)){
                    checklistCheckCompleteIds.add(indSpecific.PEO_Underwriting_Checklist__c);
                    System.debug('PeoWCIndSpecificDelete: Added indSpecific.PEO_Underwriting_Checklist__c to checklistCheckCompleteIds:'+checklistCheckCompleteIds);
                }
            }
        }
        
        if(!checklistToRecordTypes.isEmpty()) {
            System.debug('PeoWCIndSpecificDelete: Adding ISQ values to chk: '+checklistToRecordTypes);
            // pass in false so the new rec types are added
            udpateChecklistIndSpecRecordTypes(checklistsToUpdate, checklistToRecordTypes, false);            
        }
        
        if(!isqToRemoveFromChk.isEmpty()) {
            System.debug('PeoWCIndSpecificDelete: Removing ISQ values to chk: '+isqToRemoveFromChk);
            // pass in true so rec types are removed
            udpateChecklistIndSpecRecordTypes(checklistsToUpdate, isqToRemoveFromChk, true);            
        }
        
        if(!checklistCheckCompleteIds.isEmpty()){
            System.debug('PeoWCIndSpecificDelete: Updating ISQ Status field for CHKs: '+checklistCheckCompleteIds);
            checkIfChecklistComplete(checklistCheckCompleteIds,checklistsToUpdate);
        }
        
        System.debug('WCQuestionnaireIndustrySpecificAfter checklistsToUpdate.size()='+checklistsToUpdate.size());
        //Update the checklists
        if(!checklistsToUpdate.isEmpty()) {
            // when debuggin failed field saves use standard DML so errors are surfaced and clear
            //Boolean success = DMLHelper.performDML2(checklistsToUpdate.values(),DmlHelper.DML_UPDATE,'WCQuestionnaireIndustrySpecificAfter','handleAfter','update checklistsToUpdate' ,true);
            try {
                update checklistsToUpdate.values();
            }Catch(Exception e) {
                System.debug('PeoWCIndSpecificDelete: failed update: '+e.getMessage());
            }
        }
        
        System.debug('MGF WCQuestionnaireIndustrySpecificAfter System.isFuture()='+System.isFuture()+' checklistIds.IsEmpty()='+checklistIds.IsEmpty());
        if(!System.isFuture() && !checklistIds.IsEmpty()) {
            //CommunityMethods.checkIfChecklistCompleteFuture(checklistIds, 'WCQuestionnaireIndustrySpecificAfter After Update');
        }
        
    }
    
    public void udpateChecklistIndSpecRecordTypes(Map<Id,PEO_Onboarding_Checklist__c> checklistsToUpdate, Map<Id, List<String>> checklistToRecordTypes, Boolean removeISQValues) {
        System.debug('WCQuestionnaireIndustrySpecificAfter checklistToRecordTypes.size()='+checklistToRecordTypes.size()+' removgin values: '+ removeISQValues);
        //Add the new record types into the Checklist's field if they are not currently there.
        List<PEO_Onboarding_Checklist__c> checklists = new List<PEO_Onboarding_Checklist__c>([SELECT Id, Name, Industry_Record_Types__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistToRecordTypes.keySet()]);
        for(PEO_Onboarding_Checklist__c checklist : checklists) {
            // get the list of industries for this checklsit adn set it to industryRecordTypes
            List<String> industryRecordTypes = checklistToRecordTypes.get(checklist.Id);
            String currentRecordTypes = '';
            // if th cheklsit has record types set them to the currentRecordTypes string
            if(checklist.Industry_Record_Types__c != null) {
                System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: setting rec types from chk: '+ checklist.Industry_Record_Types__c);
                currentRecordTypes = checklist.Industry_Record_Types__c;
            }
            boolean changed = false;

            // iterate the list of industryRecordTypes
            for(String recordType : industryRecordTypes) {
                // if the recordtypes string is blank or the strig doesn't contain the record type string
                // if the string is blank assign the new string and add the record type name
                if (!removeISQValues) {
                    if(currentRecordTypes == null || !currentRecordTypes.contains(recordType)) {
                        if(String.isBlank(currentRecordTypes)) {
                            currentRecordTypes += '!.!' + recordType + '!.!';
                        }
                        else {
                            // add the record type to the string
                            currentRecordTypes += recordType + '!.!';
                        }
                        // set the flag to true
                        changed = true;
                    }
                } else {
                    System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: removing from currentRecordTypes: '+currentRecordTypes);
                    if(currentRecordTypes == null || !currentRecordTypes.contains(recordType) || String.isBlank(currentRecordTypes)) continue;
                    List<String> seperatedRecTypes = currentRecordTypes.split('!.!');
                    System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: seperatedRecTypes: '+seperatedRecTypes);
                    Integer indexOfRecType = seperatedRecTypes.indexOf(recordType);
                    System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: indexOfRecType: '+indexOfRecType);
                    if (indexOfRecType != -1) {
                        seperatedRecTypes.remove(indexOfRecType);
                        currentRecordTypes = '!.!';
                        currentRecordTypes = String.Join(seperatedRecTypes, '!.!');
                        currentRecordTypes += '!.!';
                        changed = true;
                    }
                    System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: after update of val : currentRecordTypes'+currentRecordTypes);
                }
            }

            if(changed) {
                checklist.Industry_Record_Types__c = currentRecordTypes;
                checklistsToUpdate.put(checklist.Id,checklist);
            }
        }
        
        for (PEO_Onboarding_Checklist__c chk : checklistsToUpdate.values()) System.debug('WCQuestionnaireIndustrySpecificAfter.udpateChecklistIndSpecRecordTypes: chk after update: '+chk);
    }
    
    public void checkIfChecklistComplete(Id[] checklistIds,Map<Id,PEO_Onboarding_Checklist__c> checklistsToUpdate) {
        Set<id> checklistsWithIncompleteInd = new Set<id>(); 
        Set<id> checklistsWithAnyInd = new Set<id>(); 
        WC_Questionnaire_Industry_Specific__c[] allIndRecs = [SELECT Id,PEO_Underwriting_Checklist__c,Peo_IndSpecific_formStatus__c,Peo_IndSpecific_formSubmissionTime__c
                                                              	FROM WC_Questionnaire_Industry_Specific__c 
                                                                WHERE PEO_Underwriting_Checklist__c in :checklistIds];
        system.debug('allIndRecs'+allIndRecs);
        //query any industry specific not complete, only need one per checklist to know that checklist is not complete
        for(WC_Questionnaire_Industry_Specific__c indRec : allIndRecs){ 
            if(!checklistsWithAnyInd.contains(indRec.PEO_Underwriting_Checklist__c)){
                checklistsWithAnyInd.add(indRec.PEO_Underwriting_Checklist__c);
            }
            if(!checklistsWithIncompleteInd.contains(indRec.PEO_Underwriting_Checklist__c) && indRec.Peo_IndSpecific_formStatus__c!= 'Complete'){
                checklistsWithIncompleteInd.add(indRec.PEO_Underwriting_Checklist__c);                                                    
            } 
        }//for   
        //loop through checklists and if no incomplete industry specific records were found, update the record to complete
        for(Id checklistId:checklistIds){
            system.debug('hasIncomplete'+(checklistsWithIncompleteInd.contains(checklistId))+ ' hasAny'+(checklistsWithAnyInd.contains(checklistId)));
            if(!checklistsWithIncompleteInd.contains(checklistId) && checklistsWithAnyInd.contains(checklistId)){
                PEO_Onboarding_Checklist__c checklistToUpdate;
                if(checklistsToUpdate!=null && checklistsToUpdate.containsKey(checklistId)){
                    checklistToUpdate = checklistsToUpdate.get(checklistId);
                }
                else{
                    checklistToUpdate = new PEO_Onboarding_Checklist__c(Id=checklistId);
                }
                checklistToUpdate.Peo_IndSpecific_formStatus__c='Complete';
                checklistToUpdate.Peo_IndSpecific_formSubmissionTime__c=system.now();
                checklistsToUpdate.put(checklistToUpdate.Id,checklistToUpdate);
                
            }
            else{
                PEO_Onboarding_Checklist__c checklistToUpdate;
                if(checklistsToUpdate!=null && checklistsToUpdate.containsKey(checklistId)){
                    checklistToUpdate = checklistsToUpdate.get(checklistId);
                }
                else{
                    checklistToUpdate = new PEO_Onboarding_Checklist__c(Id=checklistId);
                }
                checklistToUpdate.Peo_IndSpecific_formStatus__c='';
                checklistToUpdate.Peo_IndSpecific_formSubmissionTime__c=null;
                checklistsToUpdate.put(checklistToUpdate.Id,checklistToUpdate);
            }
        }
        for (PEO_Onboarding_Checklist__c chk : checklistsToUpdate.values()) System.debug('WCQuestionnaireIndustrySpecificAfter.checkIfChecklistComplete: chk after update: '+chk);
    }
    
}