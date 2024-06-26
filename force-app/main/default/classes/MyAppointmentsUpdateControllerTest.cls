/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Test class for My Appointments Update page controller

 * History
 * -------
   01/17/2019  Dan Carmen     Increment version number

*/

@isTest
private class MyAppointmentsUpdateControllerTest {
   
	// Verifies event and opp update
    static testMethod void verifyEventAndOppUpdate() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id), 
        					string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()), 
        					appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100');   	
       
        Test.stopTest();
        System.assertEquals('',result.message);
        System.assert(result.success);
        opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        System.assert(opp.CloseDate != controller.opp.CloseDate);
        appointment = [SELECT Id, StartDateTime, EndDateTime FROM Event WHERE ID =: appointment.Id ];
        System.assert(appointment.StartDateTime != controller.appointment.StartDateTime);
        System.assert(appointment.EndDateTime != controller.appointment.EndDateTime);
       
    }// end of verifyEventAndOppUpdate
    
    // Verifies event and opp update
    static testMethod void verifyErrorOnInvalidEmployeesPerPayrollNumber() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id), 
        					string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()), 
        					appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100-123xzs');   	
       
        Test.stopTest();
        System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidEmployeesPerPayrollNumber

    //Verifies that error is returned on invalid event (ActivityDateTime and StartDateTime are different)
    static testMethod void verifyErrorOnInvalidEvent() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id, ActivityDateTime = Datetime.now().addDays(-10)), 
							string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()),
        					appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100');   	
       
        Test.stopTest();
       	System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidEvent
    
     // Verifies that error is returned on invalid opportunity close date
    static testMethod void verifyErrorOnInvalidCloseDate() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id), 'XYZ', 
        		appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100');   	
       
        Test.stopTest();
        System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidCloseDate
    
     // Verifies that error is returned on invalid opportunity name
    static testMethod void verifyErrorOnInvalidName() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id, Name=''), new Event(Id = appointment.Id), 
        					string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()), 
        					appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100');   	
       
        Test.stopTest();
        System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidName
    
    // Verifies that error is returned on invalid event start date
    static testMethod void verifyErrorOnInvalidStartDate() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id), 
        					string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()),
        					appointment.StartDateTime.addHours(1).format('yyyy-MM-ddH:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), '100');   	
       
        Test.stopTest();
        System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidStartDate
    
    // Verifies that error is returned on invalid event end date
    static testMethod void verifyErrorOnInvalidEndDate() 
    {    	
    	MyAppointmentsUpdateController controller = null;
        MyAppointmentsTestData.CreateTestData();
        Event appointment = MyAppointmentsUtility.getAppointments('Today')[0];
        Opportunity opp = [SELECT Id, CloseDate From Opportunity WHERE ID =: appointment.WhatId];
        MyAppointmentsUpdateController.ActionResult result = null;
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsUpdate;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Today');
			pageRef.getParameters().put('Id', appointment.Id);			
			
        	controller = new MyAppointmentsUpdateController();
        	
        	System.assertEquals(appointment.Id, controller.appointment.Id);
        	System.assertEquals(appointment.WhatId, controller.opp.Id);
        	
        	result = MyAppointmentsUpdateController.updateOppAndEventWithDates(new Opportunity(Id = opp.Id), new Event(Id = appointment.Id), 
								string.valueOf(opp.closeDate.addDays(1).year()) + '-' + string.valueOf(opp.closeDate.addDays(1).month()) + '-' + string.valueOf(opp.closeDate.addDays(1).day()), 
        						appointment.StartDateTime.addHours(1).format('yyyy-MM-dd\'T\'H:mm'), appointment.EndDateTime.addHours(1).format('yyyy-MM-ddH:mm'), '100');   	
       
        Test.stopTest();
        System.assertNotEquals('',result.message);
        System.assertEquals(false, result.success);
       
    }// end of verifyErrorOnInvalidEndDate
    
}// end of Class