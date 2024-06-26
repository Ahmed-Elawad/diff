/*********************************************************************************************************************************
 Name:  DG_BatchDeleteProcessor
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Batch delete processor for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	10/05/2018			Created     Created
*********************************************************************************************************************************/
 
global class DG_BatchDeleteProcessor implements Database.batchable<SObject> {
    SObject[] source;
    
    global DG_BatchDeleteProcessor(SObject[] source) {
        this.source = source;
    }

    global Iterable<SObject> start(Database.BatchableContext bc) {
        DG_BatchSObjectFeeder bf = new DG_BatchSObjectFeeder(source);
        return bf;
    }
    
    global void execute(Database.BatchableContext bc, SObject[] scope) {
        delete scope;
    	DataBase.emptyRecycleBin(scope);
    }
    
    global void finish(Database.BatchableContext bc) {
    
    }
}