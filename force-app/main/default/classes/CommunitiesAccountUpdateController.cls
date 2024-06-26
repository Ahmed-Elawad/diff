/* 
* Controller for the commuityForms component
Methods moved to:
getPEODocument, saveFiles, getFiles, getSubmittedFilesForDoc, & deleteFile(communityFileUpload), savePeoOnboardingChecklist, saveThisAccount, & saveMedicalQuestionnaire (communityMethods), 
saveEPLIPolicyPeriods, saveEPLIPolicyPeriods, & getEPLIPolicyPeriods(communityEPLI), getDisrepenciesForDoc, getChecklistDiscrepancies,updateDisc, updateDisc, & getAllPeoDocs(communitySummary), 
saveMedicalQuestionnaire(COmmunityMedical), submitForReview(communityFileUpload), getIndustryNames(communityIndustrySpecific), getIndustrySpecificStatus(communnityMethods)
deleted: saveThisAccount, saveOsppty, 
*
* History
* -------
* 04/02/2021    Matt Fritschi   	Created
* 05/04/2021    Ahmed Elawad    	Added methods for getting discrepancies
* 05/11/2021    Jake Hinds      	Added custom permission, change to getRunningUser, adding OppId to checklist creation
* 06/03/2021    Jake Hinds      	Opp future method
* 06/16/2021    Jidesh Athippatta 	peoGetKnowledgeDetailsWrap method
* 06/17/2021    Ahmed Elawad    	Updated getIndustryDetails to use new WC NAICS code to indsutry Map obj
* 07/06/2021    Ahmed Elawad    	Updated getPEOOnboardingChecklist to take third 'oldPeoChecklist' param
* 07/09/2021    Matt Fritschi   	Update to Queue Routing when a record is submitted for review.
* 07/10/2021    Ahmed Elawad    	Added CS Locations check when files are submitted to analyst
* 07/16/2021    Jake Hinds      	Removing opp future method
* 07/26/2021    Ahmed Elawad    	Added getRecords, saveAccountNAICSCode, & getAccNaics for keyword search component
* 08/06/2021    Jake Hinds      	Change to Use Sales Org instead of experience for routing
* 08/11/2021    Jake Hinds      	Consolidated getPEOOnboardingChecklist
* /08/12/2021   Jake Hinds      	fix for permission set
* 8/27/2021		Ahmed Elawad		Added handleAutoSaveRecords for auto save functionality
* 09/01/2021	Jake Hinds			Removed oppId from getPEOOnboardingChecklist
* 09/02/2021	Ahmed Elawad		Moved methods to their respective classes. See notes above if looking for method def
* 11/04/2021	Jake Hinds			Send Complete Email method
* 12/22/2021	Jake Hinds			Removing opp references
* 02/07/2022	Jake Hinds			Removing experience/audience
* 05/30/2022    Reetesh Pandey      Apex code scan resolution
* 11/11/2022    Jidesh				Added 2 new methods submitForHSF, getUpdatedChecklist as part of HSF submission
* 10/05/2023    Jidesh			    Updated submitForHSF to remove logic for HSF_Census_Submit_Date__c field
* 12/27/2023	Jidesh				Updated logic on handleAutoSaveRecords method for Last_Change_Made__c field.
* 01/08/2024	Ahmed Elawad		SFDC-24670 added methods for retrieving checklist and related record details in two steps
*/
public without sharing class CommunitiesAccountUpdateController {
    
    @AuraEnabled
    public static Account[] getAccountInformation(String startingId, String formName) {
        try {
            // Apex code scan
            startingId = String.escapeSingleQuotes(startingId);
            Map<Id, Account[]> accounts =  communityMethods.getAccountInformation(new Set<Id>{startingId}, formName, 'CommunitiesAccountUpdateController');
            return accounts.get(startingId);   
        }catch(Exception e){
            throw new AuraHandledException('Could not retrieve Accounts. Please contact your administrator for support.');
        }
    }
    
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,PEO_Onboarding_Checklist__c oldChecklist, String formName) {
        return communityMethods.getPEOOnboardingChecklist(accountId, oldChecklist, formName, 'CommunitiesAccountUpdateController');
    }
    
    //Get the medical questionnaire
    @AuraEnabled
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaireForm(Id peoOnboardingChecklistId, String formName) {
        return communityMethods.getMedicalQuestionnaireForm(peoOnboardingChecklistId, formName, 'CommunitiesAccountUpdateController');
    }
    
    @AuraEnabled
    public static Boolean getSystemPermission()
    {
        User runningUser = getRunningUser();
        Boolean hasPermission = false;
        //there is not a good way to test this stuff.
        if(Test.isRunningTest() || runningUser.Profile.Name=='System Administrator' || runningUser.UserType != 'Standard'
           || FeatureManagement.checkPermission('PEO_Getting_Started_BETA')){
               return true;
           }
        else{
            return false;
        }
    }
    
    @AuraEnabled
    public static User getRunningUser()
    {
        System.debug('Getting running user');
        User runningUser = UserHelper.getRunningUser();
        return runningUser;
    }
    
    @AuraEnabled
    public static User getCommunityUser(String startingId)
    {
        List<User> communityUser = new List<User>();
        // Apex code scan
        startingId = String.escapeSingleQuotes(startingId);
        if(Id.valueOf(startingId).getsobjecttype() == ((SObject) Type.forName('Contact').newInstance()).getSObjectType())
        {
            communityUser = [SELECT Id, Name FROM User WHERE ContactId = :startingId LIMIT 1];
        }
        else if(Id.valueOf(startingId).getsobjecttype() == ((SObject) Type.forName('User').newInstance()).getSObjectType())
        {
            communityUser = [SELECT Id, Name FROM User WHERE Id = :startingId LIMIT 1];
        }
        
        if(communityUser.size() == 1)
        {
            return communityUser[0];
        }
        else
        {
            return null;
        }
        
    }
    
    /*@AuraEnabled
    public static Boolean checkImplchecklistPermissions(){
        String label = System.Label.PEOUWRequireImpPermission;
        if(label == 'Yes'){
            Boolean hasCustPerm = FeatureManagement.checkPermission('PEO_Getting_Started_Imp');
            if(!hasCustPerm){
                Id userId = userInfo.getUserId();
                List<PermissionSetAssignment> psas = [ select Id from PermissionSetAssignment where PermissionSetId 
                                                      IN ( select Id from PermissionSet where 
                                                          Name = 'PEO_Getting_Started_Implementation_Beta') and 
                                                      AssigneeId =: userId];
                if(psas.size() > 0){
                    return true;
                }else{
                    return false;
                }
            }else{
                return true;
            }
        }else{
            return true;
        }
    }*/
    
    @AuraEnabled
    public static User getStrategicAccountPartner(Account parentAccount) { 
        User strategicAccountPartner = null;
        if(parentAccount != null && parentAccount.Referral_National_Account__c != null) {
            System.debug('MGF getStrategicAccountPartner parentAccount='+parentAccount.Name + ' parentAccount.Referral_National_Account__c='+parentAccount.Referral_National_Account__c);
            Referral_Account__c strategicAccount = [SELECT Id, Name, NBSC_SA_Partner__c, Parent_Referral_Account__c, Parent_Referral_Account__r.NBSC_SA_Partner__c FROM Referral_Account__c WHERE Id = :parentAccount.Referral_National_Account__c LIMIT 1];
            if(strategicAccount != null) {
                System.debug('MGF getStrategicAccountPartner strategicAccount.Name='+strategicAccount.Name + ' strategicAccount.NBSC_SA_Partner__c='+strategicAccount.NBSC_SA_Partner__c);
                if(strategicAccount.NBSC_SA_Partner__c != null) {
                    strategicAccountPartner = [SELECT Id, Name FROM User WHERE Id = :strategicAccount.NBSC_SA_Partner__c];
                    System.debug('MGF getStrategicAccountPartner strategicAccountPartner.Name='+strategicAccountPartner.Name);
                }
                else if(strategicAccount.Parent_Referral_Account__c != null) {
                    if(strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c != null) {
                        strategicAccountPartner = [SELECT Id, Name FROM User WHERE Id = :strategicAccount.Parent_Referral_Account__r.NBSC_SA_Partner__c];
                    }
                }
            }
        }
        
        return strategicAccountPartner;
    }
    
    
    @AuraEnabled      
    public static Boolean needCovidQuestionnaire(Account parentAccount, String formName){
        Boolean covidQuestionnaireNeedeed = false;
        if(parentAccount.NAICS_Code__c != null) {
            try {
                List<WC_NAICS_To_Industry_Map__c> naics = [SELECT Id, Name, COVID_Questionnaire_Required__c FROM WC_NAICS_To_Industry_Map__c WHERE Name = :parentAccount.NAICS_Code__c];
                if(!naics.isEmpty() && naics.size() == 1 && naics[0].COVID_Questionnaire_Required__c) {
                    covidQuestionnaireNeedeed=true;
                }
            } catch(Exception e) {
                communityMethods.logCommunityError(e, 'needCovidQuestionnaire', 'CommunitiesAccountUpdateController', formName, parentAccount, null);
            }
        }
        
        return covidQuestionnaireNeedeed;
    }
    
    @AuraEnabled
    public static Boolean getImplementationQuestionStatus(Id checklistId){
        List<PEO_Implementation_Checklist__c> checlistData = [SELECT Id, Last_client_email_date__c, Rep_questions_finalize_date__c, 
                                                              Status__c FROM PEO_Implementation_Checklist__c WHERE PEO_Underwriting_Checklist__c =: checklistId];
        if(checlistData.size() > 0 && checlistData[0].Status__c == 'Completed' ){
            return true;
        }else{
            return false;
        }
    }
    
    //Added by Bharat - Start of Change
    @AuraEnabled
    public static List<PEO_Onboarding_Checklist__c> getPEOOnboardingChecklistsData(List<Account> accList, String formName){
        List<PEO_Onboarding_Checklist__c> data;
        try {
            data = [SELECT Id, List_of_Owners__c, Prospect_Client__c, Prospect_Client__r.Name FROM PEO_Onboarding_Checklist__c
                    WHERE Prospect_Client__c IN:accList];
            return data;
        }catch(Exception e) {
            communityMethods.logCommunityError(e, 'needCovidQuestionnaire', 'CommunitiesAccountUpdateController', formName, accList);
            return null;   
        }
    } //Added by Bharat - end of Change
    
    // Handle the auto save operation for the community Forms component. If any update fails log the error and return false
    // for any failure. DML Errors are logged to the Error_Log__c Object
    @AuraEnabled
    public static Map<String, Map<String, List<SObject>>> handleAutoSaveRecords(List<Account> accounts, List<PEO_Onboarding_Checklist__c> checklists,
                                                                                List<PEO_Onboarding_Medical_Questionnaire__c> medicalForms, List<WC_Questionnaire_Industry_Specific__c> industryForms,
                                                                                List<Policy_Period__c> policyPeriodForms, List<PEO_Implementation_Checklist__c> lstPEOImpchk, String formName) 
    { 
        // for each object list verify that there are records to be updated in the lists then send the request to update them
        // In the case of any error log the error to the error log obj and set the return flag to false indicating a
        // failure along the way.
        Boolean success = true;
        
        // build map to track object name list of failures and successes
        // Account: 
        // 		fail: [account{name='acc 1'}, account{name='acc 2'}]
        // PEO_Onboarding_Checklist__c:
        // 		Success: [PEO_Onboarding_Checklist__c{name='chk1'}]
        Map<String, Map<String, List<SObject>>> returnMap = new Map<String, Map<String, List<SObject>>>();
        
        // send a save request for the list of Accounts
        if (accounts != null && !accounts.isEmpty()) {
            success  = saveRecordsAndAddResult(accounts, returnMap, 'Account', formName);
        }
        // send a save request for the list of lstPEOImpchk
        if (lstPEOImpchk != null && !lstPEOImpchk.isEmpty()) {
            success  = saveRecordsAndAddResult(lstPEOImpchk, returnMap, 'PEO_Implementation_Checklist__c', formName);
        }
        
        // send a save request for the checklists
        if (checklists != null && !checklists.isEmpty()) {
            Id curUserProfId =userinfo.getProfileId();
            List<String> limitedProfileNames = new List<String>{'System Administrator API-ClientSpace','System Administrator','Sales Enablement'};
                List<Profile> limitedProfiles = [SELECT Id, Name FROM Profile WHERE Name IN:limitedProfileNames];
            boolean isAdminUser = false;
            for(Profile prof: limitedProfiles){
                if(prof.id == curUserProfId){
                    isAdminUser = true;
                }
            }
            for(PEO_Onboarding_Checklist__c chk: checklists){
                if(!isAdminUser){
                    chk.Last_Change_Made__c = DateTime.now();
                }
                if(Test.isRunningTest()){
                    chk.Last_Change_Made__c = DateTime.now();
                }
            }
            success  = saveRecordsAndAddResult(checklists, returnMap, 'PEO_Onboarding_Checklist__c', formName);
        }
        
        // send a save request for medical forms
        if (medicalForms != null && !medicalForms.isEmpty()) {
            success  = saveRecordsAndAddResult(medicalForms, returnMap, 'PEO_Onboarding_Medical_Questionnaire__c', formName);
        }
        
        // send a save request for industry specific
        if (industryForms != null && !industryForms.isEmpty()) {
            success  = saveRecordsAndAddResult(industryForms, returnMap, 'WC_Questionnaire_Industry_Specific__c', formName);
        }
        
        // send a save request for policyPeriodForms
        if (policyPeriodForms != null && !policyPeriodForms.isEmpty()) {
            success  = saveRecordsAndAddResult(policyPeriodForms, returnMap, 'Policy_Period__c', formName);
        }
        System.debug(returnMap);
        // send a save request for opportunities
        return returnMap;
    }
    
    @AuraEnabled
    public static List<string> getIndustryNames(String[] naicsCodes) {
        List<String> industryNames = new List<String>();
        industryNames = CommunityIndustrySpecificController.getIndustryNames(naicsCodes);
        return industryNames;
    }
    
    @AuraEnabled
    public static User getSalesRepresentativeInfo(Id userId) {
        User u = [SELECT Id, FirstName, LastName, Phone FROM User WHERE Id = :userId];
        return u;
    }
    
    @AuraEnabled
    public static Boolean sendCompleteEmail(PEO_Onboarding_Checklist__c checklist, String accountName, String currStep) {
        Boolean emailSent = false;
        String fullAddress;
        if(!Test.isRunningTest()){
            EmailServicesFunction emailFunction = [SELECT Id FROM EmailServicesFunction WHERE FunctionName='Communities Prospect Chatter Email' LIMIT 1];
            EmailServicesAddress emailServicesAddress = [SELECT Id, LocalPart, EmailDomainName FROM EmailServicesAddress WHERE FunctionId = :emailFunction.Id LIMIT 1];
            fullAddress = emailServicesAddress.LocalPart + '@' + emailServicesAddress.EmailDomainName;
        }
        else{
            fullAddress = 'test@test.test';
        }
        
        System.debug('Email Service Address: ' + fullAddress);
        Messaging.SingleEmailMessage obEmail = new Messaging.SingleEmailMessage();
        obEmail.setToAddresses(new String[]{fullAddress});
        obEmail.setSubject('Step Complete Chatter');
        
        String bodyText='';
        //body text is going to be a semi colon separated list.  The first element will be the current step, the second is the prospect name, 
        //the third is the checklist Id, the fourth is the contact id, the remaining will be those to @mention
        if(String.isNotBlank(currStep) && String.isNotBlank(accountName)){
          /*  if(checklist.Medical_Underwriting_Path__c == 'Gradient Pre-Qualifier'){
                bodyText += currStep+'PreQual;';
            }
            else{
                bodyText += currStep+';';
            } */
            bodyText += currStep+';';
            bodyText += accountName+';'; 
            if(checklist!=null){
                bodyText += checklist.Id+';';
                system.debug('Community User'+checklist.Community_User__c);
                bodyText += checklist.Community_User__c+';';
                if(String.isNotBlank(checklist.Sales_Rep__c)){
                    bodyText += checklist.Sales_Rep__c+';';
                }
                /*if(String.isNotBlank(checklist.PEO_NSC__c)){
                    bodyText += checklist.PEO_NSC__c+';';
                }*/
                if(String.isNotBlank(checklist.Sales_Analyst__c)){
                    bodyText += checklist.Sales_Analyst__c+';';
                }
            }
        }
        System.debug(bodyText);
        if(String.isNotBlank(bodyText)){
            obEmail.setPlainTextBody(bodyText);
            Messaging.SendEmailResult[] results;
            if(!Test.isRunningTest()){
                // added by rohith to fix unwanted email issue from rep
                results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {obEmail});
                // added by rohith to fix unwanted email issue from rep
            }
            if (Test.isRunningTest() || (results!=null && results[0].success)) {
                emailSent = true;
            }
        }
        
        return emailSent;
        
    }
    
    //Test is been called from CommunitiesAccountUpdateControllerTest
    @AuraEnabled
    public static DocWrapper[] getDocsApex(String checklistId){
        DocWrapper[] docWraps;
        Map<Id,PEO_Onboarding_Document__c> docMap;
        if(String.isNotBlank(checklistId)){
            docMap = new Map<Id,PEO_Onboarding_Document__c>([SELECT Id,Name,Status__c FROM PEO_Onboarding_Document__c 
                                                             WHERE PEO_Onboarding_Checklist__c=:checklistId]);
        }
        system.debug('CommunitiesAccountUpdateController getDocsApex docMap'+docMap);
        if(docMap!=null && !docMap.isEmpty()){
            //get all content document links and create a map organizing by onboarding doc id
            Map<Id,ContentDocumentLink[]> linksByDocId = new Map<Id,ContentDocumentLink[]>();
            ContentDocumentLink[] allLinks = [SELECT ContentDocumentId, LinkedEntityId,ShareType,
                                              ContentDocument.CreatedDate, ContentDocument.Title, ContentDocument.Description,ContentDocument.ContentAssetId
                                              FROM ContentDocumentLink 
                                              where LinkedEntityId in :docMap.keySet()
                                              ORDER BY ContentDocument.ContentModifiedDate DESC];
            system.debug('CommunitiesAccountUpdateController getDocsApex allLinks'+allLinks);
            for(ContentDocumentLink link:allLinks){
                //if there were multiple links per onb doc we need all of them
                ContentDocumentLink[] linksForMap = new ContentDocumentLink[]{};
                    if(!linksByDocId.isEmpty() && linksByDocId.containsKey(link.LinkedEntityId)){
                        linksForMap = linksByDocId.get(link.LinkedEntityId);
                    }
                linksForMap.add(link);
                linksByDocId.put(link.LinkedEntityId,linksForMap);
            }
            system.debug('CommunitiesAccountUpdateController getDocsApex linksByDocId'+linksByDocId);
            //loop through the onboarding doc ids, get the doc links and build a wrapper
            for(PEO_Onboarding_Document__c onbDoc:docMap.values()){
                ContentDocumentLink[] linksForDoc = linksByDocId.get(onbDoc.Id);
                DocWrapper docWrap = new DocWrapper(onbDoc,linksForDoc);
                if(docWraps==null){
                    docWraps = new DocWrapper[]{};
                        }
                docWraps.add(docWrap);
            }
            system.debug('CommunitiesAccountUpdateController getDocsApex docWraps'+docWraps);
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
            system.debug('CommunitiesAccountUpdateController DocWrapper constructor'+p_Doc+' links:'+p_docLinks);
            docId = p_doc.Id;
            name = p_doc.Name;
            status = p_doc.Status__c;
            docLinks = p_docLinks;
        } // DocWrapper
    }
    
    // create method to take generic sobject save it and add the reult to the result map
    public static Boolean saveRecordsAndAddResult(List<SObject> objList, Map<String, Map<String, List<Sobject>>> returnMap, String objName, String formName) {
                if (objList == null || returnMap == null) return false;
        if (objList.isEmpty()) return true;
        
        Map<String, List<SObject>> objResult = new Map<String, List<SObject>>();
        Map<String, List<SObject>> objError = new Map<String, List<SObject>>();
        Boolean result = true;
        String ErrorMessage='';
        try {
            //update objList;
             Database.SaveResult[] srList = Database.update(objList, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                        System.debug('Successfully updated: ' + sr.getId());
                    }
                else{
                    result =  false;
                    for(Database.Error err : sr.getErrors()) {
                        ErrorMessage=ErrorMessage+'\n'+err.getMessage();
                    }
                }
            }           
        } catch(Exception e) { 
            communityMethods.logCommunityError(e, 'handleAutoSaveRecords', 'CommunitiesAccountUpdateController', formName, objList);                          
            result =  false;
        }
        
        objResult.put( (result ? 'Success' : 'Fail'), objList);   
        if(!result){
            objError.put(ErrorMessage, objList);
          	returnMap.put(objName+ 'Error', objError);          	 
        }        
        returnMap.put(objName, objResult);
        return result;
    }
    // Rohith SFDC-15402
    @AuraEnabled
    public static Boolean getSurvey() {
        Boolean returnValue = false;
        List<User> userInstance = [select id,Name,ContactId from User where id =: userInfo.getUserId() LIMIT 1];
        
        if(!userInstance.isEmpty() && userInstance[0].ContactId != NULL){
            List<Contact> contacts = [SELECT Id,AccountId FROM Contact WHERE Id = :userInstance[0].ContactId];
            
            if(!contacts.isEmpty() && contacts[0].AccountId != NULL){
                List<PEO_Onboarding_Checklist__c> checkLists = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :contacts[0].AccountId LIMIT 1];
                
                if(!checkLists.isEmpty()){
                    List<PEO_Underwriting_Surveys__c> surveys = [SELECT Id FROM PEO_Underwriting_Surveys__c WHERE PEO_Underwriting_Checklist__c = :checkLists[0].Id LIMIT 1];
                    
                    if(surveys.isEmpty()){
                        returnValue = true;
                    }
                }
            }
        }
        
        return returnValue;
    }
    
    @AuraEnabled
    public static void submitSurvey(Decimal rating, String secondQuestion, String answers) {
         PEO_Underwriting_Surveys__c childSurvey = new PEO_Underwriting_Surveys__c();
        childSurvey.Rating__c = rating;
        childSurvey.Questions__c = secondQuestion;
        childSurvey.Answers__c = answers;
        
        List<User> userInstance = [select id,Name,ContactId from User where id =: userInfo.getUserId() LIMIT 1];
        
        if(!userInstance.isEmpty() && userInstance[0].ContactId != NULL){
            List<Contact> contacts = [SELECT Id,AccountId FROM Contact WHERE Id = :userInstance[0].ContactId];
            
            if(!contacts.isEmpty() && contacts[0].AccountId != NULL){
                List<PEO_Onboarding_Checklist__c> checkLists = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :contacts[0].AccountId LIMIT 1];
                
                if(!checkLists.isEmpty()){
                    childSurvey.PEO_Underwriting_Checklist__c = checkLists[0].Id;
                }
            }
        }
        
        try {
            if(childSurvey != NULL){
                insert childSurvey;
            }
        }catch(DMLException e){
            System.debug('Exception - ' +e.getDMLMessage(0));
        }
    }
    
     @AuraEnabled
    public static Boolean submitForHSF (PEO_Onboarding_Checklist__c peoOnbChecklist){
        Boolean success = false;
        List<PEO_Onboarding_Checklist__c> checklistInfo = [Select Id, Name, HSF_Submission_Status__c, HSF_Status_Change_Date__c, HSF_Census_Submit_Date__c from PEO_Onboarding_Checklist__c where Id =:peoOnbChecklist.Id limit 1];
        if(checklistInfo.size() >0){
            System.debug('submitForHSF: Checklist returned');
            checklistInfo[0].HSF_Submission_Status__c = 'Submitted';
            //checklistInfo[0].HSF_Census_Submit_Date__c = System.now();
            success = DmlHelper.performDML2(checklistInfo, DmlHelper.DML_UPDATE, 'CommunitiesAccountUpdateController', 'submitForHSF', 'submitForHSF', true);
        }
        return success;
    }
    
   
    @AuraEnabled
    public static List<PEO_Onboarding_Checklist__c> getUpdatedChecklist(List<PEO_Onboarding_Checklist__c> chkLists, String formName){
        System.debug('getUpdatedChecklist-chkLists:'+chkLists);
        List<PEO_Onboarding_Checklist__c> data;
        try {
            data = [SELECT Id, HSF_Submission_Status__c, HSF_Status_Change_Date__c, pkzPEOUnderwritingChecklistID__c, HSF_Submission_Response__c, PEO_Checklist_submission_status__c FROM PEO_Onboarding_Checklist__c
                    WHERE Id IN:chkLists];
            System.debug('getUpdatedChecklist-Checklist retrieved :'+data);
            return data;
        }catch(Exception e) {
            communityMethods.logCommunityError(e, 'getUpdatedChecklist', 'CommunitiesAccountUpdateController', formName, chkLists);
            return null;   
        }
    }
    
    @AuraEnabled
    public static Opportunity getOpp(Id optyId){
        return [Select Id, Name, CurrentPayrollMethod__c,Payroll_Current_Prior_Method__c from Opportunity where Id=:optyId];
    }
    
    @AuraEnabled
    public static UserAttributeWrapper getCommunityFormsUserAttributes(String startingId, String formName) {
        UserAttributeWrapper returnWrapper = new UserAttributeWrapper();
        returnWrapper.hasAccess = getSystemPermission();
        returnWrapper.runningUser = getRunningUser();
        returnWrapper.communityUser = getCommunityUser(startingId);
        return returnWrapper;
    }
	
    @TestVisible
    public class UserAttributeWrapper {
        @AuraEnabled
        Public user runningUser;
        
        @AuraEnabled
        public user communityUser;
        
        @AuraEnabled
        public Boolean hasAccess;
    }    
    
    @AuraEnabled
    public static communityFormsWrapper getCommunityFormRecords(String formName, String startingId) {
        
        communityFormsWrapper returnWrapper = new communityFormsWrapper();
        returnWrapper.allAccounts = getAccountInformation(startingId, formName);
        
        if (returnWrapper.allAccounts != null && returnWrapper.allAccounts.size() > 0) {
            // parentNAICSCode != null && parentNAICSCode != '' && parentNAICSCode != 'undefined'
            Set<String> naicsCodes = new Set<String>();
            for (Account acc : returnWrapper.allAccounts) {
                if (acc.NAICS_Code__c != null) {
                    naicsCodes.add(acc.NAICS_Code__c);
                }
            }
            if (!naicsCodes.isEmpty()) returnWrapper.industryNames = getIndustryNames(new List<String>(naicsCodes));
            
            // get the parent checklist
            returnWrapper.peoOnboardingChecklist = getPEOOnboardingChecklist(returnWrapper.allAccounts[0].Id, null, formName);
            
            // get the child checklists
            if (returnWrapper.allAccounts.size() > 1) {
                List<Account> childrenOnly = new List<Account>(returnWrapper.allAccounts);
                // remove the parant which is always assumed to be at list[0] based on how getAccountInformation is implemented
                childrenOnly.remove(0);
                returnWrapper.childChecklists = getPEOOnboardingChecklistsData(childrenOnly, formName);
            }
            
            if (returnWrapper.peoOnboardingChecklist != null) {
                returnWrapper.isEmailSent = getImplementationQuestionStatus(returnWrapper.peoOnboardingChecklist.Id);
                returnWrapper.oppty = getOpp(returnWrapper.peoOnboardingChecklist.Opportunity__c);
            }
        }
        
        return returnWrapper;
    }
    
    @Testvisible
    public class communityFormsWrapper {
        @AuraEnabled
        public List<Account> allAccounts;
        
        @AuraEnabled
        public List<PEO_Onboarding_Checklist__c> childChecklists;
        
        @AuraEnabled
        public List<String> industryNames;
        
        @AuraEnabled
        public PEO_Onboarding_Checklist__c peoOnboardingChecklist;
        
        @AUraEnabled
        public boolean isEmailSent = false;
        
        @AuraEnabled
        public Opportunity oppty;
    }
}