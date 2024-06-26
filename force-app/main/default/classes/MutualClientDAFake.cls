/* Used for testing

 * History
 * -------
  06/23/2021 Dan Carmen          Add getMutualClientFieldsByByReferralContactId method

*/
@IsTest
public with sharing class MutualClientDAFake implements MutualClientDAInterface {
    private Boolean causeException = false;

    public Integer ClientsByContactIdCallCount { get; private set; }
    public Integer ClientsByContactListCallCount { get; private set; }

    public MutualClientDAFake(Boolean causeException) {
        ClientsByContactIdCallCount = 0;
        ClientsByContactListCallCount = 0;

        this.causeException = causeException;
    }

    public Integer getMutualClientsByReferralContactId(Id referralContactId) {
        if (causeException) {
            throw new AuraHandledException('Forced Error');
        }

        ClientsByContactIdCallCount++;
        return 2;
    }

    public Integer getMutualClientsByReferralContacts(List<Referral_Contact__c> referralContacts) {
        if (causeException) {
            throw new AuraHandledException('Forced Error');
        }

        ClientsByContactListCallCount++;
        return 5;
    }
    
    public List<Account> getMutualClientFieldsByByReferralContactId(Id referralContactId) {
       return null;
    }
    public List<Account> getMutualClientFieldsByByReferralContacts(List<Referral_Contact__c> refctcts){
        return null;
    }
} // class MutualClientDAFake