/* 
 * Trigger that fires whenever a Product_Pricebook_Map__c record is saved.
 *
 * History
 * -------
 * 06/16/2011 Dan Carmen   Created
 *
 */
trigger ProductPricebookMap on Product_Pricebook_Map__c (before insert, before update) {
   // only fire for records that do not already have an id.
   Product_Pricebook_Map__c[] records = new Product_Pricebook_Map__c[]{};
   
   for (Product_Pricebook_Map__c newRec: Trigger.new) {
      if ((Trigger.isInsert || Trigger.isUpdate) && newRec.Pricebook_Id__c == null) {
         records.add(newRec);
      }
   } // for
   
   if (!records.isEmpty()) {
      ProductPricebookMap.getPricebookId(records);
   }
} // trigger ProductPricebookMap