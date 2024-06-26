/*
The Firm Membership functionality for CPA Program
 History
  -------
01/13/2023 Eric Porter         Created

*/
@isTest
public with sharing class FirmProgramMembershipTest {
    static testMethod void testcreateCPAFirmMemRequests() {
       //set up dummy json data example
      // String memberPortalRequestJSON  = '{testField:'TestData'}';
 
      Test.startTest();
      String result = FirmProgramMembership.createCPAFirmMemRequests(null);
      System.AssertEquals(result,'SUCCESS');

      Test.stopTest();
      //assert that the record was created

    }
    static testMethod void testupdateMemberShips() {
      //set up dummy json data example
      // String memInfoJSON  = '{testField:'TestData'}';
      Referral_Account__c refAct = new Referral_Account__c(name ='Test1');
      insert refAct;
      Referral_Contact__c refCt = new Referral_Contact__c(Name= 'Fn1 LN1', Referral_Account__c=refAct.id); 
      insert refCt;  
      Referral_Contact__c rc = [select id,Referral_Account__c from Referral_Contact__c where id=:refCt.Id limit 1];

      Test.startTest();
      String result = FirmProgramMembership.updateMemberShips(rc.id,true,true);
      System.AssertEquals('SUCCESS',result);
      Test.stopTest();
      //assert that the update went through
      Referral_Contact__c rc1 = [select id,Referral_Account__c, Admin_CPA__c from Referral_Contact__c where id=:refCt.Id limit 1];
      system.Assert(rc1.Admin_CPA__c); 
      
    }
    static testMethod void testfetchMemberInfo() {
      Test.startTest();
      FirmProgramMembership.MembersOuterInfo mio = FirmProgramMembership.fetchMemberInfo();
      System.AssertNotEquals(null,mio);
      Test.stopTest();
      //set up data
      // modify the class so it handles the test and doesnt pull from current data
    }
    static testMethod void testcreateOptOutMemRequests() {
      //set up dummy json data example
      // String memInfoJSON  = '{testField:'TestData'}';
      
      Test.startTest();
      String result = FirmProgramMembership.createOptOutMemRequests(null);
      System.AssertEquals(result,'SUCCESS');
      Test.stopTest();

      //assert that the Chatter went through
    }
}