/*   Handle all of the "after" Reference_HRE_CHB_Orders__c operations.
*
*  History 
*  -------
*  09/18/2013 Frank Lurz       created 
*  02/12/2015 Frank Lurz       added the updateRefHbkVersionAC method to handle Approval Copy changes
* 
*/

trigger ReferenceHandbookOrdersTrigger on Reference_HRE_CHB_Orders__c (before insert, after update) {
  
 if (Trigger.isBefore) {
    if(Trigger.isInsert){
        ReferenceHbkOrderHelper.updateRefOrderLookup(Trigger.new); 
    } //isInsert          
 } //isBefore  
 else if (Trigger.isAfter){
     if (Trigger.isUpdate) {
         //get the newRecord.Order_Current_Step__c picklist value and pass to the class in order to alter the Reference_Handbooks_Version__c.Order Current Steps Indicator
         map<Reference_HRE_CHB_Orders__c,string> refOrdersMapCS = new map<Reference_HRE_CHB_Orders__c,string>();
         map<Reference_HRE_CHB_Orders__c,date>   refOrdersMapAC = new map<Reference_HRE_CHB_Orders__c,date>();

         For(Reference_HRE_CHB_Orders__c newRecord: trigger.newmap.values()){
             if((newRecord.Order_Current_Step__c != null) 
                && (newRecord.Order_Current_Step__c != trigger.oldmap.get(newRecord.ID).Order_Current_Step__c) 
                && (newRecord.Historical_Order_Indicator__c == 0 )){
                refOrdersMapCS.put(newRecord,trigger.oldmap.get(newRecord.ID).Order_Current_Step__c);
                system.debug('FRL - checking for non-null Order_Current_Step__c values... ');
             }
             
             if((newRecord.Approval_Copy_to_Client_Date__c != null) 
                && (newRecord.Approval_Copy_to_Client_Date__c != trigger.oldmap.get(newRecord.ID).Approval_Copy_to_Client_Date__c) 
                && (newRecord.Historical_Order_Indicator__c == 0 )){
                refOrdersMapAC.put(newRecord,trigger.newmap.get(newRecord.ID).Approval_Copy_to_Client_Date__c);
                system.debug('FRL - checking for non-null Approval_Copy_to_Client_Date__c values...');
             }
             
         }
                  
         system.debug('JSG ' + trigger.newmap.values());
         system.debug('JSG ' + trigger.oldmap.values());
         system.debug('JSG ' + refOrdersMapCS);
         system.debug('JSG ' + refOrdersMapAC);

         if(!refOrdersMapCS.isEmpty()){
            ReferenceHbkOrderHelper.updateRefHbkVersionCS(refOrdersMapCS);
         }
         
         if(!refOrdersMapAC.isEmpty()){
            ReferenceHbkOrderHelper.updateRefHbkVersionAC(refOrdersMapAC);
         }

     }    
 } //else-if    
        
} // ReferenceHandbookOrdersTrigger