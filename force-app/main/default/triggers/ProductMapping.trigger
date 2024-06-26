/* 
 * Map the lookup fields on the object on change.
 *
 * History
 * -------
 * 09/22/2011 Dan Carmen   Created
 *
 */
trigger ProductMapping on Product_Mapping__c (before insert, before update) {
   ProductMapping.processData((Product_Mapping__c[])Trigger.new);
} // trigger ProductMapping