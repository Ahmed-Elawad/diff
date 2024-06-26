/* Methods to process on the Oasis Sync object with the Lead

  History
  -------
  05/15/2019 Dan Carmen        Created
  08/09/2019 Dan Carmen        Changes to move workable code to DuplicateCheckQueueable
  03/10/2020 Dan Carmen        Comment out all code
  
 */
public without sharing class OasisSyncLeads {
    
   /*
   If this is coming from OasisSyncQueueable
       Check the DuplicateCheckStatus__c field
           If "No Match Found" - just return the value
           If "Lead Match" - see if the lead is workable
           If "Contact Match" or "Account Match" - see if the record is workable
   */
    
   public static Boolean processLeads(Lead[] lds, Map<Id,Lead> oldMap, String overrideSyncType, ErrorLog__c runLog) {
      /*
      Boolean recordsSent = false;

      Map<Id,User> userMap = OasisSyncHelper.getUserMap(lds);
      // check leads for the OasisId__c or PEO record type or User is a client space user
      Id peoRecordTypeId = null;
      Map<Id,Lead> leadsToProcessMap = new Map<Id,Lead>();
      if (String.isNotBlank(overrideSyncType)) {
         leadsToProcessMap = new Map<Id,Lead>(lds);
      } else {
         for (Lead ld : lds) {
            User usr = userMap.get(ld.OwnerId);
            if (ld.DuplicateCheckStatus__c != 'Pending'  // don't allow pending records to go through
                  && (String.isNotBlank(ld.OasisId__c) 
                   || (usr != null && usr.CSUserId__c != null)
                   || (ld.RecordTypeId == peoRecordTypeId))) {
               leadsToProcessMap.put(ld.Id,ld);
            } 
         } // for
      }
      
      System.debug('processLeads leadsToProcessMap='+leadsToProcessMap.size()+' overrideSyncType='+overrideSyncType);
      if (leadsToProcessMap.isEmpty()) {
         return false;
      }

      Map<Id,PartnerReferral__c> partRefMap = (overrideSyncType == OasisSyncHelper.SYNC_DUPE_RESULT ? getPartRefMap(leadsToProcessMap.keySet())
                                                : new Map<Id,PartnerReferral__c>());
      ErrorLog.addToDescription(runLog,'overrideSyncType='+overrideSyncType+' partRefMap='+partRefMap.size());
      OasisSync__c[] insertSyncs = new OasisSync__c[]{};
      OasisSync__c[] updateSyncs = new OasisSync__c[]{};
      
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(leadsToProcessMap.values());
      
      // get the users identified on the syncs (if any) - only need to do this right now if the overrideSyncType is passed in
      Map<String,User> personIdUserMap = (String.isNotBlank(overrideSyncType) ? OasisSyncHelper.getUsersByPersonIdMap(syncMap.values()) : new Map<String,User>()); 
      
      Boolean isConnectionUser = OasisSyncHelper.isRunningUserConnectionUser();
      Set<Id> convertedLeadIdSet = new Set<Id>();
      
      ErrorLog.addToDescription(runLog,'processLeads leadsToProcessMap='+leadsToProcessMap.size()+' userMap='+userMap.size()+' syncMap='+syncMap.size()+' isConnectionUser='+isConnectionUser);
      System.debug('processLeads leadsToProcessMap='+leadsToProcessMap.size()+' userMap='+userMap.size()+' syncMap='+syncMap.size()+' isConnectionUser='+isConnectionUser);
      
      for (Lead ld : leadsToProcessMap.values()) {
         // log the info 
         if (runLog != null && String.isBlank(runLog.ObjectId__c)) {
            runLog.ObjectId__c = ld.Id;
            ErrorLog.addToObjectInfo(runLog,String.valueOf(ld));
         }
         Lead oldLd = (oldMap != null ? oldMap.get(ld.Id) : null);
         User usr = userMap.get(ld.OwnerId);
         Boolean clientSpaceUser = (usr != null && usr.CSUserId__c != null);
         OasisSync__c sync = OasisSyncHelper.getSync(ld,syncMap);
         User syncUsr = OasisSyncHelper.getUserFromMap(sync, personIdUserMap);
         
         System.debug('processLeads clientSpaceUser='+clientSpaceUser+' has sync='+(sync != null));

         if (oldLd == null && sync != null
                  && String.isNotBlank(overrideSyncType)
                  && overrideSyncType == OasisSyncHelper.SYNC_DUPE_RESULT 
                  //&& isConnectionUser
                  //&& String.isNotBlank(ld.DuplicateCheckStatus__c)
                  ) {
            System.debug('processLeads handling from here1');
            ErrorLog.addToDescription(runLog,'handling duplicate results: '+ld.DuplicateCheckStatus__c);
            // set the attributes on the sync record
            processLead(ld, oldLd, overrideSyncType, usr, sync, runLog, partRefMap.get(ld.Id), insertSyncs, updateSyncs);
            // check for additional criteria.
            //if (ld.DuplicateCheckStatus__c == 'Lead Match') {
               // check if the lead is workable
            //   checkAdditionalLeadCriteria(ld, sync, syncUsr, runLog);
            //} else if (ld.DuplicateCheckStatus__c == 'Contact Match' || ld.DuplicateCheckStatus__c == 'Account Match') {
            //   checkAddtionalAcctCtctCriteria(ld, sync, syncUsr, runLog);
            //} else if (ld.DuplicateCheckStatus__c == 'No Match Found') {
               // if no match then process the lead as is.
            //}
         } else if (isConnectionUser && oldLd == null && String.isBlank(overrideSyncType)) {
            // do not send the record on the insert from the connection user unless the overrideSyncType has a value
         } else if ((isConnectionUser && String.isNotBlank(overrideSyncType))
                      || (!isConnectionUser && (String.isNotBlank(ld.OasisId__c) || clientSpaceUser))) {
            // send if it's the connection user and overrideSyncType has a value (coming from dupe checking)
            // or not the connection user and has an oasis id or the user is a client space user

            System.debug('processLeads ld.IsConverted='+(ld.isConverted==true)+' has sync='+(sync != null));
            if (!ld.isConverted) {
               System.debug('processLeads handling from here2');
               // as long as the lead isn't converted just send as usual
               processLead(ld, oldLd, overrideSyncType, usr, sync, runLog, null, insertSyncs, updateSyncs);
            } else if (ld.isConverted) {
               // if the lead is converted we have to get some additional information
               convertedLeadIdSet.add(ld.Id);
            }
            recordsSent = true;
         }
      } // for (Lead ld
      
      ErrorLog.addToDescription(runLog,'convertedLeadIdSet='+convertedLeadIdSet.size());
      System.debug('processLeads convertedLeadIdSet='+convertedLeadIdSet.size());
      
      if (!convertedLeadIdSet.isEmpty()) {
         handleConvertedLeads(convertedLeadIdSet, syncMap, insertSyncs, updateSyncs, runLog);
      }
      
      ErrorLog.addToDescription(runLog,'insertSyncs='+insertSyncs.size()+' updateSyncs='+updateSyncs.size());
      recordsSent = (!insertSyncs.isEmpty() || !updateSyncs.isEmpty());
      OasisSyncHelper.checkSave(insertSyncs, updateSyncs);
      return recordsSent;
      */
      return false;
   } // processLeads
   
   /*
   public static Map<Id,PartnerReferral__c> getPartRefMap(Set<Id> leadIdSet) {
      Map<Id,PartnerReferral__c> partRefMap = new Map<Id,PartnerReferral__c>();
      PartnerReferral__c[] partRefs = [Select Id, Name, Lead__c
                                             ,DuplicateCheckStatus__c
                                             ,DuplicateNotWorkableReason__c
                                             ,Source__c
                                             ,Workable__c
                                         From PartnerReferral__c
                                        Where Lead__c in :leadIdSet
                                        order by CreatedDate desc];
      for (PartnerReferral__c partRef : partRefs) {
         // only store the latest in the map
         if (!partRefMap.containsKey(partRef.Lead__c)) {
            partRefMap.put(partRef.Lead__c,partRef);
         }
      } // for (PartnerReferral__c partRef
      System.debug('getPartRefMap leadIdSet='+leadIdSet.size()+' partRefMap='+partRefMap.size());
      return partRefMap;
   } // getPartRefMap
   
   public static void processLead(Lead ld, Lead oldLd, String syncType, User usr, OasisSync__c sync, ErrorLog__c runLog
                               ,PartnerReferral__c partRef
                               ,OasisSync__c[] insertSyncs, OasisSync__c[] updateSyncs) {
      if (String.isBlank(syncType)) {
         syncType = OasisSyncHelper.getSyncType(oldLd != null);
      }
      String msg = 'processLead ld='+ld.lastName+' syncType='+syncType+' has sync='+(sync != null)+' usr='+(usr != null ? usr.Name : 'noUser')+' partRef='+(partRef != null ? partRef.Name : 'NoPartRef');
      System.debug(msg);
      ErrorLog.addToDescription(runLog,msg);
      sync = OasisSyncHelper.prepareSync(sync, (ld.FirstName+' '+ld.LastName));
      
      sync.LeadIdPayx__c = ld.Id;
      sync.LeadIdOasis__c = ld.OasisId__c;
      
      sync.Address__c = ld.Street;
      sync.City__c = ld.City;
      sync.Company__c = ld.Company;
      sync.DisqualifiedReason__c = ld.DisqualifiedReason__c;
      sync.Email__c = ld.Email;
      sync.Fax__c = ld.Fax;
      sync.FirstName__c = ld.FirstName;
      sync.LastName__c = ld.LastName;
      sync.MobilePhone__c = ld.MobilePhone;
      sync.NumberOfEmployees__c = ld.NumberOfEmployees;
      sync.Phone__c = ld.Phone;
      sync.PostalCode__c = ld.PostalCode;
      sync.State__c = ld.State;
      sync.Title__c = ld.Title;
      sync.LeadStatus__c = ld.Status;
      sync.LeadSource__c = ld.LeadSource;
      sync.Lead__c = ld.Id;
 
      if (usr != null && usr.HR_Person_Id__c != null) {
         sync.OwnerHRPersonID__c = usr.HR_Person_Id__c;
      }
      sync.SyncType__c = syncType;
      if (syncType == OasisSyncHelper.SYNC_DUPE_RESULT && partRef != null) {
         sync.DuplicateCheckResult__c = ld.DuplicateCheckStatus__c+'-'+partRef.Workable__c;
         sync.DuplicateNotWorkableReason__c = partRef.DuplicateNotWorkableReason__c;
         ErrorLog.addToDescription(runLog,sync.DuplicateCheckResult__c);
      }

      if (ld.IsConverted) {      
         sync.ContactIdPayx__c = ld.ConvertedContactId;
         sync.AccountIdPayx__c = ld.ConvertedAccountId;
      }
      
      if (sync.Id == null) {
         insertSyncs.add(sync);
      } else {
         updateSyncs.add(sync);
      }
   } // processLead
   */
   public static void handleConvertedLeads(Set<Id> convertedLeadIdSet,Map<String,OasisSync__c> syncMap, OasisSync__c[] insertSyncs, OasisSync__c[] updateSyncs, ErrorLog__c runLog) {
      /*
      Set<String> querySet = new Set<String>();
      for (Id recId : convertedLeadIdSet) {
         querySet.add(recId);
      }

      //Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(querySet);
      
      Lead[] convertedleads = [Select Id
                                     ,FirstName, LastName
                                     ,ConvertedAccountId
                                     ,ConvertedContactId
                                     ,ConvertedDate
                                     ,IsConverted
                                     ,OasisId__c
                                 From Lead
                                Where Id in :convertedLeadIdSet
                                  and IsConverted=true];
      System.debug('handleConvertedLeads convertedLeadIdSet='+convertedLeadIdSet.size()+' convertedleads='+convertedleads.size());
      ErrorLog.addToDescription(runLog,'handleConvertedLeads convertedLeadIdSet='+convertedLeadIdSet.size()+' convertedleads='+convertedleads.size());

      for (Lead ld : convertedLeads) {
         // get the existing sync record (if it exists)
         OasisSync__c sync = OasisSyncHelper.prepareSync(syncMap.get(ld.Id), (ld.FirstName+' '+ld.LastName));
         sync.SyncType__c=OasisSyncHelper.SYNC_LEAD_CONVERTED;
         sync.LeadIdPayx__c = ld.Id;
         sync.ContactIdPayx__c = ld.ConvertedContactId;
         sync.AccountIdPayx__c = ld.ConvertedAccountId;
         sync.LeadIdOasis__c = ld.OasisId__c;
         
         sync.Lead__c = ld.Id;
         sync.Contact__c = ld.ConvertedContactId;
         sync.Account__c = ld.ConvertedAccountId;
         
         if (sync.Id == null) {
            insertSyncs.add(sync);
         } else {
            updateSyncs.add(sync);
         }
      } // for (Lead ld
      */
   } // handleConvertedLeads

/*
   // a match occurred on a lead. Check if there is any activity attached to it.   
   public static Boolean checkAdditionalLeadCriteria(Lead ld, OasisSync__c sync, User syncUsr, ErrorLog__c runLog) {
      Boolean okay = true;
      sync.DuplicateNotWorkableReason__c = '';
      Date activityDate = Date.today().addDays(-30);
      // check open activities
      Task[] tasks = [Select Id, ActivityDate, IsClosed from Task where WhoId=:ld.Id and ActivityDate >= :activityDate order by ActivityDate limit 5];
      ErrorLog.addToDescription(runLog,'checkAdditionalLeadCriteria tasks='+tasks.size());
      Boolean activityFound = (!tasks.isEmpty());
      if (!activityFound) {
         Event[] events = [Select Id, ActivityDate from Event where WhoId=:ld.Id and ActivityDate >= :activityDate order by ActivityDate limit 5];
         ErrorLog.addToDescription(runLog,'events='+events.size());
         activityFound = (!events.isEmpty());
         if (activityFound) {
            sync.DuplicateNotWorkableReason__c = 'Open Events found';
         }
      } else {
         sync.DuplicateNotWorkableReason__c = 'Open Tasks found';
      }
      sync.DuplicateCheckResult__c = ld.DuplicateCheckStatus__c+ (!activityFound ? '-Workable' : '-Not Workable');
      ErrorLog.addToDescription(runLog,'CheckStatus__c='+sync.DuplicateCheckResult__c+' NotWorkableReason='+sync.DuplicateNotWorkableReason__c);
      return okay;
   } // checkAdditionalLeadCriteria
*/
/*
o  If the incoming Oasis Lead is matched to a Prospect Client (Current Client? Is False) within the Paychex Salesforce instance AND has no Open Opportunity AND has no activity in the last 6 months, then the Lead is considered workable by the BDR
  Workable information is sent back to Oasis instance
•  This will be worked as usual by the BDR
  Partner Referral is created with the incoming information
  Record type is updated to Prospect Record Type
  Type is set to Oasis Prospect
  Hold Out – True
  Hold Out Description – Oasis Prospect
  Owner – New Oasis Generic User for placeholder. Upon the BDR working and converting they will send the Account record which should match to this one and then the owner will be updated then

If there are Open Opps with activity in the last 6 months – not workable by Oasis BDR
If there are no Open Opps but activity in the last 90 days – not workable by the Oasis BDR
If there are no Open Opps but future activity in the next 90 days – not workable by the Oasis BDR
All else is workable.
if they have an open opportunity and no activity for three months, it can be worked.

*/
/*
   // a match occurred on an account or contact. Check if there is any activity attached to it.   
   public static Boolean checkAddtionalAcctCtctCriteria(Lead ld, OasisSync__c sync, User syncUsr, ErrorLog__c runLog) {
      Boolean okay = true;
      sync.DuplicateNotWorkableReason__c = '';
      Date oppCheckDate = Date.today().addMonths(-6);
      Date activityQueryDate = Date.today().addMonths(-6);
      // check if activity in this range
      Date activityCheckDate = Date.today().addDays(-90);
      Date activityFutureDate = Date.today().addDays(90);
      Boolean workable = true;
      Lead convertedLead = null;
      String processNotes = 'checkAddtionalAcctCtctCriteria';
      try {
         convertedLead = [Select Id
                                     ,FirstName, LastName
                                     ,ConvertedAccountId
                                     ,ConvertedAccount.Id
                                     ,ConvertedAccount.Name
                                     ,ConvertedAccount.OwnerId
                                     ,ConvertedAccount.RecordType.Name
                                     ,ConvertedAccount.RecordTypeId
                                     ,ConvertedAccount.Type
                                     ,ConvertedAccount.Hold_Out__c
                                     ,ConvertedAccount.Permanent_Hold_Out_Description__c
                                     ,ConvertedContactId
                                     ,ConvertedDate
                                     ,IsConverted
                                     ,OasisId__c
                                 From Lead
                                Where Id = :ld.Id
                                  and IsConverted=true];
      } catch (Exception e) {
         //ErrorLog.addToDescription(runLog,'Error finding the converted lead for Id='+ld.Id);
         StringHelper.addToProcessNotes(sync,'Error finding the converted lead for Id='+ld.Id);
      }
      if (convertedLead == null) {
         return false;
      }
      // collect the converted account/contact info
      sync.ContactIdPayx__c = ld.ConvertedContactId;
      sync.AccountIdPayx__c = ld.ConvertedAccountId;
      Account acct = null;
      try {
         acct = [Select Id, Name, CurrentClient__c, RecordTypeId, RecordType.Id, RecordType.Name, Type
                       ,(Select Id, ActivityDate, IsClosed 
                           from Tasks 
                          where ActivityDate >= :activityQueryDate
                            and ActivityDate <= :activityFutureDate
                           order by ActivityDate desc limit 10)  // order by newest first so we just have to check the date of the first to see if recent
                       ,(Select Id, ActivityDate 
                           from Events 
                          where ActivityDate >= :activityQueryDate 
                            and ActivityDate <= :activityFutureDate
                          order by ActivityDate desc limit 10)  // order by newest first so we just have to check the date of the first to see if recent
                       ,(Select Id, Name, CloseDate from Opportunities where IsClosed = false and CreatedDate >= :oppCheckDate limit 5)
                    From Account
                   Where Id = :convertedLead.ConvertedAccountId];
      } catch (Exception e) {
         StringHelper.addToProcessNotes(sync,'Error selecting the account: '+e.getMessage()+'; '+e.getStackTraceString());
         //ErrorLog.addToDescription(runLog,'Error selecting the account: '+e.getMessage()+'; '+e.getStackTraceString());
         System.debug('checkAddtionalAcctCtctCriteria exception: '+e.getMessage()+'; '+e.getStackTraceString());
         okay = false;
      }
      
      if (acct != null) {
         System.debug('checkAddtionalAcctCtctCriteria acct='+acct.Name+' currentClient='+acct.CurrentClient__c);
         //StringHelper.addToProcessNotes(sync,'currentClient='+acct.CurrentClient__c);
         processNotes += ('; currentClient='+acct.CurrentClient__c);
         if (acct.CurrentClient__c) {
            sync.DuplicateNotWorkableReason__c = 'Current Paychex Client';
            workable=false;
         } else {
            Boolean openOpps = (!acct.Opportunities.isEmpty());
            Boolean hasTasks = (!acct.Tasks.isEmpty());
            Boolean hasEvents = (!acct.Events.isEmpty());
            System.debug('checkAddtionalAcctCtctCriteria openOpps='+openOpps+' hasTasks='+hasTasks+' hasEvents='+hasEvents);
            processNotes += ('; openOpps='+openOpps+' hasTasks='+hasTasks+' hasEvents='+hasEvents);
            if (openOpps && (hasTasks || hasEvents)) {
               //has an Open Opportunity AND has any activity in the last 6 months, then the Lead is considered not workable by the BDR
               workable = false;
               sync.DuplicateNotWorkableReason__c = 'Has Open Opportunities and Activity';
            } else { 
               // check if any of the activity is recent - just have to check the first one in the list since sorted by newest date
               Boolean hasRecentActivity = (hasTasks && acct.Tasks[0].ActivityDate >= activityCheckDate);
               if (!hasRecentActivity) {
                  hasRecentActivity = (hasEvents && acct.Events[0].ActivityDate >= activityCheckDate);
               }
               workable = !hasRecentActivity;
               if (hasRecentActivity) {
                  sync.DuplicateNotWorkableReason__c = 'Has Recent Activity';
               }
            }
         }
         
         if (workable) {
            Account updateAcct = new Account(Id=acct.Id);
            Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
            Schema.RecordTypeInfo prospectRtInfo = byNameMap.get(Label.RT_Prospect_Acct);
            if (prospectRtInfo != null) {
               updateAcct.RecordTypeId = prospectRtInfo.getRecordTypeId();
            }
            updateAcct.PEOLeasing__c = true;
            updateAcct.Type = 'Oasis Prospect';
            if (syncUsr != null) {
               updateAcct.OwnerId = syncUsr.Id;
            }
            updateAcct.Hold_Out__c=true;
            updateAcct.Permanent_Hold_Out_Description__c='Oasis Prospect';
            ZipCheckOwner.SKIP_TRIGGERS=true;
            DmlHelper.performDML2(new Account[]{updateAcct}, DmlHelper.DML_UPDATE, 'OasisSyncLeads', 'checkAddtionalAcctCtctCriteria', 'Update hold out info on Account', true);
         } // if (workable
      } // if (acct != null
      sync.DuplicateCheckResult__c = ld.DuplicateCheckStatus__c+ (workable ? '-Workable' : '-Not Workable');
      //ErrorLog.addToDescription(runLog,'CheckStatus__c='+sync.DuplicateCheckResult__c+' NotWorkableReason='+sync.DuplicateNotWorkableReason__c);
      StringHelper.addToProcessNotes(sync,(processNotes+'; CheckStatus__c='+sync.DuplicateCheckResult__c+' NotWorkableReason='+sync.DuplicateNotWorkableReason__c));
      System.debug('checkAddtionalAcctCtctCriteria CheckStatus__c='+sync.DuplicateCheckResult__c+' NotWorkableReason='+sync.DuplicateNotWorkableReason__c);
      return okay;
   } // checkAddtionalAcctCtctCriteria
    */
} // class OasisSyncLeads