public with sharing class ProjectStatusReportController {
    public static project_cloud__Project__c project;
    public static List<Id> resourceAssigmentList;
    public ProjectStatusReportController(ApexPages.StandardController controller) {
        project = (project_cloud__Project__c)controller.getRecord();
    }   

    public static List<project_cloud__Ticket__c> tickets { // GET OPEN ITEMS TICKETS 
        get{
            if(tickets == null){
                tickets = new List<project_cloud__Ticket__c>([SELECT Id,
                project_cloud__Ticket_Name__c,
                project_cloud__Status__c,
                project_cloud__Due_Date__c,
                Owner.Name,
                INC__c,
                APR__c,
                CreatedDate,
                project_cloud__Description__c
                FROM project_cloud__Ticket__c 
                WHERE project_cloud__Project_CCPE_Ignore__c = :project.Id
                AND project_cloud__Show_Status_Report__c = true]);
            }
            return tickets;
        }
        set;
    }

    public static List<project_cloud__Project_Phase__c> phases { // GET PHASES
        get{
            if(phases == null){
                phases = new List<project_cloud__Project_Phase__c>([SELECT Id,
                Name, 
                Project_Phase_Health__c, 
                Health_Reason__c, 
                project_cloud__Completed_Percent__c
                FROM project_cloud__Project_Phase__c 
                WHERE project_cloud__Project__c = :project.Id
                AND Show_on_Status_Report__c = true]);
            }
            return phases;
        }
        set;
    }

}