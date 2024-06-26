@IsTest
public with sharing class LeadDAFake implements LeadDAInterface {
    private Boolean causeException = false;

    public Integer GetLeadCallCount { get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    

    public LeadDAFake(Boolean causeException) {
        GetLeadCallCount = 0;
        this.causeException = causeException;
    }
   
    public Lead getLeadById(Id leadId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetLeadCallCount++;
        return new Lead();
    }

   public List<ActivityDA.ActivityCombined> getOpenActivitiesByLeadId(Id leadId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }          
    public string getSensitivities (Id leadID){
        if (causeException){
        	throw new AuraHandledException('Error');
        }//if 
        string rValue = '';
        return rValue;
        
    }//getSensitivities
}