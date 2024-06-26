/* 
   The day of a calendar
   
  History
  -------
  06/21/2013 Dan Carmen   Created
  09/26/2014 Dan Carmen   Changed to without sharing
   
 */
public without sharing class CalendarDay {

   public Date dt;
   
   /** Default constructor. */
   public CalendarDay(Date p_dt) {
      dt = p_dt;
   } // CalendarDay

   /** The long form of the date. */
   public String dayDesc {
      get {
      	DateTime dtTime = DateTime.newInstance(dt,Time.newInstance(12,0,0,0));
         return(dtTime.format('EEEE, MMMM dd, yyyy'));
      }
   } // dayDesc
   
   /** The short form of the date. */
   public String dayDescShort {
      get {
         DateTime dtTime = DateTime.newInstance(dt,Time.newInstance(12,0,0,0));
         return(dtTime.format('M/d/yyyy'));
      }
   } // dayDesc
   
   /** Is this event for the same day? */
   //public Boolean isSameDay(Event evnt) {
   	
   //}
   
   private List<User> users = null;

   // map by user id, list of timeslots   
   private Map<Id, List<TimeSlot>> timeSlotByUserMap = new Map<Id, List<TimeSlot>>();

   /** Add a user to the day. Users will be an ordered list - display in order they were added. */
   public void setUsers(List<User> p_users) {
      users = p_users;
      // for each user setup a map of the time slots available (start with 8am-4pm)
      for (User u : users) {
      	// start at 8am
      	DateTime thisDateTime = DateTime.newInstance(dt, Time.newInstance(DAY_START, 0, 0, 0));
      	
      	List<TimeSlot> timeSlots = new List<TimeSlot>();
      	
      	// hourly slots, for the next 9 hours (until 4pm);
      	for (Integer cnt=0; cnt<=(DAY_END-DAY_START); cnt++) {
      	   TimeSlot ts = new TimeSlot(thisDateTime.addHours(cnt),60);
      	   timeSlots.add(ts);
      	}
      	timeSlotByUserMap.put(u.Id,timeSlots);
      	
      }
   } // addUser
   
   public static Integer DAY_START=8;
   public static Integer DAY_END=18;
   
   public void addEvent(Event p_evnt, String timeZoneName) {
   	
      List<TimeSlot> timeSlots = timeSlotByUserMap.get(p_evnt.OwnerId);
      if (timeSlots != null) {
         // check the start time
         //Integer startHour = (p_evnt.IsAllDayEvent ? DAY_START : p_evnt.StartDateTime.hour());
         Integer startHour = (p_evnt.IsAllDayEvent ? DAY_START : Integer.valueOf(p_evnt.StartDateTime.format('H',timeZoneName)));
         // if outside our range we don't care about it
         if (startHour <= DAY_END) {
            Integer startIdx = (startHour < DAY_START ? 0 : startHour-DAY_START);
            
            // check the end time
            //Integer endHour = p_evnt.EndDateTime.hour();
            Integer endHour = Integer.valueOf(p_evnt.EndDateTime.format('H',timeZoneName));
            Integer endMinute = p_evnt.EndDateTime.minute();
            
            // if the minute is 0, only mark the previous hour as busy, else mark the current hour
            Integer endIdx = (p_evnt.IsAllDayEvent ? (DAY_END - DAY_START) : endHour-DAY_START-(endMinute > 0 ? 0 : 1));
            endIdx = (endIdx >= timeSlots.size() ? timeSlots.size()-1 : endIdx);
            for (Integer idx = startIdx; idx <= endIdx; idx++) {
               timeSlots[idx].isBusy = true;
            }
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Adding event startIds='+startIdx+' endIdx='+endIdx+' event='+p_evnt));
         } // if (startHour >= 8
      }
   } // addEvent
   
   /** A period of time for the day. */
   public class TimeSlot {
   	
   	DateTime startDateTime;
   	DateTime endDateTime;
   	Integer durationInMinutes;
   	
      public TimeSlot(DateTime p_startDateTime, Integer p_durationInMinutes) {
         startDateTime = p_startDateTime;
         durationInMinutes = p_durationInMinutes;
         endDateTime = startDateTime.addMinutes(durationInMinutes);
         isBusy = false;
      } // TimeSlot
      
      Boolean isBusy{get;set;}
      
   } // TimeSlot
   
   public List<CalendarDayOutput> calendarOutput{
      get {
         List<CalendarDayOutput> thisList = new List<CalendarDayOutput>();
         for (User u : users) {
            CalendarDayOutput cdo = new CalendarDayOutput();
            cdo.userName = u.Name;
            List<TimeSlot> timeSlots = timeSlotByUserMap.get(u.Id);
            if (timeSlots != null) {
               cdo.isBusy08am = timeSlots[0].isBusy;
               cdo.isBusy09am = timeSlots[1].isBusy;
               cdo.isBusy10am = timeSlots[2].isBusy;
               cdo.isBusy11am = timeSlots[3].isBusy;
               cdo.isBusy12pm = timeSlots[4].isBusy;
               cdo.isBusy01pm = timeSlots[5].isBusy;
               cdo.isBusy02pm = timeSlots[6].isBusy;
               cdo.isBusy03pm = timeSlots[7].isBusy;
               cdo.isBusy04pm = timeSlots[8].isBusy;
               cdo.isBusy05pm = timeSlots[9].isBusy;
               cdo.isBusy06pm = timeSlots[10].isBusy;
            }
            thisList.add(cdo);
         } // for (User
         return thisList;
      } // get
   } // calendarOutput
} // class CalendarDay