/* 
 * Create activity controller for the lightning components
 *
 * History
    * -------
    10/17/2017 Dan Carmen       Created
    03/27/2017 Mike Matonis     Updated
    11/08/2018 Jermaine Stukes  Added Reminder Date Methods
    11/27/2018 Jermaine Stukes  Added Initial Presentation Check
    06/01/2020 Manmeet Vaseer   SFDC-2592 & 3404, Added sorting for Picklists
    07/17/2020 Manmeet Vaseer   Polymorphed saveEvent() 
    08/02/2021 Dan Carmen       Add ability to pass in Description
    11/10/2023 Dan Carmen       Remove insertPlatformTracker

 */
 public with sharing class CreateActivityController {

    @AuraEnabled
    public static Task getNewTask(String activityType, Id recordId, String p_desc, String p_attendees) {
        System.debug('getNewTask activityType='+activityType+' recordId='+recordId+' p_desc='+p_desc+' p_attendees='+p_attendees);
        Task tsk = getNewTask(activityType, recordId);
        System.debug('getNewTask tsk description='+tsk.Description);
        if (tsk != null && String.isNotBlank(p_desc)) {
           tsk.Description = p_desc + (String.isNotBlank(tsk.Description) ? '\n'+tsk.Description : ''); 
        }
        if (tsk != null && String.isNotBlank(p_attendees)) {
           Integer fldLength=Task.Meeting_Attendees__c.getDescribe().getLength();
           tsk.Meeting_Attendees__c = p_attendees.left(fldLength);
        }            
        return tsk;
    } // getNewTask

    @AuraEnabled
    public static Task getNewTask(String activityType, Id recordId) {
        System.debug('CreateActivityController::getNewTask, activityType: ' + activityType + ', recordId: ' + recordId);
        MassCreateActivity mca = new MassCreateActivity(recordId, activityType);
        Task tsk = mca.firstTask;
        return tsk;
    } 

    @AuraEnabled
    public static Event getNewEvent(String activityType, Id recordId, String p_desc, String p_attendees) {
        System.debug('getNewEvent activityType='+activityType+' recordId='+recordId+' p_desc='+p_desc+' p_attendees='+p_attendees);
        Event evt = getNewEvent(activityType, recordId);
        if (String.isNotBlank(p_desc)) {
           evt.Description = p_desc + (String.isNotBlank(evt.Description) ? '\n'+evt.Description : ''); 
        }
        if (evt != null && String.isNotBlank(p_attendees)) {
           Integer fldLength=Event.Meeting_Attendees__c.getDescribe().getLength();
           evt.Meeting_Attendees__c = p_attendees.left(fldLength);
        }            
        return evt;
    } // getNewEvent

    @AuraEnabled
    public static Event getNewEvent(String activityType, Id recordId) {
        MassCreateActivity mca = new MassCreateActivity(recordId, activityType);
        MeetingWrapper meetWrap = mca.firstMeeting;
        return meetWrap.evnt;
    } 
    
    @AuraEnabled
    public static DataEnvelope getDataEnvelope(String sourceObjectName){
        DataEnvelope envelope = new DataEnvelope(getOptions(sourceObjectName), getProfileName());
        return envelope;
    }

    @AuraEnabled
    public static Task saveTask(String tsk) {

        Task newTask = (Task) JSON.deserialize(tsk, Task.class);
        System.debug('newTask CAR__c='+newTask.Car__c);
        try {
           upsert newTask;
        } catch(Exception e) {
           newTask.WhoId = null;
           upsert newTask;
        }

        OpportunityStatusUpdater.updateOpportunityStatusWithNewActivity(newTask);
        return newTask;
    } 

    @AuraEnabled
    public static Event saveEvent(String evnt) {
        return saveEvent(evnt, '');
    }
     
    @AuraEnabled
    public static Event saveEvent(String evnt, String attendees) {
        System.debug('CreateActivityController::saveEvent, attendees='+attendees+' evnt='+evnt);
        
        Event newEvent = (Event) JSON.deserialize(evnt, Event.class);
        
        // attendees parameter is not currently being used
        //List<Map<String, String>> addAttendees = new List<Map<String, String>>();        
        //if(attendees.length() > 0)	{
        //	addAttendees = (List<Map<String, String>>) JSON.deserialize(attendees, List<Map<String, String>>.class);
        //}
        //System.debug('CreateActivityController::saveEvent, addAttendees size: ' + addAttendees.size());
		
		String msg = '';        
        try{
            upsert newEvent;
        }catch(DmlException ex) {
            throw new AuraHandledException('Error Saving the Event: '+ex.getMessage());
            //Get All DML Messages
            //for (Integer i = 0; i < ex.getNumDml(); i++) {
                //Get Validation Rule & Trigger Error Messages
            //    msg += ex.getDmlMessage(i) +  '\n' ;
            //}
            //throw new AuraHandledException(msg);
        }catch(Exception e){
            newEvent.WhoId = null;
            upsert newEvent;
        }
        /* Not currently being used. Writing to Meeting_Attendees__c on the activity instead.
        List<EventRelation> ers = new List<EventRelation>();
        for(Integer i = 0; i < addAttendees.size(); i++)	{
            EventRelation er = new EventRelation();
            er.EventId = newEvent.Id;
            er.IsInvitee = true;
            er.IsWhat = false;
            Map<String, String> attend = addAttendees.get(i);
            er.RelationId = attend.get('value'); // Contact Id
        	System.debug('CreateActivityController::saveEvent, er.RelationId: ' + er.RelationId + ', er.EventId: ' + er.EventId);
            
            ers.add(er);
        }
        
        if(ers.size() > 0)	{
            try	{
            	insert ers;
            }
            catch(Exception e)	{
                throw new AuraHandledException('CreateActivityController::saveEvent: Unable to insert EventRelation records for EventId ' + newEvent.Id + ' due to ' + e.getMessage());                
            }
        }
        */
        OpportunityStatusUpdater.updateOpportunityStatusWithNewActivity(newEvent);
        return newEvent;
    } // saveEvent

    public static SelectOptionWrapper[] getOptions(String sourceObjectName) {
        Id recordTypeId = RecordTypeHelper.getDefaultRecordType(sourceObjectName).getRecordTypeId();
        RecordType rt = RecordTypeDataAccessor.getRecordTypeById(recordTypeId);

        SelectOptionWrapper[] wrappers = CreateActivityPicklistHelper.getPicklistValues(rt);
        CreateActivityPicklistHelper.addStaticPicklistValues(wrappers);
        return wrappers;
    } 
     
    @AuraEnabled
    public static Boolean initialPresentationCheck(String recordId)
    {
        List<Event> eventList = [Select Id from Event where WhatId=:recordId and Type like 'Presentation - Initial%'];
        Boolean hasInitialPresentation = eventList.isEmpty() ? false : true;
        System.debug('OPPID'+recordId+'INITIAL PRESENTATION'+hasInitialPresentation);
        return hasInitialPresentation;
    }

    @AuraEnabled
    public static String getProfileName(){
        Id profileId = UserInfo.getProfileId();
        Profile p = [SELECT Id, Name FROM Profile WHERE Id = :profileId LIMIT 1];
        return p.Name;
    }

     //SFDC-2592 (US2)
    @AuraEnabled
    public static Boolean isPEOSalesUser(){
        User u = UserHelper.getRunningUser();
        //System.debug('Running User: ' + u.Name + ', Sales Org: ' + u.Sales_Org__c);
        return (u != null && u.Sales_Org__c == 'PEO') ;
    } // isPEOSalesUser

     /*
      * SFDC-3404 (US3) 
      * Read the picklist values from the Create_Activity_Button__c custom setting.
      * 
      * @param picklistName Name of the Picklist from the Create Activity Button form. Load all the label values assoicated with this picklist.
      * @param groupName Filter (only include) the picklist label values based on the group name.
      * @param isPEOUser Tell us if the current logged in user is a PEO. We want to exclude some of the picklist values based on the PEO user.
      * @param isMultipleInitialPresentations If isMultipleInitialPresentations=true, then the 'Initial Presentation' Event has already been created in the Opportunity.
      * 
      */
    @AuraEnabled
    public static List<String> getPicklistValues(String picklistName, String groupName, Boolean isPEOUser, Boolean isMultipleInitialPresentations){
        System.debug('getPicklistValues, picklistName: ' + picklistName + ', groupName: ' + groupName + ', isPEOUser: ' + isPEOUser + ', isMultipleInitialPresentations: ' + isMultipleInitialPresentations);
                
        Create_Activity_Button__c[] picklistValues = [SELECT Label_Name__c, Exclude_For_PEO_User__c FROM Create_Activity_Button__c 
                              WHERE Picklist_Name__c = :picklistName AND Group_Name__c = :groupName ORDER BY Sort_Order__c];
        String[] retValues = new String[]{};
        for (Create_Activity_Button__c cab : picklistValues)	{
            // It it is not a PEO user then get all the picklist values. That is, if it is a Sales User (non PEO)
            // It it is a PEO user then get all the picklist values except the one where Exclude_For_PEO_User__c = true in the Create_Activity_Button__c custom setting.
            // That is, we want to exclude the picklist values for the PEO user where Exclude_For_PEO_User__c = true in the Create_Activity_Button__c custom setting
            if (!isPEOUser || (isPEOUser && !cab.Exclude_For_PEO_User__c)) {
               // If isMultipleInitialPresentations=true, then the 'Initial Presentation' Event has already been created in the Opportunity.
               // 
               // If the 'Initial Presentation' Event already exist in the Opportunity
               // then do not give the user option to create another 'Initial Presentation' Event. That is,
               // do no add it to the picklist value.
               if(groupName == 'Opportunity' && cab.Label_Name__c == 'Initial Presentation' && !isMultipleInitialPresentations)	{
                  retValues.add(cab.Label_Name__c);
               }  else if(cab.Label_Name__c != 'Initial Presentation') {
                  //SFDC-3487 (US6b) We want to show Marketing activity type for PEO users only.
                  if (cab.Label_Name__c == 'Marketing' && isPEOUser)	{
                    retValues.add(cab.Label_Name__c);                        
                  } else if (cab.Label_Name__c != 'Marketing') {
                	retValues.add(cab.Label_Name__c);
                  }

               }
            } // if (!isPEOUser || (isPEOUser
       } // for(Create_Activity_Button__c cab           
        
        return retValues;        
    } // getPicklistValues

     /*
      * SFDC-3404 (US3) 
      * 
      */
    @AuraEnabled
    public static Boolean isSelectedLabelValueEvent(String picklistName, String groupName, String labelName){
        System.debug('CreateActivityController::isSelectedLabelValueEvent, picklistName: ' + picklistName + ', groupName: ' + groupName + ', labelName: ' + labelName);
        List<Create_Activity_Button__c> picklistValues = [SELECT Is_Event__c FROM Create_Activity_Button__c 
                                       WHERE Picklist_Name__c = :picklistName AND Group_Name__c = :groupName AND Label_Name__c = :labelName];
        
        if(picklistValues.size() > 0)	{
            return picklistValues[0].Is_Event__c;
        }
        
        return false;
    }
     
    public class DataEnvelope {
        @AuraEnabled
        public SelectOptionWrapper[] options;
        @AuraEnabled
        public String profileName;

        public DataEnvelope(SelectOptionWrapper[] options, String profileName){
            this.options = options;
            this.profileName = profileName;
        }
    }
     
     @AuraEnabled
     public static Event getEventReminderDate(Event evt) {
         if(evt.ActivityDateTime > DateTime.now() && evt.IsReminderSet == true){
             evt.ReminderDateTime = evt.ActivityDateTime.addMinutes(-30);
         }
         return evt;
     } 
     
     @AuraEnabled
     public static Task getTaskReminderDate(Task tsk)
     {
         if(tsk.Status != 'Completed' && tsk.ActivityDate > Date.today() && tsk.IsReminderSet == true){
             tsk.ReminderDateTime = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(8,0,0,0));
         }
         return tsk;
     }  

}