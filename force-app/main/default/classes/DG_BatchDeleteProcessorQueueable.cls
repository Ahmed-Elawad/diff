/*********************************************************************************************************************************
 Name:  DG_BatchDeleteProcessor
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Queueable delete processor for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			DemadnGen 		08/02/2019			Created     Created
*********************************************************************************************************************************/
 
public class DG_BatchDeleteProcessorQueueable implements Queueable {
    Map<Id,CAA_Record__c> ocaToDelete;
    public DG_BatchDeleteProcessorQueueable (Map<Id,CAA_Record__c> ocaToDelete) {
    	this.ocaToDelete = ocaToDelete;
    }
    
    public void execute(QueueableContext context) {
        DG_BatchDeleteProcessor BatchDeleteObject = new DG_BatchDeleteProcessor(ocaToDelete.values());
        Database.executeBatch(BatchDeleteObject);     
    }
    
}