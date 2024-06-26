/* 
 * Actions to take on a cloned opportunity
 *
 * History
 * -------
   06/15/2017 Dan Carmen   Created
   
 *
 */
public with sharing class OpptyChkClone implements TriggerInterface {
    
   public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap) {}

   public void checkBeforeTrigger(SObject newRec, SObject oldRec) {
      // only on an update
      if (oldRec != null) {
         Opportunity opp = (Opportunity)newRec;
         if (opp.CheckIfCloned__c) {
            opp.CheckIfCloned__c = false;
            if (opp.Id != opp.OpportunityId__c) {
               v_oppToParentMap.put(opp.Id, opp.OpportunityId__c);
            }
         } // if (opp.CheckIfCloned__c
      } // if (oldRec != null
      
   } // checkBeforeTrigger
   
   public void processBeforeTriggerActions() {}
   
   public static Map<String,String> v_oppToParentMap = new Map<String,String>();
   
   public void checkAfterTrigger(SObject newRec, SObject oldRec) {
      // only on insert - if the OpportunityId__c is already populated with an id different than the record id, check the original record
      // if there's a referral/partner referral on the original opp, link the new opp to the original record
      if (oldRec == null) {
         Opportunity opp = (Opportunity)newRec;
         if (String.isNotBlank(opp.OpportunityId__c) && (String)opp.Id != opp.OpportunityId__c) {
            v_oppToParentMap.put(opp.Id, opp.OpportunityId__c);
         }
      } // if (oldRec == null
   } // checkAfterTrigger
   
   public void processAfterTriggerActions() {
      if (!v_oppToParentMap.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processParentCheckNow(v_oppToParentMap);
         } else {
            processParentCheckFuture(v_oppToParentMap);
         }
      }
   } // processAfterTriggerActions

   @future
   public static void processParentCheckFuture(Map<String,String> oppToParentMap) {
      processParentCheckNow(oppToParentMap);
   } // processParentCheckFuture

   public static void processParentCheckNow(Map<String,String> oppToParentMap) {
      // Map<String,String[]> can't be a parameter for a future method, so we'll build it here.
      Map<String,String[]> parentOppIdMap = new Map<String,String[]>();
      for (String oppId : oppToParentMap.keySet()) {
         String parentId = oppToParentMap.get(oppId);
         String[] oppIds = (parentOppIdMap.containsKey(parentId) ? parentOppIdMap.get(parentId) : new String[]{});
         oppIds.add(oppId);
         parentOppIdMap.put(parentId, oppIds);
      } // for (String oppId
      
      Map<Id,Opportunity> oppParentMap = new Map<Id,Opportunity>([Select Id, Name
                                  ,ReferralLookup__c
                                  ,ReferralLookup__r.Id
                                  ,ReferralLookup__r.OwnerId
                                  ,ReferralLookup__r.acd_name__c
                                  ,ReferralLookup__r.BypassRelatedOwnerUpdate__c
                                  ,ReferralLookup__r.Campaign__c
                                  ,ReferralLookup__r.PartnerDetail__c
                                  ,ReferralLookup__r.PartnerReferral__c
                                  ,ReferralLookup__r.Referral_Account__c
                                  ,ReferralLookup__r.Referral_Contact__c
                                  ,ReferralLookup__r.Referral_Id__c
                                  ,ReferralLookup__r.Referral_Partner__c
                                  ,ReferralLookup__r.ReferralPartnerName__c
                                  ,ReferralLookup__r.ReferralSourceAccount__c
                                  ,ReferralLookup__r.ReferralSourceContact__c
                                  ,ReferralLookup__r.ReferringAccountParent__c
                                  ,ReferralLookup__r.Referring_User__c
                                  ,ReferralLookup__r.SellingLeadSource__c
                                  ,ReferralLookup__r.SubmitDate__c
                                  ,(Select Id, OwnerId
                                          ,acd_name__c
                                          ,BypassRelatedOwnerUpdate__c
                                          ,Campaign__c
                                          ,PartnerDetail__c
                                          ,PartnerReferral__c
                                          ,Referral_Account__c
                                          ,Referral_Contact__c
                                          ,Referral_Id__c
                                          ,Referral_Partner__c
                                          ,ReferralPartnerName__c
                                          ,ReferralSourceAccount__c
                                          ,ReferralSourceContact__c
                                          ,ReferringAccountParent__c
                                          ,Referring_User__c
                                          ,SellingLeadSource__c
                                          ,SubmitDate__c
                                      From Selling_Opps__r)
                              From Opportunity
                             Where Id in :parentOppIdMap.keySet()]);
      
      Set<String> oppIdsToQuery = new Set<String>();
      Map<Id, Referral__c> oppIdToRefMap = new Map<Id, Referral__c>();
      // see if the opportunities are linked to referrals. Then we'll requery the opps to create a new referral
      for (Opportunity opp : oppParentMap.values()) {
         Referral__c ref = opp.ReferralLookup__r;
         if (ref == null && opp.Selling_Opps__r != null && !opp.Selling_Opps__r.isEmpty()) {
            // we'll assume there's one 
            ref = opp.Selling_Opps__r[0];
         }
         if (ref != null && ref.PartnerReferral__c != null) {
            String[] oppIds = parentOppIdMap.get(((String)opp.Id));
            if (oppIds != null) {
               for (String oppId : oppIds) {
                  oppIdToRefMap.put((Id)oppId, ref);
               } // for (String oppId
            } // if (oppIds != null
         } // if (ref != null
      } // for (Opportunity opp
      
      if (!oppIdToRefMap.isEmpty()) {
         
         OppWrapper[] matchedRecs = new OppWrapper[]{};
         Referral__c[] insertRefs = new Referral__c[]{};
         
         Opportunity[] clonedOpps = [Select Id,Name, AccountId
                                           ,Bank_Lead_ID__c
                                           ,OpportunityId__c
                                           ,ReferralLookup__c
                                           ,ReferralLookup__r.Account__c
                                           ,(Select Id, ContactId, Role From OpportunityContactRoles where IsPrimary=true)
                                       From Opportunity
                                      Where Id in :oppIdToRefMap.keySet()];
         for (Opportunity opp : clonedOpps) {
            // only create a new one if it doesn't already have a referral going to the correct account. 
            // The lookup to the original referral could be coming from the original opportunity.
            if (opp.ReferralLookup__c == null || (opp.ReferralLookup__r != null && opp.ReferralLookup__r.Account__c != opp.AccountId)) {
               Referral__c sourceRef = oppIdToRefMap.get(opp.Id);
               if (sourceRef != null) {
                  OppWrapper wrap = new OppWrapper();
                  wrap.opp = opp;
                  wrap.ref = sourceRef.clone(false,true);
                  wrap.ref.Account__c = opp.AccountId;
                  wrap.ref.SourceContact__c = (!opp.OpportunityContactRoles.isEmpty() ? opp.OpportunityContactRoles[0].ContactId : null);
                  wrap.ref.Selling_Opportunity__c=opp.Id;
                  wrap.ref.BypassRelatedOwnerUpdate__c = true;
                  
                  insertRefs.add(wrap.ref);
                  matchedRecs.add(wrap);
               } // if (sourceRef != null
               
            } // if (opp.ReferralLookup__c == null ||
         } // for (Opportunity opp : clonedOpps
         
         if (!insertRefs.isEmpty()) {
            DmlHelper.performDML2(insertRefs, DmlHelper.DML_INSERT, 'OpptyChkClone', 'processParentCheckNow', 'insert referrals', false);

            Opportunity[] updateOpps = new Opportunity[]{};
            // link the opportunity to the referral
            for (OppWrapper wrapper : matchedRecs) {
               if (wrapper.ref != null && wrapper.ref.Id != null) {
                  wrapper.opp.ReferralLookup__c = wrapper.ref.Id;
                  updateOpps.add(wrapper.opp);
               }
            }

            DmlHelper.performDML2(updateOpps, DmlHelper.DML_UPDATE, 'OpptyChkClone', 'processParentCheckNow', 'update opportunities', false);
            ErrorLog.checkSave();
         }
      } // if (!oppIdsToQuery.isEmpty
   } // processParentCheckNow

   public class OppWrapper {
      public Opportunity opp;
      public Referral__c ref;
   } // class OppWrapper
   
} // class OpptyChkClone