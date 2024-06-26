/* 
 * 12/13/2023 Shilpa Govindarajulu       APR0155814-Created
 * 
 * 
 */

@isTest
public class IntentHelperTest {
	static testMethod void chatterPostLeadTest(){

        Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005');
        insert l;

        Customer_Intent_Signal__c ins = new Customer_Intent_Signal__c(Marketing_Action__c = 'Action', Lead__c=l.Id, Assessment_Link__c = 'google.com');
        insert ins;
        
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    }
    
    static testMethod void chatterPostContactTest(){

        Account acct = new Account(Name='Test Acct');
        insert acct;
        
        Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
        insert ctct;

        Customer_Intent_Signal__c ins = new Customer_Intent_Signal__c(Marketing_Action__c = 'Action', Contact__c=ctct.Id, Assessment_Link__c = 'google.com');
        insert ins;
        
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    }
}