/* 
 * If the event has a certain type, update a related field on another object.
 *
 * History
 * -------
 * 03/23/2010 Dan Carmen   Created
 * 09/30/2010 Dan Carmen   Modified to attempt to catch exceptions.
   08/25/2011 Dan Carmen   Added Explore Paychex 2
   02/26/2018 Cindy Freeman     Added method to update Number of Events on opty
   04/04/2018 Jake Hinds   adding to method to update opportunity
   07/25/2018 Dan Carmen   Don't update the opportunity from the event if the opp is NSS Inbound
   10/09/2019 Dan Carmen   Look for NSS Source starts with Inbound
   01/10/2020 Brandon Vidro Added logic for setting IEUP_Date__c
   04/13/2021 Brandon Vidro Added method to create Task Orphan record for Drift Events
   04/17/2021 Dan Carmen    Changed call to queryActivityEmailMap
   05/18/2021 Carrie Marciano updated StageNames with OppStage labels
   12/30/2022 Rohit Ranjan Modified ChatterPostToRemindPreCallTT to work for Referral Contact based on record prefix
   03/06/2024 Dan Carmen      Update updateOppEvtCreateDelete to only select open opps

 */
public without sharing class EventCheckType {

   /** For the passed in Events, update the Referral Contacts attached to them.
    */
   public static void procesExplorePayx(Event[] evnts) {
      Map<Id,Id> referralIdMap = new Map<Id,Id>();
      for (Event evnt : evnts) {
         referralIdMap.put(evnt.WhatId,evnt.WhatId);
      } // for (Event
      
      // only proceed if referral ids were found.
      if (!referralIdMap.isEmpty()) {
         // get the referral contacts
         Map<Id,Referral_Contact__c> ctcts = new Map<Id,Referral_Contact__c>([
                          Select Id
                                ,Explore_Date__c
                                ,Explore_2_Date__c
                            from Referral_Contact__c 
                           where Id in :referralIdMap.values()]);
      
         // the referral contacts to update
         Map<Id,Referral_Contact__c> updateCtcts = new Map<Id,Referral_Contact__c>();
      
         for (Event evnt : evnts) {
            if (evnt.WhatId != null) {
               Referral_Contact__c rc = ctcts.get(evnt.WhatId);
               if (rc != null) {
                  if (evnt.Type == 'Explore Paychex') {
                     rc.Explore_Date__c = evnt.ActivityDate;
                  } else if (evnt.Type == 'Explore Paychex 2') {
                     rc.Explore_2_Date__c = evnt.ActivityDate;
                  }
                  if (!updateCtcts.containsKey(rc.Id)) {
                     updateCtcts.put(rc.Id,rc);
                  }
               } // if (rc != null
            } // if 
         } // for
      
         if (!updateCtcts.isEmpty()) {
            try {
               update updateCtcts.values();
            } catch (Exception e) {
               // if only one event, attach the error
               if (evnts.size() == 1) {
                  String msg = 'Error while attempting to update the Referral Contact: ';
                  msg += e.getMessage();
                  evnts[0].addError(msg);
               }
            }
         }
      } // if (!referralIds.isEmpty
   } // processExplorePayx
    //Pradeep - Code Start to capture demo date for SE 
    
       public static void UpdateSEDemoDateOnOppyTeamMember(set<id> EventOwneridsToUpdateDemoDate,List<Event> EventListToUpdateDemoDate) {
     map<id,user> OwneridsUserMap = new map<id,user>([Select id,profileid, profile.name from user where id IN : EventOwneridsToUpdateDemoDate]);
     map<id,list<event>> OpptyIdByEvent = new map<id,list<event>>();
    set<id> Evt_OppyIdsToUpdateDemodate = new set<id>();
      String[] SalesEngineerLabel = Label.SalesEngineerLabelToUpdateDemoDateAndCreateOpptyTeamMem.split(',');
           for(Event ev : EventListToUpdateDemoDate)
           {
                if(SalesEngineerLabel.contains(OwneridsUserMap.get(ev.ownerid).profile.name))//Check if owner's profile is SalesEngineer
                {
                   Evt_OppyIdsToUpdateDemodate.add(ev.WhatId);
               
               //Logic to put data into  map<id,list<event>> OpptyIdByEvent
               if(OpptyIdByEvent.containsKey(ev.WhatId)) {
                 List<event> evtList = OpptyIdByEvent.get(ev.whatid);
                 evtList.add(ev);
                 OpptyIdByEvent.put(ev.WhatId, evtList);
               }
             
             else {
                 OpptyIdByEvent.put(ev.WhatId, new List<event> { ev });
             }
               
                }
           }
         System.debug(' Evt_OppyIdsToUpdateDemodate = '+Evt_OppyIdsToUpdateDemodate);
           if(Evt_OppyIdsToUpdateDemodate.size()>0)
           {
               List<OpportunityTeamMember> teamMemberList = new List<OpportunityTeamMember>();
               List<OpportunityTeamMember> teamMemberListToUpdate = new List<OpportunityTeamMember>();
               String[] teamRoles = Label.OppyTeamMemberToKeepWhenOwnerChanged.split(',');
               System.debug(' teamRoles = '+teamRoles);
               teamMemberList = [select id,userid,TeamMemberRole,demo_date__c,OpportunityId from OpportunityTeamMember where opportunityid =: Evt_OppyIdsToUpdateDemodate AND TeamMemberRole IN : teamRoles AND userid IN : EventOwneridsToUpdateDemoDate];
               System.debug(' teamMemberList = '+teamMemberList);
               for(OpportunityTeamMember OTM: teamMemberList) 
               {
                         date tempinputDate;
                       for(event evt : OpptyIdByEvent.get(otm.OpportunityId))
                       {
                           if(evt.OwnerId == otm.UserId) tempinputDate = evt.CreatedDate.date();//get event's created date and assign it to team member demo date
                       }
                       if(tempinputDate != null)
                       {
                           String inputDate =tempinputDate.addYears(1).format(); 
                           OTM.demo_date__c =  date.parse(inputDate);
                           teamMemberListToUpdate.add(OTM);
                       }
                }
               if(teamMemberListToUpdate.size()>0) 
               {
                   DmlHelper.performDML2(teamMemberListToUpdate, DmlHelper.DML_UPDATE, 'EventCheckType', 'UpdateSEDemoDateOnOppyTeamMember', 'Update Demo date on OpptyTeam', true);
                   //update teamMemberListToUpdate;
               }
           }
       }
    
    @future
  public static void CreateOpportunityTeamMemberTT(set<id> evntids,set<id> EventOwnerIds) {
       system.debug('evntids = '+evntids);     
     map<id,user> OwneridsUserMap = new map<id,user>([Select id,profileid, profile.name from user where id IN : EventOwnerIds]);
      List<OpportunityTeamMember> teamMemberListToInsert = new List<OpportunityTeamMember>();
       list<Event> evnts = new list<Event>();
       evnts = [select id,ownerid,whatid,TimeTrade_SF1__Invitation__c from event where id IN :evntids];
      String[] SalesEngineerLabel = Label.SalesEngineerLabelToUpdateDemoDateAndCreateOpptyTeamMem.split(',');
       for (Event evt : evnts) {
           if(OwneridsUserMap.containsKey(evt.OwnerId) && SalesEngineerLabel.contains(OwneridsUserMap.get(evt.OwnerId).profile.name))
           {
               OpportunityTeamMember myTeamMember = new OpportunityTeamMember();
               myTeamMember.OpportunityId = evt.whatid;
               myTeamMember.TeamMemberRole = Label.TeamMemberRoleToCreateForTT;
               myTeamMember.UserId = evt.OwnerId;            
               
               teamMemberListToInsert.add(myTeamMember);
           }
       }
       system.debug('teamMemberListToInsert = '+teamMemberListToInsert);         
       if(teamMemberListToInsert.size()>0)    
         DmlHelper.performDML2(teamMemberListToInsert, DmlHelper.DML_INSERT, 'EventCheckType', 'CreateOpportunityTeamMemberTT', 'Inserting oppty TeamMmebers', true);

     }    
    @future
      public static void ChatterPostToRemindPreCallTT(set<id> evntids,set<id> idsWithDemoEvents)
    {
       // map<id,Event> opptyToEvents = new map<id,Event>();
        set<id> idWithPreDemo = new set<id>();
        map<id,Event> idToEvent = new map<id,Event>();
        //BAU Changes
      //  Map<Id,Id> mapOppidownerId= new Map<Id,Id>();//getOpportunityOwner(idsWithDemoEvents);
     //   Map<Id,Id> mapRCidownerId=new Map<Id,Id>();//getRefContactOwner(idsWithDemoEvents);
        Map<Id,Id> mapidownerId= new Map<Id,Id>();
        List<Opportunity> oppList = new List<Opportunity>();
        List<Referral_Contact__c> rcList = new List<Referral_Contact__c>();
        List<Id> oppIdList = new List<Id>();
        List<Id> rcIdList = new List<Id>();
        for(Id i:idsWithDemoEvents){
            if(String.valueOf(i).Left(3) == '006'){
                oppIdList.add(i);
            } else if(String.valueOf(i).Left(3) == 'a07'){
                rcIdList.add(i);
            }
        }
        if(oppIdList.size() >0){
            oppList =[Select Id,ownerid from Opportunity where Id In:oppIdList];
        } else if(rcIdList.size() >0){
            rcList=[Select Id,ownerid from Referral_Contact__c where Id In:rcIdList];
        }
         System.debug('Test idsWithDemoEvents='+idsWithDemoEvents);
        System.debug('Test rcList='+rcList);
        if(oppList.size()>0 && oppList != null){
            for(Opportunity op:oppList){
                mapidownerId.put(op.Id,op.ownerId);
            }
        }
        if(rcList.size()>0 && rcList != null){
            for(Referral_Contact__c rc:rcList){
                mapidownerId.put(rc.Id,rc.ownerId);
            }
        }
        //BAU Changes
        System.debug('Test evntids='+evntids);
        System.debug('idsWithDemoEvents='+idsWithDemoEvents);
         System.debug('Test mapidownerId='+mapidownerId);
        for(Event ev : [select id,ownerid,whatid,TimeTrade_SF1__Invitation__c,Appointment_Type__c from event where whatid IN :idsWithDemoEvents])
        {
            System.debug(evntids.contains(ev.Id)+', ev = '+ev);
            if(evntids.contains(ev.Id))
                idToEvent.put(ev.whatid, ev);
            if(ev.Appointment_Type__c == 'Pre-Demo Strategy Call')
                idWithPreDemo.add(ev.WhatId);
        }
        if(idWithPreDemo.size()>0 && idsWithDemoEvents.size()>0)
        {
           
           idsWithDemoEvents.removeall(idWithPreDemo);
        }
        String TimeTradeUrlForChatterPost = Label.TimeTradeUrlForChatterPost;
        if(idsWithDemoEvents != null)
        {
            for(id ids : idsWithDemoEvents)
            {
                String postText = TimeTradeUrlForChatterPost+ids;
                list<id> userids = new list<id>();
                if(idToEvent.containsKey(ids)) 
                    userids.add(idToEvent.get(ids).ownerid);
                
                //BAU Changes
                userids.add(mapidownerId.get(ids));
                System.debug('userids='+userids);
                ChatterMentionPost.createChatterMentionPost(ids,userids ,  new String[]{ postText},true,false);
            }
            ChatterMentionPost.postBatchFeedElements(); 
        }
    }
   /* method to increment Number of Events count on opty if new Event is linked to the opty
   */ 
   public static void procesOptyEvtCreateDelete(Map<Id,Id> optyIdByEventId, Boolean isDelete)
   {    if (!Utilities.allowFuture() || Test.isRunningTest())
        {   
            updateOppEvtCreateDelete(optyIdByEventId,isDelete);
        }
        else
        {   updateOppEvtCreateDeleteFuture(optyIdByEventId,isDelete);   }
    
   } // procesOpty
   
   @future
   public static void updateOppEvtCreateDeleteFuture(Map<Id,Id> optyIdByEventId,Boolean isDelete)
   {    
       updateOppEvtCreateDelete(optyIdByEventId,isDelete);
   }
      
   public static void updateOppEvtCreateDelete(Map<Id,Id> optyIdByEventId,Boolean isDelete)
   {    
        //Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Id,Number_of_Events__c,StageName,Probability,ForecastCategoryName,RecordTypeId,RecordType.Name FROM Opportunity WHERE id in:optyIdSet]);
        // only select open opportunities
        Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Id,Number_of_Events__c,StageName,Probability,ForecastCategoryName,RecordTypeId,RecordType.Name, IEUP_Date__c 
                                                                       ,NSS_Source__c
                                                                   FROM Opportunity 
                                                                  WHERE isClosed=false and id in:optyIdByEventId.values()]);
        //get all events related to opportunity to increment Opportunity Number of Events
        //List<Event> evntList = [select Id, whatId, IsRecurrence, Type,RecordTypeId from Event where WhatId in :optyIdSet order by WhatId];
        List<Event> evntList = [select Id, whatId, IsRecurrence, Type,RecordTypeId,RecordType.Name, Meeting_Not_Held__c, ActivityDate from Event where WhatId in :optyIdByEventId.values() order by WhatId];
        
        //create map of sales org custom settings by opportunity record type
        Map<String,SalesOrg__c> salesOrgByEvtRT = new Map<String,SalesOrg__c>();
        Map<Id,Opportunity>opptyUpdateMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> opptyDupeEUPMap = new Map<Id,Opportunity>();
        
        SalesOrg__c[] soList;
        if(!isDelete){
            soList = SalesOrg__c.getAll().values();
            //this could be problematic for sales orgs that share opportunity record types but want different statuses.
            for(SalesOrg__c sos:soList){
                if(sos.EventRecordTypeName__c!=null && sos.OppEUPStage__c!=null){
                    salesOrgByEvtRT.put(sos.EventRecordTypeName__c,sos);
                }
            }
            system.debug('event updateOppEvtCreateDelete salesOrgByEvtRT'+salesOrgByEvtRT);
        }
        
        for(Event ev:evntList)
        {   
            //increment number of events on opps as we loop through.  Need to set to null the first time each opp is hit for fresh count.   
            Opportunity opty = optyMap.get(ev.whatId);
            if(opty != null && !opptyUpdateMap.containsKey(opty.Id)){
                opty.Number_of_Events__c = 0;
            }
            if(opty!=null && ev.isRecurrence == false){
                opty.Number_of_Events__c = opty.Number_of_Events__c + 1;
                opptyUpdateMap.put(opty.Id,opty);
                
            } // if (ev.isRecurrence
            
            if(ev.Type != null) {
                if(opty != null && opty.IEUP_Date__c == null && ev.Type.contains('Presentation - Initial')) {
                    opty.IEUP_Date__c = ev.ActivityDate;
                } // if (opty.IEUP_Date__c)
            }
            
            //if this event was one of the originals passed in(since we had to get all events for each opp), 
            //check if it is a EUP.  If so, update opp status based on sales org custom setting
            if(!isDelete && ev.Type != null && ev.Type.startsWith('Presentation - Initial') && optyIdByEventId.containsKey(ev.Id)){
                //String eventRTName = RecordTypeHelper.getRecordTypeById(ev.RecordTypeId, 'Event').getName();
                SalesOrg__c sos = salesOrgByEvtRT.get(ev.RecordType.Name);
                system.debug('sos:'+sos+'opp stage:'+opty.StageName);
            if(opty!=null && sos!=null 
                  && (String.isBlank(opty.NSS_Source__c) || !opty.NSS_Source__c.startsWith(ProspectOwnershipMethods.NSS_INBOUND)) 
                  && (opty.StageName == sos.ReferralOppFirstStage__c || opty.StageName == sos.OppFirstStage__c) ){
                    opty.StageName = sos.OppEUPStage__c;
                    opptyUpdateMap.put(opty.Id,opty);
                    
                }//(opty!=null
            }//(!isDelete
            //if we've deleted an event, check to see if there are any Core EUP's left on the record, if there are we know not to update the status in a few lines
            else if(isDelete && ev.Type != null && ev.Type.startsWith('Presentation - Initial') && !optyIdByEventId.containsKey(ev.Id)){
                String eventRTName = RecordTypeHelper.getRecordTypeById(ev.RecordTypeId, 'Event').getName();
                if(eventRTName == Label.RT_Core_Event){
                    opptyDupeEUPMap.put(opty.Id,opty);
                }
                system.debug('event updateOppEvtCreateDelete isDelete presentation'+ev.Id);
            }
            
        } // for
        //loop through opportunities again to check what's left after delete
        if(isDelete){
            SalesOrg__c coreSetting = SalesOrg__c.getInstance('PAY');
            for(Opportunity opp: optyMap.values()){
                //if there were no returned events before, the oppty shouldn't have been updated in the event loop, therefore not in set
                if(!opptyUpdateMap.containsKey(opp.Id)){
                    opp.Number_of_Events__c = 0;
                    opptyUpdateMap.put(opp.id,opp);
                }
                //if the only EUP on a core opportunity is deleted and core opp is Discover, update to Create - Qualified
                if(!opptyDupeEUPMap.containsKey(opp.Id) && opp.StageName == Label.OppStage_Discovery 
                    && coreSetting != null && (opp.RecordType.Name == coreSetting.OpptyRecordTypeName__c || opp.RecordType.Name == coreSetting.OpptyRecordTypeName2__c)){
                    opp.StageName = Label.OppStage_Gained_Access;
                    opptyUpdateMap.put(opp.Id,opp);
                }
            }
        }
        system.debug('event updateOppEvtCreateDelete opptyUpdateMap'+opptyUpdateMap);
        if(!opptyUpdateMap.isEmpty()){
            //DmlHelper.performDML2(new List<Opportunity>(opptyUpdateSet), DmlHelper.DML_UPDATE, 'EventCheckType', 'updateOppEvtCreateDelete', 'calc Number of Events + status', false);
            DmlHelper.performDML2(opptyUpdateMap.values(), DmlHelper.DML_UPDATE, 'EventCheckType', 'updateOppEvtCreateDelete', 'calc Number of Events + status', false);            
        }       
   }
   public static void procesOptyEvtUpdate(Map<Id,Id> optyIdByEventId)
   {    if (System.isFuture() || System.isBatch() || Test.isRunningTest())
        {   updateOppEvtUpdate(optyIdByEventId); }
        else
        {   updateOppEvtUpdateFuture(optyIdByEventId);   }
    
   } // procesOpty
   
   @future
   public static void updateOppEvtUpdateFuture(Map<Id,Id> optyIdByEventId)
   {    updateOppEvtUpdate(optyIdByEventId); }
      
   public static void updateOppEvtUpdate(Map<Id,Id> optyIdByEventId)
   {
        Map<Id, Opportunity> optyMap = new Map<Id, Opportunity>([SELECT Id,Number_of_Events__c,StageName,Probability,ForecastCategoryName,RecordTypeId,RecordType.Name FROM Opportunity WHERE id in:optyIdByEventId.values()]);
        List<Event> evntList = [select Id, whatId, IsRecurrence, Type,RecordTypeId,Outcome__c,RecordType.Name from Event where WhatId in :optyIdByEventId.values() order by WhatId];
        Map<Id,Opportunity>opptyUpdateMap = new Map<Id,Opportunity>();
        Set<String> validOutcomeSet = new Set<String>(Label.Event_Outcome_Complete.split(';'));
        for(Event ev:evntList)
        {
            //if core eup is completed via outcome getting filled in, update opp to Discover
            Opportunity opp = optyMap.get(ev.whatId);
            SalesOrg__c coreSetting = SalesOrg__c.getInstance('PAY');
            if(opp.StageName == coreSetting.OppEUPStage__c && validOutcomeSet.contains(ev.Outcome__c)
                && coreSetting != null && (opp.RecordType.Name == coreSetting.OpptyRecordTypeName__c || opp.RecordType.Name == coreSetting.OpptyRecordTypeName2__c)){
                opp.StageName = Label.OppStage_Discovery;
                if(!opptyUpdateMap.containsKey(opp.Id)){
                    opptyUpdateMap.put(opp.Id,opp);
                }
            }
        }
        system.debug('event updateOppEvtUpdate opptyUpdateSet'+opptyUpdateMap);   
        DmlHelper.performDML2(opptyUpdateMap.values(), DmlHelper.DML_UPDATE, 'EventCheckType', 'updateOppEvtUpdate', 'calc status', false);
   }
    
	public static void createOrphanEventRecord(Event[] evnts) {	
        List<TaskOrphanCall__c> orphanCalls = new List <TaskOrphanCall__c>();	
        LIst<Id> evtIds = new List<Id>();	
        Id[] whoIds = new Id[]{};
        Map<Id,String> emailMap = new Map<Id,String>();	
        String email = '';	
        if(!evnts.isEmpty() && evnts != null) {	
            for(Event evt: evnts){	
                if(evt.Subject == Label.Drift_Event_Subject) {	
                    evtIds.add(evt.Id);	
                    if (evt.WhoId != null) {
                       whoIds.add(evt.WhoId);
                    }
                }	
            }	
        }   	
        if(!evtIds.isEmpty() && evtIds != null) {	
            emailMap = TaskHelper.queryActivityEmailMap(whoIds);	
            for(Event evnt: evnts) {	
                Id matchId = (evnt.WhoId != null ? evnt.WhoId : evnt.WhatId != null ? evnt.WhatId : null);	
                TaskOrphanCall__c orphanCall = new TaskOrphanCall__c();	
                email = emailMap.get(evnt.Id);	
                orphanCall.Email__c = email;	
                orphanCall.Drift_Activity__c = true;	
                orphanCall.Name = evnt.Subject;	
                orphanCall.EventId__c = (String)evnt.Id;	
                if (matchId != null) {	
                    orphanCall.MatchId__c = matchId;	
                } 	
                orphanCalls.add(orphanCall);	
            }	
        }	
        if(!orphanCalls.isEmpty()) {	
            DmlHelper.performDML2(orphanCalls, DmlHelper.DML_Insert, 'EventCheckData', 'createOrphanRecords', 'Creating Orphan Records for Drift Events', true);	
        }	
    } // createOrphanEventRecord
    
    
    
} // class EventCheckType