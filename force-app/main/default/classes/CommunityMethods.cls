/*
History
-------
* 05/04/2021    Jake Hinds          Created
* 07/16/2021    Jake Hinds          Set opp checkbox
* 08/23/2021    Ahmed Elawad        Added comm methods: savePeoOnboardingChecklist, getIndustrySpecificStatus, saveMedicalQuestionnaire, getPEOOnboardingChecklist, getMedicalQuestionnaireForm, getIndustryDetails, IndustrySpecificWrap
* 09/15/2021    Ahmed Elawad        Added logging methods logCommunityError & updated methods to use dml helper + take in form params, also added runningUser class member
* 10/06/2021    Ahmed Elawad        Refactored getAccountInformation
* 11/01/2021    Matt Fritschi       Added checkIfChecklistCompleteFuture to see if the checklist and all related objects have been completed.
* 02/01/2022    Ahmed Elawad        SFDC-10790 APR APR0131036: getIndustry details to insert Ind Record WQ through createIndSpecificWQFuture()
* 02/07/2022    Jake Hinds          Removing experience
* 02/10/2022    Jake Hinds          Moving med and ind status fields to checklist
* 02/11/2022    Ahmed Elawad        SFDC-11165: Add methods -updateExistingChkIsqRecTypesAndDeleteOldRecs, handleISQRecordUpdated, insertISQRecordsForChk
* 03/10/2022    Jake Hinds          Contact Trigger
* 03/18/2022    Jake Hinds          Contact After
  07/19/2022    Varun K             update to accomodate new CPA portal users for resending welcome email
  02/14/2023    Dan Carmen          Did a check for updateChecklistOwnerWithOptyOwner for future call
  12/14/2023	Jidesh				SFDC-24408: Updated checkIfChecklistComplete to check if user can update the Last Change made field based on their profile
* 12/18/2023	Priyanka			SFDC-23985: Updated updateChecklistOptyWithLatest method to check most recent Opty on checklist
* 01/17/2024	Jidesh			    Updated updateChecklistOptyWithLatest method to add check for Sales Analyst to set checklist OwnerId
* 02/05/2024    Srujan              SFDC-25219: chatterForFailedCensus - A new method to post a chatter from flow for failed census
*/

public without sharing class CommunityMethods implements TriggerInterfaceC{
    public static Boolean postCreated = false;
    public static Boolean alreadyRan = false;
    Public static User runningUser = Userhelper.getRunningUser();
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        if (TriggerMethods.objType == Contact.sObjectType && isBefore) {
            handleContactBefore((Contact[])recs, (Map<Id,Contact>)oldMap);
            system.debug('CommunityMethods in handleContactTrigger');
        }
        else if (TriggerMethods.objType == Contact.sObjectType && isAfter) {
            handleContactAfter((Contact[])recs, (Map<Id,Contact>)oldMap);
            system.debug('CommunityMethods in handleContactTrigger');
        }
    } // handleTrigger
    //This is called from the account trigger directly to fit in with zip updates
    public static void handleAcctsAfter(Account[] accts, Map<Id,Account> oldMap) {
        if(alreadyRan){
            return;
        }
        alreadyRan = true;
        User runningUser = UserHelper.getRunningUser();
        Map<Id,Id> priorOwnerByAcctId = new Map<Id,Id>();
       
        // create map to track accounts with updated NAICs codes: just the account ids. Doesn't matter if parent or child
        Map<Id, Set<String>> acctToOldNaics = new Map<Id, Set<String>>();
        Map<Id, Set<String>> acctToNewNaics = new Map<Id, Set<String>>();
        Set<String> allNaicsSet = new Set<String>();
        
        //requery record to get zip assign update?
        Map<Id,Account> queryMap = new Map<Id,Account>([SELECT Id,ShippingPostalCode,OasisPEOAccountOwner__c,Premier_PBS_Account_Owner__c, NAICS_Code__c, SalesParent__c,
                                                        SalesParent__r.NAICS_Code__c, isParent__c, isChild__c
                                                        FROM Account WHERE Id in:oldMap.keySet()]);
        for(Account acct:accts){
            Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
            Account updatedAcct = queryMap.get(acct.Id);
            if(((updatedAcct!=null && updatedAcct.OasisPEOAccountOwner__c != acct.OasisPEOAccountOwner__c) || (oldAcct!=null && oldAcct.OasisPEOAccountOwner__c != acct.OasisPEOAccountOwner__c))&& ((runningUser!=null && runningUser.UserType!='Standard') || Test.isRunningTest())){
                   priorOwnerByAcctId.put(acct.Id,acct.OasisPEOAccountOwner__c);
               }
            else if(((updatedAcct!=null && updatedAcct.Premier_PBS_Account_Owner__c != acct.Premier_PBS_Account_Owner__c) || (oldAcct!=null && oldAcct.Premier_PBS_Account_Owner__c != acct.Premier_PBS_Account_Owner__c)) && ((runningUser!=null && runningUser.UserType!='Standard') || Test.isRunningTest())){
                        priorOwnerByAcctId.put(acct.Id,acct.Premier_PBS_Account_Owner__c);
                    }
            
            // if the account naics was changed add it to tracker of account id to account
            if ( (updatedAcct!=null && oldAcct!= null) && (updatedAcct.NAICS_Code__c != oldAcct.NAICS_Code__c)) {
                // if the account is a parent or single id add it's id otherwise add the paret
                Id controllingId = (updatedAcct.isParent__c || (!updatedAcct.isParent__c && !updatedAcct.isChild__c) ? updatedAcct.Id : updatedAcct.SalesParent__c);
                Set<String> oldNaicsSet = acctToOldNaics.get(controllingId);
                Set<String> newNaicsSet = acctToNewNaics.get(controllingId);
                if (oldNaicsSet == null) {
                    oldNaicsSet = new Set<String>();
                    acctToOldNaics.put(controllingId, oldNaicsSet);
                }
                
                if (newNaicsSet == null) {
                    newNaicsSet = new Set<String>();
                    acctToNewNaics.put(controllingId, newNaicsSet);
                }
                
                allNaicsSet.add(updatedAcct.NAICS_Code__c);
                allNaicsSet.add(oldAcct.NAICS_Code__c);
                oldNaicsSet.add(oldAcct.NAICS_Code__c);
                newNaicsSet.add(updatedAcct.NAICS_Code__c);
            } 
        }
        
        system.debug('priorOwnerByAcctId:'+priorOwnerByAcctId);
        if(!priorOwnerByAcctId.isEmpty()){
            chatterOldOwner(priorOwnerByAcctId);
        }        
        
        // if acccounts with updated NAIs isn't empty 
        // send call to request isq updates and checkhlist updates
        if (!acctToOldNaics.isEmpty()) {
            updateExistingChkIsqRecTypesAndDeleteOldRecs(acctToOldNaics, acctToNewNaics, allNaicsSet);
        }
        
    } //handleAcctsAfter
    
    public static void handleContactBefore(Contact[] ctcts, Map<Id,Contact> oldMap) {
        Id[] contactIdsToResendEmail = new Id[]{};
        for(Contact ctct:ctcts){
            Contact oldCtct = (oldMap!=null && oldMap.containsKey(ctct.Id) ? oldMap.get(ctct.Id):null);
            if(oldCtct!=null && !oldCtct.Resend_Getting_Started_Welcome_Email__c && ctct.Resend_Getting_Started_Welcome_Email__c){
                ctct.Resend_Getting_Started_Welcome_Email__c = false;
                contactIdsToResendEmail.add(ctct.Id);
            }
        }
        if(!contactIdsToResendEmail.isEmpty()){
            if (System.isFuture() || System.isBatch()) {
                resendWelcomeEmailNow(contactIdsToResendEmail);
            } else {
                resendWelcomeEmailFuture(contactIdsToResendEmail);
            }
        }//!contactIdsToResendEmail.isEmpty
    }//handleContactBefore
    
    public static void handleContactAfter(Contact[] ctcts, Map<Id,Contact> oldMap) {
        Id[] contactIdsToUpdateEmail = new Id[]{};
        for(Contact ctct:ctcts){
            Contact oldCtct = (oldMap!=null && oldMap.containsKey(ctct.Id) ? oldMap.get(ctct.Id):null);
            if(oldCtct!=null && oldCtct.Email != ctct.Email){
                contactIdsToUpdateEmail.add(ctct.Id);
            }
        }
        system.debug('CommunityMethods handleContactAfter'+contactIdsToUpdateEmail);
        if(!contactIdsToUpdateEmail.isEmpty()){
            if (System.isFuture() || System.isBatch()) {
                updateCommunityUserEmailNow(contactIdsToUpdateEmail);
            } else {
                updateCommunityUserEmailFuture(contactIdsToUpdateEmail);
            }
        }//!contactIdsToUpdateEmail.isEmpty
    }//handleContactAfter
    
    @InvocableMethod
    public static void chatterForFailedCensus(List<PEO_Onboarding_Checklist__c> checkList) {
        if(checkList.size() > 0){
            List<Id> userToMentionIdList = new List<Id>();
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();            
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            textSegmentInput.text = 'Hello ';
            messageBodyInput.messageSegments.add(textSegmentInput);
            if(checkList[0].Sales_Rep__c != null){
                userToMentionIdList.add(checkList[0].Sales_Rep__c);
                List<User> u = [SELECT Id, ManagerId FROM User WHERE Id =: checkList[0].Sales_Rep__c limit 1]; 
                if(u.size() > 0 && u[0].ManagerId != null){
                    userToMentionIdList.add(u[0].ManagerId);
                }
                if(userToMentionIdList.size() > 0){
                    ChatterMentionPost.getMentions(messageBodyInput, userToMentionIdList);
                }
            }
            ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
            textSegmentInput2.text = '. It looks like ';
            messageBodyInput.messageSegments.add(textSegmentInput2);
            ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputAccount = new ConnectApi.EntityLinkSegmentInput();
            entityLinkSegmentInputAccount.entityId = checkList[0].Prospect_Client__c;   
            messageBodyInput.messageSegments.add(entityLinkSegmentInputAccount);
            
            ConnectApi.TextSegmentInput textSegmentInput3 = new ConnectApi.TextSegmentInput();
            textSegmentInput3.text = ' has a FAILED census submission to ClientSpace for Quick Quote. Ensure your census is ' + 
                'properly converted to the required template and review the error message in the "Submit" tab of the Getting Started Portal. ' + 
                ' Once resolved, please resubmit your census to continue the Quick Quote process. Click the resource guide below for assistance. \n';
            messageBodyInput.messageSegments.add(textSegmentInput3);
            
            ConnectApi.TextSegmentInput textSegmentInput4 = new ConnectApi.TextSegmentInput();
            textSegmentInput4.text = 'Resource Guide Here: ';
            messageBodyInput.messageSegments.add(textSegmentInput4);
            
            ConnectApi.LinkCapabilityInput linkInput = new ConnectApi.LinkCapabilityInput();
            linkInput.url = 'http://payx.me/95i';
            linkInput.urlName = 'GSP Census Resources';
            ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
            feedElementCapabilitiesInput.link = linkInput;
            feedItemInput.capabilities = feedElementCapabilitiesInput;
            
            feedItemInput.capabilities = feedElementCapabilitiesInput;
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = checkList[0].Id; 
            if(!test.isRunningTest()){
                ConnectApi.FeedElement feedElement =
                    ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
            }
        }
    }
    
    @future
    public static void resendWelcomeEmailFuture(Id[] contactIds){
        system.debug('CommunityMethods in resendWelcomeEmailFuture');
        resendWelcomeEmailNow(contactIds);
    }
    
    public static void resendWelcomeEmailNow(Id[] contactIds){
        system.debug('CommunityMethods in resendWelcomeEmailNow');
        //get community users for contacts that changed
        Map<Id,User> communityUserMap = new Map<Id,User>([SELECT Id,ContactId,Community_User_First_Login__c,ProfileName__c, Email FROM User WHERE ContactId in:contactIds AND IsActive=true]);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='PEO_Getting_Started_Prospect' LIMIT 1];
		//Changes start - Varun
        PermissionSet cpaps = [SELECT Id FROM PermissionSet WHERE Name='CPA_Getting_Started_Prospect' LIMIT 1];
        Set<Id> paIds = new Set<Id>{ps.Id,cpaps.Id};
        //Changes end - Varun    
        PermissionSetAssignment[] psaToInsert = new PermissionSetAssignment[]{};
        PermissionSetAssignment[] psaToDelete = new PermissionSetAssignment[]{};
        
        if(ps!=null && cpaps!=null && communityUserMap!=null && !communityUserMap.isEmpty()){
           //get existing permission set assignments
            PermissionSetAssignment[] existingPSAs = [SELECT Id,AssigneeId,PermissionSetId FROM PermissionSetAssignment 
                                                       WHERE PermissionSetId IN :paIds AND AssigneeId in:communityUserMap.keySet()];
            System.debug('existingPSAs>>>'+existingPSAs);
            System.debug('communityUserMap>>>'+communityUserMap);
            if(existingPSAs!=null && !existingPSAs.isEmpty()){
                system.debug('CommunityMethods resendWelcomeEmailNow existingPSAs'+existingPSAs.size());
                Boolean hasChatter = false;
                for(PermissionSetAssignment psa:existingPSAs){
                    User communityUser = communityUserMap.get(psa.AssigneeId);
                    //only do this if the community user is logged in.  if you try to resend after they've logged in once, it will just prompt them to login and defeats the purpose
					//Added by Varun
                    if(communityUser!=null && communityUser.Community_User_First_Login__c == null){
                        if(communityUser.ProfileName__c == 'Customer Community Login User Clone'){
							PermissionSetAssignment newPSA = new PermissionSetAssignment(PermissionSetId=psa.PermissionSetId,AssigneeId=psa.AssigneeId);
							psaToInsert.add(newPSA);
							psaToDelete.add(psa);
							hasChatter = true;
							ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The Getting Started Welcome Email has been resent for this prospect.'}, false);  
						}else if(communityUser.ProfileName__c == 'CPA Customer Community Login User Clone'){
							PermissionSetAssignment newPSA = new PermissionSetAssignment(PermissionSetId=psa.PermissionSetId,AssigneeId=psa.AssigneeId);
							psaToInsert.add(newPSA);
							psaToDelete.add(psa);
							hasChatter = true;
							ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The Getting Started Welcome Email has been resent for this prospect.'}, false);  
						}
                   }
                    else if(communityUser!=null && communityUser.Community_User_First_Login__c != null){
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message.setTargetObjectId(communityUser.Id); 
                        message.setSenderDisplayName('Getting Started'); 
                        message.setReplyTo('noreply@salesforce.com');
                        message.setUseSignature(false); 
                        message.setBccSender(false); 
                        message.setSaveAsActivity(false); 
                        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Experience Cloud: Username Reminder Email'];
                        message.setTemplateID(emailTemplate.Id); 
                        message.toAddresses = new String[] { communityUser.Email};
                            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                        
                        if (results[0].success) {
                            hasChatter = true;
                            ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The prospect has been sent a reminder email containing a link to the Getting Started Portal login page and their username.'}, false);  
                            System.debug('The email was sent successfully.');
                        }else {
                            hasChatter = true;
                            ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The prospect does not have a username created, the Username Reminder email could not be sent. Please create a Getting Started Portal username before the reminder email is available.'}, false);
                            System.debug('The email failed to send: ' +  results[0].errors[0].message);
                        }
                        //hasChatter = true;
                        //ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The prospect has already logged in prior, the Getting Started Welcome Email could not be resent.'}, false);  
                    }
                }
                //delete existing assignments and insert new ones to retrigger welcome email
                if(!psaToDelete.isEmpty() && !psaToInsert.isEmpty()){
                    DmlHelper.performDML2(psaToDelete, DmlHelper.DML_DELETE, 'CommunitiesMethods', 'resendWelcomeEmailNow', 'deleting existing PSA', true);
                    DmlHelper.performDML2(psaToInsert, DmlHelper.DML_INSERT, 'CommunitiesMethods', 'resendWelcomeEmailNow', 'inserting new PSA', true);
                }//!existingPSAs.isEmpty()
                if(hasChatter){
                    ChatterMentionPost.postBatchFeedElements();
                }
            }//if(existingPSAs!=null &&
        }//if(ps!=null && communityUserMap!=null
    }//resendWelcomeEmailNow
    
    @future
    public static void updateCommunityUserEmailFuture(Id[] contactIds){
        system.debug('CommunityMethods in updateCommunityUserEmailFuture');
        updateCommunityUserEmailNow(contactIds);
    }
    
    public static void updateCommunityUserEmailNow(Id[] contactIds){
        system.debug('CommunityMethods in updateCommunityUserEmailNow');
        User[] updatedUsers = new User[]{};
        Boolean hasChatter = false;
        //get community users for contacts that changed
        Map<Id,User> communityUserMap = new Map<Id,User>([SELECT Id,Email,ContactId,Contact.Email,Community_User_First_Login__c 
                                                          FROM User WHERE ContactId in:contactIds AND IsActive=true AND Profile.Name = 'Customer Community Login User Clone']);
        for(User communityUser : communityUserMap.values()){
            if(communityUser.ContactId != null && communityUser.Contact.Email != communityUser.Email){
                communityUser.Email = communityUser.Contact.Email;
                updatedUsers.add(communityUser);
                hasChatter = true;
                ChatterMentionPost.createChatterMentionPost(communityUser.ContactId, new Id[]{UserInfo.getUserId()}, new String[]{'The email address for this prospect has been updated.  If you need to resend the Welcome Email, please use the Getting Started Resend Welcome Email checkbox.'}, false);  
            }
        }
        if(!updatedUsers.isEmpty()){
            DmlHelper.performDML2(updatedUsers, DmlHelper.DML_UPDATE, 'CommunitiesMethods', 'updateCommunityUserEmailNow', 'updating user emails', true);
        }//!existingPSAs.isEmpty()
        if(hasChatter){
            ChatterMentionPost.postBatchFeedElements();
        }
    }//updateCommunityUserEmailNow
    
    public static void chatterOldOwner(Map<Id,Id> priorOwnerByAcctId){
        for(Id acctId:priorOwnerByAcctId.keySet()){
            if(!Test.isRunningTest()){
                ChatterMentionPost.createChatterMentionPost(acctId, new Id[]{priorOwnerByAcctId.get(acctId)}, new String[]{'A community user has updated the zip code of this account, changing the owner.'}, false);   
            }
            else{
                postCreated = true;
            }
        }
        ChatterMentionPost.postBatchFeedElements();
    }
    
    //called from usertriggermethods, after insert
    public static void checkForOpportunity(Set<Id> accountIds){
        if (Test.isRunningTest() || System.isFuture() || System.isBatch()) {
            checkOppHasUserNow(accountIds);
        } else {
            checkOppHasUserFuture(accountIds);
        }
    }
    
    @future
    public static void checkOppHasUserFuture(Set<Id> accountIds){
        system.debug('in future');
        checkOppHasUserNow(accountIds);
    }
    
    public static void checkOppHasUserNow(Set<Id> accountIds){
        system.debug('in now');
        Opportunity[] oppsToUpdate = new Opportunity[]{};
            Opportunity[] opps = [SELECT Id, Has_Community_User__c FROM Opportunity 
                                  WHERE (RecordType.Name = 'PEO Opportunity Record Type' OR RecordType.Name = 'Prism PEO Opportunity Record Type') 
                                  AND AccountId in :accountIds AND CreatedDate = Last_N_DAYS:90];
        for(Opportunity opp:opps){
            if(!opp.Has_Community_User__c){
                opp.Has_Community_User__c = true;
                oppsToUpdate.add(opp);
            }
        }
        if(!oppsToUpdate.isEmpty()){
            DmlHelper.performDML2(oppsToUpdate, DmlHelper.DML_UPDATE, 'CommunitiesMethods', 'checkOppHasUserNow', 'updating opp checkbox', true);
        }
    }
    
    // Saves the PEO Checklist
    // Updates the submission times for each form if the form was saved and submitted
    public static Boolean savePeoOnboardingChecklist(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName, String className){ 
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
        if(peoOnbChecklist.Peo_Medical_formStatus__c == 'Complete' && peoOnbChecklist.Peo_Medical_formSubmissionTime__c == null) peoOnbChecklist.Peo_Medical_formSubmissionTime__c = local;
        
        User user = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        List<PEO_Onboarding_Checklist__c> checcklistsToSave = new List<PEO_Onboarding_Checklist__c>{peoOnbChecklist};
            return DMLHelper.performDML2(checcklistsToSave,DmlHelper.DML_UPDATE,className,'savePeoOnboardingChecklist',codeKey,true);
    }
    
    // Save a single PEO_Onboarding_Medical_Questionnaire__c record.
    // Updates the timestamp for a completed form if form is saved and submitted
    // Returns true on success false on failure
    public static Boolean saveMedicalQuestionnaire(PEO_Onboarding_Medical_Questionnaire__c rec, String formName, String className) {
        List<PEO_Onboarding_Medical_Questionnaire__c> recToUpdate = new List<PEO_Onboarding_Medical_Questionnaire__c>{rec};
        User user = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        return DMLHelper.performDML2(recToUpdate,DmlHelper.DML_UPDATE,className,'saveMedicalQuestionnaire',codeKey,true);
    }
    
    // save miltuple PEO_Onboarding_Medical_Questionnaire__c records.
    // Update the submission timestamp for each if the form is flagged as complete.
    // Returns true if all updates succeed, false if any fail
    public static Boolean saveMedicalQuestionnaires(List<PEO_Onboarding_Medical_Questionnaire__c> rec, String formName, String className) {
        if(rec!=null){            
            User user = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
            String codeKey = 'By '+ user.name + ' on form ' + formName;
            return DMLHelper.performDML2(rec,DmlHelper.DML_UPDATE,className,'saveMedicalQuestionnaire',codeKey,true);
        }
        return false;
    }
    
    public static PEO_Onboarding_Checklist__c getPEOOnboardingChecklist(Id accountId,PEO_Onboarding_Checklist__c oldChecklist, String formName, String className)
    {
        System.debug('CommunitiesAccountUpdateController getPEOOnboardingChecklist Account ID: '+accountId);
        User runningUser = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        String[] fldList = new String[]{};
            Schema.FieldSet oppFldSet = Schema.SObjectType.PEO_Onboarding_Checklist__c.fieldSets.Questionnaire_Fields;
        for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldList.add(fldName);
        }
        
        String queryString = 'SELECT '
            + String.join(fldList,',') 
            +' FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = \''+ accountId + '\' ORDER BY CreatedDate ASC LIMIT 1';
        
        List<PEO_Onboarding_Checklist__c> onbChecklist = new List<PEO_Onboarding_Checklist__c>();        
        onbChecklist = Database.query(queryString);
        
        if(onbChecklist.isEmpty()) return null;
        else return onbChecklist[0];
    }
    
    //Get the medical questionnaire
    public static PEO_Onboarding_Medical_Questionnaire__c getMedicalQuestionnaireForm(Id peoOnboardingChecklistId, String formName, String className) {
        User runningUser = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        List<Schema.FieldSetMember>  medQuestionnaireFieldSet = SObjectType.PEO_Onboarding_Medical_Questionnaire__c.FieldSets.questions.getFields();
        String[] fields = new String[]{};
            for (SChema.FieldSetMember field : medQuestionnaireFieldSet) {
                fields.add(field.getFieldPath());
            }
        
        String query = 'Select '+ String.join(fields,',')  + ' FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c=\'' + peoOnboardingChecklistId + '\'  LIMIT 1';
        
        List<PEO_Onboarding_Medical_Questionnaire__c> result = new List<PEO_Onboarding_Medical_Questionnaire__c>();
        PEO_Onboarding_Medical_Questionnaire__c[] recs;
        
        try {            
            recs = Database.query(query);
        } catch(Exception e) {
            CommunityMethods.logCommunityError(e, 'getMedicalQuestionnaireForm',className, formName, null);
        }
        
        for (PEO_Onboarding_Medical_Questionnaire__c lst : recs) {
            result.add(lst);
        }
        
        if (result.isEmpty()) {
            List<PEO_Onboarding_Checklist__c> checklists = new List<PEO_Onboarding_Checklist__c>([SELECT Id, Name, medical_coverage_carrier__c, medical_coverage_renewal_date__c, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id = :peoOnboardingChecklistId]);
            PEO_Onboarding_Medical_Questionnaire__c rec = new PEO_Onboarding_Medical_Questionnaire__c();
            rec.PEO_Onboarding_Checklist__c = peoOnboardingChecklistId;
            if(checklists.size() == 1 && checklists[0].Parent_PEO_Checklist__c != null) {
                rec.Current_PEO_Carrier_if_applicable__c = checklists[0].medical_coverage_carrier__c;
                rec.Renewal_date__c = checklists[0].medical_coverage_renewal_date__c;
            }
            String codeKey = 'By '+ runningUser.name + ' on form ' + formName;
            Boolean success = DMLHelper.performDML2(new List<PEO_Onboarding_Medical_Questionnaire__c>{rec},DmlHelper.DML_INSERT,className,'getMedicalQuestionnaireForm',codeKey,true);
            if (success) return rec;
            else return null;
        }
        return result.get(0);
    }
    
    public static IndustrySpecificWrap getIndustryDetails(String PEOchecklist, String peoIndustryTitle, String formName, String className){
        System.debug('PEOchecklist ID: '+ PEOchecklist + ' peoIndustryTitle: '+peoIndustryTitle);
        
        //SFDC-10790 APR APR0131036        
        Set<Id> checklistIDstoCreateIndWQs = new Set<Id>();
        
        User runningUser = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        IndustrySpecificWrap Iwrap = new IndustrySpecificWrap();
        List<WC_Questionnaire_Industry_Specific__c> returnData;
        String IndustryName;
        string IndustryId;
        Boolean requiredWithFastPass;
        List<String> fldList = new List<String>();
        Schema.FieldSet fieldSetObj;
        
        // filters special characters from industry names
        if(peoIndustryTitle != null) {
            IndustryName = peoIndustryTitle.replace(' ','_').replace('\'','').replace('/','_').replace('(','').replace(')','');
            IndustryId = peoIndustryTitle;
        }
        System.debug('IndustryName: '+ IndustryName + '\nIndustryId: '+IndustryId);
        if(String.isNotBlank(IndustryName)){
            // some industry names are longer than 40 chars. Restrict the passed in industry name to only grab the first
            // 40 chars if that is the case then get the field set
            String indName = (IndustryName.length() > 40 ? IndustryName.left(40) : IndustryName);
            indName = indName.removeEnd('_');
            fieldSetObj = Schema.SObjectType.WC_Questionnaire_Industry_Specific__c.fieldSets.getMap().get(indName);
        }
        
        // build the fieldset list
        if(fieldSetObj!=null){
            for (Schema.FieldSetMember fsm : fieldSetObj.getFields()) {
                String fldName = fsm.getFieldPath();
                fldList.add(fldName);
            }
        }
        
        // if we have a list of fields for the current industry build the query and return the 
        // acquired record
        if(fldList != null && fldList.size() > 0) {
            string queryString = 'SELECT ';
            queryString += String.join(fldList,',');
            queryString +=' ,RecordType.Name FROM WC_Questionnaire_Industry_Specific__c ';
            queryString +=' WHERE PEO_Underwriting_Checklist__c = :PEOchecklist';
            queryString +=' AND RecordType.Name =:IndustryId';            
            returnData = Database.query(queryString);
            System.debug('IndustryId: '+IndustryId);
            System.debug('IndustryName: '+IndustryName);
            if(returnData != null && returnData.size() > 0) {
                Iwrap.industryRec = returnData[0];
            } else {
                String RecordTypeId = (String)Schema.SObjectType.WC_Questionnaire_Industry_Specific__c.getRecordTypeInfosByName().get(IndustryId).getRecordTypeId();
                WC_Questionnaire_Industry_Specific__c Rec = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=PEOchecklist); 
                Rec.RecordTypeId = RecordTypeId;
                String codeKey = 'By '+ runningUser.name + ' on form ' + formName;
                Boolean success = DMLHelper.performDML2(new List<WC_Questionnaire_Industry_Specific__c>{Rec},DmlHelper.DML_INSERT,className,'getIndustryDetails',codeKey,true);
                
                if (success) {
                    Iwrap.industryRec = rec;
                    // add the checklist ID to the set for new ind wqs
                    checklistIDstoCreateIndWQs.add(PEOchecklist);
                }
            }
            
            Iwrap.IndustryType = IndustryName;
            Iwrap.IndustryTypeId = (String)Schema.SObjectType.WC_Questionnaire_Industry_Specific__c.getRecordTypeInfosByName().get(IndustryId).getRecordTypeId();
            Iwrap.requiredWithFastPass = requiredWithFastPass;
            
            // call the future method to create the Industry Specific Work Queue async
            if (!checklistIDstoCreateIndWQs.isEmpty()) createIndSpecificWQFuture(checklistIDstoCreateIndWQs);
            if(Iwrap != null) return Iwrap;
        }
        return null;
    }
    
    public class IndustrySpecificWrap{
        @AuraEnabled public WC_Questionnaire_Industry_Specific__c industryRec {get;set;}
        @AuraEnabled public String IndustryType {get;set;}
        @AuraEnabled public String IndustryTypeId {get;set;}
        @AuraEnabled public Boolean requiredWithFastPass {get;set;}
        public IndustrySpecificWrap(){
            industryRec = new WC_Questionnaire_Industry_Specific__c();
        }
    }
    
    public static Map<Id, Account[]> getAccountInformation(Set<Id> startingIds, String formName, String className){
        try {
            return getAccountInformation(startingIds);
        } catch(Exception e) {
            CommunityMethods.logCommunityError(e, 'getPEOOnboardingChecklist',className, formName, null);
            throw e; // not sure if throwing is the right thing to do
        }
    }
    
    public static Map<Id, Account[]> getAccountInformation(Set<Id> startingIds) {
        try {
            Map<Id, Account[]> returnMap = new Map<Id, Account[]>();
            if (startingIds == null || startingIds.isEmpty()) return returnMap;
            Set<Id> userIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> checklistIds = new Set<Id>();
			
            Schema.FieldSet oppFldSet = Schema.SObjectType.Account.fieldSets.PEO_Edge_Form_Fields;      
            Set<String> fieldSet = new Set<String>();
            DMLHelper.addFieldsToSet(oppFldSet, '', fieldSet);
            String baseQuery = DMLHelper.buildQueryFromSet(fieldSet, 'Account');
            for (Id startingId : startingIds) {
                Schema.SObjectType startingIdType = Id.valueOf(startingId).getsobjecttype();
                if(startingIdType == ((SObject) Type.forName('User').newInstance()).getSObjectType()) {
                    userIds.add(startingId);
                } else if(startingIdType == ((SObject) Type.forName('Contact').newInstance()).getSObjectType()) {
                    contactIds.add(startingId);
                } else if(startingIdType == ((SObject) Type.forName('Account').newInstance()).getSObjectType()) {
                    accountIds.add(startingId);
                } else if(startingIdType == ((SObject) Type.forName('PEO_Onboarding_Checklist__c').newInstance()).getSObjectType()) {
                    checklistIds.add(startingId);
                }
            }

            Map<Id, Set<Id>> accountIdsAndStartingIds = new Map<Id, Set<Id>>();
            if (!userIds.isEmpty()) {
                for (User sourceUser : [SELECT Id, ContactId, Contact.AccountId FROM User where ID in :userIds]) {
                    Set<Id> sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceUser.Contact.AccountId);
                    if ( sourceRecordsForAccount == null) {
                        accountIdsAndStartingIds.put(sourceUser.Contact.AccountId, new Set<Id>());
                        sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceUser.Contact.AccountId);
                    }
                    sourceRecordsForAccount.add(sourceUser.Id);
                }
            }

            if (!contactIds.isEmpty()) {
                for (Contact sourceRecord : [SELECT Id, Name, AccountId FROM Contact WHERE Id IN :contactIds]) {
                    Set<Id> sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceRecord.accountId);
                    if ( sourceRecordsForAccount == null) {
                        accountIdsAndStartingIds.put(sourceRecord.accountId, new Set<Id>());
                        sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceRecord.accountId);
                    }
                    sourceRecordsForAccount.add(sourceRecord.Id);
                }
            }

            if (!checklistIds.isEmpty()) {
                for (PEO_Onboarding_Checklist__c sourceRecord : [SELECT ID,Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]) {
                    Set<Id> sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceRecord.Prospect_Client__c);
                    if ( sourceRecordsForAccount == null) {
                        accountIdsAndStartingIds.put(sourceRecord.Prospect_Client__c, new Set<Id>());
                        sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceRecord.Prospect_Client__c);
                    }
                    sourceRecordsForAccount.add(sourceRecord.Id);
                }
            }

            if (!accountIds.isEmpty()) {
                for (Id sourceId : accountIds) {
                    Set<Id> sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceId);
                    if ( sourceRecordsForAccount == null) {
                        accountIdsAndStartingIds.put(sourceId, new Set<Id>());
                        sourceRecordsForAccount = accountIdsAndStartingIds.get(sourceId);
                    }
                    sourceRecordsForAccount.add(sourceId);
                }
            }

            List<Account> allAccounts;
            if (!accountIdsAndStartingIds.isEmpty()) {
                Set<Id> matchKeys = accountIdsAndStartingIds.keySet();
                // also get the child accounts
                String childSubQuery = baseQuery;
                String checklistQuery = ' (SELECT Id, Select_Child_Accounts__c, Child_Account_Ids__c from PEO_Onboarding_Checklists__r) ';
                childSubQuery = childSubQuery.replace('From Account', 'FROM Sales_Parent__r');
                baseQuery = baseQuery.replace(' From Account ', ', (' + childSubQuery + '), ' + checklistQuery + ' FROM Account WHERE ID IN :matchKeys OR salesParent__c IN :matchKeys');
                allAccounts = Database.query(baseQuery);
            }

            if (allAccounts != null && !allAccounts.isEmpty()) {
                for (Account targetAccount : allAccounts) {
                    Set<Id> sourceRecordsForAccount = accountIdsAndStartingIds.get(targetAccount.Id);
                    if(sourceRecordsForAccount == null) continue;
                    for (Id sourceRecordId : sourceRecordsForAccount) {
                        if (returnMap.get(sourceRecordId) == null) {
                            returnMap.put(sourceRecordId, new List<Account>());
                        }
                        List<Account> accountsForSource = returnMap.get(sourceRecordId);
                        if (targetAccount.isParent__c) {
                            accountsForSource.add(targetAccount);
                            boolean hasAChecklist = targetAccount.PEO_Onboarding_Checklists__r != null;
                            PEO_Onboarding_Checklist__c chk = targetAccount.PEO_Onboarding_Checklists__r;
                            Boolean hasOnlySomeChildren = hasAChecklist && chk.Select_Child_Accounts__c == 'No';
                            if (hasOnlySomeChildren) {
                                List<String> childAccIds = chk.Child_Account_Ids__c.split(';');
                                for(Account chldAcc : targetAccount.Sales_Parent__r){
                                    if(childAccIds.contains(chldAcc.Id)){
                                        accountsForSource.add(chldAcc);
                                    }
                                }
                            } else {
                                accountsForSource.addAll(targetAccount.Sales_Parent__r);
                            } 
                        }
                        else {
                            accountsForSource.add(targetAccount);
                        }
                    }
                }
            }
            return returnMap;
        }catch(Exception e) {
            throw e;
        }
    }
    
    public static Account[] getAccountInformation(String startingId, String formName, String className){
        try {
            return communityMethods.getAccountInformation(startingId);
        } catch(Exception e) {
            CommunityMethods.logCommunityError(e, 'getPEOOnboardingChecklist',className, formName, null);
        }
        return null;
    }
    
    public static Account[] getAccountInformation(String startingId) {
        System.debug('getAccountInformation Starting ID: ' + startingId + ' ID type: '+Id.valueOf(startingId).getsobjecttype());
        
        // build the field set and base query
        Schema.FieldSet oppFldSet = Schema.SObjectType.Account.fieldSets.PEO_Edge_Form_Fields;      
        Set<String> fieldSet = new Set<String>();
        DMLHelper.addFieldsToSet(oppFldSet, '', fieldSet);
        String baseQuery = DMLHelper.buildQueryFromSet(fieldSet, 'Account');
        
        // build the account storage
        Schema.SObjectType startingIdType = Id.valueOf(startingId).getsobjecttype();
        Account parentAcc;
        List<Account> accounts;
        String parentQuery;
        
        // if the starting ID passed in a user record ID(this would only happen if the form is being accessed from the portal)
        if(startingIdType == ((SObject) Type.forName('User').newInstance()).getSObjectType())
        {
            User runningUser = [SELECT Id, Name, ContactId, Contact.AccountId FROM User WHERE Id=:startingId];
            
            if(runningUser.ContactId != null) { 
                parentQuery = baseQuery + 'WHERE Id = \''+ runningUser.Contact.AccountId + '\' LIMIT 1';
            }
        }
        
        // if the starting ID is an account ID
        if(startingIdType == ((SObject) Type.forName('Account').newInstance()).getSObjectType())
        {   
            parentQuery = baseQuery + ' WHERE Id = \''+ startingId + '\' LIMIT 1';
        }
        
        // if the starting ID is a contact ID(This will only happen when accessing the from from the convertContact screen)
        if(startingIdType == ((SObject) Type.forName('Contact').newInstance()).getSObjectType()) {
            Contact con = [SELECT Id, Name, AccountId FROM Contact WHERE Id = :startingId];
            parentQuery = baseQuery + ' WHERE Id = \''+  con.AccountId + '\' LIMIT 1';
        }
        
        // if the starting ID is a PEO UW Checklist ID. This is for the Analyst/NBSC to access the forms off the 
        // checklist. See navigateToCommunityForms.cmp & PEO UW DOcument button on checklist layout
        if(startingIdType == ((SObject) Type.forName('PEO_Onboarding_Checklist__c').newInstance()).getSObjectType()) {
            PEO_Onboarding_Checklist__c chk = [SELECT ID,Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Id=:startingId LIMIT 1];
            parentQuery = baseQuery + ' WHERE Id = \''+ chk.Prospect_Client__c + '\' LIMIT 1';
        }
        
        
        // if the parent query was succesfully created
        // query for and set the accounts.
        //system.debug('parentQuery:'+parentQuery);
        if (parentQuery != null) {
            accounts = Database.query(parentQuery);
            parentAcc = accounts.get(0);   
        }
        
        // If the prospect assigned to the parent account variable is a parent get its children and
        // add them to the return list
        if(parentAcc != null && parentAcc.isParent__c) {
            String childAccQuery = baseQuery + ' WHERE SalesParent__c = \''+ parentAcc.Id + '\'';
            
            Account[] childAccounts = Database.query(childAccQuery);
            PEO_Onboarding_Checklist__c chkList = [select Id, Select_Child_Accounts__c, Child_Account_Ids__c from PEO_Onboarding_Checklist__c where Prospect_Client__c =: parentAcc.Id];
            if(chkList.Select_Child_Accounts__c != null && chkList.Select_Child_Accounts__c == 'No'){
                List<String> childAccIds = chkList.Child_Account_Ids__c.split(';');
                system.debug('++ '+childAccIds);
                for(Account chldAcc : childAccounts){
                    system.debug('++ Id : '+ chldAcc.Id);
                    if(childAccIds.contains(chldAcc.Id)){
                        accounts.add(chldAcc);
                    }
                }
            }else{
                for (Account chldAcc : childAccounts) accounts.add(chldAcc);
            }
        }
        
        // will return null if no accounts are assigned through the queries or loops above
        return accounts;
    }
    
    @AuraEnabled
    public static string getIndustrySpecificStatus(String PEOchecklist) {
        
        List<WC_Questionnaire_Industry_Specific__c> wcIndSpecifics = new List<WC_Questionnaire_Industry_Specific__c>([SELECT Id, Name, Peo_IndSpecific_formStatus__c FROM WC_Questionnaire_Industry_Specific__c WHERE PEO_Underwriting_Checklist__c = :PEOchecklist]);
        for(WC_Questionnaire_Industry_Specific__c indSpecific : wcIndSpecifics) {
            if(indSpecific.Peo_IndSpecific_formStatus__c != 'Complete') {
                return '';
            }
        }
        if(wcIndSpecifics.isEmpty()){
            return '';
        }
        else{
            return 'Complete';
        }
    }
    
    public static void logCommunityError(Exception e, String method, String className, String formName, List<SObject> objs) {
        User runningUser = UserHelper.getRunningUser();
        for (SObject o : objs) {
            communityMethods.logCommunityError(e, method, className, formName, o, runningUser);
            break;
        }
    }
    
    // takes the class, method, and sObject attempted to be saved and logs the error passed
    public static void logCommunityError(Exception e, String method, String className, String formName, SObject obj, User runningUser) {
        User user = (runningUser == null ? UserHelper.getRunningUser() : runningUser);
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        ErrorLog.logError(className, className + ': ' + method, codeKey, obj.Id, e, obj, true);
    }
    
    // update each checklist for the related notSoldOpps to a status of abandoned
    /*@future
    public static void updateChecklistStepForNotSoldOppty(Set<Id> opptyIds, String formName) {
        System.debug('AE updateChecklistStepForNotSoldOppty '+ opptyIds + ' ' + formName);
        List<PEO_Onboarding_Checklist__c> checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c in :opptyIds];
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            chk.Current_Step__c ='Abandoned';
            if (chk.Abandoned_Status_Date__c == null) chk.Abandoned_Status_Date__c  = System.now();
        }
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        DMLHelper.performDML2(checklists,DmlHelper.DML_UPDATE,'CommunityMethods','updateChecklistStepForNotSoldOppty',codeKey,true);
    }*/
    
    @future
    public static void updateChecklistStepForLostOppty(Set<Id> opptyIds, String formName) {
        System.debug('JDA updateChecklistStepForLostOppty '+ opptyIds + ' ' + formName);
        List<PEO_Onboarding_Checklist__c> checklists = [SELECT Id, Current_Step__c, Abandoned_Status_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c in :opptyIds];
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            chk.Current_Step__c ='Lost';
            //if (chk.Abandoned_Status_Date__c == null) chk.Abandoned_Status_Date__c  = System.now();
        }
        System.debug('JDA checklists '+checklists);
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        DMLHelper.performDML2(checklists,DmlHelper.DML_UPDATE,'CommunityMethods','updateChecklistStepForLostOppty',codeKey,true);
    }
    
    //JDA sfdc-10804
    @future
    public static void updChecklistForOpptyStageChange(Set<Id> opptyIds, String formName) {
        System.debug('JDA updChecklistForOpptyStageChange '+ opptyIds + ' ' + formName);
        List<PEO_Onboarding_Checklist__c> checklists = [SELECT Id, Opportunity_to_Discovery_Date__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c in :opptyIds];
        System.debug('JDA updChecklistForOpptyStageChange checklists '+checklists);
        if(checklists.size()!=0){
            for (PEO_Onboarding_Checklist__c chk : checklists) {
                if(chk.Opportunity_to_Discovery_Date__c == null){
                    chk.Opportunity_to_Discovery_Date__c = Datetime.now();
                }
                else{
                    System.debug('JDA updChecklistForOpptyStageChange :Opportunity to Discovery Date already exists and hence the field is not updated');
                }
            } 
        }
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        DMLHelper.performDML2(checklists,DmlHelper.DML_UPDATE,'CommunityMethods','updChecklistForOpptyStageChange',codeKey,true);
    }
    
    public static void updateChecklistOwnerWithOptyOwner(Set<Id> opptyIds, String formName) {
        if (Utilities.allowFuture()) {
            updateChecklistOwnerWithOptyOwnerFuture(opptyIds,formName);
        } else {
            updateChecklistOwnerWithOptyOwnerNow(opptyIds,formName);
        }
    } // updateChecklistOwnerWithOptyOwner
    
    @future
    public static void updateChecklistOwnerWithOptyOwnerFuture(Set<Id> opptyIds, String formName) {
       updateChecklistOwnerWithOptyOwnerNow(opptyIds, formName);
    } // updateChecklistOwnerWithOptyOwnerFuture
        
    public static void updateChecklistOwnerWithOptyOwnerNow(Set<Id> opptyIds, String formName) {
        System.debug('JDA updateChecklistOwnerWithOptyOwner '+ opptyIds + ' ' + formName);
        Map<Id, Opportunity> OptyMap = new Map <Id, Opportunity>();
        List<PEO_Onboarding_Checklist__c> checklists = [SELECT Id, Current_Step__c, Opportunity__c,Sales_Rep__c FROM PEO_Onboarding_Checklist__c WHERE Opportunity__c in :opptyIds];
        List<Opportunity> optys = [SELECT Id,OwnerId FROM Opportunity WHERE Id in :opptyIds];
        for (Opportunity opty : optys) {
            OptyMap.put(opty.Id, opty);
        }
        for (PEO_Onboarding_Checklist__c chk : checklists) {
            chk.Sales_Rep__c = OptyMap.get(chk.Opportunity__c).OwnerId;
            //if (chk.Abandoned_Status_Date__c == null) chk.Abandoned_Status_Date__c  = System.now();
        }
        String codeKey = 'By '+ user.name + ' on form ' + formName;
        DMLHelper.performDML2(checklists,DmlHelper.DML_UPDATE,'CommunityMethods','updateChecklistOwnerWithOptyOwner',codeKey,true);
    }
    
    
    static final String completeStatus = 'Complete';
    
    //Checks to see if all areas of the checklist are completed.
    @future
    public static void checkIfChecklistCompleteFuture(Set<Id> checklistIds, String formUpdated){
        system.debug('in future');
        checkIfChecklistComplete(checklistIds, formUpdated);
    }
    
    public static void checkIfChecklistComplete(Set<Id> checklistIds, String formUpdated){
        Map<Id, PEO_Onboarding_Checklist__c> parentsMissingInfo = new Map<Id, PEO_Onboarding_Checklist__c>();
        Map<Id, PEO_Onboarding_Checklist__c> checklistMap = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Last_Change_Made__c, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]);
        List<Id> parentIds = new List<Id>();
        List<Id> childNeedsDocsChecked = new List<Id>();
        List<String> naicsCodes = new List<String>();
        
        //Always check against the parent checklist
        for(PEO_Onboarding_Checklist__c checklist : checklistMap.values()) {
            if(!String.isEmpty(checklist.Parent_PEO_Checklist__c)) {
                parentIds.add(checklist.Parent_PEO_Checklist__c);
            }
            else {
                parentIds.add(checklist.Id);
            }
        }
        
        Map<Id, PEO_Onboarding_Checklist__c> parentChecklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Last_Change_Made__c, Prospect_Client__c, Prospect_Client__r.NAICS_Code__c, Medical_Benefits_Underwriting_Requested__c,
                                                                                                          CensusRequired__c, Claims_Report_required__c, Health_Insurance_Renewal_required__c, Health_Insurance_Summary_required__c, Health_Invoice_required__c, 
                                                                                                          Loss_Runs_required__c, Miscellaneous_Docs_Required__c, Miscellaneous_Docs_Required_WC__c, Payroll_Register_Required__c, 
                                                                                                          SUI_Required__c, WCClassesWages_Required__c, WC_Declarations_Required__c, CS_CM_Contract_Status__c,
                                                                                                          Peo_WC_formStatus__c, Peo_EPLI_formStatus__c, Peo_401k_formStatus__c, Peo_Covid_formStatus__c, 
                                                                                                          Peo_Medical_formStatus__c,Peo_IndSpecific_formStatus__c,
                                                                                                          (SELECT Id, Name, PEO_Doc_Required__c FROM PEO_Onboarding_Documents__r WHERE PEO_Doc_Required__c = 'Needed' AND Date_Uploaded__c = null),
                                                                                                          (SELECT Id, Name FROM PEO_Underwriting_Checklists__r)                                                  
                                                                                                          FROM PEO_Onboarding_Checklist__c WHERE Id IN :parentIds]);
        
        for(PEO_Onboarding_Checklist__c checklist : parentChecklists.values()) {
            
            //Checking form status for WC, EPLI, and 401k,medical,industry
            if(checklist.Peo_WC_formStatus__c != completeStatus || checklist.Peo_EPLI_formStatus__c != completeStatus || 
                checklist.Peo_401k_formStatus__c != completeStatus || checklist.Peo_Medical_formStatus__c != completeStatus || 
                checklist.Peo_IndSpecific_formStatus__c != completeStatus) {
                parentsMissingInfo.put(checklist.Id, checklist);
                parentChecklists.remove(checklist.Id);
                continue;
            }
            
            
            //Check documents for missing uploads.
            if(checklist.PEO_Onboarding_Documents__r != null && checklist.PEO_Onboarding_Documents__r.size() > 0) {
                System.debug('MGF CommunityMethods checklist.PEO_Onboarding_Documents__r.size()='+checklist.PEO_Onboarding_Documents__r.size());
                parentsMissingInfo.put(checklist.Id, checklist);
                parentChecklists.remove(checklist.Id);
                continue;
            }
            //If this is a parent chhecklists, add the child checklist to a list to have its own docs checked.
            else if(checklist.PEO_Underwriting_Checklists__r != null && checklist.PEO_Underwriting_Checklists__r.size() > 0) {
                for(PEO_Onboarding_Checklist__c childChecklist : checklist.PEO_Underwriting_Checklists__r) {
                    childNeedsDocsChecked.add(childChecklist.Id);
                }   
            }
            
            //Add the NAICS Code of the Account to a list in order to be checked later.
            if(checklist.Prospect_Client__c != null && !String.isEmpty(checklist.Prospect_Client__r.NAICS_Code__c) && !naicsCodes.contains(checklist.Prospect_Client__r.NAICS_Code__c)) {
                naicsCodes.add(checklist.Prospect_Client__r.NAICS_Code__c);
            }
        }
        
        //Check the child checklists to make sure they have all their docs.
        if(!childNeedsDocsChecked.isEmpty()) {
            checkDocuments(childNeedsDocsChecked, parentChecklists, parentsMissingInfo);
        }
        
        //Check for Covid Questionnaire
        if(!naicsCodes.isEmpty()) {
            checkForCovidQuestionnaire(naicsCodes, parentChecklists, parentsMissingInfo);
        }
        
        //For any checklists that have passes all of the aboce tests, clear out then Last_Change_Made__c field.
        //Check if the running user belongs to Sales Enablement, System Administrator,System Administrator API-ClientSpace
        Id curUserProfId =userinfo.getProfileId();
        List<String> limitedProfileNames = new List<String>{'System Administrator API-ClientSpace','System Administrator','Sales Enablement'};
        List<Profile> limitedProfiles = [SELECT Id, Name FROM Profile WHERE Name IN:limitedProfileNames];
        boolean isAdminUser = false;
        for(Profile prof: limitedProfiles){
            if(prof.id == curUserProfId){
                isAdminUser = true;
            }
        }
        Map<Id, PEO_Onboarding_Checklist__c> checklistsNeedingUpdate = new Map<Id, PEO_Onboarding_Checklist__c>();
        for(PEO_Onboarding_Checklist__c checklistIsComplete : parentChecklists.values()) {
            if(checklistIsComplete.Last_Change_Made__c != null) {
                checklistIsComplete.Last_Change_Made__c = null;
                checklistsNeedingUpdate.put(checklistIsComplete.Id, checklistIsComplete);
            }
        }
        system.debug('checklistNotComplete:'+parentsMissingInfo.keySet());
        //For any checklists that failed the above tests & checklists that don't already have a cs cm uw status
        // set Last_Change_Made__c to be the current date.
        system.debug('isAdminUser:'+isAdminUser);
        for(PEO_Onboarding_Checklist__c checklistNotComplete : parentsMissingInfo.values()) {
            //Boolean accIsProspect = checklistNotComplete.CS_CM_Contract_Status__c == 'Prospect';
            if(!isAdminUser){
                checklistNotComplete.Last_Change_Made__c = DateTime.now();
            }
            checklistsNeedingUpdate.put(checklistNotComplete.Id, checklistNotComplete);
        }
        
        //Update checklists needing updates.
        if(!checklistsNeedingUpdate.isEmpty()) {
            DmlHelper.performDML2(checklistsNeedingUpdate.values(), DmlHelper.DML_UPDATE, 'CommunityMethods', 'checkIfChecklistComplete', 'Updating Checklist change date. Edit came from: ' + formUpdated, true);
        }
    }
    
    //Checks to see if COVID Questionnaire needs to be completed. 
    public static void checkForCovidQuestionnaire(List<String> naicsCodes, Map<Id, PEO_Onboarding_Checklist__c> parentChecklists, Map<Id, PEO_Onboarding_Checklist__c> parentsMissingInfo) {
        Map<String, Boolean> covidMap = new Map<String, Boolean>();
        
        //Get COVID_Questionnaire_Required__c for each NAICS code.
        List<WC_NAICS_To_Industry_Map__c> naicsList = new List<WC_NAICS_To_Industry_Map__c>([SELECT Id, Name, COVID_Questionnaire_Required__c FROM WC_NAICS_To_Industry_Map__c WHERE Name IN :naicsCodes]);
        for(WC_NAICS_To_Industry_Map__c naics : naicsList) {
            if(!covidMap.containsKey(naics.Name)) {
                covidMap.put(naics.Name, naics.COVID_Questionnaire_Required__c);
            }
        }
        
        //For each checklist, if COVID is needed based on NAICS code, check the COVID status.
        for(PEO_Onboarding_Checklist__c checklist : parentChecklists.values()) {
            if(checklist.Prospect_Client__c != null) {
                String naicsCode = checklist.Prospect_Client__r.NAICS_Code__c;
                if(naicsCode != null && covidMap.containsKey(naicsCode)) {
                    Boolean covidRequired = covidMap.get(naicsCode);
                    if(covidRequired && checklist.Peo_Covid_formStatus__c != completeStatus) {
                        parentsMissingInfo.put(checklist.Id, checklist);
                        parentChecklists.remove(checklist.Id);
                    }
                }
            }
        }
    }
    
    //Checks to see if all child checklists have their documents uploaded.
    public static void checkDocuments(List<Id> childNeedsDocsChecked, Map<Id, PEO_Onboarding_Checklist__c> parentChecklists, Map<Id, PEO_Onboarding_Checklist__c> parentsMissingInfo) {
        System.debug('MGF CommunityMethods checkDocuments');
        Map<Id, PEO_Onboarding_Checklist__c> childChecklists = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Name, Prospect_Client__c, Parent_PEO_Checklist__c, 
                                                                                                         (SELECT Id, Name, PEO_Doc_Required__c FROM PEO_Onboarding_Documents__r WHERE PEO_Doc_Required__c = 'Needed' AND Date_Uploaded__c = null)
                                                                                                         FROM PEO_Onboarding_Checklist__c WHERE Id IN :childNeedsDocsChecked]);
        
        for(PEO_Onboarding_Checklist__c childChecklist : childChecklists.values()) {
            
            //If the child has any missing docs, the parent checklist needs to be updated.
            if(childChecklist.PEO_Onboarding_Documents__r != null && childChecklist.PEO_Onboarding_Documents__r.size() > 0) {
                Id checklistMissingInfo = childChecklist.Parent_PEO_Checklist__c;
                if(parentChecklists.containsKey(checklistMissingInfo)) {
                    PEO_Onboarding_Checklist__c parentChecklist = parentChecklists.get(checklistMissingInfo);
                    if(parentChecklist != null) {
                        parentsMissingInfo.put(parentChecklist.Id, parentChecklist);
                        parentChecklists.remove(parentChecklist.Id);
                    }
                }
            }
        }
    }
    
    @future
    public static void createIndSpecificWQFuture(Set<Id> checklistIds) {
        System.debug('Creating ind specific WQ -checklistIds:  ' + checklistIds);
        // if the set isn't empty send the call
        if (checklistIds != null && !checklistIds.isEmpty()) {
            createIndSpecificWQForChecklistIDs(checklistIds);
        }
    }
    
    // pass the provided set of checklsit IDs to clientSpaceHelper.checkIndustrySpecificAfterChecklist
    // which creates the WQs for each industry record using the checklistId it's assigned to
    public static void createIndSpecificWQForChecklistIDs(Set<Id> checklistIds) {
        // query checklsits and save to map of Id to checklist record
        Map<Id,PEO_Onboarding_Checklist__c> checklistMap = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Id IN :checklistIds]);
        
        // pass to method it handles errors
        if (!Test.isRunningTest() && !checklistMap.isEmpty() ) clientSpaceHelper.checkIndustrySpecificAfterChecklist(checklistMap);
    }
    
    // Updates the parent/single id checklist to remove an old industry that isn't needed anymore in the Industry_Record_Types__c field
    // and deletes the WC_Questionnaire_Industry_Specific__c for the industry that was removed from the cheklsit
    public static void updateExistingChkIsqRecTypesAndDeleteOldRecs(Map<Id, Set<String>> acctToOldNaics, Map<Id, Set<String>> acctToNewNaics, Set<String> allNaicsSet) {
        // get all the checcklists
        Map<Id, PEO_Onboarding_Checklist__c> chkToIdMap = new Map<Id, PEO_Onboarding_Checklist__c>([SELECT Id, Industry_Record_Types__c,Prospect_Client__c
                                                                                                   FROM PEO_Onboarding_Checklist__c
                                                                                                   WHERE Prospect_Client__c IN :acctToOldNaics.keySet()]);
        
        // if there are no checklists don't waste time with the remaining logic
        if (chkToIdMap != null && chkToIdMap.isEmpty()) return;
        
        // get all the wc Naics mapping records
        // Loop maps Naics req by naics code from req
        // EX: { 1111111: WC_NAICS_To_Industry_Map__c(name=1111111, peo_ind_title__c='Dr offiecs', etc...) };
        Map<String, WC_NAICS_To_Industry_Map__c> naicsCodeToNaicsRecMap = new Map<String, WC_NAICS_To_Industry_Map__c>();
        for (WC_NAICS_To_Industry_Map__c naicRec : [SELECT Id, Name, PEO_Industry_Title__c FROM WC_NAICS_To_Industry_Map__c WHERE Name IN :allNaicsSet]) {
            naicsCodeToNaicsRecMap.put(naicRec.name, naicRec);
        }
        
        List<PEO_Onboarding_Checklist__c> chkToUpdateList = new List<PEO_Onboarding_Checklist__c>();
        Map<Id, Set<String>> chkIndustriesToDelete = new Map<Id, Set<String>>(); // => {chkId: [Dr Offices]}
        Map<Id, Set<String>> chkIndustriesToInsert = new Map<Id, Set<String>>(); // => {chkId: [Construction]}
        
        // iterate the checklsits and update the ISQ to insert set and ISQ to delete set to contain only
        // the industries that need to be removed/inserted respectively
        for (PEO_Onboarding_Checklist__c chk : chkToIdMap.values()) {
            // get the ISQ rec type field => [Manufacturing, Drs Office]
            List<String> isqRecTypesList = (chk.Industry_Record_Types__c != null ? chk.Industry_Record_Types__c.Split('!.!') : new List<String>() );
            // get the old naic values for the account on this checklist => oldcodes = 222222(Dr Office)
            Set<String> listOFOldNaicsToRemove = acctToOldNaics.get(chk.Prospect_Client__c);
            // get the new naic values for the account on this checklist => New Code = 333333(Construction)
            Set<String> listOFNewNaicsToAdd = acctToNewNaics.get(chk.Prospect_Client__c);
            Boolean chkUpdated = false;
            System.debug('isqRecTypesList: '+isqRecTypesList);
            // iterate over the old values and add them to the remove list if they exist for the checklist
            for (String oldCode : listOFOldNaicsToRemove) {
                WC_NAICS_To_Industry_Map__c oldCodeRecord = naicsCodeToNaicsRecMap.get(oldCode);
                System.debug('oldCodeRecord: '+oldCodeRecord);
                System.debug('oldCode: '+oldCode);
                // remove each instane of a matched industry from SIQ rec type field => [Manufacturing]
                // add mapping of chk id to list of ISQ types to delete if one was removed
                Integer indexOfOldInd = -1;
                if (oldCodeRecord != null) indexOfOldInd = isqRecTypesList.indexOf(oldCodeRecord.PEO_Industry_Title__c);
                if (indexOfOldInd != -1 ) {
                    Set<String> trackedIndsToRemove = chkIndustriesToDelete.get(chk.Id);
                    if (trackedIndsToRemove == null) {
                        trackedIndsToRemove = new Set<String>();
                        chkIndustriesToDelete.put(chk.Id, trackedIndsToRemove);
                    }
                    trackedIndsToRemove.add(isqRecTypesList[indexOfOldInd]);
                    System.debug('To Remove '+trackedIndsToRemove);
                    chkIndustriesToDelete.put(chk.Id, trackedIndsToRemove);
                    
                     isqRecTypesList.remove(indexOfOldInd);
                    // add nbool flag to reqquire update
                    chkUpdated = true;
                }
            }
            
            System.debug('listOFNewNaicsToAdd: '+listOFNewNaicsToAdd);
            // iterate the new naics to add and add it's title to the set to be inserted for the chk
            // insert method later matches on already existing ISQ and only inserts ones that don't exist
            for (String oldCode : listOFNewNaicsToAdd) {
                WC_NAICS_To_Industry_Map__c newCodeRecord = naicsCodeToNaicsRecMap.get(oldCode);
                // remove each instane of a matched industry from SIQ rec type field => [Manufacturing]
                // add mapping of chk id to list of ISQ types to delete if one was removed
                Integer indexOfNewInd = -1;
                if (newCodeRecord != null) indexOfNewInd = isqRecTypesList.indexOf(newCodeRecord.PEO_Industry_Title__c);
                if (indexOfNewInd == -1 ) {
                    Set<String> trackedIndsToAdd = chkIndustriesToInsert.get(chk.Id);
                    if (trackedIndsToAdd == null) {
                        trackedIndsToAdd = new Set<String>();
                        chkIndustriesToInsert.put(chk.Id, trackedIndsToAdd);
                    }
                    if (newCodeRecord != null) {
                        trackedIndsToAdd.add(newCodeRecord.PEO_Industry_Title__c);
                        chkIndustriesToInsert.put(chk.Id, trackedIndsToAdd);
                    }
                }
            }
        }
        
        System.debug('chkIndustriesToDelete: '+chkIndustriesToDelete);
        System.debug('chkIndustriesToInsert: '+chkIndustriesToInsert);
        // update chk if not empty
        if (!chkToUpdateList.isEmpty()) DmlHelper.performDML2(chkToUpdateList, DmlHelper.DML_UPDATE, 'CommunitiesMethods', 'updateExistingChkIsqRecTypesAndDeleteOldRecs', 'Updating Industry_Record_Types__c field', true);
        // if mapping of ISQ to delete isn't empty send call to remove
        if (!chkIndustriesToDelete.isEmpty()) {
            deleteIsqAndWqforCHK2(chkIndustriesToDelete);
        }
        
        if (!chkIndustriesToInsert.isEmpty()) {
            insertISQRecordsForChk2(chkIndustriesToInsert);
        }
    }
    
    public static void deleteIsqAndWqforCHK2(Map<Id, Set<String>> chkToIsqToRemoveMap) {
        // get every single wc isq for all chekklistls
        Map<Id, WC_Questionnaire_Industry_Specific__c> isqReqsForChkToDelete = new Map<Id, WC_Questionnaire_Industry_Specific__c>([SELECT Id, PEO_Underwriting_Checklist__c, Record_Type_Name__c
                                                                                                                                   FROM WC_Questionnaire_Industry_Specific__c
                                                                                                                                   WHERE PEO_Underwriting_Checklist__c IN :chkToIsqToRemoveMap.keySet()]);
        
        List<WC_Questionnaire_Industry_Specific__c> isqToDelete = new List<WC_Questionnaire_Industry_Specific__c>();
        // iterate the results
            // get the set of naics for the current chk of the isq
            // if the isq rec type is in the set for the chk to delete
                // add the isq to a delete list
        for (String Id : isqReqsForChkToDelete.keySet()) {
            WC_Questionnaire_Industry_Specific__c isq = isqReqsForChkToDelete.get(Id);
            Set<String> naicsSetForChk = (isq != null ? chkToIsqToRemoveMap.get(isq.PEO_Underwriting_Checklist__c) : null);
            if (naicsSetForChk != null && naicsSetForChk.contains(isq.Record_Type_Name__c)) isqToDelete.add(isq);
        }
                
        // if delete list isn't empty
            // semd delete request 
        // Use straight up dml for uat. Easier when errors surface immidietly
        if (!isqToDelete.isEmpty()) delete isqToDelete;
        // if (!isqToInsert.isEmpty()) DmlHelper.performDML2(isqToDelete, DmlHelper.DML_DELETE, 'CommunitiesMethods', 'insertISQRecordsForChk2', 'Inserting ISQ', true);
    }
    
    public static void insertISQRecordsForChk2(Map<Id, Set<String>> chkToISqTtoInsert) {
        // get all exising isq reord for all chks in map
        List<WC_Questionnaire_Industry_Specific__c> ISQList = [SELECT Id, PEO_Underwriting_Checklist__c, Record_Type_Name__c
                                                               FROM WC_Questionnaire_Industry_Specific__c 
                                                               WHERE PEO_Underwriting_Checklist__c IN :chkToISqTtoInsert.keySet()];
        // iterate all ISQ
        // get set for chk to be inserted
        // remove sring from se if in here
        for (WC_Questionnaire_Industry_Specific__c existingIsq : ISQList) {
            Set<String> isqIndustriesToInsert = chkToISqTtoInsert.get(existingIsq.PEO_Underwriting_Checklist__c);
            if (isqIndustriesToInsert != null && isqIndustriesToInsert.contains(existingIsq.Record_Type_Name__c)) isqIndustriesToInsert.remove(existingIsq.Record_Type_Name__c);
        }
        
        List<WC_Questionnaire_Industry_Specific__c> isqToInsert = new List<WC_Questionnaire_Industry_Specific__c>();
        // iterate and create the isq to insert for each chk
        for (Id chkId : chkToISqTtoInsert.keySet()) {
            Set<String> isqIndustriesToInsert = chkToISqTtoInsert.get(chkId);
            
            if (isqIndustriesToInsert == null || isqIndustriesToInsert.isEmpty()) continue;
            // iterate reamining values in set
            for (String peoIndustryTitle : isqIndustriesToInsert) {
                if (peoIndustryTitle == null || String.isBlank(peoIndustryTitle)) continue;
                String IndustryName = peoIndustryTitle.replace(' ','_').replace('\'','').replace('/','_').replace('(','').replace(')','');
                String IndustryId = peoIndustryTitle;
                String RecordTypeId = (String)Schema.SObjectType.WC_Questionnaire_Industry_Specific__c.getRecordTypeInfosByName().get(IndustryId).getRecordTypeId();
                WC_Questionnaire_Industry_Specific__c Rec = new WC_Questionnaire_Industry_Specific__c(PEO_Underwriting_Checklist__c=chkId); 
                Rec.RecordTypeId = RecordTypeId;
                isqToInsert.add(rec);
            }
        }
        
        // Use straight up dml for uat. Easier when errors surface immidietly
        if (!isqToInsert.isEmpty()) INSERT isqToInsert;
        // if (!isqToInsert.isEmpty()) DmlHelper.performDML2(isqToInsert, DmlHelper.DML_INSERT, 'CommunitiesMethods', 'insertISQRecordsForChk2', 'Inserting ISQ', true);
    }
    
    public static void updateChecklistOpty(Map<Id,Opportunity> createdOpty) {
        //Map<Id,Opportunity> createdOpty = new Map<Id,Opportunity> ([Select Id,Name,AccountId,OwnerId from Opportunity where Id IN :createdOpty]);
        updateChecklistOptyWithLatest(createdOpty);
    }
    
    public static void updateChecklistOptyWithLatest(Map<Id,Opportunity> createdOpty) {
        // Id in parameter is account Id
        Boolean isChanged = false;
        List<PEO_Onboarding_Checklist__c> updateList = new List<PEO_Onboarding_Checklist__c>();
        system.debug('Inside CommunityMethods:updateChecklistOpty createdOpty:'+createdOpty.size());
        Id recordTypeId1 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PEO Opportunity Record Type').getRecordTypeId();
        Id recordTypeId2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Prism PEO Opportunity Record Type').getRecordTypeId();
        Map<Id,PEO_Onboarding_Checklist__c> peoChecklistMap = new Map<Id,PEO_Onboarding_Checklist__c>
            ([SELECT Id, Name, OwnerId, RecordType.Name, Sales_Rep__c,Prospect_Client__c,Opportunity__c,Sales_Analyst__c,
              Prospect_Client__r.OasisPEOAccountOwner__c,CSCMContractStatus__c,RecordTypeId
              FROM PEO_Onboarding_Checklist__c
              WHERE Prospect_Client__c in : createdOpty.keyset()]);
        for(Id chkId: peoChecklistMap.keyset()){
            if(peoChecklistMap.get(chkId).Prospect_Client__c == createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).AccountId){
               // system.debug('recordTypeId:'+createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).RecordTypeId);
                if(//peoChecklistMap.get(chkId).Sales_Rep__c == createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).OwnerId &&
                   peoChecklistMap.get(chkId).Opportunity__c != null
                   && peoChecklistMap.get(chkId).Prospect_Client__r.OasisPEOAccountOwner__c == createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).OwnerId
                   //&& peoChecklistMap.get(chkId).Prospect_Client__r.OasisPEOAccountOwner__c == peoChecklistMap.get(chkId).Sales_Rep__c
                   && (peoChecklistMap.get(chkId).CSCMContractStatus__c=='Prospect' || String.isEmpty(peoChecklistMap.get(chkId).CSCMContractStatus__c))
                   && (createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).RecordTypeId == recordTypeId1 || createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).RecordTypeId == recordTypeId2)
                  ){
                      peoChecklistMap.get(chkId).Opportunity__c = createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).Id;
                      peoChecklistMap.get(chkId).Sales_Rep__c = peoChecklistMap.get(chkId).Prospect_Client__r.OasisPEOAccountOwner__c;
                      if(peoChecklistMap.get(chkId).Sales_Analyst__c==null){
                          peoChecklistMap.get(chkId).OwnerId = peoChecklistMap.get(chkId).Prospect_Client__r.OasisPEOAccountOwner__c;
                      }
                      updateList.add(peoChecklistMap.get(chkId));
                    isChanged = true;
                    }
            }            
        }
        system.debug('CommunityMethods updateChecklistOptyWithLatest updateList:'+updateList.size());
        if(isChanged){
            //Update updateList;
            DmlHelper.performDML2(updateList, DmlHelper.DML_UPDATE, 'CommunitiesMethods', 'updateChecklistOptyWithLatest', 'updating Checklist Oppty', true);
        }
    }
    
    public static Map<String, Decimal> retrieveBenchmarkValues(PEO_Onboarding_Checklist__c checklist) {
        List<PEOUW_BLS_Data__c> benchMarkRecords = new  List<PEOUW_BLS_Data__c>();
        List<Schema.FieldSetMember>  blsDataFieldSet = SObjectType.PEOUW_BLS_Data__c.FieldSets.BLS_Api_fields.getFields();
        Map<String, Decimal> values = new Map<String, Decimal>();
        String[] fields = new String[]{};
            for (SChema.FieldSetMember field : blsDataFieldSet) {
                fields.add(field.getFieldPath());
            }
        String query = 'Select '+ String.join(fields,',')  + ' FROM PEOUW_BLS_Data__c WHERE PEO_Underwriting_Checklist__c=\'' + checklist.Id + '\'  LIMIT 1';
        benchMarkRecords = Database.query(query);
        if(benchMarkRecords != null && benchMarkRecords.size() > 0) {
            values.put('medPart', benchMarkRecords[0].Medical_Participation__c);
            values.put('turnOver', benchMarkRecords[0].Turnover_rate__c);
            values.put('avgWage', benchMarkRecords[0].Average_wages__c);
            values.put('avgWageYear', benchMarkRecords[0].Avg_wages_last_updated_on__c);
        } 
        return values;
    }
    
    public static Boolean checkIfBenchmarkValuesExist(Account account, PEO_Onboarding_Checklist__c checklist) {
        // NAICS_Code__c
        List<PEOUW_BLS_Data__c> benchMarkRecords = new  List<PEOUW_BLS_Data__c>();
        List<Schema.FieldSetMember>  blsDataFieldSet = SObjectType.PEOUW_BLS_Data__c.FieldSets.BLS_Api_fields.getFields();
        Boolean needRefresh = false;
        Map<String, Decimal> values = new Map<String, Decimal>();
        String[] fields = new String[]{};
            for (SChema.FieldSetMember field : blsDataFieldSet) {
                fields.add(field.getFieldPath());
            }
        String query = 'Select '+ String.join(fields,',')  + ' FROM PEOUW_BLS_Data__c WHERE PEO_Underwriting_Checklist__c=\'' + checklist.Id + '\'  LIMIT 1';
        benchMarkRecords = Database.query(query);
        List<Account> dataPointAccs = new List<Account>();
        List<PEO_Onboarding_Checklist__c> dataPointChecklists = new List<PEO_Onboarding_Checklist__c>();
        System.debug('Account naics:'+account.NAICS_Code__c);
        if(benchMarkRecords == null || benchMarkRecords.size() == 0){
            System.debug('CommunityMethods checkIfBenchmarkValuesExist: No Benchmark records present');
            dataPointAccs.add(account);
            dataPointChecklists.add(checklist);
            return BlsDataHelper.fetchTheDatapoints(dataPointAccs, dataPointChecklists, 'CommunityMethods');
        }
        else if(benchMarkRecords != null && benchMarkRecords.size() > 0){
            System.debug('BLS naics:'+benchMarkRecords[0].NAICS_Code__c);
            System.debug('CommunityMethods checkIfBenchmarkValuesExist: Benchmark records exist');
            if(benchMarkRecords[0].NAICS_Code__c != account.NAICS_Code__c){
                System.debug('Naics mismatch: retrigger BLS sync');
                dataPointAccs.add(account);
                dataPointChecklists.add(checklist);
                return BlsDataHelper.fetchTheDatapoints(dataPointAccs, dataPointChecklists, 'CommunityMethods');
            }
        }
        return true;
    }
    
    //JDA sfdc-14645
    @AuraEnabled
    public static Boolean checkBLSPermissions(Id userId, String benchMarkPermission){
        System.debug('userId:'+userId);
        Boolean hasBLSPermission = false;
        List<PermissionSetAssignment> permissions = new List<PermissionSetAssignment>();
        permissions = [
            SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name 
            FROM PermissionSetAssignment 
            WHERE AssigneeId =:userId
        ];
        if(permissions != null && permissions.size()>0){
            for(PermissionSetAssignment eachPermission: permissions){
                System.debug('permission Name = '+eachPermission.PermissionSet.Name);
                if(eachPermission.PermissionSet.Name == benchMarkPermission){
                    hasBLSPermission = true;
                }
            } 
        }
        System.debug('checkPermissions hasBLSPermission = '+hasBLSPermission);
        return hasBLSPermission;
    }
    
    //JDA sfdc-13527
    /*public static void updateAccessForSplitOppty(Map<Id,Opportunity> createdOpty) {
        System.debug('JDA updateAccessForSplitOppty '+ createdOpty);
        Id recordTypeId1 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('PEO Opportunity Record Type').getRecordTypeId();
        Id recordTypeId2 = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Prism PEO Opportunity Record Type').getRecordTypeId();
        Map<Id,PEO_Onboarding_Checklist__c> peoChecklistMap = new Map<Id,PEO_Onboarding_Checklist__c>
            ([SELECT Id, Name, OwnerId, RecordType.Name, Sales_Rep__c,Prospect_Client__c,Opportunity__c
              FROM PEO_Onboarding_Checklist__c
              WHERE Prospect_Client__c in : createdOpty.keyset()]);
        for(Id chkId: peoChecklistMap.keyset()){
            if(peoChecklistMap.get(chkId).Opportunity__c == createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).Primary_Opportunity__c){
                system.debug('Child for split oppty found');
                 system.debug('Owner to get access:'+createdOpty.get(peoChecklistMap.get(chkId).Prospect_Client__c).OwnerId);
            }
        }
    }*/

}