/* 
 * Test Methods for the ProspectOwnershipMethods class
 *
 * History
 * -------
 * 10/11/2013 Dan Carmen   Created
   01/08/2016 Dan Carmen      Set the supervisor when the opportunity is set

 *
 */
@isTest
public class ProspectOwnershipTest {

   public static Contact ctct = null;
   public static Account acct = null;
   public static Map<Id,List<Prospect_Ownership__c>> acctOwnerMap = null;

   public static void setupAcctCtct() {
      // load the settings
      List<LifeOfLeadSettings__c> ls = Test.loadData(LifeOfLeadSettings__c.sObjectType, 'lifeOfLeadSettings');
      acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      ctct = new Contact(AccountId=acct.Id, FirstName='Sally',LastName='Test');
      insert ctct;
      // reselect the account
      acct = ReferralQueries.selectAcct(acct.Id);
   } // setupAcctCtct

   private static void runProcess(String stageName, Account p_acct, Contact p_ctct, Id ctctId, User usr, String nssTeam, String nssSource) {   
      ProspectOwnershipMethods.initializeSaveObjects();
      ProspectOwnershipMethods.checkAccountOwnership(stageName, true, p_acct, p_ctct, ctctId, (AccountTeamMember[])null, usr, null, nssTeam, nssSource, (acctOwnerMap != null ? acctOwnerMap.get(p_acct.Id) : null));
      ProspectOwnershipMethods.checkForSaves();
      // reselect the account
      acct = ReferralQueries.selectAcct(acct.Id);
      // reselect ownership records
      acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(new Set<Id>{acct.Id}, false, null,null);
   } // runProcess
   
   // test inbound prospecting with existing outbound not interested/wash.
   // test inbound lockout with existing outbound workable that was transferred (no commission dates).

   // Verify the account attributes.
   public static void verifyAccount(String testName, Account p_acct, Boolean outbound, Boolean inbound, Integer nbrATM, Id atmUserId) {
      System.debug('verifyAccount testName='+testName);
      // verify the account fields
      System.assertEquals(outbound,p_acct.AssignedToOutboundNSR__c);
      System.assertEquals(inbound,p_acct.AssignedToInboundNSR__c);
      // should be 1 account team member
      System.assertEquals(nbrATM,p_acct.AccountTeamMembers.size());
      if (atmUserId != null) {
         System.assertEquals(atmUserId,p_acct.AccountTeamMembers[0].UserId);
      }

   } // verifyAccount

   // Verify the Prospect_Ownership__c attributes.
   public static void checkOwnership(String testName, Prospect_Ownership__c po, String nssTeam, String nssSource, String status, Boolean hasProspectingStart
                                       ,Boolean hasLockoutStart, Boolean hasWorkableStart, Boolean hasCommission, Boolean hasNFI, Boolean hasEndDate
                                       ,Id nsrId) {
      checkOwnership(testName, po, nssTeam, nssSource, status, hasProspectingStart
                                       ,hasLockoutStart, hasWorkableStart, hasCommission, hasNFI, hasEndDate, 0 ,nsrId);
  } // checkOwnership

   public static void checkOwnership(String testName, Prospect_Ownership__c po, String nssTeam, String nssSource, String status, Boolean hasProspectingStart
                                       ,Boolean hasLockoutStart, Boolean hasWorkableStart, Boolean hasCommission, Boolean hasNFI, Boolean hasEndDate
                                       ,Integer addToCommEnd
                                       ,Id nsrId) {
      
      // to account for the status not existing in the LifeOfLeadSettings - so we can get the correct number of commission days
      String originalStatus = po.Ownership_Status__c;
      System.debug('checkOwnership testName='+testName+' originalStatus='+originalStatus);
      if (hasCommission) {
         // to get the commission dates
         po.Ownership_Status__c = ProspectOwnershipMethods.STAGE_LOCKOUT;
      }
      //if (po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_COMMISSION) {
      //   po.Ownership_Status__c = ProspectOwnershipMethods.STAGE_LOCKOUT;
      //} else if (hasEndDate && hasLockoutStart && hasCommission && po.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED) {
      //   po.Ownership_Status__c = ProspectOwnershipMethods.STAGE_LOCKOUT;
      //}
      LifeOfLeadSettings__c lols = ProspectOwnershipMethods.getSetting(po);
      po.Ownership_Status__c = originalStatus;
      System.debug('checkOwnership Ownership_Status__c='+po.Ownership_Status__c);
      
      System.assertEquals(nssTeam,po.NSS_Team__c);
      System.assertEquals(nssSource,po.NSS_Source__c);
      System.assertEquals(status,po.Ownership_Status__c);
      System.assertEquals(true,(po.StartDate__c == Date.today() || po.StartDate__c == Date.today().addDays(-2)));
      System.assertEquals((hasEndDate ? Date.today() : null), po.EndDate__c);
      System.assertEquals((hasProspectingStart ? Date.today() : null), po.ProspectingStart__c);
      System.assertEquals((hasProspectingStart && (hasEndDate || hasLockoutStart) ? Date.today() : null),po.ProspectingEnd__c);
      System.assertEquals((hasLockoutStart ? Date.today() : null), po.LockoutStart__c);
      System.assertEquals((hasLockoutStart && (hasEndDate || hasWorkableStart) ? Date.today() : null),po.LockoutEnd__c);
      System.assertEquals((hasWorkableStart ? Date.today() : null), po.WorkableStart__c);
      System.assertEquals((hasWorkableStart && hasEndDate ? Date.today() : null), po.WorkableEnd__c);
      System.assertEquals((hasCommission ? Date.today() : null), po.CommissionStart__c);
      System.assertEquals((hasCommission ? Date.today().addDays(lols.NumComDays__c.intValue()+addToCommEnd) : null), po.CommissionEnd__c);
      System.assertEquals((hasNFI ? Date.today() : null), po.NFI_WashStart__c);
      System.assertEquals((hasNFI && hasEndDate ? Date.today() : null), po.NFI_WashEnd__c);
      System.assertEquals(nsrId, po.NSR_Name__c);

   } // checkOwnership
   
/*
   // Test inbound prospecting -> lockout -> expired 
   static testMethod void testInboundLifeOfLead() {
      setupAcctCtct();
      
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);
      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testInboundLifeOfLead check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);

      // verify the account fields
      verifyAccount('testInboundLifeOfLead checkAccount1', acct, false, true, 1, inboundNSRs[0].Id);

      // change to Lockout
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // verify 1 ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testInboundLifeOfLead check2', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,true  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testInboundLifeOfLead checkAccount2', acct, false, true, 0, null);
   } // testInboundLifeOfLead
   
   // Test outbound prospecting -> lockout -> workable 
   static testMethod void testOutboundLifeOfLead() {
      setupAcctCtct();
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testOutboundLifeOfLead check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutboundLifeOfLead checkAccount1', acct, true, false, 1, outboundNSRs[0].Id);

      // change to Lockout
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // verify 1 ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testOutboundLifeOfLead check2', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,true  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutboundLifeOfLead checkAccount2', acct, true, false, 0, null);

   } // testOutboundLifeOfLead
   
   // Test outbound prospecting with existing inbound prospecting. 
   static testMethod void testOutProsInboundPros() {
      setupAcctCtct();
      
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testOutProsInboundPros check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutProsInboundPros checkAccount1', acct, false, true, 1, inboundNSRs[0].Id);

      // try to create an outbound prospecting record
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should still be just one inbound ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testOutProsInboundPros check2', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutProsInboundPros checkAccount2', acct, false, true, 1, inboundNSRs[0].Id);

   } // testOutProsInboundPros
   
   
   // Test outbound prospecting with existing inbound lockout.
   static testMethod void testOutProsInboundLockout() {
      setupAcctCtct();
      
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testOutProsInboundLockout check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutProsInboundLockout checkAccount1', acct, false, true, 0, null);

      // try to create an outbound prospecting record
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should still be just one inbound ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testOutProsInboundLockout check2', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      // verify the account fields
      verifyAccount('testOutProsInboundLockout checkAccount2', acct, false, true, 0, null);

   } // testOutProsInboundLockout
   
   // Test outbound lockout with existing inbound prospecting. 
   static testMethod void testOutLockoutInboundProspect() {
      setupAcctCtct();
      
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testOutLockoutInboundProspect check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);

      // verify the account fields
      verifyAccount('testOutLockoutInboundProspect checkAccount1', acct, false, true, 1, inboundNSRs[0].Id);

      // try to create an outbound prospecting record
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should still be just one inbound ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testOutLockoutInboundProspect check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);

      // verify the account fields
      verifyAccount('testOutLockoutInboundProspect checkAccount2', acct, false, true, 1, inboundNSRs[0].Id);

   } // testOutLockoutInboundProspect
   
   // Test outbound lockout with existing inbound lockout.
   static testMethod void testOutLockoutInboundLockout() {
   	setupAcctCtct();

      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testInProsOutPros check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);

      // verify the account fields
      verifyAccount('testOutLockoutInboundLockout checkAccount1', acct, false, true, 0, null);

      // try to create an outbound prospecting record
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should still be just one inbound ownership record
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testInProsOutPros check2', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);

      // verify the account fields
      verifyAccount('testOutLockoutInboundLockout checkAccount2', acct, false, true, 0, null);

   } // testOutLockoutInboundLockout
*/

   // test inbound prospecting with existing outbound prospecting.
   static testMethod void testInProsOutPros() {
   	setupAcctCtct();
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testInProsOutPros check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
                                       
      po.StartDate__c = Date.today().addDays(-2);
      update po;


      verifyAccount('testInProsOutPros checkAccount1', acct, true, false, 1, outboundNSRs[0].Id);

      // create an inbound prospecting record
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // should be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      Boolean inboundFound = false;
      Boolean outboundFound = false;
      
      for (Prospect_Ownership__c checkPo : ownerList) {
      	System.debug('testInProsOutPros checkPo='+checkPo);
      	if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
            System.debug('testInProsOutPros inboundFound');
            inboundFound = true;
            checkOwnership('testInProsOutPros checkForInbound', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
      	} else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
            System.debug('testInProsOutPros outboundFound');
            outboundFound = true;
            checkOwnership('testInProsOutPros checkForOutbound', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_EXPIRED
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,true // end date
                                       ,outboundNSRs[0].Id);
      	}
      } // for (Prospect_Ownership__c checkPo
      
      // verify inbound and outbound are found
      System.assertEquals(true,inboundFound);
      System.assertEquals(true,outboundFound);

      verifyAccount('testInProsOutPros checkAccount2', acct, false, true, 1, inboundNSRs[0].Id);


   } // testOutLockoutInboundLockout
/*
   // test inbound prospecting with existing outbound lockout - then move inbound to lockout
   static testMethod void testInProsOutLockout() {
      setupAcctCtct();
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testInProsOutLockout checkoutboundOwnership', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);


      verifyAccount('testInProsOutPros checkAccount1', acct, true, false, 0, null);

      // create an inbound prospecting record
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // should still be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      Boolean inboundFound = false;
      Boolean outboundFound = false;
      
      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testInProsOutLockout checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
            System.debug('testInProsOutLockout inboundFound');
            inboundFound = true;
            checkOwnership('testInProsOutLockout checkForInbound', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
            System.debug('testInProsOutLockout outboundFound');
            outboundFound = true;
            checkOwnership('testInProsOutLockout checkForOutbound', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      
      // verify inbound and outbound are found
      System.assertEquals(true,inboundFound);
      System.assertEquals(true,outboundFound);

      // should have both inbound and outbound ownership here
      verifyAccount('testInProsOutLockout checkAccount2', acct, true, true, 1, inboundNSRs[0].Id);
      
      // change the inbound to lockout - should end date inbound and leave outbound
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // should still be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      inboundFound = false;
      outboundFound = false;

      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testInProsOutLockout checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
            System.debug('testInProsOutLockout inboundFound');
            inboundFound = true;
            checkOwnership('testInProsOutLockout checkForInbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_COMMISSION
                                       ,true  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,true // end date
                                       ,inboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
            System.debug('testInProsOutLockout outboundFound');
            outboundFound = true;
            checkOwnership('testInProsOutLockout checkForOutbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      
      // verify inbound and outbound are found
      System.assertEquals(true,inboundFound);
      System.assertEquals(true,outboundFound);

      // should have both inbound and outbound ownership here
      verifyAccount('testInProsOutLockout checkAccount2', acct, true, false, 0, null);

   } // testInProsOutLockout

   // test inbound prospecting with existing outbound workable - then move inbound to lockout
   static testMethod void testInLockOutWorkable() {
      setupAcctCtct();
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      // create a lockout record to get the commission period set
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);
      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      // change the record to workable
      ProspectOwnershipMethods.initializeSaveObjects();
      ProspectOwnershipMethods.setStageExitInfo(po, acct, ctct, null, null, false, false, false);
      po.Ownership_Status__c = ProspectOwnershipMethods.STAGE_WORKABLE;
      ProspectOwnershipMethods.setStageEntryInfo(po, acct, ctct, null, null, false, false);
      ProspectOwnershipMethods.checkForSaves();
      
      // reselct the acctOwnerMap to have latest values
      acctOwnerMap = ProspectOwnershipMethods.getAcctOwnerMap(new Set<Id>{acct.Id}, false, null,null);
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      po = ownerList[0];
      checkOwnership('testInLockOutWorkable check1', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_WORKABLE
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,true // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);


      verifyAccount('testInLockOutWorkable checkAccount1', acct, true, false, 0, null);

      
      // create an inbound prospecting record
      User[] inboundNSRs = ProspectOwnershipMethodsTest.getInboundNSRs(1);
      
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);
      // should be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      Boolean inboundFound = false;
      Boolean outboundFound = false;
      
      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testInLockOutWorkable checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
            System.debug('testInLockOutWorkable inboundFound');
            inboundFound = true;
            checkOwnership('testInLockOutWorkable checkForInbound1', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
            System.debug('testInLockOutWorkable outboundFound');
            outboundFound = true;
            // workable stays open until inbound goes to lockout - so commission days can be calculated
            checkOwnership('testInLockOutWorkable checkForOutbound1', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_WORKABLE
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,true // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,0
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      verifyAccount('testInLockOutWorkable checkAccount2', acct, true, true, 2, null);

      // verify inbound and outbound are found
      System.assertEquals(true,inboundFound);
      System.assertEquals(true,outboundFound);

      // move to lockout
      System.debug('before error');
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, inboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND);

      // should be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      inboundFound = false;
      outboundFound = false;
      
      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testInLockOutWorkable checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_INBOUND) {
            System.debug('testInLockOutWorkable inboundFound');
            inboundFound = true;
            checkOwnership('testInLockOutWorkable checkForInbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_INBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,true  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,inboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND) {
            System.debug('testInLockOutWorkable outboundFound');
            outboundFound = true;
            // 90 days should be added onto the commission date
            checkOwnership('testInLockOutWorkable checkForOutbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_EXPIRED
                                       ,false  // prospecting
                                       ,true // lockout
                                       ,true // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,true // end date
                                       ,90
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      
      verifyAccount('testInLockOutWorkable checkAccount3', acct, false, true, 0, null);

      // verify inbound and outbound are found
      System.assertEquals(true,inboundFound);
      System.assertEquals(true,outboundFound);

   } // testInLockOutWorkable

*/
   // test outbound not interested, then a prosecting, then a lockout.
   static testMethod void testOutNoInterestLockout() {
      setupAcctCtct();
      
      User[] outboundNSRs = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      runProcess(ProspectOwnershipMethods.STAGE_NO_INTEREST, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // verify 1 ownership record
      List<Prospect_Ownership__c> ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(1,ownerList.size());
      // verify the record
      Prospect_Ownership__c po = ownerList[0];
      checkOwnership('testOutNoInterestLockout checkoutboundOwnership', po, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_NO_INTEREST
                                       ,false  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,true // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
      po.StartDate__c = Date.today().addDays(-2);

      verifyAccount('testOutNoInterestLockout checkAccount1', acct, true, false, 0, null);

      System.debug('testOutNoInterestLockout before STAGE_PROSPECTING');
      // Create a prospecting record - should end the previous record.
      runProcess(ProspectOwnershipMethods.STAGE_PROSPECTING, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      
      Boolean expiredFound = false;
      Boolean activeFound = false;

      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testOutNoInterestLockout checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND && checkPo.Ownership_Status__c == ProspectOwnershipMethods.STAGE_PROSPECTING) {
            System.debug('testOutNoInterestLockout activeFound');
            activeFound = true;
            checkOwnership('testOutNoInterestLockout checkForInbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_PROSPECTING
                                       ,true  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND && checkPo.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED) {
            System.debug('testOutNoInterestLockout expiredFound');
            expiredFound = true;
            // 90 days should be added onto the commission date
            checkOwnership('testOutNoInterestLockout checkForOutbound2', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_EXPIRED
                                       ,false  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,true // nfi/wash
                                       ,true // end date
                                       ,0
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      
      verifyAccount('testOutNoInterestLockout checkAccount2', acct, true, false, 1, outboundNSRs[0].Id);

      // verify inbound and outbound are found
      System.assertEquals(true,activeFound);
      System.assertEquals(true,expiredFound);

      // Move to Lockout
      runProcess(ProspectOwnershipMethods.STAGE_LOCKOUT, acct, null, ctct.Id, outboundNSRs[0], UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND);

      // should still be 2 ownership records
      ownerList = acctOwnerMap.get(acct.Id);
      System.assertEquals(2,ownerList.size());
      // verify the records
      
      expiredFound = false;
      activeFound = false;

      for (Prospect_Ownership__c checkPo : ownerList) {
         System.debug('testOutNoInterestLockout checkPo='+checkPo);
         if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND && checkPo.Ownership_Status__c == ProspectOwnershipMethods.STAGE_LOCKOUT) {
            System.debug('testOutNoInterestLockout activeFound');
            activeFound = true;
            checkOwnership('testOutNoInterestLockout checkForInbound3', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_LOCKOUT
                                       ,true  // prospecting
                                       ,true // lockout
                                       ,false // workable
                                       ,true // commission
                                       ,false // nfi/wash
                                       ,false // end date
                                       ,outboundNSRs[0].Id);
         } else if (checkPo.NSS_Source__c == ProspectOwnershipMethods.NSS_OUTBOUND && checkPo.Ownership_Status__c == ProspectOwnershipMethods.STAGE_EXPIRED) {
            System.debug('testOutNoInterestLockout expiredFound');
            expiredFound = true;
            // 90 days should be added onto the commission date
            checkOwnership('testOutNoInterestLockout checkForOutbound3', checkPo, UserHelper.SO_CORE, ProspectOwnershipMethods.NSS_OUTBOUND, ProspectOwnershipMethods.STAGE_EXPIRED
                                       ,false  // prospecting
                                       ,false // lockout
                                       ,false // workable
                                       ,false // commission
                                       ,true // nfi/wash
                                       ,true // end date
                                       ,0
                                       ,outboundNSRs[0].Id);
         }
      } // for (Prospect_Ownership__c checkPo
      
      verifyAccount('testOutNoInterestLockout checkAccount3', acct, true, false, 0, null);

      // verify inbound and outbound are found
      System.assertEquals(true,activeFound);
      System.assertEquals(true,expiredFound);

   } // testOutNoInterestLockout
/*
   static testMethod void testProspectOwnershipBeforeTrigger() {
      Prospect_Ownership__c po = new Prospect_Ownership__c(Ownership_Status__c='Prospecting', LastVerified__c=DateTime.now());
      insert po;
      
      po.Ownership_Status__c = 'Lockout';
      update po;
      
      po = [Select Id, Ownership_Status__c, LastVerified__c from Prospect_Ownership__c where Id=:po.Id];
      System.assertEquals('Lockout',po.Ownership_Status__c);
      System.assertEquals(null,po.LastVerified__c);
      
   } // testProspectOwnershipBeforeTrigger

   static testMethod void testSetSupervisor() {
      User testUser = [Select Id, Name, ManagerId from User where IsActive=true and ManagerId != null and Manager.IsActive=true limit 1];
      Prospect_Ownership__c po = new Prospect_Ownership__c(NSR_Name__c=testUser.Id);
      insert po;
      po = [Select Id, NSR_Name__c, NSRSupervisor__c from Prospect_Ownership__c where Id=:po.Id];
      System.assertEquals(null,po.NSRSupervisor__c);
      
      Opportunity opp = new Opportunity(Name='Test Opp',StageName='Pending',CloseDate=Date.today());
      insert opp;
      
      po.Opportunity__c = opp.Id;
      update po;

      po = [Select Id, NSR_Name__c, NSRSupervisor__c from Prospect_Ownership__c where Id=:po.Id];
      System.assertEquals(testUser.ManagerId,po.NSRSupervisor__c);
      
      po = new Prospect_Ownership__c(NSR_Name__c=testUser.Id, Opportunity__c=opp.Id);
      insert po;
      po = [Select Id, NSR_Name__c, NSRSupervisor__c from Prospect_Ownership__c where Id=:po.Id];
      System.assertEquals(testUser.ManagerId,po.NSRSupervisor__c);

   } // testSetSupervisor
   */
} // class ProspectOwnershipTest