/* Batch process to create new users. 
   
   History
   -------
   06/21/2012 Dan Carmen   Created
   06/28/2012 Dan Carmen   Modified to use JobHelper class
   11/21/2012 Dan Carmen   Modified to only select Chatter Free requests
   01/22/2013 Dan Carmen   Changes to allow Temporary Emps/Reactivations
  
 */
global with sharing class AddUserBatch implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   global JobHelper jh = new JobHelper('AddUserBatch');

   global AddUserBatch() {
   } // AddUserBatch
   
   /** The total number of requests found. */
   global Integer numberRequests = 0;
   
   /** The total number of User records created. */
   global Integer numberCreated = 0;
   
   /** The total number that failed to create. */
   global Integer numberFailed = 0;

   global String statusMsg = '';
   global AddUserController auc = new AddUserController();
   
   /** Keep track of the user status messages by email address. */
   global Map<String,String> statusMsgMap = new Map<String,String>();
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.saveJob();
      return Database.getQueryLocator([SELECT Id, Name
                                             ,Approver_Notes__c
                                             ,Contact__c
                                             ,Cost_Center__c   
                                             ,FirstName__c
                                             ,LastName__c
                                             ,Manager__c
                                             ,New_User_Email__c
                                             ,Notes__c
                                             ,Request_Complete__c
                                             ,Requestor_Email__c  
                                             ,Request_Type__c
                                             ,Status__c
                                             ,Temporary_Employee__c
                                             ,User__c
                                             ,User_to_Mirror__c
                                         FROM NewUserRequest__c 
                                        WHERE Request_Complete__c=false
                                          and Status__c = 'Pending'
                                          and Request_Type__c = 'Chatter Free User'
                                          limit 100]);
   } // start

   global static Integer BATCH_SIZE=5;
   
   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      AddUserBatch cb = new AddUserBatch();
      database.executeBatch(cb, BATCH_SIZE);
   } // execute

   // the request records to update
   global List<NewUserRequest__c> updateRequests = new NewUserRequest__c[]{};

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<NewUserRequest__c> requests = (List<NewUserRequest__c>)scope;
      numberRequests += requests.size();
      
      //NewUserRequest__c[] updateRequests = new NewUserRequest__c[]{};
      
      for (NewUserRequest__c nur : requests) {
      	auc.clearSearchVariables();
      	auc.setupRequest(nur.Id);
  
      	Boolean userCreated = auc.createUser(auc.newNur);
         if (userCreated && auc.saveNewUser(auc.newNur)) {
            numberCreated++;
         } else {
            numberFailed++;
         }
         
         statusMsg += '\n'+auc.newNur.Notes__c;
         
         // if the email addresses are different, send an email to the requestor
         if (auc.newNur.Requestor_Email__c != null && auc.newNur.Requestor_Email__c != auc.newNur.New_User_Email__c) {
            String emailMsg = statusMsgMap.get(auc.newNur.Requestor_Email__c);
            emailMsg = (emailMsg == null ? '' : emailMsg)+' \n'+auc.newNur.Notes__c;
            statusMsgMap.put(auc.newNur.Requestor_Email__c,emailMsg);

         }
         // clear out the references
         auc.newNur.User__r = null;
         updateRequests.add(auc.newNur);
         
         //if (chatMethods.checkForGroupMembers(cgs)) {
         //   updateGrps.add(cgs);
         //}
      } // for (Chatter_Group_Setup__c
      
      if (!updateRequests.isEmpty()) {
         update updateRequests;
      }
      
   } // execute
   
   global void finish(Database.BatchableContext BC){
      String message = '\nTotal User Requests Processed: '+numberRequests+' '; 
      message += '\nTotal Users created: '+auc.nbrCreated+' '; 
      message += '\nTotal Users failed: '+auc.nbrFailed+' ';
      
      message += '\n\n'+statusMsg;

      System.debug('AddUserBatch finish message='+message);
      
      jh.completeJob(bc, 'Add User update process', message);

      if (!updateRequests.isEmpty()) {
         update updateRequests;
      }
      

   } // finish 
   

} // class AddUserBatch