/* 
 * additional test methods for the ReferralController
 *
 * History
 * -------
   03/05/2020 Dan Carmen   Created
   06/19/2023 Pujitha Madamanchi  Added test for Selected Acc/Con 

*/
@isTest
public class ReferralControllerTest2 {

   public static String LLC_NAME='WEBLEAD';
   public static String CAMP_NAME='Test Campaign';

   @testSetup
   public static void setupData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, new String[]{'LeadCompanyMethods'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;

       ReferralLeadSourceMap__c rlsm1 = new ReferralLeadSourceMap__c(Name='NSS-ClientReferral',Account_Field__c='',IncomingLeadSource__c='Referral-Client-Unsolicited'
                                 ,IsActive__c=true, Label__c='Client Referral', NeedsReferralSource__c=true
                                 ,NSS_Source__c='Inbound', OppLeadSource__c='Referral-Client-Unsolicited', Partner_Type__c='NSS Referral'
                                 ,PrimarySourceType__c=true, ReferralBusType__c='', SourceType__c='Client');
      ReferralLeadSourceMap__c rlsm2 = new ReferralLeadSourceMap__c(Name='NSS-RefBank',Account_Field__c='',IncomingLeadSource__c='Referral - Bank'
                                 ,IsActive__c=true, Label__c='Bank Referral', NeedsReferralSource__c=true
                                 ,NSS_Source__c='Inbound', OppLeadSource__c='Referral - Bank', Partner_Type__c='NSS Referral'
                                 ,PrimarySourceType__c=true, ReferralBusType__c='Financial Services', SourceType__c='Bank');
      ReferralLeadSourceMap__c rlsm3 = new ReferralLeadSourceMap__c(Name='NSS-RefCPA',Account_Field__c='',IncomingLeadSource__c='Referral - CPA'
                                 ,IsActive__c=true, Label__c='CPA Referral', NeedsReferralSource__c=true
                                 ,NSS_Source__c='Inbound', OppLeadSource__c='Referral - CPA', Partner_Type__c='NSS Referral'
                                 ,PrimarySourceType__c=true, ReferralBusType__c='Accounting Firm', SourceType__c='CPA');
      UserHelperTest.setupSalesOrgSetting();
      ReferralControllerTest.setupRefPartners();
       
      LeadLoaderConfig__c llc1 = new LeadLoaderConfig__c(Name=LLC_NAME, IsActive__c=true, StoreOrginalData__c=true, QueueName__c='NSS Inbound Queue', Sales_Org__c='NSS');
      insert llc1;
      
      Campaign camp1 = new Campaign(Name=CAMP_NAME, LeadSource__c='Campaign LeadSource');
      insert camp1;
   } // setupData

   static testMethod void testLead() {
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c from Campaign where Name=:CAMP_NAME];

      Lead ld = new Lead(LastName='Test Lead', Company='Test Lead Company', Products__c='Prod1;Prod2;Prod3', PostalCode='14624'
                        ,OwnedBy__c=LLC_NAME, Current_Prior_Method__c='test');
      insert ld;
       
      // should create partner referral and referral here.
      System.assertEquals(1,[select count() from PartnerReferral__c where Lead__c=:ld.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceLead__c=:ld.Id and Referral_Partner__c=null]);
       
      User userNsr = [Select Id, Name, NSS_Team__c from User where IsActive=true and NSS_Team__c='Inbound' and Job_Name__c=:UserHelper.JOB_NSR limit 1];
      NSSTeamMap__c team1 = new NSSTeamMap__c(Name=userNsr.NSS_Team__c, NSSSource__c='Inbound', ReferralPartnerType__c=ReferralController.REF_NSS);
      insert team1;

      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Id oppRecTypeId = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId();

      // get a user we can send the lead to
      User usrRep = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Referral_Partner__c queryRp = [Select Id, Name from Referral_Partner__c where Partner_Type__c=:ReferralController.REF_NSS and Name=:UserHelper.SO_CORE order by Sort_Order__c limit 1];
      Referral_Partner__c rp = new Referral_Partner__c(Id=queryRp.Id, Default_User__c=usrRep.Id, Selling_Opp_RecordTypeId__c=oppRecTypeId);
      update rp;
       
      Test.startTest();
      System.runAs(userNsr) {
         Test.SetCurrentPageReference(Page.Referral);
         System.CurrentPageReference().getParameters().put('Id',ld.Id);
         System.CurrentPageReference().getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
         //System.currentPageReference().getParameters().put('startedFrom','Lead');            //CMF
         ReferralController rc = new ReferralController();
         rc.selectedReferralSourceOption = 'CPA Referral';
         String subTitle = rc.sectionHeaderSubTitle;
         System.debug('testLead subTitle='+subTitle);
         System.assertEquals(true,rc.isTelemarketing);
          
         // find the one we found
         ReferralWrapper matchWrap = null;
         for (ReferralWrapper wrap : rc.displayList) {
             if (wrap.refPartner.Id == queryRp.Id) {
                matchWrap = wrap;
                break;
             }
         }
         System.assertNotEquals(null, matchWrap);
         matchWrap.selected=true;
         rc.markSelected();
         
         rc.defReferral.ActivityDate__c = Date.today().addDays(12);
         rc.defReferral.TimeZoneName__c = 'America/New_York';
         rc.selectedTime = '10:00:00';
         rc.checkActivityDate();
         rc.nextStep();
         System.assertEquals(rc.currentStep,ReferralController.STEP3);
      } // System.runAs
       Test.stopTest();
       
      // test to make sure the referral is approved and the selling opportunity is created
      Lead chkLead = [Select Id, IsConverted, ConvertedAccountId, ConvertedContactId from Lead where Id=:ld.Id];
      System.assertEquals(true, chkLead.isConverted);
      
     Referral__c ref = [Select Id, Name, Account__c, SourceContact__c, SourceLead__c, Status__c, Selling_Opportunity__c, User__c from Referral__c where SourceLead__c=:ld.Id];
      System.assertEquals('Approved', ref.Status__c);
      System.assertNotEquals(null,ref.Account__c);
      System.assertNotEquals(null,ref.SourceContact__c);
      System.assertEquals(usrRep.Id, ref.User__c);
      System.assertNotEquals(null,ref.Selling_Opportunity__c); 
       
  
   } // testLead

    static testMethod void testReferralControllerSmall() {
       ReferralControllerSmall rcs = new ReferralControllerSmall();
       System.assertEquals(false,rcs.isPopup);
    }
    
    static testMethod void testLeadWithSelAcct() {
       User smbRep = [SELECT Id FROM User WHERE isActive = true Limit 1];
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c from Campaign where Name=:CAMP_NAME];

      Lead ld = new Lead(LastName='Test Lead', Company='Test Lead Company', Products__c='Prod1;Prod2;Prod3', PostalCode='14624'
                        ,OwnedBy__c=LLC_NAME, Current_Prior_Method__c='test');
      insert ld;
      
      Account acct = new Account(Name='testCo',BillingPostalCode='12451');
      insert acct;
       
      Contact ctct = new Contact(LastName='Test Lead', AccountId=acct.Id);
      insert ctct; 
        
      // should create partner referral and referral here.
      System.assertEquals(1,[select count() from PartnerReferral__c where Lead__c=:ld.Id]);
      System.assertEquals(1,[select count() from Referral__c where SourceLead__c=:ld.Id and Referral_Partner__c=null]);
       
      User userNsr = [Select Id, Name, NSS_Team__c from User where IsActive=true and NSS_Team__c='Inbound' and Job_Name__c=:UserHelper.JOB_NSR limit 1];
      NSSTeamMap__c team1 = new NSSTeamMap__c(Name=userNsr.NSS_Team__c, NSSSource__c='Inbound', ReferralPartnerType__c=ReferralController.REF_NSS);
      insert team1;

      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Id oppRecTypeId = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE).getRecordTypeId();

      // get a user we can send the lead to
      User usrRep = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 1];
      Referral_Partner__c queryRp = [Select Id, Name from Referral_Partner__c where Partner_Type__c=:ReferralController.REF_NSS and Name=:UserHelper.SO_CORE order by Sort_Order__c limit 1];
      Referral_Partner__c rp = new Referral_Partner__c(Id=queryRp.Id, Default_User__c=usrRep.Id, Selling_Opp_RecordTypeId__c=oppRecTypeId);
      update rp;
 
      Test.startTest();
      System.runAs(userNsr) {
         Test.SetCurrentPageReference(Page.Referral);
         System.CurrentPageReference().getParameters().put('Id',ld.Id);
         System.CurrentPageReference().getParameters().put(ReferralController.PARAM_FUNCTION,'NSS');
         ReferralController rc = new ReferralController();
         rc.selectedReferralSourceOption = 'CPA Referral';
         rc.defReferral.Selected_Account__c = acct.Id;
         rc.defReferral.Selected_Contact__c = ctct.Id; 
         String subTitle = rc.sectionHeaderSubTitle;
         System.debug('testLead subTitle='+subTitle);
         System.assertEquals(true,rc.isTelemarketing);
          
         // find the one we found
         ReferralWrapper matchWrap = null;
         for (ReferralWrapper wrap : rc.displayList) {
             if (wrap.refPartner.Id == queryRp.Id) {
                matchWrap = wrap;
                break;
             }
         }
         System.assertNotEquals(null, matchWrap);
         matchWrap.selected=true;
         rc.markSelected();
         
         rc.defReferral.ActivityDate__c = Date.today().addDays(12);
         rc.defReferral.TimeZoneName__c = 'America/New_York';
         rc.selectedTime = '10:00:00';
         rc.checkActivityDate();
         rc.nextStep();
         System.assertEquals(rc.currentStep,ReferralController.STEP3);
      } // System.runAs
       Test.stopTest();
       
      // test to make sure the referral is approved and the selling opportunity is created
      Lead chkLead = [Select Id, IsConverted, ConvertedAccountId, ConvertedContactId from Lead where Id=:ld.Id];
      System.assertEquals(true, chkLead.isConverted);
      Assert.areEqual(acct.Id, chkLead.ConvertedAccountId);
       
     Referral__c ref = [Select Id, Name, Status__c, Selling_Opportunity__c, Selected_Account__c from Referral__c where SourceLead__c=:ld.Id];     
      System.assertEquals('Approved', ref.Status__c);
      System.assertNotEquals(null,ref.Selling_Opportunity__c); 
      Assert.areEqual(acct.Id, ref.Selected_Account__c);
  
   } // testLeadWithSelAcct
 
} // class ReferralControllerTest2