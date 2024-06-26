/* 
  Handle SLAs and expirations
  
  SLAHelperBatch shb = new SLAHelperBatch(SLAHelperBatch.MODE_TP_EXPIRE);
  SLAHelperBatch shb = new SLAHelperBatch();
  Database.executeBatch(shb, 100);

  Apex_Batch_Control options used:
  Active__c - is this turned on
  BatchSize__c - how many records to process at once
  Minutes_till_Launch__c - interval until next launch (has to be greater than zero)
  
   
  History
  -------
  08/06/2018 Dan Carmen        Created
  08/21/2018 Dan Carmen        Close out a stage record if it no longer matches its associated lead/contact
  10/02/2018 Dan Carmen          Add in a Stage History record
  10/16/2018 Dan Carmen          Missing the name field in the Stage History query
  11/02/2018 Dan Carmen          Opportunity SLA reroute message
  11/15/2018 Dan Carmen          Handle if linked to a converted lead without a contact
  12/04/2018 Dan Carmen          Change for queue when assigning Opportunity
  05/02/2019 Dan Carmen          Change to fix an exception happening in prod.
  07/11/2019 Dan Carmen          Add NextVerifyDate__c to query parameters 
  07/17/2019 Dan Carmen          Change to tune the SQL
  08/20/2019 Dan Carmen          Add ability to not re-route opportunities when hits SLA
  02/27/2020 Cindy Freeman       commented code marking Contact After trigger already executed, we need it to fire to create Recycled history record
  08/07/2020 Dan Carmen          Fix for the expiration dates calculating properly.
  08/31/2021 Dan Carmen          Add in functionality to skip email steps on their due date.
  12/02/2021 Dan Carmen          Add check for Cadence__r.Auto_Skip_Steps__c into TP Skip query
  12/28/2022 Jaipal              Updated the Chatter notification within the method createOppChatterMsg and removed opp.Owner.DSA_FSS__c in same method to remove that user to fire Chatter
  02/03/2023 Dan Carmen          Force the Referral Triggers to fire
  01/30/2024 Dan Carmen          Commented out Opportunity handling. Can be deleted sometime in the future if not used.
  
*/
global without sharing class SLAHelperBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {
    
   public static final String CLASS_NAME='SLAHelperBatch';
      
   global JobHelper jh = new JobHelper(CLASS_NAME);
   global Account[] accts;
   global Set<Id> recTypeIdSet = null;
   //global Id mmsRTId;
   global Date todayDate = System.today();

   // keep track of the count of each update type
   global Map<String,Integer> countByTypeMap = new Map<String,Integer>();
   
   // The time the process started. 
   global DateTime startTime;
   // messages that occur during the process.
   global String processNotes = '';
   
   global SLAHelperBatch() {
      system.debug('in constructor');
   } // SLAHelperBatch

   global SLAHelperBatch(String p_currentMode) {
      system.debug('in constructor p_currentMode='+p_currentMode);
      currentMode = p_currentMode;
   } // SLAHelperBatch
    
   // The total number of stage history records found.
   global Integer numberRecsFound = 0;
      
   public static String MODE_STAGE_HISTORY='StageHistory';
   //public static String MODE_OPPORTUNITY='Opportunity';
   public static String MODE_CADENCE='Cadence';
   public static String MODE_TP_EXPIRE='TouchpointExpire';
   public static String MODE_TP_SKIP='TouchpointSkip';
   
   public static Integer QUERY_DAYS=Integer.valueOf(Label.SLAHelperBatch_QueryDays);
   // for testing purporses
   global static Boolean RUN_ONCE=false;
   
   global String currentMode=null;
    
   global void execute(SchedulableContext sc) {
      system.debug('Batch Process scheduled');
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      // pull from the custom setting, otherwise use a default value.
      Integer batchSize = (abc != null ? Integer.valueOf(abc.BatchSize__c) : 100);
      SLAHelperBatch shb = new SLAHelperBatch();
      database.executeBatch(shb, batchSize);
   } // execute
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      
      if (String.isBlank(currentMode)) {
         currentMode = MODE_STAGE_HISTORY;
      }
      System.debug('SLAHelperBatch currentMode='+currentMode);
      
      jh.tracker.Job_Name__c += currentMode;
      jh.setStarted();
      
      DateTime rightNow = DateTime.now();
      if (currentMode == MODE_STAGE_HISTORY) {
         return Database.getQueryLocator([SELECT Id, Name
                                             ,Lead__c, Lead__r.Id, Lead__r.Name, Lead__r.Lead_Stage__c, Lead__r.OwnerId, Lead__r.Referral__c
                                             ,Lead__r.Recycle_Reason__c, Lead__r.IsConverted
                                             ,Contact__c, Contact__r.Id, Contact__r.Name, Contact__r.Contact_Stage__c
                                             ,Contact__r.NSSOwnership__c
                                             ,AssignedQueueName__c
                                             ,Exited_Date_Time__c
                                             ,Expired__c,Run_Expiration_Scheduled_Job__c 
                                             ,Expiration_Deadline__c
                                             ,ExpirationMinutes__c
                                             ,ExpirationProcessed__c
                                             ,New_Stage__c
                                             ,ProcessNotes__c
                                             ,ReferralNotFound__c
                                             ,SLA_Deadline__c
                                             ,SLAHitCount__c
                                             ,SLAMinutes__c
                                             ,SLAProcessed__c
                                             ,SLA_Reached__c
                                             ,StageExpired__c
                                             ,TimeZoneAbbrev__c
                                             ,CreatedDate
                                         FROM Stage_History__c 
                                        WHERE Opportunity__c = null
                                          AND NextVerifyDate__c <= :rightNow]);
                                      //  WHERE (Expired__c = true and ExpirationProcessed__c = false and Run_Expiration_Scheduled_Job__c = false)
                                      //       or (SLA_Reached__c = true and SLAProcessed__c = false and Expired__c = false)]);
/* commented out 1/30/2024
      } else if (currentMode == MODE_OPPORTUNITY) {
         DateTime createdDateCheck = DateTime.now().addDays(-QUERY_DAYS);
         return Database.getQueryLocator([Select Id, Name, StageName, Probability
                                                ,Owner.Id
                                                ,Owner.ManagerId
                                                ,Owner.Manager.Email
                                                ,Owner.Manager.Id
                                                ,Owner.DSA_FSS__c
                                                ,Owner.DSA_FSS__r.Email
                                                ,Owner.DSA_FSS__r.Id
                                                ,Owner.Email
                                                ,Accept_Deadline__c, Accept_Reminder_Deadline__c
                                                ,AcceptDeadlineRecalc__c, LeadSource
                                                ,NSS_Source__c
                                                ,ProcessNotes__c
                                                ,ReferralLookup__r.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c
                                                ,ReferralLookup__r.Referral_Partner__r.NSS_Source__c
                                                ,ReferralLookup__r.Referral_Partner__r.Expired_SLA_queue__c
                                                ,ReferralLookup__r.PartnerReferral__r.Destination__c
                                                ,ReferralLookup__r.Id
                                                ,ReferralLookup__r.NotifyOwnerMsg__c
                                                ,ReferralLookup__r.OwnerId
                                                ,Account.TimeZoneAbbrev__c
                                            From Opportunity
                                           Where (Accept_Deadline__c < :rightNow
                                              or Accept_Reminder_Deadline__c < :rightNow)
                                             and CreatedDate > :createdDateCheck]);
*/
      } else if (currentMode == MODE_CADENCE) {
         return Database.getQueryLocator([Select Id, Name
                                                ,Close_Date__c
                                                ,CloseDateTime__c
                                                ,Status__c
                                                ,CarRecord__c
                                                ,CarRecord__r.Id
                                                ,CarRecord__r.AccountId__c
                                                ,CarRecord__r.ContactId__c
                                                ,CarRecord__r.LeadId__c
                                                ,CarRecord__r.ReferralAccount__c
                                                ,CarRecord__r.Activity_Log__c
                                                ,CarRecord__r.Closed__c
                                                ,CarRecord__r.Close_Date__c
                                                ,CarRecord__r.ExpirationDate__c
                                                ,CarRecord__r.CloseReason__c
                                                ,CarRecord__r.Rep_Closed__c
                                                ,CarRecord__r.Sales_Notes__c
                                                ,CarRecord__r.Status__c
                                            From Cadence_Touchpoint__c
                                           Where CarRecord__r.ExpirationDate__c < :rightNow
                                             and CarRecord__r.Closed__c = false
                                             and CarRecord__r.StageHistory__c = null
                                             and IsLatestTouchpoint__c=true]);
      } else if (currentMode == MODE_TP_EXPIRE) {
         return Database.getQueryLocator([Select Id, Name
                                                ,Close_Date__c
                                                ,CloseDateTime__c
                                                ,Status__c
                                                ,CarRecord__c
                                                ,CarRecord__r.Id
                                                ,CarRecord__r.AccountId__c
                                                ,CarRecord__r.ContactId__c
                                                ,CarRecord__r.LeadId__c
                                                ,CarRecord__r.ReferralAccount__c
                                                ,CarRecord__r.Activity_Log__c
                                                ,CarRecord__r.Closed__c
                                                ,CarRecord__r.Close_Date__c
                                                ,CarRecord__r.ExpirationDate__c
                                                ,CarRecord__r.CloseReason__c
                                                ,CarRecord__r.Rep_Closed__c
                                                ,CarRecord__r.Sales_Notes__c
                                                ,CarRecord__r.Status__c
                                            From Cadence_Touchpoint__c
                                           Where ExpirationDate__c <= :rightNow
                                             and Close_Date__c = null
                                             and Status__c = 'Open']);
      } else if (currentMode == MODE_TP_SKIP) {
         return Database.getQueryLocator([Select Id, Name
                                                ,Close_Date__c
                                                ,CloseDateTime__c
                                                ,Status__c
                                                ,CarRecord__c
                                                ,CarRecord__r.Id
                                                ,CarRecord__r.AccountId__c
                                                ,CarRecord__r.ContactId__c
                                                ,CarRecord__r.LeadId__c
                                                ,CarRecord__r.ReferralAccount__c
                                                ,CarRecord__r.Activity_Log__c
                                                ,CarRecord__r.Closed__c
                                                ,CarRecord__r.Close_Date__c
                                                ,CarRecord__r.ExpirationDate__c
                                                ,CarRecord__r.CloseReason__c
                                                ,CarRecord__r.Rep_Closed__c
                                                ,CarRecord__r.Sales_Notes__c
                                                ,CarRecord__r.Status__c
                                            From Cadence_Touchpoint__c
                                           Where Due_Date__c <= :rightNow
                                             and Close_Date__c = null
                                             and NoEmailEligibleContacts__c = true
                                             and SignificantEmailEligible__c = false
                                             and Cadence_Touchpoint_Step__r.Touchpoint_Type__c = 'Email'
                                             and Cadence__r.Auto_Skip_Steps__c = true
                                             and Status__c = 'Open']);
      }
      return null;
   } // start

   global void execute(Database.BatchableContext BC, List<SObject> scope) {
      system.debug('SLAHelperBatch.execute recs='+scope.size());
      numberRecsFound += scope.size();
      // what type of records are we processing?
      /* commented out 1/30/2024
      if (scope[0].getSObjectType() == Opportunity.sObjectType) {
         handleOpportunities((Opportunity[])scope);
      } else 
      */
      if (scope[0].getSObjectType() == Stage_History__c.sObjectType) {
         handleStageHistoryRecs((Stage_History__c[])scope);
      } else if (currentMode == MODE_CADENCE) {
         CadenceHelper.handleTouchpoints((Cadence_Touchpoint__c[])scope);
      } else if (currentMode == MODE_TP_EXPIRE) {
         CadenceHelper.handleExpiredTPs((Cadence_Touchpoint__c[])scope);
      } else if (currentMode == MODE_TP_SKIP) {
         WorkQueueController.skipThisTouchpoint((Cadence_Touchpoint__c[])scope, CadenceUpdate.EMAIL_AUTOSKIP_REASON,false);
      }
      
   } // execute
    
   global void handleStageHistoryRecs(Stage_History__c[] recs) {
      Stage_History__c[] slaRecs = new Stage_History__c[]{};
      Stage_History__c[] expiredRecs = new Stage_History__c[]{};
      Map<Id,Stage_History__c> expiredRecMap = new Map<Id,Stage_History__c>();
      // history records we need to update
      Stage_History__c[] updateRecs = new Stage_History__c[]{};
      
      Set<Id> ctctLeadIdSet = new Set<Id>();
      
      for (Stage_History__c stageHist : recs) {
         // if the lead is converted we're not going to use it.
         String recordStage = (stageHist.Contact__c != null ? stageHist.Contact__r.Contact_Stage__c 
                                : ((stageHist.Lead__c != null && !stageHist.Lead__r.IsConverted) ? stageHist.Lead__r.Lead_Stage__c : null));
         // if the current stage on the Stage History does not match the stage on the associated contact/lead, then we'll clear out that record.
         if (String.isBlank(recordStage)) {
            addTohistNotes(stageHist, 'Current record stage could not be determined. Clearing SLA Dates');
            stageHist.ExpirationProcessed__c = true;
            stageHist.SLAProcessed__c = true;
            updateRecs.add(stageHist);
         } else if (stageHist.New_Stage__c != recordStage) {
            addTohistNotes(stageHist, 'Stage of '+stageHist.New_Stage__c+' does not match the record stage of '+recordStage+' Clearing SLA Dates');
            //stageHist.Expiration_Deadline__c = null;
            //stageHist.SLA_Deadline__c=null;
            stageHist.ExpirationProcessed__c = true;
            stageHist.SLAProcessed__c = true;
            updateRecs.add(stageHist);
         } else {
            Id recId = (stageHist.Contact__c != null ? stageHist.Contact__c : stageHist.Lead__c);
            if (recId != null) {
               ctctLeadIdSet.add(recId);
               if (stageHist.SLA_Reached__c && !stageHist.Expired__c) {
                  slaRecs.add(stageHist);
               } else if (stageHist.Expired__c && (!stageHist.Run_Expiration_Scheduled_Job__c || !stageHist.ExpirationProcessed__c)) {
                  expiredRecs.add(stageHist);
                  expiredRecMap.put(stageHist.Id,stageHist);
               }
            } // if (recId != null
         }
      } // for (Stage_History__c stageHist
      
      processNotes += ' \nhandleStageHistoryRecs slaRecs='+slaRecs.size()+' expiredRecMap='+expiredRecMap.size();
      Set<String> queueNameSet = new Set<String>();
      queueNameSet.add(DEFAULT_QUEUE_NAME);
      Map<Id,Referral__c[]> refMap = getReferralMap(ctctLeadIdSet, queueNameSet);
      
      Map<Id,Lead> updateLeadMap = new Map<Id,Lead>();
      Map<Id,Contact> updateCtctMap = new Map<Id,Contact>();
      Map<Id,Referral__c> updateRefMap = new Map<Id,Referral__c>();
      
      if (!expiredRecMap.isEmpty()) {
         handleExpired(expiredRecMap, refMap, updateLeadMap, updateCtctMap, updateRefMap);
         // update all of the Stage History records
         updateRecs.addAll(expiredRecMap.values());
      }
      if (!slaRecs.isEmpty()) {
         handleSLA(slaRecs, queueNameSet, refMap, updateRefMap);
         // update all of the Stage History records
         updateRecs.addAll(slaRecs);
      }
      
      processNotes += '\n updateRecs='+updateRecs.size()+' updateLeadMap='+updateLeadMap.size()+' updateCtctMap='+updateCtctMap.size()+' updateRefMap='+updateRefMap.size();

      DmlHelper.performDML(updateRecs, DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleStageHistoryRecs', 'Updating Stage History', false);
      //LeadMethods.LEAD_BEFORE_EXECUTING=true;
      LeadMethods.LEAD_AFTER_EXECUTING=true;
      DmlHelper.performDML(updateLeadMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleStageHistoryRecs', 'Updating Leads', false);
      //ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      //ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;        // CMFCMF
      DmlHelper.performDML(updateCtctMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleStageHistoryRecs', 'Updating Contacts', false);
      ReferralTriggerActions.SKIP_TRIGGER=false;
      DmlHelper.performDML(updateRefMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleStageHistoryRecs', 'Updating Referrals', false);
      ErrorLog.checkSave();
   } // handleStageHistoryRecs
   
   global Integer leadsHandled = 0;
   global Integer ctctsHandled = 0;
   
   global void handleSLA(Stage_History__c[] slaRecs, Set<String> queueNameSet, Map<Id,Referral__c[]> refMap
                        ,Map<Id,Referral__c> updateRefMap) {
      String[] queueNames = new String[]{};
      queueNames.addAll(queueNameSet);
      // get all of the possible queues that would be used for reassignment (based on the queue names previously selected)
      Map<String,Group> queueMap = UserHelper.getQueueMapByName(queueNames);
      processNotes += '\n handleSLA slaRecs='+slaRecs.size()+' queueNames='+queueNames+' queueMap='+queueMap;
      
      StageHistorySLATracker__c[] trackersToInsert = new StageHistorySLATracker__c[]{};
      
      for (Stage_History__c stageHist : slaRecs) {
         Id recId = (stageHist.Contact__c != null ? stageHist.Contact__c : stageHist.Lead__c);
         // this was just for debugging purposes
         //processNotes += '\n recId='+recId+' hasContact='+(stageHist.Contact__c != null)+' hasLead='+(stageHist.Lead__c != null);
         if (stageHist.Contact__c != null) {
            handleSLAContact(stageHist, refMap.get(recId), queueMap, updateRefMap, trackersToInsert);
         } else if (stageHist.Lead__c != null) {
            handleSLALead(stageHist, refMap.get(recId), queueMap, updateRefMap, trackersToInsert);
         }
         stageHist.Contact__r = null;
         stageHist.Lead__r = null;
      } // for (Stage_History__c stageHist
      processNotes += '\n handleSLA end';
      DmlHelper.performDML(trackersToInsert, DmlHelper.DML_INSERT, 'SLAHelperBatch', 'handleSLA', 'Insert Tracker Records', false);
   } // handleSLA

   global void handleSLAContact(Stage_History__c stageHist, Referral__c[] refs, Map<String,Group> queueMap
                            ,Map<Id,Referral__c> updateRefMap, StageHistorySLATracker__c[] trackersToInsert) {
      ctctsHandled++;
      System.debug('handleSLAContact ctct='+stageHist.Contact__r.Name);
      Referral__c chosenRef = null;
      
      if (refs != null) {
         Referral__c latestRef;
         Referral__c refWithOpp;
         Referral__c refNoOpp;
         
         for (Referral__c ref : refs) {
            // grab the first referral
            if (latestRef == null) {
               latestRef = ref;
            }
            if (refWithOpp == null && ref.Selling_Opportunity__r != null) {
               refWithOpp = ref;
            }
            if (refNoOpp == null && ref.Selling_Opportunity__r == null) {
               refNoOpp = ref;
            }
         } // for (Referral__c ref : refs
         
         String ctctStageName = stageHist.Contact__r.Contact_Stage__c;
         if (ctctStageName == 'MQL' || ctctStageName == 'TQO') {
            chosenRef = refWithOpp;
         } else if (ctctStageName == 'TQO') {
            chosenRef = refNoOpp;
         }
         if (chosenRef == null && refWithOpp != null && (ctctStageName == 'SQO' || ctctStageName == 'TQO')) {
            chosenRef = refWithOpp;
         }
         if (chosenRef == null) {
            chosenRef = latestRef;
         }
      } // if (refs != null
      
      StageHistorySLATracker__c shst = createTracker(stageHist, chosenRef);
      trackersToInsert.add(shst);
      
      reassignReferral(chosenRef, queueMap, updateRefMap, stageHist);
      shst.ReferralNotFound__c = stageHist.ReferralNotFound__c;

      updateSLA(stageHist, stageHist.TimeZoneAbbrev__c);
   } // handleSLAContact
   
   global void handleSLALead(Stage_History__c stageHist, Referral__c[] refs, Map<String,Group> queueMap
                            ,Map<Id,Referral__c> updateRefMap, StageHistorySLATracker__c[] trackersToInsert) {
      leadsHandled++;
      System.debug('handleSLALead ld='+stageHist.Lead__r.Name);
      // should only be one per lead. The list is ordered newest first, we'll just use that one.
      Referral__c ref = (refs != null && !refs.isEmpty() ? refs[0] : null);

      StageHistorySLATracker__c shst = createTracker(stageHist, ref);
      trackersToInsert.add(shst);

      reassignReferral(ref, queueMap, updateRefMap, stageHist);
      shst.ReferralNotFound__c = stageHist.ReferralNotFound__c;
      updateSLA(stageHist, stageHist.TimeZoneAbbrev__c);
   } // handleSLALead

   global StageHistorySLATracker__c createTracker(Stage_History__c stageHist, Referral__c ref) {
      StageHistorySLATracker__c shst = new StageHistorySLATracker__c(Name=stageHist.Name, StageHistory__c=stageHist.Id);
      shst.PreviousOwner__c = (ref != null && ((String)ref.OwnerId).startsWith('005') ? ref.OwnerId : null);
      shst.AssignedQueueName__c = stageHist.AssignedQueueName__c;
      shst.SLAMinutes__c = stageHist.SLAMinutes__c;
      return shst;
   } // createTracker
   
   // for testing purposes so we don't have to rely on the custom metadata
   public static Integer TEST_SLA_MINUTES = null;
   
   global static Map<String,Stage_SLA__mdt> stageMdtMap = new Map<String,Stage_SLA__mdt>();
   
   global static Stage_SLA__mdt getStageSLA(String objectType, String stageName) {
      String key=objectType+stageName;
      Stage_SLA__mdt stage = stageMdtMap.get(key);
      if (stage == null) {
         try {
            stage = [SELECT MasterLabel, DeveloperName, SAL_Minutes__c ,Expiration_Minutes__c, Stage__c  
                                      FROM Stage_SLA__mdt
                                     Where MasterLabel = :objectType
                                       and Stage__c = :stageName
                                     limit 1
                                      ];
            stageMdtMap.put(key,stage);
         } catch (Exception e) {
            System.debug('getStageSLA Could not find Stage Setup for '+objectType+' and '+stageName);
         }
      } // if (stage == null)
      return stage;
   } // getStageSLA
   
   // update the sla date to the next value unless it goes past the expiration date
   // increment the hit counter so we know how many times the SLA has been hit.
   global void updateSLA(Stage_History__c stageHist, String timeZoneAbbrev) {
      BusinessHours busHours = DG_LMF_Service.getBusinessHours(timeZoneAbbrev);
      String histNotes = 'Updating SLA busHours='+(busHours != null ? busHours.Name : 'busHours not found! ');
      
      String objectType = (stageHist.Contact__c != null ? 'Contact' : 'Lead');
      Stage_SLA__mdt stageSLA = getStageSLA(objectType, stageHist.New_Stage__c);

      if (stageSLA != null && busHours != null && stageSLA.SAL_Minutes__c != null) {
         // for testing
         Integer intSLAminutes = (TEST_SLA_MINUTES != null ? TEST_SLA_MINUTES : Integer.valueof(stageSLA.SAL_Minutes__c));
         stageHist.SLAMinutes__c = intSLAminutes;
         System.debug('updateSLA intSLAminutes='+intSLAminutes);
         DateTime newDeadline = BusinessHours.add(busHours.id , DateTime.now(), intSLAminutes * 60000);
         // make sure the deadline isn't past the expiration date
         if (stageHist.Expiration_Deadline__c != null && newDeadline < stageHist.Expiration_Deadline__c) {
            histNotes += ' \nChanging SLA Deadline from '+stageHist.SLA_Deadline__c.format('M/d/yyyy H:mm:ss')+' to '+newDeadline.format('M/d/yyyy H:mm:ss');
            stageHist.SLA_Deadline__c=newDeadline;
         } else if (stageHist.Expiration_Deadline__c != null && newDeadline >= stageHist.Expiration_Deadline__c) {
            histNotes += ' \nClearing SLA Deadline of '+stageHist.SLA_Deadline__c.format('M/d/yyyy H:mm:ss')+' new deadline of '+newDeadline.format('M/d/yyyy H:mm:ss')+' falls outside of Expiration';
            //stageHist.SLA_Deadline__c=null;
            stageHist.SLAProcessed__c = true;
         }
      } // if (stageSLA != null
      
      // increment the hit counter
      Integer currentHits = (stageHist.SLAHitCount__c != null ? Integer.valueOf(stageHist.SLAHitCount__c) : 0);
      currentHits++;
      stageHist.SLAHitCount__c = currentHits;
      histNotes += ' \nChanged SLA Hit Counter to '+currentHits;
      addToHistNotes(stageHist, histNotes);
   } // updateSLA
   
   global Group reassignReferral(Referral__c ref, Map<String,Group> queueMap, Map<Id,Referral__c> updateRefMap, Stage_History__c stageHist) {
      Group queue = null;
      stageHist.ReferralNotFound__c = (ref == null);
      if (ref != null) {
         String queueName = ((ref.Referral_Partner__r != null && String.isNotBlank(ref.Referral_Partner__r.Expired_SLA_queue__c)) ? ref.Referral_Partner__r.Expired_SLA_queue__c 
                              : ((ref.PartnerReferral__r != null && String.isNotBlank(ref.PartnerReferral__r.Destination__c)) ? ref.PartnerReferral__r.Destination__c 
                              : DEFAULT_QUEUE_NAME));
         stageHist.AssignedQueueName__c = queueName;
         queue = queueMap.get(queueName);
         String refNotes = 'assigning to queue name='+queueName+' id='+(queue != null ? queue.Id : null)+' queueMap='+queueMap.size();
         System.debug('reassignReferral updating owner on '+ref.Id);
         
         if (queue != null) {
            System.debug('reassignReferral setting queue as owner');
            ref.OwnerId = queue.Id;
         }
         ReferralMethods.addToProcessNotes(ref,refNotes);
         ref.Selling_Opportunity__r = null;
         updateRefMap.put(ref.Id, ref);
      } else {
         ReferralMethods.addToProcessNotes(ref,'Referral was not found - Ownership not handled');
      } // if (ref != null
      return queue;
   } // reassignReferral
   
   public static String LEAD_RECYCLE='Recycle';
   public static String LEAD_EXCEED_SLA=Label.SLA_ExceededRecycleMsg;
   
   global void handleExpired(Map<Id,Stage_History__c> expiredRecMap, Map<Id,Referral__c[]> refMap
                             ,Map<Id,Lead> updateLeadMap, Map<Id,Contact> updateCtctMap
                             ,Map<Id,Referral__c> updateRefMap) {
      // get the marketing user id to update the owner
      Id marketoSyncUserId = DoNotSyncCheck.getMarketoSyncId();
      System.debug('handleExpired marketoSyncUserId='+marketoSyncUserId);
      processNotes += ' \nhandleExpired marketoSyncUserId='+marketoSyncUserId;
      Map<Id,Cadence_Assignment_Record__c> updateCarMap = new Map<Id,Cadence_Assignment_Record__c>();
      Map<Id,Cadence_Touchpoint__c> updateTpMap = new Map<Id,Cadence_Touchpoint__c>();
                                 
      // get any open CAR records - we will close these when the stage expires
      Map<Id,Cadence_Assignment_Record__c> carMap = getOpenCars(expiredRecMap.keySet());
                                 
      for (Stage_History__c stageHist : expiredRecMap.values()) {
         // set the flags so it's not picked up again
         stageHist.Run_Expiration_Scheduled_Job__c = true;
         stageHist.ExpirationProcessed__c = true;
         stageHist.SLAProcessed__c=true;
         stageHist.StageExpired__c = true;
         Id recId = (stageHist.Contact__c != null ? stageHist.Contact__c : stageHist.Lead__c);
         addToHistNotes(stageHist, 'recId='+recId);
         Referral__c[] refs = refMap.get(recId);
         if (refs != null) {
            for (Referral__c ref : refs) {
               ref.OwnerId = marketoSyncUserId;
               ref.Selling_Opportunity__r = null;
               ReferralMethods.addToProcessNotes(ref,'Changed Owner to Marketo User due to Expired Stage History');
               System.debug('handleExpired updating owner on '+ref.Id);
               updateRefMap.put(ref.Id, ref);
            }
         } // if (refs != null
         if (stageHist.Contact__r != null && stageHist.Contact__r.NSSOwnership__c != DoNotSyncCheck.MARKETO_SYNC_USER) {
            addToHistNotes(stageHist, 'Expiring Record Changing Contact Status to '+LEAD_RECYCLE+' and Recycle Reason to '+LEAD_EXCEED_SLA);
            stageHist.Contact__r.NSSOwnership__c = DoNotSyncCheck.MARKETO_SYNC_USER;
            stageHist.Contact__r.Contact_Stage__c = LEAD_RECYCLE; 
            stageHist.Contact__r.Recycle_Reason__c = LEAD_EXCEED_SLA; 
            updateCtctMap.put(stageHist.Contact__r.Id, stageHist.Contact__r);
         } else if (stageHist.Lead__r != null && !stageHist.Lead__r.IsConverted
                      && (stageHist.Lead__r.Lead_Stage__c != LEAD_RECYCLE || stageHist.Lead__r.Recycle_Reason__c != LEAD_EXCEED_SLA)) {
            addToHistNotes(stageHist, 'Expiring Record Changing Lead Status to '+LEAD_RECYCLE+' and Recycle Reason to '+LEAD_EXCEED_SLA);
            stageHist.Lead__r.Lead_Stage__c = LEAD_RECYCLE;
            stageHist.Lead__r.Recycle_Reason__c = LEAD_EXCEED_SLA;
            updateLeadMap.put(stageHist.Lead__r.Id, stageHist.Lead__r);
         }
         handleTouchpointExpire(stageHist, carMap.get(stageHist.Id), updateCarMap, updateTpMap);
      } // for (Stage_History__c hist
      DmlHelper.performDml2(updateCarMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleExpired', 'Update CARs', false);
      DmlHelper.performDml2(updateTpMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleExpired', 'Update Touchpoinsts', false);
      ErrorLog.checkSave();
   } // handleExpired
    
    public static void handleTouchpointExpire(Stage_History__c stageHist, Cadence_Assignment_Record__c car, Map<Id,Cadence_Assignment_Record__c> updateCarMap, Map<Id,Cadence_Touchpoint__c> updateTpMap) {
        if (car == null) {
            return;
        }
        addToHistNotes(stageHist, 'Closing car='+car.Id+', Name='+car.Name);
        Cadence_Touchpoint__c tp = (!car.Cadence_Touchpoints__r.isEmpty() ? car.Cadence_Touchpoints__r[0] : null);
        if (tp != null) {
            tp.Close_Date__c = Date.today();
            tp.Status__c = 'Closed - Expired';
            updateTpMap.put(tp.Id,tp);
        }
        car.Closed__c = true;
        car.Close_Date__c = Date.today();
        car.CloseReason__c = 'Touchpoint Expired';
        car.Rep_Closed__c = false;
        car.Status__c = 'Closed';
        String notes = 'Expired due to reaching the Expiration Date on the Marketing Stage';
        StringHelper.addNotesToField(car, 'Activity_Log__c', WorkQueueController.ACTIVITY_LOG_SIZE, notes, true);
        updateCarMap.put(car.Id,car);
    } // handleTouchpointExpire
    
   public static Map<Id,Cadence_Assignment_Record__c> getOpenCars(Set<Id> histIdSet) {
      Map<Id,Cadence_Assignment_Record__c> carMap = new Map<Id,Cadence_Assignment_Record__c>();
      Cadence_Assignment_Record__c[] cars = [Select Id, Name
                                                   ,Cadence__r.Cadence_Type__c
                                                   ,Activity_Log__c
                                                   ,Closed__c
                                                   ,CloseReason__c
                                                   ,Close_Date__c
                                                   ,ExpirationDate__c
                                                   ,Sales_Notes__c
                                                   ,StageHistory__c
                                                   ,Status__c
                                                   ,(Select Id, Close_Date__c, Status__c
                                                        From Cadence_Touchpoints__r
                                                       Where IsLatestTouchpoint__c=true)
                                               From Cadence_Assignment_Record__c
                                              Where StageHistory__c in :histIdSet
                                                and Closed__c = false];
      for (Cadence_Assignment_Record__c car : cars) {
         carMap.put(car.StageHistory__c, car);
      }
      return carMap;
   } // getOpenCars
   
   public static String OPP_OWNER_NOTIFY=Label.OppSLA_Message;
   
   public static Map<Id,Stage_History__c> getOppStageHistoryMap(Id[] oppIds) {
      Map<Id,Stage_History__c> stageHistoryMap = new Map<Id,Stage_History__c>();
      for (Stage_History__c[] histories : [Select Id, Name, CreatedDate
                                                        ,AssignedQueueName__c
                                                        ,Exited_Date_Time__c, Expiration_Deadline__c
                                                        ,ExpirationMinutes__c, ExpirationProcessed__c
                                                        ,Expired__c
                                                        ,New_Stage__c
                                                        ,Opportunity__c, ProcessNotes__c
                                                        ,ReferralNotFound__c
                                                        ,Run_Expiration_Scheduled_Job__c
                                                        ,SLA_Deadline__c, SLAHitCount__c, SLAMinutes__c, SLAProcessed__c,SLA_Reached__c
                                                        ,StageExpired__c
                                                        ,Stage_Exited_To__c, TimeZoneAbbrev__c
                                                    From Stage_History__c
                                                   Where Opportunity__c in :oppIds
                                                   order by CreatedDate desc]) {
         for (Stage_History__c hist : histories) {
            // only keep the first one selected (which should be the latest)
            if (!stageHistoryMap.containsKey(hist.Opportunity__c)) {
               stageHistoryMap.put(hist.Opportunity__c, hist);
            }
         }
      } // for (Stage_History__c[] histories
      return stageHistoryMap;
   } // getOppStageHistoryMap
   
   public static Boolean REROUTE_OPPS = (Label.SLABatch_RerouteOpps == 'Y');
   /* commented out 1/30/2024
   global void handleOpportunities(Opportunity[] opps) {
      // get the opportunity ids
      Id[] oppIds = new Id[]{};
      
      Map<Id, Referral__c> updateRefMap = new Map<Id,Referral__c>();
      Stage_History__c[] historyToUpsert = new Stage_History__c[]{};
      StageHistorySLATracker__c[] trackersToInsert = new StageHistorySLATracker__c[]{};
      Messaging.SingleEmailMessage[] emailsToSend = new Messaging.SingleEmailMessage[]{};
      
      // it appears we cannot reference the DSA attributes when selecting as part of the owner. So we'll collect the IDs and select 
      // those separately so we can reference the email later.
      Set<Id> userIdSet = new Set<Id>();
      Set<String> queueNameSet = new Set<String>();
      queueNameSet.add(DEFAULT_QUEUE_NAME);
      
      for (Opportunity opp : opps) {
         oppIds.add(opp.Id);
         if (opp.Owner.DSA_FSS__c != null) {
            userIdSet.add(opp.Owner.DSA_FSS__c);
         }
         // collect all of the queue names so we only have to query once
         if (opp.ReferralLookup__r != null) {
            if (opp.ReferralLookup__r.Referral_Partner__r != null && String.isNotBlank(opp.ReferralLookup__r.Referral_Partner__r.Expired_SLA_queue__c)) {
               queueNameSet.add(opp.ReferralLookup__r.Referral_Partner__r.Expired_SLA_queue__c);
            }
            if (opp.ReferralLookup__r.PartnerReferral__r != null && String.isNotBlank(opp.ReferralLookup__r.PartnerReferral__r.Destination__c)) {
               queueNameSet.add(opp.ReferralLookup__r.PartnerReferral__r.Destination__c);
            }
         }
      } // for (Oppportunity opp

      Map<Id,Stage_History__c> stageHistMap = getOppStageHistoryMap(oppIds);
      
      // select the Ids so we can reference the attributes for the DSA
      Map<Id,User> userMap = (userIdSet.isEmpty() ? new Map<Id,User>()
                                      : new Map<Id,User>([Select Id, Name, Email from User where IsActive=true and Id in :userIdSet]));

      String[] queueNames = new String[]{};
      queueNames.addAll(queueNameSet);
      // get all of the possible queues that would be used for reassignment (based on the queue names previously selected)
      Map<String,Group> queueMap = UserHelper.getQueueMapByName(queueNames);

      for (Opportunity opp : opps) {
         Stage_History__c stageHist = getStageHistory(opp,stageHistMap); 
          // if it's an existing history record, create a tracker to store the previous state
         if (stageHist.Id != null) {
            StageHistorySLATracker__c tracker = createTracker(stageHist, opp.ReferralLookup__r);
            trackersToInsert.add(tracker);
         }

         processNotes += '/nopp='+opp.Id+' Name='+opp.Name;
         String oppMsg = 'Processing '+CLASS_NAME;
         // first make sure the stage of the opportunity is appropriate 
         // if any of these are false, clear out the expiration
         processNotes += '  Accept_Deadline__c='+(opp.Accept_Deadline__c != null ? opp.Accept_Deadline__c.format('M/d/yyyy H:mm:ss') : 'null');
         processNotes += '  Accept_Reminder_Deadline__c='+(opp.Accept_Reminder_Deadline__c != null ? opp.Accept_Reminder_Deadline__c.format('M/d/yyyy H:mm:ss') : 'null');
         if (opp.ReferralLookup__r == null || opp.ReferralLookup__r.Referral_Partner__r == null
               || String.isBlank(opp.ReferralLookup__r.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c)) {
            oppMsg += ' Could not find a Referral Partner with a value in Stage Sales Rep needs Approval - clearing Deadline fields.';
            opp.Accept_Deadline__c = null;
            opp.Accept_Reminder_Deadline__c = null;
         } else if (opp.ReferralLookup__r.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c != opp.StageName) {
            oppMsg += ' Opp Stage='+opp.StageName+' Stage Sales Rep needs Approval='+opp.ReferralLookup__r.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c;
            oppMsg += '. Stages are not equal, clearing Deadline fields.';
            opp.Accept_Deadline__c = null;
            opp.Accept_Reminder_Deadline__c = null;
         } else {
            if (opp.Accept_Deadline__c != null && opp.Accept_Deadline__c < Datetime.now()) {
               processNotes += ' Hit the Accept Deadline';
               oppMsg += ' Hit the Accept Deadline of '+opp.Accept_Deadline__c.format('M/d/yyyy H:mm:ss')+' against '+Datetime.now().format('M/d/yyyy H:mm:ss');
               
               Referral__c ref = opp.ReferralLookup__r;
               if (REROUTE_OPPS) {
                  Group reassignQueue = reassignReferral(ref, queueMap, updateRefMap, stageHist);
                  //   global void reassignReferral(Referral__c ref, Map<String,Group> queueMap, Map<Id,Referral__c> updateRefMap, Stage_History__c stageHist) {
               
                  //Group reassignQueue = getDefaultQueue();
                  if (reassignQueue == null) {
                     oppMsg += ' Could not find a queue named '+DEFAULT_QUEUE_NAME+'!';
                  } else {
                     oppMsg += ' Changing the referral ownership to '+reassignQueue.Name;
                     opp.ReferralLookup__r.OwnerId = reassignQueue.Id;
                     opp.ReferralLookup__r.NotifyOwnerMsg__c = OPP_OWNER_NOTIFY;
                     //updateRefMap.put(opp.ReferralLookup__r.Id, opp.ReferralLookup__r);
                  }
               } // if (REROUTE_OPPS
               oppMsg += '; clearing Deadline field.';
               opp.Accept_Deadline__c = null;
               //opp.Accept_Reminder_Deadline__c = null;
               
               stageHist.SLAProcessed__c = true;
               stageHist.ExpirationProcessed__c = true; 
               stageHist.StageExpired__c = true;
               historyToUpsert.add(stageHist);
            } else if (opp.Accept_Reminder_Deadline__c != null && opp.Accept_Reminder_Deadline__c < Datetime.now()) { 
               processNotes += ' Hit the Accept Reminder Deadline';
               oppMsg += ' Hit the Accept Reminder Deadline of '+opp.Accept_Reminder_Deadline__c.format('M/d/yyyy H:mm:ss')+' against '+Datetime.now().format('M/d/yyyy H:mm:ss');
               oppMsg += '; Clearing the Reminder deadline.';
               createOppChatterMsg(opp,userMap,emailsToSend); 
                
               opp.Accept_Reminder_Deadline__c = null;
               stageHist.SLAProcessed__c = true;
               stageHist.SLAHitCount__c = (stageHist.SLAHitCount__c != null ? stageHist.SLAHitCount__c+1 : 1);
               historyToUpsert.add(stageHist);
            }
         }
         addToOppNotes(opp, oppMsg);
         addToHistNotes(stageHist, oppMsg); 
      } // for (Opportunity opp : opps
      
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      DmlHelper.performDML(opps, DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleOpportunities', 'Updating Opportunities', false);
      ReferralTriggerActions.SKIP_TRIGGER=false;
      DmlHelper.performDML(updateRefMap.values(), DmlHelper.DML_UPDATE, 'SLAHelperBatch', 'handleOpportunities', 'Updating Referrals', false);
      DmlHelper.performDML(historyToUpsert, DmlHelper.DML_UPSERT, 'SLAHelperBatch', 'handleOpportunities', 'Upsert Stage History', false);
      DmlHelper.performDML(trackersToInsert, DmlHelper.DML_INSERT, 'SLAHelperBatch', 'handleOpportunities', 'Inserting History Trackers', false);
      ErrorLog.checkSave();
      ChatterMentionPost.checkPostFeedElements();
      System.debug('handleOpportunities emailsToSend='+emailsToSend);
      processNotes += '; SEND_OPP_SLA_EMAIL='+SEND_OPP_SLA_EMAIL+' emailsToSend='+emailsToSend.size();
      if (!emailsToSend.isEmpty()) {
         try {
            Messaging.sendEmail (emailsToSend);
         } catch (Exception e) {
            processNotes += '; Exception sending emails! e='+e.getMessage()+'; '+e.getStackTraceString();
         }
      }
   } // handleOpportunities

   global Stage_History__c getStageHistory(Opportunity opp, Map<Id,Stage_History__c> stageHistMap) {
      Stage_History__c stageHist = null;
      // see if there's an existing stage history record. If so, use the latest (first in the list)
      stageHist = stageHistMap.get(opp.Id);
      if (stageHist == null) {
         // create a new one - this is to "catch up" with existing records that are out there. Eventually none should fall into here. 10/2/18
         stageHist = new Stage_History__c(Opportunity__c=opp.Id, New_Stage__c=opp.StageName, SLAHitCount__c=0);
         stageHist.SLA_Deadline__c = opp.Accept_Reminder_Deadline__c;
         stageHist.Expiration_Deadline__c = opp.Accept_Deadline__c;
         SlaHelperBatch.addToHistNotes(stageHist, 'Created new Stage History to log SLA change');
      }
      return stageHist;
   } // getStageHistory
    
   public class SLAEmail {
      public Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      
      // the main recipient of the email
      public Id sendToId = null;
      // the extra recipients
      public String[] ccEmails = new String[]{};
      
      public void addRecipient(User usr) {
         if (usr != null) {
            if (sendToId == null) {
               sendToId = usr.Id;
            } else {
               ccEmails.add(usr.Email);
            }
         }
      } // addRecipient
      
      public void buildEmail(Id recId, String recName, String[] postTexts) {
         if (sendToId == null && ccEmails.isEmpty()) {
            System.debug('buildEmail no recipients were found!');
            mail = null;
            return;
         }
         mail.setTargetObjectId(sendToId);
         if (!ccEmails.isEmpty()) {
            mail.setCcAddresses(ccEmails);
         }
         mail.setSubject(Label.SLAHelperBatch_OppSLASubject);
         mail.setHtmlBody(buildMsgBody(postTexts,false,recId,recName));
         mail.setPlainTextBody(buildMsgBody(postTexts,true,recId,recName));
         mail.setUseSignature(false);
         mail.setSaveAsActivity(false);
         
      }
      
      public String buildMsgBody(String[] postTexts, Boolean isText, Id recId, String recName) {
         String lineDivider = (isText ? '\n' : '<br>');
         String returnVal = '';
         
         if (Label.SLAHelperBatch_OppSLABody != 'N') {
            returnVal += Label.SLAHelperBatch_OppSLABody+lineDivider;
         }
         
         for (String postText : postTexts) {
             returnVal += (postText+lineDivider);
         }
         
         String sfURL = Utilities.getInstanceURL() + '/';
         String linkClassic = sfURL+recId;
         String linkLightning = sfURL+'lightning/r/'+recId+'/view';
         
         returnVal += lineDivider; 
         returnVal += lineDivider;
         returnVal += 'View the record: '+lineDivider;
          
         if (isText) {
            returnVal += 'For Salesforce Classic view '+recName+': '+linkClassic+' '+lineDivider;
            returnVal += 'For Lightning Experience view '+recName+': '+linkLightning+' '+lineDivider;
         } else {
            returnVal += 'For Salesforce Classic: <a href="'+linkClassic+'">'+recName+'</a>'+lineDivider;
            returnVal += 'For Lightning Experience: <a href="'+linkLightning+'">'+recName+'</a>'+lineDivider;
         }
         
         return returnVal;
         
      } // buildMsgBody

   } // class SLAEmail
   
   public static Boolean SEND_OPP_SLA_EMAIL=(Label.SLAHelperBatch_OppSLAEmail == 'Y');
    
   global void createOppChatterMsg(Opportunity opp, Map<Id,User> userMap, Messaging.SingleEmailMessage[] emailsToSend) {
      SLAEmail msg = new SLAEmail();

      Id[] userIdsToMention = new Id[]{opp.Owner.Id};
      if (opp.Owner.ManagerId != null) {
         userIdsToMention.add(opp.Owner.ManagerId);
         msg.addRecipient(opp.Owner.Manager);
      }
      if (opp.Owner.DSA_FSS__c != null) {
        // userIdsToMention.add(opp.Owner.DSA_FSS__c); commented out as DSA/FSS as per APR: APR0139213
         // because it fails when trying to access opp.Owner.DSA_FSS__r, we pull the user from the map
         msg.addRecipient(userMap.get(opp.Owner.DSA_FSS__c));
      }
      msg.addRecipient(opp.Owner);
      
      String[] postTexts = new String[]{};
      postTexts.add('You have received a high priority inbound Opportunity and the Status has not changed in the last 2 business days. Please take action as soon as possible.');
      postTexts.add('\nPlease note, the ‘Accept Opportunity’ button can only be used for NSS Inbound referrals. For SOAR referrals, you must update the Status directly.\nOpportunity - ' + opp.Name);
      
      ChatterMentionPost.createChatterMentionPost(opp.Id, userIdsToMention, postTexts, false, false);
      
      msg.buildEmail(opp.Id, opp.Name, postTexts);
      
      if (SEND_OPP_SLA_EMAIL && msg.mail != null) {
         emailsToSend.add(msg.mail);
      }
   } // createOppChatterMsg
    */
   global Map<Id,Referral__c[]> getReferralMap(Set<Id> recIdSet, Set<String> queueNameSet) {
      DateTime queryDate = DateTime.now().addDays(-QUERY_DAYS);
      
      // only select referrals that are inbound or have no referral partner (which should be inbound)
      
      Referral__c[] refs = [SELECT Id,Name, OwnerId, CreatedDate
                                  ,ProcessNotes__c
                                  ,SourceContact__c
                                  ,SourceLead__c
                                  ,Selling_Opportunity__r.StageName
                                  ,Selling_Opportunity__r.IsClosed
                                  ,Selling_Opportunity__r.CreatedDate
                                  ,Referral_Partner__r.Expired_SLA_queue__c
                                  ,PartnerReferral__r.Destination__c
                              FROM Referral__c 
                             WHERE (SourceContact__c IN :recIdSet
                                   or SourceLead__c in :recIdSet)
                               and (CreatedDate > :queryDate
                                   or Selling_Opportunity__r.CreatedDate > :queryDate)
                               and (Referral_Partner__c = null
                                   or Referral_Partner__r.NSS_Source__c = :ProspectOwnershipMethods.NSS_INBOUND)
                              order by createdDate desc];
      
      Map<Id,Referral__c[]> refMap = new Map<Id,Referral__c[]>();
      for (Referral__c ref : refs) {
         // don't use a referral attached to a closed opportunity
         if (ref.Selling_Opportunity__r == null || !ref.Selling_Opportunity__r.IsClosed) {
            Id recId = (ref.SourceContact__c != null ? ref.SourceContact__c : ref.SourceLead__c);
            Referral__c[] theseRefs = (refMap.containsKey(recId) ? refMap.get(recId) : new Referral__c[]{});
            theseRefs.add(ref);
            refMap.put(recId,theseRefs);
            if (ref.Referral_Partner__r != null && String.isNotBlank(ref.Referral_Partner__r.Expired_SLA_queue__c)) {
               queueNameSet.add(ref.Referral_Partner__r.Expired_SLA_queue__c);
            }
            if (ref.PartnerReferral__r != null && String.isNotBlank(ref.PartnerReferral__r.Destination__c)) {
               queueNameSet.add(ref.PartnerReferral__r.Destination__c);
            }
         }
      } // for (Referral__c ref : refs
      return refMap;
   } // getReferralMap
   
   public static String DEFAULT_QUEUE_NAME=Label.NSS_Routing_Default_Queue;
   
   //global static Group defaultQueue = null;
   
   //global static Group getDefaultQueue() {
   //   if (defaultQueue == null) {
   //      defaultQueue = new UserHelper().getQueue(DEFAULT_QUEUE_NAME);
   //   }
   //   return defaultQueue;
   //} // getDefaultQueue
  
   global void finish(Database.BatchableContext BC){
      String message = ' currentMode='+currentMode;
      message += '\nTotal recs found: '+ numberRecsFound+' ';
      if (currentMode == MODE_STAGE_HISTORY) {
         message += '\nctctsHandled='+ctctsHandled+' leadsHandled='+leadsHandled;
      }
      message += '\n\n'+processNotes;
      system.debug('message:'+message);
      jh.completeJob(bc, 'SLAHelperBatch process', message);

      // can't run a batch job more than once in a test
      if (!Test.isRunningTest() && !RUN_ONCE) {
         if (currentMode == MODE_STAGE_HISTORY) {
            //scheduleBatch(MODE_OPPORTUNITY, true);
         //} else if (currentMode == MODE_OPPORTUNITY) {  
            scheduleBatch(MODE_CADENCE, true);
         } else if (currentMode == MODE_CADENCE) {  
            scheduleBatch(MODE_TP_EXPIRE, true);
         } else if (currentMode == MODE_TP_EXPIRE) {  
            scheduleBatch(MODE_TP_SKIP, false);
         } else if (currentMode == MODE_TP_SKIP) {  
            scheduleBatch(MODE_STAGE_HISTORY, false);
         }
      } // if (!Test.isRunningTest
   } // finish
   
   /*
   MQL/Auto MQL 
   
   Custom Metadata Type - Stage SLA
   "SAL Minutes" (should be SLA) - period where you expect it to rehit the queue. Goes from the business hours on the Stage History
   
   MQL started
   If stage is changed to TAL
   New Stage History record for the new stage - close the previous stage.
   
   If multiple opps are created, and one is accepted, and one is rejected, the accepted one should move the stage forward
   
   If a lead is converted to opp, contact stage should go to TQO
   
   Rep with Opp
   Accept - SAO
   Reject - 
   
   Accept Opportunity Business Hours
    - change to minutes
    
    
   */
   
   public static String BATCH='BatchSchedule';
   
   public static SLAHelperBatch shb = null;
   
   public static void scheduleBatch(String nextMode, Boolean scheduleImmediate) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASS_NAME);
      System.debug('scheduleBatch nextMode='+nextMode+' abc='+abc+' scheduleImmediate='+scheduleImmediate);
      if (abc != null && abc.Active__c) {
         Integer batchSize = (abc != null && abc.BatchSize__c != null ? Integer.valueOf(abc.BatchSize__c) : 100);
         shb = new SLAHelperBatch(nextMode);
         if (scheduleImmediate) {
            database.executeBatch(shb, batchSize);
            
         } else {
            Integer nbrMinutes = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : -1);
            // nbrOfMinutes has to be greater than 0 to launch
            System.debug('scheduleBatchJob nbrMinutes='+nbrMinutes);
            if (nbrMinutes > 0) {
               String jobName = CLASS_NAME+DateTime.now().format('yyyyMMddHHmmssSSS');
               Integer scheduleMinutes = getScheduleMinutes(nbrMinutes, BATCH);
               try {
                  Id batchId = System.scheduleBatch(new SLAHelperBatch(nextMode), jobName, scheduleMinutes, batchSize);
                  System.debug('scheduleBatchJob batchId='+batchId+' jobName='+jobName);
               } catch (Exception e) {
                  System.debug('scheduleBatch exception: '+e.getMessage()+'; '+e.getStackTraceString());
               }
            }
         } // if (scheduleImmediate
      } // if (abc.Active__c
   } // scheduleBatch
   
   // adjust for business hours
   public static Integer getScheduleMinutes(Integer defaultMinutes, String timeZoneName) {
      // schedule based on BusinessHours
      BusinessHours busHours = DG_LMF_Service.getBusinessHours(timeZoneName);
      DateTime now = DateTime.now();
      Long checkMinutes = (defaultMinutes * 60000);
      DateTime newDeadline = BusinessHours.add(busHours.id , now, checkMinutes);
      System.debug('getScheduleMinutes defaultMinutes='+defaultMinutes+' now='+now.format('M/d/yyyy H:mm:ss')+' newDeadline='+newDeadline.format('M/d/yyyy H:mm:ss'));
      Long milliseconds = newDeadline.getTime() - now.getTime();
      Long seconds = milliseconds / 1000;
      Long minutes = seconds / 60;
      // figure out how many minutes to schedule the next run based on the business hours (so we're not running it during off hours)
      Integer scheduleMinutes = Integer.valueOf(minutes);
      if (scheduleMinutes < defaultMinutes) {
         // make sure we get at least this much time.
         System.debug('getScheduleMinutes defaultMinutes='+defaultMinutes+' scheduleMinutes='+scheduleMinutes+' resetting scheduleMinutes to defaultMinutes');
         scheduleMinutes = defaultMinutes;
      }
      System.debug('getScheduleMinutes defaultMinutes='+defaultMinutes+' scheduleMinutes='+scheduleMinutes+' milliseconds='+milliseconds+' seconds='+seconds+' minutes='+minutes);
      return scheduleMinutes;
   } // getScheduleMinutes
   
   public static final Integer OPP_PROCESS_NOTES_SIZE = Opportunity.ProcessNotes__c.getDescribe().getLength();
   public static final Integer HIST_PROCESS_NOTES_SIZE = Stage_History__c.ProcessNotes__c.getDescribe().getLength();
   
   public static void addToOppNotes(Opportunity opp, String notesToAdd) {
      System.debug('addToOppNotes opp='+opp.Name+' notesToAdd='+notesToAdd);         
      StringHelper.addNotesToField(opp, 'ProcessNotes__c', OPP_PROCESS_NOTES_SIZE, notesToAdd, true);
   } // addToOppNotes

   public static void addToHistNotes(Stage_History__c stageHist, String notesToAdd) {
      StringHelper.addNotesToField(stageHist, 'ProcessNotes__c', HIST_PROCESS_NOTES_SIZE, notesToAdd, true);
   } // addToOppNotes


} // SLAHelperBatch