/* Methods for the Org_Unit__c object.
   
  History
  -------
  04/04/2012 Dan Carmen   Created
  06/19/2012 Dan Carmen   Added update to the OrgUnitBefore trigger.
  03/15/2013 Dan Carmen   Added methods to build out the org structure into a true hierarchy.
  07/18/2013 Dan Carmen   Fix linking of users at district level
  06/03/2014 Cindy Freeman  Added DSA_FSS__c and ManagerId to ORG_UNIT_SELECT for assistant, manager and user  
  02/27/2015 Dan Carmen   Change OrgUnitJob to be a batch process
  11/23/2015 Dan Carmen   Change to be able to create a default area for a structure.
  11/21/2016 Dan Carmen   Select Org units based on user being Assistant or Manager.
  09/05/2018 Dan Carmen   Add ability to update cost center from Organization Structure
  10/09/2018 Jacob Hinds  Adding Aso partner query fields
  05/01/2020 Dan Carmen   Added ability to set the role from the Org Strc record.
  06/08/2020 Dan Carmen   Remove delete of unused org units
  01/22/2021 Dan Carmen   If no area, default the area name to the Sales Org
  06/09/2021 Dan Carmen   Change in finding role names for MMS since they changed their name format.
  08/25/2021 Dan Carmen   Modified to get user info from ZipQueries (so changes will be in one place)
  03/02/2022 Josh Cartwright updated checkForUserUpdate to process users if the assistant changes on the org
  03/18/2022 Dan Carmen   Fix for updating users
  07/19/2022 Dan Carmen   Fix for populating Org Unit User Links
  11/11/2022 Dan Carmen   Don't create a new Org Unit if the org unit number is blank
  07/15/2023 Pratik Das   APR0151864: SMB Channel Evolution BAU--Queue_Name__c added to the query
  09/05/2023 Dan Carmen   Skip role check if override flag is set and the name and id are populated
  11/09/2023 Dan Carmen   Add check to make sure 18 character ids added.
  01/25/2024 Dan Carmen   Change OrgUnitRoleSetup__mdt to select based on TopLevel__c field instead of Division

 */
public with sharing class OrgUnitMethods {
   public static Boolean SKIP_TRIGGERS=false;

   public static String TYPE_COST_CENTER='Cost Center';
   public static String TYPE_SALES_OFFICE='Sales Office';
   public static String TYPE_DISTRICT='District';
   public static String TYPE_ZONE='Zone';
   public static String TYPE_AREA='Area';
   public static String TYPE_DIVISION='Division';
   
   public static String[] ORG_TYPE_LIST = new String[]{TYPE_DIVISION,TYPE_AREA,TYPE_ZONE,TYPE_DISTRICT,TYPE_SALES_OFFICE};
   
   public static void processTriggerRecords(List<Org_Unit__c> orgs, Boolean isInsert) {
      if (isInsert) {
         orgs = checkForDups(orgs);
      }
      checkForProfiles(orgs);
   } // processTriggerRecords
   
   /** Check to make sure there isn't already an org unit of the same type and number.
       If a record is a duplicate, it will not be returned. Only non-duplicates are returned.
    */
   public static List<Org_Unit__c> checkForDups(List<Org_Unit__c> checkOrgs) {

      // a map of query key to Org_Unit__c
      Map<String,Org_Unit__c> orgUnitMap = new Map<String,Org_Unit__c>();
      // get all of the query keys
      for (Org_Unit__c org : checkOrgs) {
         // remove the leading zeroes from the Org_Unit_Number__c, just in case. We want to enforce this.
         org.Name = Utilities.removeLeadingZero(org.Name);
         String key = (String.isBlank(org.Sales_Org__c) ? 'NONE' : org.Sales_Org__c)+org.Org_Type__c+org.Name;
         // only first will be added - subsequent ones will be ignored
         if (!orgUnitMap.containsKey(key)) {
            orgUnitMap.put(key,org);
         }
      } // for
      
      // query for existing org units
      Org_Unit__c[] queryOrgs = [Select Id, Query_Key__c from Org_Unit__c where Query_Key__c in :orgUnitMap.keySet()];
      // if any of the return set exist in the map, remove them and mark as error
      for (Org_Unit__c org : queryOrgs) {
         Org_Unit__c foundOrg = orgUnitMap.remove(org.Query_Key__c);
         if (foundOrg != null) {
            // mark as error
            foundOrg.addError('A record was already found for Org Type='+foundOrg.Org_Type__c+' and Org Unit Number='+foundOrg.Name+' queryKey='+org.Query_Key__c);
         }
      } // for (Org_Unit__c
      return orgUnitMap.values();
   } // checkForDups
   
   /** If the Org Type is Cost Center, find all of the profiles associated with it.
    */
   public static void checkForProfiles(List<Org_Unit__c> checkOrgs) {
      // the Org Units that are of type Cost Center
      Map<String,Org_Unit__c> costCenterOrgs = new Map<String,Org_Unit__c>();
      for (Org_Unit__c org : checkOrgs) {
         if (org.Org_Type__c == 'Cost Center') {
            // cost center on the user record is left padded with Zeroes - left pad the key
            String key = Utilities.leftPad(org.Name, '0', 4);
            costCenterOrgs.put(key,org);
         }
      } // for
      
      if (!costCenterOrgs.isEmpty()) {
         // keep track of unique profiles for each org
         Map<String,Set<String>> profileMap = new Map<String,Set<String>>();
         // query for Users and their profiles
         for (User[] users : [Select Id, Cost_Center__c, Profile.Name from User where IsActive=true and Cost_Center__c in :costCenterOrgs.keySet()]) {
            for (User u : users) {
               Set<String> profileSet = profileMap.get(u.Cost_Center__c);
               if (profileSet == null) {
                  profileSet = new Set<String>();
                  profileMap.put(u.Cost_Center__c,profileSet);
               } // if (profileSet == null
               profileSet.add(u.Profile.Name);
            } // for (User u
         } // for (User[] users
         
         for (String key : costCenterOrgs.keySet()) {
            Org_Unit__c org = costCenterOrgs.get(key);
            setAvailableProfiles(org,profileMap.get(key));
         }
      } // if (!costCenterOrgs
   } // checkForProfiles
   
   public static void setAvailableProfiles(Org_Unit__c org, Set<String> profileSet) {
      String profiles = null;
      
      if (profileSet != null && !profileSet.isEmpty()) {
         // make a list and sort
         List<String> profileList = new List<String>();
         profileList.addAll(profileSet);
         profileList.sort();
         
         for (String prof : profileList) {
            if (profiles == null) {
               profiles = '';
            } else {
               profiles += ';';
            }
            profiles += prof;
         } // for (String prof
      } // if (profileSet != null)
      
      org.Available_Profiles__c = profiles;
   } // setAvailableProfiles
   
   /** Get the org unit attached to the passed in user via the org unit user links (if one exists).
    */
   public static Org_Unit__c[] getUserOrgUnits(User usr) {
    Org_Unit__c[] orgUnits = getOrgUnits(null,null,null,new User[]{usr}, null);
    return orgUnits;
    /*
      Org_Unit__c foundOrgUnit = null;

      if (!orgUnits.isEmpty()) {
        // should only be one record returned.
         foundOrgUnit = orgUnits[0];
      }
     
      return foundOrgUnit;
      */
   } // getUserOrgUnit
   //APR0151864: SMB Channel Evolution BAU--Queue_Name__c added to the query
   public static final String ORG_UNIT_SELECT='Select Id, Name,Queue_Name__c'+
                                      ',Assistant__c'+
                                      ',Assistant__r.Id'+
                                      ',AssistantEmail__c'+
                                      ',AssistantName__c'+
                                      ',Cost_Center__c'+
                                      ',DoNotEvaluateRoles__c'+
                                      ',EndDate__c'+
                                      ',Manager__c'+
                                      ',Manager__r.Id'+
                                      ',MgrEmail__c'+
                                      ',MgrName__c'+ 
                                      ',Org_Type__c'+
                                      ',Org_Unit_Name__c'+
                                      ',OverrideAssistant__c'+
                                      ',OverrideMgr__c'+
                                      ',OverrideRepUserRoleName__c'+
                                      ',OverrideUserRoleName__c'+
                                      ',Parent__c'+
                                      ',Parent__r.Id'+
                                      ',Parent__r.Name'+
                                      ',Parent__r.Org_Type__c'+
                                      ',Parent__r.Org_Unit_Name__c'+
                                      ',ProcessNotes__c'+
                                      ',Query_Key__c'+
                                      ',RepUserRoleId__c'+
                                      ',RepUserRoleName__c'+
                                      ',RolesSetByOrgStructure__c'+
                                      ',Sales_Org__c'+
                                      ',StartDate__c'+
                                      ',UserRoleId__c'+
                                      ',UserRoleName__c'+
                                      ',(Select Id, Name'+
                                      '        ,Org_Unit_Name__c,Org_Type__c, Primary__c'+
                                      '    From Children__r'+
                                      '   order by Primary__c desc, Name asc)'+
                                      ',(Select Id'+
                                      '       ,Job_Name__c'+
                                      '       ,User__c'+
                                      '       ,User__r.Id'+
                                      '    From Org_Unit_User_Links__r'+
                                      '      order by Job_Name__c)'+
                                  'From Org_Unit__c';
   
   public static final String WHERE_START=' Where ';
   public static final String WHERE_AND=' and ';
   
   /** Retrieve a list of org units based on the passed in parameters.
    */
   public static Org_Unit__c[] getOrgUnits(Org_Unit__c[] parentOus, String childOrgUnitType, Id[] orgUnitIds, User[] usrs, String[] queryKeys) {
    
      String query = ORG_UNIT_SELECT;
      
      Id[] userIds = new Id[]{};
      Id[] roleIds = new Id[]{};
      Boolean skipOrgUnitIdCheck = false;

      // build the where clause
      String whereClause = WHERE_START;

      if (usrs != null && !usrs.isEmpty()) {
         for (User usr : usrs) {
            userIds.add(usr.Id);
            roleIds.add(usr.UserRoleId);
         }
         if (orgUnitIds == null) {
            orgUnitIds = new Id[]{};
         }
         for (Org_Unit_User_Link__c ouul : [Select Id, Org_Unit__c From Org_Unit_User_Link__c Where User__c in :userIds]) {
            orgUnitIds.add(ouul.Org_Unit__c);
         }
         query += whereClause+'( Assistant__c in :userIds or Manager__c in :userIds or RepUserRoleId__c in :roleIds or UserRoleId__c in :roleIds ';
         if (!orgUnitIds.isEmpty()) {
            query += ' or Id in :orgUnitIds';
         }
         query += ')';
         whereClause = WHERE_AND;
         skipOrgUnitIdCheck = true;
      } // if (usrs != null &&

      Id[] parentIds = new Id[]{};
      if (parentOus != null) {
         for (Org_Unit__c ou : parentOus) {
            parentIds.add(ou.Id);
         }
      } // if (parentOus != null)
      if (!parentIds.isEmpty()) {
        // to account for retrieving at district level - to go up the tree to division with area in the hierarchy
         query += whereClause+' (Parent__c in :parentIds or Parent__r.Parent__c in :parentIds or Parent__r.Parent__r.Parent__c in :parentIds)';
         whereClause = WHERE_AND;
      }
      if (String.isNotBlank(childOrgUnitType)) {
         query += whereClause+' Org_Type__c=:childOrgUnitType';
         whereClause = WHERE_AND;
      }
      //if (childNbrs != null && !childNbrs.isEmpty()) {
      //   query += whereClause +' Name in :childNbrs';
      //   whereClause = WHERE_AND;
      //}
      
      if (!skipOrgUnitIdCheck && orgUnitIds != null && !orgUnitIds.isEmpty()) {
         query += whereClause + ' Id in :orgUnitIds';
         whereClause = WHERE_AND;
      }
      
      // dynamic SOQL doesn't like using :usr.Id, so using a local variable for the id.
      //Id userId = (usr != null ? usr.Id : null);
      /* 
      if (usrs != null && !usrs.isEmpty()) {
        for (User usr : usrs) {
           userIds.add(usr.Id);
        }
        System.debug('getOrgUnits userIds='+userIds);
         query += whereClause + 'Id in (Select Org_Unit__c From Org_Unit_User_Link__c Where User__c in :userIds)';
         whereClause = WHERE_AND;
      }
      */
      if (queryKeys != null && !queryKeys.isEmpty()) {
         query += whereClause +' Query_Key__c in :queryKeys';
         whereClause = WHERE_AND;
      }
      // make sure something was added to the where clause before performing the select
      if (whereClause != WHERE_START) {
        query += ' order by Org_Unit_Number_Padded__c';
         System.debug('getOrgUnits query='+query);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOrgUnits query='+query));
        
         Org_Unit__c[] orgUnits = Database.query(query);
         Set<Id> userIdSet = checkForUserIds(orgUnits);
         Map<Id,User> userMap = ZipQueries.getZipUserMap(userIdSet);
         setUserIds(orgUnits, userMap);
          
         System.debug('getOrgUnits number retrieved='+orgUnits.size()+' userIdSet='+userIdSet.size()+' userMap='+userMap.size());
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOrgUnits number retrieved='+orgUnits.size()));
         return orgUnits;
      }
      // return an empty array if can't perform the query
      System.debug('getOrgUnits query not performed - no where clause!');
      return new Org_Unit__c[]{};
   } // getOrgUnits
    
   public static Set<Id> checkForUserIds(Org_Unit__c[] orgUnits) {
      Set<Id> userIds = new Set<Id>();
      for (Org_Unit__c ou : orgUnits) {
         if (ou.Assistant__c != null) {
            userIds.add(ou.Assistant__c);
         }
         if (ou.Manager__c != null) {
            userIds.add(ou.Manager__c);
         }
         for (Org_Unit_User_Link__c ouul : ou.Org_Unit_User_Links__r) {
            if (ouul.User__c != null) {
               userIds.add(ouul.User__c);
            }
         }
      } // for (Org_Unit__c ou : orgUnits
      return userIds;
   } // checkForUserIds
    
   public static void setUserIds(Org_Unit__c[] orgUnits, Map<Id,User> userMap) {
      for (Org_Unit__c ou : orgUnits) {
         if (ou.Assistant__c != null) {
            ou.Assistant__r = userMap.get(ou.Assistant__c);
         }
         if (ou.Manager__c != null) {
            ou.Manager__r = userMap.get(ou.Manager__c);
         }
         for (Org_Unit_User_Link__c ouul : ou.Org_Unit_User_Links__r) {
            if (ouul.User__c != null) {
               ouul.User__r = userMap.get(ouul.User__c);
            }
         }
          
      } // for (Org_Unit__c ou : orgUnits)
   } // setUserIds
    

   
   // use the UserRoleId to select the org units - only select based on rep roles at this point
   public static Org_Unit__c[] getOrgUnitsByUserRole(Set<String> p_userRoleIdSet) {
      Set<String> userRoleIdSet = p_userRoleIdSet;
      
      if (!userRoleIdSet.isEmpty()) {
         String query = ORG_UNIT_SELECT+' where (RepUserRoleId__c in :userRoleIdSet)';
         query += ' order by Org_Unit_Number_Padded__c';
         System.debug('getOrgUnits query='+query);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOrgUnitsByUserRole query='+query));
         
         Org_Unit__c[] orgUnits = Database.query(query);
         Set<Id> userIdSet = checkForUserIds(orgUnits);
         Map<Id,User> userMap = ZipQueries.getZipUserMap(userIdSet);
         setUserIds(orgUnits, userMap);
         System.debug('getOrgUnitsByUserRole number retrieved='+orgUnits.size());
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOrgUnitsByUserRole number retrieved='+orgUnits.size()));
         return orgUnits;
      }
      // return an empty array if can't perform the query
      System.debug('getOrgUnitsByUserRole query not performed - no role ids passed in!');
      return new Org_Unit__c[]{};
   } // getOrgUnitsByUserRole
   
   public Integer nbrStrcsProcessed = 0;
   public Integer nbrExistingOrgUnits = 0;
   public Integer nbrOrgUnitsCreated = 0;
   public Integer nbrOrgUnitsUpdated = 0;
   public Integer nbrOrgUnitsDeleted = 0;
   public Integer nbrRolesMatched = 0;
   public Integer nbrRolesNotMatched = 0;
   public Integer nbrUserLinksCreated = 0;
   public Integer nbrUserLinksDeleted = 0;
   public Integer nbrUserLinksLeftAlone = 0;

   public String logMsg = '';
   public String logFile = '';
   
   public static final String LOG_FILE_HEADER='Id,Org_Unit_Name__c,Org_Nbr,Sales_Org__c,Org_Type__c,RoleType,RoleName\n';

   public String getLogFile() {
      if (String.isNotBlank(logFile)) {
         logFile = LOG_FILE_HEADER+logFile;
      }
      return logFile;
   } // getLogFile
   
   /** Use this so it can be overwritten for testing. */
   public static List<String> SALES_ORGS = UserHelper.getDivisionStructureList();
   
   // a map of all of the userRoles
   public static Map<String,UserRole> userRoleMap = null;
   
   public static String[] TOP_SALES_ROLES = Label.OrgUnitMethods_TopLevels.split(',');
   
    /*
   // make sure the map is setup
   public static void checkUserRoleMap() {
      if (userRoleMap == null) {
         System.debug('checkUserRoleMap TOP_SALES_ROLES='+TOP_SALES_ROLES);
         userRoleMap = new Map<String,UserRole>();
         for (String topRoleName : TOP_SALES_ROLES) {
            Map<String,UserRole> tempUserRoleMap = UserHelper.getUserRoleMap(topRoleName);
            // upper case all of the role names so we don't have to worry about case
            for (String key : tempUserRoleMap.keySet()) {
               userRoleMap.put(key.toUpperCase(), tempUserRoleMap.get(key));
            }
         } // for (String topRoleName
      }
   } // checkUserRoleMap
   */
   
   // used to provide a backup method to interp
   //public Map<String,UserRoleMap__c> userRoleMapByKey = null;
   
   private Map<Id,Org_Unit_User_Link__c> linksToDelete = new Map<Id,Org_Unit_User_Link__c>();
   
    /*
   public void checkOrgStructure() {
      // run each sales org individually
      for (SalesOrg__c salesOrg : SalesOrg__c.getAll().values()) {
         if (salesOrg.HasOrgStructure__c) {
            checkOrgStructure(salesOrg.Name);
         }
      }
   } // checkOrgStructure
  */
   // so we don't have to keep retrieving data
   public static Map<String,UserRole> v_byNameMap = new Map<String,UserRole>();
   public static Map<Id,UserRole[]> v_byParentIdMap = new Map<Id,UserRole[]>();
   public static Map<Id,UserRole> v_byIdMap = new Map<Id,UserRole>();
   public static Set<String> orgsRetrieved = new Set<String>();
   
   // Check for duplicates in the Organization Structure objects.
   //  Setup Org Unit objects to mimic the setup in the Organization Structure
   // Select All Organization Structures
   // Select All Org Units where type is Sales Office, District, Zone, Area, or Division
   // For each sales org, order by sales office.
   // Keep track of each sales office. Make sure only one sales office/sales org combination
   // may have to do a 2-pass save. Won't be able to set parents until we have an id.
   public void checkOrgStructure(String salesOrg) {
      SalesOrg__c soSetting = (String.isNotBlank(salesOrg) ? SalesOrg__c.getInstance(salesOrg) : null);
      if (soSetting == null) {
         System.debug('checkOrgStructure count not process salesOrg='+salesOrg+' soSetting='+soSetting);
         return;
      }
      if (!Test.isRunningTest()) {
         v_byNameMap.clear();
         v_byParentIdMap.clear();
         v_byIdMap.clear();
         orgsRetrieved.clear();
      }
      
      //Map<String,UserRole> byNameMap = new Map<String,UserRole>();
      //Map<Id,UserRole[]> byParentIdMap = new Map<Id,UserRole[]>();
      if (!orgsRetrieved.contains(salesOrg)) {
         String[] topRoles = new String[]{};
         OrgUnitRoleSetup__mdt[] topLevels = [Select Id, MasterLabel, SalesOrg__c, OrgType__c, OrgNbr__c, PartialMatch__c, RoleName__c 
                                             from OrgUnitRoleSetup__mdt where SalesOrg__c=:salesOrg and TopLevel__c=true and RoleName__c != null];
         for (OrgUnitRoleSetup__mdt topLevel : topLevels) {
             topRoles.add(topLevel.RoleName__c);
         }
         System.debug('checkOrgStructure topLevels='+topLevels+' topRoles='+topRoles);
         if (topRoles.isEmpty()) {
            topRoles = TOP_SALES_ROLES;
         }
         System.debug('checkOrgStructure salesOrg='+salesOrg+' topRoles='+topRoles+' v_byNameMap='+v_byNameMap.size()+' v_byParentIdMap='+v_byParentIdMap.size()+' v_byIdMap='+v_byIdMap.size());
         UserHelper.findUserRoles(topRoles,v_byNameMap, v_byParentIdMap, v_byIdMap);
         orgsRetrieved.add(salesOrg);
      }
      // collect the setups valid for this sales org so we don't have to always go through the entire list
      OrgUnitRoleSetup__mdt[] roleSetups = [Select Id, MasterLabel, SalesOrg__c, OrgType__c, OrgNbr__c, PartialMatch__c, RoleName__c from OrgUnitRoleSetup__mdt where SalesOrg__c=:salesOrg];
       
      String[] salesOrgs = new String[]{salesOrg};
      // get the org units currently set up. Anything left here at the end will be deleted.
      Map<String,OrgUnitWrapper> orgUnitMapUnused = new Map<String,OrgUnitWrapper>();
      getOrgUnitMap(orgUnitMapUnused,null,salesOrgs,new Set<String>());
      
      // get the sales roles
      //checkUserRoleMap();

      Integer salesOrgExisting = orgUnitMapUnused.size();   
      nbrExistingOrgUnits += salesOrgExisting;
      System.debug('checkOrgStructure salesOrg='+salesOrg+' salesOrgExisting='+salesOrgExisting+' nbrExistingOrgUnits='+nbrExistingOrgUnits+' roleSetups='+roleSetups.size());
      
      // the records used. These will all be saved at the end.
      Map<String,OrgUnitWrapper> orgUnitMapUsed = new Map<String,OrgUnitWrapper>();
      
      for (Organization_Structure__c[] strcs : [Select Id, Name
                                                      ,Area__c
                                                      ,Area_Number__c
                                                      ,CostCenter__c
                                                      ,CostCenterQueryKey__c
                                                      ,District_Name__c
                                                      ,District_Query_Key__c
                                                      ,End_Date__c
                                                      ,Role_Area__c
                                                      ,Role_District__c
                                                      ,RoleId_Area__c
                                                      ,RoleId_District__c
                                                      ,RoleId_Sales_Office__c
                                                      ,RoleId_Zone__c
                                                      ,Role_Sales_Office__c
                                                      ,Role_Zone__c
                                                      ,Sales_Office_name__c
                                                      ,Sales_Office_Number__c
                                                      ,SalesOfficeQueryKey__c
                                                      ,Sales_Org__c
                                                      ,Start_Date__c
                                                      ,Zone__c
                                                      ,Zone_Name__c
                                                  From Organization_Structure__c
                                                 Where Sales_Org__c in :salesOrgs
                                                   and End_Date__c = null
                                                   and Exclude_From_Reports__c = false]) {
         nbrStrcsProcessed += strcs.size();
                                                       
         // only one sales org is being processed at a time - we just need to check it once for the loop.
         SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(salesOrg);
         Boolean hasArea = (salesOrgSetting != null ? salesOrgSetting.StrcHasArea__c : false);
         System.debug('checkOrgStructure salesOrgs='+salesOrgs+' strcs='+strcs.size()+' hasArea='+hasArea);
         
         for (Organization_Structure__c strc : strcs) {
            checkOrgStrc(strc,orgUnitMapUsed,orgUnitMapUnused,hasArea,v_byNameMap,v_byParentIdMap,v_byIdMap,roleSetups);
         } // for (Organization_Structure__c strc
      } // for (Organization_Structure__c[]

      System.debug('checkOrgStructure orgUnitMapUsed='+orgUnitMapUsed.size()+' orgUnitMapUnused='+orgUnitMapUnused.size());
      // we will be checking for saves twice if there's an insert. The first pass to save inserts, the second pass will be to set the parent ids on any records we had to insert. 
      Map<String,OrgUnitWrapper> extraRecs = checkForSaves(orgUnitMapUsed, true); 
      if (!extraRecs.isEmpty()) {
         checkForSaves(extraRecs, false);
      }
   
      // if the unused map still has records in it, we will delete those since they're not being used.
      checkForDeletes(orgUnitMapUnused);
   
      // check for user link inserts
      checkForUserLinkInserts(orgUnitMapUsed.values());
      
      checkForDsmDsa();
      
      System.debug('nbrStrcsProcessed='+nbrStrcsProcessed+' nbrExistingOrgUnits='+nbrExistingOrgUnits+' nbrOrgUnitsCreated='+nbrOrgUnitsCreated+' nbrOrgUnitsUpdated='+nbrOrgUnitsUpdated+' nbrOrgUnitsDeleted='+nbrOrgUnitsDeleted+' nbrDsmUpdated='+nbrDsmUpdated+' nbrDsaUpdated='+nbrDsaUpdated);
   } // checkOrgStructure
   
   public Integer nbrDsmUpdated = 0;
   public Integer nbrDsaUpdated = 0;
   
   // set the DSM and DSA on the org unit record to make it easier to find them.
   public void checkForDsmDsa() {
      Org_Unit__c[] updateOrgUnits = new Org_Unit__c[]{};
      for (Org_Unit__c district : [Select Id
                                         ,Assistant__c
                                         ,Assistant__r.IsActive
                                         ,Manager__c
                                         ,Manager__r.IsActive
                                         ,OverrideAssistant__c
                                         ,OverrideMgr__c
                                         ,(Select Id
                                                 ,Job_Name__c
                                                 ,User__c
                                                 ,User__r.Id
                                                 ,User__r.Job_Name__c
                                             From Org_Unit_User_Links__r
                                            Where User__r.IsActive=true
                                              and User__r.Job_Name__c in (:UserHelper.JOB_DSA, :UserHelper.JOB_DSM)
                                            order by User__r.LastLoginDate desc)
                                     from Org_Unit__c
                                    Where Org_Type__c = :TYPE_DISTRICT
                                  ]) {
         if (evaluateDistrict(district)) {
            updateOrgUnits.add(district);
         }
      } // for (Org_Unit__c district
      
      if (!updateOrgUnits.isEmpty()) {
         update updateOrgUnits;
      }
   } // checkForDsmDsa
   
   public Boolean evaluateDistrict(Org_Unit__c district) {
      Boolean changed = checkExistingOverrides(district);
      User dsm = null;
      User dsa = null;
      if (district.Org_Unit_User_Links__r != null && !district.Org_Unit_User_Links__r.isEmpty()) {
         for (Org_Unit_User_Link__c ouul : district.Org_Unit_User_Links__r) {
            if (dsm == null && ouul.User__r.Job_Name__c == UserHelper.JOB_DSM) {
               dsm = ouul.User__r;
            } else if (dsa == null && ouul.User__r.Job_Name__c == UserHelper.JOB_DSA) {
               dsa = ouul.User__r;
            }
         } // for
      } // if (district.Org_Unit_User_Links__r
      
      if (!district.OverrideAssistant__c) {
         if (dsa == null && district.Assistant__c != null) {
            district.Assistant__c = null;
            nbrDsmUpdated++;
            changed = true;
         } else if (dsa != null && district.Assistant__c != dsa.Id) {
            district.Assistant__c = dsa.Id;
            nbrDsmUpdated++;
            changed = true;
         }
      } // if (!district.OverrideAssistant__c
      
      if (!district.OverrideMgr__c) {
         if (dsm == null && district.Manager__c != null) {
            district.Manager__c = null;
            nbrDsmUpdated++;
            changed = true;
         } else if (dsm != null && district.Manager__c != dsm.Id) {
            district.Manager__c = dsm.Id;
            nbrDsmUpdated++;
            changed = true;
         }
      } // if (!district.OverrideMgr__c
      
      return changed;
   } // evaluateDistrict
   
   public Boolean checkExistingOverrides(Org_Unit__c district) {
      Boolean changed = false;
      if (district.OverrideAssistant__c 
            && ((district.Assistant__c == null) || (district.Assistant__r != null && !district.Assistant__r.IsActive))
          ) {
         district.Assistant__c = null;
         district.Assistant__r = null;
         district.OverrideAssistant__c = false;
         changed = true;
      } // if (district.OverrideAssistant__c
      
      if (district.OverrideMgr__c 
            && ((district.Manager__c == null) || (district.Manager__r != null && !district.Manager__r.IsActive))
          ) {
         district.Manager__c = null;
         district.Manager__r = null;
         district.OverrideMgr__c = false;
         changed = true;
      } // if (district.OverrideAssistant__c
            
      return changed;
   } // checkExistingOverrides
    
   public void checkForUserLinkInserts(List<OrgUnitWrapper> ouWrappers) {
      List<Org_Unit_User_Link__c> linksToInsert = new List<Org_Unit_User_Link__c>();
      for (OrgUnitWrapper ouWrapper : ouWrappers) {
         if (!ouWrapper.linksToCreate.isEmpty() && ouWrapper.ou.Id != null) {
            for (Org_Unit_User_Link__c oul : ouWrapper.linksToCreate) {
                oul.Org_Unit__c = ouWrapper.ou.Id;
                linksToInsert.add(oul);
            } // for (Org_Unit_User_Link__c
         }
      } // for (OrgUnitWrapper
   
      if (!linksToInsert.isEmpty()) {
        nbrUserLinksCreated += linksToInsert.size();
         Database.SaveResult[] results = Database.insert(linksToInsert,false);
      }
   } // checkForUserLinkInserts
   
   /** See if any changes have been made that need saving.
    */
   public Map<String,OrgUnitWrapper> checkForSaves(Map<String,OrgUnitWrapper> orgUnitMap, Boolean isFirstPass) {
      // if records have a parent that doesn't already have an id, add them to this map so that the save can be tried again.
      Map<String,OrgUnitWrapper> orgUnitMapTryAgain = new Map<String,OrgUnitWrapper>();
      if (!orgUnitMap.isEmpty()) {
         // the records to insert
         Org_Unit__c[] orgUnitInserts = new Org_Unit__c[]{};
         // the records to update
         Org_Unit__c[] orgUnitUpdates = new Org_Unit__c[]{};
         
         for (String key : orgUnitMap.keySet()) {
            OrgUnitWrapper ouw = orgUnitMap.get(key);
            if (ouw.isChanged) {
               
               if (ouw.ou.Id == null) {
                  orgUnitInserts.add(ouw.getOu());
               } else {
                  orgUnitUpdates.add(ouw.getOu());
               }
               // if it has a parent and the parent doesn't have an id, add to this map to try again.
               // after the second pass this should no longer have records in it.
               if (ouw.parent != null && ouw.parent.ou.Id == null) {
                  orgUnitMapTryAgain.put(key,ouw);
               }
            }
         }
         
         //only log the activity on the first pass
         if (isFirstPass) {
            nbrOrgUnitsCreated += orgUnitInserts.size();
            nbrOrgUnitsUpdated += orgUnitUpdates.size();
         }
         SKIP_TRIGGERS=true;
         DmlHelper.performDML2(orgUnitInserts, DmlHelper.DML_INSERT, 'OrgUnitMethods', 'checkForSaves', 'Insert new Org Units', false);
         DmlHelper.performDML2(orgUnitUpdates, DmlHelper.DML_UPDATE, 'OrgUnitMethods', 'checkForSaves', 'Update Org Units', false);
         ErrorLog.checkSave();
         
      } // if (!orgUnitMap.isEmpty
      return orgUnitMapTryAgain;
   } // checkForSaves
   
   /** if the unused map still has records in it, we will end date them.
    */
   public Boolean checkForDeletes(Map<String,OrgUnitWrapper> orgUnitMap) {
      System.debug('checkForDeletes orgUnitMap='+orgUnitMap.size());
      Boolean okay = true;
      
      if (!linksToDelete.isEmpty()) {
         nbrUserLinksDeleted = linksToDelete.size();
         delete linksToDelete.values();
         linksToDelete.clear();
      }
      
      if (!orgUnitMap.isEmpty()) {
         
         // the org units we will be deleting. Everything in this map should already have an ID so we will not be checking that field.
         Org_Unit__c[] orgUnitUpdates = new Org_Unit__c[]{};
         for (String key : orgUnitMap.keySet()) {
            OrgUnitWrapper ouw = orgUnitMap.get(key);
            //System.debug('checkForDeletes ou='+ouw.key+' end Date='+ouw.ou.EndDate__c);
            if (ouw != null && ouw.ou.EndDate__c == null) {
               ouw.ou.EndDate__c = Date.today();
               orgUnitUpdates.add(ouw.ou);
            }
         }
         
         //System.debug('checkForDeletes orgUnitUpdates='+orgUnitUpdates.size());
         nbrOrgUnitsDeleted += orgUnitUpdates.size();
         if (!orgUnitUpdates.isEmpty()) {
            DmlHelper.performDML2(orgUnitUpdates, DmlHelper.DML_UPDATE, 'OrgUnitMethods', 'checkForDeletes', 'Set OrgUnit EndDate', true);
         }

      } // if (!orgUnitMap.isEmpty
      return okay;
   } // checkForDeletes
   
   public void checkOrgStrc(Organization_Structure__c orgStrc, Map<String,OrgUnitWrapper> orgUnitMapUsed, Map<String,OrgUnitWrapper> orgUnitMapUnused, boolean hasArea
                           ,Map<String,UserRole> byNameMap, Map<Id,UserRole[]> byParentIdMap, Map<Id,UserRole> byIdMap, OrgUnitRoleSetup__mdt[] roleSetups) {
      // get the sales office information. Verify the sales office number is a number. Do not proceed if not a number
      if (String.isNotBlank(orgStrc.Sales_Office_Number__c) && orgStrc.Sales_Office_Number__c.containsOnly(Utilities.ALL_NUMBERS)) {
         String costCenter = (String.isNotBlank(orgStrc.CostCenter__c) ? orgStrc.CostCenter__c : orgStrc.Sales_Office_Number__c);
         costCenter = (String.isNotBlank(costCenter) ? costCenter : '0');
         // make sure that cost center is 4 characters
         While (costCenter.length() < 4) {
            costCenter = '0'+costCenter;
         }
         OrgUnitWrapper salesOfficeOuw = findOuWrapper(orgStrc.Sales_Org__c,orgStrc.Sales_Office_Number__c,orgStrc.Sales_Office_name__c,TYPE_SALES_OFFICE,costCenter,orgUnitMapUsed,false,orgUnitMapUnused,null,null,null,null);

         // find a district
         OrgUnitWrapper districtOuw = findOuWrapper(orgStrc.Sales_Org__c,orgStrc.Name,orgStrc.District_Name__c,TYPE_DISTRICT,null,orgUnitMapUsed,true,orgUnitMapUnused
                                                      ,orgStrc.Role_District__c,orgStrc.RoleId_District__c,orgStrc.Role_Sales_Office__c,orgStrc.RoleId_Sales_Office__c);
         salesOfficeOuw.setParent(districtOuw);
         districtOuw.children.add(salesOfficeOuw);

         // find a zone
         OrgUnitWrapper zoneOuw = findOuWrapper(orgStrc.Sales_Org__c,orgStrc.Zone__c,orgStrc.Zone_Name__c,TYPE_ZONE,null,orgUnitMapUsed,true,orgUnitMapUnused,orgStrc.Role_Zone__c,orgStrc.RoleId_Zone__c,null,null);
         districtOuw.setParent(zoneOuw);
         zoneOuw.children.add(districtOuw);

         // if there's an area - find that
         String areaNbr = orgStrc.Area_Number__c;
         String areaName = orgStrc.Area__c;
         // if the structure doesn't have an area, create a default area to keep the structure consistent
         if (!hasArea) {
            areaNbr = '1';
            areaName = orgStrc.Sales_Org__c;
         }
         
         OrgUnitWrapper areaOuw = findOuWrapper(orgStrc.Sales_Org__c,areaNbr,areaName,TYPE_AREA,null,orgUnitMapUsed,true,orgUnitMapUnused,orgStrc.Role_Area__c,orgStrc.RoleId_Area__c,null,null);
         zoneOuw.setParent(areaOuw);
         areaOuw.children.add(zoneOuw);
         // get the division
         OrgUnitWrapper divisionOuw = findOuWrapper(orgStrc.Sales_Org__c,orgStrc.Sales_Org__c,orgStrc.Sales_Org__c,TYPE_DIVISION,null,orgUnitMapUsed,true,orgUnitMapUnused,null,null,null,null);
         if (areaOuw != null) {
            areaOuw.setParent(divisionOuw);
            divisionOuw.children.add(areaOuw);
         } else {
            // if no area in the structure
            zoneOuw.setParent(divisionOuw);
            divisionOuw.children.add(zoneOuw);
         }
         
         // do the check here - need the parent in some instances
         // only evaluate the role once per instance
         //if (!salesOfficeOuw.roleEvaluated) {
         //   checkForRole(salesOfficeOuw);
         //}
         System.debug('checkOrgStrc orgStrc='+orgStrc.Name+' districtOuw.roleEvaluated='+districtOuw.roleEvaluated+' orgUnitMapUsed='+orgUnitMapUsed.size()+' orgUnitMapUnused='+orgUnitMapUnused.size());
         if (!districtOuw.roleEvaluated) {
            //checkForRole(districtOuw);
            checkForRole(districtOuw, byNameMap, byParentIdMap, byIdMap, roleSetups);
         }
         //if (!zoneOuw.roleEvaluated && !zoneOuw.ou.DoNotEvaluateRoles__c) {
         if (!zoneOuw.roleEvaluated) {
            //checkForRole(zoneOuw);
            checkForRole(zoneOuw, byNameMap, byParentIdMap, byIdMap, roleSetups);
         }
         //if (areaOuw != null && !areaOuw.roleEvaluated && !areaOuw.ou.DoNotEvaluateRoles__c) {
         if (areaOuw != null && !areaOuw.roleEvaluated) {
            //checkForRole(areaOuw);
            checkForRole(areaOuw, byNameMap, byParentIdMap, byIdMap, roleSetups);
         }
         //if (divisionOuw != null && !divisionOuw.roleEvaluated && !divisionOuw.ou.DoNotEvaluateRoles__c) {
         if (divisionOuw != null && !divisionOuw.roleEvaluated) {
            //checkForRole(divisionOuw);
            checkForRole(divisionOuw, byNameMap, byParentIdMap, byIdMap, roleSetups);
         }
      } // if (String.isNotBlank
      
   } // checkOrgStrc
   
   public OrgUnitWrapper findOuWrapper(String salesOrg, String orgUnitNbr, String orgUnitName, String orgType, String costCenter,Map<String,OrgUnitWrapper> orgUnitMapUsed, Boolean checkUsedMap, Map<String,OrgUnitWrapper> orgUnitMapUnused
                                      ,String roleName, String roleId, String repRole, String repRoleId) {
      // build the key
      String key = salesOrg+orgType+orgUnitNbr;
      // look for existing org unit - each sales office should only be used once, so should only need to look in the unused map
      OrgUnitWrapper ouWrapper = orgUnitMapUnused.remove(key);
      System.debug('findOuWrapper key='+key+' ouWrapper='+(ouWrapper != null));
      // look in used map
      if (ouWrapper == null && checkUsedMap) {
         ouWrapper = orgUnitMapUsed.get(key);
         System.debug('findOuWrapper checkUsedMap key='+key+' ouWrapper='+(ouWrapper != null));
      }
      // if an existing one is found, see if the name is different to see if an update is needed.
      if (ouWrapper != null) {
         ouWrapper.setOrgUnitName(orgUnitName,costCenter);
      } else if (ouWrapper == null && String.isNotBlank(orgUnitNbr)) {
         System.debug('findOuWrapper createNew key='+key);
         // create the org unit if it doesn't exist
         ouWrapper = getNewOuWrapper(salesOrg,orgUnitNbr,orgUnitName,orgType,costCenter);
      } // if (ouWrapper == null
      ouWrapper.setRole(roleName, roleId, repRole, repRoleId);
      // put into the used map
      orgUnitMapUsed.put(key,ouWrapper);
      
      return ouWrapper;
   } // findOuWrapper
   
   public static final String ROLE_CORE=Label.OrgUnitMethods_Role_Core;
   public static final String ROLE_SALES_REP=' SALES REP ';
   
   public String checkSalesOrgName(String checkSalesOrg) {
      String retValue = checkSalesOrg;
      if (String.isNotBlank(checkSalesOrg)) {
         if (checkSalesOrg == UserHelper.SO_CORE) {
            retValue = ROLE_CORE;
         } else if (checkSalesOrg == UserHelper.SO_PEO_ASO) {
            retValue = UserHelper.SO_401;
         }
      }
      return retValue;
   } // checkSalesOrgName

   public void checkForRole(OrgUnitWrapper ouWrapper, Map<String,UserRole> byNameMap, Map<Id,UserRole[]> byParentIdMap, Map<Id,UserRole> byIdMap, OrgUnitRoleSetup__mdt[] roleSetups) {
      System.debug('checkForRole ou='+ouWrapper.ou.Name+' type='+ouWrapper.ou.Org_Type__c+' byNameMap='+byNameMap.size()+' byParentIdMap='+byParentIdMap.size()+' byIdMap='+byIdMap.size()+' roleSetups='+roleSetups.size());
      //if (ouWrapper.roleEvaluated) {
      //   return;
      //}
      checkForRole(ouWrapper, byNameMap, byIdMap, ouWrapper.ou.UserRoleName__c, ouWrapper.ou.UserRoleId__c, ouWrapper.ou.OverrideUserRoleName__c, false);
      if (ouWrapper.ou.Org_Type__c == TYPE_DISTRICT) {
         checkForRole(ouWrapper, byNameMap, byIdMap, ouWrapper.ou.RepUserRoleName__c, ouWrapper.ou.RepUserRoleId__c, ouWrapper.ou.OverrideRepUserRoleName__c, true);
      }
       
      // we need to set this to set the users
      if (String.isNotBlank(ouWrapper.ou.UserRoleId__c)) {
         UserRole role = byIdMap.get(ouWrapper.ou.UserRoleId__c);
         System.debug('checkForRole UserRoleId__c='+ouWrapper.ou.UserRoleId__c+' role='+(role != null));
         if (role != null) {
            ouWrapper.setRole(role);
         }
      }

      // look for the role. If this is a district, also check for the rep level
      if (String.isBlank(ouWrapper.ou.UserRoleName__c) || (ouWrapper.ou.Org_Type__c == TYPE_DISTRICT && String.isBlank(ouWrapper.ou.RepUserRoleName__c))) {
         findAndSetRole(ouWrapper, byNameMap, byParentIdMap, roleSetups);
      }
      // make sure we only evaluate each one once
      ouWrapper.roleEvaluated=true;
      evaluateUserLinks(ouWrapper);
   } // checkForRole
    
   // clear out the fields if not set properly
   public static void checkForRole(OrgUnitWrapper ouWrapper, Map<String,UserRole> byNameMap, Map<Id,UserRole> byIdMap, String roleName, String roleId, Boolean overrideRole, Boolean isRepFld) {
      UserRole foundRole=null;
      Boolean setRole=false;
      Boolean clearOverride=false;
      if (overrideRole && String.isNotBlank(roleName) && String.isBlank(roleId) ) {
         // verify the role name exists
         foundRole = byNameMap.get(roleName.toUpperCase());
         setRole = true;
         // if a role name cannot be found with the name, clear the field override and role fields. Let the code try again.
         clearOverride = (foundRole == null);
      } else if (overrideRole && String.isNotBlank(roleName) && String.isNotBlank(roleId)) {
         // do nothing if already set
      } else if (String.isBlank(roleName) && overrideRole) {
         // clear the override field
         setRole=true;
         clearOverride=true;
      } else if (!overrideRole && (String.isBlank(roleName) || String.isBlank(roleId))) {
         // if one of the fields is blank, clear to search again.
         setRole=true;
      } else if (roleId != null) {
          foundRole = byIdMap.get(roleId);
          setRole = true;
      }

      StringHelper.addToProcessNotes(ouWrapper.ou,'setRole='+setRole+' clearOverride='+clearOverride+' foundRole='+(foundRole != null));
      if (setRole) {
         if (isRepFld) {
            ouWrapper.setRepRole(foundRole);
            if (clearOverride) {
               ouWrapper.ou.OverrideRepUserRoleName__c = false;
            }
         } else {
            ouWrapper.setRole(foundRole);
            if (clearOverride) {
               ouWrapper.ou.OverrideUserRoleName__c = false;
            }
         }
           
      } // if (setRole
   } // checkForRole
    
   public static void findAndSetRole(OrgUnitWrapper ouWrapper, Map<String,UserRole> byNameMap, Map<Id,UserRole[]> byParentIdMap, OrgUnitRoleSetup__mdt[] roleSetups) {
      // look for the custom setting with the definition 
      String roleName = null;
      if (String.isBlank(ouWrapper.ou.UserRoleId__c)) {
         UserRole matchRole = null;
         for (OrgUnitRoleSetup__mdt roleSetup : roleSetups) {
            if (roleSetup.SalesOrg__c == ouWrapper.ou.Sales_Org__c && roleSetup.OrgType__c == ouWrapper.ou.Org_Type__c
                   && (roleSetup.OrgNbr__c == null || roleSetup.OrgNbr__c == ouWrapper.ou.Name)) {
               roleName = buildRoleName(roleSetup.RoleName__c, ouWrapper.ou);
               if (roleSetup.PartialMatch__c) {
                  matchRole = findRoleInMap(roleName, byNameMap);
               } else {
                  // if we find a matching role we can stop (even if there are multiple matching rules)
                  matchRole = (String.isNotBlank(roleName) ? byNameMap.get(roleName.toUpperCase()) : null);
               }
               System.debug('findAndSetRole rule='+roleSetup.MasterLabel+' roleName='+roleName+' roleFound='+(matchRole != null));
               StringHelper.addToProcessNotes(ouWrapper.ou,'rule='+roleSetup.MasterLabel+' roleName='+roleName+' roleFound='+(matchRole != null));
               if (matchRole != null) {
                  break;
               }
            } // if (ous.SalesOrg__c == ouWrapper.ou.Sales_Org__c
         } // for (OrgUnitSetup__c ous
         if (matchRole != null) {
            ouWrapper.setRole(matchRole);
         }
      } // if (String.isBlank(ouWrapper.ou.UserRoleId__c)
      // if this is a district, we're going to get the child role (should be only one) and use that for the Sales Rep - reduce some searching.
      if (ouWrapper.ou.Org_Type__c == TYPE_DISTRICT && String.isNotBlank(ouWrapper.ou.UserRoleId__c)) {
         UserRole[] childRoles = byParentIdMap.get((Id)ouWrapper.ou.UserRoleId__c);
         StringHelper.addToProcessNotes(ouWrapper.ou,'Found '+(childRoles != null ? childRoles.size() : -1)+' child roles for '+ouWrapper.ou.UserRoleId__c);
         if (childRoles != null && !childRoles.isEmpty()) {
            UserRole childRole = childRoles[0];
            StringHelper.addToProcessNotes(ouWrapper.ou,'Using '+childRole.Name+' for the Rep level');
            ouWrapper.setRepRole(childRole);
         }
      }
   } // findAndSetRole
    
   public static Boolean FIND_BY_QUERY=(Label.OrgUnitMethods_FindByQuery=='Y');
   // this is a very expensive search because we'd have to do a partial match on the keys. Is it better to perform queries?
   public static UserRole findRoleInMap(String roleName, Map<String,UserRole> byNameMap) {
      System.debug('findRoleInMap roleName='+roleName+' FIND_BY_QUERY='+FIND_BY_QUERY);
      if (String.isBlank(roleName)) {
         return null;
      }
          
      UserRole foundRole = null;
      if (FIND_BY_QUERY) {
         try {
            String searchString=roleName+'%';
            foundRole = [Select Id
                                ,Name
                                ,ParentRoleId
                                ,DeveloperName
                                ,(Select Id, Name
                                        ,FirstName
                                        ,Job_Name__c
                                        ,LastName
                                        ,Profile.Name
                                        ,UserRole.Name
                                    From Users
                                   Where IsActive=true)
                           from UserRole
                          Where Name like :searchString limit 1];
         } catch (Exception e) {
            System.debug('findRoleInMap exception='+e.getMessage());
         }
      } else {
         for (String key : byNameMap.keySet()) {
            String checkRoleName = roleName.toUpperCase();
            if (key.startsWith(checkRoleName)) {
                foundRole = byNameMap.get(key);
                break;
            } // if (key.startsWith(roleName
         } // for (String key : byNameMap.keySet
      }
      return foundRole;
   } // findRoleInMap
   
   // Keys available in the custom setting
   // <OrgName> the ou.Org_Unit_Name__c field
   public static String KEY_NAME='<OrgName>';
   // <R:ZONE/HNBF> replace the first value in the Org_Unit_Name__c with the second value ex ZONE EAST -> HNBF EAST
   public static String KEY_RPL='<R:';
   // <OrgNbr> the ou.Name field
   public static String KEY_NBR='<OrgNbr>';
   // <LastToken> tokenize Org_Unit_Name__c with spaces and use the last token 
   public static String KEY_LAST='<LastToken>';
   // <StripOrgName> Remove first and last tokens from org name - PEO Houston 615 use only Houston
   public static String KEY_STRIP='<StripOrgName>';
    
   public static String buildRoleName(String p_roleName, Org_Unit__c ou) {
      String roleName = p_roleName;
      System.debug('buildRoleName roleName='+roleName+' ou='+ou.Name+' Type='+ou.Org_Type__c+' Name='+ou.Org_Unit_Name__c);
      roleName = (roleName.contains(KEY_NAME) ? roleName.replaceAll(KEY_NAME, ou.Org_Unit_Name__c) : roleName);
      System.debug('buildRoleName after name roleName='+roleName);
      roleName = (roleName.contains(KEY_NBR) ? roleName.replaceAll(KEY_NBR, ou.Name) : roleName);
      System.debug('buildRoleName after nbr roleName='+roleName);
      if (roleName.contains(KEY_RPL)) {
          Integer startPos = roleName.indexOf(KEY_RPL);
          Integer endPos = roleName.indexOf('>', startPos);
          String subStr = roleName.substring(startPos+KEY_RPL.length(), endPos);
          // we will use this to replace what's in roleName
          String tokenReplace = KEY_RPL+subStr+'>';
          String[] tokens = subStr.split('/');
          System.debug('buildRoleName startPos='+startPos+' endPos='+endPos+' subStr='+subStr+' tokens='+tokens);
          // should be 2 tokens at this point. Use try/catch just in case
          try {
             String nameReplace = ou.Org_Unit_Name__c.replace(tokens[0],tokens[1]);
             roleName = roleName.replace(tokenReplace,nameReplace);
             //roleName = ou.Org_Unit_Name__c.replace(tokens[0],tokens[1]); 
          } catch (Exception e) {
             System.debug('buildRoleName e='+e);
          }
          System.debug('buildRoleName orgName='+ou.Org_Unit_Name__c+' roleName='+roleName);
      } // if (roleName.contains('<R:'
      if (roleName.contains(KEY_LAST)) {
         String[] tokens = ou.Org_Unit_Name__c.split(' ');
         String lastToken = tokens[tokens.size()-1];
         roleName = roleName.replace(KEY_LAST,lastToken);
         System.debug('buildRoleName '+KEY_LAST+' orgName='+ou.Org_Unit_Name__c+' lastToken='+lastToken+' roleName='+roleName);
      }
      if (roleName.contains(KEY_STRIP)) {
         String[] tokens = ou.Org_Unit_Name__c.split(' ');
         // remove the first and last tokens
         tokens.remove(0);
         tokens.remove(tokens.size()-1);
         String substr = String.join(tokens,' ');
         roleName = roleName.replace(KEY_STRIP,substr);
         System.debug('buildRoleName '+KEY_STRIP+' orgName='+ou.Org_Unit_Name__c+' substr='+substr+' roleName='+roleName);
      }
      System.debug('buildRoleName roleName='+roleName);
      return roleName;
   } // buildRoleName
    
   /** Check to see if we can find a matching role for the org unit. 
   
       Role Naming structure
       If Zone:
          <Sales Org> <Org Unit Name>
       If District:
          (HRS,PAS) HRS <District Name>
          (HNBF) HNBF DISTRICT - <District Name>
          (PAY) CORE DISTRICT - <District Name> 
          (MMS) MMS DISTRICT <District Name> <District Number>
       If Sales Office
          (HRS,PAS) HRS SALES REP - <District Name>
          (HNBF) HNBF SALES REP - <District Name>
          (PAY) CORE SALES REP - <District Name> 
          (MMS) MMS SALES REP <District Name>
   
    */ 
   /*
   public void checkForRole(OrgUnitWrapper ouWrapper) {
    String roleName = getRoleName(ouWrapper.ou, ouWrapper.ou.Org_Type__c);
    System.debug('checkForRole roleName='+roleName+' Org Type='+ouWrapper.ou.Org_Type__c);

    UserRole uRole = getRole(ouWrapper, roleName, ouWrapper.ou.Org_Type__c);
      ouWrapper.setRole(uRole);
      
      // if a district also get the sales office
      if (ouWrapper.ou.Org_Type__c == TYPE_DISTRICT) {
         roleName = getRoleName(ouWrapper.ou, TYPE_SALES_OFFICE);
         uRole = getRole(ouWrapper, roleName, TYPE_SALES_OFFICE);
         ouWrapper.setRepRole(uRole);
      }

      evaluateUserLinks(ouWrapper);

   } // checkForRole
   
   public UserRole getRole(OrgUnitWrapper ouWrapper, String roleName, String roleType) {
    UserRole uRole = null;
      if (String.isNotBlank(roleName)) {
         roleName = roleName.toUpperCase();
         uRole = userRoleMap.get(roleName);
         if (uRole == null && roleName.startsWith('CORE ')) {
            roleName = roleName.replace('CORE ', 'SMB ');
            uRole = userRoleMap.get(roleName);
         }
         if (uRole == null) {
            logFile += (ouWrapper.ou.Id != null ? (String)ouWrapper.ou.Id : '')+','+ouWrapper.ou.Org_Unit_Name__c+','+ouWrapper.ou.Name+','+ouWrapper.ou.Sales_Org__c+','+ouWrapper.ou.Org_Type__c+','+roleType+','+roleName+'\n';
            nbrRolesNotMatched++;
         } else {
            nbrRolesMatched++;
         }
         System.debug('getRole roleName='+roleName+' uRole='+uRole+' ou='+ouWrapper.ou);
      } // if (String.isNotBlank
      return uRole;
   } // getRole
   
   // Get the role name of the org unit passed in. 
   public String getRoleName(Org_Unit__c orgUnit, String roleType) {
      String roleName = null;
      System.debug('getRoleName orgUnit='+(orgUnit != null ? orgUnit.Name : 'noOrgUnit')+' roleType='+roleType);
      if (String.IsNotBlank(roleType) && orgUnit != null) {
        if (roleType == TYPE_SALES_OFFICE && orgUnit.OverrideRepUserRoleName__c && String.isNotBlank(orgUnit.RepUserRoleName__c)) {
           roleName = orgUnit.RepUserRoleName__c;
        } else if (roleType == TYPE_SALES_OFFICE) {
           orgUnit.OverrideRepUserRoleName__c = false;
        } else if (roleType != TYPE_SALES_OFFICE && orgUnit.OverrideUserRoleName__c && String.isNotBlank(orgUnit.UserRoleName__c)) {
           roleName = orgUnit.UserRoleName__c;
        } else {
           orgUnit.OverrideUserRoleName__c = false;
        }
        
        if (String.IsBlank(roleName)) {
            if (roleType == TYPE_AREA) {
               if (orgUnit.Sales_Org__c == UserHelper.SO_CORE) {
                  roleName = ROLE_CORE+' AVP - '+orgUnit.Org_Unit_Name__c;
               }
            } else if (roleType == TYPE_ZONE) {
                roleName = getZoneRoleName(orgUnit);
            } else if (roleType == TYPE_DISTRICT) {
                roleName = getDistrictRoleName(orgUnit);
            } else if (roleType == TYPE_SALES_OFFICE) {
               roleName = getSalesOfficeRoleName(orgUnit);
            } // if ouWrapper
         }
      } // if (orgUnit != null
      return roleName;
   } // getRoleName
   
   public String getZoneRoleName(Org_Unit__c orgUnit) {
      String roleName = null;
      if (orgUnit.Sales_Org__c == UserHelper.SO_401 || orgUnit.Sales_Org__c == UserHelper.SO_PEO_ASO) {
         // have to remove the dash from the name
         roleName = orgUnit.Org_Unit_Name__c.replace(' - ',' ');
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_CORE) {
         // CORE ZONE 1
         roleName = ROLE_CORE+' '+TYPE_ZONE+' '+orgUnit.Name;
      } else {
         // <Sales Org> <Org Unit Name>
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+' '+orgUnit.Org_Unit_Name__c;
      }
      return roleName;
   } // getZoneRoleName
   
   public String getDistrictRoleName(Org_Unit__c orgUnit) {
      String roleName = null;
      if (orgUnit.Sales_Org__c == UserHelper.SO_401 || orgUnit.Sales_Org__c == UserHelper.SO_PEO_ASO) {
         // (HRS,PAS) HRS <District Name>  - distrct name already in format of role name
         roleName = orgUnit.Org_Unit_Name__c.replace(' - ',' ');
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_HNB) {
         // (HNBF) HNBF DISTRICT - <District Name>
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+' '+TYPE_DISTRICT+' - '+orgUnit.Org_Unit_Name__c;
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_CORE) {
         // (PAY) CORE DISTRICT - <District Name>
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+' '+TYPE_DISTRICT+' - '+orgUnit.Org_Unit_Name__c;
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_MMS) {
         // (MMS) MMS DISTRICT <District Name>
         // Districts and Sales Orgs might be in the format MMS ENTERPRISE ROCHESTER - we need to remove the initial MMS if it's there.
         String districtName = orgUnit.Org_Unit_Name__c.replace('MMS ','');
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+' '+TYPE_DISTRICT+' '+districtName;
      }
      return roleName;
   } // getDistrictRoleName
   
   public String getSalesOfficeRoleName(Org_Unit__c orgUnit) {
      String roleName = null;
      if (orgUnit.Sales_Org__c == UserHelper.SO_401 || orgUnit.Sales_Org__c == UserHelper.SO_PEO_ASO) {
         // (HRS,PAS) HRS SALES REP - <District Name>
         roleName = orgUnit.Org_Unit_Name__c.replace(' - ',' ');
         roleName = roleName.replace('HRS ','HRS SALES REP - ');
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_HNB) {
         // (HNBF) HNBF SALES REP - <District Name>
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+ROLE_SALES_REP+'- '+orgUnit.Org_Unit_Name__c;
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_CORE) {
         // (PAY) CORE SALES REP - <District Name>
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+ROLE_SALES_REP+'- '+orgUnit.Org_Unit_Name__c;
      } else if (orgUnit.Sales_Org__c == UserHelper.SO_MMS) {
         // (MMS) MMS SALES REP <District Name>
         String districtName = orgUnit.Org_Unit_Name__c.replace('MMS ','');
         roleName = checkSalesOrgName(orgUnit.Sales_Org__c)+ROLE_SALES_REP+districtName;
      }

      return roleName;
   } // getSalesOfficeRoleName
   */
    
   // Evaluate the user links to see if we need to add/delete links based on the users attached to the role
   public void evaluateUserLinks(OrgUnitWrapper ouWrapper) {
    // Since there could be multiple roles, collect the users
    User[] users = new User[]{};
    System.debug('evaluateUserLinks ouWrapper role='+ouWrapper.role+' repRep='+ouWrapper.repRole);
    if (ouWrapper.role != null && ouWrapper.role.Users != null) {
       users.addAll(ouWrapper.role.Users);
    }
      if (ouWrapper.repRole != null && ouWrapper.repRole.Users != null) {
         users.addAll(ouWrapper.repRole.Users);
      }
    
    System.debug('evaluateUserLinks nbr users='+users.size()+' linksToDelete='+linksToDelete.size());
    // if no users, remove everyone
      if (users.isEmpty()) {
         // remove any user links
         if (ouWrapper.ou.Org_Unit_User_Links__r != null) {
            for (Org_Unit_User_Link__c ouul : ouWrapper.ou.Org_Unit_User_Links__r) {
               linksToDelete.put(ouul.Id,ouul);
            }
            //linksToDelete.addAll(ouWrapper.ou.Org_Unit_User_Links__r);
         }
      } else {
        // check the users in the roles against the users already attached to the org unit
        // get the map of existing links by user id.
        Map<Id,Org_Unit_User_Link__c> userLinkMap = getUserLinkMap(ouWrapper.ou.Org_Unit_User_Links__r);
        System.debug('evaluateUserLinks userLinkMap.size='+userLinkMap.size());
        // loop through the users in the role
        for (User usr : users) {
            Org_Unit_User_Link__c ouul = userLinkMap.remove(usr.Id);
            if (ouul != null) {
               // exists - don't need to do anything
               nbrUserLinksLeftAlone++;
            } else {
               // doesn't exist - create a new one
               ouWrapper.linksToCreate.add(new Org_Unit_User_Link__c(Name=usr.LastName+', '+usr.FirstName, User__c=usr.Id));
            }
        } // for (User usr
        
        // if anything is left in the map, those weren't used. They will be deleted.
        if (!userLinkMap.isEmpty()) {
            System.debug('evaluateUserLinks adding '+userLinkMap.size()+' links to linksToDelete');
            for (Org_Unit_User_Link__c ouul : userLinkMap.values()) {
               linksToDelete.put(ouul.Id,ouul);
            }
           //linksToDelete.addAll(userLinkMap.values());
        }
      } // if (ouWrapper.role
   } // evaluateUserLinks
   
   /** Get a map of the user links.
    */
   public Map<Id,Org_Unit_User_Link__c> getUserLinkMap(List<Org_Unit_User_Link__c> userLinkList) {
      Map<Id,Org_Unit_User_Link__c> userLinkMap = new Map<Id,Org_Unit_User_Link__c>();
      if (userLinkList != null) {
         for (Org_Unit_User_Link__c ouul : userLinkList) {
            // if a link exists more than once, delete any other that occurs - duplicate checking
            if (userLinkMap.containsKey(ouul.User__c)) {
               linksToDelete.put(ouul.Id,ouul);
            } else {
               userLinkMap.put(ouul.User__c, ouul);
            }
         }
      } // if (userLinkList != null
      return userLinkMap;
   } // getUserLinkMap
   
   public OrgUnitWrapper getNewOuWrapper(String salesOrg, String orgUnitNbr, String orgUnitName, String orgType, String costCenter) {
      Org_Unit__c ou = new Org_Unit__c(Name=orgUnitNbr, Org_Unit_Name__c=orgUnitName, Org_Type__c=orgType, Cost_Center__c=costCenter, Sales_Org__c=salesOrg, StartDate__c=Date.today()); 
      System.debug('getNewOuWrapper ou='+ou);
      OrgUnitWrapper ouw = new OrgUnitWrapper(ou);
      return ouw;
   } // getNewOuWrapper
   
   /** Get the existing org units.
    */
   public void getOrgUnitMap(Map<String,OrgUnitWrapper> orgUnitWrapperMap, Map<String,Org_Unit__c> orgUnitMap
                                                  ,List<String> salesOrgList, Set<String> keySet ) {

      String query = ORG_UNIT_SELECT + ' Where (Sales_Org__c in :salesOrgList '+
                                         'and Org_Type__c in :ORG_TYPE_LIST) '+
                                         ' or (Query_Key__c in :keySet) ';

      for (Org_Unit__c[] orgUnits : Database.query(query)) {
         for (Org_Unit__c orgUnit : orgUnits) {
            if (orgUnitWrapperMap != null) {
               OrgUnitWrapper ouw = new OrgUnitWrapper(orgUnit);
               System.debug('getOrgUnitMap adding to map key='+ouw.key);
               orgUnitWrapperMap.put(ouw.key,ouw);
            }
            if (orgUnitMap != null) {
               orgUnitMap.put(orgUnit.Query_Key__c,orgUnit);
            }
         }
      } // for (Org_Unit__c[] orgUnits
      
   } // getOrgUnitMap
   
   /** The only job we'll be linking to Org Units at this time. */
   public static Set<String> JOB_SET = new Set<String>{
          UserHelper.JOB_REP
         ,UserHelper.JOB_DSA
         ,UserHelper.JOB_DSM};
         
   public Integer nbrUsersProcessed = 0;
   
   
   /** class to encapsulate Org Unit information. 
    */
   public class OrgUnitWrapper {
      public OrgUnitWrapper(Org_Unit__c p_ou) {
         ou = p_ou;
         key=ou.Sales_Org__c+ou.Org_Type__c+ou.Name;
         // default the changed flag depending if it's new or not.
         isChanged = (ou.Id == null);
      } // OrgUnitWrapper
      
      /** Is this changed?
          Considered changed if:
             ou.Id == null
             ou.Id != null &&
                ((orgUnitName is not null and orgUnitName != ou.Org_Unit_Name__c)
                 or (ou.Parent__c != null and parent == null)
                 or (ou.Parent__c == null and parent != null)
                 or (ou.Parent__c != null and parent != null and ou.Parent__c != parent.Id)
                )
       */
      public Boolean isChanged = false;
      
      public Org_Unit__c ou = null;
      
      public Org_Unit__c getOu() {
         // check the parent if the record is marked as changed
         if (parentChanged) {
            // reset the parentChanged flag if condition is met so record isn't reretrieved.
            if (parent == null) {
               ou.Parent__c = null;
               parentChanged = false;
            }
            if (parent != null && parent.ou.Id == null) {
               // do nothing here. parent has to be saved first
            }
            if (parent != null && parent.ou.Id != null) {
               ou.Parent__c = parent.ou.Id;
               parentChanged = false;
            }
         } // if (parentChanged
         
         return ou;
      } // getOu

      // Get the passed in value for the org unit name. Marked the changed flag if it's different.
      public void setOrgUnitName(String p_orgUnitName, String p_costCenter) {
         if (isChanged || ((ou.Org_Unit_Name__c == null) 
                          || (ou.Org_Unit_Name__c != null && ou.Org_Unit_Name__c != p_orgUnitName))) {
            isChanged = true;
            ou.Org_Unit_Name__c = p_orgUnitName;
         }
         if (String.isNotBlank(p_costCenter) && p_costCenter != ou.Cost_Center__c) {
            isChanged = true;
            ou.Cost_Center__c = p_costCenter;
         } 
         // remove the end date if we're using it
         if (ou.EndDate__c != null) {
            isChanged = true;
            ou.EndDate__c = null;
         }
      } // setOrgUnitName

      public Boolean parentChanged = false;
      // Set the parent. If it's different than what's already there mark the changed flag.
      public void setParent(OrgUnitWrapper ouwParent) {
         parent = ouwParent;
         parentChanged = ((ou.Parent__c == null && parent != null)
                           || (ou.Parent__c != null && parent == null)
                           || (ou.Parent__c != null && parent != null && ou.Parent__c != parent.ou.Id)
                           );
         isChanged = (isChanged || parentChanged);
      } // setParent
            
      /** The parent of this org unit. Each should only have one parent. */
      public OrgUnitWrapper parent = null;
      
      /** The children of this record. */
      public List<OrgUnitWrapper> children = new List<OrgUnitWrapper>();
      
      /** A unique key for this org unit. */
      public String key;
      
      /** We only want to evaluate the role once for an org unit. */
      public Boolean roleEvaluated = false;

      public UserRole role = null;
       
      // if we're pushing the value in from the organization structure record
      public void setRole(String roleName, String roleId, String repRole, String repRoleId) {
          
          //ou.DoNotEvaluateRoles__c = false; //String.isNotBlank(roleId);
          if (String.isNotBlank(roleName) && roleId != null && (roleName != ou.UserRoleName__c || roleId != ou.UserRoleId__c) ) {
              ou.UserRoleName__c = roleName;
              ou.UserRoleId__c = roleId;
              ou.OverrideUserRoleName__c = true;
              isChanged = true;
              // we still need to do this to get the users
              roleEvaluated=false;
          }
          if (String.isNotBlank(repRole) && repRoleId != null && (repRole != ou.RepUserRoleName__c || repRoleId != ou.RepUserRoleId__c)) {
              ou.RepUserRoleName__c = repRole;
              ou.RepUserRoleId__c = repRoleId;
              ou.OverrideRepUserRoleName__c = true;
              isChanged = true;
              // we still need to do this to get the users
              roleEvaluated=false;
          }
      } // setRole
      
      public void setRole(UserRole p_role) {
        roleEvaluated = true;
        role = p_role;
         if (role == null && (ou.UserRoleId__c != null || ou.UserRoleName__c != null)) {
            ou.UserRoleId__c = null;
            ou.UserRoleName__c = null;
            isChanged = true;
         } else if (role != null && (ou.UserRoleId__c != role.Id)) {
            ou.UserRoleId__c = role.Id;
            ou.UserRoleName__c = role.Name;
            isChanged = true;
         } // if (role == null
      } // setRole
      
      public UserRole repRole = null;
      
      public void setRepRole(UserRole p_role) {
        repRole = p_role;
         if (repRole == null && (ou.RepUserRoleId__c != null || ou.RepUserRoleName__c != null)) {
            ou.RepUserRoleId__c = null;
            ou.RepUserRoleName__c = null;
            isChanged = true;
         } else if (repRole != null && (ou.RepUserRoleId__c != repRole.Id)) {
            ou.RepUserRoleId__c = repRole.Id;
            ou.RepUserRoleName__c = repRole.Name;
            isChanged = true;
         } // if (role == null
      } // setRepRole
      
      /** Does this have a role set? */
      public Boolean hasRole() {
         return (String.isNotBlank(ou.UserRoleId__c));
      } // hasRole
      
      // if we have to create new user links - so they can be linked to the org unit once it's created
      public List<Org_Unit_User_Link__c> linksToCreate = new List<Org_Unit_User_Link__c>();
      
   } // class OrgUnitWrapper
   
   // map of org units by role name. We're going to assume role names are unique so we don't need to account for multiple
   // org units having the same role name(s)
   private static Map<String, Org_Unit__c> orgUnitByRoleNameMap = new Map<String, Org_Unit__c>(); 
   
   // check if the role names are populated with a role id. 
   public static void checkRoleNames(Org_Unit__c orgUnit, Org_Unit__c oldOrgUnit) {
      if (oldOrgUnit != null && orgUnit.UserRoleName__c != oldOrgUnit.UserRoleName__c) {
         orgUnit.UserRoleId__c = null;
      }
      if (oldOrgUnit != null && orgUnit.RepUserRoleName__c != oldOrgUnit.RepUserRoleName__c) {
         orgUnit.RepUserRoleId__c = null;
      }
      if (String.isNotBlank(orgUnit.UserRoleName__c) && String.isBlank(orgUnit.UserRoleId__c)) {
         orgUnitByRoleNameMap.put(orgUnit.UserRoleName__c, orgUnit);
      }
      
      if (String.isNotBlank(orgUnit.RepUserRoleName__c) && String.isBlank(orgUnit.RepUserRoleId__c)) {
         orgUnitByRoleNameMap.put(orgUnit.RepUserRoleName__c, orgUnit);
      }
       
      if (String.isNotBlank(orgUnit.UserRoleId__c) && orgUnit.UserRoleId__c.length() != 18) {
         orgUnit.UserRoleId__c = checkId(orgUnit.UserRoleId__c);
      } // if (String.isNotBlank(orgUnit.UserRoleId__c)
      if (String.isNotBlank(orgUnit.RepUserRoleId__c) && orgUnit.RepUserRoleId__c.length() != 18) {
         orgUnit.RepUserRoleId__c = checkId(orgUnit.RepUserRoleId__c);
      } // if (String.isNotBlank(orgUnit.UserRoleId__c)
     
   } // checkRoleNames
    
   // check if the passed in value is an ID field
   public static String checkId(String valToCheck) {
      
      String retVal = ((String.isNotBlank(valToCheck) && valToCheck.length() == 18) ? valToCheck : null);
      if (retVal == null && String.isNotBlank(valToCheck)) {
         try {
            Id testId = Id.valueOf(valToCheck);
            retVal = testId;
            System.debug('checkRoleNames testId='+testId);
         } catch (Exception e) {
            System.debug('checkRoleNames error validating valToCheck: '+valToCheck);
            retVal = null;
         }

      } // if (retVal == null && String.isNotBlank(valToChec
      System.debug('checkId valToCheck='+valToCheck+' retVal='+retVal);
      return retVal;
   } // checkId
   
   // if there are role names in the map, search for them and populate the role ids on the org unit record
   public static void processRoleNames() {
      if (!orgUnitByRoleNameMap.isEmpty()) {
         UserRole[] roles = [Select Id, Name from UserRole where Name in :orgUnitByRoleNameMap.keySet()];
         for (UserRole role : roles) {
            Org_Unit__c orgUnit = orgUnitByRoleNameMap.get(role.Name);
            if (orgUnit != null) {
               if (orgUnit.UserRoleName__c == role.Name) {
                  orgUnit.UserRoleId__c = role.Id;
               } else if (orgUnit.RepUserRoleName__c == role.Name) {
                  orgUnit.RepUserRoleId__c = role.Id;
               }
            } // if (orgUnit != null
         } // for (UserRole role
        orgUnitByRoleNameMap.clear();
      } // if (!orgUnitByRoleNameMap
   } // processRoleNames
   
   // we will check the user records associated by the user role id to make sure the DSA is set appropriately
   private static Set<Id> orgUnitsToCheckUserIdSet = new Set<Id>();
   
   public static void checkForUserUpdate(Org_Unit__c orgUnit, Org_Unit__c oldOrgUnit, Boolean isBefore) {
      if (isBefore && orgUnit.Id != null && (orgUnit.CheckAssistantOnReps__c || (orgUnit.Assistant__c != null && orgunit.Assistant__c != oldOrgUnit.Assistant__c))) {
        // the flag is set
         orgUnitsToCheckUserIdSet.add(orgUnit.Id);
         orgUnit.CheckAssistantOnReps__c = false;
      } else if (isBefore && oldOrgUnit != null && orgUnit.Org_Unit_Name__c != oldOrgUnit.Org_Unit_Name__c) {
        // the name changes
         orgUnitsToCheckUserIdSet.add(orgUnit.Id);
      } else if (!isBefore) {
         if (orgUnit.Assistant__c != null && orgUnit.RepUserRoleId__c != null &&
                (oldOrgUnit == null || (oldOrgUnit != null && orgUnit.Assistant__c != oldOrgUnit.Assistant__c))) {
            orgUnitsToCheckUserIdSet.add(orgUnit.Id);
         }
      } // if (isBefore &&
      
   } // checkForUserUpdate
   
   // check to see if we need to process the check for assistants
   public static void checkToProcessOrgUnitUserUpdate(String sessionId) {
      if (!orgUnitsToCheckUserIdSet.isEmpty()) {
         if (System.isFuture() || System.isBatch() || Test.isRunningTest()) {
            processUserCallout(sessionId, orgUnitsToCheckUserIdSet);
         } else {
            processUserCalloutFuture(sessionId, orgUnitsToCheckUserIdSet);
         }
         orgUnitsToCheckUserIdSet.clear();
      }
   } // checkToProcessOrgUnitUserUpdate
   
   @future(callout=true)
   public static void processUserCalloutFuture(String sessionId, Set<Id> orgUnitIdSet) {
      processUserCallout(sessionId, orgUnitIdSet);
   } // processUserCalloutFuture
   
   public static void processUserCallout(String sessionId, Set<Id> orgUnitIdSet) {
    Id[] orgUnitIds = new Id[]{};
    orgUnitIds.addAll(orgUnitIdSet);
      HttpRequest req = new HttpRequest();
      Boolean okay = true;
      req.setEndpoint('https://'+URL.getOrgDomainUrl().getHost()+'/services/apexrest/UserUpdateFromOrgUnit/');
      req.setMethod('POST');
      String body = '{"orgUnitIds":'+JSON.serialize(orgUnitIds)+'}';
      req.setBody(body);
      req.setHeader('Authorization', 'Bearer '+ sessionId);
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(50000);
      Http http = new Http();
      if (!Test.isRunningTest()){
         System.debug('processUserCallout performing rest callout');
         try {
            HTTPResponse res = http.send(req);
            System.debug('processUserCallout res='+res+' body='+res.getBody());
            
         } catch (Exception ex) {
            okay = false;
            ErrorLog.logError('OrgUnitMethods', 'processUserCallout', 'Sending message', orgUnitIds[0], ex);
         }
      } else {
         System.debug('processUserCallout calling roleChanged directly');
         UserUpdateFromOrgUnitREST.doPost(orgUnitIds);
      }
   } // processUserCallout
   
} // class OrgUnitMethods