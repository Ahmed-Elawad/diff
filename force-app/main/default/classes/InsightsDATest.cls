/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code
  12/14/2023 Shilpa G			 APR0155814: Added method getIntentByContactId

 */
@IsTest
private class InsightsDATest {
    @IsTest
    static void getInsightsByContactId() {
        test.startTest();

        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contact
        Contact expectedContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false);
        insert expectedContact;

        List<Marketing_Insights__c> testInsights = new List<Marketing_Insights__c>();

        // create some open test insights for that contact
        List<Marketing_Insights__c> expectedInsights = new List<Marketing_Insights__c>();

        Marketing_Insights__c testInsight1 = new Marketing_Insights__c(Description__c = 'test 1', Name__c = 'Action', Type__c = 'Buyer Behavior', Contact__c = expectedContact.Id);
        expectedInsights.add(testInsight1);
        
        testInsights.addAll(expectedInsights);


        insert testInsights;

        List<Marketing_Insights__c> returnInsights = InsightsDA.getInsightsById(expectedContact.Id);

        test.stopTest();

        System.assert(returnInsights.size() == expectedInsights.size(), 'Should have returned expected records, it did not');
    }
    
    @IsTest
    static void getIntentByContactId() {
        test.startTest();

        // create test account
        Account testAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert testAccount;

        // create test contact
        Contact expectedContact = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', AccountId = testAccount.Id, DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false);
        insert expectedContact;

        List<Customer_Intent_Signal__c> testIntent = new List<Customer_Intent_Signal__c>();

        // create some open test insights for that contact
        List<Customer_Intent_Signal__c> expectedIntent = new List<Customer_Intent_Signal__c>();

        Customer_Intent_Signal__c testIntent1 = new Customer_Intent_Signal__c(Intent_Source__c = 'test 1', Marketing_Action__c = 'Action', Intent_Type__c = 'Buyer Behavior', Contact__c = expectedContact.Id);
        expectedIntent.add(testIntent1);
        
        testIntent.addAll(expectedIntent);


        insert testIntent;

        List<Customer_Intent_Signal__c> returnIntent = InsightsDA.getIntentById(expectedContact.Id);

        test.stopTest();

        System.assert(returnIntent.size() == expectedIntent.size(), 'Should have returned expected records, it did not');
    }
}