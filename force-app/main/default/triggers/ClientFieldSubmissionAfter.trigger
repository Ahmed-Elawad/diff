/*   Handle all of the "after" Client_Field_Submission__c operations.  
*
*  History 
*  -------
*  10/10/2017 Frank Lurz   created 
* 
*/

trigger ClientFieldSubmissionAfter on Client_Field_Submission__c (after update) {

  if (Trigger.isAfter){
     if (Trigger.isUpdate) {
     
         /* generate email to populate the Client_Field_Submission__c.Submission_Date__c field */
         map<Client_Field_Submission__c,id>   cfsMapId = new map<Client_Field_Submission__c,id>();

         For(Client_Field_Submission__c newRecord: trigger.newmap.values()){
             if((newRecord.Submission_Done__c)
                && (newRecord.Submission_Date__c == null)
                && (newRecord.Submission_Done__c != trigger.oldmap.get(newRecord.ID).Submission_Done__c) ) {
                cfsMapId.put(newRecord,trigger.newmap.get(newRecord.ID).id);
                system.debug('FRL in ClientFieldSubmissionAfter - checking for Submission_Done__c values -- ' +newRecord.Submission_Done__c);
             } //if
         } //For
         
         system.debug('* FRL * trigger.newmap.values - ' + trigger.newmap.values());
         system.debug('** FRL ** cfsMapId - ' + cfsMapId);
                  
         if(!cfsMapId.isEmpty()){
           ClientFieldSubmissionHelper.TaxNoticeEmail(cfsMapId);
         }          



         //checking if the Submission_Date__c value has been populated
         map<Client_Field_Submission__c,datetime>   cfsMapSD = new map<Client_Field_Submission__c,datetime>();

         For(Client_Field_Submission__c newRecord: trigger.newmap.values()){
             if((newRecord.Submission_Date__c != null) 
                && (newRecord.Submission_Date__c != trigger.oldmap.get(newRecord.ID).Submission_Date__c) 
                && (newRecord.CaseId__c == null )){
                cfsMapSD.put(newRecord,trigger.newmap.get(newRecord.ID).Submission_Date__c);
                system.debug('FRL - checking for null Submission_Date__c values...');
             }
             
         }
         
         system.debug('FRL ' + trigger.newmap.values());
         system.debug('FRL ' + trigger.oldmap.values());
         system.debug('FRL ' + cfsMapSD);
                  
         if(!cfsMapSD.isEmpty()){
           ClientFieldSubmissionHelper.processCFS(cfsMapSD);
         }

     }//if-isUpdate
 } //if-isAfter
        
} // ClientFieldSubmissionAfter