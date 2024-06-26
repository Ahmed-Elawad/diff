/* 
 *  A trigger to handle after delete operations due to Merging of Accounts
 *  And handle after UNdelete operations. Probably won't happen very often.
 *  And handle before delete operations (gather contacts before accounts are merged) 
 *   
 * History
 * -------
 * 04/21/2014 Cindy Freeman     created
   01/13/2017 Dan Carmen        Check if we want to prevent the delete of a recod
 * 01/25/2017 Josh Cartwright   changes for Dataflux 
 * 03/22/2017 Cindy Freeman     add check for AccountJunction
   01/08/2020 Dan Carmen        Increment API version, Move AccountJunction logic to Interface class
   01/30/2020 Dan Carmen        Added call to TriggerMethods
   03/17/2024 Dan Carmen        Move Dataflux logic to DataFluxDeltaService

 */

trigger AccountDelete on Account (after delete, after undelete, before delete) {

    if (Trigger.isDelete) {
       TriggerMethods.checkBeforeLoop('AccountDelete', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
    }
    if (Trigger.isUnDelete) {
       new DataFluxDeltaService().handleUndelete(ObjectHelper.OBJECT_ACCOUNT, Trigger.newMap);
    } // if (Trigger.isUnDelete)
    
    if (Trigger.isBefore && Trigger.isDelete) {
      // find children accounts to delete junctions
      AccountJunctionMethods.checkAccountsBefore(Trigger.new, Trigger.oldMap, Trigger.isDelete);
      
      // accounts that need to be sent to DataFlux because they were deleted
      AccountDeleteCheck.checkForDelete(Trigger.old);
      new AccountPartnerSync().checkDeleteBefore(Trigger.Old, Trigger.oldMap);
    } // if (Trigger.isBefore)  
    
} // trigger AccountDelete