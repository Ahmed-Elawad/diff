@isTest
private class FARequestFormAuraControllerTest {
   static testMethod void testBasics() {
       createTestData();
       
       
       Test.StartTest();
       Financial_Advisor_Request_Form__c FA = [Select Id, Case__c,Advisor_Type__c,FA_First_Name__c,FA_Last_Name__c,FA_Address__c,
                   FA_City__c,FA_State__c,FA_Zipcode__c,FA_Email__c,FA_Phone_Number__c,CRD_Number__c,Broker_Branch_ID__c,
                   Broker_Dealer_CRD__c, Broker_Dealer_Firm_Name__c,Compensation_Type__c,Parent_Broker_Dealer_Firm__c, Notes__c,Broker_Rep_ID__c from Financial_Advisor_Request_Form__c];
       Id caseid = FARequestFormAuraController.createCase(fa);
       //System.assertEquals(fa.Case__c,caseId);
       Test.StopTest();
   }
   
   private static void createTestData() {
        Account acct1 = new Account (name = 'Test Account1'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000');
        insert acct1;
        Contact con1 = new Contact(Firstname = 'Bill'
                                ,Lastname = 'Contact1'
                                ,Phone = '555-1212'
                                ,Email='bmadhavi@paychex.com'
                                ,AccountId=acct1.Id
                                ,Sales_Contact__c = true);
        insert con1;
        
        Account acct2 = new Account (name = 'Test Account2'
                                ,type = 'MMS Client'
                                ,BillingStreet = '10 Main Street'
                                ,BillingCity = 'Rochester'
                                ,BillingState = 'NY'
                                ,BillingPostalCode = '10000'
                                ,Bis_Id__c = 1234);
        insert acct2;
                
        Contact con2 = new Contact(Firstname = 'Mary'
                                ,Lastname = 'Contact2'
                                ,Phone = '555-1212'
                                ,Email = 'mary@account2.com'
                                ,AccountId=acct2.Id
                                ,Sales_Contact__c = true);
        insert con2;
        
        Financial_Advisor_Request_Form__c obj = new Financial_Advisor_Request_Form__c();
        obj.Advisor_Type__c = 'Broker Dealer';
        obj.Broker_Branch_ID__c = 'Test';
        obj.Broker_Dealer_CRD__c = 'Test';
        obj.Broker_Dealer_Firm_Name__c = 'Test';
        obj.Broker_Rep_ID__c = 'Test';
        obj.Compensation_Type__c = 'Commission';
        obj.CRD_Number__c = 'Test';
        obj.FA_Address__c= 'Test';
        obj.FA_City__c= 'Test';
        obj.FA_Email__c = 'Test@test.com';
        obj.FA_First_Name__c = 'Test';
        obj.FA_Last_Name__c = 'Test';
        obj.FA_Phone_Number__c = 'Test';
        obj.FA_State__c = 'Alabama - AL';
        obj.FA_Zipcode__c = '1234567890';
        obj.Notes__c = 'Test';
        obj.Parent_Broker_Dealer_Firm__c = 'Test';
        
        insert obj;
   } 
}