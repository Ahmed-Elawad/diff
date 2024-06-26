/* 
 * The methods used for NSS Administration
 *
 * History
 * -------
 * 11/06/2013 Dan Carmen       Created
   07/08/2015 Cindy Freeman    Added Segment__c to create new logic
   08/12/2015 Dan Carmen       Added supervisor into the assign to list.
   10/31/2018 Dan Carmen       Change for View State error
   12/27/2018 Dan Carmen       Changes for DialSource - qbdialer__Callback_Date_Time__c replacement
   02/20/2019 Josh Cartwright	changed the order callDisposition evaluates 
   11/14/2019 Dan Carmen       Remove qbdialer references
   01/29/2020 Dan Carmen       Adjustments to code so it will pass tests
 
 */
public without sharing class NSSAdministrationController {

   /** The person who entered the form. */
   public User runningUser{get;set;}
   
   /** Is the user a system administrator. */
   public Boolean isSystemAdmin{get;private set;}
   
   /** Does the running user have access to the form? */
   public Boolean hasFormAccess{get;private set;}
   
   public Boolean isSupervisor{get;private set;}
   
   /** Are we showing the verify screen? */
   public Boolean showVerify{get;private set;}
   
   /** Are we showing the result screen? */
   public Boolean showResults{get;private set;}
   
   /** The tracking object for the transfer. */
   public NSSTransferLog__c transferLog{get;set;}
   
   /** Default controller. 
       Access is only for System Administrator or someone in the NSS Hierarchy (NSS Director and below, has children)
    */
   public NSSAdministrationController() {
      init();
   } // NSSAdministrationController
   
   public void init() {
      /*
      runningUser = [Select Id, Name, HR_Person_Id__c, Sales_Org__c
                           ,Job_Name__c
                           ,Profile.Id
                           ,Profile.Name
                           ,UserRole.Id
                           ,UserRole.Name
                           ,UserRole.ParentRoleId
                           ,Title 
                       from User 
                      where Id=:UserInfo.getUserId()];
                    */
      runningUser = UserHelper.getRunningUser();
                      
      isSystemAdmin = UserHelper.isSystemAdmin(runningUser);
      isSupervisor = false;
      
      hasFormAccess = isSystemAdmin;
      showVerify = false;
      showResults = false;
      
      if (!hasFormAccess) {
         // check if the user is part of the NSS hierarchy and has children
         hasFormAccess = checkFormAccess(runningUser);
      } // if (!hasFormAccess
      System.debug('init hasFormAccess='+hasFormAccess);
      
      setFormAccess(!hasFormAccess, hasFormAccess, false, false);
      if (hasFormAccess) {
        setupUser();
      } // if (hasFormAccess
   } // init
   
   public Boolean showNoAccessBlock{get;private set;}
   public Boolean showRecordSelectionBlock{get; private set;}
   public Boolean showVerifyTransferBlock{get; private set;}
   public Boolean showVerifyEndOwnerBlock{get; private set;}
   
   public void setFormAccess(Boolean noAccess, Boolean recordSelection, Boolean verifyTransfer, Boolean verifyEndOwner) {
    showNoAccessBlock = noAccess;
    showRecordSelectionBlock = recordSelection;
    showVerifyTransferBlock = verifyTransfer;
    showVerifyEndOwnerBlock = verifyEndOwner;
   } // setFormAccess
   
   public void setupUser() {
      isSupervisor = runningUser.Job_Name__c == UserHelper.JOB_NSS_SUPER;
      setupTransferLog();
      
      if (!isSupervisor) {
         setAvailableSupervisorOptions(runningUser);
      } else {
         // this is a supervisor
         availableSupervisorMap.put(runningUser.Id,runningUser);
         selectedSupervisorFrom = runningUser.Id;
         supervisorFromChanged();
      }
   } // setupUser
   
   public void setupTransferLog() {
      transferLog = new NSSTransferLog__c();
      transferLog.NbrOfCallbacks__c = 0;
      transferLog.NbrOfLeads__c = 0;
      transferLog.NbrOrphanCallbacks__c = 0;
      transferLog.NbrOfOwnerRecs__c = 0;
      transferLog.NbrOfAccts__c = 0; 
      transferLog.Notes__c = 'setupTransferLog; ';
   } // setupTransferLog
   
   /** Does the user have access to the form?
    */
   public Boolean checkFormAccess(User u) {
    // for now just make sure the role name starts with NSS
      Boolean hasAccess = (u.UserRole.Name.startsWith('NSS') && hasHierarchyChildren(u));
      return hasAccess;
   } // checkFormAccess
   
   /** Does the user have children in the hierarchy? Must have children to enter the form.
    */
   public Boolean hasHierarchyChildren(User u) {
      Boolean hasChildren = ([Select count() from UserRole where ParentRoleId = :u.UserRole.Id limit 1] > 0);
      return hasChildren;
   } // hasHierarchyChildren
   
   /** Are there multiple supervisors to choose from? If there's only 1 we don't need to display anything. */
   public Boolean hasSupervisorOptions{
      get {return (supervisorOptions != null && supervisorOptions.size()>1); }
   } // hasSupervisorOptions
   
   // The available supervisors to select from. 
   public List<SelectOption> supervisorOptions{get;set;}
   
   // Which supervisor is selected. 
   public String selectedSupervisorFrom{get;set;}
   
   /** If you're at a higher level than a supervisor, the available supervisors under you.
    */
   //public User[] availableSupervisors {get;set;}
   
   public Map<Id,User> availableSupervisorMap = new Map<Id,User>();
   
   public static String NONE='None';
   /** The name of the profiles for NSS supervisors. */
   public static Set<String> superProfNames = UserHelper.NSS_MGR_PROF_SET;
   
   public Boolean setAvailableSupervisorOptions(User p_u) {
      Boolean okay = true;
      
      //availableSupervisors = new User[]{};
      
      supervisorOptions = new List<SelectOption>();
      supervisorOptions.add(new SelectOption(NONE,'--Select a Supervisor--'));
      selectedSupervisorFrom = NONE;
      
      // select only one user per role. Preference is active over inactive
      Map<Id,User> userByRoleMap = new Map<Id,User>();
      Map<Id,User[]> userByRoleMap2 = new Map<Id,User[]>();
      
      Map<Id,User> userMap = new UserHelper().getRoleSubordinateSaleUsersMap(p_u.Id, superProfNames);
      System.debug('setAvailableSupervisorOptions userMap='+userMap.size());
      for (User u : userMap.values()) {
        String jobName = UserHelper.getRoleType(u.UserRole.Name);
        if (jobName != null && jobName == UserHelper.JOB_NSS_SUPER) {
           checkAddToMap(u, userByRoleMap2);
           User userInMap = userByRoleMap.get(u.UserRole.Id);
           System.debug('u='+u.Name+' userInMap='+(userInMap == null ? 'No User' : userInMap.Name));
           if (userInMap == null || (!userInMap.IsActive && u.IsActive)) {
              userByRoleMap.put(u.UserRole.Id,u);
           }
           
        //if (u.Job_Name__c == UserHelper.JOB_NSS_SUPER) {
           //availableSupervisors.add(u);
           //availableSupervisorMap.put(u.Id,u);
           //supervisorOptions.add(new SelectOption(u.Id,u.Name+(u.Title != null ? '-'+u.Title : '')));
        } // f (jobName != null
      } // for (User u : userMap
      
      if (!userByRoleMap.isEmpty()) {
         Map<String,User> userByNameMap = new Map<String,User>();
          for (User[] usrs : userByRoleMap2.values()) {
              for (User u : usrs) {
                 userByNameMap.put(u.LastName+u.FirstName, u);
              }
          } // for (User[] usrs : userByRoleMap2
         //for (User u : userByRoleMap.values()) {
         //   userByNameMap.put(u.LastName+u.FirstName, u);
         //}
         List<String> nameList = new List<String>();
         nameList.addAll(userByNameMap.keySet());
         nameList.sort();
         
         for (String key : nameList) {
            User u = userByNameMap.get(key);
            if (u != null) {
               //availableSupervisors.add(u);
               availableSupervisorMap.put(u.Id,u);
               supervisorOptions.add(new SelectOption(u.Id,u.Name+(u.Title != null ? '-'+u.Title : '')));
            }
         } // for (String key : nameList
      } // if (!userByRoleMap.isEmpty
      return okay;
   } // setAvailableSupervisorOptions
   
    public void checkAddToMap(User usr, Map<Id,User[]> userByRoleMap2) {
       User[] usrsInMap = userByRoleMap2.get(usr.UserRole.Id);
        if (usrsInMap == null) {
            usrsInMap = new User[]{};
            usrsInMap.add(usr);
        } else if (usr.IsActive) {
            User[] newList = new User[]{usr};
            // only add active users
            for (User checkUsr : usrsInMap) {
                if (checkUsr.isActive) {
                   newList.add(checkUsr);
                }  
            } // for (User checkUsr : usrsInMap
            usrsInMap = newList;
        }
        userByRoleMap2.put(usr.UserRole.Id, usrsInMap);
    } // checkAddToMap
   
   /** When the picklist for the supervisor changes. */
   public void supervisorFromChanged() {
      transferFromOptions = null;
      initOwnerVars();
      System.debug('supervisorFromChanged selectedSupervisorFrom='+selectedSupervisorFrom);
      if (String.isNotBlank(selectedSupervisorFrom) && selectedSupervisorFrom != NONE) {
        User supervisor = availableSupervisorMap.get(selectedSupervisorFrom);
        System.debug('supervisorFromChanged found supervisor='+(supervisor != null));
        if (supervisor != null) {
           setTransferFromUsers(supervisor);
        }
      }
      
   } // supervisorFromChanged
   
   /** Which supervisor is selected. */
   public String selectedSupervisorTo{get;set;}

   public User supervisorTo{get;set;}

   /** When the picklist for the supervisor changes. */
   public void supervisorToChanged() {
      transferToOptions = null;
      selectedTransferTo = new String[]{};

      if (String.isNotBlank(selectedSupervisorTo) && selectedSupervisorTo != NONE) {
         supervisorTo = availableSupervisorMap.get(selectedSupervisorTo);
         if (supervisorTo != null) {
            setTransferToUsers(supervisorTo);
         } else {
            System.debug('supervisorToChanged supervisor not found!');
         }
      }
      
   } // supervisorFromChanged

   //public User[] availableNSRs{get;set;}
   
   public Map<Id,User> transferUserMap = new Map<Id,User>();
   
   /** Are there NSRs available for selection? */
   public Boolean hasTransferFromOptions{
      get {return (transferFromOptions != null && !transferFromOptions.isEmpty()); }
   }
   
   /** The available NSRs to choose from. */
   public List<SelectOption> transferFromOptions{get;set;}
   
   /** Are there NSRs available for selection? */
   public Boolean hasTransferToOptions{
      get {return (transferToOptions != null && !transferToOptions.isEmpty()); }
   }

   public String selectedTransferFrom{get;set;}
   /** The available people to transfer to. */
   public List<SelectOption> transferToOptions{get;set;}

   public String[] selectedTransferTo{get;set;}
   
   /** Was a user selected for transferring from? */
   public Boolean selectedFromSet{
      get {return (String.isNotBlank(selectedTransferFrom) && selectedTransferFrom != NONE); }
   } // selectedFromSet
   
   /** Was a user selected for transferring to? */
   public Boolean selectedToSet{
      get {return (selectedTransferTo != null && !selectedTransferTo.isEmpty()); }
   } // selectedToSet
   
   
   /** The transfer from selection changed. */
   public void transferFromChanged() {
      initOwnerVars();
      System.debug('transferFromChanged selectedFromSet='+selectedFromSet+' selectedTransferFrom='+selectedTransferFrom);
      // see if the selected user has any open ownership records
      if (selectedFromSet) {
         User usr = transferUserMap.get(selectedTransferFrom);
         System.debug('transferFromChanged usr='+usr);
         if (usr != null) {
            transferLog.TransferFrom__c = usr.Id;
            if (getOwnership(usr)) {
               // if records are retrieved, set the transfer to variables.
               // default the supervisor to the from supervisor
               selectedSupervisorTo = selectedSupervisorFrom;
               supervisorToChanged();
            }
         }
      } // if (String.isNotBlank
      // if yes, set transferTo options
   } // transferFromChanged
   
   /** The transfer to selection changed. */
   //public void transferToChanged() {
    
   //} // transferToChanged

   public void initOwnerVars() {
      displayList = null;
      ownershipRecs = null;
      numOfPages = null;
      selectAllOption = false;
      transferToOptions = null;
      //transferFromOptions = null;
      selectAllTransferTo = false;
   } // initOwnerVars
   
   /** When a supervisor changes, reset the list of users. */
   public Boolean setTransferFromUsers(User parentUser) {
      setupFilterOptions();
      transferFromOptions = getUsers(parentUser,false,null);
      selectedTransferFrom = NONE;
      return true;
   } // setTransferFromUsers
   
   /** When a supervisor changes, reset the list of users. */
   public Boolean setTransferToUsers(User parentUser) {
      transferToOptions = getUsers(parentUser,true,selectedTransferFrom);
      selectedTransferTo = new String[]{};
      return true;
   } // setTransferToUsers
   
   /** Are we selecting all of the users or selected users. */
   public String transferToAllOrSelected{get;set;}
   
   //public void allOrSelectedChanged() {
    
   //}
   
   /** Get all of the NSRs who report to the passed in user (based on Role Hierarchy)
       @param parentUser - the supervisor to start with
       @param selectingTransferTo - Are we performing the query to transfer to? If yes, only active, do not clear user map.
       @param excludeId - is there a user we need to exclude?
    */
   public List<SelectOption> getUsers(User parentUser, Boolean selectingTransferTo, String excludeId) {
      System.debug('getUsers parentUser='+parentUser.Id+' selectingTransferTo='+selectingTransferTo);
      List<SelectOption> userOptions = new List<SelectOption>();
      Set<Id> inactiveIds = new Set<Id>();
      // when you're selecting the users you're transferring records from
      if (!selectingTransferTo) {
         transferUserMap.clear();
         // find any inactive users that have open ownership records, or a supervisor
         AggregateResult[] inactiveResults = [Select NSR_Name__c, count(Id) nbr_recs 
                                                from Prospect_Ownership__c 
                                               where EndDate__c = null 
                                                 and ((NSR_Name__r.IsActive = false 
                                                      and NSR_Name__r.UserRole.ParentRoleId=:parentUser.UserRoleId)
                                                      or NSR_Name__r.UserRoleId = :parentUser.UserRoleId)
                                                 and Ownership_Status__c in :allOwnershipStatuses 
                                               group by NSR_Name__c];
         System.debug('getUsers inactiveResults='+inactiveResults.size());
         if (!inactiveResults.isEmpty()) {
            for (AggregateResult ar : inactiveResults) {
               inactiveIds.add((Id)ar.get('NSR_Name__c'));
            } // for AggregateResult
         } // if (!inactiveResult
         /*
            Select NSR_Name__c, count(Id) nbr_recs from Prospect_Ownership__c where NSR_Name__r.IsActive = false and NSR_Name__r.UserRole.ParentRoleId=:parentUser.UserRoleId group by NSR_Name__c 
            Select NSR_Name__c, count(Id) nbr_recs from Prospect_Ownership__c where NSR_Name__r.IsActive = true and NSR_Name__r.UserRole.ParentRoleId='00ES0000000Sfwn' group by NSR_Name__c
            
            NSS Outbound Supervisor 1.2=00ES0000000Sfwn
            */
      }

      if (!selectingTransferTo) {
         userOptions.add(new SelectOption(NONE,'--Select a User--'));
      }
      
      /*
      if (selectingTransferTo) {
        User supervisor = availableSupervisorMap.get(selectedSupervisorTo);
        String toName ='';
        if (supervisor != null) {
            toName = ' to '+supervisor.Name;
        } // if (supervisor != null
         userOptions.add(new SelectOption(ALL,'All Reports'+toName));
         //userOptions.add(new SelectOption(SELECTED,'Selected Reports'));
      }
      */
      
      String whereClause = 'where ((UserRole.ParentRoleId=\''+parentUser.UserRoleId+'\' ';
      // only select NSRs
      whereClause += ' and Job_Name__c=\''+UserHelper.JOB_NSR+'\'';
      whereClause += ' and IsActive=true) ';
      // if there are inactive ids we want to include those users
      if (!inactiveIds.isEmpty()) {
         String idClause = '';
         for (Id inactiveId : inactiveIds) {
            idClause += (String.isNotBlank(idClause) ? ',' : '') + '\''+inactiveId+'\'';
         }
         whereClause += ' or Id in ('+idClause+')';
      } // if (!inactiveIds
      
      // always include the supervisor in the transfer to options.
      if (selectingTransferTo) {
         whereClause += ' or UserRoleId=\''+parentUser.UserRoleId+'\' ';
      } // if (selectingTransferTo
      
      whereClause += ')';
      if (String.isNotBlank(excludeId)) {
         whereClause += ' and Id != \''+excludeId+'\'';
      }
      whereClause +=' order by LastName, FirstName ';
      User[] users = new UserHelper().getUsers(whereClause);
      System.debug('getUsers users='+users.size());
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'getUsers users='+users.size()+' parentUser='+parentUser+' whereClause='+whereClause));
      for (User usr : users) {
         // store the users in a map for easy reference
         System.debug('getUsers usrId='+usr.Id+' usr='+usr.Name);
         transferUserMap.put(usr.Id,usr);
         userOptions.add(new SelectOption(usr.Id,usr.Name+(!usr.IsActive ? '-INACTIVE' : '')));
      } // for (User usr
      System.debug('getUsers transferUserMap='+transferUserMap.size());
      return userOptions;
   } // getUsers
   
   /** All of the ownership settings that can be selected for this form - based on the custom setting information. */
   private Set<String> allOwnershipStatuses = new Set<String>();

   private Set<String> allNssTeamStatuses = new Set<String>();
   
   /** The available filter options. */
   public List<SelectOption> filterOptions{get;private set;}

   public List<SelectOption> nssTeamOptions{get;private set;}
   
   /** The selected filter option. */
   public String selectedFilterOption{get;set;}
   public String selectedNssTeam{get;set;}
      
   public static String ALL='All';
   //public static String SELECTED='Selected';
      
   public void setupFilterOptions() {
      selectedFilterOption = ALL;
      selectedNssTeam = ALL;

    // this only needs to be done once
    if (filterOptions == null) {
         filterOptions = new List<SelectOption>();
         filterOptions.add(new SelectOption(ALL,ALL));
         allOwnershipStatuses.clear();
      
         for (LifeOfLeadSettings__c lols : LifeOfLeadSettings__c.getAll().values()) {
            if (lols.IsFilterable__c && !allOwnershipStatuses.contains(lols.OwnershipStage__c)) {
               filterOptions.add(new SelectOption(lols.OwnershipStage__c, lols.OwnershipStage__c));
               allOwnershipStatuses.add(lols.OwnershipStage__c);
            }
         } // for (LifeOfLeadSettings__c lols
        
    } // if (filterOptions == null
      
      if (nssTeamOptions == null) {
         allNssTeamStatuses.clear();
         nssTeamOptions = new List<SelectOption>();
         nssTeamOptions.add(new SelectOption(ALL,ALL));
         Schema.DescribeFieldResult f = Schema.sObjectType.Prospect_Ownership__c.fields.NSS_Team__c;
         List<Schema.PicklistEntry> picklistValues = f.getPicklistValues();
      
         for (Schema.PicklistEntry pe : picklistValues) {
            allNssTeamStatuses.add(pe.getValue());
            nssTeamOptions.add(new SelectOption(pe.getValue(),pe.getValue()));
         }

      } // if (nssTeamOptions == null
      
   } // setupFilterOptions
   
   /** When the filter changes.
    */
   public void filterChanged() {
      User usr = transferUserMap.get(selectedTransferFrom);
      if (usr != null) {
         getOwnership(usr);
      }
   } // filterChanged
   
   /** The ownership records returned as a result of the query. */
   public ApexPages.StandardSetController ownershipRecs{get;set;}
   
   /** Is there a list to display to the user? */
   public Boolean hasDisplayList{
      get {return (displayList != null && !displayList.isEmpty()); }
   }
   
   public List<OwnerWrapper> displayList{
      get {
         if (displayList == null && ownershipRecs != null) {
            displayList = new List<OwnerWrapper>();
            List<Prospect_Ownership__c> recs = (List<Prospect_Ownership__c>) ownershipRecs.getRecords();
            for (Prospect_Ownership__c rec : recs) {
               OwnerWrapper ownWrap = new OwnerWrapper(rec);
               //pubWrap.selected = selectedPubIds.contains(pub.Id);
               displayList.add(ownWrap);
            } // for
         } // if (displayList == null
         return displayList;
      } // get
      private set;
   } // displayList
   
   /*
   public Boolean hasNext { 
      get { return (ownershipRecs != null && ownershipRecs.getHasNext());
      }  // get
   } // hasNext
        
   public Boolean hasPrevious {  
      get { return (ownershipRecs != null && ownershipRecs.getHasPrevious());
      } // get
   } // hasPrevious  
    */
    
   /** Goto the next page of records. */
   public void next() {
      displayList = null;
      ownershipRecs.next();
   } // next

   /** Goto the previous page of records. */
   public void previous() {  
      displayList = null;
      ownershipRecs.previous();  
   } // previous    

   /** Goto the next page of records. */
   public void firstPage() {
      displayList = null;
      ownershipRecs.first();
   } // next

   /** Goto the previous page of records. */
   public void lastPage() {  
      displayList = null;
      ownershipRecs.last();  
   } // previous    

   public Boolean selectAllOption{get;set;}
   
   public void changeSelectAllOption() {
    if (displayList != null) {
       for (OwnerWrapper ow : displayList) {
          ow.selected = selectAllOption;
       }
    } // if
    
   } // changeSelectAllOption
   
   /** The total number of pages available. */
   public Integer numOfPages {
      get {
        if (numOfPages == null) {
            
           numOfPages = 1;
           if (ownershipRecs != null) {
              decimal result = Decimal.valueOf(ownershipRecs.getResultSize()) / Decimal.valueOf(ownershipRecs.getPageSize());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
              numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
           }
         } // if (numOfPages
        return numOfPages;
      } // get
      private set;
   } // numOfPages
   
   /** The number of records per page. */
   public static Integer RECS_PER_PAGE=Integer.valueOf(Label.NSS_Admin_Rows_Per_Page);
   
   /** Retrieve all of the open ownership records for the passed in user.
    */
   public Boolean getOwnership(User usr) {
      Boolean okay = true;
      ownershipRecords = new OwnerWrapper[]{};
      displayList = null;
      ownershipRecs = null;
      numOfPages = null;
      System.debug('getOwnership usr='+usr);
      if (usr != null) {
         //Prospect_Ownership__c[] recs = ProspectOwnershipMethods.getOpenByUser(usr.Id,200);
         Set<String> statusFilter = ((String.isNotBlank(selectedFilterOption) && selectedFilterOption != ALL) ? new Set<String>{selectedFilterOption} : allOwnershipStatuses);
         Set<String> nssTeamFilter = ((String.isNotBlank(selectedNssTeam) && selectedNssTeam != ALL) ? new Set<String>{selectedNssTeam} : null);
         ownershipRecs = getAllOpenOwnershipByUser(usr.Id, RECS_PER_PAGE, statusFilter, nssTeamFilter);
      }
      return (ownershipRecs != null && ownershipRecs.getResultSize() > 0);
   } // getOwnership
   
   // Get all of the open ownership records.
   //  @param userId - the user we are selecting for
   //  @param recsPerPage - the number of records per page
   //  @param statusFilter - to only select certain statuses/stages
   public static ApexPages.StandardSetController getAllOpenOwnershipByUser(Id userId, Integer recsPerPage, Set<String> statusFilter, Set<String> nssTeamFilter) {
      ApexPages.StandardSetController posRecSet = null;
      System.debug('getAllOpenOwnershipByUser userId='+userId+' recsPerPage='+recsPerPage);
      if (userId != null && recsPerPage != null) {
         // query only the fields we need (to try to reduce page size)
         String query = 'Select Id ';
         query += ', DaysLeftInStage__c ,Lead__c, NSSAdminInfo__c, NSS_Team__c, Prospect_Client__c, StartDate__c, StatusStartDate__c';
         query += ', Ownership_Status__c ';
         query += ', Decision_Maker__r.LastNSSCallDisposition__c';
         query += ', Prospect_Client__r.LastNSSCallDisposition__c';
         query += ', Lead__r.LastNSSCallDisposition__c';

         query += ' From Prospect_Ownership__c ';
         //String query = getProspectOwnerQuery(true); //ObjectHelper.getSOQLQuery('Prospect_Ownership__c',null,true, false);
         if (query != null) {
            query += ' Where NSR_Name__c = :userId and EndDate__c = null'; 
            if (statusFilter != null && !statusFilter.isEmpty()) {
               query += ' and Ownership_Status__c in :statusFilter ';
            }
            if (nssTeamFilter != null && !nssTeamFilter.isEmpty()) {
               query += ' and NSS_Team__c in :nssTeamFilter ';
            }
            query += ' order by Ownership_Status__c asc, StatusStartDate__c desc ';
            System.debug('getAllOpenOwnershipByUser query='+query);
            
            posRecSet = new ApexPages.StandardSetController(Database.getQueryLocator(query));
            posRecSet.setPageSize(recsPerPage); 
         } // if (query != null)
      } // if (userId != null
      return posRecSet; 
   } // getAllOpenOwnershipByUser

   public OwnerWrapper[] ownershipRecords{get;set;}
   
   // if for some reason an id isn't found, use this so we don't get a null value
   public static Id BAD_ID='001000000000000';
   
   /** A class for wrapping around the Prospect_Ownership__c record. */
   public class OwnerWrapper {
      public OwnerWrapper(Prospect_Ownership__c p_owner) {
        owner = p_owner;
        selected = false;
        //lols = ProspectOwnershipMethods.getSetting(owner);
         //String key = owner.Ownership_Status__c+'-'+owner.NSS_Team__c;
         //LifeOfLeadSettings__c lols = LifeOfLeadSettings__c.getInstance(key);
         
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'OwnerWrapper owner='+owner.Name+' lols='+lols));
         //if (lols != null) {
            //Date startDate = (Date)owner.get(lols.StageStartDateField__c);
         //   Date startDate = owner.StatusStartDate__c;
            
         //   if (startDate != null) {
               //stageStartDate = startDate.format();
         //      Integer daysPassed = Date.today().daysBetween(startDate);
         //      daysLeftInStage = lols.NumOfDays__c.intValue() - daysPassed;
         //   }
         //}
      } // OwnerWrapper
      
      //LifeOfLeadSettings__c lols = null;
      
      /** Is this linked to an account? */
      public Boolean isAccount{
         get {return (owner.Prospect_Client__c != null); }
      } // isAccount
      
      /** Is this linked to a lead? */
      public Boolean isLead {
         get {return (owner.Lead__c != null); }
      } // isLead
      
      // The new user for when the record is transferred.
      public User newUser{get;set;}
      
      public Prospect_Ownership__c owner{get;set;}
      public Boolean selected{get;set;}
      
      // to display the start date on the form
      //public String stageStartDate{get;private set;}
      
      // the number of days left in the current stage
      //public Integer daysLeftInStage{get;private set;}

      // get either the account or lead id attached to the ownership record. 
      public Id sourceId{
         get {
            return (owner != null ? (isAccount ? owner.Prospect_Client__c : (isLead ? owner.Lead__c : BAD_ID)) : BAD_ID);
         }
      }
      
      public String callDisposition{
         //JC changed order to check prospect first then contact  
          get {
            String retVal = null;
            if (owner.Prospect_Client__r != null) {
               retVal = owner.Prospect_Client__r.LastNSSCallDisposition__c;
            } else if (owner.Decision_Maker__r != null) {
               retVal = owner.Decision_Maker__r.LastNSSCallDisposition__c;
            } else if (owner.Lead__r != null) {
               retVal = owner.Lead__r.LastNSSCallDisposition__c;
            } 
            return retVal;
         } // get
      } // callDisposition
            
   } // class OwnerWrapper
   
   /** To group the selected transfer records by user. */ 
   public class TransferToWrapper {
      public TransferToWrapper(User p_usr) {
         usr = p_usr;
         ownerRecs = new List<OwnerWrapper>();
      }
      public User usr{get;set;}
      
      public List<OwnerWrapper> ownerRecs{get;set;}
    
   } // TransferToWrapper
   
   /** The flag for selecting all of the transfer to users. */
   public boolean selectAllTransferTo{get;set;}
   
   /** Select or de-select all of the transfer to records.
    */
   public void changeSelectAllTransferTo() {
    selectedTransferTo = new String[]{};
      if (selectAllTransferTo) {
         for (SelectOption so : transferToOptions) {
            selectedTransferTo.add(so.getValue());
         } // for
      } // if (selectAllTransferTo
    
   } // changeSelectAllTransferTo
   
   /** Cancel out of the operation. */
   public PageReference cancel() {
    // reset all variables, start over
    initOwnerVars();
    transferFromOptions = null;
    selectedTransferFrom = null;
    setupUser();
    showVerify = false;
    showResults = false;
    transferGroups = null;
      setFormAccess(false,true,false,false);
      return null;
   } // cancel
   
   /** Verify the records to transfer.
    */
   public PageReference verifyTransfer() {
      Boolean okay = true;
      // verify transfer to is selected
      if (selectedTransferTo == null || selectedTransferTo.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select one or more users to transfer to!'));
         okay = false;
      }
      
      // verify at least one record is selected
      OwnerWrapper[] selectedRecs = getSelectedRecords();
      if (selectedRecs == null || selectedRecs.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one record must be selected for transfer!'));
         okay = false;
      }
      
      if (okay) {
        okay = distributeRecords(selectedRecs);
      }
      
      if (okay) {
        setFormAccess(false,false,true,false);
         showVerify = true;
      }
    return null;
   } // verifyTransfer
   
   public List<TransferToWrapper> transferGroups{get;set;}
   
   /** Using a type of "round robin" distribute the records to the selected NSRs.
    */
   public Boolean distributeRecords(OwnerWrapper[] selectedRecs) {
    System.debug('distributeRecords nbr recs='+selectedRecs.size());
    
    Boolean okay = true;
      // create an array of the selected users
      User[] selectedUsers = new User[]{};
      
      Map<Id,TransferToWrapper> userWrapperMap = new Map<Id,TransferToWrapper>();
      // for listing on the form
      transferGroups = new List<TransferToWrapper>();

      
      for (String userId : selectedTransferTo) {
         User usr = transferUserMap.get(userId);
         if (usr != null) {
            selectedUsers.add(usr);
            // map to store everything together
            TransferToWrapper ttw = new TransferToWrapper(usr);
            userWrapperMap.put(usr.Id,ttw);
            transferGroups.add(ttw);
         } else {
            // not sure we really need to handle this, but at least for troubleshooting...
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not find a User for Id '+userId));
         }
         
      } // for (String userId
      
      // make sure there's at least one selected user
      if (!selectedUsers.isEmpty()) {
         Integer userCounter = 0;
         for (OwnerWrapper ow : selectedRecs) {
            User usr = selectedUsers[userCounter];
            TransferToWrapper ttw = userWrapperMap.get(usr.Id);
            if (ttw != null) {
               ttw.ownerRecs.add(ow);
               ow.newUser = usr;
            }
            // so we can cycle through the users
            userCounter++;
            if (userCounter >= selectedUsers.size()) {
               userCounter = 0;
            }
         } // for (OwnerWrapper
         
      } else {
         // should never get here since it's being checked before we arrive here...
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not distribute records - no users found!'));
         okay = false;
      }
      return okay;
   } // distributeRecords
   
   public Map<Id,Prospect_Ownership__c> getPOMap(Id[] poRecIds) {
      Map<Id,Prospect_Ownership__c> poMap = new Map<Id, Prospect_Ownership__c>();
      String query = ProspectOwnershipMethods.getProspectOwnerQuery(true);
      query += ' where Id in :poRecIds'; 
      Prospect_Ownership__c[] recs = Database.query(query);
      for (Prospect_Ownership__c po : recs) {
         poMap.put(po.Id, po);
      }
      return poMap;
   } // getPOMap
   
   /** Perform a transfer on the selected records. 
    */
   public PageReference initializeTransfer() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'performTransfer selectedTransferTo='+selectedTransferTo));
      Boolean okay = true;

      // the collection of account and lead ids
      Map<Id,Id> oldToNewOwnerMap = new Map<Id,Id>();
      List<Id> leadAcctIdList = new List<Id>();
      // collect a list of all the prospect ownership ids - we need to reselect the records to get all of the data
      Id[] poRecIds = new Id[]{};
      
      List<OwnerWrapper> ownersToProcess = new List<OwnerWrapper>();
      
      System.debug('initializeTransfer transferGroups='+transferGroups.size());
      // set the new user in the owner wrapper, get the account and lead ids to select them
      for (TransferToWrapper ttw: transferGroups) {
        // we're going to process all of the records later
        ownersToProcess.addAll(ttw.ownerRecs);
        
        for (OwnerWrapper ow : ttw.ownerRecs) {
            ow.newUser = ttw.usr;
            poRecIds.add(ow.owner.Id);

           Id sourceId = ow.sourceId;
           transferLog.NbrOfAccts__c += (ow.isAccount ? 1 : 0);
           // this is because the lead id could still be there for a converted lead
           transferLog.NbrOfLeads__c += ((!ow.isAccount && ow.isLead) ? 1 : 0);           
           
           if (sourceId != BAD_ID) {
            leadAcctIdList.add(sourceId);
              oldToNewOwnerMap.put(sourceId,ttw.usr.Id);
           }
        } // for (OwnerWrapper ow 
        
      } // for (TransferToWrapper
      
      // the total number of owner records.
      transferLog.NbrOfOwnerRecs__c = ownersToProcess.size();
      transferLog.Notes__c += 'initializaTransfer; ';
      saveTransferLog();
      
      Map<Id, Prospect_Ownership__c> ownerMap = getPOMap(poRecIds);
      
      // select the accounts and leads
      Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(leadAcctIdList);
      Map<Id,Lead> leadMap = ReferralQueries.selectLeadMap(leadAcctIdList,null);

      if (okay) {
        // how many records are we processing
        transferLog.NbrSelected__c = ownersToProcess.size();
         saveTransferLog();
         
         performTransfer(ownersToProcess,selectedTransferTo, acctMap, leadMap, ownerMap);
         transferLog.Notes__c += 'performTransfer; ';
         saveTransferLog();
         
         transferActivityCallbacks(selectedTransferFrom,oldToNewOwnerMap);
         transferLog.Notes__c += 'transferActivityCallbacks; ';
         saveTransferLog();
         showVerify = false;
         showResults = true;
         setFormAccess(false,false,true,false);
      }
      
      return null;
   } // initializeTransfer
   
   public Boolean saveTransferLog() {
      Database.UpsertResult result = Database.upsert(transferLog,false); 
      Boolean okay = result.isSuccess();
      return okay;
   } // saveTransferLog
   
   /** Get the records that were selected. 
    */
   public OwnerWrapper[] getSelectedRecords() {
    OwnerWrapper[] recs = new OwnerWrapper[]{};
    if (displayList != null) {
       for (OwnerWrapper ow : displayList) {
          if (ow.selected) {
             recs.add(ow);
          }
       } // for (OwnerWrapper
    } // if (displayList != null
    return recs;
   } // getSelectedRecords
   
   public static final String STATUS_XFER='Transferred';
   
   /** Perform the transfer on the ownership records. 
      •  A confirmation page appears showing all the records that will be transferred and I click the Confirm button;
      •  The status of each existing record is set to “Expired” and the Workable End Date is set to Today(); the Commission Dates are left intact so the Supervisor can get credit for a sale;
      •  A new Prospect Ownership record is created and initialized as follows:
          o  Owner is set to Donna Mendoza;
          o  If Status = “Prospecting”, set Prospecting Start Date to Today;
          o  If Status = “Lockout”, copy Lockout Dates from original but leave Commission Dates set to NULL;
          o  If Status = “Workable”, set Prospecting Start Date to Today and set Status = “Prospecting”.
      •  Any Tasks related to the transferred records with a Subject of “Callback” will be transferred to Donna Mendoza;
   
    */
   public Boolean performTransfer(OwnerWrapper[] ownerRecs, String[] transferToIds, Map<Id,Account> acctMap, Map<Id,Lead> leadMap, Map<Id, Prospect_Ownership__c> ownerMap) {
    System.debug('performTransfer ownerRecs='+(ownerRecs != null ? ownerRecs.size() : -1) +' transferToIds='+transferToIds);
      Boolean okay = (ownerRecs != null && !ownerRecs.isEmpty() && transferToIds != null && !transferToIds.isEmpty());
      
      if (okay) {
        // setup the methods to save the data
        ProspectOwnershipMethods.initializeSaveObjects();
        // records we are updating
        //Prospect_Ownership__c[] recsToUpdate = new Prospect_Ownership__c[]{};
        // records we are inserting
        //Prospect_Ownership__c[] recsToInsert = new Prospect_Ownership__c[]{};
        
        for (OwnerWrapper ow : ownerRecs) {
            Prospect_Ownership__c queriedPO = ownerMap.get(ow.owner.Id);
            ow.owner = (queriedPO != null ? queriedPO : ow.owner);
            // get the current setting
            LifeOfLeadSettings__c setting = ProspectOwnershipMethods.getSetting(ow.owner);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'performTransfer ow.sourceId='+ow.sourceId+' setting.TransferStatus__c='+setting.TransferStatus__c+' acct='+acctMap.get(ow.sourceId)+' lead='+leadMap.get(ow.sourceId)));
            ProspectOwnershipMethods.setStageExitInfo(ow.owner, acctMap.get(ow.sourceId), null, null, leadMap.get(ow.sourceId), true, false, true);
            // set the status to transferred on all ownerships we end through this form.
            ow.owner.Ownership_Status__c = STATUS_XFER;
            
            //recsToUpdate.add(ow.owner);
            
            // create the new record
            Prospect_Ownership__c newPo = new Prospect_Ownership__c(
                             Lead__c=(ow.owner.Prospect_Client__c == null ? ow.owner.Lead__c : null)   // if there's an account we're not going to include the lead - the lead should be converted.
                            ,Lead_Company__c = ow.owner.Lead_Company__c
                            ,Prospect_Client__c = ow.owner.Prospect_Client__c
                            ,Decision_Maker__c = ow.owner.Decision_Maker__c
                            ,OwnerId = ow.newUser.Id
                            ,NSR_Name__c = ow.newUser.Id
                            ,NSS_Team__c = ow.owner.NSS_Team__c
                            ,NSS_Source__c = ProspectOwnershipMethods.getNSS_Source(ow.newUser.Profile.Name) //ow.owner.NSS_Source__c
                            ,Segment__c = ow.owner.Segment__c                             
                            ,StartDate__c = Date.today()
                            // link the new record to the old one
                            ,TransferredFrom__c = ow.owner.Id
                            // set the status based on the previous record
                            ,Ownership_Status__c = setting.TransferStatus__c);
            
            Date stageStartDate = (setting.TransferUseOriginalDates__c ? (Date)ow.owner.get(setting.StageStartDateField__c) : null);
            newPo.put(setting.StageStartDateField__c, stageStartDate);
            // pass in the account/lead
            ProspectOwnershipMethods.setStageEntryInfo(newPo, acctMap.get(ow.sourceId), null, null, leadMap.get(ow.sourceId), false, false);
            System.debug('performTransfer newPo='+newPo);
            //recsToInsert.add(newPo);
        } // for (OwnerWrapper
        
        //if (!recsToUpdate.isEmpty()) {
        //   Database.SaveResult[] results = Database.update(recsToUpdate,false);
        //}
        //if (!recsToInsert.isEmpty()) {
        //   Database.SaveResult[] results = Database.insert(recsToInsert,false);
        //   for (Database.SaveResult result : results) {
        //      System.debug('result='+result);
        //   }
        //}
        
        ProspectOwnershipMethods.checkForSaves();
      } // if (okay
      return okay;
   } // performTransfer
   
   /** Transfer the open call backs to the id defined in the passed in map (account/lead is the key, new user is the value).
    */
   public Boolean transferActivityCallbacks(Id originalOwnerId, Map<Id,Id> oldToNewOwnerMap) {
      Boolean okay = true;
      for (Task[] tsks : [Select Id, OwnerId
                                 ,AccountId, WhoId, WhatId
                            From Task
                           Where OwnerId = :originalOwnerId
                             and IsClosed = false
                             and ActivityDate >= :Date.today()
                             and Type = :TaskHelper.CT_CALLBACK
                             and (AccountId in :oldToNewOwnerMap.keySet() or WhoId in :oldToNewOwnerMap.keySet())
                          ]) {
         transferLog.NbrOfCallbacks__c += tsks.size();
         for (Task tsk : tsks) {
            // update to the new owner based on the values in the map
            String key = (tsk.AccountId != null ? tsk.AccountId : (tsk.WhoId != null ? tsk.WhoId : null));
            if (key != null && (key.startsWith(ObjectHelper.PREFIX_ACCOUNT) || key.startsWith(ObjectHelper.PREFIX_LEAD))) {
                Id newOwnerId = oldToNewOwnerMap.get(key);
                if (newOwnerId != null) {
                  tsk.OwnerId = newOwnerId; 
                //} else {
                //   transferLog.NbrOrphanCallbacks__c++;
                }
            } // if (key != null
         } // for (Task tsk : tsks
         update tsks;
      } // for (Task[] tsks
      return okay;
   } // transferActivityCallbacks
   
   public Boolean verifyEndOwner{get;set;}
   
   private OwnerWrapper[] selectedEndOwnerRecs = null;
   
   // the number of owner records to end
   public Integer numberEndOwnerRecs{
      get {return (selectedEndOwnerRecs != null ? selectedEndOwnerRecs.size() : 0); }
   }
   
   public PageReference verifyEndOwnership() {
    verifyEndOwner = true;
      // verify at least one record is selected
      selectedEndOwnerRecs = getSelectedRecords();
      if (numberEndOwnerRecs == 0) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'At least one record must be selected!'));
         verifyEndOwner = false;
      }
      
      if (verifyEndOwner) {
         setFormAccess(false, false, false, true);
      }
      return null;
   } // endOwnership
   
   public PageReference confirmEndOwnership() {
    setupTransferLog();
      Boolean okay = numberEndOwnerRecs > 0;
      if (okay) {
        
         // the collection of account and lead ids
         Map<Id,Id> oldToNewOwnerMap = new Map<Id,Id>();
         List<Id> leadAcctIdList = new List<Id>();
         Id[] poRecIds = new Id[]{};

         for (OwnerWrapper ow : selectedEndOwnerRecs) {
            Id sourceId = ow.sourceId;
            transferLog.NbrOfAccts__c += (ow.isAccount ? 1 : 0);
            // this is because the lead id could still be there for a converted lead
            transferLog.NbrOfLeads__c += ((!ow.isAccount && ow.isLead) ? 1 : 0);
            
            if (sourceId != BAD_ID) {
               leadAcctIdList.add(sourceId);
            }
            poRecIds.add(ow.owner.Id);
         } // for (OwnerWrapper owner : selectedEndOwnerRecs
         
         // select the records to get all the fields
         Map<Id, Prospect_Ownership__c> ownerMap = getPOMap(poRecIds);

         // the total number of owner records.
         transferLog.NbrOfOwnerRecs__c = selectedEndOwnerRecs.size();
         transferLog.NbrSelected__c = selectedEndOwnerRecs.size();
         transferLog.Notes__c += 'confirmEndOwnership;  ';
         saveTransferLog();
      
         // select the accounts and leads
         Map<Id,Account> acctMap = ReferralQueries.selectAcctMap(leadAcctIdList);
         Map<Id,Lead> leadMap = ReferralQueries.selectLeadMap(leadAcctIdList,null);

         ProspectOwnershipMethods.initializeSaveObjects();
         for (OwnerWrapper ow : selectedEndOwnerRecs) {
            Prospect_Ownership__c po = ownerMap.get(ow.owner.Id);
            ProspectOwnershipMethods.setStageExitInfo(po, acctMap.get(ow.sourceId), null, null, leadMap.get(ow.sourceId), true, true, true);
            
         } // for (OwnerWrapper owner : selectedEndOwnerRecs
         ProspectOwnershipMethods.checkForSaves();
      } // if (okay)
      
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, numberEndOwnerRecs+' ownership records were ended'));
      // force the re-selection of the data
      displayList = null;
      // return to the main page
      return cancelEndOwnership();
   } // confirmEndOwnership
   
   public PageReference cancelEndOwnership() {
    selectedEndOwnerRecs = null;
    verifyEndOwner = false;
    // in case records are selected, reset the values
    selectAllOption = false;
    changeSelectAllOption();
    setFormAccess(false, true, false, false);
      return null;
   } // cancelEndOwnership
   
} // class NSSAdministrationController