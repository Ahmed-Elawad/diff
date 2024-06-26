/* 
   Test methods for the EmailMessageMethods class

   
History
-------
04/16/2021 Dan Carmen   Created
09/28/2021 Eric Porter  Check Activity Test Added 
02/25/2022 Dan Carmen   Added check if runningUser is null
07/11/2022 Dan Carmen   Change query for checkAcctOpens
05/17/2023 Dan Carmen   Additional logic around the Securities_License__c user field
03/06/2024 Dan Carmen   Exclude paychex contacts from the ctctMap

 */
@isTest
public class EmailMessageMethodsTest {
    
   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c  abc1 = new Apex_Batch_Control__c(Name=EmailMessageBatch.CLASSNAME,Active__c=true, NbrOfAttempts__c=1, BatchSize__c=100, Minutes_till_Launch__c=1);
      insert abc1;
   } // setupData
    
   static testMethod void testTemplateId() {
      System.assertEquals(0,[select count() from EmailMessage]);
      // select a random email template
      EmailTemplate template = [Select Id, Name from EmailTemplate limit 1];
       
      EmailMessage msg = new EmailMessage(EmailTemplateId=template.Id);
      insert msg;
       
      System.assertEquals(1,[select count() from EmailMessage]);
       
      msg = [Select Id, EmailTemplateId__c, EmailTemplateName__c from EmailMessage where Id=:msg.Id];
      System.assertEquals(template.Id, msg.EmailTemplateId__c);
      System.assertEquals(template.Name, msg.EmailTemplateName__c);
   } // testTemplateId
    
   static testMethod void testCheckActivityContact(){

      Account acct = new Account(Name='testAccount');
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert acct;
      Contact ctct = new Contact(LastName='Stark',Email='tstark@test.com', AccountId= acct.Id);
      ContactMethods.CONTACT_BEFORE_TRIGGER_EXECUTING=true;
      ContactMethods.CONTACT_AFTER_TRIGGER_EXECUTING=true;
      insert ctct;
       
      Lead ld = new Lead(LastName='Richards',Company='QENG', Email='richards@test.com');
      TriggerMethods.SKIP_TRIGGERS=true;
      insert ld;

      Messaging.SingleEmailMessage msg1 = new Messaging.SingleEmailMessage();
      msg1.setTargetObjectId(ctct.Id);
      msg1.setSubject('Test Email1');
      msg1.setPlainTextBody('This is an Email Body');
      msg1.setSaveAsActivity(true);
       
      Messaging.SingleEmailMessage msg2 = new Messaging.SingleEmailMessage();
      msg2.setTargetObjectId(ld.Id);
      msg2.setSubject('Test Email2');
      msg2.setPlainTextBody('This is an Email Body');
      msg2.setSaveAsActivity(true);
       
      Messaging.SingleEmailMessage[] emails = new Messaging.SingleEmailMessage[]{msg1,msg2};
      Utilities.SKIP_FUTURE=false;
      System.debug('testCheckActivityContact before email send');
       
      Test.startTest(); 
      Messaging.sendEmail(emails);
      Test.stopTest();
       
      System.assertEquals(2,[Select count() from EmailMessage]);
       
      EmailTemplate template = [Select Id, Name from EmailTemplate limit 1];

      //EmailMessage msgCtct = new EmailMessage(ActivityId=ctctTask.Id, Status='3', FromName='Some Person1', Subject='This is the Subject!', HtmlBody='<html><body><b>Hello</b></body></html>', EmailTemplateId=template.Id);
      //EmailMessage msgLead = new EmailMessage(ActivityId=leadTask.Id, Status='3', FromName='Some Person2', Subject='This is the Subject!', HtmlBody='<html><body><b>Hello</b></body></html>', EmailTemplateId=template.Id);
      //EmailMessage[] msgs = new EmailMessage[]{msgCtct, msgLead};

      //insert msgs;
      EmailMessage[] msgs = [Select Id, Lead__c, Contact__c, Account__c, LastOpenedDate, CreatedDate, Subject, NumberOfOpens__c
                                                                    ,Lead__r.Id, Lead__r.EmailLastSent__c, Lead__r.EmailLastOpened__c, Lead__r.NumberOfOpens__c
                                                                    ,Contact__r.Id, Contact__r.EmailLastSent__c, Contact__r.EmailLastOpened__c, Contact__r.NumberOfOpens__c
                                                                    ,Account__r.Id, Account__r.EmailLastSent__c, Account__r.EmailLastOpened__c, Account__r.NumberOfOpens__c
                                                                from EmailMessage];
      EmailMessage msgCtct = null;
      EmailMessage msgLd = null;
      for (EmailMessage msg : msgs) {
         System.debug('testCheckActivity msg='+msg);
         if (msg.Subject == 'Test Email1') {
            msgCtct = msg;
            System.assertEquals(null, msg.Lead__c);
            System.assertEquals(ctct.Id, msg.Contact__c);
            System.assertEquals(acct.Id, msg.Account__c); 
            System.assertEquals(null, msg.Contact__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Contact__r.EmailLastSent__c);
            System.assertEquals(null, msg.Account__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Account__r.EmailLastSent__c);
         } else if (msg.Subject == 'Test Email2') {
            msgLd = msg;
            System.assertEquals(ld.Id, msg.Lead__c);
            System.assertEquals(null, msg.Contact__c);
            System.assertEquals(null, msg.Account__c); 
            System.assertEquals(null, msg.Lead__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Lead__r.EmailLastSent__c);

         }
      }
      System.assertNotEquals(null,msgCtct);
      System.assertNotEquals(null,msgLd);
       
      msgCtct.LastOpenedDate = Datetime.now().addMinutes(1);
      msgLd.LastOpenedDate = Datetime.now().addMinutes(1);
      Utilities.SKIP_FUTURE=true;
      update msgs;
       
      msgs = [Select Id, Lead__c, Contact__c, Account__c, LastOpenedDate, CreatedDate, Subject, NumberOfOpens__c
                                                                    ,Lead__r.Id, Lead__r.EmailLastSent__c, Lead__r.EmailLastOpened__c, Lead__r.NumberOfOpens__c
                                                                    ,Contact__r.Id, Contact__r.EmailLastSent__c, Contact__r.EmailLastOpened__c, Contact__r.NumberOfOpens__c
                                                                    ,Account__r.Id, Account__r.EmailLastSent__c, Account__r.EmailLastOpened__c, Account__r.NumberOfOpens__c
                                                                from EmailMessage];
      for (EmailMessage msg : msgs) {
         System.debug('testCheckActivity msg='+msg);
         if (msg.Subject == 'Test Email1') {
            System.assertEquals(null, msg.Lead__c);
            System.assertEquals(ctct.Id, msg.Contact__c);
            System.assertEquals(acct.Id, msg.Account__c); 
            System.assertEquals(msg.LastOpenedDate, msg.Contact__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Contact__r.EmailLastSent__c);
            System.assertEquals(msg.LastOpenedDate, msg.Account__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Account__r.EmailLastSent__c);
         } else if (msg.Subject == 'Test Email2') {
            System.assertEquals(ld.Id, msg.Lead__c);
            System.assertEquals(null, msg.Contact__c);
            System.assertEquals(null, msg.Account__c); 
            System.assertEquals(msg.LastOpenedDate, msg.Lead__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Lead__r.EmailLastSent__c);

         }
      }
      System.assertNotEquals(null,msgCtct);
      System.assertNotEquals(null,msgLd);
       
      msgCtct.LastOpenedDate = Datetime.now().addMinutes(2);
      msgLd.LastOpenedDate = Datetime.now().addMinutes(2);
      Utilities.SKIP_FUTURE=true;
      EmailMessageMethods.SKIP_TRIGGER=false;
      update msgs;

      msgs = [Select Id, Lead__c, Contact__c, Account__c, LastOpenedDate, CreatedDate, Subject, NumberOfOpens__c
                                                                    ,Lead__r.Id, Lead__r.EmailLastSent__c, Lead__r.EmailLastOpened__c, Lead__r.NumberOfOpens__c
                                                                    ,Contact__r.Id, Contact__r.EmailLastSent__c, Contact__r.EmailLastOpened__c, Contact__r.NumberOfOpens__c
                                                                    ,Account__r.Id, Account__r.EmailLastSent__c, Account__r.EmailLastOpened__c, Account__r.NumberOfOpens__c
                                                                from EmailMessage];
      for (EmailMessage msg : msgs) {
         System.debug('testCheckActivity checkNbrOpens msg='+msg);
         if (msg.Subject == 'Test Email1') {
            System.assertEquals(null, msg.Lead__c);
            System.assertEquals(ctct.Id, msg.Contact__c);
            System.assertEquals(acct.Id, msg.Account__c); 
            System.assertEquals(1,msg.NumberOfOpens__c);
            System.assertEquals(msg.LastOpenedDate, msg.Contact__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Contact__r.EmailLastSent__c);
            System.assertEquals(1,msg.Contact__r.NumberOfOpens__c);
            System.assertEquals(msg.LastOpenedDate, msg.Account__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Account__r.EmailLastSent__c);
            System.assertEquals(1,msg.Account__r.NumberOfOpens__c);
         } else if (msg.Subject == 'Test Email2') {
            System.assertEquals(ld.Id, msg.Lead__c);
            System.assertEquals(null, msg.Contact__c);
            System.assertEquals(null, msg.Account__c); 
            System.assertEquals(1,msg.NumberOfOpens__c);
            System.assertEquals(msg.LastOpenedDate, msg.Lead__r.EmailLastOpened__c);
            System.assertEquals(msg.CreatedDate, msg.Lead__r.EmailLastSent__c);
            System.assertEquals(1,msg.Lead__r.NumberOfOpens__c);
         }
      }

      Database.executeBatch(new EmailMessageBatch(), 20);
   } // testCheckActivity

   static testMethod void testScheduler() {
      TestHelper.testScheduler('testEmailMessageBatch', new EmailMessageBatch());
   } // testScheduler


} // class EmailMessageMethodsTest