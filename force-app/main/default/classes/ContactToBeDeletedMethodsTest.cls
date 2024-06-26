/* 
 * Test for ContactsToBeDeletedMethods
 * 
 * History
 * -------
   01/29/2018 Cindy Freeman     Created
   01/29/2018 Matt Fritschi     Added a check to see if To_Be_Deleted checkbox will set Sales_Contact to false.
 *
 */
@isTest
public class ContactToBeDeletedMethodsTest {

    static testMethod void testToBeDeleted() {
        TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
        TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'ContactAfter', false, true, new String[]{'ContactToBeDeletedMethods'}, setupClasses);
        insert setupClasses;
        
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = false
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = false
                                ,AnnualRevenue = 25);
        insert acct;
        Contact ctct = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct.Id
                                );
        insert ctct;
                
        ctct.Reason_for_Delete__c = 'Unknown';
        ctct.To_Be_Deleted__c = true;
        update ctct;
        
        Set<Id> ctctSet = new Set<Id>();
        ctctSet.add(ctct.Id);
        //ContactToBeDeletedMethods.checkToBeDeleted(ctctSet);
        Contact newCtct = [Select Id, To_Be_Deleted__c, To_Be_Deleted_Date__c, Purge_Exception__c, CreatedDate, 
                           Sales_Contact__c, OwnerId from Contact where Id = :ctct.Id];
        
        System.assertEquals(true, newCtct.To_Be_Deleted__c);
        System.assertNotEquals(null, newCtct.To_Be_Deleted_Date__c);
        System.assertEquals(null, newCtct.Purge_Exception__c);
        //System.assertEquals(False, newCtct.Sales_Contact__c);
        //User[] sfdcId = [SELECT Id, Name From User Where Name = 'SFDC Data'];
        //System.assertEquals(sfdcId[0].Id, newCtct.OwnerId);
        
        // create opty
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
        Opportunity oppty = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct.Id
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId());
        insert oppty;                                                 
        OpportunityContactRole  ocr1 = new OpportunityContactRole(ContactId=ctct.Id, OpportunityId=oppty.Id, IsPrimary=true);
        insert ocr1;
        // create case
        Schema.RecordTypeInfo hrsRT = RecordTypeHelper.getRecordType('Service Support 401k/S125 Case', 'Case');
        Case case1 = new Case (recordtypeId = hrsRT.getRecordTypeId()
                               ,status = 'New'
                               ,origin = 'Email'
                               //,CreatedDate = System.Now();       //dateTime.valueOf('2015-10-01 00:00:00') 
                               ,Product__c = '401K'
                               ,contactId = ctct.Id);
        insert case1;
        //create task and event
        Task tsk = new Task(Subject='ToBeDeleted Test Task',ActivityDate=System.today(),Status='Completed',WhoId=ctct.Id);
        insert tsk;
        Event ev = new Event(Subject='ToBeDeleted Test Event',ActivityDateTime=System.now(),ActivityDate=System.Today(),DurationInMinutes=60,WhoId=ctct.Id);
        insert ev;
        
        // clear TBD fields
        ctct.To_Be_Deleted__c = false;
        ctct.To_Be_Deleted_Date__c = null;
        ctct.DoNotCall = true;
        update ctct;
        
        ContactToBeDeletedMethods.SKIP_FUTURE = false;
        Test.startTest();
        // check TBD to fire trigger
        ctct.Reason_for_Delete__c = 'Unknown';
        ctct.To_Be_Deleted__c = true;
        update ctct;
        Test.stopTest();
                
        //ContactToBeDeletedMethods.checkToBeDeleted(ctctSet);
        newCtct = [Select Id, To_Be_Deleted__c, To_Be_Deleted_Date__c, Purge_Exception__c, CreatedDate 
                           from Contact where Id = :ctct.Id];
        System.assertEquals(true, newCtct.Purge_Exception__c.contains('has Opportunity'));
        System.assertEquals(true, newCtct.Purge_Exception__c.contains('has DNC'));
        System.assertEquals(true, newCtct.Purge_Exception__c.contains('has Case'));
        System.assertEquals(true, newCtct.Purge_Exception__c.contains('has Task'));
        System.assertEquals(true, newCtct.Purge_Exception__c.contains('has Event'));
       
    } // testToBeDeleted
    
    static testMethod void testMisc() {
       ContactToBeDeletedMethods ctbdm = new ContactToBeDeletedMethods();
       ctbdm.checkAllBeforeTrigger((SObject[])null, (Map<Id,Object>)null);
       ctbdm.checkBeforeTrigger((SObject)null, (SObject)null);
       ctbdm.processBeforeTriggerActions();
    } // testMisc
    
} // class ContactToBeDeletedMethodsTest