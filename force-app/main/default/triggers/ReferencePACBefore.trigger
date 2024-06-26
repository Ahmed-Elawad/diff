/* 
   This trigger to handle any before insert or before update processing.
   
     If the Reference PAC record is created via the TaxNotice Site/process, then populate the record using Client_Field_Submission__c values.
     Otherwise set Status__c and Date_1st_Notice_Received_in_PAC__c. 
   
  History
  -------
  10/12/2017 Frank Lurz   Created 

 */
trigger ReferencePACBefore on Reference_PAC__c (before insert) {

 if (Trigger.isBefore) {
    if(Trigger.isInsert){
        ReferencePACHelper.updateRefPACviaCFS(Trigger.new); 
    } //isInsert          
 } //isBefore  


} // ReferencePACBefore