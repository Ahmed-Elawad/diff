/*
 * History
 * --------
   03/18/2022 Dan Carmen        Increment API version

*/ 
@IsTest
private class OpportunityDATest {
    @testSetup
    public static void setupData() {
        ObjectBannerAuraServiceTest.setupData();
    }
    
    @IsTest
    static void getOpenOpportunitiesByContact() {
        Contact ctct = ObjectBannerAuraServiceTest.getTestCtct();
        List<Opportunity> returnOpportunities = new OpportunityDA().getOpenOpportunitiesByContactId(ctct.Id);
        System.assertEquals(1,returnOpportunities.size());
    } // getOpenOpportunitiesByContact

    @IsTest
    static void getOpenOpportunitiesByAccountId() {
        Account acct = ObjectBannerAuraServiceTest.getTestAcct();
        List<Opportunity> returnOpportunities = new OpportunityDA().getOpenOpportunitiesByAccountId(acct.Id);
        System.assertEquals(1,returnOpportunities.size());
        
    } // getOpenOpportunitiesByAccountId

    @IsTest
    static void getOpenOpportunitiesByReferralAccountId() {
        Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
        List<Opportunity> returnOpportunities = new OpportunityDA().getOpenOpportunitiesByReferralAccountId(refAcct.Id);
        System.assertEquals(1,returnOpportunities.size());
        
    } // getOpenOpportunitiesByReferralAccountId

    @IsTest
    static void getOpenOpportunitiesByReferralContactId() {
        Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
        List<Opportunity> returnOpportunities = new OpportunityDA().getOpenOpportunitiesByReferralContactId(refCtct.Id);
        System.assertEquals(1,returnOpportunities.size());

    } // getOpenOpportunitiesByReferralContactId

    @IsTest
    static void getOpportunityById() {
        Opportunity opp = ObjectBannerAuraServiceTest.getTestOpp();
        List<Opportunity> returnOpportunities = new OpportunityDA().getOpportunityById(opp.Id);
        System.assertEquals(1,returnOpportunities.size());
        System.assertEquals(opp.Id, returnOpportunities[0].Id);
    } // getOpportunityById

    @isTest
    static void testCommunityUser(){
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(FirstName='test',LastName='test',AccountId=acct.Id,email='test@test.test');    
        insert ctct;
        Profile prof = [SELECT Id FROM Profile where name='Customer Community Login User Clone'];
        User u = new User(
        	UserName = 'testOppDACommUser@test.testtesttest',
            FirstName = ctct.FirstName,
            LastName = ctct.LastName,
            Alias = 'tDAest',
            email = ctct.Email,
            ContactId = ctct.Id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'tesDAt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'PAS');
        insert u;
        Opportunity opp = new Opportunity(AccountId=acct.Id,CloseDate=date.today(),StageName='Pending',Name='test');
        insert opp;
        OpportunityDA da= new OpportunityDA();
        Opportunity oppRet = da.getOpportunityInfo(opp.Id);
        system.assert(oppRet!=null);
        User uRet = da.getPortalUsersByOpportunityId(acct.Id);
        system.assert(uRet!=null);
        
    } // testCommunityUser

} // class OpportunityDATest