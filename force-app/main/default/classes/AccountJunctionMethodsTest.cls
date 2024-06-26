/**
 * Test method for AccountJunctionMethods
 * 
 * History
 * --------
 * 01/18/2017   Cindy Freeman   created
 * 03/22/2017   Cindy Freeman   modifed for new Account Junction code
 * 08/03/2017   Cindy Freeman   added test for Push Parent to Child code
   03/18/2019   Dan Carmen      Increase API version.
   09/03/2019   Dan Carmen      Fix query to select core sales reps
   10/19/2020 Dan Carmen         Problem with testOwnershipChanges test
   02/08/2021 Matt Fritschi		Test for removing Hold Outs when EE Count changes.
   01/04/2022 Dan Carmen         Fix with setting the child contact owners
   03/04/2022 Dan Carmen         Clean up some ownership logic
   09/06/2023 Dan Carmen         Always set SalesParentChild__c
   03/06/2024 Dan Carmen         Change deleteAcctTeams to a map to ensure ATM isn't in the list more than once.

 */
@isTest
public class AccountJunctionMethodsTest {

   @testSetup
   public static void setupData() {
      setupCustomSettings();
      populateSettings();
      ZipCheckOwnerTest.setupZipsAndSegments(true);
      //createTestAccts();
   } // setupData
   
   public static void setupCustomSettings() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'AccountJunctionMethods'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ZipCheckOwner'});
      TriggerMethodsTest.saveSetupClasses();

   } // setupCustomSettings

    // create 2 accounts then link 1 as a child to the other
    static testMethod void myUnitTest1() {
        //ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
        
        Account acct1 = new Account (name = 'Test Account1', OwnerId=reps[0].Id
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        //insert acct1;
        Account acct2 = new Account (name = 'Test Account2', OwnerId=reps[1].Id
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                               // ,BillingPostalCode = '14515'
                                ,AccountNumber = '93-1234567'
                                ,Employees__c = 105
                                ,Larkspur_401K_Assets__c = 5000
                                ,Create_Junction__c = true
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        //insert acct2;
        Account[] accts = new Account[]{acct1,acct2};
        insert accts;
        
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        Contact ctct1a = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'sLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        Contact ctct2 = new Contact(Firstname = 'Two'
                                ,Lastname = 'Last2'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'fLast2@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,Sales_Contact__c = true
                                ,AccountId=acct2.Id);                                
        Contact[] ctcts = new Contact[]{ctct1,ctct1a,ctct2};
        insert ctcts;
        
        Test.startTest();              
        acct1 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c from Account where Id = :acct1.Id];
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c from Account where Id = :acct2.Id];
        System.assertNotEquals(acct1.OwnerId, acct2.OwnerId);
        System.assertEquals(acct2.NumberOfEmployees, acct2.Employees__c);
        
        // create junction 
        acct2.SalesParent__c = acct1.Id;
        update acct2;
        
        Account_Junction__c[] acctJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c from Account_Junction__c where Child_Account__c = :acct2.Id];
        System.assertEquals(1, acctJuncList.size());        
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, isChild__c, SalesParent__c from Account where Id = :acct2.Id];
        System.assertEquals(true, acct2.isChild__c);
        System.assertEquals(acct1.OwnerId, acct2.OwnerId);
        
        Set<Id> juncIdSet = new Set<Id>();
        juncIdSet.add(acctJuncList.get(0).Id);
        AccountJunctionMethods.processParentAggregates(juncIdSet);
        acct1 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, 
                            isParent__c, Child_Count__c, Child_Assets__c, Child_Employees__c from Account where Id = :acct1.Id];        
        System.assertEquals(acct1.Employees__c + acct2.Employees__c,acct1.NumberOfEmployees);        
        System.assertEquals(true, acct1.isParent__c);
        System.assertEquals(1, acct1.Child_Count__c);
        System.assertEquals(acct2.Employees__c, acct1.Child_Employees__c);
        System.assertEquals(acct2.X401K_Assets__c, acct1.Child_Assets__c);
        
        Contact[] ctctList = [Select Id, OwnerId, Name, RecordtypeId from Contact where AccountId = :acct2.Id];
        System.assertEquals(acct1.OwnerId, ctctList[0].OwnerId);
        
        //delete child account, should delete junction
        delete acct2;
        
        acctJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c from Account_Junction__c where Child_Account__c = :acct2.Id];
        System.assertEquals(0, acctJuncList.size());  
                
        Test.stopTest();      
        
        
    } // my UnitTest1

    // create 2 accounts with sales parent set on the 2nd insert
    static testMethod void myUnitTest2() {
        //ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
    
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctMMSrt.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 55
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        // insert new account with Sales Parent populated
        Account acct2 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '94-1234567'
                                ,Use_Zip_Assignment_Rules__c = true
                                ,SalesParent__c = acct1.Id
                                ,Employees__c = 1                             
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2; 
        
        Test.startTest();  
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c, RecordTypeId 
                    from Account where Id = :acct2.Id];   
        System.assertEquals(1,acct2.NumberOfEmployees);        
        Account_Junction__c[] acctJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c from Account_Junction__c where Parent_Account__c = :acct1.Id];   
        System.assertEquals(1, acctJuncList.size());        

        // clear SalesParent and delete junction
        acct2.SalesParent__c = null;
        TriggerMethods.clearVariables();
        update acct2;
        
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, isChild__c, SalesParent__c, RecordTypeId from Account where Id = :acct2.Id];
        System.assertEquals(null, acct2.SalesParent__c);
        System.assertEquals(false, acct2.isChild__c);
        System.assertNotEquals(acct1.OwnerId, acct2.OwnerId);       
                
        acctJuncList = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c from Account_Junction__c where Child_Account__c = :acct2.Id];        
        System.assertEquals(1, acctJuncList.size());
        delete acctJuncList.get(0);
        //Set<Id> tempChildSet = new Set<Id>();
        //tempChildSet.add(acct2.Id);
        //AccountJunctionMethods.deleteAcctJunction(tempChildSet,null);        
                
        acct1 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, 
                            isParent__c, Child_Count__c, Child_Assets__c, Child_Employees__c from Account where Id = :acct1.Id];        
        System.assertEquals(acct1.Employees__c,acct1.NumberOfEmployees);        
        System.assertEquals(false, acct1.isParent__c);
        System.assertEquals(0, acct1.Child_Count__c);
        System.assertEquals(0, acct1.Child_Employees__c);
        System.assertEquals(0, acct1.Child_Assets__c);
        
        Test.stopTest();
                
    } //myUnitTest2

        // create 2 accounts with sales parent set on the 2nd insert then update child employees
    static testMethod void myUnitTest3() {
        //ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
    
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 5
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        // insert new account with Sales Parent populated
        Account acct2 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '94-1234567'
                                ,SalesParent__c = acct1.Id
                                ,Employees__c = 1                             
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2; 
        
        Test.startTest();  
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct2.Id];  
        acct2.Employees__c = 10;
        acct2.Larkspur_401K_Assets__c = 5000;
        update acct2;
        
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct2.Id];   
        System.assertEquals(10,acct2.Employees__c);
        //System.assertEquals(10,acct2.NumberOfEmployees);
        
        Set<Id> childSet = new Set<Id>();
        childSet.add(acct2.Id);
        AccountJunctionMethods.upsertAcctJunction(childSet,Label.AccountJunctionDefaultType);

        Account_Junction__c acctJuncBefore = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                from Account_Junction__c where Child_Account__c = :acct2.Id];  
        Set<Id> juncIdSet = new Set<Id>();
        juncIdSet.add(acctJuncBefore.Id);
        AccountJunctionMethods.processParentAggregates(juncIdSet);
        
        Account_Junction__c acctJunc = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c 
                                                from Account_Junction__c where Child_Account__c = :acct2.Id];  
        System.assertEquals(acct2.Employees__c,acctJunc.Employees__c);      
        //System.assertEquals(acct2.X401K_Assets__c, acctJunc.Assets__c);
        System.assertEquals(acct2.Larkspur_401K_Assets__c, acctJunc.Assets__c);     
                                                                
        Account acct1a = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, 
                            isParent__c, Child_Count__c, Child_Assets__c, Child_Employees__c from Account where Id = :acct1.Id];   
        System.assertEquals(acct2.Employees__c,acct1a.Child_Employees__c);
        System.assertEquals(acct2.Larkspur_401K_Assets__c,acct1a.Child_Assets__c);
        System.assertEquals(acct1a.Employees__c + acct1a.Child_Employees__c, acct1a.NumberOfEmployees);
        
        Test.stopTest();
        
    } // myUnitTest3

        // create 2 accounts with sales parent set on the 2nd insert then change child owner then push parent to child
    static testMethod void myUnitTest4() {
        //ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
    
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 5
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        // insert new account with Sales Parent populated
        Account acct2 = new Account (name = 'Test Account3'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '94-1234567'
                                ,SalesParent__c = acct1.Id
                                ,Employees__c = 1                             
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2; 
        
        acct1 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct1.Id];
                    
        Test.startTest();  
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct2.Id];
                    
        User uCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE 
                    and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and Id != :acct2.OwnerId limit 1];
        acct2.Ownerid = uCore.Id;
        update acct2;
                
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct2.Id];  
        System.assertEquals(uCore.Id, acct2.OwnerId);
        
        Account_Junction__c acctJuncBefore = [Select Id, Child_Account__c, Assets__c, Employees__c, Parent_Account__c, Push_Parent_to_Child__c  
                                                from Account_Junction__c where Child_Account__c = :acct2.Id];  
        acctJuncBefore.Push_Parent_to_Child__c = true;
        update acctJuncBefore;                                              
        
        acct2 = [Select Id, Ownerid, HNBF_Account_Owner__c, HRS_Account_Owner__c, NumberOfEmployees, Employees__c, X401K_Assets__c, Larkspur_401K_Assets__c, isChild__c, SalesParent__c 
                    from Account where Id = :acct2.Id];   
        System.assertEquals(acct1.OwnerId,acct2.OwnerId);
       
        Test.stopTest();
        
    } // myUnitTest4

   static testMethod void testOwnershipChanges() {
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 20];

      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      Account parentAcct = new Account(Name='Parent Acct', RecordTypeId=acctCoreRt.getRecordTypeId()
                                ,OwnerId=users[0].Id
                                ,HRS_Account_Owner__c=users[1].Id
                                ,HNBF_Account_Owner__c=users[2].Id
                                ,Premier_PBS_Account_Owner__c=users[3].Id
                                ,type = 'Core Client'
                                ,BillingPostalCode = null
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 5
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
      Account childAcct = new Account(Name='Parent Acct', RecordTypeId=acctCoreRt.getRecordTypeId()
                                ,OwnerId=users[7].Id
                                ,HRS_Account_Owner__c=users[8].Id
                                ,HNBF_Account_Owner__c=null
                                ,Premier_PBS_Account_Owner__c=null
                                ,type = 'Core Client'
                                ,BillingPostalCode = null
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 5
                                ,Paychex_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{parentAcct,childAcct};
      insert accts;

      AccountTeamMember atm1 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[1].Id, TeamMemberRole='Small Market 401(k)/FSA Partner');
      AccountTeamMember atm2 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[2].Id, TeamMemberRole='HRS HNBF Partner');
      AccountTeamMember atm3 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[3].Id, TeamMemberRole='HRS HRS PEO-ASO Partner');
      AccountTeamMember atm4 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[4].Id, TeamMemberRole='PHRS HR Generalist');
      AccountTeamMember atm5 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[5].Id, TeamMemberRole='Internal Referral');

      AccountTeamMember atm7 = new AccountTeamMember(AccountId=childAcct.Id, UserId=users[9].Id, TeamMemberRole='Small Market 401(k)/FSA Partner');
      AccountTeamMember atm8 = new AccountTeamMember(AccountId=childAcct.Id, UserId=users[10].Id, TeamMemberRole='HRS HNBF Partner');
      AccountTeamMember atm9 = new AccountTeamMember(AccountId=childAcct.Id, UserId=users[11].Id, TeamMemberRole='PHRS HR Generalist');
      AccountTeamMember atm10 = new AccountTeamMember(AccountId=childAcct.Id, UserId=users[12].Id, TeamMemberRole='Internal Referral');
      AccountTeamMember[] atms = new AccountTeamMember[]{atm1,atm2,atm3,atm4,atm5,atm7,atm8,atm9,atm10};
      insert atms;
      
      System.assertEquals(5,[select count() from AccountTeamMember where AccountId=:parentAcct.Id]);
      System.assertEquals(4,[select count() from AccountTeamMember where AccountId=:childAcct.Id]);
      System.assertEquals(9,[select count() from AccountTeamMember]);

      ZipCheckOwner.SKIP_TRIGGERS=false;
      childAcct.SalesParent__c = parentAcct.Id;
      Test.startTest();
      update childAcct;
      Test.stopTest();
      
      System.assertEquals(10,[select count() from AccountTeamMember]);
      System.assertEquals(5,[select count() from AccountTeamMember where AccountId=:parentAcct.Id]);
      System.assertEquals(5,[select count() from AccountTeamMember where AccountId=:childAcct.Id]);

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, OwnerId
                                                           ,HRS_Account_Owner__c
                                                           ,HNBF_Account_Owner__c
                                                           ,Premier_PBS_Account_Owner__c
                                                           ,(Select Id, UserId, TeamMemberRole from AccountTeamMembers)
                                                       From Account]);
      Account checkChild = acctMap.get(childAcct.Id);
      System.assertEquals(parentAcct.OwnerId,checkChild.OwnerId);
      System.assertEquals(parentAcct.HRS_Account_Owner__c,checkChild.HRS_Account_Owner__c);
      System.assertEquals(parentAcct.HNBF_Account_Owner__c,checkChild.HNBF_Account_Owner__c);
      System.assertEquals(parentAcct.Premier_PBS_Account_Owner__c,checkChild.Premier_PBS_Account_Owner__c);
      
      Map<String,AccountTeamMember> teamMap = new Map<String,AccountTeamMember>();
      for (AccountTeamMember atm : checkChild.AccountTeamMembers) {
         teamMap.put(atm.TeamMemberRole,atm);
      }
      AccountTeamMember check401k = teamMap.get('Small Market 401(k)/FSA Partner');
      System.assertEquals(atm1.UserId, check401k.UserId);

      AccountTeamMember checkHNBF = teamMap.get('HRS HNBF Partner');
      System.assertEquals(atm2.UserId, checkHNBF.UserId);
                                                             
      AccountTeamMember checkPEO = teamMap.get('HRS HRS PEO-ASO Partner');
      System.assertEquals(atm3.UserId, checkPEO.UserId);

      AccountTeamMember checkHRG = teamMap.get('PHRS HR Generalist');
      System.assertEquals(atm9.UserId, checkHRG.UserId);

      AccountTeamMember checkIntRef = teamMap.get('Internal Referral');
      System.assertEquals(atm10.UserId, checkIntRef.UserId);
                                                             
   } // testOwnershipChanges


    static testMethod void testSMBChannelOwnershipChanges() {
        HoldOut_Dictionary__c hod = new HoldOut_Dictionary__c(Name='Payroll Lost Client',Next_HO_reason__c=null,Permanent__c=false, Sold_clears_Expiration_Date__c=false, SoldExtendsHoldout__c=null, Use_Opty_Owner__c=true, Not_Sold_clears_Hold_Out__c=false, Min_Employees__c = 1, Max_Employees__c = 19 );
        insert hod;
        
        User[] smbUser = [Select Id, Name from user where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c = 'SMB Channel' limit 1];
        Account acct = new Account(Name='Account', OwnerId=smbUser[0].Id, Hold_Out__c=true, Hold_Out_Expiration__c=null, Permanent_Hold_Out_Description__c=hod.Name, Employees__c = 10, NumberOfEmployees=10,Type='Lost Client');
        insert acct;
        
        Schema.RecordTypeInfo coreRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, 'Opportunity');
        Id coreRtId = coreRt.getRecordTypeId();
        Opportunity opp = new Opportunity(Name='Opp', OwnerId = acct.OwnerId, AccountId=acct.Id, RecordTypeId=coreRtId, CloseDate=Date.today().addDays(1), StageName='Sold - Started', Probability=100, Payroll_Unit__c=true, OpportunityType__c = 'Payroll');
        insert opp;
        
        acct = [SELECT Id, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c FROM Account WHERE Id=:acct.Id]; 
        System.debug('AccountJunctionMethodsTest acct='+acct);
        
        acct.Employees__c = hod.Max_Employees__c + 10;
        
        Test.startTest();
        update acct;
        Test.stopTest();
        
        Account checkAcct = [SELECT Id, Name, Hold_Out__c, Permanent_Hold_Out_Description__c, Hold_Out_Expiration__c FROM Account WHERE Id=:acct.Id];
        System.debug('checkAcct.Hold_Out__c='+checkAcct.Hold_Out__c+' checkAcct.Hold_Out_Expiration__c='+checkAcct.Hold_Out_Expiration__c+' checkAcct.Permanent_Hold_Out_Description__c='+checkAcct.Permanent_Hold_Out_Description__c);
        System.assertEquals(false, checkAcct.Hold_Out__c);
        System.assertEquals(null, checkAcct.Hold_Out_Expiration__c);
        System.assertEquals(null, checkAcct.Permanent_Hold_Out_Description__c);
    }
    
    // populated custom settings
   public static void populateSettings() {
      if (HoldOut_ExpirationDates__c.getAll().size() == 0) {
         HoldOut_ExpirationDates__c hoPAY = new HoldOut_ExpirationDates__c(Name='PAY',Sales_Org__c='PAY',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=30,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=90,
                                                                          TaskNumberOfDays__c=90,UseForOwnershipChange__c=true,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c',
                                                                          Account_Owner__c='OwnerId');
         HoldOut_ExpirationDates__c hoMMS = new HoldOut_ExpirationDates__c(Name='MMS',Sales_Org__c='MMS',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=120,Account_Date_Field__c='First_Run_Date__c',OptySoldNumberOfDays__c=120,
                                                                          Account_Owner__c='OwnerId');
         HoldOut_ExpirationDates__c hoHRS = new HoldOut_ExpirationDates__c(Name='HRS',Sales_Org__c='HRS',Account_Hold_Out__c='HRS_Hold_Out__c',Account_Hold_Out_Date__c='HRS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true,Account_Owner__c='HRS_Account_Owner__c');
         HoldOut_ExpirationDates__c hoHNBF = new HoldOut_ExpirationDates__c(Name='HNBF',Sales_Org__c='HNBF',Account_Hold_Out__c='HNBF_Hold_Out__c',Account_Hold_Out_Date__c='HNBF_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true,Account_Owner__c='HNBF_Account_Owner__c');
         HoldOut_ExpirationDates__c hoPAS = new HoldOut_ExpirationDates__c(Name='PAS',Sales_Org__c='PAS',Account_Hold_Out__c='Premier_PBS_Hold_Out__c',Account_Hold_Out_Date__c='Premier_PBS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=180,Opportunity_Date__c='CloseDate',OptySoldNumberOfDays__c=180
                                                                          ,UseForOwnershipChange__c=true, Account_Owner__c='Premier_PBS_Account_Owner__c');
         HoldOut_ExpirationDates__c hoMS = new HoldOut_ExpirationDates__c(Name='MS',Sales_Org__c='MS',Account_Hold_Out__c='MS_Hold_Out__c',Account_Hold_Out_Date__c='MS_Hold_Out_Expiration__c',
                                                                          InitialNumberofDays__c=null,Opportunity_Date__c=null,OptySoldNumberOfDays__c=null
                                                                          ,UseForOwnershipChange__c=false);
         HoldOut_ExpirationDates__c[] hoList = new HoldOut_ExpirationDates__c[]{hoPAY,hoMMS, hoHRS, hoHNBF, hoPAS,hoMS};
         insert hoList;
      } 
      if (AccountTeamMemberRoles__c.getAll().size() == 0) {
         AccountTeamMemberRoles__c role1 = new AccountTeamMemberRoles__c(Name='Role1',RoleName__c='HRS HNBF Partner', Sales__c=true);
         AccountTeamMemberRoles__c role2 = new AccountTeamMemberRoles__c(Name='Role2',RoleName__c='HRS HRS PEO-ASO Partner', Sales__c=true);
         AccountTeamMemberRoles__c role3 = new AccountTeamMemberRoles__c(Name='Role3',RoleName__c='PHRS HR Generalist', Sales__c=false);
         AccountTeamMemberRoles__c role4 = new AccountTeamMemberRoles__c(Name='Role4',RoleName__c='Small Market 401(k)/FSA Partner', Sales__c=true);
         AccountTeamMemberRoles__c role5 = new AccountTeamMemberRoles__c(Name='Role5',RoleName__c='Internal Referral', Sales__c=false);
         AccountTeamMemberRoles__c[] atmrList = new AccountTeamMemberRoles__c[]{role1,role2,role3,role4,role5};
         insert atmrList;
      }
     
   } // populateSetting
   
} // class AccountJunctionMethodsTest