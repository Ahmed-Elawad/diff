/* 
   Mock CSO Call

   
  History
  -------
  08/01/2022 Dan Carmen       Created

*/
@isTest
global class CsoQueueableMock implements HttpCalloutMock {
    
    global Integer responseCode=200;

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setBody('{"example":"test"}');
        res.setStatusCode(responseCode);
        return res;
    } // respond

} // class CsoQueueableMock