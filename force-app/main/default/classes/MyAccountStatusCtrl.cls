public without sharing class MyAccountStatusCtrl {
    public WrapperData wrapperDataObj {get; set;}
    public String unlockTier {get;set;}
    public Boolean isShowModelPopup {get;set;}
    public Boolean acceptTermAndCondition {get;set;} 
    public Boolean chkDisabled {get;set;} 
    private Id currentUserId;
    public List<OpportunityWrapper> oppWrapperList {get;set;}
    public List<AccountWrapper> acctWrapperList {get;set;}
    public List<OpportunityWrapper> oppWarpperListWith10 {get;set;}
    public List<AccountWrapper> acctWarpperListWith10 {get;set;}
    
    public OpportunityPagination oppPagination {get;set;}
    public AccountPagination acctPagination {get;set;}
    private PaginationWrapper paginationWrapper;

    private List<User> userLst;
    
    public MyAccountStatusCtrl() {
        init();
    }
    
    public void loadOppMoreResult() {
        generatePageNumber(oppPagination);
        if(oppWrapperList.size() > Integer.valueOf(oppPagination.defaultValue)){
            loadOppInList(0, Integer.valueOf(oppPagination.defaultValue)-1);
        }else{
            loadOppInList(0, oppWrapperList.size()-1);
        }
        
    }
    
    public void handleOppIsNext() {
        oppPagination.pagenumber++;
        hanldeOppPageNumber();
    }
    
    public void hanldeOppPageNumber() {
        System.debug('oppWrapperList:'+oppWrapperList);
        if(oppWrapperList.size() > 0) {
            if(Integer.valueOf(oppPagination.defaultValue) > oppWrapperList.size()-1) {
                loadOppInList(0, oppWrapperList.size()-1);
            }
            else if(oppPagination.pagenumber==1) {
                loadOppInList(0, oppPagination.pagenumber*(Integer.valueOf(oppPagination.defaultValue)-1));
            }
            else if(oppPagination.pagenumber < oppPagination.noOfPages) {
                loadOppInList(Integer.valueOf(oppPagination.defaultValue)*(oppPagination.pagenumber-1), (oppPagination.pagenumber*Integer.valueOf(oppPagination.defaultValue)) -1);
            }
            else{
                loadOppInList(Integer.valueOf(oppPagination.defaultValue)*(oppPagination.pagenumber-1), oppWrapperList.size()-1);
            }
        }
        
    }
    
    public void loadAcctMoreResult() {
        generatePageNumber(acctPagination);
        if(acctWrapperList.size() > Integer.valueOf(acctPagination.defaultValue)){
            loadAcctInList(0, Integer.valueOf(acctPagination.defaultValue)-1);
        }else{
            loadAcctInList(0, acctWrapperList.size()-1);
        }
    }
    
    public void handleAcctIsNext() {
        acctPagination.pagenumber++;
        hanldeAcctPageNumber();
    }
    
    public void hanldeAcctPageNumber() {
        if(acctWrapperList.size() > 0) {
            if(Integer.valueOf(acctPagination.defaultValue) > acctWrapperList.size()-1) {
                System.debug('hanldeAcctPageNumber if');
                loadAcctInList(0, acctWrapperList.size()-1);
            }
            else if(acctPagination.pagenumber==1) {
                 System.debug('hanldeAcctPageNumber else if');
                loadAcctInList(0, acctPagination.pagenumber*(Integer.valueOf(acctPagination.defaultValue)-1));
            }
            else if(acctPagination.pagenumber < acctPagination.noOfPages) {
                System.debug('hanldeAcctPageNumber else if 2');
                System.debug('hanldeAcctPageNumber else if 2+++++++' + Integer.valueOf(acctPagination.defaultValue)*(acctPagination.pagenumber-1));
				System.debug('hanldeAcctPageNumber else if 2>>>>>>>>>>+++++++' +  (acctPagination.pagenumber*Integer.valueOf(acctPagination.defaultValue) -1));
                loadAcctInList(Integer.valueOf(acctPagination.defaultValue)*(acctPagination.pagenumber-1), (acctPagination.pagenumber*Integer.valueOf(acctPagination.defaultValue)) -1);
            }
            else {
                System.debug('hanldeAcctPageNumber else');
                loadAcctInList(Integer.valueOf(acctPagination.defaultValue)*(acctPagination.pagenumber-1), acctWrapperList.size()-1);
            }
        }
    }
    
    private void loadData() {
        System.debug('Inside Load Data');
        this.userLst = [SELECT Id, IsActive, ContactId, Username, FirstName, LastName, Email, Requested_Invite_Date__c, Community_User_First_Login__c,CPA_Terms_and_conditions_accepted_on__c, Contact.Mirror_Ref_Ctct__c, Contact.Mirror_Ref_Ctct__r.Admin_CPA__c, Contact.Mirror_Ref_Ctct__r.CPA_portal_shared__c  FROM User WHERE Id = :currentUserId LIMIT 1];
        system.debug('userLst:'+userLst);
        if(!userLst.isEmpty()) {
            Referral_Contact__c refCont = [SELECT Id, Admin_CPA__c, CPA_portal_shared__c, Referral_Account__c, Referral_Account__r.MutualClientNextTier__c, Referral_Account__r.MutualClientTier__c,
                                           Referral_Account__r.Account__c, CPA_Program_status__c, Contact__c
                                           FROM Referral_Contact__c WHERE Id = :userLst[0].Contact.Mirror_Ref_Ctct__c AND Referral_Account__c != null LIMIT 1];
            
            wrapperDataObj.mutualClientTier = refCont.Referral_Account__r.MutualClientTier__c;
            wrapperDataObj.mutualClientNextTier = (Integer)refCont.Referral_Account__r.MutualClientNextTier__c;
            System.debug('Inside Load Data wrapperDataObj:'+wrapperDataObj);
             System.debug('Inside Load Data wrapperDataObj.mutualClientTier:'+wrapperDataObj.mutualClientTier);
             System.debug('Inside Load Data wrapperDataObj.mutualClientNextTier:'+wrapperDataObj.mutualClientNextTier);
            displayImage( wrapperDataObj.mutualClientTier);
            loadOpportunity(refCont);
            loadMutialClients(refCont);
            loadServiceTableData();
            if(userLst[0].CPA_Terms_and_conditions_accepted_on__c == null) {
                this.isShowModelPopup = true;
                this.acceptTermAndCondition = false;
                this.chkDisabled = false;
                
            }
        }
    }
    
    /*public Boolean disableButton{get;set;}
    public Boolean chkBx{get;set;}
    public String input{get;set;}       
    public void click(){    
         if(acceptTermAndCondition == true){
             this.disableButton = false;
         }
         //return null;
    }*/
    
    /*public pagereference logout(){
       //perform Business logic here
        PageReference pageRef = new PageReference('https://paychex--josh.sandbox.my.site.com//secur/logout.jsp');
        pageRef.setRedirect(true);
        return pageRef;
    }*/
    
    public PageReference hideModelPopup() {
        If(acceptTermAndCondition==false)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Please accept the Terms and Conditions');
            ApexPages.addMessage(myMsg);
        }
        else{
            System.debug('Inside hideModelPopup');
            this.isShowModelPopup = false;
            this.acceptTermAndCondition = true;
            
            if(!userLst.isEmpty()) {
                List<User> userListForUpdate = new List<User>();
                for(User userObj : this.userLst) {
                    userObj.CPA_Terms_and_conditions_accepted_on__c = System.now();//Date.today();
                    userObj.Community_User_First_Login__c = System.now();//Date.today(); 
                    userListForUpdate.add(userObj);
                }
                if(!userListForUpdate.isEmpty()) {
                    update userListForUpdate;
                }
            }
            if(!userLst.isEmpty() && userLst[0].Contact.Mirror_Ref_Ctct__c !=null) {
                Boolean admCpaUpd = true;
                Referral_Contact__c refCont = [SELECT Id, Admin_CPA__c, Referral_Account__c, CPA_Program_status__c
                                               FROM Referral_Contact__c WHERE Id = :userLst[0].Contact.Mirror_Ref_Ctct__c AND Referral_Account__c != null LIMIT 1];
                System.debug('hideModelPopup: Admin CPA check');
                System.debug('hideModelPopup refCont:'+refCont);
                System.debug('hideModelPopup refCont Admin CPA:'+refCont.Admin_CPA__c);
                if(refCont != null && refCont.Admin_CPA__c == false){
                    List<Referral_Contact__c> allRefConts = [SELECT Id, Admin_CPA__c, Referral_Account__c, CPA_Program_status__c 
                                                             FROM Referral_Contact__c WHERE Referral_Account__c = :refCont.Referral_Account__c];
                    if(allRefConts!= null && allRefConts.size()>0){
                        for(Referral_Contact__c refCon: allRefConts){
                            if(refCon.Admin_CPA__c){
                                admCpaUpd = false;
                                break;
                            }
                        }
                    }
                }
                if(admCpaUpd){
                    refCont.Admin_CPA__c = true;
                    refCont.CPA_portal_shared__c = 'Yes';
                    update refCont;
                }
            }
            
            init();
        }
        
        //JDA Testing:start

        //JDA Testing:End
        
        
        return null;
        //return isShowModelPopup;
    }
    
    /*public PageReference RerenderPage() {
        PageReference tempPage = ApexPages.currentPage();            
        tempPage.setRedirect(true);
        return tempPage;
        //return null;
    }*/
    
    /** WRAPPER CLASS DEFINITION - START **/
    
    public without sharing class WrapperData {
        public Referral_Account__c refAcct {get; set;}
        public String mutualClientTier {get; set;}
        public Integer mutualClientNextTier {get; set;}
        public Integer acceptedOpp {get; set;}
        public Integer successfullOpp {get; set;}
        public String coreDisplay {get;set;}
        public String eliteDisplay {get;set;}
        public List<Account_Status_Table_Data__mdt> acctStatusTableDataList {get;set;}
        public String signatureDisplay {get;set;}
        
        {
            coreDisplay = 'none';
            eliteDisplay = 'none';
            signatureDisplay = 'none';
            acctStatusTableDataList = new List<Account_Status_Table_Data__mdt>();
        }
    }
    
    public without sharing class  OpportunityWrapper {
        public String oppName {get;set;}
        public Date leadSubmittedDate {get;set;}
    }
    
    public without sharing class  AccountWrapper {
        public String acctName {get;set;}
        public DateTime lastmodifiedDate {get;set;}
        public String rcName {get;set;}
    }
    
    public abstract without sharing class PaginationWrapper {
        public List<SelectOption> pageSizeList {get; set;}
        public String defaultValue {get;set;}
        public Boolean isNext {get;set;}
        public List<Integer> pageNumberList {get; set;}
        public Integer pagenumber {get; set;}
        public Integer listSize=0;
        public Integer noOfPages = 0;
    }
    
    public without sharing class OpportunityPagination extends PaginationWrapper {
        
    }
    
    public without sharing class AccountPagination extends PaginationWrapper {
        
    }
    
    public PageReference redirectToReferClientPage() {
        return Page.ReferClient;
    }
    

    private void loadOpportunity(Referral_Contact__c refCont) {
        System.debug('Inside loadOpportunity');
        wrapperDataObj.acceptedOpp = 0;
        wrapperDataObj.successfullOpp = 0;
        Set<String> oppSoldStageNames = new Set<String>();

        for(String oppStage : System.Label.Opp_Sold_Stages.split(';')) {
            oppSoldStageNames.add(oppStage);
        }
        
        for(Opportunity opp : [SELECT Id,AccountId,Name, Account.Name, LastmodifiedDate, CloseDate, StageName, OwnerId, Referral_Contact__c, ReferralContact__c, Date_Lead_Submitted__c,Referral_Account__c 
            from Opportunity WHERE (OpportunityType__c ='Add-On ID' OR OpportunityType__c='Payroll' OR OpportunityType__c=: Label.Payroll_HR_Pro)
            AND  (Referral_Account__c = :refCont.Referral_Account__c)
            AND  (IsClosed = false)
            ORDER BY Name]) {
            Boolean isOppAddInTable = false;         
            if(refCont.CPA_portal_shared__c == 'Yes') {
                if(oppSoldStageNames.contains(opp.StageName)) {
                    wrapperDataObj.successfullOpp += 1;
                }
                else {
                    wrapperDataObj.acceptedOpp += 1;
                    isOppAddInTable = true;
                }
            }
            else {
                if(opp.Referral_Contact__c == refCont.Id) {
                    if(oppSoldStageNames.contains(opp.StageName)) {
                        wrapperDataObj.successfullOpp += 1;
                    }
                    else {
                        wrapperDataObj.acceptedOpp += 1;
                        isOppAddInTable = true;
                    }
                }
            }
            if(isOppAddInTable) {
                OpportunityWrapper oppWrapper = new OpportunityWrapper();
                oppWrapper.oppName = opp.Account.Name;
                oppWrapper.leadSubmittedDate = opp.Date_Lead_Submitted__c;
            }
        }
        for (PartnerReferral__c pref : [SELECT Referral__r.SourceLead__r.Company, Referral__r.DateLeadSubmitted__c
                                        FROM PartnerReferral__c
                                        WHERE PartnerContact__c =: refCont.Contact__c
                                        AND Referral__r.Selling_Opportunity__c = null
                                        AND Referral__r.SourceLead__r.Company != null
                                        ORDER BY Referral__r.SourceLead__r.Company ASC]) {
            OpportunityWrapper oppWrapperReferral = new OpportunityWrapper();
            oppWrapperReferral.oppName = pref.Referral__r.SourceLead__r.Company;
            oppWrapperReferral.leadSubmittedDate = pref.Referral__r.DateLeadSubmitted__c;
            oppWrapperList.add(oppWrapperReferral);
        }
        oppPagination.listSize = oppWrapperList.size();
        System.debug('Inside loadOpportunity oppWrapperList:'+oppWrapperList);
        System.debug('Inside loadOpportunity oppWrapperList.size():'+oppWrapperList.size());
        if(oppWrapperList.size()>10) {
        	loadOppInList(0,9);
        }
        else{
            oppWarpperListWith10.clear();
            for(Integer i = 0; i <oppWrapperList.size() ; i++) {
                oppWarpperListWith10.add(oppWrapperList[i]);
            }
        }
        generatePageNumber(oppPagination);
    }
    
    @TestVisible
    private void loadMutialClients(Referral_Contact__c refCont) {
        System.debug('Inside Load mutual Clients');
        //old query:  [SELECT Id, Name, Mirror_Referral_Account__c, LastModifiedDate From Account WHERE CPA_Name_Ref__c = :refCont.Id ORDER BY Name]
        //new Query: [SELECT Id, Name, Mirror_Referral_Account__c, LastModifiedDate, CPA_Name_Ref__c, CPA_Name_Ref__r.Name, CPA_Name_Ref__r.Referral_Account__c From Account WHERE CPA_Name_Ref__r.Referral_Account__c = :refCont.Referral_Account__c ORDER BY Name]
        if(refCont.CPA_portal_shared__c == 'No' || refCont.CPA_portal_shared__c == '' || refCont.CPA_portal_shared__c == null) {
            List<Account> mutualClients =  [SELECT Id, Name, Mirror_Referral_Account__c, LastModifiedDate, CPA_Name_Ref__c, CPA_Name_Ref__r.Name, CPA_Name_Ref__r.Referral_Account__c From Account 
                                            WHERE CPA_Name_Ref__r.Id = :refCont.Id AND CurrentClient__c = true
                                            ORDER BY Name];
            System.debug('Inside loadMutialClients refCont.CPA_portal_shared__c No mutualClients:'+mutualClients);
            if(mutualClients.size()>0){
                for(Account mutualClient : mutualClients){
                    AccountWrapper acctWrapper = new AccountWrapper();
                    acctWrapper.acctName = mutualClient.Name;
                    acctWrapper.lastmodifiedDate = mutualClient.LastModifiedDate;
                    acctWrapper.rcName = mutualClient.CPA_Name_Ref__r.Name;
                    acctWrapperList.add(acctWrapper);
                }
            }		
        }
        else{
            for(Account mutualClient : [SELECT Id, Name, Mirror_Referral_Account__c, LastModifiedDate, CPA_Name_Ref__c, CPA_Name_Ref__r.Name, CPA_Name_Ref__r.Referral_Account__c From Account 
                                        WHERE CPA_Name_Ref__r.Referral_Account__c = :refCont.Referral_Account__c AND CurrentClient__c = true 
                                        ORDER BY Name]) {
                                            Boolean isAcctAddInTable = false;
                                            if(refCont.CPA_portal_shared__c == 'Yes') { 
                                                isAcctAddInTable = true;
                                            }
                                            else {
                                                if(refCont.Referral_Account__c == mutualClient.Mirror_Referral_Account__c) {
                                                    isAcctAddInTable = true;
                                                }
                                            }
                                            if(isAcctAddInTable) {
                                                AccountWrapper acctWrapper = new AccountWrapper();
                                                acctWrapper.acctName = mutualClient.Name;
                                                acctWrapper.lastmodifiedDate = mutualClient.LastModifiedDate;
                                                acctWrapper.rcName = mutualClient.CPA_Name_Ref__r.Name;
                                                acctWrapperList.add(acctWrapper);
                                            }
                                        }
        }
        System.debug('Inside Load mutual Clients acctWrapperList:'+acctWrapperList);
        System.debug('Inside Load mutual Clients acctWrapperList.size():'+acctWrapperList.size());
        acctPagination.listSize = acctWrapperList.size();
        if(acctWrapperList.size()>10) {
        	loadAcctInList(0,9);
        }
        else{
            //acctWrapperList.clear();
            for(Integer i = 0; i <acctWrapperList.size() ; i++) {
                acctWarpperListWith10.add(acctWrapperList[i]);
            }
        }
        generatePageNumber(acctPagination);
    }
    
    @TestVisible
    private void loadOppInList(Integer first, Integer last) {
        oppWarpperListWith10.clear();
        for(Integer i = first; i <= last ; i++) {
            oppWarpperListWith10.add(oppWrapperList[i]);
        }
    }
    
    @TestVisible
    private void loadAcctInList(Integer first, Integer last) {
        System.debug('loadAcctInList first:'+first);
        System.debug('loadAcctInList last:'+last);
        acctWarpperListWith10.clear();
        for(Integer i = first; i <= last ; i++) {
            acctWarpperListWith10.add(acctWrapperList[i]);
        }
        System.debug('loadAcctInList acctWarpperListWith10:'+acctWarpperListWith10);
    }
    
    @TestVisible
    private void displayImage(String acctProgTier) {
         unlockTier = 'Elite';
        if(acctProgTier == 'Core') {
            unlockTier = 'Signature';
            wrapperDataObj.coreDisplay = 'block';
        }
        else if(acctProgTier == 'Signature') {
            unlockTier = 'Elite';
            wrapperDataObj.signatureDisplay = 'block';
        }
       	else if(acctProgTier == 'Elite') {
            wrapperDataObj.eliteDisplay = 'block';
        }
    }
    
    private void loadServiceTableData() {
        wrapperDataObj.acctStatusTableDataList = [SELECT IsCore__c, IsElite__c, IsSignature__c, Service__c, DeveloperName, DisplayOrder__c,ToolTipText__c  FROM Account_Status_Table_Data__mdt Where (NOT Service__c Like 'Single Dedicated%') ORDER BY DisplayOrder__c ASC];
    }
    
    private void generatePageNumber(PaginationWrapper paginationWrapper) {
        paginationWrapper.isNext = false;
        Integer qud = paginationWrapper.listSize / Integer.valueOf(paginationWrapper.defaultValue);
        Integer pagesize = (paginationWrapper.listSize- (Integer.valueOf(paginationWrapper.defaultValue) *qud)) > 0 ? qud + 1 : qud;
        paginationWrapper.pageNumberList = new List<Integer>();
        paginationWrapper.noOfPages = pagesize;
        if(pageSize > 5) {
            paginationWrapper.isNext = true;
        }
        for(Integer obj =1; obj <= pagesize; obj++) {
            if(obj<=5) {
            	paginationWrapper.pageNumberList.add(obj);
            }
        }
    }
    
    private void populateOppPageSizeList() {
        Integer defaultRange = oppPagination.listSize/10;
        for(Integer i=1; i<=defaultRange+1;i++) {
            String range = String.valueOf((i*10));
        	oppPagination.pageSizeList.add(new SelectOption(range,range));
        }
	}
    
    private void populateAcctPageSizeList() {
        Integer defaultRange = acctPagination.listSize/10;
        for(Integer i=1; i<=defaultRange+1;i++) {
            String range = String.valueOf((i*10));
        	acctPagination.pageSizeList.add(new SelectOption(range,range));
        }
	}
    
    private void init() {
        System.debug('Inside Init');
        currentUserId = UserInfo.getUserId();
        oppPagination = new OpportunityPagination();
        acctPagination = new AccountPagination();
      //	currentUserId = '00575000001Knje';
        isShowModelPopup = false;
        acceptTermAndCondition = false;
        wrapperDataObj = new WrapperData();
        oppWrapperList = new List<OpportunityWrapper>();
        acctWrapperList = new List<AccountWrapper>();
        initOppPagination();
        initAcctPagination();
        loadData();
        populateOppPageSizeList();
        populateAcctPageSizeList();
        
    }
    
    private void initOppPagination() {
        paginationWrapper = oppPagination;
        oppWarpperListWith10 = new List<OpportunityWrapper>();
        initPaginationValues();
    }
    
    private void initAcctPagination() {
        paginationWrapper = acctPagination;
        acctWarpperListWith10 = new List<AccountWrapper>();
        initPaginationValues();
    }
	
	private void initPaginationValues() {
        paginationWrapper.defaultValue = '10';
        paginationWrapper.pagenumber = 1;
        paginationWrapper.pageSizeList = new List<SelectOption>();
    }    
	
}