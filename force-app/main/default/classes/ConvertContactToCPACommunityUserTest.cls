/**
 * This class contains unit tests for validating the ConvertContactToCPACommunityUser class.
 * 
 *
 * History
 * --------
 * 01/13/2023   Vinay   Updated code to increase coverage.
 *
 */
@isTest
Public class ConvertContactToCPACommunityUserTest{
    static testMethod void createCommunityUserNew() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a1;
        String referralAccRcId = Schema.getGlobalDescribe().get('Referral_Account__c').getDescribe().getRecordTypeInfosByName().get('Core Referral Source Record Type').getRecordTypeId();
        String referralContRcId = Schema.getGlobalDescribe().get('Referral_Contact__c').getDescribe().getRecordTypeInfosByName().get('Core Referral Record Type').getRecordTypeId();
        String contactRecordType = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName().get('Core Referral Record Type').getRecordTypeId();
        
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                ,RecordTypeId=referralAccRcId
                                ,Referral_Type__c = 'Broker'
                                ,Zip_Postal_Code__c = '10000'
                                ,To_Be_Deleted__c = false);
        insert refacct;
        Referral_Contact__c refcon1 = new Referral_Contact__c(Name = 'First Ref Ctct1'
                                ,RecordTypeId=referralContRcId
                                ,Phone__c = '585-555-1212'
                                ,Email__c = 'fLast1@abc.com'
                                ,Referral_Type__c = '100 Broker'
                                ,Referral_Account__c = refacct.Id);
        insert refcon1;
        String username = 'testUsernameApx@test.com';
        String nickname = 'testNicknameApx';
        String alias = 'cUserAli';
        String email = 'test@email.com'; 
        Id commUserId = ConvertContactToCPACommunityUser.createCommunityUserNew(username,nickname, c1_a1.Id, alias, email);
        try {
            ConvertContactToCPACommunityUser.createCommunityUserNew(username,'test nickname123', c1_a1.Id, 'testalias22123', 'testemail234+12@test.com');
        } catch (Exception e) {
            System.debug('Exception==>'+ e.getMessage());
        }
        Test.startTest();
        ConvertContactToCPACommunityUser.saveRefCnt(refcon1.Id, 'Invited', 'test@test123.org');
        ConvertContactToCPACommunityUser.getReferralContactData(refcon1.Id);
        Test.stopTest();
        Profile commProf = [Select id FROM profile where name='CPA Customer Community Login User Clone'];
        
    }
    
    static testMethod void testResendWelcomeEmail() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        insert c1_a1;
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone'];
        User communityUsr = new User(
            UserName = 'testuse2234@test12.com',
            FirstName = c1_a1.FirstName,
            LastName = c1_a1.LastName,
            Alias = 'testcp2',
            email = 'testemail2234@test.com',
            ContactId = c1_a1.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'test nickname 12334',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community',
            License_Type__c = 'Community'
        );
        insert communityUsr;
        ConvertContactToCPACommunityUser.updateUser(communityUsr.Id,'testuse2234+123@test12.com' ,'testuse2234+123@test12.com' ,true);
        Id salesProfileId = [SELECT Id FROM Profile WHERE Name='HRS PEO-ASO Sales - SB' LIMIT 1].Id;	
        User salesUser = new User(
            UserName = 'testusersales+12@paychex.com',
            FirstName = 'Sales First',
            LastName = 'Sales last',
            Alias = 'tesa12',
            email = 'testsales333454@test.com',
            ProfileId = salesProfileId,
            EmailEncodingKey = 'UTF-8',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            License_Type__c = 'Sales-Corporate',
            Sales_Org__c = 'Sales-Corporate'
        );
        insert salesUser;
        System.runAs(salesUser) {

            PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CPA_Getting_Started_Prospect'];
           
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = communityUsr.Id;
            psa.PermissionSetId = ps.Id;
            insert psa;
        }
        ConvertContactToCPACommunityUser.resendWelcomeEmail(c1_a1.Id);
        
    }
    
    static testMethod void verifyExistingUserForContact() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST');
        insert acctA;
        
        Contact c1_a1 = new Contact(FirstName='Test Comm Contact',LastName='Contact 1',  AccountId=acctA.Id, DoNotCall=false, Email='c1a1@whoknows.com');
        User retUser = ConvertContactToCPACommunityUser.verifyExistingUserForContact(c1_a1.Id);
    }
}