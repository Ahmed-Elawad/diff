/* 
* Controller for Onboarding page.
*
* History
* -------
* 12/10/2016  Jermaine Stukes    Created
* 12/19/2016   Jermaine Stukes     Updated
* 06/12/2017   Lynn Michels        updated Account Team name for Small Market
* 11/01/2017   Jermaine Stukes     Added Chatter Methods
* 11/15/2017   Jermaine Stukes     Code Consolidation
* 01/09/2018   Cindy Freeman       added Spanish field and question
* 02/05/2018   Jermaine Stukes     Fixed subject format for Sharepoint upload
* 02/07/2018   Jermaine Stukes     Update ASO record type to pull from label
* 02/12/2018   Jermaine Stukes     Added Handbook Contact
* 02/21/2018   Sunnish Annu .      Updating the FSS Email Sent to True 
* 07/25/2018   Jermaine Stukes     Update ASO Summary naming convention
* 06/27/2019   Jermaine Stukes     Doc Desk Update
* 07/09/2019   Carrie Marciano     BAU#32984419 create case when submit to FSS is clicked
* 10/07/2019   Matt Fritschi       Added Have_Paychex_Promise__c for Paychex Promise product
* 03/20/2020   Jake Hinds          Change for MMS-ASO Pilot, MMS users with Pilot USer field of 'MMS-ASO Pilot' will use ASO clt profile, not doc desk
* 04/06/2020   Matt Fritschi       Made changes to also look for Oracle Quote
* 04/21/2020   Brandon Vidro       Changes for Doc Desk - Pivot to SMB
* 07/06/2020   Jacob Hinds         Added without sharing per PMD
* 11/30/2020   Matt Fritschi       Added in new functionality for NCO, MPSC, and Child Onboarding forms.
* 02/08/2021   Brandon Vidro       Removed System.debug statement per Q1 2021 PMD Apex Scan - ApexDangerousMethods
* 03/01/2021   Matt Fritschi       Sets SubmissionDate when NCP is submitted.
* 06/10/2022   Chris Santoro	   Added in new functionality for CA Mandate submissions - verifyCAMandate()
* 08/22/2022   Eric Porter         Added in new functionality for Client Profile enhancements saveChanges2() and added a few new fields on the onboarding tool object
* 10/19/2022   Eric Porter		   Uncommented createCase() as was causing issues in Production
* 11/04/2022   Eric Porter         Added in Duplicate Page submissions code
* 07/17/2023   Jermaine Stukes	   Added QTC Methods
  09/01/2023   Dan Carmen          More QTC fun
* 2/20/2024    Priyanka 		   Multi id Submission , New Method cloneClientProfiletoChilds
* 04/18/2024   Priyanka			   APR0168490: Visier/HR Analytics HR Services Solution
* 04/18/2024   Priyanka			   APR0168880: Paychex Flex Enagage
* 05/29/2024   Srujan			   addAdditonalContacts (APR0170390: Paychex Flex Enagage - Additional contacts)
* 06/04/2024   Priyanka			   APR0170402: emailFSS-upload NCP Summery to Sharepoint
*/
public without sharing class OnboardingController {
    public String incomingId{get;set;}
    public Opportunity onboardingOpp{get;set;}
    public Opportunity parentOnboardingOpp{get;set;}
    public Onboarding_Tool__c onboardingRecord{ get; set; }
    public OpportunityContactRole defaultContact;
    public Onboarding_Tool__c parentOnboardingRecord{ get; set; }
    public List<cafsl__Oracle_Quote__c> oracleQuote{get;set;}
    public List<cafsl__Oracle_Quote_Line_Item__c> oracleQuoteLines{get;set;}
    public Reference_Opportunity_Product__c refOppProduct{get;set;}
    public Reference_Opportunity_Product__c parentRefOppProduct{get;set;}
    public String productPackageList{get;set;}
    public String productList{get;set;}
    public String x401kProductList{get;set;}
    public User currentUser{get;set;}
    public Boolean isQuote{get;set;}
    public Boolean validRecord{get;set;}
    public Boolean hasQuote{get;set;}
    public Boolean fssValid{get;set;}
    public Boolean isFSS{get;set;}
    public Boolean hasFSS{get;set;}
    public Boolean isDSM{get;set;}
    public String emailAddress{get;set;}
    public String fssAddress{get;set;}
    public Boolean fssUpdate{get;set;}
    public String newExist{get;set;}
    public Boolean showLargeMarketRep{get;set;}
    public String noFSSEmail{get;set;}
    public Boolean InvalidEmail{get;set;}
    public Boolean changeFSS{get;set;}  
    public Boolean hasEsr{get;set;}  
    public Boolean hasFlextime{get;set;}
    public Boolean hasExistingTAA{get;set;}
    public Boolean hasEnterprise{get;set;}
    public Boolean hasPro{get;set;}
    public Boolean hasAso{get;set;}
    public Boolean hasSelect{get;set;}
    public Boolean hasSolo{get;set;}
    public Boolean hasExpressPayroll{get;set;}
    public Boolean displayMessages{get;set;}
    public Boolean moreThan1RefCtt{get;set;}
    
    /*public Boolean changeFSS{get;set;}  
public Boolean changeFSS{get;set;}  */
    public String onboardingType{get;set;}
    public String missingFields{get;set;}
    public String selectedAuthorizedContact{get;set;}
    public String selectedPayrollContact{get;set;}
    public Boolean emailSent{get;set;}
    public Boolean isChildOnboardingRec{get;set;}
    public Boolean isMMS{get;set;}
    public Boolean hasParent{get;set;}
    public Boolean hasAccess{get;set;}
    public Boolean typeSelected{get;set;}
    public User runningUser{get;set;}
    public String originalAccountDBA{get;set;}
    public Boolean newBusinessRunDateOkay{get;set;}
    public Boolean existingBusinessRunDateOkay{get;set;}
    public Boolean displayASOForMMS{get;set;}
    public Boolean parentWasSubmitted{get;set;}
    public Boolean has401kProduct {get;set;}
    public Boolean hasPayrollProduct {get;set;}
    public Boolean isMandateSale {get;set;}
    public Id refCTTOwnerId {get;set;}
    public Id refCTTOppId {get;set;}
    public Id refCTTId {get;set;}
         //Priyanka Added for HR Analytics       
    public transient blob attachBody{get;set;}
    public string attachName{get;set;}
    public string bankAccountFile    {get;set;}
    public Boolean hasHRAnalytics {get;set;} 
    public string  hrpackageProducts{get;set;}    
    	//Priyanka Added for Paychex Flex Enagege    
    public Boolean hasFlexEnagage {get;set;} 
    public Decimal flexEnagageLicenses    {get;set;}
    public Decimal flexEngagePrice    {get;set;}
    public Boolean uploadtoSharePoint {get;set;} 
    public string usrSalesDivision    {get;set;}
    public string usrSalesOrg  {get;set;}
    
    public OnboardingController(Boolean testMode) {
       // this is just used for a test - we don't want to run the initialization.
    }
    
    public OnboardingController() {   
        initialize();
    }
    public void initialize() {
        //Populate Opportunity, OnboardingTool, and Onboarding Account
        incomingId = ApexPages.CurrentPage().getParameters().get('id');
        isMMS = false;
        isChildOnboardingRec=false;
        parentWasSubmitted=true;
        hasParent = false;
        hasAccess = true;
        typeSelected = false;
        displayASOForMMS = false;
        hasPayrollProduct = false;
        has401kProduct = false;
        hasHRAnalytics=false;
        hasFlexEnagage=false;
        FlexEngagePrice=0;
        FlexEnagageLicenses=0;
        uploadtoSharePoint=false;
        
        runningUser = UserHelper.getRunningUser();        
        updateObjects();
        verifyCAMandate();
        //Checking to see if the User has access to complete this client profile.
        Profile p = new Profile();
        p = [SELECT Id, Name FROM Profile WHERE Id = :runningUser.ProfileId LIMIT 1];
        List<String> filteredProfiles = Label.Onboarding_Profiles_who_must_also_own_the_Record.split(',');
        if(p != null && p.Name != null && filteredProfiles.contains(p.Name))
        {
            hasAccess = checkUserAccess();
        }
        
        List<String> mpscProfs = new List<String>();
        List<String> ncoProfs = new List<String>();
        mpscProfs = Label.Onboarding_MPSC_Profiles.split(',');
        ncoProfs = Label.Onboarding_NCO_Profiles.split(',');
        
        //Checking to see if a form type has been specified in the past.
        if((onboardingRecord.Form_Type__c != null && onboardingRecord.Form_Type__c != ''))
        {
            typeSelected = true;
            System.debug('onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c+' typeSelected='+typeSelected);
        }
        
        //Checking if we should autofill the Form Type radio button to be MPSC or NCO
        if(mpscProfs.contains(p.Name) && (onboardingRecord.Form_Type__c == null || onboardingRecord.Form_Type__c == ''))
        {
            onboardingRecord.Form_Type__c = 'MPSC';
            System.debug('MPSC onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c+' typeSelected='+typeSelected);
        }
        else if(ncoProfs.contains(p.Name) && (onboardingRecord.Form_Type__c == null || onboardingRecord.Form_Type__c == ''))
        {
            onboardingRecord.Form_Type__c = 'NCO';
            System.debug('NCO onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c+' typeSelected='+typeSelected);
        }
        
        hasEsr = false;hasFlextime=false;hasQuote=false;hasExpressPayroll=false;hasSolo=false;hasSelect=false;
        onboardingRecord.Name = (onboardingOpp.Name.length() >= 80 ? onboardingOpp.Name.substring(0,79) : onboardingOpp.Name);
        InvalidEmail = (!String.isBlank(onboardingRecord.Alternative_Email__c) && onboardingRecord.Alternative_Email__c.contains('@paychex.com') ? false : true);
        fssUpdate = false;
        if(onboardingOpp.Account.Any_Pop__c)
        {onboardingRecord.Pop__c = false;}
        if(onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
        {onboardingRecord.MultiProdServiceCenter__c = null;}
        moreThan1RefCtt = false;
        changeFSS = false;
        getUserInfo();
        fssValidate();
        checkRunDate();
        Validate();
        getDisplaySPUpload();
        getProducts();
        getOptInOptOut();
        // ! Review for a better field to denote client type.
        if(onboardingOpp.Original_PC_Type__c!=null && onboardingOpp.Original_PC_Type__c.contains('Prospect')&& onboardingRecord.New_Existing__c == null){
            onboardingRecord.New_Existing__c = 'New Client';
        }else if(onboardingOpp.Original_PC_Type__c!=null && !onboardingOpp.Original_PC_Type__c.contains('Prospect')&& onboardingRecord.New_Existing__c == null){
            onboardingRecord.New_Existing__c = 'Existing Paychex Client';
        }
        System.debug('hasExpressPayroll='+hasExpressPayroll+' hasSolo='+hasSolo);
        
        //Default Ongoing_Delivery__c and First_Payroll_Delivery_Method__c to Online Only under these conditions.
        if(onboardingRecord.Form_Type__c == 'NCO' && (hasExpressPayroll || hasSolo) && (onboardingRecord.Ongoing_Delivery__c == null || onboardingRecord.Ongoing_Delivery__c != 'Online Only' || onboardingOpp.First_Payroll_Delivery_Method__c == null || onboardingOpp.First_Payroll_Delivery_Method__c != 'Online Only'))
        {
            System.debug('setting Ongoing_Delivery__c and First_Payroll_Delivery_Method__c to Online Only.');
            onboardingRecord.Ongoing_Delivery__c = 'Online Only';
            onboardingOpp.First_Payroll_Delivery_Method__c = 'Online Only';
            Validate();
        }
        
        selectedAuthorizedContact = onboardingRecord.Authorize_Officer__c;
        if(selectedAuthorizedContact != null){
            Contact authorizedOfficer = [Select Id, Name,Phone,Email from Contact where Id = :selectedAuthorizedContact];
            if(authorizedOfficer != null && authorizedOfficer.Phone != null && authorizedOfficer.Email != null){
                onboardingRecord.Authorized_Officer_Phone__c = authorizedOfficer.Phone;
                onboardingRecord.Authorized_Officer_Email__c = authorizedOfficer.Email;

            }
        }
        selectedPayrollContact = onboardingRecord.PayrollContact__c;
        System.debug('initialize selectedPayrollContact='+selectedPayrollContact+' onboardingRecord.PayrollContact__c='+onboardingRecord.PayrollContact__c);
        System.debug('onboardingType='+onboardingType+' isChildOnboardingRec='+isChildOnboardingRec+' typeSelected='+typeSelected+' onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c);
        //getSelectedAuthorizedDocDeskContact();
        //getSelectedPayrollDocDeskContact();
    }
    
    
    public void updateObjects()
    {
        onboardingOpp =  [Select id
                          ,AccountId
                          ,Account.SalesParent__c
                          ,Account.AccountNumber
                          ,Account.Any_Pop__c
                          ,Account.BillingStreet
                          ,Account.BillingState
                          ,Account.BillingCity
                          ,Account.BillingPostalCode
                          ,Account.Email__c
                          ,Account.Fax
                          ,Account.Federal_ID_Number__c
                          ,Account.First_Run_Date__c
                          ,Account.First_Check_Date__c
                          ,Account.Frequency__c
                          ,Account.Industry
                          ,Account.MMS_MAM_NAM__c
                          ,Account.MMS_MAM_NAM__r.FirstName
                          ,Account.MMS_MAM_NAM__r.LastName
                          ,Account.Name
                          ,Account.Phone
                          ,Account.Phone_Ext__c
                          ,Account.OwnerId
                          ,Account.Source_of_Business__c
                          ,Account.Current_Prior_Method__c
                          ,Account.DBA__c
                          ,Account.HRS_Account_Owner__c
                          ,Account.Paychex_Payroll_Specialist__c
                          ,Account.Taxpay__c
                          ,Account.isParent__c
                          ,Account.isChild__c
                          ,Account.Multi_ID_Parent__c
                          ,BranchClientNumber__c
                          ,Description
                          ,Employees_Paid_Per_Payroll__c
                          ,First_Payroll_Delivery_Method__c
                          ,Frequency__c
                          ,Handbook_Contact__c
                          ,Handbook_Contact__r.Name
                          ,LeadSource
                          ,Mandate_Sale__c
                          ,Name
                          ,New_or_Existing_Business__c
                          ,OwnerId
                          ,of_Employees__c
                          ,Payroll_Platform__c
                          ,Payroll_Current_Prior_Method__c
                          ,Number_of_Ids__c
                          ,Owner.Person_ID_Number__c
                          ,Owner.DSA_FSS__c
                          ,Owner.DSA_FSS__r.email
                          ,Owner.Name
                          ,Owner.phone
                          ,Owner.email
                          ,Original_PC_Type__c
                          ,RecordTypeId
                          ,RecordType.Name
                          ,Service_Location__c
                          ,StageName
                          ,Primary_Oracle_Quote__c
                          ,Primary_Oracle_Quote__r.Name
                          ,X401_k__c
                          ,Account_Billing_Address__c
                          ,(Select Contact.Email, Contact.Phone, Contact.Name, Contact.Id, Id, IsPrimary, Role, OpportunityId from OpportunityContactRoles)                          
                          ,(Select Id
                            ,Name
                            ,Opportunity__c 
                            ,Flex_Enterprise__c
                            ,Flex_Select__c
                            ,Paychex_Flex_Pro__c
                            ,Express_Payroll__c
                            ,ASO__c  
                            ,Tax_Credit_Service__c
                            ,Financial_Wellness_Service__c
                            ,Paychex_Flex_Onboarding__c
                            ,Paychex_Flex_Hiring__c
                            ,FLEX_Benefits_Administration_Essentials__c
                            ,Paychex_Flex_Time_Essentials__c
                            ,Onboarding_Essentials__c
                            ,Paychex_Employee_Screening_Essentials__c
                            ,Paychex_Flex_HR_Administration__c
                            ,Paychex_Flex_Time__c 
                            ,Paychex_Solo__c
                            from Reference_Opportunity_Products__r limit 1)     
                          ,(Select Id
                            ,Accidental_Death__c
                            ,Accounts_Payable_Contact__c
                            ,Add_Onboarding__c
                            ,Alternative_Email__c
                            ,Anticipated_Start_Date__c
                            ,Authorize_Officer__c
                            ,Authorized_Officer_Title__c
                            ,Authorized_Officer_Email__c
                            ,Authorized_Officer_Phone__c
                            ,Authorized_Officer_Name__c
                            ,BankDocumentation__c
                            ,Branch_Number__c
                            ,Best_Call_Time__c
                            ,Top_3_HR_Needs_Why__c
                            ,Client_Company_IDs__c
                            ,Industry__c
                            ,How_long_a_client__c
                            ,Employee_Headcount_Status__c
                            ,Other_Paychex_products_in_use__c
                            ,Client_Success_Meeting_Next_Step__c
                            ,Client_Success_Meeting_Date_Time__c
                            ,Employee_Headcount_In_Other_States__c
                            ,Paychex_Promise__c
                            ,Business_Structure__c
                            ,changeFSS__c
                            ,ChangeOfEntity__c
                            ,Client_Loss_Risk__c
                            ,Client_Number__c
                            ,Client_Require_Instructions__c
                            ,Combo__c 
                            ,Company_Contact__c
                            ,Company_Contact__r.Email
                            ,Company_Contact_Name__c
                            ,Contact_Email__c
                            ,Contact_is_HRAdmin__c
                            ,Core_Medical__c
                            ,Date_Business_Formed__c
                            ,Decision_Factors_Other__c
                            ,Dental__c
                            ,DiscountOffered__c
                            ,EmpsToLoad__c
                            ,ESR_educationInstitution__c
                            ,ESR_PriorMedRenewalDate__c
                            ,ESR_selfInsuredPlan__c
                            ,ESR_UnionEmps__c
                            ,First_Check_Date__c
                            ,Flex_Multi_Debit__c
                            ,Flex_Selling_Division__c
                            ,Flextime_Date__c
                            ,Flextime_ImpDate__c
                            ,Flextime_TAA__c
                            ,Flextime_Timeclock__c
                            ,FSS_Name__c
                            ,FSS_Email_Sent__c
                            ,GL__c
                            ,Group_Term_Life__c
                            ,Handbook_Format__c
                            ,HR_Administrator__c
                            ,HR_Admin__c
                            ,HRE_Decision_Factors__c
                            ,HRE_Decision_Factors_2__c
                            ,HRE_Decision_Factors_3__c
                            ,HRE_Existing__c
                            ,HRE_Existing_Safety_Manual__c
                            ,HRE_Paychex_created_existing__c
                            ,HRE_Paychex_created_existing_safety__c
                            ,HRE_Reason_Selected__c
                            ,HRE_Num_of_Locations__c
                            ,HR_Genralist__c
                            ,HRG_Name__c
                            ,HRS_Sales_Rep__c
                            ,HRS_Sales_Rep_Name__c
                            ,Insurance_Carrier__c
                            ,Irs_Address__c
                            ,IrsIsDelivery__c
                            ,IsCompanyContact__c
                            ,Large_Market_Sales_Rep__c
                            ,Long_Term_Disability__c
                            ,LostClientRisk__c
                            ,Migrating_from_preview_to_flex__c
                            ,MigrateToFlex__c
                            ,Multi_ID__c
                            ,Multi_Id_Billing__c
                            ,Multi_Id_Submission__c
                            ,Does_Company_Need_1099s__c
                            ,MultiBillingOption__c
                            ,MultiProdServiceCenter__c
                            ,New_Branch__c
                            ,New_Client__c
                            ,New_Existing__c
                            ,NumComboIds__c
                            ,NumEeToLoad__c
                            ,NumOf1099s__c
                            ,NumFlexId__c
                            ,Num_Management_EE__c
                            ,NumMultiIds__c
                            ,NumYearsWagesToLoad__c
                            ,Onboarding_Contact__c
                            ,Onboarding_Contact__r.Name
                            ,Onboarding_Contact__r.Email
                            ,OnboardingType__c
                            ,Ongoing_Pay_Period_End_Date__c
                            ,Ongoing_Call_Day_of_the_Week__c
                            ,Ongoing_Check_Day_of_the_Week__c
                            ,Opportunity_Id__c
                            ,Owner_Manager__c
                            ,Pay_Demand__c
                            ,PayrollContact__c 
                            ,PayrollContact_Title__c
                            ,PayrollContact_Phone__c
                            ,PayrollContact_Email__c
                            ,Payroll_Contact_Name__c
                            ,PayrollContact__r.Title
                            ,HR_Contact_Name__c
                            ,HR_Contact_Title__c
                            ,HR_Contact_Phone__c
                            ,Contact_Notes__c
                            ,PayrollRep__c
                            ,Payroll_Rep__c
                            ,Payroll_Rep_Name__c
                            ,PayrollProcessed__c
                            ,PeriodEndDate__c
                            ,PESS__c
                            ,PESS_Background_Screening__c
                            ,PESS_Drug_Testing__c
                            ,PESS_I9_Verification__c
                            ,PESS_Motor_Vehicle_Report__c
                            ,Pop__c
                            ,PreAssignedClientNum__c 
                            ,PreAssignedId__c
                            ,Preferred_Contact_Method__c
                            ,Previous_Platform__c
                            ,PriceLock3Year__c
                            ,PriorWagesLoaded__c 
                            ,Product__c
                            ,ProductList__c
                            ,Promotions__c
                            ,ReadyChex__c
                            ,RecruitingLiveDate__c
                            ,RecruitingStartDate__c
                            ,RelatedAccountId__c
                            ,RelationWithAddAccount__c
                            ,Run_Date__c
                            ,Short_Term_Disability__c
                            ,Spanish__c
                            ,Spanish_Speaking_Needs__c
                            ,StateProcessedIn__c
                            ,Submitter__c
                            ,SubmissionDate__c
                            ,Supporting_Documentation__c
                            ,Skylight__c
                            ,Taxpay__c
                            ,Tax_Exempt__c
                            ,Tax_Exempt_Id__c
                            ,Total_Num_EE__c
                            ,Vision__c
                            ,Workers_Compensation__c
                            ,Workers_Comp_Policy__c
                            ,Workers_Comp_Expiration_Date__c
                            ,Client_Key_Own_Payroll__c
                            ,Training__c
                            ,Type_Of_Employer__c
                            ,Has_Client_Applied_For_State_SUI_IDS__c
                            ,Is_Child__c
                            ,Is_Parent__c
                            ,Parent_Onboarding_Record__c
                            ,Use_Parent_Data__c
                            ,Taxed_as_S_Corp__c
                            ,Employee_Screening_Ess_Opt_In__c
                            ,Financial_Wellness_Opt_In__c
                            ,Flex_Ben_Opt_In__c
                            ,Flex_Hiring_Opt_In__c
                            ,Flex_HR_Admin_Opt_In__c
                            ,Flex_Onboarding_Ess_Opt_In__c
                            ,Flex_Onboarding_Opt_In__c
                            ,Flex_Time_Opt_In__c
                            ,Tax_Credit_Service_Opt_In__c
                            ,Does_Client_Use_DBA__c
                            ,DBA_Name_on_Checks_and_Reports__c
                            ,Ongoing_Delivery__c
                            ,Client_State_Id__c
                            ,Client_SUI_Id__c
                            ,Accounting_Software__c
                            ,Other_Accounting_Software__c
                            ,Authorized_Off_is_Payroll_Contact__c
                            ,Authorized_Off_is_HR_Contact__c
                            ,Form_Type__c
                            ,NCP_Submitted__c
                            ,X401_k_Plan_Start_Date__c
                            ,Client_Notes__c
                            ,HR_Sites__c
                            ,Multi_State__c
                            ,Sales_Parent__c
                            ,TAA_Site_Id__c
                            ,Update_Submission__c
                            ,Update_Notes__c
                            ,Multi_ID_Child_Account_Notes__c
                            ,Invoice_Email_Address__c
                            ,HR_Analytics_Contact__c
                            ,HR_Analytics_Contact_Email__c
                            ,HR_Analytics_billing__c
                            ,Bank_Account_Form__c
                            ,Flex_Engage_Contact__c
                            ,Flex_Engage_Contact_Email__c
                            ,Contact_Name_1__c
                            ,Contact_Name_2__c
                            ,Contact_Name_3__c
                            ,Contact_Name_4__c
                            ,Contact_Name_5__c
                            ,Contact_Name_6__c
                            ,Contact_Name_7__c
                            ,Contact_Name_8__c
                            ,Contact_Name_9__c
                            ,Contact_Name_10__c
                            ,Contact_Name_11__c
                            ,Contact_Name_12__c
                            ,Contact_Name_13__c
                            ,Contact_Name_14__c
                            ,Contact_Name_15__c
                            ,Contact_Name_16__c
                            ,Contact_Name_17__c
                            ,Contact_Name_18__c
                            ,Contact_Name_19__c
                            ,Contact_Name_20__c
                            ,Contact_Email_1__c
                            ,Contact_Email_2__c
                            ,Contact_Email_3__c
                            ,Contact_Email_4__c
                            ,Contact_Email_5__c
                            ,Contact_Email_6__c
                            ,Contact_Email_7__c
                            ,Contact_Email_8__c
                            ,Contact_Email_9__c
                            ,Contact_Email_10__c
                            ,Contact_Email_11__c
                            ,Contact_Email_12__c
                            ,Contact_Email_13__c
                            ,Contact_Email_14__c
                            ,Contact_Email_15__c
                            ,Contact_Email_16__c
                            ,Contact_Email_17__c
                            ,Contact_Email_18__c
                            ,Contact_Email_19__c
                            ,Contact_Email_20__c
                            ,Flex_Engage_Service_Start_Date__c
                            ,Flex_Engage_Invoice_Email__c
                            from Onboarding_Tools__r limit 1)
                          from Opportunity where id=:incomingId];
        onboardingRecord = !onboardingOpp.Onboarding_Tools__r.isEmpty() ? onboardingOpp.Onboarding_Tools__r : new Onboarding_Tool__c(Opportunity_Id__c = onboardingOpp.Id, AccountId__c = onboardingOpp.AccountId);
        System.debug('updateObjects onboardingOpp.Onboarding_Tools__r='+onboardingOpp.Onboarding_Tools__r.size()+' onboardingRecord='+(onboardingRecord != null));
        isChildOnboardingRec = onboardingRecord.Is_Child__c;
        originalAccountDBA = onboardingOpp.Account.DBA__c; 
        isMMS = onboardingOpp.RecordType.Name == 'MMS Opportunity Record Type for Sales';     
        
        System.debug('updateObjects isChildOnboardingRec='+isChildOnboardingRec);
        //If this is a child onboarding record, get the Parent's information as well.
        if(isChildOnboardingRec) {
            parentOnboardingOpp = new Opportunity();
            parentOnboardingRecord = new Onboarding_Tool__c();
            parentRefOppProduct = new Reference_Opportunity_Product__c();
            //childOnboardingRecord = onboardingRecord;
            List<Onboarding_Tool__c> onboardingRecords = [Select Id
                                                          ,Accidental_Death__c
                                                          ,Accounts_Payable_Contact__c
                                                          ,Add_Onboarding__c
                                                          ,Alternative_Email__c
                                                          ,Anticipated_Start_Date__c
                                                          ,Authorize_Officer__c
                                                          ,Authorized_Officer_Title__c
                                                          ,Authorized_Officer_Email__c
                                                          ,Authorized_Officer_Phone__c
                                                          ,Authorized_Officer_Name__c
                                                          ,BankDocumentation__c
                                                          ,Branch_Number__c
                                                          ,Best_Call_Time__c
                                                          ,Top_3_HR_Needs_Why__c
                                                          ,Client_Company_IDs__c
                                                          ,Industry__c
                                                          ,How_long_a_client__c
                                                          ,Employee_Headcount_Status__c
                                                          ,Other_Paychex_products_in_use__c
                                                          ,Client_Success_Meeting_Next_Step__c
                                                          ,Client_Success_Meeting_Date_Time__c
                                                          ,Employee_Headcount_In_Other_States__c
                                                          ,Business_Structure__c
                                                          ,changeFSS__c
                                                          ,ChangeOfEntity__c
                                                          ,Client_Loss_Risk__c
                                                          ,Client_Number__c
                                                          ,Client_Require_Instructions__c
                                                          ,Combo__c 
                                                          ,Company_Contact__c
                                                          ,Company_Contact__r.Email
                                                          ,Company_Contact_Name__c
                                                          ,Contact_Email__c
                                                          ,Contact_is_HRAdmin__c
                                                          ,Core_Medical__c
                                                          ,Date_Business_Formed__c
                                                          ,Decision_Factors_Other__c
                                                          ,Dental__c
                                                          ,DiscountOffered__c
                                                          ,EmpsToLoad__c
                                                          ,ESR_educationInstitution__c
                                                          ,ESR_PriorMedRenewalDate__c
                                                          ,ESR_selfInsuredPlan__c
                                                          ,ESR_UnionEmps__c
                                                          ,First_Check_Date__c
                                                          ,Flex_Multi_Debit__c
                                                          ,Flex_Selling_Division__c
                                                          ,Flextime_Date__c
                                                          ,Flextime_ImpDate__c
                                                          ,Flextime_TAA__c
                                                          ,Flextime_Timeclock__c
                                                          ,FSS_Name__c
                                                          ,FSS_Email_Sent__c
                                                          ,GL__c
                                                          ,Group_Term_Life__c
                                                          ,Handbook_Format__c
                                                          ,HR_Administrator__c
                                                          ,HR_Admin__c
                                                          ,HRE_Decision_Factors__c
                                                          ,HRE_Decision_Factors_2__c
                                                          ,HRE_Decision_Factors_3__c
                                                          ,HRE_Existing__c
                                                          ,HRE_Existing_Safety_Manual__c
                                                          ,HRE_Paychex_created_existing__c
                                                          ,HRE_Paychex_created_existing_safety__c
                                                          ,HRE_Reason_Selected__c
                                                          ,HRE_Num_of_Locations__c
                                                          ,HR_Genralist__c
                                                          ,HRG_Name__c
                                                          ,HRS_Sales_Rep__c
                                                          ,HRS_Sales_Rep_Name__c
                                                          ,Insurance_Carrier__c
                                                          ,Irs_Address__c
                                                          ,IrsIsDelivery__c
                                                          ,IsCompanyContact__c
                                                          ,Large_Market_Sales_Rep__c
                                                          ,Long_Term_Disability__c
                                                          ,LostClientRisk__c
                                                          ,Migrating_from_preview_to_flex__c
                                                          ,MigrateToFlex__c
                                                          ,Multi_ID__c
                                                          ,Multi_Id_Billing__c
                                                          ,Multi_Id_Submission__c
                                                          ,Does_Company_Need_1099s__c
                                                          ,MultiBillingOption__c         
                                                          ,MultiProdServiceCenter__c
                                                          ,New_Branch__c
                                                          ,New_Client__c
                                                          ,New_Existing__c
                                                          ,NumComboIds__c
                                                          ,NumEeToLoad__c
                                                          ,NumOf1099s__c
                                                          ,NumFlexId__c
                                                          ,Num_Management_EE__c
                                                          ,NumMultiIds__c
                                                          ,NumYearsWagesToLoad__c
                                                          ,Onboarding_Contact__c
                                                          ,Onboarding_Contact__r.Name
                                                          ,Onboarding_Contact__r.Email
                                                          ,OnboardingType__c
                                                          ,Ongoing_Pay_Period_End_Date__c
                                                          ,Ongoing_Call_Day_of_the_Week__c
                                                          ,Ongoing_Check_Day_of_the_Week__c
                                                          ,Opportunity_Id__c
                                                          ,Owner_Manager__c
                                                          ,Pay_Demand__c
                                                          ,PayrollContact__c 
                                                          ,PayrollContact_Title__c
                                                          ,PayrollContact_Phone__c
                                                          ,PayrollContact_Email__c
                                                          ,Payroll_Contact_Name__c
                                                          ,PayrollContact__r.Title
                                                          ,PayrollRep__c
                                                          ,Payroll_Rep__c
                                                          ,Payroll_Rep_Name__c
                                                          ,PayrollProcessed__c
                                                          ,PeriodEndDate__c
                                                          ,PESS__c
                                                          ,PESS_Background_Screening__c
                                                          ,PESS_Drug_Testing__c
                                                          ,PESS_I9_Verification__c
                                                          ,PESS_Motor_Vehicle_Report__c
                                                          ,Pop__c
                                                          ,PreAssignedClientNum__c 
                                                          ,PreAssignedId__c
                                                          ,Preferred_Contact_Method__c
                                                          ,Previous_Platform__c
                                                          ,PriceLock3Year__c
                                                          ,PriorWagesLoaded__c 
                                                          ,Product__c
                                                          ,ProductList__c
                                                          ,Promotions__c
                                                          ,ReadyChex__c
                                                          ,RecruitingLiveDate__c
                                                          ,RecruitingStartDate__c
                                                          ,RelatedAccountId__c
                                                          ,RelationWithAddAccount__c
                                                          ,Run_Date__c
                                                          ,Short_Term_Disability__c
                                                          ,Spanish__c
                                                          ,Spanish_Speaking_Needs__c
                                                          ,StateProcessedIn__c
                                                          ,Submitter__c
                                                          ,SubmissionDate__c
                                                          ,Supporting_Documentation__c
                                                          ,Skylight__c
                                                          ,Taxpay__c
                                                          ,Tax_Exempt__c
                                                          ,Tax_Exempt_Id__c
                                                          ,Total_Num_EE__c
                                                          ,Vision__c
                                                          ,Workers_Compensation__c
                                                          ,Workers_Comp_Policy__c
                                                          ,Workers_Comp_Expiration_Date__c
                                                          ,Client_Key_Own_Payroll__c
                                                          ,Training__c
                                                          ,Type_Of_Employer__c
                                                          ,Has_Client_Applied_For_State_SUI_IDS__c
                                                          ,Is_Child__c
                                                          ,Is_Parent__c
                                                          ,Use_Parent_Data__c
                                                          ,Taxed_as_S_Corp__c
                                                          ,Does_Client_Use_DBA__c
                                                          ,DBA_Name_on_Checks_and_Reports__c
                                                          ,Ongoing_Delivery__c
                                                          ,Client_State_Id__c
                                                          ,Client_SUI_Id__c
                                                          ,Accounting_Software__c
                                                          ,Other_Accounting_Software__c
                                                          ,Authorized_Off_is_Payroll_Contact__c
                                                          ,Authorized_Off_is_HR_Contact__c
                                                          ,Form_Type__c
                                                          ,NCP_Submitted__c
                                                          ,X401_k_Plan_Start_Date__c
                                                          ,Sales_Parent__c
                                                          ,Multi_ID_Child_Account_Notes__c
                                                          ,Invoice_Email_Address__c
                                                          ,HR_Analytics_Contact__c
                                                          ,HR_Analytics_Contact_Email__c
                                                          ,HR_Analytics_billing__c
                                                          ,Bank_Account_Form__c
                                                          ,Flex_Engage_Contact__c
                                                          ,Flex_Engage_Contact_Email__c	
                                                          ,Contact_Name_1__c
                                                          ,Contact_Name_2__c
                                                          ,Contact_Name_3__c
                                                          ,Contact_Name_4__c
                                                          ,Contact_Name_5__c
                                                          ,Contact_Name_6__c
                                                          ,Contact_Name_7__c
                                                          ,Contact_Name_8__c
                                                          ,Contact_Name_9__c
                                                          ,Contact_Name_10__c
                                                          ,Contact_Name_11__c
                                                          ,Contact_Name_12__c
                                                          ,Contact_Name_13__c
                                                          ,Contact_Name_14__c
                                                          ,Contact_Name_15__c
                                                          ,Contact_Name_16__c
                                                          ,Contact_Name_17__c
                                                          ,Contact_Name_18__c
                                                          ,Contact_Name_19__c
                                                          ,Contact_Name_20__c
                                                          ,Contact_Email_1__c
                                                          ,Contact_Email_2__c
                                                          ,Contact_Email_3__c
                                                          ,Contact_Email_4__c
                                                          ,Contact_Email_5__c
                                                          ,Contact_Email_6__c
                                                          ,Contact_Email_7__c
                                                          ,Contact_Email_8__c
                                                          ,Contact_Email_9__c
                                                          ,Contact_Email_10__c
                                                          ,Contact_Email_11__c
                                                          ,Contact_Email_12__c
                                                          ,Contact_Email_13__c
                                                          ,Contact_Email_14__c
                                                          ,Contact_Email_15__c
                                                          ,Contact_Email_16__c
                                                          ,Contact_Email_17__c
                                                          ,Contact_Email_18__c
                                                          ,Contact_Email_19__c
                                                          ,Contact_Email_20__c
                                                          ,Flex_Engage_Service_Start_Date__c
                                                          ,Flex_Engage_Invoice_Email__c
                                                          from Onboarding_Tool__c WHERE Id=:onboardingRecord.Parent_Onboarding_Record__c limit 1];
            
            //If a parent NCP was found, get the parent's Opportunity as well.
            if(onboardingRecords.size() > 0)
            {
                hasParent = true;
                parentOnboardingRecord = onboardingRecords[0];
                parentWasSubmitted = parentOnboardingRecord.NCP_Submitted__c;
                if(parentOnboardingRecord != null)
                {
                    parentOnboardingOpp = [Select id
                                           ,Name
                                           ,New_or_Existing_Business__c
                                           ,OwnerId
                                           ,Service_Location__c
                                           ,(Select Id
                                             ,Name
                                             ,Opportunity__c 
                                             ,Flex_Enterprise__c
                                             ,Flex_Select__c
                                             ,Paychex_Flex_Pro__c
                                             ,Express_Payroll__c
                                             ,ASO__c  
                                             ,Tax_Credit_Service__c
                                             ,Financial_Wellness_Service__c
                                             ,Paychex_Flex_Onboarding__c
                                             ,Paychex_Flex_Hiring__c
                                             ,FLEX_Benefits_Administration_Essentials__c
                                             ,Paychex_Flex_Time_Essentials__c
                                             ,Onboarding_Essentials__c
                                             ,Paychex_Employee_Screening_Essentials__c
                                             ,Paychex_Flex_HR_Administration__c
                                             ,Paychex_Flex_Time__c
                                             ,Paychex_Solo__c
                                             from Reference_Opportunity_Products__r limit 1)     
                                           from Opportunity where id=:parentOnboardingRecord.Opportunity_Id__c];
                    System.debug('parentOnboardingOpp='+parentOnboardingOpp);
                }               
            }
        }
        //oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id and cafsl__Syncing__c = true limit 1];
        if(!test.isRunningTest()){
            oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id and cafsl__Syncing__c = true limit 1];
        } else{
            oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id limit 1];
        }
        
        refOppProduct = !onboardingOpp.Reference_Opportunity_Products__r.isEmpty() ? onboardingOpp.Reference_Opportunity_Products__r : new Reference_Opportunity_Product__c(Opportunity__c = onboardingOpp.Id);
        
        //Get the parents opt in/outs as well if one exists.
        if(parentOnboardingOpp != null)
        {
            parentRefOppProduct = !parentOnboardingOpp.Reference_Opportunity_Products__r.isEmpty() ? parentOnboardingOpp.Reference_Opportunity_Products__r : new Reference_Opportunity_Product__c(Opportunity__c = parentOnboardingOpp.Id);
        }
        List <AccountTeamMember> onboardingAcctTeam = [Select id, AccountId, TeamMemberRole, UserId from AccountTeamMember where AccountId=:onboardingOpp.Account.Id];
        List <OpportunityLineItem> oliList= [Select Name, Product2.Family, Quantity, Payroll_Unit__c, Setup_Fee__c, Total_Calced__c, Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice, QuoteLineGroupAcctName__c from OpportunityLineItem where OpportunityId =:onboardingOpp.id];
        // find if Oli.Name ==A || Oli.Name == B|| Oli.Name == C 
        //A = HR Solutions ? HR Solutions-Flex
        //B = Doesn't have Flex HR ? Non Payroll
        //C = HR Essentials ? HR Essentials
        for(OpportunityLineItem oli:oliList){
            System.debug(oli.Product2.Family);
            if(oli.Product2.Family!= null && (oli.Product2.Family.contains('PESS') || oli.Product2.Family.contains('PESS Essentials'))){
                onboardingRecord.PESS__c = true;
            }
            if(oli.Product2.Family!= null &&(oli.Product2.Family.contains('Onboarding')||oli.Product2.Family.contains('Onboarding - Add On')||oli.Product2.Family.contains('Onboarding Essentials'))){
                onboardingRecord.Add_Onboarding__c = true;
            }
            //!wrap in a null check for oli.name (completed 9/22/22)
            System.debug('oli.Name: '+oli.Name);
            if((onboardingRecord.Product__c == null||onboardingRecord.Product__c == 'HR Solutions for Non-Payroll') && oli.Name!=null){
                if(oli.Name.contains('HR Solution')&& !oli.Name.contains('Non Payroll')){
                    onboardingRecord.Product__c = 'HR Solutions-Flex';
                    onboardingRecord.Flex_Multi_Debit__c ='Multi Debit';
                    System.debug('FOUND FLEX PRODUCT');
                   // continue;
    
                } else if(oli.Name.contains('HR Essentials')){
                    onboardingRecord.Product__c = 'HR Essentials';
                    System.debug('FOUND ESSENTIALS PRODUCT');

                    //continue;
    
                }else if(!oli.Name.contains('Flex HR')|| oli.Name.contains('Non Payroll')){
                    onboardingRecord.Product__c = 'HR Solutions for Non-Payroll';
                    onboardingRecord.Flex_Multi_Debit__c ='Multi Debit';
                    System.debug('FOUND HR NON PAYROLL PRODUCT');

                } 
            }
           
            
        }
        if(onboardingRecord.HRS_Sales_Rep__c == null && onboardingOpp.Account.HRS_Account_Owner__c!= null){
            onboardingRecord.HRS_Sales_Rep__c = onboardingOpp.Account.HRS_Account_Owner__c;
        }
        if(onboardingRecord.PayrollContact__c == null && onboardingOpp.Account.Paychex_Payroll_Specialist__c != null){
            onboardingRecord.PayrollContact__c = onboardingOpp.Account.Paychex_Payroll_Specialist__c;
        }
        if(onboardingRecord.NumMultiIds__c == null && onboardingOpp.Number_of_Ids__c != null){
            onboardingRecord.NumMultiIds__c = onboardingOpp.Number_of_Ids__c;
        }
        //TODO 9/21/22 
        //!updates for Auto Populating fields in Client Profile enhancement
List<OpportunityContactRole> oppContactRoles = onboardingOpp.OpportunityContactRoles;
for(OpportunityContactRole ctctRole:oppContactRoles){
    if(ctctRole.IsPrimary){
        defaultContact = ctctRole;
    }
}
if(defaultContact!=null && defaultContact.ContactId!= null){
    System.debug('OppContactRole: '+defaultContact);
    System.debug('oppContactRole.Contact: '+String.valueOf(defaultContact.Contact.Id));
    onboardingRecord.Authorize_Officer__c = defaultContact.Contact.Id ;
    selectedAuthorizedContact = (String) defaultContact.Contact.Id;
    if(selectedAuthorizedContact != null){
        Contact authorizedOfficer = [Select Id, Name,Phone,Email from Contact where Id = :selectedAuthorizedContact];
        if(authorizedOfficer != null && authorizedOfficer.Phone != null && authorizedOfficer.Email != null){
            onboardingRecord.Authorized_Officer_Phone__c = authorizedOfficer.Phone;
            onboardingRecord.Authorized_Officer_Email__c = authorizedOfficer.Email;
        }
    }
}
       // if(onboardingRecord.Authorized_Officer_Name__c== null && )
        onboardingRecord.Taxpay__c = onboardingOpp.Account.Taxpay__c;
        //onboardingRecord.MultiBillingOption__c = (onboardingOpp.Account.isParent__c ==true || onboardingOpp.Account.isChild__c == true)? 'true': 'false';
        // if(onboardingRecord.MultiBillingOption__c=='true'){
        //     //TODO add sales parent to validation fields
        // }
        if(!onboardingAcctTeam.isEmpty())
        {updateTeamMemberInfo(onboardingAcctTeam);}
        String oppRecordType = RecordTypeHelper.getRecordTypeById(onboardingOpp.RecordTypeId, 'Opportunity').getName();
        List<String> docDeskRTs = Label.Onboarding_DocDeskRT.split(',');
        Boolean hasASOPermission = false;
        CustomPermission[] cps = [SELECT DeveloperName FROM CustomPermission WHERE MasterLabel = 'MMS-ASO Pilot' LIMIT 1]; 
        if(cps!=null && !cps.isEmpty()){
            hasASOPermission = FeatureManagement.checkPermission(cps[0].DeveloperName);
            system.debug('OnboardingController updateObjects hasASOPermission: '+hasASOPermission);     
        }
        system.debug('oppRecordType: ' + oppRecordType);   
        system.debug('docDeskRTs: ' + docDeskRTs);
        onboardingType = (docDeskRTs.contains(oppRecordType) && !hasASOPermission ? 'Doc Desk' : 'HR Solutions'); 
        system.debug('onboardingType: ' + onboardingType);
        onboardingRecord.OnboardingType__c = onboardingType;
    }
    
    public void updateTeamMemberInfo(List<AccountTeamMember> onboardingAcctTeam)
    {
        for(AccountTeamMember atm: onboardingAcctTeam){
            showLargeMarketRep = onboardingOpp.Employees_Paid_Per_Payroll__c > 50 ? true : false;
            if(atm.TeamMemberRole == 'Large Market 401(k) Partner'){
                onboardingRecord.Large_Market_Sales_Rep__c = atm.UserId;break;
            }
            else if(atm.TeamMemberRole == 'Small Market 401(k) Partner'){
                onboardingRecord.HRS_Sales_Rep__c = atm.UserId;break;
            }
        }
    }
    
    //Get the products associated with this Opportunity
    public void getProducts(){
        List<String> productPackages = Label.Onboarding_DocDesk_Packages.Split(',');
        if(!oracleQuote.isEmpty()){
            hasQuote = true;
            //quoteLines = [Select Id, SBQQ__Product__c, SBQQ__PackageProductCode__c, SBQQ__Bundle__c, SBQQ__ProductName__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quote.Id];
            oracleQuoteLines = [Select Id, cafsl__Product__c, cafsl__Product__r.Name,cafsl__Product__r.Is_Package__c
                                ,cafsl__Sales_Price__c, cafsl__Quantity__c,Customer_Price_unit__c from cafsl__Oracle_Quote_Line_Item__c where cafsl__Oracle_Quote__c =:oracleQuote[0].Id];
            if(!oracleQuoteLines.isEmpty()){
                isQuote = true;
                hasFlexTime = false;
                hasEsr = false;
                System.debug('getProducts oracleQuote is not empty: '+oracleQuoteLines);
                for(cafsl__Oracle_Quote_Line_Item__c oracleQline : oracleQuoteLines)
                {
                    if(!hasEsr) {
                        if(oracleQline.cafsl__Product__r.Name.containsIgnoreCase('ESR')){
                            hasEsr = true;
                        }
                        System.debug('getProducts oracleQuote hasEsr: '+hasEsr);
                    }
                    if(!hasFlexTime) {                       
                        if(oracleQline.cafsl__Product__r.Name.containsIgnoreCase('Flex Time')){
                            hasFlextime = true;
                        }
                        System.debug('getProducts oracleQuote hasFlextime: '+hasFlextime);
                    }
                    
                    if(productPackages.contains(oracleQline.cafsl__Product__r.Name)){
                        productPackageList = String.isBlank(productPackageList) ? oracleQline.cafsl__Product__r.Name : productPackageList + ', '+oracleQline.cafsl__Product__r.Name;
                    }
                    else{
                        productList = String.isBlank(productList) ? oracleQline.cafsl__Product__r.Name : productList + ', '+oracleQline.cafsl__Product__r.Name;
                        
                        if(oracleQline.cafsl__Product__r.Name.contains('401'))
                        {
                            x401kProductList = String.isBlank(x401kProductList) ? oracleQline.cafsl__Product__r.Name : x401kProductList + ', '+oracleQline.cafsl__Product__r.Name;
                        }
                    }
                    
                    if(!displayASOForMMS && (oracleQline.cafsl__Product__r.Name.containsIgnoreCase('HR Solutions - ASO (Non Payroll Client)') || oracleQline.cafsl__Product__r.Name.equals('HR Solutions') || oracleQline.cafsl__Product__r.Name.containsIgnoreCase('HR Essentials')))
                    {
                        displayASOForMMS = true;
                    }
                    if(oracleQline.cafsl__Product__r.Name.contains('HR Analytics')){
                        hasHRAnalytics=true;
                    }
                    if(oracleQline.cafsl__Product__r.is_package__c){
                       hrpackageProducts= string.isempty(hrpackageProducts)? oracleQline.cafsl__Product__r.Name: hrpackageProducts+', '+oracleQline.cafsl__Product__r.Name ;
                    }
                    if(oracleQline.cafsl__Product__r.Name.contains('Paychex Flex Engage')){
                        hasFlexEnagage=true;
                        FlexEngagePrice=oracleQline.Customer_Price_unit__c	;
                        FlexEnagageLicenses=FlexEnagageLicenses+oracleQline.cafsl__Quantity__c;
                    }
                }
            }
        }
        else{
            isQuote = false;
            List <OpportunityLineItem> oliList= new List <OpportunityLineItem>();
            oliList = [Select Name,product2.is_package__C,UnitPrice,Quantity  from OpportunityLineItem where OpportunityId =:onboardingOpp.id];
            if(!oliList.isEmpty()){
                for(OpportunityLineItem oliLine : oliList){
                    String productName = oliLine.Name;
                    productName = productName.startsWithIgnoreCase(onboardingOpp.Name) ? productName.removeStart(onboardingOpp.Name+' ') : productName;
                    System.debug(productName+' '+productPackages);
                    if(productPackages.contains(productName)){
                        productPackageList = String.isBlank(productPackageList) ? productName : productPackageList + ', '+productName;
                    }
                    else{
                        productList = String.isBlank(productList) ? productName : productList + ', '+productName;
                        
                        if(productName.contains('401'))
                        {
                            x401kProductList = String.isBlank(x401kProductList) ? productName : x401kProductList + ', '+ productName;
                        }
                    }
                    if(productName.contains('ESR')){
                        hasEsr = true;
                    }
                    else if(productName.containsIgnoreCase('FLEX Time')){
                        hasFlextime = true;
                        //onboardingRecord.Flextime_TAA__c = 'Yes';
                    }
                    
                    if(!displayASOForMMS && (productName.containsIgnoreCase('HR Solutions - ASO (Non Payroll Client)') || productName.equals('HR Solutions') || productName.containsIgnoreCase('HR Essentials')))
                    {
                        displayASOForMMS = true;
                    }
                    if(productName.contains('HR Analytics')){	//Priyanka Added for HR Analytics 
                        hasHRAnalytics=true;
                    }
                    if(oliLine.Product2.is_package__c){
                        hrpackageProducts= string.isempty(hrpackageProducts)? productName: hrpackageProducts+', '+productName ;
                    }
                    if(productName.contains('Paychex Flex Engage')){
                        hasFlexEnagage=true;
                        FlexEngagePrice=oliLine.UnitPrice	;
                        FlexEnagageLicenses=FlexEnagageLicenses+oliLine.Quantity;
                    }
                }
            }
        }
    }

    //Displays opt in/out based on which products are selected    
    public void getOptInOptOut() {
        
        if(refOppProduct != null) {
            
            if(refOppProduct != null && refOppProduct.Flex_Enterprise__c) {
                hasEnterprise = true;
            }
            if(refOppProduct != null && refOppProduct.Flex_Select__c) {
                hasSelect = true;
            }
            if(refOppProduct != null && refOppProduct.Paychex_Flex_Pro__c) {
                hasPro = true;
            }
            if(refOppProduct != null && refOppProduct.ASO__c) {
                hasAso = true;
            }
            if(refOppProduct != null && refOppProduct.Express_Payroll__c) {
                hasExpressPayroll = true;
            }
            if(refOppProduct != null && refOppProduct.Paychex_Solo__c) {
                hasSolo = true;
            }
            
        }
    }
    
    public List<SelectOption> getContacts() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        //List of Contacts and their roles for opportunity
        if(!onboardingOpp.OpportunityContactRoles.isEmpty())
        {
            integer contactCount = onboardingOpp.OpportunityContactRoles.size();
            //Add contacts to drop-down list
            //options.addAll(onboardingOpp.OpportunityContactRoles);
            for(OpportunityContactRole oneContact : onboardingOpp.OpportunityContactRoles)
            {
                options.add(new SelectOption(oneContact.Contact.Id, oneContact.Contact.Name));
                if(oneContact.IsPrimary || contactCount == 1){
                    
                    if(onboardingRecord.Company_Contact__c == null)
                    {onboardingRecord.Company_Contact__c = oneContact.Contact.Id;}
                    if(onboardingRecord.Authorize_Officer__c == null)
                    {onboardingRecord.Authorize_Officer__c = oneContact.Contact.Id;}                   
                }
            }
            //Update company contact and authorized officer            
        }
        return options;
    }
    
    public List<SelectOption> getDocDeskContacts() {
        System.debug('getDocDeskContacts');
        List<SelectOption> docDeskOptions = new List<SelectOption>();
        List<OpportunityContactRole> oppContactRoles = onboardingOpp.OpportunityContactRoles;
        for(OpportunityContactRole ctctRole:oppContactRoles){
            if(ctctRole.IsPrimary){
                defaultContact = ctctRole;
            }
        
        }
        List<Contact> docDeskContacts = new List<Contact>();
        docDeskContacts =( defaultContact != null && defaultContact.ContactId != null) ? [Select Id, Name, Title, Phone, Email from Contact where (AccountId = :onboardingOpp.Account.Id or Id = :defaultContact.ContactId)] :[Select Id, Name, Title, Phone, Email from Contact where AccountId = :onboardingOpp.Account.Id] ;
      
        //docDeskContacts.add()
        docDeskOptions.add(new SelectOption('','--None--'));
        if(!docDeskContacts.isEmpty()) {
            for(Contact c:docDeskContacts) {
                docDeskOptions.add(new SelectOption(c.Id, c.Name));
            }
        }
        return docDeskOptions;
    }
    
    public void getSelectedAuthorizedDocDeskContact() {
        List<Contact> selectedDocDeskContact = new List<Contact>();
        selectedDocDeskContact = [Select Id, Name, Title, Phone, Email from Contact where Id=:selectedAuthorizedContact LIMIT 1];
        
        if(selectedDocDeskContact != null && !selectedDocDeskContact.isEmpty()) {

            onboardingRecord.Authorize_Officer__c = selectedDocDeskContact.get(0).Id; 
            onboardingRecord.Authorized_Officer_Email__c = selectedDocDeskContact.get(0).Email;
            onboardingRecord.Authorized_Officer_Phone__c = selectedDocDeskContact.get(0).Phone;
        }
    }
    
    public void getSelectedPayrollDocDeskContact() {
        List<Contact> selectedDocDeskContact = new List<Contact>();
        selectedDocDeskContact = [Select Id, Name, Title, Phone, Email from Contact where Id=:selectedPayrollContact LIMIT 1];
        System.debug('getSelectedPayrollDocDeskContact selectedDocDeskContact='+selectedDocDeskContact);        
        if(selectedDocDeskContact != null && !selectedDocDeskContact.isEmpty()) {
            onboardingRecord.PayrollContact__c = selectedDocDeskContact.get(0).Id;
            onboardingRecord.PayrollContact_Email__c = selectedDocDeskContact.get(0).Email;
            onboardingRecord.PayrollContact_Phone__c = selectedDocDeskContact.get(0).Phone;
            onboardingRecord.PayrollContact_Title__c = selectedDocDeskContact.get(0).Title;
        }
    }
    
    //Boolean options
    public List<SelectOption> getBoolOption() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','--None--'));
        options.add(new SelectOption('True','Yes'));
        options.add(new SelectOption('False','No'));
        return options;
    }
    
    //GL options
    public List<SelectOption> getGlOptions() {
        List<SelectOption> getGlOptions = new List<SelectOption>();
        getGlOptions.add(new SelectOption('','--None--'));
        getGlOptions.add(new SelectOption('GL Report','GL Report'));
        //options.add(new SelectOption('','GL Service'));
        getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return getGlOptions;
    }
    
    //PreAssignedClientNum options
    public List<SelectOption> getPreAssignedClientNumOptions() {
        List<SelectOption> getPreAssignedClientNumOptions = new List<SelectOption>();
        getPreAssignedClientNumOptions.add(new SelectOption('No','No'));
        getPreAssignedClientNumOptions.add(new SelectOption('Yes','Yes'));
        //options.add(new SelectOption('','GL Service'));
        //getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return getPreAssignedClientNumOptions;
    }
    
    //Pay on Demand Options
    public List<SelectOption> getPayOnDemandOptions() {
        List<SelectOption> getPayOnDemandOptions = new List<SelectOption>();
        getPayOnDemandOptions.add(new SelectOption('Decline','Decline'));
        getPayOnDemandOptions.add(new SelectOption('Pay On Demand','Pay On Demand'));
        //options.add(new SelectOption('','GL Service'));
        //getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return getPayOnDemandOptions;
    }
    
    //Authorized Officer options
    public List<SelectOption> getAuthorizedOffOptions() {
        List<SelectOption> getAuthorizedOffOptions = new List<SelectOption>();
        getAuthorizedOffOptions.add(new SelectOption('No','No'));
        getAuthorizedOffOptions.add(new SelectOption('Yes','Yes'));
        //options.add(new SelectOption('','GL Service'));
        //getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return getAuthorizedOffOptions;
    }
    
    //DBA Options
    public List<SelectOption> getDBAOptions() {
        List<SelectOption> DBAOptions = new List<SelectOption>();
        DBAOptions.add(new SelectOption('','--None--'));
        DBAOptions.add(new SelectOption('No','No'));
        DBAOptions.add(new SelectOption('Yes','Yes'));
        //options.add(new SelectOption('','GL Service'));
        //getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return DBAOptions;
    }
    
    //Irs is delivery address options
    public List<SelectOption> getIrsIsDeliveryOptions() {
        List<SelectOption> irsIsDeliveryOptions = new List<SelectOption>();
        irsIsDeliveryOptions.add(new SelectOption('Yes','Yes'));
        irsIsDeliveryOptions.add(new SelectOption('No','No'));
        //options.add(new SelectOption('','GL Service'));
        //getGlOptions.add(new SelectOption('Decline Both','Decline Both'));
        return irsIsDeliveryOptions;
    }
    
    //Validate list of Onboarding or Opportunity fields
    public Boolean verifyList(List<string> onboardingfields, List<string> oppfields, List<string> oppAccountFieldsList){
        Boolean validList = true;
        for(string field : onboardingfields){
            System.debug('verifyList field='+field+' onboardingRecord.get(field)='+onboardingRecord.get(field));
            if(onboardingRecord.get(field) == null || onboardingRecord.get(field) == ''){
                missingFields += '/n'+field;
                validList = false;break;
            }
            else if( onboardingRecord.get(field) == '--None--'){
                missingFields += '/n'+field;
                validList = false;break;
            }
            else if(field == 'PreAssignedId__c' && onboardingRecord.PreAssignedClientNum__c == 'Yes' && onboardingRecord.get(field) == ''){
                missingFields += '/n'+field;
                validList = false;break;
            }
        }
        if(oppFields != null)
        {
            for(string field : oppfields){
                System.debug('verifyList oppfield='+field+' value='+onboardingOpp.get(field));
                if(onboardingOpp.get(field) == null || onboardingOpp.get(field) == '--None--'){
                    missingFields += '/n'+field;
                    validList = false;break;
                }
            }
        }
        if(oppAccountFieldsList != null)
        {
            Account acc = onboardingOpp.Account;
            for(string field : oppAccountFieldsList){
                System.debug('verifyList oppAccountField='+field+' value='+acc.get(field));
                if(acc.get(field) == null || acc.get(field) == ''){
                    missingFields += '/n'+field;
                    validList = false;break;
                }
            }
        }
        System.debug('missingFields='+missingFields);
        System.debug('validList='+validList);
        return validList;
    }
    
    //Validate list of boolean fields
    public Boolean verifyList(List<Boolean> fields){
        Boolean validList = true;
        for(Boolean field : fields){
            if(!field){
                validList = false;break;
                missingFields += '/n'+field;
            }
        }
        return validList;
    }    
    
    //Validate Onboarding section
    public Boolean onboardingValid()
    {
        String[] listToValidate = new String[]{'Onboarding_Contact__c','Accounts_Payable_Contact__c'};
            Boolean valid = verifyList(listToValidate, null,null);
        return valid;
    }
    
    //Validate PESS section
    public Boolean pessValid()
    {
        Boolean valid = false;
        String[] listToValidate = new String[]{'PESS_Background_Screening__c','PESS_Drug_Testing__c','PESS_I9_Verification__c','PESS_Motor_Vehicle_Report__c'};
            for(string field : listToValidate){
                if(onboardingRecord.get(field) == true){
                    valid = true;
                }
            }
        return valid;
    }    
    
    //Validate POP section
    public Boolean popValid()
    {
        Boolean valid = false;
        String[] listToValidate = new String[]{'Dental__c','Group_Term_Life__c','Short_Term_Disability__c','Core_Medical__c','Vision__c','Accidental_Death__c','Long_Term_Disability__c'}; 
            for(string field : listToValidate){
                if(onboardingRecord.get(field) == true){
                    valid = true;
                }
            }
        return valid;
    }    
    
    //Validate form
    public void Validate()
    {
        System.debug('Validating... onboardingType='+onboardingType);
        missingFields = '';
        if(onboardingType == 'Doc Desk'){
            System.debug('onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c);
            
            //If this is an NCO form, validate specifically for NCO fields.
            if(onboardingRecord.Form_Type__c == 'NCO')
            {
                try{
                    validateNCO();
                }
                catch(exception ex){
                    System.debug('exception found in Validate methond for NCO: '+ex);
                    validRecord = true;
                }
            }
            else if(onboardingRecord.Form_Type__c == 'MPSC')
            {
                try{
                    validateMPSC();
                }
                catch(exception ex){
                    System.debug('exception found: '+ex);
                    validRecord = true;
                }
            }
            else
            {
                try{
                    //validateDocDesk();
                }
                catch(exception ex){
                    System.debug('exception found: '+ex);
                    validRecord = true;
                }
            }
            System.debug('validRecord='+validRecord);
        }
        else if(onboardingType == 'HR Solutions'){
            try{
                String[] onboardingValidate = new String[]{'Authorize_Officer__c','Company_Contact__c','Preferred_Contact_Method__c','Best_Call_Time__c','New_Existing__c',
                    'Authorized_Officer_Title__c','Authorized_Officer_Phone__c','Authorized_Officer_Email__c','Authorized_Off_is_HR_Contact__c','Multi_Id_Submission__c',
                    'Top_3_HR_Needs_Why__c','Client_Company_IDs__c','Industry__c','How_long_a_client__c','Employee_Headcount_Status__c','Other_Paychex_products_in_use__c','Client_Success_Meeting_Next_Step__c','Client_Success_Meeting_Date_Time__c'};
                        
                    String[] oppValidate = new String[]{'Payroll_Platform__c'};
                        validRecord = true;
                if(onboardingRecord.Multi_ID__c){
                    onboardingValidate.add( 'Total_Num_EE__c');
                }
                if(onboardingRecord.Multi_Id_Submission__c=='Yes'){
                    onboardingValidate.add( 'NumMultiIds__c');
                }
                if(onboardingRecord.MultiBillingOption__c=='true'){
                    onboardingValidate.add('Sales_Parent__c');
                }
                if(onboardingRecord.Multi_State__c == 'Yes'){
 			onboardingValidate.add('HR_Sites__c');
            onboardingValidate.add('Employee_Headcount_In_Other_States__c');
            System.debug('***ONBOARDING Validate***'+onboardingValidate);                }
                if(onboardingRecord.Authorized_Off_is_HR_Contact__c != null && onboardingRecord.Authorized_Off_is_HR_Contact__c == 'Yes'){
                    //onboardingRecord.PayrollContact__c = onboardingRecord.Authorize_Officer__c;
                    //selectedPayrollContact = onboardingRecord.PayrollContact__c;
                    onboardingRecord.HR_Contact_Name__c = onboardingRecord.Authorized_Officer_Name__c;
                    onboardingRecord.HR_Contact_Title__c = onboardingRecord.Authorized_Officer_Title__c;
                    onboardingRecord.HR_Contact_Phone__c = onboardingRecord.Authorized_Officer_Phone__c;
                }
                if(onboardingRecord.Authorized_Off_is_HR_Contact__c == '' || (onboardingRecord.Authorized_Off_is_HR_Contact__c != null && onboardingRecord.Authorized_Off_is_HR_Contact__c == 'No')){
                    onboardingValidate.add('HR_Contact_Name__c');
                    onboardingValidate.add('HR_Contact_Title__c');
                    onboardingValidate.add('HR_Contact_Phone__c');
                }
                if(hasHRAnalytics){ //Priyanka Added for HR Analytics 
                    onboardingValidate.add('Invoice_Email_Address__c');
                    onboardingValidate.add('HR_Analytics_Contact__c');
                    onboardingValidate.add('HR_Analytics_Contact_Email__c');	
                    onboardingValidate.add('HR_Analytics_billing__c');
                    if(onboardingRecord.HR_Analytics_billing__c=='False' && String.isempty(onboardingRecord.Bank_Account_Form__c)){
                         onboardingValidate.add('Bank_Account_Form__c');
                    }
                }
            	if(hasFlexEnagage){//Priyanka Added for Paychex Flex Enagage
                   	onboardingValidate.add('Flex_Engage_Invoice_Email__c');
                    onboardingValidate.add('Flex_Engage_Contact__c');
                    onboardingValidate.add('Flex_Engage_Contact_Email__c');
                    onboardingValidate.add('Flex_Engage_Service_Start_Date__c');	
                }
                
                validRecord = verifyList(onboardingValidate,oppValidate,null);
                /*if(onboardingRecord.PESS__c && validRecord){
validRecord = pessValid();
System.debug('PESS INFORMATOIN: '+validRecord);
}*/
                //Continue if currently valid
                if(validRecord)// && onboardingOpp.Account.Email__c != null)
                {
                    if(onboardingRecord.Product__c !='PESS' && onboardingRecord.Product__c !='HR Solutions-Flex' || onboardingRecord.Product__c =='HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
                    {
                        if(onboardingRecord.HRE_Decision_Factors__c == null && onboardingRecord.HRE_Decision_Factors_2__c == null && onboardingRecord.HRE_Decision_Factors_3__c == null)
                        { validRecord = false;}
                        else if (onboardingRecord.Decision_Factors_Other__c == null &&(onboardingRecord.HRE_Decision_Factors__c =='Other'||onboardingRecord.HRE_Decision_Factors_2__c =='Other'||onboardingRecord.HRE_Decision_Factors_3__c =='Other'))
                        {validRecord = false;}
                    }
                    switch on onboardingRecord.Product__c 
                    {
                        when 'HR Solutions-Flex'
                        {validateFlex();}
                        when 'HR Solutions for Non-Payroll'
                        {validateNonPayroll();}
                        when 'Custom Employee Handbook'
                        {validateHandbook();}
                        when 'Paychex HR Essentials'
                        {validateHREssentials();}
                    }
                } 
            } 
            catch(exception e){validRecord = false;
            System.debug('exception' + e);}
        }
    }
    
    public void validateFlex()
    {
        onboardingRecord.Flex_Multi_Debit__c = 'Multi Debit';
        // Update for Client Profile Enhancement ECP
        String[] onboardingList = new String[]{'HRS_Sales_Rep__c','MultiBillingOption__c','Flex_Multi_Debit__c','Run_Date__c','First_Check_Date__c' };
            String[] oppList = new String[]{'Employees_Paid_Per_Payroll__c'};
                
                if(onboardingRecord.New_Existing__c == 'Existing Paychex Client')
            {
                onboardingList.add('Previous_Platform__c');
                if(onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
                {onboardingList.add('New_Branch__c');}
            }
        if(onboardingOpp.Employees_Paid_Per_Payroll__c >= 50)
        {onboardingList.add('MultiProdServiceCenter__c');}
        validRecord = verifyList(onboardingList,oppList,null) ? true : false;
        
        //Continue if valid 
        if(validRecord)  {
            if((onboardingRecord.Pop__c && !popValid()) || (onboardingRecord.Add_Onboarding__c && !onboardingValid()))
            { validRecord = false;}
        }     
    }
    
    public void validateNonPayroll()
    {
        onboardingRecord.Flex_Multi_Debit__c = 'Multi Debit';
        String[] stringList = new String[]{'HRS_Sales_Rep__c','Date_Business_Formed__c','Run_Date__c'};
            validRecord = verifyList(stringList, null,null) ? true : false;    
    }
    
    public void validateHandbook()
    {
        String[] stringList = new String[]{'PayrollProcessed__c','Handbook_Format__c','Date_Business_Formed__c'};
            if(onboardingRecord.Tax_Exempt__c){
                stringList.add('Tax_Exempt_Id__c');
            }
        validRecord = verifyList(stringList, null,null) ? true : false;    
    }
    
    public void validateHREssentials()
    {
        String[] stringList = new String[]{'HR_Admin__c','HRE_Reason_Selected__c','Date_Business_Formed__c','PayrollProcessed__c','HRE_Existing__c','HRE_Existing_Safety_Manual__c','Handbook_Format__c'};
            if(onboardingRecord.Tax_Exempt__c){
                stringList.add('Tax_Exempt_Id__c');
            }
        if(onboardingRecord.HRE_Existing__c == 'True')
        {stringList.add('HRE_Paychex_created_existing__c');}
        if(onboardingRecord.HRE_Existing_Safety_Manual__c =='True')
        {stringList.add('HRE_Paychex_created_existing_safety__c');}
        if(onboardingRecord.Tax_Exempt__c)
        {stringList.add('Tax_Exempt_Id__c');}
        validRecord = verifyList(stringList, null,null) ? true : false;
    }
/*    
    //Validates Doc Desk form -- no longer used?
    public void validateDocDesk(){
        System.debug('Validating Doc Deck');
        String[] oppList = new String[]{'Payroll_Current_Prior_Method__c', 'New_or_Existing_Business__c', 'LeadSource', 'Employees_Paid_Per_Payroll__c', 'Service_Location__c', 
            'Payroll_Platform__c', 'First_Payroll_Delivery_Method__c'};
                
                String[] onboardingList = new String[]{'Skylight__c', 'Pay_Demand__c', 'PriorWagesLoaded__c', 'Business_Structure__c', 
                    'Run_Date__c', 'First_Check_Date__c', 'PeriodEndDate__c', 'NumOf1099s__c', 'EmpsToLoad__c', 'Authorized_Officer_Title__c', 'Authorized_Officer_Phone__c', 'Authorized_Officer_Email__c', 
                    'PayrollContact_Title__c', 'PayrollContact_Phone__c', 'PayrollContact_Email__c', 'Training__c', 'StateProcessedIn__c', 'PriceLock3Year__c','PreAssignedClientNum__c'};
                        
                        if(onboardingRecord.IrsIsDelivery__c == 'No'){
                            onboardingList.add('Irs_Address__c');
                        }  
        if(onboardingRecord.Combo__c == 'Yes'){
            onboardingList.add('NumComboIds__c');
        }
        if(onboardingRecord.RelationWithAddAccount__c == 'Yes'){
            onboardingList.add('RelatedAccountId__c');
        } 
        if(onboardingRecord.Multi_Id_Submission__c == 'Yes'){
            onboardingList.add('NumMultiIds__c');
        }
        if(onboardingRecord.PreAssignedClientNum__c == 'Yes'){
            onboardingList.add('PreAssignedId__c');
        }
        if(onboardingRecord.Business_Structure__c == 'LLC'){
            onboardingList.add('Taxed_as_S_Corp__c');
        }
        if(hasFlextime){
            onboardingList.add('Flextime_Date__c');
            onboardingList.add('Flextime_TAA__c');
            onboardingList.add('NumFlexId__c');
            onboardingList.add('Flextime_Timeclock__c');
        }
        if(hasEsr){
            onboardingList.add('ESR_educationInstitution__c');
            onboardingList.add('ESR_selfInsuredPlan__c');
            onboardingList.add('ESR_UnionEmps__c');
            onboardingList.add('ESR_PriorMedRenewalDate__c');
        }
        if(hasEnterprise == true || hasPro == true || hasAso == true){
            onboardingList.add('GL__c');
            onboardingList.add('Workers_Compensation__c');
            onboardingList.add('ReadyChex__c');
        }
        if(hasSelect == true){
            onboardingList.add('GL__c');
            onboardingList.add('ReadyChex__c');
        }
        if(onboardingRecord.Business_Structure__c != 'LLC' && onboardingRecord.Taxed_as_S_Corp__c != false)
        {
            onboardingRecord.Taxed_as_S_Corp__c = false;
        }
        System.debug('validateDocDesk onboardingRecord.PreAssignedClientNum__c='+onboardingRecord.PreAssignedClientNum__c+' onboardingRecord.PreAssignedId__c='+onboardingRecord.PreAssignedId__c);
        if(onboardingRecord.PreAssignedClientNum__c == 'No' && !String.isBlank(onboardingRecord.PreAssignedId__c)){
            System.debug('validateDocDesk setting onboardingRecord.PreAssignedId__c to null');
            onboardingRecord.PreAssignedId__c = '';
        }
        if(onboardingRecord.Pay_Demand__c == null)
        {
            onboardingRecord.Pay_Demand__c = 'Decline';
        }
        
        validRecord = verifyList(onboardingList, oppList,null) ? true : false;
        if(!(onboardingOpp.StageName.contains('Sold'))) {
            validRecord = false;
        }
        
    }
   */
    //Validates the MPSC Form
    public void validateMPSC(){
        System.debug('Validating MPSC');
        String[] oppList = new String[]{'Employees_Paid_Per_Payroll__c','New_or_Existing_Business__c', 'Service_Location__c', 'Payroll_Platform__c', 'LeadSource', 'First_Payroll_Delivery_Method__c', 'Payroll_Current_Prior_Method__c'};
            String[] onboardingList = new String[]{'Training__c', 'Skylight__c', 'Pay_Demand__c', 'PriorWagesLoaded__c', 'Business_Structure__c', 'Run_Date__c', 'First_Check_Date__c', 'PeriodEndDate__c','Does_Company_Need_1099s__c', 'EmpsToLoad__c', 'Authorized_Officer_Title__c', 'Authorized_Officer_Phone__c', 
                'Authorized_Officer_Email__c', 'PayrollContact_Title__c', 'PayrollContact_Phone__c', 'PayrollContact_Email__c', 'StateProcessedIn__c', 'PriceLock3Year__c','PreAssignedClientNum__c'};
                    if(onboardingRecord.IrsIsDelivery__c == 'No'){
                        onboardingList.add('Irs_Address__c');
                    }
        
        if(has401kProduct)
        {
            onboardingList.add('X401_k_Plan_Start_Date__c');
        }

        if(onboardingRecord.Combo__c == 'Yes'){
            onboardingList.add('NumComboIds__c');
        }
        if(onboardingRecord.RelationWithAddAccount__c == 'Yes'){
            onboardingList.add('RelatedAccountId__c');
            onboardingRecord.RelatedAccountId__c = onboardingOpp.AccountId;
            onboardingRecord.Sales_Parent__c = onboardingOpp.AccountId;
        } 
        if(onboardingRecord.Flextime_TAA__c == 'Yes'){
            //onboardingList.add('')
            onboardingList.add('TAA_Site_Id__c');
            hasExistingTAA = true;
        }
        if(onboardingRecord.Multi_Id_Submission__c  == 'Yes'){
            onboardingList.add('NumMultiIds__c');
        }
        if(onboardingRecord.Does_Company_Need_1099s__c  == 'Yes'){
            onboardingList.add('NumOf1099s__c');
        }
        if(onboardingRecord.PreAssignedClientNum__c == 'Yes'){
            onboardingList.add('PreAssignedId__c');
        }
         if(onboardingRecord.Multi_State__c =='Yes'){
            onboardingList.add('HR_Sites__c');
            //onboardingList.add('Employee_Headcount_In_Other_States__c');
            System.debug('*** ONBOARDING LIST*** '+onboardingList);

        }
        if(onboardingRecord.Business_Structure__c == 'LLC'){
            onboardingList.add('Taxed_as_S_Corp__c');
        }
        
        if(hasFlextime){
            onboardingList.add('Flextime_Date__c');
            onboardingList.add('Flextime_TAA__c');
            onboardingList.add('NumFlexId__c');
            onboardingList.add('Flextime_Timeclock__c');
        }
        
        if(hasEsr){
            onboardingList.add('ESR_educationInstitution__c');
            onboardingList.add('ESR_selfInsuredPlan__c');
            onboardingList.add('ESR_UnionEmps__c');
            onboardingList.add('ESR_PriorMedRenewalDate__c');
        }
        if(hasEnterprise == true || hasPro == true || hasAso == true){
            onboardingList.add('GL__c');
            onboardingList.add('Workers_Compensation__c');
            onboardingList.add('ReadyChex__c');
            if(onboardingRecord.GL__c == null || onboardingRecord.GL__c != 'GL Service')
            {
                onboardingRecord.Accounting_Software__c = '';
                onboardingRecord.Other_Accounting_Software__c = '';
            }
            if((onboardingRecord.GL__c != null && onboardingRecord.GL__c == 'GL Service') && !hasSelect && !hasExpressPayroll){
                onboardingList.add('Accounting_Software__c');
                if(onboardingRecord.Accounting_Software__c != null && onboardingRecord.Accounting_Software__c == 'Other Software')
                {
                    onboardingList.add('Other_Accounting_Software__c');
                }
            }
        }
        if(hasSelect == true){
            onboardingList.add('GL__c');
            onboardingList.add('ReadyChex__c');

        }
        if(onboardingRecord.Business_Structure__c != 'LLC' && onboardingRecord.Taxed_as_S_Corp__c != false)
        {
            onboardingRecord.Taxed_as_S_Corp__c = false;
        }
        if(displayASOForMMS){
            oppList.add('Handbook_Contact__c');
            onboardingList.add('Spanish__c');
            onboardingList.add('Handbook_Format__c');
            onboardingList.add('HR_Admin__c');
            onboardingList.add('HRE_Num_of_Locations__c');
            onboardingList.add('HRE_Reason_Selected__c');
            onboardingList.add('HRE_Existing__c');
            onboardingList.add('HRE_Existing_Safety_Manual__c');
        }
        if(onboardingRecord.PreAssignedClientNum__c == 'No' && !String.isBlank(onboardingRecord.PreAssignedId__c)){
            System.debug('validateDocDesk setting onboardingRecord.PreAssignedId__c to Blank');
            onboardingRecord.PreAssignedId__c = '';
        }
        validRecord = verifyList(onboardingList, oppList,null) ? true : false;
        if(!(onboardingOpp.StageName.contains('Sold'))) {
            validRecord = false;
        }
        
    }
    
    //Validate all the NCO fields.
    public void validateNCO(){
        System.debug('Validating NCO');
        String[] oppList = new String[]{'New_or_Existing_Business__c', 'Payroll_Current_Prior_Method__c', 'LeadSource'};
            String[] onboardingList = new String[]{'Authorized_Officer_Title__c', 'Authorized_Officer_Phone__c', 
                'Authorized_Officer_Email__c', 'PayrollContact_Title__c', 'PayrollContact_Phone__c', 'PayrollContact_Email__c', 'Spanish_Speaking_Needs__c',
                'Does_Client_Use_DBA__c', 'Combo__c','Does_Company_Need_1099s__c', 'Multi_Id_Submission__c', 'Business_Structure__c', 
                'EmpsToLoad__c', 
                'Authorized_Off_is_Payroll_Contact__c'}; 
                    String[] oppAccountFieldsList = new String[]{'BillingStreet', 'BillingPostalCode', 'BillingState', 'BillingCity', 'Federal_ID_Number__c', 'Name', 'Phone'};
    	
        if(hasPayrollProduct)
        {
            oppList.addAll(new String[]{'Employees_Paid_Per_Payroll__c', 'First_Payroll_Delivery_Method__c'});
            
            onboardingList.addAll(new String[]{'StateProcessedIn__c', 'Pay_Demand__c', 'Workers_Comp_Policy__c', 'PriorWagesLoaded__c', 'Ongoing_Call_Day_of_the_Week__c', 'First_Check_Date__c', 'Client_Require_Instructions__c',
                'Ongoing_Check_Day_of_the_Week__c', 'Run_Date__c', 'RelationWithAddAccount__c', 'IrsIsDelivery__c', 'Ongoing_Pay_Period_End_Date__c', 'PeriodEndDate__c', 'Ongoing_Delivery__c'});
            
            if(onboardingRecord.IrsIsDelivery__c == 'No'){
                onboardingList.add('Irs_Address__c');
            }  
            
            if(hasSelect == true)
            {
                System.debug('***HAS SELECT***');
                //onboardingList.add('GL__c');
                //onboardingList.add('ReadyChex__c');
        	}
          
            if(hasEnterprise == true || hasPro == true || hasAso == true){
                System.debug('***HAS Enterprise, Pro, or ASO***');
                onboardingList.add('GL__c');
                onboardingList.add('Workers_Compensation__c');
                onboardingList.add('ReadyChex__c');
                if(onboardingRecord.GL__c == null || (onboardingRecord.GL__c != 'GL Service'))
                {
                    onboardingRecord.Accounting_Software__c = '';
                    onboardingRecord.Other_Accounting_Software__c = '';
                }
                if(onboardingRecord.GL__c != null && (onboardingRecord.GL__c == 'GL Service') && !hasSelect && !hasExpressPayroll){
                    onboardingList.add('Accounting_Software__c');
                    if(onboardingRecord.Accounting_Software__c != null && onboardingRecord.Accounting_Software__c == 'Other Software')
                    {
                        onboardingList.add('Other_Accounting_Software__c');
                    }
                }
            }
        }

        if(onboardingRecord.Flextime_TAA__c == 'Yes'){
            //onboardingList.add('')
            onboardingList.add('TAA_Site_Id__c');

            hasExistingTAA = true;
        }
        if(has401kProduct)
        {
            onboardingList.add('X401_k_Plan_Start_Date__c');
            oppList.add('X401_k__c');
        }
        
        if(onboardingRecord.Combo__c == 'Yes'){
            onboardingList.add('NumComboIds__c');
        }
        
        if(onboardingRecord.Multi_Id_Submission__c == 'Yes'){
            onboardingList.add('NumMultiIds__c');
        }
        if(onboardingRecord.Does_Company_Need_1099s__c == 'Yes'){
            onboardingList.add('NumOf1099s__c');
        }
        if(onboardingRecord.Multi_State__c =='Yes'){
            onboardingList.add('HR_Sites__c');

        }
        
        if(onboardingRecord.Business_Structure__c == 'LLC'){
            onboardingList.add('Taxed_as_S_Corp__c');
        }
        
        if(onboardingRecord.Authorized_Off_is_Payroll_Contact__c != null && (onboardingRecord.Authorized_Off_is_Payroll_Contact__c == 'No' || onboardingRecord.Authorized_Off_is_Payroll_Contact__c == '')){
            onboardingList.add('PayrollContact__c');
            onboardingList.add('PayrollContact_Title__c');
            onboardingList.add('PayrollContact_Phone__c');
            onboardingList.add('PayrollContact_Email__c');
        }
        
        if(onboardingRecord.Does_Client_Use_DBA__c != null && onboardingRecord.Does_Client_Use_DBA__c == 'Yes'){
            oppAccountFieldsList.add('DBA__c');
            onboardingList.add('DBA_Name_on_Checks_and_Reports__c');
        }
        
        if(onboardingRecord.Workers_Comp_Policy__c != null && onboardingRecord.Workers_Comp_Policy__c == 'Yes'){
            onboardingList.add('Insurance_Carrier__c');
            onboardingList.add('Workers_Comp_Expiration_Date__c');
        }
        if(hasFlextime){
            onboardingList.add('Flextime_Date__c');
            onboardingList.add('Flextime_TAA__c');
            onboardingList.add('NumFlexId__c');
            onboardingList.add('Flextime_Timeclock__c');
        }
        if(hasEsr){
            onboardingList.add('ESR_educationInstitution__c');
            onboardingList.add('ESR_selfInsuredPlan__c');
            onboardingList.add('ESR_UnionEmps__c');
            onboardingList.add('ESR_PriorMedRenewalDate__c');
        }
        if(displayASOForMMS){
            oppList.add('Handbook_Contact__c');
            onboardingList.add('Spanish__c');
            onboardingList.add('Handbook_Format__c');
            onboardingList.add('HR_Admin__c');
            onboardingList.add('HRE_Num_of_Locations__c');
            onboardingList.add('HRE_Reason_Selected__c');
            onboardingList.add('HRE_Existing__c');
            onboardingList.add('HRE_Existing_Safety_Manual__c');
        }
        if(onboardingRecord.Business_Structure__c != 'LLC' && onboardingRecord.Taxed_as_S_Corp__c != false)
        {
            onboardingRecord.Taxed_as_S_Corp__c = false;
        }
        
        if(onboardingRecord.Authorized_Off_is_Payroll_Contact__c != null && onboardingRecord.Authorized_Off_is_Payroll_Contact__c == 'Yes')
        {
            onboardingRecord.PayrollContact__c = onboardingRecord.Authorize_Officer__c;
            selectedPayrollContact = onboardingRecord.PayrollContact__c;
            System.debug('applyParentData selectedPayrollContact='+selectedPayrollContact+' onboardingRecord.PayrollContact__c='+onboardingRecord.PayrollContact__c);
            onboardingRecord.PayrollContact_Title__c = onboardingRecord.Authorized_Officer_Title__c;
            onboardingRecord.PayrollContact_Phone__c = onboardingRecord.Authorized_Officer_Phone__c;
            onboardingRecord.PayrollContact_Email__c = onboardingRecord.Authorized_Officer_Email__c;
        }

        validRecord = verifyList(onboardingList, oppList, oppAccountFieldsList) ? true : false;
        System.debug('Validation Result -- ' + validRecord);
        
        //If it's a CA Mandate submission, allow the NCP to be submitted prior to status being set to Sold
        if(!(onboardingOpp.StageName.contains('Sold')) && !(isMandateSale)) {
            validRecord = false;
        }
    }
    
    public boolean getDisplaySPUpload()
    {
        List<String> spProducts = Label.Onboarding_Sharepoint_Products.Split(',');
        Boolean displaySharePointButton = (spProducts.contains(onboardingRecord.Product__c) ? false :true);
        return displaySharePointButton;
    }
    
    //Saves the changes made to the Opportunity and Account
    public PageReference saveChanges()
    {
        if(onboardingRecord.Authorize_Officer__c!=null && onboardingRecord.IsCompanyContact__c)
        {
            if(onboardingRecord.Company_Contact__c != onboardingRecord.Authorize_Officer__c)
            {onboardingRecord.Company_Contact__c = onboardingRecord.Authorize_Officer__c;}
        }
        onboardingRecord.Branch_Number__c = (String.isNotBlank(onboardingOpp.Account.AccountNumber) ? onboardingOpp.Account.AccountNumber.substringBefore('-') : null );
        onboardingRecord.Client_Number__c = (!String.isBlank(onboardingOpp.Account.AccountNumber) ? onboardingOpp.Account.AccountNumber.substringAfter('-') : null );
        update(onboardingOpp);
        update(onboardingOpp.Account);
        if(onboardingType == 'Doc Desk' && (onboardingOpp.Reference_Opportunity_Products__r).size() != 0) {
            onboardingRecord.Reference_Opportunity_Product__c = onboardingOpp.Reference_Opportunity_Products__r.get(0).Id;
            update(onboardingOpp.Reference_Opportunity_Products__r);
        }
        upsert(onboardingRecord);
        
        //redirect();
        /*
        
        */
        PageReference pageref = fssUpdate ? new PageReference('/apex/OnboardingFSS?id=' + incomingId) : new PageReference('/' + incomingId);
        pageref.setRedirect(true);
        return pageref;
    }
    public PageReference saveChanges2()
    {
        if(onboardingRecord.Authorize_Officer__c!=null && onboardingRecord.IsCompanyContact__c)
        {
            if(onboardingRecord.Company_Contact__c != onboardingRecord.Authorize_Officer__c)
            {onboardingRecord.Company_Contact__c = onboardingRecord.Authorize_Officer__c;}
        }
        onboardingRecord.Branch_Number__c = (String.isNotBlank(onboardingOpp.Account.AccountNumber) ? onboardingOpp.Account.AccountNumber.substringBefore('-') : null );
        onboardingRecord.Client_Number__c = (!String.isBlank(onboardingOpp.Account.AccountNumber) ? onboardingOpp.Account.AccountNumber.substringAfter('-') : null );
        update(onboardingOpp);
        update(onboardingOpp.Account);
        if(onboardingType == 'Doc Desk' && (onboardingOpp.Reference_Opportunity_Products__r).size() != 0) {
            onboardingRecord.Reference_Opportunity_Product__c = onboardingOpp.Reference_Opportunity_Products__r.get(0).Id;
            update(onboardingOpp.Reference_Opportunity_Products__r);
        }
        System.debug('onboardingRecord.HR_Sites__c : '+onboardingRecord.HR_Sites__c+' onboardingRecord.Multi_State__c: '+onboardingRecord.Multi_State__c);
        upsert(onboardingRecord);
        
        //redirect();
        PageReference pageref = new PageReference('/apex/Onboarding?id=' + incomingId);
        // pageref.setRedirect(true);
        return pageref;
    }
    
    public PageReference FSSChanges()
    {
        fssValidate();    
        if(onboardingRecord.Authorize_Officer__c!=null && onboardingRecord.IsCompanyContact__c)
        {
            if(onboardingRecord.Company_Contact__c != onboardingRecord.Authorize_Officer__c)
            {onboardingRecord.Company_Contact__c = onboardingRecord.Authorize_Officer__c;}
        }
        upsert(onboardingRecord);
        update(onboardingOpp.Account);
        update(onboardingOpp);
        fssUpdate = false;
        PageReference pageref;
        pageref = new PageReference('/apex/OnboardingFSS?id=' + onboardingOpp.Id);
        pageref.setRedirect(true);
        return pageref;
        /*if(fssValid){
saveChanges();
}*/
        
    }
    public void fssValidate()
    {
        fssValid = true;
        if(onboardingRecord.Run_Date__c == null)
        {fssValid = false; }
        else if(onboardingRecord.New_Branch__c == null && onboardingRecord.New_Existing__c =='Existing Paychex Client' && onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
        {fssValid = false;}
        else if(onboardingRecord.Branch_Number__c == null && onboardingRecord.New_Branch__c == null&&onboardingRecord.MultiProdServiceCenter__c==null)
        {fssValid = false;}
    }
    
    public PageReference redirect(){
        PageReference pageref = fssUpdate ? new PageReference('/apex/OnboardingFSS?id=' + incomingId) : new PageReference('/' + incomingId);
        pageref.setRedirect(true);
        return pageref;
    }
    
    public void updateContacts()
    {
        if(onboardingRecord.IsCompanyContact__c && onboardingRecord.Company_Contact__c != null)
        {
            onboardingRecord.Authorize_Officer__c = onboardingRecord.Company_Contact__c;
            validate();
        }
    }
    
    public void getUserInfo()
    {
        currentUser = [Select Id, email, DSA_FSS__c, DSA_FSS__r.email, Profile.Name,
                        Sales_Division__c,Sales_Org__c
                       From User Where Id=:Userinfo.getUserId()];
        usrSalesDivision=currentUser.Sales_Division__c;
        usrSalesOrg=currentUser.Sales_Org__c;
        isFSS = (currentUser.Profile.Name.contains('HRS Sales Administration') || currentUser.email == onboardingRecord.Alternative_Email__c ? true : false);
        hasFSS = (!String.isBlank(onboardingOpp.Owner.DSA_FSS__c) ? true : false);
        onboardingRecord.RepNumber__c = (!String.isBlank(onboardingOpp.Owner.Person_ID_Number__c) ? onboardingOpp.Owner.Person_ID_Number__c : null);
        fssAddress = (hasFSS ? onboardingOpp.Owner.DSA_FSS__r.email : null);
        isDSM = (!String.isBlank(onboardingRecord.Owner_Manager__c) && currentUser.Id == onboardingRecord.Owner_Manager__c && onboardingOpp.OwnerId != currentUser.Id ? true : false);
    }
    
    public void sendChatter(String ChatterType)
    {
        string chatterMessage;
        List<Id> userIdList = new List<Id>();
        if(ChatterType == 'Virtual')
        {  
            chatterMessage='FlexTime Product included in Submission';  
            List<String> hrPersonIdList = Label.OnboardingTool_Virtual_Users.Split(',');
            List<User> chatterUsers = [Select Id from User where HR_Person_Id__c in :hrPersonIdList];
            
            for(User chatterUser : chatterUsers){
                userIdList.add(chatterUser.Id);
            }            
        }
        else if(ChatterType == 'Sharepoint')
        {
            chatterMessage='An ASO Flex Sale has been submitted for '+onboardingOpp.Name+'.';
            userIdList.add(onboardingRecord.HR_Genralist__c);
        }
        if(!UserIdList.isEmpty())
        {
            ChatterMentionPost.createChatterMentionPost(onboardingOpp.Id,userIdList,chatterMessage);
            ChatterMentionPost.checkPostFeedElements();   
        }
    }
    
    public void EmailValidation()
    {InvalidEmail = (String.isBlank(onboardingRecord.Alternative_Email__c) || !(onboardingRecord.Alternative_Email__c.containsIgnoreCase('@paychex.com')) ? true : false);}
    
    public PageReference emailFSS()
    {
        /* // Priyanka Commented : US# SFDC-28181 
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject('HR Solutions ASO Case ready for review.  Prospect-Client: '+onboardingOpp.Account.Name);
        String emailAddress = ((hasFSS && !onboardingRecord.changeFSS__c) || (onboardingRecord.changeFSS__c && InvalidEmail)) ? fssAddress : onboardingRecord.Alternative_Email__c;
        List<User> emailUser = [Select Id, email from User where isActive=true and email=:emailAddress limit 1];
        if(emailUser != null && !emailUser.isEmpty()) {
            email.setTargetObjectId((emailUser.get(0)).Id);
            email.setSaveAsActivity(false);
            email.setHtmlBody('An HR Solutions ASO submission has been submitted for your approval\n\n<br/>'
                              +'<a href="' + URL.getSalesforceBaseUrl().toExternalForm()+'/apex/OnboardingFSS?id='+incomingId + '">Click this link to review HR Solution ASO submission</a>\n\n');
            email.setPlainTextBody('Client: '+onboardingOpp.Account.Name+' was onboarded onto HR Solutions ASO through Salesforce. Attached is the paperwork associated with this submission\n\n');
            
            Boolean cloneChildProfiles=false;
            // Sends the email          
            Messaging.SingleEmailMessage[] emailList=new Messaging.SingleEmailMessage[]{email};
            if(hasHRAnalytics){
                emailList.add(sendEmailSubscriptionBillingTeam());
            }
            if(hasFlexEnagage){
                emailList.add(sendEmailOrdersHelloTeam());
            }
            Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(emailList);            
            //Update the Fss Email sent to True if email sent successfully, then field will update and task will be created by process builder
            if (emailSend.get(0).isSuccess() || test.isRunningTest()) {
                onboardingRecord.FSS_Email_Sent__c = true;
                update onboardingRecord;
                User currUser = [Select Sales_Division__c,Sales_Org__c From User Where Id = :UserInfo.getUserId()];
                List<Client_Profile_Clone__c> profilesList = Client_Profile_Clone__c.getall().values() ;
                for(Client_Profile_Clone__c  PR: profilesList){
                    if(PR.Sales_Division__c==currUser.Sales_Division__c && PR.Sales_Org__c==currUser.Sales_Org__c){
                        cloneChildProfiles=true;
                    }
                }
                if(cloneChildProfiles){
                    cloneClientProfiletoChilds();
                }
            }
        } else {
            String message = 'Email Address is invalid.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
            displayMessages = true;
            return null;
        }*/
        
        Messaging.SingleEmailMessage[] emailList=new Messaging.SingleEmailMessage[]{};
            if(hasHRAnalytics){
                emailList.add(sendEmailSubscriptionBillingTeam());
            }
            if(hasFlexEnagage){
                emailList.add(sendEmailOrdersHelloTeam());
            }
        Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(emailList);
        //On Submission
        String oppRecordType = RecordTypeHelper.getRecordTypeById(onboardingOpp.RecordTypeId, 'Opportunity').getName();
        Opty_DSA_FSS_RT_MAP__C optyDSAFSSRT = Opty_DSA_FSS_RT_MAP__C.getvalues(oppRecordType);
        onboardingRecord.FSS_Email_Sent__c = true;
        if(onboardingRecord.SubmissionDate__c==null && onboardingRecord.New_Existing__c =='Existing Paychex Client')
        {
            onboardingRecord.SubmissionDate__c = date.today();
            onboardingRecord.Submitter__c = Userinfo.getName();
        }        
        if(optyDSAFSSRT!=null){
            Schema.Recordtypeinfo coreDSART = RecordTypeHelper.getRecordType(optyDSAFSSRT.DSA_FSS_Record_Type__c, 'Opportunity');
            onboardingOpp.RecordTypeId=coreDSART.getRecordTypeId();            
        }
        onboardingOpp.StageName=Label.OppStage_Sold_Submitted;
        saveChanges();
        
        Boolean cloneChildProfiles=false;
        //User currUser = [Select Sales_Division__c,Sales_Org__c From User Where Id = :UserInfo.getUserId()];
        List<Client_Profile_Clone__c> profilesList = Client_Profile_Clone__c.getall().values() ;
        for(Client_Profile_Clone__c  PR: profilesList){
            if(PR.Sales_Division__c==usrSalesDivision && PR.Sales_Org__c==usrSalesOrg){
                cloneChildProfiles=true;
            }
        }        
        if(cloneChildProfiles){
            cloneClientProfiletoChilds();
        }
        
        //SharePointUpload on ASO Submission
        uploadtoSharePoint=true;
        emailSharePoint();
        
        //Redirect to opportunity
        PageReference pageref = fssUpdate ? new PageReference('/apex/OnboardingFSS?id=' + incomingId) : new PageReference('/' + incomingId);
        pageref.setRedirect(true);
        return pageref;
    }
    
        //Priyanka Added this method for HR Analytics 
    public Messaging.SingleEmailMessage sendEmailSubscriptionBillingTeam(){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> hraProductList = productList.split(',');
        string hraProducts;
        for(String prod: hraProductList){
            if(prod.contains('HR Analytics')){
                hraProducts=string.isBlank(hraProducts)? prod: hraProducts+', '+prod;
            }
        }
        string emailText='Hi, </br> </br>';
        
        emailText=emailText+'<B>Sales Rep Name: </B>'+	onboardingOpp.Owner.Name	+'</br>';
        emailText=emailText+'<B>Sales Rep Email Address: </B>'+	onboardingOpp.Owner.Email	+'</br>';
        emailText=emailText+'<B>Sales Rep Telephone Number:</B> '+	onboardingOpp.Owner.Phone	+'</br>';
        emailText=emailText+'<B>Client Name:</B> '+	onboardingOpp.Account.Name	+'</br>';
        emailText=emailText+'<B>FEIN: </B>'+	onboardingOpp.Account.Federal_ID_Number__c +'</br>';
        emailText=emailText+'<B>Multiple IDs: </B>'+	onboardingOpp.Account.Multi_ID_Parent__c +'</br>';
		emailText=emailText+'<B>Billing Address:</B> '+ onboardingOpp.Account_Billing_Address__c	+ '</br>';        
        emailText=emailText+'<B>Number Of Employees to Load:</B> '+ onboardingOpp.Employees_Paid_Per_Payroll__c	+'</br>';
        emailText=emailText+'<B>Service Location:</B> '+onboardingOpp.Service_Location__c	+	'</br>';
        emailText=emailText+'<B>Product: </B>'+ hraProducts +'</br>';
        emailText=emailText+'<B>Client Number: </B>'+ onboardingOpp.Account.AccountNumber	+	'</br>';
        emailText=emailText+'<B>Payroll Package Name:</B> '+ hrpackageProducts +'</br>';
        emailText=emailText+'<B>HR Analytics Contact: </B>'+ onboardingRecord.HR_Analytics_Contact__c+'</br>';
        emailText=emailText+'<B>HR Analytics Contact Email Address:</B> '+ onboardingRecord.HR_Analytics_Contact_Email__c+	'</br>';
        emailText=emailText+'<B>HR Analytics Billing Invoice Email Address:</B> '+ onboardingRecord.Invoice_Email_Address__c +	'</br>';
		emailText=emailText+'<B>Estimate First Run Date: </B>'+ onboardingRecord.Run_Date__c	+'</br>';      
        emailText=emailText+'<B>Bank Account Detail:</B> '+ (onboardingRecord.HR_Analytics_billing__c=='False'? 'See attached new bank detail file '+bankAccountFile : 'Same as on file')	;     
        emailText=emailText+ '</br> </br> Thank You, </br> Salesforce Automation.' ;
        system.debug(emailText);
        String[] fileIdList = new String[]{};
        ContentDocumentLink[] opptyFilesList=[select id, ContentDocument.LatestPublishedVersionId
                                         from ContentDocumentLink where LinkedEntityId=:onboardingOpp.Id];
        
        for(ContentDocumentLink cv :opptyFilesList){
            fileIdList.add(cv.ContentDocument.LatestPublishedVersionId);
        }
        
        string emailaddr = Label.HR_Analytics_Billing_EMail ;
        mail.setToAddresses(new list<String>{emailaddr});
        mail.setReplyTo('sfdc_automation@paychex.com');
        mail.setUseSignature(false); 
        mail.setSaveAsActivity(false); 
        mail.setSenderDisplayName('Salesforce Automation'); 
        mail.setEntityAttachments(fileIdList);
        mail.setSubject(onboardingOpp.Account.Name +' HR Analytics and ASO upgrade '+ onboardingOpp.Primary_Oracle_Quote__r.Name);
        mail.setHtmlBody(emailText);
        return mail;
    }
    
     //Upon Submit if the NCP has Paychex Flex Enagage product then send email ->hasFlexEnagage
    public Messaging.SingleEmailMessage sendEmailOrdersHelloTeam(){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        string emailText='Hi, </br> </br>';
        
        emailText=emailText+'<B> Sales Rep Name: </B>'+	onboardingOpp.Owner.Name	+'</br>';
        emailText=emailText+'<B> Client Name: </B>'+	onboardingOpp.Account.Name	+'</br>';
        emailText=emailText+'<B> Client Number: </B>'+ onboardingOpp.Account.AccountNumber	+	'</br>';        
        emailText=emailText+'<B> Service Start Date: </B>'+	onboardingRecord.Flex_Engage_Service_Start_Date__c.format()	 +'</br>';
        emailText=emailText+'<B> Paychex Flex Engage Contact Name: </B>'+ onboardingRecord.Flex_Engage_Contact__c+'</br>';
        emailText=emailText+'<B> Paychex Flex Engage Contact Email: </B>'+ onboardingRecord.Flex_Engage_Contact_Email__c+'</br>';
        emailText=emailText+'<B> Paychex Flex Engage Billing Email: </B>'+ 	 onboardingRecord.Flex_Engage_Invoice_Email__c	+	'</br>';
        emailText=emailText+ '<B> Product </B>: Paychex Flex Engage </br>';
        emailText=emailText+'<B> Number of Licenses Needed: </B>'+ 	 FlexEnagageLicenses	+	'</br>';
        emailText=emailText+'<B> Pricing per license: </B>'+ 	FlexEngagePrice	+	'</br></br>';
        emailText = addAdditonalContacts(emailText, onboardingRecord);
        emailText=emailText+ '</br> </br> Thank You, </br> Salesforce Automation.' ;
        
        string emailaddr = Label.Paychex_Flex_Enagage_Email;
        string emailaddrCC = 'PFE_Notifications@paychex.com';
        mail.setToAddresses(new list<String>{emailaddr});
        mail.setCcAddresses(new list<String>{emailaddrCC});
        mail.setReplyTo('sfdc_automation@paychex.com');
        mail.setUseSignature(false); 
        mail.setSaveAsActivity(false); 
        mail.setSubject( 'Paychex |' +  onboardingOpp.Account.Name );
        mail.setHtmlBody(emailText);
        return mail;
    }
    
    //Added by Srujan to send additional contacts in the email
    public static String addAdditonalContacts(String emailText, Onboarding_Tool__c onboardingRecord){
        String text = '';
        if((onboardingRecord.Contact_Name_1__c != null && onboardingRecord.Contact_Name_1__c != '') || (onboardingRecord.Contact_Email_1__c != null && onboardingRecord.Contact_Email_1__c != '')){
            text = text + onboardingRecord.Contact_Name_1__c + ' : ' + onboardingRecord.Contact_Email_1__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_2__c != null && onboardingRecord.Contact_Name_2__c != '') || (onboardingRecord.Contact_Email_2__c != null && onboardingRecord.Contact_Email_2__c != '')){
            text = text + onboardingRecord.Contact_Name_2__c + ' : ' + onboardingRecord.Contact_Email_2__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_3__c != null && onboardingRecord.Contact_Name_3__c != '') || (onboardingRecord.Contact_Email_3__c != null && onboardingRecord.Contact_Email_3__c != '')){
            text = text + onboardingRecord.Contact_Name_3__c + ' : ' + onboardingRecord.Contact_Email_3__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_4__c != null && onboardingRecord.Contact_Name_4__c != '') || (onboardingRecord.Contact_Email_4__c != null && onboardingRecord.Contact_Email_4__c != '')){
            text = text + onboardingRecord.Contact_Name_4__c + ' : ' + onboardingRecord.Contact_Email_4__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_5__c != null && onboardingRecord.Contact_Name_5__c != '') || (onboardingRecord.Contact_Email_5__c != null && onboardingRecord.Contact_Email_5__c != '')){
            text = text + onboardingRecord.Contact_Name_5__c + ' : ' + onboardingRecord.Contact_Email_5__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_6__c != null && onboardingRecord.Contact_Name_6__c != '') || (onboardingRecord.Contact_Email_6__c != null && onboardingRecord.Contact_Email_6__c != '')){
            text = text + onboardingRecord.Contact_Name_6__c + ' : ' + onboardingRecord.Contact_Email_6__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_7__c != null && onboardingRecord.Contact_Name_7__c != '') || (onboardingRecord.Contact_Email_7__c != null && onboardingRecord.Contact_Email_7__c != '')){
            text = text + onboardingRecord.Contact_Name_7__c + ' : ' + onboardingRecord.Contact_Email_7__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_8__c != null && onboardingRecord.Contact_Name_8__c != '') || (onboardingRecord.Contact_Email_8__c != null && onboardingRecord.Contact_Email_8__c != '')){
            text = text + onboardingRecord.Contact_Name_8__c + ' : ' + onboardingRecord.Contact_Email_8__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_9__c != null && onboardingRecord.Contact_Name_9__c != '') || (onboardingRecord.Contact_Email_9__c != null && onboardingRecord.Contact_Email_9__c != '')){
            text = text + onboardingRecord.Contact_Name_9__c + ' : ' + onboardingRecord.Contact_Email_9__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_10__c != null && onboardingRecord.Contact_Name_10__c != '') || (onboardingRecord.Contact_Email_10__c != null && onboardingRecord.Contact_Email_10__c != '')){
            text = text + onboardingRecord.Contact_Name_10__c + ' : ' + onboardingRecord.Contact_Email_10__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_11__c != null && onboardingRecord.Contact_Name_11__c != '') || (onboardingRecord.Contact_Email_11__c != null && onboardingRecord.Contact_Email_11__c != '')){
            text = text + onboardingRecord.Contact_Name_11__c + ' : ' + onboardingRecord.Contact_Email_11__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_12__c != null && onboardingRecord.Contact_Name_12__c != '') || (onboardingRecord.Contact_Email_12__c != null && onboardingRecord.Contact_Email_12__c != '')){
            text = text + onboardingRecord.Contact_Name_12__c + ' : ' + onboardingRecord.Contact_Email_12__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_13__c != null && onboardingRecord.Contact_Name_13__c != '') || (onboardingRecord.Contact_Email_13__c != null && onboardingRecord.Contact_Email_13__c != '')){
            text = text + onboardingRecord.Contact_Name_13__c + ' : ' + onboardingRecord.Contact_Email_13__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_14__c != null && onboardingRecord.Contact_Name_14__c != '') || (onboardingRecord.Contact_Email_14__c != null && onboardingRecord.Contact_Email_14__c != '')){
            text = text + onboardingRecord.Contact_Name_14__c + ' : ' + onboardingRecord.Contact_Email_14__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_15__c != null && onboardingRecord.Contact_Name_15__c != '') || (onboardingRecord.Contact_Email_15__c != null && onboardingRecord.Contact_Email_15__c != '')){
            text = text + onboardingRecord.Contact_Name_15__c + ' : ' + onboardingRecord.Contact_Email_15__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_16__c != null && onboardingRecord.Contact_Name_16__c != '') || (onboardingRecord.Contact_Email_16__c != null && onboardingRecord.Contact_Email_16__c != '')){
            text = text + onboardingRecord.Contact_Name_16__c + ' : ' + onboardingRecord.Contact_Email_16__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_17__c != null && onboardingRecord.Contact_Name_17__c != '') || (onboardingRecord.Contact_Email_17__c != null && onboardingRecord.Contact_Email_17__c != '')){
            text = text + onboardingRecord.Contact_Name_17__c + ' : ' + onboardingRecord.Contact_Email_17__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_18__c != null && onboardingRecord.Contact_Name_18__c != '') || (onboardingRecord.Contact_Email_18__c != null && onboardingRecord.Contact_Email_18__c != '')){
            text = text + onboardingRecord.Contact_Name_18__c + ' : ' + onboardingRecord.Contact_Email_18__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_19__c != null && onboardingRecord.Contact_Name_19__c != '') || (onboardingRecord.Contact_Email_19__c != null && onboardingRecord.Contact_Email_19__c != '')){
            text = text + onboardingRecord.Contact_Name_19__c + ' : ' + onboardingRecord.Contact_Email_19__c + '</br>';
        }
        if((onboardingRecord.Contact_Name_20__c != null && onboardingRecord.Contact_Name_20__c != '') || (onboardingRecord.Contact_Email_20__c != null && onboardingRecord.Contact_Email_20__c != '')){
            text = text + onboardingRecord.Contact_Name_20__c + ' : ' + onboardingRecord.Contact_Email_20__c + '</br>';
        }
        
        if(text != ''){
            text = '<B>*Addtional Contacts : </B> </br>' + text;
            emailText = emailText + text;
        }
        
        return emailText;
    }
    
     //Priyanka Added for HR Analytics 
    public void uploadFiles() {
        system.debug('fileName:'+ attachName);
        system.debug('fileName:'+ onboardingRecord.Bank_Account_Form__c);
        if(string.isnotempty(attachName)){
        try{
            if(string.isnotempty(onboardingRecord.Bank_Account_Form__c)){
                system.debug('notempty');
                ContentVersion cv= [Select ContentDocumentId from ContentVersion
                                    where ID=:onboardingRecord.Bank_Account_Form__c];
                
                List<ContentDocumentLink> contentDocsList = [Select Id,LinkedentityId,ContentDocumentId 
                                                             from ContentDocumentLink 
                                                             Where ContentDocumentId =:cv.ContentDocumentId
                                                            AND LinkedentityId=:onboardingOpp.Id];
                system.debug('contentDocsList:'+ contentDocsList);
                if(contentDocsList.size()>0){
                    delete contentDocsList;
                }
            }
        ContentVersion v = new ContentVersion();
        v.versionData = attachBody;
        v.title = attachName;
        v.pathOnClient ='/'+attachName;
        v.FirstPublishLocationId=onboardingOpp.Id;
        insert v;
        onboardingRecord.Bank_Account_Form__c=v.Id;
            
            bankAccountFile=attachName;
            attachName=null;
            attachBody=null;
            system.debug('docid' +onboardingRecord.Bank_Account_Form__c);
          //  update onboardingRecord;            
        }
        catch(exception e){
            system.debug('uploadFiles' +e.getmessage());
        }
        }
    }
    
    // public PageReference EmailHRGServiceTeam(){
    //     String branch = ((onboardingRecord.Product__c =='HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c >= 50 && onboardingRecord.MultiProdServiceCenter__c != null) ? 
    //     onboardingRecord.MultiProdServiceCenter__c.Substring(0, 3).leftPad(4, '0') 
    //     : (onboardingRecord.New_Existing__c =='Existing Paychex Client' ? 
    //        onboardingRecord.New_Branch__c.leftPad(4, '0') 
    //        : !String.isBlank(onboardingRecord.Branch_Number__c) ? 
    //        onboardingRecord.Branch_Number__c.leftPad(4, '0') : null ));
    //     Boolean multiProduct = (branch != null && branch.contains('094') ? true : false);
    //     String emailBody = createEmailBody(null, multiProduct);
    //     String emailSubject = createEmailSubject(null, multiProduct);
    //     List<Attachment[]> attachments = generateAttachments();
    //     sendEmail2HRG(Integer.valueOf(onboardingOpp.Total_Employees__c),emailBody,emailSubject,attachments);
    //     return new PageReference('/apex/OnboardingFSS?id=' + onboardingOpp.Id);
    // }

    public PageReference SharePointUpload(){
        //Send Sharepoint email(s)
        emailSharePoint();
        //Update Submission date
        if(onboardingRecord.SubmissionDate__c==null)
        {
            onboardingRecord.SubmissionDate__c = date.today();
            onboardingRecord.Submitter__c = Userinfo.getName();
        }
        //Save changes
        saveChanges();
        //Send Chatter
        Schema.Recordtypeinfo peoRt = RecordTypeHelper.getRecordType(Label.RT_Oppty_ASO, 'Opportunity');
        /*if(!quote.isEmpty())
        {
            if(onboardingOpp.RecordTypeId == peoRt.getRecordTypeId() && quote[0].Have_FlexTime__c)
            {sendChatter('virtual');}              
        }*/
        if(onboardingRecord.Product__c =='HR Solutions-Flex' && onboardingRecord.HR_Genralist__c !=null)
        {sendChatter('Sharepoint');}
        //Redirect to opportunity
        //Redirect to opportunity
        PageReference pageref = new PageReference('/' + incomingId);
        pageref.setRedirect(true);
        return pageref;
    }
    
    /*public PageReference emailFSSDD(){
//Save changes
saveChanges();
//Create email message
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setSubject('Completed NCP for you review for '+onboardingOpp.Account.Name);
String emailAddress = ((hasFSS && !onboardingRecord.changeFSS__c) || (onboardingRecord.changeFSS__c && InvalidEmail)) ? fssAddress : onboardingRecord.Alternative_Email__c;
User emailUser = [Select Id, email from User where isActive=true and email=:emailAddress limit 1];
email.setTargetObjectId(emailUser.Id);
email.setSaveAsActivity(false);
email.setHtmlBody('You have received the MMS submission below  \n\n<br/>'
+'<a href="' + URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Onboarding?id='+incomingId + '">Click this link to review Submission</a>\n\n');
email.setPlainTextBody('Client: '+onboardingOpp.Account.Name+' was onboarded through Submission. Attached is the paperwork associated with this submission\n\n');

// Sends the email
Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
//Update the Fss Email sent to True if email sent successfully, then field will update and task will be created by process builder
if (emailSend.get(0).isSuccess() || test.isRunningTest()) {
onboardingRecord.FSS_Email_Sent__c = true;
update onboardingRecord;
// create CTT case
//createCase();
}

//Redirect to opportunity
PageReference pageref = fssUpdate ? new PageReference('/apex/Onboarding?id=' + incomingId) : new PageReference('/' + incomingId);
pageref.setRedirect(true);
return pageref;
}*/
   
    public void createCase() {
        if(!Test.isRunningTest()) {
            system.debug('Sales CTT Case created.');
            User runningUser = UserHelper.getRunningUser();
            Database.DMLOptions dmo = new Database.DMLOptions();
            Schema.RecordTypeInfo CTTRt = RecordTypeHelper.getRecordType('Sales CTT', 'Case');
            Case kase = new Case(RecordTypeId = CTTRt.getRecordTypeId()
                                 , OwnerId = runningUser.Id
                                 , Opportunity__c = onboardingRecord.Opportunity_Id__c
                                 , Sales_Rep__c = onboardingOpp.OwnerId
                                 , AccountId = onboardingOpp.AccountId
                                 , Origin = 'Email'
                                 , Priority = 'Medium'
                                 , Status = 'New');                          
            //system.debug('onboardingOpp.Owner: ' + onboardingOpp.Owner);
            //dmo.assignmentRuleHeader.useDefaultRule=true;
            Database.SaveResult sr = database.insert(kase, dmo);
            if (!sr.isSuccess()) {
                String errorMsg = 'Error Saving Case: ';
                for (Database.Error err : sr.getErrors()) {
                    errorMsg += err.getMessage();
                }
                ErrorLog.logError('OnboardingController', 'createCase', 'error creating Sales CTT case', onboardingRecord.Opportunity_Id__c, errorMsg);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsg));           
            } // if (!sr.isSuccess
        }     
    }
   
    
    
    public PageReference submitNCP() {
        onboardingRecord.NCP_Submitted__c = true;
        onboardingRecord.SubmissionDate__c = date.today();
        onboardingRecord.NCP_Submitter__c = UserInfo.getUserId();
        List<Reference_CTT__c> refCTT = new List<Reference_CTT__c>([SELECT Id, Name, Onboarding_Tool__c, Status__c, Ready_To_Be_Worked__c, CreatedDate,Opportunity__c,Opportunity__r.Id, OwnerId FROM Reference_CTT__c WHERE Ready_To_Be_Worked__c = True AND Onboarding_Tool__c= :onboardingRecord.Id ORDER BY CreatedDate DESC LIMIT 1]);
        List<Reference_CTT__c> refCTTs = new List<Reference_CTT__c>([SELECT Id, Name, Onboarding_Tool__c, Status__c, Ready_To_Be_Worked__c, CreatedDate,Opportunity__c,OwnerId FROM Reference_CTT__c WHERE Ready_To_Be_Worked__c = True AND Onboarding_Tool__c= :onboardingRecord.Id ORDER BY CreatedDate DESC]);
        
        System.debug('submitNCP refCTT List ='+refCTT);
        saveChanges();
   
        String[] closedStatus = Label.Reference_CTT_Closed_Status.split(',');
        
        if(refCTT != null && refCTT.size() == 1)
        {
            Reference_CTT__c newestRefCTT = refCTT[0];

            System.debug('OnboardingController refCTT='+refCTT);
            if(newestRefCTT != null && newestRefCTT.Status__c != null && !closedStatus.contains(newestRefCTT.Status__c))
            {
                System.debug('OnboardingController refCTT='+refCTT);
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setSubject('Completed NCP for your review for '+onboardingOpp.Account.Name);
                
                String emailAddress = Label.Onboarding_SMB_CTT_Email;
                List<Contact> emailUser = [Select Id, Email from Contact where Name = 'Client Transition' and Email=:emailAddress limit 1];
                
                if(emailUser != null && !emailUser.isEmpty()) {
                    email.setTargetObjectId((emailUser.get(0)).Id);
                    email.setSaveAsActivity(false);
                    email.setHtmlBody('You have received the updated client submission below  \n\n<br/>'
                              +'<a href="' + URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Onboarding?id='+incomingId + '">Click this link to review Submission</a>\n\n');
                    email.setPlainTextBody('Client: '+onboardingOpp.Account.Name+' was onboarded through Submission. Attached is the paperwork associated with this submission\n\n');
                    Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            
                    if (emailSend.get(0).isSuccess() || test.isRunningTest()) {
                        emailSent = true;
                    }
                } else {
                    String message = 'Could not find valid email address to send Client Profile.';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message)); 
                    displayMessages = true;
                    return null;
                }
            }
        }  
        System.debug('refCTTs.size():'+refCTTs.size()+'refCTTs.size()>=1 '+ String.valueOf(refCTTs.size()>=1)+'refCTTs!= null && refCTTs.size()>=1 : '+ String.valueOf(refCTTs!= null && refCTTs.size()>=1));
        if(refCTTs!= null && refCTTs.size()>=1){
            //String[] closedStatus = Label.Reference_CTT_Closed_Status.split(',');
            System.debug('we made it into the duplicate section!!');
            moreThan1RefCtt = false;
            Reference_CTT__c newestRefCTT1 = refCTT[0];
            System.debug('newestRefCTT1: '+newestRefCTT1);
            String[] openStatus = Label.Reference_CTT_Open_Status.split(',');
            System.debug('Openstatus: '+openStatus);
            for(Reference_CTT__c oneCTT :refCTTs){
                if(openStatus.contains(oneCTT.Status__c)){
                    System.debug('oneCTT.Status__c : '+oneCTT.Status__c);
                    moreThan1RefCtt = true;
                }
            }
                    refCTTOwnerId = newestRefCTT1.OwnerId;
                    refCTTOppId = newestRefCTT1.Opportunity__r.Id;
                    refCTTId = newestRefCTT1.Id;
                    System.debug('RefCTTId: '+refCTTId+' refCTTOwnerId: '+refCTTOwnerId+' refCTTOppId: '+refCTTOppId);

        }
        //Redirect to opportunity
        PageReference pageref;
        if(onboardingOpp.Mandate_Sale__c && has401kProduct && hasPayrollProduct)
        {
            OpptySplitController split = new OpptySplitController();
            split.splitOpportunity();
            
            System.debug('Oppty split: ' + incomingId);
        } 

        //pageref = fssUpdate ? new PageReference('/apex/OnboardingFSS?id=' + incomingId) : new PageReference('/' + incomingId);
        
        pageref = moreThan1RefCtt ? new PageReference('/apex/OnboardingDuplicateSubmission?id=' +incomingId): fssUpdate ? new PageReference('/apex/OnboardingFSS?id=' + incomingId) : new PageReference('/' + incomingId);
        System.debug('morethan1RefCtt: '+moreThan1RefCtt+' FSSUpdate: '+fssUpdate);
        if(moreThan1RefCtt){
            onboardingRecord.Update_Submission__c = '';
            saveChanges();

        }
        pageref.setRedirect(true);
        return pageref;        
    } //submitNCP
    public PageReference duplicatePageRedirect() {
        PageReference pageref;
        String url;
        String updatesIncoming = onboardingRecord.Update_Submission__c;
    switch on updatesIncoming {
        when 'No' {
            System.debug('IT SHOULD LEAVE THIS PAGE!!!');
            //saveChanges();
            url = '/' + incomingId;
            System.debug('Test URL: '+url);
        }
        when 'Yes'{
            
            url = null;
            
        }
        when else {
            url = null;
            System.debug('IT SHOULD STAY ON THE PAGE!');
        }
    }

    if (url != null) {
        // Go to next page
        System.debug('Test URL: '+url);

         pageref = new PageReference(url);
         pageref.setRedirect(true);
        //pageref.getParameters().put('custoemrlocation','TX');
        return pageref;
    } else {
        // Leave the user on the current page
        return null;
    }

    }
    
    public void cloneClientProfiletoChilds(){
    	system.debug('Multi Id Submission: '+ onboardingRecord.Opportunity_Id__c );
        Opportunity[] childOptiesList = [Select Id,First_Payroll_Delivery_Method__c,New_or_Existing_Business__c
                                     from Opportunity where 
                                     Primary_Opportunity__c =: onboardingRecord.Opportunity_Id__c
                                    AND ID not in (Select Opportunity_Id__c from Onboarding_Tool__c)];
        if(childOptiesList.Size()>0){
            Onboarding_Tool__c[] childOptyProfilesList = New Onboarding_Tool__c[]{};
                
            for(Opportunity op: childOptiesList){
                Onboarding_Tool__c clonedprofile = onboardingRecord.clone(false, false, false, false);
                clonedprofile.Opportunity_Id__c=op.id;
                childOptyProfilesList.add(clonedprofile);
            }
            Insert childOptyProfilesList;            
        }
    }
    
    public PageReference duplicatePageCancelRedirect() {
        PageReference pageref;
        String url;
        String updatesIncoming = onboardingRecord.Update_Submission__c;
        url = '/' + incomingId;
        onboardingRecord.Update_Submission__c = 'No';
        //saveChanges();
    if (url != null) {
        // Go to next page
        System.debug('Test URL: '+url);

         pageref = new PageReference(url);
         pageref.setRedirect(true);
        //pageref.getParameters().put('custoemrlocation','TX');
        return pageref;
    } else {
        // Leave the user on the current page
        return null;
    }

    }
    public PageReference submitUpdateChatterPost(){
        //Saves the most recent changes to the Onboarding Tool Record ***ECP*** 10/19/2022
        saveChanges();
        //Finds Reference CTT's to pull the most recent info in for chatter creation
        List<Reference_CTT__c> refCTTs = new List<Reference_CTT__c>([SELECT Id, Name, Onboarding_Tool__c, Status__c, Ready_To_Be_Worked__c, CreatedDate,Opportunity__c,OwnerId,Opportunity__r.Id FROM Reference_CTT__c WHERE Ready_To_Be_Worked__c = True AND Onboarding_Tool__c= :onboardingRecord.Id ORDER BY CreatedDate DESC]);
        System.debug('refCTTs: '+refCTTs);
        if(refCTTs!= null){
            try{
                Reference_CTT__c newestRefCTT1 = refCTTs[0];

                refCTTOwnerId = newestRefCTT1.OwnerId;
                refCTTOppId = newestRefCTT1.Opportunity__r.Id;
                refCTTId = newestRefCTT1.Id;
                System.debug('RefCTTId: '+refCTTId+' refCTTOwnerId: '+refCTTOwnerId+' refCTTOppId: '+refCTTOppId);
                runningUser = UserHelper.getRunningUser();        
                List<Id> taggedUserIds = new List<Id>();
                taggedUserIds.add(runningUser.Id);
                taggedUserIds.add(refCTTOwnerId);
                System.debug(taggedUserIds);
                //Start creating pieces for the chatter message
                /*ConnectAPI helps send chatter messages 
                FeedItemInput is the "chatter message" 
                MessageBody is the message thats sent 
                aside: you can add links to objects in a message body see below
                TextSegment is the literal text portion of the "message" in chatter
                EntityLinkSegmentInput is the way you can use the Id of an SObject in SF to tag like a hyperlink in a chatter message

                */
                String message = 'Attention: The NCP on the following Opportunity was recently updated. \n  Any corresponding changes have also been applied to the open Reference CTT record. \n';
                ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();            
                ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();   
                messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                // Create Message for ChatterPost and add to message 
                ConnectApi.TextSegmentInput textSegmentInput1 = new ConnectApi.TextSegmentInput();
                textSegmentInput1.text = message;
                messageBodyInput.messageSegments.add(textSegmentInput1);
                //Grab Opp Id for link to Opportunity and add link to opportunity 
                ConnectApi.EntityLinkSegmentInput entityLinkSegmentInputOpportunity = new ConnectApi.EntityLinkSegmentInput();
                entityLinkSegmentInputOpportunity.entityId = refCTTOppId;
                messageBodyInput.messageSegments.add(entityLinkSegmentInputOpportunity); 
                ConnectApi.TextSegmentInput textSegmentInput2 = new ConnectApi.TextSegmentInput();
                textSegmentInput2.text = '\n';
                messageBodyInput.messageSegments.add(textSegmentInput2);
                // From ChatterMentionPost; it grabs the userIds and attaches them to the message body
                ChatterMentionPost.getMentions(messageBodyInput,taggedUserIds);
                //attaches the aggregate messages segments together onto the "Chatter Message"
                feedItemInput.body = messageBodyInput;
                //? Look into the field below to see what this line does... I'm not really sure but it looks like it creates a Chatter Message officially
                feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                // ? if chatter post goes on RefCTT
                // Subject Id is where the chatter message will appear(in this case its going on the Reference CTT object's chatter feed)
                feedItemInput.subjectId = refCTTId; 
                //? if chatter post goes on Opp
                // feedItemInput.subjectId = refCTTOppId; 
                // the code below actually posts the Chatter Message
                ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);  
                //Changes page to go back to the opportunity
                PageReference pageref = new PageReference('/' + incomingId);
                pageref.setRedirect(true);
                return pageref;
            }
            catch(exception e){
                //ErrorLog.add('')
                return new PageReference('/'+incomingId);
            }
        }
        PageReference pageref = new PageReference('/'+incomingId);
                pageref.setRedirect(true);
                return pageref;
        
        
            
    }
    public void emailSharePoint(){
        String branch = ((onboardingRecord.Product__c =='HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c >= 50 && onboardingRecord.MultiProdServiceCenter__c != null) ? 
                         onboardingRecord.MultiProdServiceCenter__c.Substring(0, 3).leftPad(4, '0') 
                         : (onboardingRecord.New_Existing__c =='Existing Paychex Client' ? 
                             String.isBlank(onboardingRecord.New_Branch__c) ? null: onboardingRecord.New_Branch__c.leftPad(4, '0') 
                            : !String.isBlank(onboardingRecord.Branch_Number__c) ? 
                            onboardingRecord.Branch_Number__c.leftPad(4, '0') : null ));
        Boolean multiProduct = (branch != null && branch.contains('094') ? true : false);
        String emailBody = createEmailBody(branch, multiProduct);
        String emailSubject = createEmailSubject(branch, multiProduct);
        if(!uploadtoSharePoint){
            List<Attachment[]> attachmentList = generateAttachments();
            sendEmail(emailBody, emailSubject, attachmentList);
        }
        else{
            generateAttachmentstoSharepoint(incomingId, onboardingOpp.Name,emailBody, emailSubject
                                           , onboardingRecord.Product__c, onboardingRecord.New_Existing__c
                                           , onboardingOpp.Account.AccountNumber);
        }
    }
    
    public String createEmailSubject(String branch, Boolean multiProduct){
        String formattedCompanyName = onboardingOpp.Account.Name.replaceAll('(?i)[^a-z0-9.]', '_');
        string formattedAddress = (!String.isBlank(onboardingOpp.Account.BillingStreet) ?  onboardingOpp.Account.BillingStreet.replaceAll('(?i)[^a-z0-9.]', '_') : null);
        formattedAddress = (formattedAddress.length() > 11 ? formattedAddress.substring(0,11) : formattedAddress);
        String extension = multiProduct ? '_PACO.xml' : '_PACO.';
        String subject = branch + ' | '+ formattedCompanyName +'_'+formattedAddress + extension;
      if(onboardingRecord.New_Existing__c =='Existing Paychex Client' && !(onboardingOpp.Employees_Paid_Per_Payroll__c > 49 || multiProduct)){
            string additionalInfo = onboardingRecord.FSS_Name__c
                +';'+onboardingRecord.HRG_Name__c
                +';'+onboardingRecord.HRS_Sales_Rep_Name__c 
                +';'+onboardingRecord.Branch_Number__c
                +';'+onboardingRecord.New_Client__c
                +';'+onboardingRecord.First_Check_Date__c
                +';'+onboardingOpp.Employees_Paid_Per_Payroll__c
                +';'+onboardingOpp.Account.Frequency__c;
            subject +=additionalInfo;
        }
        return subject;
    }
    
    public String createEmailBody(String branch, Boolean multiProduct){
        String formattedCompanyName = onboardingOpp.Account.Name.replaceAll('(?i)[^a-z0-9.]', '_');
        String formattedAddress = (!String.isBlank(onboardingOpp.Account.BillingStreet) ?  onboardingOpp.Account.BillingStreet.replaceAll('(?i)[^a-z0-9.]', '_') : null);
        formattedAddress = (formattedAddress.length() > 11 ? formattedAddress.substring(0,11) : formattedAddress);
        String submissionTypeString;
        
        //Update SubmissionType
        if(onboardingRecord.New_Existing__c =='New Client'){
            submissionTypeString = onboardingOpp.Employees_Paid_Per_Payroll__c > 49 || multiProduct ? ' is Multi-Product Service Center client onboarded ' : ' was onboarded ';
        }
        else{
            submissionTypeString = onboardingOpp.Employees_Paid_Per_Payroll__c > 49 || multiProduct ? ' is Multi-Product Service Center: '+branch+' client onboarded ' : ' was transferred ';
        }
        String Body = 'Client: '+onboardingOpp.Account.Name + submissionTypeString + 'onto HR Solutions ASO through Salesforce. Attached is the paperwork associated with this submission\n\n';      
        return Body;
    }
    
    public List<Attachment[]> generateAttachments(){
        //Add Summary
        saveSummary();
        //Create Attachment List
        Attachment[] attList = new Attachment[]{};
            List<Attachment[]> attachListPerEmail = new List<Attachment[]>();
        Integer sizeLimit = Integer.valueOf(label.OnboardingTool_Size_Limit);
        List<Attachment> opptyAttachments = [Select Id, Name, Body, BodyLength, ContentType from Attachment WHERE ParentId =:incomingId and BodyLength <: sizeLimit];  
        
        Integer currentEmailsize = 0;
        for(Attachment att : opptyAttachments)
        {
            Integer tempSize = currentEmailsize + att.BodyLength;
            if(tempSize < sizeLimit)
            {
                attList.add(att);
                currentEmailsize = tempSize;
            }
            else
            {
                attachListPerEmail.add(attList);
                attList.clear();
                attList.add(att);
                currentEmailsize = att.BodyLength;
            }            
        }
        attachListPerEmail.add(attList);
        return attachListPerEmail;
    }
    
    public void sendEmail(String emailBody, String emailSubject, List<Attachment[]> attachmentList){
        List<Messaging.Email> emailList = new List<Messaging.Email>();
        User emailRecipient = [Select Id, Email from User where Email=:Label.ASO_SP_Email limit 1];
        for(Attachment[] attachmentGroup : attachmentList){
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            for(Attachment att : attachmentGroup){
                Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
                string formattedName = att.Name.replaceAll('(?i)[^a-z0-9.]', '_');
                emailAtt.setFileName(formattedName);
                emailAtt.setBody(att.Body);
                emailAtt.setContentType(att.ContentType);
                emailAttachments.add(emailAtt);
            }
            Messaging.SingleEmailMessage Email = new Messaging.SingleEmailMessage();
            Email.setFileAttachments(emailAttachments);
            Email.setSaveAsActivity(false);
            Email.setTargetObjectId(emailRecipient.Id);
            Email.setSubject(emailSubject);
            Email.setHtmlBody(emailBody);
            Email.setPlainTextBody(emailBody);
            emailList.add(Email);
        }
        // Sends the email
        Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(emailList); 
    }
    
     //APR0170402: emailFSS-upload NCP Summery to Sharepoint on submit of ASO NCP Form
	@Future(callout=true)
    public static void generateAttachmentstoSharepoint(string incomingId, string opptyName, 
                                                       string emailBody, string emailSubject,
                                                      string productType, string clientType, string AccountNumber){
        //Add Summary
         string clientNumber=string.isnotempty(AccountNumber) && AccountNumber.contains('-')?  
             AccountNumber.split('-',2)[1]:  AccountNumber;
                                                          
        PageReference pdf = new PageReference('/apex/OnboardingPDF?id=' + incomingId);
        Blob attbody = !test.isRunningTest() ? pdf.getContentAsPDF() : blob.valueof('TEST');
        Attachment summary = new Attachment(Name = opptyName+'_ASO_Onboarding_Summary_'+clientNumber +'.pdf', IsPrivate = false, 
                                            Body = attbody, ParentId = incomingId);
        upsert summary; 
        
        if(productType=='HR Solutions-Flex' && clientType=='Existing Paychex Client'){
        //Create Attachment List
        Attachment[] attList = new Attachment[]{};
            List<Attachment[]> attachListPerEmail = new List<Attachment[]>();
        Integer sizeLimit = Integer.valueOf(label.OnboardingTool_Size_Limit);
        List<Attachment> opptyAttachments = [Select Id, Name, Body, BodyLength, ContentType 
                                             from Attachment WHERE ParentId =:incomingId and BodyLength <: sizeLimit];  
        
        Integer currentEmailsize = 0;
        for(Attachment att : opptyAttachments)
        {
            Integer tempSize = currentEmailsize + att.BodyLength;
            if(tempSize < sizeLimit)
            {
                attList.add(att);
                currentEmailsize = tempSize;
            }
            else
            {
                attachListPerEmail.add(attList);
                attList.clear();
                attList.add(att);
                currentEmailsize = att.BodyLength;
            }            
        }
        attachListPerEmail.add(attList);
        
        List<Messaging.Email> emailList = new List<Messaging.Email>();
        User emailRecipient = [Select Id, Email from User where Email=:Label.ASO_SP_Email limit 1];
        for(Attachment[] attachmentGroup : attachListPerEmail){
            List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
            for(Attachment att : attachmentGroup){
                Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
                string formattedName = att.Name.replaceAll('(?i)[^a-z0-9.]', '_');
                emailAtt.setFileName(formattedName);
                emailAtt.setBody(att.Body);
                emailAtt.setContentType(att.ContentType);
                emailAttachments.add(emailAtt);
            }
            Messaging.SingleEmailMessage Email = new Messaging.SingleEmailMessage();
            Email.setFileAttachments(emailAttachments);
            Email.setSaveAsActivity(false);            
            Email.setTargetObjectId(emailRecipient.Id);
            Email.setSubject(emailSubject);
            Email.setHtmlBody(emailBody);
            Email.setPlainTextBody(emailBody);
            emailList.add(Email);
        }
            Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(emailList);    
        }     
    }
    
    // public void sendEmail2HRG(Integer Emps, String emailBody, String emailSubject, List<Attachment[]> attachmentList){
    //     List<Messaging.Email> emailList = new List<Messaging.Email>();
    //     User emailRecipient = [Select Id, Email from User where Email=:Label.ASO_SP_Email limit 1];
    //     List<String> lessThan20EmpsEmail = new List<String>{'HRGRequestSMB_0-19@paychex.com'};
    //     List<String> moreThan20EmpsEmail = new List<String>{'HRGRequestMid_20Plus@paychex.com'};
    //     List<String> emailRecipient2 = new List<String>();
    //     if(Emps<20){
    //         emailRecipient2 = lessThan20EmpsEmail;
    //     }else{
    //         emailRecipient2 = moreThan20EmpsEmail;
    //     }
        
    //     for(Attachment[] attachmentGroup : attachmentList){
    //         List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
    //         for(Attachment att : attachmentGroup){
    //             Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
    //             string formattedName = att.Name.replaceAll('(?i)[^a-z0-9.]', '_');
    //             emailAtt.setFileName(formattedName);
    //             emailAtt.setBody(att.Body);
    //             emailAtt.setContentType(att.ContentType);
    //             emailAttachments.add(emailAtt);
    //         }
    //         Messaging.SingleEmailMessage Email = new Messaging.SingleEmailMessage();
    //         Email.setFileAttachments(emailAttachments);
    //         Email.setSaveAsActivity(false);
    //         // Email.setTargetObjectId(emailRecipient.Id);
    //         Email.setToAddresses(emailRecipient2);
    //         Email.setSubject(emailSubject);
    //         Email.setHtmlBody(emailBody);
    //         Email.setPlainTextBody(emailBody);
    //         emailList.add(Email);
    //     }
    //     // Sends the email
    //     Messaging.SendEmailResult [] emailSend = Messaging.sendEmail(emailList); 
    // }
    
    public void UpdateInformationFSS(){
        fssUpdate = true;
    }
    
    public void saveSummary(){
        //Add PDF
        string clientNumber=string.isnotempty(onboardingOpp.Account.AccountNumber) && onboardingOpp.Account.AccountNumber.contains('-')?  
             onboardingOpp.Account.AccountNumber.split('-',2)[1]: onboardingOpp.Account.AccountNumber;
        
        PageReference pdf = new PageReference('/apex/OnboardingPDF?id=' + incomingId);
        Blob attbody = !test.isRunningTest() ? pdf.getContentAsPDF() : blob.valueof('TEST');
        Attachment summary = new Attachment(Name = onboardingOpp.Name+'_ASO_Onboarding_Summary_'+ clientNumber+ '.pdf',
                                            IsPrivate = false, Body = attbody, ParentId = incomingId);
        upsert summary;   
    }
    
    //Clears the BDA field when it's set to no.
    public void clearDBAField()
    {
        System.debug('clearDBAField Clearing out DBA');
        if(onboardingRecord.Does_Client_Use_DBA__c == 'No')
        {
            if(originalAccountDBA != null)
            {
                onboardingOpp.Account.DBA__c = originalAccountDBA;
            }
            else
            {
                onboardingOpp.Account.DBA__c = '';
            }
            onboardingRecord.DBA_Name_on_Checks_and_Reports__c = null;
            System.debug('clearDBAField onboardingOpp.Account.DBA__c='+onboardingOpp.Account.DBA__c);
        }
        Validate();
    }
    
    //User for child onboarding records - Pulls down the fields that are shared between the parent and child.
    public void applyParentData()
    {
        if(onboardingRecord.Use_Parent_Data__c)
        {
            onboardingRecord.ReadyChex__c = parentOnboardingRecord.ReadyChex__c;
            onboardingRecord.GL__c = parentOnboardingRecord.GL__c;
            onboardingRecord.Accounting_Software__c = parentOnboardingRecord.Accounting_Software__c;
            onboardingRecord.Other_Accounting_Software__c = parentOnboardingRecord.Other_Accounting_Software__c;
            onboardingRecord.Workers_Compensation__c = parentOnboardingRecord.Workers_Compensation__c;
            onboardingRecord.Skylight__c = parentOnboardingRecord.Skylight__c;
            onboardingRecord.Pay_Demand__c = parentOnboardingRecord.Pay_Demand__c;
            
            boolean hasParentAuthorizedOfficer = false;
            List<Contact> ctctList = new List<Contact>();
            ctctList = [Select Id, Name, Title, Phone, Email from Contact where AccountId = :onboardingOpp.Account.Id];
            System.debug('applyParentData ctctList=' + ctctList);
            for(Contact ctct : ctctList)
            {
                if(ctct.Id == parentOnboardingRecord.Authorize_Officer__c)
                {
                    hasParentAuthorizedOfficer = true;
                    break;
                }
            }
            if(hasParentAuthorizedOfficer)
            {
                onboardingRecord.Authorize_Officer__c = parentOnboardingRecord.Authorize_Officer__c;
                selectedAuthorizedContact = parentOnboardingRecord.Authorize_Officer__c;
                //System.debug('applyParentData selectedAuthorizedContact='+selectedAuthorizedContact+' parentOnboardingRecord.Authorize_Officer__c='+parentOnboardingRecord.Authorize_Officer__c);
                //onboardingRecord.Authorize_Officer_Title__c = parentOnboardingRecord.Authorize_Officer_Title__c;
                onboardingRecord.Authorized_Officer_Phone__c = parentOnboardingRecord.Authorized_Officer_Phone__c;
                onboardingRecord.Authorized_Officer_Email__c = parentOnboardingRecord.Authorized_Officer_Email__c;
            }
            else
            {
                onboardingRecord.Authorize_Officer__c = null;
                selectedAuthorizedContact = '';
                onboardingRecord.Authorized_Officer_Phone__c = null;
                onboardingRecord.Authorized_Officer_Email__c = null;
            }
            
            boolean hasParentContact = false;
            ctctList.clear();
            ctctList = [Select Id, Name, Title, Phone, Email from Contact where AccountId = :onboardingOpp.Account.Id];
            for(Contact ctct : ctctList)
            {
                if(ctct.Id == parentOnboardingRecord.PayrollContact__c)
                {
                    hasParentContact = true;
                    break;
                }
            }
            if(hasParentContact)
            {
                onboardingRecord.PayrollContact__c = parentOnboardingRecord.PayrollContact__c;
                selectedPayrollContact = parentOnboardingRecord.PayrollContact__c;
                System.debug('applyParentData selectedPayrollContact='+selectedPayrollContact+' parentOnboardingRecord.PayrollContact__c='+parentOnboardingRecord.PayrollContact__c);
                onboardingRecord.PayrollContact_Title__c = parentOnboardingRecord.PayrollContact_Title__c;
                onboardingRecord.PayrollContact_Phone__c = parentOnboardingRecord.PayrollContact_Phone__c;
                onboardingRecord.PayrollContact_Email__c = parentOnboardingRecord.PayrollContact_Email__c;
            }
            else
            {
                onboardingRecord.PayrollContact__c = null;
                selectedPayrollContact = '';
                onboardingRecord.PayrollContact_Title__c = null;
                onboardingRecord.PayrollContact_Phone__c = null;
                onboardingRecord.PayrollContact_Email__c = null;
            }
            
            onboardingRecord.Run_Date__c = parentOnboardingRecord.Run_Date__c;
            onboardingRecord.First_Check_Date__c = parentOnboardingRecord.First_Check_Date__c;
            onboardingRecord.PeriodEndDate__c = parentOnboardingRecord.PeriodEndDate__c;
            
            if(parentOnboardingOpp != null)
            {
                System.debug('applyParentData parentOnboardingOpp='+parentOnboardingOpp);
                onboardingOpp.New_or_Existing_Business__c = parentOnboardingOpp.New_or_Existing_Business__c;
                onboardingOpp.Service_Location__c = parentOnboardingOpp.Service_Location__c;
            }
            onboardingRecord.PriorWagesLoaded__c = parentOnboardingRecord.PriorWagesLoaded__c;
            onboardingRecord.IrsIsDelivery__c = parentOnboardingRecord.IrsIsDelivery__c;
            onboardingRecord.Irs_Address__c = parentOnboardingRecord.Irs_Address__c;
            onboardingRecord.Business_Structure__c = parentOnboardingRecord.Business_Structure__c;
            onboardingRecord.Taxed_as_S_Corp__c = parentOnboardingRecord.Taxed_as_S_Corp__c;
            onboardingRecord.PreAssignedClientNum__c = parentOnboardingRecord.PreAssignedClientNum__c;
            onboardingRecord.PreAssignedId__c = parentOnboardingRecord.PreAssignedId__c;            
            /*
            if(refOppProduct != null && parentRefOppProduct != null)
            {
                refOppProduct.Paychex_Flex_Onboarding__c = parentRefOppProduct.Paychex_Flex_Onboarding__c;
                refOppProduct.Paychex_Flex_Hiring__c = parentRefOppProduct.Paychex_Flex_Hiring__c;
                refOppProduct.FLEX_Benefits_Administration_Essentials__c = parentRefOppProduct.FLEX_Benefits_Administration_Essentials__c;
                refOppProduct.Paychex_Flex_Time__c = parentRefOppProduct.Paychex_Flex_Time__c;
                refOppProduct.Onboarding_Essentials__c = parentRefOppProduct.Onboarding_Essentials__c;
                refOppProduct.Financial_Wellness_Service__c = parentRefOppProduct.Financial_Wellness_Service__c;
                refOppProduct.Tax_Credit_Service__c = parentRefOppProduct.Tax_Credit_Service__c;
                refOppProduct.Paychex_Employee_Screening_Essentials__c = parentRefOppProduct.Paychex_Employee_Screening_Essentials__c;
                refOppProduct.Paychex_Flex_HR_Administration__c = parentRefOppProduct.Paychex_Flex_HR_Administration__c;
                refOppProduct.Paychex_Flex_Time_Essentials__c = parentRefOppProduct.Paychex_Flex_Time_Essentials__c;
                
            }
            */
            if(hasFlextime)
            {
                onboardingRecord.Flextime_Date__c = parentOnboardingRecord.Flextime_Date__c;
                onboardingRecord.Anticipated_Start_Date__c = parentOnboardingRecord.Anticipated_Start_Date__c;
                onboardingRecord.Flextime_TAA__c = parentOnboardingRecord.Flextime_TAA__c;
                onboardingRecord.NumFlexId__c = parentOnboardingRecord.NumFlexId__c;
                onboardingRecord.Flextime_Timeclock__c = parentOnboardingRecord.Flextime_Timeclock__c;
            }
            if(hasEsr)
            {
                onboardingRecord.ESR_educationInstitution__c = parentOnboardingRecord.ESR_educationInstitution__c;
                onboardingRecord.ESR_selfInsuredPlan__c = parentOnboardingRecord.ESR_selfInsuredPlan__c;
                onboardingRecord.ESR_UnionEmps__c = parentOnboardingRecord.ESR_UnionEmps__c;
                onboardingRecord.ESR_PriorMedRenewalDate__c = parentOnboardingRecord.ESR_PriorMedRenewalDate__c;
            }
            if(displayASOForMMS)
            {
                onboardingRecord.Spanish__c = parentOnboardingRecord.Spanish__c;
                onboardingRecord.Handbook_Format__c = parentOnboardingRecord.Handbook_Format__c;
                onboardingRecord.HR_Admin__c = parentOnboardingRecord.HR_Admin__c;
                onboardingRecord.HRE_Num_of_Locations__c = parentOnboardingRecord.HRE_Num_of_Locations__c;
                onboardingRecord.HRE_Reason_Selected__c = parentOnboardingRecord.HRE_Reason_Selected__c;
                onboardingRecord.HRE_Existing__c = parentOnboardingRecord.HRE_Existing__c;
                onboardingRecord.HRE_Existing_Safety_Manual__c = parentOnboardingRecord.HRE_Existing_Safety_Manual__c;
            }
            System.debug('OnboardingController Set to Parent Data onboardingRecord.GL__c='+onboardingRecord.GL__c+' parentOnboardingRecord.GL__c='+parentOnboardingRecord.GL__c);  
        }
        if(!onboardingRecord.Use_Parent_Data__c)
        {
            onboardingRecord.ReadyChex__c = null;
            onboardingRecord.GL__c = null;
            onboardingRecord.Accounting_Software__c = null;
            onboardingRecord.Other_Accounting_Software__c = null;
            onboardingRecord.Workers_Compensation__c = null;
            onboardingRecord.Skylight__c = null;
            onboardingRecord.Pay_Demand__c = null;
              
            onboardingRecord.Authorize_Officer__c = null;
            selectedAuthorizedContact = '';
            onboardingRecord.Authorized_Officer_Phone__c = null;
            onboardingRecord.Authorized_Officer_Email__c = null;
                       
            onboardingRecord.PayrollContact__c = null;
            selectedPayrollContact = '';
            onboardingRecord.PayrollContact_Title__c = null;
            onboardingRecord.PayrollContact_Phone__c = null;
            onboardingRecord.PayrollContact_Email__c = null;
            
            onboardingRecord.Run_Date__c = null;
            onboardingRecord.First_Check_Date__c = null;
            onboardingRecord.PeriodEndDate__c = null;
            
            onboardingOpp.New_or_Existing_Business__c = null;
            onboardingRecord.PriorWagesLoaded__c = null;
            onboardingRecord.IrsIsDelivery__c = null;
            onboardingRecord.Irs_Address__c = null;            
            onboardingRecord.Business_Structure__c = null;
            onboardingRecord.Taxed_as_S_Corp__c = false;
            onboardingOpp.Service_Location__c = null;
            onboardingRecord.PreAssignedClientNum__c = 'No';
            onboardingRecord.PreAssignedId__c = null;
            /*
            if(refOppProduct != null)
            {
                refOppProduct.Paychex_Flex_Onboarding__c = false;
                refOppProduct.Paychex_Flex_Hiring__c = false;
                refOppProduct.FLEX_Benefits_Administration_Essentials__c = false;
                refOppProduct.Paychex_Flex_Time__c = false;
                refOppProduct.Onboarding_Essentials__c = false;
                refOppProduct.Financial_Wellness_Service__c = false;
                refOppProduct.Tax_Credit_Service__c = false;
                refOppProduct.Paychex_Employee_Screening_Essentials__c = false;
                refOppProduct.Paychex_Flex_HR_Administration__c = false;
                refOppProduct.Paychex_Flex_Time_Essentials__c = false; 
                
            }
            */
            if(hasFlextime)
            {
                onboardingRecord.Flextime_Date__c = null;
                onboardingRecord.Anticipated_Start_Date__c = null;
                onboardingRecord.Flextime_TAA__c = null;
                onboardingRecord.NumFlexId__c = null;
                onboardingRecord.Flextime_Timeclock__c = null;
            }
            if(hasEsr)
            {
                onboardingRecord.ESR_educationInstitution__c = null;
                onboardingRecord.ESR_selfInsuredPlan__c = null;
                onboardingRecord.ESR_UnionEmps__c = null;
                onboardingRecord.ESR_PriorMedRenewalDate__c = null;
            }
            if(displayASOForMMS)
            {
                onboardingRecord.Spanish__c = null;
                onboardingRecord.Handbook_Format__c = null;
                onboardingRecord.HR_Admin__c = null;
                onboardingRecord.HRE_Num_of_Locations__c = null;
                onboardingRecord.HRE_Reason_Selected__c = null;
                onboardingRecord.HRE_Existing__c = null;
                onboardingRecord.HRE_Existing_Safety_Manual__c = null;
            }
            System.debug('OnboardingController Set to blank');
        }

            if((onboardingRecord.Authorized_Officer_Phone__c == null || onboardingRecord.Authorized_Officer_Email__c== null)
            && defaultContact!= null
            && defaultContact.ContactId != null 
            && defaultContact.Contact.Email != null
            && defaultContact.Contact.Phone != null){
                onboardingRecord.Authorized_Officer_Phone__c = defaultContact.Contact.Email;
            onboardingRecord.Authorized_Officer_Email__c = defaultContact.Contact.Phone;
            }
            
        Validate();
    }
    
    //Checks whether or not the Virtual Sales User should be able to edit this record.
    public boolean checkUserAccess()
    {
        System.debug('Checking the Users access');
        boolean proceed = false;
        if(onboardingOpp.OwnerId == runningUser.Id)
        {
            System.debug('Running user is owner. Has Access.');
            return true;
        }
        
        List<OpportunityTeamMember> otmList = new List<OpportunityTeamMember>();
        otmList = [SELECT Id, Name, UserId, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId = :onboardingOpp.Id];
        for(OpportunityTeamMember otm : otmList)
        {
            if(otm.UserId == runningUser.Id)
            {
                System.debug('Running user is OpportunityTeamMember. Has Access.');
                return true;
            }
        }
        
        System.debug('Running user does not have Access.');
        return false;
    }
    
    //A form Type has been chosen.
    public void continueClicked()
    {
        //System.debug('Continue was clicked: onboardingRecord.Form_Type__c='+onboardingRecord.Form_Type__c);
        if(onboardingRecord.Form_Type__c != null)
        {
            typeSelected = true;
            if(onboardingRecord.Id != null)
            {
                update onboardingRecord;
            }
            else
            {
                insert onboardingRecord;
            }
            initialize();
        }
        
    }
    
    //Checks the run date to see whether or not an error message needs to be shown.
    public void checkRunDate()
    {
        //runDateOkay = true;
        
        if(onboardingRecord.Run_Date__c != null && onboardingOpp.New_or_Existing_Business__c != null)
        {
            if(onboardingOpp.New_or_Existing_Business__c == 'Existing')
            {
                newBusinessRunDateOkay = true;
                if(onboardingRecord.Run_Date__c < addBusinessDays(System.today(), 3))
                {
                    existingBusinessRunDateOkay = false;
                }
                else
                {
                    existingBusinessRunDateOkay = true;
                }
            }
            if(onboardingOpp.New_or_Existing_Business__c == 'New')
            {
                existingBusinessRunDateOkay = true;
                if(onboardingRecord.Run_Date__c < AddBusinessDays(System.today(), 2))
                {
                    newBusinessRunDateOkay = false;
                }
                else
                {
                    newBusinessRunDateOkay = true;
                }
            }
        }
        else
        {
            newBusinessRunDateOkay = true;
            existingBusinessRunDateOkay = true;
        }
        
        validate();
    }
    
    //Add business days to a date
    public static Date addBusinessDays(Date startDate, Integer businessDaysToAdd )
    {
        //Add or decrease business days
        Date finalDate = startDate;
        Integer direction = businessDaysToAdd < 0 ? -1 : 1;
        while(businessDaysToAdd != 0)
        {
            finalDate = finalDate.addDays(direction);
            if (!isWeekend(finalDate))
            {
                businessDaysToAdd -= direction;
            }
        }
        return finalDate;
    }
    
    //Check if a date is a weekend day
    public static Boolean isWeekend(Date myDate)
    {
        String myDateString = Datetime.newInstance(myDate.year(), myDate.month(),myDate.day()).format('EEE');
        return 'Sat'.equals(myDateString) || 'Sun'.equals(myDateString);
    }
    //VERIFIED
    
    //Determine whether it's a Mandate sale or not
    public void verifyCAMandate()
    {
        if(runningUser.User_Type__c == 'CA Mandate')
        {
            List<AggregateResult> productGroups = [SELECT Product_Group__c FROM Product2 WHERE Id IN (SELECT Product2Id FROM OpportunityLineItem WHERE OpportunityId = :onboardingOpp.id) GROUP BY Product_Group__c];
            System.debug('productGroups -- ' + productGroups);
            for(AggregateResult prodGroup : productGroups)
            {
                string strProductGroup = String.valueOf(prodGroup.get('Product_Group__c'));
                
                if(strProductGroup == 'Payroll')
                {
                    hasPayrollProduct = true;
                    System.debug('PAYROLL PRODUCT -- TRUE');
                } 
                else if(strProductGroup == 'Retirement')
                {
                    has401kProduct = true;
                    System.debug('RETIREMENT PRODUCT -- TRUE');
                } 
            }
        
            typeSelected = true; 
            onboardingRecord.Form_Type__c = 'NCO'; 
            onboardingOpp.Mandate_Sale__c = true;
            isMandateSale = true;
        } 
        else 
        {
            hasPayrollProduct = true;
            onboardingOpp.Mandate_Sale__c = false;
            isMandateSale = false;
        }
    }
    @AuraEnabled
    public static void updateTrackerValidation(CSO_Tracking__c trackerToUpdate, Boolean fieldValue){
        trackerToUpdate.SSTValidated__c = fieldValue;
        update trackerToUpdate;
    }
    @AuraEnabled
    public static void updateAuthOfficer(String onboardingId, String contactId){
        System.debug('ONBOARDINGiD= '+onboardingId);
        Onboarding_Tool__c onboarding = [Select Id, Authorize_Officer__c from Onboarding_Tool__c Where Id=:onboardingId];
        System.debug('ONBOARDING OBJECT ID= '+onboarding.Id);
        onboarding.Authorize_Officer__c = contactId;
        System.debug('AUTHORIZED OFFICER ID= '+onboarding.Authorize_Officer__c);
        update onboarding;
    }
   	@AuraEnabled
    public static String createOnboardingRecord(CSO_Tracking__c trackerToUpdate, Opportunity oppty, String accountId, String accountName, Boolean isParent,Boolean isMulti,String parentOnboarding ){
        Id acctId = (trackerToUpdate != null ? trackerToUpdate.AccountId__c : accountId);
        System.debug('createOnboardingRecord acctId='+acctId);
        Account acct = null;
        try {
           acct = [Select Id, Name, SalesParent__c, isParent__c, isChild__c from Account where Id = :acctId];
        } catch (Exception e) {
           System.debug('createOnboardingRecord e='+e.getMessage()+'; '+e.getStackTraceString());
        }
        acctId = (acct != null ? acct.Id : acctId);
        isParent = (acct != null ? acct.isParent__c : isParent);
        isMulti = (acct != null ? (acct.isParent__c || acct.isChild__c) : isMulti);
        
        Onboarding_Tool__c[] existingOnboards = [Select Id, AccountId__c, Opportunity_Id__c, Is_Parent__c, isMultiIdParent__c
                                                  From Onboarding_Tool__c
                                                 Where AccountId__c = :acctId
                                                  order by CreatedDate desc limit 1];
        if (existingOnboards.isEmpty()) {
           
        }
        Onboarding_Tool__c newOnboardingRec = new Onboarding_Tool__c(Opportunity_Id__c = oppty.Id, AccountId__c = (acct != null ? acct.Id : null), ClientTracking__c=trackerToUpdate.Id);
        newOnboardingRec.Sales_Parent__c = (acct != null ? acct.SalesParent__c : null);
        Integer onboardingNameSize = Onboarding_Tool__c.Name.getDescribe().getLength();

        if(isParent){
            newOnboardingRec.Name = oppty.Name.left(onboardingNameSize);
            newOnboardingRec.Is_Parent__c = true;
            if(isMulti){
                newOnboardingRec.isMultiIdParent__c = true;
            }
        }else{
            newOnboardingRec.Parent_Onboarding_Record__c = parentOnboarding;
            newOnboardingRec.Name = accountName.left(onboardingNameSize);
        }
        insert newOnboardingRec;
        trackerToUpdate.Onboarding_Tool__c = newOnboardingRec.Id;
        update trackerToUpdate;
        return newOnboardingRec.Id;       
    }
} // class OnboardingController