/* 
   HR Matters Tracking Helper Test
   
  History
  -------
  03/05/2020 Michael Karcz    Created 

 */

@isTest
public class HRMattersTrackingHelperTest {
    
    @testSetup
    static void testSetup() {
        
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      	TriggerMethodsTest.createTriggerSetting('CaseAfter', false, true, new String[]{'HRMattersTrackingHelper'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses;
        
        Case caseParent = new Case(Subject='This is a Test Case 543'); //unique name to easily grab during the test
        insert caseParent;
    }
    
    
    static testmethod void overallTest() {
        Id rtId = RecordTypeHelper.getRecordType('HRS HRBP Case Record Type', ObjectHelper.OBJECT_CASE).getRecordTypeId();
        
        System.debug('MAK in HRMattersTrackingHelperTest - rtId: ' + rtId);
        
        Case caseParent = [SELECT Id FROM Case WHERE Subject = 'This is a Test Case 543' LIMIT 1];
        
        System.debug('MAK in HRMattersTrackingHelperTest - caseParent: ' + caseParent);
        
        Case case1 = new Case(RecordTypeId=rtId, Category__c='Coach involved');
        Case failedCase = new Case(RecordTypeId=rtId);
        Case caseChild = new Case(RecordTypeId=rtId, Category__c='Coach involved', ParentId=caseParent.Id);
        
        Case[] cases = new Case[]{case1, failedCase, caseChild};
        
        Test.startTest();
        insert cases;
        Test.stopTest();
   		
        System.debug('MAK in HRMattersTrackingHelperTest - case1 After Insert: ' + case1); 
        
        List<HR_Matters_Tracking__c> trackers = [SELECT Id, Case__c FROM HR_Matters_Tracking__c];
		
        System.debug('MAK in HRMattersTrackingHelperTest - trackers: ' + trackers); 
        
        System.assert(!trackers.isEmpty());
        System.assert(trackers.size() == 1);
        
        System.assertEquals(trackers[0].Case__c, case1.Id);
    }
    
    static testmethod void testUpdate() {
        Case caseUpdate = [SELECT Id, RecordTypeId, Category__c FROM Case WHERE Subject = 'This is a Test Case 543' LIMIT 1];
        Id rtId = RecordTypeHelper.getRecordType('HRS HRBP Case Record Type', ObjectHelper.OBJECT_CASE).getRecordTypeId();
        
        caseUpdate.RecordTypeId = rtId;
        caseUpdate.Category__c = 'Coach involved';
        
        Test.startTest();
        update caseUpdate;
        Test.stopTest();
        
        List<HR_Matters_Tracking__c> trackers = [SELECT Id, Case__c FROM HR_Matters_Tracking__c];
        
        System.assert(!trackers.isEmpty());
        System.assert(trackers.size() == 1);
        
        System.assertEquals(trackers[0].Case__c, caseUpdate.Id);
    }
}