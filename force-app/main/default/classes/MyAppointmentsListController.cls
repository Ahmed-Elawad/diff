/*
	Created By: Mendel Guillaume - BlackTab Group
	Date Created: 2015-05-11
	Description: Controller for My Appointments List page
*/
public with sharing class MyAppointmentsListController
{
	public String appointmentType {get;set;} // type of events to display
	public String todayFormatted {get;set;} // formatted date displayed for "Today" list
	public String appointmentLabel // title of list based on appointment type
	{
		get
		{
			if(this.appointmentType == 'Week')
			{
				return 'This Week';
			}
			if(this.appointmentType == 'Last')
			{
				return 'Last Week';
			}
			
			return this.appointmentType;
		}
	}
			
	/*
		Constructor
	*/
	public MyAppointmentsListController()
	{
		this.appointmentType = ApexPages.currentPage().getParameters().get('type');		
		
		if(this.appointmentType == null || (this.appointmentType != 'Future' && this.appointmentType != 'Past' && this.appointmentType != 'Week' && this.appointmentType != 'Last' && this.appointmentType != 'Today'))
		{
			this.appointmentType = 'Today';
		}
		
		if(this.appointmentType == 'Today')
		{
			todayFormatted = Datetime.now().format('MMM d, yyyy');
		}
	}// end of MyAppointmentsListController
	
	/*
		Returns number of appointments in list
	*/
	public Integer getAppointmentCount()
	{
		return MyAppointmentsUtility.getAppointmentCount(this.appointmentType);
	}// end of getAppointmentCount
	
	/*
		Returns list of appointments
	*/
	public List<Event> getAppointments()
	{
		return MyAppointmentsUtility.getAppointments(this.appointmentType);
	}// end of getAppointments
	
	/*
		Returns list of appointments group by date or time (Today)
	*/
	public List<MyAppointmentsUtility.AppointmentGroup> getAppointmentGroups()
	{
		return MyAppointmentsUtility.getAppointmentGroups(getAppointments(), this.appointmentType);
	}// end of getAppointmentGroups
}// end of class