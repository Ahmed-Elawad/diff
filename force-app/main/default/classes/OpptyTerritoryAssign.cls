/* Manage Opportunity territory assignment

  History
  -------
  11/28/2023 Dan Carmen        Created
  
 */
global without sharing class OpptyTerritoryAssign implements TerritoryMgmt.OpportunityTerritory2AssignmentFilter, TriggerInterfaceC {

    global OpptyTerritoryAssign() {}
    
    public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        SObject[] recs = TriggerMethods.checkRecs('OpptyTerritoryAssign', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
        System.debug('OpptyTerritoryAssign.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
        if (recs == null || recs.isEmpty()) {
            System.debug('OpptyTerritoryAssign.handleTrigger - trigger ran');
            return;
        }
       if (isBefore) {
          handleOppsBeforeFromTrigger((Opportunity[])recs, (Map<Id,Opportunity>)oldMap);
       }
    } // handleTrigger
    
    // If we only want to evaluate opps when the EvaluateTerritory__c checkbox is set
    // this is so SF can do it's management, and then only hit this trigger if we manually trigger it.
    public static Boolean onlyEvalCheckbox=(Label.OpptyTerritoryAssign_OnlyEvalCheckbox == 'Y');
    
    public void handleOppsBeforeFromTrigger(Opportunity[] opps, Map<Id,Opportunity> oldMap) {
       Id[] terrUserIds = new Id[]{};
       Opportunity[] terrOpps = new Opportunity[]{};
       for (Opportunity opp : opps) {
          Opportunity oldOpp = (oldMap != null ? oldMap.get(opp.Id) : null);
          if (opp.OwnerId != null && ((!onlyEvalCheckbox && oldOpp == null && opp.Territory2Id == null ) || opp.EvaluateTerritory__c)) {
             opp.EvaluateTerritory__c = false;
             terrUserIds.add(opp.OwnerId);
             terrOpps.add(opp);
          }
       } // for (Opportunity opp : opps
       System.debug('handleOppsBeforeFromTrigger terrUserIds='+terrUserIds.size()+' terrOpps='+terrOpps.size());
       if (!terrUserIds.isEmpty() && !terrOpps.isEmpty()) {
          evaluateOpps(terrUserIds, terrOpps); 
       }
    } // handleOppsBeforeFromTrigger
    
    public static void evaluateOpps(Id[] userIds, Opportunity[] opps) {
       Map<Id,User> userMap = new Map<Id,User>([Select Id, ManagerId, DSA_FSS__c
                         From User
                        Where Id in :userIds]);
       for (User usr : userMap.values()) {
          if (usr.ManagerId != null) {
             userIds.add(usr.ManagerId);
          }
          if (usr.DSA_FSS__c != null) {
             userIds.add(usr.DSA_FSS__c);
          }
       }
       Map<Id,Id> userTerritoryMap = new OpptyTerritoryAssign().getUserTerritories(userIds);
       for (Opportunity opp : opps) {
          User usr = userMap.get(opp.OwnerId);
          if (usr != null) {
             if (userTerritoryMap.containsKey(usr.Id)) {
                opp.Territory2Id =  userTerritoryMap.get(usr.Id);
             } else if (usr.ManagerId != null && userTerritoryMap.containsKey(usr.ManagerId)) {
                opp.Territory2Id =  userTerritoryMap.get(usr.ManagerId);
             } else if (usr.DSA_FSS__c != null && userTerritoryMap.containsKey(usr.DSA_FSS__c)) {
                opp.Territory2Id =  userTerritoryMap.get(usr.DSA_FSS__c);
             }
          } // if (usr != null
       } // for (Opportunity opp : opps
    } // evaluateOpps

      // Get mapping of opportunity to territory2Id. The incoming list of opportunityIds contains only those with IsExcludedFromTerritory2Filter=false.
      // If territory2Id = null in result map, clear the opportunity.territory2Id if set.
      // If opportunity is not present in result map, its territory2Id remains intact.
    global Map<Id,Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) { 
       Map<Id, Id> oppTerrResultMap = new Map<Id, Id>();
       Opportunity[] opps = [Select Id, AccountId, OwnerId, Owner.IsActive, Owner.ManagerId, Owner.Manager.IsActive
                                   ,Owner.DSA_FSS__c,Owner.DSA_FSS__r.IsActive
                               From Opportunity
                              Where Id in :opportunityIds];
       Id[] userIds = new Id[]{};
       for (Opportunity opp : opps) {
          userIds.add(opp.OwnerId);
          // if we can't find a territory for the rep, try to find one for the manager.
          if (opp.Owner.ManagerId != null) {
             userIds.add(opp.Owner.ManagerId);
          }
          if (opp.Owner.DSA_FSS__c != null) {
             userIds.add(opp.Owner.DSA_FSS__c);
          }
       } // for (Opportunity opp
       Map<Id,Id> userTerritoryMap = getUserTerritories(userIds);
       for (Opportunity opp : opps) {
          if (opp.OwnerId != null && opp.Owner.IsActive && userTerritoryMap.containsKey(opp.OwnerId)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.OwnerId));
          } else if (opp.Owner.ManagerId != null && opp.Owner.Manager.IsActive && userTerritoryMap.containsKey(opp.Owner.ManagerId)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.Owner.ManagerId));
          } else if (opp.Owner.DSA_FSS__c != null && opp.Owner.DSA_FSS__r.IsActive && userTerritoryMap.containsKey(opp.Owner.DSA_FSS__c)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.Owner.DSA_FSS__c));
          } else {
             oppTerrResultMap.put(opp.Id, null);
          }
       }
       // activeModelId = getActiveModelId();
       return oppTerrResultMap;
    } // getOpportunityTerritory2Assignments
    
    /*
    global Map<Id,Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) { 
       Map<Id, Id> oppTerrResultMap = new Map<Id, Id>();
       Opportunity[] opps = [Select Id, AccountId, OwnerId, Owner.ManagerId
                                   ,Owner.DSA_FSS__c
                               From Opportunity
                              Where Id in :opportunityIds];
       Id[] userIds = new Id[]{};
       for (Opportunity opp : opps) {
          userIds.add(opp.OwnerId);
          // if we can't find a territory for the rep, try to find one for the manager.
          if (opp.Owner.ManagerId != null) {
             userIds.add(opp.Owner.ManagerId);
          }
          if (opp.Owner.DSA_FSS__c != null) {
             userIds.add(opp.Owner.DSA_FSS__c);
          }
       } // for (Opportunity opp
       Map<Id,Id> userTerritoryMap = getUserTerritories(userIds);
       for (Opportunity opp : opps) {
          if (opp.OwnerId != null && userTerritoryMap.containsKey(opp.OwnerId)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.OwnerId));
          } else if (opp.Owner.ManagerId != null && userTerritoryMap.containsKey(opp.Owner.ManagerId)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.Owner.ManagerId));
          } else if (opp.Owner.DSA_FSS__c != null && userTerritoryMap.containsKey(opp.Owner.DSA_FSS__c)) {
             oppTerrResultMap.put(opp.Id, userTerritoryMap.get(opp.Owner.DSA_FSS__c));
          } else {
             oppTerrResultMap.put(opp.Id, null);
          }
       }
       // activeModelId = getActiveModelId();
       return oppTerrResultMap;
    } // getOpportunityTerritory2Assignments
    */
    // for testing purposes
    public static String TERR_STATE = 'Active';
    
    public Map<Id,Id> getUserTerritories(Id[] userIds) {
       UserTerritory2Association[] utas = [Select Id, RoleInTerritory2, Territory2Id, UserId
                                                 ,Territory2.Id, Territory2.Territory2Type.Priority
                                             From UserTerritory2Association
                                            Where UserId in :userIds
                                              and Territory2.EndDate__c = null
                                              and Territory2.Territory2Model.State = :TERR_STATE];
       Map<Id,TerritoryWrap> userTerrMap = new Map<Id,TerritoryWrap>();
       for (UserTerritory2Association uta : utas) {
          TerritoryWrap tw = (userTerrMap.containsKey(uta.UserId) ? userTerrMap.get(uta.UserId) : new TerritoryWrap());
          if (uta.Territory2.Territory2Type.Priority > tw.priority) {
             tw.territoryId = uta.Territory2Id;
             tw.priority = Integer.valueOf(uta.Territory2.Territory2Type.Priority);
             userTerrMap.put(uta.UserId,tw);
          }
       }
       Map<Id,Id> userTerritoryMap = new Map<Id,Id>();
       for (Id userId : userTerrMap.keySet()) {
          TerritoryWrap tw = userTerrMap.get(userId);
          userTerritoryMap.put(userId,tw.territoryId);
       }
       return userTerritoryMap;
    } // getUserTerritories
    
    public class TerritoryWrap {
       public Id territoryId;
       public Integer priority=-1;
    } // class TerritoryWrap
    
    /*
    private Id getActiveModelId() {
        List<Territory2Model> models = [Select Id from Territory2Model where State = 'Active'];
        Id activeModelId = (models.size() == 1 ? models.get(0).Id : null);
        return activeModelId;
    } // getActiveModelId
    */
} // class OpptyTerritoryAssign