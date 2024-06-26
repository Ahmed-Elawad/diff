/** Test methods for the DialSourceActionHelper class
 *
 * History
 * -------
   12/12/2018 Dan Carmen            Created.
   12/18/2018 Dan Carmen            Add some additional change fields
   01/31/2019 Dan Carmen            Add logic to pop a weblead to a user
   04/06/2021 Dan Carmen            Update inbound tests with DS_Denali__Inbound_DNIS__c

*/
@isTest
private class DialSourceActionHelperTest {

   static testMethod void testPhoneNumber() {
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c='5553456789'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name1');
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2');
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      insert actions;
        
      Map<Id,DS_Denali__DialSource_Action__c> actionMap = new Map<Id,DS_Denali__DialSource_Action__c>([
                               Select Id
                                     ,DS_Denali__Call_Campaign__c
                                     ,CallCampaignOld__c
                                     ,DS_Denali__Phone__c
                                     ,InboundCallerId__c
                                     ,InboundCallerIdOld__c
                                     ,DS_Denali__Inbound_DNIS_Name__c
                                     ,InboundDNISNameOld__c
                                 From DS_Denali__DialSource_Action__c
                          ]);
      action1 = actionMap.get(action1.Id);
      System.assertEquals('(555) 345-6789', action1.InboundCallerId__c);
      //System.assertEquals(null,action1.CallCampaignOld__c);
      //System.assertEquals(null,action1.InboundCallerIdOld__c);
      //System.assertEquals(null,action1.InboundDNISNameOld__c);
      
      action2 = actionMap.get(action2.Id);
      System.assertEquals('(555) 123-4570', action2.InboundCallerId__c);
      //System.assertEquals(null,action2.CallCampaignOld__c);
      //System.assertEquals(null,action2.InboundCallerIdOld__c);
      //System.assertEquals(null,action2.InboundDNISNameOld__c);
      
      action1.DS_Denali__Phone__c = '2221234567';
      action1.DS_Denali__Inbound_DNIS_Name__c='DNIS Name1a';
      actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      DialSourceActionHelper.actionIdsProcessedSet.clear();
      update actions;
      
      actionMap = new Map<Id,DS_Denali__DialSource_Action__c>([
                               Select Id
                                     ,DS_Denali__Call_Campaign__c
                                     ,CallCampaignOld__c
                                     ,DS_Denali__Phone__c
                                     ,InboundCallerId__c
                                     ,InboundCallerIdOld__c
                                     ,DS_Denali__Inbound_DNIS_Name__c
                                     ,InboundDNISNameOld__c
                                 From DS_Denali__DialSource_Action__c
                          ]);
      action1 = actionMap.get(action1.Id);
      System.assertEquals('(222) 123-4567', action1.InboundCallerId__c);
      System.assertEquals('Call Campaign1',action1.CallCampaignOld__c);
      System.assertEquals('(555) 345-6789',action1.InboundCallerIdOld__c);
      System.assertEquals('DNIS Name1',action1.InboundDNISNameOld__c);
      
      action2 = actionMap.get(action2.Id);
      System.assertEquals('(555) 123-4570', action2.InboundCallerId__c);
      System.assertEquals('Call Campaign2',action2.CallCampaignOld__c);
      System.assertEquals('(555) 123-4570',action2.InboundCallerIdOld__c);
      System.assertEquals('DNIS Name2',action2.InboundDNISNameOld__c);
      

      action1.DS_Denali__Phone__c = '2221234568';
      action1.DS_Denali__Inbound_DNIS_Name__c='DNIS Name1a';
      action1.DS_Denali__Call_Campaign__c='Call Campaign1a';
      actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      DialSourceActionHelper.actionIdsProcessedSet.clear();
      update actions;
      
      actionMap = new Map<Id,DS_Denali__DialSource_Action__c>([
                               Select Id
                                     ,DS_Denali__Call_Campaign__c
                                     ,CallCampaignOld__c
                                     ,DS_Denali__Phone__c
                                     ,InboundCallerId__c
                                     ,InboundCallerIdOld__c
                                     ,DS_Denali__Inbound_DNIS_Name__c
                                     ,InboundDNISNameOld__c
                                 From DS_Denali__DialSource_Action__c
                          ]);
      action1 = actionMap.get(action1.Id);
      System.assertEquals('(222) 123-4568', action1.InboundCallerId__c);
      System.assertEquals('Call Campaign1',action1.CallCampaignOld__c);
      System.assertEquals('(222) 123-4567',action1.InboundCallerIdOld__c);
      System.assertEquals('DNIS Name1a',action1.InboundDNISNameOld__c);

      action2 = actionMap.get(action2.Id);
      System.assertEquals('(555) 123-4570', action2.InboundCallerId__c);
      System.assertEquals('Call Campaign2',action2.CallCampaignOld__c);
      System.assertEquals('(555) 123-4570',action2.InboundCallerIdOld__c);
      System.assertEquals('DNIS Name2',action2.InboundDNISNameOld__c);
      

   } // testPhoneNumber
   
   static testMethod void testPopToUser() {
      Lead ld = new Lead(LastName='TestLast', Company='Test Company', Phone='(585) 555-1234');
      insert ld;
      
      DialSourceActionHelper.POP_UP_ACTIVE = true;
      
      // test do nothing
      DialSourceActionHelper.addPopToUser(null, null, null, null);
      DialSourceActionHelper.addPopToUser(ld.Id, ld.LastName, ld.Phone, UserInfo.getUserId());
      System.assertEquals(1,DialSourceActionHelper.dsVarsToSend.size());
      DialSourceActionHelper.checkPopToUser();
   } // testPopToUser
   
   static testMethod void testTaskUpdate() {
      DialSourceActionHelper.UPDATE_TASK = true;
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      Schema.RecordTypeInfo rtOutbound = CallCenterHelper.getOutboundRt();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtOutbound.getRecordTypeId()
                                                       ,DS_Denali__Subject__c='action1'
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c='5553456789'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name1'
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId());
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Subject__c='action2'
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign2'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2'
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId());
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      insert actions;
      
      //Task tsk = new Task(Subject='Test',CallObject=TaskHelper.CT_OUTBOUND, CallType=TaskHelper.CT_OUTBOUND, DS_Denali__DialSource_Action__c=action1.Id);
      //TaskHelper.SKIP_TRIGGERS=true;
      //insert tsk;
      
      Task tsk = [Select Id, CallObject, CallType, CallDisposition from Task where DS_Denali__DialSource_Action__c=:action1.Id];
      System.assertEquals(TaskHelper.CT_OUTBOUND, tsk.CallObject);
      System.assertEquals(TaskHelper.CT_OUTBOUND, tsk.CallType);
      System.assertEquals(null, tsk.CallDisposition);
      
      action1.RecordTypeId = rtInbound.getRecordTypeId();
      action1.DS_Denali__Inbound_DNIS__c='InboundCall';
      action1.DS_Denali__Call_Disposition__c = 'Contacted';
      action2.DS_Denali__Call_Disposition__c = 'Contacted';
      
      DialSourceActionHelper.actionIdsProcessedSet.clear();
      Test.startTest();
      update actions;
      Test.stopTest();
      
      tsk = [Select Id, CallObject, CallType, CallDisposition from Task where DS_Denali__DialSource_Action__c=:action1.Id];
      System.assertEquals(TaskHelper.CT_INBOUND, tsk.CallObject);
      System.assertEquals(TaskHelper.CT_INBOUND, tsk.CallType);
      System.assertEquals('Contacted', tsk.CallDisposition);
      
      Task tsk2 = [Select Id, CallObject, CallType, CallDisposition from Task where DS_Denali__DialSource_Action__c=:action2.Id];
      System.assertEquals(TaskHelper.CT_INBOUND, tsk2.CallObject);
      System.assertEquals(TaskHelper.CT_INBOUND, tsk2.CallType);
      System.assertEquals('Contacted', tsk2.CallDisposition);
      
   } // testTaskUpdate
   
   static testMethod void testCheckWhoWhat() {
      Task tsk = new Task(Subject='tsk', ActivityDate=Date.today(), Status='Not Started');
      insert tsk;
      
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Test Contact');
      insert refCtct;
      
      Lead ld1 = new Lead(LastName='Ld1', Company='Test Lead Company1');
      insert ld1;
      
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestContact');
      insert ctct;
      
      Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opportunity', StageName='Pending', CloseDate=Date.today().addDays(7));
      insert opp;
      
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(
                                                   DS_Denali__Custom_Object_ID__c = tsk.Id
                                                  ,DS_Denali__Owner__c=UserInfo.getUserId()
                                                  ,DS_Denali__Opportunity__c = opp.Id
                                                  ,DS_Denali__Account__c = acct.Id
                                                  ,DS_Denali__Case__c = null
                                                  ,DS_Denali__Contact__c = ctct.Id
                                                  ,DS_Denali__Lead__c = null);
                                                       
      DialSourceActionHelper.EXCLUDE_PREFIXES = new Set<String>{'00T'};
      Task testTask = new Task();
      DialSourceActionHelper.checkWhoWhat(tsk,action1);
      System.assertEquals(opp.Id, tsk.WhatId);
      System.assertEquals(ctct.Id, tsk.WhoId);
      
      action1.DS_Denali__Custom_Object_ID__c = refCtct.Id;
      action1.DS_Denali__Contact__c = null;
      action1.DS_Denali__Lead__c = ld1.Id;
      action1.DS_Denali__Account__c = null;
      
      testTask = new Task();
      DialSourceActionHelper.checkWhoWhat(tsk,action1);
      System.assertEquals(refCtct.Id, tsk.WhatId);
      System.assertEquals(ld1.Id, tsk.WhoId);
      
      action1.DS_Denali__Custom_Object_ID__c = null;
      action1.DS_Denali__Opportunity__c = null;
      action1.DS_Denali__Contact__c = ctct.Id;
      action1.DS_Denali__Lead__c = ld1.Id;
      action1.DS_Denali__Account__c = acct.Id;
      
      testTask = new Task();
      DialSourceActionHelper.checkWhoWhat(tsk,action1);
      System.assertEquals(acct.Id, tsk.WhatId);
      System.assertEquals(ctct.Id, tsk.WhoId);
   } // testCheckWhoWhat

   static testMethod void testCampaign() {
      DialSourceActionHelper.UPDATE_TASK = true;
      Campaign camp = new Campaign(Name='Test Oasis', ACD_Name__c='OasisTest', Destination__c='Oasis', IsActive=true);
      insert camp;
      camp = [Select Id, Name, ACD_Name__c, Destination__c, DestinationTaskRecordType__c from Campaign where Id=:camp.Id];
      System.assertNotEquals(null,camp.DestinationTaskRecordType__c);
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      DS_Denali__DialSource_Action__c action1 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Call_Campaign__c='Call Campaign1'
                                                       ,DS_Denali__Phone__c='5553456789'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Inbound_DNIS_Name__c=camp.ACD_Name__c
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId());
      DS_Denali__DialSource_Action__c action2 = new DS_Denali__DialSource_Action__c(RecordTypeId=rtInbound.getRecordTypeId()
                                                       ,DS_Denali__Inbound_DNIS__c='InboundCall'
                                                       ,DS_Denali__Phone__c='5551234570'
                                                       ,DS_Denali__DialSource_Session__c=dsSession.Id
                                                       ,DS_Denali__Call_Campaign__c=camp.Name
                                                       ,DS_Denali__Owner__c=UserInfo.getUserId());
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      Test.startTest();
      insert actions;
      update actions;
      Test.stopTest();
      
      Task tsk1 = [Select Id, RecordType.Id, RecordType.Name from Task where DS_Denali__DialSource_Action__c = :action1.Id];
      System.assertEquals(camp.DestinationTaskRecordType__c, tsk1.RecordType.Name);

      Task tsk2 = [Select Id, RecordType.Id, RecordType.Name from Task where DS_Denali__DialSource_Action__c = :action2.Id];
      System.assertEquals(camp.DestinationTaskRecordType__c, tsk2.RecordType.Name);
   } // testCampaign
   
} // class DialSourceActionHelperTest