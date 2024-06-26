/* Test Methods for OasisSyncHelper

  History
  -------
  04/09/2019 Dan Carmen        Created
  10/17/2019 Dan Carmen        Changed to not set ownership.
  03/11/2020 Dan Carmen        Remove connection to Oasis instance
  
 */
@isTest
public class OasisSyncHelperTest {
    static testMethod void testNothing() {
        OasisSync__c sync = new OasisSync__c(Name='Test');
        insert sync;
        OasisSyncHelper osh = new OasisSyncHelper();
        osh.triggerCheckAllFirst((SObject[])null, (Map<Id,SObject>)null, (Boolean)null, (Boolean)null);
        osh.triggerCheckRec((SObject)null, (SObject)null, (Boolean)null, (Boolean)null);
        osh.triggerCheckActions((Boolean)null, (Boolean)null);
        OasisSaveQueueable osq = new OasisSaveQueueable();
    } // testNothing

   public static User getTestCSUser() {
      User csUser = [Select Id, Name, HR_Person_Id__c from User where CSUserId__c != null and HR_Person_Id__c != null and IsActive=true and UserRoleId != null limit 1];
      return csUser;
   } // getTestCSUser

    /*
   @testSetup
   public static void setupTestData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=OasisSaveQueueable.CLASSNAME, Active__c = true, LogProcess__c=true
                  ,BatchSize__c=50, SendCompletionEmail__c=true, NbrOfAttempts__c=0, Minutes_till_Launch__c=4 );
      insert abc;
      setupCustomSettings();
   } // setupTestData
   
   public static void setupCustomSettings() {
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createCustomSetting('AccountAfter', false, true, new String[]{'OasisSyncHelper'}, classes, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createCustomSetting('ContactAfter', false, true, new String[]{'OasisSyncHelper'}, classes, TriggerMethods.INTERFACE_B);
      TriggerMethodsTest.createCustomSetting('LeadAfter', false, true, new String[]{'OasisSyncHelper'}, classes, TriggerMethods.INTERFACE_B);
      insert classes;
   }

   public static void setConnectionUserAsRunningUser() {
      String runningUserName = UserInfo.getName();
      // make it look like we're the connection user
      OasisSyncHelper.CONNECTION_USER = runningUserName;
   } // setConnectionUserAsRunningUser
   
   public static void resetConnectionUser() {
      OasisSyncHelper.CONNECTION_USER = 'Connection User';
   } // resetConnectionUser

   
   public static void skipAllTriggers() {
      OasisSyncHelper.SKIP_TRIGGER = true;
      LeadMethods.LEAD_BEFORE_EXECUTING = true;
      LeadMethods.LEAD_AFTER_EXECUTING = true;
      ZipCheckOwner.SKIP_TRIGGERS=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
   } // skipAllTriggers
   
   public static void resetTriggerFlags() {
      OasisSyncHelper.ALREADY_RAN_SET.clear();
      OasisSyncHelper.SKIP_TRIGGER = false;
      OasisSyncHelper.BEFORE_EXECUTED = false;
      OasisSyncHelper.AFTER_EXECUTED = false;
      LeadMethods.LEAD_BEFORE_EXECUTING = false;
      LeadMethods.LEAD_AFTER_EXECUTING = false;
      ZipCheckOwner.SKIP_TRIGGERS=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
   } // resetTriggerFlags

   // test a new lead coming in from Oasis
   static testMethod void testNewLead() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      // create a new lead to use the ID. Skip the triggers on creation
      skipAllTriggers();
      Lead checkLead = new Lead(LastName='Test', FirstName='Timmy', Company='Timmy Test Tubes', Email='timmy@testtube.com', PostalCode='15431');
      insert checkLead;
      resetTriggerFlags();
      
      // create a new OasisSync__c record to simulate it came in from the feed.
      setConnectionUserAsRunningUser();
      OasisSync__c sync = OasisSyncHelper.prepareSync(null,'Linda Lead');
      sync.Source__c=OasisSyncHelper.SOURCE_OASIS;
      sync.SyncType__c=OasisSyncHelper.SYNC_NEW;
      
      sync.LeadIdOasis__c=checkLead.Id;
      sync.FirstName__c='Linda';
      sync.LastName__c='Lead';
      sync.Title__c='Litagator';
      sync.Email__c='linda.lead@litagators.com';
      sync.Company__c='Luxe Litagators LLC';
      sync.City__c='Louisville';
      sync.State__c='LA';
      sync.PostalCode__c='43123';
      sync.OwnerHRPersonID__c = csUser.HR_Person_Id__c;
      
      Test.startTest();
      insert sync;
      Test.stopTest();
      
      // the lead should be created
      Lead ld = [Select Id, FirstName, LastName, Title, Email, Company, City, State, PostalCode, OasisId__c
                       ,CreatedByProcess__c, DuplicateCheckStatus__c, OwnedBy__c, OwnedByPrev__c
                       ,RecordType.Name 
                       ,OwnerId
                   from Lead where OasisId__c=:checkLead.Id];
      System.assertEquals(sync.FirstName__c, ld.FirstName);
      System.assertEquals(sync.LastName__c, ld.LastName);
      System.assertEquals(sync.Title__c, ld.Title);
      System.assertEquals(sync.Email__c, ld.Email);
      System.assertEquals(sync.Company__c, ld.Company);
      System.assertEquals(sync.City__c, ld.City);
      System.assertEquals(sync.State__c, ld.State);
      System.assertEquals(sync.PostalCode__c, ld.PostalCode);
      System.assertEquals('Pending', ld.DuplicateCheckStatus__c);
      //System.assertEquals(Label.RT_PEO_Lead, ld.RecordType.Name);
      System.assertEquals(OasisSyncHelper.SOURCE_OASIS, ld.CreatedByProcess__c);
      //System.assertEquals(csUser.Id, ld.OwnerId);
      //System.assertEquals(OasisSyncHelper.OASIS_NEW, ld.OwnedBy__c);
      
      // the sync record should get updated with the paychex id
      OasisSync__c checkSync = [Select Id, LeadIdPayx__c, LeadIdOasis__c, SyncType__c
                                  From OasisSync__c
                                 Where Id = :sync.Id];
      //System.assertEquals(ld.Id, checkSync.LeadIdPayx__c);
      //System.assertEquals(checkLead.Id, checkSync.LeadIdOasis__c);
      //System.assertEquals(OasisSyncHelper.SYNC_RECORD_ID, checkSync.SyncType__c);
      
   } // testNewLead

   static testMethod void testAcctCtct() {
      OasisSyncHelper.USE_SAVE_QUEUEABLE = true;
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      // create a account and contact to use the ID. Skip the triggers on creation
      skipAllTriggers();
      Account checkAcct = new Account(Name='Anything Is Possible', BillingCity='Hollywood', BillingState='CA', BillingPostalCode='90210');
      insert checkAcct;
      Contact checkCtct = new Contact(FirstName='Debbie',LastName='Gibson', AccountId=checkAcct.Id, Phone='(555) 831-1970', Email='debbie@aip.com');
      insert checkCtct;

      resetTriggerFlags();
      
      // create a new OasisSync__c record to simulate it came in from the feed.
      setConnectionUserAsRunningUser();
      OasisSync__c sync = OasisSyncHelper.prepareSync(null,'Debbie Gibson');
      sync.Source__c=OasisSyncHelper.SOURCE_OASIS;
      sync.SyncType__c=OasisSyncHelper.SYNC_NEW;
      
      sync.AccountIdOasis__c=checkAcct.Id;
      sync.Company__c=checkAcct.Name;
      sync.City__c=checkAcct.BillingCity;
      sync.State__c=checkAcct.BillingState;
      sync.PostalCode__c=checkAcct.BillingPostalCode;

      sync.ContactIdOasis__c=checkCtct.Id;
      sync.FirstName__c=checkCtct.FirstName;
      sync.LastName__c=checkCtct.LastName;
      sync.Phone__c=checkCtct.Phone;
      sync.Email__c=checkCtct.Email;
      sync.OwnerHRPersonID__c = csUser.HR_Person_Id__c;
      
      Test.startTest();
      insert sync;
      Test.stopTest();
      
      Contact ctct = [Select Id, FirstName, LastName, Phone, Email, OasisId__c, OwnerId
                            ,CreatedByProcess__c
                            ,Account.Id
                            ,Account.Name
                            ,Account.OwnerId
                            ,Account.BillingCity
                            ,Account.BillingState
                            ,Account.BillingPostalCode
                            ,Account.RecordType.Name
                            ,Account.OasisId__c
                            ,Account.CreatedByProcess__c
                        from Contact
                       Where OasisId__c=:checkCtct.Id];
      System.assertEquals(checkAcct.Name,ctct.Account.Name);
      System.assertEquals(checkAcct.BillingCity,ctct.Account.BillingCity);
      System.assertEquals(checkAcct.BillingState,ctct.Account.BillingState);
      System.assertEquals(checkAcct.BillingPostalCode,ctct.Account.BillingPostalCode);
      System.assertEquals(checkAcct.Id,ctct.Account.OasisId__c);
      System.assertEquals(Label.RT_Prospect_Acct, ctct.Account.RecordType.Name);
      System.assertEquals(OasisSyncHelper.SOURCE_OASIS, ctct.Account.CreatedByProcess__c);
      //System.assertEquals(csUser.Id, ctct.Account.OwnerId);
      
      System.assertEquals(checkCtct.FirstName, ctct.FirstName);
      System.assertEquals(checkCtct.LastName, ctct.LastName);
      System.assertEquals(checkCtct.Phone, ctct.Phone);
      System.assertEquals(checkCtct.Email, ctct.Email);
      System.assertEquals(checkCtct.Id, ctct.OasisId__c);
      System.assertEquals(OasisSyncHelper.SOURCE_OASIS, ctct.CreatedByProcess__c);
      //System.assertEquals(csUser.Id, ctct.OwnerId);
                  
      // the sync record should get updated with the paychex id
      OasisSync__c checkSync = [Select Id, AccountIdPayx__c, AccountIdOasis__c
                                      ,ContactIdPayx__c, ContactIdOasis__c
                                      ,SyncType__c
                                  From OasisSync__c
                                 Where Id = :sync.Id];
      System.assertEquals(ctct.Account.Id, checkSync.AccountIdPayx__c);
      System.assertEquals(checkAcct.Id, checkSync.AccountIdOasis__c);
      System.assertEquals(ctct.Id, checkSync.ContactIdPayx__c);
      System.assertEquals(checkCtct.Id, checkSync.ContactIdOasis__c);
      
      System.assertEquals(OasisSyncHelper.SYNC_RECORD_ID, checkSync.SyncType__c);
      
   } // testAcctCtct

   static testMethod void testLeadIdUpdate() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      // let it run through the trigger to create an OasisSync__c record
      Lead ld = new Lead(LastName='Test', FirstName='Timmy', Company='Timmy Test Tubes', Email='timmy@testtube.com', PostalCode='15431', OwnerId=csUser.Id);
      insert ld;
      
      // an OasisSync__c record should have been created
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Lead[]{ld});
      System.assertEquals(1,syncMap.size());
      OasisSync__c sync = syncMap.get(ld.Id);

      sync.SyncType__c = OasisSyncHelper.SYNC_RECORD_ID; 
      sync.Source__c = OasisSyncHelper.SOURCE_OASIS;
      sync.LeadIdOasis__c = ld.Id;
      
      resetTriggerFlags();
      setConnectionUserAsRunningUser();
      Test.startTest();
      update sync;
      Test.stopTest();
      
      Lead checkLd = [Select Id, Name, OasisId__c from Lead where Id=:ld.Id];
      System.assertEquals(ld.Id, checkLd.OasisId__c);
      
   } // testLeadIdUpdate
   
   static testMethod void testCtctIdUpdate() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      Account acct = new Account(Name='The TARDIS', BillingPostalCode='14514', OwnerId=csUser.Id);
      insert acct;
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Amy', LastName='Pond', Title='Companion', Email='amelia@thetardis.com', OwnerId=csUser.Id);
      insert ctct;
      
      // an OasisSync__c record should have been created
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Contact[]{ctct});
      System.assertEquals(1,syncMap.size());
      OasisSync__c sync = syncMap.get(ctct.Id);
      
      sync.SyncType__c = OasisSyncHelper.SYNC_RECORD_ID; 
      sync.Source__c = OasisSyncHelper.SOURCE_OASIS;
      sync.AccountIdOasis__c = acct.Id;
      sync.ContactIdOasis__c = ctct.Id;
      
      resetTriggerFlags();
      setConnectionUserAsRunningUser();
      Test.startTest();
      update sync;
      Test.stopTest();
      
      Contact checkCtct = [Select Id, Name, OasisId__c
                                 ,Account.Id
                                 ,Account.Name
                                 ,Account.OasisId__c
                             From Contact
                            Where Id=:ctct.Id];
                            
      System.assertEquals(ctct.Id, checkCtct.OasisId__c);
      System.assertEquals(acct.Id, checkCtct.Account.OasisId__c);
      
   } // testCtctIdUpdate
   
   static testMethod void testConvertedLead() {
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      // let this lead create a sync record
      Lead ld = new Lead(OwnerId=csUser.Id, FirstName='Matt', LastName='Smith', Title='The Doctor', Company='The TARDIS', State='NY',PostalCode='14321', Email='thedoctor@thetardis.com');
      insert ld;

      // create an account and contact = skip the triggers in this case.
      skipAllTriggers();
      // set the oasis flag so it will process as normal.
      ld.OasisId__c = ld.Id;
      update ld;
      
      Account acct = new Account(Name='The TARDIS');
      insert acct;
      acct.OasisId__c = acct.Id;
      update acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, FirstName='Matt', LastName='Smith');
      insert ctct;
      ctct.OasisId__c = ctct.Id;
      update ctct;
      
      setConnectionUserAsRunningUser();
      resetTriggerFlags();

      // an OasisSync__c record should have been created
      Map<String,OasisSync__c> syncMap = OasisSyncHelper.getExistingSyncMap(new Lead[]{ld});
      System.assertEquals(1,syncMap.size());
      OasisSync__c sync = syncMap.get(ld.Id);
      
      sync.SyncType__c = OasisSyncHelper.SYNC_LEAD_CONVERTED; 
      sync.Source__c = OasisSyncHelper.SOURCE_OASIS;
      sync.LeadIdOasis__c = ld.Id;
      sync.AccountIdOasis__c = acct.Id;
      sync.ContactIdOasis__c = ctct.Id;
      
      Test.startTest();
      update sync;
      Test.stopTest();
      
      Lead checkLd = [Select Id, Name
                            ,ConvertedAccountId
                            ,ConvertedContactId
                            ,IsConverted
                        From Lead
                      Where Id=:ld.Id];
      System.assertEquals(true,checkLd.IsConverted);
      System.assertEquals(acct.Id, checkLd.ConvertedAccountId);
      System.assertEquals(ctct.Id, checkLd.ConvertedContactId);
      
      Contact checkCtct = [Select Id, Name, OasisId__c
                                 ,Account.Id
                                 ,Account.Name
                                 ,Account.OasisId__c
                             From Contact
                            Where Id=:ctct.Id];
                            
      System.assertEquals(ctct.Id, checkCtct.OasisId__c);
      System.assertEquals(acct.Id, checkCtct.Account.OasisId__c);

   } // testConvertedLead

   // test when an account comes in marked as a client
   static testMethod void testClient() {
      OasisSyncHelper.USE_SAVE_QUEUEABLE = true;
      String[] prodNames = new String[]{'Oasis1'};
      OasisSyncHelper.oasisProdCodes = prodNames;
      PricebookEntry[] entries = ProductMethodsTest.getEntries(prodNames, 'PEO', null);
      
      OasisSyncHelper.SKIP_NAME_SET.clear();
      User csUser = getTestCSUser();
      // create a account and contact to use the ID. Skip the triggers on creation
      skipAllTriggers();
      Account checkAcct = new Account(Name='Anything Is Possible', BillingCity='Hollywood', BillingState='CA', BillingPostalCode='90210');
      insert checkAcct;
      Contact checkCtct = new Contact(FirstName='Debbie',LastName='Gibson', AccountId=checkAcct.Id, Phone='(555) 831-1970', Email='debbie@aip.com');
      insert checkCtct;

      resetTriggerFlags();
      
      // create a new OasisSync__c record to simulate it came in from the feed.
      setConnectionUserAsRunningUser();
      OasisSync__c sync = OasisSyncHelper.prepareSync(null,'Debbie Gibson');
      sync.Source__c=OasisSyncHelper.SOURCE_OASIS;
      sync.SyncType__c=OasisSyncHelper.SYNC_NEW;
      
      sync.AccountIdOasis__c=checkAcct.Id;
      sync.Company__c=checkAcct.Name;
      sync.City__c=checkAcct.BillingCity;
      sync.State__c=checkAcct.BillingState;
      sync.PostalCode__c=checkAcct.BillingPostalCode;

      sync.ContactIdOasis__c=checkCtct.Id;
      sync.FirstName__c=checkCtct.FirstName;
      sync.LastName__c=checkCtct.LastName;
      sync.Phone__c=checkCtct.Phone;
      sync.Email__c=checkCtct.Email;
      sync.OwnerHRPersonID__c = csUser.HR_Person_Id__c;
      sync.CSOrgStatus__c = 'Client';
      
      Test.startTest();
      insert sync;
      Test.stopTest();
      
      Account acct = [Select Id, Name, Type
                           ,(select Id, Name, ProductCode, Product2Id
                               From Assets)
                        From Account
                       Where OasisId__c = :checkAcct.Id];
      System.assertEquals(1,acct.Assets.size());
      System.assertEquals('Oasis1',acct.Assets[0].ProductCode);
      System.assertEquals('Oasis Client',acct.Type);
   } // testClient
*/
} // class OasisSyncHelperTest