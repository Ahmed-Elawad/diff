/*********************************************************************************************************************************
 Name:  DG_BatchInsertProcessor
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Test class for Batch insert processor for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	04/07/2018			Created     Created
*********************************************************************************************************************************/
@isTest
public class DG_BatchInsertProcessor_TEST {
    static testMethod void DG_BatchInsertProcessor_Test(){
    	list<Account> listAccount = new list<Account>();
    	
    	Account a = new Account(
        type = 'Prospect',
        name = 'Test Account AAA');
        
        listAccount.add(a);
        
        Test.StartTest();
    		DG_BatchInsertProcessor BatchInsertObject = new DG_BatchInsertProcessor(listAccount);
			BatchInsertObject.email = 'rick.segura@demandgen.com';
			ID batchprocessid = Database.executeBatch(BatchInsertObject);        
        Test.stopTest();
        
        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                    FROM AsyncApexJob WHERE ID =: batchprocessid ];
        
        
        System.AssertNotEquals(aaj.Id, null);
    }
}