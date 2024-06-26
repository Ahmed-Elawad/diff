/* 
  Testmethods for the ProductMethods Class
   
  History
  -------
  06/16/2011 Dan Carmen   Created
  04/02/2012 Dan Carmen   Cleaned up methods and tests.
  09/11/2012 Dan Carmen   Added additional checks in getEntries method.
  10/07/2013 Cindy Freeman  Added Family to queries for testing
  07/08/2015 Dan Carmen   Added changes to be able to test with seeAllData=false 
  11/17/2017 Jacob Hinds  adding sales org to returned price book in getEntries
  03/31/2020 Dan Carmen   Add logic to generate a unique id  
  05/27/2021 Dan Carmen   Add StockKeepingUnit to creating a product
  08/06/2021 Dan Carmen   Change for Standard Price Book

 */
@isTest
public class ProductMethodsTest {

   @isTest(SeeAllData=false)
   static void testAll() {

      String[] prodNames = new String[]{'ProductMethodsTest1','ProductMethodsTest2','ProductMethodsTest3'};
      PricebookEntry[] entries = getEntries(prodNames,'PMSalesOrg',null);
      
      // add products to the pricebook
      prodNames = new String[]{'ProductMethodsTest4','ProductMethodsTest5','ProductMethodsTest6'};
      entries.addAll(getEntries(prodNames,'PMSalesOrg',entries.get(0).Pricebook2));
      
    // test rollup products
    Product2[] testProds = new Product2[]{};
    for (PricebookEntry entry : entries) {
       Product2 p = new Product2(Name=entry.Product2.ProductCode+'-Rollup',Sales_Org__c='PMSalesOrg',IsActive=true,Rollup_Product_Code__c=entry.Product2.ProductCode);
       testProds.add(p);
    }
    insert testProds;
    // get the product ids
    Id[] prodIds = new Id[]{};
    for (Product2 p : testProds) {
       prodIds.add(p.Id);
    }
    // reselect the products
    Product2[] checkProds = [Select Id, Name, Rollup_Product_Code__c, Rollup_Product__c from Product2 where Id in :prodIds]; 
    for (Product2 p : checkProds) {
       System.assertEquals(true,(p.Rollup_Product__c != null));
    }
    
    // test no pricebook for sales org
    Product2 prod1 = new Product2(Name='TestBad1',ProductCode='TestBad1',Sales_Org__c='ThisIsABadSalesOrg',IsActive=true,Rollup_Product_Code__c='ThisIsABadRollupProductCode');
    try {
       insert prod1;
         // should never get here
         System.assertEquals(1,2);
    } catch (Exception e) {
         // should get here
         System.assertEquals(1,1);
    }
    
    // test bad rollup product
      Product2 prod2 = new Product2(Name='TestBad1',ProductCode='TestBad1',Sales_Org__c='PMSalesOrg',IsActive=true,Rollup_Product_Code__c='ThisIsABadRollupProductCode');
      try {
         insert prod2;
         // should never get here
         System.assertEquals(1,2);
      } catch (Exception e) {
        // should get here
        System.assertEquals(1,1);
      }
    
      // test no pricebook for sales org
      Product2 prod3 = new Product2(Name='TestProd1',ProductCode='TestProd1',Sales_Org__c='PMSalesOrg',IsActive=true);
      insert prod3;
      
      // should be two entries created
      System.assertEquals(2,[Select count() from PricebookEntry where Product2Id = :prod3.Id]);
      // remove the sales org
      prod3.Sales_Org__c = null;
      update prod3;

      // should only be one entry now
      System.assertEquals(1,[Select count() from PricebookEntry where Product2Id = :prod3.Id]);

      // test multiple sales orgs
      String[] prodNames2 = new String[]{'ProductMethodsNewTest1'};
      PricebookEntry[] entries2 = getEntries(prodNames,'PMNewSalesOrg',null);
      
      // test no pricebook for sales org
      Product2 prod4 = new Product2(Name='TestProd1',ProductCode='TestProd1',Sales_Org__c='PMSalesOrg;PMNewSalesOrg',IsActive=true);
      insert prod4;

      // should be three entries created
      System.assertEquals(3,[Select count() from PricebookEntry where Product2Id = :prod4.Id]);

      // remove the sales org
      prod4.Sales_Org__c = 'PMNewSalesOrg';
      update prod4;

      // should be two entries now
      System.assertEquals(2,[Select count() from PricebookEntry where Product2Id = :prod4.Id]);

      // remove the sales org
      prod4.Sales_Org__c = null;
      update prod4;

      // should be two entries now
      System.assertEquals(1,[Select count() from PricebookEntry where Product2Id = :prod4.Id]);


   } // testAll

/*
   static testMethod void testSalesOrgs() {
      // setup referral products
      String[] prodNames = new String[]{};
      Product_Mapping__c[] pms = new Product_Mapping__c[]{};
      for (String salesOrg : UserHelper.DIVISION_LIST) {
         String prodName = 'Test Referral-'+salesOrg;
         prodNames.add(prodName);
         Product_Mapping__c pm = new Product_Mapping__c(Sales_Org__c=UserHelper.SO_CORE, Product_Code__c=prodName, Type__c='Oppty-Referral',Mapping_Key__c=salesOrg);
         pms.add(pm);
      }
      // clear out the mappings just in case
      ProductMappingTest.clearMappingByType('Oppty-Referral');

      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, UserHelper.SO_CORE, null);
      // save the product mapping records after the entries were created.     
      insert pms;
      
   }
*/
/*
   @isTest
   static void testPricebook() {
      System.debug('testPricebook standard pricebookid='+Test.getStandardPricebookId());
      try {
         Pricebook2 pb = [Select Id, Name, Description, Sales_Org__c, Short_Name__c from Pricebook2 where Name='Standard Price Book'];
         System.debug('testPricebook 1 pb='+pb);
      } catch (Exception ex) {
         System.debug('testPricebook 1 Exception: '+ex);
      }
      
      try {
         Pricebook2 pb = [Select Id, Name, Description, Sales_Org__c, Short_Name__c from Pricebook2 where Id=:STANDARD_PRICEBOOKID];
         System.debug('testPricebook 2 pb='+pb);
      } catch (Exception ex) {
         System.debug('testPricebook 2 Exception: '+ex);
      }
      
      verifyStandardPricebook();
   } // testPricebook
*/
   public static Id STANDARD_PRICEBOOKID = Test.getStandardPricebookId();
   
   public static void verifyStandardPricebook() {
      // the standard price book
      // this is in case the class can't see the org data.
      //try {
      //   Pricebook2 pb = [Select Id, Name from Pricebook2 where Name='Standard Price Book'];
      //} catch (Exception e) {
      //    Pricebook2 pb = new Pricebook2(Name='Standard Price Book', IsActive=true);
      //    insert pb;
      //}
      // make sure there is a record for the standard pricebook
      try {
         Product_Pricebook_Map__c ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c from Product_Pricebook_Map__c where Sales_Org__c = :ProductMethods.STANDARD];
         System.debug('verifyStandardPricebook found ppm='+ppm);
      } catch (Exception e) {
         // if error selecting, create a new record
         Product_Pricebook_Map__c ppm = new Product_Pricebook_Map__c(Name='Test1',Sales_Org__c=ProductMethods.STANDARD,Pricebook_Name__c='Standard Price Book', Pricebook_Id__c=STANDARD_PRICEBOOKID);
         insert ppm;
         System.debug('verifyStandardPricebook created new ppm='+ppm);
      }
    
   } // verifyStandardPricebook
   
   /** To create a pricebook, products, and product entry for use in other testMethods.
    * @param prodNames the names of the products to create
    * @param pb if using an existing pricebook pass it in to add the product to it.
    */
   public static PricebookEntry[] getEntries(String[] prodNames, String salesOrg, Pricebook2 pb) {
      verifyStandardPricebook();
      if (pb == null) {
         // see if pricebook exists. If not, create it.
         try {
            pb = [Select Id, Name, IsActive,Sales_Org__c from Pricebook2 where Name=:salesOrg];
            System.debug('getEntries pricebook found for '+salesOrg);
         } catch (Exception e) {
            // setup pricebook
            pb = new Pricebook2(Name=salesOrg, IsActive=true,Sales_Org__c=salesOrg);
            insert pb;
            System.debug('getEntries new pricebook created for '+salesOrg);
         } // try
      } // if (pb == null
      if (pb != null) {
         // setup pricebook Map records so products will be automatically added
         Product_Pricebook_Map__c ppm = null;
         // see if mapping exists. If it doesn't exist, create it.
         try {
            ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c from Product_Pricebook_Map__c where Pricebook_Name__c=:pb.Name];
            System.debug('getEntries existing ppm found for '+salesOrg);
         } catch (Exception e) {
            ppm = new Product_Pricebook_Map__c(Name=salesOrg,Sales_Org__c=salesOrg,Pricebook_Name__c=pb.Name);
            insert ppm;
            System.debug('getEntries new ppm created for '+salesOrg);
         } // try
      } // if (pb != null
      
      // insert product - should get attached to pricebook based on ProductTrigger
      // collection of products created
      Product2[] prods = new Product2[]{};
      for (String prodName : prodNames) {
         prods.add(new Product2(Name=prodName,ProductCode=prodName,Sales_Org__c=salesOrg, IsActive=true,Unit_Type__c='Widget',Family=prodName, StockKeepingUnit=salesOrg+prodName
                                ,cafsl__Part_Number__c=salesOrg+prodName));
      }
      insert prods;
      // get the product ids
      Id[] prodIds = new Id[]{};
      for (Product2 prod : prods) {
         prodIds.add(prod.Id);
      }
      
    System.debug('getEntries pb='+pb.Id+' prodIds='+prodIds);
      PricebookEntry[] entries = [Select Id, Pricebook2Id, Product2Id,UnitPrice,UseStandardPrice,IsActive
                                    ,Pricebook2.Id, Pricebook2.Name
                                    ,Product2.Name, Product2.ProductCode, Product2.Sales_Org__c, Product2.IsActive, Product2.Family  
                                    ,Product2.cafsl__Part_Number__c, Product2.StockKeepingUnit
                                from PricebookEntry where Product2Id in :prodIds and Pricebook2Id=:pb.Id];
      // verify same number of entries as prodNames passed in
      System.assertEquals(prodNames.size(), entries.size());
      // verify values on each entry are set
      for (PricebookEntry entry : entries) {
         System.assertEquals(true,entry.Product2.IsActive);
         System.assertEquals(0,entry.UnitPrice);
         System.assertEquals(false,entry.UseStandardPrice);
         System.assertEquals(true,entry.IsActive);
         System.assertEquals(true,(entry.Product2.Family != null ? true : false));
      } // for
      return entries;
   } // getEntry
    
    static testMethod void testUniqueCode() {
        verifyStandardPricebook();
        String[] prodNames = new String[]{'Prod1','Prod2','Prod3','Prod4'};
        PricebookEntry[] entries = getEntries(prodNames, 'TestOrg', null);
        Pricebook2 pb = entries[0].Pricebook2;
        
        Integer nbrFound = 0;
        for (PricebookEntry entry : entries) {
            if (entry.Product2.Name == 'Prod1') {
               nbrFound++;
               System.assertEquals('TestOrgProd1', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod2') {
               nbrFound++;
               System.assertEquals('TestOrgProd2', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod3') {
               nbrFound++;
               System.assertEquals('TestOrgProd3', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod4') {
               nbrFound++;
               System.assertEquals('TestOrgProd4', entry.Product2.cafsl__Part_Number__c);
            }
        } // for (PricebookEntry entry
        System.assertEquals(4,nbrFound);
        /*
        // add a product with the same names and new names
        prodNames = new String[]{'Prod1','Prod2','Prod5','Prod5','Prod5','Prod6'};
        entries = getEntries(prodNames, 'TestOrg', pb);
        nbrFound = 0;
        Set<String> prod5Keys = new Set<String>{'prod5-prod5-prod5','prod5-prod5-prod51','prod5-prod5-prod52'};
        for (PricebookEntry entry : entries) {
            if (entry.Product2.Name == 'Prod1') {
               nbrFound++;
               System.assertEquals('TestOrgprod1', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod2') {
               nbrFound++;
               System.assertEquals('TestOrgprod1', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod6') {
               nbrFound++;
               System.assertEquals('TestOrgprod6', entry.Product2.cafsl__Part_Number__c);
            } else if (entry.Product2.Name == 'Prod5') {
               nbrFound++;
               System.assertEquals(true,prod5Keys.remove(entry.Product2.cafsl__Part_Number__c));
               //System.assertEquals('Prod6-Prod6-Prod6', entry.Product2.cafsl__Part_Number__c);
             }
        } // for (PricebookEntry entry : entries
        System.assertEquals(6,nbrFound);
        System.assertEquals(true,prod5Keys.isEmpty());
        */
    } // testUniqueCode
   
} // class ProductMethodsTest