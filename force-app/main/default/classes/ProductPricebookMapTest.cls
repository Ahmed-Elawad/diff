/* 
  Testmethods for the ProductPricebookMap Trigger and Class
   
  History
  -------
  06/16/2011 Dan Carmen   Created
  10/26/2018 Dan Carmen   Increment API to version 44
   
 */
@isTest
public class ProductPricebookMapTest {

   static testMethod void testRecords() {
   	  // setup test data
      Pricebook2 pb1 = new Pricebook2(Name='ProductPricebookMapTest1', IsActive=true);
      Pricebook2 pb2 = new Pricebook2(Name='ProductPricebookMapTest2', IsActive=true);
      Pricebook2 pb3 = new Pricebook2(Name='ProductPricebookMapTest3', IsActive=false);
      Pricebook2[] pbs = new Pricebook2[]{pb1,pb2,pb3};
      insert pbs;
      
      Product_Pricebook_Map__c ppm = new Product_Pricebook_Map__c(Name='Test1',Sales_Org__c='ProductPricebookMapTest',Pricebook_Name__c=pb1.Name);
      insert ppm;
      // verify the id field is set
      ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c, Pricebook_Id__c from Product_Pricebook_Map__c where Id = :ppm.Id];
      System.assertEquals(pb1.Id,ppm.Pricebook_Id__c);
      
      // test the update
      ppm.Pricebook_Name__c = pb2.Name;
      ppm.Pricebook_Id__c = null;
      update ppm;
      
      // verify the id field is set
      ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c, Pricebook_Id__c from Product_Pricebook_Map__c where Id = :ppm.Id];
      System.assertEquals(pb2.Id,ppm.Pricebook_Id__c);
      
      // update to bad name - verify id field is null
      ppm.Pricebook_Name__c = 'BlaBlaBla';
      ppm.Pricebook_Id__c = null;
      update ppm;

      // verify the id field is not set
      ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c, Pricebook_Id__c from Product_Pricebook_Map__c where Id = :ppm.Id];
      System.assertEquals(null,ppm.Pricebook_Id__c);
      
      // check setting to inactive pricebook
      ppm.Pricebook_Name__c = pb3.Name;
      ppm.Pricebook_Id__c = null;
      update ppm;
      
      // verify the id field is set
      ppm = [Select Id, Name, Sales_Org__c, Pricebook_Name__c, Pricebook_Id__c from Product_Pricebook_Map__c where Id = :ppm.Id];
      System.assertEquals(pb3.Id,ppm.Pricebook_Id__c);
      
   } // testRecords
    
   /** Verify that the mapping type is setup for testing.
    */
   public static void verifyMappingSetup(String mapName, String pricebookName, String salesOrg) {
      Integer cnt = [select count() from Product_Pricebook_Map__c where Pricebook_Name__c=:pricebookName
                                                              and Sales_Org__c=:salesOrg];
      if (cnt == 0) {
         // create a record if it doesn't exist
         Product_Pricebook_Map__c mapping = new Product_Pricebook_Map__c(Name=mapName 
                                                              ,Pricebook_Name__c=pricebookName
                                                              ,Sales_Org__c=salesOrg);
         insert mapping;
      }
   } // verifyMappingSetup

} // class ProductPricebookMapTest