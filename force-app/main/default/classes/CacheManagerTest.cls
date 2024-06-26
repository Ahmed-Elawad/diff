/* Test methods for the CacheManager class

  History
  -------
  08/29/2017 Dan Carmen        Created
  09/18/2018 Dan Carmen        Add Session options
  10/14/2021 Dan Carmen        Add schedulable and ability to clear the entire cache
  03/18/2022 Dan Carmen        Fix clearOrgCache method - can't clear all keys at once
  
 */
@isTest
private class CacheManagerTest {

   static testMethod void testCacheManager() {
      CacheManager.CACHE_IN_USE = true;
      
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      CacheManager.putOrg('ThisIsATestKey', acct);
      Account checkAcct = (Account)CacheManager.getOrg('ThisIsATestKey');
      
      System.assertEquals(acct.Id, checkAcct.Id);
      
      System.assertEquals(true,CacheManager.removeOrg('ThisIsATestKey'));
      // shouldn't be there a second time
      System.assertEquals(false,CacheManager.removeOrg('ThisIsATestKey'));
        
      CacheManager.putSession('ThisIsATestKey', acct);
      checkAcct = (Account)CacheManager.getSession('ThisIsATestKey');
      
      System.assertEquals(acct.Id, checkAcct.Id);
      
      System.assertEquals(true,CacheManager.removeSession('ThisIsATestKey'));
      // shouldn't be there a second time
      System.assertEquals(false,CacheManager.removeSession('ThisIsATestKey'));
      
      CacheManager.putOrg('ThisIsATestKey', acct);
      System.assertEquals(true,Cache.Org.contains('ThisIsATestKey'));
      CacheManager.clearOrgCache();
      System.assertEquals(false,Cache.Org.contains('ThisIsATestKey'));

   } // testCacheManager
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testCacheManager', new CacheManager());
   } // testScheduler

} // class CacheManagerTest