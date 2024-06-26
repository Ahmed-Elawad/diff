/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code

 */
@IsTest
public class ActivityDAFake {
    
    public class TestActivity implements ActivityDAInterface{
        
    }
    
    static testMethod void runTest() {
        TestActivity testAct = new TestActivity();
    }
    
    /*
    private Boolean causeException = false;

    public Integer OpenActivitiesCallCount { get; private set; }
    public Integer InitialPresentationEventsCallCount { get; private set; }
    public Integer ContactRolesCallCount { get; private set; }

    public ActivityDAFake(Boolean causeException) {
        OpenActivitiesCallCount = 0;
        InitialPresentationEventsCallCount = 0;
        ContactRolesCallCount = 0;
        this.causeException = causeException;
    }

    public List<ActivityDA.ActivityCombined> getOpenActivitiesByContactId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }

    public List<ActivityDA.ActivityCombined> getOpenActivitiesByAccountId(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }
    
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByLeadId(Id leadId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }

    public List<ActivityDA.ActivityCombined> getOpenActivitiesByOpportunityId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }
    
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByReferralContactId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByReferralAccountId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }
    

    public List<Event> getInitialPresentationEventsByOpportunityId(Id opportunityId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        InitialPresentationEventsCallCount++;
        return new List<Event>();
    }

    public List<OpportunityContactRole> getContactRolesByOpportunityId(Id opportunityId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        ContactRolesCallCount++;
        return new List<OpportunityContactRole>();
    }
    
    public List<Event> getEventsByRelatedId(Id leadId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<Event>();
    }
    
    public List<Task> getTasksByRelatedId(Id leadId) {
    	if (causeException) {
        	throw new AuraHandledException('Error');
    	}
    	OpenActivitiesCallCount++;
    	return new List<Task>();
	}
     */
}