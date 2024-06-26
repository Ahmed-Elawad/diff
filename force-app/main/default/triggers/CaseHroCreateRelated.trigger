/* 
 * Create related HRO cases
 *
 * History
 * -------
 * 06/29/2010 Dan Carmen   Created
 *
 */
trigger CaseHroCreateRelated on Case (after insert) {
   Id[] caseIds = new Id[]{};

   // do not send in if parent id is null and there is not an account.
   for ( Case newCase: Trigger.new) {
   	  System.debug('IN TRIGGER parentId='+newCase.ParentId+' AccountId='+newCase.AccountId);
   	  if ((newCase.ParentId == null) && (newCase.AccountId != null)) {
         caseIds.add(newCase.Id);
   	  }
   } // for (Case
   
   if (!caseIds.isEmpty()) {
      CaseHROUtilities.insertChildCases(caseIds);
   }
} // trigger CaseHroCreateRelated