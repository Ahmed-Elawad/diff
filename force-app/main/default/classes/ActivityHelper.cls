/* 
  Methods for retrieving Activity
  
  History
  -------
  08/21/2019 Dan Carmen        Created
  04/17/2020 Dan Carmen        Add field for phone and if there's a recording from the DialSource Action object.
  06/30/2020 Dan Carmen        Update to the sort

*/
global with sharing class ActivityHelper {
   
   global class ActWrap implements comparable {
      public ActWrap(Task p_tsk) {
         tsk = p_tsk;
         setAction(tsk.DS_Denali__DialSource_Action__r);
         ownerName = tsk.Owner.Name;
      }
      
      public ActWrap(Event p_evnt) {
         evnt = p_evnt;
         setAction(evnt.DS_Denali__DialSource_Action__r);
         ownerName = evnt.Owner.Name;
      }
      
      public void setAction(DS_Denali__DialSource_Action__c p_action) {
         action = p_action;
         phone = null;
         hasRecording = (action != null && String.isNotBlank(action.DS_Denali__Recording_ID__c));
         if (action != null && action.RecordType.Name=='Outbound') {
             phone = action.DS_Denali__Phone__c;
         } else if (action != null && action.RecordType.Name=='Inbound') {
             phone = action.InboundCallerId__c;
         }

      } // setAction
       
       public Id Id{
         get {return (isEvent ? evnt.Id : (isTask ? tsk.Id : null)); }
       }
       
      @AuraEnabled
      public Boolean isEvent{get { return (evnt != null);}}
      @AuraEnabled
      public Boolean isTask{get { return (tsk != null);}}
      
      @AuraEnabled
      public Event evnt;
      @AuraEnabled
      public Task tsk;
      public DS_Denali__DialSource_Action__c action;
      
      @AuraEnabled
      public Date activityDate{
         get {return (isEvent ? evnt.ActivityDate : (isTask ? tsk.ActivityDate : Date.today())); }
      } // activityDate
      
      @AuraEnabled
      public String contactName {
         get {return (isEvent ? evnt.Who.Name : (isTask ? tsk.Who.Name : null)); }
      } // contactName
      
      @AuraEnabled
      public String subject {
         get {return (isEvent ? evnt.Subject : (isTask ? tsk.Subject : null)); }
      }
      
      @AuraEnabled
      public String activityType {
         get {return (isEvent ? evnt.Type : (isTask ? tsk.Type : null)); }
      }
      
      public DateTime activityDateTime{
         get {
            DateTime dt = DateTime.now();
            if (isEvent) {
               dt = evnt.ActivityDateTime;
            } else if (isTask) {
               //dt = DateTime.newInstance(tsk.ActivityDate,Time.newInstance(1,0,0,0));
               dt = DateTime.newInstance(tsk.ActivityDate,tsk.CreatedDate.time());
            }
             return dt;
         } // get
      } // activityDateTime
       
      @AuraEnabled
       public String ownerName {get;set;}
       
       @AuraEnabled
       public String phone {get;set;}
       
       @AuraEnabled
       public boolean hasRecording {get;set;}
       
       @AuraEnabled
       public String recordingUrl{
           get {
               // if(DS_Denali__Recording_ID__c != "", HYPERLINK('/apex/DS_Denali__PlayRecording?id='+Id,"Play Recording"), "")
               String recUrl = null;
               if (action != null && String.isNotBlank(action.DS_Denali__Recording_ID__c)) {
                   recUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/DS_Denali__PlayRecording?id='+action.Id;
               }
               return recUrl;
           } // get
       } // recordingUrl
      
      global Integer compareTo(Object objectToCompareTo) {
         if (objectToCompareTo != null && (isEvent || isTask)) {
            ActWrap compareAw = (ActWrap)objectToCompareTo;
            DateTime thisDt = activityDateTime;
            DateTime thatDt = compareAw.activityDateTime;
            if (thisDt != null && thatDt != null) {
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'thisDt='+thisDt.format()+' thisDt long='+thisDt.getTime()+' thatDt='+thatDt.format()+' thatDt long='+thatDt.getTime()));
               if (thatDt.getTime() > thisDt.getTime()) {
                  return 1;
               } else if (thisDt.getTime() == thatDt.getTime()) {
                  return 0;
               }
               //return Integer.valueOf(thatDt.getTime() - thisDt.getTime());
            }
         } // if (objectToCompareTo != null
         return -1;
      } // compareTo

   } // class ActWrap
   
   @AuraEnabled
   public static ActWrap[] getLatestActivity(Id recId) {
      return getActivity(recId, false, 15);
   } // getLatestActivity
   
   public static ActWrap[] getActivity(Id recId, Boolean onlyOpen, Integer nbrRecs) {
      System.debug('getActivity recId='+recId);
      ActWrap[] actWraps = new ActWrap[]{};
      Map<Id,ActWrap[]> actByOwnerIdMap = new Map<Id,ActWrap[]>();
      Task[] tsks = [Select Id, OwnerId, Owner.Name, Subject, IsClosed, Type, CreatedDate
                           ,ActivityDate
                           ,Description
                           ,WhatId
                           ,WhoID
                           ,Who.Name 
                           ,What.Name     
                           ,DS_Denali__DialSource_Action__c
                           ,DS_Denali__DialSource_Action__r.Id
                           ,DS_Denali__DialSource_Action__r.DS_Denali__Phone__c
                           ,DS_Denali__DialSource_Action__r.DS_Denali__Recording_ID__c
                           ,DS_Denali__DialSource_Action__r.InboundCallerId__c
                           ,DS_Denali__DialSource_Action__r.RecordType.Name
                       From Task
                      Where WhatId = :recId
                         or WhoId = :recId
                         or AccountId = :recId
                      order by ActivityDate desc
                      limit :nbrRecs];
      for (Task tsk : tsks) {
         System.debug('getActivity subject='+tsk.Subject+' ownerId='+tsk.OwnerId+' owner='+tsk.Owner.Name+' action='+tsk.DS_Denali__DialSource_Action__c);
         if (!onlyOpen || (onlyOpen && !tsk.IsClosed)) {
            addToLists(tsk.OwnerId, new ActWrap(tsk), actWraps, actByOwnerIdMap);
         }
      } // for (Task tsk : tsks
      System.debug('getActivity tsks='+tsks.size()+' actWraps='+actWraps.size());
      
      Event[] evnts = [Select Id, OwnerId, Owner.Name, Subject, Type, CreatedDate
                           ,ActivityDate
                           ,ActivityDateTime
                           ,DurationInMinutes
                           ,Description
                           ,WhatId
                           ,WhoID
                           ,Who.Name 
                           ,What.Name     
                           ,DS_Denali__DialSource_Action__c
                           ,DS_Denali__DialSource_Action__r.Id
                           ,DS_Denali__DialSource_Action__r.DS_Denali__Phone__c
                           ,DS_Denali__DialSource_Action__r.DS_Denali__Recording_ID__c
                           ,DS_Denali__DialSource_Action__r.InboundCallerId__c
                           ,DS_Denali__DialSource_Action__r.RecordType.Name
                       From Event
                      Where WhatId = :recId
                         or WhoId = :recId
                         or AccountId = :recId
                      order by ActivityDate desc
                      limit :nbrRecs];
      Datetime checkDate = Datetime.now();
      for (Event evnt : evnts) {
         if (!onlyOpen || (onlyOpen && evnt.ActivityDateTime > checkDate)) {
            addToLists(evnt.OwnerId, new ActWrap(evnt), actWraps, actByOwnerIdMap);
         }
      } // for (Event evnt : evnts
      System.debug('getActivity evnts='+evnts.size()+' actWraps='+actWraps.size());
      
      if (!actWraps.isEmpty()) {
         setOwnerNames(actByOwnerIdMap);
         actWraps.sort();
      }
      return actWraps;
   } // getActivity
    
    public static void setOwnerNames(Map<Id,ActWrap[]> actByOwnerIdMap) {
       User[] users = [Select Id, Name from User where Id in :actByOwnerIdMap.keySet()];
       for (User usr : users) {
          ActWrap[] wraps = actByOwnerIdMap.get(usr.Id);
          if (wraps != null) {
             for (ActWrap wrap : wraps) {
                wrap.ownerName = usr.Name;
             }
          }
       } // for (User usr : users
    } // setOwnerNames
    
    public static void addToLists(Id ownerId, ActWrap aw, ActWrap[] actWraps, Map<Id,ActWrap[]> actByOwnerIdMap) {
       actWraps.add(aw);
       ActWrap[] byOwnerId = actByOwnerIdMap.containsKey(ownerId) ? actByOwnerIdMap.get(ownerId) : new ActWrap[]{};
       byOwnerId.add(aw);
       actByOwnerIdMap.put(ownerId,byOwnerId);
    } // addToLists
       
   
} // class ActivityHelper