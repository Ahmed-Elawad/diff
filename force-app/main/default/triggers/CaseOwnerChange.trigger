/* 
 * If the owner of the case changes, see if anything needs to be done.
 *
 * History
 * -------
 * 06/29/2010 Dan Carmen   Created
 * 09/28/2010 Dan Carmen   Updating version
   09/20/2011 Dan Carmen   Added PEO
   08/29/2013 Cindy Freeman	 Added code to look for MMS onboarding case changing owner from user to queue
   11/04/2015 Lynn Michels 	comment out code for MMS Payroll to prevent owner change from Queue to User.
   11/25/2016 Lynn Michels	if the Case is Service Onboarding MPSC Core Payroll Case RT and the owner changed, update Reference MPSC Payroll IS field
 *
 */
trigger CaseOwnerChange on Case (after update) {
   Id[] caseIds = new Id[]{};
   //holds the MPSC Cases to populate changes on Reference MPSC
   //case id, owner id map
   Map<Id,Id> CaseIdOwnerMap = new Map<Id, Id>();
  // Schema.RecordTypeInfo caseMMSrt = RecordTypeHelper.getRecordType('Service Onboarding MMS Payroll Case', 'Case');  
  Id caseOnbMPSC = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Service Onboarding MPSC Core Payroll Case').getRecordTypeId();
   
   UserHelper uh = new UserHelper();
   
   for ( Case newCase: Trigger.new) {
      // get the old record
       Case oldCase = (Case)Trigger.oldMap.get(newCase.Id);
      
		/*if (newCase.RecordTypeId == caseMMSrt.getRecordTypeId()) {
          User oldOwner = uh.getUserById(oldCase.OwnerId);                   
          Group newOwner = uh.getQueueById(newCase.OwnerId);
          if (oldOwner != null && newOwner != null)
          {  caseIds.add(newCase.Id);  }
      }
      else {*/
      
      if (oldCase.OwnerId != newCase.OwnerId) {
		caseIds.add(newCase.Id);
     	//LM - If Case is MPSC Onboarding Record type and the owner has changed. Used to populate Payroll IS field on Reference MPSC.
			if (newCase.RecordTypeId == caseOnbMPSC){
     			CaseIdOwnerMap.put(newCase.Id, NewCase.OwnerId);
     		}//end if RT == caseOnbMPSC
        }//end if owner change
   } // for (Case
   
   if (!caseIds.isEmpty()) {
   	  CaseOwnerChange.processOwnerChange(caseIds);
   } // if (!caseIds
   
   //LM - see if this case is a parent case and update Payroll IS on Reference MPSC
    if(!CaseIdOwnerMap.isEmpty()){
  		ReferenceMPSC.updatePayrollIS(CaseIdOwnerMap);
   }
   
} // trigger CaseOwnerChange