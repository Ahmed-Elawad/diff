/*********************************************************************************************************************************
 Name:  DG_BatchInsertProcessor
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Batch insert processor for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	10/05/2018			Created     Created
*********************************************************************************************************************************/
 

global class DG_BatchInsertProcessor implements Database.batchable<SObject> {
    SObject[] source;
    public String email;
        
    global DG_BatchInsertProcessor(SObject[] source) {
        this.source = source;
    }

    global Iterable<SObject> start(Database.BatchableContext bc) {
        DG_BatchSObjectFeeder bf = new DG_BatchSObjectFeeder(source);
        return bf;
    }
    
    global void execute(Database.BatchableContext bc, SObject[] scope) {
        insert scope;
    }
    
    global void finish(Database.BatchableContext bc) {
    	try{
    		if(email <> Null){
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				
				mail.setToAddresses(new String[] {email});
				mail.setReplyTo(email);
				mail.setSenderDisplayName('Batch Processing');
				mail.setSubject('Batch Insert Process Completed');
				mail.setPlainTextBody('Batch Insert Process has completed');
				
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    		}
    	}catch(exception e){}
    }
}