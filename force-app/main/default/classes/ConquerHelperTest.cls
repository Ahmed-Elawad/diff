/* 
   Methods for working with Conquer

   
  History
  -------
  10/31/2023 Dan Carmen        Removed direct query to RecordType object
  01/03/2024 Lalan Kumar       APR0161244 : Added where clause as DS_Packages__Excluded_Cadence__c = false for query ds_packages__cadence__c

*/ 
@isTest
public class ConquerHelperTest {

    // inserts test data in a way that covers 90% of ConquerHelper and hits the enqueueJob block (as of 12.16.2021)
    @testSetup
    public static void createData() {
        // Create Trigger Setup Class record for ConquerHelper
        TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{ConquerHelper.CLASSNAME});
        TriggerMethodsTest.saveSetupClasses();

        User u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' limit 1];
        // Create Account
        Account a = new Account(
            Name ='Test Account',
            OwnerId = u.Id
        );
        ZipCheckOwner.SKIP_TRIGGERS=true;
        insert a;

        // get MMS Opportunity record type Id
        Map <String,Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id rtId = rtMap.get(Label.MMS_Opportunity_Record_Type).getRecordTypeId();

        Integer recordCount = 200; // integer to control how many records are created

        // Create test Opps
        List<Opportunity> opps = new List<Opportunity>();
        for(integer i = 0; i < recordCount; i++){
            Opportunity o = new Opportunity(
                name = 'Test Opp '+i,
                AccountId = a.Id,
                recordTypeId = rtId,
                StageName = 'test',
                CloseDate = System.today()+30,
                OwnerId = u.Id
            );
            opps.add(o);
        }
        insert opps;

        // Create test Contacts
        List<Contact> conts = new List<Contact>();
        for(integer i=0; i < recordCount; i++) {
            Contact c = new Contact(
                LastName = 'Test Contact ' + i,
                AccountId = a.Id,
                Phone = '7372040212',
                email = 'test@tester' + i + '.com',
                OwnerId = u.Id
            );
            conts.add(c);
        }
        insert conts;

        // Create Contact Roles
        List<OpportunityContactRole> ocrs = new List<OpportunityContactRole>();
        for(integer i=0; i < recordCount; i++) {
            OpportunityContactRole ocr = new OpportunityContactRole(
                IsPrimary = true,
                ContactId = conts[i].Id,
                OpportunityId = opps[i].Id
            );
            ocrs.add(ocr);
        }
        insert ocrs;

        // Create sample Cadences
        DS_Packages.CadenceAPIEndpoint.createSampleData();
    }
    
    /**
     * directly tests the global method exposed in the Conquer managed package;
     * this is the method that ConquerHelper delegates to if identifies Opps that meet the appropriate criteria
     */
    @isTest
    public static void testConquerMethod() {
        // Get cadence id
        // APR0161244 : Added where clause as DS_Packages__Excluded_Cadence__c = false
        Id cadId = [select id from ds_packages__cadence__c WHERE DS_Packages__Excluded_Cadence__c = false  limit 1].Id;
        // Start a cadence for all test contacts
        List<DS_Packages.StartCadence.Request> reqs = new List<DS_Packages.StartCadence.Request>();
        for(Contact c: [select id, ownerid from contact]) {
            reqs.add(new DS_Packages.StartCadence.Request(c.Id, cadId, c.OwnerId));
        }
        DS_Packages.StartCadence.StartCadence(reqs);

        // query Ids for Opps that are related to the Contacts who were just enrolled in a Cadence
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([select id from opportunity]);

        test.startTest();
        // run the service synchronously
        if (!oppMap.isEmpty()) {
            new DS_Packages.AssociateContactDataToOpp(
                oppMap.keySet(),
                new DS_Packages.AssociateContactDataToOpp.Configuration()
            ).run();
        }
        test.stopTest();

        // assert that the members are now related to an opp
        for(ds_packages__cadence_member__c mem: [select id, ds_packages__status__c, ds_packages__opportunity__c from ds_packages__cadence_member__c]) {
            Assert.isNotNull(mem.ds_packages__opportunity__c);
        }
    } // testConquerMethod
    
} //  class ConquerHelperTest