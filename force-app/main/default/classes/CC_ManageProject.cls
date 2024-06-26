/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 07-24-2023
 * @last modified by  : Austin Barthel
**/
public with sharing class CC_ManageProject {
    public Id createProject(Id resId, List<Id> phasesToClone, String projectName, Date startDate) {
        Reference_Enterprise_Service__c res = getResData(resId);

        // Create Init Project
        Id templateId = Test.isRunningTest() ? CC_CreateUpdateProjectControllerTest.getProjectTemplateId() : System.Label.Cloud_Coach_Project_Template;
        project_cloud__Project__c project = Database.query(CC_Utils.getCloneQuery(project_cloud__Project__c.SObjectType));
        project.Name = (projectName).abbreviate(70);
        project.Reference_Enterprise_Service__c = resId;
        project_cloud__Project__c clonedProject = project_cloud.CloneHelper.cloneProject(project, startDate);
        //Insert Phases if there are any to insert
        if(phasesToClone.isEmpty()){
            return clonedProject.Id;
        }
        
        insertPhases(clonedProject.Id, phasesToClone, startDate);

        return clonedProject.Id;
    }

    public Id updateProject(Id resId, Id projectId, List<Id> phasesToClone, List<Id> phasesToDelete, Date startDate) {
        if(!phasesToDelete.isEmpty()){
            deletePhases(projectId, phasesToDelete);
        }

        if(!phasesToClone.isEmpty()){
            insertPhases(projectId, phasesToClone, startDate);
        }

        return projectId;
    }

    private void deletePhases(Id projectId, List<Id> phasesToDelete){
        Set<Id> wholePhasesToDelete = new Set<Id>();
        Set<Id> tasksToIgnore = new Set<Id>();
        Set<Id> phasesNotDeleted = new Set<Id>();
        for(project_cloud__Project_Phase__c phase : [
            SELECT Id,
            (
                SELECT Id
                FROM project_cloud__Project_Tasks__r
                WHERE project_cloud__IsComplete__c = true
                OR project_cloud__Completed_Percent__c = 100
                OR project_cloud__Worked_Hours__c != 0
            )
            FROM project_cloud__Project_Phase__c
            WHERE project_cloud__Cloned_From__c IN :phasesToDelete
            AND project_cloud__Project__c = :projectId
        ]){
            if(phase.project_cloud__Project_Tasks__r == null || phase.project_cloud__Project_Tasks__r.isEmpty()){
                wholePhasesToDelete.add(phase.Id);
            } else{
                phasesNotDeleted.add(phase.Id);
                tasksToIgnore.addAll(new Map<Id, project_cloud__Project_Task__c>(phase.project_cloud__Project_Tasks__r).keySet());
            }
        }

        List<project_cloud__Project_Task__c> tasksToUpdate = [
            SELECT
                project_cloud__Show_External__c
            FROM project_cloud__Project_Task__c
            WHERE Id IN :tasksToIgnore
            AND project_cloud__Project_Phase__c IN :phasesNotDeleted
            AND project_cloud__Show_External__c = true
        ];

        for(project_cloud__Project_Task__c task : tasksToUpdate){
            task.project_cloud__Show_External__c = false;
        }

        update tasksToUpdate;

        delete [
            SELECT Id
            FROM project_cloud__Project_Task__c
            WHERE Id NOT IN :tasksToIgnore
            AND project_cloud__Project_Phase__c IN :phasesNotDeleted
            AND project_cloud__Project_Phase__r.project_cloud__Project__c = :projectId
        ];

        delete [
            SELECT Id
            FROM project_cloud__Project_Phase__c
            WHERE Id IN :wholePhasesToDelete
            AND project_cloud__Project__c = :projectId
        ];
    }

    private void insertPhases(Id clonedProjectId, List<Id> phasesToClone, Date startDate){
        // Template phase id => new phase id
        Map<Id,Id> phaseLinks = project_cloud.CloneHelper.clonePhases(
            Database.query(CC_Utils.getCloneQuery(project_cloud__Project_Phase__c.SObjectType)),
            clonedProjectId
        );

        // Template sub phase id => new sub phase id
        Map<Id,Id> subPhaseLinks = CC_Utils.cloneSubPhases(
            Database.query(CC_Utils.getCloneQuery(project_cloud__Project_Sub_Phase__c.SObjectType)),
            phaseLinks
        );
        
        // Template task id => template task
        Map<Id, project_cloud__Project_Task__c> templateTasks = new Map<Id, project_cloud__Project_Task__c>(
            (List<project_cloud__Project_Task__c>)Database.query(CC_Utils.getCloneQuery(project_cloud__Project_Task__c.SObjectType))
        );

        Date earliestStart;
        for(project_cloud__Project_Task__c task : templateTasks.values()){
            if(earliestStart == null || earliestStart > task.project_cloud__Start__c){
                earliestStart = task.project_cloud__Start__c;
            } 
        }

        // Template task id => new task id
        Map<Id, Id> taskLinks = project_cloud.CloneHelper.cloneTasks(
            templateTasks.values(),
            phaseLinks, 
            earliestStart.daysBetween(startDate)
        );

        CC_Utils.relateTasksToSubPhases(taskLinks, subPhaseLinks, templateTasks);

        project_cloud.CloneHelper.cloneDependencies(taskLinks);
    }

    public Reference_Enterprise_Service__c getResData(Id resId){
        return[
            SELECT 
                Name
            FROM Reference_Enterprise_Service__c
            WHERE Id = :resId
        ];
    }
    
}