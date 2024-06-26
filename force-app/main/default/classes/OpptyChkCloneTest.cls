/* 
 * Test methods for OpptyChkClone
 *
 * History
 * -------
   06/16/2017 Dan Carmen   Created
   
 *
 */
@isTest
private class OpptyChkCloneTest {

   static testMethod void testClonedOpps() {
      // setup triggers
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'OpptyBefore', true, false, new String[]{'OpptyChkClone'},setupClasses);
      TriggerSetup__c trigSetup2 = TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'OpptyChkClone'},setupClasses);
      insert setupClasses;
      
      Account acct1 = new Account(Name='Test Acct1');
      Account acct2 = new Account(Name='Test Acct2');
      Account acct3 = new Account(Name='Test Acct3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      Contact ctct1 = new Contact(AccountId=acct1.Id, LastName='Last1');
      Contact ctct2 = new Contact(AccountId=acct2.Id, LastName='Last1');
      Contact ctct3 = new Contact(AccountId=acct3.Id, LastName='Last1');
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3};
      insert ctcts;
      
      Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, StageName='Pending', CloseDate=Date.today());
      insert opp1;
      
      OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id, OpportunityId=opp1.Id, IsPrimary=true);
      insert ocr1;
      
      PartnerReferral__c partRef = new PartnerReferral__c(Contact__c=ctct1.Id, Account__c=acct1.Id);
      insert partRef;
      partRef = [Select Id, Name, Contact__c, Account__c from PartnerReferral__c where Id=:partRef.Id];
      
      Referral__c ref1 = new Referral__c(Name='Test Ref', Referral_Id__c=partRef.Name, Account__c=acct1.Id, SourceContact__c=ctct1.Id
                                       ,PartnerReferral__c=partRef.Id, Selling_Opportunity__c=opp1.Id);
      insert ref1;
                
      opp1.ReferralLookup__c = ref1.Id;
      opp1.Bank_Lead_ID__c = ref1.Referral_Id__c;
      update opp1;
      
      // create cloned opps
      Test.startTest();
      Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, StageName='Pending', CloseDate=Date.today(), OpportunityId__c=opp1.Id);
      Opportunity opp3 = new Opportunity(Name='Opp2', AccountId=acct3.Id, StageName='Pending', CloseDate=Date.today(), OpportunityId__c=opp1.Id);
      Opportunity[] opps = new Opportunity[]{opp2,opp3};
      insert opps;
      
      Test.stopTest();
      System.assertEquals(3,[select count() from Referral__c]);
      
      Referral__c ref2 = [Select Id, Name, Referral_Id__c, Account__c, SourceContact__c, PartnerReferral__c, Selling_Opportunity__c from Referral__c where Selling_Opportunity__c=:opp2.Id];
      System.assertEquals(ref1.Referral_Id__c, ref2.Referral_Id__c);
      System.assertEquals(acct2.Id, ref2.Account__c);
      System.assertEquals(partRef.Id, ref2.PartnerReferral__c);
      System.assertEquals(null, ref2.SourceContact__c);
      
      Referral__c ref3 = [Select Id, Name, Referral_Id__c, Account__c, SourceContact__c, PartnerReferral__c, Selling_Opportunity__c from Referral__c where Selling_Opportunity__c=:opp3.Id];
      System.assertEquals(ref1.Referral_Id__c, ref3.Referral_Id__c);
      System.assertEquals(acct3.Id, ref3.Account__c);
      System.assertEquals(partRef.Id, ref3.PartnerReferral__c);
      System.assertEquals(null, ref3.SourceContact__c);
      
      delete ref3;
      
      OpportunityContactRole ocr3 = new OpportunityContactRole(ContactId=ctct3.Id, OpportunityId=opp3.Id, IsPrimary=true);
      insert ocr3;

      opp3.CheckIfCloned__c = true;
      update opp3;
      
      ref3 = [Select Id, Name, Referral_Id__c, Account__c, SourceContact__c, PartnerReferral__c, Selling_Opportunity__c from Referral__c where Selling_Opportunity__c=:opp3.Id];
      System.assertEquals(ref1.Referral_Id__c, ref3.Referral_Id__c);
      System.assertEquals(acct3.Id, ref3.Account__c);
      System.assertEquals(partRef.Id, ref3.PartnerReferral__c);
      System.assertEquals(ctct3.Id, ref3.SourceContact__c);
      
      opp3 = [Select Id, Name, CheckIfCloned__c from Opportunity where Id=:opp3.Id];
      System.assertEquals(false, opp3.CheckIfCloned__c);
      
      
   } // testClonedOpps
   
} // class OpptyChkCloneTest