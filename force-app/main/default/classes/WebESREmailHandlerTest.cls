/**
 * Test method for WebESREmailHandler and WebESREmailHelper
 * 
 * History
 * --------
 * 05/27/2015  Cindy Freeman    created
 * 11/02/2015  Cindy Freeman    commented out some tests because ESR was retired, fields were locked and validation rules changed
   12/29/2022  Dan Carmen       Commented out code. If no repurcussion delete the ESRtracking_settings__c custom setting

 */
@isTest
public class WebESREmailHandlerTest {

    // missing ESR custom setting
    static testMethod void myUnitTest1() {
                
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test ESR Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083-1234567</branchclientid>\r <reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ERS</reasons1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasons2>\r </note>';
        email.plainTextBody = test1;
        
        String except;
        WebESREmailHandler esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            except=ex.getMessage();
        }
        new WebESREmailHelper();
        /*
        system.assertEquals('ESRSettings missing',except.left(19));
        
        // populate custom setting but inactive
        Group goodQ = [Select Id, Name, Type from Group where Type = 'Queue' limit 1];
        ESRtracking_settings__c esrSetting = new ESRtracking_settings__c();
        esrSetting.Name = 'ESR settings';
        esrSetting.Campaign_Name__c = 'ESR test campaign';
        esrSetting.Case_Record_Type__c = 'ESR Case Record Type';
        esrSetting.isActive__c = false;
        esrSetting.Log_All_Emails__c = false;
        esrSetting.OwnerID__c = goodQ.Id;
        insert esrSetting;
                
        esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            except=ex.getMessage();
        }
        system.assertEquals('ESRSettings missing',except.left(19));
        */                
    } // myUnitTest1
    /*
    // bad xml, throw an exception
    //  bad branch-client id, throw an exception
    static testMethod void myUnitTest2() {
        setupTestData();
                
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test ESR Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083-1234567</branchclientid>\r <bisid>123456</bisid>\r <reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasons1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasons2>\r </note>';
        email.plainTextBody = test1;
        
        String except;
        WebESREmailHandler esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            System.assertEquals(ex.getMessage().Left(19),'Unable to Parse XML');
        }
        
        // populate email body        
        test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083</branchclientid>\r <bisid>123</bisid>\r <reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasonsfordecliningesrservices2>\r </note>';
        email.plainTextBody = test1;
              
        esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            System.assertEquals(ex.getMessage().Left(19),'Unable to Parse XML');
        }
    } // myUnitTest2
    
    // existing account, new contact, new case
    static testMethod void myUnitTest3() {
        setupTestData();
                
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test ESR Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083-1234567</branchclientid>\r <bisid>123456</bisid>\r ';
        test1 += '<reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasonsfordecliningesrservices2>\r </note>';
        email.plainTextBody = test1;
        
        String except;
        WebESREmailHandler esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            //System.assertEquals(ex.getMessage(),'should not fail here');
            System.assertEquals(ex.getMessage().Left(17),'Unable to Process');
        }
        /*            
        Account acct = [Select Id, Name, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c, 
                        (select Id, Name from Contacts), 
                        (Select Id, Subject, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c 
                            from Cases) from Account where bis_id__c = 123456];
        List<Contact> ctctList = new List<Contact>();
        for (Contact ct:acct.Contacts)
        {   ctctList.add(ct);   }
    
        List<Case> caseList = new List<Case>();        
        for (Case kase: acct.Cases)
        {   caseList.add(kase); }
        
        ErrorLog__c[] errlogList = [Select Id, ClassName__c, Description__c from ErrorLog__c where CreatedDate = TODAY and ClassName__c = 'WebESREmailHandler'];
        System.assertEquals(errlogList.size(), 1);
        System.assertEquals(errlogList.get(0).Description__c, 'incoming Web-Marketo ESR emails');
        
        System.assertEquals(ctctList.size(), 1);
        System.assertEquals(caseList.size(), 1);
        System.assertEquals(acct.ESRService__c,'Virtual - Opt Out Received');
        System.assertEquals(acct.ESRservice_Declined_Reason_Level1__c,'I Do Not Plan to Take Action on ESR');
        System.assertEquals(acct.ESRservice_Declined_Reason_Level2__c,'I Think ESR Is Fun');
        
        // use contact just created and create second case
        // populate email body        
        test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083-1234567</branchclientid>\r <bisid></bisid>\r ';
        test1 += '<reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun The Second Time</reasonsfordecliningesrservices2>\r </note>';
        email.plainTextBody = test1;
                
        esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            System.assertEquals(ex.getMessage(),'should not fail here');
        }
                    
        acct = [Select Id, Name, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c, 
                        (select Id, Name from Contacts), 
                        (Select Id, Subject, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c 
                            from Cases) from Account where bis_id__c = 123456];
        ctctList = new List<Contact>();
        for (Contact ct:acct.Contacts)
        {   ctctList.add(ct);   }
    
        caseList = new List<Case>();        
        for (Case kase: acct.Cases)
        {   caseList.add(kase); }
                
        System.assertEquals(ctctList.size(), 1);
        System.assertEquals(caseList.size(), 2);
        System.assertEquals(acct.ESRservice_Declined_Reason_Level2__c,'I Think ESR Is Fun The Second Time');
        
        List<Campaign> esrCampaignList = [Select Id, Name, IsActive from Campaign where Name = 'ESR test campaign' and IsActive = TRUE];
        List<CampaignMember> memberList = [Select Id, ContactId from CampaignMember where CampaignId = :esrCampaignList.get(0).Id];
        System.assertEquals(memberList.size(), 1);
        */
    /*
    } // myUnitTest3

    // existing account, existing contact, new case
    static testMethod void myUnitTest4() {
        setupTestData();
                
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test ESR Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String test1 = '<note>\r <firstname>First</firstname>\r <lastname>Last2</lastname>\r <email>fLast2@abc.com</email>\r <phone>585-555-1212</phone>';
        test1 += '<branchclientid>400-987654</branchclientid>\r <bisid>111222</bisid>\r ';
        test1 += '<reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasonsfordecliningesrservices2>\r </note>';
        email.plainTextBody = test1;
        
        String except;
        WebESREmailHandler esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            //System.assertEquals(ex.getMessage(),'should not fail here');
            System.assertEquals(ex.getMessage().Left(17),'Unable to Process');
        }
        /*            
        Account acct = [Select Id, Name, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c, 
                        (select Id, Name from Contacts), 
                        (Select Id, Subject, ESRService__c, ESRservice_Declined_Reason_Level1__c, ESRservice_Declined_Reason_Level2__c 
                            from Cases) from Account where bis_id__c = 111222];
        List<Contact> ctctList = new List<Contact>();
        for (Contact ct:acct.Contacts)
        {   ctctList.add(ct);   }
    
        List<Case> caseList = new List<Case>();        
        for (Case kase: acct.Cases)
        {   caseList.add(kase); }
          
        System.assertEquals(ctctList.size(), 1);
        System.assertEquals(caseList.size(), 1);
        System.assertEquals(acct.ESRService__c,'Virtual - Opt Out Received');
        System.assertEquals(acct.ESRservice_Declined_Reason_Level1__c,'I Do Not Plan to Take Action on ESR');
        System.assertEquals(acct.ESRservice_Declined_Reason_Level2__c,'I Think ESR Is Fun');
        
        List<Campaign> esrCampaignList = [Select Id, Name, IsActive from Campaign where Name = 'ESR test campaign' and IsActive = TRUE];
        List<CampaignMember> memberList = [Select Id, ContactId from CampaignMember where CampaignId = :esrCampaignList.get(0).Id];
        System.assertEquals(memberList.size(), 1);
        */
    /*
    } // myUnitTest4
    
    // multiple campaigns
    static testMethod void myUnitTest5() {
        setupTestData();
        Schema.RecordTypeInfo campRt = RecordTypeHelper.getRecordType('Marketing Record Type', 'Campaign'); 
        Campaign esrCampaign = new Campaign();
        esrCampaign.Name = 'ESR test campaign';
        esrCampaign.Originator__c = 'Marketing';
        esrCampaign.Status = 'Planned';
        esrCampaign.StartDate = Date.Today();
        esrCampaign.IsActive = true;
        esrCampaign.LeadSource__c = 'Corp Marketing-Email';
        esrCampaign.RecordTypeId = campRt.getRecordTypeId();
        insert esrCampaign;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
 
        // setup the data for the email
        email.subject = 'Test ESR Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String test1 = '<note>\r <firstname>Betty</firstname>\r <lastname>Rubble</lastname>\r <email>betty@email.com</email>\r <phone>585-111-1122</phone>';
        test1 += '<branchclientid>0083</branchclientid>\r <bisid>123</bisid>\r ';
        test1 += '<reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>';
        test1 += '<reasonsfordecliningesrservices2>I Think ESR Is Fun</reasonsfordecliningesrservices2>\r </note>';
        email.plainTextBody = test1;
        
        String except;
        WebESREmailHandler esrHndlr = new WebESREmailHandler();
        try {
            esrHndlr.handleInboundEmail(email, env);
        }
        catch(WebESREmailHandler.WebESREmailHandlerException ex) {
            System.assertEquals(ex.getMessage().Left(17),'Unable to Process');
        }
       
    } // myUnitTest5
    
    public static void setupTestData() {
        // create campaign
        Schema.RecordTypeInfo campRt = RecordTypeHelper.getRecordType('Marketing Record Type', 'Campaign');     
        Campaign esrCampaign = new Campaign();
        esrCampaign.Name = 'ESR test campaign';
        esrCampaign.Originator__c = 'Marketing';
        esrCampaign.Status = 'Planned';
        esrCampaign.StartDate = Date.Today();
        esrCampaign.IsActive = true;
        esrCampaign.LeadSource__c = 'Corp Marketing-Email';
        esrCampaign.RecordTypeId = campRt.getRecordTypeId();
        insert esrCampaign;
        
        Group goodQ = [Select Id, Name, Type from Group where Type = 'Queue' limit 1];              
        // populate custom setting
        ESRtracking_settings__c esrSetting = new ESRtracking_settings__c();
        esrSetting.Name = 'ESR settings';
        esrSetting.Campaign_Name__c = 'ESR test campaign';
        esrSetting.Case_Record_Type__c = 'ESR Case Record Type';
        esrSetting.isActive__c = true;
        esrSetting.Log_All_Emails__c = true;
        esrSetting.OwnerID__c = goodQ.Id;
        insert esrSetting;
        
        // create Core Account
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId(), type = 'Core Client', Bis_ID__c = 123456
                                ,BillingPostalCode = '10000', AccountNumber = '83-1234567', Do_Not_Call__c = true                                
                                ,Phone = '555-1212', Email_Opt_Out__c = true, AnnualRevenue = 25, NumberOfEmployees = 5);
        insert acct1;
        
        // create MMS Account and Contact
        Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT);
        Account acct2 = new Account (name = 'Test Account2'
                                ,recordtypeId = acctMMSrt.getRecordTypeId(), type = 'Core Client', BillingPostalCode = '10000'
                                ,Bis_ID__c=111222,AccountNumber = '400-987654', Do_Not_Call__c = true, Phone = '555-1212'
                                ,Email_Opt_Out__c = true, AnnualRevenue = 2500, NumberofEmployees = 75);
        insert acct2;
        Contact con2 = new Contact(Firstname = 'First', Lastname = 'Last2', recordtypeId = ctctMMSrt.getRecordTypeId()
                                ,Phone = '585-555-1212', Email = 'fLast2@abc.com', DoNotCall = false
                                ,HasOptedOutOfEmail = false, AccountId=acct2.Id);            
    } // setupTestData
    */
} // class WebESREmailHandlerTest