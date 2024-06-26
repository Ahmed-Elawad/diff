/* Test methods for the OpptyRevenueSplit class
   
  History
  -------
  09/12/2017 Dan Carmen       Created
  08/31/2022 Carrie Marciano  added SalesOrg custom setting to test data setup
  08/22/2023 Reetesh Pandey	  added excludeProdCode in metadata
  11/10/2023 Reetesh Pandey	  APR0148894 - Exclude Product from revenue split process-[Exclude Revenue Split]
 */
@isTest
private class OpptyRevenueSplitTest {

   @testSetup 
   static void setupData() {
       TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
           TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'OpptyRevenueSplit'}, classes);
       insert classes;
       
       RecordType__c[] recordTypes = new RecordType__c[]{};
       recordTypes.add(new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_CORE,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE, Sales_Org__c=UserHelper.SO_CORE, UsedInOwnership__c=false));
       recordTypes.add(new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_PEO,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_PEO, Sales_Org__c=UserHelper.SO_PEO_ASO, UsedInOwnership__c=false));
       insert recordTypes;       
       SalesOrg__c coreSetting = new SalesOrg__c(Name='PAY',Description__c='Core',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OwnerId');
       SalesOrg__c mmsSetting = new SalesOrg__c(Name='MMS',Description__c='MMS',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OwnerId');
       SalesOrg__c hrsSetting = new SalesOrg__c(Name='HRS',Description__c='401k/FSA',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='HRS_Account_Owner__c,Large Market 401(k) Partner');
       SalesOrg__c hnbfSetting = new SalesOrg__c(Name='HNBF',Description__c='Health & Benefits',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='HNBF_Account_Owner__c');
       SalesOrg__c pasSetting = new SalesOrg__c(Name='PAS',Description__c='HR Solutions',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='Premier_PBS_Account_Owner__c');
       SalesOrg__c peoSetting = new SalesOrg__c(Name='PEO',Description__c='PEO',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='OasisPEOAccountOwner__c');
       SalesOrg__c baSetting = new SalesOrg__c(Name='BenAdmin',Description__c='BenAdmin',HasOwnership__c=true,IsSales__c=true,ProcessAcctOwnership__c=true,StrcHasArea__c=true,Crossover_Fields__c='BenAdmin Sales Rep',Use_for_Rev_Split__c=true);
       
       List<SalesOrg__c> sos = new List<SalesOrg__c>();
       sos.add(coreSetting);
       sos.add(mmsSetting);
       sos.add(hrsSetting);
       sos.add(hnbfSetting);
       sos.add(pasSetting);
       sos.add(peoSetting);
       sos.add(baSetting);
       insert sos;
       
   } // setupData 

   public static OpptyRevSplit__mdt[] testData = null;

   public static OpptyRevSplit__mdt[] getTestData(String testName) {
      testData = [select Id
                        ,AccountAttributes__c
                        ,PctReferring__c
                        ,ProductCodes__c
                        ,ReferringSalesOrg__c
                        ,SellingNSSTeam__c
                        ,SellingRecordType__c
                        ,SellingSalesOrg__c
                        ,SellingZipTier__c
                        ,TestScenario__c
                        ,Type__c
                        ,ExcludeProdCode__c
                    from OpptyRevSplit__mdt
                   where TestScenario__c = :testName];
      System.debug('getTestData testData='+testData.size());

      // verify we get data back
      System.assertEquals(true, testData.size() > 0, 'Test Data for '+testName+' Not found!');
      return testData;
   } // getTestData
   

   public static Map<String,PricebookEntry> entryMapCore = new Map<String,PricebookEntry>();
   public static Map<String,PricebookEntry> entryMapPas = new Map<String,PricebookEntry>();
   
   public static Referral_Partner__c refPartCoreIntegrated = null;
   public static Referral_Partner__c refPartPasIntegrated = null;
   public static Referral_Partner__c refPartCoreInternal = null;
   
   public static String[] splitProdCodesCore = new String[]{};
   public static String[] splitProdCodesPas = new String[]{};

   static void setupTestData(String testName) {
      
      getTestData(testName);

      String[] coreProds = new String[]{'CoreProd1','CoreProd2','CoreProd3',OpptyRevenueSplit.PROD_INTEGRATED_SELLING, OpptyRevenueSplit.PROD_INTERNAL, OpptyRevenueSplit.PROD_NON_INTEGRATED_SELLING};
      String[] pasProds = new String[]{'PasProd1','PasProd2','PasProd3',OpptyRevenueSplit.PROD_INTEGRATED_SELLING, OpptyRevenueSplit.PROD_INTERNAL, OpptyRevenueSplit.PROD_NON_INTEGRATED_SELLING};

      splitProdCodesCore.clear();
      splitProdCodesPas.clear();
      
      // add any additional plan codes
      for (OpptyRevSplit__mdt ors : testData) {
         if (ors.ProductCodes__c != 'All') {
            if (ors.SellingSalesOrg__c == UserHelper.SO_CORE) {
               coreProds.addAll(ors.ProductCodes__c.split(','));
               splitProdCodesCore.addAll(ors.ProductCodes__c.split(','));
            } else if (ors.SellingSalesOrg__c == UserHelper.SO_PEO_ASO) {
               pasProds.addAll(ors.ProductCodes__c.split(','));
               splitProdCodesPas.addAll(ors.ProductCodes__c.split(','));
            }
         }
      } // for (OpptyRevSplit__mdt ors
      PricebookEntry[] entriesCore = ProductMethodsTest.getEntries(coreProds, UserHelper.SO_CORE, null);
      PricebookEntry[] entriesPas = ProductMethodsTest.getEntries(pasProds, UserHelper.SO_PEO_ASO, null);
      for (PricebookEntry entry : entriesCore) {
         entryMapCore.put(entry.Product2.ProductCode, entry);
      }
      
      for (PricebookEntry entry : entriesPas) {
         entryMapPas.put(entry.Product2.ProductCode, entry);
      }
      
      // setup referral partners
      refPartCoreIntegrated = new Referral_Partner__c(Name=UserHelper.SO_CORE, Partner_Type__c=ReferralController.REF_INTSELL);
      refPartPasIntegrated = new Referral_Partner__c(Name=UserHelper.SO_PEO_ASO, Partner_Type__c=ReferralController.REF_INTSELL);
      refPartCoreInternal = new Referral_Partner__c(Name=UserHelper.SO_CORE, Partner_Type__c=ReferralController.REF_INTERNAL);
      Referral_Partner__c[] partners = new Referral_Partner__c[]{refPartCoreIntegrated,refPartPasIntegrated,refPartCoreInternal};
      insert partners;
   } // setupTestData
   
   public static Map<Id, Opportunity> getOppMap(Opportunity[] opps) {
      Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([select Id, Amount, CloseDate, Name, Probability, IsClosed
                                     ,Pricebook2Id
                                     ,RecordTypeId, RecordType.Name
                                     ,StageName
                                     ,(select Id
                                             ,Estimated_Revenue__c                
                                             ,Non_Discounted_Revenue__c
                                             ,Non_Payroll_Unit__c
                                             ,Payroll_Unit__c
                                             ,PricebookEntryId
                                             ,Product2Id                 
                                             ,Product2.Name 
                                             ,Product2.ProductCode
                                             ,QuoteLineGroupAcct__c
                                             ,SplitAdjustment__c
                                             ,SplitPercent__c
                                             ,TotalPrice
                                         from OpportunityLineItems )
                                 From Opportunity
                                Where Id in :opps]);
      return oppMap;
   } // getOppMap
   
   /*
   static testMethod void testMisc() {
      OpptyRevenueSplit ors = new OpptyRevenueSplit();
      ors.checkBeforeTrigger((SObject)null, (SObject)null);
      ors.checkAllBeforeTrigger(null, null);
      ors.processBeforeTriggerActions();
   } // testMisc

   static testMethod void testIntegrated() {
      setupTestData('Test 1');
      OpptyLineItem.SKIP_REVENUE_SPLIT = false;
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtCore = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
      Schema.RecordTypeInfo rtPas = byNameMap.get(OpportunityCreateCase.RT_OPPTY_PEO);

      User userCore = [Select Id, Name, Sales_Org__c, NSS_Team__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User userPas = [Select Id, Name, Sales_Org__c, NSS_Team__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO and Job_Name__c=:UserHelper.JOB_REP limit 1];

      Account acct1 = new Account(Name='Account 1', OwnerId=userCore.Id);
      Account acct2 = new Account(Name='Account 2', OwnerId=UserPas.Id);
      Account[] accts = new Account[]{acct1,acct2};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last 1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Last 2');
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctcts;
      
      // setup referral join record
      ReferralJoin__c refJoin = new ReferralJoin__c();
      insert refJoin;
      
      // setup referrals
      Referral__c refCore = new Referral__c(Name='Referral Core', Referral_Partner__c=refPartCoreIntegrated.Id, Account__c=acct1.Id, SourceContact__c=ctct1.Id, ReferralJoin__c=refJoin.Id);
      Referral__c refPas = new Referral__c(Name='Referral PAS', Referral_Partner__c=refPartPasIntegrated.Id, Account__c=acct2.Id, SourceContact__c=ctct2.Id, ReferralJoin__c=refJoin.Id);
      Referral__c[] refs = new Referral__c[]{refCore,refPas};
      insert refs;
      
      refJoin.Core_Referral__c = refCore.Id;
      refJoin.PAS_Referral__c = refPas.Id;
      update refJoin;
      
      PricebookEntry coreIntegratedPbe = entryMapCore.get(OpptyRevenueSplit.PROD_INTEGRATED_SELLING);
      
      
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      // setup core and pas opportunities
      Opportunity oppCore = new Opportunity(AccountId=acct1.Id, Name='Core Opp', Pricebook2Id=coreIntegratedPbe.Pricebook2Id, RecordTypeId=rtCore.getRecordTypeId(), StageName='Pending', CloseDate=Date.today().addDays(5), ReferralLookup__c=refCore.Id);
      Opportunity oppPAS = new Opportunity(AccountId=acct2.Id, Name='PAS Opp', RecordTypeId=rtPas.getRecordTypeId(), StageName='Qualified', CloseDate=Date.today().addDays(5), ReferralLookup__c=refPas.Id);
      Opportunity[] opps = new Opportunity[]{oppCore,oppPAS};
      
      // if I try to set the owners on insert I get
      // INVALID_CROSS_REFERENCE_KEY, Unable to create an opportunity team member for new opportunity split user.: [SplitOwnerId] 
      insert opps;
      //oppCore.OwnerId = userCore.Id;
      //oppPAS.OwnerId = userPas.Id;
      //update opps;
      
      OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
      
      refCore.Selling_Opportunity__c=oppCore.Id;
      refPas.Selling_Opportunity__c=oppPAS.Id;
      update refs;
      
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=oppPAS.Id, PricebookEntryId=entryMapPas.get('PasProd1').Id, ServiceDate=oppPAS.CloseDate, Quantity=1, TotalPrice=100);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=oppPAS.Id, PricebookEntryId=entryMapPas.get('PasProd2').Id, ServiceDate=oppPAS.CloseDate, Quantity=1, TotalPrice=200);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=oppPAS.Id, PricebookEntryId=entryMapPas.get('PasProd3').Id, ServiceDate=oppPAS.CloseDate, Quantity=1, TotalPrice=300);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3};
      
      System.debug('testIntegrated startTest');
      OpptyRevenueSplit.SKIP_FUTURE=true;
      Test.StartTest();
      insert olis;
      Test.StopTest();
      System.debug('testIntegrated stopTest');
        
      Map<Id, Opportunity> oppMap = getOppMap(opps); 
      System.debug('testIntegrated oppMap='+oppMap);

      Opportunity oppCheckPas = oppMap.get(oppPAS.Id);
      System.assertEquals(4, oppCheckPas.OpportunityLineItems.size());
      
      Integer nbrMatched = 0;
      
      OpportunityLineItem oliSplitRev = null;
      Decimal totalRev = 0;
      OpportunityLineItem oliPasProd1 = null;
      
      for (OpportunityLineItem oli : oppCheckPas.OpportunityLineItems) {
         if (oli.Product2.ProductCode == OpptyRevenueSplit.PROD_INTEGRATED_SELLING) {
            nbrMatched++;
            oliSplitRev = oli;
         } else {
            nbrMatched++;
            System.assertEquals(testData[0].PctReferring__c, oli.SplitPercent__c);
            Decimal checkRev = (oli.TotalPrice * testData[0].PctReferring__c/100).setScale(2, RoundingMode.HALF_UP);
            System.assertEquals(checkRev, oli.SplitAdjustment__c);
            totalRev += checkRev;
            if (oli.PricebookEntryId==entryMapPas.get('PasProd1').Id) {
               oliPasProd1 = oli;
            }
         }
      } // for (OpportunityLineItem oli
      
      System.assertNotEquals(null,oliPasProd1);
      System.assertEquals(4, nbrMatched);
      System.assertEquals(true, totalRev != 0, 'totalRev is 0!');
      System.assertEquals(totalRev*-1, oliSplitRev.TotalPrice);
      
      Opportunity oppCheckCore = oppMap.get(oppCore.Id);
      System.assertEquals(1, oppCheckCore.OpportunityLineItems.size());
      OpportunityLineItem checkOli = oppCheckCore.OpportunityLineItems[0];
      System.assertEquals(OpptyRevenueSplit.PROD_INTEGRATED_SELLING,checkOli.Product2.ProductCode);
      System.assertEquals(totalRev, checkOli.TotalPrice);
      
      // keep track of the revenue
      Decimal oppRevOrig = oppCheckPas.Amount;
      Decimal splitAmtOrig= oliSplitRev.TotalPrice;
      OpptyRevenueSplit.SKIP_FUTURE = true;
      
      oliPasProd1.TotalPrice=oliPasProd1.TotalPrice+100;
      Decimal splitAdj = (100 * testData[0].PctReferring__c/100).setScale(2, RoundingMode.HALF_UP);
      Decimal splitAdj2 = 100 - splitAdj;
      System.debug('testIntegrated before updating TotalPrice');
      OpptyLineItem.INSERT_TRIGGER_PROCESSED = false;
      OpptyLineItem.UPDATE_TRIGGER_PROCESSED = false;
      OpptyLineItem.SKIP_TRIGGER = false;
      OpptyRevenueSplit.oppIdsProcessed.clear();
      update oliPasProd1;
      
      oppMap = getOppMap(opps); 
      oppCheckPas = oppMap.get(oppPAS.Id);
      Decimal oppRevNew = oppCheckPas.Amount;

      oliSplitRev = null;
      for (OpportunityLineItem oli : oppCheckPas.OpportunityLineItems) {
         if (oli.Product2.ProductCode == OpptyRevenueSplit.PROD_INTEGRATED_SELLING) {
            nbrMatched++;
            oliSplitRev = oli;
         }
      }
      System.debug('testIntegrated oppRevOrig='+oppRevOrig+' oppRevNew='+oppRevNew+' splitAmtOrig='+splitAmtOrig+' splitAmtNew='+oliSplitRev.TotalPrice);

      System.assertEquals(oppRevOrig+splitAdj, oppRevNew);
      System.assertNotEquals(null,oliSplitRev);
      System.assertEquals((splitAmtOrig-splitAdj2), oliSplitRev.TotalPrice);
   } // testIntegrated
*/
    static testMethod void testInternalRef() {
      setupTestData('Test 2');
      OpptyLineItem.SKIP_REVENUE_SPLIT = false;

      // this should have a value to continue
      System.assertEquals(false, splitProdCodesPas.isEmpty());
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtCore = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
      Schema.RecordTypeInfo rtPas = byNameMap.get(OpportunityCreateCase.RT_OPPTY_PEO);

      User userCore = [Select Id, Name, Sales_Org__c, NSS_Team__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Job_Name__c=:UserHelper.JOB_REP limit 1];
      User userPas = [Select Id, Name, Sales_Org__c, NSS_Team__c from User where IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO and Job_Name__c=:UserHelper.JOB_REP limit 1];

      Account acct1 = new Account(Name='Account 1', OwnerId=userCore.Id);
      Account acct2 = new Account(Name='Account 2', OwnerId=userCore.Id);
      Account[] accts = new Account[]{acct1,acct2};
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last 1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Last 2');
      Contact[] ctcts = new Contact[]{ctct1,ctct2};
      insert ctcts;
      
      // setup referral
      Referral__c ref1 = new Referral__c(Name='Internal Referral Test 1', Referral_Partner__c=refPartCoreInternal.Id, Account__c=acct1.Id, SourceContact__c=ctct1.Id);
      Referral__c ref2 = new Referral__c(Name='Internal Referral Test 2', Referral_Partner__c=refPartCoreInternal.Id, Account__c=acct2.Id, SourceContact__c=ctct2.Id);
      Referral__c[] refs = new Referral__c[]{ref1,ref2};
      insert refs;

      // place holder on the Core opportunity - which should be the referring opp.
      PricebookEntry coreIntRef = entryMapCore.get(OpptyRevenueSplit.PROD_INTERNAL);
      
      Opportunity oppCore = new Opportunity(AccountId=acct1.Id, Name='Core Opp', Pricebook2Id=coreIntRef.Pricebook2Id, RecordTypeId=rtCore.getRecordTypeId(), StageName='Pending', CloseDate=Date.today().addDays(5), ReferralLookup__c=ref1.Id);
      Opportunity oppPAS = new Opportunity(AccountId=acct1.Id, Name='PAS Opp', RecordTypeId=rtPas.getRecordTypeId(), StageName='Qualified', CloseDate=Date.today().addDays(5), ReferralLookup__c=ref1.Id);
      Opportunity oppCore2 = new Opportunity(AccountId=acct2.Id, Name='Core Opp 2', Pricebook2Id=coreIntRef.Pricebook2Id, RecordTypeId=rtCore.getRecordTypeId(), StageName='Pending', CloseDate=Date.today().addDays(5), ReferralLookup__c=ref2.Id);
      // set this one so the revenue won't split.
      Opportunity oppPAS2 = new Opportunity(AccountId=acct2.Id, Name='PAS Opp 2', RecordTypeId=rtPas.getRecordTypeId(), StageName='Qualified', CloseDate=Date.today().addDays(5), ReferralLookup__c=ref2.Id, OverrideRevenueSplit__c=true);
      Opportunity[] opps = new Opportunity[]{oppCore,oppPAS,oppCore2,oppPAS2};
      insert opps;

      OpportunityLineItem oliCore1 = new OpportunityLineItem(OpportunityId=oppCore.Id, PricebookEntryId=coreIntRef.Id, ServiceDate=oppCore.CloseDate, Quantity=1, TotalPrice=0);
      OpportunityLineItem oliCore2 = new OpportunityLineItem(OpportunityId=oppCore2.Id, PricebookEntryId=coreIntRef.Id, ServiceDate=oppCore2.CloseDate, Quantity=1, TotalPrice=0);
      OpportunityLineItem[] referringOlis = new OpportunityLineItem[]{oliCore1,oliCore2};
      insert referringOlis;
      System.debug('testInternalRef after insert oliCore');
      
      // set the referring line id for an internal referral
      ref1.ReferringLineItemId__c = oliCore1.Id;
      ref1.Referring_Opportunity__c = oppCore.Id;
      ref1.Selling_Opportunity__c = oppPAS.Id;
      ref2.ReferringLineItemId__c = oliCore2.Id;
      ref2.Referring_Opportunity__c = oppCore2.Id;
      ref2.Selling_Opportunity__c = oppPAS2.Id;
      update refs;

      System.assertEquals(true, splitProdCodesPas.size() > 0, 'There are no values for splitProdCodesPas');
      
      OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      Decimal testTotalPrice = 100;
      for (String prodName : splitProdCodesPas) {
         System.debug('testInternalRef add line item for '+prodName+' testTotalPrice='+testTotalPrice);
         PricebookEntry pbe = entryMapPas.get(prodName);
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=oppPAS.Id, PricebookEntryId=pbe.Id, ServiceDate=oppPAS.CloseDate, Quantity=1, TotalPrice=testTotalPrice);
         olis.add(oli);
         oli = new OpportunityLineItem(OpportunityId=oppPAS2.Id, PricebookEntryId=pbe.Id, ServiceDate=oppPAS2.CloseDate, Quantity=1, TotalPrice=testTotalPrice);
         olis.add(oli);
         testTotalPrice += 100;
      }
      
      System.debug('testInternalRef olis '+olis.size());
      OpptyLineItem.resetFlags();

      Test.startTest();        
      insert olis;        
      Test.stopTest();
     
      Map<Id, Opportunity> oppMap = getOppMap(opps); 
      System.debug('testInternalRef oppMap='+oppMap.size());
      
      Opportunity oppCheckPas = oppMap.get(oppPAS.Id);
      System.assertEquals(splitProdCodesPas.size()+1, oppCheckPas.OpportunityLineItems.size());

      Integer nbrMatched = 0;
      
      OpportunityLineItem oliSplitRev = null;
      Decimal totalRev = 0;
      
      for (OpportunityLineItem oli : oppCheckPas.OpportunityLineItems) {
         if (oli.Product2.ProductCode == OpptyRevenueSplit.PROD_INTERNAL) {
            nbrMatched++;
            oliSplitRev = oli;
         } else {
            nbrMatched++;
            System.assertEquals(testData[0].PctReferring__c, oli.SplitPercent__c);
            Decimal checkRev = (oli.TotalPrice * testData[0].PctReferring__c/100).setScale(2, RoundingMode.HALF_UP);
            System.assertEquals(checkRev, oli.SplitAdjustment__c);
            totalRev += checkRev;
         }
      } // for (OpportunityLineItem oli

      System.assertEquals(splitProdCodesPas.size()+1, nbrMatched);
      System.assertEquals(true, totalRev != 0, 'totalRev is 0!');
      System.assertEquals(totalRev*-1, oliSplitRev.TotalPrice);
      
      Opportunity oppCheckCore = oppMap.get(oppCore.Id);
      System.assertEquals(1, oppCheckCore.OpportunityLineItems.size());
      OpportunityLineItem checkOli = oppCheckCore.OpportunityLineItems[0];
      System.assertEquals(totalRev, checkOli.TotalPrice);

      // this one shouldn't have been updated because the opp was marked with the override checkbox.      
      Opportunity oppCheckCore2 = oppMap.get(oppCore2.Id);
      System.assertEquals(1, oppCheckCore2.OpportunityLineItems.size());
      OpportunityLineItem checkOli2 = oppCheckCore2.OpportunityLineItems[0];
      System.assertEquals(0, checkOli2.TotalPrice);

   } // testInternalRef
/*
   static testMethod void testNonIntegrated() {
      setupTestData('Test 3');

      // this should have a value to continue
      System.assertEquals(false, splitProdCodesPas.isEmpty());
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtPas = byNameMap.get(OpportunityCreateCase.RT_OPPTY_PEO);

      Account acct1 = new Account(Name='Account 1');
      insert acct1;
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last 1');
      insert ctct1;
      
      RecordType__c rtOpp = new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_PEO,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_PEO, Sales_Org__c=UserHelper.SO_PEO_ASO, UsedInOwnership__c=true, NonIntegratedSellingAdjustment__c=true);
      insert rtOpp;
      
      Opportunity oppPAS = new Opportunity(AccountId=acct1.Id, Name='PAS Opp', RecordTypeId=rtPas.getRecordTypeId(), StageName='Qualified', CloseDate=Date.today().addDays(5));
      insert oppPAS;
      
      System.assertEquals(true, splitProdCodesPas.size() > 0, 'There are no values for splitProdCodesPas');
      
      OpportunityLineItem[] olis = new OpportunityLineItem[]{};
      Decimal testTotalPrice = 100;
      for (String prodName : splitProdCodesPas) {
         System.debug('testNonIntegrated add line item for '+prodName+' testTotalPrice='+testTotalPrice);
         PricebookEntry pbe = entryMapPas.get(prodName);
         OpportunityLineItem oli = new OpportunityLineItem(OpportunityId=oppPAS.Id, PricebookEntryId=pbe.Id, ServiceDate=oppPAS.CloseDate, Quantity=1, TotalPrice=testTotalPrice);
         olis.add(oli);
         testTotalPrice += 100;
      }
      
      System.debug('testNonIntegrated olis '+olis.size());
      Test.startTest();
      insert olis;
      Test.stopTest();
     
      Map<Id, Opportunity> oppMap = getOppMap(new Opportunity[]{oppPAS}); 
      System.debug('testNonIntegrated oppMap='+oppMap.size());
      
      Opportunity oppCheckPas = oppMap.get(oppPAS.Id);
      System.assertEquals(splitProdCodesPas.size()+1, oppCheckPas.OpportunityLineItems.size());

      Integer nbrMatched = 0;
      
      OpportunityLineItem oliSplitRev = null;
      Decimal totalRev = 0;
      
      for (OpportunityLineItem oli : oppCheckPas.OpportunityLineItems) {
         if (oli.Product2.ProductCode == OpptyRevenueSplit.PROD_NON_INTEGRATED_SELLING) {
            nbrMatched++;
            oliSplitRev = oli;
         } else {
            nbrMatched++;
            System.assertEquals(testData[0].PctReferring__c, oli.SplitPercent__c);
            Decimal checkRev = (oli.TotalPrice * testData[0].PctReferring__c/100).setScale(2, RoundingMode.HALF_UP);
            System.assertEquals(checkRev, oli.SplitAdjustment__c);
            totalRev += checkRev;
         }
      } // for (OpportunityLineItem oli

      System.assertEquals(splitProdCodesPas.size()+1, nbrMatched);
      System.assertEquals(true, totalRev != 0, 'totalRev is 0!');
      System.assertEquals(totalRev*-1, oliSplitRev.TotalPrice);
      
   } // testNonIntegrated
*/
} // class OpptyRevenueSplitTest