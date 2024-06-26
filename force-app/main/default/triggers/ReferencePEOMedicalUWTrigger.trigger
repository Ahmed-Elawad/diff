/* Trigger for Reference PEO Medical UW Object
*
*   HISTORY
*  ---------
*   02/21/2018  Jacob Hinds     Created
*   08/07/2018  Jacob Hinds     Adding trigger criteria for INC1704937
*   11/05/2018  Jermaine Stukes Added method to calculate agency response in hours Case#30688906
    02/27/2020  Dan Carmen      Add in TriggerMethods call

*/

trigger ReferencePEOMedicalUWTrigger on Reference_PEO_Medical_UW__c (after insert, after update, before insert, before update) {
    
    TriggerMethods.checkBeforeLoop('ReferencePEOMedicalUWTrigger', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

    Reference_PEO_Medical_UW__c [] responseTargetSLA = new Reference_PEO_Medical_UW__c[]{};
    Reference_PEO_Medical_UW__c [] approvalTimeframeSLA = new Reference_PEO_Medical_UW__c[]{};
    Reference_PEO_Medical_UW__c [] responseTimeList = new Reference_PEO_Medical_UW__c[]{};

    if (Trigger.isBefore){
        if(Trigger.isInsert){
            ReferencePEOMedicalUWMethods.checkForExistingPEOUW(Trigger.new);
        }
        for (Reference_PEO_Medical_UW__c newPEOUW : Trigger.new){  
            Reference_PEO_Medical_UW__c oldPEOUW = (Trigger.isUpdate? Trigger.oldMap.get(newPEOUW.id):null);
            /*if(oldPEOUW == null && newPEOUW.Opportunity__c != null){
                ReferencePEOMedicalUWMethods.checkForExistingPEOUW(newPEOUW);
            }*/
            if((oldPEOUW == null && newPEOUW.Date_Submitted__c != null) || (oldPEOUW != null && newPEOUW.Date_Submitted__c != oldPEOUW.Date_Submitted__c)){
                responseTargetSLA.add(newPEOUW);                
            }
            if(newPEOUW.Approval_Date__c != null && newPEOUW.Deal_100_Complete__c!= null && newPEOUW.UW_SLA__c != null && 
            (oldPEOUW == null || 
            (oldPEOUW != null && ((newPEOUW.Approval_Date__c != oldPEOUW.Approval_Date__c) || (newPEOUW.Deal_100_Complete__c!= oldPEOUW.Deal_100_Complete__c) 
                || (newPEOUW.UW_SLA__c != oldPEOUW.UW_SLA__c))))){
                approvalTimeframeSLA.add(newPEOUW);             
            }
            if(newPEOUW.Date_Response_from_Agency__c != null && newPEOUW.Date_Submitted_to_Agency__c != null) {
                if(newPEOUW.Date_Response_from_Agency__c != oldPEOUW.Date_Response_from_Agency__c || newPEOUW.Date_Submitted_to_Agency__c != oldPEOUW.Date_Submitted_to_Agency__c)
                {responseTimeList.add(newPEOUW);  }              
            }
        }   
        
    }//end isBefore
    if(!responseTargetSLA.isEmpty()){
        ReferencePEOMedicalUWMethods.processResponseTargetSLA(responseTargetSLA);
    }
    if(!approvalTimeframeSLA.isEmpty()){
        ReferencePEOMedicalUWMethods.processApprovalTimeframeSLA(approvalTimeframeSLA);
    }
    if(!responseTimeList.isEmpty()){
        ReferencePEOMedicalUWMethods.agencyResponseHours(responseTimeList);
    }
}