/* 
 * The methods used displaying a license summary to the users.
 *
 * History
 * -------
 * 12/10/2009 Dan Carmen   Created
   04/24/2013 Dan Carmen   Modified to use sales org and to remove expense information
   01/03/2023 Dan Carmen   No longer needed, removed all code - CanBeDeleted
   01/24/2024 Jidesh  	   Reverted the code since we can use it for SFDC-25004 research
 *
 */
public with sharing class LicenseSummaryController {

   /** Modify the budget information. */
   //public Boolean modifyBudget{get;private set;}
   
   public User runningUser{get;private set;}
    
    public String sfTesting{get;private set;}
    
   public LicenseSummaryController() {
       //JDA pagination
       totalRecs = [select count() from User_License__c];
       System.debug('JDA LicenseSummaryController constructor');
       System.debug('JDA LicenseSummaryController totalRecs:'+totalRecs);
       runningUser = [Select Id, Profile.Name from User where Id=:UserInfo.getUserId()];
       //modifyBudget = false;
       setLicenses();
       setuserLicenses();
   } // LicenseSummaryController
   
   public Integer readOnlyCnt{get;set;}
   
   public String readOnlyPct{get;set;}
   
   public PageReference cancel() {
   	  //modifyBudget = false;
   	  //setLicenses();
      setuserLicenses();
   	  return Page.LicenseSummary;
   } // cancel

   public List<String> salesOrgs{get;set;}
   
   /** Users without a license type set. */
   public Integer usersWithoutLicense {get; private set;}
   
   /** All of the licenses created. */
   public List<LicenseInfo> licenses {get; private set;}
    
   /** The totals from all of the licenses. */
   public LicenseInfo totalInfo {get; private set;}
   
   /** A map of the license infos using the name as the key. */
   private Map<String,LicenseInfo> licenseInfoMap = new Map<String,LicenseInfo>();
   
   /** A map of the licenses by sales org. */
   //private Map<String,LicenseInfo> licenseMapBySalesOrg = new Map<String,LicenseInfo>();
   
   public Boolean unsavedChangedExist{get;private set;}
   
   /** Setup all of the licenses.
    */
   private void setLicenses() {
   	// retrieve all of the current User License records
   	Map<String,User_License__c> userLicenseMap = getUserLicenseMap();
   	unsavedChangedExist = false;
       licenseInfoMap.clear();
      // instantiate the list
      licenses = new List<LicenseInfo>();
      // setup a record for the totals
      totalInfo = new LicenseInfo(null);
      totalInfo.name = 'Total';
      totalInfo.budgeted = 0;
      totalUsedLicenses = 0;
       for (String licenseName : userLicenseMap.keySet()) {
           User_License__c ul = userLicenseMap.remove(licenseName);
           if (ul == null) {
               System.debug('null user license');
           }
           else{
               LicenseInfo li = new LicenseInfo(ul);
               licenseInfoMap.put(ul.Name,li);
               licenses.add(li);
               //totalInfo.budgeted += li.budgeted;
           }
       } 
      // if anything is left in the map - doesn't map up to a sales org - do we delete them?
      usersWithoutLicense = 0;
      licenses.add(totalInfo);
      totalUsedLicenses += usersWithoutLicense;
   } // setLicenses

   public Integer totalUsedLicenses {get; private set;}

   //Updated by Salesforce Support Case #467330374 
   public String getDetailLicense() {
      String name = System.currentPageReference().getParameters().get('licenseName');
      if (name != null) {
         LicenseInfo li = licenseInfoMap.get(name);
          System.debug('getDetailLicense li:'+li);
          System.debug('getDetailLicense li license:'+li.license);
          System.debug('getDetailLicense li license Ul id:'+li.license.Id);
         if (li != null) {
             selectedUserLicense = li;
             System.debug('li.license: '+li.license);
            return li.license.id;
         }
         ///} // for
      } // if (id != null
      return null;
   } // getDetailLicense
    
   /** Get all of the User License records
    */
   public Map<String,User_License__c> getUserLicenseMap() {
      // get a map of the user licenses
      User_License__c[] licenses = 
                [select Id
                       ,Name
                       ,Description__c
                   from User_License__c
                  order by Name];
      Map<String,User_License__c> userLicenseMap = new Map<String,User_License__c>();
      for (User_License__c license : licenses) {
         userLicenseMap.put(license.Name,license);
      }
      return userLicenseMap;
   } // getUserLicenseMap
   
   /** The User License and some extra information associated with the license.
    */
   public class LicenseInfo {
      public User_License__c license {get; private set;}
          
      public String name {get; set;}
          
      public Integer usedLicenses {get; set;} 
       
      public Integer budgeted {get; set;}
          
      public String budgetedStr {
         get {
            return budgeted.format();
         }
      } // budgetedStr
      
      public LicenseInfo(User_License__c p_license) {
         this.license = p_license;
         // default to zero
         neverLoggedIn = 0;
         if (license != null) {
            name = license.Name;
            //budgeted=(license.BudgetedLicenses__c != null ? license.BudgetedLicenses__c.intValue() : 0);
            usedLicenses = 0;
         } // if (license != null)
      } // LicenseInfo
                      
      /** The difference between the budget and the number actually being used. */                          
      /*public Integer budgetDiff {
         get{
            return (budgeted - usedLicenses);
         } // get
      } */// availableLicenses
          
      public Boolean isNew{
         get {return (String.isBlank(license.Id)); }
      }


      public Integer neverLoggedIn {get; set;}

      private Integer noLogin60Days = null;
          
      /** used for changing the budget information. */
      //public User_License_Request__c budgetULR{get;set;}
          
   } // class LicenseInfo
   
    //JDA changes start
    
    public List<User_License__c> userLicenses {get; private set;}
    public Integer usersWithoutCostCenter {get; private set;}
    public string lastRefreshedDate {get; private set;}
    private integer counter=0;  //keeps track of the offset
    private integer list_size=20; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list
    
    public integer totalRecs;
    public integer OffsetSize = 0;
    private integer LimitSize= 20;
    
    public Integer licenseDifference {get; set;}
    public String searchKey {get;set;}
    
    private String sortDirection = 'ASC';
    private String sortExp = 'name';
    
    public void search(){
        string searchquery='select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c where Name like \'%'+searchKey+'%\' Limit 20';
        userLicenses = Database.query(searchquery);
    }
    public void clear(){
        //userLicenses.clear();
        System.debug('JDA Inside clear');
        //build the full sort expression
        searchKey = '';
        string sortFullExp = sortExpression  + ' ' + sortDirection;
        userLicenses = new List<User_License__c>();
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c order by ' + sortFullExp + ' LIMIT ' + LimitSize + ' OFFSET ' + OffsetSize);
        
    }
    
    public String sortExpression
    {
        get
        {
            return sortExp;
        }
        set
        {
            //if the column is clicked on then switch between Ascending and Descending modes
            if (value == sortExp)
                sortDirection = (sortDirection == 'ASC')? 'DESC' : 'ASC';
            else
                sortDirection = 'ASC';
            sortExp = value;
        }
    }
    
    public String getSortDirection()
    {
        //if not column is selected
        if (sortExpression == null || sortExpression == '')
            return 'ASC';
        else
            return sortDirection;
    }
    
    public void setSortDirection(String value)
    {  
        sortDirection = value;
    }
    
    public void FirstPage()
    {
        OffsetSize = 0;
        getuserLicenses();
    }
    public void previous()
    {
        OffsetSize = OffsetSize - LimitSize;
        getuserLicenses();
    }
    public void next()
    {
        OffsetSize = OffsetSize + LimitSize;
        System.debug('JDA next OffsetSize:'+OffsetSize);
        getuserLicenses();
    }
    public void LastPage()
    {
        OffsetSize = totalrecs - math.mod(totalRecs,LimitSize);
        getuserLicenses();
    }
    
    public Boolean getDisablePrevious() { 
        //this will disable the previous and beginning buttons
        if (OffsetSize>0) return false; else return true;
    }
    
    public Boolean getDisableNext() { //this will disable the next and end buttons
        if (OffsetSize + LimitSize < totalRecs) return false; else return true;
    }
    
    public Integer getPageNumber() {
        return OffsetSize/LimitSize + 1;
    }
    
    public Integer getTotalPages() {
        if (math.mod(totalRecs, LimitSize) > 0) {
            return totalRecs/LimitSize + 1;
        } else {
            return (totalRecs/LimitSize);
        }
    }
    
    /*public String getlastRefreshedDate() {
        System.debug('JDA: Last refresh date:'+License_Summary_Info__c.getInstance('License Summary Data').Last_refreshed_Date__c);
        return License_Summary_Info__c.getInstance('License Summary Data').Last_refreshed_Date__c;
    }*/
    
    private LicenseInfo selectedUserLicense = null;
    
    public LicenseInfo getSelectedUserLicense() {
        return selectedUserLicense;
    } // getSelectedUserLicense
    
    /** Is a license selected? */
    public Boolean userLicenseSelected {
        get {return selectedUserLicense != null;}
    } // userLicenseSelected
    
    public PageReference  viewuserLicenses() {
        // retrieve all of the current User License records
        // instantiate the list
        System.debug('JDA Inside viewuserLicenses');
        //build the full sort expression
        string sortFullExp = sortExpression  + ' ' + sortDirection;
        userLicenses = new List<User_License__c>();
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c order by ' + sortFullExp + ' LIMIT ' + LimitSize + ' OFFSET ' + OffsetSize);
        System.debug('JDA Inside getuserLicenses userLicenses:'+userLicenses);
        return null;
        //usersWithoutCostCenter = usersWithoutCostCenterList.size();
    }
    
    private void setuserLicenses() {
        // retrieve all of the current User License records
        // instantiate the list
        System.debug('JDA Inside setuserLicenses');
        string sortFullExp = sortExpression  + ' ' + sortDirection;
        userLicenses = new List<User_License__c>();
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c order by ' + sortFullExp + ' LIMIT ' + LimitSize + ' OFFSET ' + OffsetSize);
        usersWithoutCostCenter = 0;
        List<User> usersWithoutCostCenterList = [select Id,Cost_Center__c from User where IsActive=true and Cost_Center__c = null];
        System.debug('usersWithoutCostCenterList:'+usersWithoutCostCenterList);
        System.debug('JDA Inside setuserLicenses userLicenses:'+userLicenses);
        usersWithoutCostCenter = usersWithoutCostCenterList.size();
        lastRefreshedDate = License_Summary_Info__c.getInstance('License Summary Data').Last_refreshed_Date__c;
    } // setuserLicenses 
   
    private List<User_License__c> getuserLicenses() {
        // retrieve all of the current User License records
        // instantiate the list
        System.debug('JDA Inside getuserLicenses');
        string sortFullExp = sortExpression  + ' ' + sortDirection;
        userLicenses = new List<User_License__c>();
        /*userLicenses = [Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, BudgetedLicenses__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c
                        from User_License__c order by License_Allocated__c desc LIMIT :LimitSize OFFSET :OffsetSize];*/
        /*userLicenses = [Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, BudgetedLicenses__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c
                        from User_License__c LIMIT :LimitSize OFFSET :OffsetSize];*/
        userLicenses = Database.query('Select Id, Name, Above_Or_Under_Budget__c, BU_Budgeted_License__c, IT_Budgeted_License__c, License_Allocated__c, Total_Licenses__c from User_License__c order by ' + sortFullExp + ' LIMIT ' + LimitSize + ' OFFSET ' + OffsetSize);
        
        System.debug('JDA Inside getuserLicenses userLicenses:'+userLicenses);
        return userLicenses;
        //usersWithoutCostCenter = usersWithoutCostCenterList.size();
    } /// setuserLicenses 
    
    //JDA License review story
   public PageReference getLicenseInfo() {
      //fetch all the cost centers per user
      //Query fetches Each cost centers and number of users within it
       AggregateResult[] usersPerCostCenter = [SELECT Cost_Center__c cstCen, count(Id) cnt FROM User where IsActive = True group by Cost_Center__c]; 
       Map<String, Integer> CostCenterMap = new Map<String, Integer>();
       Boolean isChanged = false;
       Boolean createNewCostCenter = false;
       
       for(AggregateResult agr: usersPerCostCenter){
           String costCenter= (String)agr.get('cstCen');
           Integer nmbrUsers = (Integer)agr.get('cnt');
           //For each cost center, create a cost center map with key: Cost center and value: User count
           //If key is null, means they are users without cost center
           CostCenterMap.put(costCenter, nmbrUsers);
       }
       //There are user with cost center as 0000 mostly sys admins, Comm users etc
       //processing for Cost center '0000' since we are grouping them again
       Map<String, Integer> zeroCCProcessed = LicenseSummaryController.processZeroCostCenters();
       //zeroCCProcessed Data will look like : {0000-Community Users=3, 0000-Force.com Free Users=38, 0000-System Admins=55, 0000-Ungrouped=67...}
       for (String zeroCCtype : zeroCCProcessed.keySet()) {
           CostCenterMap.remove('0000');//removing 0000 before splitting it
           CostCenterMap.put(zeroCCtype, zeroCCProcessed.get(zeroCCtype));
       }
       system.debug('CostCenterMap before processing:'+CostCenterMap);
       //CostCenterMap is based on User
       //costCenters list is based on Cost_Center__c
       //Fetch all the cost center records for comparison with CostCenterMap
       Cost_Center__c[] costCenters = [Select Id, Name, Cost_center_Number__c, Active_License_Count__c, User_License__c from Cost_Center__c];
       //The Unassigned Cost centers User License record - for mapping unassigned cost centers
       //This record is created via data load/manually along with other User Licenses
       String unAssgnUsrLcnName = 'Unassigned Cost centers';
       //fetching the user license info
       User_License__c unassignedCostCenters = [Select Id, Name from User_License__c where Name =: unAssgnUsrLcnName limit 1];
       System.debug('unassignedCostCenters:'+unassignedCostCenters);
       for(Cost_Center__c cc: costCenters){
           //For each cost center record in the list, check if the cost center matches the cost center of the map
           //If its a match: Fetch the active users else return the active users as 0
           System.debug('(cc.Name):'+cc.Name);
           Integer activUsers;
           if(cc.Cost_center_Number__c != '0000'){
               //for cost centers apart from 0000 we are doing normal mapping where Cost center name = Cost center number
               System.debug('CostCenterMap.containsKey(cc.Cost_center_Number__c):'+CostCenterMap.containsKey(cc.Cost_center_Number__c));
               //fetching the active users if cost centers are matching
               activUsers = CostCenterMap.containsKey(cc.Cost_center_Number__c)?CostCenterMap.get(cc.Cost_center_Number__c):0;
               CostCenterMap.remove(cc.Cost_center_Number__c);
           }
           else{
               //for cost center 0000, cost center name = cc name and Cost center number = 0000
               //e.g. 0000-Community Users will be the cc name
               System.debug('CostCenterMap.containsKey(cc.Name):'+CostCenterMap.containsKey(cc.Name));
               activUsers = CostCenterMap.containsKey(cc.Name)?CostCenterMap.get(cc.Name):0;
               CostCenterMap.remove(cc.Name);
           }
           cc.Active_License_Count__c = activUsers;
           isChanged = true;
       }
       List<Cost_Center__c> newCostCenters = new List<Cost_Center__c>();
       //If the CostCenterMap is not empty, it means there are Cost centers within the Users that are not created in SF
       //If CostCenterMap is not empty, create cost center records for that values
       if(!CostCenterMap.isEmpty()){
           system.debug('Unassigned cost centers exist - CostCenterMap:'+CostCenterMap);
           for (String key : CostCenterMap.keySet()) {
               //For cost centers not starting with 0000 
               //Create a normal cost center record mapped to Unassigned Cost Center User License record
               if(key != null && !key.startsWith('0000') && Integer.ValueOf(key) != null ){
                   Cost_Center__c costCen = new Cost_Center__c();
                   //for unassigned cost centers name and number will be same
                   costCen.Name = ''+key;
                   costCen.Cost_center_Number__c = key;
                   if(unassignedCostCenters.Id != null){
                       costCen.User_License__c = unassignedCostCenters.Id;
                   }
                   costCen.Active_License_Count__c = CostCenterMap.get(''+key);
                   newCostCenters.add(costCen);
                   createNewCostCenter = true;
               }
               else if(key != null && key.startsWith('0000')) {
                   //If cost center starts with 0000
                   //Cost center name = 0000-'category name' e.g 0000-Community Users
                   //Cost center number = 0000
                   //Active users = value retrieved from Zero CC processed map where key = CostCenterMap key
                   Cost_Center__c costCen = new Cost_Center__c();
                   costCen.Name = key;
                   costCen.Cost_center_Number__c = '0000';
                   costCen.Active_License_Count__c = zeroCCProcessed.get(key);
                   newCostCenters.add(costCen);
                   createNewCostCenter = true;
                   if(unassignedCostCenters.Id != null){
                       costCen.User_License__c = unassignedCostCenters.Id;
                   }
               }
           }
       }
       if(isChanged){
           DmlHelper.performDML2(costCenters, DmlHelper.DML_UPDATE, 'LicenseSummaryController', 'getLicenseInfo', 'Updating Cost Center Record', true);
           String strStartDate = Datetime.now().formatLong();
           License_Summary_Info__c  ls= License_Summary_Info__c.getInstance('License Summary Data');
           //updating the last refreshed date
           ls.Last_refreshed_Date__c = strStartDate;
           update ls;
           
       }
        if(createNewCostCenter){
            //Insert newCostCenters;
            DMLHelper.performDML2(newCostCenters,DmlHelper.DML_INSERT,'LicenseSummaryController','getLicenseInfo','Creating new Cost Center Record',true);
            String strStartDate = Datetime.now().formatLong();
            License_Summary_Info__c  ls= License_Summary_Info__c.getInstance('License Summary Data');
            ls.Last_refreshed_Date__c = strStartDate;
            update ls;
            setuserLicenses();
        }
       System.debug('newCostCenters created:'+newCostCenters);
       PageReference tempPage = new PageReference('/apex/LicenseSummary');          
       tempPage.setRedirect(true);
       return tempPage;
   } // getLicenseInfo
    
    public static map<String, Integer> processZeroCostCenters()
    {
        //method written to process specific cost centers. 0000
        Integer commUsers = 0;
        Integer sysAdmins = 0;
        Integer unassigned = 0;
        Integer forcefreeUser = 0;
        map<String, Integer> zeroCCSplitMap = new map<String, Integer>();
        List<User> zeroCCusers = [SELECT Id, Name, Cost_Center__c, Profile.Name FROM User where IsActive = True and Cost_Center__c ='0000']; 
        //Checking cost centers based on specific profiles
        for(User usr: zeroCCusers){
            if(usr.Profile.Name != null){
                if(usr.Profile.Name =='Customer Community Login User Clone'){
                    commUsers++;
                }
                else if(usr.Profile.Name.contains('System Administrator')){
                    sysAdmins++;
                }
                else if(usr.Profile.Name.contains('Free User')){
                    forcefreeUser++;
                }
                else{
                    unassigned++;
                }
            }
        }
        zeroCCSplitMap.put('0000-Community Users',commUsers);
        zeroCCSplitMap.put('0000-System Admins',sysAdmins);
        zeroCCSplitMap.put('0000-Force.com Free Users',forcefreeUser);
        zeroCCSplitMap.put('0000-Ungrouped',unassigned);
        System.debug('zeroCCSplitMap:'+zeroCCSplitMap);
        //this map is returned to getLicenseInfo method for further processing
        return zeroCCSplitMap;
    }//processZeroCostCenters
    
    public PageReference RerenderPage() {
        return new PageReference('/apex/LicenseSummary');
    }

} // LicenseSummaryController