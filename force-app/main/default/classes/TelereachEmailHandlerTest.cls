/** Accept an email from telereach, create opp and update account
 *
 * History
 * -------
 * 03/21/2019 Jake Hinds	Accept email from telereach, use email to convert lead, create opp and meeting
 * 11/22/2019 Jake Hinds	Adding error email test

 */
@isTest
private class TelereachEmailHandlerTest {

    static testMethod void testContact() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        SalesOrg__c sos = new SalesOrg__c(Name='PEO'
        							//,OpptyRecordTypeName__c='Prism PEO Opportunity Record Type'
        							,OpptyRecordTypeName__c='PEO Opportunity Record Type'
        							,EventRecordTypeName__c='Prism PEO Event Record Type'
        							,ReferralOppFirstStage__c='Create - Received');
        insert sos;
        Referral_Partner__c refPart = new Referral_Partner__c(Name='PEO'
        													,Partner_Type__c='PEO Referral'
        													,Ref_To_Type__c='User'
        													,IsActive__c=true
        													,NSS_Source__c='Telereach'
        													,Selling_Opp_RecordTypeId__c='0120g000000EAgo'
        													,CreateSellerActivity__c=true
        													,SellingOpportunityType__c='PEO');
		insert refPart;
		Zip_Code_Information__c zci = new Zip_Code_Information__c(Name='14425',TimeZoneName__c='America/New_York');
		insert zci;
		Schema.RecordTypeInfo peoRT = RecordTypeHelper.getRecordType(Label.RT_Prospect_Acct, ObjectHelper.OBJECT_ACCOUNT);
        Account acct = new Account (name = 'Test Account1'
                                ,recordtypeId = peoRT.getRecordTypeId()
                                ,ownerId = UserInfo.getUserId()
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Employees__c = 60
                                ,Phone = '555-1212');
        insert acct;
        Contact ctct = new Contact(FirstName='test'
        						,LastName='Contact'
        						,AccountId = acct.Id);
       	insert ctct; 
        // setup the data for the email
        email.subject = 'Test PEO Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String body = 'This email is to inform you of an appointment with: \n';
        body += 'Company Name: TeleReach Corporate\n';
		body += 'SalesForce ID: '+ctct.Id+'\n';
		body += 'Contact Name: Client Services\n';
		body += 'Contact Title: Top Chief\n';
		body += 'Address: 123 Main St, New City, NY 14425\n';
		body += 'Main Phone Number: (123) 456 7890\n';
		body += 'Direct Phone Number: (860) 358 9129\n';
		body += 'Mobile Phone Number: (860) 123 4567\n';
		body += 'Email: clientservices@telereach.com\n';
		body += 'Meeting Date: 06/01/2019\n';
		body += 'Meeting Time: 6: 00 AM Time Zone: Eastern\n';
		body += 'Original PEO Listed: \n';
		body += 'Total Number of Employees: 0\n';
		body += 'Number of Employees on Benefits: TEST 2\n';
		body += 'Current PEO if Different: Sheet Metal Machine Model(s) Inserted\n';
		body += 'PEO Renewal Date: 01/01/1996\n';
		body += 'Payroll Provider: TEST 3\n';
		body += 'If the company no longer has a PEO list Medical Provider, Renewal Date, and Payroll Processor in comments below:test\n';
		body += 'Additional Information and Comments: Test Comments Go Here\n';
		body += 'Script Title:  DO NOT EDIT THIS RECORD!\n';
		body += 'Market: Market Goes Here\n';
		body += 'Link to Sound File: http://www.google.com \n';
        
        email.plainTextBody = body;
        
        
        Test.StartTest();
        TelereachEmailHandler teleHndlr = new TelereachEmailHandler();
        teleHndlr.handleInboundEmail(email, env);
        Referral__c ref = [SELECT Id,Selling_Opportunity__c,SourceContact__c,SourceContact__r.FirstName,SourceContact__r.LastName,
        					SourceContact__r.Title,SourceContact__r.Phone,SourceContact__r.MobilePhone,SourceContact__r.Email,
        					Account__c,Account__r.Name,Account__r.ShippingStreet,Account__r.ShippingCity,Account__r.ShippingState,
        					Account__r.ShippingPostalCode,Account__r.Phone,Account__r.Current_Prior_Method__c,
        					Referral_Partner__c 
                           FROM Referral__c WHERE SourceContact__c=:ctct.Id AND Account__c=:acct.Id];
        System.assert(ref.Selling_Opportunity__c!=null);
        System.assertEquals(refPart.Id,ref.Referral_Partner__c);
        System.assertEquals('Client',ref.SourceContact__r.FirstName);
        System.assertEquals('Services',ref.SourceContact__r.LastName);
        System.assertEquals('Top Chief',ref.SourceContact__r.Title);
        System.assertEquals('(860) 358 9129',ref.SourceContact__r.Phone);
        System.assertEquals('(860) 123 4567',ref.SourceContact__r.MobilePhone);
        System.assertEquals('clientservices@telereach.com',ref.SourceContact__r.Email);
        System.assertEquals('TeleReach Corporate',ref.Account__r.Name);
        System.assertEquals('123 Main St',ref.Account__r.ShippingStreet);
        System.assertEquals('New City',ref.Account__r.ShippingCity);
        System.assertEquals('NY',ref.Account__r.ShippingState);
        System.assertEquals('14425',ref.Account__r.ShippingPostalCode);
        System.assertEquals('(123) 456 7890',ref.Account__r.Phone);
        System.assertEquals('TEST 3',ref.Account__r.Current_Prior_Method__c);
        Event evt = [SELECT Id,StartDateTime FROM Event WHERE WhatId=:ref.Selling_Opportunity__c AND WhoId=:ref.SourceContact__c LIMIT 1];
        system.assertEquals(DateTime.newInstance(2019, 6, 01, 6, 0, 0),evt.StartDateTime);
        
        Test.stopTest();
                
    }
    static testMethod void testLead() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        SalesOrg__c sos = new SalesOrg__c(Name='PEO'
        							//,OpptyRecordTypeName__c='Prism PEO Opportunity Record Type'
        							,OpptyRecordTypeName__c='PEO Opportunity Record Type'
        							,EventRecordTypeName__c='Prism PEO Event Record Type'
        							,ReferralOppFirstStage__c='Create - Received');
        insert sos;
        Referral_Partner__c refPart = new Referral_Partner__c(Name='PEO'
        													,Partner_Type__c='PEO Referral'
        													,Ref_To_Type__c='User'
        													,IsActive__c=true
        													,NSS_Source__c='Telereach'
        													,Selling_Opp_RecordTypeId__c='0120g000000EAgo'
        													,CreateSellerActivity__c=true
        													,SellingOpportunityType__c='PEO');
		insert refPart;
		Zip_Code_Information__c zci = new Zip_Code_Information__c(Name='14425',TimeZoneName__c='America/New_York');
		insert zci;
		Schema.RecordTypeInfo peoRT = RecordTypeHelper.getRecordType(Label.RT_PEO_Lead, ObjectHelper.OBJECT_LEAD);
		Lead ld = new Lead(LastName='test'
							,Company='Lead'
							,recordTypeId=peoRT.getRecordTypeId()
							,ownerId = UserInfo.getUserId()
							,leadSource = 'LeadSource');
		insert ld;
        
        // setup the data for the email
        email.subject = 'Test PEO Emails';
        email.fromname = 'FirstName LastName';
        env.fromAddress = 'someaddress@email.com';
 
        // populate email body        
        String body = 'This email is to inform you of an appointment with: \n';
        body += 'Company Name: TeleReach Corporate\n';
		body += 'SalesForce ID: '+ld.Id+'\n';
		body += 'Contact Name: Client Services\n';
		body += 'Contact Title: Top Chief\n';
		body += 'Address: 123 Main St, New City, NY 14425\n';
		body += 'Main Phone Number: (123) 456 7890\n';
		body += 'Direct Phone Number: (860) 358 9129\n';
		body += 'Mobile Phone Number: (860) 123 4567\n';
		body += 'Email: clientservices@telereach.com\n';
		body += 'Meeting Date: 06/01/2019\n';
		body += 'Meeting Time: 6: 00 AM Time Zone: Eastern\n';
		body += 'Original PEO Listed: \n';
		body += 'Total Number of Employees: 0\n';
		body += 'Number of Employees on Benefits: TEST 2\n';
		body += 'Current PEO if Different: Sheet Metal Machine Model(s) Inserted\n';
		body += 'PEO Renewal Date: 01/01/1996\n';
		body += 'Payroll Provider: TEST 3\n';
		body += 'If the company no longer has a PEO list Medical Provider, Renewal Date, and Payroll Processor in comments below:test\n';
		body += 'Additional Information and Comments: Test Comments Go Here\n';
		body += 'Script Title:  DO NOT EDIT THIS RECORD!\n';
		body += 'Market: Market Goes Here\n';
		body += 'Link to Sound File: http://www.google.com \n';
        
        email.plainTextBody = body;
        
        Test.StartTest();
        TelereachEmailHandler teleHndlr = new TelereachEmailHandler();
        teleHndlr.handleInboundEmail(email, env);
        Referral__c ref = [SELECT Id,Selling_Opportunity__c,SourceContact__c,SourceContact__r.FirstName,SourceContact__r.LastName,
        					SourceContact__r.Title,SourceContact__r.Phone,SourceContact__r.MobilePhone,SourceContact__r.Email,
        					Account__c,Account__r.Name,Account__r.ShippingStreet,Account__r.ShippingCity,Account__r.ShippingState,
        					Account__r.ShippingPostalCode,Account__r.Phone,Account__r.Current_Prior_Method__c,
        					Referral_Partner__c 
                           FROM Referral__c WHERE SourceLead__c=:ld.Id];
        System.assert(ref.Selling_Opportunity__c!=null);
        System.assertEquals(refPart.Id,ref.Referral_Partner__c);
        System.assertEquals('Client',ref.SourceContact__r.FirstName);
        System.assertEquals('Services',ref.SourceContact__r.LastName);
        System.assertEquals('Top Chief',ref.SourceContact__r.Title);
        System.assertEquals('(860) 358 9129',ref.SourceContact__r.Phone);
        System.assertEquals('(860) 123 4567',ref.SourceContact__r.MobilePhone);
        System.assertEquals('clientservices@telereach.com',ref.SourceContact__r.Email);
        System.assertEquals('TeleReach Corporate',ref.Account__r.Name);
        System.assertEquals('123 Main St',ref.Account__r.ShippingStreet);
        System.assertEquals('New City',ref.Account__r.ShippingCity);
        System.assertEquals('NY',ref.Account__r.ShippingState);
        System.assertEquals('14425',ref.Account__r.ShippingPostalCode);
        System.assertEquals('(123) 456 7890',ref.Account__r.Phone);
        System.assertEquals('TEST 3',ref.Account__r.Current_Prior_Method__c);
        Event evt = [SELECT Id,StartDateTime FROM Event WHERE WhatId=:ref.Selling_Opportunity__c AND WhoId=:ref.SourceContact__c LIMIT 1];
        system.assertEquals(DateTime.newInstance(2019, 6, 01, 6, 0, 0),evt.StartDateTime);
        
        
        
        Test.stopTest();
                
    }
    static testMethod void testErrorEmail() {
        PaychexSettings__c payxSetting = new PaychexSettings__c(Name='TelereachForwardErrorEmail',IsActive__c=true,Attribute1__c='jhinds@paychex.com');
        insert payxSetting;
        TelereachEmailHandler teleHndlr = new TelereachEmailHandler();
        Messaging.Singleemailmessage mail = teleHndlr.forwardEmail('testSubject','testBody');
        system.assert(mail!=null);
    }    
}