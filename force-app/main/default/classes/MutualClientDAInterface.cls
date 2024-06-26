public interface MutualClientDAInterface {
    Integer getMutualClientsByReferralContactId(Id referralContactId);
    Integer getMutualClientsByReferralContacts(List<Referral_Contact__c> referralContacts);
    List<Account> getMutualClientFieldsByByReferralContactId(Id referralContactId);
    List<Account> getMutualClientFieldsByByReferralContacts(List<Referral_Contact__c> referralContacts);
}