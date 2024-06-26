public with sharing class LeadWrapper {
    @AuraEnabled public Lead Lead { get; set; }
    @AuraEnabled public List<ActivityDA.ActivityCombined> OpenActivities { get; set; }
    @AuraEnabled public Datetime LastActivityDate { get; set; }
    //@AuraEnabled public List<Case> OpenCases { get; set; }
    //@AuraEnabled public List<Opportunity> OpenOpportunities { get; set; }
    @AuraEnabled public String getSensitivities { get; set; }
    @AuraEnabled public List<Marketing_Insights__c> marketingInsights { get; set; }
    @AuraEnabled public List<Customer_Intent_Signal__c> customerIntentSignals { get; set; }

}