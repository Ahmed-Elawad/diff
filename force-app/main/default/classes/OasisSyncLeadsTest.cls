/* Test Methods for the OasisSyncLeads class


  History
  -------
  05/19/2019 Dan Carmen        Created
  08/09/2019 Dan Carmen        Changes to move workable code to DuplicateCheckQueueable
  03/10/2020 Dan Carmen        Comment out all code
  
 */
@isTest
private class OasisSyncLeadsTest {

    static testMethod void testNothing() {
        OasisSyncLeads.processLeads((Lead[])null, (Map<Id,Lead>)null, (String)null, (ErrorLog__c)null);
        OasisSyncLeads.handleConvertedLeads((Set<Id>) null,(Map<String,OasisSync__c>)null, (OasisSync__c[])null, (OasisSync__c[])null, (ErrorLog__c)null);
        OasisSyncQueueable osq = new OasisSyncQueueable();
    } // testNothing

   /* Removed code
   @testSetup
   public static void setupTestData() {
      OasisSyncHelperTest.setupCustomSettings();
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = 'OasisSyncQueueable', Active__c = true, BatchSize__c=1, LogProcess__c=true);
      insert abc; 
   } // setupTestData
    
   static testMethod void testLeadCreation() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      // get a client space user
      User csUser = OasisSyncHelperTest.getTestCSUser();
      Lead ld = new Lead(FirstName='Jimmy', LastName='Test', Company='Jimmy Jimmies', Email='jimmy@test.com', PostalCode='12345', OwnerId=csUser.Id);
      insert ld;
      
      // an OasisSync__c record should have been created
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Lead[]{ld});
      System.assertEquals(1,syncMap.size());
      OasisSync__c sync = syncMap.get(ld.Id);
      System.assertEquals(OasisSyncHelper.SOURCE_PAYX, sync.Source__c);
      System.assertEquals(OasisSyncHelper.SYNC_NEW, sync.SyncType__c);
      System.assertEquals(1,sync.NbrTransits__c);
      System.assertEquals(ld.Id, sync.LeadIdPayx__c);
      System.assertEquals(ld.FirstName, sync.FirstName__c);
      System.assertEquals(ld.LastName, sync.LastName__c);
      System.assertEquals(ld.Company, sync.Company__c);
      System.assertEquals(ld.Email, sync.Email__c);
      System.assertEquals(ld.PostalCode, sync.PostalCode__c);
      System.assertEquals(csUser.HR_Person_Id__c, sync.OwnerHrPersonId__c);
      
      OasisSyncHelperTest.resetTriggerFlags();
      ld.City='Whoville';
      ld.State='CA';
      ld.PostalCode='90210';
      TriggerMethods.clearVariables();
      update ld;
      
      syncMap = OasisSyncHelper.getExistingSyncMap(new Lead[]{ld});
      System.assertEquals(1,syncMap.size());
      sync = syncMap.get(ld.Id);
      
      System.assertEquals(OasisSyncHelper.SYNC_UPDATE, sync.SyncType__c);
      System.assertEquals(2,sync.NbrTransits__c);
      System.assertEquals(ld.Id, sync.LeadIdPayx__c);
      System.assertEquals(ld.FirstName, sync.FirstName__c);
      System.assertEquals(ld.LastName, sync.LastName__c);
      System.assertEquals(ld.Company, sync.Company__c);
      System.assertEquals(ld.Email, sync.Email__c);
      System.assertEquals(ld.City, sync.City__c);
      System.assertEquals(ld.State, sync.State__c);
      System.assertEquals(ld.PostalCode, sync.PostalCode__c);
      System.assertEquals(csUser.HR_Person_Id__c, sync.OwnerHrPersonId__c);
      OasisSyncHelperTest.resetTriggerFlags();
      
      System.debug('testLeadCreation before Lead convert');
      Test.startTest();
      Id convertedCtctId = DuplicateCheckQueueable.convertLead(ld, null, null,false); 
      Test.stopTest();
      System.debug('testLeadCreation after Lead convert');
      
      Contact ctct = [Select Id, FirstName, LastName, Email
                            ,Account.Id
                            ,Account.Name
                            ,Account.BillingPostalCode
                            ,Account.BillingCity
                            ,Account.BillingState
                        From Contact
                       Where Id = :convertedCtctId];
                       
      Set<String> syncIdSet = new Set<String>();
      syncIdSet.add(ld.Id);
      syncIdSet.add(ctct.Id);
      
      syncMap = OasisSyncHelper.getExistingSyncMap(syncIdSet);
      System.assertEquals(1,syncMap.size());
      sync = syncMap.get(ld.Id);
      System.debug('testLeadCreation syncMap='+syncMap);
      // this one should no longer be selectable.
      System.assertEquals(null,sync);
      
      sync = [Select Id, SyncType__c, LeadIdPayx__c, ContactIdPayx__c, AccountIdPayx__c, NbrTransits__c from OasisSync__c where LeadIdPayx__c=:ld.Id];
      System.assertEquals(OasisSyncHelper.SYNC_LEAD_CONVERTED, sync.SyncType__c);
      System.assertEquals(3,sync.NbrTransits__c);
      System.assertEquals(ld.Id, sync.LeadIdPayx__c);
      System.assertEquals(ctct.Id, sync.ContactIdPayx__c);
      System.assertEquals(ctct.Account.Id, sync.AccountIdPayx__c);
      
      OasisSync__c sync2 = syncMap.get(ctct.Id);
      System.assertEquals(OasisSyncHelper.SOURCE_PAYX, sync2.Source__c);
      System.assertEquals(OasisSyncHelper.SYNC_NEW, sync2.SyncType__c);
      System.assertEquals(1,sync2.NbrTransits__c);
      System.assertEquals(null, sync2.LeadIdPayx__c);
      System.assertEquals(ld.FirstName, sync2.FirstName__c);
      System.assertEquals(ld.LastName, sync2.LastName__c);
      System.assertEquals(ld.Company, sync2.Company__c);
      System.assertEquals(ld.Email, sync2.Email__c);
      System.assertEquals(ld.PostalCode, sync2.PostalCode__c);
      System.assertEquals(ctct.Id, sync2.ContactIdPayx__c);
      System.assertEquals(ctct.Account.Id, sync2.AccountIdPayx__c);
      
      
   } // testLeadCreation
   */
   /* Code has been moved to DuplicateCheckQueueable
   static testMethod void testLeadDupeMatch() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      // create check data
      OasisSyncHelperTest.skipAllTriggers();
      
      Lead ld1 = new Lead(FirstName='David', LastName='Tennant', Title='The Doctor', Company='TARDIS10 Inc', Email='thedoctor10@who.com', PostalCode='12345', DuplicateCheckStatus__c='Lead Match');
      Lead ld2 = new Lead(FirstName='Matt', LastName='Smith', Title='The Doctor', Company='TARDIS11 Inc', Email='thedoctor11@who.com', PostalCode='12346', DuplicateCheckStatus__c='Lead Match');
      Lead ld3 = new Lead(FirstName='Peter', LastName='Capaldi', Title='The Doctor', Company='TARDIS12 Inc', Email='thedoctor12@who.com', PostalCode='12347', DuplicateCheckStatus__c='Lead Match');
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;
      
      // make sync records for the leads
      OasisSync__c sync1 = new OasisSync__c(Name='David Tennant', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld1.Id);
      OasisSync__c sync2 = new OasisSync__c(Name='Matt Smith', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld2.Id);
      OasisSync__c sync3 = new OasisSync__c(Name='Peter Capaldi', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld3.Id);
      OasisSync__c[] syncs = new OasisSync__c[]{sync1,sync2,sync3};
      insert syncs;
      
      // makes ld1 not workable
      Task tsk1 = new Task(WhoId=ld1.Id, Subject='Task 1', ActivityDate=Date.today(), Status='Not Started');
      insert tsk1;
      
      // makes ld2 not workable
      Event evnt2 = new Event(WhoId=ld2.Id, Subject='Event 2', ActivityDate=Date.today().addDays(1), ActivityDateTime=Datetime.now().addDays(1), DurationInMinutes=60);
      insert evnt2;
      
      // no activity for ld3 should be workable
      
      Id[] leadIds = new Id[]{ld1.Id,ld2.Id,ld3.Id};
      lds = OasisSyncQueueable.queryLeads(leadIds);

      OasisSyncHelperTest.setConnectionUserAsRunningUser();
      Test.startTest();
      OasisSyncLeads.processLeads(lds, (Map<Id,Lead>)null, OasisSyncHelper.SYNC_DUPE_RESULT, (ErrorLog__c)null);
      Test.stopTest();
      
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(lds);
      OasisSync__c checkSync1 = syncMap.get(ld1.Id);
      System.assertEquals('Lead Match-Not Workable', checkSync1.DuplicateCheckResult__c);
      System.assertEquals('Open Tasks found', checkSync1.DuplicateNotWorkableReason__c);

      OasisSync__c checkSync2 = syncMap.get(ld2.Id);
      System.assertEquals('Lead Match-Not Workable', checkSync2.DuplicateCheckResult__c);
      System.assertEquals('Open Events found', checkSync2.DuplicateNotWorkableReason__c);

      OasisSync__c checkSync3 = syncMap.get(ld3.Id);
      System.assertEquals('Lead Match-Workable', checkSync3.DuplicateCheckResult__c);
      System.assertEquals(null, checkSync3.DuplicateNotWorkableReason__c);
      
   } // testLeadDupeMatch

   static testMethod void testAcctCtctDupeMatch() {      
      OasisSyncHelper.SKIP_NAME_SET.clear();
      OasisSyncHelperTest.skipAllTriggers();
      
      Lead ld10 = new Lead(FirstName='David', LastName='Tennant', Title='The Doctor', Company='TARDIS10 Inc', Email='thedoctor10@who.com', PostalCode='12345', DuplicateCheckStatus__c='Account Match');
      Lead ld11 = new Lead(FirstName='Matt', LastName='Smith', Title='The Doctor', Company='TARDIS11 Inc', Email='thedoctor11@who.com', PostalCode='12346', DuplicateCheckStatus__c='Account Match');
      Lead ld12 = new Lead(FirstName='Peter', LastName='Capaldi', Title='The Doctor', Company='TARDIS12 Inc', Email='thedoctor12@who.com', PostalCode='12347', DuplicateCheckStatus__c='Contact Match');
      Lead ld13 = new Lead(FirstName='Jodie', LastName='Whittaker', Title='The Doctor', Company='TARDIS13 Inc', Email='thedoctor13@who.com', PostalCode='12348', DuplicateCheckStatus__c='Contact Match');
      Lead[] lds = new Lead[]{ld10,ld11,ld12,ld13};
      insert lds;
      
      // make sync records for the leads
      OasisSync__c sync10 = new OasisSync__c(Name='David Tennant', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld10.Id);
      OasisSync__c sync11 = new OasisSync__c(Name='Matt Smith', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld11.Id);
      OasisSync__c sync12 = new OasisSync__c(Name='Peter Capaldi', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld12.Id);
      OasisSync__c sync13 = new OasisSync__c(Name='Jodie Whittaker', SyncType__c=OasisSyncHelper.SYNC_NEW, LeadIdPayx__c=ld13.Id);
      OasisSync__c[] syncs = new OasisSync__c[]{sync10,sync11,sync12,sync13};
      insert syncs;

      // convert the leads (to get the accounts and contacts)
      System.assertEquals(true, convertLead(ld10));
      System.assertEquals(true, convertLead(ld11));
      System.assertEquals(true, convertLead(ld12));
      System.assertEquals(true, convertLead(ld13));
      
      Id[] leadIds = new Id[]{ld10.Id,ld11.Id,ld12.Id,ld13.Id};

      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id
                                     ,FirstName, LastName, Company
                                     ,ConvertedAccountId
                                     ,ConvertedContactId
                                     ,ConvertedDate
                                     ,DuplicateCheckStatus__c
                                     ,IsConverted
                                     ,OasisId__c
                                 From Lead
                                Where Id in :leadIds
                                  and IsConverted=true]);
      
      System.assertEquals(lds.size(), leadMap.size());
      
      // set the first as a current client
      Lead checkLd10 = leadMap.get(ld10.Id);
      Lead checkLd11 = leadMap.get(ld11.Id);
      Lead checkLd12 = leadMap.get(ld12.Id);
      Lead checkLd13 = leadMap.get(ld13.Id);
      
      System.debug('testAcctCtctDupeMatch checkLd10='+checkLd10);
      System.debug('testAcctCtctDupeMatch checkLd11='+checkLd11);
      System.debug('testAcctCtctDupeMatch checkLd12='+checkLd12);
      System.debug('testAcctCtctDupeMatch checkLd13='+checkLd13);

      // update to show as a current client
      Account acct10 = new Account(Id=checkLd10.ConvertedAccountId, Bis_ID__c=10, First_Run_Date__c=Date.today(), Type='Current Client');
      update acct10;
      acct10 = [Select Id, Name, CurrentClient__c from Account where Id=:acct10.Id];
      System.assertEquals(true,acct10.CurrentClient__c);
      
      Opportunity opp11 = new Opportunity(Name='Opp11', AccountId=checkLd11.ConvertedAccountId, StageName='Pending', CloseDate=Date.today());
      Opportunity opp12 = new Opportunity(Name='Opp12', AccountId=checkLd12.ConvertedAccountId, StageName='Pending', CloseDate=Date.today());
      // this one will be closed and shouldn't come up as a problem
      Opportunity opp13 = new Opportunity(Name='Opp13', AccountId=checkLd13.ConvertedAccountId, StageName='Not Sold', CloseDate=Date.today());
      Opportunity[] opps = new Opportunity[]{opp11,opp12,opp13};
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      insert opps;
      
      // makes ld11 not workable
      Task tsk11 = new Task(WhoId=checkLd11.ConvertedContactId, WhatId=checkLd11.ConvertedAccountId, Subject='Task 11', ActivityDate=Date.today(), Status='Not Started');
      insert tsk11;
      
      // makes ld12 not workable
      Event evnt12 = new Event(WhoId=checkLd12.ConvertedContactId, WhatId=checkLd12.ConvertedAccountId, Subject='Event 12', ActivityDate=Date.today().addDays(1), ActivityDateTime=Datetime.now().addDays(1), DurationInMinutes=60);
      insert evnt12;
      
      lds = OasisSyncQueueable.queryLeads(leadIds);

      OasisSyncHelperTest.setConnectionUserAsRunningUser();
      Test.startTest();
      OasisSyncLeads.processLeads(lds, (Map<Id,Lead>)null, OasisSyncHelper.SYNC_DUPE_RESULT, (ErrorLog__c)null);
      Test.stopTest();
      
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(lds);
      OasisSync__c checkSync10 = syncMap.get(ld10.Id);
      System.assertEquals('Account Match-Not Workable', checkSync10.DuplicateCheckResult__c);
      System.assertEquals('Current Paychex Client', checkSync10.DuplicateNotWorkableReason__c);

      OasisSync__c checkSync11 = syncMap.get(ld11.Id);
      System.assertEquals('Account Match-Not Workable', checkSync11.DuplicateCheckResult__c);
      System.assertEquals('Has Open Opportunities and Activity', checkSync11.DuplicateNotWorkableReason__c);

      OasisSync__c checkSync12 = syncMap.get(ld12.Id);
      System.assertEquals('Contact Match-Not Workable', checkSync12.DuplicateCheckResult__c);
      System.assertEquals('Has Open Opportunities and Activity', checkSync12.DuplicateNotWorkableReason__c);

      OasisSync__c checkSync13 = syncMap.get(ld13.Id);
      System.assertEquals('Contact Match-Workable', checkSync13.DuplicateCheckResult__c);
      System.assertEquals(null, checkSync13.DuplicateNotWorkableReason__c);

   } // testAcctCtctDupeMatch

   public static LeadStatus convertStatus = null; 
   
   public static Boolean convertLead(Lead ld) {
      if (convertStatus == null) {
         convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
      }
      Database.LeadConvert lc = new Database.LeadConvert();
      lc.setLeadId(ld.Id);
      lc.setDoNotCreateOpportunity(true);
      lc.setOverwriteLeadSource(false);
      lc.setConvertedStatus(convertStatus.MasterLabel);
      Database.Leadconvertresult lcr = null;
      try {
         lcr = Database.convertLead(lc);
      } catch (Exception e) {
         // return to the main lead page.
         System.debug('convertLead exception: '+e.getMessage()+'; '+e.getStackTraceString());
      } // try
      
      return (lcr != null && lcr.isSuccess());
   } // convertLead
   */
   /*
   static testMethod void testQueueable() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      // just need to execute the code at this point.
      OasisSyncHelperTest.skipAllTriggers();
      
      Lead ld10 = new Lead(FirstName='David', LastName='Tennant', Title='The Doctor', Company='TARDIS10 Inc', Email='thedoctor10@who.com', PostalCode='12345', DuplicateCheckStatus__c='Lead Match');
      insert ld10;
      
      OasisSyncQueueable osq = new OasisSyncQueueable();
      osq.addIdToProcess(ld10.Id, OasisSyncHelper.SYNC_DUPE_RESULT);
      Test.startTest();
      OasisSyncQueueable.launchQueueable(osq);
      Test.stopTest();
   } // testQueueable
   */
} // class OasisSyncLeadsTest