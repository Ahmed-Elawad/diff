/*
 * History
 * --------
 * 01/27/2016  Lynn Michels  created
 *
 */
public with sharing class caseChatterPost {

	public static void collectInfoForChatterPost(list<Id> caseIds)
	{
		//need to get Reference Adoption Agreement Review attached to these cases
		List<Reference_Adoption_Agreement_Review__c> raars = new List<Reference_Adoption_Agreement_Review__c>();
		
		List<ID> usersToMention = new List<ID>();
		String refName;
		String postText; 
		

		raars = [SELECT Case_Lookup__r.Account.Name, Name, Bis_ID__c, FSS__c, Sales_Rep__r.DSA_FSS__c, Zone__c, Sales_Rep__c, Implementation_Manager__c, Client_Relationship_Account_Manager__c, Case_Lookup__c
			FROM Reference_Adoption_Agreement_Review__c WHERE Case_Lookup__c IN: caseIds];
		
		//collect information from the Reference Adoption Agreement Review object
		for (Reference_Adoption_Agreement_Review__c raar: raars) 
		{
			//create list of users to mention in Chatter post
			if(raar.Sales_Rep__c != null)
			{
				usersToMention.add(raar.Sales_Rep__c);
			}
			if(raar.Implementation_Manager__c != null)
			{
				usersToMention.add(raar.Implementation_Manager__c);
			}
			if(raar.Client_Relationship_Account_Manager__c != null)
			{
				usersToMention.add(raar.Client_Relationship_Account_Manager__c);
			}
			if(raar.FSS__c != null && raar.Zone__c == '11')
			{
				usersToMention.add(raar.Sales_Rep__r.DSA_FSS__c);
			}
			if (raar.Case_Lookup__r.Account.Name != null)
			{
				postText = '\r\nPlease click on the '+ raar.Name + ' link at the bottom of this case to view your presale AA review for ' + raar.Case_Lookup__r.Account.Name + '. \r\nBis ID: '+ raar.Bis_ID__c +'. \r\nContact your Field Support Manager with any questions.';
			}
			else
			{
				postText = '\r\nPlease click on the '+ raar.Name + ' link at the bottom of this case to view your presale AA review. \r\nBis ID: '+ raar.Bis_ID__c +'. \r\nContact your Field Support Manager with any questions.';
			}
		}
		//place chatter post on the case related to the reference object.
		for (ID caseId: caseIds)
		{
			chatterMentionPost.createChatterMentionPost(caseId, usersToMention, postText);
		}
	}
}