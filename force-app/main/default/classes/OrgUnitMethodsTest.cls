/* Test methods for the OrgUnitMethods class.
   
  History
  -------
  04/11/2012 Dan Carmen   Created
  06/19/2012 Dan Carmen   Added update to the OrgUnitBefore trigger.
  03/15/2013 Dan Carmen   Added methods to build out the org structure into a true hierarchy.
  07/18/2013 Dan Carmen   Fix linking of users at district level
  11/23/2015 Dan Carmen   Change to be able to create a default area for a structure.
  11/21/2016 Dan Carmen   Select Org units based on user being Assistant or Manager.
  09/18/2018 Dan Carmen   Change query for user
  04/04/2019 Dan Carmen   Change query for User
  01/22/2021 Dan Carmen   If no area, default the area name to the Sales Org
  06/09/2021 Dan Carmen   Change in finding role names for MMS since they changed their name format.
  08/25/2021 Dan Carmen   Modified to get user info from ZipQueries (so changes will be in one place)
  03/18/2022 Dan Carmen   Fix for updating users
  07/19/2022 Dan Carmen   Fix for populating Org Unit User Links
  11/11/2022 Dan Carmen   Don't create a new Org Unit if the org unit number is blank
  09/05/2023 Dan Carmen   Skip role check if override flag is set and the name and id are populated
  11/09/2023 Dan Carmen   Add check to make sure 18 character ids added.
  01/25/2024 Dan Carmen   Change OrgUnitRoleSetup__mdt to select based on TopLevel__c field instead of Division
  
 */
@isTest
public class OrgUnitMethodsTest {
   
   public static Map<String,User[]> getTestUsers(Integer nbrUsers) {
      // select a few users to use to create records
      User[] users = [Select Id, Name, Cost_Center__c, Profile.Name 
                        from User 
                       where IsActive=true and Id != :UserInfo.getUserId()
                         and Cost_Center__c != null and Cost_Center__c != '0000'
                         and HR_Person_Id__c != null
                         and UserType = 'Standard' 
                       limit 20];
      // separate users by cost center
      Map<String,User[]> userMap = new Map<String,User[]>();
      for (User u : users) {
         System.debug('User='+u.Name+' Cost Center='+u.Cost_Center__c+' profile='+u.Profile.Name);
         User[] checkUsers = userMap.get(u.Cost_Center__c);
         if (checkUsers == null) {
            checkUsers = new User[]{};
            userMap.put(u.Cost_Center__c,checkUsers);
         }
         checkUsers.add(u);
      } // for (User u
      System.debug('userMap.size()='+userMap.size());
      return userMap;
   } // getTestUsers
   
   public static Org_Unit__c[] createCostCenters(Set<String> costCenterNbrs) {
      // create Org_Unit__c records
      Org_Unit__c[] orgUnits = new Org_Unit__c[]{};
      for (String key : costCenterNbrs) {
         Org_Unit__c ou = new Org_Unit__c();
         ou.Name = key;
         ou.Org_Unit_Name__c = 'Test '+key;
         ou.Org_Type__c = 'Cost Center';
         orgUnits.add(ou);
      }
      
      insert orgUnits;
      
      // verify how many were created - can select all since other data not visible on v24
      Org_Unit__c[] newOus = [Select Id, Name, Available_Profiles__c, Org_Type__c, Org_Unit_Name__c
                                    ,Org_Unit_Number_Padded__c, Query_Key__c
                                from Org_Unit__c];
      System.assertEquals(costCenterNbrs.size(),newOus.size());
      return newOus;
   } // createCostCenters
   
   // Test the get org unit method
   static testMethod void testGetOrgUnit() {
      Org_Unit__c zone1 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_ZONE, Name='1', Org_Unit_Name__c='Zone 1', Sales_Org__c=UserHelper.SO_CORE);
      // reselect the zone to get the query key
      insert zone1;
      zone1 = [Select Id, Name, Org_Unit_Name__c, Query_Key__c from Org_Unit__c where Id=:zone1.Id];

      Org_Unit__c dist1 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='1', Org_Unit_Name__c='District 1', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id);
      Org_Unit__c dist2 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='2', Org_Unit_Name__c='District 2', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id);
      Org_Unit__c dist3 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='3', Org_Unit_Name__c='District 3', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id);
      Org_Unit__c[] districts = new Org_Unit__c[]{dist1,dist2,dist3};
      insert districts;
      
      // select some users to link to the districts/zone
      User[] users = [Select Id, Name, Sales_Org__c, UserRoleId from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 4];
      Org_Unit_User_Link__c link1 = new Org_Unit_User_Link__c(Name=users[0].Name, User__c=users[0].Id, Org_Unit__c=zone1.Id);
      Org_Unit_User_Link__c link2 = new Org_Unit_User_Link__c(Name=users[1].Name, User__c=users[1].Id, Org_Unit__c=dist1.Id);
      Org_Unit_User_Link__c link3 = new Org_Unit_User_Link__c(Name=users[2].Name, User__c=users[2].Id, Org_Unit__c=dist2.Id);
      Org_Unit_User_Link__c link4 = new Org_Unit_User_Link__c(Name=users[3].Name, User__c=users[3].Id, Org_Unit__c=dist3.Id);
      Org_Unit_User_Link__c[] links = new Org_Unit_User_Link__c[]{link1,link2,link3,link4};
      insert links;
      
      // select the Org Unit by the user for the zone
      Org_Unit__c userOrgUnit = OrgUnitMethods.getUserOrgUnits(users[0])[0];
      System.assertEquals(zone1.Id, userOrgUnit.Id);
      
      Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnits(new Org_Unit__c[]{zone1}, OrgUnitMethods.TYPE_DISTRICT, null, null, null);
      // the three districts should be returned
      System.assertEquals(3,orgUnits.size());
      
      // no parameters passed in - should return nothing
      orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, null, null);
      // nothing should be returned
      System.assertEquals(0,orgUnits.size());

      // query key for the zone passed in - only zone should be returned
      orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, null, new String[]{zone1.Query_Key__c});
      // 1 zone
      System.assertEquals(1,orgUnits.size());
      System.assertEquals(zone1.Id, orgUnits[0].Id);
      
      // id for district 3 is passed in
      orgUnits = OrgUnitMethods.getOrgUnits(null, null, new Id[]{dist3.Id}, null, null);
      // 1 district
      System.assertEquals(1,orgUnits.size());
      System.assertEquals(dist3.Id, orgUnits[0].Id);
      
      
   } // testGetOrgUnit
   
   // Test the get org unit method
   static testMethod void testGetOrgUnitAssistant() {
      // select some users to link to the districts/zone
      User[] users = [Select Id, Name, Sales_Org__c, UserRoleId from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 4];


      Org_Unit__c zone1 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_ZONE, Name='1', Org_Unit_Name__c='Zone 1', Sales_Org__c=UserHelper.SO_CORE);
      // reselect the zone to get the query key
      insert zone1;
      zone1 = [Select Id, Name, Org_Unit_Name__c, Query_Key__c from Org_Unit__c where Id=:zone1.Id];

      Org_Unit__c dist1 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='1', Org_Unit_Name__c='District 1', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id, Assistant__c=users[0].Id);
      Org_Unit__c dist2 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='2', Org_Unit_Name__c='District 2', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id, Assistant__c=users[1].Id);
      Org_Unit__c dist3 = new Org_Unit__c(Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Name='3', Org_Unit_Name__c='District 3', Sales_Org__c=UserHelper.SO_CORE, Parent__c=zone1.Id, Manager__c=users[1].Id);
      Org_Unit__c[] districts = new Org_Unit__c[]{dist1,dist2,dist3};
      insert districts;
      
      // select the Org Unit by the user for the first district
      Org_Unit__c userOrgUnit = OrgUnitMethods.getUserOrgUnits(users[0])[0];
      System.assertEquals(dist1.Id, userOrgUnit.Id);
      
      // get the districts for the second user
      Org_Unit__c[] orgUnits = OrgUnitMethods.getUserOrgUnits(users[1]);
      System.assertEquals(2,orgUnits.size());
      
      Boolean dist2Found = false;
      Boolean dist3Found = false;
      for (Org_Unit__c orgUnit : orgUnits) {
         if (orgUnit.Id == dist2.Id) {
            dist2Found = true;
         } else if (orgUnit.Id == dist3.Id) {
            dist3Found = true;
         }
      } // for (Org_Unit__c
      
      System.assertEquals(true,dist2Found);
      System.assertEquals(true,dist3Found);
      
   } // testGetOrgUnitAssistant
   
   static testMethod void testCostCenter() {
    // get some test users
    Map<String,User[]> userMap = getTestUsers(20);

      // create Org_Unit__c records
      Org_Unit__c[] costCenters = createCostCenters(userMap.keySet());

      // verify Available Profiles set
      checkResults(costCenters,userMap);

      // clear out the available profiles to force the update trigger to fire.
      Id[] orgUnitIds = new Id[]{};
      for (Org_Unit__c ou : costCenters) {
         ou.Available_Profiles__c = null;
         orgUnitIds.add(ou.Id);
      } // for
      
      // save the change
      update costCenters;
      
      // reselect the data
      costCenters = [Select Id, Name, Available_Profiles__c, Org_Type__c, Org_Unit_Name__c
                                    ,Org_Unit_Number_Padded__c, Query_Key__c
                                from Org_Unit__c
                               where Id in :orgUnitIds];
                               
      // verify Available Profiles are still set
      checkResults(costCenters,userMap);

      // perform an update with no changes and make sure everything is still okay
      update costCenters;
      
      // reselect the data
      costCenters = [Select Id, Name, Available_Profiles__c, Org_Type__c, Org_Unit_Name__c
                                    ,Org_Unit_Number_Padded__c, Query_Key__c
                                from Org_Unit__c
                               where Id in :orgUnitIds];
                               
      // verify Available Profiles are still set
      checkResults(costCenters,userMap);

      // try to add a duplicate org unit.
      Org_Unit__c orgUnitDup = new Org_Unit__c();
      orgUnitDup.Name = costCenters.get(0).Name;
      orgUnitDup.Org_Type__c = 'Cost Center';
      orgUnitDup.Org_Unit_Name__c = 'Test Duplicate';
      Boolean isSuccess = true;
      try {
         insert orgUnitDup;
      } catch (Exception e) {
         isSuccess = false;
      }
      System.assertEquals(false,isSuccess);
   } // testCostCenter
    
   /** Verify profiles are set.
    */
   private static void checkResults(Org_Unit__c[] costCenters, Map<String,User[]> userMap) {
      // verify Available Profiles set
      for (Org_Unit__c ou : costCenters) {
         System.debug('ou='+ou.Name+' Nbr Padded='+ou.Org_Unit_Number_Padded__c+' profs='+ou.Available_Profiles__c);
         // get all of the profiles out as a string
         String[] checkProfs = (ou.Available_Profiles__c != null ? ou.Available_Profiles__c.split(';') : new String[]{});
         Set<String> checkProfsSet = new Set<String>();
         checkProfsSet.addAll(checkProfs);
         System.debug('Number of checkProfs='+checkProfs.size()+' checkProfsSet='+checkProfsSet.size());
         
         User[] checkUsers = userMap.get(ou.Org_Unit_Number_Padded__c);
         if (checkUsers != null) {
            System.debug('Number of checkUsers='+checkUsers.size());
         
            // verify all profiles present and no extra
            Set<String> userProfSet = new Set<String>();
         
            for (User u : checkUsers) {
               // make sure the profiles we had selected are present.
               System.assertEquals(true,checkProfsSet.contains(u.Profile.Name));
               userProfSet.add(u.Profile.Name);
            } // for (User u
         
            // size of checkProfsSet should be equal or greater than userProfSet - to account for other profiles not initially selected.
            System.assertEquals(true,(checkProfsSet.size() >= userProfSet.size()));
         } // if (checkUsers != null)
      } // for (Org_Unit__c
   } // checkResults
   
  
   // the following are static so they can be used by other test classes
   public static String salesOrg1 = UserHelper.SO_CORE;
   public static String salesOrg2 = UserHelper.SO_MMS;

   // setup some org structure objects for testing - use numbers not typically used.
   public static Organization_Structure__c os1 = new Organization_Structure__c(Sales_Office_Number__c='22',Sales_Office_name__c='BUFFALO NORTH',CostCenter__c='22'
                                        ,Name='22',District_Name__c='BUFFALO NORTH',Zone__c='6',Zone_Name__c='Core Zone 6'
                                        ,Area_Number__c='1',Area__c='EAST',Sales_Org__c=salesOrg1);
   public static Organization_Structure__c os2 = new Organization_Structure__c(Sales_Office_Number__c='21',Sales_Office_name__c='ROCHESTER ROC',CostCenter__c='21'
                                        ,Name='21',District_Name__c='ROCHESTER ROC',Zone__c='6',Zone_Name__c='Core Zone 6'
                                        ,Area_Number__c='1',Area__c='EAST', Sales_Org__c=salesOrg1);
   public static Organization_Structure__c os3 = new Organization_Structure__c(Sales_Office_Number__c='307',Sales_Office_name__c='NEW BUSINESS 307',CostCenter__c='307'
                                        ,Name='307',District_Name__c='NEW BUSINESS 307',Zone__c='36',Zone_Name__c='NEW BIZ ZONE 36'
                                        ,Area_Number__c='6',Area__c='NEW BIZ', Sales_Org__c=salesOrg1);
   // structure with no area
   public static Organization_Structure__c os4 = new Organization_Structure__c(Sales_Office_Number__c='407',Sales_Office_name__c='MMS ENTERPRISE ROCHESTER',CostCenter__c='407'
                                        ,Name='407',District_Name__c='MMS ENTERPRISE ROCHESTER',Zone__c='7',Zone_Name__c='EAST'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=salesOrg2);
   public static Organization_Structure__c os5 = new Organization_Structure__c(Sales_Office_Number__c='408',Sales_Office_name__c='MMS ENTERPRISE LONG ISLAND',CostCenter__c='408'
                                        ,Name='408',District_Name__c='MMS ENTERPRISE LONG ISLAND',Zone__c='7',Zone_Name__c='EAST'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=salesOrg2);

   /** Test the checkOrgStructure method.
    */ 
   static testMethod void testCheckOrgStructure() {
      UserHelperTest.setupSalesOrgSetting();
      
      // Change these values so we are only running the process for a subset of data. 
      UserHelper.JOB_DIVISION_SET = new Set<String>{salesOrg1,salesOrg2};
      UpdateOrgInfo.checkSalesOrgs = UserHelper.JOB_DIVISION_SET;
      OrgUnitMethods.SALES_ORGS = new List<String>{salesOrg1,salesOrg2};

      // bad sales org name - will not create org units
      Organization_Structure__c os6 = new Organization_Structure__c(Sales_Office_Number__c='7776',Sales_Office_name__c='Office 7776',CostCenter__c='6'
                                        ,Name='7704',District_Name__c='District 7704',Zone__c='7704',Zone_Name__c='Zone 7704'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c='BAD SALES ORG');
      Organization_Structure__c[] strucs = new Organization_Structure__c[]{os1,os2,os3,os4,os5,os6};
      insert strucs;
      
      System.debug('testCheckOrgStructure before first test');
      // run the process
      OrgUnitMethods oum = new OrgUnitMethods();
      oum.checkOrgStructure(salesOrg1);
      oum.checkOrgStructure(salesOrg2);
      
      // verify numbers processed
      System.assertEquals(5,oum.nbrStrcsProcessed);
      System.assertEquals(0,oum.nbrExistingOrgUnits);
      System.assertEquals(18,oum.nbrOrgUnitsCreated);
      System.assertEquals(0,oum.nbrOrgUnitsUpdated);
      System.assertEquals(0,oum.nbrOrgUnitsDeleted);
      
      // remove os2 - removes 1 sales office
      delete os2;
      // update os3 to move to zone 1 - so zone 2 should no longer be used
      os3.Zone__c = os1.Zone__c;
      os3.Zone_Name__c = os1.Zone_Name__c;
      // change district name
      os3.District_Name__c = 'New District 101';
      update os3;

      // create os7 - new office and district
      Organization_Structure__c os7 = new Organization_Structure__c(Sales_Office_Number__c='7777',Sales_Office_name__c='Office 7777',CostCenter__c='7'
                                        ,Name='7707',District_Name__c='District 7707',Zone__c='7703',Zone_Name__c='Zone 7703'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=salesOrg2);
      insert os7;
      
      System.debug('testCheckOrgStructure before test for end date');
      oum = new OrgUnitMethods();
      oum.checkOrgStructure(salesOrg1);
      oum.checkOrgStructure(salesOrg2);

      // verify numbers processed
      System.assertEquals(5,oum.nbrStrcsProcessed);
      System.assertEquals(18,oum.nbrExistingOrgUnits);
      System.assertEquals(3,oum.nbrOrgUnitsCreated);
      //System.assertEquals(5,oum.nbrOrgUnitsUpdated);
      Assert.isTrue(oum.nbrOrgUnitsUpdated > 0);
      System.assertEquals(3,oum.nbrOrgUnitsDeleted);
      
      System.debug('testCheckOrgStructure before test with no changes');
      // run again with no changes
      oum = new OrgUnitMethods();
      oum.checkOrgStructure(salesOrg1);
      oum.checkOrgStructure(salesOrg2);

      // verify numbers processed
      System.assertEquals(5,oum.nbrStrcsProcessed);
      System.assertEquals(21,oum.nbrExistingOrgUnits);
      System.assertEquals(0,oum.nbrOrgUnitsCreated);
      //System.assertEquals(4,oum.nbrOrgUnitsUpdated);
      Assert.isTrue(oum.nbrOrgUnitsUpdated > 0);
      System.assertEquals(0,oum.nbrOrgUnitsDeleted);

      // verify specific data
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os1.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os1.Sales_Org__c and Org_Unit_Name__c=:os1.Sales_Office_name__c]);
      // since we're not actually deleting, this will remain.
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os2.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os2.Sales_Org__c and Org_Unit_Name__c=:os2.Sales_Office_name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os3.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os3.Sales_Org__c and Org_Unit_Name__c=:os3.Sales_Office_name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os4.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os4.Sales_Org__c and Org_Unit_Name__c=:os4.Sales_Office_name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os5.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os5.Sales_Org__c and Org_Unit_Name__c=:os5.Sales_Office_name__c]);
      System.assertEquals(0,[Select count() from Org_Unit__c where Name=:os6.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os6.Sales_Org__c and Org_Unit_Name__c=:os6.Sales_Office_name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os7.Sales_Office_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE and Sales_Org__c=:os7.Sales_Org__c and Org_Unit_Name__c=:os7.Sales_Office_name__c]);

      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os1.Name and Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Sales_Org__c=:os1.Sales_Org__c and Org_Unit_Name__c=:os1.District_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os3.Name and Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Sales_Org__c=:os3.Sales_Org__c and Org_Unit_Name__c=:os3.District_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os4.Name and Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Sales_Org__c=:os4.Sales_Org__c and Org_Unit_Name__c=:os4.District_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os5.Name and Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Sales_Org__c=:os5.Sales_Org__c and Org_Unit_Name__c=:os5.District_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os7.Name and Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Sales_Org__c=:os7.Sales_Org__c and Org_Unit_Name__c=:os7.District_Name__c]);

      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os1.Zone__c and Org_Type__c=:OrgUnitMethods.TYPE_ZONE and Sales_Org__c=:os1.Sales_Org__c and Org_Unit_Name__c=:os1.Zone_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os3.Zone__c and Org_Type__c=:OrgUnitMethods.TYPE_ZONE and Sales_Org__c=:os3.Sales_Org__c and Org_Unit_Name__c=:os3.Zone_Name__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os4.Zone__c and Org_Type__c=:OrgUnitMethods.TYPE_ZONE and Sales_Org__c=:os4.Sales_Org__c and Org_Unit_Name__c=:os4.Zone_Name__c]);

      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os1.Area_Number__c and Org_Type__c=:OrgUnitMethods.TYPE_AREA and Sales_Org__c=:os1.Sales_Org__c and Org_Unit_Name__c=:os1.Area__c]);

      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os1.Sales_Org__c and Org_Type__c=:OrgUnitMethods.TYPE_DIVISION and Sales_Org__c=:os1.Sales_Org__c and Org_Unit_Name__c=:os1.Sales_Org__c]);
      System.assertEquals(1,[Select count() from Org_Unit__c where Name=:os4.Sales_Org__c and Org_Type__c=:OrgUnitMethods.TYPE_DIVISION and Sales_Org__c=:os4.Sales_Org__c and Org_Unit_Name__c=:os4.Sales_Org__c]);


/*
      // select some users to attach to one of the sales offices and district.
      User[] reps = [Select Id, Name, Sales_Org__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and SalesOfficeNumber__c != :os1.Sales_Office_Number__c limit 8];
      User dsa = [Select Id, Name, Sales_Org__c, District__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      User dsm = [Select Id, Name, Sales_Org__c, District__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSM and Sales_Org__c=:UserHelper.SO_CORE limit 1];
      
      // verify 8 users were selected
      System.assertEquals(8,reps.size());
      
      // update 5 users to match sample data
      for (Integer cnt=0; cnt<5; cnt++) {
         reps[cnt].SalesOfficeNumber__c = os1.Sales_Office_Number__c;
         reps[cnt].Sales_Org__c = os1.Sales_Org__c;
         reps[cnt].Cost_Center__c = os1.CostCenter__c;
         reps[cnt].District__c = os1.Name;
      }
      dsa.District__c = os1.Name;
      dsa.Sales_Org__c = os1.Sales_Org__c;
      dsm.District__c = os1.Name;
      dsm.Sales_Org__c = os1.Sales_Org__c;
      
      update reps;
      update dsa;
      update dsm;
      
      // verify the reps meet the criteria
      
      
      // run the process to create the links
      oum = new OrgUnitMethods();
      oum.checkOrgUnitUserLinks();
      
      System.assertEquals(0,oum.nbrUserLinksDeleted);
      //System.assertEquals(8,oum.nbrUserLinksInserted);
      
      Org_Unit__c office1 = [Select Id, Name
                                   ,Parent__c
                                   ,(Select Id
                                           ,User__r.Id
                                       From Org_Unit_User_Links__r)
                               from Org_Unit__c 
                              where Name=:os1.Sales_Office_Number__c 
                                and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE 
                                and Sales_Org__c=:os1.Sales_Org__c 
                                and Org_Unit_Name__c=:os1.Sales_Office_name__c];

      // the district will be the parent of the sales office
      Org_Unit__c district1 = [Select Id, Name
                                   ,Parent__c
                                   ,(Select Id
                                           ,User__r.Id
                                       From Org_Unit_User_Links__r)
                               from Org_Unit__c
                              Where Id = :office1.Parent__c];
                              
      // verify 5 reps are attached to the sales office
      System.assertEquals(5,office1.Org_Unit_User_Links__r.size());
      // verify 2 district personnel
      System.assertEquals(2,district1.Org_Unit_User_Links__r.size());
      
      // change the first rep to no longer match
      reps[0].SalesOfficeNumber__c = os3.Sales_Office_Number__c;
      reps[0].Cost_Center__c = os3.CostCenter__c;
      reps[0].District__c = os3.Name;
      
      // update the final 3 reps to now match - net addition of 2 reps
      for (Integer cnt=5; cnt<8; cnt++) {
         reps[cnt].SalesOfficeNumber__c = os1.Sales_Office_Number__c;
         reps[cnt].Sales_Org__c = os1.Sales_Org__c;
         reps[cnt].Cost_Center__c = os1.CostCenter__c;
      }
      update reps;

      // run the process to create the links
      oum = new OrgUnitMethods();
      oum.checkOrgUnitUserLinks();
      
      System.assertEquals(1,oum.nbrUserLinksDeleted);
      System.assertEquals(4,oum.nbrUserLinksInserted);

      office1 = [Select Id, Name
                                   ,Parent__c
                                   ,(Select Id
                                           ,User__r.Id
                                       From Org_Unit_User_Links__r)
                               from Org_Unit__c 
                              where Name=:os1.Sales_Office_Number__c 
                                and Org_Type__c=:OrgUnitMethods.TYPE_SALES_OFFICE 
                                and Sales_Org__c=:os1.Sales_Org__c 
                                and Org_Unit_Name__c=:os1.Sales_Office_name__c];

      // verify 7 reps are attached to the sales office
      System.assertEquals(7,office1.Org_Unit_User_Links__r.size());
   */

   } // testCheckOrgStructure

   static testMethod void testGetRoleName() {
      OrgUnitMethods oum = new OrgUnitMethods();
      /*
      System.assertEquals(null,oum.getRoleName(null,null));
      Org_Unit__c testOu = new Org_Unit__c(Name='1', Org_Unit_Name__c='Test Org 1', Sales_Org__c=UserHelper.SO_CORE, Org_Type__c=OrgUnitMethods.TYPE_ZONE
                                          ,OverrideUserRoleName__c=true, UserRoleName__c='Test Role Name');
      System.assertEquals('Test Role Name',oum.getRoleName(testOu,OrgUnitMethods.TYPE_ZONE));
      testOu.OverrideUserRoleName__c = false;
      System.assertEquals('CORE Zone 1',oum.getRoleName(testOu,OrgUnitMethods.TYPE_ZONE));
      
      testOu.Sales_Org__c = UserHelper.SO_401;
      testOu.Org_Unit_Name__c = 'Test - Org 1';
      System.assertEquals('Test Org 1',oum.getRoleName(testOu,OrgUnitMethods.TYPE_ZONE));
      
      testOu.Org_Type__c = OrgUnitMethods.TYPE_DISTRICT;
      System.assertEquals('Test Org 1',oum.getRoleName(testOu,OrgUnitMethods.TYPE_DISTRICT));

      testOu.Sales_Org__c = UserHelper.SO_HNB;
      testOu.Org_Unit_Name__c = 'Test Org 1';
      System.assertEquals('HNBF District - Test Org 1',oum.getRoleName(testOu,OrgUnitMethods.TYPE_DISTRICT));
      */

   } // testGetRoleName
   

   static testMethod void testMiscellaneous() {
      System.assertEquals(OrgUnitMethods.ROLE_CORE, new OrgUnitMethods().checkSalesOrgName(UserHelper.SO_CORE));
      System.assertEquals(UserHelper.SO_401, new OrgUnitMethods().checkSalesOrgName(UserHelper.SO_PEO_ASO));
      
      OrgUnitMethods oum = new OrgUnitMethods();
      
      Org_Unit__c ou = new Org_Unit__c(Name='1',Org_Unit_Name__c='Test Name', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT);

      ou = new Org_Unit__c(Name='12',Org_Unit_Name__c='ZONE EAST');
      String testRoleName = '<R:ZONE/HNBF>';
      String roleName = OrgUnitMethods.buildRoleName(testRoleName, ou);
      System.assertEquals('HNBF EAST', roleName);

      ou = new Org_Unit__c(Name='11',Org_Unit_Name__c='Supervisor 1.1');
      testRoleName = 'NSS Outbound Supervisor <LastToken>';
      roleName = OrgUnitMethods.buildRoleName(testRoleName, ou);
      System.assertEquals('NSS Outbound Supervisor 1.1', roleName);

      ou = new Org_Unit__c(Name='615',Org_Unit_Name__c='PEO Houston 615');
      testRoleName = 'PEO District <StripOrgName>';
      roleName = OrgUnitMethods.buildRoleName(testRoleName, ou);
      System.assertEquals('PEO District Houston', roleName);
      
   } // testMiscellaneous
    
   static testMethod void testProcessRoleNames() {
      UserRole[] roles = [Select Id, Name from UserRole where Name like '%District%' limit 2];
      Org_Unit__c ou = new Org_Unit__c(Name='666',Org_Unit_Name__c='Down Below', Org_Type__c='District', UserRoleName__c=roles[0].Name, RepUserRoleName__c=roles[1].Name);
      insert ou;
      ou = [Select Id, Name, UserRoleName__c, UserRoleId__c, RepUserRoleName__c, RepUserRoleId__c from Org_Unit__c where Id=:ou.Id];
      System.assertEquals(roles[0].Id, ou.UserRoleId__c);
      System.assertEquals(roles[1].Id, ou.RepUserRoleId__c);
   } // testProcessRoleNames
    
   static testMethod void testJob() {
      // create only one sales org so one batch runs.
      SalesOrg__c so = new SalesOrg__c(Name=salesOrg1, Description__c='Core',HasOwnership__c=true, RecordTypeAlias__c='Core '
                                    ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE
                                    ,OpptyRecordTypeName2__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA
                                    ,EventRecordTypeName__c=RecordTypeHelper.CORE_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.CORE_TASK
                                    ,ProductName__c='',IsSales__c=true,ProcessAcctOwnership__c=true,ProcessRfrlOwnership__c=true
                                    ,TeamRole__c='Payroll Owner',CanSubmitReferrals__c=true,StrcHasArea__c=true,HasOrgStructure__c=true
                                    ,LeadRecordTypeName__c=RecordTypeHelper.CORE_LEAD
                                    ,OppFirstStage__c='Pending'
                                    ,ZipBatchKey__c='A'
                                    ,IEUP_Type__c = 'Presentation - Initial'
                                    );
      insert so;
      // only 1 sales org
      System.assertEquals(1,[Select count() from SalesOrg__c]);

      // only insert the strcs for salesOrg1
      Organization_Structure__c[] strucs = new Organization_Structure__c[]{os1,os2,os3};
      insert strucs;

      // verify no org units.
      System.assertEquals(0,[Select count() from Org_Unit__c]);
      OrgUnitJob ouj = new OrgUnitJob();
      Test.startTest();
      Database.executeBatch(ouj,1);
      Test.stopTest();
       
      System.assertNotEquals(0,[Select count() from Org_Unit__c]);
      
      // check creating a log file
      String logFile = 'This,Is,A,Log,File';
      String retMsg = ouj.checkLogFile(logFile);
      System.assertEquals(true, retMsg.endsWith('See Attachment for additional Information'), retMsg);

   } // testJob
    
   static testMethod void testId() {
      Account acct = new Account(Name='Test Account');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      // a totally bad id
      String testId1 = 'JUSTABADID';
      String result = OrgUnitMethods.checkId(testId1);
      Assert.isNull(result);
      // get the shortened Id
      String testId2 = ((String)acct.Id).left(15);
      result = OrgUnitMethods.checkId(testId2);
      Assert.areEqual(acct.Id,result);
      // the full id
      String testId3 = acct.Id;
      result = OrgUnitMethods.checkId(testId3);
      Assert.areEqual(acct.Id,result);
      
   } // testId

   // Test the scheduler for the batch process.
   static testMethod void testOrgUnitJob() {
      OrgUnitJob ouj = new OrgUnitJob();
      TestHelper.testScheduler('OrgUnitJobTest', ouj);
   } // testOrgUnitJob
  
} // class OrgUnitMethodsTest