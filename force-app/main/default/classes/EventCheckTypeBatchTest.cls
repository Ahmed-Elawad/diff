/*
 * Test class for one time batch job - EventCheckTypeBatch
 *
 * History
 * -------
 * 04/03/2018 Cindy Freeman   Created
 * 06/05/2018 Jacob Hinds     Commenting out, no longer needed
*/
@isTest
public class EventCheckTypeBatchTest {
 /*
    @TestSetup
    private static void initData() {
        // create A, C, Opty
        CreateTestData.createTestAandC();
        Account acct1 = [Select Id from Account where Name = 'Test Account1'];
        Contact ctct1 = [Select Id, Name from Contact where FirstName = 'First' and LastName = 'Last1'];        
        Schema.RecordTypeInfo coreOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE,ObjectHelper.OBJECT_OPPTY);
        Opportunity opty1 = new Opportunity(Name='Test Core Opporty', RecordTypeId=coreOpptyRt.getRecordTypeId()
                                         ,AccountId=acct1.Id
                                         ,StageName='Pending'
                                         ,CloseDate=Date.today()
                                         ,OwnerId=UserInfo.getUserId());
        insert opty1;                                                 
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id, OpportunityId=opty1.Id, IsPrimary=true);
        insert ocr1;
        

        // create events
        Event evnt1 = new Event(Type='Opty1 Event',WhatId=opty1.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,DurationInMinutes=60);
        Event evnt2 = new Event(Type='Explore Paychex 2',WhatId=opty1.Id
                            ,Subject='Other'
                            ,ActivityDate=Date.today()
                            ,ActivityDateTime=DateTime.now()
                            ,DurationInMinutes=60);
        Event[] evnts = new Event[]{evnt1,evnt2}; 
        insert evnts;
        
    } // initData
    
    static testMethod void myUnitTest() {
        
        Opportunity opty1 = [Select Id,Name, Number_Of_Events__c from Opportunity where Name = 'Test Core Opporty'];
        System.assertEquals(2, opty1.Number_of_Events__c);
        
        opty1.Number_of_Events__c = 0;
        update opty1;
        System.assertEquals(0, opty1.Number_of_Events__c);
        
        // run batch job        
        EventCheckTypeBatch evntcktype = new EventCheckTypeBatch();               
        Test.startTest();
        Database.executeBatch(evntcktype);
        Test.stopTest();
        
        opty1 = [Select Id,Name, Number_Of_Events__c from Opportunity where Name = 'Test Core Opporty'];
        System.assertEquals(2, opty1.Number_of_Events__c);       
              
    } // myUnitTest
   */
}