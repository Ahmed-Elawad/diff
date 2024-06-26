/* Add a User. 
        
  Enter an email
     if this is coming from the external site (no role id on the user) default to a Chatter free request.
        check for open request for this email address
        check for active users for the email?
     if this is internal
        search for paychex contact
        search for users by email and person id (if contact is found)
           if no contact is found, ask if this is for a temporary user (temp/contract)
           if active user is found (by person id) 
              if active record is chatter free, ask if upgrading to full license
              if active record is full license, cannot proceed.
           if only inactive users are found, give them the option to reactivate
           
  History
  -------
  06/20/2012 Dan Carmen      Created
  08/02/2012 Dan Carmen      Modify error messages.
  11/10/2012 Dan Carmen      Modified to be able to submit for standard user requests
  01/22/2013 Dan Carmen      Changes to allow Temporary Emps/Reactivations
  05/03/2013 Dan Carmen      Fix for not allow apexmessages when in batch mode.
  01/04/2016 Dan Carmen      Copy permission sets/group membership when adding a user.
  10/03/2016 Dan Carmen      Add more fields to copy from user to mirror.
  12/27/2017 Dan Carmen      Ability to create a new user if existing inactive one.
  10/22/2018 Dan Carmen      Ability to pass in permission set names when creating new group membership.
  02/04/2020 Dan Carmen      Change to without sharing to pass the test
  07/28/2020 Dan Carmen      Update to use UserHelper guest user check
  01/28/2022 Carrie Marciano Automation for reactivation to reactivate CPQ license
  03/30/2022 Carrie Marciano Changed Reactivation checkbox to a value in the Request Type picklist
  03/06/2023 Carrie Marciano Updated Chatter license code to only update role, not whole user record
  06/01/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu)
  01/05/2024 Dan Carmen      Changes to use users with New User Profile  
  04/26/2024 Dan Carmen      Slight cleanups

 */
public without sharing class AddUserController {
      
   public NewUserRequest__c newNur{get;set;}
   
   /** Is the running user a system administrator? */
   public Boolean isSystemAdmin{get;private set;}
   
   public static String SITE_USER='Add Chatter User Site Guest User';
   
   /** Is this a guest user? */
   public Boolean isGuestUser {
      get {return UserHelper.isRunningUserGuest();}
   }
   
   /** The User entering the form. */
   private User runningUser = null;
   
   /** Is this the initial query form (to create the request)? */   
   public Boolean isQueryForm{get;set;}
   
   /** Default constructor
    */
   public AddUserController() {
    isQueryForm = true;
    setRunningUser();

    setQueryNur();
    
   } // AddUserController
   
   /** Was the request complete on entry of the form? */
   public Boolean requestCompleteOnEntry{get;set;}
   
   /** If we're entering this from the New User Request object.
    */
   public AddUserController(ApexPages.StandardController stdController) {
    isQueryForm = false;
      setRunningUser();
      
      newNur = (NewUserRequest__c)stdController.getRecord();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'testCase='+testCase+' subject='+testCase.Subject));
      
      // the Id of the request should be passed in here. If not, cannot proceed
      Id nurId = System.currentPageReference().getParameters().get('id');
      approveOrReject = System.currentPageReference().getParameters().get('approveOrReject');
      
      setupRequest(nurId);

  } // AddUserController
   
   public void setupRequest(Id nurId) {
      // re-retrieve the object to get all of the fields
      newNur = getRequestById(nurId);
      
      requestCompleteOnEntry = newNur.Request_Complete__c;
      
      if (!newNur.Request_Complete__c) {
         if (newNur.Contact__c != null) {
            UserHelper uh = new UserHelper();
            foundContact = uh.getContactById(newNur.Contact__c);
            newNur.Contact__r = foundContact;
         }
         // create the new User record, but don't save yet.
         // bring to a page to verify basic information
   
         if ((newNur.UpgradeFromChatterFree__c || isReactivateRequest || newNur.CurrentIsNewUser__c) 
             && newNur.User__c != null) {
            activeUser = getUser('Id=\''+newNur.User__c+'\' ',!isReactivateRequest);
            
            useActiveUserForCreate(newNur,!isReactivateRequest);
            if (isReactivateRequest) {
               newNur.User__r.IsActive = true;
            }
         } else if (createUser(newNur)) {

         } // if (createUser
      } // if (!newNur.Request_Complete__c
   } // setupRequest
   
   /** Is this a request for reactivation? */
   public Boolean isReactivateRequest {
      get { return (newNur != null && newNur.Request_Type__c == 'Reactivate'); }
   } // isReactivateRequest
   
   public NewUserRequest__c getRequestById(Id nurId) {
      NewUserRequest__c nur = [Select Id, Name
                                     ,Approver_Notes__c
                                     ,Contact__c
                                     ,Contact__r.Name
                                     ,Cost_Center__c
                                     ,CurrentIsNewUser__c
                                     ,FirstName__c
                                     ,LastName__c
                                     ,Manager__c
                                     ,New_User_Email__c
                                     ,NewUserTheSameAsRequestor__c
                                     ,Notes__c
                                     ,ProcessNotes__c
                                     ,Request_Complete__c
                                     ,Requestor_Email__c
                                     ,Request_Type__c
                                     ,Sales_Org__c
                                     ,Status__c
                                     ,Temporary_Employee__c
                                     ,Transfer_From_User__c
                                     ,TRR__c
                                     ,UpgradeFromChatterFree__c
                                     ,User__c
                                     ,User__r.Name
                                     ,User__r.FirstName
                                     ,User__r.LastName
                                     ,User_to_Mirror__c
                                     ,Role__c
                                     ,Profile__c, Copy_public_Groups_and_Queues__c
                                 From NewUserRequest__c
                                Where Id = :nurId];
      return nur;
   } // getRequestById
   
   /** Set the running user information when entering the form.
    */
   public void setRunningUser() {
      canWeProceed = true;
      runningUser = UserHelper.getRunningUser();
      isSystemAdmin = UserHelper.isRunningUserSystemAdmin(); 
   } // setRunningUser
   
   /** Clear the variables that are used as part of the search.
    */
   public void clearSearchVariables() {
      foundContact = null;
      activeUser = null;
      inActiveUser = null;     
      promptForAdditionalInfo = null;
      canWeProceed = true;
      allUserMatches = null;
      displaySubmitButton = false;
      requestType = null;
      hasOpenRequest = null;
      
      // reset this after each iteration
      if (newNur != null) {
         newNur.Request_Type__c = (isGuestUser ? CHATTER_PROFILE : null);
         newNur.Contact__c = null;
         newNur.Temporary_Employee__c = false;
      }
   } // clearSearchVariables
   
   /** Setup the query object. */
   public void setQueryNur() {
    clearSearchVariables();
    isQueryForm = true;
      newNur = new NewUserRequest__c();
      newNur.Status__c = 'Pending';
      newNur.Request_Complete__c = false;
      newNur.NewUserTheSameAsRequestor__c = isGuestUser;
      // used for the user to select the correct sales org for the user they want to create
      newNur.User__r = new User(Sales_Org__c = (runningUser != null ? runningUser.Sales_Org__c : null));
      
      newNur.Request_Type__c = (isGuestUser ? CHATTER_PROFILE : null);
      
      if (!isGuestUser && runningUser != null) {
         newNur.Requestor_Email__c = runningUser.Email;
      }
   } // setQueryNur
   
   /** The contact record found as a result of the search. */
   public Contact foundContact{get;set;}
   
   /** if a User record is found with the same person id. */
   public User activeUser{get;set;}

   public User inActiveUser{get;set;}
   
   /** Used for querying data. */
   public User newUser{get;set;}
   
   /** Was an active User record found matching the email passed in? */ 
   public Boolean matchingUserFound{
      get {return activeUser != null;}
   } // matchingUserFound
   
   /** Create a new User record.
    */
   public PageReference addNewUser() {
    if (verifyRequiredFields(newNur) && createUser(newNur)) {
         if (saveNewUser(newNur)) {
            // clear out the search
            setQueryNur();
         }
    }
    setQueryNur();
      return null;
   } // addNewUser
   
   /** Search for an employee in the Paychex Contact records.
    */
   public PageReference searchForEmployee() {
    clearSearchVariables();
    newNur.Approver_Notes__c = null;
      // make sure there's not an open request
      canWeProceed = !searchForOpenRequest(newNur);
      System.debug('searchForEmployee canWeProceed='+canWeProceed);

      if (canWeProceed) {
        findContact(newNur);
		System.debug('searchForEmployee after findContact');
          
        findUserMatches(newNur.New_User_Email__c,(foundContact != null ? foundContact.HR_Person_Id__c : null));
		System.debug('searchForEmployee after findUserMatches');
          
        // if the site user and an active user was not found, save the request
        Boolean userFound = (activeUser != null); //findActiveUser(newNur);
   		System.debug('searchForEmployee *active* userFound: '+userFound);       
          
        // can we proceed with the user request?
        canWeProceed = (!userFound || (activeUserIsChatterFree && !isChatterFreeRequest) || activeUserIsNewUser);
        System.debug('searchForEmployee canWeProceed: '+canWeProceed); 
      } // if (findContact
      
      return null;
   } // searchForEmployee
   
   /** Search for a non-termed employee contact record.
    */
   public Boolean findContact(NewUserRequest__c nur) {
      foundContact = null;
      newNur.Contact__c = null;
      newNur.Contact__r = null;
      
      NewUserExtension nue = new NewUserExtension();
      if (newNur.Contact__c != null) {
         foundContact = new UserHelper().getContactById(newNur.Contact__c);
         System.debug('findContact newNur.Contact__c != null foundContact='+foundContact); 
      }
      statusMsg = '   Trying '+nur.New_User_Email__c+'... ';
      // see if a contact record exists
      nue.searchContacts(nur.New_User_Email__c,null,null);
      // if a contact is found (should only be at most one record) see if there's an active User record
      if (nue.foundContacts == null || nue.foundContacts.isEmpty()) {
        if (DISPLAY_VF_MSG) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'A Paychex Employee contact record was not found with the Email Address '+nur.New_User_Email__c+'!'));
        } else {
            logError(nur,'No Paychex Employee was found with the Email Address '+nur.New_User_Email__c+'!');
        }
      } else {
         // pull out the first contact - we'll assume there's only one since email should be unique for non-termed employees 
         foundContact = nue.foundContacts.get(0);
         newNur.Contact__c = foundContact.Id;
         newNur.Contact__r = foundContact;
         newNur.Cost_Center__c = foundContact.Paychex_Cost_Center__c;
         System.debug('findContact newNur.Contact__c: '+newNur.Contact__c+' newNur.Contact__r: '+newNur.Contact__r);  
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'foundContact='+foundContact));

      return (newNur.Contact__c != null);
   } // findContact

   /** Are there matches to the email address on the User record? */
   public Boolean hasUserMatches{
      get {return (allUserMatches != null && !allUserMatches.isEmpty()); }
   } // hasUserMatches
   
   public String userMatchTitle{get;private set;}
   
   public User[] allUserMatches{get;set;}
   public cafsl__Oracle_User__c[] allUserMatchesWithCPQUser{get;set;}
   public Manage_Package_License__c[] newLicenseRequests = new Manage_Package_License__c[]{};
       
   /** Find all of the User records that match the passed in email address, both active and inactive.
    */
   public Boolean findUserMatches(String emailAddr, String personId) {
    // have to at least have the email address to proceed
    if (emailAddr != null) {
        userMatchTitle='Email '+emailAddr;
         String whereClause = 'where Email = \''+emailAddr+'\' ';
         if (personId != null) {
            userMatchTitle += ' or Person Id '+personId;
            whereClause += ' or HR_Person_Id__c=\''+personId+'\' ';
         }
         // get the active records before the inactive
         whereClause += 'order by IsActive desc, LastLoginDate desc NULLS Last limit 20 ';
         UserHelper uh = new UserHelper();
         allUserMatches = uh.getUsers(whereClause);
        
         // find the first active user by the person id.
         if (allUserMatches != null && !allUserMatches.isEmpty()) {
            System.debug('findUserMatches allUserMatches is not null');  
            User firstEmailMatch = null;
            User firstInactiveMatch = null;
         
            for (User u : allUserMatches) {
                System.debug('findUserMatches u.Email: '+u.Email+' u.HR_Person_Id__c: '+u.HR_Person_Id__c+' personId: '+personId);
                // save the first record that matches the email. Use that if we can't find a match by person id
                if (firstEmailMatch == null && u.Email == emailAddr) {
                   firstEmailMatch = u;
                   System.debug('findUserMatches firstEmailMatch: '+firstEmailMatch);   
                }
               if (u.IsActive && u.HR_Person_Id__c == personId) {
                  activeUser = u;
                  System.debug('findUserMatches activeUser: '+activeUser);  
                  break;
               } else if (!u.IsActive && u.HR_Person_Id__c == personId) {
                  firstInactiveMatch = u;
                  System.debug('findUserMatches firstInactiveMatch: '+firstInactiveMatch); 
                  break; 
               }
            } // for (User u
            // if an active user was not found by person id use the first inactive match. If no inactive first by email.
            if (activeUser == null && (firstEmailMatch != null && firstEmailMatch.isActive)) {
               activeUser = firstEmailMatch;
               System.debug('findUserMatches no active user use firstEmailMatch that is active activeUser: '+activeUser);  
            }
            // set the inactive user if an active user was not found.
            if (activeUser == null) {
               inActiveUser = (firstInactiveMatch != null ? firstInactiveMatch : ((firstEmailMatch != null && !firstEmailMatch.isActive) ? firstEmailMatch : null));
               System.debug('findUserMatches no active user no active firstEmailMatch use inactive firstEmailMatch inActiveUser: '+inActiveUser); 
            } 
         } // if (allUserMatches != null
    } // if (emailAddr != null
    return (hasUserMatches);
   } // findUserMatches
   
   // Does the activeUser have a Chatter Free profile?
   public Boolean activeUserIsChatterFree{
      get {return (activeUser != null && activeUser.Profile.Name == CHATTER_PROFILE); }
   } // activeUserIsChatterFree
    
   // is the active user record newly setup (so it can be reused)?
   public Boolean activeUserIsNewUser {
      get {return (activeUser != null && (activeUser.Profile.Name == Utilities.NEW_USER_PROFILE
                                          || activeUser.UserRole.Name == Utilities.NEW_USER_ROLE)); }
   } // activeUserIsNewUser
   
   public Boolean displaySubmitButton{get;private set;}
   public Boolean getMirrorUserInfo{
      get {
         return (requestType != null && (requestType.endsWith('_Standard')  || requestType.endsWith('_Read_Only')));
      }
   }
   
   public String requestType{get;set;}
   
   /** Set the type of request being set. 
    */
   public PageReference setRequestType() {
      promptForAdditionalInfo = false;
      displaySubmitButton = false;
      newNur.Temporary_Employee__c = (requestType != null && requestType.contains('_Temp_'));
    if (requestType != null && requestType != 'N' && requestType.startsWith('Y')) {
         //cannotProceed = false;
         canWeProceed = true;
         displaySubmitButton = true;
         if (activeUser != null) {
            newNur.Cost_Center__c = activeUser.Cost_Center__c;
            newNur.User__r = activeUser;
            newNur.User__c = activeUser.Id;
         }
         if (foundContact != null && String.IsNotBlank(foundContact.Paychex_Cost_Center__c)) {
            newNur.Cost_Center__c = foundContact.Paychex_Cost_Center__c;
         }
        // check if it's for a temporary employee
         if (requestType.endsWith('_Chatter')) {
            newNur.Request_Type__c = CHATTER_PROFILE;
         } else if (requestType.endsWith('_Standard') || requestType.endsWith('_Read_Only')) {
            newNur.Request_Type__c = (requestType.endsWith('_Standard') ? 'Standard User' : 'Read Only');
            // if the current active user record is chatter free it will be an upgrade
            newNur.UpgradeFromChatterFree__c = activeUserIsChatterFree;
            newNur.CurrentIsNewUser__c = activeUserIsNewUser;
            promptForAdditionalInfo = true; 
         } else if (requestType.endsWith('_Reactivate')) {
            newNur.Request_Type__c = 'Reactivate';
            newNur.Cost_Center__c = inActiveUser.Cost_Center__c;
            newNur.User__r = inActiveUser;
            newNur.User__c = inActiveUser.Id;
            newNur.Reactivate_CPQ__c = inActiveUser.Oracle_CPQ__c;
            promptForAdditionalInfo = true; 
         }

    } else {
       //cannotProceed = true;
       canWeProceed = false;
    } // if (requestType != null
    
      return null;
   } // setRequestType
      
   public Boolean promptForAdditionalInfo{get;set;}
   
   //public Boolean cannotProceed{get;set;}
   public Boolean canWeProceed{get;set;}
   
   /** Create a new User record. */
   public Boolean createUser(NewUserRequest__c nur) {
    System.debug('createUser email='+nur.New_User_Email__c+' contact='+nur.Contact__c);
    //activeUser = null;

      UserHelper uh = new UserHelper();

    // if the request is already saved and there's a contact id use that
    if (nur.Id != null && nur.Contact__c != null) {
        // retrieve it if not already retrieved
       if (foundContact == null || (foundContact != null && foundContact.Id != nur.Contact__c)) {
        foundContact = uh.getContactById(nur.Contact__c);
       }
    } // if (nur.Id != null
    
    
    Boolean okay = true;
    if (foundContact == null && !nur.Temporary_Employee__c) {
         okay = findContact(nur);
    }

    
      // if no active user record found, create the user.
      if (okay && activeUser == null) {
        if (!nur.Temporary_Employee__c) {
            NewUserExtension nue = new NewUserExtension();
            nue.newUser.Email = nur.New_User_Email__c;
            nue.createUserFromContact(nue.newUser,foundContact);
            nur.User__r = nue.newUser;
        } else {
            if (nur.User__r == null) {
               nur.User__r = (User)User.getSObjectType().newSObject(null,true);
            }
            nur.User__r.Email = nur.New_User_Email__c;
            
            nur.User__r.Alias=uh.getUserId(nur.User__r.Email,5);
            nur.User__r.CommunityNickname=uh.getUniqueNicknameByEmail(nur.User__r.Email);
            nur.User__r.FirstName = nur.FirstName__c;
            nur.User__r.LastName = nur.LastName__c;
            nur.User__r.Username = new NewUserExtension().getUsername(nur.User__r.Email);
            nur.User__r.ManagerId = nur.Manager__c;
            nur.User__r.Non_Paychex_Employee__c = true;
            nur.User__r.Non_Paychex_Employee_User_Type__c = 'Temporary Employee';
        }

         User userToMirror = setProfileAndRoleInfo(nur);
         
         // fill in other information-0
         // try to find an existing User with the same zip code. If not, default to using sfdc_dm
         User usr = findSimilarUser(nur.User__r.PostalCode);
         if (userToMirror != null) {
            System.debug('using userToMirror');
            setLocaleInfo(nur.User__r, userToMirror);
         } else if (usr != null) {
            System.debug('using similar user');
            setLocaleInfo(nur.User__r, usr);
         } else {
            // get the SFDC Data user - should always succeed
            User sfdcData = getUser('Name=\'SFDC Data\' ',true);
            System.debug('Found sfdcData='+(sfdcData == null ? 'false' : 'true'));
            if (sfdcData != null) {
                System.debug('Using SFDC Data locale info');
               setLocaleInfo(nur.User__r, sfdcData);
            } else {
               setDefaultLocale(nur.User__r);
            }
         }
         if (userToMirror == null || String.isBlank(nur.User__r.Cost_Center__c)) {
            // if not null, should pull this from the user to mirror
            nur.User__r.Cost_Center__c = nur.Cost_Center__c;
         }
         nur.User__r.CompanyName = 'Paychex';
         nur.User__r.SFDC_User_Start_Date__c = Date.today();
         nur.User__r.IsActive=true;
         nur.User__r.Creation_Type__c='AddUserC';
      } // if (activeUser != null
      return okay;
   } // createUser
   
   /** Update profile and role info on the User record */
   public User setProfileAndRoleInfo(NewUserRequest__c nur) {
      Boolean okay = true;
      Id profId = null;
      Id roleId = null;
      User userToMirror = null;
      if (isChatterFreeRequest) {
         Profile prof = UserHelper.getProfile(CHATTER_PROFILE,true);
         if (prof != null) {
            profId = prof.Id;
         } else {
            okay = false;
         }
      } else if (nur.User_to_Mirror__c != null) {
         UserHelper uh = new UserHelper();
         userToMirror = uh.getUserById(nur.User_to_Mirror__c);
         nur.User__r.CPQ_Mandate_Eligibility__c = userToMirror.CPQ_Mandate_Eligibility__c;
         roleId = userToMirror.UserRoleId;
         if (isReadOnlyRequest) {
            Profile prof = UserHelper.getProfile(READ_ONLY_PROFILE,true);
            profId = (prof != null ? prof.Id : null);
         } else {
            profId = userToMirror.ProfileId;
         }
      } else if (nur.User_to_Mirror__c == null) {
          List<UserRole> urList = ManageUserHelper.getUserRole(nur.Role__c);
          List<Profile> pList = ManageUserHelper.getProfile(nur.Profile__c);
          
          roleId = (!urList.isEmpty() ? urList[0].id : null);
          profId = (!pList.isEmpty() ? pList[0].id : null);    
          
      }// if
       	
      // handle for non-chatter free profiles
      nur.User__r.Sales_Org__c = (isChatterFreeRequest ? CHATTER_PROFILE : nur.Sales_Org__c);
      nur.User__r.License_Type__c = nur.Request_Type__c;
      nur.User__r.ProfileId = profId;
      nur.User__r.UserRoleId = roleId;
       
      if (nur.Cost_Center__c != null) {
         nur.User__r.Cost_Center__c = nur.Cost_Center__c;
      }
      // 
      if (userToMirror != null) {
         setLocaleInfo(nur.User__r, userToMirror);
         new ManageUserController().copyFromMirrorUser(nur.User__r, userToMirror);
         // add manage zip org units field
      }
      NewUserExtension nue = new NewUserExtension();
      nue.checkOrganization(nur.User__r);
      return userToMirror;
   } // setProfileAndRoleInfo
   
   public void checkOrganization() {
      NewUserExtension nue = new NewUserExtension();
      nue.checkOrganization(newNur.User__r);
   } // checkOrganization
   
   /** Set the default locale information on a User. */
   public void setDefaultLocale(User usr) {
      usr.LocaleSidKey='en_US';
      usr.TimeZoneSidKey='America/New_York';
      usr.EmailEncodingKey='ISO-8859-1';
      usr.LanguageLocaleKey='en_US';
   } // setDefaultLocale
   
   /** Copy the locale information from another user. */
   public void setLocaleInfo(User usr, User copyUser ) {
      usr.LocaleSidKey=copyUser.LocaleSidKey;
      usr.TimeZoneSidKey=copyUser.TimeZoneSidKey;
      usr.EmailEncodingKey=copyUser.EmailEncodingKey;
      usr.LanguageLocaleKey=copyUser.LanguageLocaleKey;
   } // setLocaleInfo
   
    public static Boolean DISPLAY_VF_MSG=(!System.isFuture() && !System.isBatch() && !System.isQueueable());

   /** Save the new User record.
    */
   public Boolean saveNewUser(NewUserRequest__c nur) {
    Boolean okay = true;
      if (nur.User__r != null) {
        Boolean isInsert = (nur.User__r.Id == null);
          
        System.debug('saveNewUser attempting to save '+nur.User__r.Username);
         try {
            if (isInsert) {
               insert nur.User__r;

               /// Add User to Public Groups and Queues if chekecd - Sush
               if (nur.Copy_public_Groups_and_Queues__c == true && nur.User_to_Mirror__c != null ) {

                  List<GroupMember> listGroupMember =new List<GroupMember>(); //
                  for (GroupMember groupRec : [SELECT Id, GroupId FROM GroupMember where UserOrGroupId = : nur.User_to_Mirror__c and  Group.type in ('Regular' ,'Queue')]) {
                   GroupMember groupMem= new GroupMember(); 
                   groupMem.GroupId = groupRec.GroupId;
                   groupMem.UserOrGroupId = nur.User__r.id;
                    listGroupMember.add(groupMem);
                  }     
                  if (listGroupMember.size() > 0 ) {
                     insert listGroupMember;
                  }             
               } //Sush
            } else {
               // we're updating from a Chatter free - clear out role id
               // can't save a record with a role id while a chatter free user.
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'Before update 1'));
               Id roleId = nur.User__r.UserRoleId;
               nur.User__r.UserRoleId = null;
               nur.User__r.UserRole = null;
               update nur.User__r;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'After update 1'));
               
               // reselect the record
               UserHelper uh = new UserHelper();
               // only update with role id 
               User updateUser = new User(Id=nur.User__r.Id, UserRoleId = roleId);
               update updateUser;
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'After update 2'));
            }
            nbrCreated++;
            
            // for right now we're going to assume that all users that have a Sales_Org__c field that matches up to the 
            // SalesOrg__c custom setting with HasOrgStructure__c = true will leverage Label.AddUser_Sales_PermissionSets
            String[] permissionSetNames = null;
            if (String.isNotBlank(nur.User__r.Sales_Org__c)) {
               SalesOrg__c salesOrg = SalesOrg__c.getInstance(nur.User__r.Sales_Org__c);
               if (salesOrg != null && salesOrg.HasOrgStructure__c && Label.AddUser_Sales_PermissionSets != 'None') {
                  permissionSetNames = Label.AddUser_Sales_PermissionSets.split(',');
               }
            }
            
            User userToMirror = null;
            if (nur.User_to_Mirror__c != null) {
               userToMirror = new UserHelper().getUserById(nur.User_to_Mirror__c);
            }
            
            if (userToMirror != null || permissionSetNames != null) {
               ManageUserController.checkGrpMembership(null, nur.User__r, userToMirror, permissionSetNames);
            }
            
            String msg = 'The '+nur.Request_Type__c+' User for '+nur.New_User_Email__c+' was successfully '+(isInsert ? 'created' : 'updated')+'!';
            if (DISPLAY_VF_MSG) {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,msg));
            }
            statusMsg += msg;
            okay = true;
            nur.Status__c = 'Complete';
            nur.User__c = nur.User__r.Id;
         } catch (Exception e) {
            okay = logError(nur,'The new user could not be created! Error='+e);
         }
      } // nur.User__r != null && nur.User__c == null
      
      //check to see if has CPQ Users
      UserHelper uh = new UserHelper(); 
      String whereClause = 'where cafsl__User__c = \''+nur.User__c+'\' '; 
      System.debug('saveNewUser whereClause: '+whereClause); 
      allUserMatchesWithCPQUser = uh.getCPQUsers(whereClause);
       system.debug('saveNewUser allUserMatchesWithCPQUser: '+allUserMatchesWithCPQUser);
      if (allUserMatchesWithCPQUser != null && !allUserMatchesWithCPQUser.isEmpty()) {
            Installed_Package__mdt cpqPackage = [select DeveloperName,Name_Prefix__c,OwnerId__c From Installed_Package__mdt where Name_Prefix__c = 'cafsl' ];
            for(cafsl__Oracle_User__c cpqUser : allUserMatchesWithCPQUser){
                Manage_Package_License__c addLicense = new Manage_Package_License__c();                    
                addLicense.User_Name__c = nur.User__c;
                addLicense.Request_Status__c = 'Submitted for Approval';
                addLicense.Requestor__c = runningUser.Id;
                addLicense.Package_Name__c = cpqPackage.DeveloperName;
                addLicense.Requested_Date__c = System.NOW();
                addLicense.Effective_Date__c = System.NOW();
                addLicense.OwnerId = cpqPackage.OwnerId__c;
                addLicense.Request_Type__c = 'Reactivate';
                addLicense.Oracle_User__c = cpqUser.Id;
                newLicenseRequests.add(addLicense);
            }
	        system.debug('AddUserController saveNewUser newLicenseRequests '+newLicenseRequests );	
            String msg = '\n'+ 'CPQ User(s) found, Reactivation Request will be submitted'; 
            statusMsg += msg;
      } 
      
      nur.Request_Complete__c = true;
      system.debug('AddUserController saveNewUser statusMsg '+statusMsg );
      StringHelper.addToProcessNotes(nur,statusMsg);
      nur.Approver_Notes__c = (statusMsg.length() < 255 ? statusMsg : statusMsg.substring(0,255)); 
      return okay;
   } // saveNewUser
   
   /** Log an error that occurs.
    */
   public Boolean logError(NewUserRequest__c nur, String msg) {
      nbrFailed++;
      StringHelper.addToProcessNotes(nur,msg);
      nur.Approver_Notes__c = (msg.length() < 255 ? msg : msg.substring(0,255));
      nur.Status__c = 'Failed';
      statusMsg += msg;
      if (DISPLAY_VF_MSG) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
      }
      return false;
   } // logError
   
   public Integer nbrCreated = 0;
   public Integer nbrFailed = 0;
   public String statusMsg = '';
   
   /** Try to find a User similar to the one being created (based on the zip code) so we can leverage the 
       demographic information.
    */
   public User findSimilarUser(String zipCode) {
    if (zipCode != null) {
        return getUser('PostalCode=\''+zipCode+'\' limit 1 ',true);
    } // if (zipCode != null

      return null;
   } // findSimilarUser
   
   /** Retrieve a user record based on the passed in where clause snippet.
    */
   public User getUser(String whereClausePortion, Boolean isActive) {
    User usr = null;
    if (whereClausePortion != null) {
         UserHelper uh = new UserHelper();
         String whereClause = ' where IsActive='+(isActive ? 'true' : 'false')+' and '+whereClausePortion;
         User[] users = uh.getUsers(whereClause);
         if (users != null && !users.isEmpty()) {
            // use the first one
            usr = users.get(0);
         }
    } // if (whereClausePortion)
      return usr;
   } // getSfdcDataUser
   
   // The logic gets a little in depth so putting here for readability. 
   public Boolean showChatterFreeOption{
      get {
         Boolean showOption = (!matchingUserFound 
                                //&& (cannotProceed != null && !cannotProceed) 
                                && (canWeProceed != null && canWeProceed) 
                                && ((foundContact != null) || (foundContact == null && newNur.Temporary_Employee__c)));
         return showOption;
      }
   } // showChatterFreeOption
   
   /** Is this a request for a chatter free user? */
   public Boolean isChatterFreeRequest{
      get {
        return (newNur != null && newNur.Request_Type__c == CHATTER_PROFILE);
      }
   } // isChatterFreeRequest
   
   public Boolean isReadOnlyRequest{
      get {
         return (newNur != null && newNur.Request_Type__c == 'Read Only');
      }
   } // isReadOnlyRequest
   
   public static String CHATTER_PROFILE='Chatter Free User';
      
   /** The name of the read only profile. */
   public static String READ_ONLY_PROFILE='Read Only - Contract';

   /** Use the found User information for creating a new record.
    */
   public Boolean useActiveUserForCreate(NewUserRequest__c nur, Boolean setProfAndRole) {
      Boolean okay = true;
      // use the existing user record and update
      newNur.User__c = activeUser.id;
      newNur.User__r = activeUser;

      if (setProfAndRole) {
         setProfileAndRoleInfo(newNur);
      }
      isQueryForm = false;
      return okay;
   } // useActiveUserForCreate
   
   public PageReference saveRequest() {
      saveRequest(newNur);
      setQueryNur();
      return null;
   } // saveRequest
   
   /** Save the New User Request.
    */
   public Boolean saveRequest(NewUserRequest__c nur) {
      // clear out the user lookup on save - doesn't like to have both __r and __c populated
      User tempUser = nur.User__r;
      nur.User__r = null;
      System.debug('saveRequest before upsert nur='+nur.User__r);
      upsert nur;
      System.debug('saveRequest after upsert nur='+nur.User__r);
      if (DISPLAY_VF_MSG) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'The '+nur.Request_Type__c+' license request for '+nur.New_User_Email__c+' was submitted!'));
      }
      // put back into lookup
      nur.User__r = tempUser;
      System.debug('saveRequest after set tempUser nur='+nur.User__r); 
      if(!newLicenseRequests.isEmpty()){
	     insert newLicenseRequests; 
	     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Reactivation Request for Oracle_CPQ has been submitted'));
	  } 
      return true;
   } // saveRequest
   
   /** Save the request record and proceed directly to the Create User form.
    */
   public PageReference submitRequestCreateUser() {
    return submitRequest(true);
   } // submitRequestCreateUser

   /** Save the request and stay on the current form.
    */
   public PageReference submitRequest() {
    // if submitting as the guest user, all it will do is save the request. Make sure there's not
    // already an open request first.
    if (isGuestUser && searchForOpenRequest(newNur)) {
       return null;
    }
      return submitRequest(false);
   } // submitRequest

   /** Verify all of the required fields are filled in.
    */
   public Boolean verifyRequiredFields(NewUserRequest__c nur) {
       Boolean allOkay = true;  
       List<UserRole> urList = ManageUserHelper.getUserRole(nur.Role__c);
       List<Profile> pList = ManageUserHelper.getProfile(nur.Profile__c); 
       
       if (nur.NewUserTheSameAsRequestor__c) {
           nur.New_User_Email__c = nur.Requestor_Email__c;
       }
       if (nur.New_User_Email__c == null) {
           nur.New_User_Email__c.addError('The new user Paychex Email Address must be provided!');
           allOkay = false;
       }             
 
       if (nur.Temporary_Employee__c) {
           // verify first name, last name, manager filled out.
           if (StringHelper.fieldIsBlank(nur.FirstName__c)) {
               nur.FirstName__c.addError('First Name is required.');
               allOkay = false;
           }
           if (StringHelper.fieldIsBlank(nur.LastName__c)) {
               nur.LastName__c.addError('Last Name is required.');
               allOkay = false;
           }
           if (nur.Request_Type__c == 'CHATTER_PROFILE'){
               if(urList.IsEmpty() && nur.Role__c != null){
                   nur.Role__c.addError('The Role you entered is not correct.');
                   allOkay = false;  
               }       
               if(pList.IsEmpty() && nur.Profile__c != null){
                   nur.Profile__c.addError('The Profile you entered is not correct.');
                   allOkay = false;  
               }	       
               if (nur.User_to_Mirror__c == null && (nur.Profile__c == null || nur.Role__c == null)) {
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You must fill out either the User to Mirror or (Role and Profile)'));
                   allOkay = false;
               }
               if (nur.User_to_Mirror__c != null && (nur.Profile__c != null || nur.Role__c != null)) {
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You must fill out either the User to Mirror or (Role and Profile), not both'));
                   allOkay = false;
               }    
           } // nur.Request_Type__c == 'CHATTER_PROFILE'           
       } // if (newNur.Temporary_Employee__c)
             
    return allOkay;
   } // verifyRequiredFields
   
   /** Save a New User Request object. 
    */
   public PageReference submitRequest(Boolean createUser) {
    Boolean allOkay = verifyRequiredFields(newNur);

      newNur.Sales_Org__c = newNur.User__r.Sales_Org__c;
      if (allOkay && !matchingUserFound && !isChatterFreeRequest) {
         // we passed validation for the additional information - go to the form to finish the new user.
         System.debug('submitRequest allOkay && !matchingUserFound && !isChatterFreeRequest');
         saveRequest(newNur);
         if (createUser && createUser(newNur)) {
            return gotoUserPage();
            /*
            isQueryForm = false;
            approveOrReject = 'approve';
            PageReference retPr = Page.NewUserRequestManage;
            retPr.setRedirect(true);             
            
            return retPr;
            */
         }
      } else if (allOkay && matchingUserFound && newNur.UpgradeFromChatterFree__c) {
        // use the existing user record and update
        System.debug('submitRequest allOkay && matchingUserFound && newNur.UpgradeFromChatterFree__c');
        newNur.User__c = activeUser.id;
      
         if (createUser) {
            saveRequest(newNur);

            useActiveUserForCreate(newNur, true);
           return gotoUserPage();
         } // if (createUser
      } // if (!userFound
      
      if (allOkay) {
         // save the request
         System.debug('submitRequest allOkay only='+allOkay+' createUser: '+createUser);
         saveRequest(newNur);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your '+newNur.Request_Type__c+' license request for '+newNur.New_User_Email__c+' has been submitted! You will receive an email when it has been processed.'));
         setQueryNur();
      } // if (allOkay

      return null;
   } // submitRequest
   
   public PageReference gotoUserPage() {
      isQueryForm = false;
      approveOrReject = 'approve';
      PageReference retPr = Page.NewUserRequestManage;
      retPr.getParameters().put('Id',newNur.Id);
      // default to approved
      retPr.getParameters().put('approveOrReject','approve');
      retPr.setRedirect(true);             
            
      return retPr;
   } // gotoUserPage
   
   public Boolean hasOpenRequest{get;private set;}
   
   /** Check if there's an open request.
    */
   public Boolean searchForOpenRequest(NewUserRequest__c nur) {
      // verify an open request for that email doesn't already exist
      Integer cnt = [Select count() 
                       from NewUserRequest__c 
                      Where Request_Complete__c=false 
                        and New_User_Email__c = :nur.New_User_Email__c limit 1];
      hasOpenRequest = (cnt > 0);
      if (hasOpenRequest) {
         nur.New_User_Email__c.addError('An open request for '+nur.New_User_Email__c+' already exists!');
      }
      return hasOpenRequest;
   } // searchForOpenRequest
   
   public String approveOrReject{get;set;}
   
   public PageReference setApproveOrReject() {
      return null;
   } // setApproveOrReject
   
   public PageReference saveRejection() {
      // verify that notes have been filled in
      if (newNur.Approver_Notes__c == null || newNur.Approver_Notes__c.length() == 0) {
         newNur.Approver_Notes__c.addError('You must enter in a reason for the Reject!');
         return null;
      }
      newNur.Status__c = 'Rejected';
      newNur.Request_Complete__c = true;
      saveRequest(newNur);
      
      PageReference retPr = new PageReference('/'+newNur.Id);
      retPr.setRedirect(true);             
      return retPr;
   } // saveRejection

   /** Perform the save. 
    */   
   public PageReference saveUser() {
    
    Boolean okay = saveNewUser(newNur);
      return null;
   } // doSaveUser
   
   public PageReference gotoUser() {
      saveRequest(newNur);
      PageReference retPr = new PageReference('/'+newNur.User__c);
      retPr.setRedirect(true);             
      return retPr;
   } // gotoUser
   
   public PageReference gotoRequest() {
      saveRequest(newNur);
      PageReference retPr = new PageReference('/'+newNur.Id);
      retPr.setRedirect(true);             
      return retPr;
   } // gotoRequest
   
} // class AddUserController