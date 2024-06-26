//Client side controller
//11/07/2018 Lynn Michels Created
({
	//sets which section to display on load
    doInit : function(component) {
      component.set('v.sectionToDisplay', 'chooseWho');
        console.log('doInit');  
    },
    
 	handleWho: function (component, event, helper) {
        var selectedValue = component.find('who').get('v.value');
        //If 'Myself'
        if (selectedValue == 'myself'){
            var action = component.get('c.getRunningUser');
        		action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    var runningUser = response.getReturnValue();  //returns a user record in a javascript object form
                    
                    component.set('v.userId', runningUser.Id);
                    component.set('v.profileName', runningUser.Profile.Name);                   
     console.log('OpptTeamController handleWho USER ' + runningUser.Id);
     console.log('OpptTeamController handleWho PROFILE ' + runningUser.Profile.Name);
					 $A.enqueueAction(component.get('c.checkOppTeamMembers'));
                 }//end if SUCCESS
                 else{
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error getting running user: ' +errors);
            	}//end else
                });
         	$A.enqueueAction(action);
        }//end if myself
        //If 'Someone Else'
        else{
            component.set('v.sectionToDisplay', 'displayInputUser');
        }   
    },
    
    handleRadioChange:function(component, event){
        //clear error messages
        component.set('v.showMessage', false);
    },
    
    searchForUser: function(component, event, helper) {
       component.set('v.isSearching', false);
       component.set('v.showMessage', false);
        var searchParams = component.get('v.searchUser');  //get the name that was entered
        if(searchParams){
        var action = component.get('c.getAllActiveUsers');
            action.setParams({'SearchName': searchParams});
        	action.setCallback(this, function(response) {
       			var state = response.getState();
            	if(state === 'SUCCESS') {
                    var usersReturned = response.getReturnValue();  //returns a javascript object
                    var i;
                 	var iLength = Object.keys(usersReturned).length;
             		var userSelection = [];
                    //if users are returned from the search
                    if(iLength > 0){
                         for (i = 0; i < iLength; i++){
                            userSelection.push({label: usersReturned[i].Name +' - '+ usersReturned[i].UserRole.Name, value: usersReturned[i].Id+','+ usersReturned[i].Profile.Name +','+usersReturned[i].Name});
                         }//end for
                    	component.set('v.activeUsers', userSelection);
                        component.set('v.isSearching', true);
                    } //end if iLength>0
                    else{
                        component.set('v.showMessage', true);
                        component.set('v.msg', 'No users have been found from your search criteria.');
                   }
                }//end if SUCESS
                else {
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error searching for a user: ' +errors);
            	}//end else
            }); 
        	$A.enqueueAction(action);
        }
        //if the user does not enter a name to search for
        else{
            component.set('v.showMessage', true);
            component.set('v.msg', 'Please enter a user to search for.');
		}//end else
    },
    
    
    handleUserSelected: function (component,event) {  
    	var selectedUser = component.find('whatUser').get('v.value');
        var res = selectedUser.split(',');
        component.set('v.userId', res[0]);
        component.set('v.profileName', res[1]);
        component.set('v.userName', res[2]);
       
        $A.enqueueAction(component.get('c.checkOppTeamMembers'));  //find out if they are in the team already
    },
    
    checkOppTeamMembers:function(component,event,helper){
  		var oppId = component.get('v.recordId');
        var usrId = component.get('v.userId'); 
          
        var action = component.get('c.checkCurrentTeamMembers');  //returns a list team members, should be 1 or 0 returned
        	action.setParams({ 'uId' : usrId, 'opptyId' : oppId});
        	action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {  
                     var existingTeamMbr = response.getReturnValue();  //returns a user record in a javascript object form
                    //if a team member was returned, they already exist in the opp team
                    if(existingTeamMbr.length > 0){ 
                    component.set('v.teamMemberId', existingTeamMbr[0].Id); //used for deletion
                 console.log('esistingTeamMbr '+JSON.stringify(existingTeamMbr));
                     component.set('v.sectionToDisplay', 'displayConfirmDelete');
                     component.set('v.isSearching', false);   
                    }//end if length>0
                    else{
                        $A.enqueueAction(component.get('c.getRolesForCombobox'));                    
                    }//end else
                }//end SUCCESS
                else {
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error retrieving current team members: ' +errors);
            	}//end else
            });
            $A.enqueueAction(action);
    },
    
    getRolesForCombobox:function(component,event,helper){
        var usrName = component.get('v.userName'); 
        var profName = component.get('v.profileName');    
        var action = component.get('c.getRoleList');
        	action.setParams({ 'profileName' : profName});
        	action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                     var roles = response.getReturnValue();
                     var options = [];
 					//if the profile was found in the custom settings, and it had roles listed, display the roles
                    console.log('roles.length '+roles.length);
                    if(roles.length > 0){
                        console.log('roles.length '+roles.length);
                        if(roles.length == 1){
                            console.log('roles.length '+roles.length);
                            var setRole = roles[0];
                            console.log('setRole '+roles[0]);
                            component.set('v.roleChosen', setRole);
                            component.set('v.sectionToDisplay', 'rolesetOutput');
                        }//end if 1
                        else{
                            console.log('getRolesForCombobox there are roles' );
                            roles.forEach(function(element) {
                                options.push({ value: element, label: element });
                            });
                            component.set('v.availableRoles', options);  
                                
                            component.set('v.sectionToDisplay', 'displayRoleList');
                        }
                        component.set('v.isSearching', false);
                        component.set('v.showMessage', false);
                    }//end if length >0
                    //else should never be hit because the orginal query filters out the users that don't match the criteria for this
   					//if the profile was found but there are no roles list
                    else{
                        if(usrName != undefined){
                            component.set('v.msg', usrName+ ' may not be added to this opportunity.'); 
                        }
                        else{
                        	component.set('v.msg', 'This user may not be added to this opportunity.');
                        }
                        component.set('v.showMessage', true);
                  }//end else 
                    
                }//end if SUCCESS
                else {
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error getting team roles from custom setting: ' +errors);
            	}//end else
                });
       $A.enqueueAction(action);
    },
    
    //used to set the role selected
    setRoleSelected: function (component, event) {
        var roleAlreadySet = component.get('v.roleChosen');
        //if the roleChosen is not already set, set it
        if(!roleAlreadySet){
            var selectedRole = event.getParam('value');
            console.log('selectedRole '+selectedRole);
            component.set('v.roleChosen', selectedRole);
        }
    },
   
 	addMember: function (component, event, helper) {
        var oppId = component.get('v.recordId');
        var role = component.get('v.roleChosen');
        var uid = component.get('v.userId');
        console.log('OpptyTeamController addMember - uid, role, opptyid ' + uid + ' - ' + role + 'and opptyId '+oppId);
        
        var action = component.get('c.addTeamMember');
            action.setParams({ 'userId' : uid, 'roleSelected' : role, 'opptyId' : oppId}); 
        	action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === 'SUCCESS') {
                    component.set('v.sectionToDisplay', 'displayUserHasBeenAdded');
                    component.set('v.confirmation', true);
                }//if success
                else {
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error adding a team member: ' +errors);
            	}//end else
            });
        $A.enqueueAction(action);
		
     }, 
    
   deleteMember: function (component) {
       var teamMemberToDelete = component.get('v.teamMemberId');
       var usrId = component.get('v.userId'); 
       var oppId = component.get('v.recordId');
    console.log('OpptyTeamController teamMemberToDelete ' + teamMemberToDelete);
    
       var action = component.get('c.deleteTeamMember');
       action.setParams({ 'memberToDelete' : teamMemberToDelete, 'uid' : usrId, 'oId' : oppId}); 
         action.setCallback(this, function(response) {
            var state = response.getState();
                if (state === 'SUCCESS') {
                    component.set('v.sectionToDisplay', 'displayUserHasBeenDeleted');
                    component.set('v.confirmation', true);
         		}
         		else {
                	console.error(response.getError());
                    component.set('v.showMessage', true);
                    component.set('v.msg', 'Error deleting a team member: ' +errors);
            	}//end else
            });
            $A.enqueueAction(action);
     },
    
    ok: function (component, event, helper) {
        var oppId = component.get('v.recordId');
        $A.get('e.force:refreshView').fire();
        $A.get("e.force:closeQuickAction").fire();
     },
    
})