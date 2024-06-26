/** Controller used to clone the Account object.
 *
 * History
 * -------
 * 09/13/2012 Dan Carmen   Created
   11/06/2012 Dan Carmen   Added in logic for maintaining existing multi-ids
   01/15/2013 Dan Carmen   Added HRO specific logic (from previous version of account clone)
   10/17/2013 Dan Carmen   Changed to without sharing.
   10/21/2014 Dan Carmen   Added field to the opportunity query so they'll be cloned.
   01/06/2015 Josh Cartwright added HRO_Client_Type__c to copy to asset
   03/31/2016 Dan Carmen   Added Prospect Ownership information into the clone
   08/02/2016 Dan Carmen   Default the PO NSR Name to supervisor if NSR isn't active.
   11/10/2016 Justin Stouffer - Updated to work in SF1
   03/27/2017 Cindy Freeman  changed to use Employees__c instead of NumberOfEmployees
   04/05/2017 Cindy Freeman    updates SalesParent on cloned accounts to be original account or original account's sales parent
   01/24/2020 Carrie Marciano  Added ability to add account relationship functionality for Oracle CPQ project Multi-id needs
   04/24/2020 Carrie Marciano  Added PEO_ASO_Permanent_Hold_Out_Description__c to account query so values were copied when account cloned
   05/04/2020 Carrie Marciano   Added ability to Delete Relationships for Multi-Id - will delete Account Junction record, not Account.
   06/10/2020 Carrie Marciano   Fixing original clone functionality to populate SalesParent on cloned accounts
   07/01/2020 Carrie Marciano   Added Type column as read only and Frequency column as editable to Multi-id view 
   07/08/2020 Matt Fritschi     Changed Search function to search off of additional Account/Contact fields.
   08/10/2020 Jake Hinds        Changed debug statement per PMD
   08/18/2020 Carrie Marciano   fixed issue where ParentId on child account was not getting cleared when account junction record was deleted.
   09/03/2021 Josh Cartwright added limit to the number of child accts displayed and a message when the count is over the limit
   02/22/2022 Carrie Marciano   Added BenAdmin Holdout fields
   05/01/2023 Eric Porter     Removed Primary_Competition__c 
   08/01/2023 Dan Carmen      Increment API, adjust tests to pass
   09/06/2023 Dan Carmen      Change to always set the SalesParent__c on the children and SalesParentChild__c on the junction
   10/02/2023 Dan Carmen      Fix for saving account junctions - was not accounting for updates
   11/8/2023 Carrie Marciano  Fix for INC3553329 and INC3550077 Added fields (HRO_Number__c, Consolidate_Primary__c, HNBF_Permanent_Hold_Out_Description__c) to account queries that kept throwing errors when using Account Relationships Multi-Id button

*/
public without sharing class AccountCloneController {
   /* The maximum number of records to clone. */
   public static Integer MAX_CLONE=200;
   
   /** The number of records to start with. */
   public static Integer NBR_TO_START=0;
   private Account_Clone__c acctClone = new Account_Clone__c();
   
   private User runningUser;
    
   /* Is this displaying in Salesforce1? */
   public Boolean isSF1 {get; set;}
   public Boolean isMobile {get; set;}
   public Boolean isMultiId {get; set;} 
   public Account searchAcct {get; set;}
    public Contact searchCtct {get; set;}
    public String selectedValue {get;set;}
    
   /* adding message and limit for Accts with many children */
    public Boolean hasLargeChildCount {get;set;}
    public string largeChildCountMsg{get;set;}
      
   /** The default running mode is "MMS" - for cloning with combo/group ids. */
   public String runningMode{get;set;} 
    
   private Id acctId = null;
   public Id opptyId = null;
    
   public static String MODE_MMS='MMS';
   public static String MODE_HRO='HRO';
   public static String MODE_MULTI_ID='MULTIID';
   public static String CREATEDBYPROC='Account Multi-Id Creation';
   public Set<Id> existingAcctIds = new Set<Id>();
   
    
   /** Default constructor
    */
   public AccountCloneController(ApexPages.StandardController stdController) {
      runningUser = [Select Id, Cost_Center__c, Sales_Org__c, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
      isSF1 = Utilities.isSF1();
      isMobile = Utilities.isMobile(); 
      selectedValue = 'acct';
       
      // base the mode off of the profile?
      runningMode = (isSystemAdmin ? null : (isUserHRO ? MODE_HRO : MODE_MMS));
      
      // start at step 1
      currentStep = STEP1;
      searchAcct = new Account(); 
      searchCtct = new Contact(); 
      setupRelationshipTypes();
      opptyId = System.currentPageReference().getParameters().get('OpptyId');
      String multiIdParam = System.currentPageReference().getParameters().get('MultiId');
      isMultiId = (String.isNotBlank(multiIdParam) && multiIdParam == 'True');
     
      acctId = System.currentPageReference().getParameters().get('Id');
      system.debug('AccountCloneController currentStep: '+currentStep+' isMultiId: '+isMultiId+' acctId: '+acctId+' opptyId: '+opptyId);        
      
       // default the number of records to add
      //nbrCloneRecords = NBR_TO_START;
      nbrCloneRecords = (isMultiId ? 0 : NBR_TO_START);
       
      //Boolean setAcctOkay = setAccount(acctId);
      //System.debug('isSystemAdmin='+isSystemAdmin+' setAccount(acctId): '+setAcctOkay);
      okayToProceed = (!isSystemAdmin && setAccount(acctId));
      System.debug('AccountCloneController okayToProceed='+okayToProceed);
   } // AccountCloneController
   
   /** Check if HRO user
    */
   public Boolean isUserHRO{
      get {return (runningUser != null && (runningUser.UserRole.Name.startsWith('HR Online')
                                           || runningUser.UserRole.Name.startsWith('HROSC')
                                           || runningUser.UserRole.Name.startsWith('Online'))); }
   } // isUserHRO
   
   /** Is the running user a system admin?
    */
   public Boolean isSystemAdmin{
      get {return (runningUser != null && runningUser.Profile.Name == Utilities.PROF_SYS_ADMIN); }
   } // isSystemAdmin
   
   /** Is this running in HRO mode? */
   public Boolean isModeHRO{
      get {return (runningMode != null && runningMode == MODE_HRO); }
   } // isModeHRO
   
   public PageReference changeRunningMode() {
    okayToProceed = setAccount(acctId);
      return null;
   } // changeRunningMode
   
   /** The source Account. */
   public Account acct{get;set;}
    
   /** are there any contacts? */
   public Boolean hasCtcts{
      get {return (ctcts != null && !ctcts.isEmpty()); }
   } // hasCtcts
   
       
   /** The list of Accounts */
   public List<AccountWrapper> accts{get;set;}
   /** The Contacts associated with the Account */
   public List<ContactWrapper> ctcts{get;set;}
   /** The Opportunities associated with the Account. */
   public List<OpportunityWrapper> opptys{get;set;}
   /** list of accounts found from search */
   public List<Account> foundAccounts{get;set;}
   /** What is the current step the process is on? */
   public String currentStep{get;private set;}
   
   /** are there any opportunities? */
   public Boolean hasOpptys{
      get {return (opptys != null && !opptys.isEmpty()); }
   } // hasOpptys
   
   /** The number of records to retrieve for the changeNbrAccounts method. */
   public Integer nbrCloneRecords{get;set;}
   
   /** Do any of the source account records have a bis id? */
   public Boolean hasIntegratedAcct{get;set;}
   /** Are any of the children existing records? */
   public Boolean hasExistingChild{get;set;}
   
   /** Are we only modifying existing ids? */
   public Boolean onlyModifyingExisting{
      get {return (hasExistingChild && nbrCloneRecords == 0); }
   } // onlyModifyingExisting
   
   public Integer nbrExistingChildren{get;private set;}
   /** has run one search should show results section on page */
   public Boolean searchCompleted{get;private set;}
   /** Is it okay to proceed? ex: is the account present and accounted for? */
   public Boolean okayToProceed{get;private set;}
 
   /** Set the Account object - select the minimum amount of data needed here. Select the rest of the data
       needed for copying at that point. 
    */
   
    public PageReference performSearch() {
       clearSearchResults();
       // make sure at least one field has a value
       // make sure at least one field has a value
        if (selectedValue == 'acct' && (searchAcct.Name != null || searchAcct.AccountNumber != null || searchAcct.Federal_ID_Number__c != null || searchAcct.ShippingStreet != null || searchAcct.Phone != null)) {
            // search Account record by name
            if(searchAcct.Phone == null)
            {
                searchAccountsAndContacts();
            }
            else
            {
                searchAccountsByPhone();
            }
        } // if (searchAcct.Name
        if(selectedValue == 'ctct' && (searchCtct.FirstName != null || searchCtct.LastName != null || searchCtct.Phone != null))
        {
            if(searchCtct.Phone == null)
            {
                searchAccountsAndContacts();
            }
            else
            {
                searchContactsByPhone();
            }
        }
       
       // are there any search results?
      system.debug('performSearch hasSearchResults: '+hasSearchResults);
       if (!hasSearchResults) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No search results were found! Please enter the information for a different account.'));
       }else{
         searchCompleted = true;     
      }
      
       return Page.AccountClone;
       //return null;
   } // performSearch  
   
    public Boolean hasSearchResults{
        get {
          return (foundAccounts != null && !foundAccounts.isEmpty());
        }
    }
   public void clearSearchResults() {
       foundAccounts = null;
   } // clearSearchResults
   
    private void searchAccountsAndContacts() {
        System.debug('selectedValue='+selectedValue);
        faccts = null; 
        
        Set<String> fldSet = new Set<String>();
        //String query = null;
        Schema.FieldSet acctSearchFldSet = Schema.SObjectType.Account.fieldSets.acctSearchFldSet;
        for (Schema.FieldSetMember fsm : acctSearchFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldSet.add(fldName);
        }
        String[] fldList = new String[]{};
            fldList.addAll(fldSet);
        fldList.sort();
        //String subQuery = ',(Select Id from Account_Junctions__r limit 1)'; 
        //String whereClause = ' where Name like \''+String.escapeSingleQuotes(searchAcct.Name)+'%\''; 
        //query = 'Select '+String.join(fldList,',')+' From Account'+whereClause; 
        //system.debug('searchAccounts query '+query);
        //foundAccounts = Database.query(query);
        //String searchAcctName = '%'+SearchAcct.Name+'%';
        List<Id> ctctAccountList = new List<Id>();
        List<Contact> ctctList = new List<Contact>();
        //System.debug('searchCtct.FirstName='+searchCtct.FirstName+' searchCtct.LastName='+searchCtct.LastName);
        if(selectedValue == 'ctct' && (searchCtct.FirstName != null || searchCtct.LastName != null))
        {
            String ctctSearchQuery = 'SELECT Id, Name, AccountId FROM Contact WHERE ';
            if(searchCtct.FirstName != null)
            {
                ctctSearchQuery += 'FirstName LIKE \'' + searchCtct.FirstName + '%\' and ';
            }
            if(searchCtct.LastName != null)
            {
                ctctSearchQuery += 'LastName LIKE \'' + searchCtct.LastName + '%\' and ';
            }
            ctctSearchQuery = ctctSearchQuery.substring(0, ctctSearchQuery.length()-4);
            ctctSearchQuery += +'Limit 200';
            System.debug('ctctSearchQuery='+ctctSearchQuery);
            ctctList = Database.query(ctctSearchQuery);
            //ctctList = [SELECT Id, Name, AccountId FROM Contact WHERE Name LIKE :searchContactName LIMIT 200];
        }
        for(Contact ctct : ctctList)
        {
            if(ctct.AccountId != null)
            {
                ctctAccountList.add(ctct.AccountId);
            }
        }
        String query = 'Select Id, Name'
            +',AccountNumber'
            +',Bis_Id__c'
            +',Federal_ID_Number__c'
            +',Frequency__c'
            +',NumberOfEmployees'
            +',Employees__c'
            +',SalesParent__c'
            +',Owner.Name'
            +',ShippingPostalCode'
            +',Type'
            +',Combo_Client__c'
            +',HRO_Number__c'
            +',ParentId'
            +',Consolidate_Primary__c'
            +' From Account Where ';
        if(selectedValue == 'acct')
        {
            if(SearchAcct.Name != null)
            {
                query += 'Name like \'' + SearchAcct.Name + '%\' and ';
            }
            if(searchAcct.AccountNumber != null)
            {
                query += 'AccountNumber = \'' + searchAcct.AccountNumber + '\' and ';     
            }
            if(searchAcct.Federal_ID_Number__c != null)
            {
                query += 'Federal_ID_Number__c = \'' + searchAcct.Federal_ID_Number__c + '\' and ';    
            }
            if(searchAcct.ShippingStreet != null)
            {
                query += 'ShippingStreet like \'' + searchAcct.ShippingStreet + '%\' and ';     
            }
            query = query.substring(0, query.length()-4); 
        }
        else if(selectedValue == 'ctct')
        {
            query += 'Id IN (';
            for(Id acctId : ctctAccountList)
            {
                query += '\'' + acctId + '\',';
            }
            query = query.substring(0, query.length()-1);
            query += ') ';
        }
        
        query += +'Limit 200';
        System.debug('Account Query = '+ query);
        foundAccounts = Database.query(query);
        System.debug('foundAccounts='+foundAccounts);
        system.debug('searchAccounts foundAccounts size '+foundAccounts.size()); 
        if(foundAccounts.size() == 200) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.')); 
            //searchAcct.Name.addError(' Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.');
        }
    } // searchAccountsAndContacts  
    
    public void searchAccountsByPhone()
    {
        faccts = null;
        String queryString = 'FIND {';
        String phoneNumber = searchAcct.Phone.replaceAll('[^0-9]', '');
        queryString += phoneNumber;
        
        queryString += '} IN PHONE FIELDS RETURNING ';
        
        queryString += 'Account (Id, Name'
            +',AccountNumber'
            +',Bis_Id__c'
            +',Federal_ID_Number__c'
            +',Frequency__c'
            +',NumberOfEmployees'
            +',Employees__c'
            +',SalesParent__c'
            +',Owner.Name'
            +',ShippingPostalCode'
            +',Type'
            +',Combo_Client__c'
            +',ParentId'
            +' WHERE ';
        
        boolean hasMoreCriteria = false;
        if(SearchAcct.Name != null)
        {
            queryString += 'Name like \'' + SearchAcct.Name + '%\' and ';
            hasMoreCriteria = true;
        }
        if(searchAcct.AccountNumber != null)
        {
            queryString += 'AccountNumber = \'' + searchAcct.AccountNumber + '\' and '; 
            hasMoreCriteria = true;
        }
        if(searchAcct.Federal_ID_Number__c != null)
        {
            queryString += 'Federal_ID_Number__c = \'' + searchAcct.Federal_ID_Number__c + '\' and '; 
            hasMoreCriteria = true;
        }
        if(searchAcct.ShippingStreet != null)
        {
            queryString += 'ShippingStreet like \'' + searchAcct.ShippingStreet + '%\' and '; 
            hasMoreCriteria = true;
        }
        
        if(hasMoreCriteria)
        {
            queryString = queryString.substring(0, queryString.length()-4);
        }
        else
        {
            queryString = queryString.substring(0, queryString.length()-7);
        }
        
        queryString += ') LIMIT 200';
        
        
        System.debug('accountPhoneQuery='+queryString);
        
        List<List<sobject>> searchList = search.query(queryString);
        foundAccounts = ((List<account>)searchList[0]);
        
        system.debug('searchAccounts foundAccounts size '+foundAccounts.size()); 
        if(foundAccounts.size() == 200) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.')); 
            //searchAcct.Name.addError(' Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.');
        }
    } //searchAccountsByPhone
    
    public void searchContactsByPhone()
    {
        faccts = null;
        String queryString = 'FIND {';
        
        String phoneNumber = searchctct.Phone.replaceAll('[^0-9]', '');
        queryString += phoneNumber;
        queryString += '} IN PHONE FIELDS RETURNING ';
        
        queryString += 'Contact (Id, Name, AccountId WHERE ';
        boolean hasMoreCriteria = false;
        if(searchCtct.FirstName != null)
        {
            queryString += 'FirstName LIKE \'' + searchCtct.FirstName + '%\' and ';
            hasMoreCriteria = true;
        }
        if(searchCtct.LastName != null)
        {
            queryString += 'LastName LIKE \'' + searchCtct.LastName + '%\' and ';
            hasMoreCriteria = true;
        }
        
        if(hasMoreCriteria)
        {
            queryString = queryString.substring(0, queryString.length()-4);
        }
        else
        {
            queryString = queryString.substring(0, queryString.length()-7);
        }
        
        queryString += ') LIMIT 200';
        
        System.debug('contactPhoneQuery='+queryString);
        
        List<List<sobject>> searchList = search.query(queryString);
        List<Contact> ctctList = new List <Contact>();
        ctctList = ((List<Contact>)searchList[0]);
        
        List<Id> ctctAccountList = new List<Id>();
        
        for(Contact ctct : ctctList)
        {
            if(ctct.AccountId != null)
            {
                ctctAccountList.add(ctct.AccountId);
            }
        }
        
        foundAccounts = [SELECT Id, Name,AccountNumber,Bis_Id__c,Federal_ID_Number__c,Frequency__c,NumberOfEmployees,Employees__c,SalesParent__c,
                         Owner.Name,ShippingPostalCode,Type,Combo_Client__c,HRO_Number__c,ParentId,Consolidate_Primary__c FROM Account WHERE Id IN :ctctAccountList];
        
        system.debug('searchAccounts foundAccounts size '+foundAccounts.size()); 
        if(foundAccounts.size() == 200) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.')); 
            //searchAcct.Name.addError(' Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.');
        }
    } //searchContactsByPhone
    
   /*
   private void searchAccounts() {
      faccts = null; 
      
      Set<String> fldSet = new Set<String>();
      String query = null;
      Schema.FieldSet acctSearchFldSet = Schema.SObjectType.Account.fieldSets.acctSearchFldSet;
      for (Schema.FieldSetMember fsm : acctSearchFldSet.getFields()) {
         String fldName = fsm.getFieldPath();
         fldSet.add(fldName);
      }
      String[] fldList = new String[]{};
      fldList.addAll(fldSet);
      fldList.sort();
      //String subQuery = ',(Select Id from Account_Junctions__r limit 1)'; 
       //String whereClause = ' where Name like \''+String.escapeSingleQuotes(searchAcct.Name)+'%\''; 
      //query = 'Select '+String.join(fldList,',')+' From Account'+whereClause; 
      //system.debug('searchAccounts query '+query);
       //foundAccounts = Database.query(query);
       String searchAcctName = '%'+SearchAcct.Name+'%';
       foundAccounts = [Select Id, Name
                       ,AccountNumber
                       ,Bis_Id__c
                       ,Combo_Client__c
                       ,Consolidate_Primary__c
                       ,CreatedByProcess__c
                       ,Federal_ID_Number__c
                       ,Frequency__c
                       ,Group_ID__c
                       ,HRO_Number__c
                       ,ParentId
                       ,NumberOfEmployees
                       ,Employees__c
                       ,SalesParent__c
                       ,HRO_Complexity_Code__c
                       ,Owner.Name
                       ,ShippingPostalCode
                       ,Type  
                       ,(Select Id, Name, Title
                               ,Email
                               ,Phone
                           from Contacts
                         Where Sales_Contact__c = true
                         order by LastName, FirstName)
                       ,(Select Id, Name, AccountId, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate, HRO_Client_Type__c
                           From Assets
                          Where Product_Plan_Code__c != null)
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c  from Account_Junctions__r)  // linking to the parent junctions - if they have a parent
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c from Parent_Account__r)  // linking to the child junctions - if they have children
                       // only include ownership records that have active commission periods
                      ,(Select Id
                               ,CommissionEnd__c
                               ,CommissionStart__c
                               ,Decision_Maker__c
                               ,NSR_Name__c
                               ,NSR_Name__r.Id
                               ,NSR_Name__r.IsActive
                               ,NSRSupervisor__c
                               ,NSRSupervisor__r.Id
                               ,NSRSupervisor__r.IsActive
                               ,NSS_Source__c
                               ,NSS_Team__c
                               ,Segment__c
                           From Prospect_Ownership__r
                          Where CommissionStart__c <= :Date.today()
                            and CommissionEnd__c >= :Date.today()
                            and (NSR_Name__r.IsActive = true or NSRSupervisor__r.IsActive = true))
                   From Account
                   Where Name like :searchAcctName
                   Limit 200];     
      system.debug('searchAccounts foundAccounts size '+foundAccounts.size()); 
       if(foundAccounts.size() == 200) {
          ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.')); 
          //searchAcct.Name.addError(' Only first 200 results will be returned, if you do not see the prospect-client you were looking for make your search more specific.');
       }
   } // searchAccounts  
*/
    public List<AccountWrapper> faccts{
        get {
            if (faccts == null) {
               faccts = new List<AccountWrapper>();
               for(Account fa : foundAccounts){
                   if (!existingAcctIds.contains(fa.Id)) {  
                      faccts.add(new AccountWrapper(fa,true,accts.size()));
                   }
               } // for
           } // if 
           System.debug('searchAccounts faccts: '+faccts);
           return faccts;
        } // get
      private set;
    } // faccts
    
   public PageReference handleRecordAction() {
       System.debug('handleRecordAction beginning');
       selectedFoundAccts = new List<AccountWrapper>();
       for(AccountWrapper aw : faccts){
           if (aw.selectedForRelate){
               System.debug('handleRecordAction aw.selectedForRelate: '+aw.selectedForRelate+' aw.acct.Name: '+aw.acct.Name+' acct.Id: '+acct.Id); 
               if(aw.acct.ParentId == null){
                   //set parent Id on the account added to the list
                  aw.acct.ParentId = acct.Id;               
               }
               aw.curRecNum = accts.size();
               accts.add(aw);
               existingAcctIds.add(aw.acct.Id);
           }
       }
       faccts = null;
       return Page.AccountClone;
    
   } // handleRecordAction 
   

   public Boolean setAccount(Id acctId) {
      System.debug('inside setAccount acctId passed in: '+acctId+' isMultiId: '+isMultiId);
      Boolean okay = true;
      hasIntegratedAcct = false;
      hasExistingChild = false;
      Set<String> existingComboNbrs = new Set<String>();
      // default the accts property
      accts = new List<AccountWrapper>();
      
      acct = getAcct(acctId);
      if (acct != null) {
          existingAcctIds.add(acct.Id);
          if(isMultiId){
              // if we are querying for the multi ids, we'll be checking the account junctions where this account is parent
              if (!acct.Account_Junctions__r.isEmpty()) {
                  acct = getAcct(acct.Account_Junctions__r[0].Parent_Account__c);
                  System.debug('inside setAccount isMultiId=True acct: '+acct);
              }  
          } else{
              // if this has a parentId, select the parent.
              if (acct.ParentId != null) {
                  System.debug('setAccount parentid found - selecting parentid='+acct.ParentId);
                  acct = getAcct(acct.ParentId);
                  // do we have to keep on checking for multi-level hierarchy?
              }              
              if (acct.Combo_Client__c != null) {
                  existingComboNbrs.add(acct.Combo_Client__c);
              }  
          }

          // check for bis id
         hasIntegratedAcct = (acct.Bis_Id__c != null);
         
         // check for any children
         Account[] childAccts = getAccts(acct.Id,acct.Id,(isModeHRO ? acct.HRO_Number__c : null),new Set<String>(), new Id[]{});
                    
         System.debug('setAccount acct='+acct);
         System.debug('childAccts='+childAccts);
         hasExistingChild = (childAccts.size() > 0);
         
         nbrExistingChildren = childAccts.size();
         System.debug('setAccount hasExistingChild='+hasExistingChild+' nbrExistingChildren='+nbrExistingChildren);
         
         acctClone.Account__c = acct.Id;
         okay = setContacts(acct.Contacts);

         accts.add(new AccountWrapper(acct,true,accts.size()));
         Set<Id> idCheck = new Set<Id>();
         idCheck.add(acct.Id);
         // add all of the existing children.
         for (Account childAcct : childAccts) {
            System.debug('adding childAcct to AccountWrapper: '+childAcct.Name);
            // double check to make sure only added once
            if (!idCheck.contains(childAcct.Id)) {
                existingAcctIds.add(childAcct.Id);
                idCheck.add(childAcct.Id);
               accts.add(new AccountWrapper(childAcct,true,accts.size()));
               if (childAcct.Combo_Client__c != null) {
                  existingComboNbrs.add(childAcct.Combo_Client__c);
               }
               hasIntegratedAcct = (hasIntegratedAcct || childAcct.Bis_Id__c != null);
            }
         } // for (Account
         
         setupComboGroupOptions(existingComboNbrs);
         
         // if starting with children, don't create extra records by default.
         nbrCloneRecords = (hasExistingChild ? 0 : NBR_TO_START);
         System.debug('setAccount hasExistingChild='+hasExistingChild+' nbrCloneRecords='+nbrCloneRecords);
         // create blank records
         changeNbrAccounts();
         
         // get the opportunities - only for the parent record at this point.
         if (okay) {
            okay = setOpportunities(acct.Id);
            setAssets(acct.Assets);
         } // if (okay
      }
      
      return (okay && acct != null && acct.Id != null);
   } // setAccount
    
   public Account getAcct(Id acctId) {
      Account acct = null;
      try {
         acct = [Select Id, Name
                       ,AccountNumber
                       ,Bis_Id__c
                       ,Combo_Client__c
                       ,Consolidate_Primary__c
                       ,CreatedByProcess__c
                       ,Federal_ID_Number__c
                       ,Frequency__c
                       ,Group_ID__c
                       ,HRO_Number__c
                       ,ParentId
                       ,NumberOfEmployees
                       ,Employees__c
                       ,SalesParent__c
                       ,HRO_Complexity_Code__c
                       ,Owner.Name
                       ,ShippingPostalCode
                       ,Larkspur_401K_Assets__c
                       ,Paychex_401K_Assets__c
                       ,Type  
                       ,(Select Id, Name, Title
                               ,Email
                               ,Phone
                           from Contacts
                         Where Sales_Contact__c = true
                         order by LastName, FirstName)
                       ,(Select Id, Name, AccountId, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate, HRO_Client_Type__c
                           From Assets
                          Where Product_Plan_Code__c != null)
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c  from Account_Junctions__r)  // linking to the parent junctions - if they have a parent
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c from Parent_Account__r)  // linking to the child junctions - if they have children
                       // only include ownership records that have active commission periods
                      ,(Select Id
                               ,CommissionEnd__c
                               ,CommissionStart__c
                               ,Decision_Maker__c
                               ,NSR_Name__c
                               ,NSR_Name__r.Id
                               ,NSR_Name__r.IsActive
                               ,NSRSupervisor__c
                               ,NSRSupervisor__r.Id
                               ,NSRSupervisor__r.IsActive
                               ,NSS_Source__c
                               ,NSS_Team__c
                               ,Segment__c
                           From Prospect_Ownership__r
                          Where CommissionStart__c <= :Date.today()
                            and CommissionEnd__c >= :Date.today()
                            and (NSR_Name__r.IsActive = true or NSRSupervisor__r.IsActive = true))
                   From Account
                  Where Id = :acctId];
      } catch (Exception e) {
         // log an error
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'A valid Prospect-Client was not found. Cannot proceed!'));
      } 
      return acct;
   } // getAcct
   
   /** Get the accounts that meet the passed in parameters
    */
   public Account[] getAccts(Id acctId, Id parentAcctId, String hroNumber, Set<String> branchClientNbrSet, Id[] dupIdCheck) {
    System.debug('getAccts acctId: '+acctId+' parentAcctId: '+parentAcctId); 
    if (acctId == null) {
       acctId = '001000000000000000';
    }
    if (parentAcctId == null) {
       parentAcctId = '001000000000000000';
    }
    if (hroNumber == null) {
       hroNumber = 'BadValue';
    }
    Set<Id> multiIdChildrenIdSet = new Set<Id>();
     // if Multi id
     Account_Junction__c[] juncts = [Select Child_Account__c from Account_Junction__c where Parent_Account__c = :parentAcctId];
       System.debug('juncts='+juncts.size()+' multiIdChildrenIdSet: '+multiIdChildrenIdSet.size());
       for (Account_Junction__c junc : juncts) {
         System.debug('junc='+junc);  
         multiIdChildrenIdSet.add(junc.Child_Account__c);
       }
       System.debug('after adding juncs multiIdChildrenIdSet: '+multiIdChildrenIdSet.size()+''+multiIdChildrenIdSet);
       // } end if
      integer queryLimit = integer.valueof(label.ActCloneChildLimit);
      integer childCount = null;
       
      childCount = [select count() From Account
                    Where Id != :acctId
                    and Id not in :dupIdCheck
                    and ((ParentId = :parentAcctId) 
                          or (HRO_Number__c != null 
                               and HRO_Number__c = :hroNumber)
                          or (AccountNumber in :branchClientNbrSet)
                          or (Id in :multiIdChildrenIdSet)
                        ) 
                       ];

      hasLargeChildCount = (childCount > queryLimit); 
      largeChildCountMsg = 'Displaying '+ label.ActCloneChildLimit +' of ' +string.Valueof(childCount) + ' child accounts. ' ; 
       
      Account[] accts = [Select Id, Name
                       ,AccountNumber
                       ,Bis_Id__c
                       ,Combo_Client__c
                       ,Consolidate_Primary__c
                       ,CreatedByProcess__c  
                       ,Federal_ID_Number__c
                       ,Frequency__c
                       ,Group_ID__c
                       ,HRO_Number__c
                       ,ParentId
                       ,NumberOfEmployees
                       ,Employees__c
                       ,Larkspur_401K_Assets__c
                       ,Paychex_401K_Assets__c  
                       ,SalesParent__c
                       ,HRO_Complexity_Code__c
                       ,Owner.Name
                       ,ShippingPostalCode
                       ,Type  
                       ,(Select Id, Name, Title
                               ,Email
                               ,Phone
                           from Contacts
                         Where Sales_Contact__c = true
                         order by LastName, FirstName)
                       ,(Select Id, Name
                               ,Owner.Name
                               ,Employees_Paid_Per_Payroll__c
                           From Opportunities
                          Where HasOpportunityLineItem = true
                            and IsClosed = false)
                       ,(Select Id, AccountId, Name, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate, HRO_Client_Type__c
                           From Assets
                          Where Product_Plan_Code__c != null)
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c  from Account_Junctions__r)  // linking to the parent junctions - if they have a parent
                       ,(Select Id, Child_Account__c, Parent_Account__c, SalesParentChild__c, Type__c from Parent_Account__r)  // linking to the child junctions - if they have children
                       ,(Select Id
                               ,CommissionEnd__c
                               ,CommissionStart__c
                               ,Decision_Maker__c
                               ,NSR_Name__c
                               ,NSR_Name__r.Id
                               ,NSR_Name__r.IsActive
                               ,NSRSupervisor__c
                               ,NSRSupervisor__r.Id
                               ,NSRSupervisor__r.IsActive
                               ,NSS_Source__c
                               ,NSS_Team__c
                               ,Segment__c
                           From Prospect_Ownership__r
                          Where CommissionStart__c <= :Date.today()
                            and CommissionEnd__c >= :Date.today()
                            and (NSR_Name__r.IsActive = true or NSRSupervisor__r.IsActive = true)
                         )
                   From Account
                  Where Id != :acctId
                    and Id not in :dupIdCheck
                    and ((ParentId = :parentAcctId) 
                          or (HRO_Number__c != null 
                               and HRO_Number__c = :hroNumber)
                          or (AccountNumber in :branchClientNbrSet)
                          or (Id in :multiIdChildrenIdSet)
                        ) limit:queryLimit
                       ];

      return accts;
      
   } // getAccts
   
   /** Save the Account Clone record. By default will only save if new. To force the save every time pass in a true.
    */
   public Boolean saveAcctClone(Boolean forceSave) {
      if (forceSave || acctClone.Id == null) {
         
         Database.UpsertResult result = Database.upsert(acctClone);
         // if the record was just created reselect it to get the name field
         if (result.isCreated()) {
            acctClone = [Select Id, Name
                                  ,Account__c
                                  ,Nbr_of_Contacts__c
                                  ,Nbr_of_Ids__c
                                  ,Nbr_of_Opportunities__c
                                  ,NbrOfPos__c
                                  ,Status__c
                           from Account_Clone__c where Id = :acctClone.Id];
         }
      } // if (forceSave
      System.debug('saveAcctClone acctClone: '+acctClone);
      return true;
   } // saveAcctClone
   
   /** Retrieve the open opportunity information for the main account
    */
   public Boolean setOpportunities(Id acctId) {
      opptys = new List<OpportunityWrapper>();
      // put a limit of 20 on the opportunities retrieved - should not have to have more than that!
      Opportunity[] opptyList = [Select Id, Name
                                            ,Amount
                                            ,CloseDate
                                            ,Employees_Paid_Per_Payroll__c
                                            ,StageName
                                            ,Owner.Name
                                            ,(Select Id
                                                    ,PricebookEntry.Product2.Name
                                                From OpportunityLineItems)
                                            ,(Select Id
                                                    ,ContactId
                                                    ,IsPrimary
                                                    ,Role
                                                From OpportunityContactRoles)
                                        From Opportunity
                                       Where AccountId = :acctId
                                         and IsClosed = false
                                        order by CloseDate desc limit 20];
      for (Opportunity opp : opptyList) {
         OpportunityWrapper ow = new OpportunityWrapper(opp);
         opptys.add(ow);
      } // for (Opportunity opp
      return (true);
   } // setOpportunities
   
   /** Set the contacts - create the wrapper classes.*/
   public Boolean setContacts(Contact[] p_ctcts) {
      Boolean okay = true;
      ctcts = new List<ContactWrapper>();
      if (p_ctcts != null && !p_ctcts.isEmpty()) {
         for (Contact ctct : p_ctcts) {
            ContactWrapper cw = new ContactWrapper(ctct);
            ctcts.add(cw);
         } // for (Contact ctct
      } // if (p_ctcts
      return okay;
   } // setContacts
   
   /** Does this have assets?
    */
   public Boolean hasAssets{
      get{ return (assets != null && !assets.isEmpty()); }
   } // hasAssets
   
   public List<AssetWrapper> assets{get;set;}
   
   /** Does this have selected Assets?
    */
   public Boolean hasSelectedAssets{
      get {return (selectedAssets != null && !selectedAssets.isEmpty()); }
   } // hasSelectedAssets
   
   public List<AssetWrapper> selectedAssets{get;set;}
   
   
   /** Set the Assets - create a wrapper class.
    */
   public Boolean setAssets(Asset[] p_assets) {
    Boolean okay = true;
    assets = new List<AssetWrapper>();
    if (p_assets != null && !p_assets.isEmpty()) {
       for (Asset asst : p_assets) {
          AssetWrapper asstWrap = new AssetWrapper(asst);
          assets.add(asstWrap);
       }
    } // if (p_assets
    return okay;
   } // setAssets
   
   /** Change the number of accounts we're going to clone.
    */
   public PageReference changeNbrAccounts() {
      // only allow to add up to MAX_CLONE
      if (nbrCloneRecords != null) {
         if (nbrCloneRecords > MAX_CLONE) {
            nbrCloneRecords = MAX_CLONE;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You are only allowed to clone up to '+MAX_CLONE+' Prospect-Clients.'));
         } else if (hasExistingChild && nbrCloneRecords < 1) {
            
         } else if (nbrCloneRecords < 0) {
            nbrCloneRecords = 0;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Please enter a number greater than 0.'));
         }
         // the minimum number to keep - the parent record and any pre-existing children
         Integer totalRecs = nbrExistingChildren+1+nbrCloneRecords;
         System.debug('changeNbrAccounts totalRecs='+totalRecs+' nbrCloneRecords='+nbrCloneRecords+' nbr accts='+accts.size());
         // add 1 when checking the size to account for the primary record
         if (accts.size() > totalRecs) {
            // remove extra records
            while (accts.size() > totalRecs) {
                System.debug('changeNbrAccounts removing record');
               accts.remove(accts.size()-1);
            }
         } else if (accts.size() < totalRecs) {
            while (accts.size() < totalRecs) {
               System.debug('changeNbrAccounts adding record');
               AccountWrapper aw = new AccountWrapper(acct,false,accts.size());
               accts.add(aw);
            }
         }
         checkComboGroupOptions();
      } // if (nbrCloneRecords != null
      return null;
   } // changeNbrAccounts
   
   public List<SelectOption> relationshipTypes{get; private set;} 
   
   //pull in Relationship Type picklist values from Account Junction object 
   public void setupRelationshipTypes(){
    relationshipTypes = new List<SelectOption>();
      relationshipTypes.add(new SelectOption('', ''));

       Schema.DescribeFieldResult fieldResult = Account_Junction__c.Type__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    for( Schema.PicklistEntry f : ple){
          relationshipTypes.add(new SelectOption(f.getLabel(), f.getValue()));
       } 
        System.debug('getrelationshipTypes relationshipTypes: '+relationshipTypes);  
  } // setupRelationshipTypes
   
   public List<SelectOption> comboGroupOptions{get;set;}
   
   /** Setup the options for the combo group field.
    */
   public void setupComboGroupOptions(Set<String> existingComboNbrs) {
      comboGroupOptions = new List<SelectOption>();
      comboGroupOptions.add(new SelectOption('','No'));
      // if there are existing combo options, add those to the picklist
      if (existingComboNbrs != null && !existingComboNbrs.isEmpty()) {
         for (String comboNbr : existingComboNbrs) {
            comboGroupOptions.add(new SelectOption(comboNbr,comboNbr));
         } // for
      } // if (existingComboNbrs
      comboGroupOptions.add(new SelectOption('Combo Client 1','Combo Client 1'));
      comboGroupOptions.add(new SelectOption('Combo Client 2','Combo Client 2'));
      comboGroupOptions.add(new SelectOption('Combo Client 3','Combo Client 3'));
   } // setupComboGroupOptions
   
   /** check to make sure there are at least 1/3 the number of combo client options compared to the number of records being cloned. */
   public void checkComboGroupOptions() {
      while (comboGroupOptions.size() < (accts.size()/3)) {
         String name='Combo Client '+comboGroupOptions.size();
         comboGroupOptions.add(new SelectOption(name,name));
      } // while
   } // checkComboGroupOptions
   
   public List<ContactWrapper> selectedCtcts{get;set;}
   public List<OpportunityWrapper> selectedOpptys{get;set;}
   public List<AccountWrapper> selectedFoundAccts{get;set;}
   
   /** Does this have selected contacts? */
   public Boolean hasSelectedCtcts{
      get { return (selectedCtcts != null && !selectedCtcts.isEmpty()); }
   } // hasSelectedCtcts
   
   /** Does this have selected opportunities? */
   public Boolean hasSelectedOpptys{
      get { return (selectedOpptys != null && !selectedOpptys.isEmpty()); }
   } // hasSelectedOpptys
    
   public Boolean isStep1{get{return currentStep != null && currentStep == STEP1;}}
   public Boolean isStep2{get{return currentStep != null && currentStep == STEP2;}}
   public Boolean isStep3{get{return currentStep != null && currentStep == STEP3;}}
   public Boolean isStepVerify{get{return currentStep != null && currentStep == STEP_VERIFY;}}
   public Boolean isStepLast{get{return currentStep != null && currentStep == STEP_LAST;}}
   public Boolean isStepDelete{get{return currentStep != null && currentStep == STEP_DELETE;}}
   
   public static String STEP1 = 'Select Prospect-Clients';
   public static String STEP2 = (Utilities.isMobile() ? 'Select Contacts' : 'Select Contacts and Opportunities');
   public static String STEP3 = 'Select Opportunities';
   public static String STEP_VERIFY = 'Verify Information';
   public static String STEP_LAST = 'Save Data';
   public static String STEP_DELETE = 'Verify Delete';
   
   public static Map<String,String> nextMap = new Map<String,String>();
   public static Map<String,String> prevMap = new Map<String,String>();
   static {
      nextMap.put(STEP1,STEP2);
      nextMap.put(STEP2,STEP_VERIFY);
       if(Utilities.isMobile()){
           nextMap.put(STEP2,STEP3);
           nextMap.put(STEP3,STEP_VERIFY);
           prevMap.put(STEP_VERIFY,STEP3);
           prevMap.put(STEP3,STEP2);
       } 
       else{
           nextMap.put(STEP2,STEP_VERIFY);
           prevMap.put(STEP_VERIFY,STEP2);
       }
      nextMap.put(STEP_VERIFY,STEP_LAST);
      
      prevMap.put(STEP2,STEP1);
   }
   // the steps in order of operation
   //public static String[] STEPS = new String[]{STEP1,STEP2,STEP3,STEP_VERIFY,STEP_LAST};
   
   /** Go to the next step in the process.
    */
   public PageReference nextStep() {
      if (currentStep != null) {
        system.debug('nextStep currentStep: '+currentStep+'isStep1: '+isStep1+'isStep2: '+isStep2+'isStepVerify: '+isStepVerify+'isStepLast: '+isStepLast);
        if (isStep1 && !checkAccounts()) {
           // stay on the current step if check accounts failed. We don't need to do anything here.
        } else {
            currentStep = nextMap.get(currentStep);
              }
         if (isStep2 && nbrCloneRecords == 0  && (!isModeHRO||(Utilities.isMobile() && isModeHRO))) {
            // skip to the verify step - not copying opportunities and contacts onto existing records
            currentStep = STEP_VERIFY;
         } 
         if (isStepVerify) {
            Boolean okay = verifyData();
            if (!okay) {
               currentStep = STEP1;
            } else {
               // only save when going to the verify step
               //saveAcctClone(false);
            }
            return null;
         } else if (isStepLast) {
             return saveData();
             
         } // if (isStepVerify
      } // if (currentStep != null
      return null;
   } // nextStep
   
   /** Go to the previous step in the process.
    */
   public PageReference previousStep() {
      // if currently on the delete step or on the verify step and not adding records
      if (isStepDelete || (isStepVerify && nbrCloneRecords == 0)) {
         currentStep = STEP1;
          system.debug('previousStep isStepDelete || (isStepVerify && nbrCloneRecords == 0 currentStep: '+currentStep);
      } else {
         if (currentStep != null) {
            currentStep = prevMap.get(currentStep);
            system.debug('previousStep currentStep not null currentStep: '+currentStep); 
         }
      } 
      return null;
   } // previousStep
   
   /** Have to override the cancel from the standard controller because if you enter the form from a child record and you
       delete the child, the standard cancel will try to return to the deleted record. */
   public PageReference cancel() {
       if(isMultiId){
          return returnToOpportunity(); 
       } else {
          return returnToAccount(); 
       }
   } // cancel
   
   /** Verify the data before saving.
    */
   public Boolean verifyData() {
      //Boolean allOkay = checkAccounts();
      verifyAccounts();
      Boolean allOkay = true;
      if (allOkay && nbrCloneRecords > 0) {
         // get selected contacts
         checkContacts();
         // get selected opportunities
         checkOpportunities();
         // get the selected assets
         checkAssets();
         
         if (acct.Prospect_Ownership__r != null && !acct.Prospect_Ownership__r.isEmpty()) {
            acctClone.NbrOfPOs__c=acct.Prospect_Ownership__r.size();
         }
         
      } // if (allOkay
      return allOkay;
   } // verifyData
    
    //auto-selects the Sales Parent Child checkbox before save of records
    public void verifyAccounts() {
        for (AccountWrapper aw : accts) {
            if (aw.aj != null) {
             //} && (aw.aj.Type__c == 'Sales Parent-Child' || aw.aj.Type__c == 'Combo')) {
             // always set the flag
                aw.aj.SalesParentChild__c = true;
            }
        }
    } // verifyAccounts

   /**The record number that we want to delete. */
   public Integer delRecNum{get;set;}
   
   public List<AccountWrapper> deleteAccts;
    
   /** Delete the selected record. */
   public PageReference verifyDeleteRec() {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'verifyDeleteRec delRecNum='+delRecNum));
      deleteAccts = new List<AccountWrapper>();
      if (delRecNum != null) {
         for (AccountWrapper aw : accts) {
            if (delRecNum == aw.curRecNum) {
               deleteAccts.add(aw);
            }
         }
         currentStep = STEP_DELETE;
          system.debug('verifyDeleteRec currentStep: '+currentStep);
      } // if (delRecNum
      
      return null;
   } // verifyDeleteRec
   

   /** The accounts that are valid for the current display context. */
   public List<AccountWrapper> displayAccts{
      get {
         if (isStepDelete) {
            return deleteAccts;
         } // if (isDeleteStep
         return accts;
      } // get 
   } // displayAccts
   
   /** delete the selected accts, with attached contacts and opportunities
    */
   public PageReference deleteAccts() {
      // get the account ids
      Id[] acctIds = new Id[]{};
      for (AccountWrapper aw : deleteAccts) {
         acctIds.add(aw.acct.Id);
      }
      if (processDeleteAccts(acctIds)) {
         // change the number of ids on the parent record
         acct.Number_of_ID_s__c = accts.size()-acctIds.size();
         update acct;
         // reselect the records if successful
         setAccount(acct.Id);
         currentStep = STEP1;
      }
      return null;
   } // deleteAccts
   
   /** Perform the physical delete of the records.
    */
   public Boolean processDeleteAccts(Id[] acctIds) {
      Boolean allOkay = true;
      // delete the contacts
      delete [Select Id from Contact where AccountId in :acctIds];
      // delete the opportunities - master detail don't need to delete separately
      //delete [Select Id from Opportunity where AccountId in :acctIds];
      // delete the accounts
      delete [Select Id from Account where Id in :acctIds];
      
      ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully deleted '+acctIds.size()+' Prospect-Client records.'));
      return allOkay;
   } // processDeleteAccts
   
   /** to store records without a combo id */
   public static String NO_COMBO='000_No Combo Id';
   
   public Map<String,List<AccountWrapper>> byComboMap{get;set;}
   
   /** Check that Contacts are selected and okay.
    */
   public Boolean checkContacts() {
      Boolean allOkay = true;
      selectedCtcts = new List<ContactWrapper>();
      for (ContactWrapper cw : ctcts) {
         if (cw.selected) {
            selectedCtcts.add(cw);
         }
      } // for (ContactWrapper
      acctClone.Nbr_of_Contacts__c = selectedCtcts.size();
      return allOkay;
   } // checkContacts
   
   /** Check that Opportunities are selected and okay.
    */
   public Boolean checkOpportunities() {
      Boolean allOkay = true;
      selectedOpptys = new List<OpportunityWrapper>();
      for (OpportunityWrapper ow : opptys) {
         if (ow.selected) {
            selectedOpptys.add(ow);
         }
      } // for (OpportunityWrapper
      acctClone.Nbr_of_Opportunities__c = selectedOpptys.size();
      return allOkay;
   } // checkOpportunities
   
   /** Check that Assets are selected and okay.
    */
   public Boolean checkAssets() {
      Boolean allOkay = true;
      selectedAssets = new List<AssetWrapper>();
      for (AssetWrapper aw : assets) {
         if (aw.selected) {
            selectedAssets.add(aw);
         }
      } // for (OpportunityWrapper
      acctClone.Nbr_of_Assets__c = selectedAssets.size();
      return allOkay;
   } // checkAssets
   
   /** Make sure the accounts are okay. Verify account numbers and check for duplicates.
    */
   public Boolean checkAccounts() {
      system.debug('checkAccount beginning isMultiId: '+isMultiId); 
      Boolean allOkay = true;
      // check for duplicate/existing prospect-client numbers
      Map<String,AccountWrapper> branchClientNbrMap = new Map<String,AccountWrapper>();
      // the account ids to exclude from the duplicate check
      Id[] dupIdCheck = new Id[]{};
      
      // group by combo id
      byComboMap = new Map<String,List<AccountWrapper>>();
      
      for (AccountWrapper aw : accts) {
         // use all accounts present
         Boolean thisOkay = true;

         // verify Type selected
         if (isMultiId && (!aw.isIntegrated && aw.aj.Type__c == null) && !aw.isParent) {
            aw.aj.Type__c.addError('Enter the Relationship Type');
            thisOkay = false;
         }
          
         // verify number of employees
         if (!isModeHRO && (!aw.isIntegrated && aw.acct.Employees__c == null || aw.acct.Employees__c == 0)) {
            aw.acct.Employees__c.addError('Enter the Number of Employees');
            thisOkay = false;
         }
            
         // verify the fed id is in the correct format if it's present
         if (aw.acct.Federal_ID_Number__c != null) {
            if (!Pattern.matches('[0-9]{2}-[0-9]{7}', aw.acct.Federal_ID_Number__c)) {
               aw.acct.Federal_ID_Number__c.addError('The Federal ID must be in the following format xx-xxxxxxx');
               thisOkay = false;
            }
         } // if (aw.acct.Federal_ID_Number__c
         
         // verify the account number if it is present
         if (aw.acct.AccountNumber != null) {
            String acctNbr = AccountHelper.transformAcctNbr(aw.acct.AccountNumber.toUpperCase());
            if (!aw.isIntegrated && !AccountHelper.isAcctNbrValid(acctNbr)) {
               // log an error message!
               aw.acct.AccountNumber.addError('The Prospect-Client Number you entered is not in a valid format!'); 
               thisOkay = false;
            } else {
               if (!aw.isIntegrated) {
                  aw.acct.AccountNumber = acctNbr;
               }
               // check to make sure the number is unique on the form.
               if (branchClientNbrMap.containsKey(acctNbr)) {
                  aw.acct.AccountNumber.addError('This Prospect-Client Number has already been entered!');
                  thisOkay = false;
               } else {
                  branchClientNbrMap.put(acctNbr,aw);
                  // exclude the records from the query if they've already been saved
                  if (aw.isExisting) {
                     //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Excluding id '+aw.acct.Id));
                     dupIdCheck.add(aw.acct.Id);                  
                  }
               }
            } // if (!AccountHelper.isAcctNbrValid
            
         } // if (aw.acct.AccountNumber
         if (thisOkay) {
            // to store/display the records by the combo indicator
            String comboKey = ((aw.comboIndicator != null && aw.comboIndicator != '') ? aw.comboIndicator : NO_COMBO);
            system.debug('checkAccount comboKey: '+comboKey); 
            List<AccountWrapper> comboAcctList = byComboMap.get(comboKey);
            if (comboAcctList == null) {
               system.debug('checkAccount comboAcctList == null'); 
               comboAcctList = new List<AccountWrapper>();
               byComboMap.put(comboKey,comboAcctList);
            }
            if (comboKey == NO_COMBO) {
               // make sure the primary flag is not set
               aw.acct.Consolidate_Primary__c = false;
            }
            comboAcctList.add(aw);
            system.debug('checkAccount comboAcctList:'+comboAcctList);

         } // if (thisOkay
         allOkay = (allOkay && thisOkay);               
      } // for (AccountWrapper aw
      
      if (allOkay) {
         // check for duplicate branch-client numbers in the database. Exclude the source account from the query.
         allOkay = checkForDuplicates(branchClientNbrMap,dupIdCheck);
      }
      
      if (allOkay) {
         // check that the combos are setup correctly
         allOkay = verifyCombos(byComboMap);
      } // if (allOkay
      
      if (allOkay) {
         // compile record into a display list grouped by combo id
         accts = new List<AccountWrapper>();
         String styleColor = 'BLACK';
         List<String> keysSorted = new List<String>();
         keysSorted.addAll(byComboMap.keySet());
         keysSorted.sort();
         for (String key : keysSorted) {
            List<AccountWrapper> acctList = byComboMap.get(key);
            if (acctList != null) {
               for (AccountWrapper aw : acctList) {
                  aw.styleColor = styleColor;
                  accts.add(aw);
               }
            } // if (acctList != null
            
            // switch between black and blue
            styleColor = (styleColor=='BLACK' ? 'GREEN' : 'BLACK');
         } // for (String key
      } // if (allOkay
      
      if (allOkay && accts.size() <= 1) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must add at least one id to proceed!'));
         allOkay = false;
      }
      return allOkay;
   } // checkAccounts
  
   /** Verify that the combos contain more than one record and there is only 1 primary 
    */
   public Boolean verifyCombos(Map<String,List<AccountWrapper>> byComboMap) {
      system.debug('verifyCombos byComboMap:'+byComboMap);
      Boolean allOkay = true;
      for (String key : byComboMap.keySet()) {
         if (key != NO_COMBO) {
            system.debug('verifyCombos key != NO_COMBO'); 
            Boolean thisOkay = true;
            List<AccountWrapper> comboAcctList = byComboMap.get(key);
            // assume if a list is returned that it's not empty
            // verify more than one record in the combo
            if (comboAcctList.size() == 1) {
               system.debug('verifyCombos comboAcctList.size() == 1');
               // log an error on the record
               comboAcctList[0].acct.Name.addError('There must be more than one Prospect-Client in a Combo Client.');
               thisOkay = false;
            } else {
               // 1 and only 1 primary is set
               system.debug('verifyCombos 1 and only 1 primary is set');
               AccountWrapper primary = null;
               for (AccountWrapper aw : comboAcctList) {
                  if (aw.acct.Consolidate_Primary__c) {
                     if (primary == null) {
                        primary = aw;
                     } else {
                        // there is more than one primary set - this is an error!
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'More than one primary was defined for '+key+'! Each combo has to have only 1 primary.'));
                        thisOkay = false;
                     }
                  } // if (aw.acct.Consolidate_Primary__c
               } // for (AccountWrapper
               if (thisOkay && primary == null) {
                  // no primary was set - this is an error!
                  ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, key+' does not have a Primary defined!'));
                  thisOkay = false;
               } else if (thisOkay) {
                  // make sure name and fed id are same on all in the combo
                  Boolean nonMatchFound = false;
                  for (AccountWrapper aw : comboAcctList) {
                     if (primary.acct.Name != aw.acct.Name || primary.acct.Federal_ID_Number__c != aw.acct.Federal_ID_Number__c) {
                        nonMatchFound = true;
                        //aw.acct.Name = primary.acct.Name;
                        aw.acct.Federal_ID_Number__c = primary.acct.Federal_ID_Number__c;
                     }
                  } // for (AccountWrapper
                  if (nonMatchFound) {
                     ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Name/Fed Ids were changed to match the Primary of a Combo.'));
                  }
               } // if (primary == null
               
            } 
            allOkay = (allOkay && thisOkay);
         } // if (key != NO_COMBO
      } // for (String key)
      return allOkay;
   } // verifyCombos
   
   /** Check for duplicates on the records we have a branch-client number for.
    */
   public Boolean checkForDuplicates(Map<String,AccountWrapper> branchClientNbrMap, Id[] dupIdCheck) {

      Boolean okay = true;
      // query for records
      Account[] dupAccts = getAccts(null,null,null,branchClientNbrMap.keySet(),dupIdCheck);

      for (Account acct : dupAccts) {
         AccountWrapper aw = branchClientNbrMap.get(acct.AccountNumber);
         System.debug('checkForDuplicates AccountNumber='+acct.AccountNumber+' aw='+aw);
         if (aw != null) {
            // always set to false so it remains on the same page
            okay = false;
            if (!isModeHRO) {
               aw.acct.AccountNumber.addError('An existing record was found in the database with this Branch-Client Number!');
               aw.dupAcct = acct;
            } else {
               // if this running for HRO, use the record we found
               //Account oldAcct = aw.acct;
               aw.acct = acct;
               // adjust the counts since we don't want to remove an existing record
               nbrExistingChildren++;
               nbrCloneRecords--;
               /*
               if (acct.HRO_Number__c == null && oldAcct.HRO_Number__c != null) {
                  acct.HRO_Number__c = oldAcct.HRO_Number__c;
               }
               */
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'An existing Prospect-Client record was found for '+acct.AccountNumber+'. Anything you have entered was replaced by the saved record..'));
            }
         } // if (aw != null
      } // for (Account acct
      
      return okay;
   } // checkForDuplicates
   
   /** Copy and save the data.
    */
   public PageReference saveData() {
      // Create a savepoint in case we need to rollback the data
      Savepoint sp = Database.setSavepoint();
      Boolean allOkay = copyAccountContacts();
      system.debug('saveData beginning currentStep: '+currentStep);
      if (allOkay && hasSelectedAssets) {
         allOkay = copyAssets();
      }
      
      // this should be done before opportunities are copied - so the ownership triggers for opportunies can fire properly.
      Boolean hasProspectOwnership = (acct.Prospect_Ownership__r != null && !acct.Prospect_Ownership__r.isEmpty());
      System.debug('saveData hasProspectOwnership='+hasProspectOwnership);
      
      if (allOkay && acct.Prospect_Ownership__r != null && !acct.Prospect_Ownership__r.isEmpty()) {
         allOkay = copyProspectOwnership();
      }
      
      if (allOkay && selectedOpptys != null && !selectedOpptys.isEmpty()) {
         allOkay = copyOpportunities();
      }
      
      if (allOkay) {
         // change to the last step if everything's okay.
         currentStep = STEP_LAST;
         acctClone.Status__c = 'Completed';
         saveAcctClone(true);
      } else {
         // rollback all of the changes
         Database.rollback(sp);
      } // if (allOkay 
      system.debug('saveData end currentStep: '+currentStep);
      return null;
   } // saveData
   
   private Id[] contactIds = new Id[]{};
   
   public List<AccountWrapper> copyWrappers{get;set;}
   /** Copy the account and contact records 
    */
   public Boolean copyAccountContacts() {
      System.debug('copyAccountContacts beginning'); 
      Boolean allOkay = true;
      
      saveAcctClone(false);
       
      // save the main acct info
      String acctName = acct.Name;
      String fedId = acct.Federal_ID_Number__c;
      Integer numEmps = Utilities.nvl(acct.Employees__c).intValue();  //acct.Employees__c;
      Boolean comboPrimary = acct.Consolidate_Primary__c;
      String hroNumber = acct.HRO_Number__c;
      System.debug('copyAccountContacts hroNumber: '+hroNumber);
       
      // get the ids of the contacts to copy
      // make sure the array is empty
      contactIds.clear();
      if (selectedCtcts != null) {
         for (ContactWrapper cw : selectedCtcts) {
            contactIds.add(cw.ctct.Id);
         }
      } // if (selectedCtcts
      
      // get the assets to copy
      Set<String> planCodes = new Set<String>();
      if (hasSelectedAssets) {
         for (AssetWrapper aw : selectedAssets) {
            planCodes.add(aw.asst.Product_Plan_Code__c);
         }
      } // if (hasSelectedAssets
      
      // reselect the main account and the contacts that will be copied
      acct = [Select Id, Name
                       ,AccountNumber
                       ,Banker_Name_Ref__c
                       ,BillingCity
                       ,BillingCountry
                       ,BillingPostalCode
                       ,BillingState
                       ,BillingStreet
                       ,Broker_Name_Ref__c
                       ,Combo_Client__c
                       ,Consolidate_Primary__c
                       ,CPA_Name_Ref__c
                       ,CreatedByProcess__c
                       ,Current_Prior_Method__c
                       ,DBA__c
                       ,Enterprise_Hub_Client_Indicator__c
                       ,Fax
                       ,Fed_ID_Name__c
                       ,Federal_ID_Number__c
                       ,Frequency__c
                       ,Group_ID__c
                       ,HNBF_Account_Owner__c
                       ,HNBF_Hold_Out_Expiration__c
                       ,HNBF_Hold_Out__c
                       ,HNBF_Permanent_Hold_Out_Description__c
                       ,BenAdmin_Hold_Out__c
                       ,BenAdmin_Hold_Out_Expiration__c
                       ,BenAdmin_Hold_Out_Reason__c
                       ,HRO_Complexity_Code__c
                       ,HRO_Number__c
                       ,HRO_Implementation_Coordinator__c,HRO_NCP_Received_Date__c
                       ,HRO_Service_Agreement_Received__c, HRO_First_Run_or_New_Setup_Date__c
                       ,HRO_Preview_Hosting_Client__c, HRO_Group__c, HRO_Total_ID_s__c
                       ,HRS_Account_Owner__c
                       ,HRS_Hold_Out_Expiration__c
                       ,HRS_Hold_Out__c
                       ,HRS_Permanent_Hold_Out_Description__c
                       ,Hold_Out_Expiration__c
                       ,Hold_Out__c
                       ,Larkspur_401K_Assets__c
                       ,Legal_City__c
                       ,Legal_Postal_Code__c
                       ,Legal_State__c
                       ,Legal_Street__c
                       ,Local_Competitors__c
                       ,Local_Payroll_Vendor__c
                       ,Multi_Freq__c
                       ,Multi_ID_Parent__c
                       ,NumberOfEmployees
                       ,Employees__c
                       ,SalesParent__c
                       ,Number_of_ID_s__c
                       ,OwnerId
                       ,ParentId
                       ,Paychex_401K_Assets__c
                       ,Permanent_Hold_Out_Description__c
                       ,Phone
                       ,Premier_PBS_Account_Owner__c
                       ,Premier_PBS_Hold_Out_Expiration__c
                       ,PEO_ASO_Permanent_Hold_Out_Description__c   
                       ,Premier_PBS_Hold_Out__c
                       ,RecordTypeId
                       ,Referral_National_Account__c
                       ,SIC_Code__c
                       ,ShippingCity
                       ,ShippingCountry
                       ,ShippingPostalCode
                       ,ShippingState
                       ,ShippingStreet
                       ,Sic
                       ,SicDesc
                       ,Site
                       ,Source_of_Business__c
                       ,Time_Zone__c
                       ,User_Owned_Shipping_Address__c
                       ,Website
                       ,X401K_Assets__c
                       ,(Select Id
                               ,AccountId
                               ,ContactId
                               ,IsPrimary
                               ,Role
                           From AccountContactRoles
                          Where ContactId in :contactIds)
                       ,(Select Id, Name, AccountId, Product_Plan_Code__c, Start_Date__c, Product_End_Date__c, PurchaseDate, HRO_Client_Type__c
                           From Assets
                          Where Product_Plan_Code__c in :planCodes)
                       ,(Select Id
                               ,CommissionEnd__c
                               ,CommissionStart__c
                               ,Decision_Maker__c
                               ,NSR_Name__c
                               ,NSR_Name__r.Id
                               ,NSR_Name__r.IsActive
                               ,NSRSupervisor__c
                               ,NSRSupervisor__r.Id
                               ,NSRSupervisor__r.IsActive
                               ,NSS_Source__c
                               ,NSS_Team__c
                               ,Segment__c
                           From Prospect_Ownership__r
                          Where CommissionStart__c <= :Date.today()
                            and CommissionEnd__c >= :Date.today()
                            and (NSR_Name__r.IsActive = true or NSRSupervisor__r.IsActive = true)
                         )
                       ,(Select Id
                               ,AccountId
                               ,AssistantName
                               ,AssistantPhone
                               ,Asst_Title__c
                               ,Birthdate
                               ,Business_Owner__c
                               //,Contact_Roles__c
                               ,Department
                               ,DoNotCall
                               ,Email
                               ,EmailBouncedDate
                               ,EmailBouncedReason
                               ,Email_Code__c
                               ,Email_Opt_Out_Comments__c
                               ,Email_Opt_Out_Date__c
                               ,Email_Opt_Out_Source__c
                               ,Email_Opt_Out_Submitter__c
                               ,Fax
                               ,FirstName
                               ,HNBF_Contact_Owner__c
                               ,HRS_Contact_Owner__c
                               ,HomePhone
                               ,Home_City__c
                               ,Home_Email_Address__c
                               ,Home_Fax__c
                               ,Home_State__c
                               ,Home_Street_Address__c
                               ,Home_Zip__c
                               ,LastName
                               ,LeadSource
                               ,MailingCity
                               ,MailingCountry
                               ,MailingPostalCode
                               ,MailingState
                               ,MailingStreet
                               ,Marketing_Lead_Source_Contact__c
                               ,Marketing_Lead_Source_Detail_Contact__c
                               ,MobilePhone
                               ,Name
                               ,OtherCity
                               ,OtherCountry
                               ,OtherPhone
                               ,OtherPostalCode
                               ,OtherState
                               ,OtherStreet
                               ,Other_Phone_Extention__c
                               ,OwnerId
                               ,Phone
                               ,Prefered_Name__c
                               ,Premier_PBS_Contact_Owner__c
                               ,RecordTypeId
                               ,Referral_Contact__c
                               ,Sales_Contact__c
                               ,Salutation
                               ,Title
                           from Contacts
                          Where Sales_Contact__c = true
                            and Id in :contactIds
                          order by LastName, FirstName)
                   From Account
                  Where Id = :acct.Id];
      
      System.debug('copyAccountContacts reselect main account acct.NumberOfEmployees: '+acct.NumberOfEmployees);            
      // get a value for the group id - if one is already there use it. Else set a new one.
      if (acct.Group_Id__c == null) {
         // the Name field of the Account_Clone__c object is a unique sequence
         acct.Group_Id__c = acctClone.Name;
         //updatePaychexSetting = true;
      } // if (acct.Group_Id__c

      String groupName = acct.Group_Id__c; 

      Integer comboNbr = 1;
      // get the combo keys excluding the NO_COMBO indicator
      Map<String,String> comboKeyMap = new Map<String,String>();
      for (String key : byComboMap.keySet()) {
         System.debug('Inside loop key='+key+'. NO_COMBO='+NO_COMBO+'.');
         if (key != NO_COMBO) {
            // don't change the name if a custom value
            String comboValue = key.startsWith('Combo') ? groupName+'-'+comboNbr : key;
            comboNbr++;
            //comboKeyMap.put(key,String.valueOf(ps.Clone_Combo_Sequence__c++));
            comboKeyMap.put(key,comboValue);
            //updatePaychexSetting = true;
         }
      } // for (String key

      // accounts to save
      //Account[] saveAccts = new Account[]{};
      Account[] updateAccts = new Account[]{};
      Account[] insertAccts = new Account[]{};
      copyWrappers = new List<AccountWrapper>();

      acctClone.Nbr_of_Ids__c = accts.size();
      
      for (AccountWrapper aw : accts) {
         System.debug('copyAccountContacts acct='+(acct != null)); 
        // don't set the parent if running in HRO mode.
         AccountWrapper copyAw = new AccountWrapper(aw,acct,!isModeHRO);
         copyWrappers.add(copyAw);
         //set the CreatedByProcess to indicate this account was created thru the MultiId Relationship process
         copyAw.acct.CreatedByProcess__c = CREATEDBYPROC; 
         copyAw.acct.Combo_Client__c = (aw.comboIndicator != null ? comboKeyMap.get(aw.comboIndicator) : null);
         copyAw.acct.Multi_ID_Parent__c = (aw.isParent ? 'Yes' : 'No');
         
         // save the number of ids on the original record
         // add to existing number on the parent record. Clear out on child records
         copyAw.acct.Number_of_ID_s__c = (!aw.isParent ? null : accts.size()); 
         
         if (aw.isParent) {
            // save the main acct info
            acct.Name = acctName;
            acct.Federal_ID_Number__c = fedId;
            acct.Employees__c = numEmps;
            acct.Consolidate_Primary__c = comboPrimary;
            acct.HRO_Number__c = hroNumber;
         } else if (isModeHRO && aw.isExisting) {
            // copy the HRO information if this is an existing record.
            copyAw.acct.HRO_Implementation_Coordinator__c = acct.HRO_Implementation_Coordinator__c;
            copyAw.acct.HRO_NCP_Received_Date__c = acct.HRO_NCP_Received_Date__c;
            copyAw.acct.HRO_Service_Agreement_Received__c = acct.HRO_Service_Agreement_Received__c;
            copyAw.acct.HRO_First_Run_or_New_Setup_Date__c = acct.HRO_First_Run_or_New_Setup_Date__c;
            copyAw.acct.HRO_Preview_Hosting_Client__c = acct.HRO_Preview_Hosting_Client__c;
            copyAw.acct.HRO_Group__c = acct.HRO_Group__c;
            copyAw.acct.HRO_Total_ID_s__c = acct.HRO_Total_ID_s__c;
         } else if (isModeHRO) {
            System.debug('setting HRO_Number__c on new record hroNumber='+hroNumber);
            copyAw.acct.HRO_Number__c = hroNumber;
         /*} else if (isMultiId && !aw.isParent) {
             if(aw.aj.Type__c == 'Sales Parent-Child'){
                 copyAw.acct.SalesParent__c = acct.Id;
                 System.debug('copyAccountContacts setting SalesParent__c on new account junction when type is Sales Parent-Child: '+copyAw.acct.SalesParent__c);
             } */
         } // if (aw.isParent)
         System.debug('copyAccountContacts copyAw.acct.Employees__c: '+copyAw.acct.Employees__c+' copyAw.acct.NumberOfEmployees: '+copyAw.acct.NumberOfEmployees+' copyAw.acct.Id: '+copyAw.acct.Id+' copyAw.acct.Name: '+copyAw.acct.Name+' copyAw.acct.HRO_Number__c: '+copyAw.acct.HRO_Number__c); 
         //saveAccts.add(copyAw.acct);
         if (copyAw.acct.Id != null) {
            updateAccts.add(copyAw.acct);
         } else {
            insertAccts.add(copyAw.acct);
         }
      } // for (AccountWrapper
      
      // save the records
      //TriggerMethods.SKIP_TRIGGERS=true;
      System.debug('copyAccountContacts insertAccts='+insertAccts.size()+' updateAccts='+updateAccts.size()); 
      TriggerMethods.skipObjectTriggerSet.add('AccountJunctionMethods');
      Database.DMLOptions dlo = DuplicateHelper.getDmlSkipCheck();
      DmlHelper.performDML2(updateAccts, DmlHelper.DML_UPDATE, 'AccountCloneController', 'copyAccountContacts', 'Update Accounts', true, dlo);
      allOkay = (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0);
      DmlHelper.performDML2(insertAccts, DmlHelper.DML_INSERT, 'AccountCloneController', 'copyAccountContacts', 'Insert new Accounts', true, dlo);
      allOkay = allOkay && (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0);

      //allOkay = new DmlHelper().saveRecords(saveAccts, null, null, false, true);
      System.debug('copyAccountContacts after saveAccts allOkay='+allOkay);
      TriggerMethods.skipObjectTriggerSet.clear();
          
      // if the account save was successful create account junction records
       if(allOkay && !isUserHRO){    
           //Account_Junction__c[] saveAcctJuncs = new Account_Junction__c[]{}; 
           Account_Junction__c[] insertAcctJuncs = new Account_Junction__c[]{}; 
           Account_Junction__c[] updateAcctJuncs = new Account_Junction__c[]{}; 

           Account_Junction__c[] deleteAcctJuncs = new Account_Junction__c[]{};
           for (AccountWrapper aw : copyWrappers){
               System.debug('copyAccountContacts aw='+aw);          
               if (!aw.isParent && aw.aj == null) {  //if not parent account and no existing junction create one
                   Account_Junction__c newJunc = new Account_Junction__c(); 
                   newJunc.Child_Account__c = aw.acct.Id;
                   newJunc.Parent_Account__c = aw.acct.ParentId;
                   newJunc.Employees__c = (aw.acct.Employees__c == null ? 0 : aw.acct.Employees__c);
                   if (aw.acct.Larkspur_401K_Assets__c != null && aw.acct.Larkspur_401K_Assets__c > -1) {  
                       newJunc.Assets__c = aw.acct.Larkspur_401K_Assets__c;    
                   } else {
                       newJunc.Assets__c = (aw.acct.Paychex_401k_Assets__c == null ? 0 : aw.acct.Paychex_401k_Assets__c) ;    
                   }
                   // default this to true
                   newJunc.SalesParentChild__c = true;
                   System.debug('copyAccountContacts newJunc='+newJunc);
                   insertAcctJuncs.add(newJunc);
               } else if (!aw.isParent && aw.aj != null){
                   if(aw.aj.Type__c == 'Delete Relationship'){
                       deleteAcctJuncs.add(aw.aj);
                       System.debug('copyAccountContacts existing aw.aj deleteAcctJuncs:'+deleteAcctJuncs.size()); 
                   } else{
                       System.debug('copyAccountContacts aw.acct.Id='+aw.acct.Id+' aw.acct.ParentId='+aw.acct.ParentId);
                       System.debug('MA1'+aw);
                       System.debug('MA2'+aw.acct);
                       //System.debug('MA3'+aw.acct.Larkspur_401K_Assets__c);
                       aw.aj.Child_Account__c = aw.acct.Id;
                       aw.aj.Parent_Account__c = aw.acct.ParentId;                    
                       aw.aj.Employees__c = (aw.acct.Employees__c == null ? 0 : aw.acct.Employees__c);
                       if (aw.acct.Larkspur_401K_Assets__c != null && aw.acct.Larkspur_401K_Assets__c > -1) {  
                           aw.aj.Assets__c = aw.acct.Larkspur_401K_Assets__c;    
                       } else {
                           aw.aj.Assets__c = (aw.acct.Paychex_401k_Assets__c == null ? 0 : aw.acct.Paychex_401k_Assets__c) ;    
                       }
                       if (aw.aj.Id != null) {
                           updateAcctJuncs.add(aw.aj);
                       } else {
                           insertAcctJuncs.add(aw.aj);
                       }
                       System.debug('copyAccountContacts existing aw.aj='+aw.aj);  
                   }    
               }     
           }
           System.debug('copyAccountContacts insertAcctJuncs='+insertAcctJuncs.size()+' updateAcctJuncs='+updateAcctJuncs.size());
           if (!insertAcctJuncs.isEmpty()) {
               DmlHelper.performDML2(insertAcctJuncs, DmlHelper.DML_INSERT, 'AccountCloneController', 'copyAccountContacts', 'Insert Account Junctions', true, dlo);
               allOkay = (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0) && allOkay;
               System.debug('copyAccountContacts after saveAcctJuncs:'+allOkay);
           } 
           if (!updateAcctJuncs.isEmpty()) {
               DmlHelper.performDML2(updateAcctJuncs, DmlHelper.DML_UPDATE, 'AccountCloneController', 'copyAccountContacts', 'Update Account Junctions', true, dlo);
               allOkay = (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0) && allOkay;
               System.debug('copyAccountContacts after saveAcctJuncs:'+allOkay);
           } 
           if (!deleteAcctJuncs.isEmpty()) {
               //allOkay = new DmlHelper().saveRecords(saveAcctJuncs, null, null, false, true);
               DmlHelper.performDML2(deleteAcctJuncs, DmlHelper.DML_DELETE, 'AccountCloneController', 'copyAccountContacts', 'Delete Account Junctions', true);
               System.debug('copyAccountContacts after deleteAcctJuncs:'+allOkay);
           } 
       }
       
       
      // if the account save was successful copy the contacts - assuming there are contacts
      if (allOkay && acct.Contacts != null && !acct.Contacts.isEmpty()) {
         // setup contact roles
         Map<Id,String> contactRoleMap = new Map<Id,String>();
         Map<Id,List<AccountContactRole>> acctCtctRoleMap = new Map<Id,List<AccountContactRole>>(); 
         
         if (acct.AccountContactRoles != null) {
            for (AccountContactRole acr : acct.AccountContactRoles) {
               String curIdValue = contactRoleMap.get(acr.ContactId);
               // have the list semi-colon separated. If it's a primary role, prefix it with "Pri:"
               curIdValue = (curIdValue != null ? curIdValue+';' : '')+(acr.IsPrimary ? 'Pri:' : '') + acr.Role;
               contactRoleMap.put(acr.ContactId,curIdValue);
               List<AccountContactRole> acrList = acctCtctRoleMap.get(acr.ContactId);
               if (acrList == null) {
                  acrList = new List<AccountContactRole>();
                  acctCtctRoleMap.put(acr.ContactId,acrList);
               }
               acrList.add(acr);
            } // for (AccountContactRole acr
         } // if 
         
         Contact[] saveContacts = new Contact[]{};
         AccountContactRole[] saveAcrs = new AccountContactRole[]{};
         
         for (AccountWrapper aw : copyWrappers) {
            // don't need to do anything for the primary record
            if (!aw.isParent) {
                // don't copy the contacts on existing records
               if (!aw.isExisting && aw.acct.Id != null) {
                  aw.ctctMap = new Map<Id,Contact>();
                  for (Contact ctct : acct.Contacts) {
                     Contact newCtct = ctct.clone(false,true);
                     System.debug('copyAccountContacts newCtct='+newCtct);
                     newCtct.AccountId = aw.acct.Id;
                     System.debug('copyAccountContacts newCtct.AccountId='+newCtct.AccountId);
                     // the account contact roles will be populated by a trigger
                     //newCtct.Contact_Roles__c = contactRoleMap.get(ctct.Id);
                     aw.ctctMap.put(ctct.Id, newCtct);
                     aw.ctcts.add(newCtct);
                     saveContacts.add(newCtct);
                     
                     List<AccountContactRole> acrList = acctCtctRoleMap.get(ctct.Id);
                     if (acrList != null) {
                        for (AccountContactRole acr : acrList) {
                           AccountContactRole newAcr = new AccountContactRole(Role=acr.Role, AccountId=aw.acct.Id);
                           newAcr.Contact = newCtct;
                           saveAcrs.add(newAcr);
                        } // for (AccountContactRole
                     } // if (acrList
                  } // for (Contact ctctAccountCloneController
               } // if (aw.acct.Id
            } // if (!aw.isParent
         } // for (AccountWrapper
         
         if (!saveContacts.isEmpty()) {
            // might not be able to use this routine - 
            DmlHelper.performDML2(saveContacts, DmlHelper.DML_INSERT, 'AccountCloneController', 'copyAccountContacts', 'Save Contacts', true, dlo);
            allOkay = (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0);
            //allOkay = new DmlHelper().saveRecords(saveContacts, null, null, false, true);
            if (allOkay && !saveAcrs.isEmpty()) {
               for (AccountContactRole acr : saveAcrs) {
                  acr.ContactId = acr.Contact.Id;
               }
               
               DmlHelper.performDML2(saveAcrs, DmlHelper.DML_INSERT, 'AccountCloneController', 'copyAccountContacts', 'Save Account Contact Role', true, dlo);
               allOkay = (DmlHelper.performDmlResult != null && DmlHelper.performDmlResult.nbrError==0);
               //allOkay = new DmlHelper().saveRecords(saveAcrs, null, null, false, true);
            } // if (allOkay
         } // if (!saveContacts
      } // if (allOkay

      return allOkay; 
   } // copyAccountContacts
   
   /** Copy the asset to the prospect-client if it doesn't already have it.
    */
   public Boolean copyAssets() {
      Boolean allOkay = true;
      
      // the assets to save
      Asset[] insertAssets = new Asset[]{};
      
      for (AccountWrapper aw : copyWrappers) {
        System.debug('copyAssets is parent='+aw.isParent);
         // don't need to do anything for the primary record
         if (!aw.isParent) {
            System.debug('copyAssets acct.Id='+aw.acct.Id);
            // make sure the record was saved
            if (aw.acct.Id != null) {
               Set<String> existingPlanCodes = getExistingPlanCodes(aw.acct.Id,aw.acct.Assets);
               System.debug('copyAssets existingPlanCodes='+existingPlanCodes);
               for (AssetWrapper asstWrap : selectedAssets) {
                System.debug('copyAssets check Plan Code='+asstWrap.asst.Product_Plan_Code__c);
                  if (!existingPlanCodes.contains(asstWrap.asst.Product_Plan_Code__c)) {
                     Asset newAsset = asstWrap.asst.clone(false,true);
                     newAsset.AccountId = aw.acct.Id;
                     insertAssets.add(newAsset);
                  }
               } // for (AssetWrapper
                
            } // if (aw.acct.Id != null
         } // if (!aw.isParent
      } // for (AccountWrapper aw
      
      if (!insertAssets.isEmpty()) {
         insert insertAssets;
      }
      return allOkay;
   } // copyAssets
   
   public Boolean copyProspectOwnership() {
      Boolean allOkay = true;
      Prospect_Ownership__c[] insertPOs = new Prospect_Ownership__c[]{};
      for (AccountWrapper aw : copyWrappers) {
         System.debug('copyProspectOwnership is parent='+aw.isParent+' acct.Id='+aw.acct.Id);
         if (!aw.isParent && aw.acct.Id != null) {
            for (Prospect_Ownership__c parentPO : acct.Prospect_Ownership__r) {
               Prospect_Ownership__c newPO = new Prospect_Ownership__c(CommissionStart__c=parentPO.CommissionStart__c
                                                               ,CommissionEnd__c=parentPO.CommissionEnd__c
                                                               ,Decision_Maker__c=parentPO.Decision_Maker__c
                                                               ,NSS_Source__c=parentPO.NSS_Source__c
                                                               ,NSS_Team__c=parentPO.NSS_Team__c
                                                               ,Ownership_Status__c=ProspectOwnershipMethods.STAGE_COMMISSION
                                                               ,Prospect_Client__c=aw.acct.Id
                                                               ,Segment__c=parentPO.Segment__c
                                                               ,ProcessNotes__c='Created From AccountClone'
                                                               ,Source__c='AccountClone'
                                                               ,TransferredFrom__c=parentPO.Id);
               newPO.NSRSupervisor__c = (parentPO.NSRSupervisor__r != null && parentPO.NSRSupervisor__r.IsActive ? parentPO.NSRSupervisor__c : null);
               newPO.NSR_Name__c = (parentPO.NSR_Name__r != null && parentPO.NSR_Name__r.IsActive ? parentPO.NSR_Name__c : newPO.NSRSupervisor__c);

               insertPOs.add(newPO);
            }
         } // if (!aw.isParent
      } // for (AccountWrapper aw : copyWrappers
      System.debug('copyProspectOwnership insertPOs='+insertPOs.size());

      if (!insertPOs.isEmpty()) {
         insert insertPOs;
      }
      return allOkay;
   } // copyProspectOwnership
   
   /** Get a set of all of the plan codes.
    */
   public Set<String> getExistingPlanCodes(Id acctId, Asset[] assets) {
      Set<String> existingPlanCodes = new Set<String>();
      if (assets != null && !assets.isEmpty()) {
         for (Asset asst : assets) {
            // make sure the asset is actually for this account, not a cloned artifact.
            if (asst.Id != null && asst.AccountId != null && asst.AccountId == acctId) {
               existingPlanCodes.add(asst.Product_Plan_Code__c);
            }
         }
      } // if (assets != null
      return existingPlanCodes;
   } // getExistingPlanCodes
   
   private Id[] opptyIds = new Id[]{};
   
   /** Select and copy the opportunities.
    */
   public Boolean copyOpportunities() {
      Boolean allOkay = true;
      // get the Ids of the opportunities to copy
      opptyIds.clear();
      for (OpportunityWrapper ow : selectedOpptys) {
         opptyIds.add(ow.oppty.Id);
      }
      if (!opptyIds.isEmpty()) {
         Opportunity[] opptyList = [Select Id
                                          ,AccountId
                                          ,Active_Employees__c
                                          ,Campaign__c
                                          ,CampaignId
                                          ,Child_Unit__c
                                          ,Client_Referral__c
                                          ,CloseDate
                                          ,Core_Branch_Client_Number__c
                                          ,Core_Conversion_Reason__c
                                          ,Employees_Paid_Per_Payroll__c
                                          ,Frequency__c
                                          ,LeadSource
                                          ,Local_Competitors__c
                                          ,Mthd_Lead_Rcvd__c
                                          ,Multi_Frequency__c
                                          ,Multi_ID_Client__c
                                          ,NSR_Email__c
                                          ,NSS_Prospect_ID__c
                                          ,NSS_Rep__c
                                          ,Name
                           
                                    ,Office_Price_Schedule_Map__c
                                          ,OpportunityId__c
                                          ,OppSource__c
                                          ,Other_Competition__c
                                          ,OwnerId
                                          ,Payroll_Unit__c
                                          ,Payroll_Units__c
                                          ,Pricebook2Id
                                          //,Primary_Competition__c
                                          ,Primary_Competitor__c
                                          ,RecordTypeId
                                          ,RecordType.Name
                                          ,Referral__c
                                          ,Referral_Contact__c
                                          ,Referral_Account__c
                                          ,Setup_Fee_Actual__c
                                          ,Setup_Fee__c
                                          ,StageName
                                          ,Total_Revenue__c
                                          ,(Select Id
                                                  ,Actual_Revenue__c
                                                  ,Adj_Type__c
                                                  ,Annual_Base_Trans_Disc__c
                                                  ,Annual_Base_and_Trans__c
                                                  ,Annual_Discount_Dollars__c
                                                  ,Base_Fee__c
                                                  ,Description
                                                  ,Discount_Annualized__c
                                                  ,Discount_Free_Months__c
                                                  ,Discount_Months__c
                                                  ,Discount_Percent__c
                                                  ,Discounted_Annual_Price__c
                                                  ,Estimated_Revenue__c
                                                  ,Estimated_Setup_Fee__c
                                                  ,Frequency__c
                                                  ,Has_External_Id__c
                                                  ,Is_Default__c
                                                  ,Non_Discount_Price_Per_Frequency__c
                                                  ,Non_Discounted_Price__c
                                                  ,Non_Discounted_Revenue__c
                                                  ,Non_Payroll_Unit__c
                                                  ,OpportunityId
                                                  ,Oppty_Product_Id__c
                                                  ,Payroll_Unit__c
                                                  ,Price_Per_Frequency__c
                                                  ,Price_Schedule__c
                                                  ,PricebookEntryId
                                                  ,PricebookEntry.Product2.Default_Units_to_Employees__c
                                                  ,PricebookEntry.Product2.Is_Default_Product__c
                                                  ,PricebookEntry.Product2.Name
                                                  ,Product_Parent_Child_Link__c
                                                  ,Quantity
                                                  ,Reporting_Status__c
                                                  ,Rev_Adj_Calcd__c
                                                  ,Rev_Adj__c
                                                  ,Rollup_Product__c
                                                  ,ServiceDate
                                                  ,Service_Category__c
                                                  ,Setup_Fee_Original__c
                                                  ,Setup_Fee__c
                                                  ,SortOrder
                                                  ,Status__c
                                                  ,TotalPrice
                                                  ,Total_Calced__c
                                                  ,Transaction_Fee__c
                                                  ,Unit__c
                                                  ,User_Override__c
                                              From OpportunityLineItems)
                                          ,(Select Id
                                                  ,ContactId
                                                  ,IsPrimary
                                                  ,OpportunityId
                                                  ,Role
                                              From OpportunityContactRoles)
                                          ,(Select Id
                                                  ,NSS_Source__c
                                                  ,NSS_Team__c
                                                  ,Prospect_Ownership__c
                                                  ,OpportunityId
                                                  ,TeamMemberRole
                                                  ,UserId
                                              From OpportunityTeamMembers)
                                      From Opportunity
                                     Where Id in :opptyIds];
         if (!opptyList.isEmpty()) {
            allOkay = saveOpportunities(opptyList);
         }
      } // if (!opptyIds.isEmpty
      return allOkay;
   } // copyOpportunities
   
   public Boolean saveOpportunities(Opportunity[] opptyList) {
      Boolean allOkay = true;
      Opportunity[] opptysToSave = new Opportunity[]{};

      // for Opportunities where we need to recalc the products
      Id[] opptyIdsToCalc = new Id[]{};

      // allow the process to recalc one opportunity in line. All others will be queued for batch processing.
      Boolean recalcDone = false;
      
      for (AccountWrapper aw : copyWrappers) {
         if (aw.isExisting && aw.recalcOpps) {
            // the number of employees has changed - we need to calculate the opportunities
            // on the parent record the opportunities are stores in the opptys array
            if (aw.isParent && opptys != null && !opptys.isEmpty()) {
               for (OpportunityWrapper ow : opptys) {
                  ow.oppty.Employees_Paid_Per_Payroll__c = aw.acct.Employees__c;
                  opptyIdsToCalc.add(ow.oppty.Id);
                  opptysToSave.add(ow.oppty); 
               }
            } else if (!aw.isParent && aw.acct.Opportunities != null && !aw.acct.Opportunities.isEmpty()) {
               // if not the parent the opps should be attached directly to the account
               for (Opportunity opp : aw.acct.Opportunities) {
                  opp.Employees_Paid_Per_Payroll__c = aw.acct.Employees__c;
                  opptyIdsToCalc.add(opp.Id);
                  opptysToSave.add(opp);
               }
            } // if
         } else if (!aw.isExisting) {
            for (Opportunity oppty : opptyList) {
               OpptyCopyWrapper owc = new OpptyCopyWrapper(oppty, aw.acct, aw.ctctMap);
               opptysToSave.add(owc.oppty);
               aw.opptyCopyWrappers.add(owc);
               /*
               if (!recalcDone && owc.needsRecalc) {
                  ProductCalculator.calcOpptyProducts(runningUser, owc.oppty, owc.olis);
                  owc.needsRecalc = false;
                  recalcDone = true;
               }
               */
            } // for (Opportunity
         } // if (!aw.isParent
      } // for (AccountWrapper aw

      // save the Opportunities
      DmlHelper dh = new DmlHelper();
      allOkay = dh.saveRecords(opptysToSave, null, null, false, true);
      if (allOkay) {
         
         // set the opportunity id on the other records linked to the opportunity
         List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
         List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
         List<OpportunityTeamMember> otms = new List<OpportunityTeamMember>();
         for (AccountWrapper aw : copyWrappers) {
            if (!aw.isExisting) {
               for (OpptyCopyWrapper ocw : aw.opptyCopyWrappers) {
                  // just to make sure okay
                  if (ocw.oppty != null && ocw.oppty.Id != null) {

                     if (ocw.needsRecalc) {
                        opptyIdsToCalc.add(ocw.oppty.Id);
                     }
                  
                     for (OpportunityLineItem oli : ocw.olis) {
                        oli.OpportunityId = ocw.oppty.Id;
                     }
                     olis.addAll(ocw.olis);
                        
                     for (OpportunityContactRole ocr : ocw.ocrs) {
                        ocr.OpportunityId = ocw.oppty.Id;
                     }
                     ocrs.addAll(ocw.ocrs); 
                       
                     for (OpportunityTeamMember otm : ocw.otms) {
                        otm.OpportunityId = ocw.oppty.Id;
                     }
                     otms.addAll(ocw.otms);
                  } // if (ocw.oppty != null
               } // for (OpportunityCopyWrapper
            } // if (!aw.isParent && !aw.isExisting) {
            
         } // for (AccountWrapper
         
         allOkay = dh.saveRecords(olis, null, null, false, true);
         if (allOkay) {
            allOkay = dh.saveRecords(ocrs, null, null, false, true);
         }
         if (allOkay) {
            allOkay = dh.saveRecords(otms, null, null, false, true);
         }
      } // if (allOkay
      
      if (allOkay && !opptyIdsToCalc.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You will receive an email when the recalculation of the Opportunities is complete.'));
         // launch a batch job to process the ids
         ProductCalculatorBatch pcb = new ProductCalculatorBatch();
         pcb.opptyIds = opptyIdsToCalc;
         Database.executeBatch(pcb, 1);
      }
      return allOkay;
   } // saveOpportunities
   
   /** Return to the parent account.
    */
   public PageReference returnToAccount() {
      PageReference returnPr = new PageReference('/'+acct.Id);
      return returnPr;
   } // returnToAccount
    
   public PageReference returnToOpportunity() {
      PageReference returnPr = new PageReference('/'+opptyId);
      System.debug('returnToOpportunity returnPr='+returnPr); 
      return returnPr;
   } // returnToAccount
   
   /** A wrapper class for the Account - to be able to store more information about it.
    */
   public class AccountWrapper {
      // the original wrapper this was made from (for the save routine)
      public AccountWrapper originalAw{get;set;}
      
      public AccountWrapper(Account p_acct, Boolean usePassedInAccount, Integer thisRecNum) {
         curRecNum = thisRecNum;
         if (usePassedInAccount) {
            system.debug('AccountWrapper passed in'+p_acct);
            acct = p_acct;
            comboIndicator = acct.Combo_Client__c;              
            aj = (!acct.Account_Junctions__r.isEmpty() ? acct.Account_Junctions__r[0] : null); 
            origNumOfEmps = Utilities.nvl(acct.Employees__c).intValue();
            //if  
            alreadyRelated = (!acct.Account_Junctions__r.isEmpty() || !acct.Parent_Account__r.isEmpty() ? true : false); 
            system.debug('AccountWrapper alreadyRelated: '+alreadyRelated+''+p_acct); 
         } else {
            acct = new Account(Name=p_acct.Name);
            acct.Frequency__c = p_acct.Frequency__c;
         }
         if (aj == null) {
             system.debug('AccountWrapper aj == null, p_acct: '+p_acct);
             aj = new Account_Junction__c();
         }
         
         // set the isParent flag - first record added is the parent
         isParent = (thisRecNum == 0);
         system.debug('AccountWrapper isParent: '+isParent);
         //isIntegrated = (acct != null && acct.Bis_Id__c != null);
         isExisting = (acct != null && acct.Id != null);
         selectedForDelete = false;
         selectedForRelate = false; 
          
      } // AccountWrapper
       
      // used as part of the saving - this is released after the save.
      public AccountWrapper(AccountWrapper p_aw, Account p_acct, Boolean setParent) {
         System.debug('AccountWrapper used for saving p_acct:'+p_acct);
         System.debug('AccountWrapper used for saving p_aw:'+p_aw);
         System.debug('AccountWrapper used for saving setParent: '+setParent);  
         originalAw = p_aw;
         isParent = p_aw.isParent;
         //isIntegrated = p_aw.isIntegrated;
         isExisting = p_aw.isExisting;
         selectedForDelete = p_aw.selectedForDelete;
         selectedForRelate = p_aw.selectedForRelate; 
         aj = (p_aw.aj != null ? p_aw.aj : null); 
         system.debug('AccountWrapper used for saving aj: '+aj); 
         if (p_aw.isParent) {
            // set the same record
            acct = p_acct;
         } else if (p_aw.isExisting) {
            system.debug('AccountWrapper used for saving p_aw is Existing: '+p_aw);
            acct = p_aw.acct;
            //if existing and relationship type is Delete 
            system.debug('AccountWrapper used for saving p_aw is Existing aj: '+aj);
            if(aj.Type__c != null && aj.Type__c != '' && aj.Type__c == 'Delete Relationship'){
               acct.ParentId = null; 
               acct.SalesParent__c = null;
               System.debug('AccountWrapper used for saving setting ParentId and SalesParent__c to null on existing account junction when type is Delete Relationship: ');
            } else if(setParent){
                // set the parent
                acct.ParentId = p_acct.Id;
                acct.SalesParent__c = p_acct.Id;
//                  if(aj.Type__c == 'Sales Parent-Child' || aj.Type__c == null){
//                    System.debug('AccountWrapper used for saving setting SalesParent__c on new account when type is null or Sales Parent-Child: '+acct.SalesParent__c+' acct.Name: '+acct.Name);
//                  } 
            }    
         } else {
            acct = p_acct.clone(false,true);
            acct.Name = p_aw.acct.Name;
            acct.AccountNumber = p_aw.acct.AccountNumber;
            acct.Employees__c = p_aw.acct.Employees__c;
            acct.NumberOfEmployees = (Integer)p_aw.acct.Employees__c; 
            System.debug('AccountWrapper used for saving acct.Name: '+acct.Name); 
            acct.Consolidate_Primary__c = p_aw.acct.Consolidate_Primary__c;
            acct.Federal_ID_Number__c = p_aw.acct.Federal_ID_Number__c;
            acct.HRO_Number__c = p_aw.acct.HRO_Number__c;
            acct.Frequency__c = p_aw.acct.Frequency__c; 
            // make sure this is null 
            acct.Bis_Id__c = null;
               
            if(setParent){
                // set the parent
                acct.ParentId = p_acct.Id;
                acct.SalesParent__c = p_acct.Id;
//                  if(aj.Type__c == 'Sales Parent-Child' || aj.Type__c == null){
//                    System.debug('AccountWrapper used for saving setting SalesParent__c on new account when type is null or Sales Parent-Child: '+acct.SalesParent__c+' acct.Name: '+acct.Name);
//                  }   
            }
        }          
         recalcOpps = (isExisting && acct.Employees__c != p_aw.origNumOfEmps);
         comboIndicator = p_aw.comboIndicator;
         opptyCopyWrappers = new List<OpptyCopyWrapper>();
         ctcts = new List<Contact>();
      } // AccountWrapper
      
      /** If this is an existing record - do we need to recalculate the opportunities? If the number of employees changes */
      public Boolean recalcOpps = false;
      
      /** The original value for the number of employees. If this changes on existing records we will recalculate the existing opportunities. */
      private Integer origNumOfEmps = 0;
      /** Is this record selected for delete?
          This should only be an option if the record was previously saved (isExisting) and is not part of the feed (!isIntegrated).
       */
      public Boolean selectedForDelete{get;set;}
      public Boolean selectedForRelate{get;set;}
      //when accounts are returned from search but already in a relationship.  
      // a child cannot be related to multiple parents
      // a parent cannot be related as a child causing grandchildren
      public Boolean alreadyRelated{get;set;} 
       
      /* determine if this is part of a combo, and the same values in the fields will indicate which ones are part of the 
         same combo. */
      public String comboIndicator{get;set;}
      
      /** Is this the primary combo client? */
      public Boolean comboPrimary{get;set;}
      /* The unique value for this record. */
      public Integer curRecNum{get;private set;}
      /** The account info */
      public Account acct{get;set;}
      public Account_Junction__c aj{get;set;} 
      
      /** Is this the original account (the starting account) */
      public Boolean isParent{get; private set;}
      /** Is this record part of the integration? If it has a bis id it is - no changes to those records. */
      //public Boolean isIntegrated{get; private set;}
      public Boolean isIntegrated{
         get {return (acct != null && acct.Bis_Id__c != null); }
      } // isIntegrated
      /** Is this an existing record - this was already created before entering the form. */
      public Boolean isExisting{get; private set;}
      //public Boolean isExisting{
      //   get {return (acct != null && acct.Id != null); }
      //} // isExisting
      
      /** For a message that needs to be displayed to the user. */
      public String msg{get;set;}
      
      /** If there's a duplicate account. */
      public Account dupAcct{get;set;}
      
      public String styleColor{get;set;}
      
      /** Map of the contacts that were created from the clone. They are stored by the id of the original contact. */
      public Map<Id,Contact> ctctMap{get;set;}
      
      public List<Contact> ctcts{get;set;}
       
      /** The opportunities that were created from the clone. */
      public List<OpptyCopyWrapper> opptyCopyWrappers{get;set;}

   } // class AccountWrapper
   
   /** A wrapper class for the Contact - to be able to store more information about it.
    */
   public class ContactWrapper {
      public ContactWrapper(Contact p_ctct) {
         ctct = p_ctct;
         selected=false;
      } // ContactWrapper
      
      /* The contact record */
      public Contact ctct{get;set;}
      /* is this record selected? */
      public Boolean selected{get;set;}
   } // class ContactWrapper
   
   /** A wrapper class for the Opportunity - to be able to store more information about it.
    */
   public class OpportunityWrapper {
      public OpportunityWrapper(Opportunity p_oppty) {
         oppty = p_oppty;
         selected = false;
      } // OpportunityWrapper
      
      /* The Opportunity record. */
      public Opportunity oppty{get;set;}
      /* Is this record selected? */
      public Boolean selected{get;set;}
      
   } // class OpportunityWrapper
   
   /** Wrapper used for copying the opportunity and sub classes.
    */
   public class OpptyCopyWrapper {
      public OpptyCopyWrapper(Opportunity p_oppty, Account p_acct, Map<Id,Contact> ctctMap/*, Map<Id,ProductHelper> prodHelperMap,User runningUser*/ ) {
         oppty = p_oppty.clone(false,true);
         // check for the last dash in the name -
         Integer dashPos = oppty.Name.lastIndexOf('-');
         String nameSuffix = (dashPos > -1 ? oppty.Name.subString(dashPos) : '');
         // change the name of the Opportunity to be the incoming account
         oppty.Name = p_acct.Name+nameSuffix;
         // pull over the entire object to reference other portions of it later.
         oppty.RecordType = p_oppty.RecordType;
         
         oppty.AccountId = p_acct.Id;
         // change the employee count to match what's on the company
         oppty.Employees_Paid_Per_Payroll__c = p_acct.Employees__c;
         // set the child indicator
         oppty.Child_Unit__c = true;
         oppty.OppSource__c = 'AccountCloneController';
         
         needsRecalc = false;
         // setup the ancillary objects. They'll be completed after the save of the opportunity
         if (oppty.OpportunityLineItems != null && !oppty.OpportunityLineItems.isEmpty()) {
            for (OpportunityLineItem oli : oppty.OpportunityLineItems) {
               OpportunityLineItem newOli = oli.clone(false,true);
               newOli.PricebookEntry = oli.PricebookEntry;
               // clear out the revenue if number of employees
               // do we only clear out if the number of employees is different? - Yes
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, newOli.PricebookEntry.Product2.Name+' default units='+newOli.PricebookEntry.Product2.Default_Units_to_Employees__c+' curUnit='+newOli.Unit__c+' new emps='+oppty.Employees_Paid_Per_Payroll__c));
               if (oli.PricebookEntry.Product2.Default_Units_to_Employees__c && newOli.Unit__c != oppty.Employees_Paid_Per_Payroll__c) {
                  // change the quantity where appropriate.
                  newOli.Unit__c = oppty.Employees_Paid_Per_Payroll__c;
                  //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, oli.PricebookEntry.Product2.Name+' unit was set to='+newOli.Unit__c));
                  newOli.TotalPrice = 0;
                  needsRecalc = true;
               } // if (oli.PricebookEntry.Product2
               
               olis.add(newOli);
            } // for (OpportunityLineItem

            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'needsRecalc='+needsRecalc));

         } // if (oppty.OpportunityLineItems
         
         if (oppty.OpportunityContactRoles != null && !oppty.OpportunityContactRoles.isEmpty() && ctctMap != null && !ctctMap.isEmpty()) {
            for (OpportunityContactRole ocr : oppty.OpportunityContactRoles) {
               Contact ctct = ctctMap.get(ocr.ContactId);
               if (ctct != null) {
                  OpportunityContactRole newOcr = ocr.clone(false,true);
                  newOcr.ContactId = ctct.Id;
                  ocrs.add(newOcr);
               }
            }
         } // if (oppty.OpportunityContactRoles
         
         if (oppty.OpportunityTeamMembers != null && !oppty.OpportunityTeamMembers.isEmpty()) {
            for (OpportunityTeamMember otm : oppty.OpportunityTeamMembers) {
               OpportunityTeamMember newOtm = otm.clone(false,true);
               otms.add(newOtm);
            }
         } // if (oppty.OpportunityTeamMembers
      } // OpptyCopyWrapper
      
      /* Does this opportunity need to be recalced? */
      public Boolean needsRecalc = false;
      
      public Opportunity oppty{get;set;}
      public List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
      public List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
      public List<OpportunityTeamMember> otms = new List<OpportunityTeamMember>();
   } // class OpptyCopyWrapper
   
   public class AssetWrapper {
    public AssetWrapper(Asset p_asst) {
       asst = p_asst;
       selected = false;
    } // AssetWrapper
    
    public Asset asst{get;set;}
    public Boolean selected{get;set;}
    
   } // class AssetWrapper 
    
   /*  Open issues
      - DONE-if not adding ids skip STEP2 and do not show opp and contact list on verify page
      - DONE-indicate on existing records if recalc of opps will be done-added generic message to indicate it will be done
      - DONE-if adding and removing make sure removed the right ones
      - DONE-confirmation page should indicate correctly what's being done on just an update
      - DONE-when cloning make sure fed id is not carried down - will only carry down for combo records
      - DONE-change delete checkbox to delete link.
      - DONE-make sure retains original combo number when updating records.
   */
   
} // class AccountCloneControllerun