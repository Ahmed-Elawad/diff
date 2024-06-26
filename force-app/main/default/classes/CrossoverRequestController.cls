/* 
*The methods used for creating and/or updating
* a group of accounts based off of a parent.
*
* History
* -------
* 10/29/2009 Dan Carmen         Created
08/04/2011 Dan Carmen           Fix for NullPointerException
03/14/2012 Dan Carmen           Added cc: emails for DSM/DSAs
08/21/2012 Dan Carmen           Change for Direct Sales to receive crossover requests.
11/12/2012 Dan Carmen           Remove logic for Operations Owner - user was disabled.
08/29/2013 Dan Carmen           Fix for asking for DSA, clean up code
09/10/2013 Dan Carmen           Change from Direct Sales to Virtual Sales
03/10/2016 Jacob Hinds          Allow crossover to account team, allow for multiple crossover choices.  Major rewrite of code.
9/28/2016 Justin Stouffer       Re-wrote to work better in SF1
11/28/2016 Cindy Freeman         modified approve/reject urls in email, now users must click Save when approving or rejecting request
01/17/2017 Cindy Freeman        added check, if account.isChild__c don't allow crossover
02/23/2018 Sunnish Annu         added the PAY Salesorg to CC the Managers in the CrossoverRequest Email
06/15/2018 Carrie Marciano      Added check for PEOC to evaluate extra ownership criteria
10/09/2018 Jacob Hinds          Adding sales org into query for DSA.  Sales org needed to set Owner Type field on txfer request to get the correct expiration
02/08/2019 Josh Cartwright      per case: 31767951 removed the approve and reject links. Email now only contains a link to the crossover    
06/12/2019 Jacob Hinds          Commenting out PEO extra criteria
09/11/2019 Matt Fritschi        Added constructor for Crossovers created on bank lead conversion.
02/12/2020 Matt Fritschi        If the Account Owner is inactive or null, try to send the Crossover to the DSA/DSM.
03/24/2020 Michael Karcz        Added Crossover Extension Request functionality
05/13/2020 Dan Carmen           Changes to PEO Owner to be its own field.
07/20/2020 Jermaine Stukes		Update SalesforceURL	
05/06/2021 Dan Carmen           Pull out the query to a different method so it's only in code once.
02/22/2022 Carrie Marciano      Added BenAdmin Holdout fields
03/08/2022 Dan Carmen           Removed old custom lat and long fields.
03/30/2022 Dan Carmen           Update logic for findSendRequestToUser
11/16/2022 Carrie Marciano		Converted queryAcct to use fieldset and Label.ZipCheckOwner_ExtraAcctFlds

*/
public without sharing class CrossoverRequestController {
    public Boolean finished{get;private set;}
    
    /* Is this displaying in Salesforce1? */
    public Boolean isSF1 {get; set;}
    
    public Account thisAcct{get;set;}
    
    /** The user requesting the crossover.
*/
    public User crossoverUser{get;private set;}
    
    public SalesOrg__c so{get;private set;}
    
    public boolean hasAcct {
        get {return (thisAcct != null); }
    } // hasAcct
    
    /** Is this an automatically approved transfer?
*/
    public Boolean isTransfer{get; private set;}
    
    public String getReturnButtonTitle() {
        String title='Return to Prospect-Client';
        if (isTransfer) {
            return 'Transfer Ownership and '+title;
        }
        return title;
    } // getReturnButtonTitle
    
    /** The host the visual page is running on. */
    private String host = null;
    
    /** Get the status flag saying that if this crossover request cannot be completed.
*/
    public Boolean cannotComplete{get;private set;}
    
    public Boolean crossoverOkay {get; private set;}
    
    //public String[] getCrossoverFields{get; set;}
    
    public Boolean currentOwnerSubmission {get;set;}
    
    public Boolean crossoverExtension {get;set;}
    
    public Boolean recipientSelected{get;private set;}
    
    public Boolean multipleRecipients{get;set;}
    
    public String selectedRecipient{get;set;}
    
    private ObjectHelper objectHelper = new ObjectHelper();
    
    public List<String> extraRecipients = new List<String>();
    /*   
public String getEmailBody() {
String msg = 'I have a Crossover Request for the following Prospect-Client. The Territory Rep of this Prospect-Client cannot be determined.';
msg += '%0A%0A'+getMessageBody(false,'%0A');
return msg;
} // getEmailBody
*/
    
    /** The status used when a request should be sent to a DSA. */
    public static final String DSA_STATUS='Send to DSA';
    /** The submitted status. */
    public static final String STATUS_SUBMIT='Submitted';
    /** The approved status. */
    public static final String STATUS_APPROVED='Approved';
    /** Transferred status - equivalent to Approved. */
    public static final String STATUS_TXFER='Transferred';
    
    /** The main owner field on the record. */
    public static final String OWNER_MAIN='OwnerId';
    /** The HRS owner field on the record. */
    public static final String OWNER_HRS='HRS_Account_Owner__c';
    /** The HRS Large Market owner field on the record. */
    public static final String OWNER_LRG='Large Market 401(k) Partner';
    /** The Premier owner field on the record. */
    public static final String OWNER_PREMIER='Premier_PBS_Account_Owner__c';
    /** The HNB owner field. */
    public static final String OWNER_HNB='HNBF_Account_Owner__c';
    /** The HNB owner field. */
    public static final String OWNER_MS='Merchant Services Representative';
    
    /** Which owner field to user. Default to main Owner. */
    public String ownerFieldType{get;private set;}
    
    public boolean includeCrossoverUser = false;
    public String convertedLeadType ='';
    
    // fields we can't add into the fieldset because the layers go too deep.
    public static String[] extraQueryFields = Label.ZipCheckOwner_ExtraAcctFlds.split(',');
    public static String ATM_QUERY=',(Select TeamMemberRole, UserId, User.Name, User.Profile.Name, User.Email, User.Sales_Org__c, User.IsActive, User.Job_Name__c, User.UserRole.ParentRoleId, User.UserRole.Name, User.Manager.Email, User.DSA_FSS__r.Email from AccountTeamMembers ) ';
    
    // for testing
    public CrossoverRequestController(Account p_acct) {
       thisAcct = p_acct;
    } // CrossoverRequestController
    
    public CrossoverRequestController(Account p_acct, String leadType) {
        
        List<Account> acctList = new List<Account>();
        acctList.add(p_acct);
        //zipCheckOwner.setupRecordTypeMaps();
        //zipCheckOwner.processAccounts(acctList, true);
        crossoverExtension = false;
        convertedleadType=leadType;
        System.debug('CrossoverRequestController p_acct='+p_acct.Id);
        thisAcct = queryAcct(p_acct.Id);

        System.debug('CrossoverRequestController thisAcct.Id='+thisAcct.Id+' thisAcct.OwnerId='+thisAcct.OwnerId);
        Date expireDate = Utilities.getNextBusinessDay(1);
        request = new Transfer_Request__c(Account__c = thisAcct.Id, OwnerId = thisAcct.OwnerId, Comments__c='Lead was Converted', Status__c=STATUS_SUBMIT, Account_Owner__c = thisAcct.OwnerId, Auto_Approve_Date__c = expireDate);
        
        crossoverUser = [Select Id, Name, Sales_Org__c, Email, Job_Name__c, UserRole.ParentRoleId, UserRole.Name
                         ,Manager.Email
                         ,DSA_FSS__c
                         ,DSA_FSS__r.Email
                         ,Profile.Name
                         from User where Id = :UserInfo.getUserId()];
        System.debug('CrossoverRequestController1 crossoverUser='+crossoverUser);
        cannotComplete = false;
        System.debug('leadtype='+convertedLeadType);
        
        if(convertedLeadType == 'Payroll')
        {
            System.debug('Setting the org as PAY');
            selectedRecipient = OWNER_MAIN;
            so = SalesOrg__c.getValues('PAY');
        }
        else if(convertedLeadType == '401k')
        {
            System.debug('Setting the org as HRS');
            selectedRecipient = OWNER_MAIN;
            so = SalesOrg__c.getValues('HRS');
        }
        
        System.debug('SalesOrg='+so);
        
        
        checkTransferRequest();
        setRecipient();
        multipleRecipients = false;
        //request.Send_Request_To__c = thisAcct.OwnerId;
        request.Comments__c = 'Bank Lead was converted.';
        request.Account_Owner__c = thisAcct.OwnerId;
        //request.Owner_Field__c=thisAcct.OwnerId;
        System.debug('SalesOrg='+so);
        //System.debug(thisAcct.Confidence_Code__c);
        if(thisAcct.OwnerId!=UserInfo.getUserId())
        {
            submitRequest(); 
        }
        
    }
    /* The extension constructor initializes the private member
variable acct by using the getRecord method from the standard
controller.
*/
    public CrossoverRequestController(ApexPages.StandardController stdController) {
        // default valuesgetUrl
        isTransfer = false;
        cannotComplete = false;
        finished = false;
        isSF1 = Utilities.isSF1();
        host = Utilities.getInstanceURL()+'/';
        crossoverExtension = false;
        crossoverOkay = true;
        crossoverUser = [Select Id, Name, Sales_Org__c, Email, Job_Name__c, UserRole.ParentRoleId, UserRole.Name
                         ,Manager.Email
                         ,DSA_FSS__c
                         ,DSA_FSS__r.Email
                         ,Profile.Name
                         from User where Id = :UserInfo.getUserId()];
        system.debug('crossoverRequestController crossoverUser: '+crossoverUser);
        
        Id id = System.currentPageReference().getParameters().get('id');
        
        thisAcct = queryAcct(id);

        if (thisAcct == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Prospect-Client record was found. One must be passed into this form in order to use it.'));
            System.debug('finished=true No Prospect-Client record was found. One must be passed into this form in order to use it.');
            finished = true;
        }
        else if (thisAcct.isChild__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Please go to the Sales Parent of this Prospect-Client to submit a Crossover Request.'));
            System.debug('finished=true Please go to the Sales Parent of this Prospect-Client to submit a Crossover Request.');
            finished = true;
        }
        else if (!String.isBlank(thisAcct.Permanent_Hold_Out_Description__c) && containsExcludedHO(thisAcct.Permanent_Hold_Out_Description__c)) {   
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This account is not eligible for crossovers for the following reason: ' + thisAcct.Permanent_Hold_Out_Description__c));   
            System.debug('finished=true This account is not eligible for crossovers for the following reason: ' + thisAcct.Permanent_Hold_Out_Description__c);
            finished = true;    
        }
        else{
            checkTransferRequest();
                /*System.debug('CLM return from checkTransferRequest before check crossoverUser.Profile.Name ' + crossoverUser.Profile.Name + ' and Account Type ' + thisAcct.Type + ' Owner Profile Name: ' 
                + thisAcct.Owner.Profile.Name);
                system.debug('CLM System.Label.Profile_PEO_Centric ' + System.Label.Profile_PEO_Centric); 
                if(thisAcct.Owner.Profile.Name == System.Label.Profile_PEO_Centric || (crossoverUser.Profile.Name == System.Label.Profile_PEO_Centric && thisAcct.Type!='PEO Prospect')){
                system.debug('CLM before call to PeoHelper class');
                //PEOHelper to see if PEOC can take over
                Map<Id,PeoHelper.PeoWrapper> peocCrossMap = PeoHelper.checkAccountsForPeo(acctIds,False,False);
                System.debug('CLM peoCrossMap from PeoHelper ' + peocCrossMap);
                if(!peocCrossMap.isEmpty()){
                    System.debug('peocCrossMap.get(Id).okayForPeo= '+peocCrossMap.get(Id).okayForPeo+' peocCrossMap.get(Id).notOkayReason= '+peocCrossMap.get(Id).notOkayReason); 
                    crossoverOkay = peocCrossMap.get(Id).okayForPeo;
                    if(!crossoverOkay){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, peocCrossMap.get(Id).notOkayReason)); 
                        finished = true;  
                    }   
                }  
        } */ 
            
            //Check to see how many options they have to choose from for the crossover owner.  If there's only one options, don't make them choose.  The options they have are set in the
            //Sales_Org custom setting
            List<SelectOption> options = getFieldOptions();
            if(options==null){
                finished = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You are not setup to request a Crossover! Sales Org='+crossoverUser.Sales_Org__c));
                System.debug('finished=true You are not setup to request a Crossover! Sales Org='+crossoverUser.Sales_Org__c);
                recipientSelected = false;
                multipleRecipients = false;
                return;
            }
            else if(options.size() > 1){
                recipientSelected = false;
                multipleRecipients = true;
            }
            else if (options.size() == 1){
                selectedRecipient = options[0].getValue();
                system.debug('CrossoverRequestController recipient:'+selectedRecipient);
                //recipientSelected = true;
                setRecipient();
                multipleRecipients = false;
            }    
        }
        
    } // CrossoverRequestController
    
    public static String QUERY_CACHE_KEY='CRAcctQueryCacheKey';
    
    public Account queryAcct(Id acctId) {
        Account acct = null;
        if (acctId != null) {
          String query = (String)CacheManager.getOrg(QUERY_CACHE_KEY);
          if (query == null) {               
             Set<String> fldSet = new Set<String>();
             DmlHelper.addFieldsToSet(Schema.SObjectType.Account.fieldSets.CrossoverRequestFlds, '', fldSet);
             DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CrossoverRequestFlds, 'Owner.', fldSet);
             DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CrossoverRequestFlds, 'HRS_Account_Owner__r.', fldSet);
             DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CrossoverRequestFlds, 'HNBF_Account_Owner__r.', fldSet);
             DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CrossoverRequestFlds, 'Premier_PBS_Account_Owner__r.', fldSet);
             DmlHelper.addFieldsToSet(Schema.SObjectType.User.fieldSets.CrossoverRequestFlds, 'OasisPEOAccountOwner__r.', fldSet); 
             
             fldSet.addAll(extraQueryFields);
             // add special fields for ownership checks
             fldSet.addAll(ZipQueries.getAccountQueryFields());
             query = DmlHelper.buildQueryFromSet(fldSet, null);
             
             query += ATM_QUERY;
             query += ' FROM Account WHERE Id = :acctId  ';
             System.debug('getAcctQuery query='+query);
             CacheManager.putOrg(QUERY_CACHE_KEY,query);
          }
            
          acct = Database.query(query);  
       /*     // this query should be updated to use fieldsets to be dynamic
            acct = [SELECT Id, Name, Site, AccountNumber 
                        ,OwnerId
                        ,Owner.Id
                        ,Owner.Name
                        ,Owner.Profile.Name
                        ,Owner.Email
                        ,Owner.Sales_Org__c
                        ,Owner.IsActive
                        ,Owner.Job_Name__c
                        ,Owner.UserRole.ParentRoleId
                        ,Owner.UserRole.Name
                        ,Owner.Manager.IsActive
                        ,Owner.DSA_FSS__r.IsActive
                        ,Owner.Manager.Email
                        ,Owner.DSA_FSS__r.Email
                        ,Owner.ProfileId
                        ,HRS_Hold_Out__c
                        ,HRS_Hold_Out_Expiration__c
                        ,HRS_Account_Owner__c
                        ,HRS_Account_Owner__r.Id
                        ,HRS_Account_Owner__r.Name
                        ,HRS_Account_Owner__r.Profile.Name
                        ,HRS_Account_Owner__r.Email
                        ,HRS_Account_Owner__r.Sales_Org__c
                        ,HRS_Account_Owner__r.IsActive
                        ,HRS_Account_Owner__r.Job_Name__c
                        ,HRS_Account_Owner__r.UserRole.ParentRoleId
                        ,HRS_Account_Owner__r.UserRole.Name
                        ,HRS_Account_Owner__r.Manager.Email
                        ,HRS_Account_Owner__r.DSA_FSS__r.Email
                        ,Premier_PBS_Hold_Out__c
                        ,Premier_PBS_Hold_Out_Expiration__c
                        ,PEO_ASO_Permanent_Hold_Out_Description__c
                        ,Premier_PBS_Account_Owner__c
                        ,Premier_PBS_Account_Owner__r.Id
                        ,Premier_PBS_Account_Owner__r.Name
                        ,Premier_PBS_Account_Owner__r.Profile.Name
                        ,Premier_PBS_Account_Owner__r.Email
                        ,Premier_PBS_Account_Owner__r.Sales_Org__c
                        ,Premier_PBS_Account_Owner__r.IsActive
                        ,Premier_PBS_Account_Owner__r.Job_Name__c
                        ,Premier_PBS_Account_Owner__r.UserRole.ParentRoleId
                        ,Premier_PBS_Account_Owner__r.UserRole.Name
                        ,Premier_PBS_Account_Owner__r.Manager.Email
                        ,Premier_PBS_Account_Owner__r.DSA_FSS__r.Email
                        ,HNBF_Hold_Out__c
                    	,HNBF_Permanent_Hold_Out_Description__c
                    	,HNBF_Hold_Out_Expiration__c
                    	,HNBF_Account_Owner__c
                        ,HNBF_Account_Owner__r.Id
                        ,HNBF_Account_Owner__r.Name
                        ,HNBF_Account_Owner__r.Profile.Name
                        ,HNBF_Account_Owner__r.Email
                        ,HNBF_Account_Owner__r.Sales_Org__c
                        ,HNBF_Account_Owner__r.IsActive
                        ,HNBF_Account_Owner__r.Job_Name__c
                        ,HNBF_Account_Owner__r.UserRole.ParentRoleId
                        ,HNBF_Account_Owner__r.UserRole.Name
                        ,HNBF_Account_Owner__r.Manager.Email
                        ,HNBF_Account_Owner__r.DSA_FSS__r.Email
                        ,OasisPEOHoldOut__c
                        ,OasisPEOHoldOutExpiration__c
                        ,OasisPEOHoldOutReason__c
                        ,OasisPEOAccountOwner__c
                        ,OasisPEOAccountOwner__r.Id
                        ,OasisPEOAccountOwner__r.Name
                        ,OasisPEOAccountOwner__r.Profile.Name
                        ,OasisPEOAccountOwner__r.Email
                        ,OasisPEOAccountOwner__r.Sales_Org__c
                        ,OasisPEOAccountOwner__r.IsActive
                        ,OasisPEOAccountOwner__r.Job_Name__c
                        ,OasisPEOAccountOwner__r.UserRole.ParentRoleId
                        ,OasisPEOAccountOwner__r.UserRole.Name
                        ,OasisPEOAccountOwner__r.Manager.Email
                        ,OasisPEOAccountOwner__r.DSA_FSS__r.Email
                        ,MS_Hold_Out__c
                    	,MS_Hold_Out_Expiration__c
                    	,MS_Permanent_Hold_Out_Description__c
                        ,TAA_Holdout__c
                        ,TAA_Holdout_Expiration__c
                        ,TAA_Permanent_Holdout_Description__c
                    	,BenAdmin_Hold_Out__c
						,BenAdmin_Hold_Out_Expiration__c
						,BenAdmin_Hold_Out_Reason__c
                        ,Previous_Owner_Id__c
                        ,isChild__c
                        ,Hold_Out__c
                        ,Hold_Out_Expiration__c
                        ,Permanent_Hold_Out_Description__c
                        ,(Select TeamMemberRole, UserId, User.Name, User.Profile.Name, User.Email, User.Sales_Org__c, User.IsActive
                          , User.Job_Name__c, User.UserRole.ParentRoleId, User.UserRole.Name, User.Manager.Email, User.DSA_FSS__r.Email
                          FROM AccountTeamMembers)
                        ,RecordTypeId,RecordType.Name
                        ,X401K_Assets__c
                        ,CSSR_Segment__c
                        ,CurrentClient__c
                        ,Hispanic_Ownership__c
                        ,PEOLeasing__c
                        ,NumberOfEmployees
                        ,SegmentationCore1__c
                        ,Phone, Fax, Type
                        ,BillingStreet, BillingCity, BillingState, BillingPostalCode
                        ,ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode
                        ,Owner_Zip_Code__c
                        FROM Account WHERE Id=:acctId];
            //system.debug('acct'+acct);  */
        } // if (acctId != null   
        return acct;
    } // queryAcct
    
    //This is used to populate the list of what owner field they can choose to crossover for. The options they have are set in the Sales_Org custom setting
    public List<SelectOption> getFieldOptions(){
        so = SalesOrg__c.getValues(crossoverUser.Sales_Org__c);
        if(so!=null){
            String[] fieldValues = so.Crossover_Fields__c.split(',');
            Map<String,String> fieldSet = new Map<String,String>();
            for(string fieldName:fieldValues) {
                if(fieldName == OWNER_MAIN) {
                    fieldSet.put('Prospect-Client Owner',OWNER_MAIN);
                }
                else if(fieldName.endsWith('__c')){
                    String label = objectHelper.getFieldLabel('Account',fieldName);
                    fieldSet.put(label,fieldName);
                }
                else{
                    fieldSet.put(fieldName,fieldName);
                }
            }  
            system.debug('getFieldOptions fieldSet: '+fieldSet);
            List<SelectOption> options = new List<SelectOption>();
            for(String fn:fieldSet.keySet()){
                options.add(new SelectOption(fieldSet.get(fn),fn));
            }
            return options;     
        }
        else{
            return null;
        }
        
    } // getFieldOptions
    
    
    //Called by the submit button after choosing who should receive the crossover request.
    public void setRecipient(){
        recipientSelected=true;
        Date expireDate = Utilities.getNextBusinessDay(1);
        Boolean hasActivity = checkActivity();
        Transfer_Request__c previousCrossover = null;
        
        String acctOwnerField;
        HoldOut_ExpirationDates__c hoe = HoldOut_ExpirationDates__c.getValues(crossoverUser.Sales_Org__c);
        system.debug('setRecipient hoe: ' + hoe);
        if(hoe != null && !String.isBlank(hoe.Account_Owner__c)) {
            acctOwnerField = hoe.Account_Owner__c;
        }
        else acctOwnerField = 'OwnerId';
        //Note that the account owner is being set on declaration via the get method. Search 'public User acctOwner' to find it
        
        if(thisAcct != null && thisAcct.Hold_Out__c && acctOwner != null && acctOwner.Id == crossoverUser.Id) {
            crossoverExtension = true;
        }
        
        System.debug('setRecipient crossoverUser.Id: ' + (crossoverUser != null ? crossoverUser.Id : null));
        System.debug('setRecipient acctOwner.Id: ' + (acctOwner != null ? acctOwner.Id : null));
        if (crossoverUser != null && acctOwner != null && crossoverUser.Id == thisAcct.get(acctOwnerField)) {
            System.debug('setRecipient crossoverUser.Id == acctOwner.Id');
            if(crossoverExtension && acctOwner.Id == crossoverUser.Id) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'You already own this Prospect-Client record. Are you trying to submit a Crossover Extension?'));
                
                try{
                    previousCrossover = [SELECT Id, Original_Owner__c FROM Transfer_Request__c WHERE Account__c = :thisAcct.Id AND Status__c = 'Approved' AND Owner_Type__c = :crossoverUser.Sales_Org__c AND Crossover_Extension__c = false ORDER BY CreatedDate DESC LIMIT 1];
                } catch(System.QueryException e){
                    system.debug('setRecipient - Select Transfer_Request__c error: ' + e);
                }
                
            }
            else ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The Crossover request could not be completed. You already own this Prospect-Client record.'));
            currentOwnerSubmission = true;
            finished = true;
            //System.debug('finished=true The Crossover request could not be completed. You already own this Prospect-Client record.');
            System.debug('setRecipient finished = true The Crossover request could not be completed. You already own this Prospect-Client record. Are you instead trying to submit a Crossover Extension?');
        }
        
        
        if (acctOwner == null) {
            System.debug('setRecipient acctOwner == null');
            // crossover request cannot be completed - create the request to keep track.
            User sendTo = findSendRequestToUser(crossoverUser.Sales_Org__c);
            System.debug('setRecipient 1 has sendTo='+(sendTo != null));
            if(sendTo == null)
            {
                crossoverOkay = false;
                request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient,OwnerId = crossoverUser.Id, Status__c=DSA_STATUS, Account_Owner__c = null, Auto_Approve_Date__c = expireDate);
            }
            else {
                request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient, Owner_Type__c = crossoverUser.Sales_Org__c, OwnerId = crossoverUser.Id, Status__c=STATUS_SUBMIT, Account_Owner__c = null, Send_Request_To__c = sendTo.Id, Auto_Approve_Date__c = expireDate);
            }
        } else if (!acctOwner.IsActive) {
            System.debug('setRecipient !acctOwner.IsActive acctOwner.Name: '+acctOwner.Name);
            User sendTo = findSendRequestToUser(crossoverUser.Sales_Org__c);
            System.debug('setRecipient 2 has sendTo='+(sendTo != null));
            
            if(sendTo == null)
            {
                crossoverOkay = false;
                request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient,OwnerId = crossoverUser.Id, Status__c=DSA_STATUS, Account_Owner__c = acctOwner.Id, Auto_Approve_Date__c = expireDate);
            }
            else {
                request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient, Owner_Type__c = crossoverUser.Sales_Org__c, OwnerId = crossoverUser.Id, Status__c=STATUS_SUBMIT, Account_Owner__c = acctOwner.Id, Send_Request_To__c = sendTo.Id, Auto_Approve_Date__c = expireDate);
            }
        } else if (acctOwner.IsActive && (acctOwner.Name.contains('Virtual Sales') || (String.isNotBlank(acctOwner.Job_Name__c) && TRANSFER_JOBS.contains(acctOwner.Job_Name__c)))) {
            System.debug('setRecipient acctOwner.IsActive && (acctOwner.Name.contains(Virtual Sales) || (String.isNotBlank(acctOwner.Job_Name__c) && TRANSFER_JOBS.contains(acctOwner.Job_Name__c)))');
            // as long as owned by a rep or DSA, let the transfer occur
            // treat Direct Sales owner the same as regular sales reps so that requests will be sent to that user.
            if (!hasOpenOwnerRequests) {
                Id idOfUserInOwnerField = null;
                if(acctOwnerField != null) idOfUserInOwnerField = (Id)thisAcct.get(acctOwnerField);
                
                Id sendRequestToUserId = crossoverExtension && thisAcct.Previous_Owner_Id__c != null ? thisAcct.Previous_Owner_Id__c : idOfUserInOwnerField;
                request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient, Owner_Type__c = crossoverUser.Sales_Org__c, OwnerId = crossoverUser.Id, Status__c=STATUS_SUBMIT, Account_Owner__c = acctOwner.Id, Send_Request_To__c = sendRequestToUserId, Auto_Approve_Date__c = expireDate);
                //request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient, Owner_Type__c = crossoverUser.Sales_Org__c, OwnerId = crossoverUser.Id, Status__c=STATUS_SUBMIT, Account_Owner__c = acctOwner.Id, Send_Request_To__c = acctOwner.Id, Auto_Approve_Date__c = expireDate);    
            }
        } else {
            System.debug('setRecipient Crossover is not okay');
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Fell through to the DSA request'));
            // crossover request cannot be completed - create the request to keep track.
            crossoverOkay = false;
            request = new Transfer_Request__c(Account__c = thisAcct.Id, Owner_Field__c=selectedRecipient, Owner_Type__c = crossoverUser.Sales_Org__c, OwnerId = crossoverUser.Id, Status__c=DSA_STATUS, Account_Owner__c = acctOwner.Id, Send_Request_To__c = crossoverUser.DSA_FSS__c, Auto_Approve_Date__c = expireDate);
        } // if (thisAcct.OwnerId
        
        
        //Use the Hold out Expiration Dates custom setting to find the proper hold out fields to use
        if(hoe != null) {
            if(String.isNotBlank(hoe.HoldOutReasonFld__c) && String.isNotBlank(hoe.Account_Hold_Out__c) && String.isNotBlank(hoe.Account_Hold_Out_Date__c)) {
                if((Boolean)thisAcct.get(hoe.Account_Hold_Out__c) && String.isNotBlank((String)thisAcct.get(hoe.HoldOutReasonFld__c)) && (Date)thisAcct.get(hoe.Account_Hold_Out_Date__c) == null)
                {
                    request.Hold_Out_reason__c = (String)thisAcct.get(hoe.HoldOutReasonFld__c);
                }
            }
        }
        else request.Hold_Out_Reason__c = thisAcct.Permanent_Hold_Out_Description__c;
        
        //If there was a previous crossover, set the original owner to be the user stored in the previous crossover
        //Otherwise make the current account owner the original owner
        if(crossoverExtension && previousCrossover != null) request.Original_Owner__c = previousCrossover.Original_Owner__c;
        else if(acctOwner != null) request.Original_Owner__c = acctOwner.Id;
        else request.Original_Owner__c = null;
        
    }
    
   
    
    /** The user jobs that it's okay to transfer from. */
    public static Set<String> TRANSFER_JOBS = new Set<String>{UserHelper.JOB_REP, UserHelper.JOB_DSA, UserHelper.JOB_DSM};
        
        public User acctOwner {get{
            
            if(selectedRecipient==OWNER_MAIN){
                return thisAcct.Owner;
            }
            //look for custom owner field
            else if(selectedRecipient.endsWith('__c')){
                String relationship = selectedRecipient.replace('__c','__r');
                User u = (User)thisAcct.getSobject(relationship);
                return u;
            }
            //check account team for owner field
            else{
                system.debug('acctOwner selectedRecipient: '+selectedRecipient);
                User u = new User();
                for(AccountTeamMember atm: thisAcct.AccountTeamMembers){
                    system.debug('acctOwner atm.TeamMemberRole: '+atm.TeamMemberRole);
                    if(atm.TeamMemberRole == selectedRecipient){
                        u = atm.User;
                    }
                }
                return u;
            }//else if
        } // get
                              } // acctOwner
    
    public Transfer_Request__c request{get;set;}
    
    public List<Transfer_Request__c> requests{get;set;}
    
    /** Are there any open Crossover requests for the owner field?
*/
    public Boolean hasOpenOwnerRequests{get; private set;}
    
    /** Are there any open requests? */
    public Boolean hasRequests{
        get {return (requests != null && requests.size() > 0); }
    }
    
    /** Check for open transfer requests.
*/
    private void checkTransferRequest() {
        requests = new List<Transfer_Request__c>([Select Id, CreatedBy.Name, CreatedDate, Comments__c, Owner_Field__c, Owner_Type__c from Transfer_Request__c where Account__c = :thisAcct.Id and Status__c in ('Submitted',:DSA_STATUS) LIMIT 500]);
        hasOpenOwnerRequests = false;
        for (Transfer_Request__c tr : requests) {
            if (tr.Owner_Field__c == selectedRecipient) {
                hasOpenOwnerRequests = true;
                break;
            }
        } // for (Transfer_Request__c
    } // checkTransferRequest
    
    /** Get the list of tasks.
*/
    public List<Task> tasks{get;private set;}
    
    public Boolean hasTasks {
        get {return (tasks != null && tasks.size() > 0); }
    }
    
    /** Get the list of events.
*/
    public List<Event> events{get;private set;}
    
    public Boolean hasEvents {
        get {return (events != null && events.size() > 0); }
    }
    
    /** Does the account have any activity from the past 90 days?
*/
    public Boolean hasActivity {
        get {return (hasTasks || hasEvents); }
    } // hasActivity
    
    /** Check for activity in the past 90 days.
*/
    private Boolean checkActivity() {
        // check tasks
        tasks = new List<Task>([Select Id, Subject, Type, Owner.Name, ActivityDate from Task where AccountId = :thisAcct.Id and OwnerId != :UserInfo.getUserID() and ActivityDate >= LAST_90_DAYS]);
        // check events
        events = new List<Event>([Select Id, Subject, Type, Owner.Name, ActivityDate from Event where AccountId = :thisAcct.Id and OwnerId != :UserInfo.getUserID() and ActivityDate >= LAST_90_DAYS]);
        return hasActivity;
    } // checkActivity
    
    /* Used to navigate to the first page.
*/
    public PageReference page1() {
        return Page.CrossoverRequest;
    } // step1
    
    public PageReference returnToAcct() {
        if (isTransfer) {
            insert request;
            //update thisAcct;
        }
        return cancel();
    } // returnToAcct
    
    /* Cancel the operation and return to the original account form.
*/
    public PageReference cancel() {
        PageReference acctPage = new PageReference('/'+(thisAcct != null ? thisAcct.id : ''));
        acctPage.setRedirect(true);
        return acctPage;
    } // cancel
    
    /* Used when the next button is clicked from step 1.
Only records with an account number are saved.
*/
    //Called from "Submit Crossover Extension" button on visualforce page. Sets the Crossover_Extension__c checkbox and saves as normal
    public PageReference saveExtension() {
        request.Crossover_Extension__c = true;
        return saveRequest();
    }
    
    public PageReference saveRequest() {
        //Date expireDate = Utilities.getNextBusinessDay(1);
        //request.Auto_Approve_Date__c = expireDate;
        String crossoverType = request.Crossover_Extension__c ? 'Crossover Extension' : 'Crossover';
        if(request.Comments__c==null||request.Comments__c==''){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Reason For ' + crossoverType + ': You must enter a value.'));
            return null;
        }
        if (crossoverOkay) {
            submitRequest();
            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'The ' + crossoverType + ' request was successfully submitted.'));
            finished = true;
            System.debug('finished=true The Crossover request was successfully submitted.');
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'There is an issue with the Owner of this Prospect-Client. Please see the instructions below.'));
            finished = true;
            cannotComplete = true;
            System.debug('finished=true The Territory Rep of this Prospect-Client cannot be determined!');
        }
        return page1();
    } // saveRequest
    
    public PageReference saveDsaRequest() {
        System.debug('saveDsaRequest request.Send_Request_To__c='+request.Send_Request_To__c);
        if (request.Send_Request_To__c == null) {
            System.debug('saveDsaRequest 1');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must enter the name of your DSA/FSS to proceed!'));
            request.User_Prompted_for_DSA__c = true;
            upsert request;
            return page1();
        } else if (request.Send_Request_To__c == UserInfo.getUserId()) {
            System.debug('saveDsaRequest 2');
            request.Send_Request_To__c = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You cannot send the request to yourself!'));
            return page1();
        }
        User checkUser = [Select Id, IsActive, Profile.Name,Sales_Org__c from User where Id = :request.Send_Request_To__c];
        // check to make sure user is active
        if (!checkUser.isActive) {
            System.debug('saveDsaRequest 3');
            request.Send_Request_To__c = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The user you selected is not active! Please only select an active user.'));
            return page1();
        }
        // check to make sure profile is of correct type
        if (!Utilities.checkDsaZsaProfName(checkUser.Profile.Name)) {
            System.debug('saveDsaRequest 4');
            request.Send_Request_To__c = null;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This can only be assigned to a DSA/FSS/ZSA! Please select another user.'));
            return page1();
        }
        
        if(checkUser!=null && checkUser.Sales_Org__c!=null){
            request.Owner_Type__c = checkUser.Sales_Org__c;
        }
        System.debug('saveDsaRequest before submitRequest');
        submitRequest();
        PageReference acctPage = new PageReference('/'+thisAcct.id);
        acctPage.setRedirect(true);
        return acctPage;
    } // saveDsaRequest
    
    /** Save the request and create a task.
*/
    private void submitRequest() {
        System.debug('submitRequest request='+request);
        if (request != null) {
            request.Owner_Field__c = selectedRecipient;
            upsert request;
            request = [Select Id, Auto_Approve_Date__c, Comments__c, Send_Request_To__c, Send_Request_To__r.email
                       ,Send_Request_To__r.Name, Send_Request_To__r.UserRole.ParentRoleId, Send_Request_To__r.UserRole.Name
                       ,Send_Request_To__r.Job_Name__c
                       ,Owner.Name, Account_Owner__r.Name, Owner_Field__c
                       from Transfer_Request__c where Id = :request.Id];
            System.debug('submitRequest request='+request); 
            // create a task if owned by rep
            Id taskId = createTaskEmail();
            // update the request with the task id.
            System.debug('submitRequest created task email');
            if (taskId != null) {
                request.TaskId__c = taskId;
                update request;
            } // if (taskId != null
            request = null;
        } // if (request != null
    } // submitRequest
    
    public boolean containsExcludedHO(String p_permHODesc) {
       String permHODesc = RecordTypeHelper.cleanRtName(p_permHODesc);
       if (String.isNotBlank(permHODesc)) {
          HoldOut_Dictionary__c hod = HoldOut_Dictionary__c.getInstance(permHODesc);
          if (hod != null) {
             return hod.PreventCrossover__c;
          }
       }
       return false;
    }
    
    // the sales orgs to send the cc: email to
    public static Set<String> salesOrgEmails = new Set<string>{UserHelper.SO_MMS,UserHelper.SO_401,UserHelper.SO_PEO_ASO,UserHelper.SO_PEO,UserHelper.SO_HNB,UserHelper.SO_MS,UserHelper.SO_CORE}; 
        
        /** Create a task 
*/
        private Id createTaskEmail() {
            // default value
            /*
String recordTypeName = null;
UserHelper uh = new UserHelper();
if (uh.isCore(crossoverUser.Sales_Org__c)) {
recordTypeName = RecordTypeHelper.CORE_TASK;
} else if (uh.isMMS(crossoverUser.Sales_Org__c)) {
recordTypeName = RecordTypeHelper.MMS_TASK;
} else if (uh.isHRS(crossoverUser.Sales_Org__c)) {
recordTypeName = RecordTypeHelper.HRS_TASK;
} 
String recordTypeName = so.TaskRecordTypeName__c;
System.debug('rtName: '+recordTypeName);
Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(recordTypeName, 'Task');
if (rt == null) {
System.debug('No record type found - not creating task');
return null;
} // if (rt == null*/
            
            List<String> ccEmailList = new List<String>();
            
            if(crossoverUser.Name == 'HRS Virtual Sales' && Label.Crossover_Virtual_Email_Users != null){
                checkAddEmail(Label.Crossover_Virtual_Email_Users,ccEmailList);
                system.debug('jsh crossover email: '+ccEmailList);
            }
            if  (salesOrgEmails.contains(crossoveruser.Sales_Org__c)) {
                Set<Id> userRoleIds = new Set<Id>();
                // only get the parent of Sales Rep roles
                // //************************************
                if (crossoverUser.UserRole != null && crossoverUser.UserRole.ParentRoleId != null) {
                    System.debug('crossoverUser.Job_Name__c='+crossoverUser.Job_Name__c);
                    if (String.IsNotBlank(crossoverUser.Job_Name__c) && crossoverUser.Job_Name__c == UserHelper.JOB_REP) {
                        system.debug('in if');
                        //System.debug('crossoverUser.Manager='+crossoverUser.Manager);
                        //checkAddEmail(crossoverUser.Manager,ccEmailList);
                        //System.debug('crossoverUser.DSA_FSS__r='+crossoverUser.DSA_FSS__r);
                        //checkAddEmail(crossoverUser.DSA_FSS__r.Email,ccEmailList);
                        
                        
                        //String roleType = OrgStrcRole.getRoleType(crossoverUser.UserRole);
                        //if (roleType != null && roleType == 'SALES REP') {
                        userRoleIds.add(crossoverUser.UserRole.ParentRoleId);
                    }
                }
                //sends to the current owner's superiors
                if (request.Send_Request_To__r != null && request.Send_Request_To__r.UserRole != null && request.Send_Request_To__r.UserRole.ParentRoleId != null) {
                    if (String.IsNotBlank(request.Send_Request_To__r.Job_Name__c) && request.Send_Request_To__r.Job_Name__c == UserHelper.JOB_REP) {
                        system.debug('in if2');
                        //checkAddEmail(request.Send_Request_To__r.Manager,ccEmailList);
                        //checkAddEmail(request.Send_Request_To__r.DSA_FSS__r,ccEmailList);
                        //String roleType = OrgStrcRole.getRoleType(request.Send_Request_To__r.UserRole);
                        //if (roleType != null && roleType == 'SALES REP') {
                        userRoleIds.add(request.Send_Request_To__r.UserRole.ParentRoleId);
                        System.debug('#### SNY userRoles for SendToRequest --> ' +userRoleIds);
                    }
                    //*******************************************
                }
                
                // retrieve everyone in the roles above Sales Rep
                List<User> userList = new List<User>([Select Id, Sales_Org__c, Email from User u where u.UserRoleId in :userRoleIds and Isactive=true]);
                for(User us: userList) {
                    ccEmailList.add(us.Email);
                }
                system.debug('@@@@ SNY ccEMailList --->' +ccEmailList);
                
                if(includeCrossoverUser)
                {
                    ccEmailList.add(crossoverUser.Email);
                }
                
            } // if  (salesOrgEmails.contains
            
            if(!ccEmailList.contains(crossoverUser.Email) && convertedLeadType!='')
            {
                ccEmailList.add(crossoverUser.Email);
            }
            
            for(String email : extraRecipients)
            {
                ccEmailList.add(email);
            }
            
            String taskBody = getMessageBody(true,true);
            String emailBody = getMessageBody(true,false);
            // prepare and send email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // If going to a Salesforce user, does not count towards apex email limit.
            mail.setTargetObjectId(request.Send_Request_To__c);
            mail.setSubject('Prospect-Client Crossover Request from ' + crossoverUser.Name);
            mail.setHtmlBody(emailBody);
            mail.setBccSender (false);
            mail.setCcAddresses(ccEmailList);
            mail.setUseSignature(false);
            mail.setSaveAsActivity(false);
            
            //Boolean okayToSend = String.isBlank(Utilities.checkForProduction());
            Boolean okayToSend=true;
            if (!okayToSend) {
                // check the custom setting for an override
                for (PaychexSettings__c ps : PaychexSettings__c.getall().values()) {
                    if (ps.Name == 'CrossoverRequestController') {
                        okayToSend = ps.AllowSendEmailsInSandbox__c;
                        break;
                    }
                } // for
            } // if
            
            if (okayToSend) {
                Messaging.sendEmail (new Messaging.SingleEmailMessage[] { mail });
            } 
            
            String recordTypeName = so.TaskRecordTypeName__c;
            System.debug('rtName: '+recordTypeName);
            Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(recordTypeName, 'Task');
            if (rt == null) {
                System.debug('No record type found - not creating task');
                return null;
            } // if (rt == null
            Task task = new Task(RecordTypeId = rt.getRecordTypeId()
                                 ,Lead_Source_WAR_Call_Type__c='Not WAR'
                                 ,Type='Crossover Request'
                                 ,Subject='Crossover Requested'
                                 ,Status='Not Started'
                                 ,Priority='Normal'
                                 ,ActivityDate=request.Auto_Approve_Date__c
                                 ,WhatId=thisAcct.Id
                                 ,OwnerId=request.Send_Request_To__c
                                 ,Description=taskBody
                                );
            insert task;
            return task.Id;
        } // createTask
    
    
    private void checkAddEmail(String ulist, List<String> emailList) {
        System.debug('checkAddEmail u='+ulist);
        String[] splitUsers = ulist.split(',');
        User[] users = [SELECT Id, Name, Email FROM User WHERE Name IN :splitUsers];
        System.debug('users: '+users);
        for(User u: users){
            if (u != null && String.isNotBlank(u.Email)) {
                emailList.add(u.Email);
            }
        }
        
    } // checkAddEmail
    
    
    private String getMessageBody(Boolean crossoverOkay, Boolean isText) {
        
        String line = (isText ? '\n' : '<br>');
        
        String mailText = request.Send_Request_To__r.Name+','+line;
        
        mailText += request.Owner.Name+' is requesting an ownership change of the following Prospect-Client to themselves';
        
        if (cannotComplete) {
            mailText += ', however, we cannot determine who should approve this request based upon the current owner  (Example: Open Territory or No Zip Code). ';
            mailText += 'Please communicate with the appropriate personnel and either Click on the APPROVED or DECLINED link at the end of this message to complete this ownership change request.'+line;
        } else {
            //       mailText += '.  Please Click on either the APPROVED or DECLINED link at the end of this message to complete this ownership change request. '+line;
            mailText += ' '+line;
            
        }
        
        mailText += line+' Important Note: Failure to APPROVE or REJECT this request within 24 hours (end of day '+request.Auto_Approve_Date__c.format()+') will result in an Automatic APPROVAL.'+line;
        
        if (isText) {
            mailText += line+'-------------------------------------------------'+line+line;
        } else {
            mailText += line+'<hr width=100%>'+line;
        }
        
        mailText += 'Prospect-Client Name: '+thisAcct.Name + line;
        
        mailText += 'Current Owner: ' + request.Account_Owner__r.Name + line;
        
        if (request.Comments__c != null) {
            mailText += line+' Reason for Crossover: '+request.Comments__c+line;
        }
        mailText += line+' Phone: '+(thisAcct.Phone != null ? thisAcct.Phone : 'No Phone Number found.');
        mailText += line+' Address: ';
        if (thisAcct.ShippingStreet != null && thisAcct.ShippingPostalCode != null) {
            mailText += thisAcct.ShippingStreet;
            mailText += line+'          ';
            mailText += (thisAcct.ShippingCity != null ? thisAcct.ShippingCity : '');
            mailText += (thisAcct.ShippingCity != null && thisAcct.ShippingState != null ? ', ' : '');
            mailText += ' '+thisAcct.ShippingPostalCode;
        } else if (thisAcct.BillingStreet != null && thisAcct.BillingPostalCode != null) {
            mailText += thisAcct.BillingStreet;
            mailText += line+'          ';
            mailText += (thisAcct.BillingCity != null ? thisAcct.BillingCity : '');
            mailText += (thisAcct.BillingCity != null && thisAcct.BillingState != null ? ', ' : '');
            mailText += ' '+thisAcct.BillingPostalCode;
        } else {
            mailText += 'No Address found.';
        }
        mailText += line+line+' Click ';
        if (isText) {
            mailText += 'on this link';
        } else {
            mailText += '<a href="'+host+thisAcct.Id+'">Here</a>';
        } 
        mailText += ' to view the Prospect-Client';
        if (isText) {
            mailText += ': '+host + thisAcct.Id;
        } 
        mailText += line;
        
        //String approveLink = host + request.Id + '/e?00N70000002G6ot=Approved&save=1&retURL=%2F' + thisAcct.Id;
        //String declineLink = host + request.Id + '/e?00N70000002G6ot=Declined&save=1&retURL=%2F' + thisAcct.Id;
        String approveLink = host + request.Id + '/e?00N70000002G6ot=Approved&retURL=%2F' + thisAcct.Id;
        String declineLink = host + request.Id + '/e?00N70000002G6ot=Declined&retURL=%2F' + thisAcct.Id;
        String crossoverRequestURL = host + '/lightning/r/' +  String.valueOf(request.Id) + '/view';
        
        if (isText) {
            //   mailText += line + 'To APPROVE this request follow this link and click Save: '+approveLink + line;
            //   mailText += line + 'To DECLINE this request follow this link, fill in a Reason for Rejection and click Save: '+declineLink + line;
            mailText += line + line + 'To Approve or Decline this request, click here: ' + crossoverRequestURL + line;
        } else {
            //     mailText += line + 'To APPROVE this request click <a href="'+approveLink+'">APPROVED</a> and then Save.' + line;
            //    mailText += line + 'To DECLINE this request click <a href="'+declineLink+'">DECLINED</a> fill in Reason for Rejection and then Save.' + line;
            mailText += line + line + 'To Approve or Decline this request, click here: <a href="' + crossoverRequestURL + '">Crossover Request</a>.' + line;
            
        }
        return mailText;
    } // getMessageBody
    
    
   public User findSendRequestToUser(String salesOrg) {
       
      ZipWrapper zw = ZipCodeLookupController.getZipAssignment(thisAcct.Owner_Zip_Code__c, salesOrg, thisAcct, null);
      User foundUser = ((zw != null && zw.usr != null && zw.usr.IsActive) ? zw.usr
                          : ((zw != null && zw.assistant != null && zw.assistant.usr != null && zw.assistant.usr.IsActive) ? zw.assistant.usr
                             : ((zw != null && zw.manager != null && zw.manager.usr != null && zw.manager.usr.IsActive) ? zw.manager.usr
                                : null)));

      return foundUser;
   } // findSendRequestToUser
    
} // class CrossoverRequestController