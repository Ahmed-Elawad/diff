/* 
 *  A trigger to handle after Delete and Undelete operations.
 * 
 * History
 * -------
 * 04/21/2014 Cindy Freeman     created
 * 01/25/2017 Josh Cartwright changes for Dataflux 
   01/30/2020 Dan Carmen        Added call to TriggerMethods
   03/17/2024 Dan Carmen        Move dataflux logic to DataFluxDeltaService

 */

trigger ContactDelete on Contact (before delete, after delete, after undelete) {
    // contacts that need to be sent to DataFlux because they were deleted 
    //List<Id> datafluxCtctList = new List<Id>();
    // contacts that need to be sent to DataFlux because they were UNdeleted 
    //List<Id> datafluxCtctUndeleteList = new List<Id>();
    //List<Contact> ctctToDelete = new List<Contact>(); 
   
    if (Trigger.isDelete) {
       TriggerMethods.checkBeforeLoop('ContactDelete', Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter);
    } //if (Trigger.isDelete
    
    if (Trigger.isUnDelete) {
       new DataFluxDeltaService().handleUndelete(ObjectHelper.OBJECT_CONTACT,Trigger.newMap);
    } // if (Trigger.isUnDelete
    /*
    // send deletes to dataflux delta service unless TriggerFlag says no
    if (!datafluxCtctList.isEmpty() && Utilities.runTrigger('ContactDelete', UserInfo.getName(), DataFluxDeltaService.SERVICE_NAME)) 
    {   DataFluxDeltaService.processDataFlux(DataFluxDeltaService.ACTION_DELETE, datafluxCtctList,ctctToDelete );   }
    
    // send UNdeletes to dataflux delta service unless TriggerFlag says no
    if (!datafluxCtctUndeleteList.isEmpty() && Utilities.runTrigger('ContactDelete', UserInfo.getName(), DataFluxDeltaService.SERVICE_NAME)) 
    {   DataFluxDeltaService.processDataFlux(DataFluxDeltaService.ACTION_MODIFY, datafluxCtctUndeleteList); }
     */
} // trigger ContactDelete