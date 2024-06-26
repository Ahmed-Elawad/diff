/* 
   Methods necessary to access Webex connect widget from site location
 
  History
  -------
  12/01/2022 	Jermaine Stukes     Created
  05/18/2022	Jermaine Stukes		Updated to allow multiple attendees
*/
public class WebexGuestController {
    //Web Service JSON Classes
    public class WebexHeader {
		public String typ {get;set;} 
		public String alg {get;set;}
	}	
    public class WebexPayload {
		public String sub {get;set;} 
		public String name {get;set;} 
		public String iss {get;set;} 
        public Long exp {get;set;} 
	}
    public class WebexBody{
        public Boolean isLocked {get;set;} 
        public Boolean isPublic {get;set;} 
        public Boolean isAnnouncementOnly {get;set;}
        public String title {get;set;}
        public String description {get;set;}

    }
    public class WebexMembershipBody{
        public Boolean isModerator {get;set;}
        public String roomId {get;set;}
        public String personId {get;set;} 
    }
    //Create Java Web Token
    public static String generateJWT(String contactName,String sub, String userId, String secret) {
        DateTime expiration = DateTime.now().addMinutes(30);
        Long expirationTimeStamp = (expiration.getTime() / 1000);
        //Create Header
        WebexHeader weh = new WebexHeader();
        weh.typ = 'JWT';
        weh.alg = 'HS256';       
        String header = EncodingUtil.base64Encode(Blob.valueof(json.serialize(weh)));      
        
        //Create Payload
        WebexPayload wepl = new WebexPayload();
        wepl.sub = sub;
        wepl.name = contactName;
        wepl.iss = userId;
        wepl.exp = expirationTimeStamp;
        String payload = EncodingUtil.base64Encode(Blob.valueof(json.serialize(wepl)));
        
        //Create Signature
        String encodedData = header + '.' + payload.removeEnd('=');
        String secretKey = secret;
        Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueof(encodedData), EncodingUtil.base64Decode(secretKey));
        String encodedSignature = EncodingUtil.base64Encode(signature);
        encodedSignature = encodedSignature.replace('+', '-');
        encodedSignature = encodedSignature.replace('/', '_');
        
        //Generate Token
        String webExToken = encodedData + '.' + encodedSignature;
        return webExToken.removeEnd('=');       
    }
    
    //Convert JWT to Webex Access Token
    public static String generateAccessToken(String JWT, Boolean canProceed){
        String accessToken = null;
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('WebEx_Connect'); 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(wss.Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer '+ JWT);
        Http http = new Http();
        HTTPResponse response;
        if(test.isRunningTest()){
            response = new HTTPResponse();
            response.setStatusCode(200);
            response.setBody('{"token":"MockToken","expiresIn":"1209599"}');
        }else{
           response = http.send(request);
        }
        String responseMessage = response.getBody();
        if(response.getStatusCode() == 200){
            System.debug('WebexGuestController - getAccessToken - Token:' + responseMessage);
            accessToken = responseMessage.substringBetween('"token":"', '","');  
        }else{
            System.debug('WebexGuestController - getAccessToken - Response:' + responseMessage);
            canProceed = false;
        }
        return accessToken;
    }
    
    //Retrieve PersonID associated with Access Token
    public static String getWebexPersonID(String accessToken, Boolean canProceed){
        String personId;
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('Webex_GetPersonId'); 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(wss.Endpoint__c);
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer '+ accessToken);
        request.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HTTPResponse response;
        if(test.isRunningTest()){
            response = new HTTPResponse();
            response.setStatusCode(200);
            response.setBody('{"id":"MockId"}');
        }else{
            response = http.send(request);
        }
        String responseMessage = response.getBody();
        if(response.getStatusCode() == 200){          
            personId = responseMessage.substringBetween('"id":"', '","');  
        }else{
            canProceed = false;
            System.debug('WebexGuestController - getWebexPersonID - Response:' + responseMessage);
        }
        return personId;
    }
    
    //Create Webex Room to host meeting
    public static String createWebexRoom(String accessToken, String roomTitle, Boolean canProceed){
        String webexRoomId;
        //Create Request Body
        WebexBody weBody = new WebexBody();
        weBody.isLocked = false;
        weBody.isPublic = false;
        weBody.isAnnouncementOnly = false;
        weBody.title = roomTitle;
        weBody.description = 'Paychex generated meeting space';
        String body = json.serialize(weBody);
        
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('Webex_CreateRoom'); 
        HttpRequest request = new HttpRequest();
        request.setEndpoint(wss.Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer '+ accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);

        Http http = new Http();
        HTTPResponse response;
        if(test.isRunningTest()){
            response = new HTTPResponse();
            response.setStatusCode(200);
            response.setBody('{"token":"MockToken","expiresIn":"1209599"}');
        }else{
           response = http.send(request);
        }
        String responseMessage = response.getBody();
        if(response.getStatusCode() == 200){
            webexRoomId = responseMessage.substringBetween('"id":"', '","');  
        }else{
            System.debug('WebexGuestController - createWebexRoom - Response:' + responseMessage);
            canProceed = false;
        }
        return webexRoomId;
    }
    
    //Add members to the meeting
    public static String createMembership(String accessToken, String roomId, String guestPersonId, Boolean canProceed){
        WebServiceSettings__c wss = WebServicesHelper.getWebSvcSetting('Webex_CreateMembership'); 
        HttpRequest request = new HttpRequest();
        WebexMembershipBody wmb = new WebexMembershipBody();
        String membershipId;
        wmb.isModerator = false;
        wmb.roomId = roomId;
        wmb.personId = guestPersonId;
        String body = json.serialize(wmb);
        request.setEndpoint(wss.Endpoint__c);
        request.setMethod('POST');
        request.setHeader('Authorization', 'Bearer '+ accessToken);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(body);
        Http http = new Http();
        HTTPResponse response;
        if(test.isRunningTest()){
            response = new HTTPResponse();
            response.setStatusCode(200);
            response.setBody('{"token":"MockToken","expiresIn":"1209599"}');
        }else{
            response = http.send(request);
        }
        String responseMessage = response.getBody();
        if(response.getStatusCode() == 200){
            System.debug('WebexGuestController - createMembership - Token:' + responseMessage);
            membershipId = responseMessage.substringBetween('"id":"', '","');  
        }else{
            System.debug('WebexGuestController - createMembership - Response:' + responseMessage);
            canProceed = false;
        }      
        return membershipId;
    }
    
    //Generate email for all Webex meeting attendees    
    public static Messaging.SingleEmailMessage generateWebexEmail(String siteLink, String emailAddy, String hostName, String contactName, Boolean isSalesRep){
        String emailLink = '<html><a href="'+siteLink+'">Join WebEx Meeting</a></html>';
        String emailSubject = isSalesRep ? 'Webex Instant Meeting with '+contactName : hostName+' at Paychex is inviting you to a WebEx meeting';
        String emailBody = isSalesRep ? hostName + ',<br/><br/>Below is the link for the WebEx meeting initiated out of Salesforce between yourself and the following attendees: ' + contactName + '<br/><br/>' + emailLink +
		'<br/><br/>Please Note: Only the attendees invited via the form can join.  If you need to add additional invitees, you must initiate a new meeting':
        'Dear '+contactName+',<br/><br/>I\'m inviting you to a WebEx meeting to discuss how Paychex can support your business.<br/><br/>' + emailLink;
        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
        emailToSend.setToAddresses(new String[] {emailAddy});
        emailToSend.setSubject(emailSubject);
        emailToSend.setHtmlBody(emailBody);
        emailToSend.setUseSignature(true);
        //emailToSend.getUseSignature()
        return emailToSend;
    }

    @AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [Select Id, Email, FirstName, LastName, ProfileId from User where Id=:UserInfo.getUserId()];
        return currentUser;
    }
    
    @AuraEnabled
    public static sObject getRecordInfo(String recordId){
        String contactEmail;
        String contactName;
        String objectName = ObjectHelper.getObjectNameFromId(recordId);
        sObject returnObject;
        switch on objectName{
            when 'Contact'{
                Contact con = [Select Id, FirstName, lastname, Email from Contact where Id=:recordId];
                returnObject = con;
            }
            when 'Account'{
                Account acct = [Select Id, Significant_Contact_Email__c, SignificantContact__c, SignificantContact__r.FirstName, SignificantContact__r.LastName from Account where Id=:recordId ];
                returnObject = acct;
            }
            when 'Lead'{
                Lead ld = [Select Id, FirstName, lastname, Email from Lead where Id=:recordId];
                returnObject = ld;
            }
        }
        return returnObject;
    }
    
    @AuraEnabled
    public static Boolean initiateWidget(User host, String contactname, String attendeeNames, String attendeeEmails, String title, String objectRecordId){
        Messaging.SingleEmailMessage[] msgsToSend = new Messaging.SingleEmailMessage[]{};
        List<String> attendeeJwtList = new List<String>();
        Boolean processEmail = true;
        //Get Host JWT
        String hostName = host.FirstName+' '+host.LastName;
        String subName = 'Paychex Sales Representative';
        String repUserId = label.WebexSalesRepId;
        String repSecret = label.WebexSalesRepSecret;
        String repJWT = generateJWT(hostName, subName, repUserId, repSecret);
        String hostAccessToken = generateAccessToken(repJWT, processEmail);
        String accessTokenParam = '?AccessToken=' + hostAccessToken;
        
        //create Webex meeting room
        String webexRoom = createWebexRoom(hostAccessToken, title, processEmail);
        String destinationParam = '&Destination='+webexRoom;
        //Generate Host Email
        String siteLink = label.WebexSiteLink + accessTokenParam + destinationParam;
        msgsToSend.add(generateWebexEmail(siteLink, host.Email, hostName, attendeeNames, true));
        
        //Get Attendees JWT
        List<String> attendeeList = attendeeNames.split(',');
        List<String> attendeeEmailList = attendeeEmails.split(',');
        List<String> guestIdList = label.WebexGuestUserId.split(',');
        List<String> guestSecretList = label.WebexGuestSecret.split(',');
        Integer attendeeNumber = 0;
        for(String attendee : attendeeList){
            //Generate Guest JWT
            String guestName = attendee;
            String guestSubName = 'Paychex Guest';
            String guestEmail = attendeeEmailList[attendeeNumber];
            String guestId = guestIdList[attendeeNumber];
            String guestSecret = guestSecretList[attendeeNumber];
            String guestJWT = generateJWT(guestName, guestSubName, guestId, guestSecret);
            //Get Guest Access Token
            String guestAccessToken = generateAccessToken(guestJWT, processEmail);
            //Get Guest User Person Id
            String guestPersonId = getWebexPersonID(guestAccessToken, processEmail);
            //Generate Room Membership
            createMembership(hostAccessToken,webexRoom,guestPersonId, processEmail);
            //Generate Guest Emails
            String guestAccessTokenParam = '?AccessToken=' + guestAccessToken;
            //Generate Host Email
            String guestSiteLink = label.WebexSiteLink + guestAccessTokenParam + destinationParam;
            msgsToSend.add(generateWebexEmail(guestSiteLink, guestEmail, hostName, attendee, false));
            attendeeNumber++;
        }
        Boolean emailSuccess = true;
        if(processEmail){
            try{
                Messaging.sendEmail(msgsToSend);
                //Create Activity
                if(objectRecordId!=null){
                    Event evnt = CreateActivityController.getNewEvent('Event',objectRecordId);
                    evnt.ActivityDateTime = DateTime.now();
                    evnt.Subject = 'Meeting-Instant Webex- '+contactname;
                    //evnt.c
                    evnt.Activity__c = 'Instant Webex Presentation';
                    evnt.Type = 'Instant Webex Presentation	';
                    evnt.Meeting_Attendees__c = attendeeNames;
                    evnt.Onsite_or_Virtual__c = 'Virtual';
                    evnt = CreateActivityController.saveEvent(JSON.serialize(evnt));
                }
            }catch (exception ex){
                emailSuccess = false;
            }
        }else{
           emailSuccess = false; 
        }

        return emailSuccess;
    }
}