/* 
 * Test methods for PicklistDetailScheduledUpdate
 *
 * History
 * -------
   04/10/2018 Mike Matonis       Created
   07/17/2018 Dan Carmen         Add additional fields to the queries

 */
@isTest
private class PicklistDetailScheduledUpdateTest {

   static testMethod void testPicklistDetailScheduleUpdate() {
      // set the limit to 1 so that only batch will execute
      PicklistDetailScheduledUpdate.query = 'SELECT Id, Name, DeveloperName, SObjectType FROM RecordType WHERE SObjectType = \'Task\' OR SObjectType = \'Event\' LIMIT 1';
      TestHelper.testScheduler('TestPicklistDetailScheduledUpdate', new PicklistDetailScheduledUpdate());
   } // testPicklistDetailScheduleUpdate
} // class PicklistDetailScheduledUpdateTest