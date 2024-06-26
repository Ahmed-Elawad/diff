/* 
 * The test methods for the UserHelper class.
 *
 * History
 * -------
 * 01/27/2011 Dan Carmen         Created
   08/25/2011 Dan Carmen         Modified getQueue (getGroup) method.
   07/23/2012 Dan Carmen         Added in getProdTranslation method.
   09/02/2012 Cindy Freeman      Added in get testRoleSubordinateSaleUsers method
   10/11/2012 Dan Carmen         Added in getDSA method
   11/23/2012 Dan Carmen         Added in getContactById method.
   12/10/2012 Dan Carmen         Added in getProfile method.
   12/19/2012 Dan Carmen         Added in test for checkForDsaField method.
   01/16/2014 Dan Carmen         Added method to return the running user
   03/01/2014 Dan Carmen         Changes for NSS
   04/13/2015 Dan Carmen         Add modification for setupSalesOrgSetting.
   04/22/2015 Dan Carmen         Added isUserVisible method
   07/07/2015 Dan Carmen         Modified testRoleChange to reduce the run time in prod.
   07/27/2016 Dan Carmen         Added getContactMapByEmail method.
   05/05/2017 Cindy Freeman      added test for getUserIM method
   07/17/2017 Cindy Freeman      modified test for getUserIM to test for multiple zones
   10/16/2017 Dan Carmen         Code Cleanup
   02/06/2018 Dan Carmen         Test adjustment
   04/06/2018 Dan Carmen         Set getRunningUser to run from the cache
   06/08/2018 Cindy Freeman     moved getUserIMtest method to QuoteMethodsTest
   06/11/2018 Cindy Freeman      added PEO Lead record type to Sales_Org setup
   08/01/2018 Dan Carmen         Adjustment for a test to select the right type of user.
   12/14/2018 Dan Carmen         Modify checkForJobName to use the Profile_List__c custom setting
   05/31/2019 Jake Hinds         adding in peo sales org
   07/09/2019 Dan Carmen         Use custom metadata type for Job Name
   01/02/2020 Josh Cartwright    test set and clear federation id 	
   08/25/2021 Dan Carmen         Add runningUserIsCoe
   01/04/2022 Eric Porter        Added String.escapeSingleQuotes to getUserByPersonId
   04/15/2022 Dan Carmen         Add findUserRoles method
   07/19/2022 Dan Carmen         Add another parameter to findUserRoles
   07/22/2022 Chris Santoro		 Add CA Mandate user and HR Person ID to v_reps query
   05/29/2023 Dan Carmen         Add exception handling in getProdTranslation
   06/01/2023 Dan Carmen         Adjust setupSalesOrgSetting to remove queries
   07/19/2023 Chris Santoro		 Added v_hrs_rep for 401k Oppty testing in OpportunityServicesTest
   10/31/2023 Dan Carmen         Update getContact methods to store a copy in a static map in case the same contact is retrieved more than once in a session
   11/03/2023 Dan Carmen         Update setUserFromContact to include the Payroll_Employee_Number__c
   01/03/2024 Dan Carmen         Remove User License references

   
 */
@isTest
public class UserHelperTest {

   ///********************************-----Data Setup methods ------******************************************
   public static void clearProcessNames() {
      try {
         delete [Select Id from ProcessNameMap__c];
      } catch (Exception e) {
         // do nothing
      }
   } // clearProcessNames

   public static ProcessNameMap__c setupProcessName(String processPrefix, String username) {
      ProcessNameMap__c pnm = new ProcessNameMap__c(Name=processPrefix+username, IsActive__c=true);
      insert pnm;
      return pnm;
   } // setupProcessName
   
   public static void setupGenericUsers() {
      try {
         delete [Select Id from ProcessNameMap__c];
      } catch (Exception e) {
         
      }
      UserHelper.runningUserIsSfdcData = null;
      ProcessNameMap__c pnm1 = new ProcessNameMap__c(Name=UserHelper.PREFIX_SFDC+UserHelper.SFDC_DATA, IsActive__c=true);
      ProcessNameMap__c pnm2 = new ProcessNameMap__c(Name=UserHelper.PREFIX_RJ+UserHelper.RELATIONAL_JUNCTION, IsActive__c=true);
      ProcessNameMap__c pnm3 = new ProcessNameMap__c(Name=UserHelper.PREFIX_LL+UserHelper.LEAD_LOADER, IsActive__c=true);
      ProcessNameMap__c[] pnms = new ProcessNameMap__c[]{pnm1,pnm2,pnm3};
      insert pnms;
      
   } // setupGenericUsers

   // Setup the custom setting for the sales org. 
   public static SalesOrg__c[] setupSalesOrgSetting() {
      System.debug('setupSalesOrgSetting setting up salesOrg custom setting');
      // delete any that already exist
      if (SalesOrg__c.getAll().values().size() > 0) {
         // delete any that already exist
         try {
            delete [Select Id from SalesOrg__c];
         } catch (Exception e) {
            // do nothing here
         }
      }
      if (Profile_List__c.getAll().values().size() > 0) {
         try {
            delete [Select Id from Profile_List__c];
         } catch (Exception e) {
            // do nothing here
         }
      }
      SalesOrg__c[] salesOrgs = new SalesOrg__c[]{};
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_CORE, Description__c='Core',HasOwnership__c=true, RecordTypeAlias__c='Core '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA
                                    ,EventRecordTypeName__c=RecordTypeHelper.CORE_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.CORE_TASK
                                    ,ProductName__c='',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c='Payroll Owner',CanSubmitReferrals__c=true,StrcHasArea__c=true
                                    ,LeadRecordTypeName__c=RecordTypeHelper.CORE_LEAD
                                    ,OppFirstStage__c='Pending'
                                    ,ZipBatchKey__c='A'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    ));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_MMS, Description__c='MMS',HasOwnership__c=true, RecordTypeAlias__c='MMS '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_MMS_DSA
                                    ,EventRecordTypeName__c=RecordTypeHelper.MMS_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.MMS_TASK
                                    ,ProductName__c='',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c='Payroll Owner',CanSubmitReferrals__c=true,StrcHasArea__c=false
                                    ,LeadRecordTypeName__c=RecordTypeHelper.MMS_LEAD
                                    ,ZipBatchKey__c='A'
                                    ,OppFirstStage__c='Qualified'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    ));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_401, Description__c='401k/FSA',HasOwnership__c=true, RecordTypeAlias__c='HRS 401(k) '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_401K_FSS
                                    ,EventRecordTypeName__c=RecordTypeHelper.HRS_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.HRS_TASK
                                    ,ProductName__c='401(k)',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c=Label.AT_401k,CanSubmitReferrals__c=true,StrcHasArea__c=true
                                    ,LeadRecordTypeName__c=RecordTypeHelper.HRS_LEAD
                                    ,OppFirstStage__c='Qualified'
                                    ,ZipBatchKey__c='B'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    ));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_PEO_ASO, Description__c='HR Solutions',HasOwnership__c=true, RecordTypeAlias__c='HRS PEO-ASO '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_PEO
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_PEO_FSS
                                    ,EventRecordTypeName__c=RecordTypeHelper.HRS_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.HRS_TASK
                                    ,ProductName__c='PEO/ASO',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c=Label.AT_PEO_ASO,CanSubmitReferrals__c=true,StrcHasArea__c=true
                                    ,LeadRecordTypeName__c=RecordTypeHelper.PEO_LEAD
                                    ,OppFirstStage__c='Qualified'
                                    ,ZipBatchKey__c='B'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    ));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_PEO, Description__c='PEO',HasOwnership__c=true, RecordTypeAlias__c='PEO '
                                    // ,OpptyRecordTypeName__c=Label.RT_Oppty_PeoC
                                    // ,OpptyRecordTypeName2__c=Label.RT_Oppty_PeoC_FSS
                                    ,EventRecordTypeName__c=Label.RT_PEO_Event
                                    ,TaskRecordTypeName__c=Label.RT_PEO_Task
                                    ,ProductName__c='PEO',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c=Label.AT_PEO_ASO,CanSubmitReferrals__c=true,StrcHasArea__c=true
                                    ,LeadRecordTypeName__c=RecordTypeHelper.PEO_LEAD
                                    ,OppFirstStage__c='Qualified'
                                    ,ZipBatchKey__c='B'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    ));  
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_HNB, Description__c='Health & Benefits',HasOwnership__c=true, RecordTypeAlias__c='HRS HNBF '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_HNBF
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_HNBF_DSA
                                    ,EventRecordTypeName__c=RecordTypeHelper.HNBF_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.HNBF_TASK
                                    ,ProductName__c='HNBF',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c=Label.AT_HNBF,CanSubmitReferrals__c=true,StrcHasArea__c=false
                                    ,OppFirstStage__c='Pending'
                                    ,ZipBatchKey__c='B'
                                    ,IEUP_Type__c = 'Presentation - Initial (Face to Face)'
                                    ));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_ADV, Description__c='Advantage',HasOwnership__c=false));
      salesOrgs.add(new SalesOrg__c(Name=UserHelper.SO_WHOLESALER, Description__c='Wholesaler'
                                   ,HasOwnership__c=true,ProcessAcctOwnership__c=false,ProcessRfrlOwnership__c=true));
      insert salesOrgs;
      return salesOrgs;
   } // setupSalesOrgSetting

   public static User v_dsa = null;
   public static User v_dsa2 = null;
   // these reps are under the dsa
   public static User[] v_reps = null;
   //public static User[] ca_mandate_reps = null;
   // this is a rep under a different role
   public static User v_rep6 = null;
   public static User v_hrs_rep = null;
   public static User v_runningUser = UserHelper.getRunningUser();
   

   public static void selectDsaAndReps() {
      // find the district user roles with at least 5 children
      AggregateResult[] results = [Select count(Id) nbr_recs, UserRoleId, UserRole.ParentRoleId parentRoleId
                                     From User
                                    Where IsActive=true
                                      and Sales_Org__c=:UserHelper.SO_CORE
                                      and Profile.Name in :Utilities.REP_PROFS
                                    group by UserRoleId, UserRole.ParentRoleId
                                    having count(Id) > 5
                                     order by count(Id) desc
                                    ];
      
      System.debug('testIsUserVisible nbrresults='+results.size()+' results='+results);
      
      // pull out all of the district ids to make sure we get at least one good one.
      Id[] dsaUserRoleIds = new Id[]{}; 
      for (AggregateResult result : results) {
         dsaUserRoleIds.add((Id)result.get('parentRoleId'));
      }
      
      User[] dsas = [Select Id, Name, UserRoleId, UserRole.Name
                           ,Profile.Name, Profile.Id,ManageZipOrgUnitsManaged__c, HR_Person_Id__c
                       from User 
                   where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE //and Profile.Name in :Utilities.DSA_PROFS 
                     and Job_Name__c in (:UserHelper.JOB_DSA,:UserHelper.JOB_DSM)
                     and UserRoleId in :dsaUserRoleIds
                    limit 10];
      
      v_dsa = dsas[0];
      for (User usr : dsas) {
         // find a DSA with a different role
         if (usr.UserRoleId != v_dsa.UserRoleId) {
            v_dsa2 = usr;
            break;
         }
      } // for
      System.assertEquals(true,v_dsa2 != null);
      /*
      // select a DSA
      dsa = [Select Id, Name, UserRoleId from User 
                   where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.DSA_PROFS 
                     and Job_Name__c = :UserHelper.JOB_DSA
                     and UserRoleId in :dsaUserRoleIds
                    limit 1];

      // select a DSA under a different role
      dsa2 = [Select Id, Name, UserRoleId from User 
                   where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.DSA_PROFS 
                     and Job_Name__c = :UserHelper.JOB_DSA
                     and UserRoleId in :dsaUserRoleIds
                     and UserRoleId != :dsa.UserRoleId
                    limit 1];
      */
      // select some reps
      v_reps = [Select Id, Name, UserRoleId, UserRole.ParentRoleId, User_Type__c
                    ,Sales_Org__c, District__c, District_Name__c, HR_Person_Id__c
                from User 
               where IsActive=true 
                 and UserRole.ParentRoleId = :v_dsa.UserRoleId 
                 and Sales_Org__c=:UserHelper.SO_CORE 
                 and Profile.Name in :Utilities.REP_PROFS 
               limit 5];
       /*
       ca_mandate_reps = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                          ,Sales_Org__c, District__c, District_Name__c, HR_Person_Id__c
                          from User 
                          where IsActive=true 
                          and User_Type__c = 'CA Mandate'
                          limit 5];
       */
      // this is a rep under a different role
      v_rep6 = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                    ,Sales_Org__c, District__c, District_Name__c, HR_Person_Id__c
                from User 
               where IsActive=true 
                 and UserRole.ParentRoleId = :v_dsa2.UserRoleId 
                 and Sales_Org__c=:UserHelper.SO_CORE 
                 and Profile.Name in :Utilities.REP_PROFS 
                limit 1];

      v_reps.add(v_rep6);
       
      v_hrs_rep = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                    ,Sales_Org__c, District__c, District_Name__c, HR_Person_Id__c
                from User 
               where IsActive=true 
                 //and UserRole.ParentRoleId = :v_dsa2.UserRoleId 
                 and Sales_Org__c=:UserHelper.SO_401 
                 and Profile.Name in :Utilities.REP_PROFS 
                limit 1];      
      
      v_runningUser = UserHelper.getRunningUser();
   } // selectDsaAndReps

   ///********************************-----Start Tests ------******************************************

   // test getting a user record.
   @isTest(SeeAllData=false)
   static void testGetUser() {
      UserHelper uh = new UserHelper();
      User u = uh.getUserById(UserInfo.getUserId());
      // verify user is returned
      System.assertEquals(UserInfo.getUserId(),u.Id);
      
      // find a user with a person id
      u = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null limit 1];
      User foundU = uh.getUserByPersonId(u.HR_Person_Id__c);
      System.assertEquals(u.Id, foundU.Id);
      
      // clear out the person id then try again.
      u.HR_Person_Id__c = null;
      update u;
      
      foundU = uh.getUserByPersonId(u.HR_Person_Id__c);
      System.assertEquals(true, (foundU == null));
   } // testGetUser

   // Test getting a contact record.
   static testMethod void testGetContact() {
      ContactFormatPaychexEmpsTest.checkSetupData();
      Account acct = ContactFormatPaychexEmps.getParentAcct();

      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Joe',LastName='Tester',HR_Person_Id__c='Test123');
      insert ctct;
        
      UserHelper uh = new UserHelper();
      Contact ctctResult = uh.getContactByPersonId('Test123','UserHelperTest Account');
      System.assertEquals(ctct.Id,ctctResult.Id);
      
      ctctResult = uh.getContactById(ctct.Id);
      System.assertEquals(ctct.Id,ctctResult.Id);
   } // testGetContact

   static testMethod void testSfdcData() {
      User sfdcData = UserHelper.getSfdcData();
      System.assertEquals(UserHelper.SFDC_DATA,sfdcData.Name);
      
      setupGenericUsers();

      System.assertEquals(true,UserHelper.isSfdcData(UserHelper.SFDC_DATA));
      System.assertEquals(false,UserHelper.isSfdcData('Someone Else'));
   } // testSfdcData
   
    @isTest(SeeAllData=false)
   static void testSetUserFromCtct() {
      User testUser = [Select Id, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null and Id != :UserInfo.getUserId() limit 1];
      System.assertEquals(true,testUser != null);
        
      Contact ctct = new Contact(FirstName='Joseph', Prefered_Name__c='Joe'
                       ,LastName='Tester'
                     ,MailingCity='Sometown'
                     ,Department='Testing Department'
                      // EmployeeNumber is the HR Person Id
                     ,HR_Person_Id__c='8765309'
                      // Person_Id_Number is the rep code.
                     ,Paychex_Rep_Code__c='DAN1'
                     ,Phone='(585)431-1245'
                     ,MailingPostalCode='14514'
                     ,MailingState='NY'
                     ,MailingStreet='123 Any Street'
                     ,Date_of_Employee_Termination__c=null
                     ,Title='Tester'
                     ,Paychex_Cost_Center__c='1234'
                     ,Hire_Date__c=Date.today().addMonths(-12)
                     ,Supervisor_Person_Id__c = testUser.HR_Person_Id__c
                     ,Payroll_Employee_Number__c='4242427'
                       );
      User usr = new User();
      UserHelper uh = new UserHelper();
      uh.setUserFromContact(usr,ctct);
      
      System.assertEquals('Joe',usr.FirstName);
      System.assertEquals('Tester',usr.LastName);
      System.assertEquals(ctct.MailingCity,usr.City);  
      System.assertEquals('Testing Department',usr.Department);
      System.assertEquals(ctct.HR_Person_Id__c,usr.EmployeeNumber);
      System.assertEquals(ctct.HR_Person_Id__c,usr.HR_Person_Id__c);
      System.assertEquals(ctct.Paychex_Rep_Code__c,usr.Person_ID_Number__c);
      System.assertEquals(ctct.Phone,usr.Phone);
      System.assertEquals(ctct.MailingPostalCode,usr.PostalCode);
      System.assertEquals(ctct.MailingState,usr.State);
      System.assertEquals(ctct.MailingStreet,usr.Street);
      System.assertEquals(ctct.Date_of_Employee_Termination__c,usr.Termination_Date__c);
      System.assertEquals('Tester',usr.Title);
      System.assertEquals(ctct.Paychex_Cost_Center__c,usr.Cost_Center__c);
      System.assertEquals(ctct.Hire_Date__c,usr.Hire_Date__c);
      System.assertEquals(testUser.Id,usr.ManagerId);
      Assert.areEqual(ctct.Payroll_Employee_Number__c, usr.Payroll_Employee_Number__c);

   } // testSetUserFromCtct
   
   // Test getting the user id from an email address.
   static testMethod void testGetUserId() {
      UserHelper uh = new UserHelper();
      // test with null value
      System.assertEquals('',uh.getUserId(null,null));
      // test with null max
      System.assertEquals('testuser',uh.getUserId('testuser@paychex.com', null));
      // test with a max value
      System.assertEquals('testus',uh.getUserId('testuser@paychex.com', 6));
   } // testGetUserId
      
   // Test getting a unique community nickname.
   static testMethod void testGetUniqueNickname() {
        UserTestHelper uth = new UserTestHelper();
      UserHelper uh = new UserHelper();
      User curUser = uth.getUserById(UserInfo.getUserId());
      
      // test an email address that shouldn't exist
      String nickname = uh.getUniqueNicknameByEmail('testabc123@paychex.com');
      System.assertEquals('testabc123',nickname);
      
      // create a User where the community nickname equals the email address
      User testUser = uth.createUser(1, curUser.Profile, curUser.UserRole, curUser);
      insert testUser;
      
        // run through it so it will 
        nickname = uh.getUniqueNickname(testUser.CommunityNickname);
        System.assertEquals(testUser.CommunityNickname+'0',nickname);
   } // testGetUniqueNickname

   static testMethod void testGetQueue() {
      UserHelper uh = new UserHelper();
      System.assertEquals(null,uh.getGroup(null));
      // create test groups
      Group[] grps = new Group[]{};
      grps.add(new Group(Name='UserHelperTest Queue 1',Type='Queue'));
      grps.add(new Group(Name='UserHelperTest Queue 2',Type='Queue'));
      insert grps;
      
      // test when no queue exists
      // getGroup will be deprecated, but call it here anyway
      System.assertEquals(null,uh.getGroup('This Group Does Not Exist'));
      System.assertEquals(true,(uh.getGroup('UserHelperTest Queue 1') != null));
      
      System.assertEquals(null,uh.getQueue('This Group Does Not Exist'));
      System.assertEquals(true,(uh.getQueue('UserHelperTest Queue 1') != null));

      String[] queueNames = new String[]{'UserHelperTest Queue 1','UserHelperTest Queue 2','This Queue Does Not Exist'};
      Map<String,Group> queueMap = uh.getQueues(queueNames);
      System.assertEquals(true,queueMap.containsKey('UserHelperTest Queue 1'));
      System.assertEquals(true,queueMap.containsKey('UserHelperTest Queue 2'));
      System.assertEquals(false,queueMap.containsKey('This Queue Does Not Exist'));
 
      // test getting queue by the ID
      System.assertEquals(true, (uh.getQueueById(grps.get(0).Id) != null));
      User usr = [Select Id, Profile.Name, License_Type__c, License_Type_Delegation__c from User where Profile.Name='System Administrator' and IsActive=true limit 1];
      System.assertEquals(true, (uh.getQueueById(usr.Id) == null));
      
      // test a valid queue
   } // testGetQueue

   // Test the different permutations of isCore, isMMS, and isHRS.
   static testMethod void testIsSalesForce() {
      UserHelper uh = new UserHelper();
      System.assertEquals(false,uh.isCore(null));
      System.assertEquals(false,uh.isCore('TEST'));
      System.assertEquals(true,uh.isCore(UserHelper.SO_CORE));
      System.assertEquals(false,uh.isCore(UserHelper.SO_MMS));
      System.assertEquals(false,uh.isCore(UserHelper.SO_401));
      System.assertEquals(false,uh.isCore(UserHelper.SO_PEO_ASO));
      System.assertEquals(false,uh.isCore(UserHelper.SO_PBS));
      System.assertEquals(false,uh.isCore(UserHelper.SO_HNB));
       
      System.assertEquals(false,uh.isMMS(null));
      System.assertEquals(false,uh.isMMS('TEST'));
      System.assertEquals(false,uh.isMMS(UserHelper.SO_CORE));
      System.assertEquals(true,uh.isMMS(UserHelper.SO_MMS));
      System.assertEquals(false,uh.isMMS(UserHelper.SO_401));
      System.assertEquals(false,uh.isMMS(UserHelper.SO_PEO_ASO));
      System.assertEquals(false,uh.isMMS(UserHelper.SO_PBS));
      System.assertEquals(false,uh.isMMS(UserHelper.SO_HNB));
       
      System.assertEquals(false,uh.isHRS(null));
      System.assertEquals(false,uh.isHRS('TEST'));
      System.assertEquals(false,uh.isHRS(UserHelper.SO_CORE));
      System.assertEquals(false,uh.isHRS(UserHelper.SO_MMS));
      System.assertEquals(true,uh.isHRS(UserHelper.SO_401));
      System.assertEquals(true,uh.isHRS(UserHelper.SO_PEO_ASO));
      System.assertEquals(true,uh.isHRS(UserHelper.SO_PBS));
      System.assertEquals(true,uh.isHRS(UserHelper.SO_HNB));
       
      System.assertEquals(false,uh.isHNB(null));
      System.assertEquals(false,uh.isHNB(UserHelper.SO_PEO_ASO));
      System.assertEquals(true,uh.isHNB(UserHelper.SO_HNB));
      
      System.assertEquals(false,uh.isMSP(null));
      System.assertEquals(false,uh.isMSP(UserHelper.SO_PEO_ASO));
      System.assertEquals(true,uh.isMSP(UserHelper.SO_MSP));
      
   } // testIsSalesForce
   
   static testMethod void testCheckEbsUsername() {
      User u1 = new User(Username='test1@paychex.com', EBS_Username__c=null);
      User u2 = new User(Username='test2@paychex.com', EBS_Username__c=null);
      User u3 = new User(Username='test3@paychex.com', EBS_Username__c='test4');
      User[] users = new User[]{u1,u2,u3};
      //UserHelper.checkEbsUsername(users);
      new UserHelper().checkOrganization(u1);
      UserTriggerMethods.checkEbsUsername(u1);
      UserTriggerMethods.checkEbsUsername(u2);
      UserTriggerMethods.checkEbsUsername(u3);
      System.assertEquals('test1',u1.EBS_Username__c);
      System.assertEquals('test2',u2.EBS_Username__c);
      System.assertEquals('test3',u3.EBS_Username__c);
   }
   
   static testMethod void testCheckADUsername() {
      User u1 = new User(Username='test1@paychex.com', AD_Username__c=null);
      User u2 = new User(Username='testtest2@paychex.com', AD_Username__c=null);
      User u3 = new User(Username='testtest03@paychex.com', AD_Username__c='test4');
      User[] users = new User[]{u1,u2,u3};
      //UserHelper.checkADUsername(users);
      new UserHelper().checkOrganization(u1);
      UserTriggerMethods.checkADUsername(u1);
      UserTriggerMethods.checkADUsername(u2);
      UserTriggerMethods.checkADUsername(u3);
      System.assertEquals('test1',u1.AD_Username__c);
      System.assertEquals('testtes2',u2.AD_Username__c);
      System.assertEquals('testte03',u3.AD_Username__c);
   }
   
   static testMethod void testSalesOrgTranslation() {
      UserHelper uh = new UserHelper();
      System.assertEquals(null,uh.getSalesOrgTranslation(null));
      System.assertEquals('PAY',uh.getSalesOrgTranslation('PAY'));
      System.assertEquals(UserHelper.SO_PEO_ASO,uh.getSalesOrgTranslation(UserHelper.SO_HR_SOL));
      System.assertEquals(UserHelper.SO_HR_SOL,uh.getSalesOrgTranslation(UserHelper.SO_PEO_ASO));
   } // testSalesOrgTranslation
   

   static testMethod void testGetRoleMap() {
      UserRole[] testRoles = [Select Id, Name, ParentRoleId from UserRole limit 5];
      Id[] userRoleIds = new Id[]{};
      Map<Id,UserRole> testRoleMap = new Map<Id,UserRole>();
      
      for (UserRole ur : testRoles) {
         userRoleIds.add(ur.Id);
         testRoleMap.put(ur.Id,ur);
      }
      
      UserHelper uh = new UserHelper();
      Map<Id,UserRole> queryRoleMap = uh.getRoleMap(userRoleIds);
      
      // verify results
      for (Id roleId : testRoleMap.keySet()) {
         System.assertEquals(true,queryRoleMap.containsKey(roleId));
      }

   } // testGetRoleMap

   static testMethod void testProdTranslation() {
      setupSalesOrgSetting();
      UserHelper uHelp = new UserHelper();
      System.assertEquals(null,uHelp.getProdTranslation(null));
      System.assertEquals('Test',uHelp.getProdTranslation('Test'));
      System.assertEquals('Core',uHelp.getProdTranslation(UserHelper.SO_CORE));
      System.assertEquals('MMS',uHelp.getProdTranslation(UserHelper.SO_MMS));
      System.assertEquals('401k/FSA',uHelp.getProdTranslation(UserHelper.SO_401));
      System.assertEquals('HR Solutions',uHelp.getProdTranslation(UserHelper.SO_PEO_ASO));
      System.assertEquals('Health & Benefits',uHelp.getProdTranslation(UserHelper.SO_HNB));
   } // testProdTranslation
   
   static testMethod void testRoleSubordinateSaleUsers() {
      
        User dsm = [Select Id, Name, HR_Person_Id__c, UserRoleID from User where IsActive=true 
               and HR_Person_Id__c != null 
               and (UserRole.Name like 'CORE DISTRICT%' or UserRole.Name like 'SMB District%') limit 1];
               
      Set<Id> repRoleIds = new Set<Id>();

      List<UserRole> repRole = [Select Id, Name, ParentRoleID from UserRole 
               where ParentRoleID = :dsm.UserRoleId];
     For (UserRole ur : repRole) 
     {      repRoleIds.add(ur.Id);  }

      Boolean anyMore = true;
      
      while (anyMore) {
         List<UserRole> listSubRoles = [Select Id from UserRole where ParentRoleId IN :repRoleIds];
         List<Id> listSubIds = new List<Id>();
         for (UserRole u : listSubRoles)
         {  listSubIds.add(u.Id);   }
         if (repRoleIds.containsAll(listSubIds))
         {  anyMore = false;  }
         else  
         {  repRoleIds.addAll(listSubIds);   }
     }     
                  
      List<User> repUsers = [Select Id, HR_Person_Id__c, UserRoleID from User 
               where UserRole.Id IN :repRoleIds
               and Profile.Name IN :Utilities.REP_PROFS];
      
        Map<Id,User> repUserMap = new Map<Id,User>();    
        for (User u : repUsers) {
           repUserMap.put(u.Id,u);
        }
      
        UserHelper uh = new UserHelper();
        Set <Id> returnedUsers = uh.getRoleSubordinateSaleUsers(dsm.Id);
      
      // verify results
      System.assertEquals(repUsers.size(), returnedUsers.size());      
      for (Id retUser : returnedUsers) {
         System.assertEquals(true,repUserMap.containsKey(retUser));
      }

   } // testRoleSubordinateUsers

   static testMethod void testGetDsa() {
      // create a mini role heirarchy
      UserRole firstLevelRole = new UserRole(Name='First Level ZONE Role',DeveloperName='FirstLevelRole');
      insert firstLevelRole;
      UserRole secondLevelRole = new UserRole(Name='Second Level DISTRICT Role',DeveloperName='SecondLevelRole', ParentRoleId=firstLevelRole.Id);
      insert secondLevelRole;
      UserRole thirdLevelRole = new UserRole(Name='Third Level SALES REP Role',DeveloperName='ThirdLevelRole', ParentRoleId=secondLevelRole.Id);
      insert thirdLevelRole;
      
      UserTestHelper uth = new UserTestHelper();

      // select a zone profile
      Profile zoneProf = [Select Id, Name from Profile where Name LIKE 'CORE ZONE ADMINISTRATION%' limit 1];
      // select a DSA profile
      Profile dsaProf = [Select Id, Name from Profile where Name in :Utilities.DSA_PROFS limit 1];
      // select a sales rep profile
      Profile repProf = [Select Id, Name from Profile where Name in :Utilities.REP_PROFS limit 1];

      // select running user information      
      User runningUser = uth.getUserById(UserInfo.getUserId());
      // create a "Zone" user
      User zoneUser = uth.createUser(1, zoneProf, firstLevelRole, runningUser);
      insert zoneUser;
      // create a "DSA" user
      User dsaUser = uth.createUser(2, dsaProf, secondLevelRole, runningUser);
      insert dsaUser;
      // verify that DSA fields on user remain null
      dsaUser = [Select Id, Name, DSA_FSS__c, Profile.Name, UserRole.ParentRoleId from User where Id = :dsaUser.Id];
      System.assertEquals(dsaUser.DSA_FSS__c, null);
      
      // create a "REP" users
      User repUser1 = uth.createUser(3, repProf, thirdLevelRole, runningUser);
      User repUser2 = uth.createUser(4, repProf, thirdLevelRole, runningUser);
      User repUser3 = uth.createUser(5, repProf, thirdLevelRole, runningUser);

      User sysAdminUser = [Select Id, Name, Profile.Name, UserRole.ParentRoleId from User where IsActive=true and Profile.Name=:Utilities.PROF_SYS_ADMIN limit 1];
      
      UserHelper uh = new UserHelper();
      // pass in a regular system admin user - should get nothing
      User testU = uh.getDSA(sysAdminUser);
      System.assertEquals(null,testU);
      // pass in zone user should get nothing
      testU = uh.getDSA(zoneUser);
      System.assertEquals(null,testU);
      // pass in district user - should get nothing
      testU = uh.getDSA(dsaUser);
      System.assertEquals(null,testU);
      // pass in rep user - should get the district user back
      testU = uh.getDSA(repUser1);
      System.assertEquals(dsaUser.Id,testU.Id);
      
      // setup a user with the second level role but the sales rep profile to hit the exception clause in the query
      User badRepUser = uth.createUser(4, repProf, secondLevelRole, runningUser);
      testU = uh.getDSA(badRepUser);
      System.assertEquals(null,testU);

      //User[] repUsers = new User[]{repUser1,repUser2,repUser3};
      //insert repUsers;
      // reselect and check the DSA information
      //User checkUser1 = [Select Id, DSA_FSS__c from User where Id = :repUser1.Id];
      //System.assertEquals(checkUser1.DSA_FSS__c, dsaUser.Id);
      //User checkUser2 = [Select Id, DSA_FSS__c from User where Id = :repUser2.Id];
      //System.assertEquals(checkUser2.DSA_FSS__c, dsaUser.Id);
      //User checkUser3 = [Select Id, DSA_FSS__c from User where Id = :repUser2.Id];
      //System.assertEquals(checkUser3.DSA_FSS__c, dsaUser.Id);
      
      //System.debug('Setting '+dsaUser.Name+' to InActive');
      // inactivate the DSA
      //dsaUser.IsActive = false;
      //update dsaUser;
      // make sure DSA is removed from the other users.
      // reselect and check the DSA information
      //checkUser1 = [Select Id, DSA_FSS__c from User where Id = :repUser1.Id];
      //System.assertEquals(checkUser1.DSA_FSS__c, null);
      //checkUser2 = [Select Id, DSA_FSS__c from User where Id = :repUser2.Id];
      //System.assertEquals(checkUser2.DSA_FSS__c, null);
      //checkUser3 = [Select Id, DSA_FSS__c from User where Id = :repUser2.Id];
      //System.assertEquals(checkUser3.DSA_FSS__c, null);
   } // testGetDsa

   static testMethod void testCheckForDSA() {
      selectDsaAndReps();

      // setup the structure
      Org_Unit__c district = new Org_Unit__c(Name='12',Org_Unit_Name__c='Test District', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Sales_Org__c=UserHelper.SO_CORE, Assistant__c=v_dsa.Id
                                 ,UserRoleId__c=v_dsa.UserRoleId, RepUserRoleId__c=v_reps[0].UserRoleId);
      insert district;
      
      UserHelper.SKIP_USER_TRIGGERS = false;
      System.runAs(v_runningUser) {
         update v_reps;
      } // System.runAs
      
      User u1 = [Select Id, DSA_FSS__c from User where Id=:v_reps[0].Id];
      System.assertEquals(u1.DSA_FSS__c,v_dsa.Id);
      
      User u2 = [Select Id, DSA_FSS__c from User where Id=:v_reps[1].Id];
      System.assertEquals(u2.DSA_FSS__c,v_dsa.Id);
      User u3 = [Select Id, DSA_FSS__c from User where Id=:v_reps[2].Id];
      System.assertEquals(u3.DSA_FSS__c,v_dsa.Id);
      User u4 = [Select Id, DSA_FSS__c from User where Id=:v_reps[3].Id];
      System.assertEquals(u4.DSA_FSS__c,v_dsa.Id);
      User u6 = [Select Id, DSA_FSS__c from User where Id=:v_rep6.Id];
      System.assertEquals(u6.DSA_FSS__c,null);
   } // testCheckForDSA

   // Test the getProfile method. 
   static testMethod void testGetProfile() {
      // test for a standard profile
      Profile prof = UserHelper.getProfile('Standard User',true);
      System.assertEquals(true,(prof != null));
      
      // bad profile
      prof = UserHelper.getProfile('This Profile Does Not Exist',true);
      System.assertEquals(true,(prof == null));
   } // testGetProfile
   
   static testMethod void testGetRoleType() {
      System.assertEquals(null,UserHelper.getRoleType(null));
      System.assertEquals(null,UserHelper.getRoleType('Bad Value'));
      System.assertEquals(UserHelper.JOB_REP,UserHelper.getRoleType('Sales Rep Role'));
      System.assertEquals(UserHelper.JOB_REP,UserHelper.getRoleType('Sales Rep'));
      System.assertEquals(UserHelper.ORG_DISTRICT,UserHelper.getRoleType(UserHelper.ORG_DISTRICT+' Role'));
      System.assertEquals(UserHelper.ORG_ZONE,UserHelper.getRoleType(UserHelper.ORG_ZONE+' Role'));
      System.assertEquals(UserHelper.ORG_ZONE,UserHelper.getRoleType('Region Role'));
      System.assertEquals(UserHelper.ORG_AREA,UserHelper.getRoleType('CORE AVP Role'));
      System.assertEquals(UserHelper.ORG_AREA,UserHelper.getRoleType('HRS SR DIR Role'));
      System.assertEquals(UserHelper.JOB_NSR,UserHelper.getRoleType('NSS INBOUND REP'));
      System.assertEquals(UserHelper.JOB_NSS_SUPER,UserHelper.getRoleType('NSS INBOUND SUPERVISOR'));
   } // testGetRoleType
   
   
   static testMethod void testJobName() {
      
      // get users matching the different criteria
      User rep = [Select Id, Job_Name__c from User where Sales_Org__c in :UserHelper.DIVISION_LIST_SET and UserRole.Name like '%SALES REP%' and IsActive=true and Job_Name__c != null limit 1];
      String typeDistrict = '%'+UserHelper.ORG_DISTRICT+'%';
      //User dsa = [Select Id, Job_Name__c from User where Sales_Org__c in :UserHelper.DIVISION_LIST_SET and UserRole.Name like :typeDistrict and Profile.Name in :Utilities.DSA_PROFS and IsActive=true limit 1 ];
      User dsm = [Select Id, Job_Name__c from User where Sales_Org__c in :UserHelper.DIVISION_LIST_SET and UserRole.Name like :typeDistrict and Profile.Name in :Utilities.DSM_PROFS and IsActive=true limit 1 ];
      String typeZone = '%'+UserHelper.ORG_ZONE+'%';
      User zsa = [Select Id, Job_Name__c from User where Sales_Org__c in :UserHelper.DIVISION_LIST_SET and UserRole.Name like :typeZone and Profile.Name in :Utilities.ZSA_PROFS and IsActive=true limit 1 ];
      User zsm = [Select Id, Job_Name__c from User where Sales_Org__c in :UserHelper.DIVISION_LIST_SET and UserRole.Name like :typeZone and Profile.Name in :Utilities.ZSM_PROFS and IsActive=true limit 1 ];
      User otherUser = [Select Id, Job_Name__c, ProfileId, Profile.Name from User where IsActive = true and Sales_Org__c not in :UserHelper.DIVISION_LIST_SET and Job_Name__c = null limit 1];
      //User otherUser2 = [Select Id, Job_Name__c, Profile.Name from User where IsActive = true and Sales_Org__c not in :UserHelper.DIVISION_LIST_SET and Job_Name__c = null and ProfileId != :otherUser.ProfileId limit 1];

      // to set it by the code
      //Profile_List__c profRec = new Profile_List__c(Name=otherUser2.Profile.Name, Profile_Name__c=otherUser2.Profile.Name, JobName__c='TestJobName');
      //insert profRec;

      // update sales org to a test value
      UserHelper.JOB_DIVISION_SET = new Set<String>{'TESTSALESORG1'};
      rep.Sales_Org__c = 'TESTSALESORG1';
      //dsa.Sales_Org__c = 'TESTSALESORG1';
      dsm.Sales_Org__c = 'TESTSALESORG1';
      zsa.Sales_Org__c = 'TESTSALESORG1';
      zsm.Sales_Org__c = 'TESTSALESORG1';
      //User[] users = new User[]{rep,dsa,dsm,zsa,zsm,otherUser}; //,otherUser2};
      User[] users = new User[]{rep,dsm,zsa,zsm,otherUser}; //,otherUser2};
      Test.startTest();
      update users;
      Test.stopTest();
      
      Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, Job_Name__c from User where Id in :users]);
      
      verifyJobName(userMap.get(rep.Id),UserHelper.JOB_REP);
      //verifyJobName(userMap.get(dsa.Id),UserHelper.JOB_DSA);
      verifyJobName(userMap.get(dsm.Id),UserHelper.JOB_DSM);
      verifyJobName(userMap.get(zsa.Id),UserHelper.JOB_ZSA);
      verifyJobName(userMap.get(zsm.Id),UserHelper.JOB_ZSM);
      verifyJobName(userMap.get(otherUser.Id),null);
      //verifyJobName(userMap.get(otherUser2.Id),profRec.JobName__c);
      
   } // testJobName

   private static void verifyJobName(User usr, String jobName) {
      System.assertEquals(jobName, usr.Job_Name__c);
   } // verifyJobName

   // test the job name field using the custom metadata 
   static testMethod void testJobNameMetadataAny() {
      //checkJobName('any');
   } // testJobNameMetadataAnyc

   static testMethod void testJobNameMetadataEquals() {
      checkJobName('=');
   } // testJobNameMetadataEquals
   
   static testMethod void testJobNameMetadataContains() {
      checkJobName('contains');
   } // testJobNameMetadataContains

   public static void checkJobName(String filterType) {
      // test any user
      JobMap__mdt[] jobMaps = [Select FilterType__c, JobName__c, ProfileName__c, RoleValue__c from JobMap__mdt where FilterType__c=:filterType];
      JobMap__mdt foundJobMap = null;
      // look for a user that meets the criteria
      User usr = null;
      for (JobMap__mdt jobMap : jobMaps) {
         try {
            if (filterType == 'any') {
               usr = [Select Id, LastName, Job_Name__c, ProfileId, UserRoleId from User where IsActive=true and Profile.Name = :jobMap.ProfileName__c limit 1];
            } else if (filterType == '=') {
               usr = [Select Id, LastName, Job_Name__c, ProfileId, UserRoleId from User where IsActive=true and Profile.Name = :jobMap.ProfileName__c and UserRole.Name = :jobMap.RoleValue__c limit 1];
            } else if (filterType == 'contains') {
               String roleValue = '%'+jobMap.RoleValue__c+'%';
               usr = [Select Id, LastName, Job_Name__c, ProfileId, UserRoleId from User where IsActive=true and Profile.Name = :jobMap.ProfileName__c and UserRole.Name like :roleValue limit 1];
            } 
            foundJobMap = jobMap;
            break;
         } catch (Exception e) {
            // do nothing
         }
      }
      
      System.assertNotEquals(null,foundJobMap);
      System.assertNotEquals(null,usr);
      usr.Job_Name__c = null;
      
      // to make sure it's using the metadata type
      UserHelper.SKIP_LEGACY_CHECK=true;
      UserHelper.checkForJobName(new User[]{usr});
      System.assertEquals(foundJobMap.JobName__c,usr.Job_Name__c);

   } // checkJobName
   

   static testMethod void testGetRunningUser() {
      User runningUser = UserHelper.getRunningUser();
      System.assertEquals(UserInfo.getUserId(), runningUser.Id);
   } // testGetRunningUser

   static testMethod void testGetUserMap() {
      Map<Id,User> userIdMap = new Map<Id,User>([Select Id, Name from User where IsActive=true limit 10]);
      Map<Id,User> userIdTestMap = UserHelper.getUserMapById(userIdMap.keySet());
      
      // verify they're the same size
      System.assertEquals(10,userIdMap.size());
      System.assertEquals(10,userIdTestMap.size());
      for (User u : userIdMap.values()) {
         System.assertEquals(true,userIdTestMap.containsKey(u.Id));
      }
   } // testGetUserMap
   
   static testMethod void testGetUserRoleMap() {
      // hopefully the core zone 1 name won't change
      //Map<String,UserRole> userRoleMap = UserHelper.getUserRoleMap('CORE ZONE 1');
       Map<String,UserRole> userRoleMap = UserHelper.getUserRoleMap(Label.UserHelperTest_RoleMapTest);
      // make sure values are returned
      System.assertEquals(true,userRoleMap.size() > 1);
      
      System.assertEquals(null,UserHelper.getRoleByName('ThisIsABadRoleName'));
      
      
      User u1 = [Select Id, Name, Profile.Name from User where Profile.Name=:Utilities.PROF_SYS_ADMIN limit 1];
      System.assertEquals(true,UserHelper.isSystemAdmin(u1));
      User u2 = [Select Id, Name, Profile.Name from User where Profile.Name in :Utilities.REP_PROFS limit 1];
      System.assertEquals(false,UserHelper.isSystemAdmin(u2));
      
      System.assertEquals(false,UserHelper.isNSSInboundProf(null));
      System.assertEquals(false,UserHelper.isNSSInboundProf(Utilities.PROF_SYS_ADMIN));
      System.assertEquals(true,UserHelper.isNSSInboundProf(UserHelper.PROF_NSS_INBOUND));

      System.assertEquals(false,UserHelper.isNSSOutboundProf(null));
      System.assertEquals(false,UserHelper.isNSSOutboundProf(Utilities.PROF_SYS_ADMIN));
      System.assertEquals(true,UserHelper.isNSSOutboundProf(UserHelper.PROF_NSS_OUTBOUND));
      
      System.assertEquals(false,UserHelper.isNSSOutboundProf(null));
      System.assertEquals(false,UserHelper.isNSSOutboundProf(Utilities.PROF_SYS_ADMIN));
      System.assertEquals(true,UserHelper.isNSSOutboundProf(UserHelper.PROF_NSS_OUTBOUND));
   } // testGetUserRoleMap
   
   static testMethod void testRunningUserAttributes() {
      setupProcessName(UserHelper.PREFIX_SFDC, UserInfo.getName());
      setupProcessName(UserHelper.PREFIX_RJ, UserInfo.getName());
      setupProcessName(UserHelper.PREFIX_LL, UserInfo.getName());
      UserHelper.setRunningUserAttributes();
      System.assertEquals(true,UserHelper.runningUserIsLeadLoader);
      System.assertEquals(true,UserHelper.runningUserIsRelationalJunction);
      System.assertEquals(true,UserHelper.runningUserIsSfdcData);
      
   } // testRunningUserAttributes
   
   static testMethod void testGetRunningUserType() {
      System.assertEquals(UserHelper.TYPE_USER,UserHelper.getRunningUserType());
      
      setupProcessName(UserHelper.PREFIX_SFDC, UserInfo.getName());
      // reset value so it's recalculated
      UserHelper.currentRunningUserId = null;
      System.assertEquals(UserHelper.TYPE_SFDC_DATA,UserHelper.getRunningUserType());
      
      // reset value so it's recalculated
      UserHelper.currentRunningUserId = null;
      clearProcessNames();
      setupProcessName(UserHelper.PREFIX_RJ, UserInfo.getName());
      System.assertEquals(UserHelper.TYPE_REL_JUNC,UserHelper.getRunningUserType());
      
      // reset value so it's recalculated
      UserHelper.currentRunningUserId = null;
      clearProcessNames();
      setupProcessName(UserHelper.PREFIX_LL, UserInfo.getName());
      System.assertEquals(UserHelper.TYPE_LEAD_LOAD,UserHelper.getRunningUserType());
      
   } // testRunningUserAttributes

   static testMethod void testRunningUserIsSystemAdmin() {
      User testUser = [Select Id, Name from User where Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true limit 1];
      System.runAs(testUser) {
         System.assertEquals(true,UserHelper.isRunningUserSystemAdmin());
      }
      UserHelper.getReferralOwner();
   } // testRunningUserIsSystemAdmin

   static testMethod void testRoleChange() {
      // select 2 reps in different roles
      User salesRep1 = [Select Id, District__c, Name, UserRoleId from User where IsActive=true and Profile.Name in :Utilities.CORE_PROFS and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User salesRep2 = [Select Id, District__c, Name, UserRoleId from User where IsActive=true and Profile.Name in :Utilities.CORE_PROFS and Sales_Org__c=:UserHelper.SO_CORE and UserRoleId != :salesRep1.UserRoleId limit 1];
      
      // create district org units for each user
      Org_Unit__c dist1 = new Org_Unit__c(Name=salesRep1.District__c, Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, RepUserRoleId__c=salesRep1.UserRoleId);
      Org_Unit__c dist2 = new Org_Unit__c(Name=salesRep2.District__c, Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, RepUserRoleId__c=salesRep2.UserRoleId);
      Org_Unit__c[] districts = new Org_Unit__c[]{dist1,dist2};
      insert districts;
      
      // execute the REST code
      Id[] userIds = new Id[]{salesRep1.Id};
      UserRoleUpdateRest.doPost(userIds);
      
      // should be just the one record
      Org_Unit_User_Link__c ouul = [Select Id, Org_Unit__c, User__c from Org_Unit_User_Link__c where Org_Unit__c=:dist1.Id and User__c=:salesRep1.Id];
      // change the user t= salesrep2 to make it think the role changed.
      ouul.User__c = salesRep2.Id;
      update ouul;
      
      //System.assertEquals(1,[select count() from Org_Unit_User_Link__c where Org_Unit__c=:dist1.Id]);

      // just to fire the trigger
      //User runningUser = UserHelper.getRunningUser();
      //System.runAs(runningUser) {
      //   salesRep1.UserRoleId = salesRep2.UserRoleId;
      //   update salesRep1;
      //} // System.runAs
      
      // execute the REST code again - this time for salesrep2
      userIds = new Id[]{salesRep2.Id};
      UserRoleUpdateRest.doPost(userIds);
      System.assertEquals(0,[select count() from Org_Unit_User_Link__c where Org_Unit__c=:dist1.Id]);
      System.assertEquals(1,[select count() from Org_Unit_User_Link__c where Org_Unit__c=:dist2.Id]);


   } // testRoleChange

   static testMethod void testIsUserVisible() {
      selectDsaAndReps();
      
      // system admin sees everyone - basic test
      System.assertEquals(true,UserHelper.isUserVisible(v_runningUser,v_reps[0].Id,true));
      // test dsa seeing someone in their hierarchy
      System.assertEquals(true,UserHelper.isUserVisible(v_dsa,v_reps[0].Id,true));
      // test dsa seeing someone outside their hierarchy
      System.assertEquals(false,UserHelper.isUserVisible(v_dsa,v_rep6.Id,true));
      
      // setup so the first dsa can see the second rep via the org unit override
      Org_Unit__c district = new Org_Unit__c(Name=v_rep6.District__c, Org_Unit_Name__c=v_rep6.District_Name__c
                                         ,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, UserRoleName__c=v_dsa2.UserRole.Name
                                         ,UserRoleId__c=v_dsa2.UserRoleId,OverrideUserRoleName__c=true
                                         ,Sales_Org__c=v_rep6.Sales_Org__c
                                         );
      insert district;
      district = [Select Id, Name, Query_Key__c from Org_Unit__c where Id=:district.Id];
      // update the manage user field on the 
      v_dsa.ManageZipOrgUnitsManaged__c = district.Query_Key__c;
      
      // clear the map so it reselects the user information.
      UserHelper.visibleRoleIdByUserIdMap.clear();
      System.assertEquals(true,UserHelper.isUserVisible(v_dsa,v_rep6.Id,true));
      
   } // testIsUserVisible
   
   static testMethod void testInactiveUser() {
      User testUser = [Select Id, Name, DSA_FSS__c from User where IsActive=true and DSA_FSS__c != null limit 1];
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         UserTriggerMethods.checkInactiveUser(new Id[]{testUser.Id});
      }
      //testUser = [Select Id, Name, DSA_FSS__c from User where Id=:testUser.Id];
      //System.assertEquals(null,testUser.DSA_FSS__c);
   } // testInactiveUser
   
   static testMethod void testGetContactMapByEmail() {
      Contact ctct1 = new Contact(LastName='Test1', Email='test1@testing.com', HR_Person_Id__c='1');
      Contact ctct2 = new Contact(LastName='Test2', Email='test2@testing.com', HR_Person_Id__c='2');
      Contact ctct3 = new Contact(LastName='Test3', Email='test3@testing.com', HR_Person_Id__c='3');
      Contact ctct4 = new Contact(LastName='Test4', Email='test4@testing.com', HR_Person_Id__c='4');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      Set<String> emailSet = new Set<String>();
      emailSet.add(ctct1.Email);
      emailSet.add(ctct2.Email);
      emailSet.add(ctct3.Email);
      emailSet.add(ctct4.Email);
      emailSet.add('thisabademail@testing.com');
      
      Map<String,Contact> emailMap = UserHelper.getContactMapByEmail(emailSet);
      System.assertEquals(4,emailMap.size());
      System.assertEquals(ctct1.Id, emailMap.get(ctct1.Email).Id);
      System.assertEquals(ctct2.Id, emailMap.get(ctct2.Email).Id);
      System.assertEquals(ctct3.Id, emailMap.get(ctct3.Email).Id);
      System.assertEquals(ctct4.Id, emailMap.get(ctct4.Email).Id);
   } // testGetContactMapByEmail
   
   static testMethod void testPEOEmail() {
      // create a new PEO User
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey 
                            ,UserRoleId, ProfileId
                        from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = 'jaffe@paychex.com.jaffe'
                        ,Email = 'jaffe@paychex.com.jaffe'
                        ,Sales_Org__c = UserHelper.SO_PEO
                        ,IsActive = true
                        ,Hire_Date__c = Date.today()
                        ,ManagerId = null
                        ,Department = 'Test Dept'
                        ,Alias = 'jaffe'
                        ,CommunityNickname = 'jaffe'
                        ,MobilePhone = '585-123-6544'
                        ,Phone = '585-123-6543'
                        ,Street = '123 Some St'
                        ,City = 'Somewhere'
                        ,PostalCode = '14514'
                        ,State = 'NY'
                        ,UserRoleId = curUser.UserRoleId
                        ,ProfileId = curUser.ProfileId
                        ,Creation_Type__c = 'NewUser'
                        );
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      Test.startTest();
      insert u1;
      Test.stopTest();
      
      System.assertEquals(1,UserTriggerMethods.nbrPeoEmails);

   } // testPEOEmail
 
  static testMethod void setFederationID(){
    User runningUser = UserHelper.getRunningUser();
    user u1 = [Select Id, District__c, Name, Schedule_Indicator__c, FederationIdentifier, HR_Person_Id__c, IsActive,ProfileId,Profile.name, License_Type__c, UserRoleId, Sales_Org__c from User where IsActive=false and HR_Person_Id__c != null and Profile.Name in :Utilities.CORE_PROFS and Sales_Org__c=:UserHelper.SO_CORE limit 1];
 
    u1.HR_Person_Id__c = '99'; 
      Contact ctct1 = new Contact(LastName='testLN', Email='test1@testing.com', HR_Person_Id__c= '99', User_Lookup__c = u1.id);
      
    u1.IsActive = true;
    insert ctct1;
      
    System.runAs(runningUser) {
        test.startTest();
        update u1;
        test.stopTest();
    } // System.runAs
    
    user updatedUser = [select id,FederationIdentifier,HR_Person_Id__c from user where id =: u1.id];  
      
    system.assert(updatedUser.FederationIdentifier == updatedUser.HR_Person_Id__c);
             
    }//setFederationID    
   
    static testMethod void testQueryAndMore() {
       setupSalesOrgSetting();

       String query = UserHelper.getCPQUserQuery();
       System.assertNotEquals(null,query);
        
       UserHelper uh = new UserHelper();

       String[] topSalesRoles = Label.OrgUnitMethods_TopLevels.split(',');
        
       UserRole role = [Select Id, Name from UserRole where Name in :topSalesRoles limit 1];
       Map<Id,UserRole> roleMap = UserHelper.getUserRoleByIdMap(role.Id);

       Map<String,UserRole> byNameMap = new Map<String,UserRole>(); 
       Map<Id,UserRole[]> byParentIdMap = new Map<Id,UserRole[]>();
       Map<Id,UserRole> byIdMap = new Map<Id,UserRole>();
       UserHelper.findUserRoles(topSalesRoles, byNameMap, byParentIdMap, byIdMap);
        
       // select some users to get some profiles
       User[] users = [Select Id, ProfileId, Profile.Id, Profile.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 30];
       Set<String> profileSet = new Set<String>();
       for (User usr : users) {
           profileSet.add(usr.Profile.Name);
       }
       String[] profiles = new String[]{};
       profiles.addAll(profileSet);

       Profile[] profs = UserHelper.getProfiles(profiles, false);
       System.assertEquals(profiles.size(), profs.size()); 
       
       System.assertEquals(false,UserHelper.isRunningUserGuest());
        
       SalesOrg__c soHRS = SalesOrg__c.getInstance(UserHelper.SO_401);
       String teamRole = UserHelper.getTeamRole(UserHelper.SO_401, 'FakeSegment');
       System.assertEquals(soHRS.TeamRole__c, teamRole);

       System.assertEquals(true, uh.isTAA(UserHelper.SO_TAA));
       System.assertEquals(false, uh.isTAA('BadSalesOrg'));

       System.assertEquals(true, uh.isPC(UserHelper.SO_PC));
       System.assertEquals(false, uh.isPC('BadSalesOrg'));

       System.assertEquals(true, uh.isMS(UserHelper.SO_MS));
       System.assertEquals(false, uh.isMS('BadSalesOrg'));

       System.assertEquals(true, uh.isESR(UserHelper.SO_ESR));
       System.assertEquals(false, uh.isESR('BadSalesOrg'));

       System.assertEquals(true, uh.isPBA(UserHelper.SO_PBA));
       System.assertEquals(false, uh.isPBA('BadSalesOrg'));

    } // testQueryAndMore
    
} // UserHelperTest