/* 

History
-------
12/19/2019 Brandon Vidro    Created
02/10/2020 Brandon Vidro    Added counter for update
08/27/2020 Michael Karcz    Added SetDefaultType to default the "Presentation - Initial" Type value on Events
10/22/2020 Dan Carmen       Clean up event logic
01/04/2020 Pradeep Garlapaati  Change event type for TimeTrade from opportunity. 
03/26/2021 Jacob Hinds       Adding RJMethods call
11/18/2022 Rohit Ranjan    Added method to populate Appointment Type field from Referral Contact to Event

*/
public with sharing class EventCheckData {
    
    public static Boolean INSERT_TRIGGER_PROCESSED=false;   
    public static Boolean UPDATE_TRIGGER_PROCESSED=false;
    public static Integer TRIGGER_FIRED_COUNTER=0;
          set<id> evtids = new set<id>();
    public set<id> evnt_oppids = new set<id>();
    
   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      Event[] evnts = (Event[])recs;
      Event[] oppEvnts = new Event[]{};
      Set<Id> ownerIds = new Set<Id>();
  
      
      for (Event evt : (Event[])recs) {
         Event oldEvt = (oldMap != null ? (Event)oldMap.get(evt.Id) : null);
         String whatId = (String)evt.WhatId;
         // only for events linked to an opportunity and it's new or the type or whatid changes
         if (evt.WhatId != null && whatId.startsWith('006') && (oldEvt == null || evt.Type != oldEvt.Type || evt.WhatId != oldEvt.WhatId)) {
            Id ownerId = (evt.OwnerId != null ? evt.OwnerId : UserInfo.getUserId());
            oppEvnts.add(evt);
            ownerIds.add(ownerId);
         }
         if (whatId != null && whatId.startsWith('a07') && (evt.Referral_Contact__c == null || evt.Referral_Contact__c != evt.WhatId)) {
            evt.Referral_Contact__c = evt.WhatId;
         }
         
      } // for (Event evt
       if(isBefore && !isDelete){
         RJMethods.checkOACFieldChange(recs,oldMap);
      }
       
        //Code to Change event type to Demo for TT
        Event[] TToppEvnts = new Event[]{};
        Set<Id> refContIds = new Set<Id>();
        if(isBefore && Trigger.isInsert)
        {
            for (Event evt : (Event[])recs) {
                String evtwhatId = (String)evt.WhatId;
                if(evt.WhatId != null && (evtwhatId.startsWith('006') || evtwhatId.startsWith('a07')) && evt.TimeTrade_SF1__Invitation__c != null)
                {
                    TToppEvnts.add(evt);
                    if(evtwhatId.startsWith('006')){
                        evnt_oppids.add(evt.WhatId);
                    }else if(evtwhatId.startsWith('a07')){
                        refContIds.add(evt.WhatId);
                    }
                    
                }               
            }
            if(!evnt_oppids.isEmpty())
            	UpdateEventTypeForSETimeTrade(TToppEvnts,evnt_oppids);
            
            if(!refContIds.isEmpty()){
                UpdateEventTypeForReferralContact(TToppEvnts,refContIds);
            }
                  
        }
        

       // don't need to proceed here
      if (ownerIds.isEmpty()) {
         return;
      }
      // get the owners
      Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, Sales_Org__c from User where Id in :ownerIds]);
      // check the events that are being marked as initial presentations
      Event[] initalPresEvnts = new Event[]{};
      // the opportunity ids we need to check
      Id[] oppIds = new Id[]{};
      // the ids of existing events so we don't reselect them
      Id[] evntIds = new Id[]{};

      for (Event evt : oppEvnts) {
         Event oldEvt = (oldMap != null ? (Event)oldMap.get(evt.Id) : null);
         Id ownerId = (evt.OwnerId != null ? evt.OwnerId : UserInfo.getUserId());
         User usr = userMap.get(ownerId);
         // get the custom setting for that instance.
         SalesOrg__c socs = (usr != null && usr.Sales_Org__c != null ? SalesOrg__c.getInstance(usr.Sales_Org__c) : null);
         System.debug('EventCheckData.handleTrigger evt.Type='+evt.Type+' socs='+socs);
         evt.Initial_Presentation__c = (socs != null && String.isNotBlank(evt.Type) && evt.Type == socs.IEUP_Type__c);
         System.debug('EventCheckData.handleTrigger evt.Initial_Presentation__c='+evt.Initial_Presentation__c);
         if (evt.Initial_Presentation__c) {
            initalPresEvnts.add(evt);
            oppIds.add(evt.WhatId);
            if (evt.Id != null) {
               evntIds.add(evt.id);
            }
         }
      } // for (Event evt
       
      if (!initalPresEvnts.isEmpty()) {
         checkForExistingPresentations(initalPresEvnts, oppIds, evntIds);
      }       
   } // handleTrigger
    
    
  public static void UpdateEventTypeForSETimeTrade(Event[] evnts,set<id> evt_oppids) {
        if(evt_oppids!=null && !evt_oppids.isEmpty()){
            map<id,opportunity> oppMap = new map<id,opportunity>([select id,type__c from opportunity where id in : evt_oppids]);
            if(oppMap!=null && !oppMap.isEmpty()){
                for (Event evt : evnts) {
                    System.debug('evt = '+oppMap.get(evt.WhatId).type__c);
                    if(oppMap.get(evt.WhatId).type__c != null)
                    {
                        evt.Appointment_Type__c = oppMap.get(evt.WhatId).type__c;
                    }
                }
            }
        }
        
    }
    
    
    // update Appointment Type for Referral Contact - Rohit
    public static void UpdateEventTypeForReferralContact(Event[] evnts,Set<id> evt_refContIds) {
        if(evt_refContIds!=null && !evt_refContIds.isEmpty()){
            Map<id,Referral_Contact__c> refContactMap = new Map<id,Referral_Contact__c>([Select Id,type__c from 
                                                               Referral_Contact__c where id in : evt_refContIds]);
            System.debug('evt refContactMap = '+refContactMap);
            if(refContactMap!=null && !refContactMap.isEmpty()){
                for (Event evt : evnts) {
                    if(refContactMap.get(evt.WhatId).type__c != null)
                    {
                        evt.Appointment_Type__c = refContactMap.get(evt.WhatId).type__c;
                    }
                }
            }
        }
    }     
    
    
     public static void checkForExistingPresentations(Event[] evnts, Id[] oppIds, Id[] evntIds) {
      // select the existing events
      Event[] checkEvents = [Select Id, Type, Meeting_Not_Held__c, WhatId 
                               from Event 
                              where Meeting_Not_Held__c=false 
                                and Initial_Presentation__c=true
                                and WhatId in :oppIds
                                and Id not in :evntIds];
      // create a map of opp ids that already have an initial presentaion
      Map<Id,Event> oppsWithInitialMap = new Map<Id,Event>();
      for (Event evnt : checkEvents) {
         oppsWithInitialMap.put(evnt.WhatId,evnt);
      }
      for (Event evnt : evnts) {
          if (oppsWithInitialMap.containsKey(evnt.WhatId)) {
             evnt.addError('An initial Presentation already exists on this Opportunity. Please select a different meeting type or create a new Opportunity to log a new Initial Presentation.');
          }
      } // for (Event evnt
   } // checkForExistingPresentations

} // class EventCheckData