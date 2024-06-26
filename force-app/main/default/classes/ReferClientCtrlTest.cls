/*
The Refer Client functionality for CPA Program
 History
  -------
01/12/2023 Eric Porter         Created
03/27/2023 Vinay               Added more code to increase the coverage.

*/
@isTest
public with sharing class ReferClientCtrlTest {
    
    static testMethod void testSaveAsClient() {
        Test.startTest();
        ReferClientCtrl referClientController = new ReferClientCtrl();
        referClientController.FirstName='John';
        referClientController.LastName='Proctor';
        referClientController.Email='JProctor@nowhere.net';
        referClientController.Phone='222-222-2323';
        referClientController.Company='Crucible & Co.';
        referClientController.PostalCode='12603';
        Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
        Id ctctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT,ObjectHelper.OBJECT_CONTACT).getRecordTypeId();
        Account acct = new Account(RecordTypeId=acctRT,Name='test acct');
        insert acct;
        Contact ctct = new Contact(AccountId=acct.Id, RecordTypeId=ctctRT,FirstName='Test',LastName='Contact',Email='test@test.com',Phone='555-555-5555',Title='Test');
        insert ctct;
        Profile prof1 = [select id from profile where name='CPA Customer Community Login User Clone' limit 1];
        User testUser = new User(FirstName = 'Test',
                    LastName = 'UserDA223',
                    Username = 'testUserDA+223@email.com',
                    Email = 'test223@email.com',
                    Alias = 'test443',
                    CommunityNickname = 'testUserDA2222',
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'sq_AL',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    Phone = '123-456-7891',
                    Title = 'Test Title',
                    SenderEmail = 'test@email.com',
                    IsActive = true,
                    Sales_Org__c = 'PAY',
                    HR_Person_Id__c = '123456',
                    ContactId = ctct.Id,
                    ProfileId=prof1.Id);
        insert testUser;
        Referral_Account__c refAcct = new Referral_Account__c(Name='ABC Inc.', Account__c= acct.Id, Zip_Postal_Code__c='34565');
        insert refAcct;
        Referral_Contact__c refCtct1 = new Referral_Contact__c(Name = 'Severus Snape', Referral_Account__c = refAcct.Id, Contact_ID__c='2223421');
        insert refCtct1;
        PageReference myVfPage = Page.ReferClient;
        String contactId = [SELECT Contact_ID__c FROM Referral_Contact__c WHERE Id =: refCtct1.Id].Contact_ID__c;
        myVfPage.getParameters().put('ContactId', contactId);
        Test.setCurrentPage(myVfPage);
        System.runAs(testUser) {
        	referClientController.save();
        }
        PartnerReferral__c pr = [Select Id, FirstName__c,LastName__c,Email__c,Phone__c,Company__c,ZipPostalCode__c from PartnerReferral__c ];

        System.AssertEquals(pr.Company__c , referClientController.Company);  
        Test.stopTest();
    }
    
    static testMethod void testSaveAsGuest() {
        Test.startTest();
        ReferClientCtrl referClientController = new ReferClientCtrl();
        referClientController.FirstName='John';
        referClientController.LastName='Proctor';
        referClientController.Email='JProctor@nowhere.net';
        referClientController.Phone='222-222-2323';
        referClientController.Company='Crucible & Co.';
        referClientController.PostalCode='12603';

        Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
        Id ctctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT,ObjectHelper.OBJECT_CONTACT).getRecordTypeId();
        Account acct = new Account(RecordTypeId=acctRT,Name='test acct');
        insert acct;
        Contact ctct = new Contact(AccountId=acct.Id, RecordTypeId=ctctRT,FirstName='Test',LastName='Contact',Email='test@test.com',Phone='555-555-5555',Title='Test');
        insert ctct;
        Profile prof1 = [select id from profile where name='CPA Customer Community Login User Clone' limit 1];
        User testUser = new User(FirstName = 'Test',
                    LastName = 'UserDA223',
                    Username = 'testUserDA+223@email.com',
                    Email = 'test223@email.com',
                    Alias = 'test443',
                    CommunityNickname = 'testUserDA2222',
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'sq_AL',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    Phone = '123-456-7891',
                    Title = 'Test Title',
                    SenderEmail = 'test@email.com',
                    IsActive = true,
                    Sales_Org__c = 'PAY',
                    HR_Person_Id__c = '123456',
                    ContactId = ctct.Id,
                    ProfileId=prof1.Id);
        insert testUser;
        
        System.runAs(testUser) {
        	referClientController.save();
        }
        PartnerReferral__c pr = [Select Id,FirstName__c,LastName__c,Email__c,Phone__c,Company__c,ZipPostalCode__c from PartnerReferral__c ];

        System.AssertEquals(pr.Company__c , referClientController.Company);  
        Test.stopTest();
    }
    
        static testMethod void testInviteCPA() {
        Test.startTest();
        ReferClientCtrl referClientController = new ReferClientCtrl();
        referClientController.cpaInviteFirstName='John';
        referClientController.cpaInviteLastName='Proctor';
        referClientController.cpaInviteEmail='JProctor@nowhere.net';
        referClientController.cpaInvitePhone='222-222-2323';
        referClientController.cpaInviteNotes='Test Notes 123';

        Id acctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,ObjectHelper.OBJECT_ACCOUNT).getRecordTypeId();
        Id ctctRT = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT,ObjectHelper.OBJECT_CONTACT).getRecordTypeId();
        Account acct = new Account(RecordTypeId=acctRT,Name='test acct');
        insert acct;
        Referral_Account__c refAcct = new Referral_Account__c(Name='ABC Inc.', Account__c= acct.Id, Zip_Postal_Code__c='34565');
        insert refAcct;
        Referral_Contact__c refCtct1 = new Referral_Contact__c(Name = 'Severus Snape', Referral_Account__c = refAcct.Id, Contact_ID__c='2223421');
        insert refCtct1;
        
        Contact ctct = new Contact(AccountId=acct.Id, RecordTypeId=ctctRT,FirstName='Test',LastName='Contact',Email='test@test.com',Phone='555-555-5555',Title='Test', Mirror_Ref_Ctct__c = refCtct1.Id );
        insert ctct;
        Profile prof1 = [select id from profile where name='CPA Customer Community Login User Clone' limit 1];
        User testUser = new User(FirstName = 'Test',
                    LastName = 'UserDA223',
                    Username = 'testUserDA+223@email.com',
                    Email = 'test223@email.com',
                    Alias = 'test443',
                    CommunityNickname = 'testUserDA2222',
                    TimeZoneSidKey = 'America/New_York',
                    LocaleSidKey = 'sq_AL',
                    EmailEncodingKey = 'UTF-8',
                    LanguageLocaleKey = 'en_US',
                    Phone = '123-456-7891',
                    Title = 'Test Title',
                    SenderEmail = 'test@email.com',
                    IsActive = true,
                    Sales_Org__c = 'PAY',
                    HR_Person_Id__c = '123456',
                    ContactId = ctct.Id,
                    ProfileId=prof1.Id);
        insert testUser;
        PageReference myVfPage = Page.ReferClient;
        String contactId = [SELECT Contact_ID__c FROM Referral_Contact__c WHERE Id =: refCtct1.Id].Contact_ID__c;
        myVfPage.getParameters().put('ContactId', contactId);
        Test.setCurrentPage(myVfPage);
        System.runAs(testUser) {
            referClientController.handlePersonalLink();
            referClientController.inviteCPAWindow();
        	referClientController.handleInviteCPA();
           
        }
        Partner_Portal_User_Details__c pr = [SELECT Id,First_Name__c,Last_Name__c,Email__c,Phone__c,Notes__c FROM Partner_Portal_User_Details__c LIMIT 1];

        System.AssertEquals(pr.First_Name__c , referClientController.cpaInviteFirstName);  
        Test.stopTest();
    }
}