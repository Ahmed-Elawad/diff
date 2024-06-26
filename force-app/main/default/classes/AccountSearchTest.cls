/* 
 * Test methods for the AccountSearch class
 *
 * History
 * -------
 * 11/21/2010 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API to version 44

 */
@isTest
private class AccountSearchTest {

   static testMethod void testSearch() {
      AccountSearch acctSearch = new AccountSearch();
      System.assertEquals(false,acctSearch.searchPerformed);
      // verify defaults
      System.assertEquals(false,acctSearch.hasName);
      System.assertEquals(false,acctSearch.hasBranchNumber);
      System.assertEquals(false,acctSearch.hasClientNumber);
      System.assertEquals(false,acctSearch.hasPostalCode);
      System.assertEquals(false,acctSearch.hasSearchResults);
      
      // try a search with nothing set
      System.assertEquals(false,acctSearch.searchAccts());
      System.assertEquals(false,acctSearch.searchPerformed);
      
      // create an Account to search
      Account acct = new Account(Name='AccountSearchTest Record0',AccountNumber='17-DAN0',ShippingPostalCode='14514');
      insert acct;
      
      // set search criteria
      acctSearch.linkRecord = new Client_CPA_Link__c();
      acctSearch.linkRecord.Client_Name__c = 'AccountSearchTest';
      acctSearch.linkRecord.Payroll_Branch_Number__c = '0017';
      acctSearch.linkRecord.Payroll_Client_Number__c = 'DAN0';
      acctSearch.linkRecord.Client_Postal_Code__c = '14514';
      
      // perform the search
      System.assertEquals(true,acctSearch.searchAccts());
      // verify results
      System.assertEquals(true,acctSearch.hasSearchResults);
      System.assertEquals(true,acctSearch.searchPerformed);
      System.assertEquals(1,acctSearch.searchResults.size());
      
      Account[] accts = new Account[]{};
      // create multiple accounts to get many search results
      for (Integer cnt=1; cnt<=50; cnt++) {
         accts.add(new Account(Name='AccountSearchTest Record'+cnt,AccountNumber='17-DAN'+cnt,ShippingPostalCode='14514'));
      }
      insert accts;

      // remove client number from search criteria
      acctSearch.linkRecord.Payroll_Client_Number__c = null;
      
      // perform the search
      System.assertEquals(true,acctSearch.searchAccts());
      // verify results
      System.assertEquals(true,acctSearch.hasSearchResults);
      System.assertEquals(true,acctSearch.searchPerformed);
      System.assertEquals(51,acctSearch.searchResults.size());
   } // testSearch
   
} // class AccountSearchTest