/** Methods used for sending messages to ISDC.
 *
 * History
 * -------
 * 04/29/2014 Dan Carmen        Created.
   11/14/2019 Dan Carmen        Remove ISDC Code

 */
global with sharing class ISDCMsgHandler {
   
   public ISDCMsgHandler() {}
/*
   //public LeadLoaderConfig__c config;
   public WebServiceSettings__c webServiceSetting;
   
   public ISDCMsgHandler(WebServiceSettings__c p_webServiceSetting) {
   	webServiceSetting = p_webServiceSetting;
   } // ISDCMsgHandler
   
   // is this message handler active?
   public Boolean isActive() {
      return (webServiceSetting != null && webServiceSetting.IsActive__c);
   } // isActive
   
   public Boolean hasIdsToSend() {
      return (isActive() && !idList.isEmpty());
   } // hasIdsToSend
   
   public void addId(Id idToAdd) {
      if (isActive()) {
         idList.add(idToAdd);
      }
   } // addId
   
   // the list of ids we'd be sending as part of the message
   private Id[] idList = new Id[]{};
   
   public Boolean sendMessage() {
   	Boolean allOkay = true;
      if (isActive() && !idList.isEmpty()) {
     	   String body = webServiceSetting.MsgBody__c+'&ids='+EncodingUtil.urlEncode(JSON.serialize(idList), 'ISO-8859-1'); 
     	   System.debug('body='+body);
     	   sendHTTPRequest(UserInfo.getUserId(), webServiceSetting.Endpoint__c, body,webServiceSetting.LogAllCalls__c);
     	   idList.clear();
      } // if (isActive
      return allOkay;
   } // sendMessage
   
   public static Map<Id,ISDCMsgHandler> msgHandlerMap = new Map<Id,ISDCMsgHandler>();
   
   public static ISDCMsgHandler getMsgHandler(String webServiceName) {
   	ISDCMsgHandler msgHandler = null;
      WebServiceSettings__c webServiceSetting = (String.IsNotBlank(webServiceName) ? WebServicesHelper.getWebSvcSetting(webServiceName) : null);
      if (webServiceSetting != null) {
         msgHandler = msgHandlerMap.get(webServiceSetting.Id);
         if (msgHandler == null) {
            msgHandler = new ISDCMsgHandler(webServiceSetting);
            msgHandlerMap.put(webServiceSetting.Id,msgHandler);
         } // if (msgHandler == null
      }
      return msgHandler;
   } // getMsgHandler

   public static void handleMessages() {
   	if (!System.isFuture()) {
   		nbrMsgsSent = 0;
         for (ISDCMsgHandler msgHandler : msgHandlerMap.values()) {
         	// TODO - what do we do if we hit a limit?
            if (msgHandler.hasIdsToSend() && (Limits.getLimitCallouts() - Limits.getCallouts() > 0)) {
               msgHandler.sendMessage();
               
            }
         } // for (ISDCMsgHandler msgHandler
   	}
   } // handleMessages
   
   public static Integer nbrMsgsSent = 0;
   
   public static Integer NOTES_SIZE=ObjectHelper.getFieldLngth(Web_Service_Log__c.Notes__c);
   
   @future (callout=true) 
   public static void sendHTTPRequest(Id runningUserId, String url, String body, Boolean logAll){ 

        DateTime startDT = DateTime.now();

        Http http = new Http(); 
        HttpResponse res = new HttpResponse(); 
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(url); 
        req.setBody(body); 
        req.setMethod('POST'); 
        
        String errMsg = null;

        try { 
            res = http.send(req); 
            System.debug('sendHTTPRequest res='+res);
            
            nbrMsgsSent++;
        } catch(System.CalloutException e) { 
            System.debug('CalloutException: '+ e+':'+res.toString()); 
            errMsg = 'CalloutException: '+ e+':'+res.toString();
        } 

        Boolean isSuccess = (res != null && res.getStatusCode() == 200);

        // do not attempt the save if running a test - can't perform DML after callout in a test method
        if (!Test.isRunningTest() && (logAll || !isSuccess)) {
        	  WebServicesHelper.WebServiceWrapper wrapper = new WebServicesHelper.WebServiceWrapper();
        	  wrapper.svcName='ISDC_Msg';
        	  wrapper.succes=isSuccess;
        	  wrapper.errMsg=errMsg;
        	  wrapper.notes=('Url='+url+' Body='+body);
        	  wrapper.responsexml = (res == null ? null : ('status='+(res.getStatus()==null?'':res.getStatus())+' response body='+res.getBody()) );
           WebServicesHelper.logServiceCall(wrapper);
           //WebServicesHelper.logServiceCall('ISDC_Msg', isSuccess, errMsg, ('Url='+url+' Body='+body), null, null);
        }
     } // sendHTTPRequest
  */
} // class ISDCMsgHandler