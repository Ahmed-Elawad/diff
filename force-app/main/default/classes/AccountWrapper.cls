public with sharing class AccountWrapper {
    @AuraEnabled public List<Opportunity> OpenOpportunities { get; set; }
    @AuraEnabled public List<ActivityDA.ActivityCombined> OpenActivities { get; set; }
    @AuraEnabled public List<Case> OpenCases { get; set; }
   //Added AllContacts to fetch the contacts of an Account -APR0133627
    @AuraEnabled public List<Contact> AllContacts { get; set; }
    @AuraEnabled public List<Contact> DNCContacts { get; set; }
    @AuraEnabled public List<Contact> EmailOptOutContacts { get; set; }
    @AuraEnabled public List<Contact> MarketingOwnedContact { get; set; }
    @AuraEnabled public List<Marketing_Insights__c> marketingInsights { get; set; }
    @AuraEnabled public List<Customer_Intent_Signal__c> customerIntentSignals { get; set; }
}