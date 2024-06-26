public class GenerateMSAButton {
@AuraEnabled
    public static CSO_Tracking__c getTracking(string recordId){
        CSO_Tracking__c csTracking = [SELECT Id,User_Validated__c,Account_Eligible__c
                                      FROM CSO_Tracking__c WHERE Opportunity__c =:recordId];
        return csTracking;
    }
}