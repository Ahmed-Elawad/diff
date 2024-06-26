/* 
 * Set an alert on the cases.
 *
 * History
 * -------
 * 07/01/2010 Dan Carmen   Created from setAlertTimeStamp trigger
 * 02/17/2011 Dan Carmen   Modifications to prevent exception from occurring. Added test methods.
   10/26/2018 Dan Carmen   Set API version to 44
   12/09/2021 Jake Hinds   Removing supervisor alert checkbox

 */
public with sharing class CaseSetAlertTimeStamp {
    
    public static final String SERVICE_PREMIER_RT='Service Premier Record Type';
    
   public static void setAlerts(Case[] cases, Id[] ownerIds, Boolean isInsert) {
      // get all of the Users
      Map<Id, User> userMap = new Map<Id, User>([select u.Id, u.ManagerId
                                                       ,u.Manager.ManagerId 
                                                   from User u where Id in :ownerIds ]);
      // get the RecordType for 'Service Premier Record Type'
      Schema.RecordTypeInfo rt = RecordTypeHelper.getCaseRecordTypeInfo(SERVICE_PREMIER_RT);
      Id servicePremierRtId = (rt != null ? rt.getRecordTypeId() : null);
      // get the default business hours
      BusinessHours bh = [select id from businesshours where IsDefault=true];
      
      /*
      List<Case> cases = new List<Case>([select Id, OwnerId, BusinesshoursId
                                                       ,CaseNumber
                                                       ,IsClosed
                                                       ,RecordTypeId
                                                       ,RecordType.Name
                                                       ,SupervisorAlert__c, level1alertduration__c
                                                       ,level2alertduration__c, level1AlertDateTime__c
                                                       ,level2AlertDateTime__c, LastModifiedDate 
                                                   from Case where id in :caseIds
                                                    and IsClosed = false]);
      */
                                                   
      //Loop through each case being processed
      for (case currentcase : cases) {
         //Trigger should only process open cases with populated Alert durations
         //Commented out on 5/29/09
         //if ((!currentcase.isClosed) && (currentCase.level1AlertDuration__c != null) && (currentCase.level2AlertDuration__c != null))
         //Added on 5/29/09
         //Find out 2 levels of Supervisors to be alerted
         System.debug ('alert for case: '+currentcase.CaseNumber+ ' owner: '+currentCase.OwnerId);
            
         //Get user record for the current cases owner
         User currUser = userMap.get(currentcase.OwnerId);
            
         //Only process if user record is found
         if (currUser != null) {
            System.debug('ownerid: '+currentcase.ownerid + 'owner manager: ' + currUser.ManagerId);
        
            //Add Alert Hours to LastModifiedTime
            //commented out on 5/29/09
            //DateTime level1AlertDT = BusinessHours.add (currentcase.businesshoursid, currentcase.LastModifiedDate, currentcase.level1alertduration__c.intValue() * 60 * 60 * 1000L);
            //DateTime level2AlertDT = BusinessHours.add (currentcase.businesshoursid, currentcase.LastModifiedDate, currentcase.level2alertduration__c.intValue() * 60 * 60 * 1000L);
                
            //added on 5/29/09
            DateTime level1AlertDT = null;
            
            Id busHoursId = (currentcase.businesshoursid != null ? currentcase.businesshoursid : (bh != null ? bh.Id : null));
            
            //if (currentCase.RecordTypeId != null && currentCase.RecordType.Name == 'Service Premier Record Type') {        
            if (currentCase.RecordTypeId == servicePremierRtId && busHoursId != null) {        
               level1AlertDT = BusinessHours.add ((bh != null ? bh.Id : currentcase.businesshoursid), (isInsert ? DateTime.now() : currentcase.LastModifiedDate), 5 * 24* 60 * 60 * 1000L);
            } 
                
            DateTime level2AlertDT = null;
                    
            //Set supervisors
            currentcase.User_Level_1_Supervisor__c = currUser.ManagerId;
            currentcase.User_Level_2_Supervisor__c = currUser.Manager.ManagerId;
                
            //Update Alert DateTimes
            currentcase.level1AlertDateTime__c = level1AlertDT;
            currentcase.level2AlertDateTime__c = level2AlertDT;
                    
         } // if (currUser != null
      } // for (case currentcase
      //update cases;
   } // setAlerts

} // class CaseSetAlertTimeStamp