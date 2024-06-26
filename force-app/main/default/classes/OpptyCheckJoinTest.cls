/* Test methods for the OpptyCheckJoin class.

 * History
 * -------
   05/19/2016 Dan Carmen   Created
   11/15/2017 Dan Carmen   Added to TriggerInterface
   01/23/2018 Dan Carmen   Added another record type to the setting.
   09/07/2018 Dan Carmen   Separate out setupRecordTypes
   10/19/2021 Dan Carmen   Add matching based on Product Group

 */
@isTest
public class OpptyCheckJoinTest {

   @testSetup
   public static void setupRecordTypeSettingForOpps() {
      UserHelperTest.setupSalesOrgSetting();
      setupRecordTypes();
      
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'OpptyCheckJoin'});
      TriggerMethodsTest.saveSetupClasses();

   } // setupRecordTypeSettingForOpps
   
   public static void setupRecordTypes() {
      // setup opportunity record types
      RecordType__c[] recordTypes = new RecordType__c[]{};

      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.cleanRtName(OpportunityCreateCase.RT_OPPTY_CORE),ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE, Sales_Org__c=UserHelper.SO_CORE, SecondarySalesOrg__c=UserHelper.SO_MMS,CheckForOppDupes__c=true, OpportunityType__c='Payroll'));
      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.cleanRtName(OpportunityCreateCase.RT_OPPTY_CORE_DSA),ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_CORE_DSA, Sales_Org__c=UserHelper.SO_CORE, SecondarySalesOrg__c=UserHelper.SO_MMS,CheckForOppDupes__c=false, OpportunityType__c='Payroll'));

      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.cleanRtName(OpportunityCreateCase.RT_OPPTY_MMS),ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, Sales_Org__c=UserHelper.SO_MMS, SecondarySalesOrg__c=UserHelper.SO_CORE,CheckForOppDupes__c=true, OpportunityType__c='Payroll'));
      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.cleanRtName(OpportunityCreateCase.RT_OPPTY_MMS_DSA),ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS_DSA, Sales_Org__c=UserHelper.SO_MMS, SecondarySalesOrg__c=UserHelper.SO_CORE,CheckForOppDupes__c=false, OpportunityType__c='Payroll'));

      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.cleanRtName(OpportunityCreateCase.RT_OPPTY_401K),ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OpportunityCreateCase.RT_OPPTY_401K, Sales_Org__c=UserHelper.SO_401, SecondarySalesOrg__c=null,CheckForOppDupes__c=true, OpportunityType__c='New Plan'));

      insert recordTypes;

   } // setupRecordTypes
   

   static testMethod void testOpptyJoin() {
      //for (TriggerSetupClasses__c tsc : TriggerSetupClasses__c.getAll().values()) {
      //   System.debug('testOpptyJoin tsc='+tsc);
      //}
      
      SalesOrg__c salesOrgPay = SalesOrg__c.getInstance(UserHelper.SO_CORE);
      SalesOrg__c salesOrgHrs = SalesOrg__c.getInstance(UserHelper.SO_401);
      // Test.setCreatedDate(Id, DateTime)
      
      Account acct1 = new Account(Name='Test Account1');
      Account acct2 = new Account(Name='Test Account2');
      Account acct3 = new Account(Name='Test Account3');
      Account acct4 = new Account(Name='Test Account4');
      Account acct5 = new Account(Name='Test Account5');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Map<String, Schema.RecordTypeInfo> opptyRtMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtPay1 = opptyRtMap.get(salesOrgPay.OpptyRecordTypeName__c);
      Schema.RecordTypeInfo rtPay2 = opptyRtMap.get(salesOrgPay.OpptyRecordTypeName2__c);
      Schema.RecordTypeInfo rtHrs1 = opptyRtMap.get(salesOrgHrs.OpptyRecordTypeName__c);
      // make sure they exist
      System.assertEquals(true,rtPay1 != null);
      System.assertEquals(true,rtPay2 != null);
      System.assertEquals(true,rtHrs1 != null);
      
      Opportunity opp1a = new Opportunity(Name='Opp1a',AccountId=acct1.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay1.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp2a = new Opportunity(Name='Opp2a',AccountId=acct2.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay1.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp3a = new Opportunity(Name='Opp3a',AccountId=acct3.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay1.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp4a = new Opportunity(Name='Opp4a',AccountId=acct4.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay1.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp5a = new Opportunity(Name='Opp5a',AccountId=acct5.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay1.getRecordTypeId(),OpportunityType__c='Payroll');
      Opportunity[] oldOpps = new Opportunity[]{opp1a,opp2a,opp3a,opp4a,opp5a};
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert oldOpps;
      OpptyMethods.SKIP_OPPTY_TRIGGERS=false;
      
      // change the created date to control which ones will link.
      // this should still fall in the range
      Test.setCreatedDate(opp2a.Id,DateTime.now().addDays(-2));
      // this should be outside the range
      Test.setCreatedDate(opp3a.Id,DateTime.now().addDays(-10));

      Opportunity[] testQuery = [Select Id, Name, AccountId, RecordTypeId, CreatedDate from Opportunity];
      System.debug('testOpptyJoin now='+DateTime.now());
      for (Opportunity testOpp : testQuery) {
         System.debug('testOpptyJoin testOpp='+testOpp.Name+' CreatedDate='+testOpp.CreatedDate);
      }
      
      // set to look back 3 days
      OpptyCheckJoin.NUM_HOURS_TO_CHECK = 72;
      
      Opportunity opp1b = new Opportunity(Name='Opp1b',AccountId=acct1.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay2.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp2b = new Opportunity(Name='Opp2b',AccountId=acct2.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay2.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp3b = new Opportunity(Name='Opp3b',AccountId=acct3.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtPay2.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp4b = new Opportunity(Name='Opp4b',AccountId=acct4.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtHrs1.getRecordTypeId(),OpportunityType__c='TestType1');
      Opportunity opp5b = new Opportunity(Name='Opp5b',AccountId=acct5.Id,StageName='Pending',CloseDate=Date.today().addDays(7),RecordTypeId=rtHrs1.getRecordTypeId(),OpportunityType__c='New Plan'
                                              ,EvaluateProductGroupOverride__c=true, ProductGroupsSelected__c='Payroll' );
      Opportunity[] newOpps = new Opportunity[]{opp1b,opp2b,opp3b,opp4b,opp5b};
      System.debug('testOpptyJoin before insert newOpps');
      Test.startTest();
      insert newOpps;
      Test.stopTest();
      
      // joins should be created for 1 and 2. 3 should not because it falls outside of the date range. 4 should not because not the same type. 5 should match based on the product group
      OpportunityJoin__c[] joins = [Select Id, MatchType__c
                                          ,OpportunityParent__r.Name
                                          ,OpportunityChild__r.Name
                                      From OpportunityJoin__c];
      System.assertEquals(3,joins.size());
      OpportunityJoin__c found1a = null;
      OpportunityJoin__c found2a = null;
      OpportunityJoin__c found5a = null;
      for (OpportunityJoin__c oppJoin : joins) {
         System.debug('testOpptyJoin parent='+oppJoin.OpportunityParent__r.Name+' child='+oppJoin.OpportunityChild__r.Name);
         found1a = (oppJoin.OpportunityParent__c == opp1a.Id ? oppJoin : found1a);
         found2a = (oppJoin.OpportunityParent__c == opp2a.Id ? oppJoin : found2a);
         found5a = (oppJoin.OpportunityParent__c == opp5a.Id ? oppJoin : found5a);
      } // for (OpportunityJoin__c oppJoin
      System.assertEquals(true, (found1a != null));
      System.assertEquals(OpptyCheckJoin.MATCH_RT, found1a.MatchType__c);
      System.assertEquals(true, (found2a != null));
      System.assertEquals(OpptyCheckJoin.MATCH_RT, found2a.MatchType__c);
      System.assertEquals(true, (found5a != null));
      System.assertEquals(OpptyCheckJoin.MATCH_PG, found5a.MatchType__c);
   } // testOpptyJoin

   static testMethod void testCheckMatchingRTIdSetMap() {
      //setupRecordTypeSettingForOpps();
      
      OpptyCheckJoin.checkMatchingRTIdSetMap();
      
      Map<String, Schema.RecordTypeInfo> opptyRtMap = Opportunity.getSobjectType().getDescribe().getRecordTypeInfosByName();

      // make sure all core and mms record types are linked together.
      Schema.RecordTypeInfo coreRtInfo = opptyRtMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
      System.assertEquals(4,OpptyCheckJoin.matchingRTIdSetMap.get(coreRtInfo.getRecordTypeId()).size());
      
      Schema.RecordTypeInfo coreDsaRtInfo = opptyRtMap.get(OpportunityCreateCase.RT_OPPTY_CORE_DSA);
      System.assertEquals(4,OpptyCheckJoin.matchingRTIdSetMap.get(coreDsaRtInfo.getRecordTypeId()).size());
      
      Schema.RecordTypeInfo mmsRtInfo = opptyRtMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
      System.assertEquals(4,OpptyCheckJoin.matchingRTIdSetMap.get(mmsRtInfo.getRecordTypeId()).size());
      
      Schema.RecordTypeInfo mmsDsaRtInfo = opptyRtMap.get(OpportunityCreateCase.RT_OPPTY_MMS_DSA);
      System.assertEquals(4,OpptyCheckJoin.matchingRTIdSetMap.get(mmsDsaRtInfo.getRecordTypeId()).size());
      
   } // testCheckMatchingRTIdSetMap

} // class OpptyCheckJoinTest