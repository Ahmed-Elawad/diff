@isTest
public class MilestoneUtilsTest {
    @isTest
    public static void milestoneTestMethod() {
        // Create new Case records
        Case c = new Case();
        Case c2 = new Case();

        // Ensure the RecordType is set correctly
        RecordType recordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Multi_Product_Service_Case' LIMIT 1];
        c.RecordTypeId = recordType.Id;
        c2.RecordTypeId = recordType.Id;

        // Explicitly set the field to avoid validation errors
        c.Is_Created_by_Mid_Market_Flow__c = true;
        c2.Is_Created_by_Mid_Market_Flow__c = true;
		c.Status='Submitted';
        c2.Status='Closed';
        // Add debug logging to trace the issue
        System.debug('Case RecordType: ' + c.RecordTypeId);
        System.debug('Is_Created_by_Mid_Market_Flow__c: ' + c.Is_Created_by_Mid_Market_Flow__c);
		List<Id> caseIds = new List<Id>();
       
        List<Case> caseList = new List<Case>();
        caseList.add(c);
        caseList.add(c2);
		caseIds.add(c.Id);
        Test.startTest();
        MilestoneUtils.completeMilestone(caseIds, 'OHM - completeMilestone', Date.today());
        MilestoneUtils.completeMPSCMilestones(caseList);
        Test.stopTest();
    }
}