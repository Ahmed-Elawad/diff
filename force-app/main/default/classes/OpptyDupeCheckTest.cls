/**
 * Test methods for the OpptyDupeCheck class.
 
 
  History
  -------
  10/27/2017 Dan Carmen        Created
  10/10/2018 Dan Carmen        Add additional logging
  10/26/2021 Dan Carmen        Add logic for Product Groups
  
 */
@isTest
private class OpptyDupeCheckTest {
   
   public static String TEST_OPP_NAME='OpptyDupeCheckTest Test Opp';
   
   @testSetup
   static void setupData() {
      OpptyCheckJoinTest.setupRecordTypeSettingForOpps();
      
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtCore = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
      Opportunity opp = new Opportunity(AccountId=acct.Id, RecordTypeId=rtCore.getRecordTypeId(), Name=TEST_OPP_NAME, CloseDate=Date.today(), StageName='Pending'
                                       ,OpportunityType__c='Payroll');
      insert opp;

   } // setupData 
   
   public static Opportunity getSetupOpp() {
      Opportunity opp = [Select Id, IsClosed, Name, RecordTypeId, AccountId, OpportunityType__c, AdditionalProductsOfInterest__c
                               ,EvaluateProductGroup__c, ProductGroupsSelected__c, ProductGroupByOpptyType__c 
                           from Opportunity where Name=:TEST_OPP_NAME];
      return opp;
   } // getSetupOpp

   static testMethod void testDoWeCheckForDupes() {
      RecordType__c rtSetting = RecordType__c.getInstance(OpportunityCreateCase.RT_OPPTY_CORE);
      //RecordType__c rtSetting = new RecordType__c(Name=OpportunityCreateCase.RT_OPPTY_CORE, CheckForOppDupes__c=true);
      //insert rtSetting;

      Opportunity opp = getSetupOpp();
      
      System.assertEquals(true, OpptyDupeCheck.doWeCheckForDupes(opp, OpportunityCreateCase.RT_OPPTY_CORE));
      delete rtSetting;
      System.assertEquals(false, OpptyDupeCheck.doWeCheckForDupes(opp, OpportunityCreateCase.RT_OPPTY_CORE));
      System.assertEquals(false, OpptyDupeCheck.doWeCheckForDupes(opp, null));
      
      Opportunity[] dupeOpps = OpptyDupeCheck.dupeOpps(opp);
      
   } // testDoWeCheckForDupes
   
   
   static testMethod void testGetRecordTypesToCheckAgainst() {
      Opportunity opp = getSetupOpp();
      Id[] recordTypeIds = OpptyDupeCheck.getRecordTypesToCheckAgainst(opp);
      System.assertEquals(4, recordTypeIds.size());
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      // these are the 4 record type ids that should be in the set.
      Set<Id> idCheckSet = new Set<Id>();
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId());
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE_DSA).getRecordTypeId());
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS).getRecordTypeId());
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS_DSA).getRecordTypeId());
      
      for (Id recordTypeId : recordTypeIds) {
         System.assertEquals(true, idCheckSet.contains(recordTypeId), 'The Id '+recordTypeId+' was not found!');
      }

   } // testGetRecordTypesToCheckAgainst

   static testMethod void testGetMatchingOpps() {
      
      // source opp
      Opportunity opp = getSetupOpp();
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      // these are the 4 record type ids that should be in the set.
      Set<Id> idCheckSet = new Set<Id>();
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId());
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE_DSA).getRecordTypeId());
      idCheckSet.add(byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS).getRecordTypeId());

      Opportunity oppMatch1 = new Opportunity(Name='oppMatch1', AccountId=opp.AccountId, RecordTypeId=byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId()
                                            ,CloseDate=Date.today(), StageName='Sold', Probability=95, OpportunityType__c='Payroll');
      Opportunity oppMatch2 = new Opportunity(Name='oppMatch3', AccountId=opp.AccountId, RecordTypeId=byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS).getRecordTypeId()
                                            ,CloseDate=Date.today(), StageName='Sold', Probability=95, OpportunityType__c='Payroll');

      // create matching and non-matching opps
      Opportunity oppNoMatch1 = new Opportunity(Name='oppNoMatch1', AccountId=opp.AccountId, RecordTypeId=byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId()
                                            ,CloseDate=Date.today(), StageName='Pending', OpportunityType__c='Ancillary');
      Opportunity oppNoMatch2 = new Opportunity(Name='oppNoMatch2', AccountId=opp.AccountId, RecordTypeId=byNameMap.get(OpportunityCreateCase.RT_OPPTY_401K).getRecordTypeId()
                                            ,CloseDate=Date.today(), StageName='Sold', Probability=95);
      Opportunity[] opps = new Opportunity[]{oppMatch1,oppMatch2,oppNoMatch1,oppNoMatch2};
      insert opps;
      

      Id[] recordTypeIds = OpptyDupeCheck.getRecordTypesToCheckAgainst(opp);

      Opportunity[] matchingOpps = OpptyDupeCheck.getMatchingOpps(opp, recordTypeIds);
      System.assertEquals(2, matchingOpps.size());
      for (Opportunity checkOpp : matchingOpps) {
         System.assertEquals(true, (checkOpp.Id == oppMatch1.Id || checkOpp.Id == oppMatch2.Id));
      }

   } // testGetMatchingOpps
   
} // class OpptyDupeCheckTest