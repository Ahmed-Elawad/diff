@isTest
public class ReferralContactsTest{
	
    @isTest
    private static void testfetchActiveReferralContacts(){
        ReferralContacts.fetchActiveReferralContacts(null);
    }
    
    
    @isTest
    private static void testfetchRefConUserData(){
        Profile prof = [SELECT Id FROM Profile where name='CPA Customer Community Login User Clone' LIMIT 1];
        User otherAdmin = [SELECT id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Id!=:UserInfo.getUserId() LIMIT 1];
        
        Referral_Account__c refAcc = new Referral_Account__c();
        refAcc.Name = 'Peo test';
        refAcc.MutualClientTier__c = 'Core';
        insert refAcc;
        
        System.debug('refAcc:'+refAcc);
        
        Account acc = new Account();
        acc.Name = 'Peo test';
        //acc.CPA_Name_Ref__r.Referral_Account__c = refAcc.Id;
        insert acc;
        
        
        Contact ctct = new Contact(AccountId=acc.id,
                                    FirstName = 'test',
                                    LastName = 'user',
                                    Email='testing@testingtestTest.com'); 
        insert ctct;
        Referral_Contact__c refCon = new Referral_Contact__c(Referral_Account__c = refAcc.Id, 
                                                             First_Name__c = 'test',
                                                             Last_Name__c = 'user',
                                                             Email__c = 'testing@testingtestTest.com',
                                                             Contact__c = ctct.Id,
                                                            Admin_CPA__c = true,
                                                            CPA_portal_shared__c = 'Yes');
        insert refCon;
        ctct.Mirror_Ref_Ctct__c = refCon.Id;
        Update ctct;
        
        Partner_Portal_User_Details__c ppud = new Partner_Portal_User_Details__c();
        ppud.Referral_Contact__c = refCon.Id;
        ppud.Request_Date__c = datetime.now();
        ppud.Event__c='Invited'; 
        system.debug('jc ppud' + ppud);
        insert ppud; 
        Opportunity opp = new Opportunity(
            AccountId = acc.id,
            Name = 'Test Opty',
            CloseDate = System.today(),
            StageName = 'Proposal',
            Referral_Contact__c = refCon.Id,
            Date_Lead_Submitted__c = system.today(),
            Referral_Account__c = refAcc.Id,
            OpportunityType__c='Payroll'        
        );
        Insert opp;
        Id vfpageUserId;
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
                Requested_Invite_Date__c = System.today()
            );
            insert testUser;
            vfpageUserId = testUser.Id;
            System.debug('vfpageUserId :'+vfpageUserId);
        }
        
        ReferralContacts.fetchActiveReferralContacts(refAcc.Id);
        ReferralContacts.fetchRefConUserData(refCon.Id);
        ReferralContacts.relatedReferralContacts(refCon.Id);
        ReferralContacts.fetchRefConUserInfo(refCon.Id);
        ReferralContacts.fetchPPUD(refCon.Id);
    }
}