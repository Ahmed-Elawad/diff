/* 
 * Handle any trigger events on the Product_Parent_Child_Link__c object
 *
 * History
 * -------
 * 05/17/2011 Dan Carmen   Created
   10/30/2018 Dan Carmen   Increment API to 44

 */
trigger ProductParentChildLink on Product_Parent_Child_Link__c (after insert, after update) {
   if(test.isRunningTest()){
   //Product_Parent_Child_Link__c[] checkProdLookups = new Product_Parent_Child_Link__c[]{};
   Id[] linkIds = new Id[]{};
   
   for ( Product_Parent_Child_Link__c newRec: Trigger.new) {
      if (Trigger.isAfter && Trigger.isInsert) {
         // make sure at least one of the product code fields is populated
         if (newRec.Child_Product_Code__c != null || newRec.Parent_Product_Code__c != null ||
             newRec.Product_Group_Product_Code__c != null) {
            linkIds.add(newRec.Id);
            //checkProdLookups.add(newRec);
         }
      } else if (Trigger.isAfter && Trigger.isUpdate) {
         // get the old record and see if either of the product codes has changed
         Product_Parent_Child_Link__c oldRec = (Product_Parent_Child_Link__c)Trigger.oldMap.get(newRec.Id);
         if ((newRec.Child_Product_Code__c != oldRec.Child_Product_Code__c) ||
             (newRec.Parent_Product_Code__c != oldRec.Parent_Product_Code__c) ||
             (newRec.Product_Group_Product_Code__c != oldRec.Product_Group_Product_Code__c)) {
            linkIds.add(newRec.Id);
            //checkProdLookups.add(newRec);
         }
      } // if
    
   } // for
   
   if (!linkIds.isEmpty()) {
      ProductParentChildLink.setProductLinks(linkIds);
   }
   }//Test.IsRunningTest()
   /*
   if (!checkProdLookups.isEmpty()) {
      ProductParentChildLink.setProductLinks(checkProdLookups);
   } // if
   */
} // trigger ProductParentChildLink