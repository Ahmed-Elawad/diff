/* 
* Controller for the community FileUpload component
*
* History
* -------
* 08/20/2021    Ahmed Elawad   Created
* 12/17/2021	Jake Hinds		Changing RR to use the district/sales org of sales rep instead of running user
* 5/20/2022   Srujan Kumar  Chnaged the logic to assign the default queue if the there is no queue assigned to sales rep
* 5/25/2022   Rohith Ramini  Chnaged the logic to assign the Testing queue if Route to Testing Queue is checked on Checklist record
* 09/29/2023  Jidesh		Updated getPEOchecklistDetails method by adding more fields to SOQL
* 10/05/2023  Jidesh		Updated getPEOchecklistDetails to use field sets to build SOQL
*/
 
public without sharing class CommunityFileUploadController {
    
    @AuraEnabled  
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, string formName){ 
        User runningUser = Userhelper.getRunningUser();
        // get the current local time
        Datetime current = System.now(); 
        Date currDate = current.date();
        Time currTime = current.time();
        Datetime local = datetime.newinstance(currDate,currTime);
        
        // update the submission timestamps if they've been provided on the checklist
        if(peoOnbChecklist.Peo_401k_formStatus__c == 'Complete' && peoOnbChecklist.Peo_401k_SubmissionTime__c == null) peoOnbChecklist.Peo_401k_SubmissionTime__c = local;
        if(peoOnbChecklist.Peo_EPLI_formStatus__c == 'Complete' && peoOnbChecklist.Peo_EPLI_SubmissionTime__c == null) peoOnbChecklist.Peo_EPLI_SubmissionTime__c = local;
        if(peoOnbChecklist.Peo_Covid_formStatus__c == 'Complete' && peoOnbChecklist.Peo_Covid_formSubmissionTime__c == null) peoOnbChecklist.Peo_Covid_formSubmissionTime__c = local;
        if(peoOnbChecklist.Peo_WC_formStatus__c == 'Complete' && peoOnbChecklist.Peo_WC_SubmissionTime__c == null) peoOnbChecklist.Peo_WC_SubmissionTime__c = local;
        
        String codeKey = 'By '+ runningUser.name + ' on form ' + formName;
        List<PEO_Onboarding_Checklist__c> checcklistsToSave = new List<PEO_Onboarding_Checklist__c>{peoOnbChecklist};
            return DMLHelper.performDML2(checcklistsToSave,DmlHelper.DML_UPDATE,'CommunityFileUploadController','savePeoOnboardingChecklist',codeKey,true);   
    }
    
    @AuraEnabled      
    public static CommunityMethods.IndustrySpecificWrap getIndDetails(String PEOchecklist, String peoIndustryTitle, String formName){
        return CommunityMethods.getIndustryDetails(PEOchecklist, peoIndustryTitle, formName, 'CommunityIndustrySpecificController');
    }
    
    @AuraEnabled
    public static List<PEO_Onboarding_Checklist__c> getPEOchecklists(List<Account> allAccounts){
         List<PEO_Onboarding_Checklist__c> checkLists = [SELECT Id, Company_Info_About_Your_Business_Form__c, Company_Info_Addt_Details_Form__c,
                                                        Total_Number_of_Employees__c,
                                                        Ownership_Structure__c,
                                                        Platform__c,
                                                        Currently_using_a_PEO__c,
                                                        Current_PEO_Provider__c,
                                                        Previous_Paychex_PEO_Oasis_HROI_client__c,
                                                        Medical_Carriers_currently_in_use__c,
                                                        Is_Your_Plan_Self_Funded_or_Level_Funded__c,
                                                        Is_Medical_Underwriting_Requested__c,
                                                        medical_coverage_renewal_date__c,
                                                        Benefit_Effective_Date__c,
                                                        Headquarter_State__c,
                                                        state_with_most_employees__c,
                                                        description_principle_product_business__c,
                                                        had_wrkrs_comp_claim_past_3_yrs__c,
                                                        Prospect_Client__r.Name,
                                                        Prospect_Client__r.DBA__c,
                                                        Prospect_Client__r.Federal_ID_Number__c,
                                                        Prospect_Client__r.Phone,
                                                        Prospect_Client__r.ShippingStreet,
                                                        Prospect_Client__r.ShippingCity,
                                                        Prospect_Client__r.ShippingState,
                                                        Prospect_Client__r.ShippingPostalCode,
                                                        Prospect_Client__r.NAICS_Code__c,
                                                        Prospect_Client__r.SalesParent__c,
                                                        Prospect_Client__r.isParent__c,
                                                        Prospect_Client__r.Website,
                                                        Client_Add_on__c
                                                        FROM PEO_Onboarding_Checklist__c
                                                        WHERE  Prospect_Client__c IN: allAccounts];
        return checkLists;
    }
    
    @AuraEnabled
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaireForm(Id peoOnboardingChecklistId, String formName) {
        return CommunityMethods.getMedicalQuestionnaireForm(peoOnboardingChecklistId, formName, 'CommunityFileUploadController');
    }
    
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,Id oppId,PEO_Onboarding_Checklist__c oldChecklist, String formName) {
        return CommunityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'CommunityFileUploadController');
    }
    
    @AuraEnabled
    public static Boolean submitForReview(PEO_Onboarding_Checklist__c parentOnbChecklist, User currentUser, User strategicAccountPartner, String formName) {
        System.debug('MGF CommunitiesAccountUpdateController submitDocumentsForReview currentUser.District__c = ' + currentUser.District__c);
        //Donot change the owner if document is already submitted :start 
        //	Sales_Analyst__c-->NBSC
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        
        if (parentOnbChecklist.Prospect_Client__c != null) {
        	ClientSpaceHelper.checkLocationsForAccount(new Set<Id>{parentOnbChecklist.Prospect_Client__c});
        }
        
        List<PEO_Onboarding_Checklist__c> peoChecklist = getSubmissionStatus(parentOnbChecklist.Id);    
        parentOnbChecklist.Current_Step__c = 'New Submission';
        User salesRep = [SELECT Id,District__c,Sales_Org__c,Rep_Type__c,Dedicated_NBSC__c
                         FROM User WHERE Id = :parentOnbChecklist.Sales_Rep__c AND IsActive = true LIMIT 1];
        system.debug ('JC CFUC salesRep.District__c ' + salesRep.District__c + 'submission status ' + peoChecklist[0].PEO_Checklist_submission_status__c); 
        system.debug ('JC CFUC salesRep.id ' + salesRep.id);
        if (parentOnbChecklist.New_Submission_Status_Date__c == null) parentOnbChecklist.New_Submission_Status_Date__c = system.now();
        if(peoChecklist[0].PEO_Checklist_submission_status__c == 'Submitted' && peoChecklist[0].OwnerId != null){   
            parentOnbChecklist.OwnerId = peoChecklist[0].OwnerId;   
            try {
                return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
            }catch(Exception e) {
                communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
            }
        }
        //Find all possible Queues for Sales Analyst assignment using the custom setting.
        
        if(strategicAccountPartner != null) {
            System.debug('MGF CommunitiesAccountUpdateController submitDocumentsForReview strategicAccountPartner = ' + strategicAccountPartner);
            parentOnbChecklist.OwnerId = strategicAccountPartner.Id;
            parentOnbChecklist.PEO_Checklist_submission_status__c = 'Submitted';
            parentOnbChecklist.Sales_Analyst__c = strategicAccountPartner.Id;
            try {
                return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
            }catch(Exception e) {
                System.debug(' Catch 1');
                communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
            }
        }
        else if(salesRep!=null){
            system.debug ('JC CFUC SalesRep !=null  ' +salesRep!=null); 

            List<PEO_Edge_Queue_Districts__c> possibleQueues = PEO_Edge_Queue_Districts__c.getAll().values();
            List<Group> foundQueue;
            String queueName = '';
            //SFDC-13613 APR0135284: Dummy submission queues-Rohith-Start
            if(parentOnbChecklist.Route_to_Testing_Queue__c){
                system.debug ('JC CFUC parentOnbChecklist.Route_to_Testing_Queue__c  '+ parentOnbChecklist.Route_to_Testing_Queue__c); 
                PEO_Edge_Queue_Districts__c testingQueue = PEO_Edge_Queue_Districts__c.getValues('Testing');
                
                if(testingQueue.Name != null){
                    foundQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = :testingQueue.Name LIMIT 1];
                    System.debug('Queue found '+foundQueue);
                }
                system.debug ('JC CFUC foundQueue != null  '+ foundQueue !=null);                 
                if(foundQueue != null && !foundQueue.isEmpty() && foundQueue.size() == 1) {
                system.debug ('JC CFUC foundQueue  '+ foundQueue );                                
                    parentOnbChecklist.OwnerId = foundQueue[0].Id;
                    parentOnbChecklist.PEO_Checklist_submission_status__c = 'Submitted';
                    
                }
                
               try {
                	return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
                }catch(Exception e) {
                    System.debug(' Catch 2');
                    communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
                }
                
            }
            else if(salesRep.Dedicated_NBSC__c!=null){
               
                parentOnbChecklist.OwnerId = salesRep.Dedicated_NBSC__c;
                parentOnbChecklist.PEO_Checklist_submission_status__c = 'Submitted';
                parentOnbChecklist.Sales_Analyst__c = salesRep.Dedicated_NBSC__c;
                parentOnbChecklist.Analyst_Queue__c = system.now(); 
                parentOnbChecklist.Analyst_Queue_Name__c ='Qualifier';                    
                
                try {
                	return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
                }catch(Exception e) {
                    System.debug(' Catch 2');
                    communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
                }
            }
            else if(salesRep.Rep_Type__c == 'High Velocity Rep'){
                System.debug('Inside High Velocity Rep');
                 PEO_Edge_Queue_Districts__c qualifierQueue = PEO_Edge_Queue_Districts__c.getValues('Qualifier');
               system.debug ('JC CFUC qualifierQueue.Name != null  ' +qualifierQueue.Name != null );     
                if(qualifierQueue.Name != null){
                    foundQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = :qualifierQueue.Name LIMIT 1];
                    System.debug('Queue found '+foundQueue);
                }
                system.debug ('JC CFUCfoundQueue != null2  ' +foundQueue != null );
                if(foundQueue != null && !foundQueue.isEmpty() && foundQueue.size() == 1) {
                     system.debug ('JC CFUCfoundQueue 2  ' +foundQueue);
                    parentOnbChecklist.OwnerId = foundQueue[0].Id;
                    parentOnbChecklist.PEO_Checklist_submission_status__c = 'Submitted';
                    
                }
                try {
                    return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
                }catch(Exception e) {
                    communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
                }
            }
            else{
                system.debug ('JC CFUC inside else  ' );
                //SFDC-13613 APR0135284: Dummy submission queues-Rohith-End  
                List<PEO_Edge_Queue_Districts__c> defaultQueue = new List<PEO_Edge_Queue_Districts__c>();
                for(PEO_Edge_Queue_Districts__c queue: possibleQueues){
                    if(queue.Default_Queue__c){
                        system.debug ('JC CFUC inside default  ' );
                        defaultQueue.add(queue);
                    }
                }
                Boolean queueAssigned = false;
                for(PEO_Edge_Queue_Districts__c queue : possibleQueues) {
                    if(queue.Districts__c != null /* && queue.Sales_Org__c != null*/) {//Commented as a part of SFDC-14633 Rohith
                        System.debug('MGF CommunitiesAccountUpdateController submitDocumentsForReview queue='+queue);
                        //if(queue.Sales_Org__c == salesRep.Sales_Org__c) { Commented as a part of SFDC-14633 Rohith
                            List<String> possibleDistricts = queue.Districts__c.split(',');

                            if(!String.isEmpty(salesRep.District__c) && possibleDistricts.contains(String.valueOf(integer.valueOf(salesRep.District__c)))) {
                                queueName = queue.Name;
                                queueAssigned = true;
                                system.debug ('JC CFUC inside possiblequeues   ' );
                                System.debug('Successfully found Queue: ' + queueName);
                                break;
                            }
                        //}
                        
                    }
                }
                if(!queueAssigned && defaultQueue.size() > 0){
                    for(PEO_Edge_Queue_Districts__c myQueue: defaultQueue){
                       // if(salesRep.Sales_Org__c == myQueue.Sales_Org__c){ Commented as a part of SFDC-14633 Rohit
                       // system.debug ('JC CFUC inside possiblequeues   ' );
                            queueName = myQueue.Name;
                        System.debug('JC CFUC queueName: ' + queueName);
                        //}
                    }
                }
                
                //If a queue name has been found for this account, query for it.
                if(String.isNotBlank(queueName)) {
                    //assign to the found queue.
                    foundQueue = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND NAME = :queueName LIMIT 1];
                    System.debug('JC CFUC foundQueue: ' +foundQueue);
                }                    
                
                //Set the owner of all Documents to be the retrieved queue and update the documents.
                if(foundQueue != null && !foundQueue.isEmpty() && foundQueue.size() == 1) {
                    parentOnbChecklist.OwnerId = foundQueue[0].Id;
                    System.debug('Successfully routed to Queue: ' + foundQueue[0].Name);
                    //Update the submission status* 
                    parentOnbChecklist.PEO_Checklist_submission_status__c = 'Submitted';
                    try {
                        return DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist},DmlHelper.DML_UPDATE,'CommunityFileUploadController','submitForReview',codeKey,true);
                    }catch(Exception e) {
                        communityMethods.logCommunityError(e, 'submitForReview', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Checklist__c>{parentOnbChecklist});
                    }
                }
            }
        }
        
        return false;
    }
    
    // Save the account record
    // Update the CS location data if the updated account is a child in a multi ID
    // Returns the account that was updated without re-querying
     @AuraEnabled  
    public static Account saveThisAccount(Account acct, String formName){ 
        System.debug('Updating acct...');
        // handle the type conversion for the recieved acct record
        Integer numofEmps = acct.NumberOfEmployees;
        acct.NumberOfEmployees = numofEmps;
        update acct;
        String[] fldList = new String[]{};
            Schema.FieldSet oppFldSet = Schema.SObjectType.Account.fieldSets.PEO_Edge_Form_Fields;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        String queryString = 'SELECT '
            + String.join(fldList,',') 
            +' FROM Account WHERE Id = \''+ acct.Id + '\' LIMIT 1';
        return Database.query(queryString);
    }
    
    @AuraEnabled      
    public static List<PEO_Onboarding_Checklist__c> getSubmissionStatus(Id peoFullChecklistId){
        
        List<PEO_Onboarding_Checklist__c> checklistDetails = [SELECT Id,Owner.Name,Sales_Analyst__r.Name,PEO_Checklist_submission_status__c,New_Submission_Status_Date__c, Current_Step__c
                                                              FROM PEO_Onboarding_Checklist__c WHERE Id =: peoFullChecklistId limit 1];
        //system.debug('checklistDetails:'+checklistDetails);
        return checklistDetails;
    }
    @AuraEnabled      
    public static void submitDocsToClientSpaceAll(Id checkListId, Boolean isQQWC){
        
        PEO_Onboarding_Checklist__c obc = [Select Id, WC_Only_Submission_Date__c from PEO_Onboarding_Checklist__c where Id=:checkListId];
        
        if(isQQWC ){
            if(obc.WC_Only_Submission_Date__c==null)
            	obc.WC_Only_Submission_Date__c=system.now();
        }
        else
        	obc.Submit_Docs_to_Clientspace__c = 'All';
        update obc;
    }
    
    @AuraEnabled
    public static User getStrategicAccountPartner(Account parentAccount) { 
        User strategicAccountPartner = null;
        if(parentAccount != null && parentAccount.Referral_National_Account__c != null) {
            Referral_Account__c strategicAccount = [SELECT Id, Name, NBSC_SA_Partner__c, Parent_Referral_Account__c, Parent_Referral_Account__r.NBSC_SA_Partner__c FROM Referral_Account__c WHERE Id = :parentAccount.Referral_National_Account__c LIMIT 1];
            if(strategicAccount != null) {
                if(strategicAccount.Parent_Referral_Account__c != null && strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c != null) {
                    strategicAccountPartner = [SELECT Id, Name FROM User WHERE Id = :strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c];
                }else if(strategicAccount.NBSC_SA_Partner__c != null) {
                    strategicAccountPartner = [SELECT Id, Name FROM User WHERE Id = :strategicAccount.NBSC_SA_Partner__c];
                }
            }
        }
        
        return strategicAccountPartner;
    }
    
    @AuraEnabled  
    public static PEO_Onboarding_Checklist__c  getPEOchecklistDetails(Id accountId){
        System.debug('CommunityFileUploadController getPEOchecklistDetails Account ID: '+accountId);
        String[] fldList = new String[]{};
            Schema.FieldSet chkFldSet = Schema.SObjectType.PEO_Onboarding_Checklist__c.fieldSets.Questionnaire_Fields;
        for (Schema.FieldSetMember fsm : chkFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        String queryString = 'SELECT '
            + String.join(fldList,',') 
            +' FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = \''+ String.escapeSingleQuotes(accountId) + '\' ORDER BY CreatedDate ASC LIMIT 1';
        List<PEO_Onboarding_Checklist__c> onbChecklist = new List<PEO_Onboarding_Checklist__c>();     
        onbChecklist = Database.query(queryString);
        if(onbChecklist.isEmpty()){
            return null;
        } 
        else{
            return onbChecklist[0];
        }
    }
    
    @AuraEnabled 
    public static List<PEO_Onboarding_Document__c> getPEOOnboardingDocs(String recordId){
        return  [SELECT Id, PEO_Onboarding_Checklist__c, Name, Routing_Name__c,Status__c, Parent_Account__c,PEO_Doc_Required__c FROM 
          PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c = :recordId];                        
    }
    
    @AuraEnabled  
    public static Id getPEODocument(String recordId, String docName,String customSettingName, String accountId, String formName){ 
        List<PEO_Onboarding_Document__c> peoOnboardingDocumentList = [SELECT Id, PEO_Onboarding_Checklist__c, Name, Routing_Name__c,Status__c, Parent_Account__c FROM 
                                                                      PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c = :recordId AND Name=:docName];                         
        
        PEO_Onboarding_Document__c peoOnboardingDocument;
        Account acc = [SELECT Id, isChild__c, isParent__c, SalesParent__c FROM Account WHERE Id=:accountId LIMIT 1];
        
        if(!peoOnboardingDocumentList.isEmpty()) {
            peoOnboardingDocument=peoOnboardingDocumentList[0];
            if (acc.isChild__c && acc.SalesParent__c != null && peoOnboardingDocument.Parent_Account__c == null) {
                peoOnboardingDocument.Parent_Account__c = acc.SalesParent__c;
                try {
                    update peoOnboardingDocument;   
                }catch(Exception e) {
                    communityMethods.logCommunityError(e, 'getPEODocument', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Document__c>{peoOnboardingDocument});
                }
            }
        } else if(recordId!= null) {
            peoOnboardingDocument = new PEO_Onboarding_Document__c(Name=docName, PEO_Onboarding_Checklist__c=recordId, Routing_Name__c=customSettingName);
            if (acc.isChild__c && acc.SalesParent__c != null) peoOnboardingDocument.Parent_Account__c = acc.SalesParent__c;
            try {
                insert peoOnboardingDocument;
            }catch(Exception e) {
                communityMethods.logCommunityError(e, 'getPEODocument', 'CommunityFileUploadController',formName, new List<PEO_Onboarding_Document__c>{peoOnboardingDocument});
            }
        }
        return peoOnboardingDocument.Id;      
    }
    
    @AuraEnabled
    public static void UpdatePEOCheckListData(String accountId, PEO_Onboarding_Checklist__c PEOCheckListData){
        system.debug('accountId: ' + accountId);
         system.debug('New: ' + PEOCheckListData);
         PEO_Onboarding_Checklist__c PEOCdata = [SELECT Id,Name,Sales_Rep__c,Discrepancy_Communication_Method__c,PEO_Medical_Pre_Qualifier__c,
                                                PEO_Sales_Notes__c,Financial_Underwriting_Sales_Notes__c,Workers_Comp_Sales_Notes__c,
                                                Pricing_Console_Notes__c,Prospect_Client__r.Name,Route_to_Testing_Queue__c
                                                FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c =:accountId limit 1];
                    
       PEOCdata.PEO_Sales_Notes__c = PEOCheckListData.PEO_Sales_Notes__c;
        PEOCdata.Workers_Comp_Sales_Notes__c = PEOCheckListData.Workers_Comp_Sales_Notes__c;
        PEOCdata.Financial_Underwriting_Sales_Notes__c = PEOCheckListData.Financial_Underwriting_Sales_Notes__c;
        PEOCdata.Pricing_Console_Notes__c = PEOCheckListData.Pricing_Console_Notes__c;
            Update PEOCdata;
    }
    
    @AuraEnabled
    public static Boolean getPEODocumentDetails(Id checklistId){
        Boolean allDocsUploaded = false;
        List<PEO_Onboarding_Document__c> docs = new List<PEO_Onboarding_Document__c>();
        docs = [SELECT Id, Name FROM PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c =: checklistId AND PEO_Doc_Required__c = 'Needed'];
        if(docs.size() > 0){
            System.debug('getPEODocumentDetails docs:'+docs);
            Set<Id> docId = new Set<Id>();
            for(PEO_Onboarding_Document__c doc : docs){
                docId.add(doc.Id);
            }
            Map<String, ContentDocumentLink> mapCDL = new Map<String, ContentDocumentLink>();
            List<ContentDocumentLink> contentDocLink = new List<ContentDocumentLink>();
            contentDocLink = [SELECT id, LinkedEntity.name FROM ContentDocumentLink  WHERE LinkedEntityId IN : docId];
            if(contentDocLink.size() > 0){
                System.debug('getPEODocumentDetails contentDocLink:'+contentDocLink);
                for(ContentDocumentLink cdl : contentDocLink){
                    mapCDL.put(cdl.LinkedEntity.name, cdl);
                }
                System.debug('getPEODocumentDetails mapCDL:'+mapCDL);
                Boolean exist = true;
                for(PEO_Onboarding_Document__c doc : docs){
                    if(mapCDL.get(doc.Name) == NULL){
                        System.debug('getPEODocumentDetails doc doesnt exist:'+doc.Name);
                        exist = false;
                    }
                }
                allDocsUploaded = exist;
            }
            
        }else{
            allDocsUploaded = true;
        }
        
        return allDocsUploaded;
    }
    
    @AuraEnabled  
    public static List<ContentDocument> getFiles(String recordId){ 
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, ShareType FROM 
                                             ContentDocumentLink WHERE LinkedEntityId = :recordId];
        
        List<Id> documentIds = new List<Id>(); 
        for(ContentDocumentLink cdl:cdlList){  
            documentIds.add(cdl.ContentDocumentId);  
        }
        
        if(!documentIds.isEmpty())
        {
            List<Contentversion> unsubmittedContentVersions = new List<Contentversion>([SELECT Id, PEO_Doc_Submitted__c, ContentDocumentId FROM ContentVersion where ContentDocumentId IN :documentIds]);
            
            documentIds.clear();
            for(Contentversion cv : unsubmittedContentVersions){  
                documentIds.add(cv.ContentDocumentId);  
            }
        }
        
        return [SELECT Id, Title, FileType, CreatedDate FROM ContentDocument WHERE Id IN :documentIds ORDER BY CreatedDate DESC];
    } 
    
    @AuraEnabled  
     public static void deleteFile(String contentDocumentId, String peoChecklistID, String settingName, String formName){ 
        try {
            delete [SELECT Id from ContentDocument WHERE Id = :contentDocumentId];      
        }catch(Exception e) {
            List<ContentDocument> lst = [SELECT Id from ContentDocument WHERE Id = :contentDocumentId];
            communityMethods.logCommunityError(e, 'deleteFile', 'CommunityFileUploadController',formName, lst);
        }
        
        //Added to change the document status on delete
        List<PEO_Onboarding_Document__c> peoOnboardingDocumentList = [SELECT Id, PEO_Onboarding_Checklist__c, Name, Routing_Name__c,Status__c, Parent_Account__c FROM 
                                                                      PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c = :peoChecklistID AND Routing_Name__c=:settingName];                         
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId, Visibility, ShareType FROM 
                                             ContentDocumentLink WHERE LinkedEntityId = :peoOnboardingDocumentList[0].Id];
        List<Id> documentIds = new List<Id>(); 
        for(ContentDocumentLink cdl:cdlList)documentIds.add(cdl.ContentDocumentId);                                              
        if(documentIds.isEmpty())peoOnboardingDocumentList[0].Status__c = '';
        try {
            update peoOnboardingDocumentList;
        }catch(Exception e) {
            communityMethods.logCommunityError(e, 'deleteFile', 'CommunityFileUploadController',formName, peoOnboardingDocumentList);
        }
    }
    
    @AuraEnabled  
     public static void saveFiles(String PEOOnboardingDocId, String formName){ 
        if(String.isNotBlank(PEOOnboardingDocId)) {
            Map<Id, ContentDocumentLink> contentDocumentLinks = new Map<Id, ContentDocumentLink>([SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink where LinkedEntityId = :PEOOnboardingDocId]);
            if(!contentDocumentLinks.isEmpty()) {
                List<Id> contentDocumentIdList = new List<Id>();
                for(ContentDocumentLink cdl : contentDocumentLinks.values()) {
                    contentDocumentIdList.add(cdl.ContentDocumentId);
                }
                
                List<ContentVersion> contentVersionsToBeSubmitted = new List<ContentVersion>([SELECT Id, Title, PEO_Doc_Submitted__c, ContentDocumentId FROM ContentVersion where ContentDocumentId IN :contentDocumentIdList AND PEO_Doc_Submitted__c = false]);
                if(!contentVersionsToBeSubmitted.isEmpty()) {
                    for(ContentVersion cv : contentVersionsToBeSubmitted) {
                        cv.PEO_Doc_Submitted__c = true;
                    }
                    
                        update contentVersionsToBeSubmitted;
                }
                
            }
        }
        
    }
    
    @AuraEnabled  
    public static List<ContentDocument> getSubmittedFilesForDoc(String docId){
        
        List<ContentDocumentLink> cdlList = [SELECT Id, LinkedEntityId, ContentDocumentId FROM 
                                             ContentDocumentLink WHERE LinkedEntityId = :docId];
        
        List<Id> documentIds = new List<Id>(); 
        for(ContentDocumentLink cdl:cdlList){  
            documentIds.add(cdl.ContentDocumentId);  
        }
        
        if(!documentIds.isEmpty())
        {
            List<Contentversion> submittedContentVersions = new List<Contentversion>([SELECT Id, PEO_Doc_Submitted__c, ContentDocumentId FROM ContentVersion where ContentDocumentId IN :documentIds AND PEO_Doc_Submitted__c = true]);
            
            documentIds.clear();
            for(Contentversion cv : submittedContentVersions){  
                documentIds.add(cv.ContentDocumentId);  
            }
        }
        
        return [SELECT Id, Title, FileType, CreatedDate FROM ContentDocument WHERE Id IN :documentIds ORDER BY CreatedDate DESC];
    } 
    
     @AuraEnabled      
    public static KnowledgeArticleWrap peoGetKnowledgeDetailsWrap(String settingName){
        KnowledgeArticleWrap wrap = new KnowledgeArticleWrap();
        Map<Id,Knowledge__kav> knowledgeMap = new Map<Id,Knowledge__kav>();
        if(settingName.toUpperCase()=='ALL') {
            knowledgeMap = new Map<Id,Knowledge__kav>([select id,Title,Article_Body__c,ArticleNumber,Hover_Description__c,UrlName from Knowledge__kav where PublishStatus='Online' Order By Title Asc]);
            //system.debug('knowledgeMap:'+knowledgeMap);
        }
        else {
            List<PEO_Onboarding_Document_Map__c> settingValues = [select ArticleNumber__c, Article_URL__c 
                                                                  from PEO_Onboarding_Document_Map__c where Name=:settingName limit 1];
            PEO_Onboarding_Document_Map__c pdm = PEO_Onboarding_Document_Map__c.getValues(settingName);
            String articleNumber = pdm.ArticleNumber__c ;
            knowledgeMap = new Map<Id,Knowledge__kav>([select id,Title,Article_Body__c,ArticleNumber,Hover_Description__c,UrlName from Knowledge__kav where PublishStatus='Online' and ArticleNumber=:articleNumber  Order By Title Asc]);
            System.debug('Rohith '+knowledgeMap);
            wrap.knowledge =knowledgeMap.values();
            wrap.knowledgeUrls.add(pdm.Article_URL__c);
        }
        return wrap;
    }
    
    public class KnowledgeArticleWrap{
        @AuraEnabled public List<Knowledge__kav> knowledge {get;set;}
        @AuraEnabled public List<String> knowledgeUrls {get;set;}
        @AuraEnabled public Map<Id,List<Id>> knowledgeFiles {get;set;}
        @AuraEnabled public List<ContentDistribution> contentUrl {get;set;}
        public KnowledgeArticleWrap(){
            knowledge = new List<Knowledge__kav>();
            knowledgeUrls = new List<String>();
            knowledgeFiles = new Map<Id,List<Id>>();
            contentUrl = new List<ContentDistribution>();
        }
    }
    
    @AuraEnabled      
    public static KnowledgeArticleWrap getKnowledgeDetailsWrap(String docName){
        system.debug('%'+docName+'%');
        KnowledgeArticleWrap wrap = new KnowledgeArticleWrap();
        Map<Id,Knowledge__kav> knowledgeMap = new Map<Id,Knowledge__kav>();
        if(docName=='All'){
            knowledgeMap = new Map<Id,Knowledge__kav>([select id,Title,Article_Body__c,ArticleNumber/*,Hover_Description__c*/,UrlName,ClientSpace_Field__c from Knowledge__kav where PublishStatus='Online' and ClientSpace_Field__c!=null Order By Title Asc]);
        } 
        else {
            PEO_Onboarding_Document_Map__c pdm = PEO_Onboarding_Document_Map__c.getValues(docName);
            String articleNumber = pdm.ArticleNumber__c ;
            knowledgeMap = new Map<Id,Knowledge__kav>([select id,Title,Article_Body__c,ArticleNumber/*,Hover_Description__c*/,UrlName,
                                                       ClientSpace_Field__c from Knowledge__kav 
                                                       where PublishStatus='Online' 
                                                       and ArticleNumber=:articleNumber Order By Title Asc]);
        }
        wrap.knowledge =knowledgeMap.values();
        //Integer i=0;
        if(knowledgeMap!=null && knowledgeMap.keySet().size()>0){
            for(ContentDocumentLink cdl : [SELECT ContentDocumentId,ContentDocument.Title, LinkedEntityId,LinkedEntity.Type  FROM ContentDocumentLink where LinkedEntity.Type ='Knowledge__kav' and LinkedEntityId IN :knowledgeMap.keySet() ]){
                //i++;
                if(wrap.knowledgeFiles.get(cdl.LinkedEntityId)==null)
                    wrap.knowledgeFiles.put(cdl.LinkedEntityId,new List<Id>{cdl.ContentDocumentId});
                else
                    wrap.knowledgeFiles.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                ContentDocument contentDocument = [ SELECT Id, Title FROM ContentDocument WHERE Id =: cdl.ContentDocumentId LIMIT 1 ];
                //System.debug(contentDocument);
                ContentVersion contentVersion = [ SELECT Id, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: contentDocument.Id LIMIT 1 ];
                List<ContentDistribution> contentDistributions = [ SELECT Id, Name, ContentDownloadUrl,ContentDocumentId, ContentVersionId FROM ContentDistribution WHERE ContentVersionId =: contentVersion.Id ];
                if (contentDistributions.size() > 0) {
                    //System.debug(contentDistributions[0]);
                    wrap.contentUrl.add(contentDistributions[0]);
                    //System.debug('DOWNLOAD LINK: ' + contentDistributions[0].ContentDownloadUrl);
                } else {
                    ContentDistribution newContentDistribution = new ContentDistribution();
                    newContentDistribution.Name = cdl.ContentDocument.Title;
                    newContentDistribution.ContentVersionId = contentVersion.Id;
                    newContentDistribution.PreferencesAllowViewInBrowser = true;
                    insert newContentDistribution;
                    ContentDistribution contentDistribution = [ SELECT Id, Name, ContentDownloadUrl, ContentDocumentId FROM ContentDistribution WHERE Id =: newContentDistribution.Id LIMIT 1 ];
                    //System.debug(contentDistribution);
                    //System.debug('DOWNLOAD LINK: ' + contentDistribution.ContentDownloadUrl);
                    wrap.contentUrl= new List<ContentDistribution>{contentDistribution};
                        }
            }
        }
        return wrap;
    }
    
    @AuraEnabled
    public static Boolean postSaveAndCompleteChatter(String checkListId, Boolean isTraditional){
        try {
            if (checkListId == null) return false;
            // replace with call to createChatterMentionPost(checklistId,userToMentionIdList,postTexts,mentionsFirst = true)
            // retrieve the checklist and fields required for the chatter message
            PEO_Onboarding_Checklist__c obc = [Select Id,Prospect_Portal_Complete_Date__c, HSF_Submission_Status__c, 
                                                   HSF_Submission_Response__c, Prospect_Client__c, Prospect_Client__r.Name, 
                                                   Sales_Rep__c 
                                                   FROM PEO_Onboarding_Checklist__c 
                                                   where id =: checkListId];
            
            // if the checklist is not flagged as complete set it as complete now
            if(obc.Prospect_Portal_Complete_Date__c == null){
                obc.Prospect_Portal_Complete_Date__c = System.now();
                DMLHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{obc},DmlHelper.DML_UPDATE,'CommunityFileUploadController','postSaveAndCompleteChatter', 'By '+ userHelper.getRunningUser().name + ' on form on peouwsubmitform', true);   
            } else {
                return false;
            }

            List<id> userId = new List<Id>();
            userId.add(obc.Sales_Rep__c);
            List<String> textSegments = new List<String>();
            textSegments.add('Great News, '+obc.Prospect_Client__r.Name);
            
            // add the chatter text message
            if(isTraditional){
                textSegments.add(' has completed the Getting Started portal and uploaded all necessary documents. Please review the portal information and submit to the NBSC Queue when ready.');
            }
            else{
                textSegments.add(' has completed the Getting Started portal and uploaded all necessary documents. Please review the submission, prepare the census, and submit the documents to Clientspace. Navigate to the "Submit" chevron within the Getting Started Portal when you are ready.');
            }
            
            // post the feed item
            if(!test.isRunningTest()){
                ChatterMentionPost.createChatterMentionPost(checkListId, userId, textSegments, true, true);            
            }
            return true;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());
            ErrorLog.logError('CommunityFileUploadController', 'postSaveAndCompleteChatter', 'postSaveAndCompleteChatter Error', checkListId, e, Userhelper.getRunningUser(), true);
            throw new AuraHandledException(e.getMessage()+e.getStackTraceString()+e.getLineNumber());
        }
    }
}