/* 
 * Test class for OptOutHandler
 
 *
 * History
 * -------
   01/25/2024 Dan Carmen       Created

 */
@isTest
public class OptOutHandlerTest {
    /*
     submitOptOut(String emailAddr) {
        Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c(Name=emailAddr);
        refDNC.Contact_Email__c = emailAddr;
        refDNC.Status__c = 'New';
        refDNC.Requestor__c = 'OptOutHandler';
        insert refDNC;
        String returnMesasge = 'Opt Out submitted for '+emailAddr;
        return returnMesasge;
   */
   /*
   static testMethod void testSubmit() {
      String retMsg = OptOutHandler.submitOptOut('testing@thisisatest.com');
      Assert.isTrue(retMsg.contains('testing@thisisatest.com'));
      Reference_Do_Not_Contact__c[] rdncs = [Select Id, Contact_Email__c, Requestor__c, Status__c
                                               From Reference_Do_Not_Contact__c
                                              Where Contact_Email__c = 'testing@thisisatest.com'];
      Assert.areEqual(1,rdncs.size());
      Assert.areEqual('OptOutHandler',rdncs[0].Requestor__c);
      Assert.areEqual('New',rdncs[0].Status__c);
   } // testSubmit
    */
   static testMethod void testUnsubscribeGood() {
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/unsubscribe/testing@thisisatest.com';  //Request URL
      req.httpMethod = 'POST';//HTTP Request Type
      RestContext.request = req; 
      RestContext.response= res;
       
      String retMsg = OptOutHandler.unsubscribe();
      Assert.isTrue(retMsg.contains('testing@thisisatest.com'),'retMsg='+retMsg);
      Reference_Do_Not_Contact__c[] rdncs = [Select Id, Contact_Email__c, Requestor__c, Status__c
                                               From Reference_Do_Not_Contact__c
                                              Where Contact_Email__c = 'testing@thisisatest.com'];
      Assert.areEqual(1,rdncs.size());
      Assert.areEqual('OptOutHandler',rdncs[0].Requestor__c);
      Assert.areEqual('New',rdncs[0].Status__c);
   } // testUnsubscribeGood
    
   static testMethod void testUnsubscribeEncoded() {
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      String testValue = EncodingUtil.urlEncode('testing@thisisatest.com','UTF-8');
      System.debug('testUnsubscribeEncoded testValue='+testValue);
      req.requestURI = '/services/apexrest/unsubscribe/'+testValue;  //Request URL
      req.httpMethod = 'POST';//HTTP Request Type
      RestContext.request = req; 
      RestContext.response= res;
       
      String retMsg = OptOutHandler.unsubscribe();
      Assert.isTrue(retMsg.contains('testing@thisisatest.com'),'retMsg='+retMsg);
      Reference_Do_Not_Contact__c[] rdncs = [Select Id, Contact_Email__c, Requestor__c, Status__c
                                               From Reference_Do_Not_Contact__c
                                              Where Contact_Email__c = 'testing@thisisatest.com'];
      Assert.areEqual(1,rdncs.size());
      Assert.areEqual('OptOutHandler',rdncs[0].Requestor__c);
      Assert.areEqual('New',rdncs[0].Status__c);
   } // testUnsubscribeEncoded

   static testMethod void testBadValue() {
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/unsubscribe/NotAnEmail';  //Request URL
      req.httpMethod = 'POST';//HTTP Request Type
      RestContext.request = req; 
      RestContext.response= res;
       
      String retMsg = OptOutHandler.unsubscribe();
      Assert.isTrue(retMsg.contains('NotAnEmail'),'retMsg='+retMsg);
      Reference_Do_Not_Contact__c[] rdncs = [Select Id, Contact_Email__c, Requestor__c, Status__c
                                               From Reference_Do_Not_Contact__c
                                              Where Contact_Email__c = 'NotAnEmail'];
      Assert.areEqual(1,rdncs.size());
      Assert.areEqual('OptOutHandler',rdncs[0].Requestor__c);
      Assert.areEqual('New',rdncs[0].Status__c);
   } // testUnsubscribeEncoded

    
} // class OptOutHandlerTest