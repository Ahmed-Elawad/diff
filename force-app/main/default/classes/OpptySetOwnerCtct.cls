/* 
 * Set the owner contact field on the opportunity
 *
 * History
 * -------
   01/29/2019 Dan Carmen       Created
   
 */
public with sharing class OpptySetOwnerCtct implements TriggerInterface2 {

   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
      System.debug('OpptySetOwnerCtct.triggerCheckAllFirst recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter);
      if (isBefore) {
         
         Opportunity[] opps = (Opportunity[])recs;
         Map<Id,Opportunity> oldOppMap = (Map<Id,Opportunity>)oldMap;
         Map<Id,Opportunity[]> oppOwnerIdMap = new Map<Id,Opportunity[]>();
         
         for (Opportunity opp : opps) {
            Opportunity oldOpp = (oldOppMap != null ? oldOppMap.get(opp.Id) : null);
            if (opp.OwnerId != null && (opp.OwnerContact__c == null || oldOpp == null || (oldOpp != null && opp.OwnerId != oldOpp.OwnerId))) {
               Opportunity[] ownerOpps = (oppOwnerIdMap.containsKey(opp.OwnerId) ? oppOwnerIdMap.get(opp.OwnerId) : new Opportunity[]{});
               ownerOpps.add(opp);
               oppOwnerIdMap.put(opp.OwnerId, ownerOpps);
            }
         } // for (Opportunity opp : opps
         System.debug('triggerCheckAllFirst oppOwnerIdMap='+oppOwnerIdMap.size());
         if (!oppOwnerIdMap.isEmpty()) {
            checkForContacts(oppOwnerIdMap);
         }
      } // if (isAfter
   } // triggerCheckAllFirst

   // check each record individually
   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   
   // see if there are any actions that need to take place at the end of the trigger.
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}
   

   public void checkForContacts(Map<Id,Opportunity[]> oppOwnerIdMap) {
      Contact[] ctcts = [Select Id, Name, User_Lookup__c from Contact where HR_Person_Id__c != null and User_Lookup__c in :oppOwnerIdMap.keySet()];
      System.debug('checkForContacts ctcts='+ctcts.size());
      for (Contact ctct : ctcts) {
         Opportunity[] opps = oppOwnerIdMap.get(ctct.User_Lookup__c);
         if (opps != null) {
            for (Opportunity opp : opps) {
               opp.OwnerContact__c = ctct.Id;
            } // for (Opportunity opp
         } // if (opps != null
      } // for (Contact ctct
   } // checkForContacts
   
} // class OpptySetOwnerCtct