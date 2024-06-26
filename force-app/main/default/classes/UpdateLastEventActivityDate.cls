/* Populate last activity dates on the Referral Account

Differences between last activity and last modified dates
https://help.salesforce.com/s/articleView?id=000326119&type=1

The date when a User last did something related to the record (represents one of the following):
The latest Due Date of the Closed Tasks on a record. 
The latest Start Date of Events on a record.

 * History
 * -------
  12/23/2021 Susmitha/Dan       Created
  04/06/2022 Dan Carmen         Update criteria to always check for closed tasks.

*/
public without sharing class UpdateLastEventActivityDate implements TriggerInterfaceC {
    
   public static final String CLASSNAME='UpdateLastEventActivityDate';

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      // recursion check
      SObject[] recs = TriggerMethods.checkRecs('UpdateLastEventActivityDate', p_recs,oldMap, isBefore, isAfter, isDelete, null, null);
      System.debug('UpdateLastEventActivityDate.handleTrigger recs='+recs.size());
      if (!recs.isEmpty() && isAfter) {
         if (TriggerMethods.objType == Event.sObjectType || TriggerMethods.objType == Task.sObjectType) {
            handleActivity(recs,oldMap);
         }
      } // if (!recs.isEmpty
   } // handleTrigger
    
   public static void handleActivity(SObject[] recs, Map<Id,SObject> oldMap) {
      Boolean hasRefCtct = false;
      // store both task and event dates here for the last activity date
      Map<Id,Date> activityDateMap = new Map<Id,Date>();
      // since we have to populate the separate event date field, store only event dates here
      Map<Id,Date> eventDateMap = new Map<Id,Date>();
      for (SObject rec : recs) {
         SObject oldRec = (oldMap != null ? oldMap.get(rec.Id) : null);
         Id whatId = (Id)rec.get('WhatId');
         Boolean isRefAcct = (whatId != null && whatId.getSobjectType() == Referral_Account__c.SObjectType);
         Boolean isRefCtct = (whatId != null && whatId.getSobjectType() == Referral_Contact__c.SObjectType);
         System.debug('handleActivity isRefAcct='+isRefAcct+' isRefCtct='+isRefCtct);
         if (isRefAcct || isRefCtct) {
            // keep track if we have a referral contact so we only query if we need to
            hasRefCtct = (hasRefCtct || isRefCtct);
            Boolean isEvent = (rec.getSObjectType() == Event.SObjectType);
            Boolean isTask = (rec.getSObjectType() == Task.SObjectType);
            // events always considered closed, tasks check the flag
            Boolean isClosed = (isTask ? (Boolean)rec.get('IsClosed') : true);
            // see if the closed flag changed 
            Boolean closedChanged = (isTask && isClosed && (oldRec == null || (Boolean)oldRec.get('IsClosed')==false));
            Boolean dateChanged = (rec.get('ActivityDate') != null && (oldRec == null || (oldRec != null && rec.get('ActivityDate') != oldRec.get('ActivityDate'))));
            System.debug('handleActivity isEvent='+isEvent+' isTask='+isTask+' isClosed='+isClosed+' closedChanged='+closedChanged+' dateChanged='+dateChanged);
            // check to see if it's new or the activity date changed.
            if (isClosed && (isTask || closedChanged || dateChanged)) {
               Date activityDate = (Date)rec.get('ActivityDate');
               checkAddDate(whatId, activityDate, activityDateMap);
               // also add to this map if event
               if (isEvent) {
                  checkAddDate(whatId, activityDate, eventDateMap);
               }
            } // if (isClosed &&
         } // if (isRefAcct || isRefCtct
         
      } // for (SObject rec
       
      System.debug('handleActivity activityDateMap='+activityDateMap.size());
      if (!activityDateMap.isEmpty()) {
         if (hasRefCtct) {
            handleRefCtcts(activityDateMap, eventDateMap);
         }
         // update the referral accounts here
         Referral_Account__c[] refAccts = [Select Id, Name, Last_Activity_Date__c, Last_Event_Date__c from Referral_Account__c where Id in :activityDateMap.keySet()];
         System.debug('handleActivity refAccts='+refAccts.size());
         // use a map so we don't add to the list more than once
         Map<Id,Referral_Account__c> updateMap = new Map<Id,Referral_Account__c>();
         for (Referral_Account__c refAcct : refAccts) {
            Date actDate = activityDateMap.get(refAcct.Id);
            Date eventDate = eventDateMap.get(refAcct.Id);
            System.debug('handleActivity actDate='+actDate+' eventDate='+eventDate+' refAcct='+refAcct);
            if (actDate != null && (refAcct.Last_Activity_Date__c == null || actDate > refAcct.Last_Activity_Date__c)) {
               refAcct.Last_Activity_Date__c=actDate;
               updateMap.put(refAcct.Id,refAcct);
            }
            if (eventDate != null && (refAcct.Last_Event_Date__c == null || eventDate > refAcct.Last_Event_Date__c)) {
               refAcct.Last_Event_Date__c=eventDate;
               updateMap.put(refAcct.Id,refAcct);
            }
         } // for (Referral_Account__c refAcct
         System.debug('handleActivity updateMap='+updateMap.size());
         if (!updateMap.isEmpty()) {
            // we don't need the triggers to fire
            ReferralAccountMethods.SKIP_TRIGGERS=true;
            DmlHelper.performDML2(updateMap.values(), DmlHelper.DML_UPDATE, CLASSNAME, 'handleActivity', 'Update Referral Accounts', true);
         }
      } // if (!activityDateMap
   } // handleActivity
    
   // find the referral account ids for the contacts
   public static void handleRefCtcts(Map<Id,Date> activityDateMap, Map<Id,Date> eventDateMap) {
      // select the referral contacts to get the referral account ids
      Referral_Contact__c[] refCtcts = [Select Id, Name, Referral_Account__c from Referral_Contact__c where id in :activityDateMap.keySet() and Referral_Account__c != null];
      for (Referral_Contact__c refCtct : refCtcts) {
         // add the date to the map based on the referral account id
         checkAddDate(refCtct.Referral_Account__c, activityDateMap.get(refCtct.Id), activityDateMap);
         // if it's an event, update that map too
         if (eventDateMap.containsKey(refCtct.Id)) {
            checkAddDate(refCtct.Referral_Account__c, eventDateMap.get(refCtct.Id), eventDateMap);
         }
      } // for (Referral_Contact__c
   } // handleRefCtcts
    
   public static void checkAddDate(Id whatId, Date checkDate, Map<Id,Date> dateMap) {
      // only store the latest date for a what id here
      Date mapDate = dateMap.get(whatId);
      if (checkDate != null && (mapDate == null || checkDate > mapDate)) {
         dateMap.put(whatId,checkDate);
      }
   } // checkAddDate

} // class UpdateLastEventActivityDate