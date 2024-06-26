/*  Test methods for the CaseATCTriggerHelper class 
 *  
 * History
 * --------
 * 3/6/2023  Susmitha Somavarapu   Created
 */

@istest 
public with sharing class CaseATCTriggerHelperTest {
    
    @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('CaseBefore', true, false, false, false, new String[]{'caseATCTriggerHelper'});
      TriggerMethodsTest.createTriggerSetting('CaseAfter', false, true, false, false, new String[]{'caseATCTriggerHelper'});
      TriggerMethodsTest.saveSetupClasses();      
  	  CreateTestData.createSingleAandTwoCts(); 
   } // setupDataHNB Enrollments ATC Case Record Type
   static testMethod void testGetSalesAccountType() {
  	  Account acct = [Select Id, Name from Account where Name = 'Test Account1'];  	  
  	 // Schema.RecordTypeInfo caseRt = RecordTypeHelper.getRecordType('HNB Enrollments ATC Case Record Type', ObjectHelper.OBJECT_CASE); 
      
     // Id hnbEnrollmentsATCRecType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HNB Enrollments ATC Case Record Type').getRecordTypeId();
      //   Id hnbEnrollmentsATCRecType = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('HNB_Enrollments_ATC_Case_Record_type').getRecordTypeId();
      RecordType hnbEnrollmentsATCRecType = [Select Id, Name, sobjectType from RecordType 
      where sObjectType = 'Case' and Name = 'HNB Enrollments ATC Case Record Type' and IsActive = true];  

  	  Case kase1 = new Case(recordTypeId=hnbEnrollmentsATCRecType.id,Type='ATC', AccountId=acct.Id);
  	  insert kase1;
   }

}