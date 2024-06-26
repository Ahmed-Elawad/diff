/* 
* Test methods for KeyWordSearchController.
*
* History
* -------
* 08/02/2021    Ahmed Elawad       Created
*/

@isTest
public class KeyWordSearchControllerTest {
    
    @testSetup
    Static void setupData() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acctA = new Account(Name = 'ParentTestAccountCommunities', AccountNumber = '8-00081234', RecordTypeId=rtAcct.getRecordTypeId(), NumberOfEmployees = 60, BillingStreet = 'This is a Test Billing Address', 
                                    BillingPostalCode='1234', BillingState='NY', BillingCity='Buffalo', Federal_Id_Number__c='1234', Phone='123-456-7890', DBA__c='TEST', NAICS_Code__c='12345');
        insert acctA;
    }
    
    static testMethod void saveAcctNAICSTest() {
        Account acct = [SELECT ID, Naics_Code__c, Naics_description__c FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        
        Test.startTest();
        Boolean succeeded = KeyWordSearchController.saveAccountNAICSCode(acct.Id, '334613', '');
        Test.stopTest();
        
        System.assert(succeeded);
        acct = [SELECT ID, Naics_Code__c, Naics_description__c FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        System.assertEquals('334613', acct.NAICS_Code__c);
    }
    
    static testMethod void getAcctNAICSTest() {
        Account acct = [SELECT ID, Naics_Code__c, Naics_description__c FROM Account WHERE Name='ParentTestAccountCommunities' LIMIT 1];
        
        Test.startTest();
        Account retAcc = KeyWordSearchController.getAccNaics(acct.Id);
        Test.stopTest();
        
        System.assertEquals(acct.NAICS_Code__c, retAcc.NAICS_Code__c);
    }
    
    static testMethod void getRecordsTest() {
        // setup some records for retrieval
        List<WC_NAICS_To_Industry_Map__c> recs = new List<WC_NAICS_To_Industry_Map__c>();
        recs.add(new WC_NAICS_To_Industry_Map__c(Name='334613', NAICS_Title__c='334613: Blank Magnetic and Optical Recording Media Manufacturing'));
        recs.add(new WC_NAICS_To_Industry_Map__c(Name='337122', NAICS_Title__c='337122: Nonupholstered Wood Household Furniture Manufacturing'));
        recs.add(new WC_NAICS_To_Industry_Map__c(Name='238160', NAICS_Title__c='238160: Roofing Contractors'));
        recs.add(new WC_NAICS_To_Industry_Map__c(Name='621340', NAICS_Title__c='621340: Offices of Physical, Occupational and Speech Therapists, and Audiologists'));
        recs.add(new WC_NAICS_To_Industry_Map__c(Name='621391', NAICS_Title__c='621391: Offices of Podiatrists'));
        
        Test.startTest();
        insert recs;
        Test.stopTest();
        
        List<SObject> r_33PrefixCodes = KeyWordSearchController.getRecords('33', 'WC_NAICS_To_Industry_Map__c', 'Id', 'NAICS_Title__c', '', 5);
        List<SObject> r_23PrefixCodes = KeyWordSearchController.getRecords('Roofing', 'WC_NAICS_To_Industry_Map__c', 'Id', 'NAICS_Title__c', '', 5);
        List<SObject> r_62PrefixCodes = KeyWordSearchController.getRecords('Offices', 'WC_NAICS_To_Industry_Map__c', 'Id', 'NAICS_Title__c', '', 5);
        
        System.assertEquals(r_33PrefixCodes.size(), 2);
        System.assertEquals(r_23PrefixCodes.size(), 1);
        System.assertEquals(r_62PrefixCodes.size(), 2);
    }
}