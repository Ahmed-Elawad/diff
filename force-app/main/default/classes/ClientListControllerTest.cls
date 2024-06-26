/**
 * * Test class for ClientListController
 *
 * History
 * -------
 * 10/23/2017 Lynn Michels created
 * 11/27/2017 Lynn Michels added functionality to Area Manager
 * 06/26/2018 Lynn Michels changed to incorporate changed functionality for Area Managers 
 * 01/10/2020 Dan Carmen   Update test, increment API version
 * 03/20/2020 Jake Hinds   Adding HR Admin
 * 09/29/2020 Jake Hinds   Removing HR Admin
 * 04/19/2021 Dan Carmen   Change for mixed DML operation
 * 02/11/2024 Reetesh Pandey APR0153637 Changed test code to check for HRG Name 
*/
@isTest
private class ClientListControllerTest {   
    
    @TestSetup
    public static void testSetUpClientList(){
       AccountJunctionMethodsTest.setupCustomSettings();
         string AreaManager = System.Label.Area_Manager_Profile;
        system.debug('LM areaManager ' + AreaManager);  //2008-09 HRS Premier Support Manager
        //create a user that has the Area Manger profile
        Profile p = [SELECT Id FROM Profile WHERE Name =: AreaManager];
        User u = [Select Id, Name from User where ProfileId = :p.Id and IsActive=true limit 1];
        User u1 = [Select Id, Name from User where ProfileId = :p.Id and IsActive=true limit 1];
        u1.Firstname='SetUp';
        u1.Lastname='TestMngr';
        update u1;
        
        //create Accounts
        Account a1 = new Account(Name='Account 1', Employees__c = 2);   
        Account a2 = new Account(Name='Account 2', Employees__c = 5);  
        Account a3 = new Account(Name='Account 3', Employees__c = 10);
        Account a4 = new Account(Name='Account 4', Employees__c = 11);
        Account a5 = new Account(Name='Account 5', Employees__c = 8);
        List<Account> accts = new List<Account>{a1,a2,a3,a4,a5};
        insert accts;
        
        Contact con1= new Contact(AccountId= a1.Id,LastName ='ConTest1');
        insert con1;
        Contact con2= new Contact(AccountId= a5.Id,LastName ='ConTest2',User_Lookup__c = u1.Id);
        insert con2;
        
        
        a1.HR_Generalist__c =con1.Id;
       // update a1;
        a3.HR_Generalist__c =con1.Id;        
       // update a3;
        a5.HR_Generalist__c =con2.Id;
       // update a5;
        update accts;
        
        //create a case on Account 1
        Id CaseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
        Case c1 = new Case(RecordTypeId = CaseTermTransfer, AccountId = a1.id);
        Case c2 = new Case(RecordTypeId = CaseTermTransfer, AccountId = a2.id);
        List<Case> caseList = new List<Case>{c1,c2};
        insert caseList;
        //create a reference record
        Id TermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId(); 
        Reference_HRS_Termination_Transfer__c ref1 = new Reference_HRS_Termination_Transfer__c(RecordtypeId = TermTransferRtId,Case_Lookup__c = c1.id);
        Reference_HRS_Termination_Transfer__c ref2 = new Reference_HRS_Termination_Transfer__c(RecordtypeId = TermTransferRtId,Case_Lookup__c = c2.id,Code_Lost_Date__c =System.Today());
        List<Reference_HRS_Termination_Transfer__c> termTrans = new List<Reference_HRS_Termination_Transfer__c>{ref1,ref2};
        insert termTrans;   
        
    }
    
    @isTest
    static void alertTest(){
        string AreaManager = System.Label.Area_Manager_Profile;       
        Profile p = [SELECT Id FROM Profile WHERE Name =: AreaManager];
        User u = [Select Id, Name from User where ProfileId = :p.Id and IsActive=true limit 1];
        System.runAs(u){
        Reference_HRS_Termination_Transfer__c termTrans = [select id,Case_Lookup__c FROM Reference_HRS_Termination_Transfer__c where Case_Lookup__r.Account.Name = 'Account 2' limit 1];
        Test.SetCurrentPageReference(Page.ClientList);
        System.CurrentPageReference().getParameters().put('Id',termTrans.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(termTrans);
        ClientListController clc = new ClientListController(sc);
        system.assertEquals(clc.alert,'Please populate HRG Name before you proceed.');   
        }
        
    }  
    
    static testMethod void getClientList() {
        
        AccountJunctionMethodsTest.setupCustomSettings();
        //create Accounts
        Account a1 = [Select id from Account where Name='Account 1' limit 1];   
        Account a3 = [Select id from Account where Name='Account 3' limit 1];   
       
        
        //add running user as account team member on all
        //add active asset on all accounts
        List<AccountTeamMember> teamMembers = new list<AccountTeamMember>();
        List<Asset> activeAssets = new list<Asset>();
        AccountTeamMember atm = new AccountTeamMember(AccountId=a1.Id, UserId=UserInfo.getUserId(), TeamMemberRole =ZipCheckOwner.AT_HRG);
            teamMembers.add(atm);
            Asset product = new Asset(Product_Plan_Code__c = '884', Name = 'Test884', AccountId = a1.id);
            Asset product1 = new Asset(Product_Plan_Code__c = '884', Name = 'Test884', AccountId = a3.id);
            activeAssets.add(product);   
        activeAssets.add(product1); 
        
        
        insert teamMembers;
        insert activeAssets;
        
        //create a case on Account 1
        Id CaseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
        Case c1 = new Case(RecordTypeId = CaseTermTransfer, AccountId = a1.id);
        insert c1;
        //create a reference record
        String hrgName= 'Test';
        Id TermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId(); 
        Reference_HRS_Termination_Transfer__c termTrans = new Reference_HRS_Termination_Transfer__c(RecordtypeId = TermTransferRtId,
                                                                                                    Case_Lookup__c = c1.id,
                                                                                                   Code_Lost_Date__c= System.Today()
                                                                                                   );
        
        insert termTrans;   
        
        
        string AreaManager = System.Label.Area_Manager_Profile;       
        Profile p = [SELECT Id FROM Profile WHERE Name =: AreaManager];
        User u = [Select Id, Name from User where ProfileId = :p.Id and IsActive=true limit 1];
        System.runAs(u){
        Test.SetCurrentPageReference(Page.ClientList);
        System.CurrentPageReference().getParameters().put('Id',termTrans.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(termTrans);
        ClientListController clc = new ClientListController(sc);
        system.assertEquals(true,clc.isAreaManager);
        system.assertEquals(true,clc.userIdIsSet);
        
        
        system.assertEquals(1,clc.acctWrapperList.size());
        system.assertEquals(2,clc.employeeCount);
        
        system.assertEquals(true,clc.cont);
       // system.assertEquals('Please populate Code Lost Date before you can proceed.',clc.alert);
        
        //click Cancel to go back and populate Lost Date
        clc.cancel();
        
        termTrans.Code_Lost_Date__c = date.today();
        update termTrans;
        
        //click Select Clients again
        clc = new ClientListController(sc);
        List<ClientListController.AcctWrapper> awList = new List<ClientListController.AcctWrapper>();
        awList = clc.acctWrapperList; 
        
        system.assertEquals(1,clc.acctWrapperList.size());
        system.assertEquals(2,clc.employeeCount);
        
        integer count = 0; 
        for(ClientListController.AcctWrapper aw: awList){
            
            if (count != 3){
                aw.selected = true;
                count ++;
                system.debug('LM count ' +count);
            }
            
        }
        
        clc.processSelected();
        
        List<Reference_HRS_Termination_Transfer__c> refList = [SELECT Id, Code_Lost_Date__c FROM Reference_HRS_Termination_Transfer__c WHERE Parent_Ref_HRS_Termination_Transfer__c =: termTrans.id];
        system.assertEquals(1, refList.size());
        
        List<Reference_HRS_Termination_Transfer__c> parentRef = [SELECT Id, Total_of_Employees__c, Total_of_IDs__c FROM Reference_HRS_Termination_Transfer__c WHERE id =: termTrans.id];
        system.debug('LM parentRef '+parentRef);
        system.assertEquals(12, parentRef[0].Total_of_Employees__c);
        system.assertEquals(2, parentRef[0].Total_of_IDs__c);        
        
        List<ClientListController.AcctWrapper> awList2 =  clc.acctWrapperList; 
        system.assertEquals(1, awList2.size());
        for(ClientListController.AcctWrapper aw: awList2){
            aw.selected = true;
        }
        clc.processSelected();
        
        List<Reference_HRS_Termination_Transfer__c> refList2 = [SELECT Id, Code_Lost_Date__c FROM Reference_HRS_Termination_Transfer__c WHERE Parent_Ref_HRS_Termination_Transfer__c =: termTrans.id];
        system.assertEquals(2, refList2.size());
        
        List<Reference_HRS_Termination_Transfer__c> parentRef2 = [SELECT Id, Total_of_Employees__c, Total_of_IDs__c FROM Reference_HRS_Termination_Transfer__c WHERE id =: termTrans.id];
        system.debug('LM parentRef '+parentRef2);
        system.assertEquals(22, parentRef2[0].Total_of_Employees__c);
        system.assertEquals(2, parentRef2[0].Total_of_IDs__c);
            
            clc.changeSelectAllOption();
            clc.setupClientListOptions();
            
        }
    }// end getClientList
    
    static testMethod void generateHRGFromAccTest() {
        AccountJunctionMethodsTest.setupCustomSettings();
        //create Accounts
        Account a1 = [Select id from Account where Name='Account 1' limit 1];   
        Account a3 = [Select id from Account where Name='Account 3' limit 1]; 
         Account a5 = [Select id from Account where Name='Account 5' limit 1]; 
       
        
        //add running user as account team member on all
        //add active asset on all accounts
        List<AccountTeamMember> teamMembers = new list<AccountTeamMember>();
        List<Asset> activeAssets = new list<Asset>();
        AccountTeamMember atm = new AccountTeamMember(AccountId=a1.Id, UserId=UserInfo.getUserId(), TeamMemberRole =ZipCheckOwner.AT_HRG);
            teamMembers.add(atm);
            Asset product = new Asset(Product_Plan_Code__c = '884', Name = 'Test884', AccountId = a1.id);
            Asset product1 = new Asset(Product_Plan_Code__c = '884', Name = 'Test884', AccountId = a3.id);
            activeAssets.add(product);   
        activeAssets.add(product1);     
        
        insert teamMembers;
        insert activeAssets;
        
        //create a case on Account 1
        Id CaseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
        Case c1 = new Case(RecordTypeId = CaseTermTransfer, AccountId = a5.id);
        insert c1;
        //create a reference record
        String hrgName= 'Test';
        Id TermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId(); 
        Reference_HRS_Termination_Transfer__c termTrans = new Reference_HRS_Termination_Transfer__c(RecordtypeId = TermTransferRtId,
                                                                                                    Case_Lookup__c = c1.id,
                                                                                                   Code_Lost_Date__c= System.Today()
                                                                                                   );
        
        insert termTrans;       
        string AreaManager = System.Label.Area_Manager_Profile;       
        Profile p = [SELECT Id FROM Profile WHERE Name =: AreaManager];
        User u = [Select Id, Name from User where ProfileId = :p.Id and IsActive=true and Lastname='TestMngr' limit 1];
        System.runAs(u){
        Test.SetCurrentPageReference(Page.ClientList);
        System.CurrentPageReference().getParameters().put('Id',termTrans.Id);
            ClientListController clc = new ClientListController();           
            clc.getHrgsFromAccounts(a5.Id);           
        }
        
    }
}