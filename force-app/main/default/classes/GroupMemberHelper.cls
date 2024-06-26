/* 
 * Methods for working with the Group Member (Assignment_Groups__c) object
 *
 * History
 * -------
   07/19/2019 Dan Carmen        Created.
   10/21/2022 Dan Carmen        Add getActiveUserIds method
 
 */
public with sharing class GroupMemberHelper {

   // for testing purposes
   public static Boolean SKIP_FUTURE=false;

   public static void checkFromTrigger(Assignment_Groups__c[] recs, Map<Id,Assignment_Groups__c> oldMap) {
      Set<Id> groupIdsToCheckSet = new Set<Id>();
      if (Trigger.IsDelete) {
         // collect the ids from the old map
         for (Assignment_Groups__c ag : oldMap.values()) {
            if (ag.Group_Name__c != null) {
               groupIdsToCheckSet.add(ag.Group_Name__c);
            }
         } // for (Assignment_Groups__c ag : oldMap.values
      } else if (Trigger.IsUndelete || Trigger.isInsert) {
         for (Assignment_Groups__c ag : recs) {
            if (ag.Group_Name__c != null) {
               groupIdsToCheckSet.add(ag.Group_Name__c);
            }
         } // for (Assignment_Groups__c ag : recs
      } else if (Trigger.isUpdate) {
         for (Assignment_Groups__c ag : recs) {
            Assignment_Groups__c oldAg = (oldMap.get(ag.Id));
            // if the active field changes, recalculate
            if ((ag.Active__c != oldAg.Active__c) && (ag.Group_Name__c != null)) {
               groupIdsToCheckSet.add(ag.Group_Name__c);
            }
         } // for (Assignment_Groups__c ag : recs
         
      }
      
      System.debug('checkFromTrigger recs='+(recs != null ? recs.size() : -1)+' groupIdsToCheckSet='+groupIdsToCheckSet.size());
      if (!groupIdsToCheckSet.isEmpty()) {
         if (SKIP_FUTURE || System.isFuture() || System.isBatch()) {
            checkGroupsNow(groupIdsToCheckSet);
         } else {
            checkGroupsFuture(groupIdsToCheckSet);
         }
      }
   } // checkFromTrigger
   
   public static void checkGroupsFuture(Set<Id> groupIdsToCheckSet) {
      checkGroupsNow(groupIdsToCheckSet);
   } // checkGroupsFuture
   
   public static void checkGroupsNow(Set<Id> groupIdsToCheckSet) {
      Map<Id,Assignment_Group_Name__c> updateMap = new Map<Id,Assignment_Group_Name__c>();

      Map<Id,Assignment_Group_Name__c> groupMap = new Map<Id,Assignment_Group_Name__c>([Select Id, ActiveUsers__c, TotalUsers__c from Assignment_Group_Name__c where Id in :groupIdsToCheckSet]);
      // recalculate the number of group members in an assignment group
      AggregateResult[] activeResults = [Select count(id) nbrRecs, Group_Name__c
                                     From Assignment_Groups__c
                                    Where Group_Name__c in :groupIdsToCheckSet
                                      and Active__c='True'
                                    group by Group_Name__c];
                                    
      checkResults(groupMap, updateMap, activeResults, 'ActiveUsers__c');

      AggregateResult[] totalResults = [Select count(id) nbrRecs, Group_Name__c
                                     From Assignment_Groups__c
                                    Where Group_Name__c in :groupIdsToCheckSet
                                    group by Group_Name__c];
      checkResults(groupMap, updateMap, totalResults, 'TotalUsers__c');
      
      System.debug('checkGroupsNow updateMap='+updateMap.size());
      
      if (!updateMap.isEmpty()) {
         DmlHelper.performDML2(updateMap.values(), DmlHelper.DML_UPDATE, 'GroupMemberHelper', 'checkGroupsNow', 'Update Assignment_Groups__c records', true);
      }
   } // checkGroupsNow
   
   public static void checkResults(Map<Id,Assignment_Group_Name__c> groupMap, Map<Id,Assignment_Group_Name__c> updateMap
                                   ,AggregateResult[] results, String grpFldName) {
      Set<Id> groupsNotUpdatedSet = new Set<Id>();
      groupsNotUpdatedSet.addAll(groupMap.keySet());

      System.debug('checkResults grpFldName='+grpFldName+' groupMap='+groupMap.size()+' results='+results.size());
      for (AggregateResult result : results) {
         Id grpId = (Id)result.get('Group_Name__c');
         groupsNotUpdatedSet.remove(grpId);
         Assignment_Group_Name__c grp = groupMap.get(grpId);
         Integer cnt = (Integer)result.get('nbrRecs');
         Integer grpCnt = Integer.valueOf((Decimal)grp.get(grpFldName));
         if (grp != null && cnt != grpCnt) {
            grp.put(grpFldName,cnt);
            updateMap.put(grp.Id, grp);
         }
      } // for (AggregrateResult result
      
      System.debug('checkResults updateMap='+updateMap.size()+' groupsNotUpdatedSet='+groupsNotUpdatedSet.size());
      // if nothing came back in the aggregate query, make sure the value gets updated to zero
      for (Id grpId : groupsNotUpdatedSet) {
         Assignment_Group_Name__c grp = groupMap.get(grpId);
         Integer grpCnt = Integer.valueOf((Decimal)grp.get(grpFldName));
         if (grp != null && grpCnt != 0) {
            grp.put(grpFldName,0);
            updateMap.put(grp.Id, grp);
         }
      } // for (Id grpId : groupsNotUpdatedSet

   } // checkResults
    
   public static Boolean USE_CACHE=(Label.GroupMemberHelper_UseCache == 'Y');
   
   public static Set<Id> getActiveUserIds(Id queueId) {
       String cacheKey = 'getActiveUserIds'+queueId+' USE_CACHE='+USE_CACHE;
       Set<Id> queueMemberSet = (USE_CACHE ? (Set<Id>)CacheManager.getOrg(cacheKey) : null);
       System.debug('getActiveUserIds queueMemberSet='+(queueMemberSet != null));
       if (queueMemberSet == null && queueId != null) {
          queueMemberSet = new Set<Id>();
          Assignment_Group_Queues__c[] agqs = [Select Id, QueueId__c, Assignment_Group_Name__c 
                                              from Assignment_Group_Queues__c
                                          where QueueId__c = :queueId
                                            and Active__c = 'true'];
         System.debug('getActiveUserIds agqs='+agqs.size());
         // should only be one, but what do we do if there is none or more than one?
         // right now just assuming one
         if (!agqs.isEmpty()) {
            Assignment_Groups__c[] groupMembers = [Select Id, User__c,Group_Name__c,Active__c from Assignment_Groups__c Where Active__c='True' and Group_Name__c = :agqs[0].Assignment_Group_Name__c];
            System.debug('getActiveUserIds groupMembers='+groupMembers.size());
            for (Assignment_Groups__c groupMember : groupMembers) {
               queueMemberSet.add(groupMember.User__c);
            }

         } // if (!agqs.isEmpty
         if (USE_CACHE) {
            CacheManager.putOrg(cacheKey,queueMemberSet);
         }
      } // if (queueMemberSet == null
      return queueMemberSet;
   } // getActiveUserIds
   
} // class GroupMemberHelper