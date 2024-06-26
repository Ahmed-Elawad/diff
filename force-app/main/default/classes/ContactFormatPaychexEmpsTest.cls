/** 
 * Test methods for the ContactFormatPaychexEmps trigger.
 *
 * History
 * -------
 * 03/08/2011 Dan Carmen        Created
   09/26/2013 Dan Carmen        Changes for the employee records coming in via the integration
   02/15/2015 Dan Carmen        Change to use the preferred name on the contact if it's available
   05/05/2015 Dan Carmen        Provide a linkage to the active user record from the paychex employee contact
   09/14/2017 Dan Carmen        Added a switch to not use the initCap method.
   01/31/2018 Dan Carmen        Merge in UserUpdateFromContact logic
   08/01/2018 Dan Carmen        Fix for 
   11/08/2018 Dan Carmen        Add additional check for finding inactive user
   06/17/2020 Dan Carmen        Change to use a callout.
   02/04/2022 Dan Carmen        Add check for user lookup on contact if status changes
   03/09/2022 Dan Carmen        Populate other lat and long if postal code populated
   11/01/2023 Dan Carmen        Change to use queueable instead of callout
   02/21/2024 Dan Carmen        Add fields to the getUsersByPersonId query
   06/06/2024 Dan Carmen        Remove logic around lat and long for Other postal code.

 */
@isTest
public class ContactFormatPaychexEmpsTest {
    
   @testSetup
   public static void setupData() {
      checkSetupData();
   } // setupData

   // for setting up from other classes   
   public static void checkSetupData() {
      Boolean settingFound = false;
      for (TriggerSetupClasses__c tsc : TriggerSetupClasses__c.getAll().values()) {
         if (tsc.ClassName__c == 'ContactFormatPaychexEmps') {
            settingFound = true;
            break;
         }
      }
      if (!settingFound) {
         // setup triggers
         TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'ContactFormatPaychexEmps'});
         TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false,new String[]{'ContactFormatPaychexEmps'});
         TriggerMethodsTest.saveSetupClasses();

         Schema.RecordTypeInfo acctRtType = RecordTypeHelper.getRecordType(Label.RT_System_Admin_Account, ObjectHelper.OBJECT_ACCOUNT);
         Account acct = new Account(RecordTypeId=acctRtType.getRecordTypeId(), Name=UserHelper.PAYCHEX_COMP+'-Parent'); 
         ZipCheckOwner.SKIP_TRIGGERS=true;
         insert acct;
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }
   } // checkSetupData
   
   public static void resetTriggers() {
      //ContactFormatPaychexEmps.ctctsProcessedSet.clear();
      //ContactFormatPaychexEmps.contactsToProcessSet.clear();
      TriggerMethods.clearVariables();
   } // resetTriggers


   static testMethod void testTrigger() {
      ContactFormatPaychexEmps.TERMED_DAYS = 30;
      
      // create one existing child account - 2 others will be created by the trigger.
      Account parentAcct = ContactFormatPaychexEmps.getParentAcct();
      Account childAcct = parentAcct.clone();
      childAcct.Name = UserHelper.PAYCHEX_COMP;
      childAcct.Site = ContactFormatPaychexEmps.SITE_PREFIX+'B';
      insert childAcct;
      
      Contact c1 = new Contact(TempFirstName__c='Frank',TempLastName__c='Contact',Prefered_Name__c=null, TempTitle__c='Super Tester1', HR_Person_Id__c='TEST123', TempDepartment__c='Test Dept');
      Contact c2 = new Contact(TempFirstName__c='James',TempLastName__c='Contact II',Prefered_Name__c='Jimmy', TempTitle__c='Super Tester2', HR_Person_Id__c='TEST124', TempDepartment__c='Test Dept');
      Contact c3 = new Contact(TempFirstName__c='Jennifer',TempLastName__c='Test',Prefered_Name__c='Jenny', TempTitle__c='Super Tester3', HR_Person_Id__c='TEST125', TempDepartment__c='Test Dept');
      Contact c4 = new Contact(TempFirstName__c='Emily',TempLastName__c='Bloom',Prefered_Name__c='Em', TempTitle__c='Super Tester4', HR_Person_Id__c='TEST126', TempDepartment__c='Test Dept');
      // this one shouldn't change
      Contact c5 = new Contact(FirstName='Emma',LastName='Watson',Prefered_Name__c='Emma', Title='Super Tester5', HR_Person_Id__c=null, Department='Test Dept');
      Contact c6 = new Contact(FirstName='Taylor',LastName='Swift',Prefered_Name__c='Taylor', Title='Singer', HR_Person_Id__c='Test13', Department='Test Dept', Date_of_Employee_Termination__c=Date.today().addDays(-35));
      Contact[] ctcts = new Contact[]{c1,c2,c3,c4,c5,c6};
      insert ctcts;
      
      Map<Id, Contact> ctctMap = new Map<Id, Contact>([Select Id, AccountId, FirstName, LastName, Prefered_Name__c, Title, Department from Contact where Id in :ctcts]);

      // There should be 4 child accounts created
      Account[] accts = [Select Id, Name, Site from Account where Name=:UserHelper.PAYCHEX_COMP];
      System.assertEquals(4, accts.size());
      Map<String, Account> acctMap = new Map<String, Account>();
      for (Account acct : accts) {
         System.debug('testTrigger site='+acct.Site);
         acctMap.put(acct.Site, acct);
      }
      verifyContact(ctctMap.get(c1.Id), acctMap.get(UserHelper.PAYCHEX_COMP+'-C'),'Frank','Contact',null,'Super Tester1','Test Dept');
      verifyContact(ctctMap.get(c2.Id), acctMap.get(UserHelper.PAYCHEX_COMP+'-C'),'Jimmy','Contact II','Jimmy','Super Tester2','Test Dept');
      verifyContact(ctctMap.get(c3.Id), acctMap.get(UserHelper.PAYCHEX_COMP+'-T'),'Jenny','Test','Jenny','Super Tester3','Test Dept');
      verifyContact(ctctMap.get(c4.Id), acctMap.get(UserHelper.PAYCHEX_COMP+'-C'),'Em','Bloom','Em','Super Tester4','Test Dept');
      verifyContact(ctctMap.get(c5.Id), null,'Emma','Watson','Emma','Super Tester5','Test Dept');
      verifyContact(ctctMap.get(c6.Id), acctMap.get(ContactFormatPaychexEmps.SITE_TERMED),'Taylor','Swift','Taylor','Singer','Test Dept');
      
   } // testTrigger

   // Verify that the information returned from the contact matches what we expect.
   private static void verifyContact(Contact ctct, Account acct, String firstName, String lastName, String prefName, String title, String department) {
      Assert.areEqual(firstName, ctct.FirstName);
      Assert.areEqual(lastName, ctct.LastName);
      Assert.areEqual(prefName, ctct.Prefered_Name__c);
      Assert.areEqual(title, ctct.Title);
      Assert.areEqual(department,ctct.Department);
      if (acct != null) {
         Assert.areEqual(acct.Id, ctct.AccountId);
      }
   } // verifyContact
   
   public static User findInactiveUser(Set<String> personIdSet) {
      User inactiveUsr = null;
      Integer usrCounter=0;
      while (inactiveUsr == null && usrCounter < 10) {
         inactiveUsr = [Select Id, LastName, HR_Person_Id__c from User where HR_Person_Id__c != null and HR_Person_Id__c not in :personIdSet and IsActive=false and LastName like '%-T' order by createdDate desc limit 1];
         // verify there isn't an active one
         Integer usrCheck = [select count() from User where HR_Person_Id__c = :inactiveUsr.HR_Person_Id__c and IsActive=true];
         if (usrCheck > 0) {
            personIdSet.add(inactiveUsr.HR_Person_Id__c);
            inactiveUsr = null;
         }
         usrCounter++;
      }
      System.debug('findInactiveUser usrCounter='+usrCounter+' inactiveUsr='+inactiveUsr);
      System.assertEquals(true,usrCounter < 10, 'Could not find an inactive user!!');
      return inactiveUsr;
   } // findInactiveUser

   static testMethod void testUserLinkage() {
      User[] usrs = [Select Id, LastName, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true limit 2];
      User usr1 = usrs[0];
      User usr2 = usrs[1];
      
      Org_Unit__c org1 = new Org_Unit__c(Name='District1', Org_Type__c='District');
      Org_Unit__c org2 = new Org_Unit__c(Name='District2', Org_Type__c='District');
      Org_Unit__c[] orgs = new Org_Unit__c[]{org1,org2};
      insert orgs;
      
      Org_Unit_User_Link__c link1 = new Org_Unit_User_Link__c(Org_Unit__c=org1.Id, User__c=usr1.Id);
      Org_Unit_User_Link__c link2 = new Org_Unit_User_Link__c(Org_Unit__c=org2.Id, User__c=usr2.Id);
      Org_Unit_User_Link__c[] links = new Org_Unit_User_Link__c[]{link1,link2};
      insert links;
      
      Set<String> personIdSet = new Set<String>();
      personIdSet.add(usr1.HR_Person_Id__c);
      personIdSet.add(usr2.HR_Person_Id__c);

      User inactiveUsr = findInactiveUser(personIdSet);

      System.debug('usr1='+usr1);      
      System.debug('usr2='+usr2);      
      System.debug('inactiveUsr='+inactiveUsr);      
      Account payxAcct = new Account(Name=UserHelper.PAYCHEX_COMP);
      insert payxAcct;
      
      Contact c1 = new Contact(AccountId=payxAcct.Id,LastName=usr1.LastName, HR_Person_Id__c=usr1.HR_Person_Id__c);
      Contact c2 = new Contact(AccountId=payxAcct.Id,LastName=usr2.LastName, HR_Person_Id__c=usr2.HR_Person_Id__c);
      Contact c3 = new Contact(AccountId=payxAcct.Id,LastName=inactiveUsr.LastName, HR_Person_Id__c=inactiveUsr.HR_Person_Id__c, User_Lookup__c=inactiveUsr.Id);
      Contact[] ctcts = new Contact[]{c1,c2,c3};
      insert ctcts;
      
      Map<Id, Contact> ctctMap = new Map<Id, Contact>([Select Id, HR_Person_Id__c, OrgUnit__c, User_Lookup__c, User_Lookup__r.HR_Person_Id__c from Contact where Id in :ctcts]);
      c1 = ctctMap.get(c1.Id);
      System.assertEquals(usr1.Id, c1.User_Lookup__c);
      System.assertEquals(org1.Id, c1.OrgUnit__c);

      c2 = ctctMap.get(c2.Id);
      System.assertEquals(usr2.Id, c2.User_Lookup__c);
      System.assertEquals(org2.Id, c2.OrgUnit__c);

      c3 = ctctMap.get(c3.Id);
      System.assertEquals(inactiveUsr.HR_Person_Id__c, c3.User_Lookup__r.HR_Person_Id__c);
      System.assertEquals(null, c3.OrgUnit__c);
      
   } // testUserLinkage

   static testMethod void testSupervisorLinkage() {
      ContactFormatPaychexEmps.SET_REPORTS_TO = true;
      Contact c1 = new Contact(TempFirstName__c='frank',TempLastName__c='CONTACT',Prefered_Name__c=null, TempTitle__c='SUPER tEsTeR1', HR_Person_Id__c='TEST123', TempDepartment__c='TEST DEPT');
      insert c1;
      
      Contact c2 = new Contact(TempFirstName__c='james',TempLastName__c='CONTACT II',Prefered_Name__c='jimmy', TempTitle__c='SUPER tEsTeR2', HR_Person_Id__c='TEST124', TempDepartment__c='TEST DEPT', Supervisor_Person_Id__c=c1.HR_Person_Id__c);
      insert c2;
      
      c2 = [Select Id, Name, ReportsToId from Contact where Id=:c2.Id];
      System.assertEquals(c1.Id, c2.ReportsToId);
   } // testSupervisorLinkage

   
   private static void createCtct(User u, Map<String,Contact> ctctsByPersonId, Account acct) {
      Contact ctct = new Contact (Date_of_Employee_Termination__c = u.Termination_Date__c
                                ,Department = u.Department
                                ,FirstName = u.FirstName
                                ,LastName = u.LastName
                                ,Hire_Date__c = u.Hire_Date__c
                                ,HR_Person_Id__c = u.HR_Person_Id__c
                                ,MailingStreet = u.Street
                                ,MailingCity = u.City
                                ,MailingState = u.State
                                ,MailingPostalCode = u.PostalCode
                                ,Paychex_Cost_Center__c = u.Cost_Center__c
                                ,Paychex_Rep_Code__c = u.Person_ID_Number__c
                                ,Phone = u.Phone
                                ,Title = u.Title
                                ,AccountId = acct.Id);
      ctctsByPersonId.put(ctct.HR_Person_Id__c,ctct);
      System.debug('createCtct ctctsByPersonId='+ctctsByPersonId.size()+' HR_Person_Id='+ctct.HR_Person_Id__c);
   } // createCtct
   
   static testMethod void testUserUpdate() {
      //ContactFormatPaychexEmps.USE_CALLOUT=false;
      Account paychexAcct = ContactFormatPaychexEmps.getParentAcct();
      //String paychexName = 'Paychex Inc SA TESTINGGGGG';
      UserTestHelper uth = new UserTestHelper();
      User curUser = uth.getUserById(UserInfo.getUserId());
              
      // select users for testing
      Map<Id,User> userMap = new Map<Id,User>([Select Id, Termination_Date__c
                                ,Department
                                ,FirstName
                                ,LastName
                                ,Hire_Date__c
                                ,HR_Person_Id__c
                                ,Street
                                ,City
                                ,State
                                ,PostalCode
                                ,Cost_Center__c
                                ,Person_ID_Number__c
                                ,Phone
                                ,Title
                            from User
                           Where IsActive=true
                             and HR_Person_Id__c != null
                             and Job_Name__c = :UserHelper.JOB_REP
                           limit 11]);
      
      User[] users = userMap.values();
      System.runAs(curUser) {
         // we need an ordered 
         List<Contact> ctcts = new List<Contact>();
         Map<String,Contact> ctctsByPersonId = new Map<String,Contact>();
         // create Contacts for testing.
         for (User u : users) {
            createCtct(u,ctctsByPersonId,paychexAcct);
         }
         System.assertEquals(11,ctctsByPersonId.size());
         Utilities.SKIP_FUTURE = true; 
         insert ctctsByPersonId.values();
         Utilities.SKIP_FUTURE = false; 
         
         // verify that all of the user lookups are filled out
         System.assertEquals(11,[Select count() from Contact where User_Lookup__c != null]);
         
         // update the fields on the contact records
         // for contact 0, update all fields. For rest, only update one field.
         Contact ctct0 = ctctsByPersonId.get(users.get(0).HR_Person_Id__c);
         System.debug('testUserUpdate ctct0='+ctct0.LastName);
         System.debug('other termed ctct='+ctctsByPersonId.get(users.get(1).HR_Person_Id__c).lastName);
         // change termination date
         ctct0.Date_of_Employee_Termination__c = Date.today();
         ctctsByPersonId.get(users.get(1).HR_Person_Id__c).Date_of_Employee_Termination__c = Date.today();

         // set the manager id field
         ctctsByPersonId.get(users.get(1).HR_Person_Id__c).Supervisor_Person_Id__c = ctct0.HR_Person_Id__c;

         // change FirstName
         ctct0.FirstName = 'Test First0';
         ctctsByPersonId.get(users.get(2).HR_Person_Id__c).FirstName = 'Test First2';

         // change LastName
         ctct0.LastName = 'Test Last0';
         ctctsByPersonId.get(users.get(3).HR_Person_Id__c).LastName = 'Test Last3';

         // change Hire_Date__c
         ctct0.Hire_Date__c = Date.today();
         ctctsByPersonId.get(users.get(4).HR_Person_Id__c).Hire_Date__c = Date.today();

         // change MailingStreet
         ctct0.MailingStreet = '10 Test Street';
         ctctsByPersonId.get(users.get(5).HR_Person_Id__c).MailingStreet = '15 Test Street';

         // change MailingCity
         ctct0.MailingCity = 'TestCity0';
         ctctsByPersonId.get(users.get(6).HR_Person_Id__c).MailingCity = 'TestCity6';

         // change MailingState
         ctct0.MailingState = 'TestState0';
         ctctsByPersonId.get(users.get(7).HR_Person_Id__c).MailingState = 'TestState7';

         // change MailingPostalCode
         ctct0.MailingPostalCode = '12340';
         ctctsByPersonId.get(users.get(8).HR_Person_Id__c).MailingPostalCode = '12348';

         // change Paychex_Rep_Code__c
         ctct0.Paychex_Rep_Code__c = 'AM70';
         ctctsByPersonId.get(users.get(9).HR_Person_Id__c).Paychex_Rep_Code__c = 'AM79';

         // change Title
         ctct0.Title = 'Test Title0';
         ctctsByPersonId.get(users.get(10).HR_Person_Id__c).Title = 'Test Title10';
         
         resetTriggers();
         Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=ContactFormatPaychexEmps.CLASSNAME,Active__c=true);
         insert abc;
         // update the records
         Test.startTest();
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
         System.debug('testUserUpdate before update in Test.startTest');
         update ctctsByPersonId.values();
         Test.stopTest();

         System.assertEquals(11,[Select count() from Contact where User_Lookup__c != null]);
                
         // verify changes occurred
         users = new List<User>([Select Id
                                     ,City
                                     ,Cost_Center__c
                                     ,Department
                                     ,EmployeeNumber 
                                     ,FirstName
                                     ,Hire_Date__c
                                     ,HR_Person_Id__c
                                     ,IsActive
                                     ,LastName
                                     ,ManagerId
                                     ,Person_Id_Number__c // the rep code
                                     ,Phone
                                     ,PostalCode
                                     ,State
                                     ,Street
                                     ,Termination_Date__c
                                     ,Title
                                 from User 
                                where Id in :userMap.keySet()
                                and Title != null ]);
       
         for (User u : users) {
             verifyUserAndContact(u,ctctsByPersonId.get(u.HR_Person_Id__c));
         } // for (User
         
      } // System.runAs
      
   } // testUserUpdate

   private static void verifyUserAndContact(User u, Contact c) {
      System.debug('verifyUserAndContact u='+u);
      System.debug('verifyUserAndContact c='+c);
      // ignore case because case will be changing when copied over.
      System.assertEquals(c.Date_of_Employee_Termination__c,u.Termination_Date__c);
      if (c.Date_of_Employee_Termination__c != null) {
         System.assertEquals(false,u.IsActive);
      } else {
         //System.assertEquals(c.Department,u.Department);
         System.assertEquals(c.FirstName.toUpperCase(),u.FirstName.toUpperCase());
         System.assertEquals(c.LastName.toUpperCase(),u.LastName.toUpperCase());
         System.assertEquals(c.Hire_Date__c,u.Hire_Date__c);
         System.assertEquals(c.HR_Person_Id__c,u.HR_Person_Id__c);
         System.assertEquals(c.MailingStreet,u.Street);
         System.assertEquals(c.MailingCity,u.City);
         System.assertEquals(c.MailingState,u.State);
         System.assertEquals(c.MailingPostalCode,u.PostalCode);
         //System.assertEquals(c.Paychex_Cost_Center__c,u.Cost_Center__c);
         System.assertEquals(c.Paychex_Rep_Code__c,u.Person_ID_Number__c);
         //System.assertEquals(c.Phone,u.Phone);
         System.assertEquals(c.Title.toUpperCase(),u.Title.toUpperCase());
      }
   } // verifyUserAndContact

} // class ContactFormatPaychexEmpsTest