/* Test methods for the OpptTeamMmemberHandler class
   
  History
  -------
  01/15/2021 Pradeep Garlapaati       Created
  10/06/2023 Dan Carmen               Clean up CheckTeamMemberInvolved method
  
 */

@istest
public class OpportunityTeamMemberHandlerTest {
    
    public static testmethod void oppTMHandlerTest() {
       Account acct = new Account(Name='Test Account'); 
       ZipCheckOwner.SKIP_TRIGGERS=true;
       insert acct;
       
       Opportunity opp1 = new Opportunity(Name='Opp1a',AccountId=acct.Id, StageName='Pending',CloseDate=Date.today().addDays(7),OpportunityType__c='TestType1');
       insert opp1;
       User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 4];

       String[] SalesEngineerLabel = Label.SalesEngineerLabelToUpdateDemoDateAndCreateOpptyTeamMem.split(',');
        
       OpportunityTeamMember otm1 = new OpportunityTeamMember(OpportunityId = opp1.id, UserId = users[0].id, TeamMemberRole = SalesEngineerLabel[0]);
       OpportunityTeamMember otm2 = new OpportunityTeamMember(OpportunityId = opp1.id, UserId = users[1].id, TeamMemberRole = 'Oasis SDR');
       OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId = opp1.id, UserId = users[2].id, TeamMemberRole = 'Pre-Sales Consultant');
       insert new OpportunityTeamMember[]{otm1,otm2,otm3};
       
       test.startTest();
       delete new OpportunityTeamMember[]{otm2,otm3};
       test.stopTest();
 
    } // oppTMHandlerTest

} // OpportunityTeamMemberHandlerTest