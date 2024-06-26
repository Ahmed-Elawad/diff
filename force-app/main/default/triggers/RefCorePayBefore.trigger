/** Before Trigger for Reference Core Payroll object
 *
 * History
 * -------
 *  08/17/2016 Jacob Hinds      Created
 *  12/16/2016 Jacob Hinds      Adding MPSC Exception
 *  02/15/2023 Susmitha Somavarapu  Adding CallerName field logic handling for RCP
 *  03/27/2023 Eric Porter      Adding IS_Completed_open_Client_Audit_Items__c handling for RCP
 *  03/25/2024 Carrie Marciano	commenting out code to remove old MPSC tech debt
 *  04/15/2024 Susmitha Somavarapu Commenting out code to remove refCorVSCase because it is overwritting the Caller_Name_c code in FFSservice class.
 */
trigger RefCorePayBefore on Reference_Core_Payroll__c (before insert, before update) {
   Reference_Core_Payroll__c[] fiscalWeek = new Reference_Core_Payroll__c[]{};
   //Reference_Core_Payroll__c[] exceptionCaseCreation = new Reference_Core_Payroll__c[]{};
    Map<id, String> refCorVSCase = new map<id,String>();
    List<Reference_Core_Payroll__c> refCoreListForCallerUpdate = new List<Reference_Core_Payroll__c>();
    List<Reference_Core_Payroll__c> refCoreListForIsAuditUpdate = new List<Reference_Core_Payroll__c>();
   if (Trigger.isInsert){
        for ( Reference_Core_Payroll__c newRcp: Trigger.new) {
            if(newRcp.Payroll_Run_Date__c != null){
                fiscalWeek.add(newRcp);
            }
            /*
            Id exceptionId = RecordTypeHelper.getRecordType('MPSC Exception','Reference_Core_Payroll__c').getRecordTypeId();
            if(exceptionId != null && newRcp.RecordTypeId == exceptionId){
                exceptionCaseCreation.add(newRcp);
            }
            */
            // if (newRcp.Caller_Name__c != '') {
            //     refCorVSCase.put(newRcp.id, newRcp.Caller_Name__c);
            //     refCoreListForCallerUpdate.add(newRCp); 
            // } 
        }
   }
   else{
        for ( Reference_Core_Payroll__c newRcp: Trigger.new) {
            Reference_Core_Payroll__c oldRcp = (Reference_Core_Payroll__c)Trigger.oldMap.get(newRcp.Id);
            // Payroll run date populated
            if (newRcp.Payroll_Run_Date__c != null && (oldRcp.Payroll_Run_Date__c != newRcp.Payroll_Run_Date__c)) {
               fiscalWeek.add(newRcp);
            } // if
            // if (newRcp.Caller_Name__c != trigger.oldMap.get(newRcp.id).Caller_Name__c) {
            //     refCorVSCase.put(newRcp.id, newRcp.Caller_Name__c);
            //     refCoreListForCallerUpdate.add(newRCp); 

            // }
            if(newRcp.IS_Completed_open_Client_Audit_Items__c != null && (newRcp.IS_Completed_open_Client_Audit_Items__c != oldRcp.IS_Completed_open_Client_Audit_Items__c )){
                if(newRcp.IS_Completed_open_Client_Audit_Items__c == 'Yes'){
                    refCoreListForIsAuditUpdate.add(newRcp);
                }
            }
        }
   }
   if(!fiscalWeek.isEmpty()){
      RefCorePayFiscalWeek.calculateFiscalWeek(fiscalWeek);
   }
   /*
   if(!exceptionCaseCreation.isEmpty()){
      RefCorePayExceptionCase.createCase(exceptionCaseCreation);
   }
   */
//    if (!.isEmpty()) {
//     RefCorePayUpdateOppty.updateCallerName(refCorVSCase, refCoreListForCallerUpdate);

//    }
   if(!refCoreListForIsAuditUpdate.isEmpty()){
    RefCorePayUpdateOppty.updateiSCompletedClientAuditItems(refCoreListForIsAuditUpdate);
   }
}