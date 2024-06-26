/** Trigger for RAT


 * History
 * -------
   04/27/2020 Jake Hinds       Created
   05/26/2020 Jake Hinds       Adding method for duplicate check
   12/29/2021 Dan Carmen       Move all logic to ReferralAccountTeamMethods

*/
trigger ReferralAccountTeamTrigger on Referral_Account_Team__c (before insert,after insert,before update, after update,after delete) {
    ReferralAccountTeamMethods.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);

} // trigger ReferralAccountTeamTrigger