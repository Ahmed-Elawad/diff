/*  
 * Test methods for the NSSViewController, NSSViewHelper, and NSSViewWrapper
 * 
 * History
 * -------
   08/05/2014 Dan Carmen   Created
   10/27/2017 Dan Carmen         Changes for lightning UI
   09/18/2018 Dan Carmen         Adjust test for new Lead Company methods
   10/23/2018 Jacob Hinds        Added @testSetup to match production.  Adding in email address for records marked EOO.
   12/11/2018 Dan Carmen         Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   12/27/2018 Dan Carmen         Add in changes for qbdialer__Callback_Date_Time__c to move to DialSource
   10/15/2019 Dan Carmen         Change to use TriggerMethods.clearVariables
   08/16/2022 Josh Cartwrigth    upated API version of test class 

 */
@isTest
private class NSSViewTest {
   @testSetup
   public static void setupData(){
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, new String[]{'CampaignMethods'},setupClasses, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, new String[]{'LeadCompanyMethods','CampaignMethods'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
   } // setupData
   
   static testMethod void testLead() {
    LeadCompanyMethods.SKIP_FUTURE=true;
    // create a referral account so we can link to the lead
    Referral_Account__c refAcct = new Referral_Account__c(Name='Test Ref Acct');
    insert refAcct;
    
    Referral_Contact__c refCtct = new Referral_Contact__c(Name='Jimmy Test', Referral_Account__c=refAcct.Id, Sensitivity_401_k__c=true, Sensitivity_FSA__c=true);
    insert refCtct;

      // create campaigns
      Campaign camp1 = new Campaign(Name='Test 1',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp2 = new Campaign(Name='Test 2',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp3 = new Campaign(Name='Test 3',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp4 = new Campaign(Name='Test 4',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign[] campaigns = new Campaign[]{camp1,camp2,camp3,camp4};
      insert campaigns;
      
    
    // create a Lead
    Lead l1 = new Lead(LastName='TestLast1', Company='Test Lead Company', PostalCode='14514', Referral_Contact__c=refCtct.Id, Phone = '585-456-7890',Email='test@tes.t',DoNotCall=true, HasOptedOutOfEmail=true
                      ,LatestCampaign__c=camp1.Id);
    insert l1;
    
    // lead company attached?
    l1 = [Select Id, Name, LastName, Company, PostalCode, Referral_Contact__c, Lead_Company__c, LeadGroupId__c from Lead where Id=:l1.Id];
    System.assertEquals(true, (l1.Lead_Company__c != null));
    
    // create a couple of additional leads to treat as extra contacts
    Lead l2 = new Lead(LastName='TestLast2',Company=l1.Company, PostalCode=l1.PostalCode, LeadGroupId__c=l1.LeadGroupId__c, Lead_Company__c=l1.Lead_Company__c);
      Lead l3 = new Lead(LastName='TestLast3',Company=l1.Company, PostalCode=l1.PostalCode, LeadGroupId__c=l1.LeadGroupId__c, Lead_Company__c=l1.Lead_Company__c);
      Lead[] leads = new Lead[]{l2,l3};
      TriggerMethods.clearVariables();
      insert leads;
    
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                    ,ProspectingStart__c=Date.today().addDays(-2)
                    ,Lead__c=l1.Id, NSR_Name__c=UserInfo.getUserId());

      // insert campaign members
      //CampaignMember campMember1 = new CampaignMember(CampaignId=camp1.Id, LeadId=l1.Id);
      CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, LeadId=l1.Id);
      CampaignMember campMember3 = new CampaignMember(CampaignId=camp3.Id, LeadId=l1.Id);
      CampaignMember campMember4 = new CampaignMember(CampaignId=camp4.Id, LeadId=l1.Id);
      CampaignMember[] campMembers = new CampaignMember[]{campMember2,campMember3,campMember4};
      //CampaignMember[] campMembers = new CampaignMember[]{campMember1,campMember2,campMember3,campMember4};
      TriggerMethods.clearVariables();
      insert campMembers;

      User otherUser = [Select Id, Name from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true and Id != :UserInfo.getUserId() limit 1];      
      // my tasks
      Task tsk1 = new Task(Subject='Task1',WhoId=l1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      Task tsk2 = new Task(Subject='Task2',WhoId=l1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      // create a callback
      //Task tsk3 = new Task(Subject='Callback',WhoId=l1.Id,ActivityDate=Date.today().addMonths(1),Status='New',qbdialer__Callback_Date_Time__c=DateTime.now().addDays(3));
      Task tsk3 = new Task(Subject='Callback',Type=TaskHelper.CT_CALLBACK,WhoId=l1.Id,ActivityDate=Date.today().addMonths(1),Status='New',ReminderDateTime=DateTime.now().addDays(3));
      // other tasks
      Task tsk4 = new Task(Subject='Task4',WhoId=l1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed', OwnerId=otherUser.Id);
      Task tsk5 = new Task(Subject='Task5',WhoId=l1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed', OwnerId=otherUser.Id);
      Task tsk6 = new Task(Subject='Task6',WhoId=l1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed', OwnerId=otherUser.Id);
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4,tsk5,tsk6};
      insert tsks;
      
      // open events
      DateTime openActivityDate = DateTime.now().addMonths(1);
      Event evnt1 = new Event(Subject='Event1',WhoId=l1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt2 = new Event(Subject='Event2',WhoId=l1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt3 = new Event(Subject='Event3',WhoId=l1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      // closed events
      DateTime closedActivityDate = DateTime.now().addMonths(-1);
      Event evnt4 = new Event(Subject='Event4',WhoId=l1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60, OwnerId=otherUser.Id);
      Event evnt5 = new Event(Subject='Event5',WhoId=l1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60, OwnerId=otherUser.Id);
      Event evnt6 = new Event(Subject='Event6',WhoId=l1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60, OwnerId=otherUser.Id);
      Event[] evnts = new Event[]{evnt1,evnt2,evnt3,evnt4,evnt5,evnt6};
      insert evnts;
      
      // set to a lower number to be able to test "hasMore"
      NSSViewHelper.NUM_TO_DISPLAY = 2;
      
      System.currentPageReference().getParameters().put('Id',l1.Id);

      NSSViewController nvc = new NSSViewController();
      
      System.assertEquals(true,nvc.hasCampaignData);
      System.assertEquals(true,nvc.hasOtherActivity);
      System.assertEquals(true,nvc.hasSensitivities);
      System.assertEquals(true,nvc.hasMyActivity);
      System.assertEquals(true,nvc.hasCallbacks);
      
      System.assertEquals(true,nvc.callbacks[0].callbackInfo.contains('Open Callback for'));
      
      System.assertEquals(false,nvc.hasOpps);
      System.assertEquals(true,nvc.hasOtherCtcts);
      System.assertEquals(true,nvc.hasLead);
      System.assertEquals(false,nvc.hasAccount);
      System.assertEquals(false,nvc.hasContact);

      System.assertEquals(true,nvc.hasOptOut);
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Call'));
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Email'));
      
      System.assertEquals(true,nvc.hasLatestCampaign);
      System.assertEquals(true,nvc.campaignMsg.contains(camp1.Name));

      System.assertEquals(2,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(true,nvc.campaignHelper.hasMoreRecords);
      nvc.campaignHelper.displayMore();
      System.assertEquals(4,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(false,nvc.campaignHelper.hasMoreRecords);

      //System.assertEquals(2,nvc.contactHelper.displayRecs.size());

      System.assertEquals(false,nvc.addingNewContact);
      System.assertEquals(false,nvc.showAddContactForm);

      nvc.addNewContact();
      System.assertEquals(true,nvc.addingNewContact);
      System.assertEquals(true,nvc.showAddContactForm);
      
      nvc.newLead.FirstName = 'Sammy';
      nvc.newLead.LastName = 'TestLead4';
      nvc.newLead.Phone = '555-123-5678';
      nvc.newLead.Email = 'sammy.testlead4@testing.com';
      
      nvc.saveNewContact();
      nvc.saveRecordChanges();
      
      // test the exception code (expects only task ids);
      System.currentPageReference().getParameters().put('tskId',evnt1.id);
      System.currentPageReference().getParameters().put('closeStatus','Completed');
      nvc.closeCallback();

      // test that the callback is closed
      System.currentPageReference().getParameters().put('tskId',tsk3.Id);
      System.currentPageReference().getParameters().put('closeStatus','Completed');
      nvc.closeCallback();
      tsk3 = [Select Id, Subject, Status from Task where Id=:tsk3.Id];
      System.debug('testLead tsk3='+tsk3);
      System.assertEquals('Completed',tsk3.Status);
      
   } // testLead

   static testMethod void testAccts() {
      // create a referral account so we can link to the account
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Ref Acct');
      insert refAcct;
      
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Jimmy Test', Referral_Account__c=refAcct.Id, Sensitivity_401_k__c=true, Sensitivity_FSA__c=true);
      insert refCtct;
      
      Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
      Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create an account
      Account acct = new Account(Name='Test Account',ShippingPostalCode='14514', CPA_Name_Ref__c=refCtct.Id, RecordTypeId=rtAcct.getRecordTypeId(),Do_Not_Call__c=true,Email_Opt_Out__c=true );
      insert acct;

      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='TestLast1',Phone='5855551231', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='TestLast2',Phone='5855551232', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact ctct3 = new Contact(AccountId=acct.Id,LastName='TestLast3',Phone='5855551233', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact ctct4 = new Contact(AccountId=acct.Id,LastName='TestLast4',Phone='5855551234', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      // create campaigns
      Campaign camp1 = new Campaign(Name='Test 1',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp2 = new Campaign(Name='Test 2',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp3 = new Campaign(Name='Test 3',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp4 = new Campaign(Name='Test 4',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign[] campaigns = new Campaign[]{camp1,camp2,camp3,camp4};
      insert campaigns;
      
      // insert campaign members
      CampaignMember campMember1 = new CampaignMember(CampaignId=camp1.Id, ContactId=ctct1.Id);
      CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, ContactId=ctct1.Id);
      CampaignMember campMember3 = new CampaignMember(CampaignId=camp3.Id, ContactId=ctct1.Id);
      CampaignMember campMember4 = new CampaignMember(CampaignId=camp4.Id, ContactId=ctct2.Id);
      CampaignMember[] campMembers = new CampaignMember[]{campMember1,campMember2,campMember3,campMember4};
      insert campMembers;
      
      User otherUser = [Select Id, Name from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true and Id != :UserInfo.getUserId() limit 1];      
      // insert open tasks
      Task tsk1 = new Task(Subject='Task1',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      Task tsk2 = new Task(Subject='Task2',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      Task tsk3 = new Task(Subject='Task3',WhoId=ctct2.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      // closed tasks
      Task tsk4 = new Task(Subject='Task4',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task tsk5 = new Task(Subject='Task5',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task tsk6 = new Task(Subject='Task6',WhoId=ctct2.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4,tsk5,tsk6};
      insert tsks;
      
      // open events
      DateTime openActivityDate = DateTime.now().addMonths(1);
      Event evnt1 = new Event(Subject='Event1',WhoId=ctct1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt2 = new Event(Subject='Event2',WhoId=ctct1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt3 = new Event(Subject='Event3',WhoId=ctct2.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      // closed events
      DateTime closedActivityDate = DateTime.now().addMonths(-1);
      Event evnt4 = new Event(Subject='Event4',WhoId=ctct1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event evnt5 = new Event(Subject='Event5',WhoId=ctct1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event evnt6 = new Event(Subject='Event6',WhoId=ctct2.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event[] evnts = new Event[]{evnt1,evnt2,evnt3,evnt4,evnt5,evnt6};
      insert evnts;
      
      Opportunity opp1 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity1', StageName='Pending', CloseDate=Date.today().addMonths(1), OpportunityType__c='Payroll');
      Opportunity opp2 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity2', StageName='Pending', CloseDate=Date.today().addMonths(1));
      Opportunity opp3 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity3', StageName='Pending', CloseDate=Date.today().addMonths(1));
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      Asset asst1 = new Asset(AccountId=acct.Id, Name='Test Asset1', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test1');
      Asset asst2 = new Asset(AccountId=acct.Id, Name='Test Asset2', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test2');
      Asset asst3 = new Asset(AccountId=acct.Id, Name='Test Asset3', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test3');
      Asset[] assets = new Asset[]{asst1,asst2,asst3};
      insert assets;

      Prospect_Ownership__c po1 = new Prospect_Ownership__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                    ,ProspectingStart__c=Date.today().addDays(-2)
                    ,Prospect_Client__c=acct.Id, NSR_Name__c=UserInfo.getUserId());
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                    ,LockoutStart__c=Date.today().addDays(-2)
                    ,Prospect_Client__c=acct.Id, NSR_Name__c=UserInfo.getUserId());
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2};
      insert pos;
      
      // set to a lower number to be able to test "hasMore"
      NSSViewHelper.NUM_TO_DISPLAY = 3;
      
      // with no id passed in.
      NSSViewController nvc = new NSSViewController();

      // set at the account level
      System.currentPageReference().getParameters().put('Id',acct.Id);

      nvc = new NSSViewController();
      
      System.assertEquals(true,nvc.hasCampaignData);
      System.assertEquals(true,nvc.hasOtherActivity);
      System.assertEquals(true,nvc.hasSensitivities);
      System.assertEquals(true,nvc.hasMyActivity);
      System.assertEquals(true,nvc.hasOpps);
      System.assertEquals(true,nvc.hasOtherCtcts);
      System.assertEquals(true,nvc.hasAssets2);
      System.assertEquals(true,nvc.hasAccount);
      System.assertEquals(false,nvc.hasLead);
      System.assertEquals(false,nvc.hasTimeZone);
      System.assertEquals(true,nvc.showLatestPayOpp);
      System.assertEquals(true,String.IsNotBlank(nvc.lastestPayOppDate));
      
      System.assertEquals(true,nvc.hasOwnershipMsg);
      System.assertEquals(true,nvc.showKeyInfo);

      System.assertEquals(true,nvc.hasOptOut);
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Call'));
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Email'));

      System.assertEquals(3,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(true,nvc.campaignHelper.hasMoreRecords);
      nvc.campaignHelper.displayMore();
      System.assertEquals(4,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(false,nvc.campaignHelper.hasMoreRecords);

      //System.assertEquals(3,nvc.contactHelper.displayRecs.size());

      //NSSViewWrapper contactNvw = nvc.contactHelper.allRecords[0];
      //System.assertEquals(true,contactNvw.isContact);
      //System.assertEquals(false,contactNvw.isCampaignMember);
      //System.assertEquals(false,contactNvw.isEvent);
      //System.assertEquals(false,contactNvw.isTask);
      //System.assertEquals(false,contactNvw.isOpportunity);
      //System.assertEquals(false,contactNvw.isLead);
      //System.assertEquals(false,contactNvw.isAsset);
      
      // call from a contact
      System.currentPageReference().getParameters().put('Id',ctct1.Id);
      nvc = new NSSViewController();
      //System.assertEquals(true,nvc.hasCampaignData);
      System.assertEquals(true,nvc.hasOtherActivity);
      System.assertEquals(true,nvc.hasSensitivities);
      System.assertEquals(true,nvc.hasMyActivity);
      System.assertEquals(true,nvc.hasOpps);
      System.assertEquals(true,nvc.hasOtherCtcts);

      System.assertEquals(3,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(false,nvc.campaignHelper.hasMoreRecords);

      //System.assertEquals(3,nvc.contactHelper.displayRecs.size());

      nvc.addNewContact();
      System.assertEquals(true,nvc.addingNewContact);
      System.assertEquals(true,nvc.showAddContactForm);
      
      nvc.newContact.FirstName = 'Sammy';
      nvc.newContact.LastName = 'TestLead5';
      nvc.newContact.Phone = '555-123-5678';
      nvc.newContact.Email = 'sammy.testlead4@testing.com';
      
      nvc.saveNewContact();
      nvc.saveRecordChanges();

   } // testAccts
   
   static testMethod void testCtct() {
      // create a referral account so we can link to the account
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Ref Acct');
      insert refAcct;
      
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Jimmy Test', Referral_Account__c=refAcct.Id, Sensitivity_401_k__c=true, Sensitivity_FSA__c=true);
      insert refCtct;
      
      Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
      Schema.RecordTypeInfo rtCtct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, 'Contact');

      // create an account
      Account acct = new Account(Name='Test Account',ShippingPostalCode='14514', CPA_Name_Ref__c=refCtct.Id, RecordTypeId=rtAcct.getRecordTypeId() );
      insert acct;

      Contact ctct1 = new Contact(AccountId=acct.Id,LastName='TestLast1',Phone='5855551231', Email='test@tes.t',RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true, DoNotCall=true, HasOptedOutOfEmail=true);
      Contact ctct2 = new Contact(AccountId=acct.Id,LastName='TestLast2',Phone='5855551232', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact ctct3 = new Contact(AccountId=acct.Id,LastName='TestLast3',Phone='5855551233', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact ctct4 = new Contact(AccountId=acct.Id,LastName='TestLast4',Phone='5855551234', RecordTypeId=rtCtct.getRecordTypeId(), Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;
      
      acct.SignificantContact__c=ctct1.Id;
      update acct;
      
      // create campaigns
      Campaign camp1 = new Campaign(Name='Test 1',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp2 = new Campaign(Name='Test 2',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp3 = new Campaign(Name='Test 3',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign camp4 = new Campaign(Name='Test 4',IsActive=true, StartDate=Date.today().addMonths(-1));
      Campaign[] campaigns = new Campaign[]{camp1,camp2,camp3,camp4};
      insert campaigns;
      
      // insert campaign members
      CampaignMember campMember1 = new CampaignMember(CampaignId=camp1.Id, ContactId=ctct1.Id);
      CampaignMember campMember2 = new CampaignMember(CampaignId=camp2.Id, ContactId=ctct1.Id);
      CampaignMember campMember3 = new CampaignMember(CampaignId=camp3.Id, ContactId=ctct1.Id);
      CampaignMember campMember4 = new CampaignMember(CampaignId=camp4.Id, ContactId=ctct2.Id);
      CampaignMember[] campMembers = new CampaignMember[]{campMember1,campMember2,campMember3,campMember4};
      insert campMembers;
      
      User otherUser = [Select Id, Name from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true and Id != :UserInfo.getUserId() limit 1];      
      // insert open tasks
      Task tsk1 = new Task(Subject='Task1',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      Task tsk2 = new Task(Subject='Task2',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      Task tsk3 = new Task(Subject='Task3',WhoId=ctct2.Id,ActivityDate=Date.today().addMonths(1),Status='New');
      // closed tasks
      Task tsk4 = new Task(Subject='Task4',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task tsk5 = new Task(Subject='Task5',WhoId=ctct1.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task tsk6 = new Task(Subject='Task6',WhoId=ctct2.Id,ActivityDate=Date.today().addMonths(-1),Status='Closed',OwnerId=otherUser.Id);
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4,tsk5,tsk6};
      insert tsks;
      
      // open events
      DateTime openActivityDate = DateTime.now().addMonths(1);
      Event evnt1 = new Event(Subject='Event1',WhoId=ctct1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt2 = new Event(Subject='Event2',WhoId=ctct1.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      Event evnt3 = new Event(Subject='Event3',WhoId=ctct2.Id,ActivityDate=openActivityDate.date(), ActivityDateTime=openActivityDate, DurationInMinutes=60);
      // closed events
      DateTime closedActivityDate = DateTime.now().addMonths(-1);
      Event evnt4 = new Event(Subject='Event4',WhoId=ctct1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event evnt5 = new Event(Subject='Event5',WhoId=ctct1.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event evnt6 = new Event(Subject='Event6',WhoId=ctct2.Id,ActivityDate=closedActivityDate.date(), ActivityDateTime=closedActivityDate, DurationInMinutes=60,OwnerId=otherUser.Id);
      Event[] evnts = new Event[]{evnt1,evnt2,evnt3,evnt4,evnt5,evnt6};
      insert evnts;
      
      Opportunity opp1 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity1', StageName='Pending', CloseDate=Date.today().addMonths(1));
      Opportunity opp2 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity2', StageName='Pending', CloseDate=Date.today().addMonths(1));
      Opportunity opp3 = new Opportunity(AccountId=acct.Id, Name='Test Opportunity3', StageName='Pending', CloseDate=Date.today().addMonths(1));
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      Asset asst1 = new Asset(AccountId=acct.Id, Name='Test Asset1', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test1');
      Asset asst2 = new Asset(AccountId=acct.Id, Name='Test Asset2', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test2');
      Asset asst3 = new Asset(AccountId=acct.Id, Name='Test Asset3', Start_Date__c = Date.today().addMonths(-1), Product_Plan_Code__c='Test3',Plan_Cancel_Date__c=Date.today().addDays(-1));
      Asset[] assets = new Asset[]{asst1,asst2,asst3};
      insert assets;

      Prospect_Ownership__c po1 = new Prospect_Ownership__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=ProspectOwnershipMethods.STAGE_PROSPECTING
                    ,ProspectingStart__c=Date.today().addDays(-2)
                    ,Prospect_Client__c=acct.Id, NSR_Name__c=UserInfo.getUserId());
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND
                    ,StartDate__c=Date.today().addDays(-2), Ownership_Status__c=ProspectOwnershipMethods.STAGE_LOCKOUT
                    ,LockoutStart__c=Date.today().addDays(-2)
                    ,Prospect_Client__c=acct.Id, NSR_Name__c=UserInfo.getUserId());
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2};
      insert pos;
      
      // set to a lower number to be able to test "hasMore"
      NSSViewHelper.NUM_TO_DISPLAY = 3;
      
      // with no id passed in.
      NSSViewController nvc = new NSSViewController();

      // set at the account level
      System.currentPageReference().getParameters().put('Id',ctct1.Id);

      nvc = new NSSViewController();
      
      System.assertEquals(true,nvc.hasCampaignData);
      System.assertEquals(true,nvc.hasOtherActivity);
      System.assertEquals(true,nvc.hasSensitivities);
      System.assertEquals(true,nvc.hasMyActivity);
      System.assertEquals(true,nvc.hasOpps);
      System.assertEquals(true,nvc.hasOtherCtcts);
      System.assertEquals(true,nvc.hasAssets2);
      System.assertEquals(true,nvc.hasAccount);
      System.assertEquals(false,nvc.hasLead);
      
      //System.assertEquals(true,nvc.hasActiveAssets);
      //System.assertEquals(true,nvc.hasInactiveAssets);
      
      //System.assertEquals(false,nvc.showActiveAssets);
      //System.assertEquals(false,nvc.showInactiveAssets);
      //nvc.toggleActiveAssets();
      //nvc.toggleInactiveAssets();
      //System.assertEquals(true,nvc.showActiveAssets);
      //System.assertEquals(true,nvc.showInactiveAssets);

      
      System.assertEquals(true,nvc.hasOwnershipMsg);
      System.assertEquals(true,nvc.showKeyInfo);

      System.assertEquals(true,nvc.hasOptOut);
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Call'));
      System.assertEquals(true,nvc.optOutMsg.contains('Do Not Email'));

      System.assertEquals(3,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(false,nvc.campaignHelper.hasMoreRecords);

     // System.assertEquals(3,nvc.contactHelper.displayRecs.size());

      //NSSViewWrapper contactNvw = nvc.contactHelper.allRecords[0];
      //System.assertEquals(true,contactNvw.isContact);
      //System.assertEquals(false,contactNvw.isCampaignMember);
      //System.assertEquals(false,contactNvw.isEvent);
      //System.assertEquals(false,contactNvw.isTask);
      //System.assertEquals(false,contactNvw.isOpportunity);
      //System.assertEquals(false,contactNvw.isLead);
      //System.assertEquals(false,contactNvw.isAsset);
      
      // call from a contact
      System.currentPageReference().getParameters().put('Id',ctct1.Id);
      nvc = new NSSViewController();
      //System.assertEquals(true,nvc.hasCampaignData);
      System.assertEquals(true,nvc.hasOtherActivity);
      System.assertEquals(true,nvc.hasSensitivities);
      System.assertEquals(true,nvc.hasMyActivity);
      System.assertEquals(true,nvc.hasOpps);
      System.assertEquals(true,nvc.hasOtherCtcts);

      System.assertEquals(3,nvc.campaignHelper.displayRecs.size());
      System.assertEquals(false,nvc.campaignHelper.hasMoreRecords);

      //System.assertEquals(3,nvc.contactHelper.displayRecs.size());
      
      System.currentPageReference().getParameters().put('SignificantId',ctct3.Id);
      nvc.changeSignificance();
      
      nvc.addNewContact();
      nvc.cancelNewContact();
      System.assertEquals(null,nvc.newLead);
      System.assertEquals(null,nvc.newContact);
   } // testCtct
   
   static testMethod void testMisc() {
      NSSViewController nvc = new NSSViewController();
      NSSViewController.SHOW_NEW_FORM = true;
      System.assertEquals(true,nvc.showNewForm);
      
      // defaults to open
      System.assertEquals(true,nvc.companySectionExpanded);
      nvc.changeAcctSection();
      System.assertEquals(false,nvc.companySectionExpanded);
      nvc.changeAcctSection();
      System.assertEquals(true,nvc.companySectionExpanded);

      System.assertEquals(false,nvc.ctctSectionExpanded);
      nvc.changeCtctSection();
      System.assertEquals(true,nvc.ctctSectionExpanded);
      nvc.changeCtctSection();
      System.assertEquals(false,nvc.ctctSectionExpanded);
      
      nvc.ownershipMsg = 'Has Ownership';
      nvc.ownershipIsRunningUser = true;
      nvc.prospectingOwnership = true;
      nvc.lockoutOwnership = false;
      nvc.notInterestedOwnership = false;
      System.assertEquals(NSSViewController.COLOR_GREEN,nvc.ownershipColor);
      System.assertEquals(NSSViewController.FONT_NORMAL,nvc.ownershipFontSize);
      
      nvc.prospectingOwnership = false;
      nvc.lockoutOwnership = true;
      System.assertEquals(NSSViewController.COLOR_YELLOW,nvc.ownershipColor);
      System.assertEquals(NSSViewController.FONT_YELLOW_RED,nvc.ownershipFontSize);
      
      nvc.ownershipIsRunningUser = false;
      nvc.prospectingOwnership = true;
      nvc.lockoutOwnership = false;
      System.assertEquals(NSSViewController.COLOR_YELLOW,nvc.ownershipColor);
      System.assertEquals(NSSViewController.FONT_YELLOW_RED,nvc.ownershipFontSize);
      
      nvc.ownershipIsRunningUser = false;
      nvc.prospectingOwnership = false;
      nvc.lockoutOwnership = true;
      System.assertEquals(NSSViewController.COLOR_RED,nvc.ownershipColor);
      System.assertEquals(NSSViewController.FONT_YELLOW_RED,nvc.ownershipFontSize);
      
      System.assertEquals(true,nvc.submitReferralURL != null);
      System.assertEquals(true,nvc.showErrorSection);
      
      System.assertEquals(NSSViewController.COLOR_RED,nvc.colorRed);

      nvc.recId='Test';
      nvc.isPopup=false;
      
      System.assertEquals(false,nvc.showSubmitReferralForm);
      nvc.toggleSubmitReferral();
      System.assertEquals(true,nvc.showSubmitReferralForm);
      
      Account acct = new Account(Name='Test Account');
      nvc.acct = acct;
      
      System.assertEquals(false,nvc.isLostClient);
      acct.Type = Label.AccountTypeLost;
      acct.Lost_Date__c = Date.today();
      acct.Reason_Lost__c = 'They wanted to leave!';
      
      System.assertEquals(true,nvc.isLostClient);
      System.assertEquals(true,nvc.lostInfo.contains(acct.Reason_Lost__c));
      
   } // testMisc
   
   public static void setupRefPartners() {
      UserHelperTest.setupSalesOrgSetting();
      // make sure there are no existing records
      if ([Select count() from Referral_Partner__c] > 0) {
         Database.Delete([Select Id from Referral_Partner__c],true);
      }
      Referral_Partner__c[] partners = new Referral_Partner__c[]{};
      for (String salesOrg : UserHelper.DIVISION_LIST) {
         Referral_Partner__c rp = new Referral_Partner__c(Name=salesOrg,Partner_Type__c=ReferralController.REF_NSS,Sort_Order__c=partners.size()+1,Ref_To_Type__c='User',CreateRefOpp__c=false,UseApprovalProcess__c=false, IsActive__c=true, Always_Check_Send_Email__c=false);
         partners.add(rp);
      }
    
      insert partners;

   } // setupRefPartners
   
   /*
   static testMethod void testGetReferralPartners() {
      setupRefPartners();
      Account acct = new Account(Name='Test Acct');
      insert acct;
      
      NSSViewController.getReferralPartners(acct.Id, 'true');
      
   } // testGetReferralPartners
   */
   static testMethod void testNSSViewWrapper() {
      
      Task tsk = new Task(CallDateTime__c=DateTime.now(), ActivityDate=Date.today());
      NSSViewWrapper nvwTsk = new NSSViewWrapper(tsk);
      System.assertEquals(tsk.CallDateTime__c, nvwTsk.activityDateTime);
      System.assertEquals(tsk.ActivityDate, nvwTsk.activityDate);
      
      System.assertEquals(true, nvwTsk.hasCallDate);
      nvwTsk.toggleLongDesc();
      
      Opportunity opp = new Opportunity(Name='Test Opp', CloseDate=Date.today().addDays(3), StageName='Pending');
      NSSViewWrapper nvwOpp = new NSSViewWrapper(opp);
      System.assertEquals(true, nvwOpp.formattedDate != null);
      
      System.assertEquals(false, nvwOpp.hasProductSalesRep);
      System.assertEquals(false, nvwOpp.auditIsNew);
      System.assertEquals(false, nvwOpp.linkHasOtherInfo);
      
      System.assertEquals('', nvwOpp.otherSales);
      
   } // testNSSViewWrapper
   
} // class NSSViewTest