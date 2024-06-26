/*
        Created By: Mendel Guillaume - BlackTab Group
        Date Created: 2015-05-11
        Description: Controller for My Appointments Update page
        
 * History
 * -------
   01/17/2019  Dan Carmen     Commented out Date_Last_Updated_From_SF1__c update on the activity


*/
public with sharing class MyAppointmentsUpdateController 
{
        public Event appointment{get;set;} // Appointment to be updated
        public Opportunity opp{get;set;} // Opportunity to be updated
        public String appointmentType {get;set;} // Indicates which view the user came from. Used to redirect back the right view after clicking save
        //public ID newEventRecordType {get {return MyAppointmentsUtility.mmsEventRecordType;}}
        
        /*
                Constructor: Loads appointment and opp (when applicable) for update     
        */
        public MyAppointmentsUpdateController()
        {
                List<Event> appointments = null;
                List<Opportunity> opps = null;
                string appointmentId = ApexPages.currentPage().getParameters().get('id');
                this.appointmentType = ApexPages.currentPage().getParameters().get('type');
                
                this.appointment  = new Event();
                this.opp = new Opportunity();
                
                appointments = MyAppointmentsUtility.getAppointments('WHERE ID = \'' + String.escapeSingleQuotes(appointmentId) + '\'', 'ASC');
                
                if(!appointments.isEmpty())
                {
                        this.appointment = appointments[0];
                
                        if(this.appointment.WhatId != null && string.valueOf(this.appointment.WhatId).startsWith('006'))
                        {
                                opps = MyAppointmentsUtility.getOpportunities('WHERE ID = \'' + string.valueOf(this.appointment.WhatId) + '\'');
                
                                if(!opps.isEmpty())
                                { 
                                        this.opp = opps[0];
                                }
                        }
                }
        }// end of MyAppointmentsUpdateController
        
        /*
                Updates opp, creates new task and new event log. Called from visualforce page through javascript. Work around for date parsing issue from javascript to SF
        */
    @RemoteAction
    public static ActionResult updateOppAndEventWithDates(Opportunity opp, Event appointment, string closeDate, string startDate, string endDate, string employeesPerPayroll) 
    {
        Date close = null;
        DateTime startDateTime = null;
        DateTime endDateTime = null;
        
        if(opp != null && opp.Id != null)
        {
                try
                {
                        String[] dateParts = closeDate.split('-');
                        close = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                        opp.CloseDate = close;
                }
                catch(Exception ex)
                {
                        return new ActionResult(false, 'Error \n'  + ex.getMessage());
                }
        }
        
        try
        {
                String[] dateTimeParts = startDate.split('T');
                String[] dateParts = dateTimeParts[0].split('-');
                String[] timeParts = dateTimeParts[1].split(':');
                
                startDateTime = Datetime.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]), 
                                                        Integer.valueOf(timeParts[0]), Integer.valueOf(timeParts[1]), 0);
                appointment.StartDateTime = startDateTime;
        }
        catch(Exception ex)
        {
                return new ActionResult(false, 'Error \n'  + ex.getMessage());
        }
        
        try
        {
                String[] dateTimeParts = endDate.split('T');
                String[] dateParts = dateTimeParts[0].split('-');
                String[] timeParts = dateTimeParts[1].split(':');
                
                endDateTime = Datetime.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]), 
                                                        Integer.valueOf(timeParts[0]), Integer.valueOf(timeParts[1]), 0);
                appointment.EndDateTime = endDateTime;
        }
        catch(Exception ex)
        {
                return new ActionResult(false, 'Error \n'  + ex.getMessage());
        }
        
        try
        {
                if(employeesPerPayroll != null && employeesPerPayroll != '')
                {
                        opp.Employees_Paid_Per_Payroll__c = Decimal.valueOf(employeesPerPayroll.replace(',',''));
                }
        }
        catch(Exception ex)
        {
                return new ActionResult(false, 'Error \n'  + ex.getMessage());
        }
        
        return updateOppAndEvent(opp, appointment);
    } // end of updateOppAndEventWithDates
        
        /*
                Updates opp, creates new task and new event log. Called from visualforce page through javascript
        */
    @RemoteAction
    public static ActionResult updateOppAndEvent(Opportunity opp, Event appointment) 
    {
        ActionResult result = new ActionResult(false, '');
        Boolean oppError = false;
        Savepoint sp = Database.setSavepoint(); //create save point to roll back with saving error
        string startString = 'FIELD_CUSTOM_VALIDATION_EXCEPTION,';
            string endString = ': [';
                                

        result.success = true;
        result.message = '';

        try
        {
                if(opp != null && opp.Id != null)
                {
                        try
                        {
                                opp.Updated_from_SF1__c = true;
                                opp.Date_Last_Updated_From_SF1__c = Date.Today();
                                update opp;
                        }
                        catch(Exception ex)
                        {
                                integer startIndex = ex.getMessage().indexOf(startString);
                                integer endIndex = ex.getMessage().lastIndexOf(endString);
                                System.debug('updateOppAndEvent exception: '+ex.getMessage()+'; '+ex.getStackTraceString());
                                        result = new ActionResult(false, 'Error \n'  + ex.getMessage().substring(startIndex + startString.length(), endIndex));
                                oppError = true;
                        }
                   
                        if(oppError)
                        {
                                return result;
                        }
                }
                //appointment.Date_Last_Updated_From_SF1__c = Date.Today();
                update appointment;
        }
        catch(Exception ex)
        {    
                Database.rollback(sp); //Rollback on error
                result = new ActionResult(false, 'Error \n'  + ex.getMessage());        
        }
        
        return result;
    }// end of updateOppAndEvent


        /*
                Class returned by remote action
        */
    public class ActionResult
    {
        public boolean success{get;set;}
        public string message {get;set;}

                /*
                        Constructor
                */
        public ActionResult(Boolean success, String msg)
        {
                this.success = success;
                this.message = msg;
        }// end of constructor
        
    }// end of class
    
}// end of class