/**
 * Test methods for ChatterEmailHandler

  History
  -------
  10/15/2019 Dan Carmen        Created
  08/31/2021 Dan Carmen        Commented out code
  
 */
@isTest
private class ChatterEmailHandlerTest {

   static testMethod void testEmail() {
      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = 'This is an email body';
      System.debug('testEmail plainTextBody='+email.plainTextBody);
      email.fromAddress = 'dcarmen@paychex.com';
      email.subject='Chatter Message Request'; 
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      ChatterEmailHandler ceh = new ChatterEmailHandler();

      System.debug('testEmail before startTest');
      ceh.handleInboundEmail(email, env);
       /*
      Referral__c ref1 = new Referral__c(Name='Ref1');
      Referral__c ref2 = new Referral__c(Name='Ref2');
      Referral__c[] refs = new Referral__c[]{ref1,ref2};
      insert refs;
      
      Id[] recIds = new Id[]{ref1.Id,ref2.Id};

      String recIdStr = String.join(recIds, ChatterMessageSend.ID_SEPARATOR);
      String body = ChatterMessageSend.CHAT_EMAIL_MESSAGE+recIdStr;

      messaging.Inboundemail email = new messaging.Inboundemail();
      email.plainTextBody = body;
      System.debug('testEmail plainTextBody='+email.plainTextBody);
      email.fromAddress = 'dcarmen@paychex.com';
      email.subject='Chatter Message Request'; 
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      ChatterEmailHandler ceh = new ChatterEmailHandler();

      System.debug('testEmail before startTest');
      Test.startTest();
      ceh.handleInboundEmail(email, env);
      Test.stopTest();
      System.debug('testEmail after stopTest');
      */
   } // testEmail
} // ChatterEmailHandlerTest