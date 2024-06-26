/* 
 * Test Methods for the ProductMapping trigger and class
 *
 * History
 * -------
 * 10/20/2011 Dan Carmen   Created
   08/10/2012 Dan Carmen   Modified getMapping method
   10/03/2012 Dan Carmen   Added check in for Sales Org.
   07/30/2015 Dan Carmen   Change to handle pilot users
 *
 */
@isTest
public class ProductMappingTest {

   @istest(SeeAllData=false)
   static void testOtherCases() {
      // test no data
      Product_Mapping__c pm1 = new Product_Mapping__c();
      insert pm1;
      pm1 = getMapping(pm1.Id);
      System.assertEquals(null,pm1.Parent_Product__c);
      System.assertEquals(null,pm1.Product__c);
      
      // test no pricebook - doesn't matter that product is bad because won't get to that point.
      Product_Mapping__c pm2 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg',Product_Code__c='TestProductCode');
      try {
         insert pm2;
         // should not get here
         System.assertEquals('Should not','get here');
      } catch (Exception e) {
         // should get here
         System.assertEquals(1,1);
      }
      // no id because insert should fail
      System.assertEquals(null,pm2.Id);
      
      // create some testing products
      String[] prodNames = new String[]{'ProdTest1','ProdTest2'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      // valid pricebook, valid product, no parent
      Product_Mapping__c pm3 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg',Product_Code__c=entries.get(0).Product2.ProductCode);
      insert pm3;
      pm3 = getMapping(pm3.Id);
      System.assertEquals(entries.get(0).Product2Id,pm3.Product__c);
      System.assertEquals(entries.get(0).Id, pm3.PricebookEntryId__c);
      
   } // testOtherCases
   
   private static Product_Mapping__c getMapping(Id pmId) {
      Product_Mapping__c pm = [Select Id, Sales_Org__c, Product_Code__c, Product__c, Parent_Product_Code__c, Parent_Product__c
                                     ,PricebookEntryId__c, Parent_PricebookEntryId__c, Product_Parent_Child_Link__c
                                 from Product_Mapping__c
                                where Id = :pmId];      
      return pm;
   } // getMapping
   
   @istest(SeeAllData=false)
   static void testProductMapping() {
      // create pricebooks and products for testing
      String[] prodNames = new String[]{'ProdTest1','ProdTest2','ProdTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry child = entries.get(0);
      PricebookEntry parent = entries.get(1);
      PricebookEntry otherProd = entries.get(2);
      Product_Parent_Child_Link__c ppcl = new Product_Parent_Child_Link__c(Child_Product_Code__c=child.Product2.ProductCode
                         ,Parent_Product_Code__c = parent.Product2.ProductCode, Sales_Org__c = 'TestSalesOrg');
      insert ppcl;
    
      // no data on the record
      Product_Mapping__c pm1 = new Product_Mapping__c();
      // invalid product
      Product_Mapping__c pm2 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c='Invalid Product Code');
      // valid product
      Product_Mapping__c pm3 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=child.Product2.ProductCode);
      // valid product, invalid parent
      Product_Mapping__c pm4 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=child.Product2.ProductCode, Parent_Product_Code__c='Invalid Parent Product Code');
      // valid product, valid parent, no parent-child link
      Product_Mapping__c pm5 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=child.Product2.ProductCode, Parent_Product_Code__c=otherProd.Product2.ProductCode);
      // valid product, valid parent, valid parent-child link
      Product_Mapping__c pm6 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=child.Product2.ProductCode, Parent_Product_Code__c=parent.Product2.ProductCode);
      // invalid product, valid parent
      Product_Mapping__c pm7 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c='Invalid Product Code', Parent_Product_Code__c=parent.Product2.ProductCode);
      
      Product_Mapping__c[] mappings = new Product_Mapping__c[]{pm1,pm2,pm3,pm4,pm5,pm6,pm7};
      List<Database.saveResult> uResults = Database.insert(mappings,false);
      // verify results
      Database.saveResult res1 = uResults.get(0);
      System.assertEquals(true,res1.isSuccess());
      pm1 = getMapping(pm1.id);
      System.assertEquals(null,pm1.Product__c);
      
      Database.saveResult res2 = uResults.get(1);
      System.assertEquals(false,res2.isSuccess());

      Database.saveResult res3 = uResults.get(2);
      System.assertEquals(true,res3.isSuccess());
      pm3 = getMapping(pm3.Id);
      System.assertEquals(child.Product2Id,pm3.Product__c);
      System.assertEquals(child.Id,pm3.PricebookEntryId__c);
      System.assertEquals(null,pm3.Parent_Product__c);
      System.assertEquals(null,pm3.Parent_PricebookEntryId__c);
      System.assertEquals(null,pm3.Product_Parent_Child_Link__c);

      Database.saveResult res4 = uResults.get(3);
      System.assertEquals(false,res4.isSuccess());
      
      Database.saveResult res5 = uResults.get(4);
      System.assertEquals(true,res5.isSuccess());
      pm5 = getMapping(pm5.Id);
      System.assertEquals(child.Product2Id,pm5.Product__c);
      System.assertEquals(child.Id,pm5.PricebookEntryId__c);
      System.assertEquals(otherProd.Product2Id,pm5.Parent_Product__c);
      System.assertEquals(otherProd.Id,pm5.Parent_PricebookEntryId__c);
      System.assertEquals(null,pm5.Product_Parent_Child_Link__c);

      Database.saveResult res6 = uResults.get(5);
      System.assertEquals(true,res6.isSuccess());
      pm6 = getMapping(pm6.Id);
      System.assertEquals(child.Product2Id,pm6.Product__c);
      System.assertEquals(child.Id,pm6.PricebookEntryId__c);
      System.assertEquals(parent.Product2Id,pm6.Parent_Product__c);
      System.assertEquals(parent.Id,pm6.Parent_PricebookEntryId__c);
      System.assertEquals(ppcl.Id,pm6.Product_Parent_Child_Link__c);

      Database.saveResult res7 = uResults.get(6);
      System.assertEquals(false,res7.isSuccess());
   } // testProductMapping
   
   /** in case it's needed for testing, clear out the mapping table for a certain type.
    */
   public static void clearMappingByType(String mappingType) {
      delete [Select Id from Product_Mapping__c where Type__c=:mappingType];
      
   } // clearMappingByType
   
   /** Verify that the mapping type is setup for testing.
    */
   public static void verifyMappingSetup(String mappingType, String mappingKey, String productCode, String salesOrg) {
      Integer cnt = [select count() from Product_Mapping__c where Type__c=:mappingType 
                                                              and Product_Code__c=:productCode
                                                              and Mapping_Key__c=:mappingKey
                                                              and Sales_Org__c=:salesOrg];
      if (cnt == 0) {
         // create a record if it doesn't exist
         Product_Mapping__c mapping = new Product_Mapping__c(Type__c=mappingType 
                                                             ,Product_Code__c=productCode
                                                             ,Mapping_Key__c=mappingKey
                                                             ,Sales_Org__c=salesOrg);
         insert mapping;
      }
   } // verifyMappingSetup
   
   @istest(SeeAllData=false)
   static void testGetMapping() {
      // create pricebooks and products for testing
      String[] prodNames = new String[]{'ProdTest1','ProdTest2','ProdTest3'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry prod1 = entries.get(0);
      PricebookEntry prod2 = entries.get(1);
      PricebookEntry prod3 = entries.get(2);
      
      Product_Mapping__c pm1 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=prod1.Product2.ProductCode, Type__c='Oppty-Referral',Mapping_Key__c='ProdTest1');
      Product_Mapping__c pm2 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=prod2.Product2.ProductCode, Type__c='Oppty-Referral',Mapping_Key__c='ProdTest2');
      Product_Mapping__c pm3 = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c=prod3.Product2.ProductCode, Type__c='Oppty-Referral',Mapping_Key__c='ProdTest3');
      Product_Mapping__c[] pms = new Product_Mapping__c[]{pm1,pm2,pm3};
      insert pms;
      
      // test bad data
      System.assertEquals(null,ProductMapping.getMapping('BadKey', 'BadMappingType', 'BadSalesOrg'));
      // test good record.
      Product_Mapping__c testPm = ProductMapping.getMapping('ProdTest1','Oppty-Referral','TestSalesOrg');
      System.assertEquals(pm1.Id,testPm.Id);
      
      // get multiple records - add extra values to make sure they don't hurt anything - should just be ignored.
      String[] mappingKeys = new String[]{'ProdTest1','ProdTest2','ProdTest3','ProdTest4'};
      String[] salesOrgs = new String[]{'TestSalesOrg','TestSalesOrg2'};
      Product_Mapping__c[] testPms = ProductMapping.getMappings(mappingKeys, 'Oppty-Referral', salesOrgs);
      // should be the three records returned.
      System.assertEquals(3,testPms.size());
   } // testGetMapping
   
   @istest(SeeAllData=false)
   static void testNoProducts() {
      Product_Mapping__c pm = new Product_Mapping__c(Sales_Org__c='TestSalesOrg', Product_Code__c='Invalid Product Code');
      // this should fail - no product found
      Boolean fails = false;
      try {
         insert pm;
      } catch (Exception e) {
         fails = true;
      }
      System.assertEquals(true,fails);
      pm.DoNotRequireProduct__c = true;
      insert pm;
      System.assertEquals(true, pm.Id != null);
   } // testNoProducts
   
   @isTest
   static void testGetSalesOrg() {
      // select 2 users
      ProductMapping.CHECK_USER = true;
      User[] users = [Select Id, Name, PilotUser__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and PilotUser__c=null limit 2];
      User usr1 = users[0];
      User usr2 = users[1];
      usr2.PilotUser__c='test';
      
      String testSalesOrg = ProductMapping.getSalesOrg(RecordTypeHelper.CORE_ACCOUNT, usr1);
      System.assertEquals(UserHelper.SO_CORE,testSalesOrg);
      
      testSalesOrg = ProductMapping.getSalesOrg(RecordTypeHelper.CORE_ACCOUNT, usr2);
      System.assertEquals(UserHelper.SO_CORE+'-test',testSalesOrg);
   } // testGetSalesOrg
   
   static testMethod void testDefaultProds() {
      OpptyProductsTest.setupDefaultProd();
      ProductMapping.MappingWrapper mapWrap = ProductMapping.getDefaultMappings();
      
   } // testDefaultProds
   
} // class ProductMappingTest