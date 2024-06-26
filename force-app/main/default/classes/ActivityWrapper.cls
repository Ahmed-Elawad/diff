/* 
 * Wrapper for the Referral information. This is a separate class from the ReferralController because this
   has to be defined as global when it implements the Comparable interface and we didn't want to set the whole
   controller to global.
 *
 * History
 * -------
 * 03/14/2013 Dan Carmen   Created
   10/24/2013 Dan Carmen   Added deleteActivity flag
   10/02/2014 Josh Cartwright - write type, activity type, and activity to task or event field "HRG Activity Type"
   02/16/2016 Dan Carmen    Added check for length of HRG Activity Type
   04/25/2017 Lynn Michels	Added criteria for description
 *
 */
global with sharing class ActivityWrapper implements Comparable {

   public Task tsk{get;set;}
   public Event evnt{get;set;}
   public Boolean deleteActivity{get;set;}
   private String originalDesc = null;
      
   public ActivityWrapper() {
   	deleteActivity = false;
   } // ActivityWrapper
   
   public ActivityWrapper(Task p_tsk) {
   	deleteActivity = false;
      setTask(p_tsk);
   } // ActivityWrapper
   
   public void setTask(Task p_tsk) {
      evnt = null;
      tsk = p_tsk;
      originalDesc = tsk.Description;  //LM 4/25
	  //activityId = p_tsk.Id;
      activityContactId = p_tsk.WhoId;
      taskOrEvent = 'Task';
   } // setTask
      
   public ActivityWrapper(Event p_evnt) {
   	deleteActivity = false;
      setEvent(p_evnt);
   } // ActivityWrapper

   public void setEvent(Event p_evnt) {
      tsk = null;
      evnt = p_evnt;
      originalDesc = evnt.Description;  //LM 4/25
      //activityId = p_evnt.Id;
      activityContactId = p_evnt.WhoId;
      taskOrEvent = 'Event';
      setClosestTimeOption(evnt.ActivityDateTime);
   } // setEvent
         
   
   /** Is this an event? If it is not an event, it is assumed to be a task. */
   public Boolean isEvent{get;set;}
   
   public Boolean isTask{get;set;}

   public Id activityId{
      get {return (isEvent ? evnt.Id : (isTask ? tsk.Id : null)); }
   }

   /** What type of activity is this (Task or Event)? */
   public String taskOrEvent{get;
   	set {
         taskOrEvent = value;
         isEvent = (taskOrEvent != null && taskOrEvent == 'Event');
         isTask = (taskOrEvent != null && taskOrEvent == 'Task');
   	} // set
   } // taskOrEvent
   
   /** If this is associated with a Contact - the contact id. */
   public String activityContactId{get;set;}
   
   public Date activityDate{
      get {return (isEvent ? evnt.ActivityDate : tsk.ActivityDate); }
   } // activityDate
   
   /** Append onto the description of the task or event. */
   public void addToDescription(String p_desc) {
   	if (isEvent) {
   	   evnt.Description = (evnt.Description != null ? evnt.Description+'\n' : '') + p_desc;
   	} else if (isTask) {
         tsk.Description = (tsk.Description != null ? tsk.Description+'\n' : '') + p_desc;
   	}
   } // addToDescription
   
   public static final Integer ACTIVITY_TYPE_SIZE = Task.HRG_Activity_Type__c.getDescribe().getLength();

   /** Append onto the HRG Activity Type of the task or event. */
   public void addToHRGActivityType(String p_desc) {
      String activityType = (isEvent ? evnt.HRG_Activity_Type__c : (isTask ? tsk.HRG_Activity_Type__c : null));
      // make sure it doesn't exceed the field size
      activityType = ((String.isNotBlank(activityType) ? activityType+';' : '') + p_desc).left(ACTIVITY_TYPE_SIZE);
      if (isEvent) {
         evnt.HRG_Activity_Type__c = activityType;
      } else if (isTask) {
         tsk.HRG_Activity_Type__c = activityType;
      }
   } // setHRGActivityType
   
   global Integer compareTo(Object objectToCompareTo) {
      if (objectToCompareTo != null) {
         ActivityWrapper compareAw = (ActivityWrapper)objectToCompareTo;
         if (activityDate != null && compareAw.activityDate != null) {
            return activityDate.daysBetween(compareAw.activityDate);
         }
      } // if (objectToCompareTo != null
      return -1;
   } // compareTo

   /** The number of HRG Activity records. */
   public Integer nbrHrgActivity{
      get {return (hasHrgActivity ? hrgActivity.size() : 0); }
   }      
   
   public Boolean hasHrgActivity{
      get {return (hrgActivity != null && !hrgActivity.isEmpty()); }
   }
   
   // keep a map of the current activity by recId
   private Map<String,ReferenceHRGActivityWrapper> hrgActMap = new Map<String,ReferenceHRGActivityWrapper>();
   
   // the original list of activity that was saved.
   public List<ReferenceHRGActivityWrapper> originalHrgActivity = new List<ReferenceHRGActivityWrapper>();
   
   /** reset back to the "Original" activity.
    */
   public void resetActivity() {
	if (tsk != null) {
   	     tsk.Description = originalDesc;
   	  } else if (evnt != null) {
   	     evnt.Description = originalDesc;
   	  }
	  hrgActivity = null;
      hrgActMap.clear();
      removedActivities.clear();           
      for (ReferenceHRGActivityWrapper haw : originalHrgActivity) {
         haw.aw = null;
         haw.isOpenHRG = true;  //LM used to decide if the Activity Date should be read only     
         addHRGActivity(haw);
      }
   } // resetActivity
   
   public List<ReferenceHRGActivityWrapper> hrgActivity{get;set;}
   
   public void addHRGActivity(ReferenceHRGActivityWrapper activity) {   	
   	if (hrgActivity == null) {
   	   hrgActivity = new List<ReferenceHRGActivityWrapper>();
   	}
   	// if the incoming HRG activity is attached to an activity, remove from the other one.    	  	
   	if (activity.aw != null) {  		
   		// make sure it's not in the current activity
   		if (!hrgActMap.containsKey(activity.recId)) {
   		   activity.aw.removeActivityByRecId(activity.recId);
   		   activity.aw = null;
   		}
   	} // if (activity.aw != null
   	if (activity.aw == null) { 		
         hrgActivity.add(activity);
         hrgActMap.put(activity.recId,activity);
         activity.aw = this;
   	}  	
   } // addHRGActivity

   public List<ReferenceHRGActivityWrapper> removedActivities = new List<ReferenceHRGActivityWrapper>();
   
   public ReferenceHRGActivityWrapper removeActivityByRecId(String recId) {
      // did we find the activity to remove?
      ReferenceHRGActivityWrapper foundActivity = null;
      List<ReferenceHRGActivityWrapper> temp_hrgActivity = new List<ReferenceHRGActivityWrapper>();
      for (ReferenceHRGActivityWrapper haw : hrgActivity) {
         if (haw.recId == recId) {
            foundActivity = haw;
         } else {
            temp_hrgActivity.add(haw);
         }
      } // for
      hrgActivity = temp_hrgActivity;
      return foundActivity;
   } // removeActivityByRecId
   
   public ReferenceHRGActivityWrapper removeActivity(Id activityId) {
   	ReferenceHRGActivityWrapper foundActivity = null;
      List<ReferenceHRGActivityWrapper> temp_hrgActivity = new List<ReferenceHRGActivityWrapper>();
      for (ReferenceHRGActivityWrapper haw : hrgActivity) {
         if (haw.activity.Id == activityId) {
            foundActivity = haw;
         } else {
            temp_hrgActivity.add(haw);
         }
      } // for
      hrgActivity = temp_hrgActivity;
      return foundActivity;
   } // removeActivity
   
   /** Is the meeting not held flag set? */
   public Boolean meetingNotHeld{
      get {return (isEvent ? evnt.Meeting_Not_Held__c : (isTask ? tsk.Meeting_Not_Held__c : false)); }
   } // meetingNotHeld
      
   /** Is the reason cancelled filled out? */
   public Boolean reasonCancelledFilled() {
      return (isEvent ? String.isNotBlank(evnt.Reason_Canceled__c) : (isTask ? String.isNotBlank(tsk.Reason_Canceled__c) : false));
   } // reasonCancelledFilled
   
   /** Is the date activity complete filled out? */
   public Boolean activityIsComplete {
      get {return (isEvent ? evnt.Date_Activity_Completed__c != null : (isTask ? tsk.Date_Activity_Completed__c != null : false)); }
   } // activityIsComplete
   
   /** Has the client summary been filled out? */
   public Boolean clientSummaryFilled() {
      return (isEvent ? String.isNotBlank(evnt.Client_Summary__c) : (isTask ? String.isNotBlank(tsk.Client_Summary__c) : false));
   }
   
   public Boolean logClientSummaryError(String errMsg) {
   	if (isEvent) {
         evnt.Client_Summary__c.addError(errMsg);
   	} else if (isTask) {
         tsk.Client_Summary__c.addError(errMsg);
   	}
      return false;
   } // logClientSummaryError
   
   public Boolean logReasonCanceledError(String errMsg) {
      if (isEvent) {
         evnt.Reason_Canceled__c.addError(errMsg);
      } else if (isTask) {
         tsk.Reason_Canceled__c.addError(errMsg);
      }
      return false;
   } // logReasonCanceledError
   
   public Boolean setWhoId() {
   	String whoIdValue = ((activityContactId != null && activityContactId.startsWith('003')) ? activityContactId : null);
   	if (isEvent) {
   	   evnt.WhoId = whoIdValue;
   	} else if (isTask) {
   	   tsk.WhoId = whoIdValue;
   	}
      return true;
   } // setWhoId
   
   private static Time TEMP_TIME = Time.newInstance(12, 0, 0, 0);

   /** Is this new activity? */
   public Boolean isNew{
      get {
         return (activityId == null);
      } // get
   } // isNew
   
   public String key{get;set;}
   
   /** Link for the reference object - used as part of the mass create routine. 
    */
   public Reference_HRG__c refHrg;
   
   public String selectedTime{get;set;}
   
   private static List<SelectOption> allTimeOptions=null;
   
   public List<SelectOption> timeOptions{
      get { checkOptions(); 
      	   return allTimeOptions;
      }
   } // timeOptions
   	
   private void setClosestTimeOption(DateTime p_checkTime) {
      checkOptions();
      if (p_checkTime != null) {
         Integer checkTime = Integer.valueOf(p_checkTime.format('HHmmss'));
         selectedTime = null;
         // check for a time range
         for (SelectOption so : timeOptions) {
            Integer thisTime = Integer.valueOf(so.getValue().replaceAll(':',''));
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'setClosestTimeOption checkTime='+checkTime+' thisTime='+thisTime+' match='+(checkTime <= thisTime)));
            if (checkTime <= thisTime) {
               selectedTime = so.getValue();
               break;
            }
         } // for
      } // if (p_checkTime
   } // setClosestTimeOption
   
   /* Method to setup the options needed for the form.
    */
   private void checkOptions() {
      if (allTimeOptions == null) {
         allTimeOptions = new List<SelectOption>();
         DateTime startDt = DateTime.newInstance(Date.Today(), Time.newInstance(7,0,0,0));
         DateTime loopDt = DateTime.newInstance(Date.Today(), Time.newInstance(7,0,0,0));
         DateTime endDt = DateTime.newInstance(Date.Today(), Time.newInstance(19,0,0,0));
         while (startDt <= endDt) {
            allTimeOptions.add(new SelectOption(startDt.format('HH:mm:ss'),startDt.format('hh:mm a')));
            startDt = startDt.addMinutes(30);
         } // while
      } // if (timeOptions == null
   } // checkOptions
   
   public void setActivityDateTime() {
      evnt.ActivityDateTime = DateTime.valueOf(evnt.ActivityDate.year()+'-'+
                                                   evnt.ActivityDate.month()+'-'+
                                                   evnt.ActivityDate.day()+' '+
                                                   selectedTime);

   } // setActivityDateTime
   
} // class ActivityWrapper