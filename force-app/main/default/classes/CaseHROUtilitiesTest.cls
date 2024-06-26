/* 
 * Test creatint related HRO cases
 *
 * History
 * -------
 * 07/01/2010 Dan Carmen   Created from HROCaseUtilities
   12/12/2012 Dan Carmen   Clean up some of the code.
   01/09/2014 Josh Cartwright 	Added CA HRO  	
   10/29/2018 Dan Carmen   Increment API to version 44
   05/07/2020 Dan Carmen        Remove AccountHelper.getRecordType

 */
@isTest
private class CaseHROUtilitiesTest {

   static testMethod void testSupportHRO() {
   	  testByRecordType(true,'Service Support HRO Case');
   } // testSupportHRO
   
   static testMethod void testOnboardingHRO1() {
   	  testByRecordType(false,'Service Onboarding HRO Case');
   } // testSupportHRO
   
   static testMethod void testOnboardingHRO2() {
   	  testByRecordType(false,'Service Onboarding HRO Case Record Type');
   } // testSupportHRO
   
   static testMethod void testOnboardingW2() {
   	  testByRecordType(false,'Service Onboarding W2 Only Case Record Type');
   } // testSupportHRO
   
   static testMethod void testOnboardingMAA() {
   	  testByRecordType(false,'Service Onboarding HRO MAA Case');
   } // testSupportHRO
   
    static testMethod void testOnboardingEAO() {
   	  testByRecordType(false,'Service Onboarding EAO Case Record Type');
   }
    
   static testMethod void testOnboardingCAHRO() {
   	  testByRecordType(false,'Service Onboarding CA HRO Record Type');
   } // testOnboardingCAHRO
  
   static void testByRecordType(Boolean useMassCreate, String recordTypeName) {
      // create multiple accounts with the same HRO Number
      List<Account> accts = new List<Account>();
      Account a1 = new Account(Name='Test Account1', HRO_Number__c='TestHRONumber1');
      accts.add(a1);
      Account a2 = new Account(Name='Test Account2', HRO_Number__c='TestHRONumber1');
      accts.add(a2);
      Account a3 = new Account(Name='Test Account3', HRO_Number__c='TestHRONumber1');
      accts.add(a3);
      insert accts;
      // create a Case.
      // attach one of the accounts to the Case
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(recordTypeName, 'Case');
      Case c1 = new Case(AccountId = a1.Id, RecordTypeId = rtInfo.getRecordTypeId());
      if (useMassCreate) {
      	 c1.Mass_Create_Indicator__c = 'HRO Number';
      }
      Test.startTest();
      insert c1;
      Test.stopTest();
      // verify cases created for the other accounts
      Case c2 = [Select Id, AccountId from Case where AccountId = :a2.Id];
      System.assertEquals(a2.Id,c2.AccountId);
      Case c3 = [Select Id, AccountId from Case where AccountId = :a3.Id];
      System.assertEquals(a3.Id,c3.AccountId);
   } // testSupportHRO


} // class CaseHROUtilitiesTest