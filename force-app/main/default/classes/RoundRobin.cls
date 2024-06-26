/* 
 * Handle round robin assigning of cases, leads and contacts.  Accept sObject, sot

Assignment_Group_Name__c (Label Assignment Gruop) = the group name and info
Assignment_Group_Queues__c (Label AG-Queues) = the queue information. This is so we can have more then one queue on a group
Assignment_Groups__c (Label Group Member) = the group member

 * History
 * -------
 * 08/10/2011 Dan Carmen        Created.
 * 06/11/2015 Jacob Hinds       Copied code over from CaseRoundRobin class. Making the code accept sObject instead of case
 * 01/29/2016 Jacob Hinds       Adding in Original Owner that gets filled out the first time Round Robin runs
 * 07/13/2016 Jacob Hinds       Adding in events and doing a general cleanup
 * 09/06/2016 Jacob Hinds       Overhaul on how leads and contacts enter round robin to better support bulk processes
 * 02/09/2017 Jacob Hinds       Small bug fix for partner referral
 * 04/13/2017 Jacob Hinds       Adding Generic RR entry method
 * 04/19/2017 Jacob Hinds       Adding Weighed Round Robin
 * 04/24/2017 Jacob Hinds       Adding in chatter post after assignment
 * 06/02/2017 Jacob Hinds       Adding chatter mention on referral, commenting out source+destination on PartnerReferral
 * 06/16/2017 Jacob Hinds       Commenting out a lot of unused code to be removed at a future date.  Also removed RR Custom Setting.
 * 06/19/2017 Jacob Hinds       Change to partnerReferral round robin tracking fields
 * 06/26/2017 Jacob Hinds       Adding chatter notification
 * 08/11/2017 Jacob Hinds       Adding chatter notification when delegate is assigned
 * 12/19/2017 Jacob Hinds       Removing outdated code, fixing delegate assignment when nobody is active during business hours INC1466358
 * 11/13/2018 Josh Cartwright   Added check for 11 - 12pm --  else if(currentHour == 11)
 * 01/15/2018 Jake Hinds        Changing Scheduler fields from text to time.  Adding ability to toggle night/weekend weighting. Deleting a bunch of commented out code
 * 02/18/2018 Jake Hinds        Adding logging process notes
   07/18/2019 Dan Carmen        Update save routine from SObjectHelper to DmlHelper 
   10/16/2019 Jake Hinds    Adding internal referral account team member
   11/11/2019 Josh Cartwright   Added method to store query in cache 
   06/26/2020 Jake Hinds    Fix for currTime when group member timezone is different than running user. removing commented out code
   08/23/2021 Jake Hinds    Change to without sharing
   05/24/2022 Reetesh Pandey     Account Team Member sharing
   12/15/2023 Dan Carmen         Clean up code
   12/23/2023 Dan Carmen         Fix scheduler to handle overnight times
 
 */
public without sharing class RoundRobin {
   
   //public static Integer dayOfWeek;
       
   public static Event[] updateEvents;
   
   public static Case[] updateEventCases;
      
   public static Map<Id,PartnerReferral__c> updateMotherMap;
   
   public static Map<Id,Assignment_Group_Name__c> groupsToUpdate;
   
   public class objectSettingWrapper{
     public sObject obj;
     public Id queueId;
     public String oType;
     public Case relatedCase;
     public String skillLevel;
     public PartnerReferral__c mothership;
     //public Transfer_Tracking__c latestTracker;
     public Account coAcct;
   } // class objectSettingWrapper
   
   public static void prepareCaseRoundRobin(List<Case> cases, List<Id> queueIds){
       objectSettingWrapper[] wraps = new objectSettingWrapper[]{};
       for(Case c:cases){
         objectSettingWrapper wrap = new objectSettingWrapper();
            StringHelper.addToProcessNotes((Case)c,'Entering Round Robin with OwnerId'+c.OwnerId);
            wrap.obj = c;
            wrap.queueId = c.OwnerId;
            wrap.oType = 'Case';
            wraps.add(wrap);
       }
       if(!queueIds.isEmpty()){
         handleRoundRobin(wraps, queueIds,new Map<Id,Case>());
       }
     
   }
   public static void prepareGenericRoundRobin(List<sObject> objs,Map<String,PartnerReferral__c> rrMotherMap){
       objectSettingWrapper[] wraps = new objectSettingWrapper[]{};
       Id[] queueIds = new Id[]{};
       Id[] objIds = new Id[]{};
       for(sObject s: objs){
            objIds.add((Id)s.get('Id'));
            queueIds.add((Id)s.get('OwnerId'));
       }
       Map<Id,Group> queueNames = UserHelper.getQueueMapById(queueIds);
       system.debug('queueQuery'+queueNames);
       for(sObject s:objs){
            objectSettingWrapper wrap = new objectSettingWrapper();
            if(s.getSObjectType().getDescribe().getName() == Referral__c.getSObjectType().getDescribe().getName()){
                StringHelper.addToProcessNotes((Referral__c)s,'Entering Round Robin with OwnerId'+s.get('OwnerId'));
                String transactionId = (String)s.get('Transaction_Id__c');
                system.debug(' motherMap: '+rrMotherMap+' transId: '+transactionId+' result: '+rrMotherMap.get(transactionId));
                wrap.mothership = (rrMotherMap!=null && transactionId!=null && rrMotherMap.containsKey(transactionId) ? rrMotherMap.get(transactionId) : null);
            }
            wrap.obj = s;
            wrap.queueId = (Id)s.get('OwnerId');
            wrap.oType = s.getSObjectType().getDescribe().getName();
            wraps.add(wrap);
       }
       if(!queueIds.isEmpty()){
         handleRoundRobin(wraps, queueIds,new Map<Id,Case>());
         if (updateMotherMap!=null && !updateMotherMap.isEmpty()){
            update updateMotherMap.values();
         }
       }
     
   }
   public static void prepareContactRoundRobin(Map<Id,Contact> rrContactMap,Map<Id,Account> rrAccountMap,Map<Id,PartnerReferral__c> rrMotherMap){
        if (ContactMethods.CONTACT_WAS_PROCESSED_ROUND_ROBIN) {
          return;
        }
   }
   public static void prepareLeadRoundRobin(Map<Id,Lead> rrLeadMap,Map<Id,PartnerReferral__c> rrMotherMap){
        if (LeadMethods.LEAD_WAS_PROCESSED_ROUND_ROBIN) {
            system.debug('wasprocessedrr');
          return;
        }
   }
   public static string casePreFix = case.sObjectType.getDescribe().getKeyPrefix();
 
   public static final string CACHE_KEY='AssignmentGroupQueues';    
 
//JC added this to cache Assignement Group Queues 
   public static map<string, Assignment_Group_Queues__c> selectAgQueueCache (List<Id> queueIds){
      map<string, Assignment_Group_Queues__c> assignmentGroupMap =(map<string, Assignment_Group_Queues__c>)CacheManager.getOrg(CACHE_KEY); 
      system.debug('RoundRobin.selectAgQueueCache assignmentGroupMap: ' +(assignmentGroupMap != null ? assignmentGroupMap.size() : -1));
        
      if(assignmentGroupMap == null){
         Assignment_Group_Queues__c[] queues =[SELECT Id, Name, QueueId__c
                                                       ,Active__c, Valid_Queue__c
                                                   FROM Assignment_Group_Queues__c where Active__c = 'true' ]; 

         assignmentGroupMap = new Map<string, Assignment_Group_Queues__c>(); 
         for(Assignment_Group_Queues__c agq: queues){
            assignmentGroupMap.put(agq.QueueId__c,agq);
         }
         CacheManager.putOrg(CACHE_KEY,assignmentGroupMap); 
      }//if
        
      return assignmentGroupMap; 
   }  //selectAgQueueCache
    
   // for testing purposes only
   public static String testDayOfWeek=null;
   public static String testPrevDay=null;
   public static Datetime testRightNow=null;
    
   public static void handleRoundRobin(objectSettingWrapper[] wraps, List<Id> queueIds, Map<Id,Case> relatedCases) {
      Map<String,Assignment_Group_Queues__c> queueMap = selectAgQueueCache(queueIds); 
      list <id> activeQIds = new list <id>(); 
      system.debug('handleRoundRobin queueIds='+queueIds.size()+' QueueMap='+QueueMap.size());
      for(id i: queueIds){
         system.debug ('handleRoundRobin i='+i+' queueMap.containsKey='+ queueMap.containsKey(i)); 
         if(queueMap.containsKey(i)){
             activeQIds.add(i); 
         }//if   
      }//for
      system.debug('handleRoundRobin activeQIds='+activeQIds.size());
      if (activeQIds.isEmpty()){
         return;
      }
      queueIds.clear();
      queueIds.addAll(activeQIds); 
       

       //Find active Assignment Group for Queue
      Map<Integer,Id> asgnGroupNameIds = new Map<Integer,Id>();   //Trigger index --> Assignment_Group_Name ID
      Map<Id,Assignment_Group_Queues__c> asgnGroupQueues = new Map<Id,Assignment_Group_Queues__c>(); //Queue ID --> Assignment Group Queues
      Map<Id,Id> evCaseOwnerMap = new Map<Id,Id>();
      // retrieve all records
      system.debug('handleRoundRobin wraps='+wraps.size()+' queueIds='+queueIds.size()+' relatedCases='+relatedCases.size());
      //use cachemanager put all Assignment Group Queues into a map
       
      Assignment_Group_Name__c[] grps=[SELECT Id,Name,Current_Weighting_Round__c,Current_Weighting_Round_Time__c,Round_Robin_Delegate__c,Use_Scheduler__c,Use_Weighting__c
                                                ,Weekday_Start__c,Weekday_End__c,Weekend_Start__c,Weekend_End__c,Skip_Weighting_Nights_Weekends__c,Weekend_Always_On__c
                                                ,ScheduleAllHours__c
                                           /* - remove this if we can, used in for loop below  */
                                               ,(SELECT Id, Name, QueueId__c
                                                       ,Active__c, Valid_Queue__c
                                                   FROM Assignment_Group_Queues__r) 
                                               ,(SELECT Id, Name
                                                       ,Group_Name__c
                                                       ,User__c, User__r.Name,User__r.Sales_Org__c,User__r.TimeZoneSidKey,Last_Assignment__c, Millisecond__c
                                                       ,Monday_1__c,Monday_2__c,Monday_3__c,Monday_4__c,Tuesday_1__c,Tuesday_2__c,Tuesday_3__c,Tuesday_4__c,Wednesday_1__c,Wednesday_2__c,Wednesday_3__c,Wednesday_4__c
                                                       ,Thursday_1__c,Thursday_2__c,Thursday_3__c,Thursday_4__c,Friday_1__c,Friday_2__c,Friday_3__c,Friday_4__c,Saturday_1__c,Saturday_2__c,Saturday_3__c,Saturday_4__c
                                                       ,Sunday_1__c,Sunday_2__c,Sunday_3__c,Sunday_4__c
                                                       ,Skill_Set__c,Weighting_Level__c
                                                   FROM Assignment_Groups__r
                                                  WHERE Active__c = 'True' AND User_Active__c = 'True'
                                                  ORDER BY Last_Assignment__c, Millisecond__c)
                                           FROM Assignment_Group_Name__c
                                          WHERE Id IN (SELECT Assignment_Group_Name__c
                                                         FROM Assignment_Group_Queues__c
                                                         WHERE QueueId__c in :queueIds
                                                           AND Active__c = 'True')];
      
      system.debug('handleRoundRobin grps='+grps.size());   
      if (grps.isEmpty()) {
         return;
      }
      //Get running user info. Mainly used for timecode info
      User runningUser = UserHelper.getRunningUser();
      // Map of queue id to the Assignment_Group_Queues__c id
      Map<Id,Id> queueIdMap = new Map<Id,Id>();
      // assignment group members by queue name id
      Map<Id,List<Assignment_Groups__c>> groupMembersByQueueId = new Map<Id,List<Assignment_Groups__c>>();
      // assignment groups by queue id
      Map<Id,Assignment_Group_Name__c> agByQueueId = new Map<Id,Assignment_Group_Name__c>();
      for(Assignment_Group_Name__c agn : grps) {
         system.debug('handleRoundRobin agn='+agn.Name); 
         // for multiple queues, put the same list in place
         for (Assignment_Group_Queues__c agq : agn.Assignment_Group_Queues__r) {
            agByQueueId.put(agq.QueueId__c,agn);
            groupMembersByQueueId.put(agq.QueueId__c,agn.Assignment_Groups__r);
            queueIdMap.put(agq.QueueId__c,agq.Id);
         } // for (Assignment_Group_Queues__c agq
      } // for (Assignment_Group_Name__c agn

      // Determine next valid user in Queue/Assignment Group for round robin
      // User with earliest last assignment date wins.
      
      // to store the links that will be inserted
      // store the assignment groups to be saved in a map so only in once
      Map<Id,Assignment_Groups__c> updateAssignmentGroups = new Map<Id,Assignment_Groups__c>();
      
      List<EventRelation> erList = new List<EventRelation>();
      List<Event> eventList = new List<Event>();
      List<Case> eventCases = new List<Case>();
      Boolean createChatter = false;
      
      AccountTeamMember[] atms = new AccountTeamMember[]{};
      String dayofWeekStr = (testDayOfWeek != null ? testDayOfWeek : Datetime.now().format('EEEEE'));
      String yesterdayStr = (testPrevDay != null ? testPrevDay : Datetime.now().addDays(-1).format('EEEEE'));
       
      DateTime rightNow = (testRightNow != null ? testRightNow : DateTime.now());
      Time currTime = Time.newInstance(rightNow.hour(),rightNow.minute(),rightNow.second(),rightNow.millisecond());

      if (runningUser!=null && string.isnotblank(runningUser.TimeZoneSidKey) && string.isnotblank(Label.Default_TimeZone)){
         DateTime nowDT = system.now();
         Decimal runningUserTimeZoneHour = Decimal.valueOf(nowDT.format('HH',runningUser.TimeZoneSidKey));
         Decimal defaultTimeZoneHour = Decimal.valueOf(nowDT.format('HH',Label.Default_TimeZone));
         Integer timeDifference = Integer.valueOf(defaultTimeZoneHour - runningUserTimeZoneHour);
         if(timeDifference !=null && timeDifference > 0){
            currTime = Time.newInstance(rightNow.hour()+timeDifference,rightNow.minute(),rightNow.second(),rightNow.millisecond());
         }
         system.debug('handleRoundRobin runningUserTimeZoneHour='+runningUserTimeZoneHour+' defaultTimeZoneHour='+defaultTimeZoneHour+' timeDiff='+timeDifference+' currTime='+currTime);
      } // if (runningUser

      System.debug('handleRoundRobin dayofWeekStr='+dayofWeekStr+' yesterdayStr='+yesterdayStr+' currTime='+currTime);
       
      for (objectSettingWrapper w : wraps) {
         Id queueId = w.queueId;
         sObject s = w.obj;
         String oType = w.oType;
         Account coAcct = w.coAcct;
         
         PartnerReferral__c mothership = w.mothership; 
         //Transfer_Tracking__c latestTracker = w.latestTracker;
         if(updateMotherMap==null){
           updateMotherMap = new Map<Id,PartnerReferral__c>();
         }
         List<Assignment_Groups__c> ags = groupMembersByQueueId.get(queueId);
         Assignment_Group_Name__c aGroup = agByQueueId.get(queueId);
         system.debug('handleRoundRobin queueId='+queueId+' ags='+(ags != null ? ags.size() : -1)+' aGroup='+(aGroup != null ? aGroup.Name : 'NotFound'));
         if (ags != null && !ags.isEmpty()) {
            Assignment_Groups__c ag;
            Boolean assigned = false;
            Boolean delegated = false;
            Boolean night = false;
            Boolean weekend = false;
            //AG_Queue__c agQueue = queueIdMap.get(wrap.s.get('OwnerId'));
            if(aGroup != null && (aGroup.Use_Weighting__c || aGroup.Use_Scheduler__c)){
                Boolean assignmentOkay = false;
                //switch to try and prevent recursion.  Only gets set at the end of the final round when we want to loop back to round 1.
                Boolean safetySwitch = false;
                //if nobody is active, try to use the delegate from the custom setting.
                Boolean useDelegate = false;
                
                //Date todayDay = system.today();
                //Date begWeek = todayDay.toStartofWeek();
                //if(!Test.isRunningTest()){
                //    dayOfWeek = begWeek.daysBetween(todayDay);
                //}
                // if we're including all hours in the schedule, we don't have to look at anything for the nights and weekends.
                if (!aGroup.ScheduleAllHours__c) {
                   weekend = (dayofWeekStr == 'Saturday' || dayofWeekStr == 'Sunday');
                   if (!weekend && aGroup.Weekday_Start__c != null && aGroup.Weekday_End__c !=null) {
                      night = (currTime < aGroup.Weekday_Start__c) || (currTime > aGroup.Weekday_End__c);
                   } else if (weekend && aGroup.Weekend_Start__c != null && aGroup.Weekend_End__c !=null) {
                      night = (currTime < aGroup.Weekend_Start__c) || (currTime > aGroup.Weekend_End__c);
                   }
                } // if (!aGroup.ScheduleAllHours__c
                System.debug('handleRoundRobin dayofWeekStr='+dayofWeekStr+' weekend='+weekend+' night='+night+' currTime='+currTime+' Weekday_Start__c='+aGroup.Weekday_Start__c+' Weekday_End__c='+aGroup.Weekday_End__c);
                /*
                //check to see if record falls during night hours during the week
                if(dayOfWeek>0 && dayOfWeek<6 && aGroup.Weekday_Start__c != null && aGroup.Weekday_End__c !=null){
                    night = (currTime < aGroup.Weekday_Start__c) || (currTime > aGroup.Weekday_End__c);
                    system.debug('nighttimeWeekday: '+ night + ' dayStart: '+aGroup.Weekday_Start__c+' dayEnd: '+aGroup.Weekday_End__c+' curr: '+currTime);
                }
                //check to see if record falls during night hours during the weekend
                else if((dayOfWeek==0 || dayOfWeek==6) && aGroup.Weekend_Start__c != null && aGroup.Weekend_End__c !=null){
                    night = (currTime < aGroup.Weekend_Start__c) || (currTime > aGroup.Weekend_End__c);
                    system.debug('nighttimeWeekend: '+ night + ' dayStart: '+aGroup.Weekend_Start__c+' dayEnd: '+aGroup.Weekend_End__c+' curr: '+currTime);
                }
                */
                //is it saturday or sunday
                //if(dayOfWeek==0 || dayOfWeek==6){
                //    weekend = true;
                //    system.debug('weekend: '+ weekend);
                //}
                //loop through all group members in the assignment group.  if the next person in line isn't eligble, we'll check the one after until we've ran through the list.
                for(Integer i=0;i<ags.size();i++){
                // next available assignee is at the 0 position in the list
                    ag = ags.remove(0);
                    system.debug('handleRoundRobin ag='+ag.Name);
                    // put it at the end of the list
                    ags.add(ag);
                    Integer round;
                    DateTime roundStart;
                    Boolean updateGroup = false;
                    Boolean weightingEnabled = (aGroup.Use_Weighting__c && 
                                                (!aGroup.Skip_Weighting_Nights_Weekends__c || 
                                                        (aGroup.Skip_Weighting_Nights_Weekends__c && !night && !weekend)));
                    //get the current round and roundStart time.  If those don't exist (new assignment group), set them.
                    if(weightingEnabled){
                        //start from current round
                        if(aGroup.Current_Weighting_Round__c !=null){
                            round = Integer.valueOf(aGroup.Current_Weighting_Round__c);
                        }
                        //start fresh
                        else{
                            round = 1;
                            aGroup.Current_Weighting_Round__c = round;
                            updateGroup = true;
                        }
                        //start from current round time                     
                        if(aGroup.Current_Weighting_Round_Time__c != null){
                            roundStart = aGroup.Current_Weighting_Round_Time__c;    
                        }
                        //start fresh
                        else{
                            roundStart = system.now();
                            aGroup.Current_Weighting_Round_Time__c = roundStart;
                            updateGroup = true;
                        }
                    }
                    system.debug('handleRoundRobin Round='+round+' level='+ag.Weighting_Level__c+' roundStart='+roundStart+' lastAssigned='+ag.Last_Assignment__c);
                    //check if the next person in line is set to receive a record via weighting
                    if(weightingEnabled && round!=null && roundStart!=null && ag.Weighting_Level__c != null){
                       if(round != null && Integer.valueOf(ag.Weighting_Level__c) >= round && ag.Last_Assignment__c < roundStart){
                          assignmentOkay = true;
                       }
                    }
                    //check if next person in line has been scheduled for the current day and time.
                    if(((weightingEnabled && assignmentOkay) || !aGroup.Use_Weighting__c || !weightingEnabled) && aGroup.Use_Scheduler__c == true){
                       if(night || (aGroup.Weekend_Always_On__c && weekend)){
                          system.debug('handleRoundRobin assignmentOkay for night or weekend');
                          assignmentOkay = true;
                       } else {
                          TimeWrapper timeWrap = getTimePeriods(ag, dayofWeekStr, yesterdayStr);
                          assignmentOkay = timeWrap.isTimeInRange(currTime);
                       }
                       
                       /*
                       Time startTime;
                       Time endTime;
                       Time breakStart;
                       Time breakEnd;
                       
                       if(String.isNotBlank(dayofWeekStr)){
                         
                         String startString = dayofWeekStr+'_1__c';
                         String breakStartString = dayofWeekStr+'_2__c';
                         String breakEndString = dayofWeekStr+'_3__c';
                         String endString = dayofWeekStr+'_4__c';
                         
                         startTime = (Time)ag.get(startString);
                         breakStart = (Time)ag.get(breakStartString);
                         breakEnd = (Time)ag.get(breakEndString);
                         endTime = (Time)ag.get(endString);
                         
                         //if only the first two fields are entered
                         if(breakStart!=null && endTime == null){
                            endTime = breakStart;
                            breakStart = null;
                         }
                       } // if(String.isNotBlank(dayofWeekStr
                     
                       // TODO for overnight, have to look at previous day to see if it goes overnight.
                       // Monday 8pm-5am, technically midnight-5am are Tuesday hours.
                       // If the current time is less than the start time, look at the previous day's time. See if there is one of the times where the
                       // end date is less than the start time. We'll assume the end date is for today, and the start time is midnight.
                       // So if a record comes in a 4am on Tuesday, and Tuesday's start time is 8am, we'll look at Monday's time. If the last time 
                       // on Monday spans into Tuesday, then we'll use that. 

                        
                       system.debug('handleRoundRobin '+ag.User__r.Name+' dayofWeekStr='+dayofWeekStr+' time='+currTime +' startTime=' +startTime+' breakStart='+breakStart+' breakEnd='+breakEnd+' endTime='+endTime);
                       if(night || (aGroup.Weekend_Always_On__c && weekend)){
                          system.debug('handleRoundRobin assignmentOkay for night or weekend');
                          assignmentOkay = true;
                       } else if (startTime != null && endTime != null) {
                          if ((breakStart == null && startTime < endTime && currTime > startTime && currTime < endTime)
                                  || (breakStart != null && startTime < breakStart && currTime > startTime && currTime < breakStart)
                                  || (breakEnd != null && breakEnd < endTime && currTime > breakEnd && currTime < endTime)) {
                             // the start time is less than the end time (it's the same day)
                             assignmentOkay = true;        
                          } else if ((breakStart == null && startTime > endTime && (currTime > startTime || currTime < endTime))
                                  || (breakStart != null && startTime > breakStart && (currTime > startTime || currTime < breakStart))
                                  || (breakEnd != null && breakEnd > endTime && (currTime > breakEnd || currTime < endTime))) {
                          }
                       } else if ((breakStart == null && startTime < endTime && currTime > startTime && currTime < endTime)
                                  || (breakStart != null && startTime != null && startTime < breakStart && currTime > startTime && currTime < breakStart)
                                  || (breakEnd != null && breakEnd < endTime && currTime > startTime && currTime < breakStart)) {
                          assignmentOkay = true;
                       }
                       /*
                       //check times for user with break
                       else if(startTime!=null && breakStart!=null && breakEnd!=null && endTime!=null && !night && !aGroup.Weekend_Always_On__c){
                           assignmentOkay = (startTime < currTime && breakStart > currTime) || (breakEnd < currTime && endTime > currTime);
                           system.debug('handleRoundRobin breaktimeactive='+ assignmentOkay+' start='+startTime+' curr='+currTime);
                       }
                       //check times for user without break
                       else if (startTime!=null && endTime!=null && !night && !aGroup.Weekend_Always_On__c){
                           assignmentOkay = (startTime < currTime) && endTime > currTime;
                           system.debug('handleRoundRobin timeactive='+ assignmentOkay);
                       }
                       else if (startTime == null && endTime == null && !night && !aGroup.Weekend_Always_On__c){
                           assignmentOkay = false;
                           system.debug('no start and no end time='+ assignmentOkay);
                       }
                       */
                    }//if(using scheduler
                    Integer queueSize = ags.Size()-1;
                    //if we've made it to the end of the list and nobody has been assigned, try the next level of people
                    system.debug('jsh assigmentOkay: '+assignmentOkay+' i: '+i+' round: '+round+' useWeighting: '+weightingEnabled);
                    if(!assignmentOkay && i == queueSize && aGroup != null && aGroup.Use_Weighting__c == false && aGroup.Round_Robin_Delegate__c !=null){
                        useDelegate = true;
                    }
                    else if(!assignmentOkay && i == queueSize && round != null && aGroup != null && weightingEnabled == true){
                        //get the values of the weighting level field
                        List<Schema.PicklistEntry> roundValues = Assignment_Groups__c.Weighting_Level__c.getDescribe().getPicklistValues();
                        Integer[] roundList = new Integer[]{};
                        for(Schema.PicklistEntry rv:roundValues){
                            Integer intValue = Integer.valueOf(rv.getValue());
                            roundList.add(intValue);
                        }
                        //sort the list so we can get the latest round and reset the round if we're at the last round.  If not, increase round by one
                        if(!roundList.isEmpty()){
                            roundList.sort();
                            system.debug('jsh roundlist: '+roundList);
                            Integer maxNumber = roundList.size()-1;
                            if(roundList.get(maxNumber)==round){
                                if(!safetySwitch){
                                    /**** DANGER! the following line can cause recursion if something's not right****/
                                    //reset the loop so we can try all the users at the next round
                                    i = -1;
                                    round = roundList.get(0);
                                    safetySwitch = true;
                                    updateGroup = true;
                                }
                                else if (safetySwitch && aGroup.Round_Robin_Delegate__c != null){
                                    useDelegate = true;
                                    break;
                                }
                                
                            }
                            else{
                                /**** DANGER! the following line can cause recursion if something's not right****/
                                //reset the loop so we can try all the users at the next round
                                i = -1;
                                round++;
                                updateGroup = true;
                            }
                        }
                        roundStart = system.now();
                        
                    }//if(!assignmentOkay
                    //if the assignment group's round or roundStart time needs to be updated, check to see if it is already set to be updated and make sure it
                    //has the most recent values.
                    if(updateGroup){
                        if(groupsToUpdate == null){
                            groupsToUpdate = new Map<Id,Assignment_Group_Name__c>();
                        }
                        if(groupsToUpdate.containsKey(aGroup.Id)){
                            Assignment_Group_Name__c grp = groupsToUpdate.get(aGroup.Id);
                            grp.Current_Weighting_Round__c = round;
                            grp.Current_Weighting_Round_Time__c = roundStart;
                        }
                        else{
                            aGroup.Current_Weighting_Round__c = round;
                            aGroup.Current_Weighting_Round_Time__c = roundStart;
                            groupsToUpdate.put(aGroup.Id,aGroup);
                        }
                    }    
                    if(assignmentOkay){
                       assigned=true;
                       break;
                    }//if
                    else{
                        system.debug('User: '+ag.User__r.Name+' was not eligible for assignment!');
                        assigned=false;
                    }//else
                }//for(Integer i
                //if no active users and object is a contact, use the assignment groups' delegate. Set on assignment group.
                if(!assignmentOkay && useDelegate){
                    //if no eligible user is found, pull delegate from ag and assign contact to it.
                    system.debug('delegate: '+aGroup.Round_Robin_Delegate__c);
                    s.put('OwnerId',aGroup.Round_Robin_Delegate__c);
                    delegated=true;
                    if(s.getSObjectType().getDescribe().getName() == Referral__c.getSObjectType().getDescribe().getName()){
                        system.debug('setting Notify Owner');
                        s.put('User__c',aGroup.Round_Robin_Delegate__c);
                        ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                        s.put('NotifyOwner__c',true);
                        //ChatterMessageSend.notifyOwnerIdSet.add((Id)s.get('Id'));
                        if(night || weekend){
                            s.put('Avoid_Auto_Reassign__c',true);
                        }
                        else{
                            s.put('Avoid_Auto_Reassign__c',false);
                        }
                    }
                 }
             }
             //if not using the scheduler or weighting, use next person in line
             else{
                 // next available assignee is at the 0 position in the list
                ag = ags.remove(0);
                // put it at the end of the list
                ags.add(ag);
                //Assignment_Groups__c ag = ags[math.mod(idx, ags.size())];
                assigned=true;
             }
            
            if(ag!=null && assigned && !delegated){
    
                //Set last assignment datetime
                DateTime now = DateTime.now();
                //if(oType != 'Event'){
                //Assign User to Case/Lead/Contact as the new owner
                System.debug('>>>>>Owner changed for '+oType+' '+ s.get('Id') + ' from '+queueId+' to '+ ag.User__c);
                s.put('OwnerId',ag.User__c);
                if(mothership!=null){
                    if(mothership.RR_Last_Routed__c==null){
                        mothership.RR_Last_Routed__c=now;
                        
                        String timeframe;
                        Integer currentHour = now.hour();
                        if(currentHour == 0){
                            timeframe = '12 - 1 AM';
                        }
                        else if(currentHour == 11){
                            timeframe = '11 - 12 PM';
                        }
                        else if(currentHour == 12){
                            timeframe = '12 - 1 PM';
                        }
                        else if(currentHour == 23){
                            timeframe = '11 - 12 AM';
                        }
                        else if(currentHour < 12){
                            timeframe = string.valueOf(currentHour)+' - '+string.valueOf(currentHour+1)+' AM';
                        }
                        else if(currentHour > 12){
                            timeframe = string.valueOf(currentHour-12)+' - '+string.valueOf(currentHour-11)+' PM';
                        }
                        mothership.RRTimeframe__c = timeframe!=null?timeframe:null;
                    }
                    if(mothership.Original_Owner__c==null){
                        mothership.Original_Owner__c=ag.User__r.Name;
                    }
                    updateMotherMap.put(mothership.Id,mothership);
                }
                if(s.getSObjectType().getDescribe().getName() == Referral__c.getSObjectType().getDescribe().getName()){
                    system.debug('setting Notify Owner');
                    s.put('User__c',ag.User__c);
                    ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                    s.put('NotifyOwner__c',true);
                    //ChatterMessageSend.notifyOwnerIdSet.add((Id)s.get('Id'));
                    if(night || weekend){
                        s.put('Avoid_Auto_Reassign__c',true);
                    }
                    else{
                        s.put('Avoid_Auto_Reassign__c',false);
                    }
                    Id acctId = (Id)s.get('Account__c');
                  if(String.valueOf(s.get('Referral_Type__c')) == ReferralController.REF_INTERNAL && acctId!=null){
                   AccountTeamMember atm = new AccountTeamMember();
                   atm.AccountId = acctId;
                   atm.TeamMemberRole = ReferralController.REF_INTERNAL;
                   atm.UserId = ag.User__c;
                   atm.AccountAccessLevel='Edit';
                   atm.ContactAccessLevel='Edit';
                   atm.OpportunityAccessLevel='Read';
                   atms.add(atm);
                  }
                }
                //}
                ag.Last_Assignment__c = now;
                ag.Millisecond__c = now.millisecondGMT();
                
                updateAssignmentGroups.put(ag.Id,ag);
            }//if(ag!null
            
         } // if (ags != null
         //if nobody is active and there's a delegate, send to delegate INC1466358
         else if((ags == null || (ags != null && ags.isEmpty())) && aGroup!=null && aGroup.Round_Robin_Delegate__c !=null){
            system.debug('delegate: '+aGroup.Round_Robin_Delegate__c);
            s.put('OwnerId',aGroup.Round_Robin_Delegate__c);
            if(s.getSObjectType().getDescribe().getName() == Referral__c.getSObjectType().getDescribe().getName()){
                system.debug('setting Notify Owner');
                s.put('User__c',aGroup.Round_Robin_Delegate__c);
                ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                s.put('NotifyOwner__c',true);
            }
         }
               
      } // for (Sobject s : objects

      // List/Array for DML update
      List<Assignment_Groups__c> updateAGs = updateAssignmentGroups.values();

      System.debug('>>>>>Update Assignment Groups: '+updateAGs);   
      
      ChatterMentionPost.checkPostFeedElements();
      
      // Update Assignment Group current round
      if(groupsToUpdate != null && !groupsToUpdate.isEmpty()){
         DmlHelper.performDML2(groupsToUpdate.values(), DmlHelper.DML_UPDATE, 'RoundRobin', 'handleRoundRobin', 'Update Assignment_Group_Name__c records', false);
      }
      
      // Update group member assignments that were used
      if (!updateAGs.isEmpty()) {
         DmlHelper.performDML2(updateAGs, DmlHelper.DML_UPDATE, 'RoundRobin', 'handleRoundRobin', 'Update Assignment_Groups__c records', false);
      } // if (!updateAG.isEmpty
      
      if (!atms.isEmpty()) {
         DmlHelper.performDML2(atms, DmlHelper.DML_INSERT, 'RoundRobin', 'handleRoundRobin', 'Inserting Account Share Records', false);
      } // if (!updateAG.isEmpty

      ErrorLog.checkSave();

   } // handleRoundRobin
   
   public class DateRangeWrap {
      public Time startTime;
      public Time endTime;
      public DateRangeWrap(Time p_startTime, Time p_endTime) {
         startTime = p_startTime;
         endTime = p_endTime;
         System.debug('DateRangeWrap new range added '+startTime+' to '+endTime);
      }
   } // class DateRangeWrap
    
   public class TimeWrapper {
      public void addTime(Time startTime, Time endTime) {
         DateRangeWrap drw = new DateRangeWrap(startTime,endTime);
         dateRanges.add(drw);
      }
      public DateRangeWrap[] dateRanges = new DateRangeWrap[]{};
      public Boolean isTimeInRange(Time checkTime) {
         Boolean inRange = false;
         if (checkTime != null) {
            for (DateRangeWrap drw : dateRanges) {
               if (checkTime >= drw.startTime && checkTime <= drw.endTime) {
                  inRange=true;
                  break;
               }
            } // for (DateRangeWrap drw : dateRanges
         } // if (checkTime != null
         return inRange;
      }
   } // class TimeWrapper
    
   public static TimeWrapper getTimePeriods(Assignment_Groups__c ag, String dayofWeekStr, String yesterdayStr) {
      TimeWrapper wrap = new TimeWrapper(); 
      // check the times from yesterday to see if they have overnight hours
      Time startTimePrev = (Time)ag.get(yesterdayStr+'_1__c');
      Time breakStartPrev = (Time)ag.get(yesterdayStr+'_2__c');
      Time breakEndPrev = (Time)ag.get(yesterdayStr+'_3__c');
      Time endTimePrev = (Time)ag.get(yesterdayStr+'_4__c');
      System.debug('getTimePeriods startTimePrev='+startTimePrev+' breakStartPrev='+breakStartPrev+' breakEndPrev='+breakEndPrev+' endTimePrev='+endTimePrev);
      checkYesterdayTime(wrap, startTimePrev, breakStartPrev);
      checkYesterdayTime(wrap, breakEndPrev, endTimePrev);
      
      Time startTime = (Time)ag.get(dayofWeekStr+'_1__c');
      Time breakStart = (Time)ag.get(dayofWeekStr+'_2__c');
      Time breakEnd = (Time)ag.get(dayofWeekStr+'_3__c');
      Time endTime = (Time)ag.get(dayofWeekStr+'_4__c');
      System.debug('getTimePeriods startTime='+startTime+' breakStart='+breakStart+' breakEnd='+breakEnd+' endTime='+endTime);
      checkTodayTime(wrap, startTime, breakStart);
      checkTodayTime(wrap, breakEnd, endTime);
      
      return wrap;
   } // getTimePeriods
    
   public static void checkYesterdayTime(TimeWrapper wrap, Time startTime, Time endTime) {
      if (startTime != null && endTime != null && endTime < startTime) {
         // if the end time is less than the start time then we're probably looking at an overnight shift. 
         // We'll use midnight until the breakStartPrev for the current day ex 8pm-5am
         wrap.addTime(Time.newInstance(0,0,0,0), endTime);
      }
   } // checkYesterdayTime
    
   public static void checkTodayTime(TimeWrapper wrap, Time startTime, Time endTime) {
      if (startTime != null && endTime != null) {
         if (startTime < endTime) {
            // this is a normal shift, like 8am-5pm
            wrap.addTime(startTime, endTime);
         } else if (endTime < startTime) {
            // this is an overnight shift, like 8pm-5am.
            // We'll only account up until midnight
            wrap.addTime(startTime,Time.newInstance(23,59,59,59));
         }
      }
   } // checkTodayTime
    
   // remove the Assignment Group Queues from the cache
   public static void clearAssignGroupQueueCache() {
      CacheManager.removeOrg(CACHE_KEY);
   } // clearReferralPartnerCache
   
} // class RoundRobin