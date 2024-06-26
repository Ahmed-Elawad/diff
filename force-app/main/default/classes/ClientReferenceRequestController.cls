/* 
 * Controller for requesting a Client reference. 
 *
 * History
 * -------
 * 06/27/2017 Cindy Freeman     Created
 * 03/12/2018 Cindy Freeman     added more product filters
 * 03/26/2018 Cindy Freeman    modified Account Type filter to exclude HRS Client (Only)
 * 04/10/2018 Cindy Freeman     fix bug for first time searches selecting more than 3 references
 * 04/23/2018 Cindy Freeman     added Best Practice message (from custom label) to top of page
 * 04/30/2018 Cindy Freeman     added Additional Feedback to search results display, changed Preview to Flex Migration checkbox to use survey field
 * 11/05/2018 Frank Lurz        added Notes to Client References Selected
 * 03/26/2019 Cindy Freeman     changed to use CLS_Satisfaction_Comment__c from Client Reference record
 * 03/17/2020 Cindy Freeman     added escapeSingleQuotes string method to avoid soql injection problems
*/

public without sharing class ClientReferenceRequestController {
    
    public Id optyId{get; set;}                 // opportunity that we started from
    public User runningUser{get;set;}           // runningUser
     
    public Opportunity opty {get; set;}
    public Client_Reference_Requests__c crRequest {get; set;}       // request we are currently working on
    public Client_Reference__c filterClientRef {get; set;}          // dummy ClientRef created to use in component
    public Account filterAcct {get; set;}
    public Boolean filterPreviewtoFlex {get; set;}                  // account filter field
    public Boolean filterHROnline {get; set;}                       // account filter field
    public Boolean filterLabor {get; set;}                          // account filter field
    public Boolean filterJobCosting {get; set;}                     // account filter field
    public Boolean filterCertPayroll {get; set;}                    // account filter field
    public Boolean filterX401k{get; set;}                           // account filter field
    public Boolean filterFSA{get; set;}                             // account filter field
    public Boolean filterMedical{get; set;}                         // account filter field
    public Boolean filterPOP{get; set;}                             // account filter field
    public Boolean filterSimpleIRA{get; set;}                       // account filter field
    public Boolean filterWCPS{get; set;}                            // account filter field
    public Boolean filterMultiId{get; set;}                         // account filter isChild or isParent fields
        
    /* map of Selected Client Reference rcds to insert */
    public Map<Id, Client_References_Selected__c> selectedClientRefMap;
    /*  Client Reference rcds to update they have been selected  */                 
    public Map<Id, Client_Reference__c> clientRefUpdateMap = new Map<Id, Client_Reference__c>();
    /*  set of Client Reference Ids that have been returned in query so don't display them in next query */      
    public Set<Id> displayedClientRefSet = new Set <Id>();
    
    /** Are any references active and linked to opty? (custom letting)Client Reference Selected Limit - already linked = availableSelectedLimit*/
    public Integer availableSelectedLimit {get; set;}
    public String limitWarning {get; set;}  
    public Boolean isLimitWarning{
      //get {return (String.isNotBlank(limitWarning)); }
      get; set;
    } // isLimitWarning
    public String pageMessage {get; set;}   
    
    /** How many references have been selected? */
    public Integer selectedCount{
      get {return (selectedClientRefMap.isEmpty() ? 0 : selectedClientRefMap.size()); }
    }
     
            
    public List<QueryResults> resultList{get; set;}  
    public class QueryResults {
       public String crId{get; set;}
       public String acctId{get; set;}
       public String acctName{get; set;}
       public String acctIndustry{get; set;}
       public String acctType{get; set;}
       public String acctCurrPriorMethod{get; set;}
       public String acctZip{get; set;}
       public String acctPkg{get; set;}
       public Integer acctEmp{get; set;}
       public String acctState{get; set;}
       public String acctCurrPkg{get; set;}
       public String acctPayrollType{get; set;}
       public String acctNumber{get; set;}
       public String prodReference{get; set;}
       public String notes{get; set;}
       public String surveyComments{get; set;}
       public Integer bisId{get; set;}
       public String ctctId{get; set;}
       public String ctctName{get; set;}
       public Integer respondentId{get; set;}
       public Boolean acctFlexMigration{get; set;}
       public Boolean acctX401k{get; set;}
       public Boolean acctFSA{get; set;}
       public Boolean acctMedical{get; set;}
       public Boolean acctPOP{get; set;}
       public Boolean acctSimpleIRA{get; set;}
       public Boolean acctWCPS{get; set;}
       public String vocIndicator{get; set;}
        public String prevMethod2{get; set;}
       public Boolean selected{get; set;}
    }
    /* list of query results that user selected so can display on bottom page so they dont select them again*/
    public List<QueryResults> selectedList{get; set;} 

    /* picklist and filter values */
    public List<SelectOption> acctTypeOptions{get; set;}    
    public String selectedAcctType {get; set;}
                
    public List<SelectOption> benetracOptions{get; set;}    
    public String selectedBenetrac {get; set;}
    
    public List<SelectOption> taaOptions {get; set;}    
    public String selectedTAA {get; set;}
    
    public List<SelectOption> glOptions {get; set;} 
    public String selectedGL {get; set;}
    
    public List<SelectOption> strategicAcctOptions {get; set;}
    public String selectedStrategicAcct {get; set;}
    
    public List<SelectOption> acctSftwrOptions {get; set;}
    public String selectedAcctSftwr {get; set;}
    
    public List<SelectOption> flexHiringOptions {get; set;}
    public String selectedFlexHiringString {get; set;}
    public String[] selectedFlexHiring {get; set;}
    
    public String eeMin {get; set;}         // what is minimum Employee count you want
    public String eeMax {get; set;}         // what is maximum Employee count you want
    
    public String zip {get; set;}               // allow users to put in comma delimited list of zip codes
    public String state {get; set;}             // allow users to put in comman delimited list of 2 char states
    
    /* things for mobile */
    public boolean renderVForce {get; set;}
    public boolean showSelected {get; set;}     // user selected a client, display on bottom of page
    
    /* Toggle visualforce display to speed initial load */
    public void toggleVForce(){
       renderVForce=TRUE;
    }
    
    /* Is this displaying in Salesforce1? */
    public Boolean isSF1 {get; set;}

    public String currentStep{get;set;}
    public static final String ERROR='ERROR';
    public static final String SEARCH='SEARCH';
    public static final String SELECTED='SELECTED';
    public static final String RESET='Reset';
    
    /** Did an error occur? */
    public Boolean isError{
      get {return (String.isNotBlank(currentStep) && currentStep == ERROR); }
    } // isError
    
    /** Did we do a search? */
    public Boolean isSearch{
      get {return (String.isNotBlank(currentStep) && currentStep == SEARCH); }
    } // isSearch
         
    /** Did we save some selectedion? */
    public Boolean isSelected{
      get {return (String.isNotBlank(currentStep) && currentStep == SELECTED); }
    } // isSelected
    
    /** Constructor */
    public ClientReferenceRequestController() {
        Integer previousSelectedCount = 0;
        optyId = ApexPages.CurrentPage().getParameters().get('optyId');
                
        opty = [Select Id, Name, AccountId, Account.Name, StageName, ExpectedRevenue from Opportunity where id = :optyId]; 
              
        if (opty == null)
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The id passed into this form is not valid! id='+optyId));
            //PageReference pr= new PageReference('/home/home.jsp');
            return;  // pr;
        }
        
        pageMessage = Label.Client_Reference_Page_Message+'\n';
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, pageMessage));
        
        Client_References_Selected__c[] crsList =  [select id from Client_References_Selected__c where Opportunity__c = :optyId and (Status__c = 'Approved' or Status__c = 'Waiting on Approval')];
        previousSelectedCount = (crsList == null || crsList.isEmpty()? 0 : crsList.size());
        if (previousSelectedCount > 0)
        {   // check counts to be sure no more than 3 client references on an opty
            availableSelectedLimit = Integer.valueOf(Label.Client_Reference_Selected_Limit) - previousSelectedCount; 
            limitWarning = 'You already have '+previousSelectedCount+' Client references linked to this opportunity.  You can only select '
                            +availableSelectedLimit+' more.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, limitWarning));
        } // if (previousSelectedCount
        else
        {   availableSelectedLimit = Integer.valueOf(Label.Client_Reference_Selected_Limit);    }
        runningUser = UserHelper.getRunningUser();
        
        selectedClientRefMap = new Map<Id, Client_References_Selected__c>();
        displayedClientRefSet = new Set<Id>();
        selectedList = new List<QueryResults>();
        
        showSelected = false;
        renderVForce = true;
        isSF1 = Utilities.isSF1();        
        currentStep = 'initialLoad';
        
        filterClientRef = new Client_Reference__c();
        filterAcct = new Account();     
        
        acctTypeOptions = new List<SelectOption>();
        acctTypeOptions.add(new SelectOption('--None--','--None--'));
        for (ClientReferenceAccountTypes__c at: ClientReferenceAccountTypes__c.getAll().Values())
        {   acctTypeOptions.add(new SelectOption(at.Name,at.Name));     }
                
        benetracOptions = new List<SelectOption>();
        benetracOptions.add(new SelectOption('--None--','--None--'));
        Schema.DescribeFieldResult field  = Account.Benefits_Administration__c.getDescribe();       
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   benetracOptions.add(new SelectOption(f.getLabel(), f.getLabel()));  }           
        
        taaOptions = new List<SelectOption>();
        field = Account.Time_and_Attendance__c.getDescribe();
        taaOptions.add(new SelectOption('--None--','--None--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   taaOptions.add(new SelectOption(f.getLabel(), f.getLabel()));      }
     
        glOptions = new List<SelectOption>();
        field = Account.General_Ledger__c.getDescribe();
        glOptions.add(new SelectOption('--None--','--None--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   glOptions.add(new SelectOption(f.getLabel(), f.getLabel()));      }
        
        strategicAcctOptions = new List<SelectOption>();
        field = Account.National_Account_Number__c.getDescribe();
        strategicAcctOptions.add(new SelectOption('--None--','--None--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   strategicAcctOptions.add(new SelectOption(f.getLabel(), f.getLabel()));      }
        
        acctSftwrOptions = new List<SelectOption>();
        field = Account.Accounting_Software__c.getDescribe();
        acctSftwrOptions.add(new SelectOption('--None--','--None--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   acctSftwrOptions.add(new SelectOption(f.getLabel(), f.getLabel()));      }
        
        flexHiringOptions = new List<SelectOption>();
        field = Account.Flex_Hiring__c.getDescribe();
        flexHiringOptions.add(new SelectOption('--None--','--None--'));
        for (Schema.PicklistEntry f : field.getPicklistValues())
        {   flexHiringOptions.add(new SelectOption(f.getLabel(), f.getLabel()));      }
        
    } // constructor


    /** Do the Search
    */
    public PageReference runSearch() {

        // save filter criteria from last search
        if (crRequest != null && currentStep != RESET)
        {   update crRequest;   }
        
        toggleVForce();
        PageReference pg = null;
        currentStep = SEARCH;
        User sales_rep_User;
                
        crRequest = new Client_Reference_Requests__c();         // saving new filter criteria   
        crRequest.Submitter__c = runningUser.Id;
        crRequest.Number_Found__c = 0;
        crRequest.Number_Selected__c = 0; 
        upsert crRequest;                                       // insert almost empty record so have Id for later  

        crRequest.Business_Type_1__c = filterClientRef.Business_Type_1__c;          
        crRequest.Business_Type_2__c = filterClientRef.Business_Type_2__c;          
        crRequest.Previous_Method_Level_2__c = filterClientRef.Previous_Method_Level_2__c;
        crRequest.Years_of_Service__c = filterClientRef.Years_of_Service__c;
        /*
        if (filterAcct.OwnerId != null)
        {   sales_rep_User = [select Id, Name from User where Id = :filterAcct.OwnerId];
            crRequest.PR_Sales_Rep__c = sales_rep_User.Name;
        } 
        */      
        crRequest.Account_Type__c = (selectedAcctType == '--None--'? Null : selectedAcctType);
        //crRequest.PR_Active_EE_Categories__c = filterClientRef.PR_Active_EE_Categories__c;
        crRequest.EE_min__c = (String.isBlank(eeMin)? null : Integer.valueOf(String.escapeSingleQuotes(eeMin)));
        crRequest.EE_max__c = (String.isBlank(eeMax)? null : Integer.valueOf(String.escapeSingleQuotes(eeMax)));
        crRequest.State__c = (String.isBlank(state)? null : String.escapeSingleQuotes(state));
        crRequest.Preview_to_Flex_Migration__c = filterPreviewtoFlex;
        crRequest.Zipcode__c = (String.isBlank(zip)? null : String.escapeSingleQuotes(zip));
        crRequest.HRIS_Current_Prior_Method__c = filterAcct.HRIS_Current_Prior_Method__c;
        crRequest.ATS_Current_Prior_Method__c = filterAcct.ATS_Current_Prior_Method__c;
        crRequest.Time_and_Attendance__c = (selectedTAA == '--None--'? Null : selectedTAA);
        crRequest.HR_Online__c = filterHROnline;
        crRequest.Job_Costing__c = filterJobCosting;
        crRequest.Labor_Distribution__c = filterLabor;
        crRequest.Certified_Payroll__c = filterCertPayroll;
        crRequest.X401_k__c = filterX401k;
        crRequest.FSA__c = filterFSA;
        crRequest.Medical__c = filterMedical;
        crRequest.POP__c = filterPOP;
        crRequest.SimpleIRA__c = filterSimpleIRA;
        crRequest.PAYX_WCPS__c = filterWCPS;
        crRequest.Multi_Id__c = filterMultiId;
        crRequest.Benefits_Administration__c = (selectedBenetrac == '--None--'? Null : selectedBenetrac);
        crRequest.General_Ledger__c = (selectedGL == '--None--'? Null : selectedGL);
        crRequest.Strategic_Account_Number__c = (selectedStrategicAcct == '--None--' ? Null : selectedStrategicAcct);
        crRequest.Accounting_Software__c = (selectedAcctSftwr == '--None--' ? Null : selectedAcctSftwr);
        //crRequest.Flex_Hiring__c = (selectedFlexHiring == '--None--' ? Null : selectedFlexHiring);
        //System.debug('**CMF ** selectedFlexHiring='+selectedFlexHiring+'? size='+selectedFlexHiring.size()); 
        crRequest.Flex_Hiring__c = '';
        if (!selectedFlexHiring.isEmpty())
        {   for (String fh : selectedFlexHiring)
            {   if (fh != '--None--')
                {   crRequest.Flex_Hiring__c = crRequest.Flex_Hiring__c + '\'' + fh+'\',';      }
            } // for
            crRequest.Flex_Hiring__c = (String.isBlank(crRequest.Flex_Hiring__c) ? '' : '(' + crRequest.Flex_Hiring__c.Left(crRequest.Flex_Hiring__c.length()-1)+')');
            selectedFlexHiringString = crRequest.Flex_Hiring__c;
        } 
        //System.debug('**CMF ** crRequest.Flex_Hiring__c='+crRequest.Flex_Hiring__c+' selectedFlexHiringString='+selectedFlexHiringString);
                
        String whereClause = '';

        // filter criteria on Client Reference          
        if (filterClientRef.Business_Type_1__c != null)
        {   whereClause = whereClause + ' and Business_Type_1__c = \''+String.escapeSingleQuotes(filterClientRef.Business_Type_1__c)+'\''; }
        if (filterClientRef.Business_Type_2__c != null)
        {   whereClause = whereClause + ' and Business_Type_2__c = \''+String.escapeSingleQuotes(filterClientRef.Business_Type_2__c)+'\''; }
        if (filterClientRef.Previous_Method_Level_2__c != null)
        {   whereClause = whereClause + ' and Previous_Method_Level_2__c = \''+String.escapeSingleQuotes(filterClientRef.Previous_Method_Level_2__c)+'\''; }
        
        if (filterClientRef.Years_of_Service__c != null)
        {   whereClause = whereClause + ' and Years_of_Service__c = \''+String.escapeSingleQuotes(filterClientRef.Years_of_Service__c)+'\'';   }
        
        if (sales_rep_User != null)
        {   whereClause = whereClause + ' and PR_Sales_Rep__c = \''+String.escapeSingleQuotes(sales_rep_User.Name)+'\'';   }
        
        if (filterPreviewtoFlex)
        {   whereClause = whereClause + ' and Survey__c = \'PTF\'';  }
                
        // filter criteria on Account
        if (selectedAcctType != null && selectedAcctType != '--None--')
        {   whereClause = whereClause + ' and Account__r.Type = \''+String.escapeSingleQuotes(selectedAcctType)+'\'';  }
        else
        {  whereClause = whereClause + ' and Account__r.Type != \'HRS Client (Only)\'';  }
        
        /*
        if (filterClientRef.PR_Active_EE_Categories__c!= null && filterClientRef.PR_Active_EE_Categories__c != '--None--')
        {   List<Integer> integerOptionList = splitOptions(filterClientRef.PR_Active_EE_Categories__c);
            if (!integerOptionList.isEmpty() && integerOptionList.size() < 2)
            {   whereClause += ' and Account__r.NumberOfEmployees <= '+integerOptionList.get(0);    }
            else if (!integerOptionList.isEmpty())
            {   whereClause += ' and Account__r.NumberOfEmployees >='+integerOptionList.get(0) +' and Account__r.NumberOfEmployees <= '+integerOptionList.get(1);   }
        }
        */
        if (!String.isBlank(eeMin))
        {   whereClause += ' and Account__r.NumberOfEmployees >='+Integer.valueOf(String.escapeSingleQuotes(eeMin));   }
        if (!String.isBlank(eeMax))
        {   whereClause += ' and Account__r.NumberOfEmployees <='+Integer.valueOf(String.escapeSingleQuotes(eeMax));   }
        
        List<String> stateList = new List<String>();
        if (String.isNotBlank(state) && state.contains(','))
        {   String xstate = String.escapeSingleQuotes(state);
            stateList.addAll(xstate.split(',')); 
            whereClause += ' and Account__r.BillingState in :stateList';
        }
        else if (String.isNotBlank(state) && state.length() == 2)
        {   whereClause += ' and Account__r.BillingState = \''+String.escapeSingleQuotes(state)+'\'';  }
    
        List<String> zipList = new List<String>();
        if (zip != null && zip.contains(','))
        {   String xzip = String.escapeSingleQuotes(zip);
            zipList.addAll(xzip.split(',')); 
            whereClause += ' and Account__r.Owner_Zip_Code__c in :zipList';
        }
        else if (zip != null && zip.length() == 5)
        {   whereClause += ' and Account__r.Owner_Zip_Code__c = \''+String.escapeSingleQuotes(zip)+'\'';   }
        
        //if (filterPreviewtoFlex)                                              // changed to use Survey field instead of account field
        //{   whereClause = whereClause + ' and Account__r.Preview_to_Flex_Migration__c = '+filterPreviewtoFlex;  }

        if (filterAcct.HRIS_Current_Prior_Method__c != null)
        {   whereClause = whereClause + ' and Account__r.HRIS_Current_Prior_Method__c = \''+String.escapeSingleQuotes(filterAcct.HRIS_Current_Prior_Method__c)+'\'';   }

        if (filterAcct.ATS_Current_Prior_Method__c != null)
        {   whereClause = whereClause + ' and Account__r.ATS_Current_Prior_Method__c = \''+String.escapeSingleQuotes(filterAcct.ATS_Current_Prior_Method__c)+'\''; }

        if (selectedTAA != null && selectedTAA != '--None--')
        {   whereClause = whereClause + ' and Account__r.Time_and_Attendance__c = \''+String.escapeSingleQuotes(selectedTAA)+'\''; }

        if (filterHROnline)
        {   whereClause = whereClause + ' and Account__r.HR_Online__c = '+filterHROnline;   }

        if (filterJobCosting)
        {   whereClause = whereClause + ' and Account__r.Job_Costing__c = '+filterJobCosting;   }

        if (filterLabor)
        {   whereClause = whereClause + ' and Account__r.Labor_Distribution__c = '+filterLabor; }

        if (filterCertPayroll)
        {   whereClause = whereClause + ' and Account__r.Certified_Payroll__c = '+filterCertPayroll;    }

        if (filterX401k)
        {   whereClause = whereClause + ' and Account__r.X401_k__c = '+filterX401k; }
        
        if (filterFSA)
        {   whereClause = whereClause + ' and Account__r.FSA__c = '+filterFSA;  }
        
        if (filterMedical)
        {   whereClause = whereClause + ' and Account__r.Medical__c = '+filterMedical;  }
        
        if (filterPOP)
        {   whereClause = whereClause + ' and Account__r.POP__c = '+filterPOP;  }
        
        if (filterSimpleIRA)
        {   whereClause = whereClause + ' and Account__r.SimpleIRA__c = '+filterSimpleIRA;  }
        
        if (filterWCPS)
        {   whereClause = whereClause + ' and Account__r.PAYX_WCPS__c = '+filterWCPS;   }
        
        if (filterMultiId)
        {   whereClause = whereClause + ' and (Account__r.isChild__c = true or Account__r.isParent__c = true)'; }        
        
        if (selectedBenetrac != null && selectedBenetrac != '--None--')
        {   whereClause = whereClause + ' and Account__r.Benefits_Administration__c = \''+String.escapeSingleQuotes(selectedBenetrac)+'\'';    }

        if (selectedGL != null && selectedGL != '--None--')
        {   whereClause = whereClause + ' and Account__r.General_Ledger__c = \''+String.escapeSingleQuotes(selectedGL)+'\'';   }

        if (selectedStrategicAcct != null && selectedStrategicAcct != '--None--')
        {   whereClause = whereClause + ' and Account__r.National_Account_Number__c = \''+String.escapeSingleQuotes(selectedStrategicAcct)+'\'';   }
        
        if (selectedAcctSftwr != null && selectedAcctSftwr != '--None--')
        {   whereClause = whereClause + ' and Account__r.Accounting_Software__c = \''+String.escapeSingleQuotes(selectedAcctSftwr)+'\'';   }
        
        if (!String.isBlank(selectedFlexHiringString)) // selectedFlexHiring != null && selectedFlexHiring != '--None--')
        {   whereClause = whereClause + ' and Account__r.Flex_Hiring__c in '+selectedFlexHiringString;  }
        
        // exclude client references more than 1 year old
        whereClause = whereClause + ' and Expiration_Date__c > TODAY';
        
        //apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'whereClause='+whereClause));
        System.debug('**CMF ** whereClause='+whereClause);

        resultList = new List<QueryResults>();      
        
        String queryString = 'select Id, Account__c, Account__r.Name, Contact__c, Contact__r.Name, Completed_Date__c, ';
        queryString += 'Respondent_Id__c, VoC_Indicator__c, Account__r.Preview_to_Flex_Migration__c, BIS_Id__c, '; 
        queryString += 'Previous_Method_Level_2__c, Additional_Feedback__c, CLS_Satisfaction_Comments__c, CLS_Satisfaction_Comment__c, Product_Reference__c, ';
        queryString += 'Account__r.Industry, Account__r.Current_Prior_Method__c, Account__r.Owner_Zip_Code__c,'; 
        queryString += 'Account__r.Current_Package__c, Account__r.AccountNumber, Account__r.NumberOfEmployees,';
        queryString += 'Account__r.HRIS_Current_Prior_Method__c,Account__r.ATS_Current_Prior_Method__c,';
        queryString += 'Account__r.BillingState, Account__r.Benefits_Administration__c,';
        queryString += 'Account__r.Certified_Payroll__c , Account__r.General_Ledger__c, Account__r.HR_Online__c,';
        queryString += 'Account__r.Job_Costing__c, Account__r.Labor_Distribution__c,';
        queryString += 'Account__r.X401_k__c, Account__r.FSA__c, Account__r.Medical__c, Account__r.POP__c, Account__r.SimpleIRA__c, Account__r.PAYX_WCPS__c,';
        queryString += 'Account__r.Time_and_Attendance__c, Account__r.T_O_Accrual__c, Account__r.Accounting_Software__c,';
        queryString += 'Account__r.Flex_Hiring__c, Account__r.National_Account_Number__c, Account__r.Type, ';
        queryString += 'Account__r.Payroll_Type__c ';                                                   
        queryString += 'from Client_Reference__c '; 
        queryString += 'where Account__c != null and Account__c != \''+opty.AccountId+'\' and (VoC_Indicator__c = null OR VoC_Indicator__c = \'Available\') ';
        queryString += 'and Id Not in :displayedClientRefSet '; 
        if (String.isNotBlank(whereClause))
        {   queryString += whereClause; }
        queryString += ' order by Completed_Date__c DESC limit 5';

        //apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'queryString='+queryString));
        System.debug('**CMF ** queryString='+queryString);

        List<Client_Reference__c> clientRefList =Database.query(queryString);

//xxxxx
        if (!clientRefList.isEmpty())
        {
        for (Client_Reference__c cr: clientRefList)
        {   QueryResults qr = new QueryResults();
            qr.crId = cr.Id;
            qr.acctId = cr.Account__c;
            qr.acctName = cr.Account__r.Name;
            qr.acctType = cr.Account__r.Type;
            qr.acctIndustry = cr.Account__r.Industry;
            qr.acctCurrPriorMethod = cr.Account__r.Current_Prior_Method__c;
            qr.acctZip = cr.Account__r.Owner_Zip_Code__c;
            qr.acctNumber = cr.Account__r.AccountNumber;
            qr.prodReference = cr.Product_Reference__c;
            qr.acctEmp = cr.Account__r.NumberOfEmployees;
            qr.acctState = cr.Account__r.BillingState;
            qr.BisId = (Integer)cr.BIS_Id__c;
            qr.acctPayrollType = cr.Account__r.Payroll_Type__c;
            qr.acctCurrPkg = cr.Account__r.Current_Package__c;
            qr.ctctId = cr.Contact__c;
            qr.ctctName = cr.Contact__r.Name;
            qr.vocIndicator = cr.VoC_Indicator__c;  
            qr.acctX401k = cr.Account__r.X401_k__c;
            qr.acctFSA = cr.Account__r.FSA__c;
            qr.acctMedical = cr.Account__r.Medical__c;
            qr.acctPOP = cr.Account__r.POP__c;
            qr.acctSimpleIRA = cr.Account__r.SimpleIRA__c;
            qr.acctWCPS = cr.Account__r.PAYX_WCPS__c;  
            qr.surveyComments = (cr.Additional_Feedback__c == null ? Null : cr.Additional_Feedback__c.Left(1000));
            if (cr.CLS_Satisfaction_Comment__c != null) 
               if (cr.Additional_Feedback__c != null) {
                  qr.surveyComments = (cr.Additional_Feedback__c.Left(500) + ' : ' + cr.CLS_Satisfaction_Comment__c.Left(500) );
               }
            else {
                  qr.surveyComments = (cr.CLS_Satisfaction_Comment__c == null ? Null : cr.CLS_Satisfaction_Comment__c.Left(1000));
            }
            qr.respondentId = (Integer)cr.Respondent_Id__c;
            qr.prevMethod2 = cr.Previous_Method_Level_2__c;
            qr.acctFlexMigration = (Boolean)cr.Account__r.Preview_to_Flex_Migration__c;
            qr.selected = false;
            resultList.add(qr); 
            displayedClientRefSet.add(cr.Id);
        }    
                    
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, pageMessage));
        
        crRequest.Number_Found__c = clientRefList.size();       
        }// if (!clientRefList.isEmpty())
        else
        {    System.debug('***FRL*** clientRefList is Empty');
             String msg = 'No Results returned per your search criteria. Click Reset Search and select new criteria. ';
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
        } // if empty
        
        return NULL;                                            
    } // runSearch
    
    /** Cancel the operation - return to original record.
    */
    public PageReference cancel() {
        if (crRequest != null)
        {   upsert crRequest;   }           // save last request info
        PageReference pr= new PageReference('/'+(optyId != null ? optyId : null));
        // do you need to change some client references back to Available?!? No
        return pr;
    } // cancel
 
    /** Return to original record after inserting selected records and submitting them for approval.
    */
    public PageReference returnToOpty() {       
        if (!selectedList.isEmpty() && (selectedList.size() > availableSelectedLimit ))
        {    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You can only select '+availableSelectedLimit+' references as you already have active references linked to this Opportunity.'));
             PageReference pg = null;
             return pg; 
        }
        
        if (crRequest != null)
        {   upsert crRequest;   }           // save last request info
        if (clientRefUpdateMap != null)
        {   update clientRefUpdateMap.values(); }   // update client References with 'Waiting on Approval'
        
        if (!selectedClientRefMap.isEmpty())
        //loop thru selectedList. If Notes is populated, get the value out of selectedClientRefMap and update Notes
        for (QueryResults qr: selectedList)
          {  if (String.isNotBlank(qr.Notes))
             {  selectedClientRefMap.get(qr.crId).Notes__c = qr.Notes;  }
          }

        {   insert selectedClientRefMap.values();   
            for (Client_References_Selected__c crs: selectedClientRefMap.values())
            {     Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                  req1.setComments('Submitting Client Reference request for approval.');
                  req1.setObjectId(crs.Id);
                  // Submit the approval request
                  try
                  {   Approval.ProcessResult result = Approval.process(req1);   }
                  catch (exception e)
                  {   String errmsg = e.getMessage();
                      ErrorLog.logError('ClientReferencesMethods', 'returnToOpty', 'submitting approval request', null, errmsg);
                      ErrorLog.checkSave();               
                  } // catch
            } // for        
         } // if (!selectedClientRefMap isEmpty)
         
         PageReference pr= new PageReference('/'+(optyId != null ? optyId : null));
         return pr;
    } // returnToOpty
    
    /* run when user selects 1 of the query result records */
    public PageReference markSelected() {
        toggleVForce();
        PageReference pg = null;

        if (!selectedList.isEmpty() && selectedList.size() == availableSelectedLimit)   //== Integer.valueOf(Label.Client_Reference_Selected_Limit))
        {   String msg = 'You have already selected maximum references, you cannot select any more. ';
            msg += 'You can remove a Reference you have selected by unchecking the box, then select a new reference from the query results.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
            return pg; 
        }   
    
        Boolean selectedOne = false;
        if (!resultList.isEmpty())
        {   for (QueryResults qr: resultList)
            {   if (qr.selected && !clientRefUpdateMap.containsKey(qr.crId))
                {   crRequest.Number_Selected__c +=1;
                    //selectedOne = true;
                    Client_References_Selected__c crSelected = new Client_References_Selected__c();
                    crSelected.Client_Reference__c = qr.crId;
                    crSelected.Client_Reference_Request__c = crRequest.Id;
                    crSelected.Account__c = qr.acctId;
                    crSelected.Contact__c = qr.ctctId;
                    crSelected.Opportunity__c = optyId;
                    crSelected.Notes__c = qr.notes;
                    crSelected.Submitter__c = runningUser.Id;
                    crSelected.Status__c = 'Waiting on Approval';
                    selectedClientRefMap.put(qr.crId, crSelected);
                    Client_Reference__c clientRef = new Client_Reference__c();
                    clientRef.Id = qr.crId;
                    clientRef.VoC_Indicator__c = 'Waiting on Approval';
                    clientRefUpdateMap.put(qr.crId, clientRef);
                    // save selected to display
                    showSelected = true;
                    selectedList.add(qr);
                } // if selected
            } // for
            
        } // if not empty

        
        if (!selectedList.isEmpty() && (selectedList.size() > availableSelectedLimit ))
        {    String msg = 'You can only have a total of '+Label.Client_Reference_Selected_Limit+' references linked to an Opportunity. ';
             if (availableSelectedLimit > 0 )
             {  msg += ' You already have '+(Integer.valueOf(Label.Client_Reference_Selected_Limit)-availableSelectedLimit)+' linked.  ';   }
             msg += 'You can remove a Reference you have selected by unchecking the box, then select a new reference from the query results.'; 
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, msg));
             return pg; 
        }
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, pageMessage));
        
        return pg;      
        
    }  // markSelected
    
    /* run when user unChecks 1 of the references already selected */
    public PageReference unmarkSelected() {
        toggleVForce();
        PageReference pg = null;
    
        Integer idx = 0;
        if (!selectedList.isEmpty())
        {   for (QueryResults qr: selectedList)
            {   if (!qr.selected) // && !clientRefUpdateMap.containsKey(qr.crId))
                {   crRequest.Number_Selected__c -=1;                   
                    selectedClientRefMap.remove(qr.crId);
                    clientRefUpdateMap.remove(qr.crId);
                    break;
                } // if selected
                idx +=1;
            } // for
        } // if not empty
        
        selectedList.remove(idx);
        showSelected = (selectedList.size() > 0 ? true : false);
        
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, pageMessage));
        
        return pg;      
        
    }  // unmarkSelected
 
    /* clear displayedClientRefSet list so next search will return records it returned before */
    public PageReference resetFilter() {
        // save filter criteria from last search
        if (crRequest != null)
        {   update crRequest;   }
        
        displayedClientRefSet.clear();
        displayedClientRefSet.addAll(clientRefUpdateMap.keySet());      //  add selected clientRefs back to list so dont come back in query
        resultList.clear();
        // clear filter fields on screen
        filterClientRef = new Client_Reference__c();
        filterAcct = new Account();
        filterPreviewtoFlex  = filterHROnline = filterLabor = filterJobCosting  = filterCertPayroll = false;
        filterX401k = filterFSA = filterMedical = filterPOP = filterSimpleIRA = filterWCPS = filterMultiId = false;
        eeMin = eeMax = zip = state = null;
        selectedAcctType = selectedBenetrac = selectedTAA = selectedGL = selectedStrategicAcct = null;
        selectedAcctSftwr = selectedFlexHiringString = null;
        selectedFlexHiring.clear();
        
        currentStep = RESET;
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, pageMessage));
        PageReference pr = null;
        return pr;
    }
       
    
} // ClientReferenceRequestController