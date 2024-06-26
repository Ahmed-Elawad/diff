/*
* History
* -------------------------------
* 06/01/2021	Ahmed Elawad		Created
* 10/11/2021	Matt Fritschi		Set Discrepancy Category on insert. Populate Close Date when Status is Resolved.
*/

public class PEOUnderwritingDiscrepancyBefore implements TriggerInterfaceC {
    
    public Set<String> documentNames;
    
    // handle all trigger oparations
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('Made it to trigger handler: before ');
        if (documentNames == null) {
            documentNames = new Set<String>();
            Map<String, PEO_Onboarding_Document_Map__c> docNameMap = PEO_Onboarding_Document_Map__c.getAll();
            for (String name : docNameMap.keySet()) {
                documentNames.add(name);
            }
        }
        if (isBefore && recs != null && !recs.isEmpty()) {
            // handle all before actions
            handleAfterOperations(recs, oldMap);
        }
    }
    
    // determine if we need to populate a document lookup
    // and determine if we need to populate a medical lookup
    // on an update to the discrepancy type all previoud lookups other than the lookup to the correct
    // record type should be populated. 
    // EX: an update to a document needs to clear medical questionnaire lookup
    // an aupdate to a medical needs to clear Document lookups
    public void handleAfterOperations(SObject[] recs, Map<Id,SObject> oldMap) {
        // determine the kind of update that needs to be done       
        System.debug('discrepancyDocumentLookup');
        // create a map tracking the checklist to discrepancy list: checklistToDiscListMap
        // {xxxxxx1: [dics1, dics2]}
        Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> checklistToDiscMap = new Map<Id, List<Peo_Onboarding_Document_Discrepency__c>>();
        Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> documentToDiscrepancyMap = new Map<Id, List<Peo_Onboarding_Document_Discrepency__c>>();
        Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> checklistToDiscMapForMedical = new Map<Id, List<Peo_Onboarding_Document_Discrepency__c>>();
        Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> checklistToDiscMapForIndustry = new Map<Id, List<Peo_Onboarding_Document_Discrepency__c>>();
        // if the discrepnacy list isn't empty
        // iterate the discrepancies
        for (SObject rec : recs) {
            // if the current discrepancy needs a lookup populated
            // add it to the list for its related checklist  
            Peo_Onboarding_Document_Discrepency__c disc = (Peo_Onboarding_Document_Discrepency__c)rec;
            
            if (disc.Discrepancy_Type__c == 'Medical Questionnaire' && disc.PEO_Underwriting_Medical_Questionnaire__c == null) {
                disc.Discrepancy_Category__c = 'Medical';
                List<Peo_Onboarding_Document_Discrepency__c> discsPerChecklist = checklistToDiscMap.get(disc.PEO_Underwriting_Checklist__c);
                if (discsPerChecklist == null) {
                    discsPerChecklist = new List<Peo_Onboarding_Document_Discrepency__c>();
                }
                discsPerChecklist.add(disc);
                checklistToDiscMapForMedical.put(disc.PEO_Underwriting_Checklist__c, discsPerChecklist);
            }
            
            if (disc.Discrepancy_Type__c == 'Industry Specific Questionnaire' && disc.WC_Questionnaire_Industry_Specific__c == null) {
                disc.Discrepancy_Category__c = 'Risk';
                List<Peo_Onboarding_Document_Discrepency__c> discsPerChecklist = checklistToDiscMap.get(disc.PEO_Underwriting_Checklist__c);
                if (discsPerChecklist == null) {
                    discsPerChecklist = new List<Peo_Onboarding_Document_Discrepency__c>();
                }
                discsPerChecklist.add(disc);
                checklistToDiscMapForIndustry.put(disc.PEO_Underwriting_Checklist__c, discsPerChecklist);
            }
            
            System.debug('Discrepancy type: '+disc.Discrepancy_Type__c);
            if (checkForDocumentRelatedDisc(disc.Discrepancy_Type__c)) {
                List<Peo_Onboarding_Document_Discrepency__c> discsPerChecklist = checklistToDiscMap.get(disc.PEO_Underwriting_Checklist__c);
                if (discsPerChecklist == null) {
                    discsPerChecklist = new List<Peo_Onboarding_Document_Discrepency__c>();
                }
                discsPerChecklist.add(disc);
                checklistToDiscMap.put(disc.PEO_Underwriting_Checklist__c, discsPerChecklist);
            }
            
            //System.debug('MGF disc.PEO_Underwriting_Checklist__c='+disc.PEO_Underwriting_Checklist__c);
            if (disc.PEO_Underwriting_Checklist__c == null) {
                if(disc.Discrepancy_Category__c == null || disc.Discrepancy_Category__c == '') {
                    disc.Discrepancy_Category__c = 'Risk';
                }
                System.debug('Doc checklist lookup: ' + disc.PEO_Onboarding_Document__r.PEO_Onboarding_Checklist__c);
                List<Peo_Onboarding_Document_Discrepency__c> docDiscLst = documentToDiscrepancyMap.get(disc.PEO_Onboarding_Document__c);
                if (docDiscLst == null) {
                    docDiscLst = new List<Peo_Onboarding_Document_Discrepency__c>();
                }
                docDiscLst.add(disc);
                documentToDiscrepancyMap.put(disc.PEO_Onboarding_Document__c,docDiscLst);
            }
            
            if(disc.Status__c == 'Resolved' && disc.Close_Date__c == null) {
                disc.Close_Date__c = System.today();
            }
            
            if(disc.Discrepancy_Category__c == null || disc.Discrepancy_Category__c == '') {
                disc.Discrepancy_Category__c = 'Risk';
            }
        }
        
        if (!checklistToDiscMap.isEmpty()) {
            addDiscrepancyDocumentLookup(checklistToDiscMap);
        }
        
        if (!documentToDiscrepancyMap.isEmpty()) {
            addChecklistLookupToDiscrepancy(documentToDiscrepancyMap);
        }
        
        if (!checklistToDiscMapForMedical.isEmpty()) {
            addMedicalLookupToDiscrepancy(checklistToDiscMapForMedical);
        }
        if (!checklistToDiscMapForIndustry.isEmpty()) {
            addIndustryLookupToDiscrepancy(checklistToDiscMapForIndustry);
        }
    }
    
    public void addDiscrepancyDocumentLookup(Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> checklistToDiscMap) {
        // create a storage for all checklists
        // query for checklsits and their related documents checklsit id is in the checklistToDiscMap store in resultChecklistList
        // checklist: id, name, documents: [census(id, name), dec sheet(id name)]
        System.debug('Getting checklists: '+ checklistToDiscMap.keySet());
        PEO_Onboarding_Checklist__c[] checklists = [SELECT id, (SELECT Id, Name, Routing_Name__c FROM PEO_Onboarding_Documents__r) 
                                                    FROM PEO_Onboarding_Checklist__c 
                                                    WHERE id IN :checklistToDiscMap.keySet()];
        
        System.debug('Returned checklistst: '+ checklists);
        // iterate my result set in the resultChecklistList if it isn't empty
        if (!checklists.isEmpty()) {
            // outer loop to traverse ll the checklists we've returned
            for (PEO_Onboarding_Checklist__c currChklst : checklists) {
                // outer loop to iterate through all the discrepancies being insterted
                List<Peo_Onboarding_Document_Discrepency__c> discsForChklst = checklistToDiscMap.get(currChklst.Id);
                for (Peo_Onboarding_Document_Discrepency__c disc : discsForChklst) {
                    
                    // inner iterator to determine which document to use for a lookup
                    PEO_Onboarding_Document__c docForLookup;
                    for (PEO_Onboarding_Document__c doc : currChklst.PEO_Onboarding_Documents__r) {
                        Boolean foundMatch = false;
                        System.debug('disc.Discrepancy_Type__c: '+disc.Discrepancy_Type__c);
                        System.debug('disc.Discrepancy_Type__c = Health Insurance SBC/Plan Design');
                        System.debug(disc.Discrepancy_Type__c == 'Health Insurance SBC/Plan Design');
                        if (disc.Discrepancy_Type__c =='Health Insurance SBC/Plan Design') {
                            System.debug('Disct type is health insurance');
                            if (doc.Routing_Name__c == 'Benefit Summary') {
                                System.debug('Health insurance match');
                                docForLookup = doc;
                                foundMatch = true;
                            }
                        }
                        if (disc.Discrepancy_Type__c =='Health Invoice/PEO Medical Billing Report') {
                            System.debug('Disct type is Medical Invoice');
                            if (doc.Routing_Name__c == 'Medical Invoice') {
                                System.debug('Medical Invoice');
                                docForLookup = doc;
                                foundMatch = true;
                            }
                        }
                        if (disc.Discrepancy_Type__c =='SUI') {
                            System.debug('Disct type is SUI');
                            if (doc.Routing_Name__c == 'SUI Rate Forms') {
                                System.debug('SUI Rate Forms');
                                docForLookup = doc;
                                foundMatch = true;
                            }
                        }
                        if (disc.Discrepancy_Type__c =='Workers Comp Declarations Page') {
                            System.debug('Disct type is Workers Comp Declarations Page');
                            if (doc.Routing_Name__c == 'WC Declarations Page') {
                                System.debug('WC Declarations Page');
                                docForLookup = doc;
                                foundMatch = true;
                            }
                        }
                        if (disc.Discrepancy_Type__c =='Workers Comp Rates and Pricing') {
                            System.debug('Disct type is WC Rates and Pricing');
                            if (doc.Routing_Name__c == 'WC Rates and Pricing') {
                                System.debug('WC Rates and Pricing');
                                docForLookup = doc;
                                foundMatch = true;
                            }
                        }
                        
                        
						if (foundMatch) break;                        
                        if ((doc.Routing_Name__c == disc.Discrepancy_Type__c) || (doc.Name == disc.Discrepancy_Type__c)) {
                            docForLookup = doc;
                            break;
                        }
                    }
                    
                    if (docForLookup != null) {
                        System.debug('Updating lookup for disc: ' + docForLookup);
                        setDocumentDiscrepancyCategory(docForLookup.Routing_Name__c, disc);
                        disc.PEO_Onboarding_Document__c = docForLookup.Id;
                    }
                }
            }
        }
    }
    
    public void setDocumentDiscrepancyCategory(String routingName, Peo_Onboarding_Document_Discrepency__c disc) {
        PEO_Onboarding_Document_Map__c docMapping = PEO_Onboarding_Document_Map__c.getInstance(routingName);
        if(docMapping != null && docMapping.Document_Category__c != null) {
            if(docMapping.Document_Category__c == 'Medical') {
                disc.Discrepancy_Category__c = docMapping.Document_Category__c;
            }
            else if(docMapping.Document_Category__c == 'Risk') {
                disc.Discrepancy_Category__c = docMapping.Document_Category__c;
            }
        }
    }
    
    public void addChecklistLookupToDiscrepancy(Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> docToDiscLstMap) {
        // get all the documents with the lookups we need
        // for each document iterate the list and add the required lookups
        Peo_Onboarding_document__c[] docList = [SELECT Id, PEO_Onboarding_Checklist__c
                                                FROM Peo_Onboarding_document__c 
                                                WHERE Id IN :docToDiscLstMap.keySet()];
        
        for (Peo_Onboarding_document__c doc : docList) {
            List<Peo_Onboarding_Document_Discrepency__c> discList = docToDiscLstMap.get(doc.Id);
            for (Peo_Onboarding_Document_Discrepency__c disc : discList) {
                disc.PEO_Underwriting_Checklist__c = doc.PEO_Onboarding_Checklist__c;
            }
        }
    }
    
    public void addMedicalLookupToDiscrepancy(Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> docToDiscLstMap) {
        // get the medical checklist that looks up to the checklists
        // iterate the medical checklists
        // add a lookup to the medical record for each medical checklist
        System.debug('Matching medical questionnaires: '+ docToDiscLstMap);
        PEO_Onboarding_Medical_Questionnaire__c[] medicalQuestionnaires = [SELECT id, PEO_Onboarding_Checklist__c
                                                                           FROM PEO_Onboarding_Medical_Questionnaire__c 
                                                                           WHERE PEO_Onboarding_Checklist__c IN :docToDiscLstMap.keySet()];
        
        for (PEO_Onboarding_Medical_Questionnaire__c med : medicalQuestionnaires) {
            List<Peo_Onboarding_Document_Discrepency__c> discsForChklst = docToDiscLstMap.get(med.PEO_Onboarding_Checklist__c);
            for (Peo_Onboarding_Document_Discrepency__c disc : discsForChklst) {
                disc.PEO_Underwriting_Medical_Questionnaire__c = med.id;
            }
        }
    }
    public void addIndustryLookupToDiscrepancy(Map<Id, List<Peo_Onboarding_Document_Discrepency__c>> docToDiscLstMap) {
        // get the medical checklist that looks up to the checklists
        // iterate the medical checklists
        // add a lookup to the medical record for each medical checklist
        System.debug('Matching industry questionnaires: '+ docToDiscLstMap);
        WC_Questionnaire_Industry_Specific__c[] industryQuestionnaires = [SELECT id, PEO_Underwriting_Checklist__c
                                                                           FROM WC_Questionnaire_Industry_Specific__c 
                                                                           WHERE PEO_Underwriting_Checklist__c IN :docToDiscLstMap.keySet()];
        
        for (WC_Questionnaire_Industry_Specific__c wc : industryQuestionnaires) {
            List<Peo_Onboarding_Document_Discrepency__c> discsForChklst = docToDiscLstMap.get(wc.PEO_Underwriting_Checklist__c);
            for (Peo_Onboarding_Document_Discrepency__c disc : discsForChklst) {
                disc.WC_Questionnaire_Industry_Specific__c = wc.id;
            }
        }
    }
    
    public boolean checkForDocumentRelatedDisc(String discType) {
        if (discType == 'Health Insurance Summary of Benefits/Plan Designs') return true;
        if (discType == 'Census') return true;
        //if (discType == 'Other') return true;
        if (discType == 'Claims Information') return true;
        if (discType == 'Health Insurance Renewal') return true;
        if (discType == 'Health Insurance SBC/Plan Design') return true;
        if (discType == 'Health Invoice/PEO Medical Billing Report') return true;
        if (discType == 'Loss Runs') return true;
        if (discType == 'PEO Information Sheet') return true;
        if (discType == 'SUI') return true;
        if (discType == 'Workers Comp Declarations Page') return true;
        if (discType == 'Workers Comp Rates and Pricing') return true;
        return false;
    }
    
}