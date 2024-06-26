/* 
 * The test methods for the NewUserExtension class
 * Tests to perform:
   System Admin - testAsSystemAdmin
   Non System Admin w/ delegated License - testAsNonAdminDelegated
   Non System Admin w/out delegated License - testAsNonAdmin
   No licenses available - testAsNonAdminNoAvail
   Submit request for new licenses - testAsNonAdminNoAvail
   License not defined for User - testAsNonAdminNoDefine
   Create w/ passed in license id - testAsNonAdminDelegatedId
   Search w/ Contact result - use contact - testAsNonAdmin
   Search w/ User result = copy User
   Search w/ User result = use User
   Search w/ result - do not use results, create new User
   Search w/ no results = create new User - testSearchNoResults
   Create temp User
 *
 * History
 * -------
 * 02/27/2010 Dan Carmen   Created
   06/20/2012 Dan Carmen   Update API version
   11/27/2012 Dan Carmen   Modified checkOrganization method.
   07/28/2015 Dan Carmen   Modify testAsNonAdmin test to fix a production issue.
   01/11/2019 Dan Caremn   Change in the tests to account for a validation rule change
   01/03/2024 Dan Carmen   Remove User License references

 */
@isTest
private class NewUserExtensionTest {
   
   @testSetup
   public static void setupData() {
      // search for a contact
      Contact ctct = createTestContact('nueTest5@newemail.com.nueTest5','4312','2134');
   } // setupData
   
   public static Contact getTestContact() {
      Contact ctct = [Select Id, Name, Email, HR_Person_Id__c from Contact where Email='nueTest5@newemail.com.nueTest5'];
      return ctct;
   }

   /** Create a User for testing.
    */ 
   private static User createUser(String profileName, String testName, String delegatedLicense, String personId) {
      // get the system administrator profile
      Profile p = [Select Id from Profile where Name=:profileName];
      UserRole ur = [Select Id from UserRole where Name='System Administrator'];
      // create a new user
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = testName+'@paychex.com.'+testName
                        ,Email = testName+'@paychex.com.'+testName
                        ,Sales_Org__c = 'PAY'
                        ,IsActive = true
                        // person id
                        ,EmployeeNumber = personId
                        ,Hire_Date__c = Date.today()
                        ,Termination_Date__c = null
                        ,ManagerId = null
                        ,Department = 'Test Dept'
                        ,Alias = testName
                        ,CommunityNickname = testName
                        ,MobilePhone = '585-123-6544'
                        ,Phone = '585-123-6543'
                        // rep code
                        ,Person_ID_Number__c = 'A123'
                        ,Street = '123 Some St'
                        ,City = 'Somewhere'
                        ,PostalCode = '14514'
                        ,State = 'NY'
                        ,UserRoleId = ur.Id
                        ,ProfileId = p.Id
                        ,Cost_Center__c = '0017'
                        ,District__c = '0017'
                        ,Creation_Type__c = 'NewUser'
                        );
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey from User where Id = :UserInfo.getUserId()];
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      insert u1;
      return u1;
   } // createUser
   
   /** Test the methods as a System Administrator with no delegated licenses.
    */ 
   static testMethod void testAsSystemAdmin() {
      System.debug('Start testAsSystemAdmin');
      User u1 = createUser('System Administrator','nueTest1',null,'4312');
      System.runAs(u1) {

         NewUserExtension nue = getNue();
         checkStatusFlags1(nue);
         System.assertEquals(true,nue.showNewUserInfoBlock);
         System.assertEquals(false,nue.showErrorBlock);
         System.assertEquals(true,nue.isSystemAdmin);
      } // System.runAs
      System.debug('End testAsSystemAdmin');
   } // testAsSystemAdmin
    
   /** Test the methods as a Non - System Administrator w/ Delegated Licenses.
    */ 
   static testMethod void testAsNonAdminDelegated() {
      System.debug('Start testAsNonAdminDelegated');
      User u1 = createUser('Standard User','nueTest2','Test License 2;Test License 3','4312');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         checkStatusFlags1(nue);
         System.assertEquals(true,nue.showNewUserInfoBlock);
         System.assertEquals(false,nue.showErrorBlock);
         System.assertEquals(false,nue.isSystemAdmin);
         System.assertEquals(false,ApexPages.hasMessages());
         
      } // System.runAs
        
      System.debug('End testAsNonAdminDelegated');
   } // testAsNonAdminDelegated
   
   /** Test the methods as a Non - System Administrator.
    */ 
   static testMethod void testAsNonAdmin() {
      System.debug('Start testAsNonAdmin');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      // create a User record for the supervisor
      // TODO - this is causing an error in some cases. Commenting out for now.
      //User u2 = createUser('Standard User','nueTest4',null,'2134');
      System.runAs(u1) {
         Contact ctct = getTestContact();
         NewUserExtension nue = getNue();
         checkStatusFlags1(nue);
         System.assertEquals(true,nue.showNewUserInfoBlock);
         System.assertEquals(false,nue.showErrorBlock);
         System.assertEquals(false,nue.isSystemAdmin);
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest5@newemail.com.nueTest5';
         nue.performSearch();
         System.assertEquals(false,nue.getHasUserSearchResults());
         System.assertEquals(true,nue.getHasContactSearchResults());
         
         // select the contact for use
         System.CurrentPageReference().getParameters().put('type','copyContact');
         System.CurrentPageReference().getParameters().put('recId',ctct.Id);
         nue.handleRecordAction();
         System.assertEquals(true,nue.enterAddInfo);
         
         
      } // System.runAs
        
      System.debug('End testAsNonAdmin');
   } // testAsNonAdmin
   
   /** Test the methods as a Non - System Administrator - have a supervisor id, but no User Supervisor record
    */
   static testMethod void testAsNonAdminNoSuper() {
      System.debug('Start testAsNonAdminNoSuper');
      User u1 = createUser('Standard User','nueTest3',null,'4312');

      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         // search for a contact
         Contact ctct = getTestContact();
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest5@testEmail.com.nueTest5';
         nue.performSearch();
         System.assertEquals(false,nue.getHasUserSearchResults());
         System.assertEquals(true,nue.getHasContactSearchResults());
         
         // select the contact for use
         System.CurrentPageReference().getParameters().put('type','copyContact');
         System.CurrentPageReference().getParameters().put('recId',ctct.Id);
         String resultPage = nue.handleRecordAction().getUrl();
         System.assertEquals(true,nue.enterAddInfo);
         System.assertEquals('/apex/newuser1',resultPage);
         
      } // System.runAs
        
      System.debug('End testAsNonAdminNoSuper');
   } // testAsNonAdminNoSuper
   
   /** Search and find a User record. Use that record instead of copying it.
    */
   static testMethod void testSearchUseUser() {
      System.debug('Start testSearchUseUser');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      // the record to search for
      User u2 = createUser('Standard User','nueTest4',null,'2134');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest4@paychex.com.nueTest4';
         nue.performSearch();
         System.assertEquals(true,nue.getHasUserSearchResults());
         System.assertEquals(true,nue.getHasContactSearchResults());
         
         // select the contact for use
         System.CurrentPageReference().getParameters().put('type','useUser');
         System.CurrentPageReference().getParameters().put('recId',u2.Id);
         String resultPage = nue.handleRecordAction().getUrl();

         System.assertEquals('/'+u2.id+'/e',resultPage);
         
      } // System.runAs
        
      System.debug('End testSearchUseUser');
   } // testSearchUseUser
   
   /** Search and find a User record. Copy that record to create a new User.
    */
   static testMethod void testSearchCopyUser() {
      System.debug('Start testSearchCopyUser');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      // the record to search for
      User u2 = createUser('Standard User','nueTest4',null,'2134');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest4@paychex.com.nueTest4';
         nue.performSearch();
         System.assertEquals(true,nue.getHasUserSearchResults());
         System.assertEquals(true,nue.getHasContactSearchResults());
         
         // select the contact for use
         System.CurrentPageReference().getParameters().put('type','copyUser');
         System.CurrentPageReference().getParameters().put('recId',u2.Id);
         String resultPage = nue.handleRecordAction().getUrl();

         System.assertEquals('/apex/newuser1',resultPage);
         System.assertEquals(true,nue.enterAddInfo);
         
      } // System.runAs
        
      System.debug('End testSearchCopyUser');
   } // testSearchCopyUser
   
   /** Search and find a User record. Do not use the results and create a new user.
    */
   static testMethod void testSearchDoNotUseResults() {
      System.debug('Start testSearchDoNotUseResults');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest3@paychex.com.nueTest3';
         // search and find the same record as the user
         nue.performSearch();
         System.assertEquals(true,nue.getHasUserSearchResults());
         System.assertEquals(true,nue.getHasContactSearchResults());
         
         // do not use the search results and continue
         String resultPage = nue.continueWithoutSearched().getUrl();

         System.assertEquals('/apex/newuser2',resultPage);
         System.assertEquals(true,nue.enterAddInfo);
         
      } // System.runAs
        
      System.debug('End testSearchDoNotUseResults');
   } // testSearchDoNotUseResults
   
   /** Test the methods to create a temporary user
    */
   static testMethod void testCreateTempUser() {
      System.debug('Start testCreateTempUser');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Joffer';
         newUser.Email='nueTest5@paychex.com.nueTest5';
         newUser.Non_Paychex_Employee__c=true;
         PageReference resultPage=nue.performSearch();
         System.assertEquals('/apex/newuser2',resultPage.getUrl());
         Test.SetCurrentPageReference(resultPage);

         newUser = nue.newUser;
         System.assertEquals('Temporary Employee',newUser.Non_Paychex_Employee_User_Type__c);
         newUser.Cost_Center__c='0017';
         // force an error to stay on the same page
         newUser.LastName=null;
         resultPage=nue.saveAndContinue();
         System.assertEquals('/apex/newuser2',resultPage.getUrl());
         // fix data, should allow save
         newUser = nue.newUser;
         newUser.LastName='Joffer';
         resultPage=nue.saveAndContinue();
         String newUrl = '/'+newUser.id+'/e';
         // just check the first part of the URL
         // the ids are different lengths - this test is temporarily commented out!
         //System.assertEquals(newUrl,resultPage.getUrl().subString(0,newUrl.length()));
         
      } // System.runAs
        
      System.debug('End testCreateTempUser');
   } // testCreateTempUser
   
   /** Test the methods to search with no search results
    */
   static testMethod void testSearchNoResults() {
      System.debug('Start testCreateTempUser');
      User u1 = createUser('Standard User','nueTest3',null,'4312');
      System.runAs(u1) {
         NewUserExtension nue = getNue();
         
         User newUser = nue.newUser;
         newUser.FirstName='Akeem';
         newUser.LastName='Someone';
         newUser.Email='nueTest6@paychex.com.nueTest6';
         newUser.Non_Paychex_Employee__c=false;
         String resultPage=nue.performSearch().getUrl();
         System.assertEquals('/apex/newuser2',resultPage);
         // for the message that no search results were found.
         System.assertEquals(true,ApexPages.hasMessages());
         
         // change the cost center
         nue.newUser.Cost_Center__c = '16';
         resultPage=nue.reCheckOrganization().getUrl();
         System.assertEquals('/apex/newuser2',resultPage);
      } // System.runAs
        
      System.debug('End testCreateTempUser');
   } // testCreateTempUser
   
   /** Create a test contact record to use for matching. Make sure Paychex Inc SA exists first.
    */
   private static Contact createTestContact(String email, String personId, String mgrPersonId) {
      // verify that Paychex Inc SA exists - this is to ensure it doesn't fail on an empty sandbox
      Integer cnt = [Select count() from Account where Name = 'Paychex Inc SA'];
      if (cnt == 0) {
         // create the account
         Account a = new Account(Name='Paychex Inc SA');
         insert a;
      } // if (cnt == 0
      Account acct = [Select Id from Account where Name = 'Paychex Inc SA'];
      Contact ctct = new Contact(accountId=acct.Id
                                ,FirstName='Akeem'
                                ,LastName='Joffer'
                                ,Email=email
                                ,MailingStreet='123 Some St'
                                ,MailingCity='Some City'
                                ,MailingState='NY'
                                ,MailingPostalCode='14514'
                                ,Supervisor__c=null
                                ,Date_of_Employee_Termination__c=null
                                ,Department='Zamunda'
                                ,HR_Person_Id__c=personId
                                ,Payroll_Employee_Number__c=personId
                                ,Supervisor_Person_Id__c=mgrPersonId
                                ,Paychex_Cost_Center__c ='0017'
                                ,Hire_Date__c=Date.today()
                                ,Phone='585-123-5212'
                                ,Title = 'Prince'
                                );
      insert ctct;
      return ctct;
   } // createTestContact
   
   /** Create a NewUserExtension object.
    */
   private static NewUserExtension getNue() {
      Test.SetCurrentPageReference(New PageReference('Page.NewUser1'));
      ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(new User());
      //System.CurrentPageReference().getParameters().put('id',opp1.Id);
      NewUserExtension nue = new NewUserExtension(sc1);
      return nue;
   } // getNue

   /** Check the status flags as they should be on initial entry to the page.
    */   
   private static void checkStatusFlags1(NewUserExtension nue) {
      System.assertEquals(false,nue.hasSearchResults);
      System.assertEquals(false,nue.enterAddInfo);
   } // checkStatusFlags1
   
} // NewUserExtensionTest