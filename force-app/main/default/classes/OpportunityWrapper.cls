public with sharing class OpportunityWrapper {
    @AuraEnabled public Account StrategicAccount { get; set; }
    @AuraEnabled public List<Event> RelatedEvents { get; set; }
    @AuraEnabled public List<ActivityDA.ActivityCombined> OpenActivities { get; set; }
    @AuraEnabled public List<OpportunityContactRole> ContactRoles { get; set; }
    @AuraEnabled public User UserInformation { get; set; }
    @AuraEnabled public User portalUsers{ get; set; }
    @AuraEnabled public Opportunity opp{ get; set; }

    public User setUserInformation(){
        Id userId = UserInfo.getUserId();
        User u = [SELECT Id, Name, CallCenterId FROM User WHERE Id = :userId LIMIT 1];
        UserInformation = u;
        return u;
    }
}