/* 
* Controller for the community summary component
*
* History
* -------
* 08/20/2021    Ahmed Elawad   	Created
* 12/22/2021	Jake Hinds		Removing opp references
* 30/05/2022 	Reetesh Pandey  Apex code scan resolution
*/

public without sharing class CommunitySummaryController {
    
    @AuraEnabled
    public static User getRunningUser() {
        User runningUser = UserHelper.getRunningUser();
        return runningUser;
    }
    
    @AuraEnabled
    public static Account[] getAccountInformation(String startingId, String formName) {
        try{
            // Apex code scan
            startingId = String.escapeSingleQuotes(startingId);
            Map<Id, Account[]> accounts =  communityMethods.getAccountInformation(new Set<Id>{startingId}, formName, 'CommunitiesAccountUpdateController');
            return accounts.get(startingId);   
        } catch(Exception e){
            throw new AuraHandledException('Could not retrieve Accounts. Please contact your administrator for support.');
        }
    }
    
    @AuraEnabled      
    public static CommunityMethods.IndustrySpecificWrap getIndustryDetails(String AccountId, String PEOchecklist,String formName) {
        return CommunityMethods.getIndustryDetails(String.escapeSingleQuotes(AccountId), PEOchecklist, formName, 'CommunitySummaryController');
    }
    
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,PEO_Onboarding_Checklist__c oldChecklist,String formName) {
        return CommunityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'CommunitySummaryController');
    }
    
    //Get the medical questionnaire
    @AuraEnabled
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaireForm(Id peoOnboardingChecklistId,String formName) {
        return CommunityMethods.getMedicalQuestionnaireForm(peoOnboardingChecklistId, formName, 'CommunitySummaryController');
    }
    
    @AuraEnabled
    public static string getIndustryStatus(String PEOchecklist) {
        // Apex code scan
        PEOchecklist = String.escapeSingleQuotes(PEOchecklist);
        String retVal =  CommunityMethods.getIndustrySpecificStatus(PEOchecklist);
        return retVal;
    }
    
    @AuraEnabled      
    public static Boolean needCovidQuestionnaire(Account parentAccount){
        Boolean covidQuestionnaireNeedeed = false;
        
        if(parentAccount.NAICS_Code__c != null) {
            List<WC_NAICS_To_Industry_Map__c> naics = [SELECT Id, Name, COVID_Questionnaire_Required__c FROM WC_NAICS_To_Industry_Map__c WHERE Name = :parentAccount.NAICS_Code__c];
            if(!naics.isEmpty() && naics.size() == 1 && naics[0].COVID_Questionnaire_Required__c) {
                covidQuestionnaireNeedeed=true;
            }
        }
        return covidQuestionnaireNeedeed;
    }
    
    @AuraEnabled  
    public static PEO_Onboarding_Document__c[] getAllPeoDocs(Id checkListId, Map<String, String> docNameSettingMap, String accountId, String formName){ 
        List<PEO_Onboarding_Document__c> queriedDocs = [SELECT Id, PEO_Onboarding_Checklist__c, Name, Status__c, Portal_Status__c,PEO_Doc_Required__c FROM 
                                                        PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c = :checkListId]; 
        
        Id parentAccId;
        List<PEO_Onboarding_Document__c> newDocs = new List<PEO_Onboarding_Document__c>();
        // Apex code scan
        accountId = String.escapeSingleQuotes(accountId);
        Account acc = [SELECT Id, isChild__c, isParent__c, SalesParent__c FROM Account WHERE Id=:accountId LIMIT 1];
        if (acc.isChild__c && acc.SalesParent__c != null) parentAccId = acc.SalesParent__c;
        
        Integer i = 0;
        for (String docName : docNameSettingMap.keySet()) {
            Boolean matchFound = false;
            for (PEO_Onboarding_Document__c d: queriedDocs) {
                if (d.Name == docName) {
                    matchFound = true;
                }
            }
            
            if (!matchFound) {
                PEO_Onboarding_Document__c newDoc = new PEO_Onboarding_Document__c(Name=docName, 
                                                                                   PEO_Onboarding_Checklist__c=checkListId, 
                                                                                   Routing_Name__c=docNameSettingMap.get(docName));
                if (parentAccId != null) newDoc.Parent_Account__c = parentAccId;
                newDocs.add(newDoc);
            }
            
        }
        
        if (!newDocs.isEmpty()) {
            try {
                insert newDocs;
            } catch(Exception e) {
                communityMethods.logCommunityError(e, 'getAllPeoDocs', 'CommunitySummaryController',formName, newDocs);
            }
            for (PEO_Onboarding_Document__c d : newDocs) {
                queriedDocs.add(d);
            }
        }
        
        return queriedDocs;
    }
    
    // for a list of document IDs and a map of objName to obj record ID gets the discrepancies associated and returns a map
    // of the discrepancies
    // @Return: 
    // {
    //  docDiscrepancies: [disc1, disc2, ...], <= discrepancies with a lookup to a PEO UW DOcument
    //  medical: [disc1, disc2, ...], <= discrepancies with a lookup to a medical UW record
    //  checklist: [disc1, disc2, ...] <= discrepancies with a lookup to the PEO UW Checklist(Forms and ans.)
    // }
    @AuraEnabled
    public static Map<String, PEO_Onboarding_Document_Discrepency__c[]> getDiscrepancies(List<String> docList, Map<String, String> checklistIds) {
        Map<String, PEO_Onboarding_Document_Discrepency__c[]> retVal = new Map<String, PEO_Onboarding_Document_Discrepency__c[]>();
        PEO_Onboarding_Document_Discrepency__c[] docDiscrepancies;
        
        // get the discrepancies for documents
        if (docList != null) {
            docDiscrepancies = CommunitySummaryController.getDisrepenciesForDoc(docList);
            //System.debug('Chekc Prospect Comments '+docDiscrepancies[0].Prospect_Comments__c);
        }
        
        // get discrepancies for checlists: Medical UW and PEO UW
        // adds any returned values to retVal: obj: listOfDiscs
        // EX: checklist: [disc1, disc2, ...]
        if (checklistIds != null) {
            Map<String, PEO_Onboarding_Document_Discrepency__c[]> checklsitPlaceholder = new Map<String, PEO_Onboarding_Document_Discrepency__c[]>();
            checklsitPlaceholder = CommunitySummaryController.getChecklistDiscrepancies(checklistIds);
            if (checklsitPlaceholder.get('Checklist') != null) {
                retVal.put('checklist', checklsitPlaceholder.get('Checklist'));
            }
            if (checklsitPlaceholder.get('Medical') != null) {
                retVal.put('Medical', checklsitPlaceholder.get('Medical'));
            }
            
        }
        if (docDiscrepancies != null) retVal.put('docDiscrepancies', docDiscrepancies);
        return retVal;
    }
    
    //"Class.CommunitiesAccountUpdateController.getDisrepenciesForDoc: line 469, column 1"
    @AuraEnabled
    public static PEO_Onboarding_Document_Discrepency__c[] getDisrepenciesForDoc(List<String> docList) {
        //SFDC-15863 added Comment_Log__c by Rohith
        String query = 'SELECT Name,Status__c, Prospect_Comments__c, additional_information__c, Comment_Log__c, PEO_Onboarding_Document__c, Discrepancy_Type__c, Discrepancy_Sub_Type__c, Discrepancy_ID__c FROM PEO_Onboarding_Document_Discrepency__c WHERE Status__c != \'Resolved\' AND PEO_Onboarding_Document__c IN ';
        String docIdList = '(';
        
        for (String id : docList) {
            id= String.escapeSingleQuotes(id);
            docIdList+= '\'' + id +  '\',';
        }
        
        docIdList = docIdList.removeEnd(',');
        docIdList = docIdList + ')';
        query+=docIdList;        
        PEO_Onboarding_Document_Discrepency__c[] recs = Database.query(query);        
        return recs;
    }
    
     public static Map<String, PEO_Onboarding_Document_Discrepency__c[]> getChecklistDiscrepancies(Map<String, String> checklistsToIDMap) {
        Map<String, PEO_Onboarding_Document_Discrepency__c[]> retVal = new Map<String, PEO_Onboarding_Document_Discrepency__c[]>();
        PEO_Onboarding_Document_Discrepency__c[] medicalDiscrepancies;
        PEO_Onboarding_Document_Discrepency__c[] checklstDiscrepancies;
        //Do we really need this query?
        //MedQ is not used anymore
        //this can be removed
        /*if (checklistsToIdMap.get('Medical') != null) medicalDiscrepancies = [SELECT Id, Name,Status__c, 
                                                                              Prospect_Comments__c, additional_information__c, 
                                                                              PEO_Onboarding_Document__c, Discrepancy_Type__c, 
                                                                              Discrepancy_Sub_Type__c, Discrepancy_ID__c,
                                                                              PEO_Underwriting_Medical_Questionnaire__c
                                                                              FROM PEO_Onboarding_Document_Discrepency__c 
                                                                              WHERE PEO_Underwriting_Medical_Questionnaire__c=:checklistsToIDMap.get('Medical')
                                                                              AND Status__c!='Resolved'
                                                                              AND PEO_Onboarding_Document__c = ''];*/
        //this can be modified
        if (checklistsToIdMap.get('Checklist') != null) checklstDiscrepancies = [SELECT Id, Name, Status__c, 
                                                                                 Prospect_Comments__c, additional_information__c, 
                                                                                 PEO_Onboarding_Document__c, Discrepancy_Type__c, 
                                                                                 Discrepancy_Sub_Type__c, Discrepancy_ID__c,
                                                                                 PEO_Underwriting_Medical_Questionnaire__c
                                                                                 FROM PEO_Onboarding_Document_Discrepency__c 
                                                                                 WHERE PEO_Underwriting_Checklist__c=:checklistsToIDMap.get('Checklist')
                                                                                 //AND (PEO_Underwriting_Medical_Questionnaire__c!=:checklistsToIDMap.get('Medical') OR PEO_Underwriting_Medical_Questionnaire__c = '') 
                                                                                 AND Status__c!='Resolved'
                                                                                 AND PEO_Onboarding_Document__c = ''];
        system.debug('medicalDiscrepancies:'+medicalDiscrepancies);
        system.debug('checklstDiscrepancies:'+checklstDiscrepancies);
        /*if (medicalDiscrepancies != null && !medicalDiscrepancies.isEmpty()) {
            retVal.put('Medical', medicalDiscrepancies);
        }*/
        if (checklstDiscrepancies != null && !checklstDiscrepancies.isEmpty()) {
            retVal.put('Checklist', checklstDiscrepancies);
        } 
        return retVal;
    }
    
    @AuraEnabled
    public static Id updateDisc(Map<String, String> disc, String formName) {
        PEO_Onboarding_Document_Discrepency__c rec = [SELECT id,Name, Prospect_Comments__c,PEO_Underwriting_Checklist__c,PEO_Underwriting_Checklist__r.Sales_Analyst__r.Id,PEO_Underwriting_Checklist__r.Sales_Rep__r.Id,PEO_Underwriting_Checklist__r.Sales_Rep__r.Name FROM PEO_Onboarding_Document_Discrepency__c WHERE id=:disc.get('Id')];
        System.debug('Check The Comments '+disc.get('Prospect_Comments__c'));
        if (disc.get('Prospect_Comments__c') != null) {
            System.debug('inside if');
            rec.Prospect_Comments__c = disc.get('Prospect_Comments__c');
        }
        if (disc.get('additional_information__c') != null) rec.additional_information__c = disc.get('additional_information__c');
        //SFDC-15863 Rohith 
       List<Id> mentionId = new List<Id>();
        if(!Test.isRunningTest()){
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
            
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            mentionId.add(rec.PEO_Underwriting_Checklist__r.Sales_Analyst__r.Id);
            //mentionId.add(rec.PEO_Underwriting_Checklist__r.Sales_Rep__r.Id);
            for(Id mention : mentionId){
                mentionSegmentInput.id = mention;
                // messageBodyInput.messageSegments.add(mentionSegmentInput);
            }
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            
            textSegmentInput.text = ' '+ rec.PEO_Underwriting_Checklist__r.Sales_Rep__r.Name+' has entered comments for '+rec.Name+'. Please review the information and update the discrepancy as needed.\n\n Comments:\n';
            textSegmentInput.text =textSegmentInput.text + disc.get('Prospect_Comments__c')+'\n\nDiscrepancy :\n'+ URL.getSalesforceBaseUrl().toExternalForm()+'/'+ disc.get('Id');
            
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = rec.PEO_Underwriting_Checklist__c;
            
            
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
        //System.debug(' Post Added '+post);
        //SFDC-15863 Rohith 
      //  ChatterMentionPost.createChatterMentionPost(rec.PEO_Underwriting_Checklist__c,mentionId)
        try{
            update rec;
        } catch(Exception e) {
            communityMethods.logCommunityError(e, 'updateDisc', 'CommunitySummaryController',formName, new List<PEO_Onboarding_Document_Discrepency__c>{rec});
        }
        return rec.Id;
    }
    
}