/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 07-18-2023
 * @last modified by  : Austin Barthel
**/
@istest
public class CC_CreateUpdateProjectControllerTest {
    public static Id getProjectTemplateId(){
        return [
            SELECT Id
            FROM project_cloud__Project__c
            WHERE project_cloud__IsTemplate__c = true
        ].Id;
    }
    @TestSetup
    static void makeData(){
        CC_TestDataFactory.createUserForTestClass(1111);
        CC_TestDataFactory.generateTree(6);
        project_cloud__Project__c project = [SELECT project_cloud__IsTemplate__c FROM project_cloud__PRoject__c ];
        project.project_cloud__IsTemplate__c = true;
        update project;
    }

    @IsTest
    static void getProjectTest(){
        User contextuser = [SELECT Id FROM User WHERE Email = 'test.user@test.com'];
        Reference_Enterprise_Service__c res = CC_TestDataFactory.createRes(true);
        
        Test.startTest();
        System.runAs(contextuser){
            Assert.isNull(CC_CreateUpdateProjectController.getProject(res.Id));
            
            project_cloud__Project__c project = CC_TestDataFactory.newProject('Test Project 2');
            project.Reference_Enterprise_Service__c = res.Id;
            insert project;
            project_cloud__Project_Phase__c phase = CC_TestDataFactory.newPhase('Test Phase 2', project);

            Assert.isNotNull(CC_CreateUpdateProjectController.getProject(res.Id));

            project_cloud__Project__c project2 = CC_TestDataFactory.newProject('Test Project 3');
            project2.Reference_Enterprise_Service__c = res.Id;
            insert project2;

            try {
                CC_CreateUpdateProjectController.getProject(res.Id);
                Assert.fail();
            } catch (Exception e) {
                Assert.areEqual('Script-thrown exception', e.getMessage());
            }

        }
        Test.stopTest();
    }

    @IsTest
    static void getProjectDataMappingTest(){
        User contextuser = [SELECT Id FROM User WHERE Email = 'test.user@test.com'];
        Reference_Enterprise_Service__c res = CC_TestDataFactory.createRes(true);



        Test.startTest();
        System.runAs(contextuser){
            System.debug(CC_CreateUpdateProjectController.getProductDataMapping(res.Id));
        }
        Test.stopTest();
        
    }

    @IsTest
    static void manageProjectHandlerTest(){
        User contextuser = [SELECT Id FROM User WHERE Email = 'test.user@test.com'];
        Reference_Enterprise_Service__c res = CC_TestDataFactory.createRes(true);
        CC_TestDataFactory.generateTree(6);
        
        List<project_cloud__Project_Phase__c> phases = [SELECT Id, project_cloud__Project__c FROM project_cloud__Project_Phase__c WHERE project_cloud__Project__r.project_cloud__IsTemplate__c = false];
        List<Id> phasesToCloneInit = new List<Id>{
            phases.get(0).Id,
            phases.get(1).Id,
            phases.get(2).Id,
            phases.get(3).Id
        };
        List<Id> phasesToDelete = new List<Id>{
            phases.get(0).Id,
            phases.get(1).Id
        };
        List<Id> phasesToInsertOnUpdate = new List<Id>{
            phases.get(4).Id,
            phases.get(5).Id
        };

        Test.startTest();
        System.runAs(contextuser){
            Id newProjectId = CC_CreateUpdateProjectController.manageProjectHandler(res.Id, null, 'Test Project', phasesToCloneInit, new List<Id>(), Date.today());

            List<project_cloud__Project_Phase__c> phasesInProject = [SELECT Id FROM project_cloud__Project_Phase__c WHERE project_cloud__Project__c = :newProjectId];

            Assert.areEqual(10, phasesInProject.size());

            CC_CreateUpdateProjectController.manageProjectHandler(
                res.Id,
                newProjectId,
                null,
                new List<Id>(),
                phasesToDelete,
                Date.today()
            );
            
            phasesInProject = [SELECT Id FROM project_cloud__Project_Phase__c WHERE project_cloud__Project__c = :newProjectId];
            
            Assert.areEqual(8, phasesInProject.size());
            
            CC_CreateUpdateProjectController.manageProjectHandler(res.Id, newProjectId, null, phasesToInsertOnUpdate, new List<Id>(), Date.today());
            
            phasesInProject = [SELECT Id FROM project_cloud__Project_Phase__c WHERE project_cloud__Project__c = :newProjectId];

            Assert.areEqual(10, phasesInProject.size());
        }
        Test.stopTest();
        
    }
}