@isTest
private class ExportEventAuraServiceTest {
	
	@isTest static void getEventFieldsTest_giveRecordId_getEventInfo() {
		Account expectedAccount = new Account(Name = 'testAccountA', AccountNumber = '8-00081234', NumberOfEmployees = 60);
        insert expectedAccount;

        Opportunity testOpportunity1 = new Opportunity(Name = 'test opportunity', StageName = 'Qualified', AccountId = expectedAccount.Id, CloseDate = System.Today());
        insert testOpportunity1;

        List<Event> testEvents = new List<Event>();
        testEvents.add(new Event(
        		Subject = 'Subject',
                Type = 'Presentation - Initial Test',
                ActivityDate = System.Today(),
                ActivityDateTime = DateTime.now(),
                DurationInMinutes = 60,
                WhatId = testOpportunity1.Id
        ));

        insert testEvents;

        Test.startTest();
        Event e = ExportEventAuraService.getEventFields(testEvents.get(0).Id);
        Test.stopTest();

        System.assertEquals(e != null, true);
        System.assertEquals(e.Subject, 'Subject');

	}
	
}