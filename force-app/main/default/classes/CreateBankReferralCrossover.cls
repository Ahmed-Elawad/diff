/*
* 07/22/2019	Matt Fritschi		Created Class.
* 
* Called on Bank Referral Lead convert. Finds the created Account, updates ownership based on Zip Assignment Rules, and creates a crossover request.
* 
*/

public without sharing class CreateBankReferralCrossover {
    
    public final Map<Id, Opportunity> oppMap;
    public String leadType;
    public boolean didUpdate = false;
    public Map <Id,Referral__c> referralByOppId;
    public Map<Id, Id> oppToAcct;
    public Map<Id, Account> accountByOppId;
    
    public CreateBankReferralCrossover(Map<Id, Opportunity> opptyMap)
    {
        oppMap = opptyMap;
        startChange();
    }
    
    public void startChange()
    {
        
        //Use the oppMap keyset to find the referral based on the referral's ID
        //Create a map of all opportunity ID's and the referrals linked with those opportunities.
        referralByOppId = new Map<Id,Referral__c>();
        Referral__c[] rfrls = [Select Id, Name, Account__c,Referral_Id__c
                               ,SecondaryLeadSource__c
                               ,SellingLeadSource__c
                               ,Selling_Opportunity__c
                               ,SourceLead__c
                               ,SourceLead__r.Id
                               ,SourceLead__r.OwnerId
                               ,SourceLead__r.IsConverted
                               ,SourceLead__r.LeadSource
                               ,SourceLead__r.Products__c
                               ,Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c
                               ,Account__r.OwnerId
                               From Referral__c
                               Where ID in :oppMap.keySet()];
        
        //Check that there is a referral. If not, the lead was manually created and did not come through the form. 
        if(rfrls.size() > 0)
        {
            System.debug('oppMap: '+oppMap);
            System.debug('The Referral is: '+rfrls[0]);
            System.debug('The products are: '+rfrls[0].SourceLead__r.Products__c);
            
            //check if the lead was Payroll or 401k
            if(rfrls[0].SourceLead__r.Products__c == null || rfrls[0].SourceLead__r.Products__c.contains('Payroll'))
            {
                leadType='Payroll';
            }
            else
            {
                leadType='401k';
            }
            
            
            for(Referral__c rfrl : rfrls){
                referralByOppId.put(rfrl.Selling_Opportunity__c,rfrl);
                System.debug('CreateBankReferralCrossover The referral returned is: '+ rfrl);
            }
            
            
            //Create a map of Opportunity Ids and the newly created Account Ids they have liniked
            oppToAcct = new Map<Id, Id>();
            for(Opportunity opp : oppMap.values())
            {
                oppToAcct.put(opp.AccountId, opp.Id);
            }
            
            
            //Create a map from the Opportunity ID to the Account associated with it.
            System.debug('The number of accounts is='+oppToAcct.size() + ' They are: '+oppToAcct.keySet());
            
            accountByOppId = new Map<Id, Account>();
            Account[] accts = [Select Id, Name, OwnerId, NumberOfEmployees
                               From Account
                               Where Id in :oppToAcct.keySet()];
            
            for(Account acct : accts)
            {
                System.debug('The returned account is: '+acct);
                accountByOppId.put(oppToAcct.get(acct.Id), acct);
            } //for(Account acct : accts)
            
            //See if a crossover request needs to be created
            Opportunity opp = oppMap.get(rfrls[0].ID);
            
            //Get the Account associated with the opportunity
            Account checkAccount = (accountByOppId.get(opp.Id) != null ? accountByOppId.get(opp.Id) : null);
            
            //Get the Referral associated with the opportunity
            Referral__c rfrl = referralByOppId.get(opp.Id);
            
            //System.debug('CreateBankReferralCrossover rfrl.SourceLead__r.LeadSource='+rfrl.SourceLead__r.LeadSource+' rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c='+rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c);
            
            //check that all conditions are met
            if((rfrl.SourceLead__r.LeadSource == LABEL.LeadSource_ReferralBank && rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c == null) 
               || (rfrl.SourceLead__r.LeadSource == LABEL.LeadSource_ReferralBank && checkAccount != null && checkAccount.OwnerId == rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c))
            {
                //If ownership of the account hasn't been updated, force it's update using zip assignments
                System.debug('CreateBankReferralCrossover rfrl.SourceLead__r.LeadSource='+rfrl.SourceLead__r.LeadSource+' rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c='+rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c+' accountByOppId.get(opp.Id).OwnerId='+ checkAccount.OwnerId);
                System.debug('checkAccount.OwnerId='+checkAccount.OwnerId+' UserInfo.getUserId='+UserInfo.getUserId());
                
                checkAccount = [SELECT Id, Name, OwnerId, NumberOfEmployees, Use_Zip_Assignment_Rules__c FROM Account WHERE Id = :checkAccount.Id];
                
                System.debug('saveOpp the account being entered='+checkAccount);
                ZipCheckOwner.SKIP_TRIGGERS=false;
                System.debug('SKIP_TRIGGERS='+ZipCheckOwner.SKIP_TRIGGERS);
                checkAccount.Use_Zip_Assignment_Rules__c = true;
                
                List<Account> DMLAccountList = new List<Account>();
                DMLAccountList.add(checkAccount);
                DMLHelper.performDML2(DMLAccountList, DmlHelper.DML_UPDATE, 'CreateBankReferralCrossover', 'startChange', 'Updating ownership of Account', true);
                didUpdate=true;
                
                checkAccount = [SELECT Id, Name, OwnerId, NumberOfEmployees, Use_Zip_Assignment_Rules__c FROM Account WHERE Id = :checkAccount.Id];
                
                
            } //if((rfrl.SourceLead__r.LeadSource == LABEL.LeadSource_ReferralBank && rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c == null) || (rfrl.SourceLead__r.LeadSource == LABEL.LeadSource_ReferralBank && checkAccount != null && checkAccount.OwnerId != rfrl.Referral_Contact__r.Referral_Account__r.Bank_Centric_Rep__c))
            //If the new Account owner is not equal to the original Lead owner, create a Crossover.
            if(checkAccount.OwnerId != rfrl.SourceLead__r.OwnerId || Test.isRunningTest())
            {        
                System.debug('updatedAccount='+checkAccount);
                createCrossoverRequest(checkAccount, leadType);
            } // if(checkAccount.OwnerId != rfrl.SourceLead__r.OwnerId || Test.isRunningTest())
        } //if(rfrls.size() > 0)
        
        
        else
        {
            return;
        }
        
        /*
else
{

Opportunity[] opps = oppMap.values();
Map<Id, Id> acctIds = new Map<Id, Id>();
for(Opportunity opp : opps)
{
acctIds.put(opp.Id, opp.AccountId);
}

Account[] acct = [SELECT Id, Name, OwnerId, Use_Zip_Assignment_Rules__c, Products__c FROM Account WHERE Id IN :acctIds.values()];
Account checkAccount = acct[0];
System.debug('acct='+acct);

checkAccount.Use_Zip_Assignment_Rules__c = true;
if(checkAccount.Products__c==null)
{
checkAccount.Products__c='Payroll';
}
if(checkAccount.Products__c.contains('Payroll'))
{
leadType='Payroll';
}
else
{
leadType='401k';
}
update checkAccount;

createCrossoverRequest(checkAccount, leadType);
}
*/
        
    }
    
    public void createCrossoverRequest(Account acct, String ldType)
    {
        CrossoverRequestController crt = new CrossoverRequestController(acct, ldType);
    }
    
    
}