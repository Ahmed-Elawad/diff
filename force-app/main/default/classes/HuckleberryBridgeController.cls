/**
* ----------------------------------------------------------------------------
* Class to handle communication from Salesforce to Huckleberry.
* -----------------------------------------------------------------------------
* History
* 01-03-2024   Vinay   Initial Version.
* ----------------------------------------------------------------------------
*/
public without sharing class HuckleberryBridgeController {
    @AuraEnabled
    public static Map<String, String> SendDataToHuckleberry(String pcQuoteDataString) {
        String accessToken = generateAccessToken();
        String huckURL = '';
        Map<String, String> returnMap = new Map<String, String>();
        ErrorLog__c log = new ErrorLog__c(ClassName__c='HuckleberryBridgeController',MethodName__c='SendDataToHuckleberry', CodeKey__c='LOG_DATA');
        if(!String.isEmpty(accessToken)) {
            Map<String, Object> pcQuoteDataRecord = (Map<String, Object>)JSON.deserializeUntyped(pcQuoteDataString);
            HuckleberryJSONController requestBody = new HuckleberryJSONController();
            requestBody.sfdc_request_header = new HuckleberryJSONController.Sfdc_request_header();
            requestBody.sfdc_request_header.request_id = pcQuoteDataRecord.get('Id').toString();
            requestBody.sfdc_request_header.request_date = String.valueOf(System.today());

            requestBody.sfdc_request_header.agency  = new HuckleberryJSONController.Agency();
            requestBody.sfdc_request_header.agency.user_name = pcQuoteDataRecord.get('Submitted_By__c').toString();
            List<String> linesOfBusiness = new List<String>();
            if(pcQuoteDataRecord.get('Opportunity_Type__c').toString() == 'BOP (Business Owners Package)') {
                linesOfBusiness.add('BOP');
            } else if (pcQuoteDataRecord.get('Opportunity_Type__c').toString() == 'General Liability') {
                linesOfBusiness.add('GL');
            } else if (pcQuoteDataRecord.get('Opportunity_Type__c').toString() == 'Workers Comp') {
                linesOfBusiness.add('WC');
            }
            requestBody.lines_of_business = linesOfBusiness;
            requestBody.company_name = pcQuoteDataRecord.get('Prospect_Client_Name__c').toString();
            requestBody.fein = formatFedId(pcQuoteDataRecord.get('Federal_Id_Number__c').toString());
            requestBody.first_name = pcQuoteDataRecord.get('Contact_First_Name__c').toString();
            requestBody.last_name = pcQuoteDataRecord.get('Contact_Last_Name__c').toString();
            requestBody.email = pcQuoteDataRecord.get('Contact_Email_Address__c').toString();
            requestBody.phone = pcQuoteDataRecord.get('Contact_Phone_Number__c') != '' ? (pcQuoteDataRecord.get('Contact_Phone_Number__c').toString().replaceAll('[^0-9]', '')) : '';
            requestBody.start_date = pcQuoteDataRecord.get('runEffectiveDate').toString();//'2024-01-20'; 
            requestBody.full_time_employees = pcQuoteDataRecord.get('Employees_Paid_Per_Payroll__c') != null ? (Integer) pcQuoteDataRecord.get('Employees_Paid_Per_Payroll__c') : 0;

            requestBody.billing_location = new HuckleberryJSONController.Billing_location();
            requestBody.billing_location.line1 = pcQuoteDataRecord.get('Prospect_Client_Street__c').toString();
            requestBody.billing_location.city = pcQuoteDataRecord.get('Prospect_Client_City__c').toString();
            requestBody.billing_location.state = pcQuoteDataRecord.get('Prospect_Client_State__c').toString();
            requestBody.billing_location.zip = pcQuoteDataRecord.get('Prospect_Client_Postal_Code__c').toString();
            requestBody.billing_location.formatted_address = pcQuoteDataRecord.get('Prospect_Client_Address_Text__c').toString();

            WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('HuckleBerry_Applications'); 
            HttpRequest request = new HttpRequest();
            //Set timeout
            if (String.isNotBlank(wss.Timeout__c)) {
                try {
                    Integer timeout = Integer.valueOf(wss.Timeout__c);
                    request.setTimeout(timeout);
                } catch (Exception e) {
                    System.debug('Error setting timeout: '+e.getMessage()+'; '+e.getStackTraceString());
                }
            }
            request.setEndpoint(wss.Endpoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+ accessToken);
            ErrorLog.addToDescription(log, 'JSON Payload sent to Huckleberry: '+(JSON.serialize(requestBody)));
            System.debug('HuckleberryBridgeController - SendDataToHuckleberry - Request body' + (JSON.serialize(requestBody)));
            request.setBody((JSON.serialize(requestBody)));
            Http http = new Http();
            HTTPResponse response;
            response = http.send(request);
            String responseMessage = response.getBody();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseMessage);
            returnMap.put('statusCode', response.getStatusCode().toString());
            if(response.getStatusCode() == 200){          
                huckURL = String.valueof(responseMap.get('application_url'));
                returnMap.put('message', String.valueof(responseMap.get('application_url')));
                ErrorLog.addToDescription(log, 'Quote URL received from Huckleberry.');
                System.debug('HuckleberryBridgeController - SendDataToHuckleberry - Success Response:' + huckURL);
            }else{
                returnMap.put('message', responseMap.get('message').toString());
                ErrorLog.addToDescription(log, 'Error receiving Quote URL received from from Huckleberry: '+responseMessage);
                System.debug('HuckleberryBridgeController - SendDataToHuckleberry - Error Response:' + responseMessage);
            }
        }
        return returnMap;
    }	

    public static String generateAccessToken(){
        ErrorLog__c log = new ErrorLog__c(ClassName__c='HuckleberryBridgeController',MethodName__c='generateAccessToken', CodeKey__c='LOG_DATA');
        String accessToken;
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('Huckleberry_Connect');  
        String client_secret = label.HuckleberryClientSecret;
        String client_id = label.HuckleberryClientId;
        HttpRequest request = new HttpRequest();
        request.setEndpoint(wss.Endpoint__c);
        request.setMethod('POST');
        request.setBody('client_id=' + client_id + '&client_secret=' + client_secret);
        Http http = new Http();
        HTTPResponse response;
        response = http.send(request);
        String responseMessage = response.getBody();
        system.debug('Response Data===>'+ response.toString());
        if(response.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseMessage);
            accessToken = String.valueof(responseMap.get('token'));
            ErrorLog.addToDescription(log, 'generateAccessToken received Authorization Token from Huckleberry.');
        }else{
            ErrorLog.addToDescription(log, 'generateAccessToken Error when trying to get Authorization Token from Huckleberry: '+responseMessage);
        }
        return accessToken;
    }

    public static String formatFedId(String valueToCheck) {
       String retValue = (String.isNotBlank(valueToCheck) ? valueToCheck.replaceAll('[^0-9.]', '') : '');
       return retValue;
    }

    @AuraEnabled
    public static void deletePCQuoteRecord(Id recordId){
        ErrorLog__c log = new ErrorLog__c(ClassName__c='HuckleberryBridgeController',MethodName__c='deletePCQuoteRecord', CodeKey__c='LOG_DATA');
        String sObjectName = recordId.getSObjectType().getDescribe().getName();
        String query = 'SELECT Id FROM '+ sObjectName + ' WHERE Id='+'\'' + recordId + '\'';
        SObject objectToDelete = Database.query(query);
        try {
            delete objectToDelete;
        } catch (Exception e) {
            ErrorLog.addToDescription(log, 'Unable to delete PC Quote Data record: '+e.getMessage());
        }
    }
}