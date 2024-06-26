/* Test Methods for the ManageZipAssignController class.

  History
  -------
  04/01/2013 Dan Carmen   Created 
  05/04/2016 Cindy Freeman	modified to cover cloning and deleting territories
  06/23/2016 Dan Carmen   Added in startTest method to prevent test from hitting limits.
  09/28/2016 Dan Carmen   Added some cleanup to the code - getting rid of unneeded fields
  03/29/2017 Cindy Freeman	Added code to test revised clone territory that lets you pick the segment to CloneTo
  07/21/2017 Jacob Hinds	Added state filter
  09/05/2023 Dan Carmen       Changed call to launch the ZipInsertBatch
  11/30/2023 Dan Carmen       Removed unused fields on Zip Assignment/Zip Territory

 */ 
@isTest
public class ManageZipAssignControllerTest { 

/*
   public static Organization_Structure__c os6 = new Organization_Structure__c(Sales_Office_Number__c='7778',Sales_Office_name__c='Office 7778',CostCenter__c='8'
                                        ,Name='7708',District_Name__c='District 7708',Zone__c='7708',Zone_Name__c='Zone 7708'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=UserHelper.SO_401);
   public static Organization_Structure__c os7 = new Organization_Structure__c(Sales_Office_Number__c='7779',Sales_Office_name__c='Office 7779',CostCenter__c='9'
                                        ,Name='7709',District_Name__c='District 7709',Zone__c='7709',Zone_Name__c='Zone 7709'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=UserHelper.SO_401);
   public static Organization_Structure__c os8 = new Organization_Structure__c(Sales_Office_Number__c='7780',Sales_Office_name__c='Office 7780',CostCenter__c='10'
                                        ,Name='7710',District_Name__c='District 7710',Zone__c='7711',Zone_Name__c='Zone 7711'
                                        ,Area_Number__c='774',Area__c='Area 774', Sales_Org__c=UserHelper.SO_CORE);
   public static Organization_Structure__c os9 = new Organization_Structure__c(Sales_Office_Number__c='7781',Sales_Office_name__c='Office 7781',CostCenter__c='11'
                                        ,Name='7711',District_Name__c='District 7711',Zone__c='7712',Zone_Name__c='Zone 7712'
                                        ,Area_Number__c=null,Area__c=null, Sales_Org__c=UserHelper.SO_MMS);
*/

   private static Zip_Segment__c segmentPay1 = new Zip_Segment__c(Name='Test Core1',Sales_Org__c=UserHelper.SO_CORE,Emps_Min__c=0,Emps_Max__c=999999,Paychex_Id__c='TestCore1',CloneTo__c = true,Delete_ZipAssignments__c=true);
   private static Zip_Segment__c segmentPay2 = new Zip_Segment__c(Name='Test Core2',Sales_Org__c=UserHelper.SO_CORE,Emps_Min__c=0,Emps_Max__c=999999,Paychex_Id__c='TestCore2',CloneFrom__c = true);
   private static Zip_Segment__c segmentHrs1 = new Zip_Segment__c(Name='Test HRS1',Sales_Org__c=UserHelper.SO_401,Emps_Min__c=0,Emps_Max__c=49,Paychex_Id__c='TestHrs1');
   private static Zip_Segment__c segmentHrs2 = new Zip_Segment__c(Name='Test HRS2',Sales_Org__c=UserHelper.SO_401,Emps_Min__c=50,Emps_Max__c=999999,Paychex_Id__c='TestHrs2');
   private static Zip_Segment__c[] segments = new Zip_Segment__c[]{segmentPay1,segmentPay2,segmentHrs1,segmentHrs2};

   public static Org_Unit__c divPay = new Org_Unit__c(Name=UserHelper.SO_CORE, Org_Type__c=OrgUnitMethods.TYPE_DIVISION, Sales_Org__c=UserHelper.SO_CORE, Org_Unit_Name__c=UserHelper.SO_CORE);
   public static Org_Unit__c divHrs = new Org_Unit__c(Name=UserHelper.SO_401, Org_Type__c=OrgUnitMethods.TYPE_DIVISION, Sales_Org__c=UserHelper.SO_401, Org_Unit_Name__c=UserHelper.SO_401);
   public static Org_Unit__c[] divisions = new Org_Unit__c[]{divPay, divHrs};

   public static Org_Unit__c[] zones = new Org_Unit__c[]{};
   public static Org_Unit__c[] districts = new Org_Unit__c[]{};
   public static ZipTerritory__c[] territories = new ZipTerritory__c[]{};

   public static void setupOrgUnits() {
   	
      insert segments;
   	// create divisions
   	insert divisions;
   	divisions = requeryOrgUnits(divisions);
   	for (Org_Unit__c ou : divisions) {
   	   if (ou.Sales_Org__c == UserHelper.SO_CORE) {
   	      divPay = ou;
   	   } else if (ou.Sales_Org__c == UserHelper.SO_401) {
   	      divHrs = ou;
   	   }
   	} // for
   	
   	
   	// zones
   	for (Org_Unit__c divOrgUnit : divisions) {
         Org_Unit__c zone1 = new Org_Unit__c(Name='1', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Sales_Org__c=divOrgUnit.Sales_Org__c, Org_Unit_Name__c='Zone 1',Parent__c=divOrgUnit.Id);
         Org_Unit__c zone2 = new Org_Unit__c(Name='2', Org_Type__c=OrgUnitMethods.TYPE_ZONE, Sales_Org__c=divOrgUnit.Sales_Org__c, Org_Unit_Name__c='Zone 2',Parent__c=divOrgUnit.Id);
   	   zones.add(zone1);
   	   zones.add(zone2);
   	} // for (Org_Unit__c divOrgUnit
   	insert zones;
      zones = requeryOrgUnits(zones);
   	
   	// districts
   	for (Org_Unit__c zoneOrgUnit : zones) {
         Org_Unit__c district1 = new Org_Unit__c(Name='1', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Sales_Org__c=zoneOrgUnit.Sales_Org__c, Org_Unit_Name__c='District 1',Parent__c=zoneOrgUnit.Id);
         Org_Unit__c district2 = new Org_Unit__c(Name='2', Org_Type__c=OrgUnitMethods.TYPE_DISTRICT, Sales_Org__c=zoneOrgUnit.Sales_Org__c, Org_Unit_Name__c='District 2',Parent__c=zoneOrgUnit.Id);
         districts.add(district1);
         districts.add(district2);
   	} // for (Org_Unit__c zoneOrgUnit
   	insert districts;
      districts = requeryOrgUnits(districts);
   	
   	// select users to attach to the territories - 3 per district
   	User[] users = [Select Id, Name from User where IsActive=true and Profile.Name in :Utilities.REP_PROFS limit :districts.size()*5];
   	
   	// territories
   	for (Org_Unit__c district : districts) {
   	   if (district.Sales_Org__c == UserHelper.SO_CORE) {
   	   	    addTerritory(users, district, segmentPay1);
   	   	    addTerritory(users, district, segmentPay1);
            addTerritory(users, district, segmentPay2);
   	   } else if (district.Sales_Org__c == UserHelper.SO_401) {
            addTerritory(users, district, segmentHrs1);
            addTerritory(users, district, segmentHrs1);
            addTerritory(users, district, segmentHrs2);
            addTerritory(users, district, segmentHrs2);
   	   }
   	} // for (Org_Unit__c district
   	insert territories;
   	
      /** Change these values so we are only running the process for a subset of data. */
      /** use SO_401 because we want to test the wholesaler logic. */
      /*
      UserHelper.JOB_DIVISION_SET = new Set<String>{OrgUnitMethodsTest.salesOrg1,OrgUnitMethodsTest.salesOrg2, UserHelper.SO_401, UserHelper.SO_CORE, UserHelper.SO_MMS};
      UpdateOrgInfo.checkSalesOrgs = UserHelper.JOB_DIVISION_SET;
      OrgUnitMethods.SALES_ORGS = new List<String>{OrgUnitMethodsTest.salesOrg1,OrgUnitMethodsTest.salesOrg2, UserHelper.SO_401, UserHelper.SO_CORE, UserHelper.SO_MMS};



      Organization_Structure__c[] strucs = new Organization_Structure__c[]{OrgUnitMethodsTest.os1,OrgUnitMethodsTest.os2,OrgUnitMethodsTest.os3,OrgUnitMethodsTest.os4,OrgUnitMethodsTest.os5,os6,os7,os8,os9};
      insert strucs;
      
      // run the process - create the org units
      OrgUnitMethods oum = new OrgUnitMethods();
      oum.checkOrgStructure();
      */
   } // setupOrgUnits
   
   public static Org_Unit__c[] requeryOrgUnits(Org_Unit__c[] orgUnits) {
      // get the ids
      Id[] orgUnitIds = new Id[]{};
      for (Org_Unit__c ou : orgUnits) {
         orgUnitIds.add(ou.Id);
      }
      
      Org_Unit__c[] queryResults = OrgUnitMethods.getOrgUnits(null, null, orgUnitIds, null, null);
      return queryResults;
   } // requeryOrgUnits
   
   public static void addTerritory(User[] users, Org_Unit__c district, Zip_Segment__c segment) {
      User usr = users[territories.size()];
      ZipTerritory__c territory = new ZipTerritory__c(Name=usr.Name, TerritoryRep__c=usr.Id, Territory_Nbr__c=String.valueOf(territories.size()), District__c=district.Id, Zip_Segment__c=segment.Id);
      territories.add(territory);
   } // addTerritory
   
   static testMethod void testNormalRun() {
      setupOrgUnits();
      
      // select a non-system admin user
      User runningUser = [Select Id, Name, ManageZipOrgUnitsManaged__c from User where IsActive=true and Profile.Name in :Utilities.DSA_PROFS limit 1];
      
      // link the user directly to a zone
      Org_Unit_User_Link__c ouul = new Org_Unit_User_Link__c(Org_Unit__c=zones[1].Id, User__c=runningUser.Id);
      insert ouul;
      
      // update the user to manage the divisions
      runningUser.ManageZipOrgUnitsManaged__c = divPay.Query_Key__c+','+divHrs.Query_Key__c;
      runningUser.ManageZipOrgUnitsManaged__c += ','+zones[0].Query_Key__c+','+zones[2].Query_Key__c;
      runningUser.ManageZipOrgUnitsManaged__c += ','+districts[0].Query_Key__c;
      update runningUser;
      
      System.runAs(runningUser) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(false,mzac.isDistrictUser);
         System.assertEquals(false,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(true,mzac.isCorporateUser);
         System.assertEquals(false,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
         System.assertEquals(false,mzac.canUserManageTerritory);  // CMF
                  
         System.assertEquals(true,mzac.hasMultipleSalesOrgs);
         System.assertEquals(2,mzac.salesOrgPicklist.size());
         
         // make sure it's PAY
         mzac.searchZa.Sales_Org__c=divPay.Sales_Org__c;
         mzac.changeOrgStructure();
         
         System.assertEquals(2,mzac.zoneOptions.size());
         System.assertEquals(true,mzac.hasZoneOptions);
         
         System.assertEquals(2,mzac.districtOptions.size());
         System.assertEquals(true,mzac.hasDistrictOptions);
         
         // should be two segments
         System.assertEquals(2,mzac.segmentOptions.size());
         System.assertEquals(true,mzac.hasMultipleSegmentOptions);
         
         // should be three territories
         System.assertEquals(4,mzac.territoryFromPicklist.size());
         System.assertEquals(true,mzac.hasTerritoryFroms);
         
         // change to HRS
         mzac.searchZa.Sales_Org__c=divHrs.Sales_Org__c;
         mzac.changeOrgStructure();
         
         System.assertEquals(2,mzac.zoneOptions.size());
         System.assertEquals(true,mzac.hasZoneOptions);
         
         System.assertEquals(2,mzac.districtOptions.size());
         System.assertEquals(true,mzac.hasDistrictOptions);

         // should be two segments
         System.assertEquals(2,mzac.segmentOptions.size());
         System.assertEquals(true,mzac.hasMultipleSegmentOptions);
         
         // should be two territories
         System.assertEquals(4,mzac.territoryFromPicklist.size());
         System.assertEquals(true,mzac.hasTerritoryFroms);

         // select 1 of the territories
         mzac.selectedTerritoryFromId = mzac.territoryFromPicklist[2].getValue();
         mzac.selectTerritoryFrom();
         
         System.assertEquals(false,mzac.hasTerritoryContact);
         System.assertEquals(true,mzac.hasTerritoryFromObject);
         System.assertEquals(false,mzac.isTerritoryFromNew);
         mzac.toggleShowAssignments();

         // there are no zip codes
         System.assertEquals(0,mzac.zipAssignmentSet.getResultSize());
         
         // edit the territory
         System.assertEquals(false,mzac.editTerritoryFrom);
         mzac.editTerritory();
         System.assertEquals(true,mzac.editTerritoryFrom);
         // cancel edit territory
         mzac.cancelEditTerritory();
         System.assertEquals(false,mzac.editTerritoryFrom);
         mzac.editTerritory();
         System.assertEquals(true,mzac.editTerritoryFrom);
         // change the number
         mzac.editTerritoryRecord.Territory_Nbr__c='5';
         // save the changes
         mzac.saveTerritory();
         System.assertEquals(false,mzac.editTerritoryFrom);
         
         // create a zip code to make a duplicate
         Zip_Assignment__c dupZa = new Zip_Assignment__c(Name='12345',Zip_Segment__c=mzac.selectedTerritoryFromObject.Zip_Segment__c, District__c=mzac.selectedTerritoryFromObject.District__c
                                          ,BypassDistrictTrigger__c=true, Sales_Org__c=mzac.searchZa.Sales_Org__c, ZipTerritory__c=mzac.selectedTerritoryFromObject.Id);
         insert dupZa;
         
         // add a couple of zip codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         // add 6 zip codes
         mzac.nbrToAdd = 6;
         mzac.changeAddZipQuantity();
         System.assertEquals(6,mzac.zipsToAdd.size());
         mzac.zipsToAdd[0].Name='123';
         mzac.zipsToAdd[1].Name='123456';
         mzac.zipsToAdd[2].Name='23456';
         mzac.zipsToAdd[3].Name='23456';
         mzac.zipsToAdd[4].Name='56780';
         mzac.zipsToAdd[5].Name='56781';
         
         // try to save - will have errors
         mzac.saveNewZipRequest();
         System.assertEquals(true,mzac.addingZipCode);
         
         // fix the bad size zips, leave duplicate
         mzac.zipsToAdd[0].Name='';
         mzac.zipsToAdd[1].Name='12345';
         mzac.zipsToAdd[3].Name='23457';
         // try to save - will have errors
         mzac.saveNewZipRequest();
         System.assertEquals(true,mzac.addingZipCode);
         // fix the duplicate
         mzac.zipsToAdd[1].Name='12346';

         mzac.saveNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);
         
         // there are now 6 zip codes (1 existing, 5 we just created in the form)
         System.assertEquals(6,mzac.zipAssignmentSet.getResultSize());
         
         // try to reassign with nothing selected
         mzac.startReassigningZips();
         System.assertEquals(false,mzac.isReassigning);
         System.assertEquals(0, mzac.nbrRecordsSelected);  
         System.assertEquals(true, mzac.hasDisplayZipWraps);  
         System.assertEquals(1, mzac.numOfPages);  
         
         // select all of the zip codes
         for (ManageZipAssignController.ZipWrapper zw : mzac.displayZipWraps) {
            zw.selected = true;
         }
         
         
         // start reassigning
         mzac.startReassigningZips();
         System.assertEquals(true,mzac.isReassigning);
         
         // change the zone
         mzac.selectedReassignZoneId = mzac.zoneOptions[1].getValue();
         mzac.setReassignZone();
         
         // set the district
         mzac.selectedReassignDistrictId = mzac.districtReassignOptions[1].getValue();
         mzac.setReassignDistrict();
         
         System.assertEquals(true,mzac.hasTerritoryTos);
         mzac.selectedTerritoryToId = mzac.territoryToPicklist[1].getValue();
         mzac.selectTerritoryTo();
         
         System.assertEquals(true,mzac.reassignCriteriaEntered);
         mzac.performAssignToSelection();
         
         mzac.createNewTerritory(); 
         // will error - need name and rep name
         System.assertEquals(false,mzac.performTerritorySave());
         mzac.editTerritoryRecord.Name = 'Test Territory';
         mzac.editTerritoryRecord.Rep_Name__c = 'Open Test Territory';
         // should succeed now
         System.assertEquals(true,mzac.performTerritorySave());
         
         // verify the territory's existence.
         System.assertEquals(1,[select count() from ZipTerritory__c where Name='Test Territory']);
         
         // delete the territory we just created
         mzac.deleteTerritory();
         // verify the territory's deletion.
         System.assertEquals(0,[select count() from ZipTerritory__c where Name='Test Territory']);
         
         mzac.setSegment();
         
         // test territory clone ////////////////////////
         // change to PAY
         mzac.searchZa.Sales_Org__c=divPAY.Sales_Org__c;
         mzac.changeOrgStructure();
         System.assertEquals(2,mzac.zipSegmentMap.size());
         //mzac.selectedSegmentId = mzac.segmentOptions[1].getValue();
         //Id saveSegmentId = mzac.selectedSegmentId;
         for (SelectOption selOption : mzac.segmentOptions) {
   	   		if (selOption.getLabel() == 'Test Core2') 
   	   		{	mzac.selectedSegmentId = selOption.getValue();   	      
   	      		break;
   	      	}
   	     } // for (SelectOption selOption         
         mzac.setSegment();
         System.assertEquals('Test Core2',mzac.selectedSegmentName);
         mzac.setSegment();
	     System.assertEquals(3,mzac.territoryFromPicklist.size());
	        
         mzac.selectedTerritoryFromId = mzac.territoryFromPicklist[2].getValue();
         Id saveTerritoryId = mzac.selectedTerritoryFromId;
         mzac.selectTerritoryFrom();
          // add a zip code
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         // add 1 zip code
         mzac.nbrToAdd = 1;
         mzac.changeAddZipQuantity();
         mzac.zipsToAdd[0].Name='50001';
         mzac.saveNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);
         
         // add this in because starting to hit limits during the test
         Test.startTest();
         mzac.toggleUseClone();
         System.assertEquals(1,mzac.cloneSegmentOptions.size());
         mzac.selectedCloneSegmentId = mzac.cloneSegmentOptions[0].getValue();
         mzac.cloneTerritory();
                  
         ZipTerritory__c zt = mzac.selectedTerritoryFromObject;
         System.assertEquals(2,[select count() from ZipTerritory__c where Name= :zt.Name]);
         System.assertEquals(2,[select count() from Zip_Assignment__c where Name = '50001']);
         
         // test territory delete
         // change segment to Test Core1
         for (SelectOption selOption : mzac.segmentOptions) {
   	   		if (selOption.getLabel() == 'Test Core1') 
   	   		{	mzac.selectedSegmentId = selOption.getValue();   	      
   	      		break;
   	      	}
   	     } // for (SelectOption selOption         
         mzac.setSegment();
         System.assertEquals('Test Core1',mzac.selectedSegmentName);                 
  
         // find new territory created with matching old territory name       
         ZipTerritory__c[] terrList = [Select Id, Name, Zip_Segment__c from ZipTerritory__c 
         							where Name = :zt.Name and Zip_Segment__r.Name = 'Test Core1' limit 1];
         mzac.selectedTerritoryFromId = terrList[0].Id;                    
         mzac.selectTerritoryFrom();
         System.assertEquals(zt.Name,mzac.selectedTerritoryFromObject.Name);
         System.assertEquals('Test Core1',mzac.selectedTerritoryFromObject.Zip_Segment__r.Name);
         
         mzac.deleteTerritory();
         System.assertEquals(1,[select count() from ZipTerritory__c where Name= :zt.Name]);
         System.assertEquals(1,[select count() from Zip_Assignment__c where Name = '50001']);
         Test.stopTest();
       } // System.runAs
      
   } // testNormalRun
     
   // test miscellaneous methods
   static testMethod void testMisc() {
      Org_Unit__c testOrgUnit = new Org_Unit__c();
      ManageZipAssignController mzac = new ManageZipAssignController();
      System.assertEquals(false,mzac.checkUserLevelOnOrgUnit(testOrgUnit));
      testOrgUnit.Org_Type__c = OrgUnitMethods.TYPE_DISTRICT;
      System.assertEquals(true,mzac.checkUserLevelOnOrgUnit(testOrgUnit));
      System.assertEquals(true,mzac.isDistrictUser);
      System.assertEquals(false,mzac.isZoneUser);
      System.assertEquals(false,mzac.isAreaUser);
      System.assertEquals(false,mzac.isCorporateUser);
      
      testOrgUnit.Org_Type__c = OrgUnitMethods.TYPE_ZONE;
      System.assertEquals(true,mzac.checkUserLevelOnOrgUnit(testOrgUnit));
      System.assertEquals(false,mzac.isDistrictUser);
      System.assertEquals(true,mzac.isZoneUser);
      System.assertEquals(false,mzac.isAreaUser);
      System.assertEquals(false,mzac.isCorporateUser);
      
      testOrgUnit.Org_Type__c = OrgUnitMethods.TYPE_AREA;
      System.assertEquals(true,mzac.checkUserLevelOnOrgUnit(testOrgUnit));
      System.assertEquals(false,mzac.isDistrictUser);
      System.assertEquals(false,mzac.isZoneUser);
      System.assertEquals(true,mzac.isAreaUser);
      System.assertEquals(false,mzac.isCorporateUser);
      
      testOrgUnit.Org_Type__c = OrgUnitMethods.TYPE_DIVISION;
      System.assertEquals(true,mzac.checkUserLevelOnOrgUnit(testOrgUnit));
      System.assertEquals(false,mzac.isDistrictUser);
      System.assertEquals(false,mzac.isZoneUser);
      System.assertEquals(false,mzac.isAreaUser);
      System.assertEquals(true,mzac.isCorporateUser);
      
      System.assertEquals(false,mzac.useFilter);
      mzac.toggleUseFilter();
      System.assertEquals(true,mzac.useFilter);
      
      mzac.zipLow = null;
      mzac.zipHigh = null;
      mzac.applyFilter();
      
      mzac.zipLow = 'A1';
      mzac.zipHigh = 'B2';
      mzac.selectedStateFilter = mzac.stateFilterList[0].getValue();
      mzac.applyFilter();
      
      mzac.csvAsString = null;
      mzac.importCSVFile();
      System.assertEquals(false, mzac.importOkay);
      
      mzac.resetFilter();
      System.assertEquals(false,mzac.useFilter);
      
   } // testMisc
      
/*

      // link reps to the sales office
      // select 8 reps
   static testMethod void testAsDistrict() {
      User[] reps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 8];
      // setup a district user
      User distUser = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA limit 1];
      
      Id[] repIds = new Id[]{};
      for (User rep : reps) {
         rep.Cost_Center__c = os6.CostCenter__c;
         rep.SalesOfficeNumber__c = os6.Sales_Office_Number__c;
         rep.District__c = os6.Name;
         rep.Sales_Org__c = os6.Sales_Org__c;
         repIds.add(rep.Id);
      }
      update reps;
      distUser.Sales_Org__c = os6.Sales_Org__c;
      distUser.District__c = os6.Name;
      distUser.Cost_Center__c = '0000';
      update distUser;
       
      // select a user to use for the wholesaler
      User tempUser = [Select Id, Name, HR_Person_Id__c from User where IsActive=true and HR_Person_Id__c != null and Id not in :repIds limit 1];
      // create 200 internal wholesaler zip assignments - 100 with a user, 100 with a full name - to test the email send
      Zip_Assignment__c[] assigns = new Zip_Assignment__c[]{};
      // create zip assignments attached to the user
      for (Integer cnt=0; cnt<100; cnt++) {
         Zip_Assignment__c za = new Zip_Assignment__c(Name='13'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt
                                      ,HR_Person_Id__c=tempUser.HR_Person_Id__c, Rep_Name__c=tempUser.Name
                                      ,Sales_Org__c=UserHelper.SO_WHOLESALER, Segment_Name__c=UserHelper.WHOLESALER_INTERNAL);
         assigns.add(za);
      } // for (Integer cnt=0
      
      // create zip assignments with just a name
      for (Integer cnt=100; cnt<200; cnt++) {
         Zip_Assignment__c za = new Zip_Assignment__c(Name='13'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt
                                      ,HR_Person_Id__c=null, Rep_Name__c='Temp Name Jr'
                                      ,Sales_Org__c=UserHelper.SO_WHOLESALER, Segment_Name__c=UserHelper.WHOLESALER_INTERNAL);
         assigns.add(za);
      } // for (Integer cnt=0
      
      insert assigns;
      
      // log in as a district user
      System.runAs(distUser) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(true,mzac.isDistrictUser);
         System.assertEquals(false,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(false,mzac.isCorporateUser);
         System.assertEquals(false,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
         
         // verify the district org unit
         System.assertEquals(distUser.District__c,mzac.selectedDistrictOrgUnit.Name);
         System.assertEquals(distUser.Sales_Org__c,mzac.selectedDistrictOrgUnit.Sales_Org__c);
         
         // should have 3 segment options because of DEFAULT and wholesaler options.
         System.assertEquals(3,mzac.segmentOptions.size());
         System.assertEquals(true,mzac.hasMultipleSegmentOptions);
         
         // no district options since we're at a district level
         System.assertEquals(false,mzac.hasDistrictOptions);
         System.assertEquals(false,mzac.hasZoneOptions);
         
         // verify number of rep options - 8 reps setup, 1 for no rep, 1 to say to select a rep, and includes the DSA 
         System.assertEquals(11,mzac.availableUsers.size());
         System.assertEquals(true,mzac.hasAvailableUsers);
         
         // select a rep
         mzac.selectedAvailableUser = reps[0].Id;
         mzac.searchForZips();
         
         // should be no zip codes returned
         System.assertEquals(true,mzac.searchPerformed);
         System.assertEquals(false,mzac.zipAsgnsFound);
         System.assertEquals(0,mzac.nbrZipAsgnsFound);
         System.assertEquals(false,mzac.addingZipCode);
         
         // create a new codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // defaults to 1
         System.assertEquals(1,mzac.zipsToAdd.size());
         
         // try to set to 0
         mzac.nbrToAdd = 0;
         mzac.changeAddZipQuantity();
         System.assertEquals(1,mzac.zipsToAdd.size());
         
         // Try to go over the maximum
         mzac.nbrToAdd = ManageZipAssignController.MAX_ZIP_ADD+50;
         mzac.changeAddZipQuantity();
         System.assertEquals(ManageZipAssignController.MAX_ZIP_ADD,mzac.zipsToAdd.size());

         // set to 5
         mzac.nbrToAdd = 5;
         mzac.changeAddZipQuantity();
         System.assertEquals(5,mzac.zipsToAdd.size());
         
         // populate some zip code values - add some bad ones, and leave one blank
         mzac.zipsToAdd[0].Name='12345';
         mzac.zipsToAdd[1].Name='123';
         mzac.zipsToAdd[2].Name='123456';
         mzac.zipsToAdd[3].Name='12345';
         mzac.saveNewZipRequest();
         // make sure you're still in the adding mode since there should be errors
         System.assertEquals(true,mzac.addingZipCode);
         
         // fix the zip codes so no errors
         mzac.zipsToAdd[1].Name='12346';
         mzac.zipsToAdd[2].Name='12347';
         mzac.zipsToAdd[3].Name='12348';
         mzac.zipsToAdd[4].Name='12349';
         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);
         
         // 5 zip assignment records should exist
         System.assertEquals(5,[Select count() from Zip_Assignment__c where Organization_Structure__c=:os6.Id]);
         // same selected user
         System.assertEquals(reps[0].Id, mzac.selectedAvailableUser);
         
         // user should now have 5 zip codes
         System.assertEquals(true,mzac.zipAsgnsFound);
         System.assertEquals(5,mzac.nbrZipAsgnsFound);
         
         // switch to another user then switch back
         // select a rep
         mzac.selectedAvailableUser = reps[1].Id;
         mzac.searchForZips();
         // no zips for this rep
         System.assertEquals(false,mzac.zipAsgnsFound);
         System.assertEquals(0,mzac.nbrZipAsgnsFound);
         
         // switch back - has the 5 zips again.
         mzac.selectedAvailableUser = reps[0].Id;
         mzac.searchForZips();
         // no zips for this rep
         System.assertEquals(true,mzac.zipAsgnsFound);
         System.assertEquals(5,mzac.nbrZipAsgnsFound);
         
         // try to reassign without selecting any 
         mzac.startReassigningZips();
         System.assertEquals(false,mzac.isReassigning);
         
         // select all 5 zip codes
         mzac.selectAll = true;
         mzac.selectAllZips();
         
         // try to reassign again - should succeed now
         mzac.startReassigningZips();
         System.assertEquals(true,mzac.isReassigning);
         // should not be any district reassigning options
         System.assertEquals(false,mzac.hasDistrictReassignOptions);
         // should be reps
         System.assertEquals(true,mzac.hasAssignToUsers);
         
         // select a rep
         mzac.selectedAssignToUser = reps[1].Id;
         mzac.setReassignUser();
         
         System.assertEquals(true,mzac.reassignCriteriaEntered);
         
         // save the requests
         mzac.performAssignToSelection();
         
         // are there pending requests that need to be sent?
         System.assertEquals(true,mzac.hasPendingRequests);
         
         // check how many open requests. Technically there should be only 5, but since we did two operations on the same zip code there will be 10.
         System.assertEquals(10,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);
         
         // create wholesaler requests
         // set the segment name to internal
         mzac.selectedSegmentOption = UserHelper.WHOLESALER_INTERNAL;
         mzac.setSegment();
         
         mzac.selectedAvailableUser = reps[2].Id;
         mzac.searchForZips();
         
         // create a new codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // set to 5
         mzac.nbrToAdd = 5;
         mzac.changeAddZipQuantity();
         System.assertEquals(5,mzac.zipsToAdd.size());
         
         // populate some zip code values
         mzac.zipsToAdd[0].Name='12345';
         mzac.zipsToAdd[1].Name='12346';
         mzac.zipsToAdd[2].Name='12347';
         mzac.zipsToAdd[3].Name='12348';
         mzac.zipsToAdd[4].Name='12349';

         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);

         // set the segment name to internal
         mzac.selectedSegmentOption = UserHelper.WHOLESALER_EXTERNAL;
         mzac.setSegment();
         
         // set the rep to open
         mzac.selectedAvailableUser = ManageZipAssignController.OPEN_ASSIGNMENT;
         mzac.searchForZips();
         
         // create a new codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // only add 3 for external wholesaler
         mzac.nbrToAdd = 3;
         mzac.changeAddZipQuantity();
         System.assertEquals(3,mzac.zipsToAdd.size());
         
         // populate some zip code values
         mzac.zipsToAdd[0].Name='12345';
         mzac.zipsToAdd[1].Name='12346';
         mzac.zipsToAdd[2].Name='12347';

         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);

         // check how many open requests now. 
         System.assertEquals(18,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         // add more for the external
         // set to 200
         mzac.nbrToAdd = 200;
         mzac.changeAddZipQuantity();
         System.assertEquals(200,mzac.zipsToAdd.size());
         
         // populate zip code values
         for (Integer cnt=0; cnt<200; cnt++) {
            // zero pad to get 5 digits
            mzac.zipsToAdd[cnt].Name = '13'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt;
         }

         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);

         // add an extra 100
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         // add more for the external
         // set to 200
         mzac.nbrToAdd = 100;
         mzac.changeAddZipQuantity();
         System.assertEquals(100,mzac.zipsToAdd.size());
         
         // populate zip code values
         for (Integer cnt=200; cnt<300; cnt++) {
            // zero pad to get 5 digits
            mzac.zipsToAdd[cnt-200].Name = '13'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt;
         }

         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);

         // submit the requests
         mzac.sendRequestsToNSS();
         
         // verify the requests have been updated
         System.assertEquals(318,[select count() from ZipAssignmentRequest__c where Status__c='Submitted-Email Sent']);
         
      } // System.runAs(distUser
   } // testAsDistrict

   static testMethod void testAsSysAdmin() {
      setupOrgUnits();
      // link reps to the sales office
      // select 8 reps
      User[] reps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 8];
      
      for (User rep : reps) {
         rep.Cost_Center__c = OrgUnitMethodsTest.os3.CostCenter__c;
         rep.SalesOfficeNumber__c = OrgUnitMethodsTest.os3.Sales_Office_Number__c;
         rep.District__c = OrgUnitMethodsTest.os3.Name;
         rep.Sales_Org__c = OrgUnitMethodsTest.os3.Sales_Org__c;
      }
      update reps;
      
      // run as a system administrator 
      User sysAdmin = [Select Id, Name, Email from User where IsActive=true and Profile.Name=:Utilities.PROF_SYS_ADMIN limit 1];
      
      // create default prodlist for the sales org we're using
      List<NSSProductMap__c> prodList = new List<NSSProductMap__c>();
      prodList.add(new NSSProductMap__c(Name=OrgUnitMethodsTest.salesOrg1,Sales_Org__c=OrgUnitMethodsTest.salesOrg1,Description__c=OrgUnitMethodsTest.salesOrg1));
      prodList.add(new NSSProductMap__c(Name=OrgUnitMethodsTest.salesOrg2,Sales_Org__c=OrgUnitMethodsTest.salesOrg2,Description__c=OrgUnitMethodsTest.salesOrg2));
      insert prodList;

      // create extra email addresses to send to
      EmailAddresses__c[] addresses = new EmailAddresses__c[]{};
      addresses.add(new EmailAddresses__c(Name='test1',Email_Type__c='NSS',Email__c='test1@test.com'));
      addresses.add(new EmailAddresses__c(Name='test2',Email_Type__c='NSS',Email__c='test2@test.com'));
      insert addresses;

      // run as a system administrator
      System.runAs(sysAdmin) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(false,mzac.isDistrictUser);
         System.assertEquals(false,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(true,mzac.isCorporateUser);
         System.assertEquals(true,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
                  
         // verify should be 5 sales orgs - based on 3 divisions setup
         System.assertEquals(5,mzac.salesOrgPicklist.size());
         // set a sales org
         mzac.searchZa.Sales_Org__c = OrgUnitMethodsTest.os3.Sales_Org__c;
         mzac.changeOrgStructure();
         
         // select zone/district
         Org_Unit__c zone = [Select Id, Name, Org_Type__c, Sales_Org__c 
                               from Org_Unit__c 
                              where Org_Type__c=:OrgUnitMethods.TYPE_ZONE and Name=:OrgUnitMethodsTest.os3.Zone__c and Sales_Org__c=:OrgUnitMethodsTest.os3.Sales_Org__c];
         Org_Unit__c district = [Select Id, Name, Org_Type__c, Sales_Org__c 
                               from Org_Unit__c 
                              where Org_Type__c=:OrgUnitMethods.TYPE_DISTRICT and Name=:OrgUnitMethodsTest.os3.Name and Sales_Org__c=:OrgUnitMethodsTest.os3.Sales_Org__c];
         
         mzac.selectedZone = zone.Id;
         mzac.setZone();
         
         mzac.selectedDistrict = district.Id;
         mzac.setDistrict();
         
         // verify selected zone
         System.assertEquals(OrgUnitMethodsTest.os3.Zone__c,mzac.selectedZoneOrgUnit.Name);
         // verify selected district
         System.assertEquals(OrgUnitMethodsTest.os3.Name,mzac.selectedDistrictOrgUnit.Name);


         // should have 1 segment option because of DEFAULT
         System.assertEquals(1,mzac.segmentOptions.size());
         System.assertEquals(false,mzac.hasMultipleSegmentOptions);
         
         // should have zone options. Only one district setup in the zone so no district options.
         System.assertEquals(false,mzac.hasDistrictOptions);
         System.assertEquals(true,mzac.hasZoneOptions);
         
         // verify number of rep options - 8 reps setup, 1 for no rep, 1 to say to select a rep
         System.assertEquals(10,mzac.availableUsers.size());
         
         // select a rep
         mzac.selectedAvailableUser = reps[0].Id;
         mzac.searchForZips();
         
         // should be no zip codes returned
         System.assertEquals(true,mzac.searchPerformed);
         System.assertEquals(false,mzac.zipAsgnsFound);
         System.assertEquals(0,mzac.nbrZipAsgnsFound);
         System.assertEquals(false,mzac.addingZipCode);
         
         // create a new codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // defaults to 1
         System.assertEquals(1,mzac.zipsToAdd.size());
         
         // set to 5
         mzac.nbrToAdd = 5;
         mzac.changeAddZipQuantity();
         System.assertEquals(5,mzac.zipsToAdd.size());
         
         // populate some zip code values - add some bad ones, and leave one blank
         mzac.zipsToAdd[0].Name='12345';
         mzac.zipsToAdd[1].Name='123';
         mzac.zipsToAdd[2].Name='123456';
         mzac.zipsToAdd[3].Name='12345';
         mzac.saveNewZipRequest();
         // make sure you're still in the adding mode since there should be errors
         System.assertEquals(true,mzac.addingZipCode);
         
         // fix the zip codes so no errors
         mzac.zipsToAdd[1].Name='12346';
         mzac.zipsToAdd[2].Name='12347';
         mzac.zipsToAdd[3].Name='12348';
         mzac.zipsToAdd[4].Name='12349';
         mzac.saveNewZipRequest();
         // you should no longer be in the add mode
         System.assertEquals(false,mzac.addingZipCode);
         
         System.assertEquals(5,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         // 5 zip assignment records should exist
         System.assertEquals(5,[Select count() from Zip_Assignment__c where Organization_Structure__c=:OrgUnitMethodsTest.os3.Id]);
         // same selected user
         System.assertEquals(reps[0].Id, mzac.selectedAvailableUser);
         
         // user should now have 5 zip codes
         System.assertEquals(true,mzac.zipAsgnsFound);
         System.assertEquals(5,mzac.nbrZipAsgnsFound);
         
         // switch to another user then switch back
         // select a rep
         mzac.selectedAvailableUser = reps[1].Id;
         mzac.searchForZips();
         // no zips for this rep
         System.assertEquals(false,mzac.zipAsgnsFound);
         System.assertEquals(0,mzac.nbrZipAsgnsFound);
         
         // switch back - has the 5 zips again.
         mzac.selectedAvailableUser = reps[0].Id;
         mzac.searchForZips();
         // no zips for this rep
         System.assertEquals(true,mzac.zipAsgnsFound);
         System.assertEquals(5,mzac.nbrZipAsgnsFound);
         
         // try to reassign without selecting any 
         mzac.startReassigningZips();
         System.assertEquals(false,mzac.isReassigning);
         
         // select all 5 zip codes
         mzac.selectAll = true;
         mzac.selectAllZips();
         
         // try to reassign again - should succeed now
         mzac.startReassigningZips();
         System.debug('selectedAssignToOption='+mzac.selectedAssignToOption);
         System.assertEquals(true,mzac.isReassigning);
         System.assertEquals(true,mzac.isReassigningUser);
         System.assertEquals(false,mzac.isReassigningOther);
         
         // should not be district reassigning options - only setup 1 district.
         System.assertEquals(false,mzac.hasDistrictReassignOptions);
         // should be reps
         System.assertEquals(true,mzac.hasAssignToUsers);
         
         // select a rep
         mzac.selectedAssignToUser = reps[1].Id;
         // save the requests
         mzac.performAssignToSelection();
         
         // since we're using the same zip codes, should still be only 5 pending records.
         System.assertEquals(10,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         // go through the steps to reassign again
         mzac.selectAll = true;
         mzac.selectAllZips();
         // go into reassign mode
         mzac.startReassigningZips();
         
         mzac.selectedReassignZone = zone.Id;
         mzac.setReassignZone();
         
         mzac.selectedReassignDistrict = district.Id;
         mzac.setReassignDistrict();
         
         // cancel the reassign
         mzac.cancelReassign();

         //*************************************
         // we're going to reassign to OPEN, DSR, and OTHER just to test those methods
         // create 5 more zip codes against another rep
         // select a rep
         mzac.selectedAvailableUser = reps[2].Id;
         mzac.searchForZips();
         
         // create a new codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // set to 5
         mzac.nbrToAdd = 5;
         mzac.changeAddZipQuantity();
         System.assertEquals(5,mzac.zipsToAdd.size());
         
         // populate some zip code values - first one will have already been added so save should fail
         mzac.zipsToAdd[0].Name='12345';
         mzac.zipsToAdd[1].Name='23452';
         mzac.zipsToAdd[2].Name='23453';
         mzac.zipsToAdd[3].Name='23454';
         mzac.zipsToAdd[4].Name='23455';
         mzac.saveNewZipRequest();
         System.assertEquals(true,mzac.addingZipCode);

         // change to new value
         mzac.zipsToAdd[0].Name='23451';
         mzac.saveNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);

         // five more requests, so now there are 10
         System.assertEquals(15,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         // select 1 zip code
         mzac.allZipWraps[0].selected=true;
         
         // go to reassign mode
         mzac.startReassigningZips();
         System.assertEquals(true,mzac.isReassigning);

         // leave at user with no user selected
         mzac.selectedAssignToOption = 'User';
         mzac.selectedAssignToUser = null;
         // this should fail because of no user
         mzac.performAssignToSelection();
         System.assertEquals(true,mzac.isReassigning);
         
         // change to open
         mzac.selectedAssignToOption = ManageZipAssignController.OPEN_ASSIGNMENT;
         // should succeed.
         mzac.performAssignToSelection();
         System.assertEquals(false,mzac.isReassigning);
         
         // select the second zip code
         mzac.allZipWraps[1].selected=true;
         // go to reassign mode
         mzac.startReassigningZips();
         System.assertEquals(true,mzac.isReassigning);

         // change to DSR
         mzac.selectedAssignToOption = 'DSR';
         // should succeed.
         mzac.performAssignToSelection();
         System.assertEquals(false,mzac.isReassigning);

         // select the third zip code
         mzac.allZipWraps[2].selected=true;
         // go to reassign mode
         mzac.startReassigningZips();
         System.assertEquals(true,mzac.isReassigning);

         // change to DSR
         mzac.selectedAssignToOption = 'Other';
         // leave name blank - will fail
         mzac.queryZar.FirstName__c = null;
         mzac.queryZar.LastName__c = null;
         mzac.performAssignToSelection();
         System.assertEquals(true,mzac.isReassigning);
         
         // put in a value
         mzac.queryZar.FirstName__c = 'Jimmy';
         mzac.queryZar.LastName__c = 'Test';

         // should succeed.
         mzac.performAssignToSelection();
         System.assertEquals(false,mzac.isReassigning);

         //**********************************************
         
         // are there pending requests that need to be sent?
         System.assertEquals(true,mzac.hasPendingRequests);
         
         // we added 3 more requests
         System.assertEquals(18,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);
         
         // submit the requests
         mzac.sendRequestsToNSS();
         
         // verify the requests have been updated
         System.assertEquals(18,[select count() from ZipAssignmentRequest__c where Status__c='Submitted-Email Sent']);
         
      } // System.runAs(distUser
      
   } // testAsSysAdmin
    
   static testMethod void testAsZone() {
      setupOrgUnits();
      // link reps to the sales office
      // select 8 reps
      User[] reps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 8];
      // setup a zone user
      User zoneUser = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_ZSA limit 1];
      
      for (User rep : reps) {
         rep.Cost_Center__c = os6.CostCenter__c;
         rep.SalesOfficeNumber__c = os6.Sales_Office_Number__c;
         rep.District__c = os6.Name;
         rep.Sales_Org__c = os6.Sales_Org__c;
      }
      update reps;
      zoneUser.Cost_Center__c = os6.CostCenter__c;
      zoneUser.Sales_Org__c = os6.Sales_Org__c;
      update zoneUser;
       
      // create multiple zip segments
      Zip_Segment__c[] segments = new Zip_Segment__c[]{};
      segments.add(new Zip_Segment__c(Name='Segment1', Emps_Min__c=0, Emps_Max__c=100, Sales_Org__c=zoneUser.Sales_Org__c, Sort_Order__c=1));
      segments.add(new Zip_Segment__c(Name='Segment2', Emps_Min__c=101, Emps_Max__c=10000, Sales_Org__c=zoneUser.Sales_Org__c, Sort_Order__c=2));
      insert segments;

      // log in as a district user
      System.runAs(zoneUser) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(false,mzac.isDistrictUser);
         System.assertEquals(true,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(false,mzac.isCorporateUser);
         System.assertEquals(false,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
         
         // should have 3 segment options because of DEFAULT and wholesaler options.
         System.assertEquals(4,mzac.segmentOptions.size());
         System.assertEquals(true,mzac.hasMultipleSegmentOptions);

      } // System.runAs
      
   } // testAsZone
   
   static testMethod void testAsCoreDistrict() {
      setupOrgUnits();
      // link reps to the sales office
      // select 8 reps
      User[] reps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, HR_Person_Id__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 8];
      // setup a district user
      User distUser = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA limit 1];
      
      User runningUser = [Select Id, Name from User where Id=:UserInfo.getUserId()];
      
      // keep track of the rep ids 
      Id[] repIds = new Id[]{};
      for (User rep : reps) {
         rep.Cost_Center__c = os8.CostCenter__c;
         rep.SalesOfficeNumber__c = os8.Sales_Office_Number__c;
         rep.District__c = os8.Name;
         rep.Sales_Org__c = os8.Sales_Org__c;
      }
      update reps;
      distUser.Sales_Org__c = os8.Sales_Org__c;
      distUser.District__c = os8.Name;
      distUser.Cost_Center__c = '0000';
      update distUser;

      // select more reps that we'll make inactive
      User[] inactiveReps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, HR_Person_Id__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id not in :repIds limit 4];
       
      // create zip assignments tied to the inactive reps
      Zip_Assignment__c[] tempZas = new Zip_Assignment__c[]{};
      
      Integer counter=1;
      
      // setup inactive reps and zip assignments
      for (User rep : inactiveReps) {
         rep.Cost_Center__c = os8.CostCenter__c;
         rep.SalesOfficeNumber__c = os8.Sales_Office_Number__c;
         rep.District__c = os8.Name;
         rep.Sales_Org__c = os8.Sales_Org__c;
         // the reps will attach to the zip assignment by the person id.
         Zip_Assignment__c za = new Zip_Assignment__c(Name='1122'+counter++, HR_Person_Id__c=rep.HR_Person_Id__c, Sales_Org__c=rep.Sales_Org__c);
         tempZas.add(za);
      }
      insert tempZas;
       
      // inactivate the reps
      for (User rep : inactiveReps) {
         rep.IsActive = false;
      } // for
      System.runAs(runningUser) {
         update inactiveReps;
      }

      // log in as a district user
      System.runAs(distUser) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(true,mzac.isDistrictUser);
         System.assertEquals(false,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(false,mzac.isCorporateUser);
         System.assertEquals(false,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
         
         // verify the district org unit
         System.assertEquals(distUser.District__c,mzac.selectedDistrictOrgUnit.Name);
         System.assertEquals(distUser.Sales_Org__c,mzac.selectedDistrictOrgUnit.Sales_Org__c);
         
         // should have 1 segment option
         System.assertEquals(1,mzac.segmentOptions.size());
         System.assertEquals(false,mzac.hasMultipleSegmentOptions);
         
         // no district options since we're at a district level
         System.assertEquals(false,mzac.hasDistrictOptions);
         System.assertEquals(false,mzac.hasZoneOptions);
         
         // verify number of rep options - 8 reps setup, 1 for no rep, 1 to say to select a rep, and includes the DSA 
         System.assertEquals(11,mzac.availableUsers.size());
         System.assertEquals(true,mzac.hasAvailableUsers);
         
         // search for open zips
         mzac.selectedAvailableUser = ManageZipAssignController.OPEN_ASSIGNMENT;
         mzac.searchForZips();
         
         // add 200 new zip codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         
         mzac.cancelNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);

         // defaults to 1
         System.assertEquals(1,mzac.zipsToAdd.size());
         
         // set to 200
         mzac.nbrToAdd = 200;
         mzac.changeAddZipQuantity();
         System.assertEquals(200,mzac.zipsToAdd.size());
         
         // populate zip code values
         for (Integer cnt=0; cnt<200; cnt++) {
         	// zero pad to get 5 digits
            mzac.zipsToAdd[cnt].Name = '12'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt;
         }

         // enter criteria that will fail
         mzac.queryZar.FirstName__c = null;
         mzac.queryZar.LastName__c = null;
         
         // save should fail
         mzac.saveNewZipRequest();
         System.assertEquals(true,mzac.addingZipCode);
         
         // set to open instead
         mzac.queryZar.FirstName__c = ManageZipAssignController.OPEN_ASSIGNMENT;
         // save should succeed
         mzac.saveNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);
         System.assertEquals(200,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         
         // add more zip codes
         mzac.addNewZipCodes();
         System.assertEquals(true,mzac.addingZipCode);
         // set to 200
         mzac.nbrToAdd = 200;
         mzac.changeAddZipQuantity();
         System.assertEquals(200,mzac.zipsToAdd.size());
         // populate zip code values
         for (Integer cnt=0; cnt<200; cnt++) {
            // zero pad to get 5 digits
            mzac.zipsToAdd[cnt].Name = '13'+(cnt<10 ? '00' : (cnt<100 ? '0' : ''))+cnt;
         }
         // save should succeed
         mzac.saveNewZipRequest();
         System.assertEquals(false,mzac.addingZipCode);
         System.assertEquals(400,[select count() from ZipAssignmentRequest__c where Status__c='Pending']);

         // submit the requests
         mzac.sendRequestsToNSS();
         
         // verify the requests have been updated
         System.assertEquals(400,[select count() from ZipAssignmentRequest__c where Status__c='Submitted-Email Sent']);

      } // System.runAs
   } // testAsCoreDistrict
   
   static testMethod void testAsMmsDistrict() {
      setupOrgUnits();
      // link reps to the sales office
      // select 8 reps
      User[] reps = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 8];
      // setup a district user
      User distUser = [Select Id, Name, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=true and Job_Name__c=:UserHelper.JOB_DSA limit 1];
      // select inactive reps
      User[] inactiveReps = [Select Id, Name, HR_Person_Id__c, Sales_Org__c, Cost_Center__c, District__c, SalesOfficeNumber__c from User where IsActive=false and HR_Person_Id__c != null limit 4];
      
      for (User rep : reps) {
         rep.Cost_Center__c = os9.CostCenter__c;
         rep.SalesOfficeNumber__c = os9.Sales_Office_Number__c;
         rep.District__c = os9.Name;
         rep.Sales_Org__c = os9.Sales_Org__c;
      }
      update reps;
      distUser.Sales_Org__c = os9.Sales_Org__c;
      distUser.District__c = os9.Name;
      distUser.Cost_Center__c = '0000';
      update distUser;
       
      // create zip assignments tied to the inactive reps
      Zip_Assignment__c[] tempZas = new Zip_Assignment__c[]{};
      
      Integer counter=1;
      
      // setup inactive reps and zip assignments
      for (User rep : inactiveReps) {
         rep.Cost_Center__c = os9.CostCenter__c;
         rep.SalesOfficeNumber__c = os9.Sales_Office_Number__c;
         rep.District__c = os9.Name;
         rep.Sales_Org__c = os9.Sales_Org__c;
         Zip_Assignment__c za = new Zip_Assignment__c(Name='1122'+counter, HR_Person_Id__c=rep.HR_Person_Id__c, Sales_Org__c=rep.Sales_Org__c);
         tempZas.add(za);
      }
      update inactiveReps;
      insert tempZas;
       
      // log in as a district user
      System.runAs(distUser) {
         Test.SetCurrentPageReference(Page.ManageZipAssigns);
         //System.CurrentPageReference().getParameters().put('id',cgsChild.Id);
         ManageZipAssignController mzac = new ManageZipAssignController();
         // verify it's district user
         System.assertEquals(true,mzac.isDistrictUser);
         System.assertEquals(false,mzac.isZoneUser);
         System.assertEquals(false,mzac.isAreaUser);
         System.assertEquals(false,mzac.isCorporateUser);
         System.assertEquals(false,mzac.isSystemAdmin);
         System.assertEquals(true,mzac.isValidUser);
         
         // verify the district org unit
         System.assertEquals(distUser.District__c,mzac.selectedDistrictOrgUnit.Name);
         System.assertEquals(distUser.Sales_Org__c,mzac.selectedDistrictOrgUnit.Sales_Org__c);
         
         // should have 1 segment option
         System.assertEquals(1,mzac.segmentOptions.size());
         System.assertEquals(false,mzac.hasMultipleSegmentOptions);
         
         // no district options since we're at a district level
         System.assertEquals(false,mzac.hasDistrictOptions);
         System.assertEquals(false,mzac.hasZoneOptions);
         
         // verify number of rep options - 8 reps setup, 1 for no rep, 1 to say to select a rep, and includes the DSA 
         System.assertEquals(11,mzac.availableUsers.size());
         System.assertEquals(true,mzac.hasAvailableUsers);
         
         // search for open zips
         mzac.selectedAvailableUser = ManageZipAssignController.OPEN_ASSIGNMENT;
         mzac.searchForZips();
         
      } // System.runAs
   } // testAsMmsDistrict
   */
    static testMethod void testMisc2() {
       ManageZipAssignController mzac = new ManageZipAssignController();
       System.assertNotEquals(null,mzac.hasEditAccess);
       System.assertEquals('No District Found', mzac.districtName);
       System.assertEquals(false,mzac.hasSelectedDistrictOrgUnit);
       System.assertEquals(false,mzac.hasDistrictReassignOptions); 
       mzac.setReassignUser();
        
       mzac.addingZipCode=true;
       mzac.cancelNewZipRequest();
       System.assertEquals(false,mzac.addingZipCode);
        
       System.assertEquals(false,mzac.hasDistrictUserLinks);
       mzac.managingDistrict=false;
       mzac.manageDistrict();
       System.assertEquals(true,mzac.managingDistrict);
       mzac.cancelManageDistrict();
       System.assertEquals(false,mzac.managingDistrict);

    } // testMisc
    
} // class ManageZipAssignControllerTest