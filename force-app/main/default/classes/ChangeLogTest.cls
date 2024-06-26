/* Test methods for the ChangeLog class
   
  History
  -------
  09/09/2014 Dan Carmen   Created
  08/20/2018 Cindy Freeman	added test for getFileWrapper
  
 */
@isTest
private class ChangeLogTest {

   static testMethod void testLogData() {
   	// by default it won't log
      ChangeLog.addToLog('1','2','3');
      System.assertEquals(false,ChangeLog.hasLogData());

   	ChangeLog.allowLogging = true;
      ChangeLog.addToLog('1','2','3');
      System.assertEquals('1,2,3\n',ChangeLog.logData);
      System.assertEquals(true,ChangeLog.hasLogData());
      Attachment attach = ChangeLog.getAttachment('test');
      System.assertEquals(true,attach.Name.startsWith('test'));
      FileWrapper fileWrap = ChangeLog.getFileWrapper('test');
      System.assertEquals(true, fileWrap.fileName.startsWith('test'));
      System.assertEquals(true, fileWrap.displayName.startsWith('test'));
      
   } // testLogData
   
} // class ChangeLogTest