/* 
 *  A trigger for the Account Team member object
 *   
 * History
 * -------
 *03/22/2022 Susmitha Somavarapu     created
 */
trigger AccountTeamMemberAfterTrigger on AccountTeamMember (after insert) {
    //Declaration of Account Team Member  object objHandler.
    AccountTeamMemberTriggerHandler objHandler = new AccountTeamMemberTriggerHandler();
    if(trigger.isAfter && trigger.isInsert){
    objHandler.onAfterInsert(trigger.new, trigger.newMap);
    }
   }