/* 
 * Controller for OnboardingPDF Page.  Used to create PDF that is sent to SharePoint when onboarding an ASO client.
 *
 * History
 * -------
 * 12/10/2016   Jermaine Stukes     Created
 * 01/09/2018   Cindy Freeman       added Spanish field to pdf
 * 02/12/2018   Jermaine Stukes     added Handbook Contact field to pdf
 * 07/10/2019   Jermaine Stukes     Added Doc Desk Logic
 * 10/07/2019   Matt Fritschi       Added Have_Paychex_Promise__c for Paychex Promise product
 * 04/01/2020   Carrie Marciano     Adding changes to use Oracle CPQ Quote
 * 04/29/2020   Carrie Marciano     Removed Payroll_Frequency__c from Oracle quote query
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 */
public without sharing class OnboardingPDFController {
    
    String incomingId = ApexPages.CurrentPage().getParameters().get('id');
    public String aoName{ get; set; }
    public String aoTitle{ get; set; }
    public String ccName{ get; set; }
    public String ccTitle{ get; set; }
    public String handbookName{ get; set; }
    public String handbookTitle{ get; set; }
    public Onboarding_Tool__c onboardingRecord{ get; set; }
    public Opportunity onboardingOpp{ get; set; }
    //public List<SBQQ__Quote__c> quote{get;set;}
    //public List<SBQQ__QuoteLine__c> quoteLines{get;set;}
    public List<cafsl__Oracle_Quote__c> oracleQuote{get;set;}
    public List<cafsl__Oracle_Quote_Line_Item__c> oracleQuoteLines{get;set;}
    public String productPackageList{get;set;}
    public String productList{get;set;}
    public Boolean displayPOP{get;set;}
    public Boolean displayFlextime{get;set;}
    public Boolean displayPESS{get;set;}
    public Boolean displayHRE{get;set;}
    public Boolean displayBranch{get;set;}
    public Boolean displayExist{get;set;}
    public Boolean displayFlex{get;set;}
    public Boolean displayMPSC{get;set;}
    public Boolean displayPopSelections{get;set;}
    public Boolean displayFactors{get;set;}
    public Boolean displayFactorsOther{get;set;}
    public Boolean hasPaychexPromise{get;set;}
    public OnboardingPDFController()
    {
        initialize();
        
    }
    public void initialize(){
        displayPopSelections = false;
        displayPESS = false;
        displayPOP = false;
        displayHRE = false;
        displayBranch = false;
        displayFlex = false;
        displayMPSC = false;
        displayFactors = false;
        displayFactorsOther = false;
        hasPaychexPromise = false;

        onboardingOpp =  [Select id
                          ,AccountId
                          ,Account.AccountNumber
                          ,Account.Any_Pop__c
                          ,Account.BillingAddress
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
                          ,Account.NumberOfEmployees
                          ,Account.Phone
                          ,Account.Phone_Ext__c
                          ,Account.OwnerId
                          ,BranchClientNumber__c
                          ,Description
                          ,Employees_Paid_Per_Payroll__c
                          ,First_Payroll_Delivery_Method__c
                          ,Frequency__c
                          ,Handbook_Contact__c
                          ,Handbook_Contact__r.Name
                          ,Handbook_Contact__r.Email
                          ,LeadSource
                          ,Name
                          ,New_or_Existing_Business__c
                          ,OwnerId
                          ,of_Employees__c
                          ,Payroll_Platform__c
                          ,Payroll_Current_Prior_Method__c
                          ,Owner.Name
                          ,Owner.Person_ID_Number__c
                          ,Owner.DSA_FSS__c
                          ,Owner.DSA_FSS__r.email
                          ,RecordTypeId
                          ,Service_Location__c
                          ,Primary_Oracle_Quote__c
                          ,Primary_Oracle_Quote__r.Name
                          ,(Select Id
                            ,Accidental_Death__c
                            ,Accounts_Payable_Contact__c
                            ,Add_Onboarding__c
                            ,Alternative_Email__c
                            ,Anticipated_Start_Date__c
                            ,Authorize_Officer__c
                            ,Authorized_Officer_Name__c
                            ,Authorized_Officer_Phone__c
                            ,Authorized_Officer_Email__c
                            ,Authorize_Officer__r.Name
                            ,Authorize_Officer__r.Title
                            ,Authorize_Officer__r.Phone
                            ,Authorize_Officer__r.Email
                            ,Authorized_Off_is_HR_Contact__c
                            ,BankDocumentation__c
                            ,Branch_Number__c
                            ,Best_Call_Time__c
                            ,Business_Structure__c
                            ,changeFSS__c
                            ,ChangeOfEntity__c
                            ,Client_Loss_Risk__c
                            ,Client_Number__c
                            ,Client_Company_IDs__c
                            ,Client_Success_Meeting_Date_Time__c,
                            Client_Success_Meeting_Next_Step__c
                            ,Combo__c 
                            ,Company_Contact__c
                            ,Company_Contact__r.Email
                            ,Company_Contact__r.Name
                            ,Company_Contact__r.Title
                            ,Company_Contact_Name__c
                            ,Contact_Email__c
                            ,Contact_is_HRAdmin__c
                            ,Contact_Notes__c
                            ,Core_Medical__c
                            ,Date_Business_Formed__c
                            ,Decision_Factors_Other__c
                            ,Dental__c
                            ,DiscountOffered__c
                            ,EmpsToLoad__c
                            ,Employee_Headcount_In_Other_States__c
                            ,Employee_Headcount_Status__c
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
                            ,GL__c
                            ,Group_Term_Life__c
                            ,Handbook_Format__c
                            ,How_long_a_client__c
                            ,HR_Administrator__c
                            ,HR_Admin__c
                            ,HR_Contact_Name__c
                            ,HR_Contact_Title__c
                            ,HR_Contact_Phone__c
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
                            ,Industry__c
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
                            ,MultiBillingOption__c
                            ,MultiProdServiceCenter__c
                            ,Multi_State__c
                            ,New_Branch__c
                            ,New_Client__c
                            ,New_Existing__c
                            ,NumComboIds__c
                            ,NumEeToLoad__c
                            ,NumFlexId__c
                            ,Num_Management_EE__c
                            ,NumYearsWagesToLoad__c 
                            ,NumOf1099s__c
                            ,NumMultiIds__c
                            ,Onboarding_Contact__c
                            ,OnboardingType__c
                            ,Ongoing_Call_Day_of_the_Week__c
                            ,Opportunity_Id__c
                            ,Other_Paychex_products_in_use__c
                            ,Owner_Manager__c
                            ,PayrollContact__c
                            ,PayrollContact__r.Name
                            ,PayrollContact__r.Title
                            ,PayrollContact__r.Phone
                            ,PayrollContact__r.Email
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
                            ,RepNumber__c 
                            ,Run_Date__c
                            ,Short_Term_Disability__c
                            ,Spanish__c
                            ,StateProcessedIn__c
                            ,Submitter__c
                            ,SubmissionDate__c
                            ,Supporting_Documentation__c
                            ,Skylight__c
                            ,Taxpay__c
                            ,Tax_Exempt__c
                            ,Tax_Exempt_Id__c
                            ,Taxed_as_S_Corp__c
                            ,Top_3_HR_Needs_Why__c
                            ,Total_Num_EE__c
                            ,Vision__c
                            ,Workers_Compensation__c
                            from Onboarding_Tools__r Order by LastModifiedDate DESC Limit 1)
                          from Opportunity where id=:incomingId];
        onboardingRecord = onboardingOpp.Onboarding_Tools__r;
        //quote = [Select Have_FlexTime__c, SBQQ__Opportunity2__c from SBQQ__Quote__c where SBQQ__Opportunity2__c=:onboardingOpp.Id and SBQQ__Primary__c = true limit 1];
        //oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id and cafsl__Syncing__c = true limit 1];
        if(!test.isRunningTest()){
           oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id and cafsl__Syncing__c = true limit 1];
        } else{
          oracleQuote = [Select Id, cafsl__Opportunity__c from cafsl__Oracle_Quote__c where cafsl__Opportunity__c=:onboardingOpp.Id limit 1];
        }
        //Commented as part of SBQQ package removal
        /*if(!quote.isEmpty()){
            quoteLines = [Select Id, SBQQ__Product__c, SBQQ__PackageProductCode__c, SBQQ__Bundle__c, SBQQ__ProductName__c SBQQ__Product__r. from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quote[0].Id];
            if(!quoteLines.isEmpty())
            {
                List<String> productPackages = Label.Onboarding_DocDesk_Packages.Split(',');
                displayFlexTime = false;
                for(SBQQ__QuoteLine__c qLine : quoteLines){
                    if(!displayFlextime)
                    {
                        if(qLine.SBQQ__ProductName__c.containsIgnoreCase('Flextime')){
                            displayFlextime = true;
                        }
                    }
                    if(!hasPaychexPromise)
                    {
                        if(qLine.SBQQ__ProductName__c.contains('Paychex Promise'))
                        {
                            hasPaychexPromise = true;
                        }
                    }
                    
                    if(productPackages.contains(qLine.SBQQ__ProductName__c)){
                        productPackageList = String.isBlank(productPackageList) ? qLine.SBQQ__ProductName__c : productPackageList + ', '+qLine.SBQQ__ProductName__c;
                    }
                    else{
                        productList = String.isBlank(productList) ? qLine.SBQQ__ProductName__c : productList + ', '+qLine.SBQQ__ProductName__c;
                    }
                }
            }
        }*/
        
        
        if(!oracleQuote.isEmpty()){
            oracleQuoteLines = [Select Id, cafsl__Product__c, cafsl__Product__r.Name from cafsl__Oracle_Quote_Line_Item__c where cafsl__Oracle_Quote__c =:oracleQuote[0].Id];
            if(!oracleQuoteLines.isEmpty())
            {
                List<String> productPackages = Label.Onboarding_DocDesk_Packages.Split(',');
                displayFlexTime = false;
                for(cafsl__Oracle_Quote_Line_Item__c oQuoteLine : oracleQuoteLines){
                    if(!displayFlextime)
                    {
                        if(oQuoteLine.cafsl__Product__r.Name.containsIgnoreCase('Flextime')){
                            displayFlextime = true;
                        }
                    }
                    if(!hasPaychexPromise)
                    {
                        if(oQuoteLine.cafsl__Product__r.Name.contains('Paychex Promise'))
                        {
                            hasPaychexPromise = true;
                            System.debug('hasPaychexPromise='+hasPaychexPromise);
                        }
                    }
                    
                    if(productPackages.contains(oQuoteLine.cafsl__Product__r.Name)){
                        productPackageList = String.isBlank(productPackageList) ? oQuoteLine.cafsl__Product__r.Name : productPackageList + ', '+oQuoteLine.cafsl__Product__r.Name;
                    }
                    else{
                        productList = String.isBlank(productList) ? oQuoteLine.cafsl__Product__r.Name : productList + ', '+oQuoteLine.cafsl__Product__r.Name;
                    }
                }
            }
        }
                    
        if(onboardingRecord.PESS__c)
        {displayPESS = true;}
        if(onboardingRecord.Product__c=='HR Solutions-Flex')
        {displayFlex = true;}
        if(onboardingRecord.Product__c=='Paychex HR Essentials')
        {displayHRE = true;}

        if(!onboardingOpp.Account.Any_Pop__c)
        {
            displayPOP = true;
            if(onboardingRecord.Pop__c)
            {displayPopSelections = true;}
        }
        if(onboardingRecord.Product__c == 'HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
        {displayBranch = true;}
        if(onboardingRecord.New_Existing__c == 'Existing Paychex Client' && onboardingOpp.Employees_Paid_Per_Payroll__c < 50)
        {displayExist = true;}
        if(onboardingRecord.Product__c == 'HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c >= 50)
        {displayMPSC = true;}
        if(onboardingRecord.Product__c != 'PESS'&&onboardingRecord.Product__c != 'HR Solutions-Flex'||(onboardingRecord.Product__c == 'HR Solutions-Flex' && onboardingOpp.Employees_Paid_Per_Payroll__c < 50))
        {
            displayFactors = true;
            if(onboardingRecord.HRE_Decision_Factors__c == 'Other' ||onboardingRecord.HRE_Decision_Factors_2__c == 'Other' ||onboardingRecord.HRE_Decision_Factors_3__c == 'Other')
            {displayFactorsOther = true;}
        }
    }
}