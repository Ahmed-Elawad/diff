/**
 * This class contains unit tests for validating the MyAcctHelp class.
 * 
 *
 * History
 * --------
 * 01/11/2023   Vinay   created
 *
 */
@isTest
public without sharing class MyAcctHelpTest {
    static testMethod void testReferralContactData() {
        ReferralObjectsSync.SKIP_SYNC = false;

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
        
        Account acc = new Account();
        acc.Name = 'Peo test';
        acc.ShippingState = 'Texas';
        insert acc;
        
        Contact c = new Contact(AccountId=acc.id,
                               FirstName = 'test',
                               LastName = 'contact',
                               RecordTypeId = contactRecordType,
                               Mirror_Ref_Ctct__c = refcon1.Id,
                               Email='testing@testing.com');
        insert c;
        
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone'];
        
        User communityUsr = new User(
            UserName = c.email,
            FirstName = c.FirstName,
            LastName = c.LastName,
            Alias = 'alias',
            email = c.Email,
            ContactId = c.id,
            ProfileId = prof.Id,
            EmailEncodingKey = 'UTF-8',
            CommunityNickname = 'nickName',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            Sales_Org__c = 'Community'
        );
        insert communityUsr;
		test.startTest();
        System.runAs(communityUsr) {
            PageReference pref = Page.MyAcctHelp;
            pref.getParameters().put('userId', communityUsr.Id);
            Test.setCurrentPage(pref);
            MyAcctHelp controller = new MyAcctHelp();
        }
        test.stopTest();
    }
}