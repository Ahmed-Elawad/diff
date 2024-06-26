/** Test methods for EventCreateObject Class
 * 
 * History
 * -------
 * 12/17/2018 Michael Karcz         Created
   03/28/2019 Dan Carmen            Modify to make sure only creating the Sales_Engineer_Tracker__c with the correct record

 */
@isTest
private class EventCreateObjectTest {
    
    static void testMisc() {
        // for full test coverage
        EventCreateObject eco = new EventCreateObject();
        eco.triggerCheckRec(null, null, null, null);
        eco.triggerCheckActions(null, null);
    } // testMisc

    static testMethod void testEventCreateObject() {
        
        // creating the custom settings
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'EventCheckType', true, false, new String[]{'EventCreateObject'}, setupClasses);
        insert setupClasses;
        
        // Create an account and a contact and insert them
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        Account[] accts = new Account[]{acct1};
        insert accts;
        
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
                                
        Contact[] ctcts = new Contact[]{ctct1};
        insert ctcts;
        
        Schema.RecordTypeInfo mmsRt = RecordTypeHelper.getRecordType(Label.MMS_Event_Record_Type, 'Event');
        
        // CreateTestData.createTestAandC();
        Account a = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        CreateTestData.createTestCoreOptys(a.Id, c.Id);
        
        Opportunity op = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        User user = [SELECT Id, Name, ProfileId FROM User WHERE Profile.Name = 'Sales Engineer' AND User.IsActive = true LIMIT 1];
        
        DateTime dt = System.now();
        
        // Create new event and add it to a list of events to pass to EventCreateObject
        List<Event> eventList = new List<Event>();
        Event testEvent = new Event(
        RecordTypeId = mmsRt.getRecordTypeId(),
        WhatId = op.Id,
        StartDateTime = dt,
        EndDateTime = dt.addDays(1),
        Appointment_Type__c = 'Demo',
        CreatedById = user.Id
        );
        
        eventList.add(testEvent);
        insert eventList;
        
        Test.startTest();
        
        EventCreateObject ecd = new EventCreateObject();
        ecd.triggerCheckAllFirst(eventList, null, false, true);
        testMisc();
        
        Test.stopTest();
    }
}