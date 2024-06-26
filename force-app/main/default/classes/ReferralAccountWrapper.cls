public with sharing class ReferralAccountWrapper {
    @AuraEnabled public Referral_Account__c ReferralAccount { get; set; }
    @AuraEnabled public List<Referral_Contact__c> RelatedReferralContacts { get; set; }
    @AuraEnabled public List<ActivityDA.ActivityCombined> OpenActivities { get; set; }
    @AuraEnabled public List<Case> OpenCases { get; set; }
    @AuraEnabled public List<Opportunity> OpenOpportunities { get; set; }
    @AuraEnabled public Integer MutualClientCount { get; set; }
    @AuraEnabled public string getSensitivities {get; set; }
}