/* 
 *   
 * History
 * -------
 * 08/21/2017 Cindy Freeman     created
 * 05/04/2018 Cindy Freeman     commented out all code and moved it to process builder
 *
 */


trigger ClientReferencesSelectedAfter on Client_References_Selected__c (after insert, after update) {
   /*
    for (Client_References_Selected__c clientRefSel : Trigger.new){ 
         if (Trigger.isUpdate) {
            Client_References_Selected__c oldclientRefSel = (Client_References_Selected__c)Trigger.oldMap.get(clientRefSel.id);
            System.debug('**CMF ** ClientReferencesSelectedAfter, calling TriggerMethods.checkInLoop');          
            TriggerMethods.checkInLoop('ClientReferencesSelectedAfter', clientRefSel, oldclientRefSel, Trigger.isBefore, Trigger.isAfter);        
         } // if
        
    } // for
    
    TriggerMethods.checkOutsideLoop('ClientReferencesSelectedAfter',Trigger.isBefore, Trigger.isAfter);
   */ 
}