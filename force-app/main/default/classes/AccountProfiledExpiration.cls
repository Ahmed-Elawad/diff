/* Batch process to find expired hold outs on accounts and remove them
   
  History
  -------
  12/16/2016 Jacob Hinds   Created
  12/13/2021 Added phase field to query to update the phase field to '0' when profiled is false and profile expiration date is less than today---Jaipal
*/
global without sharing class AccountProfiledExpiration implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The total number of account records found. */
   global Integer numberAccounts = 0;
   /** The time the process started. */
   global DateTime startTime;
   
   global Date checkDate = Date.today();
   
   /** messages that occur during the process. */
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper('AccountProfiledExpiration');

   global AccountProfiledExpiration() {
      startTime = DateTime.now();
   } // UserUpdateFromContact
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      
      return Database.getQueryLocator([SELECT id,Profiled__c,Profiled_Date__c,Profiled_Expiration_Date__c,Phase__c
                                         FROM Account 
                                        WHERE Profiled__c= true AND Profiled_Expiration_Date__c <= :checkDate LIMIT 100000]);
   } // start

   global static Integer BATCH_SIZE=500;

   /** In order to schedule a batch run 
    */
   global void execute(SchedulableContext sc) {
      AccountProfiledExpiration ape = new AccountProfiledExpiration();
      database.executeBatch(ape, 500);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Account> accts = (List<Account>)scope;
      numberAccounts += accts.size();
      List<Account> updateAccts = new List<Account>();
      for (Account acct : accts) {
         
          acct.Profiled__c = false; 
         acct.Profiled_Date__c = null; 
         acct.Profiled_Expiration_Date__c = null; 
         acct.Phase__c='0';
         updateAccts.add(acct);
      }
      if (!updateAccts.isEmpty()) {
         try {
            update updateAccts;
         } catch (Exception e) {
            ErrorLog.logError('AccountProfiledExpiration', 'execute', 'updateAccts', updateAccts[0].Id, e, updateAccts[0],true);
         }
      }
   } // execute
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Accounts Processed: '+numberAccounts+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'AccountProfiledExpiration', message);
   } // finish
   
   
} // class HoldOutAcctBatch