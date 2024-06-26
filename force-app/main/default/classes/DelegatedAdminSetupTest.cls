/* Test methods for the DelegatedAdminSetup class
   
   History
   -------
   03/20/2024 Dan Carmen        Created

*/
@isTest
public class DelegatedAdminSetupTest {

   static testMethod void testGroupIdSuccess() {
      DelegatedAdminSetupMock mockResp = new DelegatedAdminSetupMock();
      mockResp.responseToUse = DelegatedAdminSetupMock.groupIdFound;
      mockResp.responseCode = 200;
      Test.setMock(HttpCalloutMock.class, mockResp);
 
      String groupId = DelegatedAdminSetup.getDelegateGroupId('All Sales');
      Assert.areEqual('02f0g000000CfQsAAK',groupId);
   } // testGroupIdSuccess
    
   static testMethod void testGroupIdFailure() {
      DelegatedAdminSetupMock mockResp = new DelegatedAdminSetupMock();
      mockResp.responseToUse = DelegatedAdminSetupMock.groupIdNotFound;
      mockResp.responseCode = 200;
      Test.setMock(HttpCalloutMock.class, mockResp);
 
      String groupId = DelegatedAdminSetup.getDelegateGroupId('NotAGroup');
      Assert.isNull(groupId,'groupId='+groupId);
   } // testGroupIdSuccess
    
   static testMethod void testGroupMemberSuccess() {
      DelegatedAdminSetupMock mockResp = new DelegatedAdminSetupMock();
      mockResp.responseToUse = DelegatedAdminSetupMock.grpMemberSuccess;
      mockResp.responseCode = 201;
      Test.setMock(HttpCalloutMock.class, mockResp);
 
      String addResult = DelegatedAdminSetup.addToDelegateGroup('02f0g000000CfQsAAK','00530000000xxTA');
      Assert.areEqual('Added to Group Successfully',addResult);
   } // testGroupMemberSuccess
    
   static testMethod void testGroupMemberExists() {
      DelegatedAdminSetupMock mockResp = new DelegatedAdminSetupMock();
      mockResp.responseToUse = DelegatedAdminSetupMock.grpMemberExists;
      mockResp.responseCode = 400;
      Test.setMock(HttpCalloutMock.class, mockResp);
 
      String addResult = DelegatedAdminSetup.addToDelegateGroup('02f0g000000CfQsAAK','00530000000xxTA');
      Assert.areEqual('Already in Group',addResult);
   } // testGroupMemberSuccess
    

    
} // class DelegatedAdminSetupTest