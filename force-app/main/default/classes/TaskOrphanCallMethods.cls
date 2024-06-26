/** Trigger on the TaskOrphanCall__c object.
 *
 * History
 * -------
   03/31/2017 Dan Carmen        Created.
   12/10/2018 Dan Carmen        Set to work with DialSource
   04/13/2021 Brandon Vidro     Modified to work with Drift Chats/Meetings
   04/17/2021 Dan Carmen        Added call to queryActivityEmailMap
   
*/
public without sharing class TaskOrphanCallMethods {
   
   public static Boolean SKIP_TRIGGER=false;

   // do we want to search tasks if there's nothing connected to them?
   public static Boolean SEARCH_TASKS = Label.TaskHelper_SearchTasks == 'Y';
   public static Boolean PROCESS_DRIFT_TASKS = Label.TaskOrphan_ProcessDriftTasks == 'Y';

   public static void handleTrigger(TaskOrphanCall__c[] newRecs, Map<Id, TaskOrphanCall__c> oldMap) {
      if (SEARCH_TASKS) {
         Id[] taskIds = new Id[]{};
         Id[] eventIds = new Id[]{};
         Set<Id> orphanIdSet = new Set<Id>();
         Set<Id> orphanEvtIdSet = new Set<Id>();
         for (TaskOrphanCall__c toc : newRecs) {
            if (String.isBlank(toc.MatchId__c) && String.isNotBlank(toc.TaskId__c)) {
               taskIds.add((Id)toc.TaskId__c);
               orphanIdSet.add(toc.Id);
            }
            if (String.isNotBlank(toc.TaskId__c) && toc.Drift_Activity__c) {
               taskIds.add((Id)toc.TaskId__c);
               orphanIdSet.add(toc.Id);                
            }
            if (String.isNotBlank(toc.EventId__c) && toc.Drift_Activity__c) {
                eventIds.add((Id)toc.EventId__c);
                orphanEvtIdSet.add(toc.Id);                
            }
         } // for (TaskOrphanCall__c toc
         if (!orphanIdSet.isEmpty()) {
            checkProcessIds(orphanIdSet, taskIds);
         }
         if (!orphanEvtIdSet.isEmpty()) {
             checkProcessIdsEvts(orphanEvtIdSet, eventIds);
         }
      } // if (SEARCH_TASKS
   } // handleTrigger
   
   public static void checkProcessIds(Set<Id> orphanIdSet, Id[] taskIds) {
      if (System.isFuture() || System.isBatch()) {
         processIds(orphanIdSet, taskIds);
      } else {
         processIdsFuture(orphanIdSet, taskIds);
      }
   } // checkProcessIds
   
   @future
   public static void processIdsFuture(Set<Id> orphanIdSet, Id[] taskIds) {
      processIds(orphanIdSet, taskIds);
   } // processIdsFuture
   
   public class TskWrapper {
      public TaskOrphanCall__c toc;
      public Task tsk;
   } // classTskWrapper
    
    public static void checkProcessIdsEvts(Set<Id> orphanIdSet, Id[] eventIds) {
        if (System.isFuture() || System.isBatch()) {
            processEvtIds(orphanIdSet, eventIds);
        } else {
            processIdsFutureEvts(orphanIdSet, eventIds);
        }
    } // checkProcessIds
    
    @future
    public static void processIdsFutureEvts(Set<Id> orphanIdSet, Id[] eventIds) {
        processEvtIds(orphanIdSet, eventIds);
    } // processIdsFuture
    
    public class EvtWrapper {
        public TaskOrphanCall__c toc;
        public Event evt;
    } // classTskWrapper
   
   public static void processIds(Set<Id> orphanIdSet, Id[] taskIds) {
      System.debug('processIds orphanIdSet='+orphanIdSet.size()+' taskIds='+taskIds.size());
      TaskOrphanCall__c[] tocs = [Select Id, Name
                                        ,MatchId__c
                                        ,NbrAttempts__c
                                        ,Phone__c
                                        ,Email__c
                                        ,TaskId__c
                                    From TaskOrphanCall__c
                                   Where Id in :orphanIdSet];
                   
      Map<Id,Task> taskMap = TaskHelper.queryTaskMap(taskIds);
      Id[] whoIds = new Id[]{};
      for (Task tsk : taskMap.values()) {
          if (tsk.WhoId != null) {
              whoIds.add(tsk.WhoId);
          }
      }
      Map<Id, String> emailMap = TaskHelper.queryActivityEmailMap(whoIds);
      Map<String, TskWrapper[]> tskByPhoneMap = new Map<String, TskWrapper[]>();
      Map<String, TskWrapper[]> tskByEmailMap = new Map<String, TskWrapper[]>();
      DateTime earliestCallTime = DateTime.now();
            
      for (TaskOrphanCall__c toc : tocs) {
         Task tsk = taskMap.get(toc.TaskId__c);
         String email = emailMap.get(tsk.WhoId);
         if (tsk != null) {
            toc.NbrAttempts__c = (toc.NbrAttempts__c == null ? 0 : toc.NbrAttempts__c) + 1;
            
            if (toc.Phone__c == null && tsk.DS_Denali__DialSource_Action__r != null && tsk.DS_Denali__DialSource_Action__r.DS_Denali__Phone__c != null) {
               toc.Phone__c = tsk.DS_Denali__DialSource_Action__r.DS_Denali__Phone__c;
            }
            if (toc.Email__c == null && tsk.Subject.contains(Label.Drift_Task_Subject) && (tsk.Type.contains(Label.TrackRecord_Chat) || tsk.Type.contains(Label.Drift_Task_Type)) && email != null) {
               toc.Email__c = email; 
            }
            String phoneKey = Utilities.removeExtraChars(toc.Phone__c, Utilities.ALL_NUMBERS);
            String emailNew = '';
            if(String.isNotBlank(toc.Email__c)) {
            	emailNew = (String)toc.Email__c;
            }
            if (String.isNotBlank(phoneKey)) {
               phoneKey = phoneKey.left(10);
            }
            // make sure we have the right sized string
            if (phoneKey != null && phoneKey.length() == 10) {
               TskWrapper wrap = new TskWrapper();
               wrap.toc = toc; 
               wrap.tsk = tsk;
               TskWrapper[] wraps = (tskByPhoneMap.containsKey(phoneKey) ? tskByPhoneMap.get(phoneKey) : new TskWrapper[]{});
               wraps.add(wrap);
               tskByPhoneMap.put(phoneKey, wraps);
               if (tsk.CallDateTime__c != null && tsk.CallDateTime__c < earliestCallTime) {
                  earliestCallTime = tsk.CallDateTime__c;
               }
            } // if (phoneKey.length() == 10
            if (email != null && String.isNotBlank(email)) {
               TskWrapper wrap = new TskWrapper();
               wrap.toc = toc; 
               wrap.tsk = tsk;
               TskWrapper[] wraps = (tskByEmailMap.containsKey(email) ? tskByEmailMap.get(email) : new TskWrapper[]{});
               wraps.add(wrap);
               tskByEmailMap.put(email, wraps);
               if (tsk.CallDateTime__c != null && tsk.CallDateTime__c < earliestCallTime) {
                  earliestCallTime = tsk.CallDateTime__c;
               }               
            } 
         } // if (tsk != null
      } // for (TaskOrphanCall__c toc
      if (!tskByPhoneMap.isEmpty()) {
         searchForRelatedTaskRecords(earliestCallTime, tskByPhoneMap, tocs);
      }
      if (!tskByEmailMap.isEmpty()) {
         searchForRelatedTaskRecordsByEmail(earliestCallTime, tskByEmailMap, tocs);
      }
      SKIP_TRIGGER = true;
      DmlHelper.performDML2(tocs, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedTaskRecords', 'Update Orphan Record', true);

   } // processIds
    
    public static void processEvtIds(Set<Id> orphanEvtIdSet, Id[] eventIds) {
      System.debug('processIds orphanEvtIdSet='+orphanEvtIdSet.size()+' eventIds='+eventIds.size());
      TaskOrphanCall__c[] tocs = [Select Id, Name
                                        ,MatchId__c
                                        ,NbrAttempts__c
                                        ,Phone__c
                                        ,Email__c
                                        ,TaskId__c
										,EventId__c
                                    From TaskOrphanCall__c
                                   Where Id in :orphanEvtIdSet];
                   
      Map<Id,Event> eventMap = queryEventMap(eventIds);
      Id[] whoIds = new Id[]{};
      for (Event evt : eventMap.values()) {
         if (evt.WhoId != null) {
            whoIds.add(evt.WhoId);
         }
      }
      Map<Id, String> emailMap = TaskHelper.queryActivityEmailMap(whoIds);
      Map<String, EvtWrapper[]> evtByPhoneMap = new Map<String, EvtWrapper[]>();
      Map<String, EvtWrapper[]> evtByEmailMap = new Map<String, EvtWrapper[]>();
      DateTime earliestCallTime = DateTime.now();
            
      for (TaskOrphanCall__c toc : tocs) {
         Event evt = eventMap.get(toc.EventId__c);
         String email = emailMap.get(evt.WhoId);
         if (evt != null) {
            toc.NbrAttempts__c = (toc.NbrAttempts__c == null ? 0 : toc.NbrAttempts__c) + 1;

            if (toc.Email__c == null && evt.Subject == Label.Drift_Event_Subject) {
               toc.Email__c = email; 
            }
            String emailNew = '';
            if(toc.Email__c != null && String.isNotBlank(toc.Email__c)) {
            	emailNew = (String)toc.Email__c;
            }
            if (email != null && String.isNotBlank(email)) {
               EvtWrapper wrap = new EvtWrapper();
               wrap.toc = toc; 
               wrap.evt = evt;
               EvtWrapper[] wraps = (evtByEmailMap.containsKey(email) ? evtByEmailMap.get(email) : new EvtWrapper[]{});
               wraps.add(wrap);
               evtByEmailMap.put(email, wraps);         
            } 
         } // if (evt != null
      } // for (TaskOrphanCall__c toc
      if (!evtByEmailMap.isEmpty()) {
         searchForRelatedEvtRecordsByEmail(earliestCallTime, evtByEmailMap, tocs);
      }
      SKIP_TRIGGER = true;
      DmlHelper.performDML2(tocs, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedEvtRecordsByEmail', 'Update Orphan Record', true);

   } // processIds
   
   // do we log the search results in the error log object?
   public static Boolean LOG_TASK_SEARCH = Label.TaskHelper_LogTaskSearch=='Y';

   public static ErrorLog__c errLog;
   public static void addToErrorDescription(String descToAdd) {
      if (errLog != null) {
         errLog.Description__c = ((String.isNotBlank(errLog.Description__c) ? errLog.Description__c+'\n' : '') 
                                      + descToAdd).left(ErrorLog.DESCRIPTION_SIZE);
      }
   } // addToErrorDescription

   public static List<List<SObject>> TEST_QUERY_RESULTS = new List<List<SObject>>();
    
   public static void searchForRelatedTaskRecordsByEmail(DateTime earliestCallTime, Map<String,TskWrapper[]> tskByEmailMap, TaskOrphanCall__c[] tocs) {
      String emailStr = '';
      for (String emailKey : tskByEmailMap.keySet()) {
         emailStr += (String.isNotBlank(emailStr) ? ' OR ' : '')+'"'+emailKey+'"';
      }
      
      if (String.isNotBlank(emailStr)) {
         TaskOrphanCall__c[] updateOrphans = new TaskOrphanCall__c[]{};
         Task[] updateTasks = new Task[]{};
         Lead[] updateLeads = new Lead[]{};
         Contact[] updateContacts = new Contact[]{};
         List<List<SObject>> queryResults;
          
            DateTime queryTime = earliestCallTime.addHours(-1);
            queryResults = [FIND :emailStr IN EMAIL FIELDS RETURNING
                            Lead(Id, OwnerId, Email, Company, Street, City, State, PostalCode, FirstName, LastName, Phone, NumberOfEmployees, Frequency__c, OwnedByPrev__c, LeadSource, MktgId__c,
                                 Current_Prior_Method__c, LastModifiedDate, CreatedDate, RecordTypeId, Bank_Product_Of_Interest__c where 
                                 IsConverted=false and MktgId__c != null order by LastModifiedDate desc)
                            ,Contact(Id, AccountId, LastModifiedDate, CreatedDate, Email, MktgId__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, Name, Phone
                                     where HR_Person_Id__c = null and MktgId__c != null
                                     order by LastModifiedDate desc)
                           ];
                   
         if (!queryResults.isEmpty()) {
            if (!tskByEmailMap.isEmpty()) {
            	checkResultsEmail((queryResults.size() >= 1 ? queryResults[0] : new Sobject[]{})
                              , ObjectHelper.OBJECT_LEAD, tskByEmailMap, updateOrphans, updateTasks, updateLeads, updateContacts);
            }
            if (!tskByEmailMap.isEmpty()) {
                checkResultsEmail((queryResults.size() >= 2 ? queryResults[1] : new Sobject[]{})
                              , ObjectHelper.OBJECT_CONTACT, tskByEmailMap, updateOrphans, updateTasks, updateLeads, updateContacts);
            }
            if (!updateTasks.isEmpty()) {
               TaskHelper.SKIP_TRIGGERS=true;
               DmlHelper.performDML2(updateTasks, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedTaskRecordsByEmail', 'Update Tasks', true);
            }
            if (!updateLeads.isEmpty()) {
               TriggerMethods.SKIP_TRIGGERS=true;
               DmlHelper.performDML2(updateLeads, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedTaskRecordsByEmail', 'Update Leads', true);
            }
            if (!updateContacts.isEmpty()) {
               ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
               ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
               DmlHelper.performDML2(updateContacts, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedTaskRecordsByEmail', 'Update Contacts', true);
            }             
         }
      } // if (String.isNotBlank(emailStr
   } // searchForRelatedTaskRecordsByEmail
    
  public static void searchForRelatedEvtRecordsByEmail(DateTime earliestCallTime, Map<String,EvtWrapper[]> evtByEmailMap, TaskOrphanCall__c[] tocs) {
      String emailStr = '';
      for (String emailKey : evtByEmailMap.keySet()) {
         emailStr += (String.isNotBlank(emailStr) ? ' OR ' : '')+'"'+emailKey+'"';
      }
      
      if (String.isNotBlank(emailStr)) {
         TaskOrphanCall__c[] updateOrphans = new TaskOrphanCall__c[]{};
         Event[] updateEvents = new Event[]{};
         Lead[] updateLeads = new Lead[]{};
         Contact[] updateContacts = new Contact[]{};
         List<List<SObject>> queryResults;
          
            DateTime queryTime = earliestCallTime.addHours(-1);
            // order by the last modified date to use the latest first.
            queryResults = [FIND :emailStr IN EMAIL FIELDS RETURNING
                            Lead(Id, OwnerId, Email, Company, Street, City, State, PostalCode, FirstName, LastName, Phone, NumberOfEmployees, Frequency__c, Current_Prior_Method__c, LeadSource, MktgId__c,
                                 LastModifiedDate, CreatedDate, Bank_Product_Of_Interest__c, RecordTypeId, OwnedByPrev__c
                                 where IsConverted=false and MktgId__c != null order by LastModifiedDate desc)
                            ,Contact(Id, AccountId, LastModifiedDate, CreatedDate, Email, MktgId__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, Name, Phone
                                     where HR_Person_Id__c = null and MktgId__c != null
                                     order by LastModifiedDate desc)
                           ];
                   
         if (!queryResults.isEmpty()) {
            if (!evtByEmailMap.isEmpty()) {
            	checkResultsEmailEvents((queryResults.size() >= 1 ? queryResults[0] : new Sobject[]{})
                              , ObjectHelper.OBJECT_LEAD, evtByEmailMap, updateOrphans, updateEvents, updateLeads, updateContacts);
            }
            if (!evtByEmailMap.isEmpty()) {
                checkResultsEmailEvents((queryResults.size() >= 2 ? queryResults[1] : new Sobject[]{})
                              , ObjectHelper.OBJECT_CONTACT, evtByEmailMap, updateOrphans, updateEvents, updateLeads, updateContacts);
            }
            if (!updateEvents.isEmpty()) {
               DmlHelper.performDML2(updateEvents, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedEvtRecordsByEmail', 'Update Events', true);
            }
            if (!updateLeads.isEmpty()) {
               TriggerMethods.SKIP_TRIGGERS=true;
               DmlHelper.performDML2(updateLeads, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedEvtRecordsByEmail', 'Update Leads', true);
            }
            if (!updateContacts.isEmpty()) {
               ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
               ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
               DmlHelper.performDML2(updateContacts, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedEvtRecordsByEmail', 'Update Contacts', true);
            }             
         }
      } // if (String.isNotBlank(emailStr
   } // searchForRelatedEvtRecordsByEmail

   public static void searchForRelatedTaskRecords(DateTime earliestCallTime, Map<String,TskWrapper[]> tskByPhoneMap, TaskOrphanCall__c[] tocs) {
      // create an ErrorLog__c record to record what's happening.
      if (LOG_TASK_SEARCH) {
         errLog = new ErrorLog__c(ClassName__c='TaskOrphanCallMethods',MethodName__c='searchForRelatedTaskRecords',CodeKey__c='LOG_DATA', BatchSize__c=tskByPhoneMap.size(), NbrSuccess__c=0);
      }
      String phoneStr = '';
      for (String phoneKey : tskByPhoneMap.keySet()) {
         phoneStr += (String.isNotBlank(phoneStr) ? ' OR ' : '')+'"'+phoneKey+'"';
      }
      addToErrorDescription('Earliest Call Time='+earliestCallTime.format('M/d/yyyy HH:mm:ss'));
      
      if (String.isNotBlank(phoneStr)) {
         TaskOrphanCall__c[] updateOrphans = new TaskOrphanCall__c[]{};
         Task[] updateTasks = new Task[]{};
             
         List<List<SObject>> queryResults;
          
            DateTime queryTime = earliestCallTime.addDays(-2);
            // order by the last modified date to use the latest first.
            queryResults = [FIND :phoneStr IN PHONE FIELDS RETURNING
                            Lead(Id, Phone, MobilePhone, LastModifiedDate where IsConverted=false and LastModifiedDate >= :queryTime order by LastModifiedDate desc)
                            ,Contact(Id, AccountId, Phone, HomePhone, MobilePhone, OtherPhone, LastModifiedDate 
                                            where LastModifiedDate >= :queryTime
                                              and HR_Person_Id__c = null    // exclude employee contacts 
                                            order by LastModifiedDate desc)
                            ,Account(Id, Phone, LastModifiedDate 
                                            where LastModifiedDate >= :queryTime
                                              and Name != :Label.Paychex_Account
                                            order by LastModifiedDate desc)
                           ];
                   
         if (!queryResults.isEmpty()) {
            
            checkResults((queryResults.size() >= 1 ? queryResults[0] : new Sobject[]{})
                              , ObjectHelper.OBJECT_LEAD, tskByPhoneMap, updateOrphans, updateTasks);
            if (!tskByPhoneMap.isEmpty()) {
               checkResults((queryResults.size() >= 2 ? queryResults[1] : new Sobject[]{})
                              , ObjectHelper.OBJECT_CONTACT, tskByPhoneMap, updateOrphans, updateTasks);
            }
            if (!tskByPhoneMap.isEmpty()) {
               checkResults((queryResults.size() >= 3 ? queryResults[2] : new Sobject[]{})
                              , ObjectHelper.OBJECT_ACCOUNT, tskByPhoneMap, updateOrphans, updateTasks);
            }

            if (!updateTasks.isEmpty()) {
               TaskHelper.SKIP_TRIGGERS=true;
               DmlHelper.performDML2(updateTasks, DmlHelper.DML_UPDATE, 'TaskOrphanCallMethods', 'searchForRelatedTaskRecords', 'Update Tasks', true);
            }

         }
      } // if (String.isNotBlank(phoneStr
      if (LOG_TASK_SEARCH && errLog != null) {
         errLog.NbrFailure__c = tskByPhoneMap.size();
         Database.insert(errLog,false);
      }
   } // searchForRelatedTaskRecords
   
   public static void checkResults(SObject[] objectList, String objectType, Map<String,TskWrapper[]> tskByPhoneMap
                                             , TaskOrphanCall__c[] updateOrphans, Task[] updateTasks) {
      addToErrorDescription('objectType='+objectType+' objectList='+objectList+' tskByPhoneMap='+tskByPhoneMap.size());
                                                 
      for (SObject obj : objectList) {
         TskWrapper[] wraps = checkForWraps(obj, 'Phone', tskByPhoneMap);
         if (wraps == null && (objectType == ObjectHelper.OBJECT_LEAD || objectType == ObjectHelper.OBJECT_CONTACT)) {
            wraps = checkForWraps(obj, 'MobilePhone', tskByPhoneMap);
         }
         if (wraps == null && objectType == ObjectHelper.OBJECT_CONTACT) {
            wraps = checkForWraps(obj, 'HomePhone', tskByPhoneMap);
         }
         if (wraps == null && objectType == ObjectHelper.OBJECT_CONTACT) {
            wraps = checkForWraps(obj, 'OtherPhone', tskByPhoneMap);
         }
            if (wraps != null) {
               for (TskWrapper wrap : wraps) {
                  wrap.tsk.Description = 'TaskOrphanCallMethods Found match by phone on '+objectType;
                  if (objectType == ObjectHelper.OBJECT_LEAD) {
                     wrap.tsk.WhoId = obj.Id;
                  } else if (objectType == ObjectHelper.OBJECT_CONTACT) {
                     Contact ctct = (Contact)obj;
                     wrap.tsk.WhoId = ctct.Id;
                     wrap.tsk.WhatId = ctct.AccountId;
                  } else if (objectType == ObjectHelper.OBJECT_ACCOUNT) {
                     wrap.tsk.WhatId = obj.Id;
                  }
                  addToErrorDescription('   tsk='+wrap.tsk.Id+' match='+obj.Id);
                  updateTasks.add(wrap.tsk);
                  wrap.toc.MatchId__c = obj.Id;
                  updateOrphans.add(wrap.toc);
               } // for (TskWrapper wrap
               errLog.NbrSuccess__c++;
            } // if (wraps != null
      } // for (Object obj
   } // checkResults
    
   public static Boolean chatterSent = false;
   public static Boolean chatterSentTsk = false;
   public static Boolean chatterSentEvt = false;
   public static Boolean chatterAdded = false;
   public static Boolean chatterAddedEvt = false;
   public static Boolean chatterAddedTsk = false;
   
    public static void checkResultsEmail(SObject[] objectList, String objectType, Map<String,TskWrapper[]> tskByEmailMap
                                             , TaskOrphanCall__c[] updateOrphans, Task[] updateTasks, Lead[] updateLeads, Contact[] updateContacts) {
      System.debug('checkResultsEmail objectList='+objectList.size());
      if(!PROCESS_DRIFT_TASKS)  {
      	return;
      }                                         
      Id mentionId = null;
      Id mentionIdTask = null;                                          
      List<String> chatterMsgs = new List<String>();
      List<String> chatterMsgsTsks = new List<String>();                                           
      List<Id> mentionIds = new List<Id>(); 
      List<Id> mentionIdsTsks = new List<Id>();
                                         
      for (SObject obj : objectList) {
         TskWrapper[] wraps = checkForWrapsEmail(obj, 'Email', tskByEmailMap);
         System.debug('checkResultsEmail wraps='+(wraps == null ? -1 : wraps.size()));
         if (wraps == null && (objectType == ObjectHelper.OBJECT_LEAD || objectType == ObjectHelper.OBJECT_CONTACT)) {
            wraps = checkForWrapsEmail(obj, 'Email', tskByEmailMap);
         }
            if (wraps != null) {
               for (TskWrapper wrap : wraps) {
                  wrap.tsk.Description += '\nTaskOrphanCallMethods Found match by email on '+objectType;
                  if (objectType == ObjectHelper.OBJECT_LEAD) {
                      Lead ld = (Lead)obj;
                      wrap.tsk.WhoId = obj.Id;
                      wrap.tsk.RecordTypeId = RecordTypeHelper.getRecordType('NSS Task','Task').getRecordTypeId(); 
                      if(ld.OwnerId != null && ld.OwnerId == Label.Drift_Chat_Queue_Id) {
                          ld.OwnerId = wrap.tsk.OwnerId;
                          if(!chatterAdded){
                              mentionId = ld.OwnerId;
                              mentionIds.add(mentionId);
                              String chatterMsg = 'This Lead record has been assigned to you.\n';
                              chatterMsg += ChatterMentionPost.buildChatterMessage(ld);
                              chatterMsgs.add(chatterMsg);
                              chatterAdded = true;
						  }
                          updateLeads.add(ld);
                      }
                      if(!chatterAddedTsk) {
                      	mentionIdTask= wrap.tsk.OwnerId;
                        mentionIdsTsks.add(mentionIdTask);
                        String chatterMsgTsk = 'This Task record has been assigned to you.\n';
						chatterMsgTsk += ChatterMentionPost.buildChatterMessage(ld);
						chatterMsgsTsks.add(chatterMsgTsk);
                        chatterAddedTsk = true;
                      }
                  } else if (objectType == ObjectHelper.OBJECT_CONTACT) {
                      Contact ctct = (Contact)obj;
                      wrap.tsk.WhoId = obj.Id;
                      wrap.tsk.RecordTypeId = RecordTypeHelper.getRecordType('NSS Task','Task').getRecordTypeId(); 
                      if(!chatterAddedTsk) {
                      	mentionIdTask= wrap.tsk.OwnerId;
                        mentionIdsTsks.add(mentionIdTask);
                        String chatterMsgTsk = 'This Task record has been assigned to you.\n';
						chatterMsgTsk += ChatterMentionPost.buildChatterMessage(ctct);
						chatterMsgsTsks.add(chatterMsgTsk);
                        chatterAddedTsk = true;
                      }
                  }
                  updateTasks.add(wrap.tsk);
                  wrap.toc.MatchId__c = obj.Id;
                  updateOrphans.add(wrap.toc);
                  if(!chatterSentTsk){
                  	ChatterMentionPost.createChatterMentionPost(wrap.tsk.Id, mentionIdsTsks, chatterMsgsTsks, false, true);
           	 		chatterSentTsk = true; 
                  }
               } // for (TskWrapper wrap
            } // if (wraps != null
          	if(!chatterSent) {
          		ChatterMentionPost.createChatterMentionPost(obj.Id, mentionIds, chatterMsgs, false, false);
           	 	chatterSent = true;
            }
      } // for (Object obj   
   } // checkResults
    
   public static void checkResultsEmailEvents(SObject[] objectList, String objectType, Map<String,EvtWrapper[]> evtByEmailMap
                                             , TaskOrphanCall__c[] updateOrphans, Event[] updateEvents, Lead[] updateLeads, Contact[] updateContacts) {
      Id mentionIdEvent = null;                                          
      List<String> chatterMsgsEvts = new List<String>();                                           
      List<Id> mentionIdsEvts = new List<Id>(); 
      
      if(!PROCESS_DRIFT_TASKS)  {
      	return;
      }                                               
      for (SObject obj : objectList) {
         EvtWrapper[] wraps = checkForWrapsEmailEvent(obj, 'Email', evtByEmailMap);
         if (wraps == null && (objectType == ObjectHelper.OBJECT_LEAD || objectType == ObjectHelper.OBJECT_CONTACT)) {
            wraps = checkForWrapsEmailEvent(obj, 'Email', evtByEmailMap);
         }
            if (wraps != null) {
               for (EvtWrapper wrap : wraps) {
                  wrap.evt.Description += '\nTaskOrphanCallMethods Found match by email on '+objectType;
                  if (objectType == ObjectHelper.OBJECT_LEAD) {
                      Lead ld = (Lead)obj;
                      wrap.evt.WhoId = obj.Id;
                      wrap.evt.RecordTypeId = ld.RecordTypeId;
                          if(!chatterAddedEvt){
                              mentionIdEvent= wrap.evt.OwnerId;
                              mentionIdsEvts.add(mentionIdEvent);
                              String chatterMsgEvt = 'This Event record has been assigned to you.\n';
                              chatterMsgEvt += ChatterMentionPost.buildChatterMessage(ld);
                              chatterMsgsEvts.add(chatterMsgEvt);
                              chatterAddedEvt = true;
                          }
                  } else if (objectType == ObjectHelper.OBJECT_CONTACT) {
                      Contact ctct = (Contact)obj;
                      wrap.evt.WhoId = obj.Id;
                      if(!chatterAddedEvt) {
                      	mentionIdEvent= wrap.evt.OwnerId;
                        mentionIdsEvts.add(mentionIdEvent);
                        String chatterMsgEvt = 'This Event record has been assigned to you.\n';
						chatterMsgEvt += ChatterMentionPost.buildChatterMessage(ctct);
						chatterMsgsEvts.add(chatterMsgEvt);
                        chatterAddedEvt = true;
                      }
                  } 
                  updateEvents.add(wrap.evt);
                  wrap.toc.MatchId__c = obj.Id;
                  updateOrphans.add(wrap.toc);
                  if(!chatterSentEvt){
                  	ChatterMentionPost.createChatterMentionPost(wrap.evt.Id, mentionIdsEvts, chatterMsgsEvts, false, true);
           	 		chatterSentEvt = true; 
                  }
               } // for (TskWrapper wrap
            } // if (wraps != null
      } // for (Object obj   
   } // checkResults
   
   public static TskWrapper[] checkForWraps(SObject obj, String phoneFld, Map<String,TskWrapper[]> tskByPhoneMap) {
      TskWrapper[] wraps = null;
      String phoneNbr = (String)obj.get(phoneFld);
      String phoneKey = (String.isNotBlank(phoneNbr) ? Utilities.removeExtraChars(phoneNbr, Utilities.ALL_NUMBERS).left(10) : null);
      if (String.isNotBlank(phoneKey)) {
         wraps = tskByPhoneMap.remove(phoneKey);
      }
      if (wraps != null) {
         addToErrorDescription('TaskOrphanCallMethods checkForWraps found match on '+phoneFld+' for number '+phoneNbr+' match='+obj.Id);
      }
      return wraps;
   }
       
   public static TskWrapper[] checkForWrapsEmail(SObject obj, String emailFld, Map<String,TskWrapper[]> tskByEmailMap) {
      TskWrapper[] wraps = null;
      String emailKey = (String)obj.get(emailFld);
      if (String.isNotBlank(emailKey)) {
         wraps = tskByEmailMap.remove(emailKey);
      }
      return wraps;
   } // checkForWraps
    
  public static EvtWrapper[] checkForWrapsEmailEvent(SObject obj, String emailFld, Map<String,EvtWrapper[]> evtByEmailMap) {
        EvtWrapper[] wraps = null;
        String emailKey = (String)obj.get(emailFld);
        if (String.isNotBlank(emailKey)) {
            wraps = evtByEmailMap.remove(emailKey);
        }
        return wraps;
    } // checkForWraps
    
   public static Map<Id,Event> queryEventMap(Id[] eventIds) {
        
      DateTime queryDate = DateTime.now().addDays(-TaskHelper.TASK_NBR_DAYS);
      Map<Id,Event> eventMap = new Map<Id,Event>([Select Id, WhoId, WhatId, AccountId, OwnerId
                             ,ActivityDate
                             ,RecordTypeId
                             ,RecordType.Id,RecordType.Name
                             ,CreatedDate
                             ,Subject
                             ,Description
                             ,ReminderDateTime
                             ,Type
                         from Event
                        Where Id in :eventIds
                          and CreatedDate >= :queryDate 
                          ]);
      return eventMap;
   } // queryEventMap
    /*
   public static Map<Id,String> queryEventEmailMap(Id[] eventIds) {
        
      DateTime queryDate = DateTime.now().addDays(-TaskHelper.TASK_NBR_DAYS);
      Map<Id,String> emailMap = new Map<Id,String>();
      List<Event> evts = new List<Event>();
      List<Lead> leads = new List<Lead>();
      List<Contact> contacts = new List<Contact>();
      Set<Id> whoIds = new Set<Id>();
      evts = [Select Id, WhoId, WhatId, AccountId, OwnerId
                             ,ActivityDate
                             ,RecordTypeId
                             ,RecordType.Id,RecordType.Name
                             ,CreatedDate
                             ,Subject
                             ,Description
                             ,ReminderDateTime
                             ,Type
                         from Event
                        Where Id in :eventIds
                          and CreatedDate >= :queryDate];
      if(evts != null) {
          for(Event evt: evts) {
              whoIds.add(evt.WhoId);
          }   
      }
      leads = [Select Id, Email from Lead where Id in :whoIds];
      contacts = [Select Id, Email from Contact where Id in :whoIds];
      if(leads != null) {
          for(Lead ld: leads) {
              emailMap.put(ld.Id, ld.Email);
          }
      }
      if(contacts != null) {
          for(Contact ct: contacts) {
              emailMap.put(ct.Id, ct.Email);
          }
      }
      return emailMap;
   } // queryTaskEmailMap
   */
} // class TaskOrphanCallMethods