/* 
 * Create a related case on a case.
 *
 * History
 * -------
 * 07/11/2017 Lynn Michels	Create only one related case on 'Service Onboarding MPSC Core Payroll Case' Case
 * 03/25/2024 Carrie Marciano	CanBeDeleted old MPSC tech debt
 */
 //ensure that only one MPSC Transfer Case case is created on a 'Service Onboarding MPSC Core Payroll Case' Case
public without sharing class CreateRelatedCase {
    public CreateRelatedCase(){}
    
/*	
	public static void checkForAlreadyExistingCases(Map<Id, Case> IdMPSCOnboardingCaseMap){
		//onboarding case ids come in if there current step is step 6 of 7
		//query MPSC Transfer Cases to see if the caseIds exist as parentIds on any of them
		
		Id caseMPSCTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('MPSC Transfer Case').getRecordTypeId();	
		List<Case> mpscTransferCases = [SELECT ParentID, RecordTypeId
										FROM Case
										WHERE ParentId in :IdMPSCOnboardingCaseMap.keyset() AND RecordTypeId =: caseMPSCTransfer];
										
		//loop through the MPSC Transfer Cases and remove the ids that exist as ParentIds 
		for (Case c: mpscTransferCases){
			IdMPSCOnboardingCaseMap.keyset().remove(c.ParentId);
		}
	
		//if all ids have MPSC Transfer Cases, all ids will be removed and no new cases need to be created.
		if (IdMPSCOnboardingCaseMap.keyset().isEmpty()) {
			return;
		}
		
	    List<Case> casesToCreate = new List<Case>();
	    //use new list to query details for the new case
	  
		for(Case newCase: IdMPSCOnboardingCaseMap.values()){
			// create a Case object
			Case thisCase = new Case(ContactId = newCase.ContactId
				                    ,AccountId = newCase.AccountId
				                    ,Subject = 'MPSC TransferCase'
				                    ,OwnerId = newCase.OwnerId
				                    ,Status = 'New'
				                    ,ParentId = newCase.Id
				                    ,RecordTypeId = caseMPSCTransfer);  
			casesToCreate.add(thisCase);
		}//end mpscOnboardingCases
   	 	if (!casesToCreate.isEmpty()) {
         	insert casesToCreate;
   		}
   	 }//end checkForAlreadyExistingCases
*/	 
}