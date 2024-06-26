/* Test methods for ChatterMessageSend

  History
  -------
  01/07/2017 Dan Carmen        Created
  03/13/2020 Dan Carmen        Remove OasisSyncHelper
  08/24/2021 Dan Carmen        Replace Account Lost Notification process builder
  08/25/2021 Dan Carmen        Replace AICPA Ref Ctct chatter posts process builder
  02/02/2022 Dan Carmen        Fix Lost Client notification
  01/04/2023 Dan Carmen        Modify processChatterMessage
  
 */
@isTest
private class ChatterMessageSendTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('ReferralContactAfter', false, true, false, false,new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.createTriggerSetting('ReferralTrigger', true, true, false, false, new String[]{'ChatterMessageSend'});
      TriggerMethodsTest.saveSetupClasses();
       
      AICPAChatter__c chat1 = new AICPAChatter__c(Name='Chat1',ChatterMsg__c='This is a chatter for Chat1');
      AICPAChatter__c chat2 = new AICPAChatter__c(Name='Chat2',ChatterMsg__c='This is a chatter for Chat2');
      AICPAChatter__c[] chats = new AICPAChatter__c[]{chat1,chat2};
      insert chats;
   } // setupData

   static testMethod void testLead() {
      // force to always send so we don't worry about the user type
      ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
      // don't skip the lead triggers as part of this test
      LeadMethods.LEAD_BEFORE_EXECUTING = false;
      LeadMethods.LEAD_AFTER_EXECUTING = false;
      
      Lead ld = new Lead(Company='Test Comp', LastName='TestLast', NotifyOwner__c=true);
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      Test.startTest();
      insert ld;
      Test.stopTest();
      ld = [Select Id, Name, NotifyOwner__c from Lead where Id=:ld.Id];
      System.assertEquals(false,ld.NotifyOwner__c);
      
      //System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.contains(ld.Id));
      
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(ld.Id));
      
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      ChatterMessageSend.recordsNotified.clear();
      ChatterMessageSend.recordIdsProcessed.clear();
      
      ld.NotifyOwner__c = true;
      LeadMethods.LEAD_BEFORE_EXECUTING = false;
      LeadMethods.LEAD_AFTER_EXECUTING = false;
      TriggerMethods.clearVariables();
      Utilities.SKIP_FUTURE=true;
      update ld;
      
      //System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.contains(ld.Id));
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(ld.Id));
   } // testLead

   static testMethod void testContact() {
      // force to always send so we don't worry about the user type
      ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
      // don't skip the triggers as part of this test
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
      
      Contact ctct = new Contact(LastName='TestLast', NotifyOwner__c=true);
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      
      Test.startTest();
      insert ctct;
      Test.stopTest();
      ctct = [Select Id, Name, NotifyOwner__c from Contact where Id=:ctct.Id];
      System.assertEquals(false,ctct.NotifyOwner__c);
      //System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.contains(ctct.Id));
      
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(ctct.Id));

      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      ChatterMessageSend.recordsNotified.clear();
      ChatterMessageSend.recordIdsProcessed.clear();
      
      ctct.NotifyOwner__c = true;
      Utilities.SKIP_FUTURE=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
      update ctct;

      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(ctct.Id));
      
   } // testContact

   static testMethod void testAccount() {
      // force to always send so we don't worry about the user type
      ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
      // don't skip the triggers as part of this test
      ZipCheckOwner.SKIP_TRIGGERS = false;
      
      Account acct = new Account(Name='TestLast', NotifyOwner__c=true);
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      
      Test.startTest();
      insert acct;
      Test.stopTest();
      acct = [Select Id, Name, NotifyOwner__c from Account where Id=:acct.Id];

      System.assertEquals(false,acct.NotifyOwner__c);
      //System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.contains(acct.Id));
      
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(acct.Id));
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      ChatterMessageSend.recordsNotified.clear();
      ChatterMessageSend.recordIdsProcessed.clear();
      
      acct.NotifyOwner__c = true;
      ZipCheckOwner.SKIP_TRIGGERS = false;
      Utilities.SKIP_FUTURE=true;
      update acct;
      
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(acct.Id));
      

   } // testAccount
   
   static testMethod void testReferrals() {
      ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
      // skip the triggers as part of this test
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      ZipCheckOwner.SKIP_TRIGGERS = true;
      
      Account acct = new Account(Name='Test Acct');
      insert acct;
      Contact ctct = new Contact(LastName='TestLast', AccountId=acct.Id);
      insert ctct;
      
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
      insert opp;
      
      Referral__c ref = new Referral__c(Name='Temp Ref', Account__c=acct.Id, SourceContact__c=ctct.Id, Selling_Opportunity__c=opp.Id, NotifyOwner__c=true);
      ref.User__c=UserInfo.getUserId();
      ref.CreateSellerEvent__c=true;
      Utilities.SKIP_FUTURE=true;
      insert ref;

      ref = [select Id, Name, NotifyOwner__c from Referral__c where Id=:ref.Id];
      System.assertEquals(false,ref.NotifyOwner__c);
      
   } // testReferrals
    
   static testMethod void testAccountLost() {
      // force to always send so we don't worry about the user type
      ChatterMessageSend.acctChatActive = true;
      // skip the triggers for the insert
      ZipCheckOwner.SKIP_TRIGGERS = true;
       
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
      
      Account acct = new Account(Name='TestLast', AccountNumber='12-DAN1', ShippingState='NY', ShippingPostalCode='14624', BillingPostalCode='14624'
                                ,OwnerId=reps[0].Id, Premier_PBS_Account_Owner__c=reps[1].Id, Type='Client');
      System.assertEquals(true,ChatterMessageSend.notifyOwnerIdSet.isEmpty());
      
      insert acct;
      // just make sure a chatter wasn't sent
      System.assertEquals(false,ChatterMessageSend.recordsNotified.contains(acct.Id));
      ChatterMessageSend.recordsNotified.clear();
      ChatterMessageSend.recordIdsProcessed.clear();
      
      acct.Lost_Date__c = Date.today();
      acct.Reason_Lost__c = 'Lost';
      // make sure we hit the trigger.
      ZipCheckOwner.SKIP_TRIGGERS = false;
      update acct;
      
      System.assertEquals(true,ChatterMessageSend.recordsNotified.contains(acct.Id));
   } // testAccountLost
    
   static testMethod void testRefCtctAicpa() {
      User runningUser = UserHelper.getRunningUser();
      // so the trigger fires as COE user
      ProcessNameMap__c pnm = new ProcessNameMap__c(Name=RecordTypeHelper.cleanRtName(UserHelper.PREFIX_COE+runningUser.Name), IsActive__c=true);
      insert pnm;
       
      Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Acct');
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      insert refAcct;
       
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Test Ctct1', AICPA_Original_Type__c='Chat1');
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Test Ctct2', AICPA_Original_Type__c='ChatBad');
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;
      
      System.assertEquals(true, ChatterMessageSend.recordsNotified.contains(refCtct1.Id));
      System.assertEquals(false, ChatterMessageSend.recordsNotified.contains(refCtct2.Id));
       
      ChatterMessageSend.recordsNotified.clear();
      ChatterMessageSend.recordIdsProcessed.clear();
      
      refCtct2.AICPA_Original_Type__c='Chat2';
      ReferralAccountMethods.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();      
      update refCtcts;
       
      System.assertEquals(false, ChatterMessageSend.recordsNotified.contains(refCtct1.Id));
      System.assertEquals(true, ChatterMessageSend.recordsNotified.contains(refCtct2.Id));
       
   } // testRefCtctAicpa

} // class ChatterMessageSendTest