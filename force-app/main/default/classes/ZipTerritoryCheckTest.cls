/** Test Methods for ZipTerritoryCheck
 *
 * History
 * -------
 * 10/22/2014 Dan Carmen        Created.
   01/18/2017 Dan Carmen        Changes to allow the code to run in production.
 *
 */
@isTest
private class ZipTerritoryCheckTest {

   static testMethod void territoryCheckTest() {
      User u1 = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.REP_PROFS limit 1];
      User u2 = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name in :Utilities.REP_PROFS and Id != :u1.Id limit 1];

   	Org_Unit__c district = new Org_Unit__c(Name='12',Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Org_Unit_Name__c='Test', Sales_Org__c=UserHelper.SO_CORE
   	                                      ,Assistant__c=u1.Id);
   	insert district;
   	
      ZipTerritory__c terr = new ZipTerritory__c(Name='Test',TerritoryRep__c=null, Rep_Name__c=u1.Name, District__c=district.Id);
      insert terr;
      
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name='12345',User__c=u2.Id, Rep_Name__c=u2.Name, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr.Id);
      insert za1;
      za1 = [Select Id, Name, User__c, Rep_Name__c, HR_Person_Id__c, Sales_Org__c, NeedsUpdate__c from Zip_Assignment__c where Id=:za1.Id];
      System.assertEquals(true,za1.NeedsUpdate__c);
      
      Test.startTest();
      ZipTerritoryCheck.EVALUATE_TERRITORY_REP = true;
      Database.executeBatch(new ZipTerritoryCheck(), 1);
      Test.stopTest();
      
      terr = [Select Id, Name, TerritoryRep__c, Rep_Name__c, District__c from ZipTerritory__c where Id=:terr.Id];
      System.assertEquals(u1.Id, terr.TerritoryRep__c);
   
      za1 = [Select Id, Name, User__c, Rep_Name__c, HR_Person_Id__c, Sales_Org__c, NeedsUpdate__c from Zip_Assignment__c where Id=:za1.Id];
      System.assertEquals(false,za1.NeedsUpdate__c);
   
   } // territoryCheckTest
    
   static testMethod void testScheduler() {
      TestHelper.testScheduler('ZipTerritoryCheckTest', new ZipTerritoryCheck());
   } // testScheduler


} // class ZipTerritoryCheckTes