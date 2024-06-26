/* Form to allow users to submit changes for zip codes
 
   DistrictsManaged__c - don't use
   ManageZipDefOrgUnit__c - don't use
   ManageZipOrgUnitsManaged__c - these should all be at the same level within the same sales org (all PAY Districts, all HRS Zones)
   SalesOrgsManaged__c - don't use
   
   If System admin, select all division level sales orgs
   If managing orgs other than one you are directly connected to, the query keys will be listed in ManageZipOrgUnitsManaged__c
  
  TODO:
  Zips Managed
  Add message if more than maximum selected
  Allow for filter criteria - zip range, sales office number, rep name

  History
  -------
  01/30/2013 Dan Carmen   Created
  06/01/2013 Dan Carmen   Small changes for creating the file.
  06/10/2013 Dan Carmen   Change how determining level of the user - use the Job Name
  03/09/2015 Cindy Freeman  Modified to be able to set Assistant and Manager overrides on the Territory, 
                            used for Virtual Sales to cover open territories
  03/14/2015 Dan Carmen   Allow for the upload of zip code files to manage zip codes
  05/02/2016 Cindy Freeman  Modified for new Core segments so can Clone segment or delete Segment with zip assignments
  09/28/2016 Dan Carmen   Added some cleanup to the code - getting rid of unneeded fields
  03/29/2017 Cindy Freeman  added option to select which segment you are cloning to  
  06/14/2017 Cindy Freeman    changed to public without sharing so deletion of territory doesnt fail on Zip Assignments owned by someone higher
  07/21/2017 Jacob Hinds      added state filter
  05/11/2017 Jacob Hinds      Adding MMS-ASO Partner
  06/18/2019 Jacob Hinds      Adding Read-Only Access
  05/29/2020 Dan Carmen       Added ability for ALLACCESS
  05/18/2021 Jermaine Stukes  Adding SaveHRServicePartner
  07/15/2023 Pratik Das       APR0151864: SMB Channel Evolution BAU--District__r.Queue_Name__c added to the query
  09/05/2023 Dan Carmen       Changed call to launch the ZipInsertBatch
  11/30/2023 Dan Carmen       Removed unused fields on Zip Assignment/Zip Territory

 */
public without sharing class ManageZipAssignController {

   public Boolean searchPerformed{get;set;}

   public User runningUser{get;set;}
   
   /** Is the running user a system admin? */
   public Boolean isSystemAdmin{get;private set;}
   
   /** Is this user valid for this form? */
   public Boolean isValidUser{get;private set;}
   
   /** Is this a user at a district level (DSA/DSM/FSS)? */   
   public Boolean isDistrictUser{get;private set;}
   /** Is this a user at a zone level (ZSM/ZSA)? */
   public Boolean isZoneUser{get;private set;}
   /** Is this a user at an area level? */
   public Boolean isAreaUser{get;private set;}
   /** Is this a corporate user? So they can see everything? */
   public Boolean isCorporateUser{get;private set;}
   
   private String[] availableSalesOrgs = null;
   
   // the reason a user wouldn't have access to the form.
   public String noAccessReason{get;private set;}
   
   /** The Org Unit attached to the running user (if any). */
   //private Org_Unit__c userOrgUnit=null;
   
   public ManageZipAssignController() {
      runningUser = UserHelper.getRunningUser();

      isDistrictUser = false;
      isZoneUser = false;
      isAreaUser = false;
      isCorporateUser = false;
      managingDistrict = false;
      editTerritoryFrom = false;
      useFilter = false;
      useClone = false;
      
      // is the running user a system admin?
      isSystemAdmin = Utilities.checkSysAdminProf(runningUser.Profile.Name);
      
      setAvailableOrgUnits(runningUser);
      
      // is this user valid for this form? Make sure they're part of the sales org
      isValidUser = !availableSalesOrgs.isEmpty();
      if (!isValidUser) {
         noAccessReason = 'You do not have access to any Districts!';
      }

      // if not system admin, find what level they're on.
      if (isValidUser && !isSystemAdmin) {

      } // if (isValidUser && !isSystemAdmin

      // if we can't define what level they are we cannot proceed.
      if (isValidUser) {
         setup();
      }
   } // ManageZipAssignController

   // for testing purposes, if you want to force the code to ignore the check for the district user, set this to true.
   public static Boolean FORCE_IGNORE_DISTRICT_USER = false;

   // can the running user manage the territory?
   public Boolean canUserManageTerritory{
      get {
        Boolean checkDistrictUser = (FORCE_IGNORE_DISTRICT_USER || isDistrictUser);
        Boolean canManage = (selectedTerritoryFromObject != null 
                              && (!checkDistrictUser || (checkDistrictUser && !selectedTerritoryFromObject.District_Lockout__c)));
         return canManage;
      }
   } // canUserManageTerritory
   
   public Boolean hasEditAccess{
      get{
        Boolean editAccess = false;
        Boolean hasManageZipPermission = FeatureManagement.checkPermission('Manage_Zip_Assignment');
        SalesOrg__c so = SalesOrg__c.getValues(runningUser.Sales_Org__c);
        Profile_List__c pl = Profile_List__c.getValues(runningUser.Profile.Name);
        if(isSystemAdmin || (so!=null && !so.Manage_Zip_Read_Only__c) || (pl!=null && pl.Manage_Zip_Edit_Access__c) || hasManageZipPermission){
            editAccess = true;
        }
        return editAccess;
      }
   }
   
   /** all of the org units the user has direct access to - through the org unit links */
   private Map<String,List<Org_Unit__c>> availableOrgUnitMap = new Map<String,List<Org_Unit__c>>();
   
   public void setAvailableOrgUnits(User usr) {
    availableOrgUnitMap.clear();
      // collect all available org units
      Org_Unit__c[] userOrgUnits = OrgUnitMethods.getUserOrgUnits(usr);

      Set<Id> checkIds = new Set<Id>();
      // add it to the map
      if (userOrgUnits != null && !userOrgUnits.isEmpty()) {
        for (Org_Unit__c ou : userOrgUnits) {
           checkIds.add(ou.Id);
           List<Org_Unit__c> orgUnitList = availableOrgUnitMap.get(ou.Sales_Org__c);
           if (orgUnitList == null) {
              orgUnitList = new List<Org_Unit__c>();
              availableOrgUnitMap.put(ou.Sales_Org__c,orgUnitList);
           }
           orgUnitList.add(ou);
        } // for (Org_Unit__c ou
        
      } // if (userOrgUnits != null
      
      String[] orgUnitQueryKeys = new String[]{};
      if (String.isNotBlank(usr.ManageZipOrgUnitsManaged__c)) {
         orgUnitQueryKeys.addAll(usr.ManageZipOrgUnitsManaged__c.split(','));
      }
      isSystemAdmin = (isSystemAdmin || usr.ManageZipOrgUnitsManaged__c=='ALLACCESS');
      if (isSystemAdmin) {
         // add query keys for all division levels
         for (String salesOrg : UserHelper.getDivisionStructureSet()) {
            String queryKey = salesOrg+OrgUnitMethods.TYPE_DIVISION+salesOrg;
            orgUnitQueryKeys.add(queryKey);
         }
      } // if (isSystemAdmin)
      System.debug('setAvailableOrgUnits orgUnitQueryKeys='+orgUnitQueryKeys);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAvailableOrgUnits orgUnitQueryKeys='+orgUnitQueryKeys));
      
      Org_Unit__c[] orgUnits = OrgUnitMethods.getOrgUnits(null, null, null, null, orgUnitQueryKeys);
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setAvailableOrgUnits nbr orgUnits='+orgUnits.size()));
      System.debug('setAvailableOrgUnits orgUnits='+orgUnits.size());
      for (Org_Unit__c orgUnit : orgUnits) {
         System.debug('setAvailableOrgUnits orgUnit='+orgUnit); 
        // don't add the user org unit a second time
         if (!checkIds.contains(orgUnit.Id)) {
            List<Org_Unit__c> orgUnitList = availableOrgUnitMap.get(orgUnit.Sales_Org__c);
            if (orgUnitList == null) {
               orgUnitList = new List<Org_Unit__c>();
               availableOrgUnitMap.put(orgUnit.Sales_Org__c, orgUnitList);
            }
            orgUnitList.add(orgUnit);
         } // if (orgUnit.Id
      } // for (Org_Unit__c orgUnit
      
      availableSalesOrgs = new String[]{};
      
      // only keep the org units that are at the highest level (don't keep districts if there's a zone for the same sales org)
      for (String salesOrg : availableOrgUnitMap.keySet()) {
         checkForHighestLevel(availableOrgUnitMap.get(salesOrg));
         availableSalesOrgs.add(salesOrg);
      }
      availableSalesOrgs.sort();
   } // setAvailableOrgUnits
   
   /** Only keep the org units with the highest levels. This is in case mixed records are added. To keep the form clean.
    */
   public void checkForHighestLevel(List<Org_Unit__c> orgUnitList) {
    // don't need to do anything if only one record
      if (orgUnitList.size() > 1) {
        // add everything into a map
         Map<String,List<Org_Unit__c>> typeListMap = new Map<String,List<Org_Unit__c>>();
         for (Org_Unit__c orgUnit : orgUnitList) {
            List<Org_Unit__c> typeList = typeListMap.get(orgUnit.Org_Type__c);
            if (typeList == null) {
               typeList = new List<Org_Unit__c>();
               typeListMap.put(orgUnit.Org_Type__c, typeList);
            }
            typeList.add(orgUnit);
         } // for (Org_Unit__c orgUnit
         
         // go down the type list, stopping when you find a record
         orgUnitList.clear();
         for (String orgType : OrgUnitMethods.ORG_TYPE_LIST) {
            if (typeListMap.containsKey(orgType)) {
               orgUnitList.addAll(typeListMap.get(orgType));
               break;
            }
         } // for
      } // if (orgUnitList.size() > 1
   } // checkForHighestLevel
   

   /** Based on the org unit the user is attached to, set what level they're at in the form.
    */
   public Boolean checkUserLevelOnOrgUnit(Org_Unit__c orgUnit) {
    isDistrictUser = false;
    isZoneUser = false;
    isAreaUser = false;
    isCorporateUser = false;
    
      if (orgUnit != null) {
         if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DISTRICT) {
            isDistrictUser = true;
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_ZONE) {
            isZoneUser = true;
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_AREA) {
            isAreaUser = true;
         } else if (orgUnit.Org_Type__c == OrgUnitMethods.TYPE_DIVISION) {
            isCorporateUser = true;
         }
      } // if (orgUnit != null
      return (isDistrictUser || isZoneUser || isAreaUser || isCorporateUser);
   } // checkUserLevelOnOrgUnit
   
   /** If user has access to a single district, the name of the district is set here. */
   public String districtName{
      get {return (selectedDistrictOrgUnit != null ? selectedDistrictOrgUnit.Name+'-'+selectedDistrictOrgUnit.Org_Unit_Name__c : 'No District Found'); }
   }

   public Zip_Assignment__c searchZa{get;set;}

   public Zip_Assignment__c reassignZa{get;set;}
   
   /** Used to request a new zip code */
   public Zip_Assignment__c newZa{get;set;}

   //public ZipAssignmentRequest__c queryZar{get;set;}
   
   /** Any setup tasks to be performed.
    */
   public void setup() {
      askForNewUser = false;
      addingZipCode = false;
      showZipAssignments = false;
      //selectedAvailableUser = null;
      searchZa = new Zip_Assignment__c();
      reassignZa = new Zip_Assignment__c();
      //queryZar = new ZipAssignmentRequest__c();
      
      if (isSystemAdmin) {
         isCorporateUser = true;
      }
      setSalesOrgPicklist();
      setSegments(searchZa.Sales_Org__c);
      setSalesOrg();
      
      // default the searchPerformed flag to false
      searchPerformed = false;
         
   } // setup;

   public void setSalesOrg() {
    isDistrictUser = false;
    isZoneUser = false;
    isAreaUser = false;
    isCorporateUser = false;
    resetFilter();
    if (availableOrgUnitMap != null && searchZa != null && String.isNotBlank(searchZa.Sales_Org__c)) {
       List<Org_Unit__c> orgUnitList = availableOrgUnitMap.get(searchZa.Sales_Org__c);
       if (orgUnitList != null) {
          // use the first in the list for the user
          selectedUserOrgUnit = orgUnitList[0];
          checkUserLevelOnOrgUnit(selectedUserOrgUnit);

            if (isDistrictUser) {
                selectedDistrictId = selectedUserOrgUnit.id;
                districtOptions = getOrgUnitOptions(null, null, districtOrgUnitMap, orgUnitList);
               setDistrict();
               
            } else if (isZoneUser) {
               selectedZoneId = selectedUserOrgUnit.Id;
               zoneOptions = getOrgUnitOptions(null, null, zoneOrgUnitMap, orgUnitList);
               setZone();
            } else if (isAreaUser || isCorporateUser) {
               zoneOptions = getOrgUnitOptions(orgUnitList, OrgUnitMethods.TYPE_ZONE, zoneOrgUnitMap, null);
               selectedZoneId = zoneOptions[0].getValue();
               setZone();
            }

       } // if (orgUnitList != null
       
    } // if (availableOrgUnitMap != null

   } // setSalesOrg
   
   /** Options for the zip code segment. */
   public List<SelectOption> segmentOptions{get;set;}
   
   public String selectedSegmentId{get;set;}
   public String selectedSegmentName{get;private set;}
   public Boolean selectedSegmentDeleteZips{get; private set;}
   // list of zip segments based on selected sales org
   public Map<Id, Zip_Segment__c> zipSegmentMap{get; private set;}
      
   /** Does this have more than 1 segment option? */
   public Boolean hasMultipleSegmentOptions{
      get {return (segmentOptions != null && segmentOptions.size() > 1); }
   } // hasMultipleSegmentOptions
      
   /** Get all of the segments for the sales org. 
    */
   public Boolean setSegments(String salesOrg) {
      selectedSegmentId = null;
      
      String[] salesOrgs = new String[]{salesOrg};
      if (salesOrg == UserHelper.SO_401) {
        // to return the wholesaler segments
         salesOrgs.add(UserHelper.SO_WHOLESALER);
      }      
      // look for the existing segment records
      Zip_Segment__c[] segments = ZipQueries.getSegments(salesOrgs);
      System.debug('setSegments Number of Segments selected for '+salesOrg+'='+segments.size());
      segmentOptions = new List<SelectOption>();
      zipSegmentMap = new Map<Id, Zip_Segment__c>();
      for (Zip_Segment__c segment : segments) {
         zipSegmentMap.put(segment.Id, segment);
         String segmentName = (String.isNotBlank(segment.DisplayName__c) ? segment.DisplayName__c : segment.Name);
         segmentOptions.add(new SelectOption(segment.Id,segmentName));
         // set the selected value to the first segment selected
         if (selectedSegmentId == null) {
            selectedSegmentName = segmentName;
            selectedSegmentId = segment.Id;
            selectedSegmentDeleteZips = segment.Delete_ZipAssignments__c;
         }
      } // for (Zip_Segment__c segment
      
      return (!segmentOptions.isEmpty());
   } // setSegments

   /** When a new segment is selected. */
   public void setSegment() {
    for (SelectOption selOption : segmentOptions) {
       if (selOption.getValue() == selectedSegmentId) {
          selectedSegmentName = selOption.getLabel();
          selectedSegmentDeleteZips = zipSegmentMap.get(selectedSegmentId).Delete_ZipAssignments__c;
          break;
       }
    } // for (SelectOption selOption
    
      // reselect the zip codes
      //getZips();
      searchPerformed = false;
      resetFilter();
      // reselect the territories
      selectedTerritoryFromId = null;
      selectedTerritoryFromObject = null;
      setupTerritoryFromPicklist();
    
   } // setSegment    
   
   /** Is the code in the process of reassigning zip codes to another territory? */
   public Boolean isReassigning{
      get {return (askForNewUser && (nbrRecordsSelected>0));}
   } // isReassigning
   
   /** Change the org structure from the form. */
   public void changeOrgStructure() {
    selectedTerritoryFromObject = null;
      setSegments(searchZa.Sales_Org__c);
      
      setSalesOrg();
      // reset the userOrgUnit
      
      // if corporate or area user, get zone picklist
      //setZonePicklistOptions(userOrgUnit);
      //setZone();
   } // changeOrgStructure
   
   /** Are there multiple district options? This is for if someone enters the form at higher than a zone level. */
   public Boolean hasDistrictOptions{
      get {return (districtOptions != null && districtOptions.size() > 1); }
   }
   public String selectedDistrictId{get;set;}
   
   public Org_Unit__c selectedDistrictOrgUnit{get; set;}
   
   public Boolean hasSelectedDistrictOrgUnit{
      get {return (selectedDistrictOrgUnit != null); }
   }
   
   public String selectedReassignDistrictId{get;set;}
   
   public Org_Unit__c selectedReassignDistrictOrgUnit = null;

   public List<SelectOption> districtOptions{get;set;}
   
   public Boolean hasDistrictReassignOptions{
      get {return (districtReassignOptions != null && !districtReassignOptions.isEmpty()); }
   } // hasDistrictReassignOptions
   
   public List<SelectOption> districtReassignOptions{get;set;}
   
   /** Keep a map for easy lookup. */
   private Map<Id,Org_Unit__c> districtOrgUnitMap = new Map<Id,Org_Unit__c>();
   
   public void setDistrictPicklistOptions(Org_Unit__c parentOu) {
      districtOptions = getOrgUnitOptions(new Org_Unit__c[]{parentOu}, OrgUnitMethods.TYPE_DISTRICT, districtOrgUnitMap, null);
      selectedDistrictId = ((districtOptions != null && !districtOptions.isEmpty()) ? districtOptions[0].getValue() : null);
   } // setDistrictPicklistOptions
   
   public void setDistrictReassignPicklistOption(Org_Unit__c parentOu) {
      districtReassignOptions = getOrgUnitOptions(new Org_Unit__c[]{parentOu}, OrgUnitMethods.TYPE_DISTRICT, districtOrgUnitMap, null);
      selectedReassignDistrictId = ((districtReassignOptions != null && !districtReassignOptions.isEmpty()) ? districtReassignOptions[0].getValue() : null);
   } // setDistrictReassignPicklistOption
   
   /** Are there zone options? This is for if someone enters the form at higher than a zone level. */
   public Boolean hasZoneOptions{
      get {return (zoneOptions != null && !zoneOptions.isEmpty()); }
   } // hasZoneOptions
   
   public String selectedZoneId{get;set;}
   
   private Org_Unit__c selectedZoneOrgUnit = null;
   
   public String selectedReassignZoneId{get;set;}
   
   private Org_Unit__c selectedReassignZoneOrgUnit = null;
   
   public List<SelectOption> zoneOptions{get;set;}

   /** Keep a map for easy lookup. */
   private Map<Id,Org_Unit__c> zoneOrgUnitMap = new Map<Id,Org_Unit__c>();
   
   public void setZonePicklistOptions(Org_Unit__c parentOu) {
      zoneOptions = getOrgUnitOptions(new Org_Unit__c[]{parentOu}, OrgUnitMethods.TYPE_ZONE, zoneOrgUnitMap, null);
      selectedZoneId = ((zoneOptions != null && !zoneOptions.isEmpty()) ? zoneOptions[0].getValue() : null);
   } // setZonePicklistOptions
   
   /** When a zone is selected from the picklist get the districts.
    */
   public void setZone() {
      // if a zone changes clear the search flag
      searchPerformed = false;
      selectedZoneOrgUnit = null;
      selectedTerritoryFromObject = null;
      resetFilter();

      if (selectedZoneId != null) {
         selectedZoneOrgUnit = zoneOrgUnitMap.get(selectedZoneId);
         if (selectedZoneOrgUnit != null) {
            setDistrictPicklistOptions(selectedZoneOrgUnit);
            setDistrict();
         }
      } // if (selectedZoneId != null
   } // setZone
   
   /** When a zone is selected from the picklist get the districts.
    */
   public void setReassignZone() {
      selectedReassignZoneOrgUnit = null;
      
      if (selectedReassignZoneId != null) {
         selectedReassignZoneOrgUnit = zoneOrgUnitMap.get(selectedReassignZoneId);
         if (selectedReassignZoneOrgUnit != null) {
            setDistrictReassignPicklistOption(selectedReassignZoneOrgUnit);
            setReassignDistrict();
         }
      } // if (selectedZoneId != null
   } // setReassignZone
   
   /** When a district is selected from a picklist get the reps.
    */
   public void setDistrict() {
      // if a zone changes clear the search flag
      searchPerformed = false;
      selectedDistrictOrgUnit = null;
      showNoneSelected = false;
      selectedTerritoryFromObject = null;
      resetFilter();
      
      checkDistrictId();
      //if (selectedDistrictId != null) {
         //selectedDistrictOrgUnit = districtOrgUnitMap.get(selectedDistrictId);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setDistrict selectedDistrictOrgUnit='+selectedDistrictOrgUnit));
         if (selectedDistrictOrgUnit != null) {
            
            selectedTerritoryFromId = null;
            setupTerritoryFromPicklist();
         }
      //} // if (selectedDistrictId != null
   } // setDistrict
   
   public void checkDistrictId() {
      if (selectedDistrictId != null) {
         selectedDistrictOrgUnit = districtOrgUnitMap.get(selectedDistrictId);
      }
   } // checkDistrictId
   
   /** When a district is selected from a picklist get the reps.
    */
   public void setReassignDistrict() {
      checkReassignDistrictId();
      if (selectedReassignDistrictOrgUnit != null) {
         //selectedAssignToUser = null;
         //setNSSFields();
            
         selectedTerritoryToId = null;
         setupTerritoryToPicklist();
      }
   } // setReassignDistrict
   
   public void checkReassignDistrictId() {
      if (selectedReassignDistrictId != null) {
         selectedReassignDistrictOrgUnit = districtOrgUnitMap.get(selectedReassignDistrictId);
      }
   }
   public void setReassignTo() {
      
   } // setReassignTo
   
   /** Create a picklist of org units based on the passed in parameters.
    */
   public List<SelectOption> getOrgUnitOptions(Org_Unit__c[] parentOus, String childType, Map<Id,Org_Unit__c> orgUnitMap, Org_Unit__c[] orgUnitsToUse) {
      List<SelectOption> orgUnitOptions = new List<SelectOption>();
      orgUnitMap.clear();
      
      // get the org units
      Org_Unit__c[] orgUnits = orgUnitsToUse;
      if (orgUnits == null) {
         orgUnits = OrgUnitMethods.getOrgUnits(parentOus, childType, null, null, null);
      }
      if (orgUnits != null && !orgUnits.isEmpty()) {

         for (Org_Unit__c ou : orgUnits) {
            orgUnitOptions.add(new SelectOption(ou.Id,ou.Name+'-'+ou.Org_Unit_Name__c));
            orgUnitMap.put(ou.Id,ou);
         }
      } // if (orgUnits != null
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getOrgUnitOptions salesOrg='+salesOrg+' parentType='+parentType+' parentOrgUnitNbr='+parentOrgUnitNbr+' childType='+childType+' nbr orgUnitOptions='+orgUnitOptions.size()));
      return orgUnitOptions;
   } // getOrgUnitOptions
   
   /*
   If user is system admin, allow them to choose any sales org/district
   If at a higher level than district, ability to transfer between any orgs you have access to.
   Add a new zip code.
   query for a range of zip codes.
   Query for a tier?
   Internal/External wholesalers - who manages the wholesaler zip codes?
   */
   
   /** Does the user have access to multiple sales orgs? */
   public Boolean hasMultipleSalesOrgs{
      get { return (salesOrgPicklist != null && salesOrgPicklist.size() > 1); }
   }
   
   /** The picklist of the available sales orgs. This is only populated for a system admin. */
   public List<SelectOption> salesOrgPicklist{get;private set;}
   
   //private Org_Unit__c[] availableDivisionOrgUnits = null;
   
   //public Org_Unit__c selectedDivisionOrgUnit{get;set;}
   
   public Org_Unit__c selectedUserOrgUnit{get;set;}
   
   /** Create a picklist of all of the sales org options. */
   public void setSalesOrgPicklist() {
      salesOrgPicklist = new List<SelectOption>();
      if (availableSalesOrgs != null && !availableSalesOrgs.isEmpty()) {
         searchZa.Sales_Org__c = (isSystemAdmin ? UserHelper.SO_CORE : availableSalesOrgs[0]);
         for (String salesOrg : availableSalesOrgs) {
            salesOrgPicklist.add(new SelectOption(salesOrg,salesOrg));
         }
      } // if (availableSalesOrgs != null
   } // setSalesOrgPicklist
   
   public String selectedTerritoryFromId{get;set;}
   
   public ZipTerritory__c selectedTerritoryFromObject{get;set;}
   
   /** Is there an email associated with the territory? */
   public Boolean hasTerritoryContact{
      get { return (selectedTerritoryFromObject != null && selectedTerritoryFromObject.TerritoryContact__c != null); }
   }
   
   public String selectedTerritoryToId{get;set;}

   private ZipTerritory__c selectedTerritoryToObject=null;
   
   /** The picklist of the territories we are transferring zip codes from (or maintaining). */
   public list<SelectOption> territoryFromPicklist{get;private set;}
   /** The picklist of the territories we are transferring zip codes to. */
   public list<SelectOption> territoryToPicklist{get;private set;}
      
   /* To hold the territories. */
   private Map<String,ZipTerritory__c> territoryMap = new Map<String,ZipTerritory__c>();
   
   public Boolean hasTerritoryFroms{
      get {return (territoryFromPicklist != null && territoryFromPicklist.size() > 2);}
   }
   
   public Boolean hasTerritoryTos{
      get {return (territoryToPicklist != null && territoryToPicklist.size() > 1);}
   }
   
   public void setupTerritoryFromPicklist() {
      territoryFromPicklist = setupTerritoryPicklist(false,selectedDistrictOrgUnit.Id,(Id)selectedSegmentId);
   } // setupTerritoryFromPicklist

   public void setupTerritoryToPicklist() {
      territoryToPicklist = setupTerritoryPicklist(true,selectedReassignDistrictOrgUnit.Id,(Id)selectedSegmentId);
   } // setupTerritoryFromPicklist
   
   public static final String REMOVE_FROM_TERRITORY='RemoveFromTerritory';
   public static final String NO_TERRITORY='NoTerritory';
   
   public List<SelectOption> setupTerritoryPicklist(Boolean isReassigning, Id districtId, Id segmentId) {
       System.debug('setupTerritoryPicklist isReassigning='+isReassigning+' districtId='+districtId+' segmentId='+segmentId);
    territoryMap.clear();
    //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setupTerritoryPicklist isReassigning='+isReassigning+' districtId='+districtId+' segmentId='+segmentId));
    List<SelectOption> territoryPicklist = new List<SelectOption>();
      territoryPicklist.add(new SelectOption('NONE','--Select A Territory--'));
      if (isReassigning) {
        // TODO - not sure we would actually want them to have zip codes that are not part of a territory...
         //territoryPicklist.add(new SelectOption(REMOVE_FROM_TERRITORY,'Remove from Territory'));
      } else {
         territoryMap.clear();
         territoryPicklist.add(new SelectOption(NO_TERRITORY,'Zips Without a Territory'));
      }
    
    if (selectedDistrictOrgUnit != null && selectedSegmentId != ZipQueries.SEGMENT_DEFAULT) {
    
      //APR0151864: SMB Channel Evolution BAU--District__r.Queue_Name__c added to the query
         ZipTerritory__c[] territories = [Select Id, Name
                                             ,District__c
                                             ,District__r.Sales_Org__c
                                             ,District_Lockout__c
                                             ,Rep_Name__c
                                             ,Territory_Nbr__c
                                             ,TerritoryContact__c
                                             ,TerritoryContact__r.Id
                                             ,TerritoryContact__r.Name
                                             ,TerritoryContact__r.FirstName
                                             ,TerritoryContact__r.LastName
                                             ,TerritoryContact__r.Email
                                             ,TerritoryRep__c
                                             ,TerritoryRep__r.Id
                                             ,TerritoryRep__r.Name
                                             ,TerritoryRep__r.FirstName
                                             ,TerritoryRep__r.LastName
                                             ,TerritoryRep__r.IsActive
                                             ,TerritoryRep__r.HR_Person_Id__c
                                             ,TerritoryRep__r.ASO_Partner__c
                                             ,TerritoryRep__r.HR_Services_Partner__c
                                             ,OverrideAssistant__r.Name
                                             ,OverrideAssistant__r.Email
                                             ,OverrideAssistant__r.Id
                                             ,OverrideAssistant__c
                                             ,OverrideManager__r.Name
                                             ,OverrideManager__r.Email
                                             ,OverrideManager__r.Id
                                             ,OverrideManager__c
                                             ,Zip_Segment__c
                                             ,Zip_Segment__r.Name
                                             ,Zip_Segment__r.Delete_ZipAssignments__c
                                             ,Zip_Segment__r.CloneTo__c
                                             ,Zip_Segment__r.CloneFrom__c
                                             ,District__r.Queue_Name__c                                             
                                         From ZipTerritory__c
                                        Where District__c = :districtId
                                          and Zip_Segment__c = :segmentId
                                          order by Name];

         for (ZipTerritory__c territory : territories) {
            if (!isReassigning || (isReassigning && selectedTerritoryFromId == null || selectedTerritoryFromId != territory.id)) {
               territoryMap.put(territory.Id,territory);
               territoryPicklist.add(new SelectOption(territory.Id, territory.Name+(isReassigning ? '-'+territory.Zip_Segment__r.Name : '')));
            }
         } // for (ZipTerritory__c
    } // if
    return territoryPicklist;
   } // setupTerritoryPicklist
   
   /** Select the "from" territory from the picklist. */
   public void selectTerritoryFrom() {
      selectedTerritoryFromObject = null;
      if (String.isNotBlank(selectedTerritoryFromId)) {
        // default values for the zip code filter
         resetFilter();
         selectedTerritoryFromObject = territoryMap.get(selectedTerritoryFromId);
         setZipAssignmentsSetController();
      }
   } // selectTerritoryFrom
   
   /** Select the "to" territory from the picklist. */
   public void selectTerritoryTo() {
      selectedTerritoryToObject = null;
      if (String.isNotBlank(selectedTerritoryToId)) {
         selectedTerritoryToObject = territoryMap.get(selectedTerritoryToId);
      }
   } // selectTerritoryFrom
   
   /** Was the territory from selected? */
   public Boolean hasTerritoryFromObject {
      get {return (selectedTerritoryFromObject != null); }
   } // territoryFromSelected
   
   /** is the territory from object new? */
   public Boolean isTerritoryFromNew {
      get {return (selectedTerritoryFromObject != null && selectedTerritoryFromObject.Id == null); }
   } // isTerritoryFromNew
   
   public Boolean editTerritoryFrom{get;set;}
   
   public Boolean showZipAssignments{get;set;}
   
   public PageReference toggleShowAssignments() {
      //getZips();
      showZipAssignments = !showZipAssignments;
      setZipAssignmentsSetController();
      return null;
   } // searchForZips
   
   public ZipTerritory__c editTerritoryRecord{get;set;}
   
   public void editTerritory() {
    showZipAssignments = false;
    editTerritoryFrom = true;
    editTerritoryRecord = selectedTerritoryFromObject.clone(true,true);
   } // editTerritory
   
   public void createNewTerritory() {
      showZipAssignments = false;
      editTerritoryFrom = true;
      editTerritoryRecord = new ZipTerritory__c(District__c=selectedDistrictOrgUnit.Id, Zip_Segment__c=selectedSegmentId);
      
   } // createNewTerritory
   
   /* clone selected Territory if CloneTo and CloneFrom fields are populated on Zip Segment record
      also take Zip Assignments with it if there is not already a zip assignment for that segment
   */
   public void cloneTerritory() {
        Zip_Segment__c cloneToSegment;  
        Zip_Assignment__c[] insertZas = new Zip_Assignment__c[]{};
                    
        if (selectedTerritoryFromObject.Zip_Segment__r.CloneFrom__c)        
        {   ZipTerritory__c clonedZipTerr = selectedTerritoryFromObject.clone(false,true);
            // get CloneTo segment in same sales org, if there is a CloneFrom there must be a CloneTo               
            for (Zip_Segment__c seg: zipSegmentMap.values())
            {   if (seg.CloneTo__c && seg.Id == selectedCloneSegmentId)
                {   clonedZipTerr.Zip_Segment__c = seg.Id;
                    cloneToSegment = seg;                   
                }               
            } // for 
  
            insert clonedZipTerr;
            
            selectAll = true;
            selectAllZips();
            Boolean zipsSelected = checkForSelected();          
            showZipAssignments = true;          
            String salesOrg = getSaveSalesOrg();
            Map<String, Zip_Assignment__c> zipAssgnMap = new Map<String, Zip_Assignment__c>();
            
            if (zipsSelected)
            {
                for (ZipWrapper zw : selectedZipWraps)
                {   zipAssgnMap.put(zw.za.Name, zw.za); }
            
                Zip_Assignment__c[] zas = [Select Id, Name, Sales_Org__c, Segment_Name__c
                                              ,District__c
                                              ,District__r.Name
                                              ,Zip_Segment__r.Name
                                              ,ZipTerritory__r.Name
                                           From Zip_Assignment__c
                                           Where Sales_Org__c = :salesOrg
                                             and Name in :zipAssgnMap.keySet()
                                             and Zip_Segment__c = :clonedZipTerr.Zip_Segment__c];
                                             
                // gather zipcodes from query so we dont create duplicates
                zipAssgnMap = new Map<String, Zip_Assignment__c>();             
                if (!zas.isEmpty()) 
                {   for (Zip_Assignment__c za : zas) 
                    {   zipAssgnMap.put(za.Name,za);    }
                } // if (!zas.isEmpty())
                    
                for (ZipWrapper zw : selectedZipWraps)
                {   if (zipAssgnMap.containsKey(zw.za.Name))
                    {   //String msg = 'Zip Code '+zw.za.Name+' already exists';
                        String msg = 'Zip Code already exists';
                        if (zipAssgnMap.get(zw.za.Name).District__r != null) 
                        {   msg += ' in District '+ zipAssgnMap.get(zw.za.Name).District__r.Name;
                            if (zipAssgnMap.get(zw.za.Name).ZipTerritory__r != null) 
                            {   msg += ' Territory '+ zipAssgnMap.get(zw.za.Name).ZipTerritory__r.Name;  }
                        }
                        msg += '!';
                        zw.za.Name.addError(msg);
                        zw.selected = false;                                                   
                    }  // if (zipNameSet.contains(zw.za.Name)
                    else
                    {   Zip_Assignment__c clonedZa = zw.za.clone(false, true);
                        clonedZa.ZipTerritory__c=clonedZipTerr.Id;
                        clonedZa.User__c = clonedZipTerr.TerritoryRep__c;
                        clonedZa.HR_Person_Id__c = (clonedZipTerr.TerritoryRep__r != null ? clonedZipTerr.TerritoryRep__r.HR_Person_Id__c : null);
                        clonedZa.District__c = clonedZipTerr.District__c;
                        clonedZa.Rep_Name__c = clonedZipTerr.Rep_Name__c;
                        clonedZa.BypassDistrictTrigger__c = true;
                        clonedZa.Zip_Segment__c = clonedZipTerr.Zip_Segment__c;
                        clonedZa.Segment_Name__c = cloneToSegment.Name;
                        insertZas.add(clonedZa);
                    } // else
                } // for(ZipWrapper

                if (!insertZas.isEmpty())               
                {   insert insertZas;   }
            } // if (zipsSelected)
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'New territory with '+insertZas.size()+' Zip Codes has been saved!'));
                    
            //askForNewUser = false;
            //selectAll = false;
            //repopulate Territory picklist that also requeries ZipAssignments
            //setupTerritoryFromPicklist();
            //queryZar = new ZipAssignmentRequest__c();
            //selectAllZips();
            //setZipAssignmentsSetController();
        }
        else    // should never get here coz checked in toggleUseClone
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Territory '+selectedTerritoryFromObject.Name+' in Segment '+selectedSegmentName + ' Cannot be Cloned!'));    }
        
        toggleUseClone();
   } // cloneTerritory
   
   
   
   /** Delete the current territory.  Will also remove Zip Assignments is zip segment allows it.
       Any zip codes attached to the territory will still be attached to the district, but will no longer
       be part of the territory. */
   public void deleteTerritory() {
      Zip_Assignment__c[] deleteZas = new Zip_Assignment__c[]{};
      if (selectedSegmentDeleteZips)
      {     // delete any zip assignments this territory has
            selectAll = true;
            selectAllZips();            
            Boolean zipsSelected = checkForSelected();              
            if (zipsSelected)
            {   for (ZipWrapper zw : selectedZipWraps) 
                {   deleteZas.add(zw.za);   }
            } // if (zipsSelected)
            delete deleteZas;
      } // if (selectedSegmentDeleteZips)
      
      if (selectedTerritoryFromObject != null) {
          String territoryName = selectedTerritoryFromObject.Name;
          delete selectedTerritoryFromObject;
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Territory '+territoryName+' Successfully Deleted along with '+deleteZas.size()+' zip codes assignments!'));
      }  // if      
      selectedTerritoryFromId = null;
      editTerritoryFrom = false;
      // requery the territories
      setupTerritoryFromPicklist();
      selectTerritoryFrom();
      showZipAssignments = false;

   } // deleteTerritory
   
   // save the territory
   public PageReference saveTerritory() {
      performTerritorySave();
      return null;
   } // saveTerritory
   
   /** Confirm required fields are filled in and save the territory change. */
   public Boolean performTerritorySave() {
    // verify record - 
    Boolean allOkay = true;
    // territory name has to be filled in
    if (String.isBlank(editTerritoryRecord.Name)) {
       editTerritoryRecord.Name.addError('Territory Name must be entered!');
       allOkay = false;
    }
    //user or rep name have to be filled in.
    if (String.isBlank(editTerritoryRecord.Rep_Name__c) && editTerritoryRecord.TerritoryRep__c == null) {
        editTerritoryRecord.TerritoryRep__c.addError('Must enter either Territory Rep or Rep Name!');
    }
    
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'performTerritorySave allOkay='+allOkay));
    if (!allOkay) {
       return allOkay;
    }
    
    ZipAssignment.setTerritoryRep(editTerritoryRecord, null);
    /*
    // if core or mms, have to have a user - this defines the owner on the account/contact/lead
      // core - ZipAssignment.UNASSIGNED_CORE_PERSON_ID
      // mms - ZIpAssignment.UNASSIGNED_MMS_PERSON_ID
    if (editTerritoryRecord.TerritoryRep__c == null && (selectedDistrictOrgUnit.Sales_Org__c == UserHelper.SO_CORE || selectedDistrictOrgUnit.Sales_Org__c == UserHelper.SO_MMS)) {
        String personId = ((selectedDistrictOrgUnit.Sales_Org__c == UserHelper.SO_MMS) ? UserHelper.UNASSIGNED_MMS_PERSON_ID : UserHelper.UNASSIGNED_CORE_PERSON_ID);
        // select the user
        User unassignedUser = new UserHelper().getUserByPersonId(personId);
        editTerritoryRecord.TerritoryRep__c = (unassignedUser != null ? unassignedUser.Id : null);

    } // if (editTerritoryRecord.TerritoryRep__c == null
    
    // populate the rep name if a user is selected
    if (editTerritoryRecord.TerritoryRep__c != null && String.isBlank(editTerritoryRecord.Rep_Name__c)) {
       // select the user record
       User rep = new UserHelper().getUserById(editTerritoryRecord.TerritoryRep__c);
       if (rep != null) {
          editTerritoryRecord.Rep_Name__c = rep.Name;
       }
    } // if (editTerritoryRecord.TerritoryRep__c != null
    */
    // save the record
    upsert editTerritoryRecord;
    selectedTerritoryFromId = editTerritoryRecord.Id;
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Territory Changes Successfully Saved!'));
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'performTerritorySave selectedTerritoryFromId='+selectedTerritoryFromId));

      editTerritoryFrom = false;
    // requery the territories
    setupTerritoryFromPicklist();
    selectTerritoryFrom();
    return true;
   } // performTerritorySave
   
   public void cancelEditTerritory() {
    editTerritoryFrom = false;
    editTerritoryRecord = null;
   } // cancelEditTerritory
   
   public void saveASOPartner(){
     User territoryRep = new User();
     territoryRep.Id = editTerritoryRecord.TerritoryRep__c;
     territoryRep.ASO_Partner__c = editTerritoryRecord.TerritoryRep__r.ASO_Partner__c;
     update territoryRep;
       ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'ASO Partner Updated.  Please allow up to 30 minutes for the corresponding prospect records to be updated.'));
   }
    
    public void saveHRServicePartner(){
        User territoryRep = new User();
        territoryRep.Id = editTerritoryRecord.TerritoryRep__c;
        territoryRep.HR_Services_Partner__c = editTerritoryRecord.TerritoryRep__r.HR_Services_Partner__c;
        update territoryRep;
        upsert editTerritoryRecord;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'HR Services Partner Updated.'));
    }
    
   /** Were zip assignments found? */
   public Boolean zipAsgnsFound{
    get {return (zipAssignmentSet != null && zipAssignmentSet.getResultSize()>0); }
   } // zipAsgnFound
   
   public static final String ZA_QUERY='Select Id, Name'+
                                       ',Cost_Center__c'+
                                       ',District__c'+
                                       ',District__r.Name'+
                                       ',HR_Person_Id__c'+
                                       ',Organization_Structure__c'+
                                       ',Rep_Name__c'+
                                       ',Sales_Office__c'+
                                       ',Sales_Org__c'+
                                       ',Segment_Name__c'+
                                       ',User__c'+
                                       ',User__r.ASO_Partner__c'+
                                       ',User__r.HR_Services_Partner__c'+
                                       ',User__r.NSS_Territory_Nbr__c'+
                                       ',Zip_Code_Information__r.City__c'+
                                       ',Zip_Code_Information__r.State__c'+
                                       ',ZipTerritory__c'+
                                       ',ZipTerritory__r.Name'+
                                       ',ZipTerritory__r.OverrideAssistant__r.Id'+
                                       ',ZipTerritory__r.OverrideAssistant__r.Email'+
                                       ',ZipTerritory__r.OverrideAssistant__r.Name'+
                                       ',ZipTerritory__r.OverrideAssistant__c'+
                                       ',ZipTerritory__r.OverrideManager__r.Id'+
                                       ',ZipTerritory__r.OverrideManager__r.Email'+
                                       ',ZipTerritory__r.OverrideManager__r.Name'+
                                       ',ZipTerritory__r.OverrideManager__c'+
                                       ',(Select Id, Name, FirstName__c, LastName__c, User__c'+
                                       '    From ZipAssignmentRequests__r'+
                                       '   Where Complete__c = false'+
                                       '   order by CreatedDate desc) '+
                                   'From Zip_Assignment__c';
   
   public ApexPages.StandardSetController zipAssignmentSet{get;set;}
   
   // are we going to filter the zip code results?
   public Boolean useFilter{get;set;}
   public String zipLow{get;set;}
   public String zipHigh{get;set;}
   
   public void resetFilter(){
        useFilter = false;
        zipLow = '00000';
        zipHigh = '99999';
        selectedStateFilter = null;
   }
   public void toggleUseFilter() {
      useFilter = !useFilter;
      if (!useFilter) {
        // reselect without the filter on
         setZipAssignmentsSetController();
      }
      else{
        populateStateFilterList();
      }
   } // toggleUseFilter

   // which segment are we cloning to?
   public Boolean useClone{get; set;}
   public List<SelectOption> cloneSegmentOptions{get;set;}
   public String selectedCloneSegmentId{get;set;}
   
   public void toggleUseClone() {
      useClone = !useClone;   
      if (useClone)
      {   if (!selectedTerritoryFromObject.Zip_Segment__r.CloneFrom__c)   
          {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This Territory '+selectedTerritoryFromObject.Name+' in Segment '+selectedSegmentName + ' Cannot be Cloned!'));  
              useClone = !useClone;
          }   
          else
          {   cloneSegmentOptions = new List<SelectOption>();
              for (Zip_Segment__c seg: zipSegmentMap.values())
              {   if (seg.CloneTo__c)
                  { cloneSegmentOptions.add(new SelectOption(seg.Id, seg.Name));    }
              } // for
          } // else 
      } // if (useClone)
      
   } // toggleUseClone
      
   private Integer recsPerPage=300;
   
   public List<SelectOption> stateFilterList{get;set;}
   public String selectedStateFilter{get;set;}
   
   public void populateStateFilterList(){
        /*Schema.DescribeFieldResult fieldResult = Account.State.getDescribe();
        List<Schema.PicklistEntry> stateValues = fieldResult.getPicklistValues();
        System.debug('Picklist::'+stateValues);
        stateFilterList = new List<SelectOption>();
        for( Schema.PicklistEntry state : stateValues){
            SelectOption o = new SelectOption(state.getLabel(),state.getValue());
            stateFilterList.add(o);
        }*/
        String[] stateAbbrs = new String[]{'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA'
                                            ,'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD'
                                            ,'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ'
                                            ,'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC'
                                            ,'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY'};
        stateFilterList = new List<SelectOption>();
        stateFilterList.add(new SelectOption('','All'));
        for( String state : stateAbbrs){
            SelectOption o = new SelectOption(state,state);
            stateFilterList.add(o);
        }
   }
   
   public void applyFilter() {
      if (String.isBlank(zipLow)) {
         zipLow = '00000';
      }
      if (String.isBlank(zipHigh)) {
         zipHigh = '99999';
      }
      
      // verify 5 characters and all numbers
      String zipLowCheck = Utilities.removeExtraChars(zipLow,Utilities.ALL_NUMBERS);
      String zipHighCheck = Utilities.removeExtraChars(zipHigh,Utilities.ALL_NUMBERS);
      Boolean okay = true;
      if (zipLowCheck.length() != 5) {
         okay = false;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid value for Starting Zip: '+zipLow));
      }
      if (zipHighCheck.length() != 5) {
         okay = false;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid value for Ending Zip: '+zipHigh));
      }
      
      if (okay) {
         setZipAssignmentsSetController();
      }
   } // applyFilter
   
   /** Get all of the open ownership records.
     @param userId - the user we are selecting for
     @param recsPerPage - the number of records per page
     @param statusFilter - to only select certain statuses/stages
     */
   public void setZipAssignmentsSetController() {
      zipAssignmentSet = null;
      displayZipWraps = null;
      if (selectedDistrictOrgUnit != null) {
        searchPerformed = true;
        Id districtId = selectedDistrictOrgUnit.Id;
        Id territoryId = null;
         String query = ZA_QUERY;
         query += ' Where District__c = :districtId '; 
         if (selectedTerritoryFromObject == null) {
            query += ' and ZipTerritory__c=null ';
         } else {
            territoryId = selectedTerritoryFromObject.Id;
            query += ' and ZipTerritory__c=:territoryId ';
         }

         if (useFilter) {
            query += ' and (Name >= :zipLow and Name <= :zipHigh) ';
            if(selectedStateFilter!=null){
                query += 'and Zip_Code_Information__r.State__c = :selectedStateFilter';
                //test with Core Zone 7, District 99, Tier2, Roberts.
            }
         }
         // set the limit on rows returned
         Integer allowedRows = Limits.getLimitQueryLocatorRows() - Limits.getQueryLocatorRows();
         query += ' Order by Name limit '+allowedRows;
         
         System.debug('setZipAssignmentsSetController query='+query);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssignmentsSetController query='+query));
         zipAssignmentSet = new ApexPages.StandardSetController(Database.getQueryLocator(query));
         zipAssignmentSet.setPageSize(recsPerPage); 
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setZipAssignmentsSetController districtId='+districtId+' territoryId='+territoryId+' results='+zipAssignmentSet.getResultSize()));

      } // if (userId != null

   } // setZipAssignmentsSetController

   /** Goto the next page of records. */
   public void next() {
      displayZipWraps = null;
      zipAssignmentSet.next();
   } // next

   /** Goto the previous page of records. */
   public void previous() {  
      displayZipWraps = null;
      zipAssignmentSet.previous();  
   } // previous    

   /** Goto the next page of records. */
   public void firstPage() {
      displayZipWraps = null;
      zipAssignmentSet.first();
   } // next

   /** Goto the previous page of records. */
   public void lastPage() {  
      displayZipWraps = null;
      zipAssignmentSet.last();  
   } // previous    

   /** The total number of pages available. */
   public Integer numOfPages {
      get {
         if (numOfPages == null) {
            
            numOfPages = 1;
            if (zipAssignmentSet != null) {
               decimal result = Decimal.valueOf(zipAssignmentSet.getResultSize()) / Decimal.valueOf(zipAssignmentSet.getPageSize());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
               numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
            }
         } // if (numOfPages
         return numOfPages;
      } // get
      private set;
   } // numOfPages
   
   /** Is there a list to display to the user? */
   public Boolean hasDisplayZipWraps{
      get {return (displayZipWraps != null && !displayZipWraps.isEmpty()); }
   }
   
   public List<ZipWrapper> displayZipWraps{
      get {
         if (displayZipWraps == null && zipAssignmentSet != null) {
            displayZipWraps = new List<ZipWrapper>();
            List<Zip_Assignment__c> recs = (List<Zip_Assignment__c>) zipAssignmentSet.getRecords();
            for (Zip_Assignment__c rec : recs) {
               ZipWrapper zw = new ZipWrapper(rec);
               displayZipWraps.add(zw);
            } // for
         } // if (displayZipWraps == null
         return displayZipWraps;
      } // get
      private set;
   } // displayZipWraps
   


   public void cancelReassign() {
      askForNewUser = false;
      // TODO - should we clear all selected on cancel?
      selectAll = false;
      selectAllZips();
   } // cancelReassign
   

   /** Create the request objects. */ 
   public void performAssignToSelection() {
      //ZipAssignmentRequest__c[] saveRequests = new ZipAssignmentRequest__c[]{};

      // the assignments we are updating
      Zip_Assignment__c[] updateZas = new Zip_Assignment__c[]{};
      
      // create requests and update the selected zip codes
      for (ZipWrapper zw : selectedZipWraps) {
        //ZipAssignmentRequest__c zar = new ZipAssignmentRequest__c(Zip_Assignment__c=zw.za.Id, Status__c=ZipAssignment.REQUEST_SUBMITTED
        //                                 ,OldTerritory__c=zw.za.ZipTerritory__c, NewTerritory__c=selectedTerritoryToObject.Id);
        //saveRequests.add(zar);
        zw.za.ZipTerritory__c=selectedTerritoryToObject.Id;
        zw.za.User__c = selectedTerritoryToObject.TerritoryRep__c;
        zw.za.HR_Person_Id__c = (selectedTerritoryToObject.TerritoryRep__r != null ? selectedTerritoryToObject.TerritoryRep__r.HR_Person_Id__c : null);
        zw.za.District__c = selectedTerritoryToObject.District__c;
        zw.za.Rep_Name__c = selectedTerritoryToObject.Rep_Name__c;
        zw.za.BypassDistrictTrigger__c = true;
        updateZas.add(zw.za);
         //saveRequests.add(newRequest(zw.za,queryZar));
      } // for (ZipWrapper zw
      
      if (!updateZas.isEmpty()) {
         //insert saveRequests;
         update updateZas;
         
         //hasPendingRequests = true;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, updateZas.size()+' Zip Codes changes were saved!'));
         
         // get the ids of the records
         //Id[] requestIds = new Id[]{};
         //for (ZipAssignmentRequest__c zar : saveRequests) {
         //   requestIds.add(zar.Id);
         //}
         //sendRequests(requestIds);
      } // if (!saveRequests.isEmpty
      askForNewUser = false;
      // deselect the selected records.
      selectAll = false;
      //queryZar = new ZipAssignmentRequest__c();
      
      selectAllZips();
      // reselect all of the zip codes
      setZipAssignmentsSetController();
      //getZips();
      
   } // performAssignToSelection

   /** Create a new ZipAssignmentRequest__c object.
    */
   //public ZipAssignmentRequest__c newRequest(Zip_Assignment__c za, ZipAssignmentRequest__c p_zar) {
   //   ZipAssignmentRequest__c zar = p_zar.clone(false,true);
   //   zar.Zip_Assignment__c = za.Id;
   //   return zar;
   //} // newRequest
   
   /** For the "Select All" checkbox on the form. */
   public Boolean selectAll{get;set;}
   
   /** Toggle the selected flag on all of the zip codes.
    */
   public void selectAllZips() {
      for (ZipWrapper zw : displayZipWraps) {
         zw.selected = selectAll;
      }
   } // selectAllZips
   
   /** Are we asking for a new user to reassign zip codes to? */
   public Boolean askForNewUser{get;set;}
   
   /** Show the no zip codes selected message. */
   public Boolean showNoneSelected{get;set;}
   
   /** Count the number of records selected. */
   public Integer nbrRecordsSelected{
      get { return (selectedZipWraps == null || selectedZipWraps.isEmpty() ? 0 : selectedZipWraps.size()); }
   } // nbrRecordsSelected
   
   /** Start reassigning the zip codes to a new territory. */
   public void startReassigningZips() {
      askForNewUser = checkForSelected();
      System.debug('startReassigningZips askForNewUser='+askForNewUser);
      
      //queryZar = new ZipAssignmentRequest__c();
      
      showNoneSelected = !askForNewUser;
      //selectedAssignToUser = null;
      if (askForNewUser) {
         // default to first option
         //selectedAssignToOption = 'User';
         
         setReassignOrgs();

         if (selectedReassignDistrictOrgUnit != null) {
            //assignToUsers = getDistrictUserOptions(selectedReassignDistrictOrgUnit.Sales_Org__c, selectedReassignDistrictOrgUnit.Name, assignToUserMap, true,null);
            setupTerritoryToPicklist();
         }
         reassignZa.Sales_Org__c = searchZa.Sales_Org__c;
         //reassignZa.DistrictNbr__c = searchZa.DistrictNbr__c;
         
         //setupUserTypeOptions();
         //setNSSFields();
      }
   } // startReassigningZips
   
   public void setReassignOrgs() {
      selectedReassignZoneId = selectedZoneId;
      selectedReassignZoneOrgUnit = selectedZoneOrgUnit;
      selectedReassignDistrictId = selectedDistrictId;
      selectedReassignDistrictOrgUnit = selectedDistrictOrgUnit;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'setReassignOrgs selectedDistrictId='+selectedDistrictId));
         
      if (hasDistrictOptions) {
         districtReassignOptions = new List<SelectOption>();
         districtReassignOptions.addAll(districtOptions);
         //setReassignDistrict();
            
      } //else if (isDistrictUser) {

   } // setReassignOrgs
   
   /** Has all of the reassign criteria been entered? */
   public Boolean reassignCriteriaEntered{
      get {return (isReassigning && selectedTerritoryToObject != null);
      } // get
   } // reassignCriteriaEntered
   
   public List<ZipWrapper> selectedZipWraps{get;set;}
   
   /** check how many zip codes are selected
    */
   public Boolean checkForSelected() {
      selectedZipWraps = new List<ZipWrapper>();
      if (displayZipWraps != null) {
         for (ZipWrapper zw : displayZipWraps) {
            if (zw.selected) {
               selectedZipWraps.add(zw);
            } // if (za.selected
         } // for (ZipWrapper
      } // if (displayZipWraps
      
      // return true if at least one record is selected 
      return (nbrRecordsSelected > 0);
   } // checkForSelected
   
   public void setReassignUser() {
      //setNSSFields();
   }
   
   // Are we in the process of adding zip codes? 
   public Boolean addingZipCode{get;set;}
   
   /** The number of zip codes to add */
   public Integer nbrToAdd{get;set;}
   
   public List<Zip_Assignment__c> zipsToAdd{get;set;}
   
   /** The maximum zip codes we'll allow them to add at once. */
   public static Integer MAX_ZIP_ADD=200;
   
   /** Change the number of zip codes we're adding. */
   public void changeAddZipQuantity() {
      // make sure at least one is entered
      if (nbrToAdd == null || nbrToAdd < 1) {
         nbrToAdd = 1;
      }
      // no more than MAX_ZIP_ADD
      if (nbrToAdd > MAX_ZIP_ADD) {
         nbrToAdd = MAX_ZIP_ADD;
      }
      // if we need to add more
      while (nbrToAdd > zipsToAdd.size()) {
         zipsToAdd.add(new Zip_Assignment__c(Sales_Org__c=searchZa.Sales_Org__c, District__c=selectedDistrictOrgUnit.Id, Segment_Name__c=selectedSegmentName, Zip_Segment__c=selectedSegmentId, ZipTerritory__c=selectedTerritoryFromObject.Id));
      } // while

      // if we need to remove some - keep on removing the last one
      while (nbrToAdd < zipsToAdd.size()) {
         zipsToAdd.remove(zipsToAdd.size()-1);
      }
   } // changeAddZipQuantity
   
   /** Add 1 or more zip codes for a sales org/tier. */
   public void addNewZipCodes() {
      addingZipCode = true;
      // default to adding 1 zip code
      nbrToAdd = 1;
      zipsToAdd = new List<Zip_Assignment__c>();
      changeAddZipQuantity();
      
      //newZa = new Zip_Assignment__c(Sales_Org__c=searchZa.Sales_Org__c, Segment_Name__c=selectedSegmentId);
      //queryZar = new ZipAssignmentRequest__c();

      //User selectedUser = getSelectedAvailUser();
      //newZa.Rep_Name__c = 'NEW ZIP REQUEST PENDING';
      //if (selectedUser != null) {
      //   queryZar.FirstName__c = selectedUser.FirstName;
      //   queryZar.LastName__c = selectedUser.LastName;
      //   queryZar.User__c = selectedUser.id;
      //   queryZar.User__r = selectedUser;
      //} else {
      //   queryZar.FirstName__c = 'OPEN';
      //   queryZar.LastName__c = null;
      //}
      //setNSSFields(queryZar,selectedUser,selectedDistrictOrgUnit);
   } // addNewZipCode
   
   /** Get the sales org that's saved in Zip Assignment. Wholesaler records use a different sales org.
    */
   public String getSaveSalesOrg() {
      return ((selectedSegmentName != null && selectedSegmentName==UserHelper.WHOLESALER_INTERNAL) ? UserHelper.SO_WHOLESALER : searchZa.Sales_Org__c);
   } // getSaveSalesOrg
   
   public void saveNewZipRequest() {
      //if (!hasSelectedAvailableUser && (String.isBlank(queryZar.FirstName__c) && String.isBlank(queryZar.LastName__c))) {
      //   queryZar.FirstName__c.addError('You must enter a name to continue!');
      //   System.debug('saveNewZipRequest exiting because of no name');
      //   return;
      //}

      // make sure all rows are filled out, 5 characters, and distinct
      Map<String,Zip_Assignment__c> zipMap = new Map<String,Zip_Assignment__c>();
      Boolean allOkay = true;

      String salesOrg = getSaveSalesOrg();

      for (Zip_Assignment__c za : zipsToAdd) {
        // ignore fields that are blank
        if (String.isBlank(za.Name)) {
           // do nothing
        } else if (za.Name.length() != 5) {
            System.debug('saveNewZipRequest-You need to enter a 5 digit zip code! '+za.Name);
            za.Name.addError('You need to enter a 5 digit zip code!');
            allOkay = false;
         } else if (zipMap.containsKey(za.Name)) {
            System.debug('saveNewZipRequest-You have entered this zip code more than once. '+za.Name);
            za.Name.addError('You have entered this zip code more than once.');
            allOkay = false;
         } else {
            zipMap.put(za.Name,za);
         }

         za.Sales_Org__c = salesOrg;
         za.User__c = selectedTerritoryFromObject.TerritoryRep__c;
         za.Rep_Name__c = selectedTerritoryFromObject.Rep_Name__c;
         za.District__c = selectedDistrictOrgUnit.Id;
         za.BypassDistrictTrigger__c = true;

         if (selectedTerritoryFromObject.TerritoryRep__r != null) {
            za.HR_Person_Id__c = selectedTerritoryFromObject.TerritoryRep__r.HR_Person_Id__c;
         }
         
      } // for (Zip_Assignment__c
      
      if (allOkay && zipMap.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'No Zip Codes were entered!'));
         allOkay = false;
      }
      if (!allOkay) {
         System.debug('saveNewZipRequest exiting because !allOkay');
         return;
      } // if (!allOkay
      
      
      // check if the zip code already exists
      Zip_Assignment__c[] zas = [Select Id, Name, Sales_Org__c, Segment_Name__c
                                      ,District__c
                                      ,District__r.Name
                                      ,Zip_Segment__r.Name
                                      ,ZipTerritory__r.Name
                                   From Zip_Assignment__c
                                  Where Sales_Org__c = :salesOrg
                                    and Name in :zipMap.keySet()
                                    and Zip_Segment__c = :selectedSegmentId];
      // if anything is returned there are duplicates. Mark them and return to the form
      if (!zas.isEmpty()) {
         for (Zip_Assignment__c za : zas) {
            Zip_Assignment__c foundZa = zipMap.get(za.Name);
            if (foundZa != null) {
                String msg = 'Zip Code already exists';
                if (za.District__r != null) {
                   msg += ' in District '+za.District__r.Name;
                   if (za.ZipTerritory__r != null) {
                      msg += ' Territory '+za.ZipTerritory__r.Name;
                   }
                }
                msg += '!';
               foundZa.Name.addError(msg);
            } // if (foundZa != null
         } // for
         System.debug('saveNewZipRequest exiting because of zip code already existing');
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Zip Code already exists for '+newZa.Name+', Sales Org '+newZa.Sales_Org__c+', Segment '+newZa.Segment_Name__c));
         return;
      } //
      
      // if we get to here, we are okay to save. Save the Zip Assignments and create a Zip Request for each Zip Assignment.
      insert zipMap.values();
      
      /* No longer need - 10/22/2014
      ZipAssignmentRequest__c[] requests = new ZipAssignmentRequest__c[]{};
      for (Zip_Assignment__c za : zipMap.values()) {
        ZipAssignmentRequest__c zar = new ZipAssignmentRequest__c(Zip_Assignment__c=za.Id, NewTerritory__c=selectedTerritoryFromObject.Id);
        // TODO - will we automatically let users enter them, or will there be approval? 
        // for now, let the change automatically happen.
        zar.Status__c=ZipAssignment.REQUEST_COMPLETE;
         requests.add(zar);
      } // for
      insert requests;
      */
      
      addingZipCode = false;
      //hasPendingRequests = true;
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, requests.size()+' Changes have been saved. Remember to click the Send Requests to NSS button when you are finished to send all requests to NSS'));
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, zipMap.size()+' Zip Codes were added!'));
      //getZips();
      setZipAssignmentsSetController();
   } // saveNewZipRequest
   
   public void cancelNewZipRequest() {
      addingZipCode = false;
      
   } // cancelNewZipRequest
   
   
   public Boolean hasDistrictUserLinks{
      get { return (selectedDistrictOrgUnit != null && selectedDistrictOrgUnit.Org_Unit_User_Links__r != null && !selectedDistrictOrgUnit.Org_Unit_User_Links__r.isEmpty()); }
   } // hasDistrictUserLinks
   
   public Boolean managingDistrict{get;set;}
   
   /** Manage the district settings - like the DSM/DSA information. */
   public void manageDistrict() {
      managingDistrict = true;
      
   } // manageDistrict
   
   public void saveManageDistrictChanges() {
      // verify the role name
      //OrgUnitMethods.checkOrgUnitRole(selectedDistrictOrgUnit);
      /*
      String roleName = new OrgUnitMethods().getRoleName(selectedDistrictOrgUnit,OrgUnitMethods.TYPE_DISTRICT);
      if (String.isNotBlank(roleName)) {
         // try to find the role
         UserRole uRole = UserHelper.getRoleByName(roleName);
         if (uRole == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Could not find a valid role for '+roleName+'! DSM/DSA will NOT be attached to the District.'));
            //selectedDistrictOrgUnit.UserRoleName__c.addError('Could not find a valid role for '+roleName+'! DSM/DSA will NOT be attached to the District.');
            selectedDistrictOrgUnit.UserRoleName__c = null;
         } else {
            selectedDistrictOrgUnit.UserRoleName__c = roleName;
            selectedDistrictOrgUnit.UserRoleId__c = uRole.Id;
         }
      } // if (String.isNotBlank 
      */
      update selectedDistrictOrgUnit;
      
      // reselect the district

      managingDistrict = false;

   } // saveManageDistrictChanges
   
   public void cancelManageDistrict() {
      managingDistrict = false;
   }
   /** Wrapper class used to assist in the selection of zip codes to reassign. */
   public class ZipWrapper {
      public ZipWrapper(Zip_Assignment__c p_za) {
         za = p_za;
         selected = false;
         if (za.ZipAssignmentRequests__r != null && !za.ZipAssignmentRequests__r.isEmpty()) {
            openRequestName = za.ZipAssignmentRequests__r[0].Name; //za.ZipAssignmentRequests__r[0].FirstName__c+' '+za.ZipAssignmentRequests__r[0].LastName__c;
         }
         if (za.Zip_Code_Information__r != null && za.Zip_Code_Information__r.City__c != null) {
            cityState = za.Zip_Code_Information__r.City__c+', '+za.Zip_Code_Information__r.State__c;
         }
      } // ZipWrapper
      
      public Boolean selected{get;set;}
      
      
      public Boolean hasOpenRequests{
         get {return !String.isBlank(openRequestName); }
      }
      /** If there's an open request - the name on the request. */
      public String openRequestName{get;set;}
      
      public Zip_Assignment__c za{get;set;}
      
      public String cityState{get;private set;}
      
   } // class ZipWrapper

   /** A class to match internal and external wholesalers - need both in order to send file (if they both exist)
    */
   public class WholesalerWrapper {
      
      public WholesalerWrapper(String p_zip) {
         zip = p_zip;
      }
      public String zip = null; 
      public Zip_Assignment__c external = null;
      public Zip_Assignment__c internal = null;
   } // class WholesalerWrapper
   
   public Blob csvFileBody{get;set;}
   public string csvAsString{get;set;}
   
   private ZipImport__c zipImport = null;
   
   public Boolean importOkay = true;
   
   public void importCSVFile(){
    importOkay = (String.isNotBlank(csvAsString));
    if (!importOkay) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'No File was passed in!'));
         return;
    }
    // create the import record
    zipImport = new ZipImport__c();
    insert zipImport;
    
    String fileName=csvAsString;
    
    // create the attachment
    Attachment newAtt = new Attachment();
      newAtt.ParentId = zipImport.Id;
      newAtt.Name = fileName; // '_'+UserInfo.getName()+Datetime.now().format('yyyyMMdd');
      newAtt.Body = csvFileBody;
      insert newAtt;
    Integer numberRows = 0;
    
      try {
         csvAsString = csvFileBody.toString(); //EncodingUtil.base64Encode(csvFileBody);
         String[] csvFileLines = csvAsString.split('\n'); 
         numberRows = csvFileLines.size();
         if (numberRows <= 1) {
            zipImport.Notes__c='Including the header row, there should be at least 2 rows in the imported file';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,zipImport.Notes__c));
            importOkay = false;
         } else if (numberRows > 9000) {
            zipImport.Notes__c='There should be no more than 9000 rows in the imported file';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,zipImport.Notes__c));
            importOkay = false;
         } else {          
            ZipImportDetail__c[] zipDetails = new ZipImportDetail__c[]{};
         
            Boolean fileStart = true;
         
         
            for (Integer i=0;i<csvFileLines.size();i++) {
               if (i == 0) {
                  if (!checkHeader(csvFileLines[i])) {
                   importOkay = false;
                     break;
                  }
               } else {
                  ZipImportDetail__c detail = new ZipImportDetail__c(ZipImport__c=zipImport.Id);
                  string[] csvRecordData = csvFileLines[i].split(',');
                  detail.Name = ZipAssignment.checkZipCodeLength(csvRecordData[posZipCode],null);
                  detail.ZipSegmentName__c = csvRecordData[posZipSegment];
                  detail.ZipTerritoryName__c = csvRecordData[posZipTerritory];
                  detail.Sales_Org__c = csvRecordData[posSalesOrg];
                  detail.DistrictNbr__c = csvRecordData[posDistrict];
               
                  zipDetails.add(detail);
               
               }
            
               // insert at regular intervals
               if (zipDetails.size() > 1000) {
                  insert zipDetails;
                  zipDetails.clear();
               }
            } // for (Integer i=0

            if (!zipDetails.isEmpty()) {
               insert zipDetails;
            }
         } // if (csvFileLines.size() <= 1
      } catch (Exception e) {
        importOkay = false;
         zipImport.Notes__c='An error has occured while importing data Please make sure input csv file is correct';
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,zipImport.Notes__c));
         ErrorLog.logError('ManageZipAssignController', 'importCSVFile', 'setting zip detail', zipImport.Id, e, zipImport);
         ErrorLog.checkSave();

      } // try
      
      update zipImport;
      if (importOkay) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO,'File uploaded Successfully. '+(numberRows-1)+' Zip Codes were imported. You will receive an email when processing is complete.'));
      }
      
      csvFileBody = null;
      csvAsString = null;
      
      if (importOkay && !Test.isRunningTest()) {
         ZipInsertBatch.launchBatch();
         //Database.executeBatch(new ZipInsertBatch(), ZipInsertBatch.BATCH_SIZE);
      }
   } // importCSVFile
   
   public static String HEADER_DISTRICT='District';
   public static String HEADER_SALES_ORG='Sales Org';
   public static String HEADER_ZIP_CODE='Zip Code';
   public static String HEADER_ZIP_SEGMENT='Zip Segment';
   public static String HEADER_ZIP_TERRITORY='Zip Territory';
   
   public Integer posDistrict=null;
   public Integer posSalesOrg=null;
   public Integer posZipCode=null;
   public Integer posZipSegment=null;
   public Integer posZipTerritory=null;
   
   public Boolean checkHeader(String headerLine) {
    String[] fileHeaders = headerLine.split(',');
    for (Integer pos=0; pos<fileHeaders.size(); pos++) {
        String checkValue = fileHeaders[pos].trim();
        System.debug('checkHeader header name='+checkValue+'.');
       if (checkValue == HEADER_ZIP_CODE) {
          posZipCode = pos;
       } else if (checkValue == HEADER_ZIP_SEGMENT) {
          posZipSegment = pos;
       } else if (checkValue == HEADER_ZIP_TERRITORY) {
          posZipTerritory = pos;
       } else if (checkValue == HEADER_DISTRICT) {
          posDistrict = pos;
       } else if (checkValue == HEADER_SALES_ORG) {
          posSalesOrg = pos;
       }
    } // for (String header
    
    String notFoundHeaders = '';
    checkHeader(notFoundHeaders,posZipCode,HEADER_ZIP_CODE);
      checkHeader(notFoundHeaders,posDistrict,HEADER_DISTRICT);
      checkHeader(notFoundHeaders,posZipTerritory,HEADER_ZIP_TERRITORY);
      checkHeader(notFoundHeaders,posSalesOrg,HEADER_SALES_ORG);
      checkHeader(notFoundHeaders,posZipSegment,HEADER_ZIP_SEGMENT);

    System.debug('checkHeader posZipCode='+posZipCode+' posZipSegment='+posZipSegment+' posZipTerritory='+posZipTerritory+' posDistrict='+posDistrict+' posSalesOrg='+posSalesOrg);
    
    Boolean okay = String.isBlank(notFoundHeaders);
    if (!okay) {
       zipImport.Notes__c = 'Could not parse header. You are missing the following header(s) from your file: '+notFoundHeaders;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,zipImport.Notes__c));
    }
      return okay;
   } // checkHeader
   
   public String checkHeader(String notFoundHeaders, Integer headerPos, String headerName) {
      if (headerPos == null) {
         if (String.isNotBlank(notFoundHeaders)) {
            notFoundHeaders += ',';
         }
         notFoundHeaders += headerName;
      } // if (headerPos == null
      return notFoundHeaders;
   } // checkHeader
   
   public PageReference goToUploadForm() {
      PageReference pr = Page.ManageZipUploadForm;
      pr.setRedirect(true);
      return pr;
   } // goToUploadForm
   
   public PageReference returnToManageZipForm() {
      PageReference pr = Page.ManageZipAssigns;
      pr.setRedirect(true);
      return pr;
   } // returnToManageZipForm
   
} // class ManageZipAssignController