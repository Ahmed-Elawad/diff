/* 
 * Creates a Sales Engineer Tracker record for each Demo created for MMS Event Record Type by sales engineers
 * History
 * -------
 * 12/17/2018 Michael Karcz         created
   03/28/2019 Dan Carmen            Modify to make sure only creating the Sales_Engineer_Tracker__c with the correct record

 */
 
public with sharing class EventCreateObject implements TriggerInterface2{

    // check all of the records as a group before cycling through them individually
   public void triggerCheckAllFirst(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter) {
       
        if(isAfter) {
           
           Map<Id,Event> eventByOppIdMap = new Map<Id,Event>();
            
            List<Sales_Engineer_Tracker__c> SETrackerList = new List<Sales_Engineer_Tracker__c>();
            
            Schema.RecordTypeInfo mmsRt = RecordTypeHelper.getRecordType(Label.MMS_Event_Record_Type, 'Event');
            
            // Create a list of the opportunity Ids of the oppts that the events were created from
            List<Id> oppIds = new List<Id>();
            for(SObject so : recs) {
                Event e = (Event)so;
                String idString = (String)e.WhatId;
                
                // Confirm that the event was actually made from an opportunity before adding it to the list
                if(idString.StartsWith(Opportunity.sObjectType.getDescribe().getKeyPrefix())) {
                   eventByOppIdMap.put(e.WhatId, e);
                    oppIds.add(e.WhatId);
                }
            } // for
            
            if (!eventByOppIdMap.isEmpty()) {
            // Grab the actual opportunities
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, AccountId FROM Opportunity WHERE Id in :eventByOppIdMap.keySet()]);
            
            for (Event e : eventByOppIdMap.values()) {
                   Opportunity opp = oppMap.get(e.WhatId);
                   
                if(opp != null && (e.Appointment_Type__c == 'Demo' && (UserHelper.getRunningUser().Profile.Name == 'Sales Engineer' || UserHelper.getRunningUser().Profile.Name == 'System Administrator'))) {
                    
                    // Create the new Sales Engineer Tracker object
                    Sales_Engineer_Tracker__c seTracker = new Sales_Engineer_Tracker__c(
                        Opportunity_Lookup__c = e.WhatId,
                        Prospect_Client_Lookup__c = (opp != null ? opp.AccountId : null),
                        Event_Id__c = e.Id,
                        Type__c = 'Issue',
                        Demo_Start_Time__c = e.StartDateTime,
                        Demo_End_Time__c = e.EndDateTime
                    ); // new Sales Engineer Tracker object
                    SETrackerList.add(seTracker);
                } // if
            } // for
            
            
            DmlHelper.performDML2(SETrackerList, 'Upsert', 'EventCreateObject', 'triggerCheckAllFirst', 'Upserting SE Tracker Objects', true);

            } // if (!eventByOppIdMap.isEmpty
            
            //if(!SETrackerList.isEmpty()) Database.upsert(SETrackerList,Sales_Engineer_Tracker__c.Fields.Event_Id__c, false);
            // if(!SETrackerList.isEmpty()) upsert SETrackerList;
            
        } // if(isAfter)
   } // triggerCheckAllFirst

   public void triggerCheckRec(SObject newRec, SObject oldRec, Boolean isBefore, Boolean isAfter) {}
   public void triggerCheckActions(Boolean isBefore, Boolean isAfter) {}

}