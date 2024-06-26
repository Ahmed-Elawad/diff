/* 
* The methods used for managing user maintenance.

Existing user is entered on the form.
if Ending a user
if there is open activity, the users will get an option to transfer the activity to another user. 
if they do not enter another user the open activity will remain with the ended user. The user will be inactivated immediately. 
If they enter another user the user will remain active until the activity is transferred.
if there is no open activity, the user will be inactivated immediately.
if Transferring activity only
if no open activity exists, nothing will happen - error displays
If open activity exists, prompt for user to transfer activity to.
If no user is entered, error that nothing was changed and return to main form.
If user is entered, save the user transfer record and allow the triggers to perform the operation.
if transferring an existing user
User to mirror must be entered, otherwise they get an error.
if both existing user and user to mirror are sales
if closed activity exists, both users will remain active to transfer the closed activity to the non-surviving user
if open activity exists, and a user to transfer is selected, transfer the open activity to that user.
If open activity exists, and a user to transfer is not selected, transfer the closed activity to the non-surviving user
If one or both users are not sales
If open activity exists, and a user to transfer is selected, transfer the open activity to that user.
When activity is handled, inactivate the non-surviving user record.

Change to Transfer User process.
Running User selects existing user
Running User selects User to mirror
On the next screen, the running user confirms their selection
The User Transfer record is saved with a status of STATUS_USER_TXFER
The UserTransfer trigger calls a future method. A callout to UserTransferTxferREST happens during the future method
UserTransferTxferREST creates the new User record and updates the existing record. It also handles any public group copy.
The rest service returns the ID of the new User record. This is to handle the mixed DML operation.
Back at the calling method (in ManageUserHelper)
if success, we set the new user id on the User_Transfer__c record and change the status.
If there is activity to transfer, that transfer is started now.
If failure, error message is returned. Status is changed and message is logged to comments


*
* History
* -------
* 10/29/2010 Dan Carmen   Created
08/10/2011 Dan Carmen   Add additional testing.
11/21/2011 Dan Carmen   Add in logic to maintain queues
07/15/2012 Justin Stouffer Add in logic to restrict Add New Users to Sys Admin.
06/06/2015 Dan Carmen   Changes to how process works
01/04/2016 Dan Carmen   Changes to allow AddUserController to call group/permission set methods
02/03/2016 Dan Carmen   Change to without sharing.
06/09/2016 Dan Carmen   Don't save the error message after group operations.
07/11/2016 Dan Carmen   Add some additional debugging
10/03/2016 Dan Carmen   Add ManageZipOrgUnitsManaged__c to be copied with user to mirror
04/04/2017 Dan Carmen   Add Leave of Absence option to the menu
03/05/2018 Carrie Marciano Add ForecastEnabled to be copied with user to mirror
10/22/2018 Dan Carmen      Ability to pass in permission set names when creating new group membership.
11/26/2018 Jake Hinds    Adding in user license request
08/25/2020  Carrie Marciano Oracle CPQ license functionality
12/15/2020 Dan Carmen    Clear out Federation Id on non-surviving user. Add field to query.
02/17/2020 Josh Cartwright added excludedPermsList to query that selects permission sets to exclude certain permissions from transferring 
10/11/2022 Dan Carmen      Change copyFromMirrorUser to use CopyFromMirrorFlds fieldSet for the fields to copy 
06/14/2023 Lalan Kumar   APR0135718: updating 'Transfer Date' field when a Transfer User request is completed
06/27/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu)
04/26/2024 Dan Carmen      Don't show Apex message in queueable

*/
public class ManageUserController {
    
    // sales to sales transfers all old activity to the new user record and they continue to use the existing record.
    public static final String RULE_BEFORE='Before Effective Date';
    // all other transfers will go to 
    public static final String RULE_AFTER='After Effective Date';
    
    public boolean packageSelected{get;set;}
    public static List<Installed_Package__mdt> packages;      
    public static Id requestor = Userinfo.getuserid();               
    public static string requestorName = Userinfo.getName();
    Public List<string> leftselected{get;set;}   
    Public List<string> rightselected{get;set;}  
    Public Set<string> leftvalues = new Set<string>();   
    Public Set<string> rightvalues = new Set<string>();      
    String  indxvalue{get;set;}
    
    /** Default constructor.
*/
    public ManageUserController() {
        setup();
    } // ManageUserController
    
    private void setup() {
        system.debug('setup begin - build userTransfer record');  
        doStep1();
        existingUserName = null;
        
        userTransfer = new User_Transfer__c(Status__c=ManageUserHelper.STATUS_INCOMPLETE);
        userTransfer.Effective_Date__c = Date.today();
        userTransfer.StrX__c='X';
        
        resetCounters(userTransfer);
        //strXs = 'X';
        xferMsg = Date.today().format();
        userSaveNeeded = false;
        
        isTxfer = false;
        isTxferActivity = false;
        // txferOpp = false;  
        
        isEnd = false;
        leftselected = new List<String>();    
        rightselected = new List<String>();   
        Schema.DescribeFieldResult fieldResult = Manage_Package_License__c.CPQ_User_type__c.getDescribe();   
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();    
        for( Schema.PicklistEntry f : ple){  
            //cpqUserTypes.add(new SelectOption(f.getLabel(), f.getValue()));    
            leftvalues.add(f.getValue());    
        }  
    } // setup
    
    private String xferMsg = null;
    
    public final static String OPTION_NEW='NewUser';
    public final static String OPTION_TXFER='Transfer User';
    public final static String OPTION_TXFER_ACTIVITY='Transfer Activity';
    public final static String OPTION_END='End User-Term';
    public final static String OPTION_END_LOA='End User-Leave Of Absence';
    public final static String OPTION_QUEUE='Queue';
    public final static String OPTION_PKG_LICENSE = 'Add CPQ License (New User)';
    public final static String OPTION_PKG_LICENSE_ChangeGroup = 'Manage CPQ Groups (Existing User)'; 
    public final static String OPTION_Transfer_User_Basic='Transfer User Basic';
    public final static String OPTION_Update_User_Role_Only='Update User Role Only';
    public final static String OPTION_Transfer_User_with_Open_Activity='Transfer User with Open Activity';
    public final static String OPTION_Transfer_User_and_Open_Opportunities_Only='Transfer User and Open Opportunities Only';
    public final static String OPTION_Move_Open_Activity_and_Open_Opportunities='Move Open Activity and Open Opportunities';    
    
    public PageReference selectclick(){ 
        Integer rowNum = Integer.valueOf(apexpages.currentpage().getparameters().get('index'));
        System.debug('cpq indext ' + rowNum); 
        rightselected.clear();  
        for(String s : leftselected){   
            leftvalues.remove(s);   
            rightvalues.add(s); 
        }   
        licenseWrapList[rowNum].cpqUserTypeList = rightvalues; 
        licenseWrapList[rowNum].cpqUserType = rightvalues.toString();
        return null;    
    }   
    
    public PageReference unselectclick(){   
        
        Integer rowNum = Integer.valueOf(apexpages.currentpage().getparameters().get('index1'));
        System.debug('logLevel 1' + licenseWrapList[rowNum].cpqUserType); 
        leftselected.clear();   
        for(String s : rightselected){  
            rightvalues.remove(s);  
            leftvalues.add(s);  
        }   
        licenseWrapList[rowNum].cpqUserTypeList = rightvalues; 
        licenseWrapList[rowNum].cpqUserType = rightvalues.toString(); 
        System.debug('logLevel 2' + licenseWrapList[rowNum].cpqUserType); 
        return null;    
    }   
    
    public List<SelectOption> getunSelectedValues(){    
        List<SelectOption> options = new List<SelectOption>();  
        List<string> tempList = new List<String>(); 
        tempList.addAll(leftvalues);    
        tempList.sort();    
        for(string s : tempList)    
            options.add(new SelectOption(s,s)); 
        return options; 
    }   
    
    public List<SelectOption> getSelectedValues(){  
        List<SelectOption> options1 = new List<SelectOption>(); 
        List<string> tempList = new List<String>(); 
        tempList.addAll(rightvalues);   
        tempList.sort();    
        for(String s : tempList)    
            options1.add(new SelectOption(s,s));    
        return options1;    
    }
    
    // The options available for managing a user.
    public List<SelectOption> manageOptions { 
        get{
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption(OPTION_NEW,'Create a New User'));
            options.add(new SelectOption(OPTION_TXFER,'Transfer an Existing User'));
            options.add(new SelectOption(OPTION_END,'End an Existing User-No Longer with Paychex'));
            options.add(new SelectOption(OPTION_END_LOA,'End an Existing User-Leave of Absence'));
            options.add(new SelectOption(OPTION_QUEUE,'Add/Remove User From Queue/Group'));
            options.add(new SelectOption(OPTION_TXFER_ACTIVITY,'Transfer Activity Only (user remains active)'));
            options.add(new SelectOption(OPTION_PKG_LICENSE,'Add CPQ License (New User)'));
            options.add(new SelectOption(OPTION_PKG_LICENSE_ChangeGroup,'Manage CPQ Groups (Existing User)'));
            //options.add(new SelectOption('Reactivate','Reactivate an Inactive User'));
            return options;
        } // get
    } // manageOptions
    
    public List<SelectOption> cpqUserTypes {
        get{                     
            List<SelectOption> cpqUserTypes = new List<SelectOption>();
            cpqUserTypes.add(new SelectOption('', ''));
            Schema.DescribeFieldResult fieldResult = Manage_Package_License__c.CPQ_User_type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple){
                cpqUserTypes.add(new SelectOption(f.getLabel(), f.getValue()));
            }
            
            System.debug('cpqUserTypes: '+cpqUserTypes);
            return cpqUserTypes;
        }       
    } 
    
    Public List<SelectOption> typeOptions{get;set;}
    
    // Transfer an Existing User - Sales Options
    public void transferOptions() { 
           typeOptions = new List<SelectOption>();
           typeOptions.add(new SelectOption('','--None--')); 
           typeOptions.add(new SelectOption(OPTION_Transfer_User_Basic,'Transfer User Basic (No Opportunities or Activity will Transfer, Ex: changing sales orgs)'));
           typeOptions.add(new SelectOption(OPTION_Update_User_Role_Only,'Update User Role Only (Only updating user role only, no transferred user, Ex: District closing, District splitting)'));
           typeOptions.add(new SelectOption(OPTION_Transfer_User_with_Open_Activity,'Transfer User with Open Activity (Move All Open Tasks and Events Only, Ex: User needs tasks and scheduled activity to move with them)'));
           typeOptions.add(new SelectOption(OPTION_Transfer_User_and_Open_Opportunities_Only,'Transfer User and Open Opportunities Only (Move open Opportunities that are in sold or prior status, Ex: User allowed to keep working open opportunities)'));
           typeOptions.add(new SelectOption(OPTION_Move_Open_Activity_and_Open_Opportunities,'Move Open Activity and Open Opportunities (Move both Activity and Opportunity, Ex: User allowed to keep working existing open opportunities and open activity)'));          
    } // transferExistingUsers
    
    // For transfer/end
    //    select a user/date
    //    check for activity
    //        if existing activity, ask what they want to do with it
    //    if transfer ask for a user to mirror - a user in a position they want to transfer the employee to
    
    public Boolean isTxfer{get;set;}
    public Boolean isTxferActivity{get;set;}
    public Boolean isEnd{get;set;}
    
    public User existingUser{get;set;}
    public User newUser = null;
    public User userToMirror{get;set;}
    public User xferToUser = null;
    
    
    // First step in the process - selecting an action. 
    public Boolean step1{get;private set;}
    // Second step in the process - selecting a transfer type. 
    public Boolean step2{get;private set;}
    
    // For the Add/Remove from Queue/Group page.
    public Boolean maintainGroup{get; private set;}
    public Boolean showMainBlock{get; private set;}
    public Boolean copyPublicGrpuQue{get;  set;}
    public string buttonName{get; private set;}
    private void setupPage(Boolean s1, Boolean s2, Boolean q1, Boolean showFinished, Boolean l1) {
        step1 = s1;
        step2 = s2;
        system.debug('step1====>>>'+step1);
        showMainBlock = (step1 || step2);
        system.debug('showMainBlock----====>>>'+showMainBlock);
        maintainGroup = q1;
        packageSelected= l1; 
        if (l1 == true && userTransfer.Manage_Type__c == OPTION_PKG_LICENSE  ) {    
            buttonName = 'Request for License';    
        }         
        else if(l1 == true && userTransfer.Manage_Type__c == OPTION_PKG_LICENSE_ChangeGroup ){    
            buttonName = 'Submit Request';     
        }       
        system.debug('packageSelected-====>>>'+packageSelected);
        showFinishedBlock = showFinished;
    } // setupPage
        
    public PageReference saveTransfer() {
        userTransfer.Status__c = ManageUserHelper.STATUS_USER_TXFER; 
        system.debug('saveTransfer userTransfer.Transfer_Type__c: '+userTransfer.Transfer_Type__c);
        saveUserTransfer();
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your request was submitted successfully! You will receive an email when the new User is ready.'));
        setup();
        return Page.ManageUsers;
    } // saveTransfer
    
    public PageReference finished() {
        saveUserTransfer();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your request was submitted successfully!'));
        setup();
        return Page.ManageUsers;
    } // finished
    
    // Cancel current step and start over.
    public PageReference cancel() {
        if (userTransfer.Id != null) {
            delete userTransfer;
        }
        setup();
        for(String s : rightvalues){  
            rightvalues.remove(s); 
            leftvalues.add(s); 
        } 
        
        return ApexPages.currentPage();
    } // cancel
    
    public PageReference doStep1() {
        setupPage(true,false,false,false,false);
        return Page.ManageUsers;
    } // doStep1
    
    public PageReference doStep2() {
        setupPage(false,true,false,false,false);
        return Page.ManageUsers;
    } // doStep2
    
    public PageReference doMaintainGroup() {
        setupPage(false,false,true,false,false);
        return Page.ManageUsers;
    } // doMaintainGroup
    
    public PageReference doShowFinished() {
        setupPage(false,false,false,true,false);
        return Page.ManageUsers;
    } // doShowFinished
    
    public PageReference doMaintainLicenses() {
        setupPage(false,false,false,false,true);      
        return Page.ManageUsers;      
    } // doMaintainLicenses
    public list<LicenseWrapper> licenseWrapList{get;set;}
    
    // make a selection from the first screen
    public PageReference selectManageType() {
        system.debug('selectManageType userTransfer.Manage_Type__c'+userTransfer.Manage_Type__c); 
        transferOptions();
        if (userTransfer.Manage_Type__c == OPTION_NEW) {
            // send to existing new user functionality
            PageReference pr = Page.AddUser;
            pr.setRedirect(true);
            return pr;
        } // if (userTransfer.Manage_Type__c == OPTION_NEW
        
        checkExistingUser(userTransfer.Manage_Type__c != OPTION_TXFER_ACTIVITY);
        if (!existingUserOkay) {
            return doStep1();
        } else {
            if (userTransfer.Manage_Type__c == OPTION_QUEUE) {
                return processGroup();
            } else if (userTransfer.Manage_Type__c == OPTION_TXFER 
                       || userTransfer.Manage_Type__c == OPTION_END
                       || userTransfer.Manage_Type__c == OPTION_END_LOA 
                       || userTransfer.Manage_Type__c == OPTION_TXFER_ACTIVITY) {
                if (userTransfer.Effective_Date__c == null) {
                    userTransfer.Effective_Date__c.addError('Effective Date must be selected to proceed!');
                    return doStep1();
                }
                if (userTransfer.Effective_Date__c > Date.today()) {
                    userTransfer.Effective_Date__c.addError('Effective Date must not be in the future.');
                    return doStep1();
                }
                if (userTransfer.Manage_Type__c == OPTION_END) {
                    isEnd = true;
                    verifyActivity();
                    setTermedFields(existingUser);
                    userSaveNeeded = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You have chosen to End the User record for '+existingUserName+'. Click Next to continue.'));
                } else if (userTransfer.Manage_Type__c == OPTION_END_LOA) {
                    isEnd = true;
                    userSaveNeeded = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You have chosen to End the User record for '+existingUserName+'. Click Next to continue.'));
                } else if (userTransfer.Manage_Type__c == OPTION_TXFER) {               
                    if (!verifyCopyFromUser()) {
                       return doStep1();
                    }                   
                    isTxfer = true;
                    verifyActivity();
                } else if (userTransfer.Manage_Type__c == OPTION_TXFER_ACTIVITY) {
                    isTxferActivity = true;
                    verifyActivity();
                    if (!userTransfer.HasOpenActivity__c) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No activity was found for this user to transfer!'));
                        return doStep1();
                    }
                } // if (userTransfer.Manage_Type__c == OPTION_TXFER_ACTIVITY
            } // if (userTransfer.Manage_Type__c == OPTION_TXFER         
            else if(userTransfer.Manage_Type__c == OPTION_PKG_LICENSE){
                //packanegselected=true;
                //step1=false;
                licenseWrapList = new list<LicenseWrapper>();
                packages = [Select DeveloperName,Name_Prefix__c,OwnerId__c From Installed_Package__mdt];
                for(integer i=0;i<packages.size();i++)
                {
                    LicenseWrapper obj = new LicenseWrapper();
                    obj.indxvalue = String.valueOf(i); 
                    obj.csettingname = packages[i].DeveloperName;
                    obj.namePrefix = packages[i].Name_Prefix__c;
                    obj.selectedval=false;
                    if(packages[i].Name_Prefix__c == 'cafsl'){
                        obj.cpqLicense=true;  
                    }
                    else{
                        obj.cpqLicense=false; 
                    }
                    obj.cpqUserType='';
                    //obj.cpqUserTypeList = new set<string>(); 
                    obj.owner = packages[i].OwnerId__c;
                    licenseWrapList.add(obj);     
                    //break;    
                }   
                //return doStep1(); 
                return doMaintainLicenses();    
            }  
            else if(userTransfer.Manage_Type__c == OPTION_PKG_LICENSE_ChangeGroup){   
                //    
                //       
                UserHelper uh = new UserHelper(); 
                String whereClause = 'where cafsl__User__c = \''+existingUser.Id+'\' ';    
                List<cafsl__Oracle_User__c> allUserMatchesWithCPQUser = uh.getCPQUsers(whereClause);
                if(allUserMatchesWithCPQUser != null && !allUserMatchesWithCPQUser.isEmpty()){
                    List<string> values; 
                    for (cafsl__Oracle_User__c rec : allUserMatchesWithCPQUser) {
                        values = String.valueOf(rec.cafsl__Groups__c).split(';');                         
                    }
                    for (string  s : values) {
                        leftvalues.remove(s); 
                        rightvalues.add(s); 
                    }
                    licenseWrapList = new list<LicenseWrapper>();
                    
                    packages = [Select DeveloperName,Name_Prefix__c,OwnerId__c From Installed_Package__mdt];    
                    
                    List<Manage_Package_License__c> existLicForUsr = [Select User_Name__c, Request_Status__c,    
                                                                      Requestor__c, Package_Name__c, ownerId,  
                                                                      CPQ_User_Type__c from Manage_Package_License__c];    
                    for(integer i=0;i<packages.size();i++)    {   
                        LicenseWrapper obj = new LicenseWrapper(); 
                        obj.indxvalue = String.valueOf(i); 
                        obj.csettingname = packages[i].DeveloperName;  
                        obj.namePrefix = packages[i].Name_Prefix__c;   
                        obj.selectedval=false; 
                        if(packages[i].Name_Prefix__c == 'cafsl'){ 
                            obj.cpqLicense=true;    
                        }  
                        else{  
                            obj.cpqLicense=false;   
                        }  
                        obj.cpqUserType='';    
                        // obj.cpqUserTypeList = new set<string>(); 
                        obj.owner = packages[i].OwnerId__c;
                        licenseWrapList.add(obj);
                        //break;
                    }
                    //return doStep1();
                    return doMaintainLicenses();
                }
                else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Existing user don\'t have CPQ User Licenses'));
                    return doStep1();
                }
            } // to remove package licents 
        } // if (existingUserOkay
        saveUserTransfer();
        
        // for all other options select a user
        return doStep2();
    } // selectManageType
    
    /** The name of the selected user. */
    public String existingUserName{get; private set;}
    
    public Boolean existingUserOkay{
        get { return (existingUser != null && existingUser.IsActive);}
    }
    
    // Check for the existing user record.
    private Boolean checkExistingUser(Boolean activeOnly) {
        system.debug('checkExistingUser begin'); 
        if (userTransfer.Existing_User__c == null) {
            userTransfer.Existing_User__c.addError('You need to select an existing user to continue!');
            return false;
        }
        
        existingUser = usrHelper.getUserById(userTransfer.Existing_User__c);
        userTransfer.Existing_User__c = existingUser.Id;
        
        if (activeOnly && !existingUser.IsActive) {
            userTransfer.Existing_User__c.addError('The User you selected is not active. You must start with an active User record.');
            return false;
        }
        
        SalesOrg__c salesOrg = (String.isNotBlank(existingUser.Sales_Org__c) ? SalesOrg__c.getInstance(existingUser.Sales_Org__c) : null);
        System.debug('checkExistingUser existingUser.Sales_Org__c='+existingUser.Sales_Org__c+' salesOrg='+salesOrg);
        userTransfer.IsExistingSales__c = (salesOrg != null && salesOrg.IsSales__c);
        userTransfer.Email__c = existingUser.email;
        userTransfer.Username__c = existingUser.Username;
        
        existingUserName = existingUser.Name;
        if (userTransfer.Manage_Type__c != 'Queue') {
            searchExistingXfers(existingUser.Username);
            if (isExistingSales) {
                xferMsg += ' From Sales Org '+existingUser.Sales_Org__c+', District '+existingUser.District__c;
            } else {
                xferMsg += ' From Business Unit '+existingUser.Sales_Org__c+', Cost Center '+existingUser.Cost_Center__c;
            }
        } // (userTransfer.Manage_Type__c
        return true;
    } // checkExistingUser
    
    // Save the User_Transfer__c record.
    private boolean saveUserTransfer() {
        system.debug('saveUserTransfer begin');
        if (userTransfer.Id == null) {
            insert userTransfer;
        } else {
            update userTransfer;
        }
        return true;
    } // saveUserTransfer
    
    /** The record used to select the user to transfer. */
    public User_Transfer__c userTransfer {get;set;}
    
    /** instantiation of the UserHelper class. */
    private UserHelper usrHelper = new UserHelper();
    
    // Is the existing user a sales user? 
    public Boolean isExistingSales {
        get {return userTransfer.IsExistingSales__c;}
    } // isExistingSales
    
    
    // The X's used for the transfer record. 
    //public String strXs{get; private set;} 
    
    // get whichever user record is going to be the survivor
    public User survivingUser{
        get {return (userTransfer.ExistingUserIsSurvivor__c ? existingUser : newUser); }
    } // survivingUser
    
    public User nonSurvivingUser{
        get {return (isTxfer && userTransfer.ExistingUserIsSurvivor__c ? (userTransfer.Transfer_Type__c != 'Update User Role Only' ? newUser : null) : (userTransfer.Transfer_Type__c != 'Update User Role Only' ? existingUser : null)); }
    }
    
    // Verify if the user has activity to populate fields on userTransfer - not to determine what activity to move
    public Boolean verifyActivity() {
        system.debug('verifyActivity begin - Verify if the user has activity to populate fields on userTransfer - not to determine what activity to move');
        system.debug('verifyActivity userTransfer.Transfer_Type__c: '+userTransfer.Transfer_Type__c);
        
        userTransfer.HasOpenActivity__c = checkForActivity(existingUser.Id,userTransfer.Effective_Date__c, true, userTransfer.Transfer_Type__c);
        // if sales, and the existing user record is the survivor
        userTransfer.HasClosedActivity__c = (isExistingSales ? checkForActivity(existingUser.Id,userTransfer.Effective_Date__c, false, userTransfer.Transfer_Type__c) : false);
        
        // if we are updating the role on an existing user and not transferring we do not need to create a transfer User
        if(userTransfer.Transfer_Type__c != 'Update User Role Only'){
        	createTxferUser();    
        }
                
        return true;
    } // verifyActivity
    
    public void updateExistingUserRole() {
        system.debug('updateExistingUserRole begin');  
        List<UserRole> urList = ManageUserHelper.getUserRole(userTransfer.Role__c);
        List<Profile> pList = ManageUserHelper.getProfile(userTransfer.Profile__c);   
        
        if(userToMirror != null){
           	existingUser.userRoleId = userToMirror.UserRoleId; 
            system.debug('updateExistingUserRole update role from userToMirror');
        }
        else{
        	if(!urList.isEmpty() && userTransfer.Role__c != null){
           		existingUser.UserRoleId = urList[0].id;
        	}
        	if(!pList.isEmpty() && userTransfer.Profile__c != null){
            	existingUser.ProfileId = pList[0].id;
        	}
            existingUser.Sales_Org__c = userTransfer.Sales_Org__c;
            system.debug('updateExistingUserRole update role, profile & sales org from userTransfer Role, Profile & sales org fields');
        }
        
        // for a role update only we do not create a new user we update the existing user
        userTransfer.ExistingUserIsSurvivor__c = True;
        userSaveNeeded = true;
    } // updateExistingUserRole
    
    public void createTxferUser() {
        system.debug('createTxferUser begin survivingUser: '+survivingUser);
        system.debug('createTxferUser begin nonSurvivingUser: '+nonSurvivingUser);
        if (isTxfer) {
            newUser = createNewUser(existingUser);
            system.debug('createTxferUser begin newUser: '+newUser);
            setTransferFields(nonSurvivingUser);
            userSaveNeeded = true;
        }
        
        // get contact record if it exists.
        userTransfer.Contact__r = usrHelper.getContactByPersonId(existingUser.HR_Person_Id__c,UserHelper.PAYCHEX_COMP);
        userTransfer.Contact__c = (userTransfer.Contact__r != null ? userTransfer.Contact__r.Id : null);
        
        System.debug('createTxferUser survivingUser='+survivingUser);
        
        if (survivingUser != null) {
            userSaveNeeded = true;
            updateUserFromContact(survivingUser, userTransfer.Contact__r);
            
            // set fields from the copy user
            copyFromMirrorUser(survivingUser,userToMirror);
            
            survivingUser.Email = (String.IsNotBlank(userTransfer.Email__c) ? userTransfer.Email__c : survivingUser.Email);
            survivingUser.Username = (String.isNotBlank(userTransfer.Username__c) ? userTransfer.Username__c : survivingUser.Username);
            survivingUser.Cost_Center__c = (String.isNotBlank(userTransfer.CostCenter__c) ? userTransfer.CostCenter__c : survivingUser.Cost_Center__c);
        } // if (survivorUser    
        
    } // createTxferUser
    
    public void copyFromMirrorUser(User survivorUser, User mirrorUser) {
        system.debug('copyFromMirrorUser begin'); 
        List<UserRole> urList = ManageUserHelper.getUserRole(userTransfer.Role__c);
        List<Profile> pList = ManageUserHelper.getProfile(userTransfer.Profile__c);
        
        // set fields from the copy user
        if (mirrorUser != null) {
            for (Schema.FieldSetMember fsm : Schema.SObjectType.User.fieldSets.CopyFromMirrorFlds.getFields()) {
                String fldName = fsm.getFieldPath();
                try {
                    survivorUser.put(fldName, mirrorUser.get(fldName));
                } catch (Exception e) {
                    System.debug('copyFromMirrorUser fldName='+fldName+' e='+e.getMessage());
                }
            }
        } 
        else {
        	if(!urList.isEmpty() && userTransfer.Role__c != null){
           		survivorUser.UserRoleId = urList[0].id;
        	}
        	if(!pList.isEmpty() && userTransfer.Profile__c != null){
            	survivorUser.ProfileId = pList[0].id;
        	}
            system.debug('copyFromMirrorUser userTransfer.Sales_Org__c: '+userTransfer.Sales_Org__c);
            if (userTransfer.Sales_Org__c !=  null){
                survivorUser.Sales_Org__c = userTransfer.Sales_Org__c;
            }
            system.debug('copyFromMirrorUser update role, profile & salesOrg from userTransfer Role, Profile & Sales Org fields');
            system.debug('copyFromMirrorUser survivorUser.UserRoleId: '+survivorUser.UserRoleId);
            system.debug('copyFromMirrorUser survivorUser.ProfileId: '+survivorUser.ProfileId);
        } // if (mirrorUser
    } // copyFromMirrorUser
    
    // do we need to save the users after the confirmation screen?
    public Boolean userSaveNeeded{get;private set;}
    
    // after the user selects the user to mirror and/or user to transfer open activity to
    public PageReference prepareToTransfer() {
        // verify that any users entered are valid (active)
        Boolean okay = verifyActivityTxferToUser();
        System.debug('prepareToTransfer okay='+okay);
        // if okay, save the user records
        if (isTxferActivity) {
            if (okay && userTransfer.Activity_Xfer_To__c == null) {
                userTransfer.Activity_Xfer_To__c.addError('Select a User to transfer the open activity');
                okay = false;
            }
            if (okay) {
                userTransfer.Status__c = ManageUserHelper.STATUS_ACT_TRANSFER;
                return finishProcessWithActivity();
            }
        } else if (okay && isEnd) {
            userTransfer.Status__c = (userTransfer.Activity_Xfer_To__c != null ? ManageUserHelper.STATUS_ACT_TRANSFER : ManageUserHelper.STATUS_COMPLETE);
            if (userTransfer.Status__c == ManageUserHelper.STATUS_COMPLETE) {
                existingUser.IsActive=false;
                userSaveNeeded = true;
            }
            return finishProcessWithActivity();
        } else if (okay && isTxfer) {
            userTransfer.Status__c = ManageUserHelper.STATUS_ACT_TRANSFER;
            return finishProcessWithActivity();
        } // if (okay && isEnd
        
        return doStep2();
    } // prepareToTransfer
    
    public PageReference finishProcessWithActivity() {
        System.debug('finishProcessWithActivity userSaveNeeded: '+userSaveNeeded);
        // only can do one or the other due to mixed dml operations
        if (userSaveNeeded) {
            saveUsers();
        } else {
            saveUserTransfer();
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your information has been saved and queued for processing. You will be sent an email when it is complete'));
        return doShowFinished();
    } // finishProcessWithActivity
    
    public Boolean showFinishedBlock{get;private set;}
    
    // verify a user was selected and they're active
    public Boolean verifyCopyFromUser() {
        system.debug('verifyCopyFromUser begin'); 
        Boolean okay = true;
           
        if (userTransfer.CopyUserFrom__c == null) {
            if (userTransfer.Role__c != null && userTransfer.Profile__c != null){
                List<UserRole> urList = ManageUserHelper.getUserRole(userTransfer.Role__c);
        		List<Profile> pList = ManageUserHelper.getProfile(userTransfer.Profile__c); 
            	if(urList.IsEmpty() && userTransfer.Role__c != null){
                   userTransfer.Role__c.addError('The Role you entered is not correct.');
                   okay = false;  
                }
                if(pList.IsEmpty() && userTransfer.Profile__c != null){
                   userTransfer.Profile__c.addError('The Profile you entered is not correct.');
                   okay = false;  
                }	
                if (userTransfer.Sales_Org__c == null){
                    userTransfer.Sales_Org__c.addError('When entering Profile and Role, you must also enter a Sales Org');
                }
                else {
                    SalesOrg__c salesOrg = (String.isNotBlank(userTransfer.Sales_Org__c) ? SalesOrg__c.getInstance(userTransfer.Sales_Org__c) : null);	
                	userTransfer.IsTxferSales__c = (salesOrg != null && salesOrg.IsSales__c);	
                	// we'll keep the existing user if transferring within sales and both are the same sales org.	
                	userTransfer.ExistingUserIsSurvivor__c = (userTransfer.IsExistingSales__c	
                                                          && userTransfer.IsTxferSales__c	
                                                          && existingUser.Sales_Org__c == userTransfer.Sales_Org__c); 
                    // for sales we want new user to be survivor and will move activity and/or opportunities to them if that is the transfer type selected
                    //userTransfer.ExistingUserIsSurvivor__c = userTransfer.IsExistingSales__c && userTransfer.IsTxferSales__c ? false : true;
                }
                userTransfer.CostCenter__c = existingUser.Cost_Center__c;
            }
            else{
                userTransfer.CopyUserFrom__c.addError('You must fill out either the User to Mirror OR Role, Profile and Sales Org');
            	okay = false;    
            }
            
        } else if (userTransfer.CopyUserFrom__c != null) {
            userToMirror = usrHelper.getUserById(userTransfer.CopyUserFrom__c);
            userTransfer.CopyUserFrom__c = userToMirror.Id;
            userTransfer.CostCenter__c = userToMirror.Cost_Center__c;     
            if (!userToMirror.IsActive) {
                userTransfer.CopyUserFrom__c.addError('The User you selected is not active. You must supply an active User record.');
                okay = false;
            } else {	
                SalesOrg__c salesOrg = (String.isNotBlank(userToMirror.Sales_Org__c) ? SalesOrg__c.getInstance(userToMirror.Sales_Org__c) : null);	
                userTransfer.IsTxferSales__c = (salesOrg != null && salesOrg.IsSales__c);	
                // we'll keep the existing user if transferring within sales and both are the same sales org.	
                userTransfer.ExistingUserIsSurvivor__c = (userTransfer.IsExistingSales__c	
                                                          && userTransfer.IsTxferSales__c	
                                                          && existingUser.Sales_Org__c == userToMirror.Sales_Org__c);	
                // for sales we want new user to be survivor and will move activity and/or opportunities to them if that is the transfer type selected
                //userTransfer.ExistingUserIsSurvivor__c = userTransfer.IsExistingSales__c && userTransfer.IsTxferSales__c ? false : true;
                userTransfer.HasGrpMembershipToCopy__c = hasGroupsOrPermissionSets(userToMirror);	
            }
        } // if (isTxfer
        return okay;
    } // verifyCopyFromUser
    
    public Boolean verifyActivityTxferToUser() {
        Boolean okay = true;
        if (userTransfer.HasOpenActivity__c && userTransfer.Activity_Xfer_To__c != null) {
            xferToUser = usrHelper.getUserById(userTransfer.Activity_Xfer_To__c);
            userTransfer.Activity_Xfer_To__c = xferToUser.Id;
            
            if (!existingUser.IsActive) {
                userTransfer.Activity_Xfer_To__c.addError('The User you selected is not active. You must supply an active User record.');
                okay = false;
            }
        } // if (userTransfer.HasActivity__c
        return okay;
    } // verifyActivityTxferToUser
    
    //public String transferUser{get;set;}
    
    public static Boolean CHECK_GRP_MEMBERSHIP=(Label.ManageUserChkGrpMembership == 'Yes');
    
    // save the user record(s)
    public Boolean saveUsers() {
        system.debug('saveUsers begin isTxfer: '+isTxfer);
        Boolean okay = true;
        
        if (isTxfer) {
            if (userTransfer.Transfer_Type__c == 'Update User Role Only'){
                String msg = 'Role updated '+Date.today().format();
                existingUser.Comments__c = msg;
            } else{
            	String msg = 'Transfer '+Date.today().format()+' From ';
            	nonSurvivingUser.IsActive = false;
            	if (userTransfer.ExistingUserIsSurvivor__c) {
                	msg += (getTxferMsg(newUser,userTransfer.IsTxferSales__c)+' To '+getTxferMsg(existingUser,userTransfer.IsExistingSales__c));
            	} else {
                	msg += (getTxferMsg(existingUser,userTransfer.IsExistingSales__c)+' To '+getTxferMsg(newUser,userTransfer.IsTxferSales__c));
            	}
            	existingUser.Comments__c = msg;
                existingUser.Transfer_Date__c = date.today();
            	newUser.Comments__c = msg;    
            } // userTransfer.Transfer_Type__c            
        } // if (isTxfer
        if (test.isRunningTest()) {
            //newUser.Non_Paychex_Employee__c = false ;             
        }
        System.debug('saveUsers ALLOW_ROLE_CALLOUT='+ UserHelper.ALLOW_ROLE_CALLOUT+' existingUser='+existingUser);
        userTransfer.UserSaveStart__c = DateTime.now();
        System.debug('saveUsers before update existingUser: '+existingUser);
        if (existingUser != null) {
            // used to bypass validation rules
            existingUser.ApexUpdatedTime__c = System.now();
            update existingUser;
        }
        System.debug('saveUsers before insert newUser: '+newUser);
        if (newUser != null) {
            // used to bypass validation rules
            newUser.ApexUpdatedTime__c = System.now();
            insert newUser;
            userTransfer.New_User__c = newUser.Id;
            // because of SSO, this command generally won't work
            if (newUser.IsActive) {
                Profile prof = (newUser.ProfileId != null ? [Select Id, Name, PermissionsIsSSOEnabled, IsSSOEnabled from Profile where Id=:newUser.ProfileId] : null);
                if (prof == null || (!prof.PermissionsIsSSOEnabled && !prof.IsSSOEnabled)) {
                    System.ResetPasswordResult result = System.resetPassword(newUser.Id,true);
                }
            } 
        }
        userTransfer.UserSaveEnd__c = DateTime.now();
        User survivingUser = (userTransfer.ExistingUserIsSurvivor__c ? existingUser : newUser);
        if (newUser != null) {
            userTransfer.HasGrpMembershipToCopy__c = hasGroupsOrPermissionSets(userToMirror);
            if (CHECK_GRP_MEMBERSHIP) {
                checkGrpMembership(userTransfer, survivingUser, userToMirror);
            }
        } // if (newUser != null)
        userSaveNeeded = false;
        return okay;
    } // saveUsers
    
    public static boolean checkGrpMembership(User_Transfer__c p_userTransfer, User survivingUser, User p_userToMirror) {
        return checkGrpMembership(p_userTransfer, survivingUser, p_userToMirror, new String[]{});
    }
    
    public static boolean checkGrpMembership(User_Transfer__c p_userTransfer, User survivingUser, User p_userToMirror, String[] permSetNames) {
        Boolean okay = true;
        Boolean checkGrp = (p_userTransfer == null || (p_userTransfer != null && p_userTransfer.HasGrpMembershipToCopy__c));
        if (survivingUser != null && p_userToMirror != null && checkGrp) {
            if (p_userTransfer != null) {
                p_userTransfer.GrpMemberSaveStart__c = DateTime.now();
            }
            okay = copyPermissionsSets(p_userTransfer, survivingUser, p_userToMirror, permSetNames);
            if (okay) {
                okay = copyGroups(p_userTransfer, survivingUser, p_userToMirror);
            }
            if (okay && p_userTransfer != null) {
                p_userTransfer.HasGrpMembershipToCopy__c = false;
            }
            if (p_userTransfer != null) {
                p_userTransfer.GrpMemberSaveEnd__c = DateTime.now();
            }
        } // if (survivingUser != null
        return okay;
    } // checkGrpMembership
    
    // does the copy user have any groups or permission sets for the new user?
    public static boolean hasGroupsOrPermissionSets(User copyUser) {
        Boolean hasData = false;
        if (copyUser != null) {
            Integer cnt = [Select count()
                           From Group
                           Where Type in ('Regular','Queue')
                           and Id in (Select GroupId
                                      From GroupMember
                                      Where UserOrGroupId = :copyUser.Id)];
            hasData = (cnt > 0);
            
            if (!hasData) {
                cnt = [Select count() From PermissionSetAssignment
                       Where AssigneeId=:copyUser.Id
                       and PermissionSet.IsOwnedByProfile = false];
                hasData = (cnt > 0);
            } // if (!hasData
        } // if (copyUser != null
        return hasData;
    } // hasGroupsOrPermissionSets
    
    public static Boolean DISPLAY_VF_MSG=(!System.isFuture() && !System.isBatch() && !System.isQueueable());
    
    // check for permission sets and save on new user
    // permSetNames is to allow to add permission sets to the new user even if the source user doesn't have the permission set
    public static Boolean copyPermissionsSets(User_Transfer__c p_userTransfer, User newUser, User copyUser, String[] permSetNames) {
        if (newUser == null || newUser.Id == null) {
            System.debug('copyPermissionsSets no newUser record found!');
            return false;
        }
        Boolean okay = true;
        Set<Id> permissionSetIdSet = new Set<Id>();
        Set<Id> permissionSetGroupIdSet = new Set<Id>(); 
        // keep track of what the user currently has so we don't add it again
        Set<Id> curUserPerms = new Set<Id>();
        
        list<string> excludedPermsList = label.PermissionSetExclusions.split(',');  
        if (copyUser != null) {
            // find any existing permission sets for the user
            PermissionSetAssignment[] assgns = [Select Id, PermissionSetId, PermissionSet.label,
                                                     PermissionSetGroupId, AssigneeId
                                                     From PermissionSetAssignment
                                                     Where (AssigneeId=:copyUser.Id or AssigneeId=:newUser.Id)
                                                     and PermissionSet.IsOwnedByProfile = false
                                                     and PermissionSet.label not in: excludedPermsList];
            System.debug('copyPermissionsSets assgns='+assgns.size());
            for (PermissionSetAssignment assgn : assgns) {
                if (assgn.AssigneeId == copyUser.Id) {
                   if (assgn.PermissionSetId != null) {
                      permissionSetIdSet.add(assgn.PermissionSetId);
                   } else {
                      permissionSetGroupIdSet.add(assgn.PermissionSetGroupId);
                   }
                } else if (assgn.AssigneeId == newUser.Id) {
                   Id idToAdd = (assgn.PermissionSetId != null ? assgn.PermissionSetId : assgn.PermissionSetGroupId);
                   if (idToAdd != null) {
                      curUserPerms.add(idToAdd);
                   }
                }
            }
        } // if (copyUser != null
        
        if (permSetNames != null && !permSetNames.isEmpty()) {
            PermissionSet[] permSets = [Select Id, Name, IsOwnedByProfile
                                        From PermissionSet
                                        Where Name in :permSetNames
                                        and IsOwnedByProfile = false];
            System.debug('copyPermissionsSets permSets='+permSets.size());
            for (PermissionSet permSet : permSets) {
                permissionSetIdSet.add(permSet.Id);
            }
        }
        System.debug('copyPermissionsSets permissionSetIdSet='+permissionSetIdSet.size()+' permissionSetGroupIdSet='+permissionSetGroupIdSet.size()+' curUserPerms='+curUserPerms.size());
        // remove any that the user currently has
        for (Id curPermId : curUserPerms) {
           permissionSetIdSet.remove(curPermId); 
           permissionSetGroupIdSet.remove(curPermId);
        }
        System.debug('copyPermissionsSets permissionSetIdSet='+permissionSetIdSet.size()+' permissionSetGroupIdSet='+permissionSetGroupIdSet.size());
        
        if (!permissionSetIdSet.isEmpty()) {
            PermissionSetAssignment[] newAssignments = new PermissionSetAssignment[]{};
                for (Id permSetId : permissionSetIdSet) {
                    newAssignments.add(new PermissionSetAssignment(AssigneeId=newUser.Id, PermissionSetId=permSetId));
                }
            String msg = null;
            if (DmlHelper.performDML2(newAssignments, DmlHelper.DML_INSERT, 'ManageUserController', 'checkPermissionsSets', 'insert new PermissionSetAssignment', false)) {
                msg = 'Number of Permission Sets added to User: '+newAssignments.size();
                System.debug('checkPermissionsSets '+msg);
                if (DISPLAY_VF_MSG) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, msg));
                }
            } else {
                okay = false;
                msg = 'Error when inserting permission sets';
                System.debug('checkPermissionsSets '+msg);
                if (DISPLAY_VF_MSG) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
                }
            }
            if (p_userTransfer != null) {
                ManageUserHelper.addToComments(p_userTransfer,msg);
            }
        }
        //PermissionSet Group Insertion
        if (!permissionSetGroupIdSet.isEmpty()) {
            PermissionSetAssignment[] newPermSetGroupAssignments = new PermissionSetAssignment[]{};
                for (Id permSetGroupId : permissionSetGroupIdSet) {
                    newPermSetGroupAssignments.add(new PermissionSetAssignment(AssigneeId=newUser.Id, PermissionSetGroupId=permSetGroupId));
                }
            String msg = null;
            if (DmlHelper.performDML2(newPermSetGroupAssignments, DmlHelper.DML_INSERT, 'ManageUserController', 'checkPermissionsSets', 'insert new PermissionSetAssignment', false)) {
                msg = 'Number of Permission Sets Groups added to User: '+newPermSetGroupAssignments.size();
                System.debug('checkPermissionsSets '+msg);
                if (DISPLAY_VF_MSG) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, msg));
                }
            } else {
                okay = false;
                msg = 'Error when inserting permission Set Groups';
                System.debug('checkPermissionsSets '+msg);
                if (DISPLAY_VF_MSG) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
                }
            }
            if (p_userTransfer != null) {
                ManageUserHelper.addToComments(p_userTransfer,msg);
            }
        }
        
        return okay;
    } // checkPermissionsSets
    
    public static Boolean copyGroups(User_Transfer__c p_userTransfer, User newUser, User copyUser) {
        system.debug('copyGroups begin');
        Boolean okay = true;
        if (copyUser != null && newUser.Id != null) {
            // get existing groups the user is in
            Group[] existingGroups = [Select Id, Name
                                      From Group
                                      Where Type in ('Regular','Queue')
                                      and Id in (Select GroupId
                                                 From GroupMember
                                                 Where UserOrGroupId = :copyUser.Id)];
            if (!existingGroups.isEmpty()) {
                system.debug('copyGroups has existingGroups');
                GroupMember[] newGroupMembers = new GroupMember[]{};
                    for (Group grp : existingGroups) {
                        system.debug('copyGroups grp.Name: '+grp.Name);
                        newGroupMembers.add(new GroupMember(GroupId=grp.Id, UserOrGroupId=newUser.Id));
                    }
                okay = DmlHelper.performDML2(newGroupMembers, DmlHelper.DML_INSERT, 'ManageUserController', 'checkForGroups', 'insert new GroupMembers', false);
                if (p_userTransfer != null) {
                    ManageUserHelper.addToComments(p_userTransfer,'Number of Groups: '+existingGroups.size() );
                }
            }
        } // if (copyUser != null
        return okay;
    } // copyGroups
    public PageReference RerenderPage() {
        
        return new PageReference('/apex/manageusers');
    }
    
    public String getTxferMsg(User usr, Boolean isSales) {
        String msg = '';
        if (isSales) {
            msg += ' Sales Org '+usr.Sales_Org__c+', District '+usr.District__c;
        } else {
            msg += ' Business Unit '+usr.Sales_Org__c+', Cost Center'+usr.Cost_Center__c;
        }
        return msg;
    } // getTxferMsg
    
    public void setTransferFields(User usr) {
        system.debug('setTransferFields begin');
        if (usr != null) {
            usr.LastName = usr.LastName+'-'+userTransfer.StrX__c+'ferred';
            usr.Username = usrHelper.getUserId(usr.Username,null)+userTransfer.StrX__c+usr.Username.substring(usr.Username.indexOf('@'));
            Integer lngthDiff = 8 - (usr.Alias.length()+userTransfer.StrX__c.length());
            if (lngthDiff < 0) {
                usr.Alias = usr.Alias.substring(0,usr.Alias.length()+lngthDiff);
            }
            usr.Alias += userTransfer.StrX__c;
            usr.EmployeeNumber = 'I-'+usr.EmployeeNumber;
            usr.Transfer_Date__c = Date.today();
            usr.CommunityNickname = usrHelper.getUniqueNickname(usr.CommunityNickname+userTransfer.StrX__c);
            usr.FederationIdentifier=null;
        } // if (usr != null
    } // setTransferFields
    
    public void setTermedFields(User usr) {
        if (usr != null) {
            usr.LastName = usr.LastName+'-T';
            usr.Username = usrHelper.getUserId(usr.Username,null)+'-T'+usr.Username.substring(usr.Username.indexOf('@'));
            usr.EmployeeNumber = 'I-'+usr.EmployeeNumber;
            usr.Termination_Date__c = userTransfer.Effective_Date__c;
            usr.FederationIdentifier=null;
        } // if (usr != null
    } // setTermedFields
    
    // Update the user from the contact record, if it exists.
    private void updateUserFromContact(User usr, Contact ctct) {
        if (usr != null && ctct != null) {
            usrHelper.setUserFromContact(usr,ctct);
            usrHelper.checkOrganization(usr);
        }
    } // updateUserFromContact
    
    // Create a new user record from the existing one. 
    public User createNewUser(User copyFrom) {
        system.debug('createNewUser begin');
        User copyTo = copyFrom.clone(false,true);
        copyTo.Creation_Type__c  = 'ManageU';        
        return copyTo;
    } // createNewUser
    
    // Get the prefix of the username (everything before the "@")
    public String getUsernamePrefix(String username) {
        return username.substring(0, username.indexOf('@'));
    } // getUsernamePrefix
    
    // Look to see if this user has already transferred. Return the number of 
    //    user records returned. This will indicate how many "X"s will be used.
    public void searchExistingXfers(String username) {
        userTransfer.StrX__c = 'X';
        String searchUN = getUsernamePrefix(username) + 'X%';
        Integer nbrRecs = [Select count() from User where Username like :searchUN];
        while (userTransfer.StrX__c.length() <= nbrRecs) { //users.size()) {
            userTransfer.StrX__c += 'X';
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'searchUN='+searchUN+' nbrRecs='+nbrRecs+' userTransfer.StrX__c='+userTransfer.StrX__c));
    } // searchExistingXfers
    
    // Reset the counters in the transfer object to zero.
    public static void resetCounters(User_Transfer__c userTransfer) {
        userTransfer.Nbr_Events__c = 0;
        userTransfer.Nbr_Events_Failed__c = 0;
        userTransfer.Nbr_Tasks__c = 0;
        userTransfer.Nbr_Tasks_Failed__c = 0;
        userTransfer.Nbr_Opptys__c = 0;
        userTransfer.Nbr_Opptys_Failed__c = 0;
        userTransfer.Nbr_Cases__c = 0;
        userTransfer.Nbr_Cases_Failed__c = 0;
    } // reset counters
    
    /** Get the transfer queries needed for Sales or Operations.
For Sales, this is all closed Opportunities, and Tasks and Events with 
Activity Date before the Effective Date.
For Operations, this is all open Cases, Tasks, and Events.
*/
    private String[] getActivityQueries(Id curOwnerId, Date effectiveDate) {
        String[] queries = new String[]{};
            if (isExistingSales) {
                queries.add(ManageUserHelper.getClosedObjectQuery(curOwnerId,'Task',true, NULL, NULL));
                queries.add(ManageUserHelper.getClosedObjectQuery(curOwnerId,'Opportunity',true, NULL, NULL));
                queries.add(ManageUserHelper.getClosedObjectQuery(curOwnerId,'Opportunity',false, effectiveDate, NULL));
                queries.add(ManageUserHelper.getEventsQuery(curOwnerId, effectiveDate, true));
            } else {
                queries.add(ManageUserHelper.getClosedObjectQuery(curOwnerId,'Task',false, NULL, NULL));
                queries.add(ManageUserHelper.getClosedObjectQuery(curOwnerId,'Case',false, NULL, NULL));
                queries.add(ManageUserHelper.getEventsQuery(curOwnerId, effectiveDate, false));
            }
        return queries;
    } // getActivityQueries
    
    // Check if there is any activity to transfer.
    private Boolean checkForActivity(Id curOwnerId, Date effectiveDate, Boolean isOpen, String transferType) {
        Boolean hasActivity = false;
        Map<String,String> activityQueryMap = ManageUserHelper.getActivityQueryMap(curOwnerId, effectiveDate, isOpen, isExistingSales, transferType);
        for (String query : activityQueryMap.values()) {
            if (doesQueryReturnData(query)) {
                hasActivity = true;
                break;
            }
        } // for
        return hasActivity;
    } // checkForActivity
    
    
    // Check if the passed in query has any results. Will just try to select one record.
    private Boolean doesQueryReturnData(String query) {
        query += ' limit 1 ';
        List<SObject> objects = Database.query(query);
        return (objects.size() > 0);
    } // doesQueryReturnData
    
    // Does the user have any groups. 
    public Boolean hasGroups{
        get{ return (gms != null && gms.size() > 0); }
    } // hasGroups
    
    public GroupMember[] gms {get;private set;}
    
    public PageReference processGroup() {
        // find groups the user is part of (if any);
        System.debug('userId='+userTransfer.Existing_User__c);
        selectGroups(userTransfer.Existing_User__c);
        return doMaintainGroup();
    } // processGroup
    
    public GroupMember grpMember{get;set;}
    
    /** Select the groups the user is in.
*/
    private void selectGroups(Id userId) {
        gms = [select Id
               ,GroupId
               ,SystemModStamp
               ,Group.Name
               // ,Group.Type
               from GroupMember
               where UserOrGroupId = :userId];
    } // selectGroups
    
    public String groupName{get;set;}
    
    public PageReference addToGroup() {
        // search for the group
        UserHelper uh = new UserHelper();
        Group grp = uh.getGroup(groupName);
        if (grp != null) {
            // make sure not already member of the group
            for (GroupMember gm : gms) {
                if (gm.GroupId == grp.Id) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, existingUser.Name+' is already a member of '+groupName+'!'));
                    grp = null;
                    break;
                }
            } // for
        } else {
            // no group is returned - return an error 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Group with the name '+groupName+' could not be found!'));
        } // if
        if (grp != null) {
            // if a value is returned add the user
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'GroupId='+grp.Id+' UserOrGroupId='+userTransfer.Existing_User__c));
            System.debug('GroupId='+grp.Id+' UserOrGroupId='+userTransfer.Existing_User__c);
            GroupMember gm = new GroupMember(GroupId=grp.Id,UserOrGroupId=userTransfer.Existing_User__c);
            insert gm;
            selectGroups(userTransfer.Existing_User__c);
        }
        groupName = null;
        return null;
    } // addToGroup
    
    public PageReference handleRecordAction() {
        String actionType = System.currentPageReference().getParameters().get('actionType');
        String recId = System.currentPageReference().getParameters().get('recId');
        // find the record
        if (actionType != null && actionType=='Remove' && recId != null) {
            for (GroupMember gm : gms) {
                if (gm.Id == recId) {
                    delete gm;
                    break;
                }
            }
            selectGroups(userTransfer.Existing_User__c);
        } // if
        return null;
    } // handleRecordAction
    
    public PageReference ManageLicenses(){
        List<string> selectedPackageNames = new list<string>();
        Map<String,LicenseWrapper> packageNameMap = new Map<String,LicenseWrapper>();
        List<string> packageId = new list<string>();
        system.debug('ManageUserController ManageLicenses licenseWrapList '+licenseWrapList);
        //loop through selected rows in table, build map of package prefix -> custom setting name(Label of package)
        for (LicenseWrapper licenseWrapper : licenseWrapList) {
            system.debug('ManageUserController ManageLicenses licenseWrapper.selectedval '+licenseWrapper.selectedval);
            if (licenseWrapper.selectedval == true) {
                system.debug('ManageLicenses licenseWrapper.csettingName '+licenseWrapper.csettingName);
                packageNameMap.put(licenseWrapper.namePrefix,licenseWrapper);
                selectedPackageNames.add(licenseWrapper.csettingName);
                if(licenseWrapper.namePrefix=='cafsl'){
                    licenseWrapper.cpqLicense=true;  
                    if(licenseWrapper.cpqUserType==null){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must select a CPQ User Type to proceed!'));
                        return null;
                    }
                    else{   
                        SYSTEM.DEBUG(' CP TYPE' + licenseWrapper.cpqUserType);    
                        // licenseWrapper.cpqUserTypeList = new List<String>(); 
                        // licenseWrapper.cpqUserTypeList.addall(licenseWrapper.cpqUserType.split(','));   
                    }
                }       
            }
        }
        if(!packageNameMap.isEmpty()){
            //try to get existing licenses for this user that they're currently requesting
            List<UserPackageLicense> existingLicenses = [SELECT id, PackageLicenseId,UserId,PackageLicense.NamespacePrefix 
                                                         from UserPackageLicense WHERE PackageLicense.NamespacePrefix IN : packageNameMap.keySet() 
                                                         AND UserId = : existingUser.Id];
            system.debug('ManageUserController ManageLicenses existingLicenses'+existingLicenses );
            
            //get pending requests for user to make sure we're not creating duplicate submissions
            List<Manage_Package_License__c> existingRequests = [SELECT Id, User_Name__c, Package_Name__c,Effective_Date__c,CPQ_User_type__c  
                                                                FROM Manage_Package_License__c WHERE User_Name__c = :existingUser.Id 
                                                                AND Package_Name__c IN : selectedPackageNames
                                                                AND Request_Status__c = 'Submitted for Approval'];
            
            //User already has licenses                                          
            if(existingLicenses != null && !existingLicenses.isEmpty() && userTransfer.Manage_Type__c == OPTION_PKG_LICENSE){
                String existingLicenseNameString = '';
                for(UserPackageLicense existingLicense : existingLicenses){
                    existingLicenseNameString+=packageNameMap.get(existingLicense.PackageLicense.NamespacePrefix).csettingname+', ';
                }
                existingLicenseNameString = existingLicenseNameString.removeEnd(', ');
                system.debug('ManageUserController ManageLicenses existingLicenseNameString '+existingLicenseNameString );
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This user already has access to '+existingLicenseNameString));
                return null;
            }//if(existingLicenses != null
            else if(existingRequests!=null && !existingRequests.isEmpty()){
                String existingRequestNameString = '';
                for(Manage_Package_License__c existingRequest : existingRequests){
                    existingRequestNameString+=existingRequest.Package_Name__c+', ';
                }
                existingRequestNameString = existingRequestNameString.removeEnd(', ');
                system.debug('ManageUserController ManageLicenses existingRequestNameString '+existingRequestNameString );
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This user already has a pending request for '+existingRequestNameString));
                return null;
            }
            //successful submission    
            else{
                Manage_Package_License__c[] newLicenseRequests = new Manage_Package_License__c[]{};
                    UserHelper uh = new UserHelper(); 
                String whereClause = 'where cafsl__User__c = \''+existingUser.Id+'\' ';    
                List<cafsl__Oracle_User__c> allUserMatchesWithCPQUser = uh.getCPQUsers(whereClause);
                
                for(LicenseWrapper selectedLicenseWrapper : packageNameMap.values()){
                    Manage_Package_License__c addLicense = new Manage_Package_License__c();
                    
                    addLicense.User_Name__c = existingUser.Id;
                    addLicense.Request_Status__c = 'Submitted for Approval';
                    addLicense.Requestor__c = requestor;
                    
                    addLicense.Package_Name__c = selectedLicenseWrapper.csettingname;
                    addLicense.Requested_Date__c = System.NOW();
                    addLicense.OwnerId = selectedLicenseWrapper.owner;
                    addLicense.CPQ_User_type__c = selectedLicenseWrapper.cpqUserType;
                    addLicense.CPQ_User_type__c = String.join(new List<String>(selectedLicenseWrapper.cpqUserTypeList), ';');  
                    if (userTransfer.Manage_Type__c == OPTION_PKG_LICENSE) {   
                        addLicense.Request_Type__c     = 'Add Package';   
                    }  
                    else if (userTransfer.Manage_Type__c == OPTION_PKG_LICENSE_ChangeGroup) {  
                        addLicense.Request_Type__c     = 'Manage Groups';       
                        addLicense.Oracle_User__c = allUserMatchesWithCPQUser[0].Id;              
                    }
                    newLicenseRequests.add(addLicense);
                }
                system.debug('ManageUserController ManageLicenses newLicenseRequests '+newLicenseRequests );
                if(!newLicenseRequests.isEmpty()){
                    insert newLicenseRequests;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Request for '+string.join(selectedPackageNames,', ')+ ' has been submitted'));
                }
                return null;
            }//successfull submit 
        }//packageNameMap not empty
        else{
            system.debug('ManageUserController ManageLicenses packageNameMap is empty - no package selected ');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a package before continuing'));
            return null;
        }//packageNameMap empty
        
        //return doMaintainLicenses();
    }
    
    //saketh
    public class LicenseWrapper{
        public String  indxvalue{get; set; }
        public string csettingname{get;set;}
        public string namePrefix{get;set;}
        public boolean selectedval{get;set;}
        public boolean cpqLicense{get;set;} 
        public string cpqUserType{get;set;}
        public set<String> cpqUserTypeList {get;set;} 
        public Id owner{get;set;}
    }
    
} // class ManageUserController