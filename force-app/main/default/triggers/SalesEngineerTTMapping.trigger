trigger SalesEngineerTTMapping on Sales_Engineer_TT_Mapping__c (before insert,before update,before delete) {
   String TT_CACHEKEY = 'TTMappingCacheKey';
	CacheManager.removeOrg(TT_CACHEKEY);
}