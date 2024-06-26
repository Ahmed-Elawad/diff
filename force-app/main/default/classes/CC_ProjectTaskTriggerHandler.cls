/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-25-2023
 * @last modified by  : Austin Barthel
**/
public with sharing class CC_ProjectTaskTriggerHandler implements CC_ITriggerHandler{
    public void bulkBefore(){
        if(Trigger.isUpdate){
            beforeUpdate();
        }
    }
    public void bulkAfter(){
    }

    public void beforeUpdate(){
        project_cloud__Project_Task__c[] tasks = new project_cloud__Project_Task__c[]{};
        Set<Id> projectIds = new Set<Id>();
        Set<String> emails = new Set<String>();

        for(project_cloud__Project_Task__c task : (project_cloud__Project_Task__c[])Trigger.new){
            if(task.project_cloud__External_Assignees__c != (String)Trigger.oldMap.get(task.Id).get('project_cloud__External_Assignees__c')){
                if(task.project_cloud__External_Assignees__c == null){
                    task.Assignees__c = '';
                } else{
                    tasks.add(task);
                    projectIds.add(task.CaseSafeProjectID__c);
                    emails.addAll(task.project_cloud__External_Assignees__c.split(', '));
                }
            }
        }
    
        if(tasks.size() != 0){
            CC_ProjectTaskTriggerHelper.updateAssigneeField(tasks, projectIds, emails);
        }

    }
}