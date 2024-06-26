/*
 *    09/08/2021 Carrie Marciano	Commented out for Forseva uninstall
*/

@isTest
private class BCCreditReviewTest {

    static testMethod void creditReview() {
        
/*       //custom setting
        BusinessConnect__c bcSet = new BusinessConnect__c();
        bcSet.Name = 'test1';
        bcSet.Initial_Credit_Limit__c = 20000;
        bcSet.Initial_Credit_Review_Status__c = 'Auto-Approved';
        bcSet.Initial_Current_Review_Status__c = 'Requires Review';
        insert bcSet;
        
        Account acct = new Account();
        acct.Name = 'Test Account1';
        acct.Business_Type__c = 'MMS';
        insert acct;
        
        Test.startTest ();*/
        BCCreditReview cr = new BCCreditReview();
        BCCreditReviewVerify crv = new BCCreditReviewVerify();
     	//cr.startCreditPull();
     	//Test.stopTest();
        
    }
/*    
    static testMethod void verifyCreditReview() {
        
        //custom setting
        BusinessConnect__c bcSet = new BusinessConnect__c();
        bcSet.Name = 'test1';
        bcSet.Initial_Credit_Limit__c = 5000;
        bcSet.Initial_Credit_Review_Status__c = 'Auto-Approved';
        bcSet.Initial_Current_Review_Status__c = 'Requires Review';
        insert bcSet;
        
        Account acct = new Account();
        acct.Name = 'Test Account1';
        acct.Business_Type__c = 'MMS';
        insert acct;
        
        Test.startTest ();
        BCCreditReviewVerify crv = new BCCreditReviewVerify(new ApexPages.StandardController(acct));
     	crv.startCreditPull();
     	Test.stopTest();
        
    }
*/    
}