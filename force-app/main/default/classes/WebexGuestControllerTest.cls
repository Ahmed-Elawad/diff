/*
02/27/2023  Jermaine Stukes   Created.

*/
@isTest
public class WebexGuestControllerTest {
    @testSetup
    Static void Setup()
    {
        List<WebServiceSettings__c> webexWebServiceSettings = new List<WebServiceSettings__c>();
        WebServiceSettings__c tokenWs = new WebServiceSettings__c(
            Name = 'WebEx_Connect'
            ,IsActive__c=true
            ,Endpoint__c = 'https://webexapis.com/v1/jwt/login'
        );
        webexWebServiceSettings.add(tokenWs);
        WebServiceSettings__c personId = new WebServiceSettings__c(
            Name = 'Webex_GetPersonId'
            ,IsActive__c=true
            ,Endpoint__c = 'https://webexapis.com/v1/people/me'
        );
        webexWebServiceSettings.add(personId);
        WebServiceSettings__c createMembership = new WebServiceSettings__c(
            Name = 'Webex_CreateMembership'
            ,IsActive__c=true
            ,Endpoint__c = 'https://webexapis.com/v1/memberships'
        );
        webexWebServiceSettings.add(createMembership);
        WebServiceSettings__c createRoom = new WebServiceSettings__c(
            Name = 'Webex_CreateRoom'
            ,IsActive__c=true
            ,Endpoint__c = 'https://webexapis.com/v1/rooms'
        );
        webexWebServiceSettings.add(createRoom);
        insert webexWebServiceSettings;
        //Create Account and contacts
        CreateTestData.createTestAandC();
        //Create Lead
        CreateTestData.createTestLeadMany();
    }//Setup
    static testMethod void TestGetRecordInfo()
    {
        Contact con = [Select Id, FirstName, lastname, Email from Contact where Email = 'fLast1@abc.com'];
        sObject contactObj = WebexGuestController.getRecordInfo(con.Id);
        String contactObjectName = ObjectHelper.getObjectNameFromId(contactObj.Id);
        System.Assert(contactObjectName == 'Contact');
        Lead ld = [Select Id, FirstName, lastname, Email from Lead where Email = 'mary@account11.com'];
        sObject leadObj = WebexGuestController.getRecordInfo(ld.Id);
        String leadObjectName = ObjectHelper.getObjectNameFromId(leadObj.Id);
        System.Assert(leadObjectName == 'Lead');
        Account acct = [Select Id,Significant_Contact_Email__c,SignificantContact__c, SignificantContact__r.FirstName,SignificantContact__r.LastName from Account where name = 'Test Account1'];
        sObject acctObj = WebexGuestController.getRecordInfo(acct.Id);
        String acctObjectName = ObjectHelper.getObjectNameFromId(acctObj.Id);
        System.Assert(acctObjectName == 'Account');
    }
    static testMethod void TestInitiateWebexFromContactS()
    {
        User testUser = WebexGuestController.getCurrentUserInfo();
        //Test.setMock(HttpCalloutMock.class, new WebexGuestControllerMock());
        Contact con = [Select Id, FirstName, lastname, Email from Contact where Email = 'fLast1@abc.com'];
        Boolean initiateWebex = WebexGuestController.initiateWidget(testUser,con.FirstName, con.FirstName, con.Email,'Test Title', con.Id);
        Event testEvent = [Select Id, Activity__c, Type from Event where WhoId=:con.Id];
        System.assert(testEvent!=null);
        System.assert(testEvent.Activity__c == 'Instant Webex Presentation');

    }
    static testMethod void TestInitiateWebexFromLeadS()
    {
        User testUser = WebexGuestController.getCurrentUserInfo();
        Lead ld = [Select Id, FirstName, lastname, Email from Lead where Email = 'mary@account11.com'];
        Boolean initiateWebex = WebexGuestController.initiateWidget(testUser,ld.FirstName, ld.FirstName, ld.Email,'Test Title', ld.Id);
        Event testEvent = [Select Id, Activity__c, Type from Event where WhoId=:ld.Id];
        System.assert(testEvent!=null);
        System.assert(testEvent.Activity__c == 'Instant Webex Presentation');
    }
    static testMethod void TestInitiateWebexFromAccountS()
    {
        User testUser = WebexGuestController.getCurrentUserInfo();
        Account acct = [Select Id,Significant_Contact_Email__c,SignificantContact__c, SignificantContact__r.FirstName,SignificantContact__r.LastName from Account where name = 'Test Account1'];
        Boolean initiateWebex = WebexGuestController.initiateWidget(testUser,'Jermaine', 'Stukes', 'test@test.com','Test Title', acct.Id);
        Event testEvent = [Select Id, Activity__c, Type from Event where WhatId=:acct.Id];
        System.assert(testEvent!=null);
        System.assert(testEvent.Activity__c == 'Instant Webex Presentation');
    }
}