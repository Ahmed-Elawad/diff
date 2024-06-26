/* Test Methods for the TerritoryManager class

  History
  -------
  11/30/2023 Dan Carmen        Created
  01/22/2024 Dan Carmen        Run as batch job
  02/15/2024 Dan Carmen        Set forecast manager when available
  
 */
@isTest
public class TerritoryManagerTest {
   @testSetup
   public static void setupData() {
      setupTestModel();
   } // setupData
   
   public static void setupTestModel() {
      Territory2Model terrModel = new Territory2Model(Name='TerritoryManagerTestModel', DeveloperName='TerritoryManagerTestModel');
      insert terrModel;
   } // setupTestModel
    
   public static Territory2Model getTestModel() {
      Territory2Model terrModel = [Select Id, Name, State from Territory2Model where Name='TerritoryManagerTestModel'];
      System.debug('getTestModel terrModel='+terrModel);
      return terrModel;
   } // getTestModel
    
   static testMethod void testTerritorySetup(){
      SalesOrg__c salesOrgCs = new SalesOrg__c(Name='PAY', UseInTerritoryManagement__c=true);
      insert salesOrgCs;
       
      Territory2Model model = getTestModel();
      System.debug('testTerritorySetup model='+model);
      TerritoryManager.TERR_STATE=model.State;
      Territory2Model terrModel = getTestModel();
       
      User[] dsms = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSM and ForecastEnabled=true limit 4];
      // to make sure it doesn't fail if the dsm doesn't have Forecasting
      User[] dsms2 = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSM and ForecastEnabled=false limit 1];
      User[] dsas = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA and ForecastEnabled=true limit 4];
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and ForecastEnabled=true limit 8];
      Org_Unit__c division = new Org_Unit__c(Name='PAY', Org_Unit_Name__c='PAY', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_DIVISION);
      insert division;
      Org_Unit__c area1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='EAST', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_AREA, Parent__c=division.Id);
      Org_Unit__c area2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='WEST', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_AREA, Parent__c=division.Id);
      insert new Org_Unit__c[]{area1,area2};
      
      Org_Unit__c zone1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='ZONE 1', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Parent__c=area1.Id);
      Org_Unit__c zone2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='ZONE 2', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Parent__c=area1.Id);
      Org_Unit__c zone3 = new Org_Unit__c(Name='3', Org_Unit_Name__c='ZONE 3', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Parent__c=area2.Id);
      Org_Unit__c zone4 = new Org_Unit__c(Name='4', Org_Unit_Name__c='ZONE 4', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Parent__c=area2.Id);
      insert new Org_Unit__c[]{zone1,zone2,zone3,zone4};
          
      Org_Unit__c dist1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='DISTRICT 1', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Parent__c=zone1.Id
                                              ,Assistant__c=dsas[0].Id, Manager__c=dsms[0].Id);
      Org_Unit__c dist2 = new Org_Unit__c(Name='1', Org_Unit_Name__c='DISTRICT 2', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Parent__c=zone2.Id
                                              ,Assistant__c=dsas[1].Id, Manager__c=dsms[1].Id);
      Org_Unit__c dist3 = new Org_Unit__c(Name='1', Org_Unit_Name__c='DISTRICT 3', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Parent__c=zone3.Id
                                              ,Assistant__c=dsas[2].Id, Manager__c=dsms[2].Id);
      Org_Unit__c dist4 = new Org_Unit__c(Name='1', Org_Unit_Name__c='DISTRICT 4', Sales_Org__c='PAY', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Parent__c=zone4.Id
                                              ,Assistant__c=dsas[3].Id, Manager__c=dsms2[0].Id);
      insert new Org_Unit__c[]{dist1,dist2,dist3,dist4};
      
      ZipTerritory__c zipTerr1a = new ZipTerritory__c(Name=reps[0].Name, TerritoryRep__c=reps[0].Id, District__c=dist1.Id);
      ZipTerritory__c zipTerr1b = new ZipTerritory__c(Name=reps[1].Name, TerritoryRep__c=reps[1].Id, District__c=dist1.Id);
      ZipTerritory__c zipTerr2a = new ZipTerritory__c(Name=reps[2].Name, TerritoryRep__c=reps[2].Id, District__c=dist2.Id);
      ZipTerritory__c zipTerr2b = new ZipTerritory__c(Name=reps[3].Name, TerritoryRep__c=reps[3].Id, District__c=dist2.Id);
      ZipTerritory__c zipTerr3a = new ZipTerritory__c(Name=reps[4].Name, TerritoryRep__c=reps[4].Id, District__c=dist3.Id);
      ZipTerritory__c zipTerr3b = new ZipTerritory__c(Name=reps[5].Name, TerritoryRep__c=reps[5].Id, District__c=dist3.Id);
      ZipTerritory__c zipTerr4a = new ZipTerritory__c(Name=reps[6].Name, TerritoryRep__c=reps[6].Id, District__c=dist4.Id);
      ZipTerritory__c zipTerr4b = new ZipTerritory__c(Name=reps[7].Name, TerritoryRep__c=reps[7].Id, District__c=dist4.Id);
      insert new ZipTerritory__c[]{zipTerr1a,zipTerr1b,zipTerr2a,zipTerr2b,zipTerr3a,zipTerr3b,zipTerr4a,zipTerr4b};
      
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         Test.startTest();
         Database.executeBatch(new TerritoryManager(),1);
         //TerritoryManager.checkSalesOrg('PAY');
         Test.stopTest();
      }
       
      Territory2[] terrs = [Select Id, Name, ParentTerritory2Id, SegmentName__c, OrgUnitId__c, ZipTerritoryId__c, SalesOrg__c
                                  ,ForecastUserId
                              from Territory2 where Territory2ModelId=:terrModel.Id];
      Assert.areEqual(19, terrs.size());
      Map<Id, Territory2> terrMapByOrgId = new Map<Id,Territory2>();
      for (Territory2 terr : terrs) {
         if (terr.ZipTerritoryId__c != null) {
            terrMapByOrgId.put(terr.ZipTerritoryId__c, terr);
         } else if (terr.OrgUnitId__c != null) {
            terrMapByOrgId.put(terr.OrgUnitId__c, terr);
         }
      }
      Assert.areEqual(19, terrMapByOrgId.size());
      // TODO - check individual records?
      Territory2 terrDist1 = terrMapByOrgId.get(dist1.Id);
      Assert.areEqual(dist1.Manager__c, terrDist1.ForecastUserId);
      Territory2 terrDist2 = terrMapByOrgId.get(dist2.Id);
      Assert.areEqual(dist2.Manager__c, terrDist2.ForecastUserId);
      Territory2 terrDist3 = terrMapByOrgId.get(dist3.Id);
      Assert.areEqual(dist3.Manager__c, terrDist3.ForecastUserId);
      // the dsm for this district does not have forecasting set
      Territory2 terrDist4 = terrMapByOrgId.get(dist4.Id);
      Assert.isNull(terrDist4.ForecastUserId);

      Map<Id,Territory2> terrMap = new Map<Id,Territory2>(terrs);
      Assert.areEqual(16, [Select count() from UserTerritory2Association where Territory2Id in :terrMap.keySet()]);
   } // testTerritorySetup
    
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testTerritoryManager', new TerritoryManager());
   } // testScheduler

   
} // class TerritoryManagerTest