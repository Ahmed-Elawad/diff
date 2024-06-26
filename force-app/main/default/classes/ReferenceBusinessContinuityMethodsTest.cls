/* 
   Test for Reference Business Continuity Response
   
  History
  -------
  03/31/2020 Jake Hinds         Created
 */
@isTest
public class ReferenceBusinessContinuityMethodsTest {
    static testMethod void testCaseUpdate(){
        Account acct = new Account(Name='test');
        insert acct;
        Contact ctct = new Contact(LastName='test',AccountId=acct.Id);
        insert ctct;
        Id caseRTId = RecordTypeHelper.getRecordType('Business Continuity Response','Case').getRecordTypeId();
        Case c1 = new Case(Subject='test',AccountId=acct.Id,ContactId=ctct.Id,recordTypeId = caseRTId);
        Case c2 = new Case(Subject='test',AccountId=acct.Id,ContactId=ctct.Id,recordTypeId = caseRTId);
        Case c3 = new Case(Subject='test',AccountId=acct.Id,ContactId=ctct.Id,recordTypeId = caseRTId);
        Case c4 = new Case(Subject='test',AccountId=acct.Id,ContactId=ctct.Id,recordTypeId = caseRTId);
        Case[] cases = new Case[]{c1,c2,c3,c4};
        insert cases;
        Reference_Business_Continuity_Response__c bcr1 = new Reference_Business_Continuity_Response__c(Case_Lookup__c = c1.Id,Status__c='Complete');
        Reference_Business_Continuity_Response__c bcr2 = new Reference_Business_Continuity_Response__c(Case_Lookup__c = c2.Id);
        Reference_Business_Continuity_Response__c bcr3 = new Reference_Business_Continuity_Response__c(Case_Lookup__c = c3.Id);
        Reference_Business_Continuity_Response__c bcr4 = new Reference_Business_Continuity_Response__c(Case_Lookup__c = c4.Id);
        Reference_Business_Continuity_Response__c[] bcrs = new Reference_Business_Continuity_Response__c[]{bcr1,bcr2,bcr3,bcr4};
        insert bcrs;
        
        Test.startTest();
        bcr1.Status__c = 'New';
        bcr1.Level_of_Risk__c = '1 - Remain Open and Operational';
        bcr2.Status__c = 'In Progress';
        bcr2.Level_of_Risk__c = '3';
        bcr3.Status__c = 'Client Non-Responsive';
        bcr3.Level_of_Risk__c = '4';
        bcr4.Status__c = 'Complete';
        bcr4.Level_of_Risk__c = '5 - Permanent Closures or Layoffs';
        update bcrs;
        
        Case uC1 = [SELECT Id,Status,Priority FROM Case WHERE Id = :c1.Id LIMIT 1];
        Case uC2 = [SELECT Id,Status,Priority FROM Case WHERE Id = :c2.Id LIMIT 1];
        Case uC3 = [SELECT Id,Status,Priority FROM Case WHERE Id = :c3.Id LIMIT 1];
        Case uC4 = [SELECT Id,Status,Priority FROM Case WHERE Id = :c4.Id LIMIT 1];
        
        system.assertEquals('New',uc1.Status);
        system.assertEquals('Low',uc1.Priority);
        system.assertEquals('In Progress',uc2.Status);
        system.assertEquals('Medium',uc2.Priority);
        system.assertEquals('Cancelled',uc3.Status);
        system.assertEquals('High',uc3.Priority);
        system.assertEquals('Complete',uc4.Status);
        system.assertEquals('Critical',uc4.Priority);
        Test.stopTest();
    }
}