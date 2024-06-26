/*********************************************************************************************************************************
 Name:  DG_BatchDeleteProcessor_TEST
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Test class for DG_BatchDeleteProcessorr for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	04/07/2018			Created     Created
*********************************************************************************************************************************/
@isTest
public class DG_BatchDeleteProcessor_TEST {
    
    static testMethod void DG_BatchDeleteProcessor_Test(){
    	list<Account> listAccount = new list<Account>();
    	
    	Account a = new Account(
        type = 'Prospect',
        name = 'Test Account AAA');
        
        listAccount.add(a);
        insert listAccount;
        
        Test.StartTest();
    		DG_BatchDeleteProcessor BatchDeleteObject = new DG_BatchDeleteProcessor(listAccount);
			ID batchprocessid = Database.executeBatch(BatchDeleteObject);        
        Test.stopTest();
        
        AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors
                    FROM AsyncApexJob WHERE ID =: batchprocessid ];
        
        
        System.AssertNotEquals(aaj.Id, null);
    }
    
}