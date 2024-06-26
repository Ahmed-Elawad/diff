/* 
* The methods used for assisting with User record transactions.
*
* History
* -------
* 06/04/2020 Dan Carmen   Created
* 08/10/2020 Dan Carmen   Fix for call center field not clearing when user goes inactive
* 10/09/2020 Jake Hinds   Adding without sharing per PMD
* 11/23/2020 Dan Carmen   Added check for SSO flag.
* 12/15/2020 Dan Carmen   Update for how the FederationIdentifier is being set.
* 02/09/2020 Jake Hinds   Putting try catch around job abort code
* 02/23/2020 Jake Hinds   Adding RJMethods call in before trigger
* 03/04/2021 Jake Hinds   Making trigger only fire for standard users
* 03/26/2021 Jake Hinds   Commenting out RJMethods call
* 05/18/2021 J Stukes     Add Hr Partner to MMSASOPartnerQueueable logic
* 07/16/2021 Jake Hinds   Adding call to CommunityMethods
* 07/22/2021 Dan Carmen   Add check for HR_Services_Partner__c to inactive user check
* 22/12/2021 Jaipal       Adding check for DSM users and generating email
* 02/01/2022 Jake Hinds   Adding call to CommunityMethods check if checklist complete
  02/04/2022 Dan Carmen   Add check for user lookup on contact if status changes
* 03/17/2022 Shilpa Govindarajulu	Commented QuoteMethods class references as part of SBQQ Package Removal 
  08/03/2022 Dan Carmen   Add check for profiles for the before insert trigger since the usertype isn't set. 
  01/13/2023 Josh Cartwright  added changes for Accountant Program Portal - new email service 
  03/06/2023 Carrie Marciano Added profile check to auto set the CPQ_Mandate_Eligibility__c checkbox on the user
  06/27/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu) added skipInactiveQueueable variable to prevent user transfers from running queueable they need to be async
  01/03/2024 Dan Carmen      Add logic to link the user to the contact if updated by a particular user

*/
public without sharing class UserTriggerMethods {
    public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        SObject usrObj = (SObject)(Type.forName('Schema.'+ 'User').newInstance());
           usrObj.Id = Userinfo.getUserId();
        //system.debug('oldMap'+oldMap.get(Userinfo.getUserId()));
       // system.debug((User)p_recs[0].EmailPreferencesAutoBcc + 'old');  
        SObject[] recs = (UserHelper.SKIP_USER_TRIGGERS ? new SObject[]{} : TriggerMethods.checkRecs('UserTriggerMethods', p_recs, oldMap, isBefore, isAfter, isDelete, null, null));
        if (recs == null || recs.isEmpty()) {
            return;
        }
        SObjectType objType = TriggerMethods.objType;
        String objTypeName = TriggerMethods.objectTypeName;
        System.debug('UserHelper objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);
        
        if (isBefore) {
            //if (objType == Contact.sObjectType) {
            handleUserBefore((User[])recs,(Map<Id,User>)oldMap);
            //}
        } // if (isBefore)
        if (isAfter) {
            system.debug('testing....');
            handleUserAfter((User[])recs,(Map<Id,User>)oldMap);
        }
    } // handleTrigger
    
    // the users we want to force the evaluation for permission set group assignment
    public static Id[] evaluatePermissionSetIds = new Id[]{};   
    public static String[] licenseNames = Label.UserTriggerMethods_LicensesToInclude.split(',');
    public static String[] CPQMandateProfiles = label.CPQ_Mandate_Eligibility.split(',');
    public static Boolean skipInactiveQueueable = false;
    
    public static void handleUserBefore(User[] recs, Map<Id,User> oldMap) {
       evaluatePermissionSetIds.clear();
       // if user is activated, check to see if a federation id can be added
       map<String, user> statusChangedMap = new map<String, user>();
       // hr person ids from the users with status changes
       String[] statusPersonIds = new String[]{};
       
       // do this check for all users
       User[] checkOrgInfo = new User[]{};
       Set<String> orgStructureDivisionSet = UserHelper.getDivisionStructureSet();
       // check for the DSA/FSS
       User[] checkDsa = new User[]{};
       // check for forecast sharing
       Map<Id,User> checkForecastSharing = new Map<Id,User>();
       // users that went from active to inactive 
       Id[] inactiveUserIds = new Id[]{};
                
       // always check the jobs
       UserHelper.checkForJobName(recs);
       //RJMethods.checkOACFieldChange(recs,oldMap);
       Set<Id> validProfileIds = new Set<Id>();
       Map<Id,Profile> profMap = new Map<Id,Profile>();
      
        Id[] profileIds = new Id[]{};
            for (User usr : recs) {
                User oldU = (oldMap != null ? oldMap.get(usr.Id) : null);
                if (usr.ProfileId != null && (oldU == null || (oldU.ProfileId != usr.ProfileId))) {
                    profileIds.add(usr.ProfileId);
                }
            } // for (User usr
        if (!profileIds.isEmpty()) {
            profMap = new Map<Id,Profile>([Select Id, Name from Profile where Id in :profileIds and UserLicense.Name in :licenseNames]);
            if (!profMap.isEmpty()) {
                validProfileIds.addAll(profMap.keySet());
            }
        } // if (!profileIds.isEmpty
            
       for (User usr : recs) {
          System.debug('handleUserBefore usr='+usr.LastName+' userType='+usr.UserType+' profMap='+profMap.size());
          User oldU = (oldMap != null ? oldMap.get(usr.Id) : null);
          // UserType isn't set in a before insert operation.
          if (usr.UserType == 'Standard' || (usr.ProfileId != null && validProfileIds.contains(usr.ProfileId))) {
                    // always check
                    checkOrgInfo.add(usr);
                    // only populate from the trigger once - once person id is populated, don't need to do anything anymore
                    if ((usr.HR_Person_Id__c == null) && (usr.EmployeeNumber != null)) {
                        String newPersonId = Utilities.removeExtraChars(usr.EmployeeNumber, Utilities.ALL_NUMBERS);
                        usr.HR_Person_Id__c = ((newPersonId != null && newPersonId.length() > 0) ? newPersonId : null);
                    } 
                    // only if AD_Username__c is null or email address changes
                    if (usr.IsActive && usr.UserRoleId != null 
                        && (usr.EBS_Username__c == null || usr.AD_Username__c == null || (oldU != null && usr.Username != oldU.Username))) {
                            checkEbsUsername(usr);
                            checkADUsername(usr);
                        }
                    
              		// set CPQ Mandate Eligibility based on profile custom label
                    if (usr.ProfileId != null && profMap.containsKey(usr.ProfileId)){
                        Profile profileRec = profMap.get(usr.ProfileId);
                        System.debug('handleUserBefore usr.ProfileId: '+usr.ProfileId+' profileRec.Name '+ profileRec.Name);  
        				usr.CPQ_Mandate_Eligibility__c = (CPQMandateProfiles.contains(profileRec.Name) ? True : False);   
        				System.debug('handleUserBefore usr.CPQ_Mandate_Eligibility__c '+usr.CPQ_Mandate_Eligibility__c);  
                    }
              
                    System.debug('handleUserBefore usr.HR_Person_Id__c='+usr.HR_Person_Id__c);
                    if (usr.HR_Person_Id__c != null && usr.IsActive && (usr.FederationIdentifier == null || oldU == null || (oldU != null && !oldU.IsActive))) {
                        // if a user is created or changed to active
                        statusChangedMap.put(usr.HR_Person_Id__c, usr);       
                        //statusPersonIds.add(usr.HR_Person_Id__c);
                    } else if (usr.FederationIdentifier != null && !usr.IsActive) {
                        // if a user goes inactive, remove the FederationIdentifier
                        usr.FederationIdentifier = null;
                    }
                    if (orgStructureDivisionSet.contains(usr.Sales_Org__c)) {
                        checkDsa.add(usr);
                        
                        if (usr.UserRoleId != null && (oldU == null || usr.UserRoleId != oldU.UserRoleId)) {
                            checkForecastSharing.put(usr.Id,usr);   
                        }
                    }
                    if (!usr.IsActive && oldU != null && oldU.IsActive) {
                        usr.CallCenterId = null;
                        inactiveUserIds.add(usr.Id);
                    }
                    if (usr.EvaluatePermissionSets__c && usr.Id != null) {
                        usr.EvaluatePermissionSets__c=false;
                        evaluatePermissionSetIds.add(usr.Id);
                    }
                    
                    if (usr.IsActive && (usr.Send_Paychex_SSO_New_User_Email__c ||
                                         (oldU == null || (!oldU.IsActive)))
                       ) {
                           usr.Send_Paychex_SSO_New_User_Email__c = false; 
                           usr.SSOEmailSent__c = datetime.now();
                       }
                }//if user type is standard
            } // for (User usr : recs
            System.debug('handleUserBefore checkOrgInfo='+checkOrgInfo.size()+' statusChangedMap='+statusChangedMap.size()+' checkDsa='+checkDsa.size());
            
            if (!checkOrgInfo.isEmpty()) {
                UpdateOrgInfo.SetUserInfo(checkOrgInfo);
            } 
            if (!statusChangedMap.isEmpty()) {
                setFederationID(statusChangedMap); 
            }
            
            if (!checkForecastSharing.isEmpty()){
                UserForecastSharing.setForecastSharing(checkForecastSharing);
            }  
            
            if (!checkDsa.isEmpty()) {
                UserHelper.checkForDSA(checkDSA);
            }
            
            // don't let this be called if this flag is set to false
            if (!inactiveUserIds.isEmpty()) {
                checkInactiveUser(inactiveUserIds);
                if (UserHelper.ALLOW_ROLE_CALLOUT && !System.isFuture() && !System.isBatch()) {
                    UserHelper.checkOrgUnitsForInactive(inactiveUserIds);
                    ActivityDeleteRecurring.checkActivity(inactiveUserIds);
                }
            } // if (!inactiveUserIds
            System.debug('handleUserBefore end');
        } // handleUserBefore
    
    // for use in the ProcessNameMap__c custom setting to see if the user is an admin user
    public static final String USER_ATTR='User-';
    
    public static void handleUserAfter(User[] recs, Map<Id,User> oldMap) {
        System.debug('handleUserAfter begin recs='+(recs != null ? recs.size() : -1)+' oldMap='+(oldMap != null)); 
        User runningUser = UserHelper.getRunningUser();
        // the user admin is the generic user that creates/manages the user records through the API
        Boolean isUserAdmin = (runningUser != null ? UserHelper.hasActiveProcessName(USER_ATTR+runningUser.Name) : false);
        System.debug('handleUserAfter isUserAdmin='+isUserAdmin);
        // if a PEO user is created, we will create an email to notify the appropriate people 
        User[] peoUsers = new User[]{};
        User[] DsmUsers = new User[]{};
        Set<Id> profileIdSet = new Set<Id>();
        Set<Id> roleIdSet = new Set<Id>();
        // if the user is Inactivated, cancel all of their scheduled jobs 
        Map<Id,User> inactiveUsers = new Map<Id,User>();
        // did the role change on the user record?
        Id[] userRoleChangedIds = new Id[]{};
        User[] usersASOPartner = new User[]{};
        // we're going to evaluate if we need to add these users to permission set groups
        Map<Id,User> evaluatePermissionSetMap = new Map<id,User>();
        //store account ids, this field is set systematically for community users based on contactid
        Set<Id> accountIds = new Set<Id>();
      	Set<Id> accountIdsForChecklistCompleteCheck = new Set<Id>();
        
        // if the active flag changes (or a new record)
        Set<String> statusChangedPersonIdSet = new Set<String>();
        // Start: Update By Rohith for Story SFDC-15955	
        Map<Id,Id> mapOfContactWithUser = new Map<Id,Id>();	
        List<Contact> finalContactList = new List<Contact>();
        Map<Id,Id> mapOfDeactiavingUser = new Map<Id,Id>();
        List<Contact> deactiveContact = new List<Contact>();
        List<User> newUserListCPA = new List<User>();
        Map<Id,User> oldMapCPA = new Map<Id,User>();
        // check the linkage to the contact record by users created/updated by the userAdmin user.
        Map<String,User> checkCtctMap = new Map<String,User>();
        	
        for (User usr : recs) {
            User oldUsr = (oldMap != null ? oldMap.get(usr.Id) : null);
            if (isUserAdmin && String.isNotBlank(usr.HR_Person_Id__c)) {
               checkCtctMap.put(usr.HR_Person_Id__c, usr);
            }
            if(usr.UserType == 'Standard'){
                if(usr.EmailPreferencesAutoBcc ==  false && usr.Securities_License__c == True) //oldUsr.EmailPreferencesAutoBcc == true && usr.EmailPreferencesAutoBcc != oldUsr.EmailPreferencesAutoBcc  )
                   { // Securities_License__c field checked for LG market users to trigger email for compliance
                    DsmUsers.add(usr); 
                }
                
                if (oldUsr == null && usr.IsActive && usr.Sales_Org__c == UserHelper.SO_PEO) {
                    peoUsers.add(usr);
                    profileIdSet.add(usr.ProfileId);
                    roleIdSet.add(usr.UserRoleId);
                }
                if (String.isNotBlank(usr.HR_Person_Id__c) && (oldUsr == null || usr.IsActive != oldUsr.IsActive) ) {
                   statusChangedPersonIdSet.add(usr.HR_Person_Id__c); 
                }
                if (!usr.IsActive && oldUsr != null && oldUsr.IsActive) {
                    inactiveUsers.put(usr.Id, usr);
                }
                if (UserHelper.DIVISION_LIST_SET.contains(usr.Sales_Org__c) && usr.IsActive && usr.UserRoleId != null && oldUsr != null && usr.UserRoleId != oldUsr.UserRoleId) {
                    userRoleChangedIds.add(usr.Id);
                }
                // see if any of the pertinent user information changes where we should evaluate permission set group assignment
                if (usr.IsActive && usr.ProfileId != null && usr.UserRoleId != null
                    && (evaluatePermissionSetIds.contains(usr.Id) || oldUsr == null
                        || usr.ProfileId != oldUsr.ProfileId
                        || usr.Job_Name__c != oldUsr.Job_Name__c
                        || usr.Sales_Org__c != oldUsr.Sales_Org__c
                        || usr.NSS_Team__c != oldUsr.NSS_Team__c)) {
                            evaluatePermissionSetMap.put(usr.Id,usr);     
                            profileIdSet.add(usr.ProfileId);
                        }
                if (oldUsr != null) {
                    if (/*usr.ASO_Partner__c != oldUsr.ASO_Partner__c ||*/ usr.HR_Services_Partner__c != oldUsr.HR_Services_Partner__c){
                        usersASOPartner.add(usr);
                    }
                } // if (oldUsr != null
            }//user type is standard
            //community users
            else{
                // Start: Update By Rohith for Story SFDC-15955	
                if(!usr.IsActive){
                    mapOfDeactiavingUser.put(usr.ContactId, usr.Id);
                }
                if(usr.ContactId != null){	
					mapOfContactWithUser.put(usr.ContactId, usr.Id);	
				}	
                 // End: Update By Rohith for Story SFDC-15955
                 
                //JDA
                System.debug('User data:'+usr);
                if(usr.ContactId != null && usr.ProfileName__c == 'CPA Customer Community Login User Clone'){	
                    newUserListCPA.add(usr);	
                }	
                
                if(oldUsr == null && user.AccountId!=null && usr.ProfileName__c!=null && usr.ProfileName__c != 'CPA Customer Community Login User Clone'&&!accountIds.contains(usr.AccountId)){
                    system.debug('UserTriggerMethods is commuser');
                    accountIds.add(usr.AccountId);
                }
                //probably will only be filled in on insert but the login process is screwy so just in case, 
                //checking both insert and update for the field to be entered
                if(usr.AccountId!=null && usr.ProfileName__c!=null && usr.ProfileName__c != 'CPA Customer Community Login User Clone'&& !accountIdsForChecklistCompleteCheck.contains(usr.AccountId) 
                      && ((oldUsr != null && oldUsr.Community_User_First_Login__c == null && usr.Community_User_First_Login__c != null)
                     		|| (oldUsr== null && usr.Community_User_First_Login__c == null))){
                	system.debug('user logged in for the first time');
                    accountIdsForChecklistCompleteCheck.add(usr.AccountId);
                }
            } 
        } // for (User usr : users
        // Start: Update By Rohith for Story SFDC-15955		
		if(!mapOfContactWithUser.isEmpty()){	
			for(Contact con : [Select Id,Name,User_Lookup__c from Contact Where Id IN :mapOfContactWithUser.keySet()]){	
				if(con != null){
                    if(con.User_Lookup__c != mapOfContactWithUser.get(con.Id)){
                        con.User_Lookup__c = mapOfContactWithUser.get(con.Id);	
                        finalContactList.add(con);
                    }
                }	
			}
            System.debug('Update Thsi Contact Rohith '+finalContactList);
            if(finalContactList != null && finalContactList.size() >0 ){
                  ID jobID = System.enqueueJob(new AsyncExecutionExample(finalContactList));
            }				
		}
        
        //JDA
        System.debug('handleUserAfter newUserListCPA:'+newUserListCPA);
        if(newUserListCPA != null && newUserListCPA.size()>0){	
            //UserTriggerHandler.onAfterUpdate(newUserListCPA,oldMapCPA);
            List<Id> updatedUserIds = new List<Id>();
            for(User usr: newUserListCPA){
                updatedUserIds.add(usr.Id);
            }
            sendCPaStatusChange(updatedUserIds[0]);
        }
         // End: Update By Rohith for Story SFDC-15955
         
        if (!peoUsers.isEmpty()) {
            generatePeoEMail(peoUsers, profileIdSet, roleIdSet);
        }
        System.debug('UserTriggerMethods DSMusers='+DsmUsers.size());
        if(!DsmUsers.isEmpty()){
            generateDSMEMail(DsmUsers);
        }
        
      if (!skipInactiveQueueable && (!statusChangedPersonIdSet.isEmpty() || !inactiveUsers.isEmpty())) {
          System.debug('UserTriggerMethods checking inactive xsmb channel change');
          System.debug('UserTriggerMethods statusChangedPersonIdSet.Size(): '+statusChangedPersonIdSet.Size());
          System.debug('UserTriggerMethods inactiveUsers.Size(): '+inactiveUsers.Size());
          ID jobID = System.enqueueJob(new InactiveUserAccountQueueable(inactiveUsers, statusChangedPersonIdSet));
      }
       
      if (!checkCtctMap.isEmpty()) {
         checkCtctLinkage(checkCtctMap);
      }
      if(!inactiveUsers.isEmpty()) {
            if (UserHelper.ALLOW_ROLE_CALLOUT) {
                for (CronTrigger ct : [Select Id, NextFireTime, State, OwnerId from CronTrigger where State != 'DELETED' and OwnerId IN :inactiveUsers.keySet()]) {
                    try{
                        System.abortjob(ct.Id);      
                    } 
                    catch(exception e){
                        Errorlog.logError('UserTriggerMethods', 'handleUserAfter', 'abort cron job', ct.OwnerId, e,null,false);
                    }
                }
                ErrorLog.checkSave();
            } // if (!inactiveUsers.isEmpty
        }
        
        System.debug('handleUserAfter  UserHelper.ALLOW_ROLE_CALLOUT='+ UserHelper.ALLOW_ROLE_CALLOUT+' evaluatePermissionSetMap='+evaluatePermissionSetMap.size());
        if (UserHelper.ALLOW_ROLE_CALLOUT && !userRoleChangedIds.isEmpty() && !System.isFuture() && !System.isBatch()) {
            UserHelper.handleUserRoleChanged(UserInfo.getSessionId() ,userRoleChangedIds);
        } // if (!userRoleChangedIds.isEmpty
        
        if (!usersASOPartner.isEmpty()) {
            MMSASOPartnerQueueable mapq = new MMSASOPartnerQueueable(usersASOPartner);
            System.enqueueJob(mapq);
        }
        
        if (!evaluatePermissionSetMap.isEmpty()) {
            handlePermissionSetGroups(evaluatePermissionSetMap, profileIdSet);
        }
        if (!accountIds.isEmpty()){
            CommunityMethods.checkForOpportunity(accountIds);
        }
        if (!accountIdsForChecklistCompleteCheck.isEmpty()){
          getChecklist(accountIdsForChecklistCompleteCheck);
      }
      system.debug('handleUserAfter end');
    } // handleUserAfter
    
    public static final String QUEUEABLE_NAME='UpdateCtctFromUser';
    
    public static void checkCtctLinkage(Map<String,User> usrByPrsnIdMap) {
       // drop contacts in the map to get the ids - if the contacts are already linked to the contact we don't need to do anything
       // so we'll exclude them from the query
       Map<Id,User> userMap = new Map<Id,User>(usrByPrsnIdMap.values());
       // look for existing records
       Contact[] ctcts = [Select Id, Name, HR_Person_Id__c, User_Lookup__c 
                            from Contact 
                           where HR_Person_Id__c in :usrByPrsnIdMap.keySet() and User_Lookup__c not in :userMap.keySet()]; 
       // the contacts we'll update to link to the user record
       Contact[] updateCtcts = new Contact[]{};
       for (Contact ctct : ctcts) {
          User usr = usrByPrsnIdMap.get(ctct.HR_Person_Id__c);
          if (usr != null && ctct.User_Lookup__c != usr.Id) {
             ctct.User_Lookup__c = usr.Id;
             updateCtcts.add(ctct);
          }
       } // for (Contact ctct : ctcts
       // so we don't get a mixed DML operation, we'll do the actual update in a queueable
       if (!updateCtcts.isEmpty()) {
         Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(QUEUEABLE_NAME);
         Boolean allowQueueable = (abc != null && abc.Active__c);
         System.debug('ContactFormatPaychexEmps.checkUserCtctMatch allowQueueable='+allowQueueable);
         UpdateCtctFromUser ucfu = new UpdateCtctFromUser(updateCtcts);
         if (allowQueueable && Utilities.allowFuture()) {
            System.enqueueJob(ucfu);
         }
       } // if (!updateCtcts
    } // checkCtctLinkage
    
   public class UpdateCtctFromUser implements Queueable {
      public Contact[] ctcts;
      public UpdateCtctFromUser(Contact[] p_ctcts) {
         ctcts = p_ctcts;
      } // UpdateCtctFromUser
       
      public void execute(QueueableContext context) {
         System.debug('UpdateCtctFromUser in execute method');
         handleUpdate();
      } // execute

      public void handleUpdate() {
         if (!ctcts.isEmpty()) {
            DmlHelper.performDML2(ctcts, DmlHelper.DML_UPDATE, 'UpdateCtctFromUser', 'handleUpdate', 'updating contacts', true);
         }

     } // handleUpdate
      
  } // class UpdateCtctFromUser

    public static void checkEbsUsername(User usr) {
        String checkStr = usr.Username;
        if (String.isNotBlank(checkStr)) {
            usr.EBS_Username__c = checkStr.substring(0,checkStr.indexOf('@'));
        }
    } // checkEbsUsername
    
    public static void checkADUsername(User usr) {
        // derive the username from the email address - everything before the '@'
        String checkStr = usr.Username;
        if (String.isNotBlank(checkStr)) {
            usr.AD_Username__c = checkStr.substring(0,checkStr.indexOf('@'));
            if(usr.AD_Username__c.length() > 8){
                List<String> ls = usr.AD_Username__c.splitByCharacterTypeCamelCase();
                if (ls.size() > 1) {
                    string lastValue = ls.remove(ls.size()-1);
                    string alpha = String.join(ls,'');
                    alpha = alpha.left(8-lastValue.length());
                    usr.AD_Username__c = alpha + lastValue;
                } else{
                    usr.AD_Username__c = usr.AD_Username__c.left(8);
                }
            }
        }
    } // checkADUsername
    
    public static void setFederationID (map<String, user> userByPersonIdMap) {
        System.debug('setFederationID userMap='+userByPersonIdMap.size());
        // select the contacts so we can 1) determine if employee and 2) determine if latest
        list<contact> ctcts = [select id, User_Lookup__c, User_Lookup__r.Profile.Name
                               ,User_Lookup__r.Id
                               ,User_Lookup__r.HR_Person_Id__c
                               ,User_Lookup__r.IsActive
                               ,User_Lookup__r.FederationIdentifier
                               ,HR_Person_Id__c 
                               from contact 
                               where HR_Person_Id__c in :userByPersonIdMap.keySet()]; 
        // store in a map for easy reference
        Map<String,Contact> ctctPersonIdMap = new Map<String,Contact>();
        for (contact c: ctcts) {
            if (c.HR_Person_Id__c != null) {
                //linkedContactMap.put(c.User_Lookup__c,c); 
                ctctPersonIdMap.put(c.HR_Person_Id__c, c);
            }//if
        } //for 
        
        for (User usr : userByPersonIdMap.values()) {
            Contact ctct = ctctPersonIdMap.get(usr.HR_Person_Id__c);
            // if there isn't a contact with the person id, or the contact isn't already linked, 
            // or if for some reason the contact is linked but the federation id isn't set.
            if (ctct == null || ctct.User_Lookup__c == null || ctct.User_Lookup__c == usr.Id) {
                usr.FederationIdentifier = usr.HR_Person_Id__c;
            } else if (ctct != null && ctct.User_Lookup__c != null) {
                // if the contact currently linked isn't active and doesn't have a federation id
                if (!ctct.User_Lookup__r.IsActive && String.isBlank(ctct.User_Lookup__r.FederationIdentifier)) {
                    usr.FederationIdentifier = usr.HR_Person_Id__c;
                }
            }
        } // for (User usr : userMap.values
        
    }//setFederationID    
    
    // when a user is made inactive, remove them from linkings so they don't cause issues.
    public static void checkInactiveUser(Id[] userIds) {
        System.debug('checkInactiveUser begin');
        // these will be excluded from adding back into the User record.
        UserHelper.excludeDSAUserIdSet.addAll(userIds);
        // for easy searching
        Set<Id> userIdSet = new Set<Id>();
        userIdSet.addAll(userIds);
        
        for (User[] users : [Select Id, DSA_FSS__c, ASO_Partner__c,HR_Services_Partner__c
                             from User 
                             where DSA_FSS__c in :userIds
                             or ASO_Partner__c in :userIds
                             or HR_Services_Partner__c in :userIds]) {
                                 // clear out any value that's found
                                 for (User usr : users) {
                                     if (usr.DSA_FSS__c != null && userIdSet.contains(usr.DSA_FSS__c)) {
                                         usr.DSA_FSS__c = null;
                                     }
                                     if (usr.ASO_Partner__c != null && userIdSet.contains(usr.ASO_Partner__c)) {
                                         usr.ASO_Partner__c = null;
                                     }
                                     if (usr.HR_Services_Partner__c != null && userIdSet.contains(usr.HR_Services_Partner__c)) {
                                         usr.HR_Services_Partner__c = null;
                                     }
                                 } // for (User usr
                                 UserHelper.SKIP_USER_TRIGGERS = true;
                                 update users;
                                 System.debug('checkInactiveUser after update users');
                                 UserHelper.SKIP_USER_TRIGGERS = false;
                             } // for
    } // checkInactiveUser
    
    public static String PEO_EMAIL_ADDY=Label.UserHelperNewPEOEmail; 
    public static String DSM_EMAIL_ADDY=Label.DSM_and_christine_team_email;
    
    public static Boolean GENERATE_PEO_EMAIL=(PEO_EMAIL_ADDY != 'NoEmail');
    public static Integer nbrPeoEmails = 0;
    public static Boolean GENERATE_DSM_EMAIL=(DSM_EMAIL_ADDY != 'NoEmail');
    public static Integer nbrDsmemails = 0;
    
    
    public static void generatePeoEMail(User[] users, Set<Id> profileIdSet, Set<Id> roleIdSet) {
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
            Map<Id,Profile> profMap = new Map<Id,Profile>([Select Id, Name from Profile where Id in :profileIdSet]);
        Map<Id,UserRole> roleMap = new Map<Id,UserRole>([Select Id, Name from UserRole where Id in :roleIdSet]);
        
        for (User usr : users) {
            Profile prof = profMap.get(usr.ProfileId);
            UserRole role = roleMap.get(usr.UserRoleId);
            System.debug('generatePeoEMail usr='+usr.Username+' prof='+(prof != null ? prof.Name : 'NoProf')+' role='+(role != null ? role.Name : 'NoRole'));
            if (prof != null && role != null) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String msgTxt = 'New PEO User created.';
                msgTxt += '\nSF ID='+usr.Id;
                msgTxt += '\nName='+usr.FirstName+' '+usr.LastName;
                msgTxt += '\nUsername='+usr.Username;
                msgTxt += '\nEmail='+usr.Email;
                msgTxt += '\nProfile='+profile.Name;
                msgTxt += '\nRole='+role.Name;
                msgTxt += '\nCS User Id='+(String.isNotBlank(usr.CSUserId__c) ? usr.CSUserId__c : '');
                mail.setToAddresses(PEO_EMAIL_ADDY.split(','));
                mail.setSubject('New PEO User Setup');
                mail.setPlainTextBody(msgTxt);
                mail.setUseSignature(false);
                mail.setSaveAsActivity(false);
                emails.add(mail);
            }
        } // for (User usr : users
        
		 nbrPeoEmails = emails.size();
        if (GENERATE_PEO_EMAIL && !emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    } // generatePeoEMail
    
    //generateDSMEmail
    
    
    
    public static void generateDSMEMail(User[] users) {
        system.debug('ingenerateDSMEmail');
        List<emailtemplate> emailtemplateidList =[select id,name from EmailTemplate where name ='EmailPreferencesAutoBcc' limit 1];
        Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{};
            Map<Id,Id> userIdManagerIdMap = new Map<Id,Id>();
        for(User usr : Users){ userIdManagerIdMap.put(usr.Id,usr.managerId);}
        List<User> mgrUser =[Select id ,email from User where id in :userIdManagerIdMap.values()];
        Map<Id, User> ManagerIdMap = new Map<Id, User>(mgrUser);
        Map<Id,String> usrIdManagerEmailMap = new Map <Id,String>();
        for(Id i:userIdManagerIdMap.keyset()) {
            usrIdManagerEmailMap.put(i,ManagerIdMap.get(userIdManagerIdMap.get(i)).Email);
        }// getting manager email 
        
        for (User usr : users) {
            list<String>emailIdsToSend =new List<String>(DSM_EMAIL_ADDY.split(','));
            system.debug('manageremail'+usr.ManagerId+'--'+usrIdManagerEmailMap.get(usr.id));
            If ((usrIdManagerEmailMap.get(usr.id)!=null) && String.isNotBlank(usrIdManagerEmailMap.get(usr.id)))  {
                system.debug('Manager.Email'+usrIdManagerEmailMap.get(usr.id));
                emailIdsToSend.add(usrIdManagerEmailMap.get(usr.id));
                system.debug('emailids'+emailIdsToSend);
            }
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            system.debug('user');
            mail.setToAddresses(emailIdsToSend);
            mail.setTemplateId(emailtemplateidList.get(0).id);
            //mail.setWhatId(usr.Id);
            mail.setTargetObjectId(usr.Id);
            mail.setSaveAsActivity(false); 
            emails.add(mail);
            
        } // for (User usr : users
        if ( !emails.isEmpty()) {
            Messaging.sendEmail(emails); 
        }
    }
    
    public static void handlePermissionSetGroups(Map<Id,User> p_userMap, Set<Id> profileIdSet) {
        Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, ProfileId, Profile.Name, Sales_Org__c, Sales_Division__c, Job_Name__c from User where Id in :p_userMap.keySet()]);
        
        //Map<Id,Profile> profMap = new Map<Id,Profile>([Select Id, Name from Profile where Id in :profileIdSet]);
        // to recalculate the formula fields (specifically Sales Division in this case)
        //Formula.recalculateFormulas(userMap.values()); 
        
        // these are the only groups we're going to care about (if they're active in the custom setting). Otherwise we won't touch them
        Set<String> validGroupNames = new Set<String>(); 
        for (PermissionSetAssignment__c psa : PermissionSetAssignment__c.getAll().values()) {
            if (psa.Active__c) {
                validGroupNames.add(psa.PermissionGroupName__c);
            }
        } // for (PermissionSetAssignment__c psa
        
        // select the permission set groups so we can make assignments
        PermissionSetGroup[] grps = [Select id, MasterLabel, DeveloperName from PermissionSetGroup where MasterLabel in :validGroupNames];
        Map<String,PermissionSetGroup> grpMap = new Map<String,PermissionSetGroup>();
        for (PermissionSetGroup grp : grps) {
            grpMap.put(grp.MasterLabel, grp);
        }
        
        
        System.debug('handlePermissionSetGroups userMap='+userMap.size());
        // get the existing group assignments, group by user
        Map<Id,Map<String,PermissionSetAssignment>> permByUserMap = getExistingPerms(userMap.keySet(), validGroupNames);
        
        PermissionSetAssignment[] insertAsgns = new PermissionSetAssignment[]{};
            PermissionSetAssignment[] deleteAsgns = new PermissionSetAssignment[]{};
                
                for (User usr : userMap.values()) {
                    checkPermSetUser(usr, permByUserMap.get(usr.Id), grpMap, insertAsgns, deleteAsgns);
                } // for (User usr : userMap.values
        
        DmlHelper.performDML2(insertAsgns, DmlHelper.DML_INSERT, 'UserTriggerMethods', 'handlePermissionSetGroups', 'Insert new permission sets', false);
        DmlHelper.performDML2(deleteAsgns, DmlHelper.DML_DELETE, 'UserTriggerMethods', 'handlePermissionSetGroups', 'Delete permission sets', false);
        ErrorLog.checkSave();
    } // handlePermissionSetGroups
    
    public static Map<Id,Map<String,PermissionSetAssignment>> getExistingPerms(Set<Id> userIdSet, Set<String> groupNames) {
        // get the existing group assignments, group by user
        PermissionSetAssignment[] asgns = [Select Id, AssigneeId, PermissionSetId, PermissionSetGroupId 
                                           ,PermissionSet.Id
                                           ,PermissionSet.Label
                                           ,PermissionSet.Name
                                           ,PermissionSetGroup.Id
                                           ,PermissionSetGroup.MasterLabel
                                           ,PermissionSetGroup.DeveloperName
                                           from PermissionSetAssignment where AssigneeId in :userIdSet
                                           and PermissionSetGroup.MasterLabel in :groupNames    // Only select the ones for the groups we have definitions for
                                          ];
        System.debug('getExistingPerms userIdSet='+userIdSet.size()+' groupNames='+groupNames.size()+' asgns='+asgns.size());
        Map<Id,Map<String,PermissionSetAssignment>> permByUserMap = new Map<Id,Map<String,PermissionSetAssignment>>();
        for (PermissionSetAssignment asgn : asgns) {
            Map<String,PermissionSetAssignment> usrAsgnMap = (permByUserMap.containsKey(asgn.AssigneeId) ? permByUserMap.get(asgn.AssigneeId) : new Map<String,PermissionSetAssignment>());
            usrAsgnMap.put(asgn.PermissionSetGroup.MasterLabel, asgn);
            permByUserMap.put(asgn.AssigneeId, usrAsgnMap);
        } // for (PermissionSetAssignment asgn : asgns)
        return permByUserMap;
    } // getExistingPerms
    
    public static void checkPermSetUser(User usr, Map<String,PermissionSetAssignment> existingSetMap, Map<String,PermissionSetGroup> grpMap
                                        ,PermissionSetAssignment[] insertAsgns, PermissionSetAssignment[] deleteAsgns) {
                                            // so we don't have to deal with a null object
                                            existingSetMap = (existingSetMap != null ? existingSetMap : new Map<String,PermissionSetAssignment>());
                                            for (PermissionSetAssignment__c psa : PermissionSetAssignment__c.getAll().values()) {
                                                if (psa.Active__c && userMatchesCriteria(usr, psa)) {
                                                    // see if it already exists
                                                    PermissionSetAssignment permAsgn = existingSetMap.remove(psa.PermissionGroupName__c);
                                                    if (permAsgn == null) {
                                                        // create a new assignment if it doesn't exist
                                                        PermissionSetGroup grp = grpMap.get(psa.PermissionGroupName__c);
                                                        if (grp != null) {
                                                            permAsgn = new PermissionSetAssignment(AssigneeId=usr.Id, PermissionSetGroupId=grp.Id);
                                                            insertAsgns.add(permAsgn);
                                                        }
                                                    } // if (permAsgn == null
                                                }
                                            } // for (PermissionSetAssignment__c psa
                                            
                                            // anything remains in the map, delete it because they no longer meet the criteria
                                            if (!existingSetMap.isEmpty()) {
                                                deleteAsgns.addAll(existingSetMap.values());
                                            }
                                        } // checkPermSetUser
    
    public static Boolean userMatchesCriteria(User usr, PermissionSetAssignment__c psa) {
        Boolean match=true;
        // as long as there's criteria, it has to match all that's there.
        match = valueMatches((usr.ProfileId != null ? usr.profile.Name : null), psa.ProfileNames__c);
        System.debug('userMatchesCriteria match1='+match);
        match = (match && valueMatches(usr.Sales_Division__c, psa.SalesDivisions__c));
        System.debug('userMatchesCriteria match2='+match);
        match = (match && valueMatches(usr.Sales_Org__c, psa.SalesOrgs__c));
        System.debug('userMatchesCriteria match3='+match);
        match = (match && valueMatches(usr.Job_Name__c, psa.JobNames__c));
        System.debug('userMatchesCriteria match3='+match);
        
        return match;
    } // userMatchesCriteria
    
    public static boolean valueMatches(String value, String listOfValues) {
        if (String.isNotBlank(listOfValues)) {
            String[] valueList = listOfValues.split(',');
            if (String.isBlank(value) || !valueList.contains(value)) {
                return false;
            }
        }
        return true;
    } // valueMatches
    public static void getChecklist(Set<id> accountIds){
        Map<Id,PEO_Onboarding_Checklist__c> checklistMap = new Map<Id,PEO_Onboarding_Checklist__c>([SELECT id FROM PEO_Onboarding_Checklist__c 
                                                                                                    WHERE Prospect_Client__c in :accountIds AND Parent_PEO_Checklist__c=null]);
        if(!System.isFuture() && !Test.isRunningTest()){
            CommunityMethods.checkIfChecklistCompleteFuture(checklistMap.keySet(),'User First Login');
        }
        else{
            CommunityMethods.checkIfChecklistComplete(checklistMap.keySet(),'User First Login');
        }
        
    }
    
    // Start: Update By Rohith for Story SFDC-15955	
    
    public class AsyncExecutionExample implements Queueable, Database.AllowsCallouts {
        public List<Contact> userUpdate ;
        
        public AsyncExecutionExample (List<Contact> usertoUpdate){
               userUpdate = usertoUpdate ;
            
           
        }
        public void execute(QueueableContext context) {
            if(userUpdate != null){
                ReferralAccountMethods.SKIP_TRIGGERS = True;
                update userUpdate ;
                System.debug('AsyncExecutionExample after update users');
            }  
            
            
        }
        // Start: Update By Rohith for Story SFDC-15955	
        
    }
    
    public static void sendCPaStatusChange (Id updatedUserIds) {
    System.debug('sendCPaStatusChange Label.CPAEmailService='+Label.CPAEmailService);
      if (String.isNotBlank(Label.CPAEmailService)) {
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String[] toAddresses = new String[] {Label.CPAEmailService};
         mail.setToAddresses(toAddresses);
         mail.setSaveAsActivity(false);
      
         mail.setSubject('CPA Portal User Request');

        String body = updatedUserIds;

         System.debug('sendCPaStatusChange body='+body);
         mail.setPlainTextBody (body);
         Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         for (Messaging.SendEmailResult result : results) {
            System.debug('sendCPaStatusChange result='+result);
         }
      } // if (String.isNotBlank(Label
     // System.debug('sendCPaStatusChange emailSent='+emailSent);
   } // sendCPaStatusChange        

} // UserTriggerMethods