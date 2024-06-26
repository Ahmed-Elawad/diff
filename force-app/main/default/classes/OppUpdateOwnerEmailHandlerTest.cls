/*
01/22/2023  Jermaine Stukes   Created.

*/

@isTest
public class OppUpdateOwnerEmailHandlerTest {
    @testSetup
    Static void Setup()
    {
        //Create Account and contacts
        CreateTestData.createTestAandC();
        Account acct1 = [Select Id, Name
                         ,(Select Id from Contacts)
                         from Account where Name='Test Account1' limit 1];
        Id ctctId = acct1.Contacts[0].Id;
        CreateTestData.createTestCoreOptys(acct1.Id, ctctId);
    }//Setup

    static testMethod void TestinBoundEmailSuccess()
    {
        User inactiveUser = [SELECT Id FROM User WHERE IsActive=False AND Profile.name='System Administrator' LIMIT 1];
        Opportunity testOpp =  [Select Id, OwnerId from Opportunity where Name='Test Core Opporty' limit 1];
        testOpp.Inactive_User_Id__c=inactiveUser.Id;
        test.startTest();
        update testOpp;
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'Update Opp Owner to Inactive Users';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = 'Opportunity Ids:'+testOpp.Id+'endOfList';
        
        OppUpdateOwnerEmailHandler emailHandler = new OppUpdateOwnerEmailHandler();
        emailHandler.handleInboundEmail(email, env);
        test.stopTest();
        Opportunity testOpp2 =  [Select Id, OwnerId, Inactive_User_Id__c from Opportunity where Name='Test Core Opporty' limit 1];
        System.assertEquals(inactiveUser.Id, testOpp2.OwnerId);
        System.assertEquals(null, testOpp2.Inactive_User_Id__c);      
    }
    static testMethod void TestinBoundEmailFail()
    {
        String badUserId = '000000000000000000';
        Opportunity testOpp =  [Select Id, OwnerId from Opportunity where Name='Test Core Opporty' limit 1];
        testOpp.Inactive_User_Id__c=badUserId;
        update testOpp;
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'Update Opp Owner to Inactive Users';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = 'Opportunity Ids:'+testOpp.Id+'endOfList';
        test.startTest();
        OppUpdateOwnerEmailHandler emailHandler = new OppUpdateOwnerEmailHandler();
        emailHandler.handleInboundEmail(email, env);
        test.stopTest();
        Opportunity testOpp2 =  [Select Id, OwnerId, Inactive_User_Id__c from Opportunity where Name='Test Core Opporty' limit 1];
        System.assertNotEquals(badUserId, testOpp2.OwnerId);
        System.assertEquals(null, testOpp2.Inactive_User_Id__c);      
    }
        static testMethod void TestinBoundEmailSuccessWithSignature()
    {
        User inactiveUser = [SELECT Id FROM User WHERE IsActive=False AND Profile.name='System Administrator' LIMIT 1];
        Opportunity testOpp =  [Select Id, OwnerId from Opportunity where Name='Test Core Opporty' limit 1];
        testOpp.Inactive_User_Id__c=inactiveUser.Id;
        test.startTest();
        update testOpp;
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        // setup the data for the email
        email.subject = 'Update Opp Owner to Inactive Users';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = 'Opportunity Ids:'+testOpp.Id+'endOfList Add a fake signature';
        
        OppUpdateOwnerEmailHandler emailHandler = new OppUpdateOwnerEmailHandler();
        emailHandler.handleInboundEmail(email, env);
        test.stopTest();
        Opportunity testOpp2 =  [Select Id, OwnerId, Inactive_User_Id__c from Opportunity where Name='Test Core Opporty' limit 1];
        System.assertEquals(inactiveUser.Id, testOpp2.OwnerId);
        System.assertEquals(null, testOpp2.Inactive_User_Id__c);      
    }
}