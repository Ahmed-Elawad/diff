/** 
* Create an external community user. 
*
* History
* -------
* 03/10/2020    Ahmed Elawad        Created.
* 04/30/2021    Jake Hinds          Adding in custom permission check, oppId
* 07/6/2021     Ahmed Elawad        Updated createQuestionnaire to pass checklsit values to CommunitiesAccountUpdateController.getPEOOnboardingChecklist
* 08/5/2021     Ahmed Elawad        Added updateContactAndAcctWorkqueue
* 08/12/2021    Jake Hinds          fix for permission set
* 08/16/2021    Ahmed Elawad        Added checkForExistingChecklist method, and updated createQuestionnaire to use upsert
* 09/01/2021    Jake Hinds          Removed oppId from getPEOOnboardingChecklist
* 09/07/2021    Jake Hinds          Adding Community User future method
* 09/22/2021    Jake Hinds          Refactor permissions method
* 10/06/2021    Ahmed Elawad        Removed communityForms saveMedicalQuestionnaire dependency from createQuestionnaire method and extended getContactForId query to get account info
* 10/08/2021    Jake Hinds          Reactivate method
* 11/01/2021    Ahmed Elawad        Updated logic for checklsit creation to happen in buildChecklistToUpsertList
* 12/09/2021    Jake Hinds          Adding frequency to opp pull and checklist creation
* 01/26/2022    Jake Hinds          Changes for NBSC Vertical Rep
* 02/07/2022    Jake Hinds          Removing experience
* 03/10/2022    Jake Hinds          getEnvironment + assignProspectPermissionSet
* 05/03/2022    Srujan Kumar        createCommunityUserNew + sendEmailToCommUser(called from flow)
* 07/26/2022    Srujan Kumar		getChildAccounts
* 07/26/2022    Srujan Kumar		deleteChildAccountChecklists
* 02/01/2023    Josh Cartwright     updated sendEmailToCommUser to do an update to the contact instead of insert. 
* 06/06/2023    Josh Cartwright     upated NSC check to look for PEO Sales org instead of NSC (NSC was recently removed)
* 06/12/2023    Josh Cartwright 	changed sendEmailToCommUser to not update the contact, its causing dupelicate welcome emails 
* 01/12/2024	Jidesh 				Tech debt SFDC-25031: removing unwanted methods 
* 02/01/2024    Josh Cartwright     adding error logging to assignProspectPermissionSet
* 05/07/2024    Josh Cartwright     updated updateContactAndAcctWorkqueue to reset broker commission work queues 
* 05/16/2024    Srujan Kumar        updated updateContactAndAcctWorkqueue to create work queues for child accounts 
*/

public without sharing class ConvertContactToCommunityUser {
    
    /**
* return the contact record for the passed in ID
* @Params: {Id(contact record id)}
* @Return: {Contact record, or NUll}
*/
    @AuraEnabled
    public static Contact getContactForId(Id conId) {
        System.debug('Retireving contact: '+conId);
        Contact retVal;
        Contact[] cons = [SELECT name, firstName, lastName, email, phone, AccountId, Account.SalesParent__c,  Account.SalesParent__r.Name, Account.Name FROM Contact WHERE id=:conId LIMIT 1];
        for (Contact c : cons) {
            retVal = c;
        }
        System.debug('Returned contact: '+conId);
        return retVal;
    }
    
    @AuraEnabled	
    public static Map<String, Object> getChildAccounts(Id accId) { 	
        Map<String, Object> returnVals = new Map<String, Object>();	
        List<Account> childAcc = [select Id, Name from account where  SalesParent__c =: accId];	
        returnVals.put('childAccounts', childAcc);	
        if(childAcc.size() > 0){	
            List<PEO_Onboarding_Checklist__c> childAccChecklist = new List<PEO_Onboarding_Checklist__c>([SELECT Prospect_Client__c  FROM PEO_Onboarding_Checklist__c 	
                                                                                                         WHERE Prospect_Client__c IN: childAcc]);	
            returnVals.put('childAccChecklists', childAccChecklist);	
        }	
        return returnVals;	
    }
    
    @AuraEnabled
    public static User getRunningUser(){
        User runningUser = UserHelper.getRunningUser();
        System.debug('CommunitiesAccountUpdateController runningUser.Profile.Name = '+ runningUser.Profile.Name);
        return runningUser;
    }
    
    @AuraEnabled
    public static String[] checkPermissions(User currUser){
        String[] missingPermissions = new String[]{};
            System.debug('CommunitiesAccountUpdateController getInvitePaychex currUser.Profile.Name = '+ currUser.Profile.Name);
        Boolean hasEmailPermission = FeatureManagement.checkPermission('PEO_Getting_Started_Invite_Paychex');
        Boolean hasBETAPermission = FeatureManagement.checkPermission('PEO_Getting_Started_BETA');
        System.debug('ConvertCommUser hasEmailPermission = '+hasEmailPermission);
        System.debug('ConvertCommUser hasBETAPermission = '+hasBETAPermission);
        if(currUser.UserType == 'Standard' && currUser.Profile.Name != 'System Administrator' && !Test.isRunningTest()){
            if(!hasEmailPermission){
                missingPermissions.add('Paychex Email');
            }
            if(!hasBETAPermission){
                missingPermissions.add('BETA Access');
            }
        }
        return missingPermissions;
    }
    
    /**
* Verifies if a username or nickname is already in use for a new Community user record creation
* @Params {String(username), String(nickName)}
* @Return: {List<String>(Contains any list of errors, empty if no errors)}
*/
    @AuraEnabled
    public static List<String> verifyFields(String uName, String nickName) {
        List<String> errs = new List<String>();
        system.debug('verifyFields uName'+uName+' nickName'+nickName);
        User[] usrs = [SELECT Username,CommunityNickname FROM User WHERE Username=:uName or CommunityNickname=:nickName];
        
        for (User u : usrs) {
            if (u.Username == uName) {
                errs.add('Username');
            }
            if (u.CommunityNickname == nickName) {
                errs.add('NickName');
            }
        }
        return errs;
    }
    @AuraEnabled
    public static Opportunity getOpp(Id accId){
        Opportunity returnOpp;
        List<String> contractStatus = new List<String>{'Client','Terminated','UnderContract','PendingTermination','PendingActivation'}; // SFDC-13614  APR0134709 - Rohith
        //List<String> recordTypeNames = new List<String>{'PEO Opportunity Record Type','Prism PEO Opportunity Record Type','PEO Referral Revenue Opportunity','Prism PEO Referral Revenue Opportunity','ASO Referral Revenue Opportunity'}; // SFDC-14127 Rohith
        List<String> recordTypeNames = new List<String>{'PEO Opportunity Record Type','PEO Referral Revenue Opportunity','ASO Referral Revenue Opportunity'}; // SFDC-14127 Rohith
        User runningUser = UserHelper.getRunningUser();
        String runningUserTitle = runningUser.Title; //SFDC-14126 Rohith
        Boolean hasNBSCVerticalPermission = FeatureManagement.checkPermission('PEO_Getting_Started_NBSC_Vertical');
        system.debug('hasVertical'+hasNBSCVerticalPermission);
        Opportunity[] allOpps = [SELECT Id,Name,OwnerId,CreatedDate,Frequency__c,Account.Premier_PBS_Account_Owner__c,Account.OasisPEOAccountOwner__c,Account.OwnerId,
                                 Referring_Employee__c, Referring_Employee__r.User_Lookup__c,  // SFDC-14126 Rohith
                                 Owner.ManagerId,
                                 (SELECT Id,LastModifiedDate,Name,OpportunityId,TeamMemberRole,UserId
                                  FROM OpportunityTeamMembers
                                  WHERE UserId =:runningUser.id
                                  AND TeamMemberRole ='PEO NSC') 
                                 FROM Opportunity WHERE CreatedDate = LAST_N_DAYS: 179 
                                 AND (OpportunityType__c = 'PEO' OR OpportunityType__c ='Referral')
                                 AND AccountId =: accId 
                                 AND Account.CSCMContractStatus__c NOT IN :contractStatus// SFDC-13614  APR0134709 - Rohith
                                 //AND (RecordType.Name = 'PEO Opportunity Record Type' OR RecordType.Name = 'Prism PEO Opportunity Record Type') // SFDC-14127 Rohith
                                 AND RecordType.Name IN :recordTypeNames  // SFDC-14127 Rohith
                                 ORDER BY CreatedDate DESC];
        System.debug('Check opportunity Values --->'+allOpps);
        if(!allOpps.isEmpty()){
            //Added by Srujan
            List<PermissionSetAssignment> psas = [SELECT PermissionSetId, AssigneeId, PermissionSet.Name From PermissionSetAssignment 
                                                  WHERE AssigneeId =: runningUser.Id
                                                  AND PermissionSet.Name = 'PEO_Getting_Started_Portal_Creation' LIMIT 1];
            if(psas.size() > 0){
                system.debug('Permission set found');
                return allOpps[0];
            }
            for(Opportunity opp : allOpps){
                system.debug('allOpps'+allOpps.size());
                //Changed by Srujan (Commented below code)
                if(opp.OwnerId == runningUser.Id && opp.OwnerId == opp.Account.OasisPEOAccountOwner__c){
                    return opp;
                }
            }
        }
        return null;
    }
    
/**
* Creates a community user record based on specific date and time
* @Params {String(username), String(nickName), Id(contact record ID), String(user alias), String(community audiance), DateTime(DateValue)}
* @Return: {Id(new user record id on success, null on failure)}
*/
    @AuraEnabled
    public static String createCommunityUserNew(String uName, String nickName, Id conId, String alias, String communityMessage, DateTime inviteDate) {
        System.debug('Start user creation request');
        //Bharat Changes - Renamed usrId to retVal, changed returntype from Id to String, Added query and If-else block
        String retVal;
        String accId = [SELECT AccountId FROM Contact WHERE Id=:conId LIMIT 1].AccountId;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        // create an instance of the class or is this call fine??
        Contact conRec = ConvertContactToCommunityUser.getContactForId(conId);
        
        //it would be better to pass this into the method.
        User runningUser = getRunningUser();
        if(inviteDate == null){
            inviteDate = system.now();
        }
        User communityUsr = new User(
            UserName = uName,
            FirstName = conRec.FirstName,
            LastName = conRec.LastName,
            Alias = alias,
            email = conRec.Email,
            ContactId = conId,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = nickName,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community',
            License_Type__c = 'Community',
            UserPermissionsKnowledgeUser = true,
            community_Welcome_Messsage__c = communityMessage,
            Community_User_Created_By__c = runningUser.Name,
            Requested_Invite_Date__c = inviteDate
        );
        
        System.debug('New user profile: '+communityUsr);
        try {
            // insert communityUsr;
            // Database.DMLOptions dlo = new Database.DMLOptions();
            // dlo.EmailHeader.triggerUserEmail = true;
            Database.SaveResult sr =  Database.insert(communityUsr);
            if (!sr.isSuccess()) {
                System.debug('Error creating user: ' + sr.getErrors());
                return null;
            } else {
                system.debug('User created: ' + sr.getId());
                retVal = sr.getId();
                retVal = communityUsr.Id;
                // CS Helper method checks the existing locations in CS for the account which the contact
                // is related to to ensure locations are stood up for the process. Good placement for already 
                // existing accounts to ensure all locations exist as needed in CS.
                
                //assignProspectPermissionSet(communityUsr.Id);
                updateChecklistWithUser(accId,communityUsr.Id,inviteDate,conId);
                //ClientSpaceHelper.checkLocationsForAccount(conRec.AccountId);
                return retVal;
            }
        } catch(DmlException  ex) {
            system.debug('Error creating user' + ex);
            ErrorLog.logError('ConvertContactToCommunityUser', 'createCommunityUser', 'createCommunityUser Error', communityUsr.Id, ex, communityUsr, true);
            return null;
        } catch (Exception e) {
            ErrorLog.logError('ConvertContactToCommunityUser', 'createCommunityUser', 'General Process Error', communityUsr.Id, e, communityUsr, true);
            return null;
        }
    }
    
    @Invocablemethod
    public static void sendEmailToCommUser(List<String> inputId){
        User u= [SELECT Id, ContactId from User WHERE Id IN: inputId limit 1];
        assignProspectPermissionSet(u.Id);
    }
    
    @future
    public static void assignProspectPermissionSet(Id commUserId) {
    	PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name='PEO_Getting_Started_Prospect' LIMIT 1];
        if(ps!=null && commUserId!=null){
            PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId=ps.id,AssigneeId=commuserId);
            
            try {
				insert psa;        		
            }catch(Exception e) {
            	ErrorLog.logError('ConvertContactToCommunityUser','assignProspectPermissionSet', 'codekey',psa.id,e);
        		}
            
        }
    }
    
    @AuraEnabled
    public static Boolean createQuestionnaire(PEO_Onboarding_Checklist__c peoOnbChecklist, String formName,Opportunity oppty) {
        // tries to insert a new record for the new user. Any failures return false
        //system.debug('createQuestionnaire:peoOnbChecklist- '+peoOnbChecklist);
        //PEO_Onboarding_Checklist__c peo = CommunitiesAccountUpdateController.getPEOOnboardingChecklist(peoOnbChecklist.Prospect_Client__c,oppId, peoOnbChecklist);
        String codeKey = 'By '+ user.name + ' on form convertContactToCommunityUser';
        Set<Id> ParentAccIdSet = new Set<Id>();
        
        Id accId = peoOnbChecklist.Prospect_Client__c;
        List<PEO_Onboarding_Checklist__c> checklsitsToUpsert = buildChecklistToUpsertList(accId, peoOnbChecklist, ParentAccIdSet);
        
        try {
            DMLHelper.performDML2(checklsitsToUpsert,DmlHelper.DML_UPSERT,'ConvertContactToCommunityUser','createQuestionnaire','By '+ UserInfo.getUserId() + ' on form ' + formName,true);
        }catch(Exception e) {
            CommunityMethods.logCommunityError(e, 'createQuestionnaire','ConvertContactToCommunityUser', 'ConvertContactToCommunityUser',checklsitsToUpsert);
        }
        
        if (peoOnbChecklist.Medical_Benefits_Underwriting_Requested__c == 'yes' && peoOnbChecklist.Id != null) {
            System.debug('Creating medical questionnaire for new user creation: ');
            List<PEO_Onboarding_Medical_Questionnaire__c> oldMedicalRec = [SELECT id, PEO_Onboarding_Checklist__c FROM PEO_Onboarding_Medical_Questionnaire__c WHERE PEO_Onboarding_Checklist__c=:peoOnbChecklist.Id];
            if (oldMedicalRec.isEmpty()) {
                PEO_Onboarding_Medical_Questionnaire__c newMedicalRec = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c = peoOnbChecklist.Id);
                DMLHelper.performDML2(new List<PEO_Onboarding_Medical_Questionnaire__c>{newMedicalRec},DmlHelper.DML_INSERT,'ConvertContactToCommunityUser','createQuestionnaire',codeKey,true);
            }
        }
        
        // If a parent acc id was populated into the set that means either the parent or one of its
        // children needed a checklist inserted in which case we need to sync the child accounts
        // to their locations in CS
        if (!ParentAccIdSet.isEmpty()) {
            System.debug('Sending Acc Sync: ' + ParentAccIdSet);
            ClientSpaceHelper.checkLocationsForAccount(ParentAccIdSet);
        }
        
        if (!checklsitsToUpsert.isEmpty()) return true;
        return false;
    }
    
    @AuraEnabled
    public static boolean updateContactAndAcctWorkqueue(Id contactId, Id acctId, List<Id> childAccountIdsForQueues, String childAccountSelection) {
        // Get the exisiting wqs for each obj
        // determine if we need to update or insert a new one
        // update or insert the account first
        // then update or insert the contact
        List<Id> accIds = new List<Id>();
        List<Id> contIds = new List<Id>();
        if(childAccountSelection == 'Yes'){
            Map<Id, Account> childAccs = new Map<Id, Account>([select Id from Account where SalesParent__c =: acctId]);
            accIds = new List<Id>(childAccs.keyset());
            Map<Id, Contact> cont = new Map<ID, Contact>([SELECT Id, AccountId FROM Contact WHERE AccountId IN: accIds]);
            if(!cont.keySet().isEmpty()){
                contIds = new List<Id>(cont.keyset());
            }
        }else{
            if(childAccountIdsForQueues.size() > 0){
                accIds = childAccountIdsForQueues;
                Map<Id, Contact> cont = new Map<ID, Contact>([SELECT Id, AccountId FROM Contact WHERE AccountId IN: accIds]);
                if(!cont.keySet().isEmpty()){
                    contIds = new List<Id>(cont.keyset());
                }
            }
        }
        accIds.add(acctId);
        contIds.add(contactId);        
        
        Map<Id, Account> accountMap = new Map<Id, Account>([select Id from Account where Id IN:accIds]);
        Map<Id, Contact> contactMap = new Map<Id, Contact>([select Id, AccountId from Contact where AccountId IN: accIds]);
        Work_Queue__c[] recs =  [SELECT ID, Object__c, Object_Record_ID__c, Account_ID__c
                                 FROM Work_Queue__c 
                                 WHERE Account_ID__c IN:accIds AND (Object__c='Contact' OR Object__c='Account' OR Object__c ='Broker_Commission__c')];
        Map<String, List<Work_Queue__c>> updateRecs = new Map<String, List<Work_Queue__c>>();
        Map<String, List<Work_Queue__c>> createRecs = new Map<String, List<Work_Queue__c>>();
        Boolean updateInsteadOfInsertAcctWQ = false;
        Boolean updateInsteadOfInsertCntctWQ = false;
        Boolean updateInsteadOfInsertBCWQ = false;
        List<Work_Queue__c> accWQRecs = new List<Work_Queue__c>();
        List<Work_Queue__c> contWQRecs = new List<Work_Queue__c>();
        List<Work_Queue__c> BCWQ = new List<Work_Queue__c>();
        List<Account> acctRecs = new List<Account>();
        List<Account> cntctRecs = new List<Account>();
        // if a match is found save the wq
        for (Work_Queue__c wqRec : recs) {
            if (wqRec.Object__c == 'Account' && accountMap.containsKey(wqRec.Object_Record_ID__c)){
                wqRec.Completed__c = false;
                accWQRecs.add(wqRec);
                updateInsteadOfInsertAcctWQ = true;
                accountMap.remove(wqRec.Object_Record_ID__c);
            }
            if (wqRec.Object__c == 'Contact' && contactMap.containsKey(wqRec.Object_Record_ID__c)) {
                wqRec.Completed__c = false;
                contWQRecs.add(wqRec);
                updateInsteadOfInsertCntctWQ = true;
                contactMap.remove(wqRec.Object_Record_ID__c);
            }           
            if (wqRec.Object__c == 'Broker_Commission__c') {
                wqRec.Completed__c = false;
                BCWQ.add(wqRec);
                updateInsteadOfInsertBCWQ = true;
            }    
        }
        if(accWQRecs.size() > 0){
            updateRecs.put('acctWQ',accWQRecs);
        }
        if(contWQRecs.size() > 0){
            updateRecs.put('cntctWQ',contWQRecs);
        }
        if(BCWQ.size() > 0){
            updateRecs.put('BCWQ',BCWQ);
        }
        
        //Account acct = [SELECT ID FROM Account WHERE ID=:acctId LIMIT 1];
        //Contact ctct = [SELECT ID, AccountId FROM Contact WHERE ID=:contactId LIMIT 1];
        
        // update or insert an account WQ first
        if (updateInsteadOfInsertAcctWQ){
            update updateRecs.get('acctWQ');
        } 
        
        if(!accountMap.isEmpty()){
            List<Work_Queue__c> insertAcctWQRecs = new List<Work_Queue__c>();
            for(Account acc : accountMap.values()){
                Work_Queue__c acctWQ = new Work_Queue__c(Object_Record_ID__c = acc.Id, Account_ID__c = acc.Id, Object__c=ObjectHelper.OBJECT_ACCOUNT);
                acctWQ.Completed__c = false;
                insertAcctWQRecs.add(acctWQ);
            }
            clientSpaceHelper.saveWorkQueues(accountMap.values(), null, insertAcctWQRecs, 'Account');
        }
        
        // update or insert the contact WQ
        if (updateInsteadOfInsertCntctWQ) {
            update updateRecs.get('cntctWQ');
        }
        
        if(!contactMap.isEmpty()){
            List<Work_Queue__c> insertcntctWQRecs = new List<Work_Queue__c>();
            for(Contact cnct : contactMap.values()){
                Work_Queue__c cntctWQ = new Work_Queue__c(Object_Record_ID__c = cnct.Id, Contact_ID__c = cnct.Id, Account_ID__c = (cnct.AccountId != null ? cnct.AccountId : null), Object__c=ObjectHelper.OBJECT_CONTACT);
                cntctWQ.Completed__c = false;
                insertcntctWQRecs.add(cntctWQ);
            }
            clientSpaceHelper.saveWorkQueues(null, contactMap.values(), insertcntctWQRecs,'Contact');
        }
        
        if(updateInsteadOfInsertBCWQ){
            update updateRecs.get('BCWQ');
        }
        
        // send the record updates if they need to be saved
        return true;
    }
    
    // Method to check for existing checklist
    // return checklist answers needed by UI of found.
    // Return null if no match found
    @AuraEnabled
    public static PEO_Onboarding_Checklist__c checkForExistingChecklist(Id AccountID) {
        // retrieve a matched checklsit
        PEO_Onboarding_Checklist__c[] chklsts = [SELECT Id, Name,Prospect_Client__c, OwnerId, Sales_Rep__c,  Client_Add_on__c,
                                                 Medical_Benefits_Underwriting_Requested__c, Medical_Underwriting_Path__c,
                                                 Workers_Comp_FastPass__c , Benefit_Effective_Date__c, Self_retain_reason__c,Medical_Underwriting_Path_Option__c,
                                                 WC_Codes_are_in_Target_Hazard_Group__c, WC_Premium_is_less_than_10_000__c, Select_Child_Accounts__c, 
                                                 Submit_to_Workers_Comp_Underwriting__c,Please_Explain__c,Reason_Why_You_Are_Not_Inviting_Prospect__c,
                                                 Opportunity__c,Opportunity__r.Id,Opportunity__r.OwnerId, Health_Benefits_Currently_through_a_PEO__c,
                                                 display_Benchmark_tab__c, Platform__c, Current_Aff_with_Paychex_PEO_Oasis__c, Client_Number__c, 
                                                 why_choose_full_underwriting_path__c, Is_this_a_current_Paychex_Agency_Client__c, Parent_Company_Legal_Name__c,
                                                 Parent_Paychex_oasis_Num__c, Parent_appro_self_retain_workers_comp__c, Is_Medical_Underwriting_Requested__c,
                                                 Do_you_need_full_underwriting_path__c, Prospect_Client__r.AccountNumber,Prospect_Client__r.CSCMContractStatus__c,
                                                 Medical_Underwriting_Path_Type__c, Workers_Comp_Underwriting_Path_Type__c,CS_CM_Contract_Status__c,
                                                 Workers_Comp_Quick_Quote_Eligibility__c, Medical_Quick_Quote_Eligibility__c, QQ_Medical_Submit_Date__c,
                                                 QQ_WC_Submit_Date__c, QQ_Reset_Eligible_Date__c, QQ_Reset_Date__c,
                                                 Sales_Analyst__c,PEO_Checklist_submission_status__c, Total_Number_of_Employees__c,
                                                 Is_Your_Plan_Self_Funded_or_Level_Funded__c, Currently_using_a_PEO__c,
                                                 Medical_Carriers_currently_in_use__c
                                                 FROM PEO_Onboarding_Checklist__c 
                                                 WHERE Prospect_Client__c=:AccountID ORDER BY CreatedDate ASC];
        
        if (!chklsts.isEmpty()) return chklsts[0];
        return null;
    }
    @future
    public static void updateChecklistWithUser(Id accountId, Id userId, DateTime inviteDate, Id contId){
        system.debug('updateChecklistWithUser contId:'+contId);
        PEO_Onboarding_Checklist__c checklist = [SELECT Id,Community_User__c,Community_User_Contact__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :accountId ORDER BY CreatedDate DESC LIMIT 1];
        checklist.Community_User__c = userId;
        checklist.Community_User_Contact__c = contId;
        checklist.Send_Welcome_Email_Date__c = inviteDate;
        PEO_Onboarding_Checklist__c[] checklists = new PEO_Onboarding_Checklist__c[]{checklist};
            DmlHelper.performDML2(checklists, DmlHelper.DML_UPDATE, 'ConvertContactToCommunityUser', 'updateChecklistWithUser', 'Update Comm User Lookup', true);
    }
    @AuraEnabled
    public static Boolean reactivateCommunityUser(User u){
        Boolean saveSuccess;
        PEO_Onboarding_Checklist__c checklist = [SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c = :u.AccountId LIMIT 1];
        u.isActive = true;
        try{
            update u;
            //sendReactivationEmail(u);
            //need future to avoid mixed dml
            resetChecklistUsersFuture(checklist.Id);
            saveSuccess = true;
        }
        catch(Exception e){
            saveSuccess = false;
        }
        return saveSuccess;
    }
    
    @future
    public static void resetChecklistUsersFuture(Id checklistId) {
        resetChecklistUsers(checklistId);
    } // resetChecklistUsersFuture
    
    public static void resetChecklistUsers(Id checklistId) {
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(
            Id=checklistId,
            OwnerId = UserInfo.getUserId(),
            Sales_Rep__c = UserInfo.getUserId(),
            PEO_Checklist_submission_status__c = null,
            Sales_Analyst__c = null,
            Analyst_Queue_Name__c = null,
            Analyst_Queue__c=null);
        
        DmlHelper.performDML2(new List<PEO_Onboarding_Checklist__c>{checklist}, DmlHelper.DML_UPDATE, 'ConvertContactToCommunityUser', 'resetChecklistUsers', 'Updating Checklist', true);  
        
    } // resetChecklistUsers
    
    /*
    * @PARAMS: {AccountId(Starting acc ID) PEO_Onboarding_Checklist__c (Checklist created by client already has some info populated), }
    * @RETURNS: {List<PEO_Onboarding_Checklist__c>(all RELAVENT checklsits for the prospect))}
    * + a relavent checklsit is the parent and all child checklists if starting from a parent 
    * + or just the child checklists if a client add on. See @ref1 for cleint add on logic
    */
    public static List<PEO_Onboarding_Checklist__c> buildChecklistToUpsertList(Id AccountId, PEO_Onboarding_Checklist__c checklistToInsert, set<Id> parentAccIdSet) {
        String medicalUWPathType = checklistToInsert.Medical_Underwriting_Path_Type__c;	
        String workersCompUWPathType = checklistToInsert.Workers_Comp_Underwriting_Path_Type__c;	
        System.debug(checklistToInsert);
        User runningUser = UserHelper.getRunningUser();
        List<PEO_Onboarding_Checklist__c> upsertList = new List<PEO_Onboarding_Checklist__c>();
        Map<Id, Account> accIdToAccMap = new Map<Id, Account>();
        Account parentAcc;
        
        // @ref1: if client add on simply return a list with the new checklist inserted. Do not copy values ANY
        if (checklistToInsert.Client_Add_on__c) {
            upsertList.add(checklistToInsert);
            return upsertList;
        }
        
        // get all accounts including children
        List<Account> allAccounts = [SELECT Id, Name, isParent__c, isChild__c, SalesParent__c FROM Account WHERE Id=:AccountId OR SalesParent__c=:AccountId ORDER BY SalesParent__c];
        // iterate all accounts.
        // if the account is a parent assign the parentACc var
        // add each account to the accIdToAccMap
        for (Account acc : allAccounts) {
            if (acc.isParent__c) parentAcc = acc;
            accIdToAccMap.put(acc.Id, acc);
        }
        // get all existing checklsits for the child accounts including the current account
        Schema.FieldSet oppFldSet = Schema.SObjectType.PEO_Onboarding_Checklist__c.fieldSets.Questionnaire_Fields;      
        Set<String> fieldSet = new Set<String>();
        DMLHelper.addFieldsToSet(oppFldSet, '', fieldSet);
        String baseQuery = DMLHelper.buildQueryFromSet(fieldSet, 'PEO_Onboarding_Checklist__c');
        baseQuery +=  'WHERE Prospect_Client__c IN (\'';
        set<Id> keySet = accIdToAccMap.keySet();
        List<Id> keys = new List<Id>(keySet);
        baseQuery += String.join(keys, '\',\'');
        baseQuery += '\') ORDER BY CreatedDate DESC';
        
        List<PEO_Onboarding_Checklist__c> existingChecklists = new List<PEO_Onboarding_Checklist__c>();
        Map<Id, PEO_Onboarding_Checklist__c> accIdToChecklistMap = new Map<Id, PEO_Onboarding_Checklist__c>();
        PEO_Onboarding_Checklist__c parentChk;        
        existingChecklists = Database.query(baseQuery);
        
        // iterate all the existing checklists
        // if the parentchk is assigned copy values from the parent and add the 
        // updated to the upsertList after removing the account from the accIdToAccMap & continue
        // otherwise add the checcklist to accIdToChecklistMap
        // if the current checklsit is the parent checklist assign the parentchk var
        for (PEO_Onboarding_Checklist__c chk : existingChecklists) {
            if (chk.Prospect_Client__c == checklistToInsert.Prospect_Client__c) {
                PEO_Onboarding_Checklist__c copied = copyChecklistValues(checklistToInsert, chk, accIdToAccMap.get(chk.Prospect_Client__c),runningUser, medicalUWPathType, workersCompUWPathType);
                if (copied != null) {
                    upsertList.add(copied);
                    accIdToAccMap.remove(chk.Prospect_Client__c);
                    continue;
                }
            }
            
            // if the parent checklist was assigned to the tracker variable in a previous step of the loop we
            // can shorten the total number of iterations done in this method. Take the values from the already
            // matched parent checklsit and copy it onto the current checklist(should be a child since line 410 handles the parent
            // After copying the values add the checklsit to be upserted and remove the account from the accIdToAccMap map.
            // and continue. There's nothing else to do for this checklist/account pair
            if (parentChk != null) {
                PEO_Onboarding_Checklist__c copied = copyChecklistValues(parentChk, chk, accIdToAccMap.get(chk.Prospect_Client__c),runningUser, medicalUWPathType, workersCompUWPathType);
                if (copied != null) upsertList.add(copied);
                accIdToAccMap.remove(chk.Prospect_Client__c);
                continue;
            }
           
            // if the current checklist is the parent accoutns checklist assign it to the tracker variable
            if (parentChk == null && parentAcc != null && chk.Prospect_Client__c == parentAcc.Id) parentChk = chk;
            // add the checklist to the accIdToChecklistMap for later use
            accIdToChecklistMap.put(chk.Prospect_Client__c, chk);
        }
        
        Boolean hasNBSCVerticalPermission = FeatureManagement.checkPermission('PEO_Getting_Started_NBSC_Vertical');
        // the copy from should either be the existing parent checklist which has already been updated from the prior
        // loop or the checklsit to be inserted <- the latter occurs on a first time accessing the portal
        PEO_Onboarding_Checklist__c copyFromChk = (parentChk != null ? parentChk : checklistToInsert);
        List<String> childAccIds = new List<String>();		
        if(checklistToInsert.Child_Account_Ids__c != null){		
            childAccIds = checklistToInsert.Child_Account_Ids__c.split(';');		
        }		
        List<Id> childAccountIds = new List<Id>();
        // iterate the accIdToAccMap. This should contain accounts that have not been already matched with a checklist
        // in the prior loop
        for (Account remainingAccount : accIdToAccMap.values()) {
            //custom permissions do not work right in tests.
            if ((hasNBSCVerticalPermission || (Test.isRunningTest() && checklistToInsert.Name.contains('Vertical'))) && checklistToInsert.Sales_Analyst__c == null && runningUser!=null){
                checklistToInsert.Sales_Analyst__c = runningUser.Id;
                checklistToInsert.OwnerId = runningUser.Id;
                checklistToInsert.PEO_Checklist_submission_status__c = 'Submitted';
                system.debug('setting all them fields:'+hasNBSCVerticalPermission);
            }
            // if it's a parent there's nothing to copy. Add the checklist created from the client to the
            // upsert and continue
            if (remainingAccount.isParent__c || (!remainingAccount.isParent__c && !remainingAccount.isChild__c)) {
                //upsertList.add(checklistToInsert);
                //If parent checklist doesnt exist create the parent and update the parent id
                Id ChecklistInserted = doQuickInsert(checklistToInsert);
                copyFromChk.Id = ChecklistInserted;
                continue;
            }
            
            // since it's a set we an always just insert an ID that should be in there
            // if the account is a parent add it's id to the parent acc id set
            if (remainingAccount.isParent__c) parentAccIdSet.add(remainingAccount.ID);
            // if the acc is a child add its parent to the id set
            if (remainingAccount.isChild__c) parentAccIdSet.add(remainingAccount.SalesParent__c);
            
            if(remainingAccount.isChild__c){	
                if((childAccIds != null && childAccIds.contains(remainingAccount.Id)) || checklistToInsert.Select_Child_Accounts__c == 'Yes'){	
                    // get the checklsit or create one then add it to the upsert list.	
                    PEO_Onboarding_Checklist__c exitsingChk = accIdToChecklistMap.get(remainingAccount.ID);	
                    if (exitsingChk == null)  system.debug('no existing chk for acc');	
                    if (exitsingChk == null) exitsingChk = new PEO_Onboarding_Checklist__c(Prospect_Client__c=remainingAccount.Id);	
                    PEO_Onboarding_Checklist__c copiedToChk = copyChecklistValues(copyFromChk, exitsingChk, remainingAccount,runningUser, medicalUWPathType, workersCompUWPathType);	
                    if (copiedToChk != null) upsertList.add(copiedToChk);	
                }else{	
                    childAccountIds.add(remainingAccount.Id);	
                }	
            }
        }

        if(childAccountIds.size() > 0){	
            deleteChildAccountChecklists(childAccountIds);	
        }
        
        // finaly return the checklist to insert list
        return upsertList;
    }
    
    public static void deleteChildAccountChecklists(List<Id> childAccountIds){		
        List<PEO_Onboarding_Checklist__c> childAccountChecklists = new List<PEO_Onboarding_Checklist__c>([SELECT Id FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c IN: childAccountIds]);		
        if(childAccountChecklists.size() > 0){		
            Database.DeleteResult[] drList = Database.delete(childAccountChecklists, false);		
            for(Database.DeleteResult dr : drList) {		
                if (dr.isSuccess()) {		
                    // Operation was successful, so get the ID of the record that was processed		
                    System.debug('Successfully deleted account with ID: ' + dr.getId());		
                }		
                else {		
                    // Operation failed, so get all errors                		
                    for(Database.Error err : dr.getErrors()) {		
                        System.debug('The following error has occurred.');                    		
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());		
                        System.debug('checklist fields that affected this error: ' + err.getFields());		
                    }		
                }		
            }		
        }		
    }
    
    public static Id doQuickInsert( PEO_Onboarding_Checklist__c parentChecklist) {
        Database.UpsertResult upsertChecklistResult = Database.upsert(parentChecklist, false);
        return upsertChecklistResult.getId();
    }
     
    public static PEO_Onboarding_Checklist__c copyChecklistValues(PEO_Onboarding_Checklist__c parentChecklist, PEO_Onboarding_Checklist__c newChecklist, Account prospect,User runningUser, String medicalUWPathType, String workersCompUWPathType) {
        if (parentChecklist == null || newChecklist == null || prospect == null) {
            System.debug('has null value');
            return null;
        }
        system.debug('parentChecklist '+parentChecklist);
        System.debug(' newChecklist: '+newChecklist);
        try {
            system.debug('copyChecklistValues for account '+prospect.name+' isChild?: '+prospect.isChild__c+' parentChecklistId: '+parentChecklist.Id);
            // copy the core values such as name, reps, prospect lookup, and oppty only if they need to be copied
            if (newChecklist.prospect_client__c == null) newChecklist.Prospect_Client__c = prospect.Id;
            if (prospect.isChild__c) newChecklist.Parent_PEO_Checklist__c = parentChecklist.Id;
            if (newChecklist.Name == null || newChecklist.Name != prospect.Name) newChecklist.Name = prospect.Name;
            //if (newChecklist.PEO_NSC__c == null) newChecklist.PEO_NSC__c = (parentChecklist.PEO_NSC__c != null?  parentChecklist.PEO_NSC__c : null) ;
            if (newChecklist.OwnerId == null) newChecklist.OwnerId = (parentChecklist.OwnerId != null ?  parentChecklist.OwnerId : runningUser.Id);
            if (newChecklist.Sales_Rep__c == null) {
                newChecklist.Sales_Rep__c = (parentChecklist.Sales_Rep__c != null ? parentChecklist.Sales_Rep__c : runningUser.Id) ;
            }
            if (newChecklist.Payroll_Frequency__c == null) newChecklist.Payroll_Frequency__c = (parentChecklist.Payroll_Frequency__c != null ? parentChecklist.Payroll_Frequency__c : null);
            
            // always copy the answers of the answers
            newChecklist.Medical_Benefits_Underwriting_Requested__c = (parentChecklist.Medical_Benefits_Underwriting_Requested__c != null ? parentChecklist.Medical_Benefits_Underwriting_Requested__c : null);
            newChecklist.Medical_Underwriting_Path__c = (parentChecklist.Medical_Underwriting_Path__c != null ? parentChecklist.Medical_Underwriting_Path__c : null);
            newChecklist.Submit_to_Workers_Comp_Underwriting__c = (parentChecklist.Submit_to_Workers_Comp_Underwriting__c != null ? parentChecklist.Submit_to_Workers_Comp_Underwriting__c : null);
            //newChecklist.Benefit_Effective_Date__c = (parentChecklist.Benefit_Effective_Date__c != null ? parentChecklist.Benefit_Effective_Date__c : null);
            newChecklist.Workers_Comp_FastPass__c = (parentChecklist.Workers_Comp_FastPass__c != null ? parentChecklist.Workers_Comp_FastPass__c : null);
            newChecklist.WC_Codes_are_in_Target_Hazard_Group__c = (parentChecklist.WC_Codes_are_in_Target_Hazard_Group__c != null ? parentChecklist.WC_Codes_are_in_Target_Hazard_Group__c : null);
            newChecklist.WC_Premium_is_less_than_10_000__c = (parentChecklist.WC_Premium_is_less_than_10_000__c != null ? parentChecklist.WC_Premium_is_less_than_10_000__c : null);
            newChecklist.Health_Benefits_Currently_through_a_PEO__c = (parentChecklist.Health_Benefits_Currently_through_a_PEO__c != null ? parentChecklist.Health_Benefits_Currently_through_a_PEO__c : null);
            newChecklist.Select_Child_Accounts__c = parentChecklist.Select_Child_Accounts__c;		
            newChecklist.Child_Account_Ids__c = parentChecklist.Child_Account_Ids__c;
            newChecklist.Medical_Underwriting_Path_Option__c = parentChecklist.Medical_Underwriting_Path_Option__c;
            newChecklist.display_Benchmark_tab__c = parentChecklist.display_Benchmark_tab__c;
            newChecklist.Platform__c = parentChecklist.Platform__c;
            newChecklist.Current_Aff_with_Paychex_PEO_Oasis__c = parentChecklist.Current_Aff_with_Paychex_PEO_Oasis__c;
            newChecklist.Client_Number__c = parentChecklist.Client_Number__c;
            newChecklist.Is_this_a_current_Paychex_Agency_Client__c = parentChecklist.Is_this_a_current_Paychex_Agency_Client__c;
            newChecklist.Parent_Company_Legal_Name__c = parentChecklist.Parent_Company_Legal_Name__c;
            newChecklist.Parent_Paychex_oasis_Num__c = parentChecklist.Parent_Paychex_oasis_Num__c;
            newChecklist.Parent_appro_self_retain_workers_comp__c = parentChecklist.Parent_appro_self_retain_workers_comp__c;
            newChecklist.Is_Medical_Underwriting_Requested__c = parentChecklist.Is_Medical_Underwriting_Requested__c;
            newChecklist.Do_you_need_full_underwriting_path__c = parentChecklist.Do_you_need_full_underwriting_path__c;
            newChecklist.why_choose_full_underwriting_path__c = parentChecklist.why_choose_full_underwriting_path__c;
            newChecklist.Client_Add_on__c = parentChecklist.Client_Add_on__c;
            
            if(parentChecklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote'){
                newChecklist.Medical_Carriers_currently_in_use__c = null;
                newChecklist.medical_coverage_renewal_date__c = null;
                newChecklist.Is_Your_Plan_Self_Funded_or_Level_Funded__c = null;
            }
            if(parentChecklist.Is_Medical_Underwriting_Requested__c != 'Currently have Medical, please quote' && 
               parentChecklist.Is_Medical_Underwriting_Requested__c != 'Currently does not have Medical, please quote'){
                newChecklist.Benefit_Effective_Date__c = null;
                newChecklist.Headquarter_State__c = null;
            }
            newChecklist.Medical_Underwriting_Path_Type__c = medicalUWPathType;	
            newChecklist.Workers_Comp_Underwriting_Path_Type__c = workersCompUWPathType;
            if (newChecklist.Opportunity__c == null) newChecklist.Opportunity__c = (parentChecklist.Opportunity__c != null ? parentChecklist.Opportunity__c : null);
            return newChecklist;
        }catch(Exception e) {
            
            return null;
        }
    }
    
    
    @AuraEnabled 
    public static List<PEO_Onboarding_Document__c> getPEOOnboardingDocs(String recordId){
        system.debug('getPEOOnboardingDocs Id: ' + recordId);
        return  [SELECT Id, PEO_Onboarding_Checklist__c, Name, Routing_Name__c,Status__c, Parent_Account__c,PEO_Doc_Required__c FROM 
          PEO_Onboarding_Document__c WHERE PEO_Onboarding_Checklist__c = :recordId];                        
    }
    
    @AuraEnabled
    public static void UpdatePEOOnboardingDocs(List<PEO_Onboarding_Document__c> peoonchkdocuments) {
    	    DmlHelper.performDML2(peoonchkdocuments, 
                                  DmlHelper.DML_UPDATE, 'ConvertContactToCommunityUser', 
                                  'UpdatePEOOnboardingDocs', 'Updating Documents', false);  
    }
    
    /*
     * Get records used in the PEOUWConvertContactToCommunityUser aura component
     * Retrieves: 
     * 	- Opportunity attached to Account
     * 	- Checklist attached to Account
     * 	- Child accounts of the account
     * @PARAMS: ID<Account>
     * @RETURNS: RecordWrapper(Opportunity, PEO_Onboarding_Checklist__c, Map<String, Object>)
     */
    @auraEnabled
    public static RecordWrapper getOpportunityAndChecklistDocuments(Id accountId) {
        try {
            RecordWrapper wrapper = new RecordWrapper();
            wrapper.opportunityForAccount = getOpp(accountId);
            wrapper.existingChecklist = checkForExistingChecklist(accountId);
            wrapper.childAccountMap = getChildAccounts(accountId);
            return wrapper;
        }catch(Exception e) {
            ErrorLog.logError('ConvertContactToCommunityUser', 'getOpportunityAndChecklistDocuments', 'getOpportunityAndChecklistDocuments Error', accountId, e, null, true);
            throw new AuraHandledException('Error retrieveing records ' + e.getMessage());
        }
    } // getOpportunityAndChecklistDocuments
    
    @TestVisible
    class RecordWrapper {
        @AuraEnabled
        public Opportunity opportunityForAccount;
        
        @AuraEnabled
        public PEO_Onboarding_Checklist__c existingChecklist;
        
        @AuraEnabled
        public Map<String, Object> childAccountMap;
    }
    
    /*
     * Get attributes required to initialize the PEOUWConvertContactToCommunityUser component
     * Retrieves: 
     * 	- List of permissions
     * 	- Checklist attached to Account
     * 	- Child accounts of the account
     * @PARAMS: ID <Contact>
     * @RETURNS: ConfigurationWrapper(String, User, Contact, User, List<String>)
     */
    @AuraEnabled
    public static ConfigurationWrapper getInitializationAttributes(Id contactId) {
        try {
            ConfigurationWrapper wrapper = new ConfigurationWrapper();
           
            Boolean hasEmailPermission = FeatureManagement.checkPermission('PEO_Getting_Started_Invite_Paychex');
            
            if(wrapper.runningUser.UserType == 'Standard' && wrapper.runningUser.Profile.Name != 'System Administrator' && !Test.isRunningTest()){
                if(!hasEmailPermission){
                    wrapper.missingPermissionsList.add('Paychex Email');
                }
            }
            
            Contact[] cons = [SELECT name, firstName, lastName, 
                              email, phone, AccountId, 
                              Account.SalesParent__c,
                              Account.SalesParent__r.Name, 
                              Account.AccountNumber,
                              Account.Name 
                              FROM Contact 
                              WHERE id=:contactId LIMIT 1];
            if (!cons.isEmpty()) wrapper.contactRecord = cons[0];
            
            // check & is active?
            User[] communityUsersForContact = [SELECT Name,isActive,ContactId,
                                               Account.SalesParent__c,
                                               Account.SalesParent__r.Name, 
                                               Account.AccountNumber,
                                               Account.Name, Username, CommunityNickname, 
                                               Alias,Email,LastLoginDate 
                                               FROM User 
                                               WHERE ContactId =: contactId
                                               LIMIT 1];
            if (!communityUsersForContact.isEmpty()) wrapper.communityUserRecord = communityUsersForContact[0];
            return wrapper;
        }catch(Exception e) {
            ErrorLog.logError('ConvertContactToCommunityUser', 'getInitializationAttributes', 'getInitializationAttributes Error', contactId, e, null, true);
            throw new AuraHandledException('Unable to retrieve initialization details' + e.getMessage());
        }
    } // getInitializationAttributes
    
    @TestVisible
    class ConfigurationWrapper {
        @AuraEnabled
        public string env = Utilities.checkForProduction();
        
        @AuraEnabled
        public User runningUser = UserHelper.getRunningUser();
        
        @AuraEnabled
        public Contact contactRecord;
        
        @AuraEnabled
        public User communityUserRecord;
        
        @AuraEnabled
        public List<String> missingPermissionsList = new List<String>();
    }
}