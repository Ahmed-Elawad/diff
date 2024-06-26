/* Controller for the setting up the Meeting information. 
   
  History
  -------
  02/22/2011 Dan Carmen   Created.
  11/16/2017 Dan Carmen   Increasing the API version
  
 */
public with sharing class MeetingController extends ComponentControllerBase {

   public Event evnt { get; 
      set {
         if (value != null) {
            evnt = value;

            if(timeSelection == null){
               setClosestTimeOption(evnt.ActivityDateTime);
            }

            if(durationSelection == null){
               durationSelection = String.valueOf(evnt.DurationInMinutes);
            }

            setStartEndDateTime();
            //pageController.setComponentController(this);
         }
      } // set
   } // pageController

   // Default constructor.
   public MeetingController() {
   	setOptions();
   	evnt = new Event();
   } // StartEndDateController
   
   public DateTime startDateTime{get;private set;}
   public String getFormattedEndDateTime() {
   	return (endDateTime != null ? endDateTime.format() : null);
   }
   
   public DateTime endDateTime{get;private set;}
   
   private void setStartEndDateTime() {
      if (durationSelection != null && evnt.ActivityDate != null && timeSelection != null) {
         evnt.DurationInMinutes = Integer.valueOf(durationSelection);
         evnt.ActivityDateTime = DateTime.valueOf(evnt.ActivityDate.year()+'-'+
                                                   evnt.ActivityDate.month()+'-'+
                                                   evnt.ActivityDate.day()+' '+
                                                   timeSelection);
         endDateTime = evnt.ActivityDateTime.addMinutes(evnt.DurationInMinutes);
      }
   } // setStartEndDateTime
   
   private void setClosestTimeOption(DateTime p_checkTime) {
      if (p_checkTime != null) {
         Integer checkTime = Integer.valueOf(p_checkTime.format('HHmmss'));
         timeSelection = null;
         // make sure the options are set
         for (SelectOption so : timeOptions) {
            Integer thisTime = Integer.valueOf(so.getValue().replaceAll(':',''));
            if (checkTime <= thisTime) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'checkTime='+checkTime+' thisTime='+thisTime+' MATCH!!'));
               timeSelection = so.getValue();
               break;
            }
         } // for
   	}
   } // setClosestTimeOption

   public String timeSelection{get;set;}
   
   public String durationSelection{get;set{
         System.debug(durationSelection);
         System.debug(value);
         durationSelection = value;
      }
   }
   
   public List<SelectOption> timeOptions{get;private set;}
   
   public List<SelectOption> durationOptions{get;private set;}
   
   // Method to setup the options needed for the form.
   private void setOptions() {
      if (timeOptions == null) {
         timeOptions = new List<SelectOption>();
         DateTime startDt = DateTime.newInstance(Date.Today(), Time.newInstance(0,0,0,0));
         DateTime loopDt = DateTime.newInstance(Date.Today(), Time.newInstance(0,0,0,0));
         DateTime endDt = DateTime.newInstance(Date.Today().addDays(1), Time.newInstance(0,0,0,0));
         while (loopDt.isSameDay(startDt)) {
         	timeOptions.add(new SelectOption(loopDt.format('HH:mm:ss'),loopDt.format('hh:mm a')));
            loopDt = loopDt.addMinutes(30);
         } // while
      } // if (timeOptions == null
      if (durationOptions == null) {
         durationOptions = new List<SelectOption>();
         durationOptions.add(new SelectOption('30','30 Minutes'));
         durationOptions.add(new SelectOption('60','1 Hour'));
         durationOptions.add(new SelectOption('90','1 1/2 Hours'));
         durationOptions.add(new SelectOption('120','2 Hours'));
         durationOptions.add(new SelectOption('150','2 1/2 Hours'));
         durationOptions.add(new SelectOption('180','3 Hours'));
         durationOptions.add(new SelectOption('210','3 1/2 Hours'));
         durationOptions.add(new SelectOption('240','4 Hours'));
      }
   } // setOptions
   
   public PageReference changeDateTime() {
      setStartEndDateTime();
      return null;
   } // changeDateTime

} // class MeetingController