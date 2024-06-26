/* 
 * Test methods for the ZipBatch class
 *
 * History
 * -------
 * 04/24/2012 Dan Carmen   Created
   06/14/2012 Dan Carmen   Fix for hold outs.
   06/27/2012 Dan Carmen   Update for making email more verbose.
   11/21/2012 Dan Carmen   Modified test because ownership trigger is now firing.
   06/24/2013 Dan Carmen   Use the Emp/Asset on the zip segment instead of zip assignment record
   03/11/2014 Dan Carmen   Changes for NSS
   06/12/2014 Dan Carmen   Changes to handle the lead hold out field
   12/09/2014 Dan Carmen   Simplify queries to attempt to improve performance.
   06/04/2015 Dan Carmen   Changes to work with Referrals
   01/04/2016 Dan Carmen   Make the Lead query generation more dynamic.
   04/05/2016 Dan Carmen   Updates for testing
   07/22/2017 Cindy Freeman     Testing for children accounts
   02/12/2018 Dan Carmen        Configurable limit for contacts.
   05/24/2019 Dan Carmen      Replace MAX_BATCH with a value from the custom setting
   06/18/2019 Dan Carmen      Modify logic to handle multiple record type names
   05/25/2021 Dan Carmen      Added ability to run changes in descending created date order for flexibility
   08/18/2021 Dan Carmen      Changed the method used going into CadenceOwnerCheck
   12/29/2022 Dan Carmen      Added DmlOption to skip Salesforce Duplicate Management
   05/19/2023 Dan Carmen       Fix Client Type query
   08/02/2023 Dan Carmen       Fix for Attempt to de-reference a null object, Zip Code Information isn't always there
   01/02/2024 Dan Carmen       Additional linkage for ZipSegmentCriteriaLink__c for more flexibility
   05/06/2024 Shilpa G       APR0164310: Added method testCltTypeSegCriteria for coverage of Client Type Operand

 */
@isTest
private class ZipBatchTest {
   
   @TestSetup
   public static void setupData() {
      UserHelperTest.setupSalesOrgSetting();
   } // setupData

   static testMethod void testBatch() {
      ZipCheckOwnerTest.setupZipsAndSegments(false);
      //Label.ZipBatch_pushParentToChildren = 'Y';
      ZipQueries.clearSegments();

      Zip_Assignment__c za1 = ZipCheckOwnerTest.zaCore1Seg1;
      Zip_Assignment__c za1a = ZipCheckOwnerTest.zaCore1Seg2;
      Zip_Assignment__c za2 = ZipCheckOwnerTest.zaCore2Seg1;
      Zip_Assignment__c za2b = ZipCheckOwnerTest.zaCore3Seg1;
      Zip_Assignment__c za3 = ZipCheckOwnerTest.zaMMS1Seg1;
      Zip_Assignment__c za3b = ZipCheckOwnerTest.zaMMS1Seg2;
      Zip_Assignment__c za4 = ZipCheckOwnerTest.zaHRS1Seg1;
      Zip_Assignment__c za4b = ZipCheckOwnerTest.zaHRS1Seg2;
      Zip_Assignment__c za5 = ZipCheckOwnerTest.zaPEO1Seg1;
      Zip_Assignment__c za5b = ZipCheckOwnerTest.zaPEO1Seg2;
      Zip_Assignment__c za6 = ZipCheckOwnerTest.zaHNB1Seg1;
      Zip_Assignment__c za7 = ZipCheckOwnerTest.zaHNB1Seg2;
                                                   
      Zip_Assignment__c za8 = ZipCheckOwnerTest.zaWholeInt;

      // don't save now - create the accounts/contacts/leads first
      
      // create accounts,contacts, and Leads
      
      // get the record types
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] sObjectNames = new String[]{'Account','Contact','Lead'};
      RecordTypeHelper.getRecordTypesMap(sObjectNames,null,byName);
      
      // create Core accounts
      Schema.RecordTypeInfo rtCoreAcct = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo rtCoreCtct = byName.get(RecordTypeHelper.CORE_CONTACT);
      
      Account acctCore1 = new Account(Name='Test Core Account 1',ShippingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=null);
      Account acctCore2 = new Account(Name='Test Core Account 2',BillingPostalCode=za2.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=5);
      Account acctCore3 = new Account(Name='Test Core Account 3',ShippingPostalCode=za2.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=10);
      Account acctCore4 = new Account(Name='Test Core Account 4',ShippingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=11);
      Account acctCore5 = new Account(Name='Test Core Account 5',BillingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=100);
      Account acctCore6 = new Account(Name='Test Core Account 6',BillingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=117);      
      // test the holdout flags
      Account acctCore7 = new Account(Name='Test Core Account 7',BillingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=5
                                     ,HRS_Hold_Out__c=true, HRS_Account_Owner__c=ZipCheckOwnerTest.uCore2.Id, HRS_Hold_Out_Expiration__c=Date.today().addDays(7)
                                     ,Premier_PBS_Hold_Out__c=true, Premier_PBS_Account_Owner__c=ZipCheckOwnerTest.uCore2.Id, Premier_PBS_Hold_Out_Expiration__c=Date.today().addDays(7)
                                     ,HNBF_Hold_Out__c=true, HNBF_Account_Owner__c=ZipCheckOwnerTest.uCore2.Id,HNBF_Hold_Out_Expiration__c=Date.today().addDays(7));
      
      //Account[] coreAccts = new Account[]{acctCore7,acctCore6};
      Account[] coreAccts = new Account[]{acctCore1,acctCore2,acctCore3,acctCore4,acctCore5,acctCore6,acctCore7};
      ZipCheckOwner.SKIP_TRIGGERS = true;
      UserHelper.setRunningUserAttributes();
      for (Account acct : coreAccts) {
         AccountMethods.checkZipFields(acct,null);
      }
      
      // create MMS accounts
      Schema.RecordTypeInfo rtMmsAcct = byName.get(RecordTypeHelper.MMS_ACCOUNT);
      Schema.RecordTypeInfo rtMmsCtct = byName.get(RecordTypeHelper.MMS_CONTACT);
     
      Account acctMms1 = new Account(Name='Test MMS Account 1',ShippingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=null);
      Account acctMms2 = new Account(Name='Test MMS Account 2',BillingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=5);
      Account acctMms3 = new Account(Name='Test MMS Account 3',BillingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=10);
      Account acctMms4 = new Account(Name='Test MMS Account 4',BillingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=11);
      Account acctMms5 = new Account(Name='Test MMS Account 5',BillingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=100);
      Account acctMms6 = new Account(Name='Test MMS Account 6',BillingPostalCode=za3.Name, RecordTypeId=rtMmsAcct.getRecordTypeId(), NumberOfEmployees=117);

      //Account[] mmsAccts = new Account[]{acctMms2,acctMms3,acctMms4};
      Account[] mmsAccts = new Account[]{acctMms1,acctMms2,acctMms3,acctMms4,acctMms5,acctMms6};
      for (Account acct : mmsAccts) {
         AccountMethods.checkZipFields(acct,null);
      }
      
      Account[] allAccts = new Account[]{};
      allAccts.addAll(coreAccts);
      allAccts.addAll(mmsAccts);

      insert allAccts;
      
      Account acctCore6child = new Account(Name='Test Core Child 6',BillingPostalCode=za2.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=110,
                                            SalesParent__c = acctCore6.Id);
      insert acctCore6child;
      System.assertEquals(acctCore6.OwnerId, acctCore6child.OwnerId);

      Contact[] ctcts = new Contact[]{};
      // create Contacts for the Accounts
      createContacts(coreAccts,ctcts,rtCoreCtct.getRecordTypeId());
      createContacts(mmsAccts,ctcts,rtMmsCtct.getRecordTypeId());
      
      // to skip the triggers
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = true;
      insert ctcts;
      //ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING = false;
      //ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING = false;

      // create referral accounts and contacts
      Referral_Account__c ra1 = new Referral_Account__c(Name='Test Ref Acct1', Zip_Postal_Code__c=za1.Name, Referral_Source_Business_Type__c='Accounting Firm');
      Referral_Account__c ra2 = new Referral_Account__c(Name='Test Ref Acct2', Zip_Postal_Code__c=za1.Name, Referral_Source_Business_Type__c='Accounting Firm');
      Referral_Account__c ra3 = new Referral_Account__c(Name='Test Ref Acct3', Zip_Postal_Code__c=za2.Name, Referral_Source_Business_Type__c='Accounting Firm');
      Referral_Account__c ra4 = new Referral_Account__c(Name='Test Ref Acct4', Zip_Postal_Code__c=za3.Name, Referral_Source_Business_Type__c='Accounting Firm');
      Referral_Account__c[] refAccts = new Referral_Account__c[]{ra1,ra2,ra3,ra4};
      insert refAccts;
      
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{};
      
      for (Referral_Account__c ra : refAccts) {
         Referral_Contact__c rc1 = new Referral_Contact__c(Name='Test1 '+ra.Name, Referral_Account__c=ra.Id);
         refCtcts.add(rc1);
         Referral_Contact__c rc2 = new Referral_Contact__c(Name='Test2 '+ra.Name, Referral_Account__c=ra.Id);
         refCtcts.add(rc2);
      }
      insert refCtcts;
      
      // create Leads
      Schema.RecordTypeInfo rtCoreLead = byName.get(RecordTypeHelper.CORE_LEAD);
      Schema.RecordTypeInfo rtMmsLead = byName.get(RecordTypeHelper.MMS_LEAD);
      Schema.RecordTypeInfo rtHrsLead = byName.get(RecordTypeHelper.HRS_LEAD);
      Lead leadCore1 = new Lead(LastName='Core Lead 1',Company='Core Lead 1',RecordTypeId=rtCoreLead.getRecordTypeId(),PostalCode=za1.Name);      
      Lead leadCore2 = new Lead(LastName='Core Lead 2',Company='Core Lead 2',RecordTypeId=rtCoreLead.getRecordTypeId(),PostalCode=za2.Name);      
      Lead leadMms1 = new Lead(LastName='MMS Lead 1',Company='MMS Lead 1',RecordTypeId=rtMmsLead.getRecordTypeId(),PostalCode=za3.Name);      
      Lead leadHrs1 = new Lead(LastName='HRS Lead 1',Company='HRS Lead 1',RecordTypeId=rtHrsLead.getRecordTypeId(),PostalCode=za4.Name);
      Lead[] leads = new Lead[]{leadCore1,leadCore2,leadMms1,leadHrs1};
      insert leads;

      ZipCheckOwner.SKIP_TRIGGERS = false;

      // insert after all records are created
      insert ZipCheckOwnerTest.zas;

      // pull out the zip segment records for the hnb zips - set the join criteria to use the emps field
      za6 = [Select Id, Name,HR_Person_Id__c
                   ,Emps_Min__c, Emps_Max__c
                   ,Sales_Org__c, MC_Id__c, Segment_Name__c
                   ,Zip_Segment__r.Id,Zip_Segment__r.JoinCriteria__c
               From Zip_Assignment__c
              Where Id = :za6.Id];
      za6.Zip_Segment__r.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      za6.Zip_Segment__r.Emps_Min__c = 0;
      za6.Zip_Segment__r.Emps_Max__c = 10;

      za7 = [Select Id, Name,HR_Person_Id__c
                   ,Emps_Min__c, Emps_Max__c
                   ,Sales_Org__c, MC_Id__c, Segment_Name__c
                   ,Zip_Segment__r.Id,Zip_Segment__r.JoinCriteria__c
               From Zip_Assignment__c
              Where Id = :za7.Id];
      za7.Zip_Segment__r.JoinCriteria__c = ZipCheckOwner.JOIN_EMPS;
      za7.Zip_Segment__r.Emps_Min__c = 11;
      za7.Zip_Segment__r.Emps_Max__c = 100;

      Zip_Segment__c[] updateSegments = new Zip_Segment__c[]{za6.Zip_Segment__r, za7.Zip_Segment__r};
      TriggerMethods.clearVariables();
      update updateSegments;
      //ZipQueries.clearSegments();
      
       
      // test results
      // make sure change records are created - should be at least one for each Zip Assignment record
      Integer nbrChanges = [Select count() from Zip_Assignment_Change__c];
      System.assertEquals(true,nbrChanges >= ZipCheckOwnerTest.zas.size(), 'nbrChanges='+nbrChanges+' zas='+ZipCheckOwnerTest.zas.size());
      
      ZipBatch zb = new ZipBatch();
      zb.salesOrgOverride = 'N';
      ZipCheckOwner.SKIP_TRIGGERS=true;

      // run process
      Test.startTest();
      Database.executeBatch(zb,ZipCheckOwnerTest.zas.size()*2);
      Test.stopTest();
      
      Map<Id,Zip_Assignment__c> zaMap = new Map<Id,Zip_Assignment__c>([Select Id, Name, User__c, Zip_Segment__c from Zip_Assignment__c]);
      
      // reselect the Zip_Assigment__c records to get the Users
      za1 = zaMap.get(za1.Id);
      za2 = zaMap.get(za2.Id);
      za3 = zaMap.get(za3.Id);
      za3b = zaMap.get(za3b.Id);
      za4 = zaMap.get(za4.Id);
      za4b = zaMap.get(za4b.Id);
      za5 = zaMap.get(za5.Id);
      za5b = zaMap.get(za5b.Id);
      za6 = zaMap.get(za6.Id);
      za7 = zaMap.get(za7.Id);
      za8 = zaMap.get(za8.Id);
      //za9 = zaMap.get(za9.Id);
      
      // reselect the accounts
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c,HNBF_Account_Owner__c
                            ,(SELECT Id ,Name ,RecordTypeId, RecordType.Name ,OwnerId ,HRS_Contact_Owner__c ,Premier_PBS_Contact_Owner__c,HNBF_Contact_Owner__c from Contacts)
                        From Account where Id in :allAccts]);
      
      // test results
      testAccount(acctMap.get(acctCore1.Id),za1.User__c,za4.User__c,za5.User__c,za6.User__c);
      testAccount(acctMap.get(acctCore2.Id),za2.User__c,null,null,null);
      testAccount(acctMap.get(acctCore3.Id),za2.User__c,null,null,null);
      testAccount(acctMap.get(acctCore4.Id),za1.User__c,za4.User__c,za5.User__c,za7.User__c);
      testAccount(acctMap.get(acctCore5.Id),za1a.User__c,za4b.User__c,za5b.User__c,za7.User__c);
      testAccount(acctMap.get(acctCore6.Id),za1a.User__c,za4b.User__c,za5b.User__c,null);
      //testAccount(acctCore6child.Id,za1a.User__c,za4b.User__c,za5b.User__c,null);
      testAccount(acctMap.get(acctCore7.Id),za1.User__c,ZipCheckOwnerTest.uCore2.Id,ZipCheckOwnerTest.uCore2.Id,ZipCheckOwnerTest.uCore2.Id);

      testAccount(acctMap.get(acctMms1.Id),za3.User__c,za4.User__c,za5.User__c,za6.User__c);
      testAccount(acctMap.get(acctMms2.Id),za3.User__c,za4.User__c,za5.User__c,za6.User__c);
      testAccount(acctMap.get(acctMms3.Id),za3.User__c,za4.User__c,za5.User__c,za6.User__c);
      testAccount(acctMap.get(acctMms4.Id),za3.User__c,za4.User__c,za5.User__c,za7.User__c);
      testAccount(acctMap.get(acctMms5.Id),za3b.User__c,za4b.User__c,za5b.User__c,za7.User__c);
      testAccount(acctMap.get(acctMms6.Id),za3b.User__c,za4b.User__c,za5b.User__c,null);

      Map<Id, Referral_Account__c> refAcctMap = new Map<Id, Referral_Account__c>(
              [Select Id, Name, OwnerId, Internal_Wholesaler_Account_Owner__c
                                     ,(Select Id, Name, Internal_Wholesaler_Contact_Owner__c from Referral_Contacts__r)
                                  From Referral_Account__c 
                                 Where Id in :refAccts]);
      
      testRefAccount(refAcctMap.get(ra1.Id),ZipCheckOwnerTest.uHrsInt.Id, ZipCheckOwnerTest.uHrsExt.Id);
      testRefAccount(refAcctMap.get(ra2.Id),ZipCheckOwnerTest.uHrsInt.Id, ZipCheckOwnerTest.uHrsExt.Id);

      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, OwnerId from Lead where Id in :leads]);

      testLead(leadMap.get(leadCore1.Id),za1.User__c);
      testLead(leadMap.get(leadCore2.Id),za2.User__c);
      testLead(leadMap.get(leadMms1.Id),za3.User__c);
      testLead(leadMap.get(leadHrs1.Id),za4.User__c);
      
      Zip_Assignment_Change__c[] changes = [Select Id, Zip_Assignment__c, Zip_Assignment__r.Name, ZipSegment__c
                                            ,Zip_Assignment__r.Sales_Org__c
                                            ,Zip_Assignment__r.Emps_Min__c
                                            ,Accounts_Updated__c, Contacts_Updated__c, Leads_Updated__c, Parent_Accounts_Updated__c 
                                        from Zip_Assignment_Change__c where Processed__c=true
                                         //and OwnershipType__c = :ZipAssignment.CHANGE_OWNER_FIELD
                                         ];
      System.debug('testBatch changes='+changes.size());
      Map<String, Zip_Assignment_Change__c> changeMap = new Map<String, Zip_Assignment_Change__c>();
      for (Zip_Assignment_Change__c change : changes) {
         changeMap.put(change.Zip_Assignment__c+''+change.ZipSegment__c, change);
      }
      
      // check the results on the change records.
      testChangeRecord(changeMap.get(za1.Id+''+za1.Zip_Segment__c),3,6,1);
      testChangeRecord(changeMap.get(za2.Id+''+za2.Zip_Segment__c),2,4,1);
      testChangeRecord(changeMap.get(za2b.Id+''+za2b.Zip_Segment__c),0,0,0);
      testChangeRecord(changeMap.get(za3.Id+''+za3.Zip_Segment__c),4,8,1);
      testChangeRecord(changeMap.get(za4.Id+''+za4.Zip_Segment__c),6,12,1);
      testChangeRecord(changeMap.get(za5.Id+''+za5.Zip_Segment__c),6,12,0);
      testChangeRecord(changeMap.get(za6.Id+''+za6.Zip_Segment__c),4,8,0);
      testChangeRecord(changeMap.get(za7.Id+''+za7.Zip_Segment__c),4,8,0);

      // test if account team members were created
      System.assertEquals(true,[select count() from AccountTeamMember where AccountId=:acctCore1.Id] > 0);
   } // testBatch

   private static void testChangeRecord(Zip_Assignment_Change__c zac, Integer numAccts, Integer numCtcts, Integer numLeads) {
      System.debug('testing change '+zac.Zip_Assignment__r);
      System.assertEquals(numAccts,zac.Accounts_Updated__c);
      System.assertEquals(numCtcts,zac.Contacts_Updated__c);
      System.assertEquals(numLeads,zac.Leads_Updated__c);
      //System.assertEquals(numParents, zac.Parent_Accounts_Updated__c);
   } // testChangeRecord
   
   private static void testLead(Lead l, Id ownerId) {
      //Lead l = [Select Id, Name, OwnerId from Lead where Id=:leadId];
      System.debug('testLead for '+l.Name);
      System.assertEquals(ownerId, l.OwnerId);
   } // testLead
   
   private static void testAccount(Account acct, Id ownerId, Id hrsOwnerId, Id pasOwnerId, Id hnbfOwnerId) {
      System.debug('testAccount for '+acct.Name);
      System.debug('testAccount ownerId='+acct.OwnerId);
      System.assertEquals(ownerId,acct.OwnerId);
      System.assertEquals(hrsOwnerId,acct.HRS_Account_Owner__c);
      System.assertEquals(pasOwnerId,acct.Premier_PBS_Account_Owner__c);
      System.assertEquals(hnbfOwnerId,acct.HNBF_Account_Owner__c);
      // check the contacts
      // 2 contacts for each account
      System.assertEquals(2,acct.Contacts.size());
      for (Contact ctct : acct.Contacts) {
         System.assertEquals(ownerId,ctct.OwnerId);
         System.assertEquals(hrsOwnerId,ctct.HRS_Contact_Owner__c);
         System.assertEquals(pasOwnerId,ctct.Premier_PBS_Contact_Owner__c);
         System.assertEquals(hnbfOwnerId,ctct.HNBF_Contact_Owner__c);
      }
   } // testAccount
   
   private static void testRefAccount(Referral_Account__c ra, Id wholesalesIntId, Id wholesaleExtId) {
      System.debug('testRefAccount for '+ra.Name);
      System.assertEquals(wholesalesIntId,ra.Internal_Wholesaler_Account_Owner__c);
      // check the contacts
      // 2 contacts for each account
      System.assertEquals(2,ra.Referral_Contacts__r.size());
      for (Referral_Contact__c rc : ra.Referral_Contacts__r) {
         System.assertEquals(wholesalesIntId,rc.Internal_Wholesaler_Contact_Owner__c);
      }
   } // testRefAccount
   
   private static void createContacts(Account[] accts, Contact[] ctcts, Id rtId) {
      for (Account acct : accts) {
         ctcts.add(new Contact(RecordTypeId=rtId,AccountId=acct.Id,FirstName='Jimmy',LastName=acct.Name
                               ,HRS_Contact_Owner__c=acct.HRS_Account_Owner__c
                               ,Premier_PBS_Contact_Owner__c=acct.Premier_PBS_Account_Owner__c
                               ,HNBF_Contact_Owner__c=acct.HNBF_Account_Owner__c));
         ctcts.add(new Contact(RecordTypeId=rtId,AccountId=acct.Id,FirstName='Ashley',LastName=acct.Name
                               ,HRS_Contact_Owner__c=acct.HRS_Account_Owner__c
                               ,Premier_PBS_Contact_Owner__c=acct.Premier_PBS_Account_Owner__c
                               ,HNBF_Contact_Owner__c=acct.HNBF_Account_Owner__c));
      }
   } // createContacts

 
   static testMethod void testScheduler() {
      TestHelper.testScheduler('testZipBatch', new ZipBatch());
   } // testScheduler

   static testMethod void testLimits() {
      UserHelperTest.setupSalesOrgSetting();
      RecordTypeHelperTest.setupRecordType();
      ZipCheckOwnerTest.setupSegments();
      
      // so the trigger fires.
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_SFDC,runningUser.Name);

      // select test users
      User uCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :UserInfo.getUserId() limit 1];
      User uCore2 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id and Id != :UserInfo.getUserId() limit 1];

      // make sure there are no change records
      System.assertEquals(0,[Select count() from Zip_Assignment_Change__c]);
      
      Org_Unit__c district1 = new Org_Unit__c(Name='1',Org_Type__c='District',Org_Unit_Name__c='Test District');
      insert district1;
      
      ZipTerritory__c territory1 = new ZipTerritory__c(District__c=district1.Id, Name='Territory1', TerritoryRep__c=uCore.Id);
      insert territory1;
      
      // create Zip Assignment records
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name='14514',HR_Person_Id__c=uCore.HR_Person_Id__c
                                                   ,Emps_Min__c=0, Emps_Max__c=100
                                                   ,Sales_Org__c=uCore.Sales_Org__c, MC_Id__c='TestCore', Segment_Name__c=ZipCheckOwnerTest.coreSeg1.Name
                                                   ,Zip_Segment__c=ZipCheckOwnerTest.coreSeg1.Id
                                                   ,ZipTerritory__c=territory1.Id);
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1};
      // don't save now - create the accounts
      
      // create accounts
      
      // get the record types
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      String[] sObjectNames = new String[]{'Account'};
      RecordTypeHelper.getRecordTypesMap(sObjectNames,null,byName);
      
      // create Core accounts
      Schema.RecordTypeInfo rtCoreAcct = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Account[] accts = new Account[]{};
      for (Integer cnt=0; cnt<40; cnt++) {
         Account acct = new Account(Name='Test Core Account '+cnt,OwnerId=uCore2.Id, ShippingPostalCode=za1.Name, RecordTypeId=rtCoreAcct.getRecordTypeId(), NumberOfEmployees=5);
         accts.add(acct);
      }

      insert accts;
     
      // insert after all records are created
      insert zas;
      
      // test results
      // make sure change record is created - should be one for each Zip Assignment record
      System.assertEquals(1,[Select count() from Zip_Assignment_Change__c where Zip_Assignment__c=:za1.Id and ZipSegment__c=:za1.Zip_Segment__c]);
      
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ZipBatch', Active__c=true, BatchSize__c=1, Minutes_till_Launch__c=20);
      insert abc;
      System.assertEquals(20,ZipBatch.getMaxBatch());
      
      ZipBatch zb = new ZipBatch();
      zb.sortDescending = true;
      // set a low batch size - to force it to create a new change record
      //zb.MAX_BATCH = 20;

      // run process
      Test.startTest();
      Database.executeBatch(zb,10);
      Test.stopTest();
      
      // reselect the Zip_Assigment__c records to get the Users
      za1 = [Select Id, Name, User__c from Zip_Assignment__c where Id = :za1.Id];

      //System.assertEquals(2,[Select count() from Zip_Assignment_Change__c where Zip_Assignment__c=:za1.Id]);
      //testChangeRecord(za1.Id,20,0,0);
   } // testLimits
   
   static testMethod void testRecordTypeIdString() {
      String[] recordTypeNames = new String[]{RecordTypeHelper.CORE_ACCOUNT, RecordTypeHelper.MMS_ACCOUNT};
      ZipBatch zb = new ZipBatch();
      /*
      String recordTypeString = zb.getRecordTypeIdString(ObjectHelper.OBJECT_ACCOUNT, recordTypeNames);
      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      RecordTypeInfo coreRT = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT);
      String checkStr = '\''+coreRT.getRecordTypeId()+'\'';
      System.assertEquals(true,recordTypeString.contains(checkStr));
      RecordTypeInfo mmsRT = byNameMap.get(RecordTypeHelper.MMS_ACCOUNT);
      checkStr = '\''+mmsRT.getRecordTypeId()+'\'';
      System.assertEquals(true,recordTypeString.contains(checkStr));
      */
   } // testRecordTypeIdString

   static testMethod void testAddCriteria() {
      ZipBatch zb = new ZipBatch();
      ZipSegmentCriteria__c criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_BOOLEAN, FieldAPIName__c='CSSR_Segment__c', Values__c='True');
      ZipSegmentCriteria__c criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_BOOLEAN, FieldAPIName__c='CSSR_Segment__c', Values__c='False');
      String query = zb.addCriteria(criteria1);
      System.assertEquals(true, query.contains('CSSR_Segment__c=true'));
      query = zb.addCriteria(criteria2);
      System.assertEquals(true, query.contains('CSSR_Segment__c=false'));
       
      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c='CAID');
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_NOT_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c='CAID');
      query = zb.addCriteria(criteria1);
      System.assertEquals(true, query.contains('Paychex_CAID__c=\'CAID\''));
      query = zb.addCriteria(criteria2);
      System.assertEquals(true, query.contains('Paychex_CAID__c!=\'CAID\''));
       
      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c='CAID,CEID');
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_NOT_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c='CAID,CEID');
      query = zb.addCriteria(criteria1);
      System.assertEquals(true, query.contains('Paychex_CAID__c IN (\'CAID\',\'CEID\')'));
      query = zb.addCriteria(criteria2);
      System.assertEquals(true, query.contains('Paychex_CAID__c NOT IN (\'CAID\',\'CEID\')'));
       
      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c=null);
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_NOT_EQUALS, FieldAPIName__c='Paychex_CAID__c', Values__c=null);
      query = zb.addCriteria(criteria1);
      System.assertEquals(true, query.contains('Paychex_CAID__c=null'));
      query = zb.addCriteria(criteria2);
      System.assertEquals(true, query.contains('Paychex_CAID__c!=null'));

      criteria1 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      criteria2 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria3 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_NOT_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      ZipSegmentCriteria__c criteria4 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_NOT_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria5 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_GREATER, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      ZipSegmentCriteria__c criteria6 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_GREATER, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria7 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_GREATER_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      ZipSegmentCriteria__c criteria8 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_GREATER_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria9 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_LESS_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      ZipSegmentCriteria__c criteria10 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_LESS_EQUALS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria11 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_LESS, FieldAPIName__c='NumberOfEmployees', Number1__c=5);
      ZipSegmentCriteria__c criteria12 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR, Operator__c=ZipCheckOwner.OP_LESS, FieldAPIName__c='NumberOfEmployees', Number1__c=0);
      ZipSegmentCriteria__c criteria13 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=5, Number2__c=7);
      ZipSegmentCriteria__c criteria14 = new ZipSegmentCriteria__c(FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=4);
      // these need to be saved so the formula field calculates
      insert new ZipSegmentCriteria__c[]{criteria1,criteria2,criteria3,criteria4,criteria5,criteria6,criteria7,criteria8,criteria9,criteria10,criteria11,criteria12,criteria13,criteria14};
      
      Map<Id,ZipSegmentCriteria__c> criteriaMap = new Map<Id,ZipSegmentCriteria__c>([Select FieldAPIName__c, FieldType__c, Operator__c, NumberFormat__c
                                                                                           ,Number1__c, Number2__c, SOQLNullOkay__c, SOQLOperator__c, Values__c
                                                                                       From ZipSegmentCriteria__c]);

      query = zb.addCriteria(criteriaMap.get(criteria1.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees=5)'));
      query = zb.addCriteria(criteriaMap.get(criteria2.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees=0 or NumberOfEmployees=null)'));
      query = zb.addCriteria(criteriaMap.get(criteria3.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees!=5)'));
      query = zb.addCriteria(criteriaMap.get(criteria4.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees!=0)'));       
      query = zb.addCriteria(criteriaMap.get(criteria5.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees>5)'));
      query = zb.addCriteria(criteriaMap.get(criteria6.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees>0)'));       
      query = zb.addCriteria(criteriaMap.get(criteria7.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees>=5)'));
      query = zb.addCriteria(criteriaMap.get(criteria8.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees>=0)'));       
      query = zb.addCriteria(criteriaMap.get(criteria9.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees<=5 or NumberOfEmployees=null)'));
      query = zb.addCriteria(criteriaMap.get(criteria10.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees<=0 or NumberOfEmployees=null)'));       
      query = zb.addCriteria(criteriaMap.get(criteria11.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees<5 or NumberOfEmployees=null)'));
      query = zb.addCriteria(criteriaMap.get(criteria12.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees<0 or NumberOfEmployees=null)'));       

      query = zb.addCriteria(criteriaMap.get(criteria13.Id));
      System.assertEquals(true, query.contains('NumberOfEmployees>=5 and NumberOfEmployees<=7)'));
      query = zb.addCriteria(criteriaMap.get(criteria14.Id));
      System.assertEquals(true, query.contains('(NumberOfEmployees>=0 and NumberOfEmployees<=4) or NumberOfEmployees=null)'));

   } // testAddCriteria
    
   static testMethod void testSegmentCriteria() {
      String zip1='14624';
      String zip2='14625';
      Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo leadRt = RecordTypeHelper.getRecordType(Label.RT_Core_Lead, ObjectHelper.OBJECT_LEAD);
      Schema.RecordTypeInfo refAcctRt = RecordTypeHelper.getRecordType('Core Referral Source Record Type', ObjectHelper.OBJECT_REF_ACCOUNT);
      
      ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
      Zip_Segment__c seg_a = ZipCheckOwnerTest.createSegment(UserHelper.SO_CORE, null,null, '1','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_a.LeadRecordTypeName__c = Label.RT_Core_Lead;
      seg_a.RfrlAcctDefault__c=true;
      seg_a.RfrlRecordTypes__c = 'Core Referral Source Record Type';
      
      Zip_Segment__c seg_b = ZipCheckOwnerTest.createSegment(UserHelper.SO_CORE, null,null, '2','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_b.LeadRecordTypeName__c = Label.RT_Core_Lead;
      seg_b.RfrlAcctDefault__c=true;
      seg_b.RfrlRecordTypes__c = 'Core Referral Source Record Type';
       
      insert ZipCheckOwnerTest.segments;
           
      ZipSegmentCriteria__c criteria1a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=20);
      ZipSegmentCriteria__c criteria1b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=21, Number2__c=999);
      ZipSegmentCriteria__c criteria2a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan1,Dan2');
      ZipSegmentCriteria__c criteria2b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan3,Dan4');
      ZipSegmentCriteria__c criteria3a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Rochester');
      ZipSegmentCriteria__c criteria3b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Buffalo');
      ZipSegmentCriteria__c criteria4a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Mailbox');
      ZipSegmentCriteria__c criteria4b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Pony Express');
      insert new ZipSegmentCriteria__c[]{criteria1a,criteria1b,criteria2a,criteria2b,criteria3a,criteria3b,criteria4a,criteria4b};

      ZipSegmentCriteriaLink__c[] links = new ZipSegmentCriteriaLink__c[]{};
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria1a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria2a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria3a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria4a.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria1b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria2b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria3b.Id));
      links.add(new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_b.Id, ZipSegmentCriteria__c=criteria4b.Id));
      insert links;
          
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
      User defRep = reps[0];
      
      User rep1 = reps[1];
      User rep2 = reps[2];
      
      Lead ld1 = new Lead(OwnerId=defRep.Id, Company='Lead1',LastName='Last1', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='Mailbox');
      Lead ld2 = new Lead(OwnerId=defRep.Id, Company='Lead2',LastName='Last2', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='SomethingElse');
      Lead ld3 = new Lead(OwnerId=defRep.Id, Company='Lead3',LastName='Last3', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=42, LeadSource='Pony Express');
      Lead ld4 = new Lead(OwnerId=defRep.Id, Company='Lead3',LastName='Last3', PostalCode=zip2, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=42, LeadSource='Pony Express');
      insert new Lead[]{ld1,ld2,ld3,ld4};
      
      Account acct1 = new Account(OwnerId=defRep.Id, Name='Account1', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan1', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct2 = new Account(OwnerId=defRep.Id, Name='Account2', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan7', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct3 = new Account(OwnerId=defRep.Id, Name='Account3', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=42, Type='Dan3', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1);
      Account acct4 = new Account(OwnerId=defRep.Id, Name='Account3', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=42, Type='Dan3', ShippingPostalCode=zip2, Owner_Zip_Code__c=zip1);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2,acct3,acct4};
          
      Referral_Account__c refAcct1 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct1', Zip_Postal_Code__c=zip1, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct2 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct2', Zip_Postal_Code__c=zip1, City__c='Buffalo', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct3 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct3', Zip_Postal_Code__c=zip1, City__c='Syracuse', RecordTypeId=refAcctRt.getRecordTypeId());
      Referral_Account__c refAcct4 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct4', Zip_Postal_Code__c=zip2, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId());
      insert new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
          
      Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District Dan', Org_Type__c='District', Sales_Org__c=UserHelper.SO_CORE);
      insert dist;
      
      ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      ZipTerritory__c terr_b = new ZipTerritory__c(Name='Territory b', District__c=dist.Id, TerritoryRep__c=rep2.Id, Zip_Segment__c=seg_b.Id);
      insert new ZipTerritory__c[]{terr_a,terr_b};
      
      Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      //Zip_Assignment__c za_b = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr_b.Id, User__c=rep2.Id, Zip_Segment__c=seg_b.Id);
      //insert new Zip_Assignment__c[]{za_a, za_b};
      insert new Zip_Assignment__c[]{za_a};
         
      System.assertEquals(1, [select count() from Zip_Assignment_Change__c]);
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ZipBatch', Active__c=true, BatchSize__c=1);
      insert abc;
      
      ZipBatch zb = new ZipBatch();
      Test.startTest();
      Database.executeBatch(zb,1);
      Test.stopTest();
       
      Map<Id,Lead> ldMap = new Map<Id,Lead>([Select Id, Name, OwnerId from Lead]);
      System.assertEquals(rep1.Id, ldMap.get(ld1.Id).OwnerId);
      System.assertEquals(defRep.Id, ldMap.get(ld2.Id).OwnerId);
      System.assertEquals(defRep.Id, ldMap.get(ld3.Id).OwnerId);
      System.assertEquals(defRep.Id, ldMap.get(ld4.Id).OwnerId);

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId from Account]);
      System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct2.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct3.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct4.Id).OwnerId);
       
      Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name, OwnerId from Referral_Account__c]);
      System.assertEquals(rep1.Id, refAcctMap.get(refAcct1.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct2.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct3.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct4.Id).OwnerId);
   } // testSegmentCriteria
    
  /* static testMethod void testAccountSegment() {
      ZipBatch zb = new ZipBatch();
      String query = zb.getAcctSegmentQuery('All');
      System.assertEquals('',query);
      query = zb.getAcctSegmentQuery(ZipCheckOwner.TYPE_PROSPECT+';'+ZipCheckOwner.TYPE_CLIENT+';'+ZipCheckOwner.TYPE_LOSTCLIENT);
      System.assertEquals(' and ( (CurrentClient__c=false and LostClient__c=false)  or  (CurrentClient__c=true and LostClient__c=false)  or  LostClient__c=true ) ',query);
      query = zb.getAcctSegmentQuery(ZipCheckOwner.TYPE_CLIENT+';'+ZipCheckOwner.TYPE_LOSTCLIENT);
      System.assertEquals(' and ( (CurrentClient__c=true and LostClient__c=false)  or  LostClient__c=true ) ',query);
      query = zb.getAcctSegmentQuery(ZipCheckOwner.TYPE_PROSPECT);
      System.assertEquals(' and ( (CurrentClient__c=false and LostClient__c=false) ) ',query);
   } // testAccountSegment */

    static testMethod void testAccountSegment1() {
       Zip_Segment__c zipSeg = new Zip_Segment__c(Name = 'Associate Rep', Account_Segmentation_Type_Multi__c= 'All');
       insert zipSeg;
       
       String acctSegment = zipSeg.Account_Segmentation_Type_Multi__c;
       
       
      ZipBatch zb = new ZipBatch();
      String query = zb.getAcctSegmentQuery(zipSeg);
      System.assertEquals('',query);
  /*    query = ZipCheckOwner.TYPE_PROSPECT+';'+ZipCheckOwner.TYPE_CLIENT+';'+ZipCheckOwner.TYPE_LOSTCLIENT;
      System.assertEquals(' and ( (CurrentClient__c=false and LostClient__c=false)  or  (CurrentClient__c=true and LostClient__c=false)  or  LostClient__c=true ) ',query);
      query = ZipCheckOwner.TYPE_CLIENT+';'+ZipCheckOwner.TYPE_LOSTCLIENT;
      System.assertEquals(' and ( (CurrentClient__c=true and LostClient__c=false)  or  LostClient__c=true ) ',query);
      query = ZipCheckOwner.TYPE_PROSPECT;
      System.assertEquals(' and ( (CurrentClient__c=false and LostClient__c=false) ) ',query);
   } // testAccountSegment1 */
   }   
    
   static testMethod void testSegmentCriteria2() {
      String zip1='14624';
      String zip2='14625';
      Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo leadRt = RecordTypeHelper.getRecordType(Label.RT_Core_Lead, ObjectHelper.OBJECT_LEAD);
      Schema.RecordTypeInfo refAcctRt = RecordTypeHelper.getRecordType('Core Referral Source Record Type', ObjectHelper.OBJECT_REF_ACCOUNT);
      
      ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
      Zip_Segment__c seg_a = ZipCheckOwnerTest.createSegment(UserHelper.SO_CORE, null,null, '1','OwnerId', 'Hold_Out__c', 'Core Account Record Type',null
                              ,'OwnerId','Hold_Out__c','OwnerId','Hold_Out__c','OwnerId','Hold_Out__c');
      seg_a.LeadRecordTypeName__c = Label.RT_Core_Lead;
      seg_a.RfrlAcctDefault__c=true;
      seg_a.RfrlRecordTypes__c = 'Core Referral Source Record Type';
      
      insert seg_a;
           
      ZipSegmentCriteria__c criteria1a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=20);
      ZipSegmentCriteria__c criteria1b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=21, Number2__c=999);
      ZipSegmentCriteria__c criteria2a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan1,Dan2');
      ZipSegmentCriteria__c criteria2b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan3,Dan4');
      ZipSegmentCriteria__c criteria3a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Rochester');
      ZipSegmentCriteria__c criteria3b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=false, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='City__c', Values__c='Buffalo');
      ZipSegmentCriteria__c criteria4a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Mailbox');
      ZipSegmentCriteria__c criteria4b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Pony Express');
      ZipSegmentCriteria__c criteria5a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Ethnicity__c', Values__c='HA1');
      ZipSegmentCriteria__c criteria5b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=true
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Ethnicity__c', Values__c='HA2');
      insert new ZipSegmentCriteria__c[]{criteria1a,criteria1b,criteria2a,criteria2b,criteria3a,criteria3b,criteria4a,criteria4b,criteria5a,criteria5b};

      ZipSegmentCriteriaLink__c link1a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria1a.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_OR, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_AND);
      ZipSegmentCriteriaLink__c link1b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria1b.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_OR, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_OR);
      ZipSegmentCriteriaLink__c link2a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria2a.Id);
      ZipSegmentCriteriaLink__c link2b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria2b.Id);
      ZipSegmentCriteriaLink__c link3a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria3a.Id);
      ZipSegmentCriteriaLink__c link3b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria3b.Id);
      ZipSegmentCriteriaLink__c link4a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria4a.Id);
      ZipSegmentCriteriaLink__c link4b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria4b.Id);
      ZipSegmentCriteriaLink__c link5a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria5a.Id);
      ZipSegmentCriteriaLink__c link5b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg_a.Id, ZipSegmentCriteria__c=criteria5b.Id);
      insert new ZipSegmentCriteriaLink__c[]{link1a,link1b,link2a,link2b,link3a,link3b,link4a,link4b,link5a,link5b};          
           
      // these will be ANDS
      link2a.ZipLinkJoin__c = link1a.Id;
      link3a.ZipLinkJoin__c = link1a.Id;
      link4a.ZipLinkJoin__c = link1a.Id;
      link5a.ZipLinkJoin__c = link1a.Id;
      // these will be ORS
      link2b.ZipLinkJoin__c = link1b.Id;
      link3b.ZipLinkJoin__c = link1b.Id;
      link4b.ZipLinkJoin__c = link1b.Id;
      link5b.ZipLinkJoin__c = link1b.Id;
      update new ZipSegmentCriteriaLink__c[]{link2a,link2b,link3a,link3b,link4a,link4b,link5a,link5b};          

      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
      User defRep = reps[0];
      
      User rep1 = reps[1];
      User rep2 = reps[2];
      
      // this should match group 1
      Lead ld1 = new Lead(OwnerId=defRep.Id, Company='Lead1',LastName='Last1', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='Mailbox', Ethnicity__c='HA1');
      Lead ld2 = new Lead(OwnerId=defRep.Id, Company='Lead2',LastName='Last2', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='SomethingElse', Ethnicity__c='HA1');
      // only one OR criteria matches
      Lead ld3 = new Lead(OwnerId=defRep.Id, Company='Lead3',LastName='Last3', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=42, LeadSource='Pony Express', Ethnicity__c='HA2');
      Lead ld4 = new Lead(OwnerId=defRep.Id, Company='Lead4',LastName='Last4', PostalCode=zip1, RecordTypeId=leadRt.getRecordTypeId(), NumberOfEmployees=10, LeadSource='Camel Express', Ethnicity__c='HA4');
      insert new Lead[]{ld1,ld2,ld3,ld4};
      
      Account acct1 = new Account(OwnerId=defRep.Id, Name='Account1', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan1', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1, Ethnicity__c='HA1');
      Account acct2 = new Account(OwnerId=defRep.Id, Name='Account2', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan7', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1, Ethnicity__c='HA1');
      Account acct3 = new Account(OwnerId=defRep.Id, Name='Account3', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=42, Type='Dan3', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1, Ethnicity__c='HA1');
      // only one OR criteria matches
      Account acct4 = new Account(OwnerId=defRep.Id, Name='Account4', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=10, Type='Dan5', ShippingPostalCode=zip2, Owner_Zip_Code__c=zip1, Ethnicity__c='HA2');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert new Account[]{acct1,acct2,acct3,acct4};
          
      Referral_Account__c refAcct1 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct1', Zip_Postal_Code__c=zip1, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId(), Ethnicity__c='HA1');
      Referral_Account__c refAcct2 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct2', Zip_Postal_Code__c=zip1, City__c='Buffalo', RecordTypeId=refAcctRt.getRecordTypeId(), Ethnicity__c='HA1');
      Referral_Account__c refAcct3 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct3', Zip_Postal_Code__c=zip1, City__c='Syracuse', RecordTypeId=refAcctRt.getRecordTypeId(), Ethnicity__c='HA1');
      Referral_Account__c refAcct4 = new Referral_Account__c(OwnerId=defRep.Id, Name='RefAcct4', Zip_Postal_Code__c=zip1, City__c='Rochester', RecordTypeId=refAcctRt.getRecordTypeId(), Ethnicity__c='HA2');
      insert new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4};
          
      Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District Dan', Org_Type__c='District', Sales_Org__c=UserHelper.SO_CORE);
      insert dist;
      
      ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      insert new ZipTerritory__c[]{terr_a};
      
      Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_CORE, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_a.Id);
      insert new Zip_Assignment__c[]{za_a};
         
      Assert.areEqual(1, [select count() from Zip_Assignment_Change__c]);
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ZipBatch', Active__c=true, BatchSize__c=1);
      insert abc;
      
      ZipBatch zb = new ZipBatch();
      Test.startTest();
      Database.executeBatch(zb,1);
      Test.stopTest();
      
      System.debug('testSegmentCriteria2 defRep='+defRep.Id+' rep1='+rep1.Id);
      Map<Id,Lead> ldMap = new Map<Id,Lead>([Select Id, Name, OwnerId from Lead]);
      System.assertEquals(rep1.Id, ldMap.get(ld1.Id).OwnerId);
      System.assertEquals(defRep.Id, ldMap.get(ld2.Id).OwnerId);
      System.assertEquals(rep1.Id, ldMap.get(ld3.Id).OwnerId);
      System.assertEquals(defRep.Id, ldMap.get(ld4.Id).OwnerId);

      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId from Account]);
      System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OwnerId);
      System.assertEquals(defRep.Id, acctMap.get(acct2.Id).OwnerId);
      System.assertEquals(rep1.Id, acctMap.get(acct3.Id).OwnerId);
      System.assertEquals(rep1.Id, acctMap.get(acct4.Id).OwnerId);
       
      Map<Id,Referral_Account__c> refAcctMap = new Map<Id,Referral_Account__c>([Select Id, Name, OwnerId from Referral_Account__c]);
      System.assertEquals(rep1.Id, refAcctMap.get(refAcct1.Id).OwnerId);
      System.assertEquals(rep1.Id, refAcctMap.get(refAcct2.Id).OwnerId);
      System.assertEquals(defRep.Id, refAcctMap.get(refAcct3.Id).OwnerId);
      System.assertEquals(rep1.Id, refAcctMap.get(refAcct4.Id).OwnerId);
   } // testSegmentCriteria2
    
    static testMethod void testCltTypeSegCriteria() {
      String zip1='14624';
      Schema.RecordTypeInfo acctRt = RecordTypeHelper.getRecordType('Core Account Record Type', ObjectHelper.OBJECT_ACCOUNT);
      
      ZipCheckOwnerTest.segments = new Zip_Segment__c[]{};
      Zip_Segment__c seg_peo = ZipCheckOwnerTest.createSegment(UserHelper.SO_PEO, 0, 9999,'1','OasisPEOAccountOwner__c', 'OasisPEOHoldOut__c','Core Account Record Type',Label.AT_PEO_ASO,'OasisPEOOwner__c','Hold_Out__c',null,null,null,null);  
      seg_peo.Account_Segmentation_Type_Multi__c = 'Client';
      seg_peo.ClientType__c = 'Oasis Client';
      seg_peo.ClientTypeOperand__c = 'NOT EQUALS';
      insert ZipCheckOwnerTest.segments;
           
      User[] reps = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 7 ];
      User defRep = reps[0];      
      User rep1 = reps[1];
      
      Account acct1 = new Account(OwnerId=defRep.Id, Name='Account1', RecordTypeId=acctRt.getRecordTypeId(), NumberOfEmployees=15, Type='HR Solutions FLEX Client', ShippingPostalCode=zip1, Owner_Zip_Code__c=zip1,Bis_ID__c=1234,First_Run_Date__c=system.today());
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct1;
          
      Org_Unit__c dist = new Org_Unit__c(Name='10', Org_Unit_Name__c='District PEO', Org_Type__c='District', Sales_Org__c=UserHelper.SO_PEO);
      insert dist;
      
      ZipTerritory__c terr_a = new ZipTerritory__c(Name='Territory a', District__c=dist.Id, TerritoryRep__c=rep1.Id, Zip_Segment__c=seg_peo.Id);
      insert new ZipTerritory__c[]{terr_a};
      
      Zip_Assignment__c za_a = new Zip_Assignment__c(Name=zip1, District__c=dist.Id, Sales_Org__c=UserHelper.SO_PEO, ZipTerritory__c=terr_a.Id, User__c=rep1.Id, Zip_Segment__c=seg_peo.Id);
      insert new Zip_Assignment__c[]{za_a};
         
      System.assertEquals(1, [select count() from Zip_Assignment_Change__c]);
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='ZipBatch', Active__c=true, BatchSize__c=1);
      insert abc;
      
      ZipBatch zb = new ZipBatch();
      Test.startTest();
      Database.executeBatch(zb,1);
      Test.stopTest();
       
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId, OasisPEOAccountOwner__c from Account]);
      System.assertEquals(rep1.Id, acctMap.get(acct1.Id).OasisPEOAccountOwner__c);
   } // testCltTypeSegCriteria
} // class ZipBatchTest