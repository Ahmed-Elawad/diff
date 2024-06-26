/* 

  History
  -------
  03/22/2022 Dan Carmen          Cleaned up code

 */
public with sharing class ActivityDA {
    
   // for testing purposes only
   public static Boolean throwTestException=false;
    
   public static ActivityCombined[] getOpenActivities(Id checkId) {
       if (throwTestException) {
          throw new AuraHandledException('This is a test exception');
       }
       Task[] tasks = [Select Id, ActivityDate, AccountId
                             ,Description
                             ,Subject
                             ,Contact_Name__c
                             ,WhatId
                          	 ,WhoID
                             ,Who.Name
                             ,What.Name                          		
                         From Task where IsClosed=false
                          And (WhoId = :checkId or WhatId = :checkId or AccountId=:checkId)
                       ORDER BY ActivityDate ASC NULLS LAST, LastModifiedDate DESC
                           LIMIT 50];
       Event[] events = [Select Id, ActivityDate, AccountId
                               ,Description
                               ,Subject
                               ,Contact_Name__c
                               ,DurationInMinutes
                               ,WhatID
                               ,WhoID	
                               ,Who.Name
                               ,What.Name
                               ,ActivityDateTime
                          From Event where ActivityDateTime >= :System.now()
                           And (WhoId = :checkId or WhatId = :checkId or AccountId=:checkId)
                        ORDER BY ActivityDate ASC NULLS LAST, LastModifiedDate DESC
                            LIMIT 50];
        ActivityCombined[] returnActivities = combineActivity(tasks,events);
        return returnActivities;
   } // getOpenActivities
    

//JC wrapper class to combine tasks and events
    public class ActivityCombined {
        public Task tsk;
        public Event evt;
                
        public ActivityCombined(Task p_tsk) {
            tsk = p_tsk;
        }
        public ActivityCombined(Event p_evt) {
            evt = p_evt;
        }
        @AuraEnabled
        public Id recId {
            get {return (tsk != null ? tsk.Id : evt.Id);}
        }        
        @AuraEnabled
        public Date activityDate {
            get {return (tsk != null ? tsk.ActivityDate : evt.ActivityDate);}
        }
        @AuraEnabled

        public string type {
            get{return(tsk!=null ? 'Task' : 'Event');}
        }
        @AuraEnabled
        public string subject {
            get{return(tsk!=null ? tsk.Subject :evt.Subject);}
        }
        @AuraEnabled        
        public string whoId {
            get {return(tsk!=null ? tsk.WhoId : evt.WhoId);}
        }
        @AuraEnabled        
        public string whatId {
            get {return(tsk!=null ? tsk.WhatId : evt.WhatId);}
        }        
        @AuraEnabled 
        public string whoName{
            get {return (tsk!=null ? tsk.Who.name : evt.Who.name);}   
        }
        @AuraEnabled 
        public string whatName{
            get {return (tsk!=null ? tsk.What.Name : evt.What.Name);}   
        }        
        
        @AuraEnabled 
        public string whoLink{
          	get{return (null);}
        } 
              
        @AuraEnabled 
        public string whatLink{
			get{return (null);}            
        }

    } // class ActivityCombined
    
    //JC new list generated to combine tasks/events
    public static List<ActivityCombined> combineActivity(Task[] tsks, Event[] evnts) {
        Map<Date,ActivityCombined[]> activityMap = new Map<Date,ActivityCombined[]>();
        for (Task tsk : tsks) {
            ActivityCombined[] actList = (activityMap.containsKey(tsk.ActivityDate) ? activityMap.get(tsk.ActivityDate) : new ActivityCombined[]{});
            actList.add(new ActivityCombined(tsk));
            activityMap.put(tsk.ActivityDate, actList);
        }
        
        for (Event evt : evnts) {
            ActivityCombined[] actList = (activityMap.containsKey(evt.ActivityDate) ? activityMap.get(evt.ActivityDate) : new ActivityCombined[]{});
            actList.add(new ActivityCombined(evt));
            activityMap.put(evt.ActivityDate, actList);
        }
        
        
        Date[] sortedKeys = new Date[]{};
        sortedKeys.addAll(activityMap.keySet());
        sortedKeys.sort();  // have to check to see how it sorts - pretty sure it sorts ascending
        
        ActivityCombined[] returnList = new ActivityCombined[]{};
            for (Integer cnt=sortedKeys.size()-1; cnt>=0; cnt--) {
               ActivityCombined[] mapList = activityMap.get(sortedKeys[cnt]);
                if (mapList != null) {
                   returnList.addAll(mapList);
                }
            }
        
        return returnList;
    } // combineActivity

    public List<Event> getInitialPresentationEventsByOpportunityId(Id opportunityId) {
            // Matches on anything that starts w/ Presentation - Initial
            String initialPresentationType = 'Presentation - Initial%';

            List<Event> initialPresentationEvents = new List<Event>();
            initialPresentationEvents = [
                    SELECT Id,
                            Type,
                            ActivityDate,
                            Outcome__c
                    FROM Event
                    WHERE WhatId = :opportunityId
                    AND Type LIKE :initialPresentationType
            ];

            return initialPresentationEvents;
    } // getInitialPresentationEventsByOpportunityId

    public List<OpportunityContactRole> getContactRolesByOpportunityId(Id opportunityId) {
            // Matches on anything that starts w/ Presentation - Initial

            List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
            contactRoles = [
                    SELECT ContactId,
                            Contact.Name,
                            Contact.Phone,
                            Contact.HomePhone,
                            Contact.MobilePhone,
                            IsPrimary,
                            OpportunityId,
                            Role,
                            Contact.Title,
                            Contact.AccountId,
                            Contact.Account.Name,
                            Contact.MailingAddress,
                			Contact.DoNotCall,
                			Contact.HasOptedOutOfEmail,
                            Contact.Email
                    FROM OpportunityContactRole
                    WHERE OpportunityId = :opportunityId
            ];

            return contactRoles;
    } // getContactRolesByOpportunityId

} // class ActivityDA