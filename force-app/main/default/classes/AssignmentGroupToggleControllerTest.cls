/**
 * Test class for the Assignment Group Toggle Component

   History
   -------
   12/15/2023 Dan Carmen         Add error handling to the Group Member update

 */
@isTest
private class AssignmentGroupToggleControllerTest {

    static testMethod void getGroups() {
    	User runningUser = UserHelper.getRunningUser();
    	
    	Assignment_Group_Name__c agn = new Assignment_Group_Name__c(Name='Test Group 1');
    	Assignment_Group_Name__c agn2 = new Assignment_Group_Name__c(Name='Test Group 2');
    	Assignment_Group_Name__c[] agns = new Assignment_Group_Name__c[]{agn,agn2};
    	insert agns;
    	
    	Assignment_Groups__c gm = new Assignment_Groups__c(User__c = runningUser.Id,Group_Name__c = agn.Id, Active__c = 'True', Manage_Group__c = true);
    	Assignment_Groups__c gm2 = new Assignment_Groups__c(User__c = runningUser.Id,Group_Name__c = agn2.Id, Active__c = 'False', Manage_Self__c = true);
    	Assignment_Groups__c[] gms = new Assignment_Groups__c[]{gm,gm2};
    	insert gms;
    	
        AssignmentGroupToggleController agc = new AssignmentGroupToggleController();
        
        //get list of options, should be number of assignment groups+1 for -None- option
        List<SelectOption> groups = agc.getGroupOptions();
        System.assertEquals(3,groups.size());
        System.assertEquals(true,agc.hasGroups);
        
        //ensure selected group is active
        agc.selectedGroup = groups[1].getValue();
        System.assertEquals('You are currently active',agc.activeStatus);
        System.assertEquals(true,agc.hasStatus);
        
        //toggle active and ensure now false
        agc.toggleActive();
        Assignment_Groups__c ugm = [SELECT Id,Active__c FROM Assignment_Groups__c WHERE Id=:gm.Id];
        system.assertEquals('False',ugm.Active__c);
        
        //change selection to second group, ensure inactive
        agc.selectedGroup = groups[2].getValue();
        System.assertEquals('You are currently inactive',agc.activeStatus);
        
        //toggle active and ensure now true
        agc.toggleActive();
        Assignment_Groups__c ugm2 = [SELECT Id,Active__c FROM Assignment_Groups__c WHERE Id=:gm2.Id];
        system.assertEquals('True',ugm2.Active__c);
    }
} // class AssignmentGroupToggleControllerTest