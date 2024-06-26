@isTest
private class ProjectStatusReportControllerTest {
    @TestSetup
    static void makeData(){

        // PROJECT
        project_cloud__Project__c project = new project_cloud__Project__c(
            Name = 'Test', 
            project_cloud__Units__c = 'Duration',
            project_cloud__Resourcing_Mode__c = 'timeBased'
        );
        insert project; 

        // PROJECT PHASES
        List<project_cloud__Project_Phase__c> phaseList = new List<project_cloud__Project_Phase__c>();
        phaseList.add(new project_cloud__Project_Phase__c(
            Name = 'Phase 1',
            project_cloud__Project__c = project.Id
        ));
        insert phaseList;

        // TICKET
        List<project_cloud__Ticket__c> ticketList = new List<project_cloud__Ticket__c>();
        ticketList.add(new project_cloud__Ticket__c(
            project_cloud__Ticket_Name__c = 'Risk',
            project_cloud__Project__c = project.Id,
            project_cloud__Show_Status_Report__c = true
        ));
        insert ticketList;
        
    }

    @isTest
    private static void testTickets(){ // TICKET TESTING METHOD 
        Test.startTest();
        project_cloud__Project__c project = [SELECT Id FROM project_cloud__Project__c LIMIT 1];
        ProjectStatusReportController ctrl = new ProjectStatusReportController(new ApexPages.StandardController(project));
        List<project_cloud__Ticket__c> tickets = ProjectStatusReportController.tickets;
        Assert.areEqual(1, tickets.size(), 'Tickets size should equal one');
        Test.stopTest();
    }

    @isTest
    private static void testPhases(){ // TICKET TESTING METHOD 
        Test.startTest();
        project_cloud__Project__c project = [SELECT Id FROM project_cloud__Project__c LIMIT 1];
        ProjectStatusReportController ctrl = new ProjectStatusReportController(new ApexPages.StandardController(project));
        List<project_cloud__Project_Phase__c> phases = ProjectStatusReportController.phases;
        Assert.areEqual(1, phases.size(), 'Phases size should equal one');
        Test.stopTest();
    }

}