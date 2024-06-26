public with sharing class MutualClientRelatedListController {
	@AuraEnabled
	public static DataEnvelope getMutualClientsForReferralContact(String recordId) {

		MutualClientDA da = new MutualClientDA();
		List<Account> mutualClients = da.getMutualClientFieldsByByReferralContactId(recordId);

		DataEnvelope envelope = new DataEnvelope(mutualClients);
		return envelope;

	}
	@AuraEnabled
	public static DataEnvelope getMutualClientsForReferralAccount(String recordId) {

		MutualClientDA da = new MutualClientDA();
		List<Referral_Contact__c> referralContacts = ObjectBannerQueries.getReferralContactsByReferralAccount(recordId);
		List<Account> mutualClients = da.getMutualClientFieldsByByReferralContacts(referralContacts);

		DataEnvelope envelope = new DataEnvelope(mutualClients);
		return envelope;

	}

	public class DataEnvelope{

		@AuraEnabled
		public List<Account> mutualClients {get; set;}

		public DataEnvelope(List<Account> mutualClients){
			this.mutualClients = mutualClients;
		}

	}
}