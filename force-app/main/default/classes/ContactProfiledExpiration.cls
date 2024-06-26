/* Batch process to find expired hold outs on contacts and remove them
 * Mirrors Account process for profile expiration
   
  History
  -------
  03/13/2017 Jermaine Stukes   Created
 */
global without sharing class ContactProfiledExpiration implements Database.Batchable<SObject>, Database.Stateful , Schedulable {

   /** The total number of contacts records found. */
   global Integer numberContacts = 0;
   /** The time the process started. */
   global DateTime startTime;
   
   global Date checkDate = Date.today();
   
   /** messages that occur during the process. */
   global String processNotes = '';
   
   global JobHelper jh = new JobHelper('HoldOutContactBatch');

   global ContactProfiledExpiration() {
      startTime = DateTime.now();
   } // UserUpdateFromContact
   
   global Database.QueryLocator start(Database.BatchableContext BC){
      // save the record - show that the job started
      jh.setStarted();
      
       return Database.getQueryLocator([SELECT id,Profiled__c,Profiled_Date__c,Profiled_Expiration_Date__c
                                        FROM Contact 
                                        WHERE Profiled__c = true AND Profiled_Expiration_Date__c <= :checkDate LIMIT 100000]);
   } // start

   global static Integer BATCH_SIZE=500;

   /** In order to schedule a batch run
    */
   global void execute(SchedulableContext sc) {
      ContactProfiledExpiration ape = new ContactProfiledExpiration();
      database.executeBatch(ape, 500);
   } // execute

   /** Execute a batch.
    */
   global void execute(Database.BatchableContext BC, List<SObject> scope){
      List<Contact> contacts = (List<Contact>)scope;
      numberContacts += contacts.size();
      List<Contact> updateContacts = new List<Contact>();
      for (Contact contact : contacts) {
         contact.Profiled__c = false;
         contact.Profiled_Date__c = null;
         contact.Profiled_Expiration_Date__c = null;
         updateContacts.add(contact);
      }
      if (!updateContacts.isEmpty()) {
         try {
            update updateContacts;
         } catch (Exception e) {
            ErrorLog.logError('HoldOutContactBatch', 'execute', 'updateContacts', updateContacts[0].Id, e, updateContacts[0],true);
         }
      }
   } // execute
   
   global void finish(Database.BatchableContext bc){
      String message = '\nTotal Contacts Processed: '+numberContacts+' '; 
      
      message += '\n\n'+processNotes;
      
      jh.completeJob(bc, 'User Update From Contact update', message);
   } // finish
   
   
} // class HoldOutAcctBatch