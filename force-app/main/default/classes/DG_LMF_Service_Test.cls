/**********************************************************/
/* 
  This is the test class of DG_LMF_Service
   
  History
  -------
  06/19/2018 Gram Bischof        Created
  08/01/2018 Gram Bischof
  08/17/2018 Dan Carmen          Changes to handle different time zones.
  09/18/2018 Dan Carmen          Populate Contact Stages on the Account
  10/02/2018 Dan Carmen          Add in a Stage History record
  01/04/2019 Dan Carmen          Change to how Opportunities are handled
  07/25/2019 Dan Carmen          Update tests to clear ids
  10/15/2019 Dan Carmen          Update to use TriggerMethods.clearVariables
  01/18/2021 Dan Carmen          Add in OwnedBy__c field
  08/30/2021 Pujitha Madamanchi  APR0122715: Populate Reject Recycle Reason on PR.
  10/12/2021 Dan Carmen          Include logic to add to a cadence based on hitting a stage - checkLatestCampaign
  02/17/2023 Pujitha Madamanchi  APR0148916: Car owner should be set to who TAL'ed it if its NSS/VSR.
  07/06/2023 Pujitha Madamanchi  Remove Last Cadence Step completed field reference.
  01/31/2024 Dan Carmen          Comment out logic for Opportunity accept/reject fields
  

*/

@isTest
public class DG_LMF_Service_Test {
    
   @testSetup
   public static void setup(){
      String[] classString = new String[]{'DG_LMF_Service'};
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, classString);
      TriggerMethodsTest.createTriggerSetting('ReferralTrigger', false, true, false, false, classString);
      TriggerMethodsTest.saveSetupClasses();

      BusinessHours  defaultHours = [Select id From BusinessHours Where isDefault=true];
      Business_Hours_Assignment__c bizassign = new Business_Hours_Assignment__c(Name='Default Admin',UserId__c = UserINfo.getUserID(),Business_Hours_Id__c=defaultHours.id);
      insert bizassign;
        
      Apex_Batch_Control__c  apcSLA = new Apex_Batch_Control__c(Name='SLAHandler',Active__c=True);
      Apex_Batch_Control__c  apcExp = new Apex_Batch_Control__c(Name='ExpirationHandler',Active__c=True);
      Apex_Batch_Control__c[] abcs = new Apex_Batch_Control__c[]{apcSLA,apcExp};
      insert abcs;
        
      Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
      
      Lead testLead = new Lead(Firstname = 'First'
                                ,Lastname = 'Testing'
                                ,Company = 'Test Lead Company'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,NumberOfEmployees = 10
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null
                                ,Lead_Stage__c = 'Suspect');
      //DG_LMF_Service.SKIP_FUTURE=true;
      insert testLead;
      //DG_LMF_Service.SKIP_TRIGGER=false;
        
      User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];      
      Account testAccount = new Account(Name='TestAccount',OwnerId=testSalesRep.Id);
      insert testAccount;

      LeadLoaderConfig__c config = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c='Test Inbound', UseAssignmentRules__c=false);
      insert config;

   } // setup
   
   public static Lead getTestLead() {
      Lead testLead = [Select Id, Name, FirstName, LastName, Company
                              ,RecordTypeId, NumberOfEmployees, Lead_Stage__c
                              //,Next_Cadence_Follow_up_Date__c //Vinay
                          From Lead 
                         Where Company = 'Test Lead Company' limit 1];
      return testLead;
   } // getTestLead
    
   public static Account getTestAcct() {
      Account testAcct = [Select Id, Name, OwnerId, Owner.Id, Owner.Name from Account where Name='TestAccount' limit 1];
      return testAcct;
   } // getTestAcct
 
   public static LeadLoaderConfig__c getInboundConfig() {
      return LeadLoaderConfig__c.getInstance('Test Inbound');
   } // getInboundConfig
   
   public static Lead queryLead(Id leadId) {
      Lead ld = [Select Id, Name, Lead_Stage__c 
                 //,Next_Cadence_Follow_up_Date__c //Vinay
                    From Lead where Id=:leadId];
      return ld;
   } // queryLead
   
   public static void resetTests() {
      DG_LMF_Service.idsProcessedSet.clear();
      DG_LMF_Service.ALREADY_RAN_SET.clear();
      TriggerMethods.clearVariables();
      
   }
   
   public static testMethod void testDGLMFServiceLead() {
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
        
       
        Lead testLead = getTestLead();
        Referral__c testref = new Referral__c(Name = 'test ref'                      
                                              ,SourceLead__c = testLead.Id
                                              ,status__c = 'Pending');
        
        insert testref;
        
        Test.startTest();
        testLead.Lead_Stage__c = 'MQL';
        resetTests();
        update testLead;
        Test.stopTest();
        
        //List<CronTrigger> schedJobs = [Select id,state,NextFireTime From CronTrigger Where CronJobDetail.Name = 'SLAHandler'];
        //System.assertEquals(1,schedJobs.size());

        List<Stage_History__c> shs = [Select id,Lead__c From Stage_History__c Where Lead__c = :testLead.id];
        testLead = [Select id,ConvertedContactId,ConvertedAccountId,ConvertedOpportunityId From Lead Where ID =:testLead.id];
        System.assertNotEquals(0,shs.size());
    }
    
    public static testMethod void testDGLMFServiceContact() {
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id, Contact_Stage__c='TQO',OwnedBy__c=config.QueueName__c);
        Test.startTest();
        insert testContact;
        testContact.Contact_Stage__c = 'Client';
        resetTests();
        update testContact;
        Test.stopTest();
        List<Stage_History__c> shs = [Select id,Contact__c From Stage_History__c Where Contact__c = :testContact.id];
        System.assertNotEquals(0,shs.size());
        Account acct = [Select Id, ContactStages__c from Account where Id=:testAccount.Id];
        System.assertEquals('Client;',acct.ContactStages__c);
        
    } // testDGLMFServiceContact

    public static testMethod void testUpdateConStageFromOppStageSingleOpp() {
    
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c, Contact_Stage__c='Inquiry');
        insert testContact;
        
        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity testOpportunity = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                             ,StageName=dsc.Field_Value__c
                                             ,Reason_Not_Sold__c = 'External Partnership'
                                             ,Reason_Not_Sold_Details__c = 'Bank'
                                             ,CloseDate=Date.today().addDays(30)
                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                             ,Payroll_Platform__c = 'MMS'
                                             ,OwnerId=UserInfo.getUserId()
                                             ,Chatter_Manager_SLA__c=true);
        insert testOpportunity;
        
        Referral__c testref = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = testOpportunity.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending');

        Test.startTest();
        insert testref;

        // get the next opportunity stage
        DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SAO' limit 1];

        testOpportunity.stageName = dsc2.Field_Value__c;
        resetTests();
        update testOpportunity;
        Test.stopTest();
        
        // assert the contact_stage__c = TQO not blank
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        System.assertEquals('SAO',Contacttest.Contact_Stage__c);
    }  

    public static testMethod void testUpdateConStageFromOppStageDualOpp() {
    
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c,Contact_Stage__c='TAL');
        insert testContact;
        
        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];

        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        List<Opportunity> testOpps = new List<Opportunity>();
        Opportunity testOpportunityOne = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                             ,StageName=dsc.Field_Value__c
                                             ,CloseDate=Date.today().addDays(30)
                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                             ,Payroll_Platform__c = 'MMS'
                                             ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunityOne);
        
        Opportunity testOpportunityTwo = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                             ,StageName=dsc.Field_Value__c
                                             ,CloseDate=Date.today().addDays(30)
                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                             ,Payroll_Platform__c = 'MMS'
                                             ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunityTwo);
        insert testOpps;
        
        List<Referral__c> testReferrals = new List<Referral__c>();
        Referral__c testrefOne = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = testOpportunityOne.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending');
        testReferrals.add(testrefOne);
        
        Referral__c testrefTwo = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = testOpportunityTwo.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending');
        testReferrals.add(testrefTwo);
        insert testReferrals;
        
        System.assertNotEquals(0,testOpportunityOne.Probability);
        System.assertNotEquals(0,testOpportunityTwo.Probability);
        
        DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='Recycle' limit 1];
        Test.startTest();
        testOpportunityOne.stageName = dsc2.Field_Value__c;
        testOpportunityOne.Reason_Not_Sold__c = 'External Partnership';
        testOpportunityOne.Reason_Not_Sold_Details__c = 'Bank';
        resetTests();
        update testOpportunityOne;
        Test.stopTest();
        
        testOpportunityOne = [Select id,Probability From Opportunity Where Id = :testOpportunityOne.Id];
        System.assertEquals(0,testOpportunityOne.Probability);
        
        testOpportunityTwo = [Select id,Probability From Opportunity Where Id = :testOpportunityTwo.Id];
        System.assertNotEquals(0,testOpportunityTwo.Probability);
        
        // asser the contact_stage__c = TQO not blank
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        System.assertEquals('TQO',Contacttest.Contact_Stage__c);
    }
    
    public static testMethod void testUpdateConStageFromOppStageDualOppSAO() {
    
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        
        Contact testContact = new Contact(LastName='NewLast', AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c,Contact_Stage__c='TAL');
        insert testContact;
        
        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];
        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        List<Opportunity> testOpps = new List<Opportunity>();
        Opportunity testOpportunityOne = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                             ,StageName=dsc.Field_Value__c
                                             ,CloseDate=Date.today().addDays(30)
                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                             ,Payroll_Platform__c = 'MMS'
                                             ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunityOne);
        
        Opportunity testOpportunityTwo = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                             ,StageName=dsc.Field_Value__c
                                             ,CloseDate=Date.today().addDays(30)
                                             ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                             ,Payroll_Platform__c = 'MMS'
                                             ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunityTwo);
        insert testOpps;
        
        List<OpportunityContactRole> opcrs = new List<OpportunityContactRole>();
        opcrs.add(new OpportunityContactRole(OpportunityID=testOpportunityOne.id,ContactId=testContact.id,Role='Decision Maker'));
        opcrs.add(new OpportunityContactRole(OpportunityID=testOpportunityTwo.id,ContactId=testContact.id,Role='Decision Maker'));
        insert opcrs;
        
        List<Referral__c> testReferrals = new List<Referral__c>();
        Referral__c testrefOne = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = testOpportunityOne.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Approved');
        testReferrals.add(testrefOne);
        
        Referral__c testrefTwo = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = testOpportunityTwo.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Approved');
        testReferrals.add(testrefTwo);
        insert testReferrals;
        
        Test.startTest();

        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SAO' limit 1];
        // get the recycle stage
        DFR_Stage_conversion__mdt dsc3 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='Recycle' limit 1];

        testOpportunityOne.stageName = dsc2.Field_Value__c;
        resetTests();
        update testOpportunityOne;
        
        testOpportunityTwo.stageName = dsc3.Field_Value__c;
        testOpportunityTwo.Reason_Not_Sold__c = 'Duplicate Opportunity';
        DG_LMF_Service.idsProcessedSet.clear();
        update testOpportunityTwo;
        Test.stopTest();
        
        testOpportunityOne = [Select id,Probability From Opportunity Where Id = :testOpportunityOne.Id];
        System.assertNotEquals(0,testOpportunityOne.Probability);
        
        testOpportunityTwo = [Select id,Probability From Opportunity Where Id = :testOpportunityTwo.Id];
        System.assertEquals(0,testOpportunityTwo.Probability);
        
        // asser the contact_stage__c = TQO not blank
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        System.assertEquals('SAO',Contacttest.Contact_Stage__c);
    }
    
    
    public static testMethod void testUpdateConStageFromOppStageMultiOppNoLinks() {
        // Create Account and Contact for testing.
        // Contact should have a Contact_Stage__c = MQL  
        
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        
        Contact testContact = new Contact(LastName='NewLast',Contact_Stage__c='MQL',AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c);
        insert testContact;      

        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];

        // Create 3 Opportunities that map to  contacts
        List<Opportunity> oppList = new List<Opportunity>();
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        for(integer i=0; i<3;i++) {
            Opportunity testOpportunity = new Opportunity(Name='Test Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
            oppList.add(testOpportunity);
        }    
        insert oppList;
        
        // Create referrals for all opportunities that map to contact
        List<Referral__c> referralList = new List<Referral__c>();
        for(Opportunity theOpp : oppList) {
            Referral__c testref = new Referral__c(Name = 'test ref'
                                              ,Selling_Opportunity__c = theOpp.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending');    
            referralList.add(testref);
        }
        
        // get the second opportunity stage
        DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SAO' limit 1];
        // get the recycle stage
        DFR_Stage_conversion__mdt dsc3 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='Recycle' limit 1];

        Test.startTest();
            insert referralList;
            oppList[0].StageName = dsc3.Field_Value__c; 
            oppList[1].StageName = dsc2.Field_Value__c;
            //oppList[2].Probability = 10;
        resetTests();
            update oppList;
        Test.stopTest();
        // Assert contact_stage__c = SAO 
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        System.assertEquals('SAO',Contacttest.Contact_Stage__c);
    }

    public static testMethod void testUpdateConStageFromOppStageMultiOppLinked() {
        // Create Account Contact for testing.
        // Contact should have a Contact_Stage__c = MQL 
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();
        
        Contact testContact = new Contact(LastName='NewLast',Contact_Stage__c='MQL',AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c);
        insert testContact;             

        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];

        // Create 3 Opportunities that map to contacts with first Opp OpportunityType__c = Payroll
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity testOpportunity1 = new Opportunity(Name='Test Opporty1', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,OpportunityType__c = 'Payroll'
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        Opportunity testOpportunity2 = new Opportunity(Name='Test Opporty2', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,OpportunityType__c='Ancillary'
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        Opportunity testOpportunity3 = new Opportunity(Name='Test Opporty3', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,OpportunityType__c='Ancillary'
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        Opportunity[] opps = new Opportunity[]{testOpportunity1,testOpportunity2,testOpportunity3};
        insert opps;
        
        List<Opportunity> nonPayrollOpps = [Select id,OpportunityType__c From Opportunity Where Id IN :new List<Opportunity>{testOpportunity2,testOpportunity3}];
        for(Opportunity testOpp: nonPayrollOpps){
            System.assertNotEquals('Payroll',testOpp.OpportunityType__c);
        }
        
        
        // Create referrals for all opportunities that map to contact
        Referral__c testref1 = new Referral__c(Name = 'test ref1'
                                              ,Selling_Opportunity__c = testOpportunity1.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        Referral__c testref2 = new Referral__c(Name = 'test ref2'
                                              ,Selling_Opportunity__c = testOpportunity2.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        Referral__c testref3 = new Referral__c(Name = 'test ref3'
                                              ,Selling_Opportunity__c = testOpportunity3.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        
        Referral__c[] refs = new Referral__c[]{testref1,testref2,testref3};
        insert refs;
        
        // Create referralJoin__c records for referrals
        ReferralJoin__c testrj = new ReferralJoin__c(PAS_Referral__c = testref1.Id
                                                    ,MMS_Referral__c = testref2.Id
                                                    ,Core_Referral__c = testref3.Id);
        insert testrj;
        // 
        // Start test
        Test.startTest();
            // get the second opportunity stage
            DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SAO' limit 1];
            
            testOpportunity1.stageName = dsc2.Field_Value__c;  
            resetTests();
            update testOpportunity1;
            
        Test.stopTest();
        // 
        // Assert contact_stage__c = TQO 
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        // this should be SAO for multiple opps.
        System.assertEquals('SAO',Contacttest.Contact_Stage__c);
    }

    public static testMethod void testUpdateConStageFromOppStageMultiOppLinkedSAO() {
        // Create Account Contact for testing.
        // Contact should have a Contact_Stage__c = MQL  
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();

        Contact testContact = new Contact(LastName='NewLast',Contact_Stage__c='MQL',AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c);
        insert testContact;       

        // get the first opportunity stage
        DFR_Stage_conversion__mdt dsc = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='TQO' limit 1];

        // Create 3 Opportunities that map to contacts with first Opp OpportunityType__c = Payroll
        List<Opportunity> testOpps = new List<Opportunity>();
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,'Opportunity');
        Opportunity testOpportunity1 = new Opportunity(Name='Test Opporty1', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,OpportunityType__c = 'Payroll'
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunity1);
        Opportunity testOpportunity2 = new Opportunity(Name='Test Opporty2', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunity2);
        Opportunity testOpportunity3 = new Opportunity(Name='Test Opporty3', RecordTypeId=coreOpptyRt.getRecordTypeId(),AccountId=testAccount.Id
                                                 ,StageName=dsc.Field_Value__c
                                                 ,CloseDate=Date.today().addDays(30)
                                                 ,NSS_Source__c=ProspectOwnershipMethods.NSS_INBOUND
                                                 ,Payroll_Platform__c = 'MMS'
                                                 ,OwnerId=UserInfo.getUserId());
        testOpps.add(testOpportunity3);
        insert testOpps;
        // Create referrals for all opportunities that map to contact
        Referral__c testref1 = new Referral__c(Name = 'test ref1'
                                              ,Selling_Opportunity__c = testOpportunity1.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        Referral__c testref2 = new Referral__c(Name = 'test ref2'
                                              ,Selling_Opportunity__c = testOpportunity2.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        Referral__c testref3 = new Referral__c(Name = 'test ref3'
                                              ,Selling_Opportunity__c = testOpportunity3.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        Referral__c[] refs = new Referral__c[]{testref1,testref2,testref3};
        insert refs;
        
        // Create referralJoin__c records for referrals
        ReferralJoin__c testrj = new ReferralJoin__c(PAS_Referral__c = testref1.Id
                                                    ,MMS_Referral__c = testref2.Id
                                                    ,Core_Referral__c = testref3.Id);
        
        // Start test
        Test.startTest();
           // get the second opportunity stage
           DFR_Stage_conversion__mdt dsc2 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='SAO' limit 1];
           // get the recycle stage
           DFR_Stage_conversion__mdt dsc3 = [Select Id, Field_Value__c,Stage_Value__c from DFR_Stage_conversion__mdt where Stage_Value__c='Recycle' limit 1];
            testOpportunity1.stageName = dsc2.Field_Value__c;  
            testOpportunity2.stageName = dsc3.Field_Value__c;
            testOpps = new List<Opportunity>();
            testOpps.add(testOpportunity1);
            testOpps.add(testOpportunity2);
        resetTests();
            update testOpps;
        Test.stopTest();
        
        // Assert contact_stage__c = SAO 
        Contact Contacttest = [Select id,Contact_Stage__c From Contact Where Id = :testContact.id];
        System.assertEquals('SAO',Contacttest.Contact_Stage__c);
    }
    
    public static testMethod void testUpdateLeadStageToMQLReRouteOwner() {
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);        
        Referral__c ref = new Referral__c();
        ref.OwnerId = UserInfo.getUserId();
        insert ref;
        Lead testLead = new Lead(Firstname = 'First+034525'
                                ,Lastname = 'Testing+2452525'
                                ,Company = 'Test Lead Company+254254'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,NumberOfEmployees = 10
                                ,DataFlux_Id__c = null
                                ,OwnerId = UserInfo.getUserId()
                                ,LeadGroupId__c = null
                                ,Lead_Stage__c = 'Suspect'
                                ,Referral__c = ref.Id);
        Test.startTest();
        insert testLead;
        testLead.Lead_Stage__c = 'MQL';
        resetTests();
        update testLead;
        Test.stopTest();
        System.assertNotEquals(testLead.OwnerId,testLead.Referral__r.OwnerId);
        
    }
    
    public static testMethod void testUpdateContactStageToMQLReRouteOwner() {
        Account testAccount = getTestAcct();
        LeadLoaderConfig__c config = getInboundConfig();

        Contact testContact = new Contact(LastName='NewLast',OwnerId = UserInfo.getUserId(),Contact_Stage__c='TAL',AccountId=testAccount.Id,OwnedBy__c=config.QueueName__c);
        insert testContact; 
        Referral__c testref1 = new Referral__c(Name = 'test ref1'
                                              //,Selling_Opportunity__c = testOpportunity1.Id
                                              ,Account__c = testAccount.Id                                         
                                              ,SourceContact__c = testContact.Id
                                              ,status__c = 'Pending'); 
        insert testref1;
        Test.startTest();
        testContact.Contact_Stage__c = 'MQL';
        resetTests();
        update testContact;
        Test.stopTest();
        System.assertNotEquals(UserInfo.getUserId(),testref1.OwnerId);
    }  
    
    public static testMethod void testCreateSLATimesFirstStageHistoryNoSLA(){
        // Create SH with null old stage, Suspect new stage
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
        
        Lead testLead = new Lead(Firstname = 'First 1'
                                ,Lastname = 'Testing 1'
                                ,Company = 'Test Lead Company 1'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,NumberOfEmployees = 10
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null
                                ,Lead_Stage__c = 'Suspect');
        Test.startTest();
            insert testLead;
        Test.stopTest();
         
        // assert stage history has no deadlines
        List<Stage_History__c> shs = [Select Old_Stage__c ,New_Stage__c, SLA_Deadline__c, Expiration_Deadline__c From Stage_History__c Where Lead__c =:testLead.id];
        system.assertEquals(1,shs.size());
        system.assertEquals(null,shs.get(0).Old_Stage__c);
        system.assertEquals('Suspect',shs.get(0).New_Stage__c);
        system.assertEquals(null,shs.get(0).SLA_Deadline__c);
        system.assertEquals(null,shs.get(0).Expiration_Deadline__c);
        
    }
    
    public static testMethod void testCreateSLATimesFirstStageHistoryMQL(){
        // Create SH with Suspect old stage, MQL new stage
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
        
        Lead testLead = new Lead(Firstname = 'First+009767'
                                ,Lastname = 'Testing+009767'
                                ,Company = 'Test Lead Company+009767'
                                ,recordtypeId = leadCorert.getRecordTypeId()
                                ,NumberOfEmployees = 10
                                ,DataFlux_Id__c = null
                                ,LeadGroupId__c = null
                                ,Lead_Stage__c = 'MQL');
        Test.startTest();
            insert testLead;
        Test.stopTest();
         
        // assert stage history has no deadlines
        List<Stage_History__c> shs = [Select Old_Stage__c ,New_Stage__c, SLA_Deadline__c, Expiration_Deadline__c From Stage_History__c Where Lead__c =:testLead.id];
        system.assertEquals(1,shs.size());
        system.assertEquals(null,shs.get(0).Old_Stage__c);
        system.assertEquals('MQL',shs.get(0).New_Stage__c);
        system.assertNotEquals(null,shs.get(0).SLA_Deadline__c);
        system.assertNotEquals(null,shs.get(0).Expiration_Deadline__c);
    }
    
    public static testMethod void testCreateSLATimesSecondStageHistoryTAL(){
        
        Lead testLead = getTestLead();
        
        Test.startTest();
                testLead.Lead_Stage__c = 'MQL';
        resetTests();
                update testLead;
        Test.stopTest();
         
        // assert stage history has SLA deadline and expiration deadline
        List<Stage_History__c> shs = [Select Old_Stage__c ,New_Stage__c, SLA_Deadline__c, Expiration_Deadline__c From Stage_History__c Where Lead__c =:testLead.id ORDER BY Name];
        // Check first stage history
        system.assertEquals(null,shs.get(0).Old_Stage__c);
        system.assertEquals('Suspect',shs.get(0).New_Stage__c);
        system.assertEquals(null,shs.get(0).SLA_Deadline__c);
        system.assertEquals(null,shs.get(0).Expiration_Deadline__c);
        // Check second stage history
        system.assertEquals('Suspect',shs.get(1).Old_Stage__c);
        system.assertEquals('MQL',shs.get(1).New_Stage__c);
        system.assertNotEquals(null,shs.get(1).SLA_Deadline__c);
        system.assertNotEquals(null,shs.get(1).Expiration_Deadline__c);
        system.assertNotEquals(shs.get(1).SLA_Deadline__c,shs.get(1).Expiration_Deadline__c);
    }
    
    public static testMethod void testCreateSLATimesExpired(){
        
        Lead testLead = getTestLead();
        Datetime expirationDeadline = System.now().addMinutes(-15);
        Stage_History__c expiredSH = new Stage_History__c(Lead__c=testLead.id,Old_stage__c=testLead.Lead_Stage__c,New_Stage__c='MQL',Expiration_Deadline__c=expirationDeadline);
            
        Test.startTest();
        insert expiredSH;
        Test.stopTest();
        
        List<Stage_History__c> shs = [Select Id,  Old_Stage__c ,New_Stage__c, SLA_Deadline__c, Expiration_Deadline__c From Stage_History__c Where Lead__c =:testLead.id];
          System.assertEquals(2,shs.size());
        Map<Id,Stage_History__c> SHById = new Map<ID,Stage_History__c>(shs);
        system.assertEquals(expirationDeadline,SHById.get(expiredSH.id).Expiration_Deadline__c);
        //system.assertEquals(expirationDeadline,SHById.get(expiredSH.id).SLA_Deadline__c);
    }
    
    public static testMethod void testCreateSLATimes(){
        
        Lead testLead = getTestLead();
        Datetime expirationDeadline = System.now().addMinutes(15);
        Stage_History__c expiredSH = new Stage_History__c(Lead__c=testLead.id,Old_stage__c=testLead.Lead_Stage__c,New_Stage__c='MQL',Expiration_Deadline__c=expirationDeadline);
            
        Test.startTest();
                insert expiredSH;
        Test.stopTest();
        
        List<Stage_History__c> shs = [Select Id, Old_Stage__c ,New_Stage__c, SLA_Deadline__c, Expiration_Deadline__c From Stage_History__c Where Lead__c =:testLead.id];
        System.assertEquals(2,shs.size());
        Map<Id,Stage_History__c> SHById = new Map<ID,Stage_History__c>(shs);
        system.assertEquals(expirationDeadline,SHById.get(expiredSH.id).Expiration_Deadline__c);
        //system.assertEquals(expirationDeadline.addMinutes(-14).addSeconds(-expirationDeadline.second()),SHById.get(expiredSH.id).SLA_Deadline__c);
    }
    /*
    public static testMethod void testReRouteContactWithoutOpp(){
        
        // Create Account
        // Create Contact with stage with 
        // 
        // Referral -> Partner Referral -> Destination Queue field
        // 
        
        Test.startTest();
        Test.stopTest();
    }
    */
    public static testMethod void testLeadConvert(){
       
        Lead testLead = getTestLead();
        
        System.assertEquals(1,[select count() from Stage_History__c where Lead__c=:testLead.Id]);
        
        Database.LeadConvert lc = new Database.LeadConvert();
        Database.LeadConvertResult lcr;
        
        DG_LMF_Service.SKIP_FUTURE=false;
        Test.startTest();
        resetTests();
        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setLeadId(testLead.id);
        lc.setDoNotCreateOpportunity(true);
        lcr = Database.convertLead(lc);
        Test.stopTest();
        
        Lead checkLead = [Select Id, Name, IsConverted from Lead where Id=:testLead.Id];
        System.assertEquals(true,checkLead.IsConverted);
        
        Map<Id,Stage_History__c> leadSHs = new Map<Id,Stage_History__c>([Select id,Contact__c From Stage_History__c Where Lead__c = :testLead.id]);
        Map<Id,Stage_History__c> contactSHs = new Map<Id,Stage_History__c>([Select id,Lead__c From Stage_History__c Where Contact__c = :lcr.getContactId()]);
        
        System.assertEquals(1,leadSHs.size());
        System.assertEquals(leadSHs.size(),contactSHs.size());
        System.assertEquals(leadSHs.keySet(),contactSHs.keySet());
    } // testLeadConvert
/*
    public static testMethod void testReRouteLead(){
        
        // Create Lead with stage with 
        
        Test.startTest();
        Test.stopTest();
    } // testReRouteLead
    
    public static testMethod void testReRouteTALWithoutSLA(){
        
        // Create Lead with stage with 
        
        Test.startTest();
        Test.stopTest(); 
    } // testReRouteTALWithoutSLA
  */  
    static testMethod void testBusHours() {
       // should have default and Pacific time zones at least
       BusinessHours busHours = DG_LMF_Service.getBusinessHours('PT');
       System.assertEquals(DG_LMF_Service.DEFAULT_HOURS_NAME+'-PT', busHours.NAME);
       busHours = DG_LMF_Service.getBusinessHours('BadName');
       System.assertEquals(DG_LMF_Service.DEFAULT_HOURS_NAME, busHours.NAME);
    } // testBusHours

    static testMethod void testLeadStageChange() {
       Lead testLead = getTestLead();
       DG_LMF_Service.SKIP_FUTURE = true;
       testLead.Lead_Stage__c = 'Inquiry';
       System.debug('testLeadStageChange test 1');
       update testLead;
       // stages Suspect -> Inquiry
       
       // 1 stage record should be created
       //Stage_History__c[] histories = getStageHistory(testLead.Id);
       Map<String,Stage_History__c> historyMap = getStageHistoryMap(testLead.Id);
       System.assertEquals(2,historyMap.size());
       //System.assertEquals('Inquiry',histories[0].New_Stage__c);
       System.assertEquals(true, historyMap.containsKey('Inquiry'));
       
       //testLead.Next_Cadence_Follow_up_Date__c = Date.today().addDays(7);
       // stages Suspect -> Inquiry -> MQL
       testLead.Lead_Stage__c = 'MQL';
        resetTests();
       System.debug('testLeadStageChange test 2');
       update testLead;

       testLead = queryLead(testLead.Id);
       //System.assertEquals(Date.today().addDays(7),testLead.Next_Cadence_Follow_up_Date__c);
       
       //histories = getStageHistory(testLead.Id);
       historyMap = getStageHistoryMap(testLead.Id);
       System.assertEquals(3,historyMap.size());
       Stage_History__c latestStage = historyMap.get('MQL');
       Stage_History__c prevStage = historyMap.get('Inquiry');
       System.debug('testLeadStageChange 2 latestStage='+latestStage);
       System.debug('testLeadStageChange 2 prevStage='+prevStage);
       
       System.assertEquals('MQL',latestStage.New_Stage__c);
       
       
       // check the previous history
       System.assertEquals(null, prevStage.Last_Cadence_Step_Completed__c);
       //System.assertEquals(null, prevStage.Next_Cadence_Follow_up_Date__c); //Vinay
       System.assertEquals(latestStage.Id,prevStage.NextStage__c);
       System.assertEquals(prevStage.Id,latestStage.Previous_Stage__c);
       
       // stages Suspect -> Inquiry -> MQL -> TAL
       //testLead.Next_Cadence_Follow_up_Date__c = Date.today().addDays(9); //Vinay
       testLead.Lead_Stage__c = 'TAL';
       resetTests();
       System.debug('testLeadStageChange test 3');
       update testLead;

       testLead = queryLead(testLead.Id);
       //System.assertEquals(Date.today().addDays(9),testLead.Next_Cadence_Follow_up_Date__c);//Vinay
       
       //histories = getStageHistory(testLead.Id);
       historyMap = getStageHistoryMap(testLead.Id);
       System.assertEquals(4,historyMap.size());
       latestStage = historyMap.get('TAL');
       prevStage = historyMap.get('MQL');
       System.debug('testLeadStageChange 3 latestStage='+latestStage);
       System.debug('testLeadStageChange 3 prevStage='+prevStage);
       
       System.assertEquals(null, prevStage.Last_Cadence_Step_Completed__c);
       //System.assertEquals(null, prevStage.Next_Cadence_Follow_up_Date__c); //Vinay
       System.assertEquals(latestStage.Id,prevStage.NextStage__c);
       System.assertEquals(prevStage.Id,latestStage.Previous_Stage__c);
       
       // stages Suspect -> Inquiry -> MQL -> TAL -> Reject
       //testLead.Next_Cadence_Follow_up_Date__c = Date.today().addDays(11); //Vinay
       testLead.Lead_Stage__c = 'Reject';
       testLead.Reject_Reason__c = 'I do not like it';
        resetTests();
       System.debug('testLeadStageChange test 4');
       update testLead;
       
       testLead = queryLead(testLead.Id);
       //System.assertEquals(Date.today().addDays(11),testLead.Next_Cadence_Follow_up_Date__c);//Vinay

       //histories = getStageHistory(testLead.Id);
       historyMap = getStageHistoryMap(testLead.Id);
       System.assertEquals(5,historyMap.size());
       latestStage = historyMap.get('Reject');
       prevStage = historyMap.get('TAL');
       System.debug('testLeadStageChange 4 latestStage='+latestStage);
       System.debug('testLeadStageChange 4 prevStage='+prevStage);
       
       //System.assertEquals('Step 2', prevStage.Last_Cadence_Step_Completed__c);
       //System.assertEquals(Date.today().addDays(9), prevStage.Next_Cadence_Follow_up_Date__c); //Vinay
       System.assertEquals(latestStage.Id,prevStage.NextStage__c);
       System.assertEquals(prevStage.Id,latestStage.Previous_Stage__c);
       System.assertEquals('Reject', latestStage.New_Stage__c);
       System.assertEquals('I do not like it', latestStage.RejectRecycleReason__c);


       // stages Suspect -> Inquiry -> MQL -> TAL -> Reject -> Recycle
       //testLead.Next_Cadence_Follow_up_Date__c = Date.today().addDays(13); //Vinay
       testLead.Lead_Stage__c = 'Recycle';
       testLead.Reject_Reason__c = null;
       testLead.Recycle_Reason__c = 'We will try again';
        resetTests();
       System.debug('testLeadStageChange test 5');
       update testLead;
       
       //histories = getStageHistory(testLead.Id);
       historyMap = getStageHistoryMap(testLead.Id);
       System.assertEquals(6,historyMap.size());
       latestStage = historyMap.get('Recycle');
       prevStage = historyMap.get('Reject');
       System.debug('testLeadStageChange 5 latestStage='+latestStage);
       System.debug('testLeadStageChange 5 prevStage='+prevStage);
       
       //System.assertEquals('Step 3', prevStage.Last_Cadence_Step_Completed__c);
       //System.assertEquals(Date.today().addDays(11), prevStage.Next_Cadence_Follow_up_Date__c);
       System.assertEquals(latestStage.Id,prevStage.NextStage__c);
       System.assertEquals(prevStage.Id,latestStage.Previous_Stage__c);
       System.assertEquals('Recycle', latestStage.New_Stage__c);
       System.assertEquals('We will try again', latestStage.RejectRecycleReason__c);

       
    } // testLeadStageChange

    public static Map<String,Stage_History__c> getStageHistoryMap(Id ctctLdId) {
       Stage_History__c[] histories = getStageHistory(ctctLdId);
       Map<String,Stage_History__c> historyMap = new Map<String,Stage_History__c>();
       for (Stage_History__c history : histories) {
          historyMap.put(history.New_Stage__c, history);
       }
       return historyMap;
    } // getStageHistoryMap

    public static Stage_History__c[] getStageHistory(Id ctctLdId) {
       Stage_History__c[] histories = [Select Id, CreatedDate, Name
                                             ,Contact__c
                                             ,Exited_Date_Time__c
                                             ,Expiration_Deadline__c
                                             ,Last_Cadence_Step_Completed__c
                                             ,Lead__c
                                             ,New_Stage__c
                                             //,Next_Cadence_Follow_up_Date__c //Vinay
                                             ,NextStage__c
                                             ,Old_Stage__c
                                             ,Opportunity__c
                                             ,Previous_Stage__c
                                             ,ProcessNotes__c
                                             ,RejectRecycleReason__c
                                             ,SLA_Deadline__c
                                             ,Stage_Exited_To__c
                                         From Stage_History__c
                                        Where Contact__c = :ctctLdId
                                           or Lead__c = :ctctLdId
                                        order by CreatedDate desc];
       return histories;
    } // getStageHistory

    // test 1 = MQL
    public static MarketingStage__mdt stage1 = null;
    // test 2 = TAL
    public static MarketingStage__mdt stage2 = null;
    // test 3 = TQO
    public static MarketingStage__mdt stage3 = null;
    // test 4 = reject
    public static MarketingStage__mdt stage4 = null;
    
    public static void setupTestStages() {
       // make sure test stages exist and are setup
       Map<String,MarketingStage__mdt> stageMap = DG_LMF_Service.getStageMap();
       for (MarketingStage__mdt stage : stageMap.values()) {
          if (stage.TestScenario__c == 'Test 1') {
             stage1 = stage;
          } else if (stage.TestScenario__c == 'Test 2') {
             stage2 = stage;
          } else if (stage.TestScenario__c == 'Test 3') {
             stage3 = stage;
          } else if (stage.TestScenario__c == 'Test 4') {
             stage4 = stage;
          }
       } // for (MarketingStage__mdt stage
       System.assertNotEquals(null,stage1,'Stage1 is null!');
       System.assertNotEquals(null,stage2,'Stage2 is null!');
       System.assertNotEquals(null,stage3,'Stage3 is null!');
       System.assertNotEquals(null,stage4,'Stage4 is null!');
    } // setupTestStages

    static testMethod void testStageDates() {
       setupTestStages();
       DG_LMF_Service.USE_CODE_FOR_DATE_FIELDS = true;
       Lead ld = new Lead(LastName='LastName', Company='Test Company', Lead_Stage__c=stage1.MasterLabel);
       insert ld;
       
       Id leadId = ld.Id;
       
       String query = 'Select Id, Name, Lead_Stage__c';
       query += ','+stage1.DateFieldAPIName__c;
       query += ','+stage2.DateFieldAPIName__c;
       query += ','+stage4.DateFieldAPIName__c;
       query += ','+stage4.OtherFieldAPIName__c;
       query += ' From Lead where Id=:leadId';
       System.debug('testStageDates query='+query);
       
       Lead checkLd = Database.query(query);
       System.debug('testStageDates 1 checkLd='+checkLd);
       System.assertNotEquals(null,checkLd.get(stage1.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage2.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage4.DateFieldAPIName__c));
       
        resetTests();
       checkLd.Lead_Stage__c = stage2.MasterLabel;
       update checkld;
       
       checkLd = Database.query(query);
       System.debug('testStageDates 2 checkLd='+checkLd);
       System.assertNotEquals(null,checkLd.get(stage1.DateFieldAPIName__c));
       System.assertNotEquals(null,checkLd.get(stage2.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage4.DateFieldAPIName__c));
       
        resetTests();
       checkLd.Lead_Stage__c = stage4.MasterLabel;
       checkLd.Reject_Reason__c = 'Reject Reason';
       update checkld;
       
       checkLd = Database.query(query);
       System.debug('testStageDates 3 checkLd='+checkLd);
       System.assertNotEquals(null,checkLd.get(stage1.DateFieldAPIName__c));
       System.assertNotEquals(null,checkLd.get(stage2.DateFieldAPIName__c));
       System.assertNotEquals(null,checkLd.get(stage4.DateFieldAPIName__c));
       System.assertNotEquals(null,checkLd.get(stage4.OtherFieldAPIName__c));
       
       // we'll return back to MQL from Reject. This should clear out the TAL and Reject fields
        resetTests();
       checkLd.Lead_Stage__c = stage1.MasterLabel;
       update checkld;
       
       checkLd = Database.query(query);
       System.debug('testStageDates 4 checkLd='+checkLd);
       System.assertNotEquals(null,checkLd.get(stage1.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage2.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage4.DateFieldAPIName__c));
       System.assertEquals(null,checkLd.get(stage4.OtherFieldAPIName__c));
       

    } // testStageDates
    
   static testMethod void testGetMarketingStage() {
      MarketingStage__mdt test5 = null;
      Map<String,MarketingStage__mdt> stageMap = DG_LMF_Service.getStageMap();
      for (MarketingStage__mdt stage : stageMap.values()) {
         if (stage.TestScenario__c == 'Test 5') {
            test5 = stage;
         }
      } // for (MarketingStage__mdt stage
      System.assertEquals('TQO',DG_LMF_Service.getMarketingStage(10, new String[]{}));
      System.assertEquals('TQO',DG_LMF_Service.getMarketingStage(10, new String[]{'Inbound'}));
      //System.assertEquals('EFO',DG_LMF_Service.getMarketingStage(10, new String[]{test5.Source__c}));
      
      System.assertEquals('SAO',DG_LMF_Service.getMarketingStage(20, new String[]{}));
      System.assertEquals('SAO',DG_LMF_Service.getMarketingStage(20, new String[]{'Inbound'}));
      //System.assertEquals('EAO',DG_LMF_Service.getMarketingStage(20, new String[]{test5.Source__c}));

      System.assertEquals('SQO',DG_LMF_Service.getMarketingStage(40, new String[]{}));
      System.assertEquals('SQO',DG_LMF_Service.getMarketingStage(40, new String[]{'Inbound'}));
      //System.assertEquals('EQO',DG_LMF_Service.getMarketingStage(40, new String[]{test5.Source__c}));

      System.assertEquals('Client',DG_LMF_Service.getMarketingStage(100, new String[]{}));
      System.assertEquals('Client',DG_LMF_Service.getMarketingStage(100, new String[]{'Inbound'}));
      //System.assertEquals('Client',DG_LMF_Service.getMarketingStage(100, new String[]{test5.Source__c}));

   } // testGetMarketingStage

   public static testMethod void testPartRefRejectRecycleReason() {
    
    Lead ld1 = new Lead(LastName='LastName1', Company='Test Company1');
    Lead ld2 = new Lead(LastName='LastName2', Company='Test Company2');
    Lead[] leadToInsert = new Lead[]{ld1,ld2};
    insert leadToInsert;

    PartnerReferral__c pr1 = new PartnerReferral__c(Lead__c=ld1.Id);
    PartnerReferral__c pr2 = new PartnerReferral__c(Lead__c=ld2.Id);
    PartnerReferral__c[] partRefsToInsert = new PartnerReferral__c[]{pr1,pr2};
    insert partRefsToInsert;
    
    List<Lead> leads = new List<Lead>();
    
    Test.startTest();
    
    ld1.Lead_Stage__c = 'Reject';
    ld1.Reject_Reason__c = 'RejectReason';
    leads.add(ld1);

    ld2.Lead_Stage__c = 'Recycle';
    ld2.Recycle_Reason__c = 'RecycleReason';
    leads.add(ld2);

    resetTests();
    update leads;

    Test.stopTest();

    PartnerReferral__c partRef1 = [Select id, Lead__c, Reject_Reason__c From PartnerReferral__c Where Lead__c = :ld1.Id LIMIT 1];
    System.assertEquals(ld1.Reject_Reason__c, partRef1.Reject_Reason__c);
    PartnerReferral__c partRef2 = [Select id, Lead__c, Recycle_Reason__c From PartnerReferral__c Where Lead__c = :ld2.Id LIMIT 1];
    System.assertEquals(ld2.Recycle_Reason__c, partRef2.Recycle_Reason__c);

    } // testPartRefRejectRecycleReason
    
   static testMethod void testAddToCadence() {
      User runningUser = UserHelper.getRunningUser();
      CadenceUpdateTest.setupTestCadence();
      Cadence__c cad = CadenceUpdateTest.getTestCadence();
      
      Campaign camp1 = new Campaign(Name='Campaign1', IsActive=true, Cadence__c=cad.Id, CadenceMarketingStage__c='TAL');
      insert camp1;
       
      Lead ld1 = new Lead(FirstName='First', LastName='Lead1', Company='Lead1 Company', Lead_Stage__c='TAL', LatestCampaign__c=camp1.Id);
      Lead ld2 = new Lead(FirstName='First', LastName='Lead2', Company='Lead2 Company', Lead_Stage__c='MQL', LatestCampaign__c=camp1.Id);
      Lead ld3 = new Lead(FirstName='First', LastName='Lead3', Company='Lead3 Company', Lead_Stage__c=null, LatestCampaign__c=camp1.Id);
      Lead[] lds = new Lead[]{ld1,ld2,ld3};
      insert lds;    
      
      System.assertEquals(1,[select count() from Cadence_Assignment_Record__c]);
      Cadence_Assignment_Record__c[] car = [Select Id, OwnerId from Cadence_Assignment_Record__c LIMIT 1];
      Assert.areEqual(runningUser.Id, car[0].OwnerId);
   } // testAddToCadence

} // class DG_LMF_Service_Test