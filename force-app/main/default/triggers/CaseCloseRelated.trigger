/* 
 * Close cases that are related to a parent case
 *
 * History
 * -------
   12/12/2012 Dan Carmen   Created
 *
 */
trigger CaseCloseRelated on Case (after update) {

   // get all of the record type ids that we will use to close related cases
   Set<String> closeRelatedRecordTypeIds = CaseCloseRelated.getRecordTypeIds();
   // look for cases that are now closed and have this particular record type id
   Id[] closeRelatedCaseIds = new Id[]{};
    
   for (Case c : Trigger.new) {
   	// get the old value
      Case oldC = (Case)Trigger.oldMap.get(c.id);
      // make sure is newly closed and there isn't a parent
      if (c.IsClosed && !oldC.isClosed
             && c.ParentId == null 
             && closeRelatedRecordTypeIds.contains(c.RecordTypeId)) {
         closeRelatedCaseIds.add(c.Id);
      } // if
   } // for (Case c
   
   if (!closeRelatedCaseIds.isEmpty()) {
      CaseCloseRelated.checkCloseRelated(closeRelatedCaseIds);
   } // if
   
} // trigger CaseCloseRelated