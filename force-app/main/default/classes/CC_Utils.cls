/**
 * @description       : Util Helper class to assist across all current and future Cloud Coach Code
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 07-24-2023
 * @last modified by  : Austin Barthel
**/
public with sharing class CC_Utils {
    //get fields for string query
    private static String getQueryFields(Schema.DescribeSObjectResult describe) {
        String queryFields = '';
        for(Schema.SObjectField field : describe.fields.getMap().values()) {
            if(queryFields.length() > 0) {
                queryFields += ',';
            }
            queryFields += String.valueOf(field);
        }
            
        return queryFields;
    }
    

    public static String getCloneQuery(SObjectType sot){
        switch on String.valueOf(sot) {
            when 'project_cloud__Project__c' {
                return (
                    ' SELECT ' +
                    getQueryFields(project_cloud__Project__c.SObjectType.getDescribe()) +
                    ' FROM ' +
                    ' project_cloud__Project__c ' +
                    ' WHERE ' +
                    ' Id = :templateId'
                );
            }
            when 'project_cloud__Project_Phase__c' {
                return (
                    ' SELECT ' +
                    getQueryFields(project_cloud__Project_Phase__c.SObjectType.getDescribe()) +
                    ' FROM ' +
                    ' project_cloud__Project_Phase__c ' +
                    ' WHERE ' +
                    ' Id IN :phasesToClone'
                );
            }
            when 'project_cloud__Project_Sub_Phase__c' {
                return (
                    ' SELECT ' +
                    getQueryFields(project_cloud__Project_Sub_Phase__c.SObjectType.getDescribe()) +
                    ' FROM ' +
                    ' project_cloud__Project_Sub_Phase__c ' +
                    ' WHERE ' +
                    ' project_cloud__Project_Phase__r.Id IN: phasesToClone'
                );
            }
            when 'project_cloud__Project_Task__c' {
                return (
                    ' SELECT ' +
                    getQueryFields(project_cloud__Project_Task__c.SObjectType.getDescribe()) +
                    ' FROM ' +
                    ' project_cloud__Project_Task__c ' +
                    ' WHERE ' +
                    ' project_cloud__Project_Phase__r.Id IN: phasesToClone'
                );
            }
            when else {
                return null;
            }
        }
    }

    public static Map<Id,Id> cloneSubPhases(List<project_cloud__Project_Sub_Phase__c> subphasesToClone, Map<Id,Id> phaseLinks){
        List<project_cloud__Project_Sub_Phase__c> subPhasesToInsert = new List<project_cloud__Project_Sub_Phase__c>();
        // Nested Subphase map
        List<project_cloud__Project_Sub_Phase__c> nestedSubPhases = new List<project_cloud__Project_Sub_Phase__c>();
        for(project_cloud__Project_Sub_Phase__c subPhase : subPhasesToClone){
            project_cloud__Project_Sub_Phase__c clonedSubPhase = subPhase.clone(false,true,false,false);
            clonedSubPhase.project_cloud__Cloned_From__c = subPhase.Id;
            clonedSubPhase.project_cloud__Project_Phase__c = phaseLinks.get(subPhase.project_cloud__Project_Phase__c);
            clonedSubPhase.project_cloud__Project_Sub_Phase__c = null;
            clonedSubPhase.project_cloud__Start__c = null;
            clonedSubPhase.project_cloud__End__c = null;
            clonedSubPhase.project_cloud__Completed_Percent__c = null;
            subPhasesToInsert.add(clonedSubPhase);
            if(subPhase.project_cloud__Project_Sub_Phase__c != null){
                nestedSubPhases.add(subPhase);
            }
        }
        insert subPhasesToInsert;

        Map<Id, project_cloud__Project_Sub_Phase__c> tempSubphaseMap = new Map<Id, project_cloud__Project_Sub_Phase__c>(subPhasesToInsert);

        Map<Id,Id> subPhaseLinks = new Map<Id,Id>();
        for(project_cloud__Project_Sub_Phase__c subPhase : subPhasesToInsert){
            subPhaseLinks.put(subPhase.project_cloud__Cloned_From__c, subPhase.Id);
        }

        List<project_cloud__Project_Sub_Phase__c> subPhasesToUpdate = new List<project_cloud__Project_Sub_Phase__c>();
        for(project_cloud__Project_Sub_Phase__c subPhase : nestedSubPhases){
            project_cloud__Project_Sub_Phase__c childSubPhase = tempSubphaseMap.get(subPhaseLinks.get(subPhase.Id));
            childSubPhase.project_cloud__Project_Sub_Phase__c = subPhaseLinks.get(subPhase.project_cloud__Project_Sub_Phase__c);
            subPhasesToUpdate.add(childSubPhase);
        }
        update subPhasesToUpdate;

        return subPhaseLinks;
    }

    public static void relateTasksToSubPhases(Map<Id,Id> taskLinks, Map<Id,Id> subPhaseLinks, Map<Id,project_cloud__Project_Task__c> templateTasks){
        Set<Id> tasksWithSubphase = new Set<Id>();
        Map<Id, Id> templateTaskIdToSubPhaseId = new Map<Id,Id>();
        for(project_cloud__Project_Task__c task : templateTasks.values()){
            if(task.project_cloud__Project_Sub_Phase__c == null) continue;
            templateTaskIdToSubPhaseId.put(task.Id, task.project_cloud__Project_Sub_Phase__c);
            tasksWithSubphase.add(taskLinks.get(task.Id));
        }

        List<project_cloud__Project_Task__c> tasksToUpdate = new List<project_cloud__Project_Task__c>();
        for(project_cloud__Project_Task__c task : [
            SELECT 
                project_cloud__Project_Sub_Phase__c,
                project_cloud__Cloned_From__c
            FROM project_cloud__Project_Task__c
            WHERE Id IN :tasksWithSubphase
        ]){
            task.project_cloud__Project_Sub_Phase__c = subPhaseLinks.get(templateTaskIdToSubPhaseId.get(task.project_cloud__Cloned_From__c));
            tasksToUpdate.add(task);
        }
        update tasksToUpdate;
    }
}