/** Trigger for BCR
 *
 * History
 * -------
 * 03/31/2020 	Jake Hinds        Created
*/
trigger ReferenceBusinessContinuityResponse on Reference_Business_Continuity_Response__c (before insert,after insert,before update,after update) {
    //Reference_Business_Continuity_Response__c[] bcrToUpdateCase = new Reference_Business_Continuity_Response__c(){};
    List<Reference_Business_Continuity_Response__c>bcrToUpdateCase = new List<Reference_Business_Continuity_Response__c>();
    for(Reference_Business_Continuity_Response__c bcr: Trigger.new) {
        if(Trigger.isUpdate){
        	Reference_Business_Continuity_Response__c oldBCR = Trigger.oldMap.get(bcr.Id);
            if(bcr.Status__c != oldBCR.status__c || oldBCR.Level_of_Risk__c != bcr.Level_of_Risk__c){
                bcrToUpdateCase.add(bcr);
            }
        }
    }
    
    if(!bcrToUpdateCase.isEmpty()){
        ReferenceBusinessContinuityMethods.updateCases(bcrToUpdateCase);
    }
    
}