/* 
 * Test methods for the LeadSourceHelper
 *
 * History
 * -------
   01/10/2019 Dan Carmen       Created
   01/26/2023 Dan Carmen       Increment API, change to TriggerInterfaceC

 */
@isTest
public class LeadSourceHelperTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false,new String[]{'LeadSourceHelper'});
      TriggerMethodsTest.saveSetupClasses();

      LeadSource__c ls1 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-CPA-AICPA'), Category__c=Label.LeadSourceCat_CPA);
      LeadSource__c ls2 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-CPA-AICPA Platinum'), Category__c=Label.LeadSourceCat_CPA);
      LeadSource__c ls3 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-CPA-Non-AICPA'), Category__c=Label.LeadSourceCat_CPA);
      LeadSource__c ls4 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Name Dropper'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls5 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-Paychex Insiders'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls6 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-SOAR-Additional ID'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls7 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-SOAR-Additional Product'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls8 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-SOAR-New'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls9 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-Solicited'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls10 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Client-Unsolicited'), Category__c=Label.LeadSourceCat_Client);
      LeadSource__c ls11 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Outbound'), Category__c='NSS Outbound');
      LeadSource__c ls12 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Financial Advisor'), Category__c=Label.LeadSourceCat_FinAdv);
      LeadSource__c ls13 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Independent Ins. Agent'), Category__c=Label.LeadSourceCat_InsAgent);
      LeadSource__c ls14 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Bank Referral'), Category__c=Label.LeadSourceCat_Bank);
      LeadSource__c ls15 = new LeadSource__c(Name=RecordTypeHelper.cleanRtName('Referral-Strategic Account'), Category__c=Label.LeadSourceCat_Strategic);
      LeadSource__c[] leadSources = new LeadSource__c[]{ls1,ls2,ls3,ls4,ls5,ls6,ls7,ls8,ls9,ls10,ls11,ls12,ls13,ls14,ls15};
      insert leadSources;
      
   } // setupData
   
   public static LeadSource__c getLeadSourceByCategory(String lsCategory) {
      LeadSource__c retVal = null;
      for (LeadSource__c ls : LeadSource__c.getAll().values()) {
         if (ls.Category__c == lsCategory) {
            retVal = ls;
            break;
         }
      } // for (LeadSource__c ls
      return retVal;
   } // getLeadSourceByCategory
   
   static testMethod void testOppLeadSource() {
      Account acct = new Account(Name='Account1');
      insert acct;
      
      Opportunity opp1 = new Opportunity(AccountId=acct.Id, Name='Opp1',CloseDate=Date.today().addDays(7), StageName='Pending', LeadSource='Referral-CPA-AICPA');
      Opportunity opp2 = new Opportunity(AccountId=acct.Id, Name='Opp2',CloseDate=Date.today().addDays(7), StageName='Pending', LeadSource='Referral-Client-Solicited');
      Opportunity opp3 = new Opportunity(AccountId=acct.Id, Name='Opp3',CloseDate=Date.today().addDays(7), StageName='Pending', LeadSource=null);
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3};
      insert opps;
      
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, LeadSource, LeadSourceCategory__c from Opportunity where Id in :opps]);
      
      LeadSourceHelper.DEFAULT_CATEGORY='DefaultCategory';
      
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals(Label.LeadSourceCat_CPA, opp1.LeadSourceCategory__c);
      opp2 = oppMap.get(opp2.Id);
      System.assertEquals(Label.LeadSourceCat_Client, opp2.LeadSourceCategory__c);
      opp3 = oppMap.get(opp3.Id);
      System.assertEquals(null, opp3.LeadSourceCategory__c);

      // so we can run the test again      
      TriggerMethods.clearVariables();
      opp1.LeadSource = 'Referral-Client-SOAR-Additional Product';
      opp2.LeadSource = 'Referral-CPA-Non-AICPA';
      opp3.LeadSource = 'ThisIsABadLeadSource';
      opps = new Opportunity[]{opp1,opp2,opp3};
      System.debug('testOppLeadSource test 1');
      update opps;
      
      oppMap = new Map<Id,Opportunity>([Select Id, Name, LeadSource, LeadSourceCategory__c, NSS_Source__c from Opportunity where Id in :opps]);
      
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals(Label.LeadSourceCat_Client, opp1.LeadSourceCategory__c);
      opp2 = oppMap.get(opp2.Id);
      System.assertEquals(Label.LeadSourceCat_CPA, opp2.LeadSourceCategory__c);
      opp3 = oppMap.get(opp3.Id);
      System.assertEquals('DefaultCategory', opp3.LeadSourceCategory__c);
      
      // so we can run the test again      
      TriggerMethods.clearVariables();
      opp1.LeadSource = 'BadLeadSourceThisIs';
      opp1.NSS_Source__c='Inbound';
      opp3.LeadSource = 'Referral-Client-Paychex Insiders';

      opps = new Opportunity[]{opp1,opp2,opp3};
      System.debug('testOppLeadSource test 2');
      update opps;
      
      oppMap = new Map<Id,Opportunity>([Select Id, Name, LeadSource, LeadSourceCategory__c, NSS_Source__c from Opportunity where Id in :opps]);
      
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals('DefaultCategory', opp1.LeadSourceCategory__c);
      opp2 = oppMap.get(opp2.Id);
      System.assertEquals(Label.LeadSourceCat_CPA, opp2.LeadSourceCategory__c);
      opp3 = oppMap.get(opp3.Id);
      System.assertEquals(Label.LeadSourceCat_Client, opp3.LeadSourceCategory__c);
      
      // so we can run the test again      
      TriggerMethods.clearVariables();
      opp1.NSS_Source__c='Outbound';
      opp2.NSS_Source__c='Outbound';
      opp3.NSS_Source__c='Outbound';
      
      opps = new Opportunity[]{opp1,opp2,opp3};
      System.debug('testOppLeadSource test 3');
      update opps;
      
      oppMap = new Map<Id,Opportunity>([Select Id, Name, LeadSource, LeadSourceCategory__c, NSS_Source__c from Opportunity where Id in :opps]);
      
      opp1 = oppMap.get(opp1.Id);
      System.assertEquals('NSS Outbound', opp1.LeadSourceCategory__c);
      opp2 = oppMap.get(opp2.Id);
      System.assertEquals('NSS Outbound', opp2.LeadSourceCategory__c);
      opp3 = oppMap.get(opp3.Id);
      System.assertEquals('NSS Outbound', opp3.LeadSourceCategory__c);

   } // testOppLeadSource
   
} // class LeadSourceHelperTest