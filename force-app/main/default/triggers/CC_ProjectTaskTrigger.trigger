/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-25-2023
 * @last modified by  : Austin Barthel
**/
trigger CC_ProjectTaskTrigger on project_cloud__Project_Task__c (before update) {
    CC_TriggerDispatcher.createHandler(project_cloud__Project_Task__c.SObjectType);
}