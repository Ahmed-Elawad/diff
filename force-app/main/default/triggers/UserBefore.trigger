/* 
 * House all of the before trigger actions on the User record.
   Migrated code from UserCheckPersonId trigger.
   Migrated code from UpdateOrgInfoByUser trigger. 
 *
 * History
 * -------
 * 03/08/2011 Dan Carmen     Created
   04/17/2012 Dan Carmen     Added code to delete future recurring activities.
   12/19/2012 Dan Carmen     If a User is inactivated, make sure they are not a DSA on another User record.
   01/29/2013 Dan Carmen     Set so EBS Username will not populate on Users without a role.
   03/21/2013 Dan Carmen     Added check to populate new Job Name field
   03/02/2015 Dan Carmen     Changed checkForDsaField to checkInactiveUser. Added extra deletes.
   05/18/2016 Dan Carmen     Expand the list of division names when setting DSA.
   07/11/2016 Dan Carmen     Added additional debugging - skip inactive call from form.
   04/03/2017 Justin Stouffer   Added Added AD_UserName__c.
   10/23/2017 Jacob Hinds    Added in forecast sharing
   01/24/2019 Dan Carmen     Clear out CallCenterId when a user goes inactive
   01/07/2020 Josh Cartwright add or clear federation id if active status changes  
   06/04/2020 Dan Carmen     Remove code from Trigger and move to UserTriggerMethods
   06/06/2024 Dan Carmen     Add call to TriggerMethods
   
 */
trigger UserBefore on User (before insert, before update) {
   // TODO - this direct call should be eventually removed but there are a lot of dependencies to change this over for testing so 
   // leaving in the trigger for now - DC, 6/6/2024
   new UserTriggerMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
   TriggerMethods.checkBeforeLoop('UserBefore', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

} // trigger UserBefore