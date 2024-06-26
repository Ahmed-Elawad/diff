/* 
 *   
 * History
 * -------
 * 09/14/2017 Cindy Freeman		created
 *
 */

trigger ClientReferencesSelectedBefore on Client_References_Selected__c (before insert, before update) {
	for (Client_References_Selected__c clientRefSel : Trigger.new){ 
    	 if (Trigger.isUpdate) {
    	 	Client_References_Selected__c oldclientRefSel = (Client_References_Selected__c)Trigger.oldMap.get(clientRefSel.id);
    	 	System.debug('**CMF ** ClientReferencesSelectedBefore, calling TriggerMethods.checkInLoop');          
        	TriggerMethods.checkInLoop('ClientReferencesSelectedBefore', clientRefSel, oldclientRefSel, Trigger.isBefore, Trigger.isAfter);        
    	 } // if
    	
    } // for
    
    TriggerMethods.checkOutsideLoop('ClientReferencesSelectedBefore',Trigger.isBefore, Trigger.isAfter);
}