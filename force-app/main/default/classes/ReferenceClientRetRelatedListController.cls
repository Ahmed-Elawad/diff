/* 

  History
  -------
  10/12/2023 Carrie Marciano	created, added code to create banner on Reference Client Retention object

 */

public class ReferenceClientRetRelatedListController {
	@AuraEnabled
	public static DataEnvelope getReferenceClientRetentionForRCRAcctId(String recordId) {

		List<Reference_Client_Retention__c> refClientRets = ObjectBannerQueries.getTotalRCRByRefClientRetAcctId(recordId);

		DataEnvelope envelope = new DataEnvelope(refClientRets);
		return envelope;

	}

    public class DataEnvelope{

		@AuraEnabled
		public List<Reference_Client_Retention__c> refClientRets {get; set;}

		public DataEnvelope(List<Reference_Client_Retention__c> refClientRets){
			this.refClientRets = refClientRets;
		}

	}
}