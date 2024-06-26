/* 
 History
--------------
06/18/2019 Dan Carmen      Clean up code and increment API 

*/ 
public with sharing class QuotePrimaryContactAssigner {
    public QuotePrimaryContactAssigner(){}
/*
    public static void setPrimaryContact(List<SBQQ__Quote__c> newQuotes){

        //find primary contact on opportunity and add it to the SBQQ Quote
        Set<id> quoteIdsToUpdate = new set<id>();
        Map<Id, Opportunity> oppMap = getOpportunityMap(newQuotes);

        if(!oppMap.isEmpty()){
            setQuotePrimaryContacts(newQuotes, oppMap);
        }
    } // setPrimaryContact


    private static Map<Id, Opportunity> getOpportunityMap(List<SBQQ__Quote__c> newQuotes){
       Set<Id> oppIdSet = new Set<Id>();
       for (SBQQ__Quote__c q : newQuotes) {
         if(q.SBQQ__Opportunity2__c != null && q.SBQQ__PrimaryContact__c == null) {
            oppIdSet.add(q.SBQQ__Opportunity2__c);
         }
       }
       Map<Id,Opportunity> oppMap = null;
       if (oppIdSet.isEmpty()) {
          oppMap = new Map<Id,Opportunity>();
       } else {
          oppMap = new Map<Id, Opportunity>([
                           SELECT Id, Name, (SELECT Id, ContactId, OpportunityId FROM OpportunityContactRoles WHERE IsPrimary = true)
                             FROM Opportunity
                            WHERE Id IN :oppIdSet
                           ]);
       }
      return oppMap;
    } // getOpportunityMap

    private static void setQuotePrimaryContacts(List<SBQQ__Quote__c> newQuotes, Map<Id, Opportunity> oppMap){
        for (SBQQ__Quote__c q : newQuotes){
            if (q.SBQQ__PrimaryContact__c == null) {
                
                Opportunity opp = oppMap.get(q.SBQQ__Opportunity2__c);
                if(opp != null && opp.OpportunityContactRoles.size() > 0){
                    q.SBQQ__PrimaryContact__c = opp.OpportunityContactRoles[0].ContactId;
                }

            }   
        } // for (SBQQ__Quote__c q
    } // setQuotePrimaryContacts
*/
} // class QuotePrimaryContactAssigner