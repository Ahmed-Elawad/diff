/* 
   Batch job for compiling Email Information
   
  EmailMessageBatch emb = new EmailMessageBatch();
  Database.executeBatch(dlb, 200);

  Apex_Batch_Control__c setup
  Name: EmailMessageBatch
  Active: true
  Batch Title: Email Message Batch
  Batch Size: 200

  Retrieve recent EmailMessage

  History
  -------
  06/25/2021 Dan Carmen   Created
  07/11/2022 Dan Carmen   Check check days from the custom setting

 */
global without sharing class EmailMessageBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
   public static String CLASSNAME='EmailMessageBatch';
    
    
   global void execute(SchedulableContext SC) {
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      if (abc != null && abc.Active__c) {
         Database.executeBatch(new EmailMessageBatch(), Integer.valueOf(abc.BatchSize__c));
      }
   } // execute
    
   global JobHelper jh = new JobHelper(CLASSNAME);
    
   global Integer nbrRecs=0;

   global Database.QueryLocator start(Database.BatchableContext BC){
      jh.setStarted();
       
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      Integer nbrDaysToCheck = (abc != null && abc.Check_Days__c != null ? Integer.valueOf(abc.Check_Days__c) : 7 );

      // if no previous run date, go back 14 days (or what we have defined in the custom setting) 
      Datetime checkDate = Datetime.now().addDays(-nbrDaysToCheck);
      // these values will be reselected (for performance) so we're keeping the query simple here.
      return Database.getQueryLocator([Select Id
                                             //,ActivityId
                                             //,FirstOpenedDate
                                             //,IsBounced
                                             //,IsOpened
                                             //,LastOpenedDate
                                             //,MessageDate
                                             //,ReplyToEmailMessageId
                                             //,Account__c
                                             //,Contact__c
                                             //,EmailTemplateFolder__c
                                             //,EmailTemplateFolderId__c
                                             //,EmailTemplateId__c
                                             //,EmailTemplateName__c
                                             //,Lead__c
                                             //,NumberOfOpens__c
                                             //,ProcessNotes__c
                                         From EmailMessage
                                        Where LastModifiedDate > :checkDate
                                          and LastOpenedUpdate__c = true]);
   } // start

   global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
      EmailMessage[] msgs = (EmailMessage[])scope;
      nbrRecs += msgs.size();
      // we just need to save the records so the triggers fire
      EmailMessageMethods.SKIP_TRIGGER=false;
      DmlHelper.performDML2(msgs, DmlHelper.DML_UPDATE, CLASSNAME, 'CLASSNAME', 'Update EmailMessages', true);
   } // execute
    
   global void finish(Database.BatchableContext batchableContext){
      jh.completeJob(batchableContext, 'EmailMessageBatch job', 'Finished processing '+nbrRecs+' records');
   } // finish

} // EmailMessageBatch