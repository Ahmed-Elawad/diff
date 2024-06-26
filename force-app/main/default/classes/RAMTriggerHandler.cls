/* 
 * History
 * -------
  01/12/2023 Rohit Ranjan Created
  

*/



public class RAMTriggerHandler {
    public static List<Reference_Account_Management__c> setRAMOwnerRR(List<Reference_Account_Management__c> ramList) {        
        Map<Reference_Account_Management__c,Id> rAMRefMap = new Map<Reference_Account_Management__c,Id>();
        Id recTypeId = [Select id from RecordType where developername ='HRS_4S_Conversion_5500'].Id;
        Id ownrId= [select id from group where developerName='HRS_4S_Conv_5500_RAM' AND type ='Queue' limit 1].Id;
        for(Reference_Account_Management__c r:ramList){
            if(r.recordTypeId == recTypeId){
                r.OwnerId = ownrId;
            }
            if(r.recordTypeId == recTypeId && r.Reference_401k_S125__c != null){
                rAMRefMap.put(r, r.Reference_401k_S125__c);
            }
        }
        if(rAMRefMap.size()>0){
            List<Reference_401k_S125__c> refList =[Select id,CAAR_Prepared_Date__c from Reference_401k_S125__c where id IN:rAMRefMap.values()];
            Map<Id,Reference_401k_S125__c> refMap= new Map<Id,Reference_401k_S125__c>(refList);
            List<Reference_Account_Management__c> rmList = new List<Reference_Account_Management__c>();            
            for(Reference_Account_Management__c r:ramList){                
                if(rAMRefMap.containsKey(r)){
                    if(refMap.get(rAMRefMap.get(r)).CAAR_Prepared_Date__c != null)
                    {
                        rmList.add(r);                
                    }
                }
            }
            if(rmList.size() > 0){
                RoundRobin.prepareGenericRoundRobin(rmList,null); 
            }  
        }
        return ramList;
    }
    
}