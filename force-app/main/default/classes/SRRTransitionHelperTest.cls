/* Test methods for the SRRTransitionHelper class
   
  History
  -------
  04/08/2016 Dan Carmen         Created
  12/15/2016 Lynn Michels       added PartnerId__c to Referral Accounts in testAccountLookups
  02/01/2018 Dan Carmen         Implement the TriggerInterface code.
  10/10/2019 Dan Carmen         Add TriggerMethods.clearVariables();
  

 */
@isTest
public class SRRTransitionHelperTest {

   @testSetup
   public static void setupData() {
      setupCustomSettings();

      // to skip the other triggers and use this code instead.
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = true;
      ReferralTriggerActions.SKIP_TRIGGER = true;
   } // setupData
    
   public static void setupCustomSettings() {
      // setup triggers
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'SRRTransitionHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'SRRTransitionHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'SRRTransitionHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ReferralTrigger', true, false, false, false, new String[]{'SRRTransitionHelper'}, classes, TriggerMethods.INTERFACE_C);

      insert classes;
   } // setupCustomSettings

   static testMethod void testContactLookups() {
      ReferralObjectsSync.SKIP_SYNC=false;
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Acct');
      insert refAcct;
      refAcct = [Select Id, Name, Account__c, Account__r.Id, Account__r.Name from Referral_Account__c where Id=:refAcct.Id];
      System.assertEquals(true,refAcct.Account__r != null);
      
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Jimmy Test', First_Name__c='Jimmy', Last_Name__c='Test',Referral_Account__c=refAcct.Id);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Johnny Test', First_Name__c='Johnny', Last_Name__c='Test',Referral_Account__c=refAcct.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2};
      insert refCtcts;
      
      refCtct1 = [Select Id, Name, Contact__c, Contact__r.Id, Contact__r.AccountId from Referral_Contact__c where Id=:refCtct1.Id];
      refCtct2 = [Select Id, Name, Contact__c, Contact__r.Id, Contact__r.AccountId from Referral_Contact__c where Id=:refCtct2.Id];
      System.assertEquals(refAcct.Account__r.Id, refCtct1.Contact__r.AccountId);
      System.assertEquals(refAcct.Account__r.Id, refCtct2.Contact__r.AccountId);

      Lead ld = new Lead(Company='Test Lead', LastName='Smith', Referral_Contact__c=refCtct1.Id);
      insert ld;
      
      ld = [Select Id, Name, Referral_Contact__c, ReferralContact__c from Lead where Id=:ld.Id];
      System.assertEquals(refCtct1.Contact__c, ld.ReferralContact__c);
      
      ld.ReferralContact__c = null;
      TriggerMethods.clearVariables();
      update ld;
      ld = [Select Id, Name, Referral_Contact__c, ReferralContact__c from Lead where Id=:ld.Id];
      System.assertEquals(refCtct1.Contact__c, ld.ReferralContact__c);
      
      ld.Referral_Contact__c=refCtct2.Id;
      TriggerMethods.clearVariables();
      update ld;
      ld = [Select Id, Name, Referral_Contact__c, ReferralContact__c from Lead where Id=:ld.Id];
      System.assertEquals(refCtct2.Contact__c, ld.ReferralContact__c);


      Account acct = new Account(Name='Test Prospect');
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, LastName='SmithJones');
      insert ctct;
      ctct.Referral_Contact__c = refCtct2.Id;
      update ctct;
      ctct = [Select Id, Name, Referral_Contact__c, ReferralContact__c from Contact where Id=:ctct.Id];
      System.assertEquals(refCtct2.Contact__c, ctct.ReferralContact__c);
      
      Opportunity opp = new Opportunity(Name='Test Opp1', CloseDate=Date.today().addDays(7), StageName='Pending');
      insert opp;
      opp.Referral_Contact__c = refCtct1.Id;
      update opp;
      opp = [Select Id, Referral_Contact__c, ReferralContact__c, Referral_Account__c, ReferralAccount__c from Opportunity where Id=:opp.Id];
      System.assertEquals(refCtct1.Contact__c, opp.ReferralContact__c);
      System.assertEquals(refAcct.Account__c, opp.ReferralAccount__c);

      Case cs = new Case(Subject='Test Case');
      insert cs;
      cs.Referral_Contact__c = refCtct1.Id;
      update cs;
      cs = [Select Id, Referral_Contact__c, ReferralContact__c from Case where Id=:cs.Id];
      System.assertEquals(refCtct1.Contact__c, opp.ReferralContact__c);
      
      
      Reference_401k_S125__c ref401 = new Reference_401k_S125__c(Case_Lookup__c=cs.Id, Financial_Advisor__c=refCtct1.Id);
      insert ref401;
      
      ref401 = [Select Id, Financial_Advisor__c, FinancialAdvisor__c from Reference_401k_S125__c where Id=:ref401.Id];
      System.assertEquals(refCtct1.Contact__c, ref401.FinancialAdvisor__c);

      Referral_Partner__c refPart = new Referral_Partner__c(Name='test', Referral_Contact__c=refCtct1.Id);
      insert refPart;
      
      refPart = [Select Id, Referral_Contact__c, DefaultReferralContact__c from Referral_Partner__c where Id=:refPart.Id];
      System.assertEquals(refCtct1.Contact__c, refPart.DefaultReferralContact__c);
      
      Referral__c ref1 = new Referral__c(Referral_Contact__c=refCtct1.Id);
      Referral__c ref2 = new Referral__c(Referral_Account__c=refAcct.Id);
      Referral__c[] refs = new Referral__c[]{ref1,ref2};
      insert refs;
      
      ref1 = [Select Id, Referral_Contact__c, ReferralSourceContact__c from Referral__c where Id=:ref1.Id];
      System.assertEquals(refCtct1.Contact__c, ref1.ReferralSourceContact__c);
      ref2 = [Select Id, Referral_Account__c, ReferralSourceAccount__c from Referral__c where Id=:ref2.Id];
      System.assertEquals(refAcct.Account__c, ref2.ReferralSourceAccount__c);
   } // testContactLookups

   static testMethod void testAccountLookups() {
      ReferralObjectsSync.SKIP_SYNC=false;
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test Acct1', PartnerId__c = '1234');
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test Acct2', PartnerId__c = '5678');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2};
      insert refAccts;
      refAcct1 = [Select Id, Name, Account__c, Account__r.Id, Account__r.Name from Referral_Account__c where Id=:refAcct1.Id];
      System.assertEquals(true,refAcct1.Account__r != null);
      
      refAcct2 = [Select Id, Name, Account__c, Account__r.Id, Account__r.Name from Referral_Account__c where Id=:refAcct2.Id];
      System.assertEquals(true,refAcct2.Account__r != null);

      Case cse = new Case(Subject='Test Case');
      insert cse;

      CSA_Inquiries__c csaInq = new CSA_Inquiries__c(Referral_Bank_Name__c=refAcct1.Id, Case__c=cse.Id);
      insert csaInq;
      csaInq = [Select Id, Referral_Bank_Name__c, ReferralBankName__c from CSA_Inquiries__c where Id=:csaInq.Id];
      System.assertEquals(refAcct1.Account__r.Id, csaInq.ReferralBankName__c);
      
      csaInq.Referral_Bank_Name__c = refAcct2.Id;
      update csaInq;
      csaInq = [Select Id, Referral_Bank_Name__c, ReferralBankName__c from CSA_Inquiries__c where Id=:csaInq.Id];
      System.assertEquals(refAcct2.Account__r.Id, csaInq.ReferralBankName__c);

      Cleansing_Object__c  cleanse = new Cleansing_Object__c(Parent_Referral_Account__c=refAcct1.Id, Name__c='Test');
      insert cleanse;
      cleanse = [Select Id, Parent_Referral_Account__c, ParentReferralAccount__c from Cleansing_Object__c where Id=:cleanse.Id];
      System.assertEquals(refAcct1.Account__r.Id, cleanse.ParentReferralAccount__c);
      
      cleanse.Parent_Referral_Account__c = refAcct2.Id;
      update cleanse;
      cleanse = [Select Id, Parent_Referral_Account__c, ParentReferralAccount__c from Cleansing_Object__c where Id=:cleanse.Id];
      System.assertEquals(refAcct2.Account__r.Id, cleanse.ParentReferralAccount__c);

   } // testAccountLookups
 

} // class SRRTransitionHelperTest