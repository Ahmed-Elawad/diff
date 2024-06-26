/* 
 * Test Methods for the DuplicateCheck class
 *
 * History
 * -------
   03/02/2018 Dan Carmen       Created
   04/11/2018 Dan Carmen       Modifications for using merge() and convertLead()
   04/27/2018 Dan Carmen       Adjustments for Marketo
   11/12/2019 Dan Carmen       Changes to handle an inactive account user on lead convert
   10/18/2022 Dan Carmen       Change excludeCopyFldSet to a Label
   12/06/2022 Dan Carmen       Changed to be able to use SF Duplicate Management
   12/13/2022 Pujitha Madamanchi    Added Form Fill Date to Contact queries.
   09/26/2023 Dan Carmen       Removed Dupeblocker code

*/
@isTest
private class DuplicateCheckTest {

   @testSetup
   private static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = 'DuplicateCheckQueueable', Active__c = true, BatchSize__c=1);
      insert abc;
      Account acct = new Account(Name='Test Account', BillingStreet= '234 Some Ave', BillingCity='City', BillingState='NY', BillingPostalCode='12345', Owner_Zip_Code__c='12345');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      Contact ctct = new Contact(FirstName='Joe', LastName='Contact', Email='firstemail@test.com', Phone='(555) 123-4567', Title='Test', AccountId=acct.Id
                                 ,MailingPostalCode='12345');
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctct;
   } // setupData
   
   public static Account getTestAcct() {
      Account acct = [Select Id, Owner.Id, Owner.IsActive, OwnerId, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, Owner_Zip_Code__c
                            ,(Select Id, Owner.Id, Owner.IsActive, OwnerId, Name, FirstName, LastName, Email, Phone, Title, Profiled__c, AccountId, Form_Fill_Date__c from Contacts)
                        From Account
                       Where Name='Test Account'];
      return acct;
   } // getTestAcct

   public static String ACCT_COPY_FLDS='Name,Company,false,false:BillingStreet,Street,false,false:BillingCity,City,false,false'
                                      +':BillingState,State,false,false:BillingPostalCode,PostalCode,false,false'
                                      +':Employees__c,NumberOfEmployees,false,false';

   public static String CTCT_COPY_FLDS='LastName,LastName,false,false:FirstName,FirstName,false,false:Email,Email,false,false'
                                      +':Phone,Phone,false,false:MobilePhone,MobilePhone,false,false:OwnedBy__c,OwnedBy__c,false,false'
                                      +':MailingStreet,Street,false,false:MailingCity,City,false,false:MailingState,State,false,false'
                                      +':MailingPostalCode,PostalCode,false,false:MailingCountry,Country,false,false'
                                      +':TransactionId__c,TransactionId__c,false,false';

   static testMethod void checkLeadMatch() {
      Lead ld1 = new Lead(Company='Test Company', FirstName='TestFirst', LastName='TestLast', Email='testlast@testcompany.com', PostalCode='12345');
      insert ld1;
      
      Lead ld2 = new Lead(Company='Test Company', FirstName='TestFirst', LastName='TestLast', Email='testlast@testcompany.com', PostalCode='12345');
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
         System.assertEquals(true,DuplicateCheck.checkForDuplicates(new SObject[]{ld2}, ObjectHelper.OBJECT_LEAD));
         System.assertEquals(1,DuplicateCheck.allRecsChecked.size());
         DuplicateCheck.DupeWrapper dupeWrap = DuplicateCheck.allRecsChecked[0];
         System.assertEquals(ld1.Id, dupeWrap.matchLead.Id);
           
      }
   } // checkLeadMatch
   
   static testMethod void checkAcctMatch() {
      Account acct = getTestAcct();
      
      Lead ld2 = new Lead(Company='Test Account', LastName='TestLast', Email='testlast@testcompany.com', PostalCode='12345');
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
         System.assertEquals(true,DuplicateCheck.checkForDuplicates(new SObject[]{ld2}, ObjectHelper.OBJECT_LEAD));
         System.assertEquals(1,DuplicateCheck.allRecsChecked.size());
         DuplicateCheck.DupeWrapper dupeWrap = DuplicateCheck.allRecsChecked[0];
         System.assertEquals(acct.Id, dupeWrap.matchAcct.Id);
      }
   } // checkAcctMatch
   
    static testMethod void checkCtctMatch() {
      Account acct = getTestAcct();
      Contact ctct = acct.Contacts[0];
      
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
            
         Lead ld2 = new Lead(Company=acct.Name, FirstName=ctct.FirstName, LastName=ctct.LastName, Email=ctct.Email, PostalCode=acct.Owner_Zip_Code__c);
         System.assertEquals(true,DuplicateCheck.checkForDuplicates(new SObject[]{ld2}, ObjectHelper.OBJECT_LEAD));
         System.assertEquals(1,DuplicateCheck.allRecsChecked.size());
         DuplicateCheck.DupeWrapper dupeWrap = DuplicateCheck.allRecsChecked[0];
         System.assertEquals(ctct.Id, dupeWrap.matchCtct.Id);
         System.assertEquals(null,dupeWrap.matchAcct);
      }
   } // checkCtctMatch

   static testMethod void testLeadMatchQueuable() {
      Lead ld1 = new Lead(Company='Test Company', FirstName='TestFirst', LastName='TestLast', Email='testlast@testcompany.com', Phone='585-123-4567', PostalCode='12345', TransactionId__c='DoNotKeep');
      Lead ld2 = new Lead(Company='Test Company', FirstName='TestFirst', LastName='TestLast', Email='testlast@testcompany.com', PostalCode='12345', TransactionId__c='A12345');
      Lead[] lds = new Lead[]{ld1,ld2};
      insert lds;
      
      Datetime checkDt = Datetime.now().addDays(-7);
      Test.setCreatedDate(ld1.Id, checkDt);
      
      // create activity to see if it's reparented
      Task tsk1 = new Task(WhoId=ld1.Id, ActivityDate=Date.today(), Subject='Test Task1');
      insert tsk1;
      
      Id ld2Id = ld2.Id;
      Id ld1Id = ld1.Id;
      
      // simulate being launched from the trigger
      PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(ld2);
      Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
      dupeCheckMap.put(ld2.TransactionId__c, partRef);
      SObject[] recsToCheck = new SObject[]{ld2};
      
      DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, recsToCheck);
      
      System.assertEquals(1,[select count() from Task where WhoId=:ld1Id]);
      
      Test.startTest();
      System.enqueueJob(dcq);
      Test.stopTest();
      /*
      // ld2 should be deleted
      System.assertEquals(0,[select count() from Lead where Id=:ld1Id]);
      // only 1 lead in existence
      System.assertEquals(1,[select count() from Lead]);

      // check that the task is reparented by the merge
      System.assertEquals(0,[select count() from Task where WhoId=:ld1Id]);
      System.assertEquals(1,[select count() from Task where WhoId=:ld2Id]);

      
      Lead ld2Check = [Select Id, Name, Company, FirstName, LastName, Email, Phone, TransactionId__c, WebLead__c, CreatedDate from Lead where Id=:ld2.Id];
      // make sure the name doesn't change
      System.assertEquals(ld2.Company, ld2Check.Company);
      System.assertEquals(ld1.Phone, ld2Check.Phone);
      System.assertEquals(checkDt, ld2Check.CreatedDate);
      */
   } // testLeadMatchQueuable

   static testMethod void testAcctMatchQueuable() {

      Account acct = getTestAcct();
      
      Lead newLd = new Lead(Company=acct.Name, Street=acct.BillingStreet, City=acct.BillingCity, State=acct.BillingState, PostalCode=acct.BillingPostalCode
                           ,FirstName='Timmy', LastName='Taylor', Phone='(585) 555-1234'
                           ,Email='taylor@test.com', TransactionId__c='ThisIsATestId1', NumberOfEmployees=10, Form_Fill_Date__c=system.today());
      insert newLd;
      Id newLdId = newLd.Id;
      
      // simulate being launched from the trigger
      PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(newLd);
      Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
      dupeCheckMap.put(newLd.TransactionId__c, partRef);
      SObject[] recsToCheck = new SObject[]{newLd};
      
      DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, recsToCheck);
      
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
         Test.startTest();
         System.enqueueJob(dcq);
         Test.stopTest();
      }
      
      // newLd should be converted
      Lead checkLd = [Select Id, IsConverted, Company, FirstName, LastName, Email, Phone, TransactionId__c
                            ,Street, City, State, PostalCode
                            ,ConvertedAccountId, ConvertedContactId
                        From Lead
                       Where Id=:newLdId];
      Assert.isTrue(checkLd.IsConverted);
      Assert.areEqual(acct.Id, checkLd.ConvertedAccountId);
      
      Contact ctct = [Select Id, FirstName, LastName, Email, TransactionId__c, MailingStreet, MailingCity, MailingState, MailingPostalCode
                            ,ProcessNotes__c, Form_Fill_Date__c
                        From Contact
                       Where Id=:checkLd.ConvertedContactId];
                       
      Assert.areEqual(newLd.FirstName, ctct.FirstName);
      Assert.areEqual(newLd.LastName, ctct.LastName);
      Assert.areEqual(newLd.Email, ctct.Email);
      Assert.areEqual(newLd.TransactionId__c, ctct.TransactionId__c);
      Assert.areEqual(newLd.Street, ctct.MailingStreet);
      Assert.areEqual(newLd.City, ctct.MailingCity);
      Assert.areEqual(newLd.State, ctct.MailingState);
      Assert.areEqual(newLd.PostalCode, ctct.MailingPostalCode);
      Assert.isTrue(ctct.ProcessNotes__c.contains('checkForDuplicatesSF hasResults'), 'Did not find checkForDuplicates ProcessNotes__c='+ctct.ProcessNotes__c);
      
      Account checkAcct = [Select Id, Name
                                 ,Employees__c, NumberOfEmployees
                                 ,BillingStreet, BillingState, BillingCity, BillingPostalCode
                             From Account
                            Where Id = :checkLd.ConvertedAccountId];
                            
      Assert.areEqual(newLd.Company, checkAcct.name);
      Assert.areEqual(newLd.Street, checkAcct.BillingStreet);
      Assert.areEqual(newLd.City, checkAcct.BillingCity);
      Assert.areEqual(newLd.State, checkAcct.BillingState);
      Assert.areEqual(newLd.PostalCode, checkAcct.BillingPostalCode);
      Assert.areEqual(newLd.NumberOfEmployees, checkAcct.Employees__c);

   } // testAcctMatchQueueable

   static testMethod void testCtctMatchQueuable() {
      Account acct = getTestAcct();
      Contact ctct = acct.Contacts[0];
      
      Lead newLd = new Lead(Company=acct.Name, Street=acct.BillingStreet, City=acct.BillingCity, State=acct.BillingState, PostalCode=acct.BillingPostalCode
                           ,FirstName=ctct.FirstName, LastName=ctct.LastName
                           ,Email=ctct.Email, Phone=ctct.Phone, TransactionId__c='ThisIsATestId1'
                           ,CreatedByProcess__c=DoNotSyncCheck.CREATED_BY_MARKETO);
      insert newLd;
      Id newLdId = newLd.Id;
      
      // simulate being launched from the trigger
      PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(newLd);
      Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
      dupeCheckMap.put(newLd.TransactionId__c, partRef);
      SObject[] recsToCheck = new SObject[]{newLd};
      
      DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, recsToCheck);
      
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
         Test.startTest();
         System.enqueueJob(dcq);
         Test.stopTest();
      }
      
      // newLd should be converted
      System.assertEquals(1,[select count() from Lead where Id=:newLdId and IsConverted=true]);
      
      Contact checkCtct = [Select Id, FirstName, LastName, Email, TransactionId__c, MailingStreet, MailingCity, MailingState, MailingPostalCode
                                 ,ProcessNotes__c, CreatedByProcess__c, Do_Not_Sync__c, Form_Fill_Date__c
                             From Contact
                            Where Id=:ctct.Id];
                       
      System.assertEquals(newLd.FirstName, checkCtct.FirstName);
      System.assertEquals(newLd.LastName, checkCtct.LastName);
      System.assertEquals(newLd.Email, checkCtct.Email);
      System.assertEquals(newLd.TransactionId__c, checkCtct.TransactionId__c);
      System.assertEquals(newLd.Street, checkCtct.MailingStreet);
      System.assertEquals(newLd.City, checkCtct.MailingCity);
      System.assertEquals(newLd.State, checkCtct.MailingState);
      System.assertEquals(newLd.PostalCode, checkCtct.MailingPostalCode);
      //System.assertEquals(true,checkCtct.ProcessNotes__c.contains('checkForDuplicates matchSets'), 'Did not find checkForDuplicates ProcessNotes__c='+ctct.ProcessNotes__c);
      System.assertEquals(DoNotSyncCheck.CREATED_BY_MARKETO, checkCtct.CreatedByProcess__c);
      System.assertEquals(false,checkCtct.Do_Not_Sync__c);

      Account checkAcct = [Select Id, Name
                                 ,Employees__c, NumberOfEmployees
                                 ,BillingStreet, BillingState, BillingCity, BillingPostalCode
                             From Account
                            Where Id = :acct.Id];
                            
      System.assertEquals(newLd.Company, checkAcct.name);
      System.assertEquals(newLd.Street, checkAcct.BillingStreet);
      System.assertEquals(newLd.City, checkAcct.BillingCity);
      System.assertEquals(newLd.State, checkAcct.BillingState);
      System.assertEquals(newLd.PostalCode, checkAcct.BillingPostalCode);
      System.assertEquals(newLd.NumberOfEmployees, checkAcct.Employees__c);


   } // testCtctMatchQueuable


   static testMethod void testNoMatchQueuable() {
      Lead newLd = new Lead(Company='Test Lead', Street='123 Any St', City='Some City', State='NY', PostalCode='14604'
                           ,FirstName='Timmy', LastName='Taylor'
                           ,Email='taylor@test.com', TransactionId__c='ThisIsATestId1'
                           ,WebLead__c=true, OwnedBy__c=TrackRecordEntry.WEBLEAD);
      insert newLd;

      // simulate being launched from the trigger
      PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(newLd);
      Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
      dupeCheckMap.put(newLd.TransactionId__c, partRef);
      SObject[] recsToCheck = new SObject[]{newLd};
      
      DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, recsToCheck);
      
      Test.startTest();
      System.enqueueJob(dcq);
      Test.stopTest();
      
      Lead checkld = [Select Id, Company, Street, City, State, PostalCode
                            ,FirstName, LastName, Email, TransactionId__c, WebLead__c, OwnedBy__c
                            ,DuplicateCheckStatus__c
                        From Lead
                       Where Id=:newLd.Id];
      //System.assertEquals(false, checkLd.WebLead__c);
      System.assertEquals(TrackRecordEntry.WEBLEAD, checkLd.OwnedBy__c);
      System.assertEquals(newLd.Company, checkLd.Company);
      System.assertEquals('No Match Found',checkLd.DuplicateCheckStatus__c);
      
   } // testNoMatchQueuable

   public static void setupDataGovernance() {
      DataGovernance__c[] dgs = new DataGovernance__c[]{};
      dgs.add(new DataGovernance__c(Name='setting01',UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='FirstName'));
      dgs.add(new DataGovernance__c(Name='setting02',UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='LastName'));
      dgs.add(new DataGovernance__c(Name='setting03',UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Email'));
      dgs.add(new DataGovernance__c(Name='setting04',UserType__c=CheckDataGovernance.LEAD_LOADER,Type__c=CheckDataGovernance.IS_PROFILED,ObjectName__c=ObjectHelper.OBJECT_CONTACT,FieldName__c='Phone'));
      insert dgs;
   } // setupDataGovernance

   static testMethod void testProfiled() {
      setupDataGovernance();
      // so the trigger fires as lead loader
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);

      Account acct = getTestAcct();
      Contact ctct = acct.Contacts[0];
      ctct.Profiled__c=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      update ctct;
      
      
      Lead newLd = new Lead(Company=acct.Name, Street=acct.BillingStreet, City=acct.BillingCity, State=acct.BillingState, PostalCode=acct.BillingPostalCode
                           ,FirstName=ctct.FirstName, LastName=ctct.LastName
                           ,Email=ctct.Email, Phone=ctct.Phone, TransactionId__c='ThisIsATestId1'
                           ,CreatedByProcess__c=DoNotSyncCheck.CREATED_BY_MARKETO);
      insert newLd;
      Id newLdId = newLd.Id;
      
      // simulate being launched from the trigger
      PartnerReferral__c partRef = TrackRecordEntry.logOriginalData(newLd);
      Map<String, PartnerReferral__c> dupeCheckMap = new Map<String, PartnerReferral__c>();
      dupeCheckMap.put(newLd.TransactionId__c, partRef);
      SObject[] recsToCheck = new SObject[]{newLd};
      
      DuplicateCheckQueueable dcq = new DuplicateCheckQueueable(dupeCheckMap, recsToCheck);
      
      User testUser = DuplicateHelperTest.getDupeTestUser();
      System.runAs(testUser) {
         Test.startTest();
         System.enqueueJob(dcq);
         Test.stopTest();
      }
      
      // newLd should be converted
      System.assertEquals(1,[select count() from Lead where Id=:newLdId and IsConverted=true]);
      
      Contact checkCtct = [Select Id, FirstName, LastName, Email, Phone, TransactionId__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, Form_Fill_Date__c
                        From Contact
                       Where Id=:ctct.Id];
                       
      System.assertEquals(ctct.FirstName, checkCtct.FirstName);
      System.assertEquals(ctct.LastName, checkCtct.LastName);
      System.assertEquals(ctct.Email, checkCtct.Email);
      System.assertEquals(ctct.Phone, checkCtct.Phone);
      System.assertEquals(newLd.TransactionId__c, checkCtct.TransactionId__c);
      System.assertEquals(newLd.Street, checkCtct.MailingStreet);
      System.assertEquals(newLd.City, checkCtct.MailingCity);
      System.assertEquals(newLd.State, checkCtct.MailingState);
      System.assertEquals(newLd.PostalCode, checkCtct.MailingPostalCode);

      Account checkAcct = [Select Id, Name
                                 ,Employees__c, NumberOfEmployees
                                 ,BillingStreet, BillingState, BillingCity, BillingPostalCode
                             From Account
                            Where Id = :acct.Id];
                            
      System.assertEquals(newLd.Company, checkAcct.name);
      System.assertEquals(newLd.Street, checkAcct.BillingStreet);
      System.assertEquals(newLd.City, checkAcct.BillingCity);
      System.assertEquals(newLd.State, checkAcct.BillingState);
      System.assertEquals(newLd.PostalCode, checkAcct.BillingPostalCode);
      System.assertEquals(newLd.NumberOfEmployees, checkAcct.Employees__c);

      
   } // testProfiled

   static testMethod void testCheckMarketingStage() {
      MarketingStage__mdt[] mktgStages = [Select MasterLabel, SortOrder__c from MarketingStage__mdt];
      String stage1 = null;
      String stage2 = null;
      // grab 2 random stages
      for (MarketingStage__mdt mktgStage : mktgStages) {
         if (stage1 == null && mktgStage.SortOrder__c < 40) {
            stage1 = mktgStage.MasterLabel;
         }
         if (stage2 == null && mktgStage.SortOrder__c > 40) {
            stage2 = mktgStage.MasterLabel;
         }
         if (stage1 != null && stage2 != null) {
            break;
         }
      } // for (MarketingStage__mdt mktgStage
      
      Contact ctct = new Contact(LastName='TestLast');
      DuplicateCheckQueueable.checkMarketingStage(ctct, 'Contact_Stage__c', null);
      System.assertEquals(true, ctct.ProcessNotes__c.contains('No Lead Stage'));
      System.assertEquals(null, ctct.Contact_Stage__c);
      
      // no existing contact stage - using what's passed in
      ctct.ProcessNotes__c=null;
      DuplicateCheckQueueable.checkMarketingStage(ctct, 'Contact_Stage__c', stage1);
      System.assertEquals(true, ctct.ProcessNotes__c.contains('No existing Marketing Stage'));
      System.assertEquals(stage1, ctct.Contact_Stage__c);

      // passing in a higher ranker stage to change
      ctct.ProcessNotes__c=null;
      DuplicateCheckQueueable.checkMarketingStage(ctct, 'Contact_Stage__c', stage2);
      System.assertEquals(true, ctct.ProcessNotes__c.contains('changing Marketing Stage to'));
      System.assertEquals(stage2, ctct.Contact_Stage__c);
      
      // passing in a lower stage
      ctct.ProcessNotes__c=null;
      DuplicateCheckQueueable.checkMarketingStage(ctct, 'Contact_Stage__c', stage1);
      System.assertEquals(true, ctct.ProcessNotes__c.contains('not changing Marketing Stage'));
      System.assertEquals(stage2, ctct.Contact_Stage__c);
      
      // passing in the same values - nothing happens
      ctct.ProcessNotes__c=null;
      DuplicateCheckQueueable.checkMarketingStage(ctct, 'Contact_Stage__c', stage2);
      System.assertEquals(null, ctct.ProcessNotes__c);
      System.assertEquals(stage2, ctct.Contact_Stage__c);
      
   } // testCheckMarketingStage

   static testMethod void testInactiveLeadConvert() {
      Account acct = getTestAcct();
      //Contact ctct = acct.Contacts[0];
      // set the account owner to inactive
      User inactiveRep = [Select Id, Name from User where IsActive=false and Job_Name__c=:UserHelper.JOB_REP limit 1];
      acct.OwnerId = inactiveRep.Id;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      update acct;
      acct = getTestAcct();
      
      Lead ld = new Lead(FirstName='John', LastName='Doe', Company='Test Company', PostalCode='14624');
      TriggerMethods.SKIP_TRIGGERS=true;
      insert ld;
      
      Test.startTest();
      Id ctctId = DuplicateCheckQueueable.convertLead(ld, acct, null, true);
      Test.stopTest();
      
      Lead checkLd = [Select Id, IsConverted from Lead where Id=:ld.Id];
      System.assertEquals(true,checkLd.IsConverted);
      acct = getTestAcct();
      System.assertEquals(inactiveRep.Id, acct.OwnerId);
   } // testInactiveLeadConvert

} // class DuplicateCheckTest