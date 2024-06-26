/* The class checks the value of the field District in the
   user record, and matches is to the name of the Organizational
   structure object to populate the user record. 
   
  History
  -------
  02/03/2009 Christophe Soulet   Created by Salesforce.com
  03/07/2011 Dan Carmen          Modified to clean up code. Added test methods to this class.
  04/27/2012 Dan Carmen          Added field to populate the area number.
  06/05/2012 Dan Carmen          Change error handling if can't find org structure.
  10/03/2012 Dan Carmen          Do not log error if System Admin is making change
  02/18/2013 Dan Carmen          Added logic for the SalesOfficeNumber__c to get populated
  03/04/2015 Dan Carmen          Changed when errors are logged - check if running user part of sales orgs.
  02/27/2017 Dan Carmen          Update both the cost center and sales office number back to the user from the org structure.
  06/15/2017 Dan Carmen          Change to match by Sales Office Number instead of Cost Center.
  08/14/2018 Dan Carmen          Update to use the Org_Unit__c objects
  09/11/2018 Dan Carmen          Update for org units in different structures using the same roles.
  08/06/2019 Dan Carmen          Handle Org Units for other than Districts  
  06/08/2020 Dan Carmen          Make sure that CostCenter is in correct format.
  07/06/2020  Jacob Hinds         Added without sharing per PMD
  06/23/2022 Josh Cartwright 	 INC3043656 - removed error to check for matching org structre 
  10/05/2023 Susmitha Somavarapu Commented the Cost Center field code(APR0159472)


  
 */
public without sharing class UpdateOrgInfo {
    
   public static Set<string> checkSalesOrgs = UserHelper.getDivisionStructureSet();
   
   public static void SetUserInfo(User[] usersToUpdate){

      // attempt to first populate using the UserRoleId against the Org_Unit__c objects.
      User[] remainingUsers = setByRoleId(usersToUpdate);

      Map<String, Organization_Structure__c> osByDist = new Map<String, Organization_Structure__c>();
      Map<String, Organization_Structure__c> osBySalesOffice = new Map<String, Organization_Structure__c>();

      if (!remainingUsers.isEmpty()) {
         getOrganizationStructures(remainingUsers, osByDist, osBySalesOffice);

      /*
      Set<String> districtNbrSet = new Set<String>();
      Set<String> salesOfficeNbrSet = new Set<String>();
      Set<String> salesOrgSet = new Set<String>();
      
        
      // build the list of District values
      for (User u : usersToUpdate) {
         // remove the leading zero to match the org structure - we'll add it back later (users are expecting leading zeroes)
         u.District__c = Utilities.removeLeadingZero(u.District__c);
         // make sure cost center is left padded
         u.Cost_Center__c = Utilities.leftPad(u.Cost_Center__c,'0',4);
         if (String.isNotBlank(u.District__c)) {
            districtNbrSet.add(u.District__c); 
            salesOrgSet.add(u.Sales_Org__c);
         }
         if (String.isNotBlank(u.SalesOfficeNumber__c)) {
            salesOfficeNbrSet.add(u.SalesOfficeNumber__c);
            salesOrgSet.add(u.Sales_Org__c);
         } // if 
           
      } // for (User u
        
      // make sure there's some data.
      if (!salesOrgSet.isEmpty()) {
        
         // retrieve the Org Structure data
         Organization_Structure__c[] orgStrcs =[Select Area__c
                                               ,Area_Number__c 
                                               ,Core_Area__c
                                               ,Sales_Office_Number__c
                                               ,Sales_Office_name__c
                                               ,Zone__c
                                               ,Zone_Name__c
                                               ,District_Name__c
                                               ,CostCenter__c
                                               ,Name
                                               ,Sales_Org__c
                                         From Organization_Structure__c 
                                         Where Exclude_From_Reports__c = false
                                           and (Name IN :districtNbrSet
                                            or Sales_Office_Number__c IN :salesOfficeNbrSet)
                                           and Sales_Org__c IN :salesOrgSet
                                          order by CreatedDate desc];
                                         
        
         Map<String, Organization_Structure__c> osByDist = new Map<String, Organization_Structure__c>();
         Map<String, Organization_Structure__c> osBySalesOffice = new Map<String, Organization_Structure__c>();
        
         for (Organization_Structure__c newOS:orgStrcs){
            // store by Sales Org and district number
            String distKey = newOS.Sales_Org__c+'-'+newOS.Name;
            // only put in the map if not already there - we'll use the newest record
            if (!osByDist.containsKey(distKey)) {
               osByDist.put(distKey,newOS);
            }
            osBySalesOffice.put(newOS.Sales_Org__c+'-'+newOS.Sales_Office_Number__c,newOS);
         }
         */
         // Check if we need to log an error if it exists
         Boolean logErrorIfExists = false;
         
         // get the current user information
         User curUser = UserHelper.getRunningUser();
         
         // if multiple records are being updated at once, don't log the error.
         // only check to log the error if not system admin and the running user is one of the sales orgs
         if (remainingUsers.size() == 1 && !curUser.Profile.Name.startsWith(Utilities.PROF_SYS_ADMIN) && checkSalesOrgs.contains(curUser.Sales_Org__c)) {
            // only log an error if organization structures actually exist - this will prevent the error from 
            // happening in sandboxes.
            logErrorIfExists = [select count() from organization_structure__c limit 1] > 0;
         } // if (usersToUpdate
                 
         
         // check the values against the array and update the fields if a match is found
         for (User u: remainingUsers){
            // first try by the sales office number. If a record is found, see if it matches the district or if the district is null.
            Organization_Structure__c os = (String.isNotBlank(u.SalesOfficeNumber__c) ? osBySalesOffice.get(u.Sales_Org__c+'-'+u.SalesOfficeNumber__c) : null);
            if (os != null) {
               // make sure the district matches what's on the user record, so we select the most correct organization structure record 
               if (String.isNotBlank(u.District__c) && u.District__c != os.Name) {
                  os = null;
               }
            } // if os != null
            if (os == null && String.isNotBlank(u.District__c)) {
               // if nothing by sales office, look by district
               os = osByDist.get(u.Sales_Org__c+'-'+Utilities.removeLeadingZero(u.District__c));
            }
            if (os != null) {
               u.Areatxt__c = os.Area__c;
               u.Area_Nbr__c = os.Area_Number__c;
               u.Core_Area__c = os.Core_Area__c;
               u.District_Name__c = os.District_Name__c;
                // make sure the district number on the user record is left padded.
               u.District__c = Utilities.leftPad(os.Name,'0',3);
               u.Zone__c = os.Zone__c;
               u.Zonetxt__c = os.Zone_Name__c;
             //  u.Cost_Center__c = os.CostCenter__c;
               u.SalesOfficeNumber__c = os.Sales_Office_Number__c;
            } else {
               // do check for sales org
               // make sure at least one of the key fields has a value in order to throw an error.
    /* removing per INC3043656 
                if ((String.isNotBlank(u.SalesOfficeNumber__c) || String.isNotBlank(u.District__c)) 
                         && logErrorIfExists && u.IsActive && checkSalesOrgs.contains(u.Sales_Org__c)) {
                  u.addError('Could not find a matching Organization Structure for the Sales Org '+u.Sales_Org__c+', District='+u.District__c+' Sales Office='+u.SalesOfficeNumber__c);
               }*/
               u.Areatxt__c = u.Sales_Org__c;
               u.Core_Area__c = u.Sales_Org__c;
               u.District_Name__c = u.Sales_Org__c;
               u.Zone__c = u.Sales_Org__c;
               u.Zonetxt__c = u.Sales_Org__c;
               u.SalesOfficeNumber__c = null; 
               //u.District__c = null;
            } // else  
            if (String.isBlank(u.Cost_Center__c)) {
               // we don't want a null cost center.
               u.Cost_Center__c = '0000';
            }
         } // for (User u: usersToUpdate
      } // if (!remainingUsers.isEmpty()
   }// Set userinfo
   
   
   public static void getOrganizationStructures(User[] usersToCheck, Map<String, Organization_Structure__c> osByDist
                                                ,Map<String, Organization_Structure__c> osBySalesOffice ) {

      Set<String> districtNbrSet = new Set<String>();
      Set<String> salesOfficeNbrSet = new Set<String>();
      Set<String> salesOrgSet = new Set<String>();
      
      // build the list of District values
      for (User u : usersToCheck) {
         // remove the leading zero to match the org structure - we'll add it back later (users are expecting leading zeroes)
         u.District__c = Utilities.removeLeadingZero(u.District__c);
         // make sure cost center is left padded
         //u.Cost_Center__c = Utilities.leftPad(u.Cost_Center__c,'0',4);
         if (String.isNotBlank(u.District__c)) {
            districtNbrSet.add(u.District__c); 
            salesOrgSet.add(u.Sales_Org__c);
         }
         if (String.isNotBlank(u.SalesOfficeNumber__c)) {
            salesOfficeNbrSet.add(u.SalesOfficeNumber__c);
            salesOrgSet.add(u.Sales_Org__c);
         } // if 
           
      } // for (User u
        
      if (!salesOrgSet.isEmpty()) {
         // retrieve the Org Structure data
         Organization_Structure__c[] orgStrcs =[Select Area__c
                                               ,Area_Number__c 
                                               ,Core_Area__c
                                               ,Sales_Office_Number__c
                                               ,Sales_Office_name__c
                                               ,Zone__c
                                               ,Zone_Name__c
                                               ,District_Name__c
                                               ,CostCenter__c
                                               ,Name
                                               ,Sales_Org__c
                                         From Organization_Structure__c 
                                         Where Exclude_From_Reports__c = false
                                           and (Name IN :districtNbrSet
                                            or Sales_Office_Number__c IN :salesOfficeNbrSet)
                                           and Sales_Org__c IN :salesOrgSet
                                          order by CreatedDate desc];
                                         
         for (Organization_Structure__c newOS:orgStrcs){
            // store by Sales Org and district number
            String distKey = newOS.Sales_Org__c+'-'+newOS.Name;
            // only put in the map if not already there - we'll use the newest record
            if (!osByDist.containsKey(distKey)) {
               osByDist.put(distKey,newOS);
            }
            osBySalesOffice.put(newOS.Sales_Org__c+'-'+newOS.Sales_Office_Number__c,newOS);
         }
      }
   } // getOrganizationStructures
   
   // Attempt to match the users to an Org Unit object by the User Role Id
   public static User[] setByRoleId(User[] usersToCheck) {
      Map<String, User[]> usrsByRoleIdMap = new Map<String, User[]>();
      User[] usersNotHandled = new User[]{};
      Set<Id> userRoleIdSet = new Set<Id>();
      Set<String> salesOrgSet = new Set<String>();
      
      // separate the users by UserRoleId
      for (User usr : usersToCheck) {
         if (usr.UserRoleId != null && String.IsNotBlank(usr.Sales_Org__c)) {
            String key = usr.Sales_Org__c+usr.UserRoleId;
            User[] roleUsers = usrsByRoleIdMap.containsKey(key) ? usrsByRoleIdMap.get(key) : new User[]{};
            roleUsers.add(usr);
            usrsByRoleIdMap.put(key, roleUsers);
            userRoleIdSet.add(usr.UserRoleId);
            salesOrgSet.add(usr.Sales_Org__c);
         } else {
            // if there's not a role we can't do anything here
            usersNotHandled.add(usr);
         }
         
      } // for (User usr
      
      System.debug('setByRoleId before query usersToCheck='+usersToCheck.size()+' usrsByRoleIdMap='+usrsByRoleIdMap.size()+' usersNotHandled='+usersNotHandled.size());
      if (usrsByRoleIdMap.isEmpty()) {
         System.debug('setByRoleId nothing to do here!');
         return usersNotHandled;
      }
      
      Org_Unit__c[] orgUnits = [Select Id, Name, Org_Unit_Name__c, Sales_Org__c   // district
                                      ,Assistant__c, Manager__c, Org_Type__c
                                      ,Query_Key__c
                                      ,RepUserRoleId__c,UserRoleId__c
                                      ,Parent__r.Id, Parent__r.Name, Parent__r.Org_Unit_Name__c    // zone 
                                      ,Parent__r.Parent__r.Id, Parent__r.Parent__r.Name 
                                      ,Parent__r.Parent__r.Org_Unit_Name__c// Area
                                      ,(Select Id, Name, Org_Unit_Name__c, Primary__c, Cost_Center__c
                                          From Children__r)   // sales office(s)
                                  From Org_Unit__c
                                 Where (RepUserRoleId__c in :userRoleIdSet
                                   or UserRoleId__c in :userRoleIdSet)
                                   and Sales_Org__c in :salesOrgSet];
                                   //and Org_Type__c = :OrgUnitMethods.TYPE_DISTRICT];
      System.debug('setByRoleId orgUnits='+orgUnits.size());      
      
      for (Org_Unit__c orgUnit : orgUnits) {
         User[] users = new User[]{};
         if (String.isNotBlank(orgUnit.RepUserRoleId__c) && usrsByRoleIdMap.containsKey(orgUnit.Sales_Org__c+orgUnit.RepUserRoleId__c)) {
            users.addAll(usrsByRoleIdMap.remove(orgUnit.Sales_Org__c+orgUnit.RepUserRoleId__c));
         }
         if (String.isNotBlank(orgUnit.UserRoleId__c) && usrsByRoleIdMap.containsKey(orgUnit.Sales_Org__c+orgUnit.UserRoleId__c)) {
            users.addAll(usrsByRoleIdMap.remove(orgUnit.Sales_Org__c+orgUnit.UserRoleId__c));
         }
         System.debug('setByRoleId orgUnit='+orgUnit.Query_Key__c+' users='+(users != null ? users.size() : -1));
         Org_Unit__c area = null;
         Org_Unit__c zone = null;
         Org_Unit__c district = null;
         Org_Unit__c salesOffice = null;
         
         if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DISTRICT) {
            district = orgUnit;
            salesOffice = (!orgUnit.Children__r.isEmpty() ? orgUnit.Children__r[0] : null);
            // should always be a zone and an area
            zone = orgUnit.Parent__r;
            area = (orgUnit.Parent__r != null ? orgUnit.Parent__r.Parent__r : null);
         } else if (OrgUnit.Org_Type__c == OrgUnitMethods.TYPE_ZONE) {
            zone = orgUnit;
            area = orgUnit.Parent__r;
         } else if (OrgUnit.Org_Type__c == OrgUnitMethods.TYPE_AREA) {
            area = orgUnit;
         }

         //Org_Unit__c salesOffice = (!district.Children__r.isEmpty() ? district.Children__r[0] : null);
         // should always be a zone and an area
         //Org_Unit__c zone = district.Parent__r;
         //Org_Unit__c area = (district.Parent__r != null ? district.Parent__r.Parent__r : null);
         System.debug('setByRoleId salesOffice='+(salesOffice != null ? salesOffice.Name : 'null')+' zone='+(zone != null ? zone.Name : 'null')
                                  +' area='+(area != null ? area.Name : 'null'));
         if (!users.isEmpty()) {
            for (User usr : users) {
               System.debug('Setting values on usr='+usr.Name);
               if (district != null) {
                  usr.District_Name__c = district.Org_Unit_Name__c;
                   // make sure the district number on the user record is left padded.
                  usr.District__c = Utilities.leftPad(district.Name,'0',3);
               } else {
                  usr.District__c = orgUnit.Sales_Org__c;
                  usr.District_Name__c = orgUnit.Sales_Org__c;
               }
               if (salesOffice != null) {
                  // this shouldn't be a null value
                  String costCenter = (salesOffice.Cost_Center__c != null ? salesOffice.Cost_Center__c : usr.Cost_Center__c);
                  // make sure it's not a null value and not more than 4 characters
                  costCenter = (String.isBlank(costCenter) ? '0' : costCenter.left(4));
                  // make sure 4 characters
                  while (costCenter.length() < 4) {
                     costCenter = '0'+costCenter;
                  }
              //    usr.Cost_Center__c = (salesOffice.Cost_Center__c != null ? salesOffice.Cost_Center__c : usr.Cost_Center__c);
                  usr.SalesOfficeNumber__c = salesOffice.Name;
               } else {
                  //usr.Cost_Center__c = (district != null ? usr.District__c : orgUnit.Sales_Org__c);
                  usr.SalesOfficeNumber__c = (district != null ? usr.District__c : orgUnit.Sales_Org__c);
               }
               if (zone != null) {
                  usr.Zone__c = zone.Name;
                  usr.Zonetxt__c = zone.Org_Unit_Name__c;
               } else {
                  usr.Zone__c = orgUnit.Sales_Org__c;
                  usr.Zonetxt__c = orgUnit.Sales_Org__c;
               }
               if (area != null) {
                  usr.Areatxt__c = area.Org_Unit_Name__c;
                  usr.Area_Nbr__c = area.Name;
                  usr.Core_Area__c = area.Name;
               } else {
                  usr.Areatxt__c = orgUnit.Sales_Org__c;
                  usr.Area_Nbr__c = orgUnit.Sales_Org__c;
                  usr.Core_Area__c = orgUnit.Sales_Org__c;
               }
               if (String.isBlank(usr.Cost_Center__c)) {
                  // we don't want a null cost center.
                  usr.Cost_Center__c = '0000';
               }
            } // for (User usr
         } // if (users != null)
      } // for (Org_Unit__c orgUnit
      
      // anything left in the map hasn't been handled here
      // add them all in the list to be processed by the other code
      System.debug('setRoleById usrsByRoleIdMap='+usrsByRoleIdMap.size());
      for (User[] users : usrsByRoleIdMap.values()) {
         usersNotHandled.addAll(users);
      }
      System.debug('setRoleById usersNotHandled='+usersNotHandled.size());
      return usersNotHandled;
   } // setByRoleId
   
} // updateOrgInfo