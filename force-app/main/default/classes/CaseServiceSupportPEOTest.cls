/*
 * Test class for CaseServiceSupportPEO.
 * 
 * History
 * -------
 * 04/21/2020 Manmeet Vaseer    Created - SFDC-3072 (US4)
 * 
 */ 
@isTest
public class CaseServiceSupportPEOTest {

    /*
    *  When a new Case is created with Service Support PEO Finance record type then 
    *  update Case.Sales_Rep__c with Account Team User name (of PEO-ASO Partner Role type).
    */
    static testMethod void testCaseSalesRep() {
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
        insert parentAcct;
        
        AccountTeamMember atm1 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[11].Id, TeamMemberRole='Small Market 401(k)/FSA Partner');
        AccountTeamMember atm2 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[12].Id, TeamMemberRole='HRS HNBF Partner');
        AccountTeamMember atm3 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[13].Id, TeamMemberRole='PEO-ASO Partner');
        AccountTeamMember atm4 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[14].Id, TeamMemberRole='PHRS HR Generalist');
        AccountTeamMember atm5 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[15].Id, TeamMemberRole='Internal Referral');
        AccountTeamMember[] atms = new AccountTeamMember[]{atm1,atm2,atm3,atm4,atm5};
        insert atms;
        
        /*
         * This new Case insert will execute the CaseBefore trigger, which in turn will call the CaseServiceSupportPEO.updateCases() 
         * that will set the Case.Sales_Rep__c field with Account Team Member user of role type PEO-ASO Partner.
         */
        Schema.RecordTypeInfo caseSSPeoFinance = RecordTypeHelper.getRecordType('Service Support PEO Finance', 'Case');                
        Case newCase = new Case(RecordTypeId=caseSSPeoFinance.getRecordTypeId(),
                            AccountId=parentAcct.Id,
                            OwnerId=UserInfo.getUserId());
        insert newCase;
        
        Case theCase = [Select Id, Sales_Rep__c from Case where Id = :newCase.Id];        
        System.assertEquals(users[13].Id,  theCase.Sales_Rep__c, 'Case Sale Rep is not PEO-ASO Partner role type.');
    }

    /*
    *  When a new Case is created with Service Support PEO Finance record type 
    *  and Account Team User name that is NOT PEO-ASO Partner Role type then
    *  do not update Case.Sales_Rep__c.
    */
    static testMethod void testCaseSalesRepWithNonPeoRoleType() {
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
        insert parentAcct;
        
        AccountTeamMember atm1 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[11].Id, TeamMemberRole='Small Market 401(k)/FSA Partner');
        AccountTeamMember atm2 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[12].Id, TeamMemberRole='HRS HNBF Partner');
        AccountTeamMember atm4 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[14].Id, TeamMemberRole='PHRS HR Generalist');
        AccountTeamMember atm5 = new AccountTeamMember(AccountId=parentAcct.Id, UserId=users[15].Id, TeamMemberRole='Internal Referral');
        AccountTeamMember[] atms = new AccountTeamMember[]{atm1,atm2,atm4,atm5};
        insert atms;
        
        /*
         * This new Case insert will execute the CaseBefore trigger, which in turn will call the CaseServiceSupportPEO.updateCases() 
         * that will set the Case.Sales_Rep__c field with Account Team Member user of role type PEO-ASO Partner.
         */
        Schema.RecordTypeInfo caseSSPeoFinance = RecordTypeHelper.getRecordType('Service Support PEO Finance', 'Case');                
        Case newCase = new Case(RecordTypeId=caseSSPeoFinance.getRecordTypeId(),
                            AccountId=parentAcct.Id,
                            OwnerId=UserInfo.getUserId());
        insert newCase;
        
        Case theCase = [Select Id, Sales_Rep__c from Case where Id = :newCase.Id];        
        System.assertEquals(null,  theCase.Sales_Rep__c, 'Case Sale Rep should be null as there is no PEO-ASO Partner role type.');
    }
    
}