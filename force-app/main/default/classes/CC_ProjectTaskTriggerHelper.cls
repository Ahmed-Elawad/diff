/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-31-2023
 * @last modified by  : Austin Barthel
**/
public with sharing class CC_ProjectTaskTriggerHelper {
    public static void updateAssigneeField(project_cloud__Project_Task__c[] tasks, Set<Id> projectIds, Set<String> emails) {
        if(Trigger.isUpdate){
            beforeUpdateAssigneeField(tasks, projectIds, emails);
        }
    }

    private static void beforeUpdateAssigneeField(project_cloud__Project_Task__c[] tasks, Set<Id> projectIds, Set<String> emails){
        Map<String, String> emailToName = getStakeholderContactsByEmail(projectIds, emails);
        for(project_cloud__Project_Task__c task : tasks){
            task.Assignees__c = assigneeFieldUpdated(task, emailToName).abbreviate(255);
        }
    }

    private static String assigneeFieldUpdated(project_cloud__Project_Task__c task, Map<String, String> emailToName){
        String names = '';
        if(!task.project_cloud__External_Assignees__c.contains(',')){
            names = emailToName.get(task.project_cloud__External_Assignees__c.trim());
        } else{
            for(String email : task.project_cloud__External_Assignees__c.split(',')){

                names += names != '' ? ', ' : '';
                names += emailToName.get(email.trim());
            }
        }
        return names;
    }

    private static Map<String, String> getStakeholderContactsByEmail(Set<Id> projectIds, Set<String> emails) {
        Map<String, String> emailToName = new Map<String,String>();
        for(project_cloud__Stakeholder_Contact__c sc : [
            SELECT project_cloud__Name__c, project_cloud__Email__c
            FROM project_cloud__Stakeholder_Contact__c
            WHERE project_cloud__Project__c IN :projectIds
            AND project_cloud__Email__c IN :emails
            AND project_cloud__Email__c != null
        ]){
            emailToName.put(sc.project_cloud__Email__c, sc.project_cloud__Name__c);
        }
        return emailToName;
    }
}