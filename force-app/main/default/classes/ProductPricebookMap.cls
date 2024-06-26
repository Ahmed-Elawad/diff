/* 
 * Methods for the Product_Pricebook_Map__c object.
 *
 * History
 * -------
 * 06/16/2011 Dan Carmen   Created
   10/26/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class ProductPricebookMap {

   public static void getPricebookId(Product_Pricebook_Map__c[] records) {
      // get the pricebook names
      Map<String,String> pricebookNameMap = new Map<String,String>();
      for (Product_Pricebook_Map__c ppm : records) {
         pricebookNameMap.put(ppm.Pricebook_Name__c,ppm.Pricebook_Name__c);
      } // for (Product_Pricebook_Map__c
      
      // select the pricebooks
      Pricebook2[] pricebooks = [Select Id, Name
                                   from Pricebook2
                                 where Name IN :pricebookNameMap.values()];
      
      // set the pricebook ids 
      for (Product_Pricebook_Map__c ppm : records) {
         ppm.Pricebook_Id__c = null;
         for (Pricebook2 pb : pricebooks) {
            if (ppm.Pricebook_Name__c == pb.Name) {
               ppm.Pricebook_Id__c = pb.Id;
               break;
            }
         } // for (Pricebook2
      } // for (Product_Pricebook_Map__c
   } // getPricebookId
   
} // class ProductPricebookMap