/* Test methods for the SandboxPostCopyNoData class
   
  History
  -------
  08/17/2018 Dan Carmen   Created
  
 */
@isTest
private class SandboxPostCopyNoDataTest {

   @isTest
   static void myUnitTest() {
      // Insert logic here to create records of the objects that the class you’re testing manipulates (if any)
      PermissionSet permSet = new PermissionSet(Name='TestPermSet', Label='TestPermSet'); 
      insert permSet;
       
      PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(), PermissionSetId=permSet.Id);
      insert assign;
       
      System.assertEquals(1, [Select count() from PermissionSetAssignment Where PermissionSet.Name='TestPermSet']);

      SandboxPostCopyNoData.DELETE_PERM_SETS='TestPermSet';
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
      Test.startTest();

      Test.testSandboxPostCopyScript(
           new SandboxPostCopyNoData(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

      Test.stopTest();
      }
      System.assertEquals(true, [select count() from Organization_Structure__c] > 2);
      System.assertEquals(true, [select count() from Org_Unit__c] > 2);
      System.assertEquals(true, [select count() from Zip_Segment__c] > 2);
      System.assertEquals(true, [select count() from Referral_Partner__c] > 2);
      System.assertEquals(0, [Select count() from PermissionSetAssignment Where PermissionSet.Name='TestPermSet']);
   } // myUnitTest
} // class SandboxPostCopyNoDataTest