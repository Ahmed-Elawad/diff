/********************************
05/15/2023 Pratik Das:APR0147362: Agency - Add Flock AM to Prospect Client Page:testupdateFlockAccountManager added to cover AccountTeamMemberTriggerHandler methods:updateFlockAccountManager,updateReferenceHNBF,updateReferenceBeneTrac,queryReferenceHNBF,queryReferenceBeneTrac 
06/02/2023 Dan Carmen              Update quote to reduce number of queries


******************************* */

@istest 
public with sharing class AccountTeamMemberTriggerTest {

    @istest 
    static void testmethod1() {
        test.startTest();
        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;
        User testUsers = new User(FirstName = 'Test',
                    LastName = 'UserDA',
                    Username = 'testUserDA@email.com',
                    Email = 'test@email.com',
                    Alias = 'test',
                    CommunityNickname = 'testUserDA',
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'sq_AL',
                    EmailEncodingKey = 'UTF-8',
                    ProfileId = '00e0g0000010D3TAAU',
                    LanguageLocaleKey = 'en_US',
                    Phone = '123-456-7891',
                    Title = 'Test Title',
                    SenderEmail = 'test@email.com',
                    IsActive = true,
                    Sales_Org__c = 'PAY',
                    HR_Person_Id__c = '123456');
        insert testUsers;

        AccountTeamMemberRoles__c cRole = new AccountTeamMemberRoles__c (name = 'v' , RoleName__c = 'TeamMemberRole', Allow_Delete__c = true ); 
        insert cRole; 
        AccountTeamMember act1 = new AccountTeamMember(Accountid = testAccount.id, userid = testUsers.id, TeamMemberRole = 'TeamMemberRole' ); 
        insert act1; 
        
        AccountTeamMember act2 = new AccountTeamMember(Accountid = testAccount.id, userid = testUsers.id, TeamMemberRole = 'TeamMemberRole' ); 
        insert act2;       
    
        // select id ,AccountId,TeamMemberRole,userid from AccountTeamMember
        test.stopTest();
    }

    @istest 
    public static void testupdateFlockAccountManager(){
        //Create Account
        Account testAcc = new Account(Name='Test Account');
        insert testAcc;
        //Profile
        Profile prof = [select id from profile where name='System Administrator'];
        //Create user
        User testUsers = new User(FirstName = 'Test',
                    LastName = 'UserDA',
                    Username = 'testUserDA@email.com',
                    Email = 'test@email.com',
                    Alias = 'test',
                    CommunityNickname = 'testUserDA',
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'sq_AL',
                    EmailEncodingKey = 'UTF-8',
                    ProfileId =prof.Id,
                    LanguageLocaleKey = 'en_US',
                    Phone = '123-456-7891',
                    Title = 'Test Title',
                    SenderEmail = 'test@email.com',
                    IsActive = true,
                    Sales_Org__c = 'PAY',
                    HR_Person_Id__c = '123456');
        insert testUsers;
        //Create Case
        Case testCase = new Case(Subject='Test Case',Description = 'This is the description for the test case',accountId=testAcc.Id);
        insert testCase;
        //Create reference Agency
        Id hnbfRT = RecordTypeHelper.getRecordType('HNB Enrollments ATC Record Type', 'Reference_HNBF__c').getRecordTypeId();	
        Reference_HNBF__c testRefHNBF=new Reference_HNBF__c(Case_Number__c=testCase.Id, status__c  = 'New',recordtypeid =hnbfRT );
        insert testRefHNBF;
        //Create Reference onboarding
        Reference_BeneTrac_Onboarding__c testRefBen=new Reference_BeneTrac_Onboarding__c(Case_Number__c=testCase.Id);
        insert testRefBen;
        system.runas(testUsers){
            AccountTeamMember testATM = new AccountTeamMember(UserId=testUsers.Id, AccountId=testAcc.Id, TeamMemberRole='FLOCK Account Manager');
            insert testATM;
        }  
        
      
    }







}