/* 
   Check to make sure email are being retrieved 

   
  History
  -------
  05/08/2024 Dan Carmen        Created
  05/28/2024 Dan Carmen        Fix for mixed dml

*/
global class EmailChecker implements Schedulable, Messaging.InboundEmailHandler {
   public static final String CLASSNAME='EmailChecker';
    
   global void execute(SchedulableContext SC) {
      runChecker();
   } // execute
    
   global void runChecker() {
      // see if there are any records that have not been processed.
      Web_Service_Log__c[] openLogs = [Select Id, ServiceName__c, Successful__c, ServiceStart__c, ServiceEnd__c
                                             ,ErrorMsg__c, UcRetryFailed__c, SendMsg__c
                                         From Web_Service_Log__c
                                        Where ServiceName__c = :CLASSNAME
                                          and SendMsg__c=true];
      System.debug('runChecker openLogs='+openLogs.size());
      Messaging.SingleEmailMessage[] emailsToSend = new Messaging.SingleEmailMessage[]{};
      if (!openLogs.isEmpty()) {
         handleOpenLogs(openLogs, emailsToSend);  
      }
      // create a new log
      Web_Service_Log__c log = new Web_Service_Log__c(ServiceName__c= CLASSNAME, ServiceStart__c=Datetime.now(), SendMsg__c=true);
      insert log;
      // so we only send the pertinent information
      Web_Service_Log__c sendLog = new Web_Service_Log__c(Id=log.Id);
      String emailBody = json.serialize(sendLog).replace('number_Z','number')+emailTail;
      Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
      emailToSend.setSaveAsActivity(false);
      emailToSend.setToAddresses(new String[]{emailCheckerEmail});
      emailToSend.setSubject(SUBJECT_CHECK);
      emailToSend.setPlainTextBody(emailBody);
      emailsToSend.add(emailToSend);

      Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
      // reschedule
      Apex_Batch_Control__c abc = Apex_Batch_Control__c.getInstance(CLASSNAME);
      System.debug('runChecker abc='+(abc != null));
      Integer nextMinutes = (abc != null && abc.Minutes_till_Launch__c != null ? Integer.valueOf(abc.Minutes_till_Launch__c) : 5);
      DateTime nextRunTime = DateTime.now().addMinutes(nextMinutes);
      // Schedule the test job
      String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + 
             nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + 
             nextRunTime.month() + ' ? ' + nextRunTime.year(); 
 
      if (abc != null && abc.Active__c) {
         String jobId = System.schedule('EmailChecker'+Datetime.now().format(), cronString, new EmailChecker());
         System.debug('runChecker jobId='+jobId);
      }
   } // runChecker
    
   global void handleOpenLogs(Web_Service_Log__c[] openLogs, Messaging.SingleEmailMessage[] emailsToSend) {
      // update the current logs to closed so they're not picked up again
      for (Web_Service_Log__c log : openLogs) {
         log.ServiceEnd__c = Datetime.now();
         log.SendMsg__c = false;
         log.UcRetryFailed__c = true;
         log.ErrorMsg__c = 'Next EmailCheck attempt made and this was still open';
         // so it's not picked up again
         log.Successful__c = false;
      } // for (Web_Service_Log__c log
      update openLogs;
       
      // set the EmailDomainFilter to inactive  select Id, EmailRelayId, EmailRelay.Host, FromDomain, IsActive, ToDomain from EmailDomainFilter where IsActive=true and EmailRelay.Host like '%socketlabs%'
      EmailDomainFilter[] emailFilters = [select Id, IsActive  // ,EmailRelayId, EmailRelay.Host, FromDomain, ToDomain 
                                            from EmailDomainFilter where IsActive=true and EmailRelay.Host like '%socketlabs%'];
      if (!emailFilters.isEmpty()) {
         turnOffFilter();
         //Map<String, Object> params = new Map<String, Object>();
         //Flow.Interview.Disable_Domain_Filter disableFilter = new Flow.Interview.Disable_Domain_Filter(params);
         //if (!Test.isRunningTest()) {
         //   disableFilter.start();
         //}
      } // if (!emailFilters.isEmpty
       
      // notify that the emails aren't going through
      // do we only send an email if there's an active filter?
      String emailBody = Label.EmailChecker_ErrorMsg;
      Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
      emailToSend.setSaveAsActivity(false);
      emailToSend.setToAddresses(errorEmails);
      emailToSend.setSubject('Email Seems to be Failing');
      emailToSend.setPlainTextBody(emailBody);
      emailsToSend.add(emailToSend);
      //Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{emailToSend}, false);
      
   } // handleOpenLogs
   
   @future
   global static void turnOffFilter() {
       Map<String, Object> params = new Map<String, Object>();
       Flow.Interview.Disable_Domain_Filter disableFilter = new Flow.Interview.Disable_Domain_Filter(params);
       disableFilter.start();
   } // turnOffFilter
     
   public static final String emailTail='<ThisIsTheEnd>';
   public static String emailCheckerEmail=Label.EmailCheckerEmail;
   public static Boolean sendErrors=(Label.EmailCheckerErrorEmails != 'False');
   public static String[] errorEmails = Label.EmailCheckerErrorEmails.split(',');
   public static String SUBJECT_CHECK='Email Check';

   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
      String myPlainText = email.plainTextBody;
      System.debug('handleInboundEmail subject='+email.subject);
      // this is to account for any footers or anything else added to the end - strip off the end
      Integer tailPos = (String.isNotBlank(myPlainText) ? myPlainText.indexOf(EmailChecker.emailTail) : -1);
      String emailBody = (tailPos > -1 ? myPlainText.subString(0,tailPos) : myPlainText);
      System.debug('handleInboundEmail emailBody='+String.isNotBlank(emailBody));
      Web_Service_Log__c log =  (Web_Service_Log__c)json.deserialize(emailBody, Web_Service_Log__c.class);
      System.debug('handleInboundEmail log='+log);
      log.ServiceEnd__c = Datetime.now();
      log.SendMsg__c = false;
      log.Successful__c = true;
      update log;
      return result;
   } // handleInboundEmail
    
} // classEmailChecker