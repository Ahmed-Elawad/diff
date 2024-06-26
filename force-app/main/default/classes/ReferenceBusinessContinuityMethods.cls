/* 
   Methods for Reference Business Continuity Response
   
  History
  -------
  03/31/2020 Jake Hinds         Created
 */
public without sharing class ReferenceBusinessContinuityMethods {
    public static void updateCases(Reference_Business_Continuity_Response__c[] bcrs){
        Id[] caseIds = new Id[]{};
        Case[] casesToUpdate = new Case[]{};
        for(Reference_Business_Continuity_Response__c bcr: bcrs){
            if(String.isNotBlank(bcr.Case_Lookup__c)){
                caseIds.add(bcr.Case_Lookup__c);
            }
        }
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,Status,Priority FROM Case WHERE Id in:caseIds]);
        system.debug('ReferenceBusinessContinuityMethods updateCases caseMap:'+caseMap);
        if(caseMap!=null && !caseMap.isEmpty()){
            for(Reference_Business_Continuity_Response__c bcr: bcrs){
                if(caseMap.containsKey(bcr.Case_Lookup__c)){
                	Case c = caseMap.get(bcr.Case_Lookup__c);
                    String newStatus='';
                    String newPriority='';
                    Boolean caseUpdated = false;
                    if(bcr.Status__c == 'New'){
                        newStatus = 'New';
                    }
                    if(bcr.Status__c == 'In Progress' || bcr.Status__c.startsWith('Follow Up')){
                        newStatus = 'In Progress';
                    }
                    else if(bcr.Status__c == 'Client Non-Responsive'){
                        newStatus = 'Cancelled';
                    }
                    else if(bcr.Status__c == 'Complete'){
                        newStatus = 'Complete';
                    }
                    system.debug('ReferenceBusinessContinuityMethods updateCases newStatus:'+newStatus);
                    if(String.isNotBlank(newStatus) && newStatus != c.Status){
                        c.Status = newStatus;
                        caseUpdated = true;
                    }
                    if(bcr.Level_of_Risk__c!=null && String.isNotBlank(bcr.Level_of_Risk__c) && (bcr.Level_of_Risk__c.startsWith('1') || bcr.Level_of_Risk__c.startsWith('2'))){
                        newPriority = 'Low';
                    }
                    else if(bcr.Level_of_Risk__c!=null && String.isNotBlank(bcr.Level_of_Risk__c) && bcr.Level_of_Risk__c.startsWith('3')){
                        newPriority = 'Medium';
                    }
                    else if(bcr.Level_of_Risk__c!=null && String.isNotBlank(bcr.Level_of_Risk__c) && bcr.Level_of_Risk__c.startsWith('4')){
                        newPriority = 'High';
                    }
                    else if(bcr.Level_of_Risk__c!=null && String.isNotBlank(bcr.Level_of_Risk__c) && bcr.Level_of_Risk__c.startsWith('5')){
                        newPriority = 'Critical';
                    }
                    if(String.isNotBlank(newPriority) && newPriority != c.Priority){
                        c.Priority = newPriority;
                        caseUpdated = true;
                    }
                    if(caseUpdated){
                        casesToUpdate.add(c);
                    }
                }
        	}
        }
        
        if(!casesToUpdate.isEmpty()){
            DMLHelper.performDML2(casesToUpdate, DMLHelper.DML_UPDATE, 'ReferenceBusinessContinuityMethods', 'updateCases', 'updating cases', true);
        }
        
    }
}