/* 
 * Methods for working with on the CampaignInfluence object
 *
 * History
 * -------
   03/29/2018 Dan Carmen        Created
   03/02/2020 Dan Carmen        Add additional tracking for NSS Source and Referral Contact

 */
public without sharing class CampaignInfluenceHelper {
   
   public static Boolean SKIP_FUTURE=false;
   public static Boolean SKIP_TRIGGER=false;
   public static Boolean LOG_DATA=(Label.CampaignInfluenceHelper_LogData == 'Y');
   
   // if there's a user we want to indicate processing is required
   public static String PROCESSING_NAME='NAME';
   
   //public static Set<Id> opptyIdSet = new Set<Id>();
   //public static String runLog = '';
    
   public static void checkFromTrigger(CampaignInfluence[] cis, Map<Id,CampaignInfluence> oldMap, Boolean isBefore) {
      System.debug('checkFromTrigger isBefore='+isBefore+' SKIP_TRIGGER='+SKIP_TRIGGER);
      if (SKIP_TRIGGER) {
         return;
      }
      User runningUser = UserHelper.getRunningUser();

      if (isBefore) {
         Set<Id> opptyIdSet = new Set<Id>();
         System.debug('CampaignInfluenceHelper.checkFromTrigger');
         String runLog = 'CampaignInfluenceHelper.checkFromTrigger isBefore='+isBefore+' cis='+cis.size();
         runLog += '\n userId='+UserInfo.getUserId();
         runLog += '\n runningUser='+runningUser;
         // if on insert, check for existing and increment the OrderOfInfluence__c field
         Map<Id, CampaignInfluence[]> ciByOppMap = new Map<Id, CampaignInfluence[]>();

         for (CampaignInfluence ci : cis) {
            // set the NeedsProcessing__c flag.
            ci.NeedsProcessing__c = (runningUser == null || runningUser.Name == PROCESSING_NAME);
            CampaignInfluence oldCI = (oldMap != null && ci.Id != null ? oldMap.get(ci.Id) : null);
            runLog += '\n has oldCI='+(oldCI != null)+' ci.OpportunityId='+ci.OpportunityId+' modelId='+ci.ModelId+' NeedsProcessing='+ci.NeedsProcessing__c;
            if (oldCI == null && ci.OpportunityId != null) {
               // collect the opportunity ids
               System.debug('checkFromTrigger added to opptyIdSet '+ci.OpportunityId);
               //opptyIdSet.add(ci.OpportunityId);
            
               //CampaignInfluence[] oppCIs = (ciByOppMap.containsKey(ci.OpportunityId) ? ciByOppMap.get(ci.OpportunityId) : new CampaignInfluence[]{});
               //oppCIs.add(ci);
               //ciByOppMap.put(ci.OpportunityId, oppCIs);
            }
         }
         runLog += '\n opptyIdSet='+opptyIdSet;
         System.debug('runLog='+runLog);
      } // if (isBefore
      if (!isBefore) {
         // we're running in the after trigger
         Boolean runInFuture = !SKIP_FUTURE && runningUser != null;
         String runLog = 'CampaignInfluenceHelper.checkFromTrigger isBefore='+isBefore+' cis='+cis.size()+' runInFuture='+runInFuture;
        // if there's no running user selected, run in context
         System.debug('checkFromTrigger runInFuture='+runInFuture);
         Set<Id> opptyIdSet = new Set<Id>();
         Set<Id> influenceIdSet = new Set<Id>();

         for (CampaignInfluence ci : cis) {
            CampaignInfluence oldCI = (oldMap != null && ci.Id != null ? oldMap.get(ci.Id) : null);
            runLog += '\n has oldCI='+(oldCI != null)+' ci.OpportunityId='+ci.OpportunityId+' modelId='+ci.ModelId+' NeedsProcessing='+ci.NeedsProcessing__c;
            if (oldCI == null && ci.OpportunityId != null) {
               // collect the opportunity ids
               System.debug('checkFromTrigger added to opptyIdSet '+ci.OpportunityId);
               opptyIdSet.add(ci.OpportunityId);
               influenceIdSet.add(ci.Id);
            }
         } // for (CampaignInfluence
      //if (!opptyIdSet.isEmpty()) {
         //if (!runInFuture || System.isBatch() || System.isFuture()) {
            runLog += '\n calling checkInfluenceOnInsertNow opptyIdSet='+opptyIdSet.size();
            checkInfluenceOnInsertNow(influenceIdSet, opptyIdSet, runLog);
         //} else {
         //   runLog += '\n calling checkInfluenceOnInsertFuture';
         //   checkInfluenceOnInsertFuture(opptyIdSet, runLog);
         //} 
      //}

      //if (!ciByOppMap.isEmpty()) {
      //   checkOpportunityInfo(ciByOppMap);
      //}
         //ErrorLog__c errLog = ErrorLog.logError('CampaignInfluenceHelper', 'checkFromTrigger', 'LOG_DATA', null, runLog, null, true);
      } // if (!isBefore
   } // checkFromTrigger
   
   @future
   public static void checkInfluenceOnInsertFuture(Set<Id> p_influenceIdSet, Set<Id> p_opptyIdSet, String p_runLog) {
      checkInfluenceOnInsertNow(p_influenceIdSet, p_opptyIdSet, p_runLog);
   } // checkInfluenceOnInsertFuture
   
   public static void checkInfluenceOnInsertNow(Set<Id> p_influenceIdSet, Set<Id> p_opptyIdSet, String p_runLog) {
      p_runLog += '\ncheckInfluenceOnInsertNow influenceIdSet='+p_influenceIdSet.size()+' opptyIdSet='+p_opptyIdSet.size();
      Id[] oppIds = new Id[]{};
      oppIds.addAll(p_opptyIdSet);
      //Opportunity[] opps = OpptyCampaignInfluence.getOpps(oppIds);
      //Opportunity[] opps = new Opportunity[]{};
      Opportunity[] opps = [Select Id, Name
                                  ,Referring_Employee__c, Referring_Employee__r.Name
                                  ,NSS_Source__c, Referral_Contact__r.Id, Referral_Contact__r.Name
                                 ,(Select Id, CampaignId, ContactId, Influence, OpportunityId, RevenueShare
                                         ,CampaignCounter__c, NSS_Source__c, OrderOfInfluence__c, ProcessNotes__c
                                         ,ReferralContactId__c, ReferralContactName__c
                                         ,ReferringEmployeeId__c, ReferringEmployeeName__c
                                     From CampaignInfluences
                                    order by CreatedDate ASC)   // select the oldest first
                              From Opportunity
                             Where Id in :p_opptyIdSet];
      p_runLog += '\nAfter Query opps='+opps.size();
      
      /*
      CampaignInfluence[] campInfluences = [Select Id, CampaignId, ContactId, CreatedDate, Influence, ModelId, OpportunityId, RevenueShare
                                                  ,CampaignCounter__c, OrderOfInfluence__c
                                                  ,ReferringEmployeeId__c, ReferringEmployeeName__c
                                              From CampaignInfluence
                                             Where OpportunityId in :p_opptyIdSet
                                           order by OpportunityId, CreatedDate ASC];
      p_runLog += '\ncheckInfluenceOnInsertNow campInfluences='+campInfluences.size();
      */
      Map<Id,CampaignInfluence> updateCIMap = new Map<Id,CampaignInfluence>();
      /*
      Map<Id,CampaignInfluence[]> influenceByOppIdMap = new Map<Id,CampaignInfluence[]>();
      
      for (CampaignInfluence ci : campInfluences) {
         CampaignInfluence[] byOppId = (influenceByOppIdMap.containsKey(ci.OpportunityId) ? influenceByOppIdMap.get(ci.OpportunityId) : new CampaignInfluence[]{});
         byOppId.add(ci);
         if (ci.OrderOfInfluence__c != byOppId.size()) {
            p_runLog += '\noppId='+ci.OpportunityId+' order='+byOppId.size();
            ci.OrderOfInfluence__c = byOppId.size();
            updateCIMap.put(ci.Id, ci);
         }
      } // for (CampaignInfluence ci
      */
      for (Opportunity opp : opps) {
         p_runLog += '\nIn Loop opp='+opp.Name+' influences='+opp.CampaignInfluences.size();
         Integer influenceCnt = 1;
         CampaignInfluence lastInfluence = null;
         Map<Id,Integer> campCountMap = new Map<Id,Integer>();
         for (CampaignInfluence ci : opp.CampaignInfluences) {
            lastInfluence = ci;
            Integer campCount = (campCountMap.containsKey(ci.CampaignId) ? campCountMap.get(ci.CampaignId) : 0);
            campCount += 1;
            campCountMap.put(ci.CampaignId, campCount);
            if (ci.OrderOfInfluence__c == null || ci.OrderOfInfluence__c != influenceCnt) {
               StringHelper.addToProcessNotes(ci,'set influenceCnt '+influenceCnt);
               //p_runLog += '\n set influenceCnt '+influenceCnt;
               ci.OrderOfInfluence__c = influenceCnt;
               updateCIMap.put(ci.Id, ci);
            }
            if (ci.CampaignCounter__c == null || ci.CampaignCounter__c != campCount) {
               StringHelper.addToProcessNotes(ci,'set CampaignCounter '+campCount);
               //p_runLog += '\n set CampaignCounter '+campCount;
               ci.CampaignCounter__c = campCount;
               updateCIMap.put(ci.Id, ci);
            }
            influenceCnt++;
         } // for (CampaignInfluence
         if (checkOppFields(opp, lastInfluence)) {
            updateCIMap.put(lastInfluence.Id, lastInfluence);
         }
         
         /*
         if (lastInfluence != null && opp.Referring_Employee__c != null && String.isBlank(lastInfluence.ReferringEmployeeId__c)) {
            p_runLog += '\n set referring employee '+opp.Referring_Employee__r.Name;
            lastInfluence.ReferringEmployeeId__c = opp.Referring_Employee__c;
            lastInfluence.ReferringEmployeeName__c = opp.Referring_Employee__r.Name;
            updateCIMap.put(lastInfluence.Id, lastInfluence);
         } // if (lastInfluence
          
         if (lastInfluence != null && opp.Referral_Contact__c != null && String.isBlank(lastInfluence.ReferralContactId__c)) {
            p_runLog += '\n set referral contact '+opp.Referral_Contact__r.Name;
            lastInfluence.ReferralContactId__c = opp.Referral_Contact__c;
            lastInfluence.ReferralContactName__c = opp.Referral_Contact__r.Name;
            updateCIMap.put(lastInfluence.Id, lastInfluence);
         }
         CampaignInfluence[] cis = ciByOppMap.get(opp.Id);
         if (cis != null) {
            // see how many influence record already exist
            Integer influenceCnt = opp.CampaignInfluences.size();
            System.debug('checkOpportunityInfo opp='+opp.Name+' influenceCnt='+influenceCnt);
            runLog += '\ncheckOpportunityInfo opp='+opp.Name+' influenceCnt='+influenceCnt;
            for (CampaignInfluence ci : cis) {
               
               influenceCnt++;
               ci.OrderOfInfluence__c = influenceCnt;
               runLog += '\ncheckOpportunityInfo set influenceCnt';
               System.debug('checkOpportunityInfo set influenceCnt');
               // not sure about this logic because it will pick up any referring employee on the opportunity
               // and we don't know if it's necessarily the right one.
               if (String.isBlank(ci.ReferringEmployeeId__c) && opp.Referring_Employee__c != null) {
                  ci.ReferringEmployeeId__c = opp.Referring_Employee__c;
                  ci.ReferringEmployeeName__c = opp.Referring_Employee__r.Name;
               }
            }
         } // if (cis != null
         */
      } // for (Opportunity opp
      SKIP_TRIGGER = true;
      DmlHelper.performDML2(updateCIMap.values(), DmlHelper.DML_UPDATE, 'CampaignInfluenceHelper', 'checkInfluenceOnInsertNow', 'Updating Campaign Influence', false);
      if (LOG_DATA) {
         ErrorLog__c errLog = ErrorLog.logError('CampaignInfluenceHelper', 'checkInfluenceOnInsertNow', 'LOG_DATA', null, p_runLog, null, true);
      }
   } // checkInfluenceOnInsertNow
    
   public static Boolean checkOppFields(Opportunity opp, CampaignInfluence ci) { 
      Boolean updated = false;
       if (ci != null && String.isNotBlank(opp.NSS_Source__c) && String.isBlank(ci.NSS_Source__c)) {
          ci.NSS_Source__c = opp.NSS_Source__c;
       }
      if (ci != null && opp.Referring_Employee__c != null && String.isBlank(ci.ReferringEmployeeId__c)) {
         //p_runLog = (String.IsBlank(p_runLog) ? '' : p_runLog) + '\n set referring employee '+opp.Referring_Employee__r.Name;
         StringHelper.addToProcessNotes(ci,'set referring employee '+opp.Referring_Employee__r.Name);
         ci.ReferringEmployeeId__c = opp.Referring_Employee__c;
         ci.ReferringEmployeeName__c = opp.Referring_Employee__r.Name;
         updated = true;
      } // if (lastInfluence
          
      if (ci != null && opp.Referral_Contact__c != null && String.isBlank(ci.ReferralContactId__c)) {
         //p_runLog = (String.IsBlank(p_runLog) ? '' : p_runLog) + '\n set referral contact '+opp.Referral_Contact__r.Name;
         StringHelper.addToProcessNotes(ci,'set referral contact '+opp.Referral_Contact__r.Name);
         ci.ReferralContactId__c = opp.Referral_Contact__c;
         ci.ReferralContactName__c = opp.Referral_Contact__r.Name;
         updated = true;
      }
      return updated;
   } // checkOppFields

/*
   public static void checkOpportunityInfo(Map<Id, CampaignInfluence[]> ciByOppMap) {
      Opportunity[] opps = [Select Id, Name
                                  ,Referring_Employee__c, Referring_Employee__r.Name
                                 ,(Select Id, CampaignId, Influence, RevenueShare
                                         ,CampaignCounter__c, OrderOfInfluence__c 
                                         ,ReferringEmployeeId__c, ReferringEmployeeName__c
                                     From CampaignInfluences)
                              From Opportunity
                             Where Id in :ciByOppMap.keySet()];
      String runLog = '\ncheckOpportunityInfo opps='+opps.size();
      for (Opportunity opp : opps) {
         CampaignInfluence[] cis = ciByOppMap.get(opp.Id);
         if (cis != null) {
            // see how many influence record already exist
            Integer influenceCnt = opp.CampaignInfluences.size();
            System.debug('checkOpportunityInfo opp='+opp.Name+' influenceCnt='+influenceCnt);
            runLog += '\ncheckOpportunityInfo opp='+opp.Name+' influenceCnt='+influenceCnt;
            for (CampaignInfluence ci : cis) {
               
               influenceCnt++;
               ci.OrderOfInfluence__c = influenceCnt;
               runLog += '\ncheckOpportunityInfo set influenceCnt';
               System.debug('checkOpportunityInfo set influenceCnt');
               // not sure about this logic because it will pick up any referring employee on the opportunity
               // and we don't know if it's necessarily the right one.
               if (String.isBlank(ci.ReferringEmployeeId__c) && opp.Referring_Employee__c != null) {
                  ci.ReferringEmployeeId__c = opp.Referring_Employee__c;
                  ci.ReferringEmployeeName__c = opp.Referring_Employee__r.Name;
               }
            }
         } // if (cis != null
      } // for (Opportunity opp
      ErrorLog__c errLog = ErrorLog.logError('CampaignInfluenceHelper', 'checkFromTrigger', 'LOG_DATA', null, runLog, null, true);
   } // checkOpportunityInfo
  */
} // CampaignInfluenceHelper