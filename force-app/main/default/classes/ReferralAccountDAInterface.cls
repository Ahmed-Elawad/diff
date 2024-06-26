public interface ReferralAccountDAInterface {
    Referral_Account__c getReferralAccountById(Id referralAccountId);
	String getSensitivities(Id referralAccountId); 
}