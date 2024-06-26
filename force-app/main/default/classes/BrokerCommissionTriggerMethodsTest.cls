// created test method for for Broker Commission trigger , Rohit Ranjan 09/01/2022

@isTest


public class BrokerCommissionTriggerMethodsTest {
     static testMethod void testInsertUpdateBrokerCommissions(){
        Account acct1 = new Account(Name='Test 2', Bis_Id__c=122, AssignedToOutboundNSR__c=true,CSCMContractStatus__c = 'Approved');
        insert acct1;
        Contact con = new Contact(AccountId=acct1.Id,LastName='Test1',Hold_Out_Reason__c=LeadCompanyMethods.HOLD_OUT_DEFAULT, NSSStatus__c=LeadCompanyMethods.STATUS_DEFAULT);
        insert con;
        Referral_Account__c refAcc = new Referral_Account__c(Name='TestRA', Account__c = acct1.id);
        insert refAcc;
        Referral_Contact__c refCon = new Referral_Contact__c(Name='TestRC', Contact__c = con.id);
        insert refCon;
        List<Broker_Commission__c> lstBC = new List<Broker_Commission__c>(); 
        Broker_Commission__c bc1 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc2 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc3 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc4 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        lstBC.add(bc1);
        lstBC.add(bc2);
        lstBC.add(bc3);
        lstBC.add(bc4);
        insert lstBC;
     }

}