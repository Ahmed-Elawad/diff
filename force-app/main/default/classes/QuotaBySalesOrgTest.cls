/* 
 * Test Methods for the QuotaBySalesOrg trigger/class.
 *
 * History
 * -------
 * 10/04/2011 Dan Carmen   Created
   03/05/2012 Dan Carmen   Added Zone and Area checks
   08/01/2014 Dan Carmen   Rewrote to use the Org Unit object
   09/03/2019 Dan Carmen        Fix query to select core sales reps
   11/16/2019 Dan Carmen   Small change to allow tests to pass

*/
@isTest
private class QuotaBySalesOrgTest {

   static testMethod void testQuota() {
      UserRole ur1 = new UserRole(Name='Test Role SALES REP');
      UserRole ur2 = new UserRole(Name='Test Role DISTRICT');
      UserRole ur3 = new UserRole(Name='Test Role ZONE');
      UserRole ur4 = new UserRole(Name='Test Role CORE AVP');
      UserRole[] urs = new UserRole[]{ur1,ur2,ur3,ur4};
      insert urs;
      
      // select sales reps 
      User[] reps = [Select Id, UserRoleId, Name, Sales_Org__c, UserRole.Id, UserRole.Name
                           ,HR_Person_Id__c, District__c, District_Name__c
                       From User
                      Where IsActive=true
                        and HR_Person_Id__c != null
                        and Sales_Org__c = :UserHelper.SO_CORE
                        and Profile.Name like :Utilities.PROF_CORE_SALES+'%'
                        and Job_Name__c = :UserHelper.JOB_REP
                      limit 1];
      System.assertEquals(1,reps.size());
      String districtNbr = Utilities.removeLeadingZero(reps[0].District__c);
      User rep = reps[0];
      System.debug('testQuota user='+rep.Name+' District='+districtNbr);
      User runningUser = UserHelper.getRunningUser();
	
      System.runAs(runningUser) {
      	// create org units
      	Org_Unit__c district = new Org_Unit__c(Name=districtNbr,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Org_Unit_Name__c='Test District 1', Sales_Org__c=UserHelper.SO_CORE
      	                                ,UserRoleId__c=ur2.Id, UserRoleName__c=ur2.Name);
         Org_Unit__c zone = new Org_Unit__c(Name='1',Org_Type__c=OrgUnitMethods.TYPE_ZONE, Org_Unit_Name__c='Test Zone 1', Sales_Org__c=UserHelper.SO_CORE
                                         ,UserRoleId__c=ur3.Id, UserRoleName__c=ur3.Name);
         Org_Unit__c area = new Org_Unit__c(Name='1',Org_Type__c=OrgUnitMethods.TYPE_AREA, Org_Unit_Name__c='Test Area 1', Sales_Org__c=UserHelper.SO_CORE
                                         ,UserRoleId__c=ur4.Id, UserRoleName__c=ur4.Name);
         Org_Unit__c[] orgUnits = new Org_Unit__c[]{district, zone, area};
         insert orgUnits;

         // create single rep record
         Quota_By_Sales_Org__c quotaRep = new Quota_By_Sales_Org__c(Fiscal_Year__c='2014', FY_Month__c=1, Sales_Org__c=UserHelper.SO_CORE,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT,Org_Number__c=districtNbr, HR_Person_Id__c=rep.HR_Person_Id__c);
         insert quotaRep;
         // very results
         quotaRep = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaRep.Id];
         System.assertEquals(rep.Id,quotaRep.User__c);
         System.assertEquals(rep.UserRoleId,quotaRep.UserRoleId__c);
         System.assertEquals(rep.UserRole.Name,quotaRep.UserRole_Name__c);
         System.assertEquals(rep.District_Name__c,quotaRep.Org_Name__c);

         // create single district record
         Quota_By_Sales_Org__c quotaDist = new Quota_By_Sales_Org__c(Fiscal_Year__c='2014', FY_Month__c=1, Sales_Org__c=UserHelper.SO_CORE,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT,Org_Number__c=district.Name);
         insert quotaDist;
         // verify results
         quotaDist = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaDist.Id];
         System.assertEquals(district.UserRoleId__c,quotaDist.UserRoleId__c);
         System.assertEquals(district.UserRoleName__c,quotaDist.UserRole_Name__c);
         System.assertEquals(district.Org_Unit_Name__c,quotaDist.Org_Name__c);
                 
         // create single zone record
         Quota_By_Sales_Org__c quotaZone = new Quota_By_Sales_Org__c(Fiscal_Year__c='2014', FY_Month__c=1, Sales_Org__c=UserHelper.SO_CORE,Org_Type__c=OrgUnitMethods.TYPE_ZONE,Org_Number__c='1');
         insert quotaZone;
         // verify results
         quotaZone = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaZone.Id];
         System.assertEquals(zone.UserRoleId__c,quotaZone.UserRoleId__c);
         System.assertEquals(zone.UserRoleName__c,quotaZone.UserRole_Name__c);
         System.assertEquals(zone.Org_Unit_Name__c,quotaZone.Org_Name__c);
                 
         // create single area record
         Quota_By_Sales_Org__c quotaArea = new Quota_By_Sales_Org__c(Fiscal_Year__c='2014', FY_Month__c=1, Sales_Org__c=UserHelper.SO_CORE,Org_Type__c=OrgUnitMethods.TYPE_AREA,Org_Number__c='1');
         insert quotaArea;
         // verify results
         quotaArea = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaArea.Id];
         System.assertEquals(area.UserRoleId__c,quotaArea.UserRoleId__c);
         System.assertEquals(area.UserRoleName__c,quotaArea.UserRole_Name__c);
         System.assertEquals(area.Org_Unit_Name__c,quotaArea.Org_Name__c);
                 
         // check with bad person id
         Quota_By_Sales_Org__c quotaBad = new Quota_By_Sales_Org__c(Fiscal_Year__c='2014', FY_Month__c=1, Sales_Org__c=UserHelper.SO_CORE,Org_Type__c=OrgUnitMethods.TYPE_DISTRICT,Org_Number__c=district.Name, HR_Person_Id__c='1118675309');
         insert quotaBad;
         // verify results
         quotaBad = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaBad.Id];
         System.assertEquals(null,quotaBad.User__c);
         System.assertEquals(null,quotaBad.UserRoleId__c);
         System.assertEquals(null,quotaBad.UserRole_Name__c);
         System.assertEquals(null,quotaBad.Org_Name__c);
         

      } // System.runAs

      /*
      // set the parents
      ur1.ParentRoleId = ur2.Id;
      ur2.ParentRoleId = ur3.Id;
      ur3.ParentRoleId = ur4.Id;
      update urs;
      
      User[] users = [Select Id, UserRoleId, Name, Sales_Org__c, Cost_Center__c, District__c, District_Name__c
                            ,HR_Person_Id__c
                  from User 
                 where IsActive=true
                   and Profile.Name='System Administrator'
                 limit 4];

      users[0].UserRoleId = ur1.Id;
      users[0].Sales_Org__c = 'TEST';
      users[0].Cost_Center__c = '0123';
      users[0].District__c = '1';
      users[0].District_Name__c = 'Test Name';
      users[1].UserRoleId = ur2.Id;
      users[1].Sales_Org__c = 'TEST';
      users[1].Cost_Center__c = '0123';
      users[1].District__c = '1';
      users[1].District_Name__c = 'Test Name';
      users[1].HR_Person_Id__c = '123456789';
      users[2].UserRoleId = ur3.Id;
      users[2].Sales_Org__c = 'TEST';
      users[2].Cost_Center__c = '0123';
      users[3].UserRoleId = ur4.Id;
      users[3].Sales_Org__c = 'TEST';
      users[3].Cost_Center__c = '0123';
      update users;

      User user0 = users[0];
      User user1 = users[1];

      User user0 = [Select Id, UserRoleId, UserRole.Name, Name, Sales_Org__c, Cost_Center__c, District__c, District_Name__c
                            ,HR_Person_Id__c
                  from User 
                 where Id = :users[0].Id];
      User user1 = [Select Id, UserRoleId, UserRole.Name, Name, Sales_Org__c, Cost_Center__c, District__c, District_Name__c
                            ,HR_Person_Id__c
                  from User 
                 where Id = :users[1].Id];

      // use System.runAs to prevent MIXED DML exception
      System.runAs(user0) {
         // include the test area to have an area
         OrgStrcRole.STRUCT_HAS_AREA.add('TEST');
         Organization_Structure__c os = new Organization_Structure__c(Name='1',District_Name__c = 'Test Name Strc'
                                                                     ,Sales_Office_Number__c='123'
                                                                     ,Zone__c='1', Zone_Name__c='Test Zone 1'
                                                                     ,Area_Number__c='1', Area__c='Test Area 1'
                                                                     ,Sales_Org__c='TEST');
         insert os;
         // check results
         os = [Select Id, Cost_Center__c,District_Name__c
                     ,Zone__c, Zone_Name__c
                     ,Area_Number__c, Area__c
                     ,RoleId_Sales_Office__c,Role_Sales_Office__c
                     ,RoleId_District__c,Role_District__c
                     ,RoleId_Zone__c,Role_Zone__c
                     ,RoleId_Area__c,Role_Area__c
                 From Organization_Structure__c
                where Id = :os.Id];
         System.assertEquals(ur1.Id,os.RoleId_Sales_Office__c);
         System.assertEquals(ur1.Name,os.Role_Sales_Office__c);
         System.assertEquals(ur2.Id,os.RoleId_District__c);
         System.assertEquals(ur2.Name,os.Role_District__c);
         System.assertEquals(ur3.Id,os.RoleId_Zone__c);
         System.assertEquals(ur3.Name,os.Role_Zone__c);
         System.assertEquals(ur4.Id,os.RoleId_Area__c);
         System.assertEquals(ur4.Name,os.Role_Area__c);
         
         // create single rep record
         Quota_By_Sales_Org__c quotaRep = new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=1, Sales_Org__c='TEST',Org_Type__c='District',Org_Number__c='1', HR_Person_Id__c='123456789');
         insert quotaRep;
         // very results
         quotaRep = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaRep.Id];
         System.assertEquals(user1.Id,quotaRep.User__c);
         System.assertEquals(user1.UserRoleId,quotaRep.UserRoleId__c);
         System.assertEquals(user1.UserRole.Name,quotaRep.UserRole_Name__c);
         System.assertEquals(user1.District_Name__c,quotaRep.Org_Name__c);

         // create single district record
         Quota_By_Sales_Org__c quotaDist = new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=1, Sales_Org__c='TEST',Org_Type__c='District',Org_Number__c='1');
         insert quotaDist;
         // verify results
         quotaDist = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaDist.Id];
         System.assertEquals(os.RoleId_District__c,quotaDist.UserRoleId__c);
         System.assertEquals(os.Role_District__c,quotaDist.UserRole_Name__c);
         System.assertEquals(os.District_Name__c,quotaDist.Org_Name__c);
                 
         // create single zone record
         Quota_By_Sales_Org__c quotaZone = new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=1, Sales_Org__c='TEST',Org_Type__c='Zone',Org_Number__c='1');
         insert quotaZone;
         // verify results
         quotaZone = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaZone.Id];
         System.assertEquals(os.RoleId_Zone__c,quotaZone.UserRoleId__c);
         System.assertEquals(os.Role_Zone__c,quotaZone.UserRole_Name__c);
         System.assertEquals(os.Zone_Name__c,quotaZone.Org_Name__c);
                 
         // create single area record
         Quota_By_Sales_Org__c quotaArea = new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=1, Sales_Org__c='TEST',Org_Type__c='Area',Org_Number__c='1');
         insert quotaArea;
         // verify results
         quotaArea = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaArea.Id];
         System.assertEquals(os.RoleId_Area__c,quotaArea.UserRoleId__c);
         System.assertEquals(os.Role_Area__c,quotaArea.UserRole_Name__c);
         System.assertEquals(os.Area__c,quotaArea.Org_Name__c);
                 
         // check with bad person id
         Quota_By_Sales_Org__c quotaBad = new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=1, Sales_Org__c='TEST',Org_Type__c='District',Org_Number__c='1', HR_Person_Id__c='1118675309');
         insert quotaBad;
         // verify results
         quotaBad = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quotaBad.Id];
         System.assertEquals(null,quotaBad.User__c);
         System.assertEquals(null,quotaBad.UserRoleId__c);
         System.assertEquals(null,quotaBad.UserRole_Name__c);
         System.assertEquals(null,quotaBad.Org_Name__c);
         
         Quota_By_Sales_Org__c[] quotaReps = new Quota_By_Sales_Org__c[]{};
         Quota_By_Sales_Org__c[] quotaDists = new Quota_By_Sales_Org__c[]{};
         
         // create multiple records - to test bulk 
         // add records for the rest of the fiscal year
         for (Integer cnt=2; cnt<= 12; cnt++) {
            quotaReps.add(new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=cnt, Sales_Org__c='TEST',Org_Type__c='District',Org_Number__c='1', HR_Person_Id__c='123456789'));
            quotaDists.add(new Quota_By_Sales_Org__c(Fiscal_Year__c='2012', FY_Month__c=cnt, Sales_Org__c='TEST',Org_Type__c='District',Org_Number__c='1'));
         }
         Quota_By_Sales_Org__c[] quotas = new Quota_By_Sales_Org__c[]{};
         quotas.addAll(quotaReps);
         quotas.addAll(quotaDists);
         insert quotas;
         
         // verify all results
         for (Quota_By_Sales_Org__c quota : quotaReps) {
            quota = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quota.Id];
            System.assertEquals(user1.Id,quota.User__c);
            System.assertEquals(user1.UserRoleId,quota.UserRoleId__c);
            System.assertEquals(user1.UserRole.Name,quota.UserRole_Name__c);
            System.assertEquals(user1.District_Name__c,quota.Org_Name__c);
         }

         for (Quota_By_Sales_Org__c quota : quotaDists) {
            quota = [Select Id, Org_Number__c, Org_Name__c, User__c, UserRoleId__c, UserRole_Name__c from Quota_By_Sales_Org__c where Id = :quota.Id];
            System.assertEquals(os.RoleId_District__c,quota.UserRoleId__c);
            System.assertEquals(os.Role_District__c,quota.UserRole_Name__c);
            System.assertEquals(os.District_Name__c,quota.Org_Name__c);
         } // for        
      } // System.runAs
      */
   } // testQuota
   
} // class QuotaBySalesOrgTest