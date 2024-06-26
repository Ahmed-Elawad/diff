/* 
* Controller for the users to manage CAR and Touchpoint records
*
* History
* ------------------
04/30/2020 Dan Carmen         Created
09/17/2020 Jermaine Stukes	  Added Sales Program Filter
11/21/2022 Reetesh Pandey	  updated filter to check with started and not Cadence Started
10/10/2023 Dan Carmen         Update Cadence filter to use name instead of id.
01/17/2024 Reetesh Pandey	  Updated code for Service User
*/
public without sharing class CadenceManagerController {

   public ManageZipAssignController mzac {get;set;} 
    
   // the profile that can see the 'Reassign Current Step Only' button
   public static String[] CURRENT_STEP_PROFS=Label.CadenceManager_CurrentStepProfiles.split(',');
   public static String[] SECONDARYOWNER_MANAGER_PROFS=Label.CadenceManager_SecondaryMngrProfiles.split(',');
   public static String[] SECONDARYOWNER_USER_PROFS=Label.CadenceManager_SecondaryUsrProfiles.split(',');
   
   public CadenceManagerController(){  
      screenMode=MODE_MAIN;
      User runningUser = UserHelper.getRunningUser();
      reassignCurrentStepOnly = CURRENT_STEP_PROFS.contains(runningUser.Profile.Name);
       isSvcManager = SECONDARYOWNER_MANAGER_PROFS.contains(runningUser.Profile.Name);
       If(!isSvcManager){
           mzac = new ManageZipAssignController(); 
           //selectReassignUser = false;
           districtSelected();
       } else {
           screenMode=MODE_SECONDARY_OWNER;
           managerName = runningUser.Name;
           repOptions = getSalesRep(runningUser.Id,runningUser.Profile.Name ); 
       }
   } // CadenceManagerController
    
   public static String MODE_MAIN='MainEntry';
   public static String MODE_REASSIGN='Reassign';
   public static String MODE_SECONDARY_OWNER='SecondaryOwner';
   public Boolean isSvcManager{get;set;}
   public String managerName{get;set;}
   
   public String filterZipLow{get;set;}
   public String filterZipHigh{get;set;}
   public String filterStartedSelection{get;set;}
    
   public static String FILTER_NONE='None';
   public static String FILTER_STARTED='Only Started';
   public static String FILTER_NOT_STARTED='Only Not Started';
   public SelectOption[] salesProgramOptions{get;set;}
   public String salesProgramSelected{get;set;}
   public String stateSelected{get;set;}
    
   public SelectOption[] filterStartedOptions{
      get {
          if (filterStartedOptions == null) {
             filterStartedSelection = FILTER_NONE;
             filterStartedOptions = new SelectOption[]{};
             filterStartedOptions.add(new SelectOption(FILTER_NONE,FILTER_NONE));
             filterStartedOptions.add(new SelectOption(FILTER_STARTED,FILTER_STARTED));
             filterStartedOptions.add(new SelectOption(FILTER_NOT_STARTED,FILTER_NOT_STARTED));
             
          }
          return filterStartedOptions;
      } // get
      private set;
   } // filterStartedOptions
    
   public String filterCadenceId{get;set;}
   public SelectOption[] filterCadenceOptions{get;set;}
    
    public void clearFilters() {
        filterZipLow=null;
        filterZipHigh=null;
        filterStartedSelection=FILTER_NONE;
        filterCadenceId=FILTER_NONE;
        filterCadenceOptions = null;
        salesProgramSelected=null;
        stateSelected=null;
    } // clearFilters
    
   public void applyFilter() {
      loadRep();
   } // applyFilter
    
   public String screenMode{get;set;}
    
   public void salesOrgSelected() {
      mzac.changeOrgStructure();
      districtSelected(); 
   } // salesOrgSelected

   public void zoneSelected(){
      mzac.setZone(); 
      districtSelected(); 
   } //zoneSelected

   public void reassignZoneSelected(){
      mzac.setReassignZone(); 
      reAssignDistrictSelected(); 
   }//reassignZoneSelected
    
   
   public void districtSelected() {  

      //selectedController = null; 
      //selectedRepId = null; 
      mzac.selectedDistrictOrgUnit = null; 
      mzac.checkDistrictId();
//    displaylistOld = null;
      //displaylist = null; 
 //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'districtSelected mzac.selectedDistrictOrgUnit='+mzac.selectedDistrictOrgUnit));
      if (mzac.selectedDistrictOrgUnit != null) {
          // select the reps
         repOptions = getUsersForDistrict(mzac.selectedDistrictOrgUnit, true, true);
         selectedRepId = (repOptions != null && !repOptions.isEmpty() ? repOptions[0].getValue() : null);
         repSelected();
      }
    
   } // districtSelected
    
   public void reAssignDistrictSelected (){  
      selectedReassignRepId = null; 
      reassignRepOptions = null;
      //mzac.selectedReassignDistrictOrgUnit = null;
      //selectedReassignDistrictId
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'selectedReassignDistrictId='+mzac.selectedReassignDistrictId));
      mzac.checkReassignDistrictId();
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'districtSelected mzac.selectedDistrictOrgUnit='+mzac.selectedDistrictOrgUnit));
      if (mzac.selectedReassignDistrictOrgUnit != null) {
      // select the reps
         reassignRepOptions= getUsersForDistrict(mzac.selectedReassignDistrictOrgUnit, false, true); 
         selectedReassignRepId = (reassignRepOptions != null && !reassignRepOptions.isEmpty() ? reassignRepOptions[0].getValue() : null);
      }
   } // districtSelected 
    
   public SelectOption[] getUsersForDistrict(Org_Unit__c district, Boolean includeInactive, Boolean excludeSelected) {
      SelectOption[] theseOptions = new SelectOption[]{};
      searchPerformed = false;
      // get the users for a districts. If includeInactive is true, return inactive users who have open CAR records.
      Id[] roleIds = new Id[]{};
      if (district != null) {
          if (district.UserRoleId__c != null) {
              roleIds.add(district.UserRoleId__c);
          }
          if (district.RepUserRoleId__c != null) {
              roleIds.add(district.RepUserRoleId__c);
          }
      }
      if (!roleIds.isEmpty()) {
         User[] users = [Select Id, Name, FirstName, LastName, IsActive, HR_Person_Id__c, Job_Name__c, Title, UserRoleId, UserRole.Id, UserRole.Name
                               ,Profile.Name
                           From User
                          Where UserRoleId in :roleIds
                            and Profile.UserLicense.Name='Salesforce'];
         User[] inactiveUsers = new User[]{};
         User[] usersToUse = new User[]{};
         Id excludeId = null;
         if (excludeSelected) {
            try {
                excludeId = (Id)selectedRepId;
            } catch (Exception e) {}
         } // if (excludeSelected
         // so when we're reassigning a rep, we don't give the option to reassign to the same person
         for (User usr : users) {
            if (excludeId == null || excludeId != usr.Id) {
               if (usr.isActive) {
                  usersToUse.add(usr);
               } else {
                  inactiveUsers.add(usr);
               }
                 
            }
         } // for (User usr : users
         if (includeInactive && !inactiveUsers.isEmpty()) {
            User[] otherUsers = checkInactiveUsers(inactiveUsers);
             if (!otherUsers.isEmpty()) {
                usersToUse.addAll(otherUsers);
             }
         }
         // sort the results
         if (!usersToUse.isEmpty()) {
            Map<String,User> sortMap = new Map<String,User>();
            for (User usr : usersToUse) {
               String key = usr.LastName+usr.FirstName+usr.HR_Person_Id__c;
               sortMap.put(key,usr);
            }
            String[] sortList = new String[]{};
            sortList.addAll(sortMap.keySet());
            sortList.sort();
            for (String sortKey : sortList) {
               User usr = sortMap.get(sortKey);
               if (usr != null) {
                  String label = usr.FirstName+' '+usr.LastName+(!usr.IsActive ? '-Inactive' : '');
                  theseOptions.add(new SelectOption(usr.Id, label));
               }
            }
         } // if (!usersToUse.isEmpty
      } // if (!roleIds.isEmpty
      return theseOptions;
   } // getUsersForDistrict
    
   public Boolean hasRepOptions{ get {return (repOptions != null && !repOptions.isEmpty());}}
   public Boolean hasReassignRepOptions{ get {return (reassignRepOptions != null && !reassignRepOptions.isEmpty());}}
   
   // which rep is selected? 
   public String selectedRepId {get;set;}
   // all of the users to select from
   public List<SelectOption> repOptions{get;set;}
   // which rep is selected? 
   public String selectedReassignRepId {get;set;}
   // all of the users to select from
   public List<SelectOption> reassignRepOptions{get;set;}
 
   public User[] checkInactiveUsers(User[] usersToCheck) {
      User[] usersToUse = new User[]{};
      // to get the user ids to query the touchpoints
      Map<Id,User> userMap = new Map<Id,User>(usersToCheck);
      // see if the users have any open touchpoints
      AggregateResult[] results = [Select OwnerId, count(Id) 
                                     From Cadence_Touchpoint__c
                                    Where OwnerId in :userMap.keySet()
                                      and IsLatestTouchpoint__c = true
                                      and Status__c='Open'
                                      and CarRecord__r.Closed__c = false
                                    group by OwnerId];
      for (AggregateResult result : results) {
         Id ownerId = (Id)result.get('OwnerId');
         User usr = userMap.get(ownerId);
         if (usr != null) {
            usersToUse.add(usr);
         }
      } // for (AggregateResult result
      return usersToUse;
   } // checkInactiveUsers

    public Boolean selectAll {get;set;}
    
    public Boolean searchPerformed{get; set;}
    public Boolean hasOpenTouchpoints{ get {return (displayList != null && !displayList.isEmpty());}}
       
    //public TpWrap[] displayList2{get;set;}
    public class TpWrap {
       public TpWrap(Cadence_Touchpoint__c p_tp) {
          selected=false;
          tp=p_tp;
          car=tp.CarRecord__r;
          step=tp.Cadence_Touchpoint_Step__r;
       } // TpWrap
       public Boolean selected{get;set;}
       public Cadence_Touchpoint__c tp{get;set;}
       public Cadence_Assignment_Record__c car{get;set;}
       public Cadence_Step__c step{get;set;}
    } // class TpWrap

   // the query used to select the touchpoints. Static so we can add filters
   public static String TP_QUERY = 'Select Id, Name, OwnerId, Owner.Name, CreatedDate '+
                                             ' ,Cadence_Touchpoint_Step__r.Name '+
                                             ' ,Cadence_Touchpoint_Step__r.Step_Number__c '+
                                             ' ,CarRecord__r.Id'+
                                             ' ,CarRecord__r.Activity_Log__c '+
                                             ' ,CarRecord__r.Cadence__r.Name '+
                                             ' ,CarRecord__r.Cadence_Owner__c '+
                                             ' ,CarRecord__r.Started__c '+
                                             ' ,CarRecord__r.CompanyName__c '+
                                             ' ,CarRecord__r.OwnerId '+
                                             ' ,CarRecord__r.Owner.Name '+
                                             ' ,CarRecord__r.ParentZipCode__c '+
                                             ' ,CarRecord__r.Sales_Program__c '+
                                             ' ,CarRecord__r.SalesProgramEndDate__c '+
       										 ' ,CarRecord__r.State__c '+
                                             ' ,Due_Date__c '+
                                             ' ,Past_Due_Date__c '+
                                             ' ,Status__c '+
                                         ' From Cadence_Touchpoint__c '+
                                        ' Where IsLatestTouchpoint__c = true '+
                                          ' and Status__c=\'Open\'  ';
    
   public void repSelected() {
      selectedMap.clear();
      clearFilters();
      System.debug('repSelected selectedRepId='+selectedRepId);
      if (selectedRepId != null) {
         //checkForTouchpoints('00530000000xxTA');
         checkForTouchpoints(selectedRepId);
      }
  } // repSelected
    
    public void loadRep() {
      if (selectedRepId != null) {
         //checkForTouchpoints('00530000000xxTA');
         checkForTouchpoints(selectedRepId);
      }
    } // loadRep
    
   public static Integer RECS_PER_PAGE=Integer.valueOf(Label.CadenceManagerController_RecsPerPage);
    
   // the list of available touchpoints
   public ApexPages.StandardSetController tpController{get;set;}

    public void checkForTouchpoints(Id p_ownerId) {
        displayList = null;
        Id ownerId = p_ownerId;
        String zipLow = filterZipLow;
        String zipHigh = filterZipHigh;
        String filtCadenceId = filterCadenceId;
        String salesProgramValue = salesProgramSelected;
        String stateValue = stateSelected;
        //string zipValue
        System.debug('checkForTouchpoints ownerId='+ownerId+' zipLow='+zipLow+' zipHigh='+zipHigh+' filtCadenceId='+filtCadenceId+' filterStartedSelection='+filterStartedSelection+
                     ' salesProgramSelected='+salesProgramValue+' stateSelected='+stateValue);
        Boolean filterStarted = ((filterStartedSelection != null && filterStartedSelection != FILTER_NONE) 
                                 ? (filterStartedSelection == FILTER_STARTED)
                                 : (Boolean)null);
        String tpQuery = TP_QUERY+' and OwnerId=:ownerId ';
        if (String.isNotBlank(filtCadenceId) && filtCadenceId != FILTER_NONE) {
            tpQuery += ' and CarRecord__r.Cadence__r.Name = :filtCadenceId ';
        }
        if (String.isNotBlank(salesProgramValue) && salesProgramValue != FILTER_NONE) {
            tpQuery += ' and CarRecord__r.Sales_Program__c = :salesProgramValue ';
        }
        if (String.isNotBlank(stateValue) && stateValue != FILTER_NONE) {
            tpQuery += ' and CarRecord__r.State__c = :stateValue ';
        }
        if (String.isNotBlank(zipLow)) {
            tpQuery += ' and CarRecord__r.ParentZipCode__c ';
            if (String.isNotBlank(zipHigh)) {
                tpQuery += ' >= :zipLow and CarRecord__r.ParentZipCode__c <= :zipHigh ';
            } else {
                tpQuery += ' = :zipLow ';
            }
        } // if (String.isNotBlank(zipLow
        if (filterStarted != null) {
            tpQuery += ' and CarRecord__r.Started__c='+filterStarted;
        }
        System.debug('checkForTouchpoints tpQuery='+tpQuery);
        tpController =  new ApexPages.StandardSetController(Database.getQueryLocator(tpQuery));
        tpController.setPageSize(RECS_PER_PAGE); 
        Set<String> cadenceNameSet = new Set<String>();
        String[] salesPrograms = new String[]{};
            
            // get the unique lists of cadences available to the user
        AggregateResult[] results = [Select CarRecord__r.Cadence__r.Name cadenceName, CarRecord__r.Sales_Program__c salesProgram, count(Id) nbrRecs 
                                     From Cadence_Touchpoint__c
                                    Where IsLatestTouchpoint__c = true
                                      and Status__c='Open'
                                      and OwnerId=:ownerId
                                     group by CarRecord__r.Cadence__r.Name, CarRecord__r.Sales_Program__c
                                    order by CarRecord__r.Cadence__r.Name];

        
        System.debug('checkForTouchpoints aggregate results='+results.size());
        filterCadenceOptions = new SelectOption[]{};
        filterCadenceOptions.add(new SelectOption(FILTER_NONE,FILTER_NONE));
        filtCadenceId = FILTER_NONE;
        for (AggregateResult result : results) {
            String cadenceName = (String)result.get('cadenceName');
            String salesProgram = (String)result.get('salesProgram');
            if (!cadenceNameSet.contains(cadenceName)) {
                filterCadenceOptions.add(new SelectOption(cadenceName,cadenceName));
                cadenceNameSet.add(cadenceName);
            }
            if (String.isNotBlank(salesProgram) && !salesPrograms.contains(salesProgram)) {
                salesPrograms.add(salesProgram);
            }
            
        }
        salesProgramOptions = new SelectOption[]{};
        salesProgramOptions.add(new SelectOption(FILTER_NONE,FILTER_NONE));
        if (!salesPrograms.isEmpty()) {
            salesPrograms.sort();
            for (String salesProgram : salesPrograms) {
                salesProgramOptions.add(new SelectOption(salesProgram,salesProgram));
            }
        }
        
    } // checkForTouchpoints
   
   
   public TpWrap[] displayList{
      get {
         if (displayList == null && tpController != null) {
            displayList = new TpWrap[]{};
            for (SObject rec : tpController.getRecords()) {
               TpWrap wrap = new TpWrap((Cadence_Touchpoint__c)rec);
               displayList.add(wrap);
            }
         }
         return displayList;
     }
     private set;}
    
   private Map<Id,TpWrap> selectedMap = new Map<Id,TpWrap>();
   public void addToSelectMap(){
      if (displayList == null) {
         return;
      }
      for (TpWrap wrap : displaylist) {
         if (wrap.selected){      
            selectedMap.put(wrap.tp.id, wrap); 
         } else {
            selectedMap.remove(wrap.tp.id);
         } //else
      }//for 
   } //addToSelectMap 

   // Goto the next page of records. 
   public void next() {
      addToSelectMap();
      displaylist = null;     
      tpController.next();
   } // next

   // Goto the previous page of records. 
   public void previous() {
      addToSelectMap();  
      displaylist = null;
      tpController.previous();  
   } // previous    

   // Goto the next page of records.
   public void firstPage() {
      addToSelectMap();     
      displaylist = null;
      tpController.first();
   } // next

   // Goto the previous page of records. 
   public void lastPage() {
      addToSelectMap();       
      displaylist = null;
      tpController.last();  
   } // previous    

   // The total number of pages available.
   public Integer numOfPages {
      get {
         if (numOfPages == null) {
            
            numOfPages = 1;
            if (tpController != null) {
               decimal result = Decimal.valueOf(tpController.getResultSize()) / Decimal.valueOf(tpController.getPageSize());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
               numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
            }
         } // if (numOfPages
         return numOfPages;
      } // get
      private set;
   } // numOfPages
 
    public static String REASSIGN_CARS='ReassignCars';
    public static String REASSIGN_TPS='ReassignTPs';
    
    public Boolean reassignCurrentStepOnly{get;private set;}
    
    public String reassignMode{get;set;}
    
    public PageReference reassignCARs() {
        return verifyStartReassign(REASSIGN_CARS);
    }
    
    public PageReference reassignTPs() {
        return verifyStartReassign(REASSIGN_TPS);
    }
    
    public PageReference verifyStartReassign(String p_reassignMode) {
      addToSelectMap();
      selectedList = null;
      if (selectedMap.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You must select at least 1 record to continue!'));
         return null;
      }
      reassignMode=p_reassignMode;
      screenMode = MODE_REASSIGN;
      If(!isSvcManager){
         mzac.setReassignOrgs();
         //reassignZoneSelected();
         reAssignDistrictSelected();
        } else {
            reassignRepOptions= getSalesRep(UserHelper.getRunningUser().Id,UserHelper.getRunningUser().Profile.Name ) ; 
            selectedReassignRepId = (reassignRepOptions != null && !reassignRepOptions.isEmpty() ? reassignRepOptions[0].getValue() : null);            
        }
        return null;  
   } // verifyStartReassign
    
   public PageReference cancelReassign() {
      if(!isSvcManager){
      screenMode = MODE_MAIN;
      } else { screenMode=MODE_SECONDARY_OWNER; }
      repSelected();
      return null;
   } // cancelReassign
    
   public PageReference performReassign() {
      if (String.isBlank(selectedReassignRepId)) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'A Rep Must be selected before you can continue!'));
         return null;
      }
      // verify that a rep was selected
      Id newOwnerId = null;
      try {
         newOwnerId = (Id)selectedReassignRepId;
      } catch (Exception e) {
         System.debug('performReassign exception: '+e.getMessage());
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There is an error with the rep chosen: '+e.getMessage()));
         return null;
      }
      String newOwnerName = newOwnerId;
      for (SelectOption so : reassignRepOptions) {
          if (so.getValue() == selectedReassignRepId) {
             newOwnerName = so.getLabel();
          }
      }
      
      Cadence_Touchpoint__c[] updateTPs = new Cadence_Touchpoint__c[]{};
      Cadence_Assignment_Record__c[] updateCARs = new Cadence_Assignment_Record__c[]{};
      String ownerType = 'TP'+(reassignMode == REASSIGN_CARS ? '/CAR' : '');
      for (TpWrap wrap : selectedList) {
         String notes='CadenceManager changed '+ownerType+' owner from '+wrap.car.Owner.Name+' to '+newOwnerName;
         wrap.tp.OwnerId = newOwnerId;
         if (reassignMode == REASSIGN_CARS && isSvcManager) {
            wrap.car.Secondary_User__c = newOwnerId;
         }
          else if (reassignMode == REASSIGN_CARS) {
            wrap.car.OwnerId = newOwnerId;
            wrap.car.Cadence_Owner__c = newOwnerId;
         }
         StringHelper.addNotesToField(wrap.car, 'Activity_Log__c', WorkQueueController.ACTIVITY_LOG_SIZE, notes, true);
         updateTPs.add(wrap.tp);
         updateCARs.add(wrap.car);
      } // for (TpWrap wrap : selectedList
      CadenceHelper.SKIP_TRIGGERS=true;
      try {
         update updateTPs;
         update updateCARs;
      } catch (Exception e) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There is an error moving the touchpoints! '+e.getMessage()));
         return null;
      }
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully moved '+updateCARs.size()+' touchpoints.'));
      return cancelReassign();
   } // performReassign
    
    public TpWrap[] selectedList{
        get {
           if (selectedList == null && selectedMap != null && !selectedMap.isEmpty()) {
              selectedList = new TpWrap[]{};
              for (TpWrap wrap : selectedMap.values()) {
                 selectedList.add(wrap);
              }
           }
           return selectedList;
        } // get
        private set;
    } // selectedList
    public List<SelectOption> getSalesRep(Id usrId ,String prfleName) {
        System.debug('usrId >>'+usrId +'  prfleName >>' +prfleName );
        SelectOption[] reps = new SelectOption[]{};         
		UserHelper uh = new UserHelper();
        Set<String> profileSet = new Set<String>();
        profileSet.add(prfleName);
        profileSet.addAll(SECONDARYOWNER_MANAGER_PROFS);
        profileSet.addAll(SECONDARYOWNER_USER_PROFS);           
        Map<Id,User> idUserMap = uh.getRoleSubordinateSaleUsersMap(usrId,profileSet); 
        String label = '';        
        List<User> repList = idUserMap.Values();
        repList.sort();
        reps.add(new SelectOption(usrId, managerName));
		for(User rep :repList){			
            if(rep.isActive) {
                reps.add(new SelectOption(rep.Id, rep.Name));              	
            }
		}         
        selectedRepId = (reps != null && !reps.isEmpty() ? reps[0].getValue() : null);
		profileSet.clear();         
        return reps;        
    }
} // class CadenceManagerController