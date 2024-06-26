/*********************************************************************************************************************************
 Name:  DG_CampaignAttributionAnalyzer_Test
 Created by DemadnGen Inc.
==================================================================================================================================
Purpose: Test Class of DG_CampaignAttributionAnalyzer_Class.
==================================================================================================================================
History
-------
VERSION     AUTHOR          DATE(dd/mm/yyyy)    DETAIL      Description
1.0         Gram Bischof     29/10/2018          Created     Created
            Dan Carmen       08/09/2023          Increment API
   09/28/2023  Dan Carmen        Change for OP_WITH_INVALID_USER_TYPE_EXCEPTION

************************************************************************************************************************************/

@isTest
private class DG_CampaignAttributionAnalyzer_TEST {
 
    
    @testSetup
    public static void setup(){
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'DG_CampaignAttributionAnalyzer_Class'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses;
    }
    
    static testMethod void CampaignAttributionAnalyzer_Test1() {
        list <Account> listAccount = new list <Account>();
        Account a1 = new Account(//type = 'Prospect', 
		                         name = 'Test Account #1'
								); 
	    listAccount.add(a1);
        Account a2 = new Account( type = 'Prospect', name = 'Test Account #2');           
		listAccount.add(a2);
		
        database.insert(listAccount, false);
        list <Contact> listContact = new list <Contact>();
        Contact c1 = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a1.id, Description = 'Test Contact 1');
        listContact.add(c1);
		
        Contact c2 = new Contact( FirstName = 'Trey', LastName = 'Trey', Email = 'trey@treytest.com', AccountId = a2.id, Description = 'Test Contact 2');
        listContact.add(c2);
		
        database.insert(listContact, false);
        list<Campaign> listCampaign = new list<Campaign>();
        Campaign cm1 = new Campaign( Name = 'xLive Demo1x', Type = 'Webinar');
        listCampaign.add(cm1);
		
        Campaign cm2 = new Campaign( Name = 'xLive Demo2x', Type = 'Website');
		listCampaign.add(cm2);
		
        Campaign cm3 = new Campaign( Name = 'xLive Demo3x', Type = 'Email');
        listCampaign.add(cm3);
		
        database.insert(listCampaign, false);
       	Integer agrCampaignsCount = [SELECT COUNT() FROM Campaign WHERE Name IN ('xLive Demo1x', 'xLive Demo2x', 'xLive Demo3x')];
        system.debug('!!! agrCampaigns:(3) ' + agrCampaignsCount);
		
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm1_1 = new CampaignMember( contactid = c1.id, campaignid = cm1.id, Status = 'Responded');
        listCM.add(cm1_1);
		
        CampaignMember cm1_2 = new CampaignMember( contactid = c1.id, campaignid = cm2.id, Status = 'Responded');
        listCM.add(cm1_2);
		
        CampaignMember cm2_1 = new CampaignMember( contactid = c2.id, campaignid = cm1.id, Status = 'Responded');
        listCM.add(cm2_1);
		
        CampaignMember cm2_2 = new CampaignMember( contactid = c2.id, campaignid = cm2.id, Status = 'Responded');
        listCM.add(cm2_2);
		
        CampaignMember cm2_3 = new CampaignMember( contactid = c2.id, campaignid = cm3.id, Status = 'Responded');
        listCM.add(cm2_3);
		
        database.insert(listCM, false);
        Integer agrCMSCount = [SELECT COUNT() FROM CampaignMember WHERE ContactId IN (:c1.id, :c2.id)];
        system.debug('!!! agrCMSCount:(6) ' + agrCMSCount);
        list<CampaignMember> listSelectCM = [Select Id from CampaignMember where ContactId = :c2.id];
        system.debug('### CM Count: ' + listSelectCM.Size());
        list<Opportunity> listOpportunity = new list<Opportunity>();
        Opportunity o1 = new Opportunity( Name = 'xxDFRxx Opp1', AccountId = a1.id, StageName = 'Estimation', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound' 
		                                 // Commented by AA  
										 //Use_cases__c = 'Booking'
										 );
        listOpportunity.add(o1);
		
        Opportunity o2 = new Opportunity( Name = 'xxDFRxx Opp2', AccountId = a1.id, StageName = 'Closed Won', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search', ForecastCategoryName = 'Closed',NSS_Source__c = 'Inbound' 
		                                 // Commented by AA 
										 /*Potential_Plan__c='Community', 
										 Contract_Start_Date__c=date.today() + 1, 
										 Closing_Notes__c='foo', 
										 Use_cases__c = 'Booking', 
										 Commitment__c = 'One Year', 
										 BillingSchedule__c = 'Monthly', 
										 Out_clause__c = 'No', 
										 Payment_Terms__c = 'Upfront', 
										 Billing_Contact__c = c1.Id*/ 
										 );
        listOpportunity.add(o2);
		
        Test.startTest();
        database.insert(listOpportunity, false);
        Test.stopTest();
		
        Integer agrOppsCount = [SELECT COUNT() FROM Opportunity WHERE Id IN (:o1.id, :o2.id)];
        system.debug('!!! agrOppsCount:(2) ' + agrOppsCount);
        Integer agrCAA1Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id, :o2.id)];
        system.debug('!!! agrCAA1Count:(30) ' + agrCAA1Count);
        system.assertNotEquals(agrCAA1Count, 0);
    }
    
    static testMethod void CampaignAttributionAnalyzer_Test2() {
        list<Account> listAccount = new list<Account>();
        Account a1 = new Account( 
		                         //type = 'Prospect', 
								 name = 'Test Account #1');
        listAccount.add(a1);
		
        database.insert(listAccount, false);
        list<Contact> listContact = new list<Contact>();
        Contact c1 = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a1.id, Description = 'Test Contact 1');
        listContact.add(c1);
		
        Contact c2 = new Contact( FirstName = 'Trey', LastName = 'Trey', Email = 'trey@treytest.com', AccountId = a1.id, Description = 'Test Contact 2');
        listContact.add(c2);
		
        database.insert(listContact, false);
        list<Campaign>listCampaign = new list<Campaign>();
        Campaign cm1 = new Campaign( Name = 'xLive Demo1x', Type = 'Webinar');
        listCampaign.add(cm1);
		
        Campaign cm2 = new Campaign( Name = 'xLive Demo2x', Type = 'Website');
        listCampaign.add(cm2);
		
        Campaign cm3 = new Campaign( Name = 'xLive Demo3x', Type = 'Email');
        listCampaign.add(cm3);
		
        Campaign cm4 = new Campaign( Name = 'xLive Demo4x', Type = 'Other');
        listCampaign.add(cm4);
		
        database.insert(listCampaign, false);
        Integer agrCampaignsCount = [SELECT COUNT() FROM Campaign WHERE Name IN ('xLive Demo1x', 'xLive Demo2x', 'xLive Demo3x')];
        system.debug('!!! agrCampaignsCount:(3) ' + agrCampaignsCount);
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm1_1 = new CampaignMember( contactid = c1.id, campaignid = cm1.id, Status = 'Responded');
        listCM.add(cm1_1);
		
        CampaignMember cm1_2 = new CampaignMember( contactid = c1.id, campaignid = cm2.id, Status = 'Responded');
        listCM.add(cm1_2);
		
        CampaignMember cm1_3 = new CampaignMember( contactid = c1.id, campaignid = cm3.id, Status = 'Responded');
        listCM.add(cm1_3);
		
        CampaignMember cm1_4 = new CampaignMember( contactid = c1.id, campaignid = cm4.id, Status = 'Responded');
        listCM.add(cm1_4);
		
        database.insert(listCM, false);
        list<Opportunity> listOpportunity = new list<Opportunity>();
        Opportunity o1 = new Opportunity( Name = 'xxDFRxx Opp1', AccountId = a1.id, StageName = 'Estimation', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound' 
		                                  // Commented by AA //Use_cases__c = 'Booking'
										);
        listOpportunity.add(o1);
		
        database.insert(listOpportunity, false);
        Integer agrOppsCount = [SELECT COUNT() FROM Opportunity WHERE Id IN (:o1.id)];
        system.debug('!!! agrOppsCount:(2) ' + agrOppsCount);
        Integer agrCAA1Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id)];
        system.debug('!!! agrCAA1Count:(30) ' + agrCAA1Count);
        //system.assertNotEquals(agrCAA1[0].get('caa'), 0);
		
        Contact c3 = new Contact( FirstName = 'Joe', LastName = 'Joe', Email = 'joe@joetest.com', AccountId = a1.id, Description = 'Test Contact 3');
        listContact.add(c2);
        insert c3;
		
        OpportunityContactRole ocr = new OpportunityContactRole( Role = 'Influencer', OpportunityId = o1.Id, ContactId = c2.id);
        try {
            insert ocr;
        } 
		catch (exception e) {
		system.debug('!!! An exception occurred: ' + e.getMessage());
		}
				
        Integer agrOCRsCount = [SELECT COUNT() FROM OpportunityContactRole WHERE OpportunityId IN (:o1.id)];
        system.debug('!!! agrOCRsCount:(1) ' + agrOCRsCount);
        Integer agrCAA2Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id)];
        system.debug('!!! agrCAA2Count:(?) ' + agrCAA2Count);
        CampaignMember cm2_2 = new CampaignMember( contactid = c2.id, campaignid = cm2.id, Status = 'Responded');
        insert cm2_2;
		
        CampaignMember cm3_2 = new CampaignMember( contactid = c3.id, campaignid = cm2.id, Status = 'Responded');
        insert cm3_2;
		
        Test.startTest();
        o1.StageName = 'Closed Won';
        o1.ForecastCategoryName = 'Closed';
       
        try {
            update o1;
        }
		catch (exception e){
		system.debug('!!! An exception occurred: ' + e.getMessage());
		}
		
        Test.stopTest();
        system.debug('!!! test');
        Integer agrCAA3Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id)];
        system.debug('!!! agrCAA3Count:(?) ' + agrCAA3Count);
        system.assertNotEquals(agrCAA3Count, 0);
    }
    
    static testMethod void CampaignAttributionAnalyzer_Test3() {
        list<Account> listAccount = new list<Account>();
        Account a1 = new Account( //type = 'Prospect', 
		                          name = 'Test Account #1'
								);
        listAccount.add(a1);
		
        database.insert(listAccount, false);
        list<Contact> listContact = new list<Contact>();
        Contact c1 = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a1.id, Description = 'Test Contact 1');
        listContact.add(c1);
		
        database.insert(listContact, false);
        list<Campaign> listCampaign = new list<Campaign>();
        Campaign cm1 = new Campaign( Name = 'xLive Demo1x', Type = 'Webinar');
        listCampaign.add(cm1);
		
        Campaign cm2 = new Campaign( Name = 'xLive Demo2x', Type = 'Website');
        listCampaign.add(cm2);
		
        Campaign cm3 = new Campaign( Name = 'xLive Demo3x', Type = 'Email');
        listCampaign.add(cm3);
		
        Campaign cm4 = new Campaign( Name = 'xLive Demo4x', Type = 'Other');
        listCampaign.add(cm4);
		
        database.insert(listCampaign, false);
        Integer agrCampaignsCount = [SELECT COUNT() FROM Campaign WHERE Name IN ('xLive Demo1x', 'xLive Demo2x', 'xLive Demo3x')];
        system.debug('!!! agrCampaignsCount:(3) ' + agrCampaignsCount);
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm1_1 = new CampaignMember( contactid = c1.id, campaignid = cm1.id, Status = 'Responded');
        listCM.add(cm1_1);
		
        CampaignMember cm1_2 = new CampaignMember( contactid = c1.id, campaignid = cm2.id, Status = 'Responded');
        listCM.add(cm1_2);
		
        CampaignMember cm1_3 = new CampaignMember( contactid = c1.id, campaignid = cm3.id, Status = 'Responded');
        listCM.add(cm1_3);
		
        CampaignMember cm1_4 = new CampaignMember( contactid = c1.id, campaignid = cm4.id, Status = 'Responded');
        listCM.add(cm1_4);
		
        database.insert(listCM, false);
        list<Opportunity> listOpportunity = new list<Opportunity>();
        Opportunity o1 = new Opportunity( Name = 'xxDFRxx Opp1', AccountId = a1.id, StageName = 'Estimation', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound'   
		                                 // Commented by AA 
										 //Use_cases__c = 'Booking'
										 );
        listOpportunity.add(o1);
		
        database.insert(listOpportunity, false);
        Integer agrOppsCount = [SELECT COUNT()FROM Opportunity WHERE Id IN (:o1.id)];
        system.debug('!!! agrOppsCount:(2) ' + agrOppsCount);
        Integer agrCAA1Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id)];
        system.debug('!!! agrCAA1Count:(30) ' + agrCAA1Count);
        //system.assertNotEquals(agrCAA1Count, 0);
		
        Test.startTest();
        o1.StageName = 'Closed Won';
        o1.ForecastCategoryName = 'Closed';
        // Commented by AA
        /*o1.Potential_Plan__c='Community';
		o1.Contract_Start_Date__c=date.today() + 1;
		o1.Commitment__c='One Year';
		o1.BillingSchedule__c='Monthly';
		o1.Closing_Notes__c='foo';
		o1.Out_clause__c = 'No';
		o1.Payment_Terms__c = 'Upfront';
		o1.Billing_Contact__c = c1.Id;*/
        try {
            update o1;
        }
		catch (exception e){
		system.debug('!!! An exception occurred: ' + e.getMessage());
		}
        Test.stopTest();
		
        system.debug('!!! test');
        Integer agrCAA3Count = [SELECT COUNT()FROM CAA_Record__c WHERE Opportunity__c IN (:o1.id)];
        system.debug('!!! agrCAA3Count:(?) ' + agrCAA3Count);
        system.assertNotEquals(agrCAA3Count, 0);
    }
    static testMethod void ProcessCampaignAttributionUsingDateRange_Test() {
        Account a = new Account( type = 'Prospect', name = 'Augusto test acct customer 2');
        try {
            insert a;
        } 
		catch (exception e){}
		
        Contact ic = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a.id, Description = 'Test Contact');
        try {
            insert ic;
        } 
		catch (exception e) {}
		
        Campaign c = new Campaign( Name = 'xLive Demox', Type = 'Webinar');
        try {
            insert c;
        } 
		catch (exception e) {}
		
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm = new CampaignMember( contactid = ic.id, campaignid = c.id, Status = 'Responded');
        listCM.add(cm);
        try {
            insert listCM;
        } 
		catch (exception e) {}
		
        try {
            update cm;
        } 
		catch (exception e) {}
		
        Opportunity o = new Opportunity( Name = 'xxDFRxx Opp', AccountId = a.id, StageName = 'Closing', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound'  
		                                // Commented by AA 
										//Use_cases__c = 'Booking'
										);
        try {
            insert o;
        } 
		catch (exception e) {}
		
        DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionUsingDateRange(date.today(), date.today() + 1);
        Integer agrCAACount = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c = :o.id];
        system.debug('!!! agrCAACount:(?) ' + agrCAACount);
        system.assertNotEquals(agrCAACount, 0);
    }
    static testMethod void ProcessCampaignAttributionWithLeadSourceExclusion() {
        Account a = new Account( type = 'Prospect', name = 'My Exclusion Test');
        try {
            insert a;
        } 
		catch (exception e) {}
		
        Contact ic = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a.id, Description = 'Test Contact');
        try {
            insert ic;
        } 
		catch (exception e) {}
		
        Campaign c = new Campaign(Name = 'please discontinue this campaign', Type = 'Webinar');
        try {
            insert c;
        } 
		catch (exception e) {}
		
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm = new CampaignMember( contactid = ic.id, campaignid = c.id,Status = 'Responded');
        listCM.add(cm);
        try {
            insert listCM;
        } 
		catch (exception e) {}
		
        try {
            update cm;
        } 
		catch (exception e) {}
		
        Opportunity o = new Opportunity( Name = 'TestOpportunityForCampaignAttribution', AccountId = a.id, StageName = 'Closed Won', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'List Import', ForecastCategoryName = 'Closed' 
		                                // Commented by AA 
										/*Potential_Plan__c='Community', 
										Contract_Start_Date__c=date.today() + 1, 
										Commitment__c='One Year', 
										BillingSchedule__c='Monthly', 
										Closing_Notes__c='foo'*/
										);            
        try {
            insert o;
        } 
		catch (exception e) {}
		
        Integer agrCAACount = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c = :o.id];
        system.debug('!!! agrCAACount:(?) ' + agrCAACount);

    }
    static testMethod void ProcessCampaignAttributionOnOppRoleChanges_Test() {
        Account a = new Account( type = 'Prospect', name = 'Augusto test acct customer 2');
        try {
            insert a;
        } 
		catch (exception e) {}
		
        Contact ic = new Contact( FirstName = 'Troy', LastName = 'Troy', Email = 'troy@troytest.com', AccountId = a.id, Description = 'Test Contact');
        try {
            insert ic;
        } 
		catch (exception e) {}
		
        Campaign c = new Campaign( Name = 'xLive Demox', Type = 'Webinar');
        try {
            insert c;
        } 
		catch (exception e) {}
		
        list<CampaignMember> listCM = new list<CampaignMember>();
        CampaignMember cm = new CampaignMember( contactid = ic.id, campaignid = c.id, Status = 'Responded');
        listCM.add(cm);
        //try{
        insert listCM;
        //}catch(exception e){}
		
        Opportunity o = new Opportunity( Name = 'TestOpportunityForCampaignAttribution', AccountId = a.id, StageName = 'Closing', CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        //try{
        insert o;
        //}catch(exception e){}
		
        OpportunityContactRole ocr = new OpportunityContactRole( Role = 'Influencer', OpportunityId = o.Id, ContactId = ic.id);
        //try{
        insert ocr;
        //}catch(exception e){}
		
        Integer agrCAA1Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c = :o.id];
        system.debug('!!! agrCAA1Count:(?) ' + agrCAA1Count);
        DG_CampaignAttributionAnalyzer_Class.ProcessCampaignAttributionOnOppRoleChanges();
        Integer agrCAA2Count = [SELECT COUNT() FROM CAA_Record__c WHERE Opportunity__c = :o.id];
        system.debug('!!! agrCAA2Count:(?) ' + agrCAA2Count);
        system.assertNotEquals(agrCAA2Count, 0);
    }
    
    // Add assertions
    static testMethod void DG_CAA_LeadConversion_FromSuspect_Test() {
        test.startTest();
        User Owner = [SELECT Id, Name FROM User WHERE IsActive = true and Job_Name__c=:UserHelper.JOB_REP LIMIT 1];
        Lead l = new Lead( Status = 'Open - Not Contacted', LeadSource = 'Search', Phone = '+1.213.111.1111', LastName = 'First', FirstName = 'Last', Company = 'xxDFRxx', Email = 'aaadfr@aaadfr.net', OwnerId = Owner.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        database.Saveresult srL1Insert = database.insert(l);
		
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setOwnerId(Owner.Id);
        //lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult result = Database.convertLead(lc);
        test.stopTest();
    }
    
	static testMethod void LeadwithCMtoOpportuntity_Test() {
		/*User Owner = [SELECT Id, Name FROM User WHERE IsActive=true LIMIT 1];
		Lead testLead = new Lead(Status = 'Open - Not Contacted',LeadSource = 'Search',Phone = '+1.213.111.1111',
		LastName = 'First',FirstName = 'Last',Company = 'xxDFRxx',Email = 'aaadfr@aaadfr.net',
		OwnerId = Owner.Id);
		insert testLead;
		Campaign testCampaign = new Campaign(Name = 'testCampaign',Type = 'Email');
		insert testCampaign;
		CampaignMember testCM = new CampaignMember(Leadid = testLead.id,Campaignid = testCampaign.id,Status = 'Responded');
		insert testCM;
		Database.LeadConvert lc = new database.LeadConvert();
		lc.setLeadId(testLead.Id);
		lc.setOwnerId(Owner.Id);
		lc.setConvertedStatus('Converted');
		Database.LeadConvertResult result = Database.convertLead(lc);
		System.debug('result.contactid'+result.contactid);
		test.startTest();
		Opportunity theOpp = [SELECT Amount,CloseDate FROM Opportunity WHERE Id = : result.opportunityid];
		theOpp.Amount = 1000;
		update theOpp;
		test.stopTest();
		List<CAA_Record__c> createdCAAs = [Select Id,model__c FROM CAA_Record__c];
		System.assertNotEquals(0, createdCAAs.size());
		Map<String,List<CAA_Record__c>> modelToCAAMap = new Map<String,List<CAA_Record__c>>();
		for(CAA_Record__c caa: createdCAAs){
		if(!modelToCAAMap.containsKey(caa.model__c)) modelToCAAMap.put(caa.model__c,new List<CAA_Record__c>());
		modelToCAAMap.get(caa.model__c).add(caa);
		}
		System.assertEquals(5 * 2,modelToCAAMap.keySet().size());*/
	} 
    static testMethod void OppFromAccRealtedToConWithCM_Test() {
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;		
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact;
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
		
        test.startTest();
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Discovery',
                                                      CloseDate = date.today() + 1, Amount = 1000, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        test.stopTest();
		
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(5, createdCAAs.size());
        Set<String> modelsCreated = new Set<String>();
        for (CAA_Record__c theCAA : createdCAAs) {
            System.assertEquals(100.00, theCAA.Weight__c);
            System.assertEquals(1000.00, theCAA.Split_Amount__c);
            System.assert(theCAA.Model__c.startsWith('Pipeline'));
            modelsCreated.add(theCAA.Model__c);
        }

        System.assert(modelsCreated.contains('Pipeline - First Touch'));
        System.assert(modelsCreated.contains('Pipeline - Last Touch'));
        System.assert(modelsCreated.contains('Pipeline - Linear (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Position (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Weighted (MT)'));
        System.assert(!modelsCreated.contains('Bookings - First Touch'));
        System.assert(!modelsCreated.contains('Bookings - Last Touch'));
        System.assert(!modelsCreated.contains('Bookings - Linear (MT)'));
        System.assert(!modelsCreated.contains('Bookings - Position (MT)'));
        System.assert(!modelsCreated.contains('Bookings - Weighted (MT)'));
    }
    static testMethod void OppCreatedThenAmountChanged_Test() {
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact;
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Discovery',
                                                      CloseDate = date.today().adddays(30), Amount = 100, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        OpportunityContactRole testOCR = new OpportunityContactRole(ContactId = testContact.Id, OpportunityId = testOpportunity.Id, Role = 'Influencer');
        insert testOCR;
		
        test.startTest();
        testOpportunity.Amount = 200;
        update testOpportunity;
        test.stopTest();
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(5, createdCAAs.size());
        Set<String> modelsCreated = new Set<String>();
		
        for (CAA_Record__c theCAA : createdCAAs) {
            System.assertEquals(100.00, theCAA.Weight__c);
            System.assertEquals(200.00, theCAA.Split_Amount__c);
            System.assert(theCAA.Model__c.startsWith('Pipeline'));
            modelsCreated.add(theCAA.Model__c);
        }
        System.assert(modelsCreated.contains('Pipeline - First Touch'));
        System.assert(modelsCreated.contains('Pipeline - Last Touch'));
        System.assert(modelsCreated.contains('Pipeline - Linear (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Position (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Weighted (MT)'));
        System.assert(!modelsCreated.contains('Bookings - First Touch'));
        System.assert(!modelsCreated.contains('Bookings - Last Touch'));
        System.assert(!modelsCreated.contains('Bookings - Linear (MT)'));
        System.assert(!modelsCreated.contains('Bookings - Position (MT)'));
        System.assert(!modelsCreated.contains('Bookings - Weighted (MT)'));
    }
    static testMethod void OppCreatedThenAmountChangedAndWon_Test() {
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact;
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Discovery',
                                                      CloseDate = date.today().adddays(30), Amount = 100, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        OpportunityContactRole testOCR = new OpportunityContactRole(ContactId = testContact.Id, OpportunityId = testOpportunity.Id, Role = 'Influencer');
        insert testOCR;
		
        test.startTest();
        testOpportunity.Amount = 200;
        testOpportunity.StageName = 'Closed Won';
        // Commented by AA
        /*testOpportunity.Closing_Notes__c = 'Something';
		testOpportunity.Commitment__c = 'One Year';
		testOpportunity.Contract_Start_Date__c = Date.today();
		testOpportunity.BillingSchedule__c = 'Annual';*/
        update testOpportunity;
        test.stopTest();
		
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(10, createdCAAs.size());
        Set<String> modelsCreated = new Set<String>();
		
        for (CAA_Record__c theCAA : createdCAAs) {
            System.assertEquals(100.00, theCAA.Weight__c);
            System.assertEquals(200.00, theCAA.Split_Amount__c);
            modelsCreated.add(theCAA.Model__c);
        }
        System.assert(modelsCreated.contains('Pipeline - First Touch'));
        System.assert(modelsCreated.contains('Pipeline - Last Touch'));
        System.assert(modelsCreated.contains('Pipeline - Linear (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Position (MT)'));
        System.assert(modelsCreated.contains('Pipeline - Weighted (MT)'));
        System.assert(modelsCreated.contains('Bookings - First Touch'));
        System.assert(modelsCreated.contains('Bookings - Last Touch'));
        System.assert(modelsCreated.contains('Bookings - Linear (MT)'));
        System.assert(modelsCreated.contains('Bookings - Position (MT)'));
        System.assert(modelsCreated.contains('Bookings - Weighted (MT)'));
    }
    static testMethod void OppCreatedOCRAddedCAARecalc_Test() {
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact;
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Closing',
                                                      CloseDate = date.today() + 1, Amount = 100, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        OpportunityContactRole testOCR = new OpportunityContactRole(ContactId = testContact.Id, OpportunityId = testOpportunity.Id);
        insert testOCR;
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        //System.assertEquals(5, createdCAAs.size());
		
        test.startTest();
        Contact testContact2 = new Contact(FirstName = 'testFN2', LastName = 'testLN2', Email = 'test2@testFL.com', AccountId = testAccount.Id, Description = 'Test Contact');
        insert testContact2;
        CampaignMember testCM2 = new CampaignMember(ContactId = testContact2.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM2;
        OpportunityContactRole testOCR2 = new OpportunityContactRole(ContactId = testContact2.Id, OpportunityId = testOpportunity.Id);
        insert testOCR2;
        testOpportunity.Amount = 200;
        update testOpportunity;
        test.stopTest();
		
        createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(8, createdCAAs.size());
        Map<String, List<CAA_Record__c>> modelToCAAMap = new Map<String, List<CAA_Record__c>>();
        for (CAA_Record__c theCAA : createdCAAs) {
            if (!modelToCAAMap.containsKey(theCAA.Model__c)) modelToCAAMap.put(theCAA.Model__c, new List<CAA_Record__c>());                                                                                                                                                             
            modelToCAAMap.get(theCAA.Model__c).add(theCAA);
            if (theCAA.Model__c == 'Pipeline - First Touch' || theCAA.Model__c == 'Pipeline - Last Touch') {
                System.assertEquals(100.00, theCAA.Weight__c);
                System.assertEquals(200.00, theCAA.Split_Amount__c);
            }
            if (theCAA.Model__c == 'Pipeline - Linear (MT)' || theCAA.Model__c == 'Pipeline - Position (MT)' || theCAA.Model__c == 'Pipeline - Weighted (MT)') {
                System.assertEquals(50.00, theCAA.Weight__c);
                System.assertEquals(100.00, theCAA.Split_Amount__c);
            }
        }
        System.assertEquals(1, modelToCAAMap.get('Pipeline - First Touch').size());
        System.assertEquals(1, modelToCAAMap.get('Pipeline - Last Touch').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Linear (MT)').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Position (MT)').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Weighted (MT)').size());
        System.assert(!modelToCAAMap.keySet().contains('Bookings - First Touch'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Last Touch'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Linear (MT)'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Position (MT)'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Weighted (MT)'));
    }
    
    static testMethod void OppCreatedOCRemovedCAARecalc_Test() {
        
        DG_CAA_Settings__mdt CAAsettings =[SELECT MasterLabel, Label, QualifiedApiName, Attribution_Window__c,
		Batch_Email_Notification__c, Batch_Email_Notification_Recipient__c,
		Enable__c, First_Position__c,
		Include_Accelerators_for_Bookings__c,
		Include_Non_Response_Status__c,
		Influence_Source__c,
		Last_Position__c,
		Model_Bookings_First_Touch__c,
		Model_Bookings_Last_Touch__c,
		Model_Bookings_Linear__c,
		Model_Bookings_Position_Based__c,
		Model_Bookings_Weighted__c,
		Model_Pipeline_First_Touch__c,
		Model_Pipeline_Last_Touch__c,
		Model_Pipeline_Linear__c,
		Model_Pipeline_Position_Based__c,
		Model_Pipeline_Weighted__c
		FROM DG_CAA_Settings__mdt WHERE MasterLabel = 'MasterSettings'];
        
        // Check that Opportunity Contact Roles are being used
        if(CAAsettings.Influence_Source__c == 'AccountContact') return;
        
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact;
        Contact testContact2 = new Contact(FirstName = 'testFN2', LastName = 'testLN2', Email = 'test2@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert testContact2;
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        CampaignMember testCM2 = new CampaignMember(ContactId = testContact2.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM2;
        // Add Campaign and Campaign Members
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Closing',
                                                      CloseDate = date.today() + 1, Amount = 100, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        OpportunityContactRole testOCR = new OpportunityContactRole(ContactId = testContact.Id, OpportunityId = testOpportunity.Id, Role = 'Influencer');
        insert testOCR;
        OpportunityContactRole testOCR2 = new OpportunityContactRole(ContactId = testContact2.Id, OpportunityId = testOpportunity.Id, Role = 'Influencer');
        insert testOCR2;
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(8, createdCAAs.size());
        Map<String, List<CAA_Record__c>> modelToCAAMap = new Map<String, List<CAA_Record__c>>();
        for (CAA_Record__c theCAA : createdCAAs) {
            if (!modelToCAAMap.containsKey(theCAA.Model__c)) modelToCAAMap.put(theCAA.Model__c, new List<CAA_Record__c>());                                                                                                                                                           
            modelToCAAMap.get(theCAA.Model__c).add(theCAA);
            if (theCAA.Model__c == 'Pipeline - First Touch' || theCAA.Model__c == 'Pipeline - Last Touch') {
                System.assertEquals(100.00, theCAA.Weight__c);
            }
            if (theCAA.Model__c == 'Pipeline - Linear (MT)' || theCAA.Model__c == 'Pipeline - Position (MT)' || theCAA.Model__c == 'Pipeline - Weighted (MT)') {
                System.assertEquals(50.00, theCAA.Weight__c);
            }
        }
        System.assertEquals(1, modelToCAAMap.get('Pipeline - First Touch').size());
        System.assertEquals(1, modelToCAAMap.get('Pipeline - Last Touch').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Linear (MT)').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Position (MT)').size());
        System.assertEquals(2, modelToCAAMap.get('Pipeline - Weighted (MT)').size());
        System.assert(!modelToCAAMap.keySet().contains('Bookings - First Touch'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Last Touch'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Linear (MT)'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Position (MT)'));
        System.assert(!modelToCAAMap.keySet().contains('Bookings - Weighted (MT)'));
		
        test.startTest();
        Delete testOCR2;
        testOpportunity.Amount = 200;
        update testOpportunity;
        test.stopTest();
		
        createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        System.assertEquals(5, createdCAAs.size());
        for(CAA_Record__c theCAA : createdCAAs) {
        	System.assertEquals(200, theCAA.Split_Amount__c);    
        }

    }
    
    static testMethod void OppCreatedWithOLI_Test() {
        Account testAccount = new Account(type = 'Prospect', name = 'testAccount');
        insert testAccount;
        Contact testContact = new Contact(FirstName = 'testFN', LastName = 'testLN', Email = 'test@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        Contact testContact2 = new Contact(FirstName = 'testFN2', LastName = 'testLN2', Email = 'test2@testFL.com', AccountId = testAccount.id, Description = 'Test Contact');
        insert new Contact[]{testContact,testContact2};
        Campaign testCampaign = new Campaign(Name = 'testCampaign', Type = 'Email');
        insert testCampaign;
        CampaignMember testCM = new CampaignMember(ContactId = testContact.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM;
        CampaignMember testCM2 = new CampaignMember(ContactId = testContact2.id, Campaignid = testCampaign.id, Status = 'Responded');
        insert testCM2;
        // Add Campaign and Campaign Members
        Opportunity testOpportunity = new Opportunity(Name = 'TestOpportunity', AccountId = testAccount.id, StageName = 'Closing',
                                                      CloseDate = date.today() + 1, Amount = 0, LeadSource = 'Search',NSS_Source__c = 'Inbound' );
        insert testOpportunity;
        
       
        
        test.startTest();
        
        List<CAA_Record__c> createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        //System.assertEquals(8, createdCAAs.size()); Moved this to async so it no longer can be asserted until after stop test
      
        Pricebook2 testPB = new Pricebook2(Name='testDIE');
        insert testPB;
        
        Product2 testProduct = new Product2(Name='BXCD', isActive=true);
        insert testProduct;
        
        PricebookEntry testPBE =new PricebookEntry(unitprice=100,Product2Id=testProduct.Id,Pricebook2Id=Test.getStandardPricebookId(),
                                                isActive=true,UseStandardPrice = false);
        insert testPBE;
        
        OpportunityLineItem OPplineitem2 = new OpportunityLineItem (Quantity=2, OpportunityId=testOpportunity.Id,UnitPrice=100,PriceBookEntryId=testPBE.Id);
        insert OPplineitem2;
        
        test.stopTest();
		
        testOpportunity = [Select id,Amount From Opportunity Where Id = :testOpportunity.Id];
        
        createdCAAs = [Select Id, Weight__c, Model__c, Split_Amount__c FROM CAA_Record__c];
        for(CAA_Record__c theCAA : createdCAAs) {
        	//System.assertEquals(theCAA.Weight__c/100 * testOpportunity.Amount, theCAA.Split_Amount__c);    
        }
    }

}