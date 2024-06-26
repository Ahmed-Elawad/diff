/* Methods to process on the Oasis Sync object

  History
  -------
  04/04/2019 Dan Carmen        Created
  10/17/2019 Dan Carmen        Changed to not set ownership.
  10/21/2019 Dan Carmen        Only set the Lead Stage if the ownedby field is also set
  
 */
public without sharing class OasisSyncHelper implements TriggerInterface2 {
   
   /*
   public static final String SOURCE_OASIS='Oasis';
   public static final String SOURCE_PAYX='Paychex';
   public static final String SYNC_RECORD_ID='Record Id Update';
   public static final String SYNC_NEW='New Record';
   public static final String SYNC_UPDATE='Record Update';
   public static final String SYNC_LEAD_CONVERTED='Lead Converted';
   public static final String SYNC_DUPE_RESULT='Duplicate Result';

   public static ErrorLog__c log = null;
   
   public static Boolean BEFORE_EXECUTED=false;
   public static Boolean AFTER_EXECUTED=false;
   
   public static Boolean SKIP_TRIGGER=false;
   
   // if we don't want the trigger to run for specific users, set them comma separated (full name) in the label.
   // should leave at least one name (even fake name) in the Label
   public static Set<String> SKIP_NAME_SET=new Set<String>(label.OasisSync_SkipUsers.split(','));
   
   // this is so we can change it for testing purposes
   public static String CONNECTION_USER='Connection User';
   
   public static Boolean isRunningUserConnectionUser() {
      Boolean isConnectionUser = (UserInfo.getName() == CONNECTION_USER);
      return isConnectionUser;
   } // isRunningUserConnectionUser

   public static Boolean skipTrigger() {
      Boolean skip = (SKIP_TRIGGER || System.isFuture()
           || (Trigger.IsBefore && BEFORE_EXECUTED)
           || (Trigger.isAfter && AFTER_EXECUTED));
      return skip;
   } // skipTrigger
   
   public static Boolean USE_SAVE_QUEUEABLE=(Test.isRunningTest() ? false  : (Label.OasisSync_UseSaveQueueable == 'Y'));
   
   public static OasisSync__c[] recsForQueueable = new OasisSync__c[]{};
   
   public static Apex_Batch_Control__c getBatchControl() {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance('OasisSyncHelper');
      return abc;
   } // getBatchControl

   public static void processRecords(OasisSync__c[] recs, Map<Id,OasisSync__c> oldMap) {
      Boolean isConnectionUser = isRunningUserConnectionUser();
      System.debug('processRecords skipTrigger()='+skipTrigger()+' recs='+recs.size()+' isBefore='+Trigger.isBefore+' isAfter='+Trigger.isAfter);
      if (skipTrigger()) {
         return;
      }
      System.debug('processRecords USE_SAVE_QUEUEABLE='+USE_SAVE_QUEUEABLE);
      Map<String,User> usersByPersonIdMap = new Map<String,User>();
      if (Trigger.isBefore) {
         BEFORE_EXECUTED = true;
         if (!USE_SAVE_QUEUEABLE) {
            usersByPersonIdMap = getUsersByPersonIdMap(recs); 
         }
         Apex_Batch_Control__c abc = getBatchControl();
         if (abc != null && abc.LogProcess__c) {
            log = ErrorLog.logError('OasisSyncHelper', 'LOG_DATA', recs[0].Name, null, 'Number of recs='+recs.size()+' usersByPersonIdMap='+usersByPersonIdMap.size()+' user='+UserInfo.getLastName());
            log.BatchSize__c = recs.size();
            log.ObjectId__c = recs[0].Id;
         }
      }
      
      Map<Id,SObject> existingObjectMap = new Map<Id,SObject>();
      if (Trigger.isBefore) {
         existingObjectMap = checkForExisting(recs, isConnectionUser);
      } // if (Trigger.isBefore
      
      Map<String,Campaign> campMap = null;
      if (Trigger.isBefore) {
         campMap = getCampaignMap(recs);
      }
      
      for (OasisSync__c rec : recs) {
         OasisSync__c oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         if (Trigger.isBefore) {
            if (isConnectionUser) {
               rec.Processed__c=false;
               rec.ReceivedLastUpdated__c=Datetime.now();
            }
            if (log != null && String.isBlank(log.ObjectInfo__c)) {
               ErrorLog.addToObjectInfo(log,String.valueOf(rec));
            }
            ErrorLog.addToDescription(log,'Source='+rec.Source__c+' SyncType='+rec.SyncType__c+' LeadIdOasis='+rec.LeadIdOasis__c);
            StringHelper.addToProcessNotes(rec,'Source='+rec.Source__c+' SyncType='+rec.SyncType__c+' user='+UserInfo.getUserName()+' USE_SAVE_QUEUEABLE='+USE_SAVE_QUEUEABLE);
            System.debug('processRecords Source='+rec.Source__c+' SyncType='+rec.SyncType__c+' LeadIdOasis='+rec.LeadIdOasis__c);
            if (!rec.Processed__c && rec.Source__c == SOURCE_OASIS) {
               if (USE_SAVE_QUEUEABLE) {
                  StringHelper.addToProcessNotes(rec,'Adding to queueable');
                  recsForQueueable.add(rec);
               } else {
                  StringHelper.addToProcessNotes(rec,'Handling in OasisSyncHelper');
                  User usr = getUserFromMap(rec, usersByPersonIdMap);
                  handleRecord(rec, usr, campMap);
               }
               /*
               if (rec.SyncType__c == SYNC_LEAD_CONVERTED && rec.LeadIdOasis__c != null) {
                  handleConvertedLead(rec,usr);
               } else if (rec.SyncType__c == SYNC_NEW || rec.SyncType__c == SYNC_UPDATE) {
                  if (rec.LeadIdOasis__c != null) {
                     handleLead(rec,usr);
                  } else if (rec.ContactIdOasis__c != null) {
                     handleAcctCtct(rec,usr);
                  }
               } else if (rec.SyncType__c == SYNC_RECORD_ID) {
                  if (rec.LeadIdPayx__c != null) {
                     handleLeadIdUpdate(rec,usr);
                  } else if (rec.ContactIdPayx__c != null) {
                     handleAcctCtctIdUpdate(rec,usr);
                  }
               }
               */
    /*
            } // if (Trigger.isBefore
         }
      } // for
      
      if (Trigger.isBefore && !USE_SAVE_QUEUEABLE) {
         checkSave();

         for (OasisSync__c sync : recs) {
            if (sync.Account__r != null && sync.Account__r.Id != null && sync.Account__c != sync.Account__r.Id) {
               sync.Account__c = sync.Account__r.Id;
            }
            if (sync.Contact__r != null && sync.Contact__r.Id != null && sync.Contact__c != sync.Contact__r.Id) {
               sync.Contact__c = sync.Contact__r.Id;
            }
            if (sync.Lead__r != null && sync.Lead__r.Id != null && sync.Lead__c != sync.Lead__r.Id) {
               sync.Lead__c = sync.Lead__r.Id;
            }
            
            //sync.Account__r = null;
            //sync.Contact__r = null;
            //sync.Lead__r = null;
         }
      }
      
      if (Trigger.isAfter) {
         System.debug('processRecords createdCtctIds='+createdCtctIds.size()+' recsForQueueable='+recsForQueueable.size());
         ErrorLog.addToDescription(log,'In the after trigger recsForQueueable='+recsForQueueable.size());
         if (!USE_SAVE_QUEUEABLE) {
            AFTER_EXECUTED = true;
         
            checkSendRecordIdUpdates();
         } else if (!recsForQueueable.isEmpty()) {
            Map<Id,Datetime> queueableSyncIdMap = new Map<Id,Datetime>();
            for (OasisSync__c sync : recsForQueueable) {
               if (sync.Id != null) {
                  queueableSyncIdMap.put(sync.Id, sync.ReceivedLastUpdated__c);
               }
            } // for (OasisSync__c sync
            ErrorLog.addToDescription(log,'queueableSyncIdMap='+queueableSyncIdMap.size());
            if (!queueableSyncIdMap.isEmpty()) {
               OasisSaveQueueable osq = new OasisSaveQueueable(queueableSyncIdMap);
               Id batchId = System.enqueueJob(osq);
               ErrorLog.addToDescription(log,'batchId='+batchId);
            }
            
         }
         //if (!createdCtctIds.isEmpty()) {
         //   sendCreatedCtctIds(createdCtctIds);
         //}
         
      }
      //PROCESSED = true;
      ErrorLog.saveErrorLog(log);
   } // processRecords
   
   // check for existing leads/contacts/accounts
   public static Map<Id,SObject> checkForExisting(OasisSync__c[] recs, Boolean isConnectionUser) {
      Set<String> leadIdSet = new Set<String>();
      Set<String> ctctIdSet = new Set<String>();
         
      for (OasisSync__c rec : recs) {
         if (isConnectionUser) {
            rec.Processed__c=false;
            rec.ReceivedLastUpdated__c=Datetime.now();
         }
         if (!rec.Processed__c && rec.Source__c == SOURCE_OASIS) {
            if (rec.LeadIdOasis__c != null) {
               leadIdSet.add(rec.LeadIdOasis__c);
            }
            if (rec.LeadIdPayx__c != null) {
               leadIdSet.add(rec.LeadIdPayx__c);
            }
            if (rec.ContactIdOasis__c != null) {
               ctctIdSet.add(rec.ContactIdOasis__c);
            }
            if (rec.ContactIdPayx__c != null) {
               ctctIdSet.add(rec.ContactIdPayx__c);
            }
         } // if (!rec.Processed__c
      } // for (OasisSync__c rec
      
      Map<Id,SObject> objectMap = new Map<Id,SObject>();
      checkExistingLeads(leadIdSet, objectMap);
      checkExistingCtcts(ctctIdSet, objectMap);
      return objectMap;
   } // checkForExisting
   
   public static void checkExistingLeads(Set<String> leadIdSet, Map<Id,SObject> objectMap) {
      if (!leadIdSet.isEmpty()) {
         Lead[] leads = [Select Id, LeadSource, Status, Lead_Stage__c, OasisId__c
                               ,OwnedBy__c
                           From Lead
                          Where Id in :leadIdSet
                             or OasisId__c in :leadIdSet];
         for (Lead ld : leads) {
            objectMap.put(ld.Id,ld);
            if (ld.OasisId__c != null) {
               objectMap.put(ld.OasisId__c,ld);
            }
         } // for (Lead ld : leads
      } // if (!leadIdSet.isEmpty
   } // checkExistingLeads
   
   public static void checkExistingCtcts(Set<String> ctctIdSet, Map<Id,SObject> objectMap) {
      if (!ctctIdSet.isEmpty()) {
         Contact[] ctcts = [Select Id, Name, Contact_Stage__c, OasisId__c
                                  ,OwnedBy__c
                                  ,Account.Id
                                  ,Account.Name
                              From Contact
                             Where Id in :ctctIdSet
                                or OasisId__c in :ctctIdSet];
         for (Contact ctct : ctcts) {
            objectMap.put(ctct.Id, ctct);
            if (ctct.OasisId__c != null) {
               objectMap.put(ctct.OasisId__c,ctct);
            }
         } // for (Contact ctct : ctcts
      } // if (!ctctIdSet.isEmpty
   } // checkExistingCtcts
   
   public static void handleRecord(OasisSync__c rec, User usr, Map<String,Campaign> campMap) {
      System.debug('handleRecord rec='+rec.Name+' SyncType__c='+rec.SyncType__c);
      if (rec.SyncType__c == SYNC_LEAD_CONVERTED && rec.LeadIdOasis__c != null) {
         handleConvertedLead(rec,usr);
      } else if (rec.SyncType__c == SYNC_NEW || rec.SyncType__c == SYNC_UPDATE) {
         Campaign camp = ((campMap != null && String.isNotBlank(rec.CampaignId_Oasis__c)) ? campMap.get(rec.CampaignId_Oasis__c) : null);
         if (rec.LeadIdOasis__c != null) {
            handleLead(rec,usr,camp);
         } else if (rec.ContactIdOasis__c != null) {
            handleAcctCtct(rec,usr,camp);
         }
      } else if (rec.SyncType__c == SYNC_RECORD_ID) {
         if (rec.LeadIdPayx__c != null) {
            handleLeadIdUpdate(rec,usr);
         } else if (rec.ContactIdPayx__c != null) {
            handleAcctCtctIdUpdate(rec,usr);
         }
      }

   } // handleRecord

   // if we need to send back the Paychex Ids to Oasis   
   public static Map<String,OasisSync__c> updatePaychexIdMap = new Map<String,OasisSync__c>();
   public static Set<String> syncRecordIdsUpdatedSet = new Set<String>();
   
   public static void checkSendRecordIdUpdates() {
      if (!syncRecordIdsUpdatedSet.isEmpty()) {
         sendRecordIdUpdates();
      }
   } // checkSendRecordIdUpdates
   
   public static void sendRecordIdUpdates() {
      Map<String,OasisSync__c> existingSyncMap = getExistingSyncMap(syncRecordIdsUpdatedSet);
      System.debug('sendRecordIdUpdates syncRecordIdsUpdatedSet='+syncRecordIdsUpdatedSet.size()+' existingSyncMap='+existingSyncMap.size());
      // all should have an OasisSync record. If they do not, we will ignore
      Map<Id,OasisSync__c> updateSyncMap = new Map<Id,OasisSync__c>();
      for (OasisSync__c sync : existingSyncMap.values()) {

         if (sync != null && !updateSyncMap.containsKey(sync.Id)) {
            sync = prepareSync(sync, sync.Name);
            System.debug('sendRecordIdUpdates account='+sync.Account__c+' contact='+sync.Contact__c);
            OasisSync__c newSync = new OasisSync__c(Id=sync.Id);
            newSync.NbrTransits__c = sync.NbrTransits__c;
            newSync.SourceLastUpdated__c = sync.SourceLastUpdated__c;
            newSync.LastUpdatedPaychex__c = sync.LastUpdatedPaychex__c;
            newSync.Source__c = sync.Source__c;
            
            newSync.SyncType__c = SYNC_RECORD_ID;
            updateSyncMap.put(newSync.Id,newSync);
         }
      } // for (Contact ctct
      SKIP_TRIGGER=true;
      System.debug('sendRecordIdUpdates updateSyncMap='+updateSyncMap.size());
      ErrorLog.addToDescription(log,'sendRecordIdUpdates syncRecordIdsUpdatedSet='+syncRecordIdsUpdatedSet.size()+' updateSyncMap='+updateSyncMap.size());
      checkSave(new OasisSync__c[]{}, updateSyncMap.values());
   } // sendRecordIdUpdates
    
   public static Set<String> ALREADY_RAN_SET = new Set<String>();
   
   // in case we want to log all transactions - only for testing purposes
   public static Boolean LOG_ALL=false;
    */
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
       /*
      String runningUserName = UserInfo.getName();
      Boolean skipUser = SKIP_NAME_SET.contains(runningUserName);

      System.debug('OasisSyncHelper.triggerCheckAllFirst skipTrigger()='+skipTrigger()+' isAfter='+isAfter+' runningUser='+runningUserName+' skipUser='+skipUser);
      if (skipUser || skipTrigger()) {
         return;
      }
      Boolean isConnectionUser = isRunningUserConnectionUser();
      if ((isConnectionUser || LOG_ALL) && log == null) {
         log = ErrorLog.logError('OasisSyncHelper', 'processRecords', 'LOG_DATA', null, 'Number of recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter+' usr='+UserInfo.getName());
      }
      System.debug('OasisSyncHelper.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1));
      Boolean recordsSent = false;
      if (isAfter && recs != null && !recs.isEmpty()) {
         // check what the type of the first record is
         SObjectType objType = recs[0].getSObjectType();
         String objTypeName = objType.getDescribe().getName();
         Boolean alreadyRan = ALREADY_RAN_SET.contains(objTypeName);
         System.debug('OasisSyncHelper.triggerCheckAllFirst objTypeName='+objTypeName+' alreadyRan='+alreadyRan);
         ErrorLog.addToDescription(log,'objTypeName='+objTypeName+' alreadyRan='+alreadyRan);
         if (!alreadyRan) {
            if (objType == Lead.sObjectType) {
               recordsSent = OasisSyncLeads.processLeads((Lead[])recs, (Map<Id,Lead>)oldMap, (String)null, log);
            } else if (objType == Account.sObjectType) {
               // do not process accounts on an insert - wait for the contact
               if (Trigger.isUpdate) {
                  recordsSent = OasisSyncAcctCtct.sendAccounts((Account[])recs, (Map<Id,Account>)oldMap, log);
               }
            } else if (objType == Contact.sObjectType) {
               recordsSent = OasisSyncAcctCtct.sendContacts((Contact[])recs, (Map<Id,Contact>) oldMap, log);
            }
            // so it only runs once per object type
            ALREADY_RAN_SET.add(objTypeName);
         } // if (!ALREADY_RAN_SET.contains

         //AFTER_EXECUTED=true;
      } // if (recs != null
      if (recordsSent) {
         ErrorLog.checkSave();
      }
      */
   } // checkAllBeforeTrigger

   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
/*

   // the person id for the generic user we're going to use for this integration
   public static String GENERIC_PERSON_ID=Label.OasisGenericUserPersonId;
   
   public static User getUserFromMap(OasisSync__c sync, Map<String,User> personIdUserMap) {
      User usr = null;
      if (sync != null && String.isNotBlank(sync.OwnerHRPersonID__c)) {
         usr = personIdUserMap.get(sync.OwnerHRPersonID__c);
      }
      if (usr == null) {
         usr = personIdUserMap.get(GENERIC_PERSON_ID);
      }
      StringHelper.addToProcessNotes(sync,'OwnerHRPersonID__c='+(sync != null ? sync.OwnerHRPersonID__c : 'None')+' usr='+(usr != null ? usr.Name : 'Not Found')+' personIdUserMap='+(personIdUserMap != null ? personIdUserMap.size() : -1));
      return usr;
   } // getUserFromMap
   
   // the tie of the users between the systems will be the Paychex HR Person Id. 
   // Use this method to get the actual user records.
   public static Map<String,User> getUsersByPersonIdMap(OasisSync__c[] recs) {
      Set<String> personIdSet = new Set<String>();
      // always add in the default
      personIdSet.add(GENERIC_PERSON_ID);
      for (OasisSync__c rec : recs) {
         if (String.isNotBlank(rec.OwnerHRPersonID__c)) {
            personIdSet.add(rec.OwnerHRPersonID__c);
         }
      } // for (OasisSync__c
      Map<String,User> userByPersonIdMap = new Map<String,User>();
      System.debug('getUsersByPersonIdMap personIdSet='+personIdSet.size());
      if (!personIdSet.isEmpty()) {
         // we want to pull out the active records first. We will only use the inactive
         // if there isn't already an active record.
         User[] users = [Select Id, Name, HR_Person_Id__c, Sales_Org__c
                               ,Profile.Name, NSS_Team__c
                               ,CSUserId__c // the client space user id
                           From User
                          Where HR_Person_Id__c in :personIdSet
                          order by IsActive desc, LastModifiedDate desc];
         System.debug('getUsersByPersonIdMap users='+users.size());
         for (User usr : users) {
            if (!userByPersonIdMap.containsKey(usr.HR_Person_Id__c)) {
               userByPersonIdMap.put(usr.HR_Person_Id__c,usr);
            }
         } // for (User usr : users
      } // if (!personIdSet.isEmpty
      System.debug('getUsersByPersonIdMap userByPersonIdMap='+userByPersonIdMap.size());
      return userByPersonIdMap;
   } // getUsersByPersonIdMap
   
   public static Map<Id,User> getUserMap(SObject[] recs) {
      Set<Id> userIdSet = new Set<Id>();
      for (SObject rec : recs) {
         Id ownerId = (Id)rec.get('OwnerId');
         if (ownerId != null) {
            userIdSet.add(ownerId);
         }
      } // for (SObject rec
      Map<Id,User> userMap = getUserMap(userIdSet);
      System.debug('getUserMap recs='+recs.size()+' userIdSet='+userIdSet.size()+' userMap='+userMap.size());
      return userMap;
   } // getUserMap
   
   public static Map<Id,User> getUserMap(Set<Id> userIdSet) {
      Map<Id,User> userMap = null;
      if (userIdSet.isEmpty()) {
         userMap = new Map<Id,User>();
      } else {
         userMap = new Map<Id,User>([Select Id, Name, HR_Person_Id__c, Sales_Org__c
                                           ,Profile.Name, NSS_Team__c
                                           ,CSUserId__c // the client space user id
                                       From User
                                      Where Id in :userIdSet]);
      }
      return userMap;
   } // getUserMap
   
   public static String OASIS_NEW='OasisNew';
   public static String OASIS_UPDATE='OasisUpdate';

   public static Map<String,Campaign> getCampaignMap(OasisSync__c[] syncs) {
      Set<String> oasisCampIdSet = new Set<String>();
      for (OasisSync__c sync : syncs) {
         if (String.isNotBlank(sync.CampaignId_Oasis__c)) {
            oasisCampIdSet.add(sync.CampaignId_Oasis__c);
         }
      } // for (OasisSync__c sync
      Map<String,Campaign> campMap = new Map<String,Campaign>();
      if (!oasisCampIdSet.isEmpty()) {
         Campaign[] camps = [Select Id, Name, OasisCampaignId__c
                               from Campaign
                              Where OasisCampaignId__c in :oasisCampIdSet];
         for (Campaign camp : camps) {
            campMap.put(camp.OasisCampaignId__c, camp);
         }
      } // if (!oasisCampIdSet.isEmpty
      return campMap;
   } // getCampaignMap
   
   // when we get the Oasis Ids back due to an insert performed on the Paychex side,
   // update the oasis Ids on the Paychex side
   public static void handleLeadIdUpdate(OasisSync__c sync, User usr) {
      if (String.isNotBlank(sync.LeadIdPayx__c) && String.isNotBlank(sync.LeadIdOasis__c)) {
         Lead ld = new Lead(Id=sync.LeadIdPayx__c, OasisId__c=sync.LeadIdOasis__c);
         if (usr != null) {
            ld.OwnerId = usr.Id;
         }
         updateLeadMap.put(ld.Id,ld);
         sync.Processed__c=true;
      }
   } // handleLeadIdUpdate
   
   /*
o  If the incoming Oasis Lead is matched to a Current Client (Current Client? Is True) within the Paychex Salesforce instance, then the Lead is considered not workable by the BDR
  Non workable information is sent back to Oasis instance
o  If the incoming Oasis Lead is matched to a Prospect Client (Current Client? Is False) within the Paychex Salesforce instance AND has an Open Opportunity AND has any activity in the last 6 months, then the Lead is considered not workable by the BDR
  Non workable information is sent back to Oasis instance
  No notification is needed to the current record owner
o  If the incoming Oasis Lead is matched to a Prospect Client (Current Client? Is False) within the Paychex Salesforce instance AND has no Open Opportunity AND has no activity in the last 6 months, then the Lead is considered workable by the BDR
  Workable information is sent back to Oasis instance
•  This will be worked as usual by the BDR
  Partner Referral is created with the incoming information
  Record type is updated to Prospect Record Type
  Type is set to Oasis Prospect
  Hold Out – True
  Hold Out Description – Oasis Prospect
  Owner – New Oasis Generic User for placeholder. Upon the BDR working and converting they will send the Account record which should match to this one and then the owner will be updated then

   
   */
   /*
   public static Id peoRtId = null;
   
   public static Id getPeoRTId() {
      if (peoRtId == null) {
         Map<String,Schema.RecordTypeInfo> byNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
         Schema.RecordTypeInfo peoRtInfo = byNameMap.get(Label.RT_Oasis_Lead);
         if (peoRTInfo != null) {
            peoRtId = peoRtInfo.getRecordTypeId();
         }
      }
      return peoRTId;
   } // getPeoRTId
   
   public static void handleLead(OasisSync__c sync, User usr, Campaign camp) {
      //ErrorLog.addToDescription(log,'handleLead LeadIdOasis__c='+sync.LeadIdOasis__c);
      StringHelper.addToProcessNotes(sync, 'handleLead LeadIdOasis__c='+sync.LeadIdOasis__c+' has camp='+(camp != null)+' ownedBy='+sync.OwnedBy__c);     
      // new lead
      // PEO Lead Record Type
      // Lead Source - TBD
      // Hold Out = true
      // if owner can't be found via person id, use the "Oasis Queue"
      
      
      
      // TODO - have to set record type, product of interest (PEO?)
      Boolean isNew = (sync.SyncType__c ==SYNC_NEW || String.isBlank(sync.LeadIdPayx__c));
      Lead ld = new Lead(OasisId__c = sync.LeadIdOasis__c);
      if (sync.NumberOfEmployees__c != null) {
         ld.NumberOfEmployees = Integer.valueOf(sync.NumberOfEmployees__c);
      }
      if (String.isNotBlank(sync.NumberOfEmployeesRange__c)) {
         ld.Number_of_Employees_Range__c = sync.NumberOfEmployeesRange__c;
      }

      ld.FirstName = sync.FirstName__c;
      ld.LastName = sync.LastName__c;
      ld.Title = sync.Title__c;
      ld.Company = sync.Company__c;
      ld.Other_Phone__c = sync.Phone2__c;
      ld.Website = sync.Website__c;
      ld.Street = sync.Address__c;
      ld.City = sync.City__c;
      ld.State = sync.State__c;
      ld.PostalCode = sync.PostalCode__c;
      ld.Email = sync.Email__c;
      ld.Phone = sync.Phone__c;
      ld.MobilePhone = sync.MobilePhone__c;
      ld.DisqualifiedReason__c = sync.DisqualifiedReason__c;
      // always allow Oasis records to Sync
      ld.Do_Not_Sync__c = false;
      
      // do we need to do anything special for Industry?
      ld.Industry = sync.Industry__c;
      // do we need to do anything special for Status?
      //ld.Status = sync.LeadStatus__c;
      // do we need to do anything special for LeadSource?
      ld.LeadSource = sync.LeadSource__c;
      sync.Lead__r = ld;
      
      
      //if (usr != null) {
      //   ld.OwnerId = usr.Id;
         // only set the hold out if we don't have a paychex id
     //    if (String.isBlank(sync.LeadIdPayx__c)) {
            //ld.Hold_Out__c=true;
            //ld.Hold_Out_Reason__c='Oasis Prospect';
     //    }
      //}
      
      if (camp != null) {
         ld.LatestCampaign__c = camp.Id;
      }
      ld.OwnedBy__c = sync.OwnedBy__c;
      if (String.isNotBlank(ld.OwnedBy__c)) {
         ld.Description = sync.Description__c;
         if (String.isNotBlank(sync.MarketingStage__c)) {
            ld.Lead_Stage__c = sync.MarketingStage__c;
         }
      }

      // this will control what happens with the Lead
      // if a new lead comes in from oasis, we basically want it to follow the same lead process as webleads.
      //ld.OwnedBy__c = (isNew ? OASIS_NEW : null);
      if (isNew) {
         Id rtId = getPeoRTId();
         StringHelper.addToProcessNotes(sync,'RecordType for '+Label.RT_Oasis_Lead+'='+(rtId != null ? 'Found' : 'Not Found'));
         if (rtId != null) {
            ld.RecordTypeId = rtId;
         }
         ld.Product_Division__c='PEOOasis';
         ld.CreatedByProcess__c=SOURCE_OASIS;
         // set to Pending so we know not to send the record back yet.
         ld.DuplicateCheckStatus__c = 'Pending';
         ld.PEOLeasing__c = true;
         // default this value
         ld.Frequency__c = '1 Weekly';
      }
      
      if (String.isBlank(sync.LeadIdPayx__c)) {
         updatePaychexIdMap.put(ld.OasisId__c, sync);
         upsertLeads.add(ld);
      } else {
         ld.Id = sync.LeadIdPayx__c;
         updateLeadMap.put(ld.Id,ld);
      }
      //ErrorLog.addToDescription(log,'end of handleLead');
      StringHelper.addToProcessNotes(sync,'end of handleLead');
      ErrorLog.addToObjectInfo(log,String.valueOf(ld));
      sync.Processed__c=true;
   } // handleLead

   public static void handleAcctCtctIdUpdate(OasisSync__c sync, User usr) {
      if (String.isNotBlank(sync.AccountIdPayx__c) && String.isNotBlank(sync.AccountIdOasis__c)) {
         Account acct = new Account(Id=sync.AccountIdPayx__c, OasisId__c=sync.AccountIdOasis__c);
         if (usr != null) {
            acct.OwnerId = usr.Id;
         }
         if (sync.Account__c == null || sync.Account__c != acct.Id) {
            sync.Account__c = acct.Id;
         }
         updateAcctMap.put(acct.Id,acct);
         sync.Processed__c=true;
      }

      if (String.isNotBlank(sync.ContactIdPayx__c) && String.isNotBlank(sync.ContactIdOasis__c)) {
         Contact ctct = new Contact(Id=sync.ContactIdPayx__c, OasisId__c=sync.ContactIdOasis__c);
         if (ctct != null) {
            ctct.OwnerId = usr.Id;
         }
         if (sync.Contact__c == null || sync.Contact__c != ctct.Id) {
            sync.Contact__c = ctct.Id;
         }
         updateCtctMap.put(ctct.Id,ctct);
         sync.Processed__c=true;
      }
      
   } // handleAcctCtctIdUpdate
   
   /*
o  Account is created in Paychex Salesforce instance as follows:
  Owner per what is sent from Oasis
  Prospect Record Type
  Type – Oasis Prospect
  Hold Out – True
  Hold out Description – Oasis Client

o  Contact is created in Paychex Salesforce instance as follows: 
  Owner to match what is sent from Oasis
  Core/MMS record type
  Hold out – True
  Hold out description – Oasis Client

   
   */
   /*
   public static Id acctRtId = null;
   
   public static Id getAcctRtId() {
      if (acctRtId == null) {
         Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
         Schema.RecordTypeInfo prospectRtInfo = byNameMap.get(Label.RT_Prospect_Acct);
         if (prospectRtInfo != null) {
            acctRtId = prospectRtInfo.getRecordTypeId();
         }
         
      }
      return acctRtId;
   } // getAcctRtId
   
   public static Id ctctRtId = null;
   
   public static Id getCtctRtId() {
      if (ctctRtId == null) {
         Map<String,Schema.RecordTypeInfo> byNameMap = Contact.SObjectType.getDescribe().getRecordTypeInfosByName();
         Schema.RecordTypeInfo contactRtInfo = byNameMap.get(Label.RT_Core_Contact);
         if (contactRtInfo != null) {
            ctctRtId = contactRtInfo.getRecordTypeId();
         }
      }
      return ctctRtId;
   } // getCtctRtId
   
   public static void handleAcctCtct(OasisSync__c sync, User usr, Campaign camp) {
      Boolean isNew = (sync.SyncType__c ==SYNC_NEW || String.isBlank(sync.AccountIdPayx__c));
      
      // TODO - what is the indication that it is a client coming from 

      //ErrorLog.addToDescription(log,'handleAcctCtct ContactIdOasis__c='+sync.ContactIdOasis__c);
      StringHelper.addToProcessNotes(sync,'handleAcctCtct ContactIdOasis__c='+sync.ContactIdOasis__c);
      Account acct = new Account(OasisId__c = sync.AccountIdOasis__c);
      acct.Name = sync.Company__c;
      acct.BillingStreet = sync.Address__c;
      acct.BillingCity = sync.City__c;
      acct.BillingState = sync.State__c;
      acct.BillingPostalCode = sync.PostalCode__c;
      acct.Phone = sync.Phone2__c;
      acct.Website = sync.Website__c;
      // do we need to do anything special for Industry?
      acct.Industry = sync.Industry__c;
      acct.NumberOfEmployees = Integer.valueOf(sync.NumberOfEmployees__c);
      acct.Employees__c = Integer.valueOf(sync.NumberOfEmployees__c);
      acct.Federal_ID_Number__c = sync.Federal_ID_Number__c;
      acct.Other_PEO_Client_Number__c = sync.CS_Client_Number__c;
      //acct.Frequency__c = sync.Frequency__c;
      acct.DBA__c = sync.DBA__c;
      acct.Do_Not_Call__c = sync.DoNotCall__c;
      acct.Fax = sync.Fax__c;
      acct.Lead_Source__c = sync.LeadSource__c;
      acct.Sic_Code__c = sync.SICCode__c;
      acct.NAICS_Code__c = sync.NAICSCode__c;
      acct.CSOrgID__c = sync.CSOrgID__c;
      acct.CSImportID__c = sync.CSImportID__c;
      acct.CSOrgCategory__c = sync.CSOrgCategory__c;
      acct.CSOrgStatus__c = sync.CSOrgStatus__c;
      acct.CSCMContractStatus__c = sync.CSCMContractStatus__c;
      acct.CSPrimaryClientNumber__c = sync.CSPrimaryClientNumber__c;
      acct.CSServiceType__c = sync.CSServiceType__c;
      sync.Account__r = acct;

      if (String.isBlank(sync.AccountIdPayx__c)) {
         updatePaychexIdMap.put(acct.OasisId__c, sync);
      }
      
      upsertAccts.add(acct);
      
      Contact ctct = new Contact(OasisId__c = sync.ContactIdOasis__c);
      ctct.Account = acct;
      ctct.FirstName = sync.FirstName__c;
      ctct.LastName = sync.LastName__c;
      ctct.Title = sync.Title__c;
      ctct.Phone = sync.Phone__c;
      ctct.Email = sync.Email__c;
      ctct.MobilePhone = sync.MobilePhone__c;
      ctct.CSContactID__c = sync.CSContactID__c;
      ctct.CSOrgID__c = sync.CSOrgID__c;
      ctct.MailingStreet = sync.MailingStreet__c;
      ctct.MailingCity = sync.MailingCity__c;
      ctct.MailingState = sync.MailingState__c;
      ctct.MailingPostalCode = sync.MailingPostalCode__c;
      if (camp != null) {
         ctct.LatestCampaign__c = camp.Id;
      }
      if (String.isNotBlank(sync.OwnedBy__c)) {
         ctct.OwnedBy__c = sync.OwnedBy__c;
      }
      if (String.isNotBlank(sync.MarketingStage__c)) {
         ctct.Contact_Stage__c = sync.MarketingStage__c;
      }
      sync.Contact__r = ctct;

      if (String.isBlank(sync.ContactIdPayx__c)) {
         updatePaychexIdMap.put(ctct.OasisId__c, sync);
      }
      
      upsertCtcts.add(ctct);
      
      if (isNew) {
         acct.PEOLeasing__c = true;
         acct.CreatedByProcess__c=SOURCE_OASIS;
         acct.Type = 'Oasis Prospect';
         // default this value for now.
         acct.Frequency__c = '1 Weekly';
         ctct.CreatedByProcess__c=SOURCE_OASIS;
         Id rtIdAcct = getAcctRtId();
         if (rtIdAcct != null) {
            acct.RecordTypeId = rtIdAcct;
         }
         Id rtIdCtct = getCtctRtId();
         if (rtIdCtct != null) {
            ctct.RecordTypeId = rtIdCtct;
         }
         //ErrorLog.addToDescription(log,'acct RT for '+Label.RT_Prospect_Acct+(prospectRtInfo != null ? ' Found' : ' Not Found')+' ctct RT for '+Label.RT_Core_Contact+(contactRtInfo != null ? ' Found' : ' Not Found'));
         StringHelper.addToProcessNotes(sync,'acct RT for '+Label.RT_Prospect_Acct+(rtIdAcct != null ? ' Found' : ' Not Found')+' ctct RT for '+Label.RT_Core_Contact+(rtIdCtct != null ? ' Found' : ' Not Found'));
      }

      String holdOutReason = 'Oasis Prospect';
      
      System.debug('handleAcctCtct sync.CSOrgStatus__c='+sync.CSOrgStatus__c);
      if (sync.CSOrgStatus__c == 'Client') {
         acct.Type = 'Oasis Client';
         holdOutReason = 'Oasis Client';
         checkForClientSet.add(sync.AccountIdOasis__c);
      }

      //if (usr != null) {
      //   ctct.OwnerId = usr.Id;
         //ctct.Hold_Out__c=true;
         //ctct.Hold_Out_Reason__c=holdOutReason;
      //   acct.OwnerId = usr.Id;
         //acct.Hold_Out__c=true;
         //acct.Permanent_Hold_Out_Description__c=holdOutReason;
      //}

      if (String.isNotBlank(sync.CSOrgStatus__c)) {
         // look for an opportunity to update
         checkForOpportunity(sync, usr);
      }
      ErrorLog.addToObjectInfo(log,String.valueOf(acct));
      //ErrorLog.addToDescription(log,'end of method');
      StringHelper.addToProcessNotes(sync,'end of method');
      sync.Processed__c=true;
   } // handleAcctCtct
   
   // see if an opportunity exists
   public static void checkForOpportunity(OasisSync__c sync, User usr) {
      // look for a PEO Opportunity
      SalesOrg__c salesOrg = SalesOrg__c.getInstance('PEO');
      String[] recordTypeNames = (salesOrg != null ? new String[]{salesOrg.OpptyRecordTypeName__c, salesOrg.OpptyRecordTypeName2__c} : new String[]{});
      StringHelper.addToProcessNotes(sync,'checkForOpp CSOrgStatus__c='+sync.CSOrgStatus__c+' recordTypeNames='+recordTypeNames);
      Opportunity opp = null;
      try {
         opp = [Select Id, Name, OwnerId, CloseDate, StageName, Reason_Not_Sold__c
                      ,OppSource__c
                  From Opportunity
                 Where RecordType.Name in :recordTypeNames
                   And IsClosed = false
                   and Account.OasisId__c = :sync.AccountIdOasis__c
                  order by CreatedDate limit 1];
      } catch (Exception e) {
         StringHelper.addToProcessNotes(sync,'Opp Not found!');
      }
      if (opp != null) {
         
         StringHelper.addToProcessNotes(sync,'opp='+opp.Name+' id='+opp.Id);
         if (sync.Opportunity__c != opp.Id) {
            sync.Opportunity__c = opp.Id;
         }
         String oppStatus = null;
         Boolean oppUpdated = false;

         if ((opp.OppSource__c == SOURCE_OASIS || opp.OppSource__c == 'OasisSync') 
               && (usr != null && usr.Id != opp.OwnerId)) {
            StringHelper.addToProcessNotes(sync,'Updated opp Owner from '+opp.OwnerId+' to '+usr.Id);
            opp.OwnerId = usr.Id;
            oppUpdated = true;
         }

         if ((sync.CSOrgStatus__c == 'Accepted' || sync.CSOrgStatus__c == 'Underwriting')
               && opp.StageName != 'Discover') {
            opp.StageName = 'Discover';
            oppUpdated = true;
         } else if (sync.CSOrgStatus__c == 'Approved'
               && opp.StageName != 'Prove') {
            opp.StageName = 'Prove';
            oppUpdated = true;
         } else if ((sync.CSOrgStatus__c == 'Contract Pending Approval' || sync.CSOrgStatus__c == 'Pending Activation'
                      || sync.CSOrgStatus__c == 'Submitted' || sync.CSOrgStatus__c == 'Implementation')
               && opp.StageName != 'Sold - Submitted') {
            opp.StageName = 'Sold - Submitted';
            oppUpdated = true;
         } else if (sync.CSOrgStatus__c == 'Client'
               && opp.StageName != 'Sold - Started') {
            opp.StageName = 'Sold - Started';
            oppUpdated = true;
         } else if ((sync.CSOrgStatus__c == 'Dead' || sync.CSOrgStatus__c == 'Expired')
               && opp.StageName != 'Not Sold') {
            opp.StageName = 'Not Sold';
            opp.Reason_Not_Sold__c = 'Oasis-'+sync.CSOrgStatus__c;
            oppUpdated = true;
         }
         
         if (oppUpdated) {
            StringHelper.addToProcessNotes(sync,'Opp Updated StageName='+opp.StageName+' Reason Not Sold='+opp.Reason_Not_Sold__c);
            DmlHelper.performDML2(new Opportunity[]{opp}, DmlHelper.DML_UPDATE, 'OasisSyncHelper', 'checkForOpportunity', 'Updating Opportunity', true);
         } 
      } // if (opp != null
   } // checkForOpportunity
   
   public static Lead[] upsertLeads = new Lead[]{};
   public static Map<Id,Lead> updateLeadMap = new Map<Id,Lead>();
   public static Account[] upsertAccts = new Account[]{};
   public static Map<Id,Account> updateAcctMap = new Map<Id,Account>();
   public static Contact[] upsertCtcts = new Contact[]{};
   public static Map<Id,Contact> updateCtctMap = new Map<Id,Contact>();
   
   public static Set<String> checkForClientSet = new Set<String>();
   
   //public static Id[] createdLeadIds = new Id[]{};
   public static Id[] createdCtctIds = new Id[]{};
   
   public static void checkSave() {
      System.debug('checkSave upsertLeads='+upsertLeads.size()+' upsertAccts='+upsertAccts.size()+' upsertCtcts='+upsertCtcts.size());
      SKIP_TRIGGER = true;
      ErrorLog.addToDescription(log,'checkSave upsertLeads='+upsertLeads.size()+' upsertAccts='+upsertAccts.size()+' upsertCtcts='+upsertCtcts.size());
      ErrorLog.addToDescription(log,'updateLeadMap='+updateLeadMap.size()+' updateAcctMap='+updateAcctMap.size()+' updateCtctMap='+updateCtctMap.size());
      
      if (!upsertLeads.isEmpty()) {
         // these extra steps are so we can upsert to a specific field.
         DmlHelper.prepareForSave();
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertLeads, DmlHelper.DML_UPSERT, 'OasisSyncHelper', 'checkSave', 'upserting leads');
         Database.UpsertResult[] results = Database.upsert(upsertLeads,Lead.Fields.OasisId__c,false);
         ErrorLog.addToDescription(log,'upsertResults='+results);
         DmlHelper.handleUpsertResults(upsertLeads, results, dmlResult);
         ErrorLog.addToDescription(log,'Save Result recs='+dmlResult.nbrRecs+' success='+dmlResult.nbrSuccess);
         //createdLeadIds = checkForCreatedIds(results);
      }
      
      if (!updateLeadMap.isEmpty()) {
         LeadMethods.LEAD_BEFORE_EXECUTING = true;
         LeadMethods.LEAD_AFTER_EXECUTING = true;
         DmlHelper.performDML2(updateLeadMap.values(), DmlHelper.DML_UPDATE, 'OasisSyncHelper', 'checkSave', 'updating Leads', false);
         LeadMethods.LEAD_BEFORE_EXECUTING = false;
         LeadMethods.LEAD_AFTER_EXECUTING = false;
      }
      
      if (!upsertAccts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.prepareForSave();
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertAccts, DmlHelper.DML_UPSERT, 'OasisSyncHelper', 'checkSave', 'upserting leads');
         Database.UpsertResult[] results = Database.upsert(upsertAccts,Account.Fields.OasisId__c,false);
         ErrorLog.addToDescription(log,'upsertResults='+results);
         DmlHelper.handleUpsertResults(upsertAccts, results, dmlResult);
         ErrorLog.addToDescription(log,'Save Result recs='+dmlResult.nbrRecs+' success='+dmlResult.nbrSuccess);
         ZipCheckOwner.SKIP_TRIGGERS=false;
         checkUpsertAccts();
         //createdAcctIds = checkForCreatedIds(results);
      }
      
      if (!updateAcctMap.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(updateAcctMap.values(), DmlHelper.DML_UPDATE, 'OasisSyncHelper', 'checkSave', 'updating Accounts', false);
         ZipCheckOwner.SKIP_TRIGGERS=false;
       }

      if (!upsertCtcts.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
         // get the id of the account
         for (Contact ctct : upsertCtcts) {
            if (ctct.Account != null && ctct.Account.Id != null) {
               ctct.AccountId = ctct.Account.Id;
               ctct.Account = null;
            }
         } // for (Contact ctct
         DmlHelper.prepareForSave();
         DmlHelper.DmlResult dmlResult = DmlHelper.initializeDmlResult(upsertCtcts, DmlHelper.DML_UPSERT, 'OasisSyncHelper', 'checkSave', 'upserting leads');
         Database.UpsertResult[] results = Database.upsert(upsertCtcts,Contact.Fields.OasisId__c,false);
         ErrorLog.addToDescription(log,'upsertResults='+results);
         DmlHelper.handleUpsertResults(upsertCtcts, results, dmlResult);
         ErrorLog.addToDescription(log,'Save Result recs='+dmlResult.nbrRecs+' success='+dmlResult.nbrSuccess);
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
         ZipCheckOwner.SKIP_TRIGGERS=false;
         //createdCtctIds = checkForCreatedIds(results);
         checkUpsertCtcts();
      } // if (!upsertCtcts.isEmpty

      if (!updateCtctMap.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
         DmlHelper.performDML2(updateCtctMap.values(), DmlHelper.DML_UPDATE, 'OasisSyncHelper', 'checkSave', 'updating Contacts', false);
         ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
         ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }

      System.debug('checkSave checkForClientSet='+checkForClientSet.size());
      if (!checkForClientSet.isEmpty()) {
         checkForClientAsset();
      }
      System.debug('checkSave createdCtctIds='+createdCtctIds.size());
      //ErrorLog.addToDescription(log,'isBefore='+Trigger.isBefore+' createdLeadIds='+createdLeadIds.size()+' createdCtctIds='+createdCtctIds.size());
      ErrorLog.addToDescription(log,'isBefore='+Trigger.isBefore+' createdCtctIds='+createdCtctIds.size());
      ErrorLog.checkSave();
      
      SKIP_TRIGGER = false;
   } // checkSave
   
   public static String[] oasisProdCodes = Label.OasisProductCodes.split(',');
   
   public static void checkForClientAsset() {
      Account[] accts = [Select Id, Name, Type, CSOrgStatus__c
                               ,(Select Id, AccountId, Name, ProductCode, Product2Id
                                   From Assets
                                  Where ProductCode in :oasisProdCodes)
                           From Account
                          Where OasisId__c in :checkForClientSet];
      System.debug('checkForClientAsset accts='+accts.size());
      Asset[] newAssets = new Asset[]{};
      for (Account acct : accts) {
         System.debug('checkForClientAsset type='+acct.Type+' orgStatus='+acct.CSOrgStatus__c);
         if ((acct.Type == 'Oasis Client' || acct.CSOrgStatus__c == 'Client')
                  && acct.Assets.isEmpty()) {
            Product2 prod = getOasisProd();
            System.debug('checkForClientAsset prod='+(prod != null ? prod.Name : 'No prod'));
            if (prod != null) {
               Asset asst = new Asset(Name=prod.Name, Product2Id=prod.Id, AccountId=acct.Id);
               newAssets.add(asst);
            }
         }
      } // for (Account acct : accts
      System.debug('checkForClientAsset accts='+accts.size()+' newAssets='+newAssets.size());
      
      if (!newAssets.isEmpty()) {
         ZipCheckOwner.SKIP_TRIGGERS=true;
         DmlHelper.performDML2(newAssets, DmlHelper.DML_INSERT, 'OasisSyncHelper', 'checkForClientAsset', 'insert assets', false);
         ZipCheckOwner.SKIP_TRIGGERS=false;
      }
   } // checkForClientAsset
   
   public static Product2 oasisProd = null;
   public static Product2 getOasisProd() {
      if (oasisProd == null) {
         StringHelper.addToProcessNotes(log,'Attempting to query product for '+oasisProdCodes);
         try {
            oasisProd = [select Id, Name, ProductCode 
                           from Product2 
                          where ProductCode in :oasisProdCodes
                            and Sales_Org__c like '%PEO%'
                           order by ProductCode limit 1];
         } catch (Exception e) {
            StringHelper.addToProcessNotes(log,'Error finding prod: '+e.getMessage());
         }
         StringHelper.addToProcessNotes(log,'oasisProd found='+(oasisProd != null));
      }
      return oasisProd;
   } // getOasisProd
   
   //public static Map<String,OasisSync__c> updatePaychexIdMap = new Map<String,OasisSync__c>();
   //public static Set<String> syncRecordIdsUpdatedSet = new Set<String>();
   
   public static void checkUpsertAccts() {
      for (Account acct : upsertAccts) {
         if (acct.Id != null && String.isNotBlank(acct.OasisId__c)) {
            OasisSync__c sync = updatePaychexIdMap.get(acct.OasisId__c);
            if (sync != null && String.isBlank(sync.AccountIdPayx__c)) {
               sync.AccountIdPayx__c = acct.Id;
               sync.Account__c = acct.Id;
               syncRecordIdsUpdatedSet.add(acct.OasisId__c);
            }
         }
      } // for (Account acct
   } // checkUpsertAccts
   
   public static void checkUpsertCtcts() {
      for (Contact ctct : upsertCtcts) {
         if (ctct.Id != null && String.isNotBlank(ctct.OasisId__c)) {
            OasisSync__c sync = updatePaychexIdMap.get(ctct.OasisId__c);
            if (sync != null && String.isBlank(sync.ContactIdPayx__c)) {
               sync.ContactIdPayx__c = ctct.Id;
               sync.Contact__c = ctct.Id;
               syncRecordIdsUpdatedSet.add(ctct.OasisId__c);
            }
         } // if (ctct.Id != null
      } // for (Contact ctct
   } // checkUpsertCtcts
   /*
   public static Id[] checkForCreatedIds(Database.UpsertResult[] results) {
      Id[] createdIds = new Id[]{};
      for (Database.UpsertResult result : results) {
         if (result.isSuccess() && result.isCreated()) {
            createdIds.add(result.getId());
         }
      }
      System.debug('checkForCreatedIds createdIds='+createdIds.size());
      return createdIds;
   } // checkForCreatedIds
   
   public static void sendCreatedCtctIds(Id[] createdCtctIds) {
      Contact[] ctcts = [Select Id, Name, OasisId__c, AccountId
                               ,Account.Id
                               ,Account.Name
                               ,Account.OasisId__c
                           From Contact
                          where Id in :createdCtctIds];
      Map<String,OasisSync__c> existingSyncMap = getExistingSyncMap(ctcts);
      System.debug('sendCreatedCtctIds createdCtctIds='+createdCtctIds.size()+' ctcts='+ctcts.size()+' existingSyncMap='+existingSyncMap.size());
      // all leads should have an OasisSync record. If they do not, we will ignore?
      OasisSync__c[] updateSyncs = new OasisSync__c[]{};
      for (Contact ctct : ctcts) {
         OasisSync__c sync = existingSyncMap.get(ctct.OasisId__c);
         if (sync != null && ctct.Account != null) {
            sync = prepareSync(sync, ctct.Name);
            sync.SyncType__c = SYNC_RECORD_ID;
            sync.AccountIdPayx__c = ctct.AccountId;
            sync.ContactIdPayx__c = ctct.Id;
            updateSyncs.add(sync);
         }
      } // for (Contact ctct
      SKIP_TRIGGER=true;
      System.debug('sendCreatedCtctIds updateSyncs='+updateSyncs.size());
      ErrorLog.addToDescription(log,'sendCreatedCtctIds ctcts='+ctcts.size()+' updateSyncs='+updateSyncs.size());
      checkSave(new OasisSync__c[]{}, updateSyncs);
   } // sendCreatedCtctIds
   */
    /*
   // if a PEO opportunity (PEO Prism Opportunity Record Type) is created, and the owner of the opp has a client space id,
   // then send the account and contact to CS.
   public static void sendOppUpdates(Id[] oppIds) {
      Opportunity[] opps = [Select Id, StageName
                                  ,Account.Id
                                  ,Account.OasisId__c
                                  ,Account.Name
                                  ,Account.BillingStreet
                                  ,Account.BillingCity
                                  ,Account.BillingState
                                  ,Account.BillingPostalCode
                                  ,Account.Phone
                                  ,Account.Website
                                  ,(Select Id
                                          ,Contact.Id
                                          ,Contact.OasisId__c
                                          ,Contact.FirstName
                                          ,Contact.LastName
                                          ,Contact.Title
                                          ,Contact.Phone
                                          ,Contact.Email
                                          ,Contact.MobilePhone
                                      From OpportunityContactRoles
                                     Where IsPrimary = true)
                              From Opportunity
                             Where Id in :oppIds];
      for (Opportunity opp : opps) {
         
      }
   } // sendOppUpdates

   public static void handleConvertedLead(OasisSync__c sync, User usr) {
      // when a lead converts on the oasis side, convert it on the paychex side.
      // make sure all three ids exist
      Lead ld = null;
      if (sync.LeadIdOasis__c != null) {
         try {
            ld = [Select Id, Name, Company, OasisId__c, IsConverted from Lead where OasisId__c=:sync.LeadIdOasis__c];// and IsConverted=false];
         } catch (Exception e) {
            // no lead found, we won't continue
         }
      } // if (rec.LeadIdOasis__c
      Contact ctct = null;
      if (ld != null && sync.ContactIdOasis__c != null && sync.AccountIdOasis__c != null) {
         try {
            ctct = [Select Id, Name, OwnerId
                          ,OasisId__c
                          ,Account.Id
                          ,Account.Name
                          ,Account.OwnerId
                          ,Account.OasisId__c
                      From Contact
                     Where OasisId__c=:sync.ContactIdOasis__c
                       and Account.OasisId__c=:sync.AccountIdOasis__c];
         } catch (Exception e) {
            // no contact found, we won't continue
            StringHelper.addToProcessNotes(sync,'No data found for ContactIdOasis__c='+sync.ContactIdOasis__c+' AccountIdOasis__c='+sync.AccountIdOasis__c+': '+e.getMessage());
            //ErrorLog.addToDescription(log,'No data found for ContactIdOasis__c='+rec.ContactIdOasis__c+' AccountIdOasis__c='+rec.AccountIdOasis__c+': '+e.getMessage());
         }
      } // if (hasLead && rec.ContactIdOasis__c != null
      
      Boolean leadConverted=(ld != null && ld.IsConverted);
      StringHelper.addToProcessNotes(sync,'handleConvertedLead hasLd='+(ld != null ? String.valueOf(ld.Id) : 'false')+' hasCtct='+(ctct != null ? String.valueOf(ctct.Id) : 'false'));
      if (ld != null && !ld.IsConverted && ctct != null) {
         // convert the lead into the existing records
         DuplicateCheckQueueable.overrideOwnerId = (usr != null ? usr.Id : null);
         Id convertedCtctId = DuplicateCheckQueueable.convertLead(ld, ctct.Account, ctct); 
         StringHelper.addToProcessNotes(sync,'ContactIdOasis__c='+sync.ContactIdOasis__c+' convertedCtctId='+convertedCtctId);
         if (convertedCtctId != null) {
            leadConverted = true;
            LeadCheckContactRecordType.SKIP_FUTURE=true;
            LeadCheckContactRecordType.ONLY_REPARENT=true;
            LeadCheckContactRecordType.checkLeads(new Id[]{ld.Id},false);
            StringHelper.addToProcessNotes(sync,'After LeadCheckContactRecordType call');
         }
      }
      
      // if the lead is converted from Oasis, create an opportunity
      if (leadConverted && ctct != null) {
         sync.Processed__c = createOpp(ctct.Account,ctct,usr,sync);
      }
   } // handleConvertedLead
   
   // Owner to match what is sent from Oasis
   // PEO Prism Record Type
   //  Opportunity Type – PEO
   //  Payroll Platform – Prism PEO
   //  Lead Source – TBD
   //  Status – Created Qualified
   public static Boolean createOpp(Account acct, Contact ctct, User usr, OasisSync__c sync) {
      StringHelper.addToProcessNotes(sync,'In createOpp');
      CreateOppAndMeeting coam = new CreateOppAndMeeting('PEO');
      coam.usr = usr;
      coam.contactId = ctct.Id;
      coam.initializeContact();
      coam.setOppForContact();
      coam.createOpportunity = true;
      coam.createMeeting = false;
      CreateOppAndMeeting.NON_VISUAL_CONTEXT = true;
      if (coam.opp != null && usr != null) {
         coam.opp.OwnerId = usr.Id;
      }
      coam.opp.OppSource__c = SOURCE_OASIS;
      
      coam.saveOpp();
      StringHelper.addToProcessNotes(sync,'After saveOpp opp='+(coam.opp != null ? coam.opp.Name : 'No Opp')+' owner='+(usr != null ? usr.Name : 'No Usr'));
      Boolean okay = (coam.opp != null && coam.opp.Id != null);
      sync.OppCreated__c = okay;
      sync.Opportunity__c = ((coam.opp != null && coam.opp.Id != null) ? coam.opp.Id : sync.Opportunity__c);
      return okay;
   } // createOpp
   
   public static String getSyncType(Boolean isUpdate) {
      String syncType = null;
      Boolean isConnectionUser = isRunningUserConnectionUser();
      if (!isUpdate) {
         if (isConnectionUser) {
            // if the connection user created the records, just send back the Ids
            syncType = SYNC_RECORD_ID;
         } else {
            // this is a new record for Paychex
            syncType = SYNC_NEW;
         }
      } else if (!isConnectionUser) {
         // as long as the connection user isn't making the updates, send the changes to Paychex
         syncType = SYNC_UPDATE;
      }
      return syncType;
   } // getSyncType;
   

   public static OasisSync__c prepareSync(OasisSync__c sync, String recName) {
      if (sync == null) {
         sync = new OasisSync__c(Name=recName);
         sync.SourceCreatedDate__c = Datetime.now();
      }
      sync.NbrTransits__c = (sync.NbrTransits__c == null ? 1 : sync.NbrTransits__c+1);
      sync.SourceLastUpdated__c = Datetime.now();
      sync.LastUpdatedPaychex__c = Datetime.now();
      sync.Source__c = SOURCE_PAYX;
      return sync;
   } // prepareSync

   public static OasisSync__c getSync(SObject rec, Map<String,OasisSync__c> syncMap) {
      OasisSync__c sync = null;
      if (syncMap != null && !syncMap.isEmpty()) {
         sync = syncMap.get(rec.Id);
         if (sync == null && rec.get('OasisId__c') != null) {
            sync = syncMap.get((String)rec.get('OasisId__c'));
         }
      } // if (syncMap != null &&
      return sync;
   } // getSync

   public static Map<String,OasisSync__c> getExistingSyncMap(SObject[] recs) {
      Set<String> syncIdSet = new Set<String>();
      for (SObject rec : recs) {
         if (rec.Id != null) {
            syncIdSet.add(rec.Id);
         }
         String oasisId = (String)rec.get('OasisId__c');
         if (String.isNotBlank(oasisId)) {
            syncIdSet.add(oasisId);
         }
      }
      return getExistingSyncMap(syncIdSet);
   } // getExistingSyncMap

   public static Map<String,OasisSync__c> getExistingSyncMap(Set<String> syncIdSet) {
      return getExistingSyncMap(syncIdSet, new Set<Id>());
   } // getExistingSyncMap
   
   public static Map<String,OasisSync__c> getExistingSyncMap(Set<String> syncIdSet, Set<Id> idSet) {
      idSet = (idSet == null ? new Set<Id>() : idSet);
      syncIdSet = (syncIdSet == null ? new Set<String>() : syncIdSet);
      Map<String,OasisSync__c> oasisSyncMap = new Map<String,OasisSync__c>();
      if (!syncIdSet.isEmpty() || !idSet.isEmpty()) {
         OasisSync__c[] oasisSyncs = [Select Id, Name
                             ,Account__c
                             ,Account__r.Id
                             ,AccountIdOasis__c
                             ,AccountIdPayx__c
                             ,Address__c
                             ,CampaignId_Oasis__c
                             ,City__c
                             ,Company__c
                             ,ConnectionReceivedId
                             ,Contact__c
                             ,Contact__r.Id
                             ,ContactIdOasis__c
                             ,ContactIdPayx__c
                             ,CS_Client_Number__c
                             ,CSCMContractStatus__c
                             ,CSContactID__c
                             ,CSImportID__c
                             ,CSOrgCategory__c
                             ,CSOrgID__c
                             ,CSOrgStatus__c 
                             ,CSPrimaryClientNumber__c
                             ,CSServiceType__c
                             ,DBA__c
                             ,Description__c
                             ,DisqualifiedReason__c
                             ,DoNotCall__c
                             ,DuplicateCheckResult__c
                             ,DuplicateNotWorkableReason__c
                             ,Email__c
                             ,Fax__c
                             ,Federal_ID_Number__c
                             ,FirstName__c
                             ,Frequency__c
                             ,Industry__c
                             ,LastName__c
                             ,Lead__c
                             ,Lead__r.Id
                             ,LeadIdOasis__c
                             ,LeadIdPayx__c
                             ,LeadSource__c
                             ,LeadStatus__c
                             ,MailingStreet__c
                             ,MailingCity__c
                             ,MailingState__c
                             ,MailingPostalCode__c
                             ,MarketingStage__c
                             ,MobilePhone__c
                             ,NAICSCode__c
                             ,NbrTransits__c
                             ,NumberOfEmployees__c
                             ,NumberOfEmployeesRange__c
                             ,Opportunity__c
                             ,Opportunity__r.Id
                             ,OppStatus__c
                             ,OwnedBy__c
                             ,OwnerHRPersonID__c
                             ,Phone__c
                             ,Phone2__c
                             ,PostalCode__c
                             ,Processed__c
                             ,ProcessNotes__c
                             ,ReceivedLastUpdated__c
                             ,SICCode__c
                             ,Source__c
                             ,SourceCreatedDate__c
                             ,SourceLastUpdated__c
                             ,State__c
                             ,SyncStatus__c
                             ,SyncType__c
                             ,Title__c
                             ,Website__c
                         From OasisSync__c
                        Where (ContactIdOasis__c in :syncIdSet
                           or ContactIdPayx__c in :syncIdSet
                           or AccountIdOasis__c in :syncIdSet
                           or AccountIdPayx__c in :syncIdSet
                           or LeadIdOasis__c in :syncIdSet
                           or LeadIdPayx__c in :syncIdSet
                           or Id in :idSet)
                          and SyncType__c != :SYNC_LEAD_CONVERTED
                       order by CreatedDate desc
                      ];
         for (OasisSync__c sync : oasisSyncs) {
            
            String key1 = ((String.isNotBlank(sync.ContactIdOasis__c) && syncIdSet.contains(sync.ContactIdOasis__c)) ? sync.ContactIdOasis__c 
                          : ((String.isNotBlank(sync.AccountIdOasis__c) && syncIdSet.contains(sync.AccountIdOasis__c)) ? sync.AccountIdOasis__c 
                              : (String.isNotBlank(sync.LeadIdOasis__c) && syncIdSet.contains(sync.LeadIdOasis__c)) ? sync.LeadIdOasis__c : null));
            if (key1 != null && !oasisSyncMap.containsKey(key1)) {
               oasisSyncMap.put(key1,sync);
            }
            String key2 = ((String.isNotBlank(sync.ContactIdPayx__c) && syncIdSet.contains(sync.ContactIdPayx__c)) ? sync.ContactIdPayx__c 
                          : ((String.isNotBlank(sync.AccountIdPayx__c) && syncIdSet.contains(sync.AccountIdPayx__c)) ? sync.AccountIdPayx__c 
                              : (String.isNotBlank(sync.LeadIdPayx__c) && syncIdSet.contains(sync.LeadIdPayx__c)) ? sync.LeadIdPayx__c : null));
            if (key2 != null && !oasisSyncMap.containsKey(key2)) {
               oasisSyncMap.put(key2,sync);
            }
            if (!idSet.isEmpty() && idSet.contains(sync.Id)) {
               oasisSyncMap.put(sync.Id, sync);
            }

         } // for (OasisSync__c sync
      } // if (!oasisIds.isEmpty
      return oasisSyncMap;
   } // getExistingSyncs

   public static void checkSave(OasisSync__c[] insertSyncs, OasisSync__c[] updateSyncs) {
      SKIP_TRIGGER=true;
      if (!insertSyncs.isEmpty()) {
         DmlHelper.performDML2(insertSyncs, DmlHelper.DML_INSERT, 'OasisSyncHelper', 'checkSave', 'Insert Oasis Sync Records', false);
         //SfToSfConnectionHelper.sendToPartner(insertSyncs);
      }
      DmlHelper.performDML2(updateSyncs, DmlHelper.DML_UPDATE, 'OasisSyncHelper', 'checkSave', 'Update Oasis Sync Records', false);
      ErrorLog.checkSave();
      SKIP_TRIGGER=false;
   } // checkSave
 */
} // class OasisSyncHelper