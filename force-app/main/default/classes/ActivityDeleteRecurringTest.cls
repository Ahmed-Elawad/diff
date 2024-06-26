/* 
 * Test methods for the ActivityDeleteRecurring class.
 *
 * History
 * -------
 * 04/17/2012 Dan Carmen   Created
 * 04/28/2017 Cindy Freeman	Modified to exclude default workflow user
 *
 */
@isTest
private class ActivityDeleteRecurringTest {

   static testMethod void testRecurring() {
   	// select the running user
   	User runningUser = [Select Id, Name from User where IsActive=true and id=:UserInfo.getUserId()];
   	// select a user   	
   	User u = [Select Id, Name, IsActive from User where IsActive=true and id != :UserInfo.getUserId() 
              and UserRoleId != null and Profile.Name != :Utilities.PROF_SYS_ADMIN 
              and Name != 'SFDC Data' limit 1];  
   	
      // for recurring activity
      DateTime activityDateTime = DateTime.now();
      // for non-recurring future dated activity
      DateTime futureActivityDT = DateTime.now().addDays(7);
         	
      // create recurring and non-recurring activity
      Event evnt1 = new Event(OwnerId=u.Id,Subject='ActivityDeleteRecurringTest RecurringEvent', ActivityDateTime=activityDateTime
                             ,ActivityDate=activityDateTime.date(),DurationInMinutes=60                                      
                             ,RecurrenceEndDateOnly=activityDateTime.date().addDays(10),IsRecurrence=true
                             ,RecurrenceType='RecursEveryWeekDay',RecurrenceDayOfWeekMask=10
                             ,RecurrenceStartDateTime=activityDateTime);
      Event evnt2 = new Event(OwnerId=u.Id,Subject='ActivityDeleteRecurringTest RecurringEvent', ActivityDateTime=futureActivityDT
                             ,ActivityDate=futureActivityDT.date(),DurationInMinutes=60,IsRecurrence=false);
      insert evnt1;
      insert evnt2;
      
      Task tsk1 = new Task(OwnerId=u.Id,Subject='ActivityDeleteRecurringTest RecurringTask'
                         //    ,ActivityDate=activityDateTime.date()                                  
                             ,RecurrenceEndDateOnly=activityDateTime.date().addDays(10),IsRecurrence=true
                             ,RecurrenceType='RecursEveryWeekDay',RecurrenceDayOfWeekMask=10
                             ,RecurrenceStartDateOnly=activityDateTime.date());
      Task tsk2 = new Task(OwnerId=u.Id,Subject='ActivityDeleteRecurringTest RecurringTask'
                             ,ActivityDate=futureActivityDT.date(),IsRecurrence=false);
      insert tsk1;
      insert tsk2;
      
      System.debug('verify recurring activity is created');
      System.assertEquals(true,(1<[Select count() from Event where RecurrenceActivityId=:evnt1.Id and IsRecurrence=false and ActivityDate > :Date.today()]));
      System.assertEquals(true,(1<[Select count() from Task where RecurrenceActivityId=:tsk1.Id and IsRecurrence=false and ActivityDate > :Date.today()]));
      System.debug('verify the future dated activity exists');
      System.assertEquals(1,[Select count() from Event where Id=:evnt2.Id]);
      System.assertEquals(1,[Select count() from Task where Id=:tsk2.Id]);
      
      System.debug('make sure future recurring activity is deleted and non-recurring is not.');
      System.runAs(runningUser) {
      	Test.startTest();
      	u.IsActive = false;
      	update u;
      	Test.stopTest();
      } // System.runAs

      System.debug('verify recurring activity is deleted');
      System.assertEquals(0,[Select count() from Event where RecurrenceActivityId=:evnt1.Id and IsRecurrence=false and ActivityDate > :Date.today()]);
      System.assertEquals(0,[Select count() from Task where RecurrenceActivityId=:tsk1.Id and IsRecurrence=false and ActivityDate > :Date.today()]);
      System.debug('verify the future dated activity still exists');
      System.assertEquals(1,[Select count() from Event where Id=:evnt2.Id]);
      System.assertEquals(1,[Select count() from Task where Id=:tsk2.Id]);

   } // testRecurring
    
} // ActivityDeleteRecurringTest