/* 
   Email Handler to start and stop jobs as a specific user
   
  History
  -------
  08/17/2021 Dan Carmen   Created
  05/10/2023 Dan Carmen   Increment API

 */
@isTest
public class EmailJobManagerTest {
   static testMethod void testMail() {
      // test bad subject
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      email.fromAddress = 'john@smith.com';
      email.subject = 'Bad Subject';
      Messaging.InboundEmailResult result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(false,result.success);
      System.debug('testMail Start 1 result.message='+result.message);
      System.assertEquals('Subject needs to begin with one of these actions: Start,Stop,Status', result.message);
       
      // test without the WebServiceSettings__c 
      email.subject = 'Start '+DataFluxDeltaBatch.CLASSNAME;
      result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(false,result.success);
      System.assertEquals(true, result.message.contains('Could not find a Batch Control setting'));
       
      email.subject = 'Stop '+DataFluxDeltaBatch.CLASSNAME;
      result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(false,result.success);
      System.debug('testMail Stop 1 result.message='+result.message);
      System.assertEquals(true, result.message.contains('Could not find a Batch Control setting'));
       
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=DataFluxDeltaBatch.CLASSNAME, Active__c=true, AdditionalEmails__c='jim@smith.com', SendCompletionEmail__c=true);
      insert abc;

      email.subject = 'Start '+DataFluxDeltaBatch.CLASSNAME;
      result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(true, result.success);
      System.debug('testMail Start 2 result.message='+result.message);
      System.assertEquals(true, result.message.contains('has started'));
       
      abc = [Select Id, Name, EmailTest__c, Active__c, ProcessNotes__c from Apex_Batch_Control__c where Name=:DataFluxDeltaBatch.CLASSNAME];
      System.assertEquals('john@smith.com',abc.EmailTest__c);
      System.assertEquals(true,abc.Active__c);
      System.debug('testMail Start 2 abc.ProcessNotes__c='+abc.ProcessNotes__c);
      System.assertEquals(true,abc.ProcessNotes__c.contains('Started via EmailJobManager'));

      email.subject = 'Stop '+DataFluxDeltaBatch.CLASSNAME;
      result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(true, result.success);
      System.debug('Dataflux Stop 2 result.message='+result.message);
      System.assertEquals(true, result.message.contains('has been stopped'));

      abc = [Select Id, Name, EmailTest__c, Active__c, ProcessNotes__c from Apex_Batch_Control__c where Name=:DataFluxDeltaBatch.CLASSNAME];
      System.assertEquals('john@smith.com',abc.EmailTest__c);
      System.assertEquals(false,abc.Active__c);
      System.debug('testMail Stop 2 abc.ProcessNotes__c='+abc.ProcessNotes__c);
      System.assertEquals(true,abc.ProcessNotes__c.contains('Stopped via EmailJobManager'));

      email.subject = 'Status '+DataFluxDeltaBatch.CLASSNAME;
      result = new EmailJobManager().handleInboundEmail(email, env);
      System.assertEquals(true, result.success);
      System.debug('Dataflux Stop 2 result.message='+result.message);
      //System.assertEquals(true, result.message.contains('No running or scheduled jobs were found'));

   } // testStart
    
   static testMethod void testRun() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name=DataFluxDeltaBatch.CLASSNAME, Active__c=false, AdditionalEmails__c='jim@smith.com', SendCompletionEmail__c=true);
      insert abc;

      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      email.fromAddress = 'john@smith.com';

      email.subject = 'Run '+DataFluxDeltaBatch.CLASSNAME;
      Messaging.InboundEmailResult result = new EmailJobManager().handleInboundEmail(email, env);
      Assert.isFalse(result.success);
      System.debug('testMail Start 2 result.message='+result.message);
      Assert.isTrue(result.message.contains('is not active'), result.message);

      abc.Active__c = true;
      update abc;
       
      result = new EmailJobManager().handleInboundEmail(email, env);
      Assert.isTrue(result.success);
      System.debug('testMail Start 2 result.message='+result.message);
      Assert.isTrue(result.message.contains('has started'), result.message);
   } // testRun
    
   static testMethod void testMsgs() {
      EmailJobManager ejm = new EmailJobManager();
      String msg = ejm.getAsyncMsg('JobName', 'jobId', 'Pending', 'This Is Pending', 13, 13, 6 );
      Assert.isTrue(msg.startsWith('Found a running job for JobName'),msg);
       
      msg = ejm.getCronMsg('JobName', 'jobId', 'Confusion', Datetime.now());
      Assert.isTrue(msg.startsWith('Found a scheduled job for JobName'),msg);
 
   } // testMsgs
    
} // class EmailJobManagerTest