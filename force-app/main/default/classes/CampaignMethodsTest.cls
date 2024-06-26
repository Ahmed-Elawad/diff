/* 
   Test methods for the CampaignMethods class.
   
  History
  -------
   06/17/2014 Dan Carmen       Created
   03/15/2015 Dan Carmen       Attach the contact to an account
   10/15/2019 Dan Carmen       Update to use TriggerMethods.clearVariables();
   01/23/2023 Dan Carmen       Change to InterfaceC, increment API
   12/11/2023 Dan Carmen       Moved trigger logic to CampaignMethods, clear cache on change
   
     
 */

@isTest(seeAllData=false)
private class CampaignMethodsTest {
   
   @testSetup
   public static void setup(){
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'CampaignMethods'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'CampaignMethods'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'CampaignMethods'});
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'CampaignMethods'});
      TriggerMethodsTest.saveSetupClasses();

   } // setup
   
   static testMethod void testCampaignParent() {
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, StartDate=Date.today());
      insert camp1;
      camp1 = [Select Id, Name, IsParent__c, ParentCampaign__c, ParentId from Campaign where Id=:camp1.Id];
      System.assertEquals(false,camp1.IsParent__c);
      System.assertEquals(null,camp1.ParentCampaign__c);
      System.assertEquals(null,camp1.ParentId);
      
      Campaign camp2 = new Campaign(Name='Campaign2', IsActive=true, StartDate=Date.today(), ParentId=camp1.Id, IsParent__c=true);
      insert camp2;
      camp2 = [Select Id, Name, IsParent__c, ParentCampaign__c, ParentId from Campaign where Id=:camp2.Id];
      System.assertEquals(true,camp2.IsParent__c);
      System.assertEquals(null,camp2.ParentCampaign__c);
      System.assertEquals(camp1.Id,camp2.ParentId);

      Campaign camp3 = new Campaign(Name='Campaign3', IsActive=true, StartDate=Date.today(), ParentId=camp2.Id, IsParent__c=false);
      insert camp3;
      camp3 = [Select Id, Name, IsParent__c, ParentCampaign__c, ParentId from Campaign where Id=:camp3.Id];
      System.assertEquals(false,camp3.IsParent__c);
      System.assertEquals(camp2.Id,camp3.ParentCampaign__c);
      System.assertEquals(camp2.Id,camp3.ParentId);

      Campaign camp4 = new Campaign(Name='Campaign4', IsActive=true, StartDate=Date.today(), ParentId=camp3.Id, IsParent__c=false);
      insert camp4;
      camp4 = [Select Id, Name, IsParent__c, ParentCampaign__c, ParentId from Campaign where Id=:camp4.Id];
      System.assertEquals(false,camp4.IsParent__c);
      System.assertEquals(camp2.Id,camp4.ParentCampaign__c);
      System.assertEquals(camp3.Id,camp4.ParentId);

      Campaign camp5 = new Campaign(Name='Campaign5', IsActive=true, StartDate=Date.today(), ParentId=camp4.Id, IsParent__c=false);
      insert camp5;
      camp5 = [Select Id, Name, IsParent__c, ParentCampaign__c, ParentId from Campaign where Id=:camp5.Id];
      System.assertEquals(false,camp5.IsParent__c);
      System.assertEquals(camp2.Id,camp5.ParentCampaign__c);
      System.assertEquals(camp4.Id,camp5.ParentId);

      Lead ld1 = new Lead(LastName='Lead1', Company='Test Lead Company', LatestCampaign__c=camp5.Id);
      insert ld1;
      
      ld1 = [Select Id, Name, Company, LatestCampaign__c, LatestCampaignParent__c from Lead where Id=:ld1.Id];
      System.assertEquals(ld1.LatestCampaign__c,camp5.Id);
      System.assertEquals(ld1.LatestCampaignParent__c,camp2.Id);
      
      TriggerMethods.clearVariables();
      ld1.LatestCampaign__c = camp4.Id;
      update ld1;
      ld1 = [Select Id, Name, Company, LatestCampaign__c, LatestCampaignParent__c from Lead where Id=:ld1.Id];
      System.assertEquals(ld1.LatestCampaign__c,camp4.Id);
      System.assertEquals(ld1.LatestCampaignParent__c,camp2.Id);

      ld1.LatestCampaign__c = null;
      LeadMethods.leadIdsProcessed.clear();
      TriggerMethods.clearVariables();
      update ld1;
      ld1 = [Select Id, Name, Company, LatestCampaign__c, LatestCampaignParent__c from Lead where Id=:ld1.Id];
      System.assertEquals(ld1.LatestCampaign__c,null);
      System.assertEquals(ld1.LatestCampaignParent__c,null);
      
      Account acct1=new Account(Name='Test Acct');
      insert acct1;
      
      System.debug('CampaignMethodsTest insert ctct1');
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Contact1',LatestCampaign__c=camp4.Id);
      insert ctct1;
      
      ctct1 = [Select Id, Name, LatestCampaign__c, LatestCampaignParent__c from Contact where Id=:ctct1.Id];
      System.assertEquals(ctct1.LatestCampaign__c,camp4.Id);
      System.assertEquals(ctct1.LatestCampaignParent__c,camp2.Id);

      // check for exceptions
      Lead[] leads = new Lead[]{ld1};
      Boolean exceptionFound = false;
      try {
         CampaignMethods.checkForCampaignParent(leads, 'BadFieldName', 'AnotherBadFieldName');
      } catch (Exception e) {
         exceptionFound = true;
      }
      System.assertEquals(true,exceptionFound);
   } // testCampaignParent

   static testMethod void testGetCampaigns() {
      // create an account
      Account acct = new Account(Name='Test Account',ShippingPostalCode='14514');
      insert acct;
      
      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='TestLast1',Phone='5855551231');
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='TestLast2',Phone='5855551232');
      Contact ctct3 = new Contact(AccountId=acct.Id,LastName='TestLast3',Phone='5855551233');
      Contact ctct4 = new Contact(AccountId=acct.Id,LastName='TestLast4',Phone='5855551234');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      // create campaigns
      Campaign camp1 = new Campaign(Name='Test 1',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp2 = new Campaign(Name='Test 2',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp3 = new Campaign(Name='Test 3',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp4 = new Campaign(Name='Test 4',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign[] campaigns = new Campaign[]{camp1,camp2,camp3,camp4};
      insert campaigns;
      
      // create a map - use the code to create campaign members
      Map<Id,Id> campaignMemberMap = new Map<Id,Id>();
      campaignMemberMap.put(ctct1.Id,camp1.Id);
      campaignMemberMap.put(ctct2.Id,camp2.Id);
      campaignMemberMap.put(ctct3.Id,camp3.Id);
      campaignMemberMap.put(ctct4.Id,camp4.Id);
      
      CampaignMethods.checkToCreateCampaignMembers(campaignMemberMap);
      
      System.assertEquals(4,[select count() from CampaignMember]);

      // insert campaign members
      //CampaignMember campMember1 = new CampaignMember(CampaignId=camp1.Id, ContactId=ctct1.Id);
      //CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, ContactId=ctct1.Id);
      //CampaignMember campMember3 = new CampaignMember(CampaignId=camp3.Id, ContactId=ctct1.Id);
      //CampaignMember campMember4 = new CampaignMember(CampaignId=camp4.Id, ContactId=ctct1.Id);
      //CampaignMember[] campMembers = new CampaignMember[]{campMember1,campMember2,campMember3,campMember4};
      //insert campMembers;
      
      CampaignMember[] campaignMembers = CampaignMethods.getCampaignMembersForAccounts(new Id[]{acct.Id}, null);
      System.assertEquals(4,campaignMembers.size());
      
   } // testGetCampaigns

} // class CampaignMethodsTest