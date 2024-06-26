public class BrokerCommissionTriggerMethods {
    public static void handleTrigger( Sobject[] recs, Map<Id,Broker_Commission__c> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete)  
    {
        ClientSpaceHelper objClient = new ClientSpaceHelper();
        objClient.handleTrigger(recs, oldMap, isBefore, isAfter, isDelete);
        
    }  
    
}