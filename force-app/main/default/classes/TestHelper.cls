/* 
 * Generic tests that can be use by any class.
 *
 * History
 * -------
 * 02/09/2012 Dan Carmen   Created
   10/29/2018 Dan Carmen   Increment API to version 44
   01/13/2021 Dan Carmen   Change testScheduler so it always looks to the future - previously had a hard coded date
   10/21/2021 Dan Carmen   Update to actually run execute the scheduled class

 */
@isTest
public class TestHelper {
   private static Integer s_num = 1;

   // This test runs a scheduled job at midnight Sept. 3rd. 2022
   // public static String CRON_EXP = '0 0 0 3 9 ? 2022';
   
   // Test the scheduled component of Batch Apex code.
   public static void testScheduler(String scheduleName, Schedulable testClassInstance) {
      Test.startTest();
      testClassInstance.execute(null);
      /*
      DateTime nextRunTime = DateTime.now().addSeconds(1);
      // Schedule the test job
      String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
            nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
            nextRunTime.month() + ' ? ' + nextRunTime.year(); 
      String jobId = System.schedule(scheduleName + 'test-' + Datetime.now().format(), cronString, testClassInstance);

      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT id, CronExpression, TimesTriggered,NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
      // Verify the expressions are the same
      System.assertEquals(cronString,ct.CronExpression);

      // Verify the job has not run
      System.assertEquals(0, ct.TimesTriggered);

      // Verify the next time the job will run
      System.assertEquals(nextRunTime,ct.NextFireTime);
      System.abortJob(jobId);
      */
      Test.stopTest();	
   } // testScheduler
   
   public static void logOutput(List<Database.saveResult> results) {
   	if (results != null && !results.isEmpty()) {
         for (Integer cnt=0; cnt<results.size(); cnt++) {
            Database.saveResult result = results.get(cnt);
            String errorStr = null;
            if (!result.isSuccess()) {
               errorStr = '';
               for (Database.Error err : result.getErrors()) {
                  errorStr += err.getMessage();
               }
            }
            System.debug('result for record '+cnt+'='+result.isSuccess()+(errorStr != null ? ' errorStr='+errorStr : ''));
         } // for
   	} // if (results != null && !results.isEmpty
   } // logOutput

   public static String getFakeId(Schema.SObjectType sot) {
      String result = String.valueOf(s_num++);
      return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
   }
} // TestHelper