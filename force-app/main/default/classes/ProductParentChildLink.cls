/* 
 * Handle trigger actions for the Product_Parent_Child_Links__c object.
 *
 * History
 * -------
 * 05/17/2011 Dan Carmen   Created
   05/16/2012 Dan Carmen   Modified to be able to use multiple sales orgs on products
   10/29/2018 Dan Carmen   Increment API to version 44

 */
public with sharing class ProductParentChildLink {

   public static void setProductLinks(Id[] linkIds) {
      Product_Parent_Child_Link__c[] prodLinks = [Select Id
                                                        ,Child_Product_Code__c
                                                        ,Child_Product__c
                                                        ,Product_Group_Product_Code__c
                                                        ,Product_Group__c
                                                        ,Parent_Product_Code__c
                                                        ,Parent_Product__c
                                                        ,Sales_Org__c
                                                    from Product_Parent_Child_Link__c
                                                   where Id in :linkIds];
      if (!prodLinks.isEmpty()) {
         setProductLinks(prodLinks);
      }
   } // setProductLinks

   public static void setProductLinks(Product_Parent_Child_Link__c[] prodLinks) {
      // get the product codes - use a set to prevent duplicates
      Set<String> prodCodes = new Set<String>();
      
      for (Product_Parent_Child_Link__c ppcl : prodLinks) {
         if (ppcl.Child_Product_Code__c != null) {
            prodCodes.add(ppcl.Child_Product_Code__c);
         }
         if (ppcl.Parent_Product_Code__c != null) {
            prodCodes.add(ppcl.Parent_Product_Code__c);
         }
         if (ppcl.Product_Group_Product_Code__c != null) {
            prodCodes.add(ppcl.Product_Group_Product_Code__c);
         }
      } // for (Product_Parent_Child_Link__c
      // select the products
      Product2[] prods = [Select Id, Name, ProductCode
                                ,Sales_Org__c
                            From Product2
                           where IsActive=true
                             and ProductCode in :prodCodes];
      
      // records to update - use map to prevent dups in the list
      Map<String,Product2> toUpdate = new Map<String,Product2>();
      
      // add the links to the products
      for (Product_Parent_Child_Link__c ppcl : prodLinks) {
      	 Product2 prod = getProduct(prods,ppcl.Child_Product_Code__c,ppcl.Sales_Org__c);
      	 ppcl.Child_Product__c = (prod != null ? prod.Id : null);
      	 
      	 prod = getProduct(prods,ppcl.Product_Group_Product_Code__c,ppcl.Sales_Org__c);
      	 ppcl.Product_Group__c = (prod != null ? prod.Id : null);
      	 
      	 prod = getProduct(prods,ppcl.Parent_Product_Code__c,ppcl.Sales_Org__c);
      	 ppcl.Parent_Product__c = (prod != null ? prod.Id : null);
      	 if (prod != null) {
            prod.Has_Child__c = true;
            // add parent records to map to update
            toUpdate.put(prod.ProductCode,prod);
      	 } // if (prod != null

      } // for (Product_Parent_Child_Link__c

      update prodLinks;
      if (!toUpdate.isEmpty()) {
         update toUpdate.values();
      } // if (!toUpdate.isEmpty
      
   } // setProductLinks
   
   private static Product2 getProduct(Product2[] prods, String prodCode, String p_salesOrg) {
   	  Product2 foundProd = null;
   	  if (prodCode != null && p_salesOrg != null) {
   	  	  String[] salesOrgs = p_salesOrg.split(';');
   	  	  for (String salesOrg : salesOrgs) {
              for (Product2 prod : prods) {
   	           if ((prod.ProductCode == prodCode) &&
   	               (prod.Sales_Org__c != null && prod.Sales_Org__c.contains(salesOrg))) {
   	              foundProd = prod;
   	              break;
   	           }
              } // for (Product2 prod
   	     } // for (String salesOrg
   	  } // if (prodCode != null
   	  return foundProd;
   } // getProduct
   
} // class ProductParentChildLink