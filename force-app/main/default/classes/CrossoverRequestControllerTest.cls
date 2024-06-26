/* 
*Test methods for the CrossoverRequestController.
*
* History
* -------
* 10/29/2009 Dan Carmen   Created
08/21/2012 Dan Carmen   Change for Direct Sales to receive crossover requests.
11/12/2012 Dan Carmen   Remove logic for Operations Owner - user was disabled.
08/29/2013 Dan Carmen   Fix for asking for DSA, clean up code
02/01/2015 Jacob Hinds  Added in selection based on Owner field in custom setting.
06/28/2018 Carrie Marciano Added in testPEOCRequest method
06/12/2019 Jacob Hinds  changes to PEO method
09/03/2019 Dan Carmen        Fix query to select core sales reps
10/18/2019 Matt Fritschi	Added tests for crossovers from 401k and Payroll Bank Referral Lead Conversions. 
05/13/2020 Dan Carmen           Changes to PEO Owner to be its own field.
07/29/2020 Jermaine Stukes	Update TestNonRepOwns Test
05/06/2021 Dan Carmen           Pull out the query to a different method so it's only in code once.
04/11/2022 Dan Carmen           Add Zip segmentation fields in query
05/02/2023 Dan Carmen           Adjust testNoOwner test for dsm instead of dsa

*/
@isTest
private class CrossoverRequestControllerTest {
    
    @testSetup static void createSetting() {
        SalesOrg__c coreSetting = new SalesOrg__c(Name='PAY',Description__c='Core',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OwnerId');
        SalesOrg__c mmsSetting = new SalesOrg__c(Name='MMS',Description__c='MMS',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OwnerId');
        SalesOrg__c hrsSetting = new SalesOrg__c(Name='HRS',Description__c='401k/FSA',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='HRS_Account_Owner__c,Large Market 401(k) Partner');
        SalesOrg__c hnbfSetting = new SalesOrg__c(Name='HNBF',Description__c='Health & Benefits',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='HNBF_Account_Owner__c');
        SalesOrg__c pasSetting = new SalesOrg__c(Name='PAS',Description__c='HR Solutions',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='Premier_PBS_Account_Owner__c');
        SalesOrg__c peoSetting = new SalesOrg__c(Name='PEO',Description__c='PEO',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OasisPEOAccountOwner__c');
        
        List<SalesOrg__c> sos = new List<SalesOrg__c>();
        sos.add(coreSetting);
        sos.add(mmsSetting);
        sos.add(hrsSetting);
        sos.add(hnbfSetting);
        sos.add(pasSetting);
        sos.add(peoSetting);
        insert sos; 
    }
    
    
    private static Account getAccount(Id ownerId, Id hrsOwnerId, Id pasOwnerId, Id hnbOwnerId, Id lrgMarketId, Id peoOwnerId, String rtName, Boolean useShip, Boolean useBill, Boolean usePhone) {
        RecordType rt = [select id, name from RecordType where name=:rtName];
        Account testAcct = new Account(Name='testMethod Acct'
                                       ,AccountNumber='17-TEST'
                                       ,OwnerId=ownerId
                                       ,HRS_Account_Owner__c=hrsOwnerId
                                       ,Premier_PBS_Account_Owner__c=pasOwnerId
                                       ,HNBF_Account_Owner__c=hnbOwnerId
                                       ,OasisPEOAccountOwner__c=peoOwnerId
                                       ,RecordTypeId=rt.Id
                                       ,NumberOfEmployees=12
                                       ,Phone=(usePhone ? '(585) 123-4567' : null)
                                       ,Type='Core Client'
                                       ,BillingStreet=(useBill ? '123 Bill St' : null)
                                       ,BillingCity=(useBill ? 'Bill City' : null)
                                       ,BillingState=(useBill ? 'NY' : null)
                                       ,BillingPostalCode=(useBill ? '14624' : null)
                                       ,ShippingStreet=(useShip ? '123 Ship St' : null)
                                       ,ShippingCity=(useShip ? 'Ship City' : null)
                                       ,ShippingState=(useShip ? 'NY' : null)
                                       ,ShippingPostalCode=(useShip ? '14624' : null)
                                       ,Time_Zone__c='EST'
                                       ,Frequency__c='Weekly'
                                       ,Current_Prior_Method__c='Intuit'
                                      );
        insert testAcct;
        
        if(lrgMarketId!=null){
            AccountTeamMember atm = new AccountTeamMember(AccountId=testAcct.Id, UserId=lrgMarketId, TeamMemberRole='Large Market 401(k) Partner' );
            insert atm;
        }
        
        
        
        return testAcct;
    } // getAccount
    
    // Test proper steps - everything correct.
    static testMethod void testCrossoverRequest() {
        // get Core users
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id limit 1];
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,false);
        
        // for different address configurations
        Account testAcct2 = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,false);
        testAcct2.ShippingCity = null;
        update testAcct2;
        
        
        Account testAcct3 = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,false);
        testAcct3.ShippingCity = null;
        testAcct3.ShippingState = null;
        update testAcct3;
        System.runAs(u2) {
            
            Test.startTest();
            System.debug('if no account is passed in, nothing should happen.');
            CrossoverRequestController crc = new CrossoverRequestController(new ApexPages.StandardController(new Account()));
            // no account, should be finished
            System.assertEquals(true,crc.finished);
            // no account was set
            System.assertEquals(false,crc.hasAcct);

            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            
            System.assertEquals(u2.Id,crc.crossoverUser.Id);
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals('Return to Prospect-Client',crc.getReturnButtonTitle());
            System.assertEquals(false,crc.cannotComplete);
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
            // test for different address configurations
            sc1 = New ApexPages.StandardController(testAcct2);
            ApexPages.currentPage().getParameters().put('id', testAcct2.Id);
            crc = new CrossoverRequestController(sc1);
            request = crc.request;
            request.Comments__c = 'test comments';
            nextPage = crc.saveRequest().getUrl();
            
            sc1 = New ApexPages.StandardController(testAcct3);
            ApexPages.currentPage().getParameters().put('id', testAcct3.Id);
            crc = new CrossoverRequestController(sc1);
            request = crc.request;
            request.Comments__c = 'test comments';
            nextPage = crc.saveRequest().getUrl();
            
            Test.stopTest();
        } // System.runAs
    } // class testCrossoverRequest
    
    // Test no account passed in.
    static testmethod void testNoAcct() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        System.runAs(u1) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // Shouldn't do anything else - no account is passed in.
            System.assertEquals(true,crc.finished);
            // should be an error message.
            System.assertEquals(true,ApexPages.hasMessages());
            
        } // System.runAs
        
    } // testSameRep
    
    // Test where the same rep that created the account is requesting the crossover.
    static testmethod void testSameRep() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        System.runAs(u1) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // Shouldn't do anything else - already owner by the current user.
            System.assertEquals(crc.finished,true);
            // test the transfer flag
            System.assertEquals(crc.isTransfer,false);
            
        } // System.runAs
        
    } // testSameRep
    
    /** Test where Operations Owner owns the account - should automatically transfer.
*/
    /*
static testmethod void testOperationsOwner() {
// get the operations owner
User u1 = [select Id from User where Name='Operations Owner' and isActive=true and Id != :UserInfo.getUserId() limit 1];
User u2 = [select Id from User where Profile.Name=:Utilities.PROF_CORE_SALES and isActive=true and Sales_Org__c='PAY' and Id != :u1.Id limit 1];

Account testAcct = getAccount(u1.Id,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);

System.runAs(u2) {
ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
ApexPages.currentPage().getParameters().put('id', testAcct.Id);
CrossoverRequestController crc = new CrossoverRequestController(sc1);
// Shouldn't do anything else - already owner by the current user.
System.assertEquals(crc.finished,true);
// test the transfer flag
System.assertEquals(crc.isTransfer,true);

// test the text of the return button
System.assertEquals(crc.getReturnButtonTitle(),'Transfer Ownership and Return to Prospect-Client');

String nextPage = crc.returnToAcct().getUrl();
System.assertEquals('/'+testAcct.Id,nextPage);
} // System.runAs

} // testOperationsOwner
*/
    
    // Test where Operations Owner owns the account - should automatically transfer.
    static testmethod void testNonRepOwns() {
        // get a non-rep user
        User u1 = [select Id from User where UserType = 'Standard' AND Job_Name__c=null and isActive=true and Id != :UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id and Id != :UserInfo.getUserId() limit 1];
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        
        System.runAs(u2) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            System.assertEquals(crc.finished,false);
            // test the transfer flag
            System.assertEquals(crc.isTransfer,false);
            System.assertEquals(crc.crossoverOkay,false);
            crc.request.Comments__c='Test Comment';
            
            crc.saveRequest().getUrl();
            System.assertEquals(crc.cannotComplete,true);
            
            crc.request.Send_Request_To__c = null;
            String nextPage = crc.saveDsaRequest().getUrl();
            // no user was entered, cannot proceed.
            System.assertEquals(nextPage,Page.CrossoverRequest.getUrl());
            
            // test trying to send request to self.
            crc.request.Send_Request_To__c=UserInfo.getUserId();
            nextPage = crc.saveDsaRequest().getUrl();
            // same user entered, cannot proceed. 
            System.assertEquals(nextPage,Page.CrossoverRequest.getUrl());
            
            // test setting an inactive user
            System.debug('USER 3: ');
            User u3 = [Select Id from User where Profile.Name like 'Core Sales Administration%' and isActive=false and Id != :UserInfo.getUserId() and Id != :u1.Id limit 1];     
            crc.request.Send_Request_To__c=u3.Id;
            nextPage = crc.saveDsaRequest().getUrl();
            System.assertEquals(nextPage,Page.CrossoverRequest.getUrl());
            
            // test setting an active user with the wrong profile type
            System.debug('USER 4: ');
            User u4 = [select Id, ProfileId,Profile.Name from User where Profile.Name like :Utilities.PROF_CORE_SALES_SB+'%' and isActive=true and Id != :UserInfo.getUserId() and Id != :u1.Id and Id != :u3.Id limit 1];
            System.debug('Check Profile: '+Utilities.checkDsaZsaProfName(u4.Profile.Name));
            System.debug('PROFILE NAME: '+u4.Profile.Name);
            crc.request.Send_Request_To__c=u4.Id;
            nextPage = crc.saveDsaRequest().getUrl();
            System.assertEquals(nextPage,Page.CrossoverRequest.getUrl());
            
            // test setting an active user with the correct profile type
            User u5 = [select Id from User where (Profile.Name=:Utilities.PROF_CORE_SALES_ADMIN OR Profile.Name = :Utilities.PROF_CORE_SALES_ADMIN_SB) and isActive=true and Id != :UserInfo.getUserId() and Id != :u1.Id and Id != :u3.Id and Id != :u4.Id limit 1];
            crc.request.Send_Request_To__c=u5.Id;
            nextPage = crc.saveDsaRequest().getUrl();
            // correct - proceed
            System.assertEquals('/'+testAcct.Id,nextPage);
            
        } // System.runAs
    } // testNonRepOwns
    
    // Test where an inactive user owns the account.
    static testmethod void testInactiveRepOwns() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=false and Id != :UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        
        System.runAs(u2) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // The rep is inactive, so the crossover will not be okay.
            System.assertEquals(crc.crossoverOkay,false);
            // test the transfer flag
            System.assertEquals(crc.isTransfer,false);
            crc.request.Comments__c='Test Comment';
            crc.saveRequest();
            // test the text of the return button
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            String nextPage = crc.returnToAcct().getUrl();
            System.assertEquals('/'+testAcct.Id,nextPage);
        } // System.runAs
    } // testNonRepOwns
    
    // Test if there's activity
    static testmethod void testActivity() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true and Id!=:UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,false,true);
        datetime date1 = (System.now());
        date activityDate = Date.newInstance(date1.year(),date1.month(),date1.day());
        
        Event e1 = new Event(OwnerId=u1.Id, Subject='TEST1', Type='TEST1', WhatId=testAcct.Id, ActivityDate=activityDate, DurationInMinutes=60, ActivityDateTime=date1);
        Task t1 = new Task(OwnerId=u1.Id, Subject='TEST1', Type='TEST1', WhatId=testAcct.Id, ActivityDate=activityDate);
        insert e1;
        insert t1;
        
        //e1 = [Select Id, AccountId from Event where Id = :e1.Id];
        //System.assertEquals(e1.AccountId, testAcct.Id);
        
        System.runAs(u2) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // Activity 
            System.assertEquals(false,crc.finished);
            // test the transfer flag
            System.assertEquals(false,crc.isTransfer);
            
            // test that it found activity
            System.assertEquals(true,crc.hasActivity);
        } // System.runAs
    } // testNonRepOwns
    
    // Test proper steps - everything correct. MMS Account
    static testMethod void testMMSRequest() {
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE  and Id != :u1.Id limit 1];
        System.runAs(u2) {
            System.debug('if no account is passed in, nothing should happen.');
            CrossoverRequestController crc = new CrossoverRequestController(new ApexPages.StandardController(new Account()));
            // no account, should be finished
            System.assertEquals(true,crc.finished);
            // no account was set
            System.assertEquals(false,crc.hasAcct);
            
            // get a default Core user
            
            Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.MMS_ACCOUNT,false,true,false);
            
            
            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
        } // System.runAs
    } // class testMMSRequest
    
    // Test proper steps - everything correct. HRS rep
    static testMethod void testHRSRequest() {
        
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User uHRS1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
        User uHRS2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_401 and Id != :uHRS1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,uHRS1.Id,null,null,null,null,AccountHelper.CORE_ACCOUNT,false,true,false);
        
        System.runAs(uHRS2) {
            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            
            crc.selectedRecipient = 'HRS_Account_Owner__c';  
            crc.setRecipient();       
            System.assertEquals(testAcct.get(crc.selectedRecipient),crc.acctOwner.Id);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
        } // System.runAs
    } // class testHRSRequest
    
    static testMethod void testLargeMarketRequest() {
        
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User uHRS1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
        User uHRS2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_401 and Id != :uHRS1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,uHRS1.Id,null,AccountHelper.CORE_ACCOUNT,false,true,false);
        
        List<AccountTeamMember> atm = [SELECT UserId FROM AccountTeamMember WHERE TeamMemberRole = 'Large Market 401(k) Partner' AND AccountId = :testAcct.Id LIMIT 1];
        
        System.runAs(uHRS2) {
            Test.startTest();
            
            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            crc.selectedRecipient = 'Large Market 401(k) Partner';
            crc.setRecipient();
            
            System.assertEquals(atm[0].UserId,crc.acctOwner.Id);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
            Test.stopTest();
            
        } // System.runAs
    } // class testHRSRequest
    
    // Test proper steps - everything correct. PEO rep
    static testMethod void testPASRequest() {
        
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User uPAS1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
        User uPAS2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO and Id != :uPAS1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,uPAS1.Id,null,null,null,AccountHelper.CORE_ACCOUNT,false,true,false);
        
        System.runAs(uPAS2) {
            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
            
        } // System.runAs
    } // class testPASRequest
    
    static testMethod void testPEORequest() {
        
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User uPEO1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_PEO and Profile.Name='HRS PEO Centric Sales - SB' limit 1];
        User uPEO2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_PEO and Profile.Name='HRS PEO Centric Sales - SB' and Id != :uPEO1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,uPEO1.Id,null,null,uPEO1.Id,AccountHelper.CORE_ACCOUNT,false,true,false);
        
        System.runAs(uPEO2) {
            System.debug('test with an account owned by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
            
        } // System.runAs
    } // class testPEORequest
    
    // Test proper steps - everything correct. HNB rep
    static testMethod void testHNBRequest() {
        
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true limit 1];
        User uHNB1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_HNB limit 1];
        User uHNB2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_HNB and Id != :uHNB1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,uHNB1.Id,null,null,AccountHelper.CORE_ACCOUNT,false,true,false);
        
        
        System.runAs(uHNB2) {
            System.debug('test with an account owner by a Core Sales user');
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // the account should be the one passed in.
            System.assertEquals(testAcct.Id,crc.thisAcct.Id);
            // not finished - needs comment entered by the user
            System.assertEquals(false,crc.finished);
            // the account is set.
            System.assertEquals(true,crc.hasAcct);
            System.assertEquals(true,crc.crossoverOkay);
            
            
            Transfer_Request__c request = crc.request;
            request.Comments__c = 'test comments';
            String nextPage = crc.saveRequest().getUrl();
            System.assertEquals('/apex/crossoverrequest',nextPage);
            
            System.assertEquals(crc.getReturnButtonTitle(),'Return to Prospect-Client');
            
            // request was saved, should error if we try to submit another one.
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            crc = new CrossoverRequestController(sc1);
            // should be finished - there should be an open transfer request.
            System.assertEquals(true,crc.hasRequests);
            
        } // System.runAs
    } // class testHNBRequest
    
    // Test where owned by rep and non-rep attempts crossover
    static testmethod void testNonRepCrossover() {
        Set<String> excludeSalesOrgs = new Set<String>();
        for (SalesOrg__c so : SalesOrg__c.getAll().values()) {
            excludeSalesOrgs.add(so.Name);
        }
        
        // get a system admin
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Profile.Name='System Administrator' and isActive=true and Sales_Org__c not in :excludeSalesOrgs and Id != :u1.Id limit 1];
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        System.debug('testNonRepCrossover u2='+u2);         
        System.runAs(u2) {
            ApexPages.StandardController sc1 = New ApexPages.StandardController(testAcct);
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(sc1);
            // Shouldn't do anything else - running user doesn't have the correct type of sales org.
            System.assertEquals(true,crc.finished);
            // test the transfer flag
        } // System.runAs
    } // testNonRepCrossover
    
    static testmethod void testBankReferralPayrollCrossover() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true and Id != :UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        
        System.runAs(u2) {
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(testAcct, 'Payroll');
            
            Transfer_Request__c[] request = [SELECT Id, Name, Send_Request_To__c, Comments__c FROM Transfer_Request__c WHERE Send_Request_To__c = :testAcct.OwnerId];
            
            System.assertEquals(request.size(), 1);
            System.assertEquals(request[0].Comments__c, 'Bank Lead was converted.');
            
        } // System.runAs
    } // testBankReferralPayrollCrossover
    
    static testmethod void testBankReferral401kCrossover() {
        // get a default Core user
        User u1 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and isActive=true and Id != :UserInfo.getUserId() limit 1];
        User u2 = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and isActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :u1.Id limit 1];
        
        Account testAcct = getAccount(u1.Id,null,null,null,null,null,AccountHelper.CORE_ACCOUNT,true,true,true);
        
        
        System.runAs(u2) {
            ApexPages.currentPage().getParameters().put('id', testAcct.Id);
            CrossoverRequestController crc = new CrossoverRequestController(testAcct, '401k');
            
            Transfer_Request__c[] request = [SELECT Id, Name, Send_Request_To__c, Comments__c FROM Transfer_Request__c WHERE Send_Request_To__c = :testAcct.OwnerId];
            
            System.assertEquals(request.size(), 1);
            System.assertEquals(request[0].Comments__c, 'Bank Lead was converted.');
            
        } // System.runAs
    } // testBankReferral401kCrossover
    
   
    static testMethod void testNoOwner() {
       // there isn't an owner in the field we're trying to crossover, it should find the DSA
       User[] usrs = [select Id from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_401 and isActive=true and Id != :UserInfo.getUserId() limit 2];
       User dsa = usrs[0];
       User dsm = usrs[1];
       System.debug('testNoOwner dsa='+dsa.Id+' dsm='+dsm.Id);
       ZipCheckOwnerTest.setupZipsAndSegments(true);
       if (ZipCheckOwnerTest.finAdvSeg != null) {
          delete ZipCheckOwnerTest.finAdvSeg;
       }
       Org_Unit__c distHrs = [Select Id, Name, Assistant__c, OverrideAssistant__c,
                                     Manager__c, OverrideMgr__c
                               From  Org_Unit__c
                               Where Name='1'
                                 and Org_Type__c='District'
                                 and Sales_Org__c= :UserHelper.SO_401 limit 1];
       // we want to be able to get the values from the org unit
       distHrs.Assistant__c = dsa.Id;
       distHrs.OverrideAssistant__c = true;
       distHrs.Manager__c = dsm.Id;
       distHrs.OverrideMgr__c = true;
       update distHrs;
        
       Account acct = new Account(Name='Test Account', ShippingPostalCode=ZipCheckOwnerTest.zaHRS1Seg1.Name, Owner_Zip_Code__c=ZipCheckOwnerTest.zaHRS1Seg1.Name);
       CrossoverRequestController crc = new CrossoverRequestController(acct);
       User checkUsr = crc.findSendRequestToUser(UserHelper.SO_401);
       System.debug('testNoOwner zaHRS1Seg1='+ZipCheckOwnerTest.zaHRS1Seg1.User__c+' zaHRS1Seg2='+ZipCheckOwnerTest.zaHRS1Seg2.User__c);
       // this should pull out the territory rep
       System.assertEquals(ZipCheckOwnerTest.zaHRS1Seg1.User__c, checkUsr.Id);
        
       // clear the usr and make sure we get the assistant.
       ZipCheckOwnerTest.terrHrs1.TerritoryRep__c = null;
       ZipCheckOwnerTest.zaHRS1Seg1.User__c = null;
       update ZipCheckOwnerTest.terrHrs1;
       update ZipCheckOwnerTest.zaHRS1Seg1;
       
       checkUsr = crc.findSendRequestToUser(UserHelper.SO_401);
       // this should pull out the territory rep
       System.assertEquals(dsm.Id, checkUsr.Id);
    } // testNoOwner
    
} // class CrossoverRequestControllerTest