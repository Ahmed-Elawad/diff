/* 
 * Wrapper class for the ReferenceHRGActivity__c object.
 *
 * History
 * -------
 * 03/01/2013 Dan Carmen   Created
   10/30/2014 Dan Carmen   Change to check the size of the notes field
   02/24/2015 Cindy Freeman     didnt really change anything
   04/25/2017 Lynn Michels	added new variable to hold if the HRG is open
   06/13/2019 Brandon Vidro Added Onsite-One Way and Onsite-Two Way to Event Types
 *
 */
public with sharing class ReferenceHRGActivityWrapper {

   public static final Integer NOTES_SIZE = ReferenceHRGActivity__c.Notes__c.getDescribe().getLength();

   public static final String ONSITE='Onsite';
   public static final String ONSITEONEWAY = 'Onsite-One Way';
   public static final String ONSITETWOWAY = 'Onsite-Two Way';
   /** The types that will identify this as an event instead of a type. */
   public static Set<String> EVENT_TYPES = new Set<String>{ONSITE, ONSITEONEWAY, ONSITETWOWAY};
   
    public Boolean isOpenHRG{get; set;}  //LM
      
   /** Constructor used when creating onboarding activities. */
   public ReferenceHRGActivityWrapper(String p_recId, String p_activityType, String p_activityName, String p_dateFieldName) {
      recId = p_recId;
      activity = new ReferenceHRGActivity__c(Activity_Date__c=Date.today());
      activity.Activity_Type__c = p_activityType;
      activity.Activity__c = p_activityName;
      //activityType = p_activityType;
      //label = p_label;
      dateFieldName = p_dateFieldName;
      //logActivity = false;
      completed = false;
      isOnboarding = true;
      isNew = true;
      isOpenHRG = false;   //LM
  system.debug('LM here');
   } // ReferenceHRGActivityWrapper

      // if this is already linked to an activity
      public ActivityWrapper aw = null;
      
      public void addNoteInfo(String p_notesFieldName) {
         notesFieldName = p_notesFieldName;
      } // addNoteInfo
      
      public String recId{get;private set;}
      
      /** Constructor for ongoing activities. */
      public ReferenceHRGActivityWrapper(String p_recId, ReferenceHRGActivity__c p_activity) {
         recId = p_recId;
         activity = p_activity;
         //completed = activity.Closed__c;
         completed = false;
         isNew = (activity.Id == null);
         //logActivity = isNew;
         isOnboarding = false;
         // save the original values to see if anything changed 
         originalNotesSize = getNotesSize();
         originalActivityDate = activity.Activity_Date__c;
         originalType = activity.Type__c;
		 isOpenHRG = false;
system.debug('LM or here, isNew; isOpenHRG; isClosed? ' +isNew +';' + isOpenHRG + '; ' +activity.Closed__c);
      } // ReferenceHRGActivityWrapper
      
      /** Set information from the Reference HRG object. */
      public void setHRGActivity(Reference_HRG__c refHRG) {
         if (dateFieldName != null && refHRG.get(dateFieldName) != null) {
            activity.Complete_Date__c = ((Date)refHRG.get(dateFieldName));
            //activity.Closed__c = (activity.Complete_Date__c != null);
            //completed = activity.Closed__c;
         }
         if (notesFieldName != null && refHRG.get(notesFieldName) != null) {
            // get the notes from the reference object
            activity.Notes__c = (String)refHRG.get(notesFieldName);
            originalNotesSize = getNotesSize();
         }
      } // setHRGActivity
      
      // do any pre-save checks on the fields to make sure they're okay.
      public void verifyFields() {
         // make sure we don't exceed the field size
         if (String.isNotBlank(activity.Notes__c)) {
            activity.Notes__c = activity.Notes__c.left(NOTES_SIZE);
         }
      } // verifyFields
      
      /** Update the Reference HRG object with information the user entered. */
      public Boolean updateRefHrg(Reference_HRG__c refHRG) {
        Boolean changed = false;
        // see if the task is now completed
         if (completed && dateFieldName != null) {
            // update the date if not already set - only set it the first time it's closed.
            if (refHrg.get(dateFieldName) == null) {
               refHRG.put(dateFieldName,activity.Complete_Date__c);
               changed = true;
            }
         } // if (completed
         
         // see if the notes changed
         if (notesFieldName != null && originalNotesSize != getNotesSize()) {
            refHRG.put(notesFieldName,activity.Notes__c);
            changed = true;
         } // if (notesFieldName != nul
         return changed;
      } // updateRefHrg
      
      /** Does the passed in activity match this instance? */
      public Boolean activityMatches(ReferenceHRGActivity__c p_activity) {
         if (p_activity.Activity_Type__c == activity.Activity_Type__c && p_activity.Activity__c == activity.Activity__c) {
            // use the passed in activity if it matches.
            activity = p_activity;
            /*
            if (activity.Activity_Date__c == null || activity.Activity_Date__c < p_activity.Activity_Date__c) {
               activity.Activity_Date__c = p_activity.Activity_Date__c;
            }
            */
         }
         return false;
      } // activityMatches

      // the size of the notes originally. If the size changes we will assume a change was made.
      public Integer originalNotesSize=0;
      //private String originalType = null;
      public String originalType = null;  //LM
      private Date originalActivityDate = null;
      
      // set the size of the notes field
      public Integer getNotesSize() {
         return ((activity != null && activity.Notes__c != null) ? activity.Notes__c.length() : 0 );
      }
      
      public ReferenceHRGActivity__c activity{get;set;}
      
      /** Is this an onboarding activity? */
      public Boolean isOnboarding{get;set;}
      
      //public String activityType{get;set;}
      // the activity label displayed on the form
      public String label{
         get {return (activity.Activity_Type__c+'-'+activity.Activity__c); } // get
      } // label

      public String dateFieldName{get;set;}
      public String notesFieldName{get;set;}
      // if this is an onboarding activity and the complete date has already been set
      //public String curValue{get;set;}
      // are we going to log activity for this?
      //public Boolean logActivity{get;set;}
      public Boolean completed{get;set;}
      public Boolean isNew{get;set;}

      // are there any changes to save?
      public Boolean hasChangesToSave() {
         return ((!String.isBlank(activity.Type__c) && isNew) || completed || (originalNotesSize != getNotesSize())
                || (originalActivityDate != null && originalActivityDate != activity.Activity_Date__c)
                || (originalType != null && originalType != activity.Type__c)
                ); 
      } // hasChangesToSave
      
      /** Is this an event? If it's not an event we'll assume it's a task. */
      public Boolean isEvent{
         get {return (activity != null && activity.Type__c != null && EVENT_TYPES.contains(activity.Type__c)); }
      } // isEvent
      
} // class ReferenceHRGActivityWrapper