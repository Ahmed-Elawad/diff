/* 
   Mock New Client call

   
  History
  -------
  09/19/2022 Dan Carmen       Created

*/
@isTest
global class FlexNewClientOnboardingMock implements HttpCalloutMock {

    global FlexNewClientOnboardingMock(Boolean isSuccess) {
       if (isSuccess) {
          responseCode = 200;
          respBody = '{"content":[{"client":{"ttesinType":"FEIN","tin":"476845124","legalName":"Testing Account 1","legalAddress":{"streetAddressOne":"844 Testing Lane","city":"Rochester","stateProv":"NY","postalcode":"12584","countryCode":"US"},"ceid":"00DCE1NVK2BVUZ8ZE09Y","caid":"00DCE1NVK2BVUZFHE1EQ","assignedName":"NYA160","user":{"contactId":"0030g00002MdkNsAAJ","email":"testingEmail12321@gmai1.com","firstName":"Joe","lastName":"Shmo","telephone":{"areaCode":"778","number":"8541205"},"guid":"00DCE1NVK2B5FX75DXKV"},"cltPeo":false}}]}';
       } else {
          responseCode = 400;
          respBody = '{"content":[],"errors":[{"code":"API-CLIENTADD105","description":"Partial match. Clt Add Exists - Tin Match Only. New client was not created.","resolution":"0030g00002KbcXqAAJ12:04:21.551Z"}]}';
       }
    } // FlexNewClientOnboardingMock
    
    global Integer responseCode=200;
    global String respBody='';

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody(respBody);
        res.setStatus(String.valueOf(responseCode));
        res.setStatusCode(responseCode);
        return res;
    } // respond

} // class FlexNewClientOnboardingMock