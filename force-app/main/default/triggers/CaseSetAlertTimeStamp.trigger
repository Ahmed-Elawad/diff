/* 
 * If the owner of the case changes, see if anything needs to be done.
 *
 * History
 * -------
 * 06/30/2010 Dan Carmen   Created from setAlertTimeStamp trigger
 * 02/17/2011 Dan Carmen   Modifications to prevent exception from occurring.
 *
 */
trigger CaseSetAlertTimeStamp on Case (before insert, before update) {
   
   // the collection of Case Ids
   //Id[] caseIds = new Id[]{};
   Case[] cases = new Case[]{};
   // the collection of owner Ids. Use a Map so we don't get duplicates
   Map<Id,Id> ownerIds = new Map<Id,Id>();
   
   for ( Case newCase: Trigger.new) {
   	  if (newCase.IsClosed == false) {
   	     //caseIds.add(newCase.Id);
   	     cases.add(newCase);
   	     ownerIds.put(newCase.OwnerId,newCase.OwnerId);
   	  }
   } // for (Case

   if (!cases.isEmpty()) {
   	  CaseSetAlertTimeStamp.setAlerts(cases, ownerIds.values(), Trigger.isInsert);
   }   
} // trigger CaseSetAlertTimeStamp