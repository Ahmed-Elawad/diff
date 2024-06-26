@IsTest
public with sharing class ReferralAccountDAFake implements ReferralAccountDAInterface {
    private Boolean causeException = false;

    public Integer GetReferralAccountCallCount { get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    

    public ReferralAccountDAFake(Boolean causeException) {
        GetReferralAccountCallCount = 0;
        this.causeException = causeException;
    }

    public Referral_Account__c getReferralAccountById(Id referralAccountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetReferralAccountCallCount++;
        return new Referral_Account__c();
    }
   public List<ActivityDA.ActivityCombined> getOpenActivitiesByReferralAccountId(Id referralAccountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }          
    public string getSensitivities (Id referralAccountID){
        if (causeException){
        	throw new AuraHandledException('Error');
        }//if 
        string rValue = '';
        return rValue;
        
    }//getSensitivities
}