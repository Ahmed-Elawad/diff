/**
 * Global class needed to create Mock response for NSSLegacyHistoryController RESTful callout test class
 * creates response showing an error returned from callout
 * History
 * -------
 * 2/03/2014 Cindy Freeman   Created
 * 11/14/2017	Cindy Freeman	code was deleted since it is not used anymore
 */
@isTest 
global class NSSLegacyHistoryMockGoodResponse implements HttpCalloutMock {
	    global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            return res;
        }
}