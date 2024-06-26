/* 
 * If the event has a certain type, update a related field on another object.
 *
 * History
 * -------
 * 03/23/2010 Dan Carmen   Created
 * 09/30/2010 Dan Carmen   Modified criteria for trigger to make sure only enters when necessary.
 * 08/25/2011 Dan Carmen   Added Explore Paychex 2
 * 09/10/2015 Cindy Freeman   Added logic to update Hold Out expiration date if Initial Presentation
 * 12/09/2015 Cindy Freeman   fixed error thrown if user creates event from calendar and whoId and whatId are both blank 
 * 11/30/2017 Jake Hinds    Commenting out ESR 
 * 02/26/2018 Cindy Freeman   if new event is linked to an opty, recalc Number of Events on opty
 * 07/30/2018 Cindy Freeman	  get rid of null pointer error on line 57,64 if Event has 'master' record type
 * 12/21/2020 Pradeep Garlapaati	  Added logic that creates a new opportunity team member when a event is created for opportunity from Time trade. 
 * 01/18/2020 Pradeep Garlapaati  Wrote logic to renew oppty TeamMember demoed date. 
   03/06/2024 Dan Carmen          Adjust delete logic to only fire for events within the past 6 months.

 */
trigger EventCheckType on Event (after insert, after update, after delete) {

   // set of events that need Hold out checked
   List<Id> idEventList = new List<Id>();

   //ids of opportunities attached to events inserted,updated and deleted
   Map<Id,Id> optyIdByInsertEventId = new Map<Id,Id>();
   Map<Id,Id> optyIdByUpdateEventId = new Map<Id,Id>();
   Map<Id,Id> optyIdByDeleteEventId = new Map<Id,Id>();
   set<id> 	CreateTimeTradeOTM = new set<id>();
   set<id> 	CreateTimeTradeOTMOpptIds = new set<id>();
   set<id> 	EventOwnerIdsToCreateOTM = new set<id>();
   set<id> 	EventOwneridsToUpdateDemoDate = new set<id>();
   set<id> 	EventIdsWithDemoType = new set<id>();
    set<id> 	OpptyIdsWithDemoEvents = new set<id>();
 
   List<Event> 	EventListToUpdateDemoDate = new List<Event>();
   List<Event> driftMeetings = new List<Event>();
   //Set<Id> esrEventIDSet = new Set<Id>();
   //id esrCalendarID = [select id from User where isActive = TRUE and name = :Label.ESR_User limit 1].id;   
   // get the prefix of the Referral_Contact__c object
   Schema.DescribeSObjectResult dor = Referral_Contact__c.sObjectType.getDescribe();
   String refCtctPrefix = dor.getKeyPrefix();
   System.debug('refCtctPrefix='+refCtctPrefix);

   TriggerMethods.checkBeforeLoop('EventCheckType', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

   Event[] evnts = new Event[]{};
   if(!Trigger.isDelete){
               String[] ActivityTypesRenewOpptyTeamDemoDate = Label.RenewOpptyTeamDemoDateWhenActivityTypesCreated.split(',');
   		for ( Event newEvt: Trigger.new) {
	      Event oldEvt = (Trigger.isUpdate ? Trigger.oldMap.get(newEvt.Id) : null);
	
	      TriggerMethods.checkInLoop('EventCheckType', newEvt, oldEvt, Trigger.IsBefore, Trigger.IsAfter);
	      // only for Events where the Type=Explore Paychex
	      if ((newEvt.Type == 'Explore Paychex' || newEvt.Type == 'Explore Paychex 2') &&
	          (newEvt.WhatId != null && ((String)newEvt.WhatId).startsWith(refCtctPrefix))) {
	         if (Trigger.isInsert) {
	            // always fire for insert
	            evnts.add(newEvt);
	         } else if (Trigger.isUpdate) {
	            // only send it through if the date changes, or if the type was not explore paychex and it is now.
	            if ((newEvt.ActivityDate != oldEvt.ActivityDate) ||
	                (newEvt.Type != oldEvt.Type)) {
	               evnts.add(newEvt);
	            } // if ((newEvt))
	         } // if (Trigger
	      } // if (newEvt.Type
	        
	      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordTypeById(newEvt.RecordTypeId, 'Event');
	      if (Trigger.isInsert && rtInfo != null && rtInfo.getName()== RecordTypeHelper.CORE_EVENT 
	          && newEvt.Type != null && newEvt.Type.startsWith('Presentation - Initial') )
	      {   if (newEvt.WhoId != null || newEvt.WhatId != null)  
	          {   idEventList.add(newEvt.WhoId == null ? newEvt.WhatId : newEvt.WhoId);     }
	      }
	      
	      if (Trigger.isInsert && newEvt.WhatId != null && String.valueOf(newEvt.WhatId).Left(3) == '006'){ 
	      	  optyIdByInsertEventId.put(newEvt.Id,newEvt.WhatId);     
 	      } 

	      if (Trigger.isInsert && newEvt.WhatId != null && String.valueOf(newEvt.WhatId).Left(3) == '006' && ActivityTypesRenewOpptyTeamDemoDate.contains( newEvt.Appointment_Type__c)){ 
                	 EventOwneridsToUpdateDemoDate.add(newEvt.ownerid);   
                	 EventListToUpdateDemoDate.add(newEvt);  
	      } 
            
	      if (Trigger.isUpdate && newEvt.WhatId != null && String.valueOf(newEvt.WhatId).Left(3) == '006' 
	      		&& rtInfo != null && rtInfo.getName()== RecordTypeHelper.CORE_EVENT && newEvt.Outcome__c != oldEvt.Outcome__c
	      		&& newEvt.Type.startsWith('Presentation - Initial')){
	      	  optyIdByUpdateEventId.put(newEvt.Id,newEvt.WhatId);
	      }
         //creating a new opportunity team member when a event is created for opportunity from Time trade.          
            if(Trigger.IsAfter && Trigger.isInsert && newEvt.WhatId != null && String.valueOf(newEvt.WhatId).Left(3) == '006' && newEvt.TimeTrade_SF1__Invitation__c != null)
            { 
               	 CreateTimeTradeOTM.add(newEvt.Id);  
               	 EventOwnerIdsToCreateOTM.add(newEvt.OwnerId);  
                CreateTimeTradeOTMOpptIds.add(newEvt.whatid);
              //  if(newEvt.Appointment_Type__c == 'Demo') OpptyIdsWithDemoEvents.add(newEvt.WhatId);
            }
            
            if(Trigger.IsAfter && Trigger.isInsert && newEvt.WhatId != null && (String.valueOf(newEvt.WhatId).Left(3) == '006' || String.valueOf(newEvt.WhatId).Left(3) == 'a07') && newEvt.TimeTrade_SF1__Invitation__c != null && newEvt.Appointment_Type__c == 'Demo')
            { 
                System.debug('newEvt = '+newEvt);
                OpptyIdsWithDemoEvents.add(newEvt.WhatId);
                EventIdsWithDemoType.add(newEvt.id);
            }
            
          if(Trigger.IsAfter && Trigger.isInsert && newEvt.Subject != null && newEvt.Subject == Label.Drift_Event_Subject){
               driftMeetings.add(newEvt);
          }
	   } // for ( (Event))
   }
   //trigger is delete
   else{
       // only fire for events within the past 6 months
       Date checkDate = Date.today().addMonths(-6);
   		for ( Event oldEvt: Trigger.old) {
   			if (oldEvt.WhatId != null && String.valueOf(oldEvt.WhatId).Left(3) == '006' && oldEvt.ActivityDate > checkDate){
	      	  optyIdByDeleteEventId.put(oldEvt.Id,oldEvt.WhatId);
	      }
   		}
   }
   
    
    TriggerMethods.checkOutsideLoop('EventCheckType', Trigger.isBefore, Trigger.isAfter);

   if (!evnts.isEmpty()) {
      EventCheckType.procesExplorePayx(evnts);
   } // if (!evnts.isEmpty
   
   if (!idEventList.isEmpty()) 
   {    HoldOutExpirationMethods.reviseTaskExpiration(idEventList); }
   if(!driftMeetings.isEmpty()) {
        EventCheckType.createOrphanEventRecord(driftMeetings);
   }
   if (!optyIdByInsertEventId.isEmpty())
   {    EventCheckType.procesOptyEvtCreateDelete(optyIdByInsertEventId,false);   }
   
   if (!optyIdByUpdateEventId.isEmpty())
   {    EventCheckType.procesOptyEvtUpdate(optyIdByUpdateEventId);   }
   
   if (!optyIdByDeleteEventId.isEmpty())
   {    EventCheckType.procesOptyEvtCreateDelete(optyIdByDeleteEventId,true);   }
   
  if(!CreateTimeTradeOTM.isEmpty()) 
   {	EventCheckType.CreateOpportunityTeamMemberTT(CreateTimeTradeOTM,EventOwnerIdsToCreateOTM); 	}
   
  if(!EventIdsWithDemoType.isEmpty()) 
   {	
       EventCheckType.ChatterPostToRemindPreCallTT(EventIdsWithDemoType,OpptyIdsWithDemoEvents);
   }
  
    

    if(!EventOwneridsToUpdateDemoDate.isEmpty()) 
   {	EventCheckType.UpdateSEDemoDateOnOppyTeamMember(EventOwneridsToUpdateDemoDate,EventListToUpdateDemoDate); 	}
} // trigger EventCheckType