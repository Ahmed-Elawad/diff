/* 
 * The test methods for the ManageUserController.
 *
 * History
 * -------
 * 10/29/2010 Dan Carmen   Created
   08/10/2011 Dan Carmen   Fix test that's failing - mixed DML Operation
   11/21/2011 Dan Carmen   Add in logic to maintain queues
   07/15/2012 Justin Stouffer Add in logic to restrict Add New Users to System Administrator profile
   11/08/2013 Cindy Freeman  Fix timezone renamed issue
   06/02/2015 Dan Carmen   Added tests for UserTransferBatch
   01/04/2016 Dan Carmen   Changes to allow AddUserController to call group/permission set methods
   04/04/2017 Dan Carmen   Add Leave of Absense option to the menu
   03/12/2018 Carrie Marciano Added criteria to not use Chatter Free Users as test data
   05/08/2018 Dan Carmen    Additional criteria for non-chatter users
   11/28/2018 Jake Hinds    Adding license request test
   08/25/2020 Carrie Marciano Oracle CPQ license functionality tests
   10/11/2022 Dan Carmen      Change copyFromMirrorUser to use CopyFromMirrorFlds fieldSet for the fields to copy 
   06/27/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu) 
   04/26/2024 Dan Carmen      Don't show Apex message in queueable

*/
@isTest
private class ManageUserControllerTest {

   // Test the default entry into the controller.
   static testMethod void testDefaultEntry() {
      ManageUserController muc = new ManageUserController();
      verifySteps(muc,true,false,false,false);
      // test different steps
      System.assertEquals('/apex/manageusers',muc.doStep1().getURL());
      verifySteps(muc,true,false,false,false);
      muc.finished();


      System.assertEquals('/apex/manageusers',muc.doStep2().getURL());
      verifySteps(muc,false,true,false,false);

      System.assertEquals('/apex/manageusers',muc.doMaintainGroup().getURL());
      verifySteps(muc,false,false,true,false);

    //  System.assertEquals('/apex/manageusers',muc.cancel().getURL());
      verifySteps(muc,true,false,false,false);

      System.assertEquals(null,muc.existingUserName);
      //System.assertEquals(false,muc.selectUserDest);
      //System.assertEquals(false,muc.getAddtlInfo);
      System.assertEquals('X',muc.userTransfer.StrX__c);
      
      // check the options
      List<SelectOption> options = muc.manageOptions;
      System.assertEquals(8,options.size());
      //System.assertEquals(options[0].getValue(),'New');
      //System.assertEquals(options[0].getLabel(),'Create a New User');

      //System.assertEquals(options[1].getValue(),'TxferEnd');
      //System.assertEquals(options[1].getLabel(),'Transfer or End an Existing User');

      //System.assertEquals(options[2].getValue(),'Queue');
      //System.assertEquals(options[2].getLabel(),'Add/Remove User From Queue/Group');

      //System.assertEquals(options[3].getValue(),'Reactivate');
      //System.assertEquals(options[3].getLabel(),'Reactivate an Inactive User');
      
      muc.finished();
      
   } // testDefaultEntry

   static testMethod void testUserProfile() {  
      Profile stdUsrProfile = [select id from profile where name='Standard User']; 
      Profile sysAdmnProfile = [select id from profile where name='System Administrator']; 
      User su = new User(alias = 'stdUser9', email='stdUser9999@stdUser9999.com',   
         emailencodingkey='UTF-8', lastname='sUsr9999', languagelocalekey='en_US',   
         localesidkey='en_US', profileid = stdUsrProfile.Id,   
         timezonesidkey='America/Indiana/Indianapolis', username='stdUser9999@stdUser9999.com'
         ,Sales_Org__c='PAY');
      User sa = new User(alias = 'sysAdmn9', email='sysAdmin9999@sysAdmin9999.com',   
         emailencodingkey='UTF-8', lastname='sysAdmin9999', languagelocalekey='en_US',   
         localesidkey='en_US', profileid = sysAdmnProfile.Id,   
         timezonesidkey='America/Indiana/Indianapolis', username='sysAdmin9999@sysAdmin9999.com'
         ,Sales_Org__c='PAY');  
    
    
      System.runAs(su) {  //Runs as Standard User
         ManageUserController muc = new ManageUserController();  
         List<SelectOption> options = muc.manageOptions;
        // System.assertEquals(8,options.size());

         //System.assertEquals(options[0].getValue(),'TxferEnd');
         //System.assertEquals(options[0].getLabel(),'Transfer or End an Existing User');

         //System.assertEquals(options[1].getValue(),'Queue');
         //System.assertEquals(options[1].getLabel(),'Add/Remove User From Queue/Group'); 
        } 
        
      System.runAs(sa) {  //Runs as System Administrator
         ManageUserController muc = new ManageUserController();  
         List<SelectOption> options = muc.manageOptions;
         System.assertEquals(8,options.size());
        // System.assertEquals(options[0].getValue(),'New');
         //System.assertEquals(options[0].getLabel(),'Create a New User');
    
       // System.assertEquals(options[1].getValue(),'TxferEnd');
        //System.assertEquals(options[1].getLabel(),'Transfer or End an Existing User');
    
       // System.assertEquals(options[2].getValue(),'Queue');
       // System.assertEquals(options[2].getLabel(),'Add/Remove User From Queue/Group');
        } 
   } // testUserProfile

   private static void verifySteps(ManageUserController muc, Boolean s1, Boolean s2, Boolean q1, Boolean showFinished) {
      //System.assertEquals(s1,muc.step1);
      System.assertEquals(s2,muc.step2);
     // System.assertEquals(q1,muc.maintainGroup);
      System.assertEquals(showFinished,muc.showFinishedBlock);
   } // verifySteps

   // Test the result when the New User selection is made.
   static testMethod void testSelectNewUser() {
      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_NEW;      
      System.assertEquals('/apex/adduser',muc.selectManageType().getURL());
   } // testSelectNewUser

   // Test the result when the Queue selection is made.
   static testMethod void testSelectQueue() {
      // create a test queue
      Group queue = new Group(Name='ManageUserControllerTest Queue 1',Type='Queue');
      insert queue;

      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_QUEUE;      
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      // this will be a failure because name was not selected
      System.assertEquals(true,ApexPages.hasMessages());
      // should still be on first page
      verifySteps(muc,true,false,false,false);
      
      // find a user with no group
      User u = [SELECT Id, Name FROM User u WHERE IsActive=true AND Id != :UserInfo.getUserId()
                                              AND UserRoleId != null
                                              AND Profile.Name !='Chatter Free User' AND Id NOT IN (SELECT UserOrGroupId FROM GroupMember)
                                            limit 1];
      muc.userTransfer.Existing_User__c = u.Id;
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      // should return false because no groups
      System.assertEquals(false,muc.hasGroups);

      // add to group - first use a bad name
      muc.groupName = 'This is a bad queue name';
      System.assertEquals(null,muc.addToGroup());
      // use our test group name
      muc.groupName = queue.Name;
      System.assertEquals(null,muc.addToGroup());
      // should now have groups
      System.assertEquals(true,muc.hasGroups);
      // verify only one
      System.assertEquals(1,muc.gms.size());
      
      // try to add the same name again
      muc.groupName = queue.Name;
      System.assertEquals(null,muc.addToGroup());
      // should now have groups
      System.assertEquals(true,muc.hasGroups);
      // verify still only one
      System.assertEquals(1,muc.gms.size());

      GroupMember gm = muc.gms.get(0);
      
      // remove the User from the Group
      System.CurrentPageReference().getParameters().put('actionType','Remove');
      System.CurrentPageReference().getParameters().put('recId',gm.Id);
      System.assertEquals(null,muc.handleRecordAction());
      // should return false because no groups
      System.assertEquals(false,muc.hasGroups);
      

      // return to the main page
      // System.assertEquals('/apex/manageusers',muc.cancel().getURL());
      verifySteps(muc,true,false,false,false);
      
      // find a user with a group
      u = [SELECT Id, Name FROM User u WHERE IsActive=true AND Id != :UserInfo.getUserId()
                                              AND UserRoleId != null
                                              AND Id IN (SELECT UserOrGroupId FROM GroupMember)
                                            limit 1];
      
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_QUEUE;      
      muc.userTransfer.Existing_User__c = u.Id;
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      // should return true because has groups
      System.assertEquals(true,muc.hasGroups);

   } // testSelectQueue

   private static void createTasks(Integer numRecs, User u, Date taskDate, Boolean isClosed) {
      Task[] tasks = new Task[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         tasks.add(new Task(OwnerId=u.Id,Subject='ManagerUserControllerTest Task '+cnt,ActivityDate=taskDate,Status=(isClosed ? 'Completed' : 'Not Started')));
      }
      insert tasks;
   } // createTasks
   
   private static void createEvents(Integer numRecs, User u, DateTime eventDateTime) {
      Event[] events = new Event[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         events.add(new Event(OwnerId=u.Id,Subject='ManagerUserControllerTest Event '+cnt,ActivityDateTime=eventDateTime,ActivityDate=eventDateTime.date(),DurationInMinutes=60));
      }
      insert events;
   } // createEvents
   
   private static void createOpportunities(Integer numRecs, User u, Date dt, Boolean isClosed) {
      Opportunity[] opptys = new Opportunity[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         opptys.add(new Opportunity(OwnerId=u.Id,Name='ManagerUserControllerTest Event '+cnt,CloseDate=dt,StageName='Pending',Probability =65));
      }
      insert opptys;
   } // createOpportunities
   
   private static void createCases(Integer numRecs, User u, Date dt, Boolean isClosed) {
      Case[] cases = new Case[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         cases.add(new Case(OwnerId=u.Id,Subject='ManagerUserControllerTest Event '+cnt));
      }
      insert cases;
   } // createCases   
   
   // Get a Sales User
   private static User getSalesUser() {
      return [Select Id, Name, Sales_Org__c, UserRole.Name, UserRole.Id, Profile.Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
   } // getSalesUser

   // Get an operations User.
   private static User getOpsUser() {
      return [Select Id, Name, Sales_Org__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
   } // getOpsUser
   
   // Setup a Sales User. Assign tasks, events, and opportunities. For a Sales User being transferred within Sales, 
   //  all activity before the transfer date will be transferred to the newly created user record.
   private static User setupSalesUser(DateTime transferDate) {
      User u = getSalesUser();
      // create tasks
      createTasks(5, u, transferDate.addDays(-7).date(), true);
      // create events
      createEvents(5, u, transferDate.addDays(-7));
      // create opportunities
      createOpportunities(5, u, transferDate.addDays(-7).date(), true);
      return u;
   } // setupSalesUser
   
   // Setup a non-sales user. Assign tasks, events, and cases.
   private static User setupOpsUser(DateTime transferDate) {
      User u = getOpsUser();
      // create tasks
      // create events
      // create cases
      return u;
   } // setupOpsUser

   // Test the result when transferring within Sales.
   static testMethod void testSalesToSalesXfer() {
    UserHelperTest.setupSalesOrgSetting();
    
      User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
      DateTime testDate = DateTime.now();
      User u = setupSalesUser(testDate);
      User badMirrorUser = [Select Id, Name from User where IsActive=false and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User mirrorUser = [Select Id, Name from User where IsActive=true and Id != :u.Id and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      mirrorUser.Non_Paychex_Employee__c= false ; 
      badmirroruser.Non_Paychex_Employee__c = false; 
      u.Non_Paychex_Employee__c = false; 
      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER;    
      muc.userTransfer.Existing_User__c = u.Id;  
      muc.userTransfer.Effective_Date__c = null;
      date d = date.today(); 
      //muc.getTxferMsg(mirrorUser, true); 
      System.assertEquals(true,muc.step1);
      // this will fail because of no mirror user
      muc.selectManageType();
      System.assertEquals(true,muc.step1);
  
      muc.userTransfer.CopyUserFrom__c = mirrorUser.Id;
      // fail because of null date
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      System.assertEquals(true,muc.step1);
      // fail because of future date
      muc.userTransfer.Effective_Date__c = testDate.date().addDays(7);
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      System.assertEquals(true,muc.step1);
      // this one should succeed
      muc.userTransfer.Effective_Date__c = testDate.date();
      muc.userTransfer.CopyUserFrom__c = badMirrorUser.Id;
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      System.assertEquals(true,muc.step1);

      muc.userTransfer.CopyUserFrom__c = mirrorUser.Id;
      System.assertEquals('/apex/manageusers',muc.selectManageType().getURL());
      System.assertEquals(true,muc.step2);

      System.assertEquals(true,muc.isExistingSales);

      System.assertEquals(u.Id,muc.existingUser.Id);

      
      System.runAs(runUser) {
         //System.assertEquals('/apex/manageusers',muc.prepareToTransfer().getURL());
         muc.saveTransfer();
         muc.isTxfer = true; 
         muc.saveUsers();
      }
      
      //muc.finishProcessWithActivity();

      //System.runAs(runUser) {
      //    muc.finishProcessWithActivity();
         //System.assertEquals('/apex/manageusers',muc.finishProcess().getURL());
      //}
      //System.assertEquals(false,muc.userTransfer.New_User__r.IsActive);
      
      
   } // testSelectTxferEnd

   static testMethod void testMisc() {
      //ManageUserController muc = new ManageUserController();
      Account acct = new Account(Name='Test1');
      insert acct; 
      acct.Name=null;
      Database.SaveResult result = Database.update(acct,false);
      System.assertEquals(false,result.isSuccess());
      ManageUserHelper.ResultCount rc = new ManageUserHelper.ResultCount();

      ManageUserHelper.logUpdateError(acct,result,rc);
      System.assertEquals(1,rc.nbrFailure);
      System.assertEquals(0,rc.nbrSuccess);
      System.assertEquals(1,rc.nbrRecs);
      System.assertEquals(1,rc.errorMsgs.size());
      System.assertEquals(acct.Id,rc.errorMsgs[0].recordId);
      
      
      User_Transfer__c userTransfer = new User_Transfer__c();
      ManageUserController.resetCounters(userTransfer);
      ManageUserHelper.addToComments(userTransfer, 'These are test comments. I hope you enjoy!');
      insert userTransfer;
      
      ManageUserHelper.addToCounter(userTransfer, ObjectHelper.OBJECT_EVENT, rc);
      
      User[] users = [Select Id, Name from User where IsActive=true and UserRoleId != null limit 2];
      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Existing_User__c = users[0].Id;
      muc.userTransfer.CopyUserFrom__c = users[1].Id;
      muc.saveTransfer();      
      muc.cancel();
      string[] v  ; 
      Boolean x =  ManageUserController.checkGrpMembership(userTransfer, users[0], users[1], v);
      x =  ManageUserController.copyPermissionsSets(userTransfer, users[0], users[1], v);
     x =  ManageUserController.checkGrpMembership(userTransfer, users[0], users[1]);
      
   } // testMisc

   static testMethod void testEndUser() {
      UserHelperTest.setupSalesOrgSetting();
      User runningUser = UserHelper.getRunningUser();
     
      User testUser = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      
      System.runAs(runningUser) {
         ManageUserController muc = new ManageUserController();
         muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_END;    
         muc.userTransfer.Existing_User__c = testUser.Id;  
         muc.userTransfer.Effective_Date__c = Date.today();
         muc.selectManageType();
         // muc.prepareToTransfer();
      }
   } // testEndUser

   static testMethod void testXferActivity() {
      ManageUserHelper.USE_QUEUEABLE = false;
      User salesUser = setupSalesUser(Date.today());
      createEvents(5, salesUser, DateTime.now().addDays(7));
      
      User xferToUserInactive = [Select Id, Name from User where IsActive=false and Job_Name__c=:UserHelper.JOB_REP and Id != :salesUser.Id limit 1];
      User xferToUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id != :salesUser.Id and Id != :xferToUserInactive.Id limit 1];

      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER_ACTIVITY;    
      muc.userTransfer.Existing_User__c = salesUser.Id;  
      muc.userTransfer.Effective_Date__c = Date.today();
      muc.selectManageType();
      System.assertEquals(true,muc.step2);
      System.debug('testXferActivity call1');
      // should error because no transfer to user selected
      muc.prepareToTransfer();
      // set inactive user
      muc.userTransfer.Activity_Xfer_To__c = xferToUserInactive.Id;
      System.debug('testXferActivity call2');
      muc.prepareToTransfer();

      ManageUserHelper.USE_QUEUEABLE = true;

      // set to active user
      muc.userTransfer.Activity_Xfer_To__c = xferToUser.Id;
      System.debug('testXferActivity call3');
      muc.prepareToTransfer();
      

   } // testXferActivity
   
   static testMethod void testManageLicenses() {
      User[] salesUsers = [Select Id, Name, Sales_Org__c from User where IsActive=true and Job_Name__c='Sales Representative' and Oracle_CPQ__c=False limit 2];
      User salesUser = salesUsers[0];
      User salesUser2 = salesUsers[1];
      User runningUser = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
      
      
      Installed_Package__mdt ipmdt = [Select id, DeveloperName, Name_Prefix__c, User_Permission_Set__c,User_Permission_Set_Group__c,Pilot_User_Value__c,Oracle_CPQ__c,Salesforce_License__c
                                                    From Installed_Package__mdt LIMIT 1];
      PackageLicense pl = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status 
                                                    FROM PackageLicense WHERE NamespacePrefix = :ipmdt.Name_Prefix__c];
      system.debug('testManageLicenses pl: '+pl.NamespacePrefix);
      UserPackageLicense upl = new UserPackageLicense();
      upl.UserId = salesUser2.Id;
      upl.PackageLicenseId = pl.Id;
      insert upl;
      
      Test.startTest();
      system.runAs(runningUser){ 
          
          ManageUserController muc = new ManageUserController();
          muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_PKG_LICENSE;    
          muc.userTransfer.Existing_User__c = salesUser.Id;  
          muc.userTransfer.Effective_Date__c = Date.today();
          muc.selectManageType();
          
         system.assert(muc.licenseWrapList.size() > 0);
          
          //should throw warning that they must select a package
          muc.ManageLicenses();
          boolean noPackage = false;
          List<Apexpages.Message> pMsgs = ApexPages.getMessages();
          system.debug('test pMsgs: '+pMsgs);
          for(Apexpages.Message msg:pMsgs){
            if (msg.getSummary().contains('Please select a package before continuing')) noPackage = true;
            system.debug('test noPackage: '+noPackage); 
          }
          system.assert(noPackage);
          ApexPages.getMessages().clear();
          
          system.assert(muc.licenseWrapList.size() > 0);
          for(Integer i = 0;i<muc.licenseWrapList.size();i++){
            if(muc.licenseWrapList[i].csettingname == ipmdt.DeveloperName){
                muc.licenseWrapList[i].selectedval = true;
                system.debug('muc.licenseWrapList[i].csettingname: '+muc.licenseWrapList[i].csettingname);
            }
          }
          
          //should be successful, create a license request record
          muc.ManageLicenses();
          Manage_Package_License__c mpl = [SELECT Id FROM Manage_Package_License__c WHERE User_Name__c = :salesUser.Id LIMIT 1];
          system.assert(mpl!=null);
          
          //should throw error now that one is already submitted
          muc.ManageLicenses();
          boolean pendingRequest = false;
          List<Apexpages.Message> rMsgs = ApexPages.getMessages();
          system.debug('test msgs: '+rMsgs);
          for(Apexpages.Message msg:rMsgs){
            if (msg.getSummary().contains('This user already has a pending request for')) pendingRequest = true;
            system.debug('test pendingRequest: '+pendingRequest);  
          }
          system.assert(pendingRequest);
          ApexPages.getMessages().clear();
          
          //change to user 2
          muc.userTransfer.Existing_User__c = salesUser2.Id;  
          muc.selectManageType();
          
          system.assert(muc.licenseWrapList.size() > 0);
          for(Integer i = 0;i<muc.licenseWrapList.size();i++){
            if(muc.licenseWrapList[i].csettingname == ipmdt.DeveloperName){
                muc.licenseWrapList[i].selectedval = true;
            }
          }
          muc.ManageLicenses();
          List<Apexpages.Message> msgs = ApexPages.getMessages();
          msgs = ApexPages.getMessages();
          boolean licenseExist = false;
          for(Apexpages.Message msg:msgs){
            if (msg.getSummary().contains('This user already has access to')) licenseExist = true;
          }
          system.assert(licenseExist);
      }
      
      Test.stopTest();

   } // testManageLicenses
    
   static testMethod void testSalesToSalesXfer2() {
      User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
      Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
      
      User mirrorUser = [SELECT ID FROM User WHERE IsActive = true and Sales_Org__c= 'PAY' LIMIT 1];
      System.runAs(runUser){
      //PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'InsideSales_com_Access_User_Permissions' Limit 1];
      PermissionSetGroup pg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName='Oracle_CPQ_Admin' Limit 1];
      
      //insert new PermissionSetAssignment(AssigneeId = mirrorUser.id, PermissionSetId = ps.Id);
      insert new PermissionSetAssignment(AssigneeId = mirrorUser.id, PermissionSetGroupId = pg.Id);
     }
      DateTime testDate = DateTime.now();
      User u = setupSalesUser(testDate);
      UserHelperTest.setupSalesOrgSetting();
           
      System.runAs(runUser){
      ManageUserController muc = new ManageUserController();
      muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER;    
      muc.userTransfer.Existing_User__c = u.Id;  
      muc.userTransfer.Effective_Date__c = System.Today();
      muc.userTransfer.CopyUserFrom__c = mirrorUser.Id;
      muc.selectManageType();
      ManageUserController.CHECK_GRP_MEMBERSHIP = true;
      muc.createTxferUser(); 
      // muc.prepareToTransfer();
      }     
    } // testSalesToSalesXfer2
    
    // Transfer Type = Update Role Only
    static testMethod void testUpdateRoleOnly(){
        SalesOrg__c[] salesOrgs = UserHelperTest.setupSalesOrgSetting();
        User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
        DateTime testDate = DateTime.now();
        User u = setupSalesUser(testDate);  // core sales org
        User mirrorUser = [Select Id, Name, Profile.Name, UserRole.Name, UserRole.Id, Sales_Org__c from User where IsActive=true and Id != :u.Id and Sales_Org__c=:UserHelper.SO_CORE and UserRole.Id != :u.UserRole.Id limit 1];        
        mirrorUser.Non_Paychex_Employee__c= false ;
        
        ManageUserController muc = new ManageUserController();
        muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER; 
        muc.userTransfer.Existing_User__c = u.Id;  
        muc.userTransfer.Effective_Date__c = testDate.date(); 
        muc.userTransfer.CopyUserFrom__c = mirrorUser.Id;
        muc.selectManageType();   
        muc.userTransfer.Transfer_Type__c = 'Update User Role Only';
        muc.userTransfer.Status__c='Complete';
        
        System.runAs(runUser) {
            muc.saveTransfer();
            muc.newUser = null;
            muc.updateExistingUserRole();
            UserHelper.ALLOW_ROLE_CALLOUT = false;
            UserTriggerMethods.skipInactiveQueueable = true; 
            ManageUserController.DISPLAY_VF_MSG = false;
            muc.saveUsers();
        }            
        // user should now exist
        User uUpdated = [Select Id, Name, Email, Profile.Name, UserRole.Name, Sales_Org__c 
                                      from User
                                     where IsActive=true and Id=:u.Id]; 
        System.assertEquals(mirrorUser.Profile.Name, uUpdated.Profile.Name);    
        System.assertEquals(mirrorUser.UserRole.Name, uUpdated.UserRole.Name); 
                
    } // testUpdateRoleOnly
    
    // Transfer Type = Open Activity Only
    // Transfer Type = Open Oppties Only
    // Transfer Type = Move Open Activity and Open Opportunities
    /* static testMethod void testTransferAndAllOpen(){   	
        User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
        System.runAs(runUser){
        	SalesOrg__c[] salesOrgs = UserHelperTest.setupSalesOrgSetting();    
        }
        DateTime testDate = DateTime.now();
        User u = setupSalesUser(testDate);  // core sales org
        User salesUser = [Select Id, Name, Profile.Name, UserRole.Name, UserRole.Id, Sales_Org__c from User where IsActive=true and Id != :u.Id and Sales_Org__c=:UserHelper.SO_MMS and UserRole.Id != :u.UserRole.Id and Job_Name__c = 'Sales Representative' limit 1];        
    	UserHelper uHelper = new UserHelper();
        ManageUserController muc = new ManageUserController();
        muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER; 
        muc.userTransfer.Existing_User__c = u.Id;  
        muc.userTransfer.Effective_Date__c = testDate.date(); 
        muc.userTransfer.CopyUserFrom__c = salesUser.Id;  
        muc.selectManageType();   
        muc.userTransfer.Transfer_Type__c = 'Move Open Activity and Open Opportunities';
        
        system.assertEquals(True, muc.userTransfer.HasOpenActivity__c);
        system.assertEquals(True, muc.userTransfer.HasClosedActivity__c);
         
        muc.isTxfer = True;
        muc.existingUser = uHelper.getUserById(u.Id);
        muc.userToMirror = uHelper.getUserById(salesUser.Id);
        muc.saveTransfer();            
        muc.createTxferUser();
        UserHelper.ALLOW_ROLE_CALLOUT = false;
        UserTriggerMethods.skipInactiveQueueable = true; 
        ManageUserController.DISPLAY_VF_MSG = false;
        muc.nonSurvivingUser.IsActive = false;
        muc.isTxfer = True;
        muc.saveUsers();
                        
        // user should now exist
        User uUpdated = [Select Id, Name, Email, Profile.Name, UserRole.Name, Sales_Org__c, isActive 
                                      from User
                                     where Id=:u.Id]; 
        System.assertEquals(False, uUpdated.isActive);  
        User uNew = [Select Id, Name, Email, Profile.Name, UserRole.Name, Sales_Org__c, isActive 
                                      from User
                                     where Id=:muc.newUser.Id]; 
        System.assertEquals(True, uNew.isActive); 
    
        muc.userTransfer.Status__c='Pending Activity Transfer';
        muc.saveTransfer();
        
    } // testTransferAndAllOpen
    */
    // Transfer with Role, Profile, Sales Org no user to mirror
    // Transfer Type = User Transfer Basic
    static testMethod void testNoUserToMirror(){
        UserHelper uHelper = new UserHelper();
        SalesOrg__c[] salesOrgs = UserHelperTest.setupSalesOrgSetting();
        User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
        DateTime testDate = DateTime.now();
        User u = setupSalesUser(testDate);  // core sales org     
        User salesUser = [Select Id, Name, Profile.Name, UserRole.Name, UserRole.Id, Sales_Org__c from User where IsActive=true and Id != :u.Id and Sales_Org__c=:UserHelper.SO_MMS and UserRole.Id != :u.UserRole.Id and Job_Name__c = 'Sales Representative' limit 1];         
        ManageUserController muc = new ManageUserController();
        muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER; 
        muc.userTransfer.Existing_User__c = u.Id;  
        muc.userTransfer.Effective_Date__c = testDate.date(); 
        muc.userTransfer.CopyUserFrom__c = null;
        muc.userTransfer.Profile__c = salesUser.Profile.Name;
        muc.userTransfer.Role__c = salesUser.UserRole.Name;
        muc.userTransfer.Sales_Org__c = salesUser.Sales_Org__c;
        muc.selectManageType();
        system.debug('muc.userTransfer.New_User__c: '+muc.userTransfer.New_User__c);
        muc.userTransfer.Transfer_Type__c = 'Transfer User Basic';
        muc.userTransfer.Status__c = 'Complete';
        muc.createTxferUser();

        System.assertEquals(muc.userTransfer.Profile__c, salesUser.Profile.Name);
        System.assertEquals(muc.userTransfer.Role__c, salesUser.UserRole.Name);
    } // testNoUserToMirror 
    
    // Transfer with Role, Profile, Sales Org no user to mirror
    // Transfer Type = User Transfer Basic
    static testMethod void testBadRoleProfile(){
        UserHelper uHelper = new UserHelper();
        SalesOrg__c[] salesOrgs = UserHelperTest.setupSalesOrgSetting();
        User runUser = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
        DateTime testDate = DateTime.now();
        User u = setupSalesUser(testDate);  // core sales org
		User salesUser = [Select Id, Name, Profile.Name, UserRole.Name, UserRole.Id, Sales_Org__c from User where IsActive=true and Id != :u.Id and Sales_Org__c=:UserHelper.SO_MMS and UserRole.Id != :u.UserRole.Id and Job_Name__c = 'Sales Representative' limit 1];       
        ManageUserController muc = new ManageUserController();
        muc.userTransfer.Manage_Type__c = ManageUserController.OPTION_TXFER; 
        muc.userTransfer.Existing_User__c = u.Id;  
        muc.userTransfer.Effective_Date__c = testDate.date(); 
        muc.userTransfer.CopyUserFrom__c = null;
        // bad profile
        muc.userTransfer.Profile__c = 'Bad Profile';
        muc.userTransfer.Role__c = salesUser.UserRole.Name;
        muc.userTransfer.Sales_Org__c = salesUser.Sales_Org__c;
        muc.selectManageType();
        System.assert(ApexPages.getMessages().get(0).getDetail() == 'The Profile you entered is not correct.');
        Test.clearApexPageMessages();
        // fix profile, enter bad role
        muc.userTransfer.Profile__c = salesUser.Profile.Name;
        muc.userTransfer.Role__c = 'Bad Role';
        muc.selectManageType();
        System.assert(ApexPages.getMessages().get(0).getDetail() == 'The Role you entered is not correct.');
        Test.clearApexPageMessages();
        // fix role
        muc.userTransfer.Role__c = salesUser.UserRole.Name;
        muc.selectManageType();
        muc.userTransfer.Transfer_Type__c = 'Transfer User Basic';
        muc.userTransfer.Status__c = 'Complete';               
        muc.createTxferUser();
       
        System.assertEquals(muc.userTransfer.Profile__c, salesUser.Profile.Name);
        System.assertEquals(muc.userTransfer.Role__c, salesUser.UserRole.Name);
    } // testBadRoleProfile 
    
} // class ManageUserControllerTest