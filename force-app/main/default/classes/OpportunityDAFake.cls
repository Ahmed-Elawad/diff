@IsTest
public class OpportunityDAFake implements OpportunityDAInterface {
    private Boolean causeException = false;

    public Integer OpenOpportunitiesCallCount { get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    

    public OpportunityDAFake(Boolean causeException) {
        OpenOpportunitiesCallCount = 0;
        this.causeException = causeException;
    }

    public List<Opportunity> getOpenOpportunitiesByContactId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenOpportunitiesCallCount++;
        return new List<Opportunity>();
    }

    public List<Opportunity> getOpenOpportunitiesByAccountId(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenOpportunitiesCallCount++;
        return new List<Opportunity>();
    }

    public List<Opportunity> getOpenOpportunitiesByReferralAccountId(Id referralAccountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenOpportunitiesCallCount++;
        return new List<Opportunity>();
    }

    public List<Opportunity> getOpenOpportunitiesByReferralContactId(Id referralContactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenOpportunitiesCallCount++;
        return new List<Opportunity>();
    }

    public List<Opportunity> getOpportunityById(Id oppId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenOpportunitiesCallCount++;
        return new List<Opportunity>();
    }
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByOpportunityId(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }  
    public User getPortalUsersByOpportunityId(Id accountId){
         if (causeException) {
            throw new AuraHandledException('Error');
        }
        user ur = new user();
        return ur;
    }
    public Opportunity getOpportunityInfo(Id opportunityId){
         if (causeException) {
            throw new AuraHandledException('Error');
        }
        Opportunity opp = new Opportunity();
        return opp;
    } 
}