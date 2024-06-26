public with sharing class CampaignRelatedList {
    @AuraEnabled
	public static List<Campaign> getOpenCampaigns(String recordId) {
	

		List<CampaignMember> cms =[SELECT CampaignId, Campaign.Originator__c, Status 
									FROM CampaignMember 
									WHERE (ContactId =: recordId OR LeadId =: recordId)
										AND Campaign.Originator__c = 'Marketing'];
		Set<Id> campaignIds= new Set<Id>();

		for (CampaignMember  cm : cms){
			campaignIds.add(cm.CampaignId);
		}
		date d = system.today().addDays(-90);
		List<Campaign> campaigns = [SELECT Id, Name FROM Campaign WHERE Id IN:campaignIds AND IsActive=TRUE];
		return campaigns;

    }
}