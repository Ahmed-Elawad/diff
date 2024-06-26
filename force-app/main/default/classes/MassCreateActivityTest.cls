/* 
 * Test Methods for the MassCreateActivity class.
 *
 * History
 * -------
 * 02/08/2012 Dan Carmen   Created
 * 03/06/2016 Cindy Freeman		Modified to use Account.Type not Leadsource for the WAR Lead source on the Task or Event
   09/27/2017 Dan Carmen        Changes so this will work for a single record, not just a list view
 *
 */
@isTest
private class MassCreateActivityTest {

   /** Test when no records are passed into the controller.
    */
   static testMethod void testNoRecords() {
      Contact[] contacts = new Contact[]{};
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
      ssc.setSelected(contacts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(false,mca.hasRecords);
      System.assertEquals(false,mca.useWhat);
   } // testNoRecords
   
   static testMethod void testContactTasks() {
      Account[] accounts = new Account[]{};
      accounts.add(new Account(Name='Account Test1',Type = 'Prospect'));
      accounts.add(new Account(Name='Account Test2',Type = 'CORE Client'));
      accounts.add(new Account(Name='Account Test3',Type = 'Prospect'));
      insert accounts;
      Contact[] contacts = new Contact[]{};
      contacts.add(new Contact(FirstName='Test', LastName='Test1', LeadSource='Test Lead',AccountId = accounts.get(0).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test2', LeadSource='Test Lead',AccountId = accounts.get(1).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test3', LeadSource='Test Lead',AccountId = accounts.get(2).Id));
      insert contacts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
      ssc.setSelected(contacts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(false,mca.useWhat);
      String retUrl = mca.save().getUrl();

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Contact.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] contactIds = new Id[]{};
      for (Contact ctct : contacts) {
         contactIds.add(ctct.Id);
      }
      Contact[] ctcts = [Select Id, Account.Type, (Select Id, Lead_Source_WAR_Call_Type__c from Tasks) from Contact where Id in :contactIds];
      // verify correct number returned
      System.assertEquals(contacts.size(), ctcts.size());
      // verify each Contact has one Task and Lead Source is set
      for (Contact ctct : ctcts) {
         System.assertEquals(1,ctct.Tasks.size());
         System.assertEquals(ctct.Account.Type,ctct.Tasks.get(0).Lead_Source_WAR_Call_Type__c);
      } // for

   } // testContactTasks

   static testMethod void testContactEvents() {
      Account[] accounts = new Account[]{};
      accounts.add(new Account(Name='Account Test1',Type = 'Prospect'));
      accounts.add(new Account(Name='Account Test2',Type = 'CORE Client'));
      accounts.add(new Account(Name='Account Test3',Type = 'Prospect'));
      insert accounts;
      Contact[] contacts = new Contact[]{};
      contacts.add(new Contact(FirstName='Test', LastName='Test1', LeadSource='Test Lead',AccountId = accounts.get(0).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test2', LeadSource='Test Lead',AccountId = accounts.get(1).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test3', LeadSource='Test Lead',AccountId = accounts.get(2).Id));
      insert contacts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
      ssc.setSelected(contacts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(false,mca.useWhat);
      System.assertEquals('Task',mca.activityType);
      
      // switch to Event
      mca.activityType = 'Event';
      System.assertEquals(null,mca.changeActivity());
      System.assertEquals('Event',mca.activityType);
      
      String retUrl = mca.save().getUrl();

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Contact.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] contactIds = new Id[]{};
      for (Contact ctct : contacts) {
         contactIds.add(ctct.Id);
      }
      Contact[] ctcts = [Select Id,Account.Type,(Select Id, Lead_Source_WAR_Call_Type__c from Events) from Contact where Id in :contactIds];
      // verify correct number returned
      System.assertEquals(contacts.size(), ctcts.size());
      // verify each Contact has one Event and Lead Source is set
      for (Contact ctct : ctcts) {
         System.assertEquals(1,ctct.Events.size());
         System.assertEquals(ctct.Account.Type,ctct.Events.get(0).Lead_Source_WAR_Call_Type__c);
      } // for

   } // testContactEvents

   static testMethod void testuseFirstActivity() {
      Account[] accounts = new Account[]{};
      accounts.add(new Account(Name='Account Test1',Type = 'Prospect'));
      accounts.add(new Account(Name='Account Test2',Type = 'CORE Client'));
      accounts.add(new Account(Name='Account Test3',Type = 'Prospect'));
      insert accounts;
      Contact[] contacts = new Contact[]{};
      contacts.add(new Contact(FirstName='Test', LastName='Test1', LeadSource='Test Lead',AccountId = accounts.get(0).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test2', LeadSource='Test Lead',AccountId = accounts.get(1).Id));
      contacts.add(new Contact(FirstName='Test', LastName='Test3', LeadSource='Test Lead',AccountId = accounts.get(2).Id));
      insert contacts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
      ssc.setSelected(contacts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(false,mca.useWhat);
      
      // verify 3 tasks
      System.assertEquals(contacts.size(), mca.taskList.size());
      // set values on first task
      Task firstTask = mca.taskList.get(0);
      firstTask.Type='Test Type';
      firstTask.Subject='Test Subject';
      firstTask.Description='Test Description';
      firstTask.ActivityDate=Date.today().addDays(5);
      
      // set the flag to use the values in first task for all tasks
      mca.useFirstActivity = true;
      
      String retUrl = mca.save().getUrl();

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Contact.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] contactIds = new Id[]{};
      for (Contact ctct : contacts) {
         contactIds.add(ctct.Id);
      }
      Contact[] ctcts = [Select Id,Account.Type, (Select Id, Subject, Type, Description, ActivityDate, Lead_Source_WAR_Call_Type__c from Tasks) from Contact where Id in :contactIds];
      // verify correct number returned
      System.assertEquals(contacts.size(), ctcts.size());
      // verify each Contact has one Task and Lead Source is set
      for (Contact ctct : ctcts) {
         System.assertEquals(1,ctct.Tasks.size());
         Task checkTask = ctct.Tasks.get(0);
         System.assertEquals(ctct.Account.Type,checkTask.Lead_Source_WAR_Call_Type__c);
         System.assertEquals('Test Type',checkTask.Type);
         System.assertEquals('Test Subject',checkTask.Subject);
         System.assertEquals('Test Description',checkTask.Description);
         System.assertEquals(Date.today().addDays(5),checkTask.ActivityDate);
      } // for

   } // testuseFirstActivity


   static testMethod void testAccountTasks() {
      Account[] accounts = new Account[]{};
      accounts.add(new Account(Name='Test1', Type='Prospect',Lead_Source__c='Test Lead'));
      accounts.add(new Account(Name='Test2', Type = 'CORE Client', Lead_Source__c='Test Lead'));
      accounts.add(new Account(Name='Test3', Type = 'Prospect',Lead_Source__c='Test Lead'));
      insert accounts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(accounts);
      ssc.setSelected(accounts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(true,mca.useWhat);
      System.assertEquals(false,mca.useWho);
      String retUrl = mca.save().getUrl();

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Account.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] accountIds = new Id[]{};
      for (Account acct : accounts) {
         accountIds.add(acct.Id);
      }
      Account[] accts = [Select Id, Type,(Select Id, Lead_Source_WAR_Call_Type__c from Tasks) from Account where Id in :accountIds];
      // verify correct number returned
      System.assertEquals(accounts.size(), accts.size());
      // verify each Contact has one Task and Lead Source is set
      for (Account acct : accts) {
         System.assertEquals(1,acct.Tasks.size());
         System.assertEquals(acct.Type,acct.Tasks.get(0).Lead_Source_WAR_Call_Type__c);
      } // for

   } // testAccountTasks
   
   static testMethod void testAccountEvents() {
      Account[] accounts = new Account[]{};
      accounts.add(new Account(Name='Test1', Type = 'Prospect', Lead_Source__c='Test Lead'));
      accounts.add(new Account(Name='Test2', Type = 'CORE Client', Lead_Source__c='Test Lead'));
      accounts.add(new Account(Name='Test3', Type = 'Prospect', Lead_Source__c='Test Lead'));
      insert accounts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(accounts);
      ssc.setSelected(accounts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(true,mca.useWhat);
      System.assertEquals('Task',mca.activityType);
      
      // switch to Event
      mca.activityType = 'Event';
      System.assertEquals(null,mca.changeActivity());
      System.assertEquals('Event',mca.activityType);

      DateTime newDateTime = DateTime.now().addDays(5);
      
      // verify the correct number of events
      System.assertEquals(accounts.size(), mca.meetingList.size());
      // set values on first event
      MeetingWrapper firstMeeting = mca.meetingList.get(0);
      firstMeeting.evnt.Type='Test Type';
      firstMeeting.evnt.Subject='Test Subject';
      firstMeeting.evnt.Description='Test Description';
      firstMeeting.evnt.ActivityDate=newDateTime.date();
      firstMeeting.evnt.ActivityDateTime=newDateTime;

      // set the flag to use the values in first task for all tasks
      mca.useFirstActivity = true;
      String retUrl = mca.save().getUrl();

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Account.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] accountIds = new Id[]{};
      for (Account acct : accounts) {
         accountIds.add(acct.Id);
      }
      Account[] accts = [Select Id, Type, (Select Id, Lead_Source_WAR_Call_Type__c, Type, Subject, Description, ActivityDate from Events) from Account where Id in :accountIds];
      // verify correct number returned
      System.assertEquals(accounts.size(), accts.size());
      // verify each Contact has one Task and Lead Source is set
      for (Account acct : accts) {
         System.assertEquals(1,acct.Events.size());
         Event checkEvent = acct.Events.get(0);
         System.assertEquals(acct.Type,checkEvent.Lead_Source_WAR_Call_Type__c);
         System.assertEquals('Test Type',checkEvent.Type);
         System.assertEquals('Test Subject',checkEvent.Subject);
         System.assertEquals('Test Description',checkEvent.Description);
         System.assertEquals(Date.today().addDays(5),checkEvent.ActivityDate);
      } // for

   } // testAccountEvents
   
   static testMethod void testRefContacts() {
      Referral_Contact__c[] contacts = new Referral_Contact__c[]{};
      contacts.add(new Referral_Contact__c(Name='Referral Test1', Referral_Type__c='Test Lead'));
      contacts.add(new Referral_Contact__c(Name='Referral Test2', Referral_Type__c='Test Lead'));
      contacts.add(new Referral_Contact__c(Name='Referral Test3', Referral_Type__c='Test Lead'));
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      insert contacts;
      
      ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(contacts);
      ssc.setSelected(contacts);
      MassCreateActivity mca = new MassCreateActivity(ssc);
      System.assertEquals(true,mca.hasRecords);
      System.assertEquals(true,mca.useWhat);
      String retUrl = mca.save().getUrl();
      System.assertEquals(true,mca.entryFromListView);

      // verify it returns to the page for Contacts
      Schema.DescribeSObjectResult dor = Referral_Contact__c.sObjectType.getDescribe();
      String queuePrefix = dor.getKeyPrefix();
      System.assertEquals(true,(retUrl.endsWith(queuePrefix)));
      
      // verify that Tasks were created.
      Id[] contactIds = new Id[]{};
      for (Referral_Contact__c ctct : contacts) {
         contactIds.add(ctct.Id);
      }
      Referral_Contact__c[] ctcts = [Select Id, (Select Id, Lead_Source_WAR_Call_Type__c from Tasks) from Referral_Contact__c where Id in :contactIds];
      // verify correct number returned
      System.assertEquals(contacts.size(), ctcts.size());
      // verify each Contact has one Task and Lead Source is set
      for (Referral_Contact__c ctct : ctcts) {
         System.assertEquals(1,ctct.Tasks.size());
         System.assertEquals('Test Lead',ctct.Tasks.get(0).Lead_Source_WAR_Call_Type__c);
      } // for
   } // testRefContacts
   
   static testMethod void testRefAccts() {
      Referral_Account__c refAcct = new Referral_Account__c(Name='Cool Ref Account', Street_Address_1__c='123 Main St', City__c='Rochester'
                                                            , State_Province__c='NY', Zip_Postal_Code__c='14614', Referral_Source_Business_Type__c='Accounting Firm'
                                                            , Referral_Type__c='CPA', Phone__c='(585) 555-1234');
      ReferralAccountMethods.SKIP_TRIGGERS=true;
      insert refAcct;
      // create a tast
      MassCreateActivity mca = new MassCreateActivity(refAcct.Id, MassCreateActivity.TYPE_CALL);
      Task tsk = mca.firstTask;
      System.assertEquals(refAcct.Id, tsk.WhatId);

      // create an event
      mca = new MassCreateActivity(refAcct.Id, MassCreateActivity.TYPE_MEETING);
      MeetingWrapper meetWrap = mca.firstMeeting;
      Event evt = meetWrap.evnt;
      System.assertEquals(refAcct.Id, evt.WhatId);

   } // testRefAccts
    
   static testMethod void testOpportunity() {
      Account acct = new Account(Name='Test Acct');
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast');
      insert ctct;
      
      Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', CloseDate=Date.today().addDays(7), StageName='Pending');
      insert opp;
      
      OpportunityContactRole ocr = new OpportunityContactRole(OpportunityId=opp.Id, ContactId=ctct.Id, IsPrimary=true, Role='Decision Maker');
      insert ocr;
      
      System.currentPageReference().getParameters().put('Id', opp.Id);
      MassCreateActivity mca = new MassCreateActivity();
      System.assertEquals(false,mca.entryFromListView);
      System.assertEquals(true,mca.useWho);
      
      mca.activityType = MassCreateActivity.TYPE_INIT_PRES;
      mca.changeActivity();
      
      MeetingWrapper meetWrap = mca.firstMeeting;
      meetWrap.evnt.Description = 'This is a description';
      
      mca.save();
      
      System.assertEquals(1, [Select count() from Event where WhatId=:opp.Id]);
   } // testOpportunity

   static testMethod void testConstructorForReferralContactEvent() {

      Referral_Contact__c refContact = new Referral_Contact__c(Name='Referral Test', Referral_Type__c='Test Lead');
      insert refContact;

      Test.startTest();
      MassCreateActivity mca = new MassCreateActivity(refContact.Id, 'Event');
      Test.stopTest();

   } // testOpportunity

   static testMethod void testConstructorForLeadTask() {

      Lead newLead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Lead Company');
      insert newLead;

      Test.startTest();
      MassCreateActivity mca = new MassCreateActivity(newLead.Id, 'Task');
      Test.stopTest();

   } // testOpportunity

} // class MassCreateActivityTest