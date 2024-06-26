/**
 * This class contains unit tests for validating the PortalRequetControllerTest class.
 * 
 * History
 * --------
 * 01/13/2023   Vinay   created
 *
 */
@IsTest
public without sharing class CPA_PortalRequetControllerTest {
    static testMethod void testPortalReuest() {
        String json = '{"First_Name__c" :"test first name","Last_Name__c" : "test last name", "Email__c" : "testemail@test.com", "Email__c" : "testemail@test.com","Firm_Name__c" : "test firm name", "Firm_Zip_Code__c" : "12345", "Phone_Number__c" : "2122223333"}';
        Map<String,String> portalRequestMap = new Map<String,String>();
        portalRequestMap.put('AccountInfo',json);
        String result = CPA_PortalRequetController.insertCPAPortalRequest(json);
        CPA_PortalRequetController.sendNotificationEmail(portalRequestMap);
        System.assertNotEquals(result, null, 'Result as expected');
    }
}