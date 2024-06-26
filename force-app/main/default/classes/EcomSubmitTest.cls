/* Test methods for the EcomSubmit class
  
  History
  -------
  06/05/2024 Dan Carmen        Created


*/
@isTest
public class EcomSubmitTest {
   @testSetup
   public static void setupData() { 
      EcomMethodsTest.setupData();
   }
    
   @isTest
   static void testSubmit() {
      RestRequest req = new RestRequest();
      String reqBody = '{"attributes":{"type":"ECommerce__c"},"Action__c":"OCC Form 1","OracleCommerceCloudId__c":"4793022b-3fcd-4fd6-bec8-9251ebb56194","ContactFirstName__c":"Billy","ContactLastName__c":"Idol","ContactEmail__c":"billy.idol@testing.com","ContactPhone__c":"(555)555-1234","Company__c":"Rebel Yell Inc","NumberOfEmployees__c":3,"PayrollFrequency__c":"monthly","Source__c":"OCC","SubmittedDateTime__c":"2024-04-29T22:41:37.221+0000"}';
      //String reqBody = '{"attributes":{"type":"ECommerce__c"},"Action__c":"OCC Form 1","OracleCommerceCloudId__c":"4793022b-3fcd-4fd6-bec8-9251ebb56194"}';
      req.requestBody = Blob.valueOf(reqBody);
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/EcomSubmit'; //Request URL
      req.httpMethod = 'POST';

      RestContext.request = req;
      RestContext.response= res;
      /*
      Ecommerce__c ecom = new Ecommerce__c(Action__c='OCC Form 1', OracleCommerceCloudId__c='793022b-3fcd-4fd6-bec8-9251ebb56194');
      ecom.ContactFirstName__c='Billy';
      ecom.ContactLastName__c='Idol';
      ecom.ContactEmail__c='billy.idol@testing.com';
      ecom.ContactPhone__c='(555)555-1234';
      ecom.Company__c='Rebel Yell Inc';
      ecom.NumberOfEmployees__c=3;
      ecom.PayrollFrequency__c='monthly';
      ecom.Source__c='OCC';
      ecom.SubmittedDateTime__c=Datetime.now();
      */
      Test.startTest();
      EcomSubmit.EcomResponse resp = EcomSubmit.doPost();
      Test.stopTest();
      Assert.isNotNull(resp);
      Assert.isTrue(resp.success);
      Assert.isNotNull(resp.leadId);
       
      Ecommerce__c checkEcom = [Select Id, Action__c, OracleCommerceCloudId__c
                                      ,ContactFirstName__c, ContactLastName__c, ContactEmail__c, ContactPhone__c
                                      ,Company__c, NumberOfEmployees__c, PayrollFrequency__c, Source__c, SubmittedDateTime__c
                                  From Ecommerce__c
                                 Where OracleCommerceCloudId__c='4793022b-3fcd-4fd6-bec8-9251ebb56194'];
      Assert.areEqual('Billy', checkEcom.ContactFirstName__c);
   } // testSubmit
    
   @isTest
   static void testNoBody() {
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/EcomSubmit'; //Request URL
      req.httpMethod = 'POST';

      RestContext.request = req;
      RestContext.response= res;

      Test.startTest();
      EcomSubmit.EcomResponse resp = EcomSubmit.doPost();
      Test.stopTest();
      Assert.isNotNull(resp);
      Assert.isFalse(resp.success);
      Assert.areEqual('Record Data Not Found!',resp.errMsg);
   } // testNoBody

   @isTest
   static void testBadBody() {
      RestRequest req = new RestRequest();
      //String reqBody = '{"attributes":{"type":"ECommerce__c"},"Action__c":"OCC Form 1","OracleCommerceCloudId__c":"4793022b-3fcd-4fd6-bec8-9251ebb56194","ContactFirstName__c":"Billy","ContactLastName__c":"Idol","ContactEmail__c":"billy.idol@testing.com","ContactPhone__c":"(555)555-1234","Company__c":"Rebel Yell Inc","NumberOfEmployees__c":3,"PayrollFrequency__c":"monthly","Source__c":"OCC","SubmittedDateTime__c":"2024-04-29T22:41:37.221+0000"}';
      String reqBody = '{This is a bad json body}';
      req.requestBody = Blob.valueOf(reqBody);
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/EcomSubmit'; //Request URL
      req.httpMethod = 'POST';

      RestContext.request = req;
      RestContext.response= res;

      Test.startTest();
      EcomSubmit.EcomResponse resp = EcomSubmit.doPost();
      Test.stopTest();
      Assert.isNotNull(resp);
      Assert.isFalse(resp.success);
      Assert.isTrue(resp.errMsg.startsWith('Error with record data'),'Error is: '+resp.errMsg);
   } // testNoBody

} // class EcomSubmitTest