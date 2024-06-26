/* 
   Methods for working with the bulk v2 API

   
  History
  -------
  12/22/2020 Dan Carmen   Created
  04/06/2021 Dan Carmen   Added better error handling

 */
public class BulkApiHelper {
    
   public static Integer responseStatusCode = 0;
   public static String responseBody = null;

   public static String createBulkJob(String objectName, String operation, Id contentDocumentId) {
      System.debug('createBulkJob objectName='+objectName+' operation='+operation+' contentDocumentId='+contentDocumentId);
      String jobId = null;
        
      // create the job
      // have to use lower case 'insert' and  'update' for operation
      HttpRequest request = new HttpRequest();
      request.setMethod('POST');
      request.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest');
      request.setHeader('content-type', 'application/json' );
      request.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );//CR  
      String body = '{ '+
                        '"externalIdFieldName": "Id",'+  
                        '"lineEnding": "CRLF",'+ 
                        '"operation": "'+operation+'",'+ 
                        '"object": "'+objectName+'",'+ 
                        '"contentType": "CSV",'+
                        '"columnDelimiter": "COMMA"'+
                      '}';

      System.debug('createBulkJob body='+body);
      request.setBody(body);
      Http h = new Http();
      HttpResponse resp = (Test.isRunningTest() ? new BulkApiMock().respond(request) : h.send(request));
      System.debug('createBulkJob call1 resp='+resp+' resp body='+resp.getBody());
      responseBody = resp.getBody();
      responseStatusCode = resp.getStatusCode();
        
      if (resp.getStatusCode() <= 299) {
         Map<String, Object> respMap = (Map<String, Object>) Json.deserializeUntyped(resp.getBody());
         jobId = (String)respMap.get('id');

         ContentVersion cv = [SELECT Id, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId ];


         //second request to store data - might have to be called multiple times
         HttpRequest request1 = new HttpRequest();
         request1.setMethod('PUT');
         request1.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest/'+jobId+'/batches');
         request1.setHeader('content-type', 'text/csv' );
         request1.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );  
            
         request1.setBody(cv.VersionData.toString());
         Http h1 = new Http();
         HttpResponse resp1 = (Test.isRunningTest() ? new BulkApiMock().respond(request1) : h1.send(request1));

         System.debug('createBulkJob call2 resp1='+resp1+' resp1 body='+resp1.getBody());
         responseBody = resp1.getBody();
         responseStatusCode = resp1.getStatusCode();

         if (resp1.getStatusCode() <= 299) {
            //third request to start processing
            HttpRequest request2 = new HttpRequest();
            request2.setMethod('PATCH');
            request2.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest/'+jobId);
            request2.setHeader('content-type', 'application/json' );
            request2.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );  
                
            request2.setBody('{ "state" : "UploadComplete" }');
            Http h2 = new Http();
            HttpResponse resp2 =  (Test.isRunningTest() ? new BulkApiMock().respond(request2) : h2.send(request2));
            System.debug('resp2='+resp2);
            responseBody = resp2.getBody();
            responseStatusCode = resp2.getStatusCode();
            if(resp2.getStatusCode() <= 299) {
                    
            }
         }
      }

      return jobId;
    } // createBulkJob
    
   public static String STATE_OPEN='Open';
   public static String STATE_UPLOADED='UploadComplete';
   public static String STATE_INPROGRESS='InProgress';
   public static String STATE_ABORTED='Aborted';
   public static String STATE_COMPLETE='JobComplete';
   public static String STATE_FAILED='Failed';
    
   public static String jobState;
   public static Integer recsProcessed=0;
   public static Integer recsFailed=0;
   public static Long totalProcessingTime=0;
   public static String respBody=null;
   public static String errorMsg=null;
    
   public static String exceptionOccurred = null;

   public static void checkJobStatus(String jobId) {
      exceptionOccurred = null;
      HttpRequest request = new HttpRequest();
      request.setMethod('GET');
      request.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest/'+jobId);
      request.setHeader('content-type', 'application/json' );
      request.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );//CR  
      Http h1 = new Http();
      HttpResponse resp1 = (Test.isRunningTest() ? new BulkApiMock().respond(request) : h1.send(request));
      respBody = (resp1 != null ? resp1.getBody() : 'No Body');
      System.debug('resp1='+resp1+' resp body='+respBody);
      if (resp1.getStatusCode() <= 299) {
         try {
            Map<String, Object> respMap = (Map<String, Object>) Json.deserializeUntyped(resp1.getBody());
            jobState = (String)respMap.get('state');
            recsProcessed = (Integer)respMap.get('numberRecordsProcessed');
            recsFailed = (Integer)respMap.get('numberRecordsFailed');
            totalProcessingTime = (Long)respMap.get('totalProcessingTime');
            errorMsg = (String)respMap.get('errorMessage');
         } catch (Exception e) {
            exceptionOccurred = 'checkJobStatus exception='+e.getMessage()+'; code='+resp1.getStatusCode()+' resp body='+respBody;
         }
      } else {
         exceptionOccurred = 'checkJobStatus completed with status code='+resp1.getStatusCode()+' resp body='+respBody;
 
      }
      System.debug('jobState='+jobState);

   } // checkJobStatus
    
   public static AddFileQueueable afq = null;
    
   public static String exceptions = '';
    
   public static void getResults(String jobId, Id parentId) {
      afq = null;
      exceptions = '';
      HttpRequest request1 = new HttpRequest();
      request1.setMethod('GET');
      request1.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest/'+jobId+'/successfulResults/');
      request1.setHeader('content-type', 'application/json' );
      request1.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );//CR  
      Http h1 = new Http();
      HttpResponse resp1 = null;
      String successBody = null;
      String failureBody = null;
      try {
         resp1 = h1.send(request1);
         successBody =  resp1.getBody();
      //} catch (System.CalloutException ce) {
      } catch (Exception e) {
         // if the file returned is too large will fail here. 
         exceptions += '\nError getting Success file: '+e.getMessage();
      }
      System.debug('resp1='+resp1);
      //System.debug('resp1 body='+(resp1 != null ? resp2.getBody() : 'No Body'));
       
       
      HttpRequest request2 = new HttpRequest();
      request2.setMethod('GET');
      request2.setEndpoint(URl.getOrgDomainUrl().toExternalForm()+'/services/data/v51.0/jobs/ingest/'+jobId+'/failedResults/');
      request2.setHeader('content-type', 'application/json' );
      request2.setHeader('Authorization' ,'Bearer '+userInfo.getSessionId() );//CR  
      Http h2 = new Http();
      HttpResponse resp2 = null;
      try {
          resp2 = h2.send(request2);
          failureBody = resp2.getBody();
      } catch (Exception e) {
         // if the file returned is too large will fail here. 
         exceptions += '\nError getting Failure file: '+e.getMessage();
      }
      System.debug('resp2='+resp2);
      //System.debug('resp2 body='+(resp2 != null ? resp2.getBody() : 'No Body'));
      afq = new AddFileQueueable();
      if (String.isNotBlank(successBody)) {
         String fileName1 = 'success'+datetime.now().format('MMddyyyyHHmmss')+'.csv';
         afq.addAnotherFile(new Id[]{parentId}, fileName1, fileName1, null, Blob.valueOf(successBody));
      }
      if (String.isNotBlank(failureBody)) {
         String fileName2 = 'failure'+datetime.now().format('MMddyyyyHHmmss')+'.csv';
         afq.addAnotherFile(new Id[]{parentId}, fileName2, fileName2, null, Blob.valueOf(failureBody));
      }
      if (!afq.wrappersToProcess.isEmpty()) {
         ContentDocumentUtilities.SKIP_TRIGGER=true;
         afq.processRecs();
      }

   } // getResults
    
} // BulkApiHelper