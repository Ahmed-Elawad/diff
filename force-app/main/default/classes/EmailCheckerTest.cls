/* 
   Test Methods for EmailChecker 

   
  History
  -------
  05/09/2024 Dan Carmen        Created
  05/28/2024 Dan Carmen        Fix for mixed dml

*/
@isTest
public class EmailCheckerTest {

   static testMethod void checkWithOneOpen() {
      Web_Service_Log__c log = new Web_Service_Log__c(ServiceName__c=EmailChecker.CLASSNAME, ServiceStart__c=Datetime.now(), SendMsg__c=true);
      insert log;
      EmailChecker ec = new EmailChecker();
      ec.runChecker();
      log = [Select Id, ServiceName__c, Successful__c, ServiceStart__c, ServiceEnd__c
                   ,ErrorMsg__c, UcRetryFailed__c, SendMsg__c
               From Web_Service_Log__c
              Where Id=:log.Id];
      Assert.isFalse(log.Successful__c);
      Assert.isFalse(log.SendMsg__c);
      Assert.isTrue(log.UcRetryFailed__c);
       
      // should be a new log created
      Web_Service_Log__c newLog = [Select Id, ServiceName__c, ServiceStart__c
                                     From Web_Service_Log__c
                                    Where Successful__c = false and SendMsg__c=true];
      
   } // checkWithOneOpen
    
   static testMethod void testCloseLog() {
      Web_Service_Log__c log = new Web_Service_Log__c(ServiceName__c=EmailChecker.CLASSNAME, ServiceStart__c=Datetime.now(), SendMsg__c=true);
      insert log;
      Web_Service_Log__c sendLog = new Web_Service_Log__c(Id=log.Id);
      String emailBody = json.serialize(sendLog).replace('number_Z','number')+EmailChecker.emailTail;

      Messaging.Inboundemail email = new Messaging.Inboundemail();
      email.subject = EmailChecker.SUBJECT_CHECK;
      email.plainTextBody = emailBody;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      EmailChecker ec = new EmailChecker();
      Test.startTest();
      ec.handleInboundEmail(email, env);
      Test.stopTest();
      log = [Select Id, ServiceName__c, Successful__c, ServiceStart__c, ServiceEnd__c
                   ,ErrorMsg__c, UcRetryFailed__c, SendMsg__c
               From Web_Service_Log__c
              Where Id=:log.Id];
      Assert.isTrue(log.Successful__c);
      Assert.isFalse(log.SendMsg__c);
      Assert.isNotNull(log.ServiceEnd__c);
      Assert.isFalse(log.UcRetryFailed__c);
   } // testCloseLog
    
} // class EmailCheckerTest