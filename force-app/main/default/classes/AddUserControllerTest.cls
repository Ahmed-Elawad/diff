/* Test methods for the AddUserController. 
   
  History
  -------
  06/20/2012 Dan Carmen   Created
  01/22/2013 Dan Carmen   Changes to allow Temporary Emps/Reactivations
  01/04/2016 Dan Carmen   Copy permission sets/group membership when adding a user.
  12/27/2017 Dan Carmen   Ability to create a new user if existing inactive one.
  02/04/2020 Dan Carmen   Change to without sharing to pass the test
  09/10/2020 Brandon Vidro  Change to nonSysAdmin query for APR0110504
  01/28/2022 Carrie Marciano Automation for reactivation to reactivate CPQ license
  03/06/2023 Carrie Marciano update API version  
  06/01/2023 Carrie Marciano FY24 Transfer User options  
  07/31/2023 Dan Carmen      add OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger() so that Oracle doesn't try to perform a callout in a test method
  01/05/2024 Dan Carmen      Changes to use users with New User Profile  
  04/26/2024 Dan Carmen      Slight cleanups

 */
@isTest
private class AddUserControllerTest {

   static testMethod void testCreatingUsers() {
      // create the Paychex Inc SA Account
      Account paychexIncSa = new Account(Name='Paychex Inc SA');
      insert paychexIncSa;

      // find an existing user
      User existingU = [Select Id, FirstName, LastName, Name, Email, Cost_Center__c, HR_Person_Id__c, PostalCode from User where IsActive=true and Profile.Name != 'System Administrator' and HR_Person_Id__c != null and Id != :UserInfo.getUserId() and PostalCode != null limit 1];
      
      // create Contacts
      Contact ctct1 = new Contact(FirstName='Test1', LastName='Testing', Email='Test1@aucpaychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990001', Paychex_Cost_Center__c='0017');
      Contact ctct2 = new Contact(FirstName='Test2', LastName='Testing', Email='Test2@aucpaychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990002', Paychex_Cost_Center__c='0017', MailingPostalCode=existingU.PostalCode);
      Contact ctct3 = new Contact(FirstName='Test3', LastName='Testing', Email='Test3@aucpaychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990003', Paychex_Cost_Center__c='0017');
      Contact ctct4 = new Contact(FirstName='Test4', LastName='Testing', Email='Test4@aucpaychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990004', Paychex_Cost_Center__c='0017');
      Contact ctctExisting = new Contact(FirstName=existingU.FirstName, LastName=existingU.LastName, Email=existingU.Email, AccountId=paychexIncSa.Id, HR_Person_Id__c=existingU.HR_Person_Id__c, Paychex_Cost_Center__c=existingU.Cost_Center__c);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctctExisting};
      insert ctcts;

      // select a non-system admin user
      User nonSysAdmin = [Select Id, Name, Email, Profile.Name from User where UserType = 'Standard' and Profile.Name LIKE 'CORE ZONE ADMINISTRATION%' and IsActive=true and Id != :existingU.Id limit 1];
      System.runAs(nonSysAdmin) {
         // submit records
         Test.setCurrentPage(Page.AddUser);
      
         AddUserController auc = new AddUserController();
         System.assertEquals(false,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         
         // verify the requestor email is set
         System.assertEquals(nonSysAdmin.Email,auc.newNur.Requestor_Email__c);
         
         // submit a new address
         auc.newNur.New_User_Email__c = ctct2.Email;
         auc.newNur.Request_Type__c = AddUserController.CHATTER_PROFILE;
         
         System.assertEquals(null,auc.submitRequest());
         // should now be two requests
         System.assertEquals(1,[Select count() from NewUserRequest__c]);
         
         // submit a new address
         auc.newNur.Requestor_Email__c = ctct3.Email;
         auc.newNur.NewUserTheSameAsRequestor__c = true;
         auc.newNur.Request_Type__c = AddUserController.CHATTER_PROFILE;
         auc.newNur.Copy_public_Groups_and_Queues__c = true; 
         auc.newNur.User_to_Mirror__c = existingU.id; 


         System.assertEquals(null,auc.submitRequest());
         // should now be three requests
         System.assertEquals(2,[Select count() from NewUserRequest__c]);
         
         auc.newNur.New_User_Email__c = ctctExisting.Email;
         auc.newNur.Request_Type__c = AddUserController.CHATTER_PROFILE;

         System.assertEquals(null,auc.submitRequest());
         // should now be four requests
         System.assertEquals(3,[Select count() from NewUserRequest__c]);
          
      } // System.runAs(nonSysAdmin
      
      // submit a batch request
      User sfdcData = [Select Id, Name, Email from User where Name='SFDC Data' and IsActive=true limit 1];
      System.runAs(sfdcData) {
         AddUserBatch aub = new AddUserBatch();
         Test.startTest();
         // should be only 4 running - but run for 8 to verify only 4 ran
         Database.executeBatch(aub,8);
         Test.stopTest();

      } // System.runAs(sfdcData
      
      // verify users are created
      // make sure all requests are marked as complete
      System.assertEquals(3,[Select count() from NewUserRequest__c where Request_Complete__c=true]);
      // verify request for existing user is marked as 'Failed'
      //System.assertEquals(1,[Select count() from NewUserRequest__c where Request_Complete__c=true and Status__c='Failed' and New_User_Email__c = :ctctExisting.Email and Notes__c like '%could not be created because an active Salesforce User record was found matching%']);
      // verify users were created
      System.assertEquals(0,[Select count() from User where IsActive=true and Email=:ctct1.Email and Profile.Name=:AddUserController.CHATTER_PROFILE]);
      System.assertEquals(1,[Select count() from User where IsActive=true and Email=:ctct2.Email and Profile.Name=:AddUserController.CHATTER_PROFILE]);
      System.assertEquals(1,[Select count() from User where IsActive=true and Email=:ctct3.Email and Profile.Name=:AddUserController.CHATTER_PROFILE]);
   } // testCreatingUsers
    
   static testMethod void testCreatingUsersRoleProfile() {
      // create the Paychex Inc SA Account
      Account paychexIncSa = new Account(Name='Paychex Inc SA');
      insert paychexIncSa;

      // find an existing user
      User existingU = [Select Id, FirstName, LastName, Name, Email, Cost_Center__c, HR_Person_Id__c, Job_Name__c, PostalCode, Sales_Org__c, UserRole.Name, Profile.Name, ProfileName__c from User where IsActive=true and Profile.Name != 'System Administrator' and HR_Person_Id__c != null and Job_Name__c = 'Sales Representative' and Id != :UserInfo.getUserId() and PostalCode != null limit 1];
      
      // create Contact
      Contact ctct2 = new Contact(FirstName='Test2', LastName='Testing', Email='Test2@aucpaychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990002', Paychex_Cost_Center__c='0017', MailingPostalCode=existingU.PostalCode);
      insert ctct2;

      // select a system admin user
      User sysAdminU = [Select Id, Name, Email, ProfileId, UserRoleId from User where IsActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' limit 1];
      System.runAs(sysAdminU) {
         // submit records
         Test.setCurrentPage(Page.AddUser);
      
         AddUserController auc = new AddUserController();
         System.assertEquals(true,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         
         // submit a new address
         auc.newNur.New_User_Email__c = ctct2.Email;
         
         System.assertEquals(null,auc.searchForEmployee());
         //System.assertEquals(true,(auc.foundContact == null));
         System.assertEquals(true,(auc.activeUser == null));
         System.assertEquals(true,(auc.inActiveUser == null));
         System.assertEquals(false,auc.matchingUserFound);
         
         // set the request type to be standard user
         auc.requestType = 'Y_Standard';
         System.assertEquals(null,auc.setRequestType());
         System.assertEquals(true,auc.canWeProceed);
         System.assertEquals('Standard User',auc.newNur.Request_Type__c);
         System.assertEquals(false,auc.newNur.Temporary_Employee__c);
         System.assertEquals(false,auc.newNur.UpgradeFromChatterFree__c);
         System.assertEquals(true,auc.promptForAdditionalInfo);
         System.assertEquals(true,auc.getMirrorUserInfo);
         
         // no user to mirror specify role, profile, sales org
         auc.newNur.User_to_Mirror__c = null;
         auc.newNur.Role__c = existingU.UserRole.Name;
         auc.newNur.Profile__c = existingU.Profile.Name;
         auc.newNur.Sales_Org__c = existingU.Sales_Org__c; 
         auc.newNur.Copy_public_Groups_and_Queues__c = true ; 
        
         // save the request
         System.assertEquals(null,auc.submitRequest());
         // verify open request exists
         NewUserRequest__c nur = [Select Id, New_User_Email__c,Request_Type__c from NewUserRequest__c where New_User_Email__c=:ctct2.Email and Request_Complete__c = false];
         
         // manage the new user request
         Test.setCurrentPage(Page.NewUserRequestManage);
         System.CurrentPageReference().getParameters().put('id',nur.Id);
         ApexPages.Standardcontroller sc = New ApexPages.StandardController(nur);
         auc = new AddUserController(sc);
         
         System.assertEquals(true,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         System.assertEquals(nur.Id,auc.newNur.Id);
         System.assertEquals(false,auc.requestCompleteOnEntry);
         
         // set to approve
         auc.approveOrReject = 'approve';
         System.assertEquals(null,auc.setApproveOrReject());
                 
         // save the user
         System.assertEquals(null,auc.saveUser());
         
         // user should now exist
         User user2 = [Select Id, Name, Email, Profile.Name, UserRole.Name, Sales_Org__c 
                                      from User
                                     where IsActive=true and Email=:ctct2.Email]; 
         System.assertEquals(auc.newNur.Profile__c, user2.Profile.Name);    
         System.assertEquals(auc.newNur.Role__c, user2.UserRole.Name); 
          
         // return to request
         PageReference retPr = auc.gotoRequest();
         System.assertEquals(true,retPr.getUrl().contains(nur.Id));
         // return to user
         retPr = auc.gotoUser();
         System.assertEquals(true,retPr.getUrl().contains(user2.Id));
      } // System.runAs(sysAdminU      
   } // testCreatingUsersRoleProfile 
   
   /** Create a user request for a chatter free user.
       Approve the request and create the user.
       Create a request for the same user, for a full licenes.
       Approve the request and upgrade the user.
    */
   static testMethod void testChatterFreeAsSystemAdmin() {
      // create the Paychex Inc SA Account
      Account paychexIncSa = new Account(Name='Paychex Inc SA');
      insert paychexIncSa;

      // find an existing user
      User existingU = [Select Id, FirstName, LastName, Name, Email, Cost_Center__c, HR_Person_Id__c from User where IsActive=true and Profile.Name != 'System Administrator' and HR_Person_Id__c != null and Id != :UserInfo.getUserId() and UserRoleId != null limit 1];
      
      // change SFDC Data Name so not selected - for test coverage.
      User sfdcData = [Select Id, Name, FirstName, LastName, Email, IsActive from User where Name='SFDC Data' and IsActive=true limit 1];
      sfdcData.FirstName='TestSfdc';
      sfdcData.LastName='TestData';
      update sfdcData;
      
      // create Contacts
      Contact ctct1 = new Contact(FirstName='Test1', LastName='Testing', Email='test1@paychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990001', Paychex_Cost_Center__c='0017', MailingPostalCode='14623');
      Contact ctct2 = new Contact(FirstName='Test2', LastName='Testing', Email='test2@paychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990002', Paychex_Cost_Center__c='0017');
      Contact ctct3 = new Contact(FirstName='Test3', LastName='Testing', Email='test3@paychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990003', Paychex_Cost_Center__c='0017');
      Contact ctct4 = new Contact(FirstName='Test4', LastName='Testing', Email='test4@paychextesting.com', AccountId=paychexIncSa.Id, HR_Person_Id__c='999990004', Paychex_Cost_Center__c='0017');
      Contact ctctExisting = new Contact(FirstName=existingU.FirstName, LastName=existingU.LastName, Email=existingU.Email, AccountId=paychexIncSa.Id, HR_Person_Id__c=existingU.HR_Person_Id__c, Paychex_Cost_Center__c=existingU.Cost_Center__c);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctctExisting};
      insert ctcts;
      
      // get a system admin user
      User sysAdminU = [Select Id, Name, Email, ProfileId, UserRoleId from User where IsActive=true and Id != :UserInfo.getUserId() and Profile.Name='System Administrator' limit 1];
      System.runAs(sysAdminU) {
         // submit records
         Test.setCurrentPage(Page.AddUser);
      
         AddUserController auc = new AddUserController();
         System.assertEquals(true,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         
         String testEmail = 'notcurrentuser@paychextesting.com';
         // submit a non employee email
         auc.newNur.New_User_Email__c = testEmail;
         //auc.newNur.Request_Type__c = AddUserController.CHATTER_PROFILE;
         
         System.assertEquals(null,auc.searchForEmployee());
         System.assertEquals(true,(auc.foundContact == null));
         System.assertEquals(true,(auc.activeUser == null));
         System.assertEquals(true,(auc.inActiveUser == null));
         System.assertEquals(false,auc.matchingUserFound);
         
         // should be 1 message - says a contact wasn't found
         System.assertEquals(1,ApexPages.getMessages().size());
         
         // set the request type to N so it doesn't proceed
         auc.requestType = 'N';
         System.assertEquals(null,auc.setRequestType());
         System.assertEquals(false,auc.canWeProceed);
         
         // set the request type to be a temp chatter free
         auc.requestType = 'Y_Temp_Chatter';
         System.assertEquals(null,auc.setRequestType());
         System.assertEquals(true,auc.canWeProceed);
         System.assertEquals(AddUserController.CHATTER_PROFILE,auc.newNur.Request_Type__c);
         System.assertEquals(true,auc.newNur.Temporary_Employee__c);
         System.assertEquals(false,auc.newNur.UpgradeFromChatterFree__c);
         System.assertEquals(false,auc.promptForAdditionalInfo);

         // verify the required fields - should return false
         System.assertEquals(false,auc.verifyRequiredFields(auc.newNur));
         // populate the name
         auc.newNur.FirstName__c='First';
         auc.newNur.LastName__c='Last';
         auc.newNur.Cost_Center__c = '0017';
         System.assertEquals(true,auc.verifyRequiredFields(auc.newNur));
         
         // add the chatter user
         System.assertEquals(null,auc.addNewUser());
         
         // user should now exist
         User newChatterFreeUser = [Select Id, Name, Email, Profile.Name 
                                      from User
                                     where IsActive=true and Email=:testEmail and Profile.Name=:AddUserController.CHATTER_PROFILE];

         // upgrade to a full license - start a new request
         auc = new AddUserController();
         System.assertEquals(true,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         
         // submit a non employee email
         auc.newNur.New_User_Email__c = testEmail;
         
         System.assertEquals(null,auc.searchForEmployee());
         System.assertEquals(true,(auc.foundContact == null));
         System.assertEquals(true,(auc.activeUser != null));
         System.assertEquals(true,(auc.inActiveUser == null));
         System.assertEquals(true,auc.matchingUserFound);
         
         // set the request type to be a temp chatter free
         auc.requestType = 'Y_Standard';
         System.assertEquals(null,auc.setRequestType());
         System.assertEquals(true,auc.canWeProceed);
         System.assertEquals('Standard User',auc.newNur.Request_Type__c);
         System.assertEquals(false,auc.newNur.Temporary_Employee__c);
         System.assertEquals(true,auc.newNur.UpgradeFromChatterFree__c);
         System.assertEquals(true,auc.promptForAdditionalInfo);
         System.assertEquals(true,auc.getMirrorUserInfo);
         
         // fill out user to mirror to satisfy required information.
         User userToMirror = [Select Id, Name, ProfileId, UserRoleId, License_Type__c from User where UserType != 'Guest' and Profile.Name != 'System Administrator' and IsActive=true limit 1];
         
         auc.newNur.User_to_Mirror__c = userToMirror.Id;
         auc.newNur.Copy_public_Groups_and_Queues__c = true ; 
         // save the request
         System.assertEquals(null,auc.submitRequest());
         // verify open request exists
         NewUserRequest__c nur = [Select Id, New_User_Email__c,Request_Type__c from NewUserRequest__c where New_User_Email__c=:testEmail and Request_Complete__c = false];
         
         // manage the new user request
         Test.setCurrentPage(Page.NewUserRequestManage);
         System.CurrentPageReference().getParameters().put('id',nur.Id);
         ApexPages.Standardcontroller sc = New ApexPages.StandardController(nur);
         auc = new AddUserController(sc);
         
         System.assertEquals(true,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         System.assertEquals(nur.Id,auc.newNur.Id);
         System.assertEquals(false,auc.requestCompleteOnEntry);
         
         // first reject it
         auc.approveOrReject = 'reject';
         System.assertEquals(null,auc.setApproveOrReject());
         
         // try to save the rejection - should fail because no reason entered
         System.assertEquals(null,auc.saveRejection());
         
         // set a reason
         auc.newNur.Approver_Notes__c = 'Because I felt like it';
         PageReference retPr = auc.saveRejection();
         System.assertEquals(true,retPr.getUrl().contains(nur.Id));
         
         // set to approve
         auc.approveOrReject = 'approve';
         System.assertEquals(null,auc.setApproveOrReject());
         
         // should just be able to save from here - additional info should come from the "User to Copy"
         // verify the new user created defaults to the userToMirror's role and profile
         System.assertEquals(userToMirror.ProfileId, auc.newNur.User__r.ProfileId);
         System.assertEquals(userToMirror.UserRoleId, auc.newNur.User__r.UserRoleId);
         // license type should default to the request type
         System.assertEquals(auc.newNur.User__r.License_Type__c, userToMirror.License_Type__c);
         
         // save the user
         System.assertEquals(null,auc.saveUser());
         // verify the user is now a full license type.
         System.assertEquals(1,[select count() from User where Id = :newChatterFreeUser.Id and UserType!='Guest']);
         
         // return to request
         retPr = auc.gotoRequest();
         System.assertEquals(true,retPr.getUrl().contains(nur.Id));
         // return to user
         retPr = auc.gotoUser();
         System.assertEquals(true,retPr.getUrl().contains(newChatterFreeUser.Id));
      } // System.runAs(sysAdminU
      
   } // testChatterFreeAsSystemAdmin
   
   // Test the scheduler for the batch process.
   static testMethod void testBatchScheduler() {
      AddUserBatch auBatch = new AddUserBatch();
      TestHelper.testScheduler('AddUserBatchTest', auBatch);
   } // testBatchScheduler
   
   // Create a user request for a chatter free user.
   //    Approve the request and create the user.
   //    Create a request for the same user, for a full licenes.
   //    Approve the request and upgrade the user.
   static testMethod void testMisc() {
    AddUserController auc = new AddUserController();
    User usr = new User();
    auc.setDefaultLocale(usr);
    auc.checkOrganization();
    Boolean showChatterFree = auc.showChatterFreeOption;
    
    PageReference pr = auc.gotoUserPage();
   } // testMisc

    static testMethod void testReactivatingUser() {
      OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger();
      // create the Paychex Inc SA Account
      Account paychexIncSa = new Account(Name='Paychex Inc SA');
      insert paychexIncSa;

      // find an existing Inactive user
      List<AggregateResult> uniqueEmail = [SELECT Count(ID), Email FROM User WHERE IsActive = False and Profile.Name != 'System Administrator' and HR_Person_Id__c != null and PostalCode != null GROUP BY Email HAVING Count(ID) = 1 ORDER BY Count(ID) DESC LIMIT 1];
      string uniqueEmailAddr = (String) uniqueEmail[0].get('Email');
      User existingUOracle = [Select Id, FirstName, LastName, Name, Email, Cost_Center__c, HR_Person_Id__c, PostalCode, Oracle_CPQ__c from User where Email= :uniqueEmailAddr];
        
      // create Contacts
      Contact ctctExistingOracle = new Contact(FirstName=existingUOracle.FirstName, LastName=existingUOracle.LastName, Email=existingUOracle.Email, AccountId=paychexIncSa.Id, HR_Person_Id__c=existingUOracle.HR_Person_Id__c, Paychex_Cost_Center__c=existingUOracle.Cost_Center__c, Date_of_Employee_Termination__c=null);
      insert ctctExistingOracle;
        
      cafsl__Embedded_CPQ_Settings__c embeddedCPQSetting = new cafsl__Embedded_CPQ_Settings__c();
      embeddedCPQSetting.Name = 'CPQ Test Class';
      embeddedCPQSetting.cafsl__Callout_URL__c = 'https://paychexinctest1.bigmachines.com/';
      embeddedCPQSetting.cafsl__Connected_App_Name__c = 'OracleCPQ';
      embeddedCPQSetting.cafsl__Copy_Action_Id__c = '56789123';
      embeddedCPQSetting.cafsl__Data_Set__c = 'paychexinctestclass';
      embeddedCPQSetting.cafsl__Document_Id__c = '23456789';
      embeddedCPQSetting.cafsl__Open_Action_Id__c = '34567891';
      embeddedCPQSetting.cafsl__Primary__c = True;
      embeddedCPQSetting.cafsl__Process_Id__c = '12345678';
      embeddedCPQSetting.cafsl__Process_Name__c  = 'paychexCommerceProcess';
      embeddedCPQSetting.cafsl__Embed_In_Lightning__c = True;    
      embeddedCPQSetting.cafsl__Use_Opportunity_Currency__c = True;
      embeddedCPQSetting.cafsl__Use_Opportunity_Pricebook__c = True;   
      embeddedCPQSetting.cafsl__Version_Id__c = '67891234';
      embeddedCPQSetting.cafsl__Version_Number__c = 2018.200;
      insert embeddedCPQSetting;
       
      cafsl__Oracle_User__c oUser = new cafsl__Oracle_User__c(cafsl__User__c=existingUOracle.Id,cafsl__allow_quote_creation__c=True,cafsl__Currency_Preference__c='USD',cafsl__Date_Time_Format__c='0',cafsl__Embedded_CPQ_Settings__c=embeddedCPQSetting.Id,
                                                              cafsl__Groups__c='salesUser',cafsl__Language_Preference__c='English',cafsl__Link_to_CPQ_User__c=True,cafsl__Number_Format__c='0',cafsl__Units__c='1',cafsl__User_Type__c='SALES_AGENT');
      insert oUser;
       
      // select a non-system admin user
      User nonSysAdmin = [Select Id, Name, Email, Profile.Name from User where UserType = 'Standard' and Profile.Name LIKE 'CORE ZONE ADMINISTRATION%' and IsActive=true and Id != :existingUOracle.Id limit 1];
      System.runAs(nonSysAdmin) {
         // submit records
         Test.setCurrentPage(Page.AddUser);
      
         AddUserController auc = new AddUserController();
         System.assertEquals(false,auc.isSystemAdmin);
         System.assertEquals(false,auc.isGuestUser);
         
         // verify the requestor email is set
         System.assertEquals(nonSysAdmin.Email,auc.newNur.Requestor_Email__c);
         
         //submit reactivate with Oracle CPQ
         auc.newNur.New_User_Email__c = ctctExistingOracle.Email;
         System.assertEquals(null,auc.searchForEmployee()); 
         System.assertEquals(false,(auc.hasUserMatches == null));
         auc.requestType = 'Y_Reactivate';
         System.assertEquals(null,auc.setRequestType());
         System.assertEquals(true,auc.canWeProceed);
         System.assertEquals('Reactivate',auc.newNur.Request_Type__c);
         // verify the required fields - should return false
         System.assertEquals(true,auc.verifyRequiredFields(auc.newNur));
         // save the request
         System.assertEquals(null,auc.submitRequest());
                             
         // should now be a request
         System.assertEquals(1,[Select count() from NewUserRequest__c]); 
              
          // verify open request exists
          NewUserRequest__c nur = [Select Id, New_User_Email__c,Request_Type__c from NewUserRequest__c where New_User_Email__c=:existingUOracle.Email and Request_Complete__c = false]; 
          
          // manage the new user request
          Test.setCurrentPage(Page.NewUserRequestManage);
          System.CurrentPageReference().getParameters().put('id',nur.Id);
          ApexPages.Standardcontroller sc = New ApexPages.StandardController(nur);
          auc = new AddUserController(sc);
          
          //System.assertEquals(true,auc.isSystemAdmin);
          System.assertEquals(false,auc.isSystemAdmin);
          System.assertEquals(false,auc.isGuestUser);
          System.assertEquals(nur.Id,auc.newNur.Id);
          System.assertEquals(false,auc.requestCompleteOnEntry);
          
          // set to approve
          auc.approveOrReject = 'approve';
          System.assertEquals(null,auc.setApproveOrReject());
          
          // save the user
          System.assertEquals(null,auc.saveUser());
          
          // return to request
          PageReference retPr = auc.gotoRequest();
          System.assertEquals(true,retPr.getUrl().contains(nur.Id)); 
      } // System.runAs(nonSysAdmin
      
   } // testReactivatingUser
   
} // class AddUserControllerTest