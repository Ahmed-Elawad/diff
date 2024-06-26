/* Created by Pujitha Madmananchi 10/09/2020
 * 
 * 
 * 
 */

@isTest
public class InsightHelperTest{

    static testMethod void accountUpdateTest(){
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Contact ctct = new Contact(LastName='NewLast',AccountId=acct.Id);
        insert ctct;

        Marketing_Insights__c ins = new Marketing_Insights__c(Name__c = 'Action', Contact__c=ctct.Id, Assessment_Link__c = 'google.com');
        insert ins;
        
        Marketing_Insights__c insight = [Select Id, Account__c from Marketing_Insights__c where Contact__c!= null LIMIT 1];
        system.assert(insight.Account__c!=null);
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    }

    
    static testMethod void chatterPostLeadTest(){

        Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005');
        insert l;

        Marketing_Insights__c ins = new Marketing_Insights__c(Name__c = 'Action', Lead__c=l.Id, Assessment_Link__c = 'google.com');
        insert ins;
        
        System.assertEquals(1,ChatterMentionPost.feedItemsToPostSize);
    }
}