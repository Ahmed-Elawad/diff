/* 
 * Methods for adding opportunity team members, initially or if there isn't a team member and the number of employees changes.
 *
 * History
 * -------
   07/23/2018 Dan Carmen       Created
   12/05/2018 Dan Carmen       Add chatter message
   12/13/2018 Dan Carmen       Add in RecordTypeName as a criteria
   12/17/2018 Dan Carmen       Change to without sharing
   01/29/2019 Carrie Marciano  Add ability to add chattergroup to the chatterpost   
   
 */
public without sharing class OpptyTeamMember implements TriggerInterface2 {
   
   public static String CACHE_KEY='OpptyTeamMemberOpptyTypes';
   
   // the list of types we will be checking - keep as a label so we don't need to do a query
   public static Set<String> OPPTY_TYPES = null;
   
   public static Set<Id> RECORD_TYPE_ID_SET = null;
   
   public class OpptyCheckInfo {
      Set<String> opptyTypeSet = new Set<String>();
      Set<String> recordTypeNameSet = new Set<String>();
      Set<Id> recordTypeIdSet = new Set<Id>();
   } // class OpptyCheckInfo
   
   public static OpptyCheckInfo oppCheckInfo = null;
   
   
   // store in the cache so we don't have to perform this query all of the time or store the values in a separate place.
   public static Set<String> getOpptyTypesToCheck() {
      System.debug('getOpptyTypesToCheck oppCheckInfo already set in variable='+(oppCheckInfo != null));
      if (oppCheckInfo == null) {
         oppCheckInfo = (OpptyCheckInfo)CacheManager.getOrg(CACHE_KEY);
         System.debug('getOpptyTypesToCheck oppCheckInfo found in cache='+(oppCheckInfo != null));
         if (oppCheckInfo == null) {
            oppCheckInfo = new OpptyCheckInfo();
            // retrieve all of the segments with OpportunityTypes__c
            Zip_Segment__c[] segments = [Select Id, Name, OpportunityType__c, OpptyRecordTypeName__c, OpptyTeamMemberName__c
                                           From Zip_Segment__c
                                          Where OpportunityType__c != null
                                            and OpptyTeamMemberName__c != null];
            for (Zip_Segment__c segment: segments) {
               oppCheckInfo.opptyTypeSet.addAll(segment.OpportunityType__c.split(','));
               if (String.isNotBlank(segment.OpptyRecordTypeName__c)) {
                  oppCheckInfo.recordTypeNameSet.add(segment.OpptyRecordTypeName__c);
               }
            } // for (Zip_Segment__c segment
            System.debug('getOpptyTypesToCheck oppCheckInfo opptyTypeSet='+oppCheckInfo.opptyTypeSet+' recordTypeNameSet='+oppCheckInfo.recordTypeNameSet);
            if (!oppCheckInfo.recordTypeNameSet.isEmpty()) {
               Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
               for (String rtName : oppCheckInfo.recordTypeNameSet) {
                  Schema.RecordTypeInfo rtInfo = byNameMap.get(rtName);
                  if (rtName != null) {
                     oppCheckInfo.recordTypeIdSet.add(rtInfo.getRecordTypeId());
                  }
               }
               
            } // if (!oppCheckInfo.recordTypeNameSet.isEmpty
            System.debug('getOpptyTypesToCheck oppCheckInfo opptyTypeSet='+oppCheckInfo.opptyTypeSet);
            System.debug('getOpptyTypesToCheck oppCheckInfo recordTypeNameSet='+oppCheckInfo.recordTypeNameSet);
            System.debug('getOpptyTypesToCheck oppCheckInfo recordTypeIdSet='+oppCheckInfo.recordTypeIdSet);
            
            CacheManager.putOrg(CACHE_KEY, oppCheckInfo);
         }
      } // if (OPPTY_TYPES == null
      return oppCheckInfo.opptyTypeSet;
   } // getOpptyTypesToCheck
    
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      System.debug('OpptyTeamMember.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (isAfter) {
         // so the opp triggers don't fire again
         OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
         Id[] checkForSalesTeamIds = new Id[]{};
         Opportunity[] opps = (Opportunity[])recs;
         Set<String> opptyTypesToCheck = getOpptyTypesToCheck();
         for (Opportunity opp : opps) {
            Opportunity oldOpp = (oldMap != null ? (Opportunity)oldMap.get(opp.Id) : null);
            if (opptyTypesToCheck.contains(opp.OpportunityType__c)
                && oppCheckInfo.recordTypeIdSet.contains(opp.RecordTypeId)
                && opp.Employees_Paid_Per_Payroll__c != null
                && (oldOpp == null || opp.Employees_Paid_Per_Payroll__c != oldOpp.Employees_Paid_Per_Payroll__c)
               ) {
               checkForSalesTeamIds.add(opp.Id);
            }
         } // for (Opportunity opp
         
         System.debug('OpptyTeamMember.triggerCheckAllFirst checkForSalesTeamIds='+checkForSalesTeamIds.size());
         if (!checkForSalesTeamIds.isEmpty()) {
            checkSalesTeam(checkForSalesTeamIds);
         }
      } // if (isAfter
   } // triggerCheckAllFirst

   // check each record individually
   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   
   // for testing purposes, to process the team members now instead of the future context
   public static Boolean TEST_PROCESS_NOW=false;

   public static void checkSalesTeam(Id[] opptyIds) {
      if (!opptyIds.isEmpty()) {
         if (TEST_PROCESS_NOW || System.isFuture() || System.isBatch()) {
            processSalesTeamNow(opptyIds);
         } else {
            processSalesTeamFuture(opptyIds);
         }
      }
   } // checkSalesTeam
   
   @future
   public static void processSalesTeamFuture(Id[] opptyIds) {
      System.debug('processSalesTeamFuture opptyIds='+opptyIds.size());
      processSalesTeamNow(opptyIds);  
   } // processSalesTeamFuture
   
   public static void processSalesTeamNow(Id[] opptyIds) {
      // requery the opportunities to get the team members and zip code of the account
      Opportunity[] opps = [Select Id, Name
                                  ,Employees_Paid_Per_Payroll__c
                                  ,OpportunityType__c
                                  ,RecordTypeId, RecordType.Name
                                  ,Account.Owner_Zip_Code__c
                                  ,(Select Id, OpportunityAccessLevel, OpportunityId, TeamMemberRole, UserId from OpportunityTeamMembers)
                              From Opportunity
                             Where Id in :opptyIds
                               and Account.Owner_Zip_Code__c != null];
      System.debug('processSalesTeamNow opps='+opps.size());
      // collect the zip codes so we can find the zip assignments
      Set<String> zipCodeSet = new Set<String>();
      for (Opportunity opp : opps) {
         zipCodeSet.add(opp.Account.Owner_Zip_Code__c);
         //opp.SE_Auto_Assigned__c=true;
      }
      System.debug('processSalesTeamNow zipCodeSet='+zipCodeSet);
      otmToInsert.clear();
      if (!zipCodeSet.isEmpty()) {
         checkSalesTeams(opps,zipCodeSet);
         DmlHelper.performDML2(otmToInsert, DmlHelper.DML_INSERT, 'OpptyTeamMember', 'processSalesTeamNow', 'Insert New Oppty Team Members', true);
         DmlHelper.performDML2(opps, DmlHelper.DML_UPDATE, 'OpptyTeamMember', 'processSalesTeamNow', 'Insert New Oppty Team Members', true);
         ChatterMentionPost.checkPostFeedElements();
      }
      
   } // processSalesTeamNow
   
   public static OpportunityTeamMember[] otmToInsert = new OpportunityTeamMember[]{};
   
   public static void checkSalesTeams(Opportunity[] opps, Set<String> zipCodeSet) {
      Map<String,Zip_Assignment__c[]> zaMap = getOppZipAssigns(zipCodeSet);
      System.debug('checkSalesTeams zaMap='+zaMap.size());
      for (Opportunity opp : opps) {
         // check if there's already a sales engineer if there is, we'll stop
         OpportunityTeamMember otm = findExistingTeamMember(opp);
         System.debug('checkSalesTeams opp='+opp.Name+' otm='+otm);
         if (otm == null) {
            // create a new one
            Zip_Assignment__c za = findMatchingAssignment(opp, zaMap.get(opp.Account.Owner_Zip_Code__c));
            System.debug('checkSalesTeams za='+za);
            if (za != null) {
               otm = new OpportunityTeamMember(OpportunityId=opp.Id, UserId=za.ZipTerritory__r.TerritoryRep__r.Id, TeamMemberRole=za.Zip_Segment__r.OpptyTeamMemberName__c);
               otmToInsert.add(otm);
               sendChatter(opp, za.ZipTerritory__r.TerritoryRep__r);
               
            }
            
         }
      } // for (Opportunity opp
   } // checkSalesTeams
   
   public static void sendChatter(Opportunity opp, User usrToMention) {
      // right now it's only setup to send a chatter message for Sales Engineers. 
      // if more teams are added in, we'll have to setup a way to send different messages.
      Id[] userIds = new Id[]{};
      userIds.add(usrToMention.Id);
      if (usrToMention.Manager != null && usrToMention.Manager.IsActive) {
         userIds.add(usrToMention.Manager.Id);
      }
       if (usrToMention.DSA_FSS__r != null && usrToMention.DSA_FSS__r.IsActive) {
         userIds.add(usrToMention.DSA_FSS__r.Id);
      }
       if(usrToMention.Sales_Org__c == 'SalesEng'){
           userIds.addAll(Label.OpptyTeamMemberGroupMentions.split(','));
       }
      ChatterMentionPost.createChatterMentionPost(opp.Id, userIds, new String[]{Label.OpptyTeamMember_Notify1}, false, false);
   } // sendChatter
   
   public static OpportunityTeamMember findExistingTeamMember(Opportunity opp) {
      OpportunityTeamMember existingOtm = null;
      for (OpportunityTeamMember otm : opp.OpportunityTeamMembers) {
         if (teamMemberNameSet.contains(otm.TeamMemberRole)) {
            existingOtm = otm;
            break;
         }
      } // for (OpportunityTeamMember
      return existingOtm;
   } // findExistingTeamMember
   
   // find the zip assignment that matches the passed in Opportunity
   public static Zip_Assignment__c findMatchingAssignment(Opportunity opp, Zip_Assignment__c[] zas) {
      Zip_Assignment__c foundZa = null;
      if (zas == null) {
         return foundZa;
      }
      for (Zip_Assignment__c za : zas) {
         Boolean userOkay = za.ZipTerritory__r != null && za.ZipTerritory__r.TerritoryRep__r != null && za.ZipTerritory__r.TerritoryRep__r.IsActive;
         
         // if there's a record type setup on the zip segment, see if this opp is the same type 
         Boolean rtMatch = (String.isBlank(za.Zip_Segment__r.OpptyRecordTypeName__c)
                            || (String.isNotBlank(za.Zip_Segment__r.OpptyRecordTypeName__c) && (za.Zip_Segment__r.OpptyRecordTypeName__c == opp.RecordType.Name)));
         
         // check if the record type of the opportunity matches one of the types in the zip setting
         Boolean opptyTypeMatch = true;
         if (String.isNotBlank(za.Zip_Segment__r.OpportunityType__c)) {
            Set<String> opptyTypeSet = new Set<String>();
            opptyTypeSet.addAll(za.Zip_Segment__r.OpportunityType__c.split(','));
            opptyTypeMatch = opptyTypeSet.contains(opp.OpportunityType__c);
         }
         // if both of these match, check the employee criteria
         if (userOkay && rtMatch && opptyTypeMatch) {
            Integer empCnt = Integer.valueOf(opp.Employees_Paid_Per_Payroll__c);
            if (za.Zip_Segment__r.Emps_Min__c <= empCnt && empCnt <= za.Zip_Segment__r.Emps_Max__c) {
               foundZa = za;
               break;
            }
         } // if (userOkay && rtMatch
      } // for (Zip_Assignment__c za
      return foundZa;
   } // findMatchingAssignment
   
   public static Set<String> teamMemberNameSet = new Set<String>();
   
   public static Map<String,Zip_Assignment__c[]> getOppZipAssigns(Set<String> zipCodeSet) {
       Zip_Assignment__c[] zas = [Select Id, Name
                                       ,ZipTerritory__r.TerritoryRep__r.Id
                                       ,ZipTerritory__r.TerritoryRep__r.IsActive
                                       ,ZipTerritory__r.TerritoryRep__r.Sales_Org__c    
                                       ,ZipTerritory__r.TerritoryRep__r.Manager.Id
                                       ,ZipTerritory__r.TerritoryRep__r.Manager.IsActive
                                       ,ZipTerritory__r.TerritoryRep__r.DSA_FSS__r.Id
                                       ,ZipTerritory__r.TerritoryRep__r.DSA_FSS__r.IsActive
                                       ,Zip_Segment__r.OpportunityType__c
                                       ,Zip_Segment__r.Emps_Min__c
                                       ,Zip_Segment__r.Emps_Max__c
                                       ,Zip_Segment__r.OpptyRecordTypeName__c
                                       ,Zip_Segment__r.OpptyTeamMemberName__c
                                    From Zip_Assignment__c
                                   Where Name in :zipCodeSet
                                     and Zip_Segment__r.OpptyTeamMemberName__c != null];
                                     
      Map<String,Zip_Assignment__c[]> zaMap = new Map<String,Zip_Assignment__c[]>();
      for (Zip_Assignment__c za : zas) {
         // collect the set of team member names to compare against.
         teamMemberNameSet.add(za.Zip_Segment__r.OpptyTeamMemberName__c);
         Zip_Assignment__c[] tempList = (zaMap.containsKey(za.Name) ? zaMap.get(za.Name) : new Zip_Assignment__c[]{});
         tempList.add(za);
         zaMap.put(za.Name, tempList);
      } // for (Zip_Assignment__c za
      
      return zaMap;
   } // getOppZipAssigns
   
} // class OpptyTeamMember