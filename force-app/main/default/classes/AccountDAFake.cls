@IsTest
public with sharing class AccountDAFake implements AccountDAInterface {
    private Boolean causeException = false;

    public Integer GetAccountByOpportunityCallCount { public get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    

    public AccountDAFake(Boolean causeException) {
        GetAccountByOpportunityCallCount = 0;
        this.causeException = causeException;
    }

    public Account getAccountByOpportunityId(Id opportunityId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetAccountByOpportunityCallCount++;
        return new Account();
    }
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByAccountId(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }    
}