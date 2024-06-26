/**
 * Test class for DataFluxDeltaService web service callout
 * History
 * -------
 * 04/15/2014 Cindy Freeman   Created
 * 08/30/2016 Josh Cartwright changed end point **
   02/06/2018 Dan Carmen        Adjust tests
   09/18/2018 Dan Carmen         Adjust test for new Lead Company methods
   05/23/2019 Dan Carmen         Added field missing from test
   07/20/2021 Dan Carmen        Streamline update code, add dataflux fields to ref acct/ctct.
   03/08/2022 Dan Carmen        Set the Lead Dataflux Id to remove a workflow.
   01/30/2022 Dan Carmen        Update to allow future calls
   03/17/2024 Dan Carmen        Update to create the message only when it's actually sending it

 */
@isTest
public class DataFluxDeltaServiceTest {

   @testSetup
   public static void setupData() {
      TriggerMethodsTest.createTriggerSetting('LeadAfter', false, true, false, false,new String[]{'LeadCompanyMethods'});
      TriggerMethodsTest.createTriggerSetting('LeadBefore', true, false, false, false,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.createTriggerSetting('AccountDelete', false, false, true, true,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.createTriggerSetting('ContactDelete', false, false, true, false,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.createTriggerSetting('LeadDelete', false, false, true, false,new String[]{DataFluxDeltaService.CLASSNAME});
      TriggerMethodsTest.saveSetupClasses();

      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=DataFluxDeltaBatch.CLASSNAME, Active__c=true, AdditionalEmails__c='jim@smith.com');
      insert abc;
      populateEndpoint();
   } // setupData

   public static void disableDeltaTriggers() {
      // no longer needed - using TriggerMethods
   } // disableDeltaTriggers

    /*
    // test Web Service Log with no request attachment
    static testMethod void testNoRequest() {
        Test.startTest();
        DataFluxDeltaService.ALLOW_TEST_TO_RUN = true;
        Web_Service_Log__c log = new Web_Service_Log__c();
        log.ServiceName__c = 'DFDeltaSvc';
        log.SendMsg__c = true;
        log.SobjName__c = 'Contact';
        log.NamedFunction__c = 'DELTA_JOB_CONTACT';
        log.Action__c = 'Modify';
        insert log; 
        
        DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch();
        Database.executeBatch(dfdb);
        Test.stopTest();
        Web_Service_Log__c newWslog = [select Id, Name, ErrorMsg__c, Notes__c, Successful__c, SendMsg__c from Web_Service_Log__c 
                                        where CreatedDate = TODAY];
        System.assertEquals(false, newWslog.Successful__c);
        System.assertEquals(false, newWslog.SendMsg__c);
        System.assertEquals(true, newWslog.ErrorMsg__c.contains('No request'));
    }
    */
    // test insert of multiple Leads
    static testMethod void testLeadInsert() {
        List<Id> createdLeadList = CreateTestData.createTestLeadMany();

        Lead[] leads = [Select id, Name, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                          From Lead
                         Where Id in :createdLeadList];
        for (Lead ld : leads) {
           System.debug('testLeadInsert ld='+ld);
           Assert.isTrue(ld.Dataflux_Force_Delta__c);
           Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, ld.DatafluxSyncOperation__c, 'Operation is '+ld.DatafluxSyncOperation__c);
           Assert.isNotNull(ld.DatafluxSyncTime__c);
           Assert.isNull(ld.DatafluxLastSyncTime__c);
        }

        DataFluxDeltaServiceMock mockResp = new DataFluxDeltaServiceMock();
        mockResp.responseToUse = DataFluxDeltaServiceMock.makeLeadResponseXML2();
        Test.setMock(HttpCalloutMock.class, mockResp);
 
        Test.startTest();
        DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch(ObjectHelper.OBJECT_LEAD);
        Database.executeBatch(dfdb,10);                         
        Test.stopTest();        

        List<Lead> updatedList = [Select Id, LastName, Dataflux_Id__c, LeadGroupId__c, Lead_Company__c, SignificantLead__c 
                                        ,DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                                    from Lead 
                                    where id in :createdLeadList];
                                    
        for (Lead ld : updatedList) {
           System.debug('testLeadInsert ld='+ld);
           if (ld.LastName == 'Lead1') {
              Assert.isTrue(ld.SignificantLead__c);
              Assert.areEqual('123456789', ld.Dataflux_Id__c);
              Assert.isFalse(ld.Dataflux_Force_Delta__c);
              Assert.isNull(ld.DatafluxSyncOperation__c);
              Assert.isNull(ld.DatafluxSyncTime__c);
              Assert.isNotNull(ld.DatafluxLastSyncTime__c);
           } else if (ld.LastName == 'Lead2') {
              System.assertEquals('111222333', ld.Dataflux_Id__c);
              Assert.isFalse(ld.Dataflux_Force_Delta__c);
              Assert.isNull(ld.DatafluxSyncOperation__c);
              Assert.isNull(ld.DatafluxSyncTime__c);
              Assert.isNotNull(ld.DatafluxLastSyncTime__c);
           }
        } // for
         
        Web_Service_Log__c[] newWslogs = [select Id, Name, ErrorMsg__c, Notes__c, Successful__c, SendMsg__c from Web_Service_Log__c 
                                         where ServiceName__c = 'DFDeltaSvc' and CreatedDate = TODAY];
        System.assertEquals(1, newWslogs.size());
        for (Web_Service_Log__c log: newWslogs) {
            Assert.isFalse(log.SendMsg__c);
            Assert.isTrue(log.Successful__c);
        }
    }// testLeadInsert
   
   // test LeadDelete triggers
   static testMethod void testLeadDelete() {
      LeadCompanyMethods.SKIP_FUTURE=true;
      Test.startTest();
      Lead ld1 = new Lead(Firstname = 'Mary'
                              ,Lastname = 'Lead1'
                              ,Company = 'Test Account11'
                              ,Phone = '555-3333'
                              ,Email = 'mary@account11.com'
                              ,Street = '10 Main St'
                              ,City = 'Rochester'
                              ,State = 'NY'
                              ,PostalCode = '10000'
                              ,NSS_Prospect_ID__c = '12345'
                              ,DataFlux_Id__c = null
                              ,LeadGroupId__c = '101');
      insert ld1;
      Id lead1Id = ld1.Id;
      Lead checkLd1 = [Select id, Name, PostalCode, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                         From Lead where Id=:ld1.Id];
      Assert.isTrue(checkLd1.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, checkLd1.DatafluxSyncOperation__c, 'Operation is '+checkLd1.DatafluxSyncOperation__c);
      Assert.isNotNull(checkLd1.DatafluxSyncTime__c);
      Assert.isNull(checkLd1.DatafluxLastSyncTime__c);
      
      //clear variables to make it look like it ran
      checkLd1.DatafluxSyncTime__c=null;
      checkLd1.Dataflux_Force_Delta__c=false;
      checkLd1.DatafluxSyncOperation__c=null;
      update checkLd1;

      // trigger an operation that will do an update
      checkLd1.PostalCode = '14607';
      TriggerMethods.clearVariables();
      System.debug('testLeadDelete before postalcode update');
      update checkLd1;
      checkLd1 = [Select id, Name, PostalCode, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                         From Lead where Id=:ld1.Id];
      Assert.isTrue(checkLd1.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY, checkLd1.DatafluxSyncOperation__c, 'Operation is '+checkLd1.DatafluxSyncOperation__c);
      Assert.isNotNull(checkLd1.DatafluxSyncTime__c);
      Assert.isNull(checkLd1.DatafluxLastSyncTime__c);
       
      //clear variables to make it look like it ran
      checkLd1.DatafluxSyncTime__c=null;
      checkLd1.Dataflux_Force_Delta__c=false;
      checkLd1.DatafluxSyncOperation__c=null;
      update checkLd1;

      TriggerMethods.clearVariables();
      delete checkLd1; 
      
      // a DatafluxSync__c should be created
      DatafluxSync__c sync = [Select Id, ObjectId__c, ObjectAPIName__c, OperationType__c, ReadyToSync__c, ReadyToSyncTime__c
                                From DatafluxSync__c
                               Where ObjectId__c=:lead1Id];
      Assert.isTrue(sync.ReadyToSync__c);
      Assert.isNotNull(sync.ReadyToSyncTime__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_DELETE, sync.OperationType__c);
      Assert.areEqual(ObjectHelper.OBJECT_LEAD, sync.ObjectAPIName__c);
       
      Database.UnDeleteResult udr = Database.undelete(lead1Id);
      checkLd1 = [Select Id, Name, Company, DataFlux_Id__c, Lead_Company__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
               from Lead where Id = :lead1Id];
                
      Assert.isTrue(checkLd1.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY, checkLd1.DatafluxSyncOperation__c, 'Operation is '+checkLd1.DatafluxSyncOperation__c);
      Assert.isNotNull(checkLd1.DatafluxSyncTime__c);
      Assert.isNull(checkLd1.DatafluxLastSyncTime__c);

      Test.stopTest();
        
    } // testLeadDelete
   
   // test insert of Contact
   static testMethod void testContactInsert() {
      Account acct = new Account(Name='Test Account1');
      insert acct;
        
      Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType('Core Contact Record Type', 'Contact');
      Contact con1a = new Contact(AccountId=acct.Id,Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false);
      insert con1a;
      Contact con1b = new Contact(AccountId=acct.Id,Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'sLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false);
      insert con1b;
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, FirstName, LastName
                                                             ,DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                                                         From Contact]);
      Contact check1a = ctctMap.get(con1a.Id);
      Assert.isTrue(check1a.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, check1a.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1a.DatafluxSyncTime__c);
      Assert.isNull(check1a.DatafluxLastSyncTime__c);

      Contact check1b = ctctMap.get(con1b.Id);
      Assert.isTrue(check1b.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, check1b.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1b.DatafluxSyncTime__c);
      Assert.isNull(check1b.DatafluxLastSyncTime__c);
             
      DataFluxDeltaServiceMock mockResp = new DataFluxDeltaServiceMock();
      mockResp.responseToUse = DataFluxDeltaServiceMock.makeCtctResponseXML2();
      Test.setMock(HttpCalloutMock.class, mockResp);
       
      Test.startTest();
      DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch(ObjectHelper.OBJECT_CONTACT);
      Database.executeBatch(dfdb,10);                         
      Test.stopTest();
                
      Web_Service_Log__c[] newWslogs = [select Id, Name, ErrorMsg__c, Notes__c, Successful__c, SendMsg__c from Web_Service_Log__c 
                                         where ServiceName__c = 'DFDeltaSvc' and NamedFunction__c = 'DELTA_JOB_CONTACT' and CreatedDate = TODAY];                                         
      Assert.areEqual(1, newWslogs.size());
      Assert.isFalse(newWslogs[0].SendMsg__c);
      Assert.IsTrue(newWslogs[0].Successful__c);
        
      ctctMap = new Map<Id,Contact>([Select Id, FirstName, LastName, Dataflux_Id__c
                                                             ,DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                                                         From Contact]);
      check1a = ctctMap.get(con1a.Id);
      Assert.areEqual(check1a.Id,check1a.Dataflux_Id__c);
      Assert.isFalse(check1a.Dataflux_Force_Delta__c);
      Assert.isNull(check1a.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNull(check1a.DatafluxSyncTime__c);
      Assert.isNotNull(check1a.DatafluxLastSyncTime__c);

      check1b = ctctMap.get(con1b.Id);
      Assert.areEqual(check1b.Id,check1b.Dataflux_Id__c);
      Assert.isFalse(check1b.Dataflux_Force_Delta__c);
      Assert.isNull(check1b.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNull(check1b.DatafluxSyncTime__c);
      Assert.isNotNull(check1b.DatafluxLastSyncTime__c);        

    } // testContactInsert

   // test ContactAfter, ContactAfterDelete and ContactAfterUndelete triggers
   static testMethod void testContactDelete() {
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account');
      Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType('Core Contact Record Type', 'Contact');
        
      Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Core Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
      insert acct1;
      Contact con1a = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
      insert con1a;
      Contact con1b = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-2323'
                                ,Email = 'sLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
      insert con1b;        
      Id con1aId = con1a.Id;
      Id con1bId = con1b.Id;
       
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, FirstName, LastName
                                                             ,DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                                                         From Contact]);
      Contact check1a = ctctMap.get(con1a.Id);
      Assert.isTrue(check1a.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, check1a.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1a.DatafluxSyncTime__c);
      Assert.isNull(check1a.DatafluxLastSyncTime__c);

      Contact check1b = ctctMap.get(con1b.Id);
      Assert.isTrue(check1b.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, check1b.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1b.DatafluxSyncTime__c);
      Assert.isNull(check1b.DatafluxLastSyncTime__c);

      // clear out the fields to see if they repopulate after undelete
      check1a.Dataflux_Force_Delta__c=false;
      check1a.DatafluxSyncTime__c=null;
      check1a.DatafluxSyncOperation__c=null;
      check1b.Dataflux_Force_Delta__c=false;
      check1b.DatafluxSyncTime__c=null;
      check1b.DatafluxSyncOperation__c=null;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      update new Contact[]{check1a,check1b};
      
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      TriggerMethods.clearVariables();
       
      delete new Contact[]{check1a,check1b};
      Id[] ctctIds = new Id[]{con1aId,con1bId};
      Assert.areEqual(0,[Select count() from Contact where id in :ctctIds]);

      // a DatafluxSync__c should be created
      DatafluxSync__c sync = [Select Id, ObjectId__c, ObjectAPIName__c, OperationType__c, ReadyToSync__c, ReadyToSyncTime__c
                                From DatafluxSync__c
                               Where ObjectId__c=:con1aId];
      Assert.isTrue(sync.ReadyToSync__c);
      Assert.isNotNull(sync.ReadyToSyncTime__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_DELETE, sync.OperationType__c);
      Assert.areEqual(ObjectHelper.OBJECT_CONTACT, sync.ObjectAPIName__c);

      sync = [Select Id, ObjectId__c, ObjectAPIName__c, OperationType__c, ReadyToSync__c, ReadyToSyncTime__c
                                From DatafluxSync__c
                               Where ObjectId__c=:con1bId];
      Assert.isTrue(sync.ReadyToSync__c);
      Assert.isNotNull(sync.ReadyToSyncTime__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_DELETE, sync.OperationType__c);
      Assert.areEqual(ObjectHelper.OBJECT_CONTACT, sync.ObjectAPIName__c);
     
      Database.undelete(new Contact[]{check1a,check1b});
      ctctMap = new Map<Id,Contact>([Select Id, FirstName, LastName
                                                             ,DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                                                         From Contact]);
      check1a = ctctMap.get(con1a.Id);
      Assert.isTrue(check1a.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY, check1a.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1a.DatafluxSyncTime__c);
      Assert.isNull(check1a.DatafluxLastSyncTime__c);

      check1b = ctctMap.get(con1b.Id);
      Assert.isTrue(check1b.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY, check1b.DatafluxSyncOperation__c, 'Operation is '+check1a.DatafluxSyncOperation__c);
      Assert.isNotNull(check1b.DatafluxSyncTime__c);
      Assert.isNull(check1b.DatafluxLastSyncTime__c);
        
      //  merge con1 con1a;
   } // testContactDelete

    // test insert of Account 
    static testMethod void testAccountInsert() {
        
        CreateTestData.createSingleAandTwoCts();
        Account a1 = [select Id, Name, AccountNumber, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                        from Account where name = 'Test Account1'];
        Assert.isTrue(a1.Dataflux_Force_Delta__c);
        Assert.isNull(a1.DatafluxLastSyncTime__c);
        Assert.areEqual(DataFluxDeltaService.ACTION_INSERT, a1.DatafluxSyncOperation__c, 'Operation is '+a1.DatafluxSyncOperation__c);
        Assert.isNotNull(a1.DatafluxSyncTime__c);
        
        Contact ctct1 = [select Id, Name, Dataflux_Id__c from Contact where AccountId = :a1.Id and FirstName = 'First'];
        
        DataFluxDeltaServiceMock mockResp = new DataFluxDeltaServiceMock();
        mockResp.responseToUse = DataFluxDeltaServiceMock.makeAcctResponseXML2();
        Test.setMock(HttpCalloutMock.class, mockResp);

        Test.startTest();
        DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch(ObjectHelper.OBJECT_ACCOUNT);
        Database.executeBatch(dfdb,10);                         
        Test.stopTest();
        
        a1 = [select Id, Name, AccountNumber, Dataflux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                        from Account where Id=:a1.Id];
        Assert.areEqual(a1.Id,a1.Dataflux_Id__c);
        Assert.isFalse(a1.Dataflux_Force_Delta__c);
        Assert.isNotNull(a1.DatafluxLastSyncTime__c);
        Assert.isNull(a1.DatafluxSyncOperation__c, 'Operation is '+a1.DatafluxSyncOperation__c);
        Assert.isNull(a1.DatafluxSyncTime__c);
        Web_Service_Log__c[] newWslogs = [select Id, Name, Successful__c, SendMsg__c, ErrorMsg__c from Web_Service_Log__c 
                                        where CreatedDate = TODAY order by CreatedDate DESC];
        Assert.areEqual(1, newWslogs.size());
        Assert.isFalse(newWslogs[0].SendMsg__c);
        Assert.isTrue(newWslogs[0].Successful__c);
    } // testAccountInsert
    
    // test good insert of Account then delete and undelete
    static testMethod void testAccountDelete() {
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account');
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType('Core Contact Record Type', 'Contact');
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Contact con1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        insert con1;
        // clear these fields before we delete the record
        acct1.Dataflux_Force_Delta__c=false;
        acct1.DatafluxSyncOperation__c=null;
        acct1.DatafluxSyncTime__c=null;
        ZipCheckOwner.SKIP_TRIGGERS=true;
        update acct1;
        TriggerMethods.clearVariables();
        delete acct1;       
        
      Id acctId = acct1.Id;
      // a DatafluxSync__c should be created
      DatafluxSync__c sync = [Select Id, ObjectId__c, ObjectAPIName__c, OperationType__c, ReadyToSync__c, ReadyToSyncTime__c
                                From DatafluxSync__c
                               Where ObjectId__c=:acctId];
      Assert.isTrue(sync.ReadyToSync__c);
      Assert.isNotNull(sync.ReadyToSyncTime__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_DELETE, sync.OperationType__c);
      Assert.areEqual(ObjectHelper.OBJECT_ACCOUNT, sync.ObjectAPIName__c);

      ZipCheckOwner.SKIP_TRIGGERS=false;
      TriggerMethods.clearVariables();

      Database.undelete(acct1);
        
      Account chkAcct = [Select Id, Name, DataFlux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
               from Account where Id = :acctId];
                
      Assert.isTrue(chkAcct.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY, chkAcct.DatafluxSyncOperation__c, 'Operation is '+chkAcct.DatafluxSyncOperation__c);
      Assert.isNotNull(chkAcct.DatafluxSyncTime__c);
      Assert.isNull(chkAcct.DatafluxLastSyncTime__c);
        
   } // testAccountDelete
   
   static testMethod void testAcctCtctFldChanges() {
      CreateTestData.createSingleAandTwoCtsNoTrigs();
      Account acct = CreateTestData.acct1;
      Account chkAcct = [Select Id, Name, DataFlux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                             from Account where Id=:acct.Id];
      Assert.isFalse(chkAcct.Dataflux_Force_Delta__c);
      Assert.isNull(chkAcct.DatafluxSyncOperation__c, 'Operation is '+chkAcct.DatafluxSyncOperation__c);
      Assert.isNull(chkAcct.DatafluxSyncTime__c);
      Assert.isNull(chkAcct.DatafluxLastSyncTime__c);
      Contact ctct1 = acct.Contacts[0];
      Contact chkCtct1 =  [Select Id, Name, DataFlux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                             from Contact where Id=:ctct1.Id];
      Assert.isFalse(chkCtct1.Dataflux_Force_Delta__c);
      Assert.isNull(chkCtct1.DatafluxSyncOperation__c, 'Operation is '+chkAcct.DatafluxSyncOperation__c);
      Assert.isNull(chkCtct1.DatafluxSyncTime__c);
      Assert.isNull(chkCtct1.DatafluxLastSyncTime__c);
       
      acct.ShippingPostalCode = '12345';
      acct.BillingPostalCode = '12345';
      ZipCheckOwner.SKIP_TRIGGERS=false;
      update acct;
      chkAcct = [Select Id, Name, DataFlux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                             from Account where Id=:acct.Id];
      Assert.isTrue(chkAcct.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY,chkAcct.DatafluxSyncOperation__c, 'Operation is '+chkAcct.DatafluxSyncOperation__c);
      Assert.isNotNull(chkAcct.DatafluxSyncTime__c);
      Assert.isNull(chkAcct.DatafluxLastSyncTime__c);
       
      ctct1.MailingPostalCode = '12345';
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=false;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=false;
      update ctct1;
      chkCtct1 =  [Select Id, Name, DataFlux_Id__c, DatafluxLastSyncTime__c, DatafluxSyncOperation__c, Dataflux_Force_Delta__c, DatafluxSyncTime__c
                             from Contact where Id=:ctct1.Id];
      Assert.isTrue(chkCtct1.Dataflux_Force_Delta__c);
      Assert.areEqual(DataFluxDeltaService.ACTION_MODIFY,chkCtct1.DatafluxSyncOperation__c, 'Operation is '+chkAcct.DatafluxSyncOperation__c);
      Assert.isNotNull(chkCtct1.DatafluxSyncTime__c);
      Assert.isNull(chkCtct1.DatafluxLastSyncTime__c);
      
   } // testFldChanges

   static testMethod void testScheduler() {
      TestHelper.testScheduler('testDataFluxDeltaBatch', new DataFluxDeltaBatch());
   } // testScheduler

   // can be used to populate Custom Setting when testing (or after sandbox refresh)
   public static WebServiceSettings__c populateEndpoint() {
        //DataFluxDeltaService.ALLOW_TEST_TO_RUN = true;
        WebServiceSettings__c wssInternal = new WebServiceSettings__c (
            Name = DataFluxDeltaService.WEBSERVICE_SETTING
            ,certificate__c = label.Certificate_Name
         ,endpoint__c = 'http://dfapdvh1.paychex.com:21036'
         //JC removed   ,endpoint__c='https://ws.n1.paychex.com/soap/corporate/sfdc-dev/1_0/LeadManagementActivityOrchestrationServiceFS'
            ,IsActive__c=true
            ,LogAllCalls__c = true);            
        upsert wssInternal;
        return wssInternal;
    } // populateEndpoint
    
   static testMethod void testEmail() {
      Apex_Batch_Control__c abc = [Select Id, Name, EmailTest__c from Apex_Batch_Control__c where Name=:DataFluxDeltaBatch.CLASSNAME];
      abc.EmailTest__c = 'john@smith.com';
      update abc;
       
      DataFluxDeltaBatch dfdb = new DataFluxDeltaBatch();
       
      dfdb.checkSettingForEmail();
      abc = [Select Id, Name, EmailTest__c from Apex_Batch_Control__c where Name=:DataFluxDeltaBatch.CLASSNAME];
      System.assertEquals(null,abc.EmailTest__c);
   } // testEmail

} // class DataFluxDeltaServiceTest