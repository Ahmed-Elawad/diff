/** Test methods for the ContactMethods class
 *
 * History
 * -------
 * 01/17/2014 Dan Carmen        Created.
   02/12/2015 Dan Carmen        Log changes made to the contact in a related object.
   05/11/2016 Jacob Hinds    Added testing for bypass nss
   11/14/2017 Dan Carmen        Update for test execution
   01/12/2018 Jacob Hinds    commenting out testCallDisposition
   08/09/2018 Cindy Freeman    add tests for PEOC logic
   08/23/2018 Dan Carmen        Clean up the checkOwnedBy code - removed unneccessary work.
   03/19/2019 Jake Hinds        Changing PEOC to not use campaigns and use product division instead
   06/30/2021 Dan Carmen        Clear email verification when email changes, format phone numbers
   01/07/2022 Dan Carmen        Remove PeoHelper code

*/
@isTest
private class ContactMethodsTest {

   static testMethod void testDialed() {
      LeadMethods.DISABLE_DIAL_CHECKBOX = false;
      // create the lead call disposition custom setting
      LeadCallDisposition__c[] lcds = LeadMethodsTest.createLeadCallDispositions();
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);

      AccountMethodsTest.setupTestAcctCtct(1); 

      // reselect the contact
      Contact ctct = [Select AccountId, Account.Id, Account.Name, Dialed__c, FirstName, LastName, Name, Phone, Products__c from Contact where Id=:AccountMethodsTest.testCtcts[0].Id];
      
      // select an outbound NSR
      User nsrOutbound1 = ProspectOwnershipMethodsTest.getOutboundNSRs(1)[0];
      
      AccountShare acctShare1 = new AccountShare(AccountId=ctct.AccountId,AccountAccessLevel='Edit',ContactAccessLevel='Edit',OpportunityAccessLevel='Edit',UserOrGroupId=nsrOutbound1.Id);
      // to make sure the user have permissions
      insert acctShare1;

      System.runAs(nsrOutbound1) {
         ctct.Dialed__c = true;
         update ctct;
      
      }
      // verify ownership record was created with the status
      Prospect_Ownership__c[] pos = ProspectOwnershipMethods.getByAcctId(AccountMethodsTest.testAcct.Id);
      Prospect_Ownership__c po = pos[0];
      System.assertEquals(po.Decision_Maker__c, ctct.Id);
   } // testDialed
  /*
   static testMethod void testCallDisposition() {
      // create the lead call disposition custom setting
      LeadCallDisposition__c[] lcds = LeadMethodsTest.createLeadCallDispositions();
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createNotInterestedLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
      
      AccountMethodsTest.setupTestAcctCtct(1);

      AccountMethodsTest.testCtcts[0].NSSStatus__c = lcds[3].CurrentLeadStatus__c;
      AccountMethodsTest.testCtcts[0].NSSCallDisposition__c = lcds[3].CallDisposition__c;
      update AccountMethodsTest.testCtcts[0];
      
      // verify ownership record was created with the status
      Prospect_Ownership__c[] pos = ProspectOwnershipMethods.getByAcctId(AccountMethodsTest.testAcct.Id);
      Prospect_Ownership__c po = pos[0];
      System.assertEquals(po.Ownership_Status__c, lcds[3].NewOwnershipStatus__c);
   } // testCallDisposition
   */
   static testMethod void testContactOwnedBy() {
      LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);

      AccountMethodsTest.setupTestAcctCtct(1);
      Account acct = AccountMethodsTest.testAcct;
      
      User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];
      
      Account acct2 = new Account(Name='TestAccount2',OwnerId=testSalesRep.Id);
      insert acct2;
      
      // set the running user as a "Lead Loader" user so the trigger will fire
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
      System.assertEquals(true,UserHelper.isLeadLoader(runningUser.Name));
      
      Campaign cm1 = new Campaign(Name='Test Campaign 1',Status='Planned',IsActive=true,Originator__c='Marketing',Worked_By__c='VirtualSales',Send_To_Virtual__c='Always',StartDate=system.today());
      Campaign cm2 = new Campaign(Name='Test Campaign 2',Status='Planned',IsActive=true,Originator__c='Marketing',Worked_By__c='VirtualSales',Send_To_Virtual__c='Check Zips',StartDate=system.today());      
      Campaign[] cms = new Campaign[]{cm1,cm2};
      insert cms;
     
      User vsu = [SELECT Name,Id FROM User WHERE Name='Virtual Sales' AND Sales_Org__c='PAY' LIMIT 1];
      User vsr = [SELECT Name,Id FROM User WHERE UserRole.Name like '%Virtual%' AND NSS_Team__c = 'VS PAY' LIMIT 1];
     
      system.debug('vsr: '+vsr);
     
      ZipCheckOwnerTest.setupSegments();
     
      Zip_Segment__c zs = ZipCheckOwnerTest.coreSeg1;
      zs.Id = null;
      zs.Name = 'DEFAULT';
      insert zs;
     
       Zip_Assignment__c za1 = new Zip_Assignment__c(Name='11111', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=runningUser.Name,User__c=runningUser.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name='22222', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=vsu.Name,User__c=vsu.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name='33333', HR_Person_Id__c=null,Emps_Min__c=0, Emps_Max__c=100,
                                               Asset_Min__c=0, Asset_Max__c=100,
                                               Sales_Org__c='PAY', MC_Id__c='TestPAY',
                                               Rep_Name__c=vsr.Name,User__c=vsr.Id,
                                               Segment_Name__c=zs.Name,
                                               Zip_Segment__c=zs.Id);                                          
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3};
      insert zas;
     
      Group vq = [SELECT Id,Name FROM Group WHERE Type='Queue' AND Name = 'Virtual Sales Queue' LIMIT 1];
      
      BypassNSS__c bypassSetting = BypassNSS__c.getOrgDefaults();
      if(bypassSetting.SetupOwnerId==null){
        bypassSetting = new BypassNSS__c(SetupOwnerId=UserInfo.getOrganizationId(), IsActive__c=true,Queue_Id__c=vq.Id,Queue_Name__c=vq.Name,Partner_Referral_Expiration_Duration__c=1,Holdout_Expiration__c=1);
        insert bypassSetting; 
      }
      // create the custom settings
      LeadLoaderConfig__c config1 = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c='Test Inbound', UseAssignmentRules__c=false, StoreOrginalData__c=true);
      LeadLoaderConfig__c config2 = new LeadLoaderConfig__c(Name='Test Outbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_OUTBOUND, QueueName__c='Test Outbound', UseAssignmentRules__c=false);
      LeadLoaderConfig__c config3 = new LeadLoaderConfig__c(Name='Test Assignment Rules', IsActive__c=true, NSSSource__c=null, QueueName__c=null, UseAssignmentRules__c=true);
      LeadLoaderConfig__c[] configs = new LeadLoaderConfig__c[]{config1,config2,config3};
      insert configs;
      
      // create a new contact
      Contact ctct = new Contact(LastName='NewLast', AccountId=acct.Id, OwnedBy__c=config1.Name);
      Contact ctct2 = new Contact(LastName='TestCt',AccountId=acct2.Id, OwnedBy__c=config1.Name,MailingPostalCode = za3.Name,LatestCampaign__c=cm1.Id);
      Contact[] ctcts = new Contact[]{ctct,ctct2};
      insert ctcts;
      
      //Contact ctct = new Contact(LastName='NewLast', AccountId=acct.Id, OwnedBy__c=config1.QueueName__c);
      //insert ctct;
      //Contact ctct2 = new Contact(LastName='TestCt',AccountId=acct2.Id, OwnedBy__c=config1.QueueName__c);
      //insert ctct2;
      
      ctct = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c from Contact where Id=:ctct.Id];
      System.assertEquals(config1.QueueName__c, ctct.NSSOwnership__c);
      System.assertEquals(null, ctct.OwnedBy__c);
      System.assertEquals(config1.Name, ctct.OwnedByPrev__c);
      
      acct = [Select Id, Name, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct.Id, acct.SignificantContact__c);
      
      //PartnerReferral__c partRef = [SELECT Id FROM PartnerReferral__c WHERE Contact__c =:ctct.Id LIMIT 1];
      //system.assert(partRef!=null);
      
      ctct2 = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c from Contact where Id=:ctct2.Id];
      System.assertEquals(vq.Name, ctct2.NSSOwnership__c);
      System.assertEquals(null, ctct2.OwnedBy__c);
      System.assertEquals(config1.Name, ctct.OwnedByPrev__c);
      
      //PartnerReferral__c partRef2 = [SELECT Id FROM PartnerReferral__c WHERE Contact__c =:ctct2.Id LIMIT 1];
      //system.assert(partRef!=null);
      
      ctct2.OwnedBy__c = config1.Name;
      ctct2.MailingPostalCode = za3.Name;
      ctct2.LatestCampaign__c = cm2.Id;
      update ctct2;
      
      ctct2 = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c,OwnerId from Contact where Id=:ctct2.Id];
      //System.assertEquals(vsr.Id, ctct2.OwnerId);
      System.assertEquals(null, ctct2.OwnedBy__c);
      System.assertEquals(config1.Name, ctct.OwnedByPrev__c);
    
    //PartnerReferral__c partRef3 = [SELECT Id,Master_Partner_Referral__c FROM PartnerReferral__c WHERE Contact__c =:ctct2.Id ORDER BY CreatedDate DESC LIMIT 1];
      //system.assertEquals(partRef2.Id,partRef3.Master_Partner_Referral__c);
    
      ctct.OwnedBy__c = config2.Name;
      ctct.MailingPostalCode = za1.Name;
      update ctct;
      
      ctct = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c from Contact where Id=:ctct.Id];
      System.assertEquals(config2.QueueName__c, ctct.NSSOwnership__c);
      System.assertEquals(null, ctct.OwnedBy__c);
      System.assertEquals(config2.Name, ctct.OwnedByPrev__c);
      
      acct = [Select Id, Name, SignificantContact__c from Account where Id=:acct.Id];
      System.assertEquals(ctct.Id, acct.SignificantContact__c);
      
      // create an outbound ownership record
      Prospect_Ownership__c po = new Prospect_Ownership__c(Decision_Maker__c=ctct.Id, Prospect_Client__c=acct.Id, StartDate__c=Date.today()
                                       ,ProspectingStart__c=Date.today(), NSR_Name__c=runningUser.Id, NSS_Source__c=ProspectOwnershipMethods.NSS_OUTBOUND, NSS_Team__c=UserHelper.SO_CORE);
      insert po;
      
      ctct.OwnedBy__c = config1.Name;
      update ctct;
      
      ctct = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c from Contact where Id=:ctct.Id];
      System.assertEquals(config1.QueueName__c, ctct.NSSOwnership__c);
      System.assertEquals(null, ctct.OwnedBy__c);
      System.assertEquals(config1.Name, ctct.OwnedByPrev__c);

   } // testContactOwnedBy
   /* test for Contact Flopper stuff 
   static testMethod void testClone() {
        CreateTestData.createSingleAandTwoCts();       
        Contact[] existingCtcts = [select Id, Firstname, Lastname, AccountId, Duplicate_OK__c from Contact where Account.Name = 'Test Account1'];
        
        Boolean foundDuplicate = ContactMethods.checkForDuplicate(existingCtcts[0]);
        System.assertEquals(false, foundDuplicate);             // false coz cant see any DB scenarios!
        
        existingCtcts[0].FirstName = 'Second';
        existingCtcts[0].Copy_Contact__c = true;
        update existingCtcts[0];
        List<Contact> updatedCtcts = new List<Contact>();
        updatedCtcts = [select Id, FirstName, LastName, Account.Name, AccountId, Account.RecordTypeId, Copy_Contact__c, RecordTypeId
                                    from Contact
                                    where Account.Name = 'Test Account1'];      
        System.assertEquals(3, updatedCtcts.size());
        
        Contact tempCtct = new Contact(Firstname = 'Third'
                                ,Lastname = 'Last1'
                                ,AccountId = updatedCtcts[0].AccountId
                                ,recordtypeId = updatedCtcts[0].recordTypeId
                                ,Duplicate_OK__c = true);
        Boolean clonedOK = ContactMethods.cloneCtct(tempCtct);
        System.assertEquals(true, clonedOK);
        Contact clonedCt = [Select Id, Name, AccountId, Copy_Contact__c, Duplicate_OK__c, NSSStatus__c, LeadSource from Contact 
                            where Name = 'Third Last1'];
        System.assertEquals('Contacted', clonedCt.NSSStatus__c);
        System.assertEquals('Lead Referral', clonedCt.LeadSource);
                
    } //testClone
   */
   
   static testMethod void testCheckForContactChange() {
     // make sure the flag is true (even if the label changes) so the test passes
     ContactMethods.CHANGE_TRIGGER_ENABLED=true;
      Account acct = new Account(Name='Test Acct');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
       
      Contact c1 = new Contact(AccountId=acct.Id, LastName='John', Email='john@thisisatest.com',Phone='(555) 555-1234', MailingStreet='123 Any Street', MailingCity='SomeCity',MailingState='NY',MailingPostalCode='12345');
      insert c1;
      
      // keep a copy of the original to compare values
      Contact c2 = c1.clone();
      
      c1.Email='john2@thisisatest.com';
      c1.Phone='(555) 555-4321';
      c1.MailingStreet='321 Any Street'; 
      c1.MailingCity='SomeOtherCity';
      c1.MailingState='MA';
      c1.MailingPostalCode='54321';
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.contactsCheckedForChangeSet.clear();
      update c1;
      
      /* test is failing in production - not sure why. Will check it later. */
      ContactChange__c change = [Select Id, ChangeExternalId__c, City__c, CityPrev__c, Contact__c
                                       ,Email__c, EmailPrev__c
                                       ,Phone__c, PhonePrev__c
                                       ,PostalCode__c, PostalCodePrev__c
                                       ,State__c, StatePrev__c
                                       ,Street__c, StreetPrev__c, UserType__c
                                   From ContactChange__c
                                  Where Contact__c = :c1.Id];
                                  
      System.assertEquals(UserHelper.TYPE_USER,change.UserType__c);
      System.assertEquals(c1.Email, change.Email__c);
      System.assertEquals(c1.Phone, change.Phone__c);
      System.assertEquals(c1.MailingCity, change.City__c);
      System.assertEquals(c1.MailingPostalCode, change.PostalCode__c);
      System.assertEquals(c1.MailingState, change.State__c);
      System.assertEquals(c1.MailingStreet, change.Street__c);
      
      System.assertEquals(c2.Email, change.EmailPrev__c);
      System.assertEquals(c2.Phone, change.PhonePrev__c);
      System.assertEquals(c2.MailingCity, change.CityPrev__c);
      System.assertEquals(c2.MailingPostalCode, change.PostalCodePrev__c);
      System.assertEquals(c2.MailingState, change.StatePrev__c);
      System.assertEquals(c2.MailingStreet, change.StreetPrev__c);
      
   } // testCheckForContactChange
   
    /*
   // test for PEOC logic
   static testMethod void testContactOwnedByPEOC() {
       LifeOfLeadSettings__c lols = ProspectOwnershipMethodsTest.createProspectingLols(UserHelper.SO_CORE, ProspectOwnerShipMethods.NSS_OUTBOUND);
    // create the custom settings
      LeadLoaderConfig__c config1 = new LeadLoaderConfig__c(Name='Test Inbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_INBOUND, QueueName__c='Test Inbound', UseAssignmentRules__c=false);
      LeadLoaderConfig__c config2 = new LeadLoaderConfig__c(Name='Test Outbound', IsActive__c=true, NSSSource__c=ProspectOwnershipMethods.NSS_OUTBOUND, QueueName__c='Test Outbound', UseAssignmentRules__c=false);
      LeadLoaderConfig__c config3 = new LeadLoaderConfig__c(Name='Test Assignment Rules', IsActive__c=true, NSSSource__c=null, QueueName__c=null, UseAssignmentRules__c=true);
      LeadLoaderConfig__c[] configs = new LeadLoaderConfig__c[]{config1,config2,config3};
      insert configs;
      
      LeadRouting__c lr = new LeadRouting__c(Name='SendToVirtual-PEO Centric Ownership',CheckforOtherZips__c = true);
      insert lr;
      
      User testSalesRep = [Select Id, Name, Profile.Name, UserRole.Name from User where Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE and IsActive=true limit 1];
      
    ZipCheckOwnerTest.setupZipsAndSegments(true);
    
      List<String> peoProductSet = new List<String>(Label.Product_Division_PEO.split(';'));
      
    Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
      Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
      
    Account acct1 = new Account(name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Flex Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,NumberOfEmployees = 10);
    insert acct1;
    
    Account acct2 = new Account(name = 'Test Account2'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Flex Client'
                                ,BillingPostalCode = '14514'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25
                                ,NumberOfEmployees = 10);
    insert acct2;
    
    Contact ctct2 = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last2'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct2.Id
                                ,OwnedBy__c=config3.Name
                                ,Product_Division__c = peoProductSet[0]);
      insert ctct2;
              
    Test.startTest();
    
    // set the running user as a "Lead Loader" user so the trigger will fire
      User runningUser = UserHelper.getRunningUser();
      ProcessNameMap__c pnm = UserHelperTest.setupProcessName(UserHelper.PREFIX_LL,runningUser.Name);
      
      System.assertEquals(true,UserHelper.isLeadLoader(runningUser.Name));
     
      // insert ctct onto existing account, account should change to prospecting account and update contact owners
      Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c=config3.Name
                                ,Product_Division__c = peoProductSet[0]);
      insert ctct1;
      
      Account updatedAcct1 = [select Id, ownerId, RecordType.Name, HNBF_Account_Owner__c, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c
                    from Account where Name = 'Test Account1'];
    System.assertEquals('Prospect',updatedAcct1.RecordType.Name);
    System.assertNotEquals(updatedAcct1.OwnerId, acct1.OwnerId);    
    Contact updatedCtct1 = [select Id, ownerId, RecordType.Name from Contact where Lastname = 'Last1'];
    System.assertEquals(updatedAcct1.OwnerId, updatedCtct1.OwnerId);
    
    // insert ctct onto existing Prospect account (that was just updated), owner should come down from account
    Contact ctct3 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last3'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast3@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id
                                ,OwnedBy__c=config3.Name
                                ,Products__c = peoProductSet[0]);
      insert ctct3;
      Contact updatedCtct3 = [select Id, ownerId, recordTypeId, RecordType.Name from Contact where Lastname = 'Last3'];
    System.assertEquals(updatedAcct1.OwnerId, updatedCtct3.OwnerId);
    System.assertEquals(ctctCorert.getRecordTypeId(), updatedCtct3.recordTypeId);
    
    
    // update existing ctct on existing account, does account change to Prospect and update all owners?
    ctct2.OwnedBy__c = config3.Name;
    update ctct2;
    
    Account updatedAcct2 = [select Id, ownerId, RecordType.Name, HNBF_Account_Owner__c, HRS_Account_Owner__c, Premier_PBS_Account_Owner__c
                    from Account where Name = 'Test Account2'];
    System.assertEquals('Prospect',updatedAcct2.RecordType.Name);
    System.assertNotEquals(updatedAcct2.OwnerId, acct2.OwnerId);
    
    Contact updatedCtct2 = [select Id, ownerId, RecordType.Name from Contact where Lastname = 'Last2'];
    System.assertEquals(updatedAcct2.OwnerId, updatedCtct2.OwnerId);
    
    Test.stopTest();   
        
                
   } // testContactOwnedByPEOC
   */
} // ContactMethodsTest