/** Test methods for FullSandbxRefreshUsers Class
 * 
 * History
 * -------
 * 11/30/2018 Michael Karcz			Created
   11/17/2023 Dan Carmen            Add setAgentSyncAsyncSettings due to AgentSync Mixed Dml Issue
   04/09/2024 Carrie Marciano	commenting out code to remove old MPSC tech debt
 */


@isTest
public class FullSandbxRefreshUsersTest {
    
    // to get around mixed dml errors in agentsync
    @testsetup
    public static void setAgentSyncAsyncSettings(){
        agentsync__Async_Framework_Settings__c settings = agentsync__Async_Framework_Settings__c.getOrgDefaults();
        Boolean isCreated = new agentsync__Async_Framework_Settings__c() != settings;
        if(!isCreated){
            settings.agentsync__Daily_Async_Limit__c = 90; 
            insert settings;
        }
    }
    
	
    public static testMethod void testUsers() {
    	//setAgentSyncAsyncSettings();

    	// Get the users we want to test on into a map
    	List<FullSandbx_Refresh_Users__mdt> mdUserList = [SELECT User_Id__c, Email__c, Manage_Users_Permission__c FROM FullSandbx_Refresh_Users__mdt WHERE Test_User__c = true];
    	
    	Map<String, FullSandbx_Refresh_Users__mdt> mdUserMap = new Map<String, FullSandbx_Refresh_Users__mdt>();
    	for(FullSandbx_Refresh_Users__mdt mdU : mdUserList) {
    		mdUserMap.put(mdU.User_Id__c, mdU);
    	}
    	
    	// Check whether or not the permission set exists
    	List<PermissionSet> psList = [SELECT Id, Name FROM PermissionSet WHERE Name = :Label.Process_Builder];
    	// If it exists, delete all permission set assignments related to it and delete the permission set
    	if(!psList.isEmpty()) {
    		
            PermissionSet ps = psList.get(0);
            
    		List<PermissionSetAssignment> psas = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id];
    		delete psas;
    		delete ps;
    	}
    	
        
        List<User> MPSCUsers = [SELECT Id, IsActive FROM User WHERE Profile.Name = :Label.Fullsandbx_Deactivate_Profile AND IsActive = true LIMIT 3];
    	
        System.debug('*************USERS: ' + MPSCUsers);
        

    	Test.startTest();
    	
    	
    	new FullSandbxRefreshUsers();
    	
    	Map<Id, User> afterUsers = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id in :mdUserMap.keySet()]);
    	
    	// collection of user Ids that have the Process Builder assignment set
    	Set<String> psUserIdSet = new Set<String>();
    	for(PermissionSetAssignment psa : [SELECT Assignee.Id FROM PermissionSetAssignment WHERE PermissionSet.Name = :Label.Process_Builder AND Assignee.Id IN :mdUserMap.keySet()]) {
    		psUserIdSet.add(psa.Assignee.Id);
    	}
    	
    	// Check that the users have the correct email and permission set assignment after running class
    	for(FullSandbx_Refresh_Users__mdt mdUser : mdUserMap.values()) {
    		User afterUser = afterUsers.get(mdUser.User_Id__c);
    		System.assertEquals(mdUser.Email__c, afterUser.Email);
    		
    		if(mdUser.Manage_Users_Permission__c) {
    			//System.assert(psUserIdSet.contains(afterUser.Id));
    		}
    		
    	} // for
    	
        
        /**
        Map<Id, User> updatedMPSCUsers = new Map<Id, User>([SELECT Id, IsActive FROM User WHERE Id IN :MPSCUsers]);
        for(User u : MPSCUsers) {
            System.assertNotEquals(u.IsActive, (updatedMPSCUsers.get(u.Id)).IsActive);
        }
		
        
        List<User> updatedMPSCUsers = [SELECT Id FROM User WHERE Id IN :MPSCUsers AND IsActive = false];
        System.assertEquals(MPSCUsers.size(), updatedMPSCUsers.size()); 
        **/
        
    	Test.stopTest();
    	
    } // testUsers
} // FullsandbxRefreshUsersTest