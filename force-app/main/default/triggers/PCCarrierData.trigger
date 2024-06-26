/* 
* ------------------------------------------------------------------------------
* Trigger for P&C Carrier Data Object. 
* -------------------------------------------------------------------------------   
* History
* -------
* 12/18/2023    Vinay   Created
*
* -------------------------------------------------------------------------------    
* */
trigger PCCarrierData on P_C_Carrier_Data__c (before insert, after insert, before update, after update) {
    new PCCarrierDataMethods().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isDelete);
}