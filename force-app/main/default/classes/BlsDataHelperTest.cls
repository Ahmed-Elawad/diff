/* Test Methods for BlsDataHelper

  History
  -------
  07/19/2022 Jidesh       Created
*/

@isTest
public class BlsDataHelperTest {

    @testSetup
    public static void setupTestData() {
        Account acct1 = new Account(Name='Account1',BillingState ='CA', ShippingState='CA', NAICS_Code__c='561720');
        Account acct2 = new Account(Name='Account2',BillingState ='CA', ShippingState='CA', NAICS_Code__c='561720');
        Account[] accts = new Account[]{
            acct1,
            acct2 
                };
                    insert accts;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = accts[0].Id);
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Prospect_Client__c = accts[1].Id);
        insert checklist;
        insert checklist2;
        BLS_Med_Partcptn__c blsMedData = new BLS_Med_Partcptn__c();
        blsMedData.Name = 'Default';
        blsMedData.Prefix__c = 'NB';
        blsMedData.datatype_code__c ='26';
        blsMedData.estimate_code__c = '15';
        blsMedData.industry_code__c = '0000';
        blsMedData.ocupational_code__c = '000000';
        blsMedData.ownership_code__c = '2';
        blsMedData.provision_code__c = '179';
        blsMedData.seasonal__c = 'U';
        blsMedData.subcell_code__c = '00';
        Insert blsMedData;
        
        BLS_Average_Wage__c blsAvgWageData = new BLS_Average_Wage__c();
        blsAvgWageData.Name = 'Default';
        blsAvgWageData.seasonal__c = 'U';
        blsAvgWageData.area_code__c = '000';
        blsAvgWageData.industry_code__c = '10';
        blsAvgWageData.owner_code__c = '5';
        blsAvgWageData.Prefix__c = 'EN';
        blsAvgWageData.size_code__c = '0';
        blsAvgWageData.type_code__c = '5';
        Insert blsAvgWageData;
        
        BLS_Turnover_Rate__c blsTurnOverData = new BLS_Turnover_Rate__c();
        blsTurnOverData.Name = 'Default';
        blsTurnOverData.area_code__c = '00000';
        blsTurnOverData.dataelement_code__c = 'QU';
        blsTurnOverData.industry_code__c = '000000';
        blsTurnOverData.Prefix__c = 'JT';
        blsTurnOverData.ratelevel_code__c = 'R';
        blsTurnOverData.seasonal__c = 'U';
        blsTurnOverData.sizeclass_code__c = '00';
        blsTurnOverData.state_code__c = '00';
        Insert blsTurnOverData;
        
    }
    
    static testMethod void testfetchTheDatapoints() {
        
        List<Account> dataPointAcc = [Select id, Name, BillingState, ShippingState, NAICS_Code__c from Account];
        List<PEO_Onboarding_Checklist__c>  dataPointchecklist  = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c IN :dataPointAcc];
        BlsDataHelper.fetchTheDatapoints(dataPointAcc, dataPointchecklist,'Fetch info');
        BlsDataHelper.fetchTheDatapoints(dataPointAcc, dataPointchecklist,'CommunityMethods');
        Boolean boolVal = BlsDataHelper.fetchTheDatapoints(dataPointAcc, dataPointchecklist,'Fetch info');
        System.debug('boolVal testfetchTheDatapoints:'+boolVal);
        System.assertEquals(true, boolVal);
    }
    
    static testMethod void testExistingRecords() {
        
        List<Account> dataPointAcc = [Select id, Name, BillingState, ShippingState, NAICS_Code__c from Account];
        List<PEO_Onboarding_Checklist__c>  dataPointchecklist  = [SELECT Id, Name, Prospect_Client__c FROM PEO_Onboarding_Checklist__c WHERE Prospect_Client__c IN :dataPointAcc];
        PEOUW_BLS_Data__c blsRecordnew = new PEOUW_BLS_Data__c();
        blsRecordnew.Name = dataPointchecklist[0].Name;
        blsRecordnew.PEO_Underwriting_Checklist__c = dataPointchecklist[0].Id;
        blsRecordnew.NAICS_Code__c = dataPointAcc[0].NAICS_Code__c;
        Insert blsRecordnew;
        Boolean boolVal = BlsDataHelper.fetchTheDatapoints(dataPointAcc, dataPointchecklist,'CommunityMethods');
        System.debug('boolVal testExistingRecords:'+boolVal);
        System.assertEquals(true, boolVal);
    }
}