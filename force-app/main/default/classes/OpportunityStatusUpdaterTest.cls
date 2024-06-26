/* 
   Test methods for the OpportunityStatusUpdater
   
  History
  -------
  05/18/2021 Carrie Marciano     updated StageNames with OppStage labels
  03/24/2022 Dan Carmen          Cleaned up code

 */

@isTest
private class OpportunityStatusUpdaterTest {
	
	@isTest public static void updateOpportunityStatusWithNewActivity_giveActivityObjectWithDemo_UpdateOpportunityFromDiscoverToProve() {
		Account expectedAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234',NumberOfEmployees = 60);
        insert expectedAccount;

        List<Opportunity_Status_Update__mdt> metadataUpdates = [SELECT Id, MasterLabel, DeveloperName, RecordTypeId__c, Status__c, Activity_Type__c FROM Opportunity_Status_Update__mdt LIMIT 10];
        Opportunity_Status_Update__mdt metadataUpdate = metadataUpdates[0];

        Opportunity testOpportunity1 = new Opportunity(Name='test opportunity 1', StageName=Label.OppStage_IEUP, Account=expectedAccount, CloseDate = System.Today().addDays(7), Probability=0);
        testOpportunity1.RecordTypeId = metadataUpdate.RecordTypeId__c;
        insert testOpportunity1;

		Event e = new Event(
                Type = metadataUpdate.Activity_Type__c,
                ActivityDate = System.Today(),
                ActivityDateTime = DateTime.now(),
                DurationInMinutes = 60,
                WhatId = testOpportunity1.Id
        );

        Test.startTest();
        	Opportunity updatedOpportunity = OpportunityStatusUpdater.updateOpportunityStatusWithNewActivity(e);
        Test.stopTest();


        System.assertEquals(updatedOpportunity.StageName, metadataUpdate.Status__c, 'The opportunity had its status updated');
	}

} // class OpportunityStatusUpdaterTest