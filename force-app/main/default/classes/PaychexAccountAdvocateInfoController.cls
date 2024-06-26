/* 
History
--------

09/25/2019 Josh Cartwright  created
11/06/2019 Josh Cartwright change to allow sig contact to be selected if there isn't one. 
04/14/2020 Jermaine Stukes  Remove clientId requirement
06/03/2020 Matthew Fritschi New Error message, and checks for Amplifinity Permission Set.
06/08/2020 Jake Hinds      added in without sharing per pmd
07/06/2020 Matthew Fritschi Checks for Account Number or valid Opportunity.
10/19/2020 Brandon Vidro   Added check for Preview Clients
05/18/2021 Carrie Marciano  updated StageNames with OppStage labels
*/  

public without sharing class PaychexAccountAdvocateInfoController {
    public id selectedCtctID{get;set;}
    public id acctID;  
    public account acc;
    public contact newContact = null; 
    public contact sigContact = null; 
    public boolean swapContact{get;set;}
    public string sigNameEmail{get;set;}
    public map <Id, Contact> allCtMap = new map <Id, Contact>(); 
    public list <contact> allCtList = new list <contact>(); 
    public boolean displayMain {get;set;}
    public boolean displayAmp {get;set;}
    public boolean displayAmpPage {get;set;}
    public string displayMessage {get;set;}
    public account record{get;set;}
    
    public PaychexAccountAdvocateInfoController(ApexPages.StandardController stdController){
        displayMain = TRUE;
        displayAmp = TRUE;
        swapContact = FALSE;
        displayAmpPage = FALSE;
        
        User curUser = UserHelper.getRunningUser();
        List<PermissionSetAssignment> psa = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId = :curUser.Id AND PermissionSet.Name = 'Amplifinity_Page_Access'];
        //System.debug('psa='+psa);
        if(psa.size() > 0)
        {
            displayAmpPage = TRUE;
        }
        System.debug('displayAmpPage='+displayAmpPage);
        
        List<String> fields = new List<String> {'Id', 'SignificantContact__c', 'accountNumber'};
            if(!Test.isRunningTest()){                
             stdController.addFields(fields);
             record = (Account)stdController.getRecord();
            }//isrunningtest
        
        acc = (Account)stdController.getRecord();
        System.debug('acc='+acc);
        acctID = acc.id;
        acc = [SELECT Id, Name, SignificantContact__c, AccountNumber, Type FROM Account WHERE Id = :acctId LIMIT 1];
        allCtList = [select id, email, name, SignificantContact__c from contact where accountID=:acctID order by Name ASC];
        UserRecordAccess uRA = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userinfo.getuserid() AND RecordId =: acc.id Limit 1];
        
        List<Opportunity> opptyList = [SELECT Id, Name, Probability FROM Opportunity WHERE AccountId = :acctID];
        boolean hasValidOppty = False;
        
        //Check to see if the Account has a valid Opportunity.
        for(Opportunity oppty : opptyList)
        {
            if(!hasValidOppty && oppty.Probability >= 70 && oppty.Probability <= 90)
            {
                hasValidOppty = true;
            }
        }
        if(!uRA.HasEditAccess && !Test.isRunningTest()){
            displayMain = FALSE;
            displayMessage = 'You do not have permission to edit this record. Please contact the record owner.';            
        }
        else if(acc.AccountNumber == NULL && !hasValidOppty){
            displayMain = FALSE;
            displayMessage = 'This Prospect is not ready for Paychex Referral Network. Eligibility will be available during the "Verbal Commit" status.';   
        }
        else if(acc.Type != null && acc.Type.contains('Preview')) {
            displayMain = FALSE;
            displayMessage = 'Preview clients are not eligible for Paychex Referral Network';
        }
        else if(allCtList.isEmpty()){
            displayMain = FALSE;
            displayMessage = 'No Significant Contact! You must create a contact record before proceeding.';
        }
        else { 
                for(contact ct: allCtList ){
                    allCtMap.put(ct.id, ct); 
                    if(acc.SignificantContact__c != null && ct.id == acc.SignificantContact__c){
                        sigContact = ct; 
                    }//if 
                }//
                if(sigContact != NULL){
                    sigNameEmail = sigContact.Name +' - ' + (sigContact.Email !=null ? sigContact.Email : 'No Email'); 
                }
                else{
                    sigNameEmail = 'No Significant Contact! You must select one before proceeding.';
                    displayAmp = FALSE;
                }
        }
    }//PaychexAccountAdvocateInfoController
    
    public list<SelectOption> getContactNames(){
        list<SelectOption> conOptions = new List <SelectOption>();

        if(allCtMap != null){
            if(sigContact != Null){
                conOptions.add(new SelectOption(sigContact.id, sigContact.Name));
            }
            for (contact con: allCtMap.values()){
                if(sigContact == null || (sigContact != NULL && con.id != sigContact.id) ){
                    conOptions.add(new SelectOption(con.id, con.name));
                }//if                              
            } //for
        }//if
        else{
            conOptions.add( new SelectOption('--None--','--None--'));
        }//else    
        
        return conOptions;
        
    }//getContactNames 
    
    public void saveContact(){
        newContact = allCtMap.get(selectedCtctID);
        account acctToUpdate = new account();
        acctToUpdate.id = acctID; 
        acctToUpdate.SignificantContact__c = newContact.id; 
        ZipCheckOwner.SKIP_TRIGGERS = TRUE;  // skip owner triggers
        
        update acctToUpdate; 
        sigContact = newContact; 
        sigNameEmail = sigContact.Name +' - ' + (sigContact.Email !=null ? sigContact.Email : 'No Email');
        swapContact = FALSE; 
        displayAmp = TRUE;
        //if we do this we need to skip triggers. 
    }//saveContact       
    
    public pageReference changeContact(){
        getContactNames(); 
        swapContact = TRUE;
        displayAmp = FALSE;
        return null; 
    }//change
    public pageReference cancel(){
        swapContact = FALSE; 
        displayAmp = TRUE;
        return null; 
    }
}