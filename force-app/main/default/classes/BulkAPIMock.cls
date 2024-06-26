/* 
   Mock for the callout

MOCK2 status check example response
Status=OK, StatusCode=200] resp body={"id":"7501b000004tsZVAAY","operation":"update","object":"Account","createdById":"00530000000xxTAAAY","createdDate":"2021-01-04T19:05:40.000+0000","systemModstamp":"2021-01-04T19:06:45.000+0000","state":"InProgress","concurrencyMode":"Parallel","contentType":"CSV","apiVersion":50.0,"jobType":"V2Ingest","lineEnding":"CRLF","columnDelimiter":"COMMA","numberRecordsProcessed":97600,"numberRecordsFailed":21,"retries":40,"totalProcessingTime":1967272,"apiActiveProcessingTime":26767066,"apexProcessingTime":93900162}

MOCK3 Response:
resp1=System.HttpResponse[Status=OK, StatusCode=200] resp body="sf__Id","sf__Created",Id,FirstName,LastName
"00Q5C000002whmcUAA","false","00Q5C000002whmc","Harry","Potter"
"00Q5C000002whmmUAA","false","00Q5C000002whmm","Ron","Weasley"
"00Q5C000002whmhUAA","false","00Q5C000002whmh","Hermione","Granger"
"00Q5C000002wl00UAA","false","00Q5C000002wl00UAA","Albus","Dumbledore"


   
  History
  -------
  12/31/2020 Dan Carmen   Created
  02/10/2021 Dan Carmen   Added more conditions

 */
@isTest
global class BulkAPIMock implements HttpCalloutMock {
    
    public static String JOB_ID = '7505C000002Q9xCQAS';
    
    public static String MOCK1='Mock1';
    public static String MOCK2='Mock2';
    public static String MOCK2a='Mock2a';  // Failed
    public static String MOCK2b='Mock2b';  // Complete
    public static String MOCK2c='Mock2c';
    public static String MOCK3='Mock3';
    
    public static String MOCK_VERSION=MOCK1;
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if (MOCK_VERSION == MOCK1) {
           response.setBody('{ "id" : "'+JOB_ID+'"}');
        } else if (MOCK_VERSION == MOCK2) {
           String body='{"id":"7501b000004tsZVAAY","operation":"update","object":"Account","createdById":"00530000000xxTAAAY","createdDate":"2021-01-04T19:05:40.000+0000","systemModstamp":"2021-01-04T19:06:45.000+0000","state":"InProgress","concurrencyMode":"Parallel","contentType":"CSV","apiVersion":50.0,"jobType":"V2Ingest","lineEnding":"CRLF","columnDelimiter":"COMMA","numberRecordsProcessed":4,"numberRecordsFailed":1,"retries":40,"totalProcessingTime":1313,"apiActiveProcessingTime":26767066,"apexProcessingTime":93900162}';
           response.setBody(body);
        } else if (MOCK_VERSION == MOCK2a) {
           String body='{"id":"7501b000004tsZVAAY","operation":"update","object":"Account","createdById":"00530000000xxTAAAY","createdDate":"2021-01-04T19:05:40.000+0000","systemModstamp":"2021-01-04T19:06:45.000+0000","state":"Failed","concurrencyMode":"Parallel","contentType":"CSV","apiVersion":50.0,"jobType":"V2Ingest","lineEnding":"CRLF","columnDelimiter":"COMMA","numberRecordsProcessed":4,"numberRecordsFailed":1,"retries":40,"totalProcessingTime":1313,"apiActiveProcessingTime":26767066,"apexProcessingTime":93900162,"errorMessag":"Bad Message"}';
           response.setBody(body);
        } else if (MOCK_VERSION == MOCK2b) {
           String body='{"id":"7501b000004tsZVAAY","operation":"update","object":"Account","createdById":"00530000000xxTAAAY","createdDate":"2021-01-04T19:05:40.000+0000","systemModstamp":"2021-01-04T19:06:45.000+0000","state":"JobComplete","concurrencyMode":"Parallel","contentType":"CSV","apiVersion":50.0,"jobType":"V2Ingest","lineEnding":"CRLF","columnDelimiter":"COMMA","numberRecordsProcessed":4,"numberRecordsFailed":1,"retries":40,"totalProcessingTime":1313,"apiActiveProcessingTime":26767066,"apexProcessingTime":93900162}';
           response.setBody(body);
        } else if (MOCK_VERSION == MOCK3) {
           String body = '"sf__Id","sf__Created",Id,FirstName,LastName\n'+
                         '"00Q5C000002whmcUAA","false","00Q5C000002whmc","Harry","Potter"\n'+
                         '"00Q5C000002whmmUAA","false","00Q5C000002whmm","Ron","Weasley"\n'+
                         '"00Q5C000002whmhUAA","false","00Q5C000002whmh","Hermione","Granger"';
           response.setBody(body);
        }
        response.setStatusCode(200);
        return response; 
    }
    
} // class BulkAPIMock