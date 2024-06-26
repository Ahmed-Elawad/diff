/* 
  Methods for retrieving Activity
  
  History
  -------
  08/21/2019 Dan Carmen        Created
  04/17/2020 Dan Carmen        Add field for phone and if there's a recording from the DialSource Action object.
  04/27/2021 Dan Carmen        Updated tests to pass for new DialSource package.

*/
@isTest
private class ActivityHelperTest {

   static testMethod void testAccountActivity() {
      Account acct = new Account(Name='Account1');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      
      DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c(Name='Test Session',DS_Denali__Session_Date__c=Datetime.now());
      insert dsSession;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='LastTest', Email='test@test.com');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctct;
      ctct= [Select Id, Name from Contact where Id=:ctct.Id];

      User runningUser = UserHelper.getRunningUser();
       
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
                                                       ,DS_Denali__Inbound_DNIS_Name__c='DNIS Name2'
                                                       ,DS_Denali__Recording_ID__c='thisisnotreallyanid');
      DS_Denali__DialSource_Action__c[] actions = new DS_Denali__DialSource_Action__c[]{action1,action2};
      DialSourceActionHelper.UPDATE_TASK=false;
      insert actions;


      
      Task tsk1 = new Task(Subject='Task1',ActivityDate=Date.today().addDays(-5), WhoId=ctct.Id, Status='Not Started', Type='TestAct1', DS_Denali__DialSource_Action__c=action1.Id, OwnerId=runningUser.Id);
      Task tsk2 = new Task(Subject='Task2',ActivityDate=Date.today().addDays(-3), WhoId=ctct.Id, Status='Not Started', Type='TestAct2', DS_Denali__DialSource_Action__c=action2.Id, OwnerId=runningUser.Id);
      TaskHelper.SKIP_TRIGGERS=true;
      Task[] tsks = new Task[]{tsk1,tsk2};
      insert tsks;
      
      Event evt1 = new Event(Subject='Event1',ActivityDate=Date.today().addDays(1), ActivityDateTime=Datetime.now().addDays(1), DurationInMinutes=30, WhoId=ctct.Id, Type='TestAct3');
      Event evt2 = new Event(Subject='Event2',ActivityDate=Date.today().addDays(2), ActivityDateTime=Datetime.now().addDays(2), DurationInMinutes=30, WhoId=ctct.Id, Type='TestAct4');
      Event[] events = new Event[]{evt1,evt2};
      insert events;
      
      ActivityHelper.ActWrap[] allActivity = ActivityHelper.getLatestActivity(acct.Id);
      System.assertEquals(4,allActivity.size());
       
      
      // first in the list should be the newest.
      ActivityHelper.ActWrap latestAct = allActivity[0];
      System.assertEquals(evt2.Id, latestAct.Id);
      System.assertEquals(evt2.ActivityDate, latestAct.activityDate);
      System.assertEquals(ctct.Name, latestAct.contactName);
      System.assertEquals(evt2.Type, latestAct.activityType);
      System.assertEquals(evt2.Subject, latestAct.subject);
       
      ActivityHelper.ActWrap earliestAct = allActivity[3];
      System.assertEquals(tsk1.Id, earliestAct.Id);
      System.assertEquals('(555) 345-6789', earliestAct.phone);
      System.assertEquals(false, earliestAct.hasRecording);
      System.assertEquals(runningUser.Name, earliestAct.ownerName);
       
      ActivityHelper.ActWrap nextAct = allActivity[2];
      System.assertEquals(tsk2.Id, nextAct.Id);
      System.assertEquals('(555) 123-4570', nextAct.phone);
      System.assertEquals(true, nextAct.hasRecording);
       System.assertEquals(runningUser.Name, nextAct.ownerName);
     
        
   } // testAccountActivity
} // class ActivityHelperTest