/* 
 * Tarmika Bridge Token generation for API call
 *
 * History
    * -------
    12/12/2022 Carrie Marciano      Created
	

 */


public class TarmikaBridgeToken {
    public static final String CACHE_KEY='TarmikaAccessToken';
    
    public class TarmikaTokenWrapper{
        public String Token;
        public Integer TokenExp;
        public DateTime TokenStartDT;
        public DateTime TokenExpiryDT;        
    }
    
    public static TarmikaTokenWrapper tokenWrap = null;
    
    public static string getToken(){
        dateTime nowDT=System.now();
        
        if(tokenWrap == null){
            system.debug('getTokenWrapper nowDT: '+nowDT);
          	tokenWrap = (TarmikaTokenWrapper)CacheManager.getOrg(CACHE_KEY); 
        }
        
        if(tokenWrap == null){
            system.debug('getTokenWrapper tokenWrap not found in cache');            
            tokenWrap = doPost();
            if (tokenWrap != null){                
                CacheManager.putOrg(CACHE_KEY,tokenWrap);
                system.debug('getTokenWrapper new tokenWrap added to cache');
            }
        } else if (tokenWrap != null){
            if (tokenWrap.TokenExpiryDT <= nowDT){
                system.debug('getTokenWrapper tokenWrap is not null but expired');
            	tokenWrap = doPost();
            	if (tokenWrap != null){                
                	CacheManager.putOrg(CACHE_KEY,tokenWrap);
                	system.debug('getTokenWrapper new tokenWrap added to cache');
            	}
            } else {
                 system.debug('getTokenWrapper use existing tokenWrap.Token: '+tokenWrap.Token); 
            }
        }
        return tokenWrap.Token;
    }
    
    public static TarmikaTokenWrapper doPost(){
        TarmikaTokenWrapper tokenWrapper = null;
    	tokenWrapper = new TarmikaTokenWrapper();
        
        string ClientId = label.TarmikaClientId;
        string ClientSecret = label.TarmikaClientSecret;
        string endpoint = label.TarmikaTokenURL;
        string body = 'grant_type=client_credentials&client_id='+ClientId+'&client_secret='+ClientSecret;
        
        Blob headerValue = Blob.valueOf(ClientId + ':' + ClientSecret);
        String authorizationHeader = 'Basic ' +  EncodingUtil.base64Encode(headerValue);
        system.debug('Encoder Value' + EncodingUtil.base64Encode(headerValue));
        
        // Construct the request
        http http = new http();
        httpRequest request = new httpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Authorization', authorizationHeader);
        request.setBody(body);
        
        // Send the request
        httpResponse authResp = http.send(request);
        
        if (authResp.getStatusCode() == 200) {
            // Deserializes the JSON string into collections of primitive data types.
            // expected response {"access_token":"d1320367-c3e4-497c-860f-29b367e29f85","token_type":"Bearer","expires_in":28800}
            Map<String, Object> ResponseMap = (Map<String, Object>) JSON.deserializeUntyped(authResp.getBody());
            system.debug('response OK ' + authResp.getBody() );
            
            tokenWrapper.Token = (string)ResponseMap.get('access_token');
            system.debug('tokenWrapper.Token: ' + tokenWrapper.Token );
            
            tokenWrapper.TokenExp = (integer)ResponseMap.get('expires_in');
            system.debug('tokenWrapper.TokenExp: ' + tokenWrapper.TokenExp );
            Integer hours = integer.valueOf(tokenWrapper.TokenExp)/3600;
            system.debug('hours: ' + hours);
            
            tokenWrapper.TokenStartDT = System.now();
            //set expiry datetime one hour less than what is set in response for cushion
            tokenWrapper.TokenExpiryDT = System.now().addHours(hours-1);
            system.debug('tokenWrapper.TokenStartDT: ' + tokenWrapper.TokenStartDT + ' tokenWrapper.TokenExpiryDT: '+tokenWrapper.TokenExpiryDT );    
        } else {
            system.debug('response error ' + authResp.getBody() );
        }
        
        return tokenWrapper;
    }
}