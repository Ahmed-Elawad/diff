public with sharing class ReferenceClientRetentionWrapper {
	@AuraEnabled public Reference_Client_Retention__c refClientRet { get; set; }
    @AuraEnabled public List<Reference_Client_Retention__c> openRCRs { get; set; }
    @AuraEnabled public List<Reference_Client_Retention__c> totalRCRs { get; set; }
}