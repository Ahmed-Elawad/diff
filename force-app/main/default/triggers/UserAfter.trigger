/*
  * The place to put all after insert and update triggers for User object
  *
  *  History
  *  -------
  *  10/10/2012 Cindy Freeman   created
     01/19/2015 Dan Carmen      Check if user role changes
     07/11/2016 Dan Carmen   Add some additional debugging
     05/25/2017 Cindy Freeman   added code so if the MMS user's zone changes, it will update their quotes     
     05/21/2018 Jake Hinds      When MMS-ASO Partner changes, update accounts that mms rep owns
     01/15/2020 Dan Carmen      Add call to UserHelper.checkUsersAfter
     06/04/2020 Dan Carmen      Move logic to UserTriggerMethods
     06/06/2024 Dan Carmen      Add call to TriggerMethods

  */

trigger UserAfter on User (after insert, after update) {
   // TODO - this direct call should be eventually removed but there are a lot of dependencies to change this over for testing so 
   // leaving in the trigger for now - DC, 6/6/2024
   new UserTriggerMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
   TriggerMethods.checkBeforeLoop('UserBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

} // trigger UserAfter