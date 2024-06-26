/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-25-2023
 * @last modified by  : Austin Barthel
**/
@isTest
public class CC_TestDataFactory {
    public static Reference_Enterprise_Service__c createRes(Boolean isInsert){
        Reference_Enterprise_Service__c res = new Reference_Enterprise_Service__c();

        if (isInsert) insert res;

        return res;
    }

    @Future
    public static void createUserForTestClass(Integer userRate){
        User u = newUser();
        u.ccpe_r__Rate__c = userRate;
        insert u;
    }
    
    public static User newUser() {
        return newUser(null);
    }
    
    public static User newUser(String profileName) {
        if (profileName != null) {
            profileName = '%' + profileName + '%';
        } else {
            profileName = 'System Administrator';
        }
        return new User(
            FirstName = 'Test User',
            LastName = 'Test User',
            Email = 'test.user@test.com',
            Alias = 'tuser',
            Username = 'test.user@neci.com',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/New_York',
            ProfileId = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1].Id,
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            project_cloud__Allocatable__c = true,
            UserRoleId = null,
            Sales_Org__c = 'Agency'
        );
    }

    // This will generate the amount of phases specified with only child tasks and child sub tasks
    public static void generateTree(Integer childRecordCount){
        project_cloud__Project__c project = newProject('Test Project');
        insert project;
        List<project_cloud__Project_Phase__c> phases = newPhaseList('Test Phase', childRecordCount, project);
        insert phases;
        List<project_cloud__Project_Sub_Phase__c> subPhases = newSubPhaseList('Test SubPhase', childRecordCount, phases);
        insert subPhases;
        Map<Id, project_cloud__Project_Sub_Phase__c[]> subPhaseLinks = new Map<Id, project_cloud__Project_Sub_Phase__c[]>();
        for(project_cloud__Project_Sub_Phase__c subPhase : subPhases){
            if(subPhaseLinks.containsKey(subPhase.project_cloud__Project_Phase__c)){
                subPhaseLinks.get(subPhase.project_cloud__Project_Phase__c).add(subPhase);
            } else{
                subPhaseLinks.put(subPhase.project_cloud__Project_Phase__c, new List<project_cloud__Project_Sub_Phase__c>{subPhase});
            }
        }
        List<project_cloud__Project_Task__c> tasks = newTaskList('Test Task', childRecordCount, phases, subPhaseLinks);
        insert tasks;
    }
    
    // This method returns a new Project object that can be inserted in a @TestSetup method testMethod method
    public static project_cloud__Project__c newProject(String projectName) {
        return new project_cloud__Project__c(
            Name = projectName,
            project_cloud__Units__c = 'Duration',
            project_cloud__Methodology__c = 'Water-Scrum-Fall',
            project_cloud__Resourcing_Mode__c = 'quickAssign'
        );
    }
    
    // This method returns a new list of Project objects for test data
    public static project_cloud__Project__c[] newProjectList(String projectName, Integer recordCount) {
        project_cloud__Project__c[] projectList = new project_cloud__Project__c[]{};
        for (Integer i = 0; i < recordCount; i++) {
            projectList.add(newProject(projectName));
        }
        return projectList;
    }
    
    // This method returns a new Phase object that can be inserted in a @TestSetup method or testMethod method
    public static project_cloud__Project_Phase__c newPhase(
        String phaseName, 
        project_cloud__Project__c project
    ) {
        return new project_cloud__Project_Phase__c(
            Name = phaseName,
            project_cloud__Project__c = project.Id
        );
    }
    
    // This method returns a list of new Phase objects for test data
    public static project_cloud__Project_Phase__c[] newPhaseList(
        String phaseName, 
        Integer recordCount, 
        project_cloud__Project__c project
    ) {
        project_cloud__Project_Phase__c[] phaseList = new project_cloud__Project_Phase__c[]{};
        for (Integer i = 0; i < recordCount; i++) {
            phaseList.add(new project_cloud__Project_Phase__c(
                Name = phaseName + ' ' + i,
                project_cloud__Project__c = project.Id
            ));
        }
        return phaseList;
    }
    
    // This method returns a list of new Sub-Phase objects for test data
    public static project_cloud__Project_Sub_Phase__c[] newSubPhaseList(
        String subPhaseName,
        Integer recordCount,
        project_cloud__Project_Phase__c[] parentPhases
    ) {
        project_cloud__Project_Sub_Phase__c[] subPhaseList = new project_cloud__Project_Sub_Phase__c[]{};
        for (project_cloud__Project_Phase__c phase : parentPhases) {
            for (Integer i = 0; i < recordCount; i++) {
                subPhaseList.add(new project_cloud__Project_Sub_Phase__c(
                    Name = subPhaseName + ' ' + i,
                    project_cloud__Project_Phase__c = phase.Id
                ));
            }
        }
        return subPhaseList;
    }
    
    public static project_cloud__Project_Sub_Phase__c newSubPhase(
        String subPhaseName,
        Id phaseId
    ) {
        return new project_cloud__Project_Sub_Phase__c(
            Name = subPhaseName,
            project_cloud__Project_Phase__c = phaseId
        );
    }
    
    // This method returns a list of new Project Task objects for test data
    public static project_cloud__Project_Task__c[] newTaskList(
        String taskName, 
        Integer recordCount, 
        project_cloud__Project_Phase__c[] parentPhases,
        Map<Id, project_cloud__Project_Sub_Phase__c[]> subPhaseLinks
    ) {
        project_cloud__Project_Task__c[] taskList = new project_cloud__Project_Task__c[]{};
        for (project_cloud__Project_Phase__c phase : parentPhases) {
            if(subPhaseLinks.containsKey(phase.Id)){
                for(project_cloud__Project_Sub_Phase__c subPhase : subPhaseLinks.get(phase.Id)){
                    for (Integer i = 0; i < recordCount; i++) {
                        taskList.add(new project_cloud__Project_Task__c(
                            Name = taskName + ' ' + i,
                            project_cloud__Project_Phase__c = phase.Id,
                            project_cloud__Project_Sub_Phase__c = subPhase?.Id,
                            project_cloud__Duration__c = 2,
                            project_cloud__Estimated_Hours__c = 1,
                            project_cloud__Autonomous_Start__c = Date.today().toStartOfWeek().addDays(1)
                        ));
                    }
                }
            } else{
                for (Integer i = 0; i < recordCount; i++) {
                    taskList.add(new project_cloud__Project_Task__c(
                        Name = taskName + ' ' + i,
                        project_cloud__Project_Phase__c = phase.Id,
                        project_cloud__Duration__c = 2,
                        project_cloud__Estimated_Hours__c = 1,
                        project_cloud__Autonomous_Start__c = Date.today().toStartOfWeek().addDays(1)
                    ));
                }
            }
        }
        return taskList;
    }
    
    // This method returns a new Project Task object that can be inserted in a @TestSetup method to testMethod method
    public static project_cloud__Project_Task__c newTask(
        String taskName, 
        project_cloud__Project_Phase__c phase, 
        project_cloud__Project_Sub_Phase__c subPhase
    ) {
        return new project_cloud__Project_Task__c(
            Name = taskName,
            project_cloud__Project_Phase__c = phase.Id,
            project_cloud__Project_Sub_Phase__c = subPhase?.Id,
            project_cloud__Duration__c = 1,
            project_cloud__Estimated_Hours__c = 1,
            project_cloud__Autonomous_Start__c = Date.today().toStartOfWeek().addDays(1)
        );
    }
    
    public static project_cloud__Project_Sub_Task__c newSubTask(String subTaskName, Id taskId){
        return new project_cloud__Project_Sub_Task__c(
            Name = subTaskName,
            project_cloud__Project_Task__c = taskId
        );
    }
    
    public static project_cloud__Project_Task_Dependency__c newDependency(Id parentId, Id childId){
        return new project_cloud__Project_Task_Dependency__c(
            project_cloud__Parent__c = parentId,
            project_cloud__Child__c = childId
        );
    }

    public static project_cloud__Stakeholder_Contact__c newStakeholderContact(Id projectId, Id userId) {
        return new project_cloud__Stakeholder_Contact__c(
            project_cloud__user__c = userId,
            project_cloud__Project__c = projectId
        );
    }
}