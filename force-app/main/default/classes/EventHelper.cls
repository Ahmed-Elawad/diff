/*

  History
  -------
  07/21/2021 Dan Carmen         Subject (parentId) of the chatter wasn't being set. Fixed code for bulk transactions.
  
 */
public without sharing class EventHelper implements TriggerInterfaceC {
    
    public static final String CLASSNAME='EventHelper';
    public static Boolean SKIP_TRIGGERS=false;

    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('EventHelper.handleTrigger recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete+' Trigger.old='+(Trigger.old != null ? Trigger.old.size() : -1));
        if (TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
           System.debug('EventHelper handleTrigger trigger ran');
           return;
        }
        SObjectType objType = TriggerMethods.objType;

        if(isAfter){
            if(objType == Event.sObjectType){
                // method to create that handles the old events if the owner has changed
                handleEventsAfter((Event[])recs,(Map<Id,Event>)oldMap);
            }
        }
    }
    
    // for testing purposes.
    public static Integer nbrChatterPosts=0;
    
    public static void handleEventsAfter(Event[] evts, Map<Id,Event> oldMap){
        // call on the chatterMentionPost method to post chatter update to DSM and DSA of users

        // while going through the events create a chatterWrapper and add it to a list of chatterWrappers 


        // use chatterMentionPost.createChatterMentionPost and ChatterMentionPost.postBatchFeedElements to batchify the posts.
        
        //EventWrapper[] ewList = new EventWrapper[]{};
        System.debug('Entering Event For Loop');
        //String[] chatterMessages = new String[]{};
            
        Id[] ownerIds = new Id[]{};
        Event[] evtsToProcess = new Event[]{};
        Id[] refCtctIds = new Id[]{};
            
        for (Event evt : evts) {
           Event oldEvt = (oldMap != null ? oldMap.get(evt.Id) : null);
           System.debug('handleEventsAfter refCtct='+evt.Referral_Contact__c+' ownerId='+evt.OwnerId+' old ownerId='+(oldEvt != null ? oldEvt.OwnerId : null));
           if (evt.Referral_Contact__c != null && oldEvt != null && evt.OwnerId != oldEvt.OwnerId) {
              ownerIds.add(evt.OwnerId);
              ownerIds.add(oldEvt.OwnerId);
              ownerIds.add(evt.CreatedById);
              evtsToProcess.add(evt);
              refCtctIds.add(evt.Referral_Contact__c);
           }
        } // for (Event evt : evts
        
        System.debug('handleEventsAfter ownerIds='+ownerIds.size()+' evtsToProcess='+evtsToProcess.size()+' refCtctIds='+refCtctIds.size());
        if (evtsToProcess.isEmpty()) {
           return;
        }
         
        Map<Id,User> userMap = new Map<Id,User>([Select Id, Name, DSA_FSS__c,ManagerId from User where Id in :ownerIds]);
        Map<Id,Referral_Contact__c> refCtctMap = new Map<Id,Referral_Contact__c>([Select Id,Name,Referral_Account__r.Name from Referral_Contact__c where Id in :refCtctIds]);
       
        for (Event evt : evtsToProcess) {
           Event oldEvt = (oldMap != null ? oldMap.get(evt.Id) : null);
           User curOwner = userMap.get(evt.OwnerId);
           User prevOwner = userMap.get(oldEvt.OwnerId);
           User createdBy = userMap.get(evt.CreatedById);
           Referral_Contact__c refCtct = refCtctMap.get(evt.Referral_Contact__c);
           if (curOwner != null && prevOwner != null && createdBy != null && refCtct != null) {
              Id[] mentionIds = new Id[]{};
              mentionIds.add(evt.CreatedById);
              String[] chatterMessages = new String[]{};
              String formattedMeetingTime = evt.ActivityDateTime.format('M/d/yyyy hh:mm a');
              chatterMessages.add('Hello '+createdBy.Name+', \n');
              chatterMessages.add('The CPA Meeting has been reassigned from '+prevOwner.Name+' to '+curOwner.Name+'\n');
              chatterMessages.add('Previous Owner: '+prevOwner.Name+'\n');
              chatterMessages.add('Current Owner: '+curOwner.Name+'\n');
              chatterMessages.add('Referral Contact Name: '+refctct.Name+'\n');
              chatterMessages.add('Referral Account Name: '+refctct.Referral_Account__r.Name+'\n');
              chatterMessages.add('Date and Time: '+formattedMeetingTime+'\n');
              chatterMessages.add('Event Created By: '+createdBy.Name+'\n \n');
              ChatterMentionPost.createChatterMentionPost(refCtct.Id,mentionIds,chatterMessages,false,true);
              nbrChatterPosts++;
           } else {
              System.debug('handleEventsAfter null record found curOwner='+evt.OwnerId+' prevOwner='+oldEvt.OwnerId+' createdBy='+evt.CreatedById+' refCtct='+evt.Referral_Contact__c);
           }
        } // for (Event evt
/*
        for(Event evt:evts){ //for loop to populate the EventWrappers
            if(oldMap.get(evt.Id)!= null){
                Event oldEvent = oldMap.get(evt.Id);
           
            if(evt.OwnerId != oldEvent.OwnerId){
                EventWrapper ew = new EventWrapper(oldEvent);
                ew.prevOwner = getUser(oldEvent.OwnerId);
                ew.currentOwner = getUser(evt.OwnerId);
                ew.createdBy = getUser(evt.CreatedById);
                ew.refctctId = evt.Referral_Contact__c;
                chatterMessages.add('Hello '+ew.createdBy.Name+', \n');
                chatterMessages.add('The CPA Meeting has been reassigned from '+ew.prevOwner.Name+' to '+ew.currentOwner.Name+'\n');
                chatterMessages.add('Previous Owner: '+ew.prevOwner.Name+'\n');
                chatterMessages.add('Current Owner: '+ew.currentOwner.Name+'\n');
                chatterMessages.add('Referral Contact Name: '+ew.refctct.Name+'\n');
                chatterMessages.add('Referral Account Name: '+ew.refctct.Referral_Account__r.Name+'\n');
                chatterMessages.add('Date and Time: '+ew.meetingTime+'\n');
                chatterMessages.add('Event Created By: '+ew.createdBy.Name+'\n \n \n');
                




                // chatterMessages.add('Ownership has changed from '+ew.prevOwner.Name+' to '+ew.currentOwner.Name);
                //ew.chatterText.add('Ownership has changed from '+ew.prevOwner.Name+' to '+ew.currentOwner.Name);
                ew.chatterText = chatterMessages;
                ewList.add(ew);
                //populate the list of event wrappers here 
                //EventWrapper ew = new EventWrapper(evt);
                // ewList.add(ew);
                
                // an idea, Build a new method in chatterMentionPost and assign it for Events
                // ChatterMentionPost.buildChatterMessage(evt);
                    
                //send update here 

            }
        }
        }
        System.debug('Entering EventWrapper For loop');
        System.debug('EventWrapper List size ='+ewList.size());
        for(EventWrapper ew: ewList){
            //create ChatterWrappers based off of the event wrappers
            //ChatterWrapper cw = new ChatterWrapper
            //System.debug(ew.mentionIds);
            ChatterMentionPost.createChatterMentionPost(ew.refctctId,ew.mentionIds,ew.chatterText,false,true);
            
        }
        */
        ChatterMentionPost.postBatchFeedElements();

    } // handleEventsAfter
    
   
} // class EventHelper