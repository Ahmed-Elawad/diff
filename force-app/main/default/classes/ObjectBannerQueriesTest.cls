/* 

  History
  -------
  03/22/2022 Dan Carmen         Cleaned up code
  10/12/2023 Carrie Marciano	added code to create banner on Reference Client Retention object

 */
@isTest
public class ObjectBannerQueriesTest {
   @testSetup
   public static void setupData() {
      ObjectBannerAuraServiceTest.setupData();
   } // setupData
    
   static testMethod void testCases() {
      Contact ctct = ObjectBannerAuraServiceTest.getTestCtct();
      Account acct = ObjectBannerAuraServiceTest.getTestAcct();
      Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
      Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
      
      Case[] cases = ObjectBannerQueries.getOpenCasesByContactId(ctct.Id);
      System.assertEquals(2,cases.size());
       
      cases = ObjectBannerQueries.getOpenCasesByAccountId(acct.Id);
      System.assertEquals(2,cases.size());
       
      cases = ObjectBannerQueries.getOpenCasesByReferralAccountId(refAcct.Id);
      System.assertEquals(0,cases.size());
       
      cases = ObjectBannerQueries.getOpenCasesByReferralContactId(refCtct.Id);
      System.assertEquals(2,cases.size());

   } // testCases
    
    @IsTest
    static void testSensitivity() {
       Lead ld = ObjectBannerAuraServiceTest.getTestLd();
 	   system.assert(true, !string.isBlank(ObjectBannerQueries.getSensitivitiesByLeadId(ld.Id))); 
        
    } // testSensitivity 
    
    @isTest
    static void testGetLeadById() {
       Lead ld = ObjectBannerAuraServiceTest.getTestLd();
       Account acct = ObjectBannerAuraServiceTest.getTestAcct();

       Lead result = ObjectBannerQueries.getLeadById(ld.Id);
       system.assertEquals(ld.Id, result.Id);
        
       Boolean exceptionMade = false;
       try {
          // passing in the wrong type of id to get an exception
          result = ObjectBannerQueries.getLeadById(acct.Id);
       } catch (Exception e) {
          exceptionMade = true;
       }
       System.assertEquals(true,exceptionMade);
    } // testGetLeadById
    
    static testMethod void testGetAccountByOppId() {
       Opportunity opp = ObjectBannerAuraServiceTest.getTestOpp();
       Account acct = ObjectBannerAuraServiceTest.getTestAcct();
       
       Account retAcct = ObjectBannerQueries.getAccountByOpportunityId(opp.Id);
       System.assertEquals(acct.Id, retAcct.Id);
        
       Boolean exceptionMade = false;
       try {
          // passing in the wrong type of id to get an exception
          Account retAcct2 = ObjectBannerQueries.getAccountByOpportunityId(acct.Id);
       } catch (Exception e) {
          exceptionMade = true;
       }
       System.assertEquals(true,exceptionMade);
    } // testGetAccountByOppId
    
    @IsTest
    static void getReferralAccountById() {
       Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
       Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
       Referral_Account__c returnRefAcct = ObjectBannerQueries.getReferralAccountById(refAcct.Id);
       System.assertEquals(refAcct.Id, returnRefAcct.Id);
       Boolean exceptionMade = false;
       try {
          // passing in the wrong type of id to get an exception
          returnRefAcct = ObjectBannerQueries.getReferralAccountById(refCtct.Id);
       } catch (Exception e) {
          exceptionMade = true;
       }
       System.assertEquals(true,exceptionMade);
    } // getReferralAccountById
  
    @IsTest
    static void testSensitivityRefAcct() {
        test.startTest();
        Referral_Account__c RefAcct = new Referral_Account__c(Sensitivity_401_k__c = true);
        insert RefAcct;
        Referral_Contact__c RefCtct = new Referral_Contact__c(Sensitivity_FSA__c = true, Referral_Account__c = RefAcct.Id);
        insert RefCtct;

        test.stopTest();
 		system.assert(true, !string.isBlank(ObjectBannerQueries.getSensitivitiesByRefAcctId(RefAcct.Id))); 
       
    } // testSensitivityRefAcct
    
    @IsTest
    static void getReferralContactById() {
       Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
       Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
       Referral_Contact__c returnRefContact = ObjectBannerQueries.getReferralContactById(refCtct.Id);
       System.assertEquals(refCtct.Id, returnRefContact.Id);
        
       Boolean exceptionMade = false;
       try {
          // passing in the wrong type of id to get an exception
          returnRefContact = ObjectBannerQueries.getReferralContactById(refAcct.Id);
       } catch (Exception e) {
          exceptionMade = true;
       }
       System.assertEquals(true,exceptionMade);

    } // getReferralContactById

    @IsTest
    static void getReferralContactsByReferralAccount() {
       Referral_Account__c refAcct = ObjectBannerAuraServiceTest.getTestRefAcct();
       Referral_Contact__c refCtct = ObjectBannerAuraServiceTest.getTestRefCtct();
       List<Referral_Contact__c> returnRefContacts = ObjectBannerQueries.getReferralContactsByReferralAccount(refAcct.Id);

       System.assertEquals(returnRefContacts.size(), 1);
       System.assertEquals(refCtct.Id,returnRefContacts[0].Id);
    } // getReferralContactsByReferralAccount
    
    @IsTest
    static void getOpenRCRByRefClientRetAcctId() {
       Account Acct = ObjectBannerAuraServiceTest.getTestAcctbyName('ACCT1');
       Reference_Client_Retention__c rcr = [Select Id from Reference_Client_Retention__c where Reference_Client_Retention__c.Prospect_Client_Name__c =:Acct.Id LIMIT 1]; 
       List<Reference_Client_Retention__c> returnOpenRCRs = ObjectBannerQueries.getOpenRCRByRefClientRetAcctId(rcr.Id);

       System.assertEquals(returnOpenRCRs.size(), 1);
       
    } // getOpenRCRByRefClientRetAcctId
    
    @IsTest
    static void getTotalRCRByRefClientRetAcctId() {
       Account Acct = ObjectBannerAuraServiceTest.getTestAcctbyName('ACCT1');
       Reference_Client_Retention__c rcr = [Select Id from Reference_Client_Retention__c where Reference_Client_Retention__c.Prospect_Client_Name__c =:Acct.Id LIMIT 1]; 
       List<Reference_Client_Retention__c> returnTotalRCRs = ObjectBannerQueries.getTotalRCRByRefClientRetAcctId(rcr.Id);

       System.assertEquals(returnTotalRCRs.size(), 2);
    } // getTotalRCRByRefClientRetAcctId
    
} // class ObjectBannerQueriesTest