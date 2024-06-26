/* Test methods for the CommissionMethods class.
   
  History
  -------
  02/19/2016 Dan Carmen   Created
  08/29/2016 Dan Carmen   Added to the test to check opp update.
  05/09/2022 Dan Carmen   Update API, change order of record saving
  
 */
@isTest
private class CommissionMethodsTest {

   static testMethod void testCommissionLoad() {
      Account acct1 = new Account(Name='Test 1', AccountNumber='10-TESTREC1');
      Account acct2 = new Account(Name='Test 2', AccountNumber='10-TESTREC2');
      Account acct3 = new Account(Name='Test 3', AccountNumber='10-TESTREC3');
      Account acct4 = new Account(Name='Test 4', AccountNumber='10-TESTREC4');
      Account acct8 = new Account(Name='Test 8', AccountNumber='10-TESTREC8');
      Account acct9 = new Account(Name='Test 9', AccountNumber='10-TESTREC9');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct8,acct9};
      insert accts;

      Opportunity opp1 = new Opportunity(Name='Test1 Opp', AccountId=acct1.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity opp8 = new Opportunity(Name='Test8 Opp', AccountId=acct8.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity opp9 = new Opportunity(Name='Test9 Opp', AccountId=acct9.Id, CloseDate=Date.today(), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp8,opp9};
      insert opps;
      
      
      Referral__c ref1 = new Referral__c(Name='Test1',Account__c=acct1.Id, Referral_Id__c='LTEST1', Selling_Opportunity__c=opp1.Id);
      Referral__c ref2 = new Referral__c(Name='Test2',Account__c=acct2.Id, Referral_Id__c='LTEST2');
      Referral__c[] refs = new Referral__c[]{ref1,ref2};
      insert refs;
      
      CommissionInfo__c comInfo1 = new CommissionInfo__c(NbrOfEmployees__c=6, ActualRevenue__c=100, BranchClientNumber__c=acct1.AccountNumber
                                    ,ClientName__c=acct1.Name, Disposition__c='PND', FedIdNumber__c='10-1234567'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=ref1.Referral_Id__c);
      CommissionInfo__c comInfo2 = new CommissionInfo__c(NbrOfEmployees__c=8, ActualRevenue__c=200, BranchClientNumber__c=acct2.AccountNumber
                                    ,ClientName__c=acct2.Name, Disposition__c='PND', FedIdNumber__c='10-1234568'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=ref2.Referral_Id__c);
      CommissionInfo__c comInfo3 = new CommissionInfo__c(NbrOfEmployees__c=10, ActualRevenue__c=300, BranchClientNumber__c=acct3.AccountNumber
                                    ,ClientName__c=acct3.Name, Disposition__c='PND', FedIdNumber__c='10-1234569'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null);
      CommissionInfo__c comInfo4 = new CommissionInfo__c(NbrOfEmployees__c=12, ActualRevenue__c=400, BranchClientNumber__c=acct4.AccountNumber
                                    ,ClientName__c=acct4.Name, Disposition__c='PND', FedIdNumber__c='10-1234570'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null);
      CommissionInfo__c comInfo5 = new CommissionInfo__c(NbrOfEmployees__c=14, ActualRevenue__c=500, BranchClientNumber__c='10-TESTREC5'
                                    ,ClientName__c='Test 5', Disposition__c='PND', FedIdNumber__c='10-1234571'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null);
      CommissionInfo__c comInfo6 = new CommissionInfo__c(NbrOfEmployees__c=16, ActualRevenue__c=600, BranchClientNumber__c='10-TESTREC6'
                                    ,ClientName__c='Test 6', Disposition__c='PND', FedIdNumber__c='10-1234572'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null);
      CommissionInfo__c comInfo7 = new CommissionInfo__c(NbrOfEmployees__c=16, ActualRevenue__c=600, BranchClientNumber__c=null
                                    ,ClientName__c='Test 7', Disposition__c='PND', FedIdNumber__c='10-1234573'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null);
      CommissionInfo__c comInfo8 = new CommissionInfo__c(NbrOfEmployees__c=17, ActualRevenue__c=800, BranchClientNumber__c=null
                                    ,ClientName__c=acct8.Name, Disposition__c='PND', FedIdNumber__c='10-1234574'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null, OpportunityId__c=opp8.Id);
      CommissionInfo__c comInfo9 = new CommissionInfo__c(NbrOfEmployees__c=18, ActualRevenue__c=900, BranchClientNumber__c=null
                                    ,ClientName__c=acct9.Name, Disposition__c='PND', FedIdNumber__c='10-1234575'
                                    ,MonthSaleReported__c=Date.today().addDays(-7), PendingRunOfPayroll__c=Date.today().addDays(-7)
                                    ,Referral_Id__c=null, OpportunityId__c=opp9.Id);
      CommissionInfo__c[] comInfos = new CommissionInfo__c[]{comInfo1,comInfo2,comInfo3,comInfo4,comInfo5,comInfo6,comInfo7, comInfo8, comInfo9};
      
      Test.StartTest();
      insert comInfos;
      Test.StopTest();
      
      Map<Id,CommissionInfo__c> comInfoMap = new Map<Id,CommissionInfo__c>([Select Id, NbrOfEmployees__c, ActualRevenue__c, BranchClientNumber__c
                                    ,ClientName__c, CreatedAccount__c, CreatedReferral__c, Error__c
                                    ,Disposition__c, FedIdNumber__c
                                    ,MatchedByBrCltNbr__c, MatchedByReferralId__c, MatchedByOppId__c
                                    ,MonthSaleReported__c, Notes__c, PendingRunOfPayroll__c
                                    ,Processed__c, Referral__c, Referral_Id__c, Success__c
                                    ,Referral__r.Id, Referral__r.Referral_Id__c, Referral__r.NbrOfEmployees__c
                                    ,Referral__r.ActualRevenue__c, Referral__r.BranchClientNumber__c, Referral__r.Disposition__c
                                    ,Referral__r.FedIdNumber__c, Referral__r.MonthSaleReported__c, Referral__r.PendingRunOfPayroll__c
                                    ,Referral__r.Account__r.Id
                                    ,Referral__r.Account__r.Name
                                    ,Referral__r.Account__r.AccountNumber
                                    ,Referral__r.Account__r.Federal_ID_Number__c
                                    ,Referral__r.PartnerReferral__r.Id
                                    ,Referral__r.PartnerReferral__r.Company__c
                                    ,Opportunity__r.Id
                                    ,Opportunity__r.Bank_Lead_Id__c
                                from CommissionInfo__c where Id in :comInfos]);

      CommissionInfo__c checkComInfo = comInfoMap.get(comInfo1.Id);
      System.debug('testCommissionLoad checkComInfo1='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(true,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(false,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo1.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo1.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo1.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo1.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo1.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo1.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo1.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(comInfo1.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(acct1.Id,checkComInfo.Referral__r.Account__r.Id);

      //********************

      checkComInfo = comInfoMap.get(comInfo2.Id);
      System.debug('testCommissionLoad checkComInfo2='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(true,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(false,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo2.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo2.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo2.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo2.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo2.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo2.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo2.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(comInfo2.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(acct2.Id,checkComInfo.Referral__r.Account__r.Id);

      //********************

      checkComInfo = comInfoMap.get(comInfo3.Id);
      System.debug('testCommissionLoad checkComInfo3='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(true,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo3.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo3.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo3.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo3.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo3.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo3.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo3.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(true,checkComInfo.Referral_Id__c != null);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(acct3.Id,checkComInfo.Referral__r.Account__r.Id);

      //********************

      checkComInfo = comInfoMap.get(comInfo4.Id);
      System.debug('testCommissionLoad checkComInfo4='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(true,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo4.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo4.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo4.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo4.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo4.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo4.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo4.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(true,checkComInfo.Referral_Id__c != null);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(acct4.Id,checkComInfo.Referral__r.Account__r.Id);

      //********************

      checkComInfo = comInfoMap.get(comInfo5.Id);
      System.debug('testCommissionLoad checkComInfo5='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(true,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo5.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo5.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo5.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo5.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo5.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo5.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo5.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(true,checkComInfo.Referral_Id__c != null);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(comInfo5.ClientName__c,checkComInfo.Referral__r.Account__r.Name);
      System.assertEquals(comInfo5.BranchClientNumber__c,checkComInfo.Referral__r.Account__r.AccountNumber);

      //********************

      checkComInfo = comInfoMap.get(comInfo6.Id);
      System.debug('testCommissionLoad checkComInfo6='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(true,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

      System.assertEquals(comInfo6.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo6.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo6.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo6.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo6.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo6.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo6.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(true,checkComInfo.Referral_Id__c != null);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(comInfo6.ClientName__c,checkComInfo.Referral__r.Account__r.Name);
      System.assertEquals(comInfo6.BranchClientNumber__c,checkComInfo.Referral__r.Account__r.AccountNumber);

      //********************

      checkComInfo = comInfoMap.get(comInfo7.Id);
      System.debug('testCommissionLoad checkComInfo7='+checkComInfo);
      System.assertEquals(false,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(false,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(false,checkComInfo.CreatedReferral__c);
      System.assertEquals(true,checkComInfo.Error__c);

      //********************

      checkComInfo = comInfoMap.get(comInfo8.Id);
      System.debug('testCommissionLoad checkComInfo8='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(true,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);
      
      System.assertEquals(true,checkComInfo.Referral__r.PartnerReferral__r != null);
      System.assertEquals(comInfo8.ClientName__c,checkComInfo.Referral__r.PartnerReferral__r.Company__c);
      System.assertEquals(comInfo8.NbrOfEmployees__c,checkComInfo.Referral__r.NbrOfEmployees__c);
      System.assertEquals(comInfo8.ActualRevenue__c,checkComInfo.Referral__r.ActualRevenue__c);
      System.assertEquals(comInfo8.BranchClientNumber__c,checkComInfo.Referral__r.BranchClientNumber__c);
      System.assertEquals(comInfo8.Disposition__c,checkComInfo.Referral__r.Disposition__c);
      System.assertEquals(comInfo8.FedIdNumber__c,checkComInfo.Referral__r.FedIdNumber__c);
      System.assertEquals(comInfo8.MonthSaleReported__c,checkComInfo.Referral__r.MonthSaleReported__c);
      System.assertEquals(comInfo8.PendingRunOfPayroll__c,checkComInfo.Referral__r.PendingRunOfPayroll__c);
      System.assertEquals(true,checkComInfo.Referral_Id__c != null);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Referral__r.Referral_Id__c);
      System.assertEquals(checkComInfo.Referral_Id__c,checkComInfo.Opportunity__r.Bank_Lead_Id__c);


      //********************

      checkComInfo = comInfoMap.get(comInfo9.Id);
      System.debug('testCommissionLoad checkComInfo9='+checkComInfo);
      System.assertEquals(true,checkComInfo.Success__c);
      System.assertEquals(false,checkComInfo.MatchedByBrCltNbr__c);
      System.assertEquals(false,checkComInfo.MatchedByReferralId__c);
      System.assertEquals(true,checkComInfo.MatchedByOppId__c);
      System.assertEquals(false,checkComInfo.CreatedAccount__c);
      System.assertEquals(true,checkComInfo.CreatedReferral__c);
      System.assertEquals(false,checkComInfo.Error__c);

     

   } // testCommissionLoad
   
} // class CommissionMethodsTest