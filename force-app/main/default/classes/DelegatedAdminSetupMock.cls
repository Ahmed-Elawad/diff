/* Mock call response
   
   History
   -------
   03/20/2024 Dan Carmen        Created

*/
@isTest
global class DelegatedAdminSetupMock implements HttpCalloutMock {
    global String responseToUse = '';
    global Integer responseCode = 200;

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(responseToUse);
        res.setStatusCode(responseCode);
        return res;
    }

    public static String groupIdFound = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"DelegateGroup","records":[{"attributes":{"type":"DelegateGroup","url":"/services/data/v60.0/tooling/sobjects/DelegateGroup/02f0g000000CfQsAAK"},"Id":"02f0g000000CfQsAAK","Name":"All Sales","DeveloperName":"All_Sales"}]}';
    
    public static String groupIdNotFound = '{"size":0,"totalSize":0,"done":true,"queryLocator":null,"entityTypeName":null,"records":[]}';
    
    public static String grpMemberSuccess = '{"id":"02gRL0000004s8HYAQ","success":true,"errors":[],"warnings":[],"infos":[]}';
    
    public static String grpMemberExists = '[{"message":"duplicate value found: <unknown> duplicates value on record with id: <unknown>","errorCode":"DUPLICATE_VALUE","fields":[]}]';
} // class DelegatedAdminSetupMock