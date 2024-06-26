/*    Update the .
         History
         -------
         09/16/2014 Frank Lurz   Created
        07/06/2020  Jacob Hinds         Added without sharing per PMD
    */
    public without sharing class ReferenceHbkObjManageOwnership {
          /** Update the Reference Handbook.    */
        public static void updateObjOwnership(Map<id,id> refHbkIDMap) {
             system.debug('FLurz refHbkIDMap = ' + refHbkIDMap);
             List<Reference_HRE_CHB_Onboarding__c> refHbkList = [Select Id, OwnerID
                                                                 ,(select Id, OwnerId from Reference_HR_Essentials_Orders__r where Historical_Order_Indicator__c = 0)
                                                                 from Reference_HRE_CHB_Onboarding__c
                                                                 where id in :refHbkIDMap.keySet()];
        // xxx
            list<Reference_HRE_CHB_Orders__c> ordersToUpdate = new List<Reference_HRE_CHB_Orders__c>();
            if(!refHbkList.isEmpty()){
                for (Reference_HRE_CHB_Onboarding__c refHbk : refHbkList) {
                    for (Reference_HRE_CHB_Orders__c refHbkOrd : refHbk.Reference_HR_Essentials_Orders__r){
                        refHbkOrd.OwnerID = refHbkIDMap.get(refHbk.Id);
                        ordersToUpdate.add(refHbkOrd);
                    }
                }
            }
            system.debug('FLurz refHbkList = ' + refHbkList);
            if(!ordersToUpdate.isEmpty()){
                update ordersToUpdate;
            }
        }       
    }
    //