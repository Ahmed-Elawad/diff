/*
 * 06/03/2020 Matthew Fritschi New Error message, and checks for Amplifinity Permission Set.
 * 06/08/2020 Jake Hinds      added in without sharing per pmd
 * 10/19/2020 Brandon Vidro   Added check for Preview Clients
 * 
 *  
*/

public without sharing class PaychexLeadReferralInfoController {
    public AccountLookupComponentModel AccountLookupHelper { get; private set; }
    public boolean showPage {get;set;}
    public boolean displayAmpPage {get;set;}
   // public boolean hasReferral {get;set;}
    public string recID; 
  //  public lead ld{get;set;} 
    //public contact ct{get;set;} 
    public contact ct = new contact(); 
    public lead ld = new lead(); 
    public boolean hasReferral; 
    public boolean isLead; 
    public boolean isContact; 

    public PaychexLeadReferralInfoController(ApexPages.StandardController stdController)
    {
        displayAmpPage = FALSE;
        
         User curUser = UserHelper.getRunningUser();
        List<PermissionSetAssignment> psa = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name FROM PermissionSetAssignment WHERE AssigneeId = :curUser.Id AND PermissionSet.Name = 'Amplifinity_Page_Access'];
        //System.debug('psa='+psa);
        if(psa.size() > 0)
        {
            displayAmpPage = TRUE;
        }
        System.debug('displayAmpPage='+displayAmpPage);
        
            recID = stdController.getid(); 
            if(recID.startsWith('003')){
            ct = [select id, firstName, lastName, Email,AMP_Referral__c, Account.Type from contact where id = : recid] ;     
                isContact= true; 
                isLead = false; 
                
            }else if(recID.startsWith('00Q')){
                ld = [select id, firstName, lastName, email ,amp_dev__Referral__c from lead where id = : recid] ; 
                isLead=true; 
                isContact=false; 
            }//else if 
        
        hasReferral =false; 
        if(ct !=null && ct.AMP_Referral__c !=null) {
            hasReferral = true; 

        }//if
        
        if(ld !=null && ld.amp_dev__Referral__c !=null){
            hasReferral = true; 

        }//if 
           
        if(hasReferral){
            showPage= TRUE; 
        }//if
        
        AccountLookupHelper = new AccountLookupComponentModel();
    }

    public with sharing class AccountLookupComponentModel implements amp_dev.ISObjectIdProvider
    {
        public AccountLookupComponentModel()
        {
            this.HelperForAccountLookup = new amp_dev__Amp_Lookup_Helper__c();
        }

        public amp_dev__Amp_Lookup_Helper__c HelperForAccountLookup { get; private set; }

        public Schema.SObjectType GetLookupSObjectType()
        {
            return Schema.Account.SObjectType;
        }

        public Id GetLookupId()
        {
            return this.HelperForAccountLookup.amp_dev__Account__c;
        }

    }
        public pageReference submitReferral(){
            // amplifinity requires firstName, LastName, and email for verbal referrals 
            
            if(isContact && (ct.FirstName ==null || ct.LastName ==null || ct.Email == null)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have First Name, Last Name, and Email to submit a verbal referral'));
            }//if isContact  
            
            else if(isContact && ct.Account.Type != null && ct.Account.Type.contains('Preview')) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Preview clients are not eligible for Paychex Referral Network'));    
            }
                                 
            else if(isLead &&(ld.FirstName==null || ld.LastName==null|| ld.Email ==null)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must have First Name, Last Name, and Email to submit a verbal referral'));
                
            }//else
            else{
                showPage = true; 
            }//else 
        return null; 
    }//submit Referral 
}