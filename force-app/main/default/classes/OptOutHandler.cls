/* 
 * Accept a rest request to unsubscribe
 
 *
 * History
 * -------
   01/25/2024 Dan Carmen       Created

 */
@RestResource(urlMapping='/OptOut/*')
global class OptOutHandler {
/*
    // POST request to create the opt out record
    @HttpPost 
    global static String submitOptOut(String emailAddr) {
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        String endvalue = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c(Name=emailAddr);
        refDNC.Contact_Email__c = emailAddr;
        refDNC.Status__c = 'New';
        refDNC.Requestor__c = 'OptOutHandler';
        refDNC.comments__c = endValue;
        insert refDNC;
        String returnMesasge = 'Opt Out submitted for '+emailAddr;
        return returnMesasge;
   } // submitOptOut
  */  
    // POST request to create the opt out record
    @HttpPost 
    global static String unsubscribe() {
        RestRequest req = RestContext.request;
        RestResponse res = Restcontext.response;
        String endvalue = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        String comments = 'Param Received='+endvalue;
        if (String.isNotBlank(endvalue)) {
           // if it doesn't contains an "@" we'll assume it's an urlencoded parameter
           if (!endValue.contains('@')) {
              endValue = EncodingUtil.urlDecode(endvalue,'UTF-8');
              comments += ' After urlDecode='+endValue;
           }
        } // if (String.isNotBlank
        // does the passed in value appear to be in the correct format?
        Boolean validEmail=(String.isNotBlank(endvalue) && endValue.contains('@'));
        if (String.isBlank(endvalue) || !endValue.contains('@')) {
           comments += '\nValid email not passed in!';
        }
        Reference_Do_Not_Contact__c refDNC = new Reference_Do_Not_Contact__c(Name=endvalue);
        refDNC.Contact_Email__c = endvalue;
        refDNC.Status__c = 'New';
        refDNC.Requestor__c = 'OptOutHandler';
        refDNC.comments__c = comments;
        insert refDNC;
        String returnMesasge = 'Opt Out submitted for '+endvalue;
        return returnMesasge;
   } // submitOptOut
    

} // class OptOutHandler