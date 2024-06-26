/* 
 * Test methods for the OpptyCampaignInfluence class

   History
   -------
   04/24/2017 Dan Carmen        Created
   03/02/2020 Dan Carmen        Add additional tracking for NSS Source and Referral Contact

 */
@isTest
private class OpptyCampaignInfluenceTest {

   @testSetup
   public static void setupTestData() {
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'OpptyCampaignInfluence'}, classes, TriggerMethods.INTERFACE_B);
      insert classes;
   } // setupTestData

   static testMethod void testInfluenceLeadSource() {
      Campaign camp1 = new Campaign(Name='Test Camp1', IsActive=true, StartDate=Date.today().addDays(-60), LeadSource__c='Lead Source 1',LeadSourceDefaultCampaign__c=true);
      Campaign camp2 = new Campaign(Name='Test Camp2', IsActive=true, StartDate=Date.today().addDays(-60), LeadSource__c='Lead Source 2',LeadSourceDefaultCampaign__c=true);
      Campaign camp3 = new Campaign(Name='Test Camp3', IsActive=true, StartDate=Date.today().addDays(-60), LeadSource__c='Lead Source 3',LeadSourceDefaultCampaign__c=true);
      Campaign camp4 = new Campaign(Name='Test Camp4', IsActive=true, StartDate=Date.today().addDays(-60), LeadSource__c='Lead Source 4',LeadSourceDefaultCampaign__c=true);
      Campaign[] camps = new Campaign[]{camp1,camp2,camp3,camp4};
      insert camps;
      
      Account acct1 = new Account(Name='Account 1');
      Account acct2 = new Account(Name='Account 2');
      Account[] accts = new Account[]{acct1,acct2};
      ZipCheckOwner.SKIP_TRIGGERS = true;
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Last2');
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      insert ctcts;
      
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Ref Account1');
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='Ref Account2');
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
      insert refAccts;
       
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Joe Contact', Referral_Account__c=refAcct1.Id);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Jimmy Contact', Referral_Account__c=refAcct2.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;

      CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, ContactId=ctct2.Id);
      insert campMember2;
      
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, StageName='Pending', CloseDate=Date.today(), LeadSource=camp1.LeadSource__c);
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, StageName='Pending', CloseDate=Date.today(), Campaign__c=camp2.Id);
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      
      OpptyCampaignInfluence.SKIP_FUTURE = true;
      insert opps;

      OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id, IsPrimary=true, Role='Primary Contact', OpportunityId=opp1.Id);
      OpportunityContactRole ocr2 = new OpportunityContactRole(ContactId=ctct2.Id, IsPrimary=true, Role='Primary Contact', OpportunityId=opp2.Id);
      OpportunityContactRole[] ocrs = new OpportunityContactRole[]{ocr1,ocr2};
      insert ocrs;

      System.assertEquals(2,[select count() from CampaignInfluence]);
      
      // for testing purposes, so it won't check to time difference
      OpptyCampaignInfluence.INFLUENCE_MINUTE_DIFFERENCE = 0;
      // clear so it re-selects
      OpptyCampaignInfluence.defaultCampaignMap = null;
      opp1.LeadSource = camp2.LeadSource__c;
      opp1.Referral_Contact__c = refCtct1.Id;
      update opp1;
      
      System.assertEquals(2, [select count() from CampaignInfluence where OpportunityId=:opp1.Id]);
      
      // clear so it re-selects
      OpptyCampaignInfluence.defaultCampaignMap = null;
      opp1.LeadSource = camp1.LeadSource__c;
      opp1.Referral_Contact__c = refCtct2.Id;
      // test the future method
      OpptyCampaignInfluence.SKIP_FUTURE = false;
      Test.startTest();
      update opp1;
      Test.stopTest();
      
      System.assertEquals(2, [select count() from CampaignInfluence where OpportunityId=:opp1.Id]);
      CampaignInfluence ci1a = [Select Id, CampaignCounter__c, ReferralContactId__c from CampaignInfluence where OpportunityId=:opp1.Id and CampaignId=:camp1.Id];
      System.assertEquals(2, ci1a.CampaignCounter__c);
      System.assertEquals(refCtct2.Id, ci1a.ReferralContactId__c);
              
   } // testInfluenceLeadSource
    
   static testMethod void testMisc() {
      OpptyCampaignInfluence oci = new OpptyCampaignInfluence();
      oci.triggerCheckRec(null, null, true, true);
      oci.triggerCheckActions(true, true);
      
   } // testMisc
   
} // class OpptyCampaignInfluenceTest