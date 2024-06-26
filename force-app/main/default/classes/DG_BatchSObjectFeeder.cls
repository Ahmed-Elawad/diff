/*********************************************************************************************************************************
 Name:  DG_BatchSObjectFeeder
 Created by DemadnGen Inc. 
==================================================================================================================================
Purpose: Batch object feeder for DemandGen solutions (Campaign Attribution Analyzer)
==================================================================================================================================
History
-------
VERSION		AUTHOR			DATE(dd/mm/yyyy)	DETAIL		Description
1.0			Rick Segura 	10/05/2018			Created     Created
*********************************************************************************************************************************/


global class DG_BatchSObjectFeeder implements Iterator<SObject>, Iterable<SObject> {
    SObject[] source;
    
    global Iterator<SObject> iterator() {
        return this;
    }
    
    global DG_BatchSObjectFeeder(SObject[] source) {
        this.source = source;
    }
    
    global SObject next() {
        return source.remove(0);
    }
    
    global boolean hasNext() {
        return source!=null && !source.isempty();
    }
}