@isTest
private class ContactProfiledExpirationTest 
{
    static testMethod void testExpiration() {
        Contact Con1 = new Contact(LastName='Test', FirstName='Con1', Profiled__c = true, Email='test@test.com', Phone='555-555-5555', Title='Test', Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Contact Con2 = new Contact(LastName='Test', FirstName='Con2', Profiled__c = true, Email='test@test.com', Phone='555-555-5555', Title='Test', Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Contact Con3 = new Contact(LastName='Test', FirstName='Con3', Profiled__c = true, Email='test@test.com', Phone='555-555-5555', Title='Test', Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Contact Con4 = new Contact(LastName='Test', FirstName='Con4', Profiled__c = true, Email='test@test.com', Phone='555-555-5555', Title='Test', Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Contact Con5 = new Contact(LastName='Test', FirstName='Con5', Profiled__c = true, Email='test@test.com', Phone='555-555-5555', Title='Test', Profiled_Date__c = system.today().addDays(-1), Profiled_Expiration_Date__c = system.today());
        Contact[] Cons = new Contact[]{Con1,Con2,Con3,Con4,Con5};
            insert Cons;
        
        ContactProfiledExpiration ape = new ContactProfiledExpiration();
        Test.startTest();
        Database.executeBatch(ape,5);
        Test.stopTest();
        
        for(Contact c1:[SELECT Id,Profiled__c,Profiled_Date__c,Profiled_Expiration_Date__c FROM Contact WHERE Id in:Cons]){
            system.assertEquals(false,c1.Profiled__c);
            system.assertEquals(null,c1.Profiled_Date__c);
            system.assertEquals(null,c1.Profiled_Expiration_Date__c);
        }
    }
}