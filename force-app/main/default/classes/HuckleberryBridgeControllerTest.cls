/* 
* Test Class for HuckleberyBridgeController
* --------------------------------------------------------------   
*  History
* -------------------------------------------------------------
* 1/15/2024   Vinay  Created
*
* -------------------------------------------------------------
*/
@isTest
public with sharing class HuckleberryBridgeControllerTest {
    @testSetup
    public static void setupData() {
    	WebServiceSettings__c TarmikaBOP = new WebServiceSettings__c(
            Name = 'Huckleberry_Connect'
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,LogAllCalls__c=true
            ,Endpoint__c = 'https://app-stage.huckleberry.com/integrations/salesforce/sign_in'
        );
        WebServiceSettings__c TarmikaWC = new WebServiceSettings__c(
            Name = 'HuckleBerry_Applications'
            ,Timeout__c = '10000'
            ,IsActive__c=true
            ,LogAllCalls__c=true
            ,Endpoint__c = 'https://app-stage.huckleberry.com/integrations/salesforce/applications'
        );
        WebServiceSettings__c[] wssList = new WebServiceSettings__c[]{TarmikaBOP,TarmikaWC};
            insert wssList;	
    }
    static testMethod void testToken() {
        Test.startTest();
        HuckleberryBridgeControllerMock mock = new HuckleberryBridgeControllerMock();
        mock.responseToUse = HuckleberryBridgeControllerMock.tokenResponse;
        Test.setMock(HttpCalloutMock.class, mock);
        String token = HuckleberryBridgeController.generateAccessToken();
        System.assertEquals(HuckleberryBridgeControllerMock.returnToken,token);
        Test.stopTest();
    }
    static testMethod void testSendDataToHuckleberry() {
        Test.startTest();
        HuckleberryBridgeControllerMock mock = new HuckleberryBridgeControllerMock();
        mock.responseToUse = HuckleberryBridgeControllerMock.tokenResponse;
        Test.setMock(HttpCalloutMock.class, mock);
        String requestBody = '{"Id": "a6N4C000000FJSQUA4","runEffectiveDate":"2024-01-23", "Contact_Email_Address__c": "test12@test.com","Contact_First_Name__c": "Test First name","Contact_Last_Name__c": "Test","Contact_Phone_Number__c": "(212) 333-4456","Employees_Paid_Per_Payroll__c": 6,"Federal_Id_Number__c": "121234567","Name": "P&C Quote Data 00011679","Opportunity_Type__c": "BOP","Opportunity__c": "0064C00000LMIuyQAH","Prospect_Client_Address_Text__c": "390 1st Street, San Francisco, CA 94105","Prospect_Client_City__c": "San Francisco","Prospect_Client_Name__c": "Test Prospect Client","Prospect_Client_Postal_Code__c": "94105","Prospect_Client_State__c": "CA","Prospect_Client_Street__c": "390 1st Street","Prospect_Client__c": "0014C000012AL3TQAW","Request_Date__c": "","Submitted_By__c": "test123.test@paychex.com"}';
        Map<String,String> result = HuckleberryBridgeController.SendDataToHuckleberry(requestBody);
        System.assertNotEquals(result.size() , 0);
        Test.stopTest();
    }
    static testMethod void testdeletePCQuoteRecord() {
        PC_Quote_Data__c testPCQuoteData = new PC_Quote_Data__c();
        insert testPCQuoteData;
        Test.startTest(); 
        HuckleberryBridgeController.deletePCQuoteRecord(testPCQuoteData.Id);
        Test.stopTest();
    }


}