/* 
*Test methods for the FlexOnlineAccountRequestController
*
* History
* -------
  06/18/2019 Michael Karcz    Created
  12/08/2022 Dan Carmen       Modified to use SF Duplicate Management
  04/17/2023 Dan Carmen       Add additional logging

*/

@isTest
public class FlexOnlineAccountRequestControllerTest {
	
    @testSetup
    public static void setupTests() {
        // Set up webservice setting
        //if(String.isBlank(Utilities.checkForProduction())) {
            WebServiceSettings__c ws1 = new WebServiceSettings__c(Name='FlexCPAExternal',IsActive__c=true,Certificate__c=null, //'SFDCUserProd4096',
                                         Endpoint__c='https://webservices.paychex.com/soap/corporate/1_0/SSOUserRegistration',
                                         Timeout__c='40000');
            WebServiceSettings__c ws2 = new WebServiceSettings__c(Name='FlexCPAN1',IsActive__c=true,Certificate__c=null, //'SFDCUserProd4096',
                                         Endpoint__c='https://webservicesimp.paychex.com/soap/corporate/1_0/SSOUserRegistration',
                                         Timeout__c='40000');
            WebServiceSettings__c[] wsArray = new WebServiceSettings__c[]{ws1, ws2};
                insert wsArray;
        /*
        }
        else{
    		WebServiceSettings__c ws1 = new WebServiceSettings__c(Name='FlexCPAExternal',IsActive__c=true,Certificate__c='SFDC_fullsandbx',
                                         Endpoint__c='https://webservices.paychex.com/soap/corporate/1_0/SSOUserRegistration',
                                         Timeout__c='40000');
            WebServiceSettings__c ws2 = new WebServiceSettings__c(Name='FlexCPAN1',IsActive__c=true,Certificate__c='SFDC_fullsandbx',
                                         Endpoint__c='https://webservicesimp.paychex.com/soap/corporate/1_0/SSOUserRegistration',
                                         Timeout__c='40000');
            WebServiceSettings__c[] wsArray = new WebServiceSettings__c[]{ws1, ws2};
                insert wsArray;
        }
        */
		Referral_Account__c acct1 = new Referral_Account__c(Name = 'Test Account 1', Zip_Postal_Code__c = '14464');
        Referral_Account__c acct2 = new Referral_Account__c(Name = 'Test Account 2', Zip_Postal_Code__c = '14602');
        ReferralObjectsSync.SKIP_SYNC=false;
        insert new Referral_Account__c[]{acct1, acct2};
        
        Referral_Contact__c con1 = new Referral_Contact__c(Referral_Account__c=acct1.Id, Name='John Tester', First_Name__c='John', Last_Name__c='Tester', Phone__c='5583923832'
                                                            , Email__c='testEmail2813@gmai1.com', PrimaryReferralType__c='CPA');
        Referral_Contact__c con2 = new Referral_Contact__c(Referral_Account__c=acct2.Id, Name='Sarah Smith', First_Name__c='Sarah', Last_Name__c='Smith', Phone__c='8839283874'
                                                            , Email__c='testEmail8329@gmai1.com');
        insert new Referral_Contact__c[]{con1, con2};
        
        Zip_Code_Information__c zci1 = new Zip_Code_Information__c(Name = '14464', City__c = 'Hamlin', State__c = 'NY');
        Zip_Code_Information__c zci2 = new Zip_Code_Information__c(Name = '14602', City__c = 'Rochester', State__c = 'NY');
        Zip_Code_Information__c[] zcis = new Zip_Code_Information__c[]{zci1, zci2};
        insert zcis;
    } // setupTests
    
    
    public static testMethod void testInternalSuccess() {
        FlexOnlineAccountRequestController.performUsernameCallout = false;
        Referral_Contact__c rCon = [SELECT Id FROM Referral_Contact__c WHERE Name = 'John Tester'];
        
        FlexOnlineAccountRequestControllerMock mockCallout = new FlexOnlineAccountRequestControllerMock();
        mockCallout.bodyToUse = FlexOnlineAccountRequestControllerMock.body2;
        Test.setMock(HttpCalloutMock.class, mockCallout);

        
        PageReference pageRef = Page.FlexOnlineAccountRequest;
        pageRef.getParameters().put('id', String.valueof(rCon.Id));
        pageRef.getParameters().put('access', 'FlexCPAN1');
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        testCPA.dob = Date.newInstance(1982, 5, 24); // Set dob for tests
        testCPA.newUsername = 'testUser33228'; // Set new username for tests

        testCPA.validateAndCheckDupes();
        
        Test.StartTest();
        testCPA.createShellAccount();
        Test.StopTest();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testInternalSuccess() - pageMessages: ' + pageMessages);
        ApexPages.Message message = pageMessages[0];
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testInternalSuccess() - message: ' + message);
        System.assert(message.getSummary() == 'Your submission has been submitted successfully.');
        
    } // testInternalSuccess
    
    
    public static testMethod void testExternalSuccess() {
        FlexOnlineAccountRequestController.performUsernameCallout = false;
        
        FlexOnlineAccountRequestControllerMock mockCallout = new FlexOnlineAccountRequestControllerMock();
        mockCallout.bodyToUse = FlexOnlineAccountRequestControllerMock.body2;
        Test.setMock(HttpCalloutMock.class, mockCallout);

        PageReference pageRef = Page.FlexOnlineAccountRequest;
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        testCPA.firmName = 'Test Firm 78';
    	testCPA.zipCode = '14464';
    	testCPA.contactFirstName = 'Kevin';
    	testCPA.contactLastName = 'Smith';
    	testCPA.phone = '4483928345';
        testCPA.email = 'testEmail2819@gmai1.com';
        testCPA.dob = Date.newInstance(1982, 5, 24); // Set dob for tests
        testCPA.newUsername = 'testUser33228'; // Set new username for tests
        
        testCPA.validateAndCheckDupes();
        Test.StartTest();
        testCPA.createShellAccount();
        Test.StopTest();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testExternalSuccess() - pageMessages: ' + pageMessages);
        ApexPages.Message message = pageMessages[0];
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testExternalSuccess() - message: ' + message);
        System.assert(message.getSummary() == 'Your submission has been submitted successfully.');
        
    } // testExternalSuccess
    
    
    public static testMethod void testValidationError() {
        FlexOnlineAccountRequestController.performUsernameCallout = false;
        Referral_Contact__c rCon = [SELECT Id FROM Referral_Contact__c WHERE Name = 'John Tester'];
        
        rCon.Email__c = 'testEmail228@gmai1.c';
        update rCon;
        
        Test.StartTest();
        
        PageReference pageRef = Page.FlexOnlineAccountRequest;
        pageRef.getParameters().put('id', String.valueof(rCon.Id));
        pageRef.getParameters().put('access', 'FlexCPAN1');
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        testCPA.dob = Date.newInstance(1982, 5, 24); // Set dob for tests
        testCPA.newUsername = 'testUser33228'; // Set new username for tests
        
        testCPA.validateAndCheckDupes();
        testCPA.createShellAccount();
        
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testError() - pageMessages: ' + pageMessages);
        ApexPages.Message message = pageMessages[0];
        System.debug('MAK - FlexOnlineAccountRequestControllerTest - testError() - message: ' + message);
        System.assert(message.getSummary() == 'An e-mail address must be in the format x@y.zz where x is one or more characters, y is one or more characters, and zz is two or more characters.');
        
        Test.StopTest();
    } // testValidationError
    
    public static testMethod void testUniqueUsernameSuccess() {
        FlexOnlineAccountRequestController.performUsernameCallout = true;
        FlexOnlineAccountRequestController foarc = new FlexOnlineAccountRequestController();
        foarc.newUsername = null;
        System.assertEquals('Please provide a new Flex username', foarc.isUsernameUnique());
        
        test.startTest();
        FlexOnlineAccountRequestControllerMock mockCallout = new FlexOnlineAccountRequestControllerMock();
        mockCallout.bodyToUse = FlexOnlineAccountRequestControllerMock.body1a;
        Test.setMock(HttpCalloutMock.class, mockCallout);
        foarc.newUsername = 'testUsername';
        System.assertEquals('',foarc.isUsernameUnique());
        System.assertEquals(true,foarc.isUsernameUnique);
        Test.stopTest();

    } // testUniqueUsernameSuccess
    
    public static testMethod void testUniqueUsernameFailure() {
        FlexOnlineAccountRequestController.performUsernameCallout = true;
        FlexOnlineAccountRequestController foarc = new FlexOnlineAccountRequestController();
        
        test.startTest();
        FlexOnlineAccountRequestControllerMock mockCallout = new FlexOnlineAccountRequestControllerMock();
        mockCallout.bodyToUse = FlexOnlineAccountRequestControllerMock.body1b;
        Test.setMock(HttpCalloutMock.class, mockCallout);
        foarc.newUsername = 'testUsername';
        String userResult = foarc.isUsernameUnique();
        System.assertEquals(true,userResult.contains('You are attempting to create a Username that already exists'));
        System.assertEquals(false,foarc.isUsernameUnique);
        System.assertEquals(false,foarc.uniqueCheckError);
        Test.stopTest();

    } // testUniqueUsernameSuccess

    public static testMethod void testDupeBlockers() {
        Referral_Contact__c rCon = [SELECT Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Referral_Account__c FROM Referral_Contact__c WHERE Name = 'John Tester'];
        Referral_Account__c rAcc = [SELECT Id, Name, Zip_Postal_Code__c FROM Referral_Account__c WHERE Id = :rCon.Referral_Account__c];
        Test.StartTest();
        
        //PageReference pageRef = Page.FlexOnlineAccountRequest;
        //pageRef.getParameters().put('id', String.valueof(rCon.Id));
        //pageRef.getParameters().put('access', 'FlexCPAN1');
        //Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        
        Id dupeRAccount = testCPA.dupeBlockerRAccountCheck(rAcc.Name, rAcc.Zip_Postal_Code__c);
        Id dupeRContact = testCPA.dupeBlockerRContactCheck(rCon.First_Name__c, rCon.Last_Name__c, rCon.Email__c, rCon.Referral_Account__c);
        
        System.assertEquals(dupeRAccount, rAcc.Id); // 
        System.assertEquals(dupeRContact, rCon.Id); // 
        
        Test.StopTest();
    }// testDupeBlockers
    
    
    public static testMethod void testCreateACase() {
        Referral_Contact__c rCon = [SELECT Id, Name, Phone__c, Email__c, Referral_Account__c FROM Referral_Contact__c WHERE Name = 'John Tester'];
        Test.StartTest();
        
        PageReference pageRef = Page.FlexOnlineAccountRequest;
        pageRef.getParameters().put('id', String.valueof(rCon.Id));
        pageRef.getParameters().put('access', 'FlexCPAN1');
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        
        testCPA.createACase();
        
        Case c = [SELECT Id FROM Case WHERE Referral_Contact__c = :rCon.Id LIMIT 1];
        System.assert(c != null);
        
        Test.StopTest();
    }// testCreateACase
    
    public static testMethod void testReuseRefCtct() {
        FlexOnlineAccountRequestController.performUsernameCallout = false;
        Referral_Contact__c rCon = [SELECT Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Referral_Account__c FROM Referral_Contact__c WHERE Name = 'John Tester'];
        Referral_Account__c rAcc = [SELECT Id, Name, Zip_Postal_Code__c FROM Referral_Account__c WHERE Id = :rCon.Referral_Account__c];
        
        PageReference pageRef = Page.FlexOnlineAccountRequest;
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        
        testCPA.dupRContact = rCon;
        testCPA.dupRAccount = rAcc;
        testCPA.useRAcctRCon();
        
        System.assertEquals(rCon.Id, testCPA.rContact.Id);
        System.assertEquals(rAcc.Id, testCPA.rAccount.Id);
        
    } // testReuseRefCtct
    
    public static testMethod void testReuseRefAcct() {
        FlexOnlineAccountRequestController.performUsernameCallout = false;
        Referral_Contact__c rCon = [SELECT Id, Name, First_Name__c, Last_Name__c, Phone__c, Email__c, Referral_Account__c FROM Referral_Contact__c WHERE Name = 'John Tester'];
        Referral_Account__c rAcc = [SELECT Id, Name, Zip_Postal_Code__c FROM Referral_Account__c WHERE Id = :rCon.Referral_Account__c];
        
        PageReference pageRef = Page.FlexOnlineAccountRequest;
        Test.setCurrentPage(pageRef);
        
        FlexOnlineAccountRequestController testCPA = new FlexOnlineAccountRequestController();
        //testCPA.firmName = 'Test Firm 78';
    	//testCPA.zipCode = '14464';
    	testCPA.contactFirstName = 'Kevin';
    	testCPA.contactLastName = 'Smith';
    	testCPA.phone = '4483928345';
        testCPA.email = 'testEmail2819@gmai1.com';
        testCPA.dob = Date.newInstance(1982, 5, 24); // Set dob for tests
        testCPA.newUsername = 'testUser33228'; // Set new username for tests
        
        testCPA.dupRAccount = rAcc;
        testCPA.useRAccount();
        
        System.assertNotEquals(null,testCPA.rContact.Id);
        System.assertNotEquals(rCon.Id, testCPA.rContact.Id);
        System.assertEquals(rAcc.Id, testCPA.rAccount.Id);

    } // testReuseRefAcct
     
} // class FlexOnlineAccountRequestControllerTest