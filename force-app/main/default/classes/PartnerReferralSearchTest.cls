/** Test Methods for the PartnerReferralSearch class
 *
 * History
 * -------
 * 10/05/2019 Cindy Freeman        Created.
   11/04/2019 Dan Carmen           Remove isdc references
   11/25/2019 Cindy Freeman        Added test for no valid Partner Referrals for the lead
   12/06/2019 Cindy Freeman        Added test for account/contact match
   12/31/2019 Cindy Freeman       modified test for job tracker records
   05/30/2024 Dan Carmen         changed to use the Queueable delay instead of a callout
   06/10/2024 Pujitha Madamanchi Added DialSource field to be populated on merge

 */
@isTest
private class PartnerReferralSearchTest {
   

   static testMethod void test1() {
        // perhaps I need the Task trigger interface stuff
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting('TaskAfter', false, true, new String[]{'TaskHelper'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses;
        Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = PartnerReferralSearch.CLASS_NAME, Active__c = true, BatchSize__c=1, Minutes_till_Launch__c=0,LogProcess__c=true);
        insert abc; 
       
        Schema.RecordTypeInfo cmpgnRt = RecordTypeHelper.getRecordType('Marketing Record Type', 'Campaign');
        Campaign cmp = new Campaign(Name = 'Marketing Campaign TEST', Status='In Progress',StartDate = System.TODAY(), IsActive=true, NSS_Inbound__c=true,
                                    Originator__c='Marketing', ACD_Name__c='ACDTest1', 
                                    LeadSource__c='Corp Marketing-Web', Type='Corp Marketing-Web', RecordTypeId=cmpgnRt.getRecordTypeId());
        insert cmp;
        
        
        
        //create acct, ctct, opty, referral, partner ref 
        CreateTestData.createTestAandC();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Contact ctct = [Select Id, FirstName, LastName from Contact where FirstName = 'First' and LastName = 'Last1'];
        
        Id optyId = CreateTestData.createTestCoreOptys(acct.Id, ctct.Id);
        Opportunity opty = [Select Id, Name, AccountId, StageName, NSS_Source__c from Opportunity where Id = :optyId];
        // create referral with contact and opty info
        Referral__c ctctRef = new Referral__c();
        ctctRef.Name = opty.Name;
        ctctRef.Account__c = acct.Id;
        ctctRef.SourceContact__c = ctct.Id;
        ctctRef.Campaign__c = cmp.Id;
        ctctRef.Selling_Opportunity__c = opty.Id;
        insert ctctRef;
        // create partner referral with ctct and (converted) lead info
        PartnerReferral__c ctctPartRef = new PartnerReferral__c();
        ctctPartRef.Company__c = acct.Name;        
        ctctPartRef.FirstName__c = ctct.FirstName;
        ctctPartRef.LastName__c = ctct.LastName;
        ctctPartRef.DateSubmitted__c = system.Today();
        ctctPartRef.Campaign__c = cmp.Id;
        ctctPartRef.CampaignId__c = String.valueOf(cmp.Id);
        ctctPartRef.Account__c = acct.Id;
        ctctPartRef.Contact__c = ctct.Id;
        //ctctPartRef.Lead__c = ld1.Id;     // do this after we insert a lead
        ctctPartRef.Source__c = 'ReferralController';
        ctctPartRef.Referral__c = ctctRef.Id;
        insert ctctPartRef;
        // put partner referral id onto referral
        ctctRef.PartnerReferral__c = ctctPartRef.Id;
        update ctctRef;
  
        User nssUser = [Select Id, Name from User where IsActive=true and Profile.Name = 'NSS Inbound Rep' and Sales_Org__c=:UserHelper.SO_NSS limit 1];
        
        Schema.RecordTypeInfo leadNSSrt = RecordTypeHelper.getRecordType('NSS Lead Record Type', ObjectHelper.OBJECT_LEAD);      
        Lead ld1 = new Lead(Firstname = 'First',Lastname = 'Last Lead1',Company = 'Test Lead Company1', Status='Contacted DM', Phone='(585) 123-4576'
                        ,recordtypeId = leadNSSrt.getRecordTypeId(),PostalCode='14414',DataFlux_Id__c = null,LeadGroupId__c = null);
        insert ld1;
        
        DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c();
        dsSession.Name = '96349f93-43da-47ad-b3d9-0ba81d605ec5 - 5d19f78a19c297001a87';
        dsSession.DS_Denali__Session_Date__c = system.now();
        insert dsSession;       
        
        Schema.RecordTypeInfo dsActionrt = RecordTypeHelper.getRecordType('Inbound', 'DS_Denali__DialSource_Action__c');        
        DS_Denali__DialSource_Action__c dsAction = new DS_Denali__DialSource_Action__c();
        //dsAction.OwnerId = nssUser.Id;
        dsAction.DS_Denali__Date__c = system.today();
        dsAction.DS_Denali__Lead__c = ld1.Id;
        dsAction.DS_Denali__Subject__c = 'Inbound Call';
        dsAction.DS_Denali__Call_Disposition__c = 'Inbound Call';
        dsAction.recordtypeId = dsActionrt.getRecordTypeId();
        dsAction.DS_Denali__Call_Campaign__c = '*Inbound*';
        dsAction.DS_Denali__DialSource_Session__c =dsSession.Id;
        dsAction.DS_Denali__Phone__c = '655-1212';
        dsAction.DS_Denali__Inbound_DNIS_Name__c = 'Branch 28';
        dsAction.DS_Denali__Inbound_DNIS__c = '15853049497';
        insert dsAction;
        
        User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_NSS limit 1]; // and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), WhoId=ld1.Id, 
                                Subject='Inbound Call', DS_Denali__DialSource_Action__c =dsAction.Id);
        insert tsk1;
        
        // inserting the task creates the partner referral and referral
        Task leadTask = [Select Id, WhatId, WhoId, Subject from Task where whoId = :ld1.Id];
        System.assertNotEquals(null, leadTask);
        System.assertEquals('Inbound Call',leadTask.Subject);
        PartnerReferral__c leadPR = [Select Id, Account__c, Contact__c, Lead__c, Source__c,Disposition__c, Referral__c
                                    from PartnerReferral__c where Lead__c = :ld1.Id];
        System.assertNotEquals(null, leadPR);
        System.assertEquals('Inbound Call', leadPR.Source__c);                              
        Referral__c leadRef = [Select Id, Name, Account__c, SourceContact__c, SourceLead__c, PartnerReferral__c 
                                from Referral__c where SourceLead__c = :ld1.Id];
        System.assertNotEquals(null, leadRef);
        System.assertEquals(leadPR.Id, leadRef.PartnerReferral__c); 
       
        // update contact part ref with lead id
        ctctPartRef.Lead__c = ld1.Id;
        update ctctPartRef;
       
             
        // do we have duplicate records like we want
        Referral__c[] referralList = [Select Id, Account__c, SourceContact__c, SourceLead__c from Referral__c 
                                        where SourceContact__c = :ctct.Id or SourceLead__c = :ld1.Id];
        System.assertEquals(2, referralList.size());
        PartnerReferral__c[] partnerRefList = [Select Id, Account__c, Contact__c, Lead__c from PartnerReferral__c
                                                where Contact__c = :ctct.Id or Lead__c = :ld1.Id];
        System.assertEquals(2, partnerRefList.size());
        
        // run search and destroy, I mean update, code                                                      
        PartnerReferralSearch prs = new PartnerReferralSearch(acct.Id, null, null, ld1.Id);
        prs.qContext = 'contextId 123456';
        prs.partRefSearch();
        
        // make sure lead referral was deleted 
        Referral__c[] deletedRefList = [Select Id, Account__c, SourceContact__c, SourceLead__c from Referral__c 
                                        where SourceLead__c = :ld1.Id and Account__c = null];
        System.assertEquals(true, deletedRefList.isEmpty());
        
        // make sure lead partner referral was deleted 
        PartnerReferral__c[] deletedPartRefList = [Select Id, Account__c, Contact__c, Lead__c, Source__c from PartnerReferral__c
                                                where Id = :leadPR.Id];
        System.assertEquals(true, deletedPartRefList.isEmpty());
        
        //make sure contact partner referral was updated
        PartnerReferral__c updatedPartRef = [Select Id, Account__c, Contact__c, Lead__c, Source__c, ProspectContactName__c from PartnerReferral__c
                                                where Id = :ctctPartRef.Id];
        System.assertEquals(ld1.FirstName+' '+ld1.LastName, updatedPartRef.ProspectContactName__c);
        System.assertEquals('Inbound Call', updatedPartRef.Source__c);
        
        // make sure task was changed from lead to contact       
        Task updatedTask = [Select Id, WhatId, WhoId, Subject from Task where whoId = :ctct.Id];
        System.assertEquals('Inbound Call', updatedTask.Subject);
        
        // make sure the DialSource Action was updated from lead to contact
        DS_Denali__DialSource_Action__c updatedAction = [Select Id, DS_Denali__Account__c, DS_Denali__Contact__c, DS_Denali__Lead__c
                                                            from  DS_Denali__DialSource_Action__c where DS_Denali__Lead__c = :ld1.Id];
        System.assertEquals(ctct.Id, updatedAction.DS_Denali__Contact__c);                                                          
        
        // make sure job tracker record was inserted
        Job_Tracker__c[] jtList = [Select Id, Name, Job_Name__c, Job_Id__c, Notes__c From Job_Tracker__c where Job_Name__c = 'PartnerReferralSearch'];
        System.assertEquals(1, jtList.size());
        System.assert(jtList.get(0).Notes__c.startsWith('Processing acct'));
        System.assertEquals('contextId 123456',jtList.get(0).Job_Id__c);
        
        // make sure no JobTracker was created if there were no valid Partner Referrals
        Lead ld2 = new Lead(Firstname = 'Second',Lastname = 'Last Lead2',Company = 'Test Lead Company2', Status='Contacted DM', Phone='(585) 321-4576'
                        ,recordtypeId = leadNSSrt.getRecordTypeId(),PostalCode='14414',DataFlux_Id__c = null,LeadGroupId__c = null);
        insert ld2;
        PartnerReferralSearch prs2 = new PartnerReferralSearch(null, null, ld2.Id);        
        prs2.qContext = 'contextId 234567';
        prs2.partRefSearch();
        Job_Tracker__c[] jtList2 = [Select Id, Name, Job_Name__c, Job_Id__c, Notes__c From Job_Tracker__c where Job_Id__c = 'contextId 234567'];
        System.assertNotEquals(true, jtList2.isEmpty());
        //System.assert(jtList2.get(0).Notes__c.containsIgnoreCase('No Inbound Call '));
         
    } // test1
    
   static testMethod void test2() {
        // perhaps I need the Task trigger interface stuff
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting('TaskAfter', false, true, new String[]{'TaskHelper'},setupClasses, TriggerMethods.INTERFACE_B);
        insert setupClasses;
        Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = PartnerReferralSearch.CLASS_NAME, Active__c = true, BatchSize__c=1, Minutes_till_Launch__c=1,LogProcess__c=true);
        insert abc; 
       
        Schema.RecordTypeInfo cmpgnRt = RecordTypeHelper.getRecordType('Marketing Record Type', 'Campaign');
        Campaign cmp = new Campaign(Name = 'Marketing Campaign TEST', Status='In Progress',StartDate = System.TODAY(), IsActive=true, NSS_Inbound__c=true,
                                    Originator__c='Marketing', ACD_Name__c='ACDTest1', 
                                    LeadSource__c='Corp Marketing-Web', Type='Corp Marketing-Web', RecordTypeId=cmpgnRt.getRecordTypeId());
        insert cmp;
        
        
        
        //create acct, ctct, opty, referral, partner ref 
        CreateTestData.createTestAandC();
        Account acct = [Select Id, Name from Account where Name = 'Test Account1'];
        Contact ctct = [Select Id, FirstName, LastName from Contact where FirstName = 'First' and LastName = 'Last1'];
        
        Id optyId = CreateTestData.createTestCoreOptys(acct.Id, ctct.Id);
        Opportunity opty = [Select Id, Name, AccountId, StageName, NSS_Source__c from Opportunity where Id = :optyId];
        // create referral with contact and opty info
        Referral__c ctctRef = new Referral__c();
        ctctRef.Name = opty.Name;
        ctctRef.Account__c = acct.Id;
        ctctRef.SourceContact__c = ctct.Id;
        ctctRef.Campaign__c = cmp.Id;
        ctctRef.Selling_Opportunity__c = opty.Id;
        insert ctctRef;
        // create partner referral with ctct and (converted) lead info
        PartnerReferral__c ctctPartRef = new PartnerReferral__c();
        ctctPartRef.Company__c = acct.Name;        
        ctctPartRef.FirstName__c = ctct.FirstName;
        ctctPartRef.LastName__c = ctct.LastName;
        ctctPartRef.DateSubmitted__c = system.Today();
        ctctPartRef.Campaign__c = cmp.Id;
        ctctPartRef.CampaignId__c = String.valueOf(cmp.Id);
        ctctPartRef.Account__c = acct.Id;
        ctctPartRef.Contact__c = ctct.Id;
        //ctctPartRef.Lead__c = ld1.Id;     // do this after we insert a lead
        ctctPartRef.Source__c = 'ReferralController';
        ctctPartRef.Referral__c = ctctRef.Id;
        insert ctctPartRef;
        // put partner referral id onto referral
        ctctRef.PartnerReferral__c = ctctPartRef.Id;
        update ctctRef;
  
        User nssUser = [Select Id, Name from User where IsActive=true and Profile.Name = 'NSS Inbound Rep' and Sales_Org__c=:UserHelper.SO_NSS limit 1];
        
        Schema.RecordTypeInfo leadNSSrt = RecordTypeHelper.getRecordType('NSS Lead Record Type', ObjectHelper.OBJECT_LEAD);      
        Lead ld1 = new Lead(Firstname = 'First',Lastname = 'Last Lead1',Company = 'Test Lead Company1', Status='Contacted DM', Phone='(585) 123-4576'
                        ,recordtypeId = leadNSSrt.getRecordTypeId(),PostalCode='14414',DataFlux_Id__c = null,LeadGroupId__c = null);
        insert ld1;
        
        DS_Denali__DialSource_Sessions_V3__c dsSession = new DS_Denali__DialSource_Sessions_V3__c();
        dsSession.Name = '96349f93-43da-47ad-b3d9-0ba81d605ec5 - 5d19f78a19c297001a87';
        dsSession.DS_Denali__Session_Date__c = system.now();
        insert dsSession;       
        
        Schema.RecordTypeInfo dsActionrt = RecordTypeHelper.getRecordType('Inbound', 'DS_Denali__DialSource_Action__c');        
        DS_Denali__DialSource_Action__c dsAction = new DS_Denali__DialSource_Action__c();
        //dsAction.OwnerId = nssUser.Id;
        dsAction.DS_Denali__Date__c = system.today();
        dsAction.DS_Denali__Lead__c = ld1.Id;
        dsAction.DS_Denali__Subject__c = 'Inbound Call';
        dsAction.DS_Denali__Call_Disposition__c = 'Inbound Call';
        dsAction.recordtypeId = dsActionrt.getRecordTypeId();
        dsAction.DS_Denali__Call_Campaign__c = '*Inbound*';
        dsAction.DS_Denali__DialSource_Session__c =dsSession.Id;
        dsAction.DS_Denali__Phone__c = '655-1212';
        dsAction.DS_Denali__Inbound_DNIS_Name__c = 'Branch 28';
        dsAction.DS_Denali__Inbound_DNIS__c = '15853049497';
        insert dsAction;
        
        User testUsr = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_NSS limit 1]; // and Job_Name__c=:UserHelper.JOB_REP limit 1];
        Task tsk1 = new Task(OwnerId=testUsr.Id, ActivityDate=Date.today(), WhoId=ld1.Id, 
                                Subject='Inbound Call', DS_Denali__DialSource_Action__c =dsAction.Id);
        insert tsk1;
        
        // inserting the task creates the partner referral and referral
        Task leadTask = [Select Id, WhatId, WhoId, Subject from Task where whoId = :ld1.Id];
        System.assertNotEquals(null, leadTask);
        System.assertEquals('Inbound Call',leadTask.Subject);
        PartnerReferral__c leadPR = [Select Id, Account__c, Contact__c, Lead__c, Source__c,Disposition__c, Referral__c
                                    from PartnerReferral__c where Lead__c = :ld1.Id];
        System.assertNotEquals(null, leadPR);
        System.assertEquals('Inbound Call', leadPR.Source__c);                              
        Referral__c leadRef = [Select Id, Name, Account__c, SourceContact__c, SourceLead__c, PartnerReferral__c 
                                from Referral__c where SourceLead__c = :ld1.Id];
        System.assertNotEquals(null, leadRef);
        System.assertEquals(leadPR.Id, leadRef.PartnerReferral__c); 
        
        // update ctct part ref with lead id
        ctctPartRef.Lead__c = ld1.Id;
        update ctctPartRef;
        // update lead part ref with acct,ctct ids
        leadPR.Account__c = acct.Id;
        leadPR.Contact__c = ctct.Id;
        update leadPR;
       
             
        // do we have duplicate records like we want
        Referral__c[] referralList = [Select Id, Account__c, SourceContact__c, SourceLead__c from Referral__c 
                                        where SourceContact__c = :ctct.Id or SourceLead__c = :ld1.Id];
        System.assertEquals(2, referralList.size());
        PartnerReferral__c[] partnerRefList = [Select Id, Account__c, Contact__c, Lead__c from PartnerReferral__c
                                                where Contact__c = :ctct.Id or Lead__c = :ld1.Id];
        System.assertEquals(2, partnerRefList.size());
        
        // run search and destroy, I mean update, code                                                      
        PartnerReferralSearch prs = new PartnerReferralSearch(acct.Id, ctct.Id, null, ld1.Id);
        prs.qContext = 'contextId 123456';
        Test.startTest();
        PartnerReferralSearch.launchQueueable(prs);
        Test.stopTest();
        //prs.partRefSearch();
        
        // make sure lead referral was deleted 
        Referral__c[] deletedRefList = [Select Id, Account__c, SourceContact__c, SourceLead__c from Referral__c 
                                        where SourceLead__c = :ld1.Id and Account__c = null];
        System.assertEquals(true, deletedRefList.isEmpty());
        
        // make sure lead partner referral was deleted 
        PartnerReferral__c[] deletedPartRefList = [Select Id, Account__c, Contact__c, Lead__c, Source__c from PartnerReferral__c
                                                where Id = :leadPR.Id];
        System.assertEquals(true, deletedPartRefList.isEmpty());
        
        //make sure contact partner referral was updated
        PartnerReferral__c updatedPartRef = [Select Id, Account__c, Contact__c, Lead__c, Source__c, ProspectContactName__c, DialSource_Action__c from PartnerReferral__c
                                                where Id = :ctctPartRef.Id];
        System.assertEquals(ld1.FirstName+' '+ld1.LastName, updatedPartRef.ProspectContactName__c);
        System.assertEquals('Inbound Call', updatedPartRef.Source__c);
        System.assertEquals(dsAction.Id, updatedPartRef.DialSource_Action__c);
        
        // make sure task was changed from lead to contact       
        Task updatedTask = [Select Id, WhatId, WhoId, Subject from Task where whoId = :ctct.Id];
        System.assertEquals('Inbound Call', updatedTask.Subject);
        
        // make sure the DialSource Action was updated from lead to contact
        DS_Denali__DialSource_Action__c updatedAction = [Select Id, DS_Denali__Account__c, DS_Denali__Contact__c, DS_Denali__Lead__c
                                                            from  DS_Denali__DialSource_Action__c where DS_Denali__Lead__c = :ld1.Id];
        System.assertEquals(ctct.Id, updatedAction.DS_Denali__Contact__c);                                                          
        
        // make sure job tracker record was inserted
        Job_Tracker__c[] jtList = [Select Id, Name, Job_Name__c, Job_Id__c, Notes__c From Job_Tracker__c where Job_Name__c = 'PartnerReferralSearch'];
        Assert.areEqual(1, jtList.size());
        Assert.isTrue(jtList.get(0).Notes__c.startsWith('Processing acct'));
        //System.assertEquals('contextId 123456',jtList.get(0).Job_Id__c);
        Assert.isTrue(jtList.get(0).Job_Id__c.startsWith('707'));
        
        // make sure no JobTracker was created if there were no valid Partner Referrals
        Lead ld2 = new Lead(Firstname = 'Second',Lastname = 'Last Lead2',Company = 'Test Lead Company2', Status='Contacted DM', Phone='(585) 321-4576'
                        ,recordtypeId = leadNSSrt.getRecordTypeId(),PostalCode='14414',DataFlux_Id__c = null,LeadGroupId__c = null);
        insert ld2;
        PartnerReferralSearch prs2 = new PartnerReferralSearch(null, null, ld2.Id);        
        prs2.qContext = 'contextId 234567';
        prs2.partRefSearch();
        Job_Tracker__c[] jtList2 = [Select Id, Name, Job_Name__c, Job_Id__c, Notes__c From Job_Tracker__c where Job_Id__c = 'contextId 234567'];
        System.assertNotEquals(true, jtList2.isEmpty());
        //System.assert(jtList2.get(0).Notes__c.containsIgnoreCase('No Inbound Call '));
         
    } // test2
    
} // class PartnerReferralSearchTest