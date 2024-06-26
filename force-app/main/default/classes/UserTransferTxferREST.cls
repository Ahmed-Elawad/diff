/* 
 *  Update the User_Transfer__c record
 
 * History
 * -------
 * 06/05/2015 Dan Carmen     created
   07/11/2016 Dan Carmen   Add some additional debugging
   10/23/2018 Dan Carmen   Add some fields to the query
   06/01/2023 Carrie Marciano FY24 Transfer User options (originally done by Bindu)

 */
@RestResource(urlMapping='/updateTransferTxfer/*')
global without sharing class UserTransferTxferREST {

   @HttpPost
   global static String doPost(Id userTransferId) {
      System.debug('UserTransferTxferREST doPost userTransferId='+userTransferId);

      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
      
      User_Transfer__c userTransfer = [SELECT Id
                                             ,Comments__c
                                             ,Contact__c
                                             ,CopyUserFrom__c
                                             ,CopyUserFrom__r.Id
                                             ,CostCenter__c
                                             ,CreatedById
                                             ,Email__c
                                             ,Existing_User__c
                                             ,Existing_User__r.Id
                                             ,Existing_User__r.HR_Person_Id__c
                                             ,Existing_User__r.Name
                                             ,ExistingUserIsSurvivor__c
                                             ,GrpMemberSaveEnd__c
                                             ,GrpMemberSaveStart__c
                                             ,GrpMembershipCopied__c
                                             ,HasGrpMembershipToCopy__c
                                             ,IsExistingSales__c
                                             ,IsTxferSales__c
                                             ,New_User__c
                                             ,New_User__r.Id
                                             ,Status__c
                                             ,StrX__c
                                             ,Username__c
                                             ,UserSaveStart__c
                                             ,UserSaveEnd__c
                                       		 ,Role__c
                                       	     ,Profile__c
                                       		 ,Transfer_Type__c
                                       	     ,Sales_Org__c
                                         FROM User_Transfer__c 
                                        Where Id = :userTransferId];

      //userTransfer.Comments__c='class UserTransferTxferREST';
      //userTransfer.Status__c='Test Status';
      //update userTransfer;
      //return userTransfer.Id;
      return handleUserTransfer(userTransfer);
   } // doPost

   public static final Integer COMMENTS_SIZE = User_Transfer__c.Comments__c.getDescribe().getLength();

   global static String handleUserTransfer(User_Transfer__c userTransfer) {
      system.debug('handleUserTransfer begin'); 
      Boolean okay=true;
      ManageUserController muc = new ManageUserController();
      muc.userTransfer = userTransfer;
      muc.isTxfer = true;

      UserHelper uHelper = new UserHelper();
      // select the existing user
      muc.existingUser = uHelper.getUserById(userTransfer.Existing_User__c);
      muc.userToMirror = userTransfer.CopyUserFrom__c != null ? uHelper.getUserById(userTransfer.CopyUserFrom__c) : null;
      system.debug('handleUserTransfer muc.userToMirror: '+muc.userToMirror);
      
      if(userTransfer.Transfer_Type__c == 'Update User Role Only'){
        muc.updateExistingUserRole();   
      } else{
      	// create the xfer record
      	muc.createTxferUser();     
      }
      
      ManageUserController.CHECK_GRP_MEMBERSHIP = true;
      String errorMsg = null;
      UserHelper.ALLOW_ROLE_CALLOUT = false;
      System.debug('handleUserTransfer ALLOW_ROLE_CALLOUT='+UserHelper.ALLOW_ROLE_CALLOUT);
      
      try {
         UserTriggerMethods.skipInactiveQueueable = true; 
         ManageUserController.DISPLAY_VF_MSG = false;
         muc.saveUsers();
         // send an email to the creator
         sendSuccessEmail(userTransfer, muc);
      } catch (Exception e) {
         String existingComments = String.isNotBlank(userTransfer.Comments__c) ? userTransfer.Comments__c+'\n' : '';
         errorMsg = e.getMessage()+'; '+e.getStackTraceString();
         userTransfer.Comments__c = (existingComments + 'Create user failed: '+errorMsg).right(COMMENTS_SIZE);
         userTransfer.Status__c = ManageUserHelper.STATUS_TXFER_ERROR; 
         sendFailureEmail(userTransfer, muc, errorMsg); 
         
         okay = false;
      }
      
      if (okay) {
         return userTransfer.New_User__c;
      }
      
      UserHelper.ALLOW_ROLE_CALLOUT = true;

      return errorMsg;
   } // handleUserTransfer
   
   public static final String EMAIL_SUCCESS='Completed';
   public static final String EMAIL_FAIL='Failed';
   
   //global static void sendSuccessEmail(User_Transfer__c userTransfer, String survivingName, Id survivingId, Id nonSurvivingId) {   
   public static void sendSuccessEmail(User_Transfer__c userTransfer, ManageUserController muc) {    
       String host = Utilities.instanceUrl()+'/';
       String message = 'The transfer record can be found at '+host+userTransfer.Id;
       if (muc.survivingUser != null) {
       		message += '\n The active user record can be found at '+host+muc.survivingUser.Id;
       }
       if (muc.nonsurvivingUser != null) {
       		message += '\n The Inactive user record can be found at '+host+muc.nonSurvivingUser.Id;
       }                   
      sendEmail(userTransfer, muc.survivingUser.Name, EMAIL_SUCCESS, message);

   } // sendSuccessEmail
   
   //global static void sendFailureEmail(User_Transfer__c userTransfer, String survivingName, Id survivingId, String errorMsg) {
   public static void sendFailureEmail(User_Transfer__c userTransfer, ManageUserController muc, string errorMsg) {    
      String host = Utilities.instanceUrl()+'/';
      String message = 'The transfer record can be found at '+host+userTransfer.Id                   
          			  +'\nThe original user record can be found at '+host+muc.survivingUser.Id
                      +'\n The error message is: '+errorMsg;      
      sendEmail(userTransfer, muc.survivingUser.Name, EMAIL_FAIL, message); 
   } // sendFailureEmail
   
   public static void sendEmail(User_Transfer__c userTransfer, String survivingName, String successOrFail, String message) {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSaveAsActivity(false);

      String host = Utilities.instanceUrl()+'/';
         
      mail.setTargetObjectId(userTransfer.CreatedById);
      // this allows for copying in other people (like COE) on the success or failure emails
      PaychexSettings__c payxSetting = PaychexSettings__c.getInstance('UserTransferTxferREST-'+successOrFail);
      if (payxSetting != null && payxSetting.IsActive__c && String.isNotBlank(payxSetting.Attribute1__c)) {
         String[] emails = payxSetting.Attribute1__c.split(',');
         mail.setCcAddresses(emails);
      }
      String subject = 'The User Transfer for '+survivingName+' '+successOrFail+'!';
      mail.setSubject(subject);
      mail.setPlainTextBody (subject+' \n'+message);

      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

   } // sendEmail

} // UserTransferTxferREST