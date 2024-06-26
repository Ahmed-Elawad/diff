@IsTest
public class ReferralContactDAFake implements ReferralContactDAInterface {
    private Boolean causeException = false;

    public Integer GetReferralContactCallCount { get; private set; }
    public Integer GetReferralContactsCallCount { get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    

    public ReferralContactDAFake(Boolean causeException) {
        GetReferralContactCallCount = 0;
        GetReferralContactsCallCount = 0;
        this.causeException = causeException;
    }

    public Referral_Contact__c getReferralContactById(Id referralContactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetReferralContactCallCount++;
        return new Referral_Contact__c();
    }

    public List<Referral_Contact__c> getReferralContactsByReferralAccount(Id referralAccountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        GetReferralContactsCallCount++;
        return new List<Referral_Contact__c>();
    }
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByReferralContactId(Id referralContactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }      
}