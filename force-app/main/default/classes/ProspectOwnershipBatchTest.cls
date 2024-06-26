/* 
 * Test methods for the ProspectOwnershipBatch class
 *
 * History
 * -------
 * 07/13/2017 Dan Carmen   Created
i
 *
 */
@isTest
private class ProspectOwnershipBatchTest {

   static testMethod void testBatch() {
      ProspectOwnershipMethodsTest.createAllProspectingLols();
      LifeOfLeadSettings__c lockoutLol = ProspectOwnershipMethodsTest.createLockoutLols(UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2');
      Account acct3 = new Account(Name='Account3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Lead ld4 = new Lead(Company='Company4', LastName='Person4');
      Lead ld5 = new Lead(Company='Company5', LastName='Person5');
      Lead ld6 = new Lead(Company='Company6', LastName='Person6');
      Lead[] lds = new Lead[]{ld4,ld5,ld6};
      insert lds;
      
      Prospect_Ownership__c po1 = ProspectOwnershipMethodsTest.createProspectingOwnership(ProspectOwnershipMethodsTest.lolsPAY, null, acct1);
      Prospect_Ownership__c po2 = ProspectOwnershipMethodsTest.createProspectingOwnership(ProspectOwnershipMethodsTest.lolsPAY, null, acct2);
      // put ownership past the end date of the stage
      po2.StartDate__c = Date.today().addDays(-(Integer.valueOf(ProspectOwnershipMethodsTest.lolsPAY.NumOfDays__c)+3));
      po2.ProspectingStart__c = po2.StartDate__c;
      Prospect_Ownership__c po3 = ProspectOwnershipMethodsTest.createProspectingOwnership(lockoutLol, null, acct3);
      // put ownership past the end date of the stage
      po3.StartDate__c = Date.today().addDays(-(Integer.valueOf(lockoutLol.NumOfDays__c)+3));
      po3.LockoutStart__c = po3.StartDate__c;
      
      Prospect_Ownership__c po4 = ProspectOwnershipMethodsTest.createProspectingOwnership(ProspectOwnershipMethodsTest.lolsPAY, ld4, null);
      Prospect_Ownership__c po5 = ProspectOwnershipMethodsTest.createProspectingOwnership(ProspectOwnershipMethodsTest.lolsPAY, ld5, null);
      // put ownership past the end date of the stage
      po5.StartDate__c = Date.today().addDays(-(Integer.valueOf(ProspectOwnershipMethodsTest.lolsPAY.NumOfDays__c)+3));
      po5.ProspectingStart__c = po2.StartDate__c;

      Prospect_Ownership__c po6 = ProspectOwnershipMethodsTest.createProspectingOwnership(lockoutLol, ld6, null);
      // put ownership past the end date of the stage
      po6.StartDate__c = Date.today().addDays(-(Integer.valueOf(lockoutLol.NumOfDays__c)+3));
      po6.LockoutStart__c = po3.StartDate__c;

      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3,po4,po5,po6};
      insert pos;
      
      Test.startTest();
      ProspectOwnershipBatch pob = new ProspectOwnershipBatch();
      Database.executeBatch(pob,12);
      Test.stopTest();

   } // testBatch
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testProspectOwnershipBatch', new ProspectOwnershipBatch());
   } // testScheduler
   

} // class ProspectOwnershipBatchTest