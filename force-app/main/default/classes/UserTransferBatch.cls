/* 
 * A batch job to purge from the database
 *
 * History
 * -------
   06/02/2015 Dan Carmen   Created
 *
 */
global with sharing class UserTransferBatch 
   //implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts , Schedulable
                                              {
/*
   public static final String USER_TRANSFER_BATCH='UserTransferBatch';

   global static Integer BATCH_SIZE=2;

   // The total number of transfer records found.
   global Integer numberTransfers = 0;
   // The total number of records purged
   global Integer numberPurged = 0;
   // The time the process started. 
   global DateTime startTime;
   
   // messages that occur during the process. 
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper('UserTransferBatch');

   global Boolean errorOccurred=false;
   
   global UserTransferBatch() {
      startTime = DateTime.now();
   } // UserTransferBatch
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      ManageUserHelper.setBatchRunning();
      jh.setStarted();
      return Database.getQueryLocator([SELECT Id
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
                                             ,New_User__c
                                             ,New_User__r.Id
                                             ,Status__c
                                             ,StrX__c
                                             ,Username__c
                                             ,UserSaveStart__c
                                             ,UserSaveEnd__c
                                         FROM User_Transfer__c 
                                        WHERE (HasGrpMembershipToCopy__c = true
                                          AND GrpMembershipCopied__c = false)
                                           OR Status__c = :ManageUserHelper.STATUS_USER_TXFER]);
   } // start

   // In order to schedule a batch run
   global void execute(SchedulableContext sc) {
      UserTransferBatch utb = new UserTransferBatch();
      database.executeBatch(utb, BATCH_SIZE);
   } // execute

   // Execute a batch.
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<User_Transfer__c> transfers = (List<User_Transfer__c>)scope;
      numberTransfers += transfers.size();
      
      for (User_Transfer__c userTransfer : transfers) {
         if (userTransfer.Status__c == ManageUserHelper.STATUS_USER_TXFER) {
            handleUserTransfer(userTransfer);
         } else {
            handleGrpTransfer(userTransfer);
         }
         updateUserTransfer(UserInfo.getSessionId(), userTransfer);
      } // for (User_Transfer__c
      
      //DmlHelper.performDML(transfers, DmlHelper.DML_UPDATE, 'UserTransferBatch', 'execute', 'update the user transfers', true);
   } // execute

   global void addToMap(Map<String, Object> utMap, String key, Object value) {
      if (value != null) {
         utMap.put(key,value);
      }
   } // addToMap

   global void updateUserTransfer(String sessionId, User_Transfer__c userTransfer) {
      HttpRequest req = new HttpRequest();
      Boolean okay = true;
      req.setEndpoint('https://'+URL.getSalesforceBaseUrl().getHost()+'/services/apexrest/updateTransfer/');
      req.setMethod('POST');
      //String body = '{"userIds":'+JSON.serialize(userIds)+'}';
      
      Map<String, Object> utMap = new Map<String, Object>();
      addToMap(utMap,'userTransferId',userTransfer.Id);
      addToMap(utMap,'newUserId',userTransfer.New_User__c);
      addToMap(utMap,'status',userTransfer.Status__c);
      addToMap(utMap,'hasGrpMembership',userTransfer.HasGrpMembershipToCopy__c);
      addToMap(utMap,'grpMembershipCopied',userTransfer.GrpMembershipCopied__c);
      addToMap(utMap,'userStart',userTransfer.UserSaveStart__c);
      addToMap(utMap,'userEnd',userTransfer.UserSaveEnd__c);
      addToMap(utMap,'grpMemberStart',userTransfer.GrpMemberSaveStart__c);
      addToMap(utMap,'grpMemberEnd',userTransfer.GrpMemberSaveEnd__c);
    
      String body = json.serialize(utMap);
      System.debug(logginglevel.error, body);
      
      req.setBody(body);
      req.setHeader('Authorization', 'Bearer '+ sessionId);
      req.setHeader('Content-Type', 'application/json');
      req.setTimeout(50000);
      Http http = new Http();
      if (!test.isRunningTest()){
         System.debug('updateUserTransfer performing rest callout');
         try {
            HTTPResponse res = http.send(req);
            System.debug('updateUserTransfer res='+res+' body='+res.getBody());
            
            //XmlStreamReader reader = res.getXmlStreamReader();
            //while(reader.hasNext()) {
            //   System.debug('Event Type:' + reader.getEventType());
            //   if (reader.getEventType() == XmlTag.START_ELEMENT) {
            //      System.debug(reader.getLocalName());
            //   }
            //   reader.next();
            //}
         } catch (Exception ex) {
            okay = false;
            ErrorLog.logError('UserTransferBatch', 'updateUserTransfer', 'Sending message', userTransfer.Id, ex, userTransfer, true);
         }
      } else {
         System.debug('updateUserTransfer calling doPost directly');
         //UserRoleUpdateREST.doPost(userIds);
      }

   } // updateUserTransfer
   
   public static final Integer COMMENTS_SIZE = User_Transfer__c.Comments__c.getDescribe().getLength();

   global void handleUserTransfer(User_Transfer__c userTransfer) {
      ManageUserController muc = new ManageUserController();
      muc.userTransfer = userTransfer;
      muc.isTxfer = true;

      UserHelper uHelper = new UserHelper();
      // select the existing user
      muc.existingUser = uHelper.getUserById(userTransfer.Existing_User__c);
      muc.userToMirror = uHelper.getUserById(userTransfer.CopyUserFrom__c);
      
      // create the xfer record
      muc.createTxferUser();

      ManageUserController.CHECK_GRP_MEMBERSHIP = true;
      try {
         muc.saveUsers();
         // send an email to the creator
         sendSuccessEmail(userTransfer,muc.survivingUser.Name, muc.survivingUser.Id, muc.nonSurvivingUser.Id);
      } catch (Exception e) {
         String existingComments = String.isNotBlank(userTransfer.Comments__c) ? userTransfer.Comments__c+'\n' : '';
         String errorMsg = e.getMessage()+'; '+e.getStackTraceString();
         userTransfer.Comments__c = (existingComments + 'Create user failed: '+errorMsg).right(COMMENTS_SIZE);
         userTransfer.Status__c = ManageUserHelper.STATUS_TXFER_ERROR; 
         sendFailureEmail(userTransfer,muc.survivingUser.Name, muc.survivingUser.Id, errorMsg);
         errorOccurred = true;
      }
   } // handleUserTransfer
   
   global void sendSuccessEmail(User_Transfer__c userTransfer, String survivingName, Id survivingId, Id nonSurvivingId) {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSaveAsActivity(false);

      String host = Utilities.instanceUrl()+'/';
         
      mail.setTargetObjectId(userTransfer.CreatedById);
      String subject = 'The User Transfer for '+survivingName+' completed.';
      mail.setSubject(subject);
      mail.setPlainTextBody (subject+' \n The active user record can be found at '+host+survivingId
                      +'\n The Inactive user record can be found at '+host+nonSurvivingId);

      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

   } // sendSuccessEmail
   
   global void sendFailureEmail(User_Transfer__c userTransfer, String survivingName, Id survivingId, String errorMsg) {
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      mail.setSaveAsActivity(false);

      String host = Utilities.instanceUrl()+'/';
         
      mail.setTargetObjectId(userTransfer.CreatedById);
      String subject = 'The User Transfer for '+survivingName+' Failed!';
      mail.setSubject(subject);
      mail.setPlainTextBody (subject+' \n The original user record can be found at '+host+survivingId
                      +'\n The error message is: '+errorMsg);

      Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

   } // sendSuccessEmail
   
   global void handleGrpTransfer(User_Transfer__c transfer) {
      User survivingUser = (transfer.ExistingUserIsSurvivor__c ? transfer.Existing_User__r : transfer.New_User__r);
      ManageUserController.checkGrpMembership(transfer, survivingUser, transfer.CopyUserFrom__r);
   } // handleGrpTransfer
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal User Transfers Processed: '+numberTransfers+' '; 
      //message += '\nTotal records purged: '+numberPurged+' '; 
      //message += '\nTotal Users updated: '+nbrUsersUpdated+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'User Transfer Batch', message);
      
      // see if more records
      Integer nbrPendingRecs = [SELECT count() FROM User_Transfer__c 
                                        WHERE (HasGrpMembershipToCopy__c = true
                                          AND GrpMembershipCopied__c = false)
                                           OR Status__c = :ManageUserHelper.STATUS_USER_TXFER];
      if (nbrPendingRecs > 0 && !errorOccurred) {
         ManageUserHelper.launchBatch();
      } else {
         ManageUserHelper.setBatchComplete();
      }
   } // finish
    */
} // UserTransferBatch