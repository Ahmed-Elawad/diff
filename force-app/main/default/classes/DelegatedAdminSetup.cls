/* 
   Methods for setting up a user as a delegated admin 

   
  History
  -------
  09/19/2024 Dan Carmen        Created

*/
public class DelegatedAdminSetup {

   private static String baseUrl = URL.getOrgDomainUrl().toExternalForm()+'/services/data/v60.0/tooling/';
   
   // for testing purposes only
   public static Boolean useTestGrpId=false;
   public static String testGroupId=null;
    
   public static String getDelegateGroupId(String groupName) {
       if (useTestGrpId) {
          return testGroupId;
       }
       HTTPRequest req = new HTTPRequest();
       groupName = groupName.replaceAll(' ','+');
       System.debug('groupName='+groupName);
       req.setEndpoint(baseUrl + 'query?q=Select+id,Name,DeveloperName+from+DelegateGroup+Where+Name=\''+groupName+'\'');
       //req.setEndpoint(baseUrl + 'query?q=+Select+id,Name,DeveloperName+from+DelegateGroup');
       System.debug('endpoint='+req.getEndpoint());
       req.setMethod('GET');
       // OAuth header
       req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
       req.setHeader('Content-Type', 'application/json');
       Http h = new Http();
       HttpResponse res = h.send(req);
       System.debug('res='+res);
       System.debug('res body='+res.getBody());
       String groupId = null;
       
       Map<String,Object> respMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
       System.debug('keys='+respMap.keySet());
       Integer nbrResults = (respMap.containsKey('size') ? Integer.valueOf(respMap.get('size')) : 0);
       System.debug('nbrResults='+nbrResults);
       if (nbrResults == 1) {
          Object[] records = (Object[])respMap.get('records');
          System.debug('records='+records);
          if (records != null && !records.isEmpty()) {
             Map<String,Object> recMap = (Map<String,Object>)records[0];
              if (recMap.containsKey('Id')) {
                 groupId = String.valueOf(recMap.get('Id'));
              }
                
          }
       }
       
       // successful retrieval
       // StatusCode=200  body={"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"DelegateGroup","records":[{"attributes":{"type":"DelegateGroup","url":"/services/data/v60.0/tooling/sobjects/DelegateGroup/02f0g000000CfQsAAK"},"Id":"02f0g000000CfQsAAK","Name":"All Sales","DeveloperName":"All_Sales"}]}
       // not found
       // StatusCode=200  body={"size":0,"totalSize":0,"done":true,"queryLocator":null,"entityTypeName":null,"records":[]}
     System.debug('groupId='+groupId);
     return groupId;
   } // getDelegateGroupId
    
   // for testing purposes only
   public static String testGrpMemberMsg = null;
   
   public static String addToDelegateGroup(Id groupId, Id userId) {
      if (String.isNotBlank(testGrpMemberMsg)) {
         return testGrpMemberMsg;
      }
      // ALL Sales : 02f0g000000CfQsAAK
      // Userid : 00530000000xxTA
      // DelegatedAdminSetup.addToDelegateGroup('02f0g000000CfQsAAK','00530000000xxTA');
      HTTPRequest req = new HTTPRequest();
       req.setEndpoint(baseUrl + 'sobjects/DelegateGroupMember');
       System.debug('endpoint='+req.getEndpoint());
       req.setMethod('POST');
       // OAuth header
       req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
       req.setHeader('Content-Type', 'application/json');
       req.setBody('{"DelegateGroupId":"'+groupId+'","UserOrGroupId":"'+userId+'"}');
       
       System.debug('reqBody='+req.getBody());
       Http h = new Http();
       HttpResponse res = null;
       String exceptionMsg;
       try {
          res = h.send(req);
       } catch (Exception e) {
          exceptionMsg = e.getMessage();
          System.debug('addToDelegateGroup e='+e.getMessage()+', '+e.getStackTraceString());
       }
       System.debug('addToDelegateGroup res='+res);
       System.debug('addToDelegateGroup res body='+(res != null ? res.getBody() : 'NoBody'));
       String status = (res != null && res.getStatusCode() == 201 ? 'Added to Group Successfully'
                          : (res != null && res.getStatusCode() == 400 ? 'Already in Group' 
                             : (res != null ? 'Unknown error: '+res.getStatusCode() : 'Exception: '+exceptionMsg)));

       // SUCCESS
       // StatusCode=201 body={"id":"02gRL0000004s8HYAQ","success":true,"errors":[],"warnings":[],"infos":[]}
       // Already exists
       // StatusCode=400 body=[{"message":"duplicate value found: <unknown> duplicates value on record with id: <unknown>","errorCode":"DUPLICATE_VALUE","fields":[]}]
       // 
      return status;
   } // addToDelegateGroup


} // class DelegatedAdminSetup