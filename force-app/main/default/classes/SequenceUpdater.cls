/* 
 * Update the sequence on an account.
 *
 * History
 * -------
 * 01/17/2012 Dan Carmen   Created
   02/11/2014 Dan Carmen   Commented out code
 *
 */
global with sharing class SequenceUpdater {

//implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The total number of active sequences attached to Accounts. */
   //global Integer numberSequences = 0;
   /** The number of stages changed. */
   //global Integer numberStages = 0;
   /** The number of sequences completed. */
   //global Integer nbrCompleted = 0;
   /** The time the process started. */
   /*
   global DateTime startTime;
   
   global AccountCheckSequence acs = new AccountCheckSequence();
   
   global JobHelper jh = new JobHelper('SequenceUpdater');

   global SequenceUpdater() {
      startTime = DateTime.now();
   } // SequenceUpdater
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.saveJob();
      return Database.getQueryLocator([SELECT id
                                             ,Account__r.Id
                                             ,Account__r.Name
                                             ,Account__r.Sequence_Start_Date__c
                                             ,Account__r.First_Run_Date__c
                                             ,Complete__c
                                             ,Days_Left_In_Stage__c
                                             ,Sequence__c
                                             ,Sequence_Detail__c
                                             ,Sequence_Detail__r.Id
                                             ,Sequence_Detail__r.Week_Start__c
                                             ,Stage_Start_Date__c
                                             ,Stage_End_Date__c
                                         FROM Account_Sequence_Link__c
                                        WHERE Complete__c=false
                                          and Is_Test_Record__c = :Test.isRunningTest()]);
   } // start
   
   /** In order to schedule a batch run
    */
    /*
   global void execute(SchedulableContext sc) {
      SequenceUpdater su = new SequenceUpdater();
      database.executeBatch(su, 100);
   } // execute

   /** Execute a batch.
    */
    /*
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Account_Sequence_Link__c> recs = (List<Account_Sequence_Link__c>)scope;
      numberSequences += recs.size();
      acs.checkAccountSequence(recs);
      
   } // execute
   
   global void finish(Database.BatchableContext BC){
      String message = '\nTotal Sequences Processed: '+numberSequences+' '; 
      message += '\nNumber of Accounts that changed Stages: '+numberStages+' '; 
      message += '\nNumber of Accounts the completed their Sequence: '+nbrCompleted+' '; 

      jh.completeJob(bc, 'Sequence update', message);

   } // finish
   */

} // class SequenceUpdater