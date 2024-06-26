/* 
 * Test methods for the OrgStrcRole trigger and class
 *
 * History
 * -------
 * 09/14/2011 Dan Carmen   Created
   03/05/2012 Dan Carmen   Added logic to populate zone and area role information
   07/17/2012 Dan Carmen   Added change to order of profile check
   02/15/2013 Dan Carmen   Logic to populate the Cost Center field from the Sales Office Number if not populated
 *
 */
@isTest
private class OrgStrcRoleTest {

   static testMethod void testRoleSetup() {
       
      UserRole[] roles = [Select Id, Name from UserRole limit 20];
       
       
       
      Organization_Structure__c os1 = new Organization_Structure__c(Name='2',Sales_Org__c='TEST'
                                                                   ,Sales_Office_Number__c='2',Role_Sales_Office__c=roles[0].Name, RoleId_Sales_Office__c=null
                                                                   ,District_Name__c='TEST1', Role_District__c=roles[1].Name, RoleId_District__c=null
                                                                   ,Zone__c='1', Zone_Name__c='Zone1', Role_Zone__c=roles[2].Name, RoleId_Zone__c=null
                                                                   ,Area_Number__c='1',Area__c='Area1', Role_Area__c=roles[3].Name, RoleId_Area__c=null);
      Organization_Structure__c os2 = new Organization_Structure__c(Name='3',Sales_Org__c='TEST'
                                                                   ,Sales_Office_Number__c='3',Role_Sales_Office__c=roles[4].Name, RoleId_Sales_Office__c=null
                                                                   ,District_Name__c='TEST2', Role_District__c=roles[4].Name, RoleId_District__c=null
                                                                   ,Zone__c='1', Zone_Name__c='Zone1', Role_Zone__c=roles[5].Name, RoleId_Zone__c=null
                                                                   ,Area_Number__c='1',Area__c='Area1', Role_Area__c=roles[6].Name, RoleId_Area__c=null);

       
      Organization_Structure__c[] strcs = new Organization_Structure__c[]{os1,os2};
      insert strcs;

      Map<Id,Organization_Structure__c> strcMap = new Map<Id,Organization_Structure__c>([Select Id, Name,Sales_Org__c
                                                                   ,Sales_Office_Number__c,Role_Sales_Office__c, RoleId_Sales_Office__c
                                                                   ,District_Name__c, Role_District__c, RoleId_District__c
                                                                   ,Zone__c, Zone_Name__c, Role_Zone__c, RoleId_Zone__c
                                                                   ,Area_Number__c,Area__c, Role_Area__c, RoleId_Area__c
                                                                    From Organization_Structure__c]);
      os1 = strcMap.get(os1.Id);
      System.assertEquals(roles[0].Id, os1.RoleId_Sales_Office__c);
      System.assertEquals(roles[1].Id, os1.RoleId_District__c);
      System.assertEquals(roles[2].Id, os1.RoleId_Zone__c);
      System.assertEquals(roles[3].Id, os1.RoleId_Area__c);
       
      // test a bad case to hit the errors
      Organization_Structure__c os3 = new Organization_Structure__c(Name='3',Sales_Org__c='TEST'
                                                                   ,Sales_Office_Number__c='3',Role_Sales_Office__c='BadRole1', RoleId_Sales_Office__c=roles[0].Id
                                                                   ,District_Name__c='TEST2', Role_District__c='BadRole2', RoleId_District__c=roles[0].Id
                                                                   ,Zone__c='1', Zone_Name__c='Zone1', Role_Zone__c='BadRole3', RoleId_Zone__c=roles[0].Id
                                                                   ,Area_Number__c='1',Area__c='Area1', Role_Area__c='BadRole4', RoleId_Area__c=roles[0].Id);
       insert os3;
       // make sure role ids are cleared out because the names are bad;
       strcMap = new Map<Id,Organization_Structure__c>([Select Id, Name,Sales_Org__c
                                                                   ,Sales_Office_Number__c,Role_Sales_Office__c, RoleId_Sales_Office__c
                                                                   ,District_Name__c, Role_District__c, RoleId_District__c
                                                                   ,Zone__c, Zone_Name__c, Role_Zone__c, RoleId_Zone__c
                                                                   ,Area_Number__c,Area__c, Role_Area__c, RoleId_Area__c
                                                                    From Organization_Structure__c]);
       os3 = strcMap.get(os3.Id);
       System.assertEquals(null,os3.RoleId_Sales_Office__c);
       System.assertEquals(null,os3.RoleId_District__c);
       System.assertEquals(null,os3.RoleId_Zone__c);
       System.assertEquals(null,os3.RoleId_Area__c);
       
   } // testCostCenter

} // class OrgStrcRoleTest