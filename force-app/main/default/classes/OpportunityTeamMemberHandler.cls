/* Helper method for opportunityTeamMember
   
  History
  -------
  01/14/2021 Pradeep Garlapaati       Created
  10/06/2023 Dan Carmen               Clean up CheckTeamMemberInvolved method
  
 */

public class OpportunityTeamMemberHandler {
    
    public static void NotifySRWhenRemovedFromOpp(list<OpportunityTeamMember> opptm)
    {
      /***BAU Changes */
      Map<Id,Id> mapUseridOpportunityid=new Map<Id,Id>();
      Map<Id,Id> mapOpportunityidUserid=new Map<Id,Id>();
     /***BAU Changes */
         for(OpportunityTeamMember oppt : opptm)
        {
              if(oppt.TeamMemberRole == 'Pre-Sales Consultant')
              {
                list<id> userids = new list<id>();
                userids.add(OPPT.UserId);
                String postText = ' has been deleted from the opportunity';
                ChatterMentionPost.createChatterMentionPost(oppt.OpportunityId,userids ,  new String[]{ postText},true,false);
              }
              /***BAU Changes */
              if(oppt.TeamMemberRole == 'Oasis SDR'){
                mapUseridOpportunityid.put(oppt.UserId,oppt.OpportunityId);
                mapOpportunityidUserid.put(oppt.OpportunityId,oppt.UserId);
              }
              /***BAU Changes */
         }
          /***BAU Changes */
        if(mapOpportunityidUserid!=null && !mapOpportunityidUserid.isEmpty()){
          for(opportunityTeamMember oppt:[select userid,opportunityid,TeamMemberRole,Demo_date__c,Prospect_Ownership__c,OpportunityAccessLevel,user.name,User.ManagerId,Opportunity.Name,user.Manager.Name  from opportunityTeamMember where opportunityid IN :mapOpportunityidUserid.keyset() AND  TeamMemberRole='Oasis SDR']){
            if(mapUseridOpportunityid.containsKey(oppt.userid)){
              list<id> userids = new list<id>();
              userids.add(OPPT.UserId);
              userids.add(oppt.User.ManagerId);
              String postText ='\n'+oppt.user.name+' has been removed from this Opportunity Team.'+'\n'+'Opportunity Name:'+oppt.Opportunity.Name+'\n'+'Opportunity URL:'+Url.getOrgDomainUrl().toExternalForm()+'/'+oppt.opportunityid;
              ChatterMentionPost.createChatterMentionPost(oppt.OpportunityId,userids ,  new String[]{ postText},true,false);
            }
            
          }
        }
         /***BAU Changes */
        ChatterMentionPost.postBatchFeedElements(); 
    }
    public static void CheckTeamMemberInvolved(list<OpportunityTeamMember> opptm) {
       set<id> oppids = new set<id>();
       String[] SalesEngineerLabel = Label.SalesEngineerLabelToUpdateDemoDateAndCreateOpptyTeamMem.split(',');
       for (OpportunityTeamMember otm : opptm) {
          if (SalesEngineerLabel.contains(otm.TeamMemberRole))  {
             oppids.add(otm.OpportunityId);
          }
       } // for (OpportunityTeamMember otm : oppt
       if (!oppids.isEmpty()) {
          // get the opportunities that don't already have the flag set
          Opportunity[] opps = [Select Id, Name, Sales_Engineer_Involved__c from Opportunity where Id in :oppids and Sales_Engineer_Involved__c=false];
          for (Opportunity opp : opps) {
             opp.Sales_Engineer_Involved__c = true;
          }
          OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
          DmlHelper.performDML2(opps, DmlHelper.DML_UPDATE, 'OpportunityTeamMemberHandler', 'CheckTeamMemberInvolved', 'Update Sales_Engineer_Involved__c on Oppty', true);
       } // if (!oppids.isEmpty
        
    } // CheckTeamMemberInvolved

        /**BAU Changes**/
        public static void insertProspectClientTeamMember(list<OpportunityTeamMember> opptm){
          //OpportunityId
          //UserId 
          set<Id> setOpportunityId=new set<Id>();
          Map<Id,Id> mapOpportunityidUserid=new Map<Id,Id>();
          for(OpportunityTeamMember otm:opptm){
            if(otm.TeamMemberRole == 'Oasis SDR'){
              setOpportunityId.add(otm.OpportunityId);
              mapOpportunityidUserid.put(otm.OpportunityId,otm.UserId);
            }
          }
          //getting the account ids
          List<Opportunity> lstOpportunities=new List<Opportunity>();
          if(setOpportunityId!=null && !setOpportunityId.isEmpty()){
            lstOpportunities=[Select id,AccountId from Opportunity where id In:setOpportunityId];
          }
          //creating the ATM data
          List<AccountTeamMember> lstAccountTeamMember=new List<AccountTeamMember>();
          if(lstOpportunities.size()>0){
            for(Opportunity opp:lstOpportunities){
              AccountTeamMember atm = new AccountTeamMember();
              atm.AccountId =opp.AccountId;
              atm.TeamMemberRole = 'Oasis SDR';
              atm.UserId=mapOpportunityidUserid.get(opp.id);
              atm.Opportunity_Team_Start_Date__c=Datetime.now();
              lstAccountTeamMember.add(atm);
            }
    
          }
          //inserting
          if(lstAccountTeamMember!=null && !lstAccountTeamMember.isEmpty()){
            //insert lstAccountTeamMember;
            DmlHelper.performDML2(lstAccountTeamMember, DmlHelper.DML_INSERT, 'OpportunityTeamMemberHandler', 'insertProspectClientTeamMember', 'Insert ATMs', false);
          }
        }
        /**BAU Changes**/

}