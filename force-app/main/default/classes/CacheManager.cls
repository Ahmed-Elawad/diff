/* Methods for helping to manage the cache.

  History
  -------
  06/14/2017 Dan Carmen        Created
  09/18/2018 Dan Carmen        Add Session options
  10/09/2018 Dan Carmen        Additional controls around the session cache
  07/31/2019 Dan Carmen        Check the key for bad characters
  10/14/2021 Dan Carmen        Add schedulable and ability to clear the entire cache
  03/18/2022 Dan Carmen        Fix clearOrgCache method - can't clear all keys at once

 */
global with sharing class CacheManager implements Schedulable {

   global void execute(SchedulableContext sc) {
      clearOrgCache();
   } // execute
    
   // only allow the put operation to occur in a trigger.
   public static Boolean CACHE_IN_USE = Label.Cache_In_Use=='Y'; // Trigger.isExecuting && (Label.Cache_In_Use=='Y');
   // we skip using the cache if we're running in a siloed test.
   public static Boolean SKIP_CACHE = (Label.Cache_In_Use != 'Y' || (Test.isRunningTest() && !Utilities.isTestSiloed()));

   // get a value out of the org level cache
   public static Object getOrg(String key) {
      key = checkCacheKey(key);
      Object obj = (SKIP_CACHE ? null : Cache.Org.get(key));
      System.debug('getOrg key='+key+' SKIP_CACHE='+SKIP_CACHE+' valueFound='+(obj != null));
      return obj;
   } // getOrg
   
   // put a value into the org level cache
   public static void putOrg(String key, Object value) {
      if (value != null && !SKIP_CACHE && CACHE_IN_USE) {
         key = checkCacheKey(key);
         Cache.Org.put(key,value);
         System.debug('putOrg put value into cache with key='+key);
      } // if (value != null
   } // putOrg
   
   // remove from the org level cache
   public static Boolean removeOrg(String key) {
      key = checkCacheKey(key);
      Boolean keyRemoved = (!SKIP_CACHE && CACHE_IN_USE ? Cache.Org.remove(key) : false);
      return keyRemoved;
   } // removeOrg
   
   public static Boolean isSessionAvailable() {
      return (UserInfo.getSessionId() != null); // && Cache.Session.isAvailable());
   } // isSessionAvailable
   
   // get a value from the session level cache
   public static Object getSession(String key) {
      key = checkCacheKey(key);
      Boolean sessionAvailable = isSessionAvailable();
      Object obj = ((SKIP_CACHE || !sessionAvailable) ? null : Cache.Session.get(key));
      System.debug('getSession key='+key+' SKIP_CACHE='+SKIP_CACHE+' sessionAvailable='+sessionAvailable+' valueFound='+(obj != null));
      return obj;
   } // getSession
   
   // put a value into the session level cache
   public static void putSession(String key, Object value) {
      Boolean sessionAvailable = isSessionAvailable();
      if (value != null && !SKIP_CACHE && CACHE_IN_USE && sessionAvailable) {
         key = checkCacheKey(key);
         Cache.Session.put(key,value);
         System.debug('putOrg put value into cache with key='+key);
      } // if (value != null
   } // putSession
   
   // remove from the session level cache
   public static Boolean removeSession(String key) {
      key = checkCacheKey(key);
      Boolean sessionAvailable = isSessionAvailable();
      Boolean keyRemoved = ((!SKIP_CACHE && CACHE_IN_USE && sessionAvailable) ? Cache.Session.remove(key) : false);
      return keyRemoved;
   } // removeSession
   
   // check for any bad characters in a key for cache
   public static String checkCacheKey(String keyToCheck) {
      String retValue = keyToCheck;
      if (String.isNotBlank(keyToCheck)) {
         // remove characters not valid for the cache key
         Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
         Matcher matcher = nonAlphanumeric.matcher(keyToCheck);
         retValue = matcher.replaceAll(''); //
      }
      return retValue;
   } // checkCacheKey
 
   // remove all values from the org cache
   public static void clearOrgCache() {
      if (CACHE_IN_USE) {
         Set<String> keySet = Cache.Org.getKeys();
         for (String key : keySet) {
            Cache.Org.remove(key);
         }
      } // if (CACHE_IN_USE
   } // clearOrgCache
    
} // class CacheManager