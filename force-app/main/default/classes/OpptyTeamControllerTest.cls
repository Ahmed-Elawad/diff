/* 
 * Test Methods for the OpptyMethods class
 *
 * History
 * -------
 * 12/07/2018 Lynn Michels         Created
   02/04/2020 Dan Carmen           Update test to be more selective with the user.
   01/04/2022 Dan Carmen           Change to fix the tests

*/
@isTest
public with sharing class OpptyTeamControllerTest {

	 @testSetup
   static void setupData() {
   	List<Profile_List__c> profileList = new List<Profile_List__c>();
   		profileList.add(new Profile_List__c(Name='Standard User', Profile_Name__c='Standard User',OppTeamMember_Roles__c='PEO NSC,Sales Engineer'));
   		profileList.add(new Profile_List__c(Name='Test Profile', Profile_Name__c='Test Profile',OppTeamMember_Roles__c='')); 
   		insert profileList;  
   		createTestData.createSingleAandTwoCts();
   		Account a = [SELECT id from Account];
   		system.debug('account '+a);
   		Contact c = [SELECT id from Contact LIMIT 1];
   		createTestData.createTestCoreOptys (a.id, c.id);	
   }//end setupData
   
   static testMethod void testRunningUser() {
	 	Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
	 	 UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		 insert r;
		 
		 User u = new User(
		     LastName = 'last',
		     Email = 'oppTeamTestUser@example.com',
		     Username = 'oppTeamTestUser@example.com',
		     CompanyName = 'TEST',
		     Title = 'title',
		     Alias = 'oppTea',
		     TimeZoneSidKey = 'America/Los_Angeles',
		     EmailEncodingKey = 'UTF-8',
		     LanguageLocaleKey = 'en_US',
		     LocaleSidKey = 'en_US',
		     UserRoleId = r.Id,
		     ProfileId = p.id,
		     Sales_Org__c = 'COE'
		);
		insert u;
       
		Test.starttest();
        System.runAs(u) { 
            User runningUser = OpptyTeamController.getRunningUser();
	 		system.assertEquals(runningUser.id,u.id);
	 	}
       Test.stoptest();
   }//end test runningUser
    
    static testMethod void testGetRoles() {
        List<String> roles = OpptyTeamController.getRoleList('Standard User');
        system.assertEquals(2,roles.size());
        system.assertEquals(true,roles.contains('PEO NSC'));
        system.assertEquals(true,roles.contains('Sales Engineer'));
    }//end testGetRoles
	 	
    static testMethod void testcheckCurrentTeamMembers() {
	 	Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        User u1 = [SELECT Id FROM User where IsActive=true and Job_Name__c != null LIMIT 1];
	 	List<OpportunityTeamMember> currentTeamMembers = new List<OpportunityTeamMember>();
        currentTeamMembers = OpptyTeamController.checkCurrentTeamMembers(u1.id,opp1.id);
	 	system.assertEquals(0,currentTeamMembers.size());
       
        OpportunityTeamMember otmCreate = new OpportunityTeamMember(UserId = u1.id,
                                      OpportunityId = opp1.Id,
                                      TeamMemberRole = 'PEO NSC',
                                      OpportunityAccessLevel = 'Edit');
        insert otmCreate;
        currentTeamMembers = OpptyTeamController.checkCurrentTeamMembers(u1.id,opp1.id);
	 	system.assertEquals(1,currentTeamMembers.size());
                                            
    }//end testcheckCurrentTeamMembers
	 	
    static testMethod void testGetAllActiveUsers() {
        List<User> activeUsers = new List<User>();
        activeUsers = OpptyTeamController.getAllActiveUsers('Test');
        system.assertEquals(0,activeUsers.size());
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
	 	 UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
		 insert r;
		 
		 User u = new User(
		     LastName = 'Mouse',
             FirstName = 'Mickey',
		     Email = 'oppTeamTestUser@example.com',
		     Username = 'oppTeamTestUser@example.com',
		     CompanyName = 'TEST',
		     Title = 'title',
		     Alias = 'oppTea',
		     TimeZoneSidKey = 'America/Los_Angeles',
		     EmailEncodingKey = 'UTF-8',
		     LanguageLocaleKey = 'en_US',
		     LocaleSidKey = 'en_US',
		     UserRoleId = r.Id,
		     ProfileId = p.id,
		     Sales_Org__c = 'COE'
		);

         insert u;
        activeUsers = OpptyTeamController.getAllActiveUsers('Mouse');
        system.assertEquals(1,activeUsers.size());
    }
	 	
	 static testMethod void testAddTeamMember() {
        Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];
        User u1 = [SELECT Id FROM User Where IsActive=true and Job_Name__c != null LIMIT 1];
	 	Integer curTeamMembers = [Select count() from OpportunityTeamMember where OpportunityId=:opp1.Id];
        
        OpptyTeamController.addTeamMember(u1.id, 'Sales Engineer', opp1.id);
        Integer newTeamMembers = [SELECT count() FROM OpportunityTeamMember WHERE OpportunityId =: opp1.Id];
        system.assertEquals(curTeamMembers+1, newTeamMembers);
      
     }//end testAddTeamMember
    
     static testMethod void testDeleteMember() {
         List<OpportunityTeamMember> oppTeamMembers = new  List<OpportunityTeamMember>(); 
         Opportunity opp1 = [SELECT Id FROM Opportunity LIMIT 1];  
         User u1 = [SELECT Id FROM User where IsActive=true and Job_Name__c != null LIMIT 1];
        
         OpportunityTeamMember otmCreate = new OpportunityTeamMember(UserId = u1.id,
                                      OpportunityId = opp1.Id,
                                      TeamMemberRole = 'PEO NSC',
                                      OpportunityAccessLevel = 'Edit');
        insert otmCreate;
        //find Opportunity Team Member that was just inserted.
         OpportunityTeamMember otm = [SELECT id, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId =: opp1.Id AND UserId =: u1.id];
		//cofirm it exists
         system.assertEquals(true, otm != null);
		
         OpptyTeamController.deleteTeamMember(otm.id , u1.id, opp1.Id);
        
         oppTeamMembers = [SELECT id, UserId, TeamMemberRole FROM OpportunityTeamMember WHERE OpportunityId =: opp1.Id AND UserId =: u1.id];
         system.assertEquals(0, oppTeamMembers.size());
     } //end testDeleteMember
    
	 	
}//end OpptyTeamControllerTest