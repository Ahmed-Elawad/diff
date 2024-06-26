public interface ReferralContactDAInterface {
    Referral_Contact__c getReferralContactById(Id referralContactId);
    List<Referral_Contact__c> getReferralContactsByReferralAccount(Id referralAccountId);

}