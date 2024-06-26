/* 
 * Test methods for the ProductParentChildLink class.
 *
 * History
 * -------
 * 05/17/2011 Dan Carmen   Created
   05/16/2012 Dan Carmen   Modified to be able to use multiple sales orgs on products
   10/29/2018 Dan Carmen   Increment API to version 44

 */
@isTest
private class ProductParentChildLinkTest {

   private static Product2[] createTestProducts() {
      Product2 prod1 = new Product2(Name='Test Product 1',ProductCode='TestProd1', Sales_Org__c='TestProd', IsActive=true);
      Product2 prod2 = new Product2(Name='Test Product 2',ProductCode='TestProd2', Sales_Org__c='TestProd', IsActive=true);
      Product2 prod3 = new Product2(Name='Test Product 3',ProductCode='TestProd3', Sales_Org__c='TestProd', IsActive=true);
      Product2[] prods = new Product2[]{prod1,prod2,prod3};
      insert prods; 
      return prods;
   } // createTestProducts
   
   private static Product_Parent_Child_Link__c getLink(Id linkId) {
      Product_Parent_Child_Link__c ppcl = [Select Id, Parent_Product_Code__c, Parent_Product__c, Parent_Product__r.Has_Child__c
                   ,Child_Product_Code__c, Child_Product__c
                   ,Sales_Org__c
                from Product_Parent_Child_Link__c
               where Id = :linkId];
   	  return ppcl;
   } // getLink
   
   static testMethod void testMainCase() {
   	  Product2[] prods = createTestProducts();
   	  // test insert
   	  Product_Parent_Child_Link__c ppcl = new Product_Parent_Child_Link__c(Parent_Product_Code__c=prods[0].ProductCode
   	                                                                      ,Child_Product_Code__c=prods[1].ProductCode
   	                                                                      ,Sales_Org__c=prods[0].Sales_Org__c);
      insert ppcl;
      // verify product codes and links are set
      ppcl = getLink(ppcl.Id);
      System.assertEquals(prods[0].ProductCode,ppcl.Parent_Product_Code__c);
      System.assertEquals(prods[0].Id,ppcl.Parent_Product__c);
      System.assertEquals(prods[1].ProductCode,ppcl.Child_Product_Code__c);
      System.assertEquals(prods[1].Id,ppcl.Child_Product__c);
      System.assertEquals(true,ppcl.Parent_Product__r.Has_Child__c);
      
      // test updating
      ppcl.Child_Product_Code__c = prods[2].ProductCode;
      update ppcl;
      // verify product codes and links are set
      ppcl = getLink(ppcl.Id);
      System.assertEquals(prods[0].ProductCode,ppcl.Parent_Product_Code__c);
      System.assertEquals(prods[0].Id,ppcl.Parent_Product__c);
      System.assertEquals(prods[2].ProductCode,ppcl.Child_Product_Code__c);
      System.assertEquals(prods[2].Id,ppcl.Child_Product__c);
      System.assertEquals(true,ppcl.Parent_Product__r.Has_Child__c);

      // update to a product code that doesn't exist
      ppcl.Child_Product_Code__c = 'prodDoesNotExist';
      update ppcl;
      // verify product codes and links are set
      ppcl = getLink(ppcl.Id);
      System.assertEquals(prods[0].ProductCode,ppcl.Parent_Product_Code__c);
      System.assertEquals(prods[0].Id,ppcl.Parent_Product__c);
      System.assertEquals('prodDoesNotExist',ppcl.Child_Product_Code__c);
      System.assertEquals(null,ppcl.Child_Product__c);
      System.assertEquals(true,ppcl.Parent_Product__r.Has_Child__c);
   } // testMainCase
   
} // class ProductParentChildLinkTest