/*  
    Perform any validations needed on Referral Account object
	validateDeletions called by ReferralAccountBefore trigger to see if ok to flag RA for deletion
	   
  History
  -------
  04/10/2013 Cindy Freeman   Created
  08/23/2016 Dan Carmen      Update Code
  04/12/2022 Dan Carmen      Increment API
  
 */


public with sharing class ReferralAccountValidation {
	private static String tasksTimeFrame = 'ActivityDate > LAST_N_YEARS:3';				// use to pull any task within the last 3 calendar years
	private static String eventsTimeFrame = 'ActivityDateTime > LAST_N_YEARS:3';		// use to pull any event within the last 3 calendar years
	private static Boolean useTimeFrame;
	
	
	// pass in Ids of Referral Accounts that have been flagged To Be Deleted
	// add Error to each of the Referral Accounts that shouldn't be deleted because they have related contacts, opptys or activities
	public static void validateDeletions(Map<Id,Referral_Account__c> deleteRefAcctMap, Boolean useTimeLimit) {
		useTimeFrame = useTimeLimit;
		
		checkForRefCtcts(deleteRefAcctMap);
		checkForOpptys(deleteRefAcctMap);
		checkForActivities(deleteRefAcctMap);
		
			
	} // validateDeletions
	
	
	private static void markErrors(Map<Id,Referral_Account__c> deleteRefAcctMap, Set<Id> errorIdSet, String errorMessage) {
	   for (Id errorId : errorIdSet) {
	      Referral_Account__c refAcct = deleteRefAcctMap.remove(errorId);
	      if (refAcct != null) {
	         refAcct.To_Be_Deleted__c.addError(errorMessage);
	         refAcct.To_Be_Deleted__c = false;
	      }
	   } // for
	} // markErrors

			
	private static void checkForRefCtcts(Map<Id,Referral_Account__c> deleteRefAcctMap) {
	   
	   if (!deleteRefAcctMap.isEmpty()) {
         // look for any referral contacts
         Map<Id,Referral_Account__c> refAcctMap = new Map<Id, Referral_Account__c>([Select Id, Name
	                                                  From Referral_Account__c
	                                                 Where Id in (Select Referral_Account__c
	                                                                From Referral_Contact__c
	                                                               Where To_Be_Deleted__c = false
	                                                                 and Referral_Account__c in :deleteRefAcctMap.keySet())]);
         markErrors(deleteRefAcctMap, refAcctMap.keySet(), 'Cannot be deleted due to related Referral Contacts');
	   } // if (!deleteRefAcctMap.isEmpty
	} // checkForRefCtcts
	
	
	private static void checkForOpptys(Map<Id,Referral_Account__c> deleteRefAcctMap) {
	   if (!deleteRefAcctMap.isEmpty()) {
         // look for any opportunities linked to these ref accts 
	      Map<Id,Referral_Account__c> refAcctMap = new Map<Id, Referral_Account__c>([Select Id, Name
	                                                 From Referral_Account__c
	                                                Where Id in (Select Referral_Account__c
	                                                                From Opportunity
	                                                               Where Referral_Account__c in :deleteRefAcctMap.keySet())]);
         markErrors(deleteRefAcctMap, refAcctMap.keySet(), 'Cannot be deleted due to related Opportunities');

	   } // if (!deleteRefAcctMap.isEmpty
	} // checkforOpptys
	
	public static void checkForActivities(Map<Id,Referral_Account__c> deleteRefAcctMap) {
	   Set<Id> foundIdSet = checkForActivity(ObjectHelper.OBJECT_EVENT, deleteRefAcctMap.keySet(), useTimeFrame);
	   markErrors(deleteRefAcctMap, foundIdSet, 'Cannot be deleted due to related Activity');
	   foundIdSet = checkForActivity(ObjectHelper.OBJECT_TASK, deleteRefAcctMap.keySet(), useTimeFrame);
      markErrors(deleteRefAcctMap, foundIdSet, 'Cannot be deleted due to related Activity');
	} // checkForActivities
	
	 
	public static Set<Id> checkForActivity(String activityType, Set<Id> keySet, Boolean p_useTimeFrame) {
	   Set<Id> returnSet = new Set<Id>();
	   if (keySet.isEmpty()) {
	      return returnSet;
	   }
	   String query = null;
	   if (activityType == ObjectHelper.OBJECT_TASK) {
	      query = 'SELECT Id, WhatId, WhoId, ActivityDate from Task where WhatId in :checkIdSet';
	   } else if (activityType == ObjectHelper.OBJECT_EVENT) {
         query = 'SELECT Id, WhatId, WhoId, ActivityDate from Event where WhatId in :checkIdSet';
	   }
	   if (String.isBlank(query)) {
	      System.debug('checkForActivity query not found for '+activityType);
	      return returnSet;
	   }
	   if (p_useTimeFrame) {
	      query += ' AND '+tasksTimeFrame;
	   }
      Set<Id> checkIdSet = new Set<Id>();
      checkIdSet.addAll(keySet);
      SObject[] activities = Database.query(query);
      for (SObject rec : activities) {
         returnSet.add((Id)rec.get('whatid'));
      }
      return returnSet;
	} // checkForActivity
	 
	 /*
	private static void checkForActivities(Map<Id,Referral_Account__c> deleteRefAcctMap) {
	   if (!deleteRefAcctMap.isEmpty()) {
	      Set<Id> checkIdSet = new Set<Id>();
	      checkIdSet.addAll(deleteRefAcctMap.keySet());
		   // look for any events or tasks for these ref accts
		
         String eventSOQL = 'SELECT Id, WhatId, WhoId, ActivityDateTime, Description from Event where WhatId in :checkIdSet';
		   if (useTimeFrame) {
		      eventSOQL += ' AND ' + eventsTimeFrame;
		   }
		
         Event[] refEvents = Database.query(eventSOQL);
         Set<Id> whatIdSet = new Set<Id>();
         for (Event evt : refEvents) {
            whatIdSet.add(evt.WhatId);
         }
         markErrors(deleteRefAcctMap, whatIdSet, 'Cannot be deleted due to related Events');
         
      } // if (!deleteRefAcctMap
		if (!deleteRefAcctMap.isEmpty()) {
         Set<Id> checkIdSet = new Set<Id>();
         checkIdSet.addAll(deleteRefAcctMap.keySet());

			String taskSOQL = 'SELECT Id, WhatId, WhoId, ActivityDate, IsClosed from task where whatId in :checkIdSet';
			if (useTimeFrame) {
			   taskSOQL = taskSOQL + ' AND ' + tasksTimeFrame;
			}
			Task[] refTasks = Database.query(taskSOQL);
         Set<Id> whatIdSet = new Set<Id>();
         for (Task tsk : refTasks) {
            whatIdSet.add(tsk.WhatId);
         }

         markErrors(deleteRefAcctMap, whatIdSet, 'Cannot be deleted due to related Tasks');
      } // if (!deleteRefAcctMap
		
	} // checkforActivities
	*/
	
} // class ReferralAccountValidation