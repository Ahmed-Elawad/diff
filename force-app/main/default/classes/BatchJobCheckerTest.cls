/* 
 * A batch job for checking Batch job checker 
 *
 * History
 * -------
 * 11/3/2014 Cindy Freeman   Created
 * 03/06/2019 Cindy Freeman		modified to handle jobs that failed to load records
 */
@isTest
private class BatchJobCheckerTest {

    static testMethod void myUnitTest() {
        Test.startTest();
        populateBatchJobChecker();
        BatchJobChecker__c[] bjcList = [Select Name, IsActive__c, Sobject__c, WhereClause__c, Soqlstmt__c, MaxCount__c,
										EmailBody__c, EmailAddresses__c from BatchJobChecker__c];
		System.assertEquals(5, bjcList.size());
												
        List<Web_Service_Log__c> logList = new List<Web_Service_Log__c>();
        Integer i = 0;
        // create 5 logs to find
        while (i < 5)
        {	Web_Service_Log__c wsl = new Web_Service_Log__c (ServiceName__c = 'DFDeltaSvc', SendMsg__c = true);
        	logList.add(wsl);
        	i++;
        }
        insert logList;
        Web_Service_Log__c[] tempList = [Select Id from Web_Service_Log__c where ServiceName__c = 'DFDeltaSvc' and SendMsg__c = True];
        System.assertEquals(5, tempList.size());
        
        // run batch job
        BatchJobChecker jobChecker = new BatchJobChecker();        
        Database.executeBatch(jobChecker);        
        Test.stopTest();
       
    } // myUnitTest
    
    /** populate setting used to determine which batch job to check
    */
    
   public static void populateBatchJobChecker() { 
        BatchJobChecker__c bjc1 = new BatchJobChecker__c (
            Name = 'DFDeltaSvc'            
            ,IsActive__c = true
            ,MaxCount__c = 2
            ,Sobject__c = 'Web_Service_Log__c'
            ,WhereClause__c = 'ServiceName__c = \'DFDeltaSvc\' and SendMsg__c = True'
            ,EmailAddresses__c = 'cmfreema@paychex.com,dcarmen@paychex.com'
            ,EmailBody__c = 'Testing Email Body');
        insert bjc1;
        BatchJobChecker__c bjc2 = new BatchJobChecker__c (
            Name = 'DFDeltaSvc'            
            ,IsActive__c = true
            ,MaxCount__c = 2
            ,SoqlStmt__c = 'Select count() from Web_Service_Log__c where ServiceName__c = \'DFDeltaSvc\' and SendMsg__c = True'
            ,EmailAddresses__c = 'cmfreema@paychex.com'
            ,EmailBody__c = 'Testing Email Body');
        insert bjc2;
        BatchJobChecker__c bjc3 = new BatchJobChecker__c (
            Name = 'DFDeltaSvc'            
            ,IsActive__c = true
            ,MaxCount__c = 2
            ,SoqlStmt__c = 'Select count() from WebServiceLog where ServiceName__c = \'DFDeltaSvc\' and SendMsg__c = True'
            ,EmailAddresses__c = 'cmfreema@paychex.com'
            ,EmailBody__c = 'Testing Email Body');
        insert bjc3;
        BatchJobChecker__c bjc4 = new BatchJobChecker__c (
            Name = 'EVE-Checks'            
            ,IsActive__c = true
            ,MaxCount__c = 0
            ,SoqlStmt__c = 'Select count() from WebServiceLog where ServiceName__c = \'EVE-Checks\' and SendMsg__c = True'
            ,EmailAddresses__c = 'cmfreema@paychex.com'
            ,EmailBody__c = 'Testing Email Body');
        insert bjc4;
		BatchJobChecker__c bjc5 = new BatchJobChecker__c (
            Name = 'EVE-Checks'            
            ,IsActive__c = true
            ,MaxCount__c = -1
            ,SoqlStmt__c = 'Select count() from Client_Reference__c where CreatedDdate = TODAY'
            ,EmailAddresses__c = 'cmfreema@paychex.com'
            ,EmailBody__c = 'Testing Email Body');
        insert bjc5;
        return;
   } // populateBatchJobChecker
             
}