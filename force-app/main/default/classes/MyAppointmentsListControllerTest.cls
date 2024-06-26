/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Test class for My Appointments List page controller
*/
@isTest
private class MyAppointmentsListControllerTest 
{
	/*
		Verifies that appointments are returned for Today grouping
	*/
    static testMethod void verifyTodaysAppoinments() 
    {
    	
    	MyAppointmentsListController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsList;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'today1');
        	controller = new MyAppointmentsListController();
        	
        	System.assertEquals(1, controller.getAppointmentCount(), controller.getAppointmentGroups().size());
        	System.assertEquals('Today', controller.appointmentLabel);
       
        Test.stopTest();
       
    }// end of verifyTodaysAppoinments
    
    /*
		Verifies that appointments are returned for This Week grouping
	*/
    static testMethod void verifyThisWeeksAppoinments() 
    {
    	
    	MyAppointmentsListController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsList;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Week');
        	controller = new MyAppointmentsListController();
        	
        	System.assertEquals(controller.getAppointmentCount(), controller.getAppointmentGroups().size());
        	System.assertEquals('This Week', controller.appointmentLabel);
       
        Test.stopTest();
       
    }// end of verifyThisWeeksAppoinments
    
    /*
		Verifies that appointments are returned for Last Week grouping
	*/
    static testMethod void verifyLastWeeksAppoinments() 
    {
    	
    	MyAppointmentsListController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsList;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Last');
        	controller = new MyAppointmentsListController();
        	
        	System.assertEquals(controller.getAppointmentCount(), controller.getAppointmentGroups().size());
        	System.assertEquals('Last Week', controller.appointmentLabel);
       
        Test.stopTest();
       
    }// end of verifyLastWeeksAppoinments
    
    /*
		Verifies that appointments are returned for Future grouping
	*/
    static testMethod void verifyFutureAppoinments() 
    {
    	
    	MyAppointmentsListController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsList;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Future');
        	controller = new MyAppointmentsListController();
        	
        	System.assertEquals(controller.getAppointmentCount(), controller.getAppointmentGroups().size());
        	System.assertEquals('Future', controller.appointmentLabel);
       
        Test.stopTest();
       
    }// end of verifyFutureAppoinments
    
    /*
		Verifies that appointments are returned for Past grouping
	*/
    static testMethod void verifyPastAppoinments() 
    {
    	
    	MyAppointmentsListController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	PageReference pageRef = Page.MyAppointmentsList;
			Test.setCurrentPage(pageRef);        
			pageRef.getParameters().put('type', 'Past');
        	controller = new MyAppointmentsListController();
        	
        	System.assertEquals(controller.getAppointmentCount(), controller.getAppointmentGroups().size());
        	System.assertEquals('Past', controller.appointmentLabel);
       
        Test.stopTest();
       
    }// end of verifyPastAppoinments
}// end of Class