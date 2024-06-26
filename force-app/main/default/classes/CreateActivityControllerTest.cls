/* 
 * Test methods for the CreateActivityController class.
 *
 *  History
 *  -------
    10/17/2017 Dan Carmen       Created
    11/19/2018 Jermaine Stukes  Added test for reminder dates
    12/24/2018 Jermaine Stukes  Update reminder date tests
    08/02/2021 Dan Carmen       Add ability to pass in Description
    11/10/2023 Dan Carmen       Remove insertPlatformTracker

*/
@isTest
private class CreateActivityControllerTest {

   static testMethod void testGetTask() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='Test Last');
      insert ctct;
      
      Task tsk = CreateActivityController.getNewTask('Task',ctct.Id,'Description','John,Sue');
      System.assertEquals(ctct.Id, tsk.WhoId);
      
      tsk = CreateActivityController.saveTask(JSON.serialize(tsk));
      System.assertEquals(true, tsk.Id != null);
   } // testGetTask
   
   static testMethod void testGetEvent() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='Test Last');
      insert ctct;
      
      System.assertEquals(false, CreateActivityController.initialPresentationCheck(acct.Id));

      Event evnt = CreateActivityController.getNewEvent('Event',ctct.Id,'Description','John,Sue');
      System.assertEquals(ctct.Id, evnt.WhoId);
      
      evnt = CreateActivityController.saveEvent(JSON.serialize(evnt));
      System.assertEquals(true, evnt.Id != null);
   } // testGetEvent
   
   
   static testMethod void testGetOptionsTask() {
      Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_TASK).getRecordTypeId();
      RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordtypeId);
      
      String[] statusOptions = new String[]{'Status1','Status2','Status3','Status4'};
      String statusOptionsStr = PicklistDetailCalloutHelper.concatOptions(statusOptions);
      String[] typeOptions = new String[]{'Type1','Type2','Type3','Type4'};
      String typeOptionsStr = PicklistDetailCalloutHelper.concatOptions(typeOptions);
      
      PicklistDetailCalloutHelper.TASK_PICKLIST_FIELD_NAMES = 'Status,Type';

      PicklistDetail__c pkDetail1 = new PicklistDetail__c(Name='Test1', FieldName__c='Status', ObjectName__c=ObjectHelper.OBJECT_TASK
                                          ,RecordTypeName__c=rt.Name, RecordTypeId__c=rt.Id
                                          ,PicklistData__c=statusOptionsStr, Developer_Name__c=rt.DeveloperName);
      PicklistDetail__c pkDetail2 = new PicklistDetail__c(Name='Test2', FieldName__c='Type', ObjectName__c=ObjectHelper.OBJECT_TASK
                                          ,RecordTypeName__c=rt.Name, RecordTypeId__c=rt.Id
                                          ,PicklistData__c=typeOptionsStr, Developer_Name__c=rt.DeveloperName);
      PicklistDetail__c[] pkDetails = new PicklistDetail__c[]{pkDetail1,pkDetail2};
      insert pkDetails;


      Test.startTest();
      SelectOptionWrapper[] taskOptions = CreateActivityController.getOptions(ObjectHelper.OBJECT_TASK);
      Test.stopTest();

      System.assertEquals(taskOptions.size() > 0, true);
   } // testGetOptions
     
   static testMethod void testGetOptionsEvent() {
      Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_EVENT).getRecordTypeId();
      RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordtypeId);
      
      String[] typeOptions = new String[]{'Type1','Type2','Type3','Type4'};
      String typeOptionsStr = PicklistDetailCalloutHelper.concatOptions(typeOptions);
      
      PicklistDetailCalloutHelper.EVENT_PICKLIST_FIELD_NAMES = 'Type';
      PicklistDetail__c pkDetail = new PicklistDetail__c(Name='Test2', FieldName__c='Type', ObjectName__c=ObjectHelper.OBJECT_EVENT
                                          ,RecordTypeName__c=rt.Name, RecordTypeId__c=rt.Id
                                          ,PicklistData__c=typeOptionsStr, Developer_Name__c=rt.DeveloperName);
      insert pkDetail;

      Test.startTest();
      SelectOptionWrapper[] eventOptions = CreateActivityController.getOptions(ObjectHelper.OBJECT_EVENT);
      Test.stopTest();

      System.assertEquals(eventOptions.size() > 0, true);
   }

   static testMethod void testGetDataEnvelope() {
      Id recordTypeId = RecordTypeHelper.getDefaultRecordType(ObjectHelper.OBJECT_EVENT).getRecordTypeId();
      RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordtypeId);
      
      String[] typeOptions = new String[]{'Type1','Type2','Type3','Type4'};
      String typeOptionsStr = PicklistDetailCalloutHelper.concatOptions(typeOptions);
      
      PicklistDetailCalloutHelper.EVENT_PICKLIST_FIELD_NAMES = 'Type';
      PicklistDetail__c pkDetail = new PicklistDetail__c(Name='Test2', FieldName__c='Type', ObjectName__c=ObjectHelper.OBJECT_EVENT
                                          ,RecordTypeName__c=rt.Name, RecordTypeId__c=rt.Id
                                          ,PicklistData__c=typeOptionsStr, Developer_Name__c=rt.DeveloperName);
      insert pkDetail;

      Test.startTest();
      CreateActivityController.DataEnvelope envelope = CreateActivityController.getDataEnvelope(ObjectHelper.OBJECT_EVENT);
      Test.stopTest();

      System.assertEquals(envelope.options.size() > 0, true);
      System.assertEquals(envelope.profileName != null, true);
   }

   private static List<PlatformTracker__c> getPlatformTrackers(){
      return [SELECT Name, Id, RecordId__c, ObjectType__c FROM PlatformTracker__c];
   }
    static testMethod void testgetEventReminderDate(){
        Account acct = new Account(Name='Test Account');
        insert acct;
        
        Contact ctct = new Contact(AccountId=acct.Id, LastName='Test Last');
        insert ctct;
        
        Event evnt = CreateActivityController.getNewEvent('Event',ctct.Id);
        evnt.ActivityDateTime = DateTime.now();
        DateTime testDateTime = evnt.ActivityDateTime.addMinutes(-30);
        CreateActivityController.getEventReminderDate(evnt); 
        System.assertNotEquals(testDateTime, evnt.ReminderDateTime);
        
        evnt.ActivityDateTime = evnt.ActivityDateTime.addDays(2);
        testDateTime = evnt.ActivityDateTime.addMinutes(-30);
        CreateActivityController.getEventReminderDate(evnt); 
        System.assertNotEquals(testDateTime, evnt.ReminderDateTime);
        
        evnt.IsReminderSet = true;
        CreateActivityController.getEventReminderDate(evnt);
        System.assertEquals(testDateTime, evnt.ReminderDateTime);
    }
    static testMethod void testgetTaskReminderDate(){
        Account acct = new Account(Name='Test Account');
        insert acct;
        
        Contact ctct = new Contact(AccountId=acct.Id, LastName='Test Last');
        insert ctct;
        
        Task tsk = CreateActivityController.getNewTask('Task',ctct.Id);
        tsk.ActivityDate = Date.today();
        DateTime testDateTime = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(8,0,0,0));
        CreateActivityController.getTaskReminderDate(tsk); 
        System.assertNotEquals(testDateTime, tsk.ReminderDateTime);
        
        tsk.ActivityDate = Date.today() + 2;
        testDateTime = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(8,0,0,0));
        CreateActivityController.getTaskReminderDate(tsk);
        System.assertNotEquals(testDateTime, tsk.ReminderDateTime);
        
        tsk.IsReminderSet = true;
        CreateActivityController.getTaskReminderDate(tsk);
        System.assertEquals(testDateTime, tsk.ReminderDateTime);
    }

    static testMethod void testPeoUser() {
        User u = [Select Id, Name from User where IsActive=true and Sales_Org__c='PEO' limit 1];
        System.runAs(u) {
           System.assertEquals(true,CreateActivityController.isPEOSalesUser());
        }
    } // testPeoUser
    
    static testMethod void testIsSelectedLabelValueEvent() {
       Create_Activity_Button__c cab1 = new Create_Activity_Button__c(Name='cab1', Picklist_Name__c='Picklist1', Group_Name__c='Group1', Label_Name__c='Label1', Sort_Order__c=1,Is_Event__c=true);
       Create_Activity_Button__c cab2 = new Create_Activity_Button__c(Name='cab2', Picklist_Name__c='Picklist2', Group_Name__c='Group2', Label_Name__c='Label2', Sort_Order__c=2,Is_Event__c=false);
       Create_Activity_Button__c cab3 = new Create_Activity_Button__c(Name='cab3', Picklist_Name__c='Picklist2', Group_Name__c='Group2', Label_Name__c='Label3', Sort_Order__c=3,Is_Event__c=false);
       Create_Activity_Button__c cab4 = new Create_Activity_Button__c(Name='cab4', Picklist_Name__c='Picklist2', Group_Name__c='Group2', Label_Name__c='Label4', Sort_Order__c=4,Is_Event__c=false);
       Create_Activity_Button__c[] cabs = new Create_Activity_Button__c[]{cab1,cab2,cab3,cab4};
       insert cabs;
        
       System.assertEquals(true, CreateActivityController.isSelectedLabelValueEvent('Picklist1', 'Group1', 'Label1'));
       System.assertEquals(false, CreateActivityController.isSelectedLabelValueEvent('Picklist2', 'Group2', 'Label2'));
        
        
       String[] values = CreateActivityController.getPicklistValues('Picklist2', 'Group2', false, false);
       System.assertEquals(3,values.size());
        
    } // testIsSelectedLabelValueEvent
    
} // class CreateActivityControllerTest