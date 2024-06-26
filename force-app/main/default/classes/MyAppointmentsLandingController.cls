/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Controller for My Appointments Landing page
*/
public with sharing class MyAppointmentsLandingController 
{
	/*
		Returns number of appointments for Today
	*/
	public Integer getTodayAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount('Today');
	}
	
	/*
		Returns number of appointments for This Week
	*/
	public Integer getWeekAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount('Week');
	}
	
	/*
		Returns number of appointments for Future
	*/
	public Integer getFutureAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount('Future');
	}
	
	/*
		Returns number of appointments for Past 30 days
	*/
	public Integer getPastAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount('Past');
	} 
	
	/*
		Returns number of appointments for Last Week
	*/
	public Integer getLastWeekAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount('Last');
	} 
}// end of class