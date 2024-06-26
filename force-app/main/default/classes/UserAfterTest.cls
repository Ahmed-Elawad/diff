/**
 * Test methods for UserAfter trigger that cancels waiting cron jobs if user is inactivated
 * 
 * History
 * --------
 * 10/7/2012  Cindy Freeman    created
 * 03/19/2015 Cindy Freeman    modified so doesnt inactivate real users
   11/16/2017 Dan Carmen       Modify test class so it will perform code coverage

 */
@isTest
private class UserAfterTest {
	public static String CRON_EXP = '0 0 0 3 9 ? 2022';				// scheduled to run 9/3/2022
    
    static testMethod void testTrigger() {
       User testUser = [Select Id, Name, IsActive from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Id != :UserInfo.getUserId() limit 1];
       User runningUser = UserHelper.getRunningUser();
       System.runAs(runningUser) {
          testUser.IsActive=false;
          update testUser;
       }
    } // testTrigger
    
    /*
    static testMethod void testUserDeleteJobs() {

    // find and update user with waiting cron that should stay waiting
    CronTrigger ct = [Select Id, OwnerId, State from CronTrigger
            where State = 'WAITING' limit 1]; 
    User u2 = [Select Id, Name, ProfileId, IsActive, Country from User
            where IsActive = true
            and Id = :ct.OwnerId];
            
    Integer beforeCnt = [Select Count() from CronTrigger where State = 'WAITING' and OwnerId = :ct.OwnerId];
                
    u2.Country = 'USA';            
    update u2;
    
    Integer afterCnt =  [Select Count() from CronTrigger where State = 'WAITING' and OwnerId = :ct.OwnerId];
    System.assertEquals(afterCnt, beforeCnt);
                              
	 
    // create temp user, schedule cron, inactivate user, make sure cron is gone
	
	UserTestHelper uth = new UserTestHelper();
   	User curUser = uth.getUserById(UserInfo.getUserId());
    
    List<User> users = new List<User>();      
    // create User for testing
    for (Integer cnt=0; cnt<1; cnt++) {
      	 uth.createUser(users,cnt,curUser.Profile,curUser.UserRole,curUser);
    } // for
    insert users;
    User newUzer = users[0];
    
    Test.startTest();
    System.runAs(newUzer) {
        String jobId = System.schedule('testScheduler',CRON_EXP, new ChatterBatch());            
    }
    List<CronTrigger> tempCrons = [Select Id, OwnerId, State from CronTrigger
             where State = 'WAITING' and OwnerId = :newUzer.Id];
    System.assertEquals(1, tempCrons.size());
    
    newUzer.isActive = FALSE;
    update newUzer;
    
    tempCrons = [Select Id, OwnerId, State from CronTrigger
             where State = 'WAITING' and OwnerId = :newUzer.Id];
    System.assertEquals(0, tempCrons.size());
    
    } // testUserDeleteJobs
  */    
}