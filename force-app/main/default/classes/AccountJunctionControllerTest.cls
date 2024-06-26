/**
* Test method for AccountJunctionMethods
 * 
 * History
 * --------
 * 01/18/2017   Cindy Freeman   created
 * 06/19/2018   Jacob Hinds     adding perm hold out to setting for PAS, excluding mms reps with aso partner from query
   01/08/2020 Dan Carmen        Increment API version
 
 */
@isTest
private class AccountJunctionControllerTest {
     
    static testMethod void myUnitTest1() {   
        populateSettings();
        ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Larkspur_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Account acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '93-1234567'
                                ,Employees__c = 105
                                ,Larkspur_401K_Assets__c = 5000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2;
        
        User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and ASO_Partner__c = null and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.AccountJunction);
            System.CurrentPageReference().getParameters().put('Id',acct2.Id);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct2);
            AccountJunctionController ajC = new AccountJunctionController(sc);
            
            System.assertEquals(true, ajC.setChildAcct(acct2.Id));
            ajC.junc.Parent_Account__c = acct1.Id;
            ajC.save();
            System.assertEquals(true, ajC.juncSaved);
            
        } // runAs
        
        
        //System.assertEquals(true,ApexPages.hasMessages());
        //ApexPages.Message msg = ApexPages.getMessages().get(0);
    } // myUnitTest1
    
    
    // test for account that is already linked to a parent
    static testMethod void myUnitTest2() {   
        populateSettings();
        ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Larkspur_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Account acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '93-1234567'
                                ,Employees__c = 105
                                ,Larkspur_401K_Assets__c = 5000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2;
        
        Account_Junction__c junc = new Account_Junction__c();
        junc.Child_Account__c = acct2.Id;
        junc.Employees__c = 105;
        junc.Assets__c = 5000;
        junc.Parent_Account__c = acct1.Id;
        junc.Type__c = Label.AccountJunctionDefaultType;
        insert junc;

        User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and ASO_Partner__c = null and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.AccountJunction);
            System.CurrentPageReference().getParameters().put('Id',acct2.Id);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct2);
            AccountJunctionController ajC = new AccountJunctionController(sc);
            
            System.assertEquals(true, ajC.setChildAcct(acct2.Id));
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('You are already', msg.getDetail().left(15));
            
        } // runAs
       
    } // myUnitTest2
    
// test for account that is already a parent
    static testMethod void myUnitTest3() {   
        populateSettings();
        ZipCheckOwnerTest.setupZipsAndSegments(true);
        // need to insert Hold Out owner names and accountTeamRoles
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 9
                                ,Larkspur_401K_Assets__c = 10000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Account acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '14515'
                                ,AccountNumber = '93-1234567'
                                ,Employees__c = 105
                                ,Larkspur_401K_Assets__c = 5000
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct2;
        
        Account_Junction__c junc = new Account_Junction__c();
        junc.Child_Account__c = acct2.Id;
        junc.Employees__c = 105;
        junc.Assets__c = 5000;
        junc.Parent_Account__c = acct1.Id;
        junc.Type__c = Label.AccountJunctionDefaultType;
        insert junc;

        User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and ASO_Partner__c = null and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
            Test.SetCurrentPageReference(Page.AccountJunction);
            System.CurrentPageReference().getParameters().put('Id',acct1.Id);
            ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct1);
            AccountJunctionController ajC = new AccountJunctionController(sc);
            
            System.assertEquals(true, ajC.setChildAcct(acct1.Id));
            System.assertEquals(true,ApexPages.hasMessages());
            ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('You are already', msg.getDetail().left(15));
            
            PageReference retUrl = ajC.returnToAcct();
            System.assertEquals(true,(retUrl.getUrl().contains(acct1.Id)));
            
            PageReference canUrl = ajC.cancel();
            System.assertEquals(true,(canUrl.getUrl().contains(acct1.Id)));
      
        } // runAs
       
    } // myUnitTest3
    
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
                                                                          ,HoldOutReasonFld__c='PEO_ASO_Permanent_Hold_Out_Description__c',UseForOwnershipChange__c=true, Account_Owner__c='Premier_PBS_Account_Owner__c');
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
}