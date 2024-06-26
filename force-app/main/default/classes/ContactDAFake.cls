@IsTest
public with sharing class ContactDAFake implements ContactDAInterface {
    private Boolean causeException = false;

    public Integer DNCContactsCallCount { get; private set; }
    public Integer EmailOptOutContactsCallCount { get; private set; }
    public Integer OpenActivitiesCallCount { get; private set; }
    public Integer AllContactsForAccount { get; private set; }


    public ContactDAFake(Boolean causeException) {
        this.causeException = causeException;

        DNCContactsCallCount = 0;
        EmailOptOutContactsCallCount = 0;
        AllContactsForAccount = 0;
    }

    public List<Contact> getContactsByHRPersonId(List<Id> hrPersonIds) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        return new List<Contact>();
    }
    //Added getAllContactsForAccount as part of APR0133627
     public List<Contact> getAllContactsForAccount(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }

        AllContactsForAccount++;
        return new List<Contact>();
    }
    
    public List<Contact> getDoNotCallContactsForAccount(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }

        DNCContactsCallCount++;
        return new List<Contact>();
    }
    
    public List<Contact> getMarketingOwnedContact(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        
        return new List<Contact>();
    }

    public List<Contact> getEmailOptOutContactsForAccount(Id accountId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }

        EmailOptOutContactsCallCount++;
        return new List<Contact>();
    }
  
    public List<ActivityDA.ActivityCombined> getOpenActivitiesByContactId(Id contactId) {
        if (causeException) {
            throw new AuraHandledException('Error');
        }
        OpenActivitiesCallCount++;
        return new List<ActivityDA.ActivityCombined>();
    }    
}