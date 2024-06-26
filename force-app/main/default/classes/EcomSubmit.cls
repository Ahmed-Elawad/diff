/* 
   Rest service to process the ecom forms

Ecommerce__c ecom = new Ecommerce__c(Action__c='OCC Form 1', OracleCommerceCloudId__c='4793022b-3fcd-4fd6-bec8-9251ebb56194'
                                    ,ContactFirstName__c='Billy', ContactLastName__c='Idol'
                                    ,ContactEmail__c='billy.idol@testing.com', ContactPhone__c='(555)555-1234', Company__c='Rebel Yell Inc'
                                    ,NumberOfEmployees__c=3, PayrollFrequency__c='monthly'
                                    ,Source__c='OCC', SubmittedDateTime__c=Datetime.now());
String output = json.serialize(ecom).replace('number_Z','number');
System.debug('output='+output);

{"attributes":{"type":"ECommerce__c"},"Action__c":"OCC Form 1","OracleCommerceCloudId__c":"4793022b-3fcd-4fd6-bec8-9251ebb56194","ContactFirstName__c":"Billy","ContactLastName__c":"Idol","ContactEmail__c":"billy.idol@testing.com","ContactPhone__c":"(555)555-1234","Company__c":"Rebel Yell Inc","NumberOfEmployees__c":3,"PayrollFrequency__c":"monthly","Source__c":"OCC","SubmittedDateTime__c":"2024-04-29T22:41:37.221+0000"}

  History
  -------
  04/29/2024 Dan Carmen        Created


*/
@RestResource(urlMapping='/EcomSubmit/*')
global without sharing class EcomSubmit {
    
   global class EcomResponse {
      global Boolean success=false;
      global Id opportunityId;
      global Id leadId;
      global Id accountId;
      global Opportunity opp;
      global String errMsg;
   } // class EcomResponse
   @HttpPost
    
   global static EcomResponse doPost() {
   	  //System.debug('doPost ecom='+ecom);
      RestRequest req = RestContext.request;
      RestResponse res = RestContext.response;
      EcomResponse eResp = new EcomResponse();
      String reqBody = (req.requestBody != null ? req.requestBody.toString() : null);
      System.debug('reqBody='+reqBody);
      if (reqBody == null) {
         return logError(eResp,false,'Record Data Not Found!');
      }
      Ecommerce__c ecom = null;
      try {
         ecom = (Ecommerce__c)JSON.deserialize(reqBody,Ecommerce__c.class);
      } catch (Exception e) {
         return logError(eResp,false,'Error with record data: '+(e.getMessage()+'; '+e.getStackTraceString()));
      }
      TriggerMethods.SKIP_TRIGGERS=true;
      if (String.isNotBlank(ecom.OracleCommerceCloudId__c) && String.isBlank(ecom.MktgId__c) ){
         ecom.MktgId__c = ecom.OracleCommerceCloudId__c;
      }
      insert ecom;
      try {
         EcomMethods.processEcoms(new Id[]{ecom.Id});
         eResp.success=true;
      } catch (Exception e) {
         return logError(eResp,false,'Error processing data: '+(e.getMessage()+'; '+e.getStackTraceString()));
      }
      Ecommerce__c[] checkEcoms = EcomMethods.getEcoms(new Id[]{ecom.Id},null);
      Ecommerce__c checkEcom = (!checkEcoms.isEmpty() ? checkEcoms[0] : null);
      System.debug('checkEcom='+checkEcom);
      eResp.success=(checkEcom != null);
      eResp.opportunityId = (checkEcom != null ? checkEcom.Opportunity__c : null);
      eResp.leadId = (checkEcom != null ? checkEcom.Lead__c : null);
      eResp.accountId = (checkEcom != null ? checkEcom.Account__c : null);
      eResp.opp = (eResp.opportunityId != null ? [Select Id, Name, CloseDate, Frequency__c, StageName, Employees_Paid_Per_Payroll__c
                                                    From Opportunity
                                                   Where Id = :eResp.opportunityId]
                                                : null);
      return eResp;
   } // doPost
    
   public static EcomResponse logError(EcomResponse eResp, Boolean isSuccess, String errMsg) {
      eResp.success=isSuccess;
      eResp.errMsg = errMsg;
      return eResp;
   } // logError

} // class EcomSubmit