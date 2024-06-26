/* 
* Mock Huckleberry Call for HuckleberyBridgeController
* --------------------------------------------------------------   
*  History
* -------------------------------------------------------------
* 1/15/2024   Vinay  Created
*
* -------------------------------------------------------------
*/
@isTest
global with sharing class HuckleberryBridgeControllerMock implements HttpCalloutMock{
    public static String returnToken = 'd1320367-c3e4-497c-860f-29b367e29f85';
    public static String tokenResponse = '{"token":"'+returnToken+'"}';
    global String responseToUse = tokenResponse;
    public static String requestBody = '{"start_date":"2024-01-20","sfdc_request_header":{"request_id":"a6N4C000000FJSAUA4","request_date":"2023-01-15","agency":{"user_name":"vkmedishetty@paychex.com"}},"revenue":2323,"phone":"2123334456","payroll":2323,"part_time_employees":133,"lines_of_business":["BOP"],"legal_entity":"test legal entity","last_name":"Test","full_time_employees":23,"first_name":"Test First name","fein":"121234567","email":"test12@test.com","company_name":"Test Prospect Client","business_start_year":2019,"billing_location":{"zip":"94105","state":"CA","line2":"","line1":"test street","formatted_address":"","city":"San Francisco"}}';

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(responseToUse);
        res.setStatusCode(200);
        return res;
    }

    global static HTTPResponse respondApplication(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Authorization', 'Bearer '+ returnToken);
        res.setBody(requestBody);
        res.setStatusCode(200);
        return res;
    }

    public static String successResponse = '{'+
        '"status": {'+
        '    "statusCode": "Success",'+ 
        '    "statusDescription": "Request processed successfully"'+
        '},'+
        '"messages": ['+
        '    {'+
        '        "messageDescription": "Insured Business data saved"'+
        '    }'+
        '],'+
        '"errors": [],'+
        '"quoteResponseHeader": {'+
        '    "quoteResponseIdentifier": "0b981714-ace0-4c52-be1c-dc00b08327b2",'+
        '    "externalQuoteRequestIdentifier": "0000009574",'+
        '    "quoteResponseDate": 1670333939000,'+
        '    "internalQuoteRequestIdentifier": "0000063054",'+
        '    "agency": {'+
        '        "agencyNumber": null,'+
        '        "producerCode": null,'+
        '        "userName": "akosel@paychex.com",'+
        '        "password": null'+
        '    },'+
        '    "quoteProcessingStatus": {'+
        '        "statusCode": "Saved as Draft Quote Request",'+
        '        "statusDescription": null'+
        '    }'+
        '},'+
        '"application_url": "hhtps://app.huckleberyy.com/0768974904"'+
    	'}';
    public static String failureResponse = '{'+
        '"status": {'+
        '    "statusCode": "Failure",'+ 
        '    "statusDescription": "Error in processing the request"'+
        '},'+
        '"messages": [],'+
        '"errors": ['+
        '{'+
        '	"errorCode": "100",'+
        '	"errorDescription": "The agent id passed in the field agency.userName  not exist on Huckleberry"'+
        '}'+
        ']'+
    	'}';
}