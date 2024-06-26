/* 
 * Trigger for Product transactions.
 *
 * History
 * -------
 * 06/16/2011 Dan Carmen   Created
   11/08/2011 Dan Carmen   Added login to populate Rollup_Product field
   05/16/2012 Dan Carmen   Added logic to handle multiple sales orgs on products  
   03/31/2020 Dan Carmen   Add call to generate a unique id.

*/
trigger ProductTrigger on Product2 (before insert, before update, after insert, after update, after delete) {

   if (Trigger.isDelete) {
      // clear the cache after any product changes.
      productQuery.clearCache();
   } else if (Trigger.isAfter) {
   	// the records to check for the pricebook entries
      Product2[] checkEntries = new Product2[]{};
      for (Product2 rec: Trigger.new) {
         if (Trigger.isInsert) {
            if (rec.Sales_Org__c != null) {
               checkEntries.add(rec);
            }
         } else if (Trigger.isUpdate) {
            Product2 oldRec = (Product2)Trigger.oldMap.get(rec.Id);
            if (rec.Sales_Org__c != oldRec.Sales_Org__c) {
            	checkEntries.add(rec);
            }
         } // if (Trigger.isInsert
      } // for
   
      if (!checkEntries.isEmpty()) {
         ProductMethods.checkPricebookEntries(checkEntries);
      }
      // clear the cache after any product changes.
      productQuery.clearCache();
   } else if (Trigger.isBefore) {
      ProductMethods.checkForUniqueId(Trigger.new);
      Product2[] checkRollups = new Product2[]{};
      for (Product2 rec : Trigger.new) {
         rec.Rollup_Product__c = null;
         if (rec.Rollup_Product_Code__c != null) {
            checkRollups.add(rec);
         }
      }
      if (!checkRollups.isEmpty()) {
         ProductMethods.checkRollupProduct(checkRollups);
      } // if (!checkRollups
   }
} // trigger ProductTrigger