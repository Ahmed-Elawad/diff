/* 
 * Tests for the ProductQuery class
 *
 * History
 * -------
 * 07/21/2011 Dan Carmen   Created
   02/14/2013 Dan Carmen   Code modifications to reduce script statements.
   07/30/2015 Dan Carmen   Updates for product mappings
   11/06/2020 Dan Carmen    Cache Pricebooks
   03/25/2021 Dan Carmen    Add cafsl__Part_Number__c to query
   07/14/2021 Dan Carmen    rewrite the cache to save the individual pricebooks in separate cache keys versus all in one.
   03/02/2022 Dan Carmen    APR0131613 Updated to assume the Sales_Division__c field from the Pricebook2 could be a list
   04/24/2022 Dan Carmen    Adjust criteria for Pricebook selection.
   06/14/2022 Dan Carmen    Update testGetPrimaryPricebook test
   12/12/2023 Dan Carmen    Add getProdMap method
   03/06/2024 Dan Carmen    Fix for NPE

*/
@isTest
private class ProductQueryTest {

   public static String SALES_ORG_1='TestSalesOrg1';
   public static String SALES_ORG_2='TestSalesOrg2';
   public static String SALES_DIV_1='SalesDiv1';
   
   private static Pricebook2[] setupPricebooks() {
      Pricebook2 pb1 = new Pricebook2(Name='Test Pricebook1', IsActive=true, Sales_Org__c=SALES_ORG_1, Primary__c=true, Sales_Division__c=SALES_DIV_1);
      Pricebook2 pb2 = new Pricebook2(Name='Test Pricebook2', IsActive=true, Sales_Org__c=SALES_ORG_2, Primary__c=true);
      Pricebook2[] pbs = new Pricebook2[]{pb1,pb2};
      insert pbs;
      /*
      Product_Pricebook_Map__c ppm1 = new Product_Pricebook_Map__c(Name=SALES_ORG_1,Sales_Org__c=SALES_ORG_1,Pricebook_Name__c='Test Pricebook1');
      Product_Pricebook_Map__c ppm2 = new Product_Pricebook_Map__c(Name='TestSalesOrg2',Sales_Org__c=SALES_ORG_2,Pricebook_Name__c='Test Pricebook2');
      Product_Pricebook_Map__c[] ppms = new Product_Pricebook_Map__c[]{ppm1,ppm2};
      insert ppms;
      Integer nbr = [Select count() from Product_Pricebook_Map__c
                               where Sales_Org__c in (:SALES_ORG_1,:SALES_ORG_2)
                                 and Pricebook_Id__c != null
                               ];
      System.assertEquals(2,nbr);
      */
      return pbs;
   } // setupPricebooks
   
   static testMethod void testGetPricebooks() {
      Pricebook2[] pbs = setupPricebooks();
      Map<String,Pricebook2[]> newPbMap = ProductQuery.getAllPricebooksBySalesOrgs(new String[]{SALES_ORG_1,SALES_ORG_2},null);
      System.assertEquals(2,newPbMap.size());
   } // testGetPricebooks
   
   static testMethod void testGetPricebook() {
      Pricebook2[] pbs = setupPricebooks();
      ProductQuery pq = new ProductQuery();
      
      String[] salesOrgs = new String[]{SALES_ORG_1,SALES_ORG_2};
      Map<String,Pricebook2> pbMap = pq.getPricebooksBySalesOrgs(salesOrgs);
      // verify two retrieved
      System.assertEquals(2,pbMap.size());
      
      // get the pricebook ids
      Map<String,Id> pbIdMap = pq.getPricebookIdsBySalesOrgs(salesOrgs);
      // verify two retrieved
      System.assertEquals(2,pbMap.size());
      // verify ones retrieved are the ones we expect
      System.assertEquals(pbs[0].Id,pbIdMap.get(SALES_ORG_1));      
      System.assertEquals(pbs[1].Id,pbIdMap.get(SALES_ORG_2)); 
      
      // test getting one pricebook name
      // test sales org that doesn't exist
      System.assertEquals(null,pq.getPricebookNameBySalesOrg('BadSalesOrg'));
      // test null value
      System.assertEquals(null,pq.getPricebookNameBySalesOrg(null));
      // test valid value
      System.assertEquals('Test Pricebook1',pq.getPricebookNameBySalesOrg(SALES_ORG_1));
      
      // test getting one pricebook by sales org
      Pricebook2 pb = pq.getPricebook('Test Pricebook1', null);
      System.assertEquals(pb.Id,pbs[0].Id);
      
      // test getting one pricebook by Id
      pb = pq.getPricebook(null,pbs[0].Id);
      System.assertEquals(pb.Id,pbs[0].Id);
      
      
   } // testGetPricebook
   
   static testMethod void testGetProductLinksByParentMap() {
      String[] prodName = new String[]{'prod1','prod2','prod3','prod4'};
      String salesOrg = 'testSalesOrg';      
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodName, salesOrg, null);
      ProductQuery pq = new ProductQuery();
      Id[] prodIds = new Id[]{};
      PricebookEntry testEntry = null;
      for (PricebookEntry pe : entries) {
         prodIds.add(pe.Product2Id);
         if (testEntry == null) {
            testEntry = pe;
         }
      }
      
      Map<Id,List<Product_Parent_Child_Link__c>> prodLinksMap = pq.getProductLinksByParentMap(prodIds, salesOrg);
      
      Pricebook2 pricebook = new ProductQuery().getPricebookNoCache('testSalesOrg');
      System.assertNotEquals(null,pricebook);
       
      Pricebook2[] pbTests = ProductQuery.getPricebooksSetInCache(new Id[]{pricebook.Id});

      Pricebook2 pbTest2 = new ProductQuery().getPricebook(pricebook.Id);
      System.assertEquals('testSalesOrg', pbTest2.Name);
       
      PricebookEntry pbeTest = new ProductQuery().getEntry(pricebook.Id, testEntry.Id);
      System.assertEquals(testEntry.Id, pbeTest.Id);
      
      Map<Id,Product2> prodMap = ProductQuery.getProdMap(pricebook.Id);
      Assert.isFalse(prodMap.isEmpty());
       
      String cacheKey = ProductQuery.CACHE_KEY+pricebook.Id;
      System.assertNotEquals(null,CacheManager.getOrg(cacheKey));
      // remove from the cache to see if it reselects it
      CacheManager.removeOrg(cacheKey);
      System.assertEquals(null,CacheManager.getOrg(cacheKey));
       
      Pricebook2[] pbs = new ProductQuery().getPricebooks(new String[]{}, new Id[]{pricebook.Id} , new String[]{}, new String[]{});
      System.assertEquals(1,pbs.size());
      System.assertEquals(pricebook.Id, pbs[0].Id);
      // make sure it's back in the cache
      System.assertNotEquals(null,CacheManager.getOrg(cacheKey));
   } // testGetProductLinksByParentMap
    
   static testMethod void testMisc() {
      Pricebook2[] pbs = setupPricebooks();
      User runningUser = UserHelper.getRunningUser();
      //Pricebook2[] testPbs = ProductQuery.getAvailablePricebooks(runningUser,runningUser.Sales_Org__c,runningUser.Sales_Division__c);
       
      Pricebook2[] testPbs2 = new ProductQuery().getPricebooks(null, null, null,null);
      System.assertEquals(0,testPbs2.size());

   } // testMisc
    
    static testMethod void testGetPrimaryPricebook() {
       User usr1 = [Select Id, Name, PilotUser__c, Sales_Org__c, Sales_Division__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null and PilotUser__c=null limit 1];
       User usr2 = [Select Id, Name, PilotUser__c, Sales_Org__c, Sales_Division__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null and PilotUser__c=null
                          and Sales_Division__c != :usr1.Sales_Division__c and Sales_Org__c != :usr1.Sales_Org__c limit 1];
       User usr3 = [Select Id, Name, PilotUser__c, Sales_Org__c, Sales_Division__c 
                      from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Division__c != null 
                       and PilotUser__c != null
                       and Sales_Division__c != :usr1.Sales_Division__c
                       and Sales_Division__c != :usr2.Sales_Division__c limit 1];
       Pricebook2 pb1 = new Pricebook2(Name='testGetPrimaryPricebook1', IsActive=true, Sales_Org__c=usr1.Sales_Org__c, Primary__c=true, Sales_Division__c=usr1.Sales_Division__c+',Division2');
       Pricebook2 pb2 = new Pricebook2(Name='testGetPrimaryPricebook2', IsActive=true, Sales_Org__c=usr2.Sales_Org__c, Primary__c=true);
       Pricebook2 pb3 = new Pricebook2(Name='testGetPrimaryPricebook1', IsActive=true, Sales_Org__c=usr3.Sales_Org__c, Primary__c=true, Sales_Division__c=usr3.Sales_Division__c+'-'+usr3.PilotUser__c);
       insert new Pricebook2[]{pb1,pb2,pb3};
       Pricebook2 checkPb = ProductQuery.getPrimaryPricebook(usr1, usr1.Sales_Org__c, usr1.Sales_Division__c);
       System.assertNotEquals(null,checkPb);
       System.assertEquals(pb1.Id,checkPb.Id);
       checkPb = ProductQuery.getPrimaryPricebook(usr2, usr2.Sales_Org__c, usr2.Sales_Division__c);
       System.assertNotEquals(null,checkPb);
       System.assertEquals(pb2.Id,checkPb.Id);
       checkPb = ProductQuery.getPrimaryPricebook(usr3, null, null);
       System.assertNotEquals(null,checkPb);
       System.assertEquals(pb3.Id,checkPb.Id);
    } // testGetPrimaryPricebook
    
   
} // class ProductQueryTest