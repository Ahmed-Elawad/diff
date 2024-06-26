/*  Update the Reference Handbook Order. 
*
*  History 
*  -------
*  09/18/2013 Justin Stouffer   created 
*  02/12/2015 Frank Lurz        added the updateRefHbkVersionAC method to handle Approval Copy changes
*  07/07/2015 Frank Lurz        updated the updateRefOrderLookup method to assign the owner of new Orders
*
*/

public with sharing class ReferenceHbkOrderHelper {
        /** Update the Reference Handbook Version object when the related Reference Handbook Order.Order Current Step is modified    */
        public static void updateRefHbkVersionCS(Map<Reference_HRE_CHB_Orders__c,string> refOrdersMapCS) {
            boolean okToUpdateCS = FALSE;
            set<id> refHbkVersionsIDSet = new set<id>();
            for(Reference_HRE_CHB_Orders__c refOrder : refOrdersMapCS.keySet()){
                refHbkVersionsIDSet.add(refOrder.Handbook_Version__c);      
            }
            map<Id,Reference_Handbooks_Version__c> refVersionMap = new map<Id,Reference_Handbooks_Version__c>([Select id, 
                                                                            Order_Current_Steps_Indicator__c 
                                                                            from Reference_Handbooks_Version__c
                                                                            where id in :refHbkVersionsIDSet]);
                                                                            
            for(Reference_HRE_CHB_Orders__c refOrder : refOrdersMapCS.keySet()){
                if(refOrdersMapCS.get(refOrder) == 'New'){
                    if(refOrder.Order_Current_Step__c != 'Complete' && refOrder.Order_Current_Step__c != 'Order Voided' && refOrder.Order_Current_Step__c != 'Client Canceled'){
                        if(refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c != NULL){
                            refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c++;
                            system.debug('FRL - Order_Current_Steps_Indicator__c AFTER ++ ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c );
                            }
                        else{
                            refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c = 1;
                            system.debug('FRL - Order_Current_Steps_Indicator__c AFTER = 1, AFTER ++ ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c );
                        }
                        okToUpdateCS = TRUE;  
                    }
                }//if New
                else if(refOrder.Order_Current_Step__c == 'Complete' || refOrder.Order_Current_Step__c == 'Order Voided' || refOrder.Order_Current_Step__c == 'Client Canceled'){
                    if(refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c != NULL){
                       if(refOrder.Order_Current_Step__c == 'Client Canceled'){
                           refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c-=2;
                           system.debug('FRL - Order_Current_Steps_Indicator__c AFTER - by 2 ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c );
                       }
                       else {
                            refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c--;
                            system.debug('FRL - Order_Current_Steps_Indicator__c AFTER -- ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c );
                       }
                    }//NOT NULL
                    else{
                        refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c = -1;
                        system.debug('FRL - Order_Current_Steps_Indicator__c AFTER = 1, AFTER -- ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Current_Steps_Indicator__c );
                    }   
                    okToUpdateCS = TRUE;  
                }// Complete OR Void OR Cancel
            }// for refOrder
            
            if(okToUpdateCS){
                update refVersionMap.values();
                system.debug('FRL - AFTER update refVersionMap ***  CS *** ' );
            }               
        } //end  updateRefHbkVersionCS method
        
        
        /** Update the Reference Handbook Version object when the related Reference Handbook Order.Approval Copy to Client Date is populated    */
        public static void updateRefHbkVersionAC(Map<Reference_HRE_CHB_Orders__c,date> refOrdersMapAC) {
            boolean okToUpdateAC = FALSE;
            set<id> refHbkVersionsIDSet = new set<id>();
            for(Reference_HRE_CHB_Orders__c refOrder : refOrdersMapAC.keySet()){
                refHbkVersionsIDSet.add(refOrder.Handbook_Version__c);      
            }
            map<Id,Reference_Handbooks_Version__c> refVersionMap = new map<Id,Reference_Handbooks_Version__c>([Select id, 
                                                                            Order_Approval_Copy_Indicator__c 
                                                                            from Reference_Handbooks_Version__c
                                                                            where id in :refHbkVersionsIDSet]);

            for(Reference_HRE_CHB_Orders__c refOrder : refOrdersMapAC.keySet()){
              system.debug('FRL - in the beginning of the for loop for the updateRefHbkVersionAC method  ---  ' );
                if(refOrdersMapAC.get(refOrder) != null){
              system.debug('FRL - in the beginning of the first IF statement in the for loop for the updateRefHbkVersionAC method  ---  ' );  
                    if(refOrder.Approval_Copy_to_Client_Date__c != NULL){
              system.debug('FRL - in the beginning of the second IF statement in the for loop for the updateRefHbkVersionAC method  ---  ' );        
                        if(refVersionMap.get(refOrder.Handbook_Version__c).Order_Approval_Copy_Indicator__c > 0){
                            refVersionMap.get(refOrder.Handbook_Version__c).Order_Approval_Copy_Indicator__c++;
                            system.debug('FRL - Order_Approval_Copy_Indicator__c AFTER ++ ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Approval_Copy_Indicator__c );
                            }
                        else{
                            refVersionMap.get(refOrder.Handbook_Version__c).Order_Approval_Copy_Indicator__c = 1;
                            system.debug('FRL - Order_Approval_Copy_Indicator__c AFTER = 1, AFTER ++ ' + refVersionMap.get(refOrder.Handbook_Version__c).Order_Approval_Copy_Indicator__c );
                        }
                        okToUpdateAC = TRUE;  
                    }
                 }
                 else {
                 system.debug('FRL - is the refOrdersMapAC.get(refOrder) = NULL???  ' + refOrdersMapAC.get(refOrder) );
                 }
             }//end for
                                                                            
            if(okToUpdateAC){
                update refVersionMap.values();
                system.debug('FRL - AFTER update refVersionMap ***  AC *** ' );
            }               
        } //end  updateRefHbkVersionAC method
        
        
        
        
        
        
        public static void updateRefOrderLookup(List<Reference_HRE_CHB_Orders__c> refOrderList) {
            set<id> refHbkVersionsIDSet = new set<id>();
            for(Reference_HRE_CHB_Orders__c refOrder : refOrderList){
                refHbkVersionsIDSet.add(refOrder.Handbook_Version__c);      
            }
            map<Id,Reference_Handbooks_Version__c> refVersionMap = new map<Id,Reference_Handbooks_Version__c>([Select id, 
                                                                            reference_HR_Essentials__c,
                                                                            reference_HR_Essentials__r.ownerid
                                                                            from Reference_Handbooks_Version__c
                                                                            where id in :refHbkVersionsIDSet]);
            for(Reference_HRE_CHB_Orders__c refOrder : refOrderList){
                if(refOrder.Handbook_Version__c != NULL){
                    refOrder.reference_HR_Essentials__c = refVersionMap.get(refOrder.Handbook_Version__c).reference_HR_Essentials__c;
                    refOrder.Ownerid = refVersionMap.get(refOrder.Handbook_Version__c).reference_HR_Essentials__r.ownerid;
                    system.debug('FRL - AFTER update of refOrder.reference_HR_Essentials__c ' + refOrder.reference_HR_Essentials__c );
                }
            }
        } //end updateRefOrderLookup method
}