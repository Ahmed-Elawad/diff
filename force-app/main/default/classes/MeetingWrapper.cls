/* Handle the Meeting information. 
   
  History
  -------
  02/07/2012 Dan Carmen       Created.
  09/26/2017 Dan Carmen       Added additional functionality
  01/04/2022 Dan Carmen       Fix tests
  
 */
public with sharing class MeetingWrapper {

   /** Translation from the picklist to a numeric value.
    */
   public Integer getNumberMinutes(String value) {
      if (value != null) {
         if (value == '30 Minutes') {  return 30;
         } else if (value == '1 Hour') {  return 60;
         } else if (value == '1 1/2 Hours') { return 90;
         } else if (value == '2 Hours') { return 120;
         } else if (value == '2 1/2 Hours') { return 150;
         } else if (value == '3 Hours') { return 180;
         } else if (value == '3 1/2 Hours') { return 210;
         } else if (value == '4 Hours') { return 240;
         }
      } // if (value != null
      return 0;
   } // getNumberMinutes
   
   /** Translation from a numerical value to a picklist value.
    */
   public String getMinutesString(Integer numMinutes) {
      if (numMinutes != null) {
         if (numMinutes <= 30) { return '30 Minutes';
         } else if (numMinutes <= 60) { return '1 Hour';
         } else if (numMinutes <= 90) { return '1 1/2 Hours';
         } else if (numMinutes <= 120) { return '2 Hours';
         } else if (numMinutes <= 150) { return '2 1/2 Hours';
         } else if (numMinutes <= 180) { return '3 Hours';
         } else if (numMinutes <= 210) { return '3 1/2 Hours';
         } else { return '4 Hours';
         }
      } // if (value != null
      return '30 Minutes';
   } // getMinutesString
   
   public Event evnt { get; 
      set {
         if (value != null) {
            evnt = value;
            meeting = new Meeting__c();
            meeting.Meeting_Time__c = setClosestTimeOption(evnt.ActivityDateTime);
            meeting.Meeting_Duration__c = getMinutesString((Integer)evnt.DurationInMinutes);
         }
      } // set
   } // pageController

   public Meeting__c meeting {get;set;}
   
   /** Default constructor.
    */
   public MeetingWrapper() {
   	  //setOptions();
   	  evnt = new Event();
   	  meeting = new Meeting__c();
   } // StartEndDateController
   
   public String getFormattedEndDateTime() {
   	  setEventFields();
   	  return (endDateTime != null ? endDateTime.format('M/d/yyyy h:mm a') : null);
   } // getFormattedEndDateTime
   
   public DateTime endDateTime{get;private set;}
   
   /** Set the activityDateTime and durationinminutes fields on the event.
    */
   public void setEventFields() {
      evnt.DurationInMinutes = getNumberMinutes(meeting.Meeting_Duration__c);
      evnt.ActivityDateTime = getDateTime(evnt.ActivityDate,meeting.Meeting_Time__c);
      endDateTime = evnt.ActivityDateTime.addMinutes(evnt.DurationInMinutes);
   } // setEventFields
   
   /** Get the closest value in the picklist to the passed in time.
    */
   public String setClosestTimeOption(DateTime p_checkTime) {
   	  String retVal = null;
      if (p_checkTime != null) {
         DateTime checkTime = DateTime.newInstance(Date.today(), p_checkTime.time());
         Long longCheckTime = checkTime.getTime();
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'in setClosestTimeOption2 checkTime='+checkTime));
         Schema.DescribeFieldResult dfr = Meeting__c.Meeting_Time__c.getDescribe();
         List<Schema.PicklistEntry> picklist = dfr.getPicklistValues();
         String lastRecord = null;
         for (Schema.PicklistEntry entry : picklist) {
            if (entry.isActive()) {
               // picklist value is in the format 05:00 AM - convert this to a time component
               DateTime thisDateTime = getDateTime(Date.today(),entry.getValue());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'in setClosestTimeOption2 entry='+entry.getValue()+' checkTime='+checkTime+' thisDateTime='+thisDateTime+' compare='+(longCheckTime < thisDateTime.getTime())));
               if (thisDateTime != null && ( longCheckTime < thisDateTime.getTime())) {
                  retVal = entry.getValue();
                  break;
               }
               lastRecord = entry.getValue();
            } // if
         } // for
         // if the time is after what's in the picklist, use the latest picklist value.
         if (retVal == null) {
            retVal = lastRecord;
         }
      } // if (p_checkTime != null
      return retVal;
   } // setClosestTimeOption

   /** Get the Time value of a String. The time is assumed to be in the format 05:00 AM
    */
   public DateTime getDateTime(Date p_date, String value) {
      //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'in getTime value='+value));
   	  DateTime retVal = null;
      // verify entry is correct length
      if (value != null && value.length() == 8) {
         // check if AM or PM
         Boolean isPM = value.endsWith('PM');
         Integer hours = Integer.valueOf(value.substring(0,2));
         Integer minutes = Integer.valueOf(value.substring(3,5));
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'value='+value+' hours='+hours+' minutes='+minutes+' isPM='+isPM));
         // if PM, add 12 to the hours
         if (isPM && hours < 12) {
            hours += 12;
         }
         retVal = DateTime.newInstance(p_date.year(), p_date.month(), p_date.day(), hours, minutes, 0);
         //retVal = Time.newInstance(hours, minutes, 0, 0);
         //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'after check value='+value+' hours='+hours+' minutes='+minutes+' isPM='+isPM+' retVal='+retVal));
      } // if (value != null
      return retVal;
   } // getDateTime
   

} // class MeetingWrapper