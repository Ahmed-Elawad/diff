/* 
   Methods for working with the ECommerce__c object

   
  History
  -------
  10/06/2020 Dan Carmen        Created
  05/19/2021 Dan Carmen        Updated for Sales Process changes
  06/29/2021 Dan Carmen        Change to set account owner/hold out on lead convert
  10/26/2021 Dan Carmen        Update test
  07/26/2022 Dan Carmen        Handle Account updates from CSO
  08/15/2022 Dan Carmen        Fix for setting Branch-Client Number
  08/18/2022 Dan Carmen        Add First Payroll Run Date
  10/26/2022 Dan Carmen        Add process start/end
  11/14/2022 Dan Carmen        Add updates/inserts from Enterprise
  01/25/2023 Dan Carmen        Check if the integer is null before updating (so don't update null)
  04/10/2023 Dan Carmen        Ability to change opp record type based on an incoming Action
  10/19/2023 Dan Carmen        Change to be able to block the company name update from enterprise
  11/06/2023 Dan Carmen        Stop updating the ecoms after the partner referral is updated.
  04/01/2024 Dan Carmen        Fix for purge flag.
  04/12/2024 Dan Carmen        Purge selecting too many records.

 */
@isTest
public class EcomMethodsTest {
    
   public static String ECOM_OPP='Ecommerce Oppty';

   @testSetup
   public static void setupData() { 
      TrackRecordEntryTest.setupData();

      // Minutes_till_Launch__c to null so it doesn't try to launch again
      Apex_Batch_Control__c  abc2 = new Apex_Batch_Control__c(Name=EcomBatch.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=1, Minutes_till_Launch__c=null);
      insert abc2;
       
      LeadLoaderConfig__c llc1 = new LeadLoaderConfig__c(Name='eCommerce', IsActive__c=true, StoreOrginalData__c=true, CheckForDuplicate__c=false, CheckWorkable__c=true, IsAmplifinity__c=false, IsEcom__c=true);
      LeadLoaderConfig__c[] llcs = new LeadLoaderConfig__c[]{llc1};
      insert llcs;

      Referral_Partner__c refPart1 = new Referral_Partner__c(Name='Payroll', Partner_Type__c=EcomMethods.ECOMMERCE, NSS_Source__c='Inbound-Ecommerce', SellingOpportunityType__c='Payroll'
                                                           ,Sales_Org__c=EcomMethods.ECOMMERCE, Selling_Opp_RecordTypeId__c=null);
      Referral_Partner__c refPart2 = new Referral_Partner__c(Name='Ancillary', Partner_Type__c=EcomMethods.ECOMMERCE, NSS_Source__c='Inbound-Ecommerce', SellingOpportunityType__c='Payroll'
                                                           ,ProductCodes__c='ANC001'
                                                           ,Sales_Org__c=EcomMethods.ECOMMERCE, Selling_Opp_RecordTypeId__c=null);
      Referral_Partner__c[] refParts = new Referral_Partner__c[]{refPart1,refPart2};
      insert refParts;
       
      SalesOrg__c ecomSO = new SalesOrg__c(Name='Ecommerce', Description__c='Ecommerce',HasOwnership__c=false, RecordTypeAlias__c='Ecommerce '
                                    ,OpptyRecordTypeName__c=ECOM_OPP
                                    ,OpptyRecordTypeName2__c=null
                                    ,EventRecordTypeName__c=RecordTypeHelper.CORE_EVENT
                                    ,TaskRecordTypeName__c=RecordTypeHelper.CORE_TASK
                                    ,ProductName__c=null,IsSales__c=true,ProcessAcctOwnership__c=false,ProcessRfrlOwnership__c=false
                                    ,TeamRole__c=null,CanSubmitReferrals__c=false,StrcHasArea__c=false
                                    ,LeadRecordTypeName__c='Ecommerce Lead'
                                    ,OppFirstStage__c=Label.OppStage_Qualified
                                    ,OppEUPStage__c=Label.OppStage_Qualified
                                    ,ZipBatchKey__c=null
                                    ,IEUP_Type__c = null
                                    ,Default_Run_Effective_Date__c='14'
                                    );
       
      setupRtSetting();
      insert ecomSO;
      // create test products
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'XPAY0001','XPAY0002','XPAY0003','XPAY0004', 'ANC001','ANC002','ANC003'}, EcomMethods.ECOMMERCE, null);
   } // setupData
    
   public static void setupRtSetting() {
      RecordType__c[] recordTypes = new RecordType__c[]{};
      recordTypes.add(new RecordType__c(Name=ECOM_OPP,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=ECOM_OPP, Sales_Org__c='Ecommerce', UsedInOwnership__c=false,FirstRunDateUpdate__c=true
                                        ,FirstRunReasonWon__c='Ecommerce', FirstRunReasonLost__c='eCommerce Opportunity Created'));
      insert recordTypes;
   }

   public static ECommerce__c getTestEcom() {
      ECommerce__c ecom = new Ecommerce__c(Action__c=EcomMethods.ACTION_OCC2, ContactFirstName__c='Taylor', ContactLastName__c='Swift', Company__c='Swiftly Speaking Inc', ContactPhone__c='(585) 555-1234', ContactEmail__c='taylor@swift.com'
                                           ,StreetAddress__c='123 Main St', City__c='Rochester', State__c='NY', PostalCode__c='14624', MktgId__c='SwiftTest13', FEIN__C='45-3152340'
                                           ,DBA__c='Taylor Swift', CAID__c='123CAID456', CEID__c='123CEID456', BranchNbr__c='13', ClientNbr__c='138913', NumberOfEmployees__c=13);
      return ecom;
   } // getTestEcom
    
   public static Referral_Partner__c getRefPart() {
      Referral_Partner__c refPart = [Select Id,Name, Partner_Type__c, NSS_Source__c, SellingOpportunityType__c
                                       From Referral_Partner__c
                                      Where Partner_Type__c=:EcomMethods.ECOMMERCE limit 1];
      return refPart;
   } // getRefPart

   static testMethod void testStageRanking() {
      System.assertEquals('MQL',EcomMethods.checkStage(null,'MQL'));
      System.assertEquals('TAL',EcomMethods.checkStage('TAL','MQL'));
      System.assertEquals('TAL',EcomMethods.checkStage('MQL','TAL'));
      System.assertEquals('TQO',EcomMethods.checkStage('MQL','TQO'));
      System.assertEquals('Client',EcomMethods.checkStage('Client','SAO'));
   } // testStageRanking
    
   static testMethod void testConvertLead() {
      Lead testLead = new Lead(Company='Test Lead',FirstName='Joan', LastName='Smith', PostalCode='14624', NumberOfEmployees=13);
      insert testLead;
       
      Ecommerce__c ecom = new Ecommerce__c();
       
      EcomMethods.EcomWrap wrap = new EcomMethods.EcomWrap(ecom,null,null,null);
       
      Test.startTest();
      EcomMethods.convertLead(wrap,testLead);
      Test.stopTest();
       
      Lead checkLead = [Select Id, Name, Company, FirstName, LastName, PostalCode, IsConverted, ConvertedAccountId, ConvertedContactId from Lead where Id=:testLead.Id];
      System.debug('testConvertLead checkLead='+checklead);
      System.assertEquals(true, checkLead.IsConverted);
       
      Account acct = [Select Id, Name, Owner_Zip_Code__c from Account where Id=:checkLead.ConvertedAccountId];
      System.assertEquals(testLead.Company, acct.Name);
      System.assertEquals(testLead.PostalCode, acct.Owner_Zip_Code__c);
       
      Contact ctct = [Select Id, AccountId, FirstName, LastName from Contact where Id=:checkLead.ConvertedContactId]; 
      System.assertEquals(testLead.FirstName, ctct.FirstName);
      System.assertEquals(testLead.LastName, ctct.LastName);
      
      System.assertEquals(ctct.Id, ecom.Contact__c);
      System.assertEquals(acct.Id, ecom.Account__c);
      
   } // testConvertLead
    
   static testMethod void testMQLWithTAL() {
      // run a lead through the whole process with an existing ecom record.
      ECommerce__c ecom = getTestEcom();
      ecom.AncillaryProducts__c='ANC001';
      ecom.CheckTime__c = Datetime.now().addMinutes(-1);
      // insert it without the triggers so we can see if it's picked up with a new lead coming in.
      TriggerMethods.SKIP_TRIGGERS=true;
      insert ecom;
      TriggerMethods.SKIP_TRIGGERS=false;
       
      Lead ld = new Lead(Company='Taylor Swift', FirstName='Taylor', LastName='Swift', PostalCode='14624', MktgId__c=ecom.MktgId__c, OwnedBy__c='eCommerce');
      insert ld;
      // make sure the values are set from the trigger
      //ECommerce__c checkEcom = [Select Id, CheckTime__c, CheckCount__c from ECommerce__c where Id=:ecom.Id];
      //System.assertEquals(true, checkEcom.CheckTime__c <= Datetime.now());
      //System.assertEquals(0, checkEcom.CheckCount__c);
      Test.startTest();
      EcomBatch.launchBatch();
      Test.stopTest();
       
       
      System.assertEquals(1,[select count() from PartnerReferral__c]);
       
      PartnerReferral__c[] partRefs = EcomMethods.getPartRefs(new Id[]{}, new String[]{ld.MktgId__c});
      System.assertEquals(1,partRefs.size());
      PartnerReferral__c partRef = partRefs[0];
      System.debug('partRef='+partRef);
      System.assertNotEquals(null,partRef.Lead__c);

      System.assertEquals(ecom.ContactFirstName__c, partRef.FirstName__c);
      System.assertEquals(ecom.ContactLastName__c, partRef.LastName__c);
      System.assertEquals(ecom.ContactPhone__c, partRef.Phone__c);
      System.assertEquals(ecom.ContactEmail__c, partRef.Email__c);
      System.assertEquals(ecom.Company__c, partRef.Company__c);
      System.assertEquals(ecom.StreetAddress__c, partRef.StreetAddress__c);
      System.assertEquals(ecom.City__c, partRef.City__c);
      System.assertEquals(ecom.State__c, partRef.State__c);
      System.assertEquals(ecom.PostalCode__c, partRef.ZipPostalCode__c);
      System.assertEquals(ecom.NumberOfEmployees__c, partRef.NumberOfEmployees__c);

      Lead checkLd = partRef.Lead__r;
      
      System.assertEquals(ecom.ContactFirstName__c, checkLd.FirstName);
      System.assertEquals(ecom.ContactLastName__c, checkLd.LastName);
      System.assertEquals(ecom.ContactPhone__c, checkLd.Phone);
      System.assertEquals(ecom.ContactEmail__c, checkLd.Email);
      System.assertEquals(ecom.Company__c, checkLd.Company);
      System.assertEquals('TAL', checkLd.Lead_Stage__c);
      System.assertEquals(ecom.StreetAddress__c, checkLd.Street);
      System.assertEquals(ecom.City__c, checkLd.City);
      System.assertEquals(ecom.State__c, checkLd.State);
      System.assertEquals(ecom.PostalCode__c, checkLd.PostalCode);
      System.assertEquals(ecom.FEIN__c,checkld.Federal_ID_Number__c);
      System.assertEquals(ecom.CAID__c,checkld.Paychex_CAID__c);
      System.assertEquals(ecom.CEID__c,checkld.Paychex_CEID__c);
      System.assertEquals(ecom.NumberOfEmployees__c,checkld.NumberOfEmployees);
       
      Referral__c[] refs = [Select Id, Account__c, Selling_Opportunity__c, Referral_Partner__c, Referral_Partner__r.Name
                               ,Referral_Partner__r.Partner_Type__c, ProductReferred__c
                           from Referral__c where SourceLead__c=:checkLd.Id];
      System.assertEquals(2,refs.size());
      Referral__c refPayroll = null;
      Referral__c refAnc = null;
      for (Referral__c ref : refs) {
         if (ref.Referral_Partner__r.Name == 'Payroll') {
            refPayroll = ref;
            System.assertEquals(EcomMethods.ECOMMERCE, ref.Referral_Partner__r.Partner_Type__c);
            System.assertEquals(null,ref.Selling_Opportunity__c);
         } else if (ref.Referral_Partner__r.Name == 'Ancillary') {
            refAnc = ref;
            System.assertEquals(EcomMethods.ECOMMERCE, ref.Referral_Partner__r.Partner_Type__c);
            System.assertEquals('ANC001',ref.ProductReferred__c);
            System.assertEquals(null,ref.Selling_Opportunity__c);
         }
      }
      System.assertNotEquals(null,refPayroll);
      System.assertNotEquals(null,refAnc);
   } // testMQLWithTAL
    
   static testMethod void testTQOLead() {
      // create test products
      //PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'XPAY0001','XPAY0002','XPAY0003','XPAY0004'}, EcomMethods.ECOMMERCE, null);
          
      ECommerce__c ecom = getTestEcom();
      // setup product and price info
      ecom.PayrollFrequency__c = 'monthly';
      ecom.ProductInfo__c = 'XPAY0001,XPAY0002,XPAY0003,XPAY0005,1313';

      // skip the trigger for the partner referral
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
      // create a lead, let the code create a partner referral
      Lead ld = new Lead(Company='Taylor Swift', FirstName='Taylor', LastName='Swift', PostalCode='14624', MktgId__c=ecom.MktgId__c, OwnedBy__c='eCommerce');
      insert ld;
      System.assertEquals(1,[select count() from PartnerReferral__c where Lead__c=:ld.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceLead__c=:ld.Id]);
      System.assertEquals(0,[select count() from Lead where Id=:ld.Id and IsConverted=true]);
       
      ecom.Action__c = EcomMethods.ACTION_OCC3;
      ecom.AncillaryProducts__c='ANC001';
      // insert the ecom record.
      System.debug('testTQOLead before the insert');
      insert ecom;

      // make sure there is only one here.
      System.assertEquals(1,[select count() from Referral__c]);

      // make sure the values are set from the trigger
      ECommerce__c checkEcom = [Select Id, CheckTime__c, CheckCount__c from ECommerce__c where Id=:ecom.Id];
      System.assertEquals(true, checkEcom.CheckTime__c <= Datetime.now());
      System.assertEquals(0, checkEcom.CheckCount__c);
      Test.startTest();
      EcomBatch.launchBatch();
      Test.stopTest();

       
      checkEcom = [Select Id, Account__c, OppStage__c, MktgStage__c, Opportunity__c, PartnerReferral__c from Ecommerce__c where Id=:ecom.ID];
      System.assertEquals('TQO',checkEcom.MktgStage__c);
      System.assertEquals(Label.OppStage_Qualified,checkEcom.OppStage__c);
       
      // should be 2 referrals/opportunities (one for the ancillary)
      System.assertEquals(2,[select count() from Referral__c]);
       
      // lead converted, opportunity created
      Lead checkLead = [Select Id, Name, Company, FirstName, LastName, PostalCode, IsConverted, ConvertedAccountId, ConvertedContactId from Lead where Id=:ld.Id];
      System.debug('testConvertLead checkLead='+checklead);
      System.assertEquals(true, checkLead.IsConverted);

      Contact ctct = [Select Id, FirstName, LastName, Phone, Email, AccountId from Contact where Id=:checkLead.ConvertedContactId];
      System.assertEquals(ecom.ContactFirstName__c, ctct.FirstName);
      System.assertEquals(ecom.ContactLastName__c, ctct.LastName);
      System.assertEquals(ecom.ContactPhone__c, ctct.Phone);
      System.assertEquals(ecom.ContactEmail__c, ctct.Email);
       
      User ecomUser = EcomMethods.getEcomUser();

      Account acct = [Select Id, Name, NumberOfEmployees, OwnerId, Paychex_CAID__c, Paychex_CEID__c, Federal_ID_Number__c 
                            ,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                        from Account where Id=:checklead.ConvertedAccountId];
      System.assertEquals(ecom.Company__c, acct.Name);
      System.assertEquals('45-3152340', acct.Federal_ID_Number__c);
      System.assertEquals(ecom.CEID__c, acct.Paychex_CEID__c);
      System.assertEquals(ecom.CAID__c, acct.Paychex_CAID__c);
      System.assertEquals(ecom.NumberOfEmployees__c, acct.NumberOfEmployees);
      System.assertEquals(ecomUser.Id, acct.OwnerId);
      System.assertEquals(true, acct.Hold_Out__c);
      System.assertEquals(null, acct.Hold_Out_Expiration__c);
      System.assertEquals(EcomMethods.ECOMMERCE, acct.Permanent_Hold_Out_Description__c);
       
      Opportunity[] opps = [Select Id, Name, CloseDate, StageName, Employees_Paid_Per_Payroll__c, Frequency__c, RecordType.Name, Amount
                               ,(Select Id, Product2.ProductCode, Quantity, ServiceDate, TotalPrice
                                   From OpportunityLineItems
                                  order by Product2.ProductCode)
                           from Opportunity where AccountId=:checkEcom.Account__c];
      System.assertEquals(2,opps.size());
       
      Opportunity payrollOpp = null;
      Opportunity ancOpp = null;
      for (Opportunity opp : opps) {
          if (opp.Id == checkEcom.Opportunity__c) {
             payrollOpp = opp;
          } else {
             ancOpp = opp;
          }
      }
      System.assertNotEquals(null,payrollOpp);
      System.assertNotEquals(null,ancOpp);
       
      System.assertEquals(checkEcom.OppStage__c, payrollOpp.Stagename);
      System.assertEquals('Ecommerce Oppty', payrollOpp.RecordType.Name);
      System.assertEquals(Date.today().addDays(14), payrollOpp.CloseDate);
      System.assertEquals(ecom.NumberOfEmployees__c, payrollOpp.Employees_Paid_Per_Payroll__c);
      // revenue is price * 12 = 1313 * 12 = 15,756
      System.assertEquals(15756,payrollOpp.Amount);
      
      System.assertEquals(3, payrollOpp.OpportunityLineItems.size());
      for (OpportunityLineItem oli : payrollOpp.OpportunityLineItems) {
         System.assertEquals(1,oli.Quantity);
         System.assertEquals(payrollOpp.CloseDate, oli.ServiceDate);
          
         if (oli.Product2.ProductCode == 'XPAY0001') {
            System.assertEquals(15756,oli.TotalPrice);
         } else if (oli.Product2.ProductCode == 'XPAY0002' || oli.Product2.ProductCode == 'XPAY0003') {
            System.assertEquals(0,oli.TotalPrice);
         } else {
            System.assertEquals(1,2,'We should not be getting here');
         }
      }
       
      Referral__c[] refs = [Select Id, Account__c, Selling_Opportunity__c, Referral_Partner__c, Referral_Partner__r.Name
                               ,Referral_Partner__r.Partner_Type__c, ProductReferred__c
                           from Referral__c where Account__c=:checkEcom.Account__c];
      Referral__c refPayroll = null;
      Referral__c refAnc = null;
      for (Referral__c ref : refs) {
         if (ref.Referral_Partner__r.Name == 'Payroll') {
            refPayroll = ref;
            System.assertEquals(EcomMethods.ECOMMERCE, ref.Referral_Partner__r.Partner_Type__c);
         } else if (ref.Referral_Partner__r.Name == 'Ancillary') {
            refAnc = ref;
            System.assertEquals(EcomMethods.ECOMMERCE, ref.Referral_Partner__r.Partner_Type__c);
            System.assertEquals('ANC001',ref.ProductReferred__c);
         }
      }
      System.assertNotEquals(null,refPayroll);
      //System.assertNotEquals(null,refAnc);
      //System.assertEquals('Payroll', ref.Referral_Partner__r.Name);
       
   } // testTQOLead
    
   static testMethod void testTQOContact() {
      // create test products
      //PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'XPAY0001','XPAY0002','XPAY0003','XPAY0004'}, EcomMethods.ECOMMERCE, null);
          
      ECommerce__c ecom = getTestEcom();
      // setup product and price info
      ecom.PayrollFrequency__c = 'monthly';
      ecom.ProductInfo__c = 'XPAY0001,XPAY0002,XPAY0003,XPAY0005,1313';
      ecom.Action__c = EcomMethods.ACTION_OCC3;  // to create an opp
       
      // skip the trigger for the partner referral
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
      // create a lead, let the code create a partner referral
      Account acct = new Account(Name=ecom.Company__c, ShippingPostalCode=ecom.PostalCode__c);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Referral_Partner__c refPart = getRefPart();
      // insert existing opps
      Opportunity opp1 = new Opportunity(Name='Test Opp1', AccountId=acct.Id, OpportunityType__c=refPart.SellingOpportunityType__c
                                         ,OppSource__c='SomewhereElse', CloseDate=Date.today().addDays(7), StageName='Pending');
      Opportunity opp2 = new Opportunity(Name='Test Opp2', AccountId=acct.Id, OpportunityType__c='aDifferentType'
                                         ,OppSource__c='SomewhereElse', CloseDate=Date.today().addDays(7), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2};
      // we don't need the triggers to fire
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opps;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
       
      // skip the trigger for the partner referral - don't need it to fire here.
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
      Contact ctct = new Contact(AccountId=acct.Id, FirstName=ecom.ContactFirstName__c, LastName=ecom.ContactLastName__c, MktgId__c=ecom.MktgId__c, OwnedBy__c='eCommerce');
      insert ctct;

      System.assertEquals(1,[select count() from PartnerReferral__c where Contact__c=:ctct.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceContact__c=:ctct.Id]);
       
      ecom.Action__c = EcomMethods.ACTION_OCC3;
      // insert the ecom record.
      System.debug('testTQOLead before the insert');
      insert ecom;

      // make sure the values are set from the trigger
      ECommerce__c checkEcom = [Select Id, CheckTime__c, CheckCount__c from ECommerce__c where Id=:ecom.Id];
      System.assertEquals(true, checkEcom.CheckTime__c <= Datetime.now());
      System.assertEquals(0, checkEcom.CheckCount__c);
      Test.startTest();
      EcomBatch.launchBatch();
      Test.stopTest();
       
      checkEcom = [Select Id, OppStage__c, MktgStage__c, Opportunity__c from Ecommerce__c where Id=:ecom.ID];
      System.assertEquals('TQO',checkEcom.MktgStage__c);
      System.assertEquals(Label.OppStage_Qualified,checkEcom.OppStage__c);
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, StageName, CloseDate, IsClosed, IsWon, Reason_Not_Sold__c
                                                              From Opportunity]);
      System.assertEquals(3,oppMap.size());
      Opportunity checkOpp1 = oppMap.remove(opp1.Id);
      System.assertEquals(true,checkOpp1.IsClosed);
      System.assertEquals(false,checkOpp1.IsWon);
      System.assertEquals(EcomMethods.DISQUALIFIED,checkOpp1.StageName);
      RecordType__c rtSetting = RecordType__c.getInstance(ECOM_OPP);
      System.assertEquals(rtSetting.FirstRunReasonLost__c,checkOpp1.Reason_Not_Sold__c);

      Opportunity checkOpp2 = oppMap.remove(opp2.Id);
      System.assertEquals(false,checkOpp2.IsClosed);
      System.assertEquals(false,checkOpp2.IsWon);
      System.assertEquals('Pending',checkOpp2.StageName);
      System.assertEquals(null,checkOpp2.Reason_Not_Sold__c);
      
      // should only be 1 record left
      Opportunity newOpp = oppMap.values()[0];
      System.assertEquals(checkEcom.Opportunity__c, newOpp.Id);
      System.assertEquals(checkEcom.OppStage__c, newOpp.StageName);
       
      // test if the payroll ran.
      ecom = getTestEcom();
      ecom.Action__c = 'First Payroll Run';
      ecom.FirstCheckDate__c = Date.today().addDays(7);
      ecom.FirstPayrollRunDate__c = Date.today().addDays(4);
      insert ecom;
      ecom = [Select Id, Action__c, OppStage__c, MktgStage__c, Opportunity__c 
                    ,FirstCheckDate__c, FirstPayrollRunDate__c
                from Ecommerce__c where Id=:ecom.ID];
       
      EcomMethods.processEcoms(new Id[]{ecom.Id});
      Opportunity checkNewOpp = [Select Id, Name, StageName, CloseDate, IsClosed, IsWon, Reason_Not_Sold__c, Check_Date__c
                                       ,Account.Id, Account.First_Run_Date__c
                                   From Opportunity
                                 Where Id = :newOpp.Id
                                ];
      //System.assertEquals(ecom.Opportunity__c, checkNewOpp.Id);
      System.assertEquals(ecom.OppStage__c, checkNewOpp.StageName);
      System.assertEquals(true, checkNewOpp.IsClosed);
      System.assertEquals(true, checkNewOpp.IsWon);
      System.assertEquals(ecom.FirstCheckDate__c, checkNewOpp.Check_Date__c);
      System.assertEquals(ecom.FirstPayrollRunDate__c, checkNewOpp.CloseDate);
      System.assertEquals(ecom.FirstPayrollRunDate__c, checkNewOpp.Account.First_Run_Date__c);

   } // testTQOContact
    
   static testMethod void testSQO() {
      ECommerce__c ecom = getTestEcom();
      ecom.AuthorizingFirstName__c = 'Debbie';
      ecom.AuthorizingLastName__c = 'Gibson';
      ecom.AuthorizingTitle__c = 'Singer';
      ecom.AuthorizingEmail__c = 'debbie.gibson@outoftheblue.com';
      ecom.AuthorizingPhone__c = '5551234567';
      
      Account acct = new Account(Name=ecom.Company__c, ShippingPostalCode=ecom.PostalCode__c);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      // skip the trigger for the partner referral - don't need it to fire here.
      PartnerReferralHelper.TRIGGER_ALREADY_RAN=true;
      Contact ctct = new Contact(AccountId=acct.Id, FirstName=ecom.ContactFirstName__c, LastName=ecom.ContactLastName__c, MktgId__c=ecom.MktgId__c, OwnedBy__c='eCommerce');
      insert ctct;
       
      // make sure the partner referral and referral are created
      System.assertEquals(1,[select count() from PartnerReferral__c where Contact__c=:ctct.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceContact__c=:ctct.Id]);

      ecom.Action__c = EcomMethods.ACTION_FLEX2;
      // insert the ecom record.
      System.debug('testSQO before the insert');
      insert ecom;
       
      // make sure the values are set from the trigger
      ECommerce__c checkEcom = [Select Id, CheckTime__c, CheckCount__c from ECommerce__c where Id=:ecom.Id];
      System.assertEquals(true, checkEcom.CheckTime__c <= Datetime.now());
      System.assertEquals(0, checkEcom.CheckCount__c);
      Test.startTest();
      EcomBatch.launchBatch();
      Test.stopTest();

      checkEcom = [Select Id, OppStage__c, OppRecordType__c, MktgStage__c from Ecommerce__c where Id=:ecom.ID];
      System.assertEquals('SQO',checkEcom.MktgStage__c);
      System.assertEquals('Sold - Submitted',checkEcom.OppStage__c);

      ctct = [Select Id, FirstName, LastName, Phone, Email, AccountId from Contact where Id=:ctct.Id];
      System.assertEquals(ecom.ContactFirstName__c, ctct.FirstName);
      System.assertEquals(ecom.ContactLastName__c, ctct.LastName);
      System.assertEquals(ecom.ContactPhone__c, ctct.Phone);
      System.assertEquals(ecom.ContactEmail__c, ctct.Email);
       
      acct = [Select Id, Name, NumberOfEmployees, Paychex_CAID__c, Paychex_CEID__c, Federal_ID_Number__c from Account where Id=:acct.Id];
      System.assertEquals(ecom.Company__c, acct.Name);
      System.assertEquals('45-3152340', acct.Federal_ID_Number__c);
      System.assertEquals(ecom.CEID__c, acct.Paychex_CEID__c);
      System.assertEquals(ecom.CAID__c, acct.Paychex_CAID__c);
      System.assertEquals(ecom.NumberOfEmployees__c, acct.NumberOfEmployees);
       
      Opportunity opp = [Select Id, Name, CloseDate, StageName, Employees_Paid_Per_Payroll__c, Frequency__c, RecordType.Name from Opportunity where AccountId=:acct.Id];
      System.assertEquals(checkEcom.OppStage__c, opp.Stagename);
      //String rtName = (String.isNotBlank(checkEcom.OppRecordType__c) ? checkEcom.OppRecordType__c : 'Ecommerce Oppty');
      String rtName = ECOM_OPP;
      System.assertEquals(rtName, opp.RecordType.Name);
      System.assertEquals(Date.today().addDays(14), opp.CloseDate);
      System.assertEquals(ecom.NumberOfEmployees__c, opp.Employees_Paid_Per_Payroll__c);
       
      // the authorized contact should have been created
      System.assertEquals(2,[select count() from Contact where AccountId=:acct.Id]);
       
      // test that the payroll ran
      
   } // testSQO
    
   static testMethod void testOCCForm1() {
          ECommerce__c ecom = new Ecommerce__c(Action__c=EcomMethods.ACTION_OCC1, ContactFirstName__c='Taylor', ContactLastName__c='Swift', Company__c='Swiftly Speaking Inc', ContactPhone__c='(585) 555-1234', ContactEmail__c='taylor@swift.com'
                                           ,StreetAddress__c='123 Main St', City__c='Rochester', State__c='NY', PostalCode__c='14624', OracleCommerceCloudId__c='SwiftTest134', FEIN__C='121234567'
                                           ,DBA__c='Taylor Swift', CAID__c='123CAID456', CEID__c='123CEID456', BranchNbr__c='13', ClientNbr__c='138913', NumberOfEmployees__c=13);
    
        Test.starttest();
       insert ecom;
       ECommerce__c ec = [Select id from ECommerce__c where Action__c= : EcomMethods.ACTION_OCC1 AND OracleCommerceCloudId__c='SwiftTest134' limit 1];
       EcomMethods.processEcoms(new ID[]{ec.Id});
       Lead[] ld = [select id from Lead where MktgId__c= 'SwiftTest134'];
       System.assertEquals(1, ld.size());
        Test.stopTest();
    } //testOCCForm1
    
   static testMethod void testMisc() {
       
      Apex_Batch_Control__c abc = EcomBatch.getBatchControl();
      System.assertNotEquals(null, abc);
      EcomBatch.getNextLaunchTime(abc);
       
   } // testMisc
    
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testEcomBatch', new EcomBatch());
   } // testScheduler
    
    
   static testMethod void testCSOTracker() {
      Account acct = new Account(Name='Test CSO Account', Paychex_CAID__c='TestCsoAccount1');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Soupy', LastName='Sales');
      insert ctct;
       
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(7),StageName='Pending');
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opp;
       
      CSO_Tracking__c tracker = new CSO_Tracking__c(AccountId__c=acct.Id, Opportunity__c=opp.Id, Contact__c=ctct.Id);
      insert tracker;
       
      Ecommerce__c ecom1 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='First Steps Completed', SubmittedDateTime__c=Datetime.now().addMinutes(-7));
      Ecommerce__c ecom2 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Prior Payroll Completed', SubmittedDateTime__c=Datetime.now().addMinutes(-5));
      Ecommerce__c ecom3 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Business Information Completed', SubmittedDateTime__c=Datetime.now().addMinutes(-3));
      Ecommerce__c ecom4 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Banking Information Completed');
      insert new Ecommerce__c[]{ecom1,ecom2,ecom3,ecom4};
          
      Map<Id,Ecommerce__c> ecomMap = new Map<Id,Ecommerce__c>([Select Id, Action__c, CAID__c
                                                                     ,CSOTrackingFirst__c, CSOTrackingLatest__c, PriorWages__c, SubmittedDateTime__c, CreatedDate
                                                                 From Ecommerce__c]);
      // verify the fields are set - in case the formulas change
      for (Ecommerce__c ecom : ecomMap.values()) {
         System.assertNotEquals(null,ecom.CSOTrackingFirst__c,'CSOTrackingFirst__c not found for '+ecom.Action__c);
         System.assertNotEquals(null,ecom.CSOTrackingLatest__c,'CSOTrackingLatest__c not found for '+ecom.Action__c);
      }
       
      Id[] ecomIds = new Id[]{};
      ecomIds.addAll(ecomMap.keySet());
      EcomMethods.processEcoms(ecomIds);
       
      String query = EcomMethods.getCSOTrackerQuery();
      String caid = acct.Paychex_CAID__c;
      query += ' Where AccountId__r.Paychex_CAID__c=:caid ';
      CSO_Tracking__c[] trackers = Database.query(query);
      System.assertEquals(1,trackers.size());
       
      ecom4 = ecomMap.get(ecom4.Id);
       
      tracker = trackers[0];
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsCompleted__c);
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsLatest__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollCompleted__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollLatest__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoCompleted__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoLatest__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoCompleted__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoLatest__c);
       
      Ecommerce__c ecom5 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Business Information Completed', SubmittedDateTime__c=Datetime.now().addMinutes(-1));
      insert ecom5;
       
      System.debug('testCSOTracker ecom5');
      EcomMethods.processEcoms(new Id[]{ecom5.Id});

      trackers = Database.query(query);
      System.assertEquals(1,trackers.size());
              
      tracker = trackers[0];
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsCompleted__c);
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsLatest__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollCompleted__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollLatest__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoCompleted__c);
      System.assertEquals(ecom5.SubmittedDateTime__c, tracker.BusinessInfoLatest__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoCompleted__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoLatest__c);
       
      // test that the opportunity date is updated
      Ecommerce__c ecom6 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Pay Schedule Completed', SubmittedDateTime__c=Datetime.now()
                                                    , FirstPayrollRunDate__c=Date.today().addDays(1), FirstCheckDate__c=Date.today().addDays(2));
      insert ecom6;
      Ecommerce__c ecom6b = [Select Id, Action__c, CAID__c, OppStage__c, CSOTrackingFirst__c, CSOTrackingLatest__c, PriorWages__c, Processed__c from Ecommerce__c where Id=:ecom6.Id];
      System.assertNotEquals(null,ecom6b.CSOTrackingFirst__c);
      System.assertNotEquals(null,ecom6b.CSOTrackingLatest__c);
       
      System.debug('testCSOTracker ecom6');
      EcomMethods.processEcoms(new Id[]{ecom6.Id});

      trackers = Database.query(query);
      System.assertEquals(1,trackers.size());

      tracker = trackers[0];
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsCompleted__c);
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsLatest__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollCompleted__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollLatest__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoCompleted__c);
      System.assertEquals(ecom5.SubmittedDateTime__c, tracker.BusinessInfoLatest__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoCompleted__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoLatest__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleCompleted__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleLatest__c);

      opp = [Select Id, Name, Check_Date__c, CloseDate, StageName, AccountId
                   ,Account.Id, Account.Name, Account.First_Run_Date__c
               From Opportunity Where Id=:opp.Id];
      System.assertEquals(ecom6.FirstPayrollRunDate__c, opp.CloseDate);
      System.assertEquals(ecom6.FirstCheckDate__c, opp.Check_Date__c);
      System.assertEquals('Pending', opp.StageName);
      System.assertEquals(null,opp.Account.First_Run_Date__c);
       
      Test.startTest();
      Ecommerce__c ecom7 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='Submit Completed', SubmittedDateTime__c=Datetime.now());
      insert ecom7;
      Ecommerce__c ecom7b = [Select Id, Action__c, OppStage__c, CSOTrackingFirst__c, CSOTrackingLatest__c, PriorWages__c, Processed__c from Ecommerce__c where Id=:ecom7.Id];
      System.assertNotEquals(null,ecom7b.OppStage__c);
      System.assertNotEquals(null,ecom7b.CSOTrackingFirst__c);
      System.assertNotEquals(null,ecom7b.CSOTrackingLatest__c);
      System.debug('testCSOTracker ecom7');
      EcomMethods.processEcoms(new Id[]{ecom7.Id});

      trackers = Database.query(query);
      System.assertEquals(1,trackers.size());

      tracker = trackers[0];
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsCompleted__c);
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsLatest__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollCompleted__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollLatest__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoCompleted__c);
      System.assertEquals(ecom5.SubmittedDateTime__c, tracker.BusinessInfoLatest__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoCompleted__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoLatest__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleCompleted__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleLatest__c);
      System.assertEquals(ecom7.SubmittedDateTime__c, tracker.SubmitCompleted__c);
      System.assertEquals(ecom7.SubmittedDateTime__c, tracker.SubmitLatest__c);
      System.assertEquals(ecom6.FirstPayrollRunDate__c, tracker.FirstPayrollRunDate__c);
      System.assertEquals(ecom6.FirstCheckDate__c, tracker.FirstCheckDate__c);

      opp = [Select Id, Name, Check_Date__c, CloseDate, StageName, AccountId
                   ,Account.Id, Account.Name, Account.First_Run_Date__c
               From Opportunity Where Id=:opp.Id];
      System.assertEquals(ecom6.FirstPayrollRunDate__c, opp.CloseDate);
      System.assertEquals(ecom6.FirstCheckDate__c, opp.Check_Date__c);
      System.assertEquals(ecom7b.OppStage__c, opp.StageName);
      System.assertEquals(null,opp.Account.First_Run_Date__c);

      Ecommerce__c ecom8 = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c='First Payroll Run', SubmittedDateTime__c=Datetime.now()
                                              ,FirstPayrollRunDate__c=Date.today().addDays(2), FirstCheckDate__c=Date.today().addDays(3));
      insert ecom8;
      Ecommerce__c ecom8b = [Select Id, Action__c, OppStage__c, CSOTrackingFirst__c, CSOTrackingLatest__c, PriorWages__c, Processed__c from Ecommerce__c where Id=:ecom8.Id];
      System.assertNotEquals(null,ecom8b.OppStage__c);
      System.assertNotEquals(null,ecom8b.CSOTrackingFirst__c);
      System.assertNotEquals(null,ecom8b.CSOTrackingLatest__c);
      System.debug('testCSOTracker ecom8');
      EcomMethods.processEcoms(new Id[]{ecom8.Id});

      trackers = Database.query(query);
      System.assertEquals(1,trackers.size());

      tracker = trackers[0];
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsCompleted__c);
      System.assertEquals(ecom1.SubmittedDateTime__c, tracker.FirstStepsLatest__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollCompleted__c);
      System.assertEquals(ecom2.SubmittedDateTime__c, tracker.PriorPayrollLatest__c);
      System.assertEquals(ecom3.SubmittedDateTime__c, tracker.BusinessInfoCompleted__c);
      System.assertEquals(ecom5.SubmittedDateTime__c, tracker.BusinessInfoLatest__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoCompleted__c);
      System.assertEquals(ecom4.CreatedDate, tracker.BankingInfoLatest__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleCompleted__c);
      System.assertEquals(ecom6.SubmittedDateTime__c, tracker.PayScheduleLatest__c);
      System.assertEquals(ecom7.SubmittedDateTime__c, tracker.SubmitCompleted__c);
      System.assertEquals(ecom7.SubmittedDateTime__c, tracker.SubmitLatest__c);
      System.assertEquals(ecom8.SubmittedDateTime__c, tracker.FirstPayrollRun__c);
      System.assertEquals(ecom8.SubmittedDateTime__c, tracker.FirstPayrollRunLatest__c);
      System.assertEquals(ecom8.FirstPayrollRunDate__c, tracker.FirstPayrollRunDate__c);
      System.assertEquals(ecom8.FirstCheckDate__c, tracker.FirstCheckDate__c);

      opp = [Select Id, Name, Check_Date__c, CloseDate, StageName, AccountId, IsClosed, IsWon
                   ,Account.Id, Account.Name, Account.First_Run_Date__c
               From Opportunity Where Id=:opp.Id];
      System.assertEquals(ecom8.FirstPayrollRunDate__c, opp.CloseDate);
      System.assertEquals(ecom8.FirstCheckDate__c, opp.Check_Date__c);
      System.assertEquals(ecom8b.OppStage__c, opp.StageName);
      System.assertEquals(true, opp.IsClosed);
      System.assertEquals(true, opp.IsWon);
      System.assertEquals(ecom8.FirstPayrollRunDate__c,opp.Account.First_Run_Date__c);

      Test.stopTest();
   } // testCSOTracker
    
   static testMethod void testUpdateFromEnterprise() {
      Account acct = new Account(Name='Test CSO Account', Paychex_CAID__c='TestCsoAccount1');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;

      Ecommerce__c ecom = new Ecommerce__c(CAID__c=acct.Paychex_CAID__c, Action__c=EcomMethods.ACTION_CLT_UPDATE, SubmittedDateTime__c=Datetime.now());
      ecom.CEID__c = 'TestAccount1Ceid';
      ecom.LegalAddress__Street__s = '123 Billing St';
      ecom.LegalAddress__City__s = 'Somecity';
      ecom.LegalAddress__StateCode__s = 'NY';
      ecom.LegalAddress__PostalCode__s = '14624';
      ecom.LegalAddress__CountryCode__s = 'US';
      ecom.EnterpriseAAID__c = 'TestEnterpriseAAID';
      //ecom.EBSAccountID__c = 'EBSAccountId1';
      //ecom.EBSBillToSiteID__c = 'EBSBillToSiteID';
      //ecom.EBSPartyId__c = 'EBSParty1';
      //ecom.EBSShipToSiteID__c = 'EBSShipToSiteId';
      insert ecom;
       
      Ecommerce__c testEcom = [Select Id, Action__c, EnterpriseUpdate__c from Ecommerce__c where Id=:ecom.Id];
      Assert.isTrue(testEcom.EnterpriseUpdate__c);
       
      Test.startTest();
      EcomMethods.processEcoms(new Id[]{ecom.Id});
      Test.stopTest();

      Account checkAcct = [Select Id, Name, Paychex_CAID__c, Paychex_CEID__c
                                 ,LegalAddress__Street__s,LegalAddress__City__s,LegalAddress__StateCode__s,LegalAddress__PostalCode__s,LegalAddress__CountryCode__s
                                 ,EnterpriseAAID__c, EBSAccountID__c, EBSBillToSiteID__c, EBSPartyId__c, EBSShipToSiteID__c
                             From Account
                            Where Id=:acct.Id];
       
      Assert.areEqual(ecom.CEID__c, checkAcct.Paychex_CEID__c);
      Assert.areEqual(ecom.LegalAddress__Street__s, checkAcct.LegalAddress__Street__s);
      Assert.areEqual(ecom.LegalAddress__City__s, checkAcct.LegalAddress__City__s);
      Assert.areEqual(ecom.LegalAddress__StateCode__s, checkAcct.LegalAddress__StateCode__s);
      Assert.areEqual(ecom.LegalAddress__PostalCode__s, checkAcct.LegalAddress__PostalCode__s);
      Assert.areEqual(ecom.LegalAddress__CountryCode__s, checkAcct.LegalAddress__CountryCode__s);
      Assert.areEqual(ecom.EnterpriseAAID__c, checkAcct.EnterpriseAAID__c);
      //System.assertEquals(ecom.EBSAccountID__c, checkAcct.EBSAccountID__c);
      //System.assertEquals(ecom.EBSBillToSiteID__c, checkAcct.EBSBillToSiteID__c);
      //System.assertEquals(ecom.EBSPartyId__c, checkAcct.EBSPartyId__c);
      //System.assertEquals(ecom.EBSShipToSiteID__c, checkAcct.EBSShipToSiteID__c);
       
   } // testUpdateFromEnterprise
    
   static testMethod void testInsertFromEnterprise() {
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='EcomBatchClientLegal', NbrOfAttempts__c=0, Minutes_till_Launch__c=0, SaveAttachments__c=true);
      insert abc;
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo acctRt = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT);
      // create a parent account
      Account parentAcct = new Account(Name='Test Parent Account', Paychex_CAID__c='TestCsoAccount1', Paychex_CEID__c='TestParentCEID1', RecordTypeId=acctRt.getRecordTypeId());
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert parentAcct;

      // create an ecom to add a new account/child
      Ecommerce__c ecom = new Ecommerce__c(Company__c='Test Child Acct', CAID__c='TestCsoAccount2', Action__c=EcomMethods.ACTION_CLT_UPDATE, SubmittedDateTime__c=Datetime.now());
      ecom.CEID__c = 'TestParentCEID1';
      ecom.LegalAddress__Street__s = '123 Billing St';
      ecom.LegalAddress__City__s = 'Somecity';
      ecom.LegalAddress__StateCode__s = 'NY';
      ecom.LegalAddress__PostalCode__s = '14624';
      ecom.LegalAddress__CountryCode__s = 'US';
      ecom.EnterpriseAAID__c = 'TestEnterpriseAAID';
      ecom.EBSAccountID__c = 'EBSAccountId1';
      ecom.EBSBillToSiteID__c = 'EBSBillToSiteID';
      ecom.EBSPartyId__c = 'EBSParty1';
      ecom.EBSShipToSiteID__c = 'EBSShipToSiteId';
      insert ecom;

      Test.startTest();
      EcomMethods.processEcoms(new Id[]{ecom.Id});
      Test.stopTest();

      Account checkAcct = [Select Id, Name, Paychex_CAID__c, Paychex_CEID__c
                                 ,LegalAddress__Street__s,LegalAddress__City__s,LegalAddress__StateCode__s,LegalAddress__PostalCode__s,LegalAddress__CountryCode__s
                                 ,EnterpriseAAID__c, EBSAccountID__c, EBSBillToSiteID__c, EBSPartyId__c, EBSShipToSiteID__c
                                 ,SalesParent__c
                             From Account
                            Where Paychex_CAID__c=:ecom.CAID__c];
       
      System.assertEquals(ecom.CEID__c, checkAcct.Paychex_CEID__c);
      System.assertEquals(ecom.LegalAddress__Street__s, checkAcct.LegalAddress__Street__s);
      System.assertEquals(ecom.LegalAddress__City__s, checkAcct.LegalAddress__City__s);
      System.assertEquals(ecom.LegalAddress__StateCode__s, checkAcct.LegalAddress__StateCode__s);
      System.assertEquals(ecom.LegalAddress__PostalCode__s, checkAcct.LegalAddress__PostalCode__s);
      System.assertEquals(ecom.LegalAddress__CountryCode__s, checkAcct.LegalAddress__CountryCode__s);
      System.assertEquals(ecom.EnterpriseAAID__c, checkAcct.EnterpriseAAID__c);
      //System.assertEquals(ecom.EBSAccountID__c, checkAcct.EBSAccountID__c);
      //System.assertEquals(ecom.EBSBillToSiteID__c, checkAcct.EBSBillToSiteID__c);
      //System.assertEquals(ecom.EBSPartyId__c, checkAcct.EBSPartyId__c);
      //System.assertEquals(ecom.EBSShipToSiteID__c, checkAcct.EBSShipToSiteID__c);
      System.assertEquals(parentAcct.Id, checkAcct.SalesParent__c);
       
      Ecommerce__c checkEcom = [Select Id, Account__c, Processed__c
                                  From Ecommerce__c
                                 Where Id = :ecom.Id];
      System.assertEquals(true, checkEcom.Processed__c);
      System.assertEquals(checkAcct.Id, checkEcom.Account__c);
       
       
   } // testInsertFromEnterprise

   static testMethod void testDoNotInsertFromEnterprise() {
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='EcomBatchClientLegal', NbrOfAttempts__c=0, Minutes_till_Launch__c=0, SaveAttachments__c=false);
      insert abc;
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo acctRt = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT);
      // create a parent account
      Account parentAcct = new Account(Name='Test Parent Account', Paychex_CAID__c='TestCsoAccount1', Paychex_CEID__c='TestParentCEID1', RecordTypeId=acctRt.getRecordTypeId());
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert parentAcct;

      // create an ecom to add a new account/child
      Ecommerce__c ecom = new Ecommerce__c(Company__c='Test Child Acct', CAID__c='TestCsoAccount2', Action__c=EcomMethods.ACTION_CLT_UPDATE, SubmittedDateTime__c=Datetime.now());
      ecom.CEID__c = 'TestParentCEID1';
      ecom.LegalAddress__Street__s = '123 Billing St';
      ecom.LegalAddress__City__s = 'Somecity';
      ecom.LegalAddress__StateCode__s = 'NY';
      ecom.LegalAddress__PostalCode__s = '14624';
      ecom.LegalAddress__CountryCode__s = 'US';
      ecom.EnterpriseAAID__c = 'TestEnterpriseAAID';
      ecom.EBSAccountID__c = 'EBSAccountId1';
      ecom.EBSBillToSiteID__c = 'EBSBillToSiteID';
      ecom.EBSPartyId__c = 'EBSParty1';
      ecom.EBSShipToSiteID__c = 'EBSShipToSiteId';
      insert ecom;

      Test.startTest();
      EcomMethods.processEcoms(new Id[]{ecom.Id});
      Test.stopTest();

      Integer nbrResults = [Select count() from Account Where Paychex_CAID__c=:ecom.CAID__c];
      Assert.areEqual(0,nbrResults);
       
      Ecommerce__c checkEcom = [Select Id, Account__c, Processed__c
                                  From Ecommerce__c
                                 Where Id = :ecom.Id];
      Assert.isTrue(checkEcom.Processed__c);
      Assert.isNull(checkEcom.Account__c);
       
   } // testInsertFromEnterprise

   static testMethod void testMatchFromEnterprise() {
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='EcomBatchClientLegal', NbrOfAttempts__c=0, Minutes_till_Launch__c=0);
      insert abc;
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo acctRt = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT);
      // create a parent account
      Account matchAcct = new Account(Name='TestMatchAccount', RecordTypeId=acctRt.getRecordTypeId(), Federal_ID_Number__c='12-1234567');
      matchAcct.ShippingStreet = '123 Billing St';
      matchAcct.ShippingPostalCode = '14624';
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert matchAcct;

      // create an ecom to add a new account/child
      Ecommerce__c ecom = new Ecommerce__c(Company__c='TestMatchAccount', CAID__c='TestCsoAccount2', Action__c=EcomMethods.ACTION_CLT_UPDATE, SubmittedDateTime__c=Datetime.now());
      ecom.CEID__c = 'TestParentCEID1';
      ecom.FEIN__c = matchAcct.Federal_ID_Number__c;
      ecom.LegalAddress__Street__s = matchAcct.ShippingStreet;
      ecom.LegalAddress__City__s = 'Somecity';
      ecom.LegalAddress__StateCode__s = 'NY';
      ecom.LegalAddress__PostalCode__s = matchAcct.ShippingPostalCode;
      ecom.LegalAddress__CountryCode__s = 'US';
      ecom.EnterpriseAAID__c = 'TestEnterpriseAAID';
      ecom.EBSAccountID__c = 'EBSAccountId1';
      ecom.EBSBillToSiteID__c = 'EBSBillToSiteID';
      ecom.EBSPartyId__c = 'EBSParty1';
      ecom.EBSShipToSiteID__c = 'EBSShipToSiteId';
      insert ecom;

      User ecomUser = EcomMethods.getEcomUser();
      System.runAs(ecomUser) {
         Test.startTest();
         EcomMethods.processEcoms(new Id[]{ecom.Id});
         Test.stopTest();
      }

      Account checkAcct = [Select Id, Name, Paychex_CAID__c, Paychex_CEID__c
                                 ,LegalAddress__Street__s,LegalAddress__City__s,LegalAddress__StateCode__s,LegalAddress__PostalCode__s,LegalAddress__CountryCode__s
                                 ,EnterpriseAAID__c, EBSAccountID__c, EBSBillToSiteID__c, EBSPartyId__c, EBSShipToSiteID__c
                                 ,SalesParent__c
                             From Account
                            Where Paychex_CAID__c=:ecom.CAID__c];
       
      System.assertEquals(ecom.CEID__c, checkAcct.Paychex_CEID__c);
      System.assertEquals(ecom.LegalAddress__Street__s, checkAcct.LegalAddress__Street__s);
      System.assertEquals(ecom.LegalAddress__City__s, checkAcct.LegalAddress__City__s);
      System.assertEquals(ecom.LegalAddress__StateCode__s, checkAcct.LegalAddress__StateCode__s);
      System.assertEquals(ecom.LegalAddress__PostalCode__s, checkAcct.LegalAddress__PostalCode__s);
      System.assertEquals(ecom.LegalAddress__CountryCode__s, checkAcct.LegalAddress__CountryCode__s);
      System.assertEquals(ecom.EnterpriseAAID__c, checkAcct.EnterpriseAAID__c);
       
      Ecommerce__c checkEcom = [Select Id, Account__c, Processed__c
                                  From Ecommerce__c
                                 Where Id = :ecom.Id];
      System.assertEquals(true, checkEcom.Processed__c);
      System.assertEquals(checkAcct.Id, checkEcom.Account__c);
       
       
   } // testMatchFromEnterprise

   static testMethod void testReasonLost() {
         
      Account acct = new Account(Name='Test Acct', ShippingPostalCode='14604', Employees__c=10, NumberOfEmployees=10);
      insert acct;

      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast', Email='test@test.com');
      insert ctct;
       
      Id ecomRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Ecommerce Oppty').getRecordTypeId();

      Opportunity opp = new Opportunity(Name='Test Opp1', AccountId=acct.Id,RecordTypeId=ecomRecTypeId
                                          ,OppSource__c='SomewhereElse', CloseDate=Date.today() 
                                          ,StageName='Lost', Reason_Not_Sold__c = 'Unresponsive', Reason_Not_Sold_Details__c = 'Unresponsive after IEUP');
      insert opp;
      
      Referral__c ref = new Referral__c(Name='test',Selling_Opportunity__c=opp.Id);
      insert ref;

      PartnerReferral__c partRef = new PartnerReferral__c(Contact__c=ctct.Id, Account__c=acct.Id
                                                          ,Opportunity__c=opp.Id, MktgId__c='123456',Referral__c=ref.Id, Source__c='eCommerce');
      insert partRef;
     
       
      Ecommerce__c ecom = new Ecommerce__c(Action__c=EcomMethods.ACTION_OCC4, SubmittedDateTime__c=Datetime.now()
                                           ,PartnerReferral__c=partRef.Id, MktgId__c='123456'
                                           ,Contact__c = ctct.Id, Account__c=acct.Id, Opportunity__c=opp.Id, Source__c='eCommerce');
      insert ecom;

      Ecommerce__c[] ecoms = EcomMethods.getEcoms(new Id[]{ecom.Id}, null);
      Ecommerce__c checkEcom = ecoms[0];

      PartnerReferral__c[] partRefs = EcomMethods.getPartRefs(new Id[]{partRef.Id}, new String[]{});
      PartnerReferral__c checkPartRef = partRefs[0];

      EcomMethods.EcomWrap wrap = new EcomMethods.EcomWrap(checkEcom,checkPartRef,null,acct);
      wrap.opp = checkPartRef.Referral__r.Selling_Opportunity__r;
     
      Test.startTest();
      EcomMethods.handleOpps(wrap);
      EcomMethods.checkSaveRecs(new EcomMethods.EcomWrap[]{wrap});
      Test.stopTest();

      Opportunity checkOpp = [Select Id, Reason_Not_Sold__c, Reason_Not_Sold_Details__c from Opportunity Where Id=:opp.Id];
      Assert.isNull(checkOpp.Reason_Not_Sold__c);
      Assert.isNull(checkOpp.Reason_Not_Sold_Details__c);
   } // testReasonLost
    
   static testMethod void testMarkPurged() {
      EcomMethods.keepOnlyLatestActions=new String[]{'Action1'};
      EcomMethods.keepFirstLastActions=new String[]{'Action2'};
      EcomMethods.purgeLimit=10;
      String occId = 'ThisIsAnOccId';
      String caid = 'ThisisACAID';

      Ecommerce__c ecom1 = new Ecommerce__c(Action__c='Action1', Company__c='Company1',OracleCommerceCloudId__c=occId);
      Ecommerce__c ecom2 = new Ecommerce__c(Action__c='Action2', Company__c='Company2',CAID__c=caid);
      insert new Ecommerce__c[]{ecom1,ecom2};
      Map<Id,Ecommerce__c> ecomMap = getEcomMap();
      System.debug('testMarkPurged 1 ecomMap='+ecomMap);
      ecom1 = ecomMap.get(ecom1.Id);
      Assert.isFalse(ecom1.Processed__c);
      ecom2 = ecomMap.get(ecom2.Id);
      Assert.isFalse(ecom2.Processed__c);
      ecom1.Processed__c = true;
      ecom2.Processed__c = true;
      // just to make sure the trigger fires
      TriggerMethods.SKIP_TRIGGERS=false;
      update new Ecommerce__c[]{ecom1,ecom2};
          
      ecomMap = getEcomMap();
      System.debug('testMarkPurged 2 ecomMap='+ecomMap);
      ecom1 = ecomMap.get(ecom1.Id);
      Assert.isTrue(ecom1.Processed__c);
      Assert.isFalse(ecom1.PurgeRecord__c);
      ecom2 = ecomMap.get(ecom2.Id);
      Assert.isTrue(ecom2.Processed__c);
      Assert.isFalse(ecom2.PurgeRecord__c);
      
      Ecommerce__c ecom1a = new Ecommerce__c(Action__c='Action1', Company__c='Company1',OracleCommerceCloudId__c=occId);
      Ecommerce__c ecom2a = new Ecommerce__c(Action__c='Action2', Company__c='Company2',CAID__c=caid);
      insert new Ecommerce__c[]{ecom1a,ecom2a};
      ecomMap = getEcomMap();
      System.debug('testMarkPurged 3 ecomMap='+ecomMap);
      ecom1a = ecomMap.get(ecom1a.Id);
      Assert.isFalse(ecom1a.Processed__c);
      ecom2a = ecomMap.get(ecom2a.Id);
      Assert.isFalse(ecom2a.Processed__c);
      ecom1a.Processed__c = true;
      ecom2a.Processed__c = true;
      // just to make sure the trigger fires
      TriggerMethods.SKIP_TRIGGERS=false;
      update new Ecommerce__c[]{ecom1a,ecom2a};
          
      ecomMap = getEcomMap();
      System.debug('testMarkPurged 4 ecomMap='+ecomMap);
      ecom1 = ecomMap.get(ecom1.Id);
      Assert.isTrue(ecom1.Processed__c);
      Assert.isTrue(ecom1.PurgeRecord__c);
      Assert.isNotNull(ecom1.PurgeDate__c);
      ecom2 = ecomMap.get(ecom2.Id);
      Assert.isTrue(ecom2.Processed__c);
      Assert.isFalse(ecom2.PurgeRecord__c);
      ecom1a = ecomMap.get(ecom1a.Id);
      Assert.isTrue(ecom1a.Processed__c);
      Assert.isFalse(ecom1a.PurgeRecord__c);
      ecom2a = ecomMap.get(ecom2a.Id);
      Assert.isTrue(ecom2a.Processed__c);
      Assert.isFalse(ecom2a.PurgeRecord__c);

      Ecommerce__c ecom1b = new Ecommerce__c(Action__c='Action1', Company__c='Company1',OracleCommerceCloudId__c=occId);
      Ecommerce__c ecom2b = new Ecommerce__c(Action__c='Action2', Company__c='Company2',CAID__c=caid);
      insert new Ecommerce__c[]{ecom1b,ecom2b};
       
      ecomMap = getEcomMap();
      System.debug('testMarkPurged 5 ecomMap='+ecomMap);
      ecom1 = ecomMap.get(ecom1.Id);
      Assert.isTrue(ecom1.Processed__c);
      Assert.isTrue(ecom1.PurgeRecord__c);
      Assert.isNotNull(ecom1.PurgeDate__c);
      ecom2 = ecomMap.get(ecom2.Id);
      Assert.isTrue(ecom2.Processed__c);
      Assert.isFalse(ecom2.PurgeRecord__c);
      ecom1a = ecomMap.get(ecom1a.Id);
      Assert.isTrue(ecom1a.Processed__c);
      Assert.isFalse(ecom1a.PurgeRecord__c);
      ecom2a = ecomMap.get(ecom2a.Id);
      Assert.isTrue(ecom2a.Processed__c);
      Assert.isFalse(ecom2a.PurgeRecord__c);
      ecom1b = ecomMap.get(ecom1b.Id);
      Assert.isFalse(ecom1b.Processed__c);
      Assert.isFalse(ecom1b.PurgeRecord__c);
      ecom2b = ecomMap.get(ecom2b.Id);
      Assert.isFalse(ecom2b.Processed__c);
      Assert.isFalse(ecom2b.PurgeRecord__c);

      ecom1b.Processed__c = true;
      ecom2b.Processed__c = true;
      // just to make sure the trigger fires
      TriggerMethods.SKIP_TRIGGERS=false;
      update new Ecommerce__c[]{ecom1b,ecom2b};
          
      // for the Action1 records, only the latest will not be marked to purge
      // for the Action2 records, the first and latest will not be marked to purge.
      ecomMap = getEcomMap();
      System.debug('testMarkPurged 6 ecomMap='+ecomMap);
      ecom1 = ecomMap.get(ecom1.Id);
      Assert.isTrue(ecom1.Processed__c);
      Assert.isTrue(ecom1.PurgeRecord__c);
      Assert.isNotNull(ecom1.PurgeDate__c);
      ecom2 = ecomMap.get(ecom2.Id);
      Assert.isTrue(ecom2.Processed__c);
      Assert.isFalse(ecom2.PurgeRecord__c);
      ecom1a = ecomMap.get(ecom1a.Id);
      Assert.isTrue(ecom1a.Processed__c);
      Assert.isTrue(ecom1a.PurgeRecord__c);
      Assert.isNotNull(ecom1a.PurgeDate__c);
      ecom2a = ecomMap.get(ecom2a.Id);
      Assert.isTrue(ecom2a.Processed__c);
      Assert.isTrue(ecom2a.PurgeRecord__c);
      Assert.isNotNull(ecom2a.PurgeDate__c);
      ecom1b = ecomMap.get(ecom1b.Id);
      Assert.isTrue(ecom1b.Processed__c);
      Assert.isFalse(ecom1b.PurgeRecord__c);
      Assert.isNull(ecom1b.PurgeDate__c);
      ecom2b = ecomMap.get(ecom2b.Id);
      Assert.isTrue(ecom2b.Processed__c);
      Assert.isFalse(ecom2b.PurgeRecord__c);
      Assert.isNull(ecom2b.PurgeDate__c);


   } // testMarkPurged
    
    public static Map<Id,Ecommerce__c> getEcomMap() {
       Map<Id,Ecommerce__c> ecomMap = new Map<Id,Ecommerce__c>([Select Id, Processed__c, Action__c, Company__c, PurgeRecord__c, PurgeDate__c
                                                                      ,OracleCommerceCloudId__c, CAID__c
                                                                  From Ecommerce__c]);
       return ecomMap;
    } // getEcomMap
    
} // class EcomMethodsTest