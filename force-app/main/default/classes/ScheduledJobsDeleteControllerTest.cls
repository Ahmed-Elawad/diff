/* 
 *The test methods for the ScheduledJobsDeleteController class.
 *
 * History
 * -------
 * 10/11/2012 Cindy Freeman   Created
 * 03/17/2015 Cindy Freeman	  Modified to match query in controller class
 * 12/04/2018 Cindy Freeman	  Modified to pass even if running in sandbox and all scheduled jobs have already been deleted
 *
 */

@isTest
private class ScheduledJobsDeleteControllerTest {
  	
    static testMethod void myUnitTest() {
        
        User meU = [Select Id, Name from User where Id = :Userinfo.getUserId()];
        
        ApexPages.StandardController sc = new ApexPages.standardController(meU);    
        ScheduledJobsDeleteController sjd = new ScheduledJobsDeleteController(sc);

        String msg = sjd.getWhoandWhere();
        System.assertEquals('Welcome ' + meU.Name, msg );
        
        if (Utilities.checkForProduction() == '')
        {   sjd.DeleteAllJobs();
            System.assertEquals(true, sjd.productionOrg);   
            System.assertEquals(true, hasError(ApexPages.getMessages()));    
        }
        else
        {   Integer beforeCnt = [Select Count() from CronTrigger where State != 'DELETED' and (CronJobDetail.JobType = '3' or CronJobDetail.JobType = '4' or CronJobDetail.JobType = '8')];
            sjd.DeleteAllJobs();
            Integer afterCnt = [Select Count() from CronTrigger where State != 'DELETED' and (CronJobDetail.JobType = '3' or CronJobDetail.JobType = '4' or CronJobDetail.JobType = '8')];
            if (beforeCnt != 0)
            {	System.assertNotEquals(beforeCnt, afterCnt);	}	
        }
    }
    
    /** Is there a warning message?
     */
    private static boolean hasError(List<ApexPages.Message> msgs) {
       if ((msgs != null) && (msgs.size() > 0)) {
          for (ApexPages.Message msg : msgs) {
             // if at least one message of type warning, return true
             if (msg.getSeverity() == ApexPages.severity.ERROR) {
                return true;
             }
          } // for
       } // if ((msgs != null
       return false;
    } // hasError

}