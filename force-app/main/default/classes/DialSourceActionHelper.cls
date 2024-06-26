/** Trigger for the DialSource object
 *
 * History
 * -------
   12/12/2018 Dan Carmen            Created.
   12/18/2018 Dan Carmen            Add some additional change fields
   01/31/2019 Dan Carmen            Add logic to pop a weblead to a user
   03/08/2019 Dan Carmen            Add DS_Denali__Custom_Object_ID__c
   03/13/2019 Dan Carmen            Add change for Inbound Call - Agent
   03/14/2019 Dan Carmen            Add check for Task in the custom object id - can't use that for the WhatId
   10/02/2019 Dan Carmen            Add logic to handle task record type by campaign

*/
public with sharing class DialSourceActionHelper {
   
   public static Boolean UPDATE_TASK=(Label.DialSourceAction_UpdateTasks == 'Y');
   
   public static Set<Id> actionIdsProcessedSet = new Set<Id>();
   
   public static void processTrigger(DS_Denali__DialSource_Action__c[] recs, Map<Id,DS_Denali__DialSource_Action__c> oldMap) {

      Schema.RecordTypeInfo rtInbound = CallCenterHelper.getInboundRt();
      Id rtInboundId = rtInbound.getRecordTypeId();
      if (recs != null) {
         Map<Id,DS_Denali__DialSource_Action__c> checkTaskMap = new Map<Id,DS_Denali__DialSource_Action__c>();
         for (DS_Denali__DialSource_Action__c rec : recs) {
            if (rec.Id == null || !actionIdsProcessedSet.contains(rec.Id)) {
               DS_Denali__DialSource_Action__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
               if (Trigger.isBefore) {
                  if (rec.RecordTypeId == rtInboundId && String.isNotBlank(rec.DS_Denali__Phone__c)
                       && (String.isBlank(rec.InboundCallerId__c) || oldRec == null || (rec.DS_Denali__Phone__c != oldRec.DS_Denali__Phone__c))) {
                     rec.InboundCallerId__c = StringHelper.formatPhoneNumber(rec.DS_Denali__Phone__c);
                  }
                  if (rec.CallHour__c == null) {
                     rec.CallHour__c = DateTime.now().format(Label.CallTime_format,Label.CallTime_TimeZone);
                  }
                  if (oldRec != null) {
                     // we're storing these because I'll want to check for change in another trigger. This might be slight overkill. 
                     rec.InboundCallerIdOld__c = oldRec.InboundCallerId__c;
                     rec.CallCampaignOld__c = oldRec.DS_Denali__Call_Campaign__c;
                     rec.InboundDNISNameOld__c = oldRec.DS_Denali__Inbound_DNIS_Name__c;
                  } // if (oldRec != null
               } // if (Trigger.isBefore
               if (Trigger.isAfter) {
                  actionIdsProcessedSet.add(rec.Id);
                  // if the record type changes, opportunity is linked, disposition changes - check the task
                  // anytime the record changes update the task.
                  checkTaskMap.put(rec.Id,rec);
               } // if (Trigger.isAfter
            } // if (rec.Id == null ||
         } // for (DS_Denali__DialSource_Action__c rec
         System.debug('processTrigger UPDATE_TASK='+UPDATE_TASK+' checkTaskMap='+checkTaskMap.size());
         if (UPDATE_TASK && !checkTaskMap.isEmpty()) {
            checkIfTaskMatches(checkTaskMap);
         }
      } // if (recs != null
       
   } // processTrigger
   
   public static void checkIfTaskMatches(Map<Id,DS_Denali__DialSource_Action__c> checkTaskMap) {
      Task[] tsks = [Select Id, RecordTypeId, Subject, WhoId, WhatId, CallObject, CallDisposition, CallType, Type
                           ,DS_Denali__DialSource_Action__c
                       From Task
                      Where DS_Denali__DialSource_Action__c in :checkTaskMap.keySet()];
      System.debug('checkIfTaskMatches tsks='+tsks.size());
      Task[] updateTsks = new Task[]{};
      Map<Id, Schema.RecordTypeInfo> dsaRtMap = DS_Denali__DialSource_Action__c.getSobjectType().getDescribe().getRecordTypeInfosById();
      Map<String, Schema.RecordTypeInfo> taskRtMap = Task.getSobjectType().getDescribe().getRecordTypeInfosByName();
      Map<String,Campaign> campMap = getCampaignMap(checkTaskMap.values());
      
      DS_Denali__DialSource_Action__c[] updateActions = new DS_Denali__DialSource_Action__c[]{};
      
      for (Task tsk : tsks) {
         // remove from the map to handle the ones we find
         DS_Denali__DialSource_Action__c action = checkTaskMap.remove(tsk.DS_Denali__DialSource_Action__c);
         System.debug('checkIfTaskMatches tsk='+tsk.Subject+' action found='+(action != null));
         if (action != null) {
            if (!action.Task_Created__c) {
               System.debug('checkIfTaskMatches setting Task_Created__c to true');
               DS_Denali__DialSource_Action__c updateAction = new DS_Denali__DialSource_Action__c(Id=action.Id, Task_Created__c=true);
               updateActions.add(updateAction);
            }
            Boolean changed = false;
            // check inbound/outbound
            Schema.RecordTypeInfo rtInfo = dsaRtMap.get(action.RecordTypeId);
            if (rtInfo != null) {
               if (TaskHelper.checkTaskCallType(tsk, rtInfo.getName(), action.DS_Denali__Inbound_DNIS_Name__c)) {
                  changed = true;
               }
            }
            Schema.RecordTypeInfo taskRt = getTaskRt(action, campMap, taskRtMap);
            if (taskRT != null && taskRT.getRecordTypeId() != tsk.RecordTypeId) {
               tsk.RecordTypeId = taskRT.getRecordTypeId();
               changed = true;
            }
            System.debug('checkIfTaskMatches rtInfo='+(rtInfo != null ? rtInfo.getName() : 'Not Found')+' changed='+changed);
            if (String.isNotBlank(action.DS_Denali__Call_Disposition__c) && tsk.CallDisposition != action.DS_Denali__Call_Disposition__c) {
               tsk.CallDisposition = action.DS_Denali__Call_Disposition__c;
               changed = true;
            }
            
            if (checkWhoWhat(tsk,action)) {
               changed = true;
            }

            System.debug('checkIfTaskMatches tsk='+tsk.Subject+' changed='+changed);
            if (changed) {
               updateTsks.add(tsk);
            }
         } // if (action != null)
      } // for (Task tsk
      DmlHelper.performDml2(updateTsks, DmlHelper.DML_UPDATE, 'DialSourceActionHelper', 'checkIfTaskMatches', 'Update Tasks', false);
      
      System.debug('checkIfTaskMatches checkTaskMap='+checkTaskMap.size());
      // if there are any actions left, the task wasn't created
      if (!checkTaskMap.isEmpty()) {
         Task[] newTasks = new Task[]{};
         for (DS_Denali__DialSource_Action__c action : checkTaskMap.values()) {
            if (!action.Task_Created__c) {
               DS_Denali__DialSource_Action__c updateAction = new DS_Denali__DialSource_Action__c(Id=action.Id, Task_Created__c=true);
               updateActions.add(updateAction);
            }
            Task tsk = new Task(ActivityDate=Date.today(), Priority='Normal', Status='Completed', DS_Denali__DialSource_Action__c=action.Id);
            tsk.CallDisposition = action.DS_Denali__Call_Disposition__c;
            tsk.Description = action.DS_Denali__Notes__c;
            tsk.OwnerId = action.DS_Denali__Owner__c;
            tsk.Subject = action.DS_Denali__Subject__c;
            Schema.RecordTypeInfo rtInfo = dsaRtMap.get(action.RecordTypeId);
            if (rtInfo != null) {
               tsk.Type = rtInfo.getName();
               TaskHelper.checkTaskCallType(tsk, rtInfo.getName(), action.DS_Denali__Inbound_DNIS_Name__c);
            }
            Schema.RecordTypeInfo taskRt = getTaskRt(action, campMap, taskRtMap);
            if (taskRT != null) {
               tsk.RecordTypeId = taskRT.getRecordTypeId();
            }
            checkWhoWhat(tsk,action);
            newTasks.add(tsk);
         } // for (DS_Denali__DialSource_Action__c action
         
         System.debug('checkIfTaskMatches newTasks='+newTasks.size());
         DmlHelper.performDml2(newTasks, DmlHelper.DML_INSERT, 'DialSourceActionHelper', 'checkIfTaskMatches', 'Insert Tasks', false);
      } // if (!checkTaskMap.isEmpty
      
      DmlHelper.performDml2(updateActions, DmlHelper.DML_UPDATE, 'DialSourceActionHelper', 'checkIfTaskMatches', 'Update DSA records', false);
      ErrorLog.checkSave();
      
   } // checkIfTaskMatches
   
   public static Schema.RecordTypeInfo getTaskRt(DS_Denali__DialSource_Action__c action, Map<String,Campaign> campMap, Map<String, Schema.RecordTypeInfo> taskRtMap) {
      Campaign camp = checkForCampaign(action, campMap);
      Schema.RecordTypeInfo rtInfo = ((camp != null && String.isNotBlank(camp.DestinationTaskRecordType__c)) ? taskRtMap.get(camp.DestinationTaskRecordType__c) : null);
      System.debug('getTaskRt rtInfo='+(rtInfo != null ? rtInfo.getName() : 'Not Found'));
      return rtInfo;
   } // getTaskRt
   
   public static Campaign checkForCampaign(DS_Denali__DialSource_Action__c action, Map<String,Campaign> campMap) {
      Campaign camp = null;
      if (String.isNotBlank(action.DS_Denali__Inbound_DNIS_Name__c)) {
         camp = campMap.get(action.DS_Denali__Inbound_DNIS_Name__c);
      }
      if (camp == null && String.isNotBlank(action.DS_Denali__Call_Campaign__c)) {
         camp = campMap.get(action.DS_Denali__Call_Campaign__c);
      }
      System.debug('checkForCampaign camp='+(camp != null ? camp.Name : 'No Campaign'));
      return camp;
   } // checkForCampaign
   
   public static Map<String,Campaign> getCampaignMap(DS_Denali__DialSource_Action__c[] actions) {
      Set<String> campKeySet = new Set<String>();
      for (DS_Denali__DialSource_Action__c action : actions) {
         if (String.isNotBlank(action.DS_Denali__Inbound_DNIS_Name__c)) {
            campKeySet.add(action.DS_Denali__Inbound_DNIS_Name__c);
         }
         if (String.isNotBlank(action.DS_Denali__Call_Campaign__c)) {
            campKeySet.add(action.DS_Denali__Call_Campaign__c);
         }
      } // for (DS_Denali__DialSource_Action__c action
      Map<String,Campaign> campMap = new Map<String,Campaign>();
      if (!campKeySet.isEmpty()) {
         Campaign[] camps = [Select Id, Name, ACD_Name__c, CallListName__c, LeadSource__c
                                   ,Destination__c, DestinationTaskRecordType__c
                              from Campaign 
                             where IsActive=true 
                               and (ACD_Name__c in :campKeySet
                                      or CallListName__c in :campKeySet
                                      or Name in :campKeySet) 
                               and DestinationTaskRecordType__c != null
                             order by Name asc, StartDate desc];
         for (Campaign camp : camps) {
            campMap.put(camp.Name, camp);
            if (String.isNotBlank(camp.ACD_Name__c)) {
               campMap.put(camp.ACD_Name__c, camp);
            }
            if (String.isNotBlank(camp.CallListName__c)) {
               campMap.put(camp.CallListName__c, camp);
            }
         }
      } // if (!campKeySet
      
      return campMap;
   } // getCampaignMap
   
   public static Set<String> EXCLUDE_PREFIXES = new Set<String>(Label.DialSource_ExcludePrefixes.split(','));
   
   public static Boolean checkWhoWhat(Task tsk, DS_Denali__DialSource_Action__c action) {
      Boolean changed = false;
      // check for a task in the custom object id
      Id customObjectId = action.DS_Denali__Custom_Object_ID__c;
      String prefix = (customObjectId != null ? ((String)customObjectId).left(3) : null);
      // check if the object can be associated to the whatId in the task.
      if (prefix != null && EXCLUDE_PREFIXES.contains(prefix)) {
         customObjectId = null;
      }
      Id whatId = (customObjectId != null ? customObjectId 
                     : (action.DS_Denali__Opportunity__c != null ? action.DS_Denali__Opportunity__c
                        : (action.DS_Denali__Account__c != null ? action.DS_Denali__Account__c
                            : (action.DS_Denali__Case__c != null ? action.DS_Denali__Case__c : null))));
      Id whoId = (action.DS_Denali__Contact__c != null ? action.DS_Denali__Contact__c
                        : ((action.DS_Denali__Account__c == null && action.DS_Denali__Lead__c != null) ? action.DS_Denali__Lead__c : null));
      System.debug('checkWhoWhat whatId='+whatId+' tsk.WhatId='+tsk.WhatId);
      System.debug('checkWhoWhat whoId='+whoId+' tsk.WhoId='+tsk.WhoId);
      if (tsk.WhatId != whatId) {
         tsk.WhatId = whatId;
         changed = true;
      }
      
      if (tsk.WhoId != whoId) {
         tsk.WhoId = whoId;
         changed = true;
      }
      return changed;
   } // checkWhoWhat
    
   /*
   • ActivationTime: This variable represents when you want the record to be presented. The typical value is NOW(), which will send the record immediately.
• objID: A field reference whose value should be [Object].Id
• phoneNum: The primary phone number field being used on the record object.
• Token: The DialSource account-specific API token, provisioned by heading to DS Management → Settings → API Token, as above.
• objName: The display name of the object record (i.e. [Lead].FirstName + [Lead].LastName)
• PriorityScore: An number determined by your process that determines the record's priority within the queue. Higher number equates to higher priority, and therefore earlier delivery.
• userID: The Salesforce ID of the user who will receive the record, if delivering to an individual user.
• groupID: The ID of the Agent Group that will receive the record, if delivering to a group. Get the Group ID in DS Management → Agent Groups
• userOnly: used in conjunction with userID. If set to true, then it will only send to the user specified in userID. If False, it will look for an agent group
• isGlobal: If true, the record will be distributed to the next available agent on the dialer across the entire organization.
*/

   // if there isn't a group id, set the value in this variable to be 0
   public static Integer GROUP_ID=Integer.valueOf(Label.DialSource_RTPQ_GroupId);
   
   public static Boolean POP_UP_ACTIVE=Label.DialSource_PopUpActive == 'Y';
   
   public static void addPopToUser(String objId, String objName, String phoneNum, Id userIdToSendTo) {
      if (POP_UP_ACTIVE && objId != null && objName != null && phoneNum != null && userIdToSendTo != null) {
         DS_Denali.DSDenaliRTPQPBVariables vars = new DS_Denali.DSDenaliRTPQPBVariables();
         // first 6 fields in the list are required
         vars.token = Label.DialSource_API_Token;
         vars.activationTime = Datetime.now(); 
         vars.objId = objId;
         vars.phoneNum = phoneNum;
         vars.PriorityScore = 50; // not sure if this should be a more dynamic setting
         vars.objName = objName;
         // these are not required
         vars.orgId = UserInfo.getOrganizationId();  // this is a value in the class - I assume it's needed?
         vars.userId = userIdToSendTo;
         vars.userOnly = (GROUP_ID > 0); 
         vars.isGlobal = false;
         vars.groupID = (GROUP_ID > 0 ? GROUP_ID : null);
         dsVarsToSend.add(vars);
         
      } else {
         System.debug('popToUser Not enough info to add pop record POP_UP_ACTIVE='+POP_UP_ACTIVE+' objId='+objId+' objName='+objName+' phoneNum='+phoneNum+' userIdToSendTo='+userIdToSendTo);
      } // if (objId != null && objName != null
      System.debug('addPopToUser dsVarsToSend='+dsVarsToSend);
   } // addPopToUser
   
   public static DS_Denali.DSDenaliRTPQPBVariables[] dsVarsToSend = new DS_Denali.DSDenaliRTPQPBVariables[]{};

   public static void checkPopToUser() {
      System.debug('checkPopToUser dsVarsToSend='+dsVarsToSend);
      if (!dsVarsToSend.isEmpty()) {
         try {
            DS_Denali.DSDenaliRTPQPBVariables[] newList = new DS_Denali.DSDenaliRTPQPBVariables[]{};
            newList.addAll(dsVarsToSend);
            DS_Denali.DSDenaliRTPQInvocablePB.setup(newList);
            // so this doesn't get triggered by the same set.
            dsVarsToSend.clear();
         } catch (Exception e) {
            ErrorLog.logError('DialSourceActionHelper', 'checkPopToUser', 'Trying to pop record', null, e, null, true);
         }
      }
   } // checkPopToUser
   
   
} // class DialSourceActionHelper