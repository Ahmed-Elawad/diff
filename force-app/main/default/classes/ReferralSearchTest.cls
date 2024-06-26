/* 
 * Test methods for the ReferralSearch class.
 *
 * History
 * -------
 * 11/22/2011 Dan Carmen        Created.
   10/29/2018 Dan Carmen   Increment API to version 44

 */
@isTest
private class ReferralSearchTest {

   static testMethod void testSearch() {
      ReferralSearch rs = new ReferralSearch();
      // test default values
      System.assertEquals(false,rs.searchPerformed);
      System.assertEquals(false,rs.hasFirst);
      System.assertEquals(false,rs.hasLast);
      System.assertEquals(false,rs.hasEmail);
      System.assertEquals(false,rs.hasPhone);
      System.assertEquals(false,rs.hasAcctName);
      System.assertEquals(false,rs.hasZip);
      System.assertEquals(false,rs.hasSearchResults);
      
      // try a search with no values
      System.assertEquals(false,rs.searchRfrls());
      System.assertEquals(false,rs.searchPerformed);
      System.assertEquals(false,rs.hasSearchResults);
     
      Referral_Account__c ra = new Referral_Account__c(Name='ReferralSearchTest0', Street_Address_1__c = '10 Main Street', Zip_Postal_Code__c = '14514');
      insert ra;
      
      Referral_Contact__c rc = new Referral_Contact__c(Referral_Account__c=ra.Id, Name='Test Referral0', Last_Name__c='Referral0', Email__c='test0@testreferral.com', Phone__c='5551234567');
      insert rc;
      
      // set search criteria
      rs.linkRecord = new Client_CPA_Link__c();
      rs.linkRecord.First_Name__c = 'Test';
      rs.linkRecord.Last_Name__c = 'Referral0';
      rs.linkRecord.Email__c = 'test0@testreferral.com';
      rs.linkRecord.Phone__c = '5551234567';
      rs.linkRecord.Referral_Account_Name__c = 'ReferralSearchTest0';
      rs.linkRecord.Postal_Code__c = '14514';
      
      // attempt a search
      System.assertEquals(true,rs.searchRfrls());
      System.assertEquals(true,rs.searchPerformed);
      System.assertEquals(true,rs.hasSearchResults);
      System.assertEquals(1,rs.searchResults.size());
      
      // search for ref acct
      System.assertEquals(true, rs.searchRfrlAccts('ReferralSearchTest0', '10 Main St', '14514-9709'));
      System.assertEquals(1, rs.searchRefAcctResults.size());
      
      // search for ref ctct
      Referral_Contact__c foundRc1 = rs.searchRfrlCtct(ra.Id, 'Test Referral0', 'Referral0', '555-7654321', 'test0@testreferral.com');
      System.assertEquals(1, rs.searchRefCtctResults.size());
      System.assertEquals(rc.Id, foundRc1.Id);
      
      Referral_Contact__c foundRc2 = rs.searchRfrlCtct(ra.Id, 'T Referral0', 'Referral0', '555-1234567', 'testing@testreferral.com');
      System.assertEquals(1, rs.searchRefCtctResults.size());
      System.assertEquals(rc.Id, foundRc2.Id);

      Referral_Contact__c foundRc3 = rs.searchRfrlCtct(ra.Id, 'T Referral0', 'Referral0', '555-7654321', 'test0@testreferral.com');
      System.assertEquals(1, rs.searchRefCtctResults.size());
      System.assertEquals(rc.Id, foundRc3.Id);
      
      
      
   } // testSearch
   
} // class ReferralSearchTest