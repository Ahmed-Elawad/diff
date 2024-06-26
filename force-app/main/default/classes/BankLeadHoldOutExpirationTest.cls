/* 
 * A batch job for checking Lead Hold Out Expiration and clearing the Hold Out if equals or less than today
 *
 * History
 * -------
 * 10/30/2012 Carrie Marciano   Created
   01/10/2020 Dan Carmen        Change seeAllData to false, increment API version
 */
@isTest(SeeAllData=false)
private class BankLeadHoldOutExpirationTest {

   static String TEST_LEAD_SOURCE = 'BankLeadHoldOutExpirationTest';

   static testMethod void testLeadUpdate() {
    
      DataFluxDeltaServiceTest.disableDeltaTriggers();
      // create a new Lead
      Lead l1 = new Lead(LastName='Quiggle',Company='Susie Q Co',NumberOfEmployees=12,LeadSource=TEST_LEAD_SOURCE,Bank_Lead_ID__c='12345678',PostalCode='00011',Hold_Out__c=true,Hold_Out_Expiration__c=Date.TODAY());
      Lead l2 = new Lead(LastName='Barnes',Company='Barnes Law Firm',NumberOfEmployees=12,LeadSource=TEST_LEAD_SOURCE,Bank_Lead_ID__c='23456789',PostalCode='00011',Hold_Out__c=true,Hold_Out_Expiration__c=Date.TODAY().addDays(90));
      Lead l3 = new Lead(LastName='Laurel',Company='Laurel Bakery',NumberOfEmployees=12,LeadSource=TEST_LEAD_SOURCE,Bank_Lead_ID__c='34567890',PostalCode='00011',Hold_Out__c=false,Hold_Out_Expiration__c=null); 
      Lead l4 = new Lead(LastName='Greenwood',Company='Greenwood Bar and Grill',NumberOfEmployees=12,LeadSource=TEST_LEAD_SOURCE,Bank_Lead_ID__c='23456789',PostalCode='00011',Hold_Out__c=true,Hold_Out_Expiration__c=Date.TODAY().addDays(-10));
      
      Lead[] leads = new Lead[]{l1,l2,l3,l4};
      insert leads;
      
      // run process
      BankLeadHoldOutExpiration blex = new BankLeadHoldOutExpiration();
      BankLeadHoldOutExpiration.LEAD_SOURCE = TEST_LEAD_SOURCE;

      Test.startTest();
      Database.executeBatch(blex,200);
      Test.stopTest();
      
      // verify changes occurred
      Id[] ids = new Id[]{l1.Id,l2.Id,l3.Id,l4.Id};
      Map<Id,Lead> leadCheck = new Map<Id,Lead>([Select Id, FirstName, LastName, Company, Hold_Out__c, Hold_Out_Expiration__c from Lead where Id in :ids]);
         
      System.assertEquals(leadCheck.get(l1.Id).Hold_Out__c,true);
      System.assertEquals(leadCheck.get(l1.Id).Hold_Out_Expiration__c,Date.TODAY());
      System.assertEquals(leadCheck.get(l2.Id).Hold_Out__c,true);
      System.assertEquals(leadCheck.get(l2.Id).Hold_Out_Expiration__c,Date.TODAY().addDays(90));
      System.assertEquals(leadCheck.get(l3.Id).Hold_Out__c,false);
      System.assertEquals(leadCheck.get(l3.Id).Hold_Out_Expiration__c,NULL);
      System.assertEquals(leadCheck.get(l4.Id).Hold_Out__c,false);
      System.assertEquals(leadCheck.get(l4.Id).Hold_Out_Expiration__c,NULL);
    }// testLeadUpdate
    
    static testMethod void testScheduler() {
      BankLeadHoldOutExpiration.LEAD_SOURCE = TEST_LEAD_SOURCE;
      TestHelper.testScheduler('testBankLeadHoldOutExpiration', new BankLeadHoldOutExpiration());
    } // testScheduler
}