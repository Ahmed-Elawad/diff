/* 
   The week of a calendar
   
  History
  -------
  06/21/2013 Dan Carmen   Created
  09/26/2014 Dan Carmen   Changed to without sharing
   
 */
public without sharing class CalendarWeek {

   public CalendarWeek(Date useWeek, Id[] userIds, String timeZoneName) {
      User[] users = [Select Id, Name
                        From User
                       Where Id in :userIds];
      setupDays(useWeek,users);
      setupEvents(users,timeZoneName);
   } // CalendarWeek

   /** Constructor. */
   public CalendarWeek(Date useWeek, User[] users, String timeZoneName) {
   	setupDays(useWeek,users);
   	setupEvents(users,timeZoneName);
   } // CalendarWeek

   // map of the days of the week for easy reference
   private Map<Date,CalendarDay> dayMap = null;
   // ordered list of the days
   private List<CalendarDay> dayList = null;
   
   /** Does this have a list of days built?
    */
   public Boolean hasDayList{
      get {return (dayList != null && !dayList.isEmpty()); }
   } // hasDayList

   public String mondayDateOnly{
      get {       
      	DateTime dtTime = DateTime.newInstance(monday,Time.newInstance(12,0,0,0));
         return(dtTime.format('MMMM dd, yyyy'));
      }
   } // mondayDateOnly
   
   public Date monday{get;set;}
   public Date friday{get;set;}
      
   /** Setup the days of the week. */
   private void setupDays(Date useWeek, User[] users) {
   	
   	dayMap = new Map<Date,CalendarDay>();
   	dayList = new List<CalendarDay>();
   	
   	// only continue if there are users
   	if (users != null && !users.isEmpty()) {
   	   // get the start of the week - toStartOfWeek defaults to Sunday
         monday = useWeek.toStartOfWeek().addDays(1);
         for (Integer cnt=0; cnt<5; cnt++) {
            // use the friday variable - will be set to friday at the end
            friday = monday.addDays(cnt);
            CalendarDay thisDay = new CalendarDay(friday);
            thisDay.setUsers(users);
            dayMap.put(friday,thisDay);
            dayList.add(thisDay);
         } // for (Integer cnt
   	} // if (users != null && !users.isEmpty
   } // setup
   
   /** The timeZoneName is the time zone we are displaying the activity in. 
    */
   public void setupEvents(User[] users, String timeZoneName) {
   	if (users != null && !users.isEmpty()) {
         // get the userids
         Id[] userIds = new Id[]{};
         for (User u : users) {
            userIds.add(u.Id);
         } // for
      
         for (Event[] events : [Select Id
                                   ,AccountId
                                   ,ActivityDate
                                   ,ActivityDateTime
                                   ,DurationInMinutes
                                   ,EndDateTime
                                   ,IsAllDayEvent
                                   ,IsPrivate
                                   ,OwnerId
                                   ,ShowAs
                                   ,StartDateTime
                                   ,Subject
                                   ,Type
                                   ,WhatId
                                   ,WhoId
                               From Event
                              Where OwnerId in :userIds
                                and ActivityDate >= :monday
                                and ActivityDate <= :friday]) {
            for (Event evnt : events) {
               CalendarDay day = dayMap.get(evnt.ActivityDate);
               if (day != null) {
                  day.addEvent(evnt,timeZoneName);
               }
            } // for (Event evnt
                                	
         } // for (Events[]
   	} // if (users != null &&
   } // setupEvents
   
   public String mondayDesc {
      get {
      	return dayList[0].dayDesc;
      }
   } // mondayDesc
   
   public CalendarDay dayMonday {
      get {
      	return dayList[0];
      }
   } // getMonday

   public String tuesdayDesc {
      get {
         return dayList[1].dayDesc;
      }
   } // tuesdayDesc
   
   public CalendarDay dayTuesday {
      get {
         return dayList[1];
      }
   } // dayTuesday

   public String wednesdayDesc {
      get {
         return dayList[2].dayDesc;
      }
   } // wednesdayDesc
   
   public CalendarDay dayWednesday {
      get {
         return dayList[2];
      }
   } // dayWednesday

   public String thursdayDesc {
      get {
         return dayList[3].dayDesc;
      }
   } // thursdayDesc
   
   public CalendarDay dayThursday {
      get {
         return dayList[3];
      }
   } // dayThursday

   public String fridayDesc {
      get {
         return dayList[4].dayDesc;
      }
   } // fridayDesc
   
   public CalendarDay dayFriday {
      get {
         return dayList[4];
      }
   } // dayFriday

   
} // class CalendarWeek