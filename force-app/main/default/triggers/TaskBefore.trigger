/** Handle before actions on the task
 *
 * History
 * -------
 * 02/23/2015 Dan Carmen         Created.
   01/16/2018 Dan Carmen         Added in before insert
   09/20/2018 Cindy Freeman		Populating Referral_Contact__c lookup field from WhatId if task is Related To referral contact
   12/19/2018 Dan Carmen         Move logic to TaskHelper
   
 */
trigger TaskBefore on Task (before insert, before update) {
   if (!TaskHelper.SKIP_TRIGGERS) {
      TaskHelper.checkNSSTasksFromBeforeTrigger((Task[])Trigger.new, (Map<Id,Task>)Trigger.oldMap);
      TriggerMethods.checkBeforeLoop('TaskBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);
   }
} // TaskBefore