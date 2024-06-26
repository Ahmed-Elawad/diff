/* 
 * A class to modify certain user objects after a Fullsandbx refresh
 * History
 * -------
 * 11/26/2018 Michael Karcz  created
 * 12/6/2019  Michael Karcz	 Modified to save Profile first, which updates License Type and allows Roles to be set
   07/07/2020 Dan Carmen     Check for SSO users to not reset password
   04/09/2024 Carrie Marciano   	   removed references to MPSC Tech Debt

 */

public with sharing class FullSandbxRefreshUsers {
	
	public FullSandbxRefreshUsers() {
		updateUsers();
	} // Constructor
	
	public void updateUsers() {
		
		// Create the permission set 'Process Builder' and activate the 'Manage Flow' permission
		PermissionSet ps;
		List<PermissionSet> psList = [SELECT Id, Name FROM PermissionSet WHERE Name = :Label.Process_Builder];
		if(psList.isEmpty()) {
			ps = new PermissionSet(Label= Label.ProcessBuilder, Name=Label.Process_Builder);
			ps.PermissionsManageInteraction = true;
			ps.PermissionsViewRoles = true;
			ps.PermissionsViewSetup = true;
			insert ps;
		}
		else {
			ps = psList.get(0);
		}
		
		// Sets for roles and profiles to later query Ids
		Set<String> roleSet = new Set<String>();
		Set<String> profileSet = new Set<String>();
		
		// Create a map of the users from MetaData
		Map<String, FullSandbx_Refresh_Users__mdt> mdUserMap = new Map<String, FullSandbx_Refresh_Users__mdt>();
		for(FullSandbx_Refresh_Users__mdt u : [SELECT User_Id__c, Email__c, Profile__c, Role__c, Manage_Users_Permission__c, Test_User__c FROM FullSandbx_Refresh_Users__mdt]) {
			if(!Test.isRunningTest() || (Test.isRunningTest() && u.Test_User__c == true)) {
				mdUserMap.put(u.User_Id__c, u);
				roleSet.add(u.Role__c);
				profileSet.add(u.Profile__c);
			}		
		}
        
        
        //---------------------------------------
        //Create a map of users that have a profile of 'MPSC Profile' the size of the mdUserMap
        //Set their IsActive to false
        /*List<User> MPSCUsers = [SELECT Id, IsActive FROM User WHERE Profile.Name = :Label.Fullsandbx_Deactivate_Profile AND IsActive = true LIMIT :mdUserMap.size()];
        for(User mpscUser : MPSCUsers) {
            mpscUser.IsActive = false;
        }
        
        update MPSCUsers;
		//---------------------------------------
        */
        
		// Create a map of both the profiles and the roles
		Map<String, Id> roleMap = new Map<String, Id>();
		Map<String, Profile> profileMap = new Map<String, Profile>();
		
		for(UserRole r : [SELECT Id, Name FROM UserRole WHERE Name in :roleSet]) {
			roleMap.put(r.Name, r.Id);
		}
		for(Profile p : [SELECT Id, Name, PermissionsIsSSOEnabled, IsSSOEnabled  FROM Profile WHERE Name in :profileSet]) {
			profileMap.put(p.Name, p);
		}
        
		// List of Users to be updated
		Map<Id, User> users = new Map<Id, User>([SELECT Id, Email, ProfileId, Profile.PermissionsIsSSOEnabled, Profile.IsSSOEnabled, UserRoleId, License_Type__c, IsActive FROM User WHERE Id in :mdUserMap.keySet()]);
		
        
		Map<Id,PermissionSetAssignment> permissionSetAssignmentByUserId = new Map<Id,PermissionSetAssignment>();
		for(PermissionSetAssignment psa: [SELECT Id,PermissionSetId,AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps.Id AND AssigneeId in :mdUserMap.keySet()]){
			permissionSetAssignmentByUserId.put(psa.AssigneeId,psa);
		}
		
		List<PermissionSetAssignment> permissionsToAssign = new List<PermissionSetAssignment>();

        
        //Update user profiles to set the license and eliminate values in map that cause a null
        for(User u : users.values()) {
            FullSandbx_Refresh_Users__mdt mdUser = mdUserMap.get(u.Id);
            
            if(mdUser == null) {
                mdUserMap.remove(u.Id);
                users.remove(u.Id);
            } else if( String.isNotBlank(mdUser.Profile__c) && profileMap.containsKey(mdUser.Profile__c) ) {
               u.ProfileId = profileMap.get(mdUser.Profile__c).Id;
            }
        }
        update users.values();
		
        // Update the users
        for(User u : users.values()) {
            FullSandbx_Refresh_Users__mdt mdUser = mdUserMap.get(u.Id);
            
            u.Email = mdUser.Email__c;
            
            System.debug('License Type after Update: ' + u.Id + ' ' + u.Email + ' ' + u.License_Type__c);
            
            u.IsActive = true;
            
            //if(String.isNotBlank(mdUser.Profile__c)) u.ProfileId = profileMap.get(mdUser.Profile__c);
            if(String.isNotBlank(mdUser.Role__c)) u.UserRoleId = roleMap.get(mdUser.Role__c);
            
            if(mdUser.Manage_Users_Permission__c && !permissionSetAssignmentByUserId.containsKey(u.Id)) {
                PermissionSetAssignment psa = new PermissionSetAssignment();
                psa.PermissionSetId = ps.Id;
                psa.AssigneeId = u.Id;
                permissionsToAssign.add(psa);	
            }
        } // for(user u)
		
		// Insert to/Update the database. Allow partial completion.
		Database.insert(permissionsToAssign, false);
		//Database.update(users.values(), false);
		update users.values();
        
		// Reset passwords and send email
		for(User usr : users.values()) {
            if(mdUserMap.get(usr.Id) != null) {
                Profile prof = (profileMap.containsKey(usr.ProfileId) ? profileMap.get(usr.ProfileId) : usr.Profile);
                if (prof == null || (!prof.PermissionsIsSSOEnabled && !prof.IsSSOEnabled)) {
                   System.resetPassword(usr.Id, true);
                }
            }
		}
	} // updateUsers
} // FullSandbxRefreshUsers