/** Test methods for the DoNotSyncCheck class.
 *
 * History
 * -------
   01/16/2018 Dan Carmen          Created.
   01/23/2018 Dan Carmen          Additional checks for accounts.
   02/12/2018 Dan Carmen          Set the Contact_Email_Available__c field on the account
   04/27/2018 Dan Carmen          Adjustments for Marketo
   08/08/2018 Dan Carmen          Change method of caching
   03/26/2019 Dan Carmen          Added check for EmailOptOut
   08/28/2020 Pujitha Madamanchi  Added check for Marketing Block Reason + Mirrored Contact
   10/27/2021 Pujitha Madamanchi  Added check for Lead Purchased List
   01/04/2022 Dan Carmen          Make sure Record Type custom settings are setup
   01/04/2023 Dan Carmen          Add ability to skip checks for users
   02/06/2023 Pujitha Madamanchi  Add Ecomm check
   06/26/2023 Pujitha Madamanchi  Add more logic to Marketing block reason


 */
@isTest
private class DoNotSyncCheckTest {
   
   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false, new String[]{'DoNotSyncCheck'});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'DoNotSyncCheck'});
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, new String[]{'DoNotSyncCheck'});
      TriggerMethodsTest.saveSetupClasses();

      RecordTypeHelperTest.setupRecordType();

   } // setupData

   static testMethod void testCheckIfNameIsNumber() {
      System.assertEquals(true, DoNotSyncCheck.checkIfNameIsNotNumber('John','Smith'));
      System.assertEquals(true, DoNotSyncCheck.checkIfNameIsNotNumber('John','Smith7'));
      System.assertEquals(false, DoNotSyncCheck.checkIfNameIsNotNumber('1','Smith'));
      System.assertEquals(false, DoNotSyncCheck.checkIfNameIsNotNumber('John','7'));
      
      Contact ctct = new Contact(LastName='Last1', FirstName='First1');
      insert ctct;
      ctct = [Select Id, Name, Do_Not_Sync__c from Contact where Id=:ctct.Id];
      System.assertEquals(true, ctct.Do_Not_Sync__c);
      
      
   } // testCheckIfNameIsNumber

   static testMethod void testLeads() {
      DoNotSyncCheck.ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = true;
      DoNotSyncCheck.CREATED_DATE_NBR_MONTHS = 6;
      DoNotSyncCheck.NAME_EXCLUDE_CRITERIA = new String[]{'blabla','Mouse'};
 
     User ecomUser = [Select Id, Name, LastName, Email from User where IsActive=true and LastName='Ecommerce' limit 1];

      Lead ld1 = new Lead(LastName='Last1', Company='Test Company1', NumberOfEmployees=1);
      Lead ld2 = new Lead(LastName='Last2', FirstName='First2', Company='Test Company2', PostalCode='12345', NumberOfEmployees=2 );
      Lead ld3 = new Lead(LastName='Last3', FirstName='First3', Company='Test Company3', Street = '3 Any St', PostalCode='12345'
                            ,Phone='(555) 123-4567', Email='last3@testing.com', NumberOfEmployees=3);
      Lead ld4 = new Lead(LastName='Last4', FirstName='blabla', Company='Test Company4', Street = '4 Any St', PostalCode='12345'
                            ,Phone='(555) 123-4567', Email='last4@testing.com', NumberOfEmployees=4);
      Lead ld5 = new Lead(LastName='5', FirstName='5', Company='Test Company5', Street='5 Any St', HasOptedOutOfEmail=true
                            ,Email='last5@testing.com');
      Lead ld6 = new Lead(LastName='Last6', FirstName='First6', Company='Test Company6', Street='6 Any St', Email='last5@testing.com',Marketing_Block_Reason__c='Marketing Duplicate');
      Lead ld7 = new Lead(LastName='Last7', Company='Test Company7', NumberOfEmployees=1, LeadSource='Purchased List');
      Lead ld8 = new Lead(LastName='Last8', Company='Test Company8', NumberOfEmployees=1, OwnedByPrev__c='eCommerce', OwnerId=ecomUser.Id);
      Lead ld9 = new Lead(LastName='Last9', FirstName='First9', Company='Test Company9', Street='9 Any St', Email='last9@testing.com',Marketing_Block_Reason__c='Always Sync');
      Lead[] leads = new Lead[]{ld1,ld2,ld3,ld4,ld5,ld6,ld7,ld8,ld9};
      insert leads;
      
      Map<Id,Lead> leadMap = new Map<Id,Lead>([Select Id, Name, FirstName, LastName, Company
                                    ,Street, City, State, PostalCode
                                    ,Email, Phone
                                    ,Do_Not_Sync__c
                                    ,HasOptedOutOfEmail
                                    ,OwnedByPrev__c
                                    ,OwnerId
                                From Lead
                               Where Id in :leads]);
      ld1 = leadMap.get(ld1.Id);
      System.assertEquals(true, ld1.Do_Not_Sync__c);
      ld2 = leadMap.get(ld2.Id);
      System.assertEquals(true, ld2.Do_Not_Sync__c);
      ld3 = leadMap.get(ld3.Id);
      System.assertEquals(false, ld3.Do_Not_Sync__c);
      ld4 = leadMap.get(ld4.Id);
      System.assertEquals(true, ld4.Do_Not_Sync__c);
      ld5 = leadMap.get(ld5.Id);
      System.assertEquals(false, ld5.Do_Not_Sync__c);
      ld6 = leadMap.get(ld6.Id);
      System.assertEquals(true, ld6.Do_Not_Sync__c);
      ld7 = leadMap.get(ld7.Id);
      System.assertEquals(true, ld7.Do_Not_Sync__c);
      ld8 = leadMap.get(ld8.Id);
      System.assertEquals(false, ld8.Do_Not_Sync__c);    
      ld8 = leadMap.get(ld9.Id);
      System.assertEquals(false, ld9.Do_Not_Sync__c);    
       
      DoNotSyncCheck.ALREADY_RAN=false;
      ld1.FirstName='First1';
      ld1.Street = '1 Any St';
      ld1.PostalCode = '12345';
      ld1.Email = 'last1@testing.com';
      // still missing the phone number
      
      ld2.Street = '2 Any St';
      ld2.Email = 'last2@testing.com';
      ld2.Phone = '(555) 123-4567';
      
      ld3.Phone = null;
      
      ld4.FirstName = 'First1';

      TriggerMethods.clearVariables();
      leads = new Lead[]{ld1,ld2,ld3,ld4};
      update leads;

      leadMap = new Map<Id,Lead>([Select Id, Name, FirstName, LastName, Company
                                    ,Street, City, State, PostalCode
                                    ,Email, Phone
                                    ,Do_Not_Sync__c
                                From Lead
                               Where Id in :leads]);
      ld1 = leadMap.get(ld1.Id);
      System.assertEquals(true, ld1.Do_Not_Sync__c);
      ld2 = leadMap.get(ld2.Id);
      System.assertEquals(false, ld2.Do_Not_Sync__c);
      ld3 = leadMap.get(ld3.Id);
      System.assertEquals(true, ld3.Do_Not_Sync__c);
      ld4 = leadMap.get(ld4.Id);
      System.assertEquals(false, ld4.Do_Not_Sync__c);
      
      DoNotSyncCheck.ALREADY_RAN=false;
      DoNotSyncCheck.ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = false;
      
      // testing that once in the sync they won't be removed from it
      ld1.Phone = '(555) 234-5678';
      
      ld2.Phone = null;
      
      ld3.Phone = '(555) 345-6789';
      
      ld4.FirstName = 'Blabla';

      TriggerMethods.clearVariables();
      leads = new Lead[]{ld1,ld2,ld3,ld4};
      update leads;

      leadMap = new Map<Id,Lead>([Select Id, Name, FirstName, LastName, Company
                                    ,Street, City, State, PostalCode
                                    ,Email, Phone
                                    ,Do_Not_Sync__c
                                From Lead
                               Where Id in :leads]);
      ld1 = leadMap.get(ld1.Id);
      System.assertEquals(false, ld1.Do_Not_Sync__c);
      ld2 = leadMap.get(ld2.Id);
      System.assertEquals(false, ld2.Do_Not_Sync__c);
      ld3 = leadMap.get(ld3.Id);
      System.assertEquals(false, ld3.Do_Not_Sync__c);
      ld4 = leadMap.get(ld4.Id);
      System.assertEquals(false, ld4.Do_Not_Sync__c);

   } // testLeads

   static testMethod void testContacts() {
      DoNotSyncCheck.ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = true;
      DoNotSyncCheck.CREATED_DATE_NBR_MONTHS = 6;
      DoNotSyncCheck.NAME_EXCLUDE_CRITERIA = new String[]{'blabla','Mouse'};
      
      ZipCheckOwnerTest.setupCustomSettings();
      Map<String,Schema.RecordTypeInfo> rtMapByName = Contact.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo ctctRtInfo = rtMapByName.get(ZipCheckOwnerTest.rtCoreCtct1.Name);
      System.assertEquals(true, ctctRtInfo != null);
      Id rtId = ctctRtInfo.getRecordTypeId();
 
      Referral_Account__c refAcct = new Referral_Account__c(Name='Ref Account', Street_Address_1__c='St', City__c='Any City', State_Province__c='St'
                                                            , Zip_Postal_Code__c='12345',Referral_Source_Business_Type__c='Other');
      insert refAcct;
       
      Referral_Contact__c refCtct = new Referral_Contact__c(Name = 'Ref Conatct', Referral_Account__c = refAcct.Id, Email__c='refCtct@test.com', Phone__c='(999) 123-4567');
      insert refCtct;
              
      Account acct1 = new Account(Name='Account1');
      Account acct2 = new Account(Name='Account2', NumberOfEmployees=2);
      Account acct3 = new Account(Name='Account3', NumberOfEmployees=3, ShippingStreet='3 Any St', ShippingPostalCode='12345', Bis_Id__c=123, First_Run_Date__c=Date.today());
      Account acct4 = new Account(Name='Account4', NumberOfEmployees=4, ShippingStreet='4 Any St', ShippingPostalCode='12345', Lost_Date__c=Date.today());
      Account acct5 = new Account(Name='Account5', NumberOfEmployees=5, ShippingStreet='5 Any St', ShippingPostalCode='12345');
      Account acct7 = new Account(Name='Account7', NumberOfEmployees=7, ShippingStreet='7 Any St', ShippingPostalCode='12345');
      Account acct8 = new Account(Name='Account8', NumberOfEmployees=8, ShippingStreet='8 Any St', ShippingPostalCode='12345');
      Account acct9 = new Account(Name='Ref Account', ShippingStreet='St', ShippingPostalCode='12345', ShippingCity='Any City', ShippingState='St',Mirror_Referral_Account__c=refAcct.Id); 
      Account acct10 = new Account(Name='Account10', NumberOfEmployees=10, ShippingStreet='10 Any St', ShippingPostalCode='12345');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct7,acct8,acct9,acct10};
      insert accts;
           
       
      Opportunity opp5= new Opportunity(AccountId=acct5.Id, Name='Opportunity 5', StageName='Pending', CloseDate=Date.today().addMonths(1));
      
     
      
      Contact ctct1 = new Contact(RecordTypeId=rtId,AccountId=acct1.Id, LastName='Last1', FirstName='First1', Email='first1@testing.com', Phone='(111) 123-4567', Sales_Contact__c=true);
      Contact ctct2 = new Contact(RecordTypeId=rtId,AccountId=acct2.Id, LastName='Last2', FirstName='First2', Email='first2@testing.com', Phone='(222) 123-4567', Sales_Contact__c=true);
      Contact ctct3 = new Contact(RecordTypeId=rtId,AccountId=acct3.Id, LastName='Last3', FirstName='Mouse', Email='first3@testing.com', Phone='(333) 123-4567', Sales_Contact__c=true);
      Contact ctct4 = new Contact(RecordTypeId=rtId,AccountId=acct4.Id, LastName='Last4', FirstName='First4');
      Contact ctct5 = new Contact(RecordTypeId=rtId,AccountId=acct5.Id, LastName='Last5', FirstName='First5', Email='first5@testing.com', Phone='(555) 123-4567', Sales_Contact__c=true, HR_Person_Id__c='555');
      Contact ctct6 = new Contact(RecordTypeId=rtId,LastName='Last6', FirstName='First6', Email='first6@testing.com', Phone='(666) 123-4567', Sales_Contact__c=true);
      Contact ctct7 = new Contact(RecordTypeId=rtId,AccountId=acct7.Id, LastName='Last7', FirstName='First7', Email='first7@testing.com', Phone='(777) 123-4567', Sales_Contact__c=true, HasOptedOutOfEmail=true);
      Contact ctct8 = new Contact(RecordTypeId=rtId,AccountId=acct8.Id, LastName='Last8', Marketing_Block_Reason__c='Marketing Duplicate'); 
      Contact ctct9 = new Contact(FirstName = 'Ref', LastName = 'Conatct', Mirror_Ref_Ctct__c=refCtct.Id, AccountId=acct9.Id, OwnerId = Label.ReferralOwnerName,
                                 Email='refCtct@test.com', Phone='(999) 123-4567');
      Contact ctct10 = new Contact(RecordTypeId=rtId,AccountId=acct10.Id, LastName='Last10', Marketing_Block_Reason__c='Always Sync'); 
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5,ctct6,ctct7,ctct8,ctct9,ctct10};
      insert ctcts;
      
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, AccountId, Name
                                                           ,FirstName, LastName, Email, Phone
                                                           ,Sales_Contact__c, HR_Person_Id__c
                                                           ,Do_Not_Sync__c
                                                       From Contact
                                                      Where Id in :ctcts]);
                                                      
      ctct1 = ctctMap.get(ctct1.Id);
      System.assertEquals(true, ctct1.Do_Not_Sync__c);
      ctct2 = ctctMap.get(ctct2.Id);
      System.assertEquals(true, ctct2.Do_Not_Sync__c);
      ctct3 = ctctMap.get(ctct3.Id);
      System.assertEquals(true, ctct3.Do_Not_Sync__c);
      ctct4 = ctctMap.get(ctct4.Id);
      System.assertEquals(true, ctct4.Do_Not_Sync__c);
      ctct5 = ctctMap.get(ctct5.Id);
      System.assertEquals(true, ctct5.Do_Not_Sync__c);
      ctct6 = ctctMap.get(ctct6.Id);
      System.assertEquals(true, ctct6.Do_Not_Sync__c);
      ctct7 = ctctMap.get(ctct7.Id);
      System.assertEquals(false, ctct7.Do_Not_Sync__c);
      ctct8 = ctctMap.get(ctct8.Id);
      System.assertEquals(true, ctct8.Do_Not_Sync__c);
      ctct9 = ctctMap.get(ctct9.Id);
      System.assertEquals(false, ctct9.Do_Not_Sync__c);
      ctct10 = ctctMap.get(ctct10.Id);
      System.assertEquals(false, ctct10.Do_Not_Sync__c);
      
      acct1.NumberOfEmployees=1;
      acct1.ShippingStreet='1 Any St';
      acct1.ShippingPostalCode='12345';
      
      acct2.ShippingStreet='2 Any St';
      acct2.ShippingPostalCode='12345';
      accts = new Account[]{acct1,acct2};
      
      // so the account trigger fires again.
      ZipCheckOwner.SKIP_TRIGGERS = false;
      AccountMethods.callDispositionHandledSet.clear();
      update accts;
      
      DoNotSyncCheck.ALREADY_RAN=false;
      TriggerMethods.clearVariables();
      ctct3.FirstName='First3';
      ctct4.Email='first4@testing.com';
      ctct4.Phone='(444) 123-4567';
      ctct4.Sales_Contact__c=true;
      
      ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5,ctct6};
      update ctcts;
      
      ctctMap = new Map<Id,Contact>([Select Id, AccountId, Name
                                                           ,FirstName, LastName, Email, Phone
                                                           ,Sales_Contact__c, HR_Person_Id__c
                                                           ,Do_Not_Sync__c
                                                       From Contact
                                                      Where Id in :ctcts]);
                                                      
      ctct1 = ctctMap.get(ctct1.Id);
      System.assertEquals(true, ctct1.Do_Not_Sync__c);
      ctct2 = ctctMap.get(ctct2.Id);
      System.assertEquals(true, ctct2.Do_Not_Sync__c);
      ctct3 = ctctMap.get(ctct3.Id);
      System.assertEquals(false, ctct3.Do_Not_Sync__c);
      ctct4 = ctctMap.get(ctct4.Id);
      System.assertEquals(false, ctct4.Do_Not_Sync__c);
      ctct5 = ctctMap.get(ctct5.Id);
      System.assertEquals(true, ctct5.Do_Not_Sync__c);
      ctct6 = ctctMap.get(ctct6.Id);
      System.assertEquals(true, ctct6.Do_Not_Sync__c);
      
      // make these accounts client records
      acct1.Bis_Id__c=124;
      acct1.First_Run_Date__c=Date.today();

      acct2.Bis_Id__c=125;
      acct2.First_Run_Date__c=Date.today();
      
      acct5.Bis_Id__c=126;
      acct5.First_Run_Date__c=Date.today();
      
      accts = new Account[]{acct1,acct2,acct5};

      // remove this - should put it into the sync.
      ctct5.HR_Person_Id__c=null;
      ctct5.AccountId = acct5.Id;
      
      ZipCheckOwner.SKIP_TRIGGERS = false;
      AccountMethods.callDispositionHandledSet.clear();
      update accts;
      
      DoNotSyncCheck.ALREADY_RAN=false;
      TriggerMethods.clearVariables();
      
      ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5,ctct6};
      update ctcts;
      
      ctctMap = new Map<Id,Contact>([Select Id, AccountId, Name
                                                           ,FirstName, LastName, Email, Phone
                                                           ,Sales_Contact__c, HR_Person_Id__c
                                                           ,Do_Not_Sync__c
                                                       From Contact
                                                      Where Id in :ctcts]);
                                                      
      ctct1 = ctctMap.get(ctct1.Id);
      System.assertEquals(false, ctct1.Do_Not_Sync__c);
      ctct2 = ctctMap.get(ctct2.Id);
      System.assertEquals(false, ctct2.Do_Not_Sync__c);
      ctct3 = ctctMap.get(ctct3.Id);
      System.assertEquals(false, ctct3.Do_Not_Sync__c);
      ctct4 = ctctMap.get(ctct4.Id);
      System.assertEquals(false, ctct4.Do_Not_Sync__c);
      ctct5 = ctctMap.get(ctct5.Id);
      System.assertEquals(false, ctct5.Do_Not_Sync__c);
      ctct6 = ctctMap.get(ctct6.Id);
      System.assertEquals(true, ctct6.Do_Not_Sync__c);


   } // testContacts

   static testMethod void testOther() {
      DoNotSyncCheck.ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = true;
      DoNotSyncCheck.CREATED_DATE_NBR_MONTHS = 6;

      // get the running user and set as the "Marketo" user
      User runningUser = UserHelper.getRunningUser();
      DoNotSyncCheck.MARKETO_SYNC_USER = runningUser.Name;
      Lead ld = new Lead(LastName='LeadLast', Company='Lead Company', Email='test@testing.com');
      System.debug('testOther test 1');
      insert ld;
      // this should be false because of the user
      ld = [Select Id, Name, LastName, Company, Email, Do_Not_Sync__c, CreatedByProcess__c from Lead where Id=:ld.Id];
      System.assertEquals(false, ld.Do_Not_Sync__c);
      System.assertEquals(DoNotSyncCheck.CREATED_BY_MARKETO, ld.CreatedByProcess__c);

      Account acct = new Account(Name='Test Account');
      System.debug('testOther test 2');
      insert acct;
      
      Contact ctct = new Contact(AccountId=acct.Id, LastName='TestLast');      
      DoNotSyncCheck.ALREADY_RAN=false;
      System.debug('testOther test 3');
      insert ctct;
      ctct = [Select Id, AccountId, LastName, FirstName, Email, Phone, Do_Not_Sync__c from Contact where Id=:ctct.Id];
      System.assertEquals(false, ctct.Do_Not_Sync__c);

      Test.setCreatedDate(ld.Id, Datetime.now().addMonths(-7));
      Test.setCreatedDate(ctct.Id, Datetime.now().addMonths(-7));
      
      DoNotSyncCheck.ALREADY_RAN=false;
      // so we don't try to retrieve it again
      DoNotSyncCheck.marketoSyncUser = null;
      DoNotSyncCheck.MARKETO_SYNC_USER = 'Bad Name';
      Cache.Org.remove(DoNotSyncCheck.CACHE_KEY);
      
      // because of the created by process will remain false
      System.debug('testOther test 4');
      TriggerMethods.clearVariables();
      update ld;
      ld = [Select Id, Name, LastName, Company, Email, Do_Not_Sync__c, CreatedByProcess__c from Lead where Id=:ld.Id];
      System.assertEquals(false, ld.Do_Not_Sync__c);

      DoNotSyncCheck.ALREADY_RAN=false;
      // based on the date, remove from the sync
      ld.CreatedByProcess__c = null;
      System.debug('testOther test 5');
      TriggerMethods.clearVariables();
      update ld;
      ld = [Select Id, Name, LastName, Company, Email, Do_Not_Sync__c, CreatedByProcess__c from Lead where Id=:ld.Id];
      System.assertEquals(true, ld.Do_Not_Sync__c);

      DoNotSyncCheck.ALREADY_RAN=false;
      ctct.CreatedByProcess__c = null;
      System.debug('testOther test 6');
      update ctct;
      ctct = [Select Id, AccountId, LastName, FirstName, Email, Phone, Do_Not_Sync__c from Contact where Id=:ctct.Id];
      System.assertEquals(true, ctct.Do_Not_Sync__c);
      
   } // testOther

   static testMethod void testBulkLead() {
      DoNotSyncCheck.ALLOW_REMOVE_FROM_SYNC_ON_UPDATE = true;
      DoNotSyncCheck.CREATED_DATE_NBR_MONTHS = 6;
      DoNotSyncCheck.NAME_EXCLUDE_CRITERIA = new String[]{'blabla','Mouse'};
      
      Lead[] leads1 = new Lead[]{};
      for (Integer cnt=0; cnt<100; cnt++) {
         leads1.add(new Lead(LastName='Last'+cnt, FirstName='First'+cnt, Company='Test Company'+cnt, NumberOfEmployees=cnt ));
      } // for
      Lead[] leads2 = new Lead[]{};
      for (Integer cnt=100; cnt<200; cnt++) {
         leads2.add(new Lead(LastName='Last'+cnt, FirstName='First'+cnt, Company='Test Company'+cnt, Street = cnt+' Any St', PostalCode='12345'
                            ,Phone='(555) 123-4567', Email='last'+cnt+'@testing.com', NumberOfEmployees=cnt));
      }
      Lead[] allLeads = new Lead[]{};
      allLeads.addAll(leads1);
      allLeads.addAll(leads2);
      
      Test.startTest();
      insert allLeads;
      Test.stopTest();
      
      System.assertEquals(100, [select count() from Lead where Do_Not_Sync__c=true and Id in :leads1]);
      System.assertEquals(100, [select count() from Lead where Do_Not_Sync__c=false and Id in :leads2]);
      
      for (Lead ld : leads1) {
         ld.Street = ld.NumberOfEmployees+' Any St';
         ld.PostalCode='12345';
         ld.Phone='(555) 123-4567';
         ld.Email='last'+ld.NumberOfEmployees+'@testing.com';
      }
      for (lead ld : leads2) {
         ld.Email = null;
      }
      TriggerMethods.clearVariables();
      update allLeads;
      
      System.assertEquals(100, [select count() from Lead where Do_Not_Sync__c=false and Id in :leads1]);
      System.assertEquals(100, [select count() from Lead where Do_Not_Sync__c=true and Id in :leads2]);

   } // testBulkLead

   static testMethod void testAcctSync() {
      // we don't want the contact before to fire for this test
      TriggerSetupClasses__c[] settings = [Select Id from TriggerSetupClasses__c where ClassName__c='DoNotSyncCheck' and TriggerKey__c='ContactBefore'];
      delete settings;

      Account acct1 = new Account(Name='Account1', Contact_Email_Available__c=true);
      Account acct2 = new Account(Name='Account2', Contact_Email_Available__c=true);
      Account acct3 = new Account(Name='Account3', Contact_Email_Available__c=false);
      Account acct4 = new Account(Name='Account4', Contact_Email_Available__c=false);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Contact ctct1a = new Contact(AccountId=acct1.Id, LastName='Last1a', Email='last1a@test.com', Do_Not_Sync__c=true);
      Contact ctct1b = new Contact(AccountId=acct1.Id, LastName='Last1b', Email='last1b@test.com', Do_Not_Sync__c=true);
      Contact ctct2a = new Contact(AccountId=acct2.Id, LastName='Last2a', Email='last2a@test.com', Do_Not_Sync__c=true);
      Contact ctct2b = new Contact(AccountId=acct2.Id, LastName='Last2b', Email='last2b@test.com', Do_Not_Sync__c=false);
      Contact ctct3a = new Contact(AccountId=acct3.Id, LastName='Last3a', Email='last3a@test.com', Do_Not_Sync__c=false);
      Contact ctct3b = new Contact(AccountId=acct3.Id, LastName='Last3b', Email='last3b@test.com', Do_Not_Sync__c=false);
      Contact ctct4a = new Contact(AccountId=acct4.Id, LastName='Last4a', Email='last4a@test.com', Do_Not_Sync__c=true);
      Contact ctct4b = new Contact(AccountId=acct4.Id, LastName='Last4b', Email='last4b@test.com', Do_Not_Sync__c=false);
      Contact[] ctcts = new Contact[]{ctct1a,ctct1b,ctct2a,ctct2b,ctct3a,ctct3b,ctct4a,ctct4b};
      
      Test.startTest();
      insert ctcts;
      Test.stopTest();
      
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, Contact_Email_Available__c from Account where Id in :accts]);
      
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.Contact_Email_Available__c);

      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.Contact_Email_Available__c);

      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.Contact_Email_Available__c);
      
      acct4 = acctMap.get(acct4.Id);
      System.assertEquals(true,acct4.Contact_Email_Available__c);
      
   } // testAcctSync

    static testMethod void refCtctTest(){
     
      
    } 

} // class DoNotSyncCheckTest