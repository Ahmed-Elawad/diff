@isTest
public with sharing class CustomLookupLWCControllerTest {
    static testMethod void testSearch() {
        Referral_Account__c refAcct = new Referral_Account__c(Name='Test RefAcct');
        insert refAcct;
        List<Referral_Account__c> refAccList = new List<Referral_Account__c>();
        refAccList.add(refAcct);
        CustomLookupLWCController.search('', 'Referral_Account__c', '');
        List<SObject> result = CustomLookupLWCController.search('Test RefAcct', 'Referral_Account__c', '');
        System.assertEquals(result, refAccList, 'Result as expected');
    }
}