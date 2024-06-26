/*
Test class for the AutoCrossoverQueueable class.
-----------------------------------------------------------------------
08/13/2019	Matt Fritschi	Created.
*/

@isTest
public class CreateBankReferralCrossoverTest {
    
    @testSetup
    Static void Setup()
    {
        //Create Accounts
        
        //Account acct2 = new Account(Name='Test Account2');
        
        User bcr = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                    from User where HR_Person_Id__c != null 
                    and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        
        System.debug('The test Bank Centric Rep is: '+bcr.Name);
        
        //Create Acocunt
        Account acct = new Account(Name='Test Account', OwnerId=bcr.Id, Owner_Zip_Code__c='12345');
        insert acct; 
        
        System.debug('The Account is owned by: '+acct.OwnerId + ' And the owners zip code is: '+ acct.Owner_Zip_Code__c);
        //Account[] acctList = new Account[]{};
        // acctList.add(acct);
        //acctList.add(acct2);
        //insert acctList;
        
        //Create Lead
        Lead ld1 = new Lead(OwnerId=bcr.Id, FirstName='TEST', LastName='LEAD', LeadSource=LABEL.LeadSource_ReferralBank, Products__c='Payroll', IsConverted=true, ConvertedAccountId=acct.Id, Company='Test Company');
        insert ld1;
        
        
        
        //Create Referral Account
        Referral_Account__c refacct = new Referral_Account__c (name = 'Referral Account1'
                                                               ,RecordTypeId=RecordTypeHelper.getRecordType('Core Referral Source Record Type', 'Referral_Account__c').getRecordTypeId()
                                                               ,Referral_Type__c = '52 Bank Tier 2'
                                                               ,Zip_Postal_Code__c = '10000'
                                                               ,Bank_Centric_Rep__c = bcr.Id
                                                               ,To_Be_Deleted__c = false);
        insert refacct;
        
        //Create Referral Contact
        Referral_Contact__c refcon = new Referral_Contact__c(Name = 'Ref Ctct'
                                                             ,RecordTypeId=RecordTypeHelper.getRecordType('Core Referral Record Type', 'Referral_Contact__c').getRecordTypeId()
                                                             ,Phone__c = '585-555-1212'
                                                             ,Email__c = 'fLast1@abc.com'
                                                             ,Referral_Type__c = '100 Broker'
                                                             ,Referral_Account__c = refacct.Id);
        insert refcon;
        
        
        //Create Opportunity
        Opportunity opp1 = new Opportunity(Name='Test Opp1', AccountId=acct.Id, CloseDate=Date.today().addDays(14), StageName='Pending');
        insert opp1;
        
        //Create Referral
        Referral__c ref = new Referral__c(Name='Test Referral', Selling_Opportunity__c=opp1.Id, SourceLead__c=ld1.Id, Referral_Contact__c=refcon.Id);
        insert ref;
        
        opp1.ReferralLookup__c=ref.Id;
        update opp1;
        
    }//Setup()
    
    
    static testmethod void testCreateBankReferralCrossoverPayroll(){
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Opportunity opp1 = [SELECT Id, Name, AccountId, CloseDate, StageName, ReferralLookup__c FROM Opportunity WHERE Name='Test Opp1'];
        oppMap.put(opp1.ReferralLookup__c, opp1);
        Account ac = [SELECT Id, Name, OwnerId FROM Account WHERE Id=:opp1.AccountId LIMIT 1];
        User bcr = [SELECT Id, Name FROM User WHERE Id=:ac.OwnerId LIMIT 1];
        
        System.debug('Creating a Bank Centric Rep');
        CreateBankReferralCrossover CBRC;
        System.runAs(bcr)
        {
            CBRC = new CreateBankReferralCrossover(oppMap);
        }
        
        System.assertEquals('Payroll', CBRC.leadType);
        System.assertEquals(true, CBRC.didUpdate);
        System.assertEquals(false, CBRC.referralByOppId.isEmpty());
        System.assertEquals(false, CBRC.oppToAcct.isEmpty());
        System.assertEquals(false, CBRC.accountByOppId.isEmpty());
    } //testCreateBankReferralCrossoverPayroll
    
    
    static testmethod void testCreateBankReferralCrossover401k(){
        
        Lead test401kLead = [SELECT Id, name, Products__c FROM Lead WHERE Name='TEST LEAD' LIMIT 1];
        test401kLead.Products__c='401k';
        update test401kLead;
        
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Opportunity opp1 = [SELECT Id, Name, AccountId, CloseDate, StageName, ReferralLookup__c FROM Opportunity WHERE Name='Test Opp1'];
        oppMap.put(opp1.ReferralLookup__c, opp1);
        Account ac = [SELECT Id, Name, OwnerId FROM Account WHERE Id=:opp1.AccountId LIMIT 1];
        User bcr = [SELECT Id, Name FROM User WHERE Id=:ac.OwnerId LIMIT 1];
        
        System.debug('Creating a Bank Centric Rep');
        CreateBankReferralCrossover CBRC;
        System.runAs(bcr)
        {
            CBRC = new CreateBankReferralCrossover(oppMap);
        }
        
        System.assertEquals('401k', CBRC.leadType);
        System.assertEquals(true, CBRC.didUpdate);
        System.assertEquals(false, CBRC.referralByOppId.isEmpty());
        System.assertEquals(false, CBRC.oppToAcct.isEmpty());
        System.assertEquals(false, CBRC.accountByOppId.isEmpty());
    } //testCreateBankReferralCrossover401k
}