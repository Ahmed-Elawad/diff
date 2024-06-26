/* 
 *  Test methods for the NSSAuditView controller
 
 * History
 * -------
 * 08/12/2014 Dan Carmen     created
 * 12/08/2015 Cindy Freeman	 tweak to supervisor query
 * 01/17/2017 Cindy Freeman	 tweak to profile name
 * 05/18/2021 Carrie Marciano   Changed to use OppStage Labels
 */
@isTest
private class NSSAuditViewTest {
   public static String SOLD_STARTED=Label.OppStage_Sold_Started;
    
   static testMethod void testCreateAudits() {
   	User runningUser = UserHelper.getRunningUser();
   	
   	// enter the form with no data
      NSSAuditView auditView = new NSSAuditView();
   	System.assertEquals(false,auditView.hasDisplayList);
   	
      // setup the test data
      Account acct1 = new Account(Name='Test Acct1');
      Account acct2 = new Account(Name='Test Acct2');
      Account acct3 = new Account(Name='Test Acct3');
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      Prospect_Ownership__c po1 = new Prospect_Ownership__c(CommissionStart__c=Date.today().addMonths(-6), CommissionEnd__c=Date.today().addMonths(6), Prospect_Client__c=acct1.Id, NSS_Team__c=UserHelper.SO_CORE, NSR_Name__c=runningUser.Id);
      Prospect_Ownership__c po2 = new Prospect_Ownership__c(CommissionStart__c=Date.today().addMonths(-9), CommissionEnd__c=Date.today().addMonths(3), Prospect_Client__c=acct2.Id, NSS_Team__c=UserHelper.SO_CORE, NSR_Name__c=runningUser.Id);
      Prospect_Ownership__c po3 = new Prospect_Ownership__c(CommissionStart__c=Date.today().addMonths(-12), CommissionEnd__c=Date.today(), Prospect_Client__c=acct3.Id, NSS_Team__c=UserHelper.SO_CORE, NSR_Name__c=runningUser.Id);
      
      Prospect_Ownership__c[] pos = new Prospect_Ownership__c[]{po1,po2,po3};
      insert pos;
      
      Schema.RecordTypeInfo rt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_CORE, ObjectHelper.OBJECT_OPPTY);
      Opportunity opp1 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct1.Id, Name='Test Opp1', StageName='Pending', CloseDate=Date.today());
      Opportunity opp2 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct1.Id, Name='Test Opp2', StageName='Pending', CloseDate=Date.today().addMonths(-3));
      Opportunity opp3 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct1.Id, Name='Test Opp3', StageName='Pending', CloseDate=Date.today().addMonths(3));

      Opportunity opp4 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct2.Id, Name='Test Opp4', StageName=SOLD_STARTED, CloseDate=Date.today());
      Opportunity opp5 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct2.Id, Name='Test Opp5', StageName=SOLD_STARTED, CloseDate=Date.today().addMonths(-3));
      Opportunity opp6 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct2.Id, Name='Test Opp6', StageName=SOLD_STARTED, CloseDate=Date.today().addMonths(3));

      Opportunity opp7 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct3.Id, Name='Test Opp7', StageName='Pending', CloseDate=Date.today());
      Opportunity opp8 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct3.Id, Name='Test Opp8', StageName='Pending', CloseDate=Date.today().addMonths(-3));
      // this one shouldn't get a team member - outside the date range.
      Opportunity opp9 = new Opportunity(RecordTypeId=rt.getRecordTypeId(), AccountId=acct3.Id, Name='Test Opp9', StageName='Pending', CloseDate=Date.today().addMonths(3));
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5,opp6,opp7,opp8,opp9};
      insert opps;
      
      // verify the opportunity team members are created - should be created automatically
      System.assertEquals(8,[select count() from OpportunityTeamMember where TeamMemberRole=:OpptyMethods.ROLE_NSR and UserId=:runningUser.Id]);

      // shouldn't be any NSS Audit records
      System.assertEquals(0,[select count() from NSSAudit__c]);
      
      auditView = new NSSAuditView();
      
      auditView.nssSalesUser = UserHelper.getRunningUser();
      System.assertEquals(true,auditView.nssSalesUserSelected);
      System.assertEquals(false,auditView.hasNssUserOptions);
      
      auditView.findRecords();
      
      System.assertEquals(true,auditView.hasDisplayList);
      // set the date range to encompass all of the opportunities
      auditView.nssView.StartDate__c = Date.today().addMonths(-6);
      auditView.nssView.EndDate__c = Date.today().addMonths(6);
      auditView.applyFilters();
      
      System.assertEquals(8,auditView.displayList.size());
      
      // apply the status filter
      //auditView.selectedStatusOption = 'Sold';
      //System.assertEquals(3,auditView.displayRecs.size());
      
      // go back to all
      //auditView.selectedStatusOption = NSSAuditView.ALL_STATUS_OPTION;

      // nothing is selected/nothing created
      auditView.saveAuditRecords();
      
      // select all of the records.
      for (NSSViewWrapper nssWrapper : auditView.displayList) {
         nssWrapper.selected = true;
      }
      
      auditView.saveAuditRecords();
      
      System.assertEquals(8,[select count() from NSSAudit__c]);
   } // testCreateAudits
   
   public static User v_super = null;
   public static User v_nsr1 = null;
   public static User v_nsr2 = null;
   
   public static void selectSupervisorAndNsrs() {
   	  String likeName = UserHelper.PROF_NSS_OUTBOUND + '%';
      // find the district user roles with at least 5 children
      AggregateResult[] results = [Select count(Id) nbr_recs, UserRoleId, UserRole.ParentRoleId parentRoleId
                                     From User
                                    Where IsActive=true
                                      and Job_Name__c = :UserHelper.JOB_NSR
                                      and Profile.Name like :likeName
                                    group by UserRoleId, UserRole.ParentRoleId
                                    having count(Id) > 3
                                     order by count(Id) desc
                                    ];
      

      System.debug('testIsUserVisible nbrresults='+results.size()+' results='+results);
      
      // pull out all of the role ids to make sure we get at least one good one.
      Id[] supervisorRoleIds = new Id[]{}; 
      for (AggregateResult result : results) {
         supervisorRoleIds.add((Id)result.get('parentRoleId'));
      }
      
      User[] supers = [Select Id, Name, UserRoleId, UserRole.Name
                           ,Profile.Name, Profile.Id
                       from User 
                   where IsActive=true 
                     and Profile.Name in :UserHelper.NSS_MGR_PROF_SET
                     and Job_Name__c=:UserHelper.JOB_NSS_SUPER
                     and UserRoleId in :supervisorRoleIds
                     and UserRole.Name like '%Supervisor%'
                    limit 10];
      
      v_super = supers[0];

      // select some reps
      User[] nsrs = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                    ,Sales_Org__c, District__c, District_Name__c
                from User 
               where IsActive=true 
                 and UserRole.ParentRoleId = :v_super.UserRoleId 
                 and Job_Name__c = :UserHelper.JOB_NSR
                 and Profile.Name like :likeName
               limit 2];
      v_nsr1 = nsrs[0];
      v_nsr2 = nsrs[1];

   } // selectSupervisorAndNsrs

   static testMethod void testAsSupervisor() {
      System.debug('testAsSupervisor start');
      selectSupervisorAndNsrs();
      //User[] users = ProspectOwnershipMethodsTest.getOutboundNSRs(1);
      System.debug('testAsSupervisor after getOutboundNSRs');
      // find a supervisor
      //User supervisor = null;
      //try {
      //   supervisor = [Select Id, Name, UserRoleId from User where IsActive=true and UserRole.Id=:users[0].UserRole.ParentRoleId limit 1];
      //   System.debug('testAsSupervisor retrieved supervisor');
      //} catch (Exception e) {
      //   supervisor = [Select Id, Name, UserRoleId from User where Id != :users[0].Id and UserRoleId != null and IsActive=true limit 1];
      //   supervisor.UserRoleId = users[0].UserRole.ParentRoleId;
      //   update supervisor;
      //   System.debug('testAsSupervisor update existing user to meet supervisor criteria');
      //}
      
      System.runAs(v_super) {
         // enter the form with no data
         System.debug('testAsSupervisor before constructor');
         NSSAuditView auditView = new NSSAuditView();
         System.debug('testAsSupervisor after constructor constructor');
         System.assertEquals(true,auditView.promptForUser);
         
         auditView.askForUser.NSR_Name__c = v_nsr1.Id;
         auditView.askForUserChanged();
         System.debug('testAsSupervisor after askForUserChanged');
      } // System.runAs
   } // testAsSupervisor
   
   static testMethod void testSupervisorList() {
      selectSupervisorAndNsrs();
      NSSAuditView auditView = new NSSAuditView();
      auditView.adminControl.selectedSupervisorFrom = v_super.Id;
      auditView.supervisorSelected();
      System.assertEquals(true,auditView.hasNssUserOptions);
      auditView.selectedRecType = NSSAuditView.OPTION_SALES_1;
      auditView.setRecType();
      
      auditView.findRecords();

   } // testSupervisorList

   
} // class NSSAuditViewTest