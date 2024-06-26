/**
 * @description       : 
 * @author            : Austin Barthel
 * @group             : Cloud Coach
 * @last modified on  : 08-25-2023
 * @last modified by  : Austin Barthel
**/
@isTest
public with sharing class CC_ProjectTaskTriggerTest {
    @TestSetup
    static void makeData(){
        CC_TestDataFactory.createUserForTestClass(1111);
        CC_TestDataFactory.generateTree(1);
    }

    @IsTest
    static void testUpdate(){
        User contextuser = [SELECT Id FROM User WHERE Email = 'test.user@test.com'];
        project_cloud__Project_Task__c task = [
            SELECT 
                project_cloud__IsExternal_Deliverable__c,
                project_cloud__External_Assignees__c,
                Assignees__c,
                CaseSafeProjectID__c
            FROM project_cloud__Project_Task__c
            LIMIT 1
        ];
        project_cloud__Stakeholder_Contact__c sc = CC_TestDataFactory.newStakeholderContact(task.CaseSafeProjectID__c, contextuser.Id);
        insert sc;

        Test.startTest();
        System.runas(contextuser){
            Assert.areEqual(null, [
                SELECT 
                    Assignees__c
                FROM project_cloud__Project_Task__c
                WHERE ID = :task.Id
            ].Assignees__c);

            task.project_cloud__External_Assignees__c = 'test.user@test.com';
            update task;
            Assert.areEqual('Test User Test User', [
                SELECT 
                    Assignees__c
                FROM project_cloud__Project_Task__c
                WHERE ID = :task.Id
            ].Assignees__c);

            task.project_cloud__External_Assignees__c = '';
            update task;
            Assert.areEqual(null, [
                SELECT 
                    Assignees__c
                FROM project_cloud__Project_Task__c
                WHERE ID = :task.Id
            ].Assignees__c);

        }
        Test.stopTest();
        
    }

}