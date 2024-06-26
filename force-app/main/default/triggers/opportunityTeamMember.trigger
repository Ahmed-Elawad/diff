/* 

History
-------
01/12/2021 Pradeep Garlapaati    Created
 
*/

trigger opportunityTeamMember on OpportunityTeamMember (before delete, before insert, after insert) {
    if(trigger.isbefore && trigger.isdelete)
    {
         list<OpportunityTeamMember> oppt = new list<OpportunityTeamMember>();
         oppt =  (list<OpportunityTeamMember>)trigger.old;
         opportunityTeamMemberHandler.NotifySRWhenRemovedFromOpp(oppt);
    }
    if(trigger.isAfter && trigger.isInsert)
    {
         list<OpportunityTeamMember> oppt = new list<OpportunityTeamMember>();
         oppt =  (list<OpportunityTeamMember>)trigger.new;
        System.debug('oppt = '+oppt);
         opportunityTeamMemberHandler.CheckTeamMemberInvolved(oppt);
         /**BAU Changes**/
         opportunityTeamMemberHandler.insertProspectClientTeamMember(oppt);
         /**BAU Changes**/
    }
}