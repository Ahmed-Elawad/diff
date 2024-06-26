/* 
 * delete future dated recurring activity
 *
 * History
 * -------
 * 04/17/2012 Dan Carmen   Created
 *
 */
global with sharing class ActivityDeleteRecurring {

   @future
   static webservice void checkActivity(Id[] userIds) {
      processEvents(userIds);
      processTasks(userIds);
   } // checkActivity

   static void processEvents(Id[] userIds) {
   	// find recurring events
   	for (Event[] evnts : [Select Id, OwnerId
   	                            ,ActivityDate
   	                        From Event
   	                       Where IsRecurrence=false
   	                         and RecurrenceActivityId != null
   	                         and OwnerId in :userIds
   	                         and ActivityDate > :Date.today()
   	                        for update]) {
   	   
   	   // delete any events that meet the criteria         	
         delete evnts;
      } // for (Event[] evnts
   } // processEvents

   static void processTasks(Id[] userIds) {
      // find recurring tasks
      for (Task[] tsks : [Select Id, OwnerId
                                  ,ActivityDate
                              From Task
                             Where IsRecurrence=false
                               and RecurrenceActivityId != null
                               and OwnerId in :userIds
                               and ActivityDate > :Date.today()
                              for update]) {
         
         // delete any events that meet the criteria           
         delete tsks;
      } // for (Task[] tsks
   } // processTasks


 /*
 
 Select e.Type, e.Subject, e.RecurrenceType, e.RecurrenceStartDateTime, e.RecurrenceMonthOfYear, e.RecurrenceInterval, e.RecurrenceInstance, e.RecurrenceEndDateOnly, e.RecurrenceDayOfMonth, e.RecurrenceActivityId, e.IsRecurrence, e.Id, e.ActivityDate From Event e where ownerid='005S0000003l37M'
 
 Select t.Type, t.RecurrenceStartDateOnly, t.RecurrenceEndDateOnly, t.RecurrenceActivityId, t.IsRecurrence, t.CallType, t.ActivityDate From Task t where ownerid='005S0000003l37M'
 */
 
} // ActivityDeleteRecurring