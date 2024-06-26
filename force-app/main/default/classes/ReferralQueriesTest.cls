/* 
   Test methods for the ReferralQueries class
   
   History
   -------
   01/20/2017 Dan Carmen         Created
   03/05/2018 Dan Carmen         Removed Partner Referral from the queries - they'll be queried separately when needed
   02/05/2020 Dan Carmen          Clean up groupPartners method
   12/22/2021 Dan Carmen          Add additional Latest Campaign fields to the query
   05/10/2023 Dan Carmen          Added calls to ZipQueries for extra query fields
        
 */
@isTest
private class ReferralQueriesTest {

   static testMethod void testSelectLeads() {
      Lead ld = new Lead(LastName='TestLast', Company='Test Company', PostalCode='12345');
      insert ld;
      
      Set<ID> leadIdSet = new Set<Id>();
      leadIdSet.add(ld.Id);
      Lead[] leads = ReferralQueries.selectLeads(leadIdSet, null);
      System.assertEquals(ld.Id, leads[0].Id);
        
   } // testSelectLeads
   
   static testMethod void testSelectContact() {
      Contact ctct = new Contact(LastName='TestLast');
      insert ctct;
      
      Contact queryCtct = ReferralQueries.selectContact(ctct.Id);
      System.assertEquals(ctct.Id, queryCtct.Id);
   } // testSelectContact
   
   static testMethod void testSelectCtctMap() {
      Contact ctct = new Contact(LastName='TestLast');
      insert ctct;
      
      Map<Id,Contact> ctctMap = ReferralQueries.selectCtctMap(new Id[]{ctct.Id});
      System.assertEquals(ctct.Id, ctctMap.get(ctct.Id).Id);
   } // testSelectCtctMap
   
   static testMethod void testSelectOpp() {
      Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addDays(7), StageName='Pending');
      insert opp;
      
      Opportunity checkOpp = ReferralQueries.selectOpp(opp.Id);
      System.assertEquals(opp.Id, checkOpp.Id);
   } // testSelectOpp
   
   static testMethod void testSelectAcct() {
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Account checkAcct = ReferralQueries.selectAcct(acct.Id);
      System.assertEquals(acct.Id, checkAcct.Id);
   } // testSelectAcct
   
   static testMethod void testGetAtmListMap() {
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      User[] users = [Select Id, Name from User where IsActive=true and Id!=:UserInfo.getUserId() and Sales_Org__c=:UserHelper.SO_CORE limit 3];
      AccountTeamMember atm1 = new AccountTeamMember(AccountId=acct.Id, UserId=users[0].Id, TeamMemberRole='Test Role Name');
      AccountTeamMember atm2 = new AccountTeamMember(AccountId=acct.Id, UserId=users[1].Id, TeamMemberRole='Test Role Name');
      AccountTeamMember atm3 = new AccountTeamMember(AccountId=acct.Id, UserId=users[2].Id, TeamMemberRole='Test Role Name');
      AccountTeamMember[] atms = new AccountTeamMember[]{atm1,atm2,atm3};
      insert atms;
      
      Set<Id> acctIdSet = new Set<Id>();
      acctIdSet.add(acct.Id);
      Map<Id,List<AccountTeamMember>> atmListMap = ReferralQueries.getAtmListMap(acctIdSet);
      System.assertEquals(3,atmListMap.get(acct.Id).size());
   } // testGetAtmListMap
   
   static testMethod void testGetContactListMap() {
      Account acct = new Account(Name='Test Account');
      insert acct;

      Contact ctct1 = new Contact(LastName='Last1', AccountId=acct.Id, Sales_Contact__c=true);
      Contact ctct2 = new Contact(LastName='Last2', AccountId=acct.Id, Sales_Contact__c=true);
      Contact ctct3 = new Contact(LastName='Last3', AccountId=acct.Id, Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      insert ctcts;
      
      ctct1.Sales_Contact__c=true;
      ctct2.Sales_Contact__c=true;
      ctct3.Sales_Contact__c=true;
      update ctcts;
      
      Contact checkContact = [Select Id, Name from Contact where Sales_Contact__c=true and Id=:ctct1.Id];

      Set<Id> acctIdSet = new Set<Id>();
      acctIdSet.add(acct.Id);
      Map<Id,List<Contact>> contactListMap = ReferralQueries.getContactListMap(acctIdSet);
      
      System.assertEquals(3, contactListMap.get(acct.Id).size());
   } // testGetContactListMap
   
   static testMethod void testSelectRefPartnersCache() { 
      ReferralQueries.USE_STATIC_QUERY=false;
      ReferralControllerTest.setupRefPartners();
      Referral_Partner__c[] refPartnersQuery1 = ReferralQueries.selectRefPartnersCache(ReferralController.REF_INTERNAL, null);
      System.assertNotEquals(null,refPartnersQuery1);
      System.assertEquals(false,ReferralQueries.USED_CACHE);
      Referral_Partner__c[] refPartnersQuery2 = ReferralQueries.selectRefPartnersCache(ReferralController.REF_NSS, ProspectOwnershipMethods.NSS_INBOUND);
      System.assertNotEquals(null,refPartnersQuery2);
      System.assertEquals(true,ReferralQueries.USED_CACHE);
      
   } // testSelectRefPartnersCache

   static testMethod void testSelectRefPartnersCacheStatic() { 
      ReferralQueries.USE_STATIC_QUERY=true;
      ReferralControllerTest.setupRefPartners();
      Referral_Partner__c[] refPartnersQuery1 = ReferralQueries.selectRefPartnersCache(ReferralController.REF_INTERNAL, null);
      System.assertNotEquals(null,refPartnersQuery1);
      System.assertEquals(false,ReferralQueries.USED_CACHE);
      Referral_Partner__c[] refPartnersQuery2 = ReferralQueries.selectRefPartnersCache(ReferralController.REF_NSS, ProspectOwnershipMethods.NSS_INBOUND);
      System.assertNotEquals(null,refPartnersQuery2);
      System.assertEquals(true,ReferralQueries.USED_CACHE);
      
   } // testSelectRefPartnersCache

} // ReferralQueriesTest