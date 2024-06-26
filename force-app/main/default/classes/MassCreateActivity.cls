/* 
 * Ability to mass create activities off of a list
 *
 * History 
 * -------
 * 01/31/2012 Dan Carmen         Created
   03/21/2012 Dan Carmen         Added in check for object existing
   03/03/2016 Cindy Freeman     Fast track case # 20447573 -Changed to use Account.Type field for Accounts and Contacts WAR call type, 
                                still use ReferralContact.Referral Type for the WAR call type
   09/27/2017 Dan Carmen        Changes so this will work for a single record, not just a list view
   11/01/2017 Dan Carmen        Additional functionality for tasks and events.
   11/14/2017 Lynn Michels      Add CPE_Topic__c and TAP_Topic__c fields to be copied when select all is chosen.
   11/17/2017 Dan Carmen        Set the reminder on tasks and events dated in the future - if not coming from a list view.
   09/10/2018 Dan Carmen        Change to handle bulk activity
   11/08/2018 Jermaine Stukes	Update to reminder 
   12/10/2018 Jermaine Stukes	Changed Sales Engineer tasks to events
   06/30/2020 Manmeet Vaseer	SFDC-3487 (US6) - Modified setDefaultDependentEventFields() for new Marketing Activity Type.
   08/02/2021 Dan Carmen        Update to work from Referral Account
   
 */
public with sharing class MassCreateActivity {

   private ApexPages.StandardSetController stdSetController;
   
   // what object did this page originate from?
   private String sourceObjectName = null;
   private String objectPrefix = null;
   
   public Boolean inlineForm{get;private set;}
   public Boolean entryFromListView = false;
   
   /** The type of activity to create - Task or Event. */
   public String activityType{get;set;}
   
   /** The records that were passed in from the list view. */
   private SObject[] selectedRecords = null;
   
   /** To use the values in the first activity for all activities. */
   public Boolean useFirstActivity{get;set;}
   
   public MassCreateActivity(ApexPages.StandardSetController stdSetController) {
      this.stdSetController = stdSetController;
      entryFromListView = true;
      // Get the records that were selected
      selectedRecords = stdSetController.getSelected();
      objectId = ((selectedRecords != null && !selectedRecords.isEmpty()) ? selectedRecords[0].Id : null);
      runningUser = UserHelper.getRunningUser();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'MassCreateActivity closestTime='+mw.setClosestTimeOption2(DateTime.now().addHours(10))));
      init();
   } // MassCreateActivity

   // this should always be set on entry to the page as long as a record exists
   public Id objectId = null;
   public Boolean visualForceContext=true;
   public User runningUser = null;
   
   public MassCreateActivity() {
      inlineForm = false;
      objectId = System.currentPageReference().getParameters().get('Id');
      entryFromListView = false;
      runningUser = UserHelper.getRunningUser();
      init();
   } // MassCreateActivity

   public MassCreateActivity(Id p_objectId, String p_activityType) {
      runningUser = UserHelper.getRunningUser();
      objectId = p_objectId;
      entryFromListView = false;
      visualForceContext = false;
      init();
      activityType = p_activityType;
      setupActivity();
   }
  /*
   public MassCreateActivity(ApexPages.StandardController stdController) {
      objectId = System.currentPageReference().getParameters().get('Id');
      selectedRecords = new SObject[]{stdController.getRecord()};
      entryFromListView = false;
      init();
   } // MassCreateActivity
   */
   public String newObjectType{get;set;}
   
   public static String TYPE_TASK=Label.Task_Object;
   public static String TYPE_EVENT=Label.Event_Object;
   public static String TYPE_NOTE=Label.Activity_Type_Note;
   public static String TYPE_INIT_PRES=Label.Activity_Type_Initial_Presentation;
   public static String TYPE_TELEMARKETING=Label.Activity_Type_Telemarketing;
   public static String TYPE_EMAIL=Label.Activity_Type_Email;
   public static String TYPE_FOLLOW_UP_CALL=Label.Activity_Type_Follow_Up_Call;
   public static String TYPE_FOLLOW_UP_MEETING=Label.Activity_Type_Follow_Up_Meeting;
   public static String TYPE_MEETING=Label.Activity_Type_Meeting;
   public static String TYPE_CURRENT_CLIENT_CALL=Label.Activity_Type_Current_Client_Call;
   public static String TYPE_CALL=Label.Activity_Type_Call;
   public static String TYPE_SCHEDULE_DISCOVERY=Label.Activity_Type_Schedule_Discovery;
   public static String TYPE_SCHEDULE_DEMO=Label.Activity_Type_Schedule_Demo;
   public static String TYPE_SCHEDULE_PROPOSAL_MEETING=Label.Activity_Type_Schedule_Proposal_Meeting;
   public static String TYPE_SCHEDULE_PICK_UP=Label.Activity_Type_Schedule_Pick_Up;
   public static String TYPE_MARKETING=Label.Activity_Type_Marketing;
   public static String TYPE_DROP= Label.Activity_Type_Drop;

   public static String TYPE_CALL_CLIENT=Label.Activity_Type_Call_Client;
   public static String TYPE_CALL_INTERNAL=Label.Activity_Type_Call_Internal;
   public static String TYPE_CALL_THIRD_PARTY=Label.Activity_Type_Call_Third_Party;
   public static String TYPE_DATA_EXTRACT=Label.Activity_Type_Data_Extract;
   public static String TYPE_INTERFACE=Label.Activity_Type_Interface;
   public static String TYPE_OTHER=Label.Activity_Type_Other;
   public static String TYPE_TESTING=Label.Activity_Type_Testing;
   public static String TYPE_SHADOW=Label.Activity_Type_Shadow;

   public static String TYPE_DEMO=Label.Activity_Type_Demo;
   public static String TYPE_DISCOVER_FLEX=Label.Activity_Type_Discover_Flex;
   public static String TYPE_DISCOVERY_STANDARD_APPT=Label.Activity_Type_Discovery_Standard_Appt;
   public static String TYPE_PAYCHEX_FLEX_SEMINAR=Label.Activity_Type_Paychex_Flex_Seminar;
   public static String TYPE_SANDBOX=Label.Activity_Type_Sandbox;
   public static String TYPE_DISCOVERY_SIPM_APPT=Label.Activity_Type_Discovery_SIPM_Appt;
   public static String TYPE_POST_DEMO_DEBRIEF=Label.Activity_Type_Post_Demo_Debrief;
   public static String TYPE_PRE_DEMO_STRATEGY_CALL=Label.Activity_Type_Pre_Demo_Strategy_Call;
   

   public List<SelectOption> activityTypes{get;set;}
   public void setupActivityType() {
      // default to Task
      activityType = TYPE_TASK;
      newObjectType = ObjectHelper.OBJECT_TASK;
      activityTypes = new List<SelectOption>();
      activityTypes.add(new SelectOption(TYPE_TASK,TYPE_TASK));
      activityTypes.add(new SelectOption(TYPE_EVENT,TYPE_EVENT));
      activityTypes.add(new SelectOption(TYPE_NOTE,TYPE_NOTE));
      if (String.isNotBlank(sourceObjectName)) {
         if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            activityTypes.add(new SelectOption(TYPE_INIT_PRES,TYPE_INIT_PRES));
         }
      }
      
   } // setupActivityType
   
   public void init() {
      useFirstActivity = false;
      if (visualForceContext) {
         String inline = System.currentPageReference().getParameters().get('inline');
         inlineForm = (String.isNotBlank(inline) && inline == '1');
      }
      checkObjectType();
      
      // if no records were selected, give the user an error
      if (String.isBlank(sourceObjectName)) {
         if (visualForceContext) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'At least one record must be selected to proceed!'));
         }
         System.debug('At least one record must be selected to proceed!');
      } else {
         // check the type of object - get the first record
         setupActivityType();
         
         // if a lead source field is defined requery the data 
         if (String.isNotBlank(queryFields) && String.isNotBlank(sourceObjectName)) {

            // collect the record ids
            Id[] recordIds = new Id[]{};
            // one or the other should have values
            if (selectedRecords != null) {
               for (SObject obj : selectedRecords) {
                  recordIds.add(obj.Id);
               }
            } else if (objectId != null) {
               recordIds.add(objectId);
            }
            
            String query = 'Select Id, Name, '+queryFields+' From '+sourceObjectName+' where Id in :recordIds ';
            selectedRecords = Database.query(query);
         }
         setupActivity();
      }
   
   } // init
   
   public PageReference changeActivity() {
      setupActivity();
      return null;
   } // changeActivity

   public CreateOppAndMeeting coam = null;
   
   private void setupActivity() {
      if (coam == null && !selectedRecords.isEmpty()) {
         String salesOrg = runningUser.Sales_Org__c;
         if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            Opportunity opp = (Opportunity)selectedRecords[0];
            salesOrg = opp.Owner.Sales_Org__c;
         }
         coam = new CreateOppAndMeeting(salesOrg);
      } // if (coam == nul

      // get the default record type of the user
      if (activityTypeIsForTask(activityType)) {
         setupTasks(activityType);
      } else if (activityTypeIsForEvent(activityType)) {
         setupEvents(activityType);
      }
   } // setupActivity
   
   private static Boolean activityTypeIsForTask(String activityType){
      return (activityType == TYPE_TASK 
         || activityType == TYPE_NOTE 
         || activityType == TYPE_TELEMARKETING 
         || activityType == TYPE_EMAIL 
         || activityType == TYPE_FOLLOW_UP_CALL 
         || activityType == TYPE_CURRENT_CLIENT_CALL 
         || activityType == TYPE_CALL
         || activityType == TYPE_DROP
      );
   }
   private static Boolean activityTypeIsForEvent(String activityType){
       return (
           activityType == TYPE_EVENT 
           || activityType == TYPE_INIT_PRES 
           || activityType == TYPE_FOLLOW_UP_MEETING 
           || activityType == TYPE_MEETING
           || activityType == TYPE_SCHEDULE_DISCOVERY
           || activityType == TYPE_SCHEDULE_DEMO
           || activityType == TYPE_SCHEDULE_PROPOSAL_MEETING
           || activityType == TYPE_SCHEDULE_PICK_UP
           || activityType == TYPE_DEMO 
           || activityType == TYPE_DISCOVER_FLEX 
           || activityType == TYPE_DISCOVERY_STANDARD_APPT
           || activityType == TYPE_PAYCHEX_FLEX_SEMINAR 
           || activityType == TYPE_SANDBOX
           || activityType == TYPE_CALL_CLIENT 
           || activityType == TYPE_CALL_INTERNAL 
           || activityType == TYPE_CALL_THIRD_PARTY 
           || activityType == TYPE_DATA_EXTRACT 
           || activityType == TYPE_INTERFACE
           || activityType == TYPE_OTHER 
           || activityType == TYPE_TESTING 
           || activityType == TYPE_SHADOW 
           || activityType == TYPE_DISCOVERY_SIPM_APPT
           || activityType == TYPE_POST_DEMO_DEBRIEF
           || activityType == TYPE_PRE_DEMO_STRATEGY_CALL
           || activityType == TYPE_MARKETING
      ); //sfcd-3487
   }

   private void setupTasks(String activityType) {
      newObjectType = ObjectHelper.OBJECT_TASK;
      Id rtId = RecordTypeHelper.getDefaultRecordType(newObjectType).getRecordTypeId();
      taskList = new List<Task>();
      meetingList = null;    
         
      for (SObject so : selectedRecords) {
         Task t = null;
         if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            Opportunity opp = (Opportunity) so;
            t = (Task)getActivity(opp);
         } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
            Account acc = (Account) so;
            t = (Task)getActivity(acc);
         } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
            Contact con = (Contact) so;
            t = (Task)getActivity(con);
         } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
            Lead l = (Lead) so;
            t = (Task)getActivity(l);
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
            Referral_Contact__c refContact = (Referral_Contact__c) so;
            t = (Task)getActivity(refContact);
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
            Referral_Account__c refAccount = (Referral_Account__c) so;
            t = (Task)getActivity(refAccount);
         }
         
         t = setDefaultTaskFields(t, so);

         t.WhatId = getWhatId(so);
         t.WhoId = getWhoId(so);
 
         taskList.add(t);

      } // for
   } // setupTasks
   
   private void setupEvents(String activityType) {
      newObjectType = ObjectHelper.OBJECT_EVENT;
      // use the default record type of the running user
      //Id rtId = RecordTypeHelper.getDefaultRecordType(newObjectType).getRecordTypeId();
      // clear out the task list since we're creating events
      taskList = null;
      
      meetingList = new List<MeetingWrapper>();
      for (SObject so : selectedRecords) {
         Event e = null;
         if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            e = (Event)getActivity((Opportunity)so);
         } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
            e = (Event)getActivity((Account)so);
         } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
            e = (Event)getActivity((Contact)so);
         } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
            e = (Event)getActivity((Lead)so);
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
            e = (Event)getActivity((Referral_Contact__c)so);
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
            e = (Event)getActivity((Referral_Account__c)so);
         }
            
         e = setDefaultEventFields(e, so);

         e.WhatId = getWhatId(so);
         e.WhoId = getWhoId(so);

         MeetingWrapper mw = new MeetingWrapper();
         mw.evnt = e;
         meetingList.add(mw);
      } // for
   } // setupEvents

   private Event setDefaultEventFields(Event e, SObject parent){
      String profileName = ProfileDA.getCurrentProfile().Name;
      setDefaultStaticEventFields(e, profileName);
      setDefaultDependentEventFields(e, parent, profileName);
      return e;
   }
   private Task setDefaultTaskFields(Task tsk, SObject parent){
      String profileName = ProfileDA.getCurrentProfile().Name;
      setDefaultStaticTaskFields(tsk, profileName);
      setDefaultDependentTaskFields(tsk, parent, profileName);
      return tsk;
   }

   private void setDefaultStaticEventFields(Event e, String profileName){
      
      Create_Activity_Default__mdt defaultFields = queryDefaultActivityFields(activityType, profileName);

      if(defaultFields != null){

         e.Type = String.isBlank(defaultFields.Type__c) ? e.Type : defaultFields.Type__c;
         e.Outcome__c = String.isBlank(defaultFields.Outcome__c) ? e.Outcome__c : defaultFields.Outcome__c;
         e.ActivityDateTime = defaultFields.ActivityDateOffset__c == null ? e.ActivityDateTime : DateTime.now().addDays(Integer.valueOf(defaultFields.ActivityDateOffset__c));
         e.DurationInMinutes = defaultFields.DurationInMinutes__c == null ? e.DurationInMinutes : Integer.valueOf(defaultFields.DurationInMinutes__c);
         e.Onsite_or_Virtual__c = String.isBlank(defaultFields.Onsite_Or_Virtual__c) ? e.Onsite_or_Virtual__c : defaultFields.Onsite_Or_Virtual__c;
         e.Appointment_Type__c = String.isBlank(defaultFields.Appointment_Type__c) ? e.Appointment_Type__c : defaultFields.Appointment_Type__c;
      }
   }

   private void setDefaultStaticTaskFields(Task t, String profileName){

      Create_Activity_Default__mdt defaultFields = queryDefaultActivityFields(activityType, profileName);
      System.debug(defaultFields);
      System.debug(activityType);
      System.debug(profileName);
      if(defaultFields != null){

         t.Status = String.isBlank(defaultFields.Status__c) ? t.Status : defaultFields.Status__c;
         t.Type = String.isBlank(defaultFields.Type__c) ? t.Type : defaultFields.Type__c;
         t.Outcome__c = String.isBlank(defaultFields.Outcome__c) ? t.Outcome__c : defaultFields.Outcome__c;
         t.ActivityDate = defaultFields.ActivityDateOffset__c == null ? t.ActivityDate : System.Today().addDays(Integer.valueOf(defaultFields.ActivityDateOffset__c));
         t.Priority = defaultFields.Priority__c == null ? t.Priority : defaultFields.Priority__c;
         t.Onsite_or_Virtual__c = String.isBlank(defaultFields.Onsite_Or_Virtual__c) ? t.Onsite_or_Virtual__c : defaultFields.Onsite_Or_Virtual__c;
         t.Appointment_Type__c = String.isBlank(defaultFields.Appointment_Type__c) ? t.Appointment_Type__c : defaultFields.Appointment_Type__c;
      
      }
   }

   private void setDefaultDependentTaskFields(Task tsk, SObject parent, String profileName){
      String accountName = getAccountName(parent);
      String name = getRecordName(parent);
      String phoneNumber = getObjectPhoneNumber(parent);

      // get the default record type of the user
      if (activityType == TYPE_TASK){
         tsk.Subject = 'To Do' + ' - ' + name;
         tsk.Description = '';

      }else if(profileName == 'Sales Engineer'){
         tsk.Subject =  tsk.Appointment_Type__c + ' - ' + name;
         tsk.Description = '';

      }else if (activityType == TYPE_NOTE){
         tsk.Subject = TYPE_NOTE + ' - ' + name;
         tsk.Description = '';

      }else if(activityType == TYPE_DROP){
        tsk.Subject = TYPE_DROP + ' - ' + name;
        tsk.Description = '';
        
     }else if (activityType == TYPE_TELEMARKETING){
         tsk.Subject = TYPE_TELEMARKETING + ' - ' + name;
         tsk.Description = '';

      }else if (activityType == TYPE_EMAIL){
         tsk.Subject = 'Email' + ' - ' + name;
         tsk.Description = '';

      }else if (activityType == TYPE_FOLLOW_UP_CALL){
         tsk.Subject = 'Follow Up' + ' - ' + name;
         tsk.Description = '';
      
      }else if (activityType == TYPE_CURRENT_CLIENT_CALL){
         tsk.Subject = TYPE_CURRENT_CLIENT_CALL + ' - ' + name;
         tsk.Description = '';

      }else if (activityType == TYPE_CALL){
         tsk.Subject = TYPE_CALL + ' - ' + name;
         tsk.Description = '';

      }
   }

   private void setDefaultDependentEventFields(Event evnt, SObject parent, String profileName){
      String accountName = getAccountName(parent);
      String name = getRecordName(parent);
      String phoneNumber = getObjectPhoneNumber(parent);

      if (activityType == TYPE_EVENT){
         evnt.Subject = 'Meeting' + ' - ' + name;

      }else if(profileName == 'Sales Engineer'){
         evnt.Subject =  evnt.Appointment_Type__c + ' - ' + name;
         evnt.Description = '';

      }else if (activityType == TYPE_FOLLOW_UP_MEETING){
         evnt.Subject = 'Meeting' + ' - ' + name + (String.isBlank(phoneNumber) ? '' : ' - ' + phoneNumber);

      }else if (activityType == TYPE_INIT_PRES){

      }else if (activityType == TYPE_MEETING){
         evnt.Subject = TYPE_MEETING + ' - ' + name;
      }else if (activityType == TYPE_SCHEDULE_DISCOVERY){
         evnt.Subject = 'Discovery' + ' - ' + name;
      }else if (activityType == TYPE_SCHEDULE_DEMO){
         evnt.Subject = 'Demo' + ' - ' + name;
      }else if (activityType == TYPE_SCHEDULE_PROPOSAL_MEETING){
         evnt.Subject = 'Proposal Presentation' + ' - ' + name;
      }else if (activityType == TYPE_SCHEDULE_PICK_UP){
         evnt.Subject = 'Pick Up' + ' - ' + name;
      }
      else if (activityType == TYPE_MARKETING){
         evnt.Subject = 'Marketing' + ' - ' + name;
      }
   } // setDefaultDependentEventFields
   
   // store in a map so you only query once
   public static Map<String,Create_Activity_Default__mdt> cadByProfileName = new Map<String,Create_Activity_Default__mdt>();
   
   private static Create_Activity_Default__mdt queryDefaultActivityFields(String activityType, String profileName){
      String key = activityType+profileName;
      Create_Activity_Default__mdt defaultFields = cadByProfileName.get(key);
      System.debug('queryDefaultActivityFields key='+key+' defaultFields='+(defaultFields != null));
      if (defaultFields == null) {
         List<Create_Activity_Default__mdt> defaultFieldValues;
         
         if(profileName == 'Sales Engineer'){         
            defaultFieldValues = [
               SELECT ActivityType__c, Status__c, Type__c, Priority__c, Outcome__c, DurationInMinutes__c, ActivityDateOffset__c, Onsite_Or_Virtual__c, Appointment_Type__c 
               FROM Create_Activity_Default__mdt 
               WHERE ActivityType__c = :activityType AND Sales_Engineers__c = true
            ];
         }else{
            defaultFieldValues = [
               SELECT ActivityType__c, Status__c, Type__c, Priority__c, Outcome__c, DurationInMinutes__c, ActivityDateOffset__c, Onsite_Or_Virtual__c, Appointment_Type__c 
               FROM Create_Activity_Default__mdt 
               WHERE ActivityType__c = :activityType AND Sales_Engineers__c = false
            ];
         }

         if(defaultFieldValues.size() > 0){
            defaultFields = defaultFieldValues.get(0);
            cadByProfileName.put(key, defaultFields);
         }
         
      }
      return defaultFields;
   } // queryDefaultActivityFields

   

   private String getAccountName(SObject so){
      if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
         Opportunity opp = (Opportunity) so;
         return opp.Account.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
         Account acc = (Account) so;
         return acc.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
         Contact con = (Contact) so;
         return con.Account.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
         Lead l = (Lead) so;
         return l.Company;
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
         Referral_Contact__c refContact = (Referral_Contact__c) so;
         return refContact.Referral_Account__r.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
         Referral_Account__c refAcct = (Referral_Account__c) so;
         return refAcct.Name;
      }

      return '';

   }

   private String getRecordName(SObject so){
      if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
         Opportunity opp = (Opportunity) so;
         return opp.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
         Account acc = (Account) so;
         return acc.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
         Contact con = (Contact) so;
         return con.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
         Lead l = (Lead) so;
         return l.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
         Referral_Contact__c refContact = (Referral_Contact__c) so;
         return refContact.Name;
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
         Referral_Account__c refAcct = (Referral_Account__c) so;
         return refAcct.Name;
      }

      return '';

   }

   private String getObjectPhoneNumber(SObject so){
      if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
         Opportunity opp = (Opportunity) so;
         return (!opp.OpportunityContactRoles.isEmpty() ? opp.OpportunityContactRoles[0].Contact.Phone : '');
      } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
         Account acc = (Account) so;
         return acc.Phone != null ? acc.Phone : '';
      } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
         Contact con = (Contact) so;
         return con.Phone != null ? con.Phone : '';
      } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
         Lead l = (Lead) so;
         return l.Phone != null ? l.Phone : '';
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
         Referral_Contact__c refContact = (Referral_Contact__c) so;
         return refContact.Phone__c != null ? refContact.Phone__c : '';
      } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
         Referral_Account__c refAcct = (Referral_Account__c) so;
         return refAcct.Phone__c != null ? refAcct.Phone__c : '';
      }

      return '';

   }

   public SObject getActivity(Opportunity opp) {
      Contact ctct = (!opp.OpportunityContactRoles.isEmpty() ? opp.OpportunityContactRoles[0].Contact : null);
      SObject newRec = null;
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(opp.Account, ctct, 'MassCreateActivity', getLeadSource(opp));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(opp.Account, ctct, 'MassCreateActivity', getLeadSource(opp));
      }
      return newRec;
   } // getActivity
   
   public SObject getActivity(Account acct) {
      SObject newRec = null;
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(acct, acct.SignificantContact__r, 'MassCreateActivity', getLeadSource(acct));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(acct, acct.SignificantContact__r, 'MassCreateActivity', getLeadSource(acct));
      }
      return newRec;
   } // getActivity

   public SObject getActivity(Contact ctct) {
      SObject newRec = null;
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(ctct.Account, ctct, 'MassCreateActivity', getLeadSource(ctct));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(ctct.Account, ctct, 'MassCreateActivity', getLeadSource(ctct));
      }
      return newRec;
   } // getActivity

   public SObject getActivity(Lead ld) {
      SObject newRec = null;
      Account acct = new Account(Name=ld.Company, ShippingStreet=ld.Street, ShippingCity=ld.City, ShippingState=ld.State, ShippingPostalCode=ld.PostalCode);
      Contact ctct = new Contact(FirstName=ld.FirstName, LastName=ld.LastName, Email=ld.Email, Phone=ld.Phone, MobilePhone=ld.MobilePhone);
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(acct, ctct, 'MassCreateActivity', getLeadSource(ld));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(acct, ctct, 'MassCreateActivity', getLeadSource(ld));
      }
      return newRec;
   } // getActivity

   public SObject getActivity(Referral_Contact__c refCtct) {
      SObject newRec = null;
      Contact ctct = new Contact(FirstName=refCtct.First_Name__c, LastName=refCtct.Last_Name__c, Email=refCtct.Email__c, Phone=refCtct.Phone__c, MobilePhone=refCtct.Mobile_Phone__c);

      Referral_Account__c refAcct = refCtct.Referral_Account__r;
      Account acct = new Account();
      if (refAcct != null) {
         acct.Name = refAcct.Name;
         acct.ShippingStreet = refAcct.Street_Address_1__c;
         acct.ShippingCity = refAcct.City__c;
         acct.ShippingState = refAcct.State_Province__c;
         acct.ShippingPostalCode = refAcct.Zip_Postal_Code__c;
      }
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(acct, ctct, 'MassCreateActivity', getLeadSource(refCtct));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(acct, ctct, 'MassCreateActivity', getLeadSource(refCtct));
      }
      return newRec;
   } // getActivity

   public SObject getActivity(Referral_Account__c refAcct) {
      SObject newRec = null;
      Account acct = new Account();
      System.debug('getActivity refAcct='+(refAcct != null ? refAcct.Name : 'No Ref Acct'));
      if (refAcct != null) {
         acct.Name = refAcct.Name;
         acct.ShippingStreet = refAcct.Street_Address_1__c;
         acct.ShippingCity = refAcct.City__c;
         acct.ShippingState = refAcct.State_Province__c;
         acct.ShippingPostalCode = refAcct.Zip_Postal_Code__c;
      }
      if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         newRec = coam.createEvent(acct, null, 'MassCreateActivity', getLeadSource(refAcct));
      } else if (newObjectType == ObjectHelper.OBJECT_TASK) {
         newRec = coam.createTask(acct, null, 'MassCreateActivity', getLeadSource(refAcct));
      }
      return newRec;
   } // getActivity

   public Boolean useWho {
      get {
         return (sourceObjectName == ObjectHelper.OBJECT_LEAD
               || sourceObjectName == ObjectHelper.OBJECT_CONTACT
               || sourceObjectName == ObjectHelper.OBJECT_OPPTY);
      }
   } // useWho
    
   public Id getWhoId(SObject so) {
      Id whoId = null;
      try {
         if (sourceObjectName == ObjectHelper.OBJECT_LEAD
               || sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
            whoId = so.Id;
         } else if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            Opportunity opp = (Opportunity)so;
            if (opp.OpportunityContactRoles != null && !opp.OpportunityContactRoles.isEmpty()) {
               whoId = opp.OpportunityContactRoles[0].ContactId;
            }
         }
      } catch (Exception e) {
         System.debug('Exception in getWhoId: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return whoId;
   } // getWhoId
   
   // To use the whatId field. If true, use the whatId field. If false, use the whoId 
   public Boolean useWhat{
      get {
         return (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT
                || sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT
                || sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT
                || sourceObjectName == ObjectHelper.OBJECT_OPPTY);
      }
   } // useWhat
   

   public Id getWhatId(SObject so) {
      Id whatId = null;
      try {
         if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT
                || sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT
                || sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT
                || sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            whatId = so.Id;
         }   
      } catch (Exception e) {
         System.debug('Exception in getWhatId: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return whatId;
   } // getWhatId
   
   public String getLeadSource(SObject so) {
      String leadSource = null;
      try {
         if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
            Contact ctct = (Contact)so;
            leadSource = ctct.Account.Type;
         } else if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
            leadSource = (String)so.get('LeadSource');
         } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
            leadSource = (String)so.get('Type');
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
            leadSource = (String)so.get('Referral_Type__c');
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
            leadSource = (String)so.get('Referral_Type__c');
         } else if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            leadSource = (String)so.get('LeadSource');
         }
      } catch (Exception e) {
         System.debug('Exception in getLeadSource: '+e.getMessage()+'; '+e.getStackTraceString());
      }
      return leadSource;
   } // getLeadSource
      
   private String queryFields = null;
   
   public static String leadQueryFlds = 'LeadSource, Street, City, State, PostalCode, FirstName, LastName, Company '
                                      +',Email, Phone, MobilePhone';
   public static String ctctQueryFlds = 'Email, Phone, MobilePhone, MailingStreet, MailingCity, MailingState, MailingPostalCode '
                                      + ', Account.Id, Account.Type, Account.Name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode'
                                      + ', Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode';
   public static String acctQueryFlds = 'SignificantContact__r.Id, SignificantContact__r.Name, SignificantContact__r.Email, SignificantContact__r.Phone, SignificantContact__r.MobilePhone '
                                      + ', SignificantContact__r.MailingStreet, SignificantContact__r.MailingCity, SignificantContact__r.MailingState, SignificantContact__r.MailingPostalCode '
                                      + ', Type, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode'
                                      + ', BillingStreet, BillingCity, BillingState, BillingPostalCode, Phone';
   public static String opptyQueryFlds = 'LeadSource, Owner.Id, Owner.Sales_Org__c '
                                      + ', Account.Name, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState, Account.ShippingPostalCode'
                                      + ', Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingPostalCode'
                                      + ', (Select Id, ContactId, Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone '
                                      + ',  Contact.MailingStreet, Contact.MailingCity, Contact.MailingState, Contact.MailingPostalCode '
                                      + '     from OpportunityContactRoles Where IsPrimary=true)';
   public static String refCtctQueryFlds = 'First_Name__c, Last_Name__c, Email__c, Phone__c, Mobile_Phone__c, Referral_Type__c '
                                      + ',Referral_Account__r.Id, Referral_Account__r.Name, Referral_Account__r.Street_Address_1__c '
                                      + ',Referral_Account__r.City__c, Referral_Account__r.State_Province__c, Referral_Account__r.Zip_Postal_Code__c';
   public static String refAcctQueryFlds = 'Street_Address_1__c, City__c, State_Province__c, Zip_Postal_Code__c, Referral_Source_Business_Type__c, Referral_Type__c, Phone__c';
   
   public void checkObjectType() {
      sourceObjectName = ObjectHelper.getObjectNameFromId(objectId);
      if (sourceObjectName != null) {
         if (sourceObjectName == ObjectHelper.OBJECT_LEAD) {
            queryFields = leadQueryFlds;
         } else if (sourceObjectName == ObjectHelper.OBJECT_CONTACT) {
            queryFields = ctctQueryFlds;
         } else if (sourceObjectName == ObjectHelper.OBJECT_OPPTY) {
            queryFields = opptyQueryFlds;
         } else if (sourceObjectName == ObjectHelper.OBJECT_ACCOUNT) {
            queryFields = acctQueryFlds;
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_CONTACT) {
            queryFields = refCtctQueryFlds;
         } else if (sourceObjectName == ObjectHelper.OBJECT_REF_ACCOUNT) {
            queryFields = refAcctQueryFlds;
         } else {
            // we're not handling this type of object, so we'll clear out the sourceObjectName 
            System.debug('checkObjectType unhandled object type passed in: '+sourceObjectName);
         } 
 
         objectPrefix = ((String)objectId).subString(0,3);
      }
      System.debug('checkObjectType sourceObjectName='+sourceObjectName+' objectPrefix='+objectPrefix);
   } // checkObjectType
   
   public MeetingWrapper firstMeeting{
      get {
         MeetingWrapper meeting = (meetingList != null && !meetingList.isEmpty() ? meetingList[0] : null);
         return meeting;
      }
   } // firstMeeting
   
   public List<MeetingWrapper> meetingList{get;set;}
   
   public Task firstTask{
      get {
         Task tsk = (taskList != null && !taskList.isEmpty() ? taskList[0] : null);     
         return tsk;
      }
   } // firstTask
   
   public List<Task> taskList {get;set;}
   
   /** Were records selected? */
   public Boolean hasRecords {
      get {return (selectedRecords != null && !selectedRecords.isEmpty());}
   } // hasRecords
   
   public PageReference save() {
      SObject[] activityList = null;
      if (newObjectType == ObjectHelper.OBJECT_TASK) {
         activityList = checkTasks();
      } else if (newObjectType == ObjectHelper.OBJECT_EVENT) {
         activityList = checkEvents();
      }

      //Save all the activity.
      System.debug('activityList: '+activityList);
      if (activityList != null && !activityList.isEmpty()) {
         upsert activityList;
      }
      //redirect to the entry point, either the list page or the record you started from.
      if (inlineForm) {
         newObjectType = 'Activity Saved';
         return null;
      }      
      return cancel();
   } // save
   
   public PageReference cancel() {
      PageReference returnPage = null;
      if (entryFromListView) {
         returnPage = new PageReference('/'+ (objectPrefix != null ? objectPrefix : ''));
      } else {
         returnPage = new PageReference('/'+ (objectId != null ? objectId : ''));
      }
      
      return returnPage;        
   } // cancel

   public PageReference createAnother() {
      init();
      return null;
   } // createAnother
   /** Prepare the tasks for saving.
    */
   private SObject[] checkTasks() {
      if (useFirstActivity) {
         
         Task firstTask = null;
         for (Integer cnt=0; cnt<taskList.size(); cnt++) {
            Task tsk = taskList.get(cnt);
            if (cnt == 0) {
               firstTask = tsk;
            } else if (firstTask != null) {
                tsk.Type = firstTask.Type;
                tsk.TAP_Topic__c = firstTask.TAP_Topic__c;
                tsk.Subject = firstTask.Subject;
                tsk.Description = firstTask.Description;
                tsk.ActivityDate = firstTask.ActivityDate;
                
            }
         } // for (Integer cnt=0
      } // if (useFirstActivity
      
      // check status - set to completed if before or equal to today
      for (Task tsk : taskList) {
         if (!entryFromListView && tsk.Status != 'Completed' && tsk.ActivityDate > Date.today() && tsk.ReminderDateTime == Null) {
            tsk.IsReminderSet = true;
            // set the reminder for a task at 8am of the activity date
            tsk.ReminderDateTime = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(8,0,0,0));
         }
         if (tsk.ActivityDate <= Date.today()) {
            tsk.Status='Completed';
         }
      }
      return (SObject[])taskList;
   } // saveTasks   
   
   /** Prepare the Events for saving.
    */
   private SObject[] checkEvents() {
      Event[] eventList = new Event[]{};
      // extract the event objects from the wrapper class.
      for (MeetingWrapper mw : meetingList) {
         mw.setEventFields();
         eventList.add(mw.evnt);
      }
      if (useFirstActivity) {
         Event firstEvent = null;
         for (Integer cnt=0; cnt<eventList.size(); cnt++) {
            Event evnt = EventList.get(cnt);
            if (cnt == 0) {
               firstEvent = evnt;
            } else if (firstEvent != null) {
                evnt.Type = firstEvent.Type;
                evnt.Subject = firstEvent.Subject;
                evnt.Description = firstEvent.Description;
                evnt.ActivityDate = firstEvent.ActivityDate;
                evnt.ActivityDateTime = firstEvent.ActivityDateTime;
                evnt.DurationInMinutes = firstEvent.DurationInMinutes;
                evnt.CPE_Topic__c = firstEvent.CPE_Topic__c;
            }
         } // for (Integer cnt=0
      } // if (useFirstActivity
      
      if (!entryFromListView) {
         for (Event evt : eventList) {
            // if the event is in the future, set the reminder.
            if (evt.ActivityDate > Date.today() && evt.ReminderDateTime == Null) {
               evt.IsReminderSet = true;
               // set the reminder for 30 minutes before of the activity time
               evt.ReminderDateTime = evt.ActivityDateTime.addMinutes(-30);
            }
         }
      } 
      
      return (SObject[])eventList;
   } // saveEvents
   
} // class MassCreateActivity