/* Logic to link two opportunities together.
 * 
  Matching criteria. Based on the record type of the opportunity, define which other record types this one would match to. Then, it's a match if the opportunity types match.  
  If one of the opps has EvaluateProductGroup__c set to true, then look at the ProductGroupsSelected__c to see if they match 
  The complication of this.
      HRS Opp is created. EvaluateProductGroup__c is true. Can match to Pay or MMS opp types. 
      Mapping between Product Group and Opportunity Type. New field on the Opp ProductGroupByOpptyType__c to do this mapping. If it's blank there's no mapping.

 * History
 * -------
   05/17/2016 Dan Carmen   Created
   11/15/2017 Dan Carmen   Added to TriggerInterface
   10/19/2021 Dan Carmen   Add matching based on Product Group
      
 */
public without sharing class OpptyCheckJoin implements TriggerInterfaceC {

   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
       if (isAfter && Trigger.isInsert) {
           Id[] oppIds = new Id[]{};
           oppIds.addAll(Trigger.newMap.keySet());
           if (Utilities.allowFuture()) {
              checkOppsFuture(oppIds);
           } else {
              checkOppsNow(oppIds);
           }
       }
   } // handleTrigger

   public static Opportunity[] oppsToCheckForDupes = new Opportunity[]{};

   // for each record type id, map to a set that contain all of the matching ids. This is for easy reference
   // Example, Core Opportunity Record Type would be matched to the ids of both that and the Core Opportunity DSA Record Type
   public static Map<Id, Set<Id>> matchingRTIdSetMap = null; //new Map<Id, Set<Id>>();

   public static String CACHE_KEY='OpptyCheckJoinmatchingRTIdSetMap';
   // So we only retrieve it once per session. 
   public static void checkMatchingRTIdSetMap() {
      if (matchingRTIdSetMap == null) {
         matchingRTIdSetMap = (Map<Id, Set<Id>>)CacheManager.getOrg(CACHE_KEY);
         if (matchingRTIdSetMap == null) {
            matchingRTIdSetMap = new Map<Id, Set<Id>>();
            // map of the record types by Sales Org - this is so we can handle things like core and mms being potential duplicates of each other
            Map<String,String[]> oppRecordTypeNameMap = getOppRecordTypeNameMap();
            // map of the record types by name
            Map<String, Schema.RecordTypeInfo> opptyRtMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
            for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
               Set<Id> recordTypeIdSet = new Set<Id>();
               Set<String> recordTypeNameSet = new Set<String>();
               // each sales org might have 2 record types (rep and dsa)
               checkAddToMap(salesOrg.OpptyRecordTypeName__c, recordTypeIdSet, recordTypeNameSet, opptyRtMap);
               checkAddToMap(salesOrg.OpptyRecordTypeName2__c, recordTypeIdSet, recordTypeNameSet, opptyRtMap);
               // TODO - can we do this instead of checking on the SalesOrg__c custom setting at all?
               if (oppRecordTypeNameMap.containsKey(salesOrg.Name)) {
                  String[] checkRecordTypeNames = oppRecordTypeNameMap.get(salesOrg.Name);
                  for (String recordTypeName : checkRecordTypeNames) {
                     checkAddToMap(recordTypeName, recordTypeIdSet, recordTypeNameSet, opptyRtMap);
                  }
               }
               if (!recordTypeIdSet.isEmpty()) {
                  // add to the map for each record type id.
                  for (Id rtId : recordTypeIdSet) {
                     matchingRTIdSetMap.put(rtId, recordTypeIdSet);
                  }
               } // if (!recordTypeIdSet
            } // for (SalesOrg__c salesOrg

            CacheManager.putOrg(CACHE_KEY,matchingRTIdSetMap);   
         } // if (matchingRTIdSetMap == null
      } // if (matchingRTIdSetMap == null
   } // checkMatchingRTIdSetMap
   
   public static Map<String,String[]> getOppRecordTypeNameMap() {
      Map<String,String[]> oppRecordTypeNameMap = new Map<String,String[]>();
      for (RecordType__c rtSetting : RecordType__c.getAll().values()) {
         if (rtSetting.ObjectName__c == ObjectHelper.OBJECT_OPPTY) {
            addToMap(rtSetting.RecordTypeName__c, rtSetting.Sales_Org__c, oppRecordTypeNameMap);
            addToMap(rtSetting.RecordTypeName__c, rtSetting.SecondarySalesOrg__c, oppRecordTypeNameMap);
         }
      } // for (RecordType__c rtSetting
      return oppRecordTypeNameMap;
   } // getOppRecordTypeNameMap
   
   public static void addToMap(String recordTypeName, String salesOrg, Map<String,String[]> rtMap) {
      if (String.isNotBlank(salesOrg) && String.IsNotBlank(recordTypeName)) {
         String[] rtNames = (rtMap.containsKey(salesOrg) ? rtMap.get(salesOrg) : new String[]{});
         rtNames.add(recordTypeName);
         rtMap.put(salesOrg,rtNames);
      }
   } // addToMap

   public static void checkAddToMap(String recordTypeName, Set<Id> recordTypeIdSet, Set<String> recordTypeNameSet, Map<String, Schema.RecordTypeInfo> rtMap) {
      if (String.isNotBlank(recordTypeName) && !recordTypeNameSet.contains(recordTypeName)) {
         Schema.RecordTypeInfo rt = rtMap.get(recordTypeName);
         if (rt != null) {
            recordTypeIdSet.add(rt.getRecordTypeId());
         }
         recordTypeNameSet.add(recordTypeName);
      } // if (String.isNotBlank(recordTypeName
   } // checkAddToMap
    
   @future
   public static void checkOppsFuture(Id[] oppIds) {
      checkOppsNow(oppIds);
   } // checkOppsFuture
    
   public static void checkOppsNow(Id[] oppIds) {
      Opportunity[] opps = [Select Id, Name, AccountId, OpportunityType__c, RecordTypeId, RecordType.Name
                                  ,AdditionalProductsOfInterest__c, EvaluateProductGroup__c, ProductGroupsSelected__c, ProductGroupByOpptyType__c
                              From Opportunity
                             Where Id in :oppIds];
      checkOpps(opps);
   } // checkOppsNow

   // called from the after insert trigger only - look if other opportunities of the same type already exist.
   public static void checkOpps(Opportunity[] opps) {
      System.debug('checkOpps opps='+opps.size());
      // the ids of the current opportunities
      Id[] oppIds = new Id[]{};
      // map, by account id, of opportunities - to match up later
      Map<Id,Opportunity[]> oppListByAcctIdMap = new Map<Id,Opportunity[]>();
      // all of the record type ids we want to be searching for
      Set<Id> recordTypeIdSet = new Set<Id>();
      // for the opportunity types of the current opps to check against the ProductGroupByOpptyType__c field
      Set<String> oppTypeSet = new Set<String>();
      // for the types in the ProductGroupByOpptyType__c to check against the OpportunityType__c field
      Set<String> oppTypeProdGrpSet = new Set<String>();
      
      //Map<String, Set<Id>> recordTypesBySalesOrgMap = new Map<String, Set<Id>>();
      checkMatchingRTIdSetMap();
      
      for (Opportunity opp : opps) {
         if (opp.AccountId != null) {
            // create a list of opportunities by account id
            Opportunity[] oppList = (oppListByAcctIdMap.containsKey(opp.AccountId) ? oppListByAcctIdMap.get(opp.AccountId) : new Opportunity[]{});
            oppList.add(opp);
            oppListByAcctIdMap.put(opp.AccountId, oppList);
            
            if (String.isNotBlank(opp.OpportunityType__c)) {
               oppTypeSet.add(opp.OpportunityType__c);
            }
            
            if (String.isNotBlank(opp.ProductGroupByOpptyType__c)) {
               oppTypeProdGrpSet.add(opp.ProductGroupByOpptyType__c);
            }

            // collect all of the possible matching record type ids
            if (matchingRTIdSetMap.containsKey(opp.RecordTypeId)) {
               recordTypeIdSet.addAll(matchingRTIdSetMap.get(opp.RecordTypeId));
            }
            
         } // if (opp.AccountId != null
      } // for (Opportunity opp
      System.debug('checkOpps oppListByAcctIdMap='+oppListByAcctIdMap.size()+' recordTypeIdSet='+recordTypeIdSet.size());
      Opportunity[] otherOpps = queryOtherOpps(oppListByAcctIdMap.keySet(), recordTypeIdSet, opps, oppTypeSet, oppTypeProdGrpSet);
      checkOtherOpps(otherOpps, oppListByAcctIdMap);
      
   } // checkOpps

   public static String JOIN_TYPE='Potential Duplicate';

   public static void checkOtherOpps(Opportunity[] otherOpps, Map<Id,Opportunity[]> oppListByAcctIdMap) {
      OpportunityJoin__c[] newJoins = new OpportunityJoin__c[]{};
      
      for (Opportunity otherOpp : otherOpps) {
         Opportunity[] oppList = oppListByAcctIdMap.get(otherOpp.AccountId);
         //Opportunity matchingOpp = findMatchingOpp(otherOpp, oppList);
         OpportunityJoin__c oppJoin = findMatchingOpp(otherOpp, oppList);
         if (oppJoin != null) {
            newJoins.add(oppJoin);
         }
         //if (matchingOpp != null) {
         //   newJoins.add(new OpportunityJoin__c(OpportunityParent__c=otherOpp.Id, OpportunityChild__c=matchingOpp.Id, JoinType__c=JOIN_TYPE));
         //}
      } // for (Opportunity otherOpp
      
      DmlHelper.performDML2(newJoins, DmlHelper.DML_INSERT, 'OpptyCheckJoin', 'checkOtherOpps', 'Insert new Opportunity Joins', true);
   } // checkOtherOpps
    
   // match by record type
   public static String MATCH_RT='Record Type';
   // match by product group
   public static String MATCH_PG='Product Group';

   public static OpportunityJoin__c findMatchingOpp(Opportunity otherOpp, Opportunity[] oppList) {
      //Opportunity matchingOpp = null;
      OpportunityJoin__c oppJoin = new OpportunityJoin__c(OpportunityParent__c=otherOpp.Id, JoinType__c=JOIN_TYPE);
      if (oppList != null && !oppList.isEmpty()) {
         Set<Id> recordTypeIdSet = matchingRTIdSetMap.get(otherOpp.RecordTypeId);
         if (recordTypeIdSet != null) {
            for (Opportunity checkOpp : oppList) {
               System.debug('findMatchingOpp otherOpp='+otherOpp.OpportunityType__c+' checkOpp='+checkOpp.OpportunityType__c);
               // if the record type is within the same "category" - it's assumed to be a "dupe"
               if (recordTypeIdSet.contains(checkOpp.RecordTypeId) && otherOpp.OpportunityType__c == checkOpp.OpportunityType__c) {
                  System.debug('findMatchingOpp match found based on record type checkOpp='+checkOpp.Name);
                  //matchingOpp = checkOpp;
                  oppJoin.OpportunityChild__c = checkOpp.Id;
                  oppJoin.MatchType__c = MATCH_RT;
                  break;
               } // if (recordTypeIdSet.contains
            } // for (Opportunity checkOpp
         } // if (recordTypeIdSet != null
       
         // if we don't find a match based on record type and opp type, look at other criteria
         if (oppJoin.OpportunityChild__c == null) {
            for (Opportunity checkOpp : oppList) {
               // see if we match based on Product Group. Not sure if we should be using EvaluateProductGroup__c in this context
               if ((String.isNotBlank(otherOpp.ProductGroupByOpptyType__c) && String.isNotBlank(checkOpp.ProductGroupsSelected__c) && checkOpp.ProductGroupsSelected__c.contains(otherOpp.ProductGroupByOpptyType__c))
                   || (String.isNotBlank(checkOpp.ProductGroupByOpptyType__c) && String.isNotBlank(otherOpp.ProductGroupsSelected__c) && otherOpp.ProductGroupsSelected__c.contains(checkOpp.ProductGroupByOpptyType__c))) {
                  System.debug('findMatchingOpp match found based on Product Group checkOpp='+checkOpp.Name);
                  //matchingOpp = checkOpp;
                  oppJoin.OpportunityChild__c = checkOpp.Id;
                  oppJoin.MatchType__c = MATCH_PG;
                  break;
               }
            }
         }
      } // if (oppList != null && !oppList.isEmpty
      System.debug('findMatchingOpp otherOpp='+otherOpp.Name+' matchingOpp='+(oppJoin.OpportunityChild__c != null));
      return (oppJoin.OpportunityChild__c != null ? oppJoin : null);
   } // findMatchingOpp
   
   public static Integer NUM_HOURS_TO_CHECK = Integer.valueOf(Label.OppyHoursForDupeCheck);

   public static Opportunity[] queryOtherOpps(Set<Id> acctIdSet, Set<Id> recordTypeIdSet, Opportunity[] opps, Set<String> oppTypeSet, Set<String> oppTypeProdGrpSet) {
      DateTime queryDt = DateTime.now().addHours(-NUM_HOURS_TO_CHECK);
      
      Opportunity[] otherOpps = [Select Id, Name
                                       ,AccountId
                                       ,AdditionalProductsOfInterest__c
                                       ,CloseDate
                                       ,EvaluateProductGroup__c
                                       ,IsClosed
                                       ,IsWon
                                       ,OpportunityType__c
                                       ,Probability
                                       ,ProductGroupByOpptyType__c
                                       ,ProductGroupsSelected__c
                                       ,RecordTypeId
                                   From Opportunity
                                  Where AccountId in :acctIdSet
                                    and CreatedDate >= :queryDt
                                    and (RecordTypeId in :recordTypeIdSet or OpportunityType__c in :oppTypeProdGrpSet or ProductGroupByOpptyType__c in :oppTypeSet)
                                    and Id not in :opps];
      System.debug('queryOtherOpps otherOpps='+otherOpps.size()+' acctIdSet='+acctIdSet.size()+' recordTypeIdSet='+recordTypeIdSet.size()+' today='+DateTime.now()+' queryDt='+queryDt);
      return otherOpps;
   } // queryOtherOpps
   
} // class OpptyCheckJoin