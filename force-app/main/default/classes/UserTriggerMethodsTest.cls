/* 
* The test methods for the UserTriggerMethods class.
*
* History
* -------
  06/04/2020 Dan Carmen         Created
  07/22/2021 Dan Carmen   Add check for HR_Services_Partner__c to inactive user check
  02/01/2022 Jake Hinds   testCommCheckIfComplete
  02/05/2022 Jaipal       testgeneratePeoEMail
  02/12/2022 Jaipal       testgenerateDSMEMail
  08/03/2022 Dan Carmen   Add check for profiles for the before insert trigger since the usertype isn't set. 
  03/06/2023 Carrie Marciano update API version
  11/17/2023 Dan Carmen      Add setAgentSyncAsyncSettings due to AgentSync Mixed Dml Issue
  01/03/2024 Dan Carmen      Add logic to link the user to the contact if updated by a particular user
  01/09/2023 Updated testCommCheckIfComplete & testCommCheckIfComplete2 asserts
*/
@isTest
public class UserTriggerMethodsTest {
    
    @testSetup
    public static void setupData() {
        FullSandbxRefreshUsersTest.setAgentSyncAsyncSettings();
    }
    
    static testMethod void testPermGroupAssignment() {
        // create a couple of permission set groups
        PermissionSetGroup psg1 = new PermissionSetGroup(MasterLabel='UserTriggerMethodsTestGroup1', DeveloperName='UserTriggerMethodsTestGroup1', Description='TestGroupForThisTest');
        PermissionSetGroup psg2 = new PermissionSetGroup(MasterLabel='UserTriggerMethodsTestGroup2', DeveloperName='UserTriggerMethodsTestGroup2', Description='TestGroupForThisTest');
        PermissionSetGroup psg3 = new PermissionSetGroup(MasterLabel='UserTriggerMethodsTestGroup3', DeveloperName='UserTriggerMethodsTestGroup3', Description='TestGroupForThisTest');
        PermissionSetGroup[] psgs = new PermissionSetGroup[]{psg1,psg2,psg3};
            
            // get a test user
            User usr = [Select Id, Name, Sales_Division__c, Profile.Name, Sales_Org__c, Job_Name__c, EvaluatePermissionSets__c from User where IsActive=true and Sales_Division__c != null and Sales_Org__c != null and Job_Name__c != null and ProfileId != null limit 1];
        Set<Id> userIdSet = new Set<Id>{usr.Id};
            
            // setup the custom setting for first 2 groups
            PermissionSetAssignment__c setting1 = new PermissionSetAssignment__c(Name='testGroup1', Active__c=true, PermissionGroupName__c=psg1.MasterLabel, ProfileNames__c=usr.Profile.Name
                                                                                 , JobNames__c=usr.Job_Name__c, SalesDivisions__c=usr.Sales_Division__c, SalesOrgs__c=usr.Sales_Org__c);
        // this one shouldn't match
        PermissionSetAssignment__c setting2 = new PermissionSetAssignment__c(Name='testGroup2', Active__c=true, PermissionGroupName__c=psg2.MasterLabel, ProfileNames__c='A Bad Profile Name,Another Bad Name'
                                                                             , JobNames__c=usr.Job_Name__c, SalesDivisions__c=usr.Sales_Division__c, SalesOrgs__c=usr.Sales_Org__c);
        // we're not setting up a custom setting for the third one so that shouldn't be touched by the trigger.
        PermissionSetAssignment__c[] settings = new PermissionSetAssignment__c[]{setting1,setting2};
            insert settings;
        
        
        
        Set<String> groupNames = new Set<String>{'UserTriggerMethodsTestGroup1','UserTriggerMethodsTestGroup2','UserTriggerMethodsTestGroup3'};
            
            User runningUser = UserHelper.getRunningUser();
        System.runAs(runningUser) {
            insert psgs;
            
            // assign the last 2 to the user
            PermissionSetAssignment psa2 = new PermissionSetAssignment(AssigneeId=usr.Id, PermissionSetGroupId=psg2.Id);
            PermissionSetAssignment psa3 = new PermissionSetAssignment(AssigneeId=usr.Id, PermissionSetGroupId=psg3.Id);
            PermissionSetAssignment[] psas = new PermissionSetAssignment[]{psa2,psa3};
                insert psas;
            
            
            usr.EvaluatePermissionSets__c = true;
            Test.startTest();
            update usr;
            Test.stopTest();
        }
        Map<Id,Map<String,PermissionSetAssignment>> permByUserMap = UserTriggerMethods.getExistingPerms(userIdSet, groupNames);
        Map<String,PermissionSetAssignment> userPermMap = permByUserMap.get(usr.Id);
        System.assertEquals(2,userPermMap.size());
        System.assertEquals(true,userPermMap.containsKey(psg1.MasterLabel));
        System.assertEquals(false,userPermMap.containsKey(psg2.MasterLabel));
        System.assertEquals(true,userPermMap.containsKey(psg3.MasterLabel));
        
    } // testPermGroupAssignment
    
    static testMethod void testFederationId() {
        User[] usrs = [Select id, FirstName, LastName, Name, HR_Person_Id__c, FederationIdentifier 
                       from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        String personId1 = usrs[0].HR_Person_Id__c;
        String personId2 = usrs[1].HR_Person_Id__c;
        //usrs[0].HR_Person_Id__c = null;
        usrs[0].FederationIdentifier = null;
        //usrs[1].HR_Person_Id__c = null;
        usrs[1].FederationIdentifier = null;
        Contact ctct = new Contact(FirstName=usrs[0].FirstName, LastName=usrs[0].LastName, HR_Person_Id__c=personId1);
        insert ctct;
        
        Test.startTest();
        update usrs;
        Test.stopTest();
        
        usrs = [Select id, FirstName, LastName, Name, HR_Person_Id__c, FederationIdentifier 
                from User where Id in :usrs];
        System.assertEquals(usrs[0].HR_Person_Id__c, usrs[0].FederationIdentifier); 
        System.assertEquals(usrs[1].HR_Person_Id__c, usrs[1].FederationIdentifier); 
        
        
    } // testFederationId 
    
    static testMethod void testFedId2() {
      // create a new PEO User
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey 
                            ,UserRoleId, ProfileId
                        from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = 'jaffe@paychex.com.jaffe'
                        ,Email = 'jaffe@paychex.com.jaffe'
                        ,Sales_Org__c = 'TEST'
                        ,IsActive = true
                        ,Alias = 'jaffe'
                        ,CommunityNickname = 'jaffe'
                        ,UserRoleId = curUser.UserRoleId
                        ,ProfileId = curUser.ProfileId
                        ,Creation_Type__c = 'UserTest'
                        ,HR_Person_id__c='42424242'
                        );
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      Test.startTest();
      insert u1;
      Test.stopTest();
        
      u1 = [Select Id, HR_Person_Id__c, FederationIdentifier from User where Id=:u1.Id];
      System.assertEquals('42424242', u1.FederationIdentifier);
              
    } // testFedId2
    
    static testMethod void testgeneratePeoEMail() {
        list< User> usr = [Select Id, Name,FirstName,LastName,Email,CSUserId__c,Username,Sales_Division__c, Profile.Name, Sales_Org__c, Job_Name__c, EvaluatePermissionSets__c,ProfileId,UserRoleId from User where IsActive=true and Sales_Division__c != null and UserRoleId!=null and Sales_Org__c =: UserHelper.SO_PEO and Job_Name__c != null and ProfileId != null limit 1];
        
        Set<Id> profileIdSet = new Set<Id>{usr[0].ProfileId};
            Set<Id> roleIdSet = new Set<Id>{usr[0].UserRoleId};
                
                Test.startTest();
        UserTriggerMethods.generatePeoEMail(usr,profileIdSet,roleIdSet);
        Test.stopTest();
        
    }
    static testMethod void testcheckinactiveusers() {
        list< User> usr = [Select Id, DSA_FSS__c, ASO_Partner__c,HR_Services_Partner__c, Name,FirstName,LastName,Email,CSUserId__c,Username,Sales_Division__c, Profile.Name, Sales_Org__c, Job_Name__c, EvaluatePermissionSets__c,ProfileId,UserRoleId from User where isactive=true and( DSA_FSS__c!= null) limit 1];
        
        list<Id> userIdSet = new list<Id>{usr[0].DSA_FSS__c};
            //Set<Id> roleIdSet = new Set<Id>{usr[0].UserRoleId};
            
            Test.startTest();
        UserTriggerMethods.checkInactiveUser(userIdSet);
        Test.stopTest();
        
    }
    static testMethod void testcheckinactiveusers1() {
        list< User> usr = [Select Id, DSA_FSS__c, ASO_Partner__c,HR_Services_Partner__c, Name,FirstName,LastName,Email,CSUserId__c,Username,Sales_Division__c, Profile.Name, Sales_Org__c, Job_Name__c, EvaluatePermissionSets__c,ProfileId,UserRoleId from User where isactive=true and( ASO_Partner__c !=null) limit 1];
        
        list<Id> userIdSet = new list<Id>{usr[0].ASO_Partner__c};
            //Set<Id> roleIdSet = new Set<Id>{usr[0].UserRoleId};
            
            Test.startTest();
        UserTriggerMethods.checkInactiveUser(userIdSet);
        Test.stopTest();
        
    }
    static testMethod void testgenerateDSMEMail() {
        list< User> usr = [Select Id, Name,FirstName,LastName,Email,CSUserId__c,Username,Sales_Division__c,ManagerId, Profile.Name, Sales_Org__c, Job_Name__c,EmailPreferencesAutoBcc, Securities_License__c, EvaluatePermissionSets__c,ProfileId,UserRoleId from User where EmailPreferencesAutoBcc = false and Securities_License__c= True limit 1];
        
        
        Test.startTest();
        UserTriggerMethods.generateDSMEMail(usr);
        Test.stopTest();
        
    }
    static testMethod void testcheckADUsername() {
        list< User> usr = [Select Id, Name,FirstName,AD_Username__c,EBS_Username__c,LastName,Email,CSUserId__c,Username,Sales_Division__c, Profile.Name, Sales_Org__c, Job_Name__c, EvaluatePermissionSets__c,ProfileId,UserRoleId from User where IsActive=true and Sales_Division__c != null and UserRoleId!=null and Sales_Org__c =: UserHelper.SO_PEO and Job_Name__c != null and ProfileId != null limit 1];
        
        Set<Id> profileIdSet = new Set<Id>{usr[0].ProfileId};
            Set<Id> roleIdSet = new Set<Id>{usr[0].UserRoleId};
                
                Test.startTest();
        UserTriggerMethods.checkADUsername(usr[0]);
        UserTriggerMethods.checkEbsUsername(usr[0]);
        Test.stopTest();
        
    }
    
    static testMethod void testCommCheckIfComplete() {
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        
        Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing@testingtestTest.com'); 
        insert ctct;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone' LIMIT 1];
        User otherAdmin = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id!=:UserInfo.getUserId() LIMIT 1];
        
        
        
        PEO_Onboarding_Checklist__c newChecklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c = acc.Id);
        insert newChecklist;
        Test.startTest();
        system.runAs(otherAdmin){
            User testUser = new User(
                UserName = ctct.email,
                FirstName = ctct.FirstName,
                LastName =ctct.LastName,
                Alias = 'alias',
                email = ctct.Email,
                ContactId = ctct.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS'
            );
            
            insert testUser;
            testUser.Community_User_First_Login__c = system.now();
            update testUser;
        }
        
        Test.stopTest();
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Id = :newChecklist.Id LIMIT 1];
        //Last_Change_Made__c can be updated only by non-admin users
        system.assert(uChecklist!=null && uChecklist.Last_Change_Made__c == null);
    } // testCommCheckIfComplete
   
    
     static testMethod void testFedId3() {
      // create a new PEO User
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey 
                            ,UserRoleId, ProfileId
                        from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = 'jaffe@paychex.com.jaffe'
                        ,Email = 'jaffe@paychex.com.jaffe'
                        ,Sales_Org__c = 'TEST'
                        ,IsActive = true
                        ,Alias = 'jaffe'
                        ,CommunityNickname = 'jaffe'
                        ,UserRoleId = curUser.UserRoleId
                        ,ProfileId = curUser.ProfileId
                        ,Creation_Type__c = 'UserTest'
                        ,
                         EmployeeNumber='00121214'
                        );
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      Test.startTest();
         insert u1;
         u1.IsActive =false;
         Update u1;
      Test.stopTest();
        
      u1 = [Select Id, HR_Person_Id__c, FederationIdentifier from User where Id=:u1.Id];
      //System.assertEquals('42424242', u1.FederationIdentifier);
              
    }
    
    
         static testMethod void testFedId4() {
      // create a new PEO User
      User curUser = [Select Id, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, LanguageLocaleKey 
                            ,UserRoleId, ProfileId
                        from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User u1 = new User(FirstName = 'Jaffe'
                        ,LastName = 'Joffer'
                        ,Title = 'King'
                        ,Username = 'jaffe@paychex.com.jaffe'
                        ,Email = 'jaffe@paychex.com.jaffe'
                        ,Sales_Org__c = 'TEST'
                        ,IsActive = true
                        ,Alias = 'jaffe'
                        ,CommunityNickname = 'jaffe'
                        ,UserRoleId = curUser.UserRoleId
                        ,ProfileId = curUser.ProfileId
                        ,Creation_Type__c = 'UserTest'
                        ,EmployeeNumber='00121214'
                        //,agentsync__NPN__c='123567'
                        );
      u1.TimeZoneSidKey = curUser.TimeZoneSidKey;
      u1.LocaleSidKey = curUser.LocaleSidKey;
      u1.EmailEncodingKey = curUser.EmailEncodingKey;
      u1.LanguageLocaleKey = curUser.LanguageLocaleKey;
      insert u1;
      Test.startTest();
         u1.IsActive =false;
         Update u1;
      Test.stopTest();
        
      u1 = [Select Id, HR_Person_Id__c, FederationIdentifier from User where Id=:u1.Id];
      //System.assertEquals('42424242', u1.FederationIdentifier);
              
    }
    
    static testMethod void testCommCheckIfComplete2() {
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        
        Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing@testingtestTest.com'); 
        insert ctct;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone' LIMIT 1];
        User otherAdmin = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id!=:UserInfo.getUserId() LIMIT 1];
        
        
        
        PEO_Onboarding_Checklist__c newChecklist = new PEO_Onboarding_Checklist__c(Name='test checklist',Prospect_Client__c = acc.Id);
        insert newChecklist;
        Test.startTest();
        system.runAs(otherAdmin){
            User testUser = new User(
                UserName = ctct.email,
                FirstName = ctct.FirstName,
                LastName =ctct.LastName,
                Alias = 'alias',
                email = ctct.Email,
                ContactId = ctct.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS',
                isActive = false
            );
            
            insert testUser;
            testUser.Community_User_First_Login__c = system.now();
            update testUser;
        }
        
        Test.stopTest();
        PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Last_Change_Made__c FROM PEO_Onboarding_Checklist__c WHERE Id = :newChecklist.Id LIMIT 1];
        //Last_Change_Made__c can be updated only by non-admin users
        system.assert(uChecklist!=null && uChecklist.Last_Change_Made__c == null);
    } // testCommCheckIfComplete
    
   static testMethod void testCPAProgStatus() {
        Account acc = new Account();
        acc.Name = 'Peo test';
        insert acc;
        
        Referral_Account__c refAcc = new Referral_Account__c();
        refAcc.Name = 'Peo test';
        insert refAcc;
        
       Contact ctct = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing@testingtestTest.com'); 
       Contact ctct2 = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing2@testingtestTest.com'); 
       
       Contact ctct3 = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing3@testingtestTest.com'); 
       
       Contact ctct4 = new Contact(AccountId=acc.id,
                                   FirstName = 'test',
                                   LastName = 'user',
                                   Email='testing4@testingtestTest.com'); 
       insert new Contact[]{ctct,ctct2,ctct3,ctct4};
       
       Referral_Contact__c refCon = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                           First_Name__c = 'test',
                                                           Last_Name__c = 'user',
                                                           Email__c = 'testing@testingtestTest.com',
                                                           Contact__c = ctct.Id);

       Referral_Contact__c refCon2 = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                            First_Name__c = 'test',
                                                            Last_Name__c = 'user',
                                                            Email__c = 'testing2@testingtestTest.com',
                                                            Contact__c = ctct2.Id,
                                                            CPA_Program_status__c = 'Invited');
       Referral_Contact__c refCon3 = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                            First_Name__c = 'test',
                                                            Last_Name__c = 'user',
                                                            Email__c = 'testing3@testingtestTest.com',
                                                            Contact__c = ctct3.Id,
                                                            CPA_Program_status__c = 'Invited');
       
       Referral_Contact__c refCon4 = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                            First_Name__c = 'test',
                                                            Last_Name__c = 'user',
                                                            Email__c = 'testing4@testingtestTest.com',
                                                            Contact__c = ctct4.Id,
                                                            CPA_Program_status__c = 'Invited');
       insert new Referral_Contact__c[]{refCon,refCon2,refCon3,refCon4};
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone' LIMIT 1];
        User otherAdmin = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id!=:UserInfo.getUserId() LIMIT 1];
        
        Test.startTest();
        system.runAs(otherAdmin){
            User testUser = new User(
                UserName = ctct.email,
                FirstName = ctct.FirstName,
                LastName =ctct.LastName,
                Alias = 'alias',
                email = ctct.Email,
                ContactId = ctct.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS'
            );
            
            User testUser2 = new User(
                UserName = ctct2.email,
                FirstName = ctct2.FirstName,
                LastName =ctct2.LastName,
                Alias = 'alias',
                email = ctct2.Email,
                ContactId = ctct2.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName2',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS',
                Requested_Invite_Date__c = System.now(),
                Community_User_First_Login__c = system.now()
            );
            
            User testUser3 = new User(
                UserName = ctct3.email,
                FirstName = ctct3.FirstName,
                LastName =ctct3.LastName,
                Alias = 'alias',
                email = ctct3.Email,
                ContactId = ctct3.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName3',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS',
                Requested_Invite_Date__c = System.now(),
                Community_User_First_Login__c = system.now(),
                IsActive = false
            );
            
            User testUser4 = new User(
                UserName = ctct4.email,
                FirstName = ctct4.FirstName,
                LastName =ctct4.LastName,
                Alias = 'alias',
                email = ctct4.Email,
                ContactId = ctct4.id,
                ProfileId = prof.Id,
                EmailEncodingKey = 'UTF-8',
                CommunityNickname = 'nickName4',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US',
                Sales_Org__c = 'PAS',
                Requested_Invite_Date__c = System.now(),
                IsActive = true
            );
            
            insert testUser;
            insert testUser2;
            insert testUser3;
            insert testUser4;
        }
        
        Test.stopTest();
    } // testCPAProgStatus
    
   static testMethod void testUserLinking() {
      // test linking a user to a contact record.
      User runningUser = UserHelper.getRunningUser();
      // setup the running user so they'll trigger the logic
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserTriggerMethods.USER_ATTR,runningUser.Name);
      // for the queueable to run
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=UserTriggerMethods.QUEUEABLE_NAME,Active__c=true);
      insert abc;
       
      //get our test users
      User[] testUsers = [Select Id, FirstName, LastName, Email, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
      Contact[] testContacts = new Contact[]{};
      Account payxAcct = new Account(Name=UserHelper.PAYCHEX_COMP);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert payxAcct;
      Map<String,User> userByPersonId = new Map<String,User>();
      
      for (User usr : testUsers) {
         userByPersonId.put(usr.HR_Person_Id__c,usr);
         Contact ctct = new Contact(AccountId=payxAcct.Id,LastName=usr.LastName, FirstName=usr.FirstName, Email=usr.Email, HR_Person_Id__c=usr.HR_Person_Id__c);
         testContacts.add(ctct);
      }
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert testContacts;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      
      Test.startTest();
      update testUsers;
      Test.stopTest();
      
      Contact[] ctcts = [Select Id, Name, FirstName, LastName, HR_Person_Id__c, User_Lookup__c from Contact where HR_Person_Id__c in :userByPersonId.keySet()];
      Assert.areEqual(testUsers.size(), ctcts.size());
      for (Contact ctct : ctcts) {
         User checkUsr = userByPersonId.get(ctct.HR_Person_Id__c);
         Assert.areEqual(checkUsr.Id, ctct.User_Lookup__c);
      }
   } // testUserLinking
    
} // UserTriggerMethodsTest