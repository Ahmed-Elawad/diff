/* 
 * Test methods for the ReferralMethods class
 *
 * History
 * -------
 * 08/21/2012 Dan Carmen        Created
 * 01/18/2013 Dan Carmen        Modified for UPMC ownership
 * 01/28/2013 Cindy Freeman     Modified for getReferrallFromLeadSource method signature change
 * 07/31/2013 Cindy Freeman     Modified to test opty.LeadSource_Detail being populated from task.call type
 * 06/12/2014 Cindy Freeman     Added test for ChatterPost methods 
   07/08/2015 Dan Carmen        Changes for seeAllData=false, code coverage
   08/10/2015 Cindy Freeman     Added Reject Reason to get past validation rule when testing
   01/26/2016 Dan Carmen        Check disposition for commissions
   07/11/2017 Carrie Marciano   Added test Integrated Selling
   10/11/2017 Cindy Freeman      added Referral  Account when Referral Contacts are created
   11/16/2017 Dan Carmen        Adjustments for test coverage.
   10/12/2018 Dan Carmen        Duplicate Opportunity handling
   03/14/2019 Dan Carmen        Added retry ability for saving the selling opportunity
   07/08/2019 Dan Carmen        Change for Core Sales profile move
   09/03/2019 Dan Carmen        Fix query to select core sales reps
   05/18/2021 Carrie Marciano   Carrie Marciano updated to use OppStage labels
   06/08/2021 Eric Porter      Update to include Referral Contacts for NSS Referral Submission
   09/20/2021 Pujitha Madamanchi Bank Fee on Referrals from Referral Account
   02/10/2022 Dan Carmen        Use the Sales Org field on the Referral Partner for Prospect Ownership
   03/02/2022 Dan Carmen        APR0131613 Try to set the Pricebook for the opps
   05/20/2022 Dan Carmen        Change to how the NSS Source could be set on the Opp
   06/01/2022 Pujitha Madamanchi APR0122251 Test GL Case creation on Lead Conversion. 
   01/30/2023 Pujitha Madamanchi APR0145054 : Populate Marketing Source based on Lastest Campaign else, NSS Source
   08/17/2023 Dan Carmen         Commented out updateDSAOpptyRefJoin because it was updating too many records and hitting SOQL limits
   09/16/2023 Jaipal             Changed the getReferralFromLeadSource parameters in test class instances
   10/25/2023 Dan Carmen         Update updateDSAOpptyRefJoin method


   
 */
@isTest
public class ReferralMethodsTest {

   @testSetup
   static void setupData() {
      OpptyCheckJoinTest.setupRecordTypeSettingForOpps();
   } // setupData
   
   // Verify the referral information
   private static Referral__c verifyRef(String testName, Id refId, String email) {
      System.debug('verifyRef test='+testName);
      Referral__c ref = [Select Id, Email__c, Contact__c, Referral_Contact__c from Referral__c where Id=:refId];
      System.assertEquals(email,ref.Email__c);
      return ref;
   } // verifyRef

   // Check that the email field will be populated appropriately.
   static testMethod void checkPopulateEmail() {
      // the number of records we will load in each case to test for bulk loads.
      Integer numRecs = 20;
      
      // create test contacts
      Account acct = new Account(Name=UserHelper.PAYCHEX_COMP);
      insert acct;
      Contact c1 = new Contact(AccountId=acct.Id,LastName='TestContact1',HR_Person_Id__c='1',Email='testcontact1@paychex.com');
      Contact c2 = new Contact(AccountId=acct.Id,LastName='TestContact1',HR_Person_Id__c='2',Email='testcontact2@paychex.com');
      Contact c3 = new Contact(AccountId=acct.Id,LastName='TestContact3',HR_Person_Id__c='3');
      Contact[] ctcts = new Contact[]{c1,c2,c3};
      insert ctcts;

      Referral_Account__c ra1 = new Referral_Account__c(Name='Joe CPA Firm',Referral_Source_Business_Type__c='Accounting Firm');
      insert ra1;
      Referral_Contact__c rc1 = new Referral_Contact__c(Name='Joe Contact1',Email__c='joecontact1test@paychex.com',Referral_Account__c=ra1.Id);
      Referral_Contact__c rc2 = new Referral_Contact__c(Name='Joe Contact2',Email__c='joecontact2test@paychex.com',Referral_Account__c=ra1.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{rc1,rc2};
      insert refCtcts;
      
       Referral_Contact__c newrc = ReferralMethods.getRefCtct(rc1.Id);      
        System.assertEquals(True, newrc != null ? true : false);
      // test single records
      Referral__c ref1 = new Referral__c();
      insert ref1;
      ref1 = verifyRef('testNull',ref1.Id,null);
      ref1.Contact__c = c1.Id;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref1;

      ref1 = verifyRef('testUpdate1',ref1.Id,c1.Email);
      
      ref1.Contact__c = null;
      ref1.Referral_Contact__c = rc1.Id;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref1;

      ref1 = verifyRef('testUpdate2',ref1.Id,rc1.Email__c);
      
      // put a contact without an email - email should null out
      ref1.Contact__c = c3.Id;
      ref1.Referral_Contact__c = null;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref1;

      ref1 = verifyRef('testUpdate2',ref1.Id,null);
      
      

      // test bulk loads - no contact
      Referral__c[] refs1 = new Referral__c[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         Referral__c ref = new Referral__c();
         refs1.add(ref);
      }
      
      // contact
      Referral__c[] refs2 = new Referral__c[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         Referral__c ref = new Referral__c(Contact__c = c1.Id);
         refs2.add(ref);
      }

      // referral contact
      Referral__c[] refs3 = new Referral__c[]{};
      for (Integer cnt=0; cnt<numRecs; cnt++) {
         Referral__c ref = new Referral__c(Referral_Contact__c = rc1.Id);
         refs3.add(ref);
      }
      
      Referral__c[] refs = new Referral__c[]{};
      refs.addAll(refs1);
      refs.addAll(refs2);
      refs.addAll(refs3);
      Test.startTest();
      ReferralTriggerActions.SKIP_TRIGGER=false;
      insert refs;
      Test.stopTest();
      
      // get the ids and test the results
      Id[] refIds1 = new Id[]{};
      for (Referral__c ref : refs1) {
         refIds1.add(ref.Id);
      }
      
      Id[] refIds2 = new Id[]{};
      for (Referral__c ref : refs2) {
         refIds2.add(ref.Id);
      }
      
      Id[] refIds3 = new Id[]{};
      for (Referral__c ref : refs3) {
         refIds3.add(ref.Id);
      }
      
      System.assertEquals(numRecs,[Select count() from Referral__c where Id in :refIds1 and Email__c = null]);
      System.assertEquals(numRecs,[Select count() from Referral__c where Id in :refIds2 and Email__c = :c1.Email]);
      System.assertEquals(numRecs,[Select count() from Referral__c where Id in :refIds3 and Email__c = :rc1.Email__c]);
      
      // test mass updates
      for (Referral__c ref : refs1) {
         ref.Contact__c = c2.Id;
      }
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update refs1;

      System.assertEquals(numRecs,[Select count() from Referral__c where Id in :refIds1 and Email__c = :c2.Email]);

      for (Referral__c ref : refs1) {
         ref.Contact__c = null;
         ref.Referral_Contact__c = rc2.Id;
      }
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update refs1;

      System.assertEquals(numRecs,[Select count() from Referral__c where Id in :refIds1 and Email__c = :rc2.Email__c]);

   } // checkPopulateEmail
   
   // Test when a referral gets changed to a Rejected status.
   @IsTest(SeeAllData=false)
   static void testRejected() {
      // create an account/opportunity/opportunity product
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      // set the OpportunityId__c field so default products are not created
      Opportunity o1= new Opportunity(AccountId=a1.Id, Name='Test Opp1',StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityId__c=c1.Id);
      insert o1;
      String[] prodNames= new String[]{'TestProd'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry entry = entries.get(0);
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=o1.Id, Quantity=1, TotalPrice=0, PricebookEntryId=entry.Id);
      insert oli;
      // create Referral
      
      Referral__c ref = new Referral__c();
      ref.SourceContact__c = c1.Id;
      ref.Account__c = a1.Id;
      ref.Status__c = 'Pending';
      ref.ReferringLineItemId__c = oli.Id;
      insert ref;
      
      // change status to rejected
      ref.Status__c = 'Rejected';
      //ref.Reject_Reason__c = 'This is a Test.';
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;
      
      oli = [Select Id, Status__c from OpportunityLineItem where Id=:oli.Id];
   //   System.assertEquals('Referral Rejected',oli.Status__c);
      
   } // testRejected

   // Test when a referral gets changed to an Approved status.
   @IsTest(SeeAllData=false)
   static void testApproved() {
      String[] prodNames= new String[]{'TestProd'};
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'TestSalesOrg', null);
      PricebookEntry entry = entries.get(0);
      
      // create an account/opportunity/opportunity product
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      // set the OpportunityId__c field so default products are not created
      Opportunity o1= new Opportunity(AccountId=a1.Id, Name='Test Opp1',StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityId__c=c1.Id);
      insert o1;
      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=o1.Id, Quantity=1, TotalPrice=0, PricebookEntryId=entry.Id);
      insert oli;
      
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_MMS,OpportunityCreateCase.RT_OPPTY_MMS, ReferralController.REF_INTERNAL);
      //Referral_Partner__c rp = new Referral_Partner__c(Name='MMS',Partner_Type__c=ReferralController.REF_INTERNAL, CreateRefOpp__c=true);
      //insert rp;
      // verify has a record type id
      //rp = [Select Id, Name, Selling_Opp_RecordTypeId__c from Referral_Partner__c where id=:rp.Id];
      System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
      
      // Select core and mms reps
      User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and HR_Person_Id__c != null limit 1];
      // verify a Contact record exists for the user
      // this is for the referring employee field on the opportunity
      if ([select count() from Contact where HR_Person_Id__c = :uCore.HR_Person_Id__c] == 0) {
         
         // verify Paychex Inc SA exists
         Account payxAcct = null;
         try {
            payxAcct = [Select Id, Name from Account where Name=:UserHelper.PAYCHEX_COMP];
         } catch (Exception e) {
            // if fails - create the account
            payxAcct = new Account(Name = UserHelper.PAYCHEX_COMP);
            insert payxAcct;
         }
         // create a contact record.
         Contact empCtct = new Contact(AccountId=payxAcct.Id, FirstName=uCore.FirstName, LastName=uCore.LastName, HR_Person_Id__c=uCore.HR_Person_Id__c);
         insert empCtct;
      }
      User uMMS = [Select Id, Name from User where IsActive=true and Sales_Org__c=:UserHelper.SO_MMS limit 1];

     // create referral contact with a task
     Referral_Account__c ra1 = new Referral_Account__c(Name='Joe CPA Firm',Referral_Source_Business_Type__c='Accounting Firm');
     insert ra1;
     Referral_Contact__c rc1 = new Referral_Contact__c(Name='Joe Contact1',Email__c='joecontact1test@paychex.com',Referral_Account__c=ra1.Id);
     insert rc1;
     Schema.RecordTypeInfo taskHRSrt = RecordTypeHelper.getRecordType('HRS Task Record Type', 'Task');
     Date tooday = Date.today();
        Task tsk1 = new Task(WhatId = rc1.Id, Subject = 'FA requests a conversation', 
                     Status = 'Referred', Lead_Source_WAR_Call_Type__c = 'Search Engine Test',
                     ActivityDate = tooday, Activity_Source__c = 'FAEmailSvc',
                     RecordTypeId = taskHRSrt.getRecordTypeId());
        insert tsk1;
        
      // create Referral
      Referral__c ref = new Referral__c();
      ref.Referral_Partner__c = rp.Id;
      ref.SourceContact__c = c1.Id;
      ref.Account__c = a1.Id;
      ref.Status__c = 'Pending';
      ref.ReferringLineItemId__c = oli.Id;
      ref.Referring_Opportunity__c = o1.Id;
      ref.Referring_User__c = uCore.Id;
      ref.User__c = uMMS.Id;
      ref.Referral_Contact__c = rc1.Id;
      insert ref;
      
      Test.StartTest();
      System.debug('testApproved set status to approved');
      ReferralTriggerActions.SKIP_TRIGGER=false;
      // change status to approved
      ref.Status__c = 'Approved';
      update ref;
      
      Test.StopTest();
      
      oli = [Select Id, Status__c from OpportunityLineItem where Id=:oli.Id];
      //System.assertEquals('Referral Approved',oli.Status__c);
      
      // verify selling opportunity was created
      ref = [Select Id, Selling_Opportunity__c, Referral_Contact__r.Id, Started_From__c from Referral__c where Id=:ref.Id];
      System.assertEquals(true,(ref.Selling_Opportunity__c != null));
      
      Opportunity opty = [Select Id, LeadSource_detail__c from Opportunity where Id =:ref.Selling_Opportunity__c];
      //System.assertEquals('Search Engine Test',opty.LeadSource_Detail__c);
      
      Referral__c[] listRef = new List<Referral__c>();
      listRef.add(ref);
      ReferralMethods.retrieveTasks(listRef);
      //System.assertEquals(true,ReferralMethods.retrieveTasks(listRef).containsKey(rc1.Id));
      
   } // testApproved

   // Test other methods for full test coverage
   @isTest
   static void testOthers() {
      System.assertEquals('TEST',ReferralMethods.getReferralFrom('TEST'));
      System.assertEquals(null,ReferralMethods.getReferralFrom(null));
      System.assertEquals('CORE',ReferralMethods.getReferralFrom(UserHelper.SO_CORE));
      System.assertEquals('PEO-ASO',ReferralMethods.getReferralFrom(UserHelper.SO_PEO_ASO));
      System.assertEquals('MMS',ReferralMethods.getReferralFrom('MMS'));
      ErrorLog__c errLog = new ErrorLog__c();
      
      String msg = ReferralMethods.getSaveMsg('Test',true,false,null,'ReferralMethodsTest','testOthers','testCode',null,errLog);
      System.assertEquals('Test Successfully Saved!',msg);
      
      // create a save error
      Lead l = new Lead();
      Database.SaveResult sr = Database.insert(l,false);
      msg = ReferralMethods.getSaveMsg('Lead',sr.isSuccess(),false,sr.getErrors(),'ReferralMethodsTest','testOthers','testCode',null,errLog);
      System.assertEquals(true,msg.startsWith('Lead Encountered an Error: '));
      String salesOrg = 'MMS';
      String salesDivision = 'Test';
      ReferralMethods.getCoam(salesOrg,salesDivision);
       
      Referral__c ref = new Referral__c();
      ref.Status__c = 'Pending';
      Id[] listRef = new List<Id>();
      Referral__c[] listRefs = new List<Referral__c>();
      listRef.add(ref.Id);
      listRefs.add(ref);
      ReferralMethods.handleApprovedFuture(listRef);
      ReferralMethods.syncRelatedOwnersFuture(listRef);
      ProcessInstance prcIns = new ProcessInstance(TargetObjectId = listRefs[0].Id, Status = 'Rejected');
      ReferralMethods.moveRejectedReasons(listRefs);
      
      System.assertEquals(Label.LeadSource_Ref_Internal_Emp,ReferralMethods.getReferralFromLeadSource(ref));
   /*   System.assertEquals(Label.LeadSource_Ref_Internal_Emp,ReferralMethods.getReferralFromLeadSource('TEST', null));
      System.assertEquals(Label.LeadSource_Ref_Internal_Emp,ReferralMethods.getReferralFromLeadSource('COE', null));
      System.assertEquals(Label.LeadSource_Ref_Internal_Core,ReferralMethods.getReferralFromLeadSource(UserHelper.SO_CORE, null));
      System.assertEquals(Label.LeadSource_Ref_Internal_MMS,ReferralMethods.getReferralFromLeadSource(UserHelper.SO_MMS, null));
      System.assertEquals(Label.LeadSource_Ref_Internal_HRS,ReferralMethods.getReferralFromLeadSource(UserHelper.SO_401, null));
      System.assertEquals(Label.LeadSource_Ref_Internal_HRSolution,ReferralMethods.getReferralFromLeadSource(UserHelper.SO_PEO_ASO, null));
      System.assertEquals(Label.LeadSource_Ref_Internal_HB,ReferralMethods.getReferralFromLeadSource(UserHelper.SO_HNB, null));
      System.assertEquals(Label.LeadSource_ReferralFA,ReferralMethods.getReferralFromLeadSource('TEST','Wholesaler'));      */
   } // testOthers
   
   // test nss referral
   @isTest
   static void testNSSRef() {
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_NSS);
      System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
      
      // Select core and mms reps
      User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and HR_Person_Id__c != null limit 1];
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      User outboundNSR = outboundNSRs[0];
      
      // create an account/contact
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;

      // create Referral
      Referral__c ref = new Referral__c();
      ref.Referral_Partner__c = rp.Id;
      ref.SourceContact__c = c1.Id;
      ref.Account__c = a1.Id;
      ref.Status__c = 'Approved';
      ref.Referring_User__c = uCore.Id;
      ref.User__c = uCore.Id;
      //ref.Referral_Contact__c = rc1.Id;
      ref.CreateSellerEvent__c = true;
      DateTime activityDT = DateTime.now().addDays(5);
      ref.ActivityDate__c = activityDT.date();
      ref.ActivityDateTime__c = activityDT;
      ref.CreateSellerTask__c = true;
      insert ref;
      
      ReferralMethods.handleApproved(new Id[]{ref.Id});

   } // testNSSRef
    
   // test Integrated Selling
   @isTest
   static void testINTSELL() {
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_INTSELL);
      System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
      
      // Select core and mms reps
      User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and HR_Person_Id__c != null limit 1];
      User uASO = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO and Profile.Name = :Utilities.PROF_HRS_PEO_ASO_SB and HR_Person_Id__c != null limit 1];
      // create an account/contact
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      // create ReferralJoin
      ReferralJoin__c refJoin = new ReferralJoin__c();
      insert refJoin;
       
      // create Referral
      Referral__c ref1 = new Referral__c(Name='Test MMS Referral');
      Referral__c ref2 = new Referral__c(Name='Test ASO Referral');
      Referral__c [] refs = new Referral__c[]{ref1, ref2};
      ref1.Referral_Partner__c = rp.Id;
      ref1.SourceContact__c = c1.Id;
      ref1.Account__c = a1.Id;
      ref1.Status__c = 'Approved';
      ref1.Referring_User__c = uCore.Id;
      ref1.User__c = uCore.Id;
      //ref.Referral_Contact__c = rc1.Id;
      ref1.CreateSellerEvent__c = true;
      ref1.ReferralJoin__c = refJoin.id;
      DateTime activityDT = DateTime.now().addDays(5);
      ref1.ActivityDate__c = activityDT.date();
      ref1.ActivityDateTime__c = activityDT;
      ref1.CreateSellerTask__c = true;
      ref2.Referral_Partner__c = rp.Id;
      ref2.SourceContact__c = c1.Id;
      ref2.Account__c = a1.Id;
      ref2.Status__c = 'Approved';
      ref2.Referring_User__c = uCore.Id;
      ref2.User__c = uASO.Id;
      //ref.Referral_Contact__c = rc1.Id;
      ref2.CreateSellerEvent__c = true;
      ref2.ReferralJoin__c = refJoin.id;
      ref2.ActivityDate__c = activityDT.date();
      ref2.ActivityDateTime__c = activityDT;
      ref2.CreateSellerTask__c = true;
      insert refs;
      
       ReferralMethods.handleApproved(new list<Id>{ref1.Id, ref2.Id});

   } // testINTSELL
   
   @isTest
   static void testRefPartnerName() {
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_MMS,OpportunityCreateCase.RT_OPPTY_MMS, ReferralController.REF_INTERNAL);
      
      Referral__c ref = new Referral__c();
      insert ref;
      ref = [Select Id, Name, Referral_Partner__c, ReferralPartnerName__c from Referral__c where Id=:ref.Id];
      System.assertEquals(null,ref.ReferralPartnerName__c);
      ref.Referral_Partner__c = rp.Id;
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;
      ref = [Select Id, Name, Referral_Partner__c, ReferralPartnerName__c from Referral__c where Id=:ref.Id];
      System.assertEquals(rp.Name,ref.ReferralPartnerName__c);
      
      
   } // testRefPartnerName
   
   @isTest
   static void testCheckDisposition() {
      ReferralMethods.LOCK_DISPOSITION = 'SLD';
      Referral__c ref = new Referral__c(Name='Test');
      insert ref;
      ref.ActualRevenue__c = 100;
      ref.Disposition__c = ReferralMethods.LOCK_DISPOSITION;
      ref.MonthSaleReported__c = Date.today().addDays(-10);
      ref.NbrOfEmployees__c = 30;
      ref.PendingRunOfPayroll__c = Date.today().addDays(10);
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;
      
      ref = [Select Id, Name, CommissionOverride__c, ActualRevenue__c, Disposition__c, MonthSaleReported__c, NbrOfEmployees__c, PendingRunOfPayroll__c from Referral__c where Id=:ref.Id];
      System.assertEquals(100,ref.ActualRevenue__c);
      System.assertEquals(ReferralMethods.LOCK_DISPOSITION, ref.Disposition__c);
      System.assertEquals(Date.today().addDays(-10), ref.MonthSaleReported__c);
      System.assertEquals(30, ref.NbrOfEmployees__c);
      System.assertEquals(Date.today().addDays(10), ref.PendingRunOfPayroll__c);
      
      ref.ActualRevenue__c = 200;
      ref.Disposition__c = 'PND';
      ref.MonthSaleReported__c = Date.today().addDays(-20);
      ref.NbrOfEmployees__c = 50;
      ref.PendingRunOfPayroll__c = Date.today().addDays(20);
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;
      
      // values shouldn't change
      ref = [Select Id, Name, CommissionOverride__c, ActualRevenue__c, Disposition__c, MonthSaleReported__c, NbrOfEmployees__c, PendingRunOfPayroll__c from Referral__c where Id=:ref.Id];
      System.assertEquals(100,ref.ActualRevenue__c);
      System.assertEquals(ReferralMethods.LOCK_DISPOSITION, ref.Disposition__c);
      System.assertEquals(Date.today().addDays(-10), ref.MonthSaleReported__c);
      System.assertEquals(30, ref.NbrOfEmployees__c);
      System.assertEquals(Date.today().addDays(10), ref.PendingRunOfPayroll__c);

      ref.CommissionOverride__c = true;
      ref.ActualRevenue__c = 200;
      ref.Disposition__c = 'PND';
      ref.MonthSaleReported__c = Date.today().addDays(-20);
      ref.NbrOfEmployees__c = 50;
      ref.PendingRunOfPayroll__c = Date.today().addDays(20);
      ReferralTriggerActions.SKIP_TRIGGER=false;
      update ref;
      
      // values shouldn't change
      ref = [Select Id, Name, CommissionOverride__c, ActualRevenue__c, Disposition__c, MonthSaleReported__c, NbrOfEmployees__c, PendingRunOfPayroll__c from Referral__c where Id=:ref.Id];
      System.assertEquals(200,ref.ActualRevenue__c);
      System.assertEquals('PND', ref.Disposition__c);
      System.assertEquals(Date.today().addDays(-20), ref.MonthSaleReported__c);
      System.assertEquals(50, ref.NbrOfEmployees__c);
      System.assertEquals(Date.today().addDays(20), ref.PendingRunOfPayroll__c);
      System.assertEquals(false,ref.CommissionOverride__c);

   } // testRejectReason

    @isTest
    static void testTransferTracking() {
        Referral__c ref = new Referral__c(Name='test Referral');
        insert ref;
        System.assertEquals(1,[select count() FROM Transfer_Tracking__c WHERE Referral_Lookup__c = :ref.Id ]);
        Group ibQueue = [SELECT Name,Id FROM Group WHERE Type='Queue' AND Name = 'NSS Inbound Queue'];
        ref.OwnerId = ibQueue.Id;
      ReferralTriggerActions.SKIP_TRIGGER=false;
        update ref;
        Transfer_Tracking__c[] tt = [SELECT Id,Assigned_to__c,Division__c,Assigned_to_Queue__c,Date_of_Assignment__c,Assignment_End_Date__c,Previous_Transfer_Tracking__c FROM Transfer_Tracking__c WHERE Referral_Lookup__c = :ref.Id ORDER BY CreatedDate ASC];
        system.assertEquals(2, tt.size());
        system.debug('tt: '+tt);
        system.assert(tt[0].Assigned_to__c !=null);
        system.assert(tt[0].Division__c !=null);
        system.assert(tt[1].Assigned_to_Queue__c !=null);
        system.assert(tt[0].Assignment_End_Date__c!=null);
        system.assert(tt[1].Assignment_End_Date__c==null);
        system.assertEquals(tt[0].Id,tt[1].Previous_Transfer_Tracking__c);
    }
    
    @isTest
    static void testOwnerSync(){
       // make sure this is the value we expect.
        ReferralMethods.exceptionValues = new Set<String>{'NSS Pending Queue'};
        Lead ld = new Lead(LastName='test',Company='test');
        insert ld;

        Account acct = new Account(Name = 'test acct');
        insert acct;
        Contact ctct = new Contact(LastName='test',AccountId = acct.Id);
        insert ctct;

        Referral__c ref = new Referral__c(Name='test Referral',SourceLead__c = ld.Id);
        insert ref;
        
        Id runningUserId = UserInfo.getUserId();
        User[] u = [Select Id FROM User WHERE IsActive = true AND Profile.Name = 'System Administrator' AND Id != :runningUserId LIMIT 2];
        Group obQueue = [SELECT Id,Name FROM Group WHERE Type = 'Queue' AND Name = 'NSS Pending Queue'];
        
        Test.startTest();
        
        ref.OwnerId = u[0].Id;
        System.debug('testOwnerSync setting ref owner as user1');
      ReferralTriggerActions.SKIP_TRIGGER=false;
        update ref;
        Lead uLd = [SELECT Id,OwnerId FROM Lead WHERE Id=:ld.Id];
        system.assertEquals(u[0].Id,uLd.OwnerId);
        
        ref.SourceContact__c=ctct.Id;
        ref.Account__c=acct.Id;
        ref.OwnerId = u[1].Id;
        System.debug('testOwnerSync setting ref owner as user2');
        ReferralTriggerActions.SKIP_TRIGGER = false;
        update ref;
        Contact uCtct = [SELECT Id,OwnerId FROM Contact WHERE Id=:ctct.Id];
        system.assertEquals(u[1].Id,uCtct.OwnerId);
        
        Opportunity oppty = new Opportunity(Name='Test Oppty',StageName='New',CloseDate=system.today());
        insert oppty;
        ref.Selling_Opportunity__c = oppty.Id;
        ref.OwnerId = u[0].Id;
        System.debug('testOwnerSync setting ref owner as user3');
        ReferralTriggerActions.SKIP_TRIGGER = false;
        update ref;
        Opportunity uOppty = [SELECT Id,OwnerId FROM Opportunity WHERE Id=:oppty.Id];
        system.assertEquals(u[0].Id,uOppty.OwnerId);
        
        ref.OwnerId = obQueue.Id;
        System.debug('testOwnerSync setting ref owner as queue');
        ReferralTriggerActions.SKIP_TRIGGER = false;
        update ref;
        uCtct = [SELECT Id,OwnerId,NSSOwnership__c FROM Contact WHERE Id=:ctct.Id];
        system.assertEquals(obQueue.Name,uCtct.NSSOwnership__c);
        
        Test.stopTest();
        
    } // testOwnerSync
    
   // test the code finding an existing opportunity and matching the referral to it. 
   static testMethod void testDuplicateCheck() {
      ReferralMethods.CHECK_DUPES_UNDER_70=true;
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_NSS);
      System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
      rp.CheckForDuplicates__c = true;
      rp.SellingOpportunityType__c='Payroll';
      update rp;
      
      // Select core reps
      User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and HR_Person_Id__c != null limit 1];
      
      // create an account/contact
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      
      Opportunity opp = new Opportunity(Name='Test Opp', StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityType__c='Payroll'
                                       ,AccountId=a1.Id, RecordTypeId=rp.Selling_Opp_RecordTypeId__c, OwnerId=uCore.Id);
      insert opp;
      
      Referral__c ref = new Referral__c(Referral_Partner__c=rp.Id, Name='Test Referral', Account__c=a1.Id, SourceContact__c=c1.Id, User__c=uCore.Id
                                       ,Referring_User__c=UserInfo.getUserId() );
      insert ref;
      
      Test.startTest();
      ReferralMethods.handleApproved(new Id[]{ref.Id});
      Test.stopTest();
      
      Referral__c checkRef = [Select Id, Selling_Opportunity__c, SellingOppInfo__c from Referral__c where Id=:ref.Id];
      // make sure it's reusing the existing opp, not creating a new one.
      System.assertEquals(opp.Id, checkRef.Selling_Opportunity__c);
       
      
   } // testDuplicateCheck
   
   public static String NOT_SOLD=Label.OppStage_Lost;
    
   // test the code finding an existing opportunity and matching the referral to it. If the owners are different, close one create new.
   static testMethod void testDuplicateCheck2() {
      ReferralMethods.CHECK_DUPES_UNDER_70=true;
      // create a referral partner record
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_NSS);
      System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
      rp.CheckForDuplicates__c = true;
      rp.SellingOpportunityType__c='Payroll';
      update rp;
      
      // Select core reps
      User[] users= [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and HR_Person_Id__c != null limit 2];
      User uCore1 = users[0];
      User uCore2 = users[1];
      
      // create an account/contact
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      
      Opportunity opp = new Opportunity(Name='Test Opp', StageName='Pending', CloseDate=Date.today().addDays(7), OpportunityType__c='Payroll'
                                       ,AccountId=a1.Id, RecordTypeId=rp.Selling_Opp_RecordTypeId__c, OwnerId=uCore1.Id);
      insert opp;
      
      Referral__c ref = new Referral__c(Referral_Partner__c=rp.Id, Name='Test Referral', Account__c=a1.Id, SourceContact__c=c1.Id, User__c=uCore2.Id
                                       ,Referring_User__c=UserInfo.getUserId() );
      insert ref;
      
      Test.startTest();
      ReferralMethods.handleApproved(new Id[]{ref.Id});
      Test.stopTest();
      
      Referral__c checkRef = [Select Id, Selling_Opportunity__c, SellingOppInfo__c from Referral__c where Id=:ref.Id];
      // It should not reuse the existing 
      System.assertNotEquals(opp.Id, checkRef.Selling_Opportunity__c);
      
      Opportunity checkOpp = [Select Id, Name, IsClosed, StageName, Reason_Not_Sold__c from Opportunity where Id=:opp.Id];
      System.assertEquals(NOT_SOLD, checkOpp.StageName);
      System.assertEquals(Label.OppDupe_ClosedOppReason, checkOpp.Reason_Not_Sold__c);
      
      
   } // testDuplicateCheck2
   @isTest
   static void testCreateActivityEventNoOpps(){ //testCreateActivity
      //create referral wrappers to test
      Referral__c ref = new Referral__c();
      ref.User__c = UserInfo.getUserId();
      Referral_Contact__c refctct = new Referral_Contact__c();
      Referral_Account__c refAcct = new Referral_Account__c(); 
      refAcct.Name = 'Anthony Mackey';
      refAcct.Street_Address_1__c = '200 Broadway blvd';
      refAcct.City__c = 'NY';
      refAcct.State_Province__c = 'NY';
      refAcct.Zip_Postal_Code__c = '10001';
      //refAcct.TimeZoneAbbrev__c = 'EST';
      Date testDate =  Date.today();
      ref.ActivityDate__c = testDate; //Todo add a week for the date 
      ref.ActivityDateTime__c = testDate.addDays(7); //Todo set a time for the meeting




      //set the referral Account
      refctct.Referral_Account__c = refAcct.Id;
      // set the activity date 


      Task[] tasksToInsert = new Task[]{};
      Event[] eventsToInsert = new Event[]{};

      String callType = '';
      String source = '';
      ref.CreateSellerEvent__c = true;
      ref.Account__c = null;
      ref.SourceContact__c = null;
      ref.Started_From__c='Referral_Contact__c';
      ref.Referral_Contact__c = refctct.Id;
      ReferralWrapper rw = new ReferralWrapper(); // Event without opportunities
      rw.sellingOppWasExisting = false;
      rw.ref = ref;

      // rw, istask, isEvent, noopportunity,taskstoInsert,EventsToInsert,callType,Source

      Test.startTest();
      ReferralMethods.createActivity(rw,tasksToInsert,eventsToInsert,callType,source);
      Test.stopTest();
      System.assert(eventsToInsert.size() > 0,'events to insert has not been incremented');
      System.assert(rw.evt != null,'no event created or tied to referral Wrapper');

   } // testCreateActivityEventNoOpps

   @isTest
   static void testCreateActivityEventWithOpp(){ //testCreateActivity
      //create referral wrappers to test
      Referral__c ref = new Referral__c();
      ref.User__c = UserInfo.getUserId();
      Account acct = new Account();
      acct.ShippingStreet = '3261 Promontory Circle';
      acct.ShippingCity='San Ramon';
      acct.ShippingState='CA';
      acct.ShippingPostalCode='94582';
      acct.Name='Matthew Blake';
      acct.TimeZoneAbbrev__c ='EST';
      Opportunity opp = new Opportunity();
      Contact ctct = new Contact();
      ctct.MailingStreet='1909 Eastlawn Drive';
      ctct.MailingCity='Midland';
      ctct.MailingState='MI';
      ctct.MailingPostalCode='48642';
      ctct.Phone='989-656-8888';
      ctct.MobilePhone='989-999-9999';
      ctct.Email='MBlake1234@nowhere.net';
      ref.SourceContact__c = ctct.Id;
      ref.Account__c = acct.Id; 
      

      //refAcct.TimeZoneAbbrev__c = 'EST';
      Date testDate =  Date.today();
      ref.ActivityDate__c = testDate; //Todo add a week for the date 
      ref.ActivityDateTime__c = testDate.addDays(7); //Todo set a time for the meeting

      //set the referral Account
      // set the activity date 


      Task[] tasksToInsert = new Task[]{};
      Event[] eventsToInsert = new Event[]{};

      String callType = '';
      String source = '';
      ref.CreateSellerEvent__c = true;
      ref.Account__c = null;
      ref.SourceContact__c = null;
      ref.Started_From__c='Referral_Contact__c';
      
      ReferralWrapper rw = new ReferralWrapper(); // Event without opportunities
      rw.sellingOppWasExisting = false;
      rw.ref = ref;
      rw.oppSelling = opp;

     // rw, istask, isEvent, noopportunity,taskstoInsert,EventsToInsert,callType,Source

      Test.startTest();
      ReferralMethods.createActivity(rw,tasksToInsert,eventsToInsert,callType,source);
      Test.stopTest();
      System.assert(eventsToInsert.size() > 0,'events to insert has not been incremented');
      System.assert(rw.evt != null,'no event created or tied to referral Wrapper');

   } // testCreateActivityEventWithOpp
    
   @isTest
   static void testCreateActivityTaskWithOpp(){ //testCreateActivity
      //create referral wrappers to test
      Referral__c ref = new Referral__c();
      ref.User__c = UserInfo.getUserId();
      Account acct = new Account();
      acct.ShippingStreet = '3261 Promontory Circle';
      acct.ShippingCity='San Ramon';
      acct.ShippingState='CA';
      acct.ShippingPostalCode='94582';
      acct.Name='Matthew Blake';
      acct.TimeZoneAbbrev__c ='EST';

      Opportunity opp = new Opportunity();
      Contact ctct = new Contact();
      ctct.MailingStreet='1909 Eastlawn Drive';
      ctct.MailingCity='Midland';
      ctct.MailingState='MI';
      ctct.MailingPostalCode='48642';
      ctct.Phone='989-656-8888';
      ctct.MobilePhone='989-999-9999';
      ctct.Email='MBlake1234@nowhere.net';
      ref.SourceContact__r = ctct;
      ref.Account__r = acct; 
      

      //refAcct.TimeZoneAbbrev__c = 'EST';
      Date testDate =  Date.today();
      ref.ActivityDate__c = testDate; //Todo add a week for the date 
      ref.ActivityDateTime__c = testDate.addDays(7); //Todo set a time for the meeting
     //set the referral Account
      // set the activity date 
      Task[] tasksToInsert = new Task[]{};
      Event[] eventsToInsert = new Event[]{};

      String callType = '';
      String source = '';
      ref.CreateSellerTask__c = true;
      ref.Started_From__c='Referral_Contact__c';
      
      ReferralWrapper rw = new ReferralWrapper(); // Event without opportunities
      rw.sellingOppWasExisting = false;
      rw.ref = ref;
      rw.oppSelling = opp;
      // rw, istask, isEvent, noopportunity,taskstoInsert,EventsToInsert,callType,Source

      Test.startTest();
      ReferralMethods.createActivity(rw,tasksToInsert,eventsToInsert,callType,source);
      Test.stopTest();
      System.assert(tasksToInsert.size() > 0,'events to insert has not been incremented');
      System.assert(rw.tsk != null,'no event created or tied to referral Wrapper');

   } // testCreateActivityTaskWithOpp
    
   @isTest
   static void testCreateChatterPost(){ //testCreateActivity
      //create referral wrappers to test
      Referral__c ref = new Referral__c();
      Referral_Contact__c refctct = new Referral_Contact__c();
      ref.User__c = UserInfo.getUserId();
      ref.OwnerId = UserInfo.getUserId();
      ref.Original_Owner_was_Queue__c = false;
      Account acct = new Account();
      acct.ShippingStreet = '3261 Promontory Circle';
      acct.ShippingCity='San Ramon';
      acct.ShippingState='CA';
      acct.ShippingPostalCode='94582';
      acct.Name='Matthew Blake';
      acct.TimeZoneAbbrev__c ='EST';
      Opportunity opp = new Opportunity();
      Contact ctct = new Contact();
      ctct.MailingStreet='1909 Eastlawn Drive';
      ctct.MailingCity='Midland';
      ctct.MailingState='MI';
      ctct.MailingPostalCode='48642';
      ctct.Phone='989-656-8888';
      ctct.MobilePhone='989-999-9999';
      ctct.Email='MBlake1234@nowhere.net';
      ref.SourceContact__c = ctct.Id;
      ref.Account__c = acct.Id; 
      ref.Referral_Contact__c = refctct.id;


      //refAcct.TimeZoneAbbrev__c = 'EST';
      Date testDate =  Date.today();
      ref.ActivityDate__c = testDate; //Todo add a week for the date 
      ref.ActivityDateTime__c = testDate.addDays(7); //Todo set a time for the meeting




      //set the referral Account
      // set the activity date 


      
      ReferralMethods.ChatterWrapper[] chatterPosts = new ReferralMethods.ChatterWrapper[]{};

      String callType = '';
      String source = '';
      ref.CreateSellerTask__c = true;
      ref.Started_From__c='Referral_Contact__c';
      
      ReferralWrapper rw = new ReferralWrapper(); // Event without opportunities
      rw.sellingOppWasExisting = false;
      rw.ref = ref;
      rw.oppSelling = opp;


      
      




      // rw, istask, isEvent, noopportunity,taskstoInsert,EventsToInsert,callType,Source

      Test.startTest();
      ReferralMethods.createChatterPost(rw, true, chatterPosts);
      Test.stopTest();
      System.assert(chatterPosts.size() > 0,'chatterPosts have not been incremented');


   }
   static testMethod void checkBankReferralFee() {
      
      id refAcctRT = RecordTypeHelper.getRecordType('Core Referral Source Record Type','Referral_Account__c').getRecordTypeId();
      
      Referral_Account__c parentRefAcct = new Referral_Account__c(Name = 'RefAcctCreate'
                                                               ,RecordTypeId = refAcctRT
                                                               ,Referral_Source_Business_Type__c = 'Financial Services'
                                                               ,Street_Address_1__c = '911 Panorama Trail South'
                                                               ,City__c = 'Rochester'
                                                               ,State_Province__c = 'NY'
                                                               ,Zip_Postal_Code__c = '14586'
                                                               ,Bank_Referral_Fee__c = 25);
      insert parentRefAcct;
      Referral_Account__c childRefAcct = new Referral_Account__c(Name = 'RefAcctCreate'
                                                            ,Recordtypeid = refAcctRT
                                                            ,Referral_Source_Business_Type__c = 'Financial Services'
                                                            ,Street_Address_1__c = '911 Panorama Trail South'
                                                            ,City__c = 'Rochester'
                                                            ,State_Province__c = 'NY'
                                                            ,Zip_Postal_Code__c = '14586');
      childRefAcct.Parent_Referral_Account__c = parentRefAcct.Id;
      insert childRefAcct;
      
      Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_NSS);
      
      // create an account/contact
      Account a1 = new Account(Name='Test Account');
      insert a1;
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      
      Referral__c ref = new Referral__c(Referral_Partner__c=rp.Id, Name='Test Referral'
                                          ,Referral_Account__c=childRefAcct.Id
                                          ,Account__c=a1.Id, SourceContact__c=c1.Id
                                          ,Referring_User__c=UserInfo.getUserId() );
      insert ref;
      

   }

   @isTest
   static void testGL() {
      // create a referral partner record
      String glRtName = 'Service Onboarding GL Case';
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(glRtName, ObjectHelper.OBJECT_CASE);


      Referral_Partner__c rp = new Referral_Partner__c(Name='GL', Partner_Type__c='NSS Referral',Ref_To_Type__c='User', IsActive__c=true, 
                                                      Case_RecordTypeId__c=rt.getRecordTypeId(), CheckPartnerReferral__c=true, SetProspectOwnership__c=true,
                                                      CheckForDuplicates__c=true);
      insert rp;
      // Select core and mms reps
      User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Profile.Name like :Utilities.PROF_CORE_SALES+'%' and HR_Person_Id__c != null limit 1];

      
      // create an account/contact
      Lead ld = new Lead(LastName='test',Company='test');
	  insert ld;
       
      PartnerReferral__c pr = new PartnerReferral__c(FirstName__c='Test',LastName__c='Person', Lead__c=ld.Id,Company__c='Test Company');
      insert pr;
       
      Campaign camp = new Campaign(Name='TestCampaign',IsActive=true,Product__c='Prod2',LeadSource__c='Camp2LeadSource');
      insert camp;
       
      Marketing_Call_Tracking__c mct = new Marketing_Call_Tracking__c(Lead__c=ld.Id, Source__c='TestMethod', Campaign_ID__c=camp.Id, Keywords__c='LotsOfWords'
                                                                      ,Partner_Referral__c= pr.Id, gl_CPA_Company_Name__c='Test GL company');
      insert mct;
       
      Account a1 = new Account(Name='Test Account');
      insert a1;
       
      Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
      insert c1;
      
      // create Referral
      Referral__c ref = new Referral__c();
      ref.Referral_Partner__c = rp.Id;
      ref.SourceContact__c = c1.Id;
      ref.SourceLead__c = ld.Id;
      ref.Account__c = a1.Id;
      ref.Status__c = 'Approved';
      ref.Referring_User__c = uCore.Id;
      ref.User__c = uCore.Id;
      ref.PartnerReferral__c = pr.Id;
      insert ref;
      
      ReferralMethods.handleApproved(new Id[]{ref.Id});
      Referral__c refChck = [Select Id, Case__c from Referral__c where Id=:ref.Id];
      System.assertEquals(true,(refChck.Case__c!=null));


   } // testGL

   /**BAU Changes**/
@isTest(SeeAllData=false)
static void testOasisSDR(){
   
   // Select core and mms reps
   // User uCore = [Select Id, Name, FirstName, LastName, Email, HR_Person_Id__c,UserRole.Name,Profile.Name from User where IsActive=true and UserRole.Name='Oasis SDR' and Profile.Name='Oasis Outbound Rep' limit 1];
   // User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
   // User outboundNSR = outboundNSRs[0];

   UserRole userrole=new UserRole(Name='Oasis SDR'); 
   insert userrole; 
   Profile prof = [select id from profile where name='Oasis Outbound Rep'];
   User uCore = new User(Alias = 'kruff1',TimeZoneSidKey='America/Los_Angeles',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US' ,LocaleSidKey='en_US');
   uCore.firstName ='Kent1';
   uCore.lastName = 'Ruffo1';
   uCore.profileId = prof.id;
   uCore.username ='kruffo1@paychex.com.fullsandbx';
   uCore.email ='kruffo1@oasispeo.com.invalid';
   uCore.UserRoleId =userrole.Id;
   //uCore.managerId=userManager.Id;
   //uCore.Sales_Org__c='PEO';
   uCore.Sales_Org__c='NSS';
   insert uCore;

   System.runAs(uCore){
         // create a referral partner record
   Referral_Partner__c rp = ReferralPartnerMethodsTest.setupReferralPartner(UserHelper.SO_CORE,OpportunityCreateCase.RT_OPPTY_CORE, ReferralController.REF_NSS);
   System.assertEquals(true,(rp.Selling_Opp_RecordTypeId__c != null));
   
   
   // create an account/contact
   Account a1 = new Account(Name='Test Account');
   Id recid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('MMS Account Record Type').getRecordTypeId();
   a1.RecordtypeId=recid;
   insert a1;
   Contact c1 = new Contact(AccountId=a1.Id, LastName='TestLast1');
   insert c1;
   Account acc1 = new Account(Name='Test Child Account');
   Id recid1=Schema.SObjectType.Account.getRecordTypeInfosByName().get('MMS Account Record Type').getRecordTypeId();
   acc1.RecordtypeId=recid1;
   acc1.SalesParent__c=a1.id;
   insert acc1;
   Contact c2 = new Contact(AccountId=acc1.Id, LastName='TestLast2');
   insert c2;
   // create Referral
   List<Id> lstRefId=new List<Id>();
   Referral__c ref = new Referral__c();
   ref.Referral_Partner__c = rp.Id;
   ref.SourceContact__c = c2.Id;
   ref.Account__c = acc1.Id;
   ref.Status__c = 'Approved';
   ref.Referring_User__c = uCore.Id;
   ref.User__c = uCore.Id;
   //ref.Referral_Contact__c = rc1.Id;
   ref.CreateSellerEvent__c = true;
   DateTime activityDT = DateTime.now().addDays(5);
   ref.ActivityDate__c = activityDT.date();
   ref.ActivityDateTime__c = activityDT;
   ref.CreateSellerTask__c = true;
   insert ref;
   lstRefId.add(ref.Id);

   Referral__c ref1 = new Referral__c();
   ref1.Referral_Partner__c = rp.Id;
   ref1.SourceContact__c = c2.Id;
   ref1.Account__c = acc1.Id;
   ref1.Status__c = 'Approved';
   ref1.Referring_User__c = uCore.Id;
   ref1.User__c = uCore.Id;
   ref1.CreateSellerEvent__c = true;
   DateTime activityDT1 = DateTime.now().addDays(5);
   ref1.ActivityDate__c = activityDT1.date();
   ref1.ActivityDateTime__c = activityDT1;
   ref1.CreateSellerTask__c = true;
   insert ref1;
   lstRefId.add(ref1.Id);
   
   test.starttest();
   //ReferralMethods.handleApproved(new Id[]{ref.Id});
   ReferralMethods.handleApproved(lstRefId);
   test.stopTest();

   }



}
    

    
/**BAU Changes**/

    @isTest
    static void testUpdateDSAOppty(){
       testDsaOppLinking();
        
    } // testUpdateDSAOppty

    public static void testDsaOppLinking() {
        User[] reps = [Select Id, FirstName, LastName, HR_Person_ID__c from User where IsActive=true and HR_Person_Id__c != null and Job_Name__c=:UserHelper.JOB_REP limit 2];
        Contact empCtct = new Contact(FirstName=reps[0].FirstName, LastName=reps[0].LastName, HR_Person_Id__c=reps[0].HR_Person_Id__c, User_Lookup__c=reps[0].Id);
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        insert empCtct;
        
        Account acct = new Account(Name='test Account');
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert acct;
        
        Opportunity oppty = new Opportunity(Name='Test Oppty',AccountId=acct.Id, StageName='New',CloseDate=system.today(), ownerId = UserInfo.getUserId()
                                            , Referring_Employee__c=empCtct.Id);
        insert oppty;
        
		Referral__c ref = new Referral__c(Name='test Referral');
        ref.Primary__c = false;
        insert ref;
		
		DS_Denali__DialSource_Sessions_V3__c dsaSession = new DS_Denali__DialSource_Sessions_V3__c();
        dsaSession.Name = 'TestSession';
        insert dsaSession;	
		
		DS_Denali__DialSource_Action__c dsa = new DS_Denali__DialSource_Action__c();
		dsa.DS_Denali__DialSource_Session__c =  dsaSession.Id;
        dsa.DS_Denali__Owner__c = reps[0].Id;
        dsa.DS_Denali__Account__c = acct.Id;
		insert dsa;
        
        ref.Selling_Opportunity__c = oppty.Id;
          ref.Primary__c = True;
          ReferralTriggerActions.SKIP_TRIGGER=false;
          update ref;
		DS_Denali__DialSource_Action__c dsaObj = [Select Id,DS_Denali__Opportunity__c from DS_Denali__DialSource_Action__c LIMIT 1];
        
		Assert.areEqual(dsaObj.DS_Denali__Opportunity__c, ref.Selling_Opportunity__c);

    } // testDsaOppLinking

    static testMethod void testDsaOppQueueable() {
        User[] reps = [Select Id, FirstName, LastName, HR_Person_ID__c from User where IsActive=true and HR_Person_Id__c != null and Job_Name__c=:UserHelper.JOB_REP limit 2];
        Contact empCtct = new Contact(FirstName=reps[0].FirstName, LastName=reps[0].LastName, HR_Person_Id__c=reps[0].HR_Person_Id__c, User_Lookup__c=reps[0].Id);
        ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
        ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
        insert empCtct;
        
        Account acct = new Account(Name='test Account');
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert acct;
        
        Opportunity oppty = new Opportunity(Name='Test Oppty',AccountId=acct.Id, StageName='New',CloseDate=system.today(), ownerId = UserInfo.getUserId()
                                            , Referring_Employee__c=empCtct.Id);
        insert oppty;
        
		Referral__c ref = new Referral__c(Name='test Referral');
        ref.Primary__c = false;
        insert ref;

        Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=ReferralMethods.QUEUEABLE_NAME, Active__c=true, NbrOfAttempts__c=2, Minutes_till_Launch__c=1);
        insert abc;
        Test.startTest();
        ref.Selling_Opportunity__c = oppty.Id;
        ref.Primary__c = True;
        ReferralTriggerActions.SKIP_TRIGGER=false;
        update ref;
        Test.stopTest();

    } // testDsaOppQueueable

} // ReferralMethodsTest