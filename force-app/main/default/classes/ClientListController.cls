/* 
* Controller for selecting the Clients to be coded lost from the Reference HRS Termination/Transfer record
*
* History
* -------
* 08/30/2017 Lynn Michels      Created
* 11/22/2017 Lynn Michels      Add functionality for if Manager, display HRG list to choose from
* 05/24/2018 Lynn Michels      Add ability to choose client base list or controlled ownership
* 03/20/2020 Jake Hinds        Adding HR Admin
* 09/29/2020 Jake Hinds        Removing HR Admin
* 02/08/2024 Reetesh Pandey	   APR0153637 Changed code to check for HRG Name 
*/

public with sharing class ClientListController { 
    
    private Id refHRSId = null;
    private Id caseId = null;
    private Id acctId = null;
    private Id userId = null; //used to pull accounts where that user is the HRG
    public List<AcctWrapper> acctWrapperList {get; set;}
    public User curUser{get;private set;}
    public Boolean showMessage{get; set;}
    public Reference_HRS_Termination_Transfer__c refHRS;
    
    public Boolean acctsFound{get;private set;}
    public Boolean cont{get;set;} //if criteria isn't met, dont continue   
    public Boolean userIdIsSet {get;set;} //is the userId set yet?
    public Boolean selectionChosen {get;set;}// has a client list been selected?
    public string  thisBranchClientNum {get;set;}
    public String alert{get;set;}
    public Id[] excludeIds = new Id[]{};
    public Decimal employeeCount = 0;
    public String ids = '';
    
    public map<id, String> hrgNames = new map<id,String>();   
    String AreaManager = System.Label.Area_Manager_Profile;
    /** Is this part of a controlled ownership relationship? */
    public Boolean isControlledOwnership{get;set;}   
    public String hrgName {get;set;}
    public Boolean isAreaManager {get;set;} //is the user an Area Manager?
    //used by ReferenceHRGController
    public ClientListController(){       
        curUser = [Select Id, Name, Email, Profile.Name,UserRoleId,UserRole.Name,
                   UserRole.ParentRoleId from User where Id = :UserInfo.getUserId()];
        isAreaManager = curUser.Profile.Name == AreaManager;       
        userId = curUser.id;
        system.debug('isAreaManager '+ isAreaManager);        
    }
    
    //code for when the page loads with the accounts listed to select   
    public ClientListController(ApexPages.StandardController stdController){
        isAreaManager = false;        
        acctsFound = true;
        cont = true;
        showMessage = false;
        this.refHRS = (Reference_HRS_Termination_Transfer__c)stdController.getRecord();
        selectionChosen = false; 
        //query to get the fields from the Reference record that will be used in this code.
        refHRS = [SELECT Id, Case_Lookup__c, Case_Lookup__r.Status, Case_Lookup__r.AccountId, Branch_Client_Number__c, Client_IDs_to_be_Coded_Lost__c,
                  Total_of_IDs__c, Case_Type__c, Termination_or_Transfer__c, Employee_Count__c,
                  Case_Lookup__r.Account.ParentId, Code_Lost_Date__c,
                  Primary_Tier_1_Reasons__c, Primary_Tier_2_Reasons__c, Primary_Tier_3_Reasons__c,Fiscal_Year__c,Fiscal_Lost_Month__c,HRG_Name__c
                  FROM Reference_HRS_Termination_Transfer__c WHERE id =: this.refHRS.id]; 
        
        
        //set variables based on queries
        acctId = refHRS.Case_Lookup__r.AccountId;
        caseId = refHRS.Case_Lookup__c;
        refHRSId = refHRS.id;
        thisBranchClientNum = refHRS.Branch_Client_Number__c;
        curUser = [Select Id, Name, Email, Profile.Name,UserRoleId,UserRole.Name,
                   UserRole.ParentRoleId from User where Id = :UserInfo.getUserId()];
        userId = curUser.id;
        if (String.isBlank(refHRS.HRG_Name__c)){ 
            cont = false;
            alert = 'Please populate HRG Name before you proceed.';
        }        
        if(acctsFound == false){
                cont = false;
                alert = alert + 'No more clients is found. ';
            }
            //stop code if code lost date is not populated
        if (refHRS.Code_Lost_Date__c == null){ 
                cont = false;
                alert = alert + 'Please populate Code Lost Date before you can proceed.';
            }
        
        if(cont){ 
            
            hrgName = refHRS.HRG_Name__c;
            //find the accounts that have already been processed on this parent record
            for (Reference_HRS_Termination_Transfer__c rftt : [SELECT Case_Lookup__r.AccountId, Employee_Count__c, Branch_Client_Number__c
                                                               FROM Reference_HRS_Termination_Transfer__c
                                                               WHERE Parent_Ref_HRS_Termination_Transfer__c = :refHRSId]) {
                                                                   excludeIds.add(rftt.Case_Lookup__r.AccountId);  //accounts to exclude from the avialable account list
                                                                   employeeCount += rftt.Employee_Count__c;  //add up the employee count of the records already attached, does not include parent
                                                                   ids += rftt.Branch_Client_Number__c+'\r\n'; //populate the id string of the accounts already attached, does not include parent
                                                               }//end for
            
            if(refHRS.Employee_Count__c != null) {   
                employeeCount += refHRS.Employee_Count__c;  //add in the parent record's employee count
            }        
            
            isControlledOwnership = refHRS.Case_Lookup__r.Account.ParentId != null;
            
            // if it doesn't have a parent, check if it has any children
            if (!isControlledOwnership) {
                isControlledOwnership = ([Select count() from Account where ParentId = :acctId limit 1] > 0);
            }
            
            //only display the radio buttons if there is a controlled ownership option, otherwise treat as Client Base was selected
            if (isControlledOwnership){
                setupClientListOptions();
            }
            else{
                chosenList = 'Client Base';
                displayClientList();
            }
        }
    }// end ClientBaseListController    
    
    
    //to display the number of accounts being displayed
    public Integer numAccounts {get;set;}      
    
    //get the accounts available    
    public void populateAcctList(Id acctId, Id userId){       
        List<Account> acctList = new List<Account>();
        
        //CLIENT BASE QUERY
        //Accounts where the user selected is on the Prospect Client Team as the PHRS HRG
        if(chosenList == 'Client Base'){ 
            acctList = [SELECT Id, Name, ParentId, AccountNumber, NumberOfEmployees, HR_Manager__r.Name,HR_Generalist__c,HR_Generalist__r.Name
                        FROM Account  
                        WHERE HR_Generalist__r.Name =:refHRS.HRG_Name__c
                        AND Id NOT IN :excludeIds
                        AND Id !=: acctId
                        AND Id in (SELECT AccountId FROM Asset WHERE Plan_Cancel_Date__c = null
                                   AND Product_Plan_Code__c IN: ReferenceHRGController.PREMIER_PLAN_CODE_SET)
                        ORDER BY Name];
        }// end if ClientBase 
        //CONTROLLED OWNERSHIP QUERY
        else{      
            //Accounts where
            //if the Account's ParentID = Ref HRS Term/Trans Account ID (child)
            //if the Account's ParentID = Ref HRS Term/Trans's ParentId (sibling)
            //or if the Account's ID = Ref HRS Term/Trans's ParentID (is the parent) 
            //or if the Account is the same Account we started from.                   
            acctList = [SELECT Id, Name, ParentId, AccountNumber, NumberOfEmployees, HR_Manager__r.Name,HR_Generalist__c,HR_Generalist__r.Name
                        FROM Account
                        WHERE ((ParentId =: acctId) OR (ParentId != null AND ParentId =: refHRS.case_lookup__r.Account.ParentId)
                               OR (Id =: refHRS.case_lookup__r.Account.ParentId))
                        AND (Id !=: acctId)
                        AND Id NOT IN :excludeIds
                        AND Id in (SELECT AccountId FROM Asset WHERE Plan_Cancel_Date__c = null
                                   AND Product_Plan_Code__c IN: ReferenceHRGController.PREMIER_PLAN_CODE_SET)
                        ORDER BY Name];
        }//end else
        
        
        acctWrapperList = new List<AcctWrapper>();
        
        for(Account acct : acctList) {
            acctWrapperList.add(new AcctWrapper(acct));
        }
        if (acctWrapperList.isEmpty()){
            acctsFound = false;
            cont  = false;
            alert = 'No more clients have been found.';
        }//end if acctWrapperList Empty
        
        numAccounts = acctWrapperList.size();
        
    }//end populateAccountList
    
    //account wrapper class
    public class AcctWrapper{
        
        public Boolean selected{get;set;}
        public Account acct{get;set;}
        
        public AcctWrapper(Account a) {
            acct = a;
            selected = false;
        } 
    }//end AcctWrapper
    
    public list<SelectOption> clientListOptions{get;set;}
    //set radio button options if there is a controlled ownership option
    public void setupClientListOptions() {
        system.debug('setupClientSelectionOptions');
        clientListOptions = new List<SelectOption>();
        clientListOptions.add(new SelectOption('Controlled Group','Controlled Group'));
        clientListOptions.add(new SelectOption('Client Base','Client Base')); 
    }//end setupClientSelectionOptions
    
    public String chosenList{get;set;} //select list from the VF page
    
    //after the user selects the list option, set the selectionChosen
    public PageReference displayClientList(){       
        System.debug('ClientListController displayClientList curUser.UserRole.Name: '+curUser.UserRole.Name+' chosenList:'+chosenList);
        if (!String.isBlank(chosenList)){
            selectionChosen = true;
        }//end if
        //if user is an area manager, give them an option to select an HRG, otherwise, just query the List of Accounts
        if(curUser.Profile.Name == AreaManager && chosenList == 'Client Base'){
            isAreaManager = true;
            userIdIsSet = true;           
            populateAcctList(acctId, userId);
        }         
        else{
            //get the client list options   
            userIdIsSet = true;
            populateAcctList(acctId, userId); 
        }        
        
        return ApexPages.currentPage();
    }//end displayClientList    
    
    // Cancel from the page. Return to the previous page if you can.
    public PageReference cancel() {
        PageReference returnPr = new PageReference('/'+refHRSId);
        return returnPr;
    } // cancel
    
    /** For the "Select All" checkbox on the form. */
    public Boolean selectAll{get;set;}
    
    public void changeSelectAllOption() {
        for (AcctWrapper aw : acctWrapperList) { 
            aw.selected = selectAll;
        }
    }    
    
    public PageReference processSelected(){
        showMessage = true;
        //uncheck all of the select checkboxes
        selectAll = false;
        PageReference returnPr = new PageReference('/'+refHRSId);
        
        //list of selected accounts
        List<Account> selectedAccounts = new List<Account>();
        List<String> accountIdsList = new List<String>(); 
        
        if (acctWrapperList != null){
            //populate the selectedAccounts List with the accounts from the acctWrapper
            for (AcctWrapper aw : acctWrapperList){
                if(aw.selected == true){
                    selectedAccounts.add(aw.acct);
                    accountIdsList.add(aw.acct.AccountNumber);
                    ids += aw.acct.AccountNumber +'\r\n';   //add these new AccountNumbers to the list
                    
                }//end if selected
            }//end for
        }//if acctWrapperList 
        
        ids = refHRS.Branch_Client_Number__c +'\r\n'+ ids;  //add in the parent record Branch Client Number at the beginning        
        //loop through selected accounts and process the records
        if (!selectedAccounts.isEmpty()){ 
            createNewRecords(selectedAccounts);
        }
        else{
            //update parent record
            updateClientIdsField(employeeCount, 1);
        }
        
        return returnPr;    
    }//end processSelected    
    
    //Create new HRS Termination Transfer Case and Ref HRS Term/Transfer record for the prospect-clients that were selected 
    public void createNewRecords(List<Account> selectedAccounts){
        integer accountCount;
        
        //if the user already selected clients and the Total # of IDs is populated,
        //we want to add to that number, otherwise, start with 1
        if (refHRS.Total_of_IDs__c != null){
            accountCount = excludeIds.size() + selectedAccounts.size() + 1;//adding one to consider the parent record
        } 
        else{
            accountCount = selectedAccounts.size() + 1;
        }       
        List<Case> newCases = new List<Case>();
        List<Reference_HRS_Termination_Transfer__c> newRefs = new List<Reference_HRS_Termination_Transfer__c>();
        Id caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId();
        Id refRT = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Related Term/Transfer Record').getRecordTypeId();
        
        //create one case for each account selected
        for (Account a : selectedAccounts){
            Case c = new Case(AccountId = a.id,
                              ParentId = CaseId,
                              RecordTypeId = caseRT,
                              Origin = 'Other',
                              Status = RefHRS.Case_Lookup__r.Status);
            newCases.add(c);
            employeeCount = employeeCount + a.NumberOfEmployees;
        }
        
        //update parent record
        updateClientIdsField(employeeCount, accountCount);
        
        
        if(!newCases.isEmpty()){
            insert newCases;
        }
        //create a Reference HRS Termination Transfer record for each case and link it back to the parent record
        for (Case c : newCases){
            Reference_HRS_Termination_Transfer__c refTt = new Reference_HRS_Termination_Transfer__c(
                Case_Lookup__c = c.id,
                Parent_Ref_HRS_Termination_Transfer__c = refHRSId,
                RecordTypeId = refRT,
                Termination_or_Transfer__c = refHRS.Termination_or_Transfer__c,
                Code_Lost_Date__c = refHRS.Code_Lost_Date__c,
                Primary_Tier_1_Reasons__c = refHRS.Primary_Tier_1_Reasons__c,
                Primary_Tier_2_Reasons__c = refHRS.Primary_Tier_2_Reasons__c,
                Primary_Tier_3_Reasons__c = refHRS.Primary_Tier_3_Reasons__c,
                Total_of_Employees__c = employeeCount,
                Total_of_IDs__c = accountCount,
                Case_Type__c = refHRS.Case_Type__c,
                Fiscal_Lost_Month__c = refHRS.Fiscal_Lost_Month__c,
                Fiscal_Year__c = refHRS.Fiscal_Year__c
            );
            newRefs.add(refTt);                                                 
        }//end for newCases loop
        
        if(!newRefs.isEmpty()){
            insert newRefs;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'A new record has been created for each client selected, please refresh your browser.'));
        }
    }//end createNewRecords
    
    //update the current reference record
    //an update to the parent record will trigger the RefHRSTermTransferAfter trigger to populate the children
    public void updateClientIdsField(Decimal employeeCount, Integer accountCount){
        Reference_HRS_Termination_Transfer__c refHRS = new Reference_HRS_Termination_Transfer__c();
        refHRS.id = refHRSId;
        refHRS.Client_IDs_to_be_Coded_Lost__c = ids;
        refHRS.Total_of_Employees__c = employeeCount;
        refHRS.Total_of_IDs__c = accountCount;
        update refHRS;
    }//end updateClientIdsField
    public list<SelectOption> hrgList {get;set;}
    //populate the hrgList for Area Managers
    public void getHrgsFromAccounts(Id acctId){
        hrgList = new list<SelectOption>();
        
        AggregateResult[] results = [Select count(Id) nbr_results, HR_Generalist__c, HR_Generalist__r.User_Lookup__c hrg_userId, HR_Generalist__r.Name hrg_name
                                     From Account
                                     Where HR_Manager__r.User_Lookup__c=:curUser.Id
                                     group by HR_Generalist__c, HR_Generalist__r.User_Lookup__c,HR_Generalist__r.Name
                                     ORDER BY HR_Generalist__r.Name];
        
        System.debug('hrgList results='+results.size());
        
        for (AggregateResult result : results) {
            String hrgName = (String)result.get('hrg_name');
            Id hrgId = (Id)result.get('hrg_userId');
            System.debug('hrgList hrgId='+hrgId+' hrgName='+hrgName);
            if (hrgId != null) {
                hrgList.add(new SelectOption(hrgId, hrgName));
                hrgNames.put(hrgId,hrgName);
            }
        }
    }//end getHrgs from Accounts    
    
}//end ClientBaseListController Class