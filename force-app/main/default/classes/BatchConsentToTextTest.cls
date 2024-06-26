/* 
 * A batch job for checking Batch Consent to text reset 
 *
 * History
 * -------
 * 12/26/2017 Cindy Freeman   Created
 * 10/23/2018 Jacob Hinds     Adding sosl fixed search results so dnc doesn't remove consent to text
   10/15/2019 Dan Carmen      Update to use TriggerMethods.clearVariables
   04/16/2020 Dan Carmen      Modify to use CreateTestData
   05/02/2023 Dan Carmen      Comment out DNCHelper.OBJECTS_RAN_SET
 
 */ 
@isTest
private class BatchConsentToTextTest {

   @testSetup
   public static void setupData() {
      DNCQueueableTest.setupTriggerClasses();
   }

    static testMethod void myUnitTest() {
        //Test.startTest();
        populateConsent();
                                                
        List<Lead> leadList = [Select Id, Consent_to_Text__c from Lead where Consent_to_Text__c = true];
        System.assertEquals(2,leadList.size());
        List<Contact> ctctList = [Select Id, Consent_to_Text__c from Contact where Consent_to_Text__c = true];
        System.assertEquals(2,ctctList.size());
System.debug('**CMF ** inserted leads and contacts');

      //DNCHelper.OBJECTS_RAN_SET.clear();
      //DNCHelper.ALREADY_RAN_SET.clear();
        TriggerMethods.clearVariables();
        // run batch job
        BatchConsentToText jobConsent = new BatchConsentToText();        
        Test.startTest();
        TriggerMethods.clearVariables();
        Database.executeBatch(jobConsent);
        
        Test.stopTest();
        
        leadList = [Select Id, Consent_to_text__c, Consent_to_Text_Date__c, Consent_to_Text_Reason__c from Lead
                                //where Id = :ld1.Id];
                                where  Consent_to_Text_Reason__c = 'Expired auto reset'];
        System.assertEquals(1, leadList.size());
        
        ctctList = [Select Id, Consent_to_text__c, Consent_to_Text_Date__c, Consent_to_Text_Reason__c from Contact
                                //where Id = :ctct1.Id];
                                where Consent_to_Text_Reason__c = 'Expired auto reset'];
        System.assertEquals(1, ctctList.size());
        
        List<Reference_Do_Not_Contact__c> refDNCList = [Select Id, Consent_to_Text_reason__c from Reference_Do_Not_Contact__c                                                   
                                                    where  Consent_to_Text_Reason__c = 'Expired auto reset'];
        //System.assertEquals(2,refDNCList.size());                                                                                                       
        
       
    } // myUnitTest 
    
    /** populate setting used to determine which batch job to check
    */
    
   public static void populateConsent() { 
        integer limitDays = Integer.valueOf(Label.ConsentToTextTimeframe)+30;
        Date cutoffDate = Date.today().addDays(-limitDays);
System.debug('**CMF ** populateConsent, cutoffDate='+cutoffDate);       
        Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);
        Lead ld1 = new Lead(Firstname = 'First',Lastname = 'Last Lead1',Company = 'Test Lead Company1',mobilePhone='555-1212'
                                ,recordtypeId = leadCorert.getRecordTypeId(),DataFlux_Id__c = null,LeadGroupId__c = null
                                ,Consent_to_Text__c = true,Consent_to_Text_Date__c=cutoffDate,Consent_to_Text_Reason__c='Lead Loader change');
        insert ld1;
        Lead ld2 = new Lead(Firstname = 'Second',Lastname = 'Last Lead2',Company = 'Test Lead Company2',mobilePhone='555-3434'
                                ,recordtypeId = leadCorert.getRecordTypeId(),DataFlux_Id__c = null,LeadGroupId__c = null
                                ,Consent_to_Text__c = true,Consent_to_Text_Date__c=Date.today(),Consent_to_Text_Reason__c='Lead Loader change');
        insert ld2;

        Schema.RecordTypeInfo acctRt = CreateTestData.getDefaultProspectAcctRT();
        Schema.RecordTypeInfo ctctRt = CreateTestData.getDefaultSalesContactRT();
        
        Account acct1 = new Account (name = 'Test Account1',recordtypeId = acctRt.getRecordTypeId()
                                ,type = 'MMS Client',BillingPostalCode = '10000',AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true,Phone = '555-1212',Email_Opt_Out__c = true,AnnualRevenue = 25);
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First',Lastname = 'Last1',recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-7649',mobilePhone='555-7896',Email = 'fLast1@abc.com'
                                ,DoNotCall = false,HasOptedOutOfEmail = false,AccountId=acct1.Id
                                ,Consent_to_Text__c = true,Consent_to_Text_Date__c=cutoffDate,Consent_to_Text_Reason__c='User change');
        insert ctct1;
        Contact ctct2 = new Contact(Firstname = 'Second',Lastname = 'Last2',recordtypeId = ctctRt.getRecordTypeId()
                                ,Phone = '585-555-9798',mobilePhone='555-9636',Email = 'fLast2@abc.com'
                                ,DoNotCall = false,HasOptedOutOfEmail = false,AccountId=acct1.Id
                                ,Consent_to_Text__c = true,Consent_to_Text_Date__c=Date.today(),Consent_to_Text_Reason__c='User change');
        insert ctct2;
        
        TriggerMethods.clearVariables();
        //update dates that process builder put it
        Reference_Do_Not_Contact__c leadRefDNC = [Select Id, Consent_to_Text_Date__c from Reference_Do_Not_Contact__c where Lead__c = :ld1.Id];
        leadRefDNC.Consent_to_Text_Date__c = cutoffDate;
        update leadRefDNC;
        ld1.Consent_to_Text_Date__c = cutoffDate;
        update ld1;
        
        Reference_Do_Not_Contact__c ctctRefDNC = [Select Id, Consent_to_Text_Date__c from Reference_Do_Not_Contact__c where Contact__c = :ctct1.Id];
        ctctRefDNC.Consent_to_Text_Date__c = cutoffDate;
        update ctctRefDNC;
        ctct1.Consent_to_Text_Date__c = cutoffDate;
        update ctct1;
        
        Id[]fixedSearchResults = new Id[]{ld1.Id,ld2.Id,ctct1.Id,ctct2.Id};
        Test.setFixedSearchResults(fixedSearchResults);
                
   } // populateConsent
                                                      
             
} // class BatchConsentToTextTest