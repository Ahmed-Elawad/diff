/* 
 * Test methods for the ErrorLog class
 *
 * History

 * ------- * 10/06/2014 Dan Carmen   Created - rewrite of the SObjectHelper class
   03/20/2015 Dan Carmen   Added additional functionality
   02/26/2016 Dan Carmen   Added record count on the record.
   03/14/2017 Dan Carmen   Save failed records for possible reprocessing.
   10/11/2018 Dan Carmen   Add addToDescription method
   11/19/2018 Dan Carmen   Change the order of logging - the actual error message is getting dropped off in some cases.
   12/08/2020 Dan Carmen   Added start and end times for logs
   12/14/2023 Dan Carmen   Add more logging options

 */
@isTest
public class ErrorLogTest {
   
   @testSetup
   public static void setupData() {
      ErrorLogCS__c log1 = new ErrorLogCS__c(Name='Test1', NbrErrorRetry__c=1, EmailOnError__c='dcarmen@paychex.com',LogData__c=true);
      ErrorLogCS__c log1b = new ErrorLogCS__c(Name='Test1-TestA', NbrErrorRetry__c=0, EmailOnError__c='dcarmen@paychex.com');
      ErrorLogCS__c log1c = new ErrorLogCS__c(Name='Test1-TestA-TestI', NbrErrorRetry__c=0, EmailOnError__c='dcarmen@paychex.com');
      ErrorLogCS__c log2 = new ErrorLogCS__c(Name='Test2', NbrErrorRetry__c=0, EmailOnError__c='dcarmen@paychex.com',LogData__c=false);
      ErrorLogCS__c log3 = new ErrorLogCS__c(Name='Test3', NbrErrorRetry__c=3, EmailOnError__c='dcarmen@paychex.com');
      ErrorLogCS__c[] logs = new ErrorLogCS__c[]{log1,log1b,log1c,log2,log3};
      insert logs;
   } // setupData

   static testMethod void testLogCreation() {
      // generate an exception
      Exception testException = null;
      // with no close date or status this should fail
      Opportunity opp = new Opportunity(Name='Test Opp');
      try {
         insert opp;
      } catch (Exception e) {
         testException = e;
      }
      
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      ErrorLog.LOG_DETAILS = true;
      
      System.assertEquals(true,(testException != null));
      
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test opp insert', 'testid', 'this is a test error');
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test opp insert', 'testid', testException);
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test opp insert', 'testid', testException,opp);
      
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test4', acct.Id, 'Description 4', acct);
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test5', acct.Id, 'Description 4', acct, false);
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test6', acct.Id, 'Description 4', 1, 1, 0, acct, false);
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test7', (String)acct.Id, 'Description 4', 1, 1, 0, '1', acct, false);

      ErrorLog.checkSave();
      
      System.assertEquals(7,[select count() from ErrorLog__c where ClassName__c='ErrorLogTest' and MethodName__c='testLogCreation']);
      
      ErrorLog.logError('ErrorLogTest', 'testLogCreation', 'test opp insert', 'testid', testException,opp, true);
      System.assertEquals(8,[select count() from ErrorLog__c where ClassName__c='ErrorLogTest' and MethodName__c='testLogCreation']);
      
      ErrorDetail__c[] errorDetails = new ErrorDetail__c[]{};
      errorDetails.add(new ErrorDetail__c(ErrorMessage__c='This is a test error'));
      errorDetails.add(new ErrorDetail__c(ErrorMessage__c='This is another test error'));
      ErrorLog__c errLog = ErrorLog.logError('TestWithDetails', 'AddSomeDetails', 'TestKey', null, 'This Is A description', 1, 1, 1, '1', opp, true, errorDetails);
      System.assertEquals(true, errLog.Id != null);
      System.assertEquals(2,[select count() from ErrorDetail__c where ErrorLog__c=:errLog.Id]);
      
   } // testLogCreation
   
   static testMethod void testGetCustomSetting() {
      System.assertEquals(null,ErrorLog.getCustomSetting('BadTest', 'BadTest', 'BadTest'));
      System.assertNotEquals(null,ErrorLog.getCustomSetting('Test1', 'TestA', 'TestI'));
      System.assertNotEquals(null,ErrorLog.getCustomSetting('Test1', 'TestB', 'TestI'));
      System.assertEquals(null,ErrorLog.getCustomSetting('BadTest', 'TestA', 'TestI'));
      System.assertNotEquals(null,ErrorLog.getCustomSetting('Test1', null, null));
   } // testGetCustomSetting
   
    static testMethod void testLog() {
       ErrorLog__c errLog1 = ErrorLog.getLog('Test1');
       ErrorLog__c errLog2 = ErrorLog.getLog('Test2');
       ErrorLog.saveLog(errLog1);
       System.assertNotEquals(null,errLog1.Id);
       ErrorLog.saveLog(errLog2);
       System.assertEquals(null,errLog2.Id);
    } // testLog
    
    static testMethod void testProcessLog() {
       ErrorLog__c errLog = ErrorLog.getProcessLog('TestProcessLog');
       Assert.areEqual('TestProcessLog', errLog.ClassName__c);
       Assert.areEqual('LOG_DATA', errLog.MethodName__c);
       Assert.areEqual('ProcessLog', errLog.CodeKey__c);
       Assert.isNotNull(errLog.DMLQueriesStart__c);
       ErrorLog.startLog1(errLog,'Process1');
       Assert.areEqual('Process1', errLog.Log1Type__c);
       Assert.isNotNull(errLog.Log1Start__c);
       Assert.isNull(errLog.Log1End__c);
       Assert.isNotNull(errLog.DMLQueriesLog1Start__c);
       Assert.isNull(errLog.DMLQueriesLog1End__c);
       ErrorLog.endLog1(errLog);
       Assert.isNotNull(errLog.Log1End__c);
       Assert.isNotNull(errLog.DMLQueriesLog1End__c);
       
       ErrorLog.startLog2(errLog,'Process2');
       Assert.areEqual('Process2', errLog.Log2Type__c);
       Assert.isNotNull(errLog.Log2Start__c);
       Assert.isNull(errLog.Log2End__c);
       Assert.isNotNull(errLog.DMLQueriesLog2Start__c);
       Assert.isNull(errLog.DMLQueriesLog2End__c);
       ErrorLog.endLog2(errLog);
       Assert.isNotNull(errLog.Log2End__c);
       Assert.isNotNull(errLog.DMLQueriesLog2End__c);
       ErrorLog.saveLog(errLog);

    } // testProcessLog
} // class ErrorLogTest