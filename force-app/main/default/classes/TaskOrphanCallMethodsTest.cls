/** Test Methods for TaskOrphanCallMethods
 *
 * History
 * -------
   03/31/2017 Dan Carmen        Created.
   12/10/2018 Dan Carmen        Set to work with DialSource
   03/26/2021 Brandon Vidro     Added test for Drift orphans
   04/17/2021 Dan Carmen        Added call to queryActivityEmailMap

*/
@isTest
private class TaskOrphanCallMethodsTest {

   @testSetup
   public static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'TaskAfter', false, true, new String[]{'TaskHelper'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;
   } // setupData

   static testMethod void testLinkTask() {
      TaskOrphanCallMethods.SEARCH_TASKS=true;
      // setup matching objects
      Account acct = new Account(Name='Account 1', Phone='5551234567');
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName', Phone='5552345678');
      insert ctct;
      Lead ld = new Lead(Company='Test Company', LastName='TestLast', Phone='5553456789');
      insert ld;
      
      Id [] fixedSoslResults = new Id[]{acct.Id, ctct.Id, ld.Id};
      Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query

      SObject[] leadList = new SObject[]{ld};
      SObject[] ctctList = new SObject[]{ctct};
      SObject[] acctList = new SObject[]{acct};
      TaskOrphanCallMethods.TEST_QUERY_RESULTS = new List<List<SObject>>(); //{leadList,ctctList,acctList};
      TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(leadList);
      TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(ctctList);
      TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(acctList);
      
      Id nssTaskRtId = TaskHelper.getNSSTaskRecordTypeId();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;

      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5551234567', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Inbound_DNIS__c='InboundCall');
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5552345678', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Inbound_DNIS__c='InboundCall');
      DS_Denali__DialSource_Action__c action3 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5553456789', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Inbound_DNIS__c='InboundCall');
      DS_Denali__DialSource_Action__c action4 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId(), DS_Denali__Phone__c='5551234570', DS_Denali__DialSource_Session__c=dsSession.Id, DS_Denali__Inbound_DNIS__c='InboundCall');
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2,action3,action4};
      insert actions;

      Task tsk1 = new Task(RecordTypeId=nssTaskRtId, Subject='Task1', CallDateTime__c = system.now(), CallType='Inbound', DS_Denali__DialSource_Action__c=action1.Id);
      Task tsk2 = new Task(RecordTypeId=nssTaskRtId, Subject='Task2', CallDateTime__c = system.now(), CallType='Inbound', DS_Denali__DialSource_Action__c=action2.Id);
      Task tsk3 = new Task(RecordTypeId=nssTaskRtId, Subject='Task3', CallDateTime__c = system.now(), CallType='Inbound', DS_Denali__DialSource_Action__c=action3.Id);
      Task tsk4 = new Task(RecordTypeId=nssTaskRtId, Subject='Task4', CallDateTime__c = system.now(), CallType='Inbound', DS_Denali__DialSource_Action__c=action4.Id);
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4};
      Test.startTest();
      insert tsks;
      Test.stopTest();
      Integer nbrOrphanRecs = [select count() from TaskOrphanCall__c];
      System.assertEquals(4, nbrOrphanRecs);
      
      tsk1 = [select Id, WhoId, WhatId, AccountId from Task where Id=:tsk1.Id];
      System.assertEquals(acct.Id, tsk1.AccountId);
      System.assertEquals(acct.Id, tsk1.WhatId);
      
      tsk2 = [select Id, WhoId, WhatId, AccountId from Task where Id=:tsk2.Id];
      System.assertEquals(ctct.Id, tsk2.WhoId);
      System.assertEquals(acct.Id, tsk2.AccountId);
      System.assertEquals(acct.Id, tsk2.WhatId);
      
      tsk3 = [select Id, WhoId, WhatId, AccountId from Task where Id=:tsk3.Id];
      System.assertEquals(ld.Id, tsk3.WhoId);

   } // testLinkTask
    
    static testMethod void testCreateOrphanDrift() {
        TaskOrphanCallMethods.SEARCH_TASKS=true;
        TaskOrphanCallMethods.PROCESS_DRIFT_TASKS=true;
        
        // find a queue for testing
        Group[] queryGrpsDrift = [Select Id, Type, OwnerId, Name, Email from Group 
                                  where Type = 'Queue'
                                  and Name = 'Drift Chat' limit 1];
        System.assertEquals(true, queryGrpsDrift.size() > 0);
        
        Campaign camp1 = new Campaign(Name='Drift Campaign', LeadSource__c='Campaign Drift LeadSource',IsActive=true);
        insert camp1;
                
        Lead ld = new Lead(Company='Test Company', LastName='TestLast', Email='bvidro@paychex.com', OwnerId = queryGrpsDrift[0].Id, CreatedDate = Date.today()-1, LatestCampaign__c=camp1.Id, Bank_Product_Of_Interest__c = null,MktgId__c='bvidro1');
        insert ld;
        //Lead ld2 = new Lead(Company='Test Company 2', LastName='TestLast 2', Email='bvidro@paychex.com', OwnerId = queryGrpsDrift[0].Id, CreatedDate = Date.today(), LatestCampaign__c=camp1.Id, Bank_Product_Of_Interest__c = null,MktgId__c='bvidro1');
        //insert ld2;
        //Account acct = new Account(Name='Account 1', Phone='5551234567');
        //insert acct;
        //Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName', Phone='5552345678', CreatedDate = Date.today(), Email='bvidro@paychex.com');
        //insert ctct;
        
        //Id [] fixedSoslResults = new Id[]{ld.Id,ld2.Id,ctct.Id};
        Id [] fixedSoslResults = new Id[]{ld.Id};
            Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
        
        //SObject[] leadList = new SObject[]{ld,ld2};
        //SObject[] ctctList = new SObject[]{ctct};
        
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS = new List<List<SObject>>(); //{leadList};
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(leadList);
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(ctctList);
        
        Task tsk1 = new Task(Subject=Label.Drift_Task_Subject, CallDateTime__c = system.now(), Type=Label.TrackRecord_Chat, WhoId = ld.Id);
        
        Test.startTest();
        insert tsk1;
        Test.stopTest();
        
        Integer nbrOrphanRecs = [select count() from TaskOrphanCall__c where TaskId__c =:tsk1.Id];
        System.assertEquals(1, nbrOrphanRecs);
        Task tsk = [Select Id, OwnerId from Task where Id=:tsk1.Id];
        ld = [Select Id, Email, OwnerId from Lead where Id = :ld.Id];
        //ld2 = [Select Id, Email, OwnerId from Lead where Id = :ld2.Id];
        //Contact ctct2 = [Select Id, OwnerId from Contact where Id =:ctct.Id];
        //Lead owner should get reassigned to Task owner
        System.assertEquals(tsk.OwnerId,ld.OwnerId);
        TaskOrphanCall__c orphan = [Select Id, Name, Email__c, MatchId__c, TaskId__c from TaskOrphanCall__c where TaskId__c =:tsk1.Id];
        System.assertNotEquals(null,orphan.Id);
        
    } // testCreateOrphanDrift
    
   static testMethod void testCreateOrphanDriftEvent() {
        TaskOrphanCallMethods.PROCESS_DRIFT_TASKS=true;
        TaskOrphanCallMethods.SEARCH_TASKS=true;
        
        // find a queue for testing
        Group[] queryGrpsDrift = [Select Id, Type, OwnerId, Name, Email from Group 
                                  where Type = 'Queue'
                                  and Name = 'Drift Chat' limit 1];
        System.assertEquals(true, queryGrpsDrift.size() > 0);
        
        Campaign camp1 = new Campaign(Name='Drift Campaign', LeadSource__c='Campaign Drift LeadSource',IsActive=true);
        insert camp1;
                
        Lead ld = new Lead(Company='Test Company', LastName='TestLast', Email='bvidro@paychex.com', OwnerId = queryGrpsDrift[0].Id, CreatedDate = Date.today()-1, LatestCampaign__c=camp1.Id, Bank_Product_Of_Interest__c = null,MktgId__c='bvidro1');
        insert ld;
        Lead ld2 = new Lead(Company='Test Company 2', LastName='TestLast 2', Email='bvidro@paychex.com', OwnerId = queryGrpsDrift[0].Id, CreatedDate = Date.today(), LatestCampaign__c=camp1.Id, Bank_Product_Of_Interest__c = null,MktgId__c='bvidro2');
        insert ld2;
        //Account acct = new Account(Name='Account 1', Phone='5551234567');
        //insert acct;
        //Contact ctct = new Contact(AccountId=acct.Id, LastName='LastName', Phone='5552345678', CreatedDate = Date.today());
        //insert ctct;
        
        //Id [] fixedSoslResults = new Id[]{ld.Id,ld2.Id,ctct.Id};
        Id [] fixedSoslResults = new Id[]{ld.Id,ld2.Id};
            Test.setFixedSearchResults(fixedSoslResults);       // force results of SOSL query
        
        //SObject[] leadList = new SObject[]{ld,ld2};
        //SObject[] ctctList = new SObject[]{ctct};
        
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS = new List<List<SObject>>(); //{leadList};
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(leadList);
        //TaskOrphanCallMethods.TEST_QUERY_RESULTS.add(ctctList);
        
        Event event1 = new Event(Subject='Meeting Booked with Drift', Type=Label.TrackRecord_Chat, WhoId = ld.Id, ActivityDate=Date.today(), ActivityDateTime=DateTime.now(), DurationInMinutes=60);
        
        Test.startTest();
        insert event1;
        Test.stopTest();
        
        Integer nbrOrphanRecs = [select count() from TaskOrphanCall__c where EventId__c =:event1.Id];
        System.assertEquals(1, nbrOrphanRecs);
        Event evt = [Select Id, OwnerId from Event where Id=:event1.Id];
        ld = [Select Id, Email, OwnerId from Lead where Id = :ld.Id];
        //ld2 = [Select Id, Email, OwnerId from Lead where Id = :ld2.Id];
        //Lead owner should get reassigned to Task owner
        System.assertEquals(queryGrpsDrift[0].Id,ld.OwnerId);
        TaskOrphanCall__c orphan = [Select Id, Name, Email__c, MatchId__c, TaskId__c, EventId__c from TaskOrphanCall__c where EventId__c =:event1.Id];
        System.assertNotEquals(null,orphan.Id);
        
    } // testCreateOrphanDriftEvent
   
} // class TaskOrphanCallMethodsTest