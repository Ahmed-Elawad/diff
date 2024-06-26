public with sharing class ReferralContactWrapper {
    @AuraEnabled public Referral_Contact__c ReferralContact { get; set; }
    @AuraEnabled public List<ActivityDA.ActivityCombined> OpenActivities { get; set; }
    @AuraEnabled public List<Case> OpenCases { get; set; }
    @AuraEnabled public List<Opportunity> OpenOpportunities { get; set; }
    @AuraEnabled public Integer MutualClientCount { get; set; }
    @AuraEnabled public List<Account> MutualClients { get; set; }
    @AuraEnabled public Map<String,Object> refConData;
    @AuraEnabled public Partner_Portal_User_Details__c pPUDData {get;set;}
 
}