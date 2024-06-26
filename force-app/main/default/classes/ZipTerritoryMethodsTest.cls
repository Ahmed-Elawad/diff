/* 
 Test methods for the ZipTerritoryMethods class
     
  History
  -------
  01/31/2014 Dan Carmen   Created
  04/01/2015 Cindy Freeman    added test for override updates 
  04/05/2016 Dan Carmen       Updates for testing
  05/25/2021 Dan Carmen       Moved logic to a queueable to be able to handle larger number of zip assignments.
  02/08/2024 Dan Carmen       Try to force the change record creation

*/
@isTest
private class ZipTerritoryMethodsTest {
    
   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c  abc1 = new Apex_Batch_Control__c(Name=ZipTerritoryQueueable.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=100, Minutes_till_Launch__c=1);
      Apex_Batch_Control__c[] abcs = new Apex_Batch_Control__c[]{abc1};
      insert abcs;
   } // setupData

   // Check that the zip assignments get updated if the connected territory gets updated.
   static testMethod void testTerritoryUpdate() {
      UserHelperTest.setupSalesOrgSetting();
      // select a couple of test users
      User[] users = [Select Id, Name from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 2];
      // create a territory and zip assignments based on the first user
      Org_Unit__c district = new Org_Unit__c(Name='1',Sales_Org__c=UserHelper.SO_CORE, Org_Type__c='District',Org_Unit_Name__c='Test District');
      insert district;
      
      ZipTerritory__c territory = new ZipTerritory__c(District__c=district.Id, Name='Territory 1',TerritoryRep__c=users[0].Id, Territory_Nbr__c='1');
      insert territory;
      
      ZipCheckOwnerTest.setupSegments();

      Zip_Assignment__c[] zipAssigns = new Zip_Assignment__c[]{};
      
      for (Integer cnt=0; cnt<10; cnt++) {
         Zip_Assignment__c za = ZipCheckOwnerTest.createZa('1111'+cnt, null, 0, 100, UserHelper.SO_CORE, ZipCheckOwnerTest.coreSeg1.Name, ZipCheckOwnerTest.coreSeg1.Id, territory, null, zipAssigns);

      } // for (Integer
      // so it doesn't create initial change records and we can make sure they're created later
      ZipAssignment.SKIP_TRIGGER = true;
      insert zipAssigns;
      System.assertEquals(0,[select count() from Zip_Assignment_Change__c]);
      ZipAssignment.SKIP_TRIGGER = false;

      // verify zip assignments match
      System.assertEquals(10,[select count() from Zip_Assignment__c where ZipTerritory__c=:territory.Id]);         
                                             
      // update the territory. Ensure that change/request records are created
      territory.TerritoryRep__c = users[1].Id;
      territory.Rep_Name__c = users[1].Name;
      System.debug('testTerritoryUpdate before update territory');
      Test.startTest();
      update territory;
      Test.stopTest();
      
      // verify zip assignments match
      System.assertEquals(10,[select count() from Zip_Assignment__c where ZipTerritory__c=:territory.Id]);         
      System.assertEquals(10,[select count() from Zip_Assignment__c where ZipTerritory__c=:territory.Id and User__c=:territory.TerritoryRep__c]);         

      Integer nbrChanges = [select count() from Zip_Assignment_Change__c];
      Assert.isTrue(nbrChanges >= zipAssigns.size(),'nbrChanges='+nbrChanges+' zipAssigns='+zipAssigns.size());

   } // testTerritoryUpdate
   
   
   // Check override update
   static testMethod void testOverrideUpdate() {
      // select a couple of test users
      User[] users = [Select Id, Name from User where Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 5];
      // create a territory and zip assignments based on the first user
      Org_Unit__c district = new Org_Unit__c(Name='1',Sales_Org__c=UserHelper.SO_CORE, Org_Type__c='District',Org_Unit_Name__c='Test District');
      insert district;
      
      ZipTerritory__c territory = new ZipTerritory__c(District__c=district.Id, Name='Territory 1',TerritoryRep__c=users[0].Id, Territory_Nbr__c='1',
                        OverrideAssistant__c=users[1].Id, OverrideManager__c = users[2].Id);
      insert territory;
      
      territory.OverrideAssistant__c = users[3].Id;
      territory.OverrideManager__c = users[4].Id;
      update territory;
      
   } // testOverrideUpdate
    
   static testMethod void testMisc() {
      Org_Unit__c district = new Org_Unit__c(Name='1',Sales_Org__c=UserHelper.SO_CORE, Org_Type__c='District',Org_Unit_Name__c='Test District');
      insert district;
      ZipTerritory__c territory = new ZipTerritory__c(Name='Territory 1',Territory_Nbr__c='1', Rep_Name__c='Test Name', District__c=district.Id);
      // this is to get code coverage in the trigger.
      ZipTerritoryMethods.SKIP_TRIGGER=true;
      insert territory;
   }
   
} // class ZipTerritoryMethodsTest