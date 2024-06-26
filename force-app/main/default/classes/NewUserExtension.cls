/* 
 * The methods used for stepping someone through creating a new user.
 *
 * History
 * -------
 * 10/20/2009 Dan Carmen   Created
 * 09/16/2010 Dan Carmen   Split some functionality to the UserHelper class.
   11/16/2011 Dan Carmen   Logic to handle apostrophes in the names.
   11/22/2011 Dan Carmen   Set mobile user to true for Sales people.
   06/20/2012 Dan Carmen   Modified to reuse some components.
   06/29/2012 Dan Carmen   Added check to only search active contacts.
   11/27/2012 Dan Carmen   Modified checkOrganization method.
   01/22/2013 Dan Carmen   Changes to allow Temporary Emps/Reactivations
   05/07/2020 Dan Carmen        Remove AccountHelper.getRecordType
   01/03/2024 Dan Carmen        Remove User License references

*/
public without sharing class NewUserExtension {

   /** instantiation of the UserHelper class. */
   private UserHelper uh = new UserHelper();
   
   /** If there were search results returned. */
   public Boolean hasSearchResults {get; private set;} 

   /** To enter additional user info on the form. */
   public Boolean enterAddInfo {get; private set;} 

   public Boolean showErrorBlock {
      get{ 
   	   ApexPages.Message[] messages = ApexPages.getMessages();
   	   for (ApexPages.Message msg : messages) {
   	      if (msg.getSeverity() == ApexPages.severity.ERROR) {
               return true;
   	      }
   	   } // for (ApexPages
   	   return false;
      } // get
   } // showErrorBlock
      
   /** Show the block that contains the user info.
    */
   public Boolean showNewUserInfoBlock {
   	// always allow to continue if system admin
   	get{ return (!enterAddInfo
   		          && (isSystemAdmin || !ApexPages.hasMessages())
                   );
   	    }}
   
   /** Does the current user have the System Administrator profile?
    */
   public Boolean isSystemAdmin {
      get{ return (curUser.Profile.Name == 'System Administrator'); }
   }
   
   /** No argument constructor
    */
   public NewUserExtension() {
      clearSearchResults();
   	  newUser = new User();
   } // NewUserExtension
   
   /** Default constructor.
    */
   public NewUserExtension(ApexPages.StandardController stdController) {
      clearSearchResults();
      newUser = (User)stdController.getRecord();
      curUser = uh.getUserById(UserInfo.getUserId());

      newUser.Sales_Org__c = curUser.Sales_Org__c;

      hasSearchResults = false;
      enterAddInfo = false;
   } // NewUserController
   
   /** The current user record. */
   public User curUser {get; private set;}
   
   /** The new user record. */
   public User newUser {get; set;}

   /** Were any results returned from the User record search?
    */
   public Boolean getHasUserSearchResults() {
   	  return (getFoundUsers() != null && getFoundUsers().size() > 0);
   } // getHasSearchUserResults

   /** Were any results returned from the Contact record search?
    */
   public Boolean getHasContactSearchResults() {
   	  return (getFoundContacts() != null && getFoundContacts().size() > 0);
   } // getHasContactSearchResults

   public List<User> foundUsers = null;
   
   public List<Contact> foundContacts = null;
   
   /** Get the users found in the search.
    */ 
   public List<User> getFoundUsers() {
   	  return foundUsers;
   } // getFoundUsers
   
   /** Get the Contacts found in the search.
    */
   public List<Contact> getFoundContacts() {
   	  return foundContacts;
   } // getFoundContacts
   
   /** Clear all of the results of the search.
    */
   public void clearSearchResults() {
   	  foundUsers = null;
   	  foundContacts = null;
   	  hasSearchResults = false;
   } // clearSearchResults
   
   public void checkOrganization() {
      checkOrganization(newUser);
   } 
   /** This is called when the cost center field changes.
    */
   public void checkOrganization(User checkUser) {
   	  // clear the district field so it will reset when cost center changes
   	  checkUser.District__c = null;
   	  User[] users = new User[]{checkUser};
   	  UpdateOrgInfo.SetUserInfo(users);
   } // checkOrganization
   
   /** Perform a search with only the email address.
    */
   public PageReference quickSearch() {
   	  clearSearchResults();
   	  if (newUser.Email != null) {
   	     // search User record by email address
   	     searchUsers();
   	     // search Contact records by email address
   	     searchContacts(newUser.Email,newUser.FirstName,newUser.LastName);
   	  } // if (newUser.Email
   	  
   	  hasSearchResults = (getHasUserSearchResults() || getHasContactSearchResults());
   	  return null;
   } // quickSearch
   
   /** Determine if there are any licenses available for the sales org defined in the user's profile.
    */
   public PageReference performSearch() {
   	  // see if the non-Paychex box is checked
   	  // if so, do not perform searches
   	  if (newUser.Non_Paychex_Employee__c == true) {
   	  	 newUser.Non_Paychex_Employee_User_Type__c = 'Temporary Employee';
         return doNotUseSearchResults();
   	  }
   	  
   	  clearSearchResults();
   	  // make sure at least one field has a value
   	  if (newUser.Email != null || newUser.LastName != null || newUser.FirstName != null) {
   	     // search User record by first name/last name and email address
   	     searchUsers();
   	     // search Contact records by first name/last name and email address
   	     searchContacts(newUser.Email,newUser.FirstName,newUser.LastName);
   	  } // if (newUser.Email
   	  
   	  // are there any search results?
   	  hasSearchResults = (getHasUserSearchResults() || getHasContactSearchResults());
   	  if (!hasSearchResults) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No search results were found! Please enter the information for a new user.'));
         return doNotUseSearchResults();
   	  }
   	  return Page.NewUser1;
   } // performSearch
   
   private PageReference doNotUseSearchResults() {
   	  enterAddInfo = true;
   	  newUser.Username = getUsername(newUser.Email);
   	  newUser.Alias=uh.getUserId(newUser.Email,5);
   	  newUser.CommunityNickname=uh.getUniqueNicknameByEmail(newUser.Email);
      return Page.NewUser2;
   } // doNotUseSearchResults
   
   /** Build the where clause for the Contact and User queries.
    */
   public String buildWhereClause(String email, String firstName, String lastName) {
   	  String whereClause = ' ';
   	  if (email != null) {
   	  	 whereClause += 'Email=\''+String.escapeSingleQuotes(email)+'\' ';
   	  }
   	  if (lastName != null || firstName != null) {
   	  	 whereClause += (email != null) ? ' or ' : '';
   	  	 whereClause += '(';
   	  	 whereClause += (lastName != null) ? '(LastName like \''+String.escapeSingleQuotes(lastName)+'%\') ' : '';
   	  	 whereClause += (lastName != null && firstName != null) ? ' and ' : '';
   	  	 whereClause += (firstName != null) ? '(FirstName like \''+String.escapeSingleQuotes(firstName)+'%\') ' : '';
   	  	 whereClause += ')';

   	  } // if (newUser.LastName
   	  return whereClause; 
   } // buildWhereClause
   
   /** Search the User records.
    */
   private void searchUsers() {
   	  String whereClause = buildWhereClause(newUser.Email,newUser.FirstName,newUser.LastName);
   	  foundUsers = uh.getUsers(' where '+whereClause);
   } // searchUsers
   
   /** Search the Contact records.
    */
   public void searchContacts(String email, String firstName, String lastName) {
      //String whereClause = ' where Account.Name = \'Paychex Inc SA\' and (';
      // make sure we only select active records - so check for term date
      String whereClause = ' where Account.Name = \'Paychex Inc SA\' and HR_Person_Id__c != null and Date_of_Employee_Termination__c=null and (';
      whereClause += buildWhereClause(email,firstName,lastName);
      whereClause += ') ';
      foundContacts = uh.getContacts(whereClause);
   } // searchContacts
   
   /** Get the username based on the email address.
    */
   public String getUsername(String email) {
      String usernameExtension = Utilities.checkForProduction();
      if (usernameExtension != '') {
         usernameExtension = '.'+usernameExtension;
      }
      return email+usernameExtension;
   } // getUsername
   
   /** process the user record from the result of a search.
    */
   public PageReference handleRecordAction() {
      String uType = System.currentPageReference().getParameters().get('type');
      Id recId = System.currentPageReference().getParameters().get('recId');
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'uType='+uType+' recId='+recId));

      if (uType == 'useUser') {
      	 // edit the existing user record
      	 for (User thisUser : foundUsers) {
      	    if (thisUser.Id == recId) {
      	       newUser = thisUser;
      	       PageReference userPage = new PageReference('/'+newUser.id+'/e');
               return userPage;
      	    } // if (thisUser
      	 } // for (User)
      } else if (uType == 'copyUser') {
      	 // copy data from an existing user record to a new record.
      	 // find the record
      	 for (User thisUser : foundUsers) {
      	    if (thisUser.Id == recId) {
      	       User copyUser = thisUser.clone(false,true);
      	       
      	       // CommunityNickname needs to be unique in an organization
      	       copyUser.CommunityNickname = uh.getUniqueNickname(thisUser.CommunityNickname);
      	       copyUser.FirstName = (newUser.FirstName == null ? thisUser.FirstName : newUser.FirstName);
      	       copyUser.LastName = (newUser.LastName == null ? thisUser.LastName : newUser.LastName);
      	       copyUser.Username = getUsername(thisUser.Email);
      	       
      	       newUser = copyUser;
      	       enterAddInfo = true;
      	       clearSearchResults();
               return Page.NewUser1;
      	    } // if (thisUser.Id
      	 } // for (User user)
      } else if (uType == 'copyContact') {
         // use the contact record to pre-populate the user record.
         for (Contact thisC : foundContacts) {
         	if (thisC.Id == recId) {
         		createUserFromContact(newUser, thisC);
               
               enterAddInfo = true;
      	      checkOrganization(newUser);
      	      clearSearchResults();
               return Page.NewUser1;
         	} // if (thisC.Id
         } // for (Contact thisC
      	
      }
      // https://cs3.salesforce.com/005/e?retURL=%2F005&cancelURL=%2F005&00N50000001WwKc=Corporate&email=test
      return Page.NewUser1;
   } // handleRecordAction
   
   public void createUserFromContact(User usr, Contact ctct) {
      uh.setUserFromContact(usr,ctct);

      String useEmail = (ctct.Email != null ? ctct.Email : usr.Email);
      newUser.Alias=uh.getUserId(useEmail,5);
      newUser.CommunityNickname=uh.getUniqueNicknameByEmail(useEmail);
      newUser.Email = useEmail;
      newUser.FirstName = (usr.FirstName == null ? ctct.FirstName : usr.FirstName);
      newUser.LastName = (usr.LastName == null ? ctct.LastName : usr.LastName);
      newUser.Username = getUsername(useEmail);
               
   } // createUserFromContact
   
   public PageReference saveAndContinue() {
      checkDefaultIds();
   	  
      // in case these weren't set on the first screen since email is not required anymore.
      if (newUser.Alias == null || newUser.Alias == '') {
         newUser.Alias=uh.getUserId(newUser.Email,5);
         newUser.CommunityNickname=uh.getUniqueNicknameByEmail(newUser.Email);
      } // if (newUser.Alias
   	  
      // set other fields
      newUser.ProfileId = newProfile.Id;
      newUser.UserRoleId = newRole.Id;
      newUser.TimeZoneSidKey = curUser.TimeZoneSidKey;
      newUser.LocaleSidKey = curUser.LocaleSidKey;
      newUser.EmailEncodingKey = curUser.EmailEncodingKey;
      newUser.LanguageLocaleKey = curUser.LanguageLocaleKey;
      if (uh.isCore(newUser.Sales_Org__c) ||
          uh.isHRS(newUser.Sales_Org__c) ||
          uh.isMMS(newUser.Sales_Org__c)) {
         //newUser.UserPermissionsMobileUser = true;
      } // if

      newUser.CompanyName = 'Paychex';
      newUser.SFDC_User_Start_Date__c = Date.today();
      newUser.IsActive=false;
      newUser.Creation_Type__c='NewUser';
   	
   	  try {
   	     insert newUser;
   	  } catch(DmlException ex){
         ApexPages.addMessages(ex);
         return ApexPages.currentPage();
   	  }
   	  PageReference pr = new ApexPages.StandardController(new User(id = newUser.id)).edit();
 //  	  pr.getParameters().put('retURL','%2F'+newUser.Id);
 //  	  pr.getParameters().put('cancelURL','%2F'+newUser.Id);
   	  return pr;
/*
      PageReference userPage = new PageReference('/'+newUser.id+'/e?&retURL=%2F'+newUser.Id+'&cancelURL=%2F'+newUser.Id);
      return userPage;
      */
   } // saveAndContinue

   public PageReference reCheckOrganization() {
   	  checkOrganization(newUser);
   	  return Page.NewUser2;
   } // reCheckOrganization

   /** The default roleId. */
   private static UserRole newRole = null;
   /** The default profileId. */
   private static Profile newProfile = null;
   
   private static void checkDefaultIds() {
   	  if (newRole == null) {
  	     newRole = [Select Id, Name from UserRole where Name = :Utilities.NEW_USER_ROLE limit 1];
   	     newProfile = [Select Id, Name from Profile where Name = :Utilities.NEW_USER_PROFILE limit 1];
   	  } // if (roleId
   } // checkDefaultIds
   
   
   public PageReference continueWithoutSearched() {
   	  enterAddInfo = true;
   	  newUser.Alias=uh.getUserId(newUser.Email,5);
      newUser.CommunityNickname=uh.getUniqueNicknameByEmail(newUser.Email);
   	  newUser.Username = getUsername(newUser.Email);
   	  return Page.NewUser2;
   } // continueWithoutSearched
   
} // class NewUserController