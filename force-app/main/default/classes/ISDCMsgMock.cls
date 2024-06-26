/** Mock message to ISDC
 *
 * History
 * -------
 * 05/06/2014 Dan Carmen        Created.
   11/14/2019 Dan Carmen        Remove ISDC code


 */
@isTest
global class ISDCMsgMock {
   global ISDCMsgMock() {}
   /*
 
global class ISDCMsgMock implements HttpCalloutMock {
   
   global static String MOCK_URL='http://api.salesforce.com/foo/bar';
   
   // Implement this interface method
   global HTTPResponse respond(HTTPRequest req) {
      // Optionally, only send a mock response for a specific endpoint
      // and method.
      System.assertEquals(MOCK_URL, req.getEndpoint());
      System.assertEquals('POST', req.getMethod());

      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', 'application/json');
      res.setBody('{"foo":"bar"}');
      res.setStatus('Success');
      res.setStatusCode(200);
      return res;
   }
   */
} // ISDCMsgMock