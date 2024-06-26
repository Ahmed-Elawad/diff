/* 
 *  Controller to help with the NSS Audit object.
 
 * History
 * -------
 * 08/12/2014 Dan Carmen       created
 * 01/12/2015 Cindy Freeman	 modified to set status based on NSSUser profile
   06/22/2015 Cindy Freeman    modified to query after all filters are populated, allow Inactive users
   03/31/2016 Dan Carmen       Use the Product_Group_Mapping__c to set the audit product.
   07/20/2016 Dan Carmen       Modification for nss product on the audit/sale record - pay vs mms.
 * 
 */
public with sharing class NSSAuditView {

   public Integer sortColumn{
      get {if (recTypeSales) {
              return 8;
           }
           return 4;}
   } // sortColumn
   
   // the user running the form
   public User runningUser=null;
   
   // the user for whom we're running the form (if running as a supervisor or above)
   public User nssSalesUser{get; set;}
   
   // has a user been selected to audit with?
   public Boolean nssSalesUserSelected{
      get {return nssSalesUser != null;}
   }
     
   public String defaultStatus{get; private set;}
      
   public Boolean hasNssUserOptions{
      get {return nssUserOptions != null && nssUserOptions.size() > 1;}
   }
   // The available NSRs to choose from. 
   public List<SelectOption> nssUserOptions{get;set;}
   public Map<Id,User> nssUserMap = new Map<Id,User>();
   // Which user is selected. 
   public String selectedNssUser{get;set;}
    
   public Boolean promptForUser {get;private set;}
   // used to prompt for the user to enter audits for (if not an NSR)
   public NSSAudit__c askForUser {get; set;}
   // prompt for a sales rep to filter on opportunity owner
   public NSSAudit__c salesRepFilter {get; set;}
   // filter on the opportunity and prospect-client name
   public String nameFilter{get;set;}
   
   public NSSView__c nssView{get;set;}
   // used for the NSS Sales data
   public NSSView__c salesDates{get;set;}
   
   public Boolean isNSR=false;

   public NSSAdministrationController adminControl {get;set;}

   public NSSAuditView() {
      runningUser = UserHelper.getRunningUser();
      adminControl = new NSSAdministrationController();
      
      // is the running user an nsr, supervisor/manager, or system admin?
      askForUser = new NSSAudit__c(NSR_Name__c = runningUser.Id);
      salesRepFilter = new NSSAudit__c();
      
      // if not an NSR, open up the prompt for a user. The user will have to be in the role hierarchy to allow to proceed.
      isNSR = (runningUser.Job_Name__c == UserHelper.JOB_NSR);
      if (isNSR) {
         nssSalesUser = runningUser;
      }
      promptForUser = (!isNSR && adminControl.hasFormAccess);
      if (adminControl.isSupervisor) {
         nssUserOptions = getUsers(runningUser);
      }
      
      nssView = new NSSView__c();
      salesDates = new NSSView__c();
      
      setupDates();
      setupPageOptions();
      setupProductTypes();
      searchedForRecords = false;
      // retrieveData();      CMF do this later

      //setOppsWithoutAudits();
      //if (!hasOpps) {
      //   System.debug('NSSAuditView no opps');
      //   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'No Qualifying Opportunities were found!'));
      //}
   } // NSSAuditView
   
   // a supervisor is selected from the list
   public PageReference supervisorSelected() {
      if (adminControl.selectedSupervisorFrom != NSSAdministrationController.NONE) {
         User supervisor = adminControl.availableSupervisorMap.get(adminControl.selectedSupervisorFrom);
         if (supervisor != null) {
            nssUserOptions = getUsers(supervisor);
         }
      } // if (selectedNssUser
      return null;
   } // supervisorSelected
   
   // if a new name is entered in the form
   public void askForUserChanged() {
      nssSalesUser = nssUserMap.get((Id)selectedNssUser);                
      /*
   	User checkUser = null;
   	if (askForUser.NSR_Name__c != null) {
   	   checkUser = [Select Id, Name, HR_Person_Id__c, Sales_Org__c, Profile.Name, UserRoleId, UserRole.ParentRoleId, Title from User where Id=:askForUser.NSR_Name__c and IsActive=true];   	   
   	}
      // if the user is system admin, allow to proceed
      Boolean okayToUse = (checkUser != null && UserHelper.isSystemAdmin(runningUser));
      // otherwise ensure that the selected user is in the running user's heirarchy
      if (!okayToUse && checkUser != null) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'In setReferralUser - checkUser is selected'));
         // make sure the user is in the running user's role hierarchy if not system admin
         // get the child role ids
         System.debug('askForUserChanged before getAllSubRoleIds');
         Set<Id> roleIds = new UserHelper().getAllSubRoleIds(new Set<ID>{runningUser.UserRoleId});
         System.debug('askForUserChanged after getAllSubRoleIds nbrIds='+roleIds.size());
         if (!roleIds.contains(checkUser.UserRoleId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can only Audit NSS Sales for users that are in your Role Hierarchy!'));
         } else {
            okayToUse = true;
         }
      } // if (!okayToUse
      
      if (okayToUse) {
         nssSalesUser = checkUser;
         retrieveData();
      } else {
         nssSalesUser = runningUser;
         askForUser.NSR_Name__c = runningUser.Id;
      }
      defaultStatus = (nssSalesUser.Profile.Name.contains('Inbound')?Label.NSS_Sales_View_Default_Inbound_Status:Label.NSS_Sales_View_Default_Status);
      */

      askForUser.NSR_Name__c = nssSalesUser.Id;
      searchedForRecords = false;
      displayList = new List<NSSViewWrapper>();

   } // askForUserChanged
   
   public Boolean recTypeOpps{ get {return (String.isNotBlank(selectedOppType) && selectedRecType==OPTION_OPPS); }}
   public Boolean recTypePending{ get {return (String.isNotBlank(selectedOppType) && selectedRecType==OPTION_PENDING); }}
   public Boolean recTypeSales{ get {return (String.isNotBlank(selectedOppType) && selectedRecType==OPTION_SALES_1); }}
   
   public static String OPTION_ALL='All';
   public static String OPTION_OPEN_SOLD='Open and Sold';
   public static String OPTION_OPEN='Open Only';
   public static String OPTION_SOLD='Sold Only';
   public static String OPTION_NOT_SOLD='Not Sold Only';
   
   public static String OPTION_OPPS='Opportunities-No Sales Record';
   public static String OPTION_PENDING='Pending Sales';
   public static String OPTION_SALES_1='Sales from Commissions';

   // which type of opportunities do we display?
   public String selectedOppType{get;set;}
   
   public List<SelectOption> oppTypeOptions{get;set;}
   
   // which type of records are we displaying?
   public String selectedRecType{get;set;}
   
   public List<SelectOption> recTypeOptions{get;set;}
   
   public void setupPageOptions() {
      oppTypeOptions = new List<SelectOption>();
      // default to this type
      selectedOppType = OPTION_OPEN_SOLD;
      oppTypeOptions.add(new SelectOption(OPTION_ALL,OPTION_ALL));
      oppTypeOptions.add(new SelectOption(OPTION_OPEN_SOLD,OPTION_OPEN_SOLD));
      oppTypeOptions.add(new SelectOption(OPTION_OPEN,OPTION_OPEN));
      oppTypeOptions.add(new SelectOption(OPTION_SOLD,OPTION_SOLD));
      oppTypeOptions.add(new SelectOption(OPTION_NOT_SOLD,OPTION_NOT_SOLD));
      
      recTypeOptions = new List<SelectOption>();
      selectedRecType = OPTION_OPPS;
      recTypeOptions.add(new SelectOption(OPTION_OPPS,OPTION_OPPS));
      recTypeOptions.add(new SelectOption(OPTION_PENDING,OPTION_PENDING));
      recTypeOptions.add(new SelectOption(OPTION_SALES_1,OPTION_SALES_1));

   } // setupPageOptions

   // query for records   
   public void findRecords() {
      retrieveData();
   } // findRecords
   
   // set the filter criteria   
   public void applyFilters() {
      retrieveData();
   } // applyFilters
   
   public void setRecType() {
      searchedForRecords = false;
      displayList = new List<NSSViewWrapper>();
      //retrieveData();
   } // setRecType
   
   public static final String PGM_MAPPING_TYPE='NSSSales';
   
   public String[] productTypeList = null;
   
   public String selectedProductType{get;set;}
   
   public List<SelectOption> prodTypeOptions{get;set;}
   
   public String[] productNameList = null;
   
   public String[] selectedProductNames{get;set;}
   
   public List<SelectOption> prodNameOptions{get;set;}

   public void setupProductTypes() {
   	if (productTypeList == null) {
         Set<String> productTypeSet = new Set<String>();
         Set<String> productNameSet = new Set<String>();
         
         for (ProductGroupMapping__c pgm : ProductGroupMapping__c.getAll().values()) {
            if (pgm.MappingType__c == PGM_MAPPING_TYPE) {
               productTypeSet.add(pgm.ProductType__c);
               productNameSet.add(pgm.Product_of_Interest__c);
            }
         } // for (ProductGroupMapping__c pgm
      
         productTypeList = new String[]{};
         productTypeList.addAll(productTypeSet);
         productTypeList.sort();
      
         prodTypeOptions = new List<SelectOption>();
         prodTypeOptions.add(new SelectOption(OPTION_ALL,OPTION_ALL));
         selectedProductType = OPTION_ALL;
      
         for (String productType : productTypeList) {
            prodTypeOptions.add(new SelectOption(productType,productType));
         }
         
         productNameList = new String[]{};
         productNameList.addAll(productNameSet);
         productNameList.sort();
         
         prodNameOptions = new List<SelectOption>();
         prodNameOptions.add(new SelectOption(OPTION_ALL,OPTION_ALL));
         selectedProductNames = new String[]{OPTION_ALL};
      
         for (String productName : productNameList) {
            prodNameOptions.add(new SelectOption(productName,productName));
         }

   	} // if (productTypeList
   } // setupProductTypes
   
   // the controller we are using
   public ApexPages.StandardSetController selectedController{get;set;}
   
   // The opportunity records returned as a result of the query. 
   public ApexPages.StandardSetController opportunityRecs{get;set;}
   
   // Is there a list to display to the user?
   public Boolean hasDisplayList{
      get {return (displayList != null && !displayList.isEmpty()); }
   }
   
   public Boolean searchedForRecords{get; set;}
   
   public List<NSSViewWrapper> displayList{
      get {
         if (displayList == null && selectedController != null) {
         	OpptyMethods.setupRecordTypeMap();
         	displayList = new NSSViewWrapper[]{};
         	// search for existing ownership records
         	Map<Id,NSSViewWrapper> searchForOwnershipMap = new Map<Id,NSSViewWrapper>();
         	
         	for (SObject rec : selectedController.getRecords()) {
         		if (recTypeOpps) {
         		   Opportunity opp = (Opportunity)rec;
                  NSSViewWrapper newWrapper = new NSSViewWrapper(opp);
                  newWrapper.po = OpptyMethods.foundPo;
                  Prospect_Ownership__c po = (opp.OpportunityTeamMembers != null && !opp.OpportunityTeamMembers.isEmpty() ? opp.OpportunityTeamMembers[0].Prospect_Ownership__r : null);
                  //newWrapper.nssAudit = OpptyMethods.createNewAudit(opp.Account, opp, OpptyMethods.byIdMap.get(opp.RecordTypeId), po, Label.NSS_Sales_View_Default_Status,'NSS Sales View');
                  newWrapper.nssAudit = OpptyMethods.createNewAudit(opp.Account, opp, OpptyMethods.byIdMap.get(opp.RecordTypeId), po, defaultStatus,'NSS Sales View-Opp');
                                    
                  displayList.add(newWrapper);
         		} else if (recTypePending) {
         	      NSSAudit__c audit = (NSSAudit__c)rec;
         	      NSSViewWrapper newWrapper = new NSSViewWrapper(audit.Opportunity__r);
         	      newWrapper.nssAudit = audit;
         	      displayList.add(newWrapper);
         		} else if (recTypeSales) {
         		   NSSSalesOppLink__c oppLink = (NSSSalesOppLink__c)rec;
         		   NSSViewWrapper newWrapper = new NSSViewWrapper(oppLink);
         		   searchForOwnershipMap.put(oppLink.Opportunity__c,newWrapper);
                  searchForOwnershipMap.put(oppLink.NSSSalesProduct__c,newWrapper);
                  ProductGroupMapping__c pgm = (oppLink.NSSSalesProduct__r != null ? NSSSalesMethods.getMapping(oppLink.NSSSalesProduct__r.Name) : null);
                  String nssProduct = (pgm != null ? pgm.Product_Group__c : null);
                  if (String.isNotBlank(nssProduct) && nssProduct == UserHelper.SO_CORE && oppLink.NSSSalesProduct__r.SalesRep__r != null && oppLink.NSSSalesProduct__r.SalesRep__r.Sales_Org__c==UserHelper.SO_MMS) {
                     nssProduct = UserHelper.SO_MMS;
                  }
                 
                  newWrapper.nssAudit = OpptyMethods.createNewAudit(oppLink.Opportunity__r.Account, oppLink.Opportunity__r, OpptyMethods.byIdMap.get(oppLink.Opportunity__r.RecordTypeId), nssProduct, oppLink.Prospect_Ownership__r, defaultStatus,'NSS Sales View-Sale',oppLink.NSSSalesProduct__r.OfficeNumber__c);
                  newWrapper.nssAudit.Client_Number2__c = OpptyMethods.formatClientNumber2(newWrapper.oppLink.NSSSalesProduct__r.OfficeNumber__c,newWrapper.oppLink.NSSSalesProduct__r.ClientNumber__c);
                  newWrapper.nssAudit.Run_Submit_Date__c = newWrapper.oppLink.NSSSalesProduct__r.FirstRunDate__c;
                  newWrapper.nssAudit.NSSSalesProduct__c = newWrapper.oppLink.NSSSalesProduct__c;
                  displayList.add(newWrapper);
         		}
         		
         	} // for (SObject

            if (recTypeSales && !searchForOwnershipMap.isEmpty()) {
               checkForNSSSalesRecords(searchForOwnershipMap);
            }
         } // if (displayList == null
         return displayList;
      } // get
      private set;
   } // displayList

   // see if there are any existing NSS Sales Records - attach to displayList
   private void checkForNSSSalesRecords(Map<Id,NSSViewWrapper> searchForOwnershipMap) {
   	
      NSSAudit__c[] nssSales = [Select Id
                                      ,NSR__c
                                      ,NSR_Name__c
                                      ,NSSSalesProduct__c
                                      ,NSS_Source__c
                                      ,NSS_Team__c
                                      ,Opportunity__c
                                      ,Product__c
                                      ,Run_Submit_Date__c
                                      ,Account__c
                                      ,BranchNumber__c
                                      ,Client_Number2__c
                                      ,Prospect_Ownership__c
                                      ,Source__c
                                      ,Status__c
                                 From NSSAudit__c
                                Where NSR_Name__c = :nssSalesUser.Id
                                  and (NSSSalesProduct__c in :searchForOwnershipMap.keySet() or Opportunity__c in :searchForOwnershipMap.keySet())
                                  and Status__c != 'Rejected'
                                ];
   
      for (NSSAudit__c sale : nssSales) {
      	NSSViewWrapper thisWrapper = null;
      	// check the product link first - if this exists, should be a solid match.
      	if (sale.NSSSalesProduct__c != null) {
      	   thisWrapper = searchForOwnershipMap.get(sale.NSSSalesProduct__c);
      	}
         // only check the opportunity if not already linked to a product.
         if (thisWrapper == null && sale.NSSSalesProduct__c == null) {
            thisWrapper = searchForOwnershipMap.get(sale.Opportunity__c);
         }
         if (thisWrapper != null) {
            thisWrapper.nssAudit = sale;
         }
      } // for (NSSAudit__c sale
      
   } // checkForNSSSalesRecords
   
   // Goto the next page of records. 
   public void next() {
      displayList = null;
      selectedController.next();
   } // next

   // Goto the previous page of records. 
   public void previous() {  
      displayList = null;
      selectedController.previous();  
   } // previous    

   // Goto the next page of records.
   public void firstPage() {
      displayList = null;
      selectedController.first();
   } // next

   // Goto the previous page of records. 
   public void lastPage() {  
      displayList = null;
      selectedController.last();  
   } // previous    

   // The total number of pages available.
   public Integer numOfPages {
      get {
         if (numOfPages == null) {
            
            numOfPages = 1;
            if (selectedController != null) {
               decimal result = Decimal.valueOf(selectedController.getResultSize()) / Decimal.valueOf(selectedController.getPageSize());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'numOfPages resultsize='+ownershipRecs.getResultSize()+' pageSize='+ownershipRecs.getPageSize()+' result='+result));
               numOfPages = (result.round(System.RoundingMode.CEILING)).intValue();
            }
         } // if (numOfPages
         return numOfPages;
      } // get
      private set;
   } // numOfPages

   public void retrieveData() {
      displayList = null;
      searchedForRecords = true;

      defaultStatus = (nssSalesUser.Profile.Name.contains('Inbound')?Label.NSS_Sales_View_Default_Inbound_Status:Label.NSS_Sales_View_Default_Status);

      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'retrieveData nssSalesUser='+nssSalesUser.Name+' recTypeOpps='+recTypeOpps+' recTypePending='+recTypePending+' recTypeSales='+recTypeSales));
   	selectedController = null;
      opportunityRecs = null;
      pendingSalesController = null;

      if (recTypeOpps) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'retrieveData recTypeOpps'));
         selectedController = getAllUnassignedOpps();
      } else if (recTypePending) {
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'retrieveData recTypePending'));
      	selectedController = getPendingSales();
      } else if (recTypeSales) {
      	setupProductTypes();
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'retrieveData getSales'));
      	selectedController = getSales();
      }
   } // retrieveData

   public static Integer RECS_PER_PAGE = Integer.valueOf(Label.NSS_Audit_View_Max_Recs);
   
   public ApexPages.StandardSetController getAllUnassignedOpps() {
      
      String oppType = (String.isBlank(selectedOppType) ? OPTION_OPEN_SOLD : selectedOppType);
      Date startDate = nssView.StartDate__c;
      Date endDate = nssView.EndDate__c;
      
      Id userId = nssSalesUser.Id;
      String query = 'Select Id, IsClosed, IsWon, AccountId, Account.Id, Account.AccountNumber, Account.Name '+
                     '             ,Name, CloseDate, StageName, RecordTypeId, RecordType.Name, CreatedDate '+
                     '             ,OwnerId, Owner.Name, Owner.LastName, Owner.FirstName, Owner.District__c '+
                     '             ,(Select Id, UserId, CommissionEnd__c, CommissionStart__c '+
                     '                     ,Prospect_Ownership__c '+
                     '                     ,Prospect_Ownership__r.Id '+
                     '                     ,Prospect_Ownership__r.NSR_NSS_Team__c '+
                     '                     ,Prospect_Ownership__r.NSS_Source__c '+
                     '                     ,Prospect_Ownership__r.NSR_Name__c '+
                     '                 from OpportunityTeamMembers where UserId=\''+userId+'\') '+ // where UserId=:userId) '+
                     '         From Opportunity '+
                     '        Where Id in (Select OpportunityId from OpportunityTeamMember where UserId=:userId and Prospect_Ownership__c != null) '+
                     '          and Id not in (Select Opportunity__c from NSSAudit__c where OwnerId=:userId) '+
                     '          and CloseDate >= :startDate '+
                     '          and CloseDate <= :endDate ';
      
      if (oppType == OPTION_OPEN_SOLD) {
         query += ' and ((IsClosed = false) or (IsClosed = true and IsWon = true)) ';
      } else if (oppType == OPTION_OPEN) {
         query += ' and IsClosed = false ';
      } else if (oppType == OPTION_SOLD) {
         query += ' and IsClosed = true and IsWon = true ';
      } else if (oppType == OPTION_NOT_SOLD) {
         query += ' and IsClosed = true and IsWon = false ';
      }
      if (String.isNotBlank(nameFilter)) {
      	query += ' and (Name like \''+nameFilter+'%\' or Account.Name like \''+nameFilter+'%\' )';
      }
      if (salesRepFilter.NSR_Name__c != null) {
         query += ' and OwnerId=\''+salesRepFilter.NSR_Name__c+'\' '; 
      }
      Integer allowedRows = Limits.getLimitQueryLocatorRows() - Limits.getQueryLocatorRows();
      query += ' order by CloseDate desc limit '+allowedRows;
         
      opportunityRecs = new ApexPages.StandardSetController(Database.getQueryLocator(query));
      opportunityRecs.setPageSize(RECS_PER_PAGE); 
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'getAllUnassignedOpps resultsize='+opportunityRecs.getResultSize()+' pageSize='+opportunityRecs.getPageSize()));

      return opportunityRecs; 
   } // getAllUnassignedOpps

   public ApexPages.StandardSetController pendingSalesController{get;set;}
   
   public ApexPages.StandardSetController getPendingSales() {
      
      Date startDate = nssView.StartDate__c;
      Date endDate = nssView.EndDate__c;
      
      Id userId = nssSalesUser.Id;

      pendingSalesController = new ApexPages.StandardSetController(Database.getQueryLocator([
                    Select Id, BranchNumber__c, Client_Number2__c, Product__c, Run_Submit_Date__c, Status__c
                          ,Opportunity__c
                          ,Opportunity__r.Id
                          ,Opportunity__r.AccountId
                          ,Opportunity__r.Account.AccountNumber
                          ,Opportunity__r.Name
                          ,Opportunity__r.OwnerId
                          ,Opportunity__r.Owner.Id
                          ,Opportunity__r.Owner.District__c
                          ,Opportunity__r.CloseDate
                          ,Opportunity__r.CreatedDate
                          ,Opportunity__r.StageName
                          ,Account__c
                      From NSSAudit__c
                     Where NSR_Name__c = :userId
                       and Status__c='Pending'
                      order by Run_Submit_Date__c desc
             ]));
      pendingSalesController.setPageSize(RECS_PER_PAGE); 
      return pendingSalesController;
   } // getPendingSales

   public ApexPages.StandardSetController salesController1{get;set;}

   // retrieve the sales data for the specified user
   public ApexPages.StandardSetController getSales() {

      Id userId = nssSalesUser.Id;
      Date startDate = salesDates.StartDate__c;
      Date endDate = salesDates.EndDate__c;
      
      String[] selectedProductTypes = new String[]{};
      if (String.isBlank(selectedProductType) || selectedProductType == OPTION_ALL) {
         selectedProductTypes.addAll(productTypeList);
      } else {
         selectedProductTypes.add(selectedProductType);
      }


      String[] v_selectedProductNames = new String[]{};
      
      if (selectedProductNames == null || selectedProductNames.isEmpty() || selectedProductNames[0] == OPTION_ALL) {
         v_selectedProductNames.addAll(productNameList);
      } else {
         v_selectedProductNames = selectedProductNames;
      }
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'getSales selectedProductNames='+selectedProductNames+' numRecs='+selectedProductNames.size()+' v_selectedProductNames='+v_selectedProductNames));

      salesController1 = new ApexPages.StandardSetController(Database.getQueryLocator([
                    Select Id, Name
                          ,CommissionEnd__c
                          ,CommissionStart__c
                          ,LinkInfo__c
                          ,NSSSalesClient__c
                          ,NSSSalesClient__r.Id
                          ,NSSSalesClient__r.Name
                          ,NSSSalesProduct__c
                          ,NSSSalesProduct__r.Id
                          ,NSSSalesProduct__r.Name
                          ,NSSSalesProduct__r.AuditProduct__c
                          ,NSSSalesProduct__r.ClientNumber__c
                          ,NSSSalesProduct__r.CommissionRevenue__c
                          ,NSSSalesProduct__r.ContractRevenue__c
                          ,NSSSalesProduct__r.FirstRunDate__c
                          ,NSSSalesProduct__r.NumberOfChecks__c
                          ,NSSSalesProduct__r.OfficeNumber__c
                          ,NSSSalesProduct__r.ProductCode__c
                          ,NSSSalesProduct__r.ProductType__c
                          ,NSSSalesProduct__r.SalesRep__c
                          ,NSSSalesProduct__r.SalesRep__r.Id
                          ,NSSSalesProduct__r.SalesRep__r.District__c
                          ,NSSSalesProduct__r.SalesRep__r.Sales_Org__c
                          ,NSSSalesProduct__r.SalesRepName__c
                          ,Opportunity__c
                          ,Opportunity__r.Id
                          ,Opportunity__r.Name
                          ,Opportunity__r.AccountId
                          ,Opportunity__r.Account.Id
                          ,Opportunity__r.Account.AccountNumber
                          ,Opportunity__r.Account.Name
                          ,Opportunity__r.CloseDate
                          ,Opportunity__r.CreatedById
                          ,Opportunity__r.CreatedDate
                          ,Opportunity__r.OwnerId
                          ,Opportunity__r.Owner.Id
                          ,Opportunity__r.Owner.District__c
                          ,Opportunity__r.RecordTypeId
                          ,Opportunity__r.StageName
                          ,OtherLinkInfo__c
                          ,Prospect_Ownership__c
                          ,Prospect_Ownership__r.Id
                          ,Prospect_Ownership__r.CommissionEnd__c
                          ,Prospect_Ownership__r.CommissionStart__c
                          ,Prospect_Ownership__r.DaysLeftInStage__c
                          ,Prospect_Ownership__r.NSR_Name__c
                          ,Prospect_Ownership__r.NSS_Source__c
                          ,Prospect_Ownership__r.NSR_NSS_Team__c
                          ,Prospect_Ownership__r.NSS_Team__c
                          ,Prospect_Ownership__r.Ownership_Status__c
                          ,Rejected__c
                      From NSSSalesOppLink__c
                     Where Prospect_Ownership__r.NSR_Name__c = :userId
                       and NSSSalesProduct__r.FirstRunDate__c >= :startDate
                       and NSSSalesProduct__r.FirstRunDate__c <= :endDate
                       and Rejected__c=false
                       and NSSSalesProduct__r.ProductType__c in :selectedProductTypes
                       and NSSSalesProduct__r.Name in :v_selectedProductNames
                       and UseInAudit__c = true
                      order by NSSSalesClient__r.Name asc, NSSSalesProduct__r.FirstRunDate__c desc
             ]));


      salesController1.setPageSize(RECS_PER_PAGE); 
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'getSales resultsize='+salesController1.getResultSize()+' pageSize='+salesController1.getPageSize()));
      return salesController1;
   } // getSales

   public void setupDates() {
      // beginning of previous month and end of current month
      nssView.StartDate__c = Date.today().addMonths(-1).toStartOfMonth();
      nssView.EndDate__c = Date.today().addMonths(1).toStartOfMonth().addDays(-1);
      
      // set to calendar year?
      //nssView.StartDate__c = Date.newInstance(Date.today().year(), 1, 1);
      //nssView.EndDate__c = Date.newInstance(Date.today().year(), 12, 31);

      //nssView.StartDate__c = Date.today().toStartOfMonth();
      // go to the end of the month
      //nssView.EndDate__c = Date.today().addMonths(1).toStartOfMonth().addDays(-1);
      
      // default dates for the sales data
      //salesDates.StartDate__c = Date.today().addDays(-7);
      //salesDates.EndDate__c = Date.today().addDays(1);
      // for now keep a wide range 
      salesDates.StartDate__c = Date.today().addMonths(-1).toStartOfMonth();
      salesDates.EndDate__c = Date.today().addMonths(1).toStartOfMonth().addDays(-1);
   } // setupDates
   
   public Boolean selectAllOption{get;set;}

   public void moveSelectedToBadMatch() {
   	NSSSalesOppLink__c[] rejectLinks = new NSSSalesOppLink__c[]{};
      for (NSSViewWrapper nssWrapper : displayList) {
         if (nssWrapper.selected) {
            nssWrapper.oppLink.Rejected__c = true;
            rejectLinks.add(nssWrapper.oppLink);
         }
      } // for (NSSViewWrapper
      
      if (!rejectLinks.isEmpty()) {
         update rejectLinks;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, rejectLinks.size()+' bad matches were updated'));  //Label.NSS_Sales_View_Default_Status));
      }
   } // moveSelectedToBadMatch

   public void saveAuditRecords() {
   	saveRecords(null);
   } // saveAuditRecords
   
   public void savePendingSales() {
   	//saveRecords(Label.NSS_Sales_View_Default_Status);
   	//saveRecords(checkUser.Profile.Name.contains('Inbound')?Label.NSS_Sales_View_Default_Inbound_Status:Label.NSS_Sales_View_Default_Status);
   	saveRecords(defaultStatus);
   } // savePendingSales
   
   public void cancelPendingSales() {
      saveRecords('Cancelled');
   }
   private void saveRecords(String status) {
      NSSAudit__c[] saveAudits = new NSSAudit__c[]{};
      //for (NSSViewWrapper nssWrapper : oppsWithoutAudits) {
      for (NSSViewWrapper nssWrapper : displayList) {
         if (nssWrapper.selected) {
            //NSSAudit__c audit = new NSSAudit__c(Opportunity__c=nssWrapper.oppty.Id, Account__c=nssWrapper.oppty.AccountId, Prospect_Ownership__c=nssWrapper.po.Id, Status__c='Pending', OwnerId=nssWrapper.po.NSR_Name__c);
            //newAudits.add(audit);
            if (status != null) {
               nssWrapper.nssAudit.Status__c = status;
            }
            saveAudits.add(nssWrapper.nssAudit);
         } // if (nssWrapper.selected
      } // for (NSSViewWrapper nssWrapper
      
      if (!saveAudits.isEmpty()) {
         try {
         	if (recTypePending) {
               update saveAudits;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, saveAudits.size()+' Sale record(s) moved to '+ defaultStatus));  //Label.NSS_Sales_View_Default_Status));
               		
         	} else if (recTypeOpps) {
               insert saveAudits;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, saveAudits.size()+' Sale record(s) created.'));
         	} else if (recTypeSales) {
               upsert saveAudits;
               ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, saveAudits.size()+' Sale record(s) saved.'));
         	}
            retrieveData();
         } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error saving new Sale records: '+e));
         }
      } else {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No records were selected!'));
      }
   } // saveRecords
   
   public static String NONE='None';
   
   // Get all of the NSRs who report to the passed in user (based on Role Hierarchy)
   //    @param parentUser - the supervisor to start with
   //    @param selectingTransferTo - Are we performing the query to transfer to? If yes, only active, do not clear user map.
   //    @param excludeId - is there a user we need to exclude?
   public List<SelectOption> getUsers(User parentUser) {

      List<SelectOption> userOptions = new List<SelectOption>();
      //Set<Id> inactiveIds = new Set<Id>();     
      nssUserMap.clear();
      nssUserMap.put(runningUser.Id, runningUser);

      //userOptions.add(new SelectOption(NONE,'--Select a User--'));
      // always set the running user as an option
      userOptions.add(new SelectOption(runningUser.Id, runningUser.Name));
      selectedNssUser = runningUser.Id;
      nssSalesUser = runningUser;
 
      String whereClause = 'where ((UserRole.ParentRoleId=\''+parentUser.UserRoleId+'\' ';
      // only select NSRs
      Integer numInactiveMonths = 8;
      try {
         numInactiveMonths = Integer.valueOf(Label.NssAuditInactiveMonths);
      } catch (Exception e) {}
      string compareDate = DateTime.now().addMonths(-numInactiveMonths).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

      whereClause += ' and Job_Name__c=\''+UserHelper.JOB_NSR+'\') ';
      whereClause += ' and (IsActive = true or (IsActive = false and LastLoginDate >= '+string.escapeSingleQuotes(compareDate)+'))';
      
      whereClause += ')';
      whereClause +=' order by LastName, FirstName ';
      
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'whereClause='+whereClause));
      User[] users = new UserHelper().getUsers(whereClause);
 

      for (User usr : users) {
         // store the users in a map for easy reference
         nssUserMap.put(usr.Id,usr);
         userOptions.add(new SelectOption(usr.Id,usr.Name+(!usr.IsActive ? '-INACTIVE' : '')));
      } // for (User usr

      return userOptions;
   } // getUsers
   
        
} // class NSSAuditView