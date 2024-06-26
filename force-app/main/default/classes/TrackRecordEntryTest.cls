/* 
 * Test Methods for the TrackRecordEntry class
 *
 * History
 * -------
   05/08/2017 Dan Carmen       Created
   12/18/2017 Cindy Freeman    Modified for Consent to Text fields
   12/28/2017 Dan Carmen       Get the employee count from the contact to pass in with the account.
   01/09/2018 Cindy Freeman    Added MobilePhone when setting Consent to Text = true for validation rule
   01/25/2018 Dan Carmen       Changes to use the Weblead checkbox
   05/14/2018 Dan Carmen       Add consent to text logic for webleads
   06/04/2018 Cindy Freeman    Added Consent to Text Reason when inserting Lead and Contact with Consent to Text set
   06/28/2018 Cindy Freeman    Added test for PEO Centric campaign stuff
   07/27/2018 Dan Carmen       Additional Code Coverage
   11/19/2018 Dan Carmen       Comment out Prospect Ownership
   03/19/2019 Jake Hinds       Removing PEO-C code
   02/17/2020 Dan Carmen       Make test class public.
   11/05/2020 Dan Carmen       Make setupData public
   03/08/2021 Brandon Vidro    Added Amp lead routing test
   03/12/2021 Brandon Vidro    Added Drift Campaign test
   07/02/2021 Pujitha Madamanchi Remove drift test method
   10/27/2021 Pujitha Madamanchi APR0109624: Populate Strategic account on Lead and Account from Campaign.
   08/09/2022 Pujitha Madamanchi APR0135240: Routing by EE segment for WEBLEAD.
   03/23/2022 Pujitha Madamanchi APR0148464: Parse XeroId from Blob
   04/03/2022 Pujitha Madamanchi : APR0151002  Fix for XeroId text 
   08/01/2023 Dan Carmen         Fix logging 
   01/19/2024 Pujitha Madamanchi : Remove tests related to blob and update PR mapping


 */
@isTest
public class TrackRecordEntryTest {
   
   private static String LLC_NAME='TestOwnedBy';
   private static String LLC_NAME2='TestOwnedBy2';
   private static String LLC_AMP='ReferralManagement';
   private static String CAMP_NAME='Test Campaign';
   private static String PEOCAMP_NAME='Test Peo Campaign';
   private static String DRIFTCAMP_NAME='Test Drift Campaign';
   
   private static Map<String,String> districtNames = new Map<String, String>();
   private static Map<String,String> tiers = new Map<String,String>();
   private static Map<String,String> zones = new Map<String,String>();
   private static Map<String,String> otherDistricts = new Map<String,String>();
   private static Map<String,Decimal> numEmpMin = new Map<String,Decimal>();
   private static Map<String,Decimal> numEmpMax = new Map<String,Decimal>();
   
   @testSetup
   public static void setupData() {
      // setup triggers
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);

      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses, TriggerMethods.INTERFACE_A);
      insert setupClasses;

      Group vq = [SELECT Id,Name FROM Group WHERE Type='Queue' AND Name = 'Virtual Sales Queue' LIMIT 1];
      BypassNSS__c bypassSetting = new BypassNSS__c(SetupOwnerId=UserInfo.getOrganizationId(), IsActive__c=true,Queue_Id__c=vq.Id,Queue_Name__c=vq.Name,Partner_Referral_Expiration_Duration__c=1,Holdout_Expiration__c=1);
      insert bypassSetting; 

      LeadLoaderConfig__c llc1 = new LeadLoaderConfig__c(Name=LLC_NAME, IsActive__c=true, StoreOrginalData__c=true, QueueName__c='NSS Inbound Queue', Sales_Org__c='NSS');
      LeadLoaderConfig__c llc2 = new LeadLoaderConfig__c(Name=LLC_NAME2, IsActive__c=true, StoreOrginalData__c=true, QueueName__c='Oasis Queue', CheckForDuplicate__c=true, Sales_Org__c='Oasis');
      LeadLoaderConfig__c llc3 = new LeadLoaderConfig__c(Name=LLC_AMP, IsActive__c=true, StoreOrginalData__c=true, CheckForDuplicate__c=true, CheckWorkable__c=true, IsAmplifinity__c=true);
      LeadLoaderConfig__c[] llcs = new LeadLoaderConfig__c[]{llc1,llc2,llc3};
      insert llcs;
      
      Campaign camp1 = new Campaign(Name=CAMP_NAME, LeadSource__c='Campaign LeadSource');
      insert camp1;
      Campaign camp2 = new Campaign(Name=PEOCAMP_NAME, LeadSource__c='Campaign PEO LeadSource',IsActive=true, Send_To_Virtual__c='PEO Centric Ownership');
      insert camp2;
      Campaign camp3 = new Campaign(Name=DRIFTCAMP_NAME, LeadSource__c='Campaign Drift LeadSource',IsActive=true, Source_Type__c='Chat');
      insert camp3;
       
      Amp_Lead_Routing__mdt[] ampLeadRouting = [Select MasterLabel, Label, District_Name__c, District_Name_Two__c, Number_Of_Employees_Max__c, Number_Of_Employees_Min__c, Tier__c, Zone__c from Amp_Lead_Routing__mdt];
  
      for(Amp_Lead_Routing__mdt record:ampLeadRouting) {
          districtNames.put(record.label,record.District_Name__c);
          tiers.put(record.label,record.Tier__c);
          zones.put(record.label,record.Zone__c);
          otherDistricts.put(record.label,record.District_Name_Two__c);
          numEmpMin.put(record.label,record.Number_Of_Employees_Min__c);
          numEmpMax.put(record.label,record.Number_Of_Employees_Max__c);
      } //for(Amp_Lead_Routing__mdt record:ampLeadRouting)
       
   } // setupData

   static testMethod void testGetConfig() {
      LeadLoaderConfig__c llc1 = new LeadLoaderConfig__c(Name='Test1', IsActive__c=true, StoreOrginalData__c=true);
      LeadLoaderConfig__c llc2 = new LeadLoaderConfig__c(Name='Test2', IsActive__c=true, StoreOrginalData__c=true);
      LeadLoaderConfig__c llc3 = new LeadLoaderConfig__c(Name='Test3', IsActive__c=true, StoreOrginalData__c=true);
      LeadLoaderConfig__c[] llcs = new LeadLoaderConfig__c[]{llc1,llc2,llc3};
      insert llcs;
      
      LeadSource__c lsSetting = new LeadSource__c(Name='Test Lead Source', OwnedByDefault__c=llc2.Name);      
      insert lsSetting;
      
      User runningUser = UserHelper.getRunningUser();
      Profile_List__c plSetting = new Profile_List__c(Name=runningUser.Profile.Name, OwnedByDefault__c=llc3.Name);
      insert plSetting;
      
      LeadLoaderConfig__c testConfig = TrackRecordEntry.getConfig('BadName','BadLeadSource',true);
      System.assertEquals(null, testConfig);
      
      testConfig = TrackRecordEntry.getConfig(llc1.Name,'BadLeadSource',true);
      System.assertEquals(llc1.Id, testConfig.Id);
      
      testConfig = TrackRecordEntry.getConfig(null,lsSetting.Name,true);
      System.assertEquals(llc2.Id, testConfig.Id);
      
      testConfig = TrackRecordEntry.getConfig(null,null,true);
      System.assertEquals(llc3.Id, testConfig.Id);
      
      testConfig = TrackRecordEntry.getConfig(null,null,false);
      System.assertEquals(null, testConfig);
      
      
   } // testGetConfig
  
 /*  public static String TEST_DESC = 'NUMBER_OF_EMPLOYEES: 4\n'
          +'FIRSTNAME: Jeffrey\n'
          +'LASTNAME: COOP\n'
          +'PHONE: (417) 631-6799\n'
          +'EMAIL: fryingchicken83@gmail.com\n'
          +'COMPANY_NAME: Scil\n'
          +'ADDRESS_1: \n'
          +'CITY: Springfield\n'
          +'STATE: MO\n'
          +'POSTAL_CODE: 65803\n'
          +'CAMPAIGN: 70170000000VHBN\n'
          +'LEAD_SOURCE: Corp Marketing-Web\n'
          +'CONSENT: false\n'
          +'MOBILE_NUMBER: \n'
          +'FRANCHISE_CODE: 77812 \n'
          +'VENDOR_ID: 7177 \n'
          +'XERO_ID: 7177-a3bdu-12345 \n'
          +'CONSENT_DATE: 2017-12-27T07:23:52Z\n'
          +'----------: \n'
          +'\n'
          +'Lead Tracking Information\n'
          +'PAYROLL_PACKAGE |^| \n'
          +'PROCESSING_FREQUENCY |^|\n' 
          +'PRICING |^| \n'
          +'REFERER |^| MARKETO\n'
          +'FIRSTNAME |^| Jeffrey\n'
          +'LASTNAME |^| COOP\n'
          +'EMAIL |^| fryingchicken83@gmail.com\n'
          +'PHONE |^| 4176316799\n'
          +'POSTAL_CODE |^| 65803\n'
          +'NUMBER_OF_EMPLOYEES |^| 5\n'
          +'CAMPAIGN |^| 70170000000VHBN\n'
          +'LEAD_SOURCE |^|\n' 
          +'COMPANY_NAME |^| Scil\n'
          +'ADDRESS_1 |^|\n' 
          +'PPCPN |^|\n';

         */

   static testMethod void testLead() {
      //TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      //TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'LeadBefore', true, false, new String[]{'TrackRecordEntry'},setupClasses);
      //TriggerSetup__c trigSetup2 = TriggerMethodsTest.createCustomSetting(null, 'LeadAfter', false, true, new String[]{'TrackRecordEntry'},setupClasses);
      //insert setupClasses;
      //LeadLoaderConfig__c llc = new LeadLoaderConfig__c(Name='TestOwnedBy', IsActive__c=true, StoreOrginalData__c=true, QueueName__c='NSS Inbound Queue');
      //insert llc;
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c,Source_Type__c from Campaign where Name=:CAMP_NAME];
      Campaign camp3 = [Select Id, Name, LeadSource__c,Source_Type__c from Campaign where Name=:DRIFTCAMP_NAME];

      TrackRecordEntry.EMPLOYEES_TAG = 'NUMBER_OF_EMPLOYEES:';
      TrackRecordEntry.FRANCHISE_TAG = 'FRANCHISE_CODE:';
      TrackRecordEntry.VENDOR_TAG='VENDOR_ID:';

      // find a queue for testing
      Group[] queryGrps = [Select Id, Type, OwnerId, Name, Email from Group 
                            where Type = 'Queue'
                              and Name in ('NSS Inbound Queue','NSS Pending Queue','NSS Pivot Queue') limit 2];
      System.assertEquals(true, queryGrps.size() > 0);
      
      LeadRouting__c leadRoute1 = new LeadRouting__c(Name='Virtual 0-4',UseAsFilter__c=true, EmpsMin__c=0,EmpsMax__c=4
                  ,QueueId__c=queryGrps[0].Id, Queue_Name__c=queryGrps[0].Name, Destination__c=queryGrps[0].Name);
      LeadRouting__c leadRoute2 = new LeadRouting__c(Name='Default-'+llc.Name,UseAsFilter__c=false, EmpsMin__c=null,EmpsMax__c=null
                  ,QueueId__c=queryGrps[1].Id, Queue_Name__c=queryGrps[1].Name, Destination__c=queryGrps[1].Name);
      LeadRouting__c[] routings = new LeadRouting__c[]{leadRoute1,leadRoute2};
      insert routings;
      
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CHANNEL_REFERRAL_ACCOUNT, ObjectHelper.OBJECT_REF_ACCOUNT);
      
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Franchise', National_Account_Code__c='77812', RecordTypeId=rtInfo.getRecordTypeId());
      insert refAcct;

      //Campaign camp1 = new Campaign(Name='Test Campaign', LeadSource__c='Campaign LeadSource');
      //insert camp1;
      
      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1', OwnedBy__c=llc.Name
                        ,LatestCampaign__c=camp1.Id
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=3
                        ,MobilePhone='555-1212'
                        ,Consent_to_Text__c=true
                        ,Consent_to_Text_Date__c=System.now()
                        ,Consent_to_Text_Reason__c = 'Weblead change'
                        //,Description=TEST_DESC
                        );
      Lead ld2 = new Lead(Company='Test Company2', FirstName='First', LastName='Last2', OwnedBy__c=llc.Name
                        ,LatestCampaign__c=camp1.Id
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=12
                        );
      Lead ld3 = new Lead(Company='Test Company3', FirstName='First', LastName='Last3', OwnedBy__c=llc.Name
                        ,LatestCampaign__c=null
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=null
                        );
      Lead ld4 = new Lead(Company='Test Company4', FirstName='First', LastName='Last4', OwnedBy__c=llc.Name
                        ,LatestCampaign__c=camp3.Id
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=null
                        );       
      Lead[] lds = new Lead[]{ld1,ld2,ld3,ld4};
      Test.StartTest();
      System.debug('testLead before insert');
      insert lds;
      Test.StopTest();
      
      //System.assertEquals(1,[select count() from PartnerReferral__c where Lead__c=:ld.Id]);
      //System.assertEquals(1,[select count() from Referral__c where SourceLead__c=:ld.Id]);
      
      Lead checkLd1 = [Select Id, Referral_National_Account__c
                         From Lead
                        Where Id=:ld1.Id];
     // System.assertEquals(refAcct.Id, checkLd1.Referral_National_Account__c);

      PartnerReferral__c partRef = [Select Id, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,Destination__c
                                          ,LeadSource__c
                                          ,NumberOfEmployees__c
                                          ,Consent_to_Text__c
                                          ,Consent_to_Text_Date__c
                                          ,Franchise_Account_Code__c
                                          ,Vendor_ID__c
                                      from PartnerReferral__c
                                     Where Lead__c = :ld1.Id];
      System.assertEquals(ld1.FirstName, partRef.FirstName__c);
      System.assertEquals(ld1.LastName, partRef.LastName__c);
      System.assertEquals(ld1.Company, partRef.Company__c);
      System.assertEquals(ld1.LatestCampaign__c, partRef.Campaign__c);
      System.assertEquals(ld1.NumberOfEmployees, partRef.NumberOfEmployees__c);
      System.assertEquals(ld1.Consent_to_Text__c, partRef.Consent_to_Text__c);
      System.assertNotEquals(null,partRef.Consent_to_Text_Date__c);
   //   System.assertEquals(ld1.Consent_to_Text_Date__c, partRef.Consent_to_Text_Date__c);
      System.assertEquals(camp1.LeadSource__c, partRef.LeadSource__c);
    //  System.assertEquals(77812, partRef.Franchise_Account_Code__c);
    //  System.assertEquals(7177, partRef.Vendor_ID__c);
       
      PartnerReferral__c partRefDrift = [Select Id, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,Source__c
                                      from PartnerReferral__c
                                     Where Lead__c = :ld4.Id];

    //  System.assertEquals('Chat', partRefDrift.Source__c);
                                 
      Referral__c ref = [Select Id, Name
                               ,Campaign__c
                               ,NbrOfEmployees__c
                               ,SellingLeadSource__c
                           From Referral__c
                          Where SourceLead__c = :ld1.Id];
      System.assertEquals(camp1.LeadSource__c, ref.SellingLeadSource__c);
      System.assertEquals(camp1.Id, ref.Campaign__c);
      System.assertEquals(ld1.NumberOfEmployees, ref.NbrOfEmployees__c);
      
   } // testLead

   static testMethod void testContact() {
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp = [Select Id, Name, LeadSource__c from Campaign where Name=:CAMP_NAME];
      TrackRecordEntry.EMPLOYEES_TAG = 'NUMBER_OF_EMPLOYEES:';
      TrackRecordEntry.CHECK_CTCT_EMP_CNT = true;
      TrackRecordEntry.FRANCHISE_TAG = 'FRANCHISE_CODE:';
      TrackRecordEntry.VENDOR_TAG='VENDOR_ID:';
      
      Account acct = new Account(Name='Test Acct', ShippingPostalCode='14604', Employees__c=10, NumberOfEmployees=10);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CHANNEL_REFERRAL_ACCOUNT, ObjectHelper.OBJECT_REF_ACCOUNT);
      
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Franchise', National_Account_Code__c='77812', RecordTypeId=rtInfo.getRecordTypeId());
      insert refAcct;
      
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Joe', LastName='Contact', Title='All Being, Master of Time, Space and Dimension'
                              //  ,Description=TEST_DESC
                                ,Email='joe@testacct.com'
                                ,LeadSource='Contact LeadSource'
                                ,LatestCampaign__c=camp.Id
                                ,OwnedBy__c=llc.Name
                                ,Consent_to_Text__c=true
                                ,MobilePhone='555-1212'
                                ,Consent_to_Text_Date__c=System.now()
                                ,Consent_to_Text_Reason__c = 'Weblead change');
      
      Test.startTest();
      insert ctct;
      Test.stopTest();
      
      PartnerReferral__c partRef = [Select Id, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,LeadSource__c
                                          ,NumberOfEmployees__c
                                          ,Consent_to_Text__c
                                          ,Consent_to_Text_Date__c
                                          ,EmployeesFromForm__c
                                          ,Franchise_Account_Code__c
                                          ,Vendor_ID__c
                                      from PartnerReferral__c
                                     Where Contact__c = :ctct.Id];
      System.assertEquals(ctct.FirstName, partRef.FirstName__c);
      System.assertEquals(ctct.LastName, partRef.LastName__c);
      System.assertEquals(acct.Name, partRef.Company__c);
      System.assertEquals(ctct.LatestCampaign__c, partRef.Campaign__c);
      System.assertEquals(ctct.Consent_to_Text__c, partRef.Consent_to_Text__c);
      System.assertNotEquals(null,partRef.Consent_to_Text_Date__c);
      //System.assertEquals(ctct.Consent_to_Text_Date__c, partRef.Consent_to_Text_Date__c);
      // should be pulling the number of employees from the description on the contact, not what was on the account.
      System.assertEquals(10, partRef.NumberOfEmployees__c);
      System.assertEquals(camp.LeadSource__c, partRef.LeadSource__c);
   /*   System.assertEquals(4, partRef.EmployeesFromForm__c);
      System.assertEquals(77812, partRef.Franchise_Account_Code__c);
      System.assertEquals(7177, partRef.Vendor_ID__c);
    */  
      Referral__c ref = [Select Id, Name
                               ,Campaign__c
                               ,NbrOfEmployees__c
                               ,SellingLeadSource__c
                           From Referral__c
                          Where SourceContact__c = :ctct.Id];
      System.assertEquals(camp.LeadSource__c, ref.SellingLeadSource__c);
      System.assertEquals(camp.Id, ref.Campaign__c);
      System.assertEquals(10, ref.NbrOfEmployees__c);
      
      //Account checkAcct = [Select Id, Name, Employees__c, NumberOfEmployees, Referral_National_Account__c from Account where Id=:acct.Id];
      //System.assertEquals(4,checkAcct.NumberOfEmployees);
      //System.assertEquals(4,checkAcct.Employees__c);
     // System.assertEquals(refAcct.Id, checkAcct.Referral_National_Account__c);

   } // testContact

/*   static testMethod void testDescription() {
      TrackRecordEntry.MARKETO_SEPARATOR = '~';
      String testDesc = 'Hi~This~Is~A~Test';
      Lead ld = new Lead(Description=testDesc, WebLead__c=true);
      TrackRecordEntry.checkLeadDescription(ld,true);
      System.assertEquals(true,ld.Description.contains('Hi\nThis\nIs\nA\nTest'));
      
      TrackRecordEntry.resetWebLead(ld);
    //  System.assertEquals(false,ld.WebLead__c);
      
      //TrackRecordEntry.setupOwnership(new Set<Id>(), 'BadObject');
      
      TrackRecordEntry.logOriginalData(ld,null);
      
   } // testDescription
   */
   
   static testMethod void testConsentToText() {
      Lead ld = new Lead(Consent_to_Text__c=true);
      TrackRecordEntry.checkConsentToText(ld, null, true);
      System.assertEquals(true, ld.Consent_to_Text_Date__c != null);
      System.assertEquals(TrackRecordEntry.CONSENT_CHANGE_REASON_WEB, ld.Consent_to_Text_reason__c);
      
      Lead ld2 = new Lead(Consent_to_Text__c=true);
      // nothing should change on the ld2 record because flags on both records are true
      TrackRecordEntry.checkConsentToText(ld2, ld, true);
      System.assertEquals(null, ld2.Consent_to_Text_Date__c);
      System.assertEquals(null, ld2.Consent_to_Text_reason__c);

      // enter with a null value - nothing happens.
      Lead ld3 = new Lead();
      TrackRecordEntry.checkConsentToText(ld2, ld, true);
      System.assertEquals(null, ld2.Consent_to_Text_Date__c);
      System.assertEquals(null, ld2.Consent_to_Text_reason__c);


   } // testConsentToText

  
  /*
  // test retrieving the Prospect_Ownership of records
  static testMethod void testGetOwnership() {
     Lead ld1 = new Lead(Company='Test Lead', LastName='TestLast');
     insert ld1;
     
     Contact ctct1 = new Contact(LastName='ContactLast');
     insert ctct1;
     
     Prospect_Ownership__c po1 = new Prospect_Ownership__c();
     Prospect_Ownership__c po2 = new Prospect_Ownership__c();
     
     TrackRecordEntry.poLeadIdMap = new Map<Id,Prospect_Ownership__c>();
     TrackRecordEntry.poLeadIdMap.put(ld1.Id, po1);
     TrackRecordEntry.poAcctIdMap = new Map<Id,List<Prospect_Ownership__c>>();
     TrackRecordEntry.poAcctIdMap.put(ctct1.Id, new Prospect_Ownership__c[]{po2});
     
     Prospect_Ownership__c[] poList = TrackRecordEntry.getOwnership(ld1.Id, ObjectHelper.OBJECT_LEAD);
     System.assertEquals(1,poList.size());

     poList = TrackRecordEntry.getOwnership(ctct1.Id, ObjectHelper.OBJECT_CONTACT);
     System.assertEquals(1,poList.size());
     
  } // testGetOwnership
  */

   static testMethod void testMisc() {
      TrackRecordEntry tre = new TrackRecordEntry();
      TrackRecordEntry.SKIP_TRIGGER=true;
      tre.checkAllBeforeTrigger(null,null);
      tre.checkAllAfterTrigger(null,null);

      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1'
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=3
                        ,MobilePhone='555-1212'
                        ,Consent_to_Text__c=true
                        ,Consent_to_Text_Date__c=System.now()
                        ,Consent_to_Text_Reason__c = 'Weblead change'
                        ,Weblead__c=true
                        ,TransactionId__c='ThisIsATestLead'
                        );
     TrackRecordEntry.logOriginalData(ld1);
     TrackRecordEntry.logOriginalData(ld1,'Please Add This To The Notes', true);
     
     Account acct = new Account(Name='Test Account');
     Contact ctct = new Contact(LastName='TestLast', TransactionId__c='ThisIsATestContact');
     
     TrackRecordEntry.logOriginalData(ctct,acct);
     TrackRecordEntry.logOriginalData(ctct,acct,'Please Add To Notes', true);
     
   } // testMisc
  
   static testMethod void testWebleadCheckbox() {
      //LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c from Campaign where Name=:CAMP_NAME];
      
      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1'
                        ,LatestCampaign__c=camp1.Id
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=3
                        ,MobilePhone='555-1212'
                        ,Consent_to_Text__c=true
                        ,Consent_to_Text_Date__c=System.now()
                        ,Consent_to_Text_Reason__c = 'Weblead change'
                        ,Weblead__c=true
                        );
      Test.StartTest();
      insert ld1;
      Test.StopTest();

  } // testWebleadCheckbox
  
   static testMethod void testCheckForDuplicate() {
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME2);

      // find a queue for testing
      Group[] queryGrps = [Select Id, Type, OwnerId, Name, Email from Group 
                            where Type = 'Queue'
                              and Name in ('NSS Inbound Queue','Oasis Queue') order by Name desc limit 2];
      System.assertEquals(true, queryGrps.size() > 0);
      
      LeadRouting__c leadRoute1 = new LeadRouting__c(Name='Default-'+llc.Name,UseAsFilter__c=false, EmpsMin__c=null,EmpsMax__c=null
                  ,QueueId__c=queryGrps[1].Id, Queue_Name__c=queryGrps[1].Name, Destination__c=queryGrps[1].Name);
      LeadRouting__c[] routings = new LeadRouting__c[]{leadRoute1};
      insert routings;
      
      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1', OwnedBy__c=llc.Name
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=3
                        ,MobilePhone='555-1212'
                        );
      Lead[] lds = new Lead[]{ld1};
      Test.StartTest();
      insert lds;
      Test.StopTest();
      
      PartnerReferral__c partRef = [Select Id, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,Destination__c
                                          ,LeadSource__c
                                          ,NumberOfEmployees__c
                                          ,Consent_to_Text__c
                                          ,Consent_to_Text_Date__c
                                      from PartnerReferral__c
                                     Where Lead__c = :ld1.Id];
      System.assertEquals(ld1.FirstName, partRef.FirstName__c);
      System.assertEquals(ld1.LastName, partRef.LastName__c);
      System.assertEquals(ld1.Company, partRef.Company__c);
      //System.assertEquals(ld1.LatestCampaign__c, partRef.Campaign__c);
      System.assertEquals(ld1.NumberOfEmployees, partRef.NumberOfEmployees__c);
                                 
      Referral__c ref = [Select Id, Name
                               ,Campaign__c
                               ,NbrOfEmployees__c
                               ,SellingLeadSource__c
                           From Referral__c
                          Where SourceLead__c = :ld1.Id];
      System.assertEquals(ld1.NumberOfEmployees, ref.NbrOfEmployees__c);
   } // testCheckForDuplicate
   
   static testMethod void testFindReferralPartner() {
      Referral_Partner__c rp = new Referral_Partner__c(Name=TrackRecordEntry.REF_PART_NETWORK,Partner_Type__c=TrackRecordEntry.AMP_PARTNER_TYPE,Sort_Order__c=10,Ref_To_Type__c='Contact',CreateRefOpp__c=false,UseApprovalProcess__c=false, IsActive__c=true, CheckPartnerReferral__c=true);
      insert rp;
      
      Referral_Partner__c searchRp = TrackRecordEntry.findReferralPartner(TrackRecordEntry.REF_PART_NETWORK);
      System.assertEquals(rp.Id, searchRp.Id);
   } // testFindReferralPartner

   static testMethod void testAmpLeadRouting() {
      LeadRouting__c leadRoute1 = new LeadRouting__c(Name='Default-ReferralManagement',Destination__c='Paychex Referral Network');
      insert leadRoute1;
      ZipCheckOwnerTest.setupSegments();
      Zip_Segment__c seg1 = ZipCheckOwnerTest.coreSeg1;
      seg1.Name = 'Channel';
      update seg1;
      
      User uCore1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, SMB_Certified__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
       
      Zip_Assignment__c[] v_zas = new Zip_Assignment__c[]{};
      Zip_Assignment__c za1 = ZipCheckOwnerTest.createZa('12345', uCore1, uCore1.Sales_Org__c, seg1.Name, seg1.Id, null, null, v_zas);
      insert za1;
       
      Account advAcct = new Account(Name='Advocate', OwnerId=uCore1.Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert advAcct;
      
      amp_dev__Amp_Advocate__c advocate = new amp_dev__Amp_Advocate__c(Name='Test Advocate', OwnerId = uCore1.Id
                                                 ,amp_dev__Enrollment_Date__c=Datetime.now().addDays(-20)
                                                 ,Account__c=advAcct.Id);
      insert advocate;
       
      
      amp_dev__Amp_Referral__c aR = new amp_dev__Amp_Referral__c (amp_dev__Last_Name__c='Test1', Name ='1234', amp_dev__Advocate__c=advocate.Id); 
      insert aR; 
      Lead l1 = new Lead(LastName='Test1',Company='Test1 Co',Product_Division__c='PAY', PostalCode='12345', NumberOfEmployees=18, amp_dev__Referral__c =aR.Id, OwnedBy__c=LLC_AMP);
      System.runAs(uCore1){
          Test.startTest();
          insert l1;
          Test.stopTest();
      }
      PartnerReferral__c partRef = [Select Id, Lead__c, Workable__c, DuplicateNotWorkableReason__c from PartnerReferral__c where Lead__c=:l1.Id];
      Referral__c ref = [Select Id, OwnerId from Referral__c where PartnerReferral__c=:partRef.Id];
      amp_dev__Amp_Advocate__c adv = [Select Id, OwnerId from amp_dev__Amp_Advocate__c where Id =:advocate.Id];
      System.assertEquals(TrackRecordEntry.WORKABLE, partRef.Workable__c);
      System.assertEquals(ref.OwnerId, adv.OwnerId); 
   } // testAmpLeadRouting
    
   static testMethod void testAcctCtctWorkable() {
      TrackRecordEntry.ONLY_AMP_API_ELIGIBILITY=true;
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_AMP,runningUser.Name);

      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
      
      Account advAcct = new Account(Name='Advocate', OwnerId=reps[0].Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert advAcct;
      
      amp_dev__Amp_Advocate__c advocate = new amp_dev__Amp_Advocate__c(Name='Test Advocate'
                                                 ,amp_dev__Enrollment_Date__c=Datetime.now().addDays(-20)
                                                 ,Account__c=advAcct.Id);
      insert advocate;
      
      amp_dev__Amp_Referral__c aR = new amp_dev__Amp_Referral__c (amp_dev__Last_Name__c='Test1', Name ='1234'); 
      insert aR; 

      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c=OpptyMethods.OPP_TYPE_PAY);
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opp;
      
      Event evt = new Event(WhatId=acct.Id, Subject='This is an Event', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now().addDays(7), DurationInMinutes=30);
      insert evt;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast', Email='test@test.com', OwnedBy__c=LLC_AMP, AMP_Referral__c=aR.Id);
      Test.startTest();
      insert ctct;
      Test.stopTest();
      
      PartnerReferral__c partRef = [Select Id, Contact__c, Workable__c, DuplicateNotWorkableReason__c from PartnerReferral__c where Contact__c=:ctct.Id];
      System.assertEquals(TrackRecordEntry.NOT_WORKABLE, partRef.Workable__c);
      
      amp_dev__Amp_Referral__c ampRef = [Select Id
                                               ,amp_dev__Status__c
                                               ,Open_Close_Status__c
                                           From amp_dev__Amp_Referral__c
                                          Where Id=:aR.Id];
      System.assertEquals('Closed',ampRef.Open_Close_Status__c);
      
   } // testAcctCtctWorkable

   static testMethod void testAcctCtctWorkable2() {
      TrackRecordEntry.ONLY_AMP_API_ELIGIBILITY=true;
      //User runningUser = UserHelper.getRunningUser();
      //ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_AMP,runningUser.Name);

      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
      
      Account advAcct = new Account(Name='Advocate', OwnerId=reps[0].Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert advAcct;
      
      amp_dev__Amp_Advocate__c advocate = new amp_dev__Amp_Advocate__c(Name='Test Advocate'
                                                 ,amp_dev__Enrollment_Date__c=Datetime.now().addDays(-20)
                                                 ,Account__c=advAcct.Id);
      insert advocate;
      
      amp_dev__Amp_Referral__c aR = new amp_dev__Amp_Referral__c (amp_dev__Last_Name__c='Test1', Name ='1234'); 
      insert aR; 

      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Opportunity opp = new Opportunity(Name='Test Opp', AccountId=acct.Id, CloseDate=Date.today().addDays(7), StageName='Pending');
      OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
      insert opp;
      
      Event evt = new Event(WhatId=acct.Id, Subject='This is an Event', ActivityDate=Date.today().addDays(7), ActivityDateTime=Datetime.now().addDays(7), DurationInMinutes=30);
      insert evt;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast', Email='test@test.com', OwnedBy__c=LLC_AMP, AMP_Referral__c=aR.Id);
      Test.startTest();
      insert ctct;
      Test.stopTest();
      
      PartnerReferral__c partRef = [Select Id, Contact__c, Workable__c, DuplicateNotWorkableReason__c from PartnerReferral__c where Contact__c=:ctct.Id];
      System.assertEquals(TrackRecordEntry.NOT_WORKABLE, partRef.Workable__c);
      
      // this should NOT update  the amplifinity referral because we didn't set the running user as the amplifinity user
      amp_dev__Amp_Referral__c ampRef = [Select Id
                                               ,amp_dev__Status__c
                                               ,Open_Close_Status__c
                                           From amp_dev__Amp_Referral__c
                                          Where Id=:aR.Id];
      System.assertEquals(null,ampRef.Open_Close_Status__c);

      Opportunity checkOpp = [Select Id, ReferralLookup__c from Opportunity where Id=:opp.Id];
      System.assertNotEquals(null, checkOpp.ReferralLookup__c);
      
      Referral__c checkRef = [Select Id, Selling_Opportunity__c from Referral__c where Id=:checkOpp.ReferralLookup__c];
      System.assertEquals(opp.Id, checkRef.Selling_Opportunity__c);

   } // testAcctCtctWorkable2
    
 /* static testMethod void testDriftLead() {
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c,Source_Type__c from Campaign where Name=:DRIFTCAMP_NAME];
      // find a queue for testing
      Group[] queryGrpsDrift = [Select Id, Type, OwnerId, Name, Email from Group 
                            where Type = 'Queue'
                            and Name = 'Drift Chat' limit 1];
      System.assertEquals(true, queryGrpsDrift.size() > 0);
      
      LeadRouting__c leadRoute1 = new LeadRouting__c(Name='Drift-Chat', QueueId__c=queryGrpsDrift[0].Id, Queue_Name__c=queryGrpsDrift[0].Name, Destination__c=queryGrpsDrift[0].Name);
      insert leadRoute1;
                  
      Lead ld1 = new Lead(Company='Test Company1', FirstName='First', LastName='Last1'
                        ,LatestCampaign__c=camp1.Id, OwnedBy__c=llc.Name
                        );
      Test.StartTest();
      System.debug('testLead before insert');
      insert ld1;
      Test.StopTest();
      
      Lead checkLd1 = [Select Id, OwnerId
                         From Lead
                        Where Id=:ld1.Id];
       
      PartnerReferral__c partRefDrift = [Select Id, OwnerId, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,Source__c
                                          ,Referral__c
                                      from PartnerReferral__c
                                     Where Lead__c = :ld1.Id];
     // System.assertEquals(Label.TrackRecord_Chat, partRefDrift.Source__c);
     System.assertEquals(camp1.Source_Type__c, partRefDrift.Source__c);
      Referral__c ref = [Select Id, Name
                               ,Campaign__c
                               ,OwnerId
                           From Referral__c
                          Where PartnerReferral__c = :partRefDrift.Id];
      System.assertEquals(ref.OwnerId,queryGrpsDrift[0].Id);
      
   } // testDriftLead 
   */

   /*
   static testMethod void testLeadRecordType() {
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME2);
      Map<String,Schema.RecordTypeInfo> byNameMap = Lead.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfo = byNameMap.get('Oasis Lead Record Type');
      System.assertNotEquals(null,rtInfo);
      
      SalesOrg__c salesOrgCs = new SalesOrg__c(Name=llc.Sales_Org__c, LeadRecordTypeName__c='Oasis Lead Record Type');
      insert salesOrgCs;
      
      Lead ld = new Lead(LastName='LeadLast', FirstName='LeadFirst', Company='LeadCompany');
      
      TrackRecordEntry.checkLeadRecordType(ld, null, llc);
      System.assertEquals(rtInfo.getRecordTypeId(), ld.RecordTypeId);
   } // testLeadRecordType
  */
  
     static testmethod void testStrategicAccount(){      
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Account acct = new Account(Name='Test Acct', ShippingPostalCode='14604', Employees__c=10, NumberOfEmployees=10);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CHANNEL_REFERRAL_ACCOUNT, ObjectHelper.OBJECT_REF_ACCOUNT);
      
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Franchise', National_Account_Code__c='77812', RecordTypeId=rtInfo.getRecordTypeId());
      insert refAcct;

      Campaign camp = new Campaign(Name=CAMP_NAME, LeadSource__c='Campaign LeadSource', Strategic_Account_Partner__c = refAcct.Id, IsActive=true);
      insert camp;


      Lead ld = new Lead(Company='Test Company1', FirstName='First', LastName='Last1'
                           ,LatestCampaign__c=camp.Id
                           ,LeadSource = 'Lead LeadSource'
                           ,NumberOfEmployees=3
                           ,MobilePhone='555-1212'
                           ,Consent_to_Text__c=true
                           ,Consent_to_Text_Date__c=System.now()
                           ,Consent_to_Text_Reason__c = 'Weblead change'
                          // ,Description=TEST_DESC
                           );
      
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Joe', LastName='Contact', Title='All Being, Master of Time, Space and Dimension'
                            //  ,Description=TEST_DESC
                              ,Email='joe@testacct.com'
                              ,LeadSource='Contact LeadSource'
                              ,LatestCampaign__c=camp.Id
                              ,Consent_to_Text__c=true
                              ,MobilePhone='555-1212'
                              ,Consent_to_Text_Date__c=System.now()
                              ,Consent_to_Text_Reason__c = 'Weblead change'
                              ,OwnedBy__c=llc.Name);
      
      Test.startTest();
      insert ld;
      insert ctct;
      Test.stopTest();

      Lead ldtest = [Select Id, Referral_National_Account__c from Lead where Id =: ld.Id];
      system.debug(ldtest.Referral_National_Account__c);
      System.assertEquals(camp.Strategic_Account_Partner__c, ldtest.Referral_National_Account__c);

      Account accTest = [Select Id, Referral_National_Account__c from Account where Id =: acct.id];
      System.assertEquals(camp.Strategic_Account_Partner__c, accTest.Referral_National_Account__c);
   }
    
   static testMethod void testupdateStateCity() {
      Zip_Code_Information__c zci = new Zip_Code_Information__c(Name='111111',DaylightSavings__c=false,TimeZone__c=1,Zip_Code_Key__c='Z11111',State__c='NY',City__c='testCity',AreaCode__c='111', TimeZoneName__c='TestName');
    insert zci;
       Lead ld = new Lead(LastName='updateLeadState',Company='updateLeadStateco',LeadSource='Data.com', PostalCode='111111');
       
       Contact con = new Contact(LastName='updateConState',MailingPostalCode='111111');
       
       Test.startTest();
       insert ld; 
       insert con;
       Test.stopTest();
       
       Lead ldtest = [Select Id, City, State from Lead where Id =: ld.Id];
       System.assertEquals(zci.City__c, ldtest.City);
       System.assertEquals(zci.State__c, ldtest.State);
       
       Contact conTest = [Select Id, MailingCity, MailingState from Contact where Id =: con.id];
       System.assertEquals(zci.City__c, conTest.MailingCity);
       System.assertEquals(zci.State__c, conTest.MailingState);
   }
    //test EE Segment
    static testMethod void testLeadEE() {
    
      LeadLoaderConfig__c llc = LeadLoaderConfig__c.getInstance(LLC_NAME);
      Campaign camp1 = [Select Id, Name, LeadSource__c,Source_Type__c from Campaign where Name=:CAMP_NAME];
      Campaign camp3 = [Select Id, Name, LeadSource__c,Source_Type__c from Campaign where Name=:DRIFTCAMP_NAME];

      TrackRecordEntry.EMPLOYEES_TAG = 'NUMBER_OF_EMPLOYEES:';
      TrackRecordEntry.FRANCHISE_TAG = 'FRANCHISE_CODE:';
      TrackRecordEntry.VENDOR_TAG='VENDOR_ID:';

      // find a queue for testing
      Group[] queryGrps = [Select Id, Type, OwnerId, Name, Email from Group 
                            where Type = 'Queue'
                              and Name in ('NSS Inbound Queue','Oasis Inbound Queue') limit 2];
      System.assertEquals(true, queryGrps.size() > 0);

      LeadRouting__c leadRoute1 = new LeadRouting__c(Name='Default-'+llc.Name,Source__c='Default-'+llc.Name, EmpsMin__c=0,EmpsMax__c=19
                  ,QueueId__c=queryGrps[0].Id, Queue_Name__c=queryGrps[0].Name, Destination__c=queryGrps[0].Name);
      LeadRouting__c leadRoute2 = new LeadRouting__c(Name='Default-'+llc.Name+'-1',Source__c='Default-'+llc.Name, EmpsMin__c=20,EmpsMax__c=99999
                  ,QueueId__c=queryGrps[0].Id, Queue_Name__c=queryGrps[0].Name, Destination__c=queryGrps[0].Name);
      LeadRouting__c[] routings = new LeadRouting__c[]{leadRoute1,leadRoute2};
      insert routings;  
      
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CHANNEL_REFERRAL_ACCOUNT, ObjectHelper.OBJECT_REF_ACCOUNT);
      
      Referral_Account__c refAcct = new Referral_Account__c(Name='Test Franchise', National_Account_Code__c='77812', RecordTypeId=rtInfo.getRecordTypeId());
      insert refAcct;    
      
      Lead ld = new Lead(Company='Test Company2', FirstName='First', LastName='Last2', OwnedBy__c=llc.Name
                        ,LatestCampaign__c=camp1.Id
                        ,LeadSource = 'Lead LeadSource'
                        ,NumberOfEmployees=25
                        );
    
     
      Test.StartTest();
      System.debug('testLead before insert');
      insert ld;
      Test.StopTest();
     
      Lead checkLd1 = [Select Id
                         From Lead
                        Where Id=:ld.Id];

      PartnerReferral__c partRef = [Select Id, Name, FirstName__c, LastName__c, Campaign__c, CampaignId__c
                                          ,Company__c
                                          ,Destination__c
                                          ,LeadSource__c
                                          ,NumberOfEmployees__c
                                          ,Consent_to_Text__c
                                          ,Consent_to_Text_Date__c
                                          ,Franchise_Account_Code__c
                                          ,Vendor_ID__c
                                      from PartnerReferral__c
                                     Where Lead__c = :ld.Id];
                
      Referral__c ref = [Select Id, Name, OwnerId
                               ,Campaign__c
                               ,NbrOfEmployees__c
                               ,SellingLeadSource__c
                           From Referral__c
                          Where SourceLead__c = :ld.Id];
      System.assertEquals(routings[1].QueueId__c, ref.OwnerId);
      
   } // testLeadEE
} // class TrackRecordEntryTest