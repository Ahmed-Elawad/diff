/* 
 * Created to keep child case statuses and owners in sync with parent for HRS Termination/Transfers
 *
 * History
 * -------
 * 09/29/2017 Lynn Michels        Created
 * 11/21/2017 Lynn Michels		  Added check to make sure Client Ids to be coded lost is not blank when owner changes
 *
 */
 
 public with sharing class CasesInSync {
    
    public static void casesInSync (List<Id> termTransferCaseIds){
        Id caseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
        List<Case> casesToUpdate = new List<Case>();
        //query for cases where the id of the cases passed in, is the parentId of another Case
        //only want HRS Termination Transfer Case Record Type cases to narrow the search    
        List<Case> childCases = [SELECT Id, Parent.Status, parent.OwnerId, RecordTypeId FROM Case
                                WHERE ParentId IN: termTransferCaseIds AND RecordTypeId =: caseTermTransfer];
        
                        
                                
                               
    if(!childCases.isEmpty()){
        for(Case child : childCases){
        	
            	Case c = new Case (Id = child.Id,
                            Status = child.Parent.Status,
                            OwnerId = child.Parent.OwnerId);
            casesToUpdate.add(c);
            
        }//for child
        
    }
        
        try{
            update casesToUpdate;
        }catch (Exception e){
            System.debug('No records were updated: ' + e.getMessage());
        }
    }//syncStatuses
    
    //Do not let the owner change if the Client IDs to be coded lost field on the reference record is blank
    public static void checkField (Map<Id, Case> caseOwnerMap){

 		Id termTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId();
 		
        //query the reference record that is related to the case                        
        list<Reference_HRS_Termination_Transfer__c> recordsToCheck = new list<Reference_HRS_Termination_Transfer__c>();
        recordsToCheck = [SELECT Id, Case_Lookup__c, Client_IDs_to_be_Coded_Lost__c FROM Reference_HRS_Termination_Transfer__c
                                WHERE Case_Lookup__c IN: caseOwnerMap.keyset()];

        for(Reference_HRS_Termination_Transfer__c ref : recordsToCheck){
        	Case cs = caseOwnerMap.get(ref.Case_Lookup__c);
        	if (cs != null) {
        		if (String.isBlank(ref.Client_IDs_to_be_Coded_Lost__c)) { 		
        		    cs.OwnerId.addError('You must use the "Select Clients" button on the Reference HRS Termination/Transfer record to populate the "Client IDs to be Coded Lost" field before you can change the owner.');
        		}   //end if
        	}//end if cs != null
        }//end for
        
    }//end checkField

}//CasesInSync