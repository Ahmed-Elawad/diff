/* Test methods for the UpdateOrgInfo class.
   
  History
  -------
  02/03/2009 Christophe Soulet   Created by Salesforce.com
  04/27/2012 Dan Carmen          Added field to populate the area number.
  02/18/2013 Dan Carmen          Added logic for the SalesOfficeNumber__c to get populated
  02/27/2017 Dan Carmen          Update both the cost center and sales office number back to the user from the org structure.
  06/15/2017 Dan Carmen          Change to match by Sales Office Number instead of Cost Center.
  11/11/2021 Dan Carmen          Update API, add tests for UserUpdateFromOrgUnitREST
  10/05/2023 Susmitha Somavarapu Commented the Cost Center field code(APR0159472)

  
 */
@isTest
private class UpdateOrgInfoTest {

   static testMethod void testOrgInfoSuccess() {
      Organization_Structure__c orgStrc = new Organization_Structure__c (Name = '8675'
                                                                       ,Area__c = 'Area'
                                                                       ,Core_Area__c = 'CoreArea'
                                                                       ,Zone__c = 'Zone'
                                                                       ,District_Name__c = 'Test Name'
                                                                       ,Sales_Office_Number__c='8676'
                                                                       ,Sales_Org__c='Test'
                                                                       ,CostCenter__c='8676');
      insert orgStrc;
      string idUser = UserInfo.getUserId();
      User testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c from User where ID =: idUser];

      System.runAs(testUser) {
         testUser.District__c = '08675';
         testUser.Sales_Org__c = 'Test';
         testUser.Cost_Center__c = '8675';
         update testUser;
      }
      testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c from User where ID =: idUser];
      System.assertEquals(orgStrc.Area__c,testUser.Areatxt__c);
      System.assertEquals(orgStrc.Zone__c,testUser.Zone__c);
      System.assertEquals(orgStrc.District_Name__c,testUser.District_Name__c);
    //System.assertEquals(orgStrc.CostCenter__c,testUser.Cost_Center__c); Sush
      System.assertEquals(orgStrc.Sales_Office_Number__c,testUser.SalesOfficeNumber__c);
   } // testOrgInfo
    
   static testMethod void testMatchOnSalesOfficeNbr() {
      Organization_Structure__c orgStrc = new Organization_Structure__c (Name = '8675'
                                                                       ,Area__c = 'Area'
                                                                       ,Core_Area__c = 'CoreArea'
                                                                       ,Zone__c = 'Zone'
                                                                       ,District_Name__c = 'Test Name'
                                                                       ,Sales_Office_Number__c='8676'
                                                                       ,Sales_Org__c='Test'
                                                                       ,CostCenter__c='8676');
      insert orgStrc;
      string idUser = UserInfo.getUserId();
      User testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c from User where ID =: idUser];

      System.runAs(testUser) {
         testUser.District__c = '08675';
         testUser.Sales_Org__c = 'Test';
         testUser.Cost_Center__c = '8675';
         testUser.SalesOfficeNumber__c=orgStrc.Sales_Office_Number__c;
         update testUser;
      }
      testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c from User where ID =: idUser];
      System.assertEquals(orgStrc.Area__c,testUser.Areatxt__c);
      System.assertEquals(orgStrc.Zone__c,testUser.Zone__c);
      System.assertEquals(orgStrc.District_Name__c,testUser.District_Name__c);
     // System.assertEquals(orgStrc.CostCenter__c,testUser.Cost_Center__c);Sush
      System.assertEquals(orgStrc.Sales_Office_Number__c,testUser.SalesOfficeNumber__c);
   } // testMatchOnSalesOfficeNbr
    
   static testMethod void testuserinfo(){
      Organization_Structure__c orgstrc = new Organization_Structure__c (Name = '8675'
                                                                        ,Area__c = 'Area'
                                                                        ,Core_Area__c = 'CoreArea'
                                                                        ,Zone__c='Zone'
                                                                        ,District_Name__c = 'Test Name'
                                                                        ,Sales_org__c='Pay');                                                       
      insert orgStrc;
      User testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, Cost_Center__c from User where IsActive=true and Sales_Org__c in :UpdateOrgInfo.checkSalesOrgs limit 1];
      // keep track of the orginal values
      String origArea = testUser.AreaTxt__c;
      String origZone = testUser.Zone__c;
      String origDist = testUser.District_Name__c;
      System.runAs(testUser) {
         // district number is wrong - won't match.
         testUser.District__c = '08676';
         testUser.Sales_Org__c = 'Pay';
         testUser.Cost_Center__c = '8675';
  /*       try {
            update testUser;
            // should not get here.
            System.assertEquals(1,2); 
         } catch ( Exception e) {
         }*/
         testUser = [select Id, Areatxt__c,Core_Area__c,District_Name__c,Zone__c, Sales_Org__c, Cost_Center__c from User where ID =:testUser.Id];
         // values should not have changed.
         System.assertEquals(origArea,testUser.Areatxt__c);
         System.assertEquals(origZone,testUser.Zone__c);
         System.assertEquals(origDist,testUser.District_Name__c); 
      }
   } // testuserinfo 

   static testMethod void testOrgUnits() {
      // get a few users to setup
      User rep1 = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User rep2 = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and UserRoleId != :rep1.UserRoleId limit 1];
      User dsa1 = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_ZSA and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User dsa2 = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_ZSA and Sales_Org__c=:UserHelper.SO_CORE and UserRoleId != :dsa1.UserRoleId limit 1];
       
      //User[] reps = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE limit 2];
      //User[] dsas = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_ZSA and Sales_Org__c=:UserHelper.SO_CORE limit 2];
      System.debug('testOrgUnits reps 1='+rep1.Name+' 2='+rep2.Name);
      System.debug('testOrgUnits dsas 1='+dsa1.Name+' 2='+dsa2.Name);
      
      Org_Unit__c area1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='Area 1', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_AREA);
      Org_Unit__c area2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='Area 2', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_AREA);

      Org_Unit__c zone1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='Zone 1', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_ZONE);
      Org_Unit__c zone2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='Zone 2', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_ZONE);

      Org_Unit__c dist1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='District 1', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT
                                         ,RepUserRoleId__c=rep1.UserRoleId, RepUserRoleName__c=rep1.UserRole.Name
                                         ,UserRoleId__c=dsa1.UserRoleId, UserRoleName__c=dsa1.UserRole.Name
                                         ,OverrideRepUserRoleName__c=true, OverrideUserRoleName__c=true);
      Org_Unit__c dist2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='District 2', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT
                                         ,RepUserRoleId__c=rep2.UserRoleId, RepUserRoleName__c=rep2.UserRole.Name
                                         ,UserRoleId__c=dsa2.UserRoleId, UserRoleName__c=dsa2.UserRole.Name
                                         ,OverrideRepUserRoleName__c=true, OverrideUserRoleName__c=true);

      Org_Unit__c office1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='Sales Office 1', Cost_Center__c='0001', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      Org_Unit__c office2 = new Org_Unit__c(Name='2', Org_Unit_Name__c='Sales Office 2', Cost_Center__c='0002', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_SALES_OFFICE);
      
      Org_Unit__c[] orgUnits = new Org_Unit__c[]{area1,area2,zone1,zone2,dist1,dist2,office1,office2};
      insert orgUnits;
      
      System.assertEquals(1, [select count() from Org_Unit__c where RepUserRoleId__c = :rep1.UserRoleId and UserRoleId__c = :dsa1.UserRoleId]);
      System.assertEquals(1, [select count() from Org_Unit__c where RepUserRoleId__c = :rep2.UserRoleId and UserRoleId__c = :dsa2.UserRoleId]);
      
      zone1.Parent__c=area1.Id;
      zone2.Parent__c=area2.Id;
      dist1.Parent__c=zone1.Id;
      dist2.Parent__c=zone2.Id;
      office1.Parent__c=dist1.Id;
      office2.Parent__c=dist2.Id;
      update orgUnits;
      
      User[] users = new User[]{rep1,rep2,dsa1,dsa2};
      Test.startTest();
      update users;
      Test.stopTest();
      
      Map<Id,User> userMap = new Map<Id,User>([select Id, Name
                                                     ,District_Name__c, District__c
                                                     ,Cost_Center__c, SalesOfficeNumber__c
                                                     ,Zone__c, Zonetxt__c
                                                     ,Areatxt__c, Area_Nbr__c
                                                 From User
                                                Where Id in :users]);
      
      checkUser(userMap.get(rep1.Id),'checking rep 1', 'District 1', '001', '0001', '1', '1', 'Zone 1', '1', 'Area 1');
      checkUser(userMap.get(rep2.Id),'checking rep 2', 'District 2', '002', '0002', '2', '2', 'Zone 2', '2', 'Area 2');
      checkUser(userMap.get(dsa1.Id),'checking dsa 1', 'District 1', '001', '0001', '1', '1', 'Zone 1', '1', 'Area 1');
      checkUser(userMap.get(dsa2.Id),'checking dsa 2', 'District 2', '002', '0002', '2', '2', 'Zone 2', '2', 'Area 2');
      
   } // testOrgUnits
   
   public static void checkUser(User usr, String checkKey, String distName, String distNbr, String ccNbr, String soNbr
                               ,String zoneNbr, String zoneName, String areaNbr, String areaName) {
      System.debug('checkUser checkKey='+checkKey+' usr='+usr.Name);
      System.assertEquals(distName, usr.District_Name__c);
      System.assertEquals(distNbr, usr.District__c);
      
   // System.assertEquals(ccNbr, usr.Cost_Center__c);Sush
      System.assertEquals(soNbr, usr.SalesOfficeNumber__c);

      System.assertEquals(zoneNbr, usr.Zone__c);
      System.assertEquals(zoneName, usr.Zonetxt__c);

      System.assertEquals(areaNbr, usr.Area_Nbr__c);
      System.assertEquals(areaName, usr.Areatxt__c);
      
   } // checkUser
    
   static testMethod void testUserUpdateFromOrgUnitREST() {
      // get a few users to setup
      User[] users = [Select Id, Name, UserRoleId, UserRole.Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE limit 4];
      User rep = users[0];
      User dsa = users[1];
      User userZone = users[2];
      User assistant = users[3];
      System.debug('testOrgUnits rep='+rep.Name+' dsa='+dsa.Name+' userZone='+userZone.Name+' assistant='+assistant.Name);
      
      Org_Unit__c zone1 = new Org_Unit__c(Name='2', Org_Unit_Name__c='Zone 2', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_ZONE
                                            ,UserRoleId__c=userZone.UserRoleId, UserRoleName__c=userZone.UserRole.Name);
      insert zone1;

      Org_Unit__c dist1 = new Org_Unit__c(Name='1', Org_Unit_Name__c='District 1', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c = OrgUnitMethods.TYPE_DISTRICT
                                         ,RepUserRoleId__c=rep.UserRoleId, RepUserRoleName__c=rep.UserRole.Name
                                         ,UserRoleId__c=dsa.UserRoleId, UserRoleName__c=dsa.UserRole.Name
                                         ,Assistant__c=assistant.Id
                                         ,OverrideRepUserRoleName__c=true, OverrideUserRoleName__c=true
                                         ,Parent__c=zone1.Id);

      insert dist1;
       
      UserUpdateFromOrgUnitREST.allowUpdate = true;
      UserUpdateFromOrgUnitREST.testingIdSet.clear();
      // to control the number of users we actually update
      UserUpdateFromOrgUnitREST.testingIdSet.add(rep.Id);
      Test.startTest();
      UserUpdateFromOrgUnitREST.doPost(new Id[]{dist1.Id});
      Test.stopTest();
       
      rep = [Select id, Name, DSA_FSS__c, District_Name__c, Zonetxt__c from User where Id=:rep.Id];
      System.assertEquals(assistant.Id, rep.DSA_FSS__c);
      System.assertEquals(dist1.Org_Unit_Name__c, rep.District_Name__c);
      System.assertEquals(zone1.Org_Unit_Name__c, rep.Zonetxt__c);
      
   } // testUserUpdateFromOrgUnitREST

} // class UpdateOrgInfoTest