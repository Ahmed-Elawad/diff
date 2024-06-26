/* **********************************************************************************************************************************
 * History
 * -------
 * 01/16/2024 Pratik Das       Created (APR0162760: To add distinct employee location state to acord data )
 * 
 * 
 ************************************************************************************************************************************/
trigger EmployeeLocation on Employee_Location__c (before insert,after insert,before update,after update,after delete) {
    //System.debug('EmployeeLocation.SKIP_TRIGGER='+EmployeeLocationMethodsHandler.SKIP_TRIGGER);
    //if(EmployeeLocationMethodsHandler.SKIP_TRIGGER){
        //return;
    //}
    system.debug('MA1--Calling EmployeeLocationMethods');
    new EmployeeLocationMethodsHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
    
}