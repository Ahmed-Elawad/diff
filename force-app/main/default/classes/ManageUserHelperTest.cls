/* 
 * The test methods for the ManageUserHelper and UserTransferTxferREST classes.
 *
 * History
 * -------
  06/26/2015 Dan Carmen   Created
  02/27/2018 Dan Carmen   Increase API version of the code.

 */
@isTest
private class ManageUserHelperTest {

   // call the rest class directly to attempt the user transfer
   static testMethod void testTransferUser() {
      // select two users - existing and copy user
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 2];
      User_Transfer__c userTransfer = new User_Transfer__c(Existing_User__c=users[0].Id, CopyUserFrom__c=users[1].Id
                              ,IsExistingSales__c=true, IsTxferSales__c=true, Manage_Type__c=ManageUserController.OPTION_TXFER
                              ,StrX__c='YYY');
      insert userTransfer;
      
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         String retVal = UserTransferTxferREST.doPost(userTransfer.Id);
         System.debug('retVal='+retVal);
         // make sure an id is returned
         System.assertEquals(true,retVal.startsWith('005'));
      } // System.runAs
      
   } // testTransferUser
   
   // call the rest class directly to attempt the user transfer
   static testMethod void testTransferUserFailure() {
      
      PaychexSettings__c payxSetting = new PaychexSettings__c(Name='UserTransferTxferREST-'+UserTransferTxferREST.EMAIL_FAIL, IsActive__c=true, Attribute1__c='test@paychex.com');
      insert payxSetting;
      
      // select two users - existing and copy user, and a 3rd user to get a duplicate username
      User[] users = [Select Id, Name, Username from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 3];
      // set the username to equal the third user to force a duplicate
      User_Transfer__c userTransfer = new User_Transfer__c(Existing_User__c=users[0].Id, CopyUserFrom__c=users[1].Id
                              ,IsExistingSales__c=true, IsTxferSales__c=true, Manage_Type__c=ManageUserController.OPTION_TXFER
                              ,StrX__c='YYY', Username__c=users[2].Username);
      insert userTransfer;
      
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         String retVal = UserTransferTxferREST.doPost(userTransfer.Id);
         System.debug('retVal='+retVal);
         // make sure an id is not returned
         System.assertEquals(false,retVal.startsWith('005'));
      } // System.runAs
      
   } // testTransferUserFailure
   
   static testMethod void testUserTransferQueueable() {
      UserTransferQueueable utq = new UserTransferQueueable(); 
      utq.setFlds(ObjectHelper.OBJECT_OPPTY);
      utq.setFlds(ObjectHelper.OBJECT_TASK);
      utq.setFlds(ObjectHelper.OBJECT_CASE);
      utq.setFlds(ObjectHelper.OBJECT_EVENT);
   } // testUserTransferQueueable
   
   
} // class ManageUserHelperTest