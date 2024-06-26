/*********************************************************************************************************************************
 Name:  DG_BatchSObjectFeeder_TEST
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Test class Batch object feeder for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	04/07/2018			Created     Created
*********************************************************************************************************************************/
@isTest
public with sharing class DG_BatchSObjectFeeder_Test {
	
    static testMethod void DG_BatchSObjectFeeder_Test(){
    	list<Account> listAccount = new list<Account>();
    	
    	Account a = new Account(
        type = 'Prospect',
        name = 'Test Account AAA');
        
        listAccount.add(a);
        insert listAccount;
        
        Test.StartTest();
    		DG_BatchSObjectFeeder bf = new DG_BatchSObjectFeeder(listAccount);      
        Test.stopTest();
        
        System.AssertNotEquals(bf, null);
    }
}