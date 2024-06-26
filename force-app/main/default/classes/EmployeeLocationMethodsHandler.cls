/* **********************************************************************************************************************************
* History
* -------
* 01/16/2024 Pratik Das       Created (APR0162760: To add distinct employee location state to acord data )
* 
* 
************************************************************************************************************************************/
public class EmployeeLocationMethodsHandler implements TriggerInterfaceC{
    
    public static Boolean SKIP_TRIGGER=false;
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete){   
        Set<Id> setAcordIds=new Set<Id>();
        if (isBefore) {
            //System.debug('EmployeeLocationMethodsHandler.handleTrigger isBefore');
            if (Trigger.isInsert){
                
            } 
            else if(Trigger.isUpdate){
                
            }
        }
        else if(isAfter){
            if (trigger.isDelete){
                for (Employee_Location__c loc: (List<Employee_Location__c>)trigger.old){
                    setAcordIds.add(loc.Acord_Name__c);
                }
            }

            else{
                 for (Employee_Location__c loc: (List<Employee_Location__c>)trigger.new){
                    setAcordIds.add(loc.Acord_Name__c);
                }
            }
        }
        if(setAcordIds!=null && !setAcordIds.isEmpty()){
            updateAccordLocation(setAcordIds);
        }
    } // handleTrigger
    public static void updateAccordLocation(Set<Id> setAcordIds){
        List<Acord__c> accordList = [Select id,Location_Distinct_State__c, (Select State__c,id,Acord_Name__c from Employee_Locations__r) FROM Acord__c WHERE id in: setAcordIds];

        for (Acord__c acrd: accordList){
            Set<String> setEmpLocs = new Set<string>();
            List<String> allLoc=new List<String>();
            string allEmpLocs = '';
            if(acrd.Employee_Locations__r != null){
                for (Employee_Location__c loc : acrd.Employee_Locations__r){
                    setEmpLocs.add(loc.State__c);
                }
                allLoc.addAll(setEmpLocs);
                acrd.Location_Distinct_State__c=string.join(allLoc,',');
            }
            else{
                acrd.Location_Distinct_State__c = '';
            }
        }

        update accordList;
    }
}