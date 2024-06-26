/* 
   This trigger to handle any after insert or after update processing.
   
     If the Reference PAC record is created via the TaxNotice Site/process, then copy any Client_Field_Submission__c to the Reference PAC record.
   
  History
  -------
  10/12/2017 Frank Lurz   Created 

 */
trigger ReferencePACAfter on Reference_PAC__c (after insert) {

 if (Trigger.isAfter) {
    if(Trigger.isInsert){
        ReferencePACHelper.copyCFSattchmntstoRefPAC(Trigger.new);
    } //isInsert          
 } //isAfter 


} // ReferencePACAfter