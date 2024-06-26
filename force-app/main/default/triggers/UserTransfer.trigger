/* 
 * Trigger on the User_Transfer__c object.
               
 *
 * History
 * -------
   04/08/2015 Dan Carmen   Created

 *
 */
trigger UserTransfer on User_Transfer__c (after update) {
   // if already within the trigger context do not execute again.
   if (ManageUserHelper.USER_TRANSFER_TRIGGER_EXECUTING) {
      return;
   }
   ManageUserHelper.USER_TRANSFER_TRIGGER_EXECUTING = true;
   Id[] checkActivityTransferIds = new Id[]{};
   Id[] userTxferIds = new Id[]{};
   
   for (User_Transfer__c userTransfer : Trigger.new) {
      if (userTransfer.Status__c == ManageUserHelper.STATUS_ACT_TRANSFER) {
         checkActivityTransferIds.add(userTransfer.Id);
      }
      if (userTransfer.Status__c == ManageUserHelper.STATUS_USER_TXFER) {
         userTxferIds.add(userTransfer.Id);
         //launchUserTransferBatch = true;
      }
   } // for (User_Transfer__c
   
   if (!checkActivityTransferIds.isEmpty()) {
      ManageUserHelper.checkActivityTransfer(UserInfo.getSessionId(), checkActivityTransferIds);
   }
   
   if (!System.isFuture() && !System.isBatch() && !userTxferIds.isEmpty()) {
      ManageUserHelper.processUserTxfers(UserInfo.getSessionId(), userTxferIds);
   }
   
   //if (launchUserTransferBatch) {
   //   ManageUserHelper.checkForBatchJob();
   //}
   
   ManageUserHelper.USER_TRANSFER_TRIGGER_EXECUTING = false;
} // trigger UserTransfer