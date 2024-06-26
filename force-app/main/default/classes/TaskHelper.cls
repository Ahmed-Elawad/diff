/** Methods to help with Tasks
 *
 * History
 * -------
 * 08/28/2014 Dan Carmen        Created.
   10/11/2014 Dan Carmen        Added more logic to set campaign info
   10/15/2014 Dan Carmen        Add in logic to check for ownership
   11/06/2014 Dan Carmen        Add in logic to set LeadSource
   11/19/2014 Dan Carmen        Additional logic for setting the call disposition
   02/20/2015 Dan Carmen        Callback on PO record, only process NSS tasks if owned by NSR
   03/16/2015 Dan Carmen        Change to handle opportunities created at the exact same time
   03/26/2015 Dan Carmen        Logic to not set latest campaign if was already set within a specified period of time.
   03/30/2015 Dan Carmen        Add logging if ACD name doesn't exist on a campaign.
   04/30/2015 Dan Carmen        Change day range to check for created date. Opened up the search for opportunities to base it 
                                    off of the NSS Source.
   12/23/2015 Dan Carmen        Change the trigger to look for call disposition change rather than changing to closed
   02/08/2016 Lynn Michels    Add in Task Record Type 'Service Onboarding MSP Ref Object' and create chatter post on reference online services object if task is complete
   02/29/2016 Dan Carmen        Modify some of the save routines.
   04/01/2016 Dan Carmen        Fix for NPE
   02/02/2017 Jacob Hinds       Adding in Partner Referral Tracking
   03/10/2017 Cindy Freeman     pushing acd_name from task to opty, pushing acd_name and campaign to referral if not already there
   03/22/2017 Dan Carmen         Fix for okayToSetCampaign variable usage
   03/29/2017 Dan Carmen         Added ability to search for leads/contacts/acounts on orphaned tasks
   05/25/2017 Cindy Freeman     push acd_name from task to opty even if opty already has campaign
   06/12/2017 Dan Carmen         Add logic for inbound calls to create partner referral and referral
   06/29/2017 Jacob Hinds       Added Referral First Call Attempted to linkPartnerReferral method
   07/12/2017 Jacob Hinds       Reworked Referral Virtual First Call Attempted
   07/17/2017 Dan Carmen        Simplify code for handling the call disposition (always set the disposition from the task)
   12/22/2017 Cindy Freeman      added Consent to Text fields to Lead and Contact queries
   12/27/2017 Dan Carmen        Adjust code for checking for existing partner referral
   01/16/2018 Dan Carmen        Logic to populate the Activity_Type_Value__c field
   02/08/2018 Dan Carmen        Fix to set call disposition on both contact and account (was only doing one or the other)
   03/28/2018 Sunnish Annu      Added the Chatter Post for Case when the related Task is completed.
   04/13/2018 Dan Carmen        Fix for setting the source on the partner referral.
   04/20/2018 Dan Carmen        Add in extra logging.
   07/20/2018 Dan Carmen        Fix for using the account (was using just a null value)
   08/14/2018 Dan Carmen        Adjust for recursion - check the disposition also.
   10/11/2018 Dan Carmen        Check for LatestCampaign__c being set to null.
   10/24/2018 Dan Carmen        Fix for missing field in query and Master_Partner_Referral__c
   10/31/2018 Dan Carmen        Log the Lead/Contact stage on the partner referral
   11/08/2018 Dan Carmen        Check for disposition and status on account/contact (not just disposition).
   11/19/2018 Dan Carmen        Missing NSSStatus__c field in query
   12/07/2018 Dan Carmen        Replace qbdialer__Call_Date_Time__c with CallDateTime__c
   02/12/2019 Dan Carmen        Additional Callback changes
   03/13/2019 Dan Carmen        Add change for Inbound Call - Agent
   04/19/2019 Dan Carmen        Add additional logging. Turn off logging NSSCallException
   11/25/2019 Cindy Freeman     set call Disposition on master Partner Referral
   12/02/2019 Cindy Freeman     modified verifyPartnerRef to populate Lead, Contact and Account from task
   01/08/2020 Cindy Freeman     modified evaluatePartRefDisp to take partner referral as a parameter so can also be used for master partner referrals
   03/04/2020 Dan Carmen        Add additional logging for Cadence check
   05/18/2020 Pujitha Madamanchi    modified evaluatePartRefDisp - based on custom settings, updates disposition on master PR. 
   06/01/2020 Cindy Freeman     modify checkTaskCallType to look for Regional ID Callback so dont create Partner Referral
   07/22/2020 Jermaine Stukes   Update checkForCadence to incorporate Touchpoint Update Platform Event
   12/29/2020 Dan Carmen        Add MktgId__c to queries
   03/22/2020 Brandon Vidro     Added new logic to create task orphan records for Drift chats
   04/17/2021 Dan Carmen        Fixed call to queryActivityEmailMap, removed call to it from this class. It's called from TaskOrphanCallMethods
                                      
   05/21/2021 Pujitha Madamanchi APR0112504 : Partner Referral Source for Inbound Calls  
   10/08/2021 Pujitha Madamanchi   APR0122715: Populate Reject Recycle Reason on PR.
   12/03/2021 Dan Carmen           Fix so a Task will only update a touchpoint once
   02/02/2022 Pujitha Madamanchi   Fix for DS Missed calls.
   04/11/2022 Pujitha Madamanchi   Adding code removed from Prod for Dialsource action field on task
   05/05/2023 Pujitha Madamanchi   new instance of lead/contact to make sure Stage is not rolling back
   07/15/2023 Jaipal               Added new method(updateTaskStatus) to update the Task status : APR0148811
   01/02/2024 Pujitha Madamanchi   Remove timeframe check to populate latestCampaign
   01/19/2024 Pujitha Madamanchi : Update lead query with fields needed for new PR Mapping when Weblead comes in
   03/06/2024 Dan Carmen           Fix NPE in checkAcctCtctFlds
   04/29/2024 Jermaine Stukes     Temporary update to Platform Event publishing for touchpoint refresh logic
   05/14/2024 Pratik Das         APR0159917/APR0169069: New functionality in Touchpoint to indicate action required with an accept function
 */
public without sharing class TaskHelper implements TriggerInterface2 {
 
   public static Boolean SKIP_TRIGGERS=false;
   
   // the call types of Inbound and Outbound. These should also be the Record Type Names of the DialSource Action object
   public static String CT_INBOUND='Inbound';
   public static String CT_OUTBOUND='Outbound';
   public static String CT_CALLBACK='Callback';
   public static String TASK_HELPER='Task Helper';
   public static String incomingLabel = Label.Incoming_Text;  
   public static string outgoingLabel = Label.Outgoing_Text;
   
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      
      // check what the type of the first record is
      System.debug('TaskHelper.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (recs != null && isAfter) {
         //Map<Id,DS_Denali__DialSource_Action__c> actionMap = TaskHelper.checkForDialSourceAction((Task[])recs);
         //checkTasksAfter((Task[])recs, (Map<Id,Task>)oldMap, actionMap);
         checkTasksAfter((Task[])recs, (Map<Id,Task>)oldMap);
      } // if (isAfter
   } // checkAllBeforeTrigger

   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}

   //public static void checkTasksAfter(Task[] tsks, Map<Id,Task> oldMap, Map<Id,DS_Denali__DialSource_Action__c> actionMap) {
   public static void checkTasksAfter(Task[] tsks, Map<Id,Task> oldMap) {
      TaskHelper.getNSSTaskRecordTypeId();
      Task[] chatterTasks = new Task[]{};
   

      for (Task tsk : tsks) {
         Task oldTsk = (oldMap != null ? oldMap.get(tsk.Id) : null);
         TriggerMethods.checkInLoop('TaskAfter', tsk, oldTsk, Trigger.IsBefore, Trigger.IsAfter);
         Boolean statusChanged = ((Trigger.IsInsert || oldTsk.Status != tsk.Status) && tsk.Status == 'Completed');
         
         if (statusChanged && (tsk.RecordTypeId == mSPOnboardingTaskRtId || tsk.RecordTypeId == esrTaskRtId)) {
                                                                        
            chatterTasks.add(tsk);
         }
         
             if (tsk.RecordTypeId == nssTaskRtId || String.isNotBlank(tsk.CallDisposition) 
                        || tsk.DS_Denali__DialSource_Action__c != null
                        || tsk.Type == CT_CALLBACK
                        || (tsk.type == 'Text' && tsk.Subject == outgoingLabel && tsk.Status == 'Completed')
                        || ((tsk.Type == Label.TrackRecord_Chat || tsk.Type == Label.Drift_Task_Type) && tsk.Subject.contains(Label.Drift_Task_Subject))) {
            System.debug('checkTasksAfter meets NSS criteria: '+tsk.Subject);
            TaskHelper.checkNSSTaskFromAfterTrigger(tsk,oldTsk,(tsk.DS_Denali__DialSource_Action__c != null ? actionMap.get(tsk.DS_Denali__DialSource_Action__c) : null));
         } // if (tsk.RecordTypeId
    
      } // for (Task tsk
      
      if (!chatterTasks.isEmpty()) {
         TaskHelper.taskCompleteChatterPost(chatterTasks); 
      }
      
      checkForNSSTasksAfterToProcess();
       
   } // checkTasksAfter

   public static void checkDeletedTasks(Task[] tsks) {
      System.debug('checkDeletedTasks tsks='+tsks.size());
      //getNSSTaskRecordTypeId();
      for (Task tsk : tsks) {
         if (tsk.IsRecurrence==false && tsk.RecurrenceActivityId==null) {
            checkCallbackTask(tsk, null, true);
         }
      } // for (Task oldTsk : Trigger.old
      checkForNSSTasksAfterToProcess();
   } // checkDeletedTasks

   // static variable so can be used in both before and after trigger.
   public static Map<Id,DS_Denali__DialSource_Action__c> actionMap = null;
   
   // retrieve the DialSource Action records based on the passed in tasks (tasks should have the lookup to the action populated)   
   public static Map<Id,DS_Denali__DialSource_Action__c> checkForDialSourceAction(Task[] tsks) {
      Id[] actionIds = new Id[]{};
      for (Task tsk : tsks) {
         if (tsk.DS_Denali__DialSource_Action__c != null) {
            actionIds.add(tsk.DS_Denali__DialSource_Action__c);
         }
      } // for (Task tsk
      actionMap = null;
      if (!actionIds.isEmpty()) {
         actionMap = new Map<Id,DS_Denali__DialSource_Action__c>(
                    [Select Id
                           ,RecordType.Id
                           ,RecordType.Name
                           ,DS_Denali__Account__c
                           ,DS_Denali__Call_Campaign__c
                           ,DS_Denali__Call_Disposition__c
                           ,DS_Denali__Phone__c
                           ,DS_Denali__Contact__c
                           ,DS_Denali__Inbound_DNIS_Name__c
                           ,DS_Denali__Inbound_Queue__c
                           ,DS_Denali__Lead__c
                           ,CallCampaignOld__c
                           ,InboundCallerId__c
                           ,InboundCallerIdOld__c
                           ,InboundDNISNameOld__c
                       From DS_Denali__DialSource_Action__c
                      Where Id in :actionIds]);
      } else {
         actionMap = new Map<Id,DS_Denali__DialSource_Action__c>();
      }
      System.debug('checkForDialSourceAction actionMap='+actionMap.size());
      return actionMap;
   } // checkForDialSourceAction

   public static Id nssTaskRtId = null;
   public static Id mSPOnboardingTaskRtId = null; 
   public static Id esrTaskRtId = null;
   
   public static Boolean LOG_DATA=Label.TaskHelper_LogRecords == 'Y';
// class to hold the task information
   public class TaskWrapper {
      public TaskWrapper(Task p_tsk, User p_usr) {
         tsk = p_tsk;
         usr = p_usr;
         String whoId = (p_tsk.WhoId != null ? (String)p_tsk.WhoId : 'NoWhoId');
         if (whoId.startsWith(ObjectHelper.PREFIX_LEAD)) {
            leadId = p_tsk.WhoId;
         } else if (whoId.startsWith(ObjectHelper.PREFIX_CONTACT)) {
            ctctId = p_tsk.WhoId;
         }
         if (p_tsk.AccountId != null) {
            acctId = p_tsk.AccountId;
         }
         //callDate = p_tsk.CallDateTime__c;
         //hasId = (leadId != null || ctctId != null || acctId != null);
         if (usr != null) {
            ownerNssSource = ProspectOwnershipMethods.getNSS_Source(usr.Profile.Name);
         }
         String key = RecordTypeHelper.cleanRtName(tsk.RecordType.Name);
         RecordType__c rtSetting = RecordType__c.getInstance(key);
         partRefSource = ((rtSetting != null && String.isNotBlank(rtSetting.CallSource__c)) ? rtSetting.CallSource__c : PART_REF_SOURCE_NAME);
          lcd = (String.isNotBlank(tsk.CallDisposition) ? LeadMethods.findCallDisposition(tsk.CallDisposition,null) : null);
         // is the disposition of the task qualified to populate the first call field?
         //firstContactQualified = (String.IsNotBlank(tsk.CallDisposition) && FIRST_CONTACT_VALUES.contains(tsk.CallDisposition));
         firstContactQualified = (lcd != null && lcd.UseForFirstContact__c);
         if (LOG_DATA) {
            log = ErrorLog.logError('TaskHelper', 'LOG_DATA', 'LOG_DATA', tsk.Id, null, null, null, null, null, tsk, false, null);
         }
      } // TaskWrapper
      
      public void addToLog(String dataToAdd) {
         ErrorLog.addToDescription(log,dataToAdd);
      } // addToLog
      
      public ErrorLog__c log = null;
      
      public String ownerNssSource = null;
      
      public LeadCallDisposition__c lcd = null;
      public LeadCallDisposition__c oldLcd = null;
      public User usr = null;
      public Account acct = null;
      public Contact ctct = null;
      public Lead ld = null;
      public PartnerReferral__c partRef = null;
      public Referral__c ref = null;
      public String acdName = null;
      public String listName = null;
      
      public Boolean refFound = false;
      public Boolean oppFound = false;
      public Boolean dispositionChecked = false;
      // is the disposition of the task qualified to populate the first call field?
      public Boolean firstContactQualified = false;
      public String partRefSource = PART_REF_SOURCE_NAME;
      
      public Boolean isInbound() {
         return (tsk != null 
                   && (tsk.CallType == CT_INBOUND || tsk.CallObject == 'Inbound')
                   && tsk.Type != TYPE_AGENT_CALL);
      } // isInbound
      
      public String getName() {
         String name = null;
         if (ld != null) {
            name = ld.Name;
         } else if (ctct != null) {
            name = ctct.Name;
         } else if (acct != null) {
            name = acct.Name;
         } else {
            name = 'Inbound Marketing Lead';
         }
         return name;
      } // getName
                  
      public void setContact(Account p_acct) {
         acct = p_acct;
         Contact significant = null;
         Contact byId = null;
         for (Contact checkCtct : acct.Contacts) {
            if (significant == null && checkCtct.SignificantContact__c) {
               significant = checkCtct;
            }
            if (ctctId != null && ctctId == checkCtct.Id) {
               byId = checkCtct;
            }
         } // for (Contact checkCtct
         ctct = (byId != null ? byId : significant);
         String msg = (byId != null ? 'setContact byId '+ctct.Id : (significant != null ? 'setContact by significant '+ctct.Id : 'setContact not found by id or significant ctctId='+ctctId));
         addToLog(msg);
         if (ctct == null && acct.Contacts != null && !acct.Contacts.isEmpty()) {
            ctct = acct.Contacts[0];
            addToLog('setContact added first contact in the array id='+ctct.Id);
         }
         if (ctct != null) {
         //   okayToSetCampaign = true;
            ctctId = ctct.Id;
         //   setLatestCampaignDate(ctct.LatestCampaignDate__c);
         }
      } // setContact
      
      public void setLead(Lead p_ld) {
         ld = p_ld;
         if (ld != null) {
         //   okayToSetCampaign = true;
            leadId = ld.Id;
         //   setLatestCampaignDate(ld.LatestCampaignDate__c);
         }
      } // setLead
      
      // If the latest campaign was set outside the specified time range
    //  public Boolean okayToSetCampaign = false;
      
      public Task tsk;
      public Boolean hasId{
         get {return (leadId != null || ctctId != null || acctId != null); }
      }
      
      public Id leadId = null;
      public Id ctctId = null;
      public Id acctId = null;
      public Id campaignId = null;
      public String campaignLeadSource = null;
      public String campaignName = null;
      public string campaignSourceType = null;
      
    /*  public void setLatestCampaignDate(DateTime latestCampaignDT) {
         okayToSetCampaign = true;
         String msg = 'latestCampaignDT='+(latestCampaignDT != null ? latestCampaignDT.format('M/d/yyyy HH:mm:ss') : 'null');
         if (latestCampaignDT != null) {
            // if the date range is 0 or less, allow the campaign to be set anytime (if not null already)
            msg += ' DATE_RANGE='+DATE_RANGE;
            if (DATE_RANGE > 0) {
               Datetime campaignDT = latestCampaignDT.addHours(DATE_RANGE);
               msg += ' latestCampaignDT adjusted='+campaignDT.format('M/d/yyyy HH:mm:ss');
               msg += ' task call time='+(tsk.CallDateTime__c != null ? tsk.CallDateTime__c.format('M/d/yyyy HH:mm:ss') : 'null');
               okayToSetCampaign = campaignDT < tsk.CallDateTime__c;
            }
         } // if (latestCampaignDT != null
         msg += ' okayToSetCampaign='+okayToSetCampaign;
         addToLog(msg);
      } // setLatestCampaignDate */
      
      // if we have a master partner referral, link it here.
      public PartnerReferral__c masterPartRef = null;
      // if there's a partner referral with a different activity id
      public PartnerReferral__c partRefOtherActId = null;
      // compile all of the partner referrals relevant to this task.
      public PartnerReferral__c[] partRefs = new PartnerReferral__c[]{};
      
   } // TaskWrapper
   public static Id getNSSTaskRecordTypeId() {
      if (nssTaskRtId == null) {
         Map<String, Schema.RecordTypeInfo> taskRtMap = Task.getSobjectType().getDescribe().getRecordTypeInfosByName();
         Schema.RecordTypeInfo taskRtInfo = taskRtMap.get(Label.ISDC_Task_Name);
         nssTaskRtId = (taskRtInfo != null ? taskRtInfo.getRecordTypeId() : null);
         taskRtInfo = taskRtMap.get('MSP Onboarding Task Recordtype');
         mSPOnboardingTaskRtId = (taskRtInfo != null ? taskRtInfo.getRecordTypeId() : null);
         taskRtInfo = taskRtMap.get('ESR Task Record Type');
         esrTaskRtId = (taskRtInfo != null ? taskRtInfo.getRecordTypeId() : null);
      }
      return nssTaskRtId;
   } // getNSSTaskRecordTypeId
   

   // for testing purposes
   public static void clearVariables() {
      v_ownerIdSet.clear();
      v_callbackIdsToDelete.clear();
      v_callbackCheckForPOTaskMap.clear();
      v_checkTaskIdSet.clear();
      v_callbackLdCtctIdSet.clear();
      handledTaskIdMap.clear();
      checkForOrphanTasks.clear();
   } // clearVariables
   
   // the owner ids of the tasks
   private static set<Id> v_ownerIdSet = new set<Id>();
   
   // for callbacks, we want to reselect the accounts/contacts/leads to update the callback dates on those
   // so might not be an actual task we'll query
   public static Set<Id> v_callbackLdCtctIdSet = new Set<Id>();
   
   // when the task is deleted or callback is closed, delete the PO callback record
   public static Id[] v_callbackIdsToDelete = new Id[]{};
   // check for a PO to link the PO callback record to. Use a map to make sure record only gets in once
   private static Map<Id,Task> v_callbackCheckForPOTaskMap = new Map<Id,Task>();
   
   //create chatter post on reference online services object if task is complete
   //tasks with the 'MSP Onboarding Task Recordtype' RT that are (new or the status has changed) AND the status is 'Completed'
   public static void taskCompleteChatterPost(List<Task> taskList) {
      System.debug('taskCompleteChatterPost taskList='+taskList.size());
         
      Schema.DescribeSObjectResult r = Reference_HRO__c.SObjectType.getDescribe();
      String prefix = r.getKeyPrefix();
      String caseKeyPrefix = Case.SObjectType.getDescribe().getKeyPrefix();
                                       
                                         

      Map<ID, Task> refOnlineServicesToTaskMap = new Map<ID, Task>();
      Map<Id,Task> caseToTaskMap = new Map<Id,Task>();
                           
                           

      List<ID> usersToMention = new List<ID>();
         
      for (Task t:taskList) {  
         if (t.WhatId != null) {
            //make sure the whatid is a reference online services object id
            String WhatIdPrefix = String.valueOf(t.WhatId).substring(0,3);
            if (WhatIdPrefix == prefix) {
               refOnlineServicesToTaskMap.put(t.WhatId, t);
            }//end if
            else if(WhatIdPrefix == caseKeyPrefix) {
               caseToTaskMap.put(t.WhatId, t);
            }

         } // if (t.WhatId != null

               
                                    
                         
                      
       
                           
                      
       
                
      }//end for
      
      System.debug('taskCompleteChatterPost refOnlineServicesToTaskMap='+refOnlineServicesToTaskMap.size()+' caseToTaskMap='+caseToTaskMap.size());

      if(!refOnlineServicesToTaskMap.isEmpty() || !caseToTaskMap.isEmpty()) {

         if(!refOnlineServicesToTaskMap.isEmpty()) {
            ID serviceOnboardingMSPRefObjectRTId  = RecordTypeHelper.getRecordType('Service Onboarding MSP Ref Object', 'Reference_HRO__c').getRecordTypeId();
            ID serviceOnboardingMSPAddOnModuleRefObjectRTId  = RecordTypeHelper.getRecordType('Service Onboarding MSP Add On Module Ref Object', 'Reference_HRO__c').getRecordTypeId();
            Set<ID> RefObjectRTIds = new Set<ID>{serviceOnboardingMSPRefObjectRTId, serviceOnboardingMSPAddOnModuleRefObjectRTId};
     
            List<Reference_HRO__c> refObjectList = [SELECT Id, OwnerId, RecordTypeId FROM Reference_HRO__c
                                          WHERE Id IN:refOnlineServicesToTaskMap.keySet() 
                                          AND RecordTypeId IN: RefObjectRTIds];
            for(Reference_HRO__c ref:refObjectList) {
               usersToMention.add(ref.OwnerId);
               String postText = 'Task "' +refOnlineServicesToTaskMap.get(ref.Id).Subject+ '" has been completed.';
               System.debug('taskCompleteChatterPost 1 '+postText);
               chatterMentionPost.createChatterMentionPost(ref.id, usersToMention, postText);
            }//end for
         } // if(!refOnlineServicesToTaskMap
         if(!caseToTaskMap.isEmpty()){
            List<Case> caseList = [SELECT Id, OwnerId FROM Case WHERE Id IN :caseToTaskMap.keySet()];
            for(Case c : caseList) {
               usersToMention.add(c.OwnerId);
               String postText = 'Task "' +caseToTaskMap.get(c.Id).Subject+ '" has been completed.';
               System.debug('taskCompleteChatterPost 2 '+postText);
               chatterMentionPost.createChatterMentionPost(c.id, usersToMention, postText);
            } // for(Case c : caseList
         }

                   
                                
                                    
                                      
                                                  
                                
                                        
      
                  
                       
                                                              
                                   
                              
                                               
        
      
   
                   
                                    
                                   
                                         
                                             
                      
                        
                                                              
                                    
                                 
                                                
        
      
         //this will post all of the chatter messages submitted - in case it is a bulk transaction, otherwise you'd run in to limit issues.
         ChatterMentionPost.checkPostFeedElements();
      }//end if
   }//end taskCompleteChatterPost

   public static void checkNSSTasksFromBeforeTrigger(Task[] tsks, Map<Id,Task> oldMap) {
      getNSSTaskRecordTypeId();
      Task[] checkActionTasks = new Task[]{};
      List<Task> taskList = new List<Task>();
      for (Task tsk : tsks) {
         Task oldTsk = ((oldMap != null && tsk.Id != null) ? oldMap.get(tsk.Id) : null);

         // set the Referral Contact lookup
         String relatedTo = (String)tsk.WhatId;
         if (relatedTo != null && relatedTo.left(3)=='a07' && (tsk.Referral_Contact__c == null || tsk.Referral_Contact__c != tsk.WhatId)) {
            tsk.Referral_Contact__c = tsk.WhatId;   
         }

         //System.debug('checkNSSTasksFromBeforeTrigger 1 tsk='+tsk.Subject+' type='+tsk.Type+' callback='+(tsk.Subject.toUpperCase().contains('CALLBACK')));
         // if we use "Callback" in the subject, check here to set the Type = Callback
         if (String.isBlank(tsk.Type) && String.isNotBlank(tsk.Subject) && tsk.Subject.toUpperCase().contains('CALLBACK')) {
            setCallback(tsk);
         } // if (String.isBlank
         
         // if the record type is nss, and it's future dated (either from activity date or reminder time) then we'll set as Callback
         if (String.isBlank(tsk.Type) && tsk.RecordTypeId == nssTaskRtId 
                        && (tsk.ActivityDate > Date.today() 
                                  || (tsk.ReminderDateTime != null && tsk.ReminderDateTime > Datetime.now().addMinutes(30)))) {
            setCallback(tsk);
         }

         System.debug('checkNSSTasksFromBeforeTrigger 2 tsk='+tsk.Subject+' type='+tsk.Type);

         Boolean callResultChanged = (oldTsk != null && tsk.CallDisposition != oldTsk.CallDisposition);

         // set the Inbound or Outbound values (if not already set)
         // if linked to a denali action, always retrieve the denalit action to use later.
         //if (tsk.DS_Denali__DialSource_Action__c != null && (String.isBlank(tsk.CallType) || callResultChanged)) {
         if (tsk.DS_Denali__DialSource_Action__c != null) {
            checkActionTasks.add(tsk);
         }
         if(tsk.Subject== incomingLabel || tsk.Subject == outgoingLabel){  
          taskList.add(tsk);  
         }
                         
                                
                   
                          
      
         checkNSSTaskFromBeforeTrigger(tsk, oldTsk);
      } // for (Task tsk : tsks

      // set the call type field on the tasks so we can use it as a trigger point later
      // always call this. This will initialize the actionMap variable even if there are no DialSource tasks.
      checkActionOnTasks(checkActionTasks);
       if(!taskList.isEmpty()){  
         updateTaskStatus(taskList);  
}
   } // checkNSSTasksFromBeforeTrigger
   
   public static final Integer TASK_SUBJECT_SIZE = Task.Subject.getDescribe().getLength();
   
   public static void setCallback(Task tsk) {
      tsk.Type = CT_CALLBACK;
      String subject = '';
      if (String.isBlank(tsk.Subject)) {
         subject = 'Callback';
      } else if (!tsk.Subject.contains('Callback') || !tsk.Subject.contains('CB')) {
         subject = 'Callback-'+tsk.Subject;
      }
      if (String.isNotBlank(subject)) {
         tsk.Subject = subject.left(TASK_SUBJECT_SIZE);
      }
      // default the reminder to 8 am on the day of the future
      if (tsk.ActivityDate > Date.today() && tsk.ReminderDateTime == null) {
         tsk.ReminderDateTime = Datetime.newInstance(tsk.ActivityDate, Time.newInstance(8,0,0,0));
         tsk.IsReminderSet = true;
      }
   } // setCallback
   
   // the valid values for the CallType picklist on the Task - this is a restricted picklist controlled by the CTI plugin
   public static Set<String> VALID_CALLTYPE_SET = new Set<String>{CT_INBOUND,CT_OUTBOUND};
   
   // use the DialSource Action record to set the call type field on the Task
   public static void checkActionOnTasks(Task[] checkCallTypeTasks) {
      //Map<Id,DS_Denali__DialSource_Action__c> actionMap = checkForDialSourceAction(checkCallTypeTasks);
      checkForDialSourceAction(checkCallTypeTasks);
      for (Task tsk : checkCallTypeTasks) {
         DS_Denali__DialSource_Action__c action = actionMap.get(tsk.DS_Denali__DialSource_Action__c);
         checkTaskCallType(tsk, (action != null ? action.RecordType.Name : null), (action != null ? action.DS_Denali__Inbound_DNIS_Name__c : null));
         /*
         if (action != null && action.RecordType != null && VALID_CALLTYPE_SET.contains(action.RecordType.Name)) {
            if (tsk.CallType != action.RecordType.Name) {
               tsk.CallType = action.RecordType.Name;
               tsk.CallObject = action.RecordType.Name;
            }
            if (action.RecordType.Name == CT_INBOUND && tsk.Type != 'Inbound Call') {
               tsk.Type = 'Inbound Call';
            } else if (action.RecordType.name == CT_OUTBOUND && tsk.Type != 'Call') {
               tsk.Type = 'Call';
            }
         } // if (action != null
         */
      } // for (Task tsk : checkCallTypeTasks
   } // checkActionOnTasks
   
   public static String TYPE_INBOUND_CALL='Inbound Call';
   public static String TYPE_AGENT_CALL='Inbound Call - Agent';

   public static Boolean checkTaskCallType(Task tsk, String dsRecordTypeName, String inboundDNIS) {
      Boolean changed = false;
      System.debug('checkTaskCallType tsk='+(tsk != null) +' dsRecordTypeName='+dsRecordTypeName);
      if (tsk != null && String.isNotBlank(dsRecordTypeName) && VALID_CALLTYPE_SET.contains(dsRecordTypeName)) {
         if (tsk.CallType != dsRecordTypeName) {
            tsk.CallType = dsRecordTypeName;
            tsk.CallObject = dsRecordTypeName;
            changed = true;
         }
         if (dsRecordTypeName == CT_INBOUND) {
            String checkType = TYPE_INBOUND_CALL;
            if (String.isNotBlank(inboundDNIS) && (inboundDNIS.startsWith('Agent') || inboundDNIS == 'Regional ID Callback')) {
               checkType = TYPE_AGENT_CALL;
            }
            if (tsk.Type != checkType) {
               tsk.Type = checkType;
               changed = true;
            }
         } else if (dsRecordTypeName == CT_OUTBOUND && tsk.Type != 'Call') {
            tsk.Type = 'Call';
            changed = true;
         }
      } // if (action != null
      return changed;
   } // checkTaskCallType

   public static void checkNSSTaskFromBeforeTrigger(Task tsk, Task oldTsk) {
      if (tsk.DS_Denali__DialSource_Action__c != null && tsk.CallDateTime__c == null) {
         // default the time for DialSource tasks (they should be created immediately)
         tsk.CallDateTime__c = Datetime.now();
      }
      
      if (tsk.ActivityDate == null && !tsk.IsRecurrence && tsk.ReminderDateTime != null) {
         tsk.ActivityDate = tsk.ReminderDateTime.date();
      }

      if (tsk.CallDateTime__c != null && (tsk.CallHour__c == null || (oldTsk != null && tsk.CallDateTime__c != oldTsk.CallDateTime__c))) {
         // get the hour in EST
         tsk.CallHour__c = tsk.CallDateTime__c.format(Label.CallTime_format,Label.CallTime_TimeZone);
      } // if (CallDateTime__c != null
      
      if (oldTsk != null && String.isNotBlank(tsk.Activity_Source__c) && tsk.Activity_Source__c == Label.Task_Check_Callback
          && tsk.Type == CT_CALLBACK) {
         // clear this out - it was a triggering action for this trigger.
         tsk.Activity_Source__c = null;
         v_callbackCheckForPOTaskMap.put(tsk.Id, tsk);
      }
      // put logic from workflow into the before trigger - workflow was causing issues with the extra updates. 
      // There were some issues reporting from the Type field, so they are using the Activity Type Value field instead.
      if (String.isNotBlank(tsk.Type)) {
         tsk.Activity_Type_Value__c = tsk.Type;
      }

   } // checkNSSTaskFromBeforeTrigger

   // log the orphan calls that come in (not attached to anything)
   private static TaskOrphanCall__c[] orphanCalls = new TaskOrphanCall__c[]{};
   
   public static Set<Id> v_checkTaskIdSet = new Set<Id>();
   
   // query the tasks that are callbacks
   public static Set<Id> v_callbackTaskIdSet = new Set<Id>();
   
   public static Map<Id,String> handledTaskIdMap = new Map<Id,String>();
   public static Map<Id,String> taskIdToCallTypeMap = new Map<Id,String>();
   
   public static String NO_DISP='NO_DISPOSITION';
   public static String NO_CALLTYPE='NO_CALLTYPE';
   
   public static final Integer TASK_NAME_SIZE = TaskOrphanCall__c.Name.getDescribe().getLength();
   
   public static Task[] checkForOrphanTasks = new Task[]{};
   
   public static String getInboundCalledId(Task tsk, DS_Denali__DialSource_Action__c action) {
      String inboundCallerId = (action != null && action.InboundCallerId__c != null ? action.InboundCallerId__c : null);
      return inboundCallerId;
   }
   
   public static String getAcdName(Task tsk, DS_Denali__DialSource_Action__c action) {
      String acdName = (action != null && String.isNotBlank(action.DS_Denali__Inbound_DNIS_Name__c) ? action.DS_Denali__Inbound_DNIS_Name__c : null);
      return acdName;
   } // getAcdName
   
   public static String getListName(Task tsk, DS_Denali__DialSource_Action__c action) {
      String listName = (action != null && String.isNotBlank(action.DS_Denali__Call_Campaign__c) ? action.DS_Denali__Call_Campaign__c : null);
      return listName;
   } // getListName
    
   public static void checkNSSTaskFromAfterTrigger(Task tsk, Task oldTsk, DS_Denali__DialSource_Action__c action) {
      String disposition = String.IsNotBlank(tsk.CallDisposition) ? tsk.CallDisposition : NO_DISP;
      String checkDisp = handledTaskIdMap.get(tsk.Id);
      String callType = String.IsNotBlank(tsk.CallType) ? tsk.CallType: NO_CALLTYPE;
      String checkCallType = taskIdToCallTypeMap.get(tsk.Id);

      // this is to handle previously orphaned tasks being linked up 
      Boolean recIdsChanged = (oldTsk == null || (oldTsk != null && (tsk.WhoId != oldTsk.WhoId
                                                                     || tsk.WhatId != oldTsk.WhatId
                                                                     || tsk.AccountId != oldTsk.AccountId)));
                                                                     

      // make sure we only re-enter the trigger if the disposition changes mid-trigger. 
      // Not sure if this would happen
      if (!recIdsChanged && ((String.isNotBlank(checkDisp) && checkDisp == disposition) && (String.isNotBlank(checkCallType) && checkCallType == callType))) {
         System.debug('checkNSSTaskFromAfterTrigger reentered with same disposition! '+disposition +' or CallType! '+callType);
         return;
      }
      
      handledTaskIdMap.put(tsk.Id, disposition);
      taskIdToCallTypeMap.put(tsk.Id, CallType);
      // was it previously orphaned
      // if it was, we will want to update the orphan record later.
      Boolean previousOrphan = (oldTsk != null && oldTsk.WhoId == null && oldTsk.WhatId == null && oldTsk.AccountId == null);
      
      String inboundCallerId = getInboundCalledId(tsk, action);
      String acdName = getAcdName(tsk, action);
      String listName = getListName(tsk, action);
      Boolean callerIdChanged = (String.isNotBlank(inboundCallerId) 
                            && (oldTsk == null || (action != null && action.InboundCallerId__c != action.InboundCallerIdOld__c)));  
      Boolean acdChanged = (String.isNotBlank(acdName) 
                            && (oldTsk == null || (action != null && action.DS_Denali__Inbound_DNIS_Name__c != action.InboundDNISNameOld__c)));
      Boolean listChanged = (String.isNotBlank(listName) 
                            && (oldTsk == null || (action != null && action.DS_Denali__Call_Campaign__c != action.CallCampaignOld__c )));
      System.debug('checkNSSTaskFromAfterTrigger acdName='+acdName+' listName='+listName+' inboundCallerId='+inboundCallerId);
      Boolean taskHandled = false;
      // always log inbound calls with an acd name
      if ((tsk.CallType == CT_INBOUND || (inboundCallerId != null && String.isNotBlank(acdName))) ||tsk.Type == 'Text') {
         System.debug('checkNSSTaskFromAfterTrigger add to list '+tsk.Subject);
         v_ownerIdSet.add(tsk.OwnerId);
         v_checkTaskIdSet.add(tsk.Id);
         taskHandled = true;
      }
      
      system.debug('jsh tskHandled'+taskHandled);
      
      if (!taskHandled && (tsk.WhoId != null || tsk.WhatId != null || tsk.AccountId != null)) {
         // check if any of these field is not blank
         if (String.isNotBlank(acdName) || String.isNotBlank(listName) 
                                || (String.isNotBlank(tsk.CallDisposition) && tsk.CallDisposition != 'null')
                               ) {
            if (oldTsk == null
                 || (oldTsk != null && (acdChanged || listChanged || tsk.CallDisposition != oldTsk.CallDisposition))) {
               System.debug('checkNSSTaskFromAfterTrigger added task to v_checkTaskIdSet');
               v_checkTaskIdSet.add(tsk.Id);
               v_ownerIdSet.add(tsk.OwnerId);
               taskHandled = true;
            } // if (oldTsk == null
         } // if (String.isNotBlank(tsk.isdc_acd_name__c

      } // if (tsk.WhoId != null || tsk.WhatId != null || tsk.AccountId != null

      // TODO - need to add callback info for DialSource callbacks
      // handle callbacks
      checkCallbackTask(tsk,oldTsk, false);
      
      // send the previousOrphan through to update the orphan record
      if (previousOrphan || (tsk.WhoId == null && tsk.WhatId == null && tsk.AccountId == null)) {
         System.debug('checkNSSTaskFromAfterTrigger callType='+tsk.CallType);
         if (tsk.CallType == CT_INBOUND && action != null && action.InboundCallerId__c != null) {
            createOrphanRecord(tsk,action.InboundCallerId__c);
         }
      } // if (tsk.WhoId == null && tsk.WhatId == null
      if (tsk.Subject == Label.Drift_Task_Subject && (tsk.Type == Label.TrackRecord_Chat || tsk.Type == Label.Drift_Task_Type)) {
          createOrphanRecord(tsk, null);
      }
      
   } // checkNSSTaskFromAfterTrigger
   
   
   public static void checkCallbackTask(Task tsk, Task oldTsk, Boolean isDeleted) {
      // if anything happens on a callback we'll requery the related record(s)
      if (tsk.Type == CT_CALLBACK) {
         // if there's an associated account/contact/lead, we want to update the next call time
         // pull out any Id that exists to query with
         if (tsk.AccountId != null) {
            v_callbackLdCtctIdSet.add(tsk.AccountId);
         } 
         if (tsk.WhoId != null) {
            v_callbackLdCtctIdSet.add(tsk.WhoId);
         } 
         if (tsk.WhatId != null) {
            v_callbackLdCtctIdSet.add(tsk.WhatId);
         } 
                  
         // always requery tasks for callbacks - TODO - this 
         //v_callbackTaskIdSet.add(tsk.Id);
         
         // TODO - this will go away when ISDC goes away
         // if changes to closed, look by id to delete
         if (isDeleted || (oldTsk != null && !oldTsk.IsClosed && tsk.IsClosed)) {
            v_callbackIdsToDelete.add(tsk.Id);
         } else if (!tsk.IsClosed && tsk.ReminderDateTime != null) {
            // process for all callbacks
            v_callbackCheckForPOTaskMap.put(tsk.Id,tsk);
         }
         System.debug('checkCallbackTask v_callbackLdCtctIdSet='+v_callbackLdCtctIdSet.size()+' v_callbackIdsToDelete='+v_callbackIdsToDelete.size()+' v_callbackCheckForPOTaskMap='+v_callbackCheckForPOTaskMap.size());
      } // if (tsk.qbdialer__Callback_Date_Time__c != null
   } // checkCallbackTask 
   
   public static TaskOrphanCall__c createOrphanRecord(Task tsk, String phoneNumber) {
      // if it was previously not matched but now it is, update the id
      Id matchId = (tsk.WhoId != null ? tsk.WhoId : tsk.WhatId != null ? tsk.WhatId : null);
      TaskOrphanCall__c orphanCall = new TaskOrphanCall__c(TaskId__c=tsk.Id, CallDisposition__c=tsk.CallDisposition);
      if (phoneNumber != null) {
         orphanCall.Phone__c = phoneNumber;
      }
      if (tsk.Subject.contains(Label.Drift_Task_Subject)) {
          orphanCall.Drift_Activity__c = true;
      }
      orphanCall.CallDateTime__c = tsk.CallDateTime__c;
      orphanCall.Name = String.isNotBlank(tsk.Subject) ? tsk.Subject.left(TASK_NAME_SIZE) : 'Orphan Call';
      // For DialSource, subject should be "Denali Missed Call"
      orphanCall.MissedCall__c = (String.isNotBlank(tsk.Subject) && tsk.Subject.contains('Missed Call'));
      if (matchId != null) {
         orphanCall.MatchId__c = matchId;
      } 
      orphanCalls.add(orphanCall);
      return orphanCall;
   } // createOrphanRecord
   
   public static Boolean SKIP_FUTURE=(Label.TaskHelper_SkipFuture=='Y');
   public static Boolean SKIP_PO_FUTURE=(Label.TaskHelper_SkipPOFuture=='Y');
   
   public static void checkForNSSTasksAfterToProcess() {
      System.debug('checkForNSSTasksAfterToProcess orphanCalls='+orphanCalls.size()+' v_checkTaskIdSet='+v_checkTaskIdSet.size()+' v_ownerIdSet='+v_ownerIdSet.size()+' v_callbackCheckForPOTaskMap='+v_callbackCheckForPOTaskMap.size());
      
      if (!orphanCalls.isEmpty()) {
         Database.upsert(orphanCalls,TaskOrphanCall__c.Fields.TaskId__c, false);
         //DmlHelper.performDML(orphanCalls, DmlHelper.DML_INSERT, 'TaskHelper', 'checkForNSSTasksAfterToProcess', 'insert orphanCalls', true);
         orphanCalls.clear();
      }
      
      // update the prospect-ownership prospect record with callback info
      if (!v_callbackCheckForPOTaskMap.isEmpty()) {
         if (SKIP_PO_FUTURE || System.isBatch() || System.isFuture() || System.isQueueable()) {
            setPOCallbacks(v_callbackCheckForPOTaskMap.values());
         } else {
            // because the map is cleared in the course of the trigger. 
            Set<Id> tskIdSet = new Set<Id>();
            tskIdSet.addAll(v_callbackCheckForPOTaskMap.keySet());
            setPOCallbacksFuture(tskIdSet);
         }
      }

      System.debug('checkForNSSTasksAfterToProcess callbackIdsToDelete='+v_callbackIdsToDelete+' number v_callbackCheckForPOTaskMap='+v_callbackCheckForPOTaskMap.size()+' v_callbackLdCtctIdSet='+v_callbackLdCtctIdSet.size());

      if (!v_callbackIdsToDelete.isEmpty()) {
         deletePOCallbacks(v_callbackIdsToDelete);
      }

      // as long as there's something in the ownerIdSet there are records to process
      if (!v_checkTaskIdSet.isEmpty() || !v_callbackLdCtctIdSet.isEmpty()) {
         if (SKIP_FUTURE || Test.isRunningTest() || System.isBatch() || System.isFuture() || System.isQueueable()) {
            handleTaskTriggerNow(v_checkTaskIdSet, v_ownerIdSet, v_callbackLdCtctIdSet);
         } else {
            handleTaskTriggerFuture(v_checkTaskIdSet, v_ownerIdSet, v_callbackLdCtctIdSet);
         }
      } // if (!ownerIdSet.isEmpty

      v_checkTaskIdSet.clear();
      v_ownerIdSet.clear();
   } // checkForNSSTasksAfterToProcess
   
   @future
   private static void handleTaskTriggerFuture(Set<Id> checkTaskIdSet, Set<Id> ownerIdSet, Set<Id> callbackLdCtctIdSet) {
      handleTaskTriggerNow(checkTaskIdSet, ownerIdSet, callbackLdCtctIdSet);
   } // handleTaskTriggerFuture

   private static void handleTaskTriggerNow(Set<Id> checkTaskIdSet, Set<Id> ownerIdSet, Set<Id> callbackLdCtctIdSet) {
      String logInfo = ('checkTaskIdSet='+(checkTaskIdSet != null ? checkTaskIdSet.size() : -1)+' ownerIdSet='+(ownerIdSet != null ? ownerIdSet.size() : -1)+' callbackLdCtctIdSet='+(callbackLdCtctIdSet != null ? callbackLdCtctIdSet.size() : -1));
      Id[] taskIds = new Id[]{};
      if (checkTaskIdSet != null) {
         taskIds.addAll(checkTaskIdSet);
      }
      Id logTaskId = (!taskIds.IsEmpty() ? taskIds[0] : null);
      logInfo += ' logTaskId='+logTaskId;
      try {
         System.debug('handleTaskTriggerNow '+logInfo);
         Map<Id, TaskWrapper> taskByLdCtctIdMap = new Map<Id, TaskWrapper>();
         Map<Id, TaskWrapper[]> taskByAcctIdMap = new Map<Id, TaskWrapper[]>();
         Map<Id, TaskWrapper> taskByIdMap = new Map<Id, TaskWrapper>();
         TaskWrapper[] checkForCadenceWraps = new TaskWrapper[]{};
         
         logInfo +=' \nbefore initializeSaveRecords';
         initializeSaveRecords();
         logInfo +=' \nafter initializeSaveRecords';

         // retrieve the tasks and associated campaigns, leads, and contacts
         getTaskMap(checkTaskIdSet, ownerIdSet, callbackLdCtctIdSet, taskByIdMap, taskByLdCtctIdMap, taskByAcctIdMap, checkForCadenceWraps);
         logInfo +=' \nafter getTaskMap';

         PartnerReferral__c[] insertPartRefs = new PartnerReferral__c[]{};

         // check for existing partner referrals, referrals, and opportunities
         checkForExistingRecords(taskByLdCtctIdMap, taskByIdMap, taskByAcctIdMap, insertPartRefs);
         logInfo +=' \nafter checkForExistingRecords';
         
         // for remaining inbound tasks, create associated records
         checkInboundTasks(taskByIdMap, insertPartRefs);
         logInfo +=' \nafter checkInboundTasks checkForCadenceWraps='+checkForCadenceWraps.size();
         if (!checkForCadenceWraps.isEmpty()) {
            checkForCadence(checkForCadenceWraps);
         }
         checkForSave();
         logInfo +=' \nafter checkForSave';
         
      } catch (Exception e) {
         String errorDesc = e.getMessage()+': '+e.getStackTraceString()+' \n'+logInfo;
         
         ErrorLog.logError('TaskHelper', 'handleTaskTriggerNow', 'General Exception', logTaskId, errorDesc, null, true);
      }
      clearVariables();
   } // handleTaskTriggerNow

   private static CampaignMember[] newCampaignMembers = new CampaignMember[]{};
   private static Map<Id,Lead> updateLeadMap = new Map<Id,Lead>();
   private static Map<Id,Contact> updateContactMap = new Map<Id,Contact>();
   private static Map<Id,Account> updateAcctMap = new Map<Id,Account>();
   private static Map<Id,Referral__c> updateRefMap = new Map<Id, Referral__c>();
   private static Map<Id,PartnerReferral__c> updatePartRefMap = new Map<Id, PartnerReferral__c>();
   private static Map<Id,Opportunity> updateOppMap = new Map<Id,Opportunity>();
   private static Map<Id,Task> updateTskMap = new Map<Id,Task>();
   
   public static void initializeSaveRecords() {
      newCampaignMembers.clear();
      updateLeadMap.clear();
      updateContactMap.clear();
      updateAcctMap.clear();
      updateRefMap.clear();
      updatePartRefMap.clear();
      updateOppMap.clear();
      updateTskMap.clear();
   } // initializeSaveRecords
   
   public static void checkForSave() {
      TriggerMethods.clearVariables();
      LeadMethods.LEAD_BEFORE_EXECUTING = false;
      LeadMethods.LEAD_AFTER_EXECUTING = false;
      System.debug('checkForSave DG_LMF_Service.idsProcessedSet='+DG_LMF_Service.idsProcessedSet.size());
      DG_LMF_Service.idsProcessedSet.clear();
      performUpdate(updateLeadMap.values(), 'checkForSave', 'update updateLeadMap');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;

      if (!updateAcctMap.isEmpty()) {
         handleAccountSave();
      }
      performUpdate(updateContactMap.values(), 'checkForSave', 'update updateContactMap');
      performUpdate(updateRefMap.values(), 'checkForSave', 'update updateRefMap');
      performUpdate(updatePartRefMap.values(), 'checkForSave', 'update updatePartRefMap');
      performUpdate(updateOppMap.values(), 'checkForSave', 'update updateOppMap');
      saveCampaignMembers(newCampaignMembers);
      if (!updateTskMap.isEmpty()) {
         SKIP_TRIGGERS=true;
         performUpdate(updateTskMap.values(), 'checkForSave', 'update tasks');
      }
      ErrorLog.checkSave();
   } // checkForSave
   
   // handle ownership rules here
   public static void handleAccountSave() {
      // we need to be able to translate the record type names
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      RecordTypeHelper.getRecordTypesMap(ObjectHelper.OBJECT_ACCOUNT, byId, null);

      // get the existing account team members
      Map<Id,List<AccountTeamMember>> atmListMap = ReferralQueries.getAtmListMap(updateAcctMap.keySet());
      // get the ownership records
      Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(updateAcctMap.keySet(),true,null, null);
      ProspectOwnershipMethods.initializeSaveObjects();
      
      User runningUser = UserHelper.getRunningUser();

      for (Account acct : updateAcctMap.values()) {
         LeadCallDisposition__c lcd = LeadMethods.findCallDisposition(acct.NSSCallDisposition__c, acct.NSSStatus__c);
         Schema.RecordTypeInfo rt = byId.get(acct.RecordTypeId);

         User dialedUser = runningUser;
         
         if (String.isNotBlank(acct.DialedUserId__c)) {
            User checkUser = AccountMethods.userMap.get((Id)acct.DialedUserId__c);
            if (checkUser != null) {
               dialedUser = checkUser;
            }
         } // if (String

         // make sure the id isn't already in the set - otherwise we can get a recursive call
         Contact significantContact = (acct.SignificantContact__c != null ? updateContactMap.get(acct.SignificantContact__c) : null);
         AccountMethods.handleCallDispositionChange(lcd,acct,significantContact,null,atmListMap.get(acct.Id),(rt != null ? rt.getName() : null),acctOwnerMap.get(acct.Id),dialedUser);
      } // for (Account acct
      
      // don't save accounts or contacts right here
      ProspectOwnershipMethods.saveAcctMap.clear();
      ProspectOwnershipMethods.saveCtctMap.clear();
      
      ProspectOwnershipMethods.checkForSaves();

      ZipCheckOwner.SKIP_TRIGGERS=true;
      performUpdate(updateAcctMap.values(), 'handleAccountSave', 'update updateAcctMap');
   } // handleAccountSave
   
   // Task comes in with an inbound phone number
   // look for an existing partner referral - if it exists, and resulted from opportunity creation, reuse.
   // if it exists, and resulted from another task (based on activity id), create a linked partner referral but not referral
   // if none exists, create both partner referral and referral.
   
   // check for existing partner referrals, referrals, and opportunities and update them.
   public static void checkForExistingRecords(Map<Id, TaskWrapper> taskByLdCtctIdMap, Map<Id, TaskWrapper> taskByIdMap, Map<Id, TaskWrapper[]> taskByAcctIdMap, PartnerReferral__c[] insertPartRefs) {

      ReferralTriggerActions.SKIP_TRIGGER = true;
      System.debug('checkForExistingRecords 1 taskByLdCtctIdMap='+taskByLdCtctIdMap.size());
      checkExistingPartnerReferrals(taskByLdCtctIdMap, taskByAcctIdMap, taskByIdMap, insertPartRefs);
      System.debug('checkForExistingRecords 2 taskByLdCtctIdMap='+taskByLdCtctIdMap.size());
      checkExistingReferrals(taskByLdCtctIdMap, taskByAcctIdMap, taskByIdMap);
      System.debug('checkForExistingRecords 3 taskByLdCtctIdMap='+taskByLdCtctIdMap.size());
      checkExistingOpportunities(taskByLdCtctIdMap, taskByAcctIdMap, taskByIdMap);
      System.debug('checkForExistingRecords 4 taskByLdCtctIdMap='+taskByLdCtctIdMap.size());
   } // checkForExistingRecords
   
   public static String PART_REF_SOURCE_NAME=Label.TaskHelperInboundSource;
   
   public static void checkInboundTasks(Map<Id, TaskWrapper> taskByIdMap, PartnerReferral__c[] insertPartRefs) {
      
      TaskWrapper[] inboundTasks = new TaskWrapper[]{};

      for (TaskWrapper tskWrap : taskByIdMap.values()) {
         if (tskWrap.isInbound() && tskWrap.partRef == null) {
            inboundTasks.add(tskWrap);
            createPartnerReferral(tskWrap, insertPartRefs);
         }
      } // for (TaskWrapper tskWrap
      
      System.debug('checkInboundTasks insertPartRefs='+insertPartRefs.size());
      
      if (!insertPartRefs.isEmpty()) {
         DmlHelper.performDml2(insertPartRefs, DmlHelper.DML_INSERT, 'TaskHelper', 'checkInboundTasks', 'Insert Partner Referrals', false);
         
         // requery to get the name field of the partner referral
         Map<Id, PartnerReferral__c> partRefQueryMap = new Map<Id,PartnerReferral__c>([Select Id, Name, ProcessNotes__c, Referral__c,
                                                            Contact__c, Lead__c,                      
                                                            Reject_Recycle_Date__c, Reject_Reason__c, Recycle_Reason__c 
                                                         from PartnerReferral__c
                                                         Where Id in :insertPartRefs]);

         Referral__c[] insertRefs = new Referral__c[]{};
         for (TaskWrapper tskWrap : inboundTasks) {
            if (tskWrap.partRef != null && tskWrap.partRef.Id != null && tskWrap.hasId) {
               PartnerReferral__c queryPartRef = partRefQueryMap.get(tskWrap.partRef.Id);
               tskWrap.ref = new Referral__c(Name=tskWrap.getName(), PartnerReferral__c=tskWrap.partRef.Id, OwnerId=tskWrap.tsk.OwnerId);
               tskWrap.ref.Account__c = tskWrap.partRef.Account__c;
               tskWrap.ref.NbrOfEmployees__c = tskWrap.partRef.NumberOfEmployees__c;
               tskWrap.ref.Campaign__c = tskWrap.partRef.Campaign__c;
               tskWrap.ref.SourceContact__c = tskWrap.partRef.Contact__c;
               tskWrap.ref.SourceLead__c = tskWrap.partRef.Lead__c;
         
               tskWrap.ref.ReferralEntry__c = tskWrap.partRef.Source__c;
               tskWrap.ref.SellingLeadSource__c = tskWrap.partRef.LeadSource__c; 
               tskWrap.ref.User__c = tskWrap.tsk.OwnerId;
               tskWrap.ref.acd_name__c = tskWrap.acdName;
               tskWrap.ref.CallListName__c = tskWrap.listName;
               tskWrap.ref.ActivityId__c = tskWrap.tsk.Id;
               
               tskWrap.ref.Referral_Id__c = (queryPartRef != null ? queryPartRef.Name : null);
               
               insertRefs.add(tskWrap.ref);
            }
         } // for (TaskWrapper tskWrap : allLdCtctIdMap.values
         
         DmlHelper.performDml2(insertRefs, DmlHelper.DML_INSERT, 'TaskHelper', 'checkInboundTasks', 'Insert Referrals', false);
         
         // update the referral lookup on the partner referral
         for (TaskWrapper tskWrap : inboundTasks) {
            if (tskWrap.partRef != null && tskWrap.partRef.Id != null && tskWrap.ref != null && tskWrap.ref.Id != null) {
               tskWrap.partRef.Referral__c = tskWrap.ref.Id;
               // verify the Master_Partner_Referral__c field
               if (tskWrap.partRef.Master_Partner_Referral__c != null && tskWrap.partRef.Id == tskWrap.partRef.Master_Partner_Referral__c) {
                  tskWrap.partRef.Master_Partner_Referral__c = null;
               }
               updatePartRefMap.put(tskWrap.partRef.Id, tskWrap.partRef);
            }
         } // for (TaskWrapper tskWrap : allLdCtctIdMap.values

      } // if (!insertPartRefs.isEmpty
      
   } // checkInboundTasks
      
   // see if there are existing referrals without a partner referral
   public static void checkExistingReferrals(Map<Id, TaskWrapper> taskByLdCtctIdMap, Map<Id, TaskWrapper[]> taskByAcctIdMap, Map<Id, TaskWrapper> taskByIdMap) {
      if (taskByLdCtctIdMap.isEmpty()) {
         return;
      }
      System.debug('TaskHelper.checkExistingReferrals');
      Referral__c[] refs = [Select Id, Name, OwnerId
                                  ,acd_name__c
                                  ,CallListName__c
                                  ,Account__c, SourceContact__c, SourceLead__c 
                                  ,Campaign__c, PartnerReferral__c, ReferralNotes__c
                                  ,SellingLeadSource__c
                                  ,First_Call_Attempted__c
                                  ,CreatedDate, CreatedById
                                  ,PartnerReferral__r.Id
                                  ,PartnerReferral__r.Account__c
                                  ,PartnerReferral__r.Contact__c
                                  ,PartnerReferral__r.Lead__c
                                  ,PartnerReferral__r.Referral__c
                                  ,PartnerReferral__r.First_Call_Attempted__c
                                  ,PartnerReferral__r.First_Contact_Made__c
                                  ,Selling_Opportunity__r.Id
                                  ,Selling_Opportunity__r.Name
                                  ,Selling_Opportunity__r.Campaign__c
                                  ,Selling_Opportunity__r.CampaignActivityId__c
                                  ,Selling_Opportunity__r.LeadSource
                                  ,Selling_Opportunity__r.NSS_Source__c
                                  ,Selling_Opportunity__r.Qualified_Type__c
                                  ,Selling_Opportunity__r.ReferralLookup__c
                                  ,Selling_Opportunity__r.ACD_Name__c
                            From Referral__c
                            Where (SourceContact__c in :taskByLdCtctIdMap.keySet()
                                   or SourceLead__c in :taskByLdCtctIdMap.keySet()
                                   or Account__c in :taskByAcctIdMap.keySet())
                              and CreatedDate >= :callDates.startDate];
      System.debug('checkExistingReferrals existing refs='+refs.size()+' allLdCtctIdMap='+taskByLdCtctIdMap.size()+' taskByAcctIdMap='+taskByAcctIdMap.size()+' startDate='+callDates.startDate.format('M/d/yyyy HH:mm:ss'));
      if (refs.isEmpty()) {
         return;
      }

      PartnerReferral__c[] insertPartRefs = new PartnerReferral__c[]{};
      
      TaskWrapper[] matchingInboundWrappers = new TaskWrapper[]{};
      
      for (Referral__c ref : refs) {
         TaskWrapper[] tskWraps = new TaskWrapper[]{};
         Id queryId = ref.SourceContact__c; 
         TaskWrapper checkTskWrap = (queryId != null ? taskByLdCtctIdMap.get(queryId) : null);
         if (checkTskWrap == null && ref.SourceLead__c != null) {
            queryId = ref.SourceLead__c;
            checkTskWrap = taskByLdCtctIdMap.get(ref.SourceLead__c);
         }
         if (checkTskWrap != null) {
            tskWraps.add(checkTskWrap);
         } else if (ref.Account__c != null) {
            tskWraps = (taskByAcctIdMap.containsKey(ref.Account__c) ? taskByAcctIdMap.get(ref.Account__c) : tskWraps);
         }
         System.debug('checkExistingReferrals ref='+ref.Name+' existing tskWraps='+tskWraps.size());
         for (TaskWrapper tskWrap : tskWraps) {
            // if we're handling this here, remove from the inboundTaskMap
            //inboundTaskMap.remove(tskWrap.tsk.Id);
            
            //checkReferral(tskWrap, ref);
            
            tskWrap.ref = ref;
            tskWrap.partRef = ref.PartnerReferral__r;
            
            verifyReferral(tskWrap, ref);
            
            if (tskWrap.isInbound() && tskWrap.partRef == null) {
               matchingInboundWrappers.add(tskWrap);
               // create a partner referral record, update the referral
               createPartnerReferral(tskWrap, insertPartRefs);
               if (tskWrap.partRef != null) {
                  tskWrap.partRef.Referral__c = ref.Id;
               }
            } // if (tskWrap.isInbound() && tskWrap.partRef
            
            // are we done processing this task?
            if (tskWrap.isInbound()
                || tskWrap.leadId != null
                || tskWrap.acctId != null && tskWrap.oppFound) {
               // remove the wrappers from the maps
               taskByIdMap.remove(tskWrap.tsk.Id);
               if (queryId != null) {
                  taskByLdCtctIdMap.remove(queryId);
               }
               if (tskWrap.acctId != null) {
                  taskByAcctIdMap.remove(tskWrap.acctId);
               }
            }
         } // for (TaskWrapper tskWrap : tskWraps
         
         
      } // for (Referral__c ref

      // if we created partner referral records, we need to match them up to the existing referrals.
      if (!matchingInboundWrappers.isEmpty()) {
         // insert the records to link to the referral record
         DmlHelper.performDml2(insertPartRefs, DmlHelper.DML_INSERT, 'TaskHelper', 'checkExistingReferrals', 'Insert Partner Referrals', false);
         // update the referrals to link back to the partner referral.
         Referral__c[] updateRefs = new Referral__c[]{};
         for (TaskWrapper tskWrap : matchingInboundWrappers) {
            if (tskWrap.partRef != null && tskWrap.partRef.Id != null && tskWrap.ref != null) {
               tskWrap.ref.PartnerReferral__c = tskWrap.partRef.Id;
               updateRefMap.put(tskWrap.ref.Id, tskWrap.ref);
               //if (tskWrap.campaignId != null) {
               //   tskWrap.ref.campaign__c = tskWrap.campaignId;
               //   tskWrap.ref.SellingLeadSource__c = tskWrap.campaignLeadSource;
               //}
              // updateRefs.add(tskWrap.ref);
            }
         } // for (TaskWrapper tskWrap : matchingWrappers
         
         //DmlHelper.performDml2(updateRefs, DmlHelper.DML_UPDATE, 'TaskHelper', 'checkExistingReferrals', 'Update Referrals', false);
      } // if (!matchingWrappers.isEmpty
   } // checkExistingReferrals


   //If a partner referral is returned
   //   if inbound call, also create a referral
   //   If other kind, confirm partner referral, referral, and opportunity if they exist
   // look for existing PartnerReferral__c records
   public static void checkExistingPartnerReferrals(Map<Id, TaskWrapper> taskByLdCtctIdMap, Map<Id, TaskWrapper[]> taskByAcctIdMap
                                                  , Map<Id, TaskWrapper> taskByIdMap, PartnerReferral__c[] insertPartRefs) {
      PartnerReferral__c[] partRefs = [Select Id, Name, LastName__c, Account__c, Contact__c, Lead__c
                                              ,ActivityId__c, Master_Partner_Referral__c
                                              ,Master_Partner_Referral__r.Id
                                              ,Master_Partner_Referral__r.First_Call_Attempted__c
                                              ,Master_Partner_Referral__r.First_Contact_Made__c
                                              ,Master_Partner_Referral__r.Disposition__c
                                              ,Master_Partner_Referral__r.ProcessNotes__c
                                              ,Master_Partner_Referral__r.Workable__c
                                              ,CampaignId__c, Campaign__c, LeadSource__c
                                              ,Disposition__c
                                              ,First_Call_Attempted__c, First_Contact_Made__c
                                              ,ProcessNotes__c
                                              ,Source__c
                                              ,Workable__c
                                              ,CreatedDate, CreatedById, CreatedByProcess__c
                                              ,(Select Id, Name, OwnerId
                                                      ,Account__c, SourceContact__c, SourceLead__c 
                                                      ,Campaign__c, PartnerReferral__c
                                                      ,acd_name__c
                                                      ,CallListName__c
                                                      ,First_Call_Attempted__c
                                                      ,ReferralNotes__c
                                                      ,SellingLeadSource__c
                                                      ,CreatedDate, CreatedById
                                                      ,Selling_Opportunity__c
                                                      ,Selling_Opportunity__r.Id
                                                      ,Selling_Opportunity__r.IsClosed
                                                      ,Selling_Opportunity__r.Name
                                                      ,Selling_Opportunity__r.Campaign__c
                                                      ,Selling_Opportunity__r.CampaignActivityId__c
                                                      ,Selling_Opportunity__r.LeadSource
                                                      ,Selling_Opportunity__r.NSS_Source__c
                                                      ,Selling_Opportunity__r.OwnerId
                                                      ,Selling_Opportunity__r.Qualified_Type__c
                                                      ,Selling_Opportunity__r.ReferralLookup__c
                                                      ,Selling_Opportunity__r.ACD_Name__c
                                                  From Referrals__r)
                                          From PartnerReferral__c
                                         Where ((Contact__c in :taskByLdCtctIdMap.keySet()
                                                 or Lead__c in :taskByLdCtctIdMap.keySet()
                                                 or Account__c in :taskByAcctIdMap.keySet())
                                               and CreatedDate >= :callDates.startDate)
                                            or ActivityId__c in :taskByIdMap.keySet()
                                          order by CreatedDate desc
                                           ];
                                     
      System.debug('checkExistingPartnerReferrals existing partRefs='+partRefs.size()+' taskByIdMap='+taskByIdMap.size()+' taskByLdCtctIdMap='+taskByLdCtctIdMap.size()+' taskByAcctIdMap='+taskByAcctIdMap.size()+' startDate='+callDates.startDate.format('M/d/yyyy HH:mm:ss'));
      // if nothing is returned, exit here
      if (partRefs.isEmpty()) {
         return;

      }

      // group all of the partner referrals by task.
      // once they're all compiled, search through the ones returned for the most relevant
      // keep track of all of the ones we match on
      Map<Id,TaskWrapper> tsksWithPartnerMap = new Map<Id,TaskWrapper>();

      // if existing records, make sure they're linked up to the campaign 
      for (PartnerReferral__c partRef : partRefs) {
         TaskWrapper[] tskWraps = new TaskWrapper[]{};
         //Id queryId = (partRef.Contact__c != null ? partRef.Contact__c : partRef.Lead__c); 
         TaskWrapper checkTskWrap = (String.IsNotBlank(partRef.ActivityId__c) ? taskByIdMap.get(partRef.ActivityId__c) : null);
         if (checkTskWrap == null && partRef.Contact__c != null) {
            checkTskWrap = taskByLdCtctIdMap.get(partRef.Contact__c);
         }
         if (checkTskWrap == null && partRef.Lead__c != null) {
            checkTskWrap = taskByLdCtctIdMap.get(partRef.Lead__c);
         }
         if (checkTskWrap != null) {
            tskWraps.add(checkTskWrap);
         }
         if (tskWraps.isEmpty() && partRef.Account__c != null) {
            tskWraps = (taskByAcctIdMap.containsKey(partRef.Account__c) ? taskByAcctIdMap.get(partRef.Account__c) : tskWraps);
         }
         System.debug('checkExistingPartnerReferrals partRef='+partRef.LastName__c+' existing tskWraps='+tskWraps.size()+' ActivityId='+partRef.ActivityId__c+' Source='+partRef.Source__c);
         for (TaskWrapper tskWrap : tskWraps) {
            System.debug('checkExistingPartnerReferrals inbound='+tskWrap.isInbound());
            if ((String.IsBlank(partRef.ActivityId__c) || partRef.ActivityId__c == tskWrap.tsk.Id)
                && (tskWrap.isInbound() && (String.isBlank(partRef.Source__c) || !partRef.Source__c.startsWith('WEBLEAD'))
                    || !tskWrap.isInbound())
                ) {
               System.debug('checkExistingPartnerReferrals');
               // only add a partner referral to 1 task for evaluation
               tskWrap.partRefs.add(partRef);
               tsksWithPartnerMap.put(tskWrap.tsk.Id, tskWrap);
               //break;  // what if we leave the break in here and the most recent one isn't the one with the matching activity id?
            } else if (tskWrap.isInbound()
                  // if the existing partner referral is from a different activity, or it's from a weblead, we can use that
                  // to link as a master partner referral
                        && tskWrap.partRefOtherActId == null
                        && ((String.IsNotBlank(partRef.ActivityId__c) && partRef.ActivityId__c != tskWrap.tsk.Id)
                            || (String.isNotBlank(partRef.Source__c) && partRef.Source__c.startsWith('WEBLEAD')))
                        ) {
               System.debug('checkExistingPartnerReferrals setting as partRefOtherActId');
               tskWrap.partRefOtherActId = partRef;
               tsksWithPartnerMap.put(tskWrap.tsk.Id, tskWrap);
               //break;
            }

         } // for (TaskWrapper tskWrap
      } // for (PartnerReferral__c partRef
      
      for (TaskWrapper tskWrap : tsksWithPartnerMap.values()) {
         evaluatePartRefs(tskWrap);
         if (tskWrap.partRef != null) {
            System.debug('checkExistingPartnerReferrals verifying existing');
            verifyPartnerRef(tskWrap);
         } else if (tskWrap.isInbound()) {
            // if no matching partner referral is found (based on ActivityId__c or Source__c=ReferralController)
            // then create a new partner referral and link to another partner ref (if found)
            System.debug('checkExistingPartnerReferrals creating a new partner referral');
            createPartnerReferral(tskWrap, insertPartRefs);
            if (tskWrap.partRef != null) {
               // if already linked to a master partner referral link to the same one, else link directly to the one found
               PartnerReferral__c masterPartRef =  (tskWrap.partRefOtherActId != null ? (tskWrap.partRefOtherActId.Master_Partner_Referral__c != null ? tskWrap.partRefOtherActId.Master_Partner_Referral__r : tskWrap.partRefOtherActId) : null);
               Id masterId = (masterPartRef != null ? masterPartRef.Id : null);
               System.debug('checkExistingPartnerReferrals masterId='+masterId);
               tskWrap.partRef.Master_Partner_Referral__c = masterId;
               if (masterPartRef != null) {
                  tskWrap.oldLcd = (String.isNotBlank(masterPartRef.Disposition__c) ? LeadMethods.findCallDisposition(masterPartRef.Disposition__c,null) : null);
                  if (evaluateCallTimes(tskWrap,masterPartRef,false)) {
                     updatePartRefMap.put(masterPartRef.Id,masterPartRef);
                  }
               }
            }
         }

         // see if criteria was found and the TaskWrapper can be removed from the map (no further processing needed)
         // if a partner referral was found and this is a lead, we're done
         // if a partner referral was found and this is an account/contact and an opportunity was found, we're done
         // if this is inbound and an existing partner referral was found, we're done
         if (tskWrap.partRef != null) {
            if (tskWrap.isInbound()
                || !tskWrap.hasId 
                || tskWrap.leadId != null 
                || (tskWrap.acctId != null && tskWrap.oppFound)
                ) {
               // remove from the maps since we've completed processing on them.
               taskByIdMap.remove(tskWrap.tsk.Id);
               if (tskWrap.tsk.WhoId != null) {
                  taskByLdCtctIdMap.remove(tskWrap.tsk.WhoId);
               }
               if (tskWrap.tsk.AccountId != null) {
                  taskByAcctIdMap.remove(tskWrap.tsk.AccountId);
               }
            } // if (tskWrap.isInbound() 
         } // if (tskWrap.partRef != null

      } // for (TaskWrapper tskWrap
      /*
         for (TaskWrapper tskWrap : tskWraps) {
            
            //taskByIdMap.get(tskWrap.tsk.Id);
            //if (queryId != null) {
            //   taskByLdCtctIdMap.get(queryId);
            //}
            
            // if source is from the referral controller we can re-use and update or it's the same task id
            if (partRef.ActivityId__c == tskWrap.tsk.Id || String.isBlank(partRef.ActivityId__c)) { // String.isBlank(partRef.Source__c) || partRef.Source__c == ReferralController.PART_REF_SOURCE_NAME) {
               System.debug('checkExistingPartnerReferrals verifying existing');
               verifyPartnerRef(tskWrap, partRef);
            } else if (tskWrap.isInbound() && String.isNotBlank(partRef.ActivityId__c)) {
               // if this is an inbound task and one exists
               // if source is other, we would just link as a master referral and stop (no referral record)
               createPartnerReferral(tskWrap, insertPartRefs);
               if (tskWrap.partRef != null) {
                  // if already linked to a master partner referral link to the same one, else link directly to the one found 
                  tskWrap.partRef.Master_Partner_Referral__c = (partRef.Master_Partner_Referral__c != null ? partRef.Master_Partner_Referral__c : partRef.Id);
               }
            }
            
            // see if criteria was found and the TaskWrapper can be removed from the map (no further processing needed)
            // if a partner referral was found and this is a lead, we're done
            // if a partner referral was found and this is an account/contact and an opportunity was found, we're done
            // if this is inbound and an existing partner referral was found, we're done
            if (tskWrap.partRef != null) {
               if (tskWrap.isInbound()
                   || !tskWrap.hasId 
                   || tskWrap.leadId != null 
                   || (tskWrap.acctId != null && tskWrap.oppFound)
                   ) {
                  // remove from the maps since we've completed processing on them.
                  taskByIdMap.remove(tskWrap.tsk.Id);
                  if (queryId != null) {
                     taskByLdCtctIdMap.remove(queryId);
                  }
                  if (partRef.Account__c != null) {
                     taskByAcctIdMap.remove(partRef.Account__c);
                  }
               } // if (tskWrap.isInbound() 
            } // if (tskWrap.partRef != null
            
         } // for (TaskWrapper tskWrap : tskWraps
      } // for (PartnerReferral__c partRef

      */
   } // checkExistingPartnerReferrals
   
   public static Boolean evaluateCallTimes(TaskWrapper tskWrap, PartnerReferral__c partRef, Boolean isChild) {
      Boolean changed = false;
      System.debug('evaluateCallTimes partRef='+(partRef != null ? 'exists' : 'does not exist'));
      if (partRef != null) {
         if (partRef.First_Call_Attempted__c == null) {
            partRef.First_Call_Attempted__c = (tskWrap.tsk.CallDateTime__c != null ? tskWrap.tsk.CallDateTime__c : system.now());
            StringHelper.addToProcessNotes(partRef,'set First_Call_Attempted__c to '+partRef.First_Call_Attempted__c.format('MM/dd/yyyy HH:mm:ss'));
            changed = true;
         }
         if (tskWrap.firstContactQualified && partRef.First_Contact_Made__c == null) {
            partRef.First_Contact_Made__c = (tskWrap.tsk.CallDateTime__c != null ? tskWrap.tsk.CallDateTime__c : system.now());
            StringHelper.addToProcessNotes(partRef,'set First_Contact_Made__c to '+partRef.First_Contact_Made__c.format('MM/dd/yyyy HH:mm:ss'));
            changed = true;
         }
         /*
         if (partRef.Disposition__c == null)                                    // CMFCMF
         {  partRef.Disposition__c = tskWrap.tsk.CallDisposition;   
            StringHelper.addToProcessNotes(partRef,'set Dispostion__c to '+partRef.Disposition__c);
            changed = true;
         }
     */
         if (evaluatePartRefDisp(tskWrap, partRef, isChild))
         {  changed = true;  }
      } // if (partRef != null)
      return changed;
   } // evaluateCallTimes
   
   public static Boolean evaluateCallTimes(TaskWrapper tskWrap, Referral__c ref) {
      Boolean changed = false;
      System.debug('evaluateCallTimes tsk='+tskWrap.tsk.Subject+' ref='+ref != null);
      if (ref != null) {
         System.debug('evaluateCallTimes tsk='+tskWrap.tsk.Subject+' ref.Selling_Opportunity__c='+ref.Selling_Opportunity__c);
         if (ref.First_Call_Attempted__c == null && ref.Selling_Opportunity__c != null) {
            ref.First_Call_Attempted__c = (tskWrap.tsk.CallDateTime__c != null ? tskWrap.tsk.CallDateTime__c : system.now());
            StringHelper.addToProcessNotes(ref,'set First_Call_Attempted__c to '+ref.First_Call_Attempted__c.format('MM/dd/yyyy HH:mm:ss'));
            changed = true;
         }
      } // if (ref != null

      return changed;
   } // evaluateCallTimes
   
   // always use the partner referral if the activity id matches the task id
   // if task is inbound, if the activity id is blank and the source is referral controller we can reuse - update the activity id
   // if the task is inbound and no match on activity id or source, create a new one. 
   // if the task is not inbound, can match on source of WEBLEAD - for inbound reps updating webleads. 
   
   public static void evaluatePartRefs(TaskWrapper tskWrap) {
      PartnerReferral__c bestMatch = null;
      PartnerReferral__c actIdMatch = null;
      System.debug('evaluatePartRefs tsk='+tskWrap.tsk.Subject+' partRefs='+tskWrap.partRefs.size());
      for (PartnerReferral__c partRef : tskWrap.partRefs) {
         // get the first match on the id. This will be the best match.
         if (String.IsNotBlank(partRef.ActivityId__c) && partRef.ActivityId__c == tskWrap.tsk.Id) {
            System.debug('evaluatePartRefs match on the activityId');
            if (actIdMatch == null) {
               actIdMatch = partRef;
            }
            // only reuse a partner referral if created from the referral controller
         } else if (String.isBlank(partRef.ActivityId__c) && bestMatch == null) {
            if ((tskWrap.isInbound() && partRef.Source__c == ReferralController.PART_REF_SOURCE_NAME)
                || (!tskWrap.isInbound())) {
               bestMatch = partRef;
            }
         }
      } // for (PartnerReferral__c partRef
      System.debug('evaluatePartRefs actIdMatch='+(actIdMatch != null) +' bestMatch='+(bestMatch != null));
      String matchType = 'matchType='+(actIdMatch != null ? 'actIdMatch' : 'bestMatch');
      tskWrap.partRef = (actIdMatch != null ? actIdMatch : bestMatch);
      StringHelper.addToProcessNotes(tskWrap.partRef,matchType);
      System.debug('evaluatePartRefs partRef='+tskWrap.partRef);
   } // evaluatePartRefs
   
   public static Set<String> validDispositionSet = new Set<String>(Label.PartnerReferralValidDispositions.split(','));
      
   public static void createPartnerReferral(TaskWrapper tskWrap, PartnerReferral__c[] insertPartRefs) {
      System.debug('createPartnerReferral tskWrap='+tskWrap.tsk.Subject);
      if (tskWrap.partRef != null) {
         return;
      }
      tskWrap.partRef = (tskWrap.ld != null ? TrackRecordEntry.logOriginalData(tskWrap.ld) : TrackRecordEntry.logOriginalData(tskWrap.ctct, tskWrap.acct));
      tskWrap.partRef.Description__c = null;
      if (tskWrap.partRef != null) {
         System.debug('createPartnerReferral PartnerReferral created');
         tskWrap.partRef.ActivityId__c = tskWrap.tsk.Id;
           
         tskWrap.partRef.DialSource_Action__c = tskWrap.tsk.DS_Denali__DialSource_Action__c;
         // if not linked to the lead or contact, populate the phone number from the task.
         if (!tskWrap.hasId) {
            tskWrap.partRef.Phone__c = (tskWrap.tsk.DS_Denali__DialSource_Action__c != null ? tskWrap.tsk.DS_Denali__DialSource_Action__r.InboundCallerId__c : null);
         }
         tskWrap.partRef.Contact__c = tskWrap.ctctId;
         tskWrap.partRef.Account__c = tskWrap.acctId;
         tskWrap.partRef.Lead__c = tskWrap.leadId;
         //APR0112504: Partner Referral Source for Inbound Calls 
         if(tskWrap.CampaignId!= null && tskWrap.campaignSourceType!= null){
            tskWrap.partRef.Source__c = tskWrap.campaignSourceType;
         }
         else{
            tskWrap.partRef.Source__c = tskWrap.partRefSource;
         }
         tskWrap.partRef.Campaign__c = tskWrap.CampaignId;
         tskWrap.partRef.CampaignId__c = tskWrap.CampaignId;
         tskWrap.partRef.LeadSource__c = tskWrap.CampaignLeadSource;
         tskWrap.partRef.CreatedByProcess__c = TASK_HELPER;
         //Boolean validDisposition = (tskWrap.lcd != null && tskWrap.UseForPartRef__c);
         //Boolean validDisposition=(String.isNotBlank(tskWrap.tsk.CallDisposition) && validDispositionSet.contains(tskWrap.tsk.CallDisposition));
         // log what we're doing with the disposition
         //StringHelper.addToProcessNotes(tskWrap.partRef,'createPartnerReferral from id='+tskWrap.tsk.Id+' validDisposition='+validDisposition+' disposition='+tskWrap.tsk.CallDisposition+'.');
         //if (validDisposition) {
         //   tskWrap.partRef.Disposition__c = tskWrap.tsk.CallDisposition;
         //}
         evaluatePartRefDisp(tskWrap, tskWrap.partRef, true);
         evaluateCallTimes(tskWrap, tskWrap.partRef, true);
         insertPartRefs.add(tskWrap.partRef);
      } // if (tskWrap.partRef != null
      System.debug('createPartnerReferral insertPartRefs='+insertPartRefs.size());
   } // createPartnerReferral
   
   
   public static void verifyPartnerRef(TaskWrapper tskWrap) {
     System.debug('TaskHelper.verifyPartnerRef');
      // always log when we verify the task
      Boolean partRefUpdated = true;
      StringHelper.addToProcessNotes(tskWrap.partRef,'Verify Task '+tskWrap.tsk.Id+' isInbound='+tskWrap.isInbound());
      //APR0143141 - DSA not populated on the Partner Referral 
      if (tskWrap.isInbound() && String.isBlank(tskWrap.partRef.ActivityId__c)) {
         System.debug('verifyPartnerRef setting ActivityId__c and DialSource Action');
         StringHelper.addToProcessNotes(tskWrap.partRef,'Setting ActivityId__c and DialSourceAction');
         tskWrap.partRef.ActivityId__c = tskWrap.tsk.Id;           
         tskWrap.partRef.DialSource_Action__c = tskWrap.tsk.DS_Denali__DialSource_Action__c;
         partRefUpdated = true;
      }

      if (tskWrap.isInbound() && (String.isBlank(tskWrap.partRef.Source__c) || tskWrap.partRef.Source__c == ReferralController.PART_REF_SOURCE_NAME)) {
         StringHelper.addToProcessNotes(tskWrap.partRef,'Changing source from '+tskWrap.partRef.Source__c+' to '+tskWrap.partRefSource);
         tskWrap.partRef.Source__c = tskWrap.partRefSource;
         partRefUpdated = true;
      }
      
      // TODO - check for valid values
      // always update if valid values
      
      //AND Call Result not equal to INB - Created Oppty - Contacted,INB - Created Oppty - Warm Rep Transfer,INB - Created Oppty - Unable to Reach,INB - Callback,INB - Customer Service - Employee,INB - Customer Service - Employer,INB - Non-Sales Lead,INB - Answered/No One on Line,INB - Previous Lead,INB - Not Interested Clear 
      // put to 4 days for record check
      
      //Boolean validDisposition=(String.isNotBlank(tskWrap.tsk.CallDisposition) && validDispositionSet.contains(tskWrap.tsk.CallDisposition));
      //Boolean validDisposition = (tskWrap.lcd != null && tskWrap.UseForPartRef__c);
      // log what we're doing with the disposition
      //StringHelper.addToProcessNotes(tskWrap.partRef,'verifyPartnerRef validDisposition='+validDisposition+' disposition='+tskWrap.tsk.CallDisposition+'.');

      //if (validDisposition) {
      //   tskWrap.partRef.Disposition__c = tskWrap.tsk.CallDisposition;
      //   partRefUpdated = true;
      //}
      if (evaluatePartRefDisp(tskWrap, tskWrap.partRef, true)) {
         partRefUpdated = true;
      }
      
      // update blank PartRef with tsk.who info  
      //if (tskWrap.partRef.Lead__c == null && tskWrap.partRef.Contact__c == null && tskWrap.partRef.Account__c == null && tskWrap.tsk.Id == tskWrap.partRef.ActivityId__c
      //        && (tskWrap.ctctId != null || tskWrap.acctId != null || tskWrap.leadId != null))
      if (tskWrap.tsk.Id == tskWrap.partRef.ActivityId__c)
      {     String fldmsg ='';
            if (tskWrap.leadId != null && tskWrap.partRef.Lead__c == null)
            {   tskWrap.partRef.Lead__c = tskWrap.leadId;
                fldmsg += 'Lead ';
                partRefUpdated = true;
            }
            if (tskWrap.acctId != null && tskWrap.partRef.Account__c == null)
            {   tskWrap.partRef.Account__c = tskWrap.acctId;
                fldmsg += 'Account ';
                partRefUpdated = true;
            }
            if (tskWrap.ctctId != null && tskWrap.partRef.Contact__c == null) 
            {   tskWrap.partRef.Contact__c = tskWrap.ctctId;
                fldmsg += 'Contact ';
                partRefUpdated = true;
            }                       
            if (String.isNotBlank(fldmsg))
            {   StringHelper.addToProcessNotes(tskWrap.partRef,'verifyPartnerRef Populating '+fldmsg+'from task');  }   
      }
           
      String acdName = getAcdName(tskWrap.tsk, tskWrap.tsk.DS_Denali__DialSource_Action__r);
      if (tskWrap.CampaignId != null && (tskWrap.partRef.Campaign__c == null || String.isNotBlank(acdName))) {
         partRefUpdated = true;
         tskWrap.partRef.Campaign__c = tskWrap.CampaignId;
         tskWrap.partRef.CampaignId__c = tskWrap.CampaignId;
         if (String.isNotBlank(tskWrap.CampaignLeadSource)) {
            tskWrap.partRef.LeadSource__c = tskWrap.CampaignLeadSource;
         }
         
      } // if (tskWrap.CampaignId != null

      // Does it make sense to only set it on the master?
      if (tskWrap.partRef.Master_Partner_Referral__c != null) {
         tskWrap.oldLcd = (String.isNotBlank(tskWrap.partRef.Master_Partner_Referral__r.Disposition__c) ? LeadMethods.findCallDisposition(tskWrap.partRef.Master_Partner_Referral__r.Disposition__c,null) : null);
         if (evaluateCallTimes(tskWrap, tskWrap.partRef.Master_Partner_Referral__r, false)) {
            updatePartRefMap.put(tskWrap.partRef.Master_Partner_Referral__c,tskWrap.partRef.Master_Partner_Referral__r);
         }
      } else if (evaluateCallTimes(tskWrap, tskWrap.partRef, true) ){
         partRefUpdated = true;
      }
      

      tskWrap.refFound = tskWrap.partRef.Referrals__r.size() > 0;
      for (Referral__c ref : tskWrap.partRef.Referrals__r) {
         verifyReferral(tskWrap, ref);
      } // for (Referral__c ref
      
      if (partRefUpdated) {
         updatePartRefMap.put(tskWrap.partRef.Id,tskWrap.partRef);
      }
   } // verifyPartnerRef
   
   public static Boolean evaluatePartRefDisp(TaskWrapper tskWrap, PartnerReferral__c partRef, Boolean isChild) {
      Boolean changed = false;
      Boolean validDisposition = (tskWrap.lcd != null && tskWrap.lcd.UseForPartRef__c);
      Boolean masterDispOverwrite = (tskWrap.oldLcd!= null && tskWrap.oldLcd.Overwrite_PR__c);
      // log what we're doing with the disposition
      StringHelper.addToProcessNotes(partRef,'evaluatePartRefDisp validDisposition='+validDisposition+' disposition='+tskWrap.tsk.CallDisposition+', masterDispOverwrite ='+masterDispOverwrite+', isChild='+isChild+'.');
      System.debug('evaluatePartRefDisp validDisposition='+validDisposition+' disposition='+tskWrap.tsk.CallDisposition+', masterDispOverwrite ='+masterDispOverwrite+', isChild='+isChild+'.');
       if (validDisposition && (isChild || (!isChild && (partRef.Disposition__c == null || masterDispOverwrite)))) {
         partRef.Disposition__c = tskWrap.tsk.CallDisposition;
         changed = true;
      }
      
      if (tskWrap.lcd != null && String.isNotBlank(tskWrap.lcd.SetWorkable__c) && tskWrap.lcd.SetWorkable__c != partRef.Workable__c) {
         partRef.Workable__c = tskWrap.lcd.SetWorkable__c;
         changed = true;
      }
      return changed;
   } // evaluatePartRefDisp
   
   public static void verifyReferral(TaskWrapper tskWrap, Referral__c ref) {
      System.debug('verifyReferral tsk='+tskWrap.tsk.Subject);
      if (ref == null) {
         return;
      }
      if (tskWrap.ref == null) {
         tskWrap.ref = ref;
      }
      Boolean refChanged = false;
      
      // if there is an acd name on the task, then we will always overwrite the campaign info on the related records
      if (tskWrap.CampaignId != null && (String.isNotBlank(tskWrap.acdName) || tskWrap.ref.Campaign__c == null)) {
         tskWrap.ref.Campaign__c = tskWrap.CampaignId;
         refChanged = true;
      }
      if (tskWrap.CampaignId != null && String.isNotBlank(tskWrap.CampaignLeadSource) && (String.isNotBlank(tskWrap.acdName) || String.isBlank(tskWrap.ref.SellingLeadSource__c))) {
         tskWrap.ref.SellingLeadSource__c = tskWrap.CampaignLeadSource;
         refChanged = true;
      }
         
      if (String.isNotBlank(tskWrap.acdName) && String.isBlank(tskWrap.ref.ACD_Name__c)) {
         tskWrap.ref.acd_name__c = tskWrap.acdName;
         refChanged = true;
      }

      if (String.isNotBlank(tskWrap.listName) && String.isBlank(tskWrap.ref.CallListName__c)) {
         tskWrap.ref.CallListname__c = tskWrap.listName;
         refChanged = true;
      }
      
      if (evaluateCallTimes(tskWrap, tskWrap.ref)) {
         refChanged = true;
      }
      
      if (tskWrap.lcd != null && String.isNotBlank(tskWrap.lcd.AssignToQueue__c) && tskWrap.lcd.SetWorkable__c == TrackRecordEntry.NOT_WORKABLE) {
         Group queue = new UserHelper().getQueue(tskWrap.lcd.AssignToQueue__c);
         if (queue != null && tskWrap.ref.OwnerId != queue.Id) {
            tskWrap.ref.OwnerId = queue.Id;
            refChanged = true;
         }
      }
         
      if (refChanged) {
         updateRefMap.put(tskWrap.ref.Id, tskWrap.ref);
      }
         
      verifyOpportunity(tskWrap, tskWrap.ref, tskWrap.ref.Selling_Opportunity__r);

   } // verifyReferral
   
   
   //public static String[] sqlValues = Label.SQL_Values.split(',');   
   
   //public static Set<String> DISPOSITION_SQL_VALUES_SET=null;
   
   public static void verifyOpportunity(TaskWrapper tskWrap, Referral__c ref, Opportunity opp) {
      System.debug('verifyOpportunity opp='+opp);
      if (opp != null) {
         //if (DISPOSITION_SQL_VALUES_SET == null) {
         //   DISPOSITION_SQL_VALUES_SET = new Set<String>();
         //   DISPOSITION_SQL_VALUES_SET.addAll(sqlValues);
         //}
         tskWrap.oppFound = true;

         Boolean oppChanged = false;
         // we're not going to change ones that are inbound and have a campaign unless acd_name is blank
         //if (opp.Campaign__c == null || opp.NSS_Source__c != ProspectOwnershipMethods.NSS_INBOUND || opp.acd_name__c == null) {
            
            if (tskWrap.CampaignId != null && (opp.Campaign__c == null || String.isNotBlank(tskWrap.acdName))) {
               opp.Campaign__c = tskWrap.CampaignId;
               opp.CampaignActivityId__c = tskWrap.tsk.Id;
               oppChanged = true;
            } // if (tskWrap.CampaignId != null
            
            // always set the lead source
            if (String.isNotBlank(tskWrap.campaignLeadSource)) {
               opp.LeadSource = tskWrap.campaignLeadSource;
               oppChanged = true;
            }
            
            // always set the acd name if one exists on the task
            if (String.isNotBlank(tskWrap.acdName)) {
               opp.ACD_Name__c = tskWrap.acdName;
               oppChanged = true;
            }
            
            if (ref != null && ref.Id != null && opp.ReferralLookup__c != ref.Id) {
               opp.ReferralLookup__c = ref.Id;
               oppChanged = true;
            }
            
         //} // if (opp.Campaign__c == null ||
         

         // if it's already SQL we're not going to change it.
         //if (opp.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND && opp.Qualified_Type__c != 'SQL') {
         //   String callDisposition = (String.isNotBlank(tskWrap.tsk.CallDisposition) ? tskWrap.tsk.CallDisposition.trim() : null);
         //   System.debug('verifyOpportunity opp='+opp.Name+' callDisposition='+callDisposition);
         //   if (callDisposition != null && DISPOSITION_SQL_VALUES_SET.contains(callDisposition)) {
         //      System.debug('verifyOpportunity set SQL');
         //      opp.Qualified_Type__c = 'SQL';
         //      oppChanged=true;
         //   } else {
         //      System.debug('verifyOpportunity set MQL');
         //      opp.Qualified_Type__c = 'MQL';
         //      oppChanged=true;
         //   }
            
         //} // if (opp.NSS_Source__c ==

         if (oppChanged) {
            updateOppMap.put(opp.Id,opp);
         }
         
      } // if (opp != null
      

   } // verifyOpportunity
   
   public static Contact getContact(Account acct, Set<Id> ctctIdSet) {
      Contact ctctInSet = null;
      Contact significantCtct = null;
      Contact firstCtct = null;
     
      for (Contact ctct : acct.Contacts) {
         if (firstCtct == null) {
            firstCtct = ctct;
         }
         if (ctctIdSet.contains(ctct.Id)) {
            ctctInSet = ctct;
            // if we get here we can stop - this is the best case scenario
            break;
         }
         if (ctct.SignificantContact__c) {
            significantCtct = ctct;
         }
      } // for (Contact ctct
      
      System.debug('getContact ctcts='+acct.Contacts.size()+' ctctInSet='+(ctctInSet != null ? 'true' : 'false')
                            +' significantCtct='+(significantCtct != null ? 'true' : 'false')
                            +' firstCtct='+(firstCtct != null ? 'true' : 'false'));
      Contact ctct = (ctctInSet != null ? ctctInSet : (significantCtct != null ? significantCtct : firstCtct));
      return ctct;
   } // getContact
   
   public static Contact getContact(TaskWrapper wrapper) {
      Contact ctct = wrapper.ctct;
      if (ctct == null && wrapper.ctctId != null) {
         ctct = updateContactMap.get(wrapper.ctctId);
         if (ctct == null) {
            ctct = new Contact(Id=wrapper.ctctId);
         }
      } // if (wrapper.ctctId

      return ctct;
   } // getContact
   
   public static Account getAccount(TaskWrapper wrapper) {
      Account acct = wrapper.acct;
      if (acct == null && wrapper.acctId != null) {
         acct = updateAcctMap.get(wrapper.acctId);
         if (acct == null) {
            acct = new Account(Id=wrapper.acctId);
         }
      }
      return acct;
   } // getAccount

   public static Lead getLead(TaskWrapper wrapper) {
      Lead ld = wrapper.ld;
      if (ld == null && wrapper.leadId != null) {
         ld = updateLeadMap.get(wrapper.leadId);
         if (ld == null) {
            ld = new Lead(Id=wrapper.leadId);
         }
      } // if (wrapper.leadId
      return ld;
   } // getLead
   
   public static Long MAX_DIFF=Long.valueOf(Label.TaskHelper_Max_Diff);

   public static void checkExistingOpportunities(Map<Id, TaskWrapper> taskByLdCtctIdMap, Map<Id, TaskWrapper[]> taskByAcctIdMap, Map<Id, TaskWrapper> taskByIdMap) {
      if (taskByAcctIdMap.isEmpty()) {
         return;
      }

      Map<Id, OppWrapper> oppWrapperByAcctIdMap = selectOpportunities(taskByAcctIdMap.keySet());
      for (Id acctId : oppWrapperByAcctIdMap.keySet()) {
         OppWrapper oppWrap = oppWrapperByAcctIdMap.get(acctId);
         TaskWrapper[] tskWrappers = taskByAcctIdMap.get(acctId);
         if (tskWrappers != null && oppWrap != null) {
            for (TaskWrapper tskWrap : tskWrappers) {
               Opportunity[] opps = oppWrap.findClosestOpps(tskWrap);
               System.debug('checkExistingOpportunities opps='+opps.size());
               if (!opps.isEmpty()) {
                  for (Opportunity opp : opps) {
                     verifyOpportunity(tskWrap, null, opp);
                  } // for (Opportunity opp
               } // if (!opps.isEmpty
            } // for (TaskWrapper tskWrap : tskWrappers
         } // if (tskWrappers != null &&
         
      } // for (Id acctId
   } // checkExistingOpportunities
   
   public static Map<Id, OppWrapper> selectOpportunities(Set<Id> acctIdSet) {
      Map<Id, OppWrapper> oppWrapperByAcctIdMap = new Map<Id, OppWrapper>();
      
      System.debug('selectOpportunities acctIdSet='+acctIdSet+' callDates='+callDates);
      
      // select opps and group them together by account id
      for (Opportunity opp : [Select Id, Name, CreatedDate, AccountId, Campaign__c, CampaignActivityId__c, LeadSource
                                    ,NSS_Source__c, Qualified_Type__c, ReferralLookup__c, acd_name__c
                                    ,(Select Id, OwnerId, Campaign__c, acd_name__c, CallListName__c
                                            ,SellingLeadSource__c
                                            ,PartnerReferral__c
                                            ,PartnerReferral__r.Id
                                            ,PartnerReferral__r.Campaign__c
                                            ,PartnerReferral__r.CampaignId__c
                                        from Referrals__r)
                                From Opportunity 
                               Where AccountId in :acctIdSet
                                 and CreatedDate >= :callDates.startDate
                                 and CreatedDate <= :callDates.endDate
                                 and NSS_Source__c != null
                                 //and Id in (Select OpportunityId from OpportunityTeamMember where UserId in :nsrIdSet)
                               ]) {
         // we're not going to change ones that are inbound and have a campaign unless acd_name is blank
         if (opp.Campaign__c == null || opp.NSS_Source__c != ProspectOwnershipMethods.NSS_INBOUND || opp.acd_name__c == null) { //CMFCMF
            OppWrapper oppWrap = oppWrapperByAcctIdMap.containsKey(opp.AccountId) ? oppWrapperByAcctIdMap.get(opp.AccountId) : new OppWrapper();
            oppWrap.addOpp(opp);
            oppWrapperByAcctIdMap.put(opp.AccountId,oppWrap);
         }
      } // for (Opportunity opp
      return oppWrapperByAcctIdMap;
   } // selectOpportunities
   
   public class OppWrapper{
      
      public void addOpp(Opportunity p_opp) {
         // the date the opp was created
         Date dt = p_opp.CreatedDate.date();
         // the time stamp the opp was created - append a 1 to keep everything the same length (account for leading zeros) MMHH
         
         // decimal value of the time stamp
         Long dateTimeStamp = p_opp.CreatedDate.getTime();
         System.debug('addOpp opp='+p_opp.Name+' dateTimeStamp='+dateTimeStamp);
         Opportunity[] opps = oppsByDateTimeStampMap.get(dateTimeStamp);
         if (opps == null) {
            opps = new Opportunity[]{};
            oppsByDateTimeStampMap.put(dateTimeStamp,opps);
         }
         opps.add(p_opp);
         //oppByDateTimeStampMap.put(dateTimeStamp,p_opp);
         
         
      } // addOpp
      
      //public Map<Long,Opportunity> oppByDateTimeStampMap = new Map<Long,Opportunity>();
      public Map<Long,Opportunity[]> oppsByDateTimeStampMap = new Map<Long,Opportunity[]>();
      
      // find the closest opportunity to the passed in task. Remove the opp from the map once found so we only set the campaign once.
      public Opportunity[] findClosestOpps(TaskWrapper wrapper) {
         Task tsk = wrapper.tsk;
         Opportunity[] closestOpps = new Opportunity[]{};
         //if (oppByDateTimeStampMap.size() == 0) {
         //   return closestOpp;
         //}
/*
         if (oppByDateTimeStampMap.size() == 1) {
            Opportunity checkOpp = oppByDateTimeStampMap.values()[0];
            if (matchingTeamMemberFound(tsk.OwnerId, checkOpp.OpportunityTeamMembers)) {
               Long checkTime = sortedKeySet[0];
               Long curDiff = Math.abs(taskDateTime - checkTime);
               closestOpp = checkOpp;
               oppByDateTimeStampMap.clear();
            }
         } else
         */
         // only proceed if there's an NSS Source on the owner - we're comparing this to  
         //if (wrapper.ownerNssSource != null && oppsByDateTimeStampMap.size() > 0) {
         if (oppsByDateTimeStampMap.size() > 0) {
            List<Long> sortedKeySet = new List<Long>();
            sortedKeySet.addAll(oppsByDateTimeStampMap.keySet());
            sortedKeySet.sort();
            Long taskDateTime = (tsk.CallDateTime__c != null ? tsk.CallDateTime__c.getTime() : tsk.CreatedDate.getTime());
            System.debug('findClosestOpps taskDateTime='+taskDateTime+' sortedKeySet='+sortedKeySet+' MAX_DIFF='+MAX_DIFF);
            Long minDiff = null;
            Long foundTime = null;
            for (Long checkTime : sortedKeySet) {
               Opportunity[] checkOpps = oppsByDateTimeStampMap.get(checkTime);
               for (Opportunity checkOpp : checkOpps) {
                  System.debug('findClosestOpps opp='+checkOpp.Name+' checking for team member');
                  //if (matchingTeamMemberFound(tsk.OwnerId, checkOpp.OpportunityTeamMembers)) {
                     Long curDiff = Math.abs(taskDateTime - checkTime);
                     System.debug('findClosestOpps team member found opp='+checkOpp.Name+' curDiff='+curDiff);
                     // make sure the minimum difference is there - don't use ones that are too far away
                     //if (checkOpp.NSS_Source__c == wrapper.ownerNssSource && curDiff <= MAX_DIFF) {
                     if (curDiff <= MAX_DIFF) {
                        // find all opps within the MAX_DIFF
                        closestOpps.add(checkOpp);

                        //if (minDiff == null) {
                           //System.debug('findClosestOpps first match');
                        // this is the first match
                           //closestOpp = checkOpp;
                           //minDiff = curDiff;
                           //foundTime = checkTime;
                        //} else {
                           //if (curDiff < minDiff) {
                              //System.debug('findClosestOpps found closer match');
                           // this is closer than previous match - use this instead.
                              //minDiff = curDiff;
                              //closestOpp = checkOpp;
                              //foundTime = checkTime;
                           //} else if (curDiff > minDiff) {
                           // we're getting farther away - we can stop and use what we have
                              //break;
                           //}
                        //}

                     } // if (curDiff <= MAX_DIFF
                  //} // if (matchingTeamMemberFound
               } // for (Opportunity checkOpp : checkOpps
            } // for (Long checkTime
            if (foundTime != null) {
               oppsByDateTimeStampMap.remove(foundTime);
            }
         } // if (oppsByDateTimeStampMap.
         
         return closestOpps;
      } // findClosestOpps
      
      private Boolean matchingTeamMemberFound(Id checkId, OpportunityTeamMember[] teamMembers) {
         Boolean matchFound = false;
         if (teamMembers != null) {
            for (OpportunityTeamMember otm : teamMembers) {
               if (otm.UserId == checkId) {
                  matchFound = true;
                  break;
               }
            } // for (OpportunityTeamMember otm
         } // if (teamMembers
         return matchFound;
      } // matchingTeamMemberFound
      // for each date, store a map of the opportunities by timestamp
      //Map<Date,Map<Integer,Opportunity>> oppByDateByTimeStampMap = new Map<Date,Map<Integer,Opportunity>>();
      //Map<Date,List<Integer>> timeStampByDateMap = new Map<Date,List<Integer>>();
   } // class OppWrapper

   public static Integer CALL_HOURS_OFFSET = Integer.valueOf(Label.TaskHelper_CallOffset);
   
   public class DateWrapper {
      public DateTime startDate = DateTime.now().addHours(-CALL_HOURS_OFFSET);
      public DateTime endDate = DateTime.now().addHours(CALL_HOURS_OFFSET);
      
      public void compareStartAndEndDate(DateTime checkStart, DateTime checkEnd) {
         if (checkStart < startDate) {
            startDate = checkStart;
         }
         
         if (checkEnd > endDate) {
            endDate = checkEnd;
         }
      } // compareStartAndEndDate
   } // class DateWrapper

   public static DateWrapper callDates = new DateWrapper();
   
   //public static map<Id, TaskWrapper> allLdCtctIdMap = new map<Id, TaskWrapper>();
   
   //public static Map<Id, TaskWrapper> inboundTaskMap = new Map<Id, TaskWrapper>();

   // get a map of all of the tasks
   public static Map<Id,TaskWrapper> getTaskMap(Set<Id> checkTaskIdSet ,Set<Id> ownerIdSet, Set<Id> callbackLdCtctIdSet
                                               ,Map<Id, TaskWrapper> taskByIdMap
                                               ,Map<Id, TaskWrapper> taskByLdCtctIdMap, Map<Id, TaskWrapper[]> taskByAcctIdMap
                                               ,TaskWrapper[] checkForCadenceWraps) {
      Id[] idList = new Id[]{};
      idList.addAll(checkTaskIdSet);

      System.debug('getTaskMap idList='+idList.size());
      
      // verify the owners are NSRs
      AccountMethods.setUserMap(ownerIdSet);
      //Map<Id,User> nsrUserMap = ProspectOwnershipMethods.getNsrUserMap(ownerIdSet);
      
      // check the leads for the latest campaign field
      Map<Id,TaskWrapper> leadTaskMap = new Map<Id,TaskWrapper>();

      // break apart the set for the callbacks to query the correct objects
      Set<Id> contactIdSet = new Set<Id>();
      Set<Id> acctIdSet = new Set<Id>();
      Set<Id> leadIdSet = new Set<Id>();
      
      for (Id checkId : callbackLdCtctIdSet) {
         SObjectType idType = checkId.getSObjectType();
         if (idType == Account.getSObjectType()) {
            acctIdSet.add(checkId);
         } else if (idType == Contact.getSObjectType()) {
            contactIdSet.add(checkId);
         } else if (idType == Lead.getSObjectType()) {
            leadIdSet.add(checkId);
         }
      } // for (Id checkId
                                                                                           

      // if not linked to an account or lead, but there is a phone number, search for related record.
      //Map<String,TaskWrapper> searchTaskMap = new Map<String,TaskWrapper>();
      
      callDates = new DateWrapper();
      
      Map<Id, Task> taskMap = (!idList.isEmpty() ? queryTaskMap(idList) : new Map<Id,Task>());
      
      Map<String, TaskWrapper[]> acdMap = new Map<String, TaskWrapper[]>();
      Map<String, TaskWrapper[]> listMap = new Map<String, TaskWrapper[]>();  
      for (Task tsk : taskMap.values()) {

         //TaskWrapper tskWrapper = new TaskWrapper(tsk, nsrUserMap.get(tsk.OwnerId));
         TaskWrapper tskWrapper = new TaskWrapper(tsk, AccountMethods.userMap.get(tsk.OwnerId));
         // get the date range for querying related records
         if (tsk.CallDateTime__c != null) {
            callDates.compareStartAndEndDate(tsk.CallDateTime__c.addHours(-CALL_HOURS_OFFSET), tsk.CallDateTime__c.addHours(CALL_HOURS_OFFSET));
         }
         
         String tskInfo = 'hasId='+tskWrapper.hasId+' isInbound='+tskWrapper.isInbound()+' tsk.CAR__c='+tsk.CAR__c;
         // if a CAR is already linked to a task, do not process it again
         if (tsk.CAR__c == null && (tskWrapper.hasId || tskWrapper.isInbound())) {
            checkForCadenceWraps.add(tskWrapper);
            if (checkTaskIdSet.contains(tsk.Id)) {
               taskByIdMap.put(tskWrapper.tsk.Id, tskWrapper);

            }
            String inboundCallerId = getInboundCalledId(tsk, tsk.DS_Denali__DialSource_Action__r);
            tskWrapper.acdName = getAcdName(tsk, tsk.DS_Denali__DialSource_Action__r);
            tskWrapper.listName = getListName(tsk, tsk.DS_Denali__DialSource_Action__r);

            if (String.isNotBlank(tskWrapper.acdName)) {
               tskInfo += ' has acd name='+tskWrapper.acdName;
               addToMap(tskWrapper.acdName, tskWrapper, acdMap);
            } else if (String.isNotBlank(tskWrapper.listName)) {
               tskInfo += ' has list name='+tskWrapper.listName;
               addToMap(tskWrapper.listName, tskWrapper, listMap);
            }

            if (tskWrapper.acctId != null) {
               tskInfo += ' has acctId';
               TaskWrapper[] tskList = taskByAcctIdMap.containsKey(tskWrapper.acctId) ? taskByAcctIdMap.get(tskWrapper.acctId) : new TaskWrapper[]{};
               tskList.add(tskWrapper);
               taskByAcctIdMap.put(tskWrapper.acctId, tskList);
               if (tskWrapper.ctctId != null) {
                  tskInfo += ' has ctctId';
                  contactIdSet.add(tskWrapper.ctctId);
               }
            } else if (tskWrapper.leadId != null) {
               tskInfo += ' has leadId';
               leadTaskMap.put(tskWrapper.leadId, tskWrapper);
               taskByLdCtctIdMap.put(tskWrapper.leadId, tskWrapper);
            }
         } // if (tskWrapper.hasId || tskWrapper.isInbound
         tskWrapper.addToLog(tskInfo);
      } // for (Task tsk
      
      System.debug('getTaskMap before checks taskByAcctIdMap='+taskByAcctIdMap.size()+' leadTaskMap='+leadTaskMap.size());
      
      // retrieve the campaigns based on the acd and list names
      if (!acdMap.isEmpty()) {
         checkForCampaign(acdMap, TYPE_ACD, true);
      }
      
      if (!listMap.isEmpty()) {
         checkForCampaign(listMap, TYPE_LIST, false);
      }

      acctIdSet.addAll(taskByAcctIdMap.keySet());
      leadIdSet.addAll(leadTaskMap.keySet());
      
      System.debug('getTaskMap before checks acctIdSet='+acctIdSet.size()+' leadIdSet='+leadIdSet.size());

      // retrieve the accounts/contacts and leads associated with the tasks
      if (!acctIdSet.isEmpty()) {
         checkAccounts(taskByAcctIdMap, acctIdSet, contactIdSet, taskByLdCtctIdMap);
      }
      if (!leadIdSet.isEmpty()) {
         checkLeads(leadTaskMap, leadIdSet);
      }

      System.debug('getTaskMap after checks taskByAcctIdMap='+taskByAcctIdMap.size()+' leadTaskMap='+leadTaskMap.size());
      
      return taskByIdMap;
   } // getTaskMap

   // how many days do we process tasks for? This is so if tasks are old and get updated we don't process them again
   public static Integer TASK_NBR_DAYS = Integer.valueOf(Label.TaskHelper_TaskQueryDays);
   
   public static Map<Id,Task> queryTaskMap(Id[] tskIds) {
        
      DateTime queryDate = DateTime.now().addDays(-TASK_NBR_DAYS);
      // need to always be able to query ca
      Map<Id,Task> taskMap = new Map<Id,Task>([Select Id, WhoId, WhatId, AccountId, OwnerId
                             ,ActivityDate
                             ,RecordTypeId
                             ,RecordType.Id,RecordType.Name
                             ,CallDisposition
                             ,CallObject
                             ,Who.Email
                             ,CallType
                             ,CAR__c
                             ,CreatedDate
                             ,Subject
                             ,Status
                             ,Description
                             ,ReminderDateTime
                             ,Type
                             ,CallDateTime__c
                             ,DS_Denali__DialSource_Action__c
                             ,DS_Denali__DialSource_Action__r.Id
                             ,DS_Denali__DialSource_Action__r.RecordType.Id
                             ,DS_Denali__DialSource_Action__r.RecordType.Name
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Account__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Campaign__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Completed_Time__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Placed__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Started__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Ended__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Call_Disposition__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Phone__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Contact__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Inbound_DNIS_Name__c
                             ,DS_Denali__DialSource_Action__r.DS_Denali__Lead__c
                             ,DS_Denali__DialSource_Action__r.CallCampaignOld__c
                             ,DS_Denali__DialSource_Action__r.InboundCallerId__c
                             ,DS_Denali__DialSource_Action__r.InboundCallerIdOld__c
                             ,DS_Denali__DialSource_Action__r.InboundDNISNameOld__c
                         from Task
                        Where Id in :tskIds
                          and CreatedDate >= :queryDate 
                          ]);
      return taskMap;
   } // queryTaskMap
    
   public static Map<Id,String> queryActivityEmailMap(Id[] whoIds) {
      Map<Id,String> emailMap = new Map<Id,String>();
      Id[] leadIds = new Id[]{};
      Id[] ctctIds = new Id[]{};
      for (Id whoId : whoIds) {
         String whoIdPrefix = String.valueOf(whoId).left(3);
         if (whoIdPrefix == ObjectHelper.PREFIX_LEAD) {
            leadIds.add(whoId);
         } else if (whoIdPrefix == ObjectHelper.PREFIX_CONTACT) {
            ctctIds.add(whoId);
         }
      }
      if (!leadIds.isEmpty()) {
         Lead[] leads = [Select Id, Email from Lead where Id in :leadIds and Email != null];
         for (Lead ld : leads) {
            emailMap.put(ld.Id, ld.Email);
         }
      }
      if (!ctctIds.isEmpty()) {
         Contact[] ctcts = [Select Id, Email from Contact where Id in :ctctIds and Email != null];
         for (Contact ctct : ctcts) {
            emailMap.put(ctct.Id, ctct.Email);
         }
      }
      System.debug('queryActivityEmailMap whoIds='+whoIds.size()+' emailMap='+emailMap.size());
      return emailMap;
   } // queryActivityEmailMap 

   // if we only have an account id, try to find a contact for it.
   public static void checkAccounts(Map<Id, TaskWrapper[]> taskByAcctIdMap, Set<Id> acctIdSet, Set<Id> contactIdSet, Map<Id, TaskWrapper> taskByLdCtctIdMap) {
      System.debug('checkAccounts taskByAcctIdMap='+taskByAcctIdMap.size());
      Date checkDate = Date.today();
      String typeCheck = CT_CALLBACK;
      String acctQuery = (String)CacheManager.getOrg('TaskHelperCheckAccountsQuery');
      if (acctQuery == null) {
         Set<String> fldSet = new Set<String>();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.TaskHelperFlds, '', fldSet);
         fldSet.addAll(ZipQueries.getAccountQueryFields());
         acctQuery = DmlHelper.buildQueryFromSet(fldSet,null);
         fldSet.clear();
         DmlHelper.addFieldsToSet(Schema.SObjectType.Contact.fieldSets.TaskHelperFlds, '', fldSet);
         // subquery for the contacts
         String subQuery = DmlHelper.buildQueryFromSet(fldSet,'Contacts');
         acctQuery += ',('+subQuery+' where (SignificantContact__c=true or Id in :contactIdSet) limit 5 ) ';
         acctQuery += ',(Select Id, CallType, ActivityDate, IsReminderSet, ReminderDateTime, Subject, Type From Tasks Where ActivityDate >= :checkDate ';
         acctQuery += '      and Type = :typeCheck and IsClosed = false order by ActivityDate desc limit 1) ';
         acctQuery += ' from Account where Id in :acctIdSet ';
         System.debug('checkAccounts acctQuery='+acctQuery);
         CacheManager.putOrg('TaskHelperCheckAccountsQuery',acctQuery);
      }
      /*
      for (Account acct : [Select Id, RecordTypeId, OwnerId, CurrentClient__c
                                 ,Name,ShippingStreet,ShippingCity,ShippingState,Owner_Zip_Code__c,Owner_ZipCode__c
                                 ,NumberOfEmployees, X401K_Assets__c
                                 ,Hispanic_Ownership__c,PEOLeasing__c,MS_Hold_Out__c
                                 ,CSSR_Segment__c,SegmentationCore1__c
                                 ,Dialed__c, DialedUserId__c, Do_Not_Call__c
                                 ,NSSCallDisposition__c, LastNSSCallDisposition__c, NSSStatus__c
                                 //,NSSContactName__c, NSSContactPhone__c
                                 ,AssignedToOutboundNSR__c,AssignedToInboundNSR__c
                                 ,LatestCallTime__c, LatestCampaignName__c
                                 ,ProcessNotes__c, Products__c
                                 ,SignificantContact__c
                                 ,DS_Denali__Next_Call_DS__c
                                 ,(Select Id, Name, AccountId, Dialed__c, DialedUserId__c, LatestCampaign__c, LatestCampaignDate__c, LeadSource
                                         ,OwnerId, Hold_Out__c, Hold_Out_Reason__c, BypassHoldout__c, Use_Zip_Assignment_Rules__c
                                         ,AMP_Referral__c
                                         ,Contact_Stage__c, Reject_Reason__c, Recycle_Reason__c
                                         ,DS_Denali__Next_Call_DS__c
                                         ,Marketo_Lead_Rating__c
                                         ,NSSCallDisposition__c, LastNSSCallDisposition__c, SignificantContact__c, NSSStatus__c
                                         ,LatestCallTime__c
                                         ,LastName,FirstName,Email,Phone,Title
                                         ,MktgId__c
                                         ,ProcessNotes__c
                                         ,Products__c,Description,OwnedByPrev__c 
                                         ,TransactionId__c,Consent_to_Text__c, Consent_to_Text_Date__c
                                     from Contacts 
                                    where (SignificantContact__c=true or Id in :contactIdSet) limit 5) 
                                 ,(Select Id, CallType, ActivityDate, IsReminderSet, ReminderDateTime, Subject, Type
                                     From Tasks
                                    Where ActivityDate >= :Date.today()
                                      and Type = :CT_CALLBACK
                                      and IsClosed = false
                                      order by ActivityDate desc
                                      limit 1)
                             from Account where Id in :acctIdSet]) 
         */
      Account[] accts = Database.query(acctQuery);
      for (Account acct : accts) {
         Datetime callbackTime = getCallbackTime(acct.Tasks);

         // so we can at least make sure the account gets updated.
         TaskWrapper[] tskWraps = taskByAcctIdMap.get(acct.Id);

         if (tskWraps != null) {
            for (TaskWrapper tskWrap : tskWraps) {
               tskWrap.setContact(acct);
               Contact ctct = getContact(tskWrap);
               if (ctct != null) {
                  taskByLdCtctIdMap.put(ctct.Id, tskWrap);
               }
               //LeadCallDisposition__c lcd = (String.isNotBlank(tskWrap.tsk.CallDisposition) ? LeadMethods.findCallDisposition(tskWrap.tsk.CallDisposition,null) : null);
               checkAcctCtctFlds(tskWrap, acct, ctct, tskWrap.lcd, callbackTime);
            } // for (TaskWrapper tskWrap : tskWraps
         } else {
            Contact ctct = getContact(acct,contactIdSet);
            checkAcctCtctFlds(null, acct, ctct, null, callbackTime);
         } // if (tskWraps != null
      } // for (Account acct
   } // checkAccounts
   
   public static void checkLeads(Map<Id, TaskWrapper> taskByLeadIdMap, Set<Id> leadIdSet) {
      for (Lead ld : [Select Id, OwnerId, Name, Dialed__c, DialedUserId__c, LatestCampaign__c, LatestCampaignDate__c, LeadSource, IsConverted
                            ,NSSCallDisposition__c,  LastNSSCallDisposition__c
                            ,LatestCallTime__c
                            ,Company,LastName,FirstName,Email,Phone,Street,City,State,PostalCode
                            ,amp_dev__Referral__c
                            ,DS_Denali__Next_Call_DS__c
                            ,Lead_Stage__c, Reject_Reason__c, Recycle_Reason__c
                            ,Marketo_Lead_Rating__c, MktgId__c
                            ,Promo_Code__c,Title,NumberOfEmployees, X401K_Assets__c
                                 ,Hispanic_Ownership__c,PEOLeasing__c
                                 ,CSSR_Segment__c,SegmentationCore1__c
                            ,ProcessNotes__c
                            ,Products__c,Product_Division__c,Description,OwnedBy__c,OwnedByPrev__c
                            ,Status,Current_Prior_Method__c
                            ,TransactionId__c,Consent_to_Text__c, Consent_to_Text_Date__c, MobilePhone,Form_Fill_Date__c, BuyerZone_Lead_ID__c
                                 ,(Select Id, CallType, ActivityDate, IsReminderSet, ReminderDateTime, Subject, Type, CallDisposition
                                     From Tasks
                                    Where ActivityDate > :Date.today()
                                      and Type = :CT_CALLBACK
                                      and IsClosed = false)
                        from Lead 
                       where Id in :leadIdSet]) {
         TaskWrapper tskWrap = taskByLeadIdMap.get(ld.Id);

         Datetime callbackTime = getCallbackTime(ld.Tasks);

         Boolean recUpdated = false;

         if (tskWrap != null) {
            tskWrap.setLead(ld);
            //LeadCallDisposition__c lcd = (String.isNotBlank(tskWrap.tsk.CallDisposition) ? LeadMethods.findCallDisposition(tskWrap.tsk.CallDisposition,null) : null);
            recUpdated = checkLeadFlds(tskWrap, getLead(tskWrap), tskWrap.lcd, callbackTime);
         } else {
            recUpdated = checkLeadFlds(null, ld, null, callbackTime);
         } // if (wrapper != null
         if (recUpdated) {
            
         }
      } // for (Lead ld
   } // checkLeads
   
   public static DateTime getCallbackTime(Task[] tsks) {
      DateTime callbackTime  = null;
      // see if there's a future task
      Task futureTask = (tsks != null && !tsks.isEmpty() ? tsks[0] : null);
      if (futureTask != null) {
         callbackTime = (futureTask.ReminderDateTime != null ? futureTask.ReminderDateTime : Datetime.newInstance(futureTask.ActivityDate, Time.newInstance(8,0,0,0)));
      } // if (futureTask != null
      System.debug('getCallbackTime callbackTime='+callbackTime);
      return callbackTime;
   } // getCallbackTime
   
   // add a record to the map
   public static void addToMap(String key, TaskWrapper wrapper, Map<String,TaskWrapper[]> tskWrapperMap) {
      List<TaskWrapper> wrapperList = (tskWrapperMap.containsKey(key) ? tskWrapperMap.get(key) : new TaskWrapper[]{});
      wrapperList.add(wrapper);
      tskWrapperMap.put(key,wrapperList);
   } // addToMap
   
   // the number of hours where it's okay to use the latest campaign
   public static Integer DATE_RANGE = Integer.valueOf(Label.TaskHelper_Campaign_Check);
   public static final String TYPE_ACD='ACD Name';
   public static final String TYPE_LIST='List Name';
   public static final Set<String> EXCLUDE_CAMPAIGNS=new Set<String>(Label.TaskHelper_ExcludeCampaigns.split(','));
   public static Boolean LOG_EXCEPTIONS=(Label.TaskHelper_LogCampExceptions == 'Y');

   // check for campaigns with the specified ACD name populated
   public static void checkForCampaign(Map<String,List<TaskWrapper>> nameMap, String listType, Boolean logExceptions) {
      System.debug('checkForCampaign nameMap='+nameMap.size());
      Set<String> keySet = nameMap.keySet();
      for (String key : keySet) {
         if (EXCLUDE_CAMPAIGNS.contains(key)) {
            List<TaskWrapper> tsks = nameMap.remove(key);
            System.debug('checkForCampaign removed key '+key+' tsks='+tsks.size());
         }
      } // for (String key
      if (nameMap.isEmpty()) {
         return;
      }

      // select only active campaigns, the ones with the latest start date first (in case there are multiple campaigns with the same ACD name)
      for (Campaign camp : [Select Id, Name, ACD_Name__c, CallListName__c, LeadSource__c, Source_Type__c
                              from Campaign 
                             where IsActive=true 
                               and (ACD_Name__c in :nameMap.keySet()
                                      or CallListName__c in :nameMap.keySet()
                                      or Name in :nameMap.keySet()) 
                             order by Name asc, StartDate desc]) {
         String key = (String.isNotBlank(camp.ACD_Name__c) ? camp.ACD_Name__c 
                          : (String.isNotBlank(camp.CallListName__c) ? camp.CallListName__c : camp.Name));
         List<TaskWrapper> wrapperList = nameMap.remove(key);
         System.debug('checkForCampaign camp='+camp.Name+' key='+key+' wrapperList='+(wrapperList == null ? -1 : wrapperList.size()));
         setCampaign(wrapperList, camp);
      } // for (Campaign camp

      // if there are remaining list names, save the information
      if (logExceptions && !nameMap.isEmpty()) {
         handleExceptions(nameMap,listType);
      } // if (!nameMap.isEmpty
   } // checkForCampaign
   
   public static void setCampaign(TaskWrapper[] wrapperList, Campaign camp) {
      if (wrapperList != null && camp != null) {
         for (TaskWrapper wrapper : wrapperList) {
            //System.debug('setCampaign okToSetCamp='+wrapper.okayToSetCampaign+' camp.Id='+camp.Id);
            System.debug('camp.Id='+camp.Id);
            wrapper.addToLog('setCampaign camp.Id='+camp.Id);
            wrapper.campaignId = camp.Id;
            wrapper.campaignLeadSource = camp.LeadSource__c;
            wrapper.campaignName = camp.Name;
            //APR0112504 : Partner Referral Source for Inbound Calls
            wrapper.campaignSourceType = camp.Source_Type__c;
            //if (wrapper.okayToSetCampaign) {
            //   newCampaignMembers.add(new CampaignMember(CampaignId=camp.Id, LeadId=wrapper.leadId, ContactId=wrapper.ctctId));
            //}
         } // for (TaskWrapper wrapper
      } // if (wrapperList != null
   } // setCampaign
   
   public static void handleExceptions(Map<String,List<TaskWrapper>> nameMap, String exceptionType) {
      if (!LOG_EXCEPTIONS) {
         return;
      }
      NSSCallException__c[] updateRecs = new NSSCallException__c[]{};
      NSSCallException__c[] insertRecs = new NSSCallException__c[]{};
         
      // handle the ones that exist
      for (NSSCallException__c callException : [Select Id, Name, NbrRecs__c, Type__c from NSSCallException__c where Name in :nameMap.keySet() and Type__c=:exceptionType]) {
         List<TaskWrapper> taskList = nameMap.remove(callException.Name);
         if (taskList != null) {
            callException.NbrRecs__c += taskList.size();
            updateRecs.add(callException);
            addMessageToList(taskList,'Could not find campaign for '+callException.Name);
         } // if
      } // for

      DmlHelper.performDML2(updateRecs, DmlHelper.DML_UPDATE, 'TaskHelper', 'handleExceptions', 'update existing recs', false);
      // create any that don't currently exist      
   
      if (!nameMap.isEmpty()) {
         for (String exceptionName : nameMap.keySet()) {
            List<TaskWrapper> taskList = nameMap.get(exceptionName);
            if (taskList != null) {
               insertRecs.add(new NSSCallException__c(Name=exceptionName, Type__c=exceptionType, NbrRecs__c=taskList.size()));
               addMessageToList(taskList,'Could not find campaign for '+exceptionName);
            }
         } // for
            
         DmlHelper.performDML2(insertRecs, DmlHelper.DML_INSERT, 'TaskHelper', 'handleExceptions', 'insert new recs', false);
          
      } // if (!nameMap
      ErrorLog.checkSave();
   } // handleExceptions
   
   public static void addMessageToList(TaskWrapper[] tskWraps, String message) {
      for (TaskWrapper tskWrap : tskWraps) {
         tskWrap.addToLog(message);
      }
   }
   

   // save the campaign members
   public static void saveCampaignMembers(CampaignMember[] p_newCampaignMembers) {
      System.debug('saveCampaignMembers newCampaignMembers='+p_newCampaignMembers.size());
      if (!p_newCampaignMembers.isEmpty()) {
         // ignore exceptions that happen here?
         Database.SaveResult[] results = Database.insert(p_newCampaignMembers,false);
         //checkSaveResults('saveCampaignMembers',results,p_newCampaignMembers[0]);
      }
   } // saveCampaignMembers
   
   public static boolean checkLeadFlds(TaskWrapper tskWrap, Lead ld, LeadCallDisposition__c lcd, Datetime callbackTime) {
      String tskInfo = 'checkLeadFlds lcd='+(lcd != null ? lcd.Name+' status='+lcd.NewLeadStatus__c : 'null')+ ' ld='+(ld != null ? 'CallDisposition='+ld.LastNSSCallDisposition__c+' status='+ld.Status : 'null')+' tsk CallDisposition='+(tskWrap != null ? tskWrap.tsk.CallDisposition : 'No Task')+' callbackTime='+callbackTime;
       Lead updatedLd = new Lead();
       updatedLd.Id = ld != null ? ld.Id : null;
       if (tskWrap != null) {
         if ((lcd != null) && (ld != null) 
                   && ((ld.LastNSSCallDisposition__c != tskWrap.tsk.CallDisposition) 
                        || (ld.DS_Denali__Next_Call_DS__c != callbackTime)
                        || (String.isNotBlank(lcd.NewLeadStatus__c) && ld.Status != lcd.NewLeadStatus__c))) {
            tskWrap.dispositionChecked = true;
            updatedLd.Dialed__c=!lcd.EndOwnership__c;
            updatedLd.DialedUserId__c=tskWrap.tsk.OwnerId;
            updatedLd.NSSCallDisposition__c = tskWrap.tsk.CallDisposition;
            updatedLd.Status = (String.isNotBlank(lcd.NewLeadStatus__c) ? lcd.NewLeadStatus__c : updatedLd.Status);
            tskInfo += ' set call disposition and status on the lead dialed='+!lcd.EndOwnership__c;
            updateLeadMap.put(updatedLd.Id, updatedLd);
         }
      
         //tskInfo += '\n okayToSetCamp='+tskWrap.okayToSetCampaign+' latestCamp='+ld.LatestCampaign__c+' campaignId='+tskWrap.campaignId;
         tskInfo += '\n latestCamp='+ld.LatestCampaign__c+' campaignId='+tskWrap.campaignId;
         if (ld != null && tskWrap.campaignId != null && (ld.LatestCampaign__c == null || ld.LatestCampaign__c != tskWrap.campaignId)) {
            updatedLd.LatestCampaign__c = tskWrap.campaignId;
            updateLeadMap.put(updatedLd.Id,updatedLd); 
            newCampaignMembers.add(new CampaignMember(CampaignId=tskWrap.campaignId, LeadId=tskWrap.leadId, ContactId=tskWrap.ctctId));
         }
         tskInfo += '\n campaignLeadSource='+tskWrap.campaignLeadSource+' leadToUpdate.LeadSource='+ld.LeadSource;
         if (ld != null && String.isNotBlank(tskWrap.campaignLeadSource) && String.isBlank(ld.LeadSource)) {
            updatedLd.LeadSource = tskWrap.campaignLeadSource;
            updateLeadMap.put(updatedLd.Id,updatedLd); 
         }
         
         // set the latest call time on the lead if needed
         if (ld != null && tskWrap.tsk.CallDateTime__c != null) {
            if (ld.LatestCallTime__c == null || ld.LatestCallTime__c < tskWrap.tsk.CallDateTime__c) {
               updatedLd.LatestCallTime__c = tskWrap.tsk.CallDateTime__c;
               tskInfo += '\n Set LatestCallTime__c on ld='+updatedLd.Id;
               updateLeadMap.put(updatedLd.Id,updatedLd); 
            }
         }

         tskWrap.addToLog(tskInfo);
      } // if (tskWrap != null
      
      
      if (ld != null && ld.DS_Denali__Next_Call_DS__c != callbackTime) {
         updatedLd.DS_Denali__Next_Call_DS__c = callbackTime;
         updateLeadMap.put(updatedLd.Id, updatedLd);
      }
      Boolean changed = false;
      if (ld != null) {
         changed = updateLeadMap.containsKey(updatedLd.Id);
         StringHelper.addToProcessNotes(updatedLd,(tskInfo+'; tsk='+(tskWrap != null ? tskWrap.tsk.Id : null)));
      }
      return changed;
   } // checkLeadFlds
   
   public static boolean checkAcctCtctFlds(TaskWrapper tskWrap, Account acct, Contact ctct, LeadCallDisposition__c lcd, Datetime callbackTime) {
      System.debug('checkAcctCtctFlds callbackTime='+callbackTime);
      String tskInfo = 'checkAcctCtctFlds lcd='+(lcd != null ? lcd.Name : 'null')+' acct='+(acct != null ? acct.Id : 'null')+' callbackTime='+callbackTime;
      Contact updatedCtct = (ctct != null ? new Contact(Id = ctct.Id) : null);
      if (tskWrap != null) {
         if (lcd != null && acct != null) {
            tskWrap.dispositionChecked = true;
            tskInfo += '\n ctct='+(ctct != null ? String.valueOf(ctct.Id) : 'null');
            if (ctct != null) {
               tskInfo += ' ctct disp='+ctct.LastNSSCallDisposition__c+' tsk disp='+tskWrap.tsk.CallDisposition+' ctct status='+ctct.NSSStatus__c+' lcd status='+lcd.NewLeadStatus__c;
               if ((ctct.LastNSSCallDisposition__c != tskWrap.tsk.CallDisposition) 
                          || (String.isNotBlank(lcd.NewLeadStatus__c) && ctct.NSSStatus__c != lcd.NewLeadStatus__c) 
                          || (ctct.DS_Denali__Next_Call_DS__c != callbackTime)) {
                  updatedCtct.Dialed__c=!lcd.EndOwnership__c;
                  updatedCtct.DialedUserId__c=tskWrap.tsk.OwnerId;
                  updatedCtct.NSSCallDisposition__c = tskWrap.tsk.CallDisposition;
                  updatedCtct.NSSStatus__c = (String.isNotBlank(lcd.NewLeadStatus__c) ? lcd.NewLeadStatus__c : ctct.NSSStatus__c);
                  tskInfo += '\n set contact call disposition NSS Status='+ctct.NSSStatus__c+' End Ownership='+lcd.EndOwnership__c;
                  updateContactMap.put(updatedCtct.Id, updatedCtct);
               }
            } 
            tskInfo += '\n acct disp='+acct.LastNSSCallDisposition__c+' tsk disp='+tskWrap.tsk.CallDisposition+' acct status='+acct.NSSStatus__c+' lcd status='+lcd.NewLeadStatus__c;
            if ((acct.LastNSSCallDisposition__c != tskWrap.tsk.CallDisposition) 
                           || (String.isNotBlank(lcd.NewLeadStatus__c) && acct.NSSStatus__c != lcd.NewLeadStatus__c)
                           || (acct.DS_Denali__Next_Call_DS__c != callbackTime)) {
               acct.Dialed__c=!lcd.EndOwnership__c;
               acct.DialedUserId__c=tskWrap.tsk.OwnerId;
               acct.NSSCallDisposition__c = tskWrap.tsk.CallDisposition;
               acct.NSSStatus__c = (String.isNotBlank(lcd.NewLeadStatus__c) ? lcd.NewLeadStatus__c : acct.NSSStatus__c);
               tskInfo += '\n set account call disposition NSS Status='+acct.NSSStatus__c+' End Ownership='+lcd.EndOwnership__c;
               updateAcctMap.put(acct.Id, acct);
            }
         } // if (lcd != null &&
      
         //tskInfo += '\n okayToSetCamp='+tskWrap.okayToSetCampaign+' lastestCamp='+(ctct != null ? ctct.LatestCampaign__c : null)+' campaignId='+tskWrap.campaignId;
         tskInfo += '\n lastestCamp='+(ctct != null ? ctct.LatestCampaign__c : null)+' campaignId='+tskWrap.campaignId;
         System.debug('checkAcctCtctFlds ctct='+ctct);
         if (tskWrap.campaignId != null) {
            if (acct.LatestCampaignName__c != tskWrap.campaignName) {
               tskInfo += ' acct.LatestCampaignName__c='+tskWrap.campaignName;
               acct.LatestCampaignName__c = tskWrap.campaignName;
               updateAcctMap.put(acct.Id, acct);
            }
            
            if (ctct != null && (ctct.LatestCampaign__c == null || ctct.LatestCampaign__c != tskWrap.campaignId)) {
               updatedCtct.LatestCampaign__c = tskWrap.campaignId;
               updateContactMap.put(updatedCtct.Id,updatedCtct);
               newCampaignMembers.add(new CampaignMember(CampaignId=tskWrap.campaignId, LeadId=tskWrap.leadId, ContactId=tskWrap.ctctId));
            }
         } // if (tskWrap.okayToSetCampaign
         tskInfo += '\n campaignLeadSource='+tskWrap.campaignLeadSource+' ctct.LeadSource='+(ctct != null ? ctct.LeadSource : null);
         if (ctct != null && String.isNotBlank(tskWrap.campaignLeadSource) && String.IsBlank(ctct.LeadSource)) {
            updatedCtct.LeadSource = tskWrap.campaignLeadSource;
            updateContactMap.put(updatedCtct.Id,updatedCtct);
         }

         if (ctct != null && tskWrap.tsk.CallDateTime__c != null) {
            if (ctct.LatestCallTime__c == null || ctct.LatestCallTime__c < tskWrap.tsk.CallDateTime__c) {
               updatedCtct.LatestCallTime__c = tskWrap.tsk.CallDateTime__c;
               tskInfo += '\n Set LatestCallTime__c on ctct='+ctct.Id;
               updateContactMap.put(updatedCtct.Id, updatedCtct);
            }
         }

         if (acct != null && tskWrap.tsk.CallDateTime__c != null) {
            if (acct.LatestCallTime__c == null || acct.LatestCallTime__c < tskWrap.tsk.CallDateTime__c) {
               acct.LatestCallTime__c = tskWrap.tsk.CallDateTime__c;
               tskInfo += '\n Set LatestCallTime__c on acct='+acct.Id;
               updateAcctMap.put(acct.Id, acct);
            }
         }


         tskWrap.addToLog(tskInfo);
      } // if (tskWrap != null
      //System.debug('checkAcctCtctFlds callbackTime='+callbackTime+' ctct matches='+(ctct.DS_Denali__Next_Call_DS__c != callbackTime));

      if (ctct != null && (ctct.DS_Denali__Next_Call_DS__c != callbackTime)) {
         updatedCtct.DS_Denali__Next_Call_DS__c = callbackTime;
         updateContactMap.put(updatedCtct.Id, updatedCtct);
      }
      //System.debug('checkAcctCtctFlds callbackTime='+callbackTime+' acct matches='+(acct.DS_Denali__Next_Call_DS__c != callbackTime));
      if (acct != null && (acct.DS_Denali__Next_Call_DS__c != callbackTime)) {
         acct.DS_Denali__Next_Call_DS__c = callbackTime;
         updateAcctMap.put(acct.Id, acct);
      }
      Boolean changed = false;
      if (ctct != null) {
         changed = changed || updateContactMap.containsKey(ctct.Id);
         StringHelper.addToProcessNotes(ctct,(tskInfo+'; tsk='+(tskWrap != null ? tskWrap.tsk.Id : null)));
      }
      if (acct != null) {
         changed = changed || updateAcctMap.containsKey(acct.Id);
         StringHelper.addToProcessNotes(acct,(tskInfo+'; tsk='+(tskWrap != null ? tskWrap.tsk.Id : null)));
      }
      return changed;
   } // checkAcctCtctFlds

   public static void performUpdate(List<Sobject> objectList, String methodName, String key) {
      System.debug('performUpdate methodName='+methodName+' key='+key+' nbrRecs='+objectList.size());
      if (!objectList.isEmpty()) {
         DmlHelper.performDML2(objectList, DmlHelper.DML_UPDATE, 'TaskHelper', methodName, key, true);
      }
   } // performUpdate
   
   // delete the Prospect Ownership Callback records with these task ids
   public static void deletePOCallbacks(Id[] taskIdsToDelete) {
      System.debug('deletePOCallbacks taskIdsToDelete='+taskIdsToDelete.size());
      try {
         delete [select Id From ProspectOwnershipCallback__c where TaskId__c in :taskIdsToDelete];
      } catch (Exception e) {
         System.debug('deletePOCallbacks exception='+e);
         //ErrorLog.logError('TaskHelper', 'deletePOCallbacks', 'delete callback records', taskIdsToDelete[0], e);
      } // try
   } // deletePOCallbacks
   

   @future
   public static void setPOCallbacksFuture(Set<Id> tskIdSet) {
      System.debug('setPOCallbacksFuture tskIdSet='+tskIdSet.size());
      Task[] tsks = [Select Id, OwnerId, WhoId, WhatId, AccountId
                           ,ReminderDateTime
                       From Task
                      Where Id in :tskIdSet];
      setPOCallbacks(tsks);
   } // setPOCallbacksFuture
   
   public static void setPOCallbacks(Task[] callbackTasks) {
      System.debug('setPOCallbacks callbackTasks='+callbackTasks.size());
      // callbacks attached to tasks
      Map<Id,List<Task>> callbackMap = new Map<Id,List<Task>>();
      
      for (Task tsk : callbackTasks) {
         Id keyId = (tsk.AccountId != null ? tsk.AccountId : (tsk.WhoId != null ? tsk.WhoId : null));
         if (keyId != null) {
            System.debug('setPOCallbacks keyId='+keyId);
            setTaskInMap(tsk, keyId, callbackMap);
         }
      } // for (Task tsk : callbackTasks
      
      // so we can make sure we only create one record for each task id
      Map<Id,ProspectOwnershipCallback__c> upsertCallbackMap = new Map<Id,ProspectOwnershipCallback__c>();
      
      // retrieve the PO records - only open and prospecting or workable?
      for (Prospect_Ownership__c[] poList : [Select Id
                                                   ,Decision_Maker__c
                                                   ,Lead__c
                                                   ,NSR_Name__c
                                                   ,Prospect_Client__c
                                               From Prospect_Ownership__c
                                              Where EndDate__c = null
                                                and (Lead__c in :callbackMap.keySet()
                                                     or Prospect_Client__c in :callbackMap.keySet()
                                                     or Decision_Maker__c in :callbackMap.keySet())
                                                     // not sure if we need to check these or just check for open ownership
                                                and ((ProspectingStart__c != null and ProspectingEnd__c = null)
                                                     or (WorkableStart__c != null and WorkableEnd__c = null)
                                                    )
                                              order by StartDate__c desc
                                              ]) {
                                              
         for (Prospect_Ownership__c po : poList) {
            Id key1 = null;
            Id key2 = null;
            if (po.Prospect_Client__c != null) {
               key1 = po.Prospect_Client__c;
               key2 = po.Decision_Maker__c;
            } else if (po.Lead__c != null) {
               key1 = po.Lead__c;
            }
            
            System.debug('setPOCallbacks key1='+key1+' key2='+key2);
            if (key1 != null) {
               // check for each id
               List<Task> taskList = callbackMap.get(key1);
               if (taskList == null && key2 != null) {
                  taskList = callbackMap.get(key2);
               }
               if (taskList != null) {
                  for (Task tsk : taskList) {
                     // only so
                     if (po.NSR_Name__c == tsk.OwnerId && !upsertCallbackMap.containsKey(tsk.Id)) {
                        
                        ProspectOwnershipCallback__c newPoCallback = new ProspectOwnershipCallback__c(Callback_Date_Time__c=tsk.ReminderDateTime
                                                                         ,Prospect_Ownership__c=po.Id
                                                                         ,TaskId__c=tsk.Id);
                        upsertCallbackMap.put(tsk.Id,newPoCallback);
                     }
                  } // for (Task tsk : taskList
               } // if (taskList != null
            } // if (key1 != null
            
         } // for (Prospect_Ownership__c po
      } // for (Prospect_Ownership__c[] poList
      
      if (!upsertCallbackMap.isEmpty()) {
         try {
            upsert upsertCallbackMap.values() ProspectOwnershipCallback__c.TaskId__c;
         } catch (Exception e) {
            ProspectOwnershipCallback__c callback = upsertCallbackMap.values()[0];
            ErrorLog.logError('TaskHelper', 'setPOCallbacks', 'upserting callbacks', callback.TaskId__c, e, callback);
         }
      }
   } // setPOCallbacks
   
   public static void setTaskInMap(Task tsk, Id keyId, Map<Id,List<Task>> callbackMap) {
      List<Task> taskList = callbackMap.get(keyId);
      if (taskList == null) {
         taskList = new List<Task>();
         callbackMap.put(keyId, taskList);
      }
      taskList.add(tsk);
   } // setTaskInMap
   
   //APR0159917--Touchpoint
  public static Map<Id,Id> maptpIdcadenceId=new Map<Id,Id>();
  public static Map<Id,Integer> mapcadenceIdstepNo=new Map<Id,Integer>();
  public static Map<Id,Boolean> mapcadenceIdoutcomeRequired=new Map<Id,Boolean>();

   public static void checkForCadence(TaskWrapper[] tskWraps) {
      Id[] queryIds = new Id[]{};
      Id[] ownerIds = new Id[]{};
      TaskWrapper[] cadenceTskWraps = new TaskWrapper[]{};
      List<Touchpoint_Update__e> tpUpdateEventList = new List<Touchpoint_Update__e>();
      for (TaskWrapper tskWrap : tskWraps) {
         if ((tskWrap.lcd != null && tskWrap.lcd.CadenceEndTouchpoint__c || String.isNotBlank(tskWrap.lcd.CadenceCloseCAR__c)) || tskWrap.tsk.Type == 'Text') {
            tskWrap.addToLog('Checking for Cadence Record');
            // see if we can find a touchpoint for these records
            cadenceTskWraps.add(tskWrap);
            ownerIds.add(tskWrap.tsk.OwnerId);
            if (tskWrap.tsk.WhoId != null) {
               queryIds.add(tskWrap.tsk.WhoId);
            }
            if (tskWrap.tsk.WhatId != null) {
               queryIds.add(tskWrap.tsk.WhatId);
            }
            if (tskWrap.tsk.AccountId != null) {
               queryIds.add(tskWrap.tsk.AccountId);
            }
            
         } // if (tskWrap.lcd != null
      } // for (TaskWrapper tskWrap
      
      // log against the first TaskWrapper
      tskWraps[0].addToLog('checkForCadence tskWraps='+tskWraps.size()+' cadenceTskWraps='+cadenceTskWraps.size()+' queryIds='+queryIds.size()+' ownerIds='+ownerIds.size());
     
      if (!queryIds.isEmpty()) {
         Map<Id,Cadence_Touchpoint__c> tpMap = WorkQueueController.getOpenTouchpoints(queryIds, ownerIds);
         //APR0159917--Touchpoint--Start
         getStepDetails(tpMap);
         //APR0159917--Touchpoint--End
         tskWraps[0].addToLog('checkForCadence tpMap='+tpMap.size());
         if (!tpMap.isEmpty()) {
            Cadence_Assignment_Record__c[] updateCars = new Cadence_Assignment_Record__c[]{};
            Cadence_Touchpoint__c[] updateTPs = new Cadence_Touchpoint__c[]{};
            Lead[] updateLds = new Lead[]{};
            Contact[] updateCtcts = new Contact[]{};
            
            for (TaskWrapper tskWrap : cadenceTskWraps) {
               Cadence_Touchpoint__c tp = null;
               // remove the touchpoints from the map so they're only processed once.
               if (tskWrap.tsk.AccountId != null) {
                  tp=tpMap.remove(tskWrap.tsk.AccountId);
               }
               String log='After acct check found tp='+(tp != null);
               if (tp == null && tskWrap.tsk.WhatId != null) {
                  tp=tpMap.remove(tskWrap.tsk.WhatId);
               }
               log +=', after WhatId found tp='+(tp != null);
               if (tp == null && tskWrap.tsk.WhoId != null) {
                  tp=tpMap.remove(tskWrap.tsk.WhoId);
               }
               log +=', after WhoId found tp='+(tp != null);
               tskWrap.addToLog(log);
               System.debug('checkForCadence tsk='+tskWrap.tsk.Subject+' tp found='+(tp != null));
               if (tp != null) {
                  handleTouchpoint(tskWrap,tp,updateCars,updateTPs,tpUpdateEventList);
               }
            } // for (TaskWrapper tskWrap : cadenceTskWraps
            
            DmlHelper.performDml2(updateCars, DmlHelper.DML_UPDATE, 'TaskHelper', 'checkForCadence', 'Update CARs', false);
            DmlHelper.performDml2(updateTPs, DmlHelper.DML_UPDATE, 'TaskHelper', 'checkForCadence', 'Update Touchpoinsts', false);
            
             User runningUser = UserHelper.getRunningUser();
             String testUserId = Label.WebexTesterId;
             if(runningUser.Id == testUserId){
                 List<Database.SaveResult> results = EventBus.publish(tpUpdateEventList);
             }
                 

            /*
            if (!updateLds.isEmpty()) {
               // make sure the triggers run
               TriggerMethods.forceTriggerSet.add('LeadBefore');
               TriggerMethods.forceTriggerSet.add('LeadAfter');
               DG_LMF_Service.ALREADY_RAN_SET.clear();
               DmlHelper.performDml2(updateLds, DmlHelper.DML_UPDATE, 'TaskHelper', 'checkForCadence', 'Update Leads', false);
               TriggerMethods.forceTriggerSet.clear();
            }
            if (!updateCtcts.isEmpty()) {
               ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
               ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
               DG_LMF_Service.ALREADY_RAN_SET.clear();
               DmlHelper.performDml2(updateCtcts, DmlHelper.DML_UPDATE, 'TaskHelper', 'checkForCadence', 'Update Contacts', false);
            }
            */
            ErrorLog.checkSave();
         } // if (!tpMap.isEmpty
      } // if (!queryIds.isEmpty
   } // checkForCadence
   
   public static void handleTouchpoint(TaskWrapper tskWrap, Cadence_Touchpoint__c tp
                                      ,Cadence_Assignment_Record__c[] updateCars, Cadence_Touchpoint__c[] updateTPs,List<Touchpoint_Update__e> tpUpdateEventList) {
      tskWrap.addToLog('CloseCar='+tskWrap.lcd.CadenceCloseCAR__c+' EndTouchpoint='+tskWrap.lcd.CadenceEndTouchpoint__c);
      // close the touchpoint for either of the cases
      System.debug('handleTouchpoint StepType__c='+tp.StepType__c+'CloseCar='+tskWrap.lcd.CadenceCloseCAR__c+' EndTouchpoint='+tskWrap.lcd.CadenceEndTouchpoint__c);
      // if we're not ending the CAR, only close the touchpoint from a task if the current touchpoint is a Call.
      
      if ((((tskWrap.lcd.CadenceEndTouchpoint__c && (tp.StepType__c == 'Call' || tp.StepType__c == 'Text')) || String.isNotBlank(tskWrap.lcd.CadenceCloseCAR__c)) && tp.CarRecord__r.IsReferralSource__c == false)) {
         Task updateTsk = (updateTskMap.containsKey(tskWrap.tsk.Id) ? updateTskMap.get(tskWrap.tsk.Id) : new Task(Id=tskWrap.tsk.Id));
         //  system.debug('touchpointStepType__c'+tp.StepType__c+'updateTskMap.get(tskWrap.tsk.Id)).Subject'+(updateTskMap.get(tskWrap.tsk.Id)).Subject+'(updateTskMap.containsKey(tskWrap.tsk.Id)'+(updateTskMap.containsKey(tskWrap.tsk.Id).size());
         // mark the task so we don't update it again
         updateTsk.CAR__c=tp.CarRecord__c;
         updateTskMap.put(updateTsk.Id,updateTsk);
         System.debug('inside CadenceEndTouchpoint__c::');
         Cadence_Touchpoint__c updateTP = new Cadence_Touchpoint__c(Id=tp.Id);
         //APR0159917 --Change in condition checking the last step--Start
         if(tp.Step_Number__c<mapcadenceIdstepNo.get(maptpIdcadenceId.get(tp.Id)) || (tp.Step_Number__c==mapcadenceIdstepNo.get(maptpIdcadenceId.get(tp.Id)) && mapcadenceIdoutcomeRequired.get(maptpIdcadenceId.get(tp.Id))==false)){
         updateTP.Close_Date__c = tskWrap.tsk.ActivityDate;
         updateTP.Status__c = 'Closed';
         updateTP.LastUpdateMethod__c = 'TaskHelper.handleTouchpoint';
         updateTP.ActivityId__c = tskWrap.tsk.Id;
         }
         else{
               updateTP.Status__c = 'Open';
         }
         //APR0159917 --Change in condition checking the last step--End
         updateTPs.add(updateTP);
          tskWrap.addToLog('Closing Touchpoint='+updateTP.Id);
          //Create Platform Event
              Touchpoint_Update__e carEvent = new Touchpoint_Update__e(
                  TouchpointId__c = updateTP.Id);
              tpUpdateEventList.add(carEvent);
          }
      if (String.isNotBlank(tskWrap.lcd.CadenceCloseCAR__c) && tp.CarRecord__r.IsReferralSource__c == false){
                            
          Cadence_Assignment_Record__c car = tp.CarRecord__r;
          //APR0159917 --Change in condition checking the last step
         if (car != null && tp.Step_Number__c<mapcadenceIdstepNo.get(maptpIdcadenceId.get(tp.Id))) {             
             tskWrap.addToLog('Closing CAR record='+car.Id+' Reason='+tskWrap.lcd.CadenceCloseCAR__c);
             car.Closed__c = true;
             car.Started__c = true;
             if(car.Start_Date__c == null){
                 car.Start_Date__c = Date.today();
             }
             car.Close_Date__c = tskWrap.tsk.ActivityDate;
            car.CloseReason__c = tskWrap.lcd.CadenceCloseCAR__c;
            car.Rep_Closed__c = true;
            car.Status__c = 'Closed';
             updateCars.add(car);
              //Commenting out for now -- Jermaine 
             //Create Platform Event
             //tpUpdateEventList.add(new Touchpoint_Update__e(TouchpointId__c = tp.Id));
            String log = 'MarketingStage='+tskWrap.lcd.MarketingStage__c;
            if (String.isNotBlank(tskWrap.lcd.MarketingStage__c)) {
               Contact ctct = getContact(tskWrap);
               Lead ld = (ctct == null ? getLead(tskWrap) : null);
               log += ', hasCtct='+(ctct != null)+' hasLead='+(ld != null);
               if (ctct != null) {
                  ctct.Contact_Stage__c=tskWrap.lcd.MarketingStage__c;
                  setStage(ctct,tskWrap.lcd.MarketingStage__c, tskWrap.lcd.CadenceCloseCAR__c);
                  updateContactMap.put(ctct.Id,ctct);
               } else if (ld != null && !ld.IsConverted) {
                  ld.Lead_Stage__c=tskWrap.lcd.MarketingStage__c;
                  setStage(ld,tskWrap.lcd.MarketingStage__c, tskWrap.lcd.CadenceCloseCAR__c);
                  updateLeadMap.put(ld.Id,ld);
               }
            } // if (String.isNotBlank(tskWrap.lcd.MarketingStage__c
            tskWrap.addToLog(log);
         } // if (car != null

         setPartRefeason(updateLeadMap, updateContactMap);      
      }
   } // handleTouchpoint
   
   public static void setStage(SObject rec, String stageName, String reasonCode) {
      //Recycle_Reason__c
      //Reject_Reason__c
      if (stageName == 'Reject') {
         rec.put('Reject_Reason__c',reasonCode);
      } else if (stageName == 'Recycle') {
         rec.put('Recycle_Reason__c',reasonCode);
      }
   } // setStage
  
   //public static PartnerReferral__c[] partRefsToUpdate = new PartnerReferral__c[]{};
   public static void setPartRefeason(Map<Id,Lead> updateLeadMap, Map<Id,Contact> updateContactMap ){
      //APR0122715 check for updateLeadMap and updateContactMap and if stage = recycle/reject -- update updatePartRefMap with the reject/recycle reason and date
      Map<Id, String> idToRejectMap = new Map<Id, String>();
      Map<Id, String> idToRecycleMap = new Map<Id, String>();
      List<Id> recIds = new List<Id>();
      
      
      if(!updateLeadMap.isEmpty()){
         for(Lead ld: updateLeadMap.values()){
            if(ld.Lead_Stage__c == 'Recycle'){ 
               recIds.add(ld.Id);
               idToRecycleMap.put(ld.Id, ld.Recycle_Reason__c);
            }
            if(ld.Lead_Stage__c == 'Reject'){
               recIds.add(ld.Id);
               idToRejectMap.put(ld.Id, ld.Reject_Reason__c);
            }
         }
         if(!idToRecycleMap.isEmpty() ||!idToRejectMap.isEmpty()){
            DG_LMF_Service.updatePartRefReason(recIds, idToRejectMap, idToRecycleMap, updatePartRefMap); 
         } 
      }
      if(!updateContactMap.isEmpty()){
         for(Contact con: updateContactMap.values()){
            if(con.Contact_Stage__c == 'Recycle'){ 
               recIds.add(con.Id);
               idToRecycleMap.put(con.Id, con.Recycle_Reason__c);
            }
            if(con.Contact_Stage__c == 'Reject'){
               recIds.add(con.Id);
               idToRejectMap.put(con.Id, con.Reject_Reason__c);
            }
         }
         if(!idToRecycleMap.isEmpty() ||!idToRejectMap.isEmpty()){
            DG_LMF_Service.updatePartRefReason(recIds, idToRejectMap, idToRecycleMap, updatePartRefMap); 
         } 
      }
      //System.debug('partRefsToUpdate:'+partRefsToUpdate);
   }
    public static void updateTaskStatus(List<Task> tsks){//, Map<Id,Task> oldMap){
        for (Task tsk : tsks) {
      //   Task oldTsk = (oldMap != null ? oldMap.get(tsk.Id) : null);
            if(tsk.Type!= 'Text'){
                tsk.Type = 'Text';
            }
            if(tsk.Type == 'Text' && tsk.Subject == outgoingLabel){
                tsk.Status = 'Completed';
                tsk.CallDisposition = 'Text Eligible Close Task';
            }
        }
    }

//APR0159917--Touchpoint--Start

public static void getStepDetails(Map<Id,Cadence_Touchpoint__c> tpMap){

   if(!tpMap.isEmpty()){
      for(Id tpId:tpMap.keySet()){
         maptpIdcadenceId.put(tpId,tpMap.get(tpId).Cadence__c);
         
         //mapcadenceIdstepNo.put();
      }
   }
   //Getting all the Cadence ids
   Set<Id> setCadenceId=new Set<Id>();
   if(!maptpIdcadenceId.isEmpty()){
      for(Id tpId:maptpIdcadenceId.keySet()){
         setCadenceId.add(maptpIdcadenceId.get(tpId));
      }
   }

   //Querying Cadence--CadenceStep (Parent to Child)
   List<Cadence__c> lstCadence=new List<Cadence__c>();
   if(!setCadenceId.isEmpty()){
      lstCadence=[Select id,Outcome_Required__c,(Select id from Cadence_Steps__r) from Cadence__c where id In:setCadenceId];
   }

   //Inserting into Map(CadenceId and CadencestepSize)
   if(!lstCadence.isEmpty()){
      for(Cadence__c cadence:lstCadence){
         mapcadenceIdstepNo.put(cadence.id,cadence.Cadence_Steps__r.size());
         mapcadenceIdoutcomeRequired.put(cadence.id,cadence.Outcome_Required__c);
      }
   }


}
//APR0159917--Touchpoint--End






} // class TaskHelper