/**
 * This class contains unit tests for validating the behavior of EventCloseCase.Trigger
 * JSH Commenting out 11/30/2017 No longer used
 */
@isTest
private class EventCloseCaseTest {
	/*
    static testMethod void testDelete() {
        Account a = new Account(Name='testAcc',RecordTypeId = RecordTypeHelper.getRecordType(Label.RT_Core_Account,'Account').getRecordTypeId());
        insert a;
        
        Contact co = new Contact(FirstName = 'test',LastName = 'contact',AccountId=a.Id);
        insert co; 
        
        Case c = new Case();
        c.RecordTypeId = RecordTypeHelper.getRecordType('Service Support ESR Case','Case').getRecordTypeId();
        //c.Product__c = 'ESR';
        //c.ESR_Team__c = 'Inbound Service';
        //c.Origin = 'Email';
        //c.ESRService__c = 'Data Update Request';
        //c.Disposition_1__c = 'Client';
        //c.Action__c = 'Transferred to Outbound Service';
        
        //c.Client_Assigned_Date__c = 
        insert c;
        
        User ESRUser = [Select id, Name from User where isActive = True and sales_org__c = 'COE' limit 1];
   		ESRUser.FirstName = 'ESR';
   		ESRUser.LastName = 'Calendar';
   		update ESRUser;
        ESREventCheck.setupESRCalendarSetting();
        
        date eventDate = system.Today().addDays(7);
        time eventTime = time.newInstance(8, 00, 0, 00);
        dateTime eventStartDateTime = dateTime.newInstance(eventDate,eventTime);
        Event e = new Event(OwnerId = ESRUser.Id,
        					RecordTypeId=RecordTypeHelper.getRecordType(Label.RT_ESR_Event,'Event').getRecordTypeId(),
        					WhatId = c.Id,startDateTime=eventStartDateTime, 
                            endDateTime=eventStartDateTime.addMinutes(30),
                            DurationInMinutes = 30);
        insert e;
        
        Test.startTest();
        Event newE = [SELECT Id FROM Event WHERE Id = :e.Id LIMIT 1];
        delete e;
        Case newC = [SELECT Id,Status FROM Case WHERE Id = :c.Id LIMIT 1];
        system.assertEquals('Deleted/Rescheduled',newC.Status);
        Test.stopTest();
    }*/
}