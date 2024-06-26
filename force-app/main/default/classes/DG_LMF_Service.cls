/* 
  Handle SLAs and expirations
  Create Stage History Object whenever Lead Stage or Contact Stage is changed
   
  History
  -------
  06/19/2018 Gram Bischof        Created
  08/17/2018 Dan Carmen          Changes to handle different time zones.
  09/18/2018 Dan Carmen          Populate Contact Stages on the Account
  10/02/2018 Dan Carmen          Add in a Stage History record
  11/01/2018 Dan Carmen          Log reject/recycle reason on the stage history
  11/09/2018 Dan Carmen          If a converted lead, also check the lead id when checking for previous stage history.
  01/04/2019 Dan Carmen          Change to how Opportunities are handled
  04/18/2019 Dan Carmen          Add additional logging when processing Opportunities
  10/21/2019 Dan Carmen          Additional logging for setting the Contact Stage from an Opp.
  04/17/2020 Cindy Freeman        changes for updateConStageFromOpp to run now instead of in the Future
                                 only fire updateConStageFromOpp when Opty is changed, not on insert
                                 skip Account triggers when populate ContactStages on account
  05/05/2020 Cindy Freeman     call setStageFields inside updateConStageFromOppStage so contact trigger doesn't have to fire again
                 fixed bug where contact stage date fields on a contact were getting updating incorrectly when a lead was converted
  06/01/2020 Pujitha Madamanchi  Update getNotSoldContactStage to make sure it looks for the first 40 characters with Opp Reason.
  07/06/2020  Jacob Hinds         Added without sharing per PMD
  07/14/2020 Pujitha Madamanchi  Update contact stage when opp is closed not won based on payroll opp 
  08/07/2020 Dan Carmen          Fix for the expiration dates calculating properly.
  01/18/2021 Dan Carmen          Add in OwnedBy__c field
  06/14/2021 Pujitha Madamanchi  Add error logging for TQO stage history
  06/14/2021 Dan Carmen          Add in day start and end times for BusinessHour select
  10/12/2021 Dan Carmen          Include logic to add to a cadence based on hitting a stage - checkLatestCampaign
  10/18/2021 Pujitha Madamanchi  APR0122715: Populate Reject Recycle Reason on PR.
  03/15/2022 Pujitha Madamanchi  APR0128936: Do not create CARS for eComm records.
  02/17/2023 Pujitha Madamanchi  APR0148916: Car owner should be set to who TAL'ed it if its NSS/VSR.
  09/26/2023 Pujitha Madamanchi  Populate Ignore DNE/DNC on car on creation
  12/08/2023 Pujitha Madamanchi  Populate Override cars on car on creation from Cadence
  01/31/2024 Dan Carmen          Comment out logic for Opportunity accept/reject fields

*/

public without sharing class DG_LMF_Service implements TriggerInterface2 {
    
   public static final String CLASSNAME='DG_LMF_Service';
   // for testing purposes
   public static Boolean SKIP_TRIGGER=false;
   
   // do we want to use the workflow for this?
   public static Boolean USE_CODE_FOR_DATE_FIELDS=(Label.DG_CodeForDateFields == 'Y');
   
   // for recursion
   public static Set<String> ALREADY_RAN_SET = new Set<String>();

   // do we run the updateConStageFromOpp now or in the future
   public static Boolean RUN_UPDATE_CTCT_SKIP_FUTURE = (Label.DG_UpdateConStageSkipFuture == 'Y');
    
   // if a lead is converted from other code, set the Id here so we can find related Stage History records
   public static Id convertedLeadId = null;

   public static String[] NSS_TEAMS = Label.NSS_Team.split(',');


   // check all of the records as a group before cycling through them individually
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      SObjectType objType = recs[0].getSObjectType();
      String objTypeName = objType.getDescribe().getName();
      String key = objTypeName+(isBefore ? 'Before' : 'After');
      Boolean alreadyRan = ALREADY_RAN_SET.contains(key);
      System.debug('DG_LMF_Service.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isAfter='+isAfter+' objTypeName='+objTypeName+' key='+key+' alreadyRan='+alreadyRan);
       if (SKIP_TRIGGER || alreadyRan || recs==null || recs.isEmpty()) {
         return;
      }

      Boolean isLead = objType == Lead.sObjectType;
         
      if (isBefore) {
         if (objType == Contact.sObjectType) {
            ALREADY_RAN_SET.add(key);
            checkRecordStages(recs, oldMap, 'Contact_Stage__c', false, true);
         } else if (isLead) {
            ALREADY_RAN_SET.add(key);
            checkRecordStages(recs, oldMap, 'Lead_Stage__c', true, false);
         } else if (objType == Opportunity.sObjectType) {
            checkOppsBefore((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
         }
      } else if (isAfter) {
         if (objType == Opportunity.sObjectType) {
            // check if the probability changes
            DG_OpportunityAcceptDeadline.checkStageHistorySave();
            updateContactStages((List<Opportunity>)recs, (Map<Id,Opportunity>)oldMap);
         } else if (objType == Referral__c.sObjectType) {
            // check if the selling opportunity is populated
            checkReferrals((List<Referral__c>)recs, (Map<Id,Referral__c>)oldMap);
         } else if (objType == Contact.sObjectType) {
            // if this is the insert after a lead convert, we don't need to fire the code here.
            if (Trigger.isInsert && DG_DFR_Controller.enteredLeadConversion) {
               // do nothing in this case? 
            } else {
               ALREADY_RAN_SET.add(key);
               evaluateStageHistory(ObjectHelper.OBJECT_CONTACT, recs, oldMap);
            }
         } else if (isLead) {
            ALREADY_RAN_SET.add(key);
            evaluateStageHistory(ObjectHelper.OBJECT_LEAD, recs, oldMap);
         }
         // add all of the ids to the set to prevent recursion
         for (SObject rec : recs) {
            idsProcessedSet.add(rec.Id);
         }
      }
            
      
      
      // so multiple tests can run.
      //if (isAfter && Test.isRunningTest()) {
      //   idsProcessedSet.clear();
      //}
      // to make sure we don't get into recursion with this trigger - only process once in a transaction.
   } // triggerCheckAllFirst

   // check each record individually
   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   
   public static Set<Id> idsProcessedSet = new Set<Id>();
   
   public static void checkOppsBefore(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
      /* commented out 1/31/2024
      Map<Id,Opportunity> byRefIdMap = new Map<Id,Opportunity>();
      
      for (Opportunity opp : opps) {
         Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
         if (opp.ReferralLookup__c != null 
              && ((opp.AcceptDeadlineRecalc__c 
                      || (opp.Accept_Deadline__c == null && opp.Accept_Reminder_Deadline__c == null
                          && (oldOpp == null || (oldOpp != null && (opp.StageName != oldOpp.StageName 
                                                                        || opp.ReferralLookup__c != oldOpp.ReferralLookup__c)))))
               //   || ((opp.Accept_Deadline__c != null || opp.Accept_Reminder_Deadline__c != null) && (oldOpp != null && opp.StageName != oldOpp.StageName))
               )) {
            byRefIdMap.put(opp.ReferralLookup__c,opp);
         }
         if (opp.AcceptDeadlineRecalc__c) {
            opp.AcceptDeadlineRecalc__c = false;
         }
      }
      System.debug('checkOppsBefore byRefIdMap='+byRefIdMap.size());
      if (byRefIdMap.isEmpty()) {
         return;
      }
      // only stop the checks if we get here.
      ALREADY_RAN_SET.add(ObjectHelper.OBJECT_OPPTY+'Before');
      Map<Id,Referral__c> refMap = new Map<Id,Referral__c>([select Id, Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c
                                                              From Referral__c
                                                             Where Id in :byRefIdMap.keySet()
                                                               and Referral_Partner__r.IsActive__c=true
                                                               and Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c != null]);
      Opportunity[] oppsToCheckAcceptDate = new Opportunity[]{};
      Map<Id,Opportunity> oppsToEndStageHistory = new Map<Id,Opportunity>();
      
      for (Opportunity opp : byRefIdMap.values()) {
         Referral__c ref = refMap.get(opp.ReferralLookup__c);
         if (ref != null)
         {    System.debug('checkOppsBefore Stage_Sales_Rep_needs_Approval__c='+ref.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c+' opp.StageName='+opp.StageName);    }
         if (ref != null && ref.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c == opp.StageName) {
            oppsToCheckAcceptDate.add(opp);
        // } else if (opp.Accept_Deadline__c != null || opp.Accept_Reminder_Deadline__c != null) {
            // clear the deadlines, and end the stage history
         //   oppsToEndStageHistory.put(opp.Id,opp);
         }
      } // for (Opportunity opp
      System.debug('checkOppsBefore oppsToCheckAcceptDate='+oppsToCheckAcceptDate.size());
      if (!oppsToCheckAcceptDate.isEmpty()) {
         DG_OpportunityAcceptDeadline.checkDeadline(oppsToCheckAcceptDate, null);
      }
     // if (!oppsToEndStageHistory.isEmpty()) {
     //    endOppStageHistory(oppsToEndStageHistory);
     // }
     */
   } // checkOppsBefore
   /*
   public static void endOppStageHistory(Map<Id,Opportunity> oppMap) {
      Stage_History__c[] histories = [Select Id
                                            ,Exited_Date_Time__c
                                            ,New_Stage__c 
                                            ,NextStage__c
                                            ,NextStage__r.Id
                                            ,Old_Stage__c
                                            ,Opportunity__c
                                            ,ProcessNotes__c
                                            ,RejectRecycleReason__c
                                            ,Stage_Exited_To__c
                                        From Stage_History__c 
                                       Where Opportunity__c in :oppMap.keySet()];
      Map<Id,Stage_History__c> stageMap = new Map<Id,Stage_History__c>();
      for (Stage_History__c history : histories) {
         stageMap.put(history.Opportunity__c, history);
      }
      
      Stage_History__c[] updateHistories = new Stage_History__c[]{};
      for (Opportunity opp : oppMap.values()) {
         Stage_History__c history = stageMap.get(opp.Id);
         StringHelper.addToProcessNotes(opp,'Clearing Deadline fields due to Stage changing to '+opp.StageName);
         opp.Accept_Deadline__c = null;
         opp.Accept_Reminder_Deadline__c = null;
         if (history != null) {
            history.Exited_Date_Time__c = Datetime.now();
            StringHelper.addToProcessNotes(history,'Opp stage changed to '+opp.StageName+'-exiting stage');
            updateHistories.add(history);
         }
      }
      DmlHelper.performDML2(updateHistories, DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'endOppStageHistory', 'Update Stage History', true);
   } // endOppStageHistory
   */
   public static void evaluateStageHistory(String objectType, SObject[] recs, Map<Id,SObject> oldMap){
      //Create Stage History Object whenever Stage is changed 
      List<Id> newIdsList = new List<Id>();
      Set<Id> acctIdSet = new Set<Id>();
      Map<Id, String> oldStageMap = new Map<Id, String>();
     // Map<Id, String> lastCadenceStepMap = new Map<Id, String>();
     // Map<Id, Date> nextCadenceFollowUpMap = new Map<Id, Date>();
      String fieldName = (objectType == ObjectHelper.OBJECT_CONTACT ? 'Contact_Stage__c' : 'Lead_Stage__c');
      
      // when inserting leads we can skip the future method
      Boolean skipFuture = (objectType == ObjectHelper.OBJECT_LEAD && oldMap == null);
       
      // we need to check the campaign on these records to see if we need to add them to a cadence
      SObject[] recsForCampaign = new SObject[]{};
      Id[] campaignIds = new Id[]{};

      for(SObject rec : recs) {
        
         String stageName = (String)rec.get(fieldName);
         String prevStageName = (oldMap != null && oldMap.containsKey(rec.Id) ? (String)oldMap.get(rec.Id).get(fieldName) : null);
         Boolean processed = idsProcessedSet.Contains(rec.Id);
         System.debug('evaluateStageHistory stageName='+stageName+' prevStageName='+prevStageName+' processed='+processed); 

         if(String.isNotBlank(stageName)) {
            // if it's a new record or the stage changes
            if (stageName != prevStageName) { 
               // stage changed
               newIdsList.add(rec.Id);
               // if there's a campaign, collect that to evaluate later
               Id campId = (Id)rec.get('LatestCampaign__c');
               if (campId != null) {
                  recsForCampaign.add(rec);
                  campaignIds.add(campId);
               }
               SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
               System.debug('evaluateStageHistory has oldRec='+(oldRec != null));
               if (oldRec != null) {
                  if (oldRec.get(fieldName) != null) {
                     oldStageMap.put(rec.Id, (String)oldRec.get(fieldName));
                  }
                 /* System.debug('evaluateStageHistory Last_Cadence_Step_Completed__c='+oldRec.get('Last_Cadence_Step_Completed__c'));
                  if (oldRec.get('Last_Cadence_Step_Completed__c') != null) {
                     lastCadenceStepMap.put(rec.id, (String)oldRec.get('Last_Cadence_Step_Completed__c'));
                  }
                  System.debug('evaluateStageHistory Next_Cadence_Follow_up_Date__c='+oldRec.get('Next_Cadence_Follow_up_Date__c'));
                  if (oldRec.get('Next_Cadence_Follow_up_Date__c') != null) {
                     nextCadenceFollowUpMap.put(rec.Id, (Date)oldRec.get('Next_Cadence_Follow_up_Date__c'));
                  } */
               } // if (oldRec != null
                   
            }
            idsProcessedSet.add(rec.Id);
            if (objectType == ObjectHelper.OBJECT_CONTACT && rec.get('AccountId') != null) {
               acctIdSet.add((Id)rec.get('AccountId'));
            }
         } // if(!idsProcessedSet.Contains(rec.Id)  
      } // for(Contact newContact

     // System.debug('evaluateStageHistory newIdsList='+newIdsList.size()+' acctIdSet='+acctIdSet.size()+' +' nextCadenceFollowUpMap='+nextCadenceFollowUpMap.size()+' skipFuture='+skipFuture+' recsForCampaign='+recsForCampaign.size());
      if (!recsForCampaign.isEmpty()) {
         checkLatestCampaign(recsForCampaign, campaignIds);
      } // if (!recsForCampaign.isEmpty

    //  checkProcessHistory(newIdsList,acctIdSet, oldStageMap, lastCadenceStepMap, nextCadenceFollowUpMap, skipFuture);
    checkProcessHistory(newIdsList,acctIdSet, oldStageMap, skipFuture);

   } // evaluateStageHistory
   
  // consider moving this to a queueable if too much processing for inline
   public static void checkLatestCampaign(SObject[] recsForCampaign, Id[] campaignIds) {
       Set<Id> idsNotToBeProcessedSet = new Set<Id>();
      // select campaigns available to use
      Map<Id,Campaign> campMap = new Map<Id,Campaign>([Select Id, Name, Cadence__c, Cadence__r.Ignore_DNC_DNE__c, Cadence__r.OverrideOtherCARs__c, CadenceMarketingStage__c
                                                        From Campaign
                                                       Where IsActive=true
                                                         And Cadence__c != null
                                                         And Id in :campaignIds]);
      System.debug('checkLatestCampaign recsForCampaign='+recsForCampaign.size()+' campaignIds='+campaignIds.size()+' campMap='+campMap.size());
      Cadence_Assignment_Record__c[] insertCars = new Cadence_Assignment_Record__c[]{};
      User runningUser = UserHelper.getRunningUser();
      for (SObject rec : recsForCampaign) {
           //Check if ownedByPrec is not ecommerce so, as ecomm should not have CARS records. 
            String owedByPrev = (String)rec.get('OwnedByPrev__c');
            //APR0128936: Do not create cars fro eComm. 
            if(owedByPrev != 'Ecommerce'){ 
            Id campId = (Id)rec.get('LatestCampaign__c');
            String stageNameFld = (rec.Id.getSObjectType() == Contact.sObjectType ? 'Contact_Stage__c' : 'Lead_Stage__c');
            String curStage = (String)rec.get(stageNameFld);
            Campaign camp = (campId != null ? campMap.get(campId) : null);
            if (camp != null && String.isNotBlank(curStage) && camp.CadenceMarketingStage__c == curStage) {
               // if we get to this point we're going to add this record to a car. We will let existing cadence rules handle if it's valid or not
               Id ownerId = NSS_TEAMS.contains(runningUser.NSS_Team__c) ? runningUser.Id : (Id)rec.get('OwnerId');
               Cadence_Assignment_Record__c car = new Cadence_Assignment_Record__c(CadenceObject__c=rec.Id, Cadence__c=camp.Cadence__c, OwnerId=ownerId, Cadence_Owner__c=ownerId
                                                                                   , Ignore_DNE__c=camp.Cadence__r.Ignore_DNC_DNE__c, OverrideOtherCARs__c=camp.Cadence__r.OverrideOtherCARs__c
                                           , Source__c=CLASSNAME);
               StringHelper.addToProcessNotes(car,'Created from Campaign '+camp.Name+' due to Stage of '+curStage);
               insertCars.add(car);
            } // if (camp != null
         } // if(rec.ownedByPrev != 'Ecommerce' 
      } // for (SObject rec : recsForCampaign
      if (!insertCars.isEmpty()) {
         DmlHelper.performDML2(insertCars, DmlHelper.DML_INSERT, 'DG_LMF_Service', 'checkLatestCampaign', 'Insert new CARS', true);
      }
   } // checkLatestCampaign

   public static Map<String,MarketingStage__mdt> stageMap = null;
   public static String stageDateFields = '';    // used later in a query
   public static Set<String> stageDateFldSet = new Set<String>();

   public static Map<String,MarketingStage__mdt> getStageMap() {
      if (stageMap == null) {
         stageMap = new Map<String,MarketingStage__mdt>();
         MarketingStage__mdt[] stages = [Select MasterLabel
                                               ,ClearCadence__c
                                               ,ClearFromRejectRecycle__c
                                               ,Contact__c
                                               ,DateFieldAPIName__c
                                               ,Lead__c
                                               ,OppProbabilityMax__c
                                               ,OppProbabilityMin__c
                                               ,OtherFieldAPIName__c
                                               ,SetOwnership__c
                                               ,SortOrder__c
                                               ,Source__c
                                               ,StagesToClear__c
                                               ,TestScenario__c
                                           From MarketingStage__mdt];
         for (MarketingStage__mdt stage : stages) {
            stageMap.put(stage.MasterLabel, stage);
            if (String.isNotBlank(stage.DateFieldAPIName__c) && stage.Contact__c == true) { 
                stageDateFldSet.add('SourceContact__r.'+stage.DateFieldAPIName__c);
                stageDateFields += 'SourceContact__r.'+stage.DateFieldAPIName__c +', ';  
            }
         }
      } // if (stageMap == null)
      return stageMap;
   } // getStageMap
   
   public static void checkRecordStages(SObject[] recs, Map<Id,SObject> oldMap, String stageFieldName, Boolean isLead, Boolean isCtct) {
      List<Id> recIdsList = new List<Id>();
      Map<Id, String> idToRejectMap = new Map<Id, String>();
      Map<Id, String> idToRecycleMap = new Map<Id, String>();
      if (!USE_CODE_FOR_DATE_FIELDS) {
         return;
      }
      for (SObject rec : recs) {
         // check for recursion
         Boolean okayToContinue = (rec.Id == null || !idsProcessedSet.contains(rec.Id));
         System.debug('checkRecordStages okayToContinue='+okayToContinue);
         if (okayToContinue) {
            SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
            String curStage = (String)rec.get(stageFieldName);
            String prevStage = (oldRec != null ? (String)oldRec.get(stageFieldName) : (String)null);
            System.debug('checkRecordStages curStage='+curStage + ' prevStage='+prevStage);

            if (String.isNotBlank(curStage) && (oldRec == null || (curStage != prevStage))) {
               setStageFields(rec, curStage, prevStage, isLead, isCtct, (oldRec == null));
               if(curStage == 'Recycle'){ 
                  recIdsList.add(rec.Id);
                  idToRecycleMap.put(rec.Id, (String)rec.get('Recycle_Reason__c'));
               }
               if(curStage == 'Reject'){
                  recIdsList.add(rec.Id);
                  idToRejectMap.put(rec.Id, (String)rec.get('Reject_Reason__c'));
               }
            } // if (String.isNotBlank(stageName)
         }
      } // for (SObject rec
      if(!recIdsList.isEmpty()){
         if (Utilities.allowFuture()) {
            updatePartRefReasonFuture(recIdsList, idToRejectMap, idToRecycleMap);
         } else {
            updatePartRefReasonNow(recIdsList, idToRejectMap, idToRecycleMap);
         }
      }
      
   } // checkRecordStages
   
  
   //APR0122715
 
   @future
   public static void updatePartRefReasonFuture(List<Id> recIdsList, Map<Id, String> idToRejectMap, Map<Id, String> idToRecycleMap){
      updatePartRefReasonNow(recIdsList, idToRejectMap, idToRecycleMap);
   } // updatePartRefReasonFuture
   public static void updatePartRefReasonNow(List<Id> recIdsList, Map<Id, String> idToRejectMap, Map<Id, String> idToRecycleMap){
      Map<Id,PartnerReferral__c> updatePartRefMap = new Map<Id,PartnerReferral__c>();
      updatePartRefReason(recIdsList, idToRejectMap, idToRecycleMap, updatePartRefMap);
      if(!updatePartRefMap.isEmpty()){
         PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
         DmlHelper.performDML2(updatePartRefMap.values(), DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'updatePartRefReason', 'Update Partner Referral', false);
      }
      
   } // updatePartRefReasonNow
    
   //The update happens in future method, so if you are using this directly, do not forget to update the records. 
   public static void updatePartRefReason(List<Id> recIdsList, Map<Id, String> idToRejectMap, Map<Id, String> idToRecycleMap, Map<Id,PartnerReferral__c> updatePartRefMap){
      List<PartnerReferral__c> partRefs = [SELECT ID,
                                                Contact__c,
                                                Lead__c,
                                                Master_Partner_Referral__c,
                                                Reject_Recycle_Date__c,
                                                Reject_Reason__c,
                                                Recycle_Reason__c,
                                                CreatedDate
                                    FROM PartnerReferral__c 
                                    WHERE (Contact__c IN: recIdsList
                                             OR Lead__c IN: recIdsList)
                                       AND Master_Partner_Referral__c = NULL
                                       ORDER BY CreatedDate DESC];
      if(!partRefs.isEmpty()){
         Set<Id> idsNotProcessedSet = new Set<Id>();
         // so we only process each id once
         idsNotProcessedSet.addAll(recIdsList);
         for (PartnerReferral__c pr : partRefs) {
            Id recId = (pr.Contact__c != null ? pr.Contact__c : pr.Lead__c);
            if (idsNotProcessedSet.contains(recId)) {
               // so we don't process again
               idsNotProcessedSet.remove(recId);
               // we only want to work with the latest record. If the latest record already has a date, we don't need to proceed.
               if (pr.Reject_Recycle_Date__c == null) {
                  PartnerReferral__c updatePr = (updatePartRefMap.containsKey(pr.Id) ? updatePartRefMap.get(pr.Id) : pr);
                  // if we get to this point, we're going to be updating the date.
                  updatePr.Reject_Recycle_Date__c = System.now();
                  updatePr.Reject_Reason__c = (idToRejectMap.containsKey(recId) ? idToRejectMap.get(recId) : null);
                  updatePr.Recycle_Reason__c = (idToRecycleMap.containsKey(recId) ? idToRecycleMap.get(recId) : null);
                  updatePartRefMap.put(updatePr.Id, updatePr);
              }
            } // if (idsNotProcessedSet.contains(recId
         } // for (PartnerReferral__c pr : partRefs

      } // if(!partRefs.isEmpty
   }//updatePartRefReason

   
   public static void setStageFields(SObject rec, String curStage, String prevStage, Boolean isLead, Boolean isCtct, Boolean isInsert) {
      // make sure the stages are retrieved.
      getStageMap();
      // get the current stage
      MarketingStage__mdt curStageMDT = stageMap.get(curStage);
      // make sure the stage is valid for this object
      if (curStageMDT != null && ((curStageMDT.Contact__c && isCtct) || (curStageMDT.Lead__c && isLead))) {
         String notes = '';
         // set the date field
         /*
         if (String.isNotBlank(curStageMDT.DateFieldAPIName__c)) {
            rec.put(curStageMDT.DateFieldAPIName__c, DateTime.now());
            notes += 'Set '+curStageMDT.DateFieldAPIName__c;
         }
         */
         if (String.isNotBlank(curStageMDT.DateFieldAPIName__c)) {
           if (isCtct && isInsert && rec.get(curStageMDT.DateFieldAPIName__c) != null)
           {    // date came in from lead convert so leave it alone
           }
           else {
               rec.put(curStageMDT.DateFieldAPIName__c, DateTime.now());
               notes += 'Set '+curStageMDT.DateFieldAPIName__c;
           } // else
         }
          
         if (curStageMDT.ClearCadence__c) {
            // notes += '; Clearing Cadence Steps';
            // rec.put('Last_Cadence_Step_Completed__c',null);
            // rec.put('Next_Cadence_Follow_up_Date__c',null);
         }
         
         if (curStage == 'Recycle' && isCtct) {
            rec.put('NSSOwnership__c',Label.Marketo_User);
            notes += '; set '+Label.Marketo_User+' into NSSOwnership__c';
         } else if (curStage == 'Recycle' && isLead) {
            Id marketoId = DoNotSyncCheck.getMarketoSyncId();
            notes += '; set Marketo as the owner id='+marketoId;
            if (marketoId != null) {
               rec.put('OwnerId', marketoId);
            }
         } else if (curStage == 'Reject' && isLead && String.isNotBlank(curStageMDT.SetOwnership__c)) {
            // get the disqualified queue
            Group queue = new UserHelper().getQueue(curStageMDT.SetOwnership__c);
            notes += '; setting '+curStageMDT.SetOwnership__c+' as the owner id='+(queue != null ? (String)queue.Id : 'Not Found');
            if (queue != null) {
               rec.put('OwnerId', queue.Id);
            }
         }
         // we only need to clear stages if there is a previous stage - this will take care on inserts and lead converts
         if (String.isNotBlank(prevStage)) {
            Set<String> stagesToClear = new Set<String>();
            if (String.isNotBlank(curStageMDT.StagesToClear__c)) {
               stagesToClear.addAll(curStageMDT.StagesToClear__c.split(','));
            }

            // if moving from reject or recycle, see if there are any additional fields we want to clear
            if ((prevStage == 'Reject' || prevStage == 'Recycle') 
                 && String.isNotBlank(curStageMDT.ClearFromRejectRecycle__c)) {
               stagesToClear.addAll(curStageMDT.ClearFromRejectRecycle__c.split(','));
            }

            for (String stage : stagesToClear) {
               MarketingStage__mdt checkStage = stageMap.get(stage);
               if (checkStage != null && String.IsNotBlank(checkStage.DateFieldAPIName__c) 
                      && ((checkStage.Contact__c && isCtct) || (checkStage.Lead__c && isLead))) {
                  if (rec.get(checkStage.DateFieldAPIName__c) != null) {
                     notes += '; clearing '+checkStage.DateFieldAPIName__c;
                     rec.put(checkStage.DateFieldAPIName__c,null);
                  }
                  if (String.isNotBlank(checkStage.OtherFieldAPIName__c) && rec.get(checkStage.OtherFieldAPIName__c) != null) {
                     notes += '; clearing '+checkStage.OtherFieldAPIName__c;
                     rec.put(checkStage.OtherFieldAPIName__c,null);
                  }
               }
            } // for (String stage

         } // if (String.isNotBlank(prevStage
         
         
         if (isCtct) {
            StringHelper.addToProcessNotes((Contact)rec,notes);
         } else if (isLead) {
            StringHelper.addToProcessNotes((Lead)rec,notes);
         }
      } // if (curStage != null
   } // setStageFields

   // for testing purposes
   public static Boolean SKIP_FUTURE=(Label.DG_SkipFuture == 'Y' || Test.IsRunningTest());
   
  // public static void checkProcessHistory(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap
  //                                              , Map<Id, String> lastCadenceStepMap, Map<Id, Date> nextCadenceFollowUpMap
  //                                              , Boolean skipFuture) {

   public static void checkProcessHistory(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap
                                                , Boolean skipFuture) {
      if (!newIdsList.isEmpty()) {
         if (!skipFuture && !SKIP_FUTURE && Utilities.allowFuture()) {
            // checkStageHistoryFuture(newIdsList,acctIdSet, oldStageMap, lastCadenceStepMap, nextCadenceFollowUpMap);
            checkStageHistoryFuture(newIdsList,acctIdSet, oldStageMap);
         } else {
          //  checkStageHistory(newIdsList,acctIdSet, oldStageMap, lastCadenceStepMap, nextCadenceFollowUpMap);
              checkStageHistory(newIdsList,acctIdSet, oldStageMap);
         }
      } // if (!newIdsList
   } // checkProcessHistory
    
   @future
 //  public static void checkStageHistoryFuture(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap
  //                                              , Map<Id, String> lastCadenceStepMap, Map<Id, Date> nextCadenceFollowUpMap){
   public static void checkStageHistoryFuture(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap){
      //checkStageHistory(newIdsList,acctIdSet, oldStageMap, lastCadenceStepMap, nextCadenceFollowUpMap);
      checkStageHistory(newIdsList,acctIdSet, oldStageMap);
   } // checkLeadStageHistoryFuture


  // public static void checkStageHistory(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap
   //                                              , Map<Id, String> lastCadenceStepMap, Map<Id, Date> nextCadenceFollowUpMap){

   public static void checkStageHistory(List<Id> newIdsList, Set<Id> acctIdSet, Map<Id, String> oldStageMap){     
      ErrorLog__c addErrLog = ErrorLog.logError('DG_LMF_Service', 'checkStageHistory', 'LOG_DATA', (!newIdsList.isEmpty() ? newIdsList[0] : null), 'Nbr conIdSet='+newIdsList.size());

      System.debug('checkStageHistory newIdsList='+newIdsList.size()+' oldStageMap='+oldStageMap.size());
      // see if this is a list of contact ids. 
      Boolean isContact = (newIdsList != null && !newIdsList.isEmpty() && ((String)newIdsList[0]).startsWith('003'));

      Set<Id> filteredIdSet = new Set<Id>();
      filteredIdSet.addAll(newIdsList);
      
      // for converted leads, keep track of mapping between lead and contact. Contact Id is the key, Lead Id is the value
      Map<Id,Id> contactLeadIdMap = new Map<Id,Id>();
      
      System.debug('checkStageHistory isContact='+isContact+' oldStageMap='+oldStageMap.size());
      // only do this on the insert of a contact - check if it was just converted
      if (isContact && oldStageMap.isEmpty()) {
         checkConvertedLeads(filteredIdSet, contactLeadIdMap, oldStageMap.isEmpty());
      } // if (oldContactIdStageMap.isEmpty
      
      // if no ids left here do nothing more
      if (filteredIdSet.isEmpty() || (oldStageMap.isEmpty() && convertedLeadId != null)) {
         System.debug('checkStageHistory exiting because of filteredIdSet or convertedLeadId='+convertedLeadId);
         return;
      } // if (filteredIdSet
        
      List<Stage_History__c> historyToInsert = new List<Stage_History__c>();

      Map<Id,Stage_History__c> stageHistMap = new Map<Id,Stage_History__c>();
      
      Set<Id> queryIdSet = new Set<Id>();
      queryIdSet.addAll(filteredIdSet);
      queryIdSet.addAll(contactLeadIdMap.values());
      
      // if we are inserting a lead, we don't need to check for previous history
      Boolean doNotCheckHistory = (!isContact && oldStageMap.isEmpty());
      
      if (!doNotCheckHistory) {
         ErrorLog.addToDescription(addErrLog,'Adding to wrapper in checkStageHistory');
         // find the latest stage histories so we can link to the new one
         for (Stage_History__c stageHist : [Select Id
                                               ,Contact__c
                                               ,Exited_Date_Time__c
                                               ,Lead__c
                                               ,New_Stage__c 
                                               ,NextStage__c
                                               ,NextStage__r.Id
                                               ,Old_Stage__c
                                               ,ProcessNotes__c
                                               ,RejectRecycleReason__c
                                               ,Stage_Exited_To__c
                                          From Stage_History__c 
                                         Where (Lead__c IN :filteredIdSet 
                                                or Contact__c in :filteredIdSet
                                                or Lead__c in :contactLeadIdMap.values())  // for converted leads
                                            and NextStage__c=null
                                        Order by CreatedDate Desc]) {
            // store only the latest for each lead or contact
            Id keyId = (stageHist.Contact__c != null ? stageHist.Contact__c : stageHist.Lead__c);
            if (keyId != null && !stageHistMap.containsKey(keyId)) {
               stageHistMap.put(keyId, stageHist);
            }
         } // for (Stage_History__c stageHist
         ErrorLog.addToDescription(addErrLog,'stageHistMap='+stageHistMap.size());
      } // if (!doNotCheckHistory
      
      if (isContact) {
         ErrorLog.addToDescription(addErrLog,'checkContacts');
         checkContacts(filteredIdSet, acctIdSet, stageHistMap, historyToInsert, contactLeadIdMap);
      } else {
         checkLeads(filteredIdSet, acctIdSet, stageHistMap, historyToInsert);
      }
      ErrorLog.addToDescription(addErrLog,'historyToInsert='+historyToInsert.size());  
      System.debug('checkStageHistory historyToInsert='+historyToInsert.size());
      // set the SLA on the history records
      createSLATimeLines(historyToInsert, false);
        
      DmlHelper.performDML2(historyToInsert, DmlHelper.DML_INSERT, 'DG_LMF_Service', 'processCtctStageHistory', 'Insert New Stage History', false);

      if (!doNotCheckHistory) {
       //  checkPrevHistory(stageHistMap.values(), lastCadenceStepMap, nextCadenceFollowUpMap);
       checkPrevHistory(stageHistMap.values());
      }
      ErrorLog.checkSave();
   } // checkStageHistory
   
   // check the previous history records to link to the new ones
 //  public static void checkPrevHistory(Stage_History__c[] histories, Map<Id, String> lastCadenceStepMap, Map<Id, Date> nextCadenceFollowUpMap) {
   public static void checkPrevHistory(Stage_History__c[] histories) {
      Stage_History__c[] historyToUpdate = new Stage_History__c[]{};
 //     System.debug('checkPrevHistory lastCadenceStepMap='+lastCadenceStepMap.keySet()+' nextCadenceFollowUpMap='+nextCadenceFollowUpMap.keySet());
      
      for (Stage_History__c stageHist : histories) {
         if (stageHist.NextStage__r != null && stageHist.NextStage__r.Id != null) {
            Id keyId = (stageHist.Contact__c != null ? stageHist.Contact__c : stageHist.Lead__c);
            Stage_History__c nextStage = stageHist.NextStage__r;
            System.debug('checkPrevHistory keyId='+keyId+' has nextStage='+(nextStage != null));
            stageHist.NextStage__r = null;
            stageHist.NextStage__c = nextStage.Id;

            stageHist.Stage_Exited_To__c = nextStage.New_Stage__c;
            stageHist.Exited_Date_Time__c = Datetime.now();
            
           // stageHist.Last_Cadence_Step_Completed__c = lastCadenceStepMap.get(keyId);
          //  stageHist.Next_Cadence_Follow_up_Date__c = nextCadenceFollowUpMap.get(keyId);

          //  System.debug('checkPrevHistory lastCadenceStepMap='+lastCadenceStepMap.get(keyId)+'; values='+lastCadenceStepMap.values());
         //   System.debug('checkPrevHistory nextCadenceFollowUpMap='+nextCadenceFollowUpMap.get(keyId)+'; values='+nextCadenceFollowUpMap.values());

            System.debug('checkPrevHistory stageHist='+stageHist);
            SLAHelperBatch.addToHistNotes(stageHist, 'Set Next Stage to '+nextStage.New_Stage__c+' with Id='+nextStage.Id);

            historyToUpdate.add(stageHist);
         }
      } // for (Stage_History__c stageHist

      DmlHelper.performDML2(historyToUpdate, DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'checkPrevHistory', 'Update Stage History', false);
   } // checkPrevHistory
   
   public static void checkLeads(Set<Id> filteredIdSet, Set<Id> acctIdSet, Map<Id,Stage_History__c> stageHistMap, List<Stage_History__c> historyToInsert) {
      for (Lead ld: [Select Id, Lead_Stage__c,IsConverted,ConvertedContactId, TimeZoneAbbrev__c
                                ,Recycle_Reason__c, Reject_Reason__c, OwnedByPrev__c
                            from Lead 
                           where Id IN : filteredIdSet]){
         Stage_History__c prevStageHist = stageHistMap.get(ld.Id);
         // if the stage is different
         if (prevStageHist == null || prevStageHist.New_Stage__c != ld.Lead_Stage__c) {
            String rejectReason = (String.isNotBlank(ld.Reject_Reason__c) ? ld.Reject_Reason__c : ld.Recycle_Reason__c);
            Stage_History__c newStage = createStageHistory(prevStageHist,ld.Lead_Stage__c,null,ld.Id, rejectReason);
            newStage.OwnedBy__c = ld.OwnedByPrev__c;
            historyToInsert.add(newStage);
         }
      } // for (Lead theLead
   } // checkLeads
   
   public static void checkContacts(Set<Id> filteredIdSet, Set<Id> acctIdSet, Map<Id,Stage_History__c> stageHistMap
                                   ,List<Stage_History__c> historyToInsert, Map<Id,Id> contactLeadIdMap) {
      // populate the ContactStages on the account - compile the unique stage names from all contacts
      Account[] accts = [Select Id, Name, ContactStages__c, TimeZoneAbbrev__c
                               ,(Select Id, Contact_Stage__c 
                                       ,Recycle_Reason__c, Reject_Reason__c, OwnedByPrev__c
                                   from Contacts
                                  Where Contact_Stage__c != null)
                           From Account
                          Where Id in :acctIdSet];
      Account[] acctsToUpdate = new Account[]{};
      for (Account acct : accts) {
         Set<String> stageSet = new Set<String>();
         for (Contact ctct : acct.Contacts) {
            stageSet.add(ctct.Contact_Stage__c);
            // if this is one of the contacts passed in through the trigger
            if (filteredIdSet.contains(ctct.Id)) {
               Stage_History__c prevHistory = stageHistMap.get(ctct.Id);
               if (prevHistory == null && contactLeadIdMap.containsKey(ctct.Id)) {
                  prevHistory = stageHistMap.get(contactLeadIdMap.get(ctct.Id));
               }
               if (prevHistory == null || (prevHistory != null && prevHistory.New_Stage__c != ctct.Contact_Stage__c)) {
               
                  String rejectReason = (String.isNotBlank(ctct.Reject_Reason__c) ? ctct.Reject_Reason__c : ctct.Recycle_Reason__c);
                  Stage_History__c newHistory = createStageHistory(prevHistory,ctct.Contact_Stage__c,ctct.Id,null,rejectReason);
                  newHistory.OwnedBy__c = ctct.OwnedByPrev__c;
                  historyToInsert.add(newHistory);
               }
            } // if (filteredCtctIdSet.contains(ctct.Id
         } // for (Contact ctct
         // create a list to alphabetize them
         String[] stageList = new String[]{};
         stageList.addAll(stageSet);
         stageList.sort();
         String stageStr = '';
         for (String tempStage : stageList) {
            stageStr += tempStage+';';
         }
         if (acct.ContactStages__c != stageStr) {
            acctsToUpdate.add(new Account(Id=acct.Id, ContactStages__c=stageStr));
         }
         
      } // for (Account acct

      ZipCheckOwner.SKIP_TRIGGERS = true;
      DmlHelper.performDML2(acctsToUpdate, DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'checkContacts', 'Update Contact Stages on Account', false);
      ZipCheckOwner.SKIP_TRIGGERS = false;
                                       
   } // checkContacts
    
   public static void checkConvertedLeads(Set<Id> filteredIdSet, Map<Id,Id> contactLeadIdMap, Boolean isInsert) {
      // only do this on the insert of a contact - check if it was just converted
      Lead[] leads = [select Id, Name
                               ,ConvertedAccountId
                               ,ConvertedContactId
                               ,ConvertedDate
                               ,IsConverted
                           From Lead
                          Where IsConverted=true
                            and ConvertedContactId in :filteredIdSet
                            and ConvertedDate >= :Date.today().addDays(-1)
                            ];
      System.debug('checkConvertedLeads leads='+leads.size()+' filteredIdSet='+filteredIdSet);
      for (Lead ld : leads) {
         System.debug('checkConvertedLeads ld='+ld);
         // remove any we find from the set if insert
         //if (isInsert) {
         //   filteredIdSet.remove(ld.ConvertedContactId);
         //} else {
            // keep track of the lead id so we can query on that too
            contactLeadIdMap.put(ld.ConvertedContactId, ld.Id);
         //}
      }
      System.debug('checkConvertedLeads after check filteredIdSet='+filteredIdSet.size());

   } // checkConvertedLeads
   
   public static Stage_History__c createStageHistory(Stage_History__c prevHistory, String NewStage, Id ContactId, Id LeadId
                                                    ,String rejectRecycleReason) {
      Stage_History__c newSH = new Stage_History__c(New_Stage__c=NewStage, Contact__c = ContactId, Lead__c = LeadId
                                                   ,RejectRecycleReason__c=rejectRecycleReason);

      if (prevHistory != null) {
         newSH.Old_Stage__c = prevHistory.New_Stage__c;
         newSH.Previous_Stage__c = prevHistory.Id;
         prevHistory.NextStage__r = newSH;
      }
      return newSH;
   } // createStageHistory
    
    public static String DEFAULT_HOURS_NAME='NSS';

    public static Map<String,BusinessHours> busHoursMap = null;
    
    public static BusinessHours getBusinessHours(String timeZoneAbbrev) {
       return getBusinessHours(timeZoneAbbrev, null);
    }
    
    public static String CACHE_NAME='DGLMFSERVICEbusHoursMap';
    
    public static BusinessHours getBusinessHours(String timeZoneAbbrev, String timeZoneSID) {
       if (busHoursMap == null) {
          busHoursMap = (Map<String,BusinessHours>)CacheManager.getOrg(CACHE_NAME);
       } // if (busHoursMap == null
        
       if (busHoursMap == null) {
          busHoursMap = new Map<String,BusinessHours>();
          String nameStr = DEFAULT_HOURS_NAME+'%';
          // only select records that are active
          BusinessHours[] hours = [Select Id, Name, TimeZoneSidKey 
                                         ,MondayStartTime, MondayEndTime
                                         ,TuesdayStartTime, TuesdayEndTime
                                         ,WednesdayStartTime, WednesdayEndTime
                                         ,ThursdayStartTime, ThursdayEndTime
                                         ,FridayStartTime, FridayEndTime
                                     from BusinessHours 
                                    where IsActive=true and Name like :nameStr];
          for (BusinessHours busHour : hours) {
             busHoursMap.put(busHour.Name, busHour);
             // do not store specific ones by time zone
             if (!busHour.Name.endsWith('BatchSchedule')) {
                busHoursMap.put(busHour.TimeZoneSidKey, busHour);
             }
          } // for (BusinessHours busHour
          CacheManager.putOrg(CACHE_NAME, busHoursMap);
       } // if (busHoursMap == null
       
       BusinessHours retHours = (String.isNotBlank(timeZoneAbbrev) ? busHoursMap.get(DEFAULT_HOURS_NAME+'-'+timeZoneAbbrev) : null);
       // try retrieving by time zone if we can't retrieve by time zone
       if (retHours == null && String.isNotBlank(timeZoneSID)) {
          retHours = busHoursMap.get(timeZoneSID);
       }
       // return a default value so we don't end with a null
       if (retHours == null) {
          retHours = busHoursMap.get(DEFAULT_HOURS_NAME);
       }
       // should never be null - should have default hours
       System.debug('getBusinessHours timeZoneAbbrev='+timeZoneAbbrev+' retHours='+(retHours != null ? retHours.Name : 'NoBusHours'));
       return retHours;
    } // getBusinessHours

    // this is called from before the insert of a record in the trigger 
   public static void createSLATimeLines(List<Stage_History__c> newList) {
      // don't use this anymore
   }

   public static void createSLATimeLines(List<Stage_History__c> newList, Boolean fromTrigger) {
      System.debug('createSLATimeLines newList='+newList.size());
      Stage_History__c[] recsToProcess = new Stage_History__c[]{};
      // only process the records if the dates aren't already filled out
      for (Stage_History__c stageHist : newList) {
         if (stageHist.SLA_Deadline__c == null && stageHist.Expiration_Deadline__c == null) {
            recsToProcess.add(stageHist);
         }
      } // for (Stage_History__c stageHist

      // exit the method if no records to process
      System.debug('createSLATimeLines recsToProcess='+recsToProcess.size());      
      if (recsToProcess.isEmpty()) {
         return;
      }

      Map<String,Stage_SLA__mdt> stageSLAMap = new Map<String,Stage_SLA__mdt>();
        
      // store all in a map for easy lookup - only select ones that have a value
      for (Stage_SLA__mdt  theStageSLA : [SELECT MasterLabel, DeveloperName, SAL_Minutes__c ,Expiration_Minutes__c, Stage__c, OwnedBy__c
                                            FROM Stage_SLA__mdt 
                                           where SAL_Minutes__c != null and Expiration_Minutes__c != null]){
         stageSLAMap.put(theStageSLA.MasterLabel+theStageSLA.Stage__c, theStageSLA);
      }
        
      System.debug('createSLATimeLines stageSLAMap='+stageSLAMap.size());
        
      for (Stage_History__c theSH: newList){
         BusinessHours busHours = getBusinessHours(theSH.TimeZoneAbbrev__c);
         System.debug('createSLATimeLines timeZone='+theSH.TimeZoneAbbrev__c+' busHours='+(busHours != null ? busHours.Name : 'None'));
         String histNotes = 'createSLATimeLines timeZone='+theSH.TimeZoneAbbrev__c+' busHours='+(busHours != null ? busHours.Name : 'None');
            
         String MasterLabel = theSH.Contact__c != null ? 'Contact' : 'Lead';
         DateTime StartDate = System.Now();
         String key = MasterLabel+theSH.New_Stage__c;
         
         Stage_SLA__mdt stageSLA = stageSLAMap.get(key);
         System.debug('createSLATimeLines stageSLA='+(stageSLA != null) +' key='+key+' theSH.OwnedBy__c='+theSH.OwnedBy__c+' stageSLA.OwnedBy='+(stageSLA != null ? stageSLA.OwnedBy__c : ''));
         if (stageSLA != null && String.isNotBlank(stageSLA.OwnedBy__c) && String.isNotBlank(theSH.OwnedBy__c) && !stageSLA.OwnedBy__c.contains(theSH.OwnedBy__c)) {
            System.debug('createSLATimeLines !stageSLA.OwnedBy__c.contains(theSH.OwnedBy)');
            stageSLA = null;
         }

         // only update if both are blank - update to SLA is being handled by the batch job
         if (stageSLA != null && theSH.SLA_Deadline__c == null && theSH.Expiration_Deadline__c == null) {
                
            Integer intSLAminutes = Integer.valueof(stageSLA.SAL_Minutes__c);
            Integer intEXPminutes = Integer.valueof(stageSLA.Expiration_Minutes__c);
            theSH.SLAMinutes__c = intSLAminutes;
            theSH.ExpirationMinutes__c = intEXPminutes;
            
            if (theSH.SLA_Deadline__c == null && !theSH.Expired__c) { 
               Long calcTime = (intSLAminutes * 60000);
               theSH.SLA_Deadline__c = BusinessHours.add(busHours.id , StartDate, calcTime);
               histNotes += ' \nChanging SLA Deadline to '+theSH.SLA_Deadline__c.format('M/d/yyyy H:mm:ss')+' intSLAminutes='+intSLAminutes;
            }
            
            if (theSH.Expiration_Deadline__c == null) { 
               Long calcTime = (intEXPminutes * 60000);
               theSH.Expiration_Deadline__c = BusinessHours.add(busHours.id, StartDate, calcTime);
               histNotes += ' \nChanging Expiration Deadline to '+theSH.Expiration_Deadline__c.format('M/d/yyyy H:mm:ss')+' intEXPminutes='+intEXPminutes;
            } else if(theSH.Expiration_Deadline__c != null && (theSH.SLA_Deadline__c == null || theSH.Expiration_Deadline__c < theSH.SLA_Deadline__c)) {
               theSH.SLA_Deadline__c = BusinessHours.add(busHours.id , theSH.Expiration_Deadline__c , (intSLAminutes - intEXPminutes) * 60000);
               histNotes += ' \nChanging SLA Deadline to '+theSH.SLA_Deadline__c.format('M/d/yyyy H:mm:ss')+' minutes='+(intSLAminutes - intEXPminutes);
            }
         } else {
            histNotes += '; No action required';
         }
            
         System.debug(theSH);
         SLAHelperBatch.addToHistNotes(theSH, histNotes);
      } // for(Stage_History__c theSH
            
   } // createSLATimeLines
    
   public static void updateSLATimeLines(List<Stage_History__c> newList) {
      /* we shouldn't need to do this anymore
      Map<Id,Stage_History__c> processMap = new Map<Id,Stage_History__c>();
      List<Stage_History__c> historyToUpdate = new List<Stage_History__c>();
      for (Stage_History__c stageHist : newList){
         // if it's linked to a previous stage history, we're going to update those previous records
         if (stageHist.Previous_Stage__c != null) {
            processMap.put(stageHist.Previous_Stage__c, stageHist);
         }
      } // for (Stage_History__c stageHist
      
      if (processMap.isEmpty()) {
         return;
      }
        
      // don't select records where the NextStage__c is already populated
      Stage_History__c[] histRecs = [SELECT Id, Stage_Exited_To__c, Exited_Date_Time__c
                                           ,NextStage__c, ProcessNotes__c
                                       FROM Stage_History__c 
                                      WHERE ID IN :processMap.keyset()
                                        AND NextStage__c = null];
      for (Stage_History__c prevStageHist : histRecs) {
         Stage_History__c curStageHist = processMap.remove(prevStageHist.Id);
         if (curStageHist != null) {
            prevStageHist.Stage_Exited_To__c = curStageHist.New_Stage__c;
            prevStageHist.Exited_Date_Time__c = curStageHist.CreatedDate;
            prevStageHist.NextStage__c = curStageHist.Id;
            SLAHelperBatch.addToHistNotes(prevStageHist, 'Set Next Stage to '+curStageHist.New_Stage__c+' with Id='+curStageHist.Id);
            historyToUpdate.add(prevStageHist);
         }
      } // for (Stage_History__c prevStageHist
      
      DmlHelper.performDML2(historyToUpdate, DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'updateSLATimeLines', 'Update Previous Stage Histories', true);
      */
    } // updateSLATimeLines
    
   public static void checkReferrals(Referral__c[] refs, Map<Id,Referral__c> oldMap) {
      Set<Id> oppIdSet = new Set<Id>();
      Set<Id> acctIdSet = new Set<Id>();
      
      for (Referral__c ref : refs) {
         Referral__c oldRef = (oldMap != null ? oldMap.get(ref.Id) : null);
         // trigger the code if the selling opportunity is set.
         if (ref.Selling_Opportunity__c != null && (oldRef == null || ref.Selling_Opportunity__c != oldRef.Selling_Opportunity__c)) {
            oppIdSet.add(ref.Selling_Opportunity__c);
            if (ref.Account__c != null) {
               acctIdSet.add(ref.Account__c);
            }
         }
      } // for (Referral__c ref

      System.debug('checkReferrals refs='+refs.size()+' oppIdSet='+oppIdSet.size());
      checkUpdateCtctStage(oppIdSet, acctIdSet);
   } // checkReferrals

   public static void updateContactStages(List<Opportunity> opps, Map<Id,Opportunity> oldMap) {
      Set<Id> acctIdSet = new Set<Id>();
      Set<Id> oppIdSet = new Set<Id>();
      
      for (Opportunity opp : opps) {
         if (!idsProcessedSet.contains(opp.Id) && String.isNotBlank(opp.NSS_Source__c) && opp.NSS_Source__c.contains(ProspectOwnershipMethods.NSS_INBOUND) && opp.AccountId != null) {
            Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
            //if (oldOpp == null || (opp.Probability != oldOpp.Probability)) {
            if (oldOpp != null && (opp.StageName != oldOpp.StageName)) {
               acctIdSet.add(opp.AccountId);
               oppIdSet.add(opp.Id);
            }
            idsProcessedSet.add(opp.Id);
         }
      } // for
      
      System.debug('updateContactStages opps='+opps.size()+' oppIdSet='+oppIdSet.size());
      checkUpdateCtctStage(oppIdSet, acctIdSet);
   } // updateContactStages
   
   public static void checkUpdateCtctStage(Set<Id> oppIdSet, Set<Id> acctIdSet) {
      System.debug('checkUpdateCtctStage oppIdSet='+oppIdSet.size()+' acctIdSet='+acctIdSet.size());
      if (!oppIdSet.isEmpty() || !acctIdSet.isEmpty()) {
         ALREADY_RAN_SET.add('Referral__cAfter');
         ALREADY_RAN_SET.add('OpportunityAfter');
         if (!RUN_UPDATE_CTCT_SKIP_FUTURE && Utilities.allowFuture()) {
            futureUpdateConStageFromOppStage(oppIdSet, acctIdSet);
         } else {
            updateConStageFromOppStage(oppIdSet, acctIdSet);
         }
      } // if (!oppIdSet.isEmpty() || !acctIdSet.isEmpty
   } // checkUpdateCtctStage
    
   @future
   public static void futureUpdateConStageFromOppStage(Set<Id> oppIdSet, Set<Id> acctIdSet){
      updateConStageFromOppStage(oppIdSet, acctIdSet);
   } // futureUpdateConStageFromOppStage
   
   public static Integer REFERRAL_NUMBER_DAYS = 365;
   
   public class CtctOppWrap {
      public CtctOppWrap(Account acct) {
         acctName = (acct != null ? acct.Name : 'No Acct');
      }
      public String acctName=null;
      public Map<Id,Contact> ctctMap = new Map<Id,Contact>();
      public Referral__c[] refs = new Referral__c[]{};
      public Decimal maxProb = -1;
      // the max stage based on probability
      public String maxStage = null;
      // get the nss sources of the opportunity(ies) with the highest probability
      public String[] sources = new String[]{};
      public String notSoldReason = null;
      public Boolean isLost = false;
      
      public void addRef(Referral__c p_ref) {
         if (p_ref.SourceContact__r != null) { // && p_ref.SourceContact__r.Contact_Stage__c != null) {
            ctctMap.put(p_ref.SourceContact__r.Id, p_ref.SourceContact__r);
         }
         // get the maximum probability from the opportunities for this account/contact
         Opportunity opp = p_ref.Selling_Opportunity__r;
         if (opp != null) {
            System.debug('addRef opp='+opp.Name+' closed='+opp.IsClosed+' won='+opp.IsWon);
            // if it's closed and lost force a 0 probability
            Integer probability = ((opp.IsClosed && !opp.isWon) ? 0 : Integer.valueOf(opp.Probability));
            if (probability > maxProb) {
               maxProb = probability;
               maxStage = opp.StageName;
               sources.clear();
               if (String.isNotBlank(opp.NSS_Source__c)) {
                  sources.add(opp.NSS_Source__c);
               }
            } else if (probability == maxProb && String.isNotBlank(opp.NSS_Source__c) && !sources.contains(opp.NSS_Source__c)) {
               sources.add(opp.NSS_Source__c);
            }
           
             if ((probability == 0 || (opp.IsClosed && !opp.isWon)) && String.isNotBlank(opp.Reason_Not_Sold__c) ){
                 if(opp.OpportunityType__c == 'Payroll' && opp.Reason_Not_Sold__c!= 'Duplicate Opportunity'){
                     notSoldReason = opp.Reason_Not_Sold__c;
                 }
                 else if(String.isBlank(notSoldReason)){
                     notSoldReason = opp.Reason_Not_Sold__c;
                 }
             }   
         } // if (p_ref.Opportunity__c

         refs.add(p_ref);
      } // addRef

     public Boolean checkStageHist(Stage_History__c p_stageHist) {
         Boolean oppMatchedAndUpdate = false;
            // if there's a stage history record and the opportunity has moved to a different stage, expire the stage history
            for (Referral__c ref : refs) {
               // find the matching record
               if (ref.Selling_Opportunity__c == p_stageHist.Opportunity__c) {
                  if (ref.Selling_Opportunity__r.StageName != ref.Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c
                            && p_stageHist.Exited_Date_Time__c == null) {
                     p_stageHist.Stage_Exited_To__c = ref.Selling_Opportunity__r.StageName;
                     p_stageHist.Exited_Date_Time__c = Datetime.now();
                     oppMatchedAndUpdate = true;
                  }
                  break;
               }
            } // for (Referral__c ref : refs)
         return oppMatchedAndUpdate;
      } // checkStageHist
   } // class CtctOppWrap
    
   public static Boolean LOG_OPP_DATA=(Label.DG_Log_Oppty_Flow == 'Y');
   
   public static void updateConStageFromOppStage(Set<Id> oppIdSet, Set<Id> acctIdSet) {
      system.debug('updateConStageFromOppStage oppIdSet: ' + oppIdSet.size()+' acctIdSet='+acctIdSet.size());
      getStageMap(); 
       
      // so we can pull one out of the list for logging purposes
      Id[] oppIds = new Id[]{};
      oppIds.addAll(oppIdSet);
      ErrorLog__c errLog = ErrorLog.logError('DG_LMF_Service', 'updateConStageFromOppStage', 'LOG_DATA', (!oppIds.isEmpty() ? oppIds[0] : null), 'Nbr oppIdSet='+oppIdSet.size()+' Nbr acctIdSet='+acctIdSet.size());
      errLog.BatchSize__c = oppIds.size();
      errLog.NbrSuccess__c = acctIdSet.size();
      
      // collect all of the referral__c ids to later query the referral join records
      Set<Id> referralIds = new Set<Id>();

      // select all of the referrals associated
      Datetime queryDate = Datetime.now().addDays(-REFERRAL_NUMBER_DAYS);

      String nssSource = ProspectOwnershipMethods.NSS_INBOUND +'%';
      Set<String> fldSet = new Set<String>();
      DmlHelper.addFieldsToSet(Schema.SObjectType.Referral__c.fieldSets.DG_LMF_Fields, '', fldSet);
      fldSet.addAll(stageDateFldSet);
      String refQuery = DmlHelper.buildQueryFromSet(fldSet, 'Referral__c');
      
      //String refQuery = 'SELECT Id,OwnerId,Name,Account__c,Account__r.Id,Account__r.Name,ProcessNotes__c,';
      //refQuery += 'SourceContact__c,SourceContact__r.Id,SourceContact__r.AccountId,SourceContact__r.Name,SourceContact__r.Contact_Stage__c,SourceContact__r.ProcessNotes__c,';
      //refQuery += stageDateFields + 'SourceContact__r.Recycle_Reason__c, SourceContact__r.Reject_Reason__c, ';
      //refQuery += 'Selling_Opportunity__r.Id,Selling_Opportunity__r.Name,Selling_Opportunity__r.IsClosed,Selling_Opportunity__r.IsWon,Selling_Opportunity__r.Probability,';
      //refQuery += 'Selling_Opportunity__r.StageName,Selling_Opportunity__r.Reason_Not_Sold__c,Selling_Opportunity__r.OpportunityType__c,Referral_Partner__r.Stage_Sales_Rep_needs_Approval__c ';
      //refQuery += 'FROM Referral__c WHERE Selling_Opportunity__c != null AND Selling_Opportunity__r.NSS_Source__c like :nssSource '; 
      refQuery += ' WHERE Selling_Opportunity__c != null AND Selling_Opportunity__r.NSS_Source__c like :nssSource '; 
      refQuery += 'AND (Selling_Opportunity__c in :oppIdSet or Account__c in :acctIdSet) AND CreatedDate > :queryDate Order by LastModifiedDate DESC';
      
      System.debug('DG_LMF_Service.updateConStageFromOppStage refQuery='+refQuery+'/');       
      Referral__c[] refs = Database.query(refQuery);
       
      ErrorLog.addToDescription(errLog,'refs='+refs.size());
      system.debug('updateConStageFromOppStage refs='+refs.size());
      if (refs.isEmpty()) {
         return;
      }
      
      Map<Id,CtctOppWrap> refMap = new Map<Id,CtctOppWrap>();
      String oppWrapMsg = 'Adding to wrapper';
      for (Referral__c ref : refs) {
         referralIds.add(ref.Id);
         // group by account id
         if (ref.Account__c != null) {
            CtctOppWrap coWrap = (refMap.containsKey(ref.Account__c) ? refMap.get(ref.Account__c) : new CtctOppWrap(ref.Account__r));
            coWrap.addRef(ref);
            oppWrapMsg += ';ref='+ref.Name+' ctctId='+ref.SourceContact__c+' curStage='+(ref.SourceContact__c != null ? ref.SourceContact__r.Contact_Stage__c : 'NoCtct');
            refMap.put(ref.Account__c,coWrap);
         } // if (ref.Account__c != null
      } // for (Referral__c ref
      oppWrapMsg += '\nrefMap='+refMap.size();
      ErrorLog.addToDescription(errLog,oppWrapMsg);

      Stage_History__c[] historyToUpdate = new Stage_History__c[]{};

      Stage_History__c[] stageHistories = [Select Id, Opportunity__c, Opportunity__r.AccountId
                                                 ,Exited_Date_Time__c, Expiration_Deadline__c, ExpirationMinutes__c, Expired__c
                                                 ,New_Stage__c, NextStage__c
                                                 ,ProcessNotes__c, Run_Expiration_Scheduled_Job__c
                                                 ,SLA_Deadline__c, SLAMinutes__c
                                                 ,Stage_Exited_To__c
                                             From Stage_History__c
                                            Where Opportunity__c in :oppIdSet
                                            order by createdDate desc];
      String stageHisMsg = 'SH Adding to wrapper';
      for (Stage_History__c stageHist : stageHistories) {
         if (stageHist.Opportunity__c != null && stageHist.Opportunity__r.AccountId != null) {
            stageHisMsg += ';opp='+stageHist.Opportunity__c+' acctId='+stageHist.Opportunity__r.AccountId;
            CtctOppWrap coWrap = refMap.get(stageHist.Opportunity__r.AccountId);
            stageHisMsg += '\ncoWrap='+coWrap;
            if (coWrap != null) {
               // see if the stage history matches the opportunity and needs to be updated
               if (coWrap.checkStageHist(stageHist)) {
                  stageHisMsg += '\nmatched stageHis';
                  historyToUpdate.add(stageHist);
               }
            } // if (coWrap != null
         }
         //if (!stageHistByOppIdMap.containsKey(stageHist.Opportunity__c)) {
         //   stageHistByOppIdMap.put(stageHist.Opportunity__c, stageHist);
         //}
      } // for (Stage_History__c stageHist
      stageHisMsg += '\nstageHistories='+stageHistories.size()+' historyToUpdate='+historyToUpdate.size();
      ErrorLog.addToDescription(errLog,stageHisMsg);
      
      // keep a map of probability by the contact id. If multiple opps, we're keeping the highest probability
      //Map<Id,Decimal> conIdOppMap = new Map<Id,Decimal>();
      // keep a map of the not sold reasons
      //Map<Id,String> conIdOppNotSoldReasonMap = new Map<Id,String>();
      Map<Id,Contact> ctctsToUpdateMap = new Map<Id,Contact>();
    // Map<Id, Contact> oldCtctMap = new Map<Id,Contact>();
      
      for (CtctOppWrap coWrap : refMap.values()) {
         String ctctMsg = coWrap.acctName+' maxProb='+coWrap.maxProb;
         String newStage = null;
         String recycleReason = null;
         if (coWrap.maxProb == 0) {
            newStage = getNotSoldContactStage(coWrap.maxStage,coWrap.notSoldReason);
            recycleReason = (String.isNotBlank(coWrap.notSoldReason) ? coWrap.notSoldReason : coWrap.maxStage);
         } else {
            newStage = getMarketingStageFromOppStage(coWrap.maxStage);
         }
         if (newStage == null) {
            newStage = getMarketingStage(coWrap.maxProb, coWrap.sources);
         }
         ctctMsg += ' newStage='+newStage+' recycleReason='+recycleReason;
         if (String.isNotBlank(newStage)) {
            ctctMsg += ' ctcts='+coWrap.ctctMap.size();
            // update all of the contacts to the correct stage
            for (Contact ctct : coWrap.ctctMap.values()) { 
               // TODO - do we need to check if the contact is already beyond this stage?
               ctctMsg += ' ctct='+ctct.Id+' currentStage='+ctct.Contact_Stage__c;
               if (ctct.Contact_Stage__c != newStage) {
               
                  String stageMsg = 'Contact Stage moved from '+ctct.Contact_Stage__c+' to '+newStage+' due to an Opp probability of '+coWrap.maxProb;
                  StringHelper.addToProcessNotes(ctct,stageMsg);
                  ctctMsg += stageMsg;
                  
                  // we want to do this here since we're skipping the before trigger later
                  setStageFields(ctct, newStage, ctct.Contact_Stage__c, false, true, false); 
                   
                  ctct.Contact_Stage__c = newStage;
                  ctct.Recycle_Reason__c = (String.isBlank(recycleReason) || newStage == 'Recycle' ? recycleReason : null);
                  ctct.Reject_Reason__c = (String.isBlank(recycleReason) || newStage == 'Reject' ? recycleReason : null);
                  ctctsToUpdateMap.put(ctct.Id,ctct);
                  
               }
            }
         } // if (String.isNotBlank(newStage
         ErrorLog.addToDescription(errLog,ctctMsg);
      } // for (CtctOppWrap coWrap

      DmlHelper.performDML2(historyToUpdate, DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'updateConStageFromOppStage', 'Update Stage Histories for Opp', true);

      Set<Id> ctctIdSet = new Set<Id>();
        
      // check the referral join record to account for team selling
      ReferralJoin__c[] refJoins = [Select id
                                          ,PAS_Referral__r.Selling_Opportunity__c
                                          ,PAS_Referral__r.Selling_Opportunity__r.StageName
                                          ,PAS_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                          ,PAS_Referral__r.SourceContact__c
                                          ,MMS_Referral__r.Selling_Opportunity__c
                                          ,MMS_Referral__r.Selling_Opportunity__r.StageName
                                          ,MMS_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                          ,MMS_Referral__r.SourceContact__c
                                          ,Core_Referral__r.Selling_Opportunity__c
                                          ,Core_Referral__r.Selling_Opportunity__r.StageName
                                          ,Core_Referral__r.Selling_Opportunity__r.OpportunityType__c
                                          ,Core_Referral__r.SourceContact__c
                                      From ReferralJoin__c 
                                     Where PAS_Referral__c IN :referralIds 
                                        OR MMS_Referral__c IN :referralIds 
                                        OR Core_Referral__c IN :referralIds];
      ErrorLog.addToDescription(errLog,'refJoins='+refJoins.size());
      for (ReferralJoin__c refJoin : refJoins) {                                     
         if (refJoin.PAS_Referral__r.Selling_Opportunity__r.OpportunityType__c == 'Payroll'
                 && refJoin.PAS_Referral__r.Selling_Opportunity__r.StageName == 'Create - Qualified'
                 && refJoin.PAS_Referral__r.SourceContact__c != null ) {
            System.debug('updateConStageFromOppStage ctctId PAS refJoin');
            ErrorLog.addToDescription(errLog,'PAS refJoin '+refJoin.PAS_Referral__r.SourceContact__c);
            ctctIdSet.add(refJoin.PAS_Referral__r.SourceContact__c);    
         }
         if (refJoin.MMS_Referral__r.Selling_Opportunity__r.OpportunityType__c == 'Payroll'
                 && refJoin.MMS_Referral__r.Selling_Opportunity__r.StageName == 'Create - Qualified'
                 && refJoin.MMS_Referral__r.SourceContact__c != null) {
            System.debug('updateConStageFromOppStage ctctId MMS refjoin');
            ErrorLog.addToDescription(errLog,'MMS refJoin '+refJoin.MMS_Referral__r.SourceContact__c);
            ctctIdSet.add(refJoin.MMS_Referral__r.SourceContact__c);    
         }
         if (refJoin.Core_Referral__r.Selling_Opportunity__r.OpportunityType__c == 'Payroll'
                 && refJoin.Core_Referral__r.Selling_Opportunity__r.StageName == 'Create - Qualified'
                 && refJoin.Core_Referral__r.SourceContact__c != null) {
            System.debug('updateConStageFromOppStage ctctId Core refJoin');
            ErrorLog.addToDescription(errLog,'Core refJoin '+refJoin.Core_Referral__r.SourceContact__c);
            ctctIdSet.add(refJoin.Core_Referral__r.SourceContact__c);    
         }                                                                                         
                                         
      } // for(ReferralJoin__c joins
        
      System.debug('updateConStageFromOppStage ctctIdSet='+ctctIdSet.size());
      
      if (!ctctIdSet.isEmpty()) {
         Contact[] ctcts = [Select Id, Contact_stage__c, ProcessNotes__c from Contact Where Id IN :ctctIdSet];
         for (Contact ctct : ctcts) {
            // use the one already in the update map if possible
            Contact checkCtct = (ctctsToUpdateMap.containsKey(ctct.Id) ? ctctsToUpdateMap.get(ctct.Id) : ctct);
            if (checkCtct.Contact_Stage__c != 'SAO') {
                StringHelper.addToProcessNotes(checkCtct,'Contact Stage moved from '+checkCtct.Contact_Stage__c+' to SAO due to Referral Join');
                ErrorLog.addToDescription(errLog,checkCtct.Id+' Contact Stage moved from '+checkCtct.Contact_Stage__c+' to SAO due to Referral Join');
                checkCtct.Contact_Stage__c = 'SAO'; 
                ctctsToUpdateMap.put(ctct.Id,checkCtct);
            }
            System.debug('updateConStageFromOppStage checkCtct=' + checkCtct);
         }
         System.debug('updateConStageFromOppStage ctctsToUpdateMap=' + ctctsToUpdateMap.size());
        
      } // if (!ctctIdSet.isEmpty
      
      ErrorLog.addToDescription(errLog,'ctctsToUpdateMap='+ctctsToUpdateMap.size());
      // skip DG_DFR_Controller for contacts here. DFR will already have been updated due to opp update
      TriggerMethods.addSkipName('DG_DFR_Controller');

      // to force contacts through the trigger for stage history
      String key='ContactAfter';
      ALREADY_RAN_SET.remove(key);
       
      // skip the before trigger, just allow the after trigger
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      DmlHelper.performDML2(ctctsToUpdateMap.values(), DmlHelper.DML_UPDATE, 'DG_LMF_Service', 'updateConStageFromOppStage', 'Update Contact Stage', true);
      if (LOG_OPP_DATA) {
         ErrorLog.checkSave();
      }
      TriggerMethods.clearSkipNames();
   } // updateConStageFromOppStage
   
   public static String getMarketingStageFromOppStage(String oppStage) {
      String mktgStage = null;
      if (String.isNotBlank(oppStage)) {
         DFR_Stage_conversion__mdt[] stages = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Field_Value__c=:oppStage limit 1];
         if (!stages.isEmpty()) {
            mktgStage = stages[0].Stage_Value__c;
         }
      }
      return mktgStage;
   } // getMarketingStageFromOppStage
    
   public static String getMarketingStage(Decimal probability, String[] sources, String notSoldReason) {
      if (probability == 0 && String.isNotBlank(notSoldReason)) {
         return getNotSoldContactStage(null, notSoldReason);
      }
      return getMarketingStage(probability,sources);
   } // getMarketingStage
    
   public static String getMarketingStage(Decimal probability, String[] sources) {
      // get the stage with the highest sort order that matches the probabilty
      String returnStage = null;
      Decimal highestSortOrder = 0;
      MarketingStage__mdt[] stages = getOppProbabilityStages();
      System.debug('getMarketingStage probability='+probability+' stages='+(stages != null ? stages.size() : -1));
      if (stages != null) {
         for (MarketingStage__mdt stage : stages) {
            System.debug('getMarketingStage checking stage='+stage.MasterLabel+' min='+stage.OppProbabilityMin__c+' max='+stage.OppProbabilityMax__c);
            if (probability >= stage.OppProbabilityMin__c 
                      && (stage.OppProbabilityMax__c == null || probability < stage.OppProbabilityMax__c)) {
               // check if sources match. 
               Boolean sourceMatch = (String.isBlank(stage.Source__c));
               if (!sourceMatch && !sources.isEmpty()) {
                  // the source(s) valid for this stage
                  String[] stageSources = stage.Source__c.split(',');
                  for (String thisSource : sources) {
                     if (stageSources.contains(thisSource)) {
                        sourcematch = true;
                        break;
                     }
                  } // for (String thisSource : sources
               } // if (!sourceMatch
               if (sourceMatch && stage.SortOrder__c > highestSortOrder) {
                  returnStage = stage.MasterLabel;
                  highestSortOrder = stage.SortOrder__c;
                  System.debug('updateConStageFromOppStage found a stage match based on Probability! returnStage='+returnStage+' highestSortOrder='+highestSortOrder);
               }
               //returnStage = stage.MasterLabel;
               //break;
            }
         } // for (MarketingStage__mdt stage
      } // if (stages != null
      return returnStage;
   } // getMarketingStage

    public static MarketingStage__mdt[] oppProbabilityStages = null;
    
    public static MarketingStage__mdt[] getOppProbabilityStages() {
       if (oppProbabilityStages == null) {
          oppProbabilityStages = [Select MasterLabel, OppProbabilityMin__c, OppProbabilityMax__c, Source__c, SortOrder__c
                                    from MarketingStage__mdt 
                                   Where OppProbabilityMin__c != null
                                order by OppProbabilityMin__c ];
       } // if (oppProbabilityStages == null
       return oppProbabilityStages;
    } // getOppProbabilityStages
    
    public static map<string, string> mapNSRtoConStage = null; //new map<string, string>();
    
    public static String DEF_NOT_SOLD_STAGE=Label.DG_DefaultCtctStageFromOpp;

    public static String getNotSoldContactStage(String stageName, String reason) {
       String[] queryReasons = new String[]{};
       if (String.isNotBlank(reason) && reason.length() >40){
          reason = reason.substring(0, 40);
          System.debug('getNotSoldContactStage Truncate reason:::'+reason);
       }
       if (String.isNotBlank(reason)) {
          queryReasons.add(reason);
       }
       if (String.isNotBlank(stageName)) {
          queryReasons.add(stageName);
       }
       
       Not_Sold_Reason_to_Contact_Stage_Map__mdt[] notSoldMappings = (queryReasons.isEmpty() ? new Not_Sold_Reason_to_Contact_Stage_Map__mdt[]{}
                                                                    : [SELECT MasterLabel, Contact_Stage__c 
                                                                         from Not_Sold_Reason_to_Contact_Stage_Map__mdt
                                                                        Where MasterLabel in :queryReasons]);       
       String oppStage = null;
       String reasonStage = null;
       for (Not_Sold_Reason_to_Contact_Stage_Map__mdt notSoldMapping : notSoldMappings) {
          if (notSoldMapping.MasterLabel == stageName) {
             oppStage = notSoldMapping.Contact_Stage__c;
          }
          if (notSoldMapping.MasterLabel == reason) {
             reasonStage = notSoldMapping.Contact_Stage__c;
          }
       }
       String notSoldStage = (String.isNotBlank(reasonStage) ? reasonStage 
                          : (String.isNotBlank(oppStage) ? oppStage : (DEF_NOT_SOLD_STAGE != 'None' ? DEF_NOT_SOLD_STAGE : null)));
       System.debug('getNotSoldContactStage stageName='+stageName+' reason='+reason+' oppStage='+oppStage+' reasonStage='+reasonStage+' mappings='+notSoldMappings.size()+' notSoldStage='+notSoldStage);
       return(notSoldStage);

    } // getNotSoldContactStage
    

} // class DG_LMF_Service