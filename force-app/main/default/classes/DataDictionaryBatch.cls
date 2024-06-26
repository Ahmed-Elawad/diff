/* 
   Batch job for the Data Dictionary object
   
  DataDictionaryBatch ddb = new DataDictionaryBatch();
  Database.executeBatch(ddb, 1);

  Apex_Batch_Control__c setup
  Name: DataDictionaryBatch
  Active: true
  Batch Title: Data Dictionary
  Batch Size: 1  (how many Data Dictionary Object records the batch will process at a time. Should be 1 due to mixed DML operations)

  History
  -------
  03/01/2021 Dan Carmen           Created
  03/30/2021 Dan Carmen           Add ability to count records
  01/06/2022 Dan Carmen           Add NotifyAllChanges__c

 */
global without sharing class DataDictionaryBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {

   global String processNotes = '';

   global JobHelper jh = new JobHelper('DataDictionaryBatch');
    
   global void execute(SchedulableContext SC) {
      DataDictionaryBatch ddb = new DataDictionaryBatch();
      Database.executeBatch(ddb, 1);
   } // execute

   global Map<String,String[]> notificationMap = new Map<String,String[]>();
   global Database.QueryLocator start(Database.BatchableContext BC){
      jh.setStarted();
      
      return Database.getQueryLocator([Select Id, Name, ObjectAPIName__c, NotifyAllChanges__c, NotifyNewField__c, ProcessNotes__c
                                             ,LatestCount__c, EarliestCount__c, PreviousCount__c
                                             ,Active__c, CountRecords__c
                                        From DataDictionaryObject__c
                                       Where Active__c=true
                                          or CountRecords__c=true]);
   } // start
   
   global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
      // should only process 1 record at a time
      DataDictionaryObject__c ddo = (DataDictionaryObject__c)scope[0];
      processNotes += '<br/><br/>Processing '+ddo.Name;
      if (ddo.Active__c) {
         handleFields(ddo);
      }
      if (ddo.CountRecords__c) {
         countRecords(ddo);
      }
      update ddo;
   } // execute
    
   global void countRecords(DataDictionaryObject__c ddo) {
      String query = 'select count() from '+ddo.ObjectAPIName__c;
      System.debug('countRecords query='+query);
      try {
         Integer recCount = Database.countQuery(query);
         StringHelper.addToProcessNotes(ddo,'countQuery recCount='+recCount);
         DataDictionaryCount__c ddc = new DataDictionaryCount__c(DataDictionaryObject__c=ddo.Id,Name=ddo.ObjectAPIName__c+'-'+Datetime.now().format('MM/dd/yyyy')
                                                                ,Count__c=recCount, CountDate__c=Date.today());
         // select the earliest record
         DataDictionaryCount__c[] ddcs = [select Id, Count__c, CountDate__c 
                                          from DataDictionaryCount__c 
                                         where DataDictionaryObject__c=:ddo.Id
                                           order by CountDate__c asc
                                         limit 1];
         insert ddc;
         ddo.PreviousCount__c = ddo.LatestCount__c;
         ddo.LatestCount__c = ddc.Id;
         DataDictionaryCount__c earliest = (!ddcs.isEmpty() ? ddcs[0] : ddc);
         if (ddo.EarliestCount__c == null || ddo.EarliestCount__c != earliest.Id) {
            ddo.EarliestCount__c = earliest.Id;
         }
      } catch (Exception e) {
         StringHelper.addToProcessNotes(ddo,'countQuery failed: '+e.getMessage());
      }
   } // countRecords
    
   global void handleFields(DataDictionaryObject__c ddo) {
      DataDictionaryDQController.populateDict(ddo);
       
      String notes = '\n Nbr SF fields found: '+DataDictionaryDQController.nbrFieldsFromToolingAPI;
      notes += ' \n Nbr fields excluded: '+DataDictionaryDQController.nbrExcluded;
      notes += ' \n Nbr existing Data Dictionary Records: '+DataDictionaryDQController.nbrDataDictionaryRecs;
      notes += ' \n Nbr Inserts: '+DataDictionaryDQController.nbrInserts;
      notes += ' \n Nbr Updates: '+DataDictionaryDQController.nbrUpdates;
      notes += ' \n Nbr Deletes: '+DataDictionaryDQController.nbrDeletes;
      StringHelper.addToProcessNotes(ddo,notes);
      //processNotes += notes;
      processNotes += '<br/> Nbr SF fields found: '+DataDictionaryDQController.nbrFieldsFromToolingAPI;
      processNotes += '<br/> Nbr fields excluded: '+DataDictionaryDQController.nbrExcluded;
      processNotes += '<br/> Nbr existing Data Dictionary Records: '+DataDictionaryDQController.nbrDataDictionaryRecs;
      processNotes += '<br/> Nbr Inserts: '+DataDictionaryDQController.nbrInserts;
      processNotes += '<br/> Nbr Updates: '+DataDictionaryDQController.nbrUpdates;
      processNotes += '<br/> Nbr Deletes: '+DataDictionaryDQController.nbrDeletes;
      processNotes += '<br/>';
      // compile all of the notifications
      if (!DataDictionaryDQController.notificationMap.isEmpty()) {
         for (String key : DataDictionaryDQController.notificationMap.keySet()) {
            String[] existingNotifies = (notificationMap.containsKey(key) ? notificationMap.get(key) : new String[]{});
            existingNotifies.addAll(DataDictionaryDQController.notificationMap.get(key));
            notificationMap.put(key,existingNotifies);
         } // for (String key
      } // if (!DataDictionaryDQController

   } // handleFields
    
   global void finish(Database.BatchableContext bc){
      String subject='DataDictionaryBatch finished';
      //String body = processNotes;
      //for (String key : notificationMap.keySet()) {
      //    String[] notifies = notificationMap.get(key);
      //    for (String notify : notifies) {
      //       body += '\n'+notify;
      //    }
      //}
      String jobNotes = processNotes;
      DataDictionaryNotify__c[] notifies = [Select Id, Name, Active__c, EmailsToNotify__c from DataDictionaryNotify__c where Active__c=true];
      Messaging.SingleEmailMessage[] msgs = new Messaging.SingleEmailMessage[]{};
      for (DataDictionaryNotify__c ddn : notifies) {
         // always send an email on a completion of a job, even if no changes
         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String body = processNotes;
         String[] bodyParts = notificationMap.get(ddn.Name);
         if (bodyParts != null) {
            for (String bodyPart : bodyParts) {
               body += '\n\n'+bodyPart;
            }
            // so we can log everything to Job Tracker.
            jobNotes += '\n\n'+body;
         }
         String[] emails = ddn.EmailsToNotify__c.split(',');
         mail.setToAddresses(emails);
         mail.setSaveAsActivity(false);
         mail.setSubject(subject);
         mail.setHtmlBody(body);
         msgs.add(mail);
      } // for (DataDictionaryNotify__c ddn
      if (!msgs.isEmpty()) {
         Messaging.sendEmail(msgs);       
      }
      jh.completeJob(bc, 'DataDictionaryBatch', jobNotes);

   } // finish
    
    

} // class DataDictionaryBatch