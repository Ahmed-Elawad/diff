/* 
 * If any change occurs on the opportunity that might affect the Campaign Influence, check for it here.

   History
   -------
   04/23/2017 Dan Carmen        Created
   03/02/2020 Dan Carmen        Add additional tracking for NSS Source and Referral Contact

 */
public with sharing class OpptyCampaignInfluence implements TriggerInterface2 {
   public static Boolean SKIP_TRIGGER=false;

   //public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      System.debug('OpptyCampaignInfluence.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (isAfter) {
         // all of the opps where we're checking for lead source
         Set<Id> leadSourceOppIdSet = new Set<Id>();
         // all of the opps where we're checking for the campaign field
         Set<Id> campaignOppIdSet = new Set<Id>();
         // All of the opportunities to check for campaign influence.
         Set<Id> oppsIdSetToCheckForInfluence = new Set<Id>();
         // to retrieve the campaigns with the lead source 
         Set<String> leadSourceSet = new Set<String>();
      
         for (SObject rec : recs) {
            Opportunity opp = (Opportunity)rec;
            Opportunity oldOpp = (Opportunity)(oldMap != null ? oldMap.get(opp.Id) : null);
            // check if this is an insert, or the lead source changes.
            if (String.isNotBlank(opp.LeadSource) && (oldOpp == null || (oldOpp != null && opp.LeadSource != oldOpp.LeadSource))) {
               oppsIdSetToCheckForInfluence.add(opp.Id);
               leadSourceOppIdSet.add(opp.Id);
               leadSourceSet.add(opp.LeadSource);
            }
            if (opp.Campaign__c != null && (oldOpp == null || (oldOpp != null && opp.Campaign__c != oldOpp.Campaign__c)) ) {
               oppsIdSetToCheckForInfluence.add(opp.Id);
               campaignOppIdSet.add(opp.Id);
            }
         } // for (SObject rec
      
         checkCampaignInfluence(oppsIdSetToCheckForInfluence, leadSourceSet, campaignOppIdSet, leadSourceOppIdSet);
      } // if (isAfter
   } // checkAllAfterTrigger
   
   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}

   // for testing purposes only
   public static Boolean SKIP_FUTURE=false;
      
   public static void checkCampaignInfluence(Set<Id> oppIdSet, Set<String> leadSourceSet, Set<Id> campaignOppIdSet, Set<Id> leadSourceOppIdSet) {
      System.debug('checkCampaignInfluence oppIdSet='+oppIdSet.size()+' leadSourceSet='+leadSourceSet+' campaignOppIdSet='+campaignOppIdSet.size()+' leadSourceOppIdSet='+leadSourceOppIdSet.size());
      if (!oppIdSet.isEmpty()) {
         if (SKIP_FUTURE || System.isFuture() || System.IsBatch()) {
            checkCampaignInfluenceNow(oppIdSet, leadSourceSet, campaignOppIdSet, leadSourceOppIdSet);
         } else {
            checkCampaignInfluenceFuture(oppIdSet, leadSourceSet, campaignOppIdSet, leadSourceOppIdSet);
         }
      } // if (!oppIds
   } // checkCampaignInfluence

   @future
   public static void checkCampaignInfluenceFuture(Set<Id> oppIdSet, Set<String> leadSourceSet, Set<Id> campaignOppIdSet, Set<Id> leadSourceOppIdSet) {
      checkCampaignInfluenceNow(oppIdSet, leadSourceSet, campaignOppIdSet, leadSourceOppIdSet);
   } // checkCampaignInfluenceFuture
   
   public static void checkCampaignInfluenceNow(Set<Id> oppIdSet, Set<String> leadSourceSet, Set<Id> campaignOppIdSet, Set<Id> leadSourceOppIdSet) {
      insertCis.clear();
      updateCis.clear();
      
      // retrieve the opportunities with the campaign influence
      Opportunity[] opps = getOpps(oppIdSet);
      for (Opportunity opp : opps) {
         checkCampaignInfluence(opp, leadSourceSet, campaignOppIdSet, leadSourceOppIdSet);
      } // for (Opportunity opp
      
      DmlHelper.performDML2(insertCis, DmlHelper.DML_INSERT, 'OpptyCampaignInfluence', 'processLeadSourceCheckNow', 'Insert new Campaign Influence', false);
      DmlHelper.performDML2(updateCis, DmlHelper.DML_UPDATE, 'OpptyCampaignInfluence', 'processLeadSourceCheckNow', 'Update Campaign Influence', false);
      ErrorLog.checkSave();
   } // checkCampaignInfluenceNow
   
   // new records we're creating
   public static CampaignInfluence[] insertCis = new CampaignInfluence[]{};
   // update an existing record.
   public static CampaignInfluence[] updateCis = new CampaignInfluence[]{};
   
   // the number of minutes to use when we assume that the campaign history record is the same one being
   // triggered by this check (so if it's created automatically or by another process we will not increment the counter)
   public static Integer INFLUENCE_MINUTE_DIFFERENCE = Integer.valueOf(Label.CampaignInfluence_MinutesToMatch);
   
   public static void checkCampaignInfluence(Opportunity opp, Set<String> leadSourceSet, Set<Id> campaignOppIdSet, Set<Id> leadSourceOppIdSet) {
      CampaignInfluence leadSourceCi = null;
      CampaignInfluence campaignIdCi = null;
      Boolean leadSourceChange = leadSourceOppIdSet.contains(opp.Id);
      Boolean campaignIdChange = campaignOppIdSet.contains(opp.Id);
      
      System.debug('checkCampaignInfluence opp='+opp.Name+' existing influences='+opp.CampaignInfluences.size()+' leadSourceChange='+leadSourceChange+' campaignIdChange='+campaignIdChange);
      for (CampaignInfluence ci : opp.CampaignInfluences) {
         if (leadSourceCi == null && leadSourceChange && ci.Campaign != null && ci.Campaign.LeadSource__c == opp.LeadSource) {
            leadSourceCi = ci;
         }
         if (campaignIdCi == null && campaignIdChange && ci.CampaignId == opp.Campaign__c) {
            campaignIdCi = ci;
         }
         if (leadSourceCi == null && campaignIdCi == null) {
            break;
         }
      } // for (CampaignInfluence ci

      // we'll use the campaign one over the lead source one if they both exist.
      CampaignInfluence checkCi = (campaignIdCi != null ? campaignIdCi : leadSourceCi);
      System.debug('checkCampaignInfluence has checkCi='+(checkCi != null));
      if (checkCi != null) {
         // if the influence record was created more than a certain amount of minutes before the current time, increment the counter.
         // we're going to assume this should hit the trigger pretty quickly.
         // add the minutes to the created time. if the minutes is greater than the current time, we'll assume it's the
         // same record and do nothing. If it's less, then it's older (existing) and we'll increment the counter.
         Datetime checkTime = checkCi.CreatedDate.addMinutes(INFLUENCE_MINUTE_DIFFERENCE);
         // this can be set to 0 for testing purposes
         if (INFLUENCE_MINUTE_DIFFERENCE == 0 || checkTime < Datetime.now()) {
            leadSourceCi.CampaignCounter__c = checkCi.CampaignCounter__c+1;
            CampaignInfluenceHelper.checkOppFields(opp, leadSourceCi);
            updateCis.add(checkCi);
         }
      }
      if (checkCi == null) {
         // try to create a new CampaignInfluence record
         Id campaignId = null;
         if (campaignIdChange) {
            campaignId = opp.Campaign__c;
         } else if (leadSourceChange) {
            Campaign camp = getDefaultCampaign(leadSourceSet, opp.LeadSource);
            if (camp != null) {
               campaignId = camp.Id;
            }
         }
         System.debug('checkCampaignInfluence create new campaignId='+campaignId);
         if (campaignId != null) {
            checkCi = new CampaignInfluence(OpportunityId=opp.Id, CampaignId=campaignId, OrderOfInfluence__c=opp.CampaignInfluences.size()+1);
            if (opp.OpportunityContactRoles != null && !opp.OpportunityContactRoles.isEmpty()) {
               checkCi.ContactId=opp.OpportunityContactRoles[0].ContactId;
            }
            checkCi.ModelId = getDefaultModel().Id;
            CampaignInfluenceHelper.checkOppFields(opp, checkCi);
            insertCis.add(checkCi);
         }
      } // if (thisCi == null
   } // checkOppLeadSource
   
   // Store so this only needs to be done once in a transaction.
   public static Map<String,Campaign> defaultCampaignMap = null;
   
   // get the default campaign for a lead source
   public static Campaign getDefaultCampaign(Set<String> leadSourceSet, String leadSourceName) {
      // this is so we only select the records if we need to. Hopefully there should already be an existing 
      // campaign influence record so we don't need to do this step at all.
      if (defaultCampaignMap == null) {
         defaultCampaignMap = new Map<String,Campaign>();
         Campaign[] camps = [Select Id, Name, LeadSource__c, StartDate, EndDate
                               From Campaign
                              Where LeadSource__c in :leadSourceSet
                                and IsActive = true
                                and LeadSourceDefaultCampaign__c = true
                                and StartDate <= :Date.today()
                                and (EndDate = null or EndDate >= :Date.today())
                               order by StartDate desc
                                ];
         for (Campaign camp : camps) {
            // make sure they're only added to the map once, newest first
            if (!defaultCampaignMap.containsKey(camp.LeadSource__c)) {
               defaultCampaignMap.put(camp.LeadSource__c, camp);
            }
         } // for (Campaign camp
                                
      } // if (defaultCampaignMap == null
      return defaultCampaignMap.get(leadSourceName);
   } // getDefaultCampaign
   
   public static CampaignInfluenceModel defaultModel = null;
   
   public static CampaignInfluenceModel getDefaultModel() {
      if (defaultModel == null) {
         try {
            defaultModel = [Select Id, ModelType
                              From CampaignInfluenceModel
                             Where IsActive = true
                               and IsDefaultModel = true
                             limit 1];
         } catch (Exception e) {
            System.debug('getDefaultModel could not select default model '+e.getMessage()+'; '+e.getStackTraceString());
            // so we don't reselect multiple times
            defaultModel = new CampaignInfluenceModel();
         }
      } // if (defaultModel == null
      System.debug('getDefaultModel defaultModel='+defaultModel);
      return defaultModel;
   } // getDefaultModel
   
   public static Opportunity[] getOpps(Set<Id> oppIdSet) {
      Opportunity[] opps = [Select Id, LeadSource, Name
                                  ,CampaignId, Campaign__c, NSS_Source__c
                                  ,Referring_Employee__c, Referring_Employee__r.Name
                                  ,Referral_Contact__c, Referral_Contact__r.Name
                                 ,(Select Id, CampaignId, ContactId, Influence, ModelId, OpportunityId, RevenueShare
                                         ,CampaignCounter__c, NSS_Source__c, OrderOfInfluence__c, ProcessNotes__c 
                                         ,ReferralContactId__c, ReferralContactName__c
                                         ,ReferringEmployeeId__c, ReferringEmployeeName__c
                                         ,Campaign.LeadSource__c
                                         ,CreatedDate
                                     From CampaignInfluences
                                    order by CreatedDate ASC)   // select the oldest first
                                 ,(Select Id, ContactId, IsPrimary
                                     From OpportunityContactRoles
                                    Where IsPrimary=true
                                    limit 1)
                              From Opportunity
                             Where Id in :oppIdSet];
      System.debug('getOpps opps='+opps.size());
      return opps;
   } // getOpps
   
 
} // OpptyCampaignInfluence