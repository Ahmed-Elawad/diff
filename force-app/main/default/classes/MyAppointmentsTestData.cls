/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Creates test data for test classes
*/
@isTest
public class MyAppointmentsTestData 
{
	/*
		Creates test account, contact, events and opportunity
	*/
    public static void CreateTestData() 
    {
    	Account account = new Account(Name = 'MA Test Account');
    	Contact contact = new Contact(FirstName = 'Contact', LastName='Test');
        Opportunity opp = new Opportunity(Name = 'MA Test Opp', CloseDate = Date.Today().addDays(25), StageName='Qualified', RecordTypeId = MyAppointmentsUtility.mmsOpportunityRecordType);
        List<Event> events = new List<Event>();
        
        insert account;
        contact.AccountId = account.Id;
        insert contact;
        opp.AccountId = account.Id;
        insert opp;
        
        Id rcdTypeId;
        Schema.RecordTypeInfo corert = RecordTypeHelper.getRecordType('MMS Event Record Type', 'Event');
        rcdTypeId = corert.getRecordTypeId();
            
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 1', StartDateTime = Datetime.now().addDays(-15), 
        						EndDateTime = Datetime.now().addDays(-15).addHours(1),	WhatId = opp.Id, WhoId = contact.Id)); //15 days ago - Past
        						
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 2', StartDateTime = Datetime.now().addDays(-3), 
        						EndDateTime = Datetime.now().addDays(-3).addHours(1), WhatId = opp.Id, WhoId = contact.Id)); //3 days ago - Past and/or last week
        						
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 3', StartDateTime = Datetime.now().addDays(-7), 
    							EndDateTime = Datetime.now().addDays(-7).addHours(1), WhatId = opp.Id, WhoId = contact.Id)); //7 days ago - Past and/or last week
        						
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 4', StartDateTime = Datetime.now(),  
        						EndDateTime = Datetime.now().addHours(1), WhatId = opp.Id, WhoId = contact.Id)); //Today and This Week
        						
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 5', StartDateTime = Datetime.now().addDays(1), 
        						EndDateTime = Datetime.now().addDays(1).addHours(1), WhatId = opp.Id, WhoId = contact.Id)); //This Week and/or Future
        						
        events.add(new Event(RecordTypeId = rcdTypeId, Subject = 'MA Test Event 6', StartDateTime = Datetime.now().addDays(15), 
        						EndDateTime = Datetime.now().addDays(15).addHours(1), WhatId = opp.Id, WhoId = contact.Id)); //15 from now - Future
        						
        insert events;
    } // end of CreateTestData
}// end of class