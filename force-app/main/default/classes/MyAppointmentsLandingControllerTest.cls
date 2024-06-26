/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Test class for My Appointments Landing page controller
*/
@isTest
private class MyAppointmentsLandingControllerTest 
{
	/*
		Verifies that appointment counts are not zero
	*/
    static testMethod void verifyAppointmentsCounts() 
    {
    	MyAppointmentsLandingController controller = null;
        MyAppointmentsTestData.CreateTestData();
        
        Test.startTest();
        	controller = new MyAppointmentsLandingController();
        	
        	System.assertEquals(1, controller.getTodayAppointmentCount());
        	System.assert(controller.getWeekAppointmentCount() > 0);
        	System.assert(controller.getFutureAppointmentCount() > 0);
        	System.assert(controller.getPastAppointmentCount() > 0);
        	System.assert(controller.getLastWeekAppointmentCount() > 0); 
        
        Test.stopTest();
    }// end of verifyAppointmentsCounts
}// end of class