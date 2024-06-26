/* 
 * Find the UserRole for the data entered.
 *
 * History
 * -------
 * 09/13/2011 Dan Carmen   Created
   03/05/2012 Dan Carmen   Added Zone and Area checks
 *
 */
trigger QuotaBySalesOrg on Quota_By_Sales_Org__c (before insert, before update) {
   QuotaBySalesOrg.setupLookupData((Quota_By_Sales_Org__c[])Trigger.new);
} // trigger QuotaBySalesOrg