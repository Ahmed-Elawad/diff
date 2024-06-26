/* Test Methods for the ZipCheckOwner class
   
  History
  -------
  05/25/2012 Dan Carmen   Created from AccountCheckOwnerTest
  12/12/2012 Dan Carmen   Added asset criteria
  06/08/2018 Cindy Freeman	set Contact4 sales_contact = false
  01/04/2022 Dan Carmen         Move logic from the AccountAfter trigger to ZipCheckOwner
  01/02/2024 Dan Carmen        Additional linkage for ZipSegmentCriteriaLink__c for more flexibility
  
 */
@isTest
private class ZipCheckOwnerTest2 {
   @testSetup
   public static void setupData() {
      ZipCheckOwnerTest.setupData();
      ZipCheckOwnerTest.setupZipsAndSegments(true);
   } // setupData
    
   static testmethod void testAccountCheckOwners() {
   	//DataFluxDeltaServiceTest.disableDeltaTriggers();
   	
      System.debug('Start testAccountCheckOwners');
      // so the trigger will fire for System Administrators
      ZipCheckOwner.EXCLUDE_PROFILE_NAME_LIST = new String[]{'System Administrator API-Relational Junction'};
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      
      RecordTypeHelper.getRecordTypesMap(ZipCheckOwner.OBJECT_NAMES,ZipCheckOwner.RECORDTYPE_NAMES,byId,byName);
     
      Schema.RecordTypeInfo rtCore = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo rtMms = byName.get(RecordTypeHelper.MMS_ACCOUNT);
      Schema.RecordTypeInfo rtCtctCore = byName.get(RecordTypeHelper.CORE_CONTACT);
      Schema.RecordTypeInfo rtCtctMms = byName.get(RecordTypeHelper.MMS_CONTACT);

      //Profile p = [select id from profile where name='System Administrator'];
      User user1 = [select id, isActive from User where Profile.Name='System Administrator' and isActive=true and Id != :UserInfo.getUserId() limit 1];
      User user2 = [select Id, isActive from User where isActive=true and Id != :UserInfo.getUserId() and Id != :user1.Id and Profile.Name like :Utilities.PROF_CORE_SALES+'%' limit 1];
      
      System.debug('user1='+user1.Id);
      
      //***************************************
      System.debug('testAccountCheckOwners Check that nothing changes with unrecognized Record Type');
      // check to make sure nothing changes for different record type
      Schema.RecordTypeInfo acctTestRt = RecordTypeHelper.getRecordType('System Administration Account', 'Account');
      Schema.RecordTypeInfo ctctTestRt = RecordTypeHelper.getRecordType('Admin','Contact');

      // store the userIds used to create the zip codes
      Id[] excludeUserIds = new Id[]{};
      String zip1 = '12345';
      Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,excludeUserIds);
      String zip2 = '12346';
      Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList(zip2,excludeUserIds);

      // Get the first segment
      Zip_Assignment__c zaCore1 = ZipCheckOwnerTest.getZipBySegment(zaMapList1.get(UserHelper.SO_CORE), ZipCheckOwnerTest.coreSeg1.Id);
      Zip_Assignment__c zaCore2 = ZipCheckOwnerTest.getZipBySegment(zaMapList2.get(UserHelper.SO_CORE), ZipCheckOwnerTest.coreSeg1.Id);

      User uCore1 = zaCore1.User__r;
      User uCore2 = zaCore2.User__r;
      System.debug('testAccountCheckOwners zaCore1='+zaCore1.Name+' segment='+zaCore1.Segment_Name__c+' userId='+uCore1.Id+' user='+uCore1.Name);
      System.debug('testAccountCheckOwners zaCore2='+zaCore1.Name+' segment='+zaCore2.Segment_Name__c+' userId='+uCore2.Id+' user='+uCore2.Name);
      User uMms1 = zaMapList1.get(UserHelper.SO_MMS).get(0).User__r;
      User uMms2 = zaMapList2.get(UserHelper.SO_MMS).get(0).User__r;
      System.debug('testAccountCheckOwners mms1='+uMms1.Id+' mms2='+uMms2.Id);

      Zip_Assignment__c zaHrs1 = ZipCheckOwnerTest.getZipBySegment(zaMapList1.get(UserHelper.SO_401), ZipCheckOwnerTest.hrsSeg1.Id);
      Zip_Assignment__c zaHrs2 = ZipCheckOwnerTest.getZipBySegment(zaMapList2.get(UserHelper.SO_401), ZipCheckOwnerTest.hrsSeg1.Id);
      User uHrs1 = zaHrs1.User__r;
      User uHrs2 = zaHrs2.User__r;
      User uPas1 = zaMapList1.get(UserHelper.SO_PEO_ASO).get(0).User__r;
      User uPas2 = zaMapList2.get(UserHelper.SO_PEO_ASO).get(0).User__r;
      User uHnb1 = zaMapList1.get(UserHelper.SO_HNB).get(0).User__r;
      User uHnb2 = zaMapList2.get(UserHelper.SO_HNB).get(0).User__r;

      //****************************************
      Account a1 = new Account(name='Test a1',ShippingPostalCode=zip2,RecordTypeId=rtCore.getRecordTypeId());
      insert a1;
      
      a1 = ZipCheckOwnerTest.getAccount(a1.Id,byId.keySet());
      System.assertEquals(uCore2.Id,a1.ownerId);
      System.assertEquals(uHrs2.Id,a1.HRS_Account_Owner__c);
      System.assertEquals(uPas2.Id,a1.Premier_PBS_Account_Owner__c);
      System.assertEquals(uHnb2.Id,a1.HNBF_Account_Owner__c);
       
      ZipCheckOwnerTest.checkAtm(a1, ZipCheckOwnerTest.hrsSeg1.TeamRole__c, uHrs2.Id);
      //ZipCheckOwnerTest.checkAtm(a1, ZipCheckOwnerTest.pasSeg1.TeamRole__c, uPas2.Id);
      ZipCheckOwnerTest.checkAtm(a1, ZipCheckOwnerTest.hnbSeg1.TeamRole__c, uHnb2.Id);
      

      System.debug('testAccountCheckOwners a1 id='+a1.Id);
      // both record type and owner do not match the account
      Contact c1 = new Contact(FirstName='Test',LastName='Contact1',RecordTypeId=rtCtctMms.getRecordTypeId(), OwnerId=uMms2.Id, AccountId=a1.Id, Sales_Contact__c=true);
      System.debug('testAccountCheckOwners after new Contact c1 MMS record type='+rtCtctMms);
      // record type does match, owner does not
      Contact c2 = new Contact(FirstName='Test',LastName='Contact2',RecordTypeId=rtCtctCore.getRecordTypeId(), OwnerId=uCore2.Id, AccountId=a1.Id, Sales_Contact__c=true);
      // both record type and owner match the account
      Contact c3 = new Contact(FirstName='Test',LastName='Contact3',RecordTypeId=rtCtctCore.getRecordTypeId(), OwnerId=uCore2.Id, AccountId=a1.Id, Sales_Contact__c=true);
      // use a different record type id so that ownership is not changed
      Contact c4 = new Contact(FirstName='Test',LastName='Contact4',RecordTypeId=ctctTestRt.getRecordTypeId(), OwnerId=uCore2.Id, AccountId=a1.Id, Sales_Contact__c=false);
      System.debug('testAccountCheckOwners before insert c1');

      ZipCheckOwnerTest.resetTriggers();
      insert c1;
      System.debug('testAccountCheckOwners after insert c1');
      // make sure the owner on the contact changes.
      c1 = [Select Id, FirstName, LastName, RecordTypeId, OwnerId from Contact where Id = :c1.Id];
      System.debug('testAccountCheckOwners c1 recordType='+c1.RecordTypeId+' MMS recordType='+rtCtctMms.getRecordTypeId());
      System.assertEquals(rtCtctCore.getRecordTypeId(),c1.RecordTypeId);
      System.assertEquals(uCore2.Id,c1.OwnerId);
      Contact[] ctcts = new Contact[]{c2,c3,c4};

      ZipCheckOwnerTest.resetTriggers();
      insert ctcts;


      // verify that contact c1 changed owner and 
      //*********************************************
      
      Account a2 = new Account(name='Test a2',ShippingPostalCode=zip2,RecordTypeId=rtCore.getRecordTypeId(),ownerId=uCore2.Id);
      Account a3 = new Account(name='Test a3',ShippingPostalCode=zip2,RecordTypeId=rtMms.getRecordTypeId(),ownerId=uMms2.Id);
      Account[] accts = new Account[]{a2,a3};
      insert accts;
      
      Id[] acctIds = new Id[]{a2.Id,a3.Id};
      Map<Id,Account> acctMap = ZipCheckOwnerTest.getAccounts(acctIds,byId.keySet());
      a2 = acctMap.get(a2.Id);
      System.debug('testAccountCheckOwners a2='+a2.Id);
      a3 = acctMap.get(a3.Id);
      System.debug('testAccountCheckOwners a3='+a3.Id);

      System.debug('testAccountCheckOwners owner='+a1.ownerId+' zip='+a1.ShippingPostalCode);
      a1.ShippingPostalCode=zip1;
      System.debug('testAccountCheckOwners owner='+a1.ownerId+' zip='+a1.ShippingPostalCode);

      System.debug('testAccountCheckOwners before update a1='+a1.Id);
      ZipCheckOwnerTest.resetTriggers();
      update a1;

      a1 = ZipCheckOwnerTest.getAccount(a1.Id,byId.keySet());
      System.debug('testAccountCheckOwners owner='+a1.ownerId+' zip='+a1.ShippingPostalCode);

      
      System.assertEquals(uCore1.Id,a1.ownerId);
      System.assertEquals(uHrs1.Id,a1.HRS_Account_Owner__c);
      System.assertEquals(uPas1.Id,a1.Premier_PBS_Account_Owner__c);
      System.assertEquals(uHnb1.Id,a1.HNBF_Account_Owner__c);
      System.assertEquals(3,a1.Contacts.size());
      // verify that all contacts were updated
      for (Contact ctct : a1.Contacts) {
      	 System.debug('testAccountCheckOwners checking Contacts name='+ctct.Name);
         // only check for valid record type ids.
         if (byId.containsKey(ctct.RecordTypeId)) {             
            System.assertEquals(uCore1.Id,ctct.ownerId);
            System.assertEquals(uHrs1.Id,ctct.HRS_Contact_Owner__c);
            System.assertEquals(uPas1.Id,ctct.Premier_PBS_Contact_Owner__c);
            System.assertEquals(uHnb1.Id,ctct.HNBF_Contact_Owner__c);
            System.assertEquals(rtCtctCore.getRecordTypeId(),ctct.RecordTypeId);
         } else if (ctct.RecordTypeId == ctctTestRt.getRecordTypeId()) {
            // check for other record types
            // make sure the owner did not change.
             System.assertEquals(ctct.OwnerId,uCore2.Id);
         } // if (byId)
      } // for (Contact ctct
      System.debug('testAccountCheckOwners before bulk update');
      // test bulk update
      List<Account> accounts = new List<Account>{a1,a2,a3};
      a1.ShippingPostalCode=zip1;
      a2.ShippingPostalCode=zip2;
      a3.ShippingPostalCode=zip1;
      Test.startTest();
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      update accounts;
      Test.stopTest();
      System.debug('testAccountCheckOwners after bulk update');
      
      acctIds = new Id[]{a1.Id,a2.Id,a3.Id};
      acctMap = ZipCheckOwnerTest.getAccounts(acctIds,byId.keySet());
      a1 = acctMap.get(a1.Id);
      a2 = acctMap.get(a2.Id);
      a3 = acctMap.get(a3.Id);
      System.assertEquals(a1.ownerId,uCore1.Id);
      System.assertEquals(a1.HRS_Account_Owner__c,uHrs1.Id);
      System.assertEquals(a1.Premier_PBS_Account_Owner__c,uPas1.Id);
      System.assertEquals(a1.HNBF_Account_Owner__c,uHnb1.Id);
      
      // since the zip code did not change, the hrs and premier owners shouldn't change
      System.assertEquals(a2.ownerId,uCore2.Id);
      System.assertEquals(a2.HRS_Account_Owner__c,uHrs2.Id);
      //System.assertEquals(a2.Premier_PBS_Account_Owner__c,uPas2.Id);
      System.assertEquals(a2.HNBF_Account_Owner__c,uHnb2.Id);
      
      System.assertEquals(a3.ownerId,uMms1.Id);
      System.assertEquals(a3.HRS_Account_Owner__c,uHrs1.Id);
      //System.assertEquals(a3.Premier_PBS_Account_Owner__c,uPas1.Id);
      System.assertEquals(a3.HNBF_Account_Owner__c,uHnb1.Id);

      System.debug('testAccountCheckOwners before updating a1 to zip2');
      a1.ShippingPostalCode=zip2;
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      update a1;
      System.debug('testAccountCheckOwners after updating a1 to zip2');

      a1 = ZipCheckOwnerTest.getAccount(a1.Id,byId.keySet());
      System.assertEquals(a1.ownerId,uCore2.Id);
      System.assertEquals(a1.HRS_Account_Owner__c,uHrs2.Id);
      //System.assertEquals(a1.Premier_PBS_Account_Owner__c,uPas2.Id);
      System.assertEquals(a1.HNBF_Account_Owner__c,uHnb2.Id);

      // test for inactive users - owner should not change
      //get an inactive user. 
      User user3 = [select id, Name, isActive, HR_Person_Id__c, Sales_Org__c from User where Job_Name__c = :UserHelper.JOB_REP and isActive=false limit 1];
      
      System.debug('testAccountCheckOwners before creating new assignments for zip3');
      String zip3 = '54321';
      List<Zip_Assignment__c> zaList = new List<Zip_Assignment__c>();
      ZipCheckOwnerTest.createZa(zip3, user3, 0, 99, UserHelper.SO_CORE, 'Test1', null, null, zaList);
      ZipCheckOwnerTest.createZa(zip3, user3, 0, 99, UserHelper.SO_401, 'Test1', null, null, zaList);
      ZipCheckOwnerTest.createZa(zip3, user3, 0, 99, UserHelper.SO_HNB, 'Test1', null, null, zaList);
      insert zaList;
      System.debug('testAccountCheckOwners after creating new assignments for zip3');
      
      a1.ShippingPostalCode=zip3;
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      System.debug('testAccountCheckOwners before updating a1 to zip3');
      update a1;
      System.debug('testAccountCheckOwners after updating a1 to zip3');
      a1 = ZipCheckOwnerTest.getAccount(a1.Id,byId.keySet());
      // the owner remains the same because the other owner is inactive
      System.assertEquals(a1.ownerId,uCore2.Id);
      System.assertEquals(a1.HRS_Account_Owner__c,uHrs2.Id);
      //System.assertEquals(a1.Premier_PBS_Account_Owner__c,uPas2.Id);
      System.assertEquals(a1.HNBF_Account_Owner__c,uHnb2.Id);
      System.debug('End testCheckOwners');
 /*       
      a1.OwnerId = uMms1.Id;
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      System.debug('testAccountCheckOwners before updating a1 ownerId to uMms1');
      update a1;
      System.debug('testAccountCheckOwners after updating a1 ownerId to uMms1');
      ZipCheckOwner.accountIdsProcessedSet.clear();
      TriggerMethods.clearVariables();
      System.runAs(uMms1) {
         a1.RecordTypeId=rtMms.getRecordTypeId();
         a1.ShippingPostalCode = zip1;
         update a1;
      } // System.runAs
      System.debug('testAccountCheckOwners after updating a1 recordtype as uMms1');
      
      a1 = ZipCheckOwnerTest.getAccount(a1.Id,byId.keySet());
      System.assertEquals(a1.ownerId,uMms1.Id);
      System.assertEquals(a1.HRS_Account_Owner__c,uHrs1.Id);
      //System.assertEquals(a1.Premier_PBS_Account_Owner__c,uPas1.Id);
      System.assertEquals(a1.HNBF_Account_Owner__c,uHnb1.Id);
      
      // verify that all contacts were updated
      for (Contact ctct : a1.Contacts) {
         // only check for valid record type ids.
         if (byId.containsKey(ctct.RecordTypeId)) {
            System.assertEquals(ctct.ownerId,uMms1.Id);
            System.assertEquals(ctct.HRS_Contact_Owner__c,uHrs1.Id);
            //System.assertEquals(ctct.Premier_PBS_Contact_Owner__c,uPas1.Id);
            System.assertEquals(ctct.RecordTypeId,rtCtctMMS.getRecordTypeId());
         } else if (ctct.RecordTypeId == ctctTestRt.getRecordTypeId()) {
            // check for other record types
            // make sure the owner did not change.
            System.assertEquals(ctct.OwnerId,uCore2.Id);
         } // if (byId)
      } // for (Contact ctct
  */
   } // testAccountCheckOwners

   /** Test the insert of Accounts where it checks the ownership flag (AccountRecordCrossover__c is set on the User).
    */
    /*
   static testmethod void testAccountCheckOwnersInsert() {
   	
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      
      RecordTypeHelper.getRecordTypesMap(ZipCheckOwner.OBJECT_NAMES,ZipCheckOwner.RECORDTYPE_NAMES,byId,byName);
      
      Schema.RecordTypeInfo rtCore = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo rtMms = byName.get(RecordTypeHelper.MMS_ACCOUNT);
      Schema.RecordTypeInfo rtCtctCore = byName.get(RecordTypeHelper.CORE_CONTACT);
      Schema.RecordTypeInfo rtCtctMms = byName.get(RecordTypeHelper.MMS_CONTACT);

      Profile p = [select Id, Name from Profile where Name=:Utilities.PROF_CORE_SALES];
      System.debug('Run tests for Core Users');   	
      //testInsert('PAY',rtCore,rtCtctCore,'Core Partner','4','5',p,byId);
      
      p = [select Id, Name from Profile where Name=:Utilities.PROF_MMS_SALES];
      System.debug('Run test for MMS Users');
      //testInsert('MMS',rtMms,rtCtctMms,'MMS Partner','6','7',p,byId);

   } // testAccountCheckOwnersInsert
   
   /*
   private static void testInsert(String salesOrg, RecordType rtAcct, RecordType rtCtct, String roleType,String zip1, String zip2, Profile p, Map<String,RecordType> byId) {
   	  // User records for testing the insert trigger. 
      User user1 = [select id, isActive, AccountRecordCrossover__c from User where isActive=true and Id != :UserInfo.getUserId() and ProfileId=:p.Id and Sales_Org__c=:salesOrg limit 1];
      User user2 = [select id, isActive, AccountRecordCrossover__c from User where isActive=true and Id != :UserInfo.getUserId() and Id != :user1.Id and ProfileId=:p.Id and Sales_Org__c=:salesOrg limit 1];

   	  NSS_Zip_Assignment__c nza1 = getNza(zip1,user1.Id);
      NSS_Zip_Assignment__c nza2 = getNza(zip2,user2.Id);

      System.RunAs(user1) {
      	 Account a1 = new Account(name='Test '+roleType,RecordTypeId = rtAcct.Id,ShippingPostalCode=nza2.Zip_Code__c);
      	 insert a1;
      	 a1 = getAccount(a1.Id,byId.keySet());
      	 // The ownership should have changed, user1 should have been added to Account Team.
      	 System.assertEquals(a1.OwnerId,user2.Id);

      	 // insert contact record
      	 Contact c1 = new Contact(FirstName='Test',LastName='Contact1',RecordTypeId=rtCtct.Id, AccountId=a1.Id);
      	 insert c1;
      	 
      	 a1 = getAccount(a1.Id,byId.keySet());
      	 // should only be one Contact, but just in case
      	 for (Contact c : a1.Contacts) {
      	 	//System.assertEquals(c.OwnerId,user2.Id);
      	 }
      } // System.RunAs   	
   	
   } // testInsert

   /* The number of records to process for a bulk trigger. */
   private static Integer BULK_COUNT = 10;
   /*
   static testmethod void testAccountBulkProcessing() {
   	System.debug('Start testBulkProcessing number records='+BULK_COUNT);
      RecordType rtCore = [select id, name from RecordType where name=:AccountHelper.CORE_ACCOUNT];
      Profile p = [select Id, Name from Profile where Name=:Utilities.PROF_CORE_SALES];
      User user1 = [select id, isActive from User where profileId = :p.Id and isActive=true and Id != :UserInfo.getUserId() limit 1];

      // create temporary user records so it's not dependent on existing records.
      NSS_Zip_Assignment__c nza1 = getNza('0',user1.Id);

      // run as a standard user
      // test bulk processing
      System.debug('test bulk processing');
      
      Account[] accountsToTest = new Account[]{};
      for (Integer x=0; x<BULK_COUNT;x++) {
         Account a = new Account(name='Bulk Test '+x,ShippingPostalCode='TEST0',RecordTypeId=rtCore.Id,ownerId=UserInfo.getUserId());
         accountsToTest.add(a);     	 
      }
      System.debug('before bulk insert');
      insert accountsToTest;
      System.debug('after bulk insert');
      // update shipping zip code
      for (Integer x=0; x<BULK_COUNT; x++) {
   	    accountsToTest[x].ShippingPostalCode=nza1.Zip_Code__c;
      }
      Test.startTest();
      System.debug('before bulk update');
      update accountsToTest;
      System.debug('after bulk update');
      Test.stopTest();
   	  System.debug('End testBulkProcessing');
   } // testAccountBulkProcessing
   */
/*
   static testMethod void testContactBulkProcessing() {
      System.debug('Start testContactCheckOwners');
      Map<String,Schema.RecordTypeInfo> byId = new Map<String,Schema.RecordTypeInfo>();
      Map<String,Schema.RecordTypeInfo> byName = new Map<String,Schema.RecordTypeInfo>();
      
      RecordTypeHelper.getRecordTypesMap(ZipCheckOwner.OBJECT_NAMES,ZipCheckOwner.RECORDTYPE_NAMES,byId,byName);
      
      Schema.RecordTypeInfo rtCore = byName.get(RecordTypeHelper.CORE_ACCOUNT);
      Schema.RecordTypeInfo rtCtctCore = byName.get(RecordTypeHelper.CORE_CONTACT);

      // store the userIds used to create the zip codes
      Id[] excludeUserIds = new Id[]{};
      String zip1 = '12345';
      Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zip1,excludeUserIds);
      String zip2 = '12346';
      Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList(zip2,excludeUserIds);

      // core owner should be first user - no emp count
      User uCore1 = zaMapList1.get(UserHelper.SO_CORE).get(0).User__r;
      User uCore2 = zaMapList2.get(UserHelper.SO_CORE).get(0).User__r;
      System.debug('core1='+uCore1.Id+' core2='+uCore1.Id);
      User uMms1 = zaMapList1.get(UserHelper.SO_MMS).get(0).User__r;
      User uMms2 = zaMapList2.get(UserHelper.SO_MMS).get(0).User__r;
      System.debug('mms1='+uMms1.Id+' mms2='+uMms2.Id);

      Account[] accountsToTest = new Account[]{};
      for (Integer x=0; x<BULK_COUNT;x++) {
         Account a = new Account(name='Bulk Test '+x,ShippingPostalCode=zip2,RecordTypeId=rtCore.getRecordTypeId());
         accountsToTest.add(a);     	 
      } // for
      insert accountsToTest;
      ZipCheckOwner.accountIdsProcessedSet.clear();

      Id[] acctIds = new Id[]{};
         
      Contact[] contactsToTest = new Contact[]{};
      for (Account a : accountsToTest) {
      	acctIds.add(a.Id);
         contactsToTest.add(new Contact(FirstName='Test',LastName='Contact1',RecordTypeId=rtCtctCore.getRecordTypeId(), AccountId=a.Id));
         contactsToTest.add(new Contact(FirstName='Test',LastName='Contact2',RecordTypeId=rtCtctCore.getRecordTypeId(), AccountId=a.Id));
      } // for
      
      Test.startTest();
      System.debug('before bulk contact update');
      insert contactsToTest;
      System.debug('after bulk contact update');
      Test.stopTest();
         
      Map<Id,Account> acctMap = ZipCheckOwnerTest.getAccounts(acctIds,byId.keySet());
      for (Id acctId : acctMap.keySet()) {
         Account acct = acctMap.get(acctId);
         // make sure owners on contacts match the account
         for (Contact ctct : acct.Contacts) {
            System.assertEquals(acct.OwnerId, ctct.OwnerId);
            System.assertEquals(acct.HRS_Account_Owner__c,ctct.HRS_Contact_Owner__c);
            System.assertEquals(acct.Premier_PBS_Account_Owner__c,ctct.Premier_PBS_Contact_Owner__c);
         }
      } // for (Id acctId

   } // testContactBulkProcessing

*/

   static testMethod void testOneReferral() {
      runReferralTest(1,1);
   } // testOneReferral
   static testMethod void testBulkReferral() {
      runReferralTest(10,2);
   } // testOneReferral

   private static void runReferralTest(Integer numAccts, Integer numContacts) {
      System.debug('running user='+UserInfo.getUserId());
      ZipCheckOwnerTest.setupZipAndTerrStatics();
      Zip_Assignment__c cpaZa = ZipCheckOwnerTest.zaCPA;
      Zip_Assignment__c zaHRS1Seg1 = ZipCheckOwnerTest.zaHRS1Seg1;
      Zip_Assignment__c zaPEO1Seg1 = ZipCheckOwnerTest.zaPEO1Seg1;
      Zip_Assignment__c zaHNB1Seg1 = ZipCheckOwnerTest.zaHNB1Seg1;
      System.assertNotEquals(null,cpaZa,'Could not find a CPA zip segment!');
      /*
      Id[] excludeUserIds = new Id[]{};
      String zipCode1 = '12345';
      //String zipCode2 = '12346';
      // create zip assignment objects
      Map<String,List<Zip_Assignment__c>> zaMapList1 = ZipCheckOwnerTest.getZaMapList(zipCode1,excludeUserIds);
      // get the CPA owner
      Zip_Assignment__c[] zaList = zaMapList1.get(UserHelper.SO_CORE);
      for (Zip_Assignment__c za : zaList) {
          if (za.Segment_Name__c == 'CPA') {
              cpaZA = za;
              break;
          }
      }
      */
      Map<String,Schema.RecordTypeInfo> refAcctRtMap = Referral_Account__c.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo coreRt = refAcctRtMap.get('Core Referral Source Record Type');
      Schema.RecordTypeInfo hrsRt = refAcctRtMap.get('HRS Referral Source Record Type');

      //Map<String,List<Zip_Assignment__c>> zaMapList2 = ZipCheckOwnerTest.getZaMapList(zipCode2,excludeUserIds);
      // create numAccts number of referral accounts
      Referral_Account__c[] refAccts = new Referral_Account__c[]{};
      for (Integer cnt=0; cnt<numAccts; cnt++) {
         Referral_Account__c ra = new Referral_Account__c(Name='Test Acct '+cnt, RecordTypeId=coreRt.getRecordTypeId(), Referral_Source_Business_Type__c='Accounting Firm');
         ra.Zip_Postal_Code__c = cpaZa.Name;
         refAccts.add(ra);
      }
      // save the accounts
      insert refAccts;
      // check the results - make sure ownership fields are set.
      // get the referral ids
      Id[] refAcctIds = new Id[]{};
      for (Referral_Account__c ra : refAccts) {
         refAcctIds.add(ra.Id);
      }

      Map<Id,Referral_Account__c> refAcctMap = ZipCheckOwner.getRefAccounts(refAcctIds);
      for (Referral_Account__c ra : refAcctMap.values()) {
         // assume the first Zip Assignment record is the one being used
         //System.assertEquals(zaMapList1.get(UserHelper.SO_CORE)[0].User__c,ra.OwnerId);
         System.assertEquals(cpaZA.User__c,ra.OwnerId);
         System.assertEquals(zaHNB1Seg1.User__c,ra.HNBF_Account_Owner__c);
         System.assertEquals(zaHRS1Seg1.User__c,ra.HRS_Account_Owner__c);
         System.assertEquals(zaPEO1Seg1.User__c,ra.Premier_PBS_Account_Owner__c);
      }
      // create numContacts number of referral contacts for each referral account
      Referral_Contact__c[] refContacts = new Referral_Contact__c[]{};
      for (Referral_Account__c ra : refAcctMap.values()) {
         for (Integer cnt=0; cnt<numContacts; cnt++) {
            Referral_Contact__c rc = new Referral_Contact__c(Referral_Account__c=ra.Id);
            rc.Name = 'Test Contact'+cnt;
            //rc.Use_Account_Ownership__c = true;
            refContacts.add(rc);
         }
      } // for
      // save the referral contacts
      insert refContacts;
      // check the results - make sure ownership fields are set
      Id[] refCtctIds = new Id[]{};
      for (Referral_Contact__c rc : refContacts) {
         refCtctIds.add(rc.Id);
      }
      
      for (Referral_Contact__c[] refCtcts : [Select Id
                                                   ,Referral_Account__c
                                                   ,OwnerId
                                                   ,HNBF_Contact_Owner__c
                                                   ,HRS_Contact_Owner__c
                                                   ,MMS_Contact_Owner__c
                                                   ,Premier_PBS_Contact_Owner__c
                                                   ,Internal_Wholesaler_Contact_Owner__c
                                                   ,External_Wholesaler_Contact_Owner__c
                                               from Referral_Contact__c
                                              Where Id in :refCtctIds]) {
         for (Referral_Contact__c rc : refCtcts) {
            // get the referral account
            Referral_Account__c ra = refAcctMap.get(rc.Referral_Account__c);
            // assume the first Zip Assignment record is the one being used
            System.assertEquals(rc.OwnerId,ra.OwnerId);
            System.assertEquals(rc.HNBF_Contact_Owner__c,ra.HNBF_Account_Owner__c);
            System.assertEquals(rc.HRS_Contact_Owner__c,ra.HRS_Account_Owner__c);
            System.assertEquals(rc.MMS_Contact_Owner__c,ra.MMS_Account_Owner__c);
            System.assertEquals(rc.Premier_PBS_Contact_Owner__c,ra.Premier_PBS_Account_Owner__c);
         }
      } // for (Referral_Contact__c[] refCtcts
   } // runReferralTest
   
   static testmethod void testESROwner() {
      ZipCheckOwnerTest.setupCustomSettings();
      
      // select some random users
      User[] testUsers = [Select Id, Name, HR_Person_Id__c from User where UserRoleId != null and IsActive=true and HR_Person_Id__c != null and Job_Name__c != null limit 3];

      Map<String,Schema.RecordTypeInfo> byNameMap = Account.SObjectType.getDescribe().getRecordTypeInfosByName();
      Id rtId = byNameMap.get(RecordTypeHelper.CORE_ACCOUNT).getRecordTypeId();
      
      Account acct1 = new Account(Name='Account 1', ESR_Person_ID__c=testUsers[0].HR_Person_Id__c, RecordTypeId=rtId);
      Account acct2 = new Account(Name='Account 2', ESR_Person_ID__c=testUsers[1].HR_Person_Id__c, RecordTypeId=rtId);
      Account acct3 = new Account(Name='Account 3', ESR_Person_ID__c=testUsers[2].HR_Person_Id__c, RecordTypeId=rtId, Use_Zip_Assignment_Rules__c=true);
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Map<Id,Account> checkMap = new Map<Id,Account>([Select Id, Name, ESR_Person_ID__c
                                        ,(Select Id, TeamMemberRole, UserId from AccountTeamMembers)
                                    From Account
                                   Where Id in :accts]);
      checkTeamMember(checkMap.get(acct1.Id),testUsers[0].Id);
      checkTeamMember(checkMap.get(acct2.Id),testUsers[1].Id);
      checkTeamMember(checkMap.get(acct3.Id),testUsers[2].Id);
      
      acct1.ESR_Person_ID__c = testUsers[2].HR_Person_Id__c;
      acct2.ESR_Person_ID__c = testUsers[2].HR_Person_Id__c;
      acct3.ESR_Person_ID__c = null;
      ZipCheckOwnerTest.resetTriggers();
      System.debug('testESROwner before update');
      update accts;
      
      checkMap = new Map<Id,Account>([Select Id, Name, ESR_Person_ID__c
                                        ,(Select Id, TeamMemberRole, UserId from AccountTeamMembers)
                                    From Account
                                   Where Id in :accts]);
      checkTeamMember(checkMap.get(acct1.Id),testUsers[2].Id);
      checkTeamMember(checkMap.get(acct2.Id),testUsers[2].Id);
      checkTeamMember(checkMap.get(acct3.Id),null);

      acct1.ESR_Person_ID__c = null;
      acct2.ESR_Person_ID__c = testUsers[1].HR_Person_Id__c;
      acct3.ESR_Person_ID__c = testUsers[1].HR_Person_Id__c;
      TriggerMethods.clearVariables();
      ZipCheckOwner.accountIdsProcessedSet.clear();
      update accts;
      
      checkMap = new Map<Id,Account>([Select Id, Name, ESR_Person_ID__c
                                        ,(Select Id, TeamMemberRole, UserId from AccountTeamMembers)
                                    From Account
                                   Where Id in :accts]);
      checkTeamMember(checkMap.get(acct1.Id),null);
      checkTeamMember(checkMap.get(acct2.Id),testUsers[1].Id);
      checkTeamMember(checkMap.get(acct3.Id),testUsers[1].Id);
      
   } // testESROwner
   
   public static void checkTeamMember(Account acct, Id userId) {
      AccountTeamMember atm = null;
      System.debug('checkTeamMember acct='+acct.Name+' teamMembers='+acct.AccountTeamMembers.size());
      for (AccountTeamMember checkAtm : acct.AccountTeamMembers) {
         if (checkAtm.TeamMemberRole == ZipCheckOwner.AT_ESR) {
            atm = checkAtm;
            break;
         }
      } // for (AccountTeamMember checkAtm
      if (userId == null) {
         System.assertEquals(null, atm);
      } else {
         System.assertEquals(true, (atm != null));
         System.assertEquals(userId, atm.UserId);
      }
      
   } // checkTeamMember
   /*
   static testMethod void testSettingFields() {        
      PaychexSettings__c ps1 = new PaychexSettings__c(Name='Rec1', isActive__c=true, ProcessName__c=ZipCheckOwner.SETTING_ACCT_PROCESS_NAME, Attribute1__c='Name');
      PaychexSettings__c ps2 = new PaychexSettings__c(Name='Rec2', isActive__c=true, ProcessName__c=ZipCheckOwner.SETTING_LEAD_PROCESS_NAME, Attribute1__c='Name');
      PaychexSettings__c[] settings = new PaychexSettings__c[]{ps1,ps2};
      insert settings;
      String result1 = ZipCheckOwner.getAccountSettingQueryFlds();
      System.assertEquals(true,result1.contains('Name'));
      String result2 = ZipCheckOwner.getLeadSettingQueryFlds();
      System.assertEquals(true,result2.contains('Name'));
       
   } // testSettingFields
   */
    
   static testMethod void testOtherCriteria() {
      Zip_Segment__c seg1 = new Zip_Segment__c(Name='Segment1');
      Zip_Segment__c seg2 = new Zip_Segment__c(Name='Segment2');
      Zip_Segment__c seg3 = new Zip_Segment__c(Name='Segment3');
      Zip_Segment__c seg4 = new Zip_Segment__c(Name='Segment4');
      insert new Zip_Segment__c[]{seg1,seg2,seg3,seg4};
           
      ZipSegmentCriteria__c criteria1a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=0, Number2__c=20);
      ZipSegmentCriteria__c criteria1b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_NBR_RANGE, FieldAPIName__c='NumberOfEmployees', Number1__c=21, Number2__c=999);
      ZipSegmentCriteria__c criteria2a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan1,Dan2');
      ZipSegmentCriteria__c criteria2b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Type', Values__c='Dan3,Dan4');
      ZipSegmentCriteria__c criteria3a = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='AccountSource', Values__c='Seance,Smoke Signal');
      ZipSegmentCriteria__c criteria3b = new ZipSegmentCriteria__c(Account__c=true, Lead__c=false, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='AccountSource', Values__c='Mailing,Telegraph');
      ZipSegmentCriteria__c criteria4a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Mailbox');
      ZipSegmentCriteria__c criteria4b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='LeadSource', Values__c='Pony Express');
      ZipSegmentCriteria__c criteria5a = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Status', Values__c='New');
      ZipSegmentCriteria__c criteria5b = new ZipSegmentCriteria__c(Account__c=false, Lead__c=true, ReferralAccount__c=false
                                                                   ,FieldType__c = ZipCheckOwner.CRI_TEXT, Operator__c=ZipCheckOwner.OP_EQUALS, FieldAPIName__c='Status', Values__c='In Progress');
      insert new ZipSegmentCriteria__c[]{criteria1a,criteria1b,criteria2a,criteria2b,criteria3a,criteria3b,criteria4a,criteria4b,criteria5a,criteria5b};
           
      ZipSegmentCriteriaLink__c link1a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg1.Id, ZipSegmentCriteria__c=criteria1a.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_AND, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_AND);
      ZipSegmentCriteriaLink__c link1b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg1.Id, ZipSegmentCriteria__c=criteria2a.Id);
      ZipSegmentCriteriaLink__c link1c = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg1.Id, ZipSegmentCriteria__c=criteria3a.Id);
      ZipSegmentCriteriaLink__c link1d = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg1.Id, ZipSegmentCriteria__c=criteria4a.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_AND, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_AND);
      ZipSegmentCriteriaLink__c link1e = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg1.Id, ZipSegmentCriteria__c=criteria5a.Id);

      ZipSegmentCriteriaLink__c link2a = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg2.Id, ZipSegmentCriteria__c=criteria1b.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_OR, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_OR);
      ZipSegmentCriteriaLink__c link2b = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg2.Id, ZipSegmentCriteria__c=criteria2b.Id);
      ZipSegmentCriteriaLink__c link2c = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg2.Id, ZipSegmentCriteria__c=criteria3b.Id);
      ZipSegmentCriteriaLink__c link2d = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg2.Id, ZipSegmentCriteria__c=criteria4b.Id
                                                                      ,ZipSegmentJoinType__c=ZipCheckOwner.JOINTYPE_OR, ZipLinkJoinType__c=ZipCheckOwner.JOINTYPE_OR);
      ZipSegmentCriteriaLink__c link2e = new ZipSegmentCriteriaLink__c(Active__c=true, ZipSegment__c=seg2.Id, ZipSegmentCriteria__c=criteria5b.Id);
      insert new ZipSegmentCriteriaLink__c[]{link1a,link1b,link1c,link1d,link1e,link2a,link2b,link2c,link2d,link2e};
          
      link1b.ZipLinkJoin__c = link1a.Id;
      link1c.ZipLinkJoin__c = link1a.Id;
      link1d.ZipLinkJoin__c = link1a.Id;
      link1e.ZipLinkJoin__c = link1a.Id;
       
      link2b.ZipLinkJoin__c = link2a.Id;
      link2c.ZipLinkJoin__c = link2a.Id;

      link2e.ZipLinkJoin__c = link2d.Id;
      update new ZipSegmentCriteriaLink__c[]{link1b,link1c,link1d,link1e,link2b,link2c,link2e}; 
          
      Zip_Segment__c[] segments = ZipQueries.getAllSegments();
      Map<Id,Zip_Segment__c> segmentMap = new Map<Id,Zip_Segment__c>(segments);
      Zip_Segment__c checkSeg1 = segmentMap.get(seg1.Id);
      Zip_Segment__c checkSeg2 = segmentMap.get(seg2.Id);
          
      Account acct1 = new Account(Name='Test Account1', NumberOfEmployees=10, Type='Dan1');
      Boolean criteriaMet = ZipCheckOwner.checkOtherCriteria(acct1, checkSeg1, true);
      // should be false since AccountSource is not set.
      Assert.isFalse(criteriaMet);

      acct1.AccountSource='Smoke Signal';
      criteriaMet = ZipCheckOwner.checkOtherCriteria(acct1, checkSeg1, true);
      // should be true now
      Assert.isTrue(criteriaMet);

      Account acct2 = new Account(Name='Test Account2', NumberOfEmployees=10, Type='Dan3');
      criteriaMet = ZipCheckOwner.checkOtherCriteria(acct2, checkSeg2, true);
      // should match because one critera matches and it's an OR
      Assert.isTrue(criteriaMet);

      Lead ld1 = new Lead(Company='Test Lead1', LeadSource='Mailbox', Status='Test');
      criteriaMet = ZipCheckOwner.checkOtherCriteria(ld1, checkSeg1, true);
      // should not match because only one criteria
      Assert.isFalse(criteriaMet);
       
      ld1.NumberOfEmployees=20;
      ld1.Status='New';
      criteriaMet = ZipCheckOwner.checkOtherCriteria(ld1, checkSeg1, true);
      Assert.isTrue(criteriaMet);

      Lead ld2 = new Lead(Company='Test Lead1', LeadSource='Pony Express', Status='Test');
      Map<Id,ZipCheckOwner.CriteriaWrap> resultMap = ZipCheckOwner.checkOtherCriteria2(ld2, checkSeg2);
      // should be two returned because 2 parents setup for lead under Seg2
      Assert.areEqual(2,resultMap.size());
      Boolean hasTrue=false;
      Boolean hasFalse=false;
      for (ZipCheckOwner.CriteriaWrap criteria : resultMap.values()) {
         if (criteria.criteriaMet) {
             hasTrue = true;
         } else {
             hasFalse = true;
         }
      }
      // both conditions should have been met
      Assert.isTrue(hasTrue);
      Assert.isTrue(hasFalse);
      
   } // testOtherCriteria
    
} // class ZipCheckOwnerTest2