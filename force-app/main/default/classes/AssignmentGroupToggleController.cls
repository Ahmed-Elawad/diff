/* 
 * AssignmentGroupToggleController


   History
   -------
   12/15/2023 Dan Carmen         Add error handling to the Group Member update
 
 */
public with sharing class AssignmentGroupToggleController {
	public User runningUser;
	public String selectedGroup{get;set;}
	Map<Id,Assignment_Groups__c>groupMemberByAGId;
	public AssignmentGroupToggleController(){
		runningUser = UserHelper.getRunningUser();
		getGroupMemberMap();
	}
	public void getGroupMemberMap(){
		groupMemberByAGId = new Map<Id,Assignment_Groups__c>();
		Assignment_Groups__c [] groupMembers = [SELECT Id,Active__c,Group_Name__c,Group_Name__r.Name 
												FROM Assignment_Groups__c 
												WHERE User__c = :runningUser.Id
                                  					AND (Manage_Group__c = true OR Manage_Self__c = true)];
        for(Assignment_Groups__c member:groupMembers){
        	groupMemberByAGId.put(member.Group_Name__c,member);
        }
	}
	public List<SelectOption> getGroupOptions() {
        List<SelectOption> groupOptions = new List<SelectOption>();
        groupOptions.add(new SelectOption('','-None-'));
        for(Assignment_Groups__c member:groupMemberByAGId.values()){
        	groupOptions.add(new SelectOption(member.Group_Name__c,member.Group_Name__r.Name));
        }
        if(groupOptions.size() == 2){
        	groupOptions.remove(0);
        	selectedGroup =  groupOptions[0].getValue();
        }
        return groupOptions;
    }
    
	public Boolean hasGroups{
    	get {return (groupMemberByAGId != null && !groupMemberByAGId.isEmpty()); }
	} // hasGroups
	
	public Boolean isActive{get;set;}
	
    public String activeStatus{
    	get{
    		String status;
			if(selectedGroup!=null){
				Assignment_Groups__c member = groupMemberByAGId.get(selectedGroup);
				isActive = (member!=null && member.Active__c == 'True' ? true : false );
				if(isActive){
					status = 'You are currently active';
					
				}
				else{
					status = 'You are currently inactive';
				}
			}
			system.debug('status: '+status);
			return status;
		}
    }
    
    public Boolean hasStatus{
    	get {
    		system.debug('evaluating Status');
    		return activeStatus != null; 
    		}
	} // hasGroups
	
    public void toggleActive(){
    	if(selectedGroup!=null){
    		Assignment_Groups__c groupMember = groupMemberByAGId.get(selectedGroup);
    		if(groupMember.Active__c == 'True'){
    			groupMember.Active__c = 'False';
    		}
    		else{
    			groupMember.Active__c = 'True';
    		}
            // just so we only save the specific fields we need to
            Assignment_Groups__c updateRec = new Assignment_Groups__c(Id=groupMember.Id, Active__c=groupMember.Active__c);
    		//update groupMember;
            DmlHelper.performDML2(new Assignment_Groups__c[]{updateRec}, DmlHelper.DML_UPDATE, 'AssignmentGroupToggleController', 'toggleActive', 'Updating Group Memner', true);
    	}
    }
} // class AssignmentGroupToggleController