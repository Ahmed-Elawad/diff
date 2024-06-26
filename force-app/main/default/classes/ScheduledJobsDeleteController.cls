/*
   *  This class will cancel all scheduled jobs if this is not the production org.
   *  If user tries to run on production and you are not running the test class it will throw back an error.
   *  This is meant to only be used when a sandbox is refreshed.
   *
   *  History
   *  -------
   *  10/11/2012  Cindy Freeman   created
   *  03/17/2015  Cindy Freeman   modified to delete specific jobtypes - Dashboard Refresh, Reporting Snapshot, Report Run 
   *  03/20/2018  Cindy Freeman	  modified to only delete 50 jobs at a time to avoid too many DML statements
   */
             
public with sharing class ScheduledJobsDeleteController {
    
    public Boolean productionOrg {get; set;}    
           
    public ScheduledJobsDeleteController(ApexPages.StandardController controller) {}
    
    public String getWhoandWhere () {
        productionOrg = (Utilities.checkForProduction() == '' ? true : false);
        return 'Welcome ' + UserInfo.getName();
    }
    
    public void DeleteAllJobs() {

        If (productionOrg)
        {ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'This can not be run in the Production org!');
            ApexPages.addMessage(myMsg);    
        }
        else
        {   Integer deleteCnt = 0;        
            //List<CronTrigger> waitingCrons = [Select Id, OwnerId, State, NextFireTime from CronTrigger where State != 'DELETED'];            
            List<CronTrigger> waitingCrons = [select id, State, OwnerId, NextFireTime, CronJobDetailId, CronJobDetail.JobType from CronTrigger
                                            where State != 'DELETED' and (CronJobDetail.JobType = '3' or CronJobDetail.JobType = '4' or CronJobDetail.JobType = '8') limit 50]; 
            for (CronTrigger ct : waitingCrons)  {
                System.abortJob(ct.Id);  
                deleteCnt++;      
            }        
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'Jobs deleted: ' + deleteCnt);
                ApexPages.addMessage(myMsg);
        }
            
    }


        
}