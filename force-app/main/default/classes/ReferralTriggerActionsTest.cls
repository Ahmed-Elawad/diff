/* 
 * Test methods for the ReferralTriggerActions class
 *
 * History
 * -------
   01/27/2016 Dan Carmen      Created
   01/26/2017 Dan Carmen      Ability to update from the referral to the opportunity
   11/01/2018 Dan Carmen      Add the LatestReferral__c flag
   04/30/2021 Pujitha Madamanchi Add inbound opp test method
   10/25/2023 Dan Carmen       Update call to ReferralMethods.updateDSAOpptyRefJoin method
   03/21/2024 Pujitha Madamanchi APR0165167 - Update Referral Inbound_Opportunity__c logic


 */
@isTest
private class ReferralTriggerActionsTest {

   static testMethod void testAcctUpdateFromRef() {
      Account acct1 = new Account(Name='Test Acct1');
      Account acct2 = new Account(Name='Test Acct2',AccountNumber='11-TEST1');
      Account acct3 = new Account(Name='Test Acct3',Federal_Id_Number__c='11-1234567');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Referral__c ref1 = new Referral__c(Name='Opp1',Account__c=acct1.Id);
      Referral__c ref2 = new Referral__c(Name='Opp2',Account__c=acct2.Id);
      Referral__c ref3 = new Referral__c(Name='Opp3',Account__c=acct3.Id);
      Referral__c[] refs = new Referral__c[]{ref1,ref2,ref3};
      insert refs;

      ref1.FedIdNumber__c = '12-1234567';
      ref1.BranchClientNumber__c = '12-TEST2';
      ref2.FedIdNumber__c = '13-1234567';
      ref2.BranchClientNumber__c = '13-TEST3';
      ref3.FedIdNumber__c = '14-1234567';
      ref3.BranchClientNumber__c = '14-TEST4';
      ReferralTriggerActions.SKIP_TRIGGER = false;
      update refs;
      
      acct1 = [Select Id, Name, AccountNumber, Federal_Id_Number__c from Account where Id=:acct1.Id];
      System.assertEquals(ref1.FedIdNumber__c, acct1.Federal_Id_Number__c);
      System.assertEquals(ref1.BranchClientNumber__c, acct1.AccountNumber);
      
      acct2 = [Select Id, Name, AccountNumber, Federal_Id_Number__c from Account where Id=:acct2.Id];
      System.assertEquals(ref2.FedIdNumber__c, acct2.Federal_Id_Number__c);
      System.assertEquals('11-TEST1', acct2.AccountNumber);

      acct3 = [Select Id, Name, AccountNumber, Federal_Id_Number__c from Account where Id=:acct3.Id];
      System.assertEquals('11-1234567', acct3.Federal_Id_Number__c);
      System.assertEquals(ref3.BranchClientNumber__c, acct3.AccountNumber);
      
   } // testAcctUpdateFromRef
   
   static testMethod void testOppUpdateFromRef() {
      
      Opportunity opp = new Opportunity(Name='Test Opp', NSS_Source__c='Inbound', StageName='Pending', CloseDate=Date.today().addDays(7));
      insert opp;

      Referral__c ref = new Referral__c(Name='Test Ref', Referral_Id__c='TestId');
      ref.NbrOfEmployees__c = 7;
      ref.ActualRevenue__c = 777;
      ref.BranchClientNumber__c = '01-DAN1';
      ref.Disposition__c = 'SLD';
      ref.FedIdNumber__c = '12-4334567';
      ref.MonthSaleReported__c = Date.today().addDays(-7);
      ref.PendingRunOfPayroll__c = Date.today().addDays(-7);
      insert ref;
      
      ref.Selling_Opportunity__c = opp.Id;
      
      ReferralTriggerActions.SKIP_TRIGGER = false;
      update ref;
       
      opp = [Select Id, Name, ReferralLookup__c, Of_Employees__c
                   ,Actual_Revenue__c, BranchClientNumber__c, Disposition__c
                   ,FedIdNumber__c, Month_Sale_Reported__c, Pending_Run_Of_Payroll__c
               From Opportunity
              Where Id=:opp.Id ORDER BY CreatedDate ASC];

      System.assertEquals(ref.Id, opp.ReferralLookup__c);
      System.assertEquals(ref.NbrOfEmployees__c, opp.Of_Employees__c);
      System.assertEquals(ref.ActualRevenue__c, opp.Actual_Revenue__c);
      System.assertEquals(ref.BranchClientNumber__c, opp.BranchClientNumber__c);
      System.assertEquals(ref.Disposition__c, opp.Disposition__c);
      System.assertEquals(ref.FedIdNumber__c, opp.FedIdNumber__c);
      System.assertEquals(ref.MonthSaleReported__c, opp.Month_Sale_Reported__c);
      System.assertEquals(ref.PendingRunOfPayroll__c, opp.Pending_Run_Of_Payroll__c);
      
   } // testOppUpdateFromRef

   static testMethod void testLatestReferral() {
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Lead ld = new Lead(LastName='TestLast', Company='Test Lead');
      insert ld;
      
      Referral__c refAcct1 = new Referral__c(Name='refAcct1', Account__c=acct.Id);
      Referral__c refLead1 = new Referral__c(Name='refLead1', SourceLead__c=ld.Id);
      Referral__c[] refs = new Referral__c[]{refAcct1,refLead1};
      insert refs;
      
      Map<Id,Referral__c> refMap = new Map<Id,Referral__c>([Select Id, Name, LatestReferral__c from Referral__c]);
      System.assertEquals(true,refMap.get(refAcct1.Id).LatestReferral__c);
      System.assertEquals(true,refMap.get(refLead1.Id).LatestReferral__c);
      
      Referral__c refAcct2 = new Referral__c(Name='refAcct2', Account__c=acct.Id);
      Referral__c refLead2 = new Referral__c(Name='refLead2', SourceLead__c=ld.Id);
      refs = new Referral__c[]{refAcct2,refLead2};
      ReferralTriggerActions.SKIP_TRIGGER = false;
      insert refs;
      
      refMap = new Map<Id,Referral__c>([Select Id, Name, LatestReferral__c from Referral__c]);
      System.assertEquals(false,refMap.get(refAcct1.Id).LatestReferral__c);
      System.assertEquals(false,refMap.get(refLead1.Id).LatestReferral__c);
      System.assertEquals(true,refMap.get(refAcct2.Id).LatestReferral__c);
      System.assertEquals(true,refMap.get(refLead2.Id).LatestReferral__c);
      
   } // testLatestReferral
    
     static testMethod void testApprovedDate() {
      Account acct1 = new Account(Name='Test Acct1');
      insert acct1;
      
      Referral_Partner__c refPart1 = new Referral_Partner__c(Name='Payroll', Partner_Type__c='Internal Referral', NSS_Source__c='Inbound');
      insert refPart1;

      Referral__c ref1 = new Referral__c(Name='Ref1', Account__c=acct1.Id, Referral_Partner__c = refPart1.Id, Status__c = 'Approved');
      insert ref1;
      
      ref1.Status__c = 'Approved';
      update ref1;
         
      Referral__c ref = [Select Id, Name, Status__c, Referral_Approved_Date__c, Referral_Approved_Timeframe__c from Referral__c];
      System.assertEquals(true,ref.Referral_Approved_date__c!=null);
      System.assertEquals(true,ref.Referral_Approved_Timeframe__c!=null);          
    } // testApprovedDate 
    
    @isTest
    static void testUpdateDSAOppty(){
        ReferralMethodsTest.testDsaOppLinking();
    } // testUpdateDSAOppty
    
     static testMethod void testInboundOpp() {

      Account acct1 = new Account(Name='Test Acct1');
      insert acct1;
      
      Opportunity opp = new Opportunity(Name='Test Opp', NSS_Source__c='Inbound', AccountId = acct1.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
      Opportunity opp1 = new Opportunity(Name='Test Opp1', NSS_Source__c='Inbound', AccountId = acct1.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
      Opportunity[] opps = new Opportunity[]{opp,opp1};
      insert opps;

      Referral_Partner__c refPart = new Referral_Partner__c(Name='Payroll', Partner_Type__c='NSS Referral', NSS_Source__c='Inbound', Referral_Product_Type__c='Payroll');
      Referral_Partner__c refPart1 = new Referral_Partner__c(Name='Payroll', Partner_Type__c='Internal Referral', NSS_Source__c='Inbound');
      Referral_Partner__c[] refParts = new Referral_Partner__c[]{refPart,refPart1};
      insert refParts;
      
      Referral__c ref = new Referral__c(Name='Test Ref', Referral_Id__c='TestId', Referral_Partner__c = refPart.Id, Account__c=acct1.Id);
      ref.NbrOfEmployees__c = 7;
      ref.ActualRevenue__c = 777;
      ref.BranchClientNumber__c = '01-DAN1';
      ref.Disposition__c = 'SLD';
      ref.FedIdNumber__c = '12-4334567';
      ref.MonthSaleReported__c = Date.today().addDays(-7);
      ref.PendingRunOfPayroll__c = Date.today().addDays(-7);
      ref.Primary__c = true;
      insert ref;

      ref.Selling_Opportunity__c = opp.Id;
      Referral__c[] updateRefs = new Referral__c[]{ref};
      ReferralTriggerActions.SKIP_TRIGGER = false;
      update updateRefs;
       
      opps = [Select Id, Name, ReferralLookup__c, Of_Employees__c
                   ,Actual_Revenue__c, BranchClientNumber__c, Disposition__c
                   ,FedIdNumber__c, Month_Sale_Reported__c, Pending_Run_Of_Payroll__c
               From Opportunity
              Where AccountId=:acct1.Id ORDER BY CreatedDate ASC];

      System.assertEquals(ref.Id, opps[0].ReferralLookup__c);
      System.assertEquals(ref.NbrOfEmployees__c, opps[0].Of_Employees__c);
      System.assertEquals(ref.ActualRevenue__c, opps[0].Actual_Revenue__c);
      System.assertEquals(ref.BranchClientNumber__c, opps[0].BranchClientNumber__c);
      System.assertEquals(ref.Disposition__c, opps[0].Disposition__c);
      System.assertEquals(ref.FedIdNumber__c, opps[0].FedIdNumber__c);
      System.assertEquals(ref.MonthSaleReported__c, opps[0].Month_Sale_Reported__c);
      System.assertEquals(ref.PendingRunOfPayroll__c, opps[0].Pending_Run_Of_Payroll__c);

      Referral__c ref1 = new Referral__c(Name='Ref1', Account__c=acct1.Id, Referral_Partner__c = refPart1.Id);
     updateRefs = new Referral__c[]{ref1};
      ReferralTriggerActions.SKIP_TRIGGER = false;
      insert updateRefs;
       
      Map<Id,Referral__c> refMap = new Map<Id,Referral__c>([Select Id, Name, Inbound_Opportunity__c from Referral__c]);
      System.assertEquals(opp.Id,refMap.get(ref1.Id).Inbound_Opportunity__c);
      
     
   } // testInboundOpp
} // class ReferralTriggerActionsTest