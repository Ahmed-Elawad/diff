/**
 * Testmethods for the CreateOppAndMeeting controller.
 *
 * History
 * -------
 * 12/29/2010 Dan Carmen        Created from CreateOppAndMeeting and CreateOppAndMeeting.
   03/01/2011 Dan Carmen        Added in logic for the other sales forces. 
   11/14/2011 Dan Carmen        Fix for error occurring in tests. 
   02/16/2011 Dan Carmen        Modify so HRS close date is 90 days.
   08/20/2012 Dan Carmen        Refactored close date and stage fields.
   08/21/2013 Dan Carmen        Changes for NSS
   02/03/2015 Justin Henderson  Changed MMS test methods to add new first stage value from 1st Presentation to Executive Overview
   07/15/2015 Dan Carmen        Changes for virtual sales
   03/16/2016 Dan Carmen        Make isCore the default when checking the sales org.
   03/03/2017 Jacob Hinds       Adding existing oppty test
   06/27/2017 Lynn Michels        Make changes to adjust StageName for case 24790247
   12/20/2017 Dan Carmen        Added code for duplicate opportunity handling
   09/03/2019 Dan Carmen        Fix query to select core sales reps
   08/30/2020 Michael Karcz		Removed testing for Event.Type = Presentation - Initial (no longer set in CreateOppAndMeeting)
   08/20/2021 Jermaine Stukes	Added PRN test methods
   05/09/2023 Eric Porter        Removed assert for hasPeoPotential code which was commented out 
   01/04/2024 Jaipal            Changed all OpportunityType__c's from 'ASO' to 'Label.HR_Pro_Upgrade' due to the APR Picklist value changes as per APR0152338
   02/26/2024 Dan Carmen        Small change to getConvertStatus - added Label.Lead_ConvertedStatus
   04/30/2024 Dan Carmen        Set ShippingUUID__c on lead convert since we're skipping the triggers

 */
@isTest
private class CreateOppAndMeetingTest {

   @testSetup
   static void setupData() {
      RecordTypeHelperTest.setupRecordType();
      OpptyCheckJoinTest.setupRecordTypeSettingForOpps();
      UserHelperTest.setupSalesOrgSetting();
      // setup the PRN Referral Partner
      Referral_Partner__c refPartPRN = new Referral_Partner__c(Name='Paychex Referral Network', Partner_Type__c='Amplifinity',IsActive__c=true, NSS_Source__c='Inbound');
      insert refPartPRN;
      //set up the PicklistValue__c 
      PicklistValue__c NoComp = new PicklistValue__c(PicklistType__c ='Competitor',Active__c=true, Name = 'no competitor');
      insert NoComp;
   } // setupData 


   // Get a Sales Rep. The tests should be run as a rep.
   private static User getCoreSalesRep() {
      User u = [Select Id, Name, Sales_Org__c from User where Profile.Name like :Utilities.PROF_CORE_SALES+'%'  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='PAY' limit 1];
      return u;
   } // getSalesRep
   
   private static User getMMSSalesRep() {
      String profName = Utilities.PROF_MMS_SALES+'%';
      User u = [Select Id, Name, Sales_Org__c from User where Profile.Name like :profName  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='MMS' limit 1];
      return u;
   } // getSalesRep
   
   private static User getHRSSalesRep() {
      User u = [Select Id, Name, Sales_Org__c from User where Profile.Name like :Utilities.PROF_HRS_401K+'%'  and UserRole.Name like '%Sales Rep%' and IsActive=true and Sales_Org__c='HRS' limit 1];
      return u;
   } // getSalesRep
   
    private static User getPEOSalesRep(){
 	User u = [Select Id, Name, Sales_Org__c from User where IsActive=true and Sales_Org__c='PAS' limit 1];
    return u;        
    } 
   
   private static Referral_Contact__c createReferral() {
      Referral_Account__c ra= new Referral_Account__c();
      ra.Name='test';
      ra.Street_Address_1__c='123';
      ra.City__c='centre';
      ra.State_Province__c='VA';
      ra.Zip_Postal_Code__c='20120';
      ra.Referral_Source_Business_Type__c='Broker';
      insert ra;
    
      Referral_Contact__c rc= new Referral_Contact__c();
      rc.Referral_Account__c=ra.id;
      rc.Name='test';
      rc.Phone__c='3456789087';
      insert rc;
      return rc;
   } // createReferral

   static testMethod void testGetOpp()  {
      System.Debug('Debugging...');
      System.Debug('Unit Test1:');
      User u = getCoreSalesRep();
      System.runAs(u) {
         Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005',Frequency__c='1 Weekly');
         insert l;  

         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+l.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         System.assertEquals(true,ctrl.isLeadConvert);
         ctrl.selectedCompany='000000000000000'; 
         //ctrl.opp.Primary_Competition__c='1 ADP'; 
         ctrl.saveOpp();
         ctrl.cancel();
         //ctrl.getMatchingAccounts();
      } // System.runAs
   } // testGet

    static testMethod void testUpdateCadence()  {
        User usr = [Select Id, name, profile.Name, email, IsActive from User where profile.Name != 'System Administrator' and UserRoleId != null and IsActive = true limit 1];
        Lead ld = new Lead(LastName='Lead1', FirstName='Test', Company='Test Company', PostalCode='12345', OwnerId=usr.Id);
        insert ld;
        Cadence__c testCad = new Cadence__c(Name = 'Test Cadence', Active__c = true, RepAdd__c = true, Sales_Org__c = 'MMS');
        insert testCad;
        Cadence_Assignment_Record__c testCar = new Cadence_Assignment_Record__c(CadenceObject__c = ld.Id, Cadence__c = testCad.Id);
        insert testCar;
        Cadence_Touchpoint__c tp = new Cadence_Touchpoint__c();
        tp.Cadence__c = testCad.Id;
        tp.CarRecord__c = testCar.Id;
        insert tp; 
        String salesProgram = 'Test Field Campaign';
        PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+ld.id);
        Test.setCurrentPage(createOppPage);
        ApexPages.currentPage().getParameters().put('touchPointId',tp.Id);
        ApexPages.currentPage().getParameters().put('salesProgram',salesProgram);
        CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
        System.assertEquals(tp.Id,ctrl.touchPointId);
        System.assertEquals(salesProgram,ctrl.fieldCampaign);
        ctrl.saveOpp();
        
    } 
   static testMethod void testBadLeadId() {
      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId=003DANTESTCTCTID01');
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      System.assertEquals(true,ApexPages.hasMessages());
   } // testBadLeadId
   
   static testMethod void testBadLeadId2() {
      Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005',Frequency__c='1 Weekly');
      insert l;
      Id leadId = l.Id;
      delete l;
        
      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+leadId);
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      System.assertEquals(true,ApexPages.hasMessages());
   } // testBadLeadId
   
   static testMethod void testBadContactId() {
      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId=003DANTESTLEADID01');
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      System.assertEquals(true,ApexPages.hasMessages());
   } // testBadContactId
   
   static testMethod void testNoId()    {
      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting');
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      // should be an error message
      System.assertEquals(true,ApexPages.hasMessages());
   } // testNoId
    
   static testMethod void testGetOpp1() {
      System.Debug('Debugging...');
      System.Debug('Unit Test2:');
 
      Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005',Frequency__c='2 Bi-weekly',Mthd_Lead_Rcvd__c='Sales Rep Effort');
      insert l;     

      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+l.id);
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
   }
    
   static testMethod void testGetOpp2() {
      System.Debug('Debugging... Unit Test3:');
      User u = getCoreSalesRep(); 
      
      System.runAs(u) {
 
         Lead l = new Lead(lastName='testName',postalcode='00001',company='test0005',Frequency__c='3 Semi-monthly');
         insert l;  

         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+l.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      } // System.runAs

   } // testGetOpp2

   // Test when accounts match the lead name.
   static testMethod void testMatchingAccts() {
      
      User u = getCoreSalesRep(); 
      Schema.RecordTypeInfo acctRtInfo = RecordTypeHelper.getAccountRecordTypeInfo(RecordTypeHelper.CORE_ACCOUNT);
      Id acctRtId = acctRtInfo.getRecordTypeId();

      System.runAs(u) {
         Account a1 = new Account(Name='Test Matching Account Inc',ShippingPostalCode='00001', RecordTypeId=acctRtId);
         insert a1;
         Account a2 = new Account(Name='Test Matching Account Inc',BillingPostalCode='00002', RecordTypeId=acctRtId);
         insert a2;
         Account a3 = new Account(Name='Test Client Referral', RecordTypeId=acctRtId);
         insert a3;
         
         Referral_Contact__c rc= createReferral();
         
         Lead l = new Lead(lastName='Test',postalcode='00001',company='Test Matching Account'
               ,LeadSource='51 CPA Referral'
               ,Current_Prior_Method__c='6 Banks');
         l.Referral_Contact__c = rc.Id;
         l.Referral_Contact__r = rc;
         l.Client_Referral__c = a3.Id;
         l.Client_Referral__r = a3;
         l.Street = '123 Test St';
         l.City = 'TestCity';
         l.State = 'NY';
         l.Phone = '(555) 555-1432';
         l.MobilePhone = '(555) 555-1433';
         //l.Primary_Competition__c = '1 ADP';
         insert l;
         l = [Select Id, LastName, PostalCode, Company, LeadSource, Street, Current_Prior_Method__c
                    ,City, State, Phone, MobilePhone, Primary_Competition__c
                    ,Referral_Contact__c, Client_Referral__c
                    ,LeadGroupId__c, Lead_Company__c 
                from Lead where Id=:l.Id];
         
         Lead l2 = l.clone(false,true,false,false);
         l2.lastName='smith';
         Lead l3 = l.clone(false,true,false,false);
         l3.lastName='jones';
         Lead[] extraleads = new Lead[]{l2,l3};
         insert extraleads;
         // all three should be attached to the same lead company
         System.assertEquals(3,[select count() from Lead where Lead_Company__c=:l.Lead_Company__c]);
         Test.startTest();
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+l.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         // Separate controller for setting the start and end date
         MeetingController mc = new MeetingController();
         ctrl.setComponentController(mc);
         System.assertEquals(mc,ctrl.getMyComponentController());
         System.assertEquals(true,ctrl.isLeadConvert);

         // should be 4 entries - default 2 plus 2 from match.
         System.assertEquals(3,ctrl.companyList.size());
         // try to save using the default - should get an error.
         PageReference pr = ctrl.saveOpp();
         System.assertEquals(null,pr);
         
         ctrl.selectedCompany=CreateOppAndMeeting.CREATE_NEW_ACCT; //sa1.Id;
         //ctrl.opp.Primary_Competition__c='1 ADP'; 
         ctrl.acct.Current_Prior_Method__c='1 ADP';
         ctrl.removeMeeting();
         system.assertEquals(false,ctrl.createMeeting);

         pr = ctrl.saveOpp();
         System.assertEquals(true,(pr != null));
         System.debug('pr='+pr);
         
         Lead convertedLead = [Select Id, ConvertedAccountId, ConvertedContactId from Lead where Id=:l.Id];
         Account acct = ReferralQueries.selectAcct(convertedLead.ConvertedAccountId); // [Select Id, Name from Account where Id=:convertedLead.ConvertedAccountId]; 
         Contact ctct = [Select Id, Name from Contact where Id=:convertedLead.ConvertedContactId];
         System.assertEquals(l.Company,acct.Name);
         
         ctrl.acct = acct;
         ctrl.ctct = ctct;
         ctrl.checkOwnership();
         Test.stopTest();
      } // System.runAs
     
   } // testMatchingAccts
   
   // Test existing oppty table
   static testMethod void testExistingOppty() {
      
      User u = getCoreSalesRep(); 
      Schema.RecordTypeInfo acctRtInfo = RecordTypeHelper.getAccountRecordTypeInfo(RecordTypeHelper.CORE_ACCOUNT);
      Id acctRtId = acctRtInfo.getRecordTypeId();
      Schema.RecordTypeInfo opptyRtInfo = RecordTypeHelper.getRecordType('Core Opportunity Record Type','Opportunity');

      System.runAs(u) {
         Account a1 = new Account(Name='Test Matching Account Inc',ShippingPostalCode='00001',Owner_Zip_Code__c='00001', RecordTypeId=acctRtId);
         Account a2 = new Account(Name='Test Matching Account Inc',BillingPostalCode='00002',Owner_Zip_Code__c='00002', RecordTypeId=acctRtId);
         Account a3 = new Account(Name='Test Client Referral', RecordTypeId=acctRtId);
         ZipCheckOwner.SKIP_TRIGGERS=true;
         insert new Account[]{a1,a2,a3};
         
         Opportunity o1 = new Opportunity(Name='Test Oppty',StageName='Pending - Cold',CloseDate=system.today().addDays(1),RecordTypeId = opptyRtInfo.getRecordTypeId(),AccountId = a1.Id, Check_Date__c = Date.today()+30);
         Opportunity o2 = new Opportunity(Name='Test Oppty 2',StageName='Pending - Cold',CloseDate=system.today().addDays(1),RecordTypeId = opptyRtInfo.getRecordTypeId(),AccountId = a1.Id, Check_Date__c = Date.today()+30);
         Opportunity[] olist = new Opportunity[]{o1,o2};
         insert olist;
         
         Referral_Contact__c rc= createReferral();
         
         Lead l = new Lead(lastName='Test',postalcode='00001',company='Test Matching Account'
               ,LeadSource='51 CPA Referral'
               ,Current_Prior_Method__c='6 Banks');
         l.Referral_Contact__c = rc.Id;
         l.Referral_Contact__r = rc;
         l.Client_Referral__c = a3.Id;
         l.Client_Referral__r = a3;
         l.Street = '123 Test St';
         l.City = 'TestCity';
         l.State = 'NY';
         l.Phone = '(555) 555-1432';
         l.MobilePhone = '(555) 555-1433';
         //l.Primary_Competition__c = '1 ADP';
         insert l;
         l = [Select Id, LastName, PostalCode, Company, LeadSource, Street, Current_Prior_Method__c
                    ,City, State, Phone, MobilePhone, Primary_Competition__c
                    ,Referral_Contact__c, Client_Referral__c
                    ,LeadGroupId__c, Lead_Company__c 
                from Lead where Id=:l.Id];
         
         Lead l2 = l.clone(false,true,false,false);
         l2.lastName='smith';
         Lead l3 = l.clone(false,true,false,false);
         l3.lastName='jones';
         Lead[] extraleads = new Lead[]{l2,l3};
         insert extraleads;
         // all three should be attached to the same lead company
         System.assertEquals(3,[select count() from Lead where Lead_Company__c=:l.Lead_Company__c]);
         Test.startTest();
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+l.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         // Separate controller for setting the start and end date
         MeetingController mc = new MeetingController();
         ctrl.setComponentController(mc);
         System.assertEquals(mc,ctrl.getMyComponentController());
         System.assertEquals(true,ctrl.isLeadConvert);

         // should be 4 entries - default 2 plus 2 from match.
         System.assertEquals(3,ctrl.companyList.size());
         // try to save using the default - should get an error.
         PageReference pr = ctrl.saveOpp();
         System.assertEquals(null,pr);
         
         ctrl.selectedCompany=a1.Id; //sa1.Id;
         ctrl.queryExistingOppty(a1.Id,ctrl.salesOrg);
         ctrl.checkExistingOpps();
         system.assertEquals(true,ctrl.hasExistingOpps);
         ExistingOpptyWrapper eow = ctrl.existingOpps[0];
         eow.selected = true;
         ApexPages.currentPage().getParameters().put('oppId',ctrl.existingOpps[0].opp.Id);
         ApexPages.currentPage().getParameters().put('prevValue',String.valueOf(false));

         ctrl.storeSelectedOppty();
         system.assertEquals(ctrl.existingOpps[0].opp.Id,ctrl.selectedOppWrap.opp.Id);
         system.assertEquals(false,ctrl.createOpportunity);
         
         eow = ctrl.existingOpps[1];
         eow.selected = true;
         ApexPages.currentPage().getParameters().put('oppId',ctrl.existingOpps[1].opp.Id);
         ApexPages.currentPage().getParameters().put('prevValue',String.valueOf(false));
         ctrl.storeSelectedOppty();
         system.assertEquals(ctrl.existingOpps[1].opp.Id,ctrl.selectedOppWrap.opp.Id);
         system.assertEquals(false,ctrl.createOpportunity);
         
         eow.selected = false;
         ApexPages.currentPage().getParameters().put('oppId',ctrl.existingOpps[1].opp.Id);
         ApexPages.currentPage().getParameters().put('prevValue',String.valueOf(true));
         ctrl.storeSelectedOppty();
         system.assertEquals(null,ctrl.selectedOppWrap);
         system.assertEquals(true,ctrl.createOpportunity); 
         
         eow.selected = true;
         ApexPages.currentPage().getParameters().put('oppId',ctrl.existingOpps[1].opp.Id);
         ApexPages.currentPage().getParameters().put('prevValue',String.valueOf(false));
         ctrl.storeSelectedOppty();      
         system.assertEquals(ctrl.existingOpps[1].opp.Id,ctrl.selectedOppWrap.opp.Id);
         system.assertEquals(false,ctrl.createOpportunity);
         system.assertEquals(true,ctrl.createMeeting);
         ctrl.saveOpp();
         
         //Event evnt = [SELECT Id, WhoId, Subject, WhatId FROM Event WHERE WhatId = :ctrl.selectedOppWrap.opp.Id];
         //system.assert(evnt!=null);
         //OpportunityJoin__c oJoins = [SELECT Id,JoinType__c,OpportunityChild__c FROM OpportunityJoin__c WHERE OpportunityChild__c =:ctrl.selectedOppWrap.opp.Id AND CreatedDate = :system.today()];
         //system.assert(oJoins!=null);
         
         Test.stopTest();
      } // System.runAs
     
   } // testMatchingAccts

   static testMethod void testConvertFrequency() {
      CreateOppAndMeeting coam = new CreateOppAndMeeting();
      System.assertEquals('0',coam.convertFrequency('test default'));
      System.assertEquals('52',coam.convertFrequency('1 Weekly'));
      System.assertEquals('26',coam.convertFrequency('2 Bi-weekly'));
      System.assertEquals('24',coam.convertFrequency('3 Semi-monthly'));
      System.assertEquals('12',coam.convertFrequency('4 Monthly'));
      System.assertEquals('4',coam.convertFrequency('5 Quarterly'));
      System.assertEquals('2',coam.convertFrequency('6 Semi-annually'));
      System.assertEquals('1',coam.convertFrequency('7 Annually'));
   } // testConvertFrequency
   
   static testMethod void testSetDefaults() {
      CreateOppAndMeeting coam = new CreateOppAndMeeting();
      coam.setDefaults(UserHelper.SO_401);
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_401K,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.HRS_EVENT,coam.eventRtName);
      System.assertEquals(false,coam.isCore);
      System.assertEquals(true,coam.isHRS);
      System.assertEquals(false,coam.isMMS);
        System.assertEquals(false,coam.isHNB);

      coam.setDefaults(UserHelper.SO_PEO_ASO);
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_PEO,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.HRS_EVENT,coam.eventRtName);
      System.assertEquals(false,coam.isCore);
      System.assertEquals(true,coam.isHRS);
      System.assertEquals(false,coam.isMMS);
        System.assertEquals(false,coam.isHNB);

      coam.setDefaults(UserHelper.SO_HNB);
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_HNBF,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.HNBF_EVENT,coam.eventRtName);
      System.assertEquals(false,coam.isCore);
      System.assertEquals(false,coam.isHRS);
      System.assertEquals(false,coam.isMMS);
        System.assertEquals(true,coam.isHNB);

      coam.setDefaults('COE');
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_CORE,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.CORE_EVENT,coam.eventRtName);
      System.assertEquals(true,coam.isCore);
      System.assertEquals(false,coam.isHRS);
      System.assertEquals(false,coam.isMMS);
        System.assertEquals(false,coam.isHNB);

      coam.setDefaults(UserHelper.SO_MMS);
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_MMS,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.MMS_EVENT,coam.eventRtName);
      System.assertEquals(false,coam.isCore);
      System.assertEquals(false,coam.isHRS);
      System.assertEquals(true,coam.isMMS);
        System.assertEquals(false,coam.isHNB);

      coam.setDefaults(UserHelper.SO_CORE);
      System.assertEquals(OpportunityCreateCase.RT_OPPTY_CORE,coam.opptyRtName);
      System.assertEquals(RecordTypeHelper.CORE_EVENT,coam.eventRtName);
      System.assertEquals(true,coam.isCore);
      System.assertEquals(false,coam.isHRS);
      System.assertEquals(false,coam.isMMS);
        System.assertEquals(false,coam.isHNB);
   } // testSetDefaults
   
   static testMethod void testEventSubjectLine() {  
      Account acc = new Account(Name='01234567890123456789012345678901234567890123456789012345678901234567890123456789',Frequency__c='6 Semi-annually');
      insert acc;
      Contact c = new Contact(FirstName='test',lastName='Name',Phone='(555) 555-1234',accountid=acc.id);
      insert c;     

      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id+'&salesOrg=PAY');
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      //ctrl.opp.Primary_Competition__c='1 ADP'; 
      ctrl.acct.Current_Prior_Method__c='1 ADP';
      PageReference pr = ctrl.saveOppGotoMeeting();
      // get the event id
      Id evntId = pr.getParameters().get('id');
      Event evnt = [Select Id, Subject, Description, WhoId, WhatId, DurationInMinutes, ActivityDate
                      from Event where Id = :evntId];
      System.assertEquals('01234567890123456789012345678901234567890123456789012345678901234567890123456789-Payroll - (555) 555-1234',evnt.Subject);
      ctrl.cancel();        
   } // testEventSubjectLine
    
    
   // Test different combinations of event parameters.
   static testmethod void testEventParams() {
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      Event evnt = ctrl.createEvent('acctName', 'oppName','ctctName','phone','mobilePhone', 'street', 'city', 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', null,'ctctName', 'phone','mobilePhone', 'street', 'city', 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', null,'mobilePhone', 'street', 'city', 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone',null, 'city', 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone',null, 'street', 'city', 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone', 'street', null, 'state', 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone', 'street', 'city', null, 'postalCode','email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone', 'street', 'city', 'state', null,'email',null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone', 'street', 'city', 'state', 'postalCode',null,null,null);
      evnt = ctrl.createEvent('acctName', 'oppName','ctctName', 'phone','mobilePhone', 'street', null, null, 'postalCode','email',null,null);
   } // testEventParams
   
   static void runGenericTest(String leadSource, String primaryComp, String curMethod
                             ,String mthdLead
                             ,Referral_Contact__c rc
                             ,Boolean hasErrorMsg) {
      Account acc = new Account(Name='Test Company, Inc',Frequency__c='1 Weekly');
      insert acc;
      Contact c = new Contact(FirstName='Joe',lastName='Tester',phone='(555) 555-1234', accountid=acc.id,leadsource=leadSource);
      insert c;     

      PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
      Test.setCurrentPage(createOppPage);
      CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
      System.assertEquals(false,ctrl.isLeadConvert);

      //ctrl.opp.Primary_Competition__c=primaryComp; 
      ctrl.acct.Current_Prior_Method__c=curMethod;
      ctrl.opp.Mthd_Lead_Rcvd__c = mthdLead;
      if (rc != null) {
         System.debug('Adding referral contact');
         ctrl.opp.Referral_Contact__c = rc.Id;
         ctrl.opp.Referral_Contact__r = rc;
      }
      ctrl.opp.Local_Competitors__c = 'Test';
      // make sure no error messages
      System.assertEquals(0,ApexPages.getMessages().size());
      ctrl.saveOpp();
      if (!hasErrorMsg) {
         // if no expected error message, assume success
         //System.assertEquals(0,ApexPages.getMessages().size());
      } else {
         // Expects a failure
         //System.assertEquals(1,ApexPages.getMessages().size());
         ctrl.cancel();
      }         
    
   } // runGenericTest
   static testMethod void test51NoCpa() {
      User u = getCoreSalesRep();
      System.runAs(u) {
         runGenericTest('Referral - AICPA/CPA2Biz', '7 CPA', '19 Other'
                             ,'Sales Rep Effort'
                             ,null
                             ,true);
      } // System.runAs 
   } // test51NoCpa
   static testMethod void test51WithCpa() { 
      User u = getCoreSalesRep();
      System.runAs(u) {
         // create referral
         Referral_Contact__c rc= createReferral();

         runGenericTest('Referral - AICPA/CPA2Biz', '7 CPA', '19 Other'
                             ,'CPA Call'
                             ,rc
                             ,false);
      } // System.runAs
   } // test51WithCpa
   // Test when a record is a core conversion.
   static testMethod void testHRSOpportunity() {
      User u = getHRSSalesRep();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
      Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                               ,RecordTypeId=rt.getRecordTypeId(),Bis_Id__c=7777
                               ,AccountNumber='123-TEST'
                               ,First_Run_Date__c=Date.today().addMonths(-6));
      insert acc;
      Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
      insert c;
      SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(UserHelper.SO_401);
      System.assertEquals(true, salesOrgSetting != null, 'The Custom Setting for '+UserHelper.SO_401+' could not be found!');

      System.runAs(u) {
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         System.assertEquals(false,ctrl.isAncillary);
         //System.assertEquals('Presentation - Initial (Face-to-Face)',ctrl.evnt.Type);
         System.assertEquals(salesOrgSetting.OppFirstStage__c,ctrl.opp.StageName);
         // remove the meeting
         ctrl.removeMeeting();
         System.assertEquals(false,ctrl.createMeeting);
         // add the meeting back
         ctrl.addMeeting();
         System.assertEquals(true,ctrl.createMeeting);
      } // System.runAs
   } // testHRSOpportunity  

   // Test when a record is a core conversion.
   static testMethod void testMMSCoreConversion() {
      User u = getMMSSalesRep();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
      Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                               ,RecordTypeId=rt.getRecordTypeId(),Bis_Id__c=7777
                               ,AccountNumber='123-TEST'
                               ,First_Run_Date__c=Date.today().addMonths(-6));
      insert acc;
      Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
      insert c;
      SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(UserHelper.SO_MMS);
      System.assertEquals(true, salesOrgSetting != null, 'The Custom Setting for '+UserHelper.SO_MMS+' could not be found!');

      System.runAs(u) {
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         System.assertEquals(false,ctrl.isAncillary);
         System.assertEquals('Transfer - Core to MMS',ctrl.opp.LeadSource);
         System.assertEquals('123-TEST',ctrl.opp.Core_Branch_Client_Number__c);
         System.assertEquals(salesOrgSetting.OppFirstStage__c,ctrl.opp.StageName);
         // remove the meeting
         ctrl.removeMeeting();
         System.assertEquals(false,ctrl.createMeeting);
         // add the meeting back
         ctrl.addMeeting();
         System.assertEquals(true,ctrl.createMeeting);
      } // System.runAs
   } // testMMSCoreConversion   

   // Test when a record is an MMS Ancillary presentation.
   static testMethod void testMMSAncillary() {
      User u = getMMSSalesRep();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT,'Account');
      Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                               ,RecordTypeId=rt.getRecordTypeId(),Bis_Id__c=7777
                               ,AccountNumber='123-TEST'
                               ,BillingStreet='123 Billing St',BillingCity='Billing City'
                               ,BillingState='NY',BillingPostalCode='14513'
                               ,First_Run_Date__c=Date.today().addMonths(-6));
      insert acc;
      Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
      insert c;
      SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(UserHelper.SO_MMS);
      System.assertEquals(true, salesOrgSetting != null, 'The Custom Setting for '+UserHelper.SO_MMS+' could not be found!');
      System.runAs(u) {
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id+'&Ancillary=Y');
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         System.assertEquals(true,ctrl.isAncillary);
         //System.assertEquals('No Competition/Ancillary',ctrl.opp.Primary_Competition__c);
         System.assertEquals(salesOrgSetting.OppFirstStage__c,ctrl.opp.StageName);
         System.assertEquals('Presentation - Current Client',ctrl.evnt.Type);

         // remove the meeting
         ctrl.removeMeeting();
         System.assertEquals(false,ctrl.createMeeting);
         // save - verify there is no meeting
         ctrl.saveOpp();
         System.assertEquals(0,[Select count() from Event where WhatId = :ctrl.opp.Id]);
      } // System.runAs
   } // testMMSAncillary    

   // Test when a record is an MMS Ancillary presentation.
   static testMethod void testCoreAncillary() {
      User u = getCoreSalesRep();
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
      Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                               ,RecordTypeId=rt.getRecordTypeId(),Bis_Id__c=7777
                               ,AccountNumber='123-TEST'
                               ,BillingStreet='123 Billing St',BillingCity='Billing City'
                               ,BillingState='NY',BillingPostalCode='14513'
                               ,First_Run_Date__c=Date.today().addMonths(-6));
      insert acc;
      Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
      insert c;
      SalesOrg__c salesOrgSetting = SalesOrg__c.getInstance(UserHelper.SO_CORE);
      System.assertEquals(true, salesOrgSetting != null, 'The Custom Setting for '+UserHelper.SO_CORE+' could not be found!');

      System.runAs(u) {
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id+'&Ancillary=Y&createMeeting=N');
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
         System.assertEquals(true,ctrl.isAncillary);
         //System.assertEquals('No Competition/Ancillary',ctrl.opp.Primary_Competition__c);
         System.assertEquals(salesOrgSetting.OppFirstStage__c,ctrl.opp.StageName);
         //System.assertEquals('Presentation - Initial',ctrl.evnt.Type);
         // verify meeting isn't created
         System.assertEquals(false,ctrl.createMeeting);

         // save - verify there is no meeting
         ctrl.saveOpp();
         System.assertEquals(0,[Select count() from Event where WhatId = :ctrl.opp.Id]);
      } // System.runAs
   } // testCoreAncillary   

   static testMethod void testGeneralCase() {
      System.Debug('Debugging... testGeneralCase');
      User u = getCoreSalesRep();
      System.runAs(u) {
         Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
         Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                               ,RecordTypeId=rt.getRecordTypeId()
                               ,Bis_Id__c=7777
                               ,AccountNumber='123-TEST'
                               ,BillingStreet='123 Billing St',BillingCity='Billing City'
                               ,BillingState='NY',BillingPostalCode='14513'
                               ,First_Run_Date__c=Date.today().addMonths(-6));
         insert acc;
         Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
         c.MailingStreet='123 Test St';
         c.MailingCity='TestCity';
         c.MailingState='TestState';
         c.Phone='(555) 555-1234';
         c.MobilePhone='(555) 555-1235';
         c.MailingPostalCode='13254';
         insert c;      
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
		 System.assertEquals(true,ctrl.isCore);
         System.assertEquals(c.Id, ctrl.ctct.Id);
         System.assertEquals(acc.Id,ctrl.acct.Id);

         ctrl.setDefaults(UserHelper.SO_CORE);
         Opportunity opp = ctrl.opp;
         System.assertEquals(null,opp.Primary_Competition__c);
         System.assertEquals('52',ctrl.opp.Frequency__c);
         ctrl.updateOpp();
         //ctrl.opp.Primary_Competition__c = '7 CPA';     
         ctrl.acct.Current_Prior_Method__c = '19 Other';
         ctrl.opp.LeadSource = '64 Local';
         ctrl.opp.Local_Competitors__c = 'Test';
         ctrl.saveOpp();
      
         //System.assertEquals('7 CPA',ctrl.opp.Primary_Competition__c);
         System.assertEquals('64 Local',ctrl.opp.leadSource);
         System.assertEquals('Test Co-Payroll',ctrl.opp.Name);

         System.assertEquals('19 Other',ctrl.acct.Current_Prior_Method__c);
         System.assertEquals('Test',ctrl.acct.Local_Competitors__c);

         // verify event was created
         /*Event evnt = [Select Id, Subject, Description, WhoId, WhatId
                          ,ActivityDate, DurationInMinutes,ActivityDateTime
                      from Event
                     where WhatId = :ctrl.opp.Id];
         System.assertEquals(Date.today(),evnt.ActivityDate);*/
      } // System.runAs
      
   } // testGeneralCase
    
   static testMethod void testPEOPotential() {
      System.Debug('Debugging... testPEOPotentialCase');
      User u = getPEOSalesRep();
      System.runAs(u) {
         Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks', PEO_Potential_Indicator__c='A');
         insert acc;
         Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
         c.MailingStreet='123 Test St';
         c.MailingCity='TestCity';
         c.MailingState='TestState';
         c.Phone='(555) 555-1234';
         c.MobilePhone='(555) 555-1235';
         c.MailingPostalCode='13254';
         insert c;      
         PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id+'&createMeeting=N');
         Test.setCurrentPage(createOppPage);
         CreateOppAndMeeting ctrl = new CreateOppAndMeeting();

         System.assertEquals(c.Id, ctrl.ctct.Id);
         System.assertEquals(acc.Id,ctrl.acct.Id);

         Opportunity opp = ctrl.opp;          

         System.assertEquals(null,opp.Primary_Competition__c);
         System.assertEquals('52',ctrl.opp.Frequency__c);

         //ctrl.opp.Primary_Competition__c = '7 CPA';     
         ctrl.acct.Current_Prior_Method__c = '19 Other';
         ctrl.opp.LeadSource = '64 Local';
         ctrl.opp.Local_Competitors__c = 'Test';
         ctrl.opp.OpportunityType__c = Label.HR_Pro_Upgrade; 
         Id asoOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('ASO Opportunity Record Type').getRecordTypeId();
         ctrl.opp.recordtypeid = asoOppRecordTypeId;
         ctrl.saveOpp();
         //System.assertEquals('PEO',ctrl.oppTemp.OpportunityType__c);
          
      
      } //runAs
   }// testPEOPotential
   static testMethod void testSalesOrgConstructor() {
      CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
      SalesOrg__c salesOrgPay = SalesOrg__c.getInstance(UserHelper.SO_CORE);
      //System.assertEquals(Label.OpptyPendingDefault,coam.oppFirstStage);
      System.assertEquals(salesOrgPay.OppFirstStage__c, coam.oppFirstStage);
      
      coam = new CreateOppAndMeeting(UserHelper.SO_MMS);
      SalesOrg__c salesOrgMms = SalesOrg__c.getInstance(UserHelper.SO_MMS);
      //System.assertEquals(Label.OpptyPendingMMS,coam.oppFirstStage);
      System.assertEquals(salesOrgMms.OppFirstStage__c, coam.oppFirstStage);
      
      coam = new CreateOppAndMeeting(UserHelper.SO_HNB);
      SalesOrg__c salesOrgHnb = SalesOrg__c.getInstance(UserHelper.SO_HNB);
      //System.assertEquals(Label.OpptyPendingHNB,coam.oppFirstStage);
      System.assertEquals(salesOrgHnb.OppFirstStage__c, coam.oppFirstStage);
   } // testSalesOrgConstructor

   static testMethod void testCreateTask() {
    Account acct = new Account(Name='Test Acct', ShippingStreet='ShippingStreet',ShippingState='NY',ShippingPostalCode='12345');
    Contact ctct = new Contact(FirstName='Test',LastName='Contact',MailingStreet='MailingStreet',MailingCity='City',MailingState='NY',MailingPostalCode='12345',Phone='1234567890',Email='Test.contact@testing.com');
    CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
    Task tsk = coam.createTask(acct, ctct, null,null);
   } // testCreateTask
   
   static testMethod void testGetOppName() {
      System.assertEquals('Test-PROD',CreateOppAndMeeting.getOppName('Test', 'PROD', CreateOppAndMeeting.OPP_NAME_SIZE));
      System.assertEquals('ThisIsALongName-AndALongProduct',CreateOppAndMeeting.getOppName('ThisIsALongName', 'AndALongProduct',CreateOppAndMeeting.OPP_NAME_SIZE));
      // incase the name length changes - keep it a controlled test
      CreateOppAndMeeting.OPP_NAME_SIZE = 80;
      System.assertEquals('ThisCompanyNameIsReallyReallyLongProbablyTooLongReal-ThisProductNameIsPrettyLong',CreateOppAndMeeting.getOppName('ThisCompanyNameIsReallyReallyLongProbablyTooLongReallyButWeNeedANameThatIsLongOk', 'ThisProductNameIsPrettyLong', CreateOppAndMeeting.OPP_NAME_SIZE));
   } // testGetOppName
   
   static testMethod void testMisc() {
      CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_CORE);
      coam.oppTemp.OpportunityType__c='Payroll';
      coam.selectOppType();
      
      coam.addOppty();
      System.assertEquals(true,coam.createOpportunity);
      
      coam.removeOppty();
      System.assertEquals(false,coam.createOpportunity);
      
      coam = new CreateOppAndMeeting(UserHelper.SO_CORE,'division');
      coam.findExistingOpps();
      System.assertEquals(null,coam.oppProbability);
      System.assertEquals(null,coam.oppForecast);
      System.assertEquals(null,coam.refOppProbability);
      System.assertEquals(null,coam.refOppForecast);
      System.assertEquals(false,coam.hasPricebookOptions);

      Account acct = new Account(Name='Test Account',ShippingPostalCode='90201');
      Contact ctct = new Contact(FirstName='Jimmy', Lastname='Contact', Phone='(555) 867-5309', Email='jimmytest@test.com');
      Event evt = coam.createEvent(acct,  ctct, 'TestClass', 'CallType');
      System.assertNotEquals(null,evt);
       
      Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Account');
      refAcct.Street_Address_1__c='123 Any St';
      refAcct.City__c='Rochester';
      refAcct.State_Province__c='NY';
      refAcct.Zip_Postal_Code__c='90210';
      Referral_Contact__c refCtct = new Referral_Contact__c(Name='Lisa Contact', Email__c='lisa@contact.com', Referral_Account__r=refAcct);
      evt = coam.createEvent(acct,  ctct, refCtct, 'TestClass', 'CallType');
      System.assertNotEquals(null,evt);
   } // testMisc

   static testMethod void testPRNLeadConversion() {
        
        User u = getCoreSalesRep();
        System.runAs(u) {
            Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
            Account acct = new Account(Name='Test Acct', ShippingStreet='ShippingStreet',ShippingState='NY',ShippingPostalCode='12345');
            insert acct;
            Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                                      ,RecordTypeId=rt.getRecordTypeId()
                                      ,Bis_Id__c=7777
                                      ,AccountNumber='123-TEST'
                                      ,BillingStreet='123 Billing St',BillingCity='Billing City'
                                      ,BillingState='NY',BillingPostalCode='14513'
                                      ,First_Run_Date__c=Date.today().addMonths(-6));
            insert acc;
            amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Active', Account__c=acc.Id, OwnerId = u.Id, Change_Owner_Date__c = Date.today());
            insert ampAdv;
            acc.Amplifinity_Advocate__c = ampAdv.Id;
            update acc;
            Referral_Contact__c rc= createReferral();
            Lead ld1 = new Lead(lastName='Test',postalcode='00001',company='Test Matching Account'
                              ,LeadSource='51 CPA Referral'
                              ,Current_Prior_Method__c='6 Banks');
            ld1.Referral_Contact__c = rc.Id;
            ld1.Referral_Contact__r = rc;
            ld1.Client_Referral__c = acct.Id;
            ld1.Client_Referral__r = acct;
            ld1.Company = acct.Name;
            ld1.Street = '123 Test St';
            ld1.City = 'TestCity';
            ld1.State = 'NY';
            ld1.Phone = '(555) 555-1432';
            ld1.MobilePhone = '(555) 555-1433';
            ld1.Primary_Competition__c = '1 ADP';
            insert ld1;
            PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?leadId='+ld1.id);
            Test.setCurrentPage(createOppPage);
            CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
            ctrl.selectedCompany=CreateOppAndMeeting.CREATE_NEW_ACCT;
            //ctrl.opp.Primary_Competition__c = '7 CPA';     
            ctrl.opp.LeadSource = 'Referral-Paychex Referral Network';   
            ctrl.acct.Current_Prior_Method__c = '19 Other';
            ctrl.opp.Local_Competitors__c = 'Test';
            ctrl.opp.OpportunityType__c='Payroll';
            ctrl.opp.Client_Referral__c = acc.Id;
            ctrl.saveOpp();
            Opportunity opp = ctrl.opp;  
            System.assert(opp.amp_dev__Referral__c !=null);
            PartnerReferral__c testPartRef = [Select Id from PartnerReferral__c where Amplifinity_Advocate__c=:ampAdv.Id];
            System.assert(testPartRef !=null);
        }
    } // testPRNLeadConversion
                                          
    static testMethod void testPRNfromContact() {
        
        User u = getCoreSalesRep();
        System.runAs(u) {
            Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
            Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                                      ,RecordTypeId=rt.getRecordTypeId()
                                      ,Bis_Id__c=7777
                                      ,AccountNumber='123-TEST'
                                      ,BillingStreet='123 Billing St',BillingCity='Billing City'
                                      ,BillingState='NY',BillingPostalCode='14513'
                                      ,First_Run_Date__c=Date.today().addMonths(-6));
            insert acc;
            Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
            c.MailingStreet='123 Test St';
            c.MailingCity='TestCity';
            c.MailingState='TestState';
            c.Phone='(555) 555-1234';
            c.MobilePhone='(555) 555-1235';
            c.MailingPostalCode='13254';
            insert c;     
            amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Active', Account__c=acc.Id, OwnerId = u.Id, Change_Owner_Date__c = Date.today());
            insert ampAdv;
            PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
            Test.setCurrentPage(createOppPage);
            CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
            ctrl.setDefaults('UserHelper.SO_CORE');
                
            //ctrl.opp.Primary_Competition__c = '7 CPA';     
            ctrl.opp.LeadSource = 'Referral-Paychex Referral Network';   
            ctrl.acct.Current_Prior_Method__c = '19 Other';
            ctrl.opp.Local_Competitors__c = 'Test';
            ctrl.opp.OpportunityType__c='Payroll';
            ctrl.opp.Client_Referral__c = acc.Id;
            ctrl.saveOpp();
            Opportunity opp = ctrl.opp;  
            System.assert(opp.amp_dev__Referral__c !=null);
            PartnerReferral__c testPartRef = [Select Id from PartnerReferral__c where Amplifinity_Advocate__c=:ampAdv.Id];
            System.assert(testPartRef !=null);
        }
    } // testPRNfromContact
                                          
    static testMethod void testPrnExistingAmpReferral() {
        
        User u = getCoreSalesRep();
        System.runAs(u) {
            Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT,'Account');
            Account acc = new Account(Name='Test Co',Frequency__c='1 Weekly', Current_Prior_Method__c='6 Banks'
                                      ,RecordTypeId=rt.getRecordTypeId()
                                      ,Bis_Id__c=7777
                                      ,AccountNumber='123-TEST'
                                      ,BillingStreet='123 Billing St',BillingCity='Billing City'
                                      ,BillingState='NY',BillingPostalCode='14513'
                                      ,First_Run_Date__c=Date.today().addMonths(-6));
            insert acc;
            Contact c = new Contact(FirstName='Jimmy',lastName='Test',LeadSource='56 National Direct Mail',accountid=acc.id);
            c.MailingStreet='123 Test St';
            c.MailingCity='TestCity';
            c.MailingState='TestState';
            c.Phone='(555) 555-1234';
            c.MobilePhone='(555) 555-1235';
            c.MailingPostalCode='13254';
            insert c;     
            amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Active', Account__c=acc.Id, OwnerId = u.Id, Change_Owner_Date__c = Date.today());
            insert ampAdv;
            acc.Amplifinity_Advocate__c = ampAdv.Id;
            update acc;
            amp_dev__Amp_Referral__c testAmpRef = new amp_dev__Amp_Referral__c(amp_dev__Advocate__c=acc.Amplifinity_Advocate__c,amp_dev__Status__c='Submitted', Contact__c = c.Id);
            insert testAmpRef;
            
            PageReference createOppPage = new PageReference('/apex/CreateOppAndMeeting?contactId='+c.id);
            Test.setCurrentPage(createOppPage);
            CreateOppAndMeeting ctrl = new CreateOppAndMeeting();
            ctrl.setDefaults('UserHelper.SO_CORE');
                 
            //ctrl.opp.Primary_Competition__c = '7 CPA';     
            ctrl.opp.LeadSource = 'Referral-Paychex Referral Network';   
            ctrl.acct.Current_Prior_Method__c = '19 Other';
            ctrl.opp.Local_Competitors__c = 'Test';
            ctrl.opp.OpportunityType__c='Payroll';
            ctrl.opp.Client_Referral__c = acc.Id;
            ctrl.saveOpp();
            Opportunity opp = ctrl.opp; 
            System.assert(opp.amp_dev__Referral__c == testAmpRef.Id);
        }
    } // testPrnExistingAmpReferral
                                          
                                          
} // CreateOppAndMeetingTest