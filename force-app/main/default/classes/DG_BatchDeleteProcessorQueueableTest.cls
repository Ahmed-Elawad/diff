/*********************************************************************************************************************************
 Name:  DG_BatchDeleteProcessorTest
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Queueable delete processor for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			DemadnGen 		08/02/2019			Created     Created
*********************************************************************************************************************************/
@isTest 
public class DG_BatchDeleteProcessorQueueableTest {
	
    public static testMethod void testQueueable(){
        Map<Id,CAA_Record__c> ocaToDelete = new Map<Id,CAA_Record__c>();
        Test.startTest();
        	System.enqueueJob(new DG_BatchDeleteProcessorQueueable(ocaToDelete));
        Test.stopTest();
    }
}