/* Test Methods for AmplifinityHelper

 * History
 * -------
  08/14/2019 Josh Cartwright	Created
  09/05/2019 Dan Carmen			Add methods to update Amplifinity Referrals with Referral info
  03/03/2020 Jermaine Stukes	Add method for account holdout
  10/19/2020 Brandon Vidro      Made updates for APR0109682 - PRN for MMS
  01/06/2020 Brandon Vidro      Added test for referring oppty and setting Paychex Referral Network Enrollment Date on Account when Advocate gets inserted with status of 'Active' 
  03/07/2021 Brandon Vidro      Removed Hold Out tests
  05/18/2021 Dan Carmen           Changed to use OppStage Labels

*/
@isTest
public class AmplifinityHelperTest {
   @testSetup 
    public static void setupData() {
        TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting('ReferralTrigger', true, true, new String[]{'AmplifinityHelper'}, classes, TriggerMethods.INTERFACE_B);
        TriggerMethodsTest.createCustomSetting('OpptyAfter', false, true, new String[]{'AmplifinityHelper'}, classes, TriggerMethods.INTERFACE_B);
        TriggerMethodsTest.createCustomSetting('AdvocateTrigger', false, true, new String[]{'AmplifinityHelper'}, classes, TriggerMethods.INTERFACE_B);
        insert classes;
        
        // use to store the number of days for a holdout
        HoldOut_ExpirationDates__c hoAmp = new HoldOut_ExpirationDates__c(Name='Amplifinity',Sales_Org__c='Amplifinity',Account_Hold_Out__c='Hold_Out__c',Account_Hold_Out_Date__c='Hold_Out_Expiration__c'
                                                                          ,InitialNumberofDays__c=120
                                                                          ,UseForOwnershipChange__c=false,HoldOutReasonFld__c='Permanent_Hold_Out_Description__c'
                                                                          ,Account_Owner__c='OwnerId');
        insert hoAmp;
    } // setupData

   static testMethod void testOppLinking() {
      AmplifinityHelper.checkAmpMaps();
      Map<String,Amplifinity_AR_Status_Mapping__mdt> statusMap = AmplifinityHelper.statusMap;
      // find a status that allows updates
      Amplifinity_AR_Status_Mapping__mdt updateStatus = null;
      for (Amplifinity_AR_Status_Mapping__mdt status : statusMap.values()) {
          if (status.Allow_Updates__c) {
             updateStatus = status;
             break;
          }
      } // for (Amplifinity_AR_Status_Mapping__mdt
      System.assertNotEquals(null,updateStatus,'Could not find a status mapping that allows update!');

      Account acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
       amp_dev__Amp_Referral__c ampRef = new amp_dev__Amp_Referral__c();
       insert ampRef;

       Referral__c ref = new Referral__c(Account__c=acct.Id, Amplifinity_Referral__c=ampRef.Id);
       ref.AMP_Status__c = 'Accepted';
       insert ref;

       amp_dev__Amp_Referral__c ampRef1 = new amp_dev__Amp_Referral__c();
       ampRef1.amp_dev__Status__c = 'Submitted';
       ampRef1.Paychex_Referral__c =ref.id;
       insert ampRef1;
 
      Opportunity opp = new Opportunity(AccountId=acct.Id, Name='Test Opp', CloseDate=Date.today().addDays(7), StageName='Pending', ReferralLookup__c=ref.Id); 
      insert opp;
      
      
      Test.startTest();
      ReferralTriggerActions.SKIP_TRIGGER = false;
      TriggerMethods.clearVariables();
      ref.Selling_Opportunity__c = opp.Id;
      update ref;
      Test.stopTest();
       
      ampRef = [Select Id, amp_dev__Opportunity__c from amp_dev__Amp_Referral__c where Id=:ampRef.Id];
      System.assertEquals(opp.Id, ampRef.amp_dev__Opportunity__c);

      // make sure we have a value for Not Sold
      System.assertEquals(true,AmplifinityHelper.ampByArStatusMap.containsKey(AmplifinityHelper.AR_NOT_SOLD));
      String ampStatus = AmplifinityHelper.ampByArStatusMap.get(AmplifinityHelper.AR_NOT_SOLD);
      System.assertEquals(true,AmplifinityHelper.arByAmpStatusMap.containsKey(ampStatus));
      String arStatus = AmplifinityHelper.arByAmpStatusMap.get(ampStatus);
       
      // update the opportunity to not sold - should update the referral
      TriggerMethods.clearVariables();
      opp.StageName = AmplifinityHelper.NOT_SOLD;
      opp.Reason_Not_Sold__c = 'Did not want';
      opp.amp_dev__Referral__c = ampRef.Id;
      update opp;
       
      ref = [Select Id, Selling_Opportunity__c, AMP_Status__c, AR_Status__c
               from Referral__c
              Where Id = :ref.Id];
      System.assertEquals(ampStatus,ref.AMP_Status__c);
      System.assertEquals(arStatus,ref.AR_Status__c);
      
   } // testOppLinking
        
    static testMethod void testChangeOwnerToAccountOwner() {
        
        Profile hrsProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HRS 401(k) Sales - SB' LIMIT 1];
        User hrsRep = [SELECT Id, Name FROM User WHERE ProfileId = :hrsProfile.Id AND IsActive = true LIMIT 1];
        
        Profile payProfile = [SELECT Id, Name FROM Profile WHERE Name = 'MMS Sales - SB' LIMIT 1];
        User mmsRep = [SELECT Id, Name FROM User WHERE ProfileId = :payProfile.Id AND IsActive = true LIMIT 1];
        
        Account acct = new Account(Name='Test Acct', OwnerId = mmsRep.Id);
        insert acct;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Active', Account__c=acct.Id, OwnerId = hrsRep.Id, Change_Owner_Date__c = Date.today());
        insert ampAdv;
        
        Test.startTest();
        
        ampAdv.Change_Owner_Date__c = null;
        update ampAdv;

        Test.stopTest();
        
        amp_dev__Amp_Advocate__c ampAdvTest = [Select Id, OwnerId from amp_dev__Amp_Advocate__c ampAdv where Id=:ampAdv.Id LIMIT 1];
        System.assertEquals(ampAdvTest.OwnerId, mmsRep.Id);
        
    }
    
    static testMethod void testAdvocateImmediatelyActive() {
        
        Profile hrsProfile = [SELECT Id, Name FROM Profile WHERE Name = 'HRS 401(k) Sales - SB' LIMIT 1];
        User hrsRep = [SELECT Id, Name FROM User WHERE ProfileId = :hrsProfile.Id AND IsActive = true LIMIT 1];
        
        Profile payProfile = [SELECT Id, Name FROM Profile WHERE Name = 'MMS Sales - SB' LIMIT 1];
        User mmsRep = [SELECT Id, Name FROM User WHERE ProfileId = :payProfile.Id AND IsActive = true LIMIT 1];
        
        Account acct = new Account(Name='Test Acct', OwnerId = mmsRep.Id);
        insert acct;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', Account__c=acct.Id, OwnerId = hrsRep.Id);
        acct.Amplifinity_Advocate__c = ampAdv.id;
        update acct;
        Test.startTest();
        
		insert ampAdv;
        ampAdv.amp_dev__Status__c = 'Active';
        update ampAdv;
        
        Test.stopTest();
        
        Account acctTest = [Select Id, Paychex_Referral_Network_Enrollment_Date__c from Account acct where Id=:acct.Id LIMIT 1];
        System.assertEquals(acctTest.Paychex_Referral_Network_Enrollment_Date__c, Date.today());
        
    }
    
    static testMethod void testOwnerChangeFromAmpUser() {
        
        Profile payProfile = [SELECT Id, Name FROM Profile WHERE Name = 'MMS Sales - SB' LIMIT 1];
        User mmsRep = [SELECT Id, Name FROM User WHERE ProfileId = :payProfile.Id AND IsActive = true LIMIT 1];
        
        User ampUser = [Select Id from User where name = 'Amplifinity API USER' limit 1];
        
        Account acct = new Account(Name='Test Acct', OwnerId = mmsRep.Id);
        insert acct;
        
        amp_dev__Amp_Advocate__c ampAdv = new amp_dev__Amp_Advocate__c(Name='TestAdvocate1234', amp_dev__Status__c = 'Invited', Account__c=acct.Id, OwnerId = ampUser.Id);
        
        Test.startTest();
        insert ampAdv;
        Test.stopTest();
        
        amp_dev__Amp_Advocate__c ampAdvTest = [Select Id, OwnerId from amp_dev__Amp_Advocate__c ampAdv where Id=:ampAdv.Id LIMIT 1];
        System.assertEquals(ampAdvTest.OwnerId, mmsRep.Id);
        
    }
    
   static testMethod void testCheckAmpStatus() {
      AmplifinityHelper.checkAmpMaps();
      Map<String,Amplifinity_AR_Status_Mapping__mdt> statusMap = AmplifinityHelper.statusMap;
      // find a status that's closed
      Amplifinity_AR_Status_Mapping__mdt closedStatus = null;
      for (Amplifinity_AR_Status_Mapping__mdt status : statusMap.values()) {
          if (status.IsClosedStatus__c) {
             closedStatus = status;
             break;
          }
      } // for (Amplifinity_AR_Status_Mapping__mdt
      // we should have a value here to proceed
      System.assertNotEquals(null,closedStatus,'Could not find a status mapping record with an IsClosedStatus=true');
      
      amp_dev__Amp_Referral__c ampRef = new amp_dev__Amp_Referral__c();
      insert ampRef;

      ampRef.amp_dev__Status__c = closedStatus.AMP_Status__c;
      TriggerMethods.clearVariables();
      update ampRef;
       
      ampRef = [Select Id, amp_dev__Status__c
                      ,Open_Close_Status__c
                  from amp_dev__Amp_Referral__c
                 Where Id = :ampRef.Id];
      System.assertEquals(AmplifinityHelper.STATUS_CLOSED,ampRef.Open_Close_Status__c);
   } // testCheckAmpStatus
}//AmplifinityHelperTest