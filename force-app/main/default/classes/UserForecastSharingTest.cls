/* 
 * The test methods for the UserForecastSharing class.
 *
 * History
 * -------
 * 10/31/2017	Jake Hinds   Created
 *
 */
@isTest
private class UserForecastSharingTest {
	static testMethod void testForecastSharing(){
   		User testUser = [SELECT Id,UserRoleId From User WHERE Job_Name__c = :UserHelper.JOB_DSA AND IsActive = true LIMIT 1];
   		User testUser2 = [SELECT Id,UserRoleId From User WHERE Job_Name__c = :UserHelper.JOB_DSA AND IsActive = true AND UserRoleId!= :testUser.UserRoleId LIMIT 1];
   		testUser.UserRoleId = testUser2.UserRoleId;
   		Map<Id,User> uMap = new Map<Id,User>();
   		uMap.put(testUser.Id,testUser);
   		
   		Test.startTest();
		
   		UserForecastSharing.setForecastSharing(uMap);
   		
   		//create empty list for method, would be where the delete call would go but no way to do that in test
   		Id[] dList = new Id[]{};
   		Map<Id,Id> userRoleIdByUserIdMap = new Map<Id,Id>();
   		userRoleIdByUserIdMap.put(testUser.Id,testUser.UserRoleId);
   		UserForecastSharing.handleForecastSharingFuture(UserInfo.getSessionId(),userRoleIdByUserIdMap,dList);

   		Test.stopTest();
   		ForecastingShare[] shares = [SELECT UserOrGroupId,SharedForecastManagerRoleId FROM ForecastingShare WHERE UserOrGroupId = :testUser.Id AND SharedForecastManagerRoleId = :testUser.UserRoleId];
		system.assert(shares!=null);   		
   }
}