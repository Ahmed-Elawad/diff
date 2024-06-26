@isTest
public with sharing class RelatedToReportsControllerTest {
	@isTest
	static void allRelatedReportsTest() {
      	Account a1 = new Account(Name='Test Account 1', Contact_Email_Available__c=false);
      	insert a1;

		RelatedToReports__c reportItem = new RelatedToReports__c(Name='Test', ReportID__c='123456789', Object__c='Account');
		insert reportItem;

		Test.startTest();
		List<RelatedToReports__c> reportItems = RelatedToReportsController.allRelatedReports(a1.Id);
		Test.stopTest();

		System.assertEquals(reportItems.size() != 0, true, 'The RelatedToReports custom setting was not received');
	}

	@isTest
	static void allRelatedReports_Exception_Test() {
		Boolean caughtException = false;

		Test.startTest();
		try{
			List<RelatedToReports__c> reportItems = RelatedToReportsController.allRelatedReports('000000000000000000');
		}catch(AuraHandledException e){
			caughtException = true;
		}
		Test.stopTest();

		System.assertEquals(caughtException, true, 'An exception should have thrown');
	}
}