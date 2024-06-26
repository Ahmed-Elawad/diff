/* History
 * 10/08/2020  Pujitha Madamanchi Created
 * 12/29/2020  Karthik Pedditi    Sort the Table Orderby Created date "descending".
   03/22/2022 Dan Carmen          Cleaned up code
 * 12/14/2023 Shilpa G			  APR0155814: Added method getIntentById

 */

public with sharing class InsightsDA {
    @AuraEnabled
    public static List<Marketing_Insights__c> getInsightsById(Id recordId) {
        try {
            List<Marketing_Insights__c> insights = new List<Marketing_Insights__c>();
            insights = [SELECT Id,
                                Name__c,
                                Type__c,
                                Contact__c,
                                Lead__c,
                            LP_URL__c,
                                Description__c,
                                Assessment_Link__c,
                                CreatedDate
                        FROM Marketing_Insights__c
                        WHERE ((Contact__c = :recordId 
                                OR Account__c =: recordId    
                                OR Lead__c =: recordId) 
                                AND (CreatedDate>= LAST_N_DAYS:90
                               OR Assessment_Link__c!= NULL))
                                ORDER BY CreatedDate DESC];
            return insights;
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }
    @AuraEnabled
    public static List<Customer_Intent_Signal__c> getIntentById(Id recordId) {
        try {
            List<Customer_Intent_Signal__c> intent = new List<Customer_Intent_Signal__c>();
            intent = [SELECT Id, Name,
                                Marketing_Action__c,
                                Intent_Type__c,
                                Contact__c,
                                Lead__c,
                            	External_URL__c,
                                Intent_Source__c,
                                Assessment_Link__c,
                                CreatedDate
                        FROM Customer_Intent_Signal__c
                        WHERE ((Contact__c = :recordId 
                                OR Account__c =: recordId    
                                OR Lead__c =: recordId) 
                                AND (CreatedDate>= LAST_N_DAYS:90
                               OR Assessment_Link__c!= NULL))
                                ORDER BY CreatedDate DESC];
            return intent;
        }
        catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }
}